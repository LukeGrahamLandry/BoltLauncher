import 'package:bolt_launcher/src/data/cache.dart';
import 'package:bolt_launcher/src/data/locations.dart';

import 'help.dart';
import 'package:bolt_launcher/bolt_launcher.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:args/args.dart';

Future<void> clearCommand(List<String> arguments) async {
  final parser = ArgParser()
                    ..addFlag("metadata", abbr: 'm')
                    ..addFlag("all", abbr: 'a')
                    ..addFlag("jars", abbr: 'j');

  ArgResults args = parser.parse(arguments);
  if (args["metadata"] as bool || args["all"] as bool){
    await Directory(Locations.metadataCacheDirectory).delete(recursive: true);
  }
  if (args["jars"] as bool || args["all"] as bool){
    await Directory(p.join(Locations.installDirectory, "libraries")).delete(recursive: true);
    await Directory(p.join(Locations.installDirectory, "versions")).delete(recursive: true);
  }
}

