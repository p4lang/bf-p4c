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

		ig_port_0 = swports[1]
		eg_port_0 = swports[1]

		ig_port_1 = swports[1]
		eg_port_1 = swports[1]

		ig_port_2 = swports[1]
		eg_port_2 = swports[1]

		ig_port_3 = swports[2] # derek changed from [4] so that this test can run on the hw, which only has 4 cpu ports total.
		eg_port_3 = swports[2] # derek changed from [4] so that this test can run on the hw, which only has 4 cpu ports total.

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
		spi_0                   = 4 # Arbitrary value
		spi_1                   = 5 # Arbitrary value
		spi_2                   = 6 # Arbitrary value
		si_0                    = 7 # Arbitrary value (ttl)
		si_1                    = 8 # Arbitrary value (ttl)
		si_2                    = 9 # Arbitrary value (ttl)
		sfc_0                   = 10 # Arbitrary value
		sfc_1                   = 11 # Arbitrary value
		sfc_2                   = 12 # Arbitrary value
		dsap                    = 13 # Arbitrary value
		ta_0                    = 14 # Arbitrary value
		ta_1                    = 15 # Arbitrary value
		ta_2                    = 16 # Arbitrary value

# DEREK MOVED DROPPING TO EGRESS, TO TEST THAT LOGIC
#		sf_bitmask_0            = 1 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress
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

		# ----- hop 0 (in ports 0, 1, 2, out ports 3) -----

		npb_nsh_chain_start_add(self, self.target,
			#ingress
			[ig_port_0], ig_lag_ptr+0, 0, sap, vpn, spi_0, si_0,                          sf_bitmask_0, rmac, nexthop_ptr+0, bd, eg_lag_ptr+0, 0+0, 0+0, [eg_port_3], False, 0, dsap,
			#tunnel
			tunnel_encap_ptr+0, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr+0, tunnel_encap_bd+0, dmac_0, tunnel_encap_smac_ptr+0, smac
			#egress
		)

		npb_nsh_chain_start_add(self, self.target,
			#ingress
			[ig_port_0], ig_lag_ptr+0, 0, sap, vpn, spi_1, si_1,                          sf_bitmask_0, rmac, nexthop_ptr+1, bd, eg_lag_ptr+1, 0+1, 0+1, [eg_port_3], False, 0, dsap,
			#tunnel
			tunnel_encap_ptr+1, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr+1, tunnel_encap_bd+1, dmac_0, tunnel_encap_smac_ptr+1, smac
			#egress
		)

		npb_nsh_chain_start_add(self, self.target,
			#ingress
			[ig_port_0], ig_lag_ptr+0, 0, sap, vpn, spi_2, si_2,                          sf_bitmask_0, rmac, nexthop_ptr+2, bd, eg_lag_ptr+2, 0+2, 0+2, [eg_port_3], False, 0, dsap,
			#tunnel
			tunnel_encap_ptr+2, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr+2, tunnel_encap_bd+2, dmac_0, tunnel_encap_smac_ptr+2, smac
			#egress
		)

		# ----- hop 1 (in port 3, out ports 0, 1, 2) -----

		npb_nsh_chain_end_add(self, self.target,
			#ingress
			[ig_port_3], ig_lag_ptr+3, 0,       ta_0,    spi_0, si_0-(popcount(sf_bitmask_0)), sf_bitmask_1, rmac, nexthop_ptr+8, bd, eg_lag_ptr+8, 0+8, 0+8, [eg_port_0], False, 0, dsap
			#egress
		)

		npb_nsh_chain_end_add(self, self.target,
			#ingress
			[ig_port_3], ig_lag_ptr+3, 0,       ta_1,    spi_1, si_1-(popcount(sf_bitmask_0)), sf_bitmask_1, rmac, nexthop_ptr+9, bd, eg_lag_ptr+9, 0+9, 0+9, [eg_port_1], False, 0, dsap
			#egress
		)

		npb_nsh_chain_end_add(self, self.target,
			#ingress
			[ig_port_3], ig_lag_ptr+3, 0,        ta_2,   spi_2, si_2-(popcount(sf_bitmask_0)), sf_bitmask_1, rmac, nexthop_ptr+10, bd, eg_lag_ptr+10, 0+10, 0+10, [eg_port_2], False, 0, dsap
			#egress
		)

		# -----------------
		# Ingress Tunnel
		# -----------------

		npb_tunnel_inner_sap_add(self, self.target, sap=sap, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, sap_new=sap, vpn=vpn, terminate=1)
		npb_tunnel_inner_sap_add(self, self.target, sap=sap, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, sap_new=sap, vpn=vpn, terminate=1)
		npb_tunnel_inner_sap_add(self, self.target, sap=sap, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, sap_new=sap, vpn=vpn, terminate=1)
		npb_tunnel_inner_sap_add(self, self.target, sap=sap, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, sap_new=sap, vpn=vpn, terminate=1)
		npb_tunnel_inner_sap_add(self, self.target, sap=sap, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, sap_new=sap, vpn=vpn, terminate=0)
		npb_tunnel_inner_sap_add(self, self.target, sap=sap, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, sap_new=sap, vpn=vpn, terminate=1)
		npb_tunnel_inner_sap_add(self, self.target, sap=sap, tun_type=IngressTunnelType.ERSPAN.value, tun_type_mask=0xf, sap_new=sap, vpn=vpn, terminate=1)

		# -----------------
		# Ingress SF(s)
		# -----------------

		# DEREK: RECLASSIFY IN TO 3 SEPARATE CHAINS

		npb_npb_sf0_policy_l34_v4_add(self, self.target, sap=sap, l3_proto=6, l3_proto_mask=0xff, l4_src=80,  l4_src_mask=0xffff, flow_class=flow_class_acl, sfc_enable=1, sfc=sfc_1) # hop 0 - reclassify to chain #1
