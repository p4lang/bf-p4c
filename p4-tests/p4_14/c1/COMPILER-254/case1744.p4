// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.

#ifndef HEADERS_H4
#define HEADERS_H4

header_type KXuvHH {
	fields { 
	fBlaNb : 24;
	iyhgyP : 24;
	PypKpF : 24;
	gRXamj : 24;
	CykjqF : 16;
	OzuGhp : 16;
	SByXeq : 16;
	EuDCFO : 12;
	Bogpst : 2;
	NyGkwv : 1;
	jXJoRq : 1;
	JnHKZN : 1;
	wLrIOy : 1;
	UFvKqQ : 1;
	fDITtJ : 1;
	}
}

header_type CIhINR {
	fields { 
	aReYBT : 24;
	kecNpA : 24;
	KkIdVY : 24;
	sWyyKF : 24;
	jRFjiT : 16;
	pCutty : 16;
	CFRaCW : 16;
	BhWQLG : 1;
	wHDtwz : 1;
	wmXYph : 1;
	zfXxVt : 1;
	khqPrw : 1;
	yXOTMa : 1;
	}
}

header_type IyKHZu {
	fields { 
	pdXGWn : 8;
	fGWrQt : 1;
	wXKPit : 1;
	xwFrxz : 1;
	VcngCe : 1;
	bgBnjZ : 1;
	}
}

header_type OPoGXQ {
	fields { 
	NfikzO : 32;
	AzzIVF : 32;
	KDRpzh : 16;
	}
}

header_type uAYuFB {
	fields { 
	AChZdR : 128;
	RzMwNx : 128;
	}
}

header_type egrogU {
	fields { 
	IZubMG : 14;
	fFjotw : 1;
	FBhmHJ : 1;
	bwlvkO : 12;
	OGejxu : 1;
	ZmhYkw : 6;
	}
}

header_type OpLBCa {
	fields { 
	kbVmag : 1;
	fLJxJk : 1;
	}
}

header_type ywCrrX {
	fields { 
	sHAGWj : 8;
	}
}

header_type GTSivn {
	fields { 
	JAeDzl : 16;
	}
}

header_type JpTLup {
	fields { 
	kqQake : 24;
	lafbST : 24;
	AWHPGV : 24;
	ipIrwD : 24;
	JmpjRu : 16;
	}
}

header_type pOcNIq {
	fields { 
	UlDfQT : 3;
	yOWkqc : 1;
	Xotmsw : 12;
	AdJIYm : 16;
	}
}

header_type vtcowb {
	fields { 
	LymMid : 4;
	CPMXCY : 4;
	usYliZ : 8;
	pZGPrL : 16;
	ABVYMR : 16;
	SZPDUJ : 3;
	Jgkzvd : 13;
	UimjPs : 8;
	jJFqpU : 8;
	nLkEdj : 16;
	gnQHPE : 32;
	qsmkxH : 32;
	}
}

header_type LSlzvW {
	fields { 
	QMvvpm : 4;
	eYGLeU : 8;
	JHvSjT : 20;
	kGlFPK : 16;
	Dbhngt : 8;
	EUFMCh : 8;
	WxNhSr : 128;
	abvaQa : 128;
	}
}

header_type LVrPBB {
	fields { 
	RoeeuW : 16;
	vieaxm : 16;
	LbOgOC : 16;
	GUmUPV : 16;
	}
}

header_type PuEPIj {
	fields { 
	tjrrBj : 16;
	spDzFh : 16;
	YsftgQ : 8;
	InmGAo : 8;
	UfSduu : 16;
	}
}

header_type KkVXBX {
	fields { 
	KbtrZj : 8;
	NdDsXw : 24;
	GpgeBz : 24;
	bvdloQ : 8;
	}
}

#endif // HEADERS_H4

#ifndef PARSER_H4
#define PARSER_H4

header JpTLup BKUgda;
header JpTLup uzTPDs;
header pOcNIq wTmLsD;
header pOcNIq NdxScV;
header vtcowb YsFfOi;
header vtcowb vJDCOF;
header LSlzvW Aeyzyj;
header LSlzvW GcwzJG;
header LVrPBB wWygMU;
header KkVXBX YmdqVQ;
header PuEPIj jEKMBL;
metadata KXuvHH ISBegy;
metadata CIhINR UEnfPN;
metadata egrogU jwCLby;
metadata OPoGXQ rPaenA;
metadata uAYuFB BmGNnj;
metadata OpLBCa aiEvpD;
metadata IyKHZu DiLHQO;
metadata ywCrrX svgufS;
metadata GTSivn WEiEAO;

