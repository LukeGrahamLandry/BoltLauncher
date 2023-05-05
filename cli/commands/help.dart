import 'package:bolt_launcher/bolt_launcher.dart';

List<String> _full_command_help_text = """
## list

Lists all existing profile names and install locations

## install 

Installs minecraft. 

Usage:
	${Branding.binaryName} install 
Arguments: 
	--name
		a unique identifier for a profile to create. wrap in quotes to use spaces
  --version
    "a.b.c"
  --loader
    "vanilla" or "forge" or "fabric" or "quilt"
	--url
		a modpack from modrinth or curseforge or nebula
	--path "[${Branding.dataDirEnvVarName}]/instances/[NAME]"
		location for the minecraft folder 
  --refresh
    flag to ignore the metadata cache. useful if you know a new version was just released. 

Specify (--url and --name) to install a mod pack to a new profile. 
Specify (--loader, --version, and --name) to create an empty profile. 

## login

Open the Microsoft login page. 

## logout

Forget your Microsoft account. You will have to login again to play. 

## launch

Starts the game.

Usage:
	${Branding.binaryName} launch <name> 
Arguments:
	name
		unique identifier of the profile to modify (use 'list' for options)

## clear

Removes downloaded data specified by arguments. 
The game will take much longer to start the first time after running this. 

Usage:
	${Branding.binaryName} clear confirm
Flags:
  --metadata
    deletes cached metadata json files
  --jars
    deletes downloaded jar files (game client and libraries)
  --all
    deletes everything --jars, --metadata

## help

${Branding.name} is a command line modpack manager. It will help you install and launch Minecraft. 
${Branding.homePageDisplayUrl}

Use a command with no arguments for more detailed help.

## license

${Branding.license}

## privacy

${Branding.privacyPolicy}

"""
    .split("\n");

String getHelp(String command) {
  String text = "";
  bool found = false;
  bool printing = false;
  List<String> programs = List.empty(growable: true);

  _full_command_help_text.forEach((line) {
    if (line != "" && line[0] == "#") {
      String title =
          line.replaceAll("#", "").replaceAll(" ", "").replaceAll("\n", "");
      programs.add(title);
      if (printing || (found && !printing)) {
        printing = false;
        return;
      }

      if (title == command) {
        found = true;
        printing = true;
      }
    } else if (printing) {
      text += "$line\n";
    }
  });

  if (command == "help") {
    text = "${text.trim()}\nCommands: $programs";
  }

  return found
      ? text.trim()
      : "Sorry, $command is not a recognized ${Branding.binaryName} command.";
}
