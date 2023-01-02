import 'package:bolt_launcher/bolt_launcher.dart';

List<String> _full_command_help_text = """
## list

Lists all existing profile names and install locations

## install 

Installs minecraft. 

Usage:
	bolt install 
Arguments: 
	--name
		a unique identifier for a profile to create. wrap in quotes to use spaces
  --version
    "a.b.c"
  --loader
    "vanilla" or "forge" or "fabric" or "quilt"
	--url
		a modpack from modrinth or curseforge or nebula
	--path "[BOLT_LAUNCHER_FOLDER]/instances/[NAME]"
		location for the minecraft folder 

Specify (--url and --name) to install a mod pack to a new profile. 
Specify (--loader, --version, and --name) to create an empty profile. 

## login

Open the Microsoft login page. 

## logout

Forget your Microsoft account. You will have to login again to play. 

## launch

Starts the game.

Usage:
	bolt launch <name> 
Arguments:
	name
		unique identifier of the profile to modify (use 'list' for options)

## settings

Set or get an option value for a given profile

Usage:
	bolt settings <name> --key value
	bolt settings <name> --key
Arguments:
	name
		unique identifier of the profile to modify (use 'list' for options)
	--source
        the url to retrieve mods from. after updating see 'bolt update'
	--path "[BOLT_LAUNCHER_FOLDER]/instances/[NAME]"
		location of the minecraft folder. remember to update this if you move the folder 
	--maxRam
	--minRam
	--jvmPath
	--jvmArgs


Set or get a global option

Usage:
	bolt settings --key value
	bolt settings --key
Arguments:
	--metaSource "https/github/lukegrahamlandry/bolt/meta/sources.json"
	    define where to find all urls for meta data
	--microsoftKey ""

BOLT_LAUNCHER_FOLDER environment variable determines where data is stored. 

## update 

Downloads the mod files for a profile

Usage:
	bolt update <name> 
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
	bolt clear confirm
Flags:
  --metadata
    deletes cached metadata json files
  --jars
    deletes downloaded jar files (game client and libraries)
  --all
    deletes everything --jars, --metadata

## help

BoltLauncher is a command line modpack manager. It will help you install and launch Minecraft. 
Source code: https://github.com/LukeGrahamLandry/BoltLauncher

Use a command with no arguments for more detailed help.

## license

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
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
      : "Sorry, $command is not a recognized bolt command.";
}
