// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.

#ifndef HEADERS_H4
#define HEADERS_H4

header_type l2_metadata_t {
	fields { 
	dstOUI : 24;
	dstSTA : 24;
	srcOUI : 24;
	srcSTA : 24;
	outer_bd : 16;
	inner_bd : 16;
	pQXqBl : 16;
	dndsBa : 12;
	eDTSaM : 2;
	dhmjSj : 1;
	AlAsan : 1;
	FZIXaP : 1;
	JFtqsz : 1;
	OjymPH : 1;
	mUhTtj : 1;
	prio : 3;
	}
}

header_type egress_l2_metadata_t {
	fields { 
	dstOUI : 24;
	dstSTA : 24;
	srcOUI : 24;
	srcSTA : 24;
	outer_bd : 16;
	inner_bd : 16;
	VqbwXd : 16;
	vid : 12;
	egress_port : 9;
	MXEAcT : 1;
	GbMjEH : 1;
	DxjBnx : 1;
	fqhobT : 1;
	vRiVoY : 1;
	xALOuI : 1;
	}
}

header_type WeFXyH {
	fields { 
	VLGXXG : 8;
	OTmmdU : 1;
	vxRZLD : 1;
	lhgqZR : 1;
	PqcjFS : 1;
	TNJQUK : 1;
	}
}

header_type ipv4_metadata_t {
	fields { 
	srcAddr : 32;
	dstAddr : 32;
	vrf : 16;
	}
}

header_type ipv6_metadata_t {
	fields { 
	srcAddr : 128;
	dstAddr : 128;
	}
}

header_type port_metadata_t {
	fields { 
	ouVJSA : 14;
	cCOHKE : 1;
	huEsCO : 1;
	vid : 12;
	}
}

header_type RjEUbC {
	fields { 
	ZtjVUq : 1;
	tgfjtx : 1;
	}
}

header_type pKpXdV {
	fields { 
	zVITkG : 8;
	}
}

header_type AbPvhk {
	fields { 
	SXktkN : 16;
	}
}

header_type ethernet_t {
	fields { 
	dstOUI : 24;
	dstSTA : 24;
	srcOUI : 24;
	srcSTA : 24;
	ethertype : 16;
	}
}

header_type vlan_tag_t {
	fields { 
	prio : 3;
	cfi : 1;
	vid : 12;
	ethertype : 16;
	}
}

header_type ipv4_t {
	fields { 
	version        : 4;
	ihl            : 4;
	diffserv       : 8;
	totalLen       : 16;
	identification : 16;
	flags          : 3;
	fragOffset     : 13;
	ttl            : 8;
	protocol       : 8;
	hdrChecksum    : 16;
	srcAddr        : 32;
	dstAddr        : 32;
	}
}

header_type ipv6_t {
	fields { 
	version      : 4;
	trafficClass : 8;
	flowLabel    : 20;
	payloadLen   : 16;
	nextHdr      : 8;
	hopLimit     : 8;
	srcAddr      : 128;
	dstAddr      : 128;
	}
}

header_type udp_t {
	fields { 
	srcPort  : 16;
	dstPort  : 16;
	length_  : 16;
	checksum : 16;
	}
}

header_type arp_t {
	fields { 
	hwType       : 16;
	protoType    : 16;
	hwAddrLen    : 8;
	protoAddrLen : 8;
	opcode       : 16;
	}
}

header_type vxlan_t {
	fields { 
	flags      : 8;
	reserved_1 : 24;
	vni        : 24;
	reserved_2 : 8;
	}
}

#endif // HEADERS_H4

#ifndef PARSER_H4
#define PARSER_H4

header ethernet_t outer_ethernet;
header ethernet_t inner_ethernet;
header vlan_tag_t outer_vlan_tag;
header vlan_tag_t inner_vlan_tag;
header ipv4_t outer_ipv4;
header ipv4_t inner_ipv4;
header ipv6_t outer_ipv6;
header ipv6_t inner_ipv6;
header udp_t udp;
header vxlan_t vxlan;
header arp_t arp;

