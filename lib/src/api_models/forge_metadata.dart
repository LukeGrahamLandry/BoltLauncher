import 'package:json_annotation/json_annotation.dart';

import 'vanilla_metadata.dart';
part 'forge_metadata.g.dart';

@JsonSerializable(explicitToJson: true)
class InstallProfile {
  int spec;
  String version;
  String json;
  String minecraft;
  Map<String, DistPair> data;
  List<ProcessorAction> processors;
  List<Library> libraries;

  InstallProfile(this.spec, this.version, this.json, this.minecraft, this.data, this.processors, this.libraries);

  factory InstallProfile.fromJson(Map<String, dynamic> json) => _$InstallProfileFromJson(json);
  Map<String, dynamic> toJson() => _$InstallProfileToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DistPair {
  String client;
  String server;

  DistPair(this.client, this.server);

  factory DistPair.fromJson(Map<String, dynamic> json) => _$DistPairFromJson(json);
  Map<String, dynamic> toJson() => _$DistPairToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProcessorAction {
  String jar;
  List<String> classpath;
  List<String> args;
  List<String>? sides;
  

  ProcessorAction(this.jar, this.classpath, this.args, this.sides);

  factory ProcessorAction.fromJson(Map<String, dynamic> json) => _$ProcessorActionFromJson(json);
  Map<String, dynamic> toJson() => _$ProcessorActionToJson(this);
}