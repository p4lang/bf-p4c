# Copyright 2013-present Barefoot Networks, Inc.
# Copyright 2018-present Open Networking Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

from itertools import combinations

from ptf.testutils import group

from p4runtime_base_tests import autocleanup
from fabric_test import *

vlan_confs = {
    "tag->tag": [True, True],
    "untag->untag": [False, False],
    "tag->untag": [True, False],
    "untag->tag": [False, True],
}


class FabricBridgingTest(BridgingTest):
    @autocleanup
    def doRunTest(self, tagged1, tagged2, pkt):
        self.runBridgingTest(tagged1, tagged2, pkt)

    def runTest(self):
        print ""
        for vlan_conf, tagged in vlan_confs.items():
            for pkt_type in ["tcp", "udp", "icmp"]:
                print "Testing %s packet with VLAN %s.." % (pkt_type, vlan_conf)
                pkt = getattr(testutils, "simple_%s_packet" % pkt_type)(
                    pktlen=120)
                self.doRunTest(tagged[0], tagged[1], pkt)


class FabricDoubleVlanXConnectTest(DoubleVlanXConnectTest):
    @autocleanup
    def doRunTest(self, pkt):
        self.runXConnectTest(pkt)

    def runTest(self):
        print ""
        for pkt_type in ["tcp", "udp", "icmp"]:
            print "Testing %s packet..." % pkt_type
            pkt = getattr(testutils, "simple_%s_packet" % pkt_type)(
                pktlen=120)
            self.doRunTest(pkt)


@group("multicast")
class FabricArpBroadcastUntaggedTest(ArpBroadcastTest):
    @autocleanup
    def runTest(self):
        self.runArpBroadcastTest(
            tagged_ports=[],
            untagged_ports=[self.port1, self.port2, self.port3])


@group("multicast")
class FabricArpBroadcastTaggedTest(ArpBroadcastTest):
    @autocleanup
    def runTest(self):
        self.runArpBroadcastTest(
            tagged_ports=[self.port1, self.port2, self.port3],
            untagged_ports=[])


@group("multicast")
class FabricArpBroadcastMixedTest(ArpBroadcastTest):
    @autocleanup
    def runTest(self):
        self.runArpBroadcastTest(
            tagged_ports=[self.port2, self.port3],
            untagged_ports=[self.port1])


class FabricIPv4UnicastTest(IPv4UnicastTest):
    @autocleanup
    def doRunTest(self, pkt, mac_dest, tagged1, tagged2):
        self.runIPv4UnicastTest(
            pkt, mac_dest, prefix_len=24, tagged1=tagged1, tagged2=tagged2)

    def runTest(self):
        print ""
        for vlan_conf, tagged in vlan_confs.items():
            for pkt_type in ["tcp", "udp", "icmp"]:
                print "Testing %s packet with VLAN %s..." \
                      % (pkt_type, vlan_conf)
                pkt = getattr(testutils, "simple_%s_packet" % pkt_type)(
                    eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
                    ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4,
                    pktlen=MIN_PKT_LEN
                )
                self.doRunTest(pkt, HOST2_MAC, tagged[0], tagged[1])


class FabricIPv4UnicastGtpTest(IPv4UnicastTest):
    @autocleanup
    def runTest(self):
        # Assert that GTP packets not meant to be processed by spgw.p4 are
        # forwarded using the outer IP+UDP headers. For spgw.p4 to kick in
        # outer IP dst should be in a subnet defined at compile time (see
        # fabric.p4's parser).
        inner_udp = UDP(sport=5061, dport=5060) / ("\xab" * 128)
        pkt = Ether(src=HOST1_MAC, dst=SWITCH_MAC) / \
              IP(src=HOST3_IPV4, dst=HOST4_IPV4) / \
              UDP(sport=UDP_GTP_PORT, dport=UDP_GTP_PORT) / \
              make_gtp(20 + len(inner_udp), 0xeeffc0f0) / \
              IP(src=HOST1_IPV4, dst=HOST2_IPV4) / \
              inner_udp
        self.runIPv4UnicastTest(pkt, HOST2_MAC)


