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
# Test Goal for testing 
# My notes on a complete truth table for just two things (e/vn and vlan)
# ==============         ==============      
# Packet                 Enables
# {vn/e,  vlan}          {e/vn,  vlan}
# ==============         ==============      
# {false, false}         {false, false}          --> nothing   enabled, nothing in pkt   --> no action
# {false, false}         {false, true }          --> vlan      enabled, nothing in pkt   --> no action
# {false, false}         {true,  false}          --> vn        enabled, nothing in pkt   --> no action
# {false, false}         {true,  true }          --> vn + vlan enabled, nothing in pkt   --> no action
# --------------         --------------      
# {false, true }         {false, false}          --> nothing   enabled, vlan in pkt      --> no action
# {false, true }         {false, true }          --> vlan      enabled, vlan in pkt      --> vlan to eth : case 0
# {false, true }         {true,  false}          --> vn        enabled, vlan in pkt      --> no action
# {false, true }         {true,  true }          --> vn + vlan enabled, vlan in pkt      --> vlan to eth : case 0
# --------------         --------------      
# {true,  false}         {false, false}          --> nothing   enabled, vn in pkt        --> no action
# {true,  false}         {false, true }          --> vlan      enabled, vn in pkt        --> no action
# {true,  false}         {true,  false}          --> vn        enabled, vn in pkt        --> vn   to eth : case 1
# {true,  false}         {true,  true }          --> vn + vlan enabled  vn in pkt        --> vn   to eth : case 1
# --------------         --------------      
# {true,  true }         {false, false}          --> nothing   enabled, vn + vlan in pkt --> no action
# {true,  true }         {false, true }          --> vlan      enabled, vn + vlan in pkt --> vlan to VN  : case 2
# {true,  true }         {true,  false}          --> vn        enabled, vn + vlan in pkt --> vn   to eth : case 3
# {true,  true }         {true,  true }          --> vn + vlan enabled, vn + vlan in pkt --> vlan to eth : case 4 (double delete case)


