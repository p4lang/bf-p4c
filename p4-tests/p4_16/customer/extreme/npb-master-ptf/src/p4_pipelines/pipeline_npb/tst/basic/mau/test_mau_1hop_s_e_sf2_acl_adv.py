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

		ig_port = swports[1]
		eg_port = swports[1]

		# -----------------------
		# Port 0(UDP) - Packet values to use
		# -----------------------

		smac = '11:11:00:11:11:11'
		dmac = '22:22:00:22:22:22'
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

		npb_nsh_chain_start_add(self, self.target,
			#ingress
			[ig_port], ig_lag_ptr, 0, sap, vpn, spi, si, sf_bitmask, rmac, nexthop_ptr, bd, eg_lag_ptr, 0, 0, [eg_port], False, 0, dsap,
			#tunnel
			tunnel_encap_ptr, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr, tunnel_encap_bd, dmac, tunnel_encap_smac_ptr, smac
			#egress
		)

		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf, drop=0)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, drop=1)


		''' VXLAN support in SF2 removed
		# -----------------------
		# Port 1(VXLAN) - Packet values to use
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

		npb_nsh_chain_start_add(self, self.target,
			#ingress
			[ig_port_1], ig_lag_ptr_1, 0, sap_1, vpn_1, spi_1, si_1, sf_bitmask_1, rmac, nexthop_ptr_1, bd_1, eg_lag_ptr_1, 1, 1, [eg_port_1], False, 0, dsap_1,
			#tunnel
			tunnel_encap_ptr_1, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr_1, tunnel_encap_bd_1, dmac_1, tunnel_encap_smac_ptr_1, smac_1
			#egress
		)

		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, drop=0)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, drop=1)
		'''

		# -----------------------
		# Port 2(IPinIP) - Packet values to use
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

		npb_nsh_chain_start_add(self, self.target,
			#ingress
			[ig_port_2], ig_lag_ptr_2, 0, sap_2, vpn_2, spi_2, si_2, sf_bitmask_2, rmac, nexthop_ptr_2, bd_2, eg_lag_ptr_2, 2, 2, [eg_port_2], False, 0, dsap_2,
			#tunnel
			tunnel_encap_ptr_2, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr_2, tunnel_encap_bd_2, dmac_2, tunnel_encap_smac_ptr_2, smac_2
			#egress
		)

		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, drop=0)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, drop=1)


		# -----------------------
		# Port 3(NVGRE) - Packet values to use
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

		npb_nsh_chain_start_add(self, self.target,
			#ingress
			[ig_port_3], ig_lag_ptr_3, 0, sap_3, vpn_3, spi_3, si_3, sf_bitmask_3, rmac, nexthop_ptr_3, bd_3, eg_lag_ptr_3, 3, 3, [eg_port_3], False, 0, dsap_3,
			#tunnel
			tunnel_encap_ptr_3, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr_3, tunnel_encap_bd_3, dmac_3, tunnel_encap_smac_ptr_3, smac_3
			#egress
		)

		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, drop=0)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, drop=1)

		# -----------------------
		# Port 4 GRE) - Packet values to use
		# -----------------------
		ig_port_4 = swports[5]
		eg_port_4 = swports[5]


		smac_4 = '11:11:04:11:11:11'
		dmac_4 = '22:22:04:22:22:22'
		sip_4 = "0.0.4.3"
		dip_4 = "0.0.4.4"

		##rmac_2 = '33:33:01:33:33:33' Shared RMAC

		# -----------------------
		# NSH values to use
		# -----------------------

		sap_4                     = 4 # Arbitrary value
		vpn_4                     = 5 # Arbitrary value
		flow_class_acl_4          = 6 # Arbitrary value
		flow_class_sfp_4          = 7 # Arbitrary value
		spi_4                     = 8 # Arbitrary value
		si_4                      = 9 # Arbitrary value (ttl)
		sfc_4                     = 10 # Arbitrary value
		dsap_4                    = 11 # Arbitrary value

		sf_bitmask_4              = 4 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

		nexthop_ptr_4             = 4 # Arbitrary value
		bd_4                      = 5 # Arbitrary value
		ig_lag_ptr_4              = 8 # Arbitrary value
		eg_lag_ptr_4              = 9 # Arbitrary value
		tunnel_encap_ptr_4        = 10 # Arbitrary value
		tunnel_encap_nexthop_ptr_4 = 11 # Arbitrary value
		tunnel_encap_bd_4         = 12 # Arbitrary value
		tunnel_encap_smac_ptr_4   = 12 # Arbitrary value

		npb_nsh_chain_start_add(self, self.target,
			#ingress
			[ig_port_4], ig_lag_ptr_4, 0, sap_4, vpn_4, spi_4, si_4, sf_bitmask_4, rmac, nexthop_ptr_4, bd_4, eg_lag_ptr_4, 4, 4, [eg_port_4], False, 0, dsap_4,
			#tunnel
			tunnel_encap_ptr_4, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr_4, tunnel_encap_bd_4, dmac_4, tunnel_encap_smac_ptr_4, smac_4
			#egress
		)

		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, drop=0)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, drop=1)


		# -----------------------
		# Port 5 (GTPC) - Packet values to use
		# -----------------------
		ig_port_5 = swports[6]
		eg_port_5 = swports[6]


		smac_5 = '11:11:05:11:11:11'
		dmac_5 = '22:22:05:22:22:22'
		sip_5 = "0.0.5.3"
		dip_5 = "0.0.5.4"

		##rmac_2 = '33:33:01:33:33:33' Shared RMAC

		# -----------------------
		# NSH values to use
		# -----------------------

		sap_5                     = 5 # Arbitrary value
		vpn_5                     = 6 # Arbitrary value
		flow_class_acl_5          = 7 # Arbitrary value
		flow_class_sfp_5          = 8 # Arbitrary value
		spi_5                     = 9 # Arbitrary value
		si_5                      = 10 # Arbitrary value (ttl)
		sfc_5                     = 11 # Arbitrary value
		dsap_5                    = 12 # Arbitrary value

		sf_bitmask_5              = 4 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

		nexthop_ptr_5             = 5 # Arbitrary value
		bd_5                      = 6 # Arbitrary value
		ig_lag_ptr_5              = 9 # Arbitrary value
		eg_lag_ptr_5              = 10 # Arbitrary value
		tunnel_encap_ptr_5        = 11 # Arbitrary value
		tunnel_encap_nexthop_ptr_5 = 12 # Arbitrary value
		tunnel_encap_bd_5         = 13 # Arbitrary value
		tunnel_encap_smac_ptr_5   = 14 # Arbitrary value

		npb_nsh_chain_start_add(self, self.target,
			#ingress
			[ig_port_5], ig_lag_ptr_5, 0, sap_5, vpn_5, spi_5, si_5, sf_bitmask_5, rmac, nexthop_ptr_5, bd_5, eg_lag_ptr_5, 5, 5, [eg_port_5], False, 0, dsap_5,
			#tunnel
			tunnel_encap_ptr_5, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr_5, tunnel_encap_bd_5, dmac_5, tunnel_encap_smac_ptr_5, smac_5
			#egress
		)

		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, drop=0)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, drop=1)


		# -----------------------
		# Port 6 (GTPU) - Packet values to use
		# -----------------------
		ig_port_6 = swports[7]
		eg_port_6 = swports[7]


		smac_6 = '11:11:06:11:11:11'
		dmac_6 = '22:22:06:22:22:22'
		sip_6 = "0.0.6.3"
		dip_6 = "0.0.6.4"

		##rmac_2 = '33:33:01:33:33:33' Shared RMAC

		# -----------------------
		# NSH values to use
		# -----------------------

		sap_6                     = 6 # Arbitrary value
		vpn_6                     = 7 # Arbitrary value
		flow_class_acl_6          = 8 # Arbitrary value
		flow_class_sfp_6          = 9 # Arbitrary value
		spi_6                     = 10 # Arbitrary value
		si_6                      = 11 # Arbitrary value (ttl)
		sfc_6                     = 12 # Arbitrary value
		dsap_6                    = 13 # Arbitrary value

		sf_bitmask_6              = 4 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

		nexthop_ptr_6             = 6 # Arbitrary value
		bd_6                      = 7 # Arbitrary value
		ig_lag_ptr_6              = 10 # Arbitrary value
		eg_lag_ptr_6              = 11 # Arbitrary value
		tunnel_encap_ptr_6        = 12 # Arbitrary value
		tunnel_encap_nexthop_ptr_6 = 13 # Arbitrary value
		tunnel_encap_bd_6         = 14 # Arbitrary value
		tunnel_encap_smac_ptr_6   = 15 # Arbitrary value

		npb_nsh_chain_start_add(self, self.target,
			#ingress
			[ig_port_6], ig_lag_ptr_6, 0, sap_6, vpn_6, spi_6, si_6, sf_bitmask_6, rmac, nexthop_ptr_6, bd_6, eg_lag_ptr_6, 6, 6, [eg_port_6], False, 0, dsap_6,
			#tunnel
			tunnel_encap_ptr_6, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr_6, tunnel_encap_bd_6, dmac_6, tunnel_encap_smac_ptr_6, smac_6
			#egress
		)

		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, drop=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, drop=0)






		# -----------------

