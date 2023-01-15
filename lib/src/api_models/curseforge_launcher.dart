
import 'package:json_annotation/json_annotation.dart';

part 'curseforge_launcher.g.dart';


@JsonSerializable(explicitToJson: true)
class MinecraftInstance {
  ModLoaderInfo? baseModLoader;
  String gameVersion;

  MinecraftInstance(this.baseModLoader, this.gameVersion);

  factory MinecraftInstance.fromJson(Map<String, dynamic> json) => _$MinecraftInstanceFromJson(json);
  Map<String, dynamic> toJson() => _$MinecraftInstanceToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ModLoaderInfo {
  String minecraftVersion;
  String? forgeVersion;
  String name;

  ModLoaderInfo(this.minecraftVersion, this.forgeVersion, this.name);

  factory ModLoaderInfo.fromJson(Map<String, dynamic> json) => _$ModLoaderInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ModLoaderInfoToJson(this);
}