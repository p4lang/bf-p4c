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
#from pprint import pprint

#sys.path.append('$SDE/pkgsrc/ptf-modules/ptf/src/ptf')
sys.path.append('/home/vagrant/barefoot/bf-sde-8.7.0/pkgsrc/ptf-modules/ptf/src/ptf')
import packet as scapy

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
        p4_name = "npb"
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
        dmac = '22:22:22:22:22:22'

        # Get bfrt_info and set it as part of the test
        self.set_bfrt_info(self.parse_bfrt_info(self.get_bfrt_info("npb")))

        # -----------------
        # Create the packet
        # -----------------

#       pkt = testutils.simple_tcp_packet(eth_dst=dmac)
        pkt = testutils.simple_udp_packet(eth_dst=dmac)
        print(type(pkt))

#        exp_pkt = testutils.simple_eth_packet(pktlen=14, eth_dst=dmac, eth_type=0x894f) / scapy.NSH(MDType=2, NextProto=3, Len=8) / pkt
        exp_pkt = pkt
        print(type(exp_pkt))

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

        proto               = 0 # Set this to 0 for now, because i am not programming the validation table
        tenant_id           = 0 # Must be 0 (that's what the default port entry is)
        flow_type           = 3 # Arbitrary value
        spi                 = 6 # Arbitrary value
        si                  = 7 # Arbitrary value (ttl)
        sfc                 = 1 # Arbitrary value
        func_bitmask_local  = 0 # All 3 service functions -- NOTE: BE SURE TO ADJUST SI IN TABLE KEYS DEPENDING ON BITS SET!!!
        func_bitmask_remote = 0 # All 3 service functions

        next_hop            = 9 # Arbitrary value
        bd                  = 9 # Arbitrary value
        tunnel_index        = 9 # Arbitrary value
        next_hop_outer      = 9 # Arbitrary value


        time.sleep(1)

        # -----------------
        # Send the packet
        # -----------------

        logger.info("Sending packet on port %d", ig_port)
        testutils.send_packet(self, ig_port, pkt)

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

        # -----------------
        # Send the packet
        # -----------------

#        logger.info("Sending packet on port %d", ig_port)
#        testutils.send_packet(self, ig_port, pkt)

        # -----------------
        # Don't Receive the packet
        # -----------------

        logger.info("Packet is expected to get dropped.")
        testutils.verify_no_other_packets(self)

