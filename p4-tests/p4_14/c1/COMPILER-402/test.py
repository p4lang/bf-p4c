#
# PTF Test for the program case2318.p4
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

from case2318.p4_pd_rpc.ttypes import *
from res_pd_rpc.ttypes import *

dev_id = 0

def InstallDefaultEntries(self):
    self.client.t_set_default_action_do_stuff(self.sess_hdl, self.dev_tgt)

def ClearDefaultEntries(self):
    self.client.t_table_reset_default_entry(self.sess_hdl, self.dev_tgt)
               
#############################################################################
# 
# Here go the tests
#
#############################################################################
class Test1(pd_base_tests.ThriftInterfaceDataPlane):
    """
    Testing the functionality of 12-to-16-bit addition 
    """
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ["case2318"])

    def runTest(self):
        print "\n", self.__doc__
        self.sess_hdl = self.conn_mgr.client_init()
        self.dev_id   = dev_id
        self.dev_tgt  = DevTarget_t(self.dev_id, hex_to_i16(0xFFFF))

        try:
            InstallDefaultEntries(self)
            self.conn_mgr.complete_operations(self.sess_hdl)

            p_send = simple_eth_packet(pktlen=100, eth_type=0xABCD)
            p_recv = p_send
            p_recv[Ether].type=0x1040
            
            print "Sending L2 packet with EtherType 0xABCD into port 0"
            send_packet(self, 0, str(p_send))

            print "Expecting L2 packet with Ethertype 0x1040 on port 0"
            verify_packets(self, p_recv, [0])
            
        finally:
            ClearDefaultEntries(self)

