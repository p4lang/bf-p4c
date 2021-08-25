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

sys.path.append('/vagrant/tools/npf')
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

################################################################################

class BasicSanityTest(BfRuntimeTest):

    def setUp(self):
        client_id = 0
        p4_name = "p4c_1587"
        BfRuntimeTest.setUp(self, client_id, p4_name)

    # -------------------------------------------------------------

    def send_and_verify_packet(self, ingress_port, egress_port, pkt, exp_pkt):
        logger.info("Sending packet on port %d", ingress_port)
        testutils.send_packet(self, ingress_port, str(pkt))
        logger.info("Expecting packet on port %d", egress_port)
        testutils.verify_packets(self, exp_pkt, [egress_port])

    # -------------------------------------------------------------

    def send_and_verify_no_other_packet(self, ingress_port, pkt):
        logger.info("Sending packet on port %d (negative test); expecting no packet", ingress_port)
        testutils.send_packet(self, ingress_port, str(pkt))
        testutils.verify_no_other_packets(self)

    # -------------------------------------------------------------

    def runTest(self):
        ig_port = swports[0]
        eg_port = swports[0]
        dmac = '22:22:22:22:22:22'

        # Get bfrt_info and set it as part of the test
        self.set_bfrt_info(self.parse_bfrt_info(self.get_bfrt_info("p4c_1587")))

        # -----------------
        # Create the packet
        # -----------------

#       pkt = testutils.simple_tcp_packet(eth_dst=dmac)
        pkt = testutils.simple_udp_packet(eth_dst=dmac)
        exp_pkt = b'\x22\x22\x22\x22\x22\x22\x00\x06\x07\x08\x09\x0A\x89\x4F\x00\x08\x02\x03\x00\x00\x06\x07\x00\x00\x00\x14\x00\x00\x00\x00\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x22\x22\x22\x22\x22\x22\x00\x06\x07\x08\x09\x0A\x08\x00\x45\x00\x00\x56\x00\x01\x00\x00\x40\x11\xF9\x42\xC0\xA8\x00\x01\xC0\xA8\x00\x02\x04\xD2\x00\x50\x00\x42\x49\xA8\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1A\x1B\x1C\x1D\x1E\x1F\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2A\x2B\x2C\x2D\x2E\x2F\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39'

        # -----------------

        target = self.Target(device_id=0, pipe_id=0xffff)

        # -----------------------------------------------------------
        # Positive Test
        # -----------------------------------------------------------

        # vi $SDE/build/p4-examples/npb/tofino2/npb/bf-rt.json

#        --- EXAMPLE ---
#        self.insert_table_entry(
#            target,
#            'SwitchIngress.forward',
#            [self.KeyField('hdr.ethernet.dst_addr', self.mac_to_bytes(dmac))],
#            'SwitchIngress.hit',
#            [self.DataField('port', self.to_bytes(eg_port, 2))])

        # -----------------------
        # Program SFC tables
        # -----------------------

        proto        = 0 # Set this to 0 for now, because i am not programming the validation table
        tenant_id    = 0 # Must be 0 (that's what the default port entry is)
        flow_type    = 3 # Arbitrary value
        spi          = 6 # Arbitrary value
        si           = 7 # Arbitrary value (ttl)
        sfc          = 1 # Arbitrary value
        func_bitmask = 0 # All 3 service functions -- NOTE: BE SURE TO ADJUST SI IN TABLE KEYS DEPENDING ON BITS SET!!!

        next_hop     = 9 # Arbitrary value
        bd           = 9 # Arbitrary value
        tunnel_index = 9 # Arbitrary value
        next_hop_outer = 9 # Arbitrary value

        # -----------------

        # Ingress SFC table(s)
        self.insert_table_entry(
            target,
            'SwitchIngress.npb_ing_sfc_top.table_1',
            [self.KeyField('lkp.ip_proto',                     self.to_bytes(proto, 1)),
             self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 3))],
            'SwitchIngress.npb_ing_sfc_top.table_1_hit',
            [self.DataField('flow_type',                       self.to_bytes(flow_type, 1))])

        self.insert_table_entry(
            target,
            'SwitchIngress.npb_ing_sfc_top.table_2',
            [self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 3)),
             self.KeyField('ig_md.nsh_extr.extr_flow_type',    self.to_bytes(flow_type, 1))],
            'SwitchIngress.npb_ing_sfc_top.table_2_hit',
            [self.DataField('nsh_sph_index',                   self.to_bytes(si, 1)),
             self.DataField('srvc_func_bitmask',               self.to_bytes(func_bitmask, 1)),
             self.DataField('service_func_chain',              self.to_bytes(sfc, 1))])

        self.insert_table_entry(
            target,
            'SwitchIngress.npb_ing_sfc_top.table_3',
            [self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 3)),
             self.KeyField('ig_md.nsh_extr.extr_flow_type',    self.to_bytes(flow_type, 1)),
            self.KeyField('service_func_chain_',               self.to_bytes(sfc, 1))],
            'SwitchIngress.npb_ing_sfc_top.table_3_hit',
            [self.DataField('nsh_sph_path_identifier',         self.to_bytes(spi, 3))])

        # -----------------

        # Ingress SF(s)

        # -----------------

        # Ingress SFF table(s)
        self.insert_table_entry(
            target,
            'SwitchIngress.npb_ing_sff_top.table_1',
            [self.KeyField('ig_md.nsh_extr.spi',               self.to_bytes(spi, 3)),
             self.KeyField('ig_md.nsh_extr.si',                self.to_bytes(si-0, 1))],
            'SwitchIngress.npb_ing_sff_top.fib_hit',
            [self.DataField('nexthop_index',                   self.to_bytes(next_hop, 2)),
             self.DataField('end_of_chain',                    self.to_bytes(  0, 1))])

        # -----------------

        # Ingress NextHop table(s)
        self.insert_table_entry(
            target,
            'SwitchIngress.nexthop.nexthop',
            [self.KeyField('ig_md.nexthop',                    self.to_bytes(next_hop, 2))],
            'SwitchIngress.nexthop.set_tunnel_properties',
            [self.DataField('bd',                              self.to_bytes(bd, 2)),
             self.DataField('tunnel_index',                    self.to_bytes(tunnel_index, 2))])

        self.insert_table_entry(
            target,
            'SwitchIngress.outer_nexthop.nexthop',
            [self.KeyField('ig_md.tunnel.index',               self.to_bytes(tunnel_index, 2))],
            'SwitchIngress.outer_nexthop.set_nexthop_properties',
            [self.DataField('port_lag_index',                  self.to_bytes(0, 2)),
             self.DataField('nexthop_index',                   self.to_bytes(next_hop_outer, 2))])

        # -----------------

        # Egress SF(s)

        # -----------------

        # Egress Rewrite table(s)

        # L2 rewrite -- doesn't modify the packet ***** I THINK WE WANT THIS ONE *****
        self.insert_table_entry(
            target,
            'SwitchEgress.rewrite.nexthop_rewrite',
            [self.KeyField('eg_md.nexthop',                    self.to_bytes(next_hop, 2))],
            'SwitchEgress.rewrite.rewrite_l2_with_tunnel',
            [self.DataField('type',                            self.to_bytes(3, 1))]) # 3 means ETHER tunnel!!!!

        # L3 rewrite -- allows rewriting the dmac, smac, and decrement the ttl
