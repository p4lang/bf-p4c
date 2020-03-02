################################################################################
# BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
#
# Copyright (c) 2018-2019 Barefoot Networks, Inc.
#
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
# Milad Sharif (msharif@barefootnetworks.com)
#
###############################################################################

import logging
import sys
import os
import random
import re
from pprint import pprint

from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils
from bfruntime_base_tests import BfRuntimeTest
#import bfrt_grpc.bfruntime_pb2 as bfruntime_pb2

logger = logging.getLogger('Test')
if logger.handlers:
    logger.handlers = []
logger.addHandler(logging.StreamHandler())

#############################################

swports = []
for device, port, ifname in config["interfaces"]:
    swports.append(port)
    swports.sort()

if swports == []:
    swports = range(9)

def port_to_pipe(port):
    local_port = port & 0x7F
    assert(local_port < 72)
    pipe = (port >> 7) & 0x3
    assert(port == ((pipe << 7) | local_port))
    return pipe

swports_0 = []
swports_1 = []
swports_2 = []
swports_3 = []
# the following method categorizes the ports in ports.json file as belonging to either of the pipes (0, 1, 2, 3)
for port in swports:
    pipe = port_to_pipe(port)
    if pipe == 0:
        swports_0.append(port)
    elif pipe == 1:
        swports_1.append(port)
    elif pipe == 2:
        swports_2.append(port)
    elif pipe == 3:
        swports_3.append(port)

        
################################################################################
################################################################################
################################################################################
################################################################################
class VxlanFailure(BfRuntimeTest):

    TARGET = { 'device_id': 0,
               'pipe_id': 0xffff }

    # --------------------------------------------------------------------------
    def setUp(self):
        client_id = 0
        p4_name = "npb"
        BfRuntimeTest.setUp(self, client_id, p4_name)

    # --------------------------------------------------------------------------        
    def runTest(self):        

        ig_port = swports[0]
        target = self.Target(device_id=0, pipe_id=0xffff)

        # Get bfrt_info and set it as part of the test
        self.set_bfrt_info(self.parse_bfrt_info(self.get_bfrt_info("npb")))   

        logger.info("Begin parser test: VxlanFailure\n")

        pkts = rdpcap("%s" %('/bfn/bf-p4c-compilers/p4c/extensions/p4_tests/p4_16/bfrt/p4c_2527/pkts_inner_VxlanFailure.pcap'))

        for pkt in pkts:
         
            # Send packet(s)
            testutils.send_packet(self, ig_port, str(pkt))        
            time.sleep(2)


################################################################################
################################################################################
################################################################################
################################################################################
#class NvgreFailure(BfRuntimeTest):
#
#    TARGET = { 'device_id': 0,
#               'pipe_id': 0xffff }
#
#    # --------------------------------------------------------------------------
#    def setUp(self):
#        client_id = 0
#        p4_name = "npb"
#        BfRuntimeTest.setUp(self, client_id, p4_name)
#
#    # --------------------------------------------------------------------------        
#    def runTest(self):        
#
#        ig_port = swports[0]
#        target = self.Target(device_id=0, pipe_id=0xffff)
#
#        # Get bfrt_info and set it as part of the test
#        self.set_bfrt_info(self.parse_bfrt_info(self.get_bfrt_info("npb")))   
#
#        logger.info("Begin parser test: NvgreFailure\n")
#
#        pkts = rdpcap("%s" %('/npb-dp/src/npb/tests/pkts_inner_NvgreFailure.pcap'))
#
#        for pkt in pkts:
#         
#            # Send packet(s)
#            testutils.send_packet(self, ig_port, str(pkt))        
#            time.sleep(2)

            
