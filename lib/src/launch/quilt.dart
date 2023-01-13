
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/install/game/quilt.dart';
import 'package:bolt_launcher/src/launch/fabric.dart';
import 'package:bolt_launcher/src/launch/vanilla.dart';
import 'package:bolt_launcher/src/loggers/launch.dart';

class QuiltLauncher extends FabricLauncher with QuiltInstallerSettings {
  QuiltLauncher.innerCreate(String minecraftVersion, String loaderVersion, String gameDirectory): super.innerCreate(minecraftVersion, loaderVersion, gameDirectory);

  static Future<QuiltLauncher> create(String minecraftVersion, String loaderVersion, String gameDirectory) async {
    QuiltLauncher self = QuiltLauncher.innerCreate(minecraftVersion, loaderVersion, gameDirectory);
    self.logger = LaunchLogger(self.loaderName.toLowerCase(), minecraftVersion, gameDirectory);
    await self.checkInstallation();
    self.metadata = await self.versionFilesMetadata(minecraftVersion, loaderVersion);
    self.vanilla = await VanillaLauncher.create(minecraftVersion, gameDirectory, doInstalledCheck: false);
    return self;
  }

  @override
  GameInstaller get installer => QuiltInstaller(minecraftVersion, loaderVersion!);
}