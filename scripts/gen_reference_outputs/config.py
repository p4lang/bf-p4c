#! /usr/bin/env python3

import os
import sys
from prettytable import PrettyTable

TEST_DRIVER_TIMEOUT = 90 * 60

BF_P4C_PATH = os.path.abspath(os.path.dirname(__file__)).replace('/scripts/gen_reference_outputs', '')

P4C = os.path.join(BF_P4C_PATH, "build/p4c/p4c")
P4C_ARGS = ['"-g"', '"--validate-output"', '"--create-graphs"', '"--verbose 1"', '\"-Xp4c=\'--enable-event-logger\'\"']

GLASS = "/usr/local/bin/p4c-tofino"
GLASS_ARGS = ['"-g"', '" -j 16"', '"--create-graphs dot"']

TEST_FILE = 'tests.csv'
P4C_TEST_MATRIX = 'test_matrix_P4C.py'
GLASS_TEST_MATRIX = 'test_matrix_Glass.py'

TEST_DRIVER_PATH = os.path.join(BF_P4C_PATH, "scripts/test_p4c_driver.py")
P4C_TEST_CMD = TEST_DRIVER_PATH + " -j 4 --print-on-failure --compiler " + \
    P4C + " --keep-output --testfile " + P4C_TEST_MATRIX
GLASS_TEST_CMD = TEST_DRIVER_PATH + " -j 4 --print-on-failure --compiler " + \
    GLASS + " --keep-output --testfile " + GLASS_TEST_MATRIX

REF_OUTPUTS_DIR = os.path.join(os.path.abspath(os.path.dirname(__file__)), \
    'results')
METRICS_DIR = os.path.join(os.path.abspath(os.path.dirname(__file__)), \
    'metrics')
METRICS_DB = os.path.join(os.path.abspath(os.path.dirname(__file__)), \
    'database/compiler_metrics.sqlite')

COMMIT_SHA = None

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
        self.p4 = ''
        self.p4_path = ''
        self.include_path = ''
        self.p4_opts = ''
        self.target = 'tofino'
        self.std = 'p4-14'
        self.arch = 'v1model'
        self.out_path = ''
        self.timestamp = ''
