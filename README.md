# Tofino Assembler

### documentation

Documentation on using the assembler, notes on file formats, and internals are in [Google Drive > Barefoot shared > documents > Software > Assembler](https://drive.google.com/drive/folders/0Byf8esgFy8YacmNzMmZiSkN4OFU)

## Setup

At the moment there is no configure script or autoconf support -- the Makefile requires
GNU make and should suffice to build the assembler on any target

### Dependencies

- GNU make
- A C++ compiler supporting C++11 (the Makefile uses g++ by defalt)
- bison
- flex

Running the test suite requires access to the Glass p4c_tofino compiler.
Running stf tests requires access to the simple test harness.
The `tests/runtests` script will look in various places for these tools (see the top of the script)

### Testing

Running `make test` will run the tests/runtests script on all .p4 files in
the tests and tests/mau directories.  This script can run one or more tests
specified on the command line, or will run all .p4 files in the current directory
if run with no arguments.  Stf tests can be run if specified explicitly on the command
line; they will not run by default.
