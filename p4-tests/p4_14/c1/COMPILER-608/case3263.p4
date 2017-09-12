// BUILD: p4c-tofino --verbose 3 --placement tp4 --no-dead-code-elimination --o bf_arista_switch_baremetal_obfuscated/ --p4-name=arista_switch --p4-prefix=p4_arista_switch --pipe-mgr-path=pipe_mgr/ --mc-mgr-path=mc_mgr/ -S -DPROFILE_BAREMETAL --parser-timing-reports --print-pa-constraints bf_arista_switch_baremetal_obfuscated/Switch.OBFUSCATED.p4


// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 154726

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
header_type Klukwan {
	fields {
		Rawlins : 16;
		Parmelee : 16;
		Nipton : 8;
		Ilwaco : 8;
		Roswell : 8;
		Grassflat : 8;
		Richvale : 2;
		Bodcaw : 2;
		Oronogo : 1;
		Rainsburg : 3;
		Crossett : 3;
	}
}
header_type LeeCreek {
	fields {
		Sparr : 24;
		Conner : 24;
		Burgdorf : 24;
		Copemish : 24;
		Radom : 16;
		Lofgreen : 16;
		Boysen : 16;
		Cleta : 16;
		Funkley : 16;
		Revere : 8;
		Weches : 8;
		Lucas : 1;
		Mantee : 1;
		MoonRun : 3;
		Joplin : 2;
		Manville : 1;
		MiraLoma : 1;
		Cache : 1;
		Browning : 1;
		Stilson : 1;
		Haugen : 1;
		Pownal : 1;
		Umpire : 1;
		Kapowsin : 1;
		Colburn : 1;
		Luttrell : 1;
		Dalkeith : 1;
		Camino : 1;
		Lowden : 1;
		Mishawaka : 16;
		Yaurel : 16;
		Denning : 8;
	}
}
header_type Dovray {
	fields {
		Sidnaw : 24;
		Shopville : 24;
		Edinburg : 24;
		Mabelvale : 24;
		Penzance : 24;
		Kahului : 24;
		Larwill : 16;
		Choptank : 16;
		Jonesport : 16;
		Newellton : 16;
		Yreka : 12;
		Mabel : 1;
		Shevlin : 3;
		Monida : 1;
		Columbus : 3;
		Ferndale : 1;
		OjoFeliz : 1;
		Beresford : 1;
		Waukegan : 1;
		Brothers : 1;
		Kempton : 8;
		Tillson : 12;
		Korbel : 4;
		Wanamassa : 6;
	Seagate : 10;
#ifdef CASE_FIX
        Temple : 16;
#else
	Temple : 17;
#endif
		BigFork : 32;
		Slagle : 8;
		Lapel : 24;
		Anawalt : 24;
		Blackwood : 9;
		Cornville : 1;
		Baytown : 1;
		Eddystone : 1;
		Pickett : 1;
		Iredell : 1;
	}
}
header_type Aguada {
	fields {
		Barnard : 8;
		Vestaburg : 4;
		Dugger : 1;
	}
}
header_type Telida {
	fields {
		Bethesda : 32;
		Gibsland : 32;
		Yorkshire : 6;
		KentPark : 16;
	}
}
header_type Brewerton {
	fields {
		Kewanee : 128;
		Charco : 128;
		Rockvale : 20;
		Arnett : 8;
		Guayabal : 11;
		Keener : 6;
		Webbville : 13;
	}
}
header_type Shelbiana {
	fields {
		Hematite : 14;
		BigLake : 1;
		Tigard : 12;
		Pittwood : 1;
		Nixon : 1;
		Separ : 2;
		Rohwer : 6;
		EastDuke : 3;
	}
}
header_type Earling {
	fields {
		Grigston : 1;
		Claypool : 1;
	}
}
header_type Chilson {
	fields {
		Goodyear : 8;
	}
}
header_type Pecos {
	fields {
		Ruffin : 16;
		Millett : 11;
	}
}
header_type DeKalb {
	fields {
		BigPark : 32;
		Archer : 32;
		Odessa : 32;
	}
}
header_type Oskawalik {
	fields {
		Swain : 32;
		Mineral : 32;
	}
}
header_type Emory {
	fields {
		Novice : 1;
		Selah : 1;
		Cuney : 1;
		Easley : 3;
		Willamina : 1;
		Lakebay : 6;
		Wetonka : 4;
		Candle : 12;
		Lanesboro : 1;
	}
}
header_type TiePlant {
	fields {
		Pueblo : 16;
	}
}
header_type Starkey {
	fields {
		Tiburon : 14;
		Rhodell : 1;
		Wilson : 1;
	}
}
header_type Wegdahl {
	fields {
		Arion : 14;
		Glendevey : 1;
		Turney : 1;
	}
}
header_type Pilar {
	fields {
		Victoria : 16;
		Cutler : 16;
		Volens : 16;
		Gullett : 16;
		NorthRim : 8;
		Harriet : 8;
		Twodot : 8;
		Ridgeview : 8;
		Chamois : 1;
		Strasburg : 6;
	}
}
header_type IttaBena {
	fields {
		Notus : 32;
	}
}
header_type Tamms {
	fields {
		Arvana : 6;
		Linville : 10;
		Glenside : 4;
		Temelec : 12;
		Kingsdale : 12;
		Counce : 2;
		Nursery : 2;
		Ohiowa : 8;
		Willmar : 3;
		DesPeres : 5;
	}
}
header_type Jermyn {
	fields {
		Wolcott : 24;
		Glouster : 24;
		Farner : 24;
		Lapoint : 24;
		WoodDale : 16;
	}
}
header_type Bellport {
	fields {
		Brainard : 3;
		DelMar : 1;
		DelRey : 12;
		Blitchton : 16;
	}
}
header_type Edwards {
	fields {
		Eunice : 4;
		Yatesboro : 4;
		Philmont : 6;
		Vinita : 2;
		Hillside : 16;
		Wyarno : 16;
		Goosport : 3;
		Currie : 13;
		Stambaugh : 8;
		Ceiba : 8;
		Gunder : 16;
		Rochert : 32;
		Milbank : 32;
	}
}
header_type Roseau {
	fields {
		Brentford : 4;
		Swedeborg : 6;
		Burrton : 2;
		Wesson : 20;
		Pembine : 16;
		Clementon : 8;
		Cistern : 8;
		Murchison : 128;
		OakLevel : 128;
	}
}
header_type Loughman {
	fields {
		Salduro : 8;
		Walland : 8;
		Moylan : 16;
	}
}
header_type Wheeling {
	fields {
		Ivins : 16;
		Morgana : 16;
	}
}
header_type Fireco {
	fields {
		Paxson : 32;
		Winger : 32;
		Castle : 4;
		Hopeton : 4;
		Springlee : 8;
		Chatfield : 16;
		Kinter : 16;
		Folcroft : 16;
	}
}
header_type AukeBay {
	fields {
		Norcatur : 16;
		Norias : 16;
	}
}
header_type Robstown {
	fields {
		SanPablo : 16;
		Elburn : 16;
		Oilmont : 8;
		Delmar : 8;
		Cardenas : 16;
	}
}
header_type Mekoryuk {
	fields {
		Tonasket : 48;
		Garwood : 32;
		Meservey : 48;
		Leadpoint : 32;
	}
}
header_type Compton {
	fields {
		Hershey : 1;
		Hermiston : 1;
		Fentress : 1;
		Grinnell : 1;
		Arriba : 1;
		WarEagle : 3;
		Helton : 5;
		Francisco : 3;
		Lolita : 16;
	}
}
header_type Elkton {
	fields {
		Avondale : 24;
		Astatula : 8;
	}
}
header_type Swansboro {
	fields {
		Rotan : 8;
		Suring : 24;
		Langtry : 24;
		Theta : 8;
	}
}
header Jermyn Frontenac;
header Jermyn Domestic;
header Bellport Hobucken[ 2 ];
@pragma pa_fragment ingress Newcomb.Gunder
@pragma pa_fragment egress Newcomb.Gunder
header Edwards Newcomb;
@pragma pa_fragment ingress Caspian.Gunder
@pragma pa_fragment egress Caspian.Gunder
header Edwards Caspian;
header Roseau Dunkerton;
header Roseau Vacherie;
header Wheeling Saxis;
header Wheeling Kerrville;
header Fireco Longmont;
header AukeBay Janney;
header Fireco Gerlach;
header AukeBay Coachella;
header Swansboro Hobson;
header Compton Lennep;
header Tamms Perrine;
header Jermyn Skillman;
parser start {
   return select(current(96, 16)) {
      0xBF00 : Flats;
      default : Wheeler;
   }
}
parser Broadmoor {
   extract( Perrine );
   return Wheeler;
}
parser Flats {
   extract( Skillman );
   return Broadmoor;
}
parser Wheeler {
   extract( Frontenac );
   return select( Frontenac.WoodDale ) {
      0x8100 : Parker;
      0x0800 : CassCity;
      0x86dd : Schofield;
      default : ingress;
   }
}
parser Parker {
   extract( Hobucken[0] );
   set_metadata(Newcastle.Oronogo, 1);
   return select( Hobucken[0].Blitchton ) {
      0x0800 : CassCity;
      0x86dd : Schofield;
      default : ingress;
   }
}
field_list Monmouth {
    Newcomb.Eunice;
    Newcomb.Yatesboro;
    Newcomb.Philmont;
    Newcomb.Vinita;
    Newcomb.Hillside;
    Newcomb.Wyarno;
    Newcomb.Goosport;
    Newcomb.Currie;
    Newcomb.Stambaugh;
    Newcomb.Ceiba;
    Newcomb.Rochert;
    Newcomb.Milbank;
}
field_list_calculation McAlister {
    input {
        Monmouth;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Newcomb.Gunder {
    verify McAlister;
    update McAlister;
}
parser CassCity {
   extract( Newcomb );
   set_metadata(Newcastle.Nipton, Newcomb.Ceiba);
   set_metadata(Newcastle.Roswell, Newcomb.Stambaugh);
   set_metadata(Newcastle.Richvale, 1);
   return select(Newcomb.Currie, Newcomb.Yatesboro, Newcomb.Ceiba) {
      0x501 : Ancho;
      0x511 : Realitos;
      0x506 : Gregory;
      0 mask 0xFF7000 : ingress;
      0x506 mask 0xfff: Tannehill;
      default : Yantis;
   }
}
parser Tannehill {
   set_metadata(Newcastle.Crossett, 5);
   return ingress;
}
parser Yantis {
   set_metadata(Newcastle.Crossett, 1);
   return ingress;
}
parser Schofield {
   extract( Vacherie );
   set_metadata(Newcastle.Nipton, Vacherie.Clementon);
   set_metadata(Newcastle.Roswell, Vacherie.Cistern);
   set_metadata(Newcastle.Richvale, 2);
   return select(Vacherie.Clementon) {
      0x3a : Ancho;
      17 : PaloAlto;
      6 : Gregory;
      default : ingress;
   }
}
parser Realitos {
   set_metadata(Newcastle.Crossett, 2);
   extract(Saxis);
   extract(Janney);
   return select(Saxis.Morgana) {
      4789 : Rosario;
      default : ingress;
    }
}
parser Ancho {
   set_metadata( Saxis.Ivins, current( 0, 16 ) );
   return ingress;
}
parser PaloAlto {
   set_metadata(Newcastle.Crossett, 2);
   extract(Saxis);
   extract(Janney);
   return ingress;
}
parser Gregory {
   set_metadata(Newcastle.Crossett, 6);
   extract(Saxis);
   extract(Longmont);
   return ingress;
}
parser Fairlee {
   set_metadata(Tingley.Joplin, 2);
   return Luning;
}
parser Placedo {
   set_metadata(Tingley.Joplin, 2);
   return Corbin;
}
parser Bratenahl {
   extract(Lennep);
   return select(Lennep.Hershey, Lennep.Hermiston, Lennep.Fentress, Lennep.Grinnell, Lennep.Arriba,
             Lennep.WarEagle, Lennep.Helton, Lennep.Francisco, Lennep.Lolita) {
      0x0800 : Fairlee;
      0x86dd : Placedo;
      default : ingress;
   }
}
parser Rosario {
   extract(Hobson);
   set_metadata(Tingley.Joplin, 1);
   return Ashville;
}
field_list Moclips {
    Caspian.Eunice;
    Caspian.Yatesboro;
    Caspian.Philmont;
    Caspian.Vinita;
    Caspian.Hillside;
    Caspian.Wyarno;
    Caspian.Goosport;
    Caspian.Currie;
    Caspian.Stambaugh;
    Caspian.Ceiba;
    Caspian.Rochert;
    Caspian.Milbank;
}
field_list_calculation Callimont {
    input {
        Moclips;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Caspian.Gunder {
    verify Callimont;
    update Callimont;
}
parser Luning {
   extract( Caspian );
   set_metadata(Newcastle.Ilwaco, Caspian.Ceiba);
   set_metadata(Newcastle.Grassflat, Caspian.Stambaugh);
   set_metadata(Newcastle.Bodcaw, 1);
   set_metadata(Luzerne.Bethesda, Caspian.Rochert);
   set_metadata(Luzerne.Gibsland, Caspian.Milbank);
   return select(Caspian.Currie, Caspian.Yatesboro, Caspian.Ceiba) {
      0x501 : Sunset;
      0x511 : Ronneby;
      0x506 : Jelloway;
      0 mask 0xFF7000 : ingress;
      0x506 mask 0xfff: Advance;
      default : Elsey;
   }
}
parser Advance {
   set_metadata(Newcastle.Rainsburg, 5);
   return ingress;
}
parser Elsey {
   set_metadata(Newcastle.Rainsburg, 1);
   return ingress;
}
parser Corbin {
   extract( Dunkerton );
   set_metadata(Newcastle.Ilwaco, Dunkerton.Clementon);
   set_metadata(Newcastle.Grassflat, Dunkerton.Cistern);
   set_metadata(Newcastle.Parmelee, Dunkerton.Pembine);
   set_metadata(Newcastle.Bodcaw, 2);
   set_metadata(Ringwood.Kewanee, Dunkerton.Murchison);
   set_metadata(Ringwood.Charco, Dunkerton.OakLevel);
   return select(Dunkerton.Clementon) {
      0x3a : Sunset;
      17 : Ronneby;
      6 : Jelloway;
      default : ingress;
   }
}
parser Sunset {
   set_metadata( Tingley.Mishawaka, current( 0, 16 ) );
   return ingress;
}
parser Ronneby {
   set_metadata( Tingley.Mishawaka, current( 0, 16 ) );
   set_metadata( Tingley.Yaurel, current( 16, 16 ) );
   set_metadata(Newcastle.Rainsburg, 2);
   return ingress;
}
parser Jelloway {
   set_metadata( Tingley.Mishawaka, current( 0, 16 ) );
   set_metadata( Tingley.Yaurel, current( 16, 16 ) );
   set_metadata( Tingley.Denning, current( 104, 8 ) );
   set_metadata(Newcastle.Rainsburg, 6);
   extract(Kerrville);
   extract(Gerlach);
   return ingress;
}
parser Ashville {
   extract( Domestic );
   set_metadata( Tingley.Sparr, Domestic.Wolcott );
   set_metadata( Tingley.Conner, Domestic.Glouster );
   set_metadata( Tingley.Radom, Domestic.WoodDale );
   return select( Domestic.WoodDale ) {
      0x0800: Luning;
      0x86dd: Corbin;
      default: ingress;
   }
}
@pragma pa_no_init ingress Tingley.Sparr
@pragma pa_no_init ingress Tingley.Conner
@pragma pa_no_init ingress Tingley.Burgdorf
@pragma pa_no_init ingress Tingley.Copemish
metadata LeeCreek Tingley;
@pragma pa_no_init ingress Ranburne.Sidnaw
@pragma pa_no_init ingress Ranburne.Shopville
@pragma pa_no_init ingress Ranburne.Edinburg
@pragma pa_no_init ingress Ranburne.Mabelvale
metadata Dovray Ranburne;
metadata Shelbiana Flasher;
metadata Klukwan Newcastle;
metadata Telida Luzerne;
metadata Brewerton Ringwood;
metadata Earling Harshaw;
@pragma pa_container_size ingress Harshaw.Claypool 32
metadata Aguada Mystic;
metadata Chilson Lorane;
metadata Pecos Ballwin;
metadata Oskawalik Laneburg;
metadata DeKalb Perma;
metadata Emory Kinross;
metadata TiePlant Narka;
@pragma pa_no_init ingress Amity.Tiburon
@pragma pa_solitary ingress Amity.Wilson
metadata Starkey Amity;
@pragma pa_no_init ingress Virginia.Arion
metadata Wegdahl Virginia;
metadata Pilar Ruthsburg;
metadata Pilar Auburn;
action Nanson() {
   no_op();
}
action Rotterdam() {
   modify_field(Tingley.Cache, 1 );
   mark_for_drop();
}
action Berea() {
   no_op();
}
action Ingleside(Converse, Murdock, Phelps, Habersham, Kirley,
                 Naalehu, SaintAnn, Beaufort) {
    modify_field(Flasher.Hematite, Converse);
    modify_field(Flasher.BigLake, Murdock);
    modify_field(Flasher.Tigard, Phelps);
    modify_field(Flasher.Pittwood, Habersham);
    modify_field(Flasher.Nixon, Kirley);
    modify_field(Flasher.Separ, Naalehu);
    modify_field(Flasher.EastDuke, SaintAnn);
    modify_field(Flasher.Rohwer, Beaufort);
}

@pragma command_line --no-dead-code-elimination
table Paradise {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Ingleside;
    }
    size : 288;
}
control Tontogany {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Paradise);
    }
}
action Lemont(Westvaco, Hokah) {
   modify_field( Ranburne.Monida, 1 );
   modify_field( Ranburne.Kempton, Westvaco);
   modify_field( Tingley.Kapowsin, 1 );
   modify_field( Kinross.Cuney, Hokah );
}
action Emajagua() {
   modify_field( Tingley.Haugen, 1 );
   modify_field( Tingley.Luttrell, 1 );
}
action Roseville() {
   modify_field( Tingley.Kapowsin, 1 );
}
action Masontown() {
   modify_field( Tingley.Kapowsin, 1 );
   modify_field( Tingley.Dalkeith, 1 );
}
action Dagsboro() {
   modify_field( Tingley.Colburn, 1 );
}
action Gordon() {
   modify_field( Tingley.Luttrell, 1 );
}
counter Kaplan {
   type : packets_and_bytes;
   direct : DimeBox;
   min_width: 16;
}
table DimeBox {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Frontenac.Wolcott : ternary;
      Frontenac.Glouster : ternary;
   }
   actions {
      Lemont;
      Emajagua;
      Roseville;
      Dagsboro;
      Gordon;
      Masontown;
   }
   size : 1024;
}
action Hoadly() {
   modify_field( Tingley.Pownal, 1 );
}
table Rockport {
   reads {
      Frontenac.Farner : ternary;
      Frontenac.Lapoint : ternary;
   }
   actions {
      Hoadly;
   }
   size : 512;
}
control Drifton {
   apply( DimeBox );
   apply( Rockport );
}
action Cascadia() {
   modify_field( Luzerne.Yorkshire, Caspian.Philmont );
   modify_field( Ringwood.Rockvale, Dunkerton.Wesson );
   modify_field( Ringwood.Keener, Dunkerton.Swedeborg );
   modify_field( Tingley.Burgdorf, Domestic.Farner );
   modify_field( Tingley.Copemish, Domestic.Lapoint );
   modify_field( Tingley.Funkley, Newcastle.Parmelee );
   modify_field( Tingley.Revere, Newcastle.Ilwaco );
   modify_field( Tingley.Weches, Newcastle.Grassflat );
   modify_field( Tingley.Mantee, Newcastle.Bodcaw, 1 );
   shift_right( Tingley.Lucas, Newcastle.Bodcaw, 1 );
   modify_field( Tingley.Camino, 0 );
   modify_field( Ranburne.Columbus, 1 );
   modify_field( Flasher.Separ, 1 );
   modify_field( Flasher.EastDuke, 0 );
   modify_field( Flasher.Rohwer, 0 );
   modify_field( Kinross.Novice, 1 );
   modify_field( Kinross.Selah, 1 );
   modify_field( Ruthsburg.Volens, Tingley.Mishawaka );
   modify_field( Tingley.MoonRun, Newcastle.Rainsburg );
   modify_field( Ruthsburg.Chamois, Newcastle.Rainsburg, 1);
}
action Emblem() {
   modify_field( Tingley.Joplin, 0 );
   modify_field( Luzerne.Bethesda, Newcomb.Rochert );
   modify_field( Luzerne.Gibsland, Newcomb.Milbank );
   modify_field( Luzerne.Yorkshire, Newcomb.Philmont );
   modify_field( Ringwood.Kewanee, Vacherie.Murchison );
   modify_field( Ringwood.Charco, Vacherie.OakLevel );
   modify_field( Ringwood.Rockvale, Vacherie.Wesson );
   modify_field( Ringwood.Keener, Vacherie.Swedeborg );
   modify_field( Tingley.Sparr, Frontenac.Wolcott );
   modify_field( Tingley.Conner, Frontenac.Glouster );
   modify_field( Tingley.Burgdorf, Frontenac.Farner );
   modify_field( Tingley.Copemish, Frontenac.Lapoint );
   modify_field( Tingley.Radom, Frontenac.WoodDale );
   modify_field( Tingley.Revere, Newcastle.Nipton );
   modify_field( Tingley.Weches, Newcastle.Roswell );
   modify_field( Tingley.Mantee, Newcastle.Richvale, 1 );
   shift_right( Tingley.Lucas, Newcastle.Richvale, 1 );
   modify_field( Kinross.Willamina, Hobucken[0].DelMar );
   modify_field( Tingley.Camino, Newcastle.Oronogo );
   modify_field( Ruthsburg.Volens, Saxis.Ivins );
   modify_field( Tingley.Mishawaka, Saxis.Ivins );
   modify_field( Tingley.Yaurel, Saxis.Morgana );
   modify_field( Tingley.Denning, Longmont.Springlee );
   modify_field( Tingley.MoonRun, Newcastle.Crossett );
   modify_field( Ruthsburg.Chamois, Newcastle.Crossett, 1);
}
table Purdon {
   reads {
      Frontenac.Wolcott : exact;
      Frontenac.Glouster : exact;
      Newcomb.Milbank : exact;
      Tingley.Joplin : exact;
   }
   actions {
      Cascadia;
      Emblem;
   }
   default_action : Emblem();
   size : 1024;
}
action Grenville() {
   modify_field( Tingley.Lofgreen, Flasher.Tigard );
   modify_field( Tingley.Boysen, Flasher.Hematite);
}
action Lemhi( Jefferson ) {
   modify_field( Tingley.Lofgreen, Jefferson );
   modify_field( Tingley.Boysen, Flasher.Hematite);
}
action Couchwood() {
   modify_field( Tingley.Lofgreen, Hobucken[0].DelRey );
   modify_field( Tingley.Boysen, Flasher.Hematite);
}
table Gustine {
   reads {
      Flasher.Hematite : ternary;
      Hobucken[0] : valid;
      Hobucken[0].DelRey : ternary;
   }
   actions {
      Grenville;
      Lemhi;
      Couchwood;
   }
   size : 4096;
}
action Dietrich( Nondalton ) {
   modify_field( Tingley.Boysen, Nondalton );
}
action MudButte() {
   modify_field( Lorane.Goodyear,
                 2 );
}
table Dunnegan {
   reads {
      Newcomb.Rochert : exact;
   }
   actions {
      Dietrich;
      MudButte;
   }
   default_action : MudButte;
   size : 4096;
}
action Globe( Lovelady, Algoa, Pinto, Milano ) {
   modify_field( Tingley.Lofgreen, Lovelady );
   modify_field( Tingley.Cleta, Lovelady );
   modify_field( Tingley.Stilson, Milano );
   Brule(Algoa, Pinto);
}
action Somis() {
   modify_field( Tingley.Browning, 1 );
}
table Wilmore {
   reads {
      Hobson.Langtry : exact;
   }
   actions {
      Globe;
      Somis;
   }
   size : 4096;
}
action Brule(Steprock, Barstow) {
   modify_field( Mystic.Barnard, Steprock );
   modify_field( Mystic.Vestaburg, Barstow );
}
action Elbing(Beatrice, Sanatoga) {
   modify_field( Tingley.Cleta, Flasher.Tigard );
   Brule(Beatrice, Sanatoga);
}
action PeaRidge(Maupin, Woodlake, Belvidere) {
   modify_field( Tingley.Cleta, Maupin );
   Brule(Woodlake, Belvidere);
}
action Piney(Yardville, Adair) {
   modify_field( Tingley.Cleta, Hobucken[0].DelRey );
   Brule(Yardville, Adair);
}
@pragma ternary 1
table Moweaqua {
   reads {
      Flasher.Tigard : exact;
   }
   actions {
      Nanson;
      Elbing;
   }
   size : 512;
}
@pragma action_default_only Nanson
table Domingo {
   reads {
      Flasher.Hematite : exact;
      Hobucken[0].DelRey : exact;
   }
   actions {
      PeaRidge;
      Nanson;
   }
   size : 1024;
}
table Evelyn {
   reads {
      Hobucken[0].DelRey : exact;
   }
   actions {
      Nanson;
      Piney;
   }
   size : 4096;
}
control Stoystown {
   apply( Purdon ) {
         Cascadia {
            apply( Dunnegan );
            apply( Wilmore );
         }
         Emblem {
            if ( not valid(Perrine) and Flasher.Pittwood == 1 ) {
               apply( Gustine );
            }
            if ( valid( Hobucken[0] ) and Hobucken[0].DelRey != 0 ) {
               apply( Domingo ) {
                  Nanson {
                     apply( Evelyn );
                  }
               }
            } else {
               apply( Moweaqua );
            }
         }
   }
}
register Pathfork {
    width : 1;
    static : Coupland;
    instance_count : 294912;
}
register Kapaa {
    width : 1;
    static : Summit;
    instance_count : 294912;
}
blackbox stateful_alu Union {
    reg : Pathfork;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : Harshaw.Grigston;
}
blackbox stateful_alu Booth {
    reg : Kapaa;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst : Harshaw.Claypool;
}
field_list Osseo {
    ig_intr_md.ingress_port;
    Hobucken[0].DelRey;
}
field_list_calculation Ladelle {
    input { Osseo; }
    algorithm: identity;
    output_width: 19;
}
action Ivyland() {
    Union.execute_stateful_alu_from_hash(Ladelle);
}
action Verdery() {
    Booth.execute_stateful_alu_from_hash(Ladelle);
}
table Coupland {
    actions {
      Ivyland;
    }
    default_action : Ivyland;
    size : 1;
}
table Summit {
    actions {
      Verdery;
    }
    default_action : Verdery;
    size : 1;
}
action Palmdale(Pocopson) {
    modify_field(Harshaw.Claypool, Pocopson);
}
@pragma ternary 1
table Stamford {
    reads {
       ig_intr_md.ingress_port mask 0x7f : exact;
    }
    actions {
      Palmdale;
    }
    size : 72;
}
control Bogota {
   if ( valid( Hobucken[ 0 ] ) and Hobucken[0].DelRey != 0 ) {
      if( Flasher.Nixon == 1 ) {
         apply( Coupland );
         apply( Summit );
      }
   } else {
      if( Flasher.Nixon == 1 ) {
         apply( Stamford );
      }
   }
}
field_list Donner {
   Frontenac.Wolcott;
   Frontenac.Glouster;
   Frontenac.Farner;
   Frontenac.Lapoint;
   Frontenac.WoodDale;
}
field_list Dolliver {
   Newcomb.Ceiba;
   Newcomb.Rochert;
   Newcomb.Milbank;
}
field_list Highcliff {
   Vacherie.Murchison;
   Vacherie.OakLevel;
   Vacherie.Wesson;
   Vacherie.Clementon;
}
field_list Hartfield {
   Newcomb.Rochert;
   Newcomb.Milbank;
   Saxis.Ivins;
   Saxis.Morgana;
}
field_list_calculation Ashtola {
    input {
        Donner;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Fowlkes {
    input {
        Dolliver;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Lefors {
    input {
        Highcliff;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Midville {
    input {
        Hartfield;
    }
    algorithm : crc32;
    output_width : 32;
}
action ShadeGap() {
    modify_field_with_hash_based_offset(Perma.BigPark, 0,
                                        Ashtola, 4294967296);
}
action Sallisaw() {
    modify_field_with_hash_based_offset(Perma.Archer, 0,
                                        Fowlkes, 4294967296);
}
action Jacobs() {
    modify_field_with_hash_based_offset(Perma.Archer, 0,
                                        Lefors, 4294967296);
}
action Farson() {
    modify_field_with_hash_based_offset(Perma.Odessa, 0,
                                        Midville, 4294967296);
}
table Marbleton {
   actions {
      ShadeGap;
   }
   size: 1;
}
control Amesville {
   apply(Marbleton);
}
table Fairchild {
   actions {
      Sallisaw;
   }
   size: 1;
}
table Faith {
   actions {
      Jacobs;
   }
   size: 1;
}
control Sidon {
   if ( valid( Newcomb ) ) {
      apply(Fairchild);
   } else {
      if ( valid( Vacherie ) ) {
         apply(Faith);
      }
   }
}
table Annetta {
   actions {
      Farson;
   }
   size: 1;
}
control Simla {
   if ( valid( Janney ) ) {
      apply(Annetta);
   }
}
action Daguao() {
    modify_field(Laneburg.Swain, Perma.BigPark);
}
action Omemee() {
    modify_field(Laneburg.Swain, Perma.Archer);
}
action Coconino() {
    modify_field(Laneburg.Swain, Perma.Odessa);
}
@pragma action_default_only Nanson
@pragma immediate 0
table Nashwauk {
   reads {
      Gerlach.valid : ternary;
      Coachella.valid : ternary;
      Caspian.valid : ternary;
      Dunkerton.valid : ternary;
      Domestic.valid : ternary;
      Longmont.valid : ternary;
      Janney.valid : ternary;
      Newcomb.valid : ternary;
      Vacherie.valid : ternary;
      Frontenac.valid : ternary;
   }
   actions {
      Daguao;
      Omemee;
      Coconino;
      Nanson;
   }
   size: 256;
}
action Bettles() {
    modify_field(Laneburg.Mineral, Perma.Odessa);
}
@pragma immediate 0
table Pendleton {
   reads {
      Gerlach.valid : ternary;
      Coachella.valid : ternary;
      Longmont.valid : ternary;
      Janney.valid : ternary;
   }
   actions {
      Bettles;
      Nanson;
   }
   size: 6;
}
control Nashua {
   apply(Pendleton);
   apply(Nashwauk);
}
counter Yorkville {
   type : packets_and_bytes;
   direct : Buncombe;
   min_width: 16;
}
table Buncombe {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Harshaw.Claypool : ternary;
      Harshaw.Grigston : ternary;
      Tingley.Browning : ternary;
      Tingley.Pownal : ternary;
      Tingley.Haugen : ternary;
   }
   actions {
      Rotterdam;
      Nanson;
   }
   default_action : Nanson();
   size : 512;
}
table Haugan {
   reads {
      Tingley.Burgdorf : exact;
      Tingley.Copemish : exact;
      Tingley.Lofgreen : exact;
   }
   actions {
      Rotterdam;
      Nanson;
   }
   default_action : Nanson();
   size : 4096;
}
action Ramhurst() {
   modify_field(Lorane.Goodyear,
                1);
}
table Worthing {
   reads {
      Tingley.Burgdorf : exact;
      Tingley.Copemish : exact;
      Tingley.Lofgreen : exact;
      Tingley.Boysen : exact;
   }
   actions {
      Berea;
      Ramhurst;
   }
   default_action : Ramhurst();
   size : 65536;
   support_timeout : true;
}
action NewAlbin( Genola, Culloden ) {
   modify_field( Tingley.Lowden, Genola );
   modify_field( Tingley.Stilson, Culloden );
}
action Corydon() {
   modify_field( Tingley.Stilson, 1 );
}
table Courtdale {
   reads {
      Tingley.Lofgreen mask 0xfff : exact;
   }
   actions {
      NewAlbin;
      Corydon;
      Nanson;
   }
   default_action : Nanson();
   size : 4096;
}
action Galloway() {
   modify_field( Mystic.Dugger, 1 );
}
table Chambers {
   reads {
      Tingley.Cleta : ternary;
      Tingley.Sparr : exact;
      Tingley.Conner : exact;
   }
   actions {
      Galloway;
   }
   size: 512;
}
control Wyanet {
   apply( Buncombe ) {
      Nanson {
         apply( Haugan ) {
            Nanson {
               if (Flasher.BigLake == 0 and Tingley.MiraLoma == 0) {
                  apply( Worthing );
               }
               apply( Courtdale );
               apply(Chambers);
            }
         }
      }
   }
}
field_list Protem {
    Lorane.Goodyear;
    Tingley.Burgdorf;
    Tingley.Copemish;
    Tingley.Lofgreen;
    Tingley.Boysen;
}
action Gilman() {
   generate_digest(0, Protem);
}
table Logandale {
   actions {
      Gilman;
   }
   size : 1;
}
control Hamel {
   if (Lorane.Goodyear == 1) {
      apply( Logandale );
   }
}
action Woodston() {
}
action Heizer( Keenes ) {
   modify_field( Luzerne.Gibsland, Keenes );
}
table Isleta {
   reads {
      Tingley.Cleta : exact;
      Luzerne.Bethesda : ternary;
      Luzerne.Gibsland : ternary;
   }
   actions {
      Woodston;
   }
   size : 2048;
}
table Grasmere {
   reads {
      Luzerne.Gibsland : exact;
      Tingley.Cleta : exact;
   }
   actions {
      Heizer;
   }
   size : 16384;
}
control Sequim {
   apply( Isleta ) {
      Woodston {
         apply( Grasmere );
      }
   }
}
action McCaulley( Moorcroft, Rives ) {
   modify_field( Ringwood.Webbville, Moorcroft );
   modify_field( Ballwin.Ruffin, Rives );
}
action Granbury( Monrovia, Callao ) {
   modify_field( Ringwood.Webbville, Monrovia );
   modify_field( Ballwin.Millett, Callao );
}
@pragma action_default_only Loysburg
table Paullina {
   reads {
      Mystic.Barnard : exact;
      Ringwood.Charco mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      McCaulley;
      Loysburg;
      Granbury;
   }
   size : 2048;
}
@pragma atcam_partition_index Ringwood.Webbville
@pragma atcam_number_partitions 2048
table Broadford {
   reads {
      Ringwood.Webbville : exact;
      Ringwood.Charco mask 0x000007FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Veradale;
      Hanapepe;
      Nanson;
   }
   default_action : Nanson();
   size : 16384;
}
action Harriston( Reagan, Belpre ) {
   modify_field( Ringwood.Guayabal, Reagan );
   modify_field( Ballwin.Ruffin, Belpre );
}
action Weatherby( Southam, BlueAsh ) {
   modify_field( Ringwood.Guayabal, Southam );
   modify_field( Ballwin.Millett, BlueAsh );
}
@pragma action_default_only Nanson
table Montalba {
   reads {
      Mystic.Barnard : exact;
      Ringwood.Charco : lpm;
   }
   actions {
      Harriston;
      Weatherby;
      Nanson;
   }
   size : 1024;
}
@pragma atcam_partition_index Ringwood.Guayabal
@pragma atcam_number_partitions 1024
table Willows {
   reads {
      Ringwood.Guayabal : exact;
      Ringwood.Charco mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Veradale;
      Hanapepe;
      Nanson;
   }
   default_action : Nanson();
   size : 8192;
}
@pragma action_default_only Loysburg
@pragma idletime_precision 1
table Shelbina {
   reads {
      Mystic.Barnard : exact;
      Luzerne.Gibsland : lpm;
   }
   actions {
      Veradale;
      Hanapepe;
      Loysburg;
   }
   size : 1024;
   support_timeout : true;
}
action Altadena( Parkville, Shabbona ) {
   modify_field( Luzerne.KentPark, Parkville );
   modify_field( Ballwin.Ruffin, Shabbona );
}
action Dizney( Joshua, Gibbs ) {
   modify_field( Luzerne.KentPark, Joshua );
   modify_field( Ballwin.Millett, Gibbs );
}
@pragma action_default_only Nanson
table Barksdale {
   reads {
      Mystic.Barnard : exact;
      Luzerne.Gibsland : lpm;
   }
   actions {
      Altadena;
      Dizney;
      Nanson;
   }
   size : 16384;
}
@pragma ways 2
@pragma atcam_partition_index Luzerne.KentPark
@pragma atcam_number_partitions 16384
table Herring {
   reads {
      Luzerne.KentPark : exact;
      Luzerne.Gibsland mask 0x000fffff : lpm;
   }
   actions {
      Veradale;
      Hanapepe;
      Nanson;
   }
   default_action : Nanson();
   size : 131072;
}
action Veradale( ElmCity ) {
   modify_field( Ballwin.Ruffin, ElmCity );
}
@pragma idletime_precision 1
table Jericho {
   reads {
      Mystic.Barnard : exact;
      Luzerne.Gibsland : exact;
   }
   actions {
      Veradale;
      Hanapepe;
      Nanson;
   }
   default_action : Nanson();
   size : 65536;
   support_timeout : true;
}
@pragma idletime_precision 1
table Elmwood {
   reads {
      Mystic.Barnard : exact;
      Ringwood.Charco : exact;
   }
   actions {
      Veradale;
      Hanapepe;
      Nanson;
   }
   default_action : Nanson();
   size : 16384;
   support_timeout : true;
}
action Skyline(Antlers, Taylors, Traverse) {
   modify_field(Ranburne.Larwill, Traverse);
   modify_field(Ranburne.Sidnaw, Antlers);
   modify_field(Ranburne.Shopville, Taylors);
   modify_field(Ranburne.Cornville, 1);
   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}
action Bruce() {
   Rotterdam();
}
action Wayland(SnowLake) {
   modify_field(Ranburne.Monida, 1);
   modify_field(Ranburne.Kempton, SnowLake);
}
action Loysburg(CruzBay) {
   modify_field(Ballwin.Ruffin, CruzBay);
}
table Quarry {
   reads {
      Ballwin.Ruffin : exact;
   }
   actions {
      Skyline;
      Bruce;
      Wayland;
   }
   size : 65536;
}
action Steger(Bomarton) {
   modify_field(Ballwin.Ruffin, Bomarton);
}
table TroutRun {
   actions {
      Steger;
   }
   default_action: Steger;
   size : 1;
}
control Edroy {
   if ( ( ( Mystic.Vestaburg & ( 0x2 ) ) == ( ( 0x2 ) ) ) and ( Tingley.Lucas == 1 ) ) {
      if ( Tingley.Cache == 0 and Mystic.Dugger == 1 ) {
         apply( Elmwood ) {
            Nanson {
               apply( Montalba );
            }
         }
      }
   } else if ( ( ( Mystic.Vestaburg & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Tingley.Mantee == 1 ) ) {
      if ( Tingley.Cache == 0 ) {
        Sequim();
         if ( Mystic.Dugger == 1 ) {
            apply( Jericho ) {
               Nanson {
                  apply(Barksdale);
               }
            }
         }
      }
  }
}
control Dominguez {
   if ( Tingley.Cache == 0 and Mystic.Dugger == 1 ) {
      if ( ( ( Mystic.Vestaburg & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Tingley.Mantee == 1 ) ) {
         if ( Luzerne.KentPark != 0 ) {
            apply( Herring );
         } else if ( Ballwin.Ruffin == 0 and Ballwin.Millett == 0 ) {
            apply( Shelbina );
         }
      } else if ( ( ( Mystic.Vestaburg & ( 0x2 ) ) == ( ( 0x2 ) ) ) and ( Tingley.Lucas == 1 ) ) {
         if ( Ringwood.Guayabal != 0 ) {
            apply( Willows );
         } else if ( Ballwin.Ruffin == 0 and Ballwin.Millett == 0 ) {
            apply( Paullina );
            if ( Ringwood.Webbville != 0 ) {
               apply( Broadford );
            }
         }
      } else if( Tingley.Stilson == 1 ) {
         apply( TroutRun );
      }
   }
}
control Blevins {
   if( Ballwin.Ruffin != 0 ) {
      apply( Quarry );
   }
}
action Hanapepe( Gillespie ) {
   modify_field( Ballwin.Millett, Gillespie );
}
field_list Jamesport {
   Laneburg.Mineral;
}
field_list_calculation Bledsoe {
    input {
        Jamesport;
    }
    algorithm : identity;
    output_width : 66;
}
action_selector Brinklow {
   selection_key : Bledsoe;
   selection_mode : resilient;
}
action_profile KawCity {
   actions {
      Veradale;
   }
   size : 65536;
   dynamic_action_selection : Brinklow;
}
@pragma selector_max_group_size 256
table Monse {
   reads {
      Ballwin.Millett : exact;
   }
   action_profile : KawCity;
   size : 2048;
}
control Bergoo {
   if ( Ballwin.Millett != 0 ) {
      apply( Monse );
   }
}
field_list Daphne {
   Laneburg.Swain;
}
field_list_calculation Pawtucket {
    input {
        Daphne;
    }
    algorithm : identity;
    output_width : 51;
}
action_selector FulksRun {
    selection_key : Pawtucket;
    selection_mode : resilient;
}
action Ladoga(Papeton) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Papeton);
}
action_profile Gallinas {
    actions {
        Ladoga;
        Nanson;
    }
    size : 1024;
    dynamic_action_selection : FulksRun;
}
table Neosho {
   reads {
      Ranburne.Jonesport : exact;
   }
   action_profile: Gallinas;
   size : 1024;
}
control Palatka {
   if ((Ranburne.Jonesport & 0x2000) == 0x2000) {
      apply(Neosho);
   }
}
action Enderlin() {
   modify_field(Ranburne.Sidnaw, Tingley.Sparr);
   modify_field(Ranburne.Shopville, Tingley.Conner);
   modify_field(Ranburne.Edinburg, Tingley.Burgdorf);
   modify_field(Ranburne.Mabelvale, Tingley.Copemish);
   modify_field(Ranburne.Larwill, Tingley.Lofgreen);
   invalidate( ig_intr_md_for_tm.ucast_egress_port );
}
table Hebbville {
   actions {
      Enderlin;
   }
   default_action : Enderlin();
   size : 1;
}
control Karlsruhe {
   apply( Hebbville );
}
action Forkville() {
   modify_field(Ranburne.Ferndale, 1);
   modify_field(Ranburne.Pickett, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Tingley.Stilson);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Ranburne.Larwill);
}
action Calvary() {
}
@pragma ways 1
table Plains {
   reads {
      Ranburne.Sidnaw : exact;
      Ranburne.Shopville : exact;
   }
   actions {
      Forkville;
      Calvary;
   }
   default_action : Calvary;
   size : 1;
}
action Bothwell() {
   modify_field(Ranburne.OjoFeliz, 1);
   modify_field(Ranburne.Brothers, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Ranburne.Larwill, 4096);
}
table Arapahoe {
   actions {
      Bothwell;
   }
   default_action : Bothwell;
   size : 1;
}
action Mondovi() {
   modify_field(Ranburne.Waukegan, 1);
   modify_field(Ranburne.Pickett, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Ranburne.Larwill);
}
table Greendale {
   actions {
      Mondovi;
   }
   default_action : Mondovi();
   size : 1;
}
action Greycliff(Moorpark) {
   modify_field(Ranburne.Beresford, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Moorpark);
   modify_field(Ranburne.Jonesport, Moorpark);
}
action Merrill(Saxonburg) {
   modify_field(Ranburne.OjoFeliz, 1);
   modify_field(Ranburne.Newellton, Saxonburg);
}
action Renton() {
}
table Wayzata {
   reads {
      Ranburne.Sidnaw : exact;
      Ranburne.Shopville : exact;
      Ranburne.Larwill : exact;
   }
   actions {
      Greycliff;
      Merrill;
      Rotterdam;
      Renton;
   }
   default_action : Renton();
   size : 65536;
}
control Pierre {
   if (Tingley.Cache == 0 and not valid(Perrine) ) {
      apply(Wayzata) {
         Renton {
            apply(Plains) {
               Calvary {
                  if ((Ranburne.Sidnaw & 0x010000) == 0x010000) {
                     apply(Arapahoe);
                  } else {
                     apply(Greendale);
                  }
               }
            }
         }
      }
   }
}
action Sylvester() {
   modify_field(Tingley.Umpire, 1);
   Rotterdam();
}
table Provo {
   actions {
      Sylvester;
   }
   default_action : Sylvester;
   size : 1;
}
control McGonigle {
   if (Tingley.Cache == 0) {
      if ((Ranburne.Cornville==0) and (Tingley.Kapowsin==0) and (Tingley.Colburn==0) and (Tingley.Boysen==Ranburne.Jonesport)) {
         apply(Provo);
      }
   }
}
action Eskridge( RoseBud ) {
   modify_field( Ranburne.Yreka, RoseBud );
}
action Hisle() {
   modify_field( Ranburne.Yreka, Ranburne.Larwill );
}
table Blunt {
   reads {
      eg_intr_md.egress_port : exact;
      Ranburne.Larwill : exact;
   }
   actions {
      Eskridge;
      Hisle;
   }
   default_action : Hisle;
   size : 4096;
}
control Belmont {
   apply( Blunt );
}
action Woodrow( Hurst, Hearne ) {
   modify_field( Ranburne.Penzance, Hurst );
   modify_field( Ranburne.Kahului, Hearne );
}
table Brackett {
   reads {
      Ranburne.Shevlin : exact;
   }
   actions {
      Woodrow;
   }
   size : 8;
}
action Coulee() {
   modify_field( Ranburne.Baytown, 1 );
   modify_field( Ranburne.Shevlin, 2 );
}
action RushHill() {
   modify_field( Ranburne.Baytown, 1 );
   modify_field( Ranburne.Shevlin, 1 );
}
table Lamont {
   reads {
      Ranburne.Mabel : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Coulee;
      RushHill;
   }
   default_action : Nanson();
   size : 16;
}
action Grants(Sieper, Virgil, Ikatan, Grainola) {
   modify_field( Ranburne.Wanamassa, Sieper );
   modify_field( Ranburne.Seagate, Virgil );
   modify_field( Ranburne.Korbel, Ikatan );
   modify_field( Ranburne.Tillson, Grainola );
}
table Mahopac {
   reads {
        Ranburne.Blackwood : exact;
   }
   actions {
      Grants;
   }
   size : 256;
}
action Brunson() {
   mark_for_drop();
}
action Achilles( Craigtown ) {
   modify_field( Ranburne.BigFork, Craigtown );
}

#ifndef NO_PRAGMA_STAGE
#define NO_PRAGMA_STAGE
#endif

@pragma use_hash_action 1
#ifndef NO_PRAGMA_STAGE
@pragma stage 0
#endif
table Bokeelia {
   reads {
      Ranburne.Temple : exact;
   }
   actions {
      Achilles;
   }
   default_action : Achilles(0);
#ifdef CASE_FIX
   size : 65536;
#else
   size : 131072;
#endif
}
action Freeville( Donnelly, Cowden ) {
   modify_field( Ranburne.Lapel, Donnelly );
   modify_field( Ranburne.Anawalt, Cowden );
}
@pragma use_hash_action 1
#ifndef NO_PRAGMA_STAGE
@pragma stage 1
#endif
table Stewart {
   reads {
      Ranburne.Slagle : exact;
   }
   actions {
      Freeville;
   }
   default_action : Freeville(0,0);
   size : 256;
}
control Campbell {
   if( Ranburne.Slagle != 0 ) {
      apply( Bokeelia );
      apply( Stewart );
   }
}
action Cornell() {
   no_op();
}
action Westbrook() {
   modify_field( Frontenac.WoodDale, Hobucken[0].Blitchton );
   remove_header( Hobucken[0] );
}
table Longview {
   actions {
      Westbrook;
   }
   default_action : Westbrook;
   size : 1;
}
action Calhan() {
   no_op();
}
action Powderly() {
   add_header( Hobucken[ 0 ] );
   modify_field( Hobucken[0].DelRey, Ranburne.Yreka );
   modify_field( Hobucken[0].Blitchton, Frontenac.WoodDale );
   modify_field( Hobucken[0].Brainard, Kinross.Easley );
   modify_field( Hobucken[0].DelMar, Kinross.Willamina );
   modify_field( Frontenac.WoodDale, 0x8100 );
}
table Scarville {
   reads {
      Ranburne.Yreka : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Calhan;
      Powderly;
   }
   default_action : Powderly;
   size : 128;
}
action NewMelle() {
   modify_field(Frontenac.Wolcott, Ranburne.Sidnaw);
   modify_field(Frontenac.Glouster, Ranburne.Shopville);
   modify_field(Frontenac.Farner, Ranburne.Penzance);
   modify_field(Frontenac.Lapoint, Ranburne.Kahului);
}
action JaneLew() {
   NewMelle();
   modify_field(Newcomb.Milbank, Luzerne.Gibsland);
   add_to_field(Newcomb.Stambaugh, -1);
   modify_field(Newcomb.Philmont, Kinross.Lakebay);
}
action Otranto() {
   NewMelle();
   add_to_field(Vacherie.Cistern, -1);
   modify_field(Vacherie.Swedeborg, Kinross.Lakebay);
}
action Grovetown() {
   modify_field(Newcomb.Milbank, Luzerne.Gibsland);
   modify_field(Newcomb.Philmont, Kinross.Lakebay);
}
action Kathleen() {
   modify_field(Vacherie.Swedeborg, Kinross.Lakebay);
}
action Toano() {
   Powderly();
}
action Pendroy( Gerty, Maxwelton, Colfax, WestLawn ) {
   add_header( Skillman );
   modify_field( Skillman.Wolcott, Gerty );
   modify_field( Skillman.Glouster, Maxwelton );
   modify_field( Skillman.Farner, Colfax );
   modify_field( Skillman.Lapoint, WestLawn );
   modify_field( Skillman.WoodDale, 0xBF00 );
   add_header( Perrine );
   modify_field( Perrine.Arvana, Ranburne.Wanamassa );
   modify_field( Perrine.Linville, Ranburne.Seagate );
   modify_field( Perrine.Glenside, Ranburne.Korbel );
   modify_field( Perrine.Temelec, Ranburne.Tillson );
   modify_field( Perrine.Ohiowa, Ranburne.Kempton );
}
action Hanks() {
   remove_header( Hobson );
   remove_header( Janney );
   remove_header( Saxis );
   copy_header( Frontenac, Domestic );
   remove_header( Domestic );
   remove_header( Newcomb );
}
action Lyman() {
   remove_header( Skillman );
   remove_header( Perrine );
}
action Oxnard() {
   Hanks();
   modify_field(Caspian.Philmont, Kinross.Lakebay);
}
action McBride() {
   Hanks();
   modify_field(Dunkerton.Swedeborg, Kinross.Lakebay);
}
table Oakes {
   reads {
      Ranburne.Columbus : exact;
      Ranburne.Shevlin : exact;
      Ranburne.Cornville : exact;
      Newcomb.valid : ternary;
      Vacherie.valid : ternary;
      Caspian.valid : ternary;
      Dunkerton.valid : ternary;
   }
   actions {
      JaneLew;
      Otranto;
      Grovetown;
      Kathleen;
      Toano;
      Pendroy;
      Lyman;
      Hanks;
      Oxnard;
      McBride;
   }
   size : 512;
}
control Stehekin {
   apply( Longview );
}
control Camanche {
   apply( Scarville );
}
control Guion {
   apply( Lamont ) {
      Nanson {
         apply( Brackett );
      }
   }
   apply( Mahopac );
   apply( Oakes );
}
field_list Hampton {
    Lorane.Goodyear;
    Tingley.Lofgreen;
    Domestic.Farner;
    Domestic.Lapoint;
    Newcomb.Rochert;
}
action Slovan() {
   generate_digest(0, Hampton);
}
table Wolsey {
   actions {
      Slovan;
   }
   default_action : Slovan;
   size : 1;
}
control Congress {
   if (Lorane.Goodyear == 2) {
      apply(Wolsey);
   }
}
action Coalwood() {
   modify_field( Kinross.Easley, Flasher.EastDuke );
}
action Vidal() {
   modify_field( Kinross.Easley, Hobucken[0].Brainard );
   modify_field( Tingley.Radom, Hobucken[0].Blitchton );
}
action Mingus() {
   modify_field( Kinross.Lakebay, Flasher.Rohwer );
}
action Alcester() {
   modify_field( Kinross.Lakebay, Luzerne.Yorkshire );
}
action Wagener() {
   modify_field( Kinross.Lakebay, Ringwood.Keener );
}
action Traskwood( Wayne, PoleOjea ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Wayne );
   modify_field( ig_intr_md_for_tm.qid, PoleOjea );
}
table Sandpoint {
   reads {
     Tingley.Camino : exact;
   }
   actions {
     Coalwood;
     Vidal;
   }
   size : 2;
}
table Chaffey {
   reads {
     Tingley.Mantee : exact;
     Tingley.Lucas : exact;
   }
   actions {
     Mingus;
     Alcester;
     Wagener;
   }
   size : 3;
}
table Grottoes {
   reads {
      Flasher.Separ : ternary;
      Flasher.EastDuke : ternary;
      Kinross.Easley : ternary;
      Kinross.Lakebay : ternary;
      Kinross.Cuney : ternary;
   }
   actions {
      Traskwood;
   }
   size : 81;
}
action Wakefield( Inverness, Christmas ) {
   bit_or( Kinross.Novice, Kinross.Novice, Inverness );
   bit_or( Kinross.Selah, Kinross.Selah, Christmas );
}
table Eustis {
   actions {
      Wakefield;
   }
   default_action : Wakefield;
   size : 1;
}
action Blakeley( Armijo ) {
   modify_field( Kinross.Lakebay, Armijo );
}
action Hobergs( Tindall ) {
   modify_field( Kinross.Easley, Tindall );
}
action Balmorhea( Pineville, Berkey ) {
   modify_field( Kinross.Easley, Pineville );
   modify_field( Kinross.Lakebay, Berkey );
}
table Eastwood {
   reads {
      Flasher.Separ : exact;
      Kinross.Novice : exact;
      Kinross.Selah : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Blakeley;
      Hobergs;
      Balmorhea;
   }
   size : 512;
}
control Astor {
   apply( Sandpoint );
   apply( Chaffey );
}
control Florida {
   apply( Grottoes );
}
control Persia {
   apply( Eustis );
   apply( Eastwood );
}
action Shirley( Pineland ) {
   modify_field( Kinross.Wetonka, Pineland );
}
table Neshaminy {
   reads {
      ig_intr_md.ingress_port : exact;
   }
   actions {
      Shirley;
   }
}
action Catawissa( Skokomish ) {
   modify_field( Kinross.Candle, Skokomish );
}
action Silvertip( Belview ) {
   Catawissa( Belview );
   modify_field( Kinross.Lanesboro, 1 );
}
table Trout {
   reads {
      Kinross.Wetonka : ternary;
      Tingley.Radom : ternary;
      Ranburne.Shopville : ternary;
      Ranburne.Sidnaw : ternary;
      Ballwin.Ruffin : ternary;
   }
   actions {
      Catawissa;
      Silvertip;
   }
   size : 512;
}
table Emigrant {
   reads {
      Kinross.Wetonka : ternary;
      Tingley.Mantee : ternary;
      Tingley.Lucas : ternary;
      Luzerne.Gibsland : ternary;
      Ringwood.Charco mask 0xffff0000000000000000000000000000 : ternary;
      Tingley.Revere : ternary;
      Tingley.Weches : ternary;
      Ranburne.Cornville : ternary;
      Ballwin.Ruffin : ternary;
      Saxis.Ivins : ternary;
      Saxis.Morgana : ternary;
   }
   actions {
      Catawissa;
      Silvertip;
   }
   size : 512;
}
meter Brush {
   type : packets;
   static : Basic;
   instance_count : 4096;
}
action Aptos() {
   execute_meter( Brush, Kinross.Candle, ig_intr_md_for_tm.packet_color );
}
table Basic {
   actions {
      Aptos;
   }
   default_action : Aptos;
   size : 1;
}
counter Alamance {
   type : packets;
   instance_count : 4096;
   min_width : 64;
}
action Hibernia() {
   count( Alamance, Kinross.Candle );
}
table Kingsgate {
   actions {
     Hibernia;
   }
   default_action : Hibernia;
   size : 1;
}
control Anson {
   apply( Neshaminy );
}
control Benwood {
      if ( ( Tingley.Mantee == 0 ) and ( Tingley.Lucas == 0 ) ) {
         apply( Trout );
      } else {
         apply( Emigrant );
      }
}
control Linganore {
    if ( Tingley.Cache == 0 ) {
      if ( Kinross.Lanesboro == 1 ) {
         apply( Basic );
      }
      apply( Kingsgate );
   }
}
action Butler( Tehachapi ) {
   modify_field( Ranburne.Mabel, 0 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Tehachapi );
   modify_field( Ranburne.Blackwood, ig_intr_md.ingress_port );
}
action Terrytown( Waitsburg ) {
   modify_field( Ranburne.Mabel, 1 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Waitsburg );
   modify_field( Ranburne.Blackwood, ig_intr_md.ingress_port );
}
action Joseph() {
   modify_field( Ranburne.Mabel, 0 );
}
action Rienzi() {
   modify_field( Ranburne.Mabel, 1 );
   modify_field( Ranburne.Blackwood, ig_intr_md.ingress_port );
}
@pragma ternary 1
table Absarokee {
   reads {
      Ranburne.Monida : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      Mystic.Dugger : exact;
      Flasher.Pittwood : ternary;
      Ranburne.Kempton : ternary;
   }
   actions {
      Butler;
      Terrytown;
      Joseph;
      Rienzi;
   }
   default_action : Nanson();
   size : 512;
}
control Cricket {
   apply( Absarokee ) {
      Butler {
      }
      Terrytown {
      }
      default {
         Palatka();
      }
   }
}
counter Knollwood {
   type : packets_and_bytes;
   instance_count : 1024;
   min_width : 128;
}
action Dellslow( Admire ) {
   count( Knollwood, Admire );
}
table Dairyland {
   reads {
      eg_intr_md.egress_port mask 0x7f: exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }
   actions {
     Dellslow;
   }
   size : 1024;
}
control Kranzburg {
   apply( Dairyland );
}
action Chatanika()
{
   Rotterdam();
}
action Cabery()
{
   modify_field(Ranburne.Columbus, 2);
   bit_or(Ranburne.Jonesport, 0x2000, Perrine.Temelec);
}
action Olene( Burnett ) {
   modify_field(Ranburne.Columbus, 2);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Burnett);
   modify_field(Ranburne.Jonesport, Burnett);
}
table Heppner {
   reads {
      Perrine.Arvana : exact;
      Perrine.Linville : exact;
      Perrine.Glenside : exact;
      Perrine.Temelec : exact;
   }
   actions {
      Cabery;
      Olene;
      Chatanika;
   }
   default_action : Chatanika();
   size : 256;
}
control Cathcart {
   apply( Heppner );
}
action Bergton( Nestoria, Kenney, Cartago, WestLine ) {
   modify_field( Narka.Pueblo, Nestoria );
   modify_field( Virginia.Glendevey, Cartago );
   modify_field( Virginia.Arion, Kenney );
   modify_field( Virginia.Turney, WestLine );
}
table Borth {
   reads {
     Luzerne.Gibsland : exact;
     Tingley.Cleta : exact;
   }
   actions {
      Bergton;
   }
  size : 16384;
}
action Onida(BealCity, Petoskey, Pettigrew) {
   modify_field( Virginia.Arion, BealCity );
   modify_field( Virginia.Glendevey, Petoskey );
   modify_field( Virginia.Turney, Pettigrew );
}
table Finney {
   reads {
     Luzerne.Bethesda : exact;
     Narka.Pueblo : exact;
   }
   actions {
      Onida;
   }
   size : 16384;
}
action Halaula( Bevington, Berville, Energy ) {
   modify_field( Amity.Tiburon, Bevington );
   modify_field( Amity.Rhodell, Berville );
   modify_field( Amity.Wilson, Energy );
}
table Belwood {
   reads {
     Ranburne.Sidnaw : exact;
     Ranburne.Shopville : exact;
     Ranburne.Larwill : exact;
   }
   actions {
      Halaula;
   }
   size : 16384;
}
action Shauck() {
   modify_field( Ranburne.Pickett, 1 );
}
action Pinta( Macdona ) {
   Shauck();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Virginia.Arion );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Macdona, Virginia.Turney );
}
action Moultrie( Niota ) {
   Shauck();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Amity.Tiburon );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Niota, Amity.Wilson );
}
action Overton( Wanatah ) {
   Shauck();
   add( ig_intr_md_for_tm.mcast_grp_a, Ranburne.Larwill,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Wanatah );
}
action Maida() {
   modify_field( Ranburne.Iredell, 1 );
}
table Exell {
   reads {
     Virginia.Glendevey : ternary;
     Virginia.Arion : ternary;
     Amity.Tiburon : ternary;
     Amity.Rhodell : ternary;
     Tingley.Revere :ternary;
     Tingley.Kapowsin:ternary;
   }
   actions {
      Pinta;
      Moultrie;
      Overton;
      Maida;
   }
   size : 32;
}
control Creston {
   if( Tingley.Cache == 0 and
       ( ( Mystic.Vestaburg & ( 0x4 ) ) == ( ( 0x4 ) ) ) and
       Tingley.Dalkeith == 1 ) {
      apply( Borth );
   }
}
control Bowers {
   if( Narka.Pueblo != 0 ) {
      apply( Finney );
   }
}
control Inola {
   if( Tingley.Cache == 0 and Tingley.Kapowsin==1 ) {
      apply( Belwood );
   }
}
control Whiteclay {
   if( Tingley.Kapowsin == 1 ) {
      apply(Exell);
   }
}
action Mogadore(Lauada) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Laneburg.Swain );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Lauada );
}
table Leflore {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Mogadore;
    }
    size : 512;
}
control Waupaca {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Leflore);
   }
}
action Forman( Haverford, Dyess ) {
   modify_field( Ranburne.Larwill, Haverford );
   modify_field( Ranburne.Cornville, Dyess );
}
action Mattapex() {
   drop();
}
table Lignite {
   reads {
     eg_intr_md.egress_rid: exact;
   }
   actions {
      Forman;
   }
   default_action: Mattapex;
   size : 57344;
}
control Scanlon {
   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Lignite);
   }
}
counter Hiland {
   type : packets;
   direct: Stratford;
   min_width: 63;
}
#ifndef NO_PRAGMA_STAGE
@pragma stage 11
#endif
table Stratford {
   reads {
     Brinkman.Notus mask 0x7fff : exact;
   }
   actions {
      Nanson;
   }
   default_action: Nanson();
   size : 32768;
}
action Shuqualak() {
   modify_field( Ruthsburg.NorthRim, Tingley.Revere );
   modify_field( Ruthsburg.Strasburg, Luzerne.Yorkshire );
   modify_field( Ruthsburg.Harriet, Tingley.Weches );
   modify_field( Ruthsburg.Twodot, Tingley.Denning );
}
action Dauphin() {
   modify_field( Ruthsburg.NorthRim, Tingley.Revere );
   modify_field( Ruthsburg.Strasburg, Ringwood.Keener );
   modify_field( Ruthsburg.Harriet, Tingley.Weches );
   modify_field( Ruthsburg.Twodot, Tingley.Denning );
}
action VanZandt( Dubbs ) {
   Shuqualak();
   modify_field( Ruthsburg.Victoria, Dubbs );
}
action Westhoff( Patsville ) {
   Dauphin();
   modify_field( Ruthsburg.Victoria, Patsville );
}
table Sumner {
   reads {
     Luzerne.Bethesda : ternary;
   }
   actions {
      VanZandt;
   }
   default_action : Shuqualak;
  size : 2048;
}
table SomesBar {
   reads {
     Ringwood.Kewanee : ternary;
   }
   actions {
      Westhoff;
   }
   default_action : Dauphin;
   size : 1024;
}
action Langlois( Belmond ) {
   modify_field( Ruthsburg.Cutler, Belmond );
}
table McDavid {
   reads {
     Luzerne.Gibsland : ternary;
   }
   actions {
      Langlois;
   }
   size : 512;
}
table Pierceton {
   reads {
     Ringwood.Charco : ternary;
   }
   actions {
      Langlois;
   }
   size : 512;
}
action Ruston( Waipahu ) {
   modify_field( Ruthsburg.Volens, Waipahu );
}
table Indrio {
   reads {
     Tingley.Mishawaka : ternary;
   }
   actions {
      Ruston;
   }
   size : 512;
}
action Surrency( Floral ) {
   modify_field( Ruthsburg.Gullett, Floral );
}
table Connell {
   reads {
     Tingley.Yaurel : ternary;
   }
   actions {
      Surrency;
   }
   size : 512;
}
action Boyle( Petrey ) {
   modify_field( Ruthsburg.Ridgeview, Petrey );
}
action Greenlawn( Visalia ) {
   modify_field( Ruthsburg.Ridgeview, Visalia );
}
table Sweeny {
   reads {
     Tingley.Mantee : exact;
     Tingley.Lucas : exact;
     Tingley.MoonRun mask 4 : exact;
     Tingley.Cleta : exact;
   }
   actions {
      Boyle;
      Nanson;
   }
   default_action : Nanson();
   size : 4096;
}
table Lantana {
   reads {
     Tingley.Mantee : exact;
     Tingley.Lucas : exact;
     Tingley.MoonRun mask 4 : exact;
     Flasher.Hematite : exact;
   }
   actions {
      Greenlawn;
   }
   size : 512;
}
control Freeny {
   if( Tingley.Mantee == 1 ) {
      apply( Sumner );
      apply( McDavid );
   } else if( Tingley.Lucas == 1 ) {
      apply( SomesBar );
      apply( Pierceton );
   }
   if( ( Tingley.MoonRun & 2 ) == 2 ) {
      apply( Indrio );
      apply( Connell );
   }
   apply( Sweeny ) {
      Nanson {
         apply( Lantana );
      }
   }
}
action Trail() {
}
action Neches() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action Asharoken() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
}
action Arvada() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
table Covina {
   reads {
     Brinkman.Notus mask 0x00018000 : ternary;
   }
   actions {
      Trail;
      Neches;
      Asharoken;
      Arvada;
   }
   size : 16;
}
control Gurdon {
   apply( Covina );
   apply( Stratford );
}
   metadata IttaBena Brinkman;
   action Elcho( Parkway ) {
          max( Brinkman.Notus, Brinkman.Notus, Parkway );
   }
