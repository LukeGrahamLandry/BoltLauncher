import 'dart:io';

import 'package:bolt_launcher/src/loggers/install.dart';
import 'package:path/path.dart' as p;

class LaunchLogger {
  String modLoader;
  String minecraftVersion;
  String loaderVersion;
  String gameDirectory;

  LaunchLogger(this.modLoader, this.minecraftVersion, this.gameDirectory, {this.loaderVersion = "0"});

  InstallLogger get installLogger => InstallLogger(modLoader, minecraftVersion);

  // TODO: these aren't actually hooked up to the process yet
  void processStdout(List<int> data){

  }

  void processStderr(List<int> data){
    
  }

  void start(String javaExecutable, List<String> args) {
    String startCommandLogLocation = p.join(gameDirectory, "launch.sh");
    File(startCommandLogLocation)..create(recursive: true)..writeAsStringSync("cd $gameDirectory && $javaExecutable ${args.join(" ")}");
    Process.run("chmod", ["-v", "777", startCommandLogLocation]);
  }
}
