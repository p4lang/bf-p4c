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
# Milad Sharif (msharif@barefootnetworks.com)
#
###############################################################################

import logging
import grpc

from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils
from bfruntime_client_base_tests import BfRuntimeTest
import bfrt_grpc.bfruntime_pb2 as bfruntime_pb2
import bfrt_grpc.client as gc
from scapy import *

logger = logging.getLogger('Test')
if not len(logger.handlers):
    logger.addHandler(logging.StreamHandler())

import random

class INTL4_SHIM(Packet):
    fields_desc = [
        ByteField("int_type", 0),
        ByteField("rsvd1", 0),
        ByteField("len", 0),
        BitField("dscp", 0, 6),
        BitField("rsvd2", 0, 2)
    ]

class INT_HEADER(Packet):
    fields_desc = [
        BitField("ver", 1, 4),
        BitField("rep", 0, 2),
        BitField("c", 0, 1),
        BitField("e", 0, 1),
        BitField("m", 0, 1),
        BitField("rsvd1", 0, 7),
        BitField("rsvd2", 0, 3),
        BitField("hop_metadata_len", 0, 5),
        ByteField("remaining_hop_cnt", 0),
        BitField("instruction_mask_0003", 0, 4),
        BitField("instruction_mask_0407", 0, 4),
        BitField("instruction_mask_0811", 0, 4),
        BitField("instruction_mask_01215", 0, 4),
        ShortField("rsvd3", 0)
    ]

class INT_SWITCH_ID(Packet):
    fields_desc = [
		IntField("switch_id", 0)
	]

class INT_LEVEL1_PORT_IDS(Packet):
    fields_desc = [
        ShortField("ingress_port_id", 0),
        ShortField("egress_port_id", 0)
    ]

class RunTest(BfRuntimeTest):
    def setUp(self):
        client_id = 0
        p4_name = "case9326"
        BfRuntimeTest.setUp(self, client_id, p4_name)

    def runTest(self):
        ig_port = 10
        eg_port = 15
        eth_src = "00:10:20:30:40:50"
        eth_dst = "00:11:22:33:44:55"
        ipv4_src = "10.60.70.80"
        ipv4_dst = "10.66.77.88"
        ipv6_src = "2001:DB8::1"
        ipv6_dst = "2001:DB8::2"
        ipv6_tc = 0x17 << 2
        ipv6_fl = 0
        ipv6_hlim = 255
        switch_id=0x42424242

        # Get bfrt_info and set it as part of the test
        bfrt_info = self.interface.bfrt_info_get("case9326")

        target = gc.Target(device_id=0, pipe_id=0xffff)

        forward_table = bfrt_info.table_get("ingress_control.forward")
        forward_key_list = [forward_table.make_key([gc.KeyTuple(
                    'ingress_intrinsic_metadata.ingress_port', eg_port)])]
        forward_data_list = [forward_table.make_data([gc.DataTuple('port', eg_port)],
                            "ingress_control.send_to")]

        try:
            forward_table.entry_add(target, forward_key_list, forward_data_list)

            bind_layers(UDP, INTL4_SHIM)
            bind_layers(INTL4_SHIM, INT_HEADER)
            bind_layers(INT_HEADER, INT_SWITCH_ID)

            pkt = testutils.scapy.Ether(dst=eth_dst, src=eth_src)
            pkt /= testutils.scapy.IPv6(src=ipv6_src, dst=ipv6_dst, fl=ipv6_fl, tc=ipv6_tc, hlim=ipv6_hlim)
            pkt /= testutils.scapy.UDP(sport=5000, dport=5000, chksum=0)
            pkt /= INTL4_SHIM(int_type=1, len=8)
            pkt /= INT_HEADER(remaining_hop_cnt=255, instruction_mask_0003=8)
            pkt /= "dit is een test"

            exp_pkt = testutils.scapy.Ether(dst=eth_dst, src=eth_src)
            exp_pkt /= testutils.scapy.IPv6(src=ipv6_src, dst=ipv6_dst, fl=ipv6_fl, tc=ipv6_tc, hlim=ipv6_hlim, plen=35)
            exp_pkt /= testutils.scapy.UDP(sport=5000, dport=5000, len=35, chksum=0)
            exp_pkt /= INTL4_SHIM(int_type=1, len=8)
            exp_pkt /= INT_HEADER(remaining_hop_cnt=254, instruction_mask_0003=8)
            exp_pkt /= INT_SWITCH_ID(switch_id=switch_id)
            exp_pkt /= "dit is een test"

            logger.info("Sending packet on port %d", ig_port)
            testutils.send_packet(self, ig_port, pkt)

            logger.info("Expecting packet on port %d", eg_port)
            testutils.verify_packet(self, exp_pkt, eg_port)
        except grpc.RpcError as e:
            raise e
        finally:
            try:
                forward_table.entry_del(target, forward_key_list)
            except grpc.RpcError as e:
                pass