# DEREK MOVED DROPPING TO EGRESS, TO TEST THAT LOGIC
#		npb_npb_sf0_policy_l34_v4_add(self, self.target, sap=sap, l3_proto=6, l3_proto_mask=0xff, l4_src=443, l4_src_mask=0xffff, flow_class=flow_class_acl, drop=1)                  # hop 0 - reclassify to drop
		npb_npb_sf0_policy_l34_v4_add(self, self.target, sap=sap, l3_proto=6, l3_proto_mask=0xff, l4_src=443, l4_src_mask=0xffff, flow_class=flow_class_acl, sfc_enable=1, sfc=sfc_2) # hop 0 - reclassify to chain #2

		# -----------------
		# Ingress SFP Sel
		# -----------------

		npb_npb_sfp_sel_add(self, self.target, vpn, flow_class_sfp, sfc_0, 0, 0+0, [spi_0], [si_0], [sf_bitmask_0]) # hop 0
		npb_npb_sfp_sel_add(self, self.target, vpn, flow_class_sfp, sfc_1, 0, 0+1, [spi_1], [si_1], [sf_bitmask_0]) # hop 0 (port 80)
		npb_npb_sfp_sel_add(self, self.target, vpn, flow_class_sfp, sfc_2, 0, 0+2, [spi_2], [si_2], [sf_bitmask_0]) # hop 0 (port 443)

		# -----------------
		# Egress SF(s)
		# -----------------

		npb_npb_sf2_policy_l34_v4_add    (self, self.target, dsap=dsap, l3_proto=6, l3_proto_mask=0xff, l4_src=443, l4_src_mask=0xffff, drop=1)                                       # hop 0 - reclassify to drop

		# -----------------

#		time.sleep(1)

		########################################################################
		# Create / Send / Verify the packet #0 (should not change spi/si)
		########################################################################

		base_pkt_inner = testutils.simple_tcp_packet(eth_dst=dmac,tcp_sport=0,tcp_dport=0)
#		base_pkt_inner = testutils.simple_udp_packet(eth_dst=dmac,udp_sport=0,udp_dport=0)

#		base_pkt = base_pkt_inner
		base_pkt = testutils.simple_vxlan_packet(eth_dst=dmac, inner_frame=base_pkt_inner)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))

		# -----------------

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac_0, eth_type=0x894f) / \
			scapy.NSH(mdtype=1, nextproto=3, spi=spi_0, si=si_0-(popcount(sf_bitmask_0)), ttl=63, \
				datatype=2, \
                vpn=vpn, \
				scope=1, \
                ssap=sap, \
			) / \
			base_pkt_inner
		print(type(exp_pkt))

		# add a mask to the packet
		exp_pkt = Mask(exp_pkt)
		exp_pkt.set_do_not_care_scapy(NSH, 'laghash')
		exp_pkt.set_do_not_care_scapy(NSH, 'timestamp')

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_3)
		testutils.verify_packets(self, exp_pkt, [eg_port_3])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		# -----------------------------------------------------------
		# Create / Send / Verify the packet #0 (should not change spi/si)
		# -----------------------------------------------------------

		src_pkt = exp_pkt.exp_pkt
		print(type(src_pkt))

		# -----------------

		exp_pkt = testutils.simple_tcp_packet(eth_dst=dmac,tcp_sport=0,tcp_dport=0)
