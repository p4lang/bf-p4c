import ptf
import os
from ptf import config
import ptf.testutils as testutils

from p4 import p4runtime_pb2
from p4.tmp import p4config_pb2
from p4.config import p4info_pb2
import google.protobuf.text_format

from base_test import P4RuntimeTest, autocleanup
from base_test import stringify, ipv4_to_binary, mac_to_binary 

FORWARDING_TYPE_BRIDGING = 2
FORWARDING_TYPE_UNICAST_IPV4 = 2

SWITCH_MAC = "00:00:00:00:aa:01"
HOST1_MAC = "00:00:00:00:00:01"
HOST2_MAC = "00:00:00:00:00:02"
HOST3_MAC = "00:00:00:00:00:03"
HOST1_IPV4 = "10.0.1.1"
HOST2_IPV4 = "10.0.2.1"

class FabricTest(P4RuntimeTest):
    def setUp(self):
        super(FabricTest, self).setUp()
        self.port1 = self.swports(1)
        self.port2 = self.swports(2)
        self.port3 = self.swports(3)

    def set_internal_vlan(self, ingress_port, vlan_valid = False,
                          vlan_id = 0, vlan_id_mask = 0,
                          new_vlan_id = 0):
        ingress_port_ = stringify(ingress_port, 2)
        vlan_valid_ = '\x01' if vlan_valid else '\x00'
        vlan_id_ = stringify(vlan_id, 2)
        vlan_id_mask_ = stringify(vlan_id_mask, 2)
        new_vlan_id_ = stringify(new_vlan_id, 2)
        self.send_request_add_entry_to_action(
            "filtering.ingress_port_vlan",
            [self.Exact("standard_metadata.ingress_port", ingress_port_),
             self.Exact("hdr.vlan_tag.is_valid", vlan_valid_),
             self.Ternary("hdr.vlan_tag.vlan_id", vlan_id_, vlan_id_mask_)],
            "filtering.push_internal_vlan", [("new_vlan_id", new_vlan_id_)])

    def set_forwarding_type(self, ingress_port, eth_dstAddr, ethertype = 0x800,
                            fwd_type = FORWARDING_TYPE_UNICAST_IPV4):
        ingress_port_ = stringify(ingress_port, 2)
        eth_dstAddr_ = mac_to_binary(eth_dstAddr)
        ethertype_ = stringify(ethertype, 2)
        fwd_type_ = stringify(fwd_type, 1)
        self.send_request_add_entry_to_action(
            "filtering.fwd_classifier",
            [self.Exact("standard_metadata.ingress_port", ingress_port_),
             self.Exact("hdr.ethernet.dst_addr", eth_dstAddr_),
             self.Exact("fabric_metadata.original_ether_type", ethertype_)],
            "filtering.set_forwarding_type", [("fwd_type", fwd_type_)])

    def add_bridging_entry(self, vlan_id, eth_dstAddr, eth_dstAddr_mask,
                           next_id):
        vlan_id_ = stringify(vlan_id, 2)
        eth_dstAddr_ = mac_to_binary(eth_dstAddr)
        eth_dstAddr_mask_ = mac_to_binary(eth_dstAddr_mask)
        next_id_ = stringify(next_id, 4)
        self.send_request_add_entry_to_action(
            "forwarding.bridging",
            [self.Exact("hdr.vlan_tag.vlan_id", vlan_id_),
             self.Ternary("hdr.ethernet.dst_addr",
                          eth_dstAddr_, eth_dstAddr_mask_)],
            "forwarding.set_next_id", [("next_id", next_id_)])

    def add_forwarding_unicast_v4_entry(self, ipv4_dstAddr, ipv4_pLen,
                                        next_id):
        ipv4_dstAddr_ = ipv4_to_binary(ipv4_dstAddr)
        next_id_ = stringify(next_id, 4)
        self.send_request_add_entry_to_action(
            "forwarding.unicast_v4",
            [self.Lpm("hdr.ipv4.dst_addr", ipv4_dstAddr_, ipv4_pLen)],
            "forwarding.set_next_id", [("next_id", next_id_)])

    def add_next_hop(self, next_id, egress_port):
        next_id_ = stringify(next_id, 4)
        egress_port_ = stringify(egress_port, 2)
        self.send_request_add_entry_to_action(
            "next.simple",
            [self.Exact("fabric_metadata.next_id", next_id_)],
            "next.output", [("port_num", egress_port_)])

    def add_next_hop_L3(self, next_id, egress_port, smac, dmac):
        next_id_ = stringify(next_id, 4)
        egress_port_ = stringify(egress_port, 2)
        smac_ = mac_to_binary(smac)
        dmac_ = mac_to_binary(dmac)
        self.send_request_add_entry_to_action(
            "next.simple",
            [self.Exact("fabric_metadata.next_id", next_id_)],
            "next.l3_routing",
            [("port_num", egress_port_), ("smac", smac_), ("dmac", dmac_)])

    # next_hops is a dictionary mapping mbr_id to (egress_port, smac, dmac)
    # we can break this method into several ones (group creation, etc.) if there
    # is a need when adding new tests in the future
    def add_next_hop_L3_group(self, next_id, grp_id, next_hops = {}):
        next_id_ = stringify(next_id, 4)
        for mbr_id, params in next_hops.items():
            egress_port, smac, dmac = params
            egress_port_ = stringify(egress_port, 2)
            smac_ = mac_to_binary(smac)
            dmac_ = mac_to_binary(dmac)
            self.send_request_add_member(
                "next.ecmp_selector", mbr_id, "next.l3_routing",
                [("port_num", egress_port_), ("smac", smac_), ("dmac", dmac_)])
        self.send_request_add_group("next.ecmp_selector", grp_id,
                                    grp_size=32, mbr_ids=next_hops.keys())
        self.send_request_add_entry_to_group(
            "next.hashed",
            [self.Exact("fabric_metadata.next_id", next_id_)],
            grp_id)

