#
# PTF Test for the program
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

from eth_addr_cmp.p4_pd_rpc.ttypes import *
from res_pd_rpc.ttypes import *

dev_id = 0

def InstallDefaultEntries(self):

    self.client.addr_compare_success_set_default_action_addr_compare(
        self.sess_hdl, self.dev_tgt,
        eth_addr_cmp_addr_compare_action_spec_t(action_is_equal=1, action_port=1))

    self.client.addr_compare_failure_set_default_action_addr_compare(
        self.sess_hdl, self.dev_tgt,
        eth_addr_cmp_addr_compare_action_spec_t(action_is_equal=0, action_port=2))

def ClearDefaultEntries(self):

    self.client.addr_compare_success_table_reset_default_entry(self.sess_hdl, self.dev_tgt)
    self.client.addr_compare_failure_table_reset_default_entry(self.sess_hdl, self.dev_tgt)


class TestSuccess(pd_base_tests.ThriftInterfaceDataPlane):
    """
    Base class for testing eth_addr_cmp
    """

    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ["eth_addr_cmp"])
        self.srcAddr='00:1c:42:00:00:08'
        self.dstAddr='00:1c:42:00:00:09'
        self.inPort1=0
        self.inPort2=1
        self.outPort=1


    def runTest(self):
        print "\n", self.__doc__
        self.sess_hdl = self.conn_mgr.client_init()
        self.dev_id   = dev_id
        self.dev_tgt  = DevTarget_t(self.dev_id, hex_to_i16(0xFFFF))

        try:
            InstallDefaultEntries(self)

            #
            # The Test
            #
            p = simple_tcp_packet(eth_dst=self.dstAddr, eth_src=self.srcAddr)

            print ("Injecting Packet with SRC=%s in port %d" %
                   (self.srcAddr, self.inPort1))
            send_packet(self, self.inPort1, str(p))
            print "Expecting Packet out on port %d" % self.outPort
            verify_packets(self, p, [self.outPort])

            print ("Injecting Packet with src=%s in port %d" %
                   (self.srcAddr, self.inPort2))
            send_packet(self, self.inPort2, str(p))
            print "Expecting Packet out on Port %d" % self.outPort
            verify_packets(self, p, [self.outPort])

        finally:
            #
            # Clear Table addr_compare_success
            #
            # ClearDefaultEntries(self)
            self.conn_mgr.client_cleanup(self.sess_hdl)

class TestFailure(pd_base_tests.ThriftInterfaceDataPlane):
    """
    Base class for testing eth_addr_cmp
    """

    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ["eth_addr_cmp"])
        self.srcAddr='00:1c:42:00:00:08'
        self.dstAddr='00:1c:42:00:00:08'
        self.inPort1=0
        self.inPort2=1
        self.outPort=2


    def runTest(self):
        print "\n", self.__doc__
        self.sess_hdl = self.conn_mgr.client_init()
        self.dev_id   = dev_id
        self.dev_tgt  = DevTarget_t(self.dev_id, hex_to_i16(0xFFFF))

        try:
            InstallDefaultEntries(self)

            #
            # The Test
            #
            p = simple_tcp_packet(eth_dst=self.dstAddr, eth_src=self.srcAddr)

            print ("Injecting Packet with SRC=%s in port %d" %
                   (self.srcAddr, self.inPort1))
            send_packet(self, self.inPort1, str(p))
            print "Expecting Packet out on port %d" % self.outPort
            verify_packets(self, p, [self.outPort])

            print ("Injecting Packet with src=%s in port %d" %
                   (self.srcAddr, self.inPort2))
            send_packet(self, self.inPort2, str(p))
            print "Expecting Packet out on Port %d" % self.outPort
            verify_packets(self, p, [self.outPort])

        finally:
            #
            # Clear Table addr_compare_success
            #
            # ClearDefaultEntries(self)
            self.conn_mgr.client_cleanup(self.sess_hdl)
