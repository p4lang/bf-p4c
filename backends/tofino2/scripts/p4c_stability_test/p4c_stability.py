#!/usr/bin/env python3

import os
import glob
import shlex
import subprocess
import pdb
import pprint
import traceback
import sys
import shutil
from datetime import datetime

import p4c_stability_matrix

# This python script performs the stability test based on the issue in:
# * https://jira.devtools.intel.com/browse/P4C-3168

# Global variables
## Path to the stability test folder
P4C_STABILITY_TEST_PATH = os.path.dirname(os.path.realpath(__file__))
## Relative path to the project root
BF_P4C_REL_PATH = os.path.join(P4C_STABILITY_TEST_PATH, "../..")
## Absolute path to the project root
BF_P4C_PATH = os.path.abspath(BF_P4C_REL_PATH)
## Path to the folder with tests
BF_P4C_TEST_PATH = os.path.join(BF_P4C_PATH,"p4-tests")
## P4C driver tool path
TEST_DRIVER_PATH = os.path.join(BF_P4C_PATH, "scripts/test_p4c_driver.py")
## Path to generated python file with matrix
TEST_MATRIX_FILE=os.path.abspath(
    os.path.join(P4C_STABILITY_TEST_PATH,"stability_test_matrix.py"))
## Compiler stuff - path and includes
P4C_PATH = os.path.join(BF_P4C_PATH, "build", "p4c", "bf-p4c")
P4C_INCLUDE_PATH = os.path.join(BF_P4C_PATH,"build","p4c","p4include")
## Number of parallel translations
JOBS = 4
## Output log files
STABILITY_LOG = os.path.join(P4C_STABILITY_TEST_PATH,"stability_test.log")

def check_bfa_files(test_matrix):
    """
    Iterate over folders and check output BFA files. The function throws exception
    iff output BFA files differs.

    Parameters:
        - test_matrix - generated test dictionary
    """
    def __canonize_bfa(path):
        """
        Canonize the BFA file content.

        Parameters:
            - path - path of the analyzed file

        Return: Canonized string from the passed file
        """
        # Currently, the string canonization contains following
        # (the reason is that these parts are changing between runs
        # and they are generated based on the output directory or their value is based
        # on the date):
        # - the run_id line is being removed
        # - the primitives line is being removed
        # - the dynhash line is not removed
        filtered_parts = ["run_id", "primitives", "dynhash"]
        ret = None
        with open(path, "r") as f:
            ret = list(f.readlines())
            for filter_out in filtered_parts:
                ret = list(filter(lambda x : not x.lstrip().startswith(filter_out), ret))

        return ''.join(ret)

    def __check_bfa_folder(src1, src2):
        """
        Open folder, iterate over pipelines and check bfa files.
        The function throws exception in a case of any error.
        """
        # Iterate over all folders inside the src1 and check if the
        # bfa file exists --> this is a pipe folder. After that, take the
        # src2 folder and check that the BFA file is also here. If not, end up with
        # error. If yes, canonize both inputs and performs the check.
        for entry in os.scandir(src1):
            if not entry.is_dir():
                continue

            search_path = os.path.join(entry.path,"*.bfa")
            bfa1_files = list(glob.iglob(search_path))
            if len(bfa1_files) == 0:
                continue

            for bfa1_path in bfa1_files:
                # Check the second folder for the presence of the second folder
                bfa2_path = bfa1_path.replace(src1, src2)
                if not os.path.exists(bfa2_path):
                    raise RuntimeError(
                        "Cannot check bfa files, the {} file doesn't exist!".format(bfa2_path))

                # Now, we can check both files
                print("Checking BFA files: {} and {}".format(bfa1_path, bfa2_path))
                src1_bfa = __canonize_bfa(bfa1_path)
                src2_bfa = __canonize_bfa(bfa2_path)

                if src1_bfa != src2_bfa:
                    raise RuntimeError(
                        "Files {} and {} are not the same!".format(src1_bfa, src2_bfa))

    # check_bfa_files body ################################
    src_dir = None
    for test, exp_tests in test_matrix.items():
        print("Checking results for {} ...".format(test))

        for dst_dir in exp_tests:
            # The first element is taken as the source directory and it is
            # being checked with another ones
            if src_dir is None:
                src_dir = dst_dir
                continue

            # Open the source folder and interate over pipe folders, the pipe
            # folder contains a BFA file. If we find such a file, we can take the
            # destination folder and use the same relative path.
            __check_bfa_folder(src_dir, dst_dir)

