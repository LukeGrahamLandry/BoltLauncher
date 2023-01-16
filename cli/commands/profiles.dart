

import 'dart:io';

import 'package:bolt_launcher/src/profile/import.dart';
import 'package:bolt_launcher/src/profile/profile.dart';

void profileCommand(List<String> arguments) async {
  int startTime = DateTime.now().millisecondsSinceEpoch;
  List<MinecraftProfile> profiles = await findInstances();
  profiles.sort((a, b) => a.gameDirectory.compareTo(b.gameDirectory));
  int endTime = DateTime.now().millisecondsSinceEpoch;

  if (arguments.length == 2){
    int? index = int.tryParse(arguments[1]);
    if (index != null){
      var process = await profiles[index].launch();
      process.stdout.listen((event) {
        stdout.add(event);
      });
      process.stderr.listen((event) {
        stdout.add(event);
      });
      await process.exitCode;
      return;
    }
  }

  print("Found ${profiles.length} minecraft profiles in ${(endTime - startTime) / 1000} seconds.");
  for (int i=0;i<profiles.length;i++){
    print("$i. ${profiles[i]}");
  }

  print("");
  print("To launch the game run: bolt profile <index>");
}
