################################################################################
# BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
#
# Copyright (c) 2018-2019 Barefoot Networks, Inc.

# All Rights Reserved.
#
# NOTICE: All information contained herein is, and remains the property of
# Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
# technical concepts contained herein are proprietary to Barefoot Networks,
# Inc.
# and its suppliers and may be covered by U.S. and Foreign Patents, patents in
# process, and are protected by trade secret or copyright law.
# Dissemination of this information or reproduction of this material is
# strictly forbidden unless prior written permission is obtained from
# Barefoot Networks, Inc.
#
# No warranty, explicit or implicit is provided, unless granted under a
# written agreement with Barefoot Networks, Inc.
#
#
###############################################################################


"""
PTF foundational class for p4c2611.p4

This module contains the P4ProgramTest class specifically taylored for 
simple_l3 program (eventually this tayloring will go away).

All individual tests are subclassed from the this base (P4ProgramTest) or 
its ssubclasses if necessary.

The easiest way to write a test for simple_l3 is to start with a line

from simple_l3 import *
"""


######### STANDARD MODULE IMPORTS ########
import unittest
import logging 
import grpc   
import pdb

######### PTF modules for BFRuntime Client Library APIs #######
import ptf
from ptf.testutils import *
from bfruntime_client_base_tests import BfRuntimeTest
import bfrt_grpc.bfruntime_pb2 as bfruntime_pb2
import bfrt_grpc.client as gc

########## Basic Initialization ############
class P4ProgramTest(BfRuntimeTest):
    # The setUp() method is used to prepare the test fixture. Typically
    # you would use it to establich connection to the gRPC Server
    #
    # You can also put the initial device configuration there. However,
    # if during this process an error is encountered, it will be considered
    # as a test error (meaning the test is incorrect),
    # rather than a test failure
    #
    # Here is the stuff we set up that is ready to use
    #  client_id
    #  p4_name
    #  bfrt_info
    #  dev
    #  dev_tgt
    #  allports
    #  tables    -- the list of tables
    #     Individual tables of the program with short names
    #     ipv4_host
    #     ipv4_lpm
    def setUp(self):
        self.client_id = 0
        self.p4_name = "p4c2611"     # Specialization
        self.dev      = 0
        self.dev_tgt  = gc.Target(self.dev, pipe_id=0xFFFF)
        
        print("\n")
        print("Test Setup")
        print("==========")

        BfRuntimeTest.setUp(self, self.client_id, self.p4_name)
        
        # This is the simple case when you run only one program on the target.
        # Otherwise, you might have to retrieve multiple bfrt_info objects and
        # in that case you will need to specify program name as a parameter
        self.bfrt_info = self.interface.bfrt_info_get()
        
        print("    Connected to Device: {}, Program: {}, ClientId: {}".format(
            self.dev, self.p4_name, self.client_id))

        # Create a list of all ports available on the device
        self.swports = []
        for (device, port, ifname) in ptf.config['interfaces']:
            self.swports.append(port)
        self.swports.sort()

        # Since this class is not a test per se, we can use the setup method
        # for common setup. For example, we can have our tables and annotations
        # ready

        # Program-specific customization
        self.ipv6_imm = self.bfrt_info.table_get("Ingress.ipv6_imm")
        self.ipv6_imm.info.key_field_annotation_add("dst_addr", "ipv6")

        self.ipv6_nonimm = self.bfrt_info.table_get("Ingress.ipv6_nonimm")
        self.ipv6_nonimm.info.key_field_annotation_add("dst_addr", "ipv6")

        self.tables = [ self.ipv6_imm, self.ipv6_nonimm]

        # Optional, but highly recommended
        # self.cleanUp()

    # Use tearDown() method to return the DUT to the initial state by cleaning
    # all the configuration and clearing up the connection
    def tearDown(self):
        print("\n")
        print("Test TearDown:")
        print("==============")

        self.cleanUp()
        
        # Call the Parent tearDown
        BfRuntimeTest.tearDown(self)

    # Use Cleanup Method to clear the tables before and after the test starts
    # (the latter is done as a part of tearDown()
    def cleanUp(self):
        print("\n")
        print("Table Cleanup:")
        print("==============")

        try:
            for t in self.tables:
                print("  Clearing Table {}".format(t.info.name_get()))
                try:
                    t.clear()
                except:
                    keys = []
                    for (d, k) in t.entry_get(self.dev_tgt):
                        if k is not None:
                            keys.append(k)
                    t.entry_del(self.dev_tgt, keys)
                    # Not all tables support default entry
                    try:
                        t.default_entry_reset(self.dev_tgt)
                    except:
                        pass
        except Exception as e:
            print("Error cleaning up: {}".format(e))

    #
    # This is a simple helper method that takes a list of entries and programs
    # them in a specified table
    #
    # Each entry is a tuple, consisting of 3 elements:
    #  key         -- a list of tuples for each element of the key
    #  action_name -- the action to use. Must use full name of the action
    #  data        -- a list (may be empty) of the tuples for each action
    #                 parameter
    #
    def programTable(self, table, entries, target=None):
        if target is None:
            target = self.dev_tgt

        key_list=[]
        data_list=[]
        for k, a, d in entries:
            key_list.append(table.make_key([gc.KeyTuple(*f)   for f in k]))
            data_list.append(table.make_data([gc.DataTuple(*p) for p in d], a))
        table.entry_add(target, key_list, data_list)

