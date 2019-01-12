import ptf
from ptf import config
import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2
from p4.tmp import p4config_pb2
from p4.config.v1 import p4info_pb2

from p4runtime_base_tests import P4RuntimeTest, stringify

# Creates a dumbPacket corresponding to the header h_t.
def dumbPacket(f1=0xab, f2=0xef, f3=0xaa):
    assert 0 <= f1 <= 0xff
    assert 0 <= f2 <= 0xff
    assert 0 <= f3 <= 0xff

    s = stringify(f1, 1) + stringify(f2, 1) + stringify(f3, 1)

    # Add fake payload.
    s += '0' * 15
    return s

class SimpleTest(P4RuntimeTest):
    def runTest(self):

        ig_port = self.swports(1)
        # no entries are added as this is a keyless match
        # exp_val is placed on f2 at port 1 only if f1 is 0x0
        eg_port = self.swports(1)

        # Sending a packet which should hit gateway and execute action.
        f1 = 0x00
        f2 = 0x00
        f3 = 0x00
        exp_val = 0x5 
        pkt = dumbPacket(f1=f1, f2=f2, f3=f3)
        testutils.send_packet(self, ig_port, str(pkt))
        exp_pkt = dumbPacket(f1=f1, f2=exp_val, f3=f3)
        testutils.verify_packet(self, exp_pkt, eg_port)

        # Send another packet which misses gateway and should be dropped
        f1 = 0xad
        f2 = 0xff
        f3 = 0x55
        # Send another packet.
        pkt = dumbPacket(f1=f1, f2=f2, f3=f3)
        testutils.send_packet(self, ig_port, str(pkt))
        exp_pkt = dumbPacket(f1=f1, f2=exp_val, f3=f3)
        testutils.verify_no_other_packets(self)
