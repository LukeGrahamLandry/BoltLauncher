
import 'package:json_annotation/json_annotation.dart';
import 'vanilla_metadata.dart' as vanilla;

part 'prism_metadata.g.dart';

@JsonSerializable(explicitToJson: true)
class Requirement {
  String uid;
  String? equals;
  String? suggests;
  Requirement(this.uid, this.equals, this.suggests);

  factory Requirement.fromJson(Map<String, dynamic> json) => _$RequirementFromJson(json);
  Map<String, dynamic> toJson() => _$RequirementToJson(this);
}

@JsonSerializable(explicitToJson: true)
class VersionEntry {
  String releaseTime;
  String sha256;
  String version;
  List<Requirement> requires;

  VersionEntry(this.releaseTime, this.version, this.sha256, this.requires);

  factory VersionEntry.fromJson(Map<String, dynamic> json) => _$VersionEntryFromJson(json);
  Map<String, dynamic> toJson() => _$VersionEntryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class VersionList {
  int formatVersion;
  String name;
  String uid;
  List<VersionEntry> versions;

  VersionList(this.formatVersion, this.name, this.uid, this.versions);

  factory VersionList.fromJson(Map<String, dynamic> json) => _$VersionListFromJson(json);
  Map<String, dynamic> toJson() => _$VersionListToJson(this);
}
