import 'dart:convert';
import 'dart:io' show File, FileMode, Platform;
import 'dart:typed_data';
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:http/http.dart';

import '../data/cache.dart';
import '../data/locations.dart';
import '../data/options.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import '../api_models/vanilla_metadata.dart' as vanilla;
import 'package:crypto/crypto.dart';


class HashError {
  String wanted;
  String got;
  String url;

  HashError(this.wanted, this.got, this.url);
}

class DownloadHelper {
  late PastDownloadManifest manifest;
  List<HashError> errors = [];
  List<LibFile> allLibs;
  int count = 0;
  int totalSize = 0;
  int totalProgress = 0;
  bool verbose;
  late Client httpClient;
  int incrementalManifestCounter = 0;
  bool showSizeProgress = true;
  int totalDownloadSize = 0;

  DownloadHelper(this.allLibs, {this.verbose = false});

  Future<void> downloadAll() async {
    manifest = await PastDownloadManifest.open();

    int startTime = DateTime.now().millisecondsSinceEpoch;

    try {
      httpClient = Client();

      for (LibFile lib in allLibs){
        if (lib.size != null){
          totalSize += lib.size!;
        } else {
          showSizeProgress = false;
          break;
        }
      }

      print("Checking ${allLibs.length} files${showSizeProgress ? " (${(totalSize/1000000).toStringAsFixed(0)} MB)" : ""}");
      
      // if i dont split it into chunks, it freezes on the Future.wait for a really long time before downloading anything
      // i guess its starting all the connections before it gives any time to actually downloading so theres no sense of progress 
      // but dowing it syncronously in a for loop awaiting each individually was a lot slower 
      var len = allLibs.length;
      var size = 50;
      List<List<LibFile>> chunks = [];
      for(var i = 0; i< len; i+= size){    
          var end = (i+size<len)?i+size:len;
          chunks.add(allLibs.sublist(i,end));
      }

      for (List<LibFile> libs in chunks){
        await Future.wait(libs.map((lib) => downloadLibrary(lib)));
      }
    } catch(e, stacktrace) {
      print("Download process failed with error: ");
      print(e.toString());
      print(stacktrace);
    }
    httpClient.close();
    
    int endTime = DateTime.now().millisecondsSinceEpoch;
    String msg = "Checked $count files in ${(endTime - startTime) / 1000} seconds. ";
    if (showSizeProgress) {
      var cachePercentage = ((1 - (totalDownloadSize / totalSize)) * 100).toStringAsFixed(1);
      msg += "Of ${(totalSize/1000000).toStringAsFixed(0)} MB, $cachePercentage% found in cache. ";
    }
    msg +="${(totalDownloadSize/1000000).toStringAsFixed(0)} MB downloaded.";
    print(msg);

    manifest.close();
  }

  String get classPath {
    List<String> files = [];
    for (var lib in allLibs){
      if (lib.fullPath.endsWith(".jar")){
        files.add(lib.fullPath);
      }
    }
    return files.join(":"); // other os separator? 
  }
  