metadata l2_metadata_t l2_metadata;
metadata egress_l2_metadata_t egress_l2_metadata;
metadata port_metadata_t port_metadata;
metadata ipv4_metadata_t ipv4_metadata;
metadata ipv6_metadata_t ipv6_metadata;
metadata RjEUbC YKjpKX;
metadata WeFXyH PdKkSx;
metadata pKpXdV ozKgHM;
metadata AbPvhk Eqzejr;

parser parse_outer_vlan_tag { 
	extract(outer_vlan_tag );
	return select( outer_vlan_tag.ethertype ) {
		0x0800 : parse_outer_ipv4;
		0x86dd : parse_outer_ipv6;
		0x0806 : parse_arp;
		default : ingress;
	}
}

parser start { 
	return parse_ethernet;
}

parser parse_inner_ipv6 { 
	extract(inner_ipv6 );
	return ingress;
}

parser parse_vxlan { 
	extract(vxlan );
	set_metadata(l2_metadata.eDTSaM, 0x1 );
	return parse_inner_ethernet;
}

parser parse_arp { 
	extract(arp );
	return ingress;
}

parser parse_outer_ipv4 { 
	extract(outer_ipv4 );
	return select( outer_ipv4.fragOffset, outer_ipv4.ihl, outer_ipv4.protocol ) {
		0x00000511 : parse_udp;
		default : ingress;
	}
}

parser parse_outer_ipv6 { 
	extract(outer_ipv6 );
	return ingress;
}

parser parse_udp { 
	extract(udp );
	return select( udp.dstPort ) {
		0x12b5 : parse_vxlan;
		default : ingress;
	}
}

parser parse_ethernet { 
	extract(outer_ethernet);
	set_metadata(l2_metadata.dstOUI, outer_ethernet.dstOUI );
	set_metadata(l2_metadata.dstSTA, outer_ethernet.dstSTA );
	set_metadata(l2_metadata.srcOUI, outer_ethernet.srcOUI );
	set_metadata(l2_metadata.srcSTA, outer_ethernet.srcSTA );
	return select( outer_ethernet.ethertype ) {
		0x8100 : parse_outer_vlan_tag;
		0x0800 : parse_outer_ipv4;
		0x86dd : parse_outer_ipv6;
		0x0806 : parse_arp;
		default : ingress;
	}
}

parser parse_inner_ipv4 { 
	extract(inner_ipv4 );
	return ingress;
}

parser parse_inner_ethernet { 
	extract(inner_ethernet );
	return select( inner_ethernet.ethertype ) {
		0x0800 : parse_inner_ipv4;
		0x86dd : parse_inner_ipv6;
		default : ingress;
	}
}

#endif // PARSER_H4

#ifdef __TARGET_BMV2__
#define BMV2
#endif
#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
#else
#include "includes/tofino.p4"
#endif

@pragma pa_solitary ingress l2_metadata.outer_bd
@pragma pa_solitary ingress l2_metadata.inner_bd
@pragma pa_solitary ingress l2_metadata.pQXqBl
@pragma pa_solitary ig_intr_md_for_tm.ucast_egress_port

field_list RgamWT { 
	ozKgHM.zVITkG;
	l2_metadata.srcOUI;
	l2_metadata.srcSTA;
	l2_metadata.outer_bd;
	l2_metadata.inner_bd;
}

field_list jeqIuB { 
	ozKgHM.zVITkG;
	l2_metadata.outer_bd;
	inner_ethernet.srcOUI;
	inner_ethernet.srcSTA;
	outer_ipv4.srcAddr;
}

action XVktOe(rJWdDI) { 
	modify_field(ipv4_metadata.vrf, rJWdDI );
}

action sgfrDS() { 
	no_op( );
}

action YpQxby() { 
	modify_field(l2_metadata.JFtqsz, 0x1 );
	modify_field(l2_metadata.OjymPH, 0x1 );
}

