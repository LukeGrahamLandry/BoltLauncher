import 'dart:convert';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

import 'package:path/path.dart' as p;

import '../constants.dart';

part 'manifiest.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: true)
class PastDownloadManifest {
	static String filename = "manifest.json";

    Map<String, String> vanillaLibs;  // name -> sha1
    Map<int, int> curseforge;  // project id -> file id
    Map<String, String> modrinth;  // project id -> file id

    PastDownloadManifest(this.vanillaLibs, this.curseforge, this.modrinth);

    factory PastDownloadManifest.fromJson(Map<String, dynamic> json) => _$PastDownloadManifestFromJson(json);
    Map<String, dynamic> toJson() => _$PastDownloadManifestToJson(this);

	static Map<String, dynamic> empty() {
		return PastDownloadManifest({}, {}, {}).toJson();
	}

	static Future<PastDownloadManifest> load({String? path}) async {
    path ??= p.join(Constants.dataDirectory, "cache", filename);
		return PastDownloadManifest.fromJson(await jsonObjectFile(path, PastDownloadManifest.empty()));
	}

	Future<void> save({String? path}) async {
    path ??= p.join(Constants.dataDirectory, "cache", filename);
		await writeJsonObjectFile(path, toJson());
	}
}