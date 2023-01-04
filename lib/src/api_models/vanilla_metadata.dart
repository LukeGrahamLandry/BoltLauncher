import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/install/downloader.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;
part 'vanilla_metadata.g.dart';

@JsonSerializable(explicitToJson: true)
class Version {
    String id;
    String url;
    String releaseTime;
    String type;
    String time;

    Version(this.id, this.url, this.releaseTime, this.time, this.type);

    factory Version.fromJson(Map<String, dynamic> json) => _$VersionFromJson(json);
    Map<String, dynamic> toJson() => _$VersionToJson(this);
}

@JsonSerializable(explicitToJson: true)
class VersionList {
    List<Version> versions;

    VersionList(this.versions);

    factory VersionList.fromJson(Map<String, dynamic> json) => _$VersionListFromJson(json);
    Map<String, dynamic> toJson() => _$VersionListToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Artifact implements LibFile {
  String path;
  String sha1;
  String url;
  int? size;

  Artifact(this.path, this.sha1, this.url, this.size);

  factory Artifact.fromJson(Map<String, dynamic> json) => _$ArtifactFromJson(json);
  Map<String, dynamic> toJson() => _$ArtifactToJson(this);
  
  @override
  String get fullPath => p.join(Locations.installDirectory, "libraries", path);

  String get jarUrl {
    return url;
  }
}

@JsonSerializable(explicitToJson: true)
class MainArtifact implements LibFile {
  String sha1;
  String url;
  int? size;

  String? version;
  String? name;

  MainArtifact(this.sha1, this.url, this.size);

  factory MainArtifact.fromJson(Map<String, dynamic> json) => _$MainArtifactFromJson(json);
  Map<String, dynamic> toJson() => _$MainArtifactToJson(this);
    
  @override
  String get fullPath {
    return p.join(Locations.installDirectory, "versions", path);
  }

  @override
  String get path {
    return p.join(version!, "$version.jar");
  }

  String get jarUrl {
    return url;
  }
}

@JsonSerializable(explicitToJson: true)
class LibraryDownloads {
    Artifact artifact;

    // pre 1.19 only. after its handled by rules
    Map<String, Artifact>? classifiers;
    
    LibraryDownloads(this.artifact, this.classifiers);

    factory LibraryDownloads.fromJson(Map<String, dynamic> json) => _$LibraryDownloadsFromJson(json);
    Map<String, dynamic> toJson() => _$LibraryDownloadsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Library {
    LibraryDownloads downloads;
    String name;
    List<Rule>? rules;

    // pre 1.19 only. after its handled by rules
    Map<String, String>? natives;

    Library(this.name, this.downloads, this.rules, this.natives);

    factory Library.fromJson(Map<String, dynamic> json) => _$LibraryFromJson(json);
    Map<String, dynamic> toJson() => _$LibraryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OperatingSystem {
    String name;

    OperatingSystem(this.name);

    factory OperatingSystem.fromJson(Map<String, dynamic> json) => _$OperatingSystemFromJson(json);
    Map<String, dynamic> toJson() => _$OperatingSystemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Rule {
    String action;
    OperatingSystem? os;

    Rule(this.action, this.os);

    factory Rule.fromJson(Map<String, dynamic> json) => _$RuleFromJson(json);
    Map<String, dynamic> toJson() => _$RuleToJson(this);
}


@JsonSerializable(explicitToJson: true)
class MainFiles {
    MainArtifact client;
    MainArtifact client_mappings;
    MainArtifact server;
    MainArtifact server_mappings;

    MainFiles(this.client_mappings, this.client, this.server, this.server_mappings);

    factory MainFiles.fromJson(Map<String, dynamic> json) => _$MainFilesFromJson(json);
    Map<String, dynamic> toJson() => _$MainFilesToJson(this);
}

@JsonSerializable(explicitToJson: true)
class VersionFiles {
    List<Library> libraries;
    MainFiles downloads;
    String mainClass;
    RemoteAssetIndex assetIndex;

    VersionFiles(this.libraries, this.downloads, this.mainClass, this.assetIndex);

    factory VersionFiles.fromJson(Map<String, dynamic> json) => _$VersionFilesFromJson(json);
    Map<String, dynamic> toJson() => _$VersionFilesToJson(this);
}

@JsonSerializable(explicitToJson: true)
class RemoteAssetIndex {
    String id;
    String sha1;
    int size;
    int totalSize;
    String url;

    RemoteAssetIndex(this.id, this.sha1, this.size, this.totalSize, this.url);

    factory RemoteAssetIndex.fromJson(Map<String, dynamic> json) => _$RemoteAssetIndexFromJson(json);
    Map<String, dynamic> toJson() => _$RemoteAssetIndexToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AssetIndexHolder {
  Map<String, AssetIndexEntry> objects;

  AssetIndexHolder(this.objects);

  factory AssetIndexHolder.fromJson(Map<String, dynamic> json) => _$AssetIndexHolderFromJson(json);
  Map<String, dynamic> toJson() => _$AssetIndexHolderToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AssetIndexEntry implements LibFile {
  String hash;
  int? size;
  
  AssetIndexEntry(this.hash, this.size);

  factory AssetIndexEntry.fromJson(Map<String, dynamic> json) => _$AssetIndexEntryFromJson(json);
  Map<String, dynamic> toJson() => _$AssetIndexEntryToJson(this);
  
  @override
  String get fullPath => p.join(Locations.installDirectory, "assets", "objects", path);
  
  @override
  String get path => "${sha1[0]}${sha1[1]}/$sha1";

  @override
  String get url => "${GlobalOptions.metadataUrls.assets}/$path";
  
  @override
  String get sha1 => hash;
}