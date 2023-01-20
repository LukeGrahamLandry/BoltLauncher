import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/install/game/fabric.dart';
import 'package:path/path.dart' as p;
import 'package:bolt_launcher/src/api_models/fabric_metadata.dart' as fabric;

class FabricLauncher extends VanillaLauncher with FabricInstallerSettings {
  late fabric.VersionFiles metadata;

  FabricLauncher(super.minecraftVersion, super.loaderVersion, super.gameDirectory);

  @override
  Future<void> loadMetadata() async {
    await super.loadMetadata();
    metadata = await versionFilesMetadata(minecraftVersion, loaderVersion!);
  }

  @override
  String get modLoader => loaderName;
  
  @override
  String get classpath {
    List<fabric.LibraryLocation> fabricLibs = [
      ...metadata.launcherMeta.libraries.common,
      ...metadata.launcherMeta.libraries.client,
      fabric.LibraryLocation(metadata.loader.maven, "$defaultMavenUrl/"),
      fabric.LibraryLocation(metadata.intermediary.maven, "$defaultMavenUrl/")
    ];
    
    String fabricClasspath = fabricLibs.map((e) => p.join(Locations.installDirectory, "libraries", e.path)).join(":");
    return "$fabricClasspath:${super.classpath}";
  }
  
  @override
  GameInstaller get installer => FabricInstaller(minecraftVersion, loaderVersion!);
  
  @override
  String get mainClass => metadata.launcherMeta.mainClass.client;
}