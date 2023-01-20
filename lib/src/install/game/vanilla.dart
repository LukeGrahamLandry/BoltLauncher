import 'dart:convert';
import 'dart:io' show Directory, File, Platform;
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart' as vanilla;
import 'package:bolt_launcher/src/install/util/meta_modifier.dart';
import 'package:bolt_launcher/src/loggers/event/base.dart';
import 'package:bolt_launcher/src/loggers/event/install.dart';
import 'package:bolt_launcher/src/loggers/logger.dart';
import 'package:bolt_launcher/src/install/util/remote_file.dart';
import 'package:crypto/crypto.dart';

import 'package:path/path.dart' as p;

void installVanilla(String versionId) async {
  await VanillaInstaller(versionId).install();
}

abstract class GameInstaller {
  String minecraftVersion;
  String? loaderVersion;
  String get modLoader;
  GameInstaller(this.minecraftVersion, this.loaderVersion);

  Future<bool> install();

  Future<bool> installVanilla() async {
    VanillaInstaller vanillaInstaller = VanillaInstaller(minecraftVersion, realLoader: modLoader);
    return await vanillaInstaller.install();
  }

  void log(InstallEvent event){
    event.init(modLoader, minecraftVersion, loaderVersion);
    Logger.instance.log(event);
  }
}

class VanillaInstaller extends GameInstaller {
  String realLoader;
	VanillaInstaller(String versionId, {this.realLoader = "vanilla"}) : super(versionId, null);

  @override
  String get modLoader => "vanilla";

  @override
	Future<bool> install() async {
    log(StartInstall());

		var metadata = await getMetadata(minecraftVersion);
    if (metadata == null){
     log(VersionNotFound());
			return false;
		}

    lwjglArmNatives(minecraftVersion, realLoader, metadata);
		await download(metadata);

    log(EndInstall());
    return true;
	}

  void check(Artifact lib){

  }

  static Future<vanilla.VersionFiles?> getMetadata(String versionId) async {
    vanilla.VersionList versionData = await MetadataCache.vanillaVersions;
		for (var version in versionData.versions){
        if (version.id == versionId) {
          var libs = vanilla.VersionFiles.fromJson(await cachedFetchJson(version.url, "vanilla/${version.id}.json"));
          libs.downloads!.client.version = versionId;
          libs.downloads!.client.name = "client";
          return libs;
        }
    }
    return null;
  }

	Future<void> download(vanilla.VersionFiles data) async {
    DownloadHelper jarDownloadHelper = DownloadHelper(constructLibraries(data, minecraftVersion));
    await jarDownloadHelper.downloadAll();

    DownloadHelper assetDownloadHelper = AssetsDownloadHelper(await constructAssets(data), data.assetIndex!.sha1);
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

    bool result = true;

    for (var rule in rules){
      String? os = rule.os?.name;
      // TODO: arch
      if (rule.action == "allow"){
        result = result && (os == null || getOS().contains(os));
      } else if (rule.action == "disallow"){
        if (os != null && getOS().contains(os)) result = false;
      }

    }
    return result;
  }
}

List<String> getOS(){
  if (Platform.isMacOS) return ["osx", "macos"];
  if (Platform.isWindows) return ["windows"];
  if (Platform.isLinux) return ["linux"];
  return [];
}