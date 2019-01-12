import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2

from p4runtime_base_tests import P4RuntimeTest, autocleanup
from p4runtime_base_tests import stringify

class PacketUpdateTest(P4RuntimeTest):
    def runTest(self):
        port1 = self.swports(1)
        inputV = 65535
        outputV = inputV - 32
        pkt = stringify(inputV, 2) + "\xab" * 64
        exp_pkt = stringify(outputV, 2) + "\xab" * 64
        testutils.send_packet(self, port1, str(pkt))
        testutils.verify_packets(self, exp_pkt, [port1])
