import logging
import sys
import os
import random
import re
from pprint import pprint

####### PTF MODULE IMPORTS #######
import ptf
from   ptf.mask import Mask
#from   ptf.testutils import *
import ptf.testutils as testutils
#from   scapy.all     import *
import ptf.packet    as scapy

####### PTF modules for BFRuntime Client Library APIs #######
import grpc
import bfrt_grpc.bfruntime_pb2 as bfruntime_pb2
import bfrt_grpc.client        as gc
from   bfruntime_client_base_tests import BfRuntimeTest

####### PTF modules for Fixed APIs (Thrift) #######
import pd_base_tests
from   ptf.thriftutils import *
from   res_pd_rpc      import * # Common data types
from   mc_pd_rpc       import * # Multicast-specific data types
from   mirror_pd_rpc   import * # Mirror-specific data types

####### Additional imports #######
import pdb # To debug insert pdb.set_trace() anywhere

from struct import pack
from struct import unpack

from test_mau_tb_shared import *

################################################################################
################################################################################
################################################################################
# NPB Model
################################################################################
################################################################################
################################################################################

################################################################################
# Helper Utilities
################################################################################

def npb_model_mac_encap(
	# transport ethernet variables
	dmac     = '00:01:02:03:04:05',
	smac     = '00:06:07:08:09:0a',
	vlan_en  = False,
	vlan_pcp = 0,
	vlan_vid = 0,

	# transport nsh variables
	spi      = 0, 
	si       = 0,
	ta       = 0,
	nshtype  = 2,  
	scope    = 0,
	sap      = 0,
	vpn      = 0,
	ttl      = 63, # new packets will have a value of 63

	#outer variables
	src_pkt_base = None
	):

	# -----------------
	# debug routine to print all the packet layers
	# -----------------
#	counter = 0
#	while True:
#		layer = src_pkt_inner.getlayer(counter)
#		if layer is None:
#			break
#		print layer.name,
#		counter += 1

	# -----------------
	# build packet
	# -----------------
	
	if(vlan_en == True):
		if(nshtype == 1):
			pkt = \
				testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x8100) / \
				scapy.Dot1Q(prio=vlan_pcp, id=0, vlan=vlan_vid,  type=0x894f) / \
				scapy.NSH(mdtype=1, nextproto=3, spi=ta, si=1, ttl=ttl, \
					datatype=nshtype, \
					vpn=vpn, \
					scope=scope, ssap=sap, \
#                   context_header0=(nshtype<<24).to_bytes(4, byteorder='big'), \
#                   context_header1=(vpn<<16).to_bytes(4, byteorder='big'), \
#                   context_header2=((scope<<16)|(sap<<0)).to_bytes(4, byteorder='big')
				) / \
				src_pkt_base
		else:
			pkt = \
				testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x8100) / \
				scapy.Dot1Q(prio=vlan_pcp, id=0, vlan=vlan_vid,  type=0x894f) / \
				scapy.NSH(mdtype=1, nextproto=3, spi=spi, si=si, ttl=ttl, \
					datatype=2, \
					vpn=vpn, \
					scope=scope, ssap=sap, \
#                   context_header0=(2<<24).to_bytes(4, byteorder='big'), \
#                   context_header1=(vpn<<16).to_bytes(4, byteorder='big'), \
#                   context_header2=((scope<<16)|(sap<<0)).to_bytes(4, byteorder='big')
				) / \
				src_pkt_base
	else:
		if(nshtype == 1):
			pkt = \
				testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x894f) / \
				scapy.NSH(mdtype=1, nextproto=3, spi=ta, si=1, ttl=ttl, \
					datatype=nshtype, \
					vpn=vpn, \
					scope=scope, ssap=sap, \
#                   context_header0=(nshtype<<24).to_bytes(4, byteorder='big'), \
#                   context_header1=(vpn<<16).to_bytes(4, byteorder='big'), \
#                   context_header2=((scope<<16)|(sap<<0)).to_bytes(4, byteorder='big')
				) / \
				src_pkt_base
		else:
			pkt = \
				testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x894f) / \
				scapy.NSH(mdtype=1, nextproto=3, spi=spi, si=si, ttl=ttl, \
					datatype=2, \
					vpn=vpn, \
					scope=scope, ssap=sap, \
#                   context_header0=(2<<24).to_bytes(4, byteorder='big'), \
#                   context_header1=(vpn<<16).to_bytes(4, byteorder='big'), \
#                   context_header2=((scope<<16)|(sap<<0)).to_bytes(4, byteorder='big')
				) / \
				src_pkt_base

	# -----------------

	return pkt