import sys
sys.path.append("/npb-dp/p4_pipelines/tst/basic/mau")
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

		# -------------------------------------------------------------


		# -----------------------
		# Port 0 - Strip_e = False, Strip_vlan = False 
		# -----------------------
		ig_port = swports[1]
		eg_port = swports[1]

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

		sf_bitmask              = 4 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

		nexthop_ptr             = 14 # Arbitrary value
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

		npb_nsh_chain_start_end_add(self, self.target,
			#ingress
			[ig_port], ig_lag_ptr, 0, sap, vpn, spi, si, sf_bitmask, rmac, nexthop_ptr, bd, eg_lag_ptr, 0, 0, [eg_port], False, 0, dsap
			#tunnel
			#tunnel_encap_ptr, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr, tunnel_encap_bd, dmac, tunnel_encap_smac_ptr, smac
			#egress
		)

		# -----------------------
		# Port 1 Strip_e = False, Strip_vlan = True 
		# -----------------------
		ig_port_1 = swports[2]
		eg_port_1 = swports[2]


		smac_1 = '11:11:01:11:11:11'
		dmac_1 = '22:22:01:22:22:22'
		sip_1 = "0.0.1.3"
		dip_1 = "0.0.1.4"

		##rmac_1 = '33:33:01:33:33:33' Shared RMAC

		# -----------------------
		# NSH values to use
		# -----------------------

		sap_1                     = 1 # Arbitrary value
		vpn_1                     = 2 # Arbitrary value
		flow_class_acl_1          = 3 # Arbitrary value
		flow_class_sfp_1          = 4 # Arbitrary value
		spi_1                     = 5 # Arbitrary value
		si_1                      = 6 # Arbitrary value (ttl)
		sfc_1                     = 7 # Arbitrary value
		dsap_1                    = 8 # Arbitrary value

		sf_bitmask_1              = 4 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

		nexthop_ptr_1             = 1 # Arbitrary value
		bd_1                      = 2 # Arbitrary value
		ig_lag_ptr_1              = 4 # Arbitrary value
		eg_lag_ptr_1              = 5 # Arbitrary value
		tunnel_encap_ptr_1        = 5 # Arbitrary value
		tunnel_encap_nexthop_ptr_1 = 6 # Arbitrary value
		tunnel_encap_bd_1         = 7 # Arbitrary value
		tunnel_encap_smac_ptr_1   = 8 # Arbitrary value

		npb_nsh_chain_start_end_add(self, self.target,
			#ingress
			[ig_port_1], ig_lag_ptr_1, 0, sap_1, vpn_1, spi_1, si_1, sf_bitmask_1, rmac, nexthop_ptr_1, bd_1, eg_lag_ptr_1, 1, 1, [eg_port_1], False, 0, dsap_1,
			#tunnel
			#tunnel_encap_ptr_1, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr_1, tunnel_encap_bd_1, dmac_1, tunnel_encap_smac_ptr_1, smac_1
			#egress
		)

		# -----------------------
		# Port 2 Strip_e = True, Strip_vlan = False 
		# -----------------------
		ig_port_2 = swports[3]
		eg_port_2 = swports[3]


		smac_2 = '11:11:02:11:11:11'
		dmac_2 = '22:22:02:22:22:22'
		sip_2 = "0.0.2.3"
		dip_2 = "0.0.2.4"

		##rmac_2 = '33:33:01:33:33:33' Shared RMAC

		# -----------------------
		# NSH values to use
		# -----------------------

		sap_2                     = 2 # Arbitrary value
		vpn_2                     = 3 # Arbitrary value
		flow_class_acl_2          = 4 # Arbitrary value
		flow_class_sfp_2          = 5 # Arbitrary value
		spi_2                     = 6 # Arbitrary value
		si_2                      = 7 # Arbitrary value (ttl)
		sfc_2                     = 8 # Arbitrary value
		dsap_2                    = 9 # Arbitrary value

		sf_bitmask_2              = 4 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

		nexthop_ptr_2             = 2 # Arbitrary value
		bd_2                      = 3 # Arbitrary value
		ig_lag_ptr_2              = 6 # Arbitrary value
		eg_lag_ptr_2              = 7 # Arbitrary value
		tunnel_encap_ptr_2        = 7 # Arbitrary value
		tunnel_encap_nexthop_ptr_2 = 8 # Arbitrary value
		tunnel_encap_bd_2         = 9 # Arbitrary value
		tunnel_encap_smac_ptr_2   = 10 # Arbitrary value

		npb_nsh_chain_start_end_add(self, self.target,
			#ingress
			[ig_port_2], ig_lag_ptr_2, 0, sap_2, vpn_2, spi_2, si_2, sf_bitmask_2, rmac, nexthop_ptr_2, bd_2, eg_lag_ptr_2, 2, 2, [eg_port_2], False, 0, dsap_2,
			#tunnel
			#tunnel_encap_ptr_2, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr_2, tunnel_encap_bd_2, dmac_2, tunnel_encap_smac_ptr_2, smac_2
			#egress
		)



		# -----------------------
		# Port 3 - Strip_e = True, Strip_vlan = True 
		# -----------------------
		ig_port_3 = swports[4]
		eg_port_3 = swports[4]


		smac_3 = '11:11:03:11:11:11'
		dmac_3 = '22:22:03:22:22:22'
		sip_3 = "0.0.3.3"
		dip_3 = "0.0.3.4"

		##rmac_2 = '33:33:01:33:33:33' Shared RMAC

		# -----------------------
		# NSH values to use
		# -----------------------

		sap_3                     = 3 # Arbitrary value
		vpn_3                     = 4 # Arbitrary value
		flow_class_acl_3          = 5 # Arbitrary value
		flow_class_sfp_3          = 6 # Arbitrary value
		spi_3                     = 7 # Arbitrary value
		si_3                      = 8 # Arbitrary value (ttl)
		sfc_3                     = 9 # Arbitrary value
		dsap_3                    = 10 # Arbitrary value

		sf_bitmask_3              = 4 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

		nexthop_ptr_3             = 3 # Arbitrary value
		bd_3                      = 4 # Arbitrary value
		ig_lag_ptr_3              = 7 # Arbitrary value
		eg_lag_ptr_3              = 8 # Arbitrary value
		tunnel_encap_ptr_3        = 8 # Arbitrary value
		tunnel_encap_nexthop_ptr_3 = 9 # Arbitrary value
		tunnel_encap_bd_3         = 10 # Arbitrary value
		tunnel_encap_smac_ptr_3   = 11 # Arbitrary value

		npb_nsh_chain_start_end_add(self, self.target,
			#ingress
			[ig_port_3], ig_lag_ptr_3, 0, sap_3, vpn_3, spi_3, si_3, sf_bitmask_3, rmac, nexthop_ptr_3, bd_3, eg_lag_ptr_3, 3, 3, [eg_port_3], False, 0, dsap_3,
			#tunnel
			#tunnel_encap_ptr_3, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr_3, tunnel_encap_bd_3, dmac_3, tunnel_encap_smac_ptr_3, smac_3
			#egress
		)



		# -----------------
		# Egress SF(s)
		# -----------------

		npb_npb_sf2_policy_l2_add    (self, self.target, dsap=dsap,   l2_etype=0x0800, l2_etype_mask=0xffff, strip_tag_e=False, strip_tag_vlan=False)
		npb_npb_sf2_policy_l2_add    (self, self.target, dsap=dsap_1, l2_etype=0x0800, l2_etype_mask=0xffff, strip_tag_e=False, strip_tag_vlan=True)
		npb_npb_sf2_policy_l2_add    (self, self.target, dsap=dsap_2, l2_etype=0x0800, l2_etype_mask=0xffff, strip_tag_e=True, strip_tag_vlan=False)
		npb_npb_sf2_policy_l2_add    (self, self.target, dsap=dsap_3, l2_etype=0x0800, l2_etype_mask=0xffff, strip_tag_e=True, strip_tag_vlan=True)


		# -----------------

