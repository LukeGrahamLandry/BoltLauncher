# Bolt Launcher 

BoltLauncher is split into three components. 

- lib: a Dart library that handles installing and launching modded Minecraft instances. 
- cli: a command line program, used for testing during development.
    - See [cli/README](cli/README.md) for details.
    - See [help.dart](cli/commands/help.dart) for usage docs.
- gui: a flutter app for launching minecraft
    - See [gui/README](gui/README.md) for details.

Although it's not the friendliest interface for players to use directly, the CLI could be used to build a minecraft launcher with any UI framework. You'd just bundle bolt with your application and call the commands based on the user's input. Bolt 
can handle everything behind the scenes and you can focus on providing a great interface. 

## Features

- Install & Launch Minecraft
    - vanilla, fabric, quilt
    - 1.19.x
- (WIP) Install Java 
- (WIP) Manage game profiles with different mods

## Developing 

- [Install the Dart SDK](https://dart.dev/get-dart)
- Run code generation: (for json parsing)
    - one time: `dart run build_runner build --delete-conflicting-outputs`
    - continuous: `dart run build_runner watch --delete-conflicting-outputs`
- Run command line app: `dart run cli/main.dart`
- Build command line app: `dart compile exe cli/main.dart -o bolt`

## Data Location

Launcher data is stored in the folder given by the `BOLT_LAUNCHER_FOLDER` environment variable. 

Defaults:

- MacOS: `~/Library/Application Support/BoltLauncher`
- Windows: `~/Library/AppData/BoltLauncher`
- Linux: `~/.BoltLauncher`
