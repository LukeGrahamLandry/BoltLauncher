import 'dart:convert';
import 'dart:io' show File, Platform, Process;
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart' as vanilla;
import 'package:bolt_launcher/src/install/util/problem.dart';
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

  Future<void> checkInstallation() async {
    print("Checking installation...");
    int startTime = DateTime.now().millisecondsSinceEpoch;
    await installer.install();
    int endTime = DateTime.now().millisecondsSinceEpoch;
    print("Full installation check finished in ${(endTime - startTime) / 1000} seconds.");
  }

  Future<Process> launch(String javaExecutable) async {
    List<String> args = [...jvmArgs, mainClass, ...minecraftArgs];
    String startCommandLogLocation = p.join(gameDirectory, "launch.sh");
    File(startCommandLogLocation).writeAsString("cd $gameDirectory && $javaExecutable ${args.join(" ")}");
    await Process.run("chmod", ["-v", "777", startCommandLogLocation]);
    return Process.start(javaExecutable, args, workingDirectory: gameDirectory);
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
  List<String> get jvmArgs {  // TODO: read from metadata
    return [
      "-XstartOnFirstThread",  // macos only?
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
  String get classpath {
    List<RemoteFile> jars = [];

    for (var lib in metadata.libraries){
      jars.addAll(VanillaInstaller.determineDownloadable(lib));
    }

    return DownloadHelper.toClasspath(jars);
  }
  
  @override
  GameInstaller get installer => VanillaInstaller(minecraftVersion);
}
