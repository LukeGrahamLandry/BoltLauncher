import 'dart:io' show File, Platform;
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class Constants {
    static String get dataDirectory {
        return Platform.environment["BOLT_LAUNCHER_FOLDER"] ?? "~/bolt-launcher";
    }

    static String get profilesFile {
        return path.join(dataDirectory, "profiles.json");
    }

    static MetaSources metaSources = MetaSources();
}

class MetaSources {
    String vanillaVersions = "https://launchermeta.mojang.com/mc/game/version_manifest.json";
}

Future<String> cachedFetch(String url, String filename) async {
    var file = File(path.join(Constants.dataDirectory, filename));
    if (!(await file.exists())){
        await file.create(recursive: true);
        var response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
            throw Exception('Failed to load $url');  // TODO
        } 
        file.writeAsString(response.body);
    }

    return file.readAsString();
}