class FabricIPv4UnicastGroupTest(FabricTest):
    @autocleanup
    def runTest(self):
        vlan_id = 10
        self.set_ingress_port_vlan(self.port1, False, 0, vlan_id)
        self.set_forwarding_type(self.port1, SWITCH_MAC, 0x800,
                                 FORWARDING_TYPE_UNICAST_IPV4)
        self.add_forwarding_routing_v4_entry(HOST2_IPV4, 24, 300)
        grp_id = 66
        mbrs = [
            (self.port2, SWITCH_MAC, HOST2_MAC),
            (self.port3, SWITCH_MAC, HOST3_MAC),
        ]
        self.add_next_routing_group(300, grp_id, mbrs)
        self.set_egress_vlan_pop(self.port2, vlan_id)
        self.set_egress_vlan_pop(self.port3, vlan_id)

        pkt_from1 = testutils.simple_tcp_packet(
            eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
            ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=64)
        exp_pkt_to2 = testutils.simple_tcp_packet(
            eth_src=SWITCH_MAC, eth_dst=HOST2_MAC,
            ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=63)
        exp_pkt_to3 = testutils.simple_tcp_packet(
            eth_src=SWITCH_MAC, eth_dst=HOST3_MAC,
            ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=63)

        testutils.send_packet(self, self.port1, str(pkt_from1))
        testutils.verify_any_packet_any_port(
            self, [exp_pkt_to2, exp_pkt_to3], [self.port2, self.port3])


class FabricIPv4UnicastGroupTestAllPortTcpSport(FabricTest):
    @autocleanup
    def runTest(self):
        # In this test we check that packets are forwarded to all ports when we change
        # one of the 5-tuple header values. In this case tcp-source-port
        vlan_id = 10
        self.set_ingress_port_vlan(self.port1, False, 0, vlan_id)
        self.set_forwarding_type(self.port1, SWITCH_MAC, 0x800,
                                 FORWARDING_TYPE_UNICAST_IPV4)
        self.add_forwarding_routing_v4_entry(HOST2_IPV4, 24, 300)
        grp_id = 66
        mbrs = [
            (self.port2, SWITCH_MAC, HOST2_MAC),
            (self.port3, SWITCH_MAC, HOST3_MAC),
        ]
        self.add_next_routing_group(300, grp_id, mbrs)
        self.set_egress_vlan_pop(self.port2, vlan_id)
        self.set_egress_vlan_pop(self.port3, vlan_id)
        # tcpsport_toport list is used to learn the tcp_source_port that
        # causes the packet to be forwarded for each port
        tcpsport_toport = [None, None]
        for i in range(50):
            test_tcp_sport = 1230 + i
            pkt_from1 = testutils.simple_tcp_packet(
                eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
                ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=64, tcp_sport=test_tcp_sport)
            exp_pkt_to2 = testutils.simple_tcp_packet(
                eth_src=SWITCH_MAC, eth_dst=HOST2_MAC,
                ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=63, tcp_sport=test_tcp_sport)
            exp_pkt_to3 = testutils.simple_tcp_packet(
                eth_src=SWITCH_MAC, eth_dst=HOST3_MAC,
                ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=63, tcp_sport=test_tcp_sport)
            testutils.send_packet(self, self.port1, str(pkt_from1))
            out_port_indx = testutils.verify_any_packet_any_port(
                self, [exp_pkt_to2, exp_pkt_to3], [self.port2, self.port3])
            tcpsport_toport[out_port_indx] = test_tcp_sport

        pkt_toport2 = testutils.simple_tcp_packet(
            eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
            ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=64, tcp_sport=tcpsport_toport[0])
        pkt_toport3 = testutils.simple_tcp_packet(
            eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
            ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=64, tcp_sport=tcpsport_toport[1])
        exp_pkt_to2 = testutils.simple_tcp_packet(
            eth_src=SWITCH_MAC, eth_dst=HOST2_MAC,
            ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=63, tcp_sport=tcpsport_toport[0])
        exp_pkt_to3 = testutils.simple_tcp_packet(
            eth_src=SWITCH_MAC, eth_dst=HOST3_MAC,
            ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=63, tcp_sport=tcpsport_toport[1])
        testutils.send_packet(self, self.port1, str(pkt_toport2))
        testutils.send_packet(self, self.port1, str(pkt_toport3))
        # In this assertion we are verifying:
        #  1) all ports of the same group are used almost once
        #  2) consistency of the forwarding decision, i.e. packets with the same 5-tuple
        #     fields are always forwarded out of the same port
        testutils.verify_each_packet_on_each_port(
            self, [exp_pkt_to2, exp_pkt_to3], [self.port2, self.port3])


