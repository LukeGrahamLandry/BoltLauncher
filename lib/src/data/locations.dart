import 'dart:io' show File, FileMode, Platform;
import 'package:path/path.dart' as path;

class Locations {
  static String get homeDirectory {
    return Platform.isWindows ? Platform.environment['USERPROFILE']! : Platform.environment['HOME']!;
  }

  static String get dataDirectory {
    String defaultLocation;
    if (Platform.isMacOS) {
      defaultLocation = path.join(homeDirectory, "Library", "Application Support", "BoltLauncher");
    } else if (Platform.isWindows) {
      defaultLocation = path.join(homeDirectory, "AppData", "BoltLauncher");
    } else {
      defaultLocation = path.join(homeDirectory, ".BoltLauncher");
    }

    return Platform.environment["BOLT_LAUNCHER_FOLDER"] ?? defaultLocation;
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
}
