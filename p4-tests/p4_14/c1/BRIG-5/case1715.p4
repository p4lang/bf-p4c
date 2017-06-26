// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.

#ifndef HEADERS_H4
#define HEADERS_H4

header_type lNrnEC {
	fields { 
	eguEQM : 24;
	YWkHqd : 24;
	kLfTIU : 24;
	FpUAZo : 24;
	eHdmgU : 16;
	vAMWZi : 16;
	ncVGWm : 16;
	rsAwNd : 12;
	nZmyfl : 2;
	TZUCwE : 1;
	zfeFym : 1;
	GiugcX : 1;
	EdbVwo : 1;
	LvzHhI : 1;
	}
}

header_type oRmbAJ {
	fields { 
	eOdtuN : 24;
	QeEJZF : 24;
	NONZPg : 24;
	pkJpeD : 24;
	jvCpRl : 16;
	iTtIao : 16;
	LAIizK : 16;
	LKfNSO : 1;
	FbyyQT : 1;
	niJaGq : 1;
	vEUGte : 1;
	iopEOe : 1;
	zpCVKR : 1;
	}
}

header_type UunjwF {
	fields { 
	WwpGkv : 8;
	YRMmxz : 1;
	yURZDh : 1;
	IMDzBn : 1;
	ZJQrpS : 1;
	}
}

header_type lbbyik {
	fields { 
	ioCVkH : 32;
	gVnEFV : 32;
	ZEWlin : 16;
	}
}

header_type WbHLUe {
	fields { 
	YsfBYV : 128;
	diDTUB : 128;
	}
}

header_type rAIBHU {
	fields { 
	XzqkeH : 14;
	HtUdGu : 1;
	NWqDYn : 1;
	VtlLDM : 13;
	}
}

header_type dBpgcI {
	fields { 
	pkkAoe : 1;
	awtutZ : 1;
	}
}

header_type YGmcXY {
	fields { 
	JiMzUK : 8;
	}
}

header_type dJliiz {
	fields { 
	OyFTpX : 1;
	}
}

header_type rNyXwr {
	fields { 
	Ljzbvt : 16;
	}
}

header_type jUZkFZ {
	fields { 
	AFUSNM : 1;
	nsfmlu : 1;
	RzhGTS : 1;
	auEkUR : 1;
	qtdxGX : 1;
	YIiTfP : 1;
	bTrFlU : 1;
	OcSaOv : 1;
	QkhLpx : 1;
	tHBgcK : 1;
	jFPmWq : 1;
	lLtRPa : 1;
	TXrHyi : 1;
	}
}

header_type BhHmvR {
	fields { 
	GpVggy : 24;
	qTArPp : 24;
	KaAvFG : 24;
	wNAybQ : 24;
	tzjKlx : 16;
	}
}

header_type nqamCy {
	fields { 
	nHsXlw : 3;
	CZBDgZ : 1;
	BaAnQa : 12;
	TQKpGO : 16;
	}
}

header_type PuCRqv {
	fields { 
	WPBaOp : 4;
	fwqSQU : 4;
	PqLkfo : 8;
	izNfcF : 16;
	IVfMXU : 16;
	pTvAaY : 3;
	GsFpGp : 13;
	jEHXNv : 8;
	TyQxJQ : 8;
	nVwTzS : 16;
	tqMJMA : 32;
	zMkMTl : 32;
	}
}

header_type nouhBO {
	fields { 
	RYRhDA : 4;
	KFRtQk : 8;
	CmygDF : 20;
	zCcdlY : 16;
	njZUCh : 8;
	tEVXcA : 8;
	jEpyFj : 128;
	XpaWNM : 128;
	}
}

header_type oJkohu {
	fields { 
	hnzZwC : 16;
	XLXjTX : 16;
	YjMRrp : 16;
	ksMxeM : 16;
	}
}

header_type vgUOKT {
	fields { 
	ikoEDW : 16;
	siVskJ : 16;
	pXoKqR : 8;
	HvwjCk : 8;
	ZGZSLc : 16;
	}
}