class FabricL2UnicastTest(FabricTest):
    @autocleanup
    def runTest(self):
        mac_addr_mask = ":".join(["ff"] * 6)
        vlan_id = 10
        self.set_internal_vlan(self.port1, False, 0, 0, vlan_id)
        self.set_internal_vlan(self.port2, False, 0, 0, vlan_id)
        # miss on filtering.fwd_classifier => bridging
        self.add_bridging_entry(vlan_id, HOST1_MAC, mac_addr_mask, 10)
        self.add_bridging_entry(vlan_id, HOST2_MAC, mac_addr_mask, 20)
        self.add_next_hop(10, self.port1)
        self.add_next_hop(20, self.port2)

        pkt_1to2 = testutils.simple_tcp_packet(
            eth_src = HOST1_MAC, eth_dst = HOST2_MAC)
        pkt_2to1 = testutils.simple_tcp_packet(
            eth_src = HOST2_MAC, eth_dst = HOST1_MAC)
        testutils.send_packet(self, self.port1, str(pkt_1to2))
        testutils.verify_packets(self, pkt_1to2, [self.port2])
        testutils.send_packet(self, self.port2, str(pkt_2to1))
        testutils.verify_packets(self, pkt_2to1, [self.port1])

class FabricIPv4UnicastTest(FabricTest):
    @autocleanup
    def runTest(self):
        vlan_id = 10
        self.set_internal_vlan(self.port1, False, 0, 0, vlan_id)
        self.set_internal_vlan(self.port2, False, 0, 0, vlan_id)
        self.set_forwarding_type(self.port1, SWITCH_MAC, 0x800,
                                 FORWARDING_TYPE_UNICAST_IPV4)
        self.set_forwarding_type(self.port2, SWITCH_MAC, 0x800,
                                 FORWARDING_TYPE_UNICAST_IPV4)
        self.add_forwarding_unicast_v4_entry(HOST1_IPV4, 24, 100)
        self.add_forwarding_unicast_v4_entry(HOST2_IPV4, 24, 200)
        self.add_next_hop_L3(100, self.port1, SWITCH_MAC, HOST1_MAC)
        self.add_next_hop_L3(200, self.port2, SWITCH_MAC, HOST2_MAC)

        pkt_1to2 = testutils.simple_tcp_packet(
            eth_src = HOST1_MAC, eth_dst = SWITCH_MAC,
            ip_src = HOST1_IPV4, ip_dst = HOST2_IPV4, ip_ttl = 64)
        exp_pkt_1to2 = testutils.simple_tcp_packet(
            eth_src = SWITCH_MAC, eth_dst = HOST2_MAC,
            ip_src = HOST1_IPV4, ip_dst = HOST2_IPV4, ip_ttl = 63)

        testutils.send_packet(self, self.port1, str(pkt_1to2))
        testutils.verify_packets(self, exp_pkt_1to2, [self.port2])

        pkt_2to1 = testutils.simple_tcp_packet(
            eth_src = HOST2_MAC, eth_dst = SWITCH_MAC,
            ip_src = HOST2_IPV4, ip_dst = HOST1_IPV4, ip_ttl = 64)
        exp_pkt_2to1 = testutils.simple_tcp_packet(
            eth_src = SWITCH_MAC, eth_dst = HOST1_MAC,
            ip_src = HOST2_IPV4, ip_dst = HOST1_IPV4, ip_ttl = 63)

        testutils.send_packet(self, self.port2, str(pkt_2to1))
        testutils.verify_packets(self, exp_pkt_2to1, [self.port1])

