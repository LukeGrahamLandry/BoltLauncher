
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/loggers/problem.dart';

class InstallLogger {
  List<DownloadLogger> downloads = [];
  List<Problem> errors = [];
  String modLoader;
  String minecraftVersion;
  String loaderVersion;
  late int startTime;
  late int endTime;

  InstallLogger? vanillaTracker;

  InstallLogger(this.modLoader, this.minecraftVersion, {this.loaderVersion = "0"}){
    if (modLoader != "vanilla"){
      vanillaTracker = InstallLogger("vanilla", minecraftVersion);
    }
  }

  void start(){
    log("Checking installation...");
    startTime = DateTime.now().millisecondsSinceEpoch;
  }

  void end(){
    endTime = DateTime.now().millisecondsSinceEpoch;
    log("Full installation check finished in ${(endTime - startTime) / 1000} seconds.");

    if (errors.isNotEmpty){
      log("Encountered ${errors.length} problems.");
      log("=" * 10);
      for (Problem err in errors) {
        log(err.message);
        log("=" * 10);
      }
    }
  }

  void failed(Problem error){
    errors.add(error);
    log(error.message);
  }

  void startDownload(DownloadHelper downloader){
    var logger = DownloadLogger();
    downloads.add(logger);
    downloader.setLogger(logger);
  }

  void log(String msg){
    print(msg);
  }

  void loadMavenHashes(int length) {
    log("Start loading $length maven hashes");
  }
}

class ForgeProcessorLogger {
  void processStdout(List<int> data){

  }

  void processStderr(List<int> data){
    
  
  }
}