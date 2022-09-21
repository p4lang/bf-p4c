import logging
import time
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils
from ptf.packet import *

from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify, ipv4_to_binary, mac_to_binary

logger = logging.getLogger('p4c-4742')
logger.addHandler(logging.StreamHandler())

class Test_P4C_4742(P4RuntimeTest):
   @autocleanup
   def runTest(self):
      def createPacket(direction, payload_type, opt, csum):
         eth = b"\x01"*6 + b"\x02"*6 + b"\x08\x00"
         ip  = b"\x00"*9 + b"\x06" + b"\x00"*10
         tcp = b"\x00"*12
         if opt == 0:
            tcp += b"\x50"
         elif opt == 64:
            tcp += b"\x70"
         elif opt == 128:
            tcp += b"\x90"
         elif opt == 320:
            tcp += b"\xF0"
         tcp += b"\x00"*3 + csum
         if direction == "in":
            tcp += b"\x00\x11"
         elif direction == "out":
            tcp += b"\x11\x00"
         if opt >= 64:
            if direction == "in":
               tcp += b"\x10"+b"\x00"+b"\x10"+b"\x00"+b"\x20"+b"\x00"+b"\x20"+b"\x00"
            elif direction == "out":
               tcp += b"\x01"+b"\x00"+b"\x01"+b"\x00"+b"\x02"+b"\x00"+b"\x02"+b"\x00"
         if opt >= 128:
            if direction == "in":
               tcp += b"\x30"+b"\x00"+b"\x30"+b"\x00"+b"\x40"+b"\x00"+b"\x40"+b"\x00"
            elif direction == "out":
               tcp += b"\x03"+b"\x00"+b"\x03"+b"\x00"+b"\x04"+b"\x00"+b"\x04"+b"\x00"
         if opt >= 192:
            if direction == "in":
               tcp += b"\x50"+b"\x00"+b"\x50"+b"\x00"+b"\x60"+b"\x00"+b"\x60"+b"\x00"
            elif direction == "out":
               tcp += b"\x05"+b"\x00"+b"\x05"+b"\x00"+b"\x06"+b"\x00"+b"\x06"+b"\x00"
         if opt >= 256:
            if direction == "in":
               tcp += b"\x70"+b"\x00"+b"\x70"+b"\x00"+b"\x80"+b"\x00"+b"\x80"+b"\x00"
            elif direction == "out":
               tcp += b"\x07"+b"\x00"+b"\x07"+b"\x00"+b"\x08"+b"\x00"+b"\x08"+b"\x00"
         if opt >= 320:
            if direction == "in":
               tcp += b"\x90"+b"\x00"+b"\x90"+b"\x00"+b"\xA0"+b"\x00"+b"\xA0"+b"\x00"
            elif direction == "out":
               tcp += b"\x09"+b"\x00"+b"\x09"+b"\x00"+b"\x0A"+b"\x00"+b"\x0A"+b"\x00"
         if payload_type != "some_payload":
            payload = b"\x01"+b"\x02"
         else:
            payload = b"\x05"+b"\x06"
         if payload_type == "payload" and direction == "out":
            payload += b"\x00\x22"
         else:
            payload += b"\x44\x00"
         payload += b"\x17\x00"*7 + b"\x11"*8
         pkt = eth + ip + tcp + payload
         return pkt
         
      ingress_port_payload = self.swports(0)
      ingress_port_some_payload = self.swports(1)
      ingress_port_get_before = self.swports(2)
      ingress_port_no_payload = self.swports(3)
      egress_port  = self.swports(2)

      # 5017 + 44 -> AFA4
      # Input packets
      in_pkt_no_opt = createPacket("in", False, 0, b"\x00\x00")
      in_pkt_64_opt = createPacket("in", False, 64, b"\x00\x00")
      in_pkt_128_opt = createPacket("in", False, 128, b"\x00\x00")
      in_pkt_320_opt = createPacket("in", False, 320, b"\x00\x00")
      # Expected output packets
      # We start from csum 0
      # TCP urgent pointer change = +10EF
      # 1. tcp opt = -1E00
      # 2. tcp opt = -3C00
      # => total for 64b opt = -5A00
      # 3. tcp opt = -5A00
      # 4. tcp opt = -7800
      # => total for 128b opt = -2C01
      # 5. tcp opt = -9600
      # 6. tcp opt = -B400
      # 7. tcp opt = -D200
      # 8. tcp opt = -F000
      # 9. tcp opt = -0E01
      # 10. tcp opt = -2C01
      # => total for 320b opt = -7206
      # payload = -43DE
      # some payload = 0506
      # some payload with subtract = 0305
      # CSUM total = +10EF => csum will be EF10
      out_pkt_no_opt = createPacket("out", "none", 0, b"\xEF\x10")
      # CSUM total = 10EF - 5A00 = -4911 => csum will be 4911
      out_pkt_64_opt = createPacket("out", "none", 64, b"\x49\x11")
      # CSUM total = 10EF - 2C01 = -1B12 => csum will be 1B12
      out_pkt_128_opt = createPacket("out", "none", 128, b"\x1B\x12")
      # CSUM total = 10EF - 7206 = -6117 => csum will be 6117
      out_pkt_320_opt = createPacket("out", "none", 320, b"\x61\x17")
      # CSUM total = 10EF - 43DE = -32EF => csum will be 32EF
      out_pkt_no_opt_payload = createPacket("out", "payload", 0, b"\x32\xEF")
      # CSUM total = 10EF - 5A00 - 43DE = -8CEF => csum will be 8CEF
      out_pkt_64_opt_payload = createPacket("out", "payload", 64, b"\x8C\xEF")
      # CSUM total = 10EF - 2C01 - 43DE = -5EF0 => csum will be 5EF0
      out_pkt_128_opt_payload = createPacket("out", "payload", 128, b"\x5E\xF0")
      # CSUM total = 10EF - 7206 - 43DE = -A4F5 => csum will be A4F5
      out_pkt_320_opt_payload = createPacket("out", "payload", 320, b"\xA4\xF5")
      # CSUM total = 10EF + 0506 = 15F5 => csum will be EA0A
      out_pkt_no_opt_some_payload = createPacket("out", "some_payload", 0, b"\xEA\x0A")
      # CSUM total = 10EF - 7206 + 0506 = -5C11 => csum will be 5C11
      out_pkt_320_opt_some_payload = createPacket("out", "some_payload", 320, b"\x5C\x11")
      # CSUM total = 10EF + 0305 = 13F4 => csum will be EC0B
      out_pkt_no_opt_get_before = createPacket("out", "some_payload", 0, b"\xEC\x0B")
      # CSUM total = 10EF - 7206 + 0305 = -5E12 => csum will be 5E12
      out_pkt_320_opt_get_before = createPacket("out", "some_payload", 320, b"\x5E\x12")

      # Packets that will not have the payload parsed (sent to other port)
      testutils.send_packet(self, ingress_port_no_payload, in_pkt_no_opt)
      testutils.verify_packets(self, out_pkt_no_opt, [egress_port])
      testutils.send_packet(self, ingress_port_no_payload, in_pkt_64_opt)
      testutils.verify_packets(self, out_pkt_64_opt, [egress_port])
      testutils.send_packet(self, ingress_port_no_payload, in_pkt_128_opt)
      testutils.verify_packets(self, out_pkt_128_opt, [egress_port])
      testutils.send_packet(self, ingress_port_no_payload, in_pkt_320_opt)
      testutils.verify_packets(self, out_pkt_320_opt, [egress_port])

      # Packets that will have payload parsed (sent to port 0)
      testutils.send_packet(self, ingress_port_payload, in_pkt_no_opt)
      testutils.verify_packets(self, out_pkt_no_opt_payload, [egress_port])
      testutils.send_packet(self, ingress_port_payload, in_pkt_64_opt)
      testutils.verify_packets(self, out_pkt_64_opt_payload, [egress_port])
      testutils.send_packet(self, ingress_port_payload, in_pkt_128_opt)
      testutils.verify_packets(self, out_pkt_128_opt_payload, [egress_port])
      testutils.send_packet(self, ingress_port_payload, in_pkt_320_opt)
      testutils.verify_packets(self, out_pkt_320_opt_payload, [egress_port])

      # Packets that have some payload parsed and then get is called (port 1)
      testutils.send_packet(self, ingress_port_some_payload, in_pkt_no_opt)
      testutils.verify_packets(self, out_pkt_no_opt_some_payload, [egress_port])
      testutils.send_packet(self, ingress_port_some_payload, in_pkt_320_opt)
      testutils.verify_packets(self, out_pkt_320_opt_some_payload, [egress_port])

      # Packets that have some payload parsed after the get was called (port 2)
      testutils.send_packet(self, ingress_port_get_before, in_pkt_no_opt)
      testutils.verify_packets(self, out_pkt_no_opt_get_before, [egress_port])
      testutils.send_packet(self, ingress_port_get_before, in_pkt_320_opt)
      testutils.verify_packets(self, out_pkt_320_opt_get_before, [egress_port])