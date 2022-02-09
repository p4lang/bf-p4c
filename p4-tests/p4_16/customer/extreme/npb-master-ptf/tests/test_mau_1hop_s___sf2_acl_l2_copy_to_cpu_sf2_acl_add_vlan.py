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

			ig_port = ig_swports[ig_pipe][1]
			eg_port = eg_swports[1]
			ig_port2= ig_swports[ig_pipe][0]
			eg_port2= eg_swports[0]

			# -----------------------
			# Packet values to use
			# -----------------------

			smac = '11:11:11:11:11:11'
			dmac = '22:22:22:22:22:22'
			dmac2= '23:22:22:22:22:22'
			sip = "0.0.0.3"
			dip = "0.0.0.4"

			rmac = '33:33:33:33:33:33'

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

			sf_bitmask              = 5 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

			nexthop_ptr             = 1 # Arbitrary value
			vid                     = 2080 # Arbitrary value
			bd                      = 2 # Arbitrary value
			ig_lag_ptr              = 3 # Arbitrary value
			eg_lag_ptr              = 4 # Arbitrary value
			tunnel_encap_ptr        = 5 # Arbitrary value
			tunnel_encap_nexthop_ptr= 6 # Arbitrary value
			tunnel_encap_bd         = 7 # Arbitrary value
			tunnel_encap_smac_ptr   = 8 # Arbitrary value

			mgid                    = 8 # Arbitrary value
			node                    = 7 # Arbitrary value
			rid                     = 9 # Arbitrary value

			# -----------------------------------------------------------
			# Insert Table Entries
			# -----------------------------------------------------------

			npb_nsh_chain_start_end_add(self, self.target, ig_pipe,
				#ingress
				[ig_port], ig_lag_ptr, 0, sap, vpn, spi, si, sf_bitmask, rmac, nexthop_ptr, bd, eg_lag_ptr, 0, 0, [eg_port], False, 0, dsap
				#tunnel
#				tunnel_encap_ptr, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr, tunnel_encap_bd, dmac, tunnel_encap_smac_ptr, smac
				#egress
			)

			# mirrored, to cpu port
			npb_egr_port_add      (self, self.target, ig_pipe, [eg_port2], True, eg_lag_ptr)

			# from cpu port, to normal port
			npb_nsh_bridge_add(self, self.target, ig_pipe,
				#ingress
#				[ig_port2], ig_lag_ptr, rmac, 0x0800, 0, vid, dmac2, eg_lag_ptr+1, 0+1, 0+1, [eg_port], False
				[ig_port2], ig_lag_ptr, nexthop_ptr, bd, rmac, 0x0800, 0xffff, 0, 0x1, vid, 0xfff, dmac2, 0xffffffffffff, eg_lag_ptr+1, 0+1, 0+1, [eg_port], False
				#egress
			)

			# -----------------
			# Ingress SF(s)
			# -----------------

			npb_npb_sf2_policy_l2_add(self, self.target, ig_pipe, dsap=dsap, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf, mirror_enable=1, mirror_id=250, cpu_reason_code=5, add_tag_vlan_bd=5)

			npb_npb_sf2_policy_l2_add(self, self.target, ig_pipe, dsap=dsap, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, mirror_enable=1, mirror_id=250, cpu_reason_code=5, add_tag_vlan_bd=5)
			npb_npb_sf2_policy_l2_add(self, self.target, ig_pipe, dsap=dsap, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, mirror_enable=1, mirror_id=250, cpu_reason_code=5, add_tag_vlan_bd=5)
			npb_npb_sf2_policy_l2_add(self, self.target, ig_pipe, dsap=dsap, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, mirror_enable=1, mirror_id=250, cpu_reason_code=5, add_tag_vlan_bd=5)
			npb_npb_sf2_policy_l2_add(self, self.target, ig_pipe, dsap=dsap, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, mirror_enable=1, mirror_id=250, cpu_reason_code=5, add_tag_vlan_bd=5)
			npb_npb_sf2_policy_l2_add(self, self.target, ig_pipe, dsap=dsap, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, mirror_enable=1, mirror_id=250, cpu_reason_code=5, add_tag_vlan_bd=5)
			npb_npb_sf2_policy_l2_add(self, self.target, ig_pipe, dsap=dsap, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, mirror_enable=1, mirror_id=250, cpu_reason_code=5, add_tag_vlan_bd=5)
			npb_npb_sf2_policy_l2_add(self, self.target, ig_pipe, dsap=dsap, tun_type=IngressTunnelType.ERSPAN.value, tun_type_mask=0xf, mirror_enable=1, mirror_id=250, cpu_reason_code=5, add_tag_vlan_bd=5)

			npb_npb_sf2_policy_hdr_edit_add(self, self.target, ig_pipe, bd=5, pcp=0, vid=vid)

