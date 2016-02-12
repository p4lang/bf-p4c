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
    print("Invokes compiler on the supplied file, possibly adding extra arguments")
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

####################### P4 v1.2 processing

v12_timeout = 100

def compare_files(options, produced, expected):
    if options.replace:
        if options.verbose:
            print("Saving new version of ", expected)
        shutil.copy2(produced, expected)
        return SUCCESS

    if options.verbose:
        print("Comparing", produced, "and", expected)
    diff = difflib.Differ().compare(open(produced).readlines(), open(expected).readlines())
    result = SUCCESS

    message = ""
    for l in diff:
        if l[0] == ' ': continue
        result = FAILURE
        message += l

    if message is not "":
        print("Files ", produced, " and ", expected, " differ:", file=sys.stderr)
        print(message, file=sys.stderr)

    return result

def recompile_file(options, produced, mustBeIdentical):
    # Compile the generated file a second time
    secondFile = produced + "-x";
    args = ["./v12test", "--pp", secondFile, "--p4v", "1.2", produced]
    result = run_timeout(options, args, v12_timeout, None)
    if result != SUCCESS:
        return result
    if mustBeIdentical:
        result = compare_files(options, produced, secondFile)
    return result

def check_generated_files(options, tmpdir, expecteddir):
    files = os.listdir(tmpdir)
    for file in files:
        if options.verbose:
            print("Checking", file)
        produced = tmpdir + "/" + file
        expected = expecteddir + "/" + file
        if not os.path.isfile(expected):
            if options.verbose:
                print("Expected file does not exist; creating", expected)
            shutil.copy2(produced, expected)
        else:
            result = compare_files(options, produced, expected)
            if result != SUCCESS:
                return result
    return SUCCESS

def process_v1_2_file(options, argv):
    assert isinstance(options, Options)

    tmpdir = tempfile.mkdtemp(dir=".")
    basename = os.path.basename(options.p4filename)
    base, ext = os.path.splitext(basename)
    dirname = os.path.dirname(options.p4filename)
    expected_dirname = dirname + "_outputs"  # expected outputs are here

    if options.verbose:
        print("Writing temporary files into ", tmpdir)
    ppfile = tmpdir + "/" + basename                  # after parsing
    lastfile = tmpdir + "/" + base + "-last" + ext    # last file produced
    stderr = tmpdir + "/" + basename + "-stderr"

    if not os.path.isfile(options.p4filename):
        raise Exception("No such file " + options.p4filename)
    args = ["./v12test", "--pp", ppfile, "--dump", tmpdir]
    args.extend(argv)

    result = run_timeout(options, args, v12_timeout, stderr)
    if result != SUCCESS:
        print("Error compiling")
        print("".join(open(stderr).readlines()))

    expected_error = isError(options.p4filename)
    if expected_error:
        # invert result
        if result == SUCCESS:
            result = FAILURE
        else:
            result = SUCCESS

    if (result == SUCCESS):
        result = check_generated_files(options, tmpdir, expected_dirname);
    if (result == SUCCESS) and (not expected_error):
        result = recompile_file(options, ppfile, True)
    if (result == SUCCESS) and (not expected_error):
        result = recompile_file(options, lastfile, True)

    if options.cleanupTmp:
        if options.verbose:
            print("Removing", tmpdir)
        shutil.rmtree(tmpdir)
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

    if isv1_2(options.p4filename):
        result = process_v1_2_file(options, argv)
    else:
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
