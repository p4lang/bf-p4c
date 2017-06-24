// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.

#ifndef HEADERS_H4
#define HEADERS_H4

header_type FSEWoG {
	fields { 
	jlUFzz : 24;
	WTfhFM : 24;
	qiziyI : 24;
	iXArIT : 24;
	TpUrJg : 16;
	bcqHSY : 16;
	pQXqBl : 16;
	dndsBa : 12;
	eDTSaM : 2;
	dhmjSj : 1;
	AlAsan : 1;
	FZIXaP : 1;
	JFtqsz : 1;
	OjymPH : 1;
	mUhTtj : 1;
	EzGKVg : 3;
	}
}

header_type gLIUwA {
	fields { 
	WzPLog : 24;
	RSWubU : 24;
	UuTZpv : 24;
	CHfqJg : 24;
	OOQMnL : 16;
	YztRYj : 16;
	VqbwXd : 16;
	VMHYPO : 12;
	Zyqigm : 9;
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

header_type VjZMBB {
	fields { 
	zaLsws : 32;
	SWwbkW : 32;
	qXPfMg : 16;
	}
}

header_type JktDqe {
	fields { 
	oVVbhH : 128;
	lmbRaR : 128;
	}
}

header_type nOCELQ {
	fields { 
	ouVJSA : 14;
	cCOHKE : 1;
	huEsCO : 1;
	nsEAdO : 12;
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

header_type LiSFTn {
	fields { 
	CEkqjr : 24;
	KdEucT : 24;
	mLIwDF : 24;
	meZADn : 24;
	KRvnNj : 16;
	}
}

header_type HAiDhC {
	fields { 
	FRllQZ : 3;
	YLtmaX : 1;
	OGqRQd : 12;
	VRmbYA : 16;
	}
}

header_type WLPffh {
	fields { 
	KfQbFE : 4;
	nwoREU : 4;
	rJkUrJ : 8;
	yhxNGf : 16;
	ZNiuLN : 16;
	OBSfSq : 3;
	CUoLAG : 13;
	gKCVqf : 8;
	MvgVaL : 8;
	igtXTf : 16;
	FNBJdE : 32;
	LdVtae : 32;
	}
}

header_type FXXYdo {
	fields { 
	dkBwfS : 4;
	zBSMmJ : 8;
	mChDtU : 20;
	twJpzV : 16;
	LDLtbo : 8;
	cQJLPb : 8;
	fYguoo : 128;
	RBgDwk : 128;
	}
}

header_type IJWRam {
	fields { 
	LOGOuD : 16;
	DegPYg : 16;
	FARNxS : 16;
	TTQEfm : 16;
	}
}

header_type ZBAjhR {
	fields { 
	CWpThE : 16;
	VBzPbU : 16;
	NyFLWm : 8;
	FiAzBr : 8;
	FuFthg : 16;
	}
}

header_type BNVnDi {
	fields { 
	HiBxeh : 8;
	qEGcKx : 24;
	MmjnLs : 24;
	QphDZZ : 8;
	}
}

#endif // HEADERS_H4

#ifndef PARSER_H4
#define PARSER_H4

header LiSFTn McGCgL;
header LiSFTn yovXod;
header HAiDhC OpBnZq;
header HAiDhC ZecaRT;
header WLPffh gOeqxi;
header WLPffh sxhDzR;
header FXXYdo jdMBYC;
header FXXYdo flxIhi;
header IJWRam QXYDDH;
header BNVnDi TPRTmY;
header ZBAjhR APcWgb;
metadata FSEWoG mkMLHZ;
metadata gLIUwA ScmCsW;
metadata nOCELQ sTsPkb;
metadata VjZMBB MeZwMk;
metadata JktDqe TmTnvj;
metadata RjEUbC YKjpKX;
metadata WeFXyH PdKkSx;
metadata pKpXdV ozKgHM;
metadata AbPvhk Eqzejr;

parser uDdoOp { 
	extract(OpBnZq );
	return select( OpBnZq.VRmbYA ) {
		0x0800 : GSUPLB;
		0x86dd : kajxLh;
		0x0806 : bMjBTK;
		default : ingress;
	}
}

parser start { 
	return arHTBf;
}

parser pRDQQI { 
	extract(jdMBYC );
	return ingress;
}

parser GWraOM { 
	extract(TPRTmY );
	set_metadata(mkMLHZ.eDTSaM, 0x1 );
	return ZaLpPF;
}

parser bMjBTK { 
	extract(APcWgb );
	return ingress;
}

parser GSUPLB { 
	extract(gOeqxi );
	return select( gOeqxi.CUoLAG, gOeqxi.nwoREU, gOeqxi.MvgVaL ) {
		0x00000511 : HGKBoJ;
		default : ingress;
	}
}

parser kajxLh { 
	extract(flxIhi );
	return ingress;
}

parser HGKBoJ { 
	extract(QXYDDH );
	return select( QXYDDH.DegPYg ) {
		0x12b5 : GWraOM;
		default : ingress;
	}
}

parser arHTBf { 
	extract(McGCgL );
	set_metadata(mkMLHZ.jlUFzz, McGCgL.CEkqjr );
	set_metadata(mkMLHZ.WTfhFM, McGCgL.KdEucT );
	set_metadata(mkMLHZ.qiziyI, McGCgL.mLIwDF );
	set_metadata(mkMLHZ.iXArIT, McGCgL.meZADn );
	return select( McGCgL.KRvnNj ) {
		0x8100 : uDdoOp;
		0x0800 : GSUPLB;
		0x86dd : kajxLh;
		0x0806 : bMjBTK;
		default : ingress;
	}
}

parser eKvOhx { 
	extract(sxhDzR );
	return ingress;
}

parser ZaLpPF { 
	extract(yovXod );
	return select( yovXod.KRvnNj ) {
		0x0800 : eKvOhx;
		0x86dd : pRDQQI;
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

@pragma pa_solitary ingress mkMLHZ.TpUrJg
@pragma pa_solitary ingress mkMLHZ.bcqHSY
@pragma pa_solitary ingress mkMLHZ.pQXqBl
@pragma pa_solitary ig_intr_md_for_tm.ucast_egress_port

field_list RgamWT { 
	ozKgHM.zVITkG;
	mkMLHZ.qiziyI;
	mkMLHZ.iXArIT;
	mkMLHZ.TpUrJg;
	mkMLHZ.bcqHSY;
}

field_list jeqIuB { 
	ozKgHM.zVITkG;
	mkMLHZ.TpUrJg;
	yovXod.mLIwDF;
	yovXod.meZADn;
	gOeqxi.FNBJdE;
}

action XVktOe(rJWdDI) { 
	modify_field(MeZwMk.qXPfMg, rJWdDI );
}

action sgfrDS() { 
	no_op( );
}

action YpQxby() { 
	modify_field(mkMLHZ.JFtqsz, 0x1 );
	modify_field(mkMLHZ.OjymPH, 0x1 );
}

action yTtrnk(JuQPYe) { 
#ifdef BMV2
	register_write(XpsIvD, JuQPYe, 0x1 );
#endif
}

action uZpeEH() { 
	modify_field(ScmCsW.DxjBnx, 0x1 );
	modify_field(ScmCsW.xALOuI, 0x1 );
	add(ScmCsW.VqbwXd, ScmCsW.OOQMnL, 0x1000 );
}

action sRuUvS(ZPSBzg,NldXIO,zbyrRT,iCFOSL,gJQdqX,EsFJTP) { 
	modify_field(mkMLHZ.pQXqBl, ZPSBzg );
	modify_field(mkMLHZ.mUhTtj, 0x1 );
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
	modify_field(mkMLHZ.TpUrJg, ObALmB );
	modify_field(mkMLHZ.mUhTtj, LqZpLg );
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
	modify_field(McGCgL.KRvnNj, OpBnZq.VRmbYA );
	modify_field(mkMLHZ.EzGKVg, OpBnZq.FRllQZ );
	remove_header(OpBnZq );
}

action tsXBkz(hkkrmJ) { 
	modify_field(ScmCsW.DxjBnx, 0x1 );
	modify_field(ScmCsW.VqbwXd, hkkrmJ );
}

action GXegax(NldXIO,zbyrRT,iCFOSL,gJQdqX,EsFJTP) { 
	modify_field(mkMLHZ.pQXqBl, sTsPkb.nsEAdO );
	modify_field(mkMLHZ.mUhTtj, 0x1 );
	modify_field(PdKkSx.VLGXXG, NldXIO );
	modify_field(PdKkSx.OTmmdU, zbyrRT );
	modify_field(PdKkSx.lhgqZR, iCFOSL );
	modify_field(PdKkSx.vxRZLD, gJQdqX );
	modify_field(PdKkSx.PqcjFS, EsFJTP );
}

action ukhAli() { 
	modify_field(ScmCsW.vRiVoY, 0x1 );
	modify_field(ScmCsW.VqbwXd, ScmCsW.OOQMnL );
}

action jYRXTf() { 
	modify_field(mkMLHZ.TpUrJg, OpBnZq.OGqRQd );
}

action JnIDid() { 
	modify_field(ScmCsW.GbMjEH, 0x1 );
	modify_field(ScmCsW.MXEAcT, 0x1 );
	modify_field(ScmCsW.VqbwXd, ScmCsW.OOQMnL );
}

action JZMMTw() { 
	modify_field(PdKkSx.TNJQUK, 0x1 );
}

action KQcrRq() { 
	modify_field(mkMLHZ.FZIXaP, 0x1 );
	modify_field(ozKgHM.zVITkG, 0x1 );
}

action xsDQie(yppSOY) { 
	modify_field(ScmCsW.fqhobT, 0x1 );
	modify_field(ScmCsW.YztRYj, yppSOY );
	modify_field(ig_intr_md_for_tm.ucast_egress_port, yppSOY );
	modify_field(ScmCsW.Zyqigm, yppSOY );
}

action uYBjrZ() { 
}

action GrmhMU() { 
	modify_field(mkMLHZ.dhmjSj, 0x1 );
}

action uNBXVV() { 
	modify_field(MeZwMk.zaLsws, sxhDzR.FNBJdE );
	modify_field(MeZwMk.SWwbkW, sxhDzR.LdVtae );
	modify_field(TmTnvj.oVVbhH, jdMBYC.fYguoo );
	modify_field(TmTnvj.lmbRaR, jdMBYC.RBgDwk );
	modify_field(mkMLHZ.jlUFzz, yovXod.CEkqjr );
	modify_field(mkMLHZ.WTfhFM, yovXod.KdEucT );
	modify_field(mkMLHZ.qiziyI, yovXod.mLIwDF );
	modify_field(mkMLHZ.iXArIT, yovXod.meZADn );
}

action xfABlB() { 
	modify_field(mkMLHZ.AlAsan, 0x1 );
	modify_field(ozKgHM.zVITkG, 0x0 );
}

action jwLDdv() { 
	modify_field(mkMLHZ.TpUrJg, sTsPkb.nsEAdO );
}

action MbuqfL() { 
	modify_field(ScmCsW.WzPLog, mkMLHZ.jlUFzz );
	modify_field(ScmCsW.RSWubU, mkMLHZ.WTfhFM );
	modify_field(ScmCsW.UuTZpv, mkMLHZ.qiziyI );
	modify_field(ScmCsW.CHfqJg, mkMLHZ.iXArIT );
	modify_field(ScmCsW.OOQMnL, mkMLHZ.TpUrJg );
}

action ucNGOW() { 
	add_header(OpBnZq );
	modify_field(OpBnZq.OGqRQd, ScmCsW.VMHYPO );
	modify_field(OpBnZq.FRllQZ, mkMLHZ.EzGKVg );
	modify_field(OpBnZq.VRmbYA, McGCgL.KRvnNj );
	modify_field(McGCgL.KRvnNj, 0x8100 );
}

action GtfyxI(ObALmB) { 
	modify_field(ScmCsW.VMHYPO, ObALmB );
	remove_header(OpBnZq );
}

action ruSbdS() { 
}

action QXYBjG() { 
	generate_digest(0x0, jeqIuB );
}

action SBqFEe(UWsnEK) { 
	modify_field(mkMLHZ.bcqHSY, UWsnEK );
}

action zEaBcj() { 
	modify_field(mkMLHZ.eDTSaM, 0x0 );
	modify_field(mkMLHZ.bcqHSY, sTsPkb.ouVJSA );
	modify_field(MeZwMk.zaLsws, gOeqxi.FNBJdE );
	modify_field(MeZwMk.SWwbkW, gOeqxi.LdVtae );
	modify_field(TmTnvj.oVVbhH, flxIhi.fYguoo );
	modify_field(TmTnvj.lmbRaR, flxIhi.RBgDwk );
	modify_field(mkMLHZ.jlUFzz, McGCgL.CEkqjr );
	modify_field(mkMLHZ.WTfhFM, McGCgL.KdEucT );
	modify_field(mkMLHZ.qiziyI, McGCgL.mLIwDF );
	modify_field(mkMLHZ.iXArIT, McGCgL.meZADn );
}

action wpFyFj(NldXIO,zbyrRT,iCFOSL,gJQdqX,EsFJTP) { 
	modify_field(mkMLHZ.pQXqBl, OpBnZq.OGqRQd );
	modify_field(mkMLHZ.mUhTtj, 0x1 );
	modify_field(PdKkSx.VLGXXG, NldXIO );
	modify_field(PdKkSx.OTmmdU, zbyrRT );
	modify_field(PdKkSx.lhgqZR, iCFOSL );
	modify_field(PdKkSx.vxRZLD, gJQdqX );
	modify_field(PdKkSx.PqcjFS, EsFJTP );
}

action Ayapvg(ZPSBzg) { 
	modify_field(mkMLHZ.TpUrJg, ZPSBzg );
}

action nsoTFn() { 
	no_op( );
}

action sSlAOq(DSyDIW,wPlBaD,jsYLqr,tTfUVS) { 
	modify_field(sTsPkb.ouVJSA, DSyDIW );
	modify_field(sTsPkb.cCOHKE, wPlBaD );
	modify_field(sTsPkb.nsEAdO, jsYLqr );
	modify_field(sTsPkb.huEsCO, tTfUVS );
}

table XzThII {
	reads{
		ig_intr_md.ingress_port : exact;
	}
	actions{ 
		sSlAOq;
	}
	size : 288;
}

table yYaWKh {
	reads{
		McGCgL.CEkqjr : exact;
		McGCgL.KdEucT : exact;
	}
	actions{ 
		GrmhMU;
	}
	size : 64;
}

table ceGwFc {
	reads{
		McGCgL.CEkqjr : exact;
		McGCgL.KdEucT : exact;
		gOeqxi.LdVtae : exact;
		mkMLHZ.eDTSaM : exact;
	}
	actions{ 
		uNBXVV;
		zEaBcj;
	}
	size : 1024;
}

table GiINoN {
	reads{
		sTsPkb.ouVJSA : ternary;
		OpBnZq : valid;
		OpBnZq.OGqRQd : ternary;
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
		gOeqxi.FNBJdE : exact;
	}
	actions{ 
		SBqFEe;
		KQcrRq;
	}
	size : 4096;
}

table KPlvUi {
	reads{
		TPRTmY.MmjnLs : exact;
	}
	actions{ 
		QYBPRQ;
		YpQxby;
	}
	size : 4096;
}

table jubrcZ {
	reads{
		sTsPkb.nsEAdO : exact;
	}
	actions{ 
		GXegax;
	}
	size : 4096;
}

table RmXtve {
	reads{
		sTsPkb.ouVJSA : exact;
		OpBnZq.OGqRQd : exact;
	}
	actions{ 
		sRuUvS;
		sgfrDS;
	}
	size : 1024;
}

table FyMYiX {
	reads{
		OpBnZq.OGqRQd : exact;
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
		mkMLHZ.pQXqBl : ternary;
		mkMLHZ.jlUFzz : exact;
		mkMLHZ.WTfhFM : exact;
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
		mkMLHZ.qiziyI : exact;
		mkMLHZ.iXArIT : exact;
		mkMLHZ.TpUrJg : exact;
		mkMLHZ.bcqHSY : exact;
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
		MeZwMk.SWwbkW : lpm;
	}
	actions{ 
		XVktOe;
	}
	size : 16384;
}

@pragma atcam_partition_index MeZwMk.qXPfMg
@pragma atcam_number_partitions 16384
table XWEKAE {
	reads{
		MeZwMk.qXPfMg : exact;
		MeZwMk.SWwbkW : lpm;
	}
	actions{ 
		TwIQHU;
	}
	size : 147456;
}

table fDUvPP {
	reads{
		PdKkSx.VLGXXG : exact;
		MeZwMk.SWwbkW : exact;
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
		ScmCsW.WzPLog : exact;
		ScmCsW.RSWubU : exact;
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
		ScmCsW.WzPLog : exact;
		ScmCsW.RSWubU : exact;
		ScmCsW.OOQMnL : exact;
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
		apply( XzThII );

	}

	apply( yYaWKh );

	apply( ceGwFc ) {
		zEaBcj {
			if (sTsPkb.huEsCO == 0x1) { 
				apply( GiINoN );

			}

			if ( valid( OpBnZq ) ) { 
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
	if ((sTsPkb.cCOHKE == 0x0) and (mkMLHZ.FZIXaP == 0x0)) { 
		apply( OsNzCx );

	}

	if ((mkMLHZ.JFtqsz == 0x0) and (mkMLHZ.OjymPH == 0x0)) { 
		apply( KhzFiy );

	}

	if (mkMLHZ.TpUrJg != 0x0) { 
		apply( sFQXXt );

	}

	if ((((YKjpKX.ZtjVUq == 0x0) and (YKjpKX.tgfjtx == 0x0)) and (mkMLHZ.JFtqsz == 0x0)) and (PdKkSx.TNJQUK == 0x1)) { 
		if ((PdKkSx.OTmmdU == 0x1) and (((mkMLHZ.eDTSaM == 0x0) and ( valid( gOeqxi ) )) or ((mkMLHZ.eDTSaM != 0x0) and ( valid( sxhDzR ) )))) { 
			apply( fDUvPP ) {
				sgfrDS {
					apply( FsxDka );

					if (MeZwMk.qXPfMg != 0x0) { 
						apply( XWEKAE );

					}

				}
			}
		}

	}

	if (mkMLHZ.JFtqsz == 0x0) { 
		apply( PHSvkl ) {
			ruSbdS {
				apply( OgtsFH ) {
					uYBjrZ {
						if ((ScmCsW.WzPLog & 0x10000) == 0x10000) { 
							apply( AosIFt );

						}

						apply( UHdtQj );

					}
				}
			}
		}
	}

	if (mkMLHZ.FZIXaP == 0x1) { 
		apply( FObudl );

	}

	if (mkMLHZ.AlAsan == 0x1) { 
		apply( GKgaxO );

	}

	if ( valid( OpBnZq ) ) { 
		apply( LbcSdm );

	}

}

table cNhnko {
	reads{
		ScmCsW.OOQMnL : exact;
	}
	actions{ 
		GtfyxI;
	}
	size : 4096;
}

table kFUytS {
	reads{
		ScmCsW.VMHYPO : exact;
		ScmCsW.Zyqigm : exact;
	}
	actions{ 
		nsoTFn;
		ucNGOW;
	}
	size : 64;
}

control egress { 
	apply( cNhnko );

	apply( kFUytS );

}
