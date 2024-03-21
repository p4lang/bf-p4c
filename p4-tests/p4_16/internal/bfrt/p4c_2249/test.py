################################################################################
# BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
#
# Copyright (c) 2018-2019 Barefoot Networks, Inc.

# All Rights Reserved.
#
# NOTICE: All information contained herein is, and remains the property of
# Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
# technical concepts contained herein are proprietary to Barefoot Networks,
# Inc.
# and its suppliers and may be covered by U.S. and Foreign Patents, patents in
# process, and are protected by trade secret or copyright law.
# Dissemination of this information or reproduction of this material is
# strictly forbidden unless prior written permission is obtained from
# Barefoot Networks, Inc.
#
# No warranty, explicit or implicit is provided, unless granted under a
# written agreement with Barefoot Networks, Inc.
#
# Milad Sharif (msharif@barefootnetworks.com)
#
###############################################################################

import logging
import sys
import os
import random
import re
import time
#from pprint import pprint

from scapy.contrib import nsh

from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils
from bfruntime_base_tests import BfRuntimeTest
import bfrt_grpc.bfruntime_pb2 as bfruntime_pb2

logger = logging.getLogger('Test')
logger.addHandler(logging.StreamHandler())

#############################################
# NPF Stuff
import yaml

sys.path.append('/npb-dp/tools/npf')
#import npf
#from npf_hdr_stacks import HdrStacks
#############################################

swports = []
for device, port, ifname in config["interfaces"]:
    swports.append(port)
    swports.sort()

if swports == []:
    swports = range(9)

def port_to_pipe(port):
    local_port = port & 0x7F
    assert(local_port < 72)
    pipe = (port >> 7) & 0x3
    assert(port == ((pipe << 7) | local_port))
    return pipe

swports_0 = []
swports_1 = []
swports_2 = []
swports_3 = []
# the following method categorizes the ports in ports.json file as belonging to either of the pipes (0, 1, 2, 3)
for port in swports:
    pipe = port_to_pipe(port)
    if pipe == 0:
        swports_0.append(port)
    elif pipe == 1:
        swports_1.append(port)
    elif pipe == 2:
        swports_2.append(port)
    elif pipe == 3:
        swports_3.append(port)

print('swports_0:', swports_0)
print('swports_1:', swports_1)
print('swports_2:', swports_2)
print('swports_3:', swports_3)

class NpbNshDecapTest(BfRuntimeTest):

    def setUp(self):
        client_id = 0
        p4_name = "p4c_2249"
        BfRuntimeTest.setUp(self, client_id, p4_name)

    # -------------------------------------------------------------

    def send_and_verify_packet(self, ingress_port, egress_port, pkt, exp_pkt):
        logger.info("Sending packet on port %d", ingress_port)
        testutils.send_packet(self, ingress_port, pkt)
        logger.info("Expecting packet on port %d", egress_port)
        testutils.verify_packets(self, exp_pkt, [egress_port])

    # -------------------------------------------------------------

    def send_and_verify_no_other_packet(self, ingress_port, pkt):
        logger.info("Sending packet on port %d (negative test); expecting no packet", ingress_port)
        testutils.send_packet(self, ingress_port, pkt)
        testutils.verify_no_other_packets(self)

    # -------------------------------------------------------------

    def runTest(self):
        ig_port = swports[0]
        eg_port = swports[0]
        smac = '11:11:11:11:11:11'
        dmac = '22:22:22:22:22:22'

        # Get bfrt_info and set it as part of the test
        self.set_bfrt_info(self.parse_bfrt_info(self.get_bfrt_info("p4c_2249")))

        # -----------------

        target = self.Target(device_id=0, pipe_id=0xffff)

        # -----------------------
        # NSH values to use
        # -----------------------

        proto_0             = 0x06 #
        proto_1             = 0x11 #
        tenant_id           = 0 # Must be 0 (that's what the default port entry is)
        flow_type           = 3 # Arbitrary value
        spi                 = 6 # Arbitrary value
        si                  = 7 # Arbitrary value (ttl)
        sfc                 = 1 # Arbitrary value
        sf_bitmask_local    = 0 # All 3 service functions -- NOTE: Each SF decrements the SI, so sf table keys need to be adjusted accordingly!
        sf_bitmask_remote   = 0 # All 3 service functions

        next_hop            = 9 # Arbitrary value
        bd                  = 9 # Arbitrary value
        tunnel_index        = 9 # Arbitrary value
        next_hop_outer      = 9 # Arbitrary value
        egress_ifindex      = 5 # Arbitrary value

        # -----------------------------------------------------------
        # Insert Table Entries
        # -----------------------------------------------------------

        # vi $SDE/build/p4-examples/npb/tofino2/npb/bf-rt.json

