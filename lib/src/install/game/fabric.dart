import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:bolt_launcher/src/install/util/problem.dart';
import 'package:bolt_launcher/src/install/util/remote_file.dart';
import 'package:path/path.dart' as p;

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/api_models/fabric_metadata.dart' as fabric;

mixin FabricInstallerSettings {
  String get defaultMavenUrl => GlobalOptions.metadataUrls.fabricMaven;

  Future<fabric.VersionList> get versionListMetadata => MetadataCache.fabricVersions;

  Future<fabric.VersionFiles> versionFilesMetadata(String minecraftVersion, String loaderVersion) async {
    return fabric.VersionFiles.fromJson(await cachedFetchJson("${GlobalOptions.metadataUrls.fabric}/versions/loader/$minecraftVersion/$loaderVersion", "fabric-$minecraftVersion-$loaderVersion.json"));
  } 

  String loaderName = "Fabric";
}

class FabricInstaller extends GameInstaller with FabricInstallerSettings {
  late VanillaInstaller vanilla;
  
  late DownloadHelper downloadHelper;

  FabricInstaller(String minecraftVersion, String loaderVersion) : super(minecraftVersion, loaderVersion) {
    vanilla = VanillaInstaller(minecraftVersion);
  }

  @override
  Future<bool> install() async {
    await vanilla.install();

    var metadata = await getMetadata();
    if (metadata == null){
			print("$loaderName $minecraftVersion $loaderVersion not found.");
			return false;
		}

    await download(metadata);
    return true;
  }

  Future<void> download(fabric.VersionFiles data) async {
    downloadHelper = DownloadHelper(await constructLibraries(data));
    await downloadHelper.downloadAll();
  }

  Future<List<RemoteFile>> constructLibraries(fabric.VersionFiles data) async {
    List<fabric.LibraryLocation> allLibs = [...data.launcherMeta.libraries.common];
    allLibs.addAll(data.launcherMeta.libraries.client);
    allLibs.add(fabric.LibraryLocation(data.loader.maven, "$defaultMavenUrl/"));

    print("Loading maven hashes.");
    List<RemoteFile> toDownload = await Future.wait(allLibs.map((lib) => lib.lib));
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
          return versionFilesMetadata(minecraftVersion, loaderVersion!);
        }
    }
    return null;
  }
}
