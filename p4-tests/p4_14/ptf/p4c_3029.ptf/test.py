import logging
import time
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils
from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify, ipv4_to_binary, mac_to_binary
import scapy

logger = logging.getLogger('TestSetInnerVLAN')
logger.addHandler(logging.StreamHandler())

class TestSetInnerVLAN(P4RuntimeTest):
    @autocleanup
    def runTest(self):
        ingress_port = self.swports(0)
        egress_port  = self.swports(0)

        ipkt = Ether(dst='00:01:02:03:04:05', src='00:06:07:08:09:0a')/ \
               Dot1Q(prio=0, id=0, vlan=1231)/ \
               Dot1Q(prio=0, id=0, vlan=1232)/ \
               IP(src='192.168.0.1', dst='192.168.0.2', tos=0, ttl=64, ihl=None, id=1)
        ivxlan_pkt = testutils.simple_vxlan_packet(with_udp_chksum=True,
                                                   vxlan_vni=1,
                                                   inner_frame=ipkt)
        # Change vlan of the second Dot1Q of the inner packet
        evxlan_pkt = ivxlan_pkt.copy()
        evxlan_pkt[VXLAN][Dot1Q][1].vlan = 3214

        testutils.send_packet(self, ingress_port, ivxlan_pkt)
        testutils.verify_packets(self, evxlan_pkt, [egress_port])
