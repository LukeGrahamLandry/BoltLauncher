import 'dart:convert';
import 'dart:io';
import 'package:bolt_launcher/src/install/manifiest.dart';

import '../constants.dart';
import '../data/options.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

part 'vanilla.g.dart';

@JsonSerializable(explicitToJson: true)
class VanillaVersion {
    String id;
    String url;
    String releaseTime;
    String type;
    String time;

    VanillaVersion(this.id, this.url, this.releaseTime, this.time, this.type);

    factory VanillaVersion.fromJson(Map<String, dynamic> json) => _$VanillaVersionFromJson(json);
    Map<String, dynamic> toJson() => _$VanillaVersionToJson(this);
}

@JsonSerializable(explicitToJson: true)
class VanillaVersionList {
    List<VanillaVersion> versions;

    VanillaVersionList(this.versions);

    VanillaVersion? findVersion(String versionId){
        for (var version in versions){
            if (version.id == versionId) return version;
        }
        return null;
    }

    factory VanillaVersionList.fromJson(Map<String, dynamic> json) => _$VanillaVersionListFromJson(json);
    Map<String, dynamic> toJson() => _$VanillaVersionListToJson(this);
}

@JsonSerializable(explicitToJson: true)
class VanillaArtifact {
    String path;
    String sha1;
    int size;
    String url;

    VanillaArtifact(this.path, this.sha1, this.size, this.url);

    factory VanillaArtifact.fromJson(Map<String, dynamic> json) => _$VanillaArtifactFromJson(json);
    Map<String, dynamic> toJson() => _$VanillaArtifactToJson(this);
    
    void download(String directory) async {
        var file = File(p.join(directory, path));
        if (!await file.exists()) await file.create(recursive: true);

        await http.get(Uri.parse(url)).then((response) {
            file.writeAsBytes(response.bodyBytes);
        });
    }
}

@JsonSerializable(explicitToJson: true)
class VanillaLibraryDownloads {
    VanillaArtifact artifact;
    VanillaLibraryDownloads(this.artifact);

    factory VanillaLibraryDownloads.fromJson(Map<String, dynamic> json) => _$VanillaLibraryDownloadsFromJson(json);
    Map<String, dynamic> toJson() => _$VanillaLibraryDownloadsToJson(this);
    
    void download(String directory) {
        artifact.download(directory);
    }
    
    bool hashMatches(String? hash) {
        if (hash == null) return false;
        return artifact.sha1 == hash;
    }
}

@JsonSerializable(explicitToJson: true)
class VanillaLibrary {
    VanillaLibraryDownloads downloads;
    String name;
    List<Rule>? rules;

    VanillaLibrary(this.name, this.downloads, this.rules);

    factory VanillaLibrary.fromJson(Map<String, dynamic> json) => _$VanillaLibraryFromJson(json);
    Map<String, dynamic> toJson() => _$VanillaLibraryToJson(this);
    
    void download(String directory) async {
        downloads.download(directory);
    }
    
    bool rulesMatch() {
        if (this.rules == null) return true;

        bool allow = true;
        rules!.forEach((rule) { 
            allow = allow && rule.matches();
        });
        return allow;
    }
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

    bool matches(){
        if (this.action == "allow"){
            return (this.os?.name ?? "osx") == "osx";
        }
        return false;
    }

    factory Rule.fromJson(Map<String, dynamic> json) => _$RuleFromJson(json);
    Map<String, dynamic> toJson() => _$RuleToJson(this);
}

@JsonSerializable(explicitToJson: true)
class VanillaVersionFiles {
    List<VanillaLibrary> libraries;

    VanillaVersionFiles(this.libraries);

    Future<void> download(String directory) async {
        PastDownloadManifest manifest = await PastDownloadManifest.load(directory);
        for (var lib in libraries) {
            if (lib.downloads.hashMatches(manifest.vanillaLibs[lib.name])){
                print("skip (already downloaded) ${lib.name}");
            } else if (!lib.rulesMatch()) {
                print("skip (rule failed) ${lib.name}");
            } else {
                print("downloading ${lib.name}");
                lib.download(directory);
                manifest.vanillaLibs[lib.name] = lib.downloads.artifact.sha1;
                
            }
        }

        await manifest.save(directory);
    }

    factory VanillaVersionFiles.fromJson(Map<String, dynamic> json) => _$VanillaVersionFilesFromJson(json);
    Map<String, dynamic> toJson() => _$VanillaVersionFilesToJson(this);
}



void installVanilla(String versionId) async {
    var versions = VanillaVersionList.fromJson(await cachedFetch(Constants.metaSources.vanillaVersions, "vanilla-versions.json"));
    var testVersion = versions.findVersion(versionId);
    if (testVersion == null){
        print("Minecraft version $versionId was not found. ");
        return;
    }
    var libs = VanillaVersionFiles.fromJson(await cachedFetch(testVersion.url, "vanilla-${testVersion.id}.json"));
    await libs.download("instance/instances/test");
}