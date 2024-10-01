import ptf
from ptf import config
import ptf.testutils as testutils
import pdb

from p4.v1 import p4runtime_pb2
from p4.tmp import p4config_pb2
from p4.config.v1 import p4info_pb2

from p4runtime_base_tests import P4RuntimeTest, stringify, autocleanup

class EcmpPITest(P4RuntimeTest):
    def common_setup(self):
        print("Setting default actions")
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        # default entries
        self.push_update_add_entry_to_action(req, "forward", None, "_drop", [])
        self.push_update_add_entry_to_action(
            req, "send_frame", None, "_drop", [])
        # autocleanup not supported yet for default entries
        self.write_request(req, store=False)

    def prog_other_ts(self, nhop = "\x0a\x00\x01\x01",
                      dmac = "\x00\x11\x11\x11\x11\x11",
                      smac = "\x00\x22\x22\x22\x22\x22",
                      eg_port = "\x00\x03"):
        print("Configuring other match-tables")
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.push_update_add_entry_to_action(
            req, "forward", [self.Exact("routing_metadata.nhop_ipv4", nhop)],
            "set_dmac", [("dmac", dmac)])
        self.push_update_add_entry_to_action(
            req, "send_frame", [self.Exact("eg_intr_md.egress_port", eg_port)],
            "rewrite_mac", [("smac", smac)])
        self.write_request(req)

    def add_mbr(self, mbr_id, nhop, eg_port):
        print("Creating member", mbr_id)
        self.send_request_add_member(
            "ecmp_action_profile", mbr_id,
            "set_nhop", [("nhop_ipv4", nhop), ("port", eg_port)])

    def mod_mbr(self, mbr_id, nhop, eg_port):
        print("Modifying member", mbr_id)
        self.send_request_modify_member(
            "ecmp_action_profile", mbr_id,
            "set_nhop", [("nhop_ipv4", nhop), ("port", eg_port)])

    def add_mat_entry_to_mbr(self, pref, pLen, mbr_id):
        print("Adding match entry to member", mbr_id)
        self.send_request_add_entry_to_member(
            "ecmp_group", [self.Lpm("ipv4.dstAddr", pref, pLen)], mbr_id)

    def add_mat_entry_to_grp(self, pref, pLen, grp_id):
        print("Adding match entry to group", grp_id)
        self.send_request_add_entry_to_group(
            "ecmp_group", [self.Lpm("ipv4.dstAddr", pref, pLen)], grp_id)

    def create_empty_grp(self, grp_id):
        print("Creating group", grp_id)
        self.send_request_add_group("ecmp_action_profile", grp_id)

    def set_grp_members(self, grp_id, mbrs):
        print("Setting members for group", grp_id)
        self.send_request_set_group_membership(
            "ecmp_action_profile", grp_id, mbrs)

class OneMemberTest(EcmpPITest):
    """Add a member, send a packet, modify the member, send another packet"""
    @autocleanup
    def runTest(self):
        ig_port = self.swports(0)

        nhop1 = "\x0a\x00\x01\x01"
        dmac1 = "\x00\x11\x11\x11\x11\x11"
        smac1 = "\x00\x22\x22\x22\x22\x22"
        eg_port1 = self.swports(2)
        eg_port1_hex = stringify(eg_port1, 2)

        self.common_setup()
        self.prog_other_ts(nhop1, dmac1, smac1, eg_port1_hex)

        mbr1 = 1
        self.add_mbr(mbr1, nhop1, eg_port1_hex)

        self.add_mat_entry_to_mbr("\x0a\x00\x00\x00", 8, mbr1)

        pkt = testutils.simple_tcp_packet(ip_dst='10.0.0.1', ip_ttl=64)

        exp_pkt = testutils.simple_tcp_packet(
            eth_dst=dmac1, eth_src=smac1, ip_dst='10.0.0.1', ip_ttl=63)

        testutils.send_packet(self, ig_port, pkt)
        print("Expecting packet on port", eg_port1)
        testutils.verify_packets(self, exp_pkt, [eg_port1])

        nhop2 = "\x0a\x00\x01\x02"
        dmac2 = "\x00\x11\x11\x11\x11\x00"
        smac2 = "\x00\x22\x22\x22\x22\x00"
        eg_port2 = self.swports(3)
        eg_port2_hex = stringify(eg_port2, 2)

        self.prog_other_ts(nhop2, dmac2, smac2, eg_port2_hex)
        self.mod_mbr(mbr1, nhop2, eg_port2_hex)

        exp_pkt = testutils.simple_tcp_packet(
            eth_dst=dmac2, eth_src=smac2, ip_dst='10.0.0.1', ip_ttl=63)

        testutils.send_packet(self, ig_port, pkt)
        print("Expecting packet on port", eg_port2)
        testutils.verify_packets(self, exp_pkt, [eg_port2])

