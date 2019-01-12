import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2

from p4runtime_base_tests import P4RuntimeTest, autocleanup
from p4runtime_base_tests import stringify

class InvalidChecksumTest(P4RuntimeTest):
    def runTest(self):
        pkt = testutils.simple_tcp_packet()
        pkt[IP].chksum = 0xffff
        port1 = self.swports(1)
        testutils.send_packet(self, port1, str(pkt))
        testutils.verify_no_other_packets(self)
