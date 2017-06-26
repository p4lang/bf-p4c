// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.

#ifndef HEADERS_H4
#define HEADERS_H4

header_type utIVEA {
	fields { 
	RPhPiY : 24;
	wykVGD : 24;
	MkajiY : 24;
	TWqzUp : 24;
	pOIqxO : 16;
	VvPTXS : 16;
	DZNMIg : 16;
	FxsiSr : 12;
	eKzYkG : 2;
	bgHldk : 1;
	tqPJuF : 1;
	elVjeb : 1;
	QwTCXn : 1;
	EcLQpV : 1;
	hlnpSR : 1;
	nMfQfA : 3;
	}
}

header_type pcfLqu {
	fields { 
	UkUtwO : 24;
	LPpPpN : 24;
	ZyxeZO : 24;
	IxlzuE : 24;
	HrAWno : 16;
	yucxOH : 16;
	mGCUUr : 16;
	JnbdSz : 12;
	CgjKAP : 9;
	UMkSdG : 1;
	QiMPVt : 1;
	YxpEDn : 1;
	RZsdyV : 1;
	FzbQJA : 1;
	ivzivF : 1;
	}
}

header_type sYHsCK {
	fields { 
	zqANcB : 8;
	xTcoWx : 1;
	eZBwQb : 1;
	GQRvBL : 1;
	zAHqEG : 1;
	zfujpg : 1;
	}
}

header_type ghhcOK {
	fields { 
	GnHlYJ : 32;
	NGhnfL : 32;
	MyzObD : 16;
	}
}

header_type LEvEDD {
	fields { 
	iFDSJN : 128;
	NPdben : 128;
	}
}

header_type MQvRDT {
	fields { 
	JazWSq : 14;
	zBlBAY : 1;
	UztNiv : 1;
	mdnlIN : 12;
	}
}

header_type EoieIl {
	fields { 
	gzYNJt : 1;
	jmskSs : 1;
	}
}

header_type drPvCh {
	fields { 
	zZzaZs : 8;
	}
}

header_type zyneRy {
	fields { 
	cmcuBX : 16;
	}
}

header_type gugSTk {
	fields { 
	HPeQML : 24;
	bltEbn : 24;
	duGsPV : 24;
	IfGrgl : 24;
	HLmiZx : 16;
	}
}

header_type XKkNha {
	fields { 
	XmNyXY : 3;
	FjbWCW : 1;
	cdQtGK : 12;
	LylCgV : 16;
	}
}

header_type AflVHK {
	fields { 
	HcULnr : 4;
	fsZcwQ : 4;
	UkWjzj : 8;
	HJmUEL : 16;
	YqLkIO : 16;
	SuTDCS : 3;
	BOfarG : 13;
	FVwMNt : 8;
	wediBU : 8;
	TnScCG : 16;
	Ihpezt : 32;
	qAssHK : 32;
	}
}

header_type EcKkMl {
	fields { 
	kMqluu : 4;
	hfKVLM : 8;
	XLWqVz : 20;
	lMISoL : 16;
	sZiImI : 8;
	ySzKat : 8;
	iYriWn : 128;
	hDlwUn : 128;
	}
}

header_type nwKXRI {
	fields { 
	XFHgZD : 16;
	YpjUPh : 16;
	AMGQiE : 16;
	TPCCMk : 16;
	}
}

header_type xeihTT {
	fields { 
	dzDCIS : 16;
	rxwAac : 16;
	ZpMqOx : 8;
	fnUBon : 8;
	xuhpRt : 16;
	}
}

header_type wjsYmB {
	fields { 
	hjqIHj : 8;
	bNvGGV : 24;
	qtDvuq : 24;
	dbqptE : 8;
	}
}

#endif // HEADERS_H4

#ifndef PARSER_H4
#define PARSER_H4

header gugSTk KqUoHB;
header gugSTk MYGeIm;
header XKkNha aGCwBy;
header XKkNha QBJpno;
header AflVHK sULdSu;
header AflVHK yEOPPV;
header EcKkMl mlybLS;
header EcKkMl LqJwCB;
header nwKXRI rFqymL;
header wjsYmB gtGekT;
header xeihTT aepgjV;
metadata utIVEA jSqpae;
metadata pcfLqu ZIrQiH;
metadata MQvRDT ZcGoCa;
metadata ghhcOK Jmvzsq;
metadata LEvEDD BJbIri;
metadata EoieIl bOswHr;
metadata sYHsCK wYDlac;
metadata drPvCh vsoyDU;
metadata zyneRy qJwTfB;

parser oibWmN { 
	extract(LqJwCB );
	return ingress;
}

