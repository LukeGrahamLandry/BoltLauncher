import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/install/downloader.dart';

import '../data/cache.dart';
import '../data/locations.dart';
import '../data/options.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import '../api_models/vanilla_metadata.dart' as vanilla;
import '../api_models/fabric_metadata.dart' as fabric;
import 'package:crypto/crypto.dart';

mixin FabricInstallerSettings {
  String get defaultMavenUrl => "https://maven.fabricmc.net/";

  Future<fabric.VersionList> get versionListMetadata => MetadataCache.fabricVersions;

  Future<fabric.VersionFiles> versionFilesMetadata(String minecraftVersion, String loaderVersion) async {
    return fabric.VersionFiles.fromJson(await cachedFetchJson("${GlobalOptions.metadataUrls.fabric}/v1/versions/loader/$minecraftVersion/$loaderVersion", "fabric-$minecraftVersion-$loaderVersion.json"));
  } 

  String loaderName = "Fabric";
}

class FabricInstaller with FabricInstallerSettings {
	String minecraftVersion;
  String loaderVersion;
	late PastDownloadManifest manifest;
  late VanillaInstaller vanilla;
  
  late DownloadHelper downloadHelper;

  FabricInstaller(this.minecraftVersion, this.loaderVersion) {
    vanilla = VanillaInstaller(minecraftVersion);
  }

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
    allLibs.add(fabric.LibraryLocation(data.loader.maven, defaultMavenUrl));  // TODO: dont hardcode url

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
}