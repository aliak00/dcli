import std.stdio;
import dcli.programoptions;
import dcli.programcommands;

alias Command1Options = ProgramOptions!(
    Option!("opt1", string).shortName!"b".description!"desc"
);
alias Command1 = Command!"cmd1".options!Command1Options;

alias Command2 = Command!"cmd2".description!"desc";

alias Command3Sub1CommandOptions = ProgramOptions!(
    Option!("opt4", string).shortName!"e".description!"desc",
);
alias Command3Sub1Command = Command!"sub1".options!Command3Sub1CommandOptions.description!"desc";
alias Command3Options = ProgramOptions!(
    Option!("opt3", string).shortName!"d".description!"desc",
);
alias Command3Commands = ProgramCommands!(
    Command3Options,
    Command3Sub1Command,
);

alias Command3 = Command!"cmd3".options!Command3Commands.description!"desc";

alias MainOptions = ProgramOptions!(
    Option!("glob1", string).shortName!"a".description!"desc",
);
alias MainCommands = ProgramCommands!(
    MainOptions,
    Command1,
    Command2,
    Command3,
);

void main() {
    auto options = ProgramOptions!(
        Option!("one", string).shortName!"a".description!"desc"
    )();
    options.helpText.writeln;

    auto commands = MainCommands();

    commands.parse([
        "-ayo",
        "cmd3",
        "-d",
        "hi",
        "sub1",
        "-e",
        "boo",
    ]);

    if (commands.cmd1) {
        writeln("cmd1");
    }

    if (commands.cmd2) {
        writeln("cmd2");
    }

    if (commands.cmd3) {
        writeln("cmd3");
    }

    commands.helpText.writeln;
}
