import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2

from p4runtime_base_tests import P4RuntimeTest, autocleanup
from p4runtime_base_tests import stringify, ipv4_to_binary, mac_to_binary

class IngressChecksumTest(P4RuntimeTest):
    def runTest(self):
        port1 = self.swports(1)
        pkt = testutils.simple_tcp_packet(ip_ttl=64)
        exp_pkt = testutils.simple_tcp_packet(ip_ttl=63)
        testutils.send_packet(self, port1, str(pkt))
        testutils.verify_packets(self, exp_pkt, [port1])