#		exp_pkt = testutils.simple_udp_packet(eth_dst=dmac,udp_sport=0,udp_dport=0)
		print(type(exp_pkt))

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_3)
		testutils.send_packet(self, ig_port_3, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packets(self, exp_pkt, [eg_port_0])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		########################################################################
		# Create / Send / Verify the packet #1 (should be redirected to new spi/si)
		########################################################################

		base_pkt_inner = testutils.simple_tcp_packet(eth_dst=dmac,tcp_sport=80,tcp_dport=0)
#		base_pkt_inner = testutils.simple_udp_packet(eth_dst=dmac,udp_sport=0,udp_dport=0)

#		base_pkt = base_pkt_inner
		base_pkt = testutils.simple_vxlan_packet(eth_dst=dmac, inner_frame=base_pkt_inner)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))

		# -----------------

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac_0, eth_type=0x894f) / \
			scapy.NSH(mdtype=1, nextproto=3, spi=spi_1, si=si_1-(popcount(sf_bitmask_0)), ttl=63, \
				datatype=2, \
                vpn=vpn, \
				scope=1, \
                ssap=sap, \
			) / \
			base_pkt_inner
		print(type(exp_pkt))

		# add a mask to the packet
		exp_pkt = Mask(exp_pkt)
		exp_pkt.set_do_not_care_scapy(NSH, 'laghash')
		exp_pkt.set_do_not_care_scapy(NSH, 'timestamp')

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_3)
		testutils.verify_packets(self, exp_pkt, [eg_port_3])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		# -----------------------------------------------------------
		# Create / Send / Verify the packet #1 (should be redirected to new spi/si)
		# -----------------------------------------------------------

		src_pkt = exp_pkt.exp_pkt
		print(type(src_pkt))

		# -----------------

		exp_pkt = testutils.simple_tcp_packet(eth_dst=dmac,tcp_sport=80,tcp_dport=0)
#		exp_pkt = testutils.simple_udp_packet(eth_dst=dmac,udp_sport=0,udp_dport=0)
		print(type(exp_pkt))

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_3)
		testutils.send_packet(self, ig_port_3, src_pkt)

		# -----------------------------------------------------------

		logger.info("Verify packet on port %d", eg_port_1)
		testutils.verify_packets(self, exp_pkt, [eg_port_1])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		########################################################################
		# Create / Send / Verify the packet #2 (should be dropped)
		########################################################################

		base_pkt_inner = testutils.simple_tcp_packet(eth_dst=dmac,tcp_sport=443,tcp_dport=0)
#		base_pkt_inner = testutils.simple_udp_packet(eth_dst=dmac,udp_sport=0,  udp_dport=0)

#		base_pkt = base_pkt_inner
		base_pkt = testutils.simple_vxlan_packet(eth_dst=dmac, inner_frame=base_pkt_inner)
		print(type(base_pkt))

		# -----------------

		src_pkt = \
			base_pkt
		print(type(src_pkt))

		# -----------------

		exp_pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac_0, eth_type=0x894f) / \
			scapy.NSH(mdtype=1, nextproto=3, spi=spi_0, si=si_0-(popcount(sf_bitmask_0)), ttl=63, \
				datatype=2, \
                vpn=vpn, \
                ssap=sap, \
			) / \
			base_pkt
		print(type(exp_pkt))

		# add a mask to the packet
		exp_pkt = Mask(exp_pkt)
		exp_pkt.set_do_not_care_scapy(NSH, 'laghash')
		exp_pkt.set_do_not_care_scapy(NSH, 'timestamp')

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)

		# -----------------------------------------------------------

