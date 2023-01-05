# Metadata

To install Minecraft you need to know which jars files you need for a given version and where to download them from. 
You don't want to just bundle the information in the launcher itself because then everyone would need to update your whole launcher whenever there's a new minecraft/modloader release. 
Instead all this required metadata is put on web servers somewhere and the launcher just includes urls to thier apis. 
It's important that you trust the owners of these urls because players will be downloading and running executables from them. 
It's like an RCE exploit but on purpose. 

- Some launchers will hardcode the urls to thier chosen meta servers. This becomes a problem if the url is compromised and someone evil can send you whatever code they want to run and players can't change it other than hoping there's an update to the launcher. 
- Some launchers (MultiMC, PolyMC, PrismLauncher) host the metadata on thier own server and use scripts to update it from the official sources so there's only one master url for players to configure and trust. This gives them options in case there's a problem with an official source. But all it takes is one [developer](https://github.com/PolyMC/PolyMC/commit/ccf282593dcdbe189c99b81b8bc90cb203aed3ee) [doing](https://news.ycombinator.com/item?id=33239211) [something](https://www.reddit.com/r/OutOfTheLoop/comments/y7647y/whats_going_on_with_polymc_being_declared/) [questionable](https://twitter.com/gamingonlinux/status/1582103691762405378) for everyone to panic and tell you to go change your meta url.
- BoltLauncher lets you configure them to be whatever you prefer. 
So if you decide you don't trust the owner of your meta server anymore, you can just change the url and any mismatched files will be redownloaded automatically. 
By default I use those from the Official Launcher and each modloader's respective installer. 

## BoltLauncher Metadata Urls

- vanilla
    - where to fetch the list of vanilla versions. response contains urls to library data per version which contains links to jar files. 
- assets
    - where to download the extra minecraft assets (sounds, etc).
- fabric
    - where to fetch the list of fabric versions. response contains urls to library data per version which contains maven repository urls and artifacts. 
- fabricMaven
    - the maven repository to use for the main fabric-loader artifact.
- quilt
    - where to fetch the list of quilt versions. response contains urls to library data per version which contains maven repository urls and artifacts. 
- quiltMaven
    - the maven repository to use for the main quilt-loader artifact.

See `lib/src/data/options.dart`

## Api Formats

The APIs generally return some json object that gives you a bunch of (jar file url, sha1 hash, path) objects to download. The exact format of the response varies. See https://apidocs.moddingtutorials.org for details.

## Caching

Fetched metadata is saved as json files in `BOLT_LAUNCHER_FOLDER/metadata`. 
Which url was used to retrive each file is saved in `sources.json`. 
We check the sources file to confirm it matches the current settings before using the cache. 
So if you use the `settings` command to change the url of a given metadata component, its cache is invalidated and the data will be fetched again from the new url. 

When an actual jar file is downloaded, its hash is saved in `BOLT_LAUNCHER_FOLDER/install/manifest.json`. If we go to fetch a file that matches that manifest, it won't be redownloaded since we know its already there. Additionally a line in the format `date time url sha1` is written to `BOLT_LAUNCHER_FOLDER/executables-download-history.txt`. We never empty this log file so you can review a complete record of any code we download and run. So if someone you trust accounces some specifc version of a library to be comprimesed (like the log4j RCE thing a while ago), you can easily go check if you might be affected by checking if you've downloaded the file at any point, even if you've since gotten rid of it. 

Every time you run the game, the `install` command is run to check that you have all the required files. But if you've already played and haven't changed any metadata settings, it won't use the network because everything is cached. It will just read a few json files from your hard drive to make sure everything matches up. 