#		time.sleep(1)

		# -----------------------------------------------------------
		# Port 0 - 1 Lyr UDP Vlan Allow
		# -----------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			#pktlen=512,
			vn_en=False, e_en=False, 
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			#pktlen_exp=252,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)


		# -----------------------------------------------------------

		print("---------- Src Debug Port 0 Allow----------")
		#print(testutils.format_packet(src_pkt))
		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		print("---------- Exp Debug Port 0 Allow----------")
		#print(testutils.format_packet(exp_pkt))
		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		src_pkt, exp_pkt = npb_simple_2lyr_ipinip(
			dmac_nsh=dmac_2, smac_nsh=smac_2, spi=spi_2, si=si_2, sap=sap_2, vpn=vpn_2, ttl=63, scope=1,
			#pktlen=512,
			vn_en=False, e_en=False, 
			sf_bitmask=sf_bitmask_2, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			#pktlen_exp=252,
			spi_exp=spi_2, si_exp=si_2, sap_exp=sap_2, vpn_exp=vpn_2
		)


		# -----------------------------------------------------------

		print("---------- Src Debug Port 0 Drop----------")
		#print(testutils.format_packet(src_pkt))
		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		print("---------- Exp Debug Port 0 Drop----------")
		#print(testutils.format_packet(exp_pkt))
		#logger.info("Verify packet on port %d", eg_port)
		#testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		# -----------------------------------------------------------
		# Port1 - 2 Layer VXLAN removed for now
		# -----------------------------------------------------------


		# -----------------------------------------------------------
		# Port2 - 2 Layer IPinIP
		# -----------------------------------------------------------

		src_pkt_2, exp_pkt_2 = npb_simple_2lyr_ipinip(
			dmac_nsh=dmac_2, smac_nsh=smac_2, spi=spi_2, si=si_2, sap=sap_2, vpn=vpn_2, ttl=63, scope=1,
			#pktlen=512,
			vn_en=False, e_en=False, 
			sf_bitmask=sf_bitmask_2, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			#pktlen_exp=252,
			spi_exp=spi_2, si_exp=si_2, sap_exp=sap_2, vpn_exp=vpn_2
		)

		# -----------------------------------------------------------

		print("---------- Src Debug Port 2 Allow ----------")
		#print(testutils.format_packet(src_pkt_2))
		logger.info("Sending packet on port %d", ig_port_2)
		testutils.send_packet(self, ig_port_2, src_pkt_2)

		# -----------------------------------------------------------

		print("---------- Exp Debug Port 2 Allow ----------")
		#print(testutils.format_packet(exp_pkt_2))
		logger.info("Verify packet on port %d", eg_port_2)
		testutils.verify_packets(self, exp_pkt_2, [eg_port_2])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		src_pkt_2, exp_pkt_2 = npb_simple_2lyr_nvgre_udp(
			dmac_nsh=dmac_2, smac_nsh=smac_2, spi=spi_2, si=si_2, sap=sap_2, vpn=vpn_2, ttl=63, scope=1,
			#pktlen=512,
			vn_en=False, e_en=False, 
			sf_bitmask=sf_bitmask_2, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			#pktlen_exp=252,
			spi_exp=spi_2, si_exp=si_2, sap_exp=sap_2, vpn_exp=vpn_2
		)

		# -----------------------------------------------------------

		print("---------- Src Debug Port 2 Drop ----------")
		#print(testutils.format_packet(src_pkt_2))
		logger.info("Sending packet on port %d", ig_port_2)
		testutils.send_packet(self, ig_port_2, src_pkt_2)

		# -----------------------------------------------------------

		print("---------- Exp Debug Port 2 Drop ----------")
		#print(testutils.format_packet(exp_pkt_2))
		#logger.info("Verify packet on port %d", eg_port_2)
		#testutils.verify_packets(self, exp_pkt_2, [eg_port_2])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)




		# -----------------------------------------------------------
		# Port3 - 2 Layer NVGRE
		# -----------------------------------------------------------

		src_pkt_3, exp_pkt_3 = npb_simple_2lyr_nvgre_udp(
			dmac_nsh=dmac_3, smac_nsh=smac_3, spi=spi_3, si=si_3, sap=sap_3, vpn=vpn_3, ttl=63, scope=1,
			#pktlen=512,
			vn_en=False, e_en=False, 
			sf_bitmask=sf_bitmask_3, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			#pktlen_exp=252,
			spi_exp=spi_3, si_exp=si_3, sap_exp=sap_3, vpn_exp=vpn_3
		)

		# -----------------------------------------------------------

		print("---------- Src Debug Port 3 Allow ----------")
		#print(testutils.format_packet(src_pkt_3))
		logger.info("Sending packet on port %d", ig_port_3)
		testutils.send_packet(self, ig_port_3, src_pkt_3)

		# -----------------------------------------------------------

		print("---------- Exp Debug Port 3 Allow ----------")
		#print(testutils.format_packet(exp_pkt_3))
		logger.info("Verify packet on port %d", eg_port_3)
		testutils.verify_packets(self, exp_pkt_3, [eg_port_3])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		src_pkt_3, exp_pkt_3 = npb_simple_2lyr_gre_ip(
			dmac_nsh=dmac_3, smac_nsh=smac_3, spi=spi_3, si=si_3, sap=sap_3, vpn=vpn_3, ttl=63, scope=1,
			#pktlen=512,
			vn_en=False, e_en=False, 
			sf_bitmask=sf_bitmask_3, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			#pktlen_exp=252,
			spi_exp=spi_3, si_exp=si_3, sap_exp=sap_3, vpn_exp=vpn_3
		)

		# -----------------------------------------------------------

		print("---------- Src Debug Port 3 Drop ----------")
		#print(testutils.format_packet(src_pkt_3))
		logger.info("Sending packet on port %d", ig_port_3)
		testutils.send_packet(self, ig_port_3, src_pkt_3)

		# -----------------------------------------------------------

		print("---------- Exp Debug Port 3 Drop ----------")
		#print(testutils.format_packet(exp_pkt_3))
		#logger.info("Verify packet on port %d", eg_port_3)
		#testutils.verify_packets(self, exp_pkt_3, [eg_port_3])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)


		# -----------------------------------------------------------
		# Port4 - 2 Layer GRE
		# -----------------------------------------------------------

		src_pkt_4, exp_pkt_4 = npb_simple_2lyr_gre_ip(
			dmac_nsh=dmac_4, smac_nsh=smac_4, spi=spi_4, si=si_4, sap=sap_4, vpn=vpn_4, ttl=63, scope=1,
			#pktlen=512,
			vn_en=False, e_en=False, 
			sf_bitmask=sf_bitmask_4, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			#pktlen_exp=252,
			spi_exp=spi_4, si_exp=si_4, sap_exp=sap_4, vpn_exp=vpn_4
		)

		# -----------------------------------------------------------

		print("---------- Src Debug Port 4 Allow----------")
		#print(testutils.format_packet(src_pkt_4))
		logger.info("Sending packet on port %d", ig_port_4)
		testutils.send_packet(self, ig_port_4, src_pkt_4)

		# -----------------------------------------------------------

		print("---------- Exp Debug Port 4 Allow----------")
		#print(testutils.format_packet(exp_pkt_4))
		logger.info("Verify packet on port %d", eg_port_4)
		testutils.verify_packets(self, exp_pkt_4, [eg_port_4])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		src_pkt_4, exp_pkt_4 = npb_simple_2lyr_gtpc_udp(
			dmac_nsh=dmac_4, smac_nsh=smac_4, spi=spi_4, si=si_4, sap=sap_4, vpn=vpn_4, ttl=63, scope=1,
			#pktlen=512,
			vn_en=False, e_en=False, 
			sf_bitmask=sf_bitmask_4, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			#pktlen_exp=252,
			spi_exp=spi_4, si_exp=si_4, sap_exp=sap_4, vpn_exp=vpn_4
		)

		# -----------------------------------------------------------

		print("---------- Src Debug Port 4 Drop----------")
		#print(testutils.format_packet(src_pkt_4))
		logger.info("Sending packet on port %d", ig_port_4)
		testutils.send_packet(self, ig_port_4, src_pkt_4)

		# -----------------------------------------------------------

		print("---------- Exp Debug Port 4 Drop----------")
		#print(testutils.format_packet(exp_pkt_4))
		#logger.info("Verify packet on port %d", eg_port_4)
		#testutils.verify_packets(self, exp_pkt_4, [eg_port_4])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)



		# -----------------------------------------------------------
		# Port5 - 2 Layer GTPC
		# -----------------------------------------------------------

		src_pkt_5, exp_pkt_5 = npb_simple_2lyr_gtpc_udp(
			dmac_nsh=dmac_5, smac_nsh=smac_5, spi=spi_5, si=si_5, sap=sap_5, vpn=vpn_5, ttl=63, scope=1,
			#pktlen=512,
			vn_en=False, e_en=False, 
			sf_bitmask=sf_bitmask_5, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			#pktlen_exp=252,
			spi_exp=spi_5, si_exp=si_5, sap_exp=sap_5, vpn_exp=vpn_5
		)

		# -----------------------------------------------------------

		print("---------- Src Debug Port 5 Allow----------")
		#print(testutils.format_packet(src_pkt_5))
		logger.info("Sending packet on port %d", ig_port_5)
		testutils.send_packet(self, ig_port_5, src_pkt_5)

		# -----------------------------------------------------------

		print("---------- Exp Debug Port 5 Allow----------")
		#print(testutils.format_packet(exp_pkt_5))
		logger.info("Verify packet on port %d", eg_port_5)
		testutils.verify_packets(self, exp_pkt_5, [eg_port_5])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		src_pkt_5, exp_pkt_5 = npb_simple_2lyr_gtpu_ip(
			dmac_nsh=dmac_5, smac_nsh=smac_5, spi=spi_5, si=si_5, sap=sap_5, vpn=vpn_5, ttl=63, scope=1,
			#pktlen=512,
			vn_en=False, e_en=False, 
			sf_bitmask=sf_bitmask_5, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			#pktlen_exp=252,
			spi_exp=spi_5, si_exp=si_5, sap_exp=sap_5, vpn_exp=vpn_5
		)

		# -----------------------------------------------------------

		print("---------- Src Debug Port 5 Drop----------")
		#print(testutils.format_packet(src_pkt_5))
		logger.info("Sending packet on port %d", ig_port_5)
		testutils.send_packet(self, ig_port_5, src_pkt_5)

		# -----------------------------------------------------------

		print("---------- Exp Debug Port 5 Drop----------")
		#print(testutils.format_packet(exp_pkt_5))
		#logger.info("Verify packet on port %d", eg_port_5)
		#testutils.verify_packets(self, exp_pkt_5, [eg_port_5])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		# -----------------------------------------------------------
		# Port6- 2 Layer GTPU
		# -----------------------------------------------------------

		src_pkt_6, exp_pkt_6 = npb_simple_2lyr_gtpu_ip(
			dmac_nsh=dmac_6, smac_nsh=smac_6, spi=spi_6, si=si_6, sap=sap_6, vpn=vpn_6, ttl=63, scope=1,
			#pktlen=512,
			vn_en=False, e_en=False, 
			sf_bitmask=sf_bitmask_6, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			#pktlen_exp=252,
			spi_exp=spi_6, si_exp=si_6, sap_exp=sap_6, vpn_exp=vpn_6
		)

		# -----------------------------------------------------------

		print("---------- Src Debug Port 6 Allow----------")
		#print(testutils.format_packet(src_pkt_6))
		logger.info("Sending packet on port %d", ig_port_6)
		testutils.send_packet(self, ig_port_6, src_pkt_6)

		# -----------------------------------------------------------

		print("---------- Exp Debug Port 6 Allow----------")
		#print(testutils.format_packet(exp_pkt_6))
		logger.info("Verify packet on port %d", eg_port_6)
		testutils.verify_packets(self, exp_pkt_6, [eg_port_6])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		src_pkt_6, exp_pkt_6 = npb_simple_1lyr_udp(
			dmac_nsh=dmac_6, smac_nsh=smac_6, spi=spi_6, si=si_6, sap=sap_6, vpn=vpn_6, ttl=63, scope=1,
			#pktlen=512,
			vn_en=False, e_en=False, 
			sf_bitmask=sf_bitmask_6, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			#pktlen_exp=252,
			spi_exp=spi_6, si_exp=si_6, sap_exp=sap_6, vpn_exp=vpn_6
		)

		# -----------------------------------------------------------

		print("---------- Src Debug Port 6 Drop----------")
		#print(testutils.format_packet(src_pkt_6))
		logger.info("Sending packet on port %d", ig_port_6)
		testutils.send_packet(self, ig_port_6, src_pkt_6)

		# -----------------------------------------------------------

		print("---------- Exp Debug Port 6 drop----------")
		#print(testutils.format_packet(exp_pkt_6))
		#logger.info("Verify packet on port %d", eg_port_6)
		#testutils.verify_packets(self, exp_pkt_6, [eg_port_6])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)



		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf)

		'''
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf)
		'''

		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf)

		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf)

		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf)

		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf)

		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf)




		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf, terminate=0)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, terminate=1)

		'''
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, terminate=0)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, terminate=0)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, terminate=1)
		'''

		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, terminate=0)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, terminate=1)

		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, terminate=0)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, terminate=1)

		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, terminate=0)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, terminate=1)

		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, terminate=0)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, terminate=1)

		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf, terminate=1)
		npb_npb_sf2_policy_l2_add(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf, terminate=0)



		# -----------------------------------------------------------
		# Port 0 - 1 Lyr UDP Vlan Terminate
		# -----------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			#pktlen=512,
			vn_en=False, e_en=False, 
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			#pktlen_exp=252,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)


		# -----------------------------------------------------------

		print("---------- Src Debug Port 0 Terminate----------")
		#print(testutils.format_packet(src_pkt))
		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		print("---------- Exp Debug Port 0 Terminate----------")
		#print(testutils.format_packet(exp_pkt))
		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)

		src_pkt_1, exp_pkt_1 = npb_simple_2lyr_ipinip(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			#pktlen=512,
			vn_en=False, e_en=False, 
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[1],
			#pktlen_exp=252,
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)
#		src_pkt, exp_pkt = npb_simple_2lyr_vxlan_udp(
#			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
#			#pktlen=512,
#			vn_en=False, e_en=False, 
#			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[1],
#			#pktlen_exp=252,
#			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
#		)


		# -----------------------------------------------------------

		print("---------- Src Debug Port 0 Terminate----------")
		#print(testutils.format_packet(src_pkt))
		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, src_pkt)

		# -----------------------------------------------------------

		print("---------- Exp Debug Port 0 Terminate----------")
		#print(testutils.format_packet(exp_pkt))
		logger.info("Verify packet on port %d", eg_port)
		testutils.verify_packets(self, exp_pkt, [eg_port])

		logger.info("Verify no other packets")
		testutils.verify_no_other_packets(self, 0, 1)






		# -----------------------------------------------------------
		# Delete Table Entries
		# -----------------------------------------------------------
		npb_nsh_chain_start_del(self, self.target,
			#ingress
			[ig_port], ig_lag_ptr, spi, si, sf_bitmask, rmac, nexthop_ptr, eg_lag_ptr, 0, 0, [eg_port],
			#tunnel
			tunnel_encap_ptr, tunnel_encap_nexthop_ptr, tunnel_encap_bd, tunnel_encap_smac_ptr
			#egress
		)
		'''
		npb_nsh_chain_start_del(self, self.target,
			#ingress
			[ig_port_1], ig_lag_ptr_1, spi_1, si_1, sf_bitmask_1, rmac, nexthop_ptr_1, eg_lag_ptr_1, 1, 1, [eg_port_1],
			#tunnel
			tunnel_encap_ptr_1, tunnel_encap_nexthop_ptr_1, tunnel_encap_bd_1, tunnel_encap_smac_ptr_1
			#egress
		)
		'''
		npb_nsh_chain_start_del(self, self.target,
			#ingress
			[ig_port_2], ig_lag_ptr_2, spi_2, si_2, sf_bitmask_2, rmac, nexthop_ptr_2, eg_lag_ptr_2, 2, 2, [eg_port_2],
			#tunnel
			tunnel_encap_ptr_2, tunnel_encap_nexthop_ptr_2, tunnel_encap_bd_2, tunnel_encap_smac_ptr_2
			#egress
		)
		npb_nsh_chain_start_del(self, self.target,
			#ingress
			[ig_port_3], ig_lag_ptr_3, spi_3, si_3, sf_bitmask_3, rmac, nexthop_ptr_3, eg_lag_ptr_3, 3, 3, [eg_port_3],
			#tunnel
			tunnel_encap_ptr_3, tunnel_encap_nexthop_ptr_3, tunnel_encap_bd_3, tunnel_encap_smac_ptr_3
			#egress
		)
		npb_nsh_chain_start_del(self, self.target,
			#ingress
			[ig_port_4], ig_lag_ptr_4, spi_4, si_4, sf_bitmask_4, rmac, nexthop_ptr_4, eg_lag_ptr_4, 4, 4, [eg_port_4],
			#tunnel
			tunnel_encap_ptr_4, tunnel_encap_nexthop_ptr_4, tunnel_encap_bd_4, tunnel_encap_smac_ptr_4
			#egress
		)
		npb_nsh_chain_start_del(self, self.target,
			#ingress
			[ig_port_5], ig_lag_ptr_5, spi_5, si_5, sf_bitmask_5, rmac, nexthop_ptr_5, eg_lag_ptr_5, 5, 5, [eg_port_5],
			#tunnel
			tunnel_encap_ptr_5, tunnel_encap_nexthop_ptr_5, tunnel_encap_bd_5, tunnel_encap_smac_ptr_5
			#egress
		)
		npb_nsh_chain_start_del(self, self.target,
			#ingress
			[ig_port_6], ig_lag_ptr_6, spi_6, si_6, sf_bitmask_6, rmac, nexthop_ptr_6, eg_lag_ptr_6, 6, 6, [eg_port_6],
			#tunnel
			tunnel_encap_ptr_6, tunnel_encap_nexthop_ptr_6, tunnel_encap_bd_6, tunnel_encap_smac_ptr_6
			#egress
		)


		# -----------------
		# Egress SF(s)
		# -----------------




		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf)
#		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf)

		'''
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf)
#		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_1, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf)
		'''

		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf)
#		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_2, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf)

		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf)
#		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_3, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf)

		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf)
#		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_4, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf)

		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf)
#		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_5, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf)

		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.NONE.value,   tun_type_mask=0xf)
#		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.VXLAN.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.IPINIP.value, tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.NVGRE.value,  tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.GRE.value,    tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.GTPC.value,   tun_type_mask=0xf)
		npb_npb_sf2_policy_l2_del(self, self.target, dsap=dsap_6, tun_type=IngressTunnelType.GTPU.value,   tun_type_mask=0xf)

