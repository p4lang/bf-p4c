import ptf
from ptf import config
import ptf.testutils as testutils

from p4 import p4runtime_pb2
from p4.tmp import p4config_pb2
from p4.config import p4info_pb2

from base_test import P4RuntimeTest

class MyTest(P4RuntimeTest):
    def runTest(self):
        print "Running test"

        ig_port = self.swports(1)
        eg_port = self.swports(2)

        pkt = testutils.simple_tcp_packet()

        # default action (from P4 program) sends all packets to port 2
        testutils.send_packet(self, ig_port, str(pkt))
        testutils.verify_packet(self, pkt, eg_port)

        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        table_entry = update.entity.table_entry
        table_entry.table_id = self.get_table_id("t")
        self.set_action_entry(table_entry, "nop", [])

        rep = self.stub.Write(req)

        testutils.send_packet(self, ig_port, str(pkt))
        testutils.verify_no_other_packets(self)

        # restore default action
        # port must be 2 bytes
        self.set_action_entry(table_entry, "do", [])

        rep = self.stub.Write(req)

        testutils.send_packet(self, ig_port, str(pkt))
        testutils.verify_packet(self, pkt, eg_port)

        testutils.verify_no_other_packets(self)
