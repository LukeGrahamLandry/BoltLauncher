import 'dart:io';
import 'dart:convert';
import 'locations.dart';
import 'options.dart';

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

class MinecraftProfile {
  String? packUrl; 
  String loader;
  String minecraftVersion;
  String? loaderVersion;
  String? packVersion;
  double? maxRam;
  double? minRam;
  String jvmPath;
  String? jvmArgs;

  MinecraftProfile(this.packUrl, this.loader, this.loaderVersion, this.minecraftVersion, this.packVersion, this.maxRam, this.minRam, this.jvmArgs, this.jvmPath);
  MinecraftProfile.empty(this.jvmPath, this.loader, this.minecraftVersion, {this.loaderVersion});
  MinecraftProfile.pack(this.jvmPath, this.loader, this.minecraftVersion, this.loaderVersion, this.packUrl, this.packVersion);
}
