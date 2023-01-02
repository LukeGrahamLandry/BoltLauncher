# Bolt Launcher 

BoltLauncher is a Dart library that handles installing and launching modded Minecraft instances. 

BoltLauncher also provides a command line program. This is how I test during development. See [help.dart](cli/commands/help.dart) for details on all command line options. 

Although it's not the friendliest interface for players to use directly, it could be used to build a minecraft launcher with any UI framework. You'd just bundle bolt with your application and call the commands based on the user's input. Bolt 
can handle everything behind the scenes and you can focus on providing a great interface. 

## Developing 

- [Install the Dart SDK](https://dart.dev/get-dart)
- Run code generation: (for json parsing)
    - one time: `dart run build_runner build --delete-conflicting-outputs`
    - continuous: `dart run build_runner watch --delete-conflicting-outputs`
- Build command line app: `dart compile exe cli/main.dart -o bolt`
