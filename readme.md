# D-cli

[![Latest version](https://img.shields.io/dub/v/dcli.svg)](https://code.dlang.org/packages/dcli) [![Build Status](https://travis-ci.org/aliak00/dcli.svg?branch=master)](https://travis-ci.org/aliak00/dcli) [![codecov](https://codecov.io/gh/aliak00/dcli/branch/master/graph/badge.svg)](https://codecov.io/gh/aliak00/dcli) [![license](https://img.shields.io/github/license/aliak00/dcli.svg)](https://github.com/aliak00/dcli/blob/master/LICENSE)

Dcli is a library that is intened to help with building command line tools in D. 

## Modules

### ProgramOptions

Allows you to define a set of program options and automatically parses them from the command line

### ProgramCommands

Provides a command handling and definitino framework. Allos you define a set of commands that can be accepted on the command line, and also invokes any given handlers for activated commands. Also integrated with `ProgramOptions`.