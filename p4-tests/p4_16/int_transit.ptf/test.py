import ptf.testutils as testutils
from ptf.mask import Mask

from p4.v1 import p4runtime_pb2

from p4runtime_base_tests import P4RuntimeTest, autocleanup
from p4runtime_base_tests import stringify, ipv4_to_binary, mac_to_binary

import scapy.main
scapy.main.load_contrib("xnt")
INT_META_HDR = scapy.contrib.xnt.INT_META_HDR
INT_L45_HEAD = scapy.contrib.xnt.INT_L45_HEAD
INT_L45_TAIL = scapy.contrib.xnt.INT_L45_TAIL

class IntTransitTest(P4RuntimeTest):
    @autocleanup
    def runTest(self):
        port2 = self.swports(2)

        self.send_request_add_entry_to_action(
            "int_egress.int_prep", None, "int_egress.int_transit",
            [("switch_id", stringify(1, 4))])

        for i in xrange(16):
            base = "int_set_header_0003_i"
            mf = self.Exact("hdr.int_header.instruction_mask_0003",
                            stringify(i, 1))
            action = "int_metadata_insert." + base + str(i)
            self.send_request_add_entry_to_action(
                "int_metadata_insert.int_inst_0003", [mf],
                action, [])
        for i in xrange(16):
            base = "int_set_header_0407_i"
            mf = self.Exact("hdr.int_header.instruction_mask_0407",
                            stringify(i, 1))
            action = "int_metadata_insert." + base + str(i)
            self.send_request_add_entry_to_action(
                "int_metadata_insert.int_inst_0407", [mf],
                action, [])

        # int_type=hop-by-hop
        int_shim = INT_L45_HEAD(int_type=1, length=4)
        # The INT_META_HDR in scapy is not up-to-date, it is still on v0.5, so
        # I'm using a binary string to build the header
        # ins_cnt: 5 = switch id + ports + q occupancy + ig port + eg port)
        # remaining_hop_count: 3
        # instruction_mask_0003: 0xd = switch id (0), ports (1), q occupancy (3)
        # instruction_mask_0407: 0xc = ig timestamp (4), eg timestamp (5)
        int_header = "\x00\x00\x05\x03\xdc\x00\x00\x00"
        # IP proto (UDP), UDP dport (4096)
        int_tail = INT_L45_TAIL(next_proto=17, proto_param=4096)
        payload = "\xab" * 128
        pkt = Ether() /\
              IP(tos=0x04) /\
              UDP(dport=4096, chksum=0) /\
              int_shim /\
              int_header /\
              int_tail /\
              payload

        exp_int_shim = INT_L45_HEAD(int_type=1, length=9)
        # remaining_hop_count: 2
        exp_int_header = "\x00\x00\x05\x02\xdc\x00\x00\x00"
        # switch id: 1
        exp_int_metadata = "\x00\x00\x00\x01"
        # ig port: port2, eg port: port2
        exp_int_metadata += stringify(port2, 2) + stringify(port2, 2)
        # q id: 0, q occupancy: ?
        exp_int_metadata += "\x00\x00\x00\x00"
        # ig timestamp: ?
        # eg timestamp: ?
        exp_int_metadata += "\x00\x00\x00\x00" * 2
        exp_pkt = Ether() /\
                  IP(tos=0x04) /\
                  UDP(dport=4096, chksum=0) /\
                  exp_int_shim /\
                  exp_int_header /\
                  exp_int_metadata /\
                  int_tail /\
                  payload
        # We mask off the timestamps as well as the queue occupancy
        exp_pkt = Mask(exp_pkt)
        offset_metadata = 14 + 20 + 8 + 4 + 8
        exp_pkt.set_do_not_care((offset_metadata + 9) * 8, 11 * 8)
        testutils.send_packet(self, port2, str(pkt))
        testutils.verify_packets(self, exp_pkt, [port2])
