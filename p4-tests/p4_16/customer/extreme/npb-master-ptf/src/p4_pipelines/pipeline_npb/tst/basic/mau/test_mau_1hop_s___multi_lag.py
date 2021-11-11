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

		ig_port_0  = swports[1]
		ig_port_1  = swports[2]
		ig_port_2  = swports[3]
		eg_port_0 = swports[1]
		eg_port_1 = swports[2]
		eg_port_2 = swports[3]
		eg_port_3 = swports[3] # derek changed from [4] so that this test can run on the hw, which only has 4 cpu ports total.

		# -----------------------
		# Packet values to use
		# -----------------------

		smac = '11:11:11:11:11:11'
		dmac = '22:22:22:22:22:22'
		smac1 = '11:11:11:11:11:33'
		dmac1 = '22:22:22:22:22:44'
		smac2 = '11:11:11:11:11:55'
		dmac2 = '22:22:22:22:22:66'
		sip = "0.0.0.3"
		dip = "0.0.0.4"
		sip1 = "0.0.1.3"
		dip1 = "0.0.1.4"

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
		vid                     = 0 # Arbitrary value
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
		
		npb_nsh_chain_start_add(self, self.target,
			#ingress
			[ig_port_1], ig_lag_ptr, 0, sap, vpn, spi, si, sf_bitmask, rmac, nexthop_ptr, bd, eg_lag_ptr, 0, 0, [eg_port_1, eg_port_2], False, 0, dsap,
			#tunnel
			tunnel_encap_ptr, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr, tunnel_encap_bd, dmac, tunnel_encap_smac_ptr, smac
			#egress
		)
		
		npb_nsh_chain_start_add(self, self.target,
			#ingress
			[ig_port_0], ig_lag_ptr+1, 0, sap+1, vpn+1, spi+1, si+1, sf_bitmask, rmac, nexthop_ptr+1, bd+1, eg_lag_ptr+3, 3, 3, [eg_port_0], False, 0, dsap,
			#tunnel
			tunnel_encap_ptr+1, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr+1, tunnel_encap_bd+1, dmac, tunnel_encap_smac_ptr+1, smac
			#egress
		)
#		npb_tunnel_network_dst_vtep_add(self, self.target, l3_src=sip, l3_src_mask=0xffffffff, l3_dst=dip, l3_dst_mask=0xffffffff, tun_type=IngressTunnelType.VXLAN.value,   tun_type_mask=0xf, sap=sap+1, vpn=vpn+1, port_lag_ptr=ig_lag_ptr+1, drop=0)
		npb_npb_sf0_policy_l34_v6_add(self, self.target, sap=sap, l3_proto=17, l3_proto_mask=0xff, flow_class=flow_class_acl, sfc_enable=1, sfc=sfc)
		npb_npb_sfp_sel_add(self, self.target, vpn, flow_class_sfp, sfc, 0, 0, [spi+1], [si+1], [sf_bitmask])

		npb_nsh_bridge_no_eg_lag_add(self, self.target, 
#		npb_nsh_bridge_add(self, self.target, 
			#ingress
			[ig_port_2], ig_lag_ptr+2, rmac,  nexthop_ptr, bd, 0x0800, 0xffff, 0, 0x1, vid, 0xfff, dmac, 0xffffffffffff, eg_lag_ptr, 0, 0, [eg_port_1, eg_port_2]
			#egress
		)

		# -----------------

#		time.sleep(1)

		# -----------------------------------------------------------
		# Create / Send / Verfiy the packet
		# -----------------------------------------------------------
		
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_1)
		testutils.send_packet(self, ig_port_1, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d or %d", eg_port_1, eg_port_2)
		testutils.verify_packets_any(self, exp_pkt, [eg_port_1, eg_port_2])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)
		


		src_pkt, exp_pkt = npb_simple_1lyr_udpv6(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			spi_exp=spi+1, si_exp=si+1, sap_exp=sap, vpn_exp=vpn
		)
#		src_pkt, exp_pkt = npb_simple_2lyr_vxlan_udp(
#			dmac_nsh=dmac1, smac_nsh=smac1, spi=spi+1, si=si+1, sap=sap+1, vpn=vpn+1, ttl=63, scope=1,
#			dmac=dmac, smac=smac,
#			transport_decap=True, sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[],
#			spi_exp=spi+1, si_exp=si+1, sap_exp=sap, vpn_exp=vpn
#		)

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_1)
		testutils.send_packet(self, ig_port_1, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		# -----------------------------------------------------------
		
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, ta=ta, nshtype=2, sap=sap, vpn=vpn, ttl=63, scope=1,
			dmac=dmac, smac=smac,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=True, scope_term_list=[], bridged_pkt=True,
			spi_exp=spi, si_exp=si, ta_exp=ta, nshtype_exp=2, sap_exp=sap, vpn_exp=vpn
		)

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_2)
		testutils.send_packet(self, ig_port_2, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d or %d", eg_port_1, eg_port_2)
		testutils.verify_packets_any(self, exp_pkt, [eg_port_1, eg_port_2])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)
		
		# -----------------------------------------------------------
		# Delete Table Entries
		# -----------------------------------------------------------

		npb_nsh_chain_start_del(self, self.target,
			#ingress
			[ig_port_1], ig_lag_ptr, spi, si, sf_bitmask, rmac, nexthop_ptr, eg_lag_ptr, 0, 0, [eg_port_1, eg_port_2],
			#tunnel
			tunnel_encap_ptr, tunnel_encap_nexthop_ptr, tunnel_encap_bd, tunnel_encap_smac_ptr
			#egress
		)
		
		npb_nsh_chain_start_del(self, self.target,
			#ingress
			[ig_port_0], ig_lag_ptr+1, spi+1, si+1, sf_bitmask, rmac, nexthop_ptr+1, eg_lag_ptr+3, 3, 3, [eg_port_0],
			#tunnel
			tunnel_encap_ptr+1, tunnel_encap_nexthop_ptr+1, tunnel_encap_bd+1, tunnel_encap_smac_ptr+1
			#egress
		)
#		npb_tunnel_network_dst_vtep_del(self, self.target, l3_src=sip, l3_src_mask=0xffffffff, l3_dst=dip, l3_dst_mask=0xffffffff, tun_type=IngressTunnelType.VXLAN.value,   tun_type_mask=0xf)
		npb_npb_sfp_sel_del(self, self.target, vpn, sfc, 0, 0, [spi+1], [si+1])
		npb_npb_sf0_policy_l34_v6_del(self, self.target, sap=sap, l3_proto=17, l3_proto_mask=0xff)

		npb_nsh_bridge_no_eg_lag_del(self, self.target,
#		npb_nsh_bridge_del(self, self.target,
			#ingress
			[ig_port_2], ig_lag_ptr+2, rmac, nexthop_ptr, 0x0800, 0xffff, 0, 0x1, vid, 0xfff, dmac, 0xffffffffffff, eg_lag_ptr, 0, 0, [eg_port_1, eg_port_2]
			#egress
		)
