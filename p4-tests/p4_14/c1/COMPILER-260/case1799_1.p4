// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
// randomseed: 154200







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
#else





header_type yFASjA {
	fields {
		tYyoYb : 3;
	}
}
metadata yFASjA PjoOyv;

header_type RlsZKO {
	fields {
		XRlRuW : 1;
		IHzibH : 9;
		Qnkyav : 48;
		cFpuUx : 32;
	}
}
metadata RlsZKO fSFWnr;

header_type mXFMLu {
	fields {
		eqGQog : 9;
		cRxeqS : 3;
		MBJOaV : 16;
		iAYzwn : 16;
		uYeOMC : 13;
		caNyAL : 13;
		FWfDPo : 16;
		jgYpvY : 9;
		Cbjnry : 16;
		XyZTLs : 1;
		dlHOBb : 3;
		nWHszG : 5;
		ABNdvB : 2;
	}
}

metadata mXFMLu SLSBhe;

header_type qzjySi {
	fields {
		liMJPA : 9;
		rkqapI : 19;
		gwnKUx : 2;
		sbRTwL : 32;
		PILVQg : 19;
		sTfshd : 2;
		zTFjCn : 8;
		mRaKYW : 32;
		tJAiRw : 16;
		tgnMIR : 1;
		EXlVCN : 5;
		NqYxLa : 3;
		fBvvZY : 1;
	}
}

metadata qzjySi bDIzUp;




action ZtjZEJ(vzMgnS) {
    modify_field(vrHLbL, vzMgnS);
}

#ifdef BMV2
#define nirylW     WskqKv
#else
#define nirylW         LKuULB
#endif

header_type ujSFSa {
	fields {
		hggOQZ : 8;
		FdDjlA : 48;
	}
}
metadata ujSFSa OxRUOj;

#define idYmKI 0
#define aECSXA 1
#define QpLrRT 2
#define oOtksQ 3
#define ITnPIS 4
#define jqlzJF 5
#define UyQHAn 6


#define tqsjwN \
    ((XyHKlf != idYmKI) and \
     (XyHKlf != jqlzJF))
#define dnCUiN \
    ((XyHKlf == idYmKI) or \
     (XyHKlf == jqlzJF))
#define ZTXZob \
    (XyHKlf == aECSXA)
#define AepvXN \
    (XyHKlf == QpLrRT)
#endif



#ifndef BBnLcf
#define BBnLcf

header_type hDYMcY {
	fields {
		ZlKTpC : 24;
		XULmvX : 24;
		lDRqij : 24;
		gzTogt : 24;
		geSdkA : 16;
		dnnZBE : 16;
		fxaceD : 16;
		aaxKVh : 16;
		PlNxwi : 12;
		MgCYWv : 2;
		GERUGL : 1;
		YpkCXt : 1;
		Btudba : 1;
		FlyOGN : 1;
		voVGgH : 1;
		mdIJff : 1;
		eSTwIB : 1;
		NmVHqk : 1;
		zKEdLf : 1;
		seCsYb : 1;
		meaTlr : 1;
	}
}

header_type dOnQOY {
	fields {
		XtjQOt : 24;
		phNuMP : 24;
		uQqZem : 24;
		cOTGpW : 24;
		bOrlpX : 24;
		kHuqpQ : 24;
		yWiZak : 16;
		FJaMhx : 16;
		dEpCpX : 16;
		Crnury : 12;
		WQEcHW : 3;
		hGsdpN : 3;
		AKktqJ : 1;
		tlxjBI : 1;
		NMjfEN : 1;
		jYwTiv : 1;
		MxCNHk : 1;
		OxaBzh : 1;
		FbZPCV : 1;
		BxqzOJ : 1;
		fRkpZh : 8;
	}
}

header_type vCHZaQ {
	fields {
		RimUZY : 8;
		ScSsrg : 1;
		idBWft : 1;
		RjOOdv : 1;
		huBqJa : 1;
		MRBoTh : 1;
	}
}

header_type ovbffT {
	fields {
		SvjLjO : 32;
		yFhASD : 32;
		yjYXse : 8;
		vHIEVR : 16;
	}
}

header_type RFsRYU {
	fields {
		IFaKfC : 128;
		tLRngq : 128;
		GxriLE : 20;
		hhuJIo : 8;
	}
}

header_type GSCxzi {
	fields {
		bBdRYe : 14;
		OkmIdf : 1;
		FfnVoF : 1;
		tcpbrh : 12;
		lxSpki : 1;
		qDdnCn : 6;
	}
}

header_type dWoWnP {
	fields {
		sRUjfg : 1;
		ymFIux : 1;
	}
}

header_type WebmrG {
	fields {
		JyxaUo : 8;
	}
}

header_type uESsmr {
	fields {
		KbmtfM : 16;
	}
}

header_type MyPNUO {
	fields {
		CITpsH :32;
		ehKLQS : 32;
	}
}

#endif



#ifndef WKwuqK
#define WKwuqK



