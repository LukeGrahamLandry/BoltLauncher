import 'package:json_annotation/json_annotation.dart';

part 'java_metadata.g.dart';

@JsonSerializable(explicitToJson: true)
class JavaInfo {
  String vendor;
  String specVersion;
  String fullVersion;
  String architexture;
  String executablePath;

  int get majorVersion => specVersion.contains(".") ? int.parse(specVersion.split(".")[1]) : int.parse(specVersion);

  JavaInfo(this.vendor, this.specVersion, this.fullVersion, this.architexture, this.executablePath);

  @override
  String toString() {
    return "Java $majorVersion ($fullVersion) for $architexture from $vendor at $executablePath";
  }

  factory JavaInfo.fromJson(Map<String, dynamic> json) => _$JavaInfoFromJson(json);
  Map<String, dynamic> toJson() => _$JavaInfoToJson(this);
}

