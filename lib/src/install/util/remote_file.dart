
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class RemoteFile {
  final String url;
  final String? path;
  final String sha1;
  String get wellKnownSubFolder => "";
  int? size;

  RemoteFile(this.url, this.path, this.sha1, this.size);

  String get fullPath {
    return p.join(Locations.installDirectory, path!);
  }

  static bool isCode(RemoteFile lib) => lib.fullPath.endsWith(".jar");
}

class MavenFile implements RemoteFile {
  MavenArtifact artifact;
  String directory;
  late String sha1;

  MavenFile(this.artifact, this.directory);

  static Future<MavenFile> of(MavenArtifact artifact, String directory) async {
    MavenFile self = MavenFile(artifact, directory);
    self.sha1 = await artifact.sha1;
    return self;
  }

  @override
  String get fullPath => p.join(directory, artifact.path);

  @override
  String get path => artifact.path;

  @override
  String get url => artifact.jarUrl;
  
  @override
  int? size;
  
  @override
  String get wellKnownSubFolder => "libraries";
}

class MavenArtifactImpl with MavenArtifact{
  MavenArtifactImpl(String identifier, String repo){
    init(identifier, repo);
  }
}

mixin MavenArtifact {
  late String _identifier;
  late String _repo;

  void init(String identifier, String repo){
    _identifier = identifier;
    _repo = repo;
  }

  String get path => identifierToPath(_identifier);

  static String identifierToPath(String identifier){
    List<String> parts = identifier.split(":");
    String group = parts[0];
    String path = group.split(".").join("/");
    String name = parts[1];
    String version = parts[2];
    String extension = identifier.contains("@") ? identifier.split("@")[1] : "jar";

    print([group, name, version, extension]);

    if (parts.length == 3){
      return "$path/$name/$version/$name-$version.$extension";
    } else {
      String classifier = parts[3];
      return "$path/$name/$version/$name-$version-$classifier.$extension";
    }
  }

  String get jarUrl {
    return "$_repo$path";
  }

  String get sha1Url {
    return "$jarUrl.sha1";
  }

  Future<String> get sha1 async {
    print(sha1Url);
    var response = await http.get(Uri.parse(sha1Url));
    if (response.statusCode != 200) {
        throw Exception('Failed to load $sha1Url');
    } 
    return response.body;
  }
}