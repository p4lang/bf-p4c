#! /usr/bin/env python

import os
import sys

P4C_TIMEOUT = 120
TEST_DRIVER_TIMEOUT = 1000

P4C = "/bfn/bf-p4c-compilers/build/p4c/p4c"
P4C_ARGS = ['"-g"', '"--validate-output"', '"--std"', '"p4-14"', '"--target"', \
    '"tofino"', '"--arch"', '"v1model"']

GLASS = "/usr/local/bin/p4c-tofino"
GLASS_ARGS = ['"-g"', '" -j 16"']

TEST_FILE = 'tests.csv'
P4C_TEST_MATRIX = 'test_matrix_P4C.py'
GLASS_TEST_MATRIX = 'test_matrix_Glass.py'

TEST_DRIVER_PATH = "/bfn/bf-p4c-compilers/scripts/test_p4c_driver.py"
P4C_TEST_CMD = TEST_DRIVER_PATH + " -j 16 --print-on-failure --compiler " + \
    P4C + " --keep-output --testfile " + P4C_TEST_MATRIX
GLASS_TEST_CMD = TEST_DRIVER_PATH + " -j 16 --print-on-failure --compiler " + \
    GLASS + " --keep-output --testfile " + GLASS_TEST_MATRIX

REF_OUTPUTS_DIR = os.path.join(os.path.abspath(os.path.dirname(__file__)), \
    'results')

class Compiler(object):
    def __init__(self):
        self.name = ''
        self.path = ''
        self.args = ''
        self.testmatrix = ''

class P4C(Compiler):
    def __init__(self):
        self.name = 'P4C'
        self.path = P4C
        self.args = P4C_ARGS
        self.testmatrix = '# P4C Test matrix\n' + \
            '# Auto generated\n\ntest_matrix = {\n'

class Glass(Compiler):
    def __init__(self):
        self.name = 'Glass'
        self.path = GLASS
        self.args = GLASS_ARGS
        self.testmatrix = '# Glass Test matrix\n' + \
            '# Auto generated\n\ntest_matrix = {\n'

class Test(object):
    def __init__(self):
        self.name = ''
        self.path = ''
        self.outpath = ''
        self.opts = ''
        self.timeout = P4C_TIMEOUT