action yTtrnk(JuQPYe) { 
#ifdef BMV2
	register_write(XpsIvD, JuQPYe, 0x1 );
#endif
}

action uZpeEH() { 
	modify_field(egress_l2_metadata.DxjBnx, 0x1 );
	modify_field(egress_l2_metadata.xALOuI, 0x1 );
	add(egress_l2_metadata.VqbwXd, egress_l2_metadata.outer_bd, 0x1000 );
}

action sRuUvS(ZPSBzg,NldXIO,zbyrRT,iCFOSL,gJQdqX,EsFJTP) { 
	modify_field(l2_metadata.pQXqBl, ZPSBzg );
	modify_field(l2_metadata.mUhTtj, 0x1 );
	modify_field(PdKkSx.VLGXXG, NldXIO );
	modify_field(PdKkSx.OTmmdU, zbyrRT );
	modify_field(PdKkSx.lhgqZR, iCFOSL );
	modify_field(PdKkSx.vxRZLD, gJQdqX );
	modify_field(PdKkSx.PqcjFS, EsFJTP );
}

action TwIQHU(ZJeNes) { 
	modify_field(Eqzejr.SXktkN, ZJeNes );
}

action QYBPRQ(ObALmB,NldXIO,zbyrRT,iCFOSL,gJQdqX,EsFJTP,LqZpLg) { 
	modify_field(l2_metadata.outer_bd, ObALmB );
	modify_field(l2_metadata.mUhTtj, LqZpLg );
	modify_field(PdKkSx.VLGXXG, NldXIO );
	modify_field(PdKkSx.OTmmdU, zbyrRT );
	modify_field(PdKkSx.lhgqZR, iCFOSL );
	modify_field(PdKkSx.vxRZLD, gJQdqX );
	modify_field(PdKkSx.PqcjFS, EsFJTP );
}

action FjFvSI() { 
	generate_digest(0x0, RgamWT );
}

action ZByrIe() { 
	modify_field(outer_ethernet.ethertype, outer_vlan_tag.ethertype );
	modify_field(l2_metadata.prio, outer_vlan_tag.prio );
	remove_header(outer_vlan_tag );
}

action tsXBkz(hkkrmJ) { 
	modify_field(egress_l2_metadata.DxjBnx, 0x1 );
	modify_field(egress_l2_metadata.VqbwXd, hkkrmJ );
}

action GXegax(NldXIO,zbyrRT,iCFOSL,gJQdqX,EsFJTP) { 
	modify_field(l2_metadata.pQXqBl, port_metadata.vid, 0x0FFF);
	modify_field(l2_metadata.mUhTtj, 0x1 );
	modify_field(PdKkSx.VLGXXG, NldXIO );
	modify_field(PdKkSx.OTmmdU, zbyrRT );
	modify_field(PdKkSx.lhgqZR, iCFOSL );
	modify_field(PdKkSx.vxRZLD, gJQdqX );
	modify_field(PdKkSx.PqcjFS, EsFJTP );
}

action ukhAli() { 
	modify_field(egress_l2_metadata.vRiVoY, 0x1 );
	modify_field(egress_l2_metadata.VqbwXd, egress_l2_metadata.outer_bd );
}

action jYRXTf() { 
//	modify_field(l2_metadata.outer_bd, outer_vlan_tag.vid);
}

action JnIDid() { 
	modify_field(egress_l2_metadata.GbMjEH, 0x1 );
	modify_field(egress_l2_metadata.MXEAcT, 0x1 );
	modify_field(egress_l2_metadata.VqbwXd, egress_l2_metadata.outer_bd );
}

action JZMMTw() { 
	modify_field(PdKkSx.TNJQUK, 0x1 );
}

action KQcrRq() { 
	modify_field(l2_metadata.FZIXaP, 0x1 );
	modify_field(ozKgHM.zVITkG, 0x1 );
}

action xsDQie(yppSOY) { 
	modify_field(egress_l2_metadata.fqhobT, 0x1 );
	modify_field(egress_l2_metadata.inner_bd, yppSOY );
	modify_field(ig_intr_md_for_tm.ucast_egress_port, yppSOY );
	modify_field(egress_l2_metadata.egress_port, yppSOY );
}

