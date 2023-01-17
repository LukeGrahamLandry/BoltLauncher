import 'dart:convert';
import 'dart:io' show Directory, File, Platform, Process;
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart' as vanilla;
import 'package:bolt_launcher/src/loggers/event/launch.dart';
import 'package:bolt_launcher/src/loggers/logger.dart';
import 'package:bolt_launcher/src/install/util/remote_file.dart';

import 'package:path/path.dart' as p;


abstract class GameLauncher {
  String minecraftVersion;
  String? loaderVersion;
  String gameDirectory;
  GameLauncher.create(this.minecraftVersion, this.loaderVersion, this.gameDirectory);

  String get classpath;
  String get mainClass;
  List<String> get minecraftArgs;
  List<String> get jvmArgs;
  GameInstaller get installer;
  String get modLoader;

  Future<void> checkInstallation() async {
    await installer.install();
  }

  Future<Process> launch(String javaExecutable) async {
    List<String> args = [...jvmArgs, mainClass, ...minecraftArgs];
    log(StartGameProcess(gameDirectory, javaExecutable, args));
    // TODO: log listens to stdout and stderr
    return Process.start(javaExecutable, args, workingDirectory: gameDirectory);
  }

  void log(LaunchEvent event){
    event.init(modLoader, minecraftVersion, loaderVersion);
    Logger.instance.log(event);
  }

  Map<String, String> get replacements => {
    "\${auth_player_name}": "todo",
    "\${version_name}": minecraftVersion,
    "\${game_directory}": gameDirectory,
    "\${assets_root}": p.join(Locations.installDirectory, "assets"), 
    "\${assets_index_name}": minecraftVersion,  
    "\${auth_uuid}": "todo",  
    "\${auth_access_token}": "todo",  
    "\${clientid}": "todo",  
    "\${auth_xuid}": "todo",  
    "\${user_type}": "todo",  
    "\${version_type}": "release",  // shows up on main menu screen if not set to "release", could use for branding
    "\${natives_directory}": "todo", 
    "\${launcher_name}": "todo",
    "\${launcher_version}": "todo", 
    "\${classpath}": classpath,
  };

  String doArgReplacement(String input){
    replacements.forEach((key, value) {
      input = input.replaceAll(key, value);
    });
    return input;
  }

  List<String> evalArgs(List<dynamic> argsMetadata){
    List<String> args = [];

    for (var arg in argsMetadata){
      if (arg is String){
        args.add(doArgReplacement(arg));
      } else if (arg is Map){
        List<Rule> rules = (arg["rules"] as List).map((e) => Rule.fromJson(e)).toList();
        if (ruleMatches(rules)){
          var value = arg["value"];
          value is String ? args.add(doArgReplacement(value)) : args.addAll(evalArgs(value));
        }
      }
    }

    return args;
  }

  bool ruleMatches(List<Rule> rules) {
    if (!VanillaInstaller.ruleMatches(rules)) return false;

    for (Rule rule in rules){
      if (rule.features != null){
        if (rule.features!["is_demo_user"] ?? false) return false;
        if (rule.features!["has_custom_resolution"] ?? false) return false;
      }
    }

    return true;
  }
}
