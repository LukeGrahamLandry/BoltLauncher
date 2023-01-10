import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:bolt_launcher/src/install/game/fabric.dart';
import 'package:path/path.dart' as p;

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/api_models/fabric_metadata.dart' as fabric;


mixin QuiltInstallerSettings on FabricInstallerSettings {
  @override
  String get defaultMavenUrl => GlobalOptions.metadataUrls.quiltMaven;

  @override
  Future<fabric.VersionList> get versionListMetadata => MetadataCache.quiltVersions;

  @override
  Future<fabric.VersionFiles> versionFilesMetadata(String minecraftVersion, String loaderVersion) async {
    return fabric.VersionFiles.fromJson(await cachedFetchJson("${GlobalOptions.metadataUrls.quilt}/versions/loader/$minecraftVersion/$loaderVersion", "quilt-$minecraftVersion-$loaderVersion.json"));
  }

  @override
  String loaderName = "Quilt";
}

class QuiltInstaller extends FabricInstaller with QuiltInstallerSettings {
  QuiltInstaller(super.minecraftVersion, super.loaderVersion);
}
