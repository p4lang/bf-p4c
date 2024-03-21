import logging
import sys
import os
import random
import re
#from pprint import pprint

from scapy.all import *
import nsh
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils

import codecs

#######################################

def popcount(x): return bin(x).count('1')

################################################################################
# Helper Utilities
################################################################################

def nsh_encap(
	#nsh source variables
	dmac     = '00:01:02:03:04:05',
	smac     = '00:06:07:08:09:0a',
	vlan_en  = False,
	vlan_pcp = 0,
	vlan_vid = 0,
	spi      = 0,
	si       = 0,
	scope    = 0,
	sap      = 0,
	vpn      = 0,
	ttl      = 63, # new packets will have a value of 63

	#pkt source variables
	base_pkt = None):

		# -----------------
		# build packet
		# -----------------

		if(vlan_en == True):
			pkt = \
				testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x8100) / \
				scapy.Dot1Q(prio=vlan_pcp, id=0, vlan=vlan_vid,  type=0x894f) / \
				nsh.NSH(MDType=1, NextProto=3, NSP=spi, NSI=si, TTL=ttl, \
					NPC=((2<<24) | (0    <<16) |   0), \
					NSC=(          (vpn  <<16) |   0), \
					SPC=(          (scope<<16) | sap), \
					SSC=(                          0), \
				) / \
				base_pkt
		else:
			pkt = \
				testutils.simple_eth_packet(pktlen=14, eth_src=smac, eth_dst=dmac, eth_type=0x894f) / \
				nsh.NSH(MDType=1, NextProto=3, NSP=spi, NSI=si, TTL=ttl, \
					NPC=((2<<24) | (0    <<16) |   0), \
					NSC=(          (vpn  <<16) |   0), \
					SPC=(          (scope<<16) | sap), \
					SSC=(                          0), \
				) / \
				base_pkt

		# -----------------

		return pkt

################################################################################
# 1 layer: Simple UDP
################################################################################

def npb_simple_1lyr_udp(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

		if((vlan_en == True) or (e_en == True) or (vn_en == True)):
			# use my version, that adds support for e and vn tags
#			base_pkt = simple_tcp_packet2(eth_dst=dmac, eth_src=smac, pktlen=pktlen, dl_vlan_enable=vlan_en, dot1br=e_en, vn_tag=vn_en)
			base_pkt = simple_udp_packet2(eth_dst=dmac, eth_src=smac, pktlen=pktlen, dl_vlan_enable=vlan_en, dot1br=e_en, vn_tag=vn_en)
		else:
			# user barefoot's version
#			base_pkt = testutils.simple_tcp_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen)
			base_pkt = testutils.simple_udp_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen)

		if((vlan_en_exp == True) or (e_en_exp == True) or (vn_en_exp == True)):
			# use my version, that adds support for e and vn tags
#			base_pkt_exp = simple_tcp_packet2(eth_dst=dmac, eth_src=smac, pktlen=pktlen_exp, dl_vlan_enable=vlan_en_exp, dot1br=e_en_exp, vn_tag=vn_en_exp)
			base_pkt_exp = simple_udp_packet2(eth_dst=dmac, eth_src=smac, pktlen=pktlen_exp, dl_vlan_enable=vlan_en_exp, dot1br=e_en_exp, vn_tag=vn_en_exp)
		else:
			# user barefoot's version
#			base_pkt_exp = testutils.simple_tcp_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen_exp)
			base_pkt_exp = testutils.simple_udp_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen_exp)

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				pass;
			elif(term == 2):
				pass;

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt_exp)
		else:
			exp_pkt = base_pkt_exp

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################

def npb_simple_1lyr_udpv6(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#		base_pkt = testutils.simple_tcpv6_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen, dl_vlan_enable=vlan_en)
		base_pkt = testutils.simple_udpv6_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen, dl_vlan_enable=vlan_en)

#		base_pkt_exp = testutils.simple_tcpv6_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen_exp, dl_vlan_enable=vlan_en_exp)
		base_pkt_exp = testutils.simple_udpv6_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen_exp, dl_vlan_enable=vlan_en_exp)

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				pass;
			elif(term == 2):
				pass;

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt_exp)
		else:
			exp_pkt = base_pkt_exp

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple VXLAN / UDP
################################################################################

