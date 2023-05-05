## 23-01-19

forcing lwjgl to 3.3.1 fixes using an arm jre for 1.18+.
but 1.16/1.17 fail with "cocoa regular windows do not have icons". could be fixed with my M1Fix mixin but then i need to inject a mod.
somehow m1craft app works
so does prism but maybe their patched version of lwjgl from random github doesn't throw that error and just ignores the set icon call 

launching forge 1.16.5 36.2.34 works but if i launch it in the life in the village directory it doesnt 
!! com.therandomlabs.randompatches.client.RPWindowHandler.updateWindowIcon fucks with it
- should submit a pr and reference forge's patch to vanilla for the same issue https://github.com/MinecraftForge/MinecraftForge/pull/8468/files#diff-28a19247da770bf100ac9858ebdc0bf74f464ab682c71e2e4460aef03b6ec664R130
- https://github.com/TheRandomLabs/RandomPatches/blob/1.16-forge/src/main/java/com/therandomlabs/randompatches/client/RPWindowHandler.java#L200
- also fixed by setting client > window > custom_icon to false in randompatches.toml

so fabric 1.16.5 might be the only meaningful one that breaks but like nobody plays that cause fabric is forwards obsessed. 

little script to generate the hashes and sizes of the new versions and natives that i force it to use. for now I'm hardcoding it in because I don't really like the idea of forcing people to trust my magic url for it. if it turns out they break, people can always toggle on prism metadata instead. 

```dart
Map<String, Map<String, dynamic>> data = {};

for (var library in metadata.libraries){
	if (!library.name.startsWith("org.lwjgl")) continue;
	
	List<Artifact> libs = [library.downloads.artifact];
	if (library.downloads.classifiers?["natives-macos"] != null){
		libs.add(library.downloads.classifiers!["natives-macos"]!);
	}

	for (var lib in libs){
		var bytes = await File(lib.fullPath).readAsBytes();
		data[lib.path!] = {
			"sha1": sha1.convert(bytes).toString(),
			"size": bytes.length
		};
	}
}

print(JsonEncoder.withIndent(' ').convert(data));
```

## 23-01-16

problem with appendJsonObject. it was reading in an empty file at a point that i should definitely have previous data already because of my locking stuff. i was missing an await on the write so it would create the file and then return and unlock before actually writing so you'd end up with two versions of the blank object floating around. shouldn't happen again because i added the lint rule for it (found a bunch more to fix).

## 23-01-15

failing to load fabric with the fabric-api mod. a bunch of errors like `ava.lang.ClassNotFoundException: net/minecraft/class_2621`. i think i actually need to download the intermediary mappings jar since all the mods will reference those instead of the actual obfuscated names. fixed by treating the `intermediary` object from metadata the same as `loader`, just get and put on classpath. 

finding the instances was really slow, like consistently 1/4 seconds each. was because it was refinding all the java installs for each to pick a good one to set as the executable to use. fixed by saving JavaFinder#search results to a json file the first time and reading that back if it exists instead of refinding. this gets instance import time down to basiclly 0. 

## 23-01-14

finding curseforge instances by looking in the well known directory instances folder and parsing minecraftinstance.json to get loader and version. then just run the game with that as the game directory. debating if i should read their version jsons from that file for the install or just use my own metadata (currently the latter). they should always be the same if everything's going normally. should at least fallback to theirs if no network so you can play offline. 

### trying to run forge 36.2.33 instance 

I imported it from curseforge but all the problems exist anyway. i couldn't actually run 1.16.5 before. 

