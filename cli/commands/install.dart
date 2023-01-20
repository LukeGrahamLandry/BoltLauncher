import 'package:bolt_launcher/src/launch/base.dart';

import 'help.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:args/args.dart';

import 'package:bolt_launcher/bolt_launcher.dart';

Future<void> installCommand(List<String> arguments, {bool launch=false}) async {
  final parser = ArgParser()
                    ..addOption("version", abbr: 'v')
                    ..addOption("loader", abbr: 'l', defaultsTo: VersionListHelper.VANILLA.name)
                    ..addOption("url", abbr: 'u')
                    ..addOption("name", abbr: 'n')
                    ..addOption("path", abbr: 'p', defaultsTo: "[${Branding.dataDirEnvVarName}]/instances/[NAME]")
                    ..addFlag("hashChecking", negatable: true, defaultsTo: true);

  ArgResults args = parser.parse(arguments);
  String path = (args["path"] as String).replaceAll("[${Branding.dataDirEnvVarName}]", Locations.dataDirectory).replaceAll("[NAME]", args["name"] ?? "");
  
  if (args.wasParsed("url")) {
    if (args.wasParsed("name")){
      await installProfileFromUrl(args["name"], args["url"]);
    } else {
      print("When installing a modpack, you must specify a (--name) for your profile.");
    }  
  } 
  
  else if (args.wasParsed("version")) {  // TODO: only launch if name specified so it knows what directory to use
    await installMinecraft((args["loader"] as String).toLowerCase(), args["version"], args["hashChecking"], launch);
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

Future<void> installMinecraft(String loader, String version, bool hashChecking, bool launch) async {
  LoaderMeta? loaderInfo = VersionListHelper.modLoaders[loader];

  if (loaderInfo == null){
    print("Sorry, '$loader' is not a recognized mod loader. Try 'vanilla', 'quilt', 'fabric', or 'forge'");
    return;
  }

  GameLauncher launcher = loaderInfo.launcher(version, await loaderInfo.recommendedVersion(version), "instance/instances/test");
  await launcher.checkInstallation();
  if (launch) {
    Process game = await launcher.launch(await VersionListHelper.suggestedJava(version, loader));
    await game.exitCode;
  }
}

Future<void> createEmptyProfile(String name, String loader, String version) async {

}

Future<void> installProfileFromUrl(String name, String url) async {

}
