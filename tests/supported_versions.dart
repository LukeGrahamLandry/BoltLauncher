
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:bolt_launcher/bolt_launcher.dart';

int requiredGameRuntime = 15;
File log = File("instance/logs/tests/supported_versions.txt");
List<String> toClear = [Locations.installDirectory, Locations.metadataCacheDirectory];

/// For recommended version of each loader for each supported minecraft version, install and launch. 
/// The test passes if stderr is empty for 15 seconds after running launch command.
void main(List<String> args) async {
  int startTime = DateTime.now().millisecondsSinceEpoch;
  int count = 0;

  toClear.map((e) => Directory(e)).forEach((element) {
    if (element.existsSync()) element.deleteSync(recursive: true);
  });
  log.createSync(recursive: true);
  log.writeAsStringSync("");

  Iterable<String> loaders = args.isEmpty ? VersionListHelper.modLoaders.keys : args;

  for (String loaderName in loaders){  //
    var loaderData = VersionListHelper.modLoaders[loaderName]!;
    List<String> minecraftVersions = await loaderData.supportedMinecraftVersions;
    for (String minecraftVersion in minecraftVersions) {
      String loaderVersion = await loaderData.recommendedVersion(minecraftVersion);
      GameLauncher launcher = await loaderData.launcher(minecraftVersion, loaderVersion, path.join(Locations.dataDirectory, "instances", "test"));
      String java = await VersionListHelper.suggestedJavaExecutable(await VersionListHelper.suggestedJavaMajorVersion(minecraftVersion));
      Process game = await launcher.launch(java);

      String errors = "";
      game.stderr.listen((event) {
        errors += utf8.decode(event);
      });
      await Future.delayed(Duration(seconds: requiredGameRuntime));

      String msg = "${errors.isEmpty ? "PASS" : "FAIL"} Minecraft $minecraftVersion $loaderName ${loaderData.hasLoaderVersions ? loaderVersion : ""}\n";
      if (errors.isNotEmpty) msg += "\n$errors\n\n";
      output(msg);
      print("Suspending process after $requiredGameRuntime seconds.");
      game.kill();
      count++;
    }
  }

  int endTime = DateTime.now().millisecondsSinceEpoch;
  output("\nFinished $count tests in ${(endTime - startTime) / 1000} seconds");
}

void output(String msg){
  print(msg);
  log.writeAsStringSync(msg, mode: FileMode.append);
}
