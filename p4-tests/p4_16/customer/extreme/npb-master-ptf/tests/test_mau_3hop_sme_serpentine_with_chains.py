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

from test_mau_tb_top import *

################################################################################

class test(BfRuntimeTest):

	def setUp(self):
		self.dev = 0
		self.client_id = 0
		self.p4_name = 'npb'

#		self.target = gc.Target(self.dev, pipe_id=0xffff)
		self.target = gc.Target(self.dev, pipe_id=0xffff, direction=0xff, prsr_id=0xff)
		BfRuntimeTest.setUp(self, self.client_id, self.p4_name)
		self.bfrt_info = self.interface.bfrt_info_get(self.p4_name)

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

		# -------------------------------------------------------------

		ig_port_0 = swports[1]
		eg_port_0 = swports[1]
		ig_port_1 = swports[2]
		eg_port_1 = swports[2]
		ig_port_2 = swports[3]
		eg_port_2 = swports[3]
#		ig_port_3 = swports[4]
#		eg_port_3 = swports[4]

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

		sf_bitmask_0            = 1 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress
		sf_bitmask_1            = 1 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress
		sf_bitmask_2            = 1 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

		nexthop_ptr             = 0 # Arbitrary value
		bd                      = 1 # Arbitrary value
		ig_lag_ptr              = 2 # Arbitrary value
		eg_lag_ptr              = 3 # Arbitrary value
		tunnel_encap_ptr        = 4 # Arbitrary value
		tunnel_encap_nexthop_ptr= 5 # Arbitrary value
		tunnel_encap_bd         = 6 # Arbitrary value
		tunnel_encap_smac_ptr   = 7 # Arbitrary value

		# -----------------------------------------------------------
		# Insert Table Entries
		# -----------------------------------------------------------

		npb_nsh_chain_start_add(self, self.target,
			#ingress
			[ig_port_0], ig_lag_ptr+0, 0, sap, vpn, spi+0, si,                                                   sf_bitmask_0, rmac, nexthop_ptr+0, bd, eg_lag_ptr+0, 0+0, 0+0, [eg_port_1], 0, dsap,
			#tunnel
			tunnel_encap_ptr+0, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr+0, tunnel_encap_bd+0, dmac_0, tunnel_encap_smac_ptr+0, smac
			#egress
		)

		npb_nsh_chain_end_add(self, self.target,
			#ingress
			[ig_port_1], ig_lag_ptr+1, 0,  ta,         spi+1, si-(popcount(sf_bitmask_2)),                          sf_bitmask_0, rmac, nexthop_ptr+1, bd, eg_lag_ptr+1, 0+1, 0+1, [eg_port_0], 0, dsap
			#egress
		)

		# ---------------------------------------

#		npb_nsh_chain_end_add(self, self.target,
#			#ingress
#			[ig_port_2], ig_lag_ptr+2, 0,           spi+0, si-(popcount(sf_bitmask_0)),                          sf_bitmask_2, rmac, nexthop_ptr+2, bd, eg_lag_ptr+2, 0+2, 0+2, [eg_port_3], 0, dsap
#			#egress
#		)
#
#		npb_nsh_chain_start_add(self, self.target,
#			#ingress
#			[ig_port_3], ig_lag_ptr+3, 0, sap, vpn, spi+1, si,                                                   sf_bitmask_2, rmac, nexthop_ptr+3, bd, eg_lag_ptr+3, 0+3, 0+3, [eg_port_2], 0, dsap,
#			#tunnel
#			tunnel_encap_ptr+3, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr+0, tunnel_encap_bd+0, dmac_0, tunnel_encap_smac_ptr+0, smac
#			#egress
#		)

		# -----------------
		# Ingress SF(s)
		# -----------------

		# -----------------
		# Egress SF(s)
		# -----------------

		# -----------------

#		time.sleep(1)

		########################################################################
		# NSH Encap
		########################################################################

		# -----------------------------------------------------------
		# Create / Send / Verify the packet
		# -----------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_0, smac_nsh=smac, spi=spi+0, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			dmac=dmac, smac=smac,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			spi_exp=spi+0, si_exp=si, ta_exp=ta, nshtype_exp=2, sap_exp=sap, vpn_exp=vpn
		)

		'''
#		base_pkt = testutils.simple_tcp_packet(eth_dst=dmac)
		base_pkt = testutils.simple_udp_packet(eth_dst=dmac)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))

		# -----------------

		exp_pkt = \
				testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac_0, eth_type=0x894f) / \
				scapy.NSH(MDType=1, NextProto=3, NSP=spi+0, NSI=si-(popcount(sf_bitmask_0)), TTL=63, \
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
		testutils.send_packet(self, ig_port_0, str(src_pkt))

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_1)
		testutils.verify_packets(self, exp_pkt, [eg_port_1])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		########################################################################
		# NSH Decap
		########################################################################

		# -----------------------------------------------------------
		# Create / Send / Verify the packet
		# -----------------------------------------------------------

		exp_pkt_saved = exp_pkt

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			spi=spi+0, si=si-(popcount(sf_bitmask_0))-(popcount(sf_bitmask_1)), sap=sap, vpn=vpn, ttl=62, scope=1,
			dmac=dmac, smac=smac,
			sf_bitmask=sf_bitmask_2, start_of_chain=False, end_of_chain=True, scope_term_list=[],
			spi_exp=spi+0, si_exp=si-(popcount(sf_bitmask_0))-(popcount(sf_bitmask_1)), ta_exp=ta, nshtype_exp=2, sap_exp=sap, vpn_exp=vpn
		)

		src_pkt = exp_pkt_saved.exp_pkt

		'''
		src_pkt = exp_pkt
		print(type(src_pkt))

		# -----------------

