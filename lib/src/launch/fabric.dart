import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/install/game/fabric.dart';
import 'package:path/path.dart' as p;
import 'package:bolt_launcher/src/api_models/fabric_metadata.dart' as fabric;

class FabricLauncher extends GameLauncher with FabricInstallerSettings {
  late VanillaLauncher vanilla;
  late fabric.VersionFiles metadata;

  FabricLauncher.innerCreate(String minecraftVersion, String loaderVersion, String gameDirectory): super.create(minecraftVersion, loaderVersion, gameDirectory);

  static Future<FabricLauncher> create(String minecraftVersion, String loaderVersion, String gameDirectory) async {
    FabricLauncher self = FabricLauncher.innerCreate(minecraftVersion, loaderVersion, gameDirectory);
    await self.checkInstallation();
    self.metadata = await self.versionFilesMetadata(minecraftVersion, loaderVersion);
    self.vanilla = await VanillaLauncher.create(minecraftVersion, gameDirectory, doInstalledCheck: false);
    return self;
  }
  
  @override
  String get classpath {
    List<fabric.LibraryLocation> fabricLibs = [...metadata.launcherMeta.libraries.common];
    fabricLibs.addAll(metadata.launcherMeta.libraries.client);
    fabricLibs.add(fabric.LibraryLocation(metadata.loader.maven, "$defaultMavenUrl/"));
    String fabricClasspath = fabricLibs.map((e) => p.join(Locations.installDirectory, "libraries", e.path)).join(":");
    return "$fabricClasspath:${vanilla.classpath}";
  }
  
  @override
  GameInstaller get installer => FabricInstaller(minecraftVersion, loaderVersion!);
  
  @override
  List<String> get jvmArgs => [
      "-XstartOnFirstThread",  // macos only?
      // "-Djava.library.path=${p.join(Locations.installDirectory, "bin", minecraftVersion)}",
      "-cp",
      classpath
    ];
  
  @override
  String get mainClass => metadata.launcherMeta.mainClass.client;
  
  @override
  List<String> get minecraftArgs => vanilla.minecraftArgs;
}