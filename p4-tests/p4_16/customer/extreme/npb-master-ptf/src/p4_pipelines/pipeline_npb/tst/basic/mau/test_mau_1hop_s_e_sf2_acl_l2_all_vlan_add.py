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
# =====================
# Packet               
# {e/vn,  vl[0], vl[1]}
# =====================
# {false, false, false}   --> empty,      disabled --> no action
# {false, false, false}   --> empty,      enabled  --> eth  to vlan : case 0
# {false, false, true }   --> impossible, disabled --> no action
# {false, false, true }   --> impossible, enabled  --> no action
# ---------------------
# {false, true,  false}   --> one full,   disabled --> no action
# {false, true,  false}   --> one full,   enabled  --> eth  to vlan : case 1
# {false, true,  true }   --> both full,  disabled --> no action
# {false, true,  true }   --> both full,  enabled  --> no action
# ---------------------
# {true,  false, false}   --> empty,      disabled --> no action
# {true,  false, false}   --> empty,      enabled  --> e/vn to vlan : case 2
# {true,  false, true }   --> impossible, disabled --> no action
# {true,  false, true }   --> impossible, enabled  --> no action
# ---------------------
# {true,  true,  false}   --> one full,   disabled --> no action
# {true,  true,  false}   --> one full,   enabled  --> e/vn to vlan : case 3
# {true,  true,  true }   --> both full,  disabled --> no action
# {true,  true,  true }   --> both full,  enabled  --> no action


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
		# Port 0 - Enable Add_vlan
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

		npb_nsh_chain_start_end_add(self, self.target,
			#ingress
			[ig_port], ig_lag_ptr, 0, sap, vpn, spi, si, sf_bitmask, rmac, nexthop_ptr, bd, eg_lag_ptr, 0, 0, [eg_port], False, 0, dsap
			#tunnel
			#tunnel_encap_ptr, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr, tunnel_encap_bd, dmac, tunnel_encap_smac_ptr, smac
			#egress
		)
		# -----------------------
		# Port 1 Disable Add Vlan
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


		# -----------------
		# Egress SF(s)
		# -----------------
		npb_npb_sf2_policy_l2_add    (self, self.target, dsap=dsap,  l2_etype=0x0800, l2_etype_mask=0xffff, add_tag_vlan_bd=5)
		npb_npb_sf2_policy_l2_add    (self, self.target, dsap=dsap_1, l2_etype=0x0800, l2_etype_mask=0xffff, add_tag_vlan_bd=0) #By not setting the hdr_edit to Set_vlan_tagged, the default action is No Action
		npb_npb_sf2_policy_hdr_edit_add(self, self.target, bd=5, pcp=0, vid=000)

#		npb_npb_sf2_policy_l2_add    (self, self.target, dsap=dsap,   l2_etype=0x0800, l2_etype_mask=0xffff, strip_tag_e=False, strip_tag_vlan=False)
#		npb_npb_sf2_policy_l2_add    (self, self.target, dsap=dsap_1, l2_etype=0x0800, l2_etype_mask=0xffff, strip_tag_e=False, strip_tag_vlan=True)
#		npb_npb_sf2_policy_l2_add    (self, self.target, dsap=dsap_2, l2_etype=0x0800, l2_etype_mask=0xffff, strip_tag_e=True, strip_tag_vlan=False)
#		npb_npb_sf2_policy_l2_add    (self, self.target, dsap=dsap_3, l2_etype=0x0800, l2_etype_mask=0xffff, strip_tag_e=True, strip_tag_vlan=True)


		# -----------------

#		time.sleep(1)

                #No Tag


		#E-Tag
		# ----------------------------------------------------------------------
		# {false, false, false}   --> empty,      disabled --> no action
		# ----------------------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=False,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)


		print("---------- Debug (f, f, f} Disabled ----------")
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

		# ----------------------------------------------------------------------
		# {false, false, false}   --> empty,      enabled  --> eth  to vlan : case 0
		# ----------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=False,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)


		print("---------- Debug (f, f, f} Enabled ----------")
#		print(testutils.format_packet(src_pkt))
#		print(exp_pkt)
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)



		# ----------------------------------------------------------------------
		# {false, false, true }   --> impossible, disabled --> no action
		# ----------------------------------------------------------------------
		# ----------------------------------------------------------------------
		# {false, false, true }   --> impossible, enabled  --> no action
		# ----------------------------------------------------------------------


		# ----------------------------------------------------------------------
		# {false, true,  false}   --> one full,   disabled --> no action
		# ----------------------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=True,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)


		print("---------- Debug (f, t, f} Disabled ----------")
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




		# ----------------------------------------------------------------------
		# {false, true,  false}   --> one full,   enabled  --> eth  to vlan : case 1
		# ----------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=True,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vlan2_en_exp=True,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)


		print("---------- Debug (f, t, f} Enabled ----------")
#		print(testutils.format_packet(src_pkt))
#		print(exp_pkt)
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)



		# ----------------------------------------------------------------------
		# {false, true,  true }   --> both full,  disabled --> no action
		# ----------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=True,vlan2_en=True,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vlan2_en_exp=True,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)


		print("---------- Debug (f, t, t} Disabled ----------")
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



		# ----------------------------------------------------------------------
		# {false, true,  true }   --> both full,  enabled  --> no action
		# ----------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=True,vlan2_en=True,e_en=False,vn_en=False,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vlan2_en_exp=True,vn_en_exp=False,e_en_exp=False,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)


		print("---------- Debug (f, t, t} Enabled ----------")
