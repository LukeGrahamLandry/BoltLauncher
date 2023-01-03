import 'package:json_annotation/json_annotation.dart';
part 'vanilla.g.dart';

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
class Artifact {
    String? path;
    String sha1;
    String url;
    int size;

    Artifact(this.path, this.sha1, this.url, this.size);

    factory Artifact.fromJson(Map<String, dynamic> json) => _$ArtifactFromJson(json);
    Map<String, dynamic> toJson() => _$ArtifactToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LibraryDownloads {
    Artifact artifact;
    LibraryDownloads(this.artifact);

    factory LibraryDownloads.fromJson(Map<String, dynamic> json) => _$LibraryDownloadsFromJson(json);
    Map<String, dynamic> toJson() => _$LibraryDownloadsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Library {
    LibraryDownloads downloads;
    String name;
    List<Rule>? rules;

    Library(this.name, this.downloads, this.rules);

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
    Artifact client;
    Artifact client_mappings;
    Artifact server;
    Artifact server_mappings;

    MainFiles(this.client_mappings, this.client, this.server, this.server_mappings);

    factory MainFiles.fromJson(Map<String, dynamic> json) => _$MainFilesFromJson(json);
    Map<String, dynamic> toJson() => _$MainFilesToJson(this);
}

@JsonSerializable(explicitToJson: true)
class VersionFiles {
    List<Library> libraries;
    MainFiles downloads;

    VersionFiles(this.libraries, this.downloads);

    factory VersionFiles.fromJson(Map<String, dynamic> json) => _$VersionFilesFromJson(json);
    Map<String, dynamic> toJson() => _$VersionFilesToJson(this);
}