################################################################################

def npb_model_gre_encap_v4(
	# transport ethernet variables
	dmac     = '00:01:02:03:04:05',
	smac     = '00:06:07:08:09:0a',
	vlan_en  = False,
	vlan_pcp = 0,
	vlan_vid = 0,

	#outer variables
	src_pkt_inner = None
	):

	# -----------------
	# find the first ip layer
	# -----------------
	counter = 0
	while True:
		layer = src_pkt_inner.getlayer(counter)
		if layer is None:
			break
#		print layer.name,
		counter += 1

		if(layer.name == 'IP'):
			src_pkt_inner = src_pkt_inner[IP] # remove the Ether layer, if packet has one
			break
		elif(layer.name == 'IPv6'):
			src_pkt_inner = src_pkt_inner[IPv6] # remove the Ether layer, if packet has one
			break

	# -----------------
	# build packet
	# -----------------

	pkt = testutils.simple_gre_packet(eth_dst=dmac, eth_src=smac, dl_vlan_enable=vlan_en, vlan_pcp=vlan_pcp, vlan_vid=vlan_vid, ip_flags=2, ip_id=0, inner_frame=src_pkt_inner)

	# -----------------

	# add a mask to the packet
	pkt_masked = Mask(pkt)

	# -----------------

	return pkt

################################################################################

def npb_model_gre_encap_v6(
	# transport ethernet variables
	dmac     = '00:01:02:03:04:05',
	smac     = '00:06:07:08:09:0a',
	vlan_en  = False,
	vlan_pcp = 0,
	vlan_vid = 0,

	#outer variables
	src_pkt_inner = None
	):

	# -----------------
	# find the first ip layer
	# -----------------
	counter = 0
	while True:
		layer = src_pkt_inner.getlayer(counter)
		if layer is None:
			break
#		print layer.name,
		counter += 1

		if(layer.name == 'IP'):
			src_pkt_inner = src_pkt_inner[IP] # remove the Ether layer, if packet has one
			break
		elif(layer.name == 'IPv6'):
			src_pkt_inner = src_pkt_inner[IPv6] # remove the Ether layer, if packet has one
			break

	# -----------------
	# build packet
	# -----------------

	pkt = testutils.simple_grev6_packet(eth_dst=dmac, eth_src=smac, dl_vlan_enable=vlan_en, vlan_pcp=vlan_pcp, vlan_vid=vlan_vid, inner_frame=src_pkt_inner)

	# -----------------

	# add a mask to the packet
	pkt_masked = Mask(pkt)

	# -----------------

	return pkt

################################################################################

def npb_model_dtel_flow_report(
	# transport ethernet variables
	dmac     = '00:01:02:03:04:05',
	smac     = '00:06:07:08:09:0a',
	vlan_en  = False,
	vlan_pcp = 0,
	vlan_vid = 0,
	#pktlen   = 100,
	#tos      = 0,
	#sip      = '11.22.33.44',
	#dip      = '55.66.77.88',
	ig_port   = 0,
	eg_port   = 0,
	qid       = 0,

	#outer variables
	src_pkt_base = None
	):

	# -----------------
	# build packet
	# -----------------

#Report Length (8b): Indicates the length of the Individual Report Header in a multiple of 4-byte words, including
#the Individual Report Main Contents and Individual Report Inner Contents, but excluding the
#length of the first 4-byte word (RepType, InType, Report Length, MD Length, D, Q, F, I, Rsvd).
#For RepType codepoint 1 INT, the Report Length includes the lengths of RepMdBits, Domain
#Specific ID, DSMdBits, DSMdstatus, Variable Optional Baseline Metadata, and Variable
#Optional Domain Specific Metadata (see Section 3.3.1).
#The Report Length value 0xFF is a special value that indicates a length greater than or equal
#to 0xFF, extending to the end of the UDP payload, i.e. there are no subsequent individual
#reports in this telemetry report.
#MD Length (8b): Metadata Length
#Indicates the length of metadata included in this report in a multiple of 4-byte words. This may
#help the telemetry monitoring system determine where the Individual Report Inner Contents
#begins. Note that this does not include the length of the fixed portion of the Individual Report
#Main Contents.
#For RepType codepoint 1 INT, this includes the length of the Variable Optional Baseline
#Metadata and Variable Optional Domain Specific Metadata in 4-byte words (see Section 3.3.1).
#D (1b): Dropped: Indicates that at least one packet matching a watchlist was dropped.
#Q (1b): Congested Queue Association: Indicates the presence of congestion on a monitored queue.
#F (1b): Tracked Flow Association :Indicates that this telemetry report is for a tracked flow, i.e. the packet matched a watchlist
#somewhere (in case of INT-MD, INT-MX or IOAM) or locally (in case of INT-XD). The report
#might include INT-MD or IOAM metadata in the truncated packet. Other telemetry reports
#are likely to be received for the same tracked flow, from the same node and (in case of drop
#reports, INT-MX, INT-XD or path changes) from other nodes.


	#pkt = testutils.simple_udp_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen_exp, ip_src=sip, ip_dst=dip, ip_tos=tos, udp_sport=udp_sport, udp_dport=udp_dport) / src_pkt_inner 
	#Hardcode these values until I figure out how the pipe is setting them.
