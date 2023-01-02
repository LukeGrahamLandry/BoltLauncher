import 'commands/help.dart';
import 'package:bolt_launcher/bolt_launcher.dart';

Future<void> main(List<String> arguments) async {
    installVanilla("1.19.2");

    return;
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

    // TODO: be aware of optional --named flags
    if (program == "create") arguments.length == 4 ? installEmptyProfile(arguments[1], arguments[2], arguments[3]) : getHelp(program);
    if (program == "install") arguments.length == 3 ? installProfileFromUrl(arguments[1], arguments[2]) : getHelp(program);
    
}


void installEmptyProfile(String name, String loader, String version) {

}

void installProfileFromUrl(String name, String url) {

}