header_type fiSJdp {
	fields {
		nfyWUz : 24;
		bbJqjF : 24;
		guzLDR : 24;
		JAADXJ : 24;
		NdTFbZ : 16;
	}
}



header_type eWVqSp {
	fields {
		FZqPQk : 3;
		tAveSA : 1;
		SdLIvH : 12;
		nHmyTr : 16;
	}
}



header_type iKXAgh {
	fields {
		CmARna : 4;
		wzYeSD : 4;
		VjsMVg : 8;
		OahBXx : 16;
		aJwUvX : 16;
		pHUVyO : 3;
		ZLxwuX : 13;
		YiOJqy : 8;
		KgxBJD : 8;
		UqOxXE : 16;
		nEWzFM : 32;
		QGkiWU : 32;
	}
}

header_type WRdjdw {
	fields {
		DdlSPU : 4;
		NVwaFf : 8;
		VYSInC : 20;
		ydmJOK : 16;
		yPebTa : 8;
		zjHDzN : 8;
		arsNZE : 128;
		qwzuBO : 128;
	}
}




header_type UlDgVu {
	fields {
		CYvMCq : 8;
		YJZLXZ : 8;
		oxddcA : 16;
	}
}

header_type wDhJWr {
	fields {
		IESDui : 16;
		EhxIXF : 16;
		QkrqRd : 32;
		FWxLfs : 32;
		lcvoKh : 4;
		FUSGQh : 4;
		xeJeuH : 8;
		owhTnf : 16;
		ReluYF : 16;
		HdxBeO : 16;
	}
}

header_type bPnuBu {
	fields {
		xfUbrS : 16;
		IvNeva : 16;
		MYamyc : 16;
		DAKxmb : 16;
	}
}



header_type QWuYMi {
	fields {
		dPWUAe : 16;
		bonEuQ : 16;
		nwfcLN : 8;
		qUOAuJ : 8;
		AHzlYE : 16;
	}
}

header_type iVOKws {
	fields {
		juonJQ : 48;
		EHCRSX : 32;
		adlmHC : 48;
		bMPxft : 32;
	}
}



header_type rZHYZS {
	fields {
		CMKWiC : 1;
		koqqfS : 1;
		ivPHkV : 1;
		EKovQv : 1;
		dUegzN : 1;
		KknNON : 3;
		CoWZFL : 5;
		rOHpgq : 3;
		JZkrIZ : 16;
	}
}

header_type dkuuSK {
	fields {
		VqodRj : 24;
		olFdZi : 8;
	}
}



header_type ThhgVB {
	fields {
		CUSZqE : 8;
		ddqYgf : 24;
		buAbKG : 24;
		DdKQff : 8;
	}
}

#endif



#ifndef drertd
#define drertd

parser start {
   return dFOSaZ;
}

#define uYDOJd        0x8100
#define kXjmSR        0x0800
#define YwtPQr        0x86dd
#define xVKuaO        0x9100
#define AfFQqV        0x8847
#define jYvgPH         0x0806
#define nyvqhJ        0x8035
#define kEplcE        0x88cc
#define uzSnDW        0x8809

#define ljgHlo              1
#define UwfnVD              2
#define yAknrr              4
#define HlJsEC               6
#define VVBkqH               17
#define tRmRlP                47

#define XPAWQj         0x501
#define VNWgpM          0x506
#define OxCciR          0x511
#define xFenln          0x52F


#define hCtHSC                 4789



#define eIUTBA               0
#define BiVXXH              1
#define yogULa                2



#define jtaDOI          0
#define EZSQXi          4095
#define AtxDUe  4096
#define iiRBGQ  8191



#define OotCJI                      0
#define pqKlnv                  0
#define vSgrnT                 1

header fiSJdp hPVgfz;
header fiSJdp ejedVK;
header eWVqSp UsqKHW[ 2 ];
header iKXAgh oADQdp;
header iKXAgh PeankK;
header WRdjdw dnOwUx;
header WRdjdw CsNnAq;
header wDhJWr pkBpIo;
header bPnuBu fpKWAU;
header wDhJWr bsPHav;
header bPnuBu ubDSaI;
header ThhgVB cIWcqc;
header QWuYMi SmkXZl;
header rZHYZS eBvgQa;

parser dFOSaZ {
   extract( hPVgfz );
   return select( hPVgfz.NdTFbZ ) {
      uYDOJd : CHqqUD;
      kXjmSR : qSGrpd;
      YwtPQr : dQMcLL;
      jYvgPH  : ZdQHRG;
      default        : ingress;
   }
}

parser CHqqUD {
   extract( UsqKHW[0] );
   return select( UsqKHW[0].nHmyTr ) {
      kXjmSR : qSGrpd;
      YwtPQr : dQMcLL;
      jYvgPH  : ZdQHRG;
      default : ingress;
   }
}

parser qSGrpd {
   extract( oADQdp );
   return select(oADQdp.ZLxwuX, oADQdp.wzYeSD, oADQdp.KgxBJD) {
      OxCciR : MULTre;
      default : ingress;
   }
}

parser dQMcLL {
   extract( CsNnAq );
   return ingress;
}

