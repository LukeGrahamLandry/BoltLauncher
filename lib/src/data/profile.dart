import 'dart:io';
import 'dart:convert';
import '../constants.dart';

Future<Map<String, String>> getProfiles() async {
    var profilesFile = File(Constants.profilesFile);
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
    String? source; 
    double? maxRam;
    double? minRam;
    String? jvmPath;
    String? jvmArgs;
}