class OneGroupTest(EcmpPITest):
    """Test a group with one or two members"""
    @autocleanup
    def runTest(self):
        ig_port = self.swports(0)
        nhop1 = "\x0a\x00\x01\x01"
        dmac1 = "\x00\x11\x11\x11\x11\x11"
        smac1 = "\x00\x22\x22\x22\x22\x22"
        eg_port1 = self.swports(2)
        eg_port1_hex = stringify(eg_port1, 2)
        nhop2 = "\x0a\x00\x01\x02"
        dmac2 = "\x00\x11\x11\x11\x11\x00"
        smac2 = "\x00\x22\x22\x22\x22\x00"
        eg_port2 = self.swports(3)
        eg_port2_hex = stringify(eg_port2, 2)

        self.common_setup()
        self.prog_other_ts(nhop1, dmac1, smac1, eg_port1_hex)
        self.prog_other_ts(nhop2, dmac2, smac2, eg_port2_hex)

        mbr1 = 1
        self.add_mbr(mbr1, nhop1, eg_port1_hex)
        mbr2 = 2
        self.add_mbr(mbr2, nhop2, eg_port2_hex)

        grp = 1
        self.create_empty_grp(grp)
        self.set_grp_members(grp, [mbr1])

        self.add_mat_entry_to_grp("\x0a\x00\x00\x00", 8, grp)

        pkt = testutils.simple_tcp_packet(ip_dst='10.0.0.1', ip_ttl=64)

        print("Checking with a single member")
        exp_pkt = testutils.simple_tcp_packet(
            eth_dst=dmac1, eth_src=smac1, ip_dst='10.0.0.1', ip_ttl=63)

        testutils.send_packet(self, ig_port, pkt)
        print("Expecting packet on port", eg_port1)
        testutils.verify_packets(self, exp_pkt, [eg_port1])

        self.set_grp_members(grp, [mbr1, mbr2])

        print("Checking load-balancing between 2 members")
        npkts = 20
        counts = [0, 0]
        for i in range(npkts):
            ip_src = "192.168.0.{}".format(i)
            pkt = testutils.simple_tcp_packet(
                ip_src=ip_src, ip_dst='10.0.0.1', ip_ttl=64)
            exp_pkt1 = testutils.simple_tcp_packet(
                eth_dst=dmac1, eth_src=smac1,
                ip_src=ip_src, ip_dst='10.0.0.1', ip_ttl=63)
            exp_pkt2 = testutils.simple_tcp_packet(
                eth_dst=dmac2, eth_src=smac2,
                ip_src=ip_src, ip_dst='10.0.0.1', ip_ttl=63)
            testutils.send_packet(self, ig_port, pkt)
            eg_idx = testutils.verify_any_packet_any_port(
                self, pkts=[exp_pkt1, exp_pkt2], ports=[eg_port1, eg_port2])
            counts[eg_idx] += 1
        self.assertTrue(counts[0] >= npkts / 4)
        self.assertTrue(counts[1] >= npkts / 4)
        self.assertTrue(counts[0] + counts[1] == npkts)

        self.set_grp_members(grp, [mbr2])

        pkt = testutils.simple_tcp_packet(ip_dst='10.0.0.1', ip_ttl=64)

        print("Checking after removing a member")
        exp_pkt = testutils.simple_tcp_packet(
            eth_dst=dmac2, eth_src=smac2, ip_dst='10.0.0.1', ip_ttl=63)

        testutils.send_packet(self, ig_port, pkt)
        print("Expecting packet on port", eg_port2)
        testutils.verify_packets(self, exp_pkt, [eg_port2])
