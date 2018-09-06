#! /usr/bin/env python3

# Script to test different compiler options and ensure that the compiler generates the correct
# directory structure and manifest.

# There are a number of assumptions in the barefoot p4c driver:
#  - p4-14 maintains the same directory structure as Glass
#     - output directory (if not specified) is <p4_file.target>
#     - contents of the directory
#       - manifest.json
#       - context.json
#       - tofino.bin
#       - resources.json (if -g)
#       - graphs/* (if --create-graphs)
#       - visualization/*
#       - logs/*
#     - an archive (if --archive)
#  - p4-16 introduces named controls in the directory structure
#     - output directory (if not specified) is <p4_file.target>
#     - contents of the directory
#       - manifest.json
#       - per pipe
#         - context.json
#         - target.bin (tofino or tofino2)
#         - p4_file.res.json (if -g)
#       - graphs/* (if --create-graphs)
#     - an archive (if --archive)
#

from __future__ import print_function, absolute_import

import os, os.path, re, sys
import argparse
import importlib
import json
from multiprocessing import Pool, Queue
import shlex, shutil
import subprocess
import traceback

class Test:
    """A stateless class to run and check the output of a compiler run.

    It may be invoked in parallel and thus it imposes the constraint
    that different tests of the compiler keep the outputs in different
    directories. This can be accomplished mainly by providing separate
    -o arguments for each test (except archives which do not currently
    take as an argument the name of the archive).

    """
    def __init__(self, args):
        self._compiler = args.compiler
        self._dry_run = args.dry_run
        self._verbose = args.verbose
        self._keep_output = args.keep_output
        self._print_on_failure = args.print_on_failure
        self.defineCompilerArgs()

    def runCompiler(self, options, xfail_msg):
        """Run the compiler with the given options"

        If unsuccessful, but expected to fail (xfail_msg is not None)
        check that xfail_msg is in stderr. If it is, then return
        success.

        """
        if self._dry_run:
            print('{} {}'.format(self._compiler, ' '.join(options)))
            return 0

        args = [self._compiler] + options
        try:
            p = subprocess.Popen(shlex.split(' '.join(args)),
                                 stdout = subprocess.PIPE, stderr = subprocess.PIPE)
        except:
            print("error invoking {} {}".format(self._compiler, ' '.join(options)),file=sys.stderr)
            print(traceback.format_exc(), file=sys.stderr)
            return 1

        if self._verbose: print('running {}'.format(' '.join(args)))
        (outlog, errlog) = p.communicate() # now wait
        if self._verbose:
            print("Output log:", outlog.decode())
            print("Error log:", errlog.decode())
        if xfail_msg is not None:
            if errlog.find(bytearray(xfail_msg, 'utf-8')) == -1:
                return p.returncode
            else:
                return 0
        if p.returncode != 0 and self._print_on_failure:
            print(outlog.decode())
            print(errlog.decode(), file=sys.stderr)
        return p.returncode

    def defineCompilerArgs(self):
        """Selected set of compiler arguments that we want to test

        """
        parser = argparse.ArgumentParser(prog="p4c")
        # from p4c
        parser.add_argument("--target", dest="target",
                            help="specify target device",
                            action="store", default="tofino")
        parser.add_argument("--arch", dest="arch",
                            help="specify target architecture",
                            action="store", default="tna")
        parser.add_argument("-I", dest="arch",
                            help="include path",
                            action="store", default=None)
        parser.add_argument("-g", dest="debug_info",
                            help="Generate debug information",
                            action="store_true", default=False)
        parser.add_argument("-o", dest="output_directory",
                            help="Write output to the provided path",
                            action="store", metavar="PATH", default=None)
        parser.add_argument("--std", dest="language",
                            choices = ["p4-14", "p4-16"],
                            help="Treat subsequent input files as having type language.",
                            action="store", default="p4-16")
        # from the barefoot driver
        parser.add_argument("--archive",
                            help="Archive all outputs into a single tar.bz2 file",
                            action="store_true", default=False)
        parser.add_argument("--create-graphs",
                            help="Create graphs",
                            action="store_true", default=False)
        # parser.add_argument("--bf-rt-schema", action="store",
        #                   help="Generate and write BF-RT JSON schema  to the specified file")
        parser.add_argument("--validate-output", action="store_true", default=False,
                            help="run context.json validation")
        parser.add_argument("--validate-manifest", action="store_true", default=False,
                            help="run manifest validation")
        parser.add_argument ("source_file", help="P4 source file")
        self._parser = parser
        # now we can call
        # self._parser.parse_args(['--std=p4-14']) and parse the args


    def checkOutputDir(self, args):
        """Check that the right output directory has been produced and that
        the manifest exists

        """
        rc = 0
        if self._verbose: print("Source file:", args.source_file)

        if args.output_directory is None:
            file_name, ext = os.path.splitext(os.path.basename(args.source_file))
            outdir = file_name + "." + args.target
            if not os.path.isdir(outdir):
                print("Can not find the output directory:", outdir)
                rc = 1
            args.output_directory = outdir

        if args.output_directory and os.path.isdir(args.output_directory):
            if self._verbose:
                print("Output dir:", args.output_directory)
                for dirname, dirnames, filenames in os.walk(args.output_directory):
                    for f in filenames:
                        print(dirname + "/" + f)
            if not os.path.isfile(os.path.join(args.output_directory, "manifest.json")):
                print("Can not find the manifest file")
                rc = 1
        return rc

    def checkManifest(self, args):
        """Check that the right output directory has been produced and that
        the manifest exists

        """
        rc = 0
        if self._verbose:  print("check manifest in", args.output_directory)

        manifest_file = os.path.join(args.output_directory, "manifest.json")

        with open(manifest_file, 'r') as json_file:
            manifest = json.load(json_file)
            if (type(manifest) is not dict or "programs" not in manifest):
                print("ERROR: Input file '" + manifest_file + \
                      "' does not have a 'programs' key", file=sys.stderr)
                return 1

            schema_version = manifest['schema_version'];
            program = manifest['programs'][0]
            p4_version = program['p4_version']

            if not (p4_version == "p4-14" or p4_version == "p4-16"):
                    print("ERROR: Invalid program version", p4_version, "in", manifest_file,
                          file=sys.stderr)
                    return 1

            # check that there is at least one context.json defined, and that file exists
            def check_file_in_manifest(key, name):
                if key not in program:
                    print("ERROR: Input file '" + manifest_file + \
                          "' does not have a", key, "key", file=sys.stderr)
                    return 1

                m_dict = program[key]
                for item in m_dict:
                    m_file = os.path.join(args.output_directory, item['path'])
                    if not os.path.isfile(m_file):
                        print("ERROR: Input file '" + manifest_file + \
                              "' contains an invalid", name, "path:", m_file, file=sys.stderr)
                        return 1
                return 0

            # check that there is at least one context.json defined
            if len(program['contexts']) == 0:
                print("ERROR: Input file '" + manifest_file + \
                      "' contains an empty contexts dictionary", file=sys.stderr)
                return 1

            rc += check_file_in_manifest('binaries', 'binary file')
            rc += check_file_in_manifest('graphs', 'graph file')
            rc += check_file_in_manifest('logs', 'log file')
            if schema_version >= "1.3.0":
                rc += check_file_in_manifest('p4i', 'resources file')
        return rc

    def checkGraphs(self, args):
        """Check that the produced graphs are valid

        """
        if not args.create_graphs:
            return 0
        # \TODO: write the checks
        return 0

    def checkArchive(self, args):
        """Check that the produced archive is valid

        """
        if not args.archive:
            return 0
        # \TODO: write the checks
        return 0

    def checkTest(self, options):
        """Check that the generated output is correct.

        """
        if self._dry_run: return 0 # nothing to check if we didn't run

        args = self._parser.parse_known_args(options)[0]
        rc = 0
        rc += self.checkOutputDir(args)
        rc += self.checkManifest(args)
        rc += self.checkGraphs(args)
        rc += self.checkArchive(args)

        try:
            if not self._keep_output and not self._dry_run:
                shutil.rmtree(args.output_directory)
        except:
            # Couldn't remove the output dir
            pass

        return rc


    def runTest(self, options, xfail_msg = None):
        """Run an individual test using the options and if the run is
        successful check the outputs.

        Returns a string with the test result: PASS, FAIL, XFAIL, XPASS.

        """
        rc = self.runCompiler(options, xfail_msg)
        if rc == 0 and xfail_msg is None:
            rc = self.checkTest(options)
        if xfail_msg is None:
            if rc == 0: return "PASS"
            else: return "FAIL"
        else:
            if rc == 0: return "XFAIL"
            else: return "XPASS"


