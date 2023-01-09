
## Assets & Jar Files

When an actual jar file is downloaded, its hash is saved in `BOLT_LAUNCHER_FOLDER/install/manifest.json`. If we go to fetch a file that matches that manifest, it won't be redownloaded since we know its already there. Additionally a line in the format `date time,url,sha1` is written to `BOLT_LAUNCHER_FOLDER/executables-download-history.csv`. We never empty this log file so you can review a complete record of any code we download and run. So if someone you trust accounces some specific version of a library to be compromised (like the log4j RCE thing a while ago), you can easily go check if you might be affected by checking if you've downloaded the file at any point, even if you've since gotten rid of it. 

Every time you run the game, the `install` command is run to check that you have all the required files. But if you've already played and haven't changed any metadata settings, it won't use the network because everything is cached. It will just read a few json files from your hard drive to make sure everything matches up. 

### Borrowing installations from other launchers

Since other launchers store thier files in a consistant folder we can take a look around for other minecraft installations to borrow files from. For example, imagine someone has played vanilla minecraft before and now wants to try out modded minecraft with our launcher. It would be silly to spend a couple minutes redownloading all the vanilla libraries and assets needed since they're already on the player's computer in the folder made by vanilla minecraft. 

Since we know what the folder is called, we can just copy them over to use ourselves. Copying files from one place on disk to another is much faster than downloading them from the internet. Additionally, since we know the hash of the files we want (from the version metadata file), we can check that the contents of the file we found is exactly what we want. That way there's no risk that someone has a different jar file in the same place and we accidently use it. We can go though a list of a few common launchers very quickly to save bandwidth and time and practiced players trying out a new launcher a better experience. If they don't have another installation we can find, that's no problem. We just fall back to downloading the files. 

Another trick we can use is creating symlinks instead of copying the files. We can create a tiny file in our installation folder that tells the operating system to go look somewhere else for the file. This way, using a new launcher doesn't double the disk space dedicated to minecraft installations. Before starting the game, we do the same hash check to make sure the file still exists and is still exactly what we want. If it went missing just fall back to looking around or redownloading it. 

Most launchers don't do this. I've played with the official launcher, the Curseforge one, MultiMC and Prism Launcher. Each one has their own special folder with thier own identical version of the 500 megabytes of assets that they carefully redownloaded the first time I played. 

These techniques have no cost to first time players but will give a much faster start and smaller storage footprint to people transitioning from another launcher.  

## Metadata 

Fetched metadata is saved as json files in `BOLT_LAUNCHER_FOLDER/metadata`. Which url was used to retrive each file is saved in `sources.json`. 
We check the sources file to confirm it matches the current settings before using the cache. So if you use the `settings` command to change the url of a given metadata component, its cache is invalidated and the data will be fetched again from the new url. 
