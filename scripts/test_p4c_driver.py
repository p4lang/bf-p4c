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
from packaging import version
import shlex, shutil
import subprocess
import traceback

class TestError(Exception):
    def __init__(self, info=""):
        self.info = info

    def __str__(self):
        return self.info

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
        parser.add_argument("-E", dest="preprocessor_only",
                            help="run preprocessor only",
                            action="store_true", default=False)
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
        parser.add_argument("--archive", nargs='?',
                            help="Archive all outputs into a single tar.bz2 file.\n" + \
                            "Note: it can not be the argument before source file" + \
                            " without specifying the archive name!",
                            const="__default__", default=None)
        parser.add_argument("--create-graphs",
                            help="Create graphs",
                            action="store_true", default=False)
        # parser.add_argument("--bf-rt-schema", action="store",
        #                   help="Generate and write BF-RT JSON schema  to the specified file")
        parser.add_argument("--validate-output", action="store_true", default=False,
                            help="run context.json validation")
        parser.add_argument("--validate-manifest", action="store_true", default=False,
                            help="run manifest validation")
        parser.add_argument("--verbose",
                            action="store", default=0, type=int, choices=[0, 1, 2, 3],
                            help="Set compiler logging verbosity level: 0=OFF, 1=SUMMARY, 2=INFO, 3=DEBUG")
        parser.add_argument ("source_file", help="P4 source file")
        self._parser = parser
        # now we can call
        # self._parser.parse_args(['--std=p4-14']) and parse the args


    def checkOutputDir(self, args):
        """Check that the right output directory has been produced and that
        the manifest exists

        """
        if self._verbose: print("Source file:", args.source_file)

        if args.output_directory is None:
            file_name, ext = os.path.splitext(os.path.basename(args.source_file))
            outdir = file_name + "." + args.target
            if not os.path.isdir(outdir):
                raise TestError(
                    "Can not find the output directory: '{}'".format(outdir))
            args.output_directory = outdir

        if args.output_directory and os.path.isdir(args.output_directory):
            if self._verbose:
                print("Output dir:", args.output_directory)
                for dirname, dirnames, filenames in os.walk(args.output_directory):
                    for f in filenames:
                        print(dirname + "/" + f)
            if not args.preprocessor_only and not os.path.isfile(os.path.join(args.output_directory, "manifest.json")):
                raise TestError("Can not find the manifest file")

    def checkManifest(self, args):
        """Check that the right output directory has been produced and that
        the manifest exists

        """
        if args.preprocessor_only:
            return
        if self._verbose:
            print("check manifest in", args.output_directory)

        manifest_file = os.path.join(args.output_directory, "manifest.json")

        with open(manifest_file, 'r') as json_file:
            manifest = json.load(json_file)
            if type(manifest) is not dict or "programs" not in manifest:
                raise TestError(
                    "ERROR: Input file '{}' does not have a 'programs' key",
                    manifest_file)

            schema_version = version.parse(manifest['schema_version'])
            program = manifest['programs'][0]
            p4_version = program['p4_version']

            if not (p4_version == "p4-14" or p4_version == "p4-16"):
                raise TestError(
                    "ERROR: Invalid program version {} in '{}'",
                    p4_version, manifest_file)

            # check that there is at least one context.json defined, and that file exists
            def check_file_in_manifest(key, name):
                if schema_version < version.parse("2.0.0"):
                    prg = program
                else:
                    prg = program['pipes'][0]['files']

                if key not in prg:
                    raise TestError("ERROR: Input file '{}' does not have "
                                    "a key '{}'".format(manifest_file, key))

                m_dict = prg[key]
                for item in m_dict:
                    if isinstance(item, dict):
                        m_file = os.path.join(args.output_directory, item['path'])
                    else:
                        m_file = os.path.join(args.output_directory, m_dict['path'])
                    if not os.path.isfile(m_file):
                        raise TestError("ERROR: Input file '{}' contains an invalid "
                                        "{} path: {}".format(manifest_file, name, m_file))

            # check that there is at least one context.json defined
            if schema_version < version.parse("2.0.0"):
                if len(program['contexts']) == 0:
                    raise TestError(
                        "ERROR: Input file '{}' contains an empty 'contexts' "
                        "dictionary", manifest_file)
            else:
                context = program['pipes'][0]['files'].get('context', False)
                if context:
                    check_file_in_manifest('context', 'context file')
                else:
                    raise TestError(
                        "ERROR: Input file '{}' contains an empty 'contexts' "
                        "dictionary", manifest_file)

            # check_file_in_manifest('binaries', 'binary file')
            check_file_in_manifest('graphs', 'graph file')
            check_file_in_manifest('logs', 'log file')
            if schema_version >= version.parse("1.3.0") and \
               schema_version < version.parse("2.0.0"):
                check_file_in_manifest('p4i', 'resources file')
            elif schema_version >= version.parse("2.0.0"):
                check_file_in_manifest('resources', 'resources_file')

    def checkGraphs(self, args):
        """Check that the produced graphs are valid

        """
        if not args.create_graphs:
            return
        # \TODO: write the checks

    def checkArchive(self, args):
        """Check that the produced archive is valid

        """
        if args.archive is None:
            return
        # \TODO: write the checks

    def checkMAUStagesForTarget(self, args):
        """Check that the number of stages generated in the resources file
           is valid for the target:
        """
        stages = {
            "tofino"   : 12,
            "tofino2"  : 20,
            "tofino2h" :  6,
            "tofino2m" : 12,
            "tofino2u" : 20,
            "tofino3"  : 20
        }

        if args.preprocessor_only:
            return

        manifest_file = os.path.join(args.output_directory, "manifest.json")

        with open(manifest_file, 'r') as json_file:
            manifest = json.load(json_file)
            schema_version = version.parse(manifest['schema_version'])
            target = manifest['target']
            if target not in stages.keys():
                raise TestError("ERROR: Invalid target {}".format(target))
            program = manifest['programs'][0]
            p4_version = program['p4_version']
            if schema_version < version.parse("2.0.0"):
                resources_files = program['p4i']
            else:
                resources_files = program['pipes'][0]['files']['resources']
            resources_file = None
            for r in resources_files:
                m_file = os.path.join(args.output_directory, r['path'])
                if not os.path.isfile(m_file):
                    raise TestError(
                        "ERROR: Input file '{}' contains an invalid "
                        "{} path: {}".format(manifest_file, 'resources file', m_file))
                # Get the resources.json/res.json path if it exists
                if r['type'] is "resources":
                    resources_file = os.path.join(args.output_directory, r['path'])
            if resources_file:
                with open(resources_file, 'r') as res_file:
                    res_json = json.load(res_file)
                    resources = res_json['resources']
                    nStages = int(resources['pipes'][0]['mau']['nStages'])
                    if nStages != stages[target]:
                        raise TestError(
                            "ERROR: Number of stages in resource file {} "
                            "!= {} expected".format(nStages, stages[target]))
        # success
        # if we either did not have a resource file, or all the stages check out.

    def checkOutputFiles(self, args, file_list):
        """
        If third item of the test_matrix tuple is not None, but List
        check (non)existence of files Listed. File path prefixed
        with ! symbol means check non-existence.
        """
        if file_list is None: return

        for file in file_list:
            fileShouldNotExist = False
            if file[0] is '!':
                file = file[1:]
                fileShouldNotExist = True
            path = os.path.join(args.output_directory, file)

            if fileShouldNotExist and os.path.isfile(path):
                raise TestError(
                    "ERROR: File {} exists (and should not)".format(path))
            elif not fileShouldNotExist and not os.path.isfile(path):
                raise TestError(
                    "ERROR: File {} does not exist".format(path))

    def checkTest(self, options, file_list):
        """
        Check that the generated output is correct.
        file_list contains list of files to check for (non)existence
        """
        if self._dry_run: return 0 # nothing to check if we didn't run

        args = self._parser.parse_known_args(options)[0]
        try:
            self.checkOutputDir(args)
            self.checkManifest(args)
            self.checkGraphs(args)
            self.checkArchive(args)
            self.checkMAUStagesForTarget(args)
            self.checkOutputFiles(args, file_list)
        except TestError as e:
            print("********************", file=sys.stderr)
            print("Error when checking output", file=sys.stderr)
            print(e, file=sys.stderr)
            print("********************", file=sys.stderr)
            return 1
        except Exception:
            print("Some other error occured")
            print(traceback.format_exc(), file=sys.stderr)
            return 1

        try:
            if not self._keep_output and not self._dry_run:
                shutil.rmtree(args.output_directory)
                if args.archive is not None:
                    archiveName, ext = os.path.splitext(os.path.basename(args.archive))
                    if args.archive == "__default__":
                        archiveName, ext = os.path.splitext(os.path.basename(args.source_file))
                    archiveName += ".tar.bz2"
                    os.remove(archiveName)

        except:
            # Couldn't remove the output dir
            pass

        return 0


    def runTest(self, options, xfail_msg = None, file_list = None):
        """Run an individual test using the options and if the run is
        successful check the outputs.

        Returns a string with the test result: PASS, FAIL, XFAIL, XPASS.

        """
        rcCode = self.runCompiler(options, xfail_msg)

        if xfail_msg is not None:
            if rcCode == 0: return "XFAIL"
            else: return "XPASS"

        ctCode = self.checkTest(options, file_list)
        if rcCode == 0 and ctCode == 0 and xfail_msg is None:
            return "PASS"
        elif ctCode != 0: return "VALIDATION_FAIL"
        else: return "FAIL"


