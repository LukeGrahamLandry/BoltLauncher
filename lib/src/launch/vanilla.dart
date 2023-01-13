import 'dart:convert';
import 'dart:io' show Directory, File, Platform, Process;
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart' as vanilla;
import 'package:bolt_launcher/src/loggers/launch.dart';
import 'package:bolt_launcher/src/loggers/problem.dart';
import 'package:bolt_launcher/src/install/util/remote_file.dart';

import 'package:path/path.dart' as p;


abstract class GameLauncher {
  String minecraftVersion;
  String? loaderVersion;
  String gameDirectory;
  late LaunchLogger logger;
  GameLauncher.create(this.minecraftVersion, this.loaderVersion, this.gameDirectory);

  String get classpath;
  String get mainClass;
  List<String> get minecraftArgs;
  List<String> get jvmArgs;
  GameInstaller get installer;

  Future<void> checkInstallation() async {
    installer.logger = logger.installLogger;
    await installer.install();
  }

  Future<Process> launch(String javaExecutable) async {
    List<String> args = [...jvmArgs, mainClass, ...minecraftArgs];
    logger.start(javaExecutable, args);
    return Process.start(javaExecutable, args, workingDirectory: gameDirectory);
  }
}

class VanillaLauncher extends GameLauncher {
  late VersionFiles metadata;

  VanillaLauncher._create(String minecraftVersion, String gameDirectory): super.create(minecraftVersion, null, gameDirectory);

  static Future<VanillaLauncher> create(String minecraftVersion, String gameDirectory, {bool doInstalledCheck = true}) async {
    VanillaLauncher self = VanillaLauncher._create(minecraftVersion, gameDirectory);
    self.logger = LaunchLogger("vanilla", minecraftVersion, gameDirectory);
    if (doInstalledCheck) await self.checkInstallation();
    self.metadata = (await VanillaInstaller.getMetadata(minecraftVersion))!;
    return self;
  }

  @override
  List<String> get jvmArgs {  // TODO: read from metadata
    return [
      "-XstartOnFirstThread",  // macos only?
      // "-Djava.library.path=${p.join(Locations.installDirectory, "bin", minecraftVersion)}",
      "-cp",
      classpath
    ];
  }

  @override
  List<String> get minecraftArgs {   // TODO: read from metadata
    return [
      "--version",
      minecraftVersion, 
      "--gameDir",
      gameDirectory,
      "--assetsDir",
      p.join(Locations.installDirectory, "assets"),
      "--assetIndex",
      minecraftVersion,  //  TODO: i think vanilla only calls it major.minor.json
      "--accessToken",
      "", // TODO
    ];
  }
  
  @override
  String get mainClass => metadata.mainClass;

  @override
  String get classpath => DownloadHelper.toClasspath(VanillaInstaller.constructLibraries(metadata, minecraftVersion));
  
  @override
  GameInstaller get installer => VanillaInstaller(minecraftVersion);
}
