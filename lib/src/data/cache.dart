import 'dart:convert';
import 'dart:io';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart' as vanilla;
import 'package:bolt_launcher/src/api_models/fabric_metadata.dart' as fabric;
import 'package:bolt_launcher/src/api_models/prism_metadata.dart' as prism;
import 'package:bolt_launcher/src/api_models/forge_metadata.dart' as forge;

part 'cache.g.dart';


@JsonSerializable(explicitToJson: true, includeIfNull: true)
class PastDownloadManifest {
  static bool locked = false;
  Map<String, String> jarLibs;  // name -> sha1
  Map<String, String> curseforge;
  List<String> fullyInstalledAssetIndexes; 

  PastDownloadManifest(this.jarLibs, this.curseforge, this.fullyInstalledAssetIndexes);

  factory PastDownloadManifest.fromJson(Map<String, dynamic> json) => _$PastDownloadManifestFromJson(json);
  Map<String, dynamic> toJson() => _$PastDownloadManifestToJson(this);

	static Map<String, dynamic> empty() {
		return PastDownloadManifest({}, {}, []).toJson();
	}

	static Future<PastDownloadManifest> open() async {
    // if (locked){
    //   throw Exception("Manifest file is locked.");
    // }
    locked = true;
    Map<String, dynamic> data = await jsonObjectFile(Locations.manifestFile, PastDownloadManifest.empty());
		return PastDownloadManifest.fromJson(data);
	}

	Future<void> close() async {
		// await writeJsonObjectFile(Locations.manifestFile, toJson());
    locked = false;
	}

  quickSave() async {
    // await writeJsonObjectFile(Locations.manifestFile, toJson());
  }
}

class MetadataCache {
  static Future<vanilla.VersionList> get vanillaVersions async {
     return vanilla.VersionList.fromJson(await cachedFetchJson(GlobalOptions.metadataUrls.vanilla, "vanilla/versions.json"));
  }

  static Future<fabric.VersionList> get fabricVersions async {
     return fabric.VersionList.fromJson(await cachedFetchJson("${GlobalOptions.metadataUrls.fabric}/versions", "fabric/versions.json"));
  }

  static Future<fabric.VersionList> get quiltVersions async {
    return fabric.VersionList.fromJson(await cachedFetchJson("${GlobalOptions.metadataUrls.quilt}/versions", "quilt/versions.json"));
  }

  static Future<Map<String, String>> get forgeRecommendedVersions async {
    return ((await cachedFetchJson("${GlobalOptions.metadataUrls.forge}/promotions_slim.json", "forge/versions-slim.json"))["promos"] as Map).map((key, value) => MapEntry(key, value as String));
  }

  static Future<fabric.VersionFiles> quiltVersionData(String minecraftVersion, String loaderVersion) async {
    return fabric.VersionFiles.fromJson(await cachedFetchJson("${GlobalOptions.metadataUrls.quilt}/versions/loader/$minecraftVersion/$loaderVersion", "quilt/quilt-loader-$loaderVersion-$minecraftVersion.json"));
  }

  static Future<fabric.VersionFiles> fabricVersionData(String minecraftVersion, String loaderVersion) async {
    return fabric.VersionFiles.fromJson(await cachedFetchJson("${GlobalOptions.metadataUrls.fabric}/versions/loader/$minecraftVersion/$loaderVersion", "fabric/fabric-loader-$loaderVersion-$minecraftVersion.json"));
  }

  static Future<forge.InstallProfile> forgeInstallProfile(String minecraftVersion, String loaderVersion) async {
    File file = File(p.join(Locations.metadataCacheDirectory, "forge/$loaderVersion-install_profile.json"));
    if (!(await file.exists())) await ForgeInstaller.extractInstallerMetadata(minecraftVersion, loaderVersion);
    return forge.InstallProfile.fromJson(json.decode(await file.readAsString()));
  }

  static Future<vanilla.VersionFiles> forgeVersionData(String minecraftVersion, String loaderVersion) async {
    File file = File(p.join(Locations.metadataCacheDirectory, "forge/$minecraftVersion-forge-$loaderVersion.json"));
    if (!(await file.exists())) await ForgeInstaller.extractInstallerMetadata(minecraftVersion, loaderVersion);
    return vanilla.VersionFiles.fromJson(json.decode(await file.readAsString()));
  }
}

Future<Map<String, dynamic>> cachedFetchJson(String url, String filename) async {
  String data = await cachedFetchText(url, filename);
  return jsonDecode(data);
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

    String result = await file.readAsString();
    // print(url);
    // print(result);
    return result;
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

