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

import 'fabric.dart';

mixin QuiltInstallerSettings on FabricInstallerSettings {
  @override
  String get defaultMavenUrl => "https://maven.quiltmc.org/repository/release/";

  @override
  Future<fabric.VersionList> get versionListMetadata => MetadataCache.quiltVersions;

  @override
  Future<fabric.VersionFiles> versionFilesMetadata(String minecraftVersion, String loaderVersion) async {
    return fabric.VersionFiles.fromJson(await cachedFetchJson("${GlobalOptions.metadataUrls.quilt}/v3/versions/loader/$minecraftVersion/$loaderVersion", "quilt-$minecraftVersion-$loaderVersion.json");
  }

  @override
  String loaderName = "Quilt";
}

class QuiltInstaller extends FabricInstaller with QuiltInstallerSettings {
  QuiltInstaller(super.minecraftVersion, super.loaderVersion);
}
