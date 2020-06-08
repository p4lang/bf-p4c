import logging
import time
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify, ipv4_to_binary, mac_to_binary

import scapy
logger = logging.getLogger('arista_workaround')
logger.addHandler(logging.StreamHandler())

class Test_IPv4_udp(P4RuntimeTest):
   @autocleanup
   def runTest(self):
        ingress_port = self.swports(0)
        egress_port  = self.swports(1)
        
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.push_update_add_entry_to_action(
         req,
         'forward',
         [self.Exact("hdr.udp.src_port", stringify(0x1234,2))],
         'send', [('port', stringify(egress_port,2))])
        self.write_request(req)
        udp_pkt = testutils.simple_udp_packet(eth_dst='00:11:11:11:11:11', 
                                              eth_src='00:55:55:55:55:55', 
                                              ip_dst='10.10.10.1', 
                                              ip_src='10.10.10.2', 
                                              ip_id = 105, 
                                              ip_ttl = 64, 
                                              pktlen = 70, 
                                              udp_sport=0x1234, 
                                              udp_dport=0x4118, 
                                              with_udp_chksum = False) 
        exp_pkt = testutils.simple_udp_packet(eth_dst='00:11:11:11:11:11',
                                              eth_src='00:55:55:55:55:55',
                                              ip_src='18.52.101.120',
                                              ip_dst='152.118.84.50',
                                              ip_id = 105,
                                              ip_ttl = 64,
                                              pktlen = 70,
                                              udp_sport=0x1234,
                                              udp_dport=0x4118,
                                              with_udp_chksum = False)
        testutils.send_packet(self, ingress_port, str(udp_pkt))
        testutils.verify_packets(self, exp_pkt, [egress_port])
