## How to Write a Minecraft Launcher 

This documentation will explain the inner workings of BoltLauncher. Hopefully in enough detail that you could implement your own launcher from scratch. 

A launcher must do several things before someone can play Minecraft.

1. install the Java Runtime Environment
2. install all the jar files the game needs to run
   - [vanilla](vanilla.md), [forge](fabric.md), [fabric/quilt](fabric.md)
3. [login to the player's microsoft account](microsoft-auth.md)
4. [run the game](launching.md)

The main problem that needs to be solved is where do we find all the required jar files. This is done by fetching [metadata](metadata.md) from some api. The process is exactly the same for modded Minecraft. There are just a few extra jar files to install. 

Mods are be installed by just downloading their jar files to the `mods` folder of an instance before starting the game. Different mod distribution sites have their own apis and there are a variety of formats for modpacks.
[Ferium](https://github.com/gorilla-devs/ferium) is a nice CLI for dealing with that.