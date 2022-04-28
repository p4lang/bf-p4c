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

			smac_nsh = '11:11:11:11:11:11'
			dmac_nsh = '22:22:22:22:22:22'
			sip_nsh = '192.168.0.7'
			dip_nsh = '192.168.0.8'
			smac_t = smac_nsh #'44:44:44:44:44:44'
			dmac_t = dmac_nsh #'55:55:55:55:55:55'
			sip_t = sip_nsh #'192.168.0.1'
			dip_t = dip_nsh #'192.168.0.2'
			smac_outer = '66:66:66:66:66:66'
			dmac_outer = '77:77:77:77:77:77'
			sip_outer = '192.168.0.5'
			dip_outer = '192.168.0.6'


			rmac = dmac_nsh

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

			npb_nsh_chain_start_add(self, self.target,ig_pipe,
				#ingress
				[ig_port], ig_lag_ptr, 0, sap, vpn, spi, si, sf_bitmask, rmac, nexthop_ptr, bd, eg_lag_ptr, 0, 0, [eg_port], 0, 0, dsap,
				#tunnel
				tunnel_encap_ptr, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr, tunnel_encap_bd, dmac_nsh, tunnel_encap_smac_ptr, smac_nsh
				#egress
			)


			#Nood to Scope shift to inner or decap

			# -----------------
			# Ingress SF(s)
			# -----------------


			
			npb_tunnel_network_dst_vtep_add(self=self, target=self.target,ig_pipe=ig_pipe,
				l3_src=sip_t, l3_src_mask=0xffffffff, l3_dst=dip_t, l3_dst_mask=0xffffffff, 
				tun_type=IngressTunnelType.GRE.value,   tun_type_mask=0xf, 
				tun_id=0,                         tun_id_mask=0, 
				sap=sap, vpn=vpn+1, port_lag_ptr=ig_lag_ptr, drop=0)


			dmac_outer     = '00:01:02:03:04:05'
			smac_outer     = '00:06:07:08:09:0a'
			sip_outer      = '192.168.0.5'
			dip_outer      = '192.168.0.6'

			npb_tunnel_inner_sap_add(self, self.target,ig_pipe, sap=sap, 
							l3_type        = 0x1,       l3_type_mask        = 0x3,
							l3_proto       = 0x11,      l3_proto_mask       = 0x00,
							l3_sip         = sip_outer, l3_sip_mask         = 0xffffffff,
							l3_dip         = dip_outer, l3_dip_mask         = 0xffffffff,
							l4_src         = 0x4d2,       l4_src_mask      = 0xffff,
							l4_dst         = 0x12b5,       l4_dst_mask       = 0xffff,
							tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, 
							tun_id=0xABA,                              tun_id_mask=0xfff, 
							sap_new=sap, vpn=vpn+2, scope=1, terminate=0)

			dmac_inner     = '20:21:22:23:24:25'
			smac_inner     = '20:26:27:28:29:2a'
			sip_inner      = '192.168.0.1'#Default in pkt_gen
			dip_inner      = '192.168.0.2'#Default in pkt_gen


			npb_npb_sf0_policy_l2_add    (self, self.target,ig_pipe, sap=sap, vpn=vpn+2,
				l2_etype=0x0800, l2_etype_mask=0xffff, flow_class=flow_class_acl, 
				l2_sa=smac_outer, l2_sa_mask=0xffffffffffff,l2_da=dmac_outer, l2_da_mask=0xffffffffffff,
  				tun_type=IngressTunnelType.VXLAN.value,   tun_type_mask=0xf,
				#tun_id=0xABA,                              tun_id_mask=0xfff, 
				scope=0,
				trunc_enable=1, trunc=0x100)

			#Need to Add L3/4 policy and read counter for L2 ACL hit
			#IN IRDER FOR THIS TO GET A HIT I HAD TO ADD THE L3PROTO. PROTO with mask=0 caused a miss.
			npb_npb_sf0_policy_l34_v4_add(self, self.target,ig_pipe,
				sap=sap,vpn=vpn+2,vpn_mask=0xffff,
				l3_len         = 0, l3_len_mask = 0,
				l3_proto       = 0x6, l3_proto_mask       = 0xff,
				l3_sip         = sip_inner, l3_sip_mask         = 0xffffffff,
				l3_dip         = dip_inner, l3_dip_mask         = 0xffffffff,
				l4_src         = 0, l4_src_mask         = 0,
				l4_dst         = 0, l4_dst_mask         = 0,
  				tun_type=IngressTunnelType.VXLAN.value,   tun_type_mask=0xf,
				#tun_id       = 0, tun_id_mask       = 0,
				scope=0,
				trunc_enable=1, trunc=0x100
			)


			# -----------------

#			time.sleep(1)

			# -----------------------------------------------------------
			# Create / Send / Verify the packet
			# -----------------------------------------------------------

			
			#Transport-L2Tunnel-L3Tunnel Overload Outer L2 -> Inner, Overload Outer Tunnel -> Inner
			src_pkt, exp_pkt = npb_simple_3lyr_gre_vxlan(
				dmac_nsh=dmac_t, smac_nsh=smac_t, dip_nsh=dip_t, sip_nsh=sip_t, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
				dmac_outer=dmac_outer, smac_outer=smac_outer,sip_outer=sip_outer, dip_outer=dip_outer,
				pktlen=512,
				transport_decap=True,sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[0],
				pktlen_exp=0x100,
				spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn+2
			)

			#print("---------- Debug4 ----------")
			#print(testutils.format_packet(src_pkt))
			#print(exp_pkt)
			logger.info("Sending packet on port %d", ig_port)
			testutils.send_packet(self, ig_port, src_pkt)

			logger.info("Verify packet on port %d", eg_port)
			testutils.verify_packets(self, exp_pkt, [eg_port])
			

			# -----------------------------------------------------------
			# Delete Table Entries
			# -----------------------------------------------------------

			npb_nsh_chain_start_del(self, self.target,ig_pipe,
				#ingress
				[ig_port], ig_lag_ptr, spi, si, sf_bitmask, rmac, nexthop_ptr, eg_lag_ptr, 0, 0, [eg_port],
				#tunnel
				tunnel_encap_ptr, tunnel_encap_nexthop_ptr, tunnel_encap_bd, tunnel_encap_smac_ptr
				#egress
			)

			# -----------------
			# Ingress SF(s)
			# -----------------

			cleanUpGlobal(self)
