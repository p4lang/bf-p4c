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

			# -----------------------
			# Packet values to use
			# -----------------------

			smac = '11:11:11:11:11:11'
			dmac = '22:22:22:22:22:22'
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
			ta                      = 8 # Arbitrary value

			sf_bitmask              = 1 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

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
			print("Starting test on Ingress pipe", ig_pipe)

			npb_nsh_chain_start_add(self, self.target, ig_pipe,
				#ingress
				[ig_port], ig_lag_ptr, 0, sap, vpn, spi, si,                          sf_bitmask, rmac, nexthop_ptr, bd, eg_lag_ptr, 0, 0, [eg_port], False, 0, dsap,
				#tunnel
				tunnel_encap_ptr, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr, tunnel_encap_bd, dmac, tunnel_encap_smac_ptr, smac
				#egress
			)

			# -----------------
			# Ingress Tunnel
			# -----------------

			npb_tunnel_inner_sap_add(self, self.target, ig_pipe, sap=sap, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, sap_new=sap, vpn=vpn+1, scope=1)
			npb_tunnel_inner_sap_add(self, self.target, ig_pipe, sap=sap, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, sap_new=sap, vpn=vpn+1, scope=1)
			npb_tunnel_inner_sap_add(self, self.target, ig_pipe, sap=sap, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, sap_new=sap, vpn=vpn+1, scope=1)
			npb_tunnel_inner_sap_add(self, self.target, ig_pipe, sap=sap, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, sap_new=sap, vpn=vpn+1, scope=0)
			npb_tunnel_inner_sap_add(self, self.target, ig_pipe, sap=sap, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, sap_new=sap, vpn=vpn+1, scope=1)
			npb_tunnel_inner_sap_add(self, self.target, ig_pipe, sap=sap, tun_type=IngressTunnelType.ERSPAN.value, tun_type_mask=0xf, sap_new=sap, vpn=vpn+1, scope=1)
			npb_tunnel_inner_sap_add(self, self.target, ig_pipe, sap=sap, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, sap_new=sap, vpn=vpn+1, scope=1)

			# -----------------
			# Ingress SF(s)
			# -----------------

			# -----------------
			# Egress SF(s)
			# -----------------

			npb_npb_sf0_policy_l2_add(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x0800, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, terminate=1)
			npb_npb_sf0_policy_l2_add(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x0800, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, terminate=1)
			npb_npb_sf0_policy_l2_add(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x0800, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, terminate=1)
			npb_npb_sf0_policy_l2_add(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x0800, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, terminate=0)
			npb_npb_sf0_policy_l2_add(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x0800, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, terminate=1)
			npb_npb_sf0_policy_l2_add(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x0800, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.ERSPAN.value, tun_type_mask=0xf, terminate=1)
			npb_npb_sf0_policy_l2_add(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x0800, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, terminate=1)

			# -----------------

