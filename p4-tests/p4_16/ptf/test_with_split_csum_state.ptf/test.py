import logging
import time
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify, ipv4_to_binary, mac_to_binary

import scapy
logger = logging.getLogger('test_with_split_csum_state')
logger.addHandler(logging.StreamHandler())
class Test_ipv4_tcp(P4RuntimeTest):
    @autocleanup
    def runTest(self):
        ingress_port = self.swports(0)
        egress_port  = self.swports(1)
        
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.write_request(req)
        tcp_pkt = testutils.simple_tcp_packet();
        testutils.send_packet(self, ingress_port, str(tcp_pkt))
        testutils.verify_packets(self, tcp_pkt, [egress_port])