def load_test_file(testfile):
    """Load a test file.

    It needs to define test_matrix as a map of test names to a tuple
    of (compiler options, xfail message). If `xfail message` is not
    None, the test is expected to fail with that message.

    """
    data = None
    f = open(testfile)
    try:
        data = f.read()
    except:
        print("ERROR reading:", testfile)
        sys.exit(1)
    f.close()

    try:
        local_env = dict()
        global_env = dict(globals())
        global_env['__file__'] = testfile
        exec(compile(data, testfile, 'exec'), global_env, local_env)
        return local_env['test_matrix']
    except SystemExit:
        e = sys.exc_info()[1]
        if e.args:
            raise
    except:
        print(traceback.format_exc())
        return None

# -----------------------------------------------------------------------------------
p = argparse.ArgumentParser()
p.add_argument("--compiler", "-c", help="compiler path to test",
               action="store", default="./p4c")
p.add_argument("--filter", "-f", help="test filter regex",
               action="store", default=None)
p.add_argument("--jobs", "-j", help="number of jobs",
               action="store", type=int, default=1)
p.add_argument("--keep-output", "-k", help="keep output files",
               action="store_true", default=False)
p.add_argument("--test_matrix", "-m", help="test specification",
               action="store", default=None)
p.add_argument("--dry-run", "-n", help="print commands only",
               action="store_true", default=False)
