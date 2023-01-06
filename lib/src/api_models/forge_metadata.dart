import 'vanilla_metadata.dart' as vanilla;

class InstallProfile {
  int spec;
  String version;
  String json;
  String minecraft;
  Map<String, DistPair> data;
  List<ProcessorAction> processors;

  InstallProfile(this.spec, this.version, this.json, this.minecraft, this.data, this.processors);

}

class DistPair {
  String client;
  String server;

  DistPair(this.client, this.server);
}

class ProcessorAction {
  String jar;
  List<String> classpath;
  List<String> args;
  List<vanilla.Library> libraries;

  ProcessorAction(this.jar, this.classpath, this.args, this.libraries);
}