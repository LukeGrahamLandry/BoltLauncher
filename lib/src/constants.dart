import 'dart:io' show File, FileMode, Platform;
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:convert';

class Constants {
  static bool recomputeHashesOnStart = false;


  static String get dataDirectory {
      return Platform.environment["BOLT_LAUNCHER_FOLDER"] ?? "~/bolt-launcher";
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

  static MetaSources metaSources = MetaSources();
}

class MetaSources {
    String vanillaVersions = "https://launchermeta.mojang.com/mc/game/version_manifest.json";
}

Future<Map<String, dynamic>> cachedFetch(String url, String filename) async {
    var sourcesPath = path.join(Constants.metadataCacheDirectory, "sources.json");
    var sources = await jsonObjectFile(sourcesPath, {});
    var file = File(path.join(Constants.metadataCacheDirectory, filename));

    bool needsFetch = !(await file.exists()) || (sources[filename] != url && sources[filename] != "");
    if (needsFetch){
        await file.create(recursive: true);
        print("Fetching $url");
        var response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
            throw Exception('Failed to load $url');  // TODO
        } 
        await file.writeAsString(response.body);

        
        sources[filename] = url;
        await writeJsonObjectFile(sourcesPath, sources);   
    } else {
      print("Using cached $filename");
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