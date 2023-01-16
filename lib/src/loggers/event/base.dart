class Event {}

abstract class Problem {
  String get message;
}

class HasVersionInfo extends Event {
  late String modLoader;
  late String minecraftVersion;
  late String loaderVersion;

  void init(String modLoader, String minecraftVersion, String? loaderVersion){
    this.minecraftVersion = minecraftVersion;
    this.modLoader = modLoader;
    this.loaderVersion = loaderVersion ?? "0";
  }

  String get id => "$minecraftVersion-$modLoader-$loaderVersion";
}

class TaskTime {
  int startTime;
  int? endTime;

  TaskTime(this.startTime);
}
