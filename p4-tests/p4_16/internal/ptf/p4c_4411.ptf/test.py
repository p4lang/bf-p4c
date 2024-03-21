import logging
import time
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils
from ptf.packet import *

from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify, ipv4_to_binary, mac_to_binary


logger = logging.getLogger('p4c_4411')
logger.addHandler(logging.StreamHandler())

class Test_p4c_4411(P4RuntimeTest):
   @autocleanup
   def runTest(self):
        ingress_port = self.swports(0)
        egress_port  = self.swports(2)

        # Config (add rule for in_pkt_t3_exit to not exit on t1)
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.push_update_add_entry_to_action(
            req,
            'ingress.t1',
            [self.Exact("hdr.hdr1.v0", stringify(0x00020002, 4))],
            'setall1',[])
        self.write_request(req)
    
        # first header + v0, v1 = 0x00010001 + checksum + extra data
        in_pkt_t1_exit = b"\x00"*4 + (b"\x00"+b"\x01")*4 + (b"\xFF"+b"\xFB") + b"\x00"*61
        in_pkt_t3_exit = b"\x00"*4 + (b"\x00"+b"\x02")*4 + (b"\xFF"+b"\xF7") + b"\x00"*61
        # first packet should exit after t1 => v0 and v1 are replaced by 0x11 and 0x22
        out_pkt_t1_exit = b"\x00"*4 + (b"\x00"+b"\x00"+b"\x00"+b"\x11") + (b"\x00"+b"\x00"+b"\x00"+b"\x22") + (b"\xFF"+b"\xCC") + b"\x00"*61
        # second packet should exit after t3 => v0 and v1 are replaced by 0x44 and 0x55
        out_pkt_t3_exit = b"\x00"*4 + (b"\x00"+b"\x00"+b"\x00"+b"\x44") + (b"\x00"+b"\x00"+b"\x00"+b"\x55") + (b"\xFF"+b"\x66") + b"\x00"*61
        testutils.send_packet(self, ingress_port, in_pkt_t1_exit)
        testutils.verify_packets(self, out_pkt_t1_exit, [egress_port])
        testutils.send_packet(self, ingress_port, in_pkt_t3_exit)
        testutils.verify_packets(self, out_pkt_t3_exit, [egress_port])