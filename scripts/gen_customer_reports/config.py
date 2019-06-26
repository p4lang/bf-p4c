#!/usr/bin/python3

import os
import sys

CTEST_DRIVER_TIMEOUT = 18000

BF_P4C_PATH = os.path.abspath(os.path.dirname(__file__)).replace('/scripts/gen_customer_reports', '')
CTEST_PATH = os.path.join(BF_P4C_PATH, "build/p4c")
REF_OUTPUTS_DIR = os.path.join(os.path.abspath(os.path.dirname(__file__)), \
    'results')
REPORTS_DIR = os.path.join(os.path.abspath(os.path.dirname(__file__)), \
    'reports')
MNT_DIR = "/mnt"

TARGET = 'tofino' # Default
TEST_SUITE = 'kaloom' # Default
