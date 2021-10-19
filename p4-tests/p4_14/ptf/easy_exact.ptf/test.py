import ptf
from ptf import config
import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2
from p4.tmp import p4config_pb2
from p4.config.v1 import p4info_pb2

from p4runtime_base_tests import P4RuntimeTest, stringify, autocleanup

# Creates a dumbPacket corresponding to the header h_t.
def dumbPacket(f1=0xabcd, f2=0xef, f3=0xaa):
    assert 0 <= f1 <= 0xffff
    assert 0 <= f2 <= 0xff
    assert 0 <= f3 <= 0xff

    s = stringify(f1, 2) + stringify(f2, 1) + stringify(f3, 1)

    # Add fake payload.
    s += b'0' * 100
    return s

class SimpleTest(P4RuntimeTest):
    @autocleanup
    def runTest(self):
        ig_port = self.swports(1)
        # Sending a packet when no entry is installed. Should miss.
        pkt = dumbPacket(0xdead, 0x00, 0x00)
        testutils.send_packet(self, ig_port, pkt)
        testutils.verify_no_other_packets(self)

        # Add a single entry: matches on the 8 bit length prefix of "0xdead",
        # and sends the packet to port number 3, while setting the h.f2 field
        # to 0x42.
        f1 = 0xdead
        val = 0x42
        eg_port = self.swports(3)
        self.send_request_add_entry_to_action(
            "t", [self.Exact("h.f1", stringify(f1, 2))],
            "do", [("val", stringify(val, 1)), ("port", stringify(eg_port, 2))])

        # Send a matching packet, with the exact value matching.
        # Expect packet on port 3, with a f2 field of 0x42.
        pkt = dumbPacket(f1=f1, f2=0x00, f3=0x00)
        testutils.send_packet(self, ig_port, pkt)
        exp_pkt = dumbPacket(f1=f1, f2=val, f3=0x00)
        testutils.verify_packet(self, exp_pkt, eg_port)

        # Send a non matching packet.
        pkt = dumbPacket(f1=0x00aa, f2=0x00, f3=0x00)
        testutils.send_packet(self, ig_port, pkt)
        testutils.verify_no_other_packets(self)
