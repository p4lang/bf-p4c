#
# PTF Test for the exclusive_cf_multiple_actions.p4
#
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

from exclusive_cf_multiple_actions.p4_pd_rpc.ttypes import *
from res_pd_rpc.ttypes import *

class TestAll(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ["exclusive_cf_multiple_actions"])
        self.forward_entries = []

    def InstallDefaultEntries(self):

        self.client.t0_set_default_action_branch(self.sess_hdl, self.dev_tgt)
        self.client.t1_set_default_action_a1(self.sess_hdl, self.dev_tgt)
        self.client.t2_set_default_action_forward(self.sess_hdl, self.dev_tgt)
        self.client.t3_set_default_action_forward(self.sess_hdl, self.dev_tgt)
        self.client.t4_set_default_action_forward(self.sess_hdl, self.dev_tgt)
        self.client.t5_set_default_action_forward(self.sess_hdl, self.dev_tgt)

        self.addrs = ['00:1c:42:00:00:07', '00:1c:42:00:00:08', \
                      '00:1c:42:00:00:01', '00:1c:42:00:00:02', \
                      '00:1c:42:00:00:03', '00:1c:42:00:00:10']
        self.forward_entries.append(
            self.client.t1_table_add_with_a1(self.sess_hdl, self.dev_tgt,
                 exclusive_cf_multiple_actions_t1_match_spec_t(macAddr_to_string(self.addrs[0]))))
        self.forward_entries.append(
            self.client.t1_table_add_with_a1(self.sess_hdl, self.dev_tgt,
                 exclusive_cf_multiple_actions_t1_match_spec_t(macAddr_to_string(self.addrs[5]))))
        self.forward_entries.append(
            self.client.t1_table_add_with_a2(self.sess_hdl, self.dev_tgt,
                 exclusive_cf_multiple_actions_t1_match_spec_t(macAddr_to_string(self.addrs[1]))))
        self.forward_entries.append(
            self.client.t1_table_add_with_a3(self.sess_hdl, self.dev_tgt,
                 exclusive_cf_multiple_actions_t1_match_spec_t(macAddr_to_string(self.addrs[2]))))
        self.forward_entries.append(
            self.client.t1_table_add_with_a4(self.sess_hdl, self.dev_tgt,
                 exclusive_cf_multiple_actions_t1_match_spec_t(macAddr_to_string(self.addrs[3]))))
        self.forward_entries.append(
            self.client.t1_table_add_with_a5(self.sess_hdl, self.dev_tgt,
                 exclusive_cf_multiple_actions_t1_match_spec_t(macAddr_to_string(self.addrs[4]))))


    def ClearEntries(self):
        for entry in self.forward_entries:
            self.client.t1_table_delete(self.sess_hdl, self.dev_id, entry)
        self.forward_entries = []


    def runTest(self):
        print "\n", self.__doc__
        self.sess_hdl = self.conn_mgr.client_init()
        self.dev_id   = 0
        self.dev_tgt  = DevTarget_t(self.dev_id, hex_to_i16(0xFFFF))

        try:
            self.InstallDefaultEntries()

            expectedPort = 1
            for a in self.addrs:
                p = simple_tcp_packet(eth_dst=a)

                print ("Injecting Packet with dst=%s in port %d" % (a, 1))
                send_packet(self, 1, str(p))
                print "Expecting Packet out on port %d" % expectedPort
                verify_packets(self, p, [expectedPort])
                expectedPort = (expectedPort + 1) % 6


        finally:
            self.ClearEntries()
            self.conn_mgr.client_cleanup(self.sess_hdl)
