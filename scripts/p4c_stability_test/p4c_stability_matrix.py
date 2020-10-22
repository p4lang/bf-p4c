#!/usr/bin/env python3

# The stability matrix has following structure:
# [NAME, REPEATS, P4_PATH, COMPILER_OPTIONS, XFAIL MESSAGE, FILE LIST]
# This is expanded later to the form accepted by the compiler.
#
# The rest of all parameters:
# * NAME - name of the test
# * REPEATS - number of repeated translations
# * P4_PATH - path to the p4 file, relative from the ../../p4tests
# * COMPILER_OPTIONS - options for the bf-p4c, list of parameters and its values
# * XFAIL MESSAGE - xfail message, can be None
# * FILE LIST - list of additional files to check, can be None
#
# The unique name accepted by the test_p4c_driver.py has the following form:
#  NAME_X, where X is the number of generated test.


# FILL THE TEST HERE IF YOU WANT TO RUN IT
TEST_LIST = [
    ["unstable_test_p4c-3168", 20,
    "p4_16/stable-test/p4c-3168.p4", ["-g","--std","p4-16","--arch","tna","--target","tofino"],
    None, None]
]