def load_test_file(testfile):
    """Load a test file.

    It needs to define test_matrix as a map of test names to a tuple
    of (compiler options, xfail message, file_list). If `xfail message` is not
    None, the test is expected to fail with that message. The `file_list` is the
    list of files to check for the existence.

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
p.add_argument("--list", "-l", help="list available tests",
               action="store_true", default=False)
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

def runOneTest(test_runner, test_name, args, xfail_msg, file_list):
    """Run a test and print the status

    """
    print('Starting', test_name, '......')
    rc = test_runner.runTest(args, xfail_msg, file_list)
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

if args.list:
    print('Tests:\n ', '\n  '.join(tests_to_run))
    sys.exit(0)

# ------- Run the tests (in parallel if requested)
failed = Queue()
test_runner = Test(args)

def worker(test_name):
    rc = runOneTest(test_runner, test_name, test_matrix[test_name][0], test_matrix[test_name][1], test_matrix[test_name][2])
    if rc != 0:
        failed.put(test_name)
    else:
        # we need to use sentinels to ensure that we do not miss any failed
        # tests later
        # surprisingly enough, the following code sometimes prints 'True':
        # q = Queue()
        # q.put(7)
        # print q.empty()
        failed.put(None)

if args.jobs > 1:
    with Pool(processes=args.jobs) as pool:
        pool.map(worker, tests_to_run)
else:
    for t in tests_to_run: worker(t)

failedTests = []
cnt = 0
while cnt != len(tests_to_run):
    r = failed.get()
    cnt += 1
    if r is not None:
        failedTests.append(r)

# -------- Report the overall status
if failedTests:
    print('Failed tests {} out of {}:'.format(len(failedTests), len(test_matrix)))
    print('  ','\n   '.join(failedTests))
    sys.exit(1)
else:
    print('Success:', len(tests_to_run), 'tests passed')
if skipped > 0:
    print('Skipped {} tests'.format(skipped))