#        self.insert_table_entry(
#            target,
#            'SwitchEgress.rewrite.nexthop_rewrite',
#            [self.KeyField('eg_md.nexthop',                    self.to_bytes(next_hop, 2))],
#            'SwitchEgress.rewrite.rewrite_l3_with_tunnel',
#            [self.DataField('dmac',                            self.to_bytes(0, 6)),
#             self.DataField('type',                            self.to_bytes(3, 1))]) # 3 means ETHER tunnel!!!!!

        # -----------------

        time.sleep(1)

        # -----------------
        # Send the packet
        # -----------------

        logger.info("Sending packet on port %d", ig_port)
        testutils.send_packet(self, ig_port, str(pkt))

        # -----------------
        # Receive the packet
        # -----------------

        logger.info("Expecting packet on port %d", eg_port)
        testutils.verify_packets(self, exp_pkt, [eg_port])

        # -----------------------------------------------------------
        # Negative test
        # -----------------------------------------------------------

#        --- EXAMPLE ---
#        self.delete_table_entry(
#            target,
#            'SwitchIngress.forward',
#            [self.KeyField('hdr.ethernet.dst_addr', self.mac_to_bytes(dmac))])

        # -----------------

        # Ingress SFC table(s)
        self.delete_table_entry(
            target,
            'SwitchIngress.npb_ing_sfc_top.table_1',
            [self.KeyField('lkp.ip_proto',                     self.to_bytes(proto, 1)),
             self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 3))])

        self.delete_table_entry(
            target,
            'SwitchIngress.npb_ing_sfc_top.table_2',
            [self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 3)),
             self.KeyField('ig_md.nsh_extr.extr_flow_type',    self.to_bytes(flow_type, 1))])

        self.delete_table_entry(
            target,
            'SwitchIngress.npb_ing_sfc_top.table_3',
            [self.KeyField('ig_md.nsh_extr.extr_tenant_id',    self.to_bytes(tenant_id, 3)),
             self.KeyField('ig_md.nsh_extr.extr_flow_type',    self.to_bytes(flow_type, 1)),
             self.KeyField('service_func_chain_',              self.to_bytes(sfc, 1))])

        # -----------------

        # Ingress SF(s)

        # -----------------

        # Ingress SFF table(s)
        self.delete_table_entry(
            target,
            'SwitchIngress.npb_ing_sff_top.table_1',
            [self.KeyField('ig_md.nsh_extr.spi',               self.to_bytes(spi, 3)),
             self.KeyField('ig_md.nsh_extr.si',                self.to_bytes(si-0, 1))])

        # -----------------

        # Ingress NextHop table(s)
        self.delete_table_entry(
            target,
            'SwitchIngress.nexthop.nexthop',
            [self.KeyField('ig_md.nexthop',                    self.to_bytes(next_hop, 2))])

        self.delete_table_entry(
            target,
            'SwitchIngress.outer_nexthop.nexthop',
            [self.KeyField('ig_md.tunnel.index',               self.to_bytes(tunnel_index, 2))])

        # -----------------

        # Egress SF(s)

        # -----------------

        # Egress Rewrite table(s)
        self.delete_table_entry(
            target,
            'SwitchEgress.rewrite.nexthop_rewrite',
            [self.KeyField('eg_md.nexthop',                    self.to_bytes(next_hop, 2))])

        # -----------------
        # Send the packet
        # -----------------

#        logger.info("Sending packet on port %d", ig_port)
#        testutils.send_packet(self, ig_port, str(pkt))

        # -----------------
        # Don't Receive the packet
        # -----------------

        logger.info("Packet is expected to get dropped.")
        testutils.verify_no_other_packets(self)