#			npb_pre_port_add(self, self.target, ig_pipe, eg_port2)
			npb_pre_mirror_add(self, self.target, ig_pipe, 250, "EGRESS", eg_port2) # this is defined in the p4 code: SWITCH_MIRROR_SESSION_CPU = 250

			# -----------------
			# Ingress SFP Sel
			# -----------------

			# -----------------

#			time.sleep(1)

			# -----------------------------------------------------------
			# Create / Send / Verify the packet
			# -----------------------------------------------------------

			src_pkt, exp_pkt = npb_simple_1lyr_udp(
				dmac_nsh=dmac, smac_nsh=smac, vlan_en=False, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
				dmac=dmac, smac=smac,
				sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
				vlan_en_exp=True, vlan_en_exp_vid=vid,
				spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn,
			)

			# -----------------------------------------------------------

			logger.info("Sending packet on port %d", ig_port)
			testutils.send_packet(self, ig_port, src_pkt)

			# -----------------------------------------------------------

#			logger.info("Verify packet on port %d", eg_port)
#			testutils.verify_packets(self, exp_pkt, [eg_port])

			logger.info("Verify packet on port %d", eg_port)
			testutils.verify_packet (self, exp_pkt, eg_port)

			logger.info("Verify packet on port %d", eg_port2)
#			testutils.verify_packet (self, exp_pkt, eg_port2)

			# -------------------------------------------------
			# CPU emulation code (receive a packet, modify it, then reinject it)
			# -------------------------------------------------

			# ----- receive packet -----

			device, port = testutils.port_to_tuple(eg_port2)
			result = testutils.dp_poll(self, device_number=device, port_number=port, timeout=2, exp_pkt=None)

			result2 = cpu_model(
				result,
				True,
				ig_port2
			)

#			print("---------- Debug ----------")
#			print(testutils.format_packet(result2))
#			print("---------- Debug ----------")

			# -----------------------------------------------------------
			# Create / Send / Verify the packet
			# -----------------------------------------------------------

			src_pkt, exp_pkt = npb_simple_1lyr_udp(
				dmac_nsh=dmac2, smac_nsh=smac, vlan_en=False, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
				dmac=dmac2, smac=smac,
				sf_bitmask=sf_bitmask, start_of_chain=False, end_of_chain=True, scope_term_list=[],
				vlan_en_exp=True, vlan_en_exp_vid=vid,
				spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
			)

			'''
#			base_pkt = testutils.simple_tcp_packet(eth_dst=dmac)
			base_pkt = testutils.simple_udp_packet(eth_dst=dmac)
			print(type(base_pkt))

			# -----------------

			exp_pkt = \
				testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac2, eth_type=0x894f) / \
				scapy.NSH(MDType=1, NextProto=3, NSP=spi, NSI=si, TTL=63, \
					NPC=((2<<24)|(sap)), \
					NSC=((vpn<<16)|(0)), \
					SPC=0, \
					SSC=0, \
				) / \
				base_pkt
#			exp_pkt = base_pkt
			print(type(src_pkt))
			'''

			# -----------------------------------------------------------

			logger.info("Sending packet on port %d", ig_port2)
			testutils.send_packet(self, ig_port2, result2)

			# -----------------------------------------------------------

			logger.info("Verify packet on port %d", eg_port)
			testutils.verify_packets(self, exp_pkt, [eg_port])

			logger.info("Verify no other packets")
			testutils.verify_no_other_packets(self, 0, 1)

			# -----------------------------------------------------------
			# Delete Table Entries
			# -----------------------------------------------------------
			cleanUpGlobal(self)
