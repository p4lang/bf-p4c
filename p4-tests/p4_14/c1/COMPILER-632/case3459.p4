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
// Random Seed: 165314

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
header_type Booth {
	fields {
		Sofia : 16;
		Tchula : 16;
		Swansboro : 8;
		Munger : 8;
		Mulhall : 8;
		Hookstown : 8;
		Hecker : 2;
		Aguila : 2;
		Covelo : 1;
		Bellmore : 3;
		Charco : 3;
	}
}
header_type Hooker {
	fields {
		Monee : 24;
		Stilwell : 24;
		Pawtucket : 24;
		Baker : 24;
		Livonia : 16;
		Trion : 12;
		Headland : 20;
		Gerty : 16;
		Hurdtown : 16;
		Weatherly : 8;
		Halliday : 8;
		Giltner : 1;
		Sturgeon : 1;
		Correo : 3;
		Forkville : 2;
		Kasilof : 1;
		Cleator : 1;
		LaSalle : 1;
		Gardiner : 1;
		Rockham : 1;
		Menfro : 1;
		Frewsburg : 1;
		Larose : 1;
		Plano : 1;
		Abbott : 1;
		LaVale : 1;
		Lewellen : 1;
		Wakefield : 16;
		Diana : 16;
		Powers : 8;
	}
}
header_type Charlack {
	fields {
		Almont : 24;
		Batchelor : 24;
		Burmester : 24;
		Guadalupe : 24;
		Bosworth : 24;
		Brackett : 24;
		Redondo : 1;
		Warsaw : 3;
		Murphy : 1;
		Cozad : 12;
		Killen : 20;
		Hadley : 16;
		Osyka : 12;
		Parrish : 3;
		Blitchton : 1;
		Freeburg : 1;
		Ambrose : 1;
		Burrel : 1;
		Northlake : 1;
		Royston : 8;
		Hartwell : 12;
		Loveland : 4;
		LaPryor : 6;
		Lowden : 10;
		CruzBay : 32;
		Shivwits : 32;
		Panaca : 32;
		Grandy : 24;
		McCaulley : 24;
		Enfield : 24;
		Weatherby : 32;
		Becida : 9;
		Onslow : 2;
		Hopeton : 1;
		Skyforest : 1;
		Lindsborg : 1;
		Mapleview : 1;
		Squire : 1;
		Clarinda : 12;
		Pekin : 1;
	}
}
header_type Maybeury {
	fields {
		Cannelton : 8;
		Ocheyedan : 4;
		Yetter : 1;
	}
}
header_type Bavaria {
	fields {
		Kempton : 32;
		Anchorage : 32;
		Mekoryuk : 6;
		Prismatic : 16;
	}
}
header_type Aldan {
	fields {
		Albemarle : 128;
		Macland : 128;
		Dougherty : 20;
		Godfrey : 8;
		Nowlin : 11;
		Ulysses : 6;
		Fiftysix : 13;
	}
}
header_type Melba {
	fields {
		McDavid : 14;
		Greenlawn : 1;
		Pollard : 12;
		Bairoa : 1;
		Milesburg : 1;
		Mango : 2;
		Oconee : 6;
		Champlin : 3;
	}
}
header_type Wagener {
	fields {
		Sarepta : 1;
		Hector : 1;
	}
}
header_type Burden {
	fields {
		Lincroft : 8;
	}
}
header_type Wahoo {
	fields {
		Luttrell : 16;
		Rohwer : 11;
	}
}
header_type Osterdock {
	fields {
		Oakford : 32;
		Holyoke : 32;
		Knolls : 32;
	}
}
header_type Rosburg {
	fields {
		Wauna : 32;
		Uhland : 32;
	}
}
header_type Silica {
	fields {
		Roxobel : 1;
		Osseo : 1;
		LaHoma : 1;
		Dillsboro : 3;
		Caban : 1;
		Crossnore : 6;
		Cockrum : 4;
		Angwin : 5;
	}
}
header_type Shade {
	fields {
		Plush : 16;
	}
}
header_type McIntosh {
	fields {
		LakeFork : 14;
		Euren : 1;
		FourTown : 1;
	}
}
header_type Neuse {
	fields {
		Kearns : 14;
		Bedrock : 1;
		Wildorado : 1;
	}
}
header_type Shirley {
	fields {
		Hilgard : 16;
		Nashoba : 16;
		Dushore : 16;
		Waretown : 16;
		Pinebluff : 8;
		Proctor : 8;
		Moorewood : 8;
		Tofte : 8;
		Shabbona : 1;
		Croghan : 6;
	}
}
header_type Ashwood {
	fields {
		Alcoma : 32;
	}
}
header_type Bremond {
	fields {
		Placid : 6;
		Edinburg : 10;
		Empire : 4;
		Fries : 12;
		Carmel : 2;
		Eudora : 2;
		Rainsburg : 12;
		Kanab : 8;
		Dunnegan : 3;
		Whitman : 5;
	}
}
header_type Cacao {
	fields {
		Wheatland : 24;
		Wabasha : 24;
		Newberg : 24;
		Slick : 24;
		Kenefic : 16;
	}
}
header_type HamLake {
	fields {
		Danforth : 3;
		Berne : 1;
		Ozona : 12;
		Wayne : 16;
	}
}
header_type Nutria {
	fields {
		Wyanet : 4;
		Elkins : 4;
		Houston : 6;
		Sheldahl : 2;
		Lofgreen : 16;
		Kanorado : 16;
		Snowflake : 3;
		Tulia : 13;
		Teaneck : 8;
		Brush : 8;
		Tallassee : 16;
		Gresston : 32;
		Worthing : 32;
	}
}
header_type Garcia {
	fields {
		Petroleum : 4;
		Doyline : 6;
		Pinecrest : 2;
		Ringtown : 20;
		Nunda : 16;
		Hilbert : 8;
		Glynn : 8;
		Cadott : 128;
		Whiteclay : 128;
	}
}
header_type Hammond {
	fields {
		Quebrada : 8;
		Hanahan : 8;
		Peebles : 16;
	}
}
header_type Letcher {
	fields {
		Dresser : 16;
		Kaltag : 16;
	}
}
header_type Hillside {
	fields {
		NantyGlo : 32;
		WolfTrap : 32;
		IdaGrove : 4;
		Menomonie : 4;
		Wenden : 8;
		Lamkin : 16;
		Demarest : 16;
		Fireco : 16;
	}
}
header_type Lamoni {
	fields {
		Olyphant : 16;
		Acree : 16;
	}
}
header_type Tobique {
	fields {
		Madras : 16;
		Bogota : 16;
		Eastman : 8;
		Weathers : 8;
		Hannibal : 16;
	}
}
header_type Millston {
	fields {
		Ladelle : 48;
		Claiborne : 32;
		Caguas : 48;
		Loogootee : 32;
	}
}
header_type Longville {
	fields {
		Bernice : 1;
		Corydon : 1;
		Horns : 1;
		Strevell : 1;
		Gosnell : 1;
		Iredell : 3;
		Chispa : 5;
		Fentress : 3;
		Adona : 16;
	}
}
header_type Johnstown {
	fields {
		Preston : 24;
		Grasston : 8;
	}
}
header_type Perryton {
	fields {
		Leawood : 8;
		Everett : 24;
		Bartolo : 24;
		Yscloskey : 8;
	}
}
header Cacao Greenland;
header Cacao Calvary;
header HamLake Mission[ 2 ];
@pragma pa_fragment ingress Amory.Tallassee
@pragma pa_fragment egress Amory.Tallassee
header Nutria Amory;
@pragma pa_fragment ingress Weissert.Tallassee
@pragma pa_fragment egress Weissert.Tallassee
header Nutria Weissert;
header Garcia Penalosa;
header Garcia Martelle;
header Letcher Vandling;
header Letcher Lorane;
header Hillside Crannell;
header Lamoni Nevis;
header Hillside Nenana;
header Lamoni Belmore;
header Perryton McKamie;
header Longville Hayfork;
header Bremond Conneaut;
header Cacao Hutchings;
parser start {
   return select(current(96, 16)) {
      0xBF00 : Elrosa;
      default : Clarissa;
   }
}
parser Penrose {
   extract( Conneaut );
   return Clarissa;
}
parser Elrosa {
   extract( Hutchings );
   return Penrose;
}
parser Clarissa {
   extract( Greenland );
   return select( Greenland.Kenefic ) {
      0x8100 : Bryan;
      0x0800 : Marie;
      0x86dd : NeckCity;
      default : ingress;
   }
}
parser Bryan {
   extract( Mission[0] );
   set_metadata(Hershey.Covelo, 1);
   return select( Mission[0].Wayne ) {
      0x0800 : Marie;
      0x86dd : NeckCity;
      default : ingress;
   }
}
field_list Paragould {
    Amory.Wyanet;
    Amory.Elkins;
    Amory.Houston;
    Amory.Sheldahl;
    Amory.Lofgreen;
    Amory.Kanorado;
    Amory.Snowflake;
    Amory.Tulia;
    Amory.Teaneck;
    Amory.Brush;
    Amory.Gresston;
    Amory.Worthing;
}
field_list_calculation LaMarque {
    input {
        Paragould;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Amory.Tallassee {
    verify LaMarque;
    update LaMarque;
}
parser Marie {
   extract( Amory );
   set_metadata(Hershey.Swansboro, Amory.Brush);
   set_metadata(Hershey.Mulhall, Amory.Teaneck);
   set_metadata(Hershey.Hecker, 1);
   return select(Amory.Tulia, Amory.Elkins, Amory.Brush) {
      0x501 : Neavitt;
      0x511 : Gladys;
      0x506 : Barber;
      0 mask 0xFF7000 : ingress;
      0x506 mask 0xfff: Kittredge;
      default : Kennebec;
   }
}
parser Kittredge {
   set_metadata(Hershey.Charco, 5);
   return ingress;
}
parser Kennebec {
   set_metadata(Hershey.Charco, 1);
   return ingress;
}
parser NeckCity {
   extract( Martelle );
   set_metadata(Hershey.Swansboro, Martelle.Hilbert);
   set_metadata(Hershey.Mulhall, Martelle.Glynn);
   set_metadata(Hershey.Hecker, 2);
   return select(Martelle.Hilbert) {
      0x3a : Neavitt;
      17 : Lostine;
      6 : Barber;
      default : ingress;
   }
}
parser Gladys {
   set_metadata(Hershey.Charco, 2);
   extract(Vandling);
   extract(Nevis);
   return select(Vandling.Kaltag) {
      4789 : Musella;
      default : ingress;
    }
}
parser Neavitt {
   set_metadata( Vandling.Dresser, current( 0, 16 ) );
   return ingress;
}
parser Lostine {
   set_metadata(Hershey.Charco, 2);
   extract(Vandling);
   extract(Nevis);
   return ingress;
}
parser Barber {
   set_metadata(Hershey.Charco, 6);
   extract(Vandling);
   extract(Crannell);
   return ingress;
}
parser Taopi {
   set_metadata(Westboro.Forkville, 2);
   return Broadus;
}
parser WildRose {
   set_metadata(Westboro.Forkville, 2);
   return Chatom;
}
parser Adams {
   extract(Hayfork);
   return select(Hayfork.Bernice, Hayfork.Corydon, Hayfork.Horns, Hayfork.Strevell, Hayfork.Gosnell,
             Hayfork.Iredell, Hayfork.Chispa, Hayfork.Fentress, Hayfork.Adona) {
      0x0800 : Taopi;
      0x86dd : WildRose;
      default : ingress;
   }
}
parser Musella {
   extract(McKamie);
   set_metadata(Westboro.Forkville, 1);
   return Odessa;
}
field_list Soledad {
    Weissert.Wyanet;
    Weissert.Elkins;
    Weissert.Houston;
    Weissert.Sheldahl;
    Weissert.Lofgreen;
    Weissert.Kanorado;
    Weissert.Snowflake;
    Weissert.Tulia;
    Weissert.Teaneck;
    Weissert.Brush;
    Weissert.Gresston;
    Weissert.Worthing;
}
field_list_calculation Weches {
    input {
        Soledad;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Weissert.Tallassee {
    verify Weches;
    update Weches;
}
parser Broadus {
   extract( Weissert );
   set_metadata(Hershey.Munger, Weissert.Brush);
   set_metadata(Hershey.Hookstown, Weissert.Teaneck);
   set_metadata(Hershey.Aguila, 1);
   set_metadata(Macon.Kempton, Weissert.Gresston);
   set_metadata(Macon.Anchorage, Weissert.Worthing);
   return select(Weissert.Tulia, Weissert.Elkins, Weissert.Brush) {
      0x501 : BigPiney;
      0x511 : Kenney;
      0x506 : Annawan;
      0 mask 0xFF7000 : ingress;
      0x506 mask 0xfff: Tomato;
      default : Colona;
   }
}
parser Tomato {
   set_metadata(Hershey.Bellmore, 5);
   return ingress;
}
parser Colona {
   set_metadata(Hershey.Bellmore, 1);
   return ingress;
}
parser Chatom {
   extract( Penalosa );
   set_metadata(Hershey.Munger, Penalosa.Hilbert);
   set_metadata(Hershey.Hookstown, Penalosa.Glynn);
   set_metadata(Hershey.Tchula, Penalosa.Nunda);
   set_metadata(Hershey.Aguila, 2);
   set_metadata(Evelyn.Albemarle, Penalosa.Cadott);
   set_metadata(Evelyn.Macland, Penalosa.Whiteclay);
   return select(Penalosa.Hilbert) {
      0x3a : BigPiney;
      17 : Kenney;
      6 : Annawan;
      default : ingress;
   }
}
parser BigPiney {
   set_metadata( Westboro.Wakefield, current( 0, 16 ) );
   return ingress;
}
parser Kenney {
   set_metadata( Westboro.Wakefield, current( 0, 16 ) );
   set_metadata( Westboro.Diana, current( 16, 16 ) );
   set_metadata(Hershey.Bellmore, 2);
   return ingress;
}
parser Annawan {
   set_metadata( Westboro.Wakefield, current( 0, 16 ) );
   set_metadata( Westboro.Diana, current( 16, 16 ) );
   set_metadata( Westboro.Powers, current( 104, 8 ) );
   set_metadata(Hershey.Bellmore, 6);
   extract(Lorane);
   extract(Nenana);
   return ingress;
}
parser Odessa {
   extract( Calvary );
   set_metadata( Westboro.Monee, Calvary.Wheatland );
   set_metadata( Westboro.Stilwell, Calvary.Wabasha );
   set_metadata( Westboro.Livonia, Calvary.Kenefic );
   return select( Calvary.Kenefic ) {
      0x0800: Broadus;
      0x86dd: Chatom;
      default: ingress;
   }
}
@pragma pa_no_init ingress Westboro.Monee
@pragma pa_no_init ingress Westboro.Stilwell
@pragma pa_no_init ingress Westboro.Pawtucket
@pragma pa_no_init ingress Westboro.Baker
@pragma pa_container_size ingress Westboro.Forkville 16
metadata Hooker Westboro;
@pragma pa_no_init ingress CoalCity.Almont
@pragma pa_no_init ingress CoalCity.Batchelor
@pragma pa_no_init ingress CoalCity.Burmester
@pragma pa_no_init ingress CoalCity.Guadalupe
@pragma pa_no_init ingress CoalCity.Becida
@pragma pa_solitary egress CoalCity.CruzBay
@pragma pa_container_size egress CoalCity.CruzBay 32
metadata Charlack CoalCity;
metadata Melba Scherr;
@pragma pa_do_not_bridge egress Hershey.Swansboro
metadata Booth Hershey;
metadata Bavaria Macon;
metadata Aldan Evelyn;
metadata Wagener Humeston;
@pragma pa_container_size ingress Wetumpka.Cannelton 16
metadata Maybeury Wetumpka;
metadata Burden Taneytown;
metadata Wahoo Alburnett;
metadata Rosburg Woodfield;
metadata Osterdock Barstow;
metadata Silica Missoula;
metadata Shade Lutts;
@pragma pa_no_init ingress Nanakuli.LakeFork
@pragma pa_solitary ingress Nanakuli.FourTown
metadata McIntosh Nanakuli;
@pragma pa_no_init ingress McLaurin.Kearns
metadata Neuse McLaurin;
metadata Shirley Wildell;
metadata Shirley Goudeau;
action Fitler() {
   no_op();
}
action Cooter() {
   modify_field(Westboro.Kasilof, 1 );
   mark_for_drop();
}
action Ugashik() {
   no_op();
}
action Charenton(Rockland, Frontenac, Halfa, Lovewell, LaCueva,
                 Mabel, Metter, Cashmere) {
    modify_field(Scherr.McDavid, Rockland);
    modify_field(Scherr.Greenlawn, Frontenac);
    modify_field(Scherr.Pollard, Halfa);
    modify_field(Scherr.Bairoa, Lovewell);
    modify_field(Scherr.Milesburg, LaCueva);
    modify_field(Scherr.Mango, Mabel);
    modify_field(Scherr.Champlin, Metter);
    modify_field(Scherr.Oconee, Cashmere);
}
@pragma command_line --no-dead-code-elimination
@pragma phase0 1
table Lovett {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Charenton;
    }
    size : 288;
}
control Dorset {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Lovett);
    }
}
action Mustang(Rockdale, Cuney) {
   modify_field( CoalCity.Murphy, 1 );
   modify_field( CoalCity.Royston, Rockdale);
   modify_field( Westboro.Frewsburg, 1 );
   modify_field( Missoula.LaHoma, Cuney );
}
action Grinnell() {
   modify_field( Westboro.Gardiner, 1 );
   modify_field( Westboro.Plano, 1 );
}
action Lapel() {
   modify_field( Westboro.Frewsburg, 1 );
}
action Junior() {
   modify_field( Westboro.Frewsburg, 1 );
   modify_field( Westboro.Abbott, 1 );
}
action Bessie() {
   modify_field( Westboro.Larose, 1 );
}
action Sumner() {
   modify_field( Westboro.Plano, 1 );
}
counter Moneta {
   type : packets_and_bytes;
   direct : Barron;
   min_width: 16;
}
table Barron {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Greenland.Wheatland : ternary;
      Greenland.Wabasha : ternary;
   }
   actions {
      Mustang;
      Grinnell;
      Lapel;
      Bessie;
      Sumner;
      Junior;
   }
   size : 2048;
}
action Ardenvoir() {
   modify_field( Westboro.Rockham, 1 );
}
table Wadley {
   reads {
      Greenland.Newberg : ternary;
      Greenland.Slick : ternary;
   }
   actions {
      Ardenvoir;
   }
   size : 512;
}
control Wellford {
   apply( Barron );
   apply( Wadley );
}
action Cogar() {
   modify_field( Macon.Mekoryuk, Weissert.Houston );
   modify_field( Evelyn.Dougherty, Penalosa.Ringtown );
   modify_field( Evelyn.Ulysses, Penalosa.Doyline );
   modify_field( Westboro.Pawtucket, Calvary.Newberg );
   modify_field( Westboro.Baker, Calvary.Slick );
   modify_field( Westboro.Hurdtown, Hershey.Tchula );
   modify_field( Westboro.Weatherly, Hershey.Munger );
   modify_field( Westboro.Halliday, Hershey.Hookstown );
   modify_field( Westboro.Sturgeon, Hershey.Aguila, 1 );
   shift_right( Westboro.Giltner, Hershey.Aguila, 1 );
   modify_field( Westboro.LaVale, 0 );
   modify_field( CoalCity.Parrish, 1 );
   modify_field( Scherr.Mango, 1 );
   modify_field( Scherr.Champlin, 0 );
   modify_field( Scherr.Oconee, 0 );
   modify_field( Missoula.Roxobel, 1 );
   modify_field( Missoula.Osseo, 1 );
   modify_field( Wildell.Dushore, Westboro.Wakefield );
   modify_field( Westboro.Correo, Hershey.Bellmore );
   modify_field( Wildell.Shabbona, Hershey.Bellmore, 1);
}
action Kingsgate() {
   modify_field( Westboro.Forkville, 0 );
   modify_field( Macon.Kempton, Amory.Gresston );
   modify_field( Macon.Anchorage, Amory.Worthing );
   modify_field( Macon.Mekoryuk, Amory.Houston );
   modify_field( Evelyn.Albemarle, Martelle.Cadott );
   modify_field( Evelyn.Macland, Martelle.Whiteclay );
   modify_field( Evelyn.Dougherty, Martelle.Ringtown );
   modify_field( Evelyn.Ulysses, Martelle.Doyline );
   modify_field( Westboro.Monee, Greenland.Wheatland );
   modify_field( Westboro.Stilwell, Greenland.Wabasha );
   modify_field( Westboro.Pawtucket, Greenland.Newberg );
   modify_field( Westboro.Baker, Greenland.Slick );
   modify_field( Westboro.Livonia, Greenland.Kenefic );
   modify_field( Westboro.Weatherly, Hershey.Swansboro );
   modify_field( Westboro.Halliday, Hershey.Mulhall );
   modify_field( Westboro.Sturgeon, Hershey.Hecker, 1 );
   shift_right( Westboro.Giltner, Hershey.Hecker, 1 );
   modify_field( Missoula.Caban, Mission[0].Berne );
   modify_field( Westboro.LaVale, Hershey.Covelo );
   modify_field( Wildell.Dushore, Vandling.Dresser );
   modify_field( Westboro.Wakefield, Vandling.Dresser );
   modify_field( Westboro.Diana, Vandling.Kaltag );
   modify_field( Westboro.Powers, Crannell.Wenden );
   modify_field( Westboro.Correo, Hershey.Charco );
   modify_field( Wildell.Shabbona, Hershey.Charco, 1);
}
table Borth {
   reads {
      Greenland.Wheatland : exact;
      Greenland.Wabasha : exact;
      Amory.Worthing : exact;
      Westboro.Forkville : exact;
   }
   actions {
      Cogar;
      Kingsgate;
   }
   default_action : Kingsgate();
   size : 1024;
}
action Murchison(Willey) {
   modify_field( Westboro.Trion, Scherr.Pollard );
   modify_field( Westboro.Headland, Willey);
}
action Borup( Juneau, WestGate ) {
   modify_field( Westboro.Trion, Juneau );
   modify_field( Westboro.Headland, WestGate);
}
action Sonoita(JaneLew) {
   modify_field( Westboro.Trion, Mission[0].Ozona );
   modify_field( Westboro.Headland, JaneLew);
}
action Yreka() {
   Cooter();
}
table BirchRun {
   reads {
      Scherr.McDavid : exact;
      Mission[0] : valid;
      Mission[0].Ozona : ternary;
   }
   actions {
      Murchison;
      Borup;
      Sonoita;
   }
   default_action : Yreka();
   size : 4096;
}
action Newtok( Gambrills ) {
   modify_field( Westboro.Headland, Gambrills );
}
action Punaluu() {
   modify_field( Taneytown.Lincroft,
                 2 );
}
table Badger {
   reads {
      Amory.Gresston : exact;
   }
   actions {
      Newtok;
      Punaluu;
   }
   default_action : Punaluu;
   size : 4096;
}
action Caplis( Lakehills, Bowen, Range, Pathfork ) {
   modify_field( Westboro.Trion, Lakehills );
   modify_field( Westboro.Gerty, Lakehills );
   modify_field( Westboro.LaSalle, Pathfork );
   Trujillo(Bowen, Range);
}
action Tilghman() {
   modify_field( Westboro.Cleator, 1 );
}
table Carnero {
   reads {
      McKamie.Bartolo : exact;
   }
   actions {
      Caplis;
      Tilghman;
   }
   size : 4096;
}
action Trujillo(Milbank, Baldwin) {
   modify_field( Wetumpka.Cannelton, Milbank );
   modify_field( Wetumpka.Ocheyedan, Baldwin );
}
action Sledge(Tamms, Elimsport) {
   modify_field( Westboro.Gerty, Scherr.Pollard );
   Trujillo(Tamms, Elimsport);
}
action OldGlory(CeeVee, Patsville, Coamo) {
   modify_field( Westboro.Gerty, CeeVee );
   Trujillo(Patsville, Coamo);
}
action ElDorado(Alsen, Wanamassa) {
   modify_field( Westboro.Gerty, Mission[0].Ozona );
   Trujillo(Alsen, Wanamassa);
}
@pragma ternary 1
table Palmhurst {
   reads {
      Scherr.Pollard : exact;
   }
   actions {
      Fitler;
      Sledge;
   }
   size : 512;
}
@pragma action_default_only Fitler
table Belcher {
   reads {
      Scherr.McDavid : exact;
      Mission[0].Ozona : exact;
   }
   actions {
      OldGlory;
      Fitler;
   }
   size : 1024;
}
table Robinette {
   reads {
      Mission[0].Ozona : exact;
   }
   actions {
      Fitler;
      ElDorado;
   }
   size : 4096;
}
control Wyatte {
   apply( Borth ) {
         Cogar {
            apply( Badger );
            apply( Carnero );
         }
         Kingsgate {
            if ( Scherr.Bairoa == 1 ) {
               apply( BirchRun );
            }
            if ( valid( Mission[ 0 ] ) and Mission[0].Ozona != 0 ) {
               apply( Belcher ) {
                  Fitler {
                     apply( Robinette );
                  }
               }
            } else {
               apply( Palmhurst );
            }
         }
   }
}
register Spenard {
    width : 1;
    static : Cresco;
    instance_count : 294912;
}
register Vesuvius {
    width : 1;
    static : Broadmoor;
    instance_count : 294912;
}
blackbox stateful_alu Moose {
    reg : Spenard;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : Humeston.Sarepta;
}
blackbox stateful_alu Matador {
    reg : Vesuvius;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst : Humeston.Hector;
}
field_list Brookston {
    ig_intr_md.ingress_port;
    Mission[0].Ozona;
}
field_list_calculation Kenmore {
    input { Brookston; }
    algorithm: identity;
    output_width: 19;
}
action Waiehu() {
    Moose.execute_stateful_alu_from_hash(Kenmore);
}
action Larwill() {
    Matador.execute_stateful_alu_from_hash(Kenmore);
}
table Cresco {
    actions {
      Waiehu;
    }
    default_action : Waiehu;
    size : 1;
}
table Broadmoor {
    actions {
      Larwill;
    }
    default_action : Larwill;
    size : 1;
}
action WestEnd(Stowe) {
    modify_field(Humeston.Hector, Stowe);
}
@pragma ternary 1
table Pidcoke {
    reads {
       ig_intr_md.ingress_port mask 0x7f : exact;
    }
    actions {
      WestEnd;
    }
    size : 72;
}
control Ludowici {
   if ( valid( Mission[ 0 ] ) and Mission[0].Ozona != 0 ) {
      if( Scherr.Milesburg == 1 ) {
         apply( Cresco );
         apply( Broadmoor );
      }
   } else {
      if( Scherr.Milesburg == 1 ) {
         apply( Pidcoke );
      }
   }
}
field_list Lewes {
   Greenland.Wheatland;
   Greenland.Wabasha;
   Greenland.Newberg;
   Greenland.Slick;
   Greenland.Kenefic;
}
field_list Sardinia {
   Amory.Brush;
   Amory.Gresston;
   Amory.Worthing;
}
field_list Nicolaus {
   Martelle.Cadott;
   Martelle.Whiteclay;
   Martelle.Ringtown;
   Martelle.Hilbert;
}
field_list Hartfield {
   Amory.Gresston;
   Amory.Worthing;
   Vandling.Dresser;
   Vandling.Kaltag;
}
field_list_calculation Eastwood {
    input {
        Lewes;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Morrow {
    input {
        Sardinia;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Chewalla {
    input {
        Nicolaus;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Clover {
    input {
        Hartfield;
    }
    algorithm : crc32;
    output_width : 32;
}
action Owanka() {
    modify_field_with_hash_based_offset(Barstow.Oakford, 0,
                                        Eastwood, 4294967296);
}
action Sunrise() {
    modify_field_with_hash_based_offset(Barstow.Holyoke, 0,
                                        Morrow, 4294967296);
}
action Turkey() {
    modify_field_with_hash_based_offset(Barstow.Holyoke, 0,
                                        Chewalla, 4294967296);
}
action Fosters() {
    modify_field_with_hash_based_offset(Barstow.Knolls, 0,
                                        Clover, 4294967296);
}
table Newburgh {
   actions {
      Owanka;
   }
   size: 1;
}
control Abernant {
   apply(Newburgh);
}
table Buckholts {
   actions {
      Sunrise;
   }
   size: 1;
}
table Cankton {
   actions {
      Turkey;
   }
   size: 1;
}
control Newhalen {
   if ( valid( Amory ) ) {
      apply(Buckholts);
   } else {
      if ( valid( Martelle ) ) {
         apply(Cankton);
      }
   }
}
table Spindale {
   actions {
      Fosters;
   }
   size: 1;
}
control Kaibab {
   if ( valid( Nevis ) ) {
      apply(Spindale);
   }
}
action Youngtown() {
    modify_field(Woodfield.Wauna, Barstow.Oakford);
}
action Beaverton() {
    modify_field(Woodfield.Wauna, Barstow.Holyoke);
}
action Ingraham() {
    modify_field(Woodfield.Wauna, Barstow.Knolls);
}
@pragma action_default_only Fitler
@pragma immediate 0
table Oshoto {
   reads {
      Nenana.valid : ternary;
      Belmore.valid : ternary;
      Weissert.valid : ternary;
      Penalosa.valid : ternary;
      Calvary.valid : ternary;
      Crannell.valid : ternary;
      Nevis.valid : ternary;
      Amory.valid : ternary;
      Martelle.valid : ternary;
      Greenland.valid : ternary;
   }
   actions {
      Youngtown;
      Beaverton;
      Ingraham;
      Fitler;
   }
   size: 256;
}
action Pierre() {
    modify_field(Woodfield.Uhland, Barstow.Knolls);
}
@pragma immediate 0
table Langdon {
   reads {
      Nenana.valid : ternary;
      Belmore.valid : ternary;
      Crannell.valid : ternary;
      Nevis.valid : ternary;
   }
   actions {
      Pierre;
      Fitler;
   }
   size: 6;
}
control Anahola {
   apply(Langdon);
   apply(Oshoto);
}
counter Poteet {
   type : packets_and_bytes;
   direct : Swords;
   min_width: 16;
}
table Swords {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Humeston.Hector : ternary;
      Humeston.Sarepta : ternary;
      Westboro.Cleator : ternary;
      Westboro.Rockham : ternary;
      Westboro.Gardiner : ternary;
   }
   actions {
      Cooter;
      Fitler;
   }
   default_action : Fitler();
   size : 512;
}
table Pineville {
   reads {
      Westboro.Pawtucket : exact;
      Westboro.Baker : exact;
      Westboro.Trion : exact;
   }
   actions {
      Cooter;
      Fitler;
   }
   default_action : Fitler();
   size : 4096;
}
action Halltown() {
   modify_field(Taneytown.Lincroft,
                1);
}
table Inola {
   reads {
      Westboro.Pawtucket : exact;
      Westboro.Baker : exact;
      Westboro.Trion : exact;
      Westboro.Headland : exact;
   }
   actions {
      Ugashik;
      Halltown;
   }
   default_action : Halltown();
   size : 65536;
   support_timeout : true;
}
action Hobucken( Rockport, Brohard ) {
   modify_field( Westboro.Lewellen, Rockport );
   modify_field( Westboro.LaSalle, Brohard );
}
action Frederika() {
   modify_field( Westboro.LaSalle, 1 );
}
table Fishers {
   reads {
      Westboro.Trion mask 0xfff : exact;
   }
   actions {
      Hobucken;
      Frederika;
      Fitler;
   }
   default_action : Fitler();
   size : 4096;
}
action Lanesboro() {
   modify_field( Wetumpka.Yetter, 1 );
}
table Neshaminy {
   reads {
      Westboro.Gerty : ternary;
      Westboro.Monee : exact;
      Westboro.Stilwell : exact;
   }
   actions {
      Lanesboro;
   }
   size: 512;
}
control Gowanda {
   apply( Swords ) {
      Fitler {
         apply( Pineville ) {
            Fitler {
               if (Scherr.Greenlawn == 0 and Taneytown.Lincroft == 0) {
                  apply( Inola );
               }
               apply( Fishers );
               apply(Neshaminy);
            }
         }
      }
   }
}
field_list Emajagua {
    Taneytown.Lincroft;
    Westboro.Pawtucket;
    Westboro.Baker;
    Westboro.Trion;
    Westboro.Headland;
}
action Ireton() {
   generate_digest(0, Emajagua);
}
table Leonidas {
   actions {
      Ireton;
   }
   size : 1;
}
control Bells {
   if (Taneytown.Lincroft == 1) {
      apply( Leonidas );
   }
}
action Fairborn( Marbleton, Kokadjo ) {
   modify_field( Evelyn.Fiftysix, Marbleton );
   modify_field( Alburnett.Luttrell, Kokadjo );
}
action Blossburg( Belvidere, Linganore ) {
   modify_field( Evelyn.Fiftysix, Belvidere );
   modify_field( Alburnett.Rohwer, Linganore );
}
@pragma action_default_only Decorah
table Tillson {
   reads {
      Wetumpka.Cannelton : exact;
      Evelyn.Macland mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Fairborn;
      Decorah;
      Blossburg;
   }
   size : 8192;
}
@pragma atcam_partition_index Evelyn.Fiftysix
@pragma atcam_number_partitions 8192
table Earling {
   reads {
      Evelyn.Fiftysix : exact;
      Evelyn.Macland mask 0x000007FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Stehekin;
      Corder;
      Fitler;
   }
   default_action : Fitler();
   size : 65536;
}
action Dollar( Chatmoss, Anthony ) {
   modify_field( Evelyn.Nowlin, Chatmoss );
   modify_field( Alburnett.Luttrell, Anthony );
}
action Lyncourt( Pengilly, Daphne ) {
   modify_field( Evelyn.Nowlin, Pengilly );
   modify_field( Alburnett.Rohwer, Daphne );
}
@pragma action_default_only Fitler
table Lenoir {
   reads {
      Wetumpka.Cannelton : exact;
      Evelyn.Macland : lpm;
   }
   actions {
      Dollar;
      Lyncourt;
      Fitler;
   }
   size : 2048;
}
@pragma atcam_partition_index Evelyn.Nowlin
@pragma atcam_number_partitions 2048
table Scanlon {
   reads {
      Evelyn.Nowlin : exact;
      Evelyn.Macland mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Stehekin;
      Corder;
      Fitler;
   }
   default_action : Fitler();
   size : 16384;
}
@pragma action_default_only Decorah
@pragma idletime_precision 1
table Glennie {
   reads {
      Wetumpka.Cannelton : exact;
      Macon.Anchorage : lpm;
   }
   actions {
      Stehekin;
      Corder;
      Decorah;
   }
   size : 1024;
   support_timeout : true;
}
action Subiaco( Omemee, Gibbstown ) {
   modify_field( Macon.Prismatic, Omemee );
   modify_field( Alburnett.Luttrell, Gibbstown );
}
action Florien( Colonie, PineCity ) {
   modify_field( Macon.Prismatic, Colonie );
   modify_field( Alburnett.Rohwer, PineCity );
}
@pragma action_default_only Fitler
table Peoria {
   reads {
      Wetumpka.Cannelton : exact;
      Macon.Anchorage : lpm;
   }
   actions {
      Subiaco;
      Florien;
      Fitler;
   }
   size : 16384;
}
@pragma ways 2
@pragma atcam_partition_index Macon.Prismatic
@pragma atcam_number_partitions 16384
table Dillsburg {
   reads {
      Macon.Prismatic : exact;
      Macon.Anchorage mask 0x000fffff : lpm;
   }
   actions {
      Stehekin;
      Corder;
      Fitler;
   }
   default_action : Fitler();
   size : 131072;
}
action Stehekin( Emory ) {
   modify_field( Alburnett.Luttrell, Emory );
}
@pragma idletime_precision 1
table Virgil {
   reads {
      Wetumpka.Cannelton : exact;
      Macon.Anchorage : exact;
   }
   actions {
      Stehekin;
      Corder;
      Fitler;
   }
   default_action : Fitler();
   size : 65536;
   support_timeout : true;
}
@pragma idletime_precision 1
@pragma stage 2 28672
@pragma stage 3
table Fairland {
   reads {
      Wetumpka.Cannelton : exact;
      Evelyn.Macland : exact;
   }
   actions {
      Stehekin;
      Corder;
      Fitler;
   }
   default_action : Fitler();
   size : 65536;
   support_timeout : true;
}
action Harshaw(Convoy, Alnwick, Ruffin) {
   modify_field(CoalCity.Cozad, Ruffin);
   modify_field(CoalCity.Almont, Convoy);
   modify_field(CoalCity.Batchelor, Alnwick);
   modify_field(CoalCity.Hopeton, 1);
   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}
action Stella() {
   Cooter();
}
action Skokomish(Clearlake) {
   modify_field(CoalCity.Murphy, 1);
   modify_field(CoalCity.Royston, Clearlake);
}
action Decorah(Nason) {
   modify_field(Alburnett.Luttrell, Nason);
}
table DonaAna {
   reads {
      Alburnett.Luttrell : exact;
   }
   actions {
      Harshaw;
      Stella;
      Skokomish;
   }
   size : 65536;
}
action Crouch(Gerster) {
   modify_field(Alburnett.Luttrell, Gerster);
}
table Bevington {
   actions {
      Crouch;
   }
   default_action: Crouch;
   size : 1;
}
control Brodnax {
   if ( ( ( Wetumpka.Ocheyedan & ( 0x2 ) ) == ( ( 0x2 ) ) ) and ( Westboro.Giltner == 1 ) ) {
      if ( Westboro.Kasilof == 0 and Wetumpka.Yetter == 1 ) {
         apply( Fairland ) {
            Fitler {
               apply( Lenoir );
            }
         }
      }
   } else if ( ( ( Wetumpka.Ocheyedan & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Westboro.Sturgeon == 1 ) ) {
      if ( Westboro.Kasilof == 0 ) {
         if ( Wetumpka.Yetter == 1 ) {
            apply( Virgil ) {
               Fitler {
                  apply(Peoria);
               }
            }
         }
      }
  }
}
control Geneva {
   if ( Westboro.Kasilof == 0 and Wetumpka.Yetter == 1 ) {
      if ( ( ( Wetumpka.Ocheyedan & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Westboro.Sturgeon == 1 ) ) {
         if ( Macon.Prismatic != 0 ) {
            apply( Dillsburg );
         } else if ( Alburnett.Luttrell == 0 and Alburnett.Rohwer == 0 ) {
            apply( Glennie );
         }
      } else if ( ( ( Wetumpka.Ocheyedan & ( 0x2 ) ) == ( ( 0x2 ) ) ) and ( Westboro.Giltner == 1 ) ) {
         if ( Evelyn.Nowlin != 0 ) {
            apply( Scanlon );
         } else if ( Alburnett.Luttrell == 0 and Alburnett.Rohwer == 0 ) {
            apply( Tillson );
            if ( Evelyn.Fiftysix != 0 ) {
               apply( Earling );
            }
         }
      } else if( Westboro.LaSalle == 1 ) {
         apply( Bevington );
      }
   }
}
control Zarah {
   if( Alburnett.Luttrell != 0 ) {
      apply( DonaAna );
   }
}
action Corder( RossFork ) {
   modify_field( Alburnett.Rohwer, RossFork );
}
field_list Lushton {
   Woodfield.Uhland;
}
field_list_calculation Cortland {
    input {
        Lushton;
    }
    algorithm : identity;
    output_width : 66;
}
action_selector Fieldon {
   selection_key : Cortland;
   selection_mode : resilient;
}
action_profile Bouse {
   actions {
      Stehekin;
   }
   size : 65536;
   dynamic_action_selection : Fieldon;
}
@pragma selector_max_group_size 256
table Parthenon {
   reads {
      Alburnett.Rohwer : exact;
   }
   action_profile : Bouse;
   size : 2048;
}
control Hemlock {
   if ( Alburnett.Rohwer != 0 ) {
      apply( Parthenon );
   }
}
field_list Noonan {
   Woodfield.Wauna;
}
field_list_calculation Lindsay {
    input {
        Noonan;
    }
    algorithm : identity;
    output_width : 51;
}
action_selector Ralls {
    selection_key : Lindsay;
    selection_mode : resilient;
}
action Westline(Duchesne) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Duchesne);
}
action_profile Belfalls {
    actions {
        Westline;
        Fitler;
    }
    size : 1024;
    dynamic_action_selection : Ralls;
}
action Trail() {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, CoalCity.Killen);
}
table Noelke {
   actions {
        Trail;
   }
   default_action : Trail();
   size : 1;
}
table Weskan {
   reads {
      CoalCity.Killen mask 0x3FF : exact;
   }
   action_profile: Belfalls;
   size : 1024;
}
control Loris {
   if ((CoalCity.Killen & 0x3C00) == 0x3C00) {
      apply(Weskan);
   } else if((CoalCity.Killen & 0xFFC00) == 0 ) {
      apply(Noelke);
   }
}
action Leonore() {
   modify_field(CoalCity.Almont, Westboro.Monee);
   modify_field(CoalCity.Batchelor, Westboro.Stilwell);
   modify_field(CoalCity.Burmester, Westboro.Pawtucket);
   modify_field(CoalCity.Guadalupe, Westboro.Baker);
   modify_field(CoalCity.Cozad, Westboro.Trion);
   modify_field(CoalCity.Killen, 511);
}
table Edgemoor {
   actions {
      Leonore;
   }
   default_action : Leonore();
   size : 1;
}
control Cliffs {
   apply( Edgemoor );
}
action Dagsboro() {
   modify_field(CoalCity.Blitchton, 1);
   modify_field(CoalCity.Mapleview, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Westboro.LaSalle);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, CoalCity.Cozad);
}
action Breda() {
}
@pragma ways 1
table Gahanna {
   reads {
      CoalCity.Almont : exact;
      CoalCity.Batchelor : exact;
   }
   actions {
      Dagsboro;
      Breda;
   }
   default_action : Breda;
   size : 1;
}
action Clermont() {
   modify_field(CoalCity.Freeburg, 1);
   modify_field(CoalCity.Northlake, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, CoalCity.Cozad, 4096);
}
@pragma stage 9
table Tolono {
   actions {
      Clermont;
   }
   default_action : Clermont;
   size : 1;
}
action Waukesha() {
   modify_field(CoalCity.Burrel, 1);
   modify_field(CoalCity.Mapleview, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, CoalCity.Cozad);
}
table Yerington {
   actions {
      Waukesha;
   }
   default_action : Waukesha();
   size : 1;
}
action Curtin(Mecosta) {
   modify_field(CoalCity.Ambrose, 1);
   modify_field(CoalCity.Killen, Mecosta);
}
action Fitzhugh(Herod) {
   modify_field(CoalCity.Freeburg, 1);
   modify_field(CoalCity.Hadley, Herod);
}
action Telida() {
}
table Vieques {
   reads {
      CoalCity.Almont : exact;
      CoalCity.Batchelor : exact;
      CoalCity.Cozad : exact;
   }
   actions {
      Curtin;
      Fitzhugh;
      Cooter;
      Telida;
   }
   default_action : Telida();
   size : 65536;
}
control Archer {
   if (Westboro.Kasilof == 0 ) {
      apply(Vieques) {
         Telida {
            apply(Gahanna) {
               Breda {
                  if ((CoalCity.Almont & 0x010000) == 0x010000) {
                     apply(Tolono);
                  } else {
                     apply(Yerington);
                  }
               }
            }
         }
      }
   }
}
field_list Justice {
   Woodfield.Wauna;
}
field_list_calculation Kupreanof {
    input {
        Justice;
    }
    algorithm : identity;
    output_width : 51;
}
field_list_calculation Ridgetop {
   input {
      Justice;
   }
   algorithm : identity;
   output_width : 16;
}
action Wrens( Admire, Dilia ) {
   modify_field( CoalCity.CruzBay, Dilia );
   modify_field( CoalCity.Shivwits, CoalCity.Killen );
   modify_field( CoalCity.Killen, Admire );
   modify_field( CoalCity.Warsaw, 3 );
   modify_field_with_hash_based_offset( Greenland.Wheatland, 0, Ridgetop, 16384 );
}
action_selector Aguilar {
    selection_key : Kupreanof;
    selection_mode : resilient;
}
action_profile Hawthorne {
    actions {
       Wrens;
    }
    size : 1024;
    dynamic_action_selection : Aguilar;
}
table Harlem {
   reads {
      CoalCity.Killen : ternary;
   }
   action_profile : Hawthorne;
   size : 512;
}
action Rockleigh() {
   modify_field(Westboro.Menfro, 1);
   Cooter();
}
table Willamina {
   actions {
      Rockleigh;
   }
   default_action : Rockleigh;
   size : 1;
}
action Palatine() {
   modify_field(CoalCity.CruzBay, CoalCity.Shivwits, 0xFFFFF);
}
table Uniopolis {
   actions {
      Palatine;
   }
  default_action : Palatine();
  size : 1;
}
control Hettinger {
   if (Westboro.Kasilof == 0) {
      if ((CoalCity.Hopeton==0) and (Westboro.Frewsburg==0) and (Westboro.Larose==0) and (Westboro.Headland==CoalCity.Killen)) {
         apply(Willamina);
      }
   }
   apply(Harlem);
}
action CoosBay( Haines ) {
   modify_field( CoalCity.Osyka, Haines );
}
action Ashley() {
   modify_field( CoalCity.Osyka, CoalCity.Cozad );
}
table Stillmore {
   reads {
      eg_intr_md.egress_port : exact;
      CoalCity.Cozad : exact;
   }
   actions {
      CoosBay;
      Ashley;
   }
   default_action : Ashley;
   size : 4096;
}
control Veradale {
   apply( Stillmore );
}
action Belle( Etter, Mifflin ) {
   modify_field( CoalCity.Bosworth, Etter );
   modify_field( CoalCity.Brackett, Mifflin );
}
action Oakton( Freeny, Candle, Gasport ) {
   modify_field( CoalCity.Bosworth, Freeny );
   modify_field( CoalCity.Brackett, Candle );
   modify_field( CoalCity.Weatherby, Gasport );
}
table FortHunt {
   reads {
      CoalCity.Warsaw : exact;
   }
   actions {
      Belle;
      Oakton;
   }
   size : 8;
}
action Mancelona( Saragosa ) {
   modify_field( CoalCity.Skyforest, 1 );
   modify_field( CoalCity.Warsaw, 2 );
   modify_field( CoalCity.Onslow, Saragosa );
}
table Connell {
   reads {
      eg_intr_md.egress_port : exact;
      Scherr.Bairoa : exact;
      CoalCity.Pekin : exact;
   }
   actions {
      Mancelona;
   }
   default_action : Fitler();
   size : 16;
}
action ElkNeck(Bosco, Whitefish, Taylors, Kempner) {
   modify_field( CoalCity.LaPryor, Bosco );
   modify_field( CoalCity.Lowden, Whitefish );
   modify_field( CoalCity.Loveland, Taylors );
   modify_field( CoalCity.Hartwell, Kempner );
}
table Terral {
   reads {
        CoalCity.Becida : exact;
   }
   actions {
      ElkNeck;
   }
   size : 512;
}
action Soldotna( Oneonta ) {
   modify_field( CoalCity.Panaca, Oneonta );
}
table Ebenezer {
   reads {
      CoalCity.CruzBay mask 0x1FFFF : exact;
   }
   actions {
      Soldotna;
   }
   default_action : Soldotna(0);
   size : 4096;
}
action Avondale( LaFayette, Gully, Covington ) {
   modify_field( CoalCity.Grandy, LaFayette );
   modify_field( CoalCity.McCaulley, Gully );
   modify_field( CoalCity.Cozad, Covington );
}
@pragma use_hash_action 1
table Asherton {
   reads {
      CoalCity.CruzBay mask 0xFF000000: exact;
   }
   actions {
      Avondale;
   }
   default_action : Avondale(0,0,0);
   size : 256;
}
action Mondovi( Ardmore ) {
   modify_field( CoalCity.Enfield, Ardmore );
}
table ElToro {
   reads {
      CoalCity.Cozad mask 0xFFF : exact;
   }
   actions {
      Mondovi;
   }
   default_action : Mondovi( 0 );
   size : 4096;
}
control Cornville {
   if( ( CoalCity.CruzBay & 0x60000 ) == 0x40000 ) {
      apply( Ebenezer );
   }
   if( CoalCity.CruzBay != 0 ) {
      apply( ElToro );
   }
   if( CoalCity.CruzBay != 0 ) {
      apply( Asherton );
   }
}
action Quitman() {
   no_op();
}
action Netarts() {
   modify_field( Greenland.Kenefic, Mission[0].Wayne );
   remove_header( Mission[0] );
}
table Sanchez {
   actions {
      Netarts;
   }
   default_action : Netarts;
   size : 1;
}
action Dietrich() {
   no_op();
}
action Stirrat() {
   add_header( Mission[ 0 ] );
   modify_field( Mission[0].Ozona, CoalCity.Osyka );
   modify_field( Mission[0].Wayne, Greenland.Kenefic );
   modify_field( Mission[0].Danforth, Missoula.Dillsboro );
   modify_field( Mission[0].Berne, Missoula.Caban );
   modify_field( Greenland.Kenefic, 0x8100 );
}
table Lilymoor {
   reads {
      CoalCity.Osyka : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Dietrich;
      Stirrat;
   }
   default_action : Stirrat;
   size : 128;
}
action Willard() {
   modify_field(Greenland.Wheatland, CoalCity.Almont);
   modify_field(Greenland.Wabasha, CoalCity.Batchelor);
   modify_field(Greenland.Newberg, CoalCity.Bosworth);
   modify_field(Greenland.Slick, CoalCity.Brackett);
}
action Shuqualak() {
   Willard();
   add_to_field(Amory.Teaneck, -1);
   modify_field(Amory.Houston, Missoula.Crossnore);
}
action Smithland() {
   Willard();
   add_to_field(Martelle.Glynn, -1);
   modify_field(Martelle.Doyline, Missoula.Crossnore);
}
action WallLake() {
   modify_field(Amory.Houston, Missoula.Crossnore);
}
action Endeavor() {
   modify_field(Martelle.Doyline, Missoula.Crossnore);
}
action Humble() {
   Stirrat();
}
action Almota( Scranton, SanSimon, Pettry, PeaRidge ) {
   add_header( Hutchings );
   modify_field( Hutchings.Wheatland, Scranton );
   modify_field( Hutchings.Wabasha, SanSimon );
   modify_field( Hutchings.Newberg, Pettry );
   modify_field( Hutchings.Slick, PeaRidge );
   modify_field( Hutchings.Kenefic, 0xBF00 );
   add_header( Conneaut );
   modify_field( Conneaut.Placid, CoalCity.LaPryor );
   modify_field( Conneaut.Edinburg, CoalCity.Lowden );
   modify_field( Conneaut.Empire, CoalCity.Loveland );
   modify_field( Conneaut.Fries, CoalCity.Hartwell );
   modify_field( Conneaut.Kanab, CoalCity.Royston );
   modify_field( Conneaut.Rainsburg, Westboro.Trion );
   modify_field( Conneaut.Eudora, CoalCity.Onslow );
}
action Yakutat() {
   remove_header( McKamie );
   remove_header( Nevis );
   remove_header( Vandling );
   copy_header( Greenland, Calvary );
   remove_header( Calvary );
   remove_header( Amory );
}
action Catawba() {
   remove_header( Hutchings );
   remove_header( Conneaut );
}
action Duster() {
   Yakutat();
   modify_field(Weissert.Houston, Missoula.Crossnore);
}
action DelMar() {
   Yakutat();
   modify_field(Penalosa.Doyline, Missoula.Crossnore);
}
action Willshire( Cement ) {
   modify_field( Weissert.Wyanet, Amory.Wyanet );
   modify_field( Weissert.Elkins, Amory.Elkins );
   modify_field( Weissert.Houston, Amory.Houston );
   modify_field( Weissert.Sheldahl, Amory.Sheldahl );
   modify_field( Weissert.Lofgreen, Amory.Lofgreen );
   modify_field( Weissert.Snowflake, Amory.Snowflake );
   modify_field( Weissert.Tulia, Amory.Tulia );
   add( Weissert.Teaneck, Amory.Teaneck, Cement );
   modify_field( Weissert.Brush, Amory.Brush );
   modify_field( Weissert.Tallassee, Amory.Tallassee );
   modify_field( Weissert.Gresston, Amory.Gresston );
   modify_field( Weissert.Worthing, Amory.Worthing );
}
action Chavies( Sieper ) {
   add_header( Calvary );
   add_header( Nevis );
   add_header( Vandling );
   add_header( McKamie );
   modify_field( Calvary.Wheatland, CoalCity.Almont );
   modify_field( Calvary.Wabasha, CoalCity.Batchelor );
   modify_field( Calvary.Newberg, Greenland.Newberg );
   modify_field( Calvary.Slick, Greenland.Slick );
   modify_field( Calvary.Kenefic, Greenland.Kenefic );
   add( Nevis.Olyphant, Sieper, 16 );
   modify_field( Nevis.Acree, 0 );
   modify_field( Vandling.Kaltag, 4789 );
   bit_or( Vandling.Dresser, Greenland.Wheatland, 0xC000 );
   modify_field( McKamie.Leawood, 0x10 );
   modify_field( McKamie.Bartolo, CoalCity.Enfield );
   modify_field( Greenland.Wheatland, CoalCity.Grandy );
   modify_field( Greenland.Wabasha, CoalCity.McCaulley );
   modify_field( Greenland.Newberg, CoalCity.Bosworth );
   modify_field( Greenland.Slick, CoalCity.Brackett );
}
action Marvin() {
   modify_field( Amory.Wyanet, 0x4 );
   modify_field( Amory.Elkins, 0x5 );
   modify_field( Amory.Houston, 0 );
   modify_field( Amory.Sheldahl, 0 );
   add_to_field( Amory.Lofgreen, 36 );
   modify_field( Amory.Kanorado, eg_intr_md_from_parser_aux.egress_global_tstamp, 0xFFFF );
   modify_field( Amory.Snowflake, 0 );
   modify_field( Amory.Tulia, 0 );
   modify_field( Amory.Teaneck, 64 );
   modify_field( Amory.Brush, 17 );
   modify_field( Amory.Gresston, CoalCity.Weatherby );
   modify_field( Amory.Worthing, CoalCity.Panaca );
   modify_field( Greenland.Kenefic, 0x0800 );
}
action Pierson(Tonasket) {
   add_header( Weissert );
   Willshire( Tonasket );
   Chavies( Amory.Lofgreen );
   Marvin();
}
action SneeOosh( Taconite ) {
   modify_field( Penalosa.Petroleum, Martelle.Petroleum );
   modify_field( Penalosa.Doyline, Martelle.Doyline );
   modify_field( Penalosa.Pinecrest, Martelle.Pinecrest );
   modify_field( Penalosa.Ringtown, Martelle.Ringtown );
   modify_field( Penalosa.Nunda, Martelle.Nunda );
   modify_field( Penalosa.Hilbert, Martelle.Hilbert );
   modify_field( Penalosa.Cadott, Martelle.Cadott );
   modify_field( Penalosa.Whiteclay, Martelle.Whiteclay );
   add( Penalosa.Glynn, Martelle.Glynn, Taconite );
}
action Talbert(Canalou) {
   add_header( Penalosa );
   SneeOosh( Canalou );
   remove_header( Martelle );
   add_header( Amory );
   Chavies( Martelle.Nunda );
   Marvin();
}
action Eggleston() {
   add_header( Amory );
   Chavies( eg_intr_md.pkt_length );
   Marvin();
}
table Paullina {
   reads {
      CoalCity.Parrish : exact;
      CoalCity.Warsaw : exact;
      CoalCity.Hopeton : exact;
      Amory.valid : ternary;
      Martelle.valid : ternary;
      Weissert.valid : ternary;
      Penalosa.valid : ternary;
   }
   actions {
      Shuqualak;
      Smithland;
      WallLake;
      Endeavor;
      Humble;
      Almota;
      Catawba;
      Yakutat;
      Duster;
      DelMar;
      Pierson;
      Talbert;
      Eggleston;
   }
   size : 512;
}
control Keller {
   apply( Sanchez );
}
control Harney {
   apply( Lilymoor );
}
control Lovilia {
   apply( Connell ) {
      Fitler {
         apply( FortHunt );
      }
   }
   apply( Terral );
   apply( Paullina );
}
field_list Brentford {
    Taneytown.Lincroft;
    Westboro.Trion;
    Calvary.Newberg;
    Calvary.Slick;
    Amory.Gresston;
}
action Camanche() {
   generate_digest(0, Brentford);
}
table Chilson {
   actions {
      Camanche;
   }
   default_action : Camanche;
   size : 1;
}
control Idalia {
   if (Taneytown.Lincroft == 2) {
      apply(Chilson);
   }
}
action Bonsall() {
   modify_field( Missoula.Dillsboro, Scherr.Champlin );
}
action Alameda() {
   modify_field( Missoula.Dillsboro, Mission[0].Danforth );
   modify_field( Westboro.Livonia, Mission[0].Wayne );
}
action Kenyon() {
   modify_field( Missoula.Crossnore, Scherr.Oconee );
}
action Orrick() {
   modify_field( Missoula.Crossnore, Macon.Mekoryuk );
}
action Arvonia() {
   modify_field( Missoula.Crossnore, Evelyn.Ulysses );
}
action Millhaven( Cecilton, Wakita ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Cecilton );
   modify_field( ig_intr_md_for_tm.qid, Wakita );
}
table Elysburg {
   reads {
     Westboro.LaVale : exact;
   }
   actions {
     Bonsall;
     Alameda;
   }
   size : 2;
}
table Galloway {
   reads {
     Westboro.Sturgeon : exact;
     Westboro.Giltner : exact;
   }
   actions {
     Kenyon;
     Orrick;
     Arvonia;
   }
   size : 3;
}
table Farragut {
   reads {
      Scherr.Mango : ternary;
      Scherr.Champlin : ternary;
      Missoula.Dillsboro : ternary;
      Missoula.Crossnore : ternary;
      Missoula.LaHoma : ternary;
   }
   actions {
      Millhaven;
   }
   size : 81;
}
action Quinault( Ludden, Nanson ) {
   bit_or( Missoula.Roxobel, Missoula.Roxobel, Ludden );
   bit_or( Missoula.Osseo, Missoula.Osseo, Nanson );
}
table MoonRun {
   actions {
      Quinault;
   }
   default_action : Quinault;
   size : 1;
}
action Greenwood( SoapLake ) {
   modify_field( Missoula.Crossnore, SoapLake );
}
action Nighthawk( SanJuan ) {
   modify_field( Missoula.Dillsboro, SanJuan );
}
action Tununak( Mendocino, Paradis ) {
   modify_field( Missoula.Dillsboro, Mendocino );
   modify_field( Missoula.Crossnore, Paradis );
}
table Oxford {
   reads {
      Scherr.Mango : exact;
      Missoula.Roxobel : exact;
      Missoula.Osseo : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Greenwood;
      Nighthawk;
      Tununak;
   }
   size : 512;
}
control Adelino {
   apply( Elysburg );
   apply( Galloway );
}
control Heidrick {
   apply( Farragut );
}
control Grapevine {
   apply( MoonRun );
   apply( Oxford );
}
action Falls( Rockaway ) {
   modify_field( Missoula.Cockrum, Rockaway );
}
table Gabbs {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
   }
   actions {
      Falls;
   }
}
action PellLake( Sawyer ) {
   modify_field( Missoula.Angwin, Sawyer );
}
table RichHill {
   reads {
      Missoula.Cockrum : ternary;
      Westboro.Livonia : ternary;
      Westboro.Larose : ternary;
      CoalCity.Batchelor : ternary;
      CoalCity.Almont : ternary;
      Alburnett.Luttrell : ternary;
   }
   actions {
      PellLake;
   }
   default_action: PellLake;
   size : 512;
}
table Everetts {
   reads {
      Missoula.Cockrum : ternary;
      Westboro.Sturgeon : ternary;
      Westboro.Giltner : ternary;
      Westboro.Larose : ternary;
      Macon.Anchorage : ternary;
      Evelyn.Macland mask 0xffff0000000000000000000000000000 : ternary;
      Westboro.Weatherly : ternary;
      Westboro.Halliday : ternary;
      CoalCity.Hopeton : ternary;
      Alburnett.Luttrell : ternary;
      Vandling.Dresser : ternary;
      Vandling.Kaltag : ternary;
   }
   actions {
      PellLake;
   }
   default_action: PellLake;
   size : 512;
}
meter Northome {
   type : packets;
   static : CityView;
   instance_count : 4096;
}
counter Alabaster {
   type : packets;
   static : CityView;
   instance_count : 4096;
   min_width : 64;
}
action Valentine(LaneCity) {
   execute_meter( Northome, LaneCity, ig_intr_md_for_tm.packet_color );
}
action Edinburgh(Karluk) {
   count( Alabaster, Karluk );
}
action Funston(Heuvelton) {
   Valentine(Heuvelton);
   Edinburgh(Heuvelton);
}
table CityView {
   reads {
      Missoula.Cockrum : exact;
      Missoula.Angwin : exact;
   }
   actions {
     Edinburgh;
     Funston;
   }
   size : 512;
}
control Redvale {
   apply( Gabbs );
}
control LaMonte {
      if ( ( Westboro.Sturgeon == 0 ) and ( Westboro.Giltner == 0 ) ) {
         apply( RichHill );
      } else {
         apply( Everetts );
      }
}
control Burgdorf {
    if ( Westboro.Kasilof == 0 ) {
      apply( CityView );
   }
}
counter Domingo {
   type : packets;
   direct : Stennett;
   min_width : 64;
}
action Lafayette( Hodge, Homeworth ) {
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Hodge );
   modify_field( CoalCity.Becida, ig_intr_md.ingress_port );
   modify_field( ig_intr_md_for_tm.qid, Homeworth );
}
action Russia() {
   modify_field( CoalCity.Becida, ig_intr_md.ingress_port );
}
action Norwood( Struthers, Rainelle ) {
   Lafayette( Struthers, Rainelle );
   modify_field( CoalCity.Pekin, 0);
}
action Lilly() {
   Russia();
   modify_field( CoalCity.Pekin, 0);
}
action Chitina( Annetta, KawCity ) {
   Lafayette( Annetta, KawCity );
   modify_field( CoalCity.Pekin, 1);
}
action Wheeler() {
   Russia();
   modify_field( CoalCity.Pekin, 1);
}
@pragma ternary 1
table Stennett {
   reads {
      CoalCity.Murphy : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      Mission[0] : valid;
      CoalCity.Royston : ternary;
   }
   actions {
      Norwood;
      Lilly;
      Chitina;
      Wheeler;
   }
   default_action : Fitler();
   size : 512;
}
control Gunter {
   apply( Stennett ) {
      Norwood {
      }
      Chitina {
      }
      default {
         Loris();
      }
   }
}
counter DeGraff {
   type : packets_and_bytes;
   instance_count : 1024;
   min_width : 128;
}
action Lasker( Mosinee ) {
   count( DeGraff, Mosinee );
}
table Oskaloosa {
   reads {
      eg_intr_md.egress_port mask 0x7f: exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }
   actions {
     Lasker;
   }
   size : 1024;
}
control Habersham {
   apply( Oskaloosa );
}
action Belfast()
{
   Cooter();
}
action Rawson() {
   modify_field(CoalCity.Parrish, 3);
}
action Brookwood( Neche ) {
   modify_field(CoalCity.Parrish, 2);
   modify_field(CoalCity.Killen, Neche);
}
table Wilsey {
   reads {
      Conneaut.Placid : exact;
      Conneaut.Edinburg : exact;
      Conneaut.Empire : exact;
      Conneaut.Fries : exact;
   }
   actions {
      Brookwood;
      Rawson;
      Belfast;
   }
   default_action : Belfast();
   size : 512;
}
control Jesup {
   apply( Wilsey );
}
action Placida( Aurora, ElkPoint, Bevier, Paxtonia ) {
   modify_field( Lutts.Plush, Aurora );
   modify_field( McLaurin.Bedrock, Bevier );
   modify_field( McLaurin.Kearns, ElkPoint );
   modify_field( McLaurin.Wildorado, Paxtonia );
}
table Wollochet {
   reads {
     Macon.Anchorage : exact;
     Westboro.Gerty : exact;
   }
   actions {
      Placida;
   }
  size : 16384;
}
action PineLake(Temelec, Anson, Meridean) {
   modify_field( McLaurin.Kearns, Temelec );
   modify_field( McLaurin.Bedrock, Anson );
   modify_field( McLaurin.Wildorado, Meridean );
}
table Arroyo {
   reads {
     Macon.Kempton : exact;
     Lutts.Plush : exact;
   }
   actions {
      PineLake;
   }
   size : 16384;
}
action Bluewater( Alvwood, LeSueur, Kamas ) {
   modify_field( Nanakuli.LakeFork, Alvwood );
   modify_field( Nanakuli.Euren, LeSueur );
   modify_field( Nanakuli.FourTown, Kamas );
}
table Castine {
   reads {
     CoalCity.Almont : exact;
     CoalCity.Batchelor : exact;
     CoalCity.Cozad : exact;
   }
   actions {
      Bluewater;
   }
   size : 16384;
}
action Holcomb() {
   modify_field( CoalCity.Mapleview, 1 );
}
action Monida( Fallis ) {
   Holcomb();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, McLaurin.Kearns );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Fallis, McLaurin.Wildorado );
}
action Agency( Cahokia ) {
   Holcomb();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Nanakuli.LakeFork );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Cahokia, Nanakuli.FourTown );
}
action Yakima( RockPort ) {
   Holcomb();
   add( ig_intr_md_for_tm.mcast_grp_a, CoalCity.Cozad,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, RockPort );
}
action Munday() {
   modify_field( CoalCity.Squire, 1 );
}
table Pikeville {
   reads {
     McLaurin.Bedrock : ternary;
     McLaurin.Kearns : ternary;
     Nanakuli.LakeFork : ternary;
     Nanakuli.Euren : ternary;
     Westboro.Weatherly :ternary;
     Westboro.Frewsburg:ternary;
   }
   actions {
      Monida;
      Agency;
      Yakima;
      Munday;
   }
   size : 32;
}
control Olcott {
   if( Westboro.Kasilof == 0 and
       ( ( Wetumpka.Ocheyedan & ( 0x4 ) ) == ( ( 0x4 ) ) ) and
       Westboro.Abbott == 1 ) {
      apply( Wollochet );
   }
}
control Wauregan {
   if( Lutts.Plush != 0 ) {
      apply( Arroyo );
   }
}
control Bonduel {
   if( Westboro.Kasilof == 0 and Westboro.Frewsburg==1 ) {
      apply( Castine );
   }
}
control Cushing {
   if( Westboro.Frewsburg == 1 ) {
      apply(Pikeville);
   }
}
action Padroni(Auberry) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Woodfield.Wauna );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Auberry );
}
table Morita {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Padroni;
    }
    size : 512;
}
control Assinippi {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Morita);
   }
}
action Ontonagon( Harold, Parkland, Kinards ) {
   modify_field( CoalCity.Cozad, Harold );
   modify_field( CoalCity.Hopeton, Parkland );
   bit_or( eg_intr_md_for_oport.drop_ctl, eg_intr_md_for_oport.drop_ctl, Kinards );
}
@pragma use_hash_action 1
table Simnasho {
   reads {
     eg_intr_md.egress_rid: exact;
   }
   actions {
      Ontonagon;
   }
   default_action: Ontonagon( 0, 0, 1 );
   size : 65536;
}
control Hercules {
   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Simnasho);
   }
}
counter Henry {
   type : packets;
   direct: Onarga;
   min_width: 63;
}
@pragma stage 11
table Onarga {
   reads {
     Weyauwega.Alcoma mask 0x7fff : exact;
   }
   actions {
      Fitler;
   }
   default_action: Fitler();
   size : 32768;
}
action Grottoes() {
   modify_field( Wildell.Pinebluff, Westboro.Weatherly );
   modify_field( Wildell.Croghan, Macon.Mekoryuk );
   modify_field( Wildell.Proctor, Westboro.Halliday );
   modify_field( Wildell.Moorewood, Westboro.Powers );
}
action Dellslow() {
   modify_field( Wildell.Pinebluff, Westboro.Weatherly );
   modify_field( Wildell.Croghan, Evelyn.Ulysses );
   modify_field( Wildell.Proctor, Westboro.Halliday );
   modify_field( Wildell.Moorewood, Westboro.Powers );
}
action Grayland( Mabank ) {
   Grottoes();
   modify_field( Wildell.Hilgard, Mabank );
}
action Hitchland( Masontown ) {
   Dellslow();
   modify_field( Wildell.Hilgard, Masontown );
}
table Shubert {
   reads {
     Macon.Kempton : ternary;
   }
   actions {
      Grayland;
   }
   default_action : Grottoes;
  size : 2048;
}
table Otranto {
   reads {
     Evelyn.Albemarle : ternary;
   }
   actions {
      Hitchland;
   }
   default_action : Dellslow;
   size : 1024;
}
action Lakeside( Lasara ) {
   modify_field( Wildell.Nashoba, Lasara );
}
table Gerlach {
   reads {
     Macon.Anchorage : ternary;
   }
   actions {
      Lakeside;
   }
   size : 512;
}
table Havana {
   reads {
     Evelyn.Macland : ternary;
   }
   actions {
      Lakeside;
   }
   size : 512;
}
action Whigham( Wapella ) {
   modify_field( Wildell.Dushore, Wapella );
}
table Pendroy {
   reads {
     Westboro.Wakefield : ternary;
   }
   actions {
      Whigham;
   }
   size : 512;
}
action Tillatoba( Overbrook ) {
   modify_field( Wildell.Waretown, Overbrook );
}
table Maxwelton {
   reads {
     Westboro.Diana : ternary;
   }
   actions {
      Tillatoba;
   }
   size : 512;
}
action Clarkdale( Paragonah ) {
   modify_field( Wildell.Tofte, Paragonah );
}
action Suffolk( Tularosa ) {
   modify_field( Wildell.Tofte, Tularosa );
}
table Kingstown {
   reads {
     Westboro.Sturgeon : exact;
     Westboro.Giltner : exact;
     Westboro.Correo mask 4 : exact;
     Westboro.Gerty : exact;
   }
   actions {
      Clarkdale;
      Fitler;
   }
   default_action : Fitler();
   size : 4096;
}
table Satanta {
   reads {
     Westboro.Sturgeon : exact;
     Westboro.Giltner : exact;
     Westboro.Correo mask 4 : exact;
     Scherr.McDavid : exact;
   }
   actions {
      Suffolk;
   }
   size : 512;
}
control Baskin {
   if( Westboro.Sturgeon == 1 ) {
      apply( Shubert );
      apply( Gerlach );
   } else if( Westboro.Giltner == 1 ) {
      apply( Otranto );
      apply( Havana );
   }
   if( ( Westboro.Correo & 2 ) == 2 ) {
      apply( Pendroy );
      apply( Maxwelton );
   }
   apply( Kingstown ) {
      Fitler {
         apply( Satanta );
      }
   }
}
action WestLine() {
}
action Beaverdam() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action Konnarock() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
}
action Hawley() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
table Harriet {
   reads {
     Weyauwega.Alcoma mask 0x00018000 : ternary;
   }
   actions {
      WestLine;
      Beaverdam;
      Konnarock;
      Hawley;
   }
   size : 16;
}
control Wattsburg {
   apply( Harriet );
   apply( Onarga );
}
   metadata Ashwood Weyauwega;
   action Chualar( Fonda ) {
          max( Weyauwega.Alcoma, Weyauwega.Alcoma, Fonda );
   }
