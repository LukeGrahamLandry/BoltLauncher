

import 'dart:convert';
import 'dart:io';
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:path/path.dart' as path;
import 'package:bolt_launcher/src/api_models/java_metadata.dart';

class JavaFinder {
  static Future<List<JavaInfo>> search() async {
    List<JavaInfo> cached = await MetadataCache.localJavaInstalls;
    if (cached.isNotEmpty) return cached;

    int startTime = DateTime.now().millisecondsSinceEpoch;
    List<JavaInfo> found = (await Future.wait((await findBinaries()).map((binary) async {
      return await getJavaInfo(binary);
    }))).expand((x) => x).toList();
    
    File cache = File(Locations.javaInstallationsList);
    await cache.create(recursive: true);
    await cache.writeAsString(JsonEncoder.withIndent('  ').convert(found));
    
    return found;
  }

  static Future<List<String>> wellKnownJreFolders() async {
    List<String> results = [
      path.join(Locations.homeDirectory, "Library", "Java", "JavaVirtualMachines"),
      path.join("/Library", "Java", "JavaVirtualMachines"),
      path.join("/Library", "Internet Plug-Ins", "JavaAppletPlugin.plugin"),
      path.join(Locations.homeDirectory, "Documents", "curseforge", "minecraft", "Install", "java"),
      path.join(Locations.homeDirectory, ".gradle", "jdks"),
    ];

    // official installer
    Directory minecraft = Directory(path.join(Locations.homeDirectory, "Library", "Application Support", "minecraft", "runtime"));
    if (minecraft.existsSync()){
      await for (var version in minecraft.list()){  // java-runtime-gamma
        if (version is Directory){
          await for (var os in version.list()){  // mac-os-arm64
            if (os is Directory){
              await for (var versionAgain in os.list()){  // java-runtime-gamma
                results.add(versionAgain.path);
              }
            }
          }
        }
      }
    }

    return results;
  }
  
  /// get the paths to all java binaries in well known locations
  static Future<List<String>> findBinaries() async {
    List<List<String>> binaryGroups = (await Future.wait((await wellKnownJreFolders()).map((folder) async {
      var dir = Directory(folder);
      if (!await dir.exists()) return [];
      List<String> results = [];
      await for (var jre in dir.list()){
        List<String> possibleBinaries = [path.join(jre.path, "Contents", "Home", "bin", "java"), path.join(jre.path, "jre", "bin", "java")];
        
        for (String binary in possibleBinaries){
          if (await File(binary).exists()){
            results.add(binary);
          }
        }
      }
      return results;
    })));

    return binaryGroups.expand((x) => x).toList()..add("java");
  }

  /// retrieve version information from a java binary
  static Future<List<JavaInfo>> getJavaInfo(String javaExecutable) async {
    ProcessResult result = await Process.run(javaExecutable, ["-XshowSettings:properties", "-version"], runInShell: true);
    List<String> lines = (result.stderr as String).split("\n");
    Map<String, String> data = {};
    for (String line in lines){
      if (line.contains("=")){
        var parts = line.split("=");
        data[parts[0].trim()] = parts[1].trim();
      }
    }

    try {
      return [JavaInfo(data["java.vendor"]!, data["java.specification.version"]!, data["java.runtime.version"]!, data["os.arch"]!, javaExecutable)];
    } catch (e){
      return [];
    }
  }
}


class JavaInstaller {
  
}