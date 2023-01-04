
import 'dart:io';
import 'package:bolt_launcher/src/install/fabric.dart';
import 'package:bolt_launcher/src/install/quilt.dart';
import 'package:path/path.dart' as p;
import 'data/locations.dart';
import 'install/vanilla.dart';

void testLaunchMinecraft(){
  String versionId = "1.19.3";
  String gameDir = p.join(Locations.dataDirectory, "instances", "test");
  var installer = QuiltInstaller(versionId, "0.18.1-beta.26");
  launchMinecraft(installer, gameDir);
}

void launchMinecraft(MinecraftInstaller installer, String gameDir) async {  
  Directory(gameDir).createSync(recursive: true);
  await installer.install();

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
    await installer.launchMainClass,
    "--version",
    installer.versionId, 
    "--accessToken",
    "" // TODO
  ];

  print("Starting Minecraft.");
  var gameProcess = await Process.start("java", arguments, workingDirectory: gameDir);
  await stdout.addStream(gameProcess.stdout);
  print("Minecraft Ended. Goodbye.");
}