# ################################################################################
# ################################################################################
# class IngressParserTestOuter(BfRuntimeTest):
#
#     '''A test for veryfing the functionality of the NPB ingress parser's
#        outermost (underlay) headers. Pass/Fail is determined by monitoring
#        a set of per header stack counters within the Tofino that increment
#        based on header isValid() conditions.
#
#        This test focuses only on the outer underlay header stack counters
#        within the Tofino. It does not check any of the inner or tunnel
#        counters for correctness. The assumption is these counters will be
#        verified via their own, directed tests.
#     '''
#
#     MIN_NUM_PKTS = 2  # min number of packets per stack
#     MAX_NUM_PKTS = 5  # max number of packets per stack
#
#     # todo: Pull this info in from bfrt.json?
#     # or use this function (def get_bfrt_info()) in bfruntime_base_tests.py
#
#     #CNTR_PROPS = { 'outer' : { 'num_cntrs' : 2048,
#     #                            'addr_fmt' : '011b' }}
#
#     CNTR_PROPS = { 'num_cntrs' : 2048,
#                    'addr_fmt' : '011b' }
#
#
#     # --------------------------------------------------------------------------
#     def setUp(self):
#         client_id = 0
#         p4_name = "npb"
#         BfRuntimeTest.setUp(self, client_id, p4_name)
#
#
#     # Helper function for stripping out header field overrides
#     # --------------------------------------------------------------------------
#     def _wack_overrides(self, stack):
#         # single repetitive regex substitute would be cleaner here.
#         # (had trouble getting that working right)
#
#         hdrs = stack.split("/")
#         return "/".join([re.sub(r'\(.*\)', '()', hdr) for hdr in hdrs ])
#
#
#
#     # Helper function for inserting counter entries
#     # --------------------------------------------------------------------------
#     # todo: Pull all this info in from bfrt.json?
#     def _insert_counter(self, target, addr, data):
#         addr = addr.replace('_','') # prep
#
#         """ Insert a new table entry
#             @param target : target device
#             @param table_name : Table name.
#             @param key_fields : List of (name, value, [mask]) tuples.
#             @param action_name : Action name.
#             @param data_fields : List of (name, value) tuples.
#         """
#
#         self.insert_table_entry(
#             target,
#             'SwitchIngress.IngressHdrStackCounters.cntrs_outer_tbl',
#             [self.KeyField('hdr.ethernet.$valid$', self.to_bytes(int(addr[0]), 1)),
#              self.KeyField('hdr.vlan_tag[0].$valid$', self.to_bytes(int(addr[1]), 1)),
#              self.KeyField('hdr.vlan_tag[1].$valid$', self.to_bytes(int(addr[2]), 1)),
#              self.KeyField('hdr.vlan_tag[2].$valid$', self.to_bytes(int(addr[3]), 1)),
#              self.KeyField('hdr.e_tag.$valid$', self.to_bytes(int(addr[4]), 1)),
#              self.KeyField('hdr.vn_tag.$valid$', self.to_bytes(int(addr[5]), 1)),
#              self.KeyField('cntrs_outer_addr_l3', self.to_bytes(int(addr[6:8],2), 1)),
#              self.KeyField('cntrs_outer_addr_l4', self.to_bytes(int(addr[8:11],2), 1))],
#
#             'SwitchIngress.IngressHdrStackCounters.hit_outer',
#             [self.DataField('$COUNTER_SPEC_PKTS', self.to_bytes(data, 8))])
#
#
#     # Helper function for deleting counter entries
#     # --------------------------------------------------------------------------
#     # todo: Pull all this info in from bfrt.json?
#     def _delete_counter(self, target, addr):
#         addr = addr.replace('_','') # prep
#
#         """ Delete a table entry
#             @param target : target device
#             @param table : Table name.
#             @param key_fields: List of (name, value, [mask]) tuples.
#         """
#
#         self.delete_table_entry(
#             target,
#             'SwitchIngress.IngressHdrStackCounters.cntrs_outer_tbl',
#             [self.KeyField('hdr.ethernet.$valid$', self.to_bytes(int(addr[0]), 1)),
#              self.KeyField('hdr.vlan_tag[0].$valid$', self.to_bytes(int(addr[1]), 1)),
#              self.KeyField('hdr.vlan_tag[1].$valid$', self.to_bytes(int(addr[2]), 1)),
#              self.KeyField('hdr.vlan_tag[2].$valid$', self.to_bytes(int(addr[3]), 1)),
#              self.KeyField('hdr.e_tag.$valid$', self.to_bytes(int(addr[4]), 1)),
#              self.KeyField('hdr.vn_tag.$valid$', self.to_bytes(int(addr[5]), 1)),
#              self.KeyField('cntrs_outer_addr_l3', self.to_bytes(int(addr[6:8],2), 1)),
#              self.KeyField('cntrs_outer_addr_l4', self.to_bytes(int(addr[8:11],2), 1))])
#
#
#     # Helper function for getting counter entries
#     # --------------------------------------------------------------------------
#     # todo: Pull all this info in from bfrt.json?
#     def _get_counter(self, target, addr):
#         addr = addr.replace('_','') # prep
#
#         table_name = 'SwitchIngress.IngressHdrStackCounters.cntrs_outer_tbl'
#         action_name = 'SwitchIngress.IngressHdrStackCounters.hit_outer'
#         data_field_name = '$COUNTER_SPEC_PKTS'
#
#         """ Get a table entry
#             @param target : target device
#             @param table_name : Table name.
#             @param key_fields : List of (name, value, [mask]) tuples.
#             @param flag : dict of flags
#             @param action_name : Action name.
#             @param data_field_ids : List of field_names
#         """
#
#         resp = self.get_table_entry(
#             target,
#             table_name,
#             [self.KeyField('hdr.ethernet.$valid$', self.to_bytes(int(addr[0]), 1)),
#              self.KeyField('hdr.vlan_tag[0].$valid$', self.to_bytes(int(addr[1]), 1)),
#              self.KeyField('hdr.vlan_tag[1].$valid$', self.to_bytes(int(addr[2]), 1)),
#              self.KeyField('hdr.vlan_tag[2].$valid$', self.to_bytes(int(addr[3]), 1)),
#              self.KeyField('hdr.e_tag.$valid$', self.to_bytes(int(addr[4]), 1)),
#              self.KeyField('hdr.vn_tag.$valid$', self.to_bytes(int(addr[5]), 1)),
#              self.KeyField('cntrs_outer_addr_l3', self.to_bytes(int(addr[6:8],2), 1)),
#              self.KeyField('cntrs_outer_addr_l4', self.to_bytes(int(addr[8:11], 2), 1))],
#             {"from_hw":True},
#             action_name,
#             [data_field_name])
#
#         # parse resp to get the counter
#         pkts_field_id = self.get_data_field(table_name, action_name, data_field_name)
#         data_dict = next(self.parseEntryGetResponse(resp))
#         recv_pkts = ''.join(x.encode('hex') for x in str(data_dict[pkts_field_id]))
#         recv_pkts = int(recv_pkts, 16)
#
#         return recv_pkts
#
#
#     # Helper function for determining L2 counter addresses
#     # --------------------------------------------------------------------------
#     def _get_cntrs_addr_L2(self, stack):
#
#         stack = stack.replace(" ","")
#         stack = self._wack_overrides(stack)
#
#         # why do we need this mapping table - why doesn't this match bf-rt.json?
#         # could it be an endianess thing?
#         mt = { 'Ether'   : 1024,   # bit[10]
#                #'Dot1AD'  : 512,    # bit[9]
#                'Dot1Q_0' : 512,    # bit[9]
#                'Dot1Q_1' : 256,    # bit[8]
#                'Dot1Q_2' : 128,    # bit[7]
#                'Dot1BR'  : 64,     # bit[6]
#                'VNTag'   : 32  }   # bit[5]
#
#         hdrs = stack.split("/")
#         addr = 0
#
#         if 'Ether()' in hdrs:
#             addr = addr + mt['Ether']
#         if 'Dot1BR()' in hdrs:
#             addr = addr + mt['Dot1BR']
#         if 'VNTag()' in hdrs:
#             addr = addr + mt['VNTag']
#
#         if hdrs.count('Dot1AD()') == 1 and hdrs.count('Dot1Q()') == 0:
#             addr = addr + mt['Dot1Q_0']
#         elif hdrs.count('Dot1AD()') == 1 and hdrs.count('Dot1Q()') == 1:
#             addr = addr + mt['Dot1Q_0'] + mt['Dot1Q_1']
#         elif hdrs.count('Dot1AD()') == 1 and hdrs.count('Dot1Q()') == 2:
#             addr = addr + mt['Dot1Q_0'] + mt['Dot1Q_1'] + mt['Dot1Q_2']
#         elif hdrs.count('Dot1AD()') == 0 and hdrs.count('Dot1Q()') == 1:
#             addr = addr + mt['Dot1Q_0']
#         elif hdrs.count('Dot1AD()') == 0 and hdrs.count('Dot1Q()') == 2:
#             addr = addr + mt['Dot1Q_0'] + mt['Dot1Q_1']
#         elif hdrs.count('Dot1AD()') == 0 and hdrs.count('Dot1Q()') == 3:
#             addr = addr + mt['Dot1Q_0'] + mt['Dot1Q_1'] + mt['Dot1Q_2']
#
#         if addr == 0:
#             addr = -1
#
#         print("L2 Address Check: %d" %(addr))
#         return addr
#
#     # Helper function for determining L3 counter addresses
#     # --------------------------------------------------------------------------
#     def _get_cntrs_addr_L3(self, stack):
#
#         stack = stack.replace(" ","")
#         stack = self._wack_overrides(stack)
#
#         mt = { 'IP'   : 8,    # bit[4:3] == 1
#                'IPv6' : 16,   # bit[4:3] == 2
#                'ARP'  : 24 }  # bit[4:3] == 3
#
#         hdrs = stack.split("/")
#         addr = 0
#
#         if 'IP()' in hdrs:
#             addr = addr + mt['IP']
#         elif 'IPv6()' in hdrs:
#             addr = addr + mt['IPv6']
#         elif 'ARP()' in hdrs:
#             addr = addr + mt['ARP']
#
#         print("L3 Address Check: %d" %(addr))
#         return addr
#
#
#     # Helper function for determining L4 counter addresses
#     # --------------------------------------------------------------------------
#     def _get_cntrs_addr_L4(self, stack):
#
#         stack = stack.replace(" ","")
#         stack = self._wack_overrides(stack)
#
#         mt = { 'ICMP' : 1,   # bit[2:0] == 1
#                'IGMP' : 2,   # bit[2:0] == 2
#                'UDP'  : 3,   # bit[2:0] == 3
#                'TCP'  : 4,   # bit[2:0] == 4
#                'SCTP' : 5 }  # bit[2:0] == 5
#
#         hdrs = stack.split("/")
#         addr = 0
#
#         if 'ICMP()' in hdrs:
#             addr = addr + mt['ICMP']
#         elif 'IGMP()' in hdrs:
#             addr = addr + mt['IGMP']
#         elif 'UDP()' in hdrs:
#             addr = addr + mt['UDP']
#         elif 'TCP()' in hdrs:
#             addr = addr + mt['TCP']
#         elif 'SCTP()' in hdrs:
#             addr = addr + mt['SCTP']
#         #elif 'ICMPv6()' in hdrs:
#         elif 'ICMPv6EchoRequest()' in hdrs:
#             addr = addr + mt['ICMP']
#
#         print("L4 Address Check: %d" %(addr))
#         return addr
#
#
#     # Helper function for determining counter addresses
#     # --------------------------------------------------------------------------
#     def _get_cntrs_addr(self, soi, stacks):
#
#         addr = -1
#
#         # determine L2 portion of address
#         try:
#             addr = self._get_cntrs_addr_L2(stacks[soi + '_L2'])
#         except KeyError:
#             pass
#
#         assert addr != -1, "ERROR: Unexpected stack"\
#             " encountered (%s)" %(stacks[soi + '_L2'])
#
#         # determine L3 portion of address
#         try:
#             addr = (addr
#                     + self._get_cntrs_addr_L3(stacks[soi + '_L3']))
#         except KeyError:
#             pass
#
#         # determine L4 portion of address
#         try:
#             addr = (addr
#                     + self._get_cntrs_addr_L4(stacks[soi + '_L4']))
#         except KeyError:
#             pass
#
#         print("(Combined) Address Check: %d" %(addr))
#         return addr
#
#
#
#     # Helper function for determining hdr stack from a counter addr (for debug)
#     # --------------------------------------------------------------------------
#     def _addr_2_stack(self, addr):
#
#         # important to note here that the order of L2 headers within a stack
#         # might not match the actual order in the pkt that was sent (npf yaml).
#         # again, all this bit-position stuff should be coming from bfrt!
#
#         stack = ""
#
#         # L2 portion (bits[10:5])
#         if addr>>10 & 1:
#             stack = stack + "Ether()"
#         if addr>>6 & 1:
#             stack = stack + "Dot1BR()"
#         if addr>>5 & 1:
#             stack = stack + "VNTag()"
#         if addr>>9 & 1:
#             stack = stack + "Dot1Q()"
#         if addr>>8 & 1:
#             stack = stack + "Dot1Q()"
#         if addr>>7 & 1:
#             stack = stack + "Dot1Q()"
#
#         # L3 portion (bits[4:3])
#         if addr>>3 & 3 == 1:
#             stack = stack + "IP()"
#         elif addr>>3 & 3 == 2:
#             stack = stack + "IPv6()"
#         elif addr>>3 & 3 == 3:
#             stack = stack + "ARP()"
#
#         # L4 portion (bits[2:0])
#         if addr & 7 == 1:
#             stack = stack + "ICMP()"
#         elif addr & 7 == 2:
#             stack = stack + "IGMP()"
#         elif addr & 7 == 3:
#             stack = stack + "UDP()"
#         elif addr & 7 == 4:
#             stack = stack + "TCP()"
#         elif addr & 7 == 5:
#             stack = stack + "SCTP()"
#
#         # cleanup
#         if len(stack) > 0:
#             stack = stack.replace(" ","")
#             stack = stack.replace("()","() / ")
#             stack = stack[:-3]
#
#         return stack
#
#
#     # --------------------------------------------------------------------------
#     def runTest(self):
#
#         ig_port = 1
#         target = self.Target(device_id=0, pipe_id=0xffff)
#
#         testdir = '/vagrant/pkgsrc/p4-examples/p4_16_programs/npb/'
#         npf_cfg_yaml = testdir + 'npb_ing_parser_npf.yaml'
#
#         # ----------------------------------------------------------------------
#         pkt_template_categories = ['outer']
#
#         pkt_template_names = ['L2',
#                               'L3',
#                               'L4_ipv4_icmp',
#                               'L4_ipv4_igmp',
#                               'L4_ipv6_icmp',
#                               'L4_transport' ] # determines order of tests
#
#         # ----------------------------------------------------------------------
#
#         Stacks = HdrStacks() # instantiate NPF HdrStacks class
#
#         # Get bfrt_info and set it as part of the test
#         self.set_bfrt_info(self.parse_bfrt_info(self.get_bfrt_info("npb")))
#
#         # Load NPF Config (into dict)
#         assert os.path.isfile(npf_cfg_yaml), \
#             "ERROR: NPF Config file (%s) not found." %(npf_cfg_yaml)
#
#         logger.info("\nLoad NPF Config: %s" %(npf_cfg_yaml))
#         npf_cfg_raw = open(npf_cfg_yaml, 'r')
#         npf_cfg = yaml.load(npf_cfg_raw)
#
#         # Create Header Stacks (from config)
#         stacks_df = Stacks.build(npf_cfg['pkt_templates'])
#         assert(len(stacks_df) > 0), "ERROR: No pkt templates present in %s" \
#             %(npf_cfg_yaml)
#
#         # Create pcaps folder if it doesn't already exist
#         # if(not os.path.exists(testdir + 'pcaps')):
#         os.system('mkdir -p %s' %(testdir + 'pcaps'))
#
#
#         # Loop through each packet template category
#         for category in pkt_template_categories:
#
#             # Filter pkt templates (for this category)
#             stacks_df_filtered_cat = Stacks.filter(stacks_df,
#                                                    'category',
#                                                    [category])
#
#             templates = set(stacks_df_filtered_cat['name'].tolist())
#             logger.info("The following (%d) packet templates were found for"
#                         " category \"%s\":", len(templates), category)
#             logger.info("  %s", templates)
#             #Stacks.show(stacks_df_filtered_cat)
#
#             logger.info("The following (%d) packet templates were requested"
#                         " for testing:", len(pkt_template_names))
#             logger.info("  %s", pkt_template_names)
#
#
#             # Loop through all the requested packet templates (names)
#             for template in pkt_template_names:
#
#                 testname = "_".join([category, template])
#
#                 logger.info("")
#                 logger.info("-----------------------------------------")
#                 logger.info("Begin parser test: %s\n", testname)
#
#                 # Filter pkt templates (for this name)
#                 stacks_df_filtered_name = (
#                     Stacks.filter(stacks_df_filtered_cat,
#                                   'name',
#                                   [template]))
#
#                 ################################################################
#                 logger.info("Prepare Stimulus:")
#                 ################################################################
#
#                 pcap = "".join([testdir,
#                                 'pcaps/pkts_',
#                                 testname,
#                                 '.pcap'])
#
#                 # Wack old pcap
#                 if os.path.isfile("%s" %(pcap)):
#                     os.system("rm %s" %(pcap))
#
#                 # Determine number of pkts to be sent (per hdr stack)
#                 pkts_per_stack = random.randrange(self.MIN_NUM_PKTS,
#                                                   self.MAX_NUM_PKTS)
#                 logger.info("  Number of packets per header stack: %d",
#                             pkts_per_stack)
#
#                 # Generate stimulus pcap (via network packet factory)
#                 logger.info("  Create stimulus pcap file (via npf): %s",
#                             pcap)
#
#                 npf.main(['-i',        npf_cfg_yaml,
#                           '-category', category,
#                           '-name',     template,
#                           '-write',    pcap,
#                           '-num_pkts', str(pkts_per_stack)])
#
#
#                 ################################################################
#                 logger.info("Determine Expected Results")
#                 ################################################################
#
#                 # Determine stack of interest (outermost header stack)
#                 # (this can vary depending on template structure)
#                 soi = Stacks.outermost_stack(stacks_df_filtered_name)
#
#                 # Determine list of cntr addresses that should see hits
#                 exp_cntr_addrs = []
#
#                 for (index, row) in stacks_df_filtered_name.iterrows():
#
#                     addr = self._get_cntrs_addr(soi, row)
#
#                     exp_cntr_addrs.append(addr)
#                     # print("Expected counter addresses: %s" %(addr))
#                     # todo: assert len(list) == len(stacks_df_filtered_name)
#                     # todo: assert no '11_1111_1111_1111' addresses in list
#
#                 # Determine the expected counter values
#                 exp_cntr_data = (
#                     [(exp_cntr_addrs.count(exp_cntr_addr) * pkts_per_stack)
#                       for exp_cntr_addr in exp_cntr_addrs ])
#
#                 # create addr/value pairs
#                 exp_results = [av for av in zip(exp_cntr_addrs, exp_cntr_data)]
#                 exp_results = set(exp_results) # remove duplicates
#
#                 ################################################################
#                 logger.info("Prepare DUT:")
#                 ################################################################
#                 # this is not perfect - we kick out after the first delete error
#                 # which prevents error msgs from scrolling up the screen for all
#                 # counters. A safer solution might be to include both the delete
#                 # and insert calls within the same for loop (tradeoff being that
#                 # error msgs can scroll).
#
#                 # Clear all DUT counters
#                 logger.info("  Clear all DUT header stack counters")
#
#                 for addr in range(self.CNTR_PROPS['num_cntrs']):
#
#                     # this will produce errors the first time through
#                     try:
#                         self._delete_counter(
#                             target,
#                             str(format(addr, self.CNTR_PROPS['addr_fmt']))) #asdf
#                     except:
#                         print("The above errors are a result of the attempted"
#                               " cleanup effort - Please disregard")
#                         break
#
#                 for addr in range(self.CNTR_PROPS['num_cntrs']):
#                     self._insert_counter(
#                         target,
#                         str(format(addr, self.CNTR_PROPS['addr_fmt'])),
#                         0)
#
#                 ################################################################
#                 logger.info("Stimulate DUT:")
#                 ################################################################
#
#                 # Read stimulus pcap
#                 logger.info("  Read Stimulus PCAP (%s)", pcap)
#                 pkts = rdpcap("%s" %(pcap))
#
#                 logger.info("  Send %d packet(s) on tofino port %d",
#                             len(pkts), ig_port)
#
#                 for pkt in pkts:
#
#                     # Send packet(s)
#                     testutils.send_packet(self, ig_port, pkt)
#
#                 time.sleep(len(pkts)*0.2) # allow packets to move
#
#                 # # debug - see what cntrs were acutally bumped
#                 # idx = 0
#                 # for addr in range(self.CNTR_PROPS['num_cntrs']):
#                 #
#                 #     act_cnt = self._get_counter(
#                 #         target,
#                 #         str(format(addr,self.CNTR_PROPS['addr_fmt'])))
#                 #
#                 #     if act_cnt > 0:
#                 #         print(idx,
#                 #               addr,
#                 #               str(format(addr,self.CNTR_PROPS['addr_fmt'])),
#                 #               act_cnt)
#                 #         idx = idx + 1
#
#
#                 ################################################################
#                 logger.info("Check Results:")
#                 ################################################################
#
#                 for idx, (exp_cntr_addr, exp_cntr_data) in enumerate(exp_results):
#
#                     # attempt to recreate the header stack here from expected
#                     # address to aid in debug if something goes wrong.
#                     # (as opposed to simply showing the stack from the df)
#                     # important - recreated stack might not show the headers
#                     # in the same order that the actual packet had them.
#                     stack = self._addr_2_stack(exp_cntr_addr)
#                     logger.info("  %d Reading counter: addr = %d (0x%x) (%s),"
#                                 " expected data = %d, predicted stack = %s",
#                                 idx, exp_cntr_addr, exp_cntr_addr,
#                                 bin(exp_cntr_addr), exp_cntr_data, stack)
#
#                     act_cnt = self._get_counter(
#                         target,
#                         #str(format(exp_cntr_addr,'006b')))
#                         str(format(exp_cntr_addr,self.CNTR_PROPS['addr_fmt'])))
#
#                     assert act_cnt == exp_cntr_data, "  ERROR (addr%d):" \
#                         " Actual counter (%d) doesn't match expected (%d)" \
#                         %(exp_cntr_addr, act_cnt, exp_cntr_data)
#
#                 logger.info("  PASS")
#
#                     # todo: if counters don't match, should we dump all cntrs
#                     # to aid in debug? Or show all non-zero counters?
#                     # there's a debug routine above in the code that does this.
#                     # it's commented out by default.
#
#
#
# ################################################################################
# ################################################################################
# class IngressParserTestOuterTunnel(BfRuntimeTest):
#
#     '''A test for veryfing the functionality of the NPB ingress parser's
#        outermost tunnel headers. Pass/Fail is determined by monitoring
#        a set of per header stack counters within the Tofino that increment
#        based on header isValid() conditions.
#
#        This test focuses only on the outer tunnel header stack counters
#        within the Tofino. It does not check all the outer (underlay), or
#        inner counters for correctness. The assumption is these counters
#        will be verified via their own, directed tests. That being said,
#        all upper layers (ie. underlay) paths through the parser are
#        exercised during this test, and counter checks should ensure all
#        packets made it to their final expected parser state.
#     '''
#
#     MIN_NUM_PKTS = 2  # min number of packets per stack
#     MAX_NUM_PKTS = 5  # max number of packets per stack
#
#
#     # todo: Pull this info in from bfrt.json?
#     # or use this function (def get_bfrt_info()) in bfruntime_base_tests.py
#
#     CNTR_PROPS = { 'num_cntrs' : 512,
#                    'addr_fmt' : '009b' }
#
#     # --------------------------------------------------------------------------
#     def setUp(self):
#         client_id = 0
#         p4_name = "npb"
#         BfRuntimeTest.setUp(self, client_id, p4_name)
#
#
#     # Helper function for stripping out header field overrides
#     # --------------------------------------------------------------------------
#     def _wack_overrides(self, stack):
#         # single repetitive regex substitute would be cleaner here.
#         # (had trouble getting that working right)
#
#         hdrs = stack.split("/")
#         return "/".join([re.sub(r'\(.*\)', '()', hdr) for hdr in hdrs ])
#
#
#     # Helper function for inserting counter entries
#     # --------------------------------------------------------------------------
#     # todo: Pull all this info in from bfrt.json?
#     def _insert_counter(self, target, addr, data):
#         addr = addr.replace('_','') # prep
#
#         """ Insert a new table entry
#             @param target : target device
#             @param table_name : Table name.
#             @param key_fields : List of (name, value, [mask]) tuples.
#             @param action_name : Action name.
#             @param data_fields : List of (name, value) tuples.
#         """
#
#         self.insert_table_entry(
#             target,
#             'SwitchIngress.IngressHdrStackCounters.cntrs_outer_tunnel_tbl',
#
#             [self.KeyField('hdr.mpls[0].$valid$', self.to_bytes(int(addr[0]), 1)),
#              self.KeyField('hdr.mpls[1].$valid$', self.to_bytes(int(addr[1]), 1)),
#              self.KeyField('hdr.mpls[2].$valid$', self.to_bytes(int(addr[2]), 1)),
#              self.KeyField('hdr.mpls[3].$valid$', self.to_bytes(int(addr[3]), 1)),
#              self.KeyField('hdr.mpls_pw_cw.$valid$', self.to_bytes(int(addr[4]), 1)),
#              self.KeyField('cntrs_outer_tnl_addr', self.to_bytes(int(addr[5:9],2), 1))],
#             'SwitchIngress.IngressHdrStackCounters.hit_outer_tunnel',
#             [self.DataField('$COUNTER_SPEC_PKTS', self.to_bytes(data, 8))])
#
#
#     # Helper function for deleting counter entries
#     # --------------------------------------------------------------------------
#     # todo: Pull all this info in from bfrt.json?
#     def _delete_counter(self, target, addr):
#         addr = addr.replace('_','') # prep
#
#         """ Delete a table entry
#             @param target : target device
#             @param table : Table name.
#             @param key_fields: List of (name, value, [mask]) tuples.
#         """
#
#         self.delete_table_entry(
#             target,
#             'SwitchIngress.IngressHdrStackCounters.cntrs_outer_tunnel_tbl',
#
#             [self.KeyField('hdr.mpls[0].$valid$', self.to_bytes(int(addr[0]), 1)),
#              self.KeyField('hdr.mpls[1].$valid$', self.to_bytes(int(addr[1]), 1)),
#              self.KeyField('hdr.mpls[2].$valid$', self.to_bytes(int(addr[2]), 1)),
#              self.KeyField('hdr.mpls[3].$valid$', self.to_bytes(int(addr[3]), 1)),
#              self.KeyField('hdr.mpls_pw_cw.$valid$', self.to_bytes(int(addr[4]), 1)),
#              self.KeyField('cntrs_outer_tnl_addr', self.to_bytes(int(addr[5:9],2), 1))])
#
#
#     # Helper function for getting counter entries
#     # --------------------------------------------------------------------------
#     # todo: Pull all this info in from bfrt.json?
#     def _get_counter(self, target, addr):
#         addr = addr.replace('_','') # prep
#
#         table_name = 'SwitchIngress.IngressHdrStackCounters.cntrs_outer_tunnel_tbl'
#         action_name = 'SwitchIngress.IngressHdrStackCounters.hit_outer_tunnel'
#         data_field_name = '$COUNTER_SPEC_PKTS'
#
#         """ Get a table entry
#             @param target : target device
#             @param table_name : Table name.
#             @param key_fields : List of (name, value, [mask]) tuples.
#             @param flag : dict of flags
#             @param action_name : Action name.
#             @param data_field_ids : List of field_names
#         """
#
#         resp = self.get_table_entry(
#             target,
#             table_name,
#             [self.KeyField('hdr.mpls[0].$valid$', self.to_bytes(int(addr[0]), 1)),
#              self.KeyField('hdr.mpls[1].$valid$', self.to_bytes(int(addr[1]), 1)),
#              self.KeyField('hdr.mpls[2].$valid$', self.to_bytes(int(addr[2]), 1)),
#              self.KeyField('hdr.mpls[3].$valid$', self.to_bytes(int(addr[3]), 1)),
#              self.KeyField('hdr.mpls_pw_cw.$valid$', self.to_bytes(int(addr[4]), 1)),
#              self.KeyField('cntrs_outer_tnl_addr', self.to_bytes(int(addr[5:9],2), 1))],
#             {"from_hw":True},
#             action_name,
#             [data_field_name])
#
#         # parse resp to get the counter
#         pkts_field_id = self.get_data_field(table_name, action_name, data_field_name)
#         data_dict = next(self.parseEntryGetResponse(resp))
#         recv_pkts = ''.join(x.encode('hex') for x in str(data_dict[pkts_field_id]))
#         recv_pkts = int(recv_pkts, 16)
#
#         return recv_pkts
#
#
#
#     # Helper function for determining counter addresses
#     # --------------------------------------------------------------------------
#     def _get_cntrs_addr(self, soi, stacks):
#
#         stack = stacks[soi + '_tunnel']
#
#         # prep stack for address decode
#         stack = stack.replace(" ","")
#         stack = stack.replace("GRE(key_present=1)","NVGRE()")
#
#         # todo: this really should catch all combos of E/S/PN
#         stack = stack.replace("GTPHeader(E=1)","GTP_OPT()")
#         stack = stack.replace("GTPHeader(S=1)","GTP_OPT()")
#         stack = stack.replace("GTPHeader(PN=1)","GTP_OPT()")
#         stack = stack.replace("GTPEchoRequest()","GTP_OPT()")
#
#         stack = stack.replace("GTP_U_Header(E=1)","GTP_OPT()")
#         stack = stack.replace("GTP_U_Header(S=1)","GTP_OPT()")
#         stack = stack.replace("GTP_U_Header(PN=1)","GTP_OPT()")
#         stack = self._wack_overrides(stack)
#
#         # why do we need this mapping table - why doesn't this match bf-rt.json?
#         # could it be an endianess thing?
#         mt = { 'NSH'        : 1,    # bit[3:0] == 1
#                'ERSPAN_I'   : 2,    # bit[3:0] == 2
#                'ERSPAN_II'  : 3,    # bit[3:0] == 3
#                'VXLAN'      : 4,    # bit[3:0] == 4
#                'NVGRE'      : 5,    # bit[3:0] == 5
#                'GRE'        : 6,    # bit[3:0] == 6
#                'ESP'        : 7,    # bit[3:0] == 7
#                'GTP_OPT'    : 8,    # bit[3:0] == 8
#                'GTP'        : 9,    # bit[3:0] == 9
#
#                'MPLS_PW_CW' : 16,   # bit[4]
#                'MPLS_3'     : 32,   # bit[5]
#                'MPLS_2'     : 64,   # bit[6]
#                'MPLS_1'     : 128,  # bit[7]
#                'MPLS_0'     : 256 } # bit[8]
#
#         hdrs = stack.split("/")
#         addr = 0
#
#         if 'NSH()' in hdrs:
#             addr = addr + mt['NSH']
#         elif 'ERSPAN_I()' in hdrs:
#             addr = addr + mt['ERSPAN_I']
#         elif 'ERSPAN_II()' in hdrs:
#             addr = addr + mt['ERSPAN_II']
#         elif 'VXLAN()' in hdrs:
#             addr = addr + mt['VXLAN']
#         elif 'GRE()' in hdrs:
#             addr = addr + mt['GRE']
#         elif 'NVGRE()' in hdrs:
#             addr = addr + mt['NVGRE']
#         elif 'ESP()' in hdrs:
#             addr = addr + mt['ESP']
#         elif 'GTP_OPT()' in hdrs:
#             addr = addr + mt['GTP_OPT']
#         elif ('GTPHeader()' in hdrs) or ('GTP_U_Header()' in hdrs):
#             addr = addr + mt['GTP']
#
#         if hdrs.count('MPLS()') == 1:
#             addr = addr + mt['MPLS_0']
#         elif hdrs.count('MPLS()') == 2:
#             addr = addr + mt['MPLS_0'] + mt['MPLS_1']
#         elif hdrs.count('MPLS()') == 3:
#             addr = addr + mt['MPLS_0'] + mt['MPLS_1'] + mt['MPLS_2']
#         elif hdrs.count('MPLS()') == 4:
#             addr = addr + mt['MPLS_0'] + mt['MPLS_1'] + mt['MPLS_2'] + mt['MPLS_3']
#
#         if 'EoMCW()' in hdrs:
#             addr = addr + mt['MPLS_PW_CW']
#
#         print("Tunnel Address Check: %d" %(addr))
#         return addr
#
#
#     # Helper function for determining hdr stack from a counter addr (for debug)
#     # --------------------------------------------------------------------------
#     def _addr_2_stack(self, addr):
#
#         # important to note here that the order of L2 headers within a stack
#         # might not match the actual order in the pkt that was sent (npf yaml).
#         # again, all this bit-position stuff should be coming from bfrt!
#
#         stack = ""
#
#         # The rest (bits[3:0])
#         if addr & 15 == 1:
#             stack = stack + "NSH()"
#         elif addr & 15 == 2:
#             stack = stack + "GRE / ERSPAN_I()"
#         elif addr & 15 == 3:
#             stack = stack + "GRE / ERSPAN_II()"
#         elif addr & 15 == 4:
#             stack = stack + "VXLAN()"
#         elif addr & 15 == 5:
#             stack = stack + "NVGRE()"
#         elif addr & 15 == 6:
#             stack = stack + "GRE()"
#         elif addr & 15 == 7:
#             stack = stack + "ESP()"
#         elif addr & 15 == 8:
#             stack = stack + "GTP_OPT()"
#         elif addr & 15 == 9:
#             stack = stack + "GTP()"
#
#         # MPLS portion (bits[8:4])
#         if addr>>8 & 1:
#             stack = stack + "MPLS()"
#         if addr>>7 & 1:
#             stack = stack + "MPLS()"
#         if addr>>6 & 1:
#             stack = stack + "MPLS()"
#         if addr>>5 & 1:
#             stack = stack + "MPLS()"
#         if addr>>4 & 1:
#             stack = stack + "EoMCW()"
#
#         # cleanup
#         if len(stack) > 0:
#             stack = stack.replace(" ","")
#             stack = stack.replace("()","() / ")
#             stack = stack[:-3]
#
#         return stack
#
#
#
#     # --------------------------------------------------------------------------
#     def runTest(self):
#
#         ig_port = 1
#         target = self.Target(device_id=0, pipe_id=0xffff)
#
#         testdir = '/vagrant/pkgsrc/p4-examples/p4_16_programs/npb/'
#         npf_cfg_yaml = testdir + 'npb_ing_parser_npf.yaml'
#
#         # ----------------------------------------------------------------------
#         pkt_template_categories = ['outer_tunnel']
#         pkt_template_names = ['nsh',
#                               'erspan_1',
#                               'erspan_2',
#                               'vxlan',
#                               'mpls_l3vpn',
#                               'mpls_pw_l2vpn',
#                               'gre',
#                               'gre_mpls_l3vpn',
#                               'gre_mpls_pw_l2vpn',
#                               'nvgre',
#                               'gtp_c',
#                               'gtp_u',
#                               'esp' ] # determines order of tests
#
#
#         #pkt_template_names = ['esp'] # override
#         # ----------------------------------------------------------------------
#
#         Stacks = HdrStacks() # instantiate NPF HdrStacks class
#
#         # Get bfrt_info and set it as part of the test
#         self.set_bfrt_info(self.parse_bfrt_info(self.get_bfrt_info("npb")))
#
#         # Load NPF Config (into dict)
#         assert os.path.isfile(npf_cfg_yaml), \
#             "ERROR: NPF Config file (%s) not found." %(npf_cfg_yaml)
#
#         logger.info("\nLoad NPF Config: %s" %(npf_cfg_yaml))
#         npf_cfg_raw = open(npf_cfg_yaml, 'r')
#         npf_cfg = yaml.load(npf_cfg_raw)
#
#         # Create Header Stacks (from config)
#         stacks_df = Stacks.build(npf_cfg['pkt_templates'])
#         assert(len(stacks_df) > 0), "ERROR: No pkt templates present in %s" \
#             %(npf_cfg_yaml)
#
#         # Create pcaps folder if it doesn't already exist
#         # if(not os.path.exists(testdir + 'pcaps')):
#         os.system('mkdir -p %s' %(testdir + 'pcaps'))
#
#
#         # Loop through each packet template category
#         for category in pkt_template_categories:
#
#             # Filter pkt templates (for this category)
#             stacks_df_filtered_cat = Stacks.filter(stacks_df,
#                                                    'category',
#                                                    [category])
#
#             templates = set(stacks_df_filtered_cat['name'].tolist())
#
#             logger.info("The following (%d) packet templates were found for"
#                         " category \"%s\":", len(templates), category)
#             logger.info("  %s", templates)
#             #Stacks.show(stacks_df_filtered_cat)
#
#             logger.info("The following (%d) packet templates were requested"
#                         " for testing:", len(pkt_template_names))
#             logger.info("  %s", pkt_template_names)
#
#
#             # Loop through all the requested packet templates (names)
#             for template in pkt_template_names:
#
#                 testname = "_".join([category, template])
#
#                 logger.info("")
#                 logger.info("-----------------------------------------")
#                 logger.info("Begin parser test: %s\n", testname)
#
#                 # Filter pkt templates (for this name)
#                 stacks_df_filtered_name = (
#                     Stacks.filter(stacks_df_filtered_cat,
#                                   'name',
#                                   [template]))
#
#                 ################################################################
#                 logger.info("Prepare Stimulus:")
#                 ################################################################
#
#                 pcap = "".join([testdir,
#                                 'pcaps/pkts_',
#                                 testname,
#                                 '.pcap'])
#
#                 # Wack old pcap
#                 if os.path.isfile("%s" %(pcap)):
#                     os.system("rm %s" %(pcap))
#
#                 # Determine number of pkts to be sent (per hdr stack)
#                 pkts_per_stack = random.randrange(self.MIN_NUM_PKTS,
#                                                   self.MAX_NUM_PKTS)
#                 logger.info("  Number of packets per header stack: %d",
#                             pkts_per_stack)
#
#                 # Generate stimulus pcap (via network packet factory)
#                 logger.info("  Create stimulus pcap file (via npf): %s",
#                             pcap)
#
#                 npf.main(['-i',        npf_cfg_yaml,
#                           '-category', category,
#                           '-name',     template,
#                           '-write',    pcap,
#                           '-num_pkts', str(pkts_per_stack)])
#
#                 ################################################################
#                 logger.info("Determine Expected Results")
#                 ################################################################
#
#                 # Determine stack of interest (outermost header stack)
#                 # (this can vary depending on template structure)
#                 soi = Stacks.outermost_stack(stacks_df_filtered_name)
#
#                 # Determine list of cntr addresses that should see hits
#                 exp_cntr_addrs = []
#
#                 for (index, row) in stacks_df_filtered_name.iterrows():
#
#                     addr = self._get_cntrs_addr(soi, row)
#
#                     exp_cntr_addrs.append(addr)
#                     # print("Expected counter addresses: %s" %(addr))
#                     # todo: assert len(list) == len(stacks_df_filtered_name)
#                     # todo: assert no '11_1111_1111_1111' addresses in list
#
#                 # Determine the expected counter values
#                 exp_cntr_data = (
#                     [(exp_cntr_addrs.count(exp_cntr_addr) * pkts_per_stack)
#                       for exp_cntr_addr in exp_cntr_addrs ])
#
#                 # create addr/value pairs
#                 exp_results = [av for av in zip(exp_cntr_addrs, exp_cntr_data)]
#                 exp_results = set(exp_results) # remove duplicates
#
#
#                 ################################################################
#                 logger.info("Prepare DUT:")
#                 ################################################################
#                 # this is not perfect - we kick out after the first delete error
#                 # which prevents error msgs from scrolling up the screen for all
#                 # counters. A safer solution might be to include both the delete
#                 # and insert calls within the same for loop (tradeoff being that
#                 # error msgs can scroll).
#
#                 # Clear all DUT counters
#                 logger.info("  Clear all DUT header stack counters")
#
#                 for addr in range(self.CNTR_PROPS['num_cntrs']):
#
#                     # this will produce errors the first time through
#                     try:
#                         self._delete_counter(
#                             target,
#                             str(format(addr, self.CNTR_PROPS['addr_fmt']))) #asdf
#                     except:
#                         print("The above errors are a result of the attempted"
#                               " cleanup effort - Please disregard")
#                         break
#
#                 for addr in range(self.CNTR_PROPS['num_cntrs']):
#                     self._insert_counter(
#                         target,
#                         str(format(addr, self.CNTR_PROPS['addr_fmt'])),
#                         0)
#
#
#                 ################################################################
#                 logger.info("Stimulate DUT:")
#                 ################################################################
#
#                 # Read stimulus pcap
#                 logger.info("  Read Stimulus PCAP (%s)", pcap)
#                 pkts = rdpcap("%s" %(pcap))
#
#                 logger.info("  Send %d packet(s) on tofino port %d",
#                             len(pkts), ig_port)
#
#                 for pkt in pkts:
#
#                     # Send packet(s)
#                     testutils.send_packet(self, ig_port, str(pkt))
#
#                 time.sleep(len(pkts)*0.2) # allow packets to move
#
#                 # # debug - see what cntrs were acutally bumped
#                 # idx = 0
#                 # for addr in range(self.CNTR_PROPS['num_cntrs']):
#                 #
#                 #     act_cnt = self._get_counter(
#                 #         target,
#                 #         str(format(addr,self.CNTR_PROPS['addr_fmt'])))
#                 #
#                 #     if act_cnt > 0:
#                 #         print(idx,
#                 #               addr,
#                 #               str(format(addr,self.CNTR_PROPS['addr_fmt'])),
#                 #               act_cnt)
#                 #         idx = idx + 1
#
#
#                 ################################################################
#                 logger.info("Check Results:")
#                 ################################################################
#
#                 for idx, (exp_cntr_addr, exp_cntr_data) in enumerate(exp_results):
#
#                     # attempt to recreate the header stack here from expected
#                     # address to aid in debug if something goes wrong.
#                     # (as opposed to simply showing the stack from the df)
#                     # important - recreated stack might not show the headers
#                     # in the same order that the actual packet had them.
#                     stack = self._addr_2_stack(exp_cntr_addr)
#                     logger.info("  %d Reading counter: addr = %d (0x%x) (%s),"
#                                 " expected data = %d, predicted stack = %s",
#                                 idx, exp_cntr_addr, exp_cntr_addr,
#                                 bin(exp_cntr_addr), exp_cntr_data, stack)
#
#                     act_cnt = self._get_counter(
#                         target,
#                         #str(format(exp_cntr_addr,'006b')))
#                         str(format(exp_cntr_addr,self.CNTR_PROPS['addr_fmt'])))
#
#                     assert act_cnt == exp_cntr_data, "  ERROR (addr%d):" \
#                         " Actual counter (%d) doesn't match expected (%d)" \
#                         %(exp_cntr_addr, act_cnt, exp_cntr_data)
#
#                 logger.info("  PASS")
#
#                     # todo: if counters don't match, should we dump all cntrs
#                     # to aid in debug? Or show all non-zero counters?
#                     # there's a debug routine above in the code that does this.
#                     # it's commented out by default.




