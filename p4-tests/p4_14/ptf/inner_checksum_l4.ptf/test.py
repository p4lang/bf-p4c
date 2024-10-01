import logging
import time
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils
from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify, ipv4_to_binary, mac_to_binary

import scapy
from scapy.layers.inet import TCP
logger = logging.getLogger('inner_checksum_l4')
logger.addHandler(logging.StreamHandler())
class InnerLayerTest_IPv4_encap_udp(P4RuntimeTest):
    @autocleanup
    def runTest(self):
        ingress_port = self.swports(0)
        egress_port  = self.swports(1)
        outer_ipv4_src = '1.1.1.2'
        inner_ipv4_src = '10.10.10.2'
        new_outer_ipv4_src = '4.4.4.4'
        new_outer_ethernet_src = '00:77:77:77:77:77'
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.push_update_add_entry_to_action(
            req,
            'forward',
            [self.Exact("udp.dstPort", stringify(0x1234, 2))],
            'set_egr',
            [('port', stringify(egress_port,2))])
        self.write_request(req)
        #pkt = testutils.simple_udp_packet(
        # eth_dst='00:11:11:11:11:11',
        # eth_src='00:22:22:22:22:22',
        # ip_dst='10.10.10.1',
        # ip_src='10.10.10.2',
        # ip_id = 0,
        # ip_ttl = 64,
        # pktlen = 70,
        # udp_sport=0x1234,
        # udp_dport=0x1234,
        # with_udp_chksum = True)
        pkt = testutils.simple_tcp_packet()
        exp_pkt = testutils.simple_tcp_packet()
        exp_pkt[TCP].sport = 0xAB0B

        vxlan_pkt = testutils.simple_vxlan_packet(
         eth_dst='00:11:11:11:11:11',
         eth_src='00:22:22:22:22:22',
         ip_id=0,
         ip_src= '10.10.10.2',
         ip_dst='10.10.10.1',
         ip_ttl=64,
         ip_options = False,
         ip_flags=0x0,
         udp_sport=0x1234,
         udp_dport=0x1234,
         with_udp_chksum=True,
         vxlan_vni=0x1234,
         inner_frame=pkt)
        exp_vxlan_pkt = testutils.simple_vxlan_packet(
         eth_dst='00:11:11:11:11:11',
         eth_src='00:22:22:22:22:22',
         ip_id=0,
         ip_src= '10.10.10.2',
         ip_dst='10.10.10.1',
         ip_ttl=64,
         ip_options = False,
         ip_flags=0x0,
         udp_sport=0x1234,
         udp_dport=0x1234,
         with_udp_chksum=True,
         vxlan_vni=0x1234,
         inner_frame=exp_pkt)

         # exp_pkt[UDP].sport = 0x440
        print('sending udp packet')
        testutils.send_packet(self, ingress_port, vxlan_pkt)
        print('receiving vxlan_udp packet with option')
        testutils.verify_packets(self, exp_vxlan_pkt, [egress_port])