parser ZdQHRG {
   extract( SmkXZl );
   return ingress;
}

parser MULTre {
   extract(fpKWAU);
   return select(fpKWAU.IvNeva) {
      hCtHSC : XlSxTX;
      default : ingress;
    }
}

parser nNMdlV {
   set_metadata(CNpgHg.MgCYWv, yogULa);
   return Byuchi;
}

parser sBqrNz {
   set_metadata(CNpgHg.MgCYWv, yogULa);
   return MwcfQZ;
}

parser HXDtRe {
   extract(eBvgQa);
   return select(eBvgQa.CMKWiC, eBvgQa.koqqfS, eBvgQa.ivPHkV, eBvgQa.EKovQv, eBvgQa.dUegzN,
             eBvgQa.KknNON, eBvgQa.CoWZFL, eBvgQa.rOHpgq, eBvgQa.JZkrIZ) {
      kXjmSR : nNMdlV;
      YwtPQr : sBqrNz;
      default : ingress;
   }
}

parser XlSxTX {
   extract(cIWcqc);
   set_metadata(CNpgHg.MgCYWv, BiVXXH);
   return SpZzeQ;
}

parser Byuchi {
   extract( PeankK );
   return ingress;
}

parser MwcfQZ {
   extract( dnOwUx );
   return ingress;
}

parser SpZzeQ {
   extract( ejedVK );
   return select( ejedVK.NdTFbZ ) {
      kXjmSR: Byuchi;
      YwtPQr: MwcfQZ;
      default: ingress;
   }
}
#endif

#ifndef VAG_FIX
@pragma pa_atomic ingress QtOVAv.CITpsH
#endif
metadata hDYMcY CNpgHg;
metadata dOnQOY qVEGeY;
metadata GSCxzi lwmijB;
metadata ovbffT oXjFaB;
metadata RFsRYU ppHepP;
metadata dWoWnP njBqBq;
metadata vCHZaQ nMhNWt;
metadata WebmrG vgJNjT;
metadata uESsmr oApvsj;
metadata MyPNUO QtOVAv;




#ifndef USE_CUSTOMERS_PRAGMA
@pragma pa_solitary ingress CNpgHg.dnnZBE
@pragma pa_solitary ingress CNpgHg.fxaceD
@pragma pa_solitary ingress CNpgHg.aaxKVh
@pragma pa_solitary egress qVEGeY.dEpCpX
@pragma pa_solitary ig_intr_md_for_tm.ucast_egress_port
#endif



#ifndef NznMZA
#define NznMZA

action fZBoEc() {
   no_op();
}

#endif

















#define PImJfM 288

action IkihAY(VRfGMf, aWJnNz, kAhNUQ, FSkdgG, EpRMew, eMDkVu) {
    modify_field(lwmijB.bBdRYe, VRfGMf);
    modify_field(lwmijB.OkmIdf, aWJnNz);
    modify_field(lwmijB.tcpbrh, kAhNUQ);
    modify_field(lwmijB.FfnVoF, FSkdgG);
    modify_field(lwmijB.lxSpki, EpRMew);
    modify_field(lwmijB.qDdnCn, eMDkVu);
}

@pragma command_line --no-dead-code-elimination
table zzWDfo {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        IkihAY;
    }
    size : PImJfM;
}

control TqpEwo {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(zzWDfo);
    }
}





#define IcDJoT 512
#define RLOSub 512


action DUUneG(VpiBlj) {
   modify_field( qVEGeY.AKktqJ, 1 );
   modify_field( qVEGeY.fRkpZh, VpiBlj);
   modify_field( CNpgHg.zKEdLf, 1 );
}

action ZVjDGe() {
   modify_field( CNpgHg.eSTwIB, 1 );
   modify_field( CNpgHg.meaTlr, 1 );
}

action cgbneL() {
   modify_field( CNpgHg.zKEdLf, 1 );
}

action UKNpAR() {
   modify_field( CNpgHg.seCsYb, 1 );
}

action lUnhrD() {
   modify_field( CNpgHg.meaTlr, 1 );
}


table guDPFX {
   reads {
      hPVgfz.nfyWUz : ternary;
      hPVgfz.bbJqjF : ternary;
   }

   actions {
      DUUneG;
      ZVjDGe;
      cgbneL;
      UKNpAR;
      lUnhrD;
   }
   default_action : lUnhrD;
   size : IcDJoT;
}

action NYgpqR() {
   modify_field( CNpgHg.NmVHqk, 1 );
}


table euoOxW {
   reads {
      hPVgfz.guzLDR : ternary;
      hPVgfz.JAADXJ : ternary;
   }

   actions {
      NYgpqR;
   }
   size : RLOSub;
}


control kwNOmT {
   apply( guDPFX );
   apply( euoOxW );
}




#define FMyhuw 1024
#define mUhrEg 4096
#define jUUTvg 4096
#define YeqhrY 4096
#define oyvNFO 4096
#define IIDeni 1024
#define qFuYOV 4096

