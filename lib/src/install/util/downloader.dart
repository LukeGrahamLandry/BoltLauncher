import 'dart:io' show File, FileMode;
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/install/util/problem.dart';
import 'package:bolt_launcher/src/install/util/remote_file.dart';
import 'package:bolt_launcher/src/install/util/progress.dart';
import 'package:http/http.dart';

import '../../data/cache.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';

class DownloadHelper {
  late PastDownloadManifest manifest;
  List<Problem> get errors => progress.errors;
  List<RemoteFile> toDownload;
  late Client httpClient;
  DownloadProgressTracker progress;
  late List<String> localSearchLocations;

  DownloadHelper(this.toDownload, {List<String>? localSearchLocations}) : progress = DownloadProgressTracker(toDownload) {
    this.localSearchLocations = localSearchLocations ?? [];
  }

  Future<void> downloadAll() async {
    progress.logStart();
    manifest = await PastDownloadManifest.open();
    httpClient = Client();

    for (var libs in getChunks()){
      await Future.wait(libs.map((lib) => downloadLibrary(lib)));
    }
    
    httpClient.close();
    await manifest.close();
    progress.logEnd();
  }
  
  Future<bool> downloadLibrary(RemoteFile lib) async {
    if (await isCached(lib)){
      progress.logCached(lib);
      return true;
    }

    var targetFile = File(lib.fullPath);
    await targetFile.create(recursive: true);

    for (String wellKnownInstall in GlobalOptions.wellKnownInstallLocations){
      var checkFile = File(p.join(wellKnownInstall, lib.wellKnownSubFolder, lib.path));
      if (await checkWellKnown(checkFile, lib)){
          await checkFile.copy(lib.fullPath);
          progress.logWellKnown(lib, wellKnownInstall);
          addToManifestCache(lib);
          return true;
        } 
    }

    Request request = Request("get", Uri.parse(lib.url));

    StreamedResponse? response;
    Problem? finalProblem;
    
    // retry 20 times
    for (int i=0; i<20; i++){
      try {
        response = await httpClient.send(request);
        finalProblem = null;
        break;
      } catch (e) {
        finalProblem = HttpProblem(e.toString(), lib.url);
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    if (finalProblem != null){
      progress.logFailed(lib, finalProblem);
      return false;
    } else if (response == null){  // i dont think this is possible without finalProblem being non-null above
      progress.logFailed(lib, HttpProblem("null response", lib.url));
      return false;
    } else if (response.statusCode != 200){
      progress.logFailed(lib, HttpProblem("Status code ${response.statusCode}", lib.url));
      return false;
    }

    int length = response.contentLength ?? 0;
    var sink = targetFile.openWrite();
    Future.doWhile(() async {
      var received = await targetFile.length();
      progress.logDownloading(lib, received, length);
      return received < length;
    });

    await response.stream.pipe(sink);

    if (GlobalOptions.checkHashesAfterDownload){
      var digest = sha1.convert(await targetFile.readAsBytes());
      if (digest.toString() != lib.sha1){
        progress.logFailed(lib, HashProblem(lib.sha1, digest.toString(), lib.url));
        return false;
      }
    }

    addToManifestCache(lib);
    progress.logDownloaded(lib, await targetFile.length());

    await manifest.quickSave();

    if (RemoteFile.isCode(lib)){
      // TODO: some sort of locking
      await File(p.join(Locations.dataDirectory, "executables-download-history.csv")).writeAsString("${DateTime.now()},${lib.url},${lib.sha1}\n", mode: FileMode.append);
    }

    return true;
  }

  Future<bool> isCached(RemoteFile lib) async {
    String? manifestHash = manifest.jarLibs[lib.path];
    if (manifestHash == null && manifest.jarLibs.isNotEmpty) return false;

    var file = File(lib.fullPath);
    bool filePresent = await file.exists();
    if (!filePresent) return false;

    bool matchesManifest = manifestHash == lib.sha1;
    if (!matchesManifest && manifestHash != null){
      progress.logExpectedHashChanged(lib, manifestHash);
    }

    if (GlobalOptions.recomputeHashesBeforeLaunch || manifest.jarLibs.isEmpty){
      var bytes = await file.readAsBytes();
      var fileSystemHash = sha1.convert(await File(lib.fullPath).readAsBytes()).toString();
      return fileSystemHash == lib.sha1;
    } 

    return matchesManifest;
  }
  
  void addToManifestCache(RemoteFile lib) {
    manifest.jarLibs[lib.path] = lib.sha1;
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
    var digest = sha1.convert(await checkFile.readAsBytes());
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
