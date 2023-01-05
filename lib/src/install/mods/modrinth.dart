

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/install/downloader.dart';
import 'package:bolt_launcher/src/install/mods/pack.dart';

class ModrinthModpackInstaller implements ModpackInstaller {
  late MinecraftInstaller baseInstaller;

  @override
  // TODO: implement errors
  List<HashProblem> get errors => throw UnimplementedError();

  @override
  Future<void> install() {
    // TODO: implement install
    throw UnimplementedError();
  }

  @override
  // TODO: implement launchClassPath
  String get launchClassPath => throw UnimplementedError();

  @override
  // TODO: implement launchMainClass
  Future<String> get launchMainClass => throw UnimplementedError();

  @override
  // TODO: implement versionId
  String get versionId => throw UnimplementedError();

}
