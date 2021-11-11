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

		ig_port_cpu= swports[0]
		eg_port_cpu= swports[0]

		ig_port_0 = swports[1]
		eg_port_0 = swports[1]

		# -----------------------
		# Port 0 DSAP_0 - Start SF2 COPY to CPU
		# -----------------------

		smac_0 = '11:11:00:11:11:11'
		dmac_0 = '22:22:00:22:22:22'
		sip_0 = "0.0.0.3"
		dip_0 = "0.0.0.4"
		smac_12 = '11:11:12:11:11:11'
		dmac_12 = '22:22:13:22:22:22'
		sip_12 = "0.0.0.12"
		dip_12 = "0.0.0.13"
		smac_13 = '11:11:14:11:11:11'
		dmac_13 = '22:22:15:22:22:22'
		sip_13 = "0.0.0.14"
		dip_13 = "0.0.0.15"

		rmac = '33:33:33:33:33:33'

		# -----------------------
		# NSH values to use
		# -----------------------

		sap_0                     = 8 # Arbitrary value
		vpn_0                     = 1 # Arbitrary value
		flow_class_acl_0          = 2 # Arbitrary value
		flow_class_sfp_0          = 3 # Arbitrary value
		ta_0                      = 3 # Arbitrary value
		spi_0                     = 4 # Arbitrary value
		si_0                      = 5 # Arbitrary value (ttl)
		sfc_0                     = 6 # Arbitrary value
		dsap_0                    = 7 # Arbitrary value
		dsap_12                   = 12 # Arbitrary value
		dsap_13                   = 13 # Arbitrary value

		sf_bitmask_0              = 1 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

		nexthop_ptr_0             = 14 # Arbitrary value
		vid_0                     = 0 # Arbitrary value
		bd_0                      = 1 # Arbitrary value
		ig_lag_ptr_0              = 2 # Arbitrary value
		eg_lag_ptr_0              = 3 # Arbitrary value
		tunnel_encap_ptr_0        = 4 # Arbitrary value
		tunnel_encap_nexthop_ptr_0= 5 # Arbitrary value
		tunnel_encap_bd_0         = 6 # Arbitrary value
		tunnel_encap_smac_ptr_0   = 7 # Arbitrary value
		
		npb_nsh_chain_start_add(self, self.target,
			#ingress
			[ig_port_0], ig_lag_ptr_0, 0, sap_0, vpn_0, spi_0, si_0, sf_bitmask_0, rmac, nexthop_ptr_0, bd_0, eg_lag_ptr_0, 0, 0, [eg_port_0], False, 0, dsap_0,
			#tunnel
			tunnel_encap_ptr_0, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr_0, tunnel_encap_bd_0, dmac_0, tunnel_encap_smac_ptr_0, smac_0
			#egress
		)
		
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_0, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, mirror_enable=1, mirror_id=250, cpu_reason_code=5)
		


		# -----------------------
		# Port 0 (2nd flow) End of Chain
		# -----------------------

		npb_nsh_chain_end_add(self, self.target,
			#ingress
			[ig_port_0], 99, 0, ta_0+100, spi_0+100, si_0+100, sf_bitmask_0, rmac, nexthop_ptr_0+100, bd_0+100, 99, 10, 10, [eg_port_0], False, 0, dsap_0
			#egress
		)
		
		# -----------------------
		# Port 0 (3rd flow) Middle of Chain Translate NSH
		# -----------------------

		npb_nsh_chain_middle_add(self, self.target,
			#ingress
			[ig_port_0], 99, 0, ta_0+101, spi_0+101, si_0+101, sf_bitmask_0, rmac, nexthop_ptr_0+101, bd_0+101, 99, 11, 11, [eg_port_0], False, 0, dsap_0,
			#tunnel
			tunnel_encap_ptr_0+101, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr_0+101, tunnel_encap_bd_0+101, rmac, tunnel_encap_smac_ptr_0+101, smac_0
			#egress
		)
		# -----------------------
		# Port 0  (4th flow) SFC inner Decap
		# -----------------------
		npb_tunnel_inner_sap_add(self, self.target, sap=sap_0, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, sap_new=16, vpn=17, terminate=1)


		# -----------------------
		# Port 0  (5th flow) SF0 L34 v4 drop port range
		# -----------------------
		npb_npb_sf0_len_rng_add(self, self.target, 0x2000, 0xffff, 1) # drop 0x2000 - 0x3000
		npb_npb_sf0_policy_l34_v4_add(self, self.target, sap=sap_0, l3_len_rng=0x0001, l3_len_rng_mask=0xffff, flow_class=flow_class_acl_0, drop=1) # drop


		npb_npb_sf0_l4_src_port_rng_add(self, self.target, 0x2000, 0x3000, 1) # drop 0x2000 - 0x3000
		npb_npb_sf0_policy_l34_v4_add(self, self.target, sap=sap_0, l4_src=1, l4_src_mask=0xffff,  flow_class=flow_class_acl_0, drop=1) # drop

		npb_npb_sf0_l4_dst_port_rng_add(self, self.target, 0x3000, 0x4000, 1) # drop 0x3000 - 0x4000
		npb_npb_sf0_policy_l34_v4_add(self, self.target, sap=sap_0, l4_dst=1, l4_dst_mask=0xffff,  flow_class=flow_class_acl_0, drop=1) # drop
		
		# -----------------------
		# Port 0  (6th flow) SF2 L34 v6 drop port range
		# -----------------------
		
		npb_nsh_chain_middle_add(self, self.target,
			#ingress
			[ig_port_0], 99, 0, ta_0+102, spi_0+102, si_0+102, 4, rmac, nexthop_ptr_0+102, bd_0+102, 99, 11, 11, [eg_port_0], False, 0, dsap_12,
			#tunnel
			tunnel_encap_ptr_0+102, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr_0+102, tunnel_encap_bd_0+102, rmac, tunnel_encap_smac_ptr_0+102, smac_12
			#egress
		)

		npb_npb_sf2_len_rng_add(self, self.target, 0x2000, 0xffff, 1) # >= 8k
		npb_npb_sf2_policy_l34_v6_add(self, self.target, dsap=dsap_12, l3_len_rng=0x0001, l3_len_rng_mask=0xffff, drop=1) # drop

		npb_npb_sf2_l4_src_port_rng_add(self, self.target, 0x4000, 0x5000, 1) # drop 0x4000 - 0x5000
		npb_npb_sf2_policy_l34_v6_add(self, self.target, dsap=dsap_12, l4_src=1, l4_src_mask=0xffff,  drop=1) # drop

		npb_npb_sf2_l4_dst_port_rng_add(self, self.target, 0x5000, 0x6000, 1) # drop 0x5000 - 0x6000
		npb_npb_sf2_policy_l34_v6_add(self, self.target, dsap=dsap_12, l4_dst=1, l4_dst_mask=0xffff,  drop=1) # drop

		# -----------------------
		# Port 0  (7th flow) SF2 L34 v4 truncate
		# -----------------------
		
		npb_nsh_chain_middle_add(self, self.target,
			#ingress
			[ig_port_0], 99, 0, ta_0+103, spi_0+103, si_0+103, 4, rmac, nexthop_ptr_0+103, bd_0+103, 99, 13, 13, [eg_port_0], False, 0, dsap_13,
			#tunnel
			tunnel_encap_ptr_0+103, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr_0+103, tunnel_encap_bd_0+103, rmac, tunnel_encap_smac_ptr_0+103, smac_13
			#egress
		)
		npb_npb_sf2_policy_l34_v4_add(self, self.target, dsap=dsap_13, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf, trunc_enable=1, trunc=0x100)

		
		# -----------------------
		# Port 1 - Bridge LACP #Was Add Vlan
		# -----------------------

		ig_port_1 = swports[2]
		eg_port_1 = swports[2]

		smac_1 = '11:11:01:11:11:11'