#		print(testutils.format_packet(src_pkt))
#		print(exp_pkt)
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)




		# ----------------------------------------------------------------------
		# {true,  false, false}   --> empty,      disabled --> no action
		# ----------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=False,vlan2_en=False,e_en=True,vn_en=False,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vlan2_en_exp=False,vn_en_exp=False,e_en_exp=True,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)


		print("---------- Debug (t(e), f, f} Disabled ----------")
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
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=False,vlan2_en=False,e_en=False,vn_en=True,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=False,vlan2_en_exp=False,vn_en_exp=True,e_en_exp=False,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)


		print("---------- Debug (t(vn), f, f} Disabled ----------")
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
		# ----------------------------------------------------------------------
		# {true,  false, false}   --> empty,      enabled  --> e/vn to vlan : case 2
		# ----------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=False,vlan2_en=False,e_en=True,vn_en=False,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vlan2_en_exp=False,vn_en_exp=False,e_en_exp=True,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)


		print("---------- Debug (t(e), f, f} Enabled ----------")
#		print(testutils.format_packet(src_pkt))
#		print(exp_pkt)
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=False,vlan2_en=False,e_en=False,vn_en=True,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vlan2_en_exp=False,vn_en_exp=True,e_en_exp=False,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)


		print("---------- Debug (t(vn), f, f} Enabled ----------")
#		print(testutils.format_packet(src_pkt))
#		print(exp_pkt)
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		# ----------------------------------------------------------------------
# {true,  false, true }   --> impossible, disabled --> no action
		# ----------------------------------------------------------------------
		# ----------------------------------------------------------------------
# {true,  false, true }   --> impossible, enabled  --> no action
		# ----------------------------------------------------------------------

		# ----------------------------------------------------------------------
		# {true,  true,  false}   --> one full,   disabled --> no action
		# ----------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=True,vlan2_en=False,e_en=True,vn_en=False,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vlan2_en_exp=False,vn_en_exp=False,e_en_exp=True,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)


		print("---------- Debug (t(e), t, f} Disabled ----------")
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
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=True,vlan2_en=False,e_en=False,vn_en=True,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vlan2_en_exp=False,vn_en_exp=True,e_en_exp=False,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)


		print("---------- Debug (t(vn), t, f} Disabled ----------")
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

		# ----------------------------------------------------------------------
		# {true,  true,  false}   --> one full,   enabled  --> e/vn to vlan : case 3
		# ----------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=True,vlan2_en=False,e_en=True,vn_en=False,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vlan2_en_exp=True,vn_en_exp=False,e_en_exp=True,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)


		print("---------- Debug (t(e), t, f} Enabled ----------")
#		print(testutils.format_packet(src_pkt))
#		print(exp_pkt)
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=True,vlan2_en=False,e_en=False,vn_en=True,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vlan2_en_exp=True,vn_en_exp=True,e_en_exp=False,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)


		print("---------- Debug (t(vn), t, f} Enabled ----------")
#		print(testutils.format_packet(src_pkt))
#		print(exp_pkt)
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		# ----------------------------------------------------------------------
		# {true,  true,  true }   --> both full,  disabled --> no action
		# ----------------------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=True,vlan2_en=True,e_en=True,vn_en=False,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vlan2_en_exp=True,vn_en_exp=False,e_en_exp=True,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)


		print("---------- Debug (t, t, t} Disabled ----------")
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

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_1, smac_nsh=smac_1, spi=spi_1, si=si_1, sap=sap_1, vpn=vpn_1, ttl=63, scope=1,
			vlan_en=True,vlan2_en=True,e_en=False,vn_en=True,
			sf_bitmask=sf_bitmask_1, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vlan2_en_exp=True,vn_en_exp=True,e_en_exp=False,
			spi_exp=spi_1, si_exp=si_1, sap_exp=sap_1, vpn_exp=vpn_1
		)


		print("---------- Debug (t(vn), t, t} Disabled ----------")
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

		# ----------------------------------------------------------------------
		# {true,  true,  true }   --> both full,  enabled  --> no action
		# ----------------------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=True,vlan2_en=False,e_en=True,vn_en=False,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vlan2_en_exp=True,vn_en_exp=False,e_en_exp=True,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)


		print("---------- Debug (t(e), t, t} Enabled ----------")
#		print(testutils.format_packet(src_pkt))
#		print(exp_pkt)
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			vlan_en=True,vlan2_en=False,e_en=False,vn_en=True,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[],
			vlan_en_exp=True,vlan2_en_exp=True,vn_en_exp=True,e_en_exp=False,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)


		print("---------- Debug (t(vn), t, t} Enabled ----------")
#		print(testutils.format_packet(src_pkt))
#		print(exp_pkt)
		print("---------- Debug ----------")

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


		# -----------------
		# Egress SF(s)
		# -----------------

		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap, l2_etype=0x0800, l2_etype_mask=0xffff)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_1, l2_etype=0x0800, l2_etype_mask=0xffff)
		npb_npb_sf2_policy_hdr_edit_del(self, self.target, bd=5)
