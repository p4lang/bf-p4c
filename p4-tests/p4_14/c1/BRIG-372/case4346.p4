// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 104221

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
header_type Heidrick {
	fields {
		Orrville : 16;
		Caspiana : 16;
		Cornville : 8;
		Cushing : 8;
		Piney : 8;
		Dyess : 8;
		Umkumiut : 3;
		Edinburgh : 3;
		Willard : 1;
		Chavies : 3;
		Wellton : 3;
		Galestown : 6;
	}
}
header_type Heavener {
	fields {
		Kaluaaha : 24;
		Silva : 24;
		Jayton : 24;
		Camino : 24;
		Kenvil : 16;
		Marquette : 12;
		Zeeland : 20;
		Hanks : 16;
		Dellslow : 16;
		Correo : 8;
		RioLinda : 8;
		Verdemont : 2;
		Lignite : 1;
		Homeworth : 3;
		CedarKey : 2;
		Hewitt : 1;
		Paxson : 1;
		Ivyland : 1;
		Elimsport : 1;
		Ekwok : 1;
		Kneeland : 1;
		Macon : 1;
		Combine : 1;
		Rendon : 1;
		Cadley : 1;
		Valeene : 1;
		Despard : 1;
		Lumberton : 1;
		NeckCity : 1;
		Kokadjo : 16;
		Keokee : 16;
		Rendville : 8;
	}
}
header_type Gypsum {
	fields {
		Bledsoe : 24;
		Coamo : 24;
		Annandale : 24;
		SantaAna : 24;
		Reynolds : 24;
		Merit : 24;
		Dollar : 1;
		Alsen : 3;
		Westview : 1;
		Monohan : 12;
		Pilottown : 20;
		AvonLake : 16;
		Kelvin : 12;
		Waldport : 12;
		DewyRose : 3;
		Palisades : 1;
		Dalton : 1;
		Kalkaska : 1;
		Schleswig : 1;
		Stratton : 1;
		Ackerly : 8;
		Headland : 12;
		DeSmet : 4;
		Arredondo : 6;
		Lilbert : 10;
		Colonie : 32;
		Keyes : 24;
		Foristell : 8;
		Shobonier : 32;
		Walcott : 9;
		Korbel : 2;
		Fieldon : 1;
		Baytown : 1;
		Pillager : 1;
		Litroe : 1;
		Conger : 1;
		Ellicott : 12;
		Nowlin : 1;
		Ravenwood : 1;
		Wamego : 32;
		Harvey : 32;
		Craigtown : 8;
		FairOaks : 24;
		Overbrook : 24;
	}
}
header_type Gakona {
	fields {
		Spiro : 7;
		BirchBay : 2;
		Corona : 10;
	}
}
header_type Hodge {
	fields {
		Maywood : 7;
		Hartwick : 2;
		Bluff : 10;
		Tamora : 8;
		Eskridge : 6;
		ViewPark : 16;
		Kohrville : 4;
		BoyRiver : 4;
	}
}
header_type Leonore {
	fields {
		Rixford : 8;
		Lafourche : 4;
		Winfall : 1;
	}
}
header_type Melstrand {
	fields {
		Walnut : 32;
		Amazonia : 32;
		Ceiba : 6;
		Termo : 6;
		Monkstown : 16;
	}
}
header_type Talbotton {
	fields {
		Haverford : 128;
		McDaniels : 128;
		Granville : 8;
		Raynham : 11;
		OldTown : 6;
		Empire : 13;
	}
}
header_type Motley {
	fields {
		Lumpkin : 14;
		Knippa : 1;
		Chaffee : 12;
		Tontogany : 1;
		Gotham : 2;
	}
}
header_type DelRosa {
	fields {
		Liberal : 1;
		Sasser : 1;
	}
}
header_type Ladoga {
	fields {
		Peosta : 1;
		NewTrier : 1;
	}
}
header_type Selawik {
	fields {
		Hospers : 2;
	}
}
header_type Biddle {
	fields {
		Raeford : 16;
		Lakota : 11;
	}
}
header_type Jeddo {
	fields {
		BigPiney : 32;
		Pittsboro : 32;
		Corder : 32;
	}
}
header_type Retrop {
	fields {
		Surrency : 32;
		BigRock : 32;
	}
}
header_type Darmstadt {
	fields {
		McClure : 2;
		Nunda : 6;
		Lazear : 3;
		Rocklin : 1;
		Uhland : 1;
		Hibernia : 1;
		Natalia : 3;
		Oakes : 1;
		Tatum : 6;
		Punaluu : 6;
		Dedham : 4;
		Allgood : 5;
	}
}
header_type LewisRun {
	fields {
		Glenvil : 16;
	}
}
header_type Halltown {
	fields {
		Hooven : 14;
		Kensal : 1;
		Sardinia : 1;
	}
}
header_type Amenia {
	fields {
		Corvallis : 14;
		Clermont : 1;
		Somis : 1;
	}
}
header_type Greenbelt {
	fields {
		Asherton : 16;
		Blairsden : 16;
		Micro : 16;
		Robert : 16;
		WarEagle : 16;
		Waucousta : 16;
		Weches : 8;
		Riley : 8;
		Avondale : 8;
		Swenson : 8;
		Angle : 1;
		Lemont : 6;
	}
}
header_type Browndell {
	fields {
		Ovett : 32;
	}
}
header_type Piketon {
	fields {
		Bleecker : 6;
		Lilymoor : 10;
		Bluewater : 4;
		Hagewood : 12;
		Putnam : 2;
		Eudora : 2;
		Langston : 12;
		Tusculum : 8;
		Greenwood : 2;
		Meeker : 3;
		Slocum : 1;
		Lamar : 2;
	}
}
header_type BeeCave {
	fields {
		NantyGlo : 24;
		Browning : 24;
		Virgil : 24;
		Cisne : 24;
		Basic : 16;
	}
}
header_type Pimento {
	fields {
		Bernstein : 3;
		LaPlata : 1;
		Harshaw : 12;
		Houston : 16;
	}
}
header_type Thalmann {
	fields {
		Picacho : 20;
		Barney : 3;
		Domingo : 1;
		BigRiver : 8;
	}
}
header_type Newellton {
	fields {
		Esmond : 4;
		Brinklow : 4;
		ElkNeck : 6;
		Astor : 2;
		Pierre : 16;
		HamLake : 16;
		Konnarock : 3;
		Kingsgate : 13;
		Worthing : 8;
		Roswell : 8;
		Arnold : 16;
		Rayville : 32;
		Kinross : 32;
	}
}
header_type Bostic {
	fields {
		WhiteOwl : 4;
		Miller : 6;
		Hermiston : 2;
		Pollard : 20;
		Scanlon : 16;
		Reinbeck : 8;
		McBrides : 8;
		Saticoy : 128;
		Joaquin : 128;
	}
}
header_type Weiser {
	fields {
		Seaford : 8;
		Camilla : 8;
		Kaibab : 16;
	}
}
header_type Hargis {
	fields {
		Folcroft : 16;
		Engle : 16;
	}
}
header_type Ojibwa {
	fields {
		LeeCity : 32;
		Jackpot : 32;
		Varnado : 4;
		Bayport : 4;
		Allen : 8;
		Hebbville : 16;
		Schroeder : 16;
		Brazos : 16;
	}
}
header_type Remington {
	fields {
		Korona : 16;
		Dagsboro : 16;
	}
}
header_type Brazil {
	fields {
		Louviers : 16;
		RockHall : 16;
		Raiford : 8;
		RyanPark : 8;
		Fleetwood : 16;
	}
}
header_type Glenoma {
	fields {
		Covington : 48;
		Kalvesta : 32;
		Linden : 48;
		Ortley : 32;
	}
}
header_type Moose {
	fields {
		Ravena : 1;
		Wilbraham : 1;
		Kempton : 1;
		McCartys : 1;
		Locke : 1;
		Uniopolis : 3;
		RoyalOak : 5;
		Crown : 3;
		Stilson : 16;
	}
}
header_type Kinsley {
	fields {
		Otsego : 24;
		Moodys : 8;
	}
}
header_type Wolford {
	fields {
		Glassboro : 8;
		Penrose : 24;
		Junior : 24;
		Bacton : 8;
	}
}
@pragma force_match_dependency egress 5
header BeeCave Olcott;
header BeeCave Kipahulu;
@pragma not_deparsed ingress
@pragma not_parsed egress
header Pimento Panola[ 2 ];
@pragma pa_fragment ingress Aynor.Arnold
@pragma pa_fragment egress Aynor.Arnold
@pragma pa_container_size ingress Aynor.Rayville 32
@pragma pa_container_size ingress Aynor.Kinross 32
@pragma pa_container egress Aynor.Kinross 16
@pragma pa_container egress Aynor.Rayville 17
header Newellton Aynor;
@pragma pa_fragment ingress Hennessey.Arnold
@pragma pa_fragment egress Hennessey.Arnold
header Newellton Hennessey;
@pragma pa_container_size egress Antonito.Joaquin 32
@pragma pa_container_size egress Antonito.Saticoy 32
header Bostic Antonito;
@pragma pa_overlay_new_container_stop ingress PineLawn 1
header Bostic PineLawn;
header Hargis ElDorado;
header Hargis Lapel;
header Ojibwa McCracken;
header Remington Brackett;
header Ojibwa Lubec;
header Remington Chugwater;
@pragma pa_container_size egress Leesport.Junior 32
header Wolford Leesport;
header Moose Suarez;
@pragma pa_container_size egress Duster.Bleecker 32
@pragma not_deparsed ingress
@pragma not_parsed egress
header Piketon Duster;
@pragma not_deparsed ingress
@pragma not_parsed egress
header BeeCave Canalou;
parser start {
   return select(current(96, 16)) {
      0xBF00 : Wabuska;
      default : Brush;
   }
}
@pragma dont_trim
@pragma packet_entry
parser start_i2e_mirrored {
   return ingress;
}
@pragma dont_trim
@pragma packet_entry
parser start_e2e_mirrored {
   return ingress;
}
@pragma dont_trim
@pragma packet_entry
parser start_egress {
   return select(current(96, 16)) {
      default : Brush;
      0xBF00 : Glendale;
   }
}
parser Glendale {
   extract( Canalou );
   extract( Duster );
   return Brush;
}
parser Boring {
   extract( Duster );
   return Brush;
}
@pragma force_shift ingress 112
parser Wabuska {
   return Boring;
}
parser Bogota {
   set_metadata(Coupland.Umkumiut, 5);
   return ingress;
}
parser Hamel {
   set_metadata(Coupland.Umkumiut, 6);
   return ingress;
}
parser Brush {
   extract( Olcott );
   return select( current(0, 8), Olcott.Basic ) {
      0x8100 mask 0xFFFF : Gosnell;
      0x450800 : Valier;
      0x50800 mask 0xFFFFF : Bogota;
      0x0800 mask 0xFFFF : Kahaluu;
      0x6086dd mask 0xF0FFFF : Cotuit;
      0x86dd mask 0xFFFF : Hamel;
      default : ingress;
   }
}
parser Gosnell {
   extract( Panola[0] );
   return select( current(0, 8), Panola[0].Houston ) {
      0x450800 : Valier;
      0x50800 mask 0xFFFFF : Bogota;
      0x0800 mask 0xFFFF : Kahaluu;
      0x6086dd mask 0xF0FFFF : Cotuit;
      0x86dd mask 0xFFFF : Hamel;
      default : ingress;
   }
}
field_list Westboro {
    Aynor.Esmond;
    Aynor.Brinklow;
    Aynor.ElkNeck;
    Aynor.Astor;
    Aynor.Pierre;
    Aynor.HamLake;
    Aynor.Konnarock;
    Aynor.Kingsgate;
    Aynor.Worthing;
    Aynor.Roswell;
    Aynor.Rayville;
    Aynor.Kinross;
}
field_list_calculation Belcher {
    input {
        Westboro;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Aynor.Arnold {
    verify Belcher;
    update Belcher;
}
parser Kahaluu {
   set_metadata(Coupland.Umkumiut, 3);
   set_metadata(Coupland.Galestown, current(8, 6));
   return ingress;
}
parser Valier {
   extract( Aynor );
   set_metadata(Coupland.Cornville, Aynor.Roswell);
   set_metadata(Bigspring.RioLinda, Aynor.Worthing);
   set_metadata(Coupland.Umkumiut, 1);
   return select(Aynor.Kingsgate, Aynor.Roswell) {
      1 : Acree;
      17 : Borup;
      6 : Vidal;
      47 : Gwynn;
      0 mask 0x1fff000 : ingress;
      6 mask 0xff: Crowheart;
      default : Chantilly;
   }
}
parser Crowheart {
   set_metadata(Coupland.Wellton, 5);
   return ingress;
}
parser Chantilly {
   set_metadata(Coupland.Wellton, 1);
   return ingress;
}
parser Cotuit {
   extract( PineLawn );
   set_metadata(Coupland.Cornville, PineLawn.Reinbeck);
   set_metadata(Bigspring.RioLinda, PineLawn.McBrides);
   set_metadata(Coupland.Umkumiut, 2);
   return select(PineLawn.Reinbeck) {
      0x3a : Acree;
      17 : Dorset;
      6 : Vidal;
      default : ingress;
   }
}
parser Borup {
   set_metadata(Coupland.Wellton, 2);
   extract(ElDorado);
   extract(Brackett);
   return select(ElDorado.Engle) {
      4789 : Hodges;
      default : ingress;
    }
}
parser Acree {
   set_metadata( ElDorado.Folcroft, current( 0, 16 ) );
   return ingress;
}
parser Dorset {
   set_metadata(Coupland.Wellton, 2);
   extract(ElDorado);
   extract(Brackett);
   return ingress;
}
parser Vidal {
   set_metadata(Coupland.Wellton, 6);
   extract(ElDorado);
   extract(McCracken);
   return ingress;
}
parser Gerlach {
   set_metadata(Bigspring.CedarKey, 2);
   return select( current(4, 4) ) {
      0x5 : Suntrana;
      default : Delavan;
   }
}
parser Ackley {
   return select( current(0,4) ) {
      0x4 : Gerlach;
      default : ingress;
   }
}
parser Swisher {
   set_metadata(Bigspring.CedarKey, 2);
   return Telegraph;
}
parser Whitefish {
   return select( current(0,4) ) {
      0x6 : Swisher;
      default: ingress;
   }
}
parser Gwynn {
   extract(Suarez);
   return select(Suarez.Ravena, Suarez.Wilbraham, Suarez.Kempton, Suarez.McCartys, Suarez.Locke,
             Suarez.Uniopolis, Suarez.RoyalOak, Suarez.Crown, Suarez.Stilson) {
      0x0800 : Ackley;
      0x86dd : Whitefish;
      default : ingress;
   }
}
parser Hodges {
   extract(Leesport);
   set_metadata(Bigspring.CedarKey, 1);
   return Spearman;
}
field_list Gahanna {
    Hennessey.Esmond;
    Hennessey.Brinklow;
    Hennessey.ElkNeck;
    Hennessey.Astor;
    Hennessey.Pierre;
    Hennessey.HamLake;
    Hennessey.Konnarock;
    Hennessey.Kingsgate;
    Hennessey.Worthing;
    Hennessey.Roswell;
    Hennessey.Rayville;
    Hennessey.Kinross;
}
field_list_calculation Monrovia {
    input {
        Gahanna;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Hennessey.Arnold {
    verify Monrovia;
    update Monrovia;
}
parser Delavan {
   set_metadata(Coupland.Edinburgh, 3);
   return ingress;
}
parser Suntrana {
   extract( Hennessey );
   set_metadata(Coupland.Cushing, Hennessey.Roswell);
   set_metadata(Coupland.Dyess, Hennessey.Worthing);
   set_metadata(Coupland.Edinburgh, 1);
   set_metadata(Nunnelly.Walnut, Hennessey.Rayville);
   set_metadata(Nunnelly.Amazonia, Hennessey.Kinross);
   return select(Hennessey.Kingsgate, Hennessey.Roswell) {
      1 : Wenatchee;
      17 : Herod;
      6 : Heron;
      0 mask 0x1fff000 : ingress;
      6 mask 0xff: Woolwine;
      default : Tillamook;
   }
}
parser Woolwine {
   set_metadata(Coupland.Chavies, 5);
   return ingress;
}
parser Tillamook {
   set_metadata(Coupland.Chavies, 1);
   return ingress;
}
parser Telegraph {
   extract( Antonito );
   set_metadata(Coupland.Cushing, Antonito.Reinbeck);
   set_metadata(Coupland.Dyess, Antonito.McBrides);
   set_metadata(Coupland.Edinburgh, 2);
   set_metadata(Portal.Haverford, Antonito.Saticoy);
   set_metadata(Portal.McDaniels, Antonito.Joaquin);
   return select(Antonito.Reinbeck) {
      0x3a : Wenatchee;
      17 : Herod;
      6 : Heron;
      default : ingress;
   }
}
parser Wenatchee {
   set_metadata( Bigspring.Kokadjo, current( 0, 16 ) );
   return ingress;
}
parser Herod {
   set_metadata( Bigspring.Kokadjo, current( 0, 16 ) );
   set_metadata( Bigspring.Keokee, current( 16, 16 ) );
   set_metadata(Coupland.Chavies, 2);
   return ingress;
}
parser Heron {
   set_metadata( Bigspring.Kokadjo, current( 0, 16 ) );
   set_metadata( Bigspring.Keokee, current( 16, 16 ) );
   set_metadata( Bigspring.Rendville, current( 104, 8 ) );
   set_metadata(Coupland.Chavies, 6);
   extract(Lapel);
   extract(Lubec);
   return ingress;
}
parser Marquand {
   set_metadata(Coupland.Edinburgh, 5);
   return ingress;
}
parser Columbia {
   set_metadata(Coupland.Edinburgh, 6);
   return ingress;
}
parser Spearman {
   extract( Kipahulu );
   set_metadata( Bigspring.Kaluaaha, Kipahulu.NantyGlo );
   set_metadata( Bigspring.Silva, Kipahulu.Browning );
   set_metadata( Bigspring.Kenvil, Kipahulu.Basic );
   return select( current( 0, 8 ), Kipahulu.Basic ) {
      0x450800 : Suntrana;
      0x50800 mask 0xFFFFF : Marquand;
      0x0800 mask 0xFFFF : Delavan;
      0x6086dd mask 0xF0FFFF : Telegraph;
      0x86dd mask 0xFFFF : Columbia;
      default: ingress;
   }
}
@pragma pa_no_init ingress Bigspring.Kaluaaha
@pragma pa_no_init ingress Bigspring.Silva
@pragma pa_no_init ingress Bigspring.Jayton
@pragma pa_no_init ingress Bigspring.Camino
@pragma pa_container_size ingress Bigspring.CedarKey 16
@pragma pa_container_size ingress Bigspring.Ekwok 32
metadata Heavener Bigspring;
@pragma pa_allowed_to_share egress Upalco.Baytown Bellwood.Maywood
@pragma pa_no_init ingress Upalco.Bledsoe
@pragma pa_no_init ingress Upalco.Coamo
@pragma pa_no_init ingress Upalco.Annandale
@pragma pa_no_init ingress Upalco.SantaAna
@pragma pa_container_size ingress Upalco.Colonie 32
@pragma pa_no_overlay ingress Upalco.Pilottown
@pragma pa_no_overlay ingress Upalco.Monohan
@pragma pa_solitary ingress Upalco.Monohan
metadata Gypsum Upalco;
metadata Gakona Aplin;
metadata Hodge Bellwood;
metadata Motley Talmo;
metadata Heidrick Coupland;
metadata Melstrand Nunnelly;
metadata Talbotton Portal;
metadata DelRosa Bozeman;
@pragma pa_container_size ingress ig_intr_md_for_tm.drop_ctl 16
@pragma pa_container_size egress Wakita.NewTrier 8
metadata Ladoga Wakita;
@pragma pa_container ingress Wyanet.Rixford 128
@pragma pa_container ingress Wyanet.Lafourche 128
@pragma pa_allowed_to_share ingress Wyanet.Rixford Wyanet.Lafourche
metadata Leonore Wyanet;
metadata Selawik BigWater;
@pragma pa_container_size ingress Emajagua.Raeford 16
@pragma pa_container_size ingress Emajagua.Lakota 16
metadata Biddle Emajagua;
@pragma pa_no_init ingress Moraine.Surrency
@pragma pa_mutually_exclusive ingress Moraine.Surrency Moraine.BigRock
metadata Retrop Moraine;
metadata Jeddo McAlister;
metadata Darmstadt DeBeque;
metadata LewisRun Poulsbo;
@pragma pa_no_init ingress Hayfork.Hooven
@pragma pa_solitary ingress Hayfork.Sardinia
metadata Halltown Hayfork;
@pragma pa_no_init ingress Rodeo.Corvallis
metadata Amenia Rodeo;
@pragma pa_no_init ingress Starkey.Micro
@pragma pa_no_init ingress Starkey.Robert
metadata Greenbelt Starkey;
metadata Greenbelt Hephzibah;
action MintHill() {
   no_op();
}
action Ripley() {
   modify_field(Bigspring.Hewitt, 1 );
   mark_for_drop();
}
action Vandling() {
   no_op();
}
action Menfro(Jamesport, Munger, Magna, Ringtown, Rodessa ) {
    modify_field(Talmo.Lumpkin, Jamesport);
    modify_field(Talmo.Knippa, Munger);
    modify_field(Talmo.Chaffee, Magna);
    modify_field(Talmo.Tontogany, Ringtown);
    modify_field(Talmo.Gotham, Rodessa);
}
@pragma phase0 1
table Lilly {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Menfro;
    }
    size : 288;
}
control Quivero {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Lilly);
    }
}
action Oronogo(Simla, Carpenter) {
   modify_field( Upalco.Westview, 1 );
   modify_field( Upalco.Ackerly, Simla);
   modify_field( Bigspring.Macon, 1 );
   modify_field( DeBeque.Hibernia, Carpenter );
}
action BelAir() {
   modify_field( Bigspring.Elimsport, 1 );
   modify_field( Bigspring.Rendon, 1 );
}
action Emmorton() {
   modify_field( Bigspring.Macon, 1 );
}
action Revere() {
   modify_field( Bigspring.Macon, 1 );
   modify_field( Bigspring.Cadley, 1 );
}
action Gunter() {
   modify_field( Bigspring.Combine, 1 );
}
action Ivydale() {
   modify_field( Bigspring.Rendon, 1 );
}
counter OreCity {
   type : packets_and_bytes;
   direct : Dialville;
   min_width: 16;
}
table Dialville {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Olcott.NantyGlo : ternary;
      Olcott.Browning : ternary;
   }
   actions {
      Oronogo;
      BelAir;
      Emmorton;
      Gunter;
      Ivydale;
      Revere;
   }
   default_action: MintHill();
   size : 2048;
}
action Chevak() {
   modify_field( Bigspring.Ekwok, 1 );
}
table LunaPier {
   reads {
      Olcott.Virgil : ternary;
      Olcott.Cisne : ternary;
   }
   actions {
      Chevak;
   }
   size : 512;
}
control Counce {
   apply( Dialville ) {
      Oronogo { }
      default {
         Chatcolet();
      }
   }
   apply( LunaPier );
}
action McDougal() {
   modify_field( Nunnelly.Ceiba, Hennessey.ElkNeck );
   modify_field( Portal.OldTown, Antonito.Miller );
   modify_field( Bigspring.Jayton, Kipahulu.Virgil );
   modify_field( Bigspring.Camino, Kipahulu.Cisne );
   modify_field( Bigspring.Correo, Coupland.Cushing );
   modify_field( Bigspring.RioLinda, Coupland.Dyess );
   modify_field( Bigspring.Verdemont, Coupland.Edinburgh, 3 );
   shift_right( Bigspring.Lignite, Coupland.Edinburgh, 2 );
   modify_field( Upalco.DewyRose, 1 );
   modify_field( Starkey.WarEagle, Bigspring.Kokadjo );
   modify_field( Bigspring.Homeworth, Coupland.Chavies );
   modify_field( Starkey.Angle, Coupland.Chavies, 1);
}
action Tchula() {
   modify_field( Bigspring.Valeene, Panola[ 0 ].valid );
   modify_field( Bigspring.CedarKey, 0 );
   modify_field( Nunnelly.Walnut, Aynor.Rayville );
   modify_field( Nunnelly.Amazonia, Aynor.Kinross );
   modify_field( Nunnelly.Ceiba, Aynor.ElkNeck );
   modify_field( Portal.Haverford, PineLawn.Saticoy );
   modify_field( Portal.McDaniels, PineLawn.Joaquin );
   modify_field( Portal.OldTown, PineLawn.Miller );
   modify_field( Bigspring.Kaluaaha, Olcott.NantyGlo );
   modify_field( Bigspring.Silva, Olcott.Browning );
   modify_field( Bigspring.Jayton, Olcott.Virgil );
   modify_field( Bigspring.Camino, Olcott.Cisne );
   modify_field( Bigspring.Kenvil, Olcott.Basic );
   modify_field( Bigspring.Correo, Coupland.Cornville );
   modify_field( Bigspring.Verdemont, Coupland.Umkumiut, 3 );
   shift_right( Bigspring.Lignite, Coupland.Umkumiut, 2 );
   modify_field( DeBeque.Oakes, Panola[0].LaPlata );
   modify_field( Starkey.WarEagle, ElDorado.Folcroft );
   modify_field( Bigspring.Kokadjo, ElDorado.Folcroft );
   modify_field( Bigspring.Keokee, ElDorado.Engle );
   modify_field( Bigspring.Rendville, McCracken.Allen );
   modify_field( Bigspring.Homeworth, Coupland.Wellton );
   modify_field( Starkey.Angle, Coupland.Wellton, 1);
}
table Hines {
   reads {
      Olcott.NantyGlo : exact;
      Olcott.Browning : exact;
      Aynor.Kinross : ternary;
      Bigspring.CedarKey : exact;
   }
   actions {
      McDougal;
      Tchula;
   }
   default_action : Tchula();
   size : 1024;
}
action Honaker(Niota) {
   modify_field( Bigspring.Marquette, Talmo.Chaffee );
   modify_field( Bigspring.Zeeland, Niota);
}
action Wymore( Orrum, Caliente ) {
   modify_field( Bigspring.Marquette, Orrum );
   modify_field( Bigspring.Zeeland, Caliente);
}
action Amherst(Burrel) {
   modify_field( Bigspring.Marquette, Panola[0].Harshaw );
   modify_field( Bigspring.Zeeland, Burrel);
}
action Absarokee() {
   Ripley();
}
table Hilburn {
   reads {
      Talmo.Lumpkin : exact;
      Panola[0] : valid;
      Panola[0].Harshaw : ternary;
   }
   actions {
      Honaker;
      Wymore;
      Amherst;
   }
   default_action : Absarokee();
   size : 4096;
}
action Molino( Littleton ) {
   modify_field( Bigspring.Zeeland, Littleton );
}
action Doral() {
   modify_field( BigWater.Hospers,
                 2 );
}
table Lowden {
   reads {
      Aynor.Rayville : exact;
   }
   actions {
      Molino;
      Doral;
   }
   default_action : Doral;
   size : 4096;
}
action Huffman( Goosport, Denby, Elrosa, Wattsburg ) {
   modify_field( Bigspring.Marquette, Goosport );
   modify_field( Bigspring.Hanks, Goosport );
   modify_field( Bigspring.Ivyland, Wattsburg );
   LasLomas(Denby, Elrosa);
}
action Jigger() {
   modify_field( Bigspring.Paxson, 1 );
}
table Paisley {
   reads {
      Leesport.Junior : exact;
   }
   actions {
      Huffman;
      Jigger;
   }
   size : 4096;
}
action LasLomas(Baltic, Theta) {
   modify_field( Wyanet.Rixford, Baltic );
   modify_field( Wyanet.Lafourche, Theta );
}
action Okaton(Ogunquit, Masontown) {
   modify_field( Bigspring.Hanks, Talmo.Chaffee );
   LasLomas(Ogunquit, Masontown);
}
action Borth(Jemison, WestEnd, Boutte) {
   modify_field( Bigspring.Hanks, Jemison );
   LasLomas(WestEnd, Boutte);
}
action Newhalen(Hooker, Killen) {
   modify_field( Bigspring.Hanks, Panola[0].Harshaw );
   LasLomas(Hooker, Killen);
}
@pragma ternary 1
table Vevay {
   reads {
      Talmo.Chaffee : exact;
   }
   actions {
      MintHill;
      Okaton;
   }
   size : 512;
}
@pragma action_default_only MintHill
table Kelso {
   reads {
      Talmo.Lumpkin : exact;
      Panola[0].Harshaw : exact;
   }
   actions {
      Borth;
      MintHill;
   }
   size : 1024;
}
table Hampton {
   reads {
      Panola[0].Harshaw : exact;
   }
   actions {
      MintHill;
      Newhalen;
   }
   size : 4096;
}
control Stecker {
   apply( Hines ) {
         McDougal {
            apply( Lowden );
            apply( Paisley );
         }
         Tchula {
            if ( Talmo.Tontogany == 1 ) {
               apply( Hilburn );
            }
            if ( valid( Panola[0] ) and Panola[0].Harshaw != 0 ) {
               apply( Kelso ) {
                  MintHill {
                     apply( Hampton );
                  }
               }
            } else {
               apply( Vevay );
            }
         }
   }
}
register Norma {
    width : 1;
    static : Willmar;
    instance_count : 294912;
}
register Lesley {
    width : 1;
    static : Lawai;
    instance_count : 294912;
}
blackbox stateful_alu Kenmore {
    reg : Norma;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : Bozeman.Liberal;
}
blackbox stateful_alu Spivey {
    reg : Lesley;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst : Bozeman.Sasser;
}
field_list Comfrey {
    ig_intr_md.ingress_port;
    Panola[0].Harshaw;
}
field_list_calculation Bodcaw {
    input { Comfrey; }
    algorithm: identity;
    output_width: 19;
}
action Bruce() {
    Kenmore.execute_stateful_alu_from_hash(Bodcaw);
}
action Joshua() {
    Spivey.execute_stateful_alu_from_hash(Bodcaw);
}
table Willmar {
    actions {
      Bruce;
    }
    default_action : Bruce;
    size : 1;
}
table Lawai {
    actions {
      Joshua;
    }
    default_action : Joshua;
    size : 1;
}
control Chatcolet {
   if ( valid( Panola[0] ) and Panola[0].Harshaw != 0 ) {
      apply( Willmar );
   }
   apply( Lawai );
}
register Godley {
    width : 1;
    static : Chelsea;
    instance_count : 294912;
}
register Pearce {
    width : 1;
    static : Durant;
    instance_count : 294912;
}
blackbox stateful_alu Lenwood {
    reg : Godley;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : Wakita.Peosta;
}
blackbox stateful_alu Giltner {
    reg : Pearce;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : Wakita.NewTrier;
}
field_list Barber {
   eg_intr_md.egress_port;
   Upalco.Kelvin;
}
field_list_calculation Woodbury {
   input { Barber; }
   algorithm: identity;
   output_width: 19;
}
action Craig() {
   Lenwood.execute_stateful_alu_from_hash(Woodbury);
}
table Chelsea {
   actions {
     Craig;
   }
   default_action : Craig;
   size : 1;
}
action Boysen() {
    Giltner.execute_stateful_alu_from_hash(Woodbury);
}
table Durant {
    actions {
      Boysen;
    }
    default_action : Boysen;
    size : 1;
}
control Gabbs {
   apply( Chelsea );
}
control Nevis {
   apply( Durant );
}
field_list IttaBena {
   Olcott.NantyGlo;
   Olcott.Browning;
   Olcott.Virgil;
   Olcott.Cisne;
   Olcott.Basic;
}
field_list Mulliken {
   Aynor.Roswell;
   Aynor.Rayville;
   Aynor.Kinross;
}
field_list Dunbar {
   PineLawn.Saticoy;
   PineLawn.Joaquin;
   PineLawn.Pollard;
   PineLawn.Reinbeck;
}
field_list Callao {
   Aynor.Rayville;
   Aynor.Kinross;
   ElDorado.Folcroft;
   ElDorado.Engle;
}
field_list LeMars {
   PineLawn.Saticoy;
   PineLawn.Joaquin;
   ElDorado.Folcroft;
   ElDorado.Engle;
}
field_list_calculation Palmerton {
    input {
        IttaBena;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Duffield {
    input {
        Mulliken;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Sparr {
    input {
        Dunbar;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Hillcrest {
    input {
        Callao;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Tombstone {
    input {
        LeMars;
    }
    algorithm : crc32;
    output_width : 32;
}
action Davie() {
    modify_field_with_hash_based_offset(McAlister.BigPiney, 0,
                                        Palmerton, 4294967296);
}
action Royston() {
    modify_field_with_hash_based_offset(McAlister.Pittsboro, 0,
                                        Duffield, 4294967296);
}
action Arvana() {
    modify_field_with_hash_based_offset(McAlister.Pittsboro, 0,
                                        Sparr, 4294967296);
}
action Glenshaw() {
    modify_field_with_hash_based_offset(McAlister.Corder, 0,
                                        Hillcrest, 4294967296);
}
action Kupreanof() {
    modify_field_with_hash_based_offset(McAlister.Corder, 0,
                                        Tombstone, 4294967296);
}
table Bufalo {
   actions {
      Davie;
   }
   size: 1;
}
control Watters {
   apply(Bufalo);
}
table Safford {
   actions {
      Royston;
   }
   size: 1;
}
table Lofgreen {
   actions {
      Arvana;
   }
   size: 1;
}
control Hookdale {
   if ( valid( Aynor ) ) {
      apply(Safford);
   }
}
control WoodDale {
   if ( valid( PineLawn ) ) {
         apply(Lofgreen);
   }
}
table Deeth {
   actions {
      Glenshaw;
   }
   size: 1;
}
control Darden {
   if ( valid( ElDorado ) and valid( Aynor )) {
      apply(Deeth);
   }
}
table LaSal {
   actions {
      Kupreanof;
   }
   size: 1;
}
control Panaca {
   if ( valid( ElDorado ) and valid( PineLawn )) {
      apply(LaSal);
   }
}
action Tinaja() {
    modify_field(Moraine.Surrency, McAlister.BigPiney);
}
action Roseville() {
    modify_field(Moraine.Surrency, McAlister.Pittsboro);
}
action Currie() {
    modify_field(Moraine.Surrency, McAlister.Corder);
}
@pragma action_default_only MintHill
@pragma immediate 0
table Allons {
   reads {
      Lubec.valid : ternary;
      Chugwater.valid : ternary;
      Hennessey.valid : ternary;
      Antonito.valid : ternary;
      Kipahulu.valid : ternary;
      McCracken.valid : ternary;
      Brackett.valid : ternary;
      Aynor.valid : ternary;
      PineLawn.valid : ternary;
      Olcott.valid : ternary;
   }
   actions {
      Tinaja;
      Roseville;
      Currie;
      MintHill;
   }
   size: 256;
}
action McAllen() {
    modify_field(Moraine.BigRock, McAlister.Pittsboro);
}
action Overton() {
    modify_field(Moraine.BigRock, McAlister.Corder);
}
@pragma immediate 0
table Calabasas {
   reads {
      PineLawn.valid : ternary;
      Aynor.valid : ternary;
      ElDorado.valid : ternary;
   }
   actions {
      McAllen;
      Overton;
      MintHill;
   }
   size: 6;
}
counter Larue {
   type : packets_and_bytes;
   direct : Canton;
   min_width: 16;
}
table Canton {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Bozeman.Sasser : ternary;
      Bozeman.Liberal : ternary;
      Bigspring.Paxson : ternary;
      Bigspring.Ekwok : ternary;
      Bigspring.Elimsport : ternary;
      Bigspring.Kenvil : ternary;
      ig_intr_md_from_parser_aux.ingress_parser_err mask 0x1000 : ternary;
      Bigspring.Lignite : ternary;
   }
   actions {
      Ripley;
      MintHill;
   }
   default_action : MintHill();
   size : 512;
}
table Snyder {
   reads {
      Bigspring.Jayton : exact;
      Bigspring.Camino : exact;
      Bigspring.Marquette : exact;
   }
   actions {
      Ripley;
      MintHill;
   }
   default_action : MintHill();
   size : 4096;
}
action Kellner() {
   modify_field(BigWater.Hospers,
                1);
}
table Slick {
   reads {
      Bigspring.Jayton : exact;
      Bigspring.Camino : exact;
      Bigspring.Marquette : exact;
      Bigspring.Zeeland : exact;
   }
   actions {
      Vandling;
      Kellner;
   }
   default_action : Kellner();
   size : 65536;
   support_timeout : true;
}
action Friend( Donner, Woodfords ) {
   modify_field( Bigspring.Despard, Donner );
   modify_field( Bigspring.Ivyland, Woodfords );
}
action Danforth() {
   modify_field( Bigspring.Ivyland, 1 );
}
table Ramah {
   reads {
      Bigspring.Marquette mask 0xfff : exact;
   }
   actions {
      Friend;
      Danforth;
      MintHill;
   }
   default_action : MintHill();
   size : 4096;
}
action RedHead() {
   modify_field( Wyanet.Winfall, 1 );
}
table Hillsview {
   reads {
      Bigspring.Hanks : ternary;
      Bigspring.Kaluaaha : exact;
      Bigspring.Silva : exact;
   }
   actions {
      RedHead;
   }
   size: 512;
}
control Wisdom {
   apply( Canton ) {
      MintHill {
         apply( Snyder ) {
            MintHill {
               if (Talmo.Knippa == 0 and BigWater.Hospers == 0) {
                  apply( Slick );
               }
               apply( Ramah );
               apply(Hillsview);
            }
         }
      }
   }
}
field_list Bairoa {
    BigWater.Hospers;
    Bigspring.Jayton;
    Bigspring.Camino;
    Bigspring.Marquette;
    Bigspring.Zeeland;
}
action Coalwood() {
   generate_digest(0, Bairoa);
}
field_list Westel {
    BigWater.Hospers;
    Bigspring.Marquette;
    Kipahulu.Virgil;
    Kipahulu.Cisne;
    Aynor.Rayville;
}
action Harpster() {
   generate_digest(0, Westel);
}
table Sweeny {
   reads {
      BigWater.Hospers : exact;
   }
   actions {
      Coalwood;
      Harpster;
      MintHill;
   }
   default_action : MintHill();
   size : 512;
}
control CoalCity {
   if (BigWater.Hospers != 0) {
      apply( Sweeny );
   }
}
action Farner( Udall, Ocracoke ) {
   modify_field( Portal.Empire, Udall );
   modify_field( Emajagua.Raeford, Ocracoke );
}
action Basehor( Millett, Jamesburg ) {
   modify_field( Portal.Empire, Millett );
   modify_field( Emajagua.Lakota, Jamesburg );
}
@pragma action_default_only MintHill
table Fairhaven {
   reads {
      Wyanet.Rixford : exact;
      Portal.McDaniels mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Farner;
      MintHill;
      Basehor;
   }
   size : 8192;
}
@pragma atcam_partition_index Portal.Empire
@pragma atcam_number_partitions 8192
table Scranton {
   reads {
      Portal.Empire : exact;
      Portal.McDaniels mask 0x000007FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Coolin;
      Springlee;
      MintHill;
   }
   default_action : MintHill();
   size : 65536;
}
action Glenolden( Willette, Siloam ) {
   modify_field( Portal.Raynham, Willette );
   modify_field( Emajagua.Raeford, Siloam );
}
action Coalton( Bethesda, McFaddin ) {
   modify_field( Portal.Raynham, Bethesda );
   modify_field( Emajagua.Lakota, McFaddin );
}
@pragma action_default_only MintHill
table Plato {
   reads {
      Wyanet.Rixford : exact;
      Portal.McDaniels : lpm;
   }
   actions {
      Glenolden;
      Coalton;
      MintHill;
   }
   size : 2048;
}
@pragma atcam_partition_index Portal.Raynham
@pragma atcam_number_partitions 2048
table Ruthsburg {
   reads {
      Portal.Raynham : exact;
      Portal.McDaniels mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Coolin;
      Springlee;
      MintHill;
   }
   default_action : MintHill();
   size : 16384;
}
@pragma action_default_only Edmeston
@pragma idletime_precision 1
table Quogue {
   reads {
      Wyanet.Rixford : exact;
      Portal.McDaniels mask 0xFFFFFFFF000000000000000000000000: lpm;
   }
   actions {
      Coolin;
      Springlee;
      Edmeston;
   }
   size : 512;
   support_timeout : true;
}
@pragma action_default_only Edmeston
@pragma idletime_precision 1
table Dizney {
   reads {
      Wyanet.Rixford : exact;
      Nunnelly.Amazonia : lpm;
   }
   actions {
      Coolin;
      Springlee;
      Edmeston;
   }
   size : 1024;
   support_timeout : true;
}
action Alston( Candor, Yorkville ) {
   modify_field( Nunnelly.Monkstown, Candor );
   modify_field( Emajagua.Raeford, Yorkville );
}
action Skokomish( Aurora, Tuckerton ) {
   modify_field( Nunnelly.Monkstown, Aurora );
   modify_field( Emajagua.Lakota, Tuckerton );
}
@pragma action_default_only MintHill
table Tigard {
   reads {
      Wyanet.Rixford : exact;
      Nunnelly.Amazonia : lpm;
   }
   actions {
      Alston;
      Skokomish;
      MintHill;
   }
   size : 16384;
}
@pragma ways 2
@pragma atcam_partition_index Nunnelly.Monkstown
@pragma atcam_number_partitions 16384
table Reidville {
   reads {
      Nunnelly.Monkstown : exact;
      Nunnelly.Amazonia mask 0x000fffff : lpm;
   }
   actions {
      Coolin;
      Springlee;
      MintHill;
   }
   default_action : MintHill();
   size : 131072;
}
action Coolin( Pevely ) {
   modify_field( Emajagua.Raeford, Pevely );
}
@pragma idletime_precision 1
table Sofia {
   reads {
      Wyanet.Rixford : exact;
      Nunnelly.Amazonia : exact;
   }
   actions {
      Coolin;
      Springlee;
      MintHill;
   }
   default_action : MintHill();
   size : 65536;
   support_timeout : true;
}
@pragma idletime_precision 1
@pragma stage 2 28672
@pragma stage 3
table Coulee {
   reads {
      Wyanet.Rixford : exact;
      Portal.McDaniels : exact;
   }
   actions {
      Coolin;
      Springlee;
      MintHill;
   }
   default_action : MintHill();
   size : 65536;
   support_timeout : true;
}
action Fallis(Hiawassee, Mabana, Beresford) {
   modify_field(Upalco.Monohan, Beresford);
   modify_field(Upalco.Bledsoe, Hiawassee);
   modify_field(Upalco.Coamo, Mabana);
   modify_field(Upalco.Fieldon, 1);
   bit_not(ig_intr_md_for_tm.rid, 0);
}
action Edmeston(Kapalua) {
   modify_field(Emajagua.Raeford, Kapalua);
}
action Dunedin(Tunica) {
   modify_field(Upalco.Westview, 1);
   modify_field(Upalco.Ackerly, Tunica);
}
table Fishers {
   reads {
      Emajagua.Raeford mask 0xF: exact;
   }
   actions {
      Dunedin;
   }
   size : 16;
}
@pragma use_hash_action 1
table Wrenshall {
   reads {
      Emajagua.Raeford : exact;
   }
   actions {
      Fallis;
   }
   default_action : Fallis(0,0,0);
   size : 65536;
}
action Dumas(Heaton) {
   modify_field(Emajagua.Raeford, Heaton);
}
table Campbell {
   reads {
      Wyanet.Lafourche : exact;
      Bigspring.Verdemont : exact;
   }
   actions {
      Dumas;
   }
   default_action: Dumas(10);
   size : 2;
}
/*
control Wetumpka {
   apply( Coulee ) {
      MintHill {
         apply( Plato );
      }
   }
}
control Chaumont {
   apply( Sofia ) {
      MintHill {
         apply(Tigard);
      }
   }
}
*/

control Breese {
   if ( ( ( Wyanet.Lafourche & ( 0x2 ) ) == ( ( 0x2 ) ) ) and ( Bigspring.Verdemont == 2 ) and
        (Talmo.Gotham != 0) and Bigspring.Hewitt == 0 and Wyanet.Winfall == 1 ) {
         apply( Coulee ) {
            MintHill {
               apply( Plato );
            }
         }
   } else if ( ( ( Wyanet.Lafourche & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Bigspring.Verdemont == 1 ) and
               (Talmo.Gotham != 0) and Bigspring.Hewitt == 0 ) {
         if ( Wyanet.Winfall == 1 ) {
            apply( Sofia ) {
               MintHill {
                  apply(Tigard);
               }
            }
         }
  }
}
control Merino {
   if ( Bigspring.Hewitt == 0 and Wyanet.Winfall == 1 and Talmo.Gotham != 0 ) {
      if ( ( ( Wyanet.Lafourche & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Bigspring.Verdemont == 1 ) ) {
         if ( Nunnelly.Monkstown != 0 ) {
            apply( Reidville );
         } else if ( Emajagua.Raeford == 0 and Emajagua.Lakota == 0 ) {
            apply( Dizney );
         }
      } else if ( ( ( Wyanet.Lafourche & ( 0x2 ) ) == ( ( 0x2 ) ) ) and Bigspring.Verdemont == 2 ) {
         if ( Portal.Raynham != 0 ) {
            apply( Ruthsburg );
         } else if ( Emajagua.Raeford == 0 and Emajagua.Lakota == 0 ) {
            apply( Fairhaven );
            if ( Portal.Empire != 0 ) {
               apply( Scranton );
            } else if ( Emajagua.Raeford == 0 and Emajagua.Lakota == 0 ) {
               apply( Quogue );
            }
         }
      } else if ( ( Bigspring.Ivyland == 1 ) or
            ( ( ( Wyanet.Lafourche & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Bigspring.Verdemont == 3 ) ) ) {
         apply( Campbell );
      }
   }
}
control Kalskag {
   if( Emajagua.Raeford != 0 ) {
      if( ( Emajagua.Raeford & 0xFFF0 ) == 0 ) {
         apply( Fishers );
      } else {
         apply( Wrenshall );
      }
   }
}
action Springlee( Weissert ) {
   modify_field( Emajagua.Lakota, Weissert );
}
field_list Luning {
   Moraine.BigRock;
}
field_list_calculation Perez {
    input {
        Luning;
    }
    algorithm : identity;
    output_width : 66;
}
action_selector Holladay {
   selection_key : Perez;
   selection_mode : resilient;
}
action_profile Devola {
   actions {
      Coolin;
   }
   size : 65536;
   dynamic_action_selection : Holladay;
}
@pragma selector_max_group_size 256
table Exell {
   reads {
      Emajagua.Lakota : exact;
   }
   action_profile : Devola;
   size : 2048;
}
control Yocemento {
   if ( Emajagua.Lakota != 0 ) {
      apply( Exell );
   }
}
field_list Hernandez {
   Moraine.Surrency;
}
field_list_calculation Sagamore {
    input {
        Hernandez;
    }
    algorithm : identity;
    output_width : 51;
}
action_selector Chamois {
    selection_key : Sagamore;
    selection_mode : resilient;
}
action Akiachak(Ferndale) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Ferndale);
}
action_profile Tecolote {
    actions {
        Akiachak;
        MintHill;
    }
    size : 32768;
    dynamic_action_selection : Chamois;
}
action Shawmut() {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Upalco.Pilottown);
}
table Aguilita {
   actions {
        Shawmut;
   }
   default_action : Shawmut();
   size : 1;
}
table Kisatchie {
   reads {
      Upalco.Pilottown mask 0x7FF : exact;
   }
   action_profile: Tecolote;
   size : 256;
}
control Stout {
   if ((Upalco.Pilottown & 0x3800) == 0x3800) {
      apply(Kisatchie);
   } else if((Upalco.Pilottown & 0xFFC00) == 0 ) {
      apply(Aguilita);
   }
}
action Ottertail() {
   modify_field(Upalco.Bledsoe, Bigspring.Kaluaaha);
   modify_field(Upalco.Coamo, Bigspring.Silva);
   modify_field(Upalco.Annandale, Bigspring.Jayton);
   modify_field(Upalco.SantaAna, Bigspring.Camino);
   modify_field(Upalco.Monohan, Bigspring.Marquette);
   modify_field(Upalco.Pilottown, 511);
}
table Ovilla {
   actions {
      Ottertail;
   }
   default_action : Ottertail();
   size : 1;
}
control Oakridge {
   apply( Ovilla );
}
action Emsworth() {
   modify_field(Upalco.Palisades, 1);
   modify_field(Upalco.Litroe, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Bigspring.Ivyland);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Upalco.Monohan);
}
action RowanBay() {
}
@pragma ways 1
table Hohenwald {
   reads {
      Upalco.Bledsoe : exact;
      Upalco.Coamo : exact;
   }
   actions {
      Emsworth;
      RowanBay;
   }
   default_action : RowanBay;
   size : 1;
}
action Nuyaka() {
   modify_field(Upalco.Dalton, 1);
   modify_field(Upalco.Stratton, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Upalco.Monohan, 4096);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Bigspring.Ivyland);
}
table Comobabi {
   actions {
      Nuyaka;
   }
   default_action : Nuyaka;
   size : 1;
}
action Dunnstown() {
   modify_field(Upalco.Schleswig, 1);
   modify_field(Upalco.Litroe, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Upalco.Monohan);
}
table Gonzalez {
   actions {
      Dunnstown;
   }
   default_action : Dunnstown();
   size : 1;
}
action Filer(Hindman) {
   modify_field(Upalco.Kalkaska, 1);
   modify_field(Upalco.Pilottown, Hindman);
}
action Biloxi(Stambaugh, Duque) {
   modify_field(Upalco.Waldport, Duque);
   Filer(Stambaugh);
}
action Randall(Syria) {
   modify_field(Upalco.Dalton, 1);
   modify_field(Upalco.AvonLake, Syria);
}
action Wyatte() {
}
@pragma pack 4
table Ilwaco {
   reads {
      Upalco.Bledsoe : exact;
      Upalco.Coamo : exact;
      Upalco.Monohan : exact;
   }
   actions {
      Filer;
      Randall;
      Biloxi;
      Ripley;
      Wyatte;
   }
   default_action : Wyatte();
   size : 65536;
}
control Challis {
   apply(Ilwaco) {
      Wyatte {
         apply(Hohenwald) {
            RowanBay {
               if ((Upalco.Bledsoe & 0x010000) == 0x010000) {
                  apply(Comobabi);
               } else {
                  apply(Gonzalez);
               }
            }
         }
      }
   }
}
field_list Calamus {
   Moraine.Surrency;
}
field_list_calculation WyeMills {
    input {
        Calamus;
    }
    algorithm : identity;
    output_width : 51;
}
field_list_calculation Carmel {
   input {
      Calamus;
   }
   algorithm : identity;
   output_width : 16;
}
action Krupp( Waterman, Hughson ) {
   bit_or( Upalco.Colonie, Upalco.Pilottown, Hughson );
   modify_field( Upalco.Pilottown, Waterman );
   modify_field( Upalco.Alsen, 5 );
   modify_field_with_hash_based_offset( Olcott.NantyGlo, 0, Carmel, 16384 );
}
action_selector Seguin {
    selection_key : WyeMills;
    selection_mode : resilient;
}
action_profile Andrade {
    actions {
       Krupp;
    }
    size : 1024;
    dynamic_action_selection : Seguin;
}
@pragma ways 2
table LasVegas {
   reads {
      Upalco.Waldport : exact;
   }
   action_profile : Andrade;
   size : 512;
}
action Hitchland() {
   modify_field(Bigspring.Kneeland, 1);
   Ripley();
}
table Longview {
   actions {
      Hitchland;
   }
   default_action : Hitchland;
   size : 1;
}
table Anawalt {
   reads {
      Upalco.Pilottown mask 0x7FF : exact;
   }
   actions {
      Vandling;
      Ripley;
   }
   default_action : Vandling;
   size : 256;
}
control Mynard {
   if ((Bigspring.Hewitt == 0) and (Upalco.Fieldon==0) and (Bigspring.Macon==0)
       and (Bigspring.Combine==0)) {
      if (Bigspring.Zeeland==Upalco.Pilottown) {
         apply(Longview);
      } else if (Talmo.Gotham==2 and
                 ((Upalco.Pilottown & 0xFF800) == 0x3800)) {
         apply(Anawalt);
      }
   }
   apply(LasVegas);
}
action Everton( DelRey ) {
   modify_field( Upalco.Kelvin, DelRey );
}
action Carrizozo() {
   modify_field( Upalco.Kelvin, Upalco.Monohan );
}
table Bratt {
   reads {
      eg_intr_md.egress_port : exact;
      Upalco.Monohan : exact;
   }
   actions {
      Everton;
      Carrizozo;
   }
   default_action : Carrizozo;
   size : 4096;
}
control Nettleton {
   apply( Bratt );
}
action Gagetown( Sahuarita, Glendevey ) {
   modify_field( Upalco.Reynolds, Sahuarita );
   modify_field( Upalco.Merit, Glendevey );
}
action Fabens( Riverbank, Monse, Brinson ) {
   modify_field( Upalco.Reynolds, Riverbank );
   modify_field( Upalco.Merit, Monse );
   modify_field( Upalco.Shobonier, Brinson );
}
action Oxford( Mackville, Talkeetna ) {
   modify_field( Upalco.Reynolds, Mackville );
   modify_field( Upalco.Merit, Talkeetna );
}
@pragma ternary 1
table Kempner {
   reads {
      Upalco.Alsen : exact;
   }
   actions {
      Gagetown;
      Fabens;
      Oxford;
   }
   size : 8;
}
action Jefferson( Emida ) {
   modify_field( Upalco.Baytown, 1 );
   modify_field( Upalco.Alsen, 2 );
   modify_field( Upalco.Korbel, Emida );
}
table Ledger {
   reads {
      eg_intr_md.egress_port : exact;
      Talmo.Tontogany : exact;
      Upalco.Nowlin : exact;
   }
   actions {
      Jefferson;
   }
   default_action : MintHill();
   size : 16;
}
action Needles(Gifford, Vergennes, Moorewood, Donnelly) {
   modify_field( Upalco.Arredondo, Gifford );
   modify_field( Upalco.Lilbert, Vergennes );
   modify_field( Upalco.DeSmet, Moorewood );
   modify_field( Upalco.Headland, Donnelly );
}
table Horsehead {
   reads {
        Upalco.Walcott : exact;
   }
   actions {
      Needles;
   }
   size : 512;
}
action Machens( Corfu ) {
   modify_field( Upalco.Harvey, Corfu );
}
table Weatherly {
   reads {
      Upalco.Colonie mask 0xfff : exact;
   }
   actions {
      Machens;
   }
   default_action : Machens(0);
   size : 4096;
}
action Gillespie( Drifton, McCaskill, Everetts ) {
   modify_field( Upalco.FairOaks, Drifton );
   modify_field( Upalco.Overbrook, McCaskill );
   modify_field( Upalco.Monohan, Everetts );
}
@pragma use_hash_action 1
table Cedonia {
   reads {
      Upalco.Colonie mask 0xFF000000: exact;
   }
   actions {
      Gillespie;
   }
   default_action : Gillespie(0,0,0);
   size : 256;
}
action Gorum( Alsea ) {
   modify_field( Upalco.Keyes, Alsea );
}
table Iroquois {
   reads {
      Upalco.Monohan mask 0xFFF : exact;
   }
   actions {
      Gorum;
   }
   default_action : Gorum( 0 );
   size : 4096;
}
action Bethune( Mentmore, Murchison, Boistfort, Delmont, Burdette, Newberg, Sespe ) {
   Machens( Mentmore );
   Gorum( Burdette );
   Gillespie( Murchison, Boistfort, Delmont );
   modify_field( Upalco.Alsen, Newberg );
   bit_or( Upalco.Fieldon, Upalco.Fieldon, Sespe );
}
@pragma ways 2
table Mosinee {
   reads {
     eg_intr_md.egress_port : exact;
     eg_intr_md.egress_rid: exact;
   }
   actions {
      Bethune;
   }
  default_action: MintHill();
  size : 4096;
}
control Leflore {
   if( ( Upalco.Colonie & 0x60000 ) == 0x40000 ) {
      apply( Weatherly );
   }
}
control RedBay {
   if( Upalco.Colonie != 0 ) {
      apply( Iroquois );
      apply( Cedonia );
   }
}
action Nipton() {
   no_op();
}
action Grizzly() {
   modify_field( Olcott.Basic, Panola[0].Houston );
}
table Burtrum {
   actions {
      Grizzly;
   }
   default_action : Grizzly;
   size : 1;
}
action Grannis() {
   no_op();
}
action Dubuque() {
   add_header( Panola[ 0 ] );
   modify_field( Panola[0].Harshaw, Upalco.Kelvin );
   modify_field( Panola[0].Houston, Olcott.Basic );
   modify_field( Panola[0].Bernstein, DeBeque.Natalia );
   modify_field( Panola[0].LaPlata, DeBeque.Oakes );
   modify_field( Olcott.Basic, 0x8100 );
}
@pragma ways 2
table Ridgeland {
   reads {
      Upalco.Kelvin : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Grannis;
      Dubuque;
   }
   default_action : Dubuque;
   size : 256;
}
action Gully() {
   modify_field(Olcott.NantyGlo, Upalco.Bledsoe);
   modify_field(Olcott.Browning, Upalco.Coamo);
   modify_field(Olcott.Virgil, Upalco.Reynolds);
   modify_field(Olcott.Cisne, Upalco.Merit);
}
action Yaurel() {
   Gully();
   add_to_field(Aynor.Worthing, -1);
}
action Mendham() {
   Gully();
   add_to_field(PineLawn.McBrides, -1);
}
action Belvidere() {
}
action Cabot() {
   Dubuque();
}
action Omemee( Trimble, Maljamar, Maxwelton, Winner ) {
   add_header( Canalou );
   modify_field( Canalou.NantyGlo, Trimble );
   modify_field( Canalou.Browning, Maljamar );
   modify_field( Canalou.Virgil, Maxwelton );
   modify_field( Canalou.Cisne, Winner );
   modify_field( Canalou.Basic, 0xBF00 );
   add_header( Duster );
   modify_field( Duster.Bleecker, Upalco.Arredondo );
   modify_field( Duster.Lilymoor, Upalco.Lilbert );
   modify_field( Duster.Bluewater, Upalco.DeSmet );
   modify_field( Duster.Hagewood, Upalco.Headland );
   modify_field( Duster.Slocum, Upalco.Ravenwood );
   modify_field( Duster.Tusculum, Upalco.Ackerly );
   modify_field( Duster.Langston, Bigspring.Marquette );
   modify_field( Duster.Eudora, Upalco.Korbel );
}
action Mackeys() {
   no_op();
}
action Speedway() {
   add_header( Olcott );
   modify_field( Olcott.NantyGlo, Upalco.Bledsoe );
   modify_field( Olcott.Browning, Upalco.Coamo );
   modify_field( Olcott.Virgil, Upalco.Reynolds );
   modify_field( Olcott.Cisne, Upalco.Merit );
   modify_field( Olcott.Basic, 0x0800 );
}
action Wakenda() {
   remove_header( Leesport );
   remove_header( Brackett );
   remove_header( ElDorado );
   copy_header( Olcott, Kipahulu );
   remove_header( Kipahulu );
   remove_header( Aynor );
}
action Moapa() {
   remove_header( Leesport );
   remove_header( Brackett );
   remove_header( ElDorado );
   remove_header( Aynor );
   modify_field( Olcott.NantyGlo, Upalco.Bledsoe );
   modify_field( Olcott.Browning, Upalco.Coamo );
   modify_field( Olcott.Virgil, Upalco.Reynolds );
   modify_field( Olcott.Cisne, Upalco.Merit );
   modify_field( Olcott.Basic, Kipahulu.Basic );
   remove_header( Kipahulu );
}
action Moorpark() {
   Moapa();
   add_to_field( Hennessey.Worthing, -1 );
}
action Colstrip() {
   Moapa();
   add_to_field( Antonito.McBrides, -1 );
}
action Hanover() {
}
action ArchCape( Sanford ) {
   modify_field( Hennessey.Esmond, Aynor.Esmond );
   modify_field( Hennessey.Brinklow, Aynor.Brinklow );
   modify_field( Hennessey.ElkNeck, Aynor.ElkNeck );
   modify_field( Hennessey.Astor, Aynor.Astor );
   modify_field( Hennessey.Pierre, Aynor.Pierre );
   modify_field( Hennessey.HamLake, Aynor.HamLake );
   modify_field( Hennessey.Konnarock, Aynor.Konnarock );
   modify_field( Hennessey.Kingsgate, Aynor.Kingsgate );
   add( Hennessey.Worthing, Aynor.Worthing, Sanford );
   modify_field( Hennessey.Roswell, Aynor.Roswell );
   modify_field( Hennessey.Arnold, Aynor.Arnold );
   modify_field( Hennessey.Rayville, Aynor.Rayville );
   modify_field( Hennessey.Kinross, Aynor.Kinross );
}
action Milesburg( Pierson, Lugert, Montalba, Kiana ) {
   modify_field( Kipahulu.NantyGlo, Upalco.Bledsoe );
   modify_field( Kipahulu.Browning, Upalco.Coamo );
   modify_field( Kipahulu.Virgil, Montalba );
   modify_field( Kipahulu.Cisne, Kiana );
   add( Brackett.Korona, Pierson, Lugert );
   modify_field( Brackett.Dagsboro, 0 );
   modify_field( ElDorado.Engle, 4789 );
   bit_or( ElDorado.Folcroft, Olcott.NantyGlo, 0xC000 );
   modify_field( Leesport.Glassboro, 0x8 );
   modify_field( Leesport.Penrose, 0 );
   modify_field( Leesport.Junior, Upalco.Keyes );
   modify_field( Leesport.Bacton, Upalco.Foristell );
   modify_field( Olcott.NantyGlo, Upalco.FairOaks );
   modify_field( Olcott.Browning, Upalco.Overbrook );
   modify_field( Olcott.Virgil, Upalco.Reynolds );
   modify_field( Olcott.Cisne, Upalco.Merit );
}
action Wimbledon( LaMonte, Longport, Oakville, Kinston, Altadena ) {
   add_header( Kipahulu );
   add_header( Brackett );
   add_header( ElDorado );
   add_header( Leesport );
   modify_field( Kipahulu.Basic, Olcott.Basic );
   Milesburg( LaMonte, Longport, Kinston, Altadena );
   Metzger( LaMonte, Oakville );
}
action Metzger( Honobia, Gowanda ) {
   modify_field( Aynor.Esmond, 0x4 );
   modify_field( Aynor.Brinklow, 0x5 );
   modify_field( Aynor.ElkNeck, 0 );
   modify_field( Aynor.Astor, 0 );
   add( Aynor.Pierre, Honobia, Gowanda );
   modify_field( Aynor.HamLake, eg_intr_md_from_parser_aux.egress_global_tstamp, 0xFFFF );
   modify_field( Aynor.Konnarock, 0x2 );
   modify_field( Aynor.Kingsgate, 0 );
   modify_field( Aynor.Worthing, 64 );
   modify_field( Aynor.Roswell, 17 );
   modify_field( Aynor.Rayville, Upalco.Shobonier );
   modify_field( Aynor.Kinross, Upalco.Harvey );
   modify_field( Olcott.Basic, 0x0800 );
}
action Platea() {
   add_header( Hennessey );
   ArchCape( -1 );
   Wimbledon( Aynor.Pierre, 30, 50,
                         Upalco.Reynolds, Upalco.Merit );
}
action BigPoint() {
   add_header( Hennessey );
   ArchCape( 0 );
   Wimbledon( eg_intr_md.pkt_length, 16, 36,
                            Olcott.Virgil, Olcott.Cisne );
}
action Portville( Reddell ) {
   modify_field( Antonito.WhiteOwl, PineLawn.WhiteOwl );
   modify_field( Antonito.Miller, PineLawn.Miller );
   modify_field( Antonito.Hermiston, PineLawn.Hermiston );
   modify_field( Antonito.Pollard, PineLawn.Pollard );
   modify_field( Antonito.Scanlon, PineLawn.Scanlon );
   modify_field( Antonito.Reinbeck, PineLawn.Reinbeck );
   modify_field( Antonito.Saticoy, PineLawn.Saticoy );
   modify_field( Antonito.Joaquin, PineLawn.Joaquin );
   add( Antonito.McBrides, PineLawn.McBrides, Reddell );
}
action Hewins() {
   add_header( Antonito );
   Portville( -1 );
   add_header( Aynor );
   Wimbledon( PineLawn.Scanlon, 30, 50,
                            Upalco.Reynolds, Upalco.Merit );
   remove_header( PineLawn );
}
action Kearns() {
   add_header( Antonito );
   Portville( 0 );
   add_header( Aynor );
   Wimbledon( eg_intr_md.pkt_length, 16, 36,
                            Olcott.Virgil, Olcott.Cisne );
   remove_header( PineLawn );
}
action Dietrich() {
   add_header( Aynor );
   Wimbledon( eg_intr_md.pkt_length, 16, 36,
                            Olcott.Virgil, Olcott.Cisne );
}
action Nenana( Dutton, Tekonsha ) {
   Milesburg( Brackett.Korona, 0, Dutton, Tekonsha );
   Metzger( Aynor.Pierre, 0 );
}
action Gheen() {
   Nenana( Kipahulu.Virgil, Kipahulu.Cisne );
}
action Wrens() {
   Nenana( Upalco.Reynolds, Upalco.Merit );
   add_to_field( Hennessey.Worthing, -1 );
}
action Ammon() {
   Nenana( Upalco.Reynolds, Upalco.Merit );
   add_to_field( Antonito.McBrides, -1 );
}
table Nichols {
   reads {
      Upalco.DewyRose : exact;
      Upalco.Alsen : exact;
      Upalco.Fieldon : exact;
      Aynor.valid : ternary;
      PineLawn.valid : ternary;
      Hennessey.valid : ternary;
      Antonito.valid : ternary;
   }
   actions {
      Yaurel;
      Mendham;
      Belvidere;
      Cabot;
      Omemee;
      Hanover;
      Wakenda;
      Moorpark;
      Colstrip;
      Gheen;
      Wrens;
      Ammon;
      BigPoint;
      Kearns;
      Platea;
      Hewins;
      Dietrich;
      Speedway;
      Mackeys;
   }
   size : 512;
}
control Bucktown {
   apply( Burtrum );
}
control Belle {
   apply( Ridgeland );
}
action LaVale() {
   drop();
}
table Woodcrest {
   reads {
        Upalco.Headland : ternary;
        Upalco.Walcott : ternary;
        eg_intr_md.egress_port mask 0x7F: exact;
   }
   actions {
      LaVale;
   }
   size : 512;
}
control Raritan {
   apply( Ledger ) {
      MintHill {
         apply( Kempner );
      }
   }
   apply( Horsehead );
   if( Upalco.Fieldon == 0 and Upalco.DewyRose == 0 and Upalco.Alsen == 0 ) {
      apply( Woodcrest );
   }
   apply( Nichols );
}
action Bayshore( Unionvale, Tobique, Hoven ) {
   modify_field( DeBeque.Lazear, Unionvale );
   modify_field( DeBeque.Nunda, Tobique );
   modify_field( DeBeque.McClure, Hoven );
}
table Halsey {
   reads {
     ig_intr_md.ingress_port : exact;
   }
   actions {
      Bayshore;
   }
   size : 512;
}
action Endeavor(Saragosa) {
   modify_field( DeBeque.Natalia, Saragosa );
}
action MuleBarn(Wickett) {
   modify_field( DeBeque.Natalia, Wickett );
   modify_field( Bigspring.Kenvil, Panola[0].Houston );
}
action Cheyenne() {
   modify_field( DeBeque.Tatum, DeBeque.Nunda );
}
action Chitina() {
   modify_field( DeBeque.Tatum, 0 );
}
action Wheeler() {
   modify_field( DeBeque.Tatum, Nunnelly.Ceiba );
}
action Spindale() {
   modify_field( DeBeque.Tatum, Coupland.Galestown );
}
action Franklin() {
   modify_field( DeBeque.Tatum, Portal.OldTown );
}
action Barnsboro( Nordheim, ElJebel ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Nordheim );
   modify_field( ig_intr_md_for_tm.qid, ElJebel );
}
table Grisdale {
   reads {
     Bigspring.Valeene : exact;
     DeBeque.Lazear : exact;
     Panola[0].Bernstein : exact;
   }
   actions {
     Endeavor;
     MuleBarn;
   }
   size : 128;
}
table Ocoee {
   reads {
     Upalco.DewyRose : exact;
     Bigspring.Verdemont : exact;
   }
   actions {
     Cheyenne;
     Chitina;
     Wheeler;
     Spindale;
     Franklin;
   }
   size : 10;
}
table Florahome {
   reads {
      DeBeque.McClure : ternary;
      DeBeque.Lazear : ternary;
      DeBeque.Natalia : ternary;
      DeBeque.Tatum : ternary;
      DeBeque.Hibernia : ternary;
      Upalco.DewyRose : ternary;
      Duster.valid : ternary;
      Duster.Greenwood : ternary;
      Duster.Meeker : ternary;
   }
   actions {
      Barnsboro;
   }
   size : 225;
}
action Shivwits( Pedro, Norco ) {
   modify_field( DeBeque.Rocklin, Pedro );
   modify_field( DeBeque.Uhland, Norco );
}
table Paxtonia {
   actions {
      Shivwits;
   }
   default_action : Shivwits(0, 0);
   size : 1;
}
action Hauppauge( Wildorado ) {
   modify_field( DeBeque.Tatum, Wildorado );
}
action Susank( McCammon ) {
   modify_field( DeBeque.Natalia, McCammon );
}
action Sunrise( Resaca, Westwego ) {
   modify_field( DeBeque.Natalia, Resaca );
   modify_field( DeBeque.Tatum, Westwego );
}
table Neame {
   reads {
      DeBeque.McClure : exact;
      DeBeque.Rocklin : exact;
      DeBeque.Uhland : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
      Upalco.DewyRose : exact;
   }
   actions {
      Hauppauge;
      Susank;
      Sunrise;
   }
   size : 1024;
}
action Pikeville( Sublimity ) {
   modify_field( DeBeque.Punaluu, Sublimity );
}
table Bladen {
   reads {
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Pikeville;
   }
   size : 8;
}
action Alvordton() {
   modify_field( Aynor.ElkNeck, DeBeque.Tatum );
}
action Hollymead() {
   modify_field( PineLawn.Miller, DeBeque.Tatum );
}
action Bremond() {
   modify_field( Hennessey.ElkNeck, DeBeque.Tatum );
}
action Kanab() {
   modify_field( Antonito.Miller, DeBeque.Tatum );
}
action Rugby() {
   modify_field( Aynor.ElkNeck, DeBeque.Punaluu );
}
action Castolon() {
   Rugby();
   modify_field( Hennessey.ElkNeck, DeBeque.Tatum );
}
action Freeville() {
   Rugby();
   modify_field( Antonito.Miller, DeBeque.Tatum );
}
table Frankston {
   reads {
      Upalco.Alsen : ternary;
      Upalco.DewyRose : ternary;
      Upalco.Fieldon : ternary;
      Aynor.valid : ternary;
      PineLawn.valid : ternary;
      Hennessey.valid : ternary;
      Antonito.valid : ternary;
   }
   actions {
      Alvordton;
      Hollymead;
      Bremond;
      Kanab;
      Rugby;
      Castolon;
      Freeville;
   }
   size : 7;
}
control Advance {
   apply( Halsey );
}
control Wittman {
   apply( Grisdale );
   apply( Ocoee );
}
control Glentana {
   apply( Florahome );
}
control LaSalle {
   apply( Paxtonia );
   apply( Neame );
}
control Sedona {
   apply( Bladen );
}
control Requa {
   apply( Frankston );
}
action Eclectic( Ivanhoe ) {
   modify_field( DeBeque.Dedham, Ivanhoe );
}
table Greendale {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
   }
   actions {
      Eclectic;
   }
}
action Maloy( Brewerton ) {
   modify_field( DeBeque.Allgood, Brewerton );
}
table Ankeny {
   reads {
      Bigspring.Kenvil : ternary;
      Bigspring.Combine : ternary;
      Upalco.Coamo : ternary;
      Upalco.Bledsoe : ternary;
      Emajagua.Raeford : ternary;
   }
   actions {
      Maloy;
   }
   default_action: Maloy(0);
   size : 512;
}
table Otisco {
   reads {
      Bigspring.Verdemont : ternary;
      Bigspring.Combine : ternary;
      Nunnelly.Amazonia : ternary;
      Portal.McDaniels mask 0xffff0000000000000000000000000000 : ternary;
      Bigspring.Correo : ternary;
      Bigspring.RioLinda : ternary;
      Upalco.Fieldon : ternary;
      Emajagua.Raeford : ternary;
      ElDorado.Folcroft : ternary;
      ElDorado.Engle : ternary;
   }
   actions {
      Maloy;
   }
   default_action: Maloy(0);
   size : 512;
}
meter Valencia {
   type : packets;
   static : Dockton;
   instance_count : 4096;
}
counter PortVue {
   type : packets;
   static : Dockton;
   instance_count : 4096;
   min_width : 64;
}
action Huxley(Glouster) {
   execute_meter( Valencia, Glouster, ig_intr_md_for_tm.packet_color );
}
action Yscloskey(Chouteau) {
   count( PortVue, Chouteau );
}
action Elmhurst(Mangham) {
   Huxley(Mangham);
   Yscloskey(Mangham);
}
table Dockton {
   reads {
      DeBeque.Dedham : exact;
      DeBeque.Allgood : exact;
   }
   actions {
     Yscloskey;
     Elmhurst;
   }
   size : 512;
}
control Woodfield {
   apply( Greendale );
}
control Rattan {
      if ( ( Bigspring.Verdemont == 0 ) or ( Bigspring.Verdemont == 3 ) ) {
         apply( Ankeny );
      } else {
         apply( Otisco );
      }
}
control Keenes {
    if ( Bigspring.Hewitt == 0 ) {
      apply( Dockton );
   }
}
action Fireco( Rehoboth, HillCity ) {
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Rehoboth );
   modify_field( Upalco.Walcott, ig_intr_md.ingress_port );
   modify_field( ig_intr_md_for_tm.qid, HillCity );
}
action Hansboro() {
   modify_field( Upalco.Walcott, ig_intr_md.ingress_port );
}
action Stuttgart( Cochrane, SoapLake ) {
   Fireco( Cochrane, SoapLake );
   modify_field( Upalco.Nowlin, 0);
}
action Waterfall() {
   Hansboro();
   modify_field( Upalco.Nowlin, 0);
}
action Jonesport( Blackman, Spalding ) {
   Fireco( Blackman, Spalding );
   modify_field( Upalco.Nowlin, 1);
}
action Heeia() {
   Hansboro();
   modify_field( Upalco.Nowlin, 1);
}
@pragma ternary 1
table Staunton {
   reads {
      Upalco.Westview : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      Panola[0] : valid;
      Upalco.Ackerly : ternary;
   }
   actions {
      Stuttgart;
      Waterfall;
      Jonesport;
      Heeia;
   }
   default_action : MintHill();
   size : 512;
}
control Sully {
   apply( Staunton ) {
      Stuttgart {
      }
      Jonesport {
      }
      default {
         Stout();
      }
   }
}
counter Rosboro {
   type : packets_and_bytes;
   static : Charm;
   instance_count : 4096;
   min_width : 128;
}
field_list Parmele {
   eg_intr_md.egress_port;
   eg_intr_md.egress_qid;
}
field_list_calculation Penitas {
    input { Parmele; }
    algorithm: identity;
    output_width: 12;
}
action HydePark() {
    // count_from_hash( Rosboro, Penitas );
}
table Charm {
   actions {
      HydePark;
   }
   default_action : HydePark;
   size : 1;
}
control Southam {
   apply( Charm );
}
action Ramos()
{
   Ripley();
}
action Rotterdam() {
}
action Falls() {
   Rotterdam();
   modify_field(Upalco.DewyRose, 3);
}
action Placida( Champlain ) {
   Rotterdam();
   modify_field(Upalco.DewyRose, 2);
   modify_field(Upalco.Pilottown, Champlain);
   modify_field(Upalco.Monohan, Bigspring.Marquette );
}
@pragma pack 1
table Urbanette {
   reads {
      Duster.Bleecker : exact;
      Duster.Lilymoor : exact;
      Duster.Bluewater : exact;
      Duster.Hagewood : exact;
   }
   actions {
      Placida;
      Falls;
      Ramos;
   }
   default_action : Ramos();
   size : 1024;
}
control Harney {
   apply( Urbanette );
}
action Holtville( Swifton, Almeria, Ivins, BigPlain ) {
   modify_field( Poulsbo.Glenvil, Swifton );
   modify_field( Rodeo.Clermont, Ivins );
   modify_field( Rodeo.Corvallis, Almeria );
   modify_field( Rodeo.Somis, BigPlain );
}
@pragma pack 2
table Mather {
   reads {
     Nunnelly.Amazonia : exact;
     Bigspring.Hanks : exact;
   }
   actions {
      Holtville;
   }
  size : 16384;
}
action GlenRose(Scissors, Tofte, Aripine) {
   modify_field( Rodeo.Corvallis, Scissors );
   modify_field( Rodeo.Clermont, Tofte );
   modify_field( Rodeo.Somis, Aripine );
}
table Crumstown {
   reads {
     Nunnelly.Walnut : exact;
     Poulsbo.Glenvil : exact;
   }
   actions {
      GlenRose;
   }
   size : 16384;
}
action Skyforest( Clauene, IdaGrove, Proctor ) {
   modify_field( Hayfork.Hooven, Clauene );
   modify_field( Hayfork.Kensal, IdaGrove );
   modify_field( Hayfork.Sardinia, Proctor );
}
@pragma ways 2
table Angeles {
   reads {
     Upalco.Bledsoe : exact;
     Upalco.Coamo : exact;
     Upalco.Monohan : exact;
   }
   actions {
      Skyforest;
   }
   size : 16384;
}
action Anguilla() {
   modify_field( Upalco.Litroe, 1 );
}
action Burrton( Prosser ) {
   Anguilla();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Rodeo.Corvallis );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Prosser, Rodeo.Somis );
}
action Lucile( Trammel ) {
   Anguilla();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Hayfork.Hooven );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Trammel, Hayfork.Sardinia );
}
action Hemet( SanRemo ) {
   Anguilla();
   add( ig_intr_md_for_tm.mcast_grp_a, Upalco.Monohan,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, SanRemo );
}
action Lostine() {
   modify_field( Upalco.Conger, 1 );
}
table Veguita {
   reads {
     Rodeo.Clermont : ternary;
     Rodeo.Corvallis : ternary;
     Hayfork.Hooven : ternary;
     Hayfork.Kensal : ternary;
     Bigspring.Correo :ternary;
     Bigspring.Macon:ternary;
   }
   actions {
      Burrton;
      Lucile;
      Hemet;
      Lostine;
   }
   size : 512;
}
control Biehle {
   if( Bigspring.Hewitt == 0 and
       ( ( Wyanet.Lafourche & ( 0x4 ) ) == ( ( 0x4 ) ) ) and
       Bigspring.Cadley == 1 and Bigspring.Verdemont == 1) {
      apply( Mather );
   }
}
control Moquah {
   if( Poulsbo.Glenvil != 0 and Bigspring.Verdemont == 1) {
      apply( Crumstown );
   }
}
control Davisboro {
   if( Bigspring.Macon==1 ) {
      apply( Angeles );
   }
}
control Mifflin {
   if( Bigspring.Macon == 1 ) {
      apply(Veguita);
   }
}
action Webbville(Gwinn) {
   modify_field( ig_intr_md_for_tm.level1_mcast_hash, Moraine.Surrency );
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Moraine.Surrency );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Gwinn );
}
@pragma ternary 1
table Rockleigh {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Webbville;
    }
    size : 512;
}
action WestGate(Brinkman) {
    modify_field(ig_intr_md_for_tm.level1_exclusion_id, Brinkman);
    modify_field(ig_intr_md_for_tm.rid, ig_intr_md_for_tm.mcast_grp_a);
}
action Humeston(Farlin) {
    bit_not(ig_intr_md_for_tm.rid, 0);
    modify_field(ig_intr_md_for_tm.level1_exclusion_id, Farlin);
}
action Thurmond(Cloverly) {
    modify_field(ig_intr_md_for_tm.level1_exclusion_id, Cloverly);
    modify_field(ig_intr_md_for_tm.rid, ig_intr_md_for_tm.mcast_grp_a);
}
table Molson {
    reads {
       Upalco.DewyRose : ternary;
       Upalco.Fieldon : ternary;
       Talmo.Gotham : ternary;
       ig_intr_md_for_tm.mcast_grp_a mask 0xC000 : ternary;
    }
    actions {
       WestGate;
       Humeston;
    }
    size: 512;
}
control Faysville {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Rockleigh);
      apply(Molson);
   }
}
action Pridgen( Owanka, Firebrick, Ignacio ) {
   modify_field( Upalco.Monohan, Owanka );
   modify_field( Upalco.Fieldon, Firebrick );
   bit_or( eg_intr_md_for_oport.drop_ctl, eg_intr_md_for_oport.drop_ctl, Ignacio );
}
@pragma ways 2
table Mulvane {
   reads {
     eg_intr_md.egress_rid: exact;
   }
   actions {
      Pridgen;
   }
   default_action: Pridgen( 0, 0, 1 );
   size : 32768;
}
control Pardee {
   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply( Mosinee ) {
         MintHill {
            apply( Mulvane );
         }
      }
   }
}
counter Bellamy {
   type : packets;
   direct: Belfalls;
   min_width: 63;
}
@pragma stage 11
table Belfalls {
   reads {
     Gresston.Ovett mask 0x7fff : exact;
   }
   actions {
      MintHill;
   }
   default_action: MintHill();
   size : 32768;
}
action Minneiska() {
   modify_field( Starkey.Weches, Bigspring.Correo );
   modify_field( Starkey.Lemont, Nunnelly.Ceiba );
   modify_field( Starkey.Riley, Bigspring.RioLinda );
   modify_field( Starkey.Avondale, Bigspring.Rendville );
}
action Odebolt() {
   modify_field( Starkey.Weches, Bigspring.Correo );
   modify_field( Starkey.Lemont, Portal.OldTown );
   modify_field( Starkey.Riley, Bigspring.RioLinda );
   modify_field( Starkey.Avondale, Bigspring.Rendville );
}
action Wahoo( Sherrill, Choudrant ) {
   Minneiska();
   modify_field( Starkey.Asherton, Sherrill );
   modify_field( Starkey.Micro, Choudrant );
}
action Poland( Dubach, Newhalem ) {
   Odebolt();
   modify_field( Starkey.Asherton, Dubach );
   modify_field( Starkey.Micro, Newhalem );
}
table Endicott {
   reads {
     Nunnelly.Walnut : ternary;
   }
   actions {
      Wahoo;
   }
   default_action : Minneiska;
  size : 2048;
}
table Grasmere {
   reads {
     Portal.Haverford : ternary;
   }
   actions {
      Poland;
   }
   default_action : Odebolt;
   size : 1024;
}
action Spraberry( Moseley, Whigham ) {
   modify_field( Starkey.Blairsden, Moseley );
   modify_field( Starkey.Robert, Whigham );
}
table Monmouth {
   reads {
     Nunnelly.Amazonia : ternary;
   }
   actions {
      Spraberry;
   }
   size : 512;
}
table Waukegan {
   reads {
     Portal.McDaniels : ternary;
   }
   actions {
      Spraberry;
   }
   size : 512;
}
action Sandston( Wardville ) {
   modify_field( Starkey.WarEagle, Wardville );
}
table Grenville {
   reads {
     Bigspring.Kokadjo : ternary;
   }
   actions {
      Sandston;
   }
   size : 512;
}
action Roosville( Chloride ) {
   modify_field( Starkey.Waucousta, Chloride );
}
table Barron {
   reads {
     Bigspring.Keokee : ternary;
   }
   actions {
      Roosville;
   }
   size : 512;
}
action Victoria( Blevins ) {
   modify_field( Starkey.Swenson, Blevins );
}
action Mogadore( Elvaston ) {
   modify_field( Starkey.Swenson, Elvaston );
}
@pragma ways 2
table Wilton {
   reads {
     Bigspring.Verdemont : exact;
     Bigspring.Homeworth mask 4 : exact;
     Bigspring.Hanks : exact;
   }
   actions {
      Victoria;
      MintHill;
   }
   default_action : MintHill();
   size : 4096;
}
@pragma ways 1
table Gomez {
   reads {
     Bigspring.Verdemont : exact;
     Bigspring.Homeworth mask 4 : exact;
     Talmo.Lumpkin : exact;
   }
   actions {
      Mogadore;
   }
   size : 512;
}
control Sunflower {
   if( Bigspring.Verdemont == 1 ) {
      apply( Endicott );
      apply( Monmouth );
   } else if( Bigspring.Verdemont == 2 ) {
      apply( Grasmere );
      apply( Waukegan );
   }
   if( ( Bigspring.Homeworth & 2 ) == 2 ) {
      apply( Grenville );
      apply( Barron );
   }
   if( Starkey.Swenson == 0 ) {
      apply( Wilton ) {
         MintHill {
            apply( Gomez );
         }
      }
   }
}
action Excello() {
}
action Salamonia() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action Cistern() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
}
action Tallevast() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
table Portales {
   reads {
     Gresston.Ovett mask 0x00018000 : ternary;
   }
   actions {
      Excello;
      Salamonia;
      Cistern;
      Tallevast;
   }
   size : 16;
}
control Libby {
   apply( Portales );
   apply( Belfalls );
}
   metadata Browndell Gresston;
   action GlenDean( Drake ) {
          max( Gresston.Ovett, Gresston.Ovett, Drake );
   }
