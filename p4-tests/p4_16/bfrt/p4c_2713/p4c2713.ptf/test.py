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
PTF foundational class for p4c2713.p4

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
    def setUp(self):
        self.client_id = 0
        self.p4_name = "p4c2713"     # Specialization
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

    # Use tearDown() method to return the DUT to the initial state by cleaning
    # all the configuration and clearing up the connection
    def tearDown(self):
        print("\n")
        print("Test TearDown:")
        print("==============")
        
        # Call the Parent tearDown
        BfRuntimeTest.tearDown(self)

def gen_udp_packet():
    pkt=Ether(dst="00:90:fb:5c:cb:4b", src="ec:0d:9a:6d:e0:29")/IP(src="192.168.100.100", dst="192.168.1.1")/UDP(dport=0x1111, sport=0x2222)/"this is the payload"
    #pkt[UDP].sport= randint(100, 60000)
    #pkt[UDP].dport= randint(300, 60000)
    pkt[UDP].sport= 100
    pkt[UDP].dport= 300
    return pkt

#
# Individual tests can now be subclassed from P4ProgramTest
#
class SimpleTest(P4ProgramTest):

    def runTest(self):
        # Prepare test packets
        pkt = gen_udp_packet()
        
        send_packet(self, 0, pkt)

        verify_packet(self, pkt, 1)
        print("Packet received of port %d" % 1)
