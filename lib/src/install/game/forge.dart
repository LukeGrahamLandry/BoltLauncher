import 'dart:convert';
import 'dart:io';

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/install/util/problem.dart';
import 'package:bolt_launcher/src/api_models/prism_metadata.dart' as prism;
import 'package:bolt_launcher/src/api_models/forge_metadata.dart' as forge;
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart' as v;
import 'package:bolt_launcher/src/install/util/remote_file.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';

class ForgeInstaller implements MinecraftInstaller {	
  String minecraftVersion;
  String loaderVersion;
  late VanillaInstaller vanilla;
  
  late DownloadHelper downloadHelper;

  late RemoteFile officialForgeInstaller;
  late List<RemoteFile> gameLibs;


  ForgeInstaller(this.minecraftVersion, this.loaderVersion) {
    vanilla = VanillaInstaller(minecraftVersion);
  }
  
  @override
  Future<void> install() async {
    await vanilla.install();

    await checkVersion();
    await extractInstaller();
    await downloadLibraries();
    await ForgeProcessors(minecraftVersion, loaderVersion).runAll();
  }

  Future<bool> checkVersion() async {
    prism.VersionList versionData = await MetadataCache.forgeVersions;

    bool exists = false;
    for (var version in versionData.versions){
      if (version.version == loaderVersion){
        exists = true;
        break;
      }
    }

    if (!exists){
      print("Forge version $loaderVersion not found");
      return false;
    }

    return true;
  }

  /// download the official forge installer jar file and extract its contents
  Future<void> extractInstaller() async {
    officialForgeInstaller = await MavenFile.of(MavenArtifactImpl("net.minecraftforge:forge:$minecraftVersion-$loaderVersion:installer", "${GlobalOptions.metadataUrls.forgeMaven}/"), p.join(Locations.installDirectory, "libraries"));
    List<RemoteFile> files = [officialForgeInstaller];
    downloadHelper = DownloadHelper(files);
    await downloadHelper.downloadAll();

    File forgeJar = File(officialForgeInstaller.fullPath);
    var forgeContents = Directory(p.join(forgeJar.parent.path, "installer-contents"));
    var zipped = ZipDecoder().decodeBytes(await forgeJar.readAsBytes());

    for (var file in zipped){
      final filename = '${forgeContents.path}/${file.name}';
      if (file.isFile) {
        // not actually running their installer so i don't care about the code
        if (filename.endsWith(".class")) continue;

        var outFile = File(filename);
        outFile = await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content);
      } 
    }

    forge.InstallProfile profile = forge.InstallProfile.fromJson(json.decode(File(p.join(forgeContents.path, "install_profile.json")).readAsStringSync()));
    for (String key in profile.data.keys){
      var value = profile.data[key]!;
      if (value.client.startsWith("/")){  // jar resource
        String source = p.join(forgeContents.path, value.client.substring(1, value.client.length));
        String target = p.join(forgeJar.parent.path, "resources", value.client.substring(1, value.client.length));
        File(target).create(recursive: true);
        await File(source).copy(target);
      } 
    }

    File(p.join(forgeContents.path, "install_profile.json")).copy(p.join(Locations.metadataCacheDirectory, "forge-$loaderVersion-install_profile.json"));
    File(p.join(forgeContents.path, "version.json")).copy(p.join(Locations.metadataCacheDirectory, "forge-$loaderVersion-version.json"));
  }

  Future<void> downloadLibraries() async {
    forge.InstallProfile profile = forge.InstallProfile.fromJson(json.decode(File(p.join(Locations.metadataCacheDirectory, "forge-$loaderVersion-install_profile.json")).readAsStringSync()));

    List<RemoteFile> processorLibs = List.of(profile.libraries.map((e) => e.downloads.artifact));  // needed for processor 
    gameLibs = List.of(v.VersionFiles.fromJson(json.decode(File(p.join(Locations.metadataCacheDirectory, "forge-$loaderVersion-version.json")).readAsStringSync())).libraries.map((e) => e.downloads.artifact));  // needed for launcher
    downloadHelper = DownloadHelper(processorLibs + gameLibs);
    await downloadHelper.downloadAll();
  }

  // the order of the classpath matters
  // if you do "${downloadHelper.classPath}:${vanilla.jarDownloadHelper.classPath}" it starts running the main class from the first chunk before loading the second chunk of classes
  // java.lang.NoSuchMethodError: com.google.gson.JsonParser: method 'void <init>()' not found
  @override
  String get launchClassPath => "${vanilla.jarDownloadHelper.classPath}:${DownloadHelper.toClasspath(gameLibs)}";

  // todo
  @override
  Future<String> get launchMainClass async {
    return "cpw.mods.bootstraplauncher.BootstrapLauncher";
  }

  @override
  String get versionId => vanilla.versionId;

  @override
  List<Problem> get errors => downloadHelper.errors + vanilla.jarDownloadHelper.errors;
}


