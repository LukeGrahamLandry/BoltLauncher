import 'package:bolt_launcher/bolt_launcher.dart';

abstract class ModpackInstaller implements MinecraftInstaller {
  ModpackInstaller(Map<String, dynamic> jsonData, String profile);

  ModpackInstaller.from(String url, String profile);

  Future<void> install();
}


