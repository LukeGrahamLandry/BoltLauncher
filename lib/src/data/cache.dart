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
  Map<String, String> modrinth;  // project id -> file id

  PastDownloadManifest(this.jarLibs, this.curseforge, this.modrinth);

  factory PastDownloadManifest.fromJson(Map<String, dynamic> json) => _$PastDownloadManifestFromJson(json);
  Map<String, dynamic> toJson() => _$PastDownloadManifestToJson(this);

	static Map<String, dynamic> empty() {
		return PastDownloadManifest({}, {}, {}).toJson();
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
}

class MetadataCache {
  static Future<vanilla.VersionList> get vanillaVersions async {
     return vanilla.VersionList.fromJson(await cachedFetch(GlobalOptions.metadataUrls.vanillaVersions, "vanilla-versions.json"));
  }

  static Future<fabric.VersionList> get fabricVersions async {
     return fabric.VersionList.fromJson(await cachedFetch("${GlobalOptions.metadataUrls.fabric}/v1/versions", "fabric-versions.json"));
  }
}

Future<Map<String, dynamic>> cachedFetch(String url, String filename) async {
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
        await writeJsonObjectFile(sourcesPath, sources);   
    } else {
      print("Using cached $filename");
    }

    return jsonDecode(await file.readAsString());
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
    file.writeAsString(json.encode(data));
}

