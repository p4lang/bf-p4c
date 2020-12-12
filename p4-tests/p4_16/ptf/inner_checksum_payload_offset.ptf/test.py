import logging
import time
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify
import scapy
logger = logging.getLogger('inner_checksum')
logger.addHandler(logging.StreamHandler())

class InnerLayerTest_IPv4_udp(P4RuntimeTest):
    @autocleanup
    def runTest(self):
        ingress_port = self.swports(0)
        egress_port  = self.swports(1)
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.push_update_add_entry_to_action(
         req,
         'forward',
         [self.Exact("hdr.outer_udp.src_port", stringify(0x1234,2))],
         'send', [('port', stringify(egress_port,2))])
        self.write_request(req)

        udp_pkt = testutils.simple_udp_packet()

        vxlan_pkt = testutils.simple_vxlan_packet( 
                              eth_dst='00:11:11:11:11:11', 
                              eth_src='00:55:55:55:55:55', 
                              ip_id=0, 
                              ip_dst='1.1.1.1', 
                              ip_ttl=64, 
                              ip_flags=0x2, 
                              udp_sport=0x1234, 
                              udp_dport=0x4118, 
                              with_udp_chksum=True, 
                              vxlan_vni=0x1234, 
                              inner_frame=udp_pkt) 

        testutils.send_packet(self, ingress_port, vxlan_pkt)
        testutils.verify_packets(self, vxlan_pkt, [egress_port])