  Future<bool> downloadLibrary(LibFile lib) async {
    if (await isCached(lib)){
      count++;
      if (showSizeProgress) totalProgress += lib.size!;
      if (verbose) print("($count/${allLibs.length}) cached ${lib.path}");
      return true;
    }

    var file = File(lib.fullPath);

    Request request = Request("get", Uri.parse(lib.url));

    StreamedResponse response;
    try {
      response = await httpClient.send(request);
    } catch (e) {
      print("${e.toString()} ${lib.url}");
      return false;
    }
    

    if (response.statusCode != 200){
      print("${lib.url} ${response.statusCode}");
      return false;
    }

    Uint8List bodyBytes = await response.stream.toBytes();
    // var response = await http.get(Uri.parse(lib.url));

    if (GlobalOptions.checkHashesAfterDownload){
      var digest = sha1.convert(bodyBytes);
      if (digest.toString() != lib.sha1){
        errors.add(HashError(lib.sha1, digest.toString(), lib.url));
        print("Error downloading from ${lib.url}");
        print("- Expected sha1=${lib.sha1} but got $digest");
        count++;
        print("($count/${allLibs.length}) failed ${lib.path}");
        return false;
      }
    } else {
      // TODO: stream directly to file instead of holding the whole thing in ram until the end 
    }

    await file.create(recursive: true);
    await file.writeAsBytes(bodyBytes);
    (lib.path.endsWith(".jar") ? manifest.jarLibs : manifest.other)[lib.path] = lib.sha1;
    count++;
    
    String msg = "($count/${allLibs.length} files";
    if (showSizeProgress){
      totalDownloadSize += lib.size!;
      totalProgress += lib.size!;
      msg += ", ${(totalProgress/GlobalOptions.bytesPerMB).toStringAsFixed(0)}/${(totalSize/1000000).toStringAsFixed(0)} MB, ${(totalProgress/totalSize*100).toStringAsFixed(1)}%";
    } else {
      totalDownloadSize += bodyBytes.length;
    }
    msg += ") ${lib.url}";
    
    print(msg);

    incrementalManifestCounter += bodyBytes.length;
    if (incrementalManifestCounter > 5000000) {
      incrementalManifestCounter = 0;
      await manifest.quickSave();
    }

    if (lib.path.endsWith(".jar")){
      // TODO: some sort of locking
      await File(p.join(Locations.dataDirectory, "executables-download-history.txt")).writeAsString("${DateTime.now()} ${lib.url} ${lib.sha1}\n", mode: FileMode.append);
    }


    return true;
  }

  Future<bool> isCached(LibFile lib) async {
    String? manifestHash = (lib.path.endsWith(".jar") ? manifest.jarLibs : manifest.other)[lib.path];
    if (manifestHash == null) return false;

    var file = File(lib.fullPath);
    bool filePresent = await file.exists();
    if (!filePresent) return false;

    if (GlobalOptions.recomputeHashesBeforeLaunch){
      var bytes = await file.readAsBytes();
      var fileSystemHash = sha1.convert(await File(lib.fullPath).readAsBytes()).toString();
      return fileSystemHash == lib.sha1;
    } 
    
    bool matchesManifest = manifestHash == lib.sha1;

    if (!matchesManifest){
      print("WARNING");
      print("Desired hash of ${lib.path} changed since last download.");
      print("Was ${manifestHash}, now ${lib.sha1}");
      print("File will be re-downloaded but this is very concerning.");
      print("=======");
    }

    return matchesManifest;
  }
}

class LibFile {
  final String url;
  final String path;
  final String sha1;
  int? size;

  LibFile(this.url, this.path, this.sha1, this.size);

  String get fullPath {
    return p.join(Locations.installDirectory, path);
  }
}

// class LibFileAt extends LibFile {
//   String? fullDirectory;

//   LibFileAt(String url, String path, String sha1, {this.fullDirectory}) : super(url, path, sha1);

//   String get fullPath {
//     return p.join(fullDirectory ?? Locations.dataDirectory, path);
//   }
// }

class MavenLibFile implements LibFile {
  MavenArtifact artifact;
  String directory;
  late String sha1;

  MavenLibFile(this.artifact, this.directory);

  static Future<MavenLibFile> of(MavenArtifact artifact, String directory) async {
    MavenLibFile self = MavenLibFile(artifact, directory);
    self.sha1 = await artifact.sha1;
    return self;
  }

  @override
  String get fullPath => p.join(directory, artifact.path);

  @override
  String get path => artifact.path;

  @override
  String get url => artifact.jarUrl;
  
  @override
  int? size;
}

mixin MavenArtifact {
  late String _identifier;
  late String _repo;

  void init(String identifier, String repo){
    _identifier = identifier;
    _repo = repo;
  }

  String get path {
    List<String> parts = _identifier.split(":");
    String group = parts[0];
    String path = group.split(".").join("/");
    String id = parts[1];
    String version = parts[2];

    return "$path/$id/$version/$id-$version.jar";
  }

  String get jarUrl {
    return "$_repo$path";
  }

  String get sha1Url {
    return "$jarUrl.sha1";
  }

  Future<String> get sha1 async {
    var response = await http.get(Uri.parse(sha1Url));
    if (response.statusCode != 200) {
        throw Exception('Failed to load $sha1Url');
    } 
    return response.body;
  }
}
