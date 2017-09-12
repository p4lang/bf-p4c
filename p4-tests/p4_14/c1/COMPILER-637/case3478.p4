// ver: 5.0.1 (f2fac13)
// BUILD: p4c-tofino --verbose 3 --placement tp4 --no-dead-code-elimination --o bf_arista_switch_default_obfuscated/ --p4-name=arista_switch --p4-prefix=p4_arista_switch --pipe-mgr-path=pipe_mgr/ --mc-mgr-path=mc_mgr/ -S -DPROFILE_DEFAULT --parser-timing-reports --print-pa-constraints  bf_arista_switch_default_obfuscated/Switch.OBFUSCATED.p4 


// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 70751

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
header_type Aspetuck {
	fields {
		Norco : 16;
		Monkstown : 16;
		Mishawaka : 8;
		Bladen : 8;
		Milano : 8;
		EastLake : 8;
		Morrow : 2;
		WestGate : 2;
		Piketon : 1;
		Klawock : 3;
		Poplar : 3;
	}
}
header_type Yocemento {
	fields {
		Kelvin : 24;
		Lampasas : 24;
		Veteran : 24;
		Kingsland : 24;
		Calvary : 16;
		Roswell : 12;
		Hargis : 16;
		Joshua : 16;
		Linville : 16;
		Hagewood : 8;
		Tinaja : 8;
		BlueAsh : 1;
		Domestic : 1;
		Pinecrest : 3;
		Ikatan : 2;
		Billett : 1;
		Ackley : 1;
		Reager : 1;
		Mossville : 1;
		Margie : 1;
		Rocky : 1;
		Gosnell : 1;
		Kurten : 1;
		Litroe : 1;
		Castle : 1;
		Thayne : 1;
		Greenwood : 1;
		Aldrich : 16;
		OakCity : 16;
		Wanilla : 8;
	}
}
header_type Golden {
	fields {
		Westvaco : 24;
		Stone : 24;
		Addison : 24;
		Barney : 24;
		Tallevast : 24;
		Beresford : 24;
		Manteo : 1;
		Goldenrod : 3;
		LaVale : 1;
		TonkaBay : 12;
		Seguin : 16;
		Blackwood : 16;
		Glassboro : 16;
		Nephi : 12;
		Servia : 3;
		Virgilina : 1;
		Korbel : 1;
		Friend : 1;
		Houston : 1;
		Elvaston : 1;
		Destin : 8;
		Millstadt : 12;
		Whitefish : 4;
		Neosho : 6;
		Aylmer : 10;
		Calamine : 24;
		Navarro : 32;
		Angwin : 9;
		Calamus : 2;
		Snowball : 1;
		Donald : 1;
		Kathleen : 1;
		Etter : 1;
		Varnado : 1;
		Colona : 32;
		Oreland : 12;
		Brave : 1;
		Champlin : 1;
		Maryville : 8;
		Tampa : 8;
		Kittredge : 16;
		Pickett : 32;
		Doddridge : 32;
		Cascadia : 8;
		Nordland : 24;
		Lowes : 24;
		Belvue : 18;
		Hackett : 6;
		Picabo : 16;
		Valsetz : 4;
		Berrydale : 4;
	}
}
header_type Hauppauge {
	fields {
		Amber : 16;
		Gerster : 16;
		Tavistock : 7;
		Plano : 2;
		Congress : 10;
		Petrey : 10;
	}
}
header_type Hampton {
	fields {
		Havana : 7;
		Yantis : 2;
		Kewanee : 10;
		Sherwin : 10;
	}
}
header_type Millett {
	fields {
		Gravette : 8;
		LoneJack : 4;
		Dietrich : 1;
	}
}
header_type CatCreek {
	fields {
		Alameda : 32;
		Commack : 32;
		Revere : 6;
		Farlin : 16;
	}
}
header_type Eustis {
	fields {
		Dollar : 128;
		Cloverly : 128;
		Longwood : 20;
		Newkirk : 8;
		Pevely : 11;
		Berlin : 6;
		Kalvesta : 13;
	}
}
header_type Keachi {
	fields {
		Gerlach : 14;
		Mattawan : 1;
		SanJuan : 12;
		Colstrip : 1;
		Stella : 1;
	}
}
header_type CapeFair {
	fields {
		Scissors : 1;
		Hiseville : 1;
	}
}
header_type Atlas {
	fields {
		Prunedale : 8;
	}
}
header_type Cowell {
	fields {
		McAdoo : 16;
		Mogadore : 11;
	}
}
header_type Forbes {
	fields {
		OldGlory : 32;
		Millport : 32;
		Kerrville : 32;
	}
}
header_type Decherd {
	fields {
		Ludell : 32;
		Mancelona : 32;
	}
}
header_type Sudbury {
	fields {
		Laclede : 2;
		Elmont : 6;
		Purley : 3;
		Onycha : 1;
		Olivet : 1;
		LaPuente : 1;
		Wyocena : 3;
		Tecolote : 1;
		Ripley : 6;
		Lurton : 4;
		Cimarron : 5;
	}
}
header_type Hiland {
	fields {
		Shivwits : 16;
	}
}
header_type NewRoads {
	fields {
		Sublimity : 14;
		Gully : 1;
		Vincent : 1;
	}
}
header_type Ickesburg {
	fields {
		Gibsland : 14;
		Desdemona : 1;
		Bethania : 1;
	}
}
header_type Temple {
	fields {
		Hallwood : 16;
		Wyncote : 16;
		Deerwood : 16;
		Emerado : 16;
		Allen : 16;
		Ontonagon : 16;
		Punaluu : 8;
		Hiawassee : 8;
		Point : 8;
		Hobergs : 8;
		Wamesit : 1;
		Tindall : 6;
	}
}
header_type Disney {
	fields {
		Mullins : 32;
	}
}
header_type Markesan {
	fields {
		Quarry : 6;
		Loogootee : 10;
		Lowden : 4;
		Separ : 12;
		Nettleton : 2;
		Vanzant : 2;
		Westoak : 12;
		Thomas : 8;
		Lafourche : 3;
		Sallisaw : 4;
		Freeman : 1;
	}
}
header_type Weimar {
	fields {
		Minoa : 24;
		Grigston : 24;
		Kosmos : 24;
		Palisades : 24;
		Whitten : 16;
	}
}
header_type Wright {
	fields {
		Westway : 3;
		Ayden : 1;
		Yorkville : 12;
		Puryear : 16;
	}
}
header_type McCleary {
	fields {
		Piperton : 4;
		Nelagoney : 4;
		Fragaria : 6;
		Baldwin : 2;
		Vallecito : 16;
		Jelloway : 16;
		Sonoma : 3;
		Rochert : 13;
		Neame : 8;
		BigArm : 8;
		Gaston : 16;
		Daysville : 32;
		ElMirage : 32;
	}
}
header_type Broadwell {
	fields {
		Bledsoe : 4;
		Mabel : 6;
		HydePark : 2;
		Leola : 20;
		Honuapo : 16;
		Waldport : 8;
		Hydaburg : 8;
		Humble : 128;
		Rumson : 128;
	}
}
header_type Trego {
	fields {
		Thaxton : 8;
		Bluff : 8;
		Fries : 16;
	}
}
header_type Catawissa {
	fields {
		Tontogany : 16;
		Ashwood : 16;
	}
}
header_type Century {
	fields {
		Ketchum : 32;
		Supai : 32;
		Alzada : 4;
		Firesteel : 4;
		Westbury : 8;
		PineCity : 16;
		Dabney : 16;
		Finlayson : 16;
	}
}
header_type Burmah {
	fields {
		Cruso : 16;
		Branson : 16;
	}
}
header_type Lonepine {
	fields {
		Masardis : 16;
		Wewela : 16;
		Salamatof : 8;
		Madeira : 8;
		Fordyce : 16;
	}
}
header_type Wanamassa {
	fields {
		Alvwood : 48;
		Nashua : 32;
		Marie : 48;
		RioLajas : 32;
	}
}
header_type Fieldon {
	fields {
		Panola : 1;
		Cacao : 1;
		Kaanapali : 1;
		Ballville : 1;
		Dickson : 1;
		Lynch : 3;
		Onawa : 5;
		Dizney : 3;
		Slater : 16;
	}
}
header_type Saluda {
	fields {
		Bergoo : 24;
		Luttrell : 8;
	}
}
header_type Trevorton {
	fields {
		Elkins : 8;
		Engle : 24;
		Ammon : 24;
		Littleton : 8;
	}
}
header Weimar Sherrill;
header Weimar Pinesdale;
header Wright Nicodemus[ 2 ];
@pragma pa_fragment ingress Woodfield.Gaston
@pragma pa_fragment egress Woodfield.Gaston
header McCleary Woodfield;
@pragma pa_fragment ingress Magazine.Gaston
@pragma pa_fragment egress Magazine.Gaston
header McCleary Magazine;
header Broadwell Glyndon;
header Broadwell WestPike;
header Catawissa Heflin;
header Catawissa Anthon;
header Century Benitez;
header Burmah Pinto;
header Century Verbena;
header Burmah Vevay;
header Trevorton Wimbledon;
header Fieldon Belmond;
header Markesan Currie;
header Weimar Iberia;
parser start {
   return select(current(96, 16)) {
      0xBF00 : Manilla;
      default : Calcasieu;
   }
}
parser Rocklake {
   extract( Currie );
   return Calcasieu;
}
parser Manilla {
   extract( Iberia );
   return Rocklake;
}
parser Calcasieu {
   extract( Sherrill );
   return select( Sherrill.Whitten ) {
      0x8100 : Bonilla;
      0x0800 : Higgston;
      0x86dd : Ferndale;
      default : ingress;
   }
}
parser Bonilla {
   extract( Nicodemus[0] );
   set_metadata(Conklin.Piketon, 1);
   return select( Nicodemus[0].Puryear ) {
      0x0800 : Higgston;
      0x86dd : Ferndale;
      default : ingress;
   }
}
field_list Center {
    Woodfield.Piperton;
    Woodfield.Nelagoney;
    Woodfield.Fragaria;
    Woodfield.Baldwin;
    Woodfield.Vallecito;
    Woodfield.Jelloway;
    Woodfield.Sonoma;
    Woodfield.Rochert;
    Woodfield.Neame;
    Woodfield.BigArm;
    Woodfield.Daysville;
    Woodfield.ElMirage;
}
field_list_calculation Fairlea {
    input {
        Center;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Woodfield.Gaston {
    verify Fairlea;
    update Fairlea;
}
parser Higgston {
   extract( Woodfield );
   set_metadata(Conklin.Mishawaka, Woodfield.BigArm);
   set_metadata(Conklin.Milano, Woodfield.Neame);
   set_metadata(Conklin.Morrow, 1);
   set_metadata( Holtville.Colona, current(0, 32));
   return select(Woodfield.Rochert, Woodfield.Nelagoney, Woodfield.BigArm) {
      0x501 : Ambrose;
      0x511 : Milam;
      0x506 : Coamo;
      0x52F : McCaulley;
      0 mask 0xFF7000 : ingress;
      0x506 mask 0xfff: Godfrey;
      default : Bannack;
   }
}
parser Godfrey {
   set_metadata(Conklin.Poplar, 5);
   return ingress;
}
parser Bannack {
   set_metadata(Conklin.Poplar, 1);
   return ingress;
}
parser Ferndale {
   extract( WestPike );
   set_metadata(Conklin.Mishawaka, WestPike.Waldport);
   set_metadata(Conklin.Milano, WestPike.Hydaburg);
   set_metadata(Conklin.Morrow, 2);
   return select(WestPike.Waldport) {
      0x3a : Ambrose;
      17 : Crossnore;
      6 : Coamo;
      47 : McCaulley;
      default : ingress;
   }
}
parser Milam {
   set_metadata(Conklin.Poplar, 2);
   extract(Heflin);
   extract(Pinto);
   return select(Heflin.Ashwood) {
      4789 : Grizzly;
      default : ingress;
    }
}
parser Ambrose {
   set_metadata( Heflin.Tontogany, current( 0, 16 ) );
   return ingress;
}
parser Crossnore {
   set_metadata(Conklin.Poplar, 2);
   extract(Heflin);
   extract(Pinto);
   return ingress;
}
parser Coamo {
   set_metadata(Conklin.Poplar, 6);
   extract(Heflin);
   extract(Benitez);
   return ingress;
}
parser Salineno {
   set_metadata(Langlois.Ikatan, 2);
   return Eckman;
}
parser Nederland {
   set_metadata(Langlois.Ikatan, 2);
   return Norias;
}
parser McCaulley {
   extract(Belmond);
   return select(Belmond.Panola, Belmond.Cacao, Belmond.Kaanapali, Belmond.Ballville, Belmond.Dickson,
             Belmond.Lynch, Belmond.Onawa, Belmond.Dizney, Belmond.Slater) {
      0x0800 : Salineno;
      0x86dd : Nederland;
      default : ingress;
   }
}
parser Grizzly {
   extract(Wimbledon);
   set_metadata(Langlois.Ikatan, 1);
   return Gobler;
}
field_list Gordon {
    Magazine.Piperton;
    Magazine.Nelagoney;
    Magazine.Fragaria;
    Magazine.Baldwin;
    Magazine.Vallecito;
    Magazine.Jelloway;
    Magazine.Sonoma;
    Magazine.Rochert;
    Magazine.Neame;
    Magazine.BigArm;
    Magazine.Daysville;
    Magazine.ElMirage;
}
field_list_calculation Arial {
    input {
        Gordon;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Magazine.Gaston {
    verify Arial;
    update Arial;
}
parser Eckman {
   extract( Magazine );
   set_metadata(Conklin.Bladen, Magazine.BigArm);
   set_metadata(Conklin.EastLake, Magazine.Neame);
   set_metadata(Conklin.WestGate, 1);
   set_metadata(Parkville.Alameda, Magazine.Daysville);
   set_metadata(Parkville.Commack, Magazine.ElMirage);
   return select(Magazine.Rochert, Magazine.Nelagoney, Magazine.BigArm) {
      0x501 : Longhurst;
      0x511 : Penzance;
      0x506 : Ivyland;
      0 mask 0xFF7000 : ingress;
      0x506 mask 0xfff: LaPlata;
      default : RedLake;
   }
}
parser LaPlata {
   set_metadata(Conklin.Klawock, 5);
   return ingress;
}
parser RedLake {
   set_metadata(Conklin.Klawock, 1);
   return ingress;
}
parser Norias {
   extract( Glyndon );
   set_metadata(Conklin.Bladen, Glyndon.Waldport);
   set_metadata(Conklin.EastLake, Glyndon.Hydaburg);
   set_metadata(Conklin.Monkstown, Glyndon.Honuapo);
   set_metadata(Conklin.WestGate, 2);
   set_metadata(Humarock.Dollar, Glyndon.Humble);
   set_metadata(Humarock.Cloverly, Glyndon.Rumson);
   return select(Glyndon.Waldport) {
      0x3a : Longhurst;
      17 : Penzance;
      6 : Ivyland;
      default : ingress;
   }
}
parser Longhurst {
   set_metadata( Langlois.Aldrich, current( 0, 16 ) );
   return ingress;
}
parser Penzance {
   set_metadata( Langlois.Aldrich, current( 0, 16 ) );
   set_metadata( Langlois.OakCity, current( 16, 16 ) );
   set_metadata(Conklin.Klawock, 2);
   return ingress;
}
parser Ivyland {
   set_metadata( Langlois.Aldrich, current( 0, 16 ) );
   set_metadata( Langlois.OakCity, current( 16, 16 ) );
   set_metadata( Langlois.Wanilla, current( 104, 8 ) );
   set_metadata(Conklin.Klawock, 6);
   extract(Anthon);
   extract(Verbena);
   return ingress;
}
parser Gobler {
   extract( Pinesdale );
   set_metadata( Langlois.Kelvin, Pinesdale.Minoa );
   set_metadata( Langlois.Lampasas, Pinesdale.Grigston );
   set_metadata( Langlois.Calvary, Pinesdale.Whitten );
   return select( Pinesdale.Whitten ) {
      0x0800: Eckman;
      0x86dd: Norias;
      default: ingress;
   }
}
@pragma pa_no_init ingress Langlois.Kelvin
@pragma pa_no_init ingress Langlois.Lampasas
@pragma pa_no_init ingress Langlois.Veteran
@pragma pa_no_init ingress Langlois.Kingsland
@pragma pa_container_size ingress Langlois.Ikatan 16
metadata Yocemento Langlois;
@pragma pa_no_init ingress Holtville.Westvaco
@pragma pa_no_init ingress Holtville.Stone
@pragma pa_no_init ingress Holtville.Addison
@pragma pa_no_init ingress Holtville.Barney
@pragma pa_do_not_bridge egress Holtville.Colona
@pragma pa_no_overlay ingress Holtville.Snowball Holtville.Brave
metadata Golden Holtville;
metadata Hauppauge Resaca;
metadata Hampton McBrides;
metadata Keachi Madison;
@pragma pa_do_not_bridge egress Conklin.Mishawaka
@pragma pa_container_size ingress Conklin.WestGate 32
@pragma pa_container_size ingress Conklin.Piketon 32
metadata Aspetuck Conklin;
metadata CatCreek Parkville;
@pragma pa_container_size ingress Humarock.Dollar 32
@pragma pa_container_size ingress Humarock.Cloverly 32
metadata Eustis Humarock;
metadata CapeFair Chamois;
@pragma pa_container_size ingress Chamois.Hiseville 32
metadata Millett Maiden;
metadata Atlas Gakona;
metadata Cowell Bushland;
metadata Decherd Chalco;
metadata Forbes Kirwin;
metadata Sudbury Kilbourne;
metadata Hiland Ashley;
@pragma pa_no_init ingress Warsaw.Sublimity
@pragma pa_solitary ingress Warsaw.Vincent
metadata NewRoads Warsaw;
@pragma pa_no_init ingress Bleecker.Gibsland
metadata Ickesburg Bleecker;
@pragma pa_no_init ingress Fennimore.Deerwood
@pragma pa_no_init ingress Fennimore.Emerado
metadata Temple Fennimore;
metadata Temple Hadley;
action Bammel() {
   no_op();
}
action Henrietta() {
   modify_field(Langlois.Billett, 1 );
   mark_for_drop();
}
action Clovis() {
   no_op();
}
action Kelsey(Lakehills, Malesus, Latham, Aguila, Ballwin ) {
    modify_field(Madison.Gerlach, Lakehills);
    modify_field(Madison.Mattawan, Malesus);
    modify_field(Madison.SanJuan, Latham);
    modify_field(Madison.Colstrip, Aguila);
    modify_field(Madison.Stella, Ballwin);
}
@pragma command_line --no-dead-code-elimination
@pragma Madison 1
table Dandridge {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Kelsey;
    }
    size : 288;
}
control Kinard {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Dandridge);
    }
}
action Wyarno(Wailuku, Marquand) {
   modify_field( Holtville.LaVale, 1 );
   modify_field( Holtville.Destin, Wailuku);
   modify_field( Langlois.Gosnell, 1 );
   modify_field( Kilbourne.LaPuente, Marquand );
}
action Menifee() {
   modify_field( Langlois.Mossville, 1 );
   modify_field( Langlois.Litroe, 1 );
}
action Freeny() {
   modify_field( Langlois.Gosnell, 1 );
}
action Neuse() {
   modify_field( Langlois.Gosnell, 1 );
   modify_field( Langlois.Castle, 1 );
}
action Achille() {
   modify_field( Langlois.Kurten, 1 );
}
action Oskaloosa() {
   modify_field( Langlois.Litroe, 1 );
}
counter Mecosta {
   type : packets_and_bytes;
   direct : Greendale;
   min_width: 16;
}
table Greendale {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Sherrill.Minoa : ternary;
      Sherrill.Grigston : ternary;
   }
   actions {
      Wyarno;
      Menifee;
      Freeny;
      Achille;
      Oskaloosa;
      Neuse;
   }
   size : 2048;
}
action Coconino() {
   modify_field( Langlois.Margie, 1 );
}
table Lomax {
   reads {
      Sherrill.Kosmos : ternary;
      Sherrill.Palisades : ternary;
   }
   actions {
      Coconino;
   }
   size : 512;
}
control Curlew {
   apply( Greendale );
   apply( Lomax );
}
action Harlem() {
   modify_field( Parkville.Revere, Magazine.Fragaria );
   modify_field( Humarock.Longwood, Glyndon.Leola );
   modify_field( Humarock.Berlin, Glyndon.Mabel );
   modify_field( Langlois.Veteran, Pinesdale.Kosmos );
   modify_field( Langlois.Kingsland, Pinesdale.Palisades );
   modify_field( Langlois.Linville, Conklin.Monkstown );
   modify_field( Langlois.Hagewood, Conklin.Bladen );
   modify_field( Langlois.Tinaja, Conklin.EastLake );
   modify_field( Langlois.Domestic, Conklin.WestGate, 1 );
   shift_right( Langlois.BlueAsh, Conklin.WestGate, 1 );
   modify_field( Langlois.Thayne, 0 );
   modify_field( Holtville.Servia, 1 );
   modify_field( Kilbourne.Onycha, 1 );
   modify_field( Kilbourne.Olivet, 1 );
   modify_field( Fennimore.Allen, Langlois.Aldrich );
   modify_field( Langlois.Pinecrest, Conklin.Klawock );
   modify_field( Fennimore.Wamesit, Conklin.Klawock, 1);
}
action Deferiet() {
   modify_field( Langlois.Ikatan, 0 );
   modify_field( Parkville.Alameda, Woodfield.Daysville );
   modify_field( Parkville.Commack, Woodfield.ElMirage );
   modify_field( Parkville.Revere, Woodfield.Fragaria );
   modify_field( Humarock.Dollar, WestPike.Humble );
   modify_field( Humarock.Cloverly, WestPike.Rumson );
   modify_field( Humarock.Longwood, WestPike.Leola );
   modify_field( Humarock.Berlin, WestPike.Mabel );
   modify_field( Langlois.Kelvin, Sherrill.Minoa );
   modify_field( Langlois.Lampasas, Sherrill.Grigston );
   modify_field( Langlois.Veteran, Sherrill.Kosmos );
   modify_field( Langlois.Kingsland, Sherrill.Palisades );
   modify_field( Langlois.Calvary, Sherrill.Whitten );
   modify_field( Langlois.Hagewood, Conklin.Mishawaka );
   modify_field( Langlois.Tinaja, Conklin.Milano );
   modify_field( Langlois.Domestic, Conklin.Morrow, 1 );
   shift_right( Langlois.BlueAsh, Conklin.Morrow, 1 );
   modify_field( Kilbourne.Tecolote, Nicodemus[0].Ayden );
   modify_field( Langlois.Thayne, Conklin.Piketon );
   modify_field( Fennimore.Allen, Heflin.Tontogany );
   modify_field( Langlois.Aldrich, Heflin.Tontogany );
   modify_field( Langlois.OakCity, Heflin.Ashwood );
   modify_field( Langlois.Wanilla, Benitez.Westbury );
   modify_field( Langlois.Pinecrest, Conklin.Poplar );
   modify_field( Fennimore.Wamesit, Conklin.Poplar, 1);
}
table SanRemo {
   reads {
      Sherrill.Minoa : exact;
      Sherrill.Grigston : exact;
      Woodfield.ElMirage : exact;
      Langlois.Ikatan : exact;
   }
   actions {
      Harlem;
      Deferiet;
   }
   default_action : Deferiet();
   size : 1024;
}
action Newsome() {
   modify_field( Langlois.Roswell, Madison.SanJuan );
   modify_field( Langlois.Hargis, Madison.Gerlach);
}
action Ohiowa( McQueen ) {
   modify_field( Langlois.Roswell, McQueen );
   modify_field( Langlois.Hargis, Madison.Gerlach);
}
action Clarkdale() {
   modify_field( Langlois.Roswell, Nicodemus[0].Yorkville );
   modify_field( Langlois.Hargis, Madison.Gerlach);
}
table Bowen {
   reads {
      Madison.Gerlach : ternary;
      Nicodemus[0] : valid;
      Nicodemus[0].Yorkville : ternary;
   }
   actions {
      Newsome;
      Ohiowa;
      Clarkdale;
   }
   size : 4096;
}
action TiffCity( Helotes ) {
   modify_field( Langlois.Hargis, Helotes );
}
action Thalia() {
   modify_field( Gakona.Prunedale,
                 2 );
}
table Hillcrest {
   reads {
      Woodfield.Daysville : exact;
   }
   actions {
      TiffCity;
      Thalia;
   }
   default_action : Thalia;
   size : 4096;
}
action Uvalde( Fairland, Vining, Riner, Paisano ) {
   modify_field( Langlois.Roswell, Fairland );
   modify_field( Langlois.Joshua, Fairland );
   modify_field( Langlois.Reager, Paisano );
   Monahans(Vining, Riner);
}
action Tunis() {
   modify_field( Langlois.Ackley, 1 );
}
table Tamora {
   reads {
      Wimbledon.Ammon : exact;
   }
   actions {
      Uvalde;
      Tunis;
   }
   size : 4096;
}
action Monahans(Walcott, Essex) {
   modify_field( Maiden.Gravette, Walcott );
   modify_field( Maiden.LoneJack, Essex );
}
action Pricedale(Palouse, Aynor) {
   modify_field( Langlois.Joshua, Madison.SanJuan );
   Monahans(Palouse, Aynor);
}
action Walland(Wharton, Cleator, Jefferson) {
   modify_field( Langlois.Joshua, Wharton );
   Monahans(Cleator, Jefferson);
}
action Tuckerton(Follett, Lueders) {
   modify_field( Langlois.Joshua, Nicodemus[0].Yorkville );
   Monahans(Follett, Lueders);
}
@pragma ternary 1
table Soldotna {
   reads {
      Madison.SanJuan : exact;
   }
   actions {
      Bammel;
      Pricedale;
   }
   size : 512;
}
@pragma action_default_only Bammel
table Bosworth {
   reads {
      Madison.Gerlach : exact;
      Nicodemus[0].Yorkville : exact;
   }
   actions {
      Walland;
      Bammel;
   }
   size : 1024;
}
table Lewistown {
   reads {
      Nicodemus[0].Yorkville : exact;
   }
   actions {
      Bammel;
      Tuckerton;
   }
   size : 4096;
}
control Carnegie {
   apply( SanRemo ) {
         Harlem {
            apply( Hillcrest );
            apply( Tamora );
         }
         Deferiet {
            if ( Madison.Colstrip == 1 ) {
               apply( Bowen );
            }
            if ( valid( Nicodemus[0] ) and Nicodemus[0].Yorkville != 0 ) {
               apply( Bosworth ) {
                  Bammel {
                     apply( Lewistown );
                  }
               }
            } else {
               apply( Soldotna );
            }
         }
   }
}
register Lapeer {
    width : 1;
    static : Licking;
    instance_count : 294912;
}
register Careywood {
    width : 1;
    static : Dyess;
    instance_count : 294912;
}
blackbox stateful_alu Kahului {
    reg : Lapeer;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : Chamois.Scissors;
}
blackbox stateful_alu Barwick {
    reg : Careywood;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst : Chamois.Hiseville;
}
field_list Ripon {
    ig_intr_md.ingress_port;
    Nicodemus[0].Yorkville;
}
field_list_calculation Hartville {
    input { Ripon; }
    algorithm: identity;
    output_width: 19;
}
action Scranton() {
    Kahului.execute_stateful_alu_from_hash(Hartville);
}
action Poland() {
    Barwick.execute_stateful_alu_from_hash(Hartville);
}
table Licking {
    actions {
      Scranton;
    }
    default_action : Scranton;
    size : 1;
}
table Dyess {
    actions {
      Poland;
    }
    default_action : Poland;
    size : 1;
}
action Nanson(Gassoway) {
    modify_field(Chamois.Hiseville, Gassoway);
}
@pragma ternary 1
table Gallinas {
    reads {
       ig_intr_md.ingress_port mask 0x7f : exact;
    }
    actions {
      Nanson;
    }
    size : 72;
}
control Baytown {
   if ( valid( Nicodemus[0] ) and Nicodemus[0].Yorkville != 0 ) {
      if( Madison.Stella == 1 ) {
         apply( Licking );
         apply( Dyess );
      }
   } else {
      if( Madison.Stella == 1 ) {
         apply( Gallinas );
      }
   }
}
field_list Mickleton {
   Sherrill.Minoa;
   Sherrill.Grigston;
   Sherrill.Kosmos;
   Sherrill.Palisades;
   Sherrill.Whitten;
}
field_list DuPont {
   Woodfield.BigArm;
   Woodfield.Daysville;
   Woodfield.ElMirage;
}
field_list Wilbraham {
   WestPike.Humble;
   WestPike.Rumson;
   WestPike.Leola;
   WestPike.Waldport;
}
field_list Livonia {
   Woodfield.Daysville;
   Woodfield.ElMirage;
   Heflin.Tontogany;
   Heflin.Ashwood;
}
field_list_calculation Covelo {
    input {
        Mickleton;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Braymer {
    input {
        DuPont;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Riverbank {
    input {
        Wilbraham;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Mather {
    input {
        Livonia;
    }
    algorithm : crc32;
    output_width : 32;
}
action Jenners() {
    modify_field_with_hash_based_offset(Kirwin.OldGlory, 0,
                                        Covelo, 4294967296);
}
action Crown() {
    modify_field_with_hash_based_offset(Kirwin.Millport, 0,
                                        Braymer, 4294967296);
}
action Falmouth() {
    modify_field_with_hash_based_offset(Kirwin.Millport, 0,
                                        Riverbank, 4294967296);
}
action Merkel() {
    modify_field_with_hash_based_offset(Kirwin.Kerrville, 0,
                                        Mather, 4294967296);
}
table Emsworth {
   actions {
      Jenners;
   }
   size: 1;
}
control Emmorton {
   apply(Emsworth);
}
table Skime {
   actions {
      Crown;
   }
   size: 1;
}
table Pathfork {
   actions {
      Falmouth;
   }
   size: 1;
}
control Knoke {
   if ( valid( Woodfield ) ) {
      apply(Skime);
   }
}
control Oshoto {
   if ( valid( WestPike ) ) {
         apply(Pathfork);
   }
}
table Artas {
   actions {
      Merkel;
   }
   size: 1;
}
control NewAlbin {
   if ( valid( Pinto ) ) {
      apply(Artas);
   }
}
action Craigtown() {
    modify_field(Chalco.Ludell, Kirwin.OldGlory);
}
action Swenson() {
    modify_field(Chalco.Ludell, Kirwin.Millport);
}
action Barber() {
    modify_field(Chalco.Ludell, Kirwin.Kerrville);
}
@pragma action_default_only Bammel
@pragma immediate 0
table Doerun {
   reads {
      Verbena.valid : ternary;
      Vevay.valid : ternary;
      Magazine.valid : ternary;
      Glyndon.valid : ternary;
      Pinesdale.valid : ternary;
      Benitez.valid : ternary;
      Pinto.valid : ternary;
      Woodfield.valid : ternary;
      WestPike.valid : ternary;
      Sherrill.valid : ternary;
   }
   actions {
      Craigtown;
      Swenson;
      Barber;
      Bammel;
   }
   size: 256;
}
action Bigspring() {
    modify_field(Chalco.Mancelona, Kirwin.Kerrville);
}
@pragma immediate 0
table Proctor {
   reads {
      Verbena.valid : ternary;
      Vevay.valid : ternary;
      Benitez.valid : ternary;
      Pinto.valid : ternary;
   }
   actions {
      Bigspring;
      Bammel;
   }
   size: 6;
}
control Chandalar {
   apply(Proctor);
   apply(Doerun);
}
counter Coalton {
   type : packets_and_bytes;
   direct : Laxon;
   min_width: 16;
}
table Laxon {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Chamois.Hiseville : ternary;
      Chamois.Scissors : ternary;
      Langlois.Ackley : ternary;
      Langlois.Margie : ternary;
      Langlois.Mossville : ternary;
   }
   actions {
      Henrietta;
      Bammel;
   }
   default_action : Bammel();
   size : 512;
}
table Elkton {
   reads {
      Langlois.Veteran : exact;
      Langlois.Kingsland : exact;
      Langlois.Roswell : exact;
   }
   actions {
      Henrietta;
      Bammel;
   }
   default_action : Bammel();
   size : 4096;
}
action Moline() {
   modify_field(Gakona.Prunedale,
                1);
}
table Miranda {
   reads {
      Langlois.Veteran : exact;
      Langlois.Kingsland : exact;
      Langlois.Roswell : exact;
      Langlois.Hargis : exact;
   }
   actions {
      Clovis;
      Moline;
   }
   default_action : Moline();
   size : 65536;
   support_timeout : true;
}
action Dante( Lenwood, Halaula ) {
   modify_field( Langlois.Greenwood, Lenwood );
   modify_field( Langlois.Reager, Halaula );
}
action McDonough() {
   modify_field( Langlois.Reager, 1 );
}
table Clearmont {
   reads {
      Langlois.Roswell mask 0xfff : exact;
   }
   actions {
      Dante;
      McDonough;
      Bammel;
   }
   default_action : Bammel();
   size : 4096;
}
action Gandy() {
   modify_field( Maiden.Dietrich, 1 );
}
table Faulkner {
   reads {
      Langlois.Joshua : ternary;
      Langlois.Kelvin : exact;
      Langlois.Lampasas : exact;
   }
   actions {
      Gandy;
   }
   size: 512;
}
control Hercules {
   apply( Laxon ) {
      Bammel {
         apply( Elkton ) {
            Bammel {
               if (Madison.Mattawan == 0 and Gakona.Prunedale == 0) {
                  apply( Miranda );
               }
               apply( Clearmont );
               apply(Faulkner);
            }
         }
      }
   }
}
field_list Vigus {
    Gakona.Prunedale;
    Langlois.Veteran;
    Langlois.Kingsland;
    Langlois.Roswell;
    Langlois.Hargis;
}
action Baudette() {
   generate_digest(0, Vigus);
}
table Snook {
   actions {
      Baudette;
   }
   size : 1;
}
control Lowland {
   if (Gakona.Prunedale == 1) {
      apply( Snook );
   }
}
action Bellvue( Kalida, Westland ) {
   modify_field( Humarock.Kalvesta, Kalida );
   modify_field( Bushland.McAdoo, Westland );
}
action Robins( Bufalo, Novinger ) {
   modify_field( Humarock.Kalvesta, Bufalo );
   modify_field( Bushland.Mogadore, Novinger );
}
@pragma action_default_only Lucien
table Wymore {
   reads {
      Maiden.Gravette : exact;
      Humarock.Cloverly mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Bellvue;
      Lucien;
      Robins;
   }
   size : 8192;
}
@pragma atcam_partition_index Humarock.Kalvesta
@pragma atcam_number_partitions 8192
table Thatcher {
   reads {
      Humarock.Kalvesta : exact;
      Humarock.Cloverly mask 0x000007FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Grabill;
      Menfro;
      Bammel;
   }
   default_action : Bammel();
   size : 65536;
}
action Cuney( Lovewell, Colonias ) {
   modify_field( Humarock.Pevely, Lovewell );
   modify_field( Bushland.McAdoo, Colonias );
}
action Sargent( Lattimore, Leucadia ) {
   modify_field( Humarock.Pevely, Lattimore );
   modify_field( Bushland.Mogadore, Leucadia );
}
@pragma action_default_only Bammel
table LaConner {
   reads {
      Maiden.Gravette : exact;
      Humarock.Cloverly : lpm;
   }
   actions {
      Cuney;
      Sargent;
      Bammel;
   }
   size : 2048;
}
@pragma atcam_partition_index Humarock.Pevely
@pragma atcam_number_partitions 2048
table Milltown {
   reads {
      Humarock.Pevely : exact;
      Humarock.Cloverly mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Grabill;
      Menfro;
      Bammel;
   }
   default_action : Bammel();
   size : 16384;
}
@pragma action_default_only Lucien
@pragma idletime_precision 1
table Fouke {
   reads {
      Maiden.Gravette : exact;
      Parkville.Commack : lpm;
   }
   actions {
      Grabill;
      Menfro;
      Lucien;
   }
   size : 1024;
   support_timeout : true;
}
action Northome( Hearne, Kiron ) {
   modify_field( Parkville.Farlin, Hearne );
   modify_field( Bushland.McAdoo, Kiron );
}
action Dushore( Sargeant, Pittsburg ) {
   modify_field( Parkville.Farlin, Sargeant );
   modify_field( Bushland.Mogadore, Pittsburg );
}
@pragma action_default_only Bammel
table Lubeck {
   reads {
      Maiden.Gravette : exact;
      Parkville.Commack : lpm;
   }
   actions {
      Northome;
      Dushore;
      Bammel;
   }
   size : 16384;
}
@pragma ways 2
@pragma atcam_partition_index Parkville.Farlin
@pragma atcam_number_partitions 16384
table DoeRun {
   reads {
      Parkville.Farlin : exact;
      Parkville.Commack mask 0x000fffff : lpm;
   }
   actions {
      Grabill;
      Menfro;
      Bammel;
   }
   default_action : Bammel();
   size : 131072;
}
action Grabill( Stratton ) {
   modify_field( Bushland.McAdoo, Stratton );
}
@pragma idletime_precision 1
table Virden {
   reads {
      Maiden.Gravette : exact;
      Parkville.Commack : exact;
   }
   actions {
      Grabill;
      Menfro;
      Bammel;
   }
   default_action : Bammel();
   size : 65536;
   support_timeout : true;
}
@pragma idletime_precision 1
@pragma stage 2 28672
@pragma stage 3
table WestCity {
   reads {
      Maiden.Gravette : exact;
      Humarock.Cloverly : exact;
   }
   actions {
      Grabill;
      Menfro;
      Bammel;
   }
   default_action : Bammel();
   size : 65536;
   support_timeout : true;
}
action Trenary(Pearl, Pavillion, Remington) {
   modify_field(Holtville.TonkaBay, Remington);
   modify_field(Holtville.Westvaco, Pearl);
   modify_field(Holtville.Stone, Pavillion);
   modify_field(Holtville.Snowball, 1);
   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}
action Leflore() {
   Henrietta();
}
action Goulding(Woolwine) {
   modify_field(Holtville.LaVale, 1);
   modify_field(Holtville.Destin, Woolwine);
}
action Lucien(Provo) {
   modify_field(Bushland.McAdoo, Provo);
}
table Stobo {
   reads {
      Bushland.McAdoo : exact;
   }
   actions {
      Trenary;
      Leflore;
      Goulding;
   }
   size : 65536;
}
action Nuyaka(Greenbelt) {
   modify_field(Bushland.McAdoo, Greenbelt);
}
table Meyers {
   actions {
      Nuyaka;
   }
   default_action: Nuyaka;
   size : 1;
}
control Nathan {
   if ( ( ( Maiden.LoneJack & ( 0x2 ) ) == ( ( 0x2 ) ) ) and ( Langlois.BlueAsh == 1 ) ) {
      if ( Langlois.Billett == 0 and Maiden.Dietrich == 1 ) {
         apply( WestCity ) {
            Bammel {
               apply( LaConner );
            }
         }
      }
   } else if ( ( ( Maiden.LoneJack & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Langlois.Domestic == 1 ) ) {
      if ( Langlois.Billett == 0 ) {
         if ( Maiden.Dietrich == 1 ) {
            apply( Virden ) {
               Bammel {
                  apply(Lubeck);
               }
            }
         }
      }
  }
}
control Naylor {
   if ( Langlois.Billett == 0 and Maiden.Dietrich == 1 ) {
      if ( ( ( Maiden.LoneJack & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Langlois.Domestic == 1 ) ) {
         if ( Parkville.Farlin != 0 ) {
            apply( DoeRun );
         } else if ( Bushland.McAdoo == 0 and Bushland.Mogadore == 0 ) {
            apply( Fouke );
         }
      } else if ( ( ( Maiden.LoneJack & ( 0x2 ) ) == ( ( 0x2 ) ) ) and ( Langlois.BlueAsh == 1 ) ) {
         if ( Humarock.Pevely != 0 ) {
            apply( Milltown );
         } else if ( Bushland.McAdoo == 0 and Bushland.Mogadore == 0 ) {
            apply( Wymore );
            if ( Humarock.Kalvesta != 0 ) {
               apply( Thatcher );
            }
         }
      } else if( Langlois.Reager == 1 ) {
         apply( Meyers );
      }
   }
}
control Perryton {
   if( Bushland.McAdoo != 0 ) {
      apply( Stobo );
   }
}
action Menfro( Burtrum ) {
   modify_field( Bushland.Mogadore, Burtrum );
}
field_list Sultana {
   Chalco.Mancelona;
}
field_list_calculation RoseTree {
    input {
        Sultana;
    }
    algorithm : identity;
    output_width : 66;
}
action_selector Gotham {
   selection_key : RoseTree;
   selection_mode : resilient;
}
action_profile Nerstrand {
   actions {
      Grabill;
   }
   size : 65536;
   dynamic_action_selection : Gotham;
}
@pragma selector_max_group_size 256
table GlenRock {
   reads {
      Bushland.Mogadore : exact;
   }
   action_profile : Nerstrand;
   size : 2048;
}
control Shubert {
   if ( Bushland.Mogadore != 0 ) {
      apply( GlenRock );
   }
}
field_list BigBar {
   Chalco.Ludell;
}
field_list_calculation Vieques {
    input {
        BigBar;
    }
    algorithm : identity;
    output_width : 51;
}
action_selector Wabbaseka {
    selection_key : Vieques;
    selection_mode : resilient;
}
action Charlotte(Dunkerton) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Dunkerton);
}
action_profile Mayflower {
    actions {
        Charlotte;
        Bammel;
    }
    size : 1024;
    dynamic_action_selection : Wabbaseka;
}
action Poulsbo() {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Holtville.Blackwood);
}
table Lodoga {
   actions {
        Poulsbo;
   }
   default_action : Poulsbo();
   size : 1;
}
table Harts {
   reads {
      Holtville.Blackwood mask 0x3FF : exact;
   }
   action_profile: Mayflower;
   size : 1024;
}
control Anchorage {
   if ((Holtville.Friend == 1) or valid(Currie)) {
      if ((Holtville.Blackwood & 0x3C00) == 0x3C00) {
         apply(Harts);
      } else {
         apply(Lodoga);
      }
   }
}
action Ignacio() {
   modify_field(Holtville.Westvaco, Langlois.Kelvin);
   modify_field(Holtville.Stone, Langlois.Lampasas);
   modify_field(Holtville.Addison, Langlois.Veteran);
   modify_field(Holtville.Barney, Langlois.Kingsland);
   modify_field(Holtville.TonkaBay, Langlois.Roswell);
   modify_field(Holtville.Blackwood, 511);
   invalidate( ig_intr_md_for_tm.ucast_egress_port );
}
table Fowler {
   actions {
      Ignacio;
   }
   default_action : Ignacio();
   size : 1;
}
control Lublin {
   apply( Fowler );
}
action Woodston() {
   modify_field(Holtville.Virgilina, 1);
   modify_field(Holtville.Etter, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Langlois.Reager);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Holtville.TonkaBay);
}
action Stamford() {
}
@pragma ways 1
table Roodhouse {
   reads {
      Holtville.Westvaco : exact;
      Holtville.Stone : exact;
   }
   actions {
      Woodston;
      Stamford;
   }
   default_action : Stamford;
   size : 1;
}
action Allyn() {
   modify_field(Holtville.Korbel, 1);
   modify_field(Holtville.Elvaston, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Holtville.TonkaBay, 4096);
}
@pragma stage 9
table Orrum {
   actions {
      Allyn;
   }
   default_action : Allyn;
   size : 1;
}
action Pioche() {
   modify_field(Holtville.Houston, 1);
   modify_field(Holtville.Etter, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Holtville.TonkaBay);
}
table Rockfield {
   actions {
      Pioche;
   }
   default_action : Pioche();
   size : 1;
}
action Montross(TroutRun) {
   modify_field(Holtville.Friend, 1);
   modify_field(Holtville.Blackwood, TroutRun);
}
action Osseo(Chaumont) {
   modify_field(Holtville.Korbel, 1);
   modify_field(Holtville.Glassboro, Chaumont);
}
action Powhatan() {
}
table Wittman {
   reads {
      Holtville.Westvaco : exact;
      Holtville.Stone : exact;
      Holtville.TonkaBay : exact;
   }
   actions {
      Montross;
      Osseo;
      Henrietta;
      Powhatan;
   }
   default_action : Powhatan();
   size : 65536;
}
control Amasa {
   if (Langlois.Billett == 0 ) {
      apply(Wittman) {
         Powhatan {
            apply(Roodhouse) {
               Stamford {
                  if ((Holtville.Westvaco & 0x010000) == 0x010000) {
                     apply(Orrum);
                  } else {
                     apply(Rockfield);
                  }
               }
            }
         }
      }
   }
}
action Benwood() {
   modify_field(Langlois.Rocky, 1);
   Henrietta();
}
table LaLuz {
   actions {
      Benwood;
   }
   default_action : Benwood;
   size : 1;
}
control Ferry {
   if (Langlois.Billett == 0) {
      if ((Holtville.Snowball==0) and (Langlois.Gosnell==0) and (Langlois.Kurten==0) and (Langlois.Hargis==Holtville.Blackwood)) {
         apply(LaLuz);
      }
   }
}
action Sharptown( Lantana ) {
   modify_field( Holtville.Nephi, Lantana );
}
action Maltby() {
   modify_field( Holtville.Nephi, Holtville.TonkaBay );
}
table Veguita {
   reads {
      eg_intr_md.egress_port : exact;
      Holtville.TonkaBay : exact;
   }
   actions {
      Sharptown;
      Maltby;
   }
   default_action : Maltby;
   size : 4096;
}
control Nutria {
   apply( Veguita );
}
action Churchill( Shingler, Goree ) {
   modify_field( Holtville.Tallevast, Shingler );
   modify_field( Holtville.Beresford, Goree );
}
action Beaverdam( RedMills, Hawley, Holcut ) {
   modify_field( Holtville.Tallevast, RedMills );
   modify_field( Holtville.Beresford, Hawley );
   modify_field( Holtville.Navarro, Holcut );
}
action Eolia() {
   modify_field( Holtville.Tampa, 47 );
   modify_field( Holtville.Kittredge, 0x0800 );
}
table Armijo {
   reads {
      Holtville.Goldenrod : exact;
   }
   actions {
      Churchill;
      Beaverdam;
      Eolia;
   }
   size : 8;
}
action Bienville( Crowheart ) {
   modify_field( Holtville.Donald, 1 );
   modify_field( Holtville.Goldenrod, 2 );
   modify_field( Holtville.Calamus, Crowheart );
}
table Eddystone {
   reads {
      eg_intr_md.egress_port : exact;
      Madison.Colstrip : exact;
      Holtville.Brave : exact;
   }
   actions {
      Bienville;
   }
   default_action : Bammel();
   size : 16;
}
action Medulla(Ephesus, Hemlock, RedBay, Welcome) {
   modify_field( Holtville.Neosho, Ephesus );
   modify_field( Holtville.Aylmer, Hemlock );
   modify_field( Holtville.Whitefish, RedBay );
   modify_field( Holtville.Millstadt, Welcome );
}
table Bairoa {
   reads {
        Holtville.Angwin : exact;
   }
   actions {
      Medulla;
   }
   size : 512;
}
action Swansea( Loris ) {
   modify_field( Holtville.Doddridge, Loris );
}
table Madill {
   reads {
      Holtville.Belvue mask 0x1FFFF : exact;
   }
   actions {
      Swansea;
   }
   default_action : Swansea(0);
   size : 4096;
}
action Grandy( Oklee, Botna ) {
   modify_field( Holtville.Nordland, Oklee );
   modify_field( Holtville.Lowes, Botna );
}
@pragma use_hash_action 1
table Boonsboro {
   reads {
      Holtville.Cascadia : exact;
   }
   actions {
      Grandy;
   }
   default_action : Grandy(0,0);
   size : 256;
}
action Camilla( Lamont ) {
   modify_field( Holtville.Calamine, Lamont );
}
table Hagerman {
   reads {
      Holtville.TonkaBay mask 0xFFF : exact;
   }
   actions {
      Camilla;
   }
   default_action : Camilla( 0 );
   size : 4096;
}
control MontIda {
   if( ( Holtville.Belvue & 0x20000 ) == 0 ) {
      apply( Madill );
   }
   if( Holtville.Cascadia != 0 ) {
      apply( Boonsboro );
   }
   apply( Hagerman );
}
action Iraan() {
   no_op();
}
action Raven() {
   modify_field( Sherrill.Whitten, Nicodemus[0].Puryear );
   remove_header( Nicodemus[0] );
}
table Dozier {
   actions {
      Raven;
   }
   default_action : Raven;
   size : 1;
}
action Wickett() {
   no_op();
}
action Skene() {
   add_header( Nicodemus[ 0 ] );
   modify_field( Nicodemus[0].Yorkville, Holtville.Nephi );
   modify_field( Nicodemus[0].Puryear, Sherrill.Whitten );
   modify_field( Nicodemus[0].Westway, Kilbourne.Wyocena );
   modify_field( Nicodemus[0].Ayden, Kilbourne.Tecolote );
   modify_field( Sherrill.Whitten, 0x8100 );
}
table Longport {
   reads {
      Holtville.Nephi : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Wickett;
      Skene;
   }
   default_action : Skene;
   size : 128;
}
action Corbin() {
   modify_field(Sherrill.Minoa, Holtville.Westvaco);
   modify_field(Sherrill.Grigston, Holtville.Stone);
   modify_field(Sherrill.Kosmos, Holtville.Tallevast);
   modify_field(Sherrill.Palisades, Holtville.Beresford);
}
action Coronado() {
   Corbin();
   add_to_field(Woodfield.Neame, -1);
   modify_field(Woodfield.Fragaria, Kilbourne.Ripley);
}
action Oroville() {
   Corbin();
   add_to_field(WestPike.Hydaburg, -1);
   modify_field(WestPike.Mabel, Kilbourne.Ripley);
}
action ElJebel() {
   modify_field(Woodfield.Fragaria, Kilbourne.Ripley);
}
action Needles() {
   modify_field(WestPike.Mabel, Kilbourne.Ripley);
}
action Swisher() {
   Skene();
}
action Daisytown( Lovilia, Sonora, Weinert, Montello ) {
   add_header( Iberia );
   modify_field( Iberia.Minoa, Lovilia );
   modify_field( Iberia.Grigston, Sonora );
   modify_field( Iberia.Kosmos, Weinert );
   modify_field( Iberia.Palisades, Montello );
   modify_field( Iberia.Whitten, 0xBF00 );
   add_header( Currie );
   modify_field( Currie.Quarry, Holtville.Neosho );
   modify_field( Currie.Loogootee, Holtville.Aylmer );
   modify_field( Currie.Lowden, Holtville.Whitefish );
   modify_field( Currie.Separ, Holtville.Millstadt );
   modify_field( Currie.Thomas, Holtville.Destin );
   modify_field( Currie.Westoak, Langlois.Roswell );
   modify_field( Currie.Vanzant, Holtville.Calamus );
   modify_field( Currie.Freeman, Holtville.Champlin );
}
action Mendota() {
   no_op();
}
action BeeCave() {
   add_header( Belmond );
   modify_field( Belmond.Slater, Holtville.Picabo );
   add_header( Woodfield );
   modify_field( Woodfield.Piperton, Holtville.Valsetz );
   modify_field( Woodfield.Nelagoney, Holtville.Berrydale );
   modify_field( Woodfield.Fragaria, Holtville.Hackett );
   modify_field( Woodfield.BigArm, Holtville.Tampa );
   modify_field( Woodfield.Neame, Holtville.Maryville );
   modify_field( Woodfield.Daysville, Holtville.Pickett );
   modify_field( Woodfield.ElMirage, Holtville.Doddridge );
   add( Woodfield.Vallecito, Woodfield.Vallecito, 24 );
   modify_field( Sherrill.Whitten, Holtville.Kittredge );
   Corbin();
}
action Kasigluk() {
   remove_header( Wimbledon );
   remove_header( Pinto );
   remove_header( Heflin );
   copy_header( Sherrill, Pinesdale );
   remove_header( Pinesdale );
   remove_header( Woodfield );
}
action Earlsboro() {
   remove_header( Iberia );
   remove_header( Currie );
}
action Froid() {
   Kasigluk();
   modify_field(Magazine.Fragaria, Kilbourne.Ripley);
}
action Spindale() {
   Kasigluk();
   modify_field(Glyndon.Mabel, Kilbourne.Ripley);
}
action Morgana( Talbert ) {
   modify_field( Magazine.Piperton, Woodfield.Piperton );
   modify_field( Magazine.Nelagoney, Woodfield.Nelagoney );
   modify_field( Magazine.Fragaria, Woodfield.Fragaria );
   modify_field( Magazine.Baldwin, Woodfield.Baldwin );
   modify_field( Magazine.Vallecito, Woodfield.Vallecito );
   modify_field( Magazine.Sonoma, Woodfield.Sonoma );
   modify_field( Magazine.Rochert, Woodfield.Rochert );
   add( Magazine.Neame, Woodfield.Neame, Talbert );
   modify_field( Magazine.BigArm, Woodfield.BigArm );
   modify_field( Magazine.Gaston, Woodfield.Gaston );
   modify_field( Magazine.Daysville, Woodfield.Daysville );
   modify_field( Magazine.ElMirage, Woodfield.ElMirage );
}
field_list Kelso {
   Woodfield.Daysville;
   Woodfield.ElMirage;
   Woodfield.BigArm;
   Holtville.Colona;
}
field_list_calculation Emblem {
    input {
       Kelso;
    }
    algorithm : crc32;
    output_width : 16;
}
action Milnor( Ruffin ) {
   add_header( Pinesdale );
   add_header( Pinto );
   add_header( Heflin );
   add_header( Wimbledon );
   modify_field( Pinesdale.Minoa, Holtville.Westvaco );
   modify_field( Pinesdale.Grigston, Holtville.Stone );
   modify_field( Pinesdale.Kosmos, Sherrill.Kosmos );
   modify_field( Pinesdale.Palisades, Sherrill.Palisades );
   modify_field( Pinesdale.Whitten, Sherrill.Whitten );
   add( Pinto.Cruso, Woodfield.Vallecito, 16 );
   modify_field( Pinto.Branson, 0 );
   modify_field( Heflin.Ashwood, 4789 );
   modify_field_with_hash_based_offset( Heflin.Tontogany, 0, Ruffin, 16384 );
   modify_field( Wimbledon.Elkins, 0x10 );
   modify_field( Wimbledon.Ammon, Holtville.Calamine );
   modify_field( Sherrill.Minoa, Holtville.Nordland );
   modify_field( Sherrill.Grigston, Holtville.Lowes );
   modify_field( Sherrill.Kosmos, Holtville.Tallevast );
   modify_field( Sherrill.Palisades, Holtville.Beresford );
}
action Chatcolet() {
   add_header( Magazine );
   Morgana( -1 );
   Milnor( Emblem );
   modify_field( Woodfield.Piperton, 0x4 );
   modify_field( Woodfield.Nelagoney, 0x5 );
   modify_field( Woodfield.Fragaria, 0 );
   modify_field( Woodfield.Baldwin, 0 );
   add_to_field( Woodfield.Vallecito, 36 );
   modify_field( Woodfield.Jelloway, eg_intr_md_from_parser_aux.egress_global_tstamp, 0xFFFF );
   modify_field( Woodfield.Sonoma, 0 );
   modify_field( Woodfield.Rochert, 0 );
   modify_field( Woodfield.Neame, 64 );
   modify_field( Woodfield.BigArm, 17 );
   modify_field( Woodfield.Daysville, Holtville.Navarro );
   modify_field( Woodfield.ElMirage, Holtville.Doddridge );
   modify_field( Sherrill.Whitten, 0x0800 );
}
table Reubens {
   reads {
      Holtville.Servia : exact;
      Holtville.Goldenrod : exact;
      Holtville.Snowball : exact;
      Woodfield.valid : ternary;
      WestPike.valid : ternary;
      Magazine.valid : ternary;
      Glyndon.valid : ternary;
   }
   actions {
      Coronado;
      Oroville;
      ElJebel;
      Needles;
      Swisher;
      Daisytown;
      Earlsboro;
      Kasigluk;
      Froid;
      Spindale;
      Chatcolet;
      BeeCave;
      Mendota;
   }
   size : 512;
}
control Sarasota {
   apply( Dozier );
}
control Seaford {
   apply( Longport );
}
action GlenAvon() {
   modify_field( Holtville.Hackett, Kilbourne.Ripley );
}
table McGonigle {
   actions {
      GlenAvon;
   }
   default_action : GlenAvon;
   size : 1;
}
action Wakeman() {
   modify_field( Holtville.Maryville, Woodfield.Neame );
}
table Escondido {
   actions {
      Wakeman;
   }
   default_action : Wakeman;
   size : 1;
}
action SandLake() {
   modify_field( Holtville.Picabo, Sherrill.Whitten );
}
table Macland {
   actions {
      SandLake;
   }
   default_action : SandLake;
   size : 1;
}
control Gifford {
   apply( Eddystone ) {
      Bammel {
         apply( Armijo );
         if( Holtville.Maryville == 0 ) {
            apply( Escondido );
         }
         if( Holtville.Hackett == 0 ) {
            apply( McGonigle );
         }
         if( Holtville.Picabo == 0 ) {
            apply( Macland );
         }
      }
   }
   apply( Bairoa );
   apply( Reubens );
}
field_list Gregory {
    Gakona.Prunedale;
    Langlois.Roswell;
    Pinesdale.Kosmos;
    Pinesdale.Palisades;
    Woodfield.Daysville;
}
action Bernice() {
   generate_digest(0, Gregory);
}
table Guadalupe {
   actions {
      Bernice;
   }
   default_action : Bernice;
   size : 1;
}
control Windber {
   if (Gakona.Prunedale == 2) {
      apply(Guadalupe);
   }
}
action Norcatur( Catarina, Joseph, Polkville ) {
   modify_field( Kilbourne.Purley, Catarina );
   modify_field( Kilbourne.Elmont, Joseph );
   modify_field( Kilbourne.Laclede, Polkville );
}
table Dairyland {
   reads {
     ig_intr_md.ingress_port : exact;
   }
   actions {
      Norcatur;
   }
   size : 512;
}
action LaJoya() {
   modify_field( Kilbourne.Wyocena, Kilbourne.Purley );
}
action Wolverine() {
   modify_field( Kilbourne.Wyocena, Nicodemus[0].Westway );
   modify_field( Langlois.Calvary, Nicodemus[0].Puryear );
}
action IdaGrove() {
   modify_field( Kilbourne.Ripley, Kilbourne.Elmont );
}
action Farson() {
   modify_field( Kilbourne.Ripley, 0 );
}
action Beechwood() {
   modify_field( Kilbourne.Ripley, Parkville.Revere );
}
action Sequim() {
   modify_field( Kilbourne.Ripley, Humarock.Berlin );
}
action Piney( MiraLoma, Swain ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, MiraLoma );
   modify_field( ig_intr_md_for_tm.qid, Swain );
}
table Aberfoil {
   reads {
     Langlois.Thayne : exact;
   }
   actions {
     LaJoya;
     Wolverine;
   }
   size : 2;
}
table Sanford {
   reads {
     Holtville.Servia : exact;
     Langlois.Domestic : exact;
     Langlois.BlueAsh : exact;
   }
   actions {
     IdaGrove;
     Farson;
     Beechwood;
     Sequim;
   }
   size : 6;
}
table Ashville {
   reads {
      Kilbourne.Laclede : ternary;
      Kilbourne.Purley : ternary;
      Kilbourne.Wyocena : ternary;
      Kilbourne.Ripley : ternary;
      Kilbourne.LaPuente : ternary;
      Holtville.Servia : ternary;
   }
   actions {
      Piney;
   }
   size : 145;
}
action Quinnesec( Stovall, Iroquois ) {
   bit_or( Kilbourne.Onycha, Kilbourne.Onycha, Stovall );
   bit_or( Kilbourne.Olivet, Kilbourne.Olivet, Iroquois );
}
table Vandling {
   actions {
      Quinnesec;
   }
   default_action : Quinnesec;
   size : 1;
}
action Boysen( Corry ) {
   modify_field( Kilbourne.Ripley, Corry );
}
action Hilger( Pearcy ) {
   modify_field( Kilbourne.Wyocena, Pearcy );
}
action PawCreek( Tusayan, Strasburg ) {
   modify_field( Kilbourne.Wyocena, Tusayan );
   modify_field( Kilbourne.Ripley, Strasburg );
}
table Kenova {
   reads {
      Kilbourne.Laclede : exact;
      Kilbourne.Onycha : exact;
      Kilbourne.Olivet : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
      Holtville.Servia : exact;
   }
   actions {
      Boysen;
      Hilger;
      PawCreek;
   }
   size : 1024;
}
control Corum {
   apply( Dairyland );
}
control Waseca {
   apply( Aberfoil );
   apply( Sanford );
}
control Whitakers {
   apply( Ashville );
}
control Winfall {
   apply( Vandling );
   apply( Kenova );
}
action Langhorne( SeaCliff ) {
   modify_field( Kilbourne.Lurton, SeaCliff );
}
table Sturgis {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
   }
   actions {
      Langhorne;
   }
}
action Maida( Bradner ) {
   modify_field( Kilbourne.Cimarron, Bradner );
}
table SwissAlp {
   reads {
      Langlois.Calvary : ternary;
      Langlois.Kurten : ternary;
      Holtville.Stone : ternary;
      Holtville.Westvaco : ternary;
      Bushland.McAdoo : ternary;
   }
   actions {
      Maida;
   }
   default_action: Maida;
   size : 512;
}
table Clifton {
   reads {
      Langlois.Domestic : ternary;
      Langlois.BlueAsh : ternary;
      Langlois.Kurten : ternary;
      Parkville.Commack : ternary;
      Humarock.Cloverly mask 0xffff0000000000000000000000000000 : ternary;
      Langlois.Hagewood : ternary;
      Langlois.Tinaja : ternary;
      Holtville.Snowball : ternary;
      Bushland.McAdoo : ternary;
      Heflin.Tontogany : ternary;
      Heflin.Ashwood : ternary;
   }
   actions {
      Maida;
   }
   default_action: Maida;
   size : 512;
}
meter Levasy {
   type : packets;
   static : Sledge;
   instance_count : 4096;
}
counter Tahlequah {
   type : packets;
   static : Sledge;
   instance_count : 4096;
   min_width : 64;
}
action Humeston(Tuttle) {
   execute_meter( Levasy, Tuttle, ig_intr_md_for_tm.packet_color );
}
action Poulan(Winnebago) {
   count( Tahlequah, Winnebago );
}
action Milwaukie(Blanding) {
   Humeston(Blanding);
   Poulan(Blanding);
}
table Sledge {
   reads {
      Kilbourne.Lurton : exact;
      Kilbourne.Cimarron : exact;
   }
   actions {
     Poulan;
     Milwaukie;
   }
   size : 512;
}
control Leacock {
   apply( Sturgis );
}
control Salus {
      if ( ( Langlois.Domestic == 0 ) and ( Langlois.BlueAsh == 0 ) ) {
         apply( SwissAlp );
      } else {
         apply( Clifton );
      }
}
control Sunflower {
    if ( Langlois.Billett == 0 ) {
      apply( Sledge );
   }
}
counter Covina {
   type : packets;
   direct : Prosser;
   min_width : 64;
}
action Kenefic( Micro, Manning ) {
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Micro );
   modify_field( Holtville.Angwin, ig_intr_md.ingress_port );
   modify_field( ig_intr_md_for_tm.qid, Manning );
}
action Ewing() {
   modify_field( Holtville.Angwin, ig_intr_md.ingress_port );
}
action Drifton( Arredondo, Silva ) {
   Kenefic( Arredondo, Silva );
   modify_field( Holtville.Brave, 0);
}
action Burket() {
   Ewing();
   modify_field( Holtville.Brave, 0);
}
action Daphne( Cranbury, Lindsay ) {
   Kenefic( Cranbury, Lindsay );
   modify_field( Holtville.Brave, 1);
}
action Ipava() {
   Ewing();
   modify_field( Holtville.Brave, 1);
}
@pragma ternary 1
table Prosser {
   reads {
      Holtville.LaVale : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      Nicodemus[0] : valid;
      Holtville.Destin : ternary;
   }
   actions {
      Drifton;
      Burket;
      Daphne;
      Ipava;
   }
   default_action : Bammel();
   size : 512;
}
control Tidewater {
   apply( Prosser ) {
      Drifton {
      }
      Daphne {
      }
      default {
         Anchorage();
      }
   }
}
counter Casselman {
   type : packets_and_bytes;
   instance_count : 1024;
   min_width : 128;
}
action Tonkawa( Uintah ) {
   count( Casselman, Uintah );
}
table Silesia {
   reads {
      eg_intr_md.egress_port mask 0x7f: exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }
   actions {
     Tonkawa;
   }
   size : 1024;
}
control Ambler {
   apply( Silesia );
}
action McCallum()
{
   Henrietta();
}
action Vernal() {
   modify_field(Holtville.Servia, 3);
}
action Oakmont()
{
   modify_field(Holtville.Servia, 2);
   bit_or(Holtville.Blackwood, 0x3C00, Currie.Separ);
}
action Burnett( Boyle ) {
   modify_field(Holtville.Servia, 2);
   modify_field(Holtville.Blackwood, Boyle);
}
table Cache {
   reads {
      Currie.Quarry : exact;
      Currie.Loogootee : exact;
      Currie.Lowden : exact;
      Currie.Separ : exact;
   }
   actions {
      Oakmont;
      Burnett;
      Vernal;
      McCallum;
   }
   default_action : McCallum();
   size : 512;
}
control Conda {
   apply( Cache );
}
action Skillman( Gladden, Palatine, Taconite, Craig ) {
   modify_field( Ashley.Shivwits, Gladden );
   modify_field( Bleecker.Desdemona, Taconite );
   modify_field( Bleecker.Gibsland, Palatine );
   modify_field( Bleecker.Bethania, Craig );
}
table Camanche {
   reads {
     Parkville.Commack : exact;
     Langlois.Joshua : exact;
   }
   actions {
      Skillman;
   }
  size : 16384;
}
action Oregon(Alabam, HornLake, Redmon) {
   modify_field( Bleecker.Gibsland, Alabam );
   modify_field( Bleecker.Desdemona, HornLake );
   modify_field( Bleecker.Bethania, Redmon );
}
table Saxis {
   reads {
     Parkville.Alameda : exact;
     Ashley.Shivwits : exact;
   }
   actions {
      Oregon;
   }
   size : 16384;
}
action Vanoss( Harney, Wayland, Parkland ) {
   modify_field( Warsaw.Sublimity, Harney );
   modify_field( Warsaw.Gully, Wayland );
   modify_field( Warsaw.Vincent, Parkland );
}
table Salitpa {
   reads {
     Holtville.Westvaco : exact;
     Holtville.Stone : exact;
     Holtville.TonkaBay : exact;
   }
   actions {
      Vanoss;
   }
   size : 16384;
}
action Magna() {
   modify_field( Holtville.Etter, 1 );
}
action Gustine( Cherokee ) {
   Magna();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Bleecker.Gibsland );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Cherokee, Bleecker.Bethania );
}
action Clarks( Hartwell ) {
   Magna();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Warsaw.Sublimity );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Hartwell, Warsaw.Vincent );
}
action Cornell( Verdery ) {
   Magna();
   add( ig_intr_md_for_tm.mcast_grp_a, Holtville.TonkaBay,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Verdery );
}
action Antoine() {
   modify_field( Holtville.Varnado, 1 );
}
table KingCity {
   reads {
     Bleecker.Desdemona : ternary;
     Bleecker.Gibsland : ternary;
     Warsaw.Sublimity : ternary;
     Warsaw.Gully : ternary;
     Langlois.Hagewood :ternary;
     Langlois.Gosnell:ternary;
   }
   actions {
      Gustine;
      Clarks;
      Cornell;
      Antoine;
   }
   size : 32;
}
control Pocopson {
   if( Langlois.Billett == 0 and
       ( ( Maiden.LoneJack & ( 0x4 ) ) == ( ( 0x4 ) ) ) and
       Langlois.Castle == 1 ) {
      apply( Camanche );
   }
}
control Malinta {
   if( Ashley.Shivwits != 0 ) {
      apply( Saxis );
   }
}
control Casper {
   if( Langlois.Billett == 0 and Langlois.Gosnell==1 ) {
      apply( Salitpa );
   }
}
control Markville {
   if( Langlois.Gosnell == 1 ) {
      apply(KingCity);
   }
}
action Doyline(Monida) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Chalco.Ludell );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Monida );
}
table Scherr {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Doyline;
    }
    size : 512;
}
control Everetts {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Scherr);
   }
}
action Gracewood( Chenequa, Siloam, Moorewood ) {
   modify_field( Holtville.TonkaBay, Chenequa );
   modify_field( Holtville.Snowball, Siloam );
   bit_or( eg_intr_md_for_oport.drop_ctl, eg_intr_md_for_oport.drop_ctl, Moorewood );
}
@pragma use_hash_action 1
table Franktown {
   reads {
     eg_intr_md.egress_rid: exact;
   }
   actions {
      Gracewood;
   }
   default_action: Gracewood( 0, 0, 1 );
   size : 65536;
}
control Stampley {
   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Franktown);
   }
}
counter Virgin {
   type : packets;
   direct: Dalkeith;
   min_width: 63;
}
@pragma stage 11
table Dalkeith {
   reads {
     LaJara.Mullins mask 0x7fff : exact;
   }
   actions {
      Bammel;
   }
   default_action: Bammel();
   size : 32768;
}
action Cistern() {
   modify_field( Fennimore.Punaluu, Langlois.Hagewood );
   modify_field( Fennimore.Tindall, Parkville.Revere );
   modify_field( Fennimore.Hiawassee, Langlois.Tinaja );
   modify_field( Fennimore.Point, Langlois.Wanilla );
}
action Minto() {
   modify_field( Fennimore.Punaluu, Langlois.Hagewood );
   modify_field( Fennimore.Tindall, Humarock.Berlin );
   modify_field( Fennimore.Hiawassee, Langlois.Tinaja );
   modify_field( Fennimore.Point, Langlois.Wanilla );
}
action Oskawalik( Garwood, Ocoee ) {
   Cistern();
   modify_field( Fennimore.Hallwood, Garwood );
   modify_field( Fennimore.Deerwood, Ocoee );
}
action Mineral( Cardenas, Loyalton ) {
   Minto();
   modify_field( Fennimore.Hallwood, Cardenas );
   modify_field( Fennimore.Deerwood, Loyalton );
}
table Kountze {
   reads {
     Parkville.Alameda : ternary;
   }
   actions {
      Oskawalik;
   }
   default_action : Cistern;
  size : 2048;
}
table August {
   reads {
     Humarock.Dollar : ternary;
   }
   actions {
      Mineral;
   }
   default_action : Minto;
   size : 1024;
}
action Wallula( Yorklyn, FourTown ) {
   modify_field( Fennimore.Wyncote, Yorklyn );
   modify_field( Fennimore.Emerado, FourTown );
}
table Rippon {
   reads {
     Parkville.Commack : ternary;
   }
   actions {
      Wallula;
   }
   size : 512;
}
table Lucas {
   reads {
     Humarock.Cloverly : ternary;
   }
   actions {
      Wallula;
   }
   size : 512;
}
action Swifton( Woodsdale ) {
   modify_field( Fennimore.Allen, Woodsdale );
}
table Nelson {
   reads {
     Langlois.Aldrich : ternary;
   }
   actions {
      Swifton;
   }
   size : 512;
}
action Dorothy( Preston ) {
   modify_field( Fennimore.Ontonagon, Preston );
}
table Ribera {
   reads {
     Langlois.OakCity : ternary;
   }
   actions {
      Dorothy;
   }
   size : 512;
}
action Pittwood( Otego ) {
   modify_field( Fennimore.Hobergs, Otego );
}
action CoosBay( Ravenwood ) {
   modify_field( Fennimore.Hobergs, Ravenwood );
}
table Cathcart {
   reads {
     Langlois.Domestic : exact;
     Langlois.BlueAsh : exact;
     Langlois.Pinecrest mask 4 : exact;
     Langlois.Joshua : exact;
   }
   actions {
      Pittwood;
      Bammel;
   }
   default_action : Bammel();
   size : 4096;
}
table Wheeling {
   reads {
     Langlois.Domestic : exact;
     Langlois.BlueAsh : exact;
     Langlois.Pinecrest mask 4 : exact;
     Madison.Gerlach : exact;
   }
   actions {
      CoosBay;
   }
   size : 512;
}
control Coulter {
   if( Langlois.Domestic == 1 ) {
      apply( Kountze );
      apply( Rippon );
   } else if( Langlois.BlueAsh == 1 ) {
      apply( August );
      apply( Lucas );
   }
   if( ( Langlois.Pinecrest & 2 ) == 2 ) {
      apply( Nelson );
      apply( Ribera );
   }
   apply( Cathcart ) {
      Bammel {
         apply( Wheeling );
      }
   }
}
action Bridger() {
}
action Elsinore() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action Hooven() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
}
action Hannibal() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
table Chatanika {
   reads {
     LaJara.Mullins mask 0x00018000 : ternary;
   }
   actions {
      Bridger;
      Elsinore;
      Hooven;
      Hannibal;
   }
   size : 16;
}
control Roachdale {
   apply( Chatanika );
   apply( Dalkeith );
}
   metadata Disney LaJara;
   action Helen( Patchogue ) {
          max( LaJara.Mullins, LaJara.Mullins, Patchogue );
   }