#		dmac_1 = '22:22:01:22:22:22'
#		dmac2_1= '23:22:22:22:22:22'
		dmac_1 = '01:80:c2:00:00:02'
		dmac2_1= '02:80:c2:00:00:02'
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
		ta_1                      = 9 # Arbitrary value

		sf_bitmask_1              = 0 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

		nexthop_ptr_1             = 1 # Arbitrary value
		vid_1                     = 0 # Arbitrary value
		bd_1                      = 2 # Arbitrary value
		ig_lag_ptr_1              = 3 # Arbitrary value
		eg_lag_ptr_1              = 4 # Arbitrary value
		tunnel_encap_ptr_1        = 5 # Arbitrary value
		tunnel_encap_nexthop_ptr_1 = 6 # Arbitrary value
		tunnel_encap_bd_1         = 7 # Arbitrary value
		tunnel_encap_smac_ptr_1   = 8 # Arbitrary value

		#npb_nsh_bridge_add(self, self.target, 
		#	#ingress
		#	[ig_port_1], ig_lag_ptr_1, rmac, bd_1, 5, dmac_1, eg_lag_ptr_1, 1, 1, [eg_port_1], False
		#	#egress
		#)
		#npb_bd_to_vlan_add(self, self.target, bd_1, vid_1, pcp_1)
		
		npb_nsh_bridge_add(self, self.target,
			#ingress
			[ig_port_1], ig_lag_ptr_1, rmac, nexthop_ptr_1, bd_1, 0x8809, 0xffff, 0, 0x1, vid_1, 0xfff, dmac2_1, 0xffffffffffff,  eg_lag_ptr_1,   1,  1,   [eg_port_1], False
			#egress
		)


		npb_nsh_bridge_add(self, self.target,
			#ingress
			[ig_port_cpu], ig_lag_ptr_1, rmac, nexthop_ptr_1, bd_1, 0x8809, 0xffff, 0, 0x1, vid_1, 0xfff, dmac_1, 0xffffffffffff, eg_lag_ptr_1+1, 1+1, 1+1, [eg_port_cpu], True
			#egress
		)
		
		#Add ingress mirror
		npb_pre_mirror_add(self, self.target, 5, "INGRESS", eg_port_0)
		npb_ing_port_mirror_add(self, self.target, ig_port_1, 5);


		
		# -----------------------------------------------------------
		# Port 2 - (S_E) SFC Transport Reencap V4
		# -----------------------------------------------------------
		ig_port_2 = swports[3]
		eg_port_2 = swports[3]


		smac_2 = '11:11:02:11:11:11'
		dmac_2 = '22:22:02:22:22:22'
		dmac_2 = rmac ##Needed for Reencap
		sip_2 = '192.168.0.1'
		dip_2 = '192.168.0.2'
		#sip_2 = "1111:1111:1111:1111:1111:1111:1111:1111"
		#dip_2 = "2222:2222:2222:2222:2222:2222:2222:2222"


		# -----------------------
		# NSH values to use
		# -----------------------

		sap_2                     = 2 # Arbitrary value
		vpn_2                     = 3 # Arbitrary value
		flow_class_acl_2          = 4 # Arbitrary value
		flow_class_sfp_2          = 5 # Arbitrary value
		spi_2                     = 8 # Arbitrary value
		si_2                      = 9 # Arbitrary value (ttl)
		sfc_2                     = 10 # Arbitrary value
		dsap_2                    = 11 # Arbitrary value

		sf_bitmask_2              = 1 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

		nexthop_ptr_2             = 7 # Arbitrary value
		bd_2                      = 3 # Arbitrary value
		ig_lag_ptr_2              = 11 # Arbitrary value
		eg_lag_ptr_2              = 12 # Arbitrary value
		tunnel_encap_ptr_2        = 9 # Arbitrary value
		tunnel_encap_nexthop_ptr_2 = 10 # Arbitrary value
		tunnel_encap_bd_2         = 11  # Arbitrary value
		tunnel_encap_smac_ptr_2   = 12  # Arbitrary value

		npb_nsh_chain_start_end_with_tunnel_add(self, self.target,
			#ingress
			[ig_port_2], ig_lag_ptr_2, 0, sap_2, vpn_2, spi_2, si_2, sf_bitmask_2, rmac, nexthop_ptr_2, bd_2, eg_lag_ptr_2, 5, 5, [eg_port_2], False, 0, dsap_2,
			#tunnel
			tunnel_encap_ptr_2, EgressTunnelType.IPV4_GRE.value, tunnel_encap_nexthop_ptr_2, tunnel_encap_bd_2, dmac_2, tunnel_encap_smac_ptr_2, smac_2
			#egress
		)
		