@pragma ways 1
table Goodwater {
   reads {
      Ruthsburg.Ridgeview : exact;
      Ruthsburg.Victoria : exact;
      Ruthsburg.Cutler : exact;
      Ruthsburg.Volens : exact;
      Ruthsburg.Gullett : exact;
      Ruthsburg.NorthRim : exact;
      Ruthsburg.Strasburg : exact;
      Ruthsburg.Harriet : exact;
      Ruthsburg.Twodot : exact;
      Ruthsburg.Chamois : exact;
   }
   actions {
      Elcho;
   }
   size : 4096;
}
control Chehalis {
   apply( Goodwater );
}
@pragma pa_no_init ingress Frankfort.Victoria
@pragma pa_no_init ingress Frankfort.Cutler
@pragma pa_no_init ingress Frankfort.Volens
@pragma pa_no_init ingress Frankfort.Gullett
@pragma pa_no_init ingress Frankfort.NorthRim
@pragma pa_no_init ingress Frankfort.Strasburg
@pragma pa_no_init ingress Frankfort.Harriet
@pragma pa_no_init ingress Frankfort.Twodot
@pragma pa_no_init ingress Frankfort.Chamois
metadata Pilar Frankfort;
@pragma ways 1
table Pidcoke {
   reads {
      Ruthsburg.Ridgeview : exact;
      Frankfort.Victoria : exact;
      Frankfort.Cutler : exact;
      Frankfort.Volens : exact;
      Frankfort.Gullett : exact;
      Frankfort.NorthRim : exact;
      Frankfort.Strasburg : exact;
      Frankfort.Harriet : exact;
      Frankfort.Twodot : exact;
      Frankfort.Chamois : exact;
   }
   actions {
      Elcho;
   }
   size : 8192;
}
action Portis( Johnstown, Milwaukie, Speed, Amenia, Dollar, Triplett, Lucerne, Onawa, Chantilly ) {
   bit_and( Frankfort.Victoria, Ruthsburg.Victoria, Johnstown );
   bit_and( Frankfort.Cutler, Ruthsburg.Cutler, Milwaukie );
   bit_and( Frankfort.Volens, Ruthsburg.Volens, Speed );
   bit_and( Frankfort.Gullett, Ruthsburg.Gullett, Amenia );
   bit_and( Frankfort.NorthRim, Ruthsburg.NorthRim, Dollar );
   bit_and( Frankfort.Strasburg, Ruthsburg.Strasburg, Triplett );
   bit_and( Frankfort.Harriet, Ruthsburg.Harriet, Lucerne );
   bit_and( Frankfort.Twodot, Ruthsburg.Twodot, Onawa );
   bit_and( Frankfort.Chamois, Ruthsburg.Chamois, Chantilly );
}
table Pavillion {
   reads {
      Ruthsburg.Ridgeview : exact;
   }
   actions {
      Portis;
   }
   default_action : Portis(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Coqui {
   apply( Pavillion );
}
control Aspetuck {
   apply( Pidcoke );
}
@pragma ways 1
table Rugby {
   reads {
      Ruthsburg.Ridgeview : exact;
      Frankfort.Victoria : exact;
      Frankfort.Cutler : exact;
      Frankfort.Volens : exact;
      Frankfort.Gullett : exact;
      Frankfort.NorthRim : exact;
      Frankfort.Strasburg : exact;
      Frankfort.Harriet : exact;
      Frankfort.Twodot : exact;
      Frankfort.Chamois : exact;
   }
   actions {
      Elcho;
   }
   size : 4096;
}
action Seguin( Noyes, Owanka, Raceland, Mickleton, Dunnstown, Moraine, Padonia, Suarez, Tulalip ) {
   bit_and( Frankfort.Victoria, Ruthsburg.Victoria, Noyes );
   bit_and( Frankfort.Cutler, Ruthsburg.Cutler, Owanka );
   bit_and( Frankfort.Volens, Ruthsburg.Volens, Raceland );
   bit_and( Frankfort.Gullett, Ruthsburg.Gullett, Mickleton );
   bit_and( Frankfort.NorthRim, Ruthsburg.NorthRim, Dunnstown );
   bit_and( Frankfort.Strasburg, Ruthsburg.Strasburg, Moraine );
   bit_and( Frankfort.Harriet, Ruthsburg.Harriet, Padonia );
   bit_and( Frankfort.Twodot, Ruthsburg.Twodot, Suarez );
   bit_and( Frankfort.Chamois, Ruthsburg.Chamois, Tulalip );
}
table Newport {
   reads {
      Ruthsburg.Ridgeview : exact;
   }
   actions {
      Seguin;
   }
   default_action : Seguin(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Tiskilwa {
   apply( Newport );
}
control Wauna {
   apply( Rugby );
}
@pragma ways 1
table Barnhill {
   reads {
      Ruthsburg.Ridgeview : exact;
      Frankfort.Victoria : exact;
      Frankfort.Cutler : exact;
      Frankfort.Volens : exact;
      Frankfort.Gullett : exact;
      Frankfort.NorthRim : exact;
      Frankfort.Strasburg : exact;
      Frankfort.Harriet : exact;
      Frankfort.Twodot : exact;
      Frankfort.Chamois : exact;
   }
   actions {
      Elcho;
   }
   size : 4096;
}
action Gastonia( RedHead, Lamine, Cortland, WestGate, Enhaut, Baird, Excel, NewRome, Huntoon ) {
   bit_and( Frankfort.Victoria, Ruthsburg.Victoria, RedHead );
   bit_and( Frankfort.Cutler, Ruthsburg.Cutler, Lamine );
   bit_and( Frankfort.Volens, Ruthsburg.Volens, Cortland );
   bit_and( Frankfort.Gullett, Ruthsburg.Gullett, WestGate );
   bit_and( Frankfort.NorthRim, Ruthsburg.NorthRim, Enhaut );
   bit_and( Frankfort.Strasburg, Ruthsburg.Strasburg, Baird );
   bit_and( Frankfort.Harriet, Ruthsburg.Harriet, Excel );
   bit_and( Frankfort.Twodot, Ruthsburg.Twodot, NewRome );
   bit_and( Frankfort.Chamois, Ruthsburg.Chamois, Huntoon );
}
table Mackeys {
   reads {
      Ruthsburg.Ridgeview : exact;
   }
   actions {
      Gastonia;
   }
   default_action : Gastonia(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Between {
   apply( Mackeys );
}
control Curlew {
   apply( Barnhill );
}
@pragma ways 1
table Crestone {
   reads {
      Ruthsburg.Ridgeview : exact;
      Frankfort.Victoria : exact;
      Frankfort.Cutler : exact;
      Frankfort.Volens : exact;
      Frankfort.Gullett : exact;
      Frankfort.NorthRim : exact;
      Frankfort.Strasburg : exact;
      Frankfort.Harriet : exact;
      Frankfort.Twodot : exact;
      Frankfort.Chamois : exact;
   }
   actions {
      Elcho;
   }
   size : 8192;
}
action BigRock( Hollyhill, Clinchco, Ridgeland, RedCliff, BeeCave, Paxico, McKibben, LongPine, Trona ) {
   bit_and( Frankfort.Victoria, Ruthsburg.Victoria, Hollyhill );
   bit_and( Frankfort.Cutler, Ruthsburg.Cutler, Clinchco );
   bit_and( Frankfort.Volens, Ruthsburg.Volens, Ridgeland );
   bit_and( Frankfort.Gullett, Ruthsburg.Gullett, RedCliff );
   bit_and( Frankfort.NorthRim, Ruthsburg.NorthRim, BeeCave );
   bit_and( Frankfort.Strasburg, Ruthsburg.Strasburg, Paxico );
   bit_and( Frankfort.Harriet, Ruthsburg.Harriet, McKibben );
   bit_and( Frankfort.Twodot, Ruthsburg.Twodot, LongPine );
   bit_and( Frankfort.Chamois, Ruthsburg.Chamois, Trona );
}
table Naguabo {
   reads {
      Ruthsburg.Ridgeview : exact;
   }
   actions {
      BigRock;
   }
   default_action : BigRock(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Grantfork {
   apply( Naguabo );
}
control Sammamish {
   apply( Crestone );
}
@pragma ways 1
table Viroqua {
   reads {
      Ruthsburg.Ridgeview : exact;
      Frankfort.Victoria : exact;
      Frankfort.Cutler : exact;
      Frankfort.Volens : exact;
      Frankfort.Gullett : exact;
      Frankfort.NorthRim : exact;
      Frankfort.Strasburg : exact;
      Frankfort.Harriet : exact;
      Frankfort.Twodot : exact;
      Frankfort.Chamois : exact;
   }
   actions {
      Elcho;
   }
   size : 8192;
}
action Kinsey( Wenona, Halbur, Freedom, Macungie, Gracewood, Dunmore, RockHall, Granville, Bairoil ) {
   bit_and( Frankfort.Victoria, Ruthsburg.Victoria, Wenona );
   bit_and( Frankfort.Cutler, Ruthsburg.Cutler, Halbur );
   bit_and( Frankfort.Volens, Ruthsburg.Volens, Freedom );
   bit_and( Frankfort.Gullett, Ruthsburg.Gullett, Macungie );
   bit_and( Frankfort.NorthRim, Ruthsburg.NorthRim, Gracewood );
   bit_and( Frankfort.Strasburg, Ruthsburg.Strasburg, Dunmore );
   bit_and( Frankfort.Harriet, Ruthsburg.Harriet, RockHall );
   bit_and( Frankfort.Twodot, Ruthsburg.Twodot, Granville );
   bit_and( Frankfort.Chamois, Ruthsburg.Chamois, Bairoil );
}
table Wartburg {
   reads {
      Ruthsburg.Ridgeview : exact;
   }
   actions {
      Kinsey;
   }
   default_action : Kinsey(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Baker {
   apply( Wartburg );
}
control Lawai {
   apply( Viroqua );
}
@pragma ways 1
table Nerstrand {
   reads {
      Ruthsburg.Ridgeview : exact;
      Frankfort.Victoria : exact;
      Frankfort.Cutler : exact;
      Frankfort.Volens : exact;
      Frankfort.Gullett : exact;
      Frankfort.NorthRim : exact;
      Frankfort.Strasburg : exact;
      Frankfort.Harriet : exact;
      Frankfort.Twodot : exact;
      Frankfort.Chamois : exact;
   }
   actions {
      Elcho;
   }
   size : 4096;
}
action Kinards( Theba, Elkville, Dasher, Timken, Gonzalez, Cowpens, Antimony, Cheyenne, Aguilar ) {
   bit_and( Frankfort.Victoria, Ruthsburg.Victoria, Theba );
   bit_and( Frankfort.Cutler, Ruthsburg.Cutler, Elkville );
   bit_and( Frankfort.Volens, Ruthsburg.Volens, Dasher );
   bit_and( Frankfort.Gullett, Ruthsburg.Gullett, Timken );
   bit_and( Frankfort.NorthRim, Ruthsburg.NorthRim, Gonzalez );
   bit_and( Frankfort.Strasburg, Ruthsburg.Strasburg, Cowpens );
   bit_and( Frankfort.Harriet, Ruthsburg.Harriet, Antimony );
   bit_and( Frankfort.Twodot, Ruthsburg.Twodot, Cheyenne );
   bit_and( Frankfort.Chamois, Ruthsburg.Chamois, Aguilar );
}
table Cliffs {
   reads {
      Ruthsburg.Ridgeview : exact;
   }
   actions {
      Kinards;
   }
   default_action : Kinards(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Geistown {
   apply( Cliffs );
}
control Kennedale {
   apply( Nerstrand );
}
@pragma ways 1
table Pierson {
   reads {
      Ruthsburg.Ridgeview : exact;
      Frankfort.Victoria : exact;
      Frankfort.Cutler : exact;
      Frankfort.Volens : exact;
      Frankfort.Gullett : exact;
      Frankfort.NorthRim : exact;
      Frankfort.Strasburg : exact;
      Frankfort.Harriet : exact;
      Frankfort.Twodot : exact;
      Frankfort.Chamois : exact;
   }
   actions {
      Elcho;
   }
   size : 4096;
}
action LaPlata( Rockdell, HillCity, Lecanto, Pelican, Silva, Kaufman, Satus, Newborn, Salamatof ) {
   bit_and( Frankfort.Victoria, Ruthsburg.Victoria, Rockdell );
   bit_and( Frankfort.Cutler, Ruthsburg.Cutler, HillCity );
   bit_and( Frankfort.Volens, Ruthsburg.Volens, Lecanto );
   bit_and( Frankfort.Gullett, Ruthsburg.Gullett, Pelican );
   bit_and( Frankfort.NorthRim, Ruthsburg.NorthRim, Silva );
   bit_and( Frankfort.Strasburg, Ruthsburg.Strasburg, Kaufman );
   bit_and( Frankfort.Harriet, Ruthsburg.Harriet, Satus );
   bit_and( Frankfort.Twodot, Ruthsburg.Twodot, Newborn );
   bit_and( Frankfort.Chamois, Ruthsburg.Chamois, Salamatof );
}
table Minto {
   reads {
      Ruthsburg.Ridgeview : exact;
   }
   actions {
      LaPlata;
   }
   default_action : LaPlata(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Canalou {
   apply( Minto );
}
control Pinecrest {
   apply( Pierson );
}
control ingress {
   Tontogany();
   if( Flasher.Nixon != 0 ) {
      Drifton();
   }
   Stoystown();
   if( Flasher.Nixon != 0 ) {
      Bogota();
      Wyanet();
   }
   Freeny();
   Sidon();
   Simla();
   Coqui();
   if( Flasher.Nixon != 0 ) {
      Edroy();
   }
   Aspetuck();
   Tiskilwa();
   Wauna();
   Between();
   if( Flasher.Nixon != 0 ) {
      Dominguez();
   }
   Amesville();
   Nashua();
   Astor();
   Curlew();
   Grantfork();
   if( Flasher.Nixon != 0 ) {
      Bergoo();
   }
   Sammamish();
   Baker();
   Karlsruhe();
   Creston();
   if( Flasher.Nixon != 0 ) {
      Blevins();
   }
   Bowers();
   Congress();
   Lawai();
   Hamel();
   if( Ranburne.Monida == 0 ) {
      if( valid( Perrine ) ) {
         Cathcart();
      } else {
         Inola();
         Pierre();
      }
   }
   if( Perrine.valid == 0 ) {
      Florida();
   }
   Anson();
   Benwood();
   if( Ranburne.Monida == 0 ) {
      McGonigle();
   }
   if ( Ranburne.Monida == 0 ) {
      Whiteclay();
   }
   if( Flasher.Nixon != 0 ) {
      Persia();
   }
   Linganore();
   if( valid( Hobucken[0] ) ) {
      Stehekin();
   }
   if( Ranburne.Monida == 0 ) {
      Waupaca();
   }
   Cricket();
   Gurdon();
}
control egress {
   Campbell();
   Scanlon();
   Belmont();
   Guion();
   if( ( Ranburne.Baytown == 0 ) and ( Ranburne.Columbus != 2 ) ) {
      Camanche();
   }
   Kranzburg();
}
