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
    ctest -V -L ptf

To run the PTF tests for a specific P4 program, use the '-R' option, with the
name of your P4 program. For example:

    cd build/p4c
    ctest -V -L ptf -R easy_ternary


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

  1) Starting the Tofino model

    sudo tofino-model -l $P4C_OUTPUT/p4_name_lookup.json

  2) Starting bf_switchd

    sudo bf_switchd --install-dir /tmp --conf-file p4-tests/dummy.conf --skip-p4

  3) Pushing P4 config to model / drivers and running PTF tests

    ./p4-tests/ptf_runner.py --testdir $P4C_OUTPUT/ --name <prog_name> --update-config-only
    sudo ./p4-tests/ptf_runner.py --testdir $P4C_OUTPUT/ --name <prog_name> --ptfdir $PTF_DIR --test-only

Any extra argument that you pass to ptf_runner.py will be forwarded to PTF. In
practice this is convenient when you want to run a single PTF test in the
test suite for that P4 program. For example:

    sudo ./p4-tests/ptf_runner.py --testdir build/p4c/tofino/extensions/p4_tests/p4_14/easy_ternary.out \
      --name easy_ternary --ptfdir p4-tests/p4_14/easy_ternary.ptf \
      --test-only test.SimpleTest

Often you may need to run bf_switchd in GDB. Because of the P4Runtime gRPC
server, you will need to ignore `SIG36` by typing `handle SIG36 noprint nostop`
at the GDB prompt.

Adding a P4 test program:
=========================

When adding a new P4 program (P4_14 or P4_16), remember to check-in the compiler
output files for it. These files are generated when you run the test suite and
you can locate them with `git status`. To generate the output files without
running the entire test suite, you can use the following commands:
  - for a P4_14 program: `ctest -L p14_to_16 -R <prog name>`
  - for a P4_16 program: `ctest -L p4 -R <prog name>`
