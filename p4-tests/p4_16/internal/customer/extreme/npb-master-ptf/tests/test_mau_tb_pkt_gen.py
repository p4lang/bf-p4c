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
from   res_pd_rpc      import * # Common daea types
from   mc_pd_rpc       import * # Multicast-specific data types
from   mirror_pd_rpc   import * # Mirror-specific data types

####### Additional imports #######
import pdb # To debug insert pdb.set_trace() anywhere

import codecs

from test_mau_tb_shared import *
from test_mau_tb_models import *

################################################################################
# 1 layer: Simple UDP
################################################################################

def npb_simple_1lyr_udp(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	vlan2_en       = False,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,
	tos            = 0,
	sip            = '11.22.33.44',
	dip            = '55.66.77.88',
	udp_sport      = 1234,
	udp_dport      = 80,
	tcp_flags      = 0,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,
#	dtel_flow_rpt  = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,
	ig_port        = 0, #Dtel report
	eg_port        = 0, #Dtel report
	qid            = 0, #Dtel report

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	vlan2_en_exp   = None,#vlan2_en_exp should never be set if vlan_en_exp is not set.
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if vlan_en         is False: vlan2_en      = False
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if vlan_en_exp     is None: vlan2_en_exp     = False
		if vlan2_en_exp    is None: vlan2_en_exp     = False
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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
#			src_pkt_base = simple_tcp_packet2(eth_dst=dmac, eth_src=smac, pktlen=pktlen, dl_vlan_enable=vlan_en, vlan_vid=vlan_en_vid, vlan_pcp=vlan_en_pcp, dot1br=e_en, vn_tag=vn_en)
			if(vlan2_en == True):
				src_pkt_base = simple_udp_packet2(eth_dst=dmac, eth_src=smac, pktlen=pktlen+4, dl_vlan_enable=2, vlan_vid=vlan_en_vid, vlan_pcp=vlan_en_pcp, dot1br=e_en, vn_tag=vn_en, ip_src=sip, ip_dst=dip, ip_tos=tos, udp_sport=udp_sport, udp_dport=udp_dport)
			else:
				src_pkt_base = simple_udp_packet2(eth_dst=dmac, eth_src=smac, pktlen=pktlen, dl_vlan_enable=vlan_en, vlan_vid=vlan_en_vid, vlan_pcp=vlan_en_pcp, dot1br=e_en, vn_tag=vn_en, ip_src=sip, ip_dst=dip, ip_tos=tos, udp_sport=udp_sport, udp_dport=udp_dport)
		else:
			# user barefoot's version
#			src_pkt_base = testutils.simple_tcp_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen)
			src_pkt_base = testutils.simple_udp_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen, ip_src=sip, ip_dst=dip, ip_tos=tos, udp_sport=udp_sport, udp_dport=udp_dport)

		# -----------------

		if((vlan_en_exp == True) or (e_en_exp == True) or (vn_en_exp == True)):
			# use my version, that adds support for e and vn tags
#			exp_pkt_base = simple_tcp_packet2(eth_dst=dmac, eth_src=smac, pktlen=pktlen_exp, dl_vlan_enable=vlan_en_exp, vlan_vid=vlan_en_exp_vid, vlan_pcp=vlan_en_exp_pcp, dot1br=e_en_exp, vn_tag=vn_en_exp)
			if(vlan2_en_exp == True):
				exp_pkt_base = simple_udp_packet2(eth_dst=dmac, eth_src=smac, pktlen=pktlen_exp+4, dl_vlan_enable=2, vlan_vid=vlan_en_exp_vid, vlan_pcp=vlan_en_exp_pcp, dot1br=e_en_exp, vn_tag=vn_en_exp, ip_src=sip, ip_dst=dip, ip_tos=tos, udp_sport=udp_sport, udp_dport=udp_dport)
			else:
				exp_pkt_base = simple_udp_packet2(eth_dst=dmac, eth_src=smac, pktlen=pktlen_exp, dl_vlan_enable=vlan_en_exp, vlan_vid=vlan_en_exp_vid, vlan_pcp=vlan_en_exp_pcp, dot1br=e_en_exp, vn_tag=vn_en_exp, ip_src=sip, ip_dst=dip, ip_tos=tos, udp_sport=udp_sport, udp_dport=udp_dport)
		else:
			# user barefoot's version
#			exp_pkt_base = testutils.simple_tcp_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen_exp)
			exp_pkt_base = testutils.simple_udp_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen_exp, ip_src=sip, ip_dst=dip, ip_tos=tos, udp_sport=udp_sport, udp_dport=udp_dport)

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_base, exp_pkt_base],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh,
			ig_port, #Needed for dtel
			eg_port,  #Needed for dtel
			qid
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

		#print("---------- Debug ----------")
		#print(testutils.format_packet(src_pkt))
		#print(testutils.format_packet(exp_pkt))
		#print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################

def npb_simple_1lyr_udpv6(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,
	tos            = 0,
	sip            = '2001:db8:85a3::8a2e:370:7334',
	dip            = '2002:db8:85a3::8a2e:370:7334',
	udp_sport      = 1234,
	udp_dport      = 80,
	tcp_flags      = 0,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_base = testutils.simple_tcpv6_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen, dl_vlan_enable=vlan_en, vlan_vid=vlan_en_vid, vlan_pcp=vlan_en_pcp)
		src_pkt_base = testutils.simple_udpv6_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen, dl_vlan_enable=vlan_en, vlan_vid=vlan_en_vid, vlan_pcp=vlan_en_pcp, ipv6_src=sip, ipv6_dst=dip, ipv6_tc=tos, udp_sport=udp_sport, udp_dport=udp_dport)

		# -----------------

