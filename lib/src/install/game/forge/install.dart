import 'dart:io';

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/install/util/downloader.dart';
import 'package:bolt_launcher/src/install/util/problem.dart';
import 'package:bolt_launcher/src/api_models/prism_metadata.dart' as prism;
import 'package:bolt_launcher/src/install/util/remote_file.dart';
import 'package:path/path.dart' as p;

class ForgeWrapperInstaller implements MinecraftInstaller {	
  String minecraftVersion;
  String loaderVersion;
  late VanillaInstaller vanilla;
  
  late DownloadHelper downloadHelper;

  late RemoteFile officialForgeInstaller;

  ForgeWrapperInstaller(this.minecraftVersion, this.loaderVersion) {
    vanilla = VanillaInstaller(minecraftVersion);
  }
  
  @override
  Future<void> install() async {
    await vanilla.install();

    var metadata = await getMetadata();
    if (metadata == null){
			print("Forge $minecraftVersion $loaderVersion not found.");
			return;
		}

    officialForgeInstaller = (await findInstaller())!;
    downloadHelper = DownloadHelper(List.of(metadata.libraries.map((e) => e.downloads.artifact))..add(officialForgeInstaller));
    await downloadHelper.downloadAll();
  }

  Future<prism.VersionFiles?> getMetadata() async {
    prism.VersionList versionData = await MetadataCache.forgeVersions;

    bool exists = false;
    for (var version in versionData.versions){
      if (version.version == loaderVersion){
        exists = true;
        break;
      }
    }

    if (!exists){
      print("Forge version $loaderVersion not found");
      return null;
    }

     return prism.VersionFiles.fromJson(await cachedFetchJson("${GlobalOptions.metadataUrls.prismLike}/net.minecraftforge/$loaderVersion.json", "forge-$loaderVersion.json"));
  }

  Future<RemoteFile?> findInstaller() async {
    prism.VersionList versionData = await MetadataCache.forgeVersions;

    bool exists = false;
    for (var version in versionData.versions){
      if (version.version == loaderVersion){
        exists = true;
        break;
      }
    }

    if (!exists){
      print("Forge version $loaderVersion not found");
      return null;
    }

    return MavenFile.of(MavenArtifactImpl("net.minecraftforge:forge:$minecraftVersion-$loaderVersion:installer", "${GlobalOptions.metadataUrls.forgeMaven}/"), p.join(Locations.installDirectory, "libraries"));
  }

  // the order of the classpath matters
  // if you do "${downloadHelper.classPath}:${vanilla.jarDownloadHelper.classPath}" it starts running the main class from the first chunk before loading the second chunk of classes
  // java.lang.NoSuchMethodError: com.google.gson.JsonParser: method 'void <init>()' not found
 @override
  String get launchClassPath => "${vanilla.jarDownloadHelper.classPath}:${downloadHelper.classPath}";

  @override
  Future<String> get launchMainClass async {
    return (await getMetadata())!.mainClass;
  }

  @override
  String get versionId => vanilla.versionId;

  @override
  List<Problem> get errors => downloadHelper.errors + vanilla.jarDownloadHelper.errors;

}