#        --- EXAMPLE ---
#        self.insert_table_entry(
#            target,
#            'SwitchIngress.forward',
#            [self.KeyField('hdr.ethernet.dst_addr', self.mac_to_bytes(dmac))],
#            'SwitchIngress.hit',
#            [self.DataField('port', self.to_bytes(eg_port, 2))])

        # -----------------

        # validation, l2
        self.insert_table_entry(
            target,
            'SwitchIngress.pkt_validation.validate_ethernet',
            [self.KeyField('hdr.ethernet.src_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
             self.KeyField('hdr.ethernet.dst_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
             self.KeyField('hdr.vlan_tag$0.$valid',                   self.to_bytes(0, 1), self.to_bytes(1, 1))],
            'SwitchIngress.pkt_validation.valid_unicast_pkt_untagged')

        # validation, l2
        self.insert_table_entry(
            target,
            'SwitchIngress.pkt_validation.validate_ethernet',
            [self.KeyField('hdr.ethernet.src_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
             self.KeyField('hdr.ethernet.dst_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
             self.KeyField('hdr.vlan_tag$0.$valid',                   self.to_bytes(1, 1), self.to_bytes(1, 1))],
            'SwitchIngress.pkt_validation.valid_unicast_pkt_tagged')

        # validation, l3, v4
        self.insert_table_entry(
            target,
            'SwitchIngress.pkt_validation.validate_ipv4',
            [self.KeyField('flags.ipv4_checksum_err',                   self.to_bytes(0, 1), self.to_bytes(1, 1)),
             self.KeyField('hdr.ipv4.version',                          self.to_bytes(0x4, 1), self.to_bytes(0xf, 1)),
             self.KeyField('hdr.ipv4.ihl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
             self.KeyField('hdr.ipv4.ttl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
             self.KeyField('hdr.ipv4.src_addr[31:24]',                  self.to_bytes(0, 1), self.to_bytes(0, 1))],
            'SwitchIngress.pkt_validation.valid_ipv4_pkt',
            [self.DataField('ip_frag',                                  self.to_bytes(0, 1))])

        # -----------------

        # validation, l2
        self.insert_table_entry(
            target,
            'SwitchIngress.tunnel_nsh.pkt_validation.validate_ethernet',
            [self.KeyField('hdr.inner_ethernet.dst_addr',               self.to_bytes(0, 6), self.to_bytes(0, 6)),
             self.KeyField('hdr.inner_ethernet.$valid',                self.to_bytes(0, 1))],
            'SwitchIngress.tunnel_nsh.pkt_validation.valid_unicast_pkt')

        # validation, l3, v4
        self.insert_table_entry(
            target,
            'SwitchIngress.tunnel_nsh.pkt_validation.validate_ipv4',
            [self.KeyField('flags.inner_ipv4_checksum_err',             self.to_bytes(0, 1), self.to_bytes(1, 1)),
             self.KeyField('hdr.inner_ipv4.version',                    self.to_bytes(0x4, 1), self.to_bytes(0xf, 1)),
             self.KeyField('hdr.inner_ipv4.ihl',                        self.to_bytes(0, 1), self.to_bytes(0, 1)),
             self.KeyField('hdr.inner_ipv4.ttl',                        self.to_bytes(0, 1), self.to_bytes(0, 1))],
            'SwitchIngress.tunnel_nsh.pkt_validation.valid_ipv4_pkt')

        # -----------------
        # Ingress SFC
        # -----------------

		# use for 1 table  (combined 1, 2, and 3)
        self.insert_table_entry(
            target,
            'SwitchIngress.npb_ing_sfc_top.ing_sfc_sfc_class_12',
            [self.KeyField('ig_md.lkp.ip_type',            self.to_bytes(1, 1)), # 1 = v4, 2 = v6
             self.KeyField('ig_md.lkp.ip_proto',           self.to_bytes(proto_0, 1)),
             self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 2))],
            'SwitchIngress.npb_ing_sfc_top.ing_sfc_sfc_classifier_12_permit',
            [self.DataField('flow_type',                       self.to_bytes(flow_type, 1)),
#            self.DataField('nsh_sph_spi',                     self.to_bytes(spi, 3)),
             self.DataField('sfc',                             self.to_bytes(spi, 1)), # just use spi for sfc, for now
             self.DataField('nsh_sph_si',                      self.to_bytes(si, 1)),
             self.DataField('sf_bitmask_local',                self.to_bytes(sf_bitmask_local, 1))])

        self.insert_table_entry(
            target,
            'SwitchIngress.npb_ing_sfc_top.ing_sfc_sfc_class_12',
            [self.KeyField('ig_md.lkp.ip_type',            self.to_bytes(1, 1)), # 1 = v4, 2 = v6
             self.KeyField('ig_md.lkp.ip_proto',           self.to_bytes(proto_1, 1)),
             self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 2))],
            'SwitchIngress.npb_ing_sfc_top.ing_sfc_sfc_classifier_12_permit',
            [self.DataField('flow_type',                       self.to_bytes(flow_type, 1)),
#            self.DataField('nsh_sph_spi',                     self.to_bytes(spi, 3)),
             self.DataField('sfc',                             self.to_bytes(spi, 1)), # just use spi for sfc, for now
             self.DataField('nsh_sph_si',                      self.to_bytes(si, 1)),
             self.DataField('sf_bitmask_local',                self.to_bytes(sf_bitmask_local, 1))])

		# use for 2 tables (combined 2 and 3)
		# use for 3 tables
#        self.insert_table_entry(
#            target,
#            'SwitchIngress.npb_ing_sfc_top.ing_sfc_flowtype_class_1',
#            [self.KeyField('ig_md.lkp.ip_type',            self.to_bytes(0, 1)),
#             self.KeyField('ig_md.lkp.ip_proto',           self.to_bytes(proto, 1)),
#             self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 2))],
#            'SwitchIngress.npb_ing_sfc_top.ing_sfc_flowtype_classifier_1_hit',
#            [self.DataField('flow_type',                       self.to_bytes(flow_type, 1))])

		# use for 2 tables (combined 2 and 3)
#        self.insert_table_entry(
#            target,
#            'SwitchIngress.npb_ing_sfc_top.ing_sfc_sfc_class_23',
#            [self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 2)),
#             self.KeyField('ig_md.nsh_extr.extr_flow_type',    self.to_bytes(flow_type, 1))],
#            'SwitchIngress.npb_ing_sfc_top.ing_sfc_sfc_classifier_23_hit',
#            [self.DataField('nsh_sph_spi',                     self.to_bytes(spi, 3)),
#             self.DataField('nsh_sph_si',                      self.to_bytes(si, 1)),
#             self.DataField('sf_bitmask_local',                self.to_bytes(sf_bitmask_local, 1)),
#             self.DataField('sfc',                             self.to_bytes(sfc, 1))])

		# use for 3 tables
#        self.insert_table_entry(
#            target,
#            'SwitchIngress.npb_ing_sfc_top.ing_sfc_sfc_class_2',
#            [self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 2)),
#             self.KeyField('ig_md.nsh_extr.extr_flow_type',    self.to_bytes(flow_type, 1))],
#            'SwitchIngress.npb_ing_sfc_top.ing_sfc_sfc_classifier_2_hit',
#            [self.DataField('nsh_sph_si',                      self.to_bytes(si, 1)),
#             self.DataField('sf_bitmask_local',                self.to_bytes(sf_bitmask_local, 1)),
#             self.DataField('sfc',                             self.to_bytes(sfc, 1))])
#
#        self.insert_table_entry(
#            target,
#            'SwitchIngress.npb_ing_sfc_top.ing_sfc_flow_schd_3',
#            [self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 2)),
#             self.KeyField('ig_md.nsh_extr.extr_flow_type',    self.to_bytes(flow_type, 1)),
#             self.KeyField('sfc_',                             self.to_bytes(sfc, 1))],
#            'SwitchIngress.npb_ing_sfc_top.ing_sfc_flow_schd_3_hit',
#            [self.DataField('nsh_sph_spi',                     self.to_bytes(spi, 3))])

        # -----------------
        # Ingress SFF/SF(s)
        # -----------------

        self.insert_table_entry(
            target,
            'SwitchIngress.npb_ing_sff_top_part2.npb_ing_sff_flow_schd.ing_schd',
            [self.KeyField('ig_md.nsh_extr.sfc',              self.to_bytes(spi, 1))],
            'SwitchIngress.npb_ing_sff_top_part2.npb_ing_sff_flow_schd.ing_schd_hit',
            [self.DataField('nsh_sph_spi',                     self.to_bytes(spi, 3))])

        self.insert_table_entry(
            target,
            'SwitchIngress.npb_ing_sff_top_part2.npb_ing_sff_arp',
            [self.KeyField('ig_md.nsh_extr.spi',               self.to_bytes(spi, 3)),
             self.KeyField('ig_md_nsh_extr_si',                self.to_bytes(si-0, 1))],
            'SwitchIngress.npb_ing_sff_top_part2.dmac_redirect',
            [self.DataField('nexthop_index',                   self.to_bytes(next_hop, 2)),
             self.DataField('sf_bitmask_remote',               self.to_bytes(sf_bitmask_remote, 1)),
             self.DataField('end_of_chain',                    self.to_bytes(  1, 1))])

        # -----------------
        # Ingress NextHop
        # -----------------

        self.insert_table_entry(
            target,
            'SwitchIngress.nexthop.nexthop',
            [self.KeyField('ig_md.nexthop',                    self.to_bytes(next_hop, 2))],
            'SwitchIngress.nexthop.set_nexthop_properties',
            [self.DataField('bd',                              self.to_bytes(bd, 2)),
             self.DataField('port_lag_index',                  self.to_bytes(0, 2)), # unused by switch.p4
             self.DataField('ifindex',                         self.to_bytes(egress_ifindex, 2))])

        # -----------------
        # Ingress Encap (aka Outer NextHop)
        # -----------------

        # -----------------
        # Ingress Lag
        # -----------------

        self.insert_table_entry(
            target,
            'SwitchIngress.lag.lag_selector',
            [self.KeyField('$ACTION_MEMBER_ID',                 self.to_bytes(0, 4))],
            'SwitchIngress.lag.set_lag_port',
            [self.DataField('port',                             self.to_bytes(eg_port, 2))])

        self.insert_table_entry(
            target,
            'SwitchIngress.lag.lag',
            [self.KeyField('port_lag_index',                    self.to_bytes(egress_ifindex, 2))],
            None,
            [self.DataField('$ACTION_MEMBER_ID',                self.to_bytes(0, 4))])

        # ------------------------------------------------------------------
        # Egress
        # ------------------------------------------------------------------

        # -----------------
        # Egress SFF/SF(s)
        # -----------------

        # -----------------
        # Egress Tunnel
        # -----------------

        # -----------------

        time.sleep(1)

        # -----------------------------------------------------------
        # Create the packet
        # -----------------------------------------------------------

#       exp_pkt = testutils.simple_tcp_packet(eth_dst=dmac)
        exp_pkt = testutils.simple_udp_packet(eth_dst=dmac)
        print(type(exp_pkt))

        pkt = \
                testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x894f) / \
                nsh.NSH(mdtype=2, nextproto=3, spi=spi, si=si, ttl=63, vlch=[ \
                        nsh.NSHTLV(metadata=[ \
#                               nsh.Metadata(value=(sf_bitmask_remote<<24)|(tenant_id<<8)|(flow_type)), \
#                               nsh.Metadata(value=(sf_bitmask_remote<<24)|(0<<8)|(0)), \
#                               nsh.Metadata(value=0)  \
                        ]) \
                ]) / \
                exp_pkt
        print(type(pkt))

        # -----------------------------------------------------------
        # Send the packet
        # -----------------------------------------------------------

        logger.info("Sending packet on port %d", ig_port)
        testutils.send_packet(self, ig_port, pkt)

        # -----------------
        # Receive the packet
        # -----------------

        logger.info("Expecting packet on port %d", eg_port)
        testutils.verify_packets(self, exp_pkt, [eg_port])

        # -----------------
        # Don't Receive the packet
        # -----------------

        logger.info("Packet is expected to get dropped.")
        testutils.verify_no_other_packets(self)

        # -----------------------------------------------------------
        # Delete Table Entries
        # -----------------------------------------------------------

#        --- EXAMPLE ---
#        self.delete_table_entry(
#            target,
#            'SwitchIngress.forward',
#            [self.KeyField('hdr.ethernet.dst_addr', self.mac_to_bytes(dmac))])

        # -----------------

        # validation, l2
        self.delete_table_entry(
            target,
            'SwitchIngress.pkt_validation.validate_ethernet',
            [self.KeyField('hdr.ethernet.src_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
             self.KeyField('hdr.ethernet.dst_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
             self.KeyField('hdr.vlan_tag$0.$valid',                   self.to_bytes(0, 1), self.to_bytes(1, 1))])

        # validation, l2
        self.delete_table_entry(
            target,
            'SwitchIngress.pkt_validation.validate_ethernet',
            [self.KeyField('hdr.ethernet.src_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
             self.KeyField('hdr.ethernet.dst_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
             self.KeyField('hdr.vlan_tag$0.$valid',                   self.to_bytes(1, 1), self.to_bytes(1, 1))])

        # validation, l3, v4
        self.delete_table_entry(
            target,
            'SwitchIngress.pkt_validation.validate_ipv4',
            [self.KeyField('flags.ipv4_checksum_err',                   self.to_bytes(0, 1), self.to_bytes(1, 1)),
             self.KeyField('hdr.ipv4.version',                          self.to_bytes(0x4, 1), self.to_bytes(0xf, 1)),
             self.KeyField('hdr.ipv4.ihl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
             self.KeyField('hdr.ipv4.ttl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
             self.KeyField('hdr.ipv4.src_addr[31:24]',                  self.to_bytes(0, 1), self.to_bytes(0, 1))])

        # -----------------

        # validation, l2
        self.delete_table_entry(
            target,
            'SwitchIngress.tunnel_nsh.pkt_validation.validate_ethernet',
            [self.KeyField('hdr.inner_ethernet.dst_addr',               self.to_bytes(0, 6), self.to_bytes(0, 6)),
             self.KeyField('hdr.inner_ethernet.$valid',                self.to_bytes(0, 1))])

        # validation, l3, v4
        self.delete_table_entry(
            target,
            'SwitchIngress.tunnel_nsh.pkt_validation.validate_ipv4',
            [self.KeyField('flags.inner_ipv4_checksum_err',             self.to_bytes(0, 1), self.to_bytes(1, 1)),
             self.KeyField('hdr.inner_ipv4.version',                    self.to_bytes(0x4, 1), self.to_bytes(0xf, 1)),
             self.KeyField('hdr.inner_ipv4.ihl',                        self.to_bytes(0, 1), self.to_bytes(0, 1)),
             self.KeyField('hdr.inner_ipv4.ttl',                        self.to_bytes(0, 1), self.to_bytes(0, 1))])

        # -----------------
        # Ingress SFC
        # -----------------

		# use for 1 table  (combined 1, 2, and 3)
        self.delete_table_entry(
            target,
            'SwitchIngress.npb_ing_sfc_top.ing_sfc_sfc_class_12',
            [self.KeyField('ig_md.lkp.ip_type',            self.to_bytes(1, 1)), # 1 = v4, 2 = v6
             self.KeyField('ig_md.lkp.ip_proto',           self.to_bytes(proto_0, 1)),
             self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 2))])

        self.delete_table_entry(
            target,
            'SwitchIngress.npb_ing_sfc_top.ing_sfc_sfc_class_12',
            [self.KeyField('ig_md.lkp.ip_type',            self.to_bytes(1, 1)), # 1 = v4, 2 = v6
             self.KeyField('ig_md.lkp.ip_proto',           self.to_bytes(proto_1, 1)),
             self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 2))])

		# use for 2 tables (combined 2 and 3)
		# use for 3 tables
#        self.delete_table_entry(
#            target,
#            'SwitchIngress.npb_ing_sfc_top.ing_sfc_flowtype_class_1',
#            [self.KeyField('ig_md.lkp.ip_type',            self.to_bytes(0, 1)),
#             self.KeyField('ig_md.lkp.ip_proto',           self.to_bytes(proto, 1)),
#             self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 2))])

		# use for 2 tables (combined 2 and 3)
#        self.delete_table_entry(
#            target,
#            'SwitchIngress.npb_ing_sfc_top.ing_sfc_sfc_class_23',
#            [self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 2)),
#             self.KeyField('ig_md.nsh_extr.extr_flow_type',    self.to_bytes(flow_type, 1))])

		# use for 3 tables
#        self.delete_table_entry(
#            target,
#            'SwitchIngress.npb_ing_sfc_top.ing_sfc_sfc_class_2',
#            [self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 2)),
#             self.KeyField('ig_md.nsh_extr.extr_flow_type',    self.to_bytes(flow_type, 1))])
#
#        self.delete_table_entry(
#            target,
#            'SwitchIngress.npb_ing_sfc_top.ing_sfc_flow_schd_3',
#            [self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 2)),
#             self.KeyField('ig_md.nsh_extr.extr_flow_type',    self.to_bytes(flow_type, 1)),
#             self.KeyField('sfc_',                             self.to_bytes(sfc, 1))])

        # -----------------
        # Ingress SFF/SF(s)
        # -----------------

        self.delete_table_entry(
            target,
            'SwitchIngress.npb_ing_sff_top_part2.npb_ing_sff_flow_schd.ing_schd',
            [self.KeyField('ig_md.nsh_extr.sfc',              self.to_bytes(spi, 1))])

        self.delete_table_entry(
            target,
            'SwitchIngress.npb_ing_sff_top_part2.npb_ing_sff_arp',
            [self.KeyField('ig_md.nsh_extr.spi',               self.to_bytes(spi, 3)),
             self.KeyField('ig_md_nsh_extr_si',                self.to_bytes(si-0, 1))])

        # -----------------
        # Ingress NextHop
        # -----------------

        self.delete_table_entry(
            target,
            'SwitchIngress.nexthop.nexthop',
            [self.KeyField('ig_md.nexthop',                    self.to_bytes(next_hop, 2))])

        # -----------------
        # Ingress Encap (aka Outer NextHop)
        # -----------------

        # -----------------
        # Ingress Lag
        # -----------------

        # delete in entries in reverse order they were added (not sure if this is necessary or not)
        self.delete_table_entry(
            target,
            'SwitchIngress.lag.lag',
            [self.KeyField('port_lag_index',                    self.to_bytes(egress_ifindex, 2))]) # actual name ig_md.egress_ifindex

        self.delete_table_entry(
            target,
            'SwitchIngress.lag.lag_selector',
            [self.KeyField('$ACTION_MEMBER_ID',                 self.to_bytes(0, 4))])

        # ------------------------------------------------------------------
        # Egress
        # ------------------------------------------------------------------

        # -----------------
        # Egress SFF/SF(s)
        # -----------------

        # -----------------
        # Egress Tunnel
        # -----------------
