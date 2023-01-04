
import 'dart:io';
import 'package:bolt_launcher/src/install/fabric.dart';
import 'package:path/path.dart' as p;
import 'data/locations.dart';
import 'install/vanilla.dart';

void launchMinecraft() async {
  String gameDir = p.join(Locations.dataDirectory, "instances", "test");
  Directory(gameDir).createSync(recursive: true);

  String versionId = "1.19.3";
  var installer = FabricInstaller(versionId, "0.14.12");
  await installer.install();

  String classpath = installer.downloadHelper.classpath + ":" + installer.vanilla.downloadHelper.classpath;

  Map<String, String> argumentValues = {
    "\${auth_player_name}": "Dev",  // TODO
    "\${version_name}": versionId,
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
    "\${classpath}": installer.downloadHelper.classpath,
  };

  List<String> arguments = [
    "-XstartOnFirstThread",
    "-cp",
    classpath,
    (await installer.getMetadata())!.launcherMeta.mainClass.client,
    "--version",
    versionId, 
    "--accessToken",
    "" // TODO
  ];

  print("Starting Minecraft.");
  var gameProcess = await Process.start("java", arguments, workingDirectory: gameDir);
  await stdout.addStream(gameProcess.stdout);
  print("Minecraft Ended. Goodbye.");
}
