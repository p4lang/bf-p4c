#
# PTF Test for the program case1892.p4
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

from vag1892.p4_pd_rpc.ttypes import *
from res_pd_rpc.ttypes import *

dev_id = 0

def InstallDefaultEntries(self):
    # Both tables (port_based_egress and vid_based_egress) are bypassed
    pass


def ClearDefaultEntries(self):
    pass
               
#############################################################################
# 
# Here go the tests
#
#############################################################################
class Test1(pd_base_tests.ThriftInterfaceDataPlane):
    """
    Port-based egress for port 0 is set to 4
    VID-based  egress is not set
    """
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ["vag1892"])

    def runTest(self):
        print "\n", self.__doc__
        self.sess_hdl = self.conn_mgr.client_init()
        self.dev_id   = dev_id
        self.dev_tgt  = DevTarget_t(self.dev_id, hex_to_i16(0xFFFF))

        vid = 5
        
        try:
            InstallDefaultEntries(self)
            entry = self.client.port_based_egress_table_add_with_set_port(
                self.sess_hdl, self.dev_tgt,
                vag1892_port_based_egress_match_spec_t(0),
                vag1892_set_port_action_spec_t(4))
            self.conn_mgr.complete_operations(self.sess_hdl)

            p = simple_udp_packet(dl_vlan_enable=True, vlan_vid=vid)
            print ("Injecting Packet with VID=%d in port 0" % (vid))
            send_packet(self, 0, str(p))
            print "Expecting Packet out on port 4"
            verify_packets(self, p, [4])

        finally:
            self.client.port_based_egress_table_delete(
                self.sess_hdl, self.dev_id, entry)
            ClearDefaultEntries(self)
            self.conn_mgr.complete_operations(self.sess_hdl)
            self.conn_mgr.client_cleanup(self.sess_hdl)