action uYBjrZ() { 
}

action GrmhMU() { 
	modify_field(l2_metadata.dhmjSj, 0x1 );
}

action uNBXVV() { 
	modify_field(ipv4_metadata.srcAddr, inner_ipv4.srcAddr );
	modify_field(ipv4_metadata.dstAddr, inner_ipv4.dstAddr );
	modify_field(ipv6_metadata.srcAddr, outer_ipv6.srcAddr );
	modify_field(ipv6_metadata.dstAddr, outer_ipv6.dstAddr );
	modify_field(l2_metadata.dstOUI, inner_ethernet.dstOUI );
	modify_field(l2_metadata.dstSTA, inner_ethernet.dstSTA );
	modify_field(l2_metadata.srcOUI, inner_ethernet.srcOUI );
	modify_field(l2_metadata.srcSTA, inner_ethernet.srcSTA );
}

action xfABlB() { 
	modify_field(l2_metadata.AlAsan, 0x1 );
	modify_field(ozKgHM.zVITkG, 0x0 );
}

action jwLDdv() { 
//	modify_field(l2_metadata.outer_bd, port_metadata.vid );
}

action MbuqfL() { 
	modify_field(egress_l2_metadata.dstOUI, l2_metadata.dstOUI );
	modify_field(egress_l2_metadata.dstSTA, l2_metadata.dstSTA );
	modify_field(egress_l2_metadata.srcOUI, l2_metadata.srcOUI );
	modify_field(egress_l2_metadata.srcSTA, l2_metadata.srcSTA );
	modify_field(egress_l2_metadata.outer_bd, l2_metadata.outer_bd );
}

action add_vlan_tag() { 
	add_header(outer_vlan_tag );
	modify_field(outer_vlan_tag.vid, egress_l2_metadata.vid );
//	modify_field(outer_vlan_tag.prio, l2_metadata.prio );
	modify_field(outer_vlan_tag.ethertype, outer_ethernet.ethertype );
	modify_field(outer_ethernet.ethertype, 0x8100 );
}

action bd2vid(ObALmB) { 
	modify_field(egress_l2_metadata.vid, ObALmB );
	remove_header(outer_vlan_tag );
}

action ruSbdS() { 
}

action QXYBjG() { 
	generate_digest(0x0, jeqIuB );
}

action SBqFEe(UWsnEK) { 
	modify_field(l2_metadata.inner_bd, UWsnEK );
}

action zEaBcj() { 
	modify_field(l2_metadata.eDTSaM, 0x0 );
	modify_field(l2_metadata.inner_bd, port_metadata.ouVJSA );
	modify_field(ipv4_metadata.srcAddr, outer_ipv4.srcAddr );
	modify_field(ipv4_metadata.dstAddr, outer_ipv4.dstAddr );
	modify_field(ipv6_metadata.srcAddr, inner_ipv6.srcAddr );
	modify_field(ipv6_metadata.dstAddr, inner_ipv6.dstAddr );
	modify_field(l2_metadata.dstOUI, outer_ethernet.dstOUI );
	modify_field(l2_metadata.dstSTA, outer_ethernet.dstSTA );
	modify_field(l2_metadata.srcOUI, outer_ethernet.srcOUI );
	modify_field(l2_metadata.srcSTA, outer_ethernet.srcSTA );
}

action wpFyFj(NldXIO,zbyrRT,iCFOSL,gJQdqX,EsFJTP) { 
//	modify_field(l2_metadata.pQXqBl, outer_vlan_tag.vid, 0x0FFF );
	modify_field(l2_metadata.mUhTtj, 0x1 );
	modify_field(PdKkSx.VLGXXG, NldXIO );
	modify_field(PdKkSx.OTmmdU, zbyrRT );
	modify_field(PdKkSx.lhgqZR, iCFOSL );
	modify_field(PdKkSx.vxRZLD, gJQdqX );
	modify_field(PdKkSx.PqcjFS, EsFJTP );
}

