import 'package:bolt_launcher/src/data/locations.dart';

import 'help.dart';
import 'package:bolt_launcher/bolt_launcher.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:args/args.dart';

void clearCommand(List<String> arguments) async {
  final parser = ArgParser()
                    ..addFlag("metadata", abbr: 'm')
                    ..addFlag("all", abbr: 'a')
                    ..addFlag("jars", abbr: 'j');

  ArgResults args = parser.parse(arguments);
  if (args["metadata"] as bool || args["all"] as bool){
    await Directory(Locations.metadataCacheDirectory).delete(recursive: true);
  }
  if (args["jars"] as bool || args["all"] as bool){
    await Directory(Locations.installDirectory).delete(recursive: true);
  }
}

