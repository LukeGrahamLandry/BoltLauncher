import 'package:bolt_launcher/src/api_models/java_metadata.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/java.dart';
import 'package:bolt_launcher/src/install/mods/curseforge.dart';
import 'package:bolt_launcher/src/launch/forge.dart';
import 'package:bolt_launcher/src/profile/import.dart';
import 'package:bolt_launcher/src/profile/profile.dart';

import 'commands/clear.dart';
import 'commands/help.dart';
import 'package:bolt_launcher/bolt_launcher.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:args/args.dart';

import 'commands/install.dart';
import 'commands/profiles.dart';

Future<void> main(List<String> arguments) async {
  await loadAllCaches();
  await run(arguments);
  await saveAllCaches();  // TODO: this should happen before launching the game process

  // this may want to delete metadata so should happen after the files are saved again. 
  if (arguments[0] == "clear") await clearCommand(arguments);
}

Future<void> run(List<String> arguments) async {
  String program = arguments.isEmpty ? "help" : arguments[0];

  if (program == "java"){
    File cache = File(Locations.javaInstallationsList);
    if (cache.existsSync()) cache.deleteSync();

    int startTime = DateTime.now().millisecondsSinceEpoch;
    List<JavaInfo> foundJava = await JavaFinder.search();
    int endTime = DateTime.now().millisecondsSinceEpoch;

    print("Found ${foundJava.length} java installations in ${(endTime - startTime) / 1000} seconds.");
    foundJava.forEach(print);

    return;
  }

  if (program == "launch") {
    await testLaunchMinecraft();
    return;
  }

  if (program == "list"){
      (await getProfiles()).forEach((key, value) {
          print("$key: $value");
      });
      return;
  }

  if (program == "mod") {
    await downloadFromCurseMaven("267602", "2642375", "instance/mods");
    return;
  }

  if (program == "profile") {
    profileCommand(arguments);
    return;
  }

  if (arguments.length <= 1) {
      print("");
      print(getHelp(program));
      print("");
      return;
  }

  if (program == "install") await installCommand(arguments);
}

Future<void> testLaunchMinecraft() async {
  String versionId = "1.19.3";
  // String loaderVersion = "40.2.0";
  String gameDir = p.join(Locations.dataDirectory, "instances", "test");
  // var installer = QuiltInstaller(versionId, "0.18.1-beta.26");
  
  Directory(gameDir).createSync(recursive: true);

  var logs = File("log.txt");
  var loaderInfo = VersionListHelper.FORGE;
  var loaderVersion = await loaderInfo.recommendedVersion(versionId);
  var launcher = await loaderInfo.launcher(versionId, loaderVersion, gameDir);
  var major = await VersionListHelper.suggestedJavaMajorVersion(versionId);

  print("Starting Minecraft...");
  var gameProcess = await launcher.launch(versionId.startsWith("1.19") ? "java" : major == 8 ? "/Library/Java/JavaVirtualMachines/jdk1.8.0_202.jdk/Contents/Home/bin/java" : "/Library/Java/JavaVirtualMachines/temurin-17.jre/Contents/Home/bin/java");
  gameProcess.stdout.listen((data) {
    stdout.add(data);
    // logs.writeAsBytesSync(data, mode: FileMode.append);
  });
  gameProcess.stderr.listen((data) {
    stdout.add(data);
    // logs.writeAsBytesSync(data, mode: FileMode.append);
  });

  int result = await gameProcess.exitCode;
  await Process.run("chmod", ["-v", "777", "command.sh"]);
  print("Minecraft Ended (exit code = $result). Goodbye.");
}
