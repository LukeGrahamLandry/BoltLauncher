
import 'package:bolt_launcher/bolt_launcher.dart';

/// White Label Settings
class LauncherConfig {
  // switching to MANAGED would disallow the player from adding their own mod packs 
  static LauncherMode mode = LauncherMode.LIBRE; // LauncherMode.MANAGED;

  // these mod packs that will be installed by default 
  static List<String> initialProfileUrls = [];

  static void init(){ 
    // // this is where new releases of your launcher will be downloaded from
    // // leave blank to disable 
    // // don't comment this out or it will default to BoltLauncher's update url and overwrite your app
    Branding.updatesAppCastUrl = "";

    // // used for microsoft authentication. players are trusting the owner of this id with access to their minecraft accounts
    // // get one at https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app
    // // if you keep this line commented out it will allow you to pass it in a build time so you don't have to commit it to your VCS
    // Branding.azureClientId = ""; 

    // Branding.name = "YourCustomLauncher";
    // Branding.license = "All Rights Reserved";
    // Branding.homePageDisplayUrl = "https://github.com/LukeGrahamLandry/BoltLauncher"; 

    // // where installed files are stored (just the name of a directory, not the full path as that is handled differently per operating system)
    Branding.dataDirectoryName = Branding.name; 

    // // environment variable that players can set to change where installed files are stored
    // Branding.dataDirEnvVarName = "BOLT_LAUNCHER_FOLDER"; 

    // Branding.privacyPolicy = 
    // """
    // This is where you would tell people if your launcher collects their data, or sends you any analytics, etc. 

    // Metadata servers (where game files are downloaded from) will get your ip address because that's how HTTP works. 
    // They will also be able to tell which version you're playing by which files are requested. 

    // The Microsoft identity platform is used to login to your Minecraft account. 
    // Minecraft has telemetry that sends information to Microsoft. 
    // See https://privacy.microsoft.com/en-ca/privacystatement
    // """;
  }
}

class LauncherMode {
  static const LauncherMode LIBRE = LauncherMode(addModsToProfiles: true, createProfiles: true);
  static const LauncherMode MANAGED = LauncherMode(createProfiles: false, addModsToProfiles: false);

  final bool createProfiles;
  final bool addModsToProfiles;

  const LauncherMode({
    required this.addModsToProfiles, 
    required this.createProfiles
  });
}
