import 'commands/help.dart';
import 'package:bolt_launcher/bolt_launcher.dart';

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
}
