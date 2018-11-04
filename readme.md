# D-cli

[![Latest version](https://img.shields.io/dub/v/dcli.svg)](https://code.dlang.org/packages/dcli) [![Build Status](https://travis-ci.org/aliak00/dcli.svg?branch=master)](https://travis-ci.org/aliak00/dcli) [![codecov](https://codecov.io/gh/aliak00/dcli/branch/master/graph/badge.svg)](https://codecov.io/gh/aliak00/dcli) [![license](https://img.shields.io/github/license/aliak00/dcli.svg)](https://github.com/aliak00/dcli/blob/master/LICENSE)

Dcli is a library that is intened to help with building command line tools in D.

Full API docs available [here](https://aliak00.github.io/dcli/)

## Modules

* [ProgramOptions](#ProgramOptions)
* [ProgramCommands](#ProgramCommands)

### ProgramOptions

Handles program options which are arguments passed with a leading `-` or `--` and followed by a value

#### Features:

* Input validation
* Customize seperators for associative array args
* Supports environment variables
* Supports default values
* Supports custom types that have a constructor that is called with a string
* You can supply custom types and they will be called with a string that you can parse

#### Enhancements over `std.getopt`:

* `getopt(args)` is destructive on args.
* You cannot create your getopts and the parse later, which in combination with try/catch leads to awkward code
* `getopt` doesn't accept `$ ./program -p 3`. For short opts, you have to do `$ ./program -p3`.
* `getopt` doesn't allow case-sensitive short name and a case-insensitive long name
* `getopt` will initialize an array type with the default values AND what the program arg was.
* You cannot assign values to bundled short args, they are only incrementable
* There is no way to handle what happens with duplicate arguments

### ProgramCommands

Provides a command handling and definitino framework. Allos you define a set of commands that can be accepted on the command line, and also invokes any given handlers for activated commands. Also integrated with `ProgramOptions`.