#	pkt = testutils.simple_udp_packet(pktlen=42, eth_dst=dmac, eth_src=smac, ip_src='11.22.33.44', ip_dst='55.66.77.88', ip_tos=0, udp_sport=0x1234, udp_dport=0x80, ip_flag=2, ip_id=0, with_udp_chksum=0) / \
	pkt = testutils.simple_udp_packet(pktlen=42, eth_dst=dmac, eth_src=smac,                                             ip_tos=0, udp_sport=0,      udp_dport=0,    ip_flag=2, ip_id=0, with_udp_chksum=0) / \
		scapy.DTEL(version=2, hw_id=0, seq_number=1, report_length=0x1300, d_q_f=1, ingress_port=ig_port, egress_port=eg_port, queue_id=qid, queue_occupancy=0x1234) / \
		src_pkt_base 

	# -----------------

	# add a mask to the packet
	pkt_masked = Mask(pkt)

	# -----------------

	return pkt

################################################################################
# NPB Model
################################################################################

def npb_model(
	# possible result packets
	exp_pkt_base        = [], # becomes packet out if 0 decaps happen

	# nsh values
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,  
	sap_exp        = None,
	vpn_exp        = None,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	# model flags
	bridged_pkt    = False,
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list= [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,

	# encap values
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh_exp= None,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	ig_port        = 0,
	eg_port        = 0,
	qid            = 0
	):

	# -------------------------------
	# NPB Model
	# - an extremely crude model of what happens in the chip.
	# - works different than the chip...this is more of a parse-as-you-go
	#   design (decaps pop things off...there are no predefined 'slots').
	# -------------------------------

	model_pkt     = exp_pkt_base.pop(0)

	if(bridged_pkt == False):

		# --------------------------

		# transport term

		if(transport_decap == True):
			model_pkt     = exp_pkt_base.pop(0)

		# --------------------------

		# decrement ttl

		if(start_of_chain == False):
			ttl = ttl - 1

		# --------------------------

		# emulate all the service functions (terms, scopes, and updating the si)

		si_exp = si_exp-(popcount(sf_bitmask))

		term = 0
		for i in scope_term_list:
			# iterate through scopes and terminates
			if(i == 0):
				# got a scope
				scope = scope + 1;       # increment scope
			elif(i == 1):
				# got a terminate
				term = term + 1 + (scope-1); # increment terminate
				scope = 1;               # reset scope

		for i in range(term):
			model_pkt     = exp_pkt_base.pop(0)

	# --------------------------

	# transport encap

	# note: we also add the mask to the packet here.  we do this last because
	# we can't manipulate the mask in scapy like we can the packet (encap,
	# decap, etc).  so we have no choice but to add it at the end.  we add a
	# mask to all packets, whether they need it or not -- having all packets
	# be the same format makes them easier to deal with...

	if(end_of_chain == False):
		transport_encap = EgressTunnelType.NSH.value

	if(transport_encap == EgressTunnelType.NSH.value):
		# encap with mac+nsh
		model_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, ta_exp, nshtype_exp, scope, sap_exp, vpn_exp, ttl, model_pkt)

		# add a mask to the packet
		model_pkt = Mask(model_pkt)
		model_pkt.set_do_not_care_scapy(NSH, 'laghash')
		model_pkt.set_do_not_care_scapy(NSH, 'timestamp')
	elif(transport_encap == EgressTunnelType.IPV4_GRE.value):
		# encap with gre
		model_pkt = npb_model_gre_encap_v4(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, model_pkt)

		# add a mask to the packet
		model_pkt = Mask(model_pkt)
	elif(transport_encap == EgressTunnelType.IPV6_GRE.value):
		# encap with gre
		model_pkt = npb_model_gre_encap_v6(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, model_pkt)

		# add a mask to the packet
		model_pkt = Mask(model_pkt)
	elif(transport_encap == EgressTunnelType.DTEL_FLOW_REPORT.value):
		# encap with DTelv2_flow_report
		model_pkt = npb_model_dtel_flow_report(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh,	ig_port, eg_port, qid, model_pkt)

		# add a mask to the packet
		model_pkt = Mask(model_pkt)

		# are there other fields we can't easily predict?
		model_pkt.set_do_not_care_scapy(DTEL, 'seq_number')
		model_pkt.set_do_not_care_scapy(DTEL, 'queue_occupancy')
		model_pkt.set_do_not_care_scapy(DTEL, 'ingress_timestamp')
		model_pkt.set_do_not_care_scapy(DTEL, 'egress_timestamp')
	else:
		# add a mask to the packet
		model_pkt = Mask(model_pkt)

	# --------------------------

	return model_pkt