# ################################################################################
# ################################################################################
# class IngressParserTestInner(BfRuntimeTest):
#
#     '''A test for veryfing the functionality of the NPB ingress parser's
#        inner L2-L4 headers. Pass/Fail is determined by monitoring
#        a set of per header stack counters within the Tofino that increment
#        based on header isValid() conditions.
#
#        This test focuses only on the inner (inside the first tunnel layer)
#        L2-L4 header stack counters within the Tofino. It does not check any
#        of the inner tunnel or outer counters for correctness. The assumption
#        is these counters will be verified via their own, directed tests.
#     '''
#
#     MIN_NUM_PKTS = 2  # min number of packets per stack
#     MAX_NUM_PKTS = 5  # max number of packets per stack
#
#     # todo: Pull this info in from bfrt.json?
#     # or use this function (def get_bfrt_info()) in bfruntime_base_tests.py
#
#     #CNTR_PROPS = { 'outer' : { 'num_cntrs' : 2048,
#     #                            'addr_fmt' : '011b' }}
#
#     CNTR_PROPS = { 'num_cntrs' : 128,
#                    'addr_fmt' : '007b' }
#
#
#     # --------------------------------------------------------------------------
#     def setUp(self):
#         client_id = 0
#         p4_name = "npb"
#         BfRuntimeTest.setUp(self, client_id, p4_name)
#
#
#     # Helper function for stripping out header field overrides
#     # --------------------------------------------------------------------------
#     def _wack_overrides(self, stack):
#         # single repetitive regex substitute would be cleaner here.
#         # (had trouble getting that working right)
#
#         hdrs = stack.split("/")
#         return "/".join([re.sub(r'\(.*\)', '()', hdr) for hdr in hdrs ])
#
#
#
#     # Helper function for inserting counter entries
#     # --------------------------------------------------------------------------
#     # todo: Pull all this info in from bfrt.json?
#     def _insert_counter(self, target, addr, data):
#         addr = addr.replace('_','') # prep
#
#         """ Insert a new table entry
#             @param target : target device
#             @param table_name : Table name.
#             @param key_fields : List of (name, value, [mask]) tuples.
#             @param action_name : Action name.
#             @param data_fields : List of (name, value) tuples.
#         """
#
#         self.insert_table_entry(
#             target,
#             'SwitchIngress.IngressHdrStackCounters.cntrs_inner_tbl',
#             [self.KeyField('hdr.inner_ethernet.$valid$', self.to_bytes(int(addr[0]), 1)),
#              self.KeyField('hdr.inner_vlan_tag.$valid$', self.to_bytes(int(addr[1]), 1)),
#              self.KeyField('cntrs_inner_addr_l3', self.to_bytes(int(addr[2:4],2), 1)),
#              self.KeyField('cntrs_inner_addr_l4', self.to_bytes(int(addr[4:7],2), 1))],
#             'SwitchIngress.IngressHdrStackCounters.hit_inner',
#             [self.DataField('$COUNTER_SPEC_PKTS', self.to_bytes(data, 8))])
#
#
#     # Helper function for deleting counter entries
#     # --------------------------------------------------------------------------
#     # todo: Pull all this info in from bfrt.json?
#     def _delete_counter(self, target, addr):
#         addr = addr.replace('_','') # prep
#
#         """ Delete a table entry
#             @param target : target device
#             @param table : Table name.
#             @param key_fields: List of (name, value, [mask]) tuples.
#         """
#
#         self.delete_table_entry(
#             target,
#             'SwitchIngress.IngressHdrStackCounters.cntrs_inner_tbl',
#             [self.KeyField('hdr.inner_ethernet.$valid$', self.to_bytes(int(addr[0]), 1)),
#              self.KeyField('hdr.inner_vlan_tag.$valid$', self.to_bytes(int(addr[1]), 1)),
#              self.KeyField('cntrs_inner_addr_l3', self.to_bytes(int(addr[2:4],2), 1)),
#              self.KeyField('cntrs_inner_addr_l4', self.to_bytes(int(addr[4:7],2), 1))])
#
#
#     # Helper function for getting counter entries
#     # --------------------------------------------------------------------------
#     # todo: Pull all this info in from bfrt.json?
#     def _get_counter(self, target, addr):
#         addr = addr.replace('_','') # prep
#
#         table_name = 'SwitchIngress.IngressHdrStackCounters.cntrs_inner_tbl'
#         action_name = 'SwitchIngress.IngressHdrStackCounters.hit_inner'
#         data_field_name = '$COUNTER_SPEC_PKTS'
#
#         """ Get a table entry
#             @param target : target device
#             @param table_name : Table name.
#             @param key_fields : List of (name, value, [mask]) tuples.
#             @param flag : dict of flags
#             @param action_name : Action name.
#             @param data_field_ids : List of field_names
#         """
#
#         resp = self.get_table_entry(
#             target,
#             table_name,
#             [self.KeyField('hdr.inner_ethernet.$valid$', self.to_bytes(int(addr[0]), 1)),
#              self.KeyField('hdr.inner_vlan_tag.$valid$', self.to_bytes(int(addr[1]), 1)),
#              self.KeyField('cntrs_inner_addr_l3', self.to_bytes(int(addr[2:4],2), 1)),
#              self.KeyField('cntrs_inner_addr_l4', self.to_bytes(int(addr[4:7], 2), 1))],
#             {"from_hw":True},
#             action_name,
#             [data_field_name])
#
#         # parse resp to get the counter
#         pkts_field_id = self.get_data_field(table_name, action_name, data_field_name)
#         data_dict = next(self.parseEntryGetResponse(resp))
#         recv_pkts = ''.join(x.encode('hex') for x in str(data_dict[pkts_field_id]))
#         recv_pkts = int(recv_pkts, 16)
#
#         return recv_pkts
#
#
#     # Helper function for determining L2 counter addresses
#     # --------------------------------------------------------------------------
#     def _get_cntrs_addr_L2(self, stack):
#
#         stack = stack.replace(" ","")
#         stack = self._wack_overrides(stack)
#
#         # why do we need this mapping table - why doesn't this match bf-rt.json?
#         # could it be an endianess thing?
#         mt = { 'Ether' : 64,  # bit[6]
#                'Dot1Q' : 32 } # bit[5]
#
#         hdrs = stack.split("/")
#         addr = 0
#
#         if 'Ether()' in hdrs:
#             addr = addr + mt['Ether']
#         if 'Dot1Q()' in hdrs:
#             addr = addr + mt['Dot1Q']
#
#         #if addr == 0:
#         #    addr = -1
#
#         #print("L2 Address Check: %d" %(addr))
#         return addr
#
#     # Helper function for determining L3 counter addresses
#     # --------------------------------------------------------------------------
#     def _get_cntrs_addr_L3(self, stack):
#
#         stack = stack.replace(" ","")
#         stack = self._wack_overrides(stack)
#
#         mt = { 'IP'   : 8,   # bit[4:3] == 1
#                'IPv6' : 16 } # bit[4:3] == 2
#
#         hdrs = stack.split("/")
#         addr = 0
#
#         if 'IP()' in hdrs:
#             addr = addr + mt['IP']
#         elif 'IPv6()' in hdrs:
#             addr = addr + mt['IPv6']
#
#         #print("L3 Address Check: %d" %(addr))
#         return addr
#
#
#     # Helper function for determining L4 counter addresses
#     # --------------------------------------------------------------------------
#     def _get_cntrs_addr_L4(self, stack):
#
#         stack = stack.replace(" ","")
#         stack = self._wack_overrides(stack)
#
#         mt = { 'ICMP' : 1,   # bit[2:0] == 1
#                'IGMP' : 2,   # bit[2:0] == 2
#                'UDP'  : 3,   # bit[2:0] == 3
#                'TCP'  : 4,   # bit[2:0] == 4
#                'SCTP' : 5 }  # bit[2:0] == 5
#
#         hdrs = stack.split("/")
#         addr = 0
#
#         if 'ICMP()' in hdrs:
#             addr = addr + mt['ICMP']
#         elif 'IGMP()' in hdrs:
#             addr = addr + mt['IGMP']
#         elif 'UDP()' in hdrs:
#             addr = addr + mt['UDP']
#         elif 'TCP()' in hdrs:
#             addr = addr + mt['TCP']
#         elif 'SCTP()' in hdrs:
#             addr = addr + mt['SCTP']
#         #elif 'ICMPv6()' in hdrs:
#         elif 'ICMPv6EchoRequest()' in hdrs:
#             addr = addr + mt['ICMP']
#
#         #print("L4 Address Check: %d" %(addr))
#         return addr
#
#
#     # Helper function for determining counter addresses
#     # --------------------------------------------------------------------------
#     def _get_cntrs_addr(self, soi, stacks):
#
#         addr = 0
#
#         # determine L2 portion of address
#         try:
#             stacks[soi + '_L2']
#             addr = self._get_cntrs_addr_L2(stacks[soi + '_L2'])
#         except:
#             pass
#
#         # determine L3 portion of address
#         try:
#             stacks[soi + '_L3']
#             addr = (addr
#                     + self._get_cntrs_addr_L3(stacks[soi + '_L3']))
#         except:
#             pass
#
#         # determine L4 portion of address
#         try:
#             stacks[soi + '_L4']
#             addr = (addr
#                     + self._get_cntrs_addr_L4(stacks[soi + '_L4']))
#         except:
#             pass
#
#         #print("(Combined) Address Check: %d" %(addr))
#         return addr
#
#
#
#     # Helper function for determining hdr stack from a counter addr (for debug)
#     # --------------------------------------------------------------------------
#     def _addr_2_stack(self, addr):
#
#         # important to note here that the order of L2 headers within a stack
#         # might not match the actual order in the pkt that was sent (npf yaml).
#         # again, all this bit-position stuff should be coming from bfrt!
#
#         stack = ""
#
#         # L2 portion (bits[6:5])
#         if addr>>6 & 1:
#             stack = stack + "Ether()"
#         if addr>>5 & 1:
#             stack = stack + "Dot1Q()"
#
#         # L3 portion (bits[4:3])
#         if addr>>3 & 3 == 1:
#             stack = stack + "IP()"
#         elif addr>>3 & 3 == 2:
#             stack = stack + "IPv6()"
#
#         # L4 portion (bits[2:0])
#         if addr & 7 == 1:
#             stack = stack + "ICMP()"
#         elif addr & 7 == 2:
#             stack = stack + "IGMP()"
#         elif addr & 7 == 3:
#             stack = stack + "UDP()"
#         elif addr & 7 == 4:
#             stack = stack + "TCP()"
#         elif addr & 7 == 5:
#             stack = stack + "SCTP()"
#
#         # cleanup
#         if len(stack) > 0:
#             stack = stack.replace(" ","")
#             stack = stack.replace("()","() / ")
#             stack = stack[:-3]
#
#         return stack
#
#
#     # --------------------------------------------------------------------------
#     def runTest(self):
#
#         ig_port = 1
#         target = self.Target(device_id=0, pipe_id=0xffff)
#
#         testdir = '/vagrant/pkgsrc/p4-examples/p4_16_programs/npb/'
#         npf_cfg_yaml = testdir + 'npb_ing_parser_npf.yaml'
#
#         # ----------------------------------------------------------------------
#         pkt_template_categories = ['inner']
#
#         pkt_template_names = [#'L2_nsh',
#                               'L2_erspan_1',
#                               'L2_erspan_2',
#                               'L2_vxlan',
#                               'L2_mpls_pw_l2vpn',
#                               'L2_gre_mpls_pw_l2vpn',
#                               'L2_nvgre',
#
#                               #'L3_nsh',
#                               'L3_erspan_1',
#                               'L3_erspan_2',
#                               'L3_vxlan',
#                               'L3_mpls_l3vpn',
#                               'L3_mpls_pw_l2vpn',
#                               'L3_gre',
#                               'L3_gre_mpls_l3vpn',
#                               'L3_gre_mpls_pw_l2vpn',
#                               'L3_nvgre',
#                               'L3_gtp_u',
#                               'L3_ip',
#
#                               #'L4_nsh',
#                               'L4_erspan_1',
#                               'L4_erspan_2',
#                               'L4_vxlan',
#                               'L4_mpls_l3vpn',
#                               'L4_mpls_pw_l2vpn',
#                               'L4_gre',
#                               'L4_gre_mpls_l3vpn',
#                               'L4_gre_mpls_pw_l2vpn',
#                               'L4_nvgre',
#                               'L4_gtp_u',
#                               'L4_ip'] # determines order of tests
#
#
#         # ----------------------------------------------------------------------
#
#         Stacks = HdrStacks() # instantiate NPF HdrStacks class
#
#         # Get bfrt_info and set it as part of the test
#         self.set_bfrt_info(self.parse_bfrt_info(self.get_bfrt_info("npb")))
#
#         # Load NPF Config (into dict)
#         assert os.path.isfile(npf_cfg_yaml), \
#             "ERROR: NPF Config file (%s) not found." %(npf_cfg_yaml)
#
#         logger.info("\nLoad NPF Config: %s" %(npf_cfg_yaml))
#         npf_cfg_raw = open(npf_cfg_yaml, 'r')
#         npf_cfg = yaml.load(npf_cfg_raw)
#
#         # Create Header Stacks (from config)
#         stacks_df = Stacks.build(npf_cfg['pkt_templates'])
#         assert(len(stacks_df) > 0), "ERROR: No pkt templates present in %s" \
#             %(npf_cfg_yaml)
#
#         # Create pcaps folder if it doesn't already exist
#         # if(not os.path.exists(testdir + 'pcaps')):
#         os.system('mkdir -p %s' %(testdir + 'pcaps'))
#
#
#         # Loop through each packet template category
#         for category in pkt_template_categories:
#
#             # Filter pkt templates (for this category)
#             stacks_df_filtered_cat = Stacks.filter(stacks_df,
#                                                    'category',
#                                                    [category])
#
#             templates = set(stacks_df_filtered_cat['name'].tolist())
#             logger.info("The following (%d) packet templates were found for"
#                         " category \"%s\":", len(templates), category)
#             logger.info("  %s", templates)
#             #Stacks.show(stacks_df_filtered_cat)
#
#             logger.info("The following (%d) packet templates were requested"
#                         " for testing:", len(pkt_template_names))
#             logger.info("  %s", pkt_template_names)
#
#
#             # Loop through all the requested packet templates (names)
#             for template in pkt_template_names:
#
#                 testname = "_".join([category, template])
#
#                 logger.info("")
#                 logger.info("-----------------------------------------")
#                 logger.info("Begin parser test: %s\n", testname)
#
#                 # Filter pkt templates (for this name)
#                 stacks_df_filtered_name = (
#                     Stacks.filter(stacks_df_filtered_cat,
#                                   'name',
#                                   [template]))
#
#                 ################################################################
#                 logger.info("Prepare Stimulus:")
#                 ################################################################
#
#                 pcap = "".join([testdir,
#                                 'pcaps/pkts_',
#                                 testname,
#                                 '.pcap'])
#
#                 # Wack old pcap
#                 if os.path.isfile("%s" %(pcap)):
#                     os.system("rm %s" %(pcap))
#
#                 # Determine number of pkts to be sent (per hdr stack)
#                 pkts_per_stack = random.randrange(self.MIN_NUM_PKTS,
#                                                   self.MAX_NUM_PKTS)
#                 logger.info("  Number of packets per header stack: %d",
#                             pkts_per_stack)
#
#                 # Generate stimulus pcap (via network packet factory)
#                 logger.info("  Create stimulus pcap file (via npf): %s",
#                             pcap)
#
#                 npf.main(['-i',        npf_cfg_yaml,
#                           '-category', category,
#                           '-name',     template,
#                           '-write',    pcap,
#                           '-num_pkts', str(pkts_per_stack)])
#
#
#                 ################################################################
#                 logger.info("Determine Expected Results")
#                 ################################################################
#
#                 # Determine stack of interest (inner header stack)
#                 # (this can vary depending on template structure)
#                 soi = Stacks.outermost_stack(stacks_df_filtered_name)
#                 if soi == 'outer1':
#                     soi = 'inner'
#                 elif soi == 'outer2':
#                     soi = 'outer1'
#
#                 # Determine list of cntr addresses that should see hits
#                 exp_cntr_addrs = []
#
#                 for (index, row) in stacks_df_filtered_name.iterrows():
#
#                     addr = self._get_cntrs_addr(soi, row)
#
#                     exp_cntr_addrs.append(addr)
#                     # print("Expected counter addresses: %s" %(addr))
#                     # todo: assert len(list) == len(stacks_df_filtered_name)
#                     # todo: assert no '11_1111_1111_1111' addresses in list
#
#                 # Determine the expected counter values
#                 exp_cntr_data = (
#                     [(exp_cntr_addrs.count(exp_cntr_addr) * pkts_per_stack)
#                       for exp_cntr_addr in exp_cntr_addrs ])
#
#                 # create addr/value pairs
#                 exp_results = [av for av in zip(exp_cntr_addrs, exp_cntr_data)]
#                 exp_results = set(exp_results) # remove duplicates
#
#                 ################################################################
#                 logger.info("Prepare DUT:")
#                 ################################################################
#                 # this is not perfect - we kick out after the first delete error
#                 # which prevents error msgs from scrolling up the screen for all
#                 # counters. A safer solution might be to include both the delete
#                 # and insert calls within the same for loop (tradeoff being that
#                 # error msgs can scroll).
#
#                 # Clear all DUT counters
#                 logger.info("  Clear all DUT header stack counters")
#
#                 for addr in range(self.CNTR_PROPS['num_cntrs']):
#
#                     # this will produce errors the first time through
#                     try:
#                         self._delete_counter(
#                             target,
#                             str(format(addr, self.CNTR_PROPS['addr_fmt']))) #asdf
#                     except:
#                         print("The above errors are a result of the attempted"
#                               " cleanup effort - Please disregard")
#                         break
#
#                 for addr in range(self.CNTR_PROPS['num_cntrs']):
#                     self._insert_counter(
#                         target,
#                         str(format(addr, self.CNTR_PROPS['addr_fmt'])),
#                         0)
#
#                 ################################################################
#                 logger.info("Stimulate DUT:")
#                 ################################################################
#
#                 # Read stimulus pcap
#                 logger.info("  Read Stimulus PCAP (%s)", pcap)
#                 pkts = rdpcap("%s" %(pcap))
#
#                 logger.info("  Send %d packet(s) on tofino port %d",
#                             len(pkts), ig_port)
#
#                 for pkt in pkts:
#
#                     # Send packet(s)
#                     testutils.send_packet(self, ig_port, pkt)
#
#                 time.sleep(len(pkts)*0.2) # allow packets to move
#
#                 # debug - see what cntrs were acutally bumped
#                 idx = 0
#                 for addr in range(self.CNTR_PROPS['num_cntrs']):
#
#                     act_cnt = self._get_counter(
#                         target,
#                         str(format(addr,self.CNTR_PROPS['addr_fmt'])))
#
#                     if act_cnt > 0:
#                         print(idx,
#                               addr,
#                               str(format(addr,self.CNTR_PROPS['addr_fmt'])),
#                               act_cnt)
#                         idx = idx + 1
#
#
#                 ################################################################
#                 logger.info("Check Results:")
#                 ################################################################
#
#                 for idx, (exp_cntr_addr, exp_cntr_data) in enumerate(exp_results):
#
#                     # attempt to recreate the header stack here from expected
#                     # address to aid in debug if something goes wrong.
#                     # (as opposed to simply showing the stack from the df)
#                     # important - recreated stack might not show the headers
#                     # in the same order that the actual packet had them.
#                     stack = self._addr_2_stack(exp_cntr_addr)
#                     logger.info("  %d Reading counter: addr = %d (0x%x) (%s),"
#                                 " expected data = %d, predicted stack = %s",
#                                 idx, exp_cntr_addr, exp_cntr_addr,
#                                 bin(exp_cntr_addr), exp_cntr_data, stack)
#
#                     act_cnt = self._get_counter(
#                         target,
#                         #str(format(exp_cntr_addr,'006b')))
#                         str(format(exp_cntr_addr,self.CNTR_PROPS['addr_fmt'])))
#
#                     assert act_cnt == exp_cntr_data, "  ERROR (addr%d):" \
#                         " Actual counter (%d) doesn't match expected (%d)" \
#                         %(exp_cntr_addr, act_cnt, exp_cntr_data)
#
#                 logger.info("  PASS")
#
#                     # todo: if counters don't match, should we dump all cntrs
#                     # to aid in debug? Or show all non-zero counters?
#                     # there's a debug routine above in the code that does this.
#                     # it's commented out by default.




