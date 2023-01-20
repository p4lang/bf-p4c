#!/usr/bin/python3
# -*- Python -*-
"""
P4C compiler benchmarks for measuring compilers performance.
"""
import argparse
import json
import subprocess
import os
import platform
from unittest import result
import psutil
import re
from datetime import datetime
import sys
from pathlib import Path

# Version is needed to correctly compare and plot outputs.
# If any major change is done to the results, the version should change.
__version__ = "1.0.0"
verbose = False

def fatal_error(msg):
    """!
    Prints error message and exits with 1
    :param msg Error message
    """
    print("ERROR: {}".format(msg), file=sys.stderr)
    exit(1)


def run_shell_cmd(cmd):
    """!
    Runs a shell command
    @param cmd Command to be run as a string or a list
    @return Object containing:
            - returncode: return code
            - stdout: standard output after running the command
            - stderr: standard output error after running the command
    """
    # Concat command and args
    if type(cmd) != str:
        cmd = " ".join(cmd)
    if verbose:
        print("+", cmd)
    return subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding="utf-8")


class BenchmarkTest:
    """!
    Holds information and setting for a test
    """
    # Regex for extracting measured time
    RE_TIME_MEASURED = re.compile(r'BENCHMARK_TIME:(.*)#')

    def __init__(self, name, params, compiler_path, dir_path, core_number):
        """
        Constructor
        :param name Test's name
        :param params Test's P4C parameters
        :param compiler_path Path to P4C compiler
        """
        self.name = name
        self.compiler_path = Path(compiler_path)
        self.dir_path = dir_path
        self.path = Path(params["path"])
        self.args = params["args"]
        # Go though args and those starting with "./" change to path to this folder
        for i in range(len(self.args)):
            if len(self.args[i]) > 1 and self.args[i][0:2] == "./":
                self.args[i] = self.dir_path / Path(self.args[i][1:])
        self.core_number = core_number

    def run(self):
        """!
        Runs benchmark test
        """
        measure_script = self.dir_path / Path("measure_process.sh")
        core_number = self.core_number
        p4c_args = " ".join(str(x) for x in self.args)
        test_path = self.dir_path / self.path

        command = " ".join(["bash", str(measure_script), core_number, '"', str(self.compiler_path), p4c_args, 
                            str(test_path), "-o /tmp/.benchmark_output", '"'])
        result = run_shell_cmd(command)
        if result.returncode != 0:
            fatal_error(f"Command '{command}' exited with {result.returncode}!")
        time_str = BenchmarkTest.RE_TIME_MEASURED.search(result.stderr)
        time = float(time_str.groups()[0])
        return time

