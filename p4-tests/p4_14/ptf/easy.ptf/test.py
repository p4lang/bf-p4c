import ptf
from ptf import config
import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2
from p4.tmp import p4config_pb2
from p4.config.v1 import p4info_pb2

from p4runtime_base_tests import P4RuntimeTest

class MyTest(P4RuntimeTest):
    def runTest(self):
        print "Running test"

        ig_port = self.swports(1)
        eg_port = self.swports(2)

        pkt = testutils.simple_tcp_packet()

        # default action (from P4 program) sends all packets to port 2
        testutils.send_packet(self, ig_port, str(pkt))
        testutils.verify_packet(self, pkt, eg_port)

        self.send_request_add_entry_to_action("t", None, "nop", [])

        testutils.send_packet(self, ig_port, str(pkt))
        testutils.verify_no_other_packets(self)

        # restore default action
        # port must be 2 bytes
        self.send_request_add_entry_to_action("t", None, "do", [])

        testutils.send_packet(self, ig_port, str(pkt))
        testutils.verify_packet(self, pkt, eg_port)

        testutils.verify_no_other_packets(self)
