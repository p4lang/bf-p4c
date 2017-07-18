# **Tofino Assembler**

## **Documentation**

Documentation on using the assembler, notes on file formats, and internals are
in [Google Drive > Barefoot shared > documents > Software > Assembler]
(https://drive.google.com/drive/folders/0Byf8esgFy8YacmNzMmZiSkN4OFU)

## **Setup**

The repository contains code for the tofino assembler (tfas) and linker (walle).
More info on walle can be found in walle/README.md.

Assembler takes assembly files (.tfa) as input to generate output json which is
then fed to walle to produce binary for tofino.

## **Dependencies**

- GNU make
- A C++ compiler supporting C++11 (the Makefile uses g++ by defalt)
- bison
- flex
- pyinstaller (for walle) [ sudo pip install pyinstaller ]

Running the test suite requires access to the Glass p4c_tofino compiler.
Running stf tests requires access to the simple test harness.  The
`tests/runtests` script will look in various places for these tools (see the top
of the script)

## **Building Assembler**

    user@box$ cd tofino-asm
    user@box$ ./bootstrap.sh
    user@box$ make

Assembler executable `tfas` is created in the build directory on running make. The
chip schema binary in tofino & jbay directories are used to generate backend
files and compiled in gen/tofino or gen/jbay

json2cpp program is used to compile the backend files which contain register, 
memory and pipe stages resource information. 

## **Address Sanitizer checks**

To enable address sanitizer checks in the assembler use,

user@box$ ./bootstrap.sh --enable-asan-checks

Or alternatively,

user@box$ ./configure --enable-asan-checks

This configures the Makefile to add -fsanitizer=address & -fsanitizer=undefined.
By default the leak sanitizer is also enabled along with the address santizier.
You can disable it by setting environment variable ASAN_OPTIONS with
"detect_leaks=0".

## **Testing**

### **Make Targets**

user@box$ make check 

Runs tests/runtests script on all .p4 files in the tests and tests/mau
directories and .tfa files in tests/asm directory. This script can run one or
more tests specified on the command line, or will run all .p4 files in the
current directory if run with no arguments.  Stf tests can be run if specified
explicitly on the command line; they will not run by default.

user@box$ make check-sanity

This is similar to `make check` but will only run on .p4 files in the tests
directory which is a small subset for a quick sanity check.

### **Runtests Script**

The ./tests/runtests script will first run glass compiler (p4c-tofino) on
input .p4 file and then run the assembler (tfas) on generated assembly (.tfa)
file.  Glass also generates output json which is then compared (by the script)
to the json generated from assembler.

To skip running glass use -f option on the runtests script

Use -j <value> to run parallel threads. If invoking through Make targets set
MAKEFLAGS to "-j <value>"

### **Expected Failures**

expected_failures.txt files are under tests & tests/mau directory which outline
failing tests with cause (compile, tfas, mismatch). These files must be updated
to reflect any new or fixed fails.

| FAIL     |  TYPE        | CAUSE                                                   |
|----------|--------------|---------------------------------------------------------|
| compile  |  Glass       | Glass cannot compile input .p4 file                     |
| tfas     |  Assembler   | Assembler error while running input assembly file (.tfa)|
| mismatch |  Json output | Difference in json outputs for glass and assembler      |

### **Context Json Ignore**
Context Json output from Glass compiler is verbose and may or may not be
consumed entirely by the drivers unlike the assembler Json output. The
tests/runtests script ignores the keys placed in the tests/ctxt_json_ignore file
while creating json diff to only display relevant mismatches

### **Json Diff**
Each test after running will have its own <testname>.out dir with following
items:
E.g. TEST = exact_match0.p4
exact_match0.p4.out
##### **Glass Json output**
```
├── cfg
│   ├── memories.all.parser.egress.cfg.json.gz
│   ├── memories.all.parser.ingress.cfg.json.gz
│   ├── memories.pipe.cfg.json.gz
│   ├── memories.top.cfg.json.gz
│   ├── regs.all.deparser.header_phase.cfg.json.gz
│   ├── regs.all.deparser.input_phase.cfg.json.gz
│   ├── regs.all.parse_merge.cfg.json.gz
│   ├── regs.all.parser.egress.cfg.json.gz
│   ├── regs.all.parser.ingress.cfg.json.gz
│   ├── regs.match_action_stage.00.cfg.json.gz
│   ├── regs.match_action_stage.01.cfg.json.gz
│   ├── regs.match_action_stage.02.cfg.json.gz
│   ├── regs.match_action_stage.03.cfg.json.gz
│   ├── regs.match_action_stage.04.cfg.json.gz
│   ├── regs.match_action_stage.05.cfg.json.gz
│   ├── regs.match_action_stage.06.cfg.json.gz
│   ├── regs.match_action_stage.07.cfg.json.gz
│   ├── regs.match_action_stage.08.cfg.json.gz
│   ├── regs.match_action_stage.09.cfg.json.gz
│   ├── regs.match_action_stage.0a.cfg.json.gz
│   ├── regs.match_action_stage.0b.cfg.json.gz
│   ├── regs.pipe.cfg.json.gz
│   └── regs.top.cfg.json.gz
├── context
│   ├── deparser.context.json
│   ├── mau.context.json
│   ├── p4_name_lookup.json
│   ├── parser.context.json
│   └── phv.context.json
```
##### **Assembler Output Directory**
```
├── exact_match0.out
```
##### **Assembler Json Output**
```
│   ├── memories.all.parser.egress.cfg.json.gz
│   ├── memories.all.parser.ingress.cfg.json.gz
│   ├── memories.pipe.cfg.json.gz
│   ├── memories.top.cfg.json.gz
│   ├── p4_name_lookup.json
│   ├── regs.all.deparser.header_phase.cfg.json.gz
│   ├── regs.all.deparser.input_phase.cfg.json.gz
│   ├── regs.all.parse_merge.cfg.json.gz
│   ├── regs.all.parser.egress.cfg.json.gz
│   ├── regs.all.parser.ingress.cfg.json.gz
│   ├── regs.match_action_stage.00.cfg.json.gz
│   ├── regs.match_action_stage.01.cfg.json.gz
│   ├── regs.match_action_stage.02.cfg.json.gz
│   ├── regs.match_action_stage.03.cfg.json.gz
│   ├── regs.match_action_stage.04.cfg.json.gz
│   ├── regs.match_action_stage.05.cfg.json.gz
│   ├── regs.match_action_stage.06.cfg.json.gz
│   ├── regs.match_action_stage.07.cfg.json.gz
│   ├── regs.match_action_stage.08.cfg.json.gz
│   ├── regs.match_action_stage.09.cfg.json.gz
│   ├── regs.match_action_stage.0a.cfg.json.gz
│   ├── regs.match_action_stage.0b.cfg.json.gz
│   ├── regs.pipe.cfg.json.gz
│   ├── regs.top.cfg.json.gz
```
##### **Context Json**
```
│   └── tbl-cfg
```
##### **Symlink to Glass Assembly File**
```
├── exact_match0.tfa -> out.tfa
```
##### **Glass Run Log**
```
├── glsc.log
```
##### **Json Diff File**
```
├── json_diff.txt
```
##### **Glass Output Logs**
```
├── logs
│   ├── asm.log
│   ├── mau.characterize.log
│   ├── mau.config.log
│   ├── mau.gateway.log
│   ├── mau.gw.log
│   ├── mau.log
│   ├── mau.power.log
│   ├── mau.resources.log
│   ├── mau.rf.log
│   ├── mau.sram.log
│   ├── mau.tcam.log
│   ├── mau.tp.log
│   ├── pa.characterize.log
│   ├── pa.liveness.log
│   ├── pa.log
│   ├── parde.calcfields.log
│   ├── parde.config.log
│   ├── parde.error.log
│   ├── parde.log
│   ├── pa.results.log
│   ├── parser.characterize.log
│   └── transform.log
├── name_lookup.c
```
##### **Glass output assembly file**
```
├── out.tfa
```
##### **Assembler Run Log**
```
├── tfas.config.log
├── tfas.log
```
##### **Test visualization htmls**
```
└── visualization
    ├── deparser.html
    ├── jquery.js
    ├── mau.html
    ├── parser.egress.html
    ├── parser.ingress.html
    ├── phv_allocation.html
    └── table_placement.html
```

## **Backends (Tofino/JBay)**
Assembler currently supports Tofino backend but code is generic enough to be
ported to a different backend like JBay. Architecture specific constants must be 
parameterized and placed in the contants.h file

"tofino" and "jbay" directories hold the chip schema to be used by the
assembler. The chip schema contains register information and is a binary
generated from csv file in bfnregs repository. 

The chip schema is copied from the glass compiler repository to align with
comparing glass output jsons. Eventually this will go away and the generation
mechanism will be in the assembler repo.

To ensure glass and assembler are always pointing to the same schema, create a
symlink in your tofino-asm source directory to the templates directory in the
glass repo:

ln -s $HOME/p4c-tofino/p4c_tofino/target/tofino/output/templates p4c-templates

then any time you update the glass repo with a new chip.schema it will
automatically be copied into the tofino-asm source tree.

## **Assembly Syntax**
The assembly syntax is documented in `SYNTAX.md` file
