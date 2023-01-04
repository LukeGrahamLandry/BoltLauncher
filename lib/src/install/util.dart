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

class LibFile {
  final String url;
  final String path;
  final String sha1;
  
  LibFile(this.url, this.path, this.sha1);

  String get fullPath {
    return p.join(Locations.dataDirectory, path);
  }

  String get jarUrl {
    return url;
  }
}

class DownloadHelper {
  late PastDownloadManifest manifest;
  List<HashError> errors = [];
  bool hashChecking = true;
  List<LibFile> allLibs;

  DownloadHelper(this.allLibs);

  Future<void> downloadAll() async {
    manifest = await PastDownloadManifest.load();

    print("Checking ${allLibs.length} libraries.");
    int startTime = DateTime.now().millisecondsSinceEpoch;
    await Future.wait(allLibs.map((lib) => downloadLibrary(lib)));
    int endTime = DateTime.now().millisecondsSinceEpoch;
    print("Checked ${allLibs.length} libraries in ${(endTime - startTime) / 1000} seconds.");

    manifest.save();
  }

  String get classpath {
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
    var response = await http.get(Uri.parse(lib.jarUrl));

    if (hashChecking){
      var digest = sha1.convert(response.bodyBytes);
      if (digest.toString() != lib.sha1){
        errors.add(HashError(lib.sha1, digest.toString(), lib.jarUrl));
        print("Error downloading from ${lib.jarUrl}");
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
      if (GlobalOptions.recomputeHashesOnStart){
        var bytes = await file.readAsBytes();
        var manifestHash = sha1.convert(await File(lib.fullPath).readAsBytes()).toString();
      }
      
      return manifestHash == lib.sha1;
    }

    return false;
  }
}