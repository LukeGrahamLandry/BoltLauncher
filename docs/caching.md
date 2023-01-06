
## Assets & Jar Files

- explore other launcher installations and use sym links

## Metadata 

Fetched metadata is saved as json files in `BOLT_LAUNCHER_FOLDER/metadata`. 
Which url was used to retrive each file is saved in `sources.json`. 
We check the sources file to confirm it matches the current settings before using the cache. 
So if you use the `settings` command to change the url of a given metadata component, its cache is invalidated and the data will be fetched again from the new url. 

When an actual jar file is downloaded, its hash is saved in `BOLT_LAUNCHER_FOLDER/install/manifest.json`. If we go to fetch a file that matches that manifest, it won't be redownloaded since we know its already there. Additionally a line in the format `date time,url,sha1` is written to `BOLT_LAUNCHER_FOLDER/executables-download-history.csv`. We never empty this log file so you can review a complete record of any code we download and run. So if someone you trust accounces some specifc version of a library to be comprimesed (like the log4j RCE thing a while ago), you can easily go check if you might be affected by checking if you've downloaded the file at any point, even if you've since gotten rid of it. 

Every time you run the game, the `install` command is run to check that you have all the required files. But if you've already played and haven't changed any metadata settings, it won't use the network because everything is cached. It will just read a few json files from your hard drive to make sure everything matches up. 