#		npb_tunnel_network_dst_vtep_add(self, self.target, l3_src=sip_2, l3_src_mask=0xffffffff, l3_dst=dip_2, l3_dst_mask=0xffffffff, tun_type=IngressTunnelType.VXLAN.value,   tun_type_mask=0xf, sap=sap_2, vpn=vpn_2+2, port_lag_ptr=ig_lag_ptr_2, drop=0)
		npb_tunnel_network_dst_vtep_add(self, self.target, l3_src=sip_2, l3_src_mask=0xffffffff, l3_dst=dip_2, l3_dst_mask=0xffffffff, tun_type=IngressTunnelType.IPINIP.value,  tun_type_mask=0xf, sap=sap_2, vpn=vpn_2+2, port_lag_ptr=ig_lag_ptr_2, drop=0)
		npb_tunnel_network_dst_vtep_add(self, self.target, l3_src=sip_2, l3_src_mask=0xffffffff, l3_dst=dip_2, l3_dst_mask=0xffffffff, tun_type=IngressTunnelType.NVGRE.value,   tun_type_mask=0xf, sap=sap_2, vpn=vpn_2+2, port_lag_ptr=ig_lag_ptr_2, drop=0)
		npb_tunnel_network_dst_vtep_add(self, self.target, l3_src=sip_2, l3_src_mask=0xffffffff, l3_dst=dip_2, l3_dst_mask=0xffffffff, tun_type=IngressTunnelType.GRE.value,     tun_type_mask=0xf, sap=sap_2, vpn=vpn_2+2, port_lag_ptr=ig_lag_ptr_2, drop=0)
		npb_tunnel_network_dst_vtep_add(self, self.target, l3_src=sip_2, l3_src_mask=0xffffffff, l3_dst=dip_2, l3_dst_mask=0xffffffff, tun_type=IngressTunnelType.GTPC.value,    tun_type_mask=0xf, sap=sap_2, vpn=vpn_2+2, port_lag_ptr=ig_lag_ptr_2, drop=0)
		npb_tunnel_network_dst_vtep_add(self, self.target, l3_src=sip_2, l3_src_mask=0xffffffff, l3_dst=dip_2, l3_dst_mask=0xffffffff, tun_type=IngressTunnelType.GTPU.value,    tun_type_mask=0xf, sap=sap_2, vpn=vpn_2+2, port_lag_ptr=ig_lag_ptr_2, drop=0)
		npb_tunnel_network_dst_vtep_add(self, self.target, l3_src=sip_2, l3_src_mask=0xffffffff, l3_dst=dip_2, l3_dst_mask=0xffffffff, tun_type=IngressTunnelType.ERSPAN.value,  tun_type_mask=0xf, sap=sap_2, vpn=vpn_2+2, port_lag_ptr=ig_lag_ptr_2, drop=0)
		

		npb_tunnel_encap_sip_rewrite_v4_add(self, self.target, tunnel_encap_bd_2, sip_2)
		npb_tunnel_encap_dip_rewrite_v4_add(self, self.target, tunnel_encap_ptr_2, dip_2)


		#Add Egress mirror
		npb_pre_mirror_add(self, self.target, 6, "EGRESS", eg_port_0)
		npb_egr_port_mirror_add(self, self.target, eg_port_2, 6);
		
		
		# -----------------------------------------------------------------------------
		# Port 2 (2nd Flow) - SF0 L34 V6 redirect
		# -----------------------------------------------------------------------------

		##Packet goes in ig_port_2 but goes out lag for eg_port1. Need to setup proper NextHop with new SPI/SI
				
		ig_port_new = ig_port_2 #swports[4]
		eg_port_new = eg_port_2 #swports[4]
		npb_nsh_chain_start_add(self, self.target,
			#ingress
			[ig_port_new], ig_lag_ptr_2+1, 0, sap_2+1, vpn_2+1, spi_2+1, si_2+1, sf_bitmask_2, rmac, nexthop_ptr_2+1, bd_2+1, eg_lag_ptr_2+1, 5+1, 5+1, [eg_port_new], False, 0, dsap_2,
			#tunnel
			tunnel_encap_ptr_2+1, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr_2+1, tunnel_encap_bd_2+1, dmac_0, tunnel_encap_smac_ptr_2+1, smac_0
			#egress
		)

		npb_npb_sf0_policy_l34_v6_add(self, self.target, sap=sap_0, l4_src=0x0123, l4_src_mask=0xffff, l3_proto=17, l3_proto_mask=0xff, flow_class=flow_class_acl_0, sfc_enable=1, sfc=sfc_0)
		npb_npb_sfp_sel_add(self, self.target, vpn_0, flow_class_sfp_0, sfc_0, 0, 0, [spi_2+1], [si_2+1], [sf_bitmask_0])
		


		# -----------------
		

