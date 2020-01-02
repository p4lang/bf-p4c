import logging
import time
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify, ipv4_to_binary, mac_to_binary

import scapy
logger = logging.getLogger('parse_recursive_ipv4')
logger.addHandler(logging.StreamHandler())

class Test_IPinIP(P4RuntimeTest):
   @autocleanup
   def runTest(self):
        ingress_port = self.swports(0)

        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id

        eth = Ether()
        udp = UDP()
        ip0 = IP(proto=4)
        ip1 = IP(proto=4)
        ip2 = IP(proto=4)
        ip3 = IP(proto=17)

        udp_pkt = eth/ip0/ip1/ip2/ip3/udp
        exp_pkt = eth/ip3/udp 

        testutils.send_packet(self, ingress_port, str(udp_pkt))
        testutils.verify_packets(self, exp_pkt, [ingress_port])
