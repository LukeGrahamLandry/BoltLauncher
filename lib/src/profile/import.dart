
import 'dart:convert';
import 'dart:io';

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/api_models/forge_metadata.dart';
import 'package:bolt_launcher/src/profile/profile.dart';
import 'package:path/path.dart' as path;
import 'package:bolt_launcher/src/api_models/curseforge_launcher.dart' as cf;

Future<List<MinecraftProfile>> findInstances() async {
  List<MinecraftProfile> results = [];

  var dir = Directory(Locations.curseforgeInstances);
  if (dir.existsSync()){
    await for (var instance in dir.list()){
      if (instance is Directory){
        results.addAll(await importCurseforgeInstance(instance));
      }
    }
  }

  return results;
}

Future<List<MinecraftProfile>> importCurseforgeInstance(Directory instanceFolder) async {
  File info = File(path.join(instanceFolder.path, "minecraftInstance.json"));
  if (!(await info.exists())) return [];

  cf.MinecraftInstance instance = cf.MinecraftInstance.fromJson(jsonDecode(await info.readAsString()));

  String loader = VersionListHelper.VANILLA.name;
  String? loaderVersion;
  if (instance.baseModLoader != null){
    loader = instance.baseModLoader!.name.split("-")[0];
    loaderVersion = instance.baseModLoader!.forgeVersion!;  // they call the variable that even for fabric  
  }

  String jvmPath = await VersionListHelper.suggestedJava(instance.gameVersion, loader);
  MinecraftProfile result = MinecraftProfile.empty(jvmPath, loader, instance.gameVersion, loaderVersion, instanceFolder.path, source: OtherLauncher.curseforge);
  return [result];
}
