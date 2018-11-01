import std.stdio;
import dcli.programoptions;
import dcli.programcommands;

alias MainCommands = ProgramCommands!(
    ProgramOptions!(
        Option!("glob1", string).shortName!"a".description!"desc",
    ),
    Command!"cmd1"
        .options!(
            ProgramOptions!(
                Option!("opt1", string).shortName!"b".description!"desc",
            ),
    ),
    Command!"cmd2"
        .description!"desc",
    Command!"cmd3"
        .options!(
            ProgramCommands!(
                ProgramOptions!(
                    Option!("opt3", string).shortName!"d".description!"desc",
                ),
                Command!"sub1"
                    .options!(
                        ProgramOptions!(
                            Option!("opt4", string).shortName!"e".description!"desc",
                        ),
                    )
                    .description!"desc",
            ),
        )
        .description!"desc",
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
        writeln("cmd3 ");
    }

    commands.helpText.writeln;
}
