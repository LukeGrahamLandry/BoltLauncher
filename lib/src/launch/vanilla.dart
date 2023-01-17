import 'dart:convert';
import 'dart:io' show Directory, File, Platform, Process;
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart' as vanilla;
import 'package:bolt_launcher/src/launch/base.dart';
import 'package:bolt_launcher/src/loggers/event/launch.dart';
import 'package:bolt_launcher/src/loggers/logger.dart';
import 'package:bolt_launcher/src/install/util/remote_file.dart';

import 'package:path/path.dart' as p;


class VanillaLauncher extends GameLauncher {
  late VersionFiles metadata;

  VanillaLauncher._create(String minecraftVersion, String gameDirectory): super.create(minecraftVersion, null, gameDirectory);

  static Future<VanillaLauncher> create(String minecraftVersion, String gameDirectory, {bool doInstalledCheck = true}) async {
    VanillaLauncher self = VanillaLauncher._create(minecraftVersion, gameDirectory);
    if (doInstalledCheck) await self.checkInstallation();
    self.metadata = (await VanillaInstaller.getMetadata(minecraftVersion))!;
    return self;
  }

  @override
  String get modLoader => "vanilla";

  @override
  List<String> get jvmArgs => evalArgs(metadata.arguments.jvm);

  @override
  List<String> get minecraftArgs => evalArgs(metadata.arguments.game);
  
  @override
  String get mainClass => metadata.mainClass;

  @override
  String get classpath => DownloadHelper.toClasspath(VanillaInstaller.constructLibraries(metadata, minecraftVersion));
  
  @override
  GameInstaller get installer => VanillaInstaller(minecraftVersion);
}
