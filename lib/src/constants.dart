import 'dart:io' show File, FileMode, Platform;
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:convert';

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

Future<Map<String, dynamic>> cachedFetch(String url, String filename) async {
    var file = File(path.join(Constants.dataDirectory, "cache", filename));
    if (!(await file.exists())){
        await file.create(recursive: true);
        var response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
            throw Exception('Failed to load $url');  // TODO
        } 
        file.writeAsString(response.body);

        var sources = File(path.join(Constants.dataDirectory, "cache", "sources.txt"));
        sources.writeAsString("$url\n", mode: FileMode.append);
    }

    return jsonDecode(await file.readAsString());
}

Future<Map<String, dynamic>> jsonObjectFile(String path, Map<String, dynamic> defaultData) async {
    var file = File(path);
    if (!(await file.exists())){
        await file.create(recursive: true);
        await writeJsonObjectFile(path, defaultData);
    }

    return jsonDecode(await file.readAsString());
}

Future<void> writeJsonObjectFile(String path, Map<String, dynamic> data) async {
    var file = File(path);
    if (!(await file.exists())){
        await file.create(recursive: true);
    }
    file.writeAsString(json.encode(data));
}