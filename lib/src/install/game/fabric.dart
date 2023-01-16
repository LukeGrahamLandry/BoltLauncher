import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:bolt_launcher/src/loggers/event/install.dart';
import 'package:bolt_launcher/src/install/util/remote_file.dart';
import 'package:path/path.dart' as p;

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/api_models/fabric_metadata.dart' as fabric;

mixin FabricInstallerSettings {
  String get defaultMavenUrl => GlobalOptions.metadataUrls.fabricMaven;

  Future<fabric.VersionList> get versionListMetadata => MetadataCache.fabricVersions;

  Future<fabric.VersionFiles> versionFilesMetadata(String minecraftVersion, String loaderVersion) => MetadataCache.fabricVersionData(minecraftVersion, loaderVersion);  

  String loaderName = "Fabric";
}

class FabricInstaller extends GameInstaller with FabricInstallerSettings {
  FabricInstaller(String minecraftVersion, String loaderVersion) : super(minecraftVersion, loaderVersion);

  @override
  String get modLoader => loaderName.toLowerCase();

  @override
  Future<bool> install() async {
    log(StartInstall());
    await installVanilla();

    var metadata = await getMetadata();
    if (metadata == null){
			log(VersionNotFound());
			return false;
		}

    await download(metadata);

    log(EndInstall());
    return true;
  }

  Future<void> download(fabric.VersionFiles data) async {
    DownloadHelper downloadHelper = DownloadHelper(await constructLibraries(data));
    await downloadHelper.downloadAll();
  }

  Future<List<RemoteFile>> constructLibraries(fabric.VersionFiles data) async {
    List<fabric.LibraryLocation> allLibs = [...data.launcherMeta.libraries.common];
    allLibs.addAll(data.launcherMeta.libraries.client);
    allLibs.add(fabric.LibraryLocation(data.loader.maven, "$defaultMavenUrl/"));
    allLibs.add(fabric.LibraryLocation(data.intermediary.maven, "$defaultMavenUrl/"));

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