parser taaQDL { 
	extract(YmdqVQ );
	set_metadata(ISBegy.Bogpst, 0x1 );
	return select( YmdqVQ.GpgeBz ) {
		default : OOpawk;
	}
}

parser KRgOmK { 
	extract(jEKMBL );
	return ingress;
}

parser xOQXHs { 
	extract(BKUgda );
	set_metadata(ISBegy.fBlaNb, BKUgda.kqQake );
	set_metadata(ISBegy.iyhgyP, BKUgda.lafbST );
	set_metadata(ISBegy.PypKpF, BKUgda.AWHPGV );
	set_metadata(ISBegy.gRXamj, BKUgda.ipIrwD );
	return select( BKUgda.JmpjRu ) {
		0x8100 : FzGFNV;
		0x0800 : CURkOl;
		0x86dd : tBQDQi;
		0x0806 : KRgOmK;
		default : ingress;
	}
}

parser tBQDQi { 
	extract(GcwzJG );
	return ingress;
}

parser CURkOl { 
	extract(YsFfOi );
	return select( YsFfOi.Jgkzvd, YsFfOi.CPMXCY, YsFfOi.jJFqpU ) {
		0x00000511 : wRzqoK;
		default : ingress;
	}
}

parser start { 
	return xOQXHs;
}

parser OOpawk { 
	extract(uzTPDs );
	return ingress;
}

parser wRzqoK { 
	extract(wWygMU );
	return select( wWygMU.vieaxm ) {
		0x12b5 : taaQDL;
		default : ingress;
	}
}

