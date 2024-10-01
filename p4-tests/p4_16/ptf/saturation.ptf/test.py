import logging
import time
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify, ipv4_to_binary, mac_to_binary

import scapy
logger = logging.getLogger('saturation')
logger.addHandler(logging.StreamHandler())
class Test_IPv6_udp(P4RuntimeTest):
   def insertRule(self, tableName, keys, actionName, params):
      self.send_request_add_entry_to_action(tableName, keys, actionName, params);

   @autocleanup
   def runTest(self):
      ingress_port = self.swports(0)
      egress_port  = 4

      req = p4runtime_pb2.WriteRequest()
      req.device_id = self.device_id
      self.write_request(req)

      pkt1 = testutils.simple_eth_packet(eth_dst="00:00:00:00:00:00",
      eth_src="00:00:00:00:00:80",
      eth_type=0x80)

      exp_pkt1 = testutils.simple_eth_packet(eth_dst="00:00:00:00:00:00",
      eth_src="00:00:00:00:00:80",
      eth_type=0xFF) # Assert: 0x80 |+| 0xFF = 0xFF

      testutils.send_packet(self, ingress_port, pkt1)
      testutils.verify_packets(self, exp_pkt1, [egress_port])
      testutils.verify_no_other_packets(self)
