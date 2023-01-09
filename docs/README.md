# How to Write a Minecraft Launcher 

This documentation will explain the inner workings of BoltLauncher. Hopefully in enough detail that you could implement your own launcher from scratch. 

A launcher must do several things before someone can play Minecraft.

1. [install the Java Runtime Environment](installing/java.md)
2. [install all the jar files the game needs to run](installing/README.md)
3. [login to the player's microsoft account](auth/microsoft.md)
4. [run the game](launching.md)

The main problem that needs to be solved is where do we find all the required jar files. This is done by fetching [metadata](metadata.md) from some api. The process is exactly the same for modded Minecraft. There are just a few extra jar files to install. 

There are some additional features that are nice to have.

- [install mods](installing/README.md)
- [automatically update the launcher app](auto-update/README.md)
- [provide alerts about security vulnerabilities](security/README.md)
