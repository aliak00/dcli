module dcli.programoptions;

// version = dcli_programoptions_debug;

private void debug_print(Args...)(Args args, int line = __LINE__, string file = __FILE__) @trusted @nogc {
    version(dcli_programoptions_debug) {
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

/**
    The duplication policy can be passed to a `ProgramOptions` `Option.duplicatePolicy`
*/
enum OptionDuplicatePolicy {
    reject, lastOneWins, firstOneWins
}

template Option(string varName, T) {
    alias Option = OptionImpl!(varName, T);
}

private template OptionImpl(
    string _varName,
    T,
    string _longName = _varName,
    string _shortName = null,
    T _defaultValue = T.init,
    string _description = null,
    string _environmentVar = null,
    bool _caseSensitiveLongName = false,
    bool _caseSensitiveShortName = true,
    bool _incremental = false,
    alias _validator = null,
    string _separator = ",",
    alias _parser = null,
    bool _bundleable = true,
    OptionDuplicatePolicy _duplicatePolicy = OptionDuplicatePolicy.reject,
) if (_varName.length > 0) {

    import std.typecons: Flag;
    import bolts: isUnaryOver;
    import std.traits: ReturnType;
    import ddash.range: frontOr;

    alias VarName = _varName;
    alias Type = T;
    alias LongName = _longName;
    alias ShortName = _shortName;
    alias DefaultValue = _defaultValue;
    alias Description = _description;
    alias EnvironmentVar = _environmentVar;
    alias CaseSensitiveLongName = _caseSensitiveLongName;
    alias CaseSensitiveShortName = _caseSensitiveShortName;
    alias Incremental = _incremental;
    alias Validator = _validator;
    alias Separator = _separator;
    alias Parser = _parser;
    alias Bundleable = _bundleable;
    alias DuplicatePolicy = _duplicatePolicy;

    static if (_incremental) {
        import std.traits: isIntegral;
        static assert(
            isIntegral!T,
            "Cannot create incremental option '" ~ VarName ~ "' of type " ~ T.stringof ~ ". Incrementals must by integral type."
        );
    }

    import std.array: split;
    private immutable NormalizedName = (LongName ~ "|" ~ ShortName ~ "|" ~ VarName).split("|").frontOr("");
    private immutable PrimaryLongName = LongName.split("|").frontOr("");
    private immutable PrimaryShortName = ShortName.split("|").frontOr("");

    public alias longName(string value) = OptionImpl!(
        VarName, Type, value, ShortName, DefaultValue, Description, EnvironmentVar, CaseSensitiveLongName,
        CaseSensitiveShortName, Incremental, Validator, Separator, Parser, Bundleable, DuplicatePolicy,
    );

    public alias shortName(string value) = OptionImpl!(
        VarName, Type, LongName, value, DefaultValue, Description, EnvironmentVar, CaseSensitiveLongName,
        CaseSensitiveShortName, Incremental, Validator, Separator, Parser, Bundleable, DuplicatePolicy,
    );

    public alias defaultValue(T value) = OptionImpl!(
        VarName, Type, LongName, ShortName, value, Description, EnvironmentVar, CaseSensitiveLongName,
        CaseSensitiveShortName, Incremental, Validator, Separator, Parser, Bundleable, DuplicatePolicy,
    );

    public template description(string value) if (value.length > 0) {
        alias description = OptionImpl!(
            VarName, Type, LongName, ShortName, DefaultValue, value, EnvironmentVar, CaseSensitiveLongName,
            CaseSensitiveShortName, Incremental, Validator, Separator, Parser, Bundleable, DuplicatePolicy,
        );
    }

    public template environmentVar(string value) if (value.length > 0)  {
        alias environmentVar = OptionImpl!(
            VarName, Type, LongName, ShortName, DefaultValue, Description, value, CaseSensitiveLongName,
            CaseSensitiveShortName, Incremental, Validator, Separator, Parser, Bundleable, DuplicatePolicy,
        );
    }

    public alias caseSensitiveLongName(bool value) = OptionImpl!(
        VarName, Type, LongName, ShortName, DefaultValue, Description, EnvironmentVar, value,
        CaseSensitiveShortName, Incremental, Validator, Separator, Parser, Bundleable, DuplicatePolicy,
    );

    public alias caseSensitiveShortName(bool value) = OptionImpl!(
        VarName, Type, LongName, ShortName, DefaultValue, Description, EnvironmentVar, CaseSensitiveLongName,
        value, Incremental, Validator, Separator, Parser, Bundleable, DuplicatePolicy,
    );

    public template incremental(bool value) {
        alias incremental = OptionImpl!(
            VarName, Type, LongName, ShortName, DefaultValue, Description, EnvironmentVar, CaseSensitiveLongName,
            CaseSensitiveShortName, value, Validator, Separator, Parser, Bundleable, DuplicatePolicy,
        );
    }

    public static template validator(alias value) if (isUnaryOver!(value, T)) {
        import std.functional: unaryFun;
        alias validator = OptionImpl!(
            VarName, Type, LongName, ShortName, DefaultValue, Description, EnvironmentVar, CaseSensitiveLongName,
            CaseSensitiveShortName, Incremental, unaryFun!value, Separator, Parser, Bundleable, DuplicatePolicy,
        );
    }

    public template separator(string value) if (value.length > 0) {
        alias separator = OptionImpl!(
            VarName, Type, LongName, ShortName, DefaultValue, Description, EnvironmentVar, CaseSensitiveLongName,
            CaseSensitiveShortName, Incremental, Validator, value, Parser, Bundleable, DuplicatePolicy,
        );
    }

    public static template parser(alias value) {
        alias parser = OptionImpl!(
            VarName, Type, LongName, ShortName, DefaultValue, Description, EnvironmentVar, CaseSensitiveLongName,
            CaseSensitiveShortName, Incremental, Validator, Separator, value, Bundleable, DuplicatePolicy,
        );
    }

    public template bundleable(bool value) {
        alias bundleable = OptionImpl!(
            VarName, Type, LongName, ShortName, DefaultValue, Description, EnvironmentVar, CaseSensitiveLongName,
            CaseSensitiveShortName, Incremental, Validator, Separator, Parser, value, DuplicatePolicy,
        );
    }

    public template duplicatePolicy(OptionDuplicatePolicy value) {
        alias duplicatePolicy = OptionImpl!(
            VarName, Type, LongName, ShortName, DefaultValue, Description, EnvironmentVar, CaseSensitiveLongName,
            CaseSensitiveShortName, Incremental, Validator, Separator, Parser, Bundleable, value,
        );
    }

    private bool isMatch(string name, Flag!"shortName" isShortName) {
        import std.uni: toLower;
        import std.array: split;
        import std.algorithm: any;
        if (isShortName) {
            static if (CaseSensitiveShortName) {
                auto lhs = ShortName;
                auto rhs = name;
            } else {
                auto lhs = ShortName.toLower;
                auto rhs = name.toLower;
            }
            return lhs.split("|").any!(a => a == rhs);
        } else {
            static if (CaseSensitiveLongName) {
                auto lhs = LongName;
                auto rhs = name;
            } else {
                auto lhs = LongName.toLower;
                auto rhs = name.toLower;
            }
            return lhs.split("|").any!(a => a == rhs);
        }
    }
}

class ProgramOptionException: Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

class MalformedProgramArgument: ProgramOptionException {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

class InvalidProgramArgument: ProgramOptionException {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

class DuplicateProgramArgument: ProgramOptionException {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

class ExpectedProgramArgument: ProgramOptionException {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

template isProgramOptions(T) {
    import std.traits: isInstanceOf;
    enum isProgramOptions = isInstanceOf!(ProgramOptions, T);
}

struct ProgramOptions(Options...) {

    import std.typecons: Flag, Tuple, tuple;
    import optional;

    static foreach (I, opt; Options) {
        mixin("opt.Type " ~ opt.VarName ~ "= opt.DefaultValue;");
    }

    private bool[string] encounteredOptions;

    Optional!(bool delegate(string)) unknownArgHandler;

    private enum AssignResult {
        setValueUsed,
        setValueUnused,
        noMatch
    }

    /**
        Why is this static you may ask... because of D's 'delegates can only have one context pointer' thing:

        https://www.bountysource.com/issues/1375082-cannot-use-delegates-as-parameters-to-non-global-template

        The error would be:
            Error: template instance `tryAssign!()` cannot use local Option!(..., __lambda2)
            as parameter to non-global template tryAssign(alias option)(string assumedValue)

        So making this a static removes the need for an extra context pointer
    */
    private static AssignResult tryAssign(alias option, T)(ref T self, string assumedValue) {
        import std.traits: isNarrowString, isArray, isAssociativeArray;
        import std.conv: to;
        import std.array: split;
        import std.algorithm: filter;

        // If this is the first encounter, we also set the value to T.init
        auto p = option.VarName in self.encounteredOptions;
        bool isDuplicate = false;
        if (!(p is null) && !*p) {
            *p = true;
            mixin("self."~option.VarName ~ " = option.Type.init;");
        } else {
            isDuplicate = true;
        }

        static if (!(isArray!(option.Type) && !isNarrowString!(option.Type)) && !isAssociativeArray!(option.Type) && !option.Incremental) {
            static if (option.DuplicatePolicy == OptionDuplicatePolicy.firstOneWins) {
                if (isDuplicate) {
                    // Flags are special. They may or may not consume the value depending on if consuming
                    // the value succeeds or not
                    static if (is(option.Type == bool)) {
                        try {
                            assumedValue.to!bool;
                        } catch (Exception) {
                            return AssignResult.setValueUnused;
                        }
                    }
                    return AssignResult.setValueUsed;
                }
            }

            static if (option.DuplicatePolicy == OptionDuplicatePolicy.reject) {
                if (isDuplicate) {
                    throw new DuplicateProgramArgument(
                        "Duplicate program option argument '" ~ assumedValue ~ "' not allowed for option '" ~ option.NormalizedName ~ "'"
                    );
                }
            }
        }

        auto tryParseValidate(T = option.Type)(string assumedValue) {
            import bolts: isNullType;
            T value;
            static if (!isNullType!(option.Parser)) {
                value = option.Parser(assumedValue);
            } else {
                static assert(
                    __traits(compiles, { assumedValue.to!(T); }),
                    "Cannot convert program arg to type '" ~ T.stringof ~ "'. Maybe type is missing a this(string) contructor?"
                );
                value = assumedValue.to!(T);
            }
            static if (!isNullType!(option.Validator)) {
                if (!option.Validator(value)) {
                    throw new InvalidProgramArgument("Option '" ~ option.NormalizedName ~ "' got invalid value: " ~ assumedValue);
                }
            }
            return value;
        }

        AssignResult result = AssignResult.setValueUsed;
        static if (option.Incremental) {
            mixin("self."~option.VarName ~ " += 1;");
            result = AssignResult.setValueUnused;
        } else static if (is(option.Type == bool)) {
            mixin("self."~option.VarName ~ " = true;");
            try {
                mixin("self."~option.VarName ~ " = " ~ "assumedValue.to!bool;");
            } catch (Exception) {
                result = AssignResult.setValueUnused;
            }
        } else static if (isArray!(option.Type) && !isNarrowString!(option.Type)) {
            import std.range: ElementType;
            auto values = assumedValue.split(option.Separator).filter!"a.length";
            foreach (str; values) {
                auto value = tryParseValidate!(ElementType!(option.Type))(str);
                mixin("self."~option.VarName ~ " ~= value;");
            }
        } else static if (isAssociativeArray!(option.Type)) {
            auto values = assumedValue.split(option.Separator).filter!"a.length";
            foreach (str; values) {
                auto parts = str.split("=");
                if (!parts.length == 2) {
                    return AssignResult.noMatch;
                }
                import std.traits: KeyType, ValueType;
                auto key = parts[0].to!(KeyType!(option.Type));
                auto value = parts[1].to!(ValueType!(option.Type));
                mixin("self."~option.VarName ~ "[key] = value;");
            }
        } else {
            import bolts: isNullType;
            auto value = tryParseValidate(assumedValue);
            mixin("self."~option.VarName ~ " = value;");
        }
        return result;
    }

    private AssignResult trySet(string name, string value, Flag!"shortName" shortName) {
        import std.conv: ConvException;
        try {
            static foreach (opt; Options) {
                if (opt.isMatch(name, shortName)) {
                    return tryAssign!(opt)(this, value);
                }
            }
        } catch (ConvException ex) {
            throw new MalformedProgramArgument(
                "Could not set '" ~ name ~ "' to '" ~ value ~ "' - " ~ ex.msg
            );
        }
        return AssignResult.noMatch;
    }

    private bool isBundleableShortName(string str) {
        import std.typecons: Yes;
        static foreach (opt; Options) {
            if (opt.isMatch(str, Yes.shortName)) {
                return opt.Bundleable;
            }
        }
        return false;
    }

    private bool isShortName(string str) {
        import std.typecons: Yes;
        static foreach (opt; Options) {
            if (opt.isMatch(str, Yes.shortName)) {
                return true;
            }
        }
        return false;
    }

    string[] parse(const string[] args) {
        this.parseEnv;
        return this.parseArgs(args);
    }

    void parseEnv() {
        import std.process: environment;
        import std.conv: ConvException;

        // Parse possible environment vars
        static foreach (opt; Options) {
            static if (opt.EnvironmentVar.length) {{
                string value;
                try {
                    value = environment[opt.EnvironmentVar];
                } catch (Exception ex) {
                    // Env var doesn't exist
                }
                if (value.length) {
                    try {
                        tryAssign!(opt)(this, value);
                    } catch (ConvException ex) {
                        throw new MalformedProgramArgument(
                            "Could not set '" ~ opt.EnvironmentVar  ~ "' to '" ~ value ~ "' - " ~ ex.msg
                        );
                    }
                }
            }}
        }
    }

    string[] parseArgs(const string[] args) {
        import std.algorithm: startsWith, findSplit, filter, map;
        import std.range: drop, array, tee, take;
        import std.conv: to;
        import std.typecons: Yes, No;
        import std.string: split;

        // Initialize the encounters array
        static foreach (opt; Options) {
            encounteredOptions[opt.VarName] = false;
        }

        // Parse the first arg and executable path and see if we should skip first arg
        import ddash.range: first, last, frontOr, withFront;
        import ddash.algorithm: flatMap;
        import std.file: thisExePath;

        int index = 0;

        args.first.map!(a => a.split("/").last).withFront!((a) {
            import std.file: thisExePath;
            thisExePath.split("/").last.withFront!((b) {
                if (a == b) {
                    index = 1;
                }
            });
        });

        while (index < args.length) {
            auto arg = args[index];
            debug_print("parsing arg ", arg);
            bool shortOption = false;
            string rest = "";
            if (arg.startsWith("--")) {
                rest = arg.drop(2);
                shortOption = false;
            } else if (arg.startsWith("-")) {
                rest = arg.drop(1);
                shortOption = true;
            } else {
                unknownArgHandler(arg).filter!"a".tee!((a) {
                    throw new MalformedProgramArgument(
                        "Unknown argument '" ~ arg ~ "'"
                    );
                }).array;
                index++;
                continue;
            }

            // Make sure we have something in rest before we continue
            if (rest.length == 0) {
                debug_print("no option found") ;
                if (shortOption) {
                    index += 1;
                    continue;
                }
                // Else it was a -- so we slice those out and we're done
                debug_print("done. storing rest arguments: ", args[index + 1 .. $]) ;
                return args[index + 1 .. $].dup;
            }

            auto nextValue() {
                import ddash.range: nth;
                auto next = args.nth(index + 1);
                if (next.empty) {
                    throw new ExpectedProgramArgument("Did not find value for arg " ~ args[index]);
                }
                return next.front;
            }

            assert(rest.length > 0);

            string[] options;
            string value;
            int steps = () {
                if (shortOption) {
                    debug_print("parsing short name") ;
                    if (rest.length == 1) {
                        debug_print("one letter option only") ;
                        options = [rest.to!string];
                        value = nextValue();
                        return 2;
                    }

                    // If we have more than one char then it can be either of the forms
                    //
                    // a) ooo - bundleable options no value
                    // b) o=V - one option and assigned value
                    // c) oV - one option and stuck value
                    // d) ooo=V - bundleable options and assigned value
                    // e) oooV - bundleable options and stuck value

                    assert(rest.length > 1);

                    import std.algorithm: until;
                    auto bundleableArgs = rest.until!(a => !isBundleableShortName(a.to!string)).array;

                    debug_print("bundleableArgs=", bundleableArgs) ;

                    // Greater than one, and all of them are bundleable, and no value - case a
                    if (bundleableArgs.length == rest.length) {
                        debug_print("case a") ;
                        options = bundleableArgs.map!(to!string).array;
                        value = nextValue();
                        return 2;
                    }

                    auto shortNames = rest.until!(a => !isShortName(a.to!string)).array;

                    debug_print("shortNames=", shortNames) ;

                    // Greater than one, but only one valid short name - case b and c
                    if (shortNames.length == 1) {
                        options = shortNames.map!(to!string).array;
                        auto parts = rest.findSplit("=");
                        debug_print("got parts=", parts) ;
                        if (parts[0].length == 1 && parts[1] == "=") { // case b
                            debug_print("case b") ;
                            value = parts[2];
                        } else {
                            debug_print("case c") ;
                            value = parts[0].drop(1);
                        }
                        return 1;
                    }

                    // We have more than one short name, so now we have bundleables
                    assert(shortNames.length > 1);

                    if (shortNames.length != bundleableArgs.length) {
                        throw new MalformedProgramArgument(
                            "Bundled args '" ~ shortNames.to!string ~ "' are not all bundleable"
                        );
                    }

                    assert(shortNames.length == bundleableArgs.length);

                    // Hanle case d and e
                    options = shortNames.map!(to!string).array;
                    auto parts = rest.findSplit("=");
                    debug_print("got parts=", parts) ;
                    if (parts[0].length == shortNames.length && parts[1] == "=") { // case d
                        debug_print("case d") ;
                        value = parts[2];
                    } else { // case e
                        debug_print("case e") ;
                        value = parts[0].drop(shortNames.length);
                    }
                    return 1;
                } else {
                    debug_print("parsing long name") ;

                    // We have a long name, and two cases:
                    //
                    // a) name
                    // b) name=V

                    auto parts = rest.findSplit("=");
                    debug_print("got parts=", parts) ;
                    if (parts[1] != "=") { // case a
                        debug_print("case a") ;
                        options = [parts[0]];
                        value = nextValue();
                        return 2;
                    }

                    // case b
                    options = [parts[0]];
                    value = parts[2];
                    debug_print("case b") ;
                    return 1;
                }
            }();

            debug_print("parsed => ", options, ", value: ", value, ", steps: ", steps) ;

            loop: foreach (option; options) {

                auto result = trySet(option, value, shortOption ? Yes.shortName : No.shortName);

                with (AssignResult) final switch (result) {
                case setValueUsed:
                    break;
                case setValueUnused:
                    steps = 1;
                    break;
                case noMatch:
                    unknownArgHandler(arg).filter!"a".tee!((a) {
                        throw new MalformedProgramArgument(
                            "Unknown argument '" ~ arg ~ "'"
                        );
                    }).array;
                    steps = 1;
                    break loop;
                }
            }

            index += steps;
        }

        return [];
    }

    string toString() const {
        import std.conv: to;
        string ret = "{ ";
        static foreach (I, Opt; Options) {
            ret ~= Opt.VarName ~ ": " ~ mixin(Opt.VarName ~ ".to!string");
            static if (I < Options.length - 1) {
                ret ~= ", ";
            }
        }
        ret ~= " }";
        return ret;
    }

    string helpText() const {
        import std.string: leftJustify, stripRight;
        import std.typecons: Tuple;

        string ret;

        // The max lengths will be used to indent the description text
        size_t maxLongNameLength = 0;
        size_t maxEnvVarLength = 0;
        static foreach (Opt; Options) {
            static if (Opt.Description) {
                if (Opt.PrimaryLongName.length > maxLongNameLength) {
                    maxLongNameLength = Opt.PrimaryLongName.length;
                }
                static if (Opt.EnvironmentVar.length) {
                    if (Opt.EnvironmentVar.length > maxEnvVarLength) {
                        maxEnvVarLength = Opt.EnvironmentVar.length;
                    }
                }
            }
        }

        maxLongNameLength += 2; // for the --
        immutable maxShortNameLength = 2;

        immutable startIndent = 2;
        immutable shortLongIndent = 2;
        immutable longDescIndent = 3;

        alias EnvVarData = Tuple!(string, "name", string, "linkedOption", string, "description");
        EnvVarData[] envVarData;

        bool hasOptionsSection = false;
        static foreach (I, Opt; Options) {{

            // This will be used later to write out the Environment Var section
            EnvVarData envVarDatum;
            envVarDatum.description = Opt.Description;

            // If we have a long name or short name we can display an "Options" section
            static if (Opt.PrimaryShortName.length || Opt.PrimaryLongName.length) {

                // Set this to null because we will output the description as part of the opttion names
                envVarDatum.description = null;

                // Write the Option section header once.
                if (!hasOptionsSection) {
                    ret ~= "Options:";
                    hasOptionsSection = true;
                }

                ret ~= "\n";

                string desc = startIndent.spaces;
                static if (Opt.PrimaryShortName.length) {{
                    auto str = "-" ~ Opt.PrimaryShortName;
                    envVarDatum.linkedOption = str;
                    desc ~= str;
                }} else {
                    desc ~= maxShortNameLength.spaces;
                }
                desc ~= shortLongIndent.spaces;
                static if (Opt.PrimaryLongName.length) {{
                    auto str = "--" ~ Opt.PrimaryLongName;
                    envVarDatum.linkedOption = str;
                    desc ~= str.leftJustify(maxLongNameLength, ' ');
                }} else {
                    desc ~= maxLongNameLength.spaces;
                }
                desc ~= longDescIndent.spaces;
                auto indent = startIndent + maxShortNameLength + shortLongIndent + maxLongNameLength + longDescIndent;
                if (!Opt.Description.length) {
                    desc = desc.stripRight;
                }
                ret ~= desc ~ printWithIndent(indent, Opt.Description);
            }

            static if (Opt.EnvironmentVar.length) {
                envVarDatum.name = Opt.EnvironmentVar;
                envVarData ~= envVarDatum;
            }
        }}

        foreach (i, data; envVarData) {
            // If first iteration, write out section header and add new lines if we had some text before (means we had an Options section)
            if (i == 0) {
                if (ret.length) {
                    ret ~= "\n\n";
                }
                ret ~= "Environment Vars:";
            }

            ret ~= "\n";
            ret ~= startIndent.spaces ~ data.name.leftJustify(maxEnvVarLength) ~ longDescIndent.spaces;
            if (data.description.length) {
                ret ~= printWithIndent(startIndent + maxEnvVarLength + longDescIndent, data.description);
            } else {
                ret ~= "See: " ~ data.linkedOption;
            }
        }

        return ret;
    }
}

private string spaces(size_t i) pure nothrow {
    import std.range: repeat, take, array;
    return ' '.repeat.take(i).array;
}

private string printWithIndent(size_t indent, string description, int maxColumnCount = 80) {
    import std.string: splitLines;
    import std.algorithm: splitter;
    import std.uni: isWhite;
    import std.range: array;
    string ret;
    auto currentWidth = indent;
    auto lines = description.splitLines;
    foreach(li, line; lines) {
        auto words = line.splitter!isWhite.array;
        foreach (wi, word; words) {
            ret ~= word ~ (wi < words.length - 1 ? 1 : 0).spaces;
            currentWidth += word.length;
            if (currentWidth > maxColumnCount) {
                ret ~= "\n" ~ indent.spaces;
                currentWidth = indent;
            }
        }
        if (li < lines.length - 1) {
            ret ~= "\n";
            ret ~= indent.spaces;
            currentWidth = indent;
        }
    }
    return ret;
}

version (unittest) {
    struct Custom {
        int x;
        int y;
        this(int a, int b) {
            x = a;
            y = b;
        }
        this(string str) {
            import std.string: split;
            import std.conv: to;
            auto parts = str.split(",");
            x = parts[0].to!int;
            y = parts[1].to!int;
        }
    }
}

unittest {
    import std.exception;
    auto opts = ProgramOptions!(
        Option!("opt", string).shortName!"o"
    )();
    assertThrown!ExpectedProgramArgument(opts.parse(["-o"]));
}

unittest {
    import std.file: thisExePath;

    auto args = [
        thisExePath,
        "program_name",
        "--opt1", "value1",
        "-b", "1",
        "--Opt3=2",
        "--OPT5", "4",
        "--opt5", "5",
        "--opt7", "9",
        "--unknown", "ha",
        "--opt8=two",
        "-i", "-j", "--incremental", "--opt9",
        "--opt10", "11",
        "--opt11", "3,4,5",
        "--opt12", "1=2::3=4::5=6",
        "--opt13", "verbose",
        "-xyz=-7",
        "--opt1", "value2",
        "--opt14", "1,2",
        "--opt15",
        "--",
        "extra",
    ];

    enum Enum { one, two, }

    auto options = ProgramOptions!(
        Option!("opt1", string)
            .shortName!"a"
            .description!"This is the description for option 1"
            .duplicatePolicy!(OptionDuplicatePolicy.firstOneWins),
        Option!("opt2", int)
            .shortName!"b"
            .description!"This is the description for option 2",
        Option!("opt3", int)
            .shortName!"B"
            .description!(
`There are three kinds of comments:
    1. Something rather sinister
    2. And something else that's not so sinister`
        ),
        Option!("opt4", int)
            .defaultValue!3
            .environmentVar!"OPT_4"
            .description!"THis is one that takes an env var",
        Option!("opt5", int[])
            .environmentVar!"OPT_5"
            .description!"THis is one that takes an env var as well",
        Option!("opt6", int[])
            .defaultValue!([6, 7, 8]),
        Option!("opt7", float[])
            .defaultValue!([1, 2]),
        Option!("opt8", Enum),
        Option!("opt9", int)
            .shortName!"i|j"
            .longName!"incremental|opt9"
            .incremental!true
            .description!"sets some level incremental thingy",
        Option!("opt10", int)
            .validator!(a => a > 10),
        Option!("opt11", int[]),
        Option!("opt12", int[int])
            .separator!"::",
        Option!("opt13", int)
            .parser!((value) {
                if (value == "verbose") return 7;
                return -1;
            }),
        Option!("b0", int)
            .shortName!"x",
        Option!("b1", int)
            .shortName!"y",
        Option!("b2", int)
            .shortName!"z",
        Option!("opt14", Custom),
        Option!("opt15", bool),
        Option!("opt16", bool)
            .longName!""
            .environmentVar!"OPT_16"
            .description!"THis one only takes and envornment variable and cant be set with any flags",
    )();

    string[] unknownArgs;
    options.unknownArgHandler = (string name) {
        unknownArgs ~= name;
        return false;
    };

    assert(options.parse(args) == ["extra"]);
    assert(unknownArgs == ["program_name", "--unknown", "ha"]);

    assert(options.opt1 == "value1");
    assert(options.opt2 == 1);
    assert(options.opt3 == 2);
    assert(options.opt4 == 3);
    assert(options.opt5 == [4, 5]);
    assert(options.opt6 == [6, 7, 8]);
    assert(options.opt7 == [9]);
    assert(options.opt8 == Enum.two);
    assert(options.opt9 == 4);
    assert(options.opt10 > 10);
    assert(options.opt11 == [3, 4, 5]);
    assert(options.opt12 == [1: 2, 3: 4, 5: 6]);
    assert(options.opt13 == 7);
    assert(options.b0 == -7);
    assert(options.b1 == -7);
    assert(options.b2 == -7);
    assert(options.opt14 == Custom(1, 2));
    assert(options.opt15 == true);

    assert(options.helpText ==
`Options:
  -a  --opt1          This is the description for option 1
  -b  --opt2          This is the description for option 2
  -B  --opt3          There are three kinds of comments:
                          1. Something rather sinister
                          2. And something else that's not so sinister
      --opt4          THis is one that takes an env var
      --opt5          THis is one that takes an env var as well
      --opt6
      --opt7
      --opt8
  -i  --incremental   sets some level incremental thingy
      --opt10
      --opt11
      --opt12
      --opt13
  -x  --b0
  -y  --b1
  -z  --b2
      --opt14
      --opt15

Environment Vars:
  OPT_4    See: --opt4
  OPT_5    See: --opt5
  OPT_16   THis one only takes and envornment variable and cant be set with any flags`
  );
}
