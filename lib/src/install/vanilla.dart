import 'dart:convert';
import '../data/options.dart';


class VanillaVersion {
    late String id;
    late String url;
    late String releaseTime;
    late String type;
    late String time;

    VanillaVersion(Map<String, dynamic> json){
        this.id = json["id"] as String;
        this.url = json["url"] as String;
        this.releaseTime = json["releaseTime"] as String;
        this.type = json["type"] as String;
        this.time = json["time"] as String;
    }
}

class VanillaVersionList {
    List<VanillaVersion> versions = List.empty(growable: true);

    VanillaVersionList(String json){
        Map<String, dynamic> data = jsonDecode(json);
        List<Map<String, dynamic>> versionData = List.from(data["versions"]);
        versionData.forEach((version) => this.versions.add(VanillaVersion(version)));
    }
}
class VanillaLibraryDownloads {
    late String path;
    late String sha1;
    late int size;
    late String url;

    VanillaLibraryDownloads(Map<String, dynamic> json){
        path = json["artifact"]["path"] as String;
        path = json["artifact"]["sha1"] as String;
        path = json["artifact"]["size"] as String;
        path = json["artifact"]["url"] as String;
    }
}

class VanillaLibrary {
    late VanillaLibraryDownloads downloads;
    late String name;

    VanillaLibrary(Map<String, dynamic> json){
        name = json["name"] as String;
        downloads = VanillaLibraryDownloads(json["downloads"] as Map<String, dynamic>);
    }
}

class VanillaVersionFiles {
    List<VanillaLibrary> libraries = List.empty(growable: true);
    VanillaVersionFiles(VanillaVersion version){
        Map<String, dynamic> 
    }
}