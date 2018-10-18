## Program options

### Features

1. Input validation
1. Customize seperators for associative array args
1. Supports environment variables
1. Supports default values
1. You can supply custom types and they will be called with a string that you can parse


### Enhancements over `std.getopt`:

1. `getopt(args)` is destructive on args.
1. `getopt` doesn't accept `$ program -p 3`. For short opts you have to do `$ program -p3`.
1. `getopt` doesn't allow case-sensitive short name and a case-insensitive long name
1. `getopt` will initialize an array type with the default values AND what the program arg was.
1. You cannot assign values to bundled short args, they are only incrementable
1. If an arg is provided twice the last one wins

## Example usage:

```d
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

auto args = [
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
    Option!("opt1", string).shortName!"a".duplicatePolicy!(OptionDuplicatePolicy.firstOneWins)
        .description!"This is the description for option 1",
    Option!("opt2", int).shortName!"b"
        .description!"This is the description for option 2",
    Option!("opt3", int).shortName!"B"
        .description!(
`There are three kinds of comments:
1. Something rather sinister
2. And something else that's not so sinister`
        ),
    Option!("opt4", int).defaultValue!3.environmentVar!"OPT_4"
        .description!"THis is one that takes an env var",
    Option!("opt5", int[]).environmentVar!"OPT_5"
        .description!"THis is one that takes an env var as well",
    Option!("opt6", int[]).defaultValue!([6, 7, 8]),
    Option!("opt7", float[]).defaultValue!([1, 2]),
    Option!("opt8", Enum),
    Option!("opt9", int).shortName!"i|j".longName!"incremental|opt9".incremental!true
        .description!"sets some level incremental thingy",
    Option!("opt10", int).validator!(a => a > 10),
    Option!("opt11", int[]),
    Option!("opt12", int[int]).separator!"::",
    Option!("opt13", int).parser!((value) {
        if (value == "verbose") return 7;
        return -1;
    }),
    Option!("b0", int).shortName!"x",
    Option!("b1", int).shortName!"y",
    Option!("b2", int).shortName!"z",
    Option!("opt14", Custom),
    Option!("opt15", bool),
    Option!("opt16", bool).longName!"".environmentVar!"OPT_16"
        .description!"THis one only takes and envornment variable and cant be set with any flags",
)();

string[] unknownArgs;
options.unknownArgHandler = (string name) {
    unknownArgs ~= name;
    return true; // continue parsing,
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
  -i  --incremental   sets some level incremental thingy
Environment Vars:
  OPT_4    See: --opt4
  OPT_5    See: --opt5
  OPT_16   THis one only takes and envornment variable and cant be set with any flags`
  );
```