#		exp_pkt_base = testutils.simple_tcpv6_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen_exp, dl_vlan_enable=vlan_en_exp, vlan_vid=vlan_en_exp_vid, vlan_pcp=vlan_en_exp_pcp)
		exp_pkt_base = testutils.simple_udpv6_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen_exp, dl_vlan_enable=vlan_en_exp, vlan_vid=vlan_en_exp_vid, vlan_pcp=vlan_en_exp_pcp, ipv6_src=sip, ipv6_dst=dip, ipv6_tc=tos, udp_sport=udp_sport, udp_dport=udp_dport)

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_base, exp_pkt_base],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 1 layers: Simple GRE
################################################################################

def npb_simple_1lyr_gre(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner = testutils.simple_tcp_packet()
#		src_pkt_inner = testutils.simple_udp_packet()
		src_pkt_inner = testutils.simple_ip_only_packet()

		src_pkt_base = testutils.simple_gre_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

		if(transport_decap == True):
			# if the pkt is decap'ed at the transport...the npb design has to create a new l2 header (and currently sets da and sa to 0)....
			exp_pkt_inner = testutils.simple_tcp_packet(eth_dst=0,    eth_src=0,    pktlen=14+100) # add 14, because original packet didn't have an l2 on it
		else:
			# if the pkt is decap'ed elsewhere...
			exp_pkt_inner = testutils.simple_tcp_packet(eth_dst=dmac, eth_src=smac, pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base


		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple VXLAN / UDP
################################################################################

def npb_simple_2lyr_vxlan_udp(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	vxlan_vni      = 0xaba,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner = testutils.simple_tcp_packet()
		src_pkt_inner = testutils.simple_udp_packet()

		src_pkt_base = testutils.simple_vxlan_packet(eth_dst=dmac, eth_src=smac, vxlan_vni=vxlan_vni, inner_frame=src_pkt_inner)

		# -----------------

		exp_pkt_inner = src_pkt_inner

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################

def npb_simple_2lyr_vxlanv6_udpv6(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner = testutils.simple_tcpv6_packet()
		src_pkt_inner = testutils.simple_udpv6_packet()

		src_pkt_base = testutils.simple_vxlanv6_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

		exp_pkt_inner = src_pkt_inner

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple MPLS L2 / UDP
################################################################################

def npb_simple_2lyr_mpls_l2_udp(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	mpls_label     = [],
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

		src_pkt_inner = testutils.simple_udp_packet()

#		src_pkt_base = testutils.simple_mpls_packet(eth_dst=dmac, eth_src=smac, mpls_tags=mpls_tags, inner_frame=src_pkt_inner)

		src_pkt_base = scapy.Ether(dst=dmac, src=smac)

		for i in range(0, len(mpls_label)):
			src_pkt_base = src_pkt_base / scapy.MPLS(label=mpls_label[i], s=(i==(len(mpls_label)-1)), ttl=0xff)

		src_pkt_base = src_pkt_base /src_pkt_inner

#                scapy.MPLS(label=0x12345, s=1, ttl=0xff)/ \

		# -----------------

		exp_pkt_inner = src_pkt_inner

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

		#print("---------- Debug ----------")
		#print(testutils.format_packet(src_pkt))
		#print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple MPLS L3 / UDP
################################################################################

def npb_simple_2lyr_mpls_l3_udp(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	mpls_label     = [],
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

		src_pkt_inner = testutils.simple_ip_only_packet(pktlen = 86)

#		src_pkt_base = testutils.simple_mpls_packet(eth_dst=dmac, eth_src=smac, mpls_tags=mpls_tags, inner_frame=src_pkt_inner)

		src_pkt_base = scapy.Ether(dst=dmac, src=smac)

		for i in range(0, len(mpls_label)):
			src_pkt_base = src_pkt_base / scapy.MPLS(label=mpls_label[i], s=(i==(len(mpls_label)-1)), ttl=0xff)

		src_pkt_base = src_pkt_base /src_pkt_inner

#                scapy.MPLS(label=0x12345, s=1, ttl=0xff)/ \

		# -----------------

		exp_pkt_inner = testutils.simple_tcp_packet(eth_dst='00:00:00:00:00:00', eth_src='00:00:00:00:00:00')

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

		#print("---------- Debug ----------")
		#print(testutils.format_packet(src_pkt))
		#print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple SPBM / TCP
################################################################################

def npb_simple_2lyr_spbm_tcp(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

		# -----------------

#		ptklen_exp = pktlen_exp - 22
		pktlen_exp_2 = pktlen_exp - 22

		# -----------------

		exp_pkt_base = testutils.simple_tcp_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen_exp_2)

		src_pkt_base = simple_spbm_tcp_packet(eth_dst=dmac, eth_src=smac, pktlen=pktlen)

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_base, exp_pkt_base],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

		#print("---------- Debug ----------")
		#print(testutils.format_packet(src_pkt))
		#print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple NVGRE / UDP
################################################################################

def npb_simple_2lyr_nvgre_udp(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner = testutils.simple_tcp_packet()
		src_pkt_inner = testutils.simple_udp_packet()

		src_pkt_base = testutils.simple_nvgre_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

		exp_pkt_inner = src_pkt_inner

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple GRE / IP
################################################################################

def npb_simple_2lyr_gre_ip(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	dip_nsh        = '192.168.0.2',
	sip_nsh        = '192.168.0.1',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac_t           = '00:01:02:03:04:05',
	smac_t           = '00:06:07:08:09:0a',
	dip_t            = '192.168.0.2',
	sip_t            = '192.168.0.1',
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	dip            = '192.168.0.2',
	sip            = '192.168.0.1',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner = testutils.simple_tcp_packet()
#		src_pkt_inner = testutils.simple_udp_packet()
		src_pkt_inner = testutils.simple_ip_only_packet(ip_src=sip, ip_dst=dip)

		src_pkt_base = testutils.simple_gre_packet(eth_dst=dmac_nsh, eth_src=smac_nsh, ip_src=sip_nsh, ip_dst=dip_nsh, inner_frame=src_pkt_inner)

		# -----------------

		if(transport_decap == True):
			# if the pkt is decap'ed at the transport...the npb design has to create a new l2 header (and currently sets da and sa to 0)....
			exp_pkt_inner = testutils.simple_tcp_packet(eth_dst=0,    eth_src=0, ip_src=sip, ip_dst=dip,   pktlen=14+100) # add 14, because original packet didn't have an l2 on it
		else:
			# if the pkt is decap'ed elsewhere...
			exp_pkt_inner = testutils.simple_tcp_packet(eth_dst=dmac_nsh, eth_src=smac_nsh, ip_src=sip, ip_dst=dip, pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base


		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################

def npb_simple_2lyr_grev6_ip(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner = testutils.simple_tcp_packet()
#		src_pkt_inner = testutils.simple_udp_packet()
		src_pkt_inner = testutils.simple_ip_only_packet()

		src_pkt_base = testutils.simple_grev6_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

		if(transport_decap == True):
			# if the pkt is decap'ed at the transport...the npb design has to create a new l2 header (and currently sets da and sa to 0)....
			exp_pkt_inner = testutils.simple_tcp_packet(eth_dst=0,    eth_src=0,    pktlen=14+100) # add 14, because original packet didn't have an l2 on it
#peter Overload			exp_pkt_inner = testutils.simple_ip_packet(eth_dst=dmac,    eth_src=smac,    pktlen=14+100) # add 14, because original packet didn't have an l2 on it
		else:
			# if the pkt is decap'ed elsewhere...
			exp_pkt_inner = testutils.simple_tcp_packet(eth_dst=dmac, eth_src=smac, pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base


		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print(testutils.format_packet(exp_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple IP / IP
################################################################################

def npb_simple_2lyr_ipinip(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner = testutils.simple_tcp_packet()
#		src_pkt_inner = testutils.simple_udp_packet()
		src_pkt_inner = testutils.simple_ip_only_packet()

		src_pkt_base = testutils.simple_ipv4ip_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner);

		# -----------------

		exp_pkt_inner = testutils.simple_tcp_packet(eth_dst=dmac, eth_src=smac, pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple GTP-C / UDP
################################################################################

def npb_simple_2lyr_gtpc_udp(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner = testutils.simple_tcp_packet()
		src_pkt_inner = testutils.simple_udp_packet()

		src_pkt_base = \
			testutils.simple_udp_packet(eth_dst=dmac, eth_src=smac, udp_sport=2123, udp_dport=2123, pktlen=0) / \
			scapy.GTPHeader(version=2,P=0,T=1,length=12) / \
			src_pkt_inner

		# derek: I found that for some reason I have to force a recalculation of the
		# checksums on these packets.  I found this snippet online.  At some point,
		# I need to revisit to understand why this better.  Seems to only be a problem
		# with gtp-c?
		del src_pkt_base.chksum
		src_pkt_base = src_pkt_base.__class__(bytes(src_pkt_base))

		# -----------------

		exp_pkt_inner = src_pkt_inner

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple GTP-U / IP
################################################################################

def npb_simple_2lyr_gtpu_ip(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner = testutils.simple_tcp_packet()
#		src_pkt_inner = testutils.simple_udp_packet()
		src_pkt_inner = testutils.simple_ip_only_packet()

		src_pkt_base = \
			testutils.simple_udp_packet(eth_dst=dmac, eth_src=smac, udp_sport=2152, udp_dport=2152, pktlen=0) / \
			scapy.GTP_U_Header(version=1,PT=1) / \
			src_pkt_inner

		# -----------------

		exp_pkt_inner = testutils.simple_tcp_packet(eth_dst=dmac, eth_src=smac, pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 2 layers: Simple ERSPAN / UDP
################################################################################

def npb_simple_2lyr_erspan_udp(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner = testutils.simple_tcp_packet()
		src_pkt_inner = testutils.simple_udp_packet()
#		src_pkt_inner = scapy.IP() / scapy.TCP() / raw(RandString(size=32))

#		src_pkt_base = testutils.simple_gre_erspan_packet(eth_dst=dmac, eth_src=smac,                       inner_frame=src_pkt_inner)
		src_pkt_base = testutils.simple_gre_erspan_packet(eth_dst=dmac, eth_src=smac, gre_seqnum_present=1, inner_frame=src_pkt_inner)

		# -----------------

		exp_pkt_inner = src_pkt_inner

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 3 layers: Simple VXLAN / GRE / IP
################################################################################

def npb_simple_3lyr_vxlan_gre_ip(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner_inner = testutils.simple_tcp_packet()
#		src_pkt_inner_inner = testutils.simple_udp_packet()
		src_pkt_inner_inner = testutils.simple_ip_only_packet()

		src_pkt_inner = testutils.simple_gre_packet(inner_frame=src_pkt_inner_inner)

		src_pkt_base = testutils.simple_vxlan_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

		exp_pkt_inner_inner = testutils.simple_tcp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_inner = testutils.simple_gre_packet(inner_frame=src_pkt_inner_inner)

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

		#print("---------- Debug ----------")
		#print(testutils.format_packet(src_pkt))
		#print(exp_pkt)
		#print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 3 layers: Simple ERSPAN / VXLAN / UDP
################################################################################

def npb_simple_3lyr_erspan_vxlan_udp(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	dip_nsh        = '192.168.0.1',
	sip_nsh        = '192.168.0.2',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	dip            = '192.168.0.1',
	sip            = '192.168.0.2',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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
		dmac_inner           = '0:01:02:03:04:05'
		smac_inner           = '0:06:07:08:09:0a'
		dmac_inner_inner     = '20:21:22:23:24:25'
		smac_inner_inner     = '20:26:27:28:29:2a'

		src_pkt_inner_inner = testutils.simple_udp_packet(eth_dst=dmac_inner_inner, eth_src=smac_inner_inner)

#		src_pkt_inner = testutils.simple_vxlan_packet(eth_dst=dmac_inner, eth_src=smac_inner,  ip_src=sip_nsh, ip_dst=dip_nsh, inner_frame=src_pkt_inner_inner)
		src_pkt_inner = testutils.simple_vxlan_packet(eth_dst=dmac_inner, eth_src=smac_inner,  ip_src=sip, ip_dst=dip, inner_frame=src_pkt_inner_inner)

#		src_pkt_base = testutils.simple_gre_packet(eth_dst=dmac_nsh, eth_src=smac_nsh, inner_frame=src_pkt_inner)
		src_pkt_base = testutils.simple_gre_erspan_packet(eth_dst=dmac_nsh, eth_src=smac_nsh, ip_src=sip_nsh, ip_dst=dip_nsh, gre_seqnum_present=1, inner_frame=src_pkt_inner)


		# -----------------

		exp_pkt_inner_inner = testutils.simple_udp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

#		exp_pkt_inner = testutils.simple_gre_packet(inner_frame=src_pkt_inner_inner)
		exp_pkt_inner = testutils.simple_vxlan_packet(eth_dst=dmac_inner, eth_src=smac_inner,  ip_src=sip, ip_dst=dip, inner_frame=src_pkt_inner_inner)

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

		#print("---------- Debug ----------")
		#print(testutils.format_packet(src_pkt))
		#print(exp_pkt)
		#print("---------- Debug ----------")

		return src_pkt, exp_pkt
################################################################################
# 3 layers: Simple ERSPAN / GRE / IP
################################################################################

def npb_simple_3lyr_erspan_gre_ip(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	dip_nsh        = '192.168.0.1',
	sip_nsh        = '192.168.0.2',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	dip            = '192.168.0.3',
	sip            = '192.168.0.4',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

		src_pkt_inner_inner = testutils.simple_ip_only_packet()

		src_pkt_inner = testutils.simple_gre_packet(eth_dst=dmac, eth_src=smac, ip_src=sip, ip_dst=dip, inner_frame=src_pkt_inner_inner)

		src_pkt_base = testutils.simple_gre_erspan_packet(eth_dst=dmac_nsh, eth_src=smac_nsh, ip_src=sip_nsh, ip_dst=dip_nsh, gre_seqnum_present=1, inner_frame=src_pkt_inner)


		# -----------------

		exp_pkt_inner_inner = testutils.simple_ip_only_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_inner = testutils.simple_gre_packet(eth_dst=dmac, eth_src=smac, ip_src=sip, ip_dst=dip, inner_frame=src_pkt_inner_inner)

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

		#print("---------- Debug ----------")
		#print(testutils.format_packet(src_pkt))
		#print(exp_pkt)
		#print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################

def npb_simple_3lyr_vxlanv6_gre_ip(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	dip_nsh        = '192.168.0.1',
	sip_nsh        = '192.168.0.2',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	dip            = '192.168.0.1',
	sip            = '192.168.0.2',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner_inner = testutils.simple_tcp_packet()
#		src_pkt_inner_inner = testutils.simple_udp_packet()
		src_pkt_inner_inner = testutils.simple_ip_only_packet()

		src_pkt_inner = testutils.simple_gre_packet(inner_frame=src_pkt_inner_inner)

		src_pkt_base = testutils.simple_vxlanv6_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

		exp_pkt_inner_inner = testutils.simple_tcp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_inner = testutils.simple_gre_packet(inner_frame=src_pkt_inner_inner)

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 3 layers: Simple VXLAN / GTP-C / UDP
################################################################################

def npb_simple_3lyr_vxlan_gtpc_udp(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner_inner = testutils.simple_tcp_packet()
#		src_pkt_inner_inner = testutils.simple_udp_packet()

		src_pkt_inner = \
			testutils.simple_udp_packet(eth_dst=dmac, eth_src=smac, udp_sport=2123, udp_dport=2123, pktlen=128) / \
			scapy.GTPHeader(version=2,P=0,T=1,length=8,teid=0xcdc) # / \
#			src_pkt_inner_inner

		# derek: I found that for some reason I have to force a recalculation of the
		# checksums on these packets.  I found this snippet online.  At some point,
		# I need to revisit to understand why this better.  Seems to only be a problem
		# with gtp-c?
		del src_pkt_inner.chksum
		src_pkt_inner = src_pkt_inner.__class__(bytes(src_pkt_inner))

		src_pkt_base = testutils.simple_vxlan_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

#		exp_pkt_inner_inner = src_pkt_inner_inner

		exp_pkt_inner = src_pkt_inner

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 3 layers: Simple VXLAN / GTP-U / IP
################################################################################

def npb_simple_3lyr_vxlan_gtpu_ip(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner_inner = testutils.simple_tcp_packet()
#		src_pkt_inner_inner = testutils.simple_udp_packet()
		src_pkt_inner_inner = testutils.simple_ip_only_packet()

		src_pkt_inner = \
			testutils.simple_udp_packet(eth_dst=dmac, eth_src=smac, udp_sport=2152, udp_dport=2152, pktlen=0) / \
			scapy.GTP_U_Header(version=1,PT=1,length=12+100,teid=0xefe) / \
			src_pkt_inner_inner

		src_pkt_base = testutils.simple_vxlan_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

		exp_pkt_inner_inner = testutils.simple_tcp_packet(eth_dst=dmac, eth_src=smac, pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_inner = src_pkt_inner

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 3 layers: Simple NVGRE / GRE / IP
################################################################################

def npb_simple_3lyr_nvgre_gre_ip(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner_inner = testutils.simple_tcp_packet()
#		src_pkt_inner_inner = testutils.simple_udp_packet()
		src_pkt_inner_inner = testutils.simple_ip_only_packet()

		src_pkt_inner = testutils.simple_gre_packet(inner_frame=src_pkt_inner_inner)

		src_pkt_base = testutils.simple_nvgre_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

		exp_pkt_inner_inner = testutils.simple_tcp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_inner = testutils.simple_gre_packet(inner_frame=src_pkt_inner_inner)

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################

def npb_simple_3lyr_nvgrev6_gre_ip(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner_inner = testutils.simple_tcp_packet()
#		src_pkt_inner_inner = testutils.simple_udp_packet()
		src_pkt_inner_inner = testutils.simple_ip_only_packet()

		src_pkt_inner = testutils.simple_gre_packet(inner_frame=src_pkt_inner_inner)

		src_pkt_base = testutils.simple_nvgrev6_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

		exp_pkt_inner_inner = testutils.simple_tcp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_inner = testutils.simple_gre_packet(inner_frame=src_pkt_inner_inner)

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 3 layers: Simple NVGRE / GTP-C / UDP
################################################################################

def npb_simple_3lyr_nvgre_gtpc_udp(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner_inner = testutils.simple_tcp_packet()
#		src_pkt_inner_inner = testutils.simple_udp_packet()

		src_pkt_inner = \
			testutils.simple_udp_packet(eth_dst=dmac, eth_src=smac, udp_sport=2123, udp_dport=2123, pktlen=128) / \
			scapy.GTPHeader(version=2,P=0,T=1,length=8,teid=0xcdc) # / \
#			src_pkt_inner_inner

		# derek: I found that for some reason I have to force a recalculation of the
		# checksums on these packets.  I found this snippet online.  At some point,
		# I need to revisit to understand why this better.  Seems to only be a problem
		# with gtp-c?
		del src_pkt_inner.chksum
		src_pkt_inner = src_pkt_inner.__class__(bytes(src_pkt_inner))

		src_pkt_base = testutils.simple_nvgre_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

#		exp_pkt_inner_inner = src_pkt_inner_inner

		exp_pkt_inner = src_pkt_inner

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 3 layers: Simple NVGRE / GTP-U / IP
################################################################################

def npb_simple_3lyr_nvgre_gtpu_ip(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner_inner = testutils.simple_tcp_packet()
#		src_pkt_inner_inner = testutils.simple_udp_packet()
		src_pkt_inner_inner = testutils.simple_ip_only_packet()

		src_pkt_inner = \
			testutils.simple_udp_packet(eth_dst=dmac, eth_src=smac, udp_sport=2152, udp_dport=2152, pktlen=0) / \
			scapy.GTP_U_Header(version=1,PT=1,length=12+100,teid=0xefe) / \
			src_pkt_inner_inner

		src_pkt_base = testutils.simple_nvgre_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

		exp_pkt_inner_inner = testutils.simple_tcp_packet(eth_dst=dmac, eth_src=smac, pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_inner = src_pkt_inner

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 3 layers: Simple GRE / IP / IP
################################################################################

def npb_simple_3lyr_gre_ip_ip(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	dip_nsh        = '192.168.0.1',
	sip_nsh        = '192.168.0.2',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	dip            = '192.168.0.1',
	sip            = '192.168.0.2',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype 
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner_inner = testutils.simple_tcp_packet()
#		src_pkt_inner_inner = testutils.simple_udp_packet()
		src_pkt_inner_inner = testutils.simple_ip_only_packet()

#		src_pkt_inner = testutils.simple_gre_packet(inner_frame=src_pkt_inner_inner)
		src_pkt_inner = scapy.IP(src=sip, dst=dip, proto=4) / src_pkt_inner_inner

		src_pkt_base = testutils.simple_gre_packet(eth_dst=dmac_nsh, eth_src=smac_nsh, ip_src=sip_nsh, ip_dst=dip_nsh, inner_frame=src_pkt_inner)


		# -----------------

		exp_pkt_inner_inner = testutils.simple_tcp_packet(eth_dst=dmac_nsh, eth_src=smac_nsh, pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		#Special case for Overloaded packets where Outer Header has no L2
		if(transport_decap == False): 
			exp_pkt_inner = testutils.simple_ip_packet(eth_dst=dmac_nsh, eth_src=smac_nsh,ip_src=sip, ip_dst=dip, pktlen=14+20, ip_proto=4) / testutils.simple_ip_only_packet()
		else:
			exp_pkt_inner = testutils.simple_ip_packet(eth_dst='00:00:00:00:00:00', eth_src='00:00:00:00:00:00', ip_src=sip, ip_dst=dip, pktlen=14+20, ip_proto=4) / testutils.simple_ip_only_packet()

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################

def npb_simple_3lyr_grev6_ip_ip(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner_inner = testutils.simple_tcp_packet()
#		src_pkt_inner_inner = testutils.simple_udp_packet()
		src_pkt_inner_inner = testutils.simple_ip_only_packet()

#		src_pkt_inner = testutils.simple_gre_packet(inner_frame=src_pkt_inner_inner)
		src_pkt_inner = scapy.IP(src='192.168.0.1', dst='192.168.0.2', proto=4) / src_pkt_inner_inner

		src_pkt_base = testutils.simple_grev6_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

		exp_pkt_inner_inner = testutils.simple_tcp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_inner = testutils.simple_ip_packet(pktlen=14+20, ip_proto=4) / testutils.simple_ip_only_packet()

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 3 layers: Simple GRE / IPv6 / IP
################################################################################

def npb_simple_3lyr_gre_ipv6_ip(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner_inner = testutils.simple_tcp_packet()
#		src_pkt_inner_inner = testutils.simple_udp_packet()
		src_pkt_inner_inner = testutils.simple_ip_only_packet()

#		src_pkt_inner = testutils.simple_gre_packet(inner_frame=src_pkt_inner_inner)
		src_pkt_inner = scapy.IPv6(src='2001:db8:85a3::8a2e:370:7334', dst='2001:db8:85a3::8a2e:370:7335', nh=4) / src_pkt_inner_inner

		src_pkt_base = testutils.simple_gre_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

		exp_pkt_inner_inner = testutils.simple_tcp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_inner = simple_ipv6_packet(pktlen=14+20, ipv6_next_header=4) / testutils.simple_ip_only_packet()

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################

def npb_simple_3lyr_grev6_ipv6_ip(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner_inner = testutils.simple_tcp_packet()
#		src_pkt_inner_inner = testutils.simple_udp_packet()
		src_pkt_inner_inner = testutils.simple_ip_only_packet()

#		src_pkt_inner = testutils.simple_gre_packet(inner_frame=src_pkt_inner_inner)
		src_pkt_inner = scapy.IPv6(src='2001:db8:85a3::8a2e:370:7334', dst='2001:db8:85a3::8a2e:370:7335', nh=4) / src_pkt_inner_inner

		src_pkt_base = testutils.simple_grev6_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

		exp_pkt_inner_inner = testutils.simple_tcp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_inner = simple_ipv6_packet(pktlen=14+20, ipv6_next_header=4) / testutils.simple_ip_only_packet()

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 3 layers: Simple GRE / IP / IPv6
################################################################################

def npb_simple_3lyr_gre_ip_ipv6(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner_inner = testutils.simple_tcp_packet()
#		src_pkt_inner_inner = testutils.simple_udp_packet()
		src_pkt_inner_inner = simple_ipv6_only_packet()

#		src_pkt_inner = testutils.simple_gre_packet(inner_frame=src_pkt_inner_inner)
		src_pkt_inner = scapy.IP(src='192.168.0.1', dst='192.168.0.2', proto=41) / src_pkt_inner_inner

		src_pkt_base = testutils.simple_gre_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

		exp_pkt_inner_inner = testutils.simple_tcpv6_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_inner = testutils.simple_ip_packet(pktlen=14+20, ip_proto=41) / simple_ipv6_only_packet()

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################

def npb_simple_3lyr_grev6_ip_ipv6(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner_inner = testutils.simple_tcp_packet()
#		src_pkt_inner_inner = testutils.simple_udp_packet()
		src_pkt_inner_inner = simple_ipv6_only_packet()

#		src_pkt_inner = testutils.simple_gre_packet(inner_frame=src_pkt_inner_inner)
		src_pkt_inner = scapy.IP(src='192.168.0.1', dst='192.168.0.2', proto=41) / src_pkt_inner_inner

		src_pkt_base = testutils.simple_grev6_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

		exp_pkt_inner_inner = testutils.simple_tcpv6_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_inner = testutils.simple_ip_packet(pktlen=14+20, ip_proto=41) / simple_ipv6_only_packet()

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt
################################################################################
# 3 layers: Simple GRE / IP / UDP
################################################################################

def npb_simple_3lyr_gre_ip_udp(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype 
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

		src_pkt_inner_inner = testutils.simple_udp_packet(ip_tos=0x69)

		src_pkt_inner = scapy.IP(src='192.168.0.1', dst='192.168.0.2', proto=4) / src_pkt_inner_inner

		src_pkt_base = testutils.simple_gre_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)
		#print("---DEBUG src_pkt_base---")
		#print(testutils.format_packet(src_pkt_base))

		# -----------------

#		exp_pkt_inner_inner = testutils.simple_udp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it
		exp_pkt_inner_inner = testutils.simple_udp_packet(ip_tos=0x69) # add 14, because original packet didn't have an l2 on it

		#print("---DEBUG INNER INNER---")
		#print(testutils.format_packet(exp_pkt_inner_inner))

		#Special case for Overloaded packets where Outer Header has no L2
		if(transport_decap == False): 
			exp_pkt_inner = testutils.simple_ip_packet(eth_dst=dmac_nsh, eth_src=smac_nsh,pktlen=14+20, ip_proto=4) / testutils.simple_ip_only_packet() / exp_pkt_inner_inner
		else:
			exp_pkt_inner = testutils.simple_ip_packet(eth_dst='00:00:00:00:00:00', eth_src='00:00:00:00:00:00' ,pktlen=14+20, ip_proto=4) / testutils.simple_ip_only_packet() / exp_pkt_inner_inner

		#print("---DEBUG EXP INNER---")
		#print(testutils.format_packet(exp_pkt_inner))

		exp_pkt_base = src_pkt_base

		#print("---DEBUG EXP BASE---")
		#print(testutils.format_packet(exp_pkt_base))

		exp_pkt_base = src_pkt_base
		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

		#print("---------- Debug Final----------")
		#print(testutils.format_packet(src_pkt))
		#print(exp_pkt)
		#print("---------- Debug ----------")

		return src_pkt, exp_pkt

################################################################################
# 3 layers: Simple GRE / GRE / UDP
################################################################################

def npb_simple_3lyr_gre_gre_udp(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac           = '00:01:02:03:04:05',
	smac           = '00:06:07:08:09:0a',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype 
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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

#		src_pkt_inner_inner = testutils.simple_tcp_packet()
		src_pkt_inner_inner = testutils.simple_udp_packet()
#		src_pkt_inner_inner = testutils.simple_ip_only_packet()

		src_pkt_inner = testutils.simple_gre_packet(inner_frame=src_pkt_inner_inner)
#		src_pkt_inner = scapy.IP(src='192.168.0.1', dst='192.168.0.2', proto=4) / src_pkt_inner_inner

		src_pkt_base = testutils.simple_gre_packet(eth_dst=dmac, eth_src=smac, inner_frame=src_pkt_inner)

		# -----------------

#		exp_pkt_inner_inner = testutils.simple_tcp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it
		exp_pkt_inner_inner = testutils.simple_udp_packet(pktlen=14+100) # add 14, because original packet didn't have an l2 on it

		exp_pkt_inner = testutils.simple_gre_packet(eth_dst=dmac, eth_src=smac, inner_frame=exp_pkt_inner_inner)

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

#		print("---------- Debug ----------")
#		print(testutils.format_packet(src_pkt))
#		print("---------- Debug ----------")

		return src_pkt, exp_pkt


################################################################################
# 3 layers: Simple GRE / VXLAN
################################################################################

def npb_simple_3lyr_gre_vxlan(
	#transport source variables (only used when start_of_chain=False)
	dmac_nsh       = '00:01:02:03:04:05',
	smac_nsh       = '00:06:07:08:09:0a',
	dip_nsh        = '192.168.0.1',
	sip_nsh        = '192.168.0.2',
	vlan_en_nsh    = False,
	vlan_pcp_nsh   = 0,
	vlan_vid_nsh   = 0,
	spi            = 0,
	si             = 0,
	ta             = 0,
	nshtype        = 2,
	sap            = 0,
	vpn            = 0,
	ttl            = 63, # new packets will have a value of 63
	scope          = 0,

	#outer source variables
	dmac_outer           = '00:01:02:03:04:05',
	smac_outer           = '00:06:07:08:09:0a',
	dip_outer            = '192.168.0.1',
	sip_outer            = '192.168.0.2',
	vlan_en        = False, vlan_en_vid = 0, vlan_en_pcp = 0,
	e_en           = False,
	vn_en          = False,
	pktlen         = 100,

	#model flags
	transport_decap= False,
	sf_bitmask     = 0,
	start_of_chain = True,
	end_of_chain   = False,
	scope_term_list = [], # an ordered list scopes and terminates that occur (0 = scope, 1 = term)
	transport_encap= EgressTunnelType.NONE.value,
	bridged_pkt    = False,

	#transport expected variables (only used when end_of_chain=False)
	vlan_en_nsh_exp= None,
	spi_exp        = None,
	si_exp         = None,
	ta_exp         = None,
	nshtype_exp    = None,
	sap_exp        = None,
	vpn_exp        = None,

	#outer expected variables
	vlan_en_exp    = None, vlan_en_exp_vid = 0, vlan_en_exp_pcp = 0,
	e_en_exp       = None,
	vn_en_exp      = None,
	pktlen_exp     = None):

		# -----------------

		if vlan_en_nsh_exp is None: vlan_en_nsh_exp = vlan_en_nsh
		if spi_exp         is None: spi_exp         = spi
		if si_exp          is None: si_exp          = si
		if ta_exp          is None: ta_exp          = ta
		if nshtype_exp     is None: nshtype_exp     = nshtype 
		if sap_exp         is None: sap_exp         = sap
		if vpn_exp         is None: vpn_exp         = vpn

		if vlan_en_exp     is None: vlan_en_exp     = vlan_en;  vlan_en_exp_vid = vlan_en_vid;  vlan_en_exp_pcp = vlan_en_pcp
		if e_en_exp        is None: e_en_exp        = e_en
		if vn_en_exp       is None: vn_en_exp       = vn_en
		if pktlen_exp      is None: pktlen_exp      = pktlen

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
		src_pkt_inner_inner = testutils.simple_udp_packet()

		#I think I need to hand create without the L2 Src/Dst
#		src_pkt_inner = testutils.simple_vxlan_packet(ip_src=sip_outer, ip_dst=dip_outer, udp_dport=4789, inner_frame=src_pkt_inner_inner)
		src_pkt_inner = simple_vxlan_packet_no_l2(ip_src=sip_outer, ip_dst=dip_outer, udp_dport=4789, inner_frame=src_pkt_inner_inner)

		src_pkt_base = testutils.simple_gre_packet(eth_dst=dmac_nsh, eth_src=smac_nsh, ip_src=sip_nsh, ip_dst=dip_nsh, inner_frame=src_pkt_inner)


		# -----------------

		exp_pkt_inner_inner = testutils.simple_udp_packet(pktlen=100)

		#I think I need to hand create without the L2 Src/Dst
		if(transport_decap == True):
			exp_pkt_inner = testutils.simple_vxlan_packet(eth_dst=0, eth_src=0, ip_src=sip_outer, ip_dst=dip_outer, udp_dport=4789,   pktlen=14+100,  inner_frame=exp_pkt_inner_inner)
		else:
			exp_pkt_inner = testutils.simple_vxlan_packet(ip_src=sip_outer, ip_dst=dip_outer, udp_dport=4789,   pktlen=14+100, inner_frame=exp_pkt_inner_inner)

		exp_pkt_base = src_pkt_base

		# -----------------
		# src: add nsh hdr
		# -----------------

		if(start_of_chain == False):
			src_pkt = npb_model_mac_encap(dmac_nsh, smac_nsh, vlan_en_nsh, vlan_pcp_nsh, vlan_vid_nsh, spi, si, ta, nshtype, scope, sap, vpn, ttl, src_pkt_base)
		else:
			src_pkt = src_pkt_base

		# -----------------
		# model
		# -----------------

		model_pkt = npb_model(
			# possible result packets
			[exp_pkt_base, exp_pkt_inner, exp_pkt_inner_inner],

			# nsh values
			spi_exp,
			si_exp,
			ta_exp,
			nshtype_exp,
			sap_exp,
			vpn_exp,
			ttl,
			scope,

			# model flags
			bridged_pkt,
			transport_decap,
			sf_bitmask,
			start_of_chain,
			end_of_chain,
			scope_term_list,
			transport_encap,

			# encap values
			dmac_nsh,
			smac_nsh,
			vlan_en_nsh_exp,
			vlan_pcp_nsh,
			vlan_vid_nsh
		)

		# -----------------
		# exp: add nsh hdr
		# -----------------

		exp_pkt = model_pkt

		# -----------------

		#print("---------- Debug ----------")
		#print(testutils.format_packet(src_pkt))
		#print("---------- Debug ----------")

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

# simple_ipv6_only_packet =      l3 ipv4 / l6 tcp

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

################################################################################

# a missing Barefoot routine for VXLAN with no L2

def simple_vxlan_packet_no_l2(pktlen=300,
                        ip_src='192.168.0.1',
                        ip_dst='192.168.0.2',
                        ip_tos=0,
                        ip_ecn=None,
                        ip_dscp=None,
                        ip_ttl=64,
                        ip_id=0x0001,
                        ip_flags=0x0,
                        udp_sport=1234,
                        udp_dport=4789,
                        with_udp_chksum=True,
                        ip_ihl=None,
                        ip_options=False,
                        vxlan_reserved1=0x000000,
                        vxlan_vni=0xaba,
                        vxlan_reserved2=0x00,
                        inner_frame=None):
    """
    Return a simple dataplane VXLAN packet

    Supports a few parameters:
    @param len Length of packet in bytes w/o CRC
    @param ip_src IP source
    @param ip_dst IP destination
    @param ip_tos IP ToS
    @param ip_ecn IP ToS ECN
    @param ip_dscp IP ToS DSCP
    @param ip_ttl IP TTL
    @param ip_id IP ID
    @param ip_flags IP Flags
    @param udp_sport UDP source port
    @param udp_dport UDP dest port (IANA) = 4789 (VxLAN)
    @param vxlan_reserved1 reserved field (3B)
    @param vxlan_vni VXLAN Network Identifier
    @param vxlan_reserved2 reserved field (1B)
    @param inner_frame The inner Ethernet frame

    Generates a simple VXLAN packet. Users shouldn't assume anything about
    this packet other than that it is a valid IP/UDP/VXLAN frame.
    """
    #if testutils.scapy.VXLAN is None:
    #    logging.error(
    #        "A VXLAN packet was requested but VXLAN is not supported "
    #        "by your Scapy. See README for more information")
    #    return None

    if testutils.MINSIZE > pktlen:
        pktlen = testutils.MINSIZE

    if with_udp_chksum:
        udp_hdr = scapy.UDP(sport=udp_sport, dport=udp_dport)
    else:
        udp_hdr = scapy.UDP(sport=udp_sport, dport=udp_dport, chksum=0)

    ip_tos = testutils.ip_make_tos(ip_tos, ip_ecn, ip_dscp)

    if not ip_options:
        pkt = scapy.IP(src=ip_src, dst=ip_dst, tos=ip_tos, ttl=ip_ttl,
                            id=ip_id, flags=ip_flags, ihl=ip_ihl) / \
                  udp_hdr
    else:
        pkt = scapy.IP(src=ip_src, dst=ip_dst, tos=ip_tos, ttl=ip_ttl,
                            id=ip_id, flags=ip_flags, ihl=ip_ihl,
                            options=ip_options) / \
                  udp_hdr

    pkt = pkt / scapy.VXLAN(flags=0x8, vni=vxlan_vni, reserved1=vxlan_reserved1,
                             reserved2=vxlan_reserved2)

    if inner_frame:
        pkt = pkt / inner_frame
    else:
        pkt = pkt / testutils.simple_tcp_packet(pktlen=pktlen - len(pkt))

    return pkt

################################################################################

# a missing Barefoot routine for VXLAN with no L2

def simple_spbm_tcp_packet(
    pktlen=100,
    eth_dst="00:01:02:03:04:05",
    eth_src="00:06:07:08:09:0a",
    dl_vlan_outer=20,
    dl_vlan_pcp_outer=0,
    dl_vlan_cfi_outer=0,
    vlan_vid=10,
    vlan_pcp=0,
    dl_vlan_cfi=0,
    ip_src="192.168.0.1",
    ip_dst="192.168.0.2",
    ip_tos=0,
    ip_ecn=None,
    ip_dscp=None,
    ip_ttl=64,
    tcp_sport=1234,
    tcp_dport=80,
    ip_ihl=None,
    ip_options=False,
):
    """
    Return a doubly tagged dataplane TCP packet

    Supports a few parameters:
    @param len Length of packet in bytes w/o CRC
    @param eth_dst Destinatino MAC
    @param eth_src Source MAC
    @param dl_vlan_outer Outer VLAN ID
    @param dl_vlan_pcp_outer Outer VLAN priority
    @param dl_vlan_cfi_outer Outer VLAN cfi bit
    @param vlan_vid Inner VLAN ID
    @param vlan_pcp VLAN priority
    @param dl_vlan_cfi VLAN cfi bit
    @param ip_src IP source
    @param ip_dst IP destination
    @param ip_tos IP ToS
    @param ip_ecn IP ToS ECN
    @param ip_dscp IP ToS DSCP
    @param tcp_dport TCP destination port
    @param ip_sport TCP source port

    Generates a TCP request.  Users
    shouldn't assume anything about this packet other than that
    it is a valid ethernet/IP/TCP frame.
    """

    if testutils.MINSIZE > pktlen:
        pktlen = testutils.MINSIZE

    ip_tos = testutils.ip_make_tos(ip_tos, ip_ecn, ip_dscp)

    # Note Dot1Q.id is really CFI
    pkt = (
        scapy.Ether(dst=eth_dst, src=eth_src, type=0x88a8)
        / scapy.Dot1Q(prio=dl_vlan_pcp_outer, id=dl_vlan_cfi_outer, vlan=dl_vlan_outer, type=0x88e7)
#       / scapy.Dot1Q(prio=vlan_pcp, id=dl_vlan_cfi, vlan=vlan_vid) # derek removed
        / scapy.SPBM(prio=1,isid=20011) # derek added
        / scapy.Ether(dst=eth_dst, src=eth_src)
        / scapy.IP(src=ip_src, dst=ip_dst, tos=ip_tos, ttl=ip_ttl, ihl=ip_ihl)
        / scapy.TCP(sport=tcp_sport, dport=tcp_dport)
    )
    
    pkt = pkt / codecs.decode(
        "".join(["%02x" % (x % 256) for x in range(pktlen - len(pkt))]), "hex"
    )
    
    return pkt
