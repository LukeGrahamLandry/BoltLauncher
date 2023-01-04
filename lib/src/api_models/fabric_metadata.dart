

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/install/util.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
part 'fabric_metadata.g.dart';

@JsonSerializable(explicitToJson: true)
class VanillaVersion {
  String version;
  bool stable;

  VanillaVersion(this.version, this.stable);

  factory VanillaVersion.fromJson(Map<String, dynamic> json) => _$VanillaVersionFromJson(json);
  Map<String, dynamic> toJson() => _$VanillaVersionToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LoaderVerson {
  String separator;
  int build;
  String maven;
  String version;
  bool stable;

  LoaderVerson(this.separator, this.build, this.maven, this.version, this.stable);

  factory LoaderVerson.fromJson(Map<String, dynamic> json) => _$LoaderVersonFromJson(json);
  Map<String, dynamic> toJson() => _$LoaderVersonToJson(this);
}


@JsonSerializable(explicitToJson: true)
class VersionList {
  List<VanillaVersion> game;
  List<LoaderVerson> loader;

  VersionList(this.game, this.loader);

  factory VersionList.fromJson(Map<String, dynamic> json) => _$VersionListFromJson(json);
  Map<String, dynamic> toJson() => _$VersionListToJson(this);
}

@JsonSerializable(explicitToJson: true)
class VersionFiles {
  LoaderVerson loader;
  LauncherInfo launcherMeta;

  VersionFiles(this.loader, this.launcherMeta);

  factory VersionFiles.fromJson(Map<String, dynamic> json) => _$VersionFilesFromJson(json);
  Map<String, dynamic> toJson() => _$VersionFilesToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LibraryLocation implements LibFile {
  String name;
  String url;
  String? sha1Value;

  LibraryLocation(this.name, this.url);

  String get path {
    List<String> parts = name.split(":");
    String group = parts[0];
    String path = group.split(".").join("/");
    String id = parts[1];
    String version = parts[2];

    return "$path/$id/$version/$id-$version.jar";
  }

  String get jarUrl {
    return "$url$path";
  }

  String get sha1Url {
    return "$jarUrl.sha1";
  }

  @override
  String get fullPath {
    return p.join(Locations.installDirectory, "libraries", path);
  }

  @override
  String get sha1 {
    return sha1Value!;
  }

  Future<void> fetchHash() async {
    var response = await http.get(Uri.parse(sha1Url));
    if (response.statusCode != 200) {
        throw Exception('Failed to load $url');  // TODO
    } 
    sha1Value = response.body;
  }

  factory LibraryLocation.fromJson(Map<String, dynamic> json) => _$LibraryLocationFromJson(json);
  Map<String, dynamic> toJson() => _$LibraryLocationToJson(this);
  
  
}

@JsonSerializable(explicitToJson: true)
class DistLibraries {
  List<LibraryLocation> client;
  List<LibraryLocation> common;
  List<LibraryLocation> server;

  DistLibraries(this.client, this.common, this.server);

  factory DistLibraries.fromJson(Map<String, dynamic> json) => _$DistLibrariesFromJson(json);
  Map<String, dynamic> toJson() => _$DistLibrariesToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MainClass {
  String client;
  String server;

  MainClass(this.client, this.server);

  factory MainClass.fromJson(Map<String, dynamic> json) => _$MainClassFromJson(json);
  Map<String, dynamic> toJson() => _$MainClassToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LauncherInfo {
  int version;
  DistLibraries libraries;
  MainClass mainClass;
  
  LauncherInfo(this.version, this.libraries, this.mainClass);

  factory LauncherInfo.fromJson(Map<String, dynamic> json) => _$LauncherInfoFromJson(json);
  Map<String, dynamic> toJson() => _$LauncherInfoToJson(this);
}

