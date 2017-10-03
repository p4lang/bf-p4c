import ptf
from ptf import config
import ptf.testutils as testutils
import pdb

from p4 import p4runtime_pb2
from p4.tmp import p4config_pb2
from p4.config import p4info_pb2

from base_test import P4RuntimeTest, stringify

class EcmpPITest(P4RuntimeTest):
    def common_setup(self):
        print "Setting default actions"
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id

        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        table_entry = update.entity.table_entry
        table_entry.table_id = self.get_table_id("forward")
        self.set_action_entry(table_entry, "_drop", [])

        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        table_entry = update.entity.table_entry
        table_entry.table_id = self.get_table_id("send_frame")
        self.set_action_entry(table_entry, "_drop", [])

        rep = self.stub.Write(req)

        self.requests = []

    def prog_other_ts(self, nhop = "\x0a\x00\x01\x01",
                      dmac = "\x00\x11\x11\x11\x11\x11",
                      smac = "\x00\x22\x22\x22\x22\x22",
                      eg_port = "\x00\x03"):
        print "Configuring other match-tables"

        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id

        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        table_entry = update.entity.table_entry
        table_entry.table_id = self.get_table_id("forward")
        self.set_match_key(
            table_entry, "forward",
            [self.Exact("routing_metadata.nhop_ipv4", nhop)])
        self.set_action_entry(table_entry, "set_dmac", [("dmac", dmac)])

        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        table_entry = update.entity.table_entry
        table_entry.table_id = self.get_table_id("send_frame")
        self.set_match_key(
            table_entry, "send_frame",
            [self.Exact("eg_intr_md.egress_port", eg_port)])
        self.set_action_entry(table_entry, "rewrite_mac", [("smac", smac)])

        rep = self.stub.Write(req)

        self.requests += [req]

    def common_cleanup(self):
        print "Common cleanup"
        for req in self.requests:
            for update in req.updates:
                update.type = p4runtime_pb2.Update.DELETE
            rep = self.stub.Write(req)

    def add_mbr(self, mbr_id, nhop, eg_port):
        print "Creating member", mbr_id
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id

        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        ap_member = update.entity.action_profile_member
        ap_member.action_profile_id = self.get_ap_id("ecmp_action_profile")
        ap_member.member_id = mbr_id
        self.set_action(ap_member.action, "set_nhop",
                        [("nhop_ipv4", nhop), ("port", eg_port)])

        rep = self.stub.Write(req)

        return req

    def mod_mbr(self, mbr_id, nhop, eg_port):
        print "Modifying member", mbr_id

        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id

        update = req.updates.add()
        update.type = p4runtime_pb2.Update.MODIFY
        ap_member = update.entity.action_profile_member
        ap_member.action_profile_id = self.get_ap_id("ecmp_action_profile")
        ap_member.member_id = mbr_id
        self.set_action(ap_member.action, "set_nhop",
                        [("nhop_ipv4", nhop), ("port", eg_port)])

        rep = self.stub.Write(req)

        return req

    def undo_req(self, req):
        for update in req.updates:
            update.type = p4runtime_pb2.Update.DELETE
        rep = self.stub.Write(req)

    def add_mat_entry_to_mbr(self, pref, pLen, mbr_id):
        print "Adding match entry to member", mbr_id
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id

        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        table_entry = update.entity.table_entry
        table_entry.table_id = self.get_table_id("ecmp_group")
        self.set_match_key(
            table_entry, "ecmp_group",
            [self.Lpm("ipv4.dstAddr", pref, pLen)])
        table_entry.action.action_profile_member_id = mbr_id

        rep = self.stub.Write(req)

        return req

    def add_mat_entry_to_grp(self, pref, pLen, grp_id):
        print "Adding match entry to group", grp_id
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id

        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        table_entry = update.entity.table_entry
        table_entry.table_id = self.get_table_id("ecmp_group")
        self.set_match_key(
            table_entry, "ecmp_group",
            [self.Lpm("ipv4.dstAddr", pref, pLen)])
        table_entry.action.action_profile_group_id = grp_id

        rep = self.stub.Write(req)

        return req

    def create_empty_grp(self, grp_id):
        print "Creating group", grp_id
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id

        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        ap_group = update.entity.action_profile_group
        ap_group.action_profile_id = self.get_ap_id("ecmp_action_profile")
        ap_group.group_id = grp_id
        ap_group.max_size = 32

        rep = self.stub.Write(req)

        return req

    def set_grp_members(self, grp_id, mbrs):
        print "Setting members for group", grp_id
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id

        update = req.updates.add()
        update.type = p4runtime_pb2.Update.MODIFY
        ap_group = update.entity.action_profile_group
        ap_group.action_profile_id = self.get_ap_id("ecmp_action_profile")
        ap_group.group_id = grp_id
        for mbr_id in mbrs:
            member = ap_group.members.add()
            member.member_id = mbr_id

        rep = self.stub.Write(req)

        return req

