#!/usr/bin/env python3
import sys
import os
SDE_INSTALL_PATH = ""
#SDE_INSTALL_PATH = os.environ['SDE_INSTALL'] # why not this?

##TEST_JSON_PATH = "/npb-dp/tst/cfg"  # being depreciated
#TEST_JSON_PATH = os.path.join(SDE_INSTALL_PATH, 'share/p4/targets/tofino2')
# Intel should use the test.json in the tarball deliverable as the
# conf file they pass to tofino model and switchd (via -c arg).
#TEST_JSON_PATH = "."

BF_P4C_PATH = os.path.abspath(os.path.dirname(__file__)).replace('/p4c/extensions/p4_tests/p4_16/customer/extreme/npb-master-ptf/tests','')
TEST_JSON_PATH = os.path.join(BF_P4C_PATH, "p4-tests/p4_16/customer/extreme/npb-master-ptf/tests")
