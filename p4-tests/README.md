# p4_tests

This is the common repository for Glass and Brig compiler Testcases.
It includes two sub directories p4_14 and p4_16

How to Run tests:
=================

  1) Run bootstrap_bfn_env.sh to install all dependencies.

  2) Run bootstrap_bfn_compilers.sh to pull in submodules and bootstrap the
  compiler.

  3) Compile and run testcases

    cd build
    make -j8
    make -j8 check

Running PTF tests:
==================

All PTF tests are tagged with the 'ptf' label. Therefore, to run all PTF tests:

    cd build/p4c
    - For tofino
    ctest -L ptf -R "^tofino/"
    - For jbay
    ctest -L ptf -R "^tofino2/"

To run the PTF tests for a specific P4 program, use the '-R' option, with the
name of your P4 program. For example:

    cd build/p4c
    - For tofino
    ctest -L ptf -R "^tofino/.*easy_ternary"
    - For jbay
    ctest -L ptf -R "^tofino2/.*easy_ternary"

Running STF tests:
==================

STF tests can run both as STF (default) and as PTF. To enable the
latter, the PTF dependencies must be met, and you need to configure
as follows:

    cd build
    cmake .. -DENABLE_STF2PTF=ON
    make -j4
    ctest -V -L ptf [-R <test>]

Note that the re-configuration should not affect any dependencies, and
thus, there should be no recompilation.

To show logs from STF tests, export `ENABLE_MODEL_LOG` or `VERBOSE_MODEL_LOG`
environment variable. Logs are produced to terminal unless redirected.

Debugging a PTF test:
=====================

When you run a PTF test with `ctest`, log files are preserved in case of
failure. Look at the test output for a message like this one:
```
Error when running PTF tests
See logfiles under /tmp/easy_ternaryCB3hwv
```
Under that temporary directory you will find:
  - the model console output
  - the bf-drivers logs
  - the bf_switchd console output
  - the PTF logs

To enable the model log, set the `ENABLE_MODEL_LOG` environment variable and run
the ctest command as-is:

    export ENABLE_MODEL_LOG=1
    ctest -L ptf [-R <test>]

To enable *verbose* model log, set the `VERBOSE_MODEL_LOG` environment variable.
To keep the logs even if the test succeeds, set the `KEEP_LOGS` environment
variable.

In some cases, these logs are not enough and you want to have more control over
the execution of a PTF test. In this case, you can run the test in "3-window
mode", using a separate terminal window for the model, bf_switchd and PTF.
Assuming the required binaries (tofino-model, bf_switchd, PTF) are in your PATH,
you can run the following commands. Note that bootstrap_bfn_env.sh installs the
binaries under /usr/local, so these binaries should be in your PATH by
default. We use `$P4C_OUTPUT` to refer to the directory containing the compiler
outputs for the P4 program. In general, `$P4C_OUTPUT` corresponds to
`build/p4c/tofino/extensions/p4_tests/p4_<version>/<prog_name>.out`. We use
`$PTF_DIR` for the directory containing the PTF tests for your P4 program. In
general, `$PTF_DIR` corresponds to `p4-tests/p4_<version>/<prog_name>.ptf`.
Also for better troubleshooting look into the output from
running the PTF test - it should contain the actual commands with parameters
that were invoked (for starting model, switchd, ...) and also paths to
`$P4C_OUTPUT` and individual conf/json files that were used.


1. **Start the Tofino model**

    ```bash
    [sudo] tofino-model --p4-target-config $P4C_OUTPUT/<prog_name>.conf [-l $P4C_OUTPUT/[pipe/]context.json]
    ```

1. **Start bf_switchd**

    ```bash
    [sudo] [LD_LIBRARY_PATH=/usr/local/lib] bf_switchd --install-dir /usr/local --conf-file $P4C_OUTPUT/<prog_name>.conf --skip-p4 [--p4rt-server 0.0.0.0:50051]
    ```

    Alternatively for P4_14 programs (or others where the config file does not
    contain pointers to appropriate files):
    
    ```bash
    [sudo] [LD_LIBRARY_PATH=/usr/local/lib] bf_switchd --install-dir /usr/local --conf-file p4-tests/tofino.conf --skip-p4 [--p4rt-server 0.0.0.0:50051]
    ```


1. **Push P4 config to model / driver**

    ```bash
    [sudo] ./p4-tests/ptf_runner.py [--run-bfrt-as-pi pipe] --testdir $P4C_OUTPUT/ --name <prog_name> --update-config-only
    ```
    Note: `sudo` might reset environment variables, therefore it is possible
    that `PYTHONPATH` will not be properly set under `sudo` (leading to errors
    with the imports in the Python script). Either omit the `sudo` or preserve
    the `PYTHONPATH` via prefixing the command with
    `sudo env "PYTHONPATH=$PYTHONPATH" ./p4-tests/ptf_runner.py ...`.

1. *(Optional) Turn on model debug output*

    ```bash
    telnet localhost 8000
    rmt-set-log-flags
    ```
    Use `rmt-clear-log-flags` to turn verbose logging off and
    `rmt-set-log-flags -t <type> -f <flags>` to set specific logging flags.

1.  **Run PTF tests**

    ```bash
    [sudo] ./p4-tests/ptf_runner.py [--run-bfrt-as-pi pipe] --testdir $P4C_OUTPUT/ --name <prog_name> --ptfdir $PTF_DIR --test-only
    ```

1. **Run PD tests**
    ```bash
    [sudo] ./p4-tests/ptf_runner.py --testdir $P4C_OUTPUT/ --name <prog_name> --ptfdir $PTF_DIR --pdtest <prog_config_file>
    ```
    Where `<prog_config_file>` is the .conf file generated for this run.
    It can be manually generated using:
    ```bash
    ./p4-tests/internal/gen_pd_conf.py --name <prog_name> --testdir $P4C_OUTPUT --device <tofino|tofino2>
    ```

