## How to Write a Minecraft Launcher 

This documentation will explain the inner workings of BoltLauncher. Hopefully in enough detail that you could implement your own launcher from scratch. 

A launcher must do several things before someone can play Minecraft.

1. [install the Java Runtime Environment](how-it-works/installing/java.md)
2. [install all the jar files the game needs to run](how-it-works/installing/README.md)
3. [login to the player's microsoft account](how-it-works/microsoft-auth.md)
4. [run the game](how-it-works/launching.md)

The main problem that needs to be solved is where do we find all the required jar files. This is done by fetching [metadata](how-it-works/metadata.md) from some api. The process is exactly the same for modded Minecraft. There are just a few extra jar files to install. 

There are some additional features that are nice to have.

- [install mods](how-it-works/installing/README.md)
- [automatically update the launcher app](how-it-works/auto-update/README.md)
- [provide alerts about security vulnerabilities](how-it-works/security/README.md)

## BoltLauncher Project Info

- [Forking](project/forking.md)
- [Privacy Policy](project/privacy.md)
- [Sponsor the project!](project/sponsor.md)