#		logger.info("Verify packet on port %d", eg_port_3)
#		testutils.verify_packets(self, exp_pkt, [eg_port_3])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		# -----------------------------------------------------------
		# Delete Table Entries
		# -----------------------------------------------------------

		# ----- hop 0 (in ports 0, 1, 2, out ports 3) -----

		npb_nsh_chain_start_del(self, self.target,
			#ingress
			[ig_port_0], ig_lag_ptr+0, spi_0, si_0,                          sf_bitmask_0, rmac, nexthop_ptr+0, eg_lag_ptr+0, 0+0, 0+0, [eg_port_0],
			#tunnel
			tunnel_encap_ptr+0, tunnel_encap_nexthop_ptr+0, tunnel_encap_bd+0, tunnel_encap_smac_ptr+0
			#egress
		)

		npb_nsh_chain_start_del(self, self.target,
			#ingress
			[ig_port_0], ig_lag_ptr+0, spi_1, si_1,                          sf_bitmask_0, rmac, nexthop_ptr+1, eg_lag_ptr+1, 0+1, 0+1, [eg_port_1],
			#tunnel
			tunnel_encap_ptr+1, tunnel_encap_nexthop_ptr+1, tunnel_encap_bd+1, tunnel_encap_smac_ptr+1
			#egress
		)

		npb_nsh_chain_start_del(self, self.target,
			#ingress
			[ig_port_0], ig_lag_ptr+0, spi_2, si_2,                          sf_bitmask_0, rmac, nexthop_ptr+2, eg_lag_ptr+2, 0+2, 0+2, [eg_port_2],
			#tunnel
			tunnel_encap_ptr+2, tunnel_encap_nexthop_ptr+2, tunnel_encap_bd+2, tunnel_encap_smac_ptr+2
			#egress
		)

		# ----- hop 1 (in port 3, out ports 0, 1, 2) -----

		npb_nsh_chain_end_del(self, self.target,
			#ingress
			[ig_port_3], ig_lag_ptr+3, ta_0, spi_0, si_0-(popcount(sf_bitmask_0)), sf_bitmask_1, rmac, nexthop_ptr+8, eg_lag_ptr+8, 0+8, 0+8, [eg_port_3]
			#egress
		)

		npb_nsh_chain_end_del(self, self.target,
			#ingress
			[ig_port_3], ig_lag_ptr+3, ta_1, spi_1, si_1-(popcount(sf_bitmask_0)), sf_bitmask_1, rmac, nexthop_ptr+9, eg_lag_ptr+9, 0+9, 0+9, [eg_port_3]
			#egress
		)

		npb_nsh_chain_end_del(self, self.target,
			#ingress
			[ig_port_3], ig_lag_ptr+3, ta_2, spi_2, si_2-(popcount(sf_bitmask_0)), sf_bitmask_1, rmac, nexthop_ptr+10, eg_lag_ptr+10, 0+10, 0+10, [eg_port_3]
			#egress
		)

		# -----------------
		# Ingress Tunnel
		# -----------------

		npb_tunnel_inner_sap_del(self, self.target, sap=sap, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf)
		npb_tunnel_inner_sap_del(self, self.target, sap=sap, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
		npb_tunnel_inner_sap_del(self, self.target, sap=sap, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)
		npb_tunnel_inner_sap_del(self, self.target, sap=sap, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf)
		npb_tunnel_inner_sap_del(self, self.target, sap=sap, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf)
		npb_tunnel_inner_sap_del(self, self.target, sap=sap, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf)
		npb_tunnel_inner_sap_del(self, self.target, sap=sap, tun_type=IngressTunnelType.ERSPAN.value, tun_type_mask=0xf)

		# -----------------
		# Ingress SF(s)
		# -----------------

		# DEREK: RECLASSIFY IN TO 3 SEPARATE CHAINS

		npb_npb_sf0_policy_l34_v4_del(self, self.target, sap=sap, l3_proto=6, l3_proto_mask=0xff, l4_src=80,  l4_src_mask=0xffff) # hop 0 - reclassify to chain #1
#		npb_npb_sf0_policy_l34_v4_del(self, self.target, sap=sap, l3_proto=6, l3_proto_mask=0xff, l4_src=443, l4_src_mask=0xffff) # hop 0 - reclassify to drop
		npb_npb_sf0_policy_l34_v4_del(self, self.target, sap=sap, l3_proto=6, l3_proto_mask=0xff, l4_src=443, l4_src_mask=0xffff) # hop 0 - reclassify to chain #2

		# -----------------
		# Ingress SFP Sel
		# -----------------

		npb_npb_sfp_sel_del(self, self.target, vpn, sfc_0, 0, 0+0, [spi_0], [si_0]) # hop 0
		npb_npb_sfp_sel_del(self, self.target, vpn, sfc_1, 0, 0+1, [spi_1], [si_1]) # hop 0 (port 80)
		npb_npb_sfp_sel_del(self, self.target, vpn, sfc_2, 0, 0+2, [spi_2], [si_2]) # hop 0 (port 443)

		# -----------------
		# Egress SF(s)
		# -----------------

		npb_npb_sf2_policy_l34_v4_del(self, self.target, dsap=dsap, l3_proto=6, l3_proto_mask=0xff, l4_src=443, l4_src_mask=0xffff) # hop 0 - reclassify to drop
