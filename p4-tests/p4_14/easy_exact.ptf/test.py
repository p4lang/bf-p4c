import ptf
from ptf import config
import ptf.testutils as testutils

#import pdb
from p4 import p4runtime_pb2
from p4.tmp import p4config_pb2
from p4.config import p4info_pb2

from base_test import P4RuntimeTest

# Takes a value and the desired length in hexadecimal. Outputs it stringified,
# with \x separating the bytes.
def stringify(val, length):
    s = format(val, '0%dx' % length)
    pairs = [s[i:i+2] for i in xrange(0, len(s), 2)]

    return "".join(pairs).decode("hex")

# Creates a dumbPacket corresponding to the header h_t.
def dumbPacket(f1=0xabcd, f2=0xef, f3=0xaa):
    assert 0 <= f1 <= 0xffff
    assert 0 <= f2 <= 0xff
    assert 0 <= f3 <= 0xff

    s = stringify(f1, 4) + stringify(f2, 2) + stringify(f3, 2)

    # Add fake payload.
    s += '000000000000000'
    return s

class SimpleTest(P4RuntimeTest):

    def runTest(self):
        print "Running test"

#        pdb.set_trace()
        # Sending a packet when no entry is installed. Should miss.
        pkt = dumbPacket(0xdead, 0x00, 0x00)
        testutils.send_packet(self, 1, str(pkt))
        testutils.verify_no_other_packets(self)

        # Setup for adding a new entry.
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        table_entry = update.entity.table_entry
        table_entry.table_id = self.get_table_id("t")

        # Add a single entry: matches on the 8 bit length prefix of "0xdead",
        # and sends the packet to port number 3, while setting the h.f2 field
        # to 0x42.
        self.set_match_key(
            table_entry, "t",
            [self.Exact("h.f1", "\xde\xad")])
        self.set_action_entry(table_entry, "do", [("val", "\x42"), ("port", "\x00\x03")])

        # Send the gRPC request.
        rep = self.stub.Write(req)

        # Send a matching packet, with the exact value matching.
        # Expect packet on port 3, with a f2 field of 0x42.
        pkt = dumbPacket(f1=0xdead, f2=0x00, f3=0x00)
        testutils.send_packet(self, 1, str(pkt))
        exp_pkt = dumbPacket(f1=0xdead, f2=0x42, f3=0x00)
        testutils.verify_packet(self, exp_pkt, 3)

        # Send a non matching packet.
        pkt = dumbPacket(f1=0x00aa, f2=0x00, f3=0x00)
        testutils.send_packet(self, 1, str(pkt))
        testutils.verify_no_other_packets(self)