class FabricIPv4UnicastGroupTestAllPortTcpDport(FabricTest):
    @autocleanup
    def runTest(self):
        # In this test we check that packets are forwarded to all ports when we change
        # one of the 5-tuple header values. In this case tcp-dst-port
        vlan_id = 10
        self.set_ingress_port_vlan(self.port1, False, 0, vlan_id)
        self.set_forwarding_type(self.port1, SWITCH_MAC, 0x800,
                                 FORWARDING_TYPE_UNICAST_IPV4)
        self.add_forwarding_routing_v4_entry(HOST2_IPV4, 24, 300)
        grp_id = 66
        mbrs = [
            (self.port2, SWITCH_MAC, HOST2_MAC),
            (self.port3, SWITCH_MAC, HOST3_MAC),
        ]
        self.add_next_routing_group(300, grp_id, mbrs)
        self.set_egress_vlan_pop(self.port2, vlan_id)
        self.set_egress_vlan_pop(self.port3, vlan_id)
        # tcpdport_toport list is used to learn the tcp_destination_port that
        # causes the packet to be forwarded for each port
        tcpdport_toport = [None, None]
        for i in range(50):
            test_tcp_dport = 1230 + i
            pkt_from1 = testutils.simple_tcp_packet(
                eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
                ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=64, tcp_dport=test_tcp_dport)
            exp_pkt_to2 = testutils.simple_tcp_packet(
                eth_src=SWITCH_MAC, eth_dst=HOST2_MAC,
                ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=63, tcp_dport=test_tcp_dport)
            exp_pkt_to3 = testutils.simple_tcp_packet(
                eth_src=SWITCH_MAC, eth_dst=HOST3_MAC,
                ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=63, tcp_dport=test_tcp_dport)
            testutils.send_packet(self, self.port1, str(pkt_from1))
            out_port_indx = testutils.verify_any_packet_any_port(
                self, [exp_pkt_to2, exp_pkt_to3], [self.port2, self.port3])
            tcpdport_toport[out_port_indx] = test_tcp_dport

        pkt_toport2 = testutils.simple_tcp_packet(
            eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
            ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=64, tcp_dport=tcpdport_toport[0])
        pkt_toport3 = testutils.simple_tcp_packet(
            eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
            ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=64, tcp_dport=tcpdport_toport[1])
        exp_pkt_to2 = testutils.simple_tcp_packet(
            eth_src=SWITCH_MAC, eth_dst=HOST2_MAC,
            ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=63, tcp_dport=tcpdport_toport[0])
        exp_pkt_to3 = testutils.simple_tcp_packet(
            eth_src=SWITCH_MAC, eth_dst=HOST3_MAC,
            ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=63, tcp_dport=tcpdport_toport[1])
        testutils.send_packet(self, self.port1, str(pkt_toport2))
        testutils.send_packet(self, self.port1, str(pkt_toport3))
        # In this assertion we are verifying:
        #  1) all ports of the same group are used almost once
        #  2) consistency of the forwarding decision, i.e. packets with the same 5-tuple
        #     fields are always forwarded out of the same port
        testutils.verify_each_packet_on_each_port(
            self, [exp_pkt_to2, exp_pkt_to3], [self.port2, self.port3])


