import logging
from scapy.all import Ether
from ptf.thriftutils import *
import ptf.testutils as testutils
from ptf.packet import *

from p4runtime_base_tests import P4RuntimeTest, autocleanup

class RoutedPacket(P4RuntimeTest):
    @autocleanup
    def runTest(self):
        # ingress_port = self.swports(0)
        # egress_port = self.swports(2)
        dpkt = Ether(dst='de:ad:be:ef:ac:ab',src='ba:0e:ad:ea:fc:ab')
        dpb = dpkt.build()
        pkt = Ether(src='02:00:00:00:00:00',dst='01:00:00:00:00:00')/'PayloadPayloadPayloadPayloadPayloadPayloadPayloadPayloadPayloadPayload'
        testutils.send_packet(self, 2, pkt)
        expected = pkt
        testutils.verify_packet(self, expected, 2)
