import 'dart:io' show File, FileMode, Platform;
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:convert';


// maybe split commands 'bolt meta trust --key value' and 'bolt meta misc --key value'

class GlobalOptions {
  static bool recomputeHashesBeforeLaunch = false;
  static bool checkHashesAfterDownload = true;
  // static bool checkSignaturesOnDownload = true;  // TODO
  // static String pgpCommand = "gpg"

  static MetaSources metadataUrls = MetaSources.initial();

  // only used for reporting download sizes. either 10^6=1000000 or 2^20=1048576 (or 10^3*2^10=1024000 if you're insane)
  static int bytesPerMB = 1000000;

  // having this off only saves ~70 milliseconds but feels clever. only a problem if they go in and delete the install/assets/objects files without deleting the manifest 
  static bool reConfirmAssetsExistBeforeLaunch = false;  

  static List<String> get wellKnownInstallLocations => defaultWellKnown();
}

// TODO: other operating systems 
List<String> defaultWellKnown() {
  return [path.join(Locations.homeDirectory, "Library", "Application Support", "minecraft"), path.join(Locations.homeDirectory, "Documents", "curseforge", "minecraft", "Install")];
}

class MetaSources {
  String vanilla = "https://launchermeta.mojang.com/mc/game/version_manifest.json";
  String assets = "https://resources.download.minecraft.net";

  String fabric = "https://meta.fabricmc.net/v2";
  String fabricMaven = "https://maven.fabricmc.net";

  String quilt = "https://meta.quiltmc.org/v3";
  String quiltMaven = "https://maven.quiltmc.org/repository/release";

  String curseMaven = "https://www.cursemaven.com/test";

  String? azureClientId;

  MetaSources(this.vanilla, this.assets, this.fabric, this.fabricMaven, this.quilt, this.quiltMaven, this.curseMaven, this.azureClientId){
    azureClientId ??= Branding.azureClientId;
  }

  MetaSources.initial();
}

class Branding {
  static String name = "BoltLauncher";
  static String binaryName = "bolt";
  static String homePageDisplayUrl = "https://github.com/LukeGrahamLandry/BoltLauncher";
  static String dataDirectoryName = name;
  static String dataDirEnvVarName = "BOLT_LAUNCHER_FOLDER";
  static String azureClientId = bool.hasEnvironment("AZURE_CLIENT_ID") ? String.fromEnvironment("AZURE_CLIENT_ID") : "";
  static String updatesAppCastUrl = "";

  static String privacyPolicy = 
"""
$name does not transmit any of your data to our servers. 

Metadata servers (where game files are downloaded from) will get your ip address because that's how HTTP works. 
They will also be able to tell which version you're playing by which files are requested. 

The Microsoft identity platform is used to login to your Minecraft account. 
Minecraft has telemetry that sends information to Microsoft. 
See https://privacy.microsoft.com/en-ca/privacystatement
""";

  static String license = 
"""
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
""";
}
