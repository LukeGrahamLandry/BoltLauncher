import 'commands/help.dart';

void main(List<String> arguments) {
    if (arguments.length <= 1) {
        String program = arguments.length == 0 ? "help" : arguments[0];
        print(getHelp(program));
        return;
    }
}