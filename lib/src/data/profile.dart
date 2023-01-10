import 'dart:io';
import 'dart:convert';
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/data/version_list.dart';
import 'package:json_annotation/json_annotation.dart';

part 'profile.g.dart';

Future<Map<String, String>> getProfiles() async {
  var profilesFile = File(Locations.profilesFile);
  if (!(await profilesFile.exists())){
      await profilesFile.create(recursive: true);
      await profilesFile.writeAsString("{}");
  }

  Map<dynamic, dynamic> data = jsonDecode(await profilesFile.readAsString());
  Map<String, String> profiles = {};
  data.forEach((key, value) => profiles[key] = value as String);
  return profiles;
}


@JsonSerializable(explicitToJson: true)
class MinecraftProfile {
  String minecraftVersion;
  String loader;
  String loaderVersion;
  String gameDirectory;

  String? packUrl;   
  String? packVersion;

  String jvmPath;
  List<String> jvmArgs = [];
  int maxRam = 4096;
  int minRam = 4096;
  
  MinecraftProfile(this.packUrl, this.loader, this.loaderVersion, this.minecraftVersion, this.packVersion, this.maxRam, this.minRam, this.jvmArgs, this.jvmPath, this.gameDirectory);
  MinecraftProfile.empty(this.jvmPath, this.loader, this.minecraftVersion, this.loaderVersion, this.gameDirectory);

  static Future<MinecraftProfile> pack(String jvmPath, String packUrl, String packVersion) async {
    throw UnimplementedError("");  // TODO
  }

  static MinecraftProfile fromFile(String path){
    return MinecraftProfile.fromJson(jsonDecode(File(path).readAsStringSync()));
  }

  factory MinecraftProfile.fromJson(Map<String, dynamic> json) => _$MinecraftProfileFromJson(json);
  Map<String, dynamic> toJson() => _$MinecraftProfileToJson(this);

  Future<Process> launch() async {
    GameLauncher launcher = await VersionListHelper.modLoaders[loader]!.launcher(minecraftVersion, loaderVersion, gameDirectory);
    return launcher.launch(jvmPath);
  }
}
