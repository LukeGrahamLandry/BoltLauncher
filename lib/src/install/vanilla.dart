import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/install/downloader.dart';

import '../api_models/vanilla_metadata.dart';
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

abstract class MinecraftInstaller {
  String get versionId;
  String get launchClassPath;
  Future<String> get launchMainClass;
  List<HashError> get errors;
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

    assetDownloadHelper = DownloadHelper(await constructAssets(data));
    await assetDownloadHelper.downloadAll();
	}

  List<LibFile> constructLibraries(vanilla.VersionFiles data) {
    List<LibFile> libraries = [data.downloads.client];
    libraries.add(LibFile(data.assetIndex.url, p.join("assets", "indexes", "$versionId.json"), data.assetIndex.sha1));

    for (var lib in data.libraries){
      libraries.addAll(determineDownloadable(lib));
    }

    return libraries;
  }

  List<LibFile> determineDownloadable(vanilla.Library lib){
    List<LibFile> toDownload = [];

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

  Future<List<LibFile>> constructAssets(vanilla.VersionFiles data) async {
    File indexFile = File(p.join(Locations.installDirectory, "assets", "indexes", "$versionId.json"));
    AssetIndexHolder indexData = AssetIndexHolder.fromJson(json.decode(await indexFile.readAsString()));
    return List.of(indexData.objects.values);
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
  List<HashError> get errors => jarDownloadHelper.errors;
}

List<String> getOS(){
  if (Platform.isMacOS) return ["osx", "macos"];
  if (Platform.isWindows) return ["windows"];
  if (Platform.isLinux) return ["linux"];
  return [];
}