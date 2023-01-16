import 'package:bolt_launcher/src/loggers/event/base.dart';
import 'package:bolt_launcher/src/loggers/event/install.dart';

class ForgeProcessorStdout extends InstallEvent {
  List<int> data;
  ForgeProcessorStdout(this.data);
}

class ForgeProcessorStartAll extends InstallEvent {

}

class ForgeProcessorStartOne extends InstallEvent {

}

class ForgeProcessorEndAll extends InstallEvent {

}

class ForgeProcessorTestPass extends InstallEvent {
  String fileNameKey;
  String generatedFilePath;

  ForgeProcessorTestPass(this.fileNameKey, this.generatedFilePath);
}

class ForgeProcessorTestFail extends InstallEvent implements Problem {
  String fileNameKey;
  String generatedFilePath;
  String? expectedHash;
  String actualHash;

  ForgeProcessorTestFail(this.fileNameKey, this.generatedFilePath, this.expectedHash, this.actualHash);

  @override
  String get message => "FAIL: Hash mismatch, expected $expectedHash} but got $actualHash for $fileNameKey ($generatedFilePath)";
}