header_type FxHYCO {
	fields { 
	wSHYhg : 8;
	dPoBYP : 24;
	rcAoXD : 24;
	zSiNtN : 8;
	}
}

#endif // HEADERS_H4

#ifndef PARSER_H4
#define PARSER_H4

header BhHmvR QUzEun;
header BhHmvR oPHKWO;
header nqamCy LkPrni;
header nqamCy QlKNFE;
header PuCRqv ujAsAs;
header PuCRqv lYXUin;
header nouhBO hibXlf;
header nouhBO SozCdH;
header oJkohu hSwWXC;
header FxHYCO qAVGBC;
header vgUOKT hPpXZx;
metadata lNrnEC cfDyxP;
metadata oRmbAJ YEKoZE;
metadata rAIBHU BdarYZ;
metadata lbbyik OlPBiN;
metadata WbHLUe OviEQo;
metadata dBpgcI KcFelw;
metadata UunjwF snSjFB;
metadata YGmcXY IYRPFS;
metadata dJliiz ndIRii;
metadata rNyXwr ktbBdq;
metadata jUZkFZ jtDeHH;

@pragma pa_solitary ingress cfDyxP.eHdmgU
@pragma pa_solitary ingress cfDyxP.vAMWZi

parser NMcrYB { 
	extract(qAVGBC );
	set_metadata(cfDyxP.nZmyfl, 0x1 );
	return select( qAVGBC.rcAoXD ) {
		default : lGxehP;
	}
}

parser tVedlz { 
	extract(hPpXZx );
	return ingressProcessing;
}

parser EsYZnM { 
	extract(SozCdH );
	return ingressProcessing;
}

parser kZlWYj { 
	extract(QUzEun );
	set_metadata(cfDyxP.eguEQM, QUzEun.GpVggy );
	set_metadata(cfDyxP.YWkHqd, QUzEun.qTArPp );
	set_metadata(cfDyxP.kLfTIU, QUzEun.KaAvFG );
	set_metadata(cfDyxP.FpUAZo, QUzEun.wNAybQ );
	return select( QUzEun.tzjKlx ) {
		0x8100 : SMkqkv;
		0x0800 : MeKmKm;
		0x86dd : EsYZnM;
		0x0806 : tVedlz;
		default : ingressProcessing;
	}
}

parser DdKsiI { 
	extract(hSwWXC );
	return select( hSwWXC.XLXjTX ) {
		0x12b5 : NMcrYB;
		default : ingressProcessing;
	}
}

parser start { 
	return kZlWYj;
}

parser lGxehP { 
	extract(oPHKWO );
	return ingressProcessing;
}

parser SMkqkv { 
	extract(LkPrni );
	return select( LkPrni.TQKpGO ) {
		0x0800 : MeKmKm;
		0x86dd : EsYZnM;
		0x0806 : tVedlz;
		default : ingressProcessing;
	}
}

