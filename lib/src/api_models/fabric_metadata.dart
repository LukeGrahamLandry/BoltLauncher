

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/install/downloader.dart';
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
  bool? stable;

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
class LibraryLocation with MavenArtifact {
  String name;
  String url;  // trailing slash

  LibraryLocation(this.name, this.url) {
    init(name, url);
  }

  Future<LibFile> get lib async {
    return await MavenLibFile.of(this, p.join(Locations.installDirectory, "libraries"));
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

