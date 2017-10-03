import ptf
from ptf import config
import ptf.testutils as testutils

from p4 import p4runtime_pb2
from p4.tmp import p4config_pb2
from p4.config import p4info_pb2

from base_test import P4RuntimeTest, stringify

import random

# Creates a dumbPacket corresponding to the header h_t.
def dumbPacket(f1=0xabcd, f2=0xef, f3=0xaa):
    assert 0 <= f1 <= 0xffff
    assert 0 <= f2 <= 0xff
    assert 0 <= f3 <= 0xff

    s = stringify(f1, 2) + stringify(f2, 1) + stringify(f3, 1)

    # Add fake payload.
    s += '0' * 15
    return s

class BaseTest(P4RuntimeTest):
    def setUp(self):
        super(BaseTest, self).setUp()
        self.reqs = []

    def add_entry(self, f1, pLen, val, port):
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        table_entry = update.entity.table_entry
        table_entry.table_id = self.get_table_id("t")

        self.set_match_key(
            table_entry, "t",
            [self.Lpm("h.f1", stringify(f1, 2), pLen)])
        self.set_action_entry(
            table_entry, "do",
            [("val", stringify(val, 1)), ("port", stringify(port, 2))])

        rep = self.stub.Write(req)
        self.reqs.append(req)

class SimpleTest(BaseTest):
    def runTest(self):
        ig_port = self.swports(1)
        eg_port = self.swports(3)

        # Sending a packet when no entry is installed. Should miss.
        pkt = dumbPacket(0xdead, 0x00, 0x00)
        testutils.send_packet(self, ig_port, str(pkt))
        testutils.verify_no_other_packets(self)

        # Add a single entry: matches on the 8 bit length prefix of "0xdead",
        # and sends the packet to port number 3, while setting the h.f2 field
        # to 0x42.
        self.add_entry(0xdead, 8, 0x42, eg_port);

        # Send a matching packet, with the exact value in the ternary entry.
        # Expect packet on port 3, with a f2 field of 0x42.
        pkt = dumbPacket(f1=0xdead, f2=0x00, f3=0x00)
        testutils.send_packet(self, ig_port, str(pkt))
        exp_pkt = dumbPacket(f1=0xdead, f2=0x42, f3=0x00)
        testutils.verify_packet(self, exp_pkt, eg_port)

        # Send a matching packet, exercising the ternary match.
        # Expect packet on port 3, with a f2 field of 0x42.
        pkt = dumbPacket(f1=0xde00, f2=0x00, f3=0x00)
        testutils.send_packet(self, ig_port, str(pkt))
        exp_pkt = dumbPacket(f1=0xde00, f2=0x42, f3=0x00)
        testutils.verify_packet(self, exp_pkt, eg_port)

        # Send a non matching packet.
        pkt = dumbPacket(f1=0xaa00, f2=0x00, f3=0x00)
        testutils.send_packet(self, ig_port, str(pkt))
        testutils.verify_no_other_packets(self)

        self.undo_write_requests(self.reqs)

class SmokeTest(BaseTest):
    def runTest(self):
        port1 = self.swports(1)
        port2 = self.swports(2)
        port3 = self.swports(3)
        port4 = self.swports(4)

        self.add_entry(0xbeef, 4, 0x42, port1)
        self.add_entry(0xbeef, 8, 0x43, port2)
        self.add_entry(0xbeef, 12, 0x44, port3)
        self.add_entry(0xbeef, 16, 0x45, port4)

        # Exercise all these LPM entries.
        for i in random.sample(range(0xb000, 0xbe00), 50):
            pkt = dumbPacket(f1=i, f2=0x00, f3=0x00)
            testutils.send_packet(self, port1, str(pkt))
            exp_pkt = dumbPacket(f1=i, f2=0x42, f3=0x00)
            testutils.verify_packet(self, exp_pkt, port1)

        for i in random.sample(range(0xbe00, 0xbee0), 20):
            pkt = dumbPacket(f1=i, f2=0x00, f3=0x00)
            testutils.send_packet(self, port1, str(pkt))
            exp_pkt = dumbPacket(f1=i, f2=0x43, f3=0x00)
            testutils.verify_packet(self, exp_pkt, port2)

        for i in random.sample(range(0xbee0, 0xbeef), 5):
            pkt = dumbPacket(f1=i, f2=0x00, f3=0x00)
            testutils.send_packet(self, port1, str(pkt))
            exp_pkt = dumbPacket(f1=i, f2=0x44, f3=0x00)
            testutils.verify_packet(self, exp_pkt, port3)

        pkt = dumbPacket(f1=0xbeef, f2=0x00, f3=0x00)
        testutils.send_packet(self, port1, str(pkt))
        exp_pkt = dumbPacket(f1=0xbeef, f2=0x45, f3=0x00)
        testutils.verify_packet(self, exp_pkt, port4)

        # Packets that don't match any entries, just to be safe.
        for i in random.sample(range(0xc000, 0xcfff), 100):
            pkt = dumbPacket(f1=i, f2=0x00, f3=0x00)
            testutils.send_packet(self, port1, str(pkt))
            testutils.verify_no_other_packets(self)

        self.undo_write_requests(self.reqs)
