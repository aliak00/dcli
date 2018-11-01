module dcli.programcommands;

import dcli.programoptions;
import ddash.lang: Void, isVoid;
import optional;
import ddash.algorithm: indexWhere;
import ddash.range: frontOr;

import std.algorithm: map;
import std.typecons;
import std.stdio: writeln;

// version = dcli_programcommands_debug;

private void debug_print(Args...)(Args args, int line = __LINE__, string file = __FILE__) @trusted @nogc {
    version(dcli_programcommands_debug) {
        debug {
            import std.stdio: writeln;
            import std.path: baseName, stripExtension, dirName, pathSplitter;
            import std.range: array;
            auto stripped = baseName(stripExtension(file));
            if (stripped == "package") {
                stripped = pathSplitter(dirName(file)).array[$ - 1] ~ "/" ~ stripped;
            }
            writeln("[", stripped, ":", line, "] : ", args);
        }
    }
}

private template isCommand(T) {
    import std.traits: isInstanceOf;
    enum isCommand = isInstanceOf!(CommandImpl, T);
}

private template isProgramCommands(T) {
    import std.traits: isInstanceOf;
    enum isProgramCommands = isInstanceOf!(ProgramCommands, T);
}

private struct CommandImpl(
    string _name,
    string _description = null,
    _Options = Void,
) {
    alias Name = _name;
    alias Description = _description;
    alias Options = _Options;
    public alias description(string value) = CommandImpl!(Name, value, Options);
    public static template options(U) if (isProgramOptions!U || isProgramCommands!U) {
        alias options = CommandImpl!(Name, Description, U);
    }

    private bool active = false;
    public T opCast(T: bool)() {
        return active;
    }
    public Options optionsPayload;
    alias optionsPayload this;
}

public template Command(string name) {
    alias Command = CommandImpl!name;
}

/*
    These two functions are here so because both ProgramCommands and ProgramOptions adhere to an interface that
    has these two functions. And when a Command is created that is only a command with no inner options or
    commands, then it resolves to type Void. So these function "fake" a similar interface for Void.
*/
private void parse(Void, const string[]) {}
private string toString(Void) { return ""; }

public struct ProgramCommands(Commands...) if (Commands.length > 0) {
    import std.conv: to;

    static if (isProgramOptions!(Commands[0])) {
        // We have a global set of options if the first argument is a ProgramOptions type.
        enum StartIndex = 1;
        public Commands[0] options;
    } else {
        enum StartIndex = 0;
    }

    // Mixin the variables for each command
    static foreach (I; StartIndex .. Commands.length) {
        static assert(
            isCommand!(Commands[I]),
            "Expected type Command. Found " ~ Commands[I].stringof ~ " for arg " ~ I.to!string
        );
        mixin("public Commands[I] " ~ Commands[I].Name ~ ";");
    }

    // Get all available commands
    private immutable allCommands = () {
        string[] result;
        static foreach (I; StartIndex .. Commands.length) {
            result ~= Commands[I].Name;
        }
        return result;
    }();

    private void parseCommand(string cmd, const string[] args) {
        command: switch (cmd) {
            static foreach (I; StartIndex .. Commands.length) {
                mixin(`case "` ~ Commands[I].Name ~ `":`);
                    mixin(Commands[I].Name ~ ".parse(args);");
                    break command;
            }
            default:
                debug_print("cannot parse invalid command: " ~ cmd);
                break;
        }
    }

    /// Sets a command to true for when it was encountered
    private void activateCommand(string cmd) {
        command: switch (cmd) {
            static foreach (I; StartIndex .. Commands.length) {
                mixin(`case "` ~ Commands[I].Name ~ `":`);
                    mixin(Commands[I].Name ~ ".active = true;");
                    break command;
            }
            default:
                debug_print("cannot activate invalid command: " ~ cmd);
                break;
        }
    }

    /// Returns trur if a string is a valid command
    private bool isValidCommand(string cmd) {
        import std.algorithm: canFind;
        return allCommands.canFind(cmd);
    }

    private alias PluckCommandResult = Tuple!(const(string)[], string, const(string)[]);
    private PluckCommandResult pluckCommand(const string[] args) {
        alias pred = (a) => this.isValidCommand(a);
        return args.indexWhere!pred
            .map!((i) {
                return PluckCommandResult(
                    args[0 .. i],
                    args[i],
                    i > 0 ? args[i + 1 .. $] : [],
                );
            })
            .frontOr(PluckCommandResult.init);
    }

    public void parse(const string[] args) {
        auto data = pluckCommand(args);

        debug_print("plucked => ", data);

        if (data[0].length) {
            options.parse(data[0]);
        }

        if (data[1].length) {
            activateCommand(data[1]);
            parseCommand(data[1], data[2]);
        }
    }

    public string helpText() const {
        string ret;
        static if (isProgramOptions!(Commands[0])) {
            ret ~= options.helpText;
            ret ~= "\n";
        }
        static if (StartIndex < Commands.length)
            ret ~= "Commands:\n";
        static foreach (I; StartIndex .. Commands.length) {
            ret ~= "  " ~ Commands[I].Name ~ "  " ~ mixin(Commands[I].Name ~ ".Description");
            static if (I < Commands.length - 1)
                ret ~= "\n";
        }
        return ret;
    }

    public string toString() const {
        import std.conv: to;
        string ret = "{ ";
        static if (isProgramOptions!(Commands[0])) {
            ret ~= "options: " ~ options.toString ~ ", ";
        }
        static foreach (I; StartIndex .. Commands.length) {
            ret ~= Commands[I].Name ~ ": { ";
            ret ~= "active: " ~ mixin(Commands[I].Name ~ ".active ? \"true\" : \"false\"");
            ret ~= ", ";
            static if (isProgramOptions!(Commands[I].Options)) {
                ret ~= "options";
            } else {
                ret ~= "commands";
            }
            ret ~= ": " ~ mixin(Commands[I].Name ~ ".toString");
            ret ~= " }";
            static if (I < Commands.length - 1) {
                ret ~= ", ";
            }
        }
        ret ~= " }";
        return ret;
    }
}
