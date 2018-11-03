/**
    Handles program commands, which are arguments passed to a program that are not prefixed with `-` or `--`. So that
    you handle programs that can be executed in this format:

    ---
    $ ./program -v --global-option=7 command1 --parameter="yo" sub-command --another-parameter=42
    ---

    Usage:

    The basic idea is to create a `ProgramCommands` structure and then define a number of `Command`s that it can handle and
    optionally, a set of $(DDOX_NAMED_REF dcli.program_options, `ProgramOptions`) that it can handle. Each `Command` can in
    turn have it's own `ProgramCommands`.

    Handlers:

    Handlers are provided to be able to eacily handle when a command is encountered. This will allow you to structure your
    program with a module based architecture, where each "handler" can e.g. pass the commands to a module that is build
    specifically for handling that command.

    E.g.:
    ---
    // install.d
    void commandHandler(T)(T commands) {
        writeln(commands.install); // prints true
    }
    // main.d
    static import install, build;
    void main(string[] args) {
        auto commands = ProgramCommands!(
            Command!"build".handler!(build.commandHandler)
            Command!"install".handler!(install.commandHandler)
        )();
        commands.parse(args);
        commands.executeHandlers();
    }
    // Run it
    $ ./program install
    $ >> true
    ---

    Inner_ProgramOptions:

    The first argument to a `ProgramCommands` object can optionally be a $(DDOX_NAMED_REF dcli.program_options, `ProgramOptions`)
    object. In this case, the program options are accessible with an internal variable named `options`

    E.g.:
    ---
    auto commands = ProgramCommands!(
        ProgramOptions!(Options!("opt1", string)),
        Command!"command1",
        Command!"command2".args!(
            ProgramOptions!(Options!("opt2", string))
        )
    )();

    commands.options.opt1; // access the option
    commands.command1; // access the command
    commands.command2.op2; // access the options of command2
    ---

    Inner_ProgramCommands:

    You can also pass in sub commands to a `Command` object in the `args` parameter:

    ---
    auto commands = ProgramCommands!(
        ProgramOptions!(Options!("opt1", string)),
        Command!"command1".args!(
            ProgramCommands!(
                ProgramOptions!(Options!("opt2", string)),
                Command!"sub-command1",
            ),
        ),
    )();

    commands.options.opt1; // access the option
    commands.command1.subCommand1; // access the command
    commands.command1.options.op2; // access the options of command2
    ---
*/
module dcli.program_commands;

///
unittest {
    alias MainCommands = ProgramCommands!(
        ProgramOptions!(
            Option!("glob1", string).shortName!"a".description!"desc",
        ),
        Command!"cmd1"
            .args!(
                ProgramOptions!(
                    Option!("opt1", string).shortName!"b".description!"desc",
                ),
        ),
        Command!"cmd2"
            .handler!(Fixtures.handleCommand2)
            .description!"desc",
        Command!"cmd3"
            .args!(
                ProgramCommands!(
                    ProgramOptions!(
                        Option!("opt3", string).shortName!"d".description!"desc",
                    ),
                    Command!"sub1"
                        .args!(
                            ProgramOptions!(
                                Option!("opt4", string).shortName!"e".description!"desc",
                            ),
                        )
                        .handler!(Fixtures.handleCommand3)
                        .description!"desc",
                ),
            )
            .handler!(Fixtures.handleCommand3Sub1)
            .description!"desc",
    );

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

    assert(cast(bool)commands.cmd1 == false);
    assert(cast(bool)commands.cmd2 == false);
    assert(cast(bool)commands.cmd3 == true);

    assert(commands.options.glob1 == "yo");
    assert(commands.cmd3.options.opt3 == "hi");
    assert(commands.cmd3.sub1.opt4 == "boo");

    assert(commands.helpText ==
`Options:
  -a  --glob1   desc
Commands:
  cmd1
  cmd2  desc
  cmd3  desc`
  );

    commands.executeHandlers;

    assert(!Fixtures.checkResetHandledCommand2);
    assert( Fixtures.checkResetHandledCommand3);
    assert( Fixtures.checkResetHandledCommand3Sub1);
}

import dcli.program_options;
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
    _Args = Void,
    alias _handler = null,
) {
    alias Name = _name;
    alias Description = _description;
    alias Args = _Args;
    alias Handler = _handler;

    public alias description(string value) = CommandImpl!(Name, value, Args, Handler);

    public static template args(U) if (isProgramOptions!U || isProgramCommands!U) {
        alias args = CommandImpl!(Name, Description, U, Handler);
    }

    public static template handler(alias value) {
        alias handler = CommandImpl!(Name, Description, Args, value);
    }

    private bool active = false;
    public T opCast(T: bool)() {
        return active;
    }
    public Args _args;
    alias _args this;
}

