import logging
import time
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils
from ptf.packet import *

from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify, ipv4_to_binary, mac_to_binary

logger = logging.getLogger('checksum_splitting')
logger.addHandler(logging.StreamHandler())

class Test_Split_Checksum(P4RuntimeTest):
   @autocleanup
   def runTest(self):
        ingress_port = self.swports(0)
        egress_port  = self.swports(2)
        # first header + split_header + split_header.checksum 
        # We will subtract two 32b values that look like x00010001 => this will
        # subtract 4 total
        # Also original checksum will subtract 0xFFE6 => total subtract of 0xFFEA
        # => we are left with 0x0015
        in_pkt = b"\x00"*12 + (b"\x00"+b"\x01")*11 + (b"\xFF"+b"\xE6") + b"\x00"*53
        # We replaced the two values with 0x00000022 and 0x00000033 => total
        # new sum of 0x0055
        # =>        +0x0015 that was left
        # =>        =0x006A
        # => new checksum will be 0xFF95
        out_pkt = b"\x00"*12
        out_pkt += b"\x00"+b"\x00"+b"\x00"+b"\x11"+b"\x00"+b"\x00"+b"\x00"+b"\x22"
        out_pkt += b"\x00"+b"\x00"+b"\x00"+b"\x33"+b"\x00"+b"\x44"
        out_pkt += b"\x00"+b"\x00"+b"\x00"+b"\x55"+b"\x00"+b"\x00"+b"\x00"+b"\x66"
        out_pkt += b"\xFF"+b"\x95"+b"\x00"*53
        testutils.send_packet(self, ingress_port, in_pkt)
        testutils.verify_packets(self, out_pkt, [egress_port])