@pragma ways 4
table Tecumseh {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : exact;
      Wildell.Nashoba : exact;
      Wildell.Dushore : exact;
      Wildell.Waretown : exact;
      Wildell.Pinebluff : exact;
      Wildell.Croghan : exact;
      Wildell.Proctor : exact;
      Wildell.Moorewood : exact;
      Wildell.Shabbona : exact;
   }
   actions {
      Chualar;
   }
   size : 4096;
}
control Canfield {
   apply( Tecumseh );
}
table Olmitz {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : ternary;
      Wildell.Nashoba : ternary;
      Wildell.Dushore : ternary;
      Wildell.Waretown : ternary;
      Wildell.Pinebluff : ternary;
      Wildell.Croghan : ternary;
      Wildell.Proctor : ternary;
      Wildell.Moorewood : ternary;
      Wildell.Shabbona : ternary;
   }
   actions {
      Chualar;
   }
   size : 512;
}
control Freehold {
   apply( Olmitz );
}
@pragma pa_no_init ingress Woodbury.Hilgard
@pragma pa_no_init ingress Woodbury.Nashoba
@pragma pa_no_init ingress Woodbury.Dushore
@pragma pa_no_init ingress Woodbury.Waretown
@pragma pa_no_init ingress Woodbury.Pinebluff
@pragma pa_no_init ingress Woodbury.Croghan
@pragma pa_no_init ingress Woodbury.Proctor
@pragma pa_no_init ingress Woodbury.Moorewood
@pragma pa_no_init ingress Woodbury.Shabbona
metadata Shirley Woodbury;
@pragma ways 4
table NorthRim {
   reads {
      Wildell.Tofte : exact;
      Woodbury.Hilgard : exact;
      Woodbury.Nashoba : exact;
      Woodbury.Dushore : exact;
      Woodbury.Waretown : exact;
      Woodbury.Pinebluff : exact;
      Woodbury.Croghan : exact;
      Woodbury.Proctor : exact;
      Woodbury.Moorewood : exact;
      Woodbury.Shabbona : exact;
   }
   actions {
      Chualar;
   }
   size : 8192;
}
action Rumson( HighRock, Milwaukie, Homeland, Lazear, Coalton, Kennedale, Sonora, Rotterdam, Catawissa ) {
   bit_and( Woodbury.Hilgard, Wildell.Hilgard, HighRock );
   bit_and( Woodbury.Nashoba, Wildell.Nashoba, Milwaukie );
   bit_and( Woodbury.Dushore, Wildell.Dushore, Homeland );
   bit_and( Woodbury.Waretown, Wildell.Waretown, Lazear );
   bit_and( Woodbury.Pinebluff, Wildell.Pinebluff, Coalton );
   bit_and( Woodbury.Croghan, Wildell.Croghan, Kennedale );
   bit_and( Woodbury.Proctor, Wildell.Proctor, Sonora );
   bit_and( Woodbury.Moorewood, Wildell.Moorewood, Rotterdam );
   bit_and( Woodbury.Shabbona, Wildell.Shabbona, Catawissa );
}
table Timnath {
   reads {
      Wildell.Tofte : exact;
   }
   actions {
      Rumson;
   }
   default_action : Rumson(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Arapahoe {
   apply( Timnath );
}
control Blakeman {
   apply( NorthRim );
}
table Delmont {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : ternary;
      Wildell.Nashoba : ternary;
      Wildell.Dushore : ternary;
      Wildell.Waretown : ternary;
      Wildell.Pinebluff : ternary;
      Wildell.Croghan : ternary;
      Wildell.Proctor : ternary;
      Wildell.Moorewood : ternary;
      Wildell.Shabbona : ternary;
   }
   actions {
      Chualar;
   }
   size : 512;
}
control Barney {
   apply( Delmont );
}
@pragma ways 4
table Padonia {
   reads {
      Wildell.Tofte : exact;
      Woodbury.Hilgard : exact;
      Woodbury.Nashoba : exact;
      Woodbury.Dushore : exact;
      Woodbury.Waretown : exact;
      Woodbury.Pinebluff : exact;
      Woodbury.Croghan : exact;
      Woodbury.Proctor : exact;
      Woodbury.Moorewood : exact;
      Woodbury.Shabbona : exact;
   }
   actions {
      Chualar;
   }
   size : 4096;
}
action Baltimore( Quamba, Magna, Waipahu, Novinger, Hebbville, Mayday, Finley, Filer, Lefor ) {
   bit_and( Woodbury.Hilgard, Wildell.Hilgard, Quamba );
   bit_and( Woodbury.Nashoba, Wildell.Nashoba, Magna );
   bit_and( Woodbury.Dushore, Wildell.Dushore, Waipahu );
   bit_and( Woodbury.Waretown, Wildell.Waretown, Novinger );
   bit_and( Woodbury.Pinebluff, Wildell.Pinebluff, Hebbville );
   bit_and( Woodbury.Croghan, Wildell.Croghan, Mayday );
   bit_and( Woodbury.Proctor, Wildell.Proctor, Finley );
   bit_and( Woodbury.Moorewood, Wildell.Moorewood, Filer );
   bit_and( Woodbury.Shabbona, Wildell.Shabbona, Lefor );
}
table Gamewell {
   reads {
      Wildell.Tofte : exact;
   }
   actions {
      Baltimore;
   }
   default_action : Baltimore(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Kelsey {
   apply( Gamewell );
}
control Frontier {
   apply( Padonia );
}
table Wilson {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : ternary;
      Wildell.Nashoba : ternary;
      Wildell.Dushore : ternary;
      Wildell.Waretown : ternary;
      Wildell.Pinebluff : ternary;
      Wildell.Croghan : ternary;
      Wildell.Proctor : ternary;
      Wildell.Moorewood : ternary;
      Wildell.Shabbona : ternary;
   }
   actions {
      Chualar;
   }
   size : 512;
}
control Cowley {
   apply( Wilson );
}
@pragma ways 4
table Venturia {
   reads {
      Wildell.Tofte : exact;
      Woodbury.Hilgard : exact;
      Woodbury.Nashoba : exact;
      Woodbury.Dushore : exact;
      Woodbury.Waretown : exact;
      Woodbury.Pinebluff : exact;
      Woodbury.Croghan : exact;
      Woodbury.Proctor : exact;
      Woodbury.Moorewood : exact;
      Woodbury.Shabbona : exact;
   }
   actions {
      Chualar;
   }
   size : 4096;
}
action Swifton( Coyote, Larchmont, Arvada, McAdoo, Sidon, Francisco, Riner, Thalia, Valders ) {
   bit_and( Woodbury.Hilgard, Wildell.Hilgard, Coyote );
   bit_and( Woodbury.Nashoba, Wildell.Nashoba, Larchmont );
   bit_and( Woodbury.Dushore, Wildell.Dushore, Arvada );
   bit_and( Woodbury.Waretown, Wildell.Waretown, McAdoo );
   bit_and( Woodbury.Pinebluff, Wildell.Pinebluff, Sidon );
   bit_and( Woodbury.Croghan, Wildell.Croghan, Francisco );
   bit_and( Woodbury.Proctor, Wildell.Proctor, Riner );
   bit_and( Woodbury.Moorewood, Wildell.Moorewood, Thalia );
   bit_and( Woodbury.Shabbona, Wildell.Shabbona, Valders );
}
table Savery {
   reads {
      Wildell.Tofte : exact;
   }
   actions {
      Swifton;
   }
   default_action : Swifton(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Chicago {
   apply( Savery );
}
control Pierpont {
   apply( Venturia );
}
table Lapoint {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : ternary;
      Wildell.Nashoba : ternary;
      Wildell.Dushore : ternary;
      Wildell.Waretown : ternary;
      Wildell.Pinebluff : ternary;
      Wildell.Croghan : ternary;
      Wildell.Proctor : ternary;
      Wildell.Moorewood : ternary;
      Wildell.Shabbona : ternary;
   }
   actions {
      Chualar;
   }
   size : 512;
}
control Knierim {
   apply( Lapoint );
}
@pragma ways 4
table RoseBud {
   reads {
      Wildell.Tofte : exact;
      Woodbury.Hilgard : exact;
      Woodbury.Nashoba : exact;
      Woodbury.Dushore : exact;
      Woodbury.Waretown : exact;
      Woodbury.Pinebluff : exact;
      Woodbury.Croghan : exact;
      Woodbury.Proctor : exact;
      Woodbury.Moorewood : exact;
      Woodbury.Shabbona : exact;
   }
   actions {
      Chualar;
   }
   size : 8192;
}
action Bayne( SnowLake, Sanford, Contact, White, Belview, Illmo, Candor, Elvaston, Saxonburg ) {
   bit_and( Woodbury.Hilgard, Wildell.Hilgard, SnowLake );
   bit_and( Woodbury.Nashoba, Wildell.Nashoba, Sanford );
   bit_and( Woodbury.Dushore, Wildell.Dushore, Contact );
   bit_and( Woodbury.Waretown, Wildell.Waretown, White );
   bit_and( Woodbury.Pinebluff, Wildell.Pinebluff, Belview );
   bit_and( Woodbury.Croghan, Wildell.Croghan, Illmo );
   bit_and( Woodbury.Proctor, Wildell.Proctor, Candor );
   bit_and( Woodbury.Moorewood, Wildell.Moorewood, Elvaston );
   bit_and( Woodbury.Shabbona, Wildell.Shabbona, Saxonburg );
}
table Vantage {
   reads {
      Wildell.Tofte : exact;
   }
   actions {
      Bayne;
   }
   default_action : Bayne(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Success {
   apply( Vantage );
}
control Lenox {
   apply( RoseBud );
}
table Perdido {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : ternary;
      Wildell.Nashoba : ternary;
      Wildell.Dushore : ternary;
      Wildell.Waretown : ternary;
      Wildell.Pinebluff : ternary;
      Wildell.Croghan : ternary;
      Wildell.Proctor : ternary;
      Wildell.Moorewood : ternary;
      Wildell.Shabbona : ternary;
   }
   actions {
      Chualar;
   }
   size : 512;
}
control Aguilita {
   apply( Perdido );
}
@pragma ways 4
table Paulette {
   reads {
      Wildell.Tofte : exact;
      Woodbury.Hilgard : exact;
      Woodbury.Nashoba : exact;
      Woodbury.Dushore : exact;
      Woodbury.Waretown : exact;
      Woodbury.Pinebluff : exact;
      Woodbury.Croghan : exact;
      Woodbury.Proctor : exact;
      Woodbury.Moorewood : exact;
      Woodbury.Shabbona : exact;
   }
   actions {
      Chualar;
   }
   size : 8192;
}
action Nelson( Lamison, Shelby, Corum, Ackerly, Arial, Vacherie, Yemassee, Flomot, Keltys ) {
   bit_and( Woodbury.Hilgard, Wildell.Hilgard, Lamison );
   bit_and( Woodbury.Nashoba, Wildell.Nashoba, Shelby );
   bit_and( Woodbury.Dushore, Wildell.Dushore, Corum );
   bit_and( Woodbury.Waretown, Wildell.Waretown, Ackerly );
   bit_and( Woodbury.Pinebluff, Wildell.Pinebluff, Arial );
   bit_and( Woodbury.Croghan, Wildell.Croghan, Vacherie );
   bit_and( Woodbury.Proctor, Wildell.Proctor, Yemassee );
   bit_and( Woodbury.Moorewood, Wildell.Moorewood, Flomot );
   bit_and( Woodbury.Shabbona, Wildell.Shabbona, Keltys );
}
table Hematite {
   reads {
      Wildell.Tofte : exact;
   }
   actions {
      Nelson;
   }
   default_action : Nelson(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Tuttle {
   apply( Hematite );
}
control Craigmont {
   apply( Paulette );
}
table Hester {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : ternary;
      Wildell.Nashoba : ternary;
      Wildell.Dushore : ternary;
      Wildell.Waretown : ternary;
      Wildell.Pinebluff : ternary;
      Wildell.Croghan : ternary;
      Wildell.Proctor : ternary;
      Wildell.Moorewood : ternary;
      Wildell.Shabbona : ternary;
   }
   actions {
      Chualar;
   }
   size : 512;
}
control Micco {
   apply( Hester );
}
@pragma ways 4
table Midas {
   reads {
      Wildell.Tofte : exact;
      Woodbury.Hilgard : exact;
      Woodbury.Nashoba : exact;
      Woodbury.Dushore : exact;
      Woodbury.Waretown : exact;
      Woodbury.Pinebluff : exact;
      Woodbury.Croghan : exact;
      Woodbury.Proctor : exact;
      Woodbury.Moorewood : exact;
      Woodbury.Shabbona : exact;
   }
   actions {
      Chualar;
   }
   size : 4096;
}
action Highcliff( Arnett, WhiteOwl, Monohan, LasLomas, Gobles, Ignacio, Zebina, Inverness, Littleton ) {
   bit_and( Woodbury.Hilgard, Wildell.Hilgard, Arnett );
   bit_and( Woodbury.Nashoba, Wildell.Nashoba, WhiteOwl );
   bit_and( Woodbury.Dushore, Wildell.Dushore, Monohan );
   bit_and( Woodbury.Waretown, Wildell.Waretown, LasLomas );
   bit_and( Woodbury.Pinebluff, Wildell.Pinebluff, Gobles );
   bit_and( Woodbury.Croghan, Wildell.Croghan, Ignacio );
   bit_and( Woodbury.Proctor, Wildell.Proctor, Zebina );
   bit_and( Woodbury.Moorewood, Wildell.Moorewood, Inverness );
   bit_and( Woodbury.Shabbona, Wildell.Shabbona, Littleton );
}
table Swedeborg {
   reads {
      Wildell.Tofte : exact;
   }
   actions {
      Highcliff;
   }
   default_action : Highcliff(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Bratenahl {
   apply( Swedeborg );
}
control Truro {
   apply( Midas );
}
table Coronado {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : ternary;
      Wildell.Nashoba : ternary;
      Wildell.Dushore : ternary;
      Wildell.Waretown : ternary;
      Wildell.Pinebluff : ternary;
      Wildell.Croghan : ternary;
      Wildell.Proctor : ternary;
      Wildell.Moorewood : ternary;
      Wildell.Shabbona : ternary;
   }
   actions {
      Chualar;
   }
   size : 512;
}
control Monowi {
   apply( Coronado );
}
@pragma ways 4
table Hedrick {
   reads {
      Wildell.Tofte : exact;
      Woodbury.Hilgard : exact;
      Woodbury.Nashoba : exact;
      Woodbury.Dushore : exact;
      Woodbury.Waretown : exact;
      Woodbury.Pinebluff : exact;
      Woodbury.Croghan : exact;
      Woodbury.Proctor : exact;
      Woodbury.Moorewood : exact;
      Woodbury.Shabbona : exact;
   }
   actions {
      Chualar;
   }
   size : 4096;
}
action Madeira( Burket, Ahuimanu, Kingman, Mabelle, Leetsdale, Burrton, Manakin, Coalgate, Woolwine ) {
   bit_and( Woodbury.Hilgard, Wildell.Hilgard, Burket );
   bit_and( Woodbury.Nashoba, Wildell.Nashoba, Ahuimanu );
   bit_and( Woodbury.Dushore, Wildell.Dushore, Kingman );
   bit_and( Woodbury.Waretown, Wildell.Waretown, Mabelle );
   bit_and( Woodbury.Pinebluff, Wildell.Pinebluff, Leetsdale );
   bit_and( Woodbury.Croghan, Wildell.Croghan, Burrton );
   bit_and( Woodbury.Proctor, Wildell.Proctor, Manakin );
   bit_and( Woodbury.Moorewood, Wildell.Moorewood, Coalgate );
   bit_and( Woodbury.Shabbona, Wildell.Shabbona, Woolwine );
}
table Kinston {
   reads {
      Wildell.Tofte : exact;
   }
   actions {
      Madeira;
   }
   default_action : Madeira(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Volens {
   apply( Kinston );
}
control Dryden {
   apply( Hedrick );
}
table Helotes {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : ternary;
      Wildell.Nashoba : ternary;
      Wildell.Dushore : ternary;
      Wildell.Waretown : ternary;
      Wildell.Pinebluff : ternary;
      Wildell.Croghan : ternary;
      Wildell.Proctor : ternary;
      Wildell.Moorewood : ternary;
      Wildell.Shabbona : ternary;
   }
   actions {
      Chualar;
   }
   size : 512;
}
control Slayden {
   apply( Helotes );
}
   metadata Ashwood Raytown;
   action Sedona( Kinter ) {
          max( Raytown.Alcoma, Raytown.Alcoma, Kinter );
   }
   action Seaford() { max( Weyauwega.Alcoma, Raytown.Alcoma, Weyauwega.Alcoma ); } table Dundalk { actions { Seaford; } default_action : Seaford; size : 1; } control Helton { apply( Dundalk ); }
@pragma ways 4
table Artas {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : exact;
      Wildell.Nashoba : exact;
      Wildell.Dushore : exact;
      Wildell.Waretown : exact;
      Wildell.Pinebluff : exact;
      Wildell.Croghan : exact;
      Wildell.Proctor : exact;
      Wildell.Moorewood : exact;
      Wildell.Shabbona : exact;
   }
   actions {
      Sedona;
   }
   size : 4096;
}
control Guaynabo {
   apply( Artas );
}
table Astatula {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : ternary;
      Wildell.Nashoba : ternary;
      Wildell.Dushore : ternary;
      Wildell.Waretown : ternary;
      Wildell.Pinebluff : ternary;
      Wildell.Croghan : ternary;
      Wildell.Proctor : ternary;
      Wildell.Moorewood : ternary;
      Wildell.Shabbona : ternary;
   }
   actions {
      Sedona;
   }
   size : 4096;
}
control Copley {
   apply( Astatula );
}
@pragma pa_no_init ingress Viroqua.Hilgard
@pragma pa_no_init ingress Viroqua.Nashoba
@pragma pa_no_init ingress Viroqua.Dushore
@pragma pa_no_init ingress Viroqua.Waretown
@pragma pa_no_init ingress Viroqua.Pinebluff
@pragma pa_no_init ingress Viroqua.Croghan
@pragma pa_no_init ingress Viroqua.Proctor
@pragma pa_no_init ingress Viroqua.Moorewood
@pragma pa_no_init ingress Viroqua.Shabbona
metadata Shirley Viroqua;
@pragma ways 4
table Follett {
   reads {
      Wildell.Tofte : exact;
      Viroqua.Hilgard : exact;
      Viroqua.Nashoba : exact;
      Viroqua.Dushore : exact;
      Viroqua.Waretown : exact;
      Viroqua.Pinebluff : exact;
      Viroqua.Croghan : exact;
      Viroqua.Proctor : exact;
      Viroqua.Moorewood : exact;
      Viroqua.Shabbona : exact;
   }
   actions {
      Sedona;
   }
   size : 4096;
}
action Teigen( Ojibwa, Goessel, Robert, Amenia, Felida, Sunset, Monrovia, Hackney, Berenice ) {
   bit_and( Viroqua.Hilgard, Wildell.Hilgard, Ojibwa );
   bit_and( Viroqua.Nashoba, Wildell.Nashoba, Goessel );
   bit_and( Viroqua.Dushore, Wildell.Dushore, Robert );
   bit_and( Viroqua.Waretown, Wildell.Waretown, Amenia );
   bit_and( Viroqua.Pinebluff, Wildell.Pinebluff, Felida );
   bit_and( Viroqua.Croghan, Wildell.Croghan, Sunset );
   bit_and( Viroqua.Proctor, Wildell.Proctor, Monrovia );
   bit_and( Viroqua.Moorewood, Wildell.Moorewood, Hackney );
   bit_and( Viroqua.Shabbona, Wildell.Shabbona, Berenice );
}
table Claysburg {
   reads {
      Wildell.Tofte : exact;
   }
   actions {
      Teigen;
   }
   default_action : Teigen(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Grisdale {
   apply( Claysburg );
}
control Warden {
   apply( Follett );
}
table ArchCape {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : ternary;
      Wildell.Nashoba : ternary;
      Wildell.Dushore : ternary;
      Wildell.Waretown : ternary;
      Wildell.Pinebluff : ternary;
      Wildell.Croghan : ternary;
      Wildell.Proctor : ternary;
      Wildell.Moorewood : ternary;
      Wildell.Shabbona : ternary;
   }
   actions {
      Sedona;
   }
   size : 512;
}
control Advance {
   apply( ArchCape );
}
@pragma ways 4
table Longmont {
   reads {
      Wildell.Tofte : exact;
      Viroqua.Hilgard : exact;
      Viroqua.Nashoba : exact;
      Viroqua.Dushore : exact;
      Viroqua.Waretown : exact;
      Viroqua.Pinebluff : exact;
      Viroqua.Croghan : exact;
      Viroqua.Proctor : exact;
      Viroqua.Moorewood : exact;
      Viroqua.Shabbona : exact;
   }
   actions {
      Sedona;
   }
   size : 4096;
}
action Fackler( Luning, Yardley, Shongaloo, Henning, DuBois, Duelm, Bechyn, Lakin, Bettles ) {
   bit_and( Viroqua.Hilgard, Wildell.Hilgard, Luning );
   bit_and( Viroqua.Nashoba, Wildell.Nashoba, Yardley );
   bit_and( Viroqua.Dushore, Wildell.Dushore, Shongaloo );
   bit_and( Viroqua.Waretown, Wildell.Waretown, Henning );
   bit_and( Viroqua.Pinebluff, Wildell.Pinebluff, DuBois );
   bit_and( Viroqua.Croghan, Wildell.Croghan, Duelm );
   bit_and( Viroqua.Proctor, Wildell.Proctor, Bechyn );
   bit_and( Viroqua.Moorewood, Wildell.Moorewood, Lakin );
   bit_and( Viroqua.Shabbona, Wildell.Shabbona, Bettles );
}
table Hewitt {
   reads {
      Wildell.Tofte : exact;
   }
   actions {
      Fackler;
   }
   default_action : Fackler(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Nederland {
   apply( Hewitt );
}
control Wayzata {
   apply( Longmont );
}
table Drifton {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : ternary;
      Wildell.Nashoba : ternary;
      Wildell.Dushore : ternary;
      Wildell.Waretown : ternary;
      Wildell.Pinebluff : ternary;
      Wildell.Croghan : ternary;
      Wildell.Proctor : ternary;
      Wildell.Moorewood : ternary;
      Wildell.Shabbona : ternary;
   }
   actions {
      Sedona;
   }
   size : 512;
}
control Newellton {
   apply( Drifton );
}
@pragma ways 4
table Westbrook {
   reads {
      Wildell.Tofte : exact;
      Viroqua.Hilgard : exact;
      Viroqua.Nashoba : exact;
      Viroqua.Dushore : exact;
      Viroqua.Waretown : exact;
      Viroqua.Pinebluff : exact;
      Viroqua.Croghan : exact;
      Viroqua.Proctor : exact;
      Viroqua.Moorewood : exact;
      Viroqua.Shabbona : exact;
   }
   actions {
      Sedona;
   }
   size : 4096;
}
action Albin( Froid, Quivero, Ashburn, RedElm, Comptche, Embarrass, Monkstown, Pajaros, Wheaton ) {
   bit_and( Viroqua.Hilgard, Wildell.Hilgard, Froid );
   bit_and( Viroqua.Nashoba, Wildell.Nashoba, Quivero );
   bit_and( Viroqua.Dushore, Wildell.Dushore, Ashburn );
   bit_and( Viroqua.Waretown, Wildell.Waretown, RedElm );
   bit_and( Viroqua.Pinebluff, Wildell.Pinebluff, Comptche );
   bit_and( Viroqua.Croghan, Wildell.Croghan, Embarrass );
   bit_and( Viroqua.Proctor, Wildell.Proctor, Monkstown );
   bit_and( Viroqua.Moorewood, Wildell.Moorewood, Pajaros );
   bit_and( Viroqua.Shabbona, Wildell.Shabbona, Wheaton );
}
table Combine {
   reads {
      Wildell.Tofte : exact;
   }
   actions {
      Albin;
   }
   default_action : Albin(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control PineLawn {
   apply( Combine );
}
control Bondad {
   apply( Westbrook );
}
table Dubach {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : ternary;
      Wildell.Nashoba : ternary;
      Wildell.Dushore : ternary;
      Wildell.Waretown : ternary;
      Wildell.Pinebluff : ternary;
      Wildell.Croghan : ternary;
      Wildell.Proctor : ternary;
      Wildell.Moorewood : ternary;
      Wildell.Shabbona : ternary;
   }
   actions {
      Sedona;
   }
   size : 512;
}
control Captiva {
   apply( Dubach );
}
@pragma ways 4
table Southdown {
   reads {
      Wildell.Tofte : exact;
      Viroqua.Hilgard : exact;
      Viroqua.Nashoba : exact;
      Viroqua.Dushore : exact;
      Viroqua.Waretown : exact;
      Viroqua.Pinebluff : exact;
      Viroqua.Croghan : exact;
      Viroqua.Proctor : exact;
      Viroqua.Moorewood : exact;
      Viroqua.Shabbona : exact;
   }
   actions {
      Sedona;
   }
   size : 4096;
}
action Edgemont( Hobson, Forepaugh, Romero, Gracewood, Affton, Muenster, WestLawn, Floris, Twinsburg ) {
   bit_and( Viroqua.Hilgard, Wildell.Hilgard, Hobson );
   bit_and( Viroqua.Nashoba, Wildell.Nashoba, Forepaugh );
   bit_and( Viroqua.Dushore, Wildell.Dushore, Romero );
   bit_and( Viroqua.Waretown, Wildell.Waretown, Gracewood );
   bit_and( Viroqua.Pinebluff, Wildell.Pinebluff, Affton );
   bit_and( Viroqua.Croghan, Wildell.Croghan, Muenster );
   bit_and( Viroqua.Proctor, Wildell.Proctor, WestLawn );
   bit_and( Viroqua.Moorewood, Wildell.Moorewood, Floris );
   bit_and( Viroqua.Shabbona, Wildell.Shabbona, Twinsburg );
}
table Newkirk {
   reads {
      Wildell.Tofte : exact;
   }
   actions {
      Edgemont;
   }
   default_action : Edgemont(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Ellisport {
   apply( Newkirk );
}
control Hiseville {
   apply( Southdown );
}
table Hoagland {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : ternary;
      Wildell.Nashoba : ternary;
      Wildell.Dushore : ternary;
      Wildell.Waretown : ternary;
      Wildell.Pinebluff : ternary;
      Wildell.Croghan : ternary;
      Wildell.Proctor : ternary;
      Wildell.Moorewood : ternary;
      Wildell.Shabbona : ternary;
   }
   actions {
      Sedona;
   }
   size : 512;
}
control ViewPark {
   apply( Hoagland );
}
@pragma ways 4
table Kinsey {
   reads {
      Wildell.Tofte : exact;
      Viroqua.Hilgard : exact;
      Viroqua.Nashoba : exact;
      Viroqua.Dushore : exact;
      Viroqua.Waretown : exact;
      Viroqua.Pinebluff : exact;
      Viroqua.Croghan : exact;
      Viroqua.Proctor : exact;
      Viroqua.Moorewood : exact;
      Viroqua.Shabbona : exact;
   }
   actions {
      Sedona;
   }
   size : 4096;
}
action Rosalie( Trilby, Waucousta, Hamden, Mellott, Keauhou, Pilger, Tatitlek, Sonestown, Tusculum ) {
   bit_and( Viroqua.Hilgard, Wildell.Hilgard, Trilby );
   bit_and( Viroqua.Nashoba, Wildell.Nashoba, Waucousta );
   bit_and( Viroqua.Dushore, Wildell.Dushore, Hamden );
   bit_and( Viroqua.Waretown, Wildell.Waretown, Mellott );
   bit_and( Viroqua.Pinebluff, Wildell.Pinebluff, Keauhou );
   bit_and( Viroqua.Croghan, Wildell.Croghan, Pilger );
   bit_and( Viroqua.Proctor, Wildell.Proctor, Tatitlek );
   bit_and( Viroqua.Moorewood, Wildell.Moorewood, Sonestown );
   bit_and( Viroqua.Shabbona, Wildell.Shabbona, Tusculum );
}
table Risco {
   reads {
      Wildell.Tofte : exact;
   }
   actions {
      Rosalie;
   }
   default_action : Rosalie(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control LaPuente {
   apply( Risco );
}
control Seattle {
   apply( Kinsey );
}
table Mulvane {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : ternary;
      Wildell.Nashoba : ternary;
      Wildell.Dushore : ternary;
      Wildell.Waretown : ternary;
      Wildell.Pinebluff : ternary;
      Wildell.Croghan : ternary;
      Wildell.Proctor : ternary;
      Wildell.Moorewood : ternary;
      Wildell.Shabbona : ternary;
   }
   actions {
      Sedona;
   }
   size : 512;
}
control Waukegan {
   apply( Mulvane );
}
@pragma ways 4
table Hannah {
   reads {
      Wildell.Tofte : exact;
      Viroqua.Hilgard : exact;
      Viroqua.Nashoba : exact;
      Viroqua.Dushore : exact;
      Viroqua.Waretown : exact;
      Viroqua.Pinebluff : exact;
      Viroqua.Croghan : exact;
      Viroqua.Proctor : exact;
      Viroqua.Moorewood : exact;
      Viroqua.Shabbona : exact;
   }
   actions {
      Sedona;
   }
   size : 4096;
}
action Ackerman( Anandale, Ruthsburg, Pound, Donnelly, Rippon, Uintah, Odell, Wabuska, Bannack ) {
   bit_and( Viroqua.Hilgard, Wildell.Hilgard, Anandale );
   bit_and( Viroqua.Nashoba, Wildell.Nashoba, Ruthsburg );
   bit_and( Viroqua.Dushore, Wildell.Dushore, Pound );
   bit_and( Viroqua.Waretown, Wildell.Waretown, Donnelly );
   bit_and( Viroqua.Pinebluff, Wildell.Pinebluff, Rippon );
   bit_and( Viroqua.Croghan, Wildell.Croghan, Uintah );
   bit_and( Viroqua.Proctor, Wildell.Proctor, Odell );
   bit_and( Viroqua.Moorewood, Wildell.Moorewood, Wabuska );
   bit_and( Viroqua.Shabbona, Wildell.Shabbona, Bannack );
}
table Warba {
   reads {
      Wildell.Tofte : exact;
   }
   actions {
      Ackerman;
   }
   default_action : Ackerman(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Reubens {
   apply( Warba );
}
control Neubert {
   apply( Hannah );
}
table Revere {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : ternary;
      Wildell.Nashoba : ternary;
      Wildell.Dushore : ternary;
      Wildell.Waretown : ternary;
      Wildell.Pinebluff : ternary;
      Wildell.Croghan : ternary;
      Wildell.Proctor : ternary;
      Wildell.Moorewood : ternary;
      Wildell.Shabbona : ternary;
   }
   actions {
      Sedona;
   }
   size : 512;
}
control Sawpit {
   apply( Revere );
}
@pragma ways 4
table Ivydale {
   reads {
      Wildell.Tofte : exact;
      Viroqua.Hilgard : exact;
      Viroqua.Nashoba : exact;
      Viroqua.Dushore : exact;
      Viroqua.Waretown : exact;
      Viroqua.Pinebluff : exact;
      Viroqua.Croghan : exact;
      Viroqua.Proctor : exact;
      Viroqua.Moorewood : exact;
      Viroqua.Shabbona : exact;
   }
   actions {
      Sedona;
   }
   size : 4096;
}
action Casper( Bothwell, Mackeys, Maloy, Sabetha, Hines, Cornudas, Coolin, Atlas, Minoa ) {
   bit_and( Viroqua.Hilgard, Wildell.Hilgard, Bothwell );
   bit_and( Viroqua.Nashoba, Wildell.Nashoba, Mackeys );
   bit_and( Viroqua.Dushore, Wildell.Dushore, Maloy );
   bit_and( Viroqua.Waretown, Wildell.Waretown, Sabetha );
   bit_and( Viroqua.Pinebluff, Wildell.Pinebluff, Hines );
   bit_and( Viroqua.Croghan, Wildell.Croghan, Cornudas );
   bit_and( Viroqua.Proctor, Wildell.Proctor, Coolin );
   bit_and( Viroqua.Moorewood, Wildell.Moorewood, Atlas );
   bit_and( Viroqua.Shabbona, Wildell.Shabbona, Minoa );
}
table Conover {
   reads {
      Wildell.Tofte : exact;
   }
   actions {
      Casper;
   }
   default_action : Casper(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Pringle {
   apply( Conover );
}
control Stockdale {
   apply( Ivydale );
}
table Pevely {
   reads {
      Wildell.Tofte : exact;
      Wildell.Hilgard : ternary;
      Wildell.Nashoba : ternary;
      Wildell.Dushore : ternary;
      Wildell.Waretown : ternary;
      Wildell.Pinebluff : ternary;
      Wildell.Croghan : ternary;
      Wildell.Proctor : ternary;
      Wildell.Moorewood : ternary;
      Wildell.Shabbona : ternary;
   }
   actions {
      Sedona;
   }
   size : 512;
}
control Christina {
   apply( Pevely );
}
action Niota( Wardville ) {
   modify_field( CoalCity.Redondo, Wardville );
   bit_or( Amory.Brush, Hershey.Swansboro, 0x80 );
}
action Patchogue( Lamar ) {
   modify_field( CoalCity.Redondo, Lamar );
   bit_or( Martelle.Hilbert, Hershey.Swansboro, 0x80 );
}
table Belpre {
   reads {
      Hershey.Swansboro mask 0x80 : exact;
      Amory.valid : exact;
      Martelle.valid : exact;
   }
   actions {
      Niota;
      Patchogue;
   }
   size : 8;
}
action Waialua() {
   modify_field( Amory.Brush, 0, 0x80 );
}
action Grigston() {
   modify_field( Martelle.Hilbert, 0, 0x80 );
}
table Higgston {
   reads {
     CoalCity.Redondo : exact;
     Amory.valid : exact;
     Martelle.valid : exact;
   }
   actions {
      Waialua;
      Grigston;
   }
   size : 8;
}
control ingress {
   Dorset();
   if( Scherr.Milesburg != 0 ) {
      Wellford();
   }
   Wyatte();
   if( Scherr.Milesburg != 0 ) {
      Ludowici();
      Gowanda();
   }
   Abernant();
   Baskin();
   Newhalen();
   Kaibab();
   Arapahoe();
   if( Scherr.Milesburg != 0 ) {
      Brodnax();
   }
   Blakeman();
   Kelsey();
   Frontier();
   Chicago();
   if( Scherr.Milesburg != 0 ) {
      Geneva();
   }
   Anahola();
   Adelino();
   Pierpont();
   Success();
   if( Scherr.Milesburg != 0 ) {
      Hemlock();
   } else {
      if( valid( Conneaut ) ) {
         Jesup();
      }
   }
   Lenox();
   Tuttle();
   if( CoalCity.Parrish != 2 ) {
      Cliffs();
   }
   Olcott();
   if( Scherr.Milesburg != 0 ) {
      Zarah();
   }
   Wauregan();
    Idalia();
   Craigmont();
   Bells();
   if( CoalCity.Murphy == 0 and CoalCity.Parrish != 2 ) {
      Bonduel();
      Archer();
   }
   if( Conneaut.valid == 0 ) {
      Heidrick();
   }
   Redvale();
   if( CoalCity.Parrish == 0 ) {
      apply(Belpre);
   }
   LaMonte();
   if( CoalCity.Murphy == 0 ) {
      Hettinger();
   }
   if ( CoalCity.Murphy == 0 ) {
      Cushing();
   }
   if( Scherr.Milesburg != 0 ) {
      Grapevine();
   }
   apply(Uniopolis);
   Burgdorf();
   if( CoalCity.Murphy == 0 ) {
      Assinippi();
   }
   Gunter();
   if( valid( Mission[0] ) ) {
      Keller();
   }
   Wattsburg();
}
control egress {
   Cornville();
   Hercules();
   Veradale();
   if( CoalCity.Parrish == 0 ) {
      apply( Higgston );
   }
   Lovilia();
   if( ( CoalCity.Skyforest == 0 ) and ( CoalCity.Parrish != 2 ) ) {
      Harney();
   }
   Habersham();
}