#		time.sleep(1)


		
		# -----------------------------------------------------------
		# Port 0 DSAP0 - SF2 Egress Copy 2 CPU
		# -----------------------------------------------------------
		
		src_pkt, exp_pkt = npb_simple_2lyr_ipinip(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			#pktlen=512,
			vn_en=False, e_en=False, 
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			#pktlen_exp=252,
			spi_exp=spi_0, si_exp=si_0, sap_exp=sap_0, vpn_exp=vpn_0
		)


		# -----------------------------------------------------------

		print("---------- Debug Port 0 SF2 Copy to CPU----------")
		#print(testutils.format_packet(src_pkt))
		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)

		# -----------------------------------------------------------

		#print(testutils.format_packet(exp_pkt))
		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)

		#logger.info("Verify no other packets")
		#testutils.verify_no_other_packets(self, 0, 1)
		

		
		# -----------------------------------------------------------
		# Port 0 Second Flow - End of Chain
		# -----------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=rmac, smac_nsh=smac_0, ta=ta_0+100, spi=spi_0+100, si=si_0+100, nshtype=2, sap=sap_0+100, vpn=vpn_0+100, ttl=63, scope=1,
			sf_bitmask=sf_bitmask_0, start_of_chain=False, end_of_chain=True, scope_term_list=[],
			spi_exp=spi_0+100, si_exp=si_0+100, ta_exp=ta_0+100, nshtype_exp=2, sap_exp=sap_0+100, vpn_exp=vpn_0+100
		)

		# -----------------------------------------------------------

		print("---------- Debug Port 0 End of Chain----------")
		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)
		

		# -----------------------------------------------------------
		# Port 0 3rd Flow - Middle of Chain Translate NSH Header
		# -----------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=rmac, smac_nsh=smac_0, spi=spi_0+101, si=si_0+101, ta=ta_0+101, nshtype=1, sap=sap_0+101,  vpn=vpn_0+101, ttl=63, scope=1,
			sf_bitmask=sf_bitmask_0, start_of_chain=False, end_of_chain=False, scope_term_list=[],
			spi_exp=spi_0+101, si_exp=si_0+101, ta_exp=ta_0+101, nshtype_exp=2, sap_exp=sap_0+101, vpn_exp=vpn_0+101
		)


		# -----------------------------------------------------------

		print("---------- Debug Port 0 Middle of Chain Translate NSH Header----------")
		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)

		
		# -----------------------------------------------------------
		# Port 0 4th Flow - SFC inner Decap
		# -----------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_2lyr_nvgre_udp(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, ta=ta_0, nshtype=2, sap=16, vpn=vpn_0, ttl=63, scope=1,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[1],
			spi_exp=spi_0, si_exp=si_0,  ta_exp=ta_0, nshtype_exp=2, sap_exp=16, vpn_exp=17
		)

		# -----------------------------------------------------------

		print("---------- Debug Port 0 SFC Inner Decap----------")
		#print(testutils.format_packet(src_pkt))
		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)


		# -----------------------
		# Port 0  (5th flow) SF0 L34 v4 drop range (ip len, src port, dst port)
		# -----------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			udp_sport=2152, udp_dport=2152,pktlen=8300,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			spi_exp=spi_0, si_exp=si_0, sap_exp=sap_0, vpn_exp=vpn_0
		)

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)


		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			udp_sport=9476, udp_dport=2152,pktlen=6300,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			spi_exp=spi_0, si_exp=si_0, sap_exp=sap_0, vpn_exp=vpn_0
		)

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			udp_sport=1000, udp_dport=13568,pktlen=6300,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			spi_exp=spi_0, si_exp=si_0, sap_exp=sap_0, vpn_exp=vpn_0
		)

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)

                #Send a UDP packet that will make it through all 3 filters
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			udp_sport=1000, udp_dport=1152,pktlen=6300,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			spi_exp=spi_0, si_exp=si_0, sap_exp=sap_0, vpn_exp=vpn_0
		)

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)

		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)
		

		# -----------------------
		# Port 0  (6th flow) SF2 L34 v6 drop range (ip len, src port, dst port)
		# -----------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udpv6(
			dmac_nsh=rmac, smac_nsh=smac_12, spi=spi_0+102, si=si_0+102, ta=ta_0+102, nshtype=1, sap=sap_0+102, vpn=vpn_0+102, ttl=63, scope=1,
			udp_sport=1000, udp_dport=1152,pktlen=8300,
			sf_bitmask=4, start_of_chain=False, end_of_chain=False, scope_term_list=[],
			spi_exp=spi_0+102, si_exp=si_0+102, ta_exp=ta_0+102, nshtype_exp=2, sap_exp=sap_0+102, vpn_exp=vpn_0+102
		)

		print("---------- Debug Port 0 Drop length/Port Ranges ----------")
		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)
		
		
		src_pkt, exp_pkt = npb_simple_1lyr_udpv6(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			udp_sport=0x4500, udp_dport=1152,pktlen=4300,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			spi_exp=spi_0, si_exp=si_0, sap_exp=sap_0, vpn_exp=vpn_0
		)

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)
		

		src_pkt, exp_pkt = npb_simple_1lyr_udpv6(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			udp_sport=1000, udp_dport=0x5500,pktlen=4300,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			spi_exp=spi_0, si_exp=si_0, sap_exp=sap_0, vpn_exp=vpn_0
		)

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)

		
		src_pkt, exp_pkt = npb_simple_1lyr_udpv6(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			udp_sport=1000, udp_dport=1234,pktlen=4300,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			spi_exp=spi_0, si_exp=si_0, sap_exp=sap_0, vpn_exp=vpn_0
		)
		print("Failure Next")
		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)

		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)
		
		# -----------------------
		# Port 0  (7th flow) SF2 L34 v4 truncate
		# -----------------------


		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=rmac, smac_nsh=smac_13, spi=spi_0+103, si=si_0+103, ta=ta_0+103, nshtype=1, sap=sap_0+103, vpn=vpn_0+103, ttl=63, scope=1,
			udp_sport=1000, udp_dport=1152,pktlen=512,
			sf_bitmask=4, start_of_chain=False, end_of_chain=False, scope_term_list=[],
			pktlen_exp=214,
			spi_exp=spi_0+103, si_exp=si_0+103, ta_exp=ta_0+103, nshtype_exp=2, sap_exp=sap_0+103, vpn_exp=vpn_0+103
		)

		# Derek: Have to fix up some of the expected values.  Most of these were obtained by looking the the received / truncated packet
		exp_pkt.exp_pkt[IP].len     = 0x01f2
		exp_pkt.exp_pkt[IP].chksum  = 0xc81e
		exp_pkt.exp_pkt[UDP].len    = 0x01de