class FabricIPv4UnicastGroupTestAllPortIpSrc(FabricTest):
    @autocleanup
    def IPv4UnicastGroupTestAllPortL4SrcIp(self, pkt_type):
        # In this test we check that packets are forwarded to all ports when we change
        # one of the 5-tuple header values and we have an ECMP-like distribution.
        # In this case IP source for tcp and udp packets
        vlan_id = 10
        self.set_ingress_port_vlan(self.port1, False, 0, vlan_id)
        self.set_forwarding_type(self.port1, SWITCH_MAC, 0x800,
                                 FORWARDING_TYPE_UNICAST_IPV4)
        self.add_forwarding_routing_v4_entry(HOST2_IPV4, 24, 300)
        grp_id = 66
        mbrs = [
            (self.port2, SWITCH_MAC, HOST2_MAC),
            (self.port3, SWITCH_MAC, HOST3_MAC),
        ]
        self.add_next_routing_group(300, grp_id, mbrs)
        self.set_egress_vlan_pop(self.port2, vlan_id)
        self.set_egress_vlan_pop(self.port3, vlan_id)
        # ipsource_toport list is used to learn the ip_src that causes the packet
        # to be forwarded for each port
        ipsource_toport = [None, None]
        for i in range(50):
            test_ipsource = "10.0.1." + str(i)
            pkt_from1 = getattr(testutils, "simple_%s_packet" % pkt_type)(
                eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
                ip_src=test_ipsource, ip_dst=HOST2_IPV4, ip_ttl=64)
            exp_pkt_to2 = getattr(testutils, "simple_%s_packet" % pkt_type)(
                eth_src=SWITCH_MAC, eth_dst=HOST2_MAC,
                ip_src=test_ipsource, ip_dst=HOST2_IPV4, ip_ttl=63)
            exp_pkt_to3 = getattr(testutils, "simple_%s_packet" % pkt_type)(
                eth_src=SWITCH_MAC, eth_dst=HOST3_MAC,
                ip_src=test_ipsource, ip_dst=HOST2_IPV4, ip_ttl=63)
            testutils.send_packet(self, self.port1, str(pkt_from1))
            out_port_indx = testutils.verify_any_packet_any_port(
                self, [exp_pkt_to2, exp_pkt_to3], [self.port2, self.port3])
            ipsource_toport[out_port_indx] = test_ipsource

        pkt_toport2 = getattr(testutils, "simple_%s_packet" % pkt_type)(
            eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
            ip_src=ipsource_toport[0], ip_dst=HOST2_IPV4, ip_ttl=64)
        pkt_toport3 = getattr(testutils, "simple_%s_packet" % pkt_type)(
            eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
            ip_src=ipsource_toport[1], ip_dst=HOST2_IPV4, ip_ttl=64)
        exp_pkt_to2 = getattr(testutils, "simple_%s_packet" % pkt_type)(
            eth_src=SWITCH_MAC, eth_dst=HOST2_MAC,
            ip_src=ipsource_toport[0], ip_dst=HOST2_IPV4, ip_ttl=63)
        exp_pkt_to3 = getattr(testutils, "simple_%s_packet" % pkt_type)(
            eth_src=SWITCH_MAC, eth_dst=HOST3_MAC,
            ip_src=ipsource_toport[1], ip_dst=HOST2_IPV4, ip_ttl=63)
        testutils.send_packet(self, self.port1, str(pkt_toport2))
        testutils.send_packet(self, self.port1, str(pkt_toport3))
        # In this assertion we are verifying:
        #  1) all ports of the same group are used almost once
        #  2) consistency of the forwarding decision, i.e. packets with the same 5-tuple
        #     fields are always forwarded out of the same port
        testutils.verify_each_packet_on_each_port(
            self, [exp_pkt_to2, exp_pkt_to3], [self.port2, self.port3])

    def runTest(self):
        self.IPv4UnicastGroupTestAllPortL4SrcIp("tcp")
        self.IPv4UnicastGroupTestAllPortL4SrcIp("udp")