parser hHvsto { 
	extract(MYGeIm );
	return ingress;
}

parser WVWjMZ { 
	extract(rFqymL );
	return select( rFqymL.YpjUPh ) {
		0x12b5 : hneEmI;
		default : ingress;
	}
}

parser hneEmI { 
	extract(gtGekT );
	set_metadata(jSqpae.eKzYkG, 0x1 );
	return select( gtGekT.qtDvuq ) {
		default : hHvsto;
	}
}

parser ThbFPa { 
	extract(aGCwBy );
	return select( aGCwBy.LylCgV ) {
		0x0800 : BBXNeC;
		0x86dd : oibWmN;
		0x0806 : AceWsM;
		default : ingress;
	}
}

parser BBXNeC { 
	extract(sULdSu );
	return select( sULdSu.BOfarG, sULdSu.fsZcwQ, sULdSu.wediBU ) {
		0x00000511 : WVWjMZ;
		default : ingress;
	}
}

parser start { 
	return SnMIki;
}

parser SnMIki { 
	extract(KqUoHB );
	set_metadata(jSqpae.RPhPiY, KqUoHB.HPeQML );
	set_metadata(jSqpae.wykVGD, KqUoHB.bltEbn );
	set_metadata(jSqpae.MkajiY, KqUoHB.duGsPV );
	set_metadata(jSqpae.TWqzUp, KqUoHB.IfGrgl );
	return select( KqUoHB.HLmiZx ) {
		0x8100 : ThbFPa;
		0x0800 : BBXNeC;
		0x86dd : oibWmN;
		0x0806 : AceWsM;
		default : ingress;
	}
}

