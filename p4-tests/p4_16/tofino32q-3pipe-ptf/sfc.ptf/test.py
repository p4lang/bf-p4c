import ptf.testutils as testutils
from ptf.testutils import group
from ptf.mask import Mask
import struct

from p4.v1 import p4runtime_pb2

from base_test import P4RuntimeTest, autocleanup
from base_test import stringify, ipv4_to_binary, mac_to_binary

import scapy.main

SWITCH_MAC = "02:00:00:00:aa:01"
HOST1_MAC = "00:00:00:00:00:01"
HOST2_MAC = "00:00:00:00:00:02"
HOST3_MAC = "00:00:00:00:00:03"
HOST1_IPV4 = "10.0.1.1"
HOST2_IPV4 = "10.0.2.1"

class SfcTest(P4RuntimeTest):
    def setUp(self):
        super(SfcTest, self).setUp()
        self.port1 = self.swports(1)
        self.port2 = self.swports(2)
        self.port3 = self.swports(3)

    def setup_int(self):
        pass

class SfcForwardingTest(SfcTest):
    @autocleanup
    def runTest(self):
        pkt_1to2 = testutils.simple_tcp_packet(
            eth_src = HOST1_MAC, eth_dst = SWITCH_MAC,
            ip_src = HOST1_IPV4, ip_dst = HOST2_IPV4, ip_ttl = 64)
        exp_pkt_1to2 = testutils.simple_tcp_packet(
            eth_src = HOST1_MAC, eth_dst = SWITCH_MAC,
            ip_src = HOST1_IPV4, ip_dst = HOST2_IPV4, ip_ttl = 64)

        testutils.send_packet(self, self.port1, str(pkt_1to2))
        testutils.verify_packets(self, exp_pkt_1to2, [self.port2])
