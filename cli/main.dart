import 'package:bolt_launcher/src/api_models/java_metadata.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/java.dart';
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
  if (arguments.isNotEmpty && arguments[0] == "clear") await clearCommand(arguments);
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

  if (program == "list"){
      (await getProfiles()).forEach((key, value) {
          print("$key: $value");
      });
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
  if (program == "launch") await installCommand(arguments, launch: true);
}
