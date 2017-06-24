#
# PTF Test for the program case1832.p4
#
"""
Thrift PD interface basic tests
"""

from collections import OrderedDict

import time
import sys
import logging

import unittest
import random

import pd_base_tests

from ptf import config
from ptf.testutils import *
from ptf.thriftutils import *

import os

from case1832.p4_pd_rpc.ttypes import *
from res_pd_rpc.ttypes import *

dev_id = 0

def InstallDefaultEntries(self):
    self.client.Okarche_set_default_action_Roseau(self.sess_hdl, self.dev_tgt)

def ClearDefaultEntries(self):
    self.client.Okarche_table_reset_default_entry(self.sess_hdl, self.dev_tgt)
               
#############################################################################
# 
# Here go the tests
#
#############################################################################
class Test1(pd_base_tests.ThriftInterfaceDataPlane):
    """
    Testing the functionality of Default Action Installation
    """
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ["case1832"])

    def runTest(self):
        print "\n", self.__doc__
        self.sess_hdl = self.conn_mgr.client_init()
        self.dev_id   = dev_id
        self.dev_tgt  = DevTarget_t(self.dev_id, hex_to_i16(0xFFFF))

        try:
            InstallDefaultEntries(self)
            self.conn_mgr.complete_operations(self.sess_hdl)

            self.assertEqual(1, 1)

        finally:
            ClearDefaultEntries(self)
            self.conn_mgr.complete_operations(self.sess_hdl)
            self.conn_mgr.client_cleanup(self.sess_hdl)

