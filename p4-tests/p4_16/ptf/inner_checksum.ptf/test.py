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

        ip_pkt = testutils.simple_ipv4ip_packet(
                     eth_dst='00:01:02:03:04:05',
                     eth_src='00:06:07:08:09:0a',
                     dl_vlan_enable=False,
                     vlan_vid=0,
                     vlan_pcp=0,
                     dl_vlan_cfi=0,
                     ip_src='192.168.0.1',
                     ip_dst='192.168.0.2',
                     ip_tos=0,
                     ip_ecn=None,
                     ip_dscp=None,
                     ip_ttl=64,
                     ip_id=0x0001,
                     ip_flags=0x0,
                     ip_ihl=None,
                     ip_options=False,
                     inner_frame=None)
 
        exp_ip_pkt = testutils.simple_ipv4ip_packet(
                     eth_dst='00:01:02:03:04:05',
                     eth_src='00:06:07:08:09:0a',
                     dl_vlan_enable=False,
                     vlan_vid=0,
                     vlan_pcp=0,
                     dl_vlan_cfi=0,
                     ip_src='192.168.0.1',
                     ip_dst='111.111.1.1',
                     ip_tos=0,
                     ip_ecn=None,
                     ip_dscp=None,
                     ip_ttl=64,
                     ip_id=0x0001,
                     ip_flags=0x0,
                     ip_ihl=None,
                     ip_options=False,
                     inner_frame=None) 

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
                              inner_frame=ip_pkt) 

        exp_vxlan_pkt = testutils.simple_vxlan_packet(
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
                              inner_frame=exp_ip_pkt)

        testutils.send_packet(self, ingress_port, vxlan_pkt)
        testutils.verify_packets(self, exp_vxlan_pkt, [egress_port])