################################################################################
################################################################################
class IngressParserTestInnerTunnel(BfRuntimeTest):

    '''A test for veryfing the functionality of the NPB ingress parser's
       inner tunnel headers. Pass/Fail is determined by monitoring a set
       of per header stack counters within the Tofino that increment
       based on header isValid() conditions.

       This test focuses only on the inner tunnel header stack counters
       within the Tofino. It does not check any outer (underlay), or inner
       L2/3/4 counters for correctness. The assumption is these counters
       will be verified via their own, directed tests. That being said,
       all upper layers paths through the parser are exercised during
       this test, and counter checks should ensure all packets made it
       to their final expected (inner tunnel) parser state.
    '''

    MIN_NUM_PKTS = 1  # min number of packets per stack
    MAX_NUM_PKTS = 2  # max number of packets per stack

    # todo: Pull this info in from bfrt.json?
    # or use this function (def get_bfrt_info()) in bfruntime_base_tests.py

    CNTR_PROPS = { 'num_cntrs' : 256,
                   'addr_fmt' : '008b' }

    # --------------------------------------------------------------------------
    def setUp(self):
        client_id = 0
        p4_name = "npb"
        BfRuntimeTest.setUp(self, client_id, p4_name)


    # Helper function for stripping out header field overrides
    # --------------------------------------------------------------------------
    def _wack_overrides(self, stack):
        # single repetitive regex substitute would be cleaner here.
        # (had trouble getting that working right)

        hdrs = stack.split("/")
        return "/".join([re.sub(r'\(.*\)', '()', hdr) for hdr in hdrs ])


    # Helper function for inserting counter entries
    # --------------------------------------------------------------------------
    # todo: Pull all this info in from bfrt.json?
    def _insert_counter(self, target, addr, data):
        addr = addr.replace('_','') # prep

        """ Insert a new table entry
            @param target : target device
            @param table_name : Table name.
            @param key_fields : List of (name, value, [mask]) tuples.
            @param action_name : Action name.
            @param data_fields : List of (name, value) tuples.
        """

        self.insert_table_entry(
            target,
            'SwitchIngress.IngressHdrStackCounters.cntrs_inner_tunnel_tbl',

            [self.KeyField('hdr.inner_mpls[0].$valid$', self.to_bytes(int(addr[0]), 1)),
             self.KeyField('hdr.inner_mpls[1].$valid$', self.to_bytes(int(addr[1]), 1)),
             self.KeyField('hdr.inner_mpls[2].$valid$', self.to_bytes(int(addr[2]), 1)),
             self.KeyField('hdr.inner_mpls[3].$valid$', self.to_bytes(int(addr[3]), 1)),
             self.KeyField('hdr.inner_mpls_pw_cw.$valid$', self.to_bytes(int(addr[4]), 1)),
             self.KeyField('cntrs_inner_tnl_addr', self.to_bytes(int(addr[5:8],2), 1))],
            'SwitchIngress.IngressHdrStackCounters.hit_inner_tunnel',
            [self.DataField('$COUNTER_SPEC_PKTS', self.to_bytes(data, 8))])


    # Helper function for deleting counter entries
    # --------------------------------------------------------------------------
    # todo: Pull all this info in from bfrt.json?
    def _delete_counter(self, target, addr):
        addr = addr.replace('_','') # prep

        """ Delete a table entry
            @param target : target device
            @param table : Table name.
            @param key_fields: List of (name, value, [mask]) tuples.
        """

        self.delete_table_entry(
            target,
            'SwitchIngress.IngressHdrStackCounters.cntrs_inner_tunnel_tbl',

            [self.KeyField('hdr.inner_mpls[0].$valid$', self.to_bytes(int(addr[0]), 1)),
             self.KeyField('hdr.inner_mpls[1].$valid$', self.to_bytes(int(addr[1]), 1)),
             self.KeyField('hdr.inner_mpls[2].$valid$', self.to_bytes(int(addr[2]), 1)),
             self.KeyField('hdr.inner_mpls[3].$valid$', self.to_bytes(int(addr[3]), 1)),
             self.KeyField('hdr.inner_mpls_pw_cw.$valid$', self.to_bytes(int(addr[4]), 1)),
             self.KeyField('cntrs_inner_tnl_addr', self.to_bytes(int(addr[5:8],2), 1))])


    # Helper function for getting counter entries
    # --------------------------------------------------------------------------
    # todo: Pull all this info in from bfrt.json?
    def _get_counter(self, target, addr):
        addr = addr.replace('_','') # prep

        table_name = 'SwitchIngress.IngressHdrStackCounters.cntrs_inner_tunnel_tbl'
        action_name = 'SwitchIngress.IngressHdrStackCounters.hit_inner_tunnel'
        data_field_name = '$COUNTER_SPEC_PKTS'

        """ Get a table entry
            @param target : target device
            @param table_name : Table name.
            @param key_fields : List of (name, value, [mask]) tuples.
            @param flag : dict of flags
            @param action_name : Action name.
            @param data_field_ids : List of field_names
        """

        resp = self.get_table_entry(
            target,
            table_name,
            [self.KeyField('hdr.inner_mpls[0].$valid$', self.to_bytes(int(addr[0]), 1)),
             self.KeyField('hdr.inner_mpls[1].$valid$', self.to_bytes(int(addr[1]), 1)),
             self.KeyField('hdr.inner_mpls[2].$valid$', self.to_bytes(int(addr[2]), 1)),
             self.KeyField('hdr.inner_mpls[3].$valid$', self.to_bytes(int(addr[3]), 1)),
             self.KeyField('hdr.inner_mpls_pw_cw.$valid$', self.to_bytes(int(addr[4]), 1)),
             self.KeyField('cntrs_inner_tnl_addr', self.to_bytes(int(addr[5:8],2), 1))],
            {"from_hw":True},
            action_name,
            [data_field_name])

        # parse resp to get the counter
        pkts_field_id = self.get_data_field(table_name, action_name, data_field_name)
        data_dict = next(self.parseEntryGetResponse(resp))
        recv_pkts = ''.join(x.encode('hex') for x in str(data_dict[pkts_field_id]))
        recv_pkts = int(recv_pkts, 16)

        return recv_pkts


    # Helper function for determining counter addresses
    # --------------------------------------------------------------------------
    def _get_cntrs_addr(self, soi, stacks):

        stack = stacks[soi + '_tunnel']

        # prep stack for address decode
        stack = stack.replace(" ","")
        stack = stack.replace("GRE(key_present=1)","NVGRE()")

        # todo: this really should catch all combos of E/S/PN
        # BE SURE TO REMOVE SPACES IN BELOW OVER-RIDES
        stack = stack.replace("GTPHeader(E=1)","GTP_OPT()")
        stack = stack.replace("GTPHeader(S=1)","GTP_OPT()")
        stack = stack.replace("GTPHeader(PN=1)","GTP_OPT()")
        stack = stack.replace("GTPEchoRequest()","GTP_OPT()")

        stack = stack.replace("GTP_U_Header(E=1)","GTP_OPT()")
        stack = stack.replace("GTP_U_Header(S=1)","GTP_OPT()")
        stack = stack.replace("GTP_U_Header(PN=1)","GTP_OPT()")
        stack = stack.replace("GTP_U_Header(S=1,length=4)","GTP_OPT()")
        stack = stack.replace("GTP_U_Header(length=0)","GTP_U_Header()")

        stack = self._wack_overrides(stack)

        # why do we need this mapping table - why doesn't this match bf-rt.json?
        # could it be an endianess thing?
        mt = { 'VXLAN'      : 1,    # bit[2:0] == 1
               'NVGRE'      : 2,    # bit[2:0] == 2
               'GRE'        : 3,    # bit[2:0] == 3
               'ESP'        : 4,    # bit[2:0] == 4
               'GTP_OPT'    : 5,    # bit[2:0] == 5
               'GTP'        : 6,    # bit[2:0] == 6

               'MPLS_PW_CW' : 8,    # bit[3]
               'MPLS_3'     : 16,   # bit[4]
               'MPLS_2'     : 32,   # bit[5]
               'MPLS_1'     : 64,   # bit[6]
               'MPLS_0'     : 128 } # bit[7]

        hdrs = stack.split("/")
        addr = 0

        if 'VXLAN()' in hdrs:
            addr = addr + mt['VXLAN']
        elif 'GRE()' in hdrs:
            addr = addr + mt['GRE']
        elif 'NVGRE()' in hdrs:
            addr = addr + mt['NVGRE']
        elif 'ESP()' in hdrs:
            addr = addr + mt['ESP']
        elif 'GTP_OPT()' in hdrs:
            addr = addr + mt['GTP_OPT']
        elif ('GTPHeader()' in hdrs) or ('GTP_U_Header()' in hdrs):
            addr = addr + mt['GTP']

        if hdrs.count('MPLS()') == 1:
            addr = addr + mt['MPLS_0']
        elif hdrs.count('MPLS()') == 2:
            addr = addr + mt['MPLS_0'] + mt['MPLS_1']
        elif hdrs.count('MPLS()') == 3:
            addr = addr + mt['MPLS_0'] + mt['MPLS_1'] + mt['MPLS_2']
        elif hdrs.count('MPLS()') == 4:
            addr = addr + mt['MPLS_0'] + mt['MPLS_1'] + mt['MPLS_2'] + mt['MPLS_3']

        if 'EoMCW()' in hdrs:
            addr = addr + mt['MPLS_PW_CW']

        #print("Tunnel Address Check: %d" %(addr))
        return addr


    # Helper function for determining hdr stack from a counter addr (for debug)
    # --------------------------------------------------------------------------
    def _addr_2_stack(self, addr):

        # important to note here that the order of L2 headers within a stack
        # might not match the actual order in the pkt that was sent (npf yaml).
        # again, all this bit-position stuff should be coming from bfrt!

        stack = ""

        # The rest (bits[2:0])
        if addr & 7 == 1:
            stack = stack + "VXLAN()"
        elif addr & 7 == 2:
            stack = stack + "NVGRE()"
        elif addr & 7 == 3:
            stack = stack + "GRE()"
        elif addr & 7 == 4:
            stack = stack + "ESP()"
        elif addr & 7 == 5:
            stack = stack + "GTP_OPT()"
        elif addr & 7 == 6:
            stack = stack + "GTP()"

        # MPLS portion (bits[7:4])
        if addr>>7 & 1:
            stack = stack + "MPLS()"
        if addr>>6 & 1:
            stack = stack + "MPLS()"
        if addr>>5 & 1:
            stack = stack + "MPLS()"
        if addr>>4 & 1:
            stack = stack + "MPLS()"
        if addr>>3 & 1:
            stack = stack + "EoMCW()"

        # cleanup
        if len(stack) > 0:
            stack = stack.replace(" ","")
            stack = stack.replace("()","() / ")
            stack = stack[:-3]

        return stack



    # --------------------------------------------------------------------------
    def runTest(self):

        ig_port = 1
        target = self.Target(device_id=0, pipe_id=0xffff)

        testdir = '/vagrant/pkgsrc/p4-examples/p4_16_programs/npb/'
        npf_cfg_yaml = testdir + 'npb_ing_parser_npf.yaml'

        # ----------------------------------------------------------------------
        pkt_template_categories = ['inner_tunnel']

        pkt_template_names = [#'vxlan_nsh_outer',
                              'vxlan_erspan_outer',
                              'mpls_l3vpn_erspan_outer',
                              'mpls_pw_l2vpn_erspan_outer',
                              'gre_erspan_outer',
                              'gre_mpls_l3vpn_erspan_outer',
                              'gre_mpls_pw_l2vpn_erspan_outer',
                              'nvgre_erspan_outer',
                              'gtp_u_erspan_outer',
                              'esp_erspan_outer']

        #pkt_template_names = ['esp_erspan_outer'] # override
        # ----------------------------------------------------------------------

        Stacks = HdrStacks() # instantiate NPF HdrStacks class

        # Get bfrt_info and set it as part of the test
        self.set_bfrt_info(self.parse_bfrt_info(self.get_bfrt_info("npb")))

        # Load NPF Config (into dict)
        assert os.path.isfile(npf_cfg_yaml), \
            "ERROR: NPF Config file (%s) not found." %(npf_cfg_yaml)

        logger.info("\nLoad NPF Config: %s" %(npf_cfg_yaml))
        npf_cfg_raw = open(npf_cfg_yaml, 'r')
        npf_cfg = yaml.load(npf_cfg_raw)

        # Create Header Stacks (from config)
        stacks_df = Stacks.build(npf_cfg['pkt_templates'])
        assert(len(stacks_df) > 0), "ERROR: No pkt templates present in %s" \
            %(npf_cfg_yaml)

        # Create pcaps folder if it doesn't already exist
        # if(not os.path.exists(testdir + 'pcaps')):
        os.system('mkdir -p %s' %(testdir + 'pcaps'))

        # Loop through each packet template category
        for category in pkt_template_categories:

            # Filter pkt templates (for this category)
            stacks_df_filtered_cat = Stacks.filter(stacks_df,
                                                   'category',
                                                   [category])

            templates = set(stacks_df_filtered_cat['name'].tolist())

            logger.info("The following (%d) packet templates were found for"
                        " category \"%s\":", len(templates), category)
            logger.info("  %s", templates)
            #Stacks.show(stacks_df_filtered_cat)

            logger.info("The following (%d) packet templates were requested"
                        " for testing:", len(pkt_template_names))
            logger.info("  %s", pkt_template_names)


            # Loop through all the requested packet templates (names)
            for template in pkt_template_names:

                testname = "_".join([category, template])

                logger.info("")
                logger.info("-----------------------------------------")
                logger.info("Begin parser test: %s\n", testname)

                # Filter pkt templates (for this name)
                stacks_df_filtered_name = (
                    Stacks.filter(stacks_df_filtered_cat,
                                  'name',
                                  [template]))

                ################################################################
                logger.info("Prepare Stimulus:")
                ################################################################

                pcap = "".join([testdir,
                                'pcaps/pkts_',
                                testname,
                                '.pcap'])

                # Wack old pcap
                if os.path.isfile("%s" %(pcap)):
                    os.system("rm %s" %(pcap))

                # Determine number of pkts to be sent (per hdr stack)
                pkts_per_stack = random.randrange(self.MIN_NUM_PKTS,
                                                  self.MAX_NUM_PKTS)
                logger.info("  Number of packets per header stack: %d",
                            pkts_per_stack)

                # Generate stimulus pcap (via network packet factory)
                logger.info("  Create stimulus pcap file (via npf): %s",
                            pcap)

                npf.main(['-i',        npf_cfg_yaml,
                          '-category', category,
                          '-name',     template,
                          '-write',    pcap,
                          '-num_pkts', str(pkts_per_stack)])


                ################################################################
                logger.info("Determine Expected Results")
                ################################################################

                # Determine stack of interest (inner header stack)
                # (this can vary depending on template structure)
                soi = Stacks.outermost_stack(stacks_df_filtered_name)
                if soi == 'outer1':
                    soi = 'inner'
                elif soi == 'outer2':
                    soi = 'outer1'

                # Determine list of cntr addresses that should see hits
                exp_cntr_addrs = []

                for (index, row) in stacks_df_filtered_name.iterrows():

                    addr = self._get_cntrs_addr(soi, row)

                    exp_cntr_addrs.append(addr)
                    # print("Expected counter addresses: %s" %(addr))
                    # todo: assert len(list) == len(stacks_df_filtered_name)
                    # todo: assert no '11_1111_1111_1111' addresses in list

                # Determine the expected counter values
                exp_cntr_data = (
                    [(exp_cntr_addrs.count(exp_cntr_addr) * pkts_per_stack)
                      for exp_cntr_addr in exp_cntr_addrs ])

                # create addr/value pairs
                exp_results = [av for av in zip(exp_cntr_addrs, exp_cntr_data)]
                exp_results = set(exp_results) # remove duplicates


                ################################################################
                logger.info("Prepare DUT:")
                ################################################################
                # this is not perfect - we kick out after the first delete error
                # which prevents error msgs from scrolling up the screen for all
                # counters. A safer solution might be to include both the delete
                # and insert calls within the same for loop (tradeoff being that
                # error msgs can scroll).

                # Clear all DUT counters
                logger.info("  Clear all DUT header stack counters")

                for addr in range(self.CNTR_PROPS['num_cntrs']):

                    # this will produce errors the first time through
                    try:
                        self._delete_counter(
                            target,
                            str(format(addr, self.CNTR_PROPS['addr_fmt']))) #asdf
                    except:
                        print("The above errors are a result of the attempted"
                              " cleanup effort - Please disregard")
                        break

                for addr in range(self.CNTR_PROPS['num_cntrs']):
                    self._insert_counter(
                        target,
                        str(format(addr, self.CNTR_PROPS['addr_fmt'])),
                        0)


                ################################################################
                logger.info("Stimulate DUT:")
                ################################################################

                # Read stimulus pcap
                logger.info("  Read Stimulus PCAP (%s)", pcap)
                pkts = rdpcap("%s" %(pcap))

                logger.info("  Send %d packet(s) on tofino port %d",
                            len(pkts), ig_port)

                for pkt in pkts:

                    # Send packet(s)
                    testutils.send_packet(self, ig_port, pkt)

                time.sleep(len(pkts)*0.2) # allow packets to move

                # debug - see what cntrs were acutally bumped
                idx = 0
                for addr in range(self.CNTR_PROPS['num_cntrs']):

                    act_cnt = self._get_counter(
                        target,
                        str(format(addr,self.CNTR_PROPS['addr_fmt'])))

                    if act_cnt > 0:
                        print(idx,
                              addr,
                              str(format(addr,self.CNTR_PROPS['addr_fmt'])),
                              act_cnt)
                        idx = idx + 1


                ################################################################
                logger.info("Check Results:")
                ################################################################

                for idx, (exp_cntr_addr, exp_cntr_data) in enumerate(exp_results):

                    # attempt to recreate the header stack here from expected
                    # address to aid in debug if something goes wrong.
                    # (as opposed to simply showing the stack from the df)
                    # important - recreated stack might not show the headers
                    # in the same order that the actual packet had them.
                    stack = self._addr_2_stack(exp_cntr_addr)
                    logger.info("  %d Reading counter: addr = %d (0x%x) (%s),"
                                " expected data = %d, predicted stack = %s",
                                idx, exp_cntr_addr, exp_cntr_addr,
                                bin(exp_cntr_addr), exp_cntr_data, stack)

                    act_cnt = self._get_counter(
                        target,
                        #str(format(exp_cntr_addr,'006b')))
                        str(format(exp_cntr_addr,self.CNTR_PROPS['addr_fmt'])))

                    assert act_cnt == exp_cntr_data, "  ERROR (addr%d):" \
                        " Actual counter (%d) doesn't match expected (%d)" \
                        %(exp_cntr_addr, act_cnt, exp_cntr_data)

                logger.info("  PASS")

                    # todo: if counters don't match, should we dump all cntrs
                    # to aid in debug? Or show all non-zero counters?
                    # there's a debug routine above in the code that does this.
                    # it's commented out by default.
