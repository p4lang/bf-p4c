#!/usr/bin/env python
# Runs the compiler on a sample P4 program

from __future__ import print_function
from subprocess import Popen
from threading import Thread
import sys
import os
import stat
import tempfile
import shutil
import difflib

SUCCESS = 0
FAILURE = 1

class Options(object):
    def __init__(self):
        self.binary = ""                # this program's name
        self.cleanupTmp = True          # if false do not remote tmp folder created
        self.p4Filename = ""            # file that is being compiled
        self.compilerSrcDir = ""        # path to compiler source tree
        self.verbose = False
        self.replace = False            # replace previous outputs
        self.compilerOptions = []

def usage(options):
    name = options.binary
    print(name, "usage:")
    print(name, "rootdir [options] file.p4")
    print("Invokes p4c-tofino on the supplied file")
    print("`rootdir` is the root directory of the compiler source tree")
    print("options:")
    print("          -b: do not remove temporary results for failing tests")
    print("          -v: verbose operation")
    print("          -f: replace reference outputs with newly generated ones")

def isError(p4filename):
    # True if the filename represents a p4 program that should fail
    return "_errors" in p4filename

class Local(object):
    # object to hold local vars accessable to nested functions
    pass

def run_timeout(options, args, timeout, stderr):
    if options.verbose:
        print("Executing ", " ".join(args))
    local = Local()
    local.process = None
    def target():
        procstderr = None
        if stderr is not None:
            procstderr = open(stderr, "w")
        local.process = Popen(args, stderr=procstderr)
        local.process.wait()
    thread = Thread(target=target)
    thread.start()
    thread.join(timeout)
    if thread.is_alive():
        print("Timeout ", " ".join(args), file=sys.stderr)
        local.process.terminate()
        thread.join()
    if local.process is None:
        # never even started
        if options.verbose:
            print("Process failed to start")
        return -1
    if options.verbose:
        print("Exit code ", local.process.returncode)
    return local.process.returncode

def isv1_2(p4filename):
    return "v1_2" in p4filename

##################### P4 v1.0 processing

def process_v1_file(options, argv):
    assert isinstance(options, Options)
    args = ["./p4c-tofino", "-I" + options.compilerSrcdir + "/testdata/v1_samples/p4_lib"]
    args.extend(argv)
    if options.testName:
        args.extend(['-o', options.testName + '.tfa'])

    result = run_timeout(options, args, 30.0, None)

    expected_error = isError(options.p4filename)
    if expected_error:
        if result == SUCCESS:
            result = FAILURE
        else:
            result = SUCCESS
    return result


######################### main

def main(argv):
    options = Options()

    options.binary = argv[0]
    if len(argv) <= 2:
        usage(options)
        return FAILURE

    options.compilerSrcdir = argv[1]
    argv = argv[2:]
    if not os.path.isdir(options.compilerSrcdir):
        print(options.compilerSrcdir + " is not a folder", file=sys.stderr)
        usage(options)
        return FAILURE

    while argv[0][0] == '-':
        if argv[0] == "-b":
            options.cleanupTmp = False
        elif argv[0] == "-v":
            options.verbose = True
        elif argv[0] == "-f":
            options.replace = True
        else:
            print("Uknown option ", argv[0], file=sys.stderr)
            usage(options)
        argv = argv[1:]

    options.p4filename=argv[-1]
    options.testName = None
    if options.p4filename.startswith(options.compilerSrcdir):
        options.testName = options.p4filename[len(options.compilerSrcdir):];
        if options.testName.startswith('/'):
            options.testName = options.testName[1:]
        if options.testName.endswith('.p4'):
            options.testName = options.testName[:-3]

    result = process_v1_file(options, argv)

    if (result == SUCCESS and options.testName and
        os.path.exists(options.testName + '.tfa') and
        os.path.exists(options.p4filename[:-3] + '.stf')):
        srcdir = os.path.abspath(options.compilerSrcdir)
        test = os.path.abspath(options.p4filename[:-3] + '.stf')
        name = os.path.basename(options.testName)
        os.chdir(os.path.dirname(options.testName))
        result = run_timeout(options, [srcdir + '/backends/tofino/runtest',
                                       test, name], 30.0, None)
    else:
        if not os.path.exists(options.testName + '.tfa'):
            print("no path ", options.testName + '.tfa')
        if not os.path.exists(options.p4filename[:-3] + '.stf'):
            print("no path ", options.p4filename[:-3] + '.stf')

    sys.exit(result)

if __name__ == "__main__":
    main(sys.argv)
