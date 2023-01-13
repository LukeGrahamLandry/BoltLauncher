import 'dart:convert';
import 'dart:io';

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/loggers/install.dart';
import 'package:bolt_launcher/src/loggers/problem.dart';
import 'package:bolt_launcher/src/api_models/forge_metadata.dart' as forge;
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart' as v;
import 'package:bolt_launcher/src/install/util/remote_file.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';

class ForgeInstaller extends GameInstaller {
  late List<RemoteFile> gameLibs;

  ForgeInstaller(String minecraftVersion, String loaderVersion) : super(minecraftVersion, loaderVersion){
    logger = InstallLogger("forge", minecraftVersion);
  }

  @override
  Future<bool> install() async {
    logger.start();
    await installVanilla();
    
    bool foundInstaller = await extractInstallerMetadata(minecraftVersion, loaderVersion!);
    if (!foundInstaller){
      logger.failed(VersionProblem(minecraftVersion, loaderVersion: loaderVersion));
      return false;
    }
    await downloadLibraries();
    await ForgeProcessors(minecraftVersion, loaderVersion!).runAll();

    logger.end();
    return true;
  }

  /// download the official forge installer jar file and extract the metadata json files. 
  static Future<bool> extractInstallerMetadata(String minecraftVersion, String loaderVersion) async {
    RemoteFile officialForgeInstaller = await MavenFile.of(MavenArtifactImpl("net.minecraftforge:forge:$minecraftVersion-$loaderVersion:installer", "${GlobalOptions.metadataUrls.forgeMaven}/"), p.join(Locations.installDirectory, "libraries"));
    List<RemoteFile> files = [officialForgeInstaller];
    DownloadHelper downloadHelper = DownloadHelper(files);
    await downloadHelper.downloadAll();

    if (downloadHelper.errors.isNotEmpty) return false;

    Archive zipped = ZipDecoder().decodeBytes(await File(officialForgeInstaller.fullPath).readAsBytes());
    await File(p.join(Locations.metadataCacheDirectory, "forge/$loaderVersion-install_profile.json")).writeAsBytes(zipped.findFile("install_profile.json")!.content);
    await File(p.join(Locations.metadataCacheDirectory, "forge/$minecraftVersion-forge-$loaderVersion.json")).writeAsBytes(zipped.findFile("version.json")!.content);

    return true;
  }

  // download all the library jar files needed for forge processors and forge game runtime. 
  Future<void> downloadLibraries() async {
    forge.InstallProfile profile = await MetadataCache.forgeInstallProfile(minecraftVersion, loaderVersion!);

    List<RemoteFile> processorLibs = List.of(profile.libraries.map((e) => e.downloads.artifact)); // needed for processor
    v.VersionFiles launchData = await MetadataCache.forgeVersionData(minecraftVersion, loaderVersion!);
    gameLibs = List.of(launchData.libraries.map((e) => e.downloads.artifact)); // needed for launcher
    DownloadHelper downloadHelper = DownloadHelper(processorLibs + gameLibs);
    logger.startDownload(downloadHelper);
    await downloadHelper.downloadAll();
  }
}

class ForgeProcessors {
  String minecraftVersion;
  String loaderVersion;

  late forge.InstallProfile profile;
  String get officialInstallerJar => p.join(Locations.installDirectory, "libraries", MavenArtifact.identifierToPath("net.minecraftforge:forge:$minecraftVersion-$loaderVersion:installer"));
  late Map<String, String> data;

  ForgeProcessors(this.minecraftVersion, this.loaderVersion);

  Future<void> runAll() async {
    int startTime = DateTime.now().millisecondsSinceEpoch;

    profile = await MetadataCache.forgeInstallProfile(minecraftVersion, loaderVersion);
    data = await genParameters();

    bool alreadyPatched = await checkForPatchedJar();
    if (!alreadyPatched) {
      for (forge.Processor processor in profile.processors) {
        await runOne(processor);
      }
    }

    int endTime = DateTime.now().millisecondsSinceEpoch;
    print("Checked forge processors in ${(endTime - startTime) / 1000} seconds.");
  }

  // parse the 'data' field of 'install_profile.json' to get the parameters that will be passed to processor jars later
  Future<Map<String, String>> genParameters() async {
    // evaluate processor parameter replacements
    Map<String, String> argValues = {
      "ROOT": p.join(Locations.dataDirectory),
      "INSTALLER": officialInstallerJar,
      "MINECRAFT_JAR": p.join(Locations.installDirectory, "versions", minecraftVersion, "$minecraftVersion.jar"),
      "SIDE": "client"
    };

    for (String key in profile.data.keys){
      String value = profile.data[key]!.client;

      if (value.startsWith("[")) {  // maven
        argValues[key] = p.join(Locations.installDirectory, "libraries", MavenArtifact.identifierToPath(value.substring(1, value.length - 1)));
      } else if (value.startsWith("'")) {  // hash
        argValues[key] = value.substring(1, value.length - 1);
      } else if (value.startsWith("/")) {  // jar resource
        String relPath = value.substring(1, value.length);
        argValues[key] = p.join(File(officialInstallerJar).parent.path, "resources", relPath);
        Archive zipped = ZipDecoder().decodeBytes(await File(officialInstallerJar).readAsBytes());
        File(argValues[key]!)..createSync(recursive: true)..writeAsBytesSync(zipped.findFile(relPath)!.content);
      } else {
        print("processor arg type unknown: $key=$value");
        argValues[key] = value;
      }
    }

    return argValues;
  }

  // check if forge has already been installed
  Future<bool> checkForPatchedJar() async {
    if (data.containsKey("PATCHED_SHA") && data.containsKey("PATCHED")) {
      File patchedFile = File(data["PATCHED"]!);
      if (await patchedFile.exists()) {
        String patchedShaFound = sha1.convert(await patchedFile.readAsBytes()).toString();
        if (data["PATCHED_SHA"] == patchedShaFound) {
          return true;
        }
      }
    }
    return false;
  }

  // run a single processor. part of creating the patched minecraft jar forge uses to run 
  Future<void> runOne(forge.Processor processor) async {
    if (processor.sides != null && !processor.sides!.contains("client")) {
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

  // find the main class of a jar file by reading its manifest file
  Future<String> mainClassOf(String jarPath) async {
    var zipped = ZipDecoder().decodeBytes(await File(jarPath).readAsBytes());
    var manifestFile = zipped.findFile("META-INF/MANIFEST.MF");
    String contents = utf8.decode(manifestFile!.content);

    for (String line in contents.split("\n")) {
      if (line.startsWith("Main-Class: ")) {
        return line.replaceFirst("Main-Class: ", "").trim();
      }
    }

    print("ERROR: $jarPath has no main class!");
    return "";
  }

  // get the extra command line arguments for a processor 
  List<String> argsOf(forge.Processor processor) {
    List<String> args = [];
    for (String argName in processor.args) {
      argName = argName.replaceFirst("{ROOT}", data["ROOT"]!);
      if (argName.startsWith("{")) {
        String key = argName.substring(1, argName.length - 1);
        print(key);
        args.add(data[key]!);
      } else if (argName.startsWith("[")) {
        args.add(p.join(Locations.installDirectory, "libraries", MavenArtifact.identifierToPath(argName.substring(1, argName.length - 1))));
      } else {
        args.add(argName);
      }
    }
    return args;
  }
}
