import 'dart:io';

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;


// should probably use the actual maven thing instead of relying on the test page to have stable behaviour 
Future<void> downloadFromCurseMaven(String projectId, String fileId, String modsFolder) async {
  String fullId = "$projectId-$fileId";
  PastDownloadManifest manifest = await PastDownloadManifest.load();

  String downloadUrl;
  bool inCache;
  if (manifest.curseforge.containsKey(fullId)) {
    inCache = true;
    downloadUrl = manifest.curseforge[fullId]!;
  } else {
    inCache = false;
    var dataUrl = "${GlobalOptions.metadataUrls.curseMaven}/$projectId/$fileId";
    var dataResponse = await http.get(Uri.parse(dataUrl));
    if (dataResponse.statusCode != 200) {
      throw Exception('Failed to load $dataUrl'); 
    }

    downloadUrl = dataResponse.body.split("\n").last.split(":").last.trim().replaceFirst("//", "https://");
  }

  var filename = downloadUrl.split("/").last;
  var file = File(path.join(modsFolder, filename));
  if (!await file.exists() || !inCache){
    var response = await http.get(Uri.parse(downloadUrl));
    if (response.statusCode != 200) {
      if (inCache) manifest.curseforge.remove(fullId);
      throw Exception('Failed to load $downloadUrl'); 
    }

    await file.create(recursive: true);
    await file.writeAsBytes(response.bodyBytes);

    if (!inCache) {
      manifest.curseforge[fullId] = downloadUrl;
      await manifest.save();
    }
  }
}
