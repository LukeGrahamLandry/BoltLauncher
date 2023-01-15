import 'dart:io' show File, FileMode, Platform;
import 'package:path/path.dart' as path;

import 'options.dart';

class Locations {
  static String get homeDirectory {
    return Platform.isWindows ? Platform.environment['USERPROFILE']! : Platform.environment['HOME']!;
  }

  static String get dataDirectory {
    String defaultLocation;
    if (Platform.isMacOS) {
      defaultLocation = path.join(homeDirectory, "Library", "Application Support", Branding.dataDirectoryName);
    } else if (Platform.isWindows) {
      defaultLocation = path.join(homeDirectory, "AppData", Branding.dataDirectoryName);
    } else {
      defaultLocation = path.join(homeDirectory, ".${Branding.dataDirectoryName}");
    }

    return Platform.environment[Branding.dataDirEnvVarName] ?? defaultLocation;
  }

  static String get profilesFile {
    return path.join(dataDirectory, "profiles.json");
  }

  static String get installDirectory {
    return path.join(dataDirectory, "install");
  }

  static String get metadataCacheDirectory {
    return path.join(dataDirectory, "metadata");
  }

  static String get manifestFile {
    return path.join(installDirectory, "manifest.json");
  }

  static String get curseforgeInstances => path.join(Locations.homeDirectory, "Documents", "curseforge", "minecraft", "Instances");
}