action Ayapvg(ZPSBzg) { 
	modify_field(l2_metadata.outer_bd, ZPSBzg );
}

action nop() { 
	no_op( );
}

action set_ingress_port_properties(DSyDIW,wPlBaD,jsYLqr,tTfUVS) { 
	modify_field(port_metadata.ouVJSA, DSyDIW );
	modify_field(port_metadata.cCOHKE, wPlBaD );
	modify_field(port_metadata.vid, jsYLqr );
	modify_field(port_metadata.huEsCO, tTfUVS );
}

table ingress_port_properties {
	reads{
		ig_intr_md.ingress_port : exact;
	}
	actions{ 
		set_ingress_port_properties;
	}
	size : 288;
}

table rmac {
	reads{
		outer_ethernet.dstOUI : exact;
		outer_ethernet.dstSTA : exact;
	}
	actions{ 
		GrmhMU;
	}
	size : 64;
}

table ceGwFc {
	reads{
		outer_ethernet.dstOUI : exact;
		outer_ethernet.dstSTA : exact;
		outer_ipv4.dstAddr : exact;
		l2_metadata.eDTSaM : exact;
	}
	actions{ 
		uNBXVV;
		zEaBcj;
	}
	size : 1024;
}

table GiINoN {
	reads{
		port_metadata.ouVJSA : ternary;
		outer_vlan_tag : valid;
		outer_vlan_tag.vid : ternary;
	}
	actions{ 
		jwLDdv;
		Ayapvg;
		jYRXTf;
	}
	size : 4096;
}

table chPApZ {
	reads{
		outer_ipv4.srcAddr : exact;
	}
	actions{ 
		SBqFEe;
		KQcrRq;
	}
	size : 4096;
}

table KPlvUi {
	reads{
		vxlan.vni : exact;
	}
	actions{ 
		QYBPRQ;
		YpQxby;
	}
	size : 4096;
}

table jubrcZ {
	reads{
		port_metadata.vid : exact;
	}
	actions{ 
		GXegax;
	}
	size : 4096;
}

table RmXtve {
	reads{
		port_metadata.ouVJSA : exact;
		outer_vlan_tag.vid : exact;
	}
	actions{ 
		sRuUvS;
		sgfrDS;
	}
	size : 1024;
}

table FyMYiX {
	reads{
		outer_vlan_tag.vid : exact;
	}
	actions{ 
		wpFyFj;
	}
	size : 4096;
}

table FObudl {
	
	actions{ 
		QXYBjG;
	}
	size : 1;
}

table KhzFiy {
	reads{
		l2_metadata.pQXqBl : ternary;
		l2_metadata.dstOUI : exact;
		l2_metadata.dstSTA : exact;
	}
	actions{ 
		JZMMTw;
	}
	size : 512;
}

register XpsIvD {
	width : 1;
	static : OsNzCx;
	instance_count: 65536;
}

table OsNzCx {
	reads{
		l2_metadata.srcOUI : exact;
		l2_metadata.srcSTA : exact;
		l2_metadata.outer_bd : exact;
		l2_metadata.inner_bd : exact;
	}
	actions{ 
		yTtrnk;
		xfABlB;
	}
	size : 65536;
}

table GKgaxO {
	
	actions{ 
		FjFvSI;
	}
	size : 1;
}

table FsxDka {
	reads{
		PdKkSx.VLGXXG : exact;
		ipv4_metadata.dstAddr : lpm;
	}
	actions{ 
		XVktOe;
	}
	size : 16384;
}

@pragma atcam_partition_index ipv4_metadata.vrf
@pragma atcam_number_partitions 16384
table XWEKAE {
	reads{
		ipv4_metadata.vrf : exact;
		ipv4_metadata.dstAddr : lpm;
	}
	actions{ 
		TwIQHU;
	}
	size : 147456;
}

