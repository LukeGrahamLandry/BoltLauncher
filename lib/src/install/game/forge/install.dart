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
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';

class ForgeInstaller implements MinecraftInstaller {	
  String minecraftVersion;
  String loaderVersion;
  late VanillaInstaller vanilla;
  
  late DownloadHelper downloadHelper;

  late RemoteFile officialForgeInstaller;

  var forgeContents;

  ForgeInstaller(this.minecraftVersion, this.loaderVersion) {
    vanilla = VanillaInstaller(minecraftVersion);
  }
  
  @override
  Future<void> install() async {
    await vanilla.install();

    officialForgeInstaller = (await findInstaller())!;
    List<RemoteFile> files = [officialForgeInstaller];
    downloadHelper = DownloadHelper(files);
    await downloadHelper.downloadAll();

    File forgeJar = File(officialForgeInstaller.fullPath);
    forgeContents = Directory(p.join(forgeJar.parent.path, "$loaderVersion-installer-contents"));
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

    List<RemoteFile> forgeLibs = List.of(profile.libraries.map((e) => e.downloads.artifact));
    downloadHelper = DownloadHelper(forgeLibs);
    await downloadHelper.downloadAll();
    
    // evaluate processor parameter replacements 
    Map<String, String> argValues = {
      "ROOT": p.join(Locations.dataDirectory),
      "INSTALLER": officialForgeInstaller.fullPath,
      "MINECRAFT_JAR": p.join(Locations.dataDirectory, "versions", "1.19.3", "1.19.3.jar"),  // TODO
      "SIDE": "CLIENT"
    };

    profile.data.forEach((key, value) {
      if (value.client.startsWith("[")){  // maven
        argValues[key] = p.join(Locations.installDirectory, "libraries", MavenArtifact.identifierToPath(value.client.substring(1, value.client.length - 1)));
      } else if (value.client.startsWith("'")){  // hash
        argValues[key] = value.client.substring(1, value.client.length - 1);
      } else if (value.client.startsWith("/")){  // jar resource
        argValues[key] = p.join(forgeContents.path, value.client.substring(1, value.client.length));
      } else {
        print("processor arg type unknown: $key=${value.client}");
        argValues[key] = value.client;
      }
      print("processor arg: $key=${argValues[key]}");
    });

    for (forge.ProcessorAction processor in profile.processors){
      if (processor.sides != null && !processor.sides!.contains("client")){
        print("ProcessorAction skip ${processor.jar}");
        continue;
      } 

      print("ProcessorAction start ${processor.jar}");

      String jar = p.join(Locations.installDirectory, "libraries", MavenArtifact.identifierToPath(processor.jar));
      String classpath = processor.classpath.map((e) => p.join(Locations.installDirectory, "libraries", MavenArtifact.identifierToPath(e))).join(":");
      classpath += ":$jar";
      List<String> args = [];
      for (String argName in processor.args){
        argName = argName.replaceFirst("{ROOT}", argValues["ROOT"]!);
        if (argName.startsWith("{")){
          String key = argName.substring(1, argName.length - 1);
          print(key);
          args.add(argValues[key]!);
        } else {
          args.add(argName);
        }
      }

      // have to specify the classpath but -jar ignores that param
      String mainClass = "";
      var zipped = ZipDecoder().decodeBytes(await File(jar).readAsBytes());
      var manifestFile = zipped.findFile("META-INF/MANIFEST.MF");
      await File("temp").writeAsBytes(manifestFile!.content);
      for (String line in File("temp").readAsLinesSync()){
        if (line.startsWith("Main-Class: ")){
          mainClass = line.replaceFirst("Main-Class: ", "").trim();
          print("$jar -> $mainClass");
          break;
        }
      }

      var processorProcessLmao = await Process.start("java", ["-cp", classpath, mainClass, ...args]);
      print("java ${["-cp", classpath, mainClass, ...args].join(" ")}");
      await stdout.addStream(processorProcessLmao.stdout);
    }

    // now need to download the libraries forge needs to actually launch the game
    v.VersionFiles extraFiles = v.VersionFiles.fromJson(json.decode(File(p.join(forgeContents.path, "version.json")).readAsStringSync()));
    List<RemoteFile> libs = List.of(extraFiles.libraries.map((e) => e.downloads.artifact));
    downloadHelper = DownloadHelper(libs);
    await downloadHelper.downloadAll();

    // now if i just pass to the normal launch code with their main class i get
    // Caused by: java.lang.reflect.InaccessibleObjectException: Unable to make field static final java.lang.invoke.MethodHandles$Lookup java.lang.invoke.MethodHandles$Lookup.IMPL_LOOKUP accessible: module java.base does not "opens java.lang.invoke" to unnamed module @1f508f09
    // have to do their command line arguments stuff
  }

  Future<RemoteFile?> findInstaller() async {
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
      return null;
    }

    return MavenFile.of(MavenArtifactImpl("net.minecraftforge:forge:$minecraftVersion-$loaderVersion:installer", "${GlobalOptions.metadataUrls.forgeMaven}/"), p.join(Locations.installDirectory, "libraries"));
  }

  // the order of the classpath matters
  // if you do "${downloadHelper.classPath}:${vanilla.jarDownloadHelper.classPath}" it starts running the main class from the first chunk before loading the second chunk of classes
  // java.lang.NoSuchMethodError: com.google.gson.JsonParser: method 'void <init>()' not found
 @override
  String get launchClassPath => "${vanilla.jarDownloadHelper.classPath}:${downloadHelper.classPath}";

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
