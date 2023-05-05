# How the forge installer works

The process for installing forge is much more involved than fabric. Instead of using mixin to modify the byte code at runtime, forge relies on applying patches to the vanilla jar file in advance to inject their hooks. 

For fabric the installer fetches the metadata it needs from an api that anyone can access. Forge bundles all the information needed for installation in their installer jar file, that can be downloaded on their website, instead of providing an api. I assume this was done to force more people to click through the adfocus link to get it so Lex can get paid. 

Luckily when it finally lets you actually download the installer, it just takes you to the link in maven so we can correctly guess the link to get the installer jar file for any version of forge without going through the ads. The url is `https://maven.minecraftforge.net/net/minecraftforge/forge/VERSION/forge-VERSION-installer.jar` where `VERSION` is `MINECRAFT_VERSION-FORGE_VERSION`. Note each forge version will have only one valid minecraft version. The list of forge versions for each minecraft version can be retried from `https://files.minecraftforge.net/net/minecraftforge/forge/maven-metadata.json`.

Once you have the jar file, you can't just run programmatically without it showing you its GUI. Instead, we have to extract the data from the jar (jar files are just zip files with a different extension) and figure out how to run the processors that apply their code patches ourselves. 

## install_profile.json

Contains the data needed to preform the installation. Carefully gitignored so you can't just get it from the repository. 

### libraries Field

The `libraries` list is in the same format as the vanilla version data json file. It's just a bunch of files that are needed to run the processors to go download. 

### data Field

The `data` object contains information that must be passed to the processors as command line arguments. 

```js
data: {
    key: {
        client: value,
        server: value
    }
}
```

There are a few ways the value must be parsed before being used.

- if it starts with a `/`, its a resource from the installer jar file that must be extracted and then the full path is used as the argument. 
- if it starts with a `[`, its a maven like identifier thingy, to be expanded into a full path in the library folder to be used as an argument. This doesn't mean its something that actually exists on their maven to go download. It's just a way to describe the file path where a processor can output something to be passed to another one. 
- if it starts with a `'`, its just a string to use after removing the `'`

### processors Field 

The `processors` list says what tasks have to happen in sequence to produce the final patched minecraft jar that will be used at runtime. 

The `sides` list will have `client` or `server` so you can decide if this processor needs to be run. If `sides` isn't present it means both.

The `jar` string and `classpath` list are maven identifiers that get expanded into paths in the libraries folder and put on the classpath to run the task. Use the main class from the `jar`, which can be determined by extracting its `META-INF/MANIFEST.MF` file. It feels a bit awkward but using the `-jar` option of the java command doesn't let you specify other things to put on the classpath. 

The `args` list has the arguments that must be passed on the command line. Replacements to be made are indicated by wrapping a key in `{}`. These will be from the `data` map or some additional hardcoded ones. 

- ROOT: I've only seen it in the server processors so i don't care
- INSTALLER: the path to the installer jar file
- MINECRAFT_JAR: the path to the vanilla minecraft jar file
- SIDE: the physical dist (in lowercase)

Some also have an `outputs` object that maps a location to a hash value (from `data`) so you can check that the task was successful before continuing to the next part.

Use all that to build a command, run it and repeat for each entry in the list. 

## Launching the Game

The installer jar also has a `version.json` file in the same format as the vanilla one that tells you the libraries to download, the arguments needed and the main class to use. There's also an `inheritsFrom` field that points to the vanilla one for that version so you have to include the values from that one as well.  

## Further Reading

- https://github.com/PolyMC/polymorphosis/blob/develop/README.md