table fDUvPP {
	reads{
		PdKkSx.VLGXXG : exact;
		ipv4_metadata.dstAddr : exact;
	}
	actions{ 
		TwIQHU;
		sgfrDS;
	}
	size : 65536;
}

table sFQXXt {
	
	actions{ 
		MbuqfL;
	}
	size : 1;
}

table OgtsFH {
	reads{
		egress_l2_metadata.dstOUI : exact;
		egress_l2_metadata.dstSTA : exact;
	}
	actions{ 
		JnIDid;
		uYBjrZ;
	}
	size : 1;
}

table AosIFt {
	
	actions{ 
		uZpeEH;
	}
	size : 1;
}

table UHdtQj {
	
	actions{ 
		ukhAli;
	}
	size : 1;
}

table PHSvkl {
	reads{
		egress_l2_metadata.dstOUI : exact;
		egress_l2_metadata.dstSTA : exact;
		egress_l2_metadata.outer_bd : exact;
	}
	actions{ 
		xsDQie;
		tsXBkz;
		ruSbdS;
	}
	size : 65536;
}

table LbcSdm {
	
	actions{ 
		ZByrIe;
	}
	size : 1;
}

control ingress { 
	if (ig_intr_md.resubmit_flag == 0x0) { 
		apply( ingress_port_properties );

	}

	apply( rmac );

	apply( ceGwFc ) {
		zEaBcj {
			if (port_metadata.huEsCO == 0x1) { 
				apply( GiINoN );

			}

			if ( valid( outer_vlan_tag ) ) { 
				apply( RmXtve ) {
					sgfrDS {
						apply( FyMYiX );

					}
				}
			}

			apply( jubrcZ );

		}
		uNBXVV {
			apply( chPApZ );

			apply( KPlvUi );

		}
	}
	if ((port_metadata.cCOHKE == 0x0) and (l2_metadata.FZIXaP == 0x0)) { 
		apply( OsNzCx );

	}

	if ((l2_metadata.JFtqsz == 0x0) and (l2_metadata.OjymPH == 0x0)) { 
		apply( KhzFiy );

	}

	if (l2_metadata.outer_bd != 0x0) { 
		apply( sFQXXt );

	}

	if ((((YKjpKX.ZtjVUq == 0x0) and (YKjpKX.tgfjtx == 0x0)) and (l2_metadata.JFtqsz == 0x0)) and (PdKkSx.TNJQUK == 0x1)) { 
		if ((PdKkSx.OTmmdU == 0x1) and (((l2_metadata.eDTSaM == 0x0) and ( valid( outer_ipv4 ) )) or ((l2_metadata.eDTSaM != 0x0) and ( valid( inner_ipv4 ) )))) { 
			apply( fDUvPP ) {
				sgfrDS {
					apply( FsxDka );

					if (ipv4_metadata.vrf != 0x0) { 
						apply( XWEKAE );

					}

				}
			}
		}

	}

	if (l2_metadata.JFtqsz == 0x0) { 
		apply( PHSvkl ) {
			ruSbdS {
				apply( OgtsFH ) {
					uYBjrZ {
						if ((egress_l2_metadata.dstOUI & 0x10000) == 0x10000) { 
							apply( AosIFt );

						}

						apply( UHdtQj );

					}
				}
			}
		}
	}

	if (l2_metadata.FZIXaP == 0x1) { 
		apply( FObudl );

	}

	if (l2_metadata.AlAsan == 0x1) { 
		apply( GKgaxO );

	}

	if ( valid( outer_vlan_tag ) ) { 
		apply( LbcSdm );

	}

}

table assign_vid {
	reads{
		egress_l2_metadata.outer_bd : exact;
	}
	actions{ 
		bd2vid;
	}
	size : 4096;
}

table add_vlan_tag {
	reads{
		egress_l2_metadata.vid : exact;
		egress_l2_metadata.egress_port : exact;
	}
	actions{ 
		nop;
		add_vlan_tag;
	}
	size : 64;
}

control egress { 
	apply( assign_vid );

    apply( add_vlan_tag );

}
