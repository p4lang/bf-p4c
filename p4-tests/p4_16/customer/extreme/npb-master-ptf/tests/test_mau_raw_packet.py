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

		sap                     = 0xc # Arbitrary value
		vpn                     = 0x0 # Arbitrary value
		flow_class_acl          = 2 # Arbitrary value
		flow_class_sfp          = 3 # Arbitrary value
		spi                     = 0x4 # Arbitrary value
		si                      = 0x5 # Arbitrary value (ttl)
		sfc                     = 0xd # Arbitrary value
		dsap                    = 7 # Arbitrary value

		sf_bitmask              = 7 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

		nexthop_ptr             = 0x65 # Arbitrary value
		bd                      = 1 # Arbitrary value
		ig_lag_ptr              = 2 # Arbitrary value
		eg_lag_ptr              = 0x10 # Arbitrary value
		tunnel_encap_ptr        = 4 # Arbitrary value
		tunnel_encap_nexthop_ptr= 5 # Arbitrary value
		tunnel_encap_bd         = 6 # Arbitrary value
		tunnel_encap_smac_ptr   = 7 # Arbitrary value

		spi_new = 0x8
		si_new  = 0x6

		# -----------------------------------------------------------
		# Insert Table Entries
		# -----------------------------------------------------------

		npb_nsh_chain_start_end_add(self, self.target,
			#ingress
			[ig_port], ig_lag_ptr, 0, sap, vpn, spi, si, sf_bitmask, rmac, nexthop_ptr, bd, eg_lag_ptr, 0, 0, [eg_port], 0, dsap
			#tunnel
#			tunnel_encap_ptr, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr, tunnel_encap_bd, dmac, tunnel_encap_smac_ptr, smac
			#egress
		)

		npb_nsh_chain_start_end_add(self, self.target,
			#ingress
			[ig_port+8], ig_lag_ptr, 0, sap, vpn, spi_new, si_new, sf_bitmask, rmac, nexthop_ptr, bd, eg_lag_ptr, 0, 0, [eg_port+8], 0, dsap
			#tunnel
#			tunnel_encap_ptr, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr, tunnel_encap_bd, dmac, tunnel_encap_smac_ptr, smac
			#egress
		)

		# -----------------
		# Ingress SF(s)
		# -----------------

		npb_npb_sf0_policy_l34_v4_add(self, self.target, sap=sap, l3_proto=0x11, l3_proto_mask=0xff, flow_class=flow_class_acl, sfc_enable=1, sfc=sfc)

		# -----------------
		# Ingress SFP Sel
		# -----------------

		npb_npb_sfp_sel_add(self, self.target, vpn, flow_class_sfp, sfc, 0, 0, [spi_new], [si_new], [sf_bitmask])

		# -----------------

#		time.sleep(1)

		# -----------------------------------------------------------
		# Create / Send / Verfiy the packet
		# -----------------------------------------------------------

		'''
		src_pkt, exp_pkt = npb_simple_2lyr_vxlan_udp(
			dmac_nsh=dmac, smac_nsh=smac, spi=spi, si=si, sap=sap, vpn=vpn, ttl=63, scope=1,
			sf_bitmask=sf_bitmask, start_of_chain=True, end_of_chain=False, scope_term_list=[0],
			spi_exp=spi, si_exp=si, sap_exp=sap, vpn_exp=vpn
		)
		'''

#		src_pkt =           Ether('\xaa\xbb\x00\x00\x00\x02\xaa\xbb\x00\x00\x00\x01\x08\x00') # ethernet
#		src_pkt = src_pkt / IP   ('\x45\x22\x00\x3c\x00\x01\x00\x00\x1f\x11\x21\x08\x09\x13\x5b\x5c\x0a\x0b\x0c\x0d') # ipv4
#		src_pkt = src_pkt / TCP  ('\x08\x50\x0c\x38\x00\x28\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00') # tcp

		src_pkt =           Ether('\x00\x00\x5e\x00\x01\x01\x34\x41\x5d\x65\xd9\xe8\x08\x00')
		src_pkt = src_pkt / IP   ('\x45\x00\x00\x43\x00\x05\x00\x00\x80\x11\xcf\x13\x86\x8d\xbc\x62\x86\x8d\xa2\x14')
		src_pkt = src_pkt / TCP  ('\xee\xd7\x00\x35\x00\x2f\x67\xc8\xf9\xf7\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x07\x6f\x75\x74\x6c\x6f\x6f\x6b\x09\x6f\x07\x6f\x75\x74\x6c\x6f\x6f\x6b\x09\x6f')

#		exp_pkt =           Ether('\xaa\xbb\x00\x00\x00\x02\xaa\xbb\x00\x00\x00\x01\x08\x00') # ethernet
#		exp_pkt = exp_pkt / IP   ('\x45\x22\x00\x3c\x00\x01\x00\x00\x1f\x11\x21\x08\x09\x13\x5b\x5c\x0a\x0b\x0c\x0d') # ipv4
#		exp_pkt = exp_pkt / TCP  ('\x08\x50\x0c\x38\x00\x28\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00') # tcp

		exp_pkt = src_pkt

		# -----------------------------------------------------------

		logger.info("Sending packet on port %d", ig_port)
		testutils.send_packet(self, ig_port, str(src_pkt))

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
			[ig_port], ig_lag_ptr, spi, si, sf_bitmask, rmac, nexthop_ptr, eg_lag_ptr, 0, 0, 1, [eg_port]
			#tunnel
#			tunnel_encap_ptr, tunnel_encap_nexthop_ptr, tunnel_encap_bd, tunnel_encap_smac_ptr
			#egress
		)

		npb_nsh_chain_start_end_del(self, self.target,
			#ingress
			[ig_port+8], ig_lag_ptr, spi_new, si_new, sf_bitmask, rmac, nexthop_ptr, eg_lag_ptr, 0, 0, 1, [eg_port+8]
			#tunnel
#			tunnel_encap_ptr, tunnel_encap_nexthop_ptr, tunnel_encap_bd, tunnel_encap_smac_ptr
			#egress
		)

		# -----------------
		# Ingress SF(s)
		# -----------------

		npb_npb_sf0_policy_l34_v4_del(self, self.target, sap=sap, l3_proto=0x11, l3_proto_mask=0xff)

		# -----------------
		# Ingress SFP Sel
		# -----------------

		npb_npb_sfp_sel_del(self, self.target, vpn, sfc, 0, 0, 1)