p.add_argument("--print-on-failure", "-p", help="print compiler output when failed",
               action="store_true", default=False)
p.add_argument("--testfile", "-t", help="test specification file",
               action="store", default=None)
p.add_argument("--verbose", "-v", help="increase verbosity",
               action="store_true", default=False)
args = p.parse_args()

# ------------ load the tests that need to run
test_dir = os.path.join(os.path.abspath(os.path.dirname(__file__)), '../p4-tests')
tests_file = args.testfile or os.path.join(test_dir, "p4c_driver_tests.py")
test_matrix = load_test_file(tests_file)

def runOneTest(test_runner, test_name, args, xfail_msg):
    """Run a test and print the status

    """
    print('Starting', test_name, '......')
    rc = test_runner.runTest(args, xfail_msg)
    print(rc, ':', test_name)
    if rc == "PASS" or rc == "XFAIL": return 0
    else: return 1

# ---------- Filter which tests need to run
filter = None
if args.filter: filter = re.compile(args.filter)

if filter:
    tests_to_run = [ t for t in test_matrix if filter.match(t) ]
else:
    tests_to_run = [ t for t in test_matrix ]
skipped = len(test_matrix) - len(tests_to_run)

# ------- Run the tests (in parallel if requested)
failed = Queue()
test_runner = Test(args)

def worker(test_name):
    rc = runOneTest(test_runner, test_name, test_matrix[test_name][0], test_matrix[test_name][1])
    if rc != 0: failed.put(test_name)

if args.jobs > 1:
    with Pool(processes=args.jobs) as pool:
        pool.map(worker, tests_to_run)
else:
    for t in tests_to_run: worker(t)

# -------- Report the overall status
if not failed.empty() > 0:
    failedTests = []
    while not failed.empty(): failedTests.append(failed.get())
    print('Failed tests {} out of {}:'.format(len(failedTests), len(test_matrix)))
    print('  ','\n   '.join(failedTests))
    sys.exit(1)
else:
    print('Success:', len(tests_to_run), 'tests passed')
if skipped > 0:
    print('Skipped {} tests'.format(skipped))