class ForgeProcessors {
  String minecraftVersion;
  String loaderVersion;

  late forge.InstallProfile profile;
  late String officialInstallerJar;
  late Map<String, String> data;

  ForgeProcessors(this.minecraftVersion, this.loaderVersion);

  Future<void> runAll() async {
    int startTime = DateTime.now().millisecondsSinceEpoch;

    officialInstallerJar = MavenArtifact.identifierToPath("net.minecraftforge:forge:$minecraftVersion-$loaderVersion:installer");
    profile = forge.InstallProfile.fromJson(json.decode(await File(p.join(Locations.metadataCacheDirectory, "forge-$loaderVersion-install_profile.json")).readAsString()));
    data = genParameters();

    bool alreadyPatched = await checkForPatchedJar();
    if (!alreadyPatched){
      for (forge.ProcessorAction processor in profile.processors){
        await runOne(processor);
      }
    }

    int endTime = DateTime.now().millisecondsSinceEpoch;
    print("Checked forge processors in ${(endTime-startTime)/1000} seconds.");
  }

  Map<String, String> genParameters(){
    // evaluate processor parameter replacements 
    Map<String, String> argValues = {
      "ROOT": p.join(Locations.dataDirectory),
      "INSTALLER": officialInstallerJar,
      "MINECRAFT_JAR": p.join(Locations.installDirectory, "versions", "1.19.3", "1.19.3.jar"),
      "SIDE": "client"
    };

    profile.data.forEach((key, value) {
      if (value.client.startsWith("[")){  // maven
        argValues[key] = p.join(Locations.installDirectory, "libraries", MavenArtifact.identifierToPath(value.client.substring(1, value.client.length - 1)));
      } else if (value.client.startsWith("'")){  // hash
        argValues[key] = value.client.substring(1, value.client.length - 1);
      } else if (value.client.startsWith("/")){  // jar resource
        argValues[key] = p.join(Locations.installDirectory, "libraries", File(officialInstallerJar).parent.path, "resources", value.client.substring(1, value.client.length));
      } else {
        print("processor arg type unknown: $key=${value.client}");
        argValues[key] = value.client;
      }
    });

    return argValues;
  }

  Future<bool> checkForPatchedJar() async {
    if (data.containsKey("PATCHED_SHA") && data.containsKey("PATCHED")){
      File patchedFile = File(data["PATCHED"]!);
      if (await patchedFile.exists()){
          String patchedShaFound = sha1.convert(await patchedFile.readAsBytes()).toString();
          if (data["PATCHED_SHA"] == patchedShaFound){
            return true;
          }
      }
    }
    return false;
  }

  Future<void> runOne(forge.ProcessorAction processor) async {
     if (processor.sides != null && !processor.sides!.contains("client")){
        return;
      } 

      String jar = p.join(Locations.installDirectory, "libraries", MavenArtifact.identifierToPath(processor.jar));
      String classpath = processor.classpath.map((e) => p.join(Locations.installDirectory, "libraries", MavenArtifact.identifierToPath(e))).join(":");
      classpath += ":$jar";

      List<String> args = await argsOf(processor);
      String mainClass = await mainClassOf(jar);

      var processorProcessLmao = await Process.start("java", ["-cp", classpath, mainClass, ...args]);
      await stdout.addStream(processorProcessLmao.stdout);
      await stdout.addStream(processorProcessLmao.stderr);
  }

  Future<String> mainClassOf(String jarPath) async {
    var zipped = ZipDecoder().decodeBytes(await File(jarPath).readAsBytes());
    var manifestFile = zipped.findFile("META-INF/MANIFEST.MF");
    String contents = utf8.decode(manifestFile!.content);

    for (String line in contents.split("\n")){
      if (line.startsWith("Main-Class: ")){
        return line.replaceFirst("Main-Class: ", "").trim();
      }
    }

    print("ERROR: $jarPath has no main class!");
    return "";
  }
  
  List<String> argsOf(forge.ProcessorAction processor) {
    List<String> args = [];
    for (String argName in processor.args){
      argName = argName.replaceFirst("{ROOT}", data["ROOT"]!);
      if (argName.startsWith("{")){
        String key = argName.substring(1, argName.length - 1);
        print(key);
        args.add(data[key]!);
      } else if (argName.startsWith("[")){
        args.add(p.join(Locations.installDirectory, "libraries", MavenArtifact.identifierToPath(argName.substring(1, argName.length - 1))));
      } else {
        args.add(argName);
      } 
    }
    return args;
  }
}