def cleanup_generated_folders(test_matrix):
    """
    Take the test matrix and clean all generated files.
    """
    for test_name, tests in test_matrix.items():
        print("Removing generated files for {} ...".format(test_name))
        for test in tests:
            shutil.rmtree(test)


def get_expanded_line(test_line):
    """
    Expand the line. This function returns the dictionary of tests which needs to be
    added into total dictionary list
    """
    ret_dic = {}

    test_name = os.path.join(P4C_STABILITY_TEST_PATH, test_line[0])
    p4_path = os.path.join(BF_P4C_TEST_PATH, test_line[2])
    for i in range(0, test_line[1]):
        key_name = "{}_{}".format(test_name, i)
        cmd_params = test_line[3] + ["-o", key_name,
            "-I",P4C_INCLUDE_PATH,
            p4_path]

        dic_line = (
            cmd_params,     # Compiler options
            test_line[4],   # xfail message
            test_line[5]    # file list to check
        )
        ret_dic[key_name] = dic_line 

    return ret_dic

def write_matrix():
    """
    Expand the test matrix from provided test configuration. The output
    is dumped to a file and also returned from this function.

    Return: Expanded dictionary with test cases, key is the test name
    and value is the dictionary with expanded tests.
    """
    # Genearate a unique file name and 
    print("Generating the test matrix to file: {}".format(TEST_MATRIX_FILE))

    # Prepare test matrix dictionary
    test_matrix = {}
    ret_matrix  = {}
    for line in p4c_stability_matrix.TEST_LIST:
        tmp_dic = get_expanded_line(line)
        test_matrix.update(tmp_dic)
        # Append the test to non-flattened structure
        ret_matrix[line[0]] = tmp_dic
    
    # Dump a pretty printed dictionary into the output file
    with open(TEST_MATRIX_FILE, 'w') as fmatrix:
        pp = pprint.PrettyPrinter(indent=4)
        now = datetime.now()
        str_date = now.strftime("%m/%d/%Y, %H:%M:%S")
        matrix_to_write  = "# !!!AUTOGENERATED FILE - {}!!!\n\n".format(str_date)
        ppmatrix = pp.pformat(test_matrix)
        matrix_to_write += "test_matrix = {}".format(ppmatrix)
        fmatrix.write(matrix_to_write)

    return ret_matrix
        
def run_translation():
    # Prepare the command for the test_p4c_driver.py and run all tests
    # defined in the generated python file
    cmd = [TEST_DRIVER_PATH,
        "--verbose",
        "--testfile", TEST_MATRIX_FILE,
        "--print-on-failure",
        "--keep-output",
        "--jobs",str(JOBS),
        "--compiler", P4C_PATH,
        " >{} 2>&1".format(STABILITY_LOG)
    ]

    print("Starting the test job ...")
    print("Logging into the file: {}".format(STABILITY_LOG))
    try:
        cmd_concat = ' '.join(cmd)
        #print(cmd_concat)
        p = subprocess.Popen(cmd_concat, shell=True)
        p.wait()
        ret_code = p.returncode
        if ret_code != 0:
            print("Return code: {}".format(ret_code))
            sys.exit(ret_code)
    except:
        print("error invoking {}".format(cmd),file=sys.stderr)
        print(traceback.format_exc(), file=sys.stderr)
        sys.exit(1)

def run_test():
    try:
        test_matrix = write_matrix()
        run_translation()
        check_bfa_files(test_matrix)
        cleanup_generated_folders(test_matrix)
        print("All tests were finished - everything seems fine!")
    except:
        print(traceback.format_exc(), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    run_test()
    sys.exit(0)
