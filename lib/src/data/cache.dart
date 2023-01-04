import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

import 'package:path/path.dart' as p;

import '../data/options.dart';
import 'package:http/http.dart' as http;
import '../api_models/vanilla_metadata.dart' as vanilla;
import '../api_models/fabric_metadata.dart' as fabric;

import 'locations.dart';

part 'cache.g.dart';


@JsonSerializable(explicitToJson: true, includeIfNull: true)
class PastDownloadManifest {
  static bool locked = false;
  Map<String, String> jarLibs;  // name -> sha1
  Map<String, String> curseforge;  // project-file -> download url
  Map<String, String> modrinth;
  Map<String, String> other;  // assets

  PastDownloadManifest(this.jarLibs, this.curseforge, this.modrinth, this.other);

  factory PastDownloadManifest.fromJson(Map<String, dynamic> json) => _$PastDownloadManifestFromJson(json);
  Map<String, dynamic> toJson() => _$PastDownloadManifestToJson(this);

	static Map<String, dynamic> empty() {
		return PastDownloadManifest({}, {}, {}, {}).toJson();
	}

	static Future<PastDownloadManifest> open() async {
    if (locked){
      throw Exception("Manifest file is locked.");
    }
    locked = true;
		return PastDownloadManifest.fromJson(await jsonObjectFile(Locations.manifestFile, PastDownloadManifest.empty()));
	}

	Future<void> close() async {
		await writeJsonObjectFile(Locations.manifestFile, toJson());
    locked = false;
	}

  quickSave() async {
    await writeJsonObjectFile(Locations.manifestFile, toJson());
  }
}

class MetadataCache {
  static Future<vanilla.VersionList> get vanillaVersions async {
     return vanilla.VersionList.fromJson(await cachedFetchJson(GlobalOptions.metadataUrls.vanilla, "vanilla-versions.json"));
  }

  static Future<fabric.VersionList> get fabricVersions async {
     return fabric.VersionList.fromJson(await cachedFetchJson("${GlobalOptions.metadataUrls.fabric}/versions", "fabric-versions.json"));
  }

  static Future<fabric.VersionList> get quiltVersions async {
    // 2023-01-04 https://meta.quiltmc.org/v3/versions does not return valid json.

    String loaderData = await cachedFetchText("${GlobalOptions.metadataUrls.quilt}/versions/loader", "quilt-loader-versions.json");
    List<fabric.LoaderVerson> loaderVersions = [];
    json.decode(loaderData).forEach((v) => loaderVersions.add(fabric.LoaderVerson.fromJson(v)));

    String gameData = await cachedFetchText("${GlobalOptions.metadataUrls.quilt}/versions/game", "quilt-game-versions.json");
    gameData = gameData.replaceFirst("][", ",");
    List<fabric.VanillaVersion> gameVersions = [];
    json.decode(gameData).forEach((v) => gameVersions.add(fabric.VanillaVersion.fromJson(v)));

    return fabric.VersionList(gameVersions, loaderVersions);
  }
}

Future<Map<String, dynamic>> cachedFetchJson(String url, String filename) async {
    return jsonDecode(await cachedFetchText(url, filename));
}

Future<String> cachedFetchText(String url, String filename) async {
    var sourcesPath = p.join(Locations.metadataCacheDirectory, "sources.json");
    var sources = await jsonObjectFile(sourcesPath, {});
    var file = File(p.join(Locations.metadataCacheDirectory, filename));

    bool needsFetch = !(await file.exists()) || (sources[filename] != url && sources[filename] != "");
    if (needsFetch){
        await file.create(recursive: true);
        print("Fetching $url");
        var response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
            throw Exception('Failed to load $url');  // TODO
        } 
        await file.writeAsString(response.body);

        sources[filename] = url;
        writeJsonObjectFile(sourcesPath, sources);
    } else {
      print("Using cached $filename");
    }

    return await file.readAsString();
}

Future<Map<String, dynamic>> jsonObjectFile(String path, Map<String, dynamic> defaultData) async {
    var file = File(path);
    if (!(await file.exists())){
        await file.create(recursive: true);
        await writeJsonObjectFile(path, defaultData);
    }

    return jsonDecode(await file.readAsString());
}

Future<void> writeJsonObjectFile(String path, Map<String, dynamic> data) async {
    var file = File(path);
    if (!(await file.exists())){
        await file.create(recursive: true);
    }
    file.writeAsString(JsonEncoder.withIndent('  ').convert(data));
}

