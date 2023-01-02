import 'package:bolt_launcher/bolt_launcher.dart';

List<String> _full_command_help_text = """
## list

Lists all existing profile names and install locations

## create

Creates a new profile with no mods. 

Usage: 
	bolt create <name> <modloader> <mc_version>
Arguments:
	name
		a unique identifier for the profile
	modloader
		"vanilla" or "forge" or "fabric" or "quilt"
	mc_version
		"a.b.c"
	--location "~/bolt-launcher"
		location for the install

## install 

Creates a new profile with a modpack installed.

Usage:
	bolt install <name> <url>
Arguments: 
	name
		a unique identifier for the profile
	url
		a modpack from modrinth or curseforge or nebula
	--path "~/bolt-launcher/installs/[NAME]"
		location for the minecraft folder 

## login

Open the Microsoft login page. 

## logout

Forget your Microsoft account. You will have to login again to play. 

## launch

Starts the game.

Usage:
	bolt settings <name> 
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
	--ram
	--jvm-path
	--jvm-args
	--source
	--path "~/bolt-launcher/installs/[NAME]"
		location of the minecraft folder 


Set or get a global option

Usage:
	bolt settings --key value
	'bolt settings --key' 
Arguments:
	--meta-source "https/github/lukegrahamlandry/bolt/meta/sources.json"
		 define where to find all urls for meta data
	--microsoft-key ""
	--root "~/bolt-launcher"

## update 

Downloads the mod files for a profile

Usage:
	bolt update <name> 
Arguments:
	name
		unique identifier of the profile to modify (use 'list' for options)
	--force
		redownload all mods even if we thing we already have them

## help

BoltLauncher is a command line modpack manager. It will help you install and launch Minecraft. 
View the code on github: https://github.com/LukeGrahamLandry/BoltLauncher
The location of most data on your machine is {$default_path}.
Use a command with no arguments for more detailed help.

## license

Copyright 2023 LukeGrahamLandry

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
""".split("\n");

String getHelp(String command){
    String text = "";
    bool found = false;
    bool printing = false;
    List<String> programs = List.empty(growable: true);

    _full_command_help_text.forEach((line) {
        if (line != "" && line[0] == "#"){
            String title = line.replaceAll("#", "").replaceAll(" ", "").replaceAll("\n", "");
            programs.add(title);
            if (printing || (found && !printing)) {
                printing = false;
                return;
            }
            
            if (title == command){
                found = true;
                printing = true;
            }
        } else if (printing) {
            text += "$line\n";
        }
    });

    if (command == "help"){
        text += "Commands: $programs";
    }

    return found ? text.trim() : "Sorry, $command is not a recognized bolt command.";
}