action qONwrn() {
   modify_field( oXjFaB.SvjLjO, PeankK.nEWzFM );
   modify_field( oXjFaB.yFhASD, PeankK.QGkiWU );
   modify_field( oXjFaB.yjYXse, PeankK.KgxBJD );
   modify_field( ppHepP.IFaKfC, dnOwUx.arsNZE );
   modify_field( ppHepP.tLRngq, dnOwUx.qwzuBO );
   modify_field( ppHepP.GxriLE, dnOwUx.VYSInC );
   modify_field( CNpgHg.ZlKTpC, ejedVK.nfyWUz );
   modify_field( CNpgHg.XULmvX, ejedVK.bbJqjF );
   modify_field( CNpgHg.lDRqij, ejedVK.guzLDR );
   modify_field( CNpgHg.gzTogt, ejedVK.JAADXJ );
   modify_field( CNpgHg.geSdkA, ejedVK.NdTFbZ );
}

action MdZFPU() {
   modify_field( CNpgHg.MgCYWv, eIUTBA );
   modify_field( oXjFaB.SvjLjO, oADQdp.nEWzFM );
   modify_field( oXjFaB.yFhASD, oADQdp.QGkiWU );
   modify_field( oXjFaB.yjYXse, oADQdp.KgxBJD );
   modify_field( ppHepP.IFaKfC, CsNnAq.arsNZE );
   modify_field( ppHepP.tLRngq, CsNnAq.qwzuBO );
   modify_field( ppHepP.GxriLE, dnOwUx.VYSInC );
   modify_field( CNpgHg.ZlKTpC, hPVgfz.nfyWUz );
   modify_field( CNpgHg.XULmvX, hPVgfz.bbJqjF );
   modify_field( CNpgHg.lDRqij, hPVgfz.guzLDR );
   modify_field( CNpgHg.gzTogt, hPVgfz.JAADXJ );
   modify_field( CNpgHg.geSdkA, hPVgfz.NdTFbZ );
}

table gfxvdU {
   reads {
      hPVgfz.nfyWUz : exact;
      hPVgfz.bbJqjF : exact;
      oADQdp.QGkiWU : exact;
      CNpgHg.MgCYWv : exact;
   }

   actions {
      qONwrn;
      MdZFPU;
   }

   default_action : MdZFPU();
   size : FMyhuw;
}


action fpAigj() {
   modify_field( CNpgHg.dnnZBE, lwmijB.tcpbrh );
   modify_field( CNpgHg.fxaceD, lwmijB.bBdRYe);
}

action tFgIpj( Ynkhsk ) {
   modify_field( CNpgHg.dnnZBE, Ynkhsk );
   modify_field( CNpgHg.fxaceD, lwmijB.bBdRYe);
}

action SFVXKy() {
   modify_field( CNpgHg.dnnZBE, UsqKHW[0].SdLIvH );
   modify_field( CNpgHg.fxaceD, lwmijB.bBdRYe);
}

table vlQbRS {
   reads {
      lwmijB.bBdRYe : ternary;
      UsqKHW[0] : valid;
      UsqKHW[0].SdLIvH : ternary;
   }

   actions {
      fpAigj;
      tFgIpj;
      SFVXKy;
   }
   size : YeqhrY;
}

action WGxCgW( qgRnck ) {
   modify_field( CNpgHg.fxaceD, qgRnck );
}

action LhuFvL() {

   modify_field( CNpgHg.Btudba, 1 );
   modify_field( vgJNjT.JyxaUo,
                 vSgrnT );
}

table vgzaDx {
   reads {
      oADQdp.nEWzFM : exact;
   }

   actions {
      WGxCgW;
      LhuFvL;
   }
   default_action : LhuFvL;
   size : jUUTvg;
}

action lzojiV( IvYWrs, XwmujG, qhxYiM, vwUTCp, dicZWz,
                        pZccxr, rWGDEc ) {
   modify_field( CNpgHg.dnnZBE, IvYWrs );
   modify_field( CNpgHg.mdIJff, rWGDEc );
   etCpVN(XwmujG, qhxYiM, vwUTCp, dicZWz,
                        pZccxr );
}

action uUiHdB() {
   modify_field( CNpgHg.FlyOGN, 1 );
   modify_field( CNpgHg.voVGgH, 1 );
}

table CIttvG {
   reads {
      cIWcqc.buAbKG : exact;
   }

   actions {
      lzojiV;
      uUiHdB;
   }
   size : mUhrEg;
}

action etCpVN(XwmujG, qhxYiM, vwUTCp, dicZWz,
                        pZccxr ) {
   modify_field( nMhNWt.RimUZY, XwmujG );
   modify_field( nMhNWt.ScSsrg, qhxYiM );
   modify_field( nMhNWt.RjOOdv, vwUTCp );
   modify_field( nMhNWt.idBWft, dicZWz );
   modify_field( nMhNWt.huBqJa, pZccxr );
}

action McEcoJ(XwmujG, qhxYiM, vwUTCp, dicZWz,
                        pZccxr ) {
   modify_field( CNpgHg.aaxKVh, lwmijB.tcpbrh );
   modify_field( CNpgHg.mdIJff, 1 );
   etCpVN(XwmujG, qhxYiM, vwUTCp, dicZWz,
                        pZccxr );
}

