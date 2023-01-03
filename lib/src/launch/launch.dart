
import 'dart:io';
import 'package:path/path.dart' as p;
import '../constants.dart';
import '../install/vanilla.dart';

void launchMinecraft() async {
  String gameDir = p.join(Constants.dataDirectory, "instances", "test");
  Directory(gameDir).createSync(recursive: true);

  List<String> arguments = [
    "-XstartOnFirstThread",
    "-cp",
    await buildClasspath(),
    "net.minecraft.client.main.Main",
    "--version",
    "1.19.3", 
    "--accessToken",
    "" // TODO
  ];

  print("Starting Minecraft.");
  var gameProcess = await Process.start("java", arguments, workingDirectory: gameDir, runInShell: true);
  await gameProcess.stdout.pipe(stdout);
  print("Minecraft Ended. Goodbye.");
}

Future<String> buildClasspath() async {
  var installer = VanillaInstaller("1.19.3");
  await installer.install();
  return installer.classpath.join(":");
}