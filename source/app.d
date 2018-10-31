import std.stdio;
import dcli.programoptions;
import dcli.programcommands;

void main() {
    auto options = ProgramOptions!(
        Option!("one", string).shortName!"a".description!"desc"
    )();
    options.helpText.writeln;

    auto commands = ProgramCommands!(
        ProgramOptions!(
            Option!("glob1", string).shortName!"a".description!"desc",
        ),
        Command!(
            "cmd1",
            ProgramOptions!(
                Option!("opt1", string).shortName!"b".description!"desc",
            ),
            "desc",
        ),
        Command!(
            "cmd2",
            ProgramOptions!(
                Option!("opt1", string).shortName!"c".description!"desc",
            ),
            "desc",
        ),
        Command!(
            "cmd3",
            ProgramCommands!(
                ProgramOptions!(
                    Option!("opt3", string).shortName!"d".description!"desc",
                ),
                Command!(
                    "sub1",
                    ProgramOptions!(
                        Option!("opt4", string).shortName!"e".description!"desc",
                    ),
                    "desc",
                ),
            ),
            "desc",
        ),
    )();

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

    commands.writeln;
}