################################################################################
################################################################################
################################################################################
# CPU Model
################################################################################
################################################################################
################################################################################

def cpu_model(
	result, # the result from ptf's 'testutils.dp_poll' function

	new_src_port_enable = False, # replace the cpu header's source port?
	new_src_port        = 0
	):

	# ----- get the packet -----
#	print(result)
	pkt_hex = result.packet

	print("---------- CPU Pkt In ----------")
	print(testutils.format_packet(result.packet))
	print("---------- CPU Pkt In ----------")

	# ----- extract headers -----

	# extract ethernet header (14 bytes total)
	eth_hdr_1 = unpack('!6s6sH', pkt_hex[:14]) # note, I extract the first da byte separately, so that I can increment below...
	print(eth_hdr_1)

	# extract cpu header (11 bytes total)
	cpu_hdr_1 = unpack('!BHHHHH', pkt_hex[14:14+11])
	print(cpu_hdr_1)

	# extract rest of packet
	rest = pkt_hex[14+11:]

	# ----- modify headers -----

	# modify ethernet header (convert tuple to list, modify, convert list to tuple)
	eth_hdr_1_list = list(eth_hdr_1)
	incremented = int.from_bytes(eth_hdr_1_list[0], "big") + 0x10000000000             # \ increment the first byte of the da 
	eth_hdr_1_list[0] = bytearray(incremented.to_bytes(len(eth_hdr_1_list[0]), 'big')) # /
	eth_hdr_2 = tuple(eth_hdr_1_list)

	# modify cpu header (convert tuple to list, modify, convert list to tuple)
	cpu_hdr_1_list = list(cpu_hdr_1)
#	cpu_hdr_1_list[0] = cpu_hdr_1_list[0] | 0x04 # misc flags         : bypass all egress
	if(new_src_port_enable == True):
		cpu_hdr_1_list[1] = new_src_port         # ing port           : (unchanged?)
	else:
		cpu_hdr_1_list[1] = cpu_hdr_1_list[1]    # ing port           : (unchanged?)
	cpu_hdr_1_list[2] = cpu_hdr_1_list[2]        # egr port/lag index : (unchanged?)
	cpu_hdr_1_list[3] = cpu_hdr_1_list[3]        # igr bd       index : (unchanged?)
#	cpu_hdr_1_list[4] = 0xff                     # ing bypass         : bypass all ingress
	cpu_hdr_1_list[4] = 0xfe                     # ing bypass         : bypass all ingress (except da table)
	cpu_hdr_2 = tuple(cpu_hdr_1_list)

	# ----- reassemble packet -----

	new_hex_pkt = pack('>6s6sH', eth_hdr_2[0], eth_hdr_2[1], eth_hdr_2[2]) + \
	              pack('>BHHHHH', cpu_hdr_2[0], cpu_hdr_2[1], cpu_hdr_2[2], cpu_hdr_2[3], cpu_hdr_2[4], cpu_hdr_2[5]) + \
	              rest

	# reformat the packet
	result2 = Raw(new_hex_pkt)

	# --------------------------

	print("---------- CPU Pkt Out ----------")
	print(testutils.format_packet(result2))
	print("---------- CPU Pkt Out ----------")

	return result2
