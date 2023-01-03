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

void installVanilla(String versionId) async {
  await VanillaInstaller(versionId).install();
}

class HashError {
  String wanted;
  String got;
  String url;

  HashError(this.wanted, this.got, this.url);
}

class VanillaInstaller {
	String versionId;
	late PastDownloadManifest manifest;
  List<HashError> errors = [];
  bool hashChecking;
  List<String> classpath = [];

	VanillaInstaller(this.versionId, {this.hashChecking=true});

	Future<void> install() async {
		manifest = await PastDownloadManifest.load();
    
		var metadata = await getMetadata();
    if (metadata == null){
			print("Minecraft version $versionId was not found. ");
			return;
		}

		await download(metadata);

    await manifest.save();
	}

  Future<vanilla.VersionFiles?> getMetadata() async {
    vanilla.VersionList versionData = await MetadataCache.vanillaVersions;
		for (var version in versionData.versions){
        if (version.id == versionId) {
          var libs = vanilla.VersionFiles.fromJson(await cachedFetch(version.url, "vanilla-${version.id}.json"));
          return libs;
        }
    }
    return null;
  }

	Future<void> download(vanilla.VersionFiles data) async {
    var clientLib = vanilla.Library("client-$versionId", vanilla.LibraryDownloads(data.downloads.client, null), null, null);
    clientLib.downloads.artifact.path = p.join(Locations.installDirectory, "versions", versionId, "$versionId.jar");
    List<vanilla.Library> allLibs = data.libraries..add(clientLib);

    // benchmark vanilla 1.19.2 2023-01-02
    // sync (awaiting each library download in a for loop): 14.857 seconds
    // async (current code): 10.758 seconds
    print("Checking Minecraft Libraries...");
    int startTime = DateTime.now().millisecondsSinceEpoch;
    await Future.wait(allLibs.map((lib) => handleLibraryDownload(data, lib)));
    int endTime = DateTime.now().millisecondsSinceEpoch;
    print("Checked ${allLibs.length} libraries in ${(endTime - startTime) / 1000} seconds");
	}

  Future<void> handleLibraryDownload(vanilla.VersionFiles data, vanilla.Library lib) async {
    if (!ruleMatches(lib.rules)) {
      print("skip (rule) ${lib.name}");
      return;
    }

    await handleArtifactDownload(lib.downloads.artifact);

    if (lib.downloads.classifiers != null && lib.natives != null){
      for (String os in getOS()){
        if (!lib.natives!.containsKey(os)) continue;
        String nativesClassifier = lib.natives![os]!;
        print(nativesClassifier);
        vanilla.Artifact? nativesArtifact = lib.downloads.classifiers![nativesClassifier];
        print(nativesArtifact);
        if (nativesArtifact != null){
          await handleArtifactDownload(nativesArtifact);
          String path = p.join(Locations.installDirectory, "libraries", nativesArtifact.path);
          // TODO: extract the natives into bin?
        }
      }
    }
  }

  Future<void> handleArtifactDownload(vanilla.Artifact artifact) async {
    if (artifact.path == null){
      print("ERROR, null target path: $artifact");
      return;
    }

    String path = p.join(Locations.installDirectory, "libraries", artifact.path);
    classpath.add(path);
    if (await isCached(artifact.sha1, artifact.path!, path)){
      print("skip (cache) ${artifact.path}");
      return;
    }

    if (await downloadLibrary(artifact, path)){
      manifest.vanillaLibs[artifact.path!] = artifact.sha1;
      print("downloaded ${artifact.path}");
    } 
  }


  
  /// Checks that a file exists at [path] and [wantedHash] matches the one in the manifest for [name]
  Future<bool> isCached(String wantedHash, String relPath, String path) async {
    String? manifestHash = manifest.vanillaLibs[relPath];
    if (manifestHash == null) return false;

    // benchmark vanilla 1.19.2 2023-01-02
    // saved hash: 0.004 seconds
    // computing hash: 0.603 seconds

    var file = File(path);
    bool filePresent = await file.exists();
    if (filePresent){
      if (GlobalOptions.recomputeHashesOnStart){
        var bytes = await file.readAsBytes();
        var manifestHash = sha1.convert(await File(path).readAsBytes()).toString();
      }
      
      return manifestHash == wantedHash;
    }

    return false;
  }

	Future<bool> downloadLibrary(vanilla.Artifact lib, String path) async {
    var file = File(path);

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
    return true;
	}

  bool ruleMatches(List<vanilla.Rule>? rules){
    if (rules == null) return true;

		for (var rule in rules){
			if (rule.action == "allow"){
				// TODO
        String? os = rule.os?.name;
				if (os != null && !getOS().contains(os)) return false;
			}

		}
		return true;
	}
}

List<String> getOS(){
  if (Platform.isMacOS) return ["osx", "macos"];
  if (Platform.isWindows) return ["windows"];
  if (Platform.isLinux) return ["linux"];
  return [];
}