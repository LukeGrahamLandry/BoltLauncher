import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:bolt_launcher/bolt_launcher.dart';

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
  bool hashChecking = true;
  List<LibFile> allLibs;

  DownloadHelper(this.allLibs);

  Future<void> downloadAll() async {
    manifest = await PastDownloadManifest.open();

    print("Checking ${allLibs.length} libraries.");
    int startTime = DateTime.now().millisecondsSinceEpoch;
    await Future.wait(allLibs.map((lib) => downloadLibrary(lib)));
    int endTime = DateTime.now().millisecondsSinceEpoch;
    print("Checked ${allLibs.length} libraries in ${(endTime - startTime) / 1000} seconds.");

    manifest.close();
  }

  String get classPath {
    List<String> files = [];
    for (var lib in allLibs){
      files.add(lib.fullPath);
    }
    return files.join(":"); // other os separator? 
  }
  
  Future<bool> downloadLibrary(LibFile lib) async {
    if (await isCached(lib)){
      print("cached ${lib.path}");
      return true;
    }

    var file = File(lib.fullPath);
    var response = await http.get(Uri.parse(lib.url));

    if (hashChecking){
      var digest = sha1.convert(response.bodyBytes);
      if (digest.toString() != lib.sha1){
        errors.add(HashError(lib.sha1, digest.toString(), lib.url));
        print("Error downloading from ${lib.url}");
        print("- Expected sha1=${lib.sha1} but got $digest");
        return false;
      }
    }

    await file.create(recursive: true);
    await file.writeAsBytes(response.bodyBytes);
    manifest.jarLibs[lib.path] = lib.sha1;

    print("downloaded ${lib.path}");

    return true;
  }

  Future<bool> isCached(LibFile lib) async {
    String? manifestHash = manifest.jarLibs[lib.path];
    if (manifestHash == null) return false;

    var file = File(lib.fullPath);
    bool filePresent = await file.exists();
    if (filePresent){
      bool matchesManifest = manifestHash == lib.sha1;

      if (!matchesManifest){
        print("WARNING");
        print("Desired hash of ${lib.path} changed since last download.");
        print("Was ${manifestHash}, now ${lib.sha1}");
        print("File will be re-downloaded but this is very concerning.");
        print("=======");
      }

      if (GlobalOptions.recomputeHashesOnStart){
        var bytes = await file.readAsBytes();
        var fileSystemHash = sha1.convert(await File(lib.fullPath).readAsBytes()).toString();
        return fileSystemHash == lib.sha1;
      }

      return matchesManifest;
    }

    return false;
  }
}

class LibFile {
  final String url;
  final String path;
  final String sha1;
  
  LibFile(this.url, this.path, this.sha1);

  String get fullPath {
    return p.join(Locations.dataDirectory, path);
  }
}

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
