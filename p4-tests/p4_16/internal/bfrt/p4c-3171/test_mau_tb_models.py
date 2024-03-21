import logging
import sys
import os
import random
import re
#from pprint import pprint

import scapy
from nsh import *

from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils

from enum import Enum

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
		pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x8100) / \
			scapy.Dot1Q(prio=vlan_pcp, id=0, vlan=vlan_vid,  type=0x894f) / \
			NSH(MDType=1, NextProto=3, NSP=spi, NSI=si, TTL=ttl, \
				NPC=((2<<24) | (0    <<16) |   0), \
				NSC=(          (vpn  <<16) |   0), \
				SPC=(          (scope<<16) | sap), \
				SSC=(                          0), \
			) / \
			src_pkt_base
	else:
		pkt = \
			testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x894f) / \
			NSH(MDType=1, NextProto=3, NSP=spi, NSI=si, TTL=ttl, \
				NPC=((2<<24) | (0    <<16) |   0), \
				NSC=(          (vpn  <<16) |   0), \
				SPC=(          (scope<<16) | sap), \
				SSC=(                          0), \
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
		print(layer.name)
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

	pkt = testutils.simple_gre_packet(eth_dst=dmac, eth_src=smac, dl_vlan_enable=vlan_en, vlan_pcp=vlan_pcp, vlan_vid=vlan_vid, ip_id=0, inner_frame=src_pkt_inner)

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
		print(layer.name)
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
	vlan_vid_nsh   = 0
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
				term = term + 1 + scope; # increment terminate
				scope = 0;               # reset scope

		for i in range(term):
			model_pkt     = exp_pkt_base.pop(0)

	# --------------------------

	# transport encap

	if(end_of_chain == False):
		transport_encap = EgressTunnelType.NSH.value

	if(transport_encap == EgressTunnelType.NSH.value):
		# encap with mac+nsh
		model_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, model_pkt)
	elif(transport_encap == EgressTunnelType.IPV4_GRE.value):
		# encap with gre
		model_pkt = npb_model_gre_encap_v4(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, model_pkt)
	elif(transport_encap == EgressTunnelType.IPV6_GRE.value):
		# encap with gre
		model_pkt = npb_model_gre_encap_v6(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, model_pkt)

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
	result # the result from ptf's 'testutils.dp_poll' function
	):

	# ----- get the packet -----
#	print result
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
	eth_hdr_1_list_da = list(eth_hdr_1_list[0])                # \
	eth_hdr_1_list_da[0] = chr(ord(eth_hdr_1_list_da[0]) + 1)  #  | convert da string to list, increment first byte, convert da list to string
	eth_hdr_1_list[0] = ''.join(eth_hdr_1_list_da)             # /
	eth_hdr_2 = tuple(eth_hdr_1_list)

	# modify cpu header (convert tuple to list, modify, convert list to tuple)
	cpu_hdr_1_list = list(cpu_hdr_1)
	cpu_hdr_1_list[0] = 0x04 & cpu_hdr_1_list[0] # bypass all egress
	cpu_hdr_1_list[4] = 0xff                     # bypass all ingress
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
