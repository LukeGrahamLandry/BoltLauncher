import 'dart:convert';
import 'dart:io' show File;
import '../util/manifiest.dart';

import '../constants.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'model/vanilla.dart' as vanilla;

void installVanilla(String versionId) async {
  await VanillaInstaller(versionId).install();
}

class VanillaInstaller {
	String versionId;
	late PastDownloadManifest manifest;

	VanillaInstaller(this.versionId);

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
			if (lib.downloads.artifact.sha1 == manifest.vanillaLibs[lib.name]){
				print("skip (cache) ${lib.name}");
			} else if (!ruleMatches(lib.rules)) {
				print("skip (rule) ${lib.name}");
			} else {
				print("downloading ${lib.name}");
        await downloadLibrary(lib.downloads.artifact, p.join(Constants.installDirectory, "libraries", lib.downloads.artifact.path));
				manifest.vanillaLibs[lib.name] = lib.downloads.artifact.sha1;
			}
		}

		if (data.downloads.client.sha1 == manifest.vanillaLibs["client-$versionId"]){
			print("skip (cache) client-$versionId");
		} else {
			print("downloading client-$versionId");
      await downloadLibrary(data.downloads.client, p.join(Constants.installDirectory, "versions", versionId, "$versionId.jar"));
			manifest.vanillaLibs["client-$versionId"] = data.downloads.client.sha1;
		}
	}

	Future<void> downloadLibrary(vanilla.Artifact lib, String path) async {
    var file = File(path);
    await file.create(recursive: true);

    await http.get(Uri.parse(lib.url)).then((response) {
        file.writeAsBytes(response.bodyBytes);
        // TODO: check hash
    });
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