#
# Individual tests can now be subclassed from P4ProgramTest
#
class Force_Immediate(P4ProgramTest):

    def runTest(self):
        ingress_port = test_param_get("ingress_port",  0)
        ipv6_dst1    = test_param_get("ipv6_dst1",     "2001:0db8:abcd:0012::0")
        egress_port1 = test_param_get("egress_port1",   2)
        ipv6_dst2    = test_param_get("ipv6_dst2",     "2001:0db8:abcd:0013::0")
        egress_port2 = test_param_get("egress_port2",   3)
        
        #
        # Program 2 entries in ipv6_imm
        #
        self.programTable(self.ipv6_imm, [
            # Entry 1
            ([("ether_type", 0x86DD),
              ("dst_addr", ipv6_dst1)],
             "Ingress.send", [("port", egress_port1)]),
            # Entry 2
            ([("ether_type", 0x86DD),
              ("dst_addr", ipv6_dst2)],
             "Ingress.send", [("port", egress_port2)]) 
        ])

        # Prepare test packets
        pkt = Ether()/IPv6(dst=ipv6_dst1)/UDP()/"Payload"
        
        print("Sending packet with IPv6 DST {} into port {}".format(
            ipv6_dst1, ingress_port))
        send_packet(self, ingress_port, pkt)

        print("Expecting the packet to be forwarded to port {}".format(
            egress_port1))
        verify_packet(self, pkt, egress_port1)
        print("Packet received of port %d" % egress_port1)

        #######################################

        pkt = Ether()/IPv6(dst=ipv6_dst2)/UDP()/"Payload"

        print("Sending packet with IPv6 DST {} into port {}".format(
            ipv6_dst2, ingress_port))
        send_packet(self, ingress_port, pkt)

        print("Expecting the packet to be forwarded to port {}".format(
            egress_port2))
        verify_packet(self, pkt, egress_port2)
        print("Packet received of port %d" % egress_port2)

class Force_Non_Immediate(P4ProgramTest):

    def runTest(self):
        ingress_port = test_param_get("ingress_port",  0)
        ipv6_dst1    = test_param_get("ipv6_dst1",     "2001:0db8:abcd:0014::0")
        egress_port1 = test_param_get("egress_port1",   4)
        ipv6_dst2    = test_param_get("ipv6_dst2",     "2001:0db8:abcd:0015::0")
        egress_port2 = test_param_get("egress_port2",   5)

        #
        # Program 2 entries in ipv6_nonimm
        #
        self.programTable(self.ipv6_nonimm, [
            # Entry 1
            ([("ether_type", 0x86DD),
              ("dst_addr", ipv6_dst1)],
             "Ingress.send", [("port", egress_port1)]),
            # Entry 2
            ([("ether_type", 0x86DD),
              ("dst_addr", ipv6_dst2)],
             "Ingress.send", [("port", egress_port2)])
        ])

        # Prepare test packets
        pkt = Ether()/IPv6(dst=ipv6_dst1)/UDP()/"Payload"

        print("Sending packet with IPv6 DST {} into port {}".format(
            ipv6_dst1, ingress_port))
        send_packet(self, ingress_port, pkt)

        print("Expecting the packet to be forwarded to port {}".format(
            egress_port1))
        verify_packet(self, pkt, egress_port1)
        print("Packet received of port %d" % egress_port1)

        #######################################

        pkt = Ether()/IPv6(dst=ipv6_dst2)/UDP()/"Payload"

        print("Sending packet with IPv6 DST {} into port {}".format(
            ipv6_dst2, ingress_port))
        send_packet(self, ingress_port, pkt)

        print("Expecting the packet to be forwarded to port {}".format(
            egress_port2))
        verify_packet(self, pkt, egress_port2)
        print("Packet received of port %d" % egress_port2)