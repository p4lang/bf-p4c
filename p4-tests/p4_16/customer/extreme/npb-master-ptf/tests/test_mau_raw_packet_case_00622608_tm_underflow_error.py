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

		loop_count = 1

		ig_port_cpu   = swports[0] # cpu tx port
		eg_port_cpu   = swports[0] # cpu tx port
		ig_port_cpu_2 = swports[1] # cpu rx port
		eg_port_cpu_2 = swports[1] # cpu rx port
		ig_port       = swports[3] # front panel port
		eg_port       = swports[3] # front panel port

		# -----------------------
		# Packet values to use
		# -----------------------

		smac = '11:11:11:11:11:11'
		dmac = '22:22:22:22:22:22'
		dmac2 = '00:00:01:00:00:01'
		sip = "0.0.0.3"
		dip = "0.0.0.4"

		rmac = '33:33:33:33:33:33'

		# -----------------------
		# NSH values to use
		# -----------------------

#		sap                     = 0xc # Arbitrary value
		sap                     = 0x1 # Arbitrary value
		vpn                     = 0x0 # Arbitrary value
		flow_class_acl          = 2 # Arbitrary value
		flow_class_sfp          = 3 # Arbitrary value
#		spi                     = 0x4 # Arbitrary value
#		si                      = 0x5 # Arbitrary value (ttl)
		spi                     = 0x6000 # Arbitrary value
		si                      = 0x5 # Arbitrary value (ttl)
#		sfc                     = 0xd # Arbitrary value
		sfc                     = 0x10 # Arbitrary value
		dsap                    = 7 # Arbitrary value

		sf_bitmask              = 1 # Bit 0 = ingress, bit 1 = multicast, bit 2 = egress

		nexthop_ptr             = 0x65 # Arbitrary value
####		vid                     = 0 # Arbitrary value
		vid                     = 0xc8 # Arbitrary value
		bd                      = 2 # Arbitrary value
		ig_lag_ptr              = 3 # Arbitrary value
#		eg_lag_ptr              = 0x10 # Arbitrary value
		eg_lag_ptr              = 0x11a # Arbitrary value
		tunnel_encap_ptr        = 5 # Arbitrary value
		tunnel_encap_nexthop_ptr= 6 # Arbitrary value
		tunnel_encap_bd         = 7 # Arbitrary value
		tunnel_encap_smac_ptr   = 8 # Arbitrary value

		spi_new = 0x8
		si_new  = 0x6

		# -----------------------------------------------------------
		# Insert Table Entries
		# -----------------------------------------------------------

		# cpu to front panel
		npb_nsh_bridge_add(self, self.target,
			#ingress
			[ig_port_cpu], ig_lag_ptr+0, rmac, nexthop_ptr+0, bd, 0x86dd, 0x0000, 0, 0x0, vid, 0x000, dmac2, 0x000000000000, eg_lag_ptr+0, 0+0, 0+0, [eg_port], False
#			[ig_port_cpu], ig_lag_ptr+0, rmac, bd, 5,                                                                 dmac2, eg_lag_ptr+0, 0+0, 0+0, [eg_port]
			#egress
		)

		# front panel to cpu
		npb_nsh_bridge_add(self, self.target,
			#ingress
			[ig_port], ig_lag_ptr+1, rmac, nexthop_ptr+1, bd, 0x86dd, 0x0000, 0, 0x0, vid, 0x000, dmac2, 0x000000000000, eg_lag_ptr+1, 0+1, 0+1, [eg_port_cpu_2], False
#			[ig_port], ig_lag_ptr+1, rmac, bd, 5,                                                                 dmac2, eg_lag_ptr+1, 0+1, 0+1, [eg_port_cpu_2]
			#egress
		)

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

#		src_pkt =           Ether(b'\xaa\xbb\x00\x00\x00\x02\xaa\xbb\x00\x00\x00\x01\x08\x00') # ethernet
#		src_pkt = src_pkt / IP   (b'\x45\x22\x00\x3c\x00\x01\x00\x00\x1f\x11\x21\x08\x09\x13\x5b\x5c\x0a\x0b\x0c\x0d') # ipv4
#		src_pkt = src_pkt / TCP  (b'\x08\x50\x0c\x38\x00\x28\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00') # tcp

#		src_pkt =           Ether(b'\x00\x00\x5e\x00\x01\x01\x34\x41\x5d\x65\xd9\xe8\x08\x00')
#		src_pkt = src_pkt / IP   (b'\x45\x00\x00\x43\x00\x05\x00\x00\x80\x11\xcf\x13\x86\x8d\xbc\x62\x86\x8d\xa2\x14')
#		src_pkt = src_pkt / TCP  (b'\xee\xd7\x00\x35\x00\x2f\x67\xc8\xf9\xf7\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x07\x6f\x75\x74\x6c\x6f\x6f\x6b\x09\x6f\x07\x6f\x75\x74\x6c\x6f\x6f\x6b\x09\x6f')

#		exp_pkt =           Ether(b'\xaa\xbb\x00\x00\x00\x02\xaa\xbb\x00\x00\x00\x01\x08\x00') # ethernet
#		exp_pkt = exp_pkt / IP   (b'\x45\x22\x00\x3c\x00\x01\x00\x00\x1f\x11\x21\x08\x09\x13\x5b\x5c\x0a\x0b\x0c\x0d') # ipv4
#		exp_pkt = exp_pkt / TCP  (b'\x08\x50\x0c\x38\x00\x28\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00') # tcp

		for n in range(loop_count):
			src_pkt =           Ether(b'\x00\x00\x01\x00\x00\x01\x00\x10\x94\x00\x00\x02\x81\x00\x00\xc8\x86\xdd\x60\x00\x00\x00\x01\x50\x11\xff\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x8d\xfb\x12\xb5\x01\x50\xed\xab\x08\x00\x00\x00\x00\x00\x1e\x00\x08\x00\x01\x00\x00\x01\x08\x10\x94\x00\x00\x02\x86\xdd\x60\x00\x00\x00\x01\x0a\x06\xff\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x04\xf0\x04\x00\x00\x01\xe2\x40\x00\x03\x94\x47\x50\x10\x10\x00\xa6\xf8\x00\x00\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\x00\xab\xba\xab\xff\xca\xce\x6d\x8f\x33')
			exp_pkt = src_pkt

			# send packet from cpu to front panel

			logger.info("Sending packet on port %d", ig_port_cpu)
			testutils.send_packet(self, ig_port_cpu, src_pkt)

			# receive packet at front panel and send it back in front panel

			logger.info("Verify packet on port %d", eg_port)
			testutils.verify_packets(self, exp_pkt, [eg_port])

			logger.info("Verify no other packets")
			testutils.verify_no_other_packets(self, 0, 1)

			logger.info("Sending packet on port %d", ig_port)
			testutils.send_packet(self, ig_port, src_pkt)

			# receive packet from front panel to cpu

			logger.info("Verify packet on port %d", eg_port_cpu_2)
			testutils.verify_packets(self, exp_pkt, [eg_port_cpu_2])

			logger.info("Verify no other packets")
			testutils.verify_no_other_packets(self, 0, 1)

		# -----------------------------------------------------------
		# Delete Table Entries
		# -----------------------------------------------------------

		# cpu to front panel
		npb_nsh_bridge_del(self, self.target,
			#ingress
			[ig_port_cpu], ig_lag_ptr+0, rmac, nexthop_ptr+0, 0x86dd, 0x0000, 0, 0x0, vid, 0x000, dmac2, 0x000000000000, eg_lag_ptr+0, 0+0, 0+0, [eg_port]
#			[ig_port_cpu], ig_lag_ptr+0, rmac, bd, 5,                                                             dmac2, eg_lag_ptr+0, 0+0, 0+0, [eg_port]
			#egress
		)

		# front panel to cpu
		npb_nsh_bridge_del(self, self.target,
			#ingress
			[ig_port], ig_lag_ptr+1, rmac, nexthop_ptr+1, 0x86dd, 0x0000, 0, 0x0, vid, 0x000, dmac2, 0x000000000000, eg_lag_ptr+1, 0+1, 0+1, [eg_port_cpu_2]
#			[ig_port], ig_lag_ptr+1, rmac, bd, 5,                                                             dmac2, eg_lag_ptr+1, 0+1, 0+1, [eg_port_cpu_2]
			#egress
		)
