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

		sip_v6    = '1111:1112:1113:1114:1115:1116:1117:1118'
		dip_v6    = '2112:2112:2113:2114:2115:2116:2117:2118'

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
			[ig_port_0], ig_lag_ptr_0, 0, sap_0, vpn_0, spi_0, si_0, sf_bitmask_0, rmac, nexthop_ptr_0, bd_0, eg_lag_ptr_0, 0, 0, [eg_port_0], 0,0, dsap_0,
			#tunnel
			tunnel_encap_ptr_0, EgressTunnelType.NSH.value, tunnel_encap_nexthop_ptr_0, tunnel_encap_bd_0, dmac_0, tunnel_encap_smac_ptr_0, smac_0
			#egress
		)

		npb_npb_sf0_len_rng_add(self, self.target,    0x0, 0x1fff, 0) # <  8k
		npb_npb_sf0_len_rng_add(self, self.target, 0x2000, 0xffff, 1) # >= 8k
		
		#L34, V6 UDP, Src Port=1, Dst Port = 1
		npb_npb_sf0_policy_l34_v6_add    (self, self.target, 
			sap=sap_0, vpn=vpn_0, vid=vid_0,
			l3_proto=17, l3_proto_mask=0xff, flow_class=flow_class_acl_0,
			l3_tos=0xe, l3_tos_mask=0xf,
			l3_len_rng=0x0000, l3_len_rng_mask=0xffff,
			l3_sip=sip_v6, l3_sip_mask=0xffffffffffffffffffffffffffffffff,
			l3_dip=dip_v6, l3_dip_mask=0xffffffffffffffffffffffffffffffff,
			l4_src=0x1234, l4_src_mask=0xffff,
			l4_dst=0x5678, l4_dst_mask=0xffff,
			tcp_flags=0x7, tcp_flags_mask=0x0,
			tun_type=IngressTunnelType.NONE.value,  tun_type_mask=0xf,
			tun_id=0, tun_id_mask=0,
			drop=1
		)
		







		#Good Packet (all Keys set) will be dropped
		src_pkt, exp_pkt = npb_simple_1lyr_udpv6(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			sip=sip_v6, dip=dip_v6,tos=0xe, 
			udp_sport=0x1234,  udp_dport=0x5678,tcp_flags=0x7,
			pktlen=1300,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			pktlen_exp=1300,
			spi_exp=spi_0, si_exp=si_0, sap_exp=sap_0, vpn_exp=vpn_0
		)

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)


		
		
		#SIP
		src_pkt, exp_pkt = npb_simple_1lyr_udpv6(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			sip='1111:1112:1113:1114:1115:1116:1117:1110', dip=dip_v6,tos=0xe, 
			udp_sport=0x1234,  udp_dport=0x5678,tcp_flags=0x7,
			pktlen=1300,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			pktlen_exp=1300,
			spi_exp=spi_0, si_exp=si_0, sap_exp=sap_0, vpn_exp=vpn_0
		)

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)
		
		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)

		#DIP
		src_pkt, exp_pkt = npb_simple_1lyr_udpv6(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			sip=sip_v6, dip='1111:1112:1113:1114:1115:1116:1117:1110',tos=0xe, 
			udp_sport=0x1234,  udp_dport=0x5678,tcp_flags=0x7,
			pktlen=1300,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			pktlen_exp=1300,
			spi_exp=spi_0, si_exp=si_0, sap_exp=sap_0, vpn_exp=vpn_0
		)

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)
		
		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)


		#TOS
		src_pkt, exp_pkt = npb_simple_1lyr_udpv6(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			sip=sip_v6, dip=dip_v6,tos=0x7, 
			udp_sport=0x1234,  udp_dport=0x5678,tcp_flags=0x7,
			pktlen=1300,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			pktlen_exp=1300,
			spi_exp=spi_0, si_exp=si_0, sap_exp=sap_0, vpn_exp=vpn_0
		)

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)
		
		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)



		#SPORT
		src_pkt, exp_pkt = npb_simple_1lyr_udpv6(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			sip=sip_v6, dip=dip_v6,tos=0xe, 
			udp_sport=0x1235,  udp_dport=0x5678,tcp_flags=0x7,
			pktlen=1300,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			pktlen_exp=1300,
			spi_exp=spi_0, si_exp=si_0, sap_exp=sap_0, vpn_exp=vpn_0
		)

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)
		
		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)

		#DPORT
		src_pkt, exp_pkt = npb_simple_1lyr_udpv6(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			sip=sip_v6, dip=dip_v6,tos=0xe, 
			udp_sport=0x1234,  udp_dport=0x4678,tcp_flags=0x7,
			pktlen=1300,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			pktlen_exp=1300,
			spi_exp=spi_0, si_exp=si_0, sap_exp=sap_0, vpn_exp=vpn_0
		)

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)
		
		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)

		#IP Len/RngeBMP
		src_pkt, exp_pkt = npb_simple_1lyr_udpv6(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			sip=sip_v6, dip=dip_v6,tos=0xe, 
			udp_sport=0x1234,  udp_dport=0x5678,tcp_flags=0x7,
			pktlen=8300,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			pktlen_exp=8300,
			spi_exp=spi_0, si_exp=si_0, sap_exp=sap_0, vpn_exp=vpn_0
		)

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)
		
		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)
		

		#IPv4		
		src_pkt, exp_pkt = npb_simple_1lyr_udp(
			dmac_nsh=dmac_0, smac_nsh=smac_0, spi=spi_0, si=si_0, sap=sap_0, vpn=vpn_0, ttl=63, scope=1,
			sip=sip_0, dip=dip_0, tos=0xe, 
			udp_sport=0x1234,  udp_dport=0x5678,tcp_flags=0x7,
			pktlen=1300,
			sf_bitmask=sf_bitmask_0, start_of_chain=True, end_of_chain=False, scope_term_list=[],
			pktlen_exp=1300,
			spi_exp=spi_0, si_exp=si_0, sap_exp=sap_0, vpn_exp=vpn_0
		)

		logger.info("Sending packet on port %d", ig_port_0)
		testutils.send_packet(self, ig_port_0, src_pkt)

		logger.info("Verify packet on port %d", eg_port_0)
		testutils.verify_packet(self, exp_pkt, eg_port_0)
		

		#SAP

		#VID

		#TunnelType

		#TunnelID



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
		
		npb_npb_sf0_len_rng_del(self, self.target,    0x0, 0x1fff) # <  8k
		npb_npb_sf0_len_rng_del(self, self.target, 0x2000, 0xffff) # >= 8k

		npb_npb_sf0_policy_l34_v6_del    (self, self.target, 
			sap=sap_0, vpn=vpn_0, vid=vid_0,
			l3_proto=17, l3_proto_mask=0xff,  
			l3_tos=0xe, l3_tos_mask=0xf,
			l3_len_rng=0x0000, l3_len_rng_mask=0xffff,
			l3_sip=sip_v6, l3_sip_mask=0xffffffffffffffffffffffffffffffff,
			l3_dip=dip_v6, l3_dip_mask=0xffffffffffffffffffffffffffffffff,
			l4_src=0x1234, l4_src_mask=0xffff,
			l4_dst=0x5678, l4_dst_mask=0xffff,
			tcp_flags=0x7, tcp_flags_mask=0,
			tun_type=IngressTunnelType.NONE.value,  tun_type_mask=0xf,
			tun_id=0, tun_id_mask=0
		)
		
