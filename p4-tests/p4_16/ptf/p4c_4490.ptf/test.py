import logging
from scapy.all import Ether
from ptf.thriftutils import *
import ptf.testutils as testutils
from ptf.packet import *

from p4runtime_base_tests import P4RuntimeTest, autocleanup

logger = logging.getLogger('p4c_4490')
logger.addHandler(logging.StreamHandler())


def create_packet(byte1, byte2):
    src = '02:00:00:00:00:00'
    dst = '01:00:00:00:00:00'
    return Ether(src=src, dst=dst)/'{}{}{}'.format(chr(byte1), chr(byte2), chr(0x0) * 44)


class Test_SliceComparison(P4RuntimeTest):
    @autocleanup
    def runTest(self):
        ingress_port = self.swports(0)
        egress_port = ingress_port

        for i in range(0, 15):
            for j in range(0, 15):
                byte1 = 0x60 + i
                byte2 = 0x60 + j

                pkt = create_packet(byte1, byte2)
                testutils.send_packet(self, ingress_port, pkt)
                if i > j:
                    byte1 = byte2
                epkt = create_packet(byte1, byte2)
                testutils.verify_packet(self, epkt, egress_port)
