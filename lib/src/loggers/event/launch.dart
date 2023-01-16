import 'package:bolt_launcher/src/loggers/event/base.dart';

class LaunchEvent extends HasVersionInfo {
  String gameDirectory;
  LaunchEvent(this.gameDirectory);

  @override
  String get id => "${super.id} at $gameDirectory";
}

class StartGameProcess extends LaunchEvent {
  String javaExecutable;
  List<String> args;

  StartGameProcess(super.gameDirectory, this.javaExecutable, this.args);
}

class GameStdout extends LaunchEvent {
  List<int> data;
  GameStdout(super.gameDirectory, this.data);
} 

class GameStderr extends LaunchEvent {
  List<int> data;
  GameStderr(super.gameDirectory, this.data);
}