action POTaQj(hqgSEi, XwmujG, qhxYiM, vwUTCp,
                        dicZWz, pZccxr ) {
   modify_field( CNpgHg.aaxKVh, hqgSEi );
   modify_field( CNpgHg.mdIJff, 1 );
   etCpVN(XwmujG, qhxYiM, vwUTCp, dicZWz,
                        pZccxr );
}

action bcHInK(XwmujG, qhxYiM, vwUTCp, dicZWz,
                        pZccxr ) {
   modify_field( CNpgHg.aaxKVh, UsqKHW[0].SdLIvH );
   modify_field( CNpgHg.mdIJff, 1 );
   etCpVN(XwmujG, qhxYiM, vwUTCp, dicZWz,
                        pZccxr );
}

table ELJoBl {
   reads {
      lwmijB.tcpbrh : exact;
   }

   actions {
      McEcoJ;
   }

   size : oyvNFO;
}

table ZwyoWc {
   reads {
      lwmijB.bBdRYe : exact;
      UsqKHW[0].SdLIvH : exact;
   }

   actions {
      POTaQj;
      fZBoEc;
   }
   default_action : fZBoEc;

   size : IIDeni;
}

table yskDBG {
   reads {
      UsqKHW[0].SdLIvH : exact;
   }

   actions {
      bcHInK;
   }

   size : qFuYOV;
}

control OqQwzQ {
   apply( gfxvdU ) {
         qONwrn {
            apply( vgzaDx );
            apply( CIttvG );
         }
         MdZFPU {
            if ( lwmijB.FfnVoF == 1 ) {
               apply( vlQbRS );
            }
            if ( valid( UsqKHW[ 0 ] ) ) {

               apply( ZwyoWc ) {
                  fZBoEc {

                     apply( yskDBG );
                  }
               }
            } else {

               apply( ELJoBl );
            }
         }
   }
}





#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register yevXhQ {
    width  : 1;
    static : xxBEJN;
    instance_count : 262144;
}

register GBdGiH {
    width  : 1;
    static : hrghfe;
    instance_count : 262144;
}

blackbox stateful_alu vOaDPT {
    reg : yevXhQ;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : njBqBq.sRUjfg;
}

blackbox stateful_alu fcVprY {
    reg : GBdGiH;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : njBqBq.ymFIux;
}

field_list TaVhut {
    lwmijB.qDdnCn;
    UsqKHW[0].SdLIvH;
}

field_list_calculation HtqUfZ {
    input { TaVhut; }
    algorithm: identity;
    output_width: 18;
}

action EAmgXn() {
    vOaDPT.execute_stateful_alu_from_hash(HtqUfZ);
}

action HWMlwq() {
    fcVprY.execute_stateful_alu_from_hash(HtqUfZ);
}

table xxBEJN {
    actions {
      EAmgXn;
    }
    default_action : EAmgXn;
    size : 1;
}

table hrghfe {
    actions {
      HWMlwq;
    }
    default_action : HWMlwq;
    size : 1;
}
#endif

action vyNWot(UZQlMJ) {
    modify_field(njBqBq.ymFIux, UZQlMJ);
}

@pragma  use_hash_action 0
table bCqvnV {
    reads {
       lwmijB.qDdnCn : exact;
    }
    actions {
      vyNWot;
    }
    size : 64;
}

action DUeAUO() {
   modify_field( CNpgHg.PlNxwi, lwmijB.tcpbrh );
   modify_field( CNpgHg.GERUGL, 0 );
}

table RtCbvi {
   actions {
      DUeAUO;
   }
   size : 1;
}

action VslHWa() {
   modify_field( CNpgHg.PlNxwi, UsqKHW[0].SdLIvH );
   modify_field( CNpgHg.GERUGL, 1 );
}

table Qfopml {
   actions {
      VslHWa;
   }
   size : 1;
}

control TDPRYG {
   if ( valid( UsqKHW[ 0 ] ) ) {
      apply( Qfopml );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( lwmijB.lxSpki == 1 ) {
         apply( xxBEJN );
         apply( hrghfe );
      }
#endif
   } else {
      apply( RtCbvi );
      if( lwmijB.lxSpki == 1 ) {
         apply( bCqvnV );
      }
   }
}




#define TQPQDx     256

field_list HgzZIu {
   hPVgfz.nfyWUz;
   hPVgfz.bbJqjF;
   hPVgfz.guzLDR;
   hPVgfz.JAADXJ;
   hPVgfz.NdTFbZ;
}

field_list xkUHWD {
   oADQdp.nEWzFM;
   oADQdp.QGkiWU;
   oADQdp.KgxBJD;
}

field_list XlFySq {
   CsNnAq.arsNZE;
   CsNnAq.qwzuBO;
   CsNnAq.VYSInC;
   CsNnAq.yPebTa;
}





