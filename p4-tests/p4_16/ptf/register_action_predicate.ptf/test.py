import logging
from scapy.all import Ether
from ptf.thriftutils import *
import ptf.testutils as testutils
from ptf.packet import *

from p4runtime_base_tests import P4RuntimeTest, autocleanup

logger = logging.getLogger('register_action_predicate')
logger.addHandler(logging.StreamHandler())

class Test_RegisterActionPredicate(P4RuntimeTest):
    
    def test_packet(self, port, range_addr, range_result):
        """ Tests predicate: 
        range_result = this.predicate(value.start > range_addr, value.end < range_addr)
        with value.start = 1, value.end = 3

        So, inside the SALU:
        cmp0: 1 > range_addr
        cmp1: 3 < range_addr
        cmp2: 0
        cmp3: 0

        Result is one-hot encoding of [0 0 cmp1 cmp0].
        """
        src = '02:00:00:00:00:00'
        dst = '01:00:00:00:00:00'
        pkt = Ether(src=src, dst=dst)/(range_addr.to_bytes(4, 'big') + range_result.to_bytes(4, 'big') + b'\xAB' * 38)

        testutils.send_packet(self, port, pkt)
        testutils.verify_packet(self, pkt, port)

    @autocleanup
    def runTest(self):
        port = self.swports(1)

        self.test_packet(port, 0, 0b0010) # only cmp0 true
        self.test_packet(port, 2, 0b0001) # both false
        self.test_packet(port, 4, 0b0100) # only cmp1 true