@testutils.disabled
class FabricIPv4UnicastGroupTest(FabricTest):
    @autocleanup
    def runTest(self):
        vlan_id = 10
        self.set_internal_vlan(self.port1, False, 0, 0, vlan_id)
        self.set_forwarding_type(self.port1, SWITCH_MAC, 0x800,
                                 FORWARDING_TYPE_UNICAST_IPV4)
        self.add_forwarding_unicast_v4_entry(HOST2_IPV4, 24, 300)
        grp_id = 66
        mbrs = {
            2 : (self.port2, SWITCH_MAC, HOST2_MAC),
            3 : (self.port3, SWITCH_MAC, HOST3_MAC),
        }
        self.add_next_hop_L3_group(300, grp_id, mbrs)

        pkt_from1 = testutils.simple_tcp_packet(
            eth_src = HOST1_MAC, eth_dst = SWITCH_MAC,
            ip_src = HOST1_IPV4, ip_dst = HOST2_IPV4, ip_ttl = 64)
        exp_pkt_to2 = testutils.simple_tcp_packet(
            eth_src = SWITCH_MAC, eth_dst = HOST2_MAC,
            ip_src = HOST1_IPV4, ip_dst = HOST2_IPV4, ip_ttl = 63)
        exp_pkt_to3 = testutils.simple_tcp_packet(
            eth_src = SWITCH_MAC, eth_dst = HOST3_MAC,
            ip_src = HOST1_IPV4, ip_dst = HOST2_IPV4, ip_ttl = 63)

        testutils.send_packet(self, self.port1, str(pkt_from1))
        port_index, _ = testutils.verify_any_packet_any_port(
            self, [exp_pkt_to2, exp_pkt_to3], [self.port2, self.port3])

class PacketOutTest(FabricTest):
    def runTest(self):
        port3 = self.swports(3)
        port3_hex = stringify(port3, 2)
        payload = 'a' * 20
        packet_out = p4runtime_pb2.PacketOut()
        packet_out.payload = payload
        egress_physical_port = packet_out.metadata.add()
        egress_physical_port.metadata_id = 1
        egress_physical_port.value = port3_hex

        self.send_packet_out(packet_out)

        testutils.verify_packet(self, payload, port3)
        testutils.verify_no_other_packets(self)
