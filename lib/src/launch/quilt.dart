import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/install/game/quilt.dart';

class QuiltLauncher extends FabricLauncher with QuiltInstallerSettings {
  QuiltLauncher(super.minecraftVersion, super.loaderVersion, super.gameDirectory);

  @override
  GameInstaller get installer => QuiltInstaller(minecraftVersion, loaderVersion!);
}