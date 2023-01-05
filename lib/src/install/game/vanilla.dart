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

abstract class MinecraftInstaller {
  String get versionId;
  String get launchClassPath;
  Future<String> get launchMainClass;
  List<Problem> get errors;
  Future<void> install();
}

class VanillaInstaller implements MinecraftInstaller {
  @override
	String versionId;
  bool hashChecking;
  late DownloadHelper jarDownloadHelper;
  late DownloadHelper assetDownloadHelper;

	VanillaInstaller(this.versionId, {this.hashChecking=true});

  @override
	Future<void> install() async {
		var metadata = await getMetadata();
    if (metadata == null){
			print("Minecraft version $versionId was not found. ");
			return;
		}

		await download(metadata);
	}

  Future<vanilla.VersionFiles?> getMetadata() async {
    vanilla.VersionList versionData = await MetadataCache.vanillaVersions;
		for (var version in versionData.versions){
        if (version.id == versionId) {
          var libs = vanilla.VersionFiles.fromJson(await cachedFetchJson(version.url, "vanilla-${version.id}.json"));
          libs.downloads.client.version = versionId;
          libs.downloads.client.name = "client";
          return libs;
        }
    }
    return null;
  }

	Future<void> download(vanilla.VersionFiles data) async {
    jarDownloadHelper = DownloadHelper(constructLibraries(data));
    await jarDownloadHelper.downloadAll();

    assetDownloadHelper = AssetsDownloadHelper(await constructAssets(data), data.assetIndex.sha1);
    await assetDownloadHelper.downloadAll();
	}

  List<RemoteFile> constructLibraries(vanilla.VersionFiles data) {
    List<RemoteFile> libraries = [data.downloads.client];
    libraries.add(RemoteFile(data.assetIndex.url, p.join("assets", "indexes", "$versionId.json"), data.assetIndex.sha1, data.assetIndex.size));

    for (var lib in data.libraries){
      libraries.addAll(determineDownloadable(lib));
    }

    return libraries;
  }

  List<RemoteFile> determineDownloadable(vanilla.Library lib){
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
    File indexFile = File(p.join(Locations.installDirectory, "assets", "indexes", "$versionId.json"));
    AssetIndexHolder indexData = AssetIndexHolder.fromJson(json.decode(await indexFile.readAsString()));
    List<RemoteFile> libs = List.of(indexData.objects.values);
    return libs;
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

  @override
  String get launchClassPath => jarDownloadHelper.classPath;

  @override
  Future<String> get launchMainClass async {
    return (await getMetadata())!.mainClass;
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