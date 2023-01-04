import 'dart:io' show File, FileMode, Platform;
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:convert';

class GlobalOptions {
  static bool recomputeHashesOnStart = false;
  // static bool checkSignaturesOnDownload = true;  // TODO
  // static String pgpCommand = "gpg"

  static MetaSources metadataUrls = MetaSources.initial();
}

class MetaSources {
  String vanilla = "https://launchermeta.mojang.com/mc/game/version_manifest.json";
  String curseMaven = "https://www.cursemaven.com/test";
  String fabric = "https://meta.fabricmc.net";
  String quilt = "https://meta.quiltmc.org";
  String assets = "https://resources.download.minecraft.net";

  MetaSources(this.vanilla);

  MetaSources.initial();
}
