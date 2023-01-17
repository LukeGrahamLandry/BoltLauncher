
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/api_models/java_metadata.dart';
import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart' as vanilla;
import 'package:bolt_launcher/src/api_models/fabric_metadata.dart' as fabric;
import 'package:bolt_launcher/src/api_models/prism_metadata.dart' as prism;
import 'package:bolt_launcher/src/launch/base.dart';

typedef LauncherFactory = Future<GameLauncher> Function(String minecraftVersion, String loaderVersion, String gameDirectory);

abstract class LoaderMeta {
  String get name;
  Future<List<String>> get supportedMinecraftVersions => Future.value(["1.19.3", "1.19.2", "1.19.1", "1.19", "1.18.2", "1.18.1", "1.18", "1.17.1", "1.17", "1.16.5"]);
  Future<List<String>> versions(String minecraftVersion) => Future.value(["0"]);
  Future<String> recommendedVersion(String minecraftVersion) => Future.value("0");
  bool get hasLoaderVersions => true;
  LauncherFactory get launcher;
}

class VersionListHelper {
  static LoaderMeta VANILLA = VanillaLoaderMeta();
  static LoaderMeta FABRIC = FabricLoaderMeta();
  static LoaderMeta QUILT = QuiltLoaderMeta();
  static LoaderMeta FORGE = ForgeLoaderMeta();

  static Map<String, LoaderMeta> modLoaders = {
    "vanilla": VANILLA,
    "fabric": FABRIC,
    "quilt": QUILT,
    "forge": FORGE
  };

  static Future<int> suggestedJavaMajorVersion(String minecraftVersion) async {  // TODO: should read from metadata
    int mcMinorVersion = int.parse(minecraftVersion.split(".")[1]);
    return mcMinorVersion > 16 ? 17 : 8;  
  }

  static Future<String> suggestedJavaExecutable(int majorVersion) async {  // TODO: check architecture 
    List<JavaInfo> installations = await JavaFinder.search();  // TODO fix arch 
    return installations.firstWhere((element) => element.majorVersion == majorVersion && element.architexture == "x86_64").executablePath;
  }
}

class ForgeLoaderMeta extends LoaderMeta {
  @override
  String get name => "forge";

  @override
  // TODO: temp, read from actual forge metadata instead
  Future<List<String>> get supportedMinecraftVersions async {
    var versions = await super.supportedMinecraftVersions;
    versions.remove("1.17");
    return versions;
  }

  @override
  Future<String> recommendedVersion(String minecraftVersion) async {  // TODO: it will crash on null check if forge doesnt have a release yet
    Map<String, String> versions = await MetadataCache.forgeRecommendedVersions;
    return versions["$minecraftVersion-recommended"] ?? versions["$minecraftVersion-latest"]!;
  }

  @override
  Future<List<String>> versions(String minecraftVersion) {
    throw UnimplementedError();
  }
  
  @override
  LauncherFactory get launcher => ForgeLauncher.create;
}

class FabricLoaderMeta extends LoaderMeta {
  @override
  String get name => "fabric";

  @override
  Future<String> recommendedVersion(String minecraftVersion) async {
    return (await versions(minecraftVersion)).first;
  }

  @override
  Future<List<String>> versions(String minecraftVersion) async {
    fabric.VersionList versions = await MetadataCache.fabricVersions;
    return versions.loader.map((e) => e.version).toList();
  }
  
  @override
  LauncherFactory get launcher => FabricLauncher.create;
}

class QuiltLoaderMeta extends LoaderMeta {
  @override
  String get name => "quilt";

  @override
  Future<String> recommendedVersion(String minecraftVersion) async {
    return (await versions(minecraftVersion)).first;
  }

  @override
  Future<List<String>> versions(String minecraftVersion) async {
    fabric.VersionList versions = await MetadataCache.quiltVersions;
    return versions.loader.map((e) => e.version).toList();
  }
  
  @override
  LauncherFactory get launcher => QuiltLauncher.create;
}

class VanillaLoaderMeta extends LoaderMeta {
  @override
  String get name => "vanilla";

  @override
  bool get hasLoaderVersions => false;
  
  @override
  LauncherFactory get launcher => (minecraftVersion, loaderVersion, gameDirectory) {
    return VanillaLauncher.create(minecraftVersion, gameDirectory);
  };
}