#			time.sleep(1)

			# -----------------------------------------------------------
			# Create / Send / Verify the packet (NVGRE / GRE / IP)
			# -----------------------------------------------------------

			src_pkt, exp_pkt = npb_simple_3lyr_nvgre_gre_ip(
				dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
				sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[0, 1],
				spi_exp=spi, si_exp=si, ta_exp=ta, nshtype_exp=2, sap_exp=sap, vpn_exp=vpn+1
			)

			# -----------------------------------------------------------

			logger.info("Sending packet1 on port %d", ig_port)
			testutils.send_packet(self, ig_port, src_pkt)

			# -----------------------------------------------------------

			logger.info("Verify packet on port %d", eg_port)
			testutils.verify_packets(self, exp_pkt, [eg_port])

			logger.info("Verify no other packets")
			testutils.verify_no_other_packets(self, 0, 1)


			# -----------------------------------------------------------
			# Create / Send / Verify the packet (GRE / IP / IP)
			# -----------------------------------------------------------

			src_pkt, exp_pkt = npb_simple_3lyr_gre_ip_ip(
				dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
				sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[0, 1],
				spi_exp=spi, si_exp=si,  ta_exp=ta, nshtype_exp=2, sap_exp=sap, vpn_exp=vpn+1
			)
			
			# -----------------------------------------------------------
			logger.info("Sending packet2 on port %d", ig_port)
			testutils.send_packet(self, ig_port, src_pkt)

			# -----------------------------------------------------------

			logger.info("Verify packet on port %d", eg_port)
			testutils.verify_packets(self, exp_pkt, [eg_port])

			logger.info("Verify no other packets")
			testutils.verify_no_other_packets(self, 0, 1)
			

			# -----------------------------------------------------------
			# Create / Send / Verify the packet (GRE / IP / IPv6)
			# -----------------------------------------------------------

			src_pkt, exp_pkt = npb_simple_3lyr_gre_ip_ipv6(
				dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
				sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[0, 1],
				spi_exp=spi, si_exp=si, ta_exp=ta, nshtype_exp=2, sap_exp=sap, vpn_exp=vpn+1
			)

			# -----------------------------------------------------------

			logger.info("Sending packet3 on port %d", ig_port)
			testutils.send_packet(self, ig_port, src_pkt)

			# -----------------------------------------------------------

			logger.info("Verify packet on port %d", eg_port)
			testutils.verify_packets(self, exp_pkt, [eg_port])

			logger.info("Verify no other packets")
			testutils.verify_no_other_packets(self, 0, 1)


			# -----------------------------------------------------------
			# Create / Send / Verify the packet (VXLANv6 / GRE / IP)
			# -----------------------------------------------------------

			src_pkt, exp_pkt = npb_simple_3lyr_vxlanv6_gre_ip(
				dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
				sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[0, 1],
				spi_exp=spi, si_exp=si, ta_exp=ta, nshtype_exp=2, sap_exp=sap, vpn_exp=vpn+1
			)

			# -----------------------------------------------------------

			logger.info("Sending packet4 on port %d", ig_port)
			testutils.send_packet(self, ig_port, src_pkt)

			# -----------------------------------------------------------

			logger.info("Verify packet on port %d", eg_port)
			testutils.verify_packets(self, exp_pkt, [eg_port])

			logger.info("Verify no other packets")
			testutils.verify_no_other_packets(self, 0, 1)

			# -----------------------------------------------------------
			# Create / Send / Verify the packet (GREv6 / IP / IP)
			# -----------------------------------------------------------

			src_pkt, exp_pkt = npb_simple_3lyr_grev6_ip_ip(
				dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
				sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[0, 1],
				spi_exp=spi, si_exp=si, ta_exp=ta, nshtype_exp=2, sap_exp=sap, vpn_exp=vpn+1
			)

			# -----------------------------------------------------------

			logger.info("Sending packet5 on port %d", ig_port)
			testutils.send_packet(self, ig_port, src_pkt)

			# -----------------------------------------------------------

			logger.info("Verify packet on port %d", eg_port)
			testutils.verify_packets(self, exp_pkt, [eg_port])

			logger.info("Verify no other packets")
			testutils.verify_no_other_packets(self, 0, 1)

			# -----------------------------------------------------------
			# Create / Send / Verify the packet (GREv6 / IP / IPv6)
			# -----------------------------------------------------------

			src_pkt, exp_pkt = npb_simple_3lyr_grev6_ip_ipv6(
				dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
				sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[0, 1],
				spi_exp=spi, si_exp=si, ta_exp=ta, nshtype_exp=2, sap_exp=sap, vpn_exp=vpn+1
			)

			# -----------------------------------------------------------

			logger.info("Sending packet6 on port %d", ig_port)
			testutils.send_packet(self, ig_port, src_pkt)

			# -----------------------------------------------------------

			logger.info("Verify packet on port %d", eg_port)
			testutils.verify_packets(self, exp_pkt, [eg_port])

			logger.info("Verify no other packets")
			testutils.verify_no_other_packets(self, 0, 1)

			# -----------------------------------------------------------
			# Create / Send / Verify the packet (NVGRE / GTP-C / UDP)
			# -----------------------------------------------------------

			src_pkt, exp_pkt = npb_simple_3lyr_nvgre_gtpc_udp(
				dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
				sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[0],
				spi_exp=spi, si_exp=si, ta_exp=ta, nshtype_exp=2, sap_exp=sap, vpn_exp=vpn+1
			)

			# -----------------------------------------------------------

			logger.info("Sending packet on port %d", ig_port)
			testutils.send_packet(self, ig_port, src_pkt)

			# -----------------------------------------------------------

			logger.info("Verify packet on port %d", eg_port)
			testutils.verify_packets(self, exp_pkt, [eg_port])

			logger.info("Verify no other packets")
			testutils.verify_no_other_packets(self, 0, 1)

			# -----------------------------------------------------------
			# Create / Send / Verify the packet (NVGRE / GTP-U / IP)
			# -----------------------------------------------------------

			src_pkt, exp_pkt = npb_simple_3lyr_nvgre_gtpu_ip(
				dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
				sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[0, 1],
				spi_exp=spi, si_exp=si, ta_exp=ta, nshtype_exp=2, sap_exp=sap, vpn_exp=vpn+1
			)

			# -----------------------------------------------------------

			logger.info("Sending packet7 on port %d", ig_port)
			testutils.send_packet(self, ig_port, src_pkt)

			# -----------------------------------------------------------

			logger.info("Verify packet on port %d", eg_port)
			testutils.verify_packets(self, exp_pkt, [eg_port])

			logger.info("Verify no other packets")
			testutils.verify_no_other_packets(self, 0, 1)

			# -----------------------------------------------------------
			# Reconfigure for "inner" to be ipv6 instead of ipv4
			# -----------------------------------------------------------

			npb_npb_sf0_policy_l2_del(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x0800, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf)
			npb_npb_sf0_policy_l2_del(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x0800, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
			npb_npb_sf0_policy_l2_del(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x0800, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)
			npb_npb_sf0_policy_l2_del(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x0800, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf)
			npb_npb_sf0_policy_l2_del(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x0800, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf)
			npb_npb_sf0_policy_l2_del(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x0800, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.ERSPAN.value, tun_type_mask=0xf)
			npb_npb_sf0_policy_l2_del(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x0800, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf)

			npb_npb_sf0_policy_l2_add(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x86dd, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, terminate=1)
			npb_npb_sf0_policy_l2_add(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x86dd, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, terminate=1)
			npb_npb_sf0_policy_l2_add(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x86dd, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, terminate=1)
			npb_npb_sf0_policy_l2_add(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x86dd, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, terminate=0)
			npb_npb_sf0_policy_l2_add(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x86dd, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, terminate=1)
			npb_npb_sf0_policy_l2_add(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x86dd, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.ERSPAN.value, tun_type_mask=0xf, terminate=1)
			npb_npb_sf0_policy_l2_add(self, self.target, ig_pipe, sap=sap, vpn=vpn+1, l2_etype = 0x86dd, l2_etype_mask = 0xffff, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, terminate=1)

			# -----------------------------------------------------------
			# Create / Send / Verify the packet (GRE / IPv6 / IP)
			# -----------------------------------------------------------

			src_pkt, exp_pkt = npb_simple_3lyr_gre_ipv6_ip(
				dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
				sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[0, 1],
				spi_exp=spi, si_exp=si, ta_exp=ta, nshtype_exp=2, sap_exp=sap, vpn_exp=vpn+1
			)

			# -----------------------------------------------------------

			logger.info("Sending packet on port %d", ig_port)
			testutils.send_packet(self, ig_port, src_pkt)

			# -----------------------------------------------------------

			logger.info("Verify packet on port %d", eg_port)
			testutils.verify_packets(self, exp_pkt, [eg_port])

			logger.info("Verify no other packets")
			testutils.verify_no_other_packets(self, 0, 1)

			# -----------------------------------------------------------
			# Create / Send / Verify the packet (GREv6 / IPv6 / IP)
			# -----------------------------------------------------------

			src_pkt, exp_pkt = npb_simple_3lyr_grev6_ipv6_ip(
				dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
				sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[0, 1],
				spi_exp=spi, si_exp=si, ta_exp=ta, nshtype_exp=2, sap_exp=sap, vpn_exp=vpn+1
			)

			# -----------------------------------------------------------

			logger.info("Sending packet on port %d", ig_port)
			testutils.send_packet(self, ig_port, src_pkt)

			# -----------------------------------------------------------

			logger.info("Verify packet on port %d", eg_port)
			testutils.verify_packets(self, exp_pkt, [eg_port])

			logger.info("Verify no other packets")
			testutils.verify_no_other_packets(self, 0, 1)

			# -----------------------------------------------------------
			# Delete Table Entries
			# -----------------------------------------------------------
			cleanUpGlobal(self)