@pragma ways 4
table Claysburg {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : exact;
      Starkey.Blairsden : exact;
      Starkey.WarEagle : exact;
      Starkey.Waucousta : exact;
      Starkey.Weches : exact;
      Starkey.Lemont : exact;
      Starkey.Riley : exact;
      Starkey.Avondale : exact;
      Starkey.Angle : exact;
   }
   actions {
      GlenDean;
   }
   size : 4096;
}
control Larose {
   apply( Claysburg );
}
table Oilmont {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : ternary;
      Starkey.Blairsden : ternary;
      Starkey.WarEagle : ternary;
      Starkey.Waucousta : ternary;
      Starkey.Weches : ternary;
      Starkey.Lemont : ternary;
      Starkey.Riley : ternary;
      Starkey.Avondale : ternary;
      Starkey.Angle : ternary;
   }
   actions {
      GlenDean;
   }
   size : 512;
}
control Danese {
   apply( Oilmont );
}
@pragma pa_no_init ingress Sammamish.Asherton
@pragma pa_no_init ingress Sammamish.Blairsden
@pragma pa_no_init ingress Sammamish.WarEagle
@pragma pa_no_init ingress Sammamish.Waucousta
@pragma pa_no_init ingress Sammamish.Weches
@pragma pa_no_init ingress Sammamish.Lemont
@pragma pa_no_init ingress Sammamish.Riley
@pragma pa_no_init ingress Sammamish.Avondale
@pragma pa_no_init ingress Sammamish.Angle
metadata Greenbelt Sammamish;
@pragma ways 4
table Thalia {
   reads {
      Starkey.Swenson : exact;
      Sammamish.Asherton : exact;
      Sammamish.Blairsden : exact;
      Sammamish.WarEagle : exact;
      Sammamish.Waucousta : exact;
      Sammamish.Weches : exact;
      Sammamish.Lemont : exact;
      Sammamish.Riley : exact;
      Sammamish.Avondale : exact;
      Sammamish.Angle : exact;
   }
   actions {
      GlenDean;
   }
   size : 8192;
}
action Ouachita( Lenexa, Adona, Anvik, Swisshome, Jelloway, Amboy, RushHill, Sandstone, Tolley ) {
   bit_and( Sammamish.Asherton, Starkey.Asherton, Lenexa );
   bit_and( Sammamish.Blairsden, Starkey.Blairsden, Adona );
   bit_and( Sammamish.WarEagle, Starkey.WarEagle, Anvik );
   bit_and( Sammamish.Waucousta, Starkey.Waucousta, Swisshome );
   bit_and( Sammamish.Weches, Starkey.Weches, Jelloway );
   bit_and( Sammamish.Lemont, Starkey.Lemont, Amboy );
   bit_and( Sammamish.Riley, Starkey.Riley, RushHill );
   bit_and( Sammamish.Avondale, Starkey.Avondale, Sandstone );
   bit_and( Sammamish.Angle, Starkey.Angle, Tolley );
}
table Berea {
   reads {
      Starkey.Swenson : exact;
   }
   actions {
      Ouachita;
   }
   default_action : Ouachita(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Onava {
   apply( Berea );
}
control Visalia {
   apply( Thalia );
}
table LaHoma {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : ternary;
      Starkey.Blairsden : ternary;
      Starkey.WarEagle : ternary;
      Starkey.Waucousta : ternary;
      Starkey.Weches : ternary;
      Starkey.Lemont : ternary;
      Starkey.Riley : ternary;
      Starkey.Avondale : ternary;
      Starkey.Angle : ternary;
   }
   actions {
      GlenDean;
   }
   size : 512;
}
control Braselton {
   apply( LaHoma );
}
@pragma ways 4
table Snohomish {
   reads {
      Starkey.Swenson : exact;
      Sammamish.Asherton : exact;
      Sammamish.Blairsden : exact;
      Sammamish.WarEagle : exact;
      Sammamish.Waucousta : exact;
      Sammamish.Weches : exact;
      Sammamish.Lemont : exact;
      Sammamish.Riley : exact;
      Sammamish.Avondale : exact;
      Sammamish.Angle : exact;
   }
   actions {
      GlenDean;
   }
   size : 4096;
}
action Cisco( McIntyre, Gallion, Donna, Hickox, Daisytown, Bokeelia, Rushmore, Eastover, Bushland ) {
   bit_and( Sammamish.Asherton, Starkey.Asherton, McIntyre );
   bit_and( Sammamish.Blairsden, Starkey.Blairsden, Gallion );
   bit_and( Sammamish.WarEagle, Starkey.WarEagle, Donna );
   bit_and( Sammamish.Waucousta, Starkey.Waucousta, Hickox );
   bit_and( Sammamish.Weches, Starkey.Weches, Daisytown );
   bit_and( Sammamish.Lemont, Starkey.Lemont, Bokeelia );
   bit_and( Sammamish.Riley, Starkey.Riley, Rushmore );
   bit_and( Sammamish.Avondale, Starkey.Avondale, Eastover );
   bit_and( Sammamish.Angle, Starkey.Angle, Bushland );
}
table Wingate {
   reads {
      Starkey.Swenson : exact;
   }
   actions {
      Cisco;
   }
   default_action : Cisco(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Vinita {
   apply( Wingate );
}
control Stidham {
   apply( Snohomish );
}
table Wakeman {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : ternary;
      Starkey.Blairsden : ternary;
      Starkey.WarEagle : ternary;
      Starkey.Waucousta : ternary;
      Starkey.Weches : ternary;
      Starkey.Lemont : ternary;
      Starkey.Riley : ternary;
      Starkey.Avondale : ternary;
      Starkey.Angle : ternary;
   }
   actions {
      GlenDean;
   }
   size : 512;
}
control Lordstown {
   apply( Wakeman );
}
@pragma ways 4
table Gardiner {
   reads {
      Starkey.Swenson : exact;
      Sammamish.Asherton : exact;
      Sammamish.Blairsden : exact;
      Sammamish.WarEagle : exact;
      Sammamish.Waucousta : exact;
      Sammamish.Weches : exact;
      Sammamish.Lemont : exact;
      Sammamish.Riley : exact;
      Sammamish.Avondale : exact;
      Sammamish.Angle : exact;
   }
   actions {
      GlenDean;
   }
   size : 4096;
}
action Menifee( Westway, Shirley, Bellmead, Vantage, Follett, Jenkins, Poplar, PawPaw, WindGap ) {
   bit_and( Sammamish.Asherton, Starkey.Asherton, Westway );
   bit_and( Sammamish.Blairsden, Starkey.Blairsden, Shirley );
   bit_and( Sammamish.WarEagle, Starkey.WarEagle, Bellmead );
   bit_and( Sammamish.Waucousta, Starkey.Waucousta, Vantage );
   bit_and( Sammamish.Weches, Starkey.Weches, Follett );
   bit_and( Sammamish.Lemont, Starkey.Lemont, Jenkins );
   bit_and( Sammamish.Riley, Starkey.Riley, Poplar );
   bit_and( Sammamish.Avondale, Starkey.Avondale, PawPaw );
   bit_and( Sammamish.Angle, Starkey.Angle, WindGap );
}
table Greycliff {
   reads {
      Starkey.Swenson : exact;
   }
   actions {
      Menifee;
   }
   default_action : Menifee(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Airmont {
   apply( Greycliff );
}
control Minto {
   apply( Gardiner );
}
table Camelot {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : ternary;
      Starkey.Blairsden : ternary;
      Starkey.WarEagle : ternary;
      Starkey.Waucousta : ternary;
      Starkey.Weches : ternary;
      Starkey.Lemont : ternary;
      Starkey.Riley : ternary;
      Starkey.Avondale : ternary;
      Starkey.Angle : ternary;
   }
   actions {
      GlenDean;
   }
   size : 512;
}
control Shongaloo {
   apply( Camelot );
}
@pragma ways 4
table Wainaku {
   reads {
      Starkey.Swenson : exact;
      Sammamish.Asherton : exact;
      Sammamish.Blairsden : exact;
      Sammamish.WarEagle : exact;
      Sammamish.Waucousta : exact;
      Sammamish.Weches : exact;
      Sammamish.Lemont : exact;
      Sammamish.Riley : exact;
      Sammamish.Avondale : exact;
      Sammamish.Angle : exact;
   }
   actions {
      GlenDean;
   }
   size : 8192;
}
action Alburnett( Wabbaseka, Blakeman, Brothers, Edgemont, Calcium, Jermyn, Winters, Cascade, CruzBay ) {
   bit_and( Sammamish.Asherton, Starkey.Asherton, Wabbaseka );
   bit_and( Sammamish.Blairsden, Starkey.Blairsden, Blakeman );
   bit_and( Sammamish.WarEagle, Starkey.WarEagle, Brothers );
   bit_and( Sammamish.Waucousta, Starkey.Waucousta, Edgemont );
   bit_and( Sammamish.Weches, Starkey.Weches, Calcium );
   bit_and( Sammamish.Lemont, Starkey.Lemont, Jermyn );
   bit_and( Sammamish.Riley, Starkey.Riley, Winters );
   bit_and( Sammamish.Avondale, Starkey.Avondale, Cascade );
   bit_and( Sammamish.Angle, Starkey.Angle, CruzBay );
}
table Perma {
   reads {
      Starkey.Swenson : exact;
   }
   actions {
      Alburnett;
   }
   default_action : Alburnett(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Heuvelton {
   apply( Perma );
}
control Fairborn {
   apply( Wainaku );
}
table BigBay {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : ternary;
      Starkey.Blairsden : ternary;
      Starkey.WarEagle : ternary;
      Starkey.Waucousta : ternary;
      Starkey.Weches : ternary;
      Starkey.Lemont : ternary;
      Starkey.Riley : ternary;
      Starkey.Avondale : ternary;
      Starkey.Angle : ternary;
   }
   actions {
      GlenDean;
   }
   size : 512;
}
control Kinsey {
   apply( BigBay );
}
@pragma ways 4
table Henry {
   reads {
      Starkey.Swenson : exact;
      Sammamish.Asherton : exact;
      Sammamish.Blairsden : exact;
      Sammamish.WarEagle : exact;
      Sammamish.Waucousta : exact;
      Sammamish.Weches : exact;
      Sammamish.Lemont : exact;
      Sammamish.Riley : exact;
      Sammamish.Avondale : exact;
      Sammamish.Angle : exact;
   }
   actions {
      GlenDean;
   }
   size : 8192;
}
action BigFork( Buncombe, Belview, Ramapo, BallClub, Tidewater, Belfast, Conklin, Louin, Commack ) {
   bit_and( Sammamish.Asherton, Starkey.Asherton, Buncombe );
   bit_and( Sammamish.Blairsden, Starkey.Blairsden, Belview );
   bit_and( Sammamish.WarEagle, Starkey.WarEagle, Ramapo );
   bit_and( Sammamish.Waucousta, Starkey.Waucousta, BallClub );
   bit_and( Sammamish.Weches, Starkey.Weches, Tidewater );
   bit_and( Sammamish.Lemont, Starkey.Lemont, Belfast );
   bit_and( Sammamish.Riley, Starkey.Riley, Conklin );
   bit_and( Sammamish.Avondale, Starkey.Avondale, Louin );
   bit_and( Sammamish.Angle, Starkey.Angle, Commack );
}
table Grampian {
   reads {
      Starkey.Swenson : exact;
   }
   actions {
      BigFork;
   }
   default_action : BigFork(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Beaufort {
   apply( Grampian );
}
control Elsmere {
   apply( Henry );
}
table Suwannee {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : ternary;
      Starkey.Blairsden : ternary;
      Starkey.WarEagle : ternary;
      Starkey.Waucousta : ternary;
      Starkey.Weches : ternary;
      Starkey.Lemont : ternary;
      Starkey.Riley : ternary;
      Starkey.Avondale : ternary;
      Starkey.Angle : ternary;
   }
   actions {
      GlenDean;
   }
   size : 512;
}
control Gobles {
   apply( Suwannee );
}
@pragma ways 4
table Westpoint {
   reads {
      Starkey.Swenson : exact;
      Sammamish.Asherton : exact;
      Sammamish.Blairsden : exact;
      Sammamish.WarEagle : exact;
      Sammamish.Waucousta : exact;
      Sammamish.Weches : exact;
      Sammamish.Lemont : exact;
      Sammamish.Riley : exact;
      Sammamish.Avondale : exact;
      Sammamish.Angle : exact;
   }
   actions {
      GlenDean;
   }
   size : 4096;
}
action Fentress( Thayne, Nerstrand, Minburn, Clifton, Alderson, Convoy, Freedom, Boquet, Weathers ) {
   bit_and( Sammamish.Asherton, Starkey.Asherton, Thayne );
   bit_and( Sammamish.Blairsden, Starkey.Blairsden, Nerstrand );
   bit_and( Sammamish.WarEagle, Starkey.WarEagle, Minburn );
   bit_and( Sammamish.Waucousta, Starkey.Waucousta, Clifton );
   bit_and( Sammamish.Weches, Starkey.Weches, Alderson );
   bit_and( Sammamish.Lemont, Starkey.Lemont, Convoy );
   bit_and( Sammamish.Riley, Starkey.Riley, Freedom );
   bit_and( Sammamish.Avondale, Starkey.Avondale, Boquet );
   bit_and( Sammamish.Angle, Starkey.Angle, Weathers );
}
table Morgana {
   reads {
      Starkey.Swenson : exact;
   }
   actions {
      Fentress;
   }
   default_action : Fentress(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Traverse {
   apply( Morgana );
}
control Dahlgren {
   apply( Westpoint );
}
table Colmar {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : ternary;
      Starkey.Blairsden : ternary;
      Starkey.WarEagle : ternary;
      Starkey.Waucousta : ternary;
      Starkey.Weches : ternary;
      Starkey.Lemont : ternary;
      Starkey.Riley : ternary;
      Starkey.Avondale : ternary;
      Starkey.Angle : ternary;
   }
   actions {
      GlenDean;
   }
   size : 512;
}
control Monico {
   apply( Colmar );
}
@pragma ways 4
table Dryden {
   reads {
      Starkey.Swenson : exact;
      Sammamish.Asherton : exact;
      Sammamish.Blairsden : exact;
      Sammamish.WarEagle : exact;
      Sammamish.Waucousta : exact;
      Sammamish.Weches : exact;
      Sammamish.Lemont : exact;
      Sammamish.Riley : exact;
      Sammamish.Avondale : exact;
      Sammamish.Angle : exact;
   }
   actions {
      GlenDean;
   }
   size : 4096;
}
action Verdery( Taopi, ElToro, Adams, Eaton, Nickerson, Dillsboro, Cahokia, OldMinto, Vestaburg ) {
   bit_and( Sammamish.Asherton, Starkey.Asherton, Taopi );
   bit_and( Sammamish.Blairsden, Starkey.Blairsden, ElToro );
   bit_and( Sammamish.WarEagle, Starkey.WarEagle, Adams );
   bit_and( Sammamish.Waucousta, Starkey.Waucousta, Eaton );
   bit_and( Sammamish.Weches, Starkey.Weches, Nickerson );
   bit_and( Sammamish.Lemont, Starkey.Lemont, Dillsboro );
   bit_and( Sammamish.Riley, Starkey.Riley, Cahokia );
   bit_and( Sammamish.Avondale, Starkey.Avondale, OldMinto );
   bit_and( Sammamish.Angle, Starkey.Angle, Vestaburg );
}
table Cornell {
   reads {
      Starkey.Swenson : exact;
   }
   actions {
      Verdery;
   }
   default_action : Verdery(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Latham {
   apply( Cornell );
}
control Kansas {
   apply( Dryden );
}
table Neosho {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : ternary;
      Starkey.Blairsden : ternary;
      Starkey.WarEagle : ternary;
      Starkey.Waucousta : ternary;
      Starkey.Weches : ternary;
      Starkey.Lemont : ternary;
      Starkey.Riley : ternary;
      Starkey.Avondale : ternary;
      Starkey.Angle : ternary;
   }
   actions {
      GlenDean;
   }
   size : 512;
}
control Gladstone {
   apply( Neosho );
}
   metadata Browndell Kahua;
   action Brockton( Arial ) {
          max( Kahua.Ovett, Kahua.Ovett, Arial );
   }
   action Ihlen() { max( Gresston.Ovett, Kahua.Ovett, Gresston.Ovett ); } table Washta { actions { Ihlen; } default_action : Ihlen; size : 1; } control Nathan { apply( Washta ); }
@pragma ways 4
table Bomarton {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : exact;
      Starkey.Blairsden : exact;
      Starkey.WarEagle : exact;
      Starkey.Waucousta : exact;
      Starkey.Weches : exact;
      Starkey.Lemont : exact;
      Starkey.Riley : exact;
      Starkey.Avondale : exact;
      Starkey.Angle : exact;
   }
   actions {
      Brockton;
   }
   size : 4096;
}
control Loughman {
   apply( Bomarton );
}
table Aldan {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : ternary;
      Starkey.Blairsden : ternary;
      Starkey.WarEagle : ternary;
      Starkey.Waucousta : ternary;
      Starkey.Weches : ternary;
      Starkey.Lemont : ternary;
      Starkey.Riley : ternary;
      Starkey.Avondale : ternary;
      Starkey.Angle : ternary;
   }
   actions {
      Brockton;
   }
   size : 4096;
}
control Dunnegan {
   apply( Aldan );
}
@pragma pa_no_init ingress Dixon.Asherton
@pragma pa_no_init ingress Dixon.Blairsden
@pragma pa_no_init ingress Dixon.WarEagle
@pragma pa_no_init ingress Dixon.Waucousta
@pragma pa_no_init ingress Dixon.Weches
@pragma pa_no_init ingress Dixon.Lemont
@pragma pa_no_init ingress Dixon.Riley
@pragma pa_no_init ingress Dixon.Avondale
@pragma pa_no_init ingress Dixon.Angle
metadata Greenbelt Dixon;
@pragma ways 4
table Claiborne {
   reads {
      Starkey.Swenson : exact;
      Dixon.Asherton : exact;
      Dixon.Blairsden : exact;
      Dixon.WarEagle : exact;
      Dixon.Waucousta : exact;
      Dixon.Weches : exact;
      Dixon.Lemont : exact;
      Dixon.Riley : exact;
      Dixon.Avondale : exact;
      Dixon.Angle : exact;
   }
   actions {
      Brockton;
   }
   size : 4096;
}
action Bowen( Beaverdam, Lawnside, Hookstown, Benson, Bazine, Luhrig, Farnham, Naylor, Donald ) {
   bit_and( Dixon.Asherton, Starkey.Asherton, Beaverdam );
   bit_and( Dixon.Blairsden, Starkey.Blairsden, Lawnside );
   bit_and( Dixon.WarEagle, Starkey.WarEagle, Hookstown );
   bit_and( Dixon.Waucousta, Starkey.Waucousta, Benson );
   bit_and( Dixon.Weches, Starkey.Weches, Bazine );
   bit_and( Dixon.Lemont, Starkey.Lemont, Luhrig );
   bit_and( Dixon.Riley, Starkey.Riley, Farnham );
   bit_and( Dixon.Avondale, Starkey.Avondale, Naylor );
   bit_and( Dixon.Angle, Starkey.Angle, Donald );
}
table Cowan {
   reads {
      Starkey.Swenson : exact;
   }
   actions {
      Bowen;
   }
   default_action : Bowen(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Lahaina {
   apply( Cowan );
}
control Comal {
   apply( Claiborne );
}
table Langdon {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : ternary;
      Starkey.Blairsden : ternary;
      Starkey.WarEagle : ternary;
      Starkey.Waucousta : ternary;
      Starkey.Weches : ternary;
      Starkey.Lemont : ternary;
      Starkey.Riley : ternary;
      Starkey.Avondale : ternary;
      Starkey.Angle : ternary;
   }
   actions {
      Brockton;
   }
   size : 512;
}
control Grants {
   apply( Langdon );
}
@pragma ways 4
table LeCenter {
   reads {
      Starkey.Swenson : exact;
      Dixon.Asherton : exact;
      Dixon.Blairsden : exact;
      Dixon.WarEagle : exact;
      Dixon.Waucousta : exact;
      Dixon.Weches : exact;
      Dixon.Lemont : exact;
      Dixon.Riley : exact;
      Dixon.Avondale : exact;
      Dixon.Angle : exact;
   }
   actions {
      Brockton;
   }
   size : 4096;
}
action Terlingua( Homeacre, PaloAlto, Edgemoor, Holliday, Gunder, Inkom, ElmCity, Aiken, Barksdale ) {
   bit_and( Dixon.Asherton, Starkey.Asherton, Homeacre );
   bit_and( Dixon.Blairsden, Starkey.Blairsden, PaloAlto );
   bit_and( Dixon.WarEagle, Starkey.WarEagle, Edgemoor );
   bit_and( Dixon.Waucousta, Starkey.Waucousta, Holliday );
   bit_and( Dixon.Weches, Starkey.Weches, Gunder );
   bit_and( Dixon.Lemont, Starkey.Lemont, Inkom );
   bit_and( Dixon.Riley, Starkey.Riley, ElmCity );
   bit_and( Dixon.Avondale, Starkey.Avondale, Aiken );
   bit_and( Dixon.Angle, Starkey.Angle, Barksdale );
}
table Mullins {
   reads {
      Starkey.Swenson : exact;
   }
   actions {
      Terlingua;
   }
   default_action : Terlingua(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Robbs {
   apply( Mullins );
}
control Modale {
   apply( LeCenter );
}
table Ketchum {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : ternary;
      Starkey.Blairsden : ternary;
      Starkey.WarEagle : ternary;
      Starkey.Waucousta : ternary;
      Starkey.Weches : ternary;
      Starkey.Lemont : ternary;
      Starkey.Riley : ternary;
      Starkey.Avondale : ternary;
      Starkey.Angle : ternary;
   }
   actions {
      Brockton;
   }
   size : 512;
}
control Tarnov {
   apply( Ketchum );
}
@pragma ways 4
table Mendon {
   reads {
      Starkey.Swenson : exact;
      Dixon.Asherton : exact;
      Dixon.Blairsden : exact;
      Dixon.WarEagle : exact;
      Dixon.Waucousta : exact;
      Dixon.Weches : exact;
      Dixon.Lemont : exact;
      Dixon.Riley : exact;
      Dixon.Avondale : exact;
      Dixon.Angle : exact;
   }
   actions {
      Brockton;
   }
   size : 4096;
}
action Leetsdale( Preston, Westline, TonkaBay, Neshoba, Rosebush, Gower, Becida, Chenequa, Bardwell ) {
   bit_and( Dixon.Asherton, Starkey.Asherton, Preston );
   bit_and( Dixon.Blairsden, Starkey.Blairsden, Westline );
   bit_and( Dixon.WarEagle, Starkey.WarEagle, TonkaBay );
   bit_and( Dixon.Waucousta, Starkey.Waucousta, Neshoba );
   bit_and( Dixon.Weches, Starkey.Weches, Rosebush );
   bit_and( Dixon.Lemont, Starkey.Lemont, Gower );
   bit_and( Dixon.Riley, Starkey.Riley, Becida );
   bit_and( Dixon.Avondale, Starkey.Avondale, Chenequa );
   bit_and( Dixon.Angle, Starkey.Angle, Bardwell );
}
table Ericsburg {
   reads {
      Starkey.Swenson : exact;
   }
   actions {
      Leetsdale;
   }
   default_action : Leetsdale(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Volens {
   apply( Ericsburg );
}
control Lebanon {
   apply( Mendon );
}
table Fitler {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : ternary;
      Starkey.Blairsden : ternary;
      Starkey.WarEagle : ternary;
      Starkey.Waucousta : ternary;
      Starkey.Weches : ternary;
      Starkey.Lemont : ternary;
      Starkey.Riley : ternary;
      Starkey.Avondale : ternary;
      Starkey.Angle : ternary;
   }
   actions {
      Brockton;
   }
   size : 512;
}
control Longford {
   apply( Fitler );
}
@pragma ways 4
table Kniman {
   reads {
      Starkey.Swenson : exact;
      Dixon.Asherton : exact;
      Dixon.Blairsden : exact;
      Dixon.WarEagle : exact;
      Dixon.Waucousta : exact;
      Dixon.Weches : exact;
      Dixon.Lemont : exact;
      Dixon.Riley : exact;
      Dixon.Avondale : exact;
      Dixon.Angle : exact;
   }
   actions {
      Brockton;
   }
   size : 4096;
}
action Hettinger( Thach, Helotes, Eldena, Ohiowa, Waitsburg, Lublin, Missoula, Dickson, Coleman ) {
   bit_and( Dixon.Asherton, Starkey.Asherton, Thach );
   bit_and( Dixon.Blairsden, Starkey.Blairsden, Helotes );
   bit_and( Dixon.WarEagle, Starkey.WarEagle, Eldena );
   bit_and( Dixon.Waucousta, Starkey.Waucousta, Ohiowa );
   bit_and( Dixon.Weches, Starkey.Weches, Waitsburg );
   bit_and( Dixon.Lemont, Starkey.Lemont, Lublin );
   bit_and( Dixon.Riley, Starkey.Riley, Missoula );
   bit_and( Dixon.Avondale, Starkey.Avondale, Dickson );
   bit_and( Dixon.Angle, Starkey.Angle, Coleman );
}
table Ardara {
   reads {
      Starkey.Swenson : exact;
   }
   actions {
      Hettinger;
   }
   default_action : Hettinger(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Stonefort {
   apply( Ardara );
}
control Quamba {
   apply( Kniman );
}
table Chubbuck {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : ternary;
      Starkey.Blairsden : ternary;
      Starkey.WarEagle : ternary;
      Starkey.Waucousta : ternary;
      Starkey.Weches : ternary;
      Starkey.Lemont : ternary;
      Starkey.Riley : ternary;
      Starkey.Avondale : ternary;
      Starkey.Angle : ternary;
   }
   actions {
      Brockton;
   }
   size : 512;
}
control Neche {
   apply( Chubbuck );
}
@pragma ways 4
table Froid {
   reads {
      Starkey.Swenson : exact;
      Dixon.Asherton : exact;
      Dixon.Blairsden : exact;
      Dixon.WarEagle : exact;
      Dixon.Waucousta : exact;
      Dixon.Weches : exact;
      Dixon.Lemont : exact;
      Dixon.Riley : exact;
      Dixon.Avondale : exact;
      Dixon.Angle : exact;
   }
   actions {
      Brockton;
   }
   size : 4096;
}
action Embarrass( Green, Bangor, Ugashik, Campton, BigBow, Sasakwa, FarrWest, Blossburg, Towaoc ) {
   bit_and( Dixon.Asherton, Starkey.Asherton, Green );
   bit_and( Dixon.Blairsden, Starkey.Blairsden, Bangor );
   bit_and( Dixon.WarEagle, Starkey.WarEagle, Ugashik );
   bit_and( Dixon.Waucousta, Starkey.Waucousta, Campton );
   bit_and( Dixon.Weches, Starkey.Weches, BigBow );
   bit_and( Dixon.Lemont, Starkey.Lemont, Sasakwa );
   bit_and( Dixon.Riley, Starkey.Riley, FarrWest );
   bit_and( Dixon.Avondale, Starkey.Avondale, Blossburg );
   bit_and( Dixon.Angle, Starkey.Angle, Towaoc );
}
table Canjilon {
   reads {
      Starkey.Swenson : exact;
   }
   actions {
      Embarrass;
   }
   default_action : Embarrass(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Wenham {
   apply( Canjilon );
}
control Hyrum {
   apply( Froid );
}
table Midville {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : ternary;
      Starkey.Blairsden : ternary;
      Starkey.WarEagle : ternary;
      Starkey.Waucousta : ternary;
      Starkey.Weches : ternary;
      Starkey.Lemont : ternary;
      Starkey.Riley : ternary;
      Starkey.Avondale : ternary;
      Starkey.Angle : ternary;
   }
   actions {
      Brockton;
   }
   size : 512;
}
control Summit {
   apply( Midville );
}
@pragma ways 4
table Calabash {
   reads {
      Starkey.Swenson : exact;
      Dixon.Asherton : exact;
      Dixon.Blairsden : exact;
      Dixon.WarEagle : exact;
      Dixon.Waucousta : exact;
      Dixon.Weches : exact;
      Dixon.Lemont : exact;
      Dixon.Riley : exact;
      Dixon.Avondale : exact;
      Dixon.Angle : exact;
   }
   actions {
      Brockton;
   }
   size : 4096;
}
action Ragley( Blencoe, BarNunn, Vesuvius, Terral, Guion, Petrolia, Center, CleElum, Gilmanton ) {
   bit_and( Dixon.Asherton, Starkey.Asherton, Blencoe );
   bit_and( Dixon.Blairsden, Starkey.Blairsden, BarNunn );
   bit_and( Dixon.WarEagle, Starkey.WarEagle, Vesuvius );
   bit_and( Dixon.Waucousta, Starkey.Waucousta, Terral );
   bit_and( Dixon.Weches, Starkey.Weches, Guion );
   bit_and( Dixon.Lemont, Starkey.Lemont, Petrolia );
   bit_and( Dixon.Riley, Starkey.Riley, Center );
   bit_and( Dixon.Avondale, Starkey.Avondale, CleElum );
   bit_and( Dixon.Angle, Starkey.Angle, Gilmanton );
}
table Temvik {
   reads {
      Starkey.Swenson : exact;
   }
   actions {
      Ragley;
   }
   default_action : Ragley(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Hotchkiss {
   apply( Temvik );
}
control Perryman {
   apply( Calabash );
}
table Monida {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : ternary;
      Starkey.Blairsden : ternary;
      Starkey.WarEagle : ternary;
      Starkey.Waucousta : ternary;
      Starkey.Weches : ternary;
      Starkey.Lemont : ternary;
      Starkey.Riley : ternary;
      Starkey.Avondale : ternary;
      Starkey.Angle : ternary;
   }
   actions {
      Brockton;
   }
   size : 512;
}
control Odenton {
   apply( Monida );
}
@pragma ways 4
table Montegut {
   reads {
      Starkey.Swenson : exact;
      Dixon.Asherton : exact;
      Dixon.Blairsden : exact;
      Dixon.WarEagle : exact;
      Dixon.Waucousta : exact;
      Dixon.Weches : exact;
      Dixon.Lemont : exact;
      Dixon.Riley : exact;
      Dixon.Avondale : exact;
      Dixon.Angle : exact;
   }
   actions {
      Brockton;
   }
   size : 4096;
}
action Tatitlek( UnionGap, Woodrow, Colburn, Emden, DimeBox, Astatula, Farson, SanPablo, Steger ) {
   bit_and( Dixon.Asherton, Starkey.Asherton, UnionGap );
   bit_and( Dixon.Blairsden, Starkey.Blairsden, Woodrow );
   bit_and( Dixon.WarEagle, Starkey.WarEagle, Colburn );
   bit_and( Dixon.Waucousta, Starkey.Waucousta, Emden );
   bit_and( Dixon.Weches, Starkey.Weches, DimeBox );
   bit_and( Dixon.Lemont, Starkey.Lemont, Astatula );
   bit_and( Dixon.Riley, Starkey.Riley, Farson );
   bit_and( Dixon.Avondale, Starkey.Avondale, SanPablo );
   bit_and( Dixon.Angle, Starkey.Angle, Steger );
}
table Deering {
   reads {
      Starkey.Swenson : exact;
   }
   actions {
      Tatitlek;
   }
   default_action : Tatitlek(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Grasston {
   apply( Deering );
}
control Martelle {
   apply( Montegut );
}
table Kathleen {
   reads {
      Starkey.Swenson : exact;
      Starkey.Asherton : ternary;
      Starkey.Blairsden : ternary;
      Starkey.WarEagle : ternary;
      Starkey.Waucousta : ternary;
      Starkey.Weches : ternary;
      Starkey.Lemont : ternary;
      Starkey.Riley : ternary;
      Starkey.Avondale : ternary;
      Starkey.Angle : ternary;
   }
   actions {
      Brockton;
   }
   size : 512;
}
control Roseau {
   apply( Kathleen );
}
action Oriskany( RioLajas ) {
   modify_field( Upalco.Dollar, RioLajas );
   bit_or( Aynor.Roswell, Coupland.Cornville, 0x80 );
}
action Janney( Lopeno ) {
   modify_field( Upalco.Dollar, Lopeno );
   bit_or( PineLawn.Reinbeck, Coupland.Cornville, 0x80 );
}
table RedElm {
   reads {
      Coupland.Cornville mask 0x80 : exact;
      Aynor.valid : exact;
      PineLawn.valid : exact;
   }
   actions {
      Oriskany;
      Janney;
   }
   size : 8;
}
action Choptank() {
   modify_field( Aynor.Roswell, 0, 0x80 );
}
action Darby() {
   modify_field( PineLawn.Reinbeck, 0, 0x80 );
}
table Skyline {
   reads {
     Upalco.Dollar : exact;
     Aynor.valid : exact;
     PineLawn.valid : exact;
   }
   actions {
      Choptank;
      Darby;
   }
   size : 16;
}
action Edroy(Pelland)
{
   modify_field( Upalco.Westview, 1 );
   modify_field( Upalco.Ackerly, Pelland);
}
action Finney(Arroyo) {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
   modify_field( Upalco.Ackerly, Arroyo);
}
table Yantis {
   reads {
      Bigspring.Kenvil : ternary;
      Bigspring.Combine : ternary;
      Bigspring.Macon : ternary;
      Bigspring.Hanks : ternary;
      Bigspring.Homeworth : ternary;
      Bigspring.Kokadjo : ternary;
      Bigspring.Keokee : ternary;
      Talmo.Lumpkin : ternary;
      Wyanet.Winfall : ternary;
      Bigspring.RioLinda : ternary;
   }
   actions {
      Edroy;
      Finney;
   }
   size : 512;
}
control Immokalee {
   apply( Yantis );
}
field_list Merkel {
   Bigspring.Marquette;
}
field_list Sixteen {
   Bigspring.Marquette;
}
field_list Tulalip {
   Moraine.Surrency;
}
field_list_calculation Caplis {
    input {
        Tulalip;
    }
    algorithm : identity;
    output_width : 51;
}
field_list Nederland {
   Moraine.Surrency;
}
field_list_calculation Bosworth {
    input {
        Nederland;
    }
    algorithm : identity;
    output_width : 51;
}
action Ivanpah( ElCentro ) {
   modify_field( Aplin.Spiro, ElCentro );
   modify_field( Aplin.Corona, ElCentro );
}
table Nuevo {
   reads {
      Talmo.Lumpkin : ternary;
      Starkey.Micro : ternary;
      Starkey.Robert : ternary;
      DeBeque.Tatum : ternary;
      Bigspring.Correo : ternary;
      Bigspring.RioLinda : ternary;
      ElDorado.Folcroft : ternary;
      ElDorado.Engle : ternary;
   }
   actions {
      Ivanpah;
   }
   default_action : Ivanpah(0);
   size : 1024;
}
control Hueytown {
   apply( Nuevo );
}
meter Ellisport {
   type : bytes;
   static : Trooper;
   instance_count : 128;
}
action Pekin( Forepaugh ) {
   execute_meter( Ellisport, Forepaugh, Aplin.BirchBay );
}
table Trooper {
   reads {
      Aplin.Spiro : exact;
   }
   actions {
      Pekin;
   }
   size : 128;
}
control Shields {
   apply( Trooper );
}
action Milwaukie() {
   clone_ingress_pkt_to_egress( Aplin.Corona, Merkel );
}
table Oconee {
   reads {
      Aplin.BirchBay : exact;
   }
   actions {
      Milwaukie;
   }
   size : 2;
}
control Makawao {
   if( Aplin.Spiro != 0 ) {
      apply( Oconee );
   }
}
action_selector Lisle {
    selection_key : Caplis;
    selection_mode : resilient;
}
action Raven( Arcanum ) {
   bit_or( Aplin.Corona, Aplin.Corona, Arcanum );
}
action_profile Ringold {
   actions {
      Raven;
   }
   size : 512;
   dynamic_action_selection : Lisle;
}
table Islen {
   reads {
      Aplin.Spiro : exact;
   }
   action_profile : Ringold;
   size : 128;
}
control Hansell {
   apply( Islen );
}
action Angola() {
   modify_field( Upalco.DewyRose, 0 );
   modify_field( Upalco.Alsen, 3 );
}
action Pinole( Hatfield, Champlin, Catawissa, McAdams, Kelliher, Maida,
      Sunman, Grainola ) {
   modify_field( Upalco.DewyRose, 0 );
   modify_field( Upalco.Alsen, 4 );
   add_header( Aynor );
   modify_field( Aynor.Esmond, 0x4);
   modify_field( Aynor.Brinklow, 0x5);
   modify_field( Aynor.ElkNeck, McAdams);
   modify_field( Aynor.Roswell, 47 );
   modify_field( Aynor.Worthing, Catawissa);
   modify_field( Aynor.HamLake, 0 );
   modify_field( Aynor.Konnarock, 0 );
   modify_field( Aynor.Kingsgate, 0 );
   modify_field( Aynor.Rayville, Hatfield);
   modify_field( Aynor.Kinross, Champlin);
   add( Aynor.Pierre, eg_intr_md.pkt_length, 24 );
   add_header( Suarez );
   modify_field( Suarez.Stilson, Kelliher);
   modify_field( Upalco.Kelvin, Maida );
   modify_field( Upalco.Bledsoe, Sunman );
   modify_field( Upalco.Coamo, Grainola );
}
action Amasa() {
   modify_field( Upalco.Ravenwood, 1 );
   modify_field( Upalco.DewyRose, 0 );
   modify_field( Upalco.Alsen, 2 );
   modify_field( Upalco.Baytown, 1 );
}
@pragma ways 2
table Kingman {
   reads {
      eg_intr_md.egress_rid : exact;
   }
   actions {
      Angola;
      Amasa;
      Pinole;
   }
   size : 128;
}
control Franktown {
   apply( Kingman );
}
action Caspian( Cuney ) {
   modify_field( Bellwood.Maywood, Cuney );
   modify_field( Bellwood.Bluff, Cuney );
}
table WestPike {
   reads {
      eg_intr_md.egress_port : exact;
   }
   actions {
      Caspian;
   }
   default_action : Caspian(0);
   size : 128;
}
control Scotland {
    apply( WestPike );
}
action_selector VanWert {
    selection_key : Bosworth;
    selection_mode : resilient;
}
action Maydelle( Slinger ) {
   bit_or( Bellwood.Bluff, Bellwood.Bluff, Slinger );
}
action_profile Magasco {
   actions {
      Maydelle;
   }
   size : 512;
   dynamic_action_selection : VanWert;
}
table Artas {
   reads {
      Bellwood.Maywood : exact;
   }
   action_profile : Magasco;
   size : 128;
}
control Umpire {
   apply( Artas );
}
meter Tiskilwa {
   type : bytes;
   static : Goodlett;
   instance_count : 128;
}
action PineLake( Bulverde ) {
   execute_meter( Tiskilwa, Bulverde, Bellwood.Hartwick );
}
table Goodlett {
   reads {
      Bellwood.Maywood : exact;
   }
   actions {
      PineLake;
   }
   default_action : PineLake( 0 );
   size : 128;
}
control Frederika {
   apply( Goodlett );
}
action Inverness() {
   clone_egress_pkt_to_egress( Bellwood.Bluff, Sixteen );
}
table Rosalie {
   reads {
      Bellwood.Hartwick : exact;
   }
   actions {
      Inverness;
   }
   size : 2;
}
control RedLevel {
   if( Bellwood.Maywood != 0 ) {
      apply( Rosalie );
   }
}
counter Pinesdale {
   type : packets_and_bytes;
   direct : Kosciusko;
   min_width: 128;
}
action Brighton() {
   drop();
}
table Kosciusko {
   reads {
      eg_intr_md.egress_port mask 0x7f : exact;
      Wakita.NewTrier : ternary;
      Wakita.Peosta : ternary;
   }
   actions {
      Brighton;
      MintHill;
   }
   default_action : MintHill();
   size : 256;
}
control ingress {
   Quivero();
   if( Talmo.Gotham != 0 ) {
      Counce();
   }
   Stecker();
   Sunflower();
   if( Talmo.Gotham != 0 ) {
      Wisdom();
   }
   Hookdale();
   Onava();
   Watters();
   Darden();
   Breese();
   Visalia();
   Vinita();
   Advance();
   WoodDale();
   Stidham();
   Airmont();
   Merino();
   Wittman();
   Minto();
   Heuvelton();
   apply( Calabasas );
   if( Talmo.Gotham != 0 ) {
      Yocemento();
   } else {
      if( valid( Duster ) ) {
         Harney();
      }
   }
   apply( Allons );
   Fairborn();
   Beaufort();
   if( Upalco.DewyRose != 2 ) {
      Oakridge();
   }
   Biehle();
   Glentana();
   Hueytown();
   if( Talmo.Gotham != 0 ) {
      Immokalee();
   }
   Hansell();
   if( Talmo.Gotham != 0 ) {
      Kalskag();
   }
   Moquah();
   Elsmere();
   CoalCity();
   if( ( Upalco.Westview == 0 ) and ( Upalco.DewyRose != 2 ) and ( Bigspring.Hewitt == 0 ) ) {
      Davisboro();
      if( Upalco.Pilottown == 511 ) {
         Challis();
      }
   }
   Woodfield();
   Shields();
   if( Upalco.DewyRose == 0 ) {
      apply(RedElm);
   }
   Rattan();
   if( Upalco.Westview == 0 ) {
      Mynard();
   }
   if ( Upalco.Westview == 0 ) {
      Mifflin();
   }
   if( Talmo.Gotham != 0 ) {
      LaSalle();
   }
   Keenes();
   if( Upalco.Westview == 0 ) {
      Faysville();
   }
   Sully();
   if( valid( Panola[0] ) ) {
      Bucktown();
   }
   Makawao();
   Libby();
}
control egress {
   if( ( (eg_intr_md_from_parser_aux.clone_src == NOT_CLONED) ) ) {
      Leflore();
      RedBay();
      Sedona();
      Nettleton();
      Pardee();
      if( Upalco.DewyRose == 0 ) {
         apply( Skyline );
      }
   } else {
      Franktown();
   }
   Raritan();
   Southam();
   if( ( (eg_intr_md_from_parser_aux.clone_src == NOT_CLONED) ) and Upalco.Baytown == 0 ) {
      Gabbs();
      Scotland();
      Nevis();
      Umpire();
      Frederika();
      Requa();
      apply( Kosciusko ) {
         MintHill {
            RedLevel();
         }
      }
   }
   if( Upalco.Baytown == 0 or Upalco.Alsen == 4 ) {
      Belle();
   }
}
