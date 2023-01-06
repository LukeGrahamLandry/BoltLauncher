import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/install/util/problem.dart';
import 'remote_file.dart';

import 'package:path/path.dart' as p;

class DownloadProgressTracker {
  int totalFileCount = 0;
  int processedFileCount = 0;
  int totalSize = 0;
  int processedSize = 0;  // includes downloaded and cached
  int downloadedSize = 0;
  int incrementalManifestCounter = 0;
  bool knownFileSizes = true;
  List<Problem> errors = [];
  late int startTime;
  int? endTime;

  DownloadProgressTracker(List<RemoteFile> allLibs){
    totalFileCount = allLibs.length;
    for (RemoteFile lib in allLibs){
      if (lib.size != null){
        totalSize += lib.size!;
      } else {
        knownFileSizes = false;
        break;
      }
    }
  }

  void logStart(){
    startTime = DateTime.now().millisecondsSinceEpoch;
    print("Checking $totalFileCount files${knownFileSizes? " (${(totalSize/1000000).toStringAsFixed(0)} MB)" : ""}");
  }

  void logCached(RemoteFile lib){
    processedFileCount++;
    if (knownFileSizes) processedSize += lib.size!;
  }

  void logDownloaded(RemoteFile lib, int bytesSize){
    processedFileCount++;
    
    String msg = "($processedFileCount/$totalFileCount files";
    downloadedSize += bytesSize;
    if (knownFileSizes){
      processedSize += lib.size!;
      msg += ", ${(processedSize/GlobalOptions.bytesPerMB).toStringAsFixed(0)}/${(totalSize/1000000).toStringAsFixed(0)} MB, ${(processedSize/totalSize*100).toStringAsFixed(1)}%";
    } 
    msg += ") ${lib.url}";
    
    print(msg);
  }

  void logFailed(RemoteFile lib, Problem problem){
    print(problem.message);
    errors.add(problem);
    processedFileCount++;
  }
  
  void logEnd() {
    endTime = DateTime.now().millisecondsSinceEpoch;
    String msg = "Checked $totalFileCount files in ${(endTime! - startTime) / 1000} seconds. ";
    if (knownFileSizes) {
      var cachePercentage = ((1 - (downloadedSize / totalSize)) * 100).toStringAsFixed(1);
      msg += "Of ${(totalSize/1000000).toStringAsFixed(0)} MB, $cachePercentage% found on disk. ";
    }
    msg +="${(downloadedSize/1000000).toStringAsFixed(0)} MB downloaded.";
    if (errors.isNotEmpty) {
      msg += "Download incomplete with ${errors.length} errors.";
    }
    print(msg);
  }

  void logExpectedHashChanged(RemoteFile lib, String manifestHash) {
    if (RemoteFile.isCode(lib)){
      print("WARNING");
      print("Desired hash of ${lib.path} changed since last download.");
      print("Was $manifestHash, now ${lib.sha1}");
      print("File will be re-downloaded but this is very concerning.");
      print("=======");
    }
  }

  void logDownloading(RemoteFile lib, int receivedBytes, int totalBytes) {
    // show incremental download in gui
  }

  void logWellKnown(RemoteFile lib, String wellKnownInstall) {
    processedFileCount++;
    if (knownFileSizes){
      processedSize += lib.size!;
    }
    
    print("($processedFileCount/$totalFileCount files) ${p.join(wellKnownInstall, lib.wellKnownSubFolder, lib.path)}");
  }
}
