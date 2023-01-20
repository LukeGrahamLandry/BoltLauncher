
import 'dart:io';

import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:bolt_launcher/src/api_models/java_metadata.dart';
import 'package:bolt_launcher/src/api_models/vanilla_metadata.dart' as vanilla;

bool supportsAppleSilicon(String mcVersion, String loader){
  int major = int.parse(mcVersion.split(".")[1]);

  if (major >= 18) return true;
  if (mcVersion == "1.16.5" && loader == VersionListHelper.FORGE.name) return true;

  return false;
}

// 1.19 works with just the normal mojang metadata
String? forcedLwjglVersion(String mcVersion, String loader){
  if (!Platform.isMacOS) return null;  // || java.architexture != "aarch64"

  if (mcVersion.startsWith("1.18")) return "3.3.1";

  // crash: no icons cocoa. needs mixin
  // if (mcVersion.startsWith("1.17")) return "3.3.1";
  if (mcVersion == "1.16.5" && loader == VersionListHelper.FORGE.name) return "3.3.1";  // forge patched the crash
  
  return null;
}

void lwjglArmNatives(String mcVersion, String modLoader, vanilla.VersionFiles metadata){
  String? lwjglVersion = forcedLwjglVersion(mcVersion, modLoader); 
  if (lwjglVersion == null) return;

  for (var lib in metadata.libraries){
    if (!lib.name.startsWith("org.lwjgl")) continue;

    forceVersion(lib.downloads.artifact, lwjglVersion);
    lib.downloads.classifiers?.forEach((key, value) {
      if (key == "natives-macos") forceVersion(value, lwjglVersion);
    });
  }
}

void forceVersion(vanilla.Artifact lib, String lwjglVersion){
  List<String> parts = lib.path!.split("/");
  String lwjglVersionOld = parts[3];

  lib.path = lib.path!.replaceAll(lwjglVersionOld, lwjglVersion).replaceAll("natives-macos", "natives-macos-arm64");
  lib.url = lib.url.replaceAll(lwjglVersionOld, lwjglVersion).replaceAll("natives-macos", "natives-macos-arm64");
  lib.sha1 = lwjglMetadata[lib.path]!["sha1"] as String;
  lib.size = lwjglMetadata[lib.path]!["size"] as int;
}

var lwjglMetadata = {
  "org/lwjgl/lwjgl/3.3.1/lwjgl-3.3.1.jar": {
    "sha1": "ae58664f88e18a9bb2c77b063833ca7aaec484cb",
    "size": 724243
  },
  "org/lwjgl/lwjgl-jemalloc/3.3.1/lwjgl-jemalloc-3.3.1.jar": {
    "sha1": "a817bcf213db49f710603677457567c37d53e103",
    "size": 36601
  },
  "org/lwjgl/lwjgl-openal/3.3.1/lwjgl-openal-3.3.1.jar": {
    "sha1": "2623a6b8ae1dfcd880738656a9f0243d2e6840bd",
    "size": 88237
  },
  "org/lwjgl/lwjgl-opengl/3.3.1/lwjgl-opengl-3.3.1.jar": {
    "sha1": "831a5533a21a5f4f81bbc51bb13e9899319b5411",
    "size": 921563
  },
  "org/lwjgl/lwjgl-glfw/3.3.1/lwjgl-glfw-3.3.1.jar": {
    "sha1": "cbac1b8d30cb4795149c1ef540f912671a8616d0",
    "size": 128801
  },
  "org/lwjgl/lwjgl-stb/3.3.1/lwjgl-stb-3.3.1.jar": {
    "sha1": "b119297cf8ed01f247abe8685857f8e7fcf5980f",
    "size": 112380
  },
  "org/lwjgl/lwjgl-tinyfd/3.3.1/lwjgl-tinyfd-3.3.1.jar": {
    "sha1": "0ff1914111ef2e3e0110ef2dabc8d8cdaad82347",
    "size": 6767
  },
  "org/lwjgl/lwjgl/3.3.1/lwjgl-3.3.1-natives-macos-arm64.jar": {
    "sha1": "71d0d5e469c9c95351eb949064497e3391616ac9",
    "size": 42693
  },
  "org/lwjgl/lwjgl-jemalloc/3.3.1/lwjgl-jemalloc-3.3.1-natives-macos-arm64.jar": {
    "sha1": "e577b87d8ad2ade361aaea2fcf226c660b15dee8",
    "size": 103475
  },
  "org/lwjgl/lwjgl-openal/3.3.1/lwjgl-openal-3.3.1-natives-macos-arm64.jar": {
    "sha1": "23d55e7490b57495320f6c9e1936d78fd72c4ef8",
    "size": 346125
  },
  "org/lwjgl/lwjgl-opengl/3.3.1/lwjgl-opengl-3.3.1-natives-macos-arm64.jar": {
    "sha1": "eafe34b871d966292e8db0f1f3d6b8b110d4e91d",
    "size": 41665
  },
  "org/lwjgl/lwjgl-glfw/3.3.1/lwjgl-glfw-3.3.1-natives-macos-arm64.jar": {
    "sha1": "cac0d3f712a3da7641fa174735a5f315de7ffe0a",
    "size": 129077
  },
  "org/lwjgl/lwjgl-stb/3.3.1/lwjgl-stb-3.3.1-natives-macos-arm64.jar": {
    "sha1": "fcf073ed911752abdca5f0b00a53cfdf17ff8e8b",
    "size": 178408
  },
  "org/lwjgl/lwjgl-tinyfd/3.3.1/lwjgl-tinyfd-3.3.1-natives-macos-arm64.jar": {
    "sha1": "972ecc17bad3571e81162153077b4d47b7b9eaa9",
    "size": 41380
  }
};