def npb_simple_2lyr_vxlan_udp(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#		base_pkt_inner = testutils.simple_tcp_packet()
		base_pkt_inner = testutils.simple_udp_packet()

		base_pkt = testutils.simple_vxlan_packet(eth_dst=dmac, eth_src=smac, inner_frame=base_pkt_inner)

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				base_pkt = base_pkt_inner
			elif(term == 2):
				pass;

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt)
		else:
			exp_pkt = base_pkt

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################

def npb_simple_2lyr_vxlanv6_udpv6(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#		base_pkt_inner = testutils.simple_tcpv6_packet()
		base_pkt_inner = testutils.simple_udpv6_packet()

		base_pkt = testutils.simple_vxlanv6_packet(eth_dst=dmac, eth_src=smac, inner_frame=base_pkt_inner)

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				base_pkt = base_pkt_inner
			elif(term == 2):
				pass;

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt)
		else:
			exp_pkt = base_pkt

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple NVGRE / UDP
################################################################################

def npb_simple_2lyr_nvgre_udp(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#		base_pkt_inner = testutils.simple_tcp_packet()
		base_pkt_inner = testutils.simple_udp_packet()

		base_pkt = testutils.simple_nvgre_packet(eth_dst=dmac, eth_src=smac, inner_frame=base_pkt_inner)

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				base_pkt = base_pkt_inner
			elif(term == 2):
				pass;

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt)
		else:
			exp_pkt = base_pkt

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple GRE / IP
################################################################################

