import ptf
import os
from ptf import config
import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2
from p4.tmp import p4config_pb2
from p4.config.v1 import p4info_pb2
import google.protobuf.text_format

from p4runtime_base_tests import P4RuntimeTest, stringify, autocleanup, skip_on_hw

class FullTest(P4RuntimeTest):
    def runCommonTest(self, proto_entries):
        p4runtime_request_path = os.path.join(
            os.path.dirname(os.path.realpath(__file__)), proto_entries)
        print "Loading entries from proto file", p4runtime_request_path
        p4runtime_request = p4runtime_pb2.WriteRequest()
        with open(p4runtime_request_path, "r") as fin:
            google.protobuf.text_format.Merge(fin.read(), p4runtime_request)
        print "Sending request to switch"
        response = self.write_request(p4runtime_request)

        h1_eth  = "EE:61:23:BC:E5:00"
        h1_ip   = "172.24.111.1"
        h2_eth  = "EE:30:CA:9D:1E:00"
        h2_ip   = "172.24.112.1"
        sw1_eth = "EE:CD:00:7E:70:01"
        sw2_eth = "EE:CD:00:7E:70:00"

        # test L3 connectivity h1 -> h2

        pkt_h1_to_h2 = testutils.simple_tcp_packet(
            eth_dst = sw1_eth, eth_src = h1_eth,
            ip_src = h1_ip, ip_dst = h2_ip,
            ip_ttl = 64)

        exp_pkt_h1_to_h2 = testutils.simple_tcp_packet(
            eth_dst = h2_eth, eth_src = sw2_eth,
            ip_src = h1_ip, ip_dst = h2_ip,
            ip_ttl = 63)

        port1 = self.swports(1)
        port2 = self.swports(2)

        testutils.send_packet(self, port1, str(pkt_h1_to_h2))
        testutils.verify_packet(self, exp_pkt_h1_to_h2, port2)

        # test L3 connectivity h2 -> h1

        pkt_h2_to_h1 = testutils.simple_tcp_packet(
            eth_dst = sw2_eth, eth_src = h2_eth,
            ip_src = h2_ip, ip_dst = h1_ip,
            ip_ttl = 64)

        exp_pkt_h2_to_h1 = testutils.simple_tcp_packet(
            eth_dst = h1_eth, eth_src = sw1_eth,
            ip_src = h2_ip, ip_dst = h1_ip,
            ip_ttl = 63)

        testutils.send_packet(self, port2, str(pkt_h2_to_h1))
        testutils.verify_packet(self, exp_pkt_h2_to_h1, port1)

        testutils.verify_no_other_packets(self)

@skip_on_hw
class FullTestGroups(FullTest):
    @autocleanup
    def runTest(self):
        # Pick entries from 'tor.ptf/write_lpm_entries.pb.txt'
        self.runCommonTest("write_lpm_entries.pb.txt")

@skip_on_hw
class FullTestMembersOnly(FullTest):
    @autocleanup
    def runTest(self):
        # Pick entries from 'tor.ptf/write_lpm_entries_members_only.pb.txt'
        self.runCommonTest("write_lpm_entries_members_only.pb.txt")