class FabricIPv4UnicastGroupTestAllPortIpDst(FabricTest):
    @autocleanup
    def IPv4UnicastGroupTestAllPortL4DstIp(self, pkt_type):
        # In this test we check that packets are forwarded to all ports when we change
        # one of the 5-tuple header values and we have an ECMP-like distribution.
        # In this case IP dest for tcp and udp packets
        vlan_id = 10
        self.set_ingress_port_vlan(self.port1, False, 0, vlan_id)
        self.set_forwarding_type(self.port1, SWITCH_MAC, 0x800,
                                 FORWARDING_TYPE_UNICAST_IPV4)
        self.add_forwarding_routing_v4_entry(HOST2_IPV4, 24, 300)
        grp_id = 66
        mbrs = [
            (self.port2, SWITCH_MAC, HOST2_MAC),
            (self.port3, SWITCH_MAC, HOST3_MAC),
        ]
        self.add_next_routing_group(300, grp_id, mbrs)
        self.set_egress_vlan_pop(self.port2, vlan_id)
        self.set_egress_vlan_pop(self.port3, vlan_id)
        # ipdst_toport list is used to learn the ip_dst that causes the packet
        # to be forwarded for each port
        ipdst_toport = [None, None]
        for i in range(50):
            test_ipdst = "10.0.2." + str(i)
            pkt_from1 = getattr(testutils, "simple_%s_packet" % pkt_type)(
                eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
                ip_src=HOST1_IPV4, ip_dst=test_ipdst, ip_ttl=64)
            exp_pkt_to2 = getattr(testutils, "simple_%s_packet" % pkt_type)(
                eth_src=SWITCH_MAC, eth_dst=HOST2_MAC,
                ip_src=HOST1_IPV4, ip_dst=test_ipdst, ip_ttl=63)
            exp_pkt_to3 = getattr(testutils, "simple_%s_packet" % pkt_type)(
                eth_src=SWITCH_MAC, eth_dst=HOST3_MAC,
                ip_src=HOST1_IPV4, ip_dst=test_ipdst, ip_ttl=63)
            testutils.send_packet(self, self.port1, str(pkt_from1))
            out_port_indx = testutils.verify_any_packet_any_port(
                self, [exp_pkt_to2, exp_pkt_to3], [self.port2, self.port3])
            ipdst_toport[out_port_indx] = test_ipdst

        pkt_toport2 = getattr(testutils, "simple_%s_packet" % pkt_type)(
            eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
            ip_src=HOST1_IPV4, ip_dst=ipdst_toport[0], ip_ttl=64)
        pkt_toport3 = getattr(testutils, "simple_%s_packet" % pkt_type)(
            eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
            ip_src=HOST1_IPV4, ip_dst=ipdst_toport[1], ip_ttl=64)
        exp_pkt_to2 = getattr(testutils, "simple_%s_packet" % pkt_type)(
            eth_src=SWITCH_MAC, eth_dst=HOST2_MAC,
            ip_src=HOST1_IPV4, ip_dst=ipdst_toport[0], ip_ttl=63)
        exp_pkt_to3 = getattr(testutils, "simple_%s_packet" % pkt_type)(
            eth_src=SWITCH_MAC, eth_dst=HOST3_MAC,
            ip_src=HOST1_IPV4, ip_dst=ipdst_toport[1], ip_ttl=63)
        testutils.send_packet(self, self.port1, str(pkt_toport2))
        testutils.send_packet(self, self.port1, str(pkt_toport3))
        # In this assertion we are verifying:
        #  1) all ports of the same group are used almost once
        #  2) consistency of the forwarding decision, i.e. packets with the same 5-tuple
        #     fields are always forwarded out of the same port
        testutils.verify_each_packet_on_each_port(
            self, [exp_pkt_to2, exp_pkt_to3], [self.port2, self.port3])

    def runTest(self):
        self.IPv4UnicastGroupTestAllPortL4DstIp("tcp")
        self.IPv4UnicastGroupTestAllPortL4DstIp("udp")


class FabricIPv4MPLSTest(FabricTest):
    @autocleanup
    def runTest(self):
        vlan_id = 10
        self.set_ingress_port_vlan(self.port1, False, 0, vlan_id)
        self.set_forwarding_type(self.port1, SWITCH_MAC, 0x800,
                                 FORWARDING_TYPE_UNICAST_IPV4)
        self.add_forwarding_routing_v4_entry(HOST2_IPV4, 24, 400)
        mpls_label = 0xaba
        self.add_next_mpls_routing(
            400, self.port2, SWITCH_MAC, HOST2_MAC, mpls_label)
        self.set_egress_vlan_pop(self.port2, vlan_id)

        pkt_1to2 = testutils.simple_tcp_packet(
            eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
            ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4, ip_ttl=64)
        exp_pkt_1to2 = testutils.simple_mpls_packet(
            eth_src=SWITCH_MAC, eth_dst=HOST2_MAC,
            mpls_tags=[{
                "label": mpls_label,
                "tc": 0,
                "s": 1,
                "ttl": DEFAULT_MPLS_TTL}],
            inner_frame=pkt_1to2[IP:])

        testutils.send_packet(self, self.port1, str(pkt_1to2))
        testutils.verify_packets(self, exp_pkt_1to2, [self.port2])


