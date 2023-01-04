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

## settings

Set or get an option value for a given profile

Usage:
	${Branding.binaryName} settings <name> --key value
    set a value
	${Branding.binaryName} settings <name> get
    display current values
Arguments:
	name
		unique identifier of the profile to modify (use 'list' for options)
	--source
        the url to retrieve mods from. after updating see '${Branding.binaryName} update'
	--path "[${Branding.dataDirEnvVarName}]/instances/[NAME]"
		location of the minecraft folder. remember to update this if you move the folder 
	--maxRam
	--minRam
	--jvmPath
	--jvmArgs

## meta

Global configuration. 
Ensure you trust the owners of all urls used. 
Executable files will be downloaded from metadata sources and run.

Usage:
	${Branding.binaryName} meta --key value
    set a value
	${Branding.binaryName} meta get
    display current values
Arguments: 
  --vanillaVersions
    url. source for the vanilla game files. 
  --prismLike
    url. use meta format of MultiMC/PolyMC/PrismLauncher instead of all options above (overrides them if set).
  --curseMaven
    url.
  --curseforgeApi
    url.
  --curseforgeApiKey
    key for accessing the official curseforge api. 
  --updatesFeed
    url.
  --azureAuth
    url.
  --azureAuthKey
    key to use for microsoft login. players are trusting the owner of this key with access to accounts. 
  --vulnerabilityChecks
    bool.
  --password
    set a password that must be included with any future commands (using the --pw option). 

For api scheme details see: https://github.com/LukeGrahamLandry/BoltLauncher/tree/main/docs/api-formats
The ${Branding.dataDirEnvVarName} environment variable determines where data is stored. 

## update 

Downloads the mod files for a profile

Usage:
	${Branding.binaryName} update <name> 
Arguments:
	name
		unique identifier of the profile to modify (use 'list' for options)
Flags:
	--force
		redownload all mods even if we thing we already have them
  --check
    does not actually install the update. just tells you if there is one

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
Source code: ${Branding.github}

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