Any extra argument that you pass to ptf_runner.py will be forwarded to PTF. In
practice this is convenient when you want to run a single PTF test in the
test suite for that P4 program. For example:

    [sudo] ./p4-tests/ptf_runner.py --testdir build/p4c/tofino/extensions/p4_tests/p4_14/easy_ternary.out \
      --name easy_ternary --ptfdir p4-tests/p4_14/easy_ternary.ptf \
      --test-only test.SimpleTest

When running a STF test with PTF (aka STF2PTF), you need to use
`p4-tests/tools/stf/` as the `--ptfdir` and provide the path to the .stf file
with `--stftest`:

    [sudo] ./p4-tests/ptf_runner.py --testdir $P4C_OUTPUT/ --name <prog_name> \
      --ptfdir p4-tests/tools/stf/ --test-only --stftest <path to .stf file>

Often you may need to run bf_switchd in GDB. Because of the P4Runtime gRPC
server, you will need to ignore `SIG40` by typing `handle SIG40 noprint nostop`
at the GDB prompt.


Adding a P4 test program:
=========================

When adding a new P4 program (P4_14 or P4_16), remember to check-in the compiler
output files for it. These files are generated when you run the test suite and
you can locate them with `git status`. To generate the output files without
running the entire test suite, you can use the following commands:
  - for a P4_14 program: `ctest -L p14_to_16 -R <prog name>`
  - for a P4_16 program: `ctest -L p4 -R <prog name>`

Updating the P4 sample outputs:
===============================

You need to set the `P4TEST_REPLACE` environment variable:

    P4TEST_REPLACE=1 make check-p4

Adding diagnostic tests:
=========================

Diagnostic tests, which verify that the compiler reports correct warnings and errors, should include
the expected warning/error messages in checks inside comments in the P4 source code.

Checks have the following form:
```
expect TYPE@OFFSET: "REGEXP"
```
where:
- TYPE is "error" or "warning", which selects whether an error or a warning is expected in this check.
- OFFSET is a (possibly negative) number or the text "NO SOURCE". 
    - If the "@OFFSET" part is omittied, the check will be matched only if any location of a reported 
    error/warning match the source code line that the check is on. 
    - If OFFSET is a number, the required source code line is offset by the number.
    - If OFFSET is "NO SOURCE", the check will not require any source code lines to be included in the
    message.
- REGEXP is a regular expression to match reported error/warnings to.

Checks should be included in comments, with one check per comment. Both line and block comments work,
but keep in mind that a newline inside a block comment will be kept in the expected message regex, unless
it is escaped with `\` at the end of the line.

Some example checks:

- Check that an error will be reported on the same line that `increment` is defined:
```
action increment(bit<12> idx1, bit<12> idx2) { /* expect error: "The action increment indexes \
Counter ingress\.ctr2 with idx2 but it also indexes Counter ingress\.ctr1 with idx1\." */
```
- Check that an error will be reported, but don't require any source location:
```
// expect error@NO SOURCE: "Value used in select statement needs to be set from input packet"
parser SkipData(packet_in pkt, out SkipHeaders hdr, in bit<8> skipLength) {
```
- Check that an error will be reported on the preceding line:
```
value.qdepth_drain_cells = (bit<32>)(qos.qdepth |-| (bit<19>)value.target_qdepth)[18:6];
// expect error@-1: "expression too complex for RegisterAction"
```
- Checks can be enabled/disabled based on compiler definitions (for more information about them see `add_test_compiler_definition` in `TestUtils.cmake`):
```
        //==== int<8> register ====
        Register<paired_8int,_>(1024) my_reg;
#if TEST == 1
        /* expect error@-2: "Register actions associated with .* do not fit on the device\. \
Actions use 5 large constants but the device has only 4 register action parameter slots\. \
To make the actions fit, reduce the number of large constants\." */
#elif TEST == 2
        /* expect error@-6: "Register actions associated with .* do not fit on the device\. \
Actions use 2 large constants and 3 register parameters for a total of 5 register \
action parameter slots but the device has only 4 register action parameter slots\. \
To make the actions fit, reduce the number of large constants or register parameters\." */
#elif TEST == 3
        /* expect error@-11: "Register actions associated with .* do not fit on the device\. \
Actions use 5 register parameters but the device has only 4 register action parameter slots\. \
To make the actions fit, reduce the number of register parameters\." */
#endif
```

If there is at least one error check in the program, the compiler will return a success
return code (0) if each reported error has been matched with one error check and there are no
unmatched error checks left at the end of the compilation, otherwise the compiler will report
a failure. Warnings are less strict and will cause a failure only if there are unmatched warning
checks left at the end of the compilation, but there can be other warnings that are not
listed in checks.

If the above behavior doesn't work, make sure the compiler is built with `-DBAREFOOT_INTERNAL=1`.
Debugging messages regarding checks can be enabled with `-Tbf_error_reporter:1`.

Tests that include warning checks are run exactly like normal compilation tests, except they
will fail if the expected warning isn't reported.

Tests that include error checks (negative tests) have to be registered a little differently in 
`ctest` because we only want to run the compiler, without the assembler or further steps. Tests
put in `p4_16/errors` will be automatically registered for all devices. Tests put in a subdirectory
with the name corresponding to a given device will be registered for that device, for example tests
in `p4_16/errors/tofino` will be registered only for Tofino, while tests in `p4_16/errors/jbay` will
be registered only for Jbay. To register a negative test from another directory, see the 
`set_negative_tests` macro in `TestUtils.cmake`.