class FabricIPv4MplsGroupTest(IPv4UnicastTest):
    @autocleanup
    def doRunTest(self, pkt, mac_dest, tagged1):
        self.runIPv4UnicastTest(
            pkt, mac_dest, prefix_len=24, tagged1=tagged1, tagged2=False,
            bidirectional=False, mpls=True)

    def runTest(self):
        print ""
        for tagged1 in [True, False]:
            for pkt_type in ["tcp", "udp", "icmp"]:
                print "Testing %s packet with tagged=%s..." \
                      % (pkt_type, tagged1)
                pkt = getattr(testutils, "simple_%s_packet" % pkt_type)(
                    eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
                    ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4,
                    pktlen=MIN_PKT_LEN
                )
                self.doRunTest(pkt, HOST2_MAC, tagged1)


class FabricMplsSegmentRoutingTest(MplsSegmentRoutingTest):
    @autocleanup
    def doRunTest(self, pkt, mac_dest, next_hop_spine):
        self.runMplsSegmentRoutingTest(pkt, mac_dest, next_hop_spine)

    def runTest(self):
        print ""
        for pkt_type in ["tcp", "udp", "icmp"]:
            for next_hop_spine in [True, False]:
                print "Testing %s packet, next_hop_spine=%s..." \
                      % (pkt_type, next_hop_spine)
                pkt = getattr(testutils, "simple_%s_packet" % pkt_type)(
                    eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
                    ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4,
                    pktlen=MIN_PKT_LEN
                )
                self.doRunTest(pkt, HOST2_MAC, next_hop_spine)


@group("packetio")
class FabricArpPacketOutTest(PacketOutTest):
    @autocleanup
    def runTest(self):
        pkt = testutils.simple_arp_packet(pktlen=MIN_PKT_LEN)
        self.runPacketOutTest(pkt)


@group("packetio")
class FabricShortIpPacketOutTest(PacketOutTest):
    @autocleanup
    def runTest(self):
        pkt = testutils.simple_ip_packet(pktlen=MIN_PKT_LEN)
        self.runPacketOutTest(pkt)


@group("packetio")
class FabricLongIpPacketOutTest(PacketOutTest):
    @autocleanup
    def runTest(self):
        pkt = testutils.simple_ip_packet(pktlen=160)
        self.runPacketOutTest(pkt)


@group("packetio")
class FabricArpPacketInTest(PacketInTest):
    @autocleanup
    def runTest(self):
        pkt = testutils.simple_arp_packet(pktlen=MIN_PKT_LEN)
        self.runPacketInTest(pkt, ETH_TYPE_ARP)


@group("packetio")
class FabricLongIpPacketInTest(PacketInTest):
    @autocleanup
    def runTest(self):
        pkt = testutils.simple_ip_packet(pktlen=160)
        self.runPacketInTest(pkt, ETH_TYPE_IPV4)


@group("packetio")
class FabricShortIpPacketInTest(PacketInTest):
    @autocleanup
    def runTest(self):
        pkt = testutils.simple_ip_packet(pktlen=MIN_PKT_LEN)
        self.runPacketInTest(pkt, ETH_TYPE_IPV4)


@group("packetio")
class FabricTaggedPacketInTest(PacketInTest):
    @autocleanup
    def runTest(self):
        pkt = testutils.simple_ip_packet(dl_vlan_enable=True, vlan_vid=10, pktlen=160)
        self.runPacketInTest(pkt, ETH_TYPE_IPV4, tagged=True, vlan_id=10)


