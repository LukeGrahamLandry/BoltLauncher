import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/game/forge.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/install/util/remote_file.dart';
import 'package:bolt_launcher/src/launch/vanilla.dart';
import 'package:path/path.dart' as p;

import '../api_models/vanilla_metadata.dart';
import '../loggers/launch.dart';

class ForgeLauncher extends GameLauncher {
  late VersionFiles metadata;
  late VanillaLauncher vanilla;

  ForgeLauncher._create(String minecraftVersion, String loaderVersion, String gameDirectory): super.create(minecraftVersion, loaderVersion, gameDirectory);

  static Future<ForgeLauncher> create(String minecraftVersion, String loaderVersion, String gameDirectory) async {
    ForgeLauncher self = ForgeLauncher._create(minecraftVersion, loaderVersion, gameDirectory);
    self.logger = LaunchLogger("forge", minecraftVersion, gameDirectory);
    await self.checkInstallation();
    self.metadata = await MetadataCache.forgeVersionData(minecraftVersion, loaderVersion);
    self.vanilla = await VanillaLauncher.create(minecraftVersion, gameDirectory, doInstalledCheck: false);
    return self;
  }
  
  @override
  String get classpath {
    List<RemoteFile> forgeLaunchLibs = List.of(metadata.libraries.map((e) => e.downloads.artifact));

    // fixes java.lang.IllegalStateException: Duplicate key on 1.18.2
    // java-objc-bridge-1.0.0.jar shows up twice in the version json, one on its own and one with the natives but the normal artifact is there again as well 
    var jars = "${DownloadHelper.toClasspath(forgeLaunchLibs)}:${vanilla.classpath}".split(":").toSet();
    // var jars = "${vanilla.classpath}:${DownloadHelper.toClasspath(forgeLaunchLibs)}".split(":").toSet();  // crashes
    return jars.join(":");
  }
  
  @override
  List<String> get jvmArgs {
    List<String> args = [];

    metadata.arguments.jvm.forEach((element) {
      if (element is String){
        element = element.replaceAll("\${library_directory}", p.join(Locations.installDirectory, "libraries"));
        element = element.replaceAll("\${classpath_separator}", ":");
        element = element.replaceAll("\${version_name}", minecraftVersion); 
        args.add(element);
      }
    });

    args.addAll([
      "-XstartOnFirstThread",  // macos only?
      "-Dfml.earlyprogresswindow=false",
      // "-Djava.library.path=${p.join(Locations.installDirectory, "bin", minecraftVersion)}",
      "-cp",
      classpath
    ]);

    return args;
  }
  
  @override
  String get mainClass => metadata.mainClass;
  
  @override
  List<String> get minecraftArgs {  // TODO: parse the map entries properly
    List<dynamic> args = [...metadata.arguments.game];
    args.removeWhere((element) => element is! String);
    return [...vanilla.minecraftArgs, ...args];
  }
  
  @override
  GameInstaller get installer => ForgeInstaller(minecraftVersion, loaderVersion!);
}