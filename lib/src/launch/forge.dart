import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/game/forge.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/install/util/remote_file.dart';
import 'package:bolt_launcher/src/launch/base.dart';
import 'package:bolt_launcher/src/launch/vanilla.dart';
import 'package:path/path.dart' as p;

import '../api_models/vanilla_metadata.dart';

class ForgeLauncher extends VanillaLauncher {
  late VersionFiles metadata;

  ForgeLauncher(super.minecraftVersion, super.loaderVersion, super.gameDirectory);

  @override
  Future<void> loadMetadata() async {
    await super.loadMetadata();
    metadata = await MetadataCache.forgeVersionData(minecraftVersion, loaderVersion!);
  }

  @override
  String get modLoader => "forge";
  
  @override
  String get classpath {
    List<RemoteFile> forgeLaunchLibs = List.of(metadata.libraries.map((e) => e.downloads.artifact));

    // fixes java.lang.IllegalStateException: Duplicate key on 1.18.2
    // java-objc-bridge-1.0.0.jar shows up twice in the version json, one on its own and one with the natives but the normal artifact is there again as well 
    var jars = "${DownloadHelper.toClasspath(forgeLaunchLibs)}:${super.classpath}".split(":").toSet();
    // var jars = "${vanilla.classpath}:${DownloadHelper.toClasspath(forgeLaunchLibs)}".split(":").toSet();  // crashes
    return jars.join(":");
  }

  Map<String, String> get replacements => super.replacements..addAll({
    "\${classpath_separator}": ":",
    "\${library_directory}": p.join(Locations.installDirectory, "libraries")
  });
  
  @override
  List<String> get jvmArgs => super.jvmArgs..addAll(evalArgs(metadata.arguments.jvm));
  
  @override
  String get mainClass => metadata.mainClass;
  
  @override
  List<String> get minecraftArgs => super.minecraftArgs..addAll(evalArgs(metadata.arguments.game));
  
  @override
  GameInstaller get installer => ForgeInstaller(minecraftVersion, loaderVersion!);
}