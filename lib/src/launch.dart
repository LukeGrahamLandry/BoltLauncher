
import 'dart:convert';
import 'dart:io';
import 'package:bolt_launcher/src/install/game/fabric.dart';
import 'package:bolt_launcher/src/install/game/quilt.dart';
import 'package:path/path.dart' as p;
import 'data/locations.dart';
import 'install/game/forge/install.dart';
import 'install/game/vanilla.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart' as vanilla;

void testLaunchMinecraft(){
  String versionId = "1.19.3";
  String gameDir = p.join(Locations.dataDirectory, "instances", "test");
  // var installer = QuiltInstaller(versionId, "0.18.1-beta.26");
  var installer = ForgeInstaller(versionId, "44.1.0");
  launchMinecraft(installer, gameDir);
}

void launchMinecraft(MinecraftInstaller installer, String gameDir) async {  
  Directory(gameDir).createSync(recursive: true);

  print("Checking installation...");
  int startTime = DateTime.now().millisecondsSinceEpoch;
  await installer.install();
  int endTime = DateTime.now().millisecondsSinceEpoch;
  print("Full installation check finished in ${(endTime - startTime) / 1000} seconds.");

  Map<String, String> argumentValues = {
    "\${auth_player_name}": "Dev",  // TODO
    "\${version_name}": installer.versionId,
    "\${game_directory}": gameDir,
    "\${assets_root}": "",  // TODO
    "\${assets_index_name}": "",  // TODO
    "\${auth_uuid}": "",  // TODO
    "\${auth_access_token}": "",  // TODO
    "\${clientid}": "",  // TODO
    "\${auth_xuid}": "",  // TODO
    "\${user_type}": "",  // TODO
    "\${version_type}": "",  // TODO
    "\${natives_directory}": "",  // TODO
    "\${launcher_name}": "",  // TODO
    "\${launcher_version}": "",  // TODO
    "\${classpath}": installer.launchClassPath,
  };

  vanilla.VersionFiles extraFiles = vanilla.VersionFiles.fromJson(json.decode(File(p.join((installer as ForgeInstaller).forgeContents.path, "version.json")).readAsStringSync()));

  List<String> jvm = [];
  extraFiles.arguments.jvm.forEach((element) {
    if (element is String){
      jvm.add(element
                      .replaceAll("\${library_directory}", p.join(Locations.installDirectory, "libraries"))
                      .replaceAll("\${classpath_separator}", ":")
                      .replaceAll("\${version_name}", "1.19.3")); 
    }
  });
  extraFiles.arguments.game.removeWhere((element) => element is! String);

  List<String> arguments = [
    "-XstartOnFirstThread",
    // forge: Exception in thread "main" java.lang.module.ResolutionException: Module minecraft contains package com.mojang.blaze3d.systems, module _1._19._3 exports package com.mojang.blaze3d.systems to minecraft
    // tried to fix by removing classpath which did fix but caused Exception in thread "main" java.lang.StringIndexOutOfBoundsException: begin 0, end -3, length 1 ... at cpw.mods.bootstraplauncher@1.1.2/cpw.mods.bootstraplauncher.BootstrapLauncher.main(BootstrapLauncher.java:84)
    // real solution was put this back and replace ${version_name} in jvm args 
    "-cp",
    installer.launchClassPath,
    ...jvm,
    await installer.launchMainClass,
    "--version",
    installer.versionId, 
    "--gameDir",
    gameDir,
    "--assetsDir",
    p.join(Locations.installDirectory, "assets"),
    "--assetIndex",
    installer.versionId,  //  TODO: i think vanilla only calls it major.minor.json
    "--accessToken",
    "", // TODO
    ...extraFiles.arguments.game
  ];

  print("Starting Minecraft.");
  // await File("log.txt").delete();
  var logs = File("log.txt");
  var gameProcess = await Process.start("java", arguments, workingDirectory: gameDir);
  gameProcess.stdout.listen((data) {
    stdout.add(data);
    // logs.writeAsBytesSync(data, mode: FileMode.append);
  });
  gameProcess.stderr.listen((data) {
    stdout.add(data);
    // logs.writeAsBytesSync(data, mode: FileMode.append);
  });
  File("command.sh").writeAsString("cd $gameDir && java ${arguments.join(" ")}");

  int result = await gameProcess.exitCode;
  await Process.run("chmod", ["-v", "777", "command.sh"]);
  print("Minecraft Ended (exit code = $result). Goodbye.");
}
