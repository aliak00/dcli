import std.stdio;
import dcli.programoptions;

void main() {
    auto options = ProgramOptions!(
        Option!("one", string).shortName!"a".description!"desc"
    )();
    options.helpText.writeln;
}
