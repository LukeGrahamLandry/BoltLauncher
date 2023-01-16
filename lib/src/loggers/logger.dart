import 'dart:io';

import 'package:bolt_launcher/src/install/util/remote_file.dart';
import 'package:bolt_launcher/src/loggers/event/forge.dart';
import 'package:bolt_launcher/src/loggers/event/launch.dart';
import 'package:bolt_launcher/src/loggers/impl/download.dart';
import 'package:bolt_launcher/src/loggers/event/download.dart';
import 'package:bolt_launcher/src/loggers/event/install.dart';

import 'event/base.dart';

class Logger {
  static Logger instance = Logger();
  static List<String> executablesDownloadHistory = [];
  List<DownloadLogger> downloads = [];
  
  void log(Event event){
    if (event is DownloadEvent) {
      logDownload(event);
    } else if (event is InstallEvent) {
      logInstall(event);
    } else if (event is LaunchEvent) {
      logLaunch(event);
    } else if (event is FetchMavenHash){
      logStr("Fetching maven hash: ${event.url}");
    }
  }
  
  void logDownload(DownloadEvent event) {
    // TODO: the downloader needs an id that gets passed with every future event. 
    // this impl assumes they always happen one at a time which is only true if not installing two versions at once. 
    if (event is StartDownload){
      DownloadLogger next = DownloadLogger();
      next.init(event.allLibs);
      next.start();
      downloads.add(next);
    }

    else if (event is FileProblem){
      downloads.last.failed(event.lib, event);
    }

    else if (event is DownloadProgress){
      downloads.last.downloading(event.lib, event.receivedBytes, event.totalBytes);
    }

    else if (event is DownloadedFile){
      downloads.last.downloaded(event.lib, event.bytesSize);

      if (RemoteFile.isCode(event.lib)){
        executablesDownloadHistory.add("${DateTime.now()},${event.lib.url},${event.lib.sha1}");
      }
    }

    else if (event is FoundCached){
      downloads.last.cached(event.lib);
    }

    else if (event is ExpectedHashChanged){
      downloads.last.expectedHashChanged(event.lib, event.manifestHash);
    }

    else if (event is FoundWellKnown){
      downloads.last.foundWellKnown(event.lib, event.wellKnownInstall);
    }

    else if (event is EndDownload){
      downloads.last.end();
    }
  }
 
  Map<String, TaskTime> installTasks = {};
  Map<String, TaskTime> forgeProcessorTasks = {};
  void logInstall(InstallEvent event){
    if (event is StartInstall){
      installTasks[event.id] = TaskTime(DateTime.now().millisecondsSinceEpoch);
      logStr("Checking installation of ${event.id}");
    }

    else if (event is EndInstall){
      installTasks[event.id]?.endTime = DateTime.now().millisecondsSinceEpoch;
      logStr("Installation check of ${event.id} finished in ${(installTasks[event.id]!.endTime! - installTasks[event.id]!.startTime) / 1000} seconds.");
    }

    else if (event is VersionNotFound){
      logStr(event.message);
    }

    if (event is ForgeProcessorStartAll){
      forgeProcessorTasks[event.id] = TaskTime(DateTime.now().millisecondsSinceEpoch);
      logStr("Running processors for ${event.id}");
    }

    else if (event is ForgeProcessorEndAll){
      forgeProcessorTasks[event.id]?.endTime = DateTime.now().millisecondsSinceEpoch;
      logStr("Processors for ${event.id} finished in ${(forgeProcessorTasks[event.id]!.endTime! - forgeProcessorTasks[event.id]!.startTime) / 1000} seconds.");
    }

    else if (event is ForgeProcessorTestFail){
      logStr(event.message);
    }

    else if (event is ForgeProcessorTestPass){
      logStr("PASS: ${event.fileNameKey} has correct hash.");
    }
  }

  void logLaunch(LaunchEvent event){
    if (event is StartGameProcess){
      logStr("Launching Minecraft ${event.id}");
    }
  }

  void logStr(String msg){
    print(msg);
  }
}