class HashDistributionTest(P4RuntimeTest):
    ap_name = "l3_fwd.wcmp_action_profile"

    def add_member(self, mbr_id, eg_port, smac, dmac):
        print "Creating member", mbr_id
        eg_port_str = stringify(eg_port, 2)
        self.send_request_add_member(
            self.ap_name, mbr_id, "l3_fwd.set_nexthop",
            [("port", eg_port_str), ("smac", smac), ("dmac", dmac)])

    def add_group(self, grp_id):
        print "Creating group", grp_id
        self.send_request_add_group(self.ap_name, grp_id)

    def set_group_membership(self, grp_id, mbr_ids = []):
        print "Setting members for group", grp_id
        self.send_request_set_group_membership(self.ap_name, grp_id, mbr_ids)

    def add_entry_to_group(self, mac, pref, pLen, grp_id):
        print "Adding match entry to group", grp_id
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.push_update_add_entry_to_action(
            req, "l3_fwd.l3_routing_classifier_table",
            [self.Exact("hdr.ethernet.dst_addr", mac)], "NoAction", [])
        self.push_update_add_entry_to_group(
            req, "l3_fwd.l3_ipv4_override_table",
            [self.Lpm("hdr.ipv4_base.dst_addr", pref, pLen)], grp_id)
        self.write_request(req)

    @autocleanup
    def runTest(self):
        ig_port = self.swports(3)
        mbr1, port1 = 1, self.swports(1)
        mbr2, port2 = 2, self.swports(2)
        smac = "\xee\xcd\x00\x7e\x70\x00"
        dmac = "\xee\x30\xca\x9d\x1e\x00"
        self.add_member(mbr1, port1, smac, dmac)
        self.add_member(mbr2, port2, smac, dmac)
        grp = 3
        self.add_group(grp)
        self.set_group_membership(grp, [mbr1, mbr2])
        ip_src = "10.0.0.2"
        ip_dst = "10.0.0.1"
        ip_dst_str = "\x0a\x00\x00\x01"
        self.add_entry_to_group(smac, ip_dst_str, 32, grp)
        npkts = 30
        counts = [0, 0]
        tcp_dport = 5001
        for i in xrange(npkts):
            tcp_sport = 4001 + i
            pkt = testutils.simple_tcp_packet(
                eth_dst = smac, ip_src = ip_src, ip_dst = ip_dst, ip_ttl = 64,
                tcp_sport = tcp_sport, tcp_dport = tcp_dport)
            exp_pkt = testutils.simple_tcp_packet(
                eth_dst = dmac, eth_src = smac,
                ip_src = ip_src, ip_dst = ip_dst, ip_ttl = 63,
                tcp_sport = tcp_sport, tcp_dport = tcp_dport)
            testutils.send_packet(self, ig_port, str(pkt))
            port_index, _ = testutils.verify_packet_any_port(
                self, exp_pkt, [port1, port2])
            counts[port_index] += 1
        print "Port counts :", counts
        freqs = [1. * c / npkts for c in counts]
        print "Port frequencies :", freqs
        for c in counts:
            self.assertGreater(c, npkts / 4)

class PacketOutTest(P4RuntimeTest):
    def runTest(self):
        # We test the case where the packet is skipping ingress & egress
        # (i.e. submit_to_ingress == 0)
        port3 = self.swports(3)
        port3_hex = stringify(port3, 2)
        payload = 'a' * 20
        packet_out = p4runtime_pb2.PacketOut()
        packet_out.payload = payload
        egress_physical_port = packet_out.metadata.add()
        egress_physical_port.metadata_id = 1
        egress_physical_port.value = port3_hex
        submit_to_ingress = packet_out.metadata.add()
        submit_to_ingress.metadata_id = 2
        submit_to_ingress.value = "\x00"  # false

        self.send_packet_out(packet_out)

        testutils.verify_packet(self, payload, port3)
        testutils.verify_no_other_packets(self)

class PacketOutTestCheckSkipIngress(P4RuntimeTest):
    @autocleanup
    def runTest(self):
        # We test the case where the packet is skipping ingress & egress
        # (i.e. submit_to_ingress == 0)
        port3 = self.swports(3)
        port3_hex = stringify(port3, 2)
        payload = 'a' * 20
        packet_out = p4runtime_pb2.PacketOut()
        packet_out.payload = payload
        egress_physical_port = packet_out.metadata.add()
        egress_physical_port.metadata_id = 1
        egress_physical_port.value = port3_hex
        submit_to_ingress = packet_out.metadata.add()
        submit_to_ingress.metadata_id = 2
        submit_to_ingress.value = "\x00"  # false

        # add an entry to punt the packet to CPU, in order to check that ingress
        # is actually skipped
        mask = "\x01\xff"
        self.send_request_add_entry_to_action(
            "punt.punt_table",
            [self.Ternary("standard_metadata.egress_spec", port3_hex, mask)],
            "punt.set_queue_and_send_to_cpu", [("queue_id", "\x01")])

        for i in xrange(3):
            self.send_packet_out(packet_out)
            testutils.verify_packet(self, payload, port3)
        testutils.verify_no_other_packets(self)

class PacketInTest(P4RuntimeTest):
    @autocleanup
    def runTest(self):
        # Add an entry to punt table which says that all packets coming on port
        # 3 should be sent to CPU
        port3 = self.swports(3)
        port3_hex = stringify(port3, 2)
        mask = "\x01\xff"
        self.send_request_add_entry_to_action(
            "punt.punt_table",
            [self.Ternary("standard_metadata.ingress_port", port3_hex, mask)],
            "punt.set_queue_and_send_to_cpu", [("queue_id", "\x01")])

        payload = 'a' * 64
        for i in xrange(3):
            testutils.send_packet(self, port3, payload)
            packet_in = self.get_packet_in()
            self.assertEqual(packet_in.payload, payload)
            ingress_physical_port = None
            for metadata in packet_in.metadata:
                if metadata.metadata_id == 1:
                    ingress_physical_port = metadata.value
                    break
            self.assertEqual(ingress_physical_port, port3_hex)
