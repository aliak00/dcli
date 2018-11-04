# D-cli

[![Latest version](https://img.shields.io/dub/v/dcli.svg)](https://code.dlang.org/packages/dcli) [![Build Status](https://travis-ci.org/aliak00/dcli.svg?branch=master)](https://travis-ci.org/aliak00/dcli) [![codecov](https://codecov.io/gh/aliak00/dcli/branch/master/graph/badge.svg)](https://codecov.io/gh/aliak00/dcli) [![license](https://img.shields.io/github/license/aliak00/dcli.svg)](https://github.com/aliak00/dcli/blob/master/LICENSE)

Dcli is a library that is intened to help with building command line tools in D.

Full API docs available [here](https://aliak00.github.io/dcli/)

## Modules

* [ProgramOptions](#ProgramOptions)
* [ProgramCommands](#ProgramCommands)

### ProgramOptions ([docs](https://aliak00.github.io/dcli/dcli/program_options.html))

Handles program options which are arguments passed with a leading `-` or `--` and followed by a value

#### Features:

* Input validation
* Customize seperators for associative array args
* Supports environment variables
* Supports default values
* Supports custom types that have a constructor that is called with a string


### ProgramCommands ([docs](https://aliak00.github.io/dcli/dcli/program_commands.html))

Provides a command handling and definitino framework. Allos you define a set of commands that can be accepted on the command line, and also invokes any given handlers for activated commands. Also integrated with `ProgramOptions`.

#### E.g.

```
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
```