import 'dart:convert';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

import '../../bolt_launcher.dart';
import 'vanilla.dart';
import 'package:path/path.dart' as p;

part 'manifiest.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: true)
class PastDownloadManifest {
	static String filename = "manifest.json";

    Map<String, String> vanillaLibs;  // name -> sha1

    PastDownloadManifest(this.vanillaLibs);

    factory PastDownloadManifest.fromJson(Map<String, dynamic> json) => _$PastDownloadManifestFromJson(json);
    Map<String, dynamic> toJson() => _$PastDownloadManifestToJson(this);

	static Map<String, dynamic> empty() {
		return PastDownloadManifest({}).toJson();
	}

	static Future<PastDownloadManifest> load(String directory) async {
        String manifestPath = p.join(directory, filename);
		return PastDownloadManifest.fromJson(await jsonObjectFile(manifestPath, PastDownloadManifest.empty()));
	}

	Future<void> save(String directory) async {
		String manifestPath = p.join(directory, filename);
		await writeJsonObjectFile(manifestPath, toJson());
	}
}