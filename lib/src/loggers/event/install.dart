import 'package:bolt_launcher/src/loggers/event/base.dart';

class InstallEvent extends HasVersionInfo {}

class StartInstall extends InstallEvent {}

class EndInstall extends InstallEvent {}

class VersionNotFound extends InstallEvent implements Problem {
  @override
  String get message => "Minecraft $minecraftVersion $modLoader $loaderVersion does not exist.";
}