parser MeKmKm { 
	extract(ujAsAs );
	return select( ujAsAs.GsFpGp, ujAsAs.fwqSQU, ujAsAs.TyQxJQ ) {
		0x00000511 : DdKsiI;
		default : ingressProcessing;
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

field_list HgFUwb { 
	IYRPFS.JiMzUK;
	cfDyxP.eHdmgU;
	oPHKWO.KaAvFG;
	oPHKWO.wNAybQ;
	ujAsAs.tqMJMA;
}

field_list uajPdr { 
	IYRPFS.JiMzUK;
	cfDyxP.kLfTIU;
	cfDyxP.FpUAZo;
	cfDyxP.eHdmgU;
	cfDyxP.vAMWZi;
}

action uPHxCo() { 
}

action zJjFjD(sjlUYX) { 
	modify_field(cfDyxP.eHdmgU, sjlUYX );
}

action qoKTrI() { 
	modify_field(cfDyxP.GiugcX, 0x1 );
	modify_field(IYRPFS.JiMzUK, 0x1 );
}

action MbVkKv(rwWKsJ) { 
	modify_field(cfDyxP.eHdmgU, rwWKsJ );
}

action QzlCgG(pGureS,bDQhft,rycpwZ,hnLajG) { 
	modify_field(BdarYZ.XzqkeH, pGureS );
	modify_field(BdarYZ.HtUdGu, bDQhft );
	modify_field(BdarYZ.VtlLDM, rycpwZ );
	modify_field(BdarYZ.NWqDYn, hnLajG );
}

action ICxVPq() { 
	modify_field(YEKoZE.FbyyQT, 0x1 );
	modify_field(YEKoZE.LKfNSO, 0x1 );
	modify_field(YEKoZE.LAIizK, YEKoZE.jvCpRl );
}

action YzsWpD() { 
	modify_field(YEKoZE.niJaGq, 0x1 );
	modify_field(YEKoZE.zpCVKR, 0x1 );
	add(YEKoZE.LAIizK, YEKoZE.jvCpRl, 0x1000 );
}

action VuYGSt() { 
	modify_field(cfDyxP.eHdmgU, BdarYZ.VtlLDM );
}

action Mkwjtg() { 
	modify_field(cfDyxP.TZUCwE, 0x1 );
}

action SLmkQK(XzuDRg) { 
	modify_field(cfDyxP.vAMWZi, XzuDRg );
}

action bqioIq() { 
	modify_field(OlPBiN.ioCVkH, lYXUin.tqMJMA );
	modify_field(OlPBiN.gVnEFV, lYXUin.zMkMTl );
	modify_field(OviEQo.YsfBYV, hibXlf.jEpyFj );
	modify_field(OviEQo.diDTUB, hibXlf.XpaWNM );
	modify_field(cfDyxP.eguEQM, oPHKWO.GpVggy );
	modify_field(cfDyxP.YWkHqd, oPHKWO.qTArPp );
	modify_field(cfDyxP.kLfTIU, oPHKWO.KaAvFG );
	modify_field(cfDyxP.FpUAZo, oPHKWO.wNAybQ );
}

action jJkNQM() { 
	modify_field(jtDeHH.RzhGTS, 0x1 );
}

action EIFNhP() { 
	modify_field(cfDyxP.EdbVwo, 0x1 );
	modify_field(cfDyxP.LvzHhI, 0x1 );
}

action dtVxfa() { 
}

action bwywWE() { 
}

action cwomqL(gwfDnu) { 
	modify_field(ktbBdq.Ljzbvt, gwfDnu );
}

action RMFuCv() { 
	modify_field(YEKoZE.iopEOe, 0x1 );
	modify_field(YEKoZE.LAIizK, YEKoZE.jvCpRl );
}

action gmRSWY(bKufzO) { 
	modify_field(YEKoZE.vEUGte, 0x1 );
	modify_field(YEKoZE.iTtIao, bKufzO );
}

action GoSejn(golbSh) { 
	modify_field(YEKoZE.niJaGq, 0x1 );
	modify_field(YEKoZE.LAIizK, golbSh );
}

action zggnXV() { 
	no_op( );
}

action aFPTVw() { 
	modify_field(ndIRii.OyFTpX, 0x1 );
}

action STOiil() { 
	generate_digest(0x0, HgFUwb );
}

action hTEbHS() { 
	modify_field(cfDyxP.nZmyfl, 0x0 );
	modify_field(cfDyxP.vAMWZi, BdarYZ.XzqkeH );
	modify_field(OlPBiN.ioCVkH, ujAsAs.tqMJMA );
	modify_field(OlPBiN.gVnEFV, ujAsAs.zMkMTl );
	modify_field(OviEQo.YsfBYV, SozCdH.jEpyFj );
	modify_field(OviEQo.diDTUB, SozCdH.XpaWNM );
	modify_field(cfDyxP.eguEQM, QUzEun.GpVggy );
	modify_field(cfDyxP.YWkHqd, QUzEun.qTArPp );
	modify_field(cfDyxP.kLfTIU, QUzEun.KaAvFG );
	modify_field(cfDyxP.FpUAZo, QUzEun.wNAybQ );
}

action GuOBkd() { 
	modify_field(cfDyxP.eHdmgU, LkPrni.BaAnQa );
}

action IJasQc() { 
	generate_digest(0x0, uajPdr );
}

action qIYpNC() { 
	modify_field(YEKoZE.eOdtuN, cfDyxP.eguEQM );
	modify_field(YEKoZE.QeEJZF, cfDyxP.YWkHqd );
	modify_field(YEKoZE.NONZPg, cfDyxP.kLfTIU );
	modify_field(YEKoZE.pkJpeD, cfDyxP.FpUAZo );
	modify_field(YEKoZE.jvCpRl, cfDyxP.eHdmgU );
}

action mwcXxi(EZSaKG) { 
	modify_field(OlPBiN.ZEWlin, EZSaKG );
}

action BrnZuC(INJWFP,hndQBi,gVOHDB,unFWnl,dVyMUm) { 
	modify_field(snSjFB.WwpGkv, INJWFP );
	modify_field(snSjFB.YRMmxz, hndQBi );
	modify_field(snSjFB.IMDzBn, gVOHDB );
	modify_field(snSjFB.yURZDh, unFWnl );
	modify_field(snSjFB.ZJQrpS, dVyMUm );
}

action fUXSVp() { 
	modify_field(jtDeHH.nsfmlu, 0x1 );
}

table fMlLMk {
	reads{
		ig_intr_md.ingress_port : exact;
	}
	actions{ 
		QzlCgG;
	}
	size : 288;
}

@pragma ways 4
table sUWDpz {
	reads{
		OlPBiN.ioCVkH : ternary;
	}
	actions{ 
		uPHxCo;
	}
	size : 2048;
}

@pragma ways 2
table BOnrSR {
	reads{
		OlPBiN.ioCVkH : exact;
	}
	actions{ 
		fUXSVp;
	}
	size : 1024;
}

@pragma ways 8
table NudxbW {
	reads{
		jtDeHH.nsfmlu : exact;
		OlPBiN.ioCVkH : exact;
	}
	actions{ 
		jJkNQM;
	}
	size : 1024;
}

table MnlGHy {
	reads{
		QUzEun.GpVggy : exact;
		QUzEun.qTArPp : exact;
	}
	actions{ 
		Mkwjtg;
	}
	size : 64;
}

table BeBzRQ {
	reads{
		QUzEun.GpVggy : exact;
		QUzEun.qTArPp : exact;
		ujAsAs.zMkMTl : exact;
		cfDyxP.nZmyfl : exact;
	}
	actions{ 
		bqioIq;
		hTEbHS;
	}
	size : 1024;
}

table OuIfwj {
	reads{
		BdarYZ.XzqkeH : ternary;
		LkPrni : valid;
		LkPrni.BaAnQa : ternary;
	}
	actions{ 
		VuYGSt;
		zJjFjD;
		GuOBkd;
	}
	size : 4096;
}

table EghpzX {
	reads{
		ujAsAs.tqMJMA : exact;
	}
	actions{ 
		SLmkQK;
		qoKTrI;
	}
	size : 4096;
}

table YKYNSG {
	reads{
		qAVGBC.rcAoXD : exact;
	}
	actions{ 
		MbVkKv;
		EIFNhP;
	}
	size : 4096;
}

table ehyhNJ {
	reads{
		BdarYZ.VtlLDM : exact;
	}
	actions{ 
		BrnZuC;
	}
	size : 4096;
}

table UqMimZ {
	reads{
		BdarYZ.XzqkeH : exact;
		LkPrni.BaAnQa : exact;
	}
	actions{ 
		BrnZuC;
		zggnXV;
	}
	size : 1024;
}

table CHXYIU {
	reads{
		LkPrni.BaAnQa : exact;
	}
	actions{ 
		BrnZuC;
	}
	size : 4096;
}

table OOBXBe {
	
	actions{ 
		STOiil;
	}
	size : 1;
}

table nhkOEk {
	reads{
		cfDyxP.eHdmgU : ternary;
		cfDyxP.eguEQM : exact;
		cfDyxP.YWkHqd : exact;
	}
	actions{ 
		aFPTVw;
	}
	size : 512;
}

table KbbyqJ {
	
	actions{ 
		IJasQc;
	}
	size : 1;
}

table RSLvpr {
	reads{
		snSjFB.WwpGkv : exact;
		OlPBiN.gVnEFV : lpm;
	}
	actions{ 
		mwcXxi;
	}
	size : 16384;
}

@pragma atcam_partition_index OlPBiN.ZEWlin
@pragma atcam_number_partitions 16384
table hywqVp {
	reads{
		OlPBiN.ZEWlin : exact;
		OlPBiN.gVnEFV : lpm;
	}
	actions{ 
		cwomqL;
	}
	size : 147456;
}

table xGtDBG {
	reads{
		snSjFB.WwpGkv : exact;
		OlPBiN.gVnEFV : exact;
	}
	actions{ 
		cwomqL;
		zggnXV;
	}
	size : 65536;
}

table pswDoc {
	
	actions{ 
		qIYpNC;
	}
	size : 1;
}

@pragma ways 1
table iAPDQh {
	reads{
		cfDyxP.eguEQM : exact;
		cfDyxP.YWkHqd : exact;
	}
	actions{ 
		ICxVPq;
		dtVxfa;
	}
	size : 1;
}

table UXzVfm {
	
	actions{ 
		YzsWpD;
	}
	size : 1;
}

table lvfcRk {
	
	actions{ 
		RMFuCv;
	}
	size : 1;
}

table RFvNXO {
	reads{
		YEKoZE.eOdtuN : exact;
		YEKoZE.QeEJZF : exact;
		YEKoZE.jvCpRl : exact;
	}
	actions{ 
		gmRSWY;
		GoSejn;
		bwywWE;
	}
	size : 65536;
}

control ingressProcessing { 
	if (ig_intr_md.resubmit_flag == 0x0) { 
		apply( fMlLMk );

	}

	apply( MnlGHy );

	apply( BeBzRQ ) {
		hTEbHS {
			if (BdarYZ.NWqDYn == 0x1) { 
				apply( OuIfwj );

			}

			if (( valid( LkPrni ) ) and (( valid( ujAsAs ) ) or ( valid( SozCdH ) ))) { 
				apply( UqMimZ ) {
					zggnXV {
						apply( CHXYIU );

					}
				}
			}

         else if (( valid( ujAsAs ) ) or ( valid( SozCdH ) )) { 
				apply( ehyhNJ );

			}

		}
		bqioIq {
			apply( EghpzX );

			apply( YKYNSG );

		}
	}
	apply( sUWDpz );

	apply( BOnrSR );

	apply( NudxbW );

	if ((cfDyxP.EdbVwo == 0x0) and (cfDyxP.LvzHhI == 0x0)) { 
		apply( nhkOEk );

	}

	if (((KcFelw.pkkAoe == 0x0) and (KcFelw.awtutZ == 0x0)) and (cfDyxP.EdbVwo == 0x0)) { 
		if ((snSjFB.YRMmxz == 0x1) and (((cfDyxP.nZmyfl == 0x0) and ( valid( ujAsAs ) )) or ((cfDyxP.nZmyfl != 0x0) and ( valid( lYXUin ) )))) { 
			apply( xGtDBG ) {
				zggnXV {
					apply( RSLvpr );

					if (OlPBiN.ZEWlin != 0x0) { 
						apply( hywqVp );

					}

				}
			}
		}

	}

	if (ndIRii.OyFTpX == 0x0) { 
		apply( pswDoc );

	}

	if (cfDyxP.EdbVwo == 0x0) { 
		apply( RFvNXO ) {
			bwywWE {
				apply( iAPDQh ) {
					dtVxfa {
						if ((YEKoZE.eOdtuN & 0x10000) == 0x10000) { 
							apply( UXzVfm );

						} else {

						apply( lvfcRk );
                  }

					}
				}
			}
		}
	}

	if (cfDyxP.GiugcX == 0x1) { 
		apply( OOBXBe );

	}

	if (cfDyxP.zfeFym == 0x1) { 
		apply( KbbyqJ );

	}

}

control egressProcessing { 
}