@group("packetio")
class FabricDefaultVlanPacketInTest(FabricTest):
    @autocleanup
    def runTest(self):
        pkt = testutils.simple_eth_packet(pktlen=MIN_PKT_LEN)
        self.add_forwarding_acl_cpu_entry(eth_type=pkt[Ether].type)
        for port in [self.port1, self.port2]:
            testutils.send_packet(self, port, str(pkt))
            self.verify_packet_in(pkt, port)
        testutils.verify_no_other_packets(self)


@group("spgw")
class SpgwDownlinkTest(SpgwSimpleTest):
    @autocleanup
    def doRunTest(self, pkt, tagged1, tagged2, mpls):
        self.runDownlinkTest(pkt=pkt, tagged1=tagged1,
                             tagged2=tagged2, mpls=mpls)

    def runTest(self):
        print ""
        for vlan_conf, tagged in vlan_confs.items():
            for pkt_type in ["tcp", "udp", "icmp"]:
                for mpls in [False, True]:
                    if mpls and tagged[1]:
                        continue
                    print "Testing VLAN=%s, pkt=%s, mpls=%s..." \
                          % (vlan_conf, pkt_type, mpls)
                    pkt = getattr(testutils, "simple_%s_packet" % pkt_type)(
                        eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
                        ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4,
                        pktlen=MIN_PKT_LEN
                    )
                    self.doRunTest(pkt, tagged[0], tagged[1], mpls)


@group("spgw")
class SpgwUplinkTest(SpgwSimpleTest):
    @autocleanup
    def doRunTest(self, pkt, tagged1, tagged2, mpls):
        self.runUplinkTest(ue_out_pkt=pkt, tagged1=tagged1,
                           tagged2=tagged2, mpls=mpls)

    def runTest(self):
        print ""
        for vlan_conf, tagged in vlan_confs.items():
            for pkt_type in ["tcp", "udp", "icmp"]:
                for mpls in [False, True]:
                    if mpls and tagged[1]:
                        continue
                    print "Testing VLAN=%s, pkt=%s, mpls=%s..." \
                          % (vlan_conf, pkt_type, mpls)
                    pkt = getattr(testutils, "simple_%s_packet" % pkt_type)(
                        eth_src=HOST1_MAC, eth_dst=SWITCH_MAC,
                        ip_src=HOST1_IPV4, ip_dst=HOST2_IPV4,
                        pktlen=MIN_PKT_LEN
                    )
                    self.doRunTest(pkt, tagged[0], tagged[1], mpls)


@group("int")
class FabricIntTransitTest(IntTest):
    @autocleanup
    def doRunTest(self, vlan_conf, tagged, pkt_type, prev_hops, instrs, mpls):
        print "Testing VLAN=%s, pkt=%s, mpls=%s, prev_hops=%s, instructions=%s..." \
              % (vlan_conf, pkt_type, mpls, prev_hops,
                 ",".join([INT_INS_TO_NAME[i] for i in instrs]))
        pkt = getattr(testutils, "simple_%s_packet" % pkt_type)()
        hop_metadata, _ = self.get_int_metadata(instrs, 0xCAFEBABE, 0xDEAD, 0xBEEF)
        int_pkt = self.get_int_pkt(pkt=pkt, instructions=instrs, max_hop=50,
                                   transit_hops=prev_hops,
                                   hop_metadata=hop_metadata)
        self.runIntTransitTest(pkt=int_pkt,
                               tagged1=tagged[0],
                               tagged2=tagged[1],
                               ignore_csum=1, mpls=mpls)

    def runTest(self):
        instr_sets = [
            [INT_SWITCH_ID, INT_IG_EG_PORT],
            [INT_SWITCH_ID, INT_IG_EG_PORT, INT_IG_TSTAMP, INT_EG_TSTAMP, INT_QUEUE_OCCUPANCY]
        ]
        print ""
        for vlan_conf, tagged in vlan_confs.items():
            for pkt_type in ["udp", "tcp"]:
                for mpls in [False, True]:
                    for prev_hops in [0, 3]:
                        for instrs in instr_sets:
                            if mpls and tagged[1]:
                                continue
                            self.doRunTest(vlan_conf, tagged, pkt_type,
                                           prev_hops, instrs, mpls)