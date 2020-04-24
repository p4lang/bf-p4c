import logging
import time
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify, ipv4_to_binary, mac_to_binary

import scapy
logger = logging.getLogger('checksum_if_else_cond')
logger.addHandler(logging.StreamHandler())

def create_payload(length, start=0):
    return "".join([chr(x % 256) for x in range(start, start+length)])

def create_ipv4_options(ipv4_opt):
    print("Creating IPv4 Options", repr(ipv4_opt))
    if ipv4_opt == 0 or ipv4_opt == None:
        return False
    elif isinstance(ipv4_opt, int):
        return IPOption(create_payload(ipv4_opt))
    elif isinstance(ipv4_opt, IPOption):
        return ipv4_opt
    else:
        return IPOption(ipv4_opt)

class Test_IPv4(P4RuntimeTest):
   @autocleanup
   def runTest(self):
        ingress_port = self.swports(0)
        egress_port  = self.swports(1)
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.push_update_add_entry_to_action(
            req,
            'forward',
            [self.Exact('hdr.ipv4.dst_addr', ipv4_to_binary('192.168.0.2'))],
            'send',
            [('port', stringify(egress_port, 2))])
        self.write_request(req)
        ip_pkt = testutils.simple_ipv4ip_packet(
                     eth_dst='02:22:22:22:22:21',
                     eth_src='01:11:11:11:11:12',
                     dl_vlan_enable=False,
                     vlan_vid=0,
                     vlan_pcp=0,
                     dl_vlan_cfi=0,
                     ip_src='10.11.12.13',
                     ip_dst='192.168.0.2',
                     ip_tos=0,
                     ip_ecn=None,
                     ip_dscp=None,
                     ip_ttl=64,
                     ip_id=0x0001,
                     ip_flags=0x0,
                     ip_ihl=None,
                     ip_options=create_ipv4_options(4),
                     inner_frame=None)
        testutils.send_packet(self, ingress_port, str(ip_pkt))
        testutils.verify_packets(self, ip_pkt, [egress_port])