@pragma ways 4
table Hookstown {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : exact;
      Fennimore.Wyncote : exact;
      Fennimore.Allen : exact;
      Fennimore.Ontonagon : exact;
      Fennimore.Punaluu : exact;
      Fennimore.Tindall : exact;
      Fennimore.Hiawassee : exact;
      Fennimore.Point : exact;
      Fennimore.Wamesit : exact;
   }
   actions {
      Helen;
   }
   size : 4096;
}
control Pridgen {
   apply( Hookstown );
}
table Kingsgate {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : ternary;
      Fennimore.Wyncote : ternary;
      Fennimore.Allen : ternary;
      Fennimore.Ontonagon : ternary;
      Fennimore.Punaluu : ternary;
      Fennimore.Tindall : ternary;
      Fennimore.Hiawassee : ternary;
      Fennimore.Point : ternary;
      Fennimore.Wamesit : ternary;
   }
   actions {
      Helen;
   }
   size : 512;
}
control Ivanpah {
   apply( Kingsgate );
}
@pragma pa_no_init ingress Beatrice.Hallwood
@pragma pa_no_init ingress Beatrice.Wyncote
@pragma pa_no_init ingress Beatrice.Allen
@pragma pa_no_init ingress Beatrice.Ontonagon
@pragma pa_no_init ingress Beatrice.Punaluu
@pragma pa_no_init ingress Beatrice.Tindall
@pragma pa_no_init ingress Beatrice.Hiawassee
@pragma pa_no_init ingress Beatrice.Point
@pragma pa_no_init ingress Beatrice.Wamesit
metadata Temple Beatrice;
@pragma ways 4
table Kiwalik {
   reads {
      Fennimore.Hobergs : exact;
      Beatrice.Hallwood : exact;
      Beatrice.Wyncote : exact;
      Beatrice.Allen : exact;
      Beatrice.Ontonagon : exact;
      Beatrice.Punaluu : exact;
      Beatrice.Tindall : exact;
      Beatrice.Hiawassee : exact;
      Beatrice.Point : exact;
      Beatrice.Wamesit : exact;
   }
   actions {
      Helen;
   }
   size : 8192;
}
action Millstone( Dovray, Standard, Buckeye, Damar, Mondovi, Rohwer, Owentown, McIntyre, Almyra ) {
   bit_and( Beatrice.Hallwood, Fennimore.Hallwood, Dovray );
   bit_and( Beatrice.Wyncote, Fennimore.Wyncote, Standard );
   bit_and( Beatrice.Allen, Fennimore.Allen, Buckeye );
   bit_and( Beatrice.Ontonagon, Fennimore.Ontonagon, Damar );
   bit_and( Beatrice.Punaluu, Fennimore.Punaluu, Mondovi );
   bit_and( Beatrice.Tindall, Fennimore.Tindall, Rohwer );
   bit_and( Beatrice.Hiawassee, Fennimore.Hiawassee, Owentown );
   bit_and( Beatrice.Point, Fennimore.Point, McIntyre );
   bit_and( Beatrice.Wamesit, Fennimore.Wamesit, Almyra );
}
table Corydon {
   reads {
      Fennimore.Hobergs : exact;
   }
   actions {
      Millstone;
   }
   default_action : Millstone(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Spiro {
   apply( Corydon );
}
control Fairborn {
   apply( Kiwalik );
}
table Francisco {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : ternary;
      Fennimore.Wyncote : ternary;
      Fennimore.Allen : ternary;
      Fennimore.Ontonagon : ternary;
      Fennimore.Punaluu : ternary;
      Fennimore.Tindall : ternary;
      Fennimore.Hiawassee : ternary;
      Fennimore.Point : ternary;
      Fennimore.Wamesit : ternary;
   }
   actions {
      Helen;
   }
   size : 512;
}
control Atwater {
   apply( Francisco );
}
@pragma ways 4
table Liberal {
   reads {
      Fennimore.Hobergs : exact;
      Beatrice.Hallwood : exact;
      Beatrice.Wyncote : exact;
      Beatrice.Allen : exact;
      Beatrice.Ontonagon : exact;
      Beatrice.Punaluu : exact;
      Beatrice.Tindall : exact;
      Beatrice.Hiawassee : exact;
      Beatrice.Point : exact;
      Beatrice.Wamesit : exact;
   }
   actions {
      Helen;
   }
   size : 4096;
}
action DeBeque( Tiverton, Denning, Issaquah, Somis, Spalding, GlenArm, Lamboglia, Mayday, Challenge ) {
   bit_and( Beatrice.Hallwood, Fennimore.Hallwood, Tiverton );
   bit_and( Beatrice.Wyncote, Fennimore.Wyncote, Denning );
   bit_and( Beatrice.Allen, Fennimore.Allen, Issaquah );
   bit_and( Beatrice.Ontonagon, Fennimore.Ontonagon, Somis );
   bit_and( Beatrice.Punaluu, Fennimore.Punaluu, Spalding );
   bit_and( Beatrice.Tindall, Fennimore.Tindall, GlenArm );
   bit_and( Beatrice.Hiawassee, Fennimore.Hiawassee, Lamboglia );
   bit_and( Beatrice.Point, Fennimore.Point, Mayday );
   bit_and( Beatrice.Wamesit, Fennimore.Wamesit, Challenge );
}
table SneeOosh {
   reads {
      Fennimore.Hobergs : exact;
   }
   actions {
      DeBeque;
   }
   default_action : DeBeque(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Westpoint {
   apply( SneeOosh );
}
control Alburnett {
   apply( Liberal );
}
table Lewes {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : ternary;
      Fennimore.Wyncote : ternary;
      Fennimore.Allen : ternary;
      Fennimore.Ontonagon : ternary;
      Fennimore.Punaluu : ternary;
      Fennimore.Tindall : ternary;
      Fennimore.Hiawassee : ternary;
      Fennimore.Point : ternary;
      Fennimore.Wamesit : ternary;
   }
   actions {
      Helen;
   }
   size : 512;
}
control Geismar {
   apply( Lewes );
}
@pragma ways 4
table Hanks {
   reads {
      Fennimore.Hobergs : exact;
      Beatrice.Hallwood : exact;
      Beatrice.Wyncote : exact;
      Beatrice.Allen : exact;
      Beatrice.Ontonagon : exact;
      Beatrice.Punaluu : exact;
      Beatrice.Tindall : exact;
      Beatrice.Hiawassee : exact;
      Beatrice.Point : exact;
      Beatrice.Wamesit : exact;
   }
   actions {
      Helen;
   }
   size : 4096;
}
action Rockdell( Upson, Canalou, Eldora, Flasher, Verndale, Dagsboro, Fosston, Downs, Denby ) {
   bit_and( Beatrice.Hallwood, Fennimore.Hallwood, Upson );
   bit_and( Beatrice.Wyncote, Fennimore.Wyncote, Canalou );
   bit_and( Beatrice.Allen, Fennimore.Allen, Eldora );
   bit_and( Beatrice.Ontonagon, Fennimore.Ontonagon, Flasher );
   bit_and( Beatrice.Punaluu, Fennimore.Punaluu, Verndale );
   bit_and( Beatrice.Tindall, Fennimore.Tindall, Dagsboro );
   bit_and( Beatrice.Hiawassee, Fennimore.Hiawassee, Fosston );
   bit_and( Beatrice.Point, Fennimore.Point, Downs );
   bit_and( Beatrice.Wamesit, Fennimore.Wamesit, Denby );
}
table Crestone {
   reads {
      Fennimore.Hobergs : exact;
   }
   actions {
      Rockdell;
   }
   default_action : Rockdell(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Sturgeon {
   apply( Crestone );
}
control DeepGap {
   apply( Hanks );
}
table Kahua {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : ternary;
      Fennimore.Wyncote : ternary;
      Fennimore.Allen : ternary;
      Fennimore.Ontonagon : ternary;
      Fennimore.Punaluu : ternary;
      Fennimore.Tindall : ternary;
      Fennimore.Hiawassee : ternary;
      Fennimore.Point : ternary;
      Fennimore.Wamesit : ternary;
   }
   actions {
      Helen;
   }
   size : 512;
}
control Walnut {
   apply( Kahua );
}
@pragma ways 4
table Fishers {
   reads {
      Fennimore.Hobergs : exact;
      Beatrice.Hallwood : exact;
      Beatrice.Wyncote : exact;
      Beatrice.Allen : exact;
      Beatrice.Ontonagon : exact;
      Beatrice.Punaluu : exact;
      Beatrice.Tindall : exact;
      Beatrice.Hiawassee : exact;
      Beatrice.Point : exact;
      Beatrice.Wamesit : exact;
   }
   actions {
      Helen;
   }
   size : 8192;
}
action Bellmead( Redvale, Theta, Sabana, Millsboro, Bayonne, Pineridge, Bryan, Grapevine, Silvertip ) {
   bit_and( Beatrice.Hallwood, Fennimore.Hallwood, Redvale );
   bit_and( Beatrice.Wyncote, Fennimore.Wyncote, Theta );
   bit_and( Beatrice.Allen, Fennimore.Allen, Sabana );
   bit_and( Beatrice.Ontonagon, Fennimore.Ontonagon, Millsboro );
   bit_and( Beatrice.Punaluu, Fennimore.Punaluu, Bayonne );
   bit_and( Beatrice.Tindall, Fennimore.Tindall, Pineridge );
   bit_and( Beatrice.Hiawassee, Fennimore.Hiawassee, Bryan );
   bit_and( Beatrice.Point, Fennimore.Point, Grapevine );
   bit_and( Beatrice.Wamesit, Fennimore.Wamesit, Silvertip );
}
table Glenvil {
   reads {
      Fennimore.Hobergs : exact;
   }
   actions {
      Bellmead;
   }
   default_action : Bellmead(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Madera {
   apply( Glenvil );
}
control Arcanum {
   apply( Fishers );
}
table Hammond {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : ternary;
      Fennimore.Wyncote : ternary;
      Fennimore.Allen : ternary;
      Fennimore.Ontonagon : ternary;
      Fennimore.Punaluu : ternary;
      Fennimore.Tindall : ternary;
      Fennimore.Hiawassee : ternary;
      Fennimore.Point : ternary;
      Fennimore.Wamesit : ternary;
   }
   actions {
      Helen;
   }
   size : 512;
}
control Savery {
   apply( Hammond );
}
@pragma ways 4
table Parnell {
   reads {
      Fennimore.Hobergs : exact;
      Beatrice.Hallwood : exact;
      Beatrice.Wyncote : exact;
      Beatrice.Allen : exact;
      Beatrice.Ontonagon : exact;
      Beatrice.Punaluu : exact;
      Beatrice.Tindall : exact;
      Beatrice.Hiawassee : exact;
      Beatrice.Point : exact;
      Beatrice.Wamesit : exact;
   }
   actions {
      Helen;
   }
   size : 8192;
}
action Mackey( Squire, Azusa, Sparland, Tillson, LeSueur, Wausaukee, Onset, Bratt, Idylside ) {
   bit_and( Beatrice.Hallwood, Fennimore.Hallwood, Squire );
   bit_and( Beatrice.Wyncote, Fennimore.Wyncote, Azusa );
   bit_and( Beatrice.Allen, Fennimore.Allen, Sparland );
   bit_and( Beatrice.Ontonagon, Fennimore.Ontonagon, Tillson );
   bit_and( Beatrice.Punaluu, Fennimore.Punaluu, LeSueur );
   bit_and( Beatrice.Tindall, Fennimore.Tindall, Wausaukee );
   bit_and( Beatrice.Hiawassee, Fennimore.Hiawassee, Onset );
   bit_and( Beatrice.Point, Fennimore.Point, Bratt );
   bit_and( Beatrice.Wamesit, Fennimore.Wamesit, Idylside );
}
table Nanakuli {
   reads {
      Fennimore.Hobergs : exact;
   }
   actions {
      Mackey;
   }
   default_action : Mackey(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Comptche {
   apply( Nanakuli );
}
control Absecon {
   apply( Parnell );
}
table DeKalb {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : ternary;
      Fennimore.Wyncote : ternary;
      Fennimore.Allen : ternary;
      Fennimore.Ontonagon : ternary;
      Fennimore.Punaluu : ternary;
      Fennimore.Tindall : ternary;
      Fennimore.Hiawassee : ternary;
      Fennimore.Point : ternary;
      Fennimore.Wamesit : ternary;
   }
   actions {
      Helen;
   }
   size : 512;
}
control Dustin {
   apply( DeKalb );
}
@pragma ways 4
table NewTrier {
   reads {
      Fennimore.Hobergs : exact;
      Beatrice.Hallwood : exact;
      Beatrice.Wyncote : exact;
      Beatrice.Allen : exact;
      Beatrice.Ontonagon : exact;
      Beatrice.Punaluu : exact;
      Beatrice.Tindall : exact;
      Beatrice.Hiawassee : exact;
      Beatrice.Point : exact;
      Beatrice.Wamesit : exact;
   }
   actions {
      Helen;
   }
   size : 4096;
}
action Falls( Randle, Elburn, Neshaminy, Aplin, Sandstone, AquaPark, Lincroft, Bulverde, Hewins ) {
   bit_and( Beatrice.Hallwood, Fennimore.Hallwood, Randle );
   bit_and( Beatrice.Wyncote, Fennimore.Wyncote, Elburn );
   bit_and( Beatrice.Allen, Fennimore.Allen, Neshaminy );
   bit_and( Beatrice.Ontonagon, Fennimore.Ontonagon, Aplin );
   bit_and( Beatrice.Punaluu, Fennimore.Punaluu, Sandstone );
   bit_and( Beatrice.Tindall, Fennimore.Tindall, AquaPark );
   bit_and( Beatrice.Hiawassee, Fennimore.Hiawassee, Lincroft );
   bit_and( Beatrice.Point, Fennimore.Point, Bulverde );
   bit_and( Beatrice.Wamesit, Fennimore.Wamesit, Hewins );
}
table Wellsboro {
   reads {
      Fennimore.Hobergs : exact;
   }
   actions {
      Falls;
   }
   default_action : Falls(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Shields {
   apply( Wellsboro );
}
control Crooks {
   apply( NewTrier );
}
table Rockville {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : ternary;
      Fennimore.Wyncote : ternary;
      Fennimore.Allen : ternary;
      Fennimore.Ontonagon : ternary;
      Fennimore.Punaluu : ternary;
      Fennimore.Tindall : ternary;
      Fennimore.Hiawassee : ternary;
      Fennimore.Point : ternary;
      Fennimore.Wamesit : ternary;
   }
   actions {
      Helen;
   }
   size : 512;
}
control Kenney {
   apply( Rockville );
}
@pragma ways 4
table Salduro {
   reads {
      Fennimore.Hobergs : exact;
      Beatrice.Hallwood : exact;
      Beatrice.Wyncote : exact;
      Beatrice.Allen : exact;
      Beatrice.Ontonagon : exact;
      Beatrice.Punaluu : exact;
      Beatrice.Tindall : exact;
      Beatrice.Hiawassee : exact;
      Beatrice.Point : exact;
      Beatrice.Wamesit : exact;
   }
   actions {
      Helen;
   }
   size : 4096;
}
action Deering( Miltona, Coachella, Arnold, Ironside, Kaolin, Melstrand, Occoquan, Waubun, Plato ) {
   bit_and( Beatrice.Hallwood, Fennimore.Hallwood, Miltona );
   bit_and( Beatrice.Wyncote, Fennimore.Wyncote, Coachella );
   bit_and( Beatrice.Allen, Fennimore.Allen, Arnold );
   bit_and( Beatrice.Ontonagon, Fennimore.Ontonagon, Ironside );
   bit_and( Beatrice.Punaluu, Fennimore.Punaluu, Kaolin );
   bit_and( Beatrice.Tindall, Fennimore.Tindall, Melstrand );
   bit_and( Beatrice.Hiawassee, Fennimore.Hiawassee, Occoquan );
   bit_and( Beatrice.Point, Fennimore.Point, Waubun );
   bit_and( Beatrice.Wamesit, Fennimore.Wamesit, Plato );
}
table Eastover {
   reads {
      Fennimore.Hobergs : exact;
   }
   actions {
      Deering;
   }
   default_action : Deering(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Sewanee {
   apply( Eastover );
}
control Wakita {
   apply( Salduro );
}
table Amherst {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : ternary;
      Fennimore.Wyncote : ternary;
      Fennimore.Allen : ternary;
      Fennimore.Ontonagon : ternary;
      Fennimore.Punaluu : ternary;
      Fennimore.Tindall : ternary;
      Fennimore.Hiawassee : ternary;
      Fennimore.Point : ternary;
      Fennimore.Wamesit : ternary;
   }
   actions {
      Helen;
   }
   size : 512;
}
control Honokahua {
   apply( Amherst );
}
   metadata Disney Glenmora;
   action Davant( Cragford ) {
          max( Glenmora.Mullins, Glenmora.Mullins, Cragford );
   }
   action Casnovia() { max( LaJara.Mullins, Glenmora.Mullins, LaJara.Mullins ); } table Henderson { actions { Casnovia; } default_action : Casnovia; size : 1; } control Rollins { apply( Henderson ); }
@pragma ways 4
table Ellicott {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : exact;
      Fennimore.Wyncote : exact;
      Fennimore.Allen : exact;
      Fennimore.Ontonagon : exact;
      Fennimore.Punaluu : exact;
      Fennimore.Tindall : exact;
      Fennimore.Hiawassee : exact;
      Fennimore.Point : exact;
      Fennimore.Wamesit : exact;
   }
   actions {
      Davant;
   }
   size : 4096;
}
control Lecompte {
   apply( Ellicott );
}
table Hopedale {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : ternary;
      Fennimore.Wyncote : ternary;
      Fennimore.Allen : ternary;
      Fennimore.Ontonagon : ternary;
      Fennimore.Punaluu : ternary;
      Fennimore.Tindall : ternary;
      Fennimore.Hiawassee : ternary;
      Fennimore.Point : ternary;
      Fennimore.Wamesit : ternary;
   }
   actions {
      Davant;
   }
   size : 4096;
}
control Fairlee {
   apply( Hopedale );
}
@pragma pa_no_init ingress Hurst.Hallwood
@pragma pa_no_init ingress Hurst.Wyncote
@pragma pa_no_init ingress Hurst.Allen
@pragma pa_no_init ingress Hurst.Ontonagon
@pragma pa_no_init ingress Hurst.Punaluu
@pragma pa_no_init ingress Hurst.Tindall
@pragma pa_no_init ingress Hurst.Hiawassee
@pragma pa_no_init ingress Hurst.Point
@pragma pa_no_init ingress Hurst.Wamesit
metadata Temple Hurst;
@pragma ways 4
table Blencoe {
   reads {
      Fennimore.Hobergs : exact;
      Hurst.Hallwood : exact;
      Hurst.Wyncote : exact;
      Hurst.Allen : exact;
      Hurst.Ontonagon : exact;
      Hurst.Punaluu : exact;
      Hurst.Tindall : exact;
      Hurst.Hiawassee : exact;
      Hurst.Point : exact;
      Hurst.Wamesit : exact;
   }
   actions {
      Davant;
   }
   size : 4096;
}
action Tolleson( Bowlus, Royston, Laurie, Sudden, WestLawn, Karluk, LaPointe, Sprout, Newfield ) {
   bit_and( Hurst.Hallwood, Fennimore.Hallwood, Bowlus );
   bit_and( Hurst.Wyncote, Fennimore.Wyncote, Royston );
   bit_and( Hurst.Allen, Fennimore.Allen, Laurie );
   bit_and( Hurst.Ontonagon, Fennimore.Ontonagon, Sudden );
   bit_and( Hurst.Punaluu, Fennimore.Punaluu, WestLawn );
   bit_and( Hurst.Tindall, Fennimore.Tindall, Karluk );
   bit_and( Hurst.Hiawassee, Fennimore.Hiawassee, LaPointe );
   bit_and( Hurst.Point, Fennimore.Point, Sprout );
   bit_and( Hurst.Wamesit, Fennimore.Wamesit, Newfield );
}
table Elysburg {
   reads {
      Fennimore.Hobergs : exact;
   }
   actions {
      Tolleson;
   }
   default_action : Tolleson(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Edmondson {
   apply( Elysburg );
}
control Nichols {
   apply( Blencoe );
}
table Avondale {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : ternary;
      Fennimore.Wyncote : ternary;
      Fennimore.Allen : ternary;
      Fennimore.Ontonagon : ternary;
      Fennimore.Punaluu : ternary;
      Fennimore.Tindall : ternary;
      Fennimore.Hiawassee : ternary;
      Fennimore.Point : ternary;
      Fennimore.Wamesit : ternary;
   }
   actions {
      Davant;
   }
   size : 512;
}
control DeGraff {
   apply( Avondale );
}
@pragma ways 4
table Placid {
   reads {
      Fennimore.Hobergs : exact;
      Hurst.Hallwood : exact;
      Hurst.Wyncote : exact;
      Hurst.Allen : exact;
      Hurst.Ontonagon : exact;
      Hurst.Punaluu : exact;
      Hurst.Tindall : exact;
      Hurst.Hiawassee : exact;
      Hurst.Point : exact;
      Hurst.Wamesit : exact;
   }
   actions {
      Davant;
   }
   size : 4096;
}
action LaSal( Lushton, Terlingua, Mahomet, Cricket, LasLomas, Knolls, Bicknell, Pilottown, Locke ) {
   bit_and( Hurst.Hallwood, Fennimore.Hallwood, Lushton );
   bit_and( Hurst.Wyncote, Fennimore.Wyncote, Terlingua );
   bit_and( Hurst.Allen, Fennimore.Allen, Mahomet );
   bit_and( Hurst.Ontonagon, Fennimore.Ontonagon, Cricket );
   bit_and( Hurst.Punaluu, Fennimore.Punaluu, LasLomas );
   bit_and( Hurst.Tindall, Fennimore.Tindall, Knolls );
   bit_and( Hurst.Hiawassee, Fennimore.Hiawassee, Bicknell );
   bit_and( Hurst.Point, Fennimore.Point, Pilottown );
   bit_and( Hurst.Wamesit, Fennimore.Wamesit, Locke );
}
table Purves {
   reads {
      Fennimore.Hobergs : exact;
   }
   actions {
      LaSal;
   }
   default_action : LaSal(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Arion {
   apply( Purves );
}
control Paxson {
   apply( Placid );
}
table Mekoryuk {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : ternary;
      Fennimore.Wyncote : ternary;
      Fennimore.Allen : ternary;
      Fennimore.Ontonagon : ternary;
      Fennimore.Punaluu : ternary;
      Fennimore.Tindall : ternary;
      Fennimore.Hiawassee : ternary;
      Fennimore.Point : ternary;
      Fennimore.Wamesit : ternary;
   }
   actions {
      Davant;
   }
   size : 512;
}
control CleElum {
   apply( Mekoryuk );
}
@pragma ways 4
table Angus {
   reads {
      Fennimore.Hobergs : exact;
      Hurst.Hallwood : exact;
      Hurst.Wyncote : exact;
      Hurst.Allen : exact;
      Hurst.Ontonagon : exact;
      Hurst.Punaluu : exact;
      Hurst.Tindall : exact;
      Hurst.Hiawassee : exact;
      Hurst.Point : exact;
      Hurst.Wamesit : exact;
   }
   actions {
      Davant;
   }
   size : 4096;
}
action Whatley( Lilymoor, Uhland, Kaufman, Yardville, Elihu, Furman, Grovetown, Oldsmar, Blossburg ) {
   bit_and( Hurst.Hallwood, Fennimore.Hallwood, Lilymoor );
   bit_and( Hurst.Wyncote, Fennimore.Wyncote, Uhland );
   bit_and( Hurst.Allen, Fennimore.Allen, Kaufman );
   bit_and( Hurst.Ontonagon, Fennimore.Ontonagon, Yardville );
   bit_and( Hurst.Punaluu, Fennimore.Punaluu, Elihu );
   bit_and( Hurst.Tindall, Fennimore.Tindall, Furman );
   bit_and( Hurst.Hiawassee, Fennimore.Hiawassee, Grovetown );
   bit_and( Hurst.Point, Fennimore.Point, Oldsmar );
   bit_and( Hurst.Wamesit, Fennimore.Wamesit, Blossburg );
}
table Macedonia {
   reads {
      Fennimore.Hobergs : exact;
   }
   actions {
      Whatley;
   }
   default_action : Whatley(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control TenSleep {
   apply( Macedonia );
}
control ElVerano {
   apply( Angus );
}
table Exira {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : ternary;
      Fennimore.Wyncote : ternary;
      Fennimore.Allen : ternary;
      Fennimore.Ontonagon : ternary;
      Fennimore.Punaluu : ternary;
      Fennimore.Tindall : ternary;
      Fennimore.Hiawassee : ternary;
      Fennimore.Point : ternary;
      Fennimore.Wamesit : ternary;
   }
   actions {
      Davant;
   }
   size : 512;
}
control Lithonia {
   apply( Exira );
}
@pragma ways 4
table Clearlake {
   reads {
      Fennimore.Hobergs : exact;
      Hurst.Hallwood : exact;
      Hurst.Wyncote : exact;
      Hurst.Allen : exact;
      Hurst.Ontonagon : exact;
      Hurst.Punaluu : exact;
      Hurst.Tindall : exact;
      Hurst.Hiawassee : exact;
      Hurst.Point : exact;
      Hurst.Wamesit : exact;
   }
   actions {
      Davant;
   }
   size : 4096;
}
action ElmCity( Ridgeview, Nordheim, Hendley, Renfroe, Claysburg, Cornville, Caballo, Kentwood, Scottdale ) {
   bit_and( Hurst.Hallwood, Fennimore.Hallwood, Ridgeview );
   bit_and( Hurst.Wyncote, Fennimore.Wyncote, Nordheim );
   bit_and( Hurst.Allen, Fennimore.Allen, Hendley );
   bit_and( Hurst.Ontonagon, Fennimore.Ontonagon, Renfroe );
   bit_and( Hurst.Punaluu, Fennimore.Punaluu, Claysburg );
   bit_and( Hurst.Tindall, Fennimore.Tindall, Cornville );
   bit_and( Hurst.Hiawassee, Fennimore.Hiawassee, Caballo );
   bit_and( Hurst.Point, Fennimore.Point, Kentwood );
   bit_and( Hurst.Wamesit, Fennimore.Wamesit, Scottdale );
}
table Brawley {
   reads {
      Fennimore.Hobergs : exact;
   }
   actions {
      ElmCity;
   }
   default_action : ElmCity(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Hotevilla {
   apply( Brawley );
}
control Seaside {
   apply( Clearlake );
}
table Cusick {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : ternary;
      Fennimore.Wyncote : ternary;
      Fennimore.Allen : ternary;
      Fennimore.Ontonagon : ternary;
      Fennimore.Punaluu : ternary;
      Fennimore.Tindall : ternary;
      Fennimore.Hiawassee : ternary;
      Fennimore.Point : ternary;
      Fennimore.Wamesit : ternary;
   }
   actions {
      Davant;
   }
   size : 512;
}
control Armstrong {
   apply( Cusick );
}
@pragma ways 4
table Wymer {
   reads {
      Fennimore.Hobergs : exact;
      Hurst.Hallwood : exact;
      Hurst.Wyncote : exact;
      Hurst.Allen : exact;
      Hurst.Ontonagon : exact;
      Hurst.Punaluu : exact;
      Hurst.Tindall : exact;
      Hurst.Hiawassee : exact;
      Hurst.Point : exact;
      Hurst.Wamesit : exact;
   }
   actions {
      Davant;
   }
   size : 4096;
}
action FulksRun( Fernway, FortShaw, LaPalma, Browning, Copemish, Hodge, Burgdorf, Grinnell, Blakeley ) {
   bit_and( Hurst.Hallwood, Fennimore.Hallwood, Fernway );
   bit_and( Hurst.Wyncote, Fennimore.Wyncote, FortShaw );
   bit_and( Hurst.Allen, Fennimore.Allen, LaPalma );
   bit_and( Hurst.Ontonagon, Fennimore.Ontonagon, Browning );
   bit_and( Hurst.Punaluu, Fennimore.Punaluu, Copemish );
   bit_and( Hurst.Tindall, Fennimore.Tindall, Hodge );
   bit_and( Hurst.Hiawassee, Fennimore.Hiawassee, Burgdorf );
   bit_and( Hurst.Point, Fennimore.Point, Grinnell );
   bit_and( Hurst.Wamesit, Fennimore.Wamesit, Blakeley );
}
table Breda {
   reads {
      Fennimore.Hobergs : exact;
   }
   actions {
      FulksRun;
   }
   default_action : FulksRun(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Mynard {
   apply( Breda );
}
control Opelousas {
   apply( Wymer );
}
table Osage {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : ternary;
      Fennimore.Wyncote : ternary;
      Fennimore.Allen : ternary;
      Fennimore.Ontonagon : ternary;
      Fennimore.Punaluu : ternary;
      Fennimore.Tindall : ternary;
      Fennimore.Hiawassee : ternary;
      Fennimore.Point : ternary;
      Fennimore.Wamesit : ternary;
   }
   actions {
      Davant;
   }
   size : 512;
}
control Brunson {
   apply( Osage );
}
@pragma ways 4
table Bavaria {
   reads {
      Fennimore.Hobergs : exact;
      Hurst.Hallwood : exact;
      Hurst.Wyncote : exact;
      Hurst.Allen : exact;
      Hurst.Ontonagon : exact;
      Hurst.Punaluu : exact;
      Hurst.Tindall : exact;
      Hurst.Hiawassee : exact;
      Hurst.Point : exact;
      Hurst.Wamesit : exact;
   }
   actions {
      Davant;
   }
   size : 4096;
}
action Lutts( Foster, CityView, Papeton, Addicks, Counce, Cowan, RioPecos, Brinson, Darden ) {
   bit_and( Hurst.Hallwood, Fennimore.Hallwood, Foster );
   bit_and( Hurst.Wyncote, Fennimore.Wyncote, CityView );
   bit_and( Hurst.Allen, Fennimore.Allen, Papeton );
   bit_and( Hurst.Ontonagon, Fennimore.Ontonagon, Addicks );
   bit_and( Hurst.Punaluu, Fennimore.Punaluu, Counce );
   bit_and( Hurst.Tindall, Fennimore.Tindall, Cowan );
   bit_and( Hurst.Hiawassee, Fennimore.Hiawassee, RioPecos );
   bit_and( Hurst.Point, Fennimore.Point, Brinson );
   bit_and( Hurst.Wamesit, Fennimore.Wamesit, Darden );
}
table Ledoux {
   reads {
      Fennimore.Hobergs : exact;
   }
   actions {
      Lutts;
   }
   default_action : Lutts(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Endeavor {
   apply( Ledoux );
}
control Kotzebue {
   apply( Bavaria );
}
table Berwyn {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : ternary;
      Fennimore.Wyncote : ternary;
      Fennimore.Allen : ternary;
      Fennimore.Ontonagon : ternary;
      Fennimore.Punaluu : ternary;
      Fennimore.Tindall : ternary;
      Fennimore.Hiawassee : ternary;
      Fennimore.Point : ternary;
      Fennimore.Wamesit : ternary;
   }
   actions {
      Davant;
   }
   size : 512;
}
control Equality {
   apply( Berwyn );
}
@pragma ways 4
table Judson {
   reads {
      Fennimore.Hobergs : exact;
      Hurst.Hallwood : exact;
      Hurst.Wyncote : exact;
      Hurst.Allen : exact;
      Hurst.Ontonagon : exact;
      Hurst.Punaluu : exact;
      Hurst.Tindall : exact;
      Hurst.Hiawassee : exact;
      Hurst.Point : exact;
      Hurst.Wamesit : exact;
   }
   actions {
      Davant;
   }
   size : 4096;
}
action Abbott( Hansell, Covington, Buckholts, Portal, Arvonia, Horatio, SandCity, Calhan, Salome ) {
   bit_and( Hurst.Hallwood, Fennimore.Hallwood, Hansell );
   bit_and( Hurst.Wyncote, Fennimore.Wyncote, Covington );
   bit_and( Hurst.Allen, Fennimore.Allen, Buckholts );
   bit_and( Hurst.Ontonagon, Fennimore.Ontonagon, Portal );
   bit_and( Hurst.Punaluu, Fennimore.Punaluu, Arvonia );
   bit_and( Hurst.Tindall, Fennimore.Tindall, Horatio );
   bit_and( Hurst.Hiawassee, Fennimore.Hiawassee, SandCity );
   bit_and( Hurst.Point, Fennimore.Point, Calhan );
   bit_and( Hurst.Wamesit, Fennimore.Wamesit, Salome );
}
table Kinsey {
   reads {
      Fennimore.Hobergs : exact;
   }
   actions {
      Abbott;
   }
   default_action : Abbott(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Menomonie {
   apply( Kinsey );
}
control Brinkman {
   apply( Judson );
}
table Udall {
   reads {
      Fennimore.Hobergs : exact;
      Fennimore.Hallwood : ternary;
      Fennimore.Wyncote : ternary;
      Fennimore.Allen : ternary;
      Fennimore.Ontonagon : ternary;
      Fennimore.Punaluu : ternary;
      Fennimore.Tindall : ternary;
      Fennimore.Hiawassee : ternary;
      Fennimore.Point : ternary;
      Fennimore.Wamesit : ternary;
   }
   actions {
      Davant;
   }
   size : 512;
}
control Pineland {
   apply( Udall );
}
action Millbrae( Whigham ) {
   modify_field( Holtville.Manteo, Whigham );
   bit_or( Woodfield.BigArm, Conklin.Mishawaka, 0x80 );
}
action Hickox( Marcus ) {
   modify_field( Holtville.Manteo, Marcus );
   bit_or( WestPike.Waldport, Conklin.Mishawaka, 0x80 );
}
table Eastwood {
   reads {
      Conklin.Mishawaka mask 0x80 : exact;
      Woodfield.valid : exact;
      WestPike.valid : exact;
   }
   actions {
      Millbrae;
      Hickox;
   }
   size : 8;
}
action Pettigrew() {
   modify_field( Woodfield.BigArm, 0, 0x80 );
}
action Pumphrey() {
   modify_field( WestPike.Waldport, 0, 0x80 );
}
action Ocheyedan(Kinston) {
   modify_field( Woodfield.BigArm, Kinston, 0x80 );
   modify_field( Holtville.Colona, 0);
}
action Bieber(Karlsruhe) {
   modify_field( WestPike.Waldport, Karlsruhe, 0x80 );
   modify_field( Holtville.Colona, 0);
}
table Summit {
   reads {
     Holtville.Manteo : exact;
     Woodfield.valid : exact;
     WestPike.valid : exact;
     Conklin.Mishawaka mask 0x7f : ternary;
   }
   actions {
      Pettigrew;
      Pumphrey;
      Ocheyedan;
      Bieber;
   }
   size : 16;
}
header_type Between {
	fields {
		Hines : 7;
		Nuiqsut : 32;
	}
}
@pragma pa_container_size egress Gibson.Hines 32
metadata Between Gibson;
field_list Frederic {
   Gibson.Hines;
}
field_list Ramos {
   Chalco.Ludell;
}
field_list_calculation Leland {
    input {
        Ramos;
    }
    algorithm : identity;
    output_width : 51;
}
action Covert( Paradis ) {
   modify_field( Resaca.Tavistock, Paradis );
   modify_field( Resaca.Petrey, Paradis );
}
table LeeCreek {
   reads {
      Madison.Gerlach : ternary;
      Fennimore.Deerwood : ternary;
      Fennimore.Emerado : ternary;
      Kilbourne.Ripley : ternary;
      Langlois.Hagewood : ternary;
      Langlois.Tinaja : ternary;
      Heflin.Tontogany : ternary;
      Heflin.Ashwood : ternary;
   }
   actions {
      Covert;
   }
   default_action : Covert(0);
   size : 2048;
}
control Gambrill {
    apply( LeeCreek );
}
meter Cutten {
   type : bytes;
   static : Cooter;
   instance_count : 128;
}
action Mabelvale( Motley ) {
   execute_meter( Cutten, Motley, Resaca.Plano );
}
table Cooter {
   reads {
      Resaca.Tavistock : exact;
   }
   actions {
      Mabelvale;
   }
   size : 128;
}
control Flats {
   apply( Cooter );
}
action Emajagua() {
   modify_field( Gibson.Hines, Resaca.Tavistock );
   modify_field( Gibson.Nuiqsut, Chalco.Ludell );
   clone_ingress_pkt_to_egress( Resaca.Petrey, Frederic );
}
table Chatfield {
   reads {
      Resaca.Plano : exact;
   }
   actions {
      Emajagua;
   }
   size : 2;
}
control Parthenon {
   if( Resaca.Tavistock != 0 ) {
      apply( Chatfield );
   }
}
action_selector Higgins {
    selection_key : Leland;
    selection_mode : resilient;
}
action Tahuya( Skiatook ) {
   bit_or( Resaca.Petrey, Resaca.Petrey, Skiatook );
}
action_profile Midville {
   actions {
      Tahuya;
   }
   size : 512;
   dynamic_action_selection : Higgins;
}
table Palmdale {
   reads {
      Resaca.Tavistock : exact;
   }
   action_profile : Midville;
   size : 128;
}
control Bodcaw {
   apply( Palmdale );
}
action Quinault() {
   modify_field( Holtville.Servia, 0 );
   modify_field( Holtville.Goldenrod, 3 );
}
action Fristoe( Ekwok, Caborn, Keyes, Weskan, Safford ) {
   modify_field( Holtville.Servia, 0 );
   modify_field( Holtville.Goldenrod, 4 );
   modify_field( Holtville.Pickett, Ekwok );
   modify_field( Holtville.Doddridge, Caborn );
   modify_field( Holtville.Maryville, Keyes );
   modify_field( Holtville.Hackett, Weskan );
   modify_field( Holtville.Valsetz, 0x4 );
   modify_field( Holtville.Berrydale, 0x5 );
   modify_field( Holtville.Picabo, Safford );
}
action Govan() {
   modify_field( Holtville.Champlin, 1 );
   modify_field( Holtville.Servia, 0 );
   modify_field( Holtville.Goldenrod, 2 );
   modify_field( Holtville.Donald, 1 );
}
table Fabens {
   reads {
      Gibson.Hines : exact;
   }
   actions {
      Quinault;
      Fristoe;
      Govan;
   }
   size : 128;
}
control ElPortal {
   if( ( (eg_intr_md_from_parser_aux.clone_src == CLONED_FROM_INGRESS) or (eg_intr_md_from_parser_aux.clone_src == CLONED_FROM_EGRESS) or (eg_intr_md_from_parser_aux.clone_src == COALESCED) ) ) {
      apply( Fabens );
   }
}
control ingress {
   Kinard();
   Corum();
   if( Madison.Stella != 0 ) {
      Curlew();
   }
   Carnegie();
   if( Madison.Stella != 0 ) {
      Baytown();
      Hercules();
   }
   Emmorton();
   Coulter();
   Knoke();
   NewAlbin();
   Spiro();
   if( Madison.Stella != 0 ) {
      Nathan();
   }
   Fairborn();
   Westpoint();
   Oshoto();
   Alburnett();
   Sturgeon();
   if( Madison.Stella != 0 ) {
      Naylor();
   }
   Chandalar();
   Waseca();
   DeepGap();
   Madera();
   Gambrill();
   if( Madison.Stella != 0 ) {
      Shubert();
   } else {
      if( valid( Currie ) ) {
         Conda();
      }
   }
   Arcanum();
   Comptche();
   if( Holtville.Servia != 2 ) {
      Lublin();
   }
   Pocopson();
   Bodcaw();
   if( Madison.Stella != 0 ) {
      Perryton();
   }
   Malinta();
   Windber();
   Absecon();
   Lowland();
   if( Currie.valid == 0 ) {
      Whitakers();
   }
   if( Holtville.LaVale == 0 and Holtville.Servia != 2 ) {
      Casper();
      if( Holtville.Blackwood == 511 ) {
         Amasa();
      }
   }
   Leacock();
   Flats();
   if( Holtville.Servia == 0 ) {
      apply(Eastwood);
   }
   Salus();
   if( Holtville.LaVale == 0 ) {
      Ferry();
   }
   if ( Holtville.LaVale == 0 ) {
      Markville();
   }
   if( Madison.Stella != 0 ) {
      Winfall();
   }
   Sunflower();
   if( Holtville.LaVale == 0 ) {
      Everetts();
   }
   Tidewater();
   if( valid( Nicodemus[0] ) ) {
      Sarasota();
   }
   Parthenon();
   Roachdale();
}
control egress {
   if( ( (eg_intr_md_from_parser_aux.clone_src == CLONED_FROM_INGRESS) or (eg_intr_md_from_parser_aux.clone_src == CLONED_FROM_EGRESS) or (eg_intr_md_from_parser_aux.clone_src == COALESCED) ) ) {
      ElPortal();
   } else {
      MontIda();
      Stampley();
      Nutria();
      if( Holtville.Servia == 0 ) {
         apply( Summit );
      }
   }
   Gifford();
   if( ( (eg_intr_md_from_parser_aux.clone_src == NOT_CLONED) ) ) {
      if( ( Holtville.Donald == 0 ) and ( Holtville.Servia != 2 ) ) {
         Seaford();
      }
      Ambler();
   }
}
