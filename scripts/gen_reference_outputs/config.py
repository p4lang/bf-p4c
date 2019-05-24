#! /usr/bin/env python

import os
import sys
from prettytable import PrettyTable

TEST_DRIVER_TIMEOUT = 1000

BF_P4C_PATH = os.path.abspath(os.path.dirname(__file__)).replace('/scripts/gen_reference_outputs', '')

P4C = os.path.join(BF_P4C_PATH, "build/p4c/p4c")
P4C_ARGS = ['"-g"', '"--validate-output"', '"--create-graphs"', '"--verbose 1"']

GLASS = "/usr/local/bin/p4c-tofino"
GLASS_ARGS = ['"-g"', '" -j 16"', '"--create-graphs dot"']

TEST_FILE = 'tests.csv'
P4C_TEST_MATRIX = 'test_matrix_P4C.py'
GLASS_TEST_MATRIX = 'test_matrix_Glass.py'

TEST_DRIVER_PATH = os.path.join(BF_P4C_PATH, "scripts/test_p4c_driver.py")
P4C_TEST_CMD = TEST_DRIVER_PATH + " -j 16 --print-on-failure --compiler " + \
    P4C + " --keep-output --testfile " + P4C_TEST_MATRIX
GLASS_TEST_CMD = TEST_DRIVER_PATH + " -j 16 --print-on-failure --compiler " + \
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
        self.skip_opt = '' # choices: '', skip_Glass, skip_P4C, skip_Glass_P4C
        self.out_path = ''
        self.timestamp = ''

class Metric():
    def __init__(self):
        self.normal_phv_bits_occupied = None
        self.normal_phv_containers_occupied = None
        self.tagalong_phv_bits_occupied = None
        self.tagalong_phv_containers_occupied = None
        self.mau_srams = None
        self.mau_tcams = None
        self.mau_logical_tables = None
        self.parser_ingress_tcam_rows = None
        self.parser_egress_tcam_rows = None

    def display(self):
        dt = PrettyTable(['Metric', 'Value'])
        dt.add_row(['Normal PHV bits_occupied', self.normal_phv_bits_occupied])
        dt.add_row(['Normal PHV containers_occupied', self.normal_phv_containers_occupied])
        dt.add_row(['Tagalong PHV bits_occupied', self.tagalong_phv_bits_occupied])
        dt.add_row(['Tagalong PHV containers_occupied', self.tagalong_phv_containers_occupied])
        dt.add_row(['MAU srams', self.mau_srams])
        dt.add_row(['MAU tcams', self.mau_tcams])
        dt.add_row(['MAU logical_tables', self.mau_logical_tables])
        dt.add_row(['Parser ingress tcam rows', self.parser_ingress_tcam_rows])
        dt.add_row(['Parser egress tcam rows', self.parser_egress_tcam_rows])
        print dt

limits = Metric()
limits.normal_phv_bits_occupied = 40
limits.normal_phv_containers_occupied = 2
limits.tagalong_phv_bits_occupied = 20
limits.tagalong_phv_containers_occupied = 1
limits.mau_srams = 10.0 # percentage
limits.mau_tcams = 10.0 # percentage
limits.mau_logical_tables = 10.0 # percentage
limits.parser_ingress_tcam_rows = 10.0 # percentage
limits.parser_egress_tcam_rows = 10.0 # percentage