class Benchmarks:
    """!
    Class handeling benchmarks
    """
    # Regex for extracting p4c version
    RE_P4C_VERSION = re.compile(r'p4c ([0-9]+\.[0-9]+\.[0-9]+) .*')
    RE_P4C_SHA = re.compile(r'p4c [0-9]+\.[0-9]+\.[0-9]+ \(SHA: (.*)\)')

    def __init__(self, arg_parser):
        """!
        Constructor
        :param arg_parser argparse object
        """
        self._arg_parser = arg_parser
        # Parse arguments
        self.add_command_line_options()
        self.opts = self._arg_parser.parse_args()
        self.p4c_path = self.opts.p4c_path
        self.core_number = self.opts.core_number
        self.output_path = self.opts.output_path
        self.repeat = self.opts.repeat
        self.repo_path = self.opts.repo_path
        self.make_cores = self.opts.make_cores
        global verbose
        verbose = self.opts.verbose
        self.build_command = "./bootstrap_bfn_compilers.sh --build-dir build --small-config --build-type RelWithDebInfo -DENABLE_GTESTS=OFF -DENABLE_BMV2=OFF -DENABLE_DPDK=OFF"
        if self.opts.build_path is not None:
            with open(self.opts.build_path, "r", encoding="utf-8") as build_script:
                self.build_command = build_script.read()
        # Flatten test_filter and commits
        self.test_filter = None if self.opts.test_filter is None else [x for subl in self.opts.test_filter for x in subl]
        self.commits = None if self.opts.commits is None else [x for subl in self.opts.commits for x in subl]
        self.tests_dir = Path(os.path.dirname(self.opts.tests_path))
        print(self.tests_dir)
        # Load tests from config into dict
        self.tests_config = self.load_json(self.opts.tests_path)
        self.reference = self.load_json(self.opts.ref_file) if self.opts.ref_file is not None else None

    def add_command_line_options(self):
        """!
        Sets up command line options for benchmarks
        """
        self._arg_group = self._arg_parser.add_argument_group("P4C benchmarks options")
        self._arg_group.add_argument("tests_path", type=str, 
                                    help="Path to the tests json configuration file.")
        self._arg_group.add_argument("--p4c",
                                    help="Path or command to run the P4C compiler.",
                                    action="store", default="p4c", type=str,
                                    dest="p4c_path", required=False)
        self._arg_group.add_argument("-n",
                                    help="Core number on which to run the tests.",
                                    action="store", default="1", type=str,
                                    dest="core_number", required=False)
        self._arg_group.add_argument("--ref",
                                    help="Path to a reference json file for comparison.",
                                    action="store", default=None, type=str,
                                    dest="ref_file", required=False)
        self._arg_group.add_argument("-o",
                                    help="File to which save the output json results.",
                                    action="store", default=None, type=str,
                                    dest="output_path", required=False)
        self._arg_group.add_argument("-d",
                                     help="Destination to which clone p4c repo or where it already \
                                     is cloned.", default="/tmp/bf-p4c-compilers", type=str,
                                     dest="repo_path", required=False)
        self._arg_group.add_argument("-t",
                                    help="Specific test(s) to run",
                                    action="append", default=None, nargs='+',
                                    dest="test_filter", required=False)
        self._arg_group.add_argument("-r", "--repeat",
                                    help="Run the same test set given times.",
                                    action="store", default=1, type=int,
                                    dest="repeat", required=False)
        self._arg_group.add_argument("-c",
                                    help="Specific commit(s) to benchmark",
                                    action="append", default=None, nargs='+',
                                    dest="commits", required=False)
        self._arg_group.add_argument("-j",
                                    help="Number of cores to be used for make command.",
                                    action="store", default=76, type=int,
                                    dest="make_cores", required=False)
        self._arg_group.add_argument("-b", "--build",
                                    help="Path to a build (bootstrap) script to be used.",
                                    action="store", default=None,
                                    dest="build_path", required=False)
        self._arg_group.add_argument("-x",
                                    help="Verbose. Prints out executed shell commands.",
                                    action="store_true", default=False, dest="verbose")

    def load_json(self, path):
        """!
        Loads json from passed in path
        :param path Path to the json file
        :return JSON file as a python dict
        """
        cnt = None
        with open(path, "r") as json_file:
            cnt = json.load(json_file)
        return cnt

    @staticmethod
    def get_platform_info():
        """!
        :return Dict with info about this platform (PC)
        """
        # Getting CPU model
        cpu_res = run_shell_cmd(["lscpu | grep 'Model name:.*'"])
        # Remove prefix from lscpu to get the cpu model
        cpu_model = re.sub(r'Model name:\s*', '', cpu_res.stdout)
        cpu_model = cpu_model.rstrip()
        return {
            "memory": {
                "size": psutil.virtual_memory().total
            },
            "cpu": {
                "model": cpu_model,
                "freq_min": psutil.cpu_freq().min,
                "freq_max": psutil.cpu_freq().max,
                "cores": psutil.cpu_count()
            },
            "os": platform.platform() 
        }

    @staticmethod
    def get_p4c_info(p4c_path):
        """!
        :return Dict with info about used P4C compiler
        """
        p4c_res = run_shell_cmd(["{} --version".format(p4c_path)]) 
        p4c_version_match = Benchmarks.RE_P4C_VERSION.search(p4c_res.stdout)
        p4c_sha_match = Benchmarks.RE_P4C_SHA.search(p4c_res.stdout)
        return {
            "version": p4c_version_match.groups()[0],
            "sha": p4c_sha_match.groups()[0]
        }

    def clone_repo(self, dst_dir):
        """!
        Clones the bf-p4c repo to dst_dir, unless it already exists
        @param dst_dir Destination directory for the bf-p4c compiler repo
        @return None
        """
        if not Path(dst_dir).is_dir():
            cmd = ["git", "clone", "--recursive", 
                "git@github.com:barefootnetworks/bf-p4c-compilers.git", dst_dir]
            print("Cloning bf-p4c repo, this might take some time...")
            result = run_shell_cmd(cmd)
            if result.returncode != 0:
                print(f"Error occurred when cloning bf-p4c: \"{result.stderr}\"", file=sys.stderr)
                exit(1)
        else:
            print("Destination directory already exists. Repository will not be cloned.")
        
    def checkout(self, commit, dir):
        """!
        Checksout bf-p4c repo to passed in commit
        @param commit Commit to checkout to
        @param dir Directory where is the bf-p4c repo cloned
        @return None
        """
        cmd = ["cd", dir, "&&", "git", "checkout", commit, "&&", "git", "submodule", "update"]
        print(f"Checking out to {commit}.")
        result = run_shell_cmd(cmd)
        if result.returncode != 0:
            print(f"Error checking out the repository: \"{result.stderr}\"", file=sys.stderr)
            exit(1)

    def build(self, dir):
        """!
        Builds bf-p4c
        @param dir Directory, where the repo is located
        @return None
        """
        cmd = ["cd", dir, "&&", self.build_command]
        print("Running a bootstrap")
        result = run_shell_cmd(cmd)
        if result.returncode != 0:
            print(f"Error occurred when running a bootstrap: '{result.stderr}'", file=sys.stderr)
            exit(1)
        cmd = ["cd", dir, "&&", "cd", "build", "&&", "make", "-j"+str(self.make_cores)]
        print("Running make, this might take some time...")
        result = run_shell_cmd(cmd)
        if result.returncode != 0:
            print(f"Error occurred when making the compiler: '{result.stderr}'", file=sys.stderr)
            exit(1)


    def compare(self, results, reference):
        """!
        Compares benchmark results with reference values and prints
        the difference in human readable form to the stdout
        :param results Benchmark results dict
        :param reference Reference dict
        :return True if all differences are within set threshold,
                False otherwise
        """
        in_thr = True
        for name, value in results.items():
            c_time_now = float(value["compile_time"])
            c_time_master = float(reference[name]["compile_time"])
            threshold = int(reference[name]["threshold_pct"])
            # Calculate percentage difference between the 2 times
            diff = (c_time_now/c_time_master-1.0)*100.0
            if diff > threshold:
                in_thr = False
                print("FAIL: Benchmark '{}' was slowed down by more than its threshold ({} %). "
                      "If this slow down is unavoidable, change the reference compile time in "
                      "'benchmark-references.json' file to {}.".format(name, threshold, c_time_now))
            diff_abs = round(abs(diff), 1)
            # leave small difference as equality
            if diff > -0.9 and diff < 0.9:
                print("NO CHANGE: '{}' has no change in compile time.".format(name))
            elif diff < 0.0:
                print("SPEED UP: '{}' was sped up by {} % (from {} s to {} s)."
                      .format(name, diff_abs, c_time_master, c_time_now))
            else:
                print("SLOW DOWN: '{}' was slowed down by {} % (from {} s to {} s)."
                      .format(name, diff_abs, c_time_master, c_time_now))
        return in_thr

    @staticmethod
    def average_results(results):
        """!
        Takes list of results and returns single result containing
        average values for all results.
        :param results List of result dictionaries
        :return Result dictionary with average value for given list of results
        """
        avg = {}
        for test_name in results[0]:
            sum = 0
            for r in results:
                sum += r[test_name]["compile_time"]
            avg[test_name] = sum/len(results)
        return avg

    def save_results(self, results, output_path=None):
        """!
        Saves benchmarks results and needed info into a file
        :param results Results dictionary
        :param output_path Path to the output file or folder, if None, then
                           current datetime with prefix will be used.
        """
        output_dict = {
            "benchmark": {
                "version": __version__,
                "time": int(datetime.now().timestamp())
            },
            "platform": self.get_platform_info(),
            "p4c": self.get_p4c_info(self.p4c_path),
            "results": results
        }
        # Handle output file path
        default_output = "p4c-benchmarks_"+datetime.now().strftime("%Y-%m-%d_%H-%M")+".json"
        if output_path is None:
            output_path = default_output
        elif os.path.isdir(output_path):
            output_path = os.path.normpath(output_path)+"/"+default_output
        # Save output to a file
        with open(output_path, "w") as json_f:
            json.dump(output_dict, json_f, indent=2)

    def run_benchmarks(self):
        """!
        Runs P4C benchmark pipeline
        :return True if benchmark results are within set compare threshold or 
                no compare file was set. False otherwise.
        """
        was_success = True
        tests = []
        for test, params in self.tests_config.items():
            if self.test_filter is None or test in self.test_filter:
                tests.append(BenchmarkTest(test, params, self.p4c_path, self.tests_dir, self.core_number))

        all_results = []
        for _ in range(self.repeat):
            results = {}
            for c, test in enumerate(tests):
                print("[{}/{}] RUNNING {}".format(c+1, len(tests), test.name))
                compile_time = test.run()
                results[test.name] = {"compile_time": compile_time,
                                    "path": test.path,
                                    "p4c_args": test.args}
                print("[{}/{}] FINISHED {} in {} sec".format(c+1, len(tests), test.name, compile_time))
            all_results.append(results)
        # Calculate average result from all runs
        avg_results = Benchmarks.average_results(all_results)
        # Save results to the output file
        self.save_results(avg_results, self.output_path)
        # Compare results with reference values
        if self.reference is not None:
            was_success = self.compare(results, self.reference)
        return was_success

    def start(self):
        """!
        Starts benchmarking
        """
        was_success = True
        # TODO: Put the commit name/number into the output file name
        if self.commits is not None and len(self.commits) > 0:
            self.clone_repo(self.repo_path)
            for c in self.commits:
                self.checkout(c, self.repo_path)
                self.build(self.repo_path)
                # Set p4c path to the newly build repo
                self.p4c_path = Path(self.repo_path) / Path("build/p4c/p4c")
                # Run benchmarks and save if one of them failed
                if not self.run_benchmarks():
                    was_success = False
        else:
            was_success = self.run_benchmarks()

        return was_success

if __name__ == "__main__":
    benchmarks = Benchmarks(argparse.ArgumentParser(description="Runs P4C performance benchmarks."))
    was_success = benchmarks.start()
    sys.exit(0 if was_success else 1)
