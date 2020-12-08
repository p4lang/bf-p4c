import logging
import time
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify, ipv4_to_binary, mac_to_binary

import scapy
logger = logging.getLogger('udpv4_and_v6_checksum')
logger.addHandler(logging.StreamHandler())
class Test_IPv6_udp(P4RuntimeTest):
   @autocleanup
   def runTest(self):
        ingress_port = self.swports(0)
        egress_port  = self.swports(1)

        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.push_update_add_entry_to_action(
            req,
            'forward',
            [self.Exact("hdr.ethernet.src_addr", mac_to_binary('00:55:55:55:55:55'))],
            'chg_src_send',
            [('port', stringify(egress_port,2))])
        self.write_request(req)
        udp_pkt = testutils.simple_udpv6_packet(pktlen=100,
                        eth_dst='00:11:11:11:11:11',
                        eth_src='00:55:55:55:55:55',
                        dl_vlan_enable=False,
                        vlan_vid=0,
                        vlan_pcp=0,
                        ipv6_src='2001:db8:85a3:0:0:8a2e:370:7334',
                        ipv6_dst='2001:db8:85a3:0:0:8a2e:370:7335',
                        ipv6_tc=0,
                        ipv6_ecn=None,
                        ipv6_dscp=None,
                        ipv6_hlim=64,
                        ipv6_fl=0,
                        udp_sport=0x1234,
                        udp_dport=0x4118,
                        with_udp_chksum=True,
                        udp_payload=None
                        )

        exp_pkt = copy.deepcopy(udp_pkt)
        exp_pkt[UDP].sport = 0x1111;
        testutils.send_packet(self, ingress_port, str(udp_pkt))
        testutils.verify_packets(self, exp_pkt, [egress_port])
