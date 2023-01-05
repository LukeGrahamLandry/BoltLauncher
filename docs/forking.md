# Forking 

You're totally welcome to fork BoltLauncher as a starting point for your own project. 

- Please make sure you change the name so nobody gets confused. 
- It would be nice of you to credit where it came from and link back to this repository but there's no obligation to. 

The project is structured so that you should be able to do all your customization in the `gui` section, to get it looking and behaving how you want, without ever needing to change anything in the `lib` section. 'lib' has the logic for actually handling installation and launching based on the requests from `gui`. 

## Configuration 

The settings in `gui/config.dart` allow you to create a white labeled custom build if you fork BoltLauncher. 

- launcher name
- home page display url
- list of mod packs installed by default 
- azure client id (for microsoft login)
- app cast feed url (for automatic launcher updates)
- name of the folder to store installations in 
- privacy policy text
- license text
- interface mode
    - **LibreMode**: Players can install any mods and mod packs they want. The launcher functions like Curseforge's launcher basically. 
    - **ManagedMode**: You hardcode a mod pack (or multiple) to be installed (and updated) automatically. The launcher will not show pages to install other mods or mod packs. Useful if the purpose of your launcher is solely to keep your players up to date with your server's mods. 

The default meta urls are in `lib/src/data/options.dart`. 
