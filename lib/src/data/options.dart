import 'dart:io' show File, FileMode, Platform;
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:convert';

class GlobalOptions {
  static bool recomputeHashesOnStart = false;
  static MetaSources metadataUrls = MetaSources.initial();
}

class MetaSources {
  String vanillaVersions = "https://launchermeta.mojang.com/mc/game/version_manifest.json";

  MetaSources(this.vanillaVersions);

  MetaSources.initial();
}
