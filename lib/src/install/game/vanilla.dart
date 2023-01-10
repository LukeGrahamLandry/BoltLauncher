import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart' as vanilla;
import 'package:bolt_launcher/src/install/util/problem.dart';
import 'package:bolt_launcher/src/install/util/remote_file.dart';

import 'package:path/path.dart' as p;

void installVanilla(String versionId) async {
  await VanillaInstaller(versionId).install();
}

abstract class GameInstaller {
  String minecraftVersion;
  String? loaderVersion;
  GameInstaller(this.minecraftVersion, this.loaderVersion);

  Future<bool> install();
}

class VanillaInstaller extends GameInstaller {
  late DownloadHelper jarDownloadHelper;
  late DownloadHelper assetDownloadHelper;

	VanillaInstaller(String versionId) : super(versionId, null);

  @override
	Future<bool> install() async {
		var metadata = await getMetadata(minecraftVersion);
    if (metadata == null){
			print("Minecraft version $minecraftVersion was not found. ");
			return false;
		}

		await download(metadata);
    return true;
	}

  static Future<vanilla.VersionFiles?> getMetadata(String versionId) async {
    vanilla.VersionList versionData = await MetadataCache.vanillaVersions;
		for (var version in versionData.versions){
        if (version.id == versionId) {
          var libs = vanilla.VersionFiles.fromJson(await cachedFetchJson(version.url, "vanilla-${version.id}.json"));
          libs.downloads!.client.version = versionId;
          libs.downloads!.client.name = "client";
          return libs;
        }
    }
    return null;
  }

	Future<void> download(vanilla.VersionFiles data) async {
    jarDownloadHelper = DownloadHelper(constructLibraries(data, minecraftVersion));
    await jarDownloadHelper.downloadAll();

    assetDownloadHelper = AssetsDownloadHelper(await constructAssets(data), data.assetIndex!.sha1);
    await assetDownloadHelper.downloadAll();
	}

  static List<RemoteFile> constructLibraries(vanilla.VersionFiles data, String minecraftVersion) {
    List<RemoteFile> libraries = [data.downloads!.client];
    libraries.add(RemoteFile(data.assetIndex!.url, p.join("assets", "indexes", "$minecraftVersion.json"), data.assetIndex!.sha1, data.assetIndex!.size));

    for (var lib in data.libraries){
      libraries.addAll(determineDownloadable(lib));
    }

    return libraries;
  }

  static List<RemoteFile> determineDownloadable(vanilla.Library lib){
    List<RemoteFile> toDownload = [];

    if (ruleMatches(lib.rules)) {
      toDownload.add(lib.downloads.artifact);

      if (lib.natives != null && lib.downloads.classifiers != null){
        for (String os in getOS()){
          if (!lib.natives!.containsKey(os)) continue;
          String nativesClassifier = lib.natives![os]!;
          vanilla.Artifact? nativesArtifact = lib.downloads.classifiers![nativesClassifier];
          if (nativesArtifact != null){
            toDownload.add(nativesArtifact);
          }
        }
      }
      
    }

    return toDownload;
  }

  Future<List<RemoteFile>> constructAssets(vanilla.VersionFiles data) async {
    File indexFile = File(p.join(Locations.installDirectory, "assets", "indexes", "$minecraftVersion.json"));
    AssetIndexHolder indexData = AssetIndexHolder.fromJson(json.decode(await indexFile.readAsString()));
    List<RemoteFile> libs = List.of(indexData.objects.values);
    return libs;
  }

  static bool ruleMatches(List<vanilla.Rule>? rules){
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

  @override
  List<Problem> get errors => [...jarDownloadHelper.errors, ...assetDownloadHelper.errors];
}

List<String> getOS(){
  if (Platform.isMacOS) return ["osx", "macos"];
  if (Platform.isWindows) return ["windows"];
  if (Platform.isLinux) return ["linux"];
  return [];
}