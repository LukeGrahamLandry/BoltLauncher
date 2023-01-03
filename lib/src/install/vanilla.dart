import 'dart:convert';
import 'dart:io' show File;
import '../util/manifiest.dart';

import '../constants.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'model/vanilla.dart' as vanilla;
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
    var versionData = vanilla.VersionList.fromJson(await cachedFetch(Constants.metaSources.vanillaVersions, "vanilla-versions.json"));
		for (var version in versionData.versions){
        if (version.id == versionId) {
          var libs = vanilla.VersionFiles.fromJson(await cachedFetch(version.url, "vanilla-${version.id}.json"));
          return libs;
        }
    }
    return null;
  }

	Future<void> download(vanilla.VersionFiles data) async {
		for (var lib in data.libraries) {
      if (!ruleMatches(lib.rules)) {
				print("skip (rule) ${lib.name}");
        continue;
			}

      String path = p.join(Constants.installDirectory, "libraries", lib.downloads.artifact.path);
      if (await isCached(lib.downloads.artifact.sha1, lib.name, path)){
        print("skip (cache) ${lib.name}");
        continue;
      }

			print("downloading ${lib.name}");
      if (await downloadLibrary(lib.downloads.artifact, path)){
        manifest.vanillaLibs[lib.name] = lib.downloads.artifact.sha1;
      }
		}

    String path = p.join(Constants.installDirectory, "versions", versionId, "$versionId.jar");
		if (await isCached(data.downloads.client.sha1, "client-$versionId", path)){
			print("skip (cache) client-$versionId");
		} else {
			print("downloading client-$versionId");
      if (await downloadLibrary(data.downloads.client, path)) {
        manifest.vanillaLibs["client-$versionId"] = data.downloads.client.sha1;
      }
		}
	}

  /// Checks that a file exists at [path] and [wantedHash] matches the one in the manifest for [name]
  Future<bool> isCached(String wantedHash, String name, String path) async {
    String? manifestHash = manifest.vanillaLibs[name];
    if (manifestHash == null) return false;

    bool cachedFileMatches = wantedHash == manifestHash;
    if (cachedFileMatches){
      bool filePresent = await File(path).exists();
      if (filePresent){
        return true;
      }
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
				if ((rule.os?.name ?? "osx") != "osx") return false;
			}

		}
		return true;
	}
}
