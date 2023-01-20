import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/launch/base.dart';

class VanillaLauncher extends GameLauncher {
  late VersionFiles vanillaMetadata;
  
  VanillaLauncher(super.minecraftVersion, super.loaderVersion, super.gameDirectory) : super();

  @override
  Future<void> loadMetadata() async {
    vanillaMetadata = (await VanillaInstaller.getMetadata(minecraftVersion, realLoader: modLoader))!;
  }

  @override
  String get modLoader => VersionListHelper.VANILLA.name;

  @override
  List<String> get jvmArgs => evalArgs(vanillaMetadata.arguments.jvm);

  @override
  List<String> get minecraftArgs => evalArgs(vanillaMetadata.arguments.game);
  
  @override
  String get mainClass => vanillaMetadata.mainClass;

  @override
  String get classpath => DownloadHelper.toClasspath(VanillaInstaller.constructLibraries(vanillaMetadata, minecraftVersion));
  
  @override
  GameInstaller get installer => VanillaInstaller(minecraftVersion);
}
