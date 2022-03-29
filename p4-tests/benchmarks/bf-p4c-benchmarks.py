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

# Version is needed to correctly compare and plot outputs.
# If any major change is done to the results, the version should change.
__version__ = "1.0.0"

def fatal_error(msg):
    """
    Prints error message and exits with 1
    :param msg Error message
    """
    print("ERROR: {}".format(msg), file=sys.stderr)
    exit(1)

class BenchmarkTest:
    """
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
        self.compiler_path = compiler_path
        self.dir_path = dir_path
        self.path = params["path"]
        self.args = params["args"]
        # Go though args and those starting with "./" change to path to this folder
        for i in range(len(self.args)):
            if len(self.args[i]) > 1 and self.args[i][0:2] == "./":
                self.args[i] = self.dir_path+self.args[i][1:]
        self.core_number = core_number

    def run(self):
        """
        Runs benchmark test
        """
        measure_script = self.dir_path+"/measure_process.sh"
        core_number = self.core_number
        p4c_args = " ".join(self.args)
        test_path = self.dir_path+"/"+self.path

        command = " ".join(["bash", measure_script, core_number, '"', self.compiler_path, p4c_args, 
                            test_path, "-o /tmp/.benchmark_output", '"'])
        result = subprocess.Popen([command],
                                  shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        result_stderr = result.communicate()[1].decode("utf-8")
        if result.returncode != 0:
            fatal_error("Command '{}' exited with {}!"
                        .format(command, result.returncode))
        time_str = BenchmarkTest.RE_TIME_MEASURED.search(result_stderr)
        # TODO: Handle error?
        time = float(time_str.groups()[0])
        return time

class Benchmarks:
    """
    Class handeling benchmarks
    """
    # Regex for extracting p4c version
    RE_P4C_VERSION = re.compile(r'p4c ([0-9]+\.[0-9]+\.[0-9]+) .*')
    RE_P4C_SHA = re.compile(r'p4c [0-9]+\.[0-9]+\.[0-9]+ \(SHA: (.*)\)')

    def __init__(self, arg_parser):
        """
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
        self.tests_dir = os.path.dirname(self.opts.tests_path)
        print(self.tests_dir)
        # Load tests from config into dict
        self.tests_config = self.load_json(self.opts.tests_path)
        self.reference = self.load_json(self.opts.ref_file) if self.opts.ref_file is not None else None

    def add_command_line_options(self):
        """
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
                                    help="File to which save the output results.",
                                    action="store", default=None, type=str,
                                    dest="output_path", required=False)

    def load_json(self, path):
        """
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
        """
        :return Dict with info about this platform (PC)
        """
        # Getting CPU model
        cpu_res = subprocess.Popen(["lscpu | grep 'Model name:.*'"],
                                    shell=True, stdout=subprocess.PIPE)
        cpu_res_stdou = cpu_res.communicate()[0].decode('utf-8')
        # Remove prefix from lscpu to get the cpu model
        cpu_model = re.sub(r'Model name:\s*', '', cpu_res_stdou)
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
        """
        :return Dict with info about used P4C compiler
        """
        p4c_res = subprocess.Popen(["{} --version".format(p4c_path)],
                                    shell=True, stdout=subprocess.PIPE)
        p4c_res_stdou = p4c_res.communicate()[0].decode('utf-8')
        p4c_version_match = Benchmarks.RE_P4C_VERSION.search(p4c_res_stdou)
        p4c_sha_match = Benchmarks.RE_P4C_SHA.search(p4c_res_stdou)
        return {
            "version": p4c_version_match.groups()[0],
            "sha": p4c_sha_match.groups()[0]
        }

    def compare(self, results, reference):
        """
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
                      "If this slow down is unavoidable, then change the reference compile time in "
                      "'benchmark-references.json' file to {}.".format(name, threshold, c_time_now))
            diff_abs = round(abs(diff), 1)
            # leave small difference as equality
            if diff > -0.9 and diff < 0.9:
                print("NO CHANGE: '{}' has no change in compile time.".format(name))
            elif diff < 0.0:
                print("SPEED UP: '{}' was sped up by {} % (from {} s to {} s)."
                      .format(name, diff_abs, c_time_master, c_time_now))
            else:
                print("SLOW DOWN: '{}' was slowed down by {} % (from {} s to {}s)."
                      .format(name, diff_abs, c_time_master, c_time_now))
        return in_thr


    def save_results(self, results, output_path=None):
        """
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
        """
        Runs P4C benchmark pipeline
        :return True if benchmark results are within set compare threshold or 
                no compare file was set. False otherwise.
        """
        was_success = True
        tests = []
        for test, params in self.tests_config.items():
            tests.append(BenchmarkTest(test, params, self.p4c_path, self.tests_dir, self.core_number))

        results = {}
        for c, test in enumerate(tests):
            print("[{}/{}] RUNNING {}".format(c+1, len(tests), test.name), file=sys.stderr)
            results[test.name] = {"compile_time": test.run(),
                                  "path": test.path,
                                  "p4c_args": test.args}
            print("[{}/{}] FINISHED {}".format(c+1, len(tests), test.name), file=sys.stderr)
        # Save results to the output file
        self.save_results(results, self.output_path)
        # Compare results with reference values
        if self.reference is not None:
            was_success = self.compare(results, self.reference)
        return was_success

if __name__ == "__main__":
    benchmarks = Benchmarks(argparse.ArgumentParser(description="Runs P4C performance benchmarks."))
    was_success = benchmarks.run_benchmarks()
    sys.exit(0 if was_success else 1)