parser AceWsM { 
	extract(aepgjV );
	return ingress;
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

@pragma pa_solitary ingress jSqpae.pOIqxO
@pragma pa_solitary ingress jSqpae.VvPTXS
@pragma pa_solitary ingress jSqpae.DZNMIg
@pragma pa_solitary ig_intr_md_for_tm.ucast_egress_port

field_list RaHIyp { 
	vsoyDU.zZzaZs;
	jSqpae.pOIqxO;
	MYGeIm.duGsPV;
	MYGeIm.IfGrgl;
	sULdSu.Ihpezt;
}

field_list VTPwAK { 
	vsoyDU.zZzaZs;
	jSqpae.MkajiY;
	jSqpae.TWqzUp;
	jSqpae.pOIqxO;
	jSqpae.VvPTXS;
}

action LFyINr() { 
}

action ZOcmCh(BpRiQs) { 
	modify_field(ZIrQiH.RZsdyV, 0x1 );
	modify_field(ZIrQiH.yucxOH, BpRiQs );
	modify_field(ig_intr_md_for_tm.ucast_egress_port, BpRiQs );
	modify_field(ZIrQiH.CgjKAP, BpRiQs );
}

action QOnsao() { 
	no_op( );
}

action WSYgPX() { 
	modify_field(jSqpae.pOIqxO, ZcGoCa.mdnlIN );
}

action wDCdba() { 
	modify_field(ZIrQiH.UkUtwO, jSqpae.RPhPiY );
	modify_field(ZIrQiH.LPpPpN, jSqpae.wykVGD );
	modify_field(ZIrQiH.ZyxeZO, jSqpae.MkajiY );
	modify_field(ZIrQiH.IxlzuE, jSqpae.TWqzUp );
	modify_field(ZIrQiH.HrAWno, jSqpae.pOIqxO );
}

action qvpIRb(siEVHw) { 
	modify_field(jSqpae.pOIqxO, siEVHw );
}

action DHnNTK(siEVHw,TOekST,mBHiec,guaLer,IOiVJT,yTbavB) { 
	modify_field(jSqpae.DZNMIg, siEVHw );
	modify_field(jSqpae.hlnpSR, 0x1 );
	modify_field(wYDlac.zqANcB, TOekST );
	modify_field(wYDlac.xTcoWx, mBHiec );
	modify_field(wYDlac.GQRvBL, guaLer );
	modify_field(wYDlac.eZBwQb, IOiVJT );
	modify_field(wYDlac.zAHqEG, yTbavB );
}

action bkYzOb() { 
	modify_field(jSqpae.bgHldk, 0x1 );
}

action fJLGnG() { 
	modify_field(ZIrQiH.YxpEDn, 0x1 );
	modify_field(ZIrQiH.ivzivF, 0x1 );
	add(ZIrQiH.mGCUUr, ZIrQiH.HrAWno, 0x1000 );
}

action HyMSUz() { 
	modify_field(jSqpae.eKzYkG, 0x0 );
	modify_field(jSqpae.VvPTXS, ZcGoCa.JazWSq );
	modify_field(Jmvzsq.GnHlYJ, sULdSu.Ihpezt );
	modify_field(Jmvzsq.NGhnfL, sULdSu.qAssHK );
	modify_field(BJbIri.iFDSJN, LqJwCB.iYriWn );
	modify_field(BJbIri.NPdben, LqJwCB.hDlwUn );
	modify_field(jSqpae.RPhPiY, KqUoHB.HPeQML );
	modify_field(jSqpae.wykVGD, KqUoHB.bltEbn );
	modify_field(jSqpae.MkajiY, KqUoHB.duGsPV );
	modify_field(jSqpae.TWqzUp, KqUoHB.IfGrgl );
}

action jqspBM() { 
	modify_field(ZIrQiH.QiMPVt, 0x1 );
	modify_field(ZIrQiH.UMkSdG, 0x1 );
	modify_field(ZIrQiH.mGCUUr, ZIrQiH.HrAWno );
}

action yeJxkf(TOekST,mBHiec,guaLer,IOiVJT,yTbavB) { 
	modify_field(jSqpae.DZNMIg, ZcGoCa.mdnlIN );
	modify_field(jSqpae.hlnpSR, 0x1 );
	modify_field(wYDlac.zqANcB, TOekST );
	modify_field(wYDlac.xTcoWx, mBHiec );
	modify_field(wYDlac.GQRvBL, guaLer );
	modify_field(wYDlac.eZBwQb, IOiVJT );
	modify_field(wYDlac.zAHqEG, yTbavB );
}

action cJcUfL() { 
	modify_field(wYDlac.zfujpg, 0x1 );
}

action HrLvrR(PHWhvV) { 
#ifdef BMV2
	register_write(YKIZwy, PHWhvV, 0x1 );
#endif
}

action SXIJHU() { 
}

action AwCFNy() { 
	modify_field(jSqpae.pOIqxO, aGCwBy.cdQtGK );
}

action WhpXrV() { 
	modify_field(ZIrQiH.FzbQJA, 0x1 );
	modify_field(ZIrQiH.mGCUUr, ZIrQiH.HrAWno );
}

action eopPLX() { 
	no_op( );
}

action hnaYfv(EzGJjr) { 
	modify_field(Jmvzsq.MyzObD, EzGJjr );
}

action rPlvuz() { 
	modify_field(jSqpae.elVjeb, 0x1 );
	modify_field(vsoyDU.zZzaZs, 0x1 );
}

action pTLwNz(cIrAyj,TOekST,mBHiec,guaLer,IOiVJT,yTbavB,zxSZXI) { 
	modify_field(jSqpae.pOIqxO, cIrAyj );
	modify_field(jSqpae.hlnpSR, zxSZXI );
	modify_field(wYDlac.zqANcB, TOekST );
	modify_field(wYDlac.xTcoWx, mBHiec );
	modify_field(wYDlac.GQRvBL, guaLer );
	modify_field(wYDlac.eZBwQb, IOiVJT );
	modify_field(wYDlac.zAHqEG, yTbavB );
}

action RzTKNQ() { 
	generate_digest(0x0, RaHIyp );
}

action fLlqqK() { 
	modify_field(KqUoHB.HLmiZx, aGCwBy.LylCgV );
	modify_field(jSqpae.nMfQfA, aGCwBy.XmNyXY );
	remove_header(aGCwBy );
}

action haXkca() { 
	add_header(aGCwBy );
	modify_field(aGCwBy.cdQtGK, ZIrQiH.JnbdSz );
	modify_field(aGCwBy.XmNyXY, jSqpae.nMfQfA );
	modify_field(aGCwBy.LylCgV, KqUoHB.HLmiZx );
	modify_field(KqUoHB.HLmiZx, 0x8100 );
}

action lCwymN(TOekST,mBHiec,guaLer,IOiVJT,yTbavB) { 
	modify_field(jSqpae.DZNMIg, aGCwBy.cdQtGK );
	modify_field(jSqpae.hlnpSR, 0x1 );
	modify_field(wYDlac.zqANcB, TOekST );
	modify_field(wYDlac.xTcoWx, mBHiec );
	modify_field(wYDlac.GQRvBL, guaLer );
	modify_field(wYDlac.eZBwQb, IOiVJT );
	modify_field(wYDlac.zAHqEG, yTbavB );
}

action pSPAke() { 
	modify_field(jSqpae.tqPJuF, 0x1 );
	modify_field(vsoyDU.zZzaZs, 0x0 );
}

action bbczIf(EwkUfT) { 
	modify_field(jSqpae.VvPTXS, EwkUfT );
}

action IuhFrg(cIrAyj) { 
	modify_field(ZIrQiH.JnbdSz, cIrAyj );
	remove_header(aGCwBy );
}

action QrzRAL() { 
	generate_digest(0x0, VTPwAK );
}

action GawuMf() { 
	modify_field(Jmvzsq.GnHlYJ, yEOPPV.Ihpezt );
	modify_field(Jmvzsq.NGhnfL, yEOPPV.qAssHK );
	modify_field(BJbIri.iFDSJN, mlybLS.iYriWn );
	modify_field(BJbIri.NPdben, mlybLS.hDlwUn );
	modify_field(jSqpae.RPhPiY, MYGeIm.HPeQML );
	modify_field(jSqpae.wykVGD, MYGeIm.bltEbn );
	modify_field(jSqpae.MkajiY, MYGeIm.duGsPV );
	modify_field(jSqpae.TWqzUp, MYGeIm.IfGrgl );
}

action ntiWZD(QMXycT,UGnwFT,tCsDEV,CBsLVF) { 
	modify_field(ZcGoCa.JazWSq, QMXycT );
	modify_field(ZcGoCa.zBlBAY, UGnwFT );
	modify_field(ZcGoCa.mdnlIN, tCsDEV );
	modify_field(ZcGoCa.UztNiv, CBsLVF );
}

action jjUIKR(MdvLkK) { 
	modify_field(ZIrQiH.YxpEDn, 0x1 );
	modify_field(ZIrQiH.mGCUUr, MdvLkK );
}

action ZXuFbP() { 
	modify_field(jSqpae.QwTCXn, 0x1 );
	modify_field(jSqpae.EcLQpV, 0x1 );
}

action fJutPM(BVCYuv) { 
	modify_field(qJwTfB.cmcuBX, BVCYuv );
}

table fNqUti {
	reads{
		ig_intr_md.ingress_port : exact;
	}
	actions{ 
		ntiWZD;
	}
	size : 288;
}

table XwcVlN {
	reads{
		KqUoHB.HPeQML : exact;
		KqUoHB.bltEbn : exact;
	}
	actions{ 
		bkYzOb;
	}
	size : 64;
}

table MewBbN {
	reads{
		KqUoHB.HPeQML : exact;
		KqUoHB.bltEbn : exact;
		sULdSu.qAssHK : exact;
		jSqpae.eKzYkG : exact;
	}
	actions{ 
		GawuMf;
		HyMSUz;
	}
	size : 1024;
}

table SHvAeR {
	reads{
		ZcGoCa.JazWSq : ternary;
		aGCwBy : valid;
		aGCwBy.cdQtGK : ternary;
	}
	actions{ 
		WSYgPX;
		qvpIRb;
		AwCFNy;
	}
	size : 4096;
}

table jKqWQQ {
	reads{
		sULdSu.Ihpezt : exact;
	}
	actions{ 
		bbczIf;
		rPlvuz;
	}
	size : 4096;
}

table CvmGZq {
	reads{
		gtGekT.qtDvuq : exact;
	}
	actions{ 
		pTLwNz;
		ZXuFbP;
	}
	size : 4096;
}

table wIHiQR {
	reads{
		ZcGoCa.mdnlIN : exact;
	}
	actions{ 
		yeJxkf;
	}
	size : 4096;
}

table uwXElH {
	reads{
		ZcGoCa.JazWSq : exact;
		aGCwBy.cdQtGK : exact;
	}
	actions{ 
		DHnNTK;
		QOnsao;
	}
	size : 1024;
}

table qmELlF {
	reads{
		aGCwBy.cdQtGK : exact;
	}
	actions{ 
		lCwymN;
	}
	size : 4096;
}

table wHpjxc {
	
	actions{ 
		RzTKNQ;
	}
	size : 1;
}

table lXhPjS {
	reads{
		jSqpae.DZNMIg : ternary;
		jSqpae.RPhPiY : exact;
		jSqpae.wykVGD : exact;
	}
	actions{ 
		cJcUfL;
	}
	size : 512;
}

register YKIZwy {
	width : 1;
	static : zvUaRN;
	instance_count: 65536;
}

table zvUaRN {
	reads{
		jSqpae.MkajiY : exact;
		jSqpae.TWqzUp : exact;
		jSqpae.pOIqxO : exact;
		jSqpae.VvPTXS : exact;
	}
	actions{ 
		HrLvrR;
		pSPAke;
	}
	size : 65536;
}

table ulGhkC {
	
	actions{ 
		QrzRAL;
	}
	size : 1;
}

table uvLcwz {
	reads{
		wYDlac.zqANcB : exact;
		Jmvzsq.NGhnfL : lpm;
	}
	actions{ 
		hnaYfv;
	}
	size : 16384;
}

@pragma atcam_partition_index Jmvzsq.MyzObD
@pragma atcam_number_partitions 16384
table pUwXgw {
	reads{
		Jmvzsq.MyzObD : exact;
		Jmvzsq.NGhnfL : lpm;
	}
	actions{ 
		fJutPM;
	}
	size : 147456;
}

table gfrjtK {
	reads{
		wYDlac.zqANcB : exact;
		Jmvzsq.NGhnfL : exact;
	}
	actions{ 
		fJutPM;
		QOnsao;
	}
	size : 65536;
}

table cOGuiM {
	
	actions{ 
		wDCdba;
	}
	size : 1;
}

table qBOLVQ {
	reads{
		jSqpae.RPhPiY : exact;
		jSqpae.wykVGD : exact;
	}
	actions{ 
		jqspBM;
		SXIJHU;
	}
	size : 1;
}

table NEINGI {
	
	actions{ 
		fJLGnG;
	}
	size : 1;
}

table dqtyNX {
	
	actions{ 
		WhpXrV;
	}
	size : 1;
}

table jqIVUQ {
	reads{
		ZIrQiH.UkUtwO : exact;
		ZIrQiH.LPpPpN : exact;
		ZIrQiH.HrAWno : exact;
	}
	actions{ 
		ZOcmCh;
		jjUIKR;
		LFyINr;
	}
	size : 65536;
}

table xUkjnn {
	
	actions{ 
		fLlqqK;
	}
	size : 1;
}

control ingress { 
	if (ig_intr_md.resubmit_flag == 0x0) { 
		apply( fNqUti );

	}

	apply( XwcVlN );

	apply( MewBbN ) {
		HyMSUz {
			if (ZcGoCa.UztNiv == 0x1) { 
				apply( SHvAeR );

			}

			if ( valid( aGCwBy ) ) { 
				apply( uwXElH ) {
					QOnsao {
						apply( qmELlF );

					}
				}
			}

			apply( wIHiQR );

		}
		GawuMf {
			apply( jKqWQQ );

			apply( CvmGZq );

		}
	}
	if ((ZcGoCa.zBlBAY == 0x0) and (jSqpae.elVjeb == 0x0)) { 
		apply( zvUaRN );

	}

	if ((jSqpae.QwTCXn == 0x0) and (jSqpae.EcLQpV == 0x0)) { 
		apply( lXhPjS );

	}

	if ((((bOswHr.gzYNJt == 0x0) and (bOswHr.jmskSs == 0x0)) and (jSqpae.QwTCXn == 0x0)) and (wYDlac.zfujpg == 0x1)) { 
		if ((wYDlac.xTcoWx == 0x1) and (((jSqpae.eKzYkG == 0x0) and ( valid( sULdSu ) )) or ((jSqpae.eKzYkG != 0x0) and ( valid( yEOPPV ) )))) { 
			apply( gfrjtK ) {
				QOnsao {
					apply( uvLcwz );

					if (Jmvzsq.MyzObD != 0x0) { 
						apply( pUwXgw );

					}

				}
			}
		}

	}

	if (wYDlac.zfujpg == 0x0) { 
		apply( cOGuiM );

	}

	if (jSqpae.QwTCXn == 0x0) { 
		apply( jqIVUQ ) {
			LFyINr {
				apply( qBOLVQ ) {
					SXIJHU {
						if ((ZIrQiH.UkUtwO & 0x10000) == 0x10000) { 
							apply( NEINGI );

						}

						apply( dqtyNX );

					}
				}
			}
		}
	}

	if (jSqpae.elVjeb == 0x1) { 
		apply( wHpjxc );

	}

	if (jSqpae.tqPJuF == 0x1) { 
		apply( ulGhkC );

	}

	if ( valid( aGCwBy ) ) { 
		apply( xUkjnn );

	}

}

table oTQXQB {
	reads{
		ZIrQiH.HrAWno : exact;
	}
	actions{ 
		IuhFrg;
	}
	size : 4096;
}

table YNslee {
	reads{
		ZIrQiH.JnbdSz : exact;
		ZIrQiH.CgjKAP : exact;
	}
	actions{ 
		eopPLX;
		haXkca;
	}
	size : 64;
}

control egress { 
	apply( oTQXQB );

	apply( YNslee );

}
