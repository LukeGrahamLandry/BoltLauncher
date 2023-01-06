
import 'package:bolt_launcher/bolt_launcher.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class RemoteFile {
  final String url;
  final String path;
  final String sha1;
  String get wellKnownSubFolder => "";
  int? size;

  RemoteFile(this.url, this.path, this.sha1, this.size);

  String get fullPath {
    return p.join(Locations.installDirectory, path);
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

mixin MavenArtifact {
  late String _identifier;
  late String _repo;

  void init(String identifier, String repo){
    _identifier = identifier;
    _repo = repo;
  }

  String get path {
    List<String> parts = _identifier.split(":");
    String group = parts[0];
    String path = group.split(".").join("/");
    String id = parts[1];
    String version = parts[2];

    return "$path/$id/$version/$id-$version.jar";
  }

  String get jarUrl {
    return "$_repo$path";
  }

  String get sha1Url {
    return "$jarUrl.sha1";
  }

  Future<String> get sha1 async {
    var response = await http.get(Uri.parse(sha1Url));
    if (response.statusCode != 200) {
        throw Exception('Failed to load $sha1Url');
    } 
    return response.body;
  }
}