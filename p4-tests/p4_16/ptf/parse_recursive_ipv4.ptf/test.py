import logging
import time
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils
from ptf.packet import *

from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify, ipv4_to_binary, mac_to_binary

logger = logging.getLogger('parse_recursive_ipv4')
logger.addHandler(logging.StreamHandler())

class Test_IPinIP(P4RuntimeTest):
   @autocleanup
   def runTest(self):
        ingress_port = self.swports(0)

        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id

        udp_pkt = Ether()/IP(proto=4)/IP(proto=4)/IP(proto=4)/IP(proto=17)/UDP()
        exp_pkt = Ether()/IP(proto=17)/UDP()

        testutils.send_packet(self, ingress_port, str(udp_pkt))
        testutils.verify_packets(self, exp_pkt, [ingress_port])
