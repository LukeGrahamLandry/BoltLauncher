import 'help.dart';
import 'package:bolt_launcher/bolt_launcher.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:args/args.dart';

void installCommand(List<String> arguments) async {
  final parser = ArgParser()
                    ..addOption("version", abbr: 'v')
                    ..addOption("loader", abbr: 'l', defaultsTo: "vanilla")
                    ..addOption("url", abbr: 'u')
                    ..addOption("name", abbr: 'n')
                    ..addOption("path", abbr: 'p', defaultsTo: "[BOLT_LAUNCHER_FOLDER]/instances/[NAME]")
                    ..addFlag("hashChecking", negatable: true, defaultsTo: true);

  ArgResults args = parser.parse(arguments);
  String path = (args["path"] as String).replaceAll("[BOLT_LAUNCHER_FOLDER]", Constants.dataDirectory).replaceAll("[NAME]", args["name"] ?? "");
  
  if (args.wasParsed("url")) {
    if (args.wasParsed("name")){
      await installProfileFromUrl(args["name"], args["url"]);
    } else {
      print("When installing a modpack, you must specify a (--name) for your profile.");
    }  
  } 
  
  else if (args.wasParsed("version")) {
    await installMinecraft((args["loader"] as String).toLowerCase(), args["version"], args["hashChecking"]);
    if (args.wasParsed("name")){
      await createEmptyProfile(args["name"], args["loader"], args["version"]);
    } else {
      print("Rerun the command with (--name) to create an empty profile. ");
    }
  } 
  
  else {
    print("You must specify either (--url) or (--version and --loader).");
  }
}

Future<void> installMinecraft(String loader, String version, bool hashChecking) async {
  if (loader == "vanilla") {
    var installer = VanillaInstaller(version, hashChecking: hashChecking);
    await installer.install();
    print("");
    if (installer.errors.isEmpty){
      print("Minecraft $loader $version has been installed.");
    } else {
      print("=== ERROR ===");
      print("${installer.errors.length} files were not downloaded because they did not match the expected hash.");
      print("Use the 'settings' command to change your metadata server and try again.");
      print("Or, run again with (--no-hashChecking) to ignore these errors and force download. This is probably a very bad idea.");
      print("");
    }
  } else {
    print("Sorry, $loader is not a recognized mod loader. Try 'vanilla'");
  }
}

Future<void> createEmptyProfile(String name, String loader, String version) async {

}

Future<void> installProfileFromUrl(String name, String url) async {

}
