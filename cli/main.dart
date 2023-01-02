import 'commands/clear.dart';
import 'commands/help.dart';
import 'package:bolt_launcher/bolt_launcher.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:args/args.dart';

import 'commands/install.dart';

Future<void> main(List<String> arguments) async {
    String program = arguments.isEmpty ? "help" : arguments[0];

    if (program == "list"){
        (await getProfiles()).forEach((key, value) {
            print("$key: $value");
        });
        return;
    }

    if (arguments.length <= 1) {
        print("");
        print(getHelp(program));
        print("");
        return;
    }

    if (program == "clear" && arguments[1] == "confirm") clearCommand(arguments);
    if (program == "install") installCommand(arguments);
}
