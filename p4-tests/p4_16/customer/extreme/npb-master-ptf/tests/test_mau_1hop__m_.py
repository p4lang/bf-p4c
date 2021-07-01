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

		rmac = dmac

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

		sf_bitmask              = 0 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

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

		npb_nsh_chain_middle_add(self, self.target,
			#ingress
			[ig_port], ig_lag_ptr, 0, ta, spi, si, sf_bitmask, rmac, nexthop_ptr, bd, eg_lag_ptr, 0, 0, [eg_port], 0, dsap,
			#tunnel
			tunnel_encap_ptr, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr, tunnel_encap_bd, dmac, tunnel_encap_smac_ptr, smac
			#egress
		)

		# -----------------

#		time.sleep(1)

		# -----------------------------------------------------------
		# Create / Send / Verify the packet
		# -----------------------------------------------------------

		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac, smac_nsh=smac, ta=ta, spi=spi, si=si, nshtype=2, sap=sap, vpn=vpn, ttl=63, scope=1,
			sf_bitmask=sf_bitmask, start_of_chain=False, end_of_chain=False, scope_term_list=[],
			spi_exp=spi, si_exp=si, ta_exp=ta, nshtype_exp=2, sap_exp=sap, vpn_exp=vpn
		)

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

		npb_nsh_chain_middle_del(self, self.target,
			#ingress
			[ig_port], ig_lag_ptr, ta, spi, si, sf_bitmask, rmac, nexthop_ptr, eg_lag_ptr, 0, 0, 1, [eg_port],
			#tunnel
			tunnel_encap_ptr, tunnel_encap_nexthop_ptr, tunnel_encap_bd, tunnel_encap_smac_ptr
			#egress
		)
