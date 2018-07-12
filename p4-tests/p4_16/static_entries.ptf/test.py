################################################################################
# BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
#
# Copyright (c) 2015-2016 Barefoot Networks, Inc.

# All Rights Reserved.
#
# NOTICE: All information contained herein is, and remains the property of
# Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
# technical concepts contained herein are proprietary to Barefoot Networks, # Inc.
# and its suppliers and may be covered by U.S. and Foreign Patents, patents in
# process, and are protected by trade secret or copyright law.
# Dissemination of this information or reproduction of this material is
# strictly forbidden unless prior written permission is obtained from
# Barefoot Networks, Inc.
#
# No warranty, explicit or implicit is provided, unless granted under a
# written agreement with Barefoot Networks, Inc.
#
#  Milad Sharif (msharif@barefootnetworks.com)
#
###############################################################################

import ptf.testutils as testutils
import logging

from p4.v1 import p4runtime_pb2

from base_test import P4RuntimeTest, autocleanup
from base_test import stringify, ipv4_to_binary, mac_to_binary

logger = logging.getLogger('static_entries')

class IPv4ChecksumTest(P4RuntimeTest):
    @autocleanup
    def runTest(self):
        ig_port = self.swports(1)
        eg_port = ig_port

        pkt = testutils.simple_tcp_packet(eth_src='00:00:11:22:33:44')
        exp_pkt = testutils.simple_tcp_packet(eth_src='00:00:00:00:00:02')
        logger.info("Sending packet on port %d", ig_port)
        testutils.send_packet(self, ig_port, str(pkt))
        logger.info("Expecting packet on port %d", eg_port)
        testutils.verify_packets(self, exp_pkt, [eg_port])

        pkt = testutils.simple_tcpv6_packet(eth_src='00:00:11:22:33:44')
        exp_pkt = testutils.simple_tcpv6_packet(eth_src='00:00:00:00:00:03')
        logger.info("Sending packet on port %d", ig_port)
        testutils.send_packet(self, ig_port, str(pkt))

        logger.info("Expecting packet on port %d", eg_port)
        testutils.verify_packets(self, exp_pkt, [eg_port])

        pkt = testutils.simple_arp_packet(
            pktlen=100, eth_src='00:00:11:22:33:44')
        exp_pkt = testutils.simple_arp_packet(
            pktlen=100, eth_src='00:00:00:00:00:01')
        logger.info("Sending packet on port %d", ig_port)
        testutils.send_packet(self, ig_port, str(pkt))

        logger.info("Expecting packet on port %d", eg_port)
        testutils.verify_packets(self, exp_pkt, [eg_port])