#		time.sleep(1)

		# ----------------------------------------------------------------------------------------------------
		# {false, false}         {false, false}          --> nothing   enabled, nothing in pkt   --> no action
		# ----------------------------------------------------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=False,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi, NSI=si-(popcount(sf_bitmask)), TTL=63, \
				NPC=((2<<24)|(sap)), \
				NSC=((vpn<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {f, f} {f, f} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)




		# ----------------------------------------------------------------------------------------------------
		# {false, false}         {false, true }          --> vlan      enabled, nothing in pkt   --> no action
		# ----------------------------------------------------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=False,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_1,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_1,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_1, eth_dst=dmac_1, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_1, NSI=si_1-(popcount(sf_bitmask_1)), TTL=63, \
				NPC=((2<<24)|(sap_1)), \
				NSC=((vpn_1<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {f, f} {f, t} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_1)
		testutils.send_packet(self, ig_port_1, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_1)
		testutils.verify_packets(self, exp_pkt, [eg_port_1])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)


		# ----------------------------------------------------------------------------------------------------
		# {false, false}         {true,  false}          --> vn        enabled, nothing in pkt   --> no action
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_2, smac_nsh=smac_2, spi=spi_2, si=si_2, sap=sap_2, vpn=vpn_2, ttl=63, scope=1,
			vlan_en=False,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask_2, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_2, si_exp=si_2, sap_exp=sap_2, vpn_exp=vpn_2
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_2,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_2,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_2, eth_dst=dmac_2, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_2, NSI=si_2-(popcount(sf_bitmask_2)), TTL=63, \
				NPC=((2<<24)|(sap_2)), \
				NSC=((vpn_2<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {f, f} {t, f} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_2)
		testutils.send_packet(self, ig_port_2, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_2)
		testutils.verify_packets(self, exp_pkt, [eg_port_2])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)





		# ----------------------------------------------------------------------------------------------------
		# {false, false}         {true,  true }          --> vn + vlan enabled, nothing in pkt   --> no action
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_3, smac_nsh=smac_3, spi=spi_3, si=si_3, sap=sap_3, vpn=vpn_3, ttl=63, scope=1,
			vlan_en=False,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask_3, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_3, si_exp=si_3, sap_exp=sap_3, vpn_exp=vpn_3
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_3,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_3,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_3, eth_dst=dmac_3, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_3, NSI=si_3-(popcount(sf_bitmask_3)), TTL=63, \
				NPC=((2<<24)|(sap_3)), \
				NSC=((vpn_3<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {f, f} {t, t} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_3)
		testutils.send_packet(self, ig_port_3, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_3)
		testutils.verify_packets(self, exp_pkt, [eg_port_3])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)



		# ----------------------------------------------------------------------------------------------------
		# {false, true }         {false, false}          --> nothing   enabled, vlan in pkt      --> no action
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=True,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi, NSI=si-(popcount(sf_bitmask)), TTL=63, \
				NPC=((2<<24)|(sap)), \
				NSC=((vpn<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {f, t} {f, f} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)





		# ----------------------------------------------------------------------------------------------------
		# {false, true }         {false, true }          --> vlan      enabled, vlan in pkt      --> vlan to eth : case 0
		# ----------------------------------------------------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=True,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_1,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_1,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_1, eth_dst=dmac_1, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_1, NSI=si_1-(popcount(sf_bitmask_1)), TTL=63, \
				NPC=((2<<24)|(sap_1)), \
				NSC=((vpn_1<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {f, t} {f, t} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(exp_pkt)
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_1)
		testutils.send_packet(self, ig_port_1, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_1)
		testutils.verify_packets(self, exp_pkt, [eg_port_1])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)





		# ----------------------------------------------------------------------------------------------------
		# {false, true }         {true,  false}          --> vn        enabled, vlan in pkt      --> no action
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_2, smac_nsh=smac_2, spi=spi_2, si=si_2, sap=sap_2, vpn=vpn_2, ttl=63, scope=1,
			vlan_en=True,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask_2, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_2, si_exp=si_2, sap_exp=sap_2, vpn_exp=vpn_2
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_2,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_2,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_2, eth_dst=dmac_2, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_2, NSI=si_2-(popcount(sf_bitmask_2)), TTL=63, \
				NPC=((2<<24)|(sap_2)), \
				NSC=((vpn_2<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {f, t} {t, f} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_2)
		testutils.send_packet(self, ig_port_2, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_2)
		testutils.verify_packets(self, exp_pkt, [eg_port_2])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)



		# ----------------------------------------------------------------------------------------------------
		# {false, true }         {true,  true }          --> vn + vlan enabled, vlan in pkt      --> vlan to eth : case 0
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_3, smac_nsh=smac_3, spi=spi_3, si=si_3, sap=sap_3, vpn=vpn_3, ttl=63, scope=1,
			vlan_en=True,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask_3, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_3, si_exp=si_3, sap_exp=sap_3, vpn_exp=vpn_3
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_3,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_3,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_3, eth_dst=dmac_3, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_3, NSI=si_3-(popcount(sf_bitmask_3)), TTL=63, \
				NPC=((2<<24)|(sap_3)), \
				NSC=((vpn_3<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {f, t} {t, t} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(exp_pkt)
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_3)
		testutils.send_packet(self, ig_port_3, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_3)
		testutils.verify_packets(self, exp_pkt, [eg_port_3])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)






		# -----------------------------------------------------------
		# {true, false}         {false, false}          --> nothing   enabled, nothing in pkt   --> no action
		# -----------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=False,e_en=True,vn_en=False,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=True,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)

		'''
#		base_pkt = simple_tcp_packet2(eth_dst=dmac,tcp_sport=0,  tcp_dport=0,dl_vlan_enable=1)
		base_pkt = simple_udp_packet2(eth_dst=dmac,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

#		base_pkt_exp = testutils.simple_udp_packet(eth_dst=dmac,udp_sport=443,udp_dport=0,pktlen=100-4) # subtract 4, since tag will be stripped
		base_pkt_exp = simple_udp_packet2(eth_dst=dmac,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi, NSI=si-(popcount(sf_bitmask)), TTL=63, \
				NPC=((2<<24)|(sap)), \
				NSC=((vpn<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {t, f} {f, f} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)


		# ----------------------------------------------------------------------------------------------------
		#  {true,  false}         {false, true }          --> vlan      enabled, vn in pkt        --> no action
		# ----------------------------------------------------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=False,e_en=True,vn_en=False,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=True,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_1,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_1,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_1, eth_dst=dmac_1, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_1, NSI=si_1-(popcount(sf_bitmask_1)), TTL=63, \
				NPC=((2<<24)|(sap_1)), \
				NSC=((vpn_1<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {t, f} {f, t} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_1)
		testutils.send_packet(self, ig_port_1, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_1)
		testutils.verify_packets(self, exp_pkt, [eg_port_1])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)





		# ----------------------------------------------------------------------------------------------------
		# {true,  false}         {true,  false}          --> vn        enabled, vn in pkt        --> vn   to eth : case 1
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_2, smac_nsh=smac_2, spi=spi_2, si=si_2, sap=sap_2, vpn=vpn_2, ttl=63, scope=1,
			vlan_en=False,e_en=True,vn_en=False,
			sf_bitmask=sf_bitmask_2, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_2, si_exp=si_2, sap_exp=sap_2, vpn_exp=vpn_2
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_2,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_2,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_2, eth_dst=dmac_2, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_2, NSI=si_2-(popcount(sf_bitmask_2)), TTL=63, \
				NPC=((2<<24)|(sap_2)), \
				NSC=((vpn_2<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {t, f} {t, f} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(exp_pkt)
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_2)
		testutils.send_packet(self, ig_port_2, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_2)
		testutils.verify_packets(self, exp_pkt, [eg_port_2])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)



		# ----------------------------------------------------------------------------------------------------
		# {true,  false}         {true,  true }          --> vn + vlan enabled  vn in pkt        --> vn   to eth : case 1
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_3, smac_nsh=smac_3, spi=spi_3, si=si_3, sap=sap_3, vpn=vpn_3, ttl=63, scope=1,
			vlan_en=False,e_en=True,vn_en=False,
			sf_bitmask=sf_bitmask_3, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_3, si_exp=si_3, sap_exp=sap_3, vpn_exp=vpn_3
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_3,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_3,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_3, eth_dst=dmac_3, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_3, NSI=si_3-(popcount(sf_bitmask_3)), TTL=63, \
				NPC=((2<<24)|(sap_3)), \
				NSC=((vpn_3<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {t, f} {t, t} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(exp_pkt)
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_3)
		testutils.send_packet(self, ig_port_3, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_3)
		testutils.verify_packets(self, exp_pkt, [eg_port_3])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)





		# -----------------------------------------------------------
		# {true,  true }         {false, false}          --> nothing   enabled, vn + vlan in pkt --> no action
		# -----------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=True,e_en=True,vn_en=False,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vn_en_exp=False,e_en_exp=True,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)

		'''
#		base_pkt = simple_tcp_packet2(eth_dst=dmac,tcp_sport=0,  tcp_dport=0,dl_vlan_enable=1)
		base_pkt = simple_udp_packet2(eth_dst=dmac,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

#		base_pkt_exp = testutils.simple_udp_packet(eth_dst=dmac,udp_sport=443,udp_dport=0,pktlen=100-4) # subtract 4, since tag will be stripped
		base_pkt_exp = simple_udp_packet2(eth_dst=dmac,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi, NSI=si-(popcount(sf_bitmask)), TTL=63, \
				NPC=((2<<24)|(sap)), \
				NSC=((vpn<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {t, t} {f, f} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)


		# ----------------------------------------------------------------------------------------------------
		#  {true,  true }         {false, true }          --> vlan      enabled, vn + vlan in pkt --> vlan to VN  : case 2
		# ----------------------------------------------------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=True,e_en=True,vn_en=False,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=True,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_1,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_1,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_1, eth_dst=dmac_1, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_1, NSI=si_1-(popcount(sf_bitmask_1)), TTL=63, \
				NPC=((2<<24)|(sap_1)), \
				NSC=((vpn_1<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {t, t} {f, t} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(exp_pkt)
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_1)
		testutils.send_packet(self, ig_port_1, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_1)
		testutils.verify_packets(self, exp_pkt, [eg_port_1])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)





		# ----------------------------------------------------------------------------------------------------
		# {true,  true }         {true,  false}          --> vn        enabled, vn + vlan in pkt --> vn   to eth : case 3
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_2, smac_nsh=smac_2, spi=spi_2, si=si_2, sap=sap_2, vpn=vpn_2, ttl=63, scope=1,
			vlan_en=True,e_en=True,vn_en=False,
			sf_bitmask=sf_bitmask_2, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_2, si_exp=si_2, sap_exp=sap_2, vpn_exp=vpn_2
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_2,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_2,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_2, eth_dst=dmac_2, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_2, NSI=si_2-(popcount(sf_bitmask_2)), TTL=63, \
				NPC=((2<<24)|(sap_2)), \
				NSC=((vpn_2<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {t, t} {t, f} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(exp_pkt)
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_2)
		testutils.send_packet(self, ig_port_2, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_2)
		testutils.verify_packets(self, exp_pkt, [eg_port_2])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)



		# ----------------------------------------------------------------------------------------------------
		# {true,  true }         {true,  true }          --> vn + vlan enabled, vn + vlan in pkt --> vlan to eth : case 4 (double delete case)
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_3, smac_nsh=smac_3, spi=spi_3, si=si_3, sap=sap_3, vpn=vpn_3, ttl=63, scope=1,
			vlan_en=True,e_en=True,vn_en=False,
			sf_bitmask=sf_bitmask_3, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_3, si_exp=si_3, sap_exp=sap_3, vpn_exp=vpn_3
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_3,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_3,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_3, eth_dst=dmac_3, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_3, NSI=si_3-(popcount(sf_bitmask_3)), TTL=63, \
				NPC=((2<<24)|(sap_3)), \
				NSC=((vpn_3<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {t, t} {t, t} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_3)
		testutils.send_packet(self, ig_port_3, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_3)
		testutils.verify_packets(self, exp_pkt, [eg_port_3])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)




		npb_npb_sf2_policy_l2_del    (self, self.target, dsap=dsap_1, l2_etype=0x0800, l2_etype_mask=0xffff)
		npb_npb_sf2_policy_l2_del    (self, self.target, dsap=dsap_2, l2_etype=0x0800, l2_etype_mask=0xffff)
		npb_npb_sf2_policy_l2_del    (self, self.target, dsap=dsap_3, l2_etype=0x0800, l2_etype_mask=0xffff)



                # VN Testing


		npb_npb_sf2_policy_l2_add    (self, self.target, dsap=dsap_1, l2_etype=0x0800, l2_etype_mask=0xffff, strip_tag_vn=False, strip_tag_vlan=True)
		npb_npb_sf2_policy_l2_add    (self, self.target, dsap=dsap_2, l2_etype=0x0800, l2_etype_mask=0xffff, strip_tag_vn=True, strip_tag_vlan=False)
		npb_npb_sf2_policy_l2_add    (self, self.target, dsap=dsap_3, l2_etype=0x0800, l2_etype_mask=0xffff, strip_tag_vn=True, strip_tag_vlan=True)





		# ----------------------------------------------------------------------------------------------------
		# {false, false}         {false, false}          --> nothing   enabled, nothing in pkt   --> no action
		# ----------------------------------------------------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=False,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi, NSI=si-(popcount(sf_bitmask)), TTL=63, \
				NPC=((2<<24)|(sap)), \
				NSC=((vpn<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {f, f} {f, f} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)




		# ----------------------------------------------------------------------------------------------------
		# {false, false}         {false, true }          --> vlan      enabled, nothing in pkt   --> no action
		# ----------------------------------------------------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=False,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_1,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_1,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_1, eth_dst=dmac_1, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_1, NSI=si_1-(popcount(sf_bitmask_1)), TTL=63, \
				NPC=((2<<24)|(sap_1)), \
				NSC=((vpn_1<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {f, f} {f, t} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_1)
		testutils.send_packet(self, ig_port_1, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_1)
		testutils.verify_packets(self, exp_pkt, [eg_port_1])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)


		# ----------------------------------------------------------------------------------------------------
		# {false, false}         {true,  false}          --> vn        enabled, nothing in pkt   --> no action
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_2, smac_nsh=smac_2, spi=spi_2, si=si_2, sap=sap_2, vpn=vpn_2, ttl=63, scope=1,
			vlan_en=False,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask_2, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_2, si_exp=si_2, sap_exp=sap_2, vpn_exp=vpn_2
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_2,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_2,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_2, eth_dst=dmac_2, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_2, NSI=si_2-(popcount(sf_bitmask_2)), TTL=63, \
				NPC=((2<<24)|(sap_2)), \
				NSC=((vpn_2<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {f, f} {t, f} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_2)
		testutils.send_packet(self, ig_port_2, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_2)
		testutils.verify_packets(self, exp_pkt, [eg_port_2])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)





		# ----------------------------------------------------------------------------------------------------
		# {false, false}         {true,  true }          --> vn + vlan enabled, nothing in pkt   --> no action
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_3, smac_nsh=smac_3, spi=spi_3, si=si_3, sap=sap_3, vpn=vpn_3, ttl=63, scope=1,
			vlan_en=False,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask_3, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_3, si_exp=si_3, sap_exp=sap_3, vpn_exp=vpn_3
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_3,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_3,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_3, eth_dst=dmac_3, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_3, NSI=si_3-(popcount(sf_bitmask_3)), TTL=63, \
				NPC=((2<<24)|(sap_3)), \
				NSC=((vpn_3<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {f, f} {t, t} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_3)
		testutils.send_packet(self, ig_port_3, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_3)
		testutils.verify_packets(self, exp_pkt, [eg_port_3])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)



		# ----------------------------------------------------------------------------------------------------
		# {false, true }         {false, false}          --> nothing   enabled, vlan in pkt      --> no action
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=True,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi, NSI=si-(popcount(sf_bitmask)), TTL=63, \
				NPC=((2<<24)|(sap)), \
				NSC=((vpn<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {f, t} {f, f} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)





		# ----------------------------------------------------------------------------------------------------
		# {false, true }         {false, true }          --> vlan      enabled, vlan in pkt      --> vlan to eth : case 0
		# ----------------------------------------------------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=True,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_1,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_1,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_1, eth_dst=dmac_1, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_1, NSI=si_1-(popcount(sf_bitmask_1)), TTL=63, \
				NPC=((2<<24)|(sap_1)), \
				NSC=((vpn_1<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {f, t} {f, t} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_1)
		testutils.send_packet(self, ig_port_1, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_1)
		testutils.verify_packets(self, exp_pkt, [eg_port_1])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)





		# ----------------------------------------------------------------------------------------------------
		# {false, true }         {true,  false}          --> vn        enabled, vlan in pkt      --> no action
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_2, smac_nsh=smac_2, spi=spi_2, si=si_2, sap=sap_2, vpn=vpn_2, ttl=63, scope=1,
			vlan_en=True,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask_2, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_2, si_exp=si_2, sap_exp=sap_2, vpn_exp=vpn_2
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_2,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_2,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_2, eth_dst=dmac_2, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_2, NSI=si_2-(popcount(sf_bitmask_2)), TTL=63, \
				NPC=((2<<24)|(sap_2)), \
				NSC=((vpn_2<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {f, t} {t, f} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_2)
		testutils.send_packet(self, ig_port_2, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_2)
		testutils.verify_packets(self, exp_pkt, [eg_port_2])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)



		# ----------------------------------------------------------------------------------------------------
		# {false, true }         {true,  true }          --> vn + vlan enabled, vlan in pkt      --> vlan to eth : case 0
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_3, smac_nsh=smac_3, spi=spi_3, si=si_3, sap=sap_3, vpn=vpn_3, ttl=63, scope=1,
			vlan_en=True,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask_3, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_3, si_exp=si_3, sap_exp=sap_3, vpn_exp=vpn_3
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_3,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_3,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_3, eth_dst=dmac_3, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_3, NSI=si_3-(popcount(sf_bitmask_3)), TTL=63, \
				NPC=((2<<24)|(sap_3)), \
				NSC=((vpn_3<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {f, t} {t, t} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_3)
		testutils.send_packet(self, ig_port_3, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_3)
		testutils.verify_packets(self, exp_pkt, [eg_port_3])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)






		# -----------------------------------------------------------
		# {true, false}         {false, false}          --> nothing   enabled, nothing in pkt   --> no action
		# -----------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=False,e_en=False,vn_en=True,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=True,e_en_exp=False,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)

		'''
#		base_pkt = simple_tcp_packet2(eth_dst=dmac,tcp_sport=0,  tcp_dport=0,dl_vlan_enable=1)
		base_pkt = simple_udp_packet2(eth_dst=dmac,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

#		base_pkt_exp = testutils.simple_udp_packet(eth_dst=dmac,udp_sport=443,udp_dport=0,pktlen=100-4) # subtract 4, since tag will be stripped
		base_pkt_exp = simple_udp_packet2(eth_dst=dmac,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi, NSI=si-(popcount(sf_bitmask)), TTL=63, \
				NPC=((2<<24)|(sap)), \
				NSC=((vpn<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {t, f} {f, f} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)


		# ----------------------------------------------------------------------------------------------------
		#  {true,  false}         {false, true }          --> vlan      enabled, vn in pkt        --> no action
		# ----------------------------------------------------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=False,e_en=False,vn_en=True,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=True,e_en_exp=False,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_1,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_1,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_1, eth_dst=dmac_1, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_1, NSI=si_1-(popcount(sf_bitmask_1)), TTL=63, \
				NPC=((2<<24)|(sap_1)), \
				NSC=((vpn_1<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {t, f} {f, t} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_1)
		testutils.send_packet(self, ig_port_1, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_1)
		testutils.verify_packets(self, exp_pkt, [eg_port_1])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)





		# ----------------------------------------------------------------------------------------------------
		# {true,  false}         {true,  false}          --> vn        enabled, vn in pkt        --> vn   to eth : case 1
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_2, smac_nsh=smac_2, spi=spi_2, si=si_2, sap=sap_2, vpn=vpn_2, ttl=63, scope=1,
			vlan_en=False,e_en=False,vn_en=True,
			sf_bitmask=sf_bitmask_2, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_2, si_exp=si_2, sap_exp=sap_2, vpn_exp=vpn_2
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_2,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_2,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_2, eth_dst=dmac_2, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_2, NSI=si_2-(popcount(sf_bitmask_2)), TTL=63, \
				NPC=((2<<24)|(sap_2)), \
				NSC=((vpn_2<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {t, f} {t, f} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_2)
		testutils.send_packet(self, ig_port_2, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_2)
		testutils.verify_packets(self, exp_pkt, [eg_port_2])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)



		# ----------------------------------------------------------------------------------------------------
		# {true,  false}         {true,  true }          --> vn + vlan enabled  vn in pkt        --> vn   to eth : case 1
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_3, smac_nsh=smac_3, spi=spi_3, si=si_3, sap=sap_3, vpn=vpn_3, ttl=63, scope=1,
			vlan_en=False,e_en=False,vn_en=True,
			sf_bitmask=sf_bitmask_3, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_3, si_exp=si_3, sap_exp=sap_3, vpn_exp=vpn_3
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_3,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_3,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_3, eth_dst=dmac_3, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_3, NSI=si_3-(popcount(sf_bitmask_3)), TTL=63, \
				NPC=((2<<24)|(sap_3)), \
				NSC=((vpn_3<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {t, f} {t, t} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_3)
		testutils.send_packet(self, ig_port_3, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_3)
		testutils.verify_packets(self, exp_pkt, [eg_port_3])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)





		# -----------------------------------------------------------
		# {true,  true }         {false, false}          --> nothing   enabled, vn + vlan in pkt --> no action
		# -----------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=True,e_en=False,vn_en=True,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vn_en_exp=True,e_en_exp=False,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)

		'''
#		base_pkt = simple_tcp_packet2(eth_dst=dmac,tcp_sport=0,  tcp_dport=0,dl_vlan_enable=1)
		base_pkt = simple_udp_packet2(eth_dst=dmac,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

#		base_pkt_exp = testutils.simple_udp_packet(eth_dst=dmac,udp_sport=443,udp_dport=0,pktlen=100-4) # subtract 4, since tag will be stripped
		base_pkt_exp = simple_udp_packet2(eth_dst=dmac,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi, NSI=si-(popcount(sf_bitmask)), TTL=63, \
				NPC=((2<<24)|(sap)), \
				NSC=((vpn<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {t, t} {f, f} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)


		# ----------------------------------------------------------------------------------------------------
		#  {true,  true }         {false, true }          --> vlan      enabled, vn + vlan in pkt --> vlan to VN  : case 2
		# ----------------------------------------------------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=True,e_en=False,vn_en=True,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=True,e_en_exp=False,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_1,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_1,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_1, eth_dst=dmac_1, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_1, NSI=si_1-(popcount(sf_bitmask_1)), TTL=63, \
				NPC=((2<<24)|(sap_1)), \
				NSC=((vpn_1<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {t, t} {f, t} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_1)
		testutils.send_packet(self, ig_port_1, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_1)
		testutils.verify_packets(self, exp_pkt, [eg_port_1])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)





		# ----------------------------------------------------------------------------------------------------
		# {true,  true }         {true,  false}          --> vn        enabled, vn + vlan in pkt --> vn   to eth : case 3
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_2, smac_nsh=smac_2, spi=spi_2, si=si_2, sap=sap_2, vpn=vpn_2, ttl=63, scope=1,
			vlan_en=True,e_en=False,vn_en=True,
			sf_bitmask=sf_bitmask_2, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_2, si_exp=si_2, sap_exp=sap_2, vpn_exp=vpn_2
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_2,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_2,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_2, eth_dst=dmac_2, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_2, NSI=si_2-(popcount(sf_bitmask_2)), TTL=63, \
				NPC=((2<<24)|(sap_2)), \
				NSC=((vpn_2<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {t, t} {t, f} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(exp_pkt)
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_2)
		testutils.send_packet(self, ig_port_2, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_2)
		testutils.verify_packets(self, exp_pkt, [eg_port_2])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)



		# ----------------------------------------------------------------------------------------------------
		# {true,  true }         {true,  true }          --> vn + vlan enabled, vn + vlan in pkt --> vlan to eth : case 4 (double delete case)
		# ----------------------------------------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_3, smac_nsh=smac_3, spi=spi_3, si=si_3, sap=sap_3, vpn=vpn_3, ttl=63, scope=1,
			vlan_en=True,e_en=False,vn_en=True,
			sf_bitmask=sf_bitmask_3, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_3, si_exp=si_3, sap_exp=sap_3, vpn_exp=vpn_3
		)

		'''
		base_pkt = simple_udp_packet2(eth_dst=dmac_3,udp_sport=443,udp_dport=0,dl_vlan_enable=1)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))


		# -----------------

		base_pkt_exp = simple_udp_packet2(eth_dst=dmac_3,udp_sport=443,udp_dport=0,dl_vlan_enable=0,pktlen=100-4) # subtract 4, since tag will be stripped

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac_3, eth_dst=dmac_3, eth_type=0x894f) / \
			scapy.NSH(MDType=1, NextProto=3, NSP=spi_3, NSI=si_3-(popcount(sf_bitmask_3)), TTL=63, \
				NPC=((2<<24)|(sap_3)), \
				NSC=((vpn_3<<16)|(0)), \
				SPC=0, \
				SSC=0, \
			) / \
			base_pkt_exp
		print(type(exp_pkt))
		'''

		print("---------- Debug {t, t} {t, t} ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_3)
		testutils.send_packet(self, ig_port_3, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_3)
		testutils.verify_packets(self, exp_pkt, [eg_port_3])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)





		# -----------------------------------------------------------
		# Delete Table Entries
		# -----------------------------------------------------------

		npb_nsh_chain_start_end_del(self, self.target,
			#ingress
			[ig_port], ig_lag_ptr, spi, si, sf_bitmask, rmac, nexthop_ptr, eg_lag_ptr, 0, 0, [eg_port]
			#tunnel
			#tunnel_encap_ptr, tunnel_encap_nexthop_ptr, tunnel_encap_bd, tunnel_encap_smac_ptr
			#egress
		)
		npb_nsh_chain_start_end_del(self, self.target,
			#ingress
			[ig_port_1], ig_lag_ptr_1, spi_1, si_1, sf_bitmask_1, rmac, nexthop_ptr_1, eg_lag_ptr_1, 1, 1, [eg_port_1],
			#tunnel
			#tunnel_encap_ptr_1, tunnel_encap_nexthop_ptr_1, tunnel_encap_bd_1, tunnel_encap_smac_ptr_1
			#egress
		)
		npb_nsh_chain_start_end_del(self, self.target,
			#ingress
			[ig_port_2], ig_lag_ptr_2, spi_2, si_2, sf_bitmask_2, rmac, nexthop_ptr_2, eg_lag_ptr_2, 2, 2, [eg_port_2],
			#tunnel
			#tunnel_encap_ptr_2, tunnel_encap_nexthop_ptr_2, tunnel_encap_bd_2, tunnel_encap_smac_ptr_2
			#egress
		)
		npb_nsh_chain_start_end_del(self, self.target,
			#ingress
			[ig_port_3], ig_lag_ptr_3, spi_3, si_3, sf_bitmask_3, rmac, nexthop_ptr_3, eg_lag_ptr_3, 3, 3, [eg_port_3],
			#tunnel
			#tunnel_encap_ptr_3, tunnel_encap_nexthop_ptr_3, tunnel_encap_bd_3, tunnel_encap_smac_ptr_3
			#egress
		)

		# -----------------
		# Egress SF(s)
		# -----------------

		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap, l2_etype=0x0800, l2_etype_mask=0xffff)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_1, l2_etype=0x0800, l2_etype_mask=0xffff)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_2, l2_etype=0x0800, l2_etype_mask=0xffff)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_3, l2_etype=0x0800, l2_etype_mask=0xffff)


