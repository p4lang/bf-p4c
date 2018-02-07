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
# $Id: $
#
#
#  Milad Sharif (msharif@barefootnetworks.com)
#
###############################################################################

import ptf.testutils as testutils
import logging

from p4 import p4runtime_pb2

from base_test import P4RuntimeTest, autocleanup
from base_test import stringify, ipv4_to_binary, mac_to_binary

logger = logging.getLogger('ipv4_checksum')

class IPv4ChecksumTest(P4RuntimeTest):
    @autocleanup
    def runTest(self):
        ig_port = self.swports(1)
        eg_port = self.swports(2)
        dst_ip = '10.0.1.1'
        dmac = '00:00:00:00:00:01'
        rmac = '00:00:00:00:00:02'
        nexthop = 1

        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id

        self.push_update_add_entry_to_action(
            req,
            'fib',
            [self.Exact('hdr.ipv4.dst_addr', ipv4_to_binary(dst_ip))],
            'set_nexthop',
            [('index', stringify(nexthop, 2))])

        self.push_update_add_entry_to_action(
            req,
            'nexthop',
            [self.Exact('nexthop_index', stringify(nexthop, 2))],
            'set_nexthop_info',
            [('dmac', mac_to_binary(dmac))])

        self.push_update_add_entry_to_action(
            req,
            'dmac',
            [self.Exact('hdr.ethernet.dst_addr', mac_to_binary(dmac))],
            'set_port',
            [('port', stringify(eg_port, 2))])

        self.push_update_add_entry_to_action(
            req,
            'rewrite',
            [self.Exact('ig_intr_md_for_tm.ucast_egress_port', stringify(eg_port, 2))],
            'rewrite_',
            [('smac', mac_to_binary(rmac))])

        self.write_request(req)

        pkt = testutils.simple_tcp_packet(
            eth_dst=rmac, ip_dst=dst_ip, ip_ttl=64)
        exp_pkt = testutils.simple_tcp_packet(
            eth_dst=dmac, eth_src=rmac, ip_dst=dst_ip, ip_ttl=63)

        logger.info("Sending packet on port %d", ig_port)
        testutils.send_packet(self, ig_port, str(pkt))

        logger.info("Expecting packet on port %d", eg_port)
        testutils.verify_packets(self, exp_pkt, [eg_port])