def npb_simple_2lyr_gre_ip(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#		base_pkt_inner = testutils.simple_tcp_packet()
#		base_pkt_inner = testutils.simple_udp_packet()
		base_pkt_inner = testutils.simple_ip_only_packet()

		base_pkt = testutils.simple_gre_packet(eth_dst=dmac, eth_src=smac, inner_frame=base_pkt_inner)

		base_pkt_inner_exp = testutils.simple_tcp_packet(eth_dst=dmac, eth_src=smac, pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				base_pkt = base_pkt_inner_exp
			elif(term == 2):
				pass;

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt)
		else:
			exp_pkt = base_pkt

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple IP / IP
################################################################################

def npb_simple_2lyr_ipinip(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#		base_pkt_inner = testutils.simple_tcp_packet()
#		base_pkt_inner = testutils.simple_udp_packet()
		base_pkt_inner = testutils.simple_ip_only_packet()

		base_pkt = testutils.simple_ipv4ip_packet(eth_dst=dmac, eth_src=smac, inner_frame=base_pkt_inner);

		base_pkt_inner_exp = testutils.simple_tcp_packet(eth_dst=dmac, eth_src=smac, pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				base_pkt = base_pkt_inner_exp
			elif(term == 2):
				pass;

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt)
		else:
			exp_pkt = base_pkt

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple GTP-C / UDP
################################################################################

def npb_simple_2lyr_gtpc_udp(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#		base_pkt_inner = testutils.simple_tcp_packet()
		base_pkt_inner = testutils.simple_udp_packet()

		base_pkt = \
			testutils.simple_udp_packet(eth_dst=dmac, eth_src=smac, udp_sport=2123, udp_dport=2123, pktlen=0) / \
			scapy.GTPHeader(version=2,P=0,T=1,length=12) / \
			base_pkt_inner

		# derek: I found that for some reason I have to force a recalculation of the
		# checksums on these packets.  I found this snippet online.  At some point,
		# I need to revisit to understand why this better.  Seems to only be a problem
		# with gtp-c?
		del base_pkt.chksum
		base_pkt = base_pkt.__class__(bytes(base_pkt))

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				# gtp-c has no "inner"
				pass;
			elif(term == 2):
				pass;

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt)
		else:
			exp_pkt = base_pkt

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple GTP-U / IP
################################################################################

def npb_simple_2lyr_gtpu_ip(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#		base_pkt_inner = testutils.simple_tcp_packet()
#		base_pkt_inner = testutils.simple_udp_packet()
		base_pkt_inner = testutils.simple_ip_only_packet()

		base_pkt = \
			testutils.simple_udp_packet(eth_dst=dmac, eth_src=smac, udp_sport=2152, udp_dport=2152, pktlen=0) / \
			scapy.GTP_U_Header(version=1,PT=1) / \
			base_pkt_inner

		base_pkt_inner_exp = testutils.simple_tcp_packet(eth_dst=dmac, eth_src=smac, pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				base_pkt = base_pkt_inner_exp
			elif(term == 2):
				pass;

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt)
		else:
			exp_pkt = base_pkt

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple ERSPAN / UDP
################################################################################

def npb_simple_2lyr_erspan_udp(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#		base_pkt_inner = testutils.simple_tcp_packet()
		base_pkt_inner = testutils.simple_udp_packet()
#		base_pkt_inner = scapy.IP() / scapy.TCP() / raw(RandString(size=32))

#		base_pkt = testutils.simple_gre_erspan_packet(eth_dst=dmac, eth_src=smac,                       inner_frame=base_pkt_inner)
		base_pkt = testutils.simple_gre_erspan_packet(eth_dst=dmac, eth_src=smac, gre_seqnum_present=1, inner_frame=base_pkt_inner)

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				base_pkt = base_pkt_inner
			elif(term == 2):
				pass;

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt)
		else:
			exp_pkt = base_pkt

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################
# 3 layers: Simple VXLAN / GRE / IP
################################################################################

def npb_simple_3lyr_vxlan_gre_ip(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#		base_pkt_inner_inner = testutils.simple_tcp_packet()
#		base_pkt_inner_inner = testutils.simple_udp_packet()
		base_pkt_inner_inner = testutils.simple_ip_only_packet()

		base_pkt_inner = testutils.simple_gre_packet(inner_frame=base_pkt_inner_inner)

		base_pkt = testutils.simple_vxlan_packet(eth_dst=dmac, eth_src=smac, inner_frame=base_pkt_inner)

		base_pkt_inner_inner_exp = testutils.simple_tcp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		base_pkt_inner_exp = testutils.simple_gre_packet(inner_frame=base_pkt_inner_inner)

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				base_pkt = base_pkt_inner_exp
			elif(term == 2):
				base_pkt = base_pkt_inner_inner_exp

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt)
		else:
			exp_pkt = base_pkt

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################

def npb_simple_3lyr_vxlanv6_gre_ip(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#		base_pkt_inner_inner = testutils.simple_tcp_packet()
#		base_pkt_inner_inner = testutils.simple_udp_packet()
		base_pkt_inner_inner = testutils.simple_ip_only_packet()

		base_pkt_inner = testutils.simple_gre_packet(inner_frame=base_pkt_inner_inner)

		base_pkt = testutils.simple_vxlanv6_packet(eth_dst=dmac, eth_src=smac, inner_frame=base_pkt_inner)

		base_pkt_inner_inner_exp = testutils.simple_tcp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		base_pkt_inner_exp = testutils.simple_gre_packet(inner_frame=base_pkt_inner_inner)

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				base_pkt = base_pkt_inner_exp
			elif(term == 2):
				base_pkt = base_pkt_inner_inner_exp

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt)
		else:
			exp_pkt = base_pkt

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################
# 3 layers: Simple GRE / IP / IP
################################################################################

def npb_simple_3lyr_gre_ip_ip(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#       notes:
#		simple_ip_packet      = l2 / l3 ipv4
#		simple_ip_only_packet =      l3 ipv4 / l4 tcp

#		base_pkt_inner_inner = testutils.simple_tcp_packet()
#		base_pkt_inner_inner = testutils.simple_udp_packet()
		base_pkt_inner_inner = testutils.simple_ip_only_packet()

#		base_pkt_inner = testutils.simple_gre_packet(inner_frame=base_pkt_inner_inner)
		base_pkt_inner = scapy.IP(src='192.168.0.1', dst='192.168.0.2', proto=4) / base_pkt_inner_inner

		base_pkt = testutils.simple_gre_packet(eth_dst=dmac, eth_src=smac, inner_frame=base_pkt_inner)

		base_pkt_inner_inner_exp = testutils.simple_tcp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		base_pkt_inner_exp = testutils.simple_ip_packet(pktlen=14+20, ip_proto=4) / testutils.simple_ip_only_packet()

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				base_pkt = base_pkt_inner_exp
			elif(term == 2):
				base_pkt = base_pkt_inner_inner_exp

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt)
		else:
			exp_pkt = base_pkt

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################

def npb_simple_3lyr_grev6_ip_ip(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#       notes:
#		simple_ip_packet      = l2 / l3 ipv4
#		simple_ip_only_packet =      l3 ipv4 / l4 tcp

#		base_pkt_inner_inner = testutils.simple_tcp_packet()
#		base_pkt_inner_inner = testutils.simple_udp_packet()
		base_pkt_inner_inner = testutils.simple_ip_only_packet()

#		base_pkt_inner = testutils.simple_gre_packet(inner_frame=base_pkt_inner_inner)
		base_pkt_inner = scapy.IP(src='192.168.0.1', dst='192.168.0.2', proto=4) / base_pkt_inner_inner

		base_pkt = testutils.simple_grev6_packet(eth_dst=dmac, eth_src=smac, inner_frame=base_pkt_inner)

		base_pkt_inner_inner_exp = testutils.simple_tcp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		base_pkt_inner_exp = testutils.simple_ip_packet(pktlen=14+20, ip_proto=4) / testutils.simple_ip_only_packet()

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				base_pkt = base_pkt_inner_exp
			elif(term == 2):
				base_pkt = base_pkt_inner_inner_exp

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt)
		else:
			exp_pkt = base_pkt

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################
# 3 layers: Simple GRE / IPv6 / IP
################################################################################

def npb_simple_3lyr_gre_ipv6_ip(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#       notes:
#		simple_ip_packet      = l2 / l3 ipv4
#		simple_ip_only_packet =      l3 ipv4 / l4 tcp

#		base_pkt_inner_inner = testutils.simple_tcp_packet()
#		base_pkt_inner_inner = testutils.simple_udp_packet()
		base_pkt_inner_inner = testutils.simple_ip_only_packet()

#		base_pkt_inner = testutils.simple_gre_packet(inner_frame=base_pkt_inner_inner)
		base_pkt_inner = scapy.IPv6(src='2001:db8:85a3::8a2e:370:7334', dst='2001:db8:85a3::8a2e:370:7335', nh=4) / base_pkt_inner_inner

		base_pkt = testutils.simple_gre_packet(eth_dst=dmac, eth_src=smac, inner_frame=base_pkt_inner)

		base_pkt_inner_inner_exp = testutils.simple_tcp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		base_pkt_inner_exp = simple_ipv6_packet(pktlen=14+20, ipv6_next_header=4) / testutils.simple_ip_only_packet()

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				base_pkt = base_pkt_inner_exp
			elif(term == 2):
				base_pkt = base_pkt_inner_inner_exp

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt)
		else:
			exp_pkt = base_pkt

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################

def npb_simple_3lyr_grev6_ipv6_ip(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#       notes:
#		simple_ip_packet      = l2 / l3 ipv4
#		simple_ip_only_packet =      l3 ipv4 / l4 tcp

#		base_pkt_inner_inner = testutils.simple_tcp_packet()
#		base_pkt_inner_inner = testutils.simple_udp_packet()
		base_pkt_inner_inner = testutils.simple_ip_only_packet()

#		base_pkt_inner = testutils.simple_gre_packet(inner_frame=base_pkt_inner_inner)
		base_pkt_inner = scapy.IPv6(src='2001:db8:85a3::8a2e:370:7334', dst='2001:db8:85a3::8a2e:370:7335', nh=4) / base_pkt_inner_inner

		base_pkt = testutils.simple_grev6_packet(eth_dst=dmac, eth_src=smac, inner_frame=base_pkt_inner)

		base_pkt_inner_inner_exp = testutils.simple_tcp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		base_pkt_inner_exp = simple_ipv6_packet(pktlen=14+20, ipv6_next_header=4) / testutils.simple_ip_only_packet()

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				base_pkt = base_pkt_inner_exp
			elif(term == 2):
				base_pkt = base_pkt_inner_inner_exp

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt)
		else:
			exp_pkt = base_pkt

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################
# 3 layers: Simple GRE / IP / IPv6
################################################################################

def npb_simple_3lyr_gre_ip_ipv6(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#       notes:
#		simple_ip_packet      = l2 / l3 ipv4
#		simple_ip_only_packet =      l3 ipv4 / l4 tcp

#		base_pkt_inner_inner = testutils.simple_tcp_packet()
#		base_pkt_inner_inner = testutils.simple_udp_packet()
		base_pkt_inner_inner = simple_ipv6_only_packet()

#		base_pkt_inner = testutils.simple_gre_packet(inner_frame=base_pkt_inner_inner)
		base_pkt_inner = scapy.IP(src='192.168.0.1', dst='192.168.0.2', proto=41) / base_pkt_inner_inner

		base_pkt = testutils.simple_gre_packet(eth_dst=dmac, eth_src=smac, inner_frame=base_pkt_inner)

		base_pkt_inner_inner_exp = testutils.simple_tcpv6_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		base_pkt_inner_exp = testutils.simple_ip_packet(pktlen=14+20, ip_proto=41) / simple_ipv6_only_packet()

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				base_pkt = base_pkt_inner_exp
			elif(term == 2):
				base_pkt = base_pkt_inner_inner_exp

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt)
		else:
			exp_pkt = base_pkt

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################

def npb_simple_3lyr_grev6_ip_ipv6(
	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#transport source variables
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#model flags
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	bridged_pkt    = False,

	#outer expected variables
	vlan_en_exp    = None,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None,

	#transport expected variables
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	sap_exp        = None,
	vpn_exp        = None):

		# -----------------

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		# -----------------

		if(vlan_en == True) and (vlan_en_exp == False):
			pktlen_exp = pktlen_exp - 4
		elif(vlan_en == False) and (vlan_en_exp == True):
			pktlen_exp = pktlen_exp + 4

		if(e_en == True) and (e_en_exp == False):
			pktlen_exp = pktlen_exp - 8

		if(vn_en == True) and (vn_en_exp == False):
			pktlen_exp = pktlen_exp - 6

		# -----------------

#       notes:
#		simple_ip_packet      = l2 / l3 ipv4
#		simple_ip_only_packet =      l3 ipv4 / l4 tcp

#		base_pkt_inner_inner = testutils.simple_tcp_packet()
#		base_pkt_inner_inner = testutils.simple_udp_packet()
		base_pkt_inner_inner = simple_ipv6_only_packet()

#		base_pkt_inner = testutils.simple_gre_packet(inner_frame=base_pkt_inner_inner)
		base_pkt_inner = scapy.IP(src='192.168.0.1', dst='192.168.0.2', proto=41) / base_pkt_inner_inner

		base_pkt = testutils.simple_grev6_packet(eth_dst=dmac, eth_src=smac, inner_frame=base_pkt_inner)

		base_pkt_inner_inner_exp = testutils.simple_tcpv6_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		base_pkt_inner_exp = testutils.simple_ip_packet(pktlen=14+20, ip_proto=41) / simple_ipv6_only_packet()

		# -----------------
		# gen src pkt
		# -----------------

		if(start_of_chain == False):
			src_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, scope, sap, vpn, ttl, base_pkt)
		else:
			src_pkt = base_pkt

		# -----------------
		# model
		# -----------------

		# an extremely crude model of what happens in the chip

		if(bridged_pkt == False):
			si_exp = si_exp-(popcount(sf_bitmask))

			if(start_of_chain == False):
				ttl = ttl-1

			term = 0
			for i in scope_term_list:
				# iterate through scopes and terminates
				if(i == 0):
					scope = scope + 1;       # increment scope
				elif(i == 1):
					term = term + 1 + scope; # increment terminate
					scope = 0;               # reset scope

			if(term == 1):
				base_pkt = base_pkt_inner_exp
			elif(term == 2):
				base_pkt = base_pkt_inner_inner_exp

		# -----------------
		# gen exp pkt
		# -----------------

		if(end_of_chain == False):
			exp_pkt = nsh_encap(dmac_nsh, smac_nsh, vlan_en_nsh_exp, vlan_pcp_nsh, vlan_vid_nsh, spi_exp, si_exp, scope, sap_exp, vpn_exp, ttl, base_pkt)
		else:
			exp_pkt = base_pkt

		# -----------------

#		print "---------- Debug ----------"
#		print(testutils.format_packet(src_pkt))
#		print "---------- Debug ----------"

		return src_pkt, exp_pkt

################################################################################
# Helper Utilities
################################################################################

# An enhanced version of Barefoot's routine, that supports e and vn tags.

def simple_udp_packet2(pktlen=100,
                      eth_dst='00:01:02:03:04:05',
                      eth_src='00:06:07:08:09:0a',
                      dl_vlan_enable=False,
                      vlan_vid=0,
                      vlan_pcp=0,
                      dl_vlan_cfi=0,
                      ip_src='192.168.0.1',
                      ip_dst='192.168.0.2',
                      ip_tos=0,
                      ip_ecn=None,
                      ip_dscp=None,
                      ip_ttl=64,
                      udp_sport=1234,
                      udp_dport=80,
                      ip_ihl=None,
                      ip_options=False,
                      ip_flag=0,
                      ip_id=1,
                      with_udp_chksum=True,
                      udp_payload=None,
                      dot1br=False,
                      vn_tag=False
                      ):
    """
    Return a simple dataplane UDP packet

    Supports a few parameters:
    @param len Length of packet in bytes w/o CRC
    @param eth_dst Destination MAC
    @param eth_src Source MAC
    @param dl_vlan_enable True if the packet is with vlan, False otherwise
    @param vlan_vid VLAN ID
    @param vlan_pcp VLAN priority
    @param ip_src IP source
    @param ip_dst IP destination
    @param ip_tos IP ToS
    @param ip_ecn IP ToS ECN
    @param ip_dscp IP ToS DSCP
    @param ip_ttl IP TTL
    @param ip_id IP ID
    @param udp_dport UDP destination port
    @param udp_sport UDP source port
    @param with_udp_chksum Valid UDP checksum

    Generates a simple UDP packet. Users shouldn't assume anything about
    this packet other than that it is a valid ethernet/IP/UDP frame.
    """

    if testutils.MINSIZE > pktlen:
        pktlen = testutils.MINSIZE

    if with_udp_chksum:
        udp_hdr = scapy.UDP(sport=udp_sport, dport=udp_dport)
    else:
        udp_hdr = scapy.UDP(sport=udp_sport, dport=udp_dport, chksum=0)

    ip_tos = testutils.ip_make_tos(ip_tos, ip_ecn, ip_dscp)

    # Note Dot1Q.id is really CFI
    if (dl_vlan_enable==1):
        if(dot1br):
            # e-tag + vlan
            pkt = scapy.Ether(dst=eth_dst, src=eth_src)/ \
                scapy.Dot1BR()/ \
                scapy.Dot1Q(prio=vlan_pcp, id=dl_vlan_cfi, vlan=vlan_vid)/ \
                scapy.IP(src=ip_src, dst=ip_dst, tos=ip_tos, ttl=ip_ttl, ihl=ip_ihl, id=ip_id)/ \
                udp_hdr
        elif(vn_tag):
            # vn-tag + vlan
            pkt = scapy.Ether(dst=eth_dst, src=eth_src)/ \
                scapy.VNTag()/ \
                scapy.Dot1Q(prio=vlan_pcp, id=dl_vlan_cfi, vlan=vlan_vid)/ \
                scapy.IP(src=ip_src, dst=ip_dst, tos=ip_tos, ttl=ip_ttl, ihl=ip_ihl, id=ip_id)/ \
                udp_hdr
        else:
            # vlan only
            pkt = scapy.Ether(dst=eth_dst, src=eth_src)/ \
                scapy.Dot1Q(prio=vlan_pcp, id=dl_vlan_cfi, vlan=vlan_vid)/ \
                scapy.IP(src=ip_src, dst=ip_dst, tos=ip_tos, ttl=ip_ttl, ihl=ip_ihl, id=ip_id)/ \
                udp_hdr
    elif (dl_vlan_enable==2):
        if(dot1br):
            # e-tag + vlan
            pkt = scapy.Ether(dst=eth_dst, src=eth_src)/ \
                scapy.Dot1BR()/ \
                scapy.Dot1Q(prio=vlan_pcp, id=dl_vlan_cfi, vlan=vlan_vid)/ \
                scapy.Dot1Q(prio=vlan_pcp, id=dl_vlan_cfi, vlan=vlan_vid)/ \
                scapy.IP(src=ip_src, dst=ip_dst, tos=ip_tos, ttl=ip_ttl, ihl=ip_ihl, id=ip_id)/ \
                udp_hdr
        elif(vn_tag):
            # vn-tag + vlan
            pkt = scapy.Ether(dst=eth_dst, src=eth_src)/ \
                scapy.VNTag()/ \
                scapy.Dot1Q(prio=vlan_pcp, id=dl_vlan_cfi, vlan=vlan_vid)/ \
                scapy.Dot1Q(prio=vlan_pcp, id=dl_vlan_cfi, vlan=vlan_vid)/ \
                scapy.IP(src=ip_src, dst=ip_dst, tos=ip_tos, ttl=ip_ttl, ihl=ip_ihl, id=ip_id)/ \
                udp_hdr
        else:
            # vlan only
            pkt = scapy.Ether(dst=eth_dst, src=eth_src)/ \
                scapy.Dot1Q(prio=vlan_pcp, id=dl_vlan_cfi, vlan=vlan_vid)/ \
                scapy.Dot1Q(prio=vlan_pcp, id=dl_vlan_cfi, vlan=vlan_vid)/ \
                scapy.IP(src=ip_src, dst=ip_dst, tos=ip_tos, ttl=ip_ttl, ihl=ip_ihl, id=ip_id)/ \
                udp_hdr
    else:
        if(dot1br):
            # e-tag + vlan
            pkt = scapy.Ether(dst=eth_dst, src=eth_src)/ \
                scapy.Dot1BR()/ \
                scapy.IP(src=ip_src, dst=ip_dst, tos=ip_tos, ttl=ip_ttl, ihl=ip_ihl, id=ip_id)/ \
                udp_hdr
        elif(vn_tag):
            # vn-tag + vlan
            pkt = scapy.Ether(dst=eth_dst, src=eth_src)/ \
                scapy.VNTag()/ \
                scapy.IP(src=ip_src, dst=ip_dst, tos=ip_tos, ttl=ip_ttl, ihl=ip_ihl, id=ip_id)/ \
                udp_hdr
        elif not ip_options:
			# plain packet
            pkt = scapy.Ether(dst=eth_dst, src=eth_src)/ \
                scapy.IP(src=ip_src, dst=ip_dst, tos=ip_tos, ttl=ip_ttl, ihl=ip_ihl, id=ip_id, flags=ip_flag)/ \
                udp_hdr
        else:
			# plain packet
            pkt = scapy.Ether(dst=eth_dst, src=eth_src)/ \
                scapy.IP(src=ip_src, dst=ip_dst, tos=ip_tos, ttl=ip_ttl, ihl=ip_ihl, options=ip_options, id=ip_id, flags=ip_flag)/ \
                udp_hdr

    if udp_payload:
        pkt = pkt/udp_payload

    pkt = pkt/codecs.decode("".join(["%02x"%(x%256) for x in range(pktlen - len(pkt))]), "hex")

    return pkt

################################################################################

# a missing Barefoot routine for ipv6

# simple_ip_packet      = l2 / l3 ipv6

def simple_ipv6_packet(pktlen=100,
                       eth_dst='00:01:02:03:04:05',
                       eth_src='00:06:07:08:09:0a',
                       dl_vlan_enable=False,
                       vlan_vid=0,
                       vlan_pcp=0,
                       dl_vlan_cfi=0,
                       ipv6_src='2001:db8:85a3::8a2e:370:7334',
                       ipv6_dst='2001:db8:85a3::8a2e:370:7335',
                       ipv6_tc=0,
                       ipv6_ecn=None,
                       ipv6_dscp=None,
                       ipv6_hlim=64,
                       ipv6_fl=0,
                       ipv6_next_header=0
                       ):
    """
    Return a simple dataplane IP packet

    Supports a few parameters:
    @param len Length of packet in bytes w/o CRC
    @param eth_dst Destinatino MAC
    @param eth_src Source MAC
    @param dl_vlan_enable True if the packet is with vlan, False otherwise
    @param vlan_vid VLAN ID
    @param vlan_pcp VLAN priority
    @param ipv6_src IPv6 source
    @param ipv6_dst IPv6 destination
    @param ipv6_tc IPv6 traffic class
    @param ipv6_ecn IPv6 traffic class ECN
    @param ipv6_dscp IPv6 traffic class DSCP
    @param ipv6_ttl IPv6 hop limit
    @param ipv6_fl IPv6 flow label

    Generates a simple IP packet.  Users
    shouldn't assume anything about this packet other than that
    it is a valid ethernet/IP frame.
    """

    if testutils.MINSIZE > pktlen:
        pktlen = testutils.MINSIZE

    ipv6_tc = testutils.ip_make_tos(ipv6_tc, ipv6_ecn, ipv6_dscp)

    # Note Dot1Q.id is really CFI
    if (dl_vlan_enable):
        pkt = scapy.Ether(dst=eth_dst, src=eth_src)/ \
            scapy.Dot1Q(prio=vlan_pcp, id=dl_vlan_cfi, vlan=vlan_vid)/ \
            scapy.IPv6(src=ipv6_src, dst=ipv6_dst, fl=ipv6_fl, tc=ipv6_tc, hlim=ipv6_hlim, nh=ipv6_next_header)
    else:
        pkt = scapy.Ether(dst=eth_dst, src=eth_src)/ \
            scapy.IPv6(src=ipv6_src, dst=ipv6_dst, fl=ipv6_fl, tc=ipv6_tc, hlim=ipv6_hlim, nh=ipv6_next_header)

    pkt = pkt/codecs.decode("".join(["%02x"%(x%256) for x in range(pktlen - len(pkt))]), "hex")

    return pkt

################################################################################

# a missing Barefoot routine for ipv6

#		simple_ipv6_only_packet =      l3 ipv4 / l6 tcp

def simple_ipv6_only_packet(pktlen=100,
                       ipv6_src='2001:db8:85a3::8a2e:370:7334',
                       ipv6_dst='2001:db8:85a3::8a2e:370:7335',
                       ipv6_tc=0,
                       ipv6_ecn=None,
                       ipv6_dscp=None,
                       ipv6_hlim=64,
                       ipv6_fl=0,
                       tcp_sport=1234,
                       tcp_dport=80,
                       tcp_flags="S",
                       with_tcp_chksum=True
                       ):
    """
    Return a simple dataplane IP packet

    Supports a few parameters:
    @param len Length of packet in bytes w/o CRC
    @param ipv6_src IPv6 source
    @param ipv6_dst IPv6 destination
    @param ipv6_tc IPv6 traffic class
    @param ipv6_ecn IPv6 traffic class ECN
    @param ipv6_dscp IPv6 traffic class DSCP
    @param ipv6_ttl IPv6 hop limit
    @param ipv6_fl IPv6 flow label

    Generates a simple IP packet.  Users
    shouldn't assume anything about this packet other than that
    it is a valid IP frame.
    """

    if testutils.MINSIZE > pktlen:
        pktlen = testutils.MINSIZE

    if with_tcp_chksum:
        tcp_hdr = scapy.TCP(sport=tcp_sport, dport=tcp_dport, flags=tcp_flags)
    else:
        tcp_hdr = scapy.TCP(sport=tcp_sport, dport=tcp_dport, flags=tcp_flags, chksum=0)

    ipv6_tc = testutils.ip_make_tos(ipv6_tc, ipv6_ecn, ipv6_dscp)

    pkt = scapy.IPv6(src=ipv6_src, dst=ipv6_dst, fl=ipv6_fl, tc=ipv6_tc, hlim=ipv6_hlim) / tcp_hdr

#   pkt = pkt/codecs.decode("".join(["%02x"%(x%256) for x in range(pktlen - len(pkt))]), "hex")
    pkt = pkt/("D" * (pktlen - len(pkt)))


    return pkt