/**
    Represents one program command. One of more of these can be given to
    a `ProgramCommands` object as template arguments.

    Params:
        name = The name of the command

    Named_optional_arguments:

    A number of named optional arguments can be given to a `Command` for e.g.:
    ---
    ProgramCommands!(
        Command!"push".description!"This command pushes all your bases belongs to us"
    );
    ---

    This will create a commands object that can parse a command `push` on the command line.

    The following named optional arguments are available:

    <li>`description`: `string` - description for help message
    <li>`args`: $(DDOX_NAMED_REF dcli.program_options, `ProgramOptions`)|`ProgramCommands` - this can be given a set of program
        options that can be used with this command, or it can be given a program commands object so that it has sub commands
    <li>`handler`: `void function(T)` - this is a handler function that will only be called if this command was present on the
        command line. The type `T` passed in will be your `ProgramCommands` structure instance
*/
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

/**
    You can configure a `ProgramCommands` object with a number of `Command`s and then use it to parse
    an list of command line arguments

    The object will generate its member variables from the `Command`s you pass in, for e.g.

    ---
    auto commands = ProgramCommands!(Command!"one", Command!"two");
    commands.one // generated variable
    commands.two // generated variable
    ---

    After you parse command line arguments, the commands that are encountered on the command line become
    "activated" and can be checked by casting them to a boolean, i.e.

    ---
    commands.parse(["two"]);
    if (commands.one) {} // will be false
    if (commands.two) {} // will be true
    ---

    You can also assign "handler" to a command and use the `executeHandlers` function to call them for the
    commands that were activated.

    Params:
        Commands = 1 or more `Command` objects, each representing one command line argument. The first
            argument may be a `ProgramOptions` type if you want the command to have a set of options
            that it may handle
*/
public struct ProgramCommands(Commands...) if (Commands.length > 0) {
    import std.conv: to;

    static if (isProgramOptions!(Commands[0])) {
        // We have a global set of options if the first argument is a ProgramOptions type.
        enum StartIndex = 1;
        /**
            The `ProgramOptions` that are associated with this command if any was passed in. If no `ProgramOptions`
            where passed as an argument then this aliases to a `Void` pseudo type.
        */
        public Commands[0] options;
    } else {
        enum StartIndex = 0;
        public Void options;
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

    // Sets a command to true for when it was encountered
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

    // Returns trur if a string is a valid command
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

    /**
        Parses the command line arguments according to the set of `Commands`s that are passed in.
    */
    public void parse(const string[] args) {
        auto data = pluckCommand(args);

        debug_print("plucked => ", data);

        if (data[0].length) {
            this.options.parse(data[0]);
        }

        if (data[1].length) {
            activateCommand(data[1]);
            parseCommand(data[1], data[2]);
        }
    }

    /**
        Returns a string that represents a block of text that can be output to stdout
        to display a help message
    */
    public string helpText() const {
        string ret;
        static if (isProgramOptions!(Commands[0])) {
            ret ~= this.options.helpText;
            ret ~= "\n";
        }
        static if (StartIndex < Commands.length)
            ret ~= "Commands:\n";
        static foreach (I; StartIndex .. Commands.length) {
            ret ~= "  " ~ Commands[I].Name;
            if (Commands[I].Description.length)
                ret ~= "  " ~ Commands[I].Description
                ;
            static if (I < Commands.length - 1)
                ret ~= "\n";
        }
        return ret;
    }

    /**
        Returns a string that is a stringified object of keys and values denoting commands
        and their values and options (if present)
    */
    public string toString() const {
        import std.conv: to;
        string ret = "{ ";
        static if (isProgramOptions!(Commands[0])) {
            ret ~= "options: " ~ this.options.toString ~ ", ";
        }
        static foreach (I; StartIndex .. Commands.length) {
            ret ~= Commands[I].Name ~ ": { ";
            ret ~= "active: " ~ mixin(Commands[I].Name ~ ".active ? \"true\" : \"false\"");
            ret ~= ", ";
            static if (isProgramOptions!(Commands[I].Args)) {
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

    /**
        If any of the `Command`s have any handlers specified. Then those will be called
        in order of appearance on the command line by calling this function
    */
    public void executeHandlers() {
        import bolts: isNullType;
        static foreach (I; StartIndex .. Commands.length) {
            if (mixin(Commands[I].Name)) { // if this command is active
                static if (!isNullType!(Commands[I].Handler)) {
                    Commands[I].Handler(this);
                }
                static if (isProgramCommands!(Commands[I].Args)) {
                    mixin(Commands[I].Name ~ ".executeHandlers();");
                }
            }
        }
    }
}

version (unittest) {
    struct Fixtures {
        static:

        private bool handledCommand2 = false;
        private bool handledCommand3 = false;
        private bool handledCommand3Sub1 = false;

        bool checkResetHandledCommand2() {
            const ret = handledCommand2;
            scope(exit) handledCommand2 = false;
            return ret;
        }
        bool checkResetHandledCommand3() {
            const ret = handledCommand3;
            scope(exit) handledCommand3 = false;
            return ret;
        }
        bool checkResetHandledCommand3Sub1() {
            const ret = handledCommand3Sub1;
            scope(exit) handledCommand3Sub1 = false;
            return ret;
        }

        void handleCommand2(T)(T command) {
            handledCommand2 = true;
        }

        void handleCommand3(T)(T command) {
            handledCommand3 = true;
        }

        void handleCommand3Sub1(T)(T command) {
            handledCommand3Sub1 = true;
        }
    }
}
