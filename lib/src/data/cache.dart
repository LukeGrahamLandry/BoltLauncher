import 'dart:convert';
import 'dart:io';
import 'package:bolt_launcher/src/api_models/java_metadata.dart';
import 'package:bolt_launcher/src/install/util/remote_file.dart';
import 'package:bolt_launcher/src/loggers/logger.dart';
import 'package:crypto/crypto.dart';
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
  static Duration get versionsCacheTime => Duration(seconds: GlobalOptions.versionListCacheSeconds);

  static Future<vanilla.VersionList> get vanillaVersions async {
     return vanilla.VersionList.fromJson(await cachedFetchJson(GlobalOptions.metadataUrls.vanilla, "vanilla/versions.json", cacheTime: versionsCacheTime));
  }

  static Future<fabric.VersionList> get fabricVersions async {
     return fabric.VersionList.fromJson(await cachedFetchJson("${GlobalOptions.metadataUrls.fabric}/versions", "fabric/versions.json", cacheTime: versionsCacheTime));
  }

  static Future<fabric.VersionList> get quiltVersions async {
    return fabric.VersionList.fromJson(await cachedFetchJson("${GlobalOptions.metadataUrls.quilt}/versions", "quilt/versions.json", cacheTime: versionsCacheTime));
  }

  static Future<Map<String, String>> get forgeRecommendedVersions async {
    Map data = await cachedFetchJson("${GlobalOptions.metadataUrls.forge}/promotions_slim.json", "forge/versions-slim.json", cacheTime: versionsCacheTime);
    return (data["promos"] as Map).map((key, value) => MapEntry(key, value as String));
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

  static Future<List<JavaInfo>> get localJavaInstalls async {
    File file = File(Locations.javaInstallationsList);
    if (!(await file.exists())) return [];

    List<JavaInfo> results = [];
    try {
      json.decode(await file.readAsString()).forEach((e) => results.add(JavaInfo.fromJson(e)));
    } catch (e) {
      return [];
    }
    
    return results;
  }
}

Future<Map<String, dynamic>> cachedFetchJson(String url, String filename, {Duration? cacheTime}) async {
  String data = await cachedFetchText(url, filename, cacheTime);
  return jsonDecode(data);
}

Future<String> cachedFetchText(String url, String filename, Duration? cacheTime) async {
    var sourcesPath = p.join(Locations.metadataCacheDirectory, "sources.json");
    var sources = await jsonObjectFile(sourcesPath, {});
    var file = File(p.join(Locations.metadataCacheDirectory, filename));

    bool needsFetch = !(await file.exists()) || (sources[filename]?["url"] != url && sources[filename]?["url"] != "");
    bool ignoreFailedRequest = false;
    if (!needsFetch && cacheTime != null){
      int msSinceLastFetched = DateTime.now().millisecondsSinceEpoch - sources[filename]!["time"]! as int;
      if (msSinceLastFetched > cacheTime.inMilliseconds){
        needsFetch = true;
        ignoreFailedRequest = true;
      }
    }

    if (needsFetch){
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200){
        await file.create(recursive: true);
        await file.writeAsString(response.body);

        sources[filename] = {
          "url": url,
          "time": DateTime.now().millisecondsSinceEpoch,
          "sha1": sha1.convert(response.bodyBytes).toString()
        };

        await appendJsonObjectFile(sourcesPath, sources);
      } else if (!ignoreFailedRequest) {
        throw Exception('Failed to load $url');  // TODO: support fallback meta servers 
      }
    }

    String result = await file.readAsString();
    return result;
}

Future<Map<String, dynamic>> jsonObjectFile(String path, Map<String, dynamic> defaultData) async {
    var file = File(path);
    if (!(await file.exists())){
        await file.create(recursive: true);
        await writeJsonObjectFile(path, defaultData);
    }

    String data = await file.readAsString();
    try {
      return jsonDecode(data);
    } catch (e) {
      print("Failed to parse $path as json");
      print(data);
      await writeJsonObjectFile(path, defaultData);
      return defaultData;
    }
}

Future<void> writeJsonObjectFile(String path, Map<String, dynamic> data) async {
    var file = File(path);
    if (!(await file.exists())){
        await file.create(recursive: true);
    }
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(data));
}

class LockFile {
  static List<String> all = []; // TODO: should clean these up somehow if the user force quits
  String path;

  LockFile(this.path);

  Future<void> lock() async {
    File lock = File("$path.lock");
    while (await lock.exists()){
      await Future.delayed(Duration(milliseconds: 100));
      print("waiting for unlocked $path");
    }

    lock.createSync(recursive: true);
  }

  void unlock(){
    File lock = File("$path.lock");
    if (lock.existsSync()) lock.deleteSync();
  }
}

Future<void> appendJsonObjectFile(String path, Map<String, dynamic> data) async {
  File file = File(path);
  LockFile lock = LockFile(path);
  await lock.lock();

  if (file.existsSync()){
    Map<String, dynamic> oldData = await jsonObjectFile(path, {});
    oldData.addAll(data);
    await writeJsonObjectFile(path, oldData);
  } else {
    await writeJsonObjectFile(path, data);
  }

  lock.unlock();
}

class MavenHashCache {
  static String path = p.join(Locations.metadataCacheDirectory, "maven-hashes.json");

  /// maven descriptor -> sha1 hash
  /// since the key doesn't include the repository url it would get confusing if someone was lying and then you switched repos
  /// TODO: changing your repo url in meta might want to invlidate the cache
  /// or if it has a mismatch and refetches file it should also refresh the hash 
  /// so it wont just keep redownloading if the file got swapped out but should log something scary cause that's sketchy
  static Map<String, String> cache = {};

  static Future<void> load() async {
    Map<String, dynamic> data = await jsonObjectFile(path, {});
    cache = data.map((key, value) => MapEntry(key, value as String));
  }

  static Future<void> save() async {
    await appendJsonObjectFile(path, cache);
  }

  
  static Future<void> resolve(MavenFile file) async {
    file.sha1 = cache[file.artifact.descriptor] ?? await file.artifact.sha1;
    cache[file.artifact.descriptor] ??= file.sha1;
  }
}

Future<void> lockedAppend(String path, String data) async {
  File file = File(path);
  LockFile lock = LockFile(path);

  await lock.lock();

  if (!(await file.exists())){
    await file.create(recursive: true);
  }

  await file.writeAsString(data, mode: FileMode.append);
  await file.writeAsString("\n", mode: FileMode.append);

  lock.unlock();
}

Future<void> loadAllCaches() async {
  await MavenHashCache.load();
}

Future<void> saveAllCaches() async {
  await MavenHashCache.save();

  if (Logger.executablesDownloadHistory.isNotEmpty){
    String location = p.join(Locations.dataDirectory, "executables-download-history.csv");
    await lockedAppend(location, Logger.executablesDownloadHistory.join("\n"));
  }
}