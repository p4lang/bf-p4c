# **Tofino Assembler**

## **Documentation**

Documentation on using the assembler, notes on file formats, and internals are
in [Google Drive > Barefoot shared > documents > Software > Assembler]
(https://drive.google.com/drive/folders/0Byf8esgFy8YacmNzMmZiSkN4OFU)

## **Setup**

The repository contains code for the Barefoot assembler (bfas) and linker (walle).
More info on walle can be found in walle/README.md.

Assembler takes assembly files (.bfa or .tfa) as input to generate output json which is
then fed to walle to produce binary for tofino.

## **Dependencies**

- GNU make
- A C++ compiler supporting C++11 (the Makefile uses g++ by defalt)
- bison
- flex
- pyinstaller (for walle) [ sudo pip install pyinstaller ]

Running the test suite requires access to the Glass p4c\_tofino compiler.
Running stf tests requires access to the simple test harness.  The
`tests/runtests` script will look in various places for these tools (see the top
of the script)

## **Building Assembler**

    user@box$ cd tofino-asm
    user@box$ ./bootstrap.sh
    user@box$ make

Assembler executable `bfas` is created in the build directory on running make. The
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
You can disable it by setting environment variable ASAN\_OPTIONS with
"detect\_leaks=0".

## **Testing**

### **Make Targets**

user@box$ make check

Runs tests/runtests script on all .p4 files in the tests and tests/mau
directories and .bfa files in tests/asm directory. This script can run one or
more tests specified on the command line, or will run all .p4 files in the
current directory if run with no arguments.  Stf tests can be run if specified
explicitly on the command line; they will not run by default.

user@box$ make check-sanity

This is similar to `make check` but will only run on .p4 files in the tests
directory which is a small subset for a quick sanity check.

### **Runtests Script**

The ./tests/runtests script will first run glass compiler (p4c-tofino) on
input .p4 file and then run the assembler (bfas) on generated assembly (.tfa)
file.  Glass also generates output json which is then compared (by the script)
to the json generated from assembler.

To skip running glass use -f option on the runtests script

Use -j <value> to run parallel threads. If invoking through Make targets set
MAKEFLAGS to "-j <value>"

### **Expected Failures**

expected\_failures.txt files are under tests & tests/mau directory which outline
failing tests with cause (compile, bfas, mismatch). These files must be updated
to reflect any new or fixed fails.

| FAIL     |  TYPE        | CAUSE                                                   |
|----------|--------------|---------------------------------------------------------|
| compile  |  Glass       | Glass cannot compile input .p4 file                     |
| bfas     |  Assembler   | Assembler error while running input assembly file (.bfa)|
| mismatch |  Json output | Difference in json outputs for glass and assembler      |

### **Context Json Ignore**
Context Json output from Glass compiler is verbose and may or may not be
consumed entirely by the drivers unlike the assembler Json output. The
tests/runtests script ignores the keys placed in the tests/ctxt\_json\_ignore file
while creating json diff to only display relevant mismatches

### **Json Diff**
Each test after running will have its own <testname>.out dir with following
items:
E.g. TEST = exact\_match0.p4
exact\_match0.p4.out
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
│   └── context.json
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
├── bfas.config.log
├── bfas.log
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
parameterized and placed in the constants.h file

"tofino" and "jbay" directories hold the chip schema to be used by the
assembler. The chip schema contains register information and is a binary
(python pickle file) generated from csv file in bfnregs repository.

The chip schema for tofino is copied from the glass compiler repository to align
with comparing glass output jsons.  To ensure glass and assembler are always pointing
to the same schema, create a symlink in your tofino-asm source directory to the
templates directory in the glass repo:

    ln -s $HOME/p4c-tofino/p4c_tofino/target/tofino/output/templates p4c-templates

(FIXME -- now that glass is in the same repo, should do this automatically?)

then any time you update the glass repo with a new chip.schema it will
automatically be copied into the tofino-asm source tree.

### **Config JSON**
The config json files (with .cfg.json extension) are generated by the
assembler which are fed into walle to generate the binary
(also called `tofino.bin`)

The config json is nothing but json files with a map of all the registers for
a backend. In order to limit the json file size assembler disables registers
which are not set (with the -C or condense json flag). Some registers are also
explicitly disabled or enabled based on what the drive expects to see in the
tofino.bin. Below is the status of regs and whether they will appear in the
config json.
```
---------------------------------
Disabled - (unconditionally)
---------------------------------
mem_pipe.mau
regs.input.icr.inp_cfg
regs.input.icr.intr
regs.header.hem.he_edf_cfg
regs.header.him.hi_edf_cfg
regs.glb_group
regs.chan0_group.chnl_drop
regs.chan0_group.chnl_metadata_fix
regs.chan1_group.chnl_drop
regs.chan1_group.chnl_metadata_fix
regs.chan2_group.chnl_drop
regs.chan2_group.chnl_metadata_fix
regs.chan3_group.chnl_drop
regs.chan3_group.chnl_metadata_fix
---------------------------------
Disabled - (if Zero)
---------------------------------
regs (In all regs)
mem_top (mau)
mem_pipe (mau/dummy_reg)
reg_top (ethgpiobr, ethgpiotl, pipes)
reg_pipe (mau, pmarb, deparser)
---------------------------------
Enabled - (always)
---------------------------------
regs.dp.imem.imem_subword8
regs.dp.imem.imem_subword16
regs.dp.imem.imem_subword32
regs.rams.map_alu.row[row].adrmux.mapram_config[col]
```
Once JBay support is added for all regs, above will be different for both
backends.

Driver dictates which regs are disabled or enabled unconditionally. Other
regs which are disabled if zero are to limit file size and driver should
automatically fill in the zero values.

#### Generating and using chip.schema

chip.schema files are generated by walle from the csv files in the
bfnregs repo.  To generate a new chip.schema file, use

    walle/walle.py --generate-schema ${BFNREGS_REPO}/modules/${CHIP}_regs

where `${BFNREGS_REPO}` is the root of the bfnregs repo, and `${CHIP}`
is the chip to target (`tofino`, `trestles`, or `jbay` at the moment).
The newly created chip.schema file should then be moved into the jbay
or tofino subdirectory where the build system expects to find it.

chip.schema is a binary (python pickle) file; you can use
`walle.py --dump-schema` to dump it as (vaguely human readble)
yaml.  It is basically a DAG of python objects (csr.address\_map,
csr.address\_map\_instance, and csr.reg) describing the register tree.
The build uses walle to turn this into json files describing various
subtrees of the dag.  The `template_objectss.yaml` file describes which
subtrees to generate json files for as well as list of subtrees to
ignore (elide from the json files).  Names in this file are the names of
csr.address\_map objects (NOT instances), and where the generated files
are nested, the containing json will contain a reference to the contained
json rather than a copy of the tree.  In this way, the generated json
files as a group describe the DAG even though json can only describe
trees, not DAGs.

If, when running make, you get a KeyError from walle, that generally
means that the template\_objects.yaml file contains a refernce to
some csr.address\_map that does not exist in the chip.schema file --
the register tree has changed in a way that invalidates the json files
it is trying to generate.  If you have your python setup to drop into pydb
automatically on an uncaught exception (highly recommended), at that point
you can use `pp section` to list all the csr.address\_map objects that
*are* in the chip.schema.  Generally you'll find that it is the 'ignore'
names that have changed, so fixing them is trivial.

## **Assembly Syntax**
The assembly syntax is documented in `SYNTAX.md` file