adding jvm arg `-Dfml.earlyprogresswindow=false` fixes `Cocoa: Failed to find service port for display` (https://forums.minecraftforge.net/topic/94803-javalangillegalstateexception-glfw-error-before-init-0x10008cocoa-failed-to-find-service-port-for-display/)

it still crashed with a different error
- `Caused by: java.lang.NoSuchMethodError: org.apache.logging.log4j.core.impl.ThrowableProxy.formatExtendedStack`
- tried using the curseforge jvm but didnt change anything
- all 3 log4j jars (api, core, impl) are on the classpath command
- vanilla version json wants log4j 2.8.1 but the forge version json wants log4j 2.15.0. both are on classpath command 
- but also it looks like this error is happening while its trying to log out the crash report from something else. it has a different indentation level and says `java.lang.Throwable:printStackTrace` but above there are errors with `java.lang.ThreadGroup:uncaughtException`. 

```
java.lang.reflect.InvocationTargetException
...
at java.lang.reflect.Method.invoke(Method.java:498)
at net.minecraftforge.fml.loading.FMLClientLaunchProvider.lambda$launchService$0(FMLClientLaunchProvider.java:51)
```
not finding `net.minecraft.client.main.Main` i guess. the vanilla version jar is on classpath command tho. taking it off breaks things even more even though i imagine forge uses its own patched version instead. 

i tried the python [minecraft-launcher-lib](https://gitlab.com/JakobDev/minecraft-launcher-lib) and it installed and ran 1.16.5-forge-36.2.34 fine when running out of the official launcher directory. tried running it out of my directory and it still works. the obvious difference in its install is that it creates versions/1.16.5-forge-36.2.34/1.16.5-forge-36.2.34.jar like the official installer does. but after that (and without deleting anything) running with mine still doesn't work. so it's not as simple as just renaming that file, its a command problem. also checked the hash and its the same normal vanilla jar file. 

printed the launch commands generated by each to investigate. running the command minecraft-launcher-lib generates in terminal works. running the command bolt generates in terminal does not work (with error above).  

I tried copying their classpath section in to my command and that works. so we know its something missing from my classpath. 
- confirmed problem is not the version jar not being called 1.16.5-forge-36.2.34.jar

wrote a script to check the difference in our classpaths. 
```python
py_lib_classpath = "...".strip().split(":")
bolt_classpath = "...".strip().split(":")

print("In bolt but not in minecraft-launcher-lib")
for x in bolt_classpath:
	if x not in py_lib_classpath:
		print("-", x)

print("In minecraft-launcher-lib but not in bolt")
for x in py_lib_classpath:
	if x not in bolt_classpath:
		print("-", x)
```
The only difference is the natives jars i put on there. maybe its the order??! mine has `.../libraries/.../forge-1.16.5-36.2.34.jar` somewhere in the middle and theirs has is at the very beginning. YUP. 

in launch/forge.dart ForgeLauncher get classpath
```dart
// crashes with InvocationTargetException decsribed above
return "${vanilla.classpath}:${DownloadHelper.toClasspath(forgeLaunchLibs)}".split(":").toSet().join(":")

// works perfectly 
return "${DownloadHelper.toClasspath(forgeLaunchLibs)}:${vanilla.classpath}".split(":").toSet().join(":")
```

had similar discovery with fabric before

#### another error higher up

while trying to debug the above, scrolled up even more and found 
```
main ERROR Could not find class in ReflectionUtil.getCallerClass(2). java.lang.ClassNotFoundException: net.minecraftforge.fml.javafmlmod.FMLJavaModLanguageProvider

main ERROR Could not find class in ReflectionUtil.getCallerClass(2). java.lang.ClassNotFoundException: net.minecraftforge.fml.mclanguageprovider.MinecraftModLanguageProvider
```

`java.lang.ClassNotFoundException: net.minecraftforge.fml.javafmlmod.FMLJavaModLanguageProvider` maybe the processors just didnt finish properly. implemented the checking hashes from outputs object in processors from install_profile.json but they said its fine. 

turns out i was just running on java 17 accidentally when testing with the launch command because i did an == on a future without await. fixing that still doesnt get rid of the InvocationTargetException above tho. 

#### 1.16.5- relies on libraries being in the same folder

while trying to debug the above, switching to recommended forge (36.2.34) changed the error 
```
Failed to find forge version 36.2.34 for MC 1.16.5 at /Users/luke/Library/Application Support/PrismLauncher/libraries/net/minecraftforge/forge/1.16.5-36.2.34/forge-1.16.5-36.2.34-universal.jar 

...at net.minecraftforge.fml.loading.FMLCommonLaunchHandler.validatePaths
```
that is not in fact the correct path it should be linking to and it doesnt show up in the launch command so it must be guessing based on something else. 

https://github.com/MinecraftForge/MinecraftForge/blob/1.16.x/src/fmllauncher/java/net/minecraftforge/fml/loading/LibraryFinder.java#L23

forge doesn't have you pass in everything on the classpath. it guesses the library folder based on ` findJarPathFor("org/objectweb/asm/Opcodes.class", "asm");`  and then finds specific jars in there. so i guess if that magic jar was a link, it will find the location of the real file not the link file and assume everything else must be in the same place. this is only a problem for 1.16.5 and before. in 1.17+ they just respect the `libraryDirectory` property like not crazy people. 
- tried to fix this by just always copying instead of linking if the jar path has `org/objectweb/asm` but that's not the right group i guess. in that group is in the lib folder or on the classpath command. so i guess its bundled somewhere? have to figure out where that jar is i guess
- just always copying and not linking does get rid of this error but brings back the previous InvocationTargetException

## 23-01-12

### try extracting natives to make old versions work

i think extracted natives all go in one directory. i dont know what the hash used for subdir name in official launcher is but i think it just splits up the ones for different mc versions and then included in the natives dir argument 

```dart
// VanillaInstaller
Future<void> extractNative(String path) async {
	String nativesDir = p.join(Locations.installDirectory, "bin", minecraftVersion);
	await Directory(nativesDir).create(recursive: true);
	Archive zipped = ZipDecoder().decodeBytes(await File(path).readAsBytes());
	
	// this does not support nested folders but that's always fine?
	for (var file in zipped.files){ 
		if (file.isFile){
			var outFile = File(p.join(nativesDir, file.name));
			outFile = await outFile.create(recursive: true);
			await outFile.writeAsBytes(file.content);
		}
	}
}

// added to *Launcher args list
// "-Djava.library.path=${p.join(Locations.installDirectory, "bin", minecraftVersion)}"
```

that did produce a bin folder like the normal one but didnt fix the crash. figured out it was an architecture thing later so i really don't know why I other things bother to extract manually. maybe you needed to pre-1.13

prism does extract natives to /PrismLauncher/instances/1.18.2/natives but at runtime. the folder disappears when the game stops

the official launcher does not create the bin directory for 1.19.3 but it does for 1.18.2. dont understand :(
for the jre problem official launcher just says go fuck yourself and installs java-runtime-beta for 1.18.2 which is always x86
java-runtime-gamma for 1.19+ is aarch64

### get old versions running on x86

1.18.2 on aarch64 jre gives error 
```
Exception in thread "Render thread" [21:54:13] [Render thread/INFO]: [STDERR]: java.lang.NoClassDefFoundError: Could not initialize class com.mojang.blaze3d.systems.RenderSystem
[21:54:13] [Render thread/INFO]: [STDERR]: at ac.a(SourceFile:65)
[21:54:13] [Render thread/INFO]: [STDERR]: at dyr.a(SourceFile:2394)
[21:54:13] [Render thread/INFO]: [STDERR]: at dyr.a(SourceFile:2389)
[21:54:13] [Render thread/INFO]: [STDERR]: at net.minecraft.client.main.Main.main(SourceFile:206)
```
I thought it was because i didnt extract natives but actually its wrong lwjgl for apple silicon. looked famillier from when i was trying to setup forge dev environment on new computer. 

Works fine if you switch to a x86 jre. still don't need to extract natives
gives GLFW error collected during initialization: GLFW error during init: `[0x10008]13116348592 (GLFW_PLATFORM_ERROR A platform-specific error occurred that does not match any of the more specific categories.)`
but the game works fine.

same for 1.17.1 and 1.16.5 and 1.15.2 and 1.14.4 and 1.13.2
so problem was not natives extracting. its that only 1.19 supports apple silicon properly

if you tell prism to use an aarch64 one it works
prism meta https://meta.prismlauncher.org/v1/org.lwjgl3/3.2.1.json
has osx-arm64 natives that come from https://github.com/MinecraftMachina/lwjgl3/releases
they had ManyMC which was a multimc fork that worked for apple silicon and was merged into prism
lwjgl.org doesnt release arm build until 3.3.0 so idk how to get around using some random guy's thing other than forcing it to use a newer version of the library but i think that would need mixins to minecraft like my previous m1 fixes so then they're back to trusting me but i guess that's better than more people. also wouldn't work for vanilla. 

I found https://github.com/ezfe/m1craft
has a swift library for actually launching minecraft https://github.com/ezfe/minecraft-jar-command
claims to be using official lwjgl build so maybe 3.3.0 just works magically without mixin stuff
api like https://m1craft.ezekiel.dev/api/patch/1.16.5.json that tells it which version to swap to, generated by https://github.com/ezfe/m1craft-server/blob/main/Sources/App/Controllers/ApiController.swift
found from https://gist.github.com/ezfe/8bc43a65e16b79c955f81b4d7fa4ae6a which references random backblaze urls but it seems that they're on libraries.minecraft.net as well by the pactches api. 
explained in gist comments: its the bandwidth thing apparently "They are sourced from the LWJGL download page and rehosted as a courtesy to the LWJGL folks.". this has it correctly linked to lwjgl.org https://gist.github.com/ezfe/fcd2410a123cb596786bed3702660808 so if it turns out mc site doesnt have it, i can use those which is even better kinda

side effect of using shitty emulated jre is that i had to add more required runtime to my test because the game doesn't even start in 15 seconds anymore. 

### tests failing on some old version

both must just be warnings that happen to be on stderr for some reason because the game still starts and works fine. worst case i can just have the tests ignore these specific strings and build up a list of those that don't matter

tests for forge pre 1.18.2 fail with 
```
SLF4J: No SLF4J providers were found.
SLF4J: Defaulting to no-operation (NOP) logger implementation
SLF4J: See http://www.slf4j.org/codes.html#noProviders for further details.
```
dont even know what i means cause stuff does still get logged normally. hopefully it will fix itself when i properly parse the cli arguments from json. 

fabric 1.16.5 failed with
```
ScriptEngineManager providers.next(): javax.script.ScriptEngineFactory: Provider jdk.nashorn.api.scripting.NashornScriptEngineFactory not found
```

### finding official launcher java

they have it structured a bit awkwardly so i have lots of nested loops instead of a the flat structure most jre locations have. `minecraft > runtime > java-runtime-LETTER[] > OS > java-runtime-LETTER`. but otherwise there's nothing special. 

legacy -> java 8 x86 (1.16.5-)
beta -> java 17 x86 (1.18.2-)
gamma -> java 17 arm (1.19+)

### logging 

went through and used specific logger classes like the download one for installing and launching so they can report detailed progress to the gui. there's a complicated hierarchy of having the launch contain the install contain the download so i'll probably have to figure out some other way to think about it that makes it simple at some point. 

### rearange meta cache

moved cached meta jsons into subdirs by loader so it looks less messy. changed names so they match the ones used by the official installers just as a step toward possibly using the same versions directory structure as the official launcher. 

there's kinda no point having my own directory in the corner where i pretend to reinstall everything but actually symlink, it might make more sense to just run myself out of the vanilla launcher and have a separate instances folder. it would even be fine if i add the profiles to the official launcher because there's a field to specify the game directory so the mods could be kept separate. 

if i do that have to remember that the fabric ones put a fake main jar in their version directory to calm down the official launcher cause they don't have to modify vanilla. so then just add the normal one and their loader wrapper thing to the classpath. https://github.com/FabricMC/fabric-installer/blob/master/src/main/java/net/fabricmc/installer/client/ClientInstaller.java#L50-L58 seems them just putting their version json that's in the right format there would make the launcher install everything. 