parser FzGFNV { 
	extract(wTmLsD );
	return select( wTmLsD.AdJIYm ) {
		0x0800 : CURkOl;
		0x86dd : tBQDQi;
		0x0806 : KRgOmK;
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

field_list HOpYxr { 
	svgufS.sHAGWj;
	ISBegy.CykjqF;
	uzTPDs.AWHPGV;
	uzTPDs.ipIrwD;
	YsFfOi.gnQHPE;
}

field_list zMykuY { 
	svgufS.sHAGWj;
	ISBegy.PypKpF;
	ISBegy.gRXamj;
	ISBegy.CykjqF;
	ISBegy.OzuGhp;
}

action xGsHXD() { 
	modify_field(ISBegy.CykjqF, wTmLsD.Xotmsw );
}

blackbox stateful_alu abcAlu1{
    reg: uVMcgg;
    update_lo_1_value: set_bit;
}

action wgUyys(pIFssJ) { 
    abcAlu1.execute_stateful_alu();
}

action WtUopq() { 
	no_op( );
}

action rGpmFL() { 
}

action OBWlGA() { 
	modify_field(UEnfPN.wHDtwz, 0x1 );
	modify_field(UEnfPN.BhWQLG, 0x1 );
	modify_field(UEnfPN.CFRaCW, UEnfPN.jRFjiT );
}

action xyNqmz() { 
	modify_field(rPaenA.NfikzO, vJDCOF.gnQHPE );
	modify_field(rPaenA.AzzIVF, vJDCOF.qsmkxH );
	modify_field(BmGNnj.AChZdR, Aeyzyj.WxNhSr );
	modify_field(BmGNnj.RzMwNx, Aeyzyj.abvaQa );
	modify_field(ISBegy.fBlaNb, uzTPDs.kqQake );
	modify_field(ISBegy.iyhgyP, uzTPDs.lafbST );
	modify_field(ISBegy.PypKpF, uzTPDs.AWHPGV );
	modify_field(ISBegy.gRXamj, uzTPDs.ipIrwD );
}

action ZREoXK() { 
	modify_field(UEnfPN.wmXYph, 0x1 );
	modify_field(UEnfPN.yXOTMa, 0x1 );
	add(UEnfPN.CFRaCW, UEnfPN.jRFjiT, 0x1000 );
}

action BYjThP() { 
	modify_field(ISBegy.NyGkwv, 0x1 );
}

action oLXWui() { 
	modify_field(ISBegy.jXJoRq, 0x1 );
	modify_field(svgufS.sHAGWj, 0x0 );
}

action hrWpRz(nXwNyt) { 
	modify_field(rPaenA.KDRpzh, nXwNyt );
}

action EcBKoV() { 
	modify_field(ISBegy.JnHKZN, 0x1 );
	modify_field(svgufS.sHAGWj, 0x1 );
}

action egDUAa() { 
	modify_field(UEnfPN.aReYBT, ISBegy.fBlaNb );
	modify_field(UEnfPN.kecNpA, ISBegy.iyhgyP );
	modify_field(UEnfPN.KkIdVY, ISBegy.PypKpF );
	modify_field(UEnfPN.sWyyKF, ISBegy.gRXamj );
	modify_field(UEnfPN.jRFjiT, ISBegy.CykjqF );
}

action mKDDtK() { 
	generate_digest(0x0, HOpYxr );
}

action zDZfBi() { 
	modify_field(ISBegy.Bogpst, 0x0 );
	modify_field(ISBegy.OzuGhp, jwCLby.IZubMG );
	modify_field(rPaenA.NfikzO, YsFfOi.gnQHPE );
	modify_field(rPaenA.AzzIVF, YsFfOi.qsmkxH );
	modify_field(BmGNnj.AChZdR, GcwzJG.WxNhSr );
	modify_field(BmGNnj.RzMwNx, GcwzJG.abvaQa );
	modify_field(ISBegy.fBlaNb, BKUgda.kqQake );
	modify_field(ISBegy.iyhgyP, BKUgda.lafbST );
	modify_field(ISBegy.PypKpF, BKUgda.AWHPGV );
	modify_field(ISBegy.gRXamj, BKUgda.ipIrwD );
}

action MRkSDK() { 
	modify_field(UEnfPN.khqPrw, 0x1 );
	modify_field(UEnfPN.CFRaCW, UEnfPN.jRFjiT );
}

action POLxik(TyKlAR) { 
	modify_field(ISBegy.OzuGhp, TyKlAR );
}

action wLhHGY(uZyYUb,CCsqtn,ipdpzE,ulWRNk,cRUESd,bBAmRj) { 
	modify_field(ISBegy.SByXeq, uZyYUb );
	modify_field(ISBegy.fDITtJ, 0x1 );
	modify_field(DiLHQO.pdXGWn, CCsqtn );
	modify_field(DiLHQO.fGWrQt, ipdpzE );
	modify_field(DiLHQO.xwFrxz, ulWRNk );
	modify_field(DiLHQO.wXKPit, cRUESd );
	modify_field(DiLHQO.VcngCe, bBAmRj );
}

action afVWBb(uZyYUb) { 
	modify_field(ISBegy.CykjqF, uZyYUb );
}

action PkiRck() { 
	generate_digest(0x0, zMykuY );
}

action HPPlzH(AVUtBp,CCsqtn,ipdpzE,ulWRNk,cRUESd,bBAmRj,baMPXN) { 
	modify_field(ISBegy.CykjqF, AVUtBp );
	modify_field(ISBegy.fDITtJ, baMPXN );
	modify_field(DiLHQO.pdXGWn, CCsqtn );
	modify_field(DiLHQO.fGWrQt, ipdpzE );
	modify_field(DiLHQO.xwFrxz, ulWRNk );
	modify_field(DiLHQO.wXKPit, cRUESd );
	modify_field(DiLHQO.VcngCe, bBAmRj );
}

action ZMxEHs() { 
	modify_field(DiLHQO.bgBnjZ, 0x1 );
}

action sNrOwP(MELMPx) { 
	modify_field(aiEvpD.fLJxJk, MELMPx );
}

action ZlMvHS() { 
	modify_field(ISBegy.wLrIOy, 0x1 );
	modify_field(ISBegy.UFvKqQ, 0x1 );
}

action GUkRTK(FWDfFV) { 
	modify_field(UEnfPN.zfXxVt, 0x1 );
	modify_field(UEnfPN.pCutty, FWDfFV );
}

action jmisxL() { 
	modify_field(ISBegy.EuDCFO, wTmLsD.Xotmsw );
}

action mzdRSP() { 
	modify_field(ISBegy.CykjqF, jwCLby.bwlvkO );
}

action OaIjAZ(BhMLPj) { 
	modify_field(UEnfPN.wmXYph, 0x1 );
	modify_field(UEnfPN.CFRaCW, BhMLPj );
}

action qWIgTk(CCsqtn,ipdpzE,ulWRNk,cRUESd,bBAmRj) { 
	modify_field(ISBegy.SByXeq, wTmLsD.Xotmsw );
	modify_field(ISBegy.fDITtJ, 0x1 );
	modify_field(DiLHQO.pdXGWn, CCsqtn );
	modify_field(DiLHQO.fGWrQt, ipdpzE );
	modify_field(DiLHQO.xwFrxz, ulWRNk );
	modify_field(DiLHQO.wXKPit, cRUESd );
	modify_field(DiLHQO.VcngCe, bBAmRj );
}

action IMZBXB() { 
	modify_field(ISBegy.EuDCFO, jwCLby.bwlvkO );
}

action WWGOmk(Cjazmt,LOAkxi,bVJRUp,AHZlEh,CrfYwa,eJKMoA) { 
	modify_field(jwCLby.IZubMG, Cjazmt );
	modify_field(jwCLby.fFjotw, LOAkxi );
	modify_field(jwCLby.bwlvkO, bVJRUp );
	modify_field(jwCLby.FBhmHJ, AHZlEh );
	modify_field(jwCLby.OGejxu, CrfYwa );
	modify_field(jwCLby.ZmhYkw, eJKMoA );
}

action xekLAZ(bUNITB) { 
	modify_field(WEiEAO.JAeDzl, bUNITB );
}

action QySKDb() { 
}

action HIrDUm(CCsqtn,ipdpzE,ulWRNk,cRUESd,bBAmRj) { 
	modify_field(ISBegy.SByXeq, jwCLby.bwlvkO );
	modify_field(ISBegy.fDITtJ, 0x1 );
	modify_field(DiLHQO.pdXGWn, CCsqtn );
	modify_field(DiLHQO.fGWrQt, ipdpzE );
	modify_field(DiLHQO.xwFrxz, ulWRNk );
	modify_field(DiLHQO.wXKPit, cRUESd );
	modify_field(DiLHQO.VcngCe, bBAmRj );
}

table pSklAb {
	reads{
		ig_intr_md.ingress_port : exact;
	}
	actions{ 
		WWGOmk;
	}
	size : 288;
}

table UvqxDx {
	reads{
		BKUgda.kqQake : exact;
		BKUgda.lafbST : exact;
	}
	actions{ 
		BYjThP;
	}
	size : 64;
}

table PYggeW {
	reads{
		BKUgda.kqQake : exact;
		BKUgda.lafbST : exact;
		YsFfOi.qsmkxH : exact;
		ISBegy.Bogpst : exact;
	}
	actions{ 
		xyNqmz;
		zDZfBi;
	}
	size : 1024;
}

table wvUKrF {
	reads{
		jwCLby.IZubMG : ternary;
		wTmLsD : valid;
		wTmLsD.Xotmsw : ternary;
	}
	actions{ 
		mzdRSP;
		afVWBb;
		xGsHXD;
	}
	size : 4096;
}

table tVqytV {
	reads{
		YsFfOi.gnQHPE : exact;
	}
	actions{ 
		POLxik;
		EcBKoV;
	}
	size : 4096;
}

table iBkgYU {
	reads{
		YmdqVQ.GpgeBz : exact;
	}
	actions{ 
		HPPlzH;
		ZlMvHS;
	}
	size : 4096;
}

table OOisIO {
	reads{
		jwCLby.bwlvkO : exact;
	}
	actions{ 
		HIrDUm;
	}
	size : 4096;
}

table watTno {
	reads{
		jwCLby.IZubMG : exact;
		wTmLsD.Xotmsw : exact;
	}
	actions{ 
		wLhHGY;
		WtUopq;
	}
	size : 1024;
}

table JDNOvi {
	reads{
		wTmLsD.Xotmsw : exact;
	}
	actions{ 
		qWIgTk;
	}
	size : 4096;
}

table VajgBr {
	
	actions{ 
		mKDDtK;
	}
	size : 1;
}

table gjmQaN {
	reads{
		jwCLby.ZmhYkw : exact;
	}
	actions{ 
		sNrOwP;
	}
	size : 512;
}

table YaVNlk {
	
	actions{ 
		IMZBXB;
	}
	size : 1;
}

table fQyPjm {
	
	actions{ 
		jmisxL;
	}
	size : 1;
}

table EnUeBj {
	reads{
		ISBegy.SByXeq : ternary;
		ISBegy.fBlaNb : exact;
		ISBegy.iyhgyP : exact;
	}
	actions{ 
		ZMxEHs;
	}
	size : 512;
}

register uVMcgg {
	width : 1;
	static : iAUfJw;
	instance_count: 65536;
}

table iAUfJw {
	reads{
		ISBegy.PypKpF : exact;
		ISBegy.gRXamj : exact;
		ISBegy.CykjqF : exact;
		ISBegy.OzuGhp : exact;
	}
	actions{ 
		wgUyys;
		oLXWui;
	}
	size : 65536;
}

table PlDVOx {
	
	actions{ 
		PkiRck;
	}
	size : 1;
}

table kiVysN {
	reads{
		DiLHQO.pdXGWn : exact;
		rPaenA.AzzIVF : lpm;
	}
	actions{ 
		hrWpRz;
	}
	size : 16384;
}

@pragma atcam_partition_index rPaenA.KDRpzh
@pragma atcam_number_partitions 16384
table wjWaOf {
	reads{
		rPaenA.KDRpzh : exact;
		rPaenA.AzzIVF : lpm;
	}
	actions{ 
		xekLAZ;
	}
	size : 147456;
}

table DLWTDd {
	reads{
		DiLHQO.pdXGWn : exact;
		rPaenA.AzzIVF : exact;
	}
	actions{ 
		xekLAZ;
		WtUopq;
	}
	size : 65536;
}

table csvDSE {
	reads{
		DiLHQO.pdXGWn : exact;
		BmGNnj.RzMwNx : exact;
	}
	actions{ 
		xekLAZ;
		WtUopq;
	}
	size : 65536;
}

table VJibYJ {
	
	actions{ 
		egDUAa;
	}
	size : 1;
}

table isqhxf {
	reads{
		UEnfPN.aReYBT : exact;
		UEnfPN.kecNpA : exact;
	}
	actions{ 
		OBWlGA;
		rGpmFL;
	}
	size : 1;
}

table kjsVFs {
	
	actions{ 
		ZREoXK;
	}
	size : 1;
}

table ZWumNk {
	
	actions{ 
		MRkSDK;
	}
	size : 1;
}

table FrriYI {
	reads{
		UEnfPN.aReYBT : exact;
		UEnfPN.kecNpA : exact;
		UEnfPN.jRFjiT : exact;
	}
	actions{ 
		GUkRTK;
		OaIjAZ;
		QySKDb;
	}
	size : 65536;
}

control ingress { 
	if (ig_intr_md.resubmit_flag == 0x0) { 
		apply( pSklAb );

	}

	apply( UvqxDx );

	apply( PYggeW ) {
		zDZfBi {
			if (jwCLby.FBhmHJ == 0x1) { 
				apply( wvUKrF );

			}

			if ( valid( wTmLsD ) ) { 
				apply( watTno ) {
					WtUopq {
						apply( JDNOvi ); 
					}
				}
			} else {
                            apply( OOisIO );
                        }
		}
		xyNqmz {
			apply( tVqytV );

			apply( iBkgYU );

		}
	}
	if ( valid( wTmLsD ) ) { 
		apply( fQyPjm );

	} else { 
                apply( YaVNlk );
                if (jwCLby.OGejxu == 0x1) { 
                  apply( gjmQaN ); 
                }
        }

	if ((jwCLby.fFjotw == 0x0) and (ISBegy.JnHKZN == 0x0)) { 
		apply( iAUfJw );

	}

	if ((ISBegy.wLrIOy == 0x0) and (ISBegy.UFvKqQ == 0x0)) { 
		apply( EnUeBj );

	}

	if (ISBegy.CykjqF != 0x0) { 
		apply( VJibYJ );

	}

	if ((((aiEvpD.kbVmag == 0x0) and (aiEvpD.fLJxJk == 0x0)) and (ISBegy.wLrIOy == 0x0)) and (DiLHQO.bgBnjZ == 0x1)) { 
		if ((DiLHQO.fGWrQt == 0x1) and (((ISBegy.Bogpst == 0x0) and ( valid( YsFfOi ) )) or ((ISBegy.Bogpst != 0x0) and ( valid( vJDCOF ) )))) { 
			apply( DLWTDd ) {
				WtUopq {
					apply( kiVysN );

					if (rPaenA.KDRpzh != 0x0) { 
						apply( wjWaOf );

					}

				}
			}
		}

		if (((DiLHQO.xwFrxz == 0x1) and ((ISBegy.Bogpst == 0x0) and ( valid( GcwzJG ) ))) or ((ISBegy.Bogpst != 0x0) and ( valid( Aeyzyj ) ))) { 
			apply( csvDSE );

		}

	}

	if (ISBegy.wLrIOy == 0x0) { 
		apply( FrriYI ) {
			QySKDb {
				apply( isqhxf ) {
					rGpmFL {
						if ((UEnfPN.aReYBT & 0x10000) == 0x10000) { 
							apply( kjsVFs );

						}

						apply( ZWumNk );

					}
				}
			}
		}
	}

	if (ISBegy.JnHKZN == 0x1) { 
		apply( VajgBr );

	}

	if (ISBegy.jXJoRq == 0x1) { 
		apply( PlDVOx );

	}

}

control egress { 
}
