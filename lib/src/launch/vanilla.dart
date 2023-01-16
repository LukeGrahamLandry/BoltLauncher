import 'dart:convert';
import 'dart:io' show Directory, File, Platform, Process;
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart' as vanilla;
import 'package:bolt_launcher/src/loggers/event/launch.dart';
import 'package:bolt_launcher/src/loggers/logger.dart';
import 'package:bolt_launcher/src/install/util/remote_file.dart';

import 'package:path/path.dart' as p;


abstract class GameLauncher {
  String minecraftVersion;
  String? loaderVersion;
  String gameDirectory;
  GameLauncher.create(this.minecraftVersion, this.loaderVersion, this.gameDirectory);

  String get classpath;
  String get mainClass;
  List<String> get minecraftArgs;
  List<String> get jvmArgs;
  GameInstaller get installer;
  String get modLoader;

  Future<void> checkInstallation() async {
    await installer.install();
  }

  Future<Process> launch(String javaExecutable) async {
    List<String> args = [...jvmArgs, mainClass, ...minecraftArgs];
    log(StartGameProcess(gameDirectory, javaExecutable, args));
    // TODO: log listens to stdout and stderr
    return Process.start(javaExecutable, args, workingDirectory: gameDirectory);
  }

  void log(LaunchEvent event){
    event.init(modLoader, minecraftVersion, loaderVersion);
    Logger.instance.log(event);
  }
}

class VanillaLauncher extends GameLauncher {
  late VersionFiles metadata;

  VanillaLauncher._create(String minecraftVersion, String gameDirectory): super.create(minecraftVersion, null, gameDirectory);

  static Future<VanillaLauncher> create(String minecraftVersion, String gameDirectory, {bool doInstalledCheck = true}) async {
    VanillaLauncher self = VanillaLauncher._create(minecraftVersion, gameDirectory);
    if (doInstalledCheck) await self.checkInstallation();
    self.metadata = (await VanillaInstaller.getMetadata(minecraftVersion))!;
    return self;
  }

  @override
  String get modLoader => "vanilla";

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