#		exp_pkt = testutils.simple_tcp_packet(eth_dst=dmac)
		exp_pkt = testutils.simple_udp_packet(eth_dst=dmac)
		print(type(exp_pkt))
		'''

		# -----------------------------------------------------------

#		logger.info("Sending packet on port %d", ig_port_2)
#		testutils.send_packet(self, ig_port_2, str(src_pkt))
#
#		# -----------------------------------------------------------
#
#		logger.info("Verify packet on port %d", eg_port_3)
#		testutils.verify_packets(self, exp_pkt, [eg_port_3])
#
#		logger.info("Verify no other packets")
#		testutils.verify_no_other_packets(self, 0, 1)

		########################################################################
		# NSH Encap
		########################################################################

		# -----------------------------------------------------------
		# Create / Send / Verify the packet
		# -----------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_0, smac_nsh=smac, spi=spi+1, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			dmac=dmac, smac=smac,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			spi_exp=spi+1, si_exp=si, ta_exp=ta, nshtype_exp=2, sap_exp=sap, vpn_exp=vpn
		)

		'''
#		base_pkt = testutils.simple_tcp_packet(eth_dst=dmac)
		base_pkt = testutils.simple_udp_packet(eth_dst=dmac)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))

		# -----------------

		exp_pkt = \
				testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac_0, eth_type=0x894f) / \
				scapy.NSH(MDType=1, NextProto=3, NSP=spi+1, NSI=si-(popcount(sf_bitmask_0)), TTL=63, \
					NPC=((2<<24)|(sap)), \
					NSC=((vpn<<16)|(0)), \
					SPC=0, \
					SSC=0, \
				) / \
				base_pkt
		print(type(exp_pkt))
		'''

		# -----------------------------------------------------------

#		logger.info("Sending packet on port %d", ig_port_3)
#		testutils.send_packet(self, ig_port_3, str(src_pkt))
#
#		# -----------------------------------------------------------
#
#		logger.info("Verify packet on port %d", eg_port_2)
#		testutils.verify_packets(self, exp_pkt, [eg_port_2])
#
#		logger.info("Verify no other packets")
#		testutils.verify_no_other_packets(self, 0, 1)

		########################################################################
		# NSH Decap
		########################################################################

		# -----------------------------------------------------------
		# Create / Send / Verify the packet
		# -----------------------------------------------------------

		exp_pkt_saved = exp_pkt

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac=dmac, smac=smac,
			spi=spi+1, si=si-(popcount(sf_bitmask_0))-(popcount(sf_bitmask_1)), sap=sap, vpn=vpn, ttl=62, scope=1,
			sf_bitmask=sf_bitmask_2, start_of_chain=False, end_of_chain=True, scope_term_list=[],
			spi_exp=spi+1, si_exp=si-(popcount(sf_bitmask_0))-(popcount(sf_bitmask_1)), ta_exp=ta, nshtype_exp=2,sap_exp=sap, vpn_exp=vpn
		)

		src_pkt = exp_pkt_saved.exp_pkt

		'''
		src_pkt = exp_pkt
		print(type(src_pkt))

		# -----------------

#		exp_pkt = testutils.simple_tcp_packet(eth_dst=dmac)
		exp_pkt = testutils.simple_udp_packet(eth_dst=dmac)
		print(type(exp_pkt))
		'''

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_1)
		testutils.send_packet(self, ig_port_1, str(src_pkt))

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packets(self, exp_pkt, [eg_port_0])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		# -----------------------------------------------------------
		# Delete Table Entries
		# -----------------------------------------------------------

		npb_nsh_chain_start_del(self, self.target,
			#ingress
			[ig_port_0], ig_lag_ptr+0, spi+0, si,                                                   sf_bitmask_0, rmac, nexthop_ptr+0, eg_lag_ptr+0, 0+0, 0+0, 1, [eg_port_1],
			#tunnel
			tunnel_encap_ptr+0, tunnel_encap_nexthop_ptr+0, tunnel_encap_bd+0, tunnel_encap_smac_ptr+0
			#egress
		)

		npb_nsh_chain_end_del(self, self.target,
			#ingress
			[ig_port_1], ig_lag_ptr+1, ta, spi+1, si-(popcount(sf_bitmask_2)),                          sf_bitmask_0, rmac, nexthop_ptr+1, eg_lag_ptr+1, 0+1, 0+1, 1, [eg_port_0]
			#egress
		)

		# ---------------------------------------

#		npb_nsh_chain_end_del(self, self.target,
#			#ingress
#			[ig_port_2], ig_lag_ptr+2, spi+0, si-(popcount(sf_bitmask_0)),                          sf_bitmask_2, rmac, nexthop_ptr+2, eg_lag_ptr+2, 0+2, 0+2, 1, [eg_port_3]
#			#egress
#		)

#		npb_nsh_chain_start_del(self, self.target,
#			#ingress
#			[ig_port_3], ig_lag_ptr+3, spi+1, si,                                                   sf_bitmask_2, rmac, nexthop_ptr+3, eg_lag_ptr+3, 0+3, 0+3, 1, [eg_port_2],
#			#tunnel
#			tunnel_encap_ptr+3, tunnel_encap_nexthop_ptr+0, tunnel_encap_bd+0, tunnel_encap_smac_ptr+0
#			#egress
#		)

		# -----------------
		# Ingress SF(s)
		# -----------------

		# -----------------
		# Egress SF(s)
		# -----------------
