import 'dart:io' show File, FileMode, Link;
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/loggers/event/base.dart';
import 'package:bolt_launcher/src/loggers/logger.dart';
import 'package:bolt_launcher/src/install/util/remote_file.dart';
import 'package:http/http.dart';

import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import '../../data/cache.dart';
import 'package:path/path.dart' as p;

import '../../loggers/event/download.dart';

class DownloadHelper {
  late PastDownloadManifest manifest;
  List<RemoteFile> toDownload;
  late Client httpClient;
  late List<String> localSearchLocations;
  List<FileProblem> errors = [];

  DownloadHelper(this.toDownload, {List<String>? localSearchLocations}) {
    this.localSearchLocations = localSearchLocations ?? [];
  }

  void log(Event event){
    if (event is FileProblem) errors.add(event);
    Logger.instance.log(event);
  }

  Future<void> downloadAll() async {
    log(StartDownload(toDownload));
    manifest = await PastDownloadManifest.open();
    httpClient = Client();

    for (var libs in getChunks()){
      await Future.wait(libs.map((lib) => downloadLibrary(lib)));
    }
    
    httpClient.close();
    await manifest.close();
    log(EndDownload());
  }
  
  Future<bool> downloadLibrary(RemoteFile lib) async {
    if (await isCached(lib)){
      log(FoundCached(lib));
      return true;
    }

    var targetFile = File(lib.fullPath);
    await targetFile.parent.create(recursive: true);

    for (String wellKnownInstall in GlobalOptions.wellKnownInstallLocations){
      var checkFile = File(p.join(wellKnownInstall, lib.wellKnownSubFolder, lib.path));

      // don't bother downloading the file if we can find it in an install by another launcher, just borrow it from there
      if (await checkWellKnown(checkFile, lib)){
        // 2023-01-05 1.19.3
        // copy all assets from borrowed: 1.346 seconds
        // link all assets to borrowed:   0.547 seconds

        bool linkWorked = false;
        try {
          // TODO: links confuse forge in 1.16.5 and before because it tries to guess libraries folder from a class's jar instad of reading the property (fixed in 1.17)
          // await Link.fromUri(targetFile.uri).create(checkFile.path);
          // linkWorked = true;
        } catch (e){};

        if (!linkWorked){
          // if anything goes wrong, like windows weird permissions stuff. just fall back to old reliable 
          await checkFile.copy(lib.fullPath);
          // only trust that it will be there next time if its in our directory, otherwise refind it
          addToManifestCache(lib);
        }
        
        log(FoundWellKnown(lib, wellKnownInstall));
        return true;
      } 
    }

    Request request = Request("get", Uri.parse(lib.url));

    StreamedResponse? response;
    FileProblem? finalProblem;
    
    // retry 20 times
    for (int i=0; i<20; i++){
      try {
        response = await httpClient.send(request);
        finalProblem = null;
        break;
      } catch (e) {
        finalProblem = HttpProblem(lib, e.toString());
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    if (finalProblem != null){
      log(finalProblem);
      return false;
    } else if (response == null){  // i dont think this is possible without finalProblem being non-null above
      log(HttpProblem(lib, "null response"));
      return false;
    } else if (response.statusCode != 200){
      log(HttpProblem(lib, "Status code ${response.statusCode}"));
      return false;
    }

    int totalLength = response.contentLength ?? 0;
    int progressLength = 0;
    var fileSink = targetFile.openWrite();
    var hashOutput = AccumulatorSink<Digest>();
    var hashInput = sha1.startChunkedConversion(hashOutput);

    await for (List<int> part in response.stream){
      hashInput.add(part);
      fileSink.add(part);
      progressLength += part.length;
      log(DownloadProgress(lib, progressLength, totalLength));
    }

    fileSink.close();
    hashInput.close();
    var digest = hashOutput.events.single;
    if (digest.toString() != lib.sha1){
      targetFile.delete();
      log(HashProblem(lib, digest.toString(), lib.url));
      return false;
    }

    addToManifestCache(lib);
    log(DownloadedFile(lib, await targetFile.length()));

    await manifest.quickSave();

    if (RemoteFile.isCode(lib)){
      // TODO: some sort of locking
      await File(p.join(Locations.dataDirectory, "executables-download-history.csv")).writeAsString("${DateTime.now()},${lib.url},${lib.sha1}\n", mode: FileMode.append);
    }

    return true;
  }

  Future<bool> isCached(RemoteFile lib) async {
    String? manifestHash = manifest.jarLibs[lib.path];

    var file = File(lib.fullPath);
    bool filePresent = await file.exists();
    if (!filePresent) return false;

    bool matchesManifest = manifestHash == lib.sha1;
    if (!matchesManifest && manifestHash != null){
      log(ExpectedHashChanged(lib, manifestHash));
    }

    if (GlobalOptions.recomputeHashesBeforeLaunch || manifestHash == null){
      var bytes = await file.readAsBytes();
      var fileSystemHash = sha1.convert(await File(lib.fullPath).readAsBytes()).toString();
      return fileSystemHash == lib.sha1;
    } 

    return matchesManifest;
  }
  
  void addToManifestCache(RemoteFile lib) {
    manifest.jarLibs[lib.path!] = lib.sha1;
  }

  Iterable<List<RemoteFile>> getChunks() sync* {
    // when downloading the 3400 files of assets 
    // if i dont split it into chunks, it freezes on the Future.wait for a really long time before downloading anything
    // i guess its starting all the connections before it gives any time to actually downloading so theres no sense of progress 
    // but dowing it syncronously in a for loop awaiting each individually was a lot slower 
    var len = toDownload.length;
    var size = 50;
    List<List<RemoteFile>> chunks = [];
    for(var i = 0; i< len; i+= size){    
        var end = (i+size<len)?i+size:len;
        yield toDownload.sublist(i,end);
    }
  }

  String get classPath {
    return toClasspath(this.toDownload);
  }

  static String toClasspath(List<RemoteFile> toDownload){
    List<String> files = [];
    for (var lib in toDownload){
      if (lib.fullPath.endsWith(".jar")){
        files.add(lib.fullPath);
      }
    }
    return files.join(":"); // other os separator? 
  }
  
   Future<bool> checkWellKnown(File checkFile, RemoteFile lib) async {
    if (!await checkFile.exists()) return false;

    var hashOutput = AccumulatorSink<Digest>();
    var hashInput = sha1.startChunkedConversion(hashOutput);
    var fileReader = checkFile.openRead();
    await for (List<int> part in fileReader){
      hashInput.add(part);
    }
    hashInput.close();
    
    var digest = hashOutput.events.single;
    return digest.toString() == lib.sha1;
  }
}

// since the minecraft assets are named based on their hash, i don't have to clutter up the manifest with them and still don't have to wast time recomputing it from the files 
class AssetsDownloadHelper extends DownloadHelper {
  String indexHash;

  AssetsDownloadHelper(super.allLibs, this.indexHash);

  @override
  Future<void> downloadAll() async {
    // 2023-01-05 fabric 1.19.3
    // saves ~70 ms vs checking the hash of each file individually 
    if (!GlobalOptions.reConfirmAssetsExistBeforeLaunch){
      manifest = await PastDownloadManifest.open();
      PastDownloadManifest.locked = false;
      if (manifest.fullyInstalledAssetIndexes.contains(indexHash)){
        print("Asset index $indexHash already processed.");
        return;
      }
    }

    await super.downloadAll();

    if (errors.isEmpty){
      manifest = await PastDownloadManifest.open();
      manifest.fullyInstalledAssetIndexes.add(indexHash);
      await manifest.close();
    }
  }

  @override
  Future<bool> isCached(RemoteFile lib) async {
    return File(lib.fullPath).exists();
  }

  @override
  void addToManifestCache(RemoteFile lib) {
    
  }

  @override
  Future<bool> checkWellKnown(File checkFile, RemoteFile lib) async {
    return checkFile.exists();
  }
}
