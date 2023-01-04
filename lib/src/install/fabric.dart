import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/install/util.dart';

import '../data/cache.dart';
import '../data/locations.dart';
import '../data/options.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import '../api_models/vanilla_metadata.dart' as vanilla;
import '../api_models/fabric_metadata.dart' as fabric;
import 'package:crypto/crypto.dart';

class FabricInstaller {
	String minecraftVersion;
  String fabricLoaderVersion;
	late PastDownloadManifest manifest;
  late VanillaInstaller vanilla;

  FabricInstaller(this.minecraftVersion, this.fabricLoaderVersion) {
    vanilla = VanillaInstaller(minecraftVersion);
  }

  Future<void> install() async {
    await vanilla.install();

    var metadata = await getMetadata();
    if (metadata == null){
			print("Fabric $minecraftVersion $fabricLoaderVersion not found.");
			return;
		}

    await download(metadata);

  }

  Future<void> download(fabric.VersionFiles data) async {
    List<fabric.LibraryLocation> allLibs = [...data.launcherMeta.libraries.common];
    allLibs.addAll(data.launcherMeta.libraries.client);
    allLibs.add(fabric.LibraryLocation(data.loader.maven, "https://maven.fabricmc.net/"));  // TODO: dont hardcode url

    print("Loading maven hashes.");
    await Future.wait(allLibs.map((lib) => lib.fetchHash()));

    DownloadHelper().downloadAll(allLibs);
  }

  Future<fabric.VersionFiles?> getMetadata() async {
    fabric.VersionList versionData = await MetadataCache.fabricVersions;

    bool mcVersionSupported = false;
    for (var version in versionData.game){
      if (version.version == minecraftVersion){
        mcVersionSupported = true;
        break;
      }
    }

    if (!mcVersionSupported){
      print("Fabric does not support $minecraftVersion");
      return null;
    }

		for (var version in versionData.loader){
        if (version.version == fabricLoaderVersion) {
          var libs = fabric.VersionFiles.fromJson(await cachedFetch("${GlobalOptions.metadataUrls.fabric}/v1/versions/loader/$minecraftVersion/$fabricLoaderVersion", "fabric-$minecraftVersion-$fabricLoaderVersion.json"));
          return libs;
        }
    }
    return null;
  }
}