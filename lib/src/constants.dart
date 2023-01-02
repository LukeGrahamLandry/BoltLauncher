import 'dart:io' show Platform;
import 'package:path/path.dart' as path;

class Constants {
    static String get dataDirectory {
        return Platform.environment["BOLT_LAUNCHER_FOLDER"] ?? "~/bolt-launcher";
    }

    static String get profilesFile {
        return path.join(dataDirectory, "profiles.json");
    }
}

