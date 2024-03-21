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
###############################################################################

import logging
import time

from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils
from bfruntime_base_tests import BfRuntimeTest
import bfrt_grpc.bfruntime_pb2 as bfruntime_pb2

logger = logging.getLogger('Test')
logger.addHandler(logging.StreamHandler())

swports = []
for device, port, ifname in config["interfaces"]:
    swports.append(port)
    swports.sort()

if swports == []:
    swports = range(9)


class TestExact(BfRuntimeTest):
    def setUp(self):
        client_id = 0
        p4_name = "t2na_static_entry"
        BfRuntimeTest.setUp(self, client_id, p4_name)

    def runTest(self):
        #ig_port = swports[0]
        #eg_port = ig_port

        ig_port = 2
        eg_port = 2

        # Get bfrt_info and set it as part of the test
        self.set_bfrt_info(self.parse_bfrt_info(self.get_bfrt_info("t2na_static_entry")))

        p1 = testutils.simple_eth_packet(pktlen=100, eth_src='00:00:00:00:00:00')
        p1_exp = testutils.simple_eth_packet(pktlen=100, eth_src='00:00:00:00:00:01')
        logger.info("Sending packet non-IP on port %d", ig_port)
        testutils.send_packet(self, ig_port, p1)
        time.sleep(5)
        logger.info("Expecting packet non-IP on port %d", eg_port)
        testutils.verify_packets(self, p1_exp, [eg_port])

        p2 = testutils.simple_ip_packet(eth_src='00:00:00:00:00:00')
        p2_exp = testutils.simple_ip_packet(eth_src='00:00:00:00:00:02')
        logger.info("Sending packet IPv4 on port %d", ig_port)
        testutils.send_packet(self, ig_port, p2)
        logger.info("Expecting packet IPv4 on port %d", eg_port)
        testutils.verify_packets(self, p2_exp, [eg_port])

        ''' -- ipv6 disabled in t2na_static_entry.p4
        p3 = testutils.simple_ipv6ip_packet(eth_src='00:00:00:00:00:00')
        p3_exp = testutils.simple_ipv6ip_packet(eth_src='00:00:00:00:00:03')
        logger.info("Sending packet IPv6 on port %d", ig_port)
        testutils.send_packet(self, ig_port, p3)
        logger.info("Expecting packet IPv6 on port %d", eg_port)
        testutils.verify_packets(self, p3_exp, [eg_port])
        '''


class TestTernary(BfRuntimeTest):
    def setUp(self):
        client_id = 0
        p4_name = "t2na_static_entry"
        BfRuntimeTest.setUp(self, client_id, p4_name)

    def runTest(self):
        ig_port = swports[0]
        eg_port = ig_port

        # Get bfrt_info and set it as part of the test
        self.set_bfrt_info(self.parse_bfrt_info(self.get_bfrt_info("t2na_static_entry")))

        p1 = testutils.simple_ip_packet(eth_src='00:00:00:00:00:01',
                                        eth_dst='00:00:00:01:03:07',
                                        ip_src='0.0.0.255',
                                        ip_proto=5)
        p1_exp = testutils.simple_ip_packet(eth_src='00:00:00:00:00:02',
                                            eth_dst='00:00:00:01:03:07',
                                            ip_src='0.0.0.255',
                                            ip_proto=5)
        logger.info("Sending packet IPv4 on port %d", ig_port)
        testutils.send_packet(self, ig_port, p1)
        logger.info("Expecting packet IPv4 on port %d", eg_port)
        testutils.verify_packets(self, p1_exp, [eg_port])

        p2 = testutils.simple_ip_packet(eth_src='00:00:00:00:00:01',
                                        eth_dst='00:00:00:01:03:07',
                                        ip_src='0.0.0.10',
                                        ip_proto=7)
        p2_exp = testutils.simple_ip_packet(eth_src='00:00:00:00:00:03',
                                            eth_dst='00:00:00:01:03:07',
                                            ip_src='0.0.0.10',
                                            ip_proto=7)
        logger.info("Sending packet IPv4 on port %d", ig_port)
        testutils.send_packet(self, ig_port, p2)
        logger.info("Expecting packet IPv4 on port %d", eg_port)
        testutils.verify_packets(self, p2_exp, [eg_port])

        p3 = testutils.simple_ip_packet(eth_src='00:00:00:00:00:01',
                                        eth_dst='00:00:00:00:00:07',
                                        ip_src='0.0.0.10',
                                        ip_proto=7)
        p3_exp = testutils.simple_ip_packet(eth_src='00:00:00:00:00:04',
                                            eth_dst='00:00:00:00:00:07',
                                            ip_src='0.0.0.10',
                                            ip_proto=7)
        logger.info("Sending packet IPv4 on port %d", ig_port)
        testutils.send_packet(self, ig_port, p3)
        logger.info("Expecting packet IPv4 on port %d", eg_port)
        testutils.verify_packets(self, p3_exp, [eg_port])

        p4 = testutils.simple_ip_packet(eth_src='00:00:00:00:00:01',
                                        eth_dst='00:00:00:01:03:07',
                                        ip_src='0.0.0.10',
                                        ip_proto=11)
        p4_exp = testutils.simple_ip_packet(eth_src='00:00:00:00:00:01',
                                            eth_dst='00:00:00:01:03:07',
                                            ip_src='0.0.0.10',
                                            ip_proto=11)
        logger.info("Sending packet IPv4 on port %d", ig_port)
        testutils.send_packet(self, ig_port, p4)
        logger.info("Expecting packet IPv4 on port %d", eg_port)
        testutils.verify_packets(self, p4_exp, [eg_port])