#		exp_pkt.exp_pkt[UDP].chksum = 0x0b0f
		exp_pkt.exp_pkt[UDP].chksum = 0x07C9

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)

		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)



		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		

		
		# -----------------------------------------------------------
		# Port 1 DSAP1 - Bridge LACP 
		# -----------------------------------------------------------

		src_pkt=scapy.Ether() / scapy.SlowProtocol() / scapy.LACP()

		print("---------- Debug Port 1 Bridge LACP (Src)----------")
		#print(testutils.format_packet(src_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_1)
		testutils.send_packet(self, ig_port_1, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_cpu)
#		testutils.verify_packet(self, exp_pkt, eg_port_cpu)

		# ---- Mirrored Packet Check --------------------------------

		logger.info("Verify Mirrored packet on port %d", eg_port_0)
		testutils.verify_packet(self, src_pkt, eg_port_0)


		# -------------------------------------------------
		# CPU emulation code (receive a packet, modify it, then reinject it)
		# -------------------------------------------------

		# ----- receive packet -----

		device, port = testutils.port_to_tuple(eg_port_cpu)
		result = testutils.dp_poll(self, device_number=device, port_number=port, timeout=2, exp_pkt=None)
		print("---------- Got Here ----------")


		result2 = cpu_model(
			result,
			False,
			0
		)

		# -----------------------------------------------------------

		exp_pkt=scapy.Ether(dst=dmac2_1) / scapy.SlowProtocol() / scapy.LACP()

		print("---------- Debug Port 1 Bridge LACP (Exp)----------")
		#print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_cpu)
		testutils.send_packet(self, ig_port_cpu, result2)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_1)
		testutils.verify_packets(self, exp_pkt, [eg_port_1])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)
		

		# -----------------------------------------------------------
		# Port 2 (S_E) SFC Transport Reencap V4
		# -----------------------------------------------------------
		
		src_pkt, exp_pkt = npb_simple_2lyr_gre_ip(
			dmac_nsh=dmac_2, smac_nsh=smac_2, spi=spi_2, si=si_2, sap=sap_2, vpn=vpn_2, ttl=63, scope=1,
			dmac=dmac_2, smac=smac_2,
			transport_decap=True, sf_bitmask=sf_bitmask_2, start_of_chain=True, end_of_chain=True, scope_term_list=[], transport_encap=EgressTunnelType.IPV4_GRE.value,
			spi_exp=spi_2, si_exp=si_2, sap_exp=sap_2, vpn_exp=vpn_2
		)

		print("---------- Debug Port 2 SFC Transport Reencap V4----------")
		#print(testutils.format_packet(src_pkt))
		#print(testutils.format_packet(exp_pkt))
		print("---------- Debug ----------")
		
		# -----------------------------------------------------------
		
		logger.info("Sending packet on port %d", ig_port_2)
		testutils.send_packet(self, ig_port_2, src_pkt)

		# -----------------------------------------------------------

		print("---------- Temp Verifying pkt ----------")
		logger.info("Verify packet on port %d", eg_port_2)
		testutils.verify_packet(self, exp_pkt, eg_port_2)

		# ---- Mirrored Packet Check --------------------------------

		print("---------- Temp Verifying Mirrored  pkt ----------")
		logger.info("Verify Mirrored packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)



		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)
		
		
		# -----------------------------------------------------------
		# Port 2 Flow 2 - SF0 L34 V6 Redirect
		# -----------------------------------------------------------
		src_pkt, exp_pkt = npb_simple_1lyr_udpv6(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			udp_sport=0x0123, 
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			spi_exp=spi_2+1, si_exp=si_2+1, sap_exp=sap_0, vpn_exp=vpn_0
        	)


		print("---------- Debug Port 2 Flow 2 SF0 L34 V6 Redirect to Port 1----------")
		#print(testutils.format_packet(src_pkt))
		#print(testutils.format_packet(exp_pkt))
		#print("---------- Debug ----------")

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_new)
		testutils.verify_packet(self, exp_pkt, eg_port_new)

		# ---- Mirrored Packet Check --------------------------------

		logger.info("Verify Mirrored packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)


		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)
		












		# -----------------------------------------------------------
		# Delete Table Entries
		# -----------------------------------------------------------
		#Port 0		
		npb_nsh_chain_start_del(self, self.target,
			#ingress 
			[ig_port_0], ig_lag_ptr_0, spi_0, si_0, sf_bitmask_0, rmac, nexthop_ptr_0, eg_lag_ptr_0, 0, 0, [eg_port_0],
			#tunnel
			tunnel_encap_ptr_0, tunnel_encap_nexthop_ptr_0, tunnel_encap_bd_0, tunnel_encap_smac_ptr_0
			#egress
		)

		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_0, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
		

		npb_nsh_chain_end_del(self, self.target,
			#ingress
			[ig_port_0], 99, ta_0+100, spi_0+100, si_0+100, sf_bitmask_0, rmac, nexthop_ptr_0+100, 99, 10, 10, [eg_port_0], 
			#egress
		)
		

		npb_nsh_chain_middle_del(self, self.target,
			#ingress
			[ig_port_0], 99, ta_0+101, spi_0+101, si_0+101, sf_bitmask_0, rmac, nexthop_ptr_0+101, 99, 11, 11, [eg_port_0],
			#tunnel
			tunnel_encap_ptr_0+101, tunnel_encap_nexthop_ptr_0+101, tunnel_encap_bd_0+101, tunnel_encap_smac_ptr_0+101
			#egress
		)
		
		npb_tunnel_inner_sap_del(self, self.target, sap=sap_0, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)

		npb_npb_sf0_len_rng_del(self, self.target, 0x2000, 0xffff) # >= 8k
		npb_npb_sf0_policy_l34_v4_del(self, self.target, sap=sap_0, l3_len_rng=0x0001, l3_len_rng_mask=0xffff) # drop


		npb_npb_sf0_l4_src_port_rng_del(self, self.target, 0x2000, 0x3000) # >= 8k
		npb_npb_sf0_policy_l34_v4_del(self, self.target, sap=sap_0, l4_src=1, l4_src_mask=0xffff) # drop

		npb_npb_sf0_l4_dst_port_rng_del(self, self.target, 0x3000, 0x4000) # >= 8k & < 12228
		npb_npb_sf0_policy_l34_v4_del(self, self.target, sap=sap_0, l4_dst=1, l4_dst_mask=0xffff) # drop

		npb_nsh_chain_middle_del(self, self.target,
			#ingress
			[ig_port_0],99 , ta_0+102, spi_0+102, si_0+102, 4, rmac, nexthop_ptr_0+102, 99, 11, 11, [eg_port_0],
			#tunnel
			tunnel_encap_ptr_0+102, tunnel_encap_nexthop_ptr_0+102, tunnel_encap_bd_0+102, tunnel_encap_smac_ptr_0+102
			#egress
		)
		npb_npb_sf2_len_rng_del(self, self.target, 0x2000, 0xffff) # >= 8k
		npb_npb_sf2_policy_l34_v6_del(self, self.target, dsap=dsap_12, l3_len_rng=0x0001, l3_len_rng_mask=0xffff) # drop

		npb_npb_sf2_l4_src_port_rng_del(self, self.target, 0x4000, 0x5000) # drop 0x4000 - 0x5000
		npb_npb_sf2_policy_l34_v6_del(self, self.target, dsap=dsap_12, l4_src=1, l4_src_mask=0xffff) # drop

		npb_npb_sf2_l4_dst_port_rng_del(self, self.target, 0x5000, 0x6000) # drop 0x5000 - 0x6000
		npb_npb_sf2_policy_l34_v6_del(self, self.target, dsap=dsap_12, l4_dst=1, l4_dst_mask=0xffff) # drop
		

		npb_nsh_chain_middle_del(self, self.target,
			#ingress
			[ig_port_0],99 , ta_0+103, spi_0+103, si_0+103, 4, rmac, nexthop_ptr_0+103, 99, 13, 13, [eg_port_0],
			#tunnel
			tunnel_encap_ptr_0+103, tunnel_encap_nexthop_ptr_0+103, tunnel_encap_bd_0+103, tunnel_encap_smac_ptr_0+103
			#egress
		)
		npb_npb_sf2_policy_l34_v4_del(self, self.target, dsap=dsap_13, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf)

		#Port 1
		#npb_nsh_bridge_del(self, self.target, 
		#	#ingress
		#	[ig_port_1], ig_lag_ptr_1, rmac, bd_1, 5, dmac_1, eg_lag_ptr_1, 1, [eg_port_1]
		#	#egress
		#)
		#npb_bd_to_vlan_del(self, self.target, bd_1)

		npb_nsh_bridge_del(self, self.target,
			#ingress
			[ig_port_1], ig_lag_ptr_1, rmac, nexthop_ptr_1, 0x8809, 0xffff, 0, 0x1, vid_1, 0xfff, dmac2_1, 0xffffffffffff,  eg_lag_ptr_1,   1,   1,  [eg_port_1]
			#egress
		)


		npb_nsh_bridge_del(self, self.target,
			#ingress

			[ig_port_cpu], ig_lag_ptr_1, rmac, nexthop_ptr_1, 0x8809, 0xffff, 0, 0x1, vid_1, 0xfff, dmac_1, 0xffffffffffff, eg_lag_ptr_1+1, 1+1, 1+1, [eg_port_cpu]
			#egress
		)
		

		npb_ing_port_mirror_del(self, self.target, ig_port_1);
		npb_pre_mirror_del(self, self.target, 5)


		'''
		npb_nsh_chain_start_del(self, self.target,
			#ingress
			[ig_port_2], ig_lag_ptr_2, spi_2, si_2, sf_bitmask_2, rmac, nexthop_ptr_2, eg_lag_ptr_2, 5, 5, [eg_port_2],
			#tunnel
			tunnel_encap_ptr_2, tunnel_encap_nexthop_ptr_2, tunnel_encap_bd_2, tunnel_encap_smac_ptr_2
			#egress
		)
		'''
		npb_nsh_chain_start_end_with_tunnel_del(self, self.target,
			#ingress
			[ig_port_2], ig_lag_ptr_2, spi_2, si_2, sf_bitmask_2, rmac, nexthop_ptr_2, eg_lag_ptr_2, 5, 5, [eg_port_2],
			#tunnel
			tunnel_encap_ptr_2, tunnel_encap_nexthop_ptr_2, tunnel_encap_bd_2, tunnel_encap_smac_ptr_2
			#egress
		)



