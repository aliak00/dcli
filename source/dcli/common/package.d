module dcli.common;

package(dcli) string makeValidCamelCase(string name)() if (name.length) {
    import std.uni: toUpper, isAlpha, isAlphaNum;

    string ret;
    enum Action {
        nothing,
        capitalize,
    }
    auto action = Action.nothing;

    if (name[0].isAlpha || name[0] == '_') { // record first character only if valid first character
        ret ~= name[0];
    }
    for (int i = 1; i < name.length; ++i) {
        if (!name[i].isAlphaNum && name[0] != '_') {
            action = Action.capitalize;
            continue;
        }

        final switch (action) {
        case Action.nothing:
            ret ~= name[i];
            break;
        case Action.capitalize:
            ret ~= toUpper(name[i]);
            break;
        }

        action = Action.nothing;
    }
    return ret;
}

unittest {
    static assert(makeValidCamelCase!"a-a" == "aA");
    static assert(makeValidCamelCase!"-a" == "a");
    static assert(makeValidCamelCase!"-a-" == "a");
    static assert(makeValidCamelCase!"9a" == "a");
    static assert(makeValidCamelCase!"_9a" == "_9a");
    static assert(makeValidCamelCase!"a-1" == "a1");
}

// version = dcli_debug;

package(dcli) void debug_print(Args...)(auto ref Args args, int line = __LINE__, string file = __FILE__) @nogc {
    version(dcli_debug) {
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
