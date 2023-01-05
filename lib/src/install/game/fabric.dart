import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:path/path.dart' as p;

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/downloader.dart';
import 'package:bolt_launcher/src/api_models/fabric_metadata.dart' as fabric;

mixin FabricInstallerSettings {
  String get defaultMavenUrl => GlobalOptions.metadataUrls.fabricMaven;

  Future<fabric.VersionList> get versionListMetadata => MetadataCache.fabricVersions;

  Future<fabric.VersionFiles> versionFilesMetadata(String minecraftVersion, String loaderVersion) async {
    return fabric.VersionFiles.fromJson(await cachedFetchJson("${GlobalOptions.metadataUrls.fabric}/versions/loader/$minecraftVersion/$loaderVersion", "fabric-$minecraftVersion-$loaderVersion.json"));
  } 

  String loaderName = "Fabric";
}

class FabricInstaller with FabricInstallerSettings implements MinecraftInstaller {
	String minecraftVersion;
  String loaderVersion;
	late PastDownloadManifest manifest;
  late VanillaInstaller vanilla;
  
  late DownloadHelper downloadHelper;

  FabricInstaller(this.minecraftVersion, this.loaderVersion) {
    vanilla = VanillaInstaller(minecraftVersion);
  }

  @override
  Future<void> install() async {
    await vanilla.install();

    var metadata = await getMetadata();
    if (metadata == null){
			print("$loaderName $minecraftVersion $loaderVersion not found.");
			return;
		}

    await download(metadata);
  }

  Future<void> download(fabric.VersionFiles data) async {
    downloadHelper = DownloadHelper(await constructLibraries(data));
    await downloadHelper.downloadAll();
  }

  Future<List<LibFile>> constructLibraries(fabric.VersionFiles data) async {
    List<fabric.LibraryLocation> allLibs = [...data.launcherMeta.libraries.common];
    allLibs.addAll(data.launcherMeta.libraries.client);
    allLibs.add(fabric.LibraryLocation(data.loader.maven, "$defaultMavenUrl/"));

    print("Loading maven hashes.");
    List<LibFile> toDownload = await Future.wait(allLibs.map((lib) => lib.lib));

    return toDownload;
  }

  Future<fabric.VersionFiles?> getMetadata() async {
    fabric.VersionList versionData = await versionListMetadata;

    bool mcVersionSupported = false;
    for (var version in versionData.game){
      if (version.version == minecraftVersion){
        mcVersionSupported = true;
        break;
      }
    }

    if (!mcVersionSupported){
      print("$loaderName does not support $minecraftVersion");
      return null;
    }

		for (var version in versionData.loader){
        if (version.version == loaderVersion) {
          return versionFilesMetadata(minecraftVersion, loaderVersion);
        }
    }
    return null;
  }
  
  @override
  String get launchClassPath => "${downloadHelper.classPath}:${vanilla.jarDownloadHelper.classPath}";

  @override
  Future<String> get launchMainClass async {
    return (await getMetadata())!.launcherMeta.mainClass.client;
  }

  @override
  String get versionId => vanilla.versionId;

  @override
  List<Problem> get errors => downloadHelper.errors + vanilla.jarDownloadHelper.errors;
}