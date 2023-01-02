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
                    ..addOption("path", abbr: 'p', defaultsTo: "[BOLT_LAUNCHER_FOLDER]/instances/[NAME]");

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
    await installMinecraft(args["loader"], args["version"]);
    print("");
    print("Minecraft ${args["loader"]} ${args["version"]} has been installed.");
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

Future<void> installMinecraft(String loader, String version) async {
  if (loader == "vanilla") {
    await VanillaInstaller(version).install();
  } else {
    print("Sorry, $loader is not a recognized mod loader. Try 'vanilla'");
  }
}

Future<void> createEmptyProfile(String name, String loader, String version) async {

}

Future<void> installProfileFromUrl(String name, String url) async {

}
