import logging
import time
import copy
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils
from ptf.packet import *

from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify, ipv4_to_binary, mac_to_binary

logger = logging.getLogger('varbit_checksum')
logger.addHandler(logging.StreamHandler())

def create_payload(length, start=0):
    return "".join([chr(x % 256) for x in range(start, start+length)])

def create_ipv4_options(ipv4_opt):
    print("Creating IPv4 Options", repr(ipv4_opt))
    if ipv4_opt == 0 or ipv4_opt == None:
        return False
    else:
        return IPOption(create_payload(ipv4_opt))

class Test_IPv4_udp(P4RuntimeTest):
   @autocleanup
   def runTest(self):
        ingress_port = self.swports(0)

        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        for ipv4_opt in range(0, 44, 4):
            udp_pkt = testutils.simple_udp_packet(eth_dst='00:11:11:11:11:11',
                                                  eth_src='00:55:55:55:55:55',
                                                  ip_dst='10.10.10.1',
                                                  ip_src='10.10.10.2',
                                                  ip_id = 105,
                                                  ip_ttl = 64,
                                                  ip_options=create_ipv4_options(ipv4_opt),
                                                  udp_sport=0x1234,
                                                  udp_dport=0x4118,
                                                  with_udp_chksum = False)

            exp_pkt = copy.deepcopy(udp_pkt)
            exp_pkt[IP].src = '1.1.1.2'
            print("Sending UDP packet with ipv4 option : %d" % (ipv4_opt))
            testutils.send_packet(self, ingress_port, udp_pkt)
            testutils.verify_packets(self, exp_pkt, [ingress_port])
