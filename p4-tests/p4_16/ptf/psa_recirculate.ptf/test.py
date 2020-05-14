import logging
import time
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify, ipv4_to_binary, mac_to_binary

import scapy
logger = logging.getLogger('psa_reciculate')
logger.addHandler(logging.StreamHandler())
class Test_IPv6_udp(P4RuntimeTest):
   @autocleanup
   def runTest(self):
        ingress_port = self.swports(0)
        egress_port  = self.swports(7)

        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.write_request(req)
        pkt = testutils.simple_eth_packet()

        exp_pkt = testutils.simple_eth_packet(eth_type=0xffff)
        testutils.send_packet(self, ingress_port, str(pkt))
        testutils.verify_packets(self, exp_pkt, [egress_port])

