import ptf
import os
from ptf import config
import ptf.testutils as testutils
import ptf.packet as scapy

from p4.v1 import p4runtime_pb2

from p4runtime_base_tests import P4RuntimeTest

class ConstantSetTest(P4RuntimeTest):
    def runTest(self):
        port = self.swports(1)

        pkt = scapy.Ether() / "\x00\x00"
        exp_pkt = scapy.Ether() / "\x00\xc7"

        testutils.send_packet(self, port, str(pkt))
        testutils.verify_packet(self, exp_pkt, port)