#		npb_tunnel_network_dst_vtep_del(self, self.target, l3_src=sip_2, l3_src_mask=0xffffffff, l3_dst=dip_2, l3_dst_mask=0xffffffff, tun_type=IngressTunnelType.VXLAN.value,   tun_type_mask=0xf)
		npb_tunnel_network_dst_vtep_del(self, self.target, l3_src=sip_2, l3_src_mask=0xffffffff, l3_dst=dip_2, l3_dst_mask=0xffffffff, tun_type=IngressTunnelType.IPINIP.value,  tun_type_mask=0xf)
		npb_tunnel_network_dst_vtep_del(self, self.target, l3_src=sip_2, l3_src_mask=0xffffffff, l3_dst=dip_2, l3_dst_mask=0xffffffff, tun_type=IngressTunnelType.NVGRE.value,   tun_type_mask=0xf)
		npb_tunnel_network_dst_vtep_del(self, self.target, l3_src=sip_2, l3_src_mask=0xffffffff, l3_dst=dip_2, l3_dst_mask=0xffffffff, tun_type=IngressTunnelType.GRE.value,     tun_type_mask=0xf)
		npb_tunnel_network_dst_vtep_del(self, self.target, l3_src=sip_2, l3_src_mask=0xffffffff, l3_dst=dip_2, l3_dst_mask=0xffffffff, tun_type=IngressTunnelType.GTPC.value,    tun_type_mask=0xf)
		npb_tunnel_network_dst_vtep_del(self, self.target, l3_src=sip_2, l3_src_mask=0xffffffff, l3_dst=dip_2, l3_dst_mask=0xffffffff, tun_type=IngressTunnelType.GTPU.value,    tun_type_mask=0xf)
		npb_tunnel_network_dst_vtep_del(self, self.target, l3_src=sip_2, l3_src_mask=0xffffffff, l3_dst=dip_2, l3_dst_mask=0xffffffff, tun_type=IngressTunnelType.ERSPAN.value,  tun_type_mask=0xf)



		npb_tunnel_encap_sip_rewrite_v4_del(self, self.target, tunnel_encap_bd_2)
		npb_tunnel_encap_dip_rewrite_v4_del(self, self.target, tunnel_encap_ptr_2)

		npb_egr_port_mirror_del(self, self.target, eg_port_2);
		npb_pre_mirror_del(self, self.target, 6)
		
		




		npb_nsh_chain_start_del(self, self.target,
			#ingress
			[ig_port_new], ig_lag_ptr_2+1, spi_2+1, si_2+1, sf_bitmask_2, rmac, nexthop_ptr_2+1, eg_lag_ptr_2+1, 5+1, 5+1, [eg_port_new],
			#tunnel
			tunnel_encap_ptr_2+1, tunnel_encap_nexthop_ptr_2+1, tunnel_encap_bd_2+1, tunnel_encap_smac_ptr_2+1
			#egress
		)


		npb_npb_sf0_policy_l34_v6_del(self, self.target, sap=sap_0, l4_src=0x0123, l4_src_mask=0xffff, l3_proto=17, l3_proto_mask=0xff)
		npb_npb_sfp_sel_del(self, self.target, vpn_0, sfc_0, 0, 0, [spi_2+1], [si_2+1])
		

		
