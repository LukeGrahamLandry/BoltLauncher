# Metadata

To install Minecraft you need to know which jars files you need for a given version and where to download them from. 
You don't want to just bundle the information in the launcher itself because then everyone would need to update your whole launcher whenever there's a new minecraft/modloader release. 
Instead, all this required metadata is put on web servers somewhere and the launcher just includes urls to their apis. 
It's important that you trust the owners of these urls because players will be downloading and running executables from them. 
It's like an RCE exploit but on purpose. 

- Some launchers will hardcode the urls to their chosen meta servers. This becomes a problem if the url is compromised and someone evil can send you whatever code they want to run and players can't change it other than hoping there's an update to the launcher. 
- Some launchers (MultiMC, PolyMC, PrismLauncher) host the metadata on their own server and use scripts to update it from the official sources so there's only one master url for players to configure and trust. This gives them options in case there's a problem with an official source. But all it takes is one [developer](https://github.com/PolyMC/PolyMC/commit/ccf282593dcdbe189c99b81b8bc90cb203aed3ee) [doing](https://news.ycombinator.com/item?id=33239211) [something](https://www.reddit.com/r/OutOfTheLoop/comments/y7647y/whats_going_on_with_polymc_being_declared/) [questionable](https://twitter.com/gamingonlinux/status/1582103691762405378) for everyone to panic and tell you to go change your meta url.
- BoltLauncher lets you configure them to be whatever you prefer. 

So if you decide you don't trust the owner of your meta server anymore, you can just change the url and any mismatched files will be redownloaded automatically. 
By default, I use those from the Official Launcher and each modloader's official installer respectively. 

## Metadata Urls

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
- forgeMaven
	- the maven repositry to use for the forge installer and files it references 

See `lib/src/data/options.dart`

## Api Formats

The APIs generally return some json object that gives you a bunch of (jar file url, sha1 hash, path) objects to download. The exact format of the response varies. 