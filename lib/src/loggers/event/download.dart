import 'package:bolt_launcher/src/install/util/remote_file.dart';
import 'package:bolt_launcher/src/loggers/event/base.dart';

class DownloadEvent extends Event {}

class StartDownload extends DownloadEvent {
  List<RemoteFile> allLibs;
  StartDownload(this.allLibs);
}

class RemoteFileEvent extends DownloadEvent {
  RemoteFile lib;
  RemoteFileEvent(this.lib);
}

class FoundCached extends RemoteFileEvent {
  FoundCached(super.lib);
}

class DownloadedFile extends RemoteFileEvent {
  int bytesSize;
  DownloadedFile(super.lib, this.bytesSize);
}

abstract class FileProblem extends RemoteFileEvent implements Problem {
  FileProblem(super.lib);  
}

class HashProblem extends FileProblem {
  String get wanted => lib.sha1;
  String got;
  String url;

  HashProblem(super.lib, this.got, this.url);
  
  @override
  String get message => "Expected sha1=$wanted from $url but got sha1=$got";
}

class HttpProblem extends FileProblem {
  String errorMessage;
  String get url => lib.url;
  HttpProblem(super.lib, this.errorMessage);
  
  @override
  String get message => "$errorMessage $url";
}

class EndDownload extends DownloadEvent {}

class FoundWellKnown extends RemoteFileEvent {
  String wellKnownInstall;

  FoundWellKnown(super.lib, this.wellKnownInstall);
}

class DownloadProgress extends RemoteFileEvent {
   int receivedBytes;
   int totalBytes;

  DownloadProgress(super.lib, this.receivedBytes, this.totalBytes);
}

class ExpectedHashChanged extends RemoteFileEvent {
  String manifestHash;

  ExpectedHashChanged(super.lib, this.manifestHash);
}