field_list_calculation UdsKpp {
    input {
        HgzZIu;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation MMiAzF {
    input {
        xkUHWD;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation mmhLpM {
    input {
        XlFySq;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action JmGdzx() {


}

action dBFylv() {
    modify_field_with_hash_based_offset(QtOVAv.CITpsH, 0,
                                        MMiAzF, 4294967296);
}

table jHooyJ {
   reads {
      bsPHav.valid : ternary;
      ubDSaI.valid : ternary;
      PeankK.valid : ternary;
      dnOwUx.valid : ternary;
      ejedVK.valid : ternary;
      pkBpIo.valid : ternary;
      fpKWAU.valid : ternary;
      oADQdp.valid : ternary;
      CsNnAq.valid : ternary;
      hPVgfz.valid : ternary;
   }
   actions {
      JmGdzx;
      dBFylv;
      fZBoEc;
   }
   default_action : fZBoEc();
   size: TQPQDx;
}

control OOyMfT {
   apply(jHooyJ);
}



#define uUuYjH 512

action SrTgya() {
   modify_field( nMhNWt.MRBoTh, 1 );
}

table kOJGmo {
   reads {
      CNpgHg.aaxKVh : ternary;
      CNpgHg.ZlKTpC : exact;
      CNpgHg.XULmvX : exact;
   }
   actions {
      SrTgya;
   }
   size: uUuYjH;
}

control DRWcKf {
   if( CNpgHg.FlyOGN == 0 and CNpgHg.voVGgH == 0 ) {
      apply( kOJGmo );
   }
}



#define ALqGfo      65536

register QUINJI {
   width: 1;
   static: klyAMJ;
   instance_count: ALqGfo;
}

#ifdef __TARGET_TOFINO__
blackbox stateful_alu tOUEnP{
    reg: QUINJI;
    update_lo_1_value: set_bit;
}
#endif

action DURXNj(rEXFwh) {
#if defined(BMV2) || defined(BMV2TOFINO)
   register_write(QUINJI, rEXFwh, 1);
#else
   tOUEnP.execute_stateful_alu();
#endif

}

action rCZnqI() {

   modify_field(CNpgHg.YpkCXt, 1 );
   modify_field(vgJNjT.JyxaUo,
                pqKlnv);
}

table klyAMJ {
   reads {
      CNpgHg.lDRqij : exact;
      CNpgHg.gzTogt : exact;
      CNpgHg.dnnZBE : exact;
      CNpgHg.fxaceD : exact;
   }

   actions {
      DURXNj;
      rCZnqI;
   }
   size : ALqGfo;
}

control IFycyA {




   if (lwmijB.OkmIdf == 0 and CNpgHg.Btudba == 0) {
      apply( klyAMJ );
   }
}

field_list AUuPrb {
    vgJNjT.JyxaUo;
    CNpgHg.lDRqij;
    CNpgHg.gzTogt;
    CNpgHg.dnnZBE;
    CNpgHg.fxaceD;
}

action iVIxCi() {
   generate_digest(OotCJI, AUuPrb);
}

table refzuV {
   actions {
      iVIxCi;
   }
   size : 1;
}

control wdEtSP {
   if (CNpgHg.YpkCXt == 1) {
      apply( refzuV );
   }
}


#define zandcl 65536
#define yCRUyc 65536
#define GHHlZH   16384
#define aiUcqi         131072
#define tlHLwK 65536

action EHLJVB(BUuMSS) {
   modify_field(oXjFaB.vHIEVR, BUuMSS);
}

table IOmUKW {
   reads {
      nMhNWt.RimUZY : exact;
      oXjFaB.yFhASD : lpm;
   }

   actions {
      EHLJVB;
   }

   size : GHHlZH;
}

@pragma atcam_partition_index oXjFaB.vHIEVR
@pragma atcam_number_partitions GHHlZH
table ziyvxD {
   reads {
      oXjFaB.vHIEVR : exact;



      oXjFaB.yFhASD mask 0x000fffff : lpm;
   }
   actions {
      iVAeyg;
      fZBoEc;
   }
   default_action : fZBoEc();
   size : aiUcqi;
}

action iVAeyg( HSkUHN ) {
   modify_field( qVEGeY.BxqzOJ, 1 );
   modify_field( oApvsj.KbmtfM, HSkUHN );
}

@pragma idletime_precision 1
table MFQRLD {
   reads {
      nMhNWt.RimUZY : exact;
      oXjFaB.yFhASD : exact;
   }

   actions {
      iVAeyg;
      fZBoEc;
   }
   default_action : fZBoEc();
   size : zandcl;
   support_timeout : true;
}

@pragma idletime_precision 1
table rsKFxA {
   reads {
      nMhNWt.RimUZY : exact;
      ppHepP.tLRngq : exact;
   }

   actions {
      iVAeyg;
      fZBoEc;
   }
   default_action : fZBoEc();
   size : yCRUyc;
   support_timeout : true;
}

action CXnwJk(ZxoCfq, lyJWmW, vLHyfd) {
   modify_field(qVEGeY.yWiZak, vLHyfd);
   modify_field(qVEGeY.XtjQOt, ZxoCfq);
   modify_field(qVEGeY.phNuMP, lyJWmW);
   modify_field(qVEGeY.BxqzOJ, 1);
}

table WjWSjo {
   reads {
      oApvsj.KbmtfM : exact;
   }

   actions {
      CXnwJk;
   }
   size : tlHLwK;
}

control vNcJYp {




   if ( njBqBq.sRUjfg == 0 and
        njBqBq.ymFIux == 0 and
        CNpgHg.FlyOGN == 0 and nMhNWt.MRBoTh == 1 ) {
      if ( ( nMhNWt.ScSsrg == 1 ) and
           ( ( CNpgHg.MgCYWv == eIUTBA and valid( oADQdp ) ) or
             ( CNpgHg.MgCYWv != eIUTBA and valid( PeankK ) ) ) ) {
         apply( MFQRLD ) {
            fZBoEc {
               apply( IOmUKW );
               if( oXjFaB.vHIEVR != 0 ) {
                  apply( ziyvxD );
               }
            }
         }
      } else if ( ( nMhNWt.RjOOdv == 1 ) and
            ( CNpgHg.MgCYWv == eIUTBA and valid( CsNnAq ) ) or
             ( CNpgHg.MgCYWv != eIUTBA and valid( dnOwUx ) ) ) {
         apply( rsKFxA );
      }
   }
}

control pBYOhi {
   if( oApvsj.KbmtfM != 0 ) {
      apply( WjWSjo );
   }
}



#define QDPbya     1024
#define AXXVOi    1024

#define gPcHSo
#define ZLhImn

field_list fqaSBr {
   QtOVAv.CITpsH;
}

field_list_calculation EpXgxd {
    input {
        fqaSBr;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector mVdeCf {
    selection_key : EpXgxd;
    selection_mode : resilient;
}

action kApMGq(KsjRHh) {
   modify_field(qVEGeY.FJaMhx, KsjRHh);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, KsjRHh);
}

action_profile JjjNMB {
    actions {
        kApMGq;
        fZBoEc;
    }
    size : AXXVOi;
    dynamic_action_selection : mVdeCf;
}

table lANHpg {
   reads {
      qVEGeY.FJaMhx : exact;
   }
   action_profile: JjjNMB;
   size : QDPbya;
}

control fVGlMw {
   if ((qVEGeY.FJaMhx & 0x2000) == 0x2000) {
      apply(lANHpg);
   }
}



#define LKleou      65536

action wdoLrj() {
   modify_field(qVEGeY.XtjQOt, CNpgHg.ZlKTpC);
   modify_field(qVEGeY.phNuMP, CNpgHg.XULmvX);
   modify_field(qVEGeY.uQqZem, CNpgHg.lDRqij);
   modify_field(qVEGeY.cOTGpW, CNpgHg.gzTogt);
   modify_field(qVEGeY.yWiZak, CNpgHg.dnnZBE);
}

table VcjJab {
   actions {
      wdoLrj;
   }
   default_action : wdoLrj();
   size : 1;
}

control FmfddY {
   if (CNpgHg.dnnZBE!=0) {
      apply( VcjJab );
   }
}

action STksvi() {
   modify_field(qVEGeY.NMjfEN, 1);
   modify_field(qVEGeY.tlxjBI, 1);
   modify_field(qVEGeY.dEpCpX, qVEGeY.yWiZak);
}

action QEckLK() {
}



@pragma ways 1
table xiJqBR {
   reads {
      qVEGeY.XtjQOt : exact;
      qVEGeY.phNuMP : exact;
   }
   actions {
      STksvi;
      QEckLK;
   }
   default_action : QEckLK;
   size : 1;
}

action BFbukt() {
   modify_field(qVEGeY.jYwTiv, 1);
   modify_field(qVEGeY.FbZPCV, 1);
   add(qVEGeY.dEpCpX, qVEGeY.yWiZak, AtxDUe);
}

table fagWRM {
   actions {
      BFbukt;
   }
   default_action : BFbukt;
   size : 1;
}

action hRNvDZ() {
   modify_field(qVEGeY.OxaBzh, 1);
   modify_field(qVEGeY.dEpCpX, qVEGeY.yWiZak);
}

table uuDtAx {
   actions {
      hRNvDZ;
   }
   default_action : hRNvDZ();
   size : 1;
}

action qXnTNQ(cWSgQP) {
   modify_field(qVEGeY.MxCNHk, 1);
   modify_field(qVEGeY.FJaMhx, cWSgQP);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, cWSgQP);
}

action dpNFDa(qnbxcf) {
   modify_field(qVEGeY.jYwTiv, 1);
   modify_field(qVEGeY.dEpCpX, qnbxcf);
}

action IBmwsU() {
}

table jqEBtN {
   reads {
      qVEGeY.XtjQOt : exact;
      qVEGeY.phNuMP : exact;
      qVEGeY.yWiZak : exact;
   }

   actions {
      qXnTNQ;
      dpNFDa;
      IBmwsU;
   }
   default_action : IBmwsU();
   size : LKleou;
}

control lrVCTN {
   if (CNpgHg.FlyOGN == 0) {
      apply(jqEBtN) {
         IBmwsU {
            apply(xiJqBR) {
               QEckLK {
                  if ((qVEGeY.XtjQOt & 0x010000) == 0x010000) {
                     apply(fagWRM);
                  } else {
                     apply(uuDtAx);
                  }
               }
            }
         }
      }
   }
}


action aTKBjx() {
   modify_field(CNpgHg.FlyOGN, 1);
}

table OSjRGs {
   actions {
      aTKBjx;
   }
   default_action : aTKBjx();
   size : 1;
}

control ZCtaqW {
   if ((qVEGeY.BxqzOJ==0) and (CNpgHg.fxaceD==qVEGeY.FJaMhx)) {
      apply(OSjRGs);
   }
}


#ifndef iNdJLL
#define iNdJLL

#define JtsGKB    4096

action spcFKl( OkndKI ) {
   modify_field( qVEGeY.Crnury, OkndKI );
}

action toVrDX() {
   modify_field( qVEGeY.Crnury, qVEGeY.yWiZak );
}

table WuVBUa {
   reads {
      eg_intr_md.egress_port : exact;
      qVEGeY.yWiZak : exact;
   }

   actions {
      spcFKl;
      toVrDX;
   }
   default_action : toVrDX;
   size : JtsGKB;
}

control GDDPzq {
   apply( WuVBUa );
}

#endif


#ifndef yAmMrV
#define yAmMrV

#define QdomPO 64
#define slcyZJ 1
#define RUGtHP  8
#define sOrAIY 512

#define UGtlPn 0

action ubSaie( hruSYJ, iAFgWr ) {
   modify_field( qVEGeY.bOrlpX, hruSYJ );
   modify_field( qVEGeY.kHuqpQ, iAFgWr );
}


table iEpLff {
   reads {
      qVEGeY.WQEcHW : exact;
   }

   actions {
      ubSaie;
   }
   size : RUGtHP;
}

action XVCKqI() {
   no_op();
}

action ldJuOq() {
   modify_field( hPVgfz.NdTFbZ, UsqKHW[0].nHmyTr );
   remove_header( UsqKHW[0] );
}

table mimuTA {
   actions {
      ldJuOq;
   }
   default_action : ldJuOq;
   size : slcyZJ;
}

action cbdcsG() {
   no_op();
}

action qTumUl() {
   add_header( UsqKHW[ 0 ] );
   modify_field( UsqKHW[0].SdLIvH, qVEGeY.Crnury );
   modify_field( UsqKHW[0].nHmyTr, hPVgfz.NdTFbZ );
   modify_field( hPVgfz.NdTFbZ, uYDOJd );
}



table nGyKoM {
   reads {
      qVEGeY.Crnury : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      cbdcsG;
      qTumUl;
   }
   default_action : qTumUl;
   size : QdomPO;
}

action DKhYPD() {
   modify_field(hPVgfz.nfyWUz, qVEGeY.XtjQOt);
   modify_field(hPVgfz.bbJqjF, qVEGeY.phNuMP);
   modify_field(hPVgfz.guzLDR, qVEGeY.bOrlpX);
   modify_field(hPVgfz.JAADXJ, qVEGeY.kHuqpQ);
}

action Wrgnar() {
   DKhYPD();
   add_to_field(oADQdp.YiOJqy, -1);
}

action bWkoUs() {
   DKhYPD();
   add_to_field(CsNnAq.zjHDzN, -1);
}






@pragma stage 2
table UtKtsI {
   reads {
      qVEGeY.hGsdpN : exact;
      qVEGeY.WQEcHW : exact;
      qVEGeY.BxqzOJ : exact;
      oADQdp.valid : ternary;
      CsNnAq.valid : ternary;
   }

   actions {
      Wrgnar;
      bWkoUs;
   }
   size : sOrAIY;
}

control aOROgW {
   apply( mimuTA );
}

control skLrFB {
   apply( nGyKoM );
}

control bUHekb {
   apply( iEpLff );
   apply( UtKtsI );
}
#endif



field_list MseOOc {
    vgJNjT.JyxaUo;
    CNpgHg.dnnZBE;
    ejedVK.guzLDR;
    ejedVK.JAADXJ;
    oADQdp.nEWzFM;
}

action nquBLx() {
   generate_digest(OotCJI, MseOOc);
}

table keYVCs {
   actions {
      nquBLx;
   }

   default_action : nquBLx;
   size : 1;
}

control HpHSVC {
   if (CNpgHg.Btudba == 1) {
      apply(keYVCs);
   }
}

control ingress {
   TqpEwo();

   kwNOmT();
   OqQwzQ();
   TDPRYG();

   IFycyA();
   DRWcKf();


   vNcJYp();
   FmfddY();
   pBYOhi();

   OOyMfT();


   lrVCTN();

   ZCtaqW();


   fVGlMw();


   HpHSVC();
   wdEtSP();


   if( valid( UsqKHW[0] ) ) {
      aOROgW();
   }
}

control egress {
   GDDPzq();
   bUHekb();
   skLrFB();
}

