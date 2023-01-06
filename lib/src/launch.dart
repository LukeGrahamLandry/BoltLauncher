
import 'dart:io';
import 'package:bolt_launcher/src/install/game/fabric.dart';
import 'package:bolt_launcher/src/install/game/quilt.dart';
import 'package:path/path.dart' as p;
import 'data/locations.dart';
import 'install/game/forge/install.dart';
import 'install/game/vanilla.dart';

void testLaunchMinecraft(){
  String versionId = "1.19.3";
  String gameDir = p.join(Locations.dataDirectory, "instances", "test");
  // var installer = QuiltInstaller(versionId, "0.18.1-beta.26");
  var installer = ForgeWrapperInstaller(versionId, "44.1.0");
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

  List<String> arguments = [
    "-XstartOnFirstThread",
    "-cp",
    installer.launchClassPath,

    // TODO: move args definition into installer class
    // start ForgeWrapper
    "-Dforgewrapper.librariesDir=${p.join(Locations.installDirectory, "libraries")}",
    "-Dforgewrapper.installer=${(installer as ForgeWrapperInstaller).officialForgeInstaller.fullPath}",
    "-Dforgewrapper.minecraft=${p.join(Locations.installDirectory, "versions", installer.versionId, "${installer.versionId}.jar")}",
    // end ForgeWrapper

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
  ];

  print("Starting Minecraft.");
  var gameProcess = await Process.start("java", arguments, workingDirectory: gameDir);
  File("command.sh").writeAsString("cd $gameDir && java ${arguments.join(" ")}");
  await stdout.addStream(gameProcess.stdout);
  await Process.run("chmod", ["-v", "777", "command.sh"]);
  print("Minecraft Ended. Goodbye.");
}
