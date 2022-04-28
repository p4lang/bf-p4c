#################################################################################
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

import sys
#sys.path.append("/npb-dp/tst/basic/mau")
from test_mau_tb_top import *
from test_mau_tb_tbl_wrap import *
from test_mau_tb_pkt_gen import *
from test_mau_tb_models import *

################################################################################

class test(BfRuntimeTest):

	def setUp(self):
		self.dev = 0
		self.client_id = 0
		self.p4_name = p4_name
#		self.target = gc.Target(self.dev, pipe_id=0xffff)
		self.target = gc.Target(self.dev, pipe_id=0xffff, direction=0xff, prsr_id=0xff)
		BfRuntimeTest.setUp(self, self.client_id, self.p4_name)
		self.bfrt_info = self.interface.bfrt_info_get(self.p4_name)
		cleanUpGlobal(self)
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

		for ig_pipe in ig_pipes:

			# -------------------------------------------------------------

			ig_port_0 = ig_swports[ig_pipe][1]
			eg_port_0 = eg_swports[1]
			ig_port_1 = ig_swports[ig_pipe][2]
			eg_port_1 = eg_swports[2]



			# -----------------------
			# Packet values to use
			# -----------------------

			smac   = '11:11:11:11:11:11'
			dmac   = '22:22:22:22:22:22'
			dmac_0 = '33:33:33:33:33:33'
			sip = "0.0.0.3"
			dip = "0.0.0.4"

			rmac   = dmac_0

			# -----------------------
			# NSH values to use
			# -----------------------

			sap                     = 0 # Arbitrary value
			vpn                     = 1 # Arbitrary value
			flow_class_acl          = 2 # Arbitrary value
			flow_class_sfp          = 3 # Arbitrary value
			spi                     = 4 # Arbitrary value
			si                      = 5 # Arbitrary value (ttl)
			sfc                     = 6 # Arbitrary value
			dsap                    = 7 # Arbitrary value
			ta                      = 8 # Arbitrary value

			sf_bitmask_0            = 5 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress
			sf_bitmask_1            = 4 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

			nexthop_ptr             = 1 # Arbitrary value
			bd                      = 2 # Arbitrary value
			ig_lag_ptr              = 3 # Arbitrary value
			eg_lag_ptr              = 4 # Arbitrary value
			tunnel_encap_ptr        = 5 # Arbitrary value
			tunnel_encap_nexthop_ptr= 6 # Arbitrary value
			tunnel_encap_bd         = 7 # Arbitrary value
			tunnel_encap_smac_ptr   = 8 # Arbitrary value

			# -----------------------------------------------------------
			# Insert Table Entries
			# -----------------------------------------------------------

			npb_nsh_chain_start_add(self, self.target, ig_pipe,
				#ingress
				[ig_port_0], ig_lag_ptr+0, 0, sap, vpn, spi, si,                          sf_bitmask_0, rmac, nexthop_ptr+0, bd, eg_lag_ptr+0, 0+0, 0+0, [recircports[0]], False, 0, dsap,
				#tunnel
				tunnel_encap_ptr+0, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr+0, tunnel_encap_bd+0, dmac_0, tunnel_encap_smac_ptr+0, smac
				#egress
			)

			npb_nsh_chain_end_add(self, self.target, ig_pipe,
				#ingress
				[ig_port_1], ig_lag_ptr+1, 0,     ta,      spi, si-(popcount(sf_bitmask_0)), sf_bitmask_1, rmac, nexthop_ptr+1, bd, eg_lag_ptr+1, 0+1, 0+1, [eg_port_1], False, 0, dsap
				#egress
			)

			# -----------------
			# Ingress SF(s)
			# -----------------

			# -----------------
			# Egress SF(s)
			# -----------------

			# -----------------

#			time.sleep(1)

			########################################################################
			# NSH Encap
			########################################################################

			# -----------------------------------------------------------
			# Create / Send / Verify the packet
			# -----------------------------------------------------------

			src_pkt, exp_pkt = npb_simple_1lyr_udp(
				dmac_nsh=dmac_0, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
				dmac=dmac, smac=smac,
				sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
				spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
			)

			'''
#			base_pkt = testutils.simple_tcp_packet(eth_dst=dmac)
			base_pkt = testutils.simple_udp_packet(eth_dst=dmac)
			print(type(base_pkt))

			# -----------------

			src_pkt = \
				base_pkt
			print(type(src_pkt))

			# -----------------

			exp_pkt = \
						testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac_0, eth_type=0x894f) / \
						scapy.NSH(MDType=1, NextProto=3, NSP=spi, NSI=si-(popcount(sf_bitmask_0)), TTL=63, \
							NPC=((2<<24)|(sap)), \
							NSC=((vpn<<16)|(0)), \
							SPC=0, \
							SSC=0, \
						) / \
						base_pkt
			print(type(exp_pkt))
			'''

			# -----------------------------------------------------------

			logger.info("Sending packet on port %d", ig_port_0)
			testutils.send_packet(self, ig_port_0, src_pkt)

			# -----------------------------------------------------------

#			logger.info("Verify packet on port %d", eg_port_0)
#			testutils.verify_packets(self, exp_pkt, [eg_port_0])

#			logger.info("Verify no other packets")
#			testutils.verify_no_other_packets(self, 0, 1)

			########################################################################
			# NSH Decap
			########################################################################

			# -----------------------------------------------------------
			# Create / Send / Verify the packet
			# -----------------------------------------------------------

			exp_pkt_saved = exp_pkt

			src_pkt, exp_pkt = npb_simple_1lyr_udp(
				spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
				dmac=dmac, smac=smac,
				sf_bitmask=sf_bitmask_1, start_of_chain=False, end_of_chain=True, scope_term_list=[],
				spi_exp=spi, si_exp=si-(popcount(sf_bitmask_0)), sap_exp=sap, vpn_exp=vpn
			)

			src_pkt = exp_pkt_saved.exp_pkt

			'''
			src_pkt = exp_pkt
			print(type(src_pkt))

			# -----------------

#			exp_pkt = testutils.simple_tcp_packet(eth_dst=dmac)
			exp_pkt = testutils.simple_udp_packet(eth_dst=dmac)
			print(type(exp_pkt))
			'''

			# -----------------------------------------------------------

#			logger.info("Sending packet on port %d", ig_port_1)
#			testutils.send_packet(self, ig_port_1, src_pkt)

			# -----------------------------------------------------------

			logger.info("Verify packet on port %d", eg_port_1)
			testutils.verify_packets(self, exp_pkt, [eg_port_1])

			logger.info("Verify no other packets")
			testutils.verify_no_other_packets(self, 0, 1)

			# -----------------------------------------------------------
			# Delete Table Entries
			# -----------------------------------------------------------
			cleanUpGlobal(self)
