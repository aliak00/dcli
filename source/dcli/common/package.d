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
}
