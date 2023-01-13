import 'package:bolt_launcher/src/loggers/install.dart';

class LaunchLogger {
  String modLoader;
  String minecraftVersion;
  String loaderVersion;
  String gameDirectory;

  LaunchLogger(this.modLoader, this.minecraftVersion, this.gameDirectory, {this.loaderVersion = "0"});

  InstallLogger get installLogger => InstallLogger(modLoader, minecraftVersion);

  void processStdout(List<int> data){

  }

  void processStderr(List<int> data){
    
  }
}