class OneMemberTest(EcmpPITest):
    """Add a member, send a packet, modify the member, send another packet"""
    def runTest(self):
        print "Running test"

        ig_port = self.swports(1)

        nhop1 = "\x0a\x00\x01\x01"
        dmac1 = "\x00\x11\x11\x11\x11\x11"
        smac1 = "\x00\x22\x22\x22\x22\x22"
        eg_port1 = self.swports(3)
        eg_port1_hex = stringify(eg_port1, 2)

        self.common_setup()
        self.prog_other_ts(nhop1, dmac1, smac1, eg_port1_hex)

        mbr1 = 1
        mbr1_req = self.add_mbr(mbr1, nhop1, eg_port1_hex)

        entry_req = self.add_mat_entry_to_mbr("\x0a\x00\x00\x00", 8, mbr1)

        pkt = testutils.simple_tcp_packet(ip_dst='10.0.0.1', ip_ttl=64)

        exp_pkt = testutils.simple_tcp_packet(
            eth_dst=dmac1, eth_src=smac1, ip_dst='10.0.0.1', ip_ttl=63)


        testutils.send_packet(self, ig_port, str(pkt))
        print "Expecting packet on port", eg_port1
        testutils.verify_packets(self, exp_pkt, [eg_port1])

        nhop2 = "\x0a\x00\x01\x02"
        dmac2 = "\x00\x11\x11\x11\x11\x00"
        smac2 = "\x00\x22\x22\x22\x22\x00"
        eg_port2 = self.swports(4)
        eg_port2_hex = stringify(eg_port2, 2)

        self.prog_other_ts(nhop2, dmac2, smac2, eg_port2_hex)
        self.mod_mbr(mbr1, nhop2, eg_port2_hex)

        exp_pkt = testutils.simple_tcp_packet(
            eth_dst=dmac2, eth_src=smac2, ip_dst='10.0.0.1', ip_ttl=63)

        testutils.send_packet(self, ig_port, str(pkt))
        print "Expecting packet on port", eg_port2
        testutils.verify_packets(self, exp_pkt, [eg_port2])

        # remove entry
        self.undo_req(entry_req)

        # remove member
        self.undo_req(mbr1_req)

        self.common_cleanup()

class OneGroupTest(EcmpPITest):
    """Test a group with one or two members"""
    def runTest(self):
        print "Running test"

        ig_port = self.swports(1)
        nhop1 = "\x0a\x00\x01\x01"
        dmac1 = "\x00\x11\x11\x11\x11\x11"
        smac1 = "\x00\x22\x22\x22\x22\x22"
        eg_port1 = self.swports(3)
        eg_port1_hex = stringify(eg_port1, 2)
        nhop2 = "\x0a\x00\x01\x02"
        dmac2 = "\x00\x11\x11\x11\x11\x00"
        smac2 = "\x00\x22\x22\x22\x22\x00"
        eg_port2 = self.swports(4)
        eg_port2_hex = stringify(eg_port2, 2)

        self.common_setup()
        self.prog_other_ts(nhop1, dmac1, smac1, eg_port1_hex)
        self.prog_other_ts(nhop2, dmac2, smac2, eg_port2_hex)

        mbr1 = 1
        mbr1_req = self.add_mbr(mbr1, nhop1, eg_port1_hex)
        mbr2 = 2
        mbr2_req = self.add_mbr(mbr2, nhop2, eg_port2_hex)

        grp = 1
        grp_req = self.create_empty_grp(grp)

        self.set_grp_members(grp, [mbr1])

        entry_req = self.add_mat_entry_to_grp("\x0a\x00\x00\x00", 8, grp)

        pkt = testutils.simple_tcp_packet(ip_dst='10.0.0.1', ip_ttl=64)

        print "Checking with a single member"
        exp_pkt = testutils.simple_tcp_packet(
            eth_dst=dmac1, eth_src=smac1, ip_dst='10.0.0.1', ip_ttl=63)

        testutils.send_packet(self, ig_port, str(pkt))
        print "Expecting packet on port", eg_port1
        testutils.verify_packets(self, exp_pkt, [eg_port1])

        self.set_grp_members(grp, [mbr1, mbr2])

        print "Checking load-balancing between 2 members"
        npkts = 20
        counts = [0, 0]
        for i in xrange(npkts):
            ip_src = "192.168.0.{}".format(i)
            pkt = testutils.simple_tcp_packet(
                ip_src=ip_src, ip_dst='10.0.0.1', ip_ttl=64)
            exp_pkt1 = testutils.simple_tcp_packet(
                eth_dst=dmac1, eth_src=smac1,
                ip_src=ip_src, ip_dst='10.0.0.1', ip_ttl=63)
            exp_pkt2 = testutils.simple_tcp_packet(
                eth_dst=dmac2, eth_src=smac2,
                ip_src=ip_src, ip_dst='10.0.0.1', ip_ttl=63)
            testutils.send_packet(self, ig_port, str(pkt))
            eg_idx = testutils.verify_any_packet_any_port(
                self, pkts=[exp_pkt1, exp_pkt2], ports=[eg_port1, eg_port2])
            counts[eg_idx] += 1
        self.assertTrue(counts[0] >= npkts / 4)
        self.assertTrue(counts[1] >= npkts / 4)
        self.assertTrue(counts[0] + counts[1] == npkts)

        self.set_grp_members(grp, [mbr2])

        pkt = testutils.simple_tcp_packet(ip_dst='10.0.0.1', ip_ttl=64)

        print "Checking after removing a member"
        exp_pkt = testutils.simple_tcp_packet(
            eth_dst=dmac2, eth_src=smac2, ip_dst='10.0.0.1', ip_ttl=63)

        testutils.send_packet(self, ig_port, str(pkt))
        print "Expecting packet on port", eg_port2
        testutils.verify_packets(self, exp_pkt, [eg_port2])

        # remove entry
        self.undo_req(entry_req)

        self.undo_req(grp_req)

        # remove member
        self.undo_req(mbr1_req)
        self.undo_req(mbr2_req)

        self.common_cleanup()
