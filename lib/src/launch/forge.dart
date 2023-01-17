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

class ForgeLauncher extends GameLauncher {
  late VersionFiles metadata;
  late VanillaLauncher vanilla;

  ForgeLauncher._create(String minecraftVersion, String loaderVersion, String gameDirectory): super.create(minecraftVersion, loaderVersion, gameDirectory);

  static Future<ForgeLauncher> create(String minecraftVersion, String loaderVersion, String gameDirectory) async {
    ForgeLauncher self = ForgeLauncher._create(minecraftVersion, loaderVersion, gameDirectory);
    await self.checkInstallation();
    self.metadata = await MetadataCache.forgeVersionData(minecraftVersion, loaderVersion);
    self.vanilla = await VanillaLauncher.create(minecraftVersion, gameDirectory, doInstalledCheck: false);
    return self;
  }

  @override
  String get modLoader => "forge";
  
  @override
  String get classpath {
    List<RemoteFile> forgeLaunchLibs = List.of(metadata.libraries.map((e) => e.downloads.artifact));

    // fixes java.lang.IllegalStateException: Duplicate key on 1.18.2
    // java-objc-bridge-1.0.0.jar shows up twice in the version json, one on its own and one with the natives but the normal artifact is there again as well 
    var jars = "${DownloadHelper.toClasspath(forgeLaunchLibs)}:${vanilla.classpath}".split(":").toSet();
    // var jars = "${vanilla.classpath}:${DownloadHelper.toClasspath(forgeLaunchLibs)}".split(":").toSet();  // crashes
    return jars.join(":");
  }

  Map<String, String> get replacements => super.replacements..addAll({
    "\${classpath_separator}": ":",
    "\${library_directory}": p.join(Locations.installDirectory, "libraries")
  });
  
  @override
  List<String> get jvmArgs => evalArgs(vanilla.metadata.arguments.jvm)..addAll(evalArgs(metadata.arguments.jvm));
  
  @override
  String get mainClass => metadata.mainClass;
  
  @override
  List<String> get minecraftArgs => evalArgs(vanilla.metadata.arguments.game)..addAll(evalArgs(metadata.arguments.game));
  
  @override
  GameInstaller get installer => ForgeInstaller(minecraftVersion, loaderVersion!);
}