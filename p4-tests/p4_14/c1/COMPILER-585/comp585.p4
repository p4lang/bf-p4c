// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 101422

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
header_type SanJon {
	fields {
		Mullins : 16;
		Hansell : 16;
		Readsboro : 8;
		Perryton : 8;
		Issaquah : 8;
		Parchment : 8;
		Reddell : 1;
		Bouton : 1;
		Snowball : 1;
		Maupin : 1;
		Korbel : 1;
		Froid : 1;
	}
}
header_type Hagerman {
	fields {
		Melmore : 24;
		MudLake : 24;
		Freeville : 24;
		Vidal : 24;
		Newfield : 16;
		LaVale : 16;
		BullRun : 16;
		Amonate : 16;
		Dunkerton : 16;
		Volcano : 8;
		Greycliff : 8;
		Capitola : 1;
		Gibson : 1;
		Shipman : 1;
		Ackley : 12;
		RedLake : 2;
		Malinta : 1;
		Aldan : 1;
		Solomon : 1;
		Slovan : 1;
		Picabo : 1;
		Lacona : 1;
		McDavid : 1;
		Sewanee : 1;
		Claypool : 1;
		Graford : 1;
		Canfield : 1;
		Lostwood : 1;
		Lenapah : 1;
		Buncombe : 1;
		Fairfield : 1;
		Hollymead : 1;
		Salamatof : 16;
		Belcher : 16;
		Tascosa : 8;
		Coachella : 1;
		Norseland : 1;
	}
}
header_type Thurston {
	fields {
		Mynard : 24;
		Hartford : 24;
		Twain : 24;
		Coalton : 24;
		Belfalls : 24;
		Norias : 24;
		Anniston : 24;
		Hadley : 24;
		Pineland : 16;
		Rosalie : 16;
		Chenequa : 16;
		Hanapepe : 16;
		Hansboro : 12;
		Blackwood : 1;
		Wrens : 3;
		Mantee : 1;
		Lonepine : 3;
		Anchorage : 1;
		Airmont : 1;
		PoleOjea : 1;
		Coulee : 1;
		Nuyaka : 1;
		VanHorn : 8;
		Yerington : 12;
		Barclay : 4;
		Calverton : 6;
		Folcroft : 10;
		Recluse : 9;
		Indios : 1;
		Upland : 1;
		Nederland : 1;
		BlackOak : 1;
		Keltys : 1;
	}
}
header_type Maceo {
	fields {
		Colson : 8;
		Lomax : 1;
		Almelund : 1;
		Alvordton : 1;
		Lakefield : 1;
		CedarKey : 1;
	}
}
header_type Renick {
	fields {
		Hanamaulu : 32;
		PineLawn : 32;
		Ephesus : 6;
		Trion : 16;
	}
}
header_type Wolsey {
	fields {
		ElmPoint : 128;
		Saranap : 128;
		Cuney : 20;
		Bieber : 8;
		Yaurel : 11;
		Terry : 6;
		Fosters : 13;
	}
}
header_type Filley {
	fields {
		Rembrandt : 14;
		Newtok : 1;
		Kapaa : 12;
		Mayview : 1;
		Allison : 1;
		Beaverton : 2;
		Hercules : 6;
		Perrin : 3;
	}
}
header_type Vestaburg {
	fields {
		Hiland : 1;
		Stratford : 1;
	}
}
header_type Mackeys {
	fields {
		Daguao : 8;
	}
}
header_type Segundo {
	fields {
		Duque : 16;
		Provencal : 11;
	}
}
header_type Paisley {
	fields {
		Amber : 32;
		Heron : 32;
		Mattawan : 32;
	}
}
header_type Bridger {
	fields {
		Haverford : 32;
		Dwight : 32;
	}
}
header_type Laneburg {
	fields {
		Livengood : 1;
		Franklin : 1;
		Cuprum : 1;
		Tuckerton : 3;
		McCaulley : 1;
		Naubinway : 6;
		Jacobs : 5;
	}
}
header_type Ralph {
	fields {
		Kalaloch : 16;
	}
}
header_type Ivydale {
	fields {
		Muncie : 14;
		Beatrice : 1;
		McManus : 1;
	}
}
header_type Loysburg {
	fields {
		Catlin : 14;
		Bridgton : 1;
		Heflin : 1;
	}
}
header_type Lincroft {
	fields {
		Sonestown : 16;
		Justice : 16;
		Hokah : 16;
		Gordon : 16;
		Ridgewood : 8;
		Linganore : 8;
		Westhoff : 8;
		Corbin : 8;
		SanPablo : 1;
		Leflore : 6;
	}
}
header_type Piketon {
	fields {
		Hitterdal : 32;
	}
}
header_type Bonsall {
	fields {
		Spiro : 6;
		Hurst : 10;
		Sawyer : 4;
		Dumas : 12;
		Lynndyl : 12;
		Elliston : 2;
		Lilydale : 2;
		Donna : 8;
		Goodrich : 3;
		Puyallup : 5;
	}
}
header_type Talmo {
	fields {
		Eckman : 24;
		Grays : 24;
		RedLevel : 24;
		Shirley : 24;
		Mabana : 16;
	}
}
header_type Murchison {
	fields {
		Cassa : 3;
		Casselman : 1;
		Willamina : 12;
		Metter : 16;
	}
}
header_type OreCity {
	fields {
		Moraine : 4;
		Kensal : 4;
		Menomonie : 6;
		Salix : 2;
		Chandalar : 16;
		Ruffin : 16;
		Amanda : 3;
		Gillespie : 13;
		Ignacio : 8;
		Granville : 8;
		Shawmut : 16;
		Hines : 32;
		Assinippi : 32;
	}
}
header_type Mellott {
	fields {
		Papeton : 4;
		HamLake : 6;
		Surrey : 2;
		LakePine : 20;
		Moclips : 16;
		Jarreau : 8;
		Rosboro : 8;
		Laketown : 128;
		Borup : 128;
	}
}
header_type TinCity {
	fields {
		Olyphant : 8;
		Chantilly : 8;
		WestLine : 16;
	}
}
header_type Lakehills {
	fields {
		Goodwin : 16;
		Alburnett : 16;
	}
}
header_type Neame {
	fields {
		Pinto : 32;
		Burrton : 32;
		Tivoli : 4;
		Chappell : 4;
		Hubbell : 8;
		Miranda : 16;
		Ivyland : 16;
		Naalehu : 16;
	}
}
header_type Stampley {
	fields {
		Freeman : 16;
		BigRock : 16;
	}
}
header_type Wabuska {
	fields {
		Fairlea : 16;
		Rienzi : 16;
		Keener : 8;
		Buenos : 8;
		Accord : 16;
	}
}
header_type Neshaminy {
	fields {
		Craigtown : 48;
		Kenmore : 32;
		Gomez : 48;
		Nisland : 32;
	}
}
header_type Bushland {
	fields {
		Clarion : 1;
		Osman : 1;
		Govan : 1;
		Nowlin : 1;
		Pringle : 1;
		Melrude : 3;
		Dacono : 5;
		Kaufman : 3;
		Waumandee : 16;
	}
}
header_type Rowlett {
	fields {
		Tolleson : 24;
		Berrydale : 8;
	}
}
header_type Gamaliel {
	fields {
		Floyd : 8;
		Farragut : 24;
		Winside : 24;
		BigPlain : 8;
	}
}
header Talmo Kiana;
header Talmo Oakley;
header Murchison Hemet[ 2 ];
@pragma pa_fragment ingress ElkRidge.Shawmut
@pragma pa_fragment egress ElkRidge.Shawmut
header OreCity ElkRidge;
@pragma pa_fragment ingress Bellmead.Shawmut
@pragma pa_fragment egress Bellmead.Shawmut
header OreCity Bellmead;
header Mellott Leona;
header Mellott Lafourche;
header Lakehills Saragosa;
header Lakehills Tillicum;
header Neame Dugger;
header Stampley Blevins;
header Neame Lemont;
header Stampley Novice;
header Gamaliel Corinth;
header Wabuska Paisano;
header Bushland Kingman;
header Bonsall Tekonsha;
header Talmo Earlimart;
parser start {
   return select(current(96, 16)) {
      0xBF00 : Lardo;
      default : Decherd;
   }
}
parser Piqua {
   extract( Tekonsha );
   return Decherd;
}
parser Lardo {
   extract( Earlimart );
   return Piqua;
}
parser Decherd {
   extract( Kiana );
   return select( Kiana.Mabana ) {
      0x8100 : Shoup;
      0x0800 : Russia;
      0x86dd : Ireton;
      0x0806 : Coqui;
      default : ingress;
   }
}
parser Shoup {
   extract( Hemet[0] );
   set_metadata(Frankston.Korbel, 1);
   return select( Hemet[0].Metter ) {
      0x0800 : Russia;
      0x86dd : Ireton;
      0x0806 : Coqui;
      default : ingress;
   }
}
field_list Roseville {
    ElkRidge.Moraine;
    ElkRidge.Kensal;
    ElkRidge.Menomonie;
    ElkRidge.Salix;
    ElkRidge.Chandalar;
    ElkRidge.Ruffin;
    ElkRidge.Amanda;
    ElkRidge.Gillespie;
    ElkRidge.Ignacio;
    ElkRidge.Granville;
    ElkRidge.Hines;
    ElkRidge.Assinippi;
}
field_list_calculation Badger {
    input {
        Roseville;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field ElkRidge.Shawmut {
    verify Badger;
    update Badger;
}
parser Russia {
   extract( ElkRidge );
   set_metadata(Frankston.Readsboro, ElkRidge.Granville);
   set_metadata(Frankston.Issaquah, ElkRidge.Ignacio);
   set_metadata(Frankston.Mullins, ElkRidge.Chandalar);
//   set_metadata(Frankston.Snowball, 0);
   set_metadata(Frankston.Reddell, 1);
   return select(ElkRidge.Gillespie, ElkRidge.Kensal, ElkRidge.Granville) {
      0x501 : Seabrook;
      0x511 : Maybee;
      0x506 : Hesler;
      0 mask 0xFF7000 : ingress;
      default : Moosic;
   }
}
parser Moosic {
   set_metadata(ShadeGap.SanPablo, 1);
   return ingress;
}
parser Ireton {
   extract( Lafourche );
   set_metadata(Frankston.Readsboro, Lafourche.Jarreau);
   set_metadata(Frankston.Issaquah, Lafourche.Rosboro);
   set_metadata(Frankston.Mullins, Lafourche.Moclips);
   set_metadata(Frankston.Snowball, 1);
//   set_metadata(Frankston.Reddell, 0);
   return select(Lafourche.Jarreau) {
      0x3a : Seabrook;
      17 : Maxwelton;
      6 : Hesler;
      default : ingress;
   }
}
parser Coqui {
   extract( Paisano );
   set_metadata(Frankston.Froid, 1);
   return ingress;
}
parser Maybee {
   extract(Saragosa);
   extract(Blevins);
   return select(Saragosa.Alburnett) {
      4789 : Wenona;
      default : ingress;
    }
}
parser Seabrook {
   set_metadata( Saragosa.Goodwin, current( 0, 16 ) );
   set_metadata( Saragosa.Alburnett, 0 );
   return ingress;
}
parser Maxwelton {
   extract(Saragosa);
   extract(Blevins);
   return ingress;
}
parser Hesler {
   set_metadata(Pimento.Coachella, 1);
   extract(Saragosa);
   extract(Dugger);
   return ingress;
}
parser Hilgard {
   set_metadata(Pimento.RedLake, 2);
   return Ivins;
}
parser Magazine {
   set_metadata(Pimento.RedLake, 2);
   return Clarkdale;
}
parser Lilymoor {
   extract(Kingman);
   return select(Kingman.Clarion, Kingman.Osman, Kingman.Govan, Kingman.Nowlin, Kingman.Pringle,
             Kingman.Melrude, Kingman.Dacono, Kingman.Kaufman, Kingman.Waumandee) {
      0x0800 : Hilgard;
      0x86dd : Magazine;
      default : ingress;
   }
}
parser Wenona {
   extract(Corinth);
   set_metadata(Pimento.RedLake, 1);
   return Portales;
}
field_list Ambrose {
    Bellmead.Moraine;
    Bellmead.Kensal;
    Bellmead.Menomonie;
    Bellmead.Salix;
    Bellmead.Chandalar;
    Bellmead.Ruffin;
    Bellmead.Amanda;
    Bellmead.Gillespie;
    Bellmead.Ignacio;
    Bellmead.Granville;
    Bellmead.Hines;
    Bellmead.Assinippi;
}
field_list_calculation Bolckow {
    input {
        Ambrose;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Bellmead.Shawmut {
    verify Bolckow;
    update Bolckow;
}
parser Ivins {
   extract( Bellmead );
   set_metadata(Frankston.Perryton, Bellmead.Granville);
   set_metadata(Frankston.Parchment, Bellmead.Ignacio);
   set_metadata(Frankston.Hansell, Bellmead.Chandalar);
   //set_metadata(Frankston.Maupin, 0);
   set_metadata(Frankston.Bouton, 1);
   return select(Bellmead.Gillespie, Bellmead.Kensal, Bellmead.Granville) {
      0x501 : Leeville;
      0x511 : Ashley;
      0x506 : Uintah;
      0 mask 0xFF7000 : ingress;
      default : Wymore;
   }
}
parser Wymore {
   set_metadata(Pimento.Shipman, 1);
   return ingress;
}
parser Clarkdale {
   extract( Leona );
   set_metadata(Frankston.Perryton, Leona.Jarreau);
   set_metadata(Frankston.Parchment, Leona.Rosboro);
   set_metadata(Frankston.Hansell, Leona.Moclips);
   set_metadata(Frankston.Maupin, 1);
   // set_metadata(Frankston.Bouton, 0);
   return select(Leona.Jarreau) {
      0x3a : Leeville;
      17 : Ashley;
      6 : Uintah;
      default : ingress;
   }
}
parser Leeville {
   set_metadata( Pimento.Salamatof, current( 0, 16 ) );
   set_metadata( Pimento.Hollymead, 1 );
   return ingress;
}
parser Ashley {
   set_metadata( Pimento.Salamatof, current( 0, 16 ) );
   set_metadata( Pimento.Belcher, current( 16, 16 ) );
   set_metadata( Pimento.Hollymead, 1 );
   return ingress;
}
parser Uintah {
   set_metadata( Pimento.Salamatof, current( 0, 16 ) );
   set_metadata( Pimento.Belcher, current( 16, 16 ) );
   set_metadata( Pimento.Tascosa, current( 104, 8 ) );
   set_metadata( Pimento.Hollymead, 1 );
   set_metadata( Pimento.Norseland, 1 );
   extract(Tillicum);
   extract(Lemont);
   return ingress;
}
parser Portales {
   extract( Oakley );
   return select( Oakley.Mabana ) {
      0x0800: Ivins;
      0x86dd: Clarkdale;
      default: ingress;
   }
}
@pragma pa_solitary ingress Pimento.Shipman
@pragma pa_no_init ingress Pimento.Melmore
@pragma pa_no_init ingress Pimento.MudLake
@pragma pa_no_init ingress Pimento.Freeville
@pragma pa_no_init ingress Pimento.Vidal
metadata Hagerman Pimento;
@pragma pa_no_init ingress Ballville.Mynard
@pragma pa_no_init ingress Ballville.Hartford
@pragma pa_no_init ingress Ballville.Twain
@pragma pa_no_init ingress Ballville.Coalton
metadata Thurston Ballville;
metadata Filley Shauck;
metadata SanJon Frankston;
metadata Renick Hisle;
metadata Wolsey CoalCity;
metadata Vestaburg Sabana;
@pragma pa_container_size ingress Sabana.Stratford 32
metadata Maceo ElCentro;
metadata Mackeys Azusa;
metadata Segundo Moreland;
metadata Bridger Sagerton;
metadata Paisley Kensett;
metadata Laneburg Helotes;
metadata Ralph Pavillion;
@pragma pa_no_init ingress Temvik.Muncie
metadata Ivydale Temvik;
@pragma pa_no_init ingress Mossville.Catlin
metadata Loysburg Mossville;
metadata Lincroft ShadeGap;
metadata Lincroft Glouster;
action Mingus() {
   no_op();
}
action Maywood() {
   modify_field(Pimento.Slovan, 1 );
   mark_for_drop();
}
action Roseworth() {
   no_op();
}
action Burden(Larose, Halaula, Felida, WhiteOwl, Monse,
                 Terral, IdaGrove, Sawpit) {
    modify_field(Shauck.Rembrandt, Larose);
    modify_field(Shauck.Newtok, Halaula);
    modify_field(Shauck.Kapaa, Felida);
    modify_field(Shauck.Mayview, WhiteOwl);
    modify_field(Shauck.Allison, Monse);
    modify_field(Shauck.Beaverton, Terral);
    modify_field(Shauck.Perrin, IdaGrove);
    modify_field(Shauck.Hercules, Sawpit);
}

@pragma command_line --no-dead-code-elimination
table Ivanpah {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Burden;
    }
    size : 288;
}
control Leadpoint {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Ivanpah);
    }
}
action Wellton(Kaolin, Parmerton) {
   modify_field( Ballville.Mantee, 1 );
   modify_field( Ballville.VanHorn, Kaolin);
   modify_field( Pimento.Graford, 1 );
   modify_field( Helotes.Cuprum, Parmerton );
}
action Isabela() {
   modify_field( Pimento.McDavid, 1 );
   modify_field( Pimento.Lostwood, 1 );
}
action Rains() {
   modify_field( Pimento.Graford, 1 );
}
action Telephone() {
   modify_field( Pimento.Graford, 1 );
   modify_field( Pimento.Lenapah, 1 );
}
action Quealy() {
   modify_field( Pimento.Canfield, 1 );
}
action Hilbert() {
   modify_field( Pimento.Lostwood, 1 );
}
counter Endeavor {
   type : packets_and_bytes;
   direct : Rocheport;
   min_width: 16;
}
table Rocheport {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Kiana.Eckman : ternary;
      Kiana.Grays : ternary;
   }
   actions {
      Wellton;
      Isabela;
      Rains;
      Quealy;
      Hilbert;
      Telephone;
   }
   size : 1024;
}
action Wanamassa() {
   modify_field( Pimento.Sewanee, 1 );
}
table Burwell {
   reads {
      Kiana.RedLevel : ternary;
      Kiana.Shirley : ternary;
   }
   actions {
      Wanamassa;
   }
   size : 512;
}
control Gunder {
   apply( Rocheport );
   apply( Burwell );
}
action Tecolote() {
   modify_field( Hisle.Hanamaulu, Bellmead.Hines );
   modify_field( Hisle.PineLawn, Bellmead.Assinippi );
   modify_field( Hisle.Ephesus, Bellmead.Menomonie );
   modify_field( CoalCity.ElmPoint, Leona.Laketown );
   modify_field( CoalCity.Saranap, Leona.Borup );
   modify_field( CoalCity.Cuney, Leona.LakePine );
   modify_field( CoalCity.Terry, Leona.HamLake );
   modify_field( Pimento.Melmore, Oakley.Eckman );
   modify_field( Pimento.MudLake, Oakley.Grays );
   modify_field( Pimento.Freeville, Oakley.RedLevel );
   modify_field( Pimento.Vidal, Oakley.Shirley );
   modify_field( Pimento.Newfield, Oakley.Mabana );
   modify_field( Pimento.Dunkerton, Frankston.Hansell );
   modify_field( Pimento.Volcano, Frankston.Perryton );
   modify_field( Pimento.Greycliff, Frankston.Parchment );
   modify_field( Pimento.Gibson, Frankston.Bouton );
   modify_field( Pimento.Capitola, Frankston.Maupin );
   modify_field( Pimento.Buncombe, 0 );
   modify_field( Ballville.Lonepine, 1 );
   modify_field( Shauck.Beaverton, 1 );
   modify_field( Shauck.Perrin, 0 );
   modify_field( Shauck.Hercules, 0 );
   modify_field( Helotes.Livengood, 1 );
   modify_field( Helotes.Franklin, 1 );
   modify_field( ShadeGap.SanPablo, Pimento.Shipman );
   modify_field( Pimento.Coachella, Pimento.Norseland );
}
action Ogunquit() {
   modify_field( Pimento.RedLake, 0 );
   modify_field( Hisle.Hanamaulu, ElkRidge.Hines );
   modify_field( Hisle.PineLawn, ElkRidge.Assinippi );
   modify_field( Hisle.Ephesus, ElkRidge.Menomonie );
   modify_field( CoalCity.ElmPoint, Lafourche.Laketown );
   modify_field( CoalCity.Saranap, Lafourche.Borup );
   modify_field( CoalCity.Cuney, Lafourche.LakePine );
   modify_field( CoalCity.Terry, Lafourche.HamLake );
   modify_field( Pimento.Melmore, Kiana.Eckman );
   modify_field( Pimento.MudLake, Kiana.Grays );
   modify_field( Pimento.Freeville, Kiana.RedLevel );
   modify_field( Pimento.Vidal, Kiana.Shirley );
   modify_field( Pimento.Newfield, Kiana.Mabana );
   modify_field( Pimento.Dunkerton, Frankston.Mullins );
   modify_field( Pimento.Volcano, Frankston.Readsboro );
   modify_field( Pimento.Greycliff, Frankston.Issaquah );
   modify_field( Pimento.Gibson, Frankston.Reddell );
   modify_field( Pimento.Capitola, Frankston.Snowball );
   modify_field( Helotes.McCaulley, Hemet[0].Casselman );
   modify_field( Pimento.Buncombe, Frankston.Korbel );
   modify_field( Pimento.Salamatof, Saragosa.Goodwin );
   modify_field( Pimento.Belcher, Saragosa.Alburnett );
   modify_field( Pimento.Tascosa, Dugger.Hubbell );
}
table Churchill {
   reads {
      Kiana.Eckman : exact;
      Kiana.Grays : exact;
      ElkRidge.Assinippi : exact;
      Pimento.RedLake : exact;
   }
   actions {
      Tecolote;
      Ogunquit;
   }
   default_action : Ogunquit();
   size : 1024;
}
action Nelson() {
   modify_field( Pimento.LaVale, Shauck.Kapaa );
   modify_field( Pimento.BullRun, Shauck.Rembrandt);
}
action Larue( Hartman ) {
   modify_field( Pimento.LaVale, Hartman );
   modify_field( Pimento.BullRun, Shauck.Rembrandt);
}
action Uvalde() {
   modify_field( Pimento.LaVale, Hemet[0].Willamina );
   modify_field( Pimento.BullRun, Shauck.Rembrandt);
}
table Margie {
   reads {
      Shauck.Rembrandt : ternary;
      Hemet[0] : valid;
      Hemet[0].Willamina : ternary;
   }
   actions {
      Nelson;
      Larue;
      Uvalde;
   }
   size : 4096;
}
action Sarasota( Heaton ) {
   modify_field( Pimento.BullRun, Heaton );
}
action Harris() {
   modify_field( Pimento.Solomon, 1 );
   modify_field( Azusa.Daguao,
                 1 );
}
table Rockport {
   reads {
      ElkRidge.Hines : exact;
   }
   actions {
      Sarasota;
      Harris;
   }
   default_action : Harris;
   size : 4096;
}
action Judson( Flaxton, Poteet, Granbury, Fount, Hillside,
                        JaneLew, Handley ) {
   modify_field( Pimento.LaVale, Flaxton );
   modify_field( Pimento.Amonate, Flaxton );
   modify_field( Pimento.Lacona, Handley );
   LaCueva(Poteet, Granbury, Fount, Hillside,
                        JaneLew );
}
action Laclede() {
   modify_field( Pimento.Picabo, 1 );
}
table Overlea {
   reads {
      Corinth.Winside : exact;
   }
   actions {
      Judson;
      Laclede;
   }
   size : 4096;
}
action LaCueva(Goree, McCaskill, Barber, Maury,
                        Toccopola ) {
   modify_field( ElCentro.Colson, Goree );
   modify_field( ElCentro.Lomax, McCaskill );
   modify_field( ElCentro.Alvordton, Barber );
   modify_field( ElCentro.Almelund, Maury );
   modify_field( ElCentro.Lakefield, Toccopola );
}
action Hoadly(Sumner, Goudeau, Danese, Toano,
                        Wauna ) {
   modify_field( Pimento.Amonate, Shauck.Kapaa );
   LaCueva(Sumner, Goudeau, Danese, Toano,
                        Wauna );
}
action Ardsley(Wenden, MuleBarn, Rotterdam, Mangham,
                        Raritan, Sixteen ) {
   modify_field( Pimento.Amonate, Wenden );
   LaCueva(MuleBarn, Rotterdam, Mangham, Raritan,
                        Sixteen );
}
action Hopkins(Saxis, Terlingua, Jackpot, Coronado,
                        Elkville ) {
   modify_field( Pimento.Amonate, Hemet[0].Willamina );
   LaCueva(Saxis, Terlingua, Jackpot, Coronado,
                        Elkville );
}
table McKenney {
   reads {
      Shauck.Kapaa : exact;
   }
   actions {
      Mingus;
      Hoadly;
   }
   size : 4096;
}
@pragma action_default_only Mingus
table Shopville {
   reads {
      Shauck.Rembrandt : exact;
      Hemet[0].Willamina : exact;
   }
   actions {
      Ardsley;
      Mingus;
   }
   size : 1024;
}
table Sutton {
   reads {
      Hemet[0].Willamina : exact;
   }
   actions {
      Mingus;
      Hopkins;
   }
   size : 4096;
}
control Moody {
   apply( Churchill ) {
         Tecolote {
            apply( Rockport );
            apply( Overlea );
         }
         Ogunquit {
            if ( not valid(Tekonsha) and Shauck.Mayview == 1 ) {
               apply( Margie );
            }
            if ( valid( Hemet[ 0 ] ) ) {
               apply( Shopville ) {
                  Mingus {
                     apply( Sutton );
                  }
               }
            } else {
               apply( McKenney );
            }
         }
   }
}
register Traverse {
    width : 1;
    static : Cordell;
    instance_count : 294912;
}
register Allen {
    width : 1;
    static : Yardley;
    instance_count : 294912;
}
blackbox stateful_alu Penalosa {
    reg : Traverse;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : Sabana.Hiland;
}
blackbox stateful_alu Rosburg {
    reg : Allen;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst : Sabana.Stratford;
}
field_list Forepaugh {
    ig_intr_md.ingress_port;
    Hemet[0].Willamina;
}
field_list_calculation Dalkeith {
    input { Forepaugh; }
    algorithm: identity;
    output_width: 19;
}
action McCracken() {
    Penalosa.execute_stateful_alu_from_hash(Dalkeith);
}
action Skyway() {
    Rosburg.execute_stateful_alu_from_hash(Dalkeith);
}
table Cordell {
    actions {
      McCracken;
    }
    default_action : McCracken;
    size : 1;
}
table Yardley {
    actions {
      Skyway;
    }
    default_action : Skyway;
    size : 1;
}
action Weatherly(Brohard) {
    modify_field(Sabana.Stratford, Brohard);
}
@pragma use_hash_action 0
table Bigspring {
    reads {
       ig_intr_md.ingress_port mask 0x7f : exact;
    }
    actions {
      Weatherly;
    }
    size : 72;
}
action Eskridge() {
   modify_field( Pimento.Ackley, Shauck.Kapaa );
   modify_field( Pimento.Malinta, 0 );
}
table Westview {
   actions {
      Eskridge;
   }
   size : 1;
}
action Creston() {
   modify_field( Pimento.Ackley, Hemet[0].Willamina );
   modify_field( Pimento.Malinta, 1 );
}
table Darden {
   actions {
      Creston;
   }
   size : 1;
}
control Bonner {
   if ( valid( Hemet[ 0 ] ) ) {
      apply( Darden );
      if( Shauck.Allison == 1 ) {
         apply( Cordell );
         apply( Yardley );
      }
   } else {
      apply( Westview );
      if( Shauck.Allison == 1 ) {
         apply( Bigspring );
      }
   }
}
field_list Bains {
   Kiana.Eckman;
   Kiana.Grays;
   Kiana.RedLevel;
   Kiana.Shirley;
   Kiana.Mabana;
}
field_list Deeth {
   ElkRidge.Granville;
   ElkRidge.Hines;
   ElkRidge.Assinippi;
}
field_list Strevell {
   Lafourche.Laketown;
   Lafourche.Borup;
   Lafourche.LakePine;
   Lafourche.Jarreau;
}
field_list Minturn {
   ElkRidge.Hines;
   ElkRidge.Assinippi;
   Saragosa.Goodwin;
   Saragosa.Alburnett;
}
field_list_calculation Cargray {
    input {
        Bains;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Dubbs {
    input {
        Deeth;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Westbury {
    input {
        Strevell;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Calimesa {
    input {
        Minturn;
    }
    algorithm : crc32;
    output_width : 32;
}
action RedElm() {
    modify_field_with_hash_based_offset(Kensett.Amber, 0,
                                        Cargray, 4294967296);
}
action WindGap() {
    modify_field_with_hash_based_offset(Kensett.Heron, 0,
                                        Dubbs, 4294967296);
}
action Troup() {
    modify_field_with_hash_based_offset(Kensett.Heron, 0,
                                        Westbury, 4294967296);
}
action Sunflower() {
    modify_field_with_hash_based_offset(Kensett.Mattawan, 0,
                                        Calimesa, 4294967296);
}
table Senatobia {
   actions {
      RedElm;
   }
   size: 1;
}
control Stonefort {
   apply(Senatobia);
}
table Paradis {
   actions {
      WindGap;
   }
   size: 1;
}
table Eaton {
   actions {
      Troup;
   }
   size: 1;
}
control Midas {
   if ( valid( ElkRidge ) ) {
      apply(Paradis);
   } else {
      if ( valid( Lafourche ) ) {
         apply(Eaton);
      }
   }
}
table Micro {
   actions {
      Sunflower;
   }
   size: 1;
}
control Courtdale {
   if ( valid( Blevins ) ) {
      apply(Micro);
   }
}
action Parthenon() {
    modify_field(Sagerton.Haverford, Kensett.Amber);
}
action Blitchton() {
    modify_field(Sagerton.Haverford, Kensett.Heron);
}
action Clearmont() {
    modify_field(Sagerton.Haverford, Kensett.Mattawan);
}
@pragma action_default_only Mingus
@pragma immediate 0
table Wymer {
   reads {
      Lemont.valid : ternary;
      Novice.valid : ternary;
      Bellmead.valid : ternary;
      Leona.valid : ternary;
      Oakley.valid : ternary;
      Dugger.valid : ternary;
      Blevins.valid : ternary;
      ElkRidge.valid : ternary;
      Lafourche.valid : ternary;
      Kiana.valid : ternary;
   }
   actions {
      Parthenon;
      Blitchton;
      Clearmont;
      Mingus;
   }
   size: 256;
}
action Speedway() {
    modify_field(Sagerton.Dwight, Kensett.Mattawan);
}
@pragma immediate 0
table Wyandanch {
   reads {
      Lemont.valid : ternary;
      Novice.valid : ternary;
      Dugger.valid : ternary;
      Blevins.valid : ternary;
   }
   actions {
      Speedway;
      Mingus;
   }
   size: 6;
}
control Colfax {
   apply(Wyandanch);
   apply(Wymer);
}
counter Sherrill {
   type : packets_and_bytes;
   direct : Longview;
   min_width: 16;
}
table Longview {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Sabana.Stratford : ternary;
      Sabana.Hiland : ternary;
      Pimento.Picabo : ternary;
      Pimento.Sewanee : ternary;
      Pimento.McDavid : ternary;
   }
   actions {
      Maywood;
      Mingus;
   }
   default_action : Mingus();
   size : 512;
}
table Perryman {
   reads {
      Pimento.Freeville : exact;
      Pimento.Vidal : exact;
      Pimento.LaVale : exact;
   }
   actions {
      Maywood;
      Mingus;
   }
   default_action : Mingus();
   size : 4096;
}
action Sudden() {
   modify_field(Pimento.Aldan, 1 );
   modify_field(Azusa.Daguao,
                0);
}
table Hodges {
   reads {
      Pimento.Freeville : exact;
      Pimento.Vidal : exact;
      Pimento.LaVale : exact;
      Pimento.BullRun : exact;
   }
   actions {
      Roseworth;
      Sudden;
   }
   default_action : Sudden();
   size : 65536;
   support_timeout : true;
}
action Millwood( Elmore, Wimbledon ) {
   modify_field( Pimento.Fairfield, Elmore );
   modify_field( Pimento.Lacona, Wimbledon );
}
action Grasmere() {
   modify_field( Pimento.Lacona, 1 );
}
table Thurmond {
   reads {
      Pimento.LaVale mask 0xfff : exact;
   }
   actions {
      Millwood;
      Grasmere;
      Mingus;
   }
   default_action : Mingus();
   size : 4096;
}
action Salamonia() {
   modify_field( ElCentro.CedarKey, 1 );
}
table Beaufort {
   reads {
      Pimento.Amonate : ternary;
      Pimento.Melmore : exact;
      Pimento.MudLake : exact;
   }
   actions {
      Salamonia;
   }
   size: 512;
}
control Dunedin {
   apply( Longview ) {
      Mingus {
         apply( Perryman ) {
            Mingus {
               if (Shauck.Newtok == 0 and Pimento.Solomon == 0) {
                  apply( Hodges );
               }
               apply( Thurmond );
               apply(Beaufort);
            }
         }
      }
   }
}
field_list RioPecos {
    Azusa.Daguao;
    Pimento.Freeville;
    Pimento.Vidal;
    Pimento.LaVale;
    Pimento.BullRun;
}
action Jessie() {
   generate_digest(0, RioPecos);
}
table HillTop {
   actions {
      Jessie;
   }
   size : 1;
}
control Thermal {
   if (Pimento.Aldan == 1) {
      apply( HillTop );
   }
}
action Yardville( Chatanika, Armstrong ) {
   modify_field( CoalCity.Fosters, Chatanika );
   modify_field( Moreland.Duque, Armstrong );
}
action Boyes( Comfrey, BarNunn ) {
   modify_field( CoalCity.Fosters, Comfrey );
   modify_field( Moreland.Provencal, BarNunn );
}
@pragma action_default_only Chewalla
table Thalia {
   reads {
      ElCentro.Colson : exact;
      CoalCity.Saranap mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Yardville;
      Chewalla;
      Boyes;
   }
   size : 8192;
}
@pragma atcam_partition_index CoalCity.Fosters
@pragma atcam_number_partitions 8192
table McHenry {
   reads {
      CoalCity.Fosters : exact;
      CoalCity.Saranap mask 0x000007FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Gilliam;
      Twinsburg;
      Mingus;
   }
   default_action : Mingus();
   size : 65536;
}
action Southdown( Bremond, Cooter ) {
   modify_field( CoalCity.Yaurel, Bremond );
   modify_field( Moreland.Duque, Cooter );
}
action Sublimity( Roberts, Lenwood ) {
   modify_field( CoalCity.Yaurel, Roberts );
   modify_field( Moreland.Provencal, Lenwood );
}
@pragma action_default_only Mingus
table LakeFork {
   reads {
      ElCentro.Colson : exact;
      CoalCity.Saranap : lpm;
   }
   actions {
      Southdown;
      Sublimity;
      Mingus;
   }
   size : 2048;
}
@pragma atcam_partition_index CoalCity.Yaurel
@pragma atcam_number_partitions 2048
table Florin {
   reads {
      CoalCity.Yaurel : exact;
      CoalCity.Saranap mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Gilliam;
      Twinsburg;
      Mingus;
   }
   default_action : Mingus();
   size : 16384;
}
@pragma action_default_only Chewalla
@pragma idletime_precision 1
table DeSmet {
   reads {
      ElCentro.Colson : exact;
      Hisle.PineLawn : lpm;
   }
   actions {
      Gilliam;
      Twinsburg;
      Chewalla;
   }
   size : 1024;
   support_timeout : true;
}
action Twisp( Lopeno, Radom ) {
   modify_field( Hisle.Trion, Lopeno );
   modify_field( Moreland.Duque, Radom );
}
action Globe( Slayden, LeMars ) {
   modify_field( Hisle.Trion, Slayden );
   modify_field( Moreland.Provencal, LeMars );
}
@pragma action_default_only Mingus
table Halley {
   reads {
      ElCentro.Colson : exact;
      Hisle.PineLawn : lpm;
   }
   actions {
      Twisp;
      Globe;
      Mingus;
   }
   size : 16384;
}
@pragma ways 2
@pragma atcam_partition_index Hisle.Trion
@pragma atcam_number_partitions 16384
table Sturgis {
   reads {
      Hisle.Trion : exact;
      Hisle.PineLawn mask 0x000fffff : lpm;
   }
   actions {
      Gilliam;
      Twinsburg;
      Mingus;
   }
   default_action : Mingus();
   size : 131072;
}
action Gilliam( Nuevo ) {
   modify_field( Moreland.Duque, Nuevo );
}
@pragma idletime_precision 1
table Geneva {
   reads {
      ElCentro.Colson : exact;
      Hisle.PineLawn : exact;
   }
   actions {
      Gilliam;
      Twinsburg;
      Mingus;
   }
   default_action : Mingus();
   size : 65536;
   support_timeout : true;
}
@pragma idletime_precision 1
@pragma stage 2 28672
@pragma stage 3
table Council {
   reads {
      ElCentro.Colson : exact;
      CoalCity.Saranap : exact;
   }
   actions {
      Gilliam;
      Twinsburg;
      Mingus;
   }
   default_action : Mingus();
   size : 65536;
   support_timeout : true;
}
action Plains(Roxobel, Blakeman, Cullen) {
   modify_field(Ballville.Pineland, Cullen);
   modify_field(Ballville.Mynard, Roxobel);
   modify_field(Ballville.Hartford, Blakeman);
   modify_field(Ballville.Indios, 1);
   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}
action Wisdom() {
   Maywood();
}
action Etter(Ribera) {
   modify_field(Ballville.Mantee, 1);
   modify_field(Ballville.VanHorn, Ribera);
}
action Chewalla(Chamois) {
   modify_field( Ballville.Mantee, 1 );
   modify_field( Ballville.VanHorn, 9 );
}
table Secaucus {
   reads {
      Moreland.Duque : exact;
   }
   actions {
      Plains;
      Wisdom;
      Etter;
   }
   size : 65536;
}
action Vernal( Kosciusko ) {
   modify_field(Ballville.Mantee, 1);
   modify_field(Ballville.VanHorn, Kosciusko);
}
table Pricedale {
   actions {
      Vernal;
   }
   default_action: Vernal(0);
   size : 1;
}
control Bayshore {
   if ( Pimento.Slovan == 0 and ElCentro.CedarKey == 1 ) {
      if ( ( ElCentro.Lomax == 1 ) and ( Pimento.Gibson == 1 ) ) {
         apply( Geneva ) {
            Mingus {
               apply(Halley);
            }
         }
      } else if ( ( ElCentro.Alvordton == 1 ) and ( Pimento.Capitola == 1 ) ) {
         apply( Council ) {
            Mingus {
               apply( LakeFork );
            }
         }
      }
   }
}
control Edmondson {
   if ( Pimento.Slovan == 0 and ElCentro.CedarKey == 1 ) {
      if ( ( ElCentro.Lomax == 1 ) and ( Pimento.Gibson == 1 ) ) {
         if ( Hisle.Trion != 0 ) {
            apply( Sturgis );
         } else if ( Moreland.Duque == 0 and Moreland.Provencal == 0 ) {
            apply( DeSmet );
         }
      } else if ( ( ElCentro.Alvordton == 1 ) and ( Pimento.Capitola == 1 ) ) {
         if ( CoalCity.Yaurel != 0 ) {
            apply( Florin );
         } else if ( Moreland.Duque == 0 and Moreland.Provencal == 0 ) {
            apply( Thalia );
            if ( CoalCity.Fosters != 0 ) {
               apply( McHenry );
            }
         }
      } else if( Pimento.Lacona == 1 ) {
         apply( Pricedale );
      }
   }
}
control Dunnville {
   if( Moreland.Duque != 0 ) {
      apply( Secaucus );
   }
}
action Twinsburg( Lawnside ) {
   modify_field( Moreland.Provencal, Lawnside );
}
field_list Bells {
   Sagerton.Dwight;
}
field_list_calculation Masardis {
    input {
        Bells;
    }
    algorithm : identity;
    output_width : 66;
}
action_selector Marie {
   selection_key : Masardis;
   selection_mode : resilient;
}
action_profile Ackerly {
   actions {
      Gilliam;
   }
   size : 65536;
   dynamic_action_selection : Marie;
}
@pragma selector_max_group_size 256
table Vinemont {
   reads {
      Moreland.Provencal : exact;
   }
   action_profile : Ackerly;
   size : 2048;
}
control Lushton {
   if ( Moreland.Provencal != 0 ) {
      apply( Vinemont );
   }
}
field_list Tamaqua {
   Sagerton.Haverford;
}
field_list_calculation Meeker {
    input {
        Tamaqua;
    }
    algorithm : identity;
    output_width : 51;
}
action_selector Harriston {
    selection_key : Meeker;
    selection_mode : resilient;
}
action Blencoe(Humacao) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Humacao);
}
action_profile Luzerne {
    actions {
        Blencoe;
        Mingus;
    }
    size : 1024;
    dynamic_action_selection : Harriston;
}
table Oregon {
   reads {
      Ballville.Chenequa : exact;
   }
   action_profile: Luzerne;
   size : 1024;
}
control Arkoe {
   if ((Ballville.Chenequa & 0x2000) == 0x2000) {
      apply(Oregon);
   }
}
action Taconite() {
   modify_field(Ballville.Mynard, Pimento.Melmore);
   modify_field(Ballville.Hartford, Pimento.MudLake);
   modify_field(Ballville.Twain, Pimento.Freeville);
   modify_field(Ballville.Coalton, Pimento.Vidal);
   modify_field(Ballville.Pineland, Pimento.LaVale);
   invalidate( ig_intr_md_for_tm.ucast_egress_port );
}
table Ottertail {
   actions {
      Taconite;
   }
   default_action : Taconite();
   size : 1;
}
control Piedmont {
   apply( Ottertail );
}
action Sieper() {
   modify_field(Ballville.Anchorage, 1);
   modify_field(Ballville.BlackOak, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Pimento.Lacona);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Ballville.Pineland);
}
action Yorkshire() {
}
@pragma ways 1
table Epsie {
   reads {
      Ballville.Mynard : exact;
      Ballville.Hartford : exact;
   }
   actions {
      Sieper;
      Yorkshire;
   }
   default_action : Yorkshire;
   size : 1;
}
action Rhodell() {
   modify_field(Ballville.Airmont, 1);
   modify_field(Ballville.Nuyaka, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Ballville.Pineland, 4096);
}
table Broadmoor {
   actions {
      Rhodell;
   }
   default_action : Rhodell;
   size : 1;
}
action Elwyn() {
   modify_field(Ballville.Coulee, 1);
   modify_field(Ballville.BlackOak, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Ballville.Pineland);
}
table Protivin {
   actions {
      Elwyn;
   }
   default_action : Elwyn();
   size : 1;
}
action Kevil(Strasburg) {
   modify_field(Ballville.PoleOjea, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Strasburg);
   modify_field(Ballville.Chenequa, Strasburg);
}
action GlenAvon(Caban) {
   modify_field(Ballville.Airmont, 1);
   modify_field(Ballville.Hanapepe, Caban);
}
action Duster() {
}
table Abraham {
   reads {
      Ballville.Mynard : exact;
      Ballville.Hartford : exact;
      Ballville.Pineland : exact;
   }
   actions {
      Kevil;
      GlenAvon;
      Maywood;
      Duster;
   }
   default_action : Duster();
   size : 65536;
}
control Calvary {
   if (Pimento.Slovan == 0 and not valid(Tekonsha) ) {
      apply(Abraham) {
         Duster {
            apply(Epsie) {
               Yorkshire {
                  if ((Ballville.Mynard & 0x010000) == 0x010000) {
                     apply(Broadmoor);
                  } else {
                     apply(Protivin);
                  }
               }
            }
         }
      }
   }
}
action Kinter() {
   modify_field(Pimento.Claypool, 1);
   Maywood();
}
table Turkey {
   actions {
      Kinter;
   }
   default_action : Kinter;
   size : 1;
}
control Yorklyn {
   if (Pimento.Slovan == 0) {
      if ((Ballville.Indios==0) and (Pimento.Graford==0) and (Pimento.Canfield==0) and (Pimento.BullRun==Ballville.Chenequa)) {
         apply(Turkey);
      } else {
         Arkoe();
      }
   }
}
action Hammonton( Shoshone ) {
   modify_field( Ballville.Hansboro, Shoshone );
}
action RockPort() {
   modify_field( Ballville.Hansboro, Ballville.Pineland );
}
table Cowles {
   reads {
      eg_intr_md.egress_port : exact;
      Ballville.Pineland : exact;
   }
   actions {
      Hammonton;
      RockPort;
   }
   default_action : RockPort;
   size : 4096;
}
control Plateau {
   apply( Cowles );
}
action Aguilita( Berkey, Goldsmith ) {
   modify_field( Ballville.Belfalls, Berkey );
   modify_field( Ballville.Norias, Goldsmith );
}
table Sylva {
   reads {
      Ballville.Wrens : exact;
   }
   actions {
      Aguilita;
   }
   size : 8;
}
action Falls() {
   modify_field( Ballville.Upland, 1 );
   modify_field( Ballville.Wrens, 2 );
}
action Sidon() {
   modify_field( Ballville.Upland, 1 );
   modify_field( Ballville.Wrens, 1 );
}
table Liberal {
   reads {
      Ballville.Blackwood : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Falls;
      Sidon;
   }
   default_action : Mingus();
   size : 16;
}
action Wheeler(Engle, WoodDale, Carpenter, Newhalen) {
   modify_field( Ballville.Calverton, Engle );
   modify_field( Ballville.Folcroft, WoodDale );
   modify_field( Ballville.Barclay, Carpenter );
   modify_field( Ballville.Yerington, Newhalen );
}
table Lovelady {
   reads {
        Ballville.Recluse : exact;
   }
   actions {
      Wheeler;
   }
   size : 256;
}
action Puryear() {
   no_op();
}
action Hydaburg() {
   modify_field( Kiana.Mabana, Hemet[0].Metter );
   remove_header( Hemet[0] );
}
table Draketown {
   actions {
      Hydaburg;
   }
   default_action : Hydaburg;
   size : 1;
}
action Firebrick() {
   no_op();
}
action Guaynabo() {
   add_header( Hemet[ 0 ] );
   modify_field( Hemet[0].Willamina, Ballville.Hansboro );
   modify_field( Hemet[0].Metter, Kiana.Mabana );
   modify_field( Hemet[0].Cassa, Helotes.Tuckerton );
   modify_field( Hemet[0].Casselman, Helotes.McCaulley );
   modify_field( Kiana.Mabana, 0x8100 );
}
table Quinault {
   reads {
      Ballville.Hansboro : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Firebrick;
      Guaynabo;
   }
   default_action : Guaynabo;
   size : 128;
}
action Dagmar() {
   modify_field(Kiana.Eckman, Ballville.Mynard);
   modify_field(Kiana.Grays, Ballville.Hartford);
   modify_field(Kiana.RedLevel, Ballville.Belfalls);
   modify_field(Kiana.Shirley, Ballville.Norias);
}
action Ontonagon() {
   Dagmar();
   add_to_field(ElkRidge.Ignacio, -1);
   modify_field(ElkRidge.Menomonie, Helotes.Naubinway);
}
action Roscommon() {
   Dagmar();
   add_to_field(Lafourche.Rosboro, -1);
   modify_field(Lafourche.HamLake, Helotes.Naubinway);
}
action Coconino() {
   modify_field(ElkRidge.Menomonie, Helotes.Naubinway);
}
action Bovina() {
   modify_field(Lafourche.HamLake, Helotes.Naubinway);
}
action Rockleigh() {
   Guaynabo();
}
action Waitsburg( Kittredge, Whitewood, Biehle, Claunch ) {
   add_header( Earlimart );
   modify_field( Earlimart.Eckman, Kittredge );
   modify_field( Earlimart.Grays, Whitewood );
   modify_field( Earlimart.RedLevel, Biehle );
   modify_field( Earlimart.Shirley, Claunch );
   modify_field( Earlimart.Mabana, 0xBF00 );
   add_header( Tekonsha );
   modify_field( Tekonsha.Spiro, Ballville.Calverton );
   modify_field( Tekonsha.Hurst, Ballville.Folcroft );
   modify_field( Tekonsha.Sawyer, Ballville.Barclay );
   modify_field( Tekonsha.Dumas, Ballville.Yerington );
   modify_field( Tekonsha.Donna, Ballville.VanHorn );
}
action Duffield() {
   remove_header( Corinth );
   remove_header( Blevins );
   remove_header( Saragosa );
   copy_header( Kiana, Oakley );
   remove_header( Oakley );
   remove_header( ElkRidge );
}
action Menfro() {
   remove_header( Earlimart );
   remove_header( Tekonsha );
}
action Cliffs() {
   Duffield();
   modify_field(Bellmead.Menomonie, Helotes.Naubinway);
}
action Slinger() {
   Duffield();
   modify_field(Leona.HamLake, Helotes.Naubinway);
}
table Algodones {
   reads {
      Ballville.Lonepine : exact;
      Ballville.Wrens : exact;
      Ballville.Indios : exact;
      ElkRidge.valid : ternary;
      Lafourche.valid : ternary;
      Bellmead.valid : ternary;
      Leona.valid : ternary;
   }
   actions {
      Ontonagon;
      Roscommon;
      Coconino;
      Bovina;
      Rockleigh;
      Waitsburg;
      Menfro;
      Duffield;
      Cliffs;
      Slinger;
   }
   size : 512;
}
control Genola {
   apply( Draketown );
}
control Windber {
   apply( Quinault );
}
control Merkel {
   apply( Liberal ) {
      Mingus {
         apply( Sylva );
      }
   }
   apply( Lovelady );
   apply( Algodones );
}
field_list CityView {
    Azusa.Daguao;
    Pimento.LaVale;
    Oakley.RedLevel;
    Oakley.Shirley;
    ElkRidge.Hines;
}
action Immokalee() {
   generate_digest(0, CityView);
}
table LaSalle {
   actions {
      Immokalee;
   }
   default_action : Immokalee;
   size : 1;
}
control Lizella {
   if (Pimento.Solomon == 1) {
      apply(LaSalle);
   }
}
action Callao() {
   modify_field( Helotes.Tuckerton, Shauck.Perrin );
}
action Hohenwald() {
   modify_field( Helotes.Tuckerton, Hemet[0].Cassa );
   modify_field( Pimento.Newfield, Hemet[0].Metter );
}
action Connell() {
   modify_field( Helotes.Naubinway, Shauck.Hercules );
}
action Curtin() {
   modify_field( Helotes.Naubinway, Hisle.Ephesus );
}
action Blanchard() {
   modify_field( Helotes.Naubinway, CoalCity.Terry );
}
action Drifton( Westvaco, Waterflow ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Westvaco );
   modify_field( ig_intr_md_for_tm.qid, Waterflow );
}
table Thatcher {
   reads {
     Pimento.Buncombe : exact;
   }
   actions {
     Callao;
     Hohenwald;
   }
   size : 2;
}
table Virden {
   reads {
     Pimento.Gibson : exact;
     Pimento.Capitola : exact;
   }
   actions {
     Connell;
     Curtin;
     Blanchard;
   }
   size : 3;
}
table Breda {
   reads {
      Shauck.Beaverton : ternary;
      Shauck.Perrin : ternary;
      Helotes.Tuckerton : ternary;
      Helotes.Naubinway : ternary;
      Helotes.Cuprum : ternary;
   }
   actions {
      Drifton;
   }
   size : 81;
}
action Levasy( PineCity, Waimalu ) {
   bit_or( Helotes.Livengood, Helotes.Livengood, PineCity );
   bit_or( Helotes.Franklin, Helotes.Franklin, Waimalu );
}
table Quivero {
   actions {
      Levasy;
   }
   default_action : Levasy(0, 0);
   size : 1;
}
action Taneytown( Topton ) {
   modify_field( Helotes.Naubinway, Topton );
}
action Rollins( Hernandez ) {
   modify_field( Helotes.Tuckerton, Hernandez );
}
action OldMinto( Cochise, Wainaku ) {
   modify_field( Helotes.Tuckerton, Cochise );
   modify_field( Helotes.Naubinway, Wainaku );
}
table RioLinda {
   reads {
      Shauck.Beaverton : exact;
      Helotes.Livengood : exact;
      Helotes.Franklin : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Taneytown;
      Rollins;
      OldMinto;
   }
   size : 512;
}
control Opelousas {
   apply( Thatcher );
   apply( Virden );
}
control Fries {
   apply( Breda );
}
control Powelton {
   apply( Quivero );
   apply( RioLinda );
}
action Storden( EastDuke ) {
   modify_field( Helotes.Jacobs, EastDuke );
}
action Whigham( Tinsman, Counce ) {
   Storden( Tinsman );
   modify_field( ig_intr_md_for_tm.qid, Counce );
}
table Fitzhugh {
   reads {
      Ballville.Mantee : ternary;
      ig_intr_md_for_tm.copy_to_cpu : ternary;
      Ballville.VanHorn : ternary;
      Pimento.Gibson : ternary;
      Pimento.Capitola : ternary;
      Pimento.Newfield : ternary;
      Pimento.Volcano : ternary;
      Pimento.Greycliff : ternary;
      Ballville.Indios : ternary;
      Saragosa.Goodwin : ternary;
      Saragosa.Alburnett : ternary;
   }
   actions {
      Storden;
      Whigham;
   }
   size : 512;
}
meter Newberg {
   type : packets;
   static : Gheen;
   instance_count : 2304;
}
action Picacho(Schleswig) {
   execute_meter( Newberg, Schleswig, ig_intr_md_for_tm.packet_color );
}
table Gheen {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Helotes.Jacobs : exact;
   }
   actions {
      Picacho;
   }
   size : 2304;
}
counter Tallevast {
   type : packets;
   instance_count : 32;
   min_width : 128;
}
action Tamms() {
   count( Tallevast, Helotes.Jacobs );
}
table Raven {
   actions {
     Tamms;
   }
   default_action : Tamms;
   size : 1;
}
control Belen {
    if ( (
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x1 ) == 0 ) ) and ( Ballville.Mantee == 1 ) ) or
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x2 ) == 0 ) ) and ( ig_intr_md_for_tm.copy_to_cpu == 1 ) )
       ) ) {
      apply( Gheen );
      apply( Raven );
   }
}
action Anvik( Hollyhill ) {
   modify_field( Ballville.Blackwood, 0 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Hollyhill );
   modify_field( Ballville.Recluse, ig_intr_md.ingress_port );
}
action Faulkner( Brawley ) {
   modify_field( Ballville.Blackwood, 1 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Brawley );
   modify_field( Ballville.Recluse, ig_intr_md.ingress_port );
}
action Talkeetna() {
   modify_field( Ballville.Blackwood, 0 );
}
action Marlton() {
   modify_field( Ballville.Blackwood, 1 );
   modify_field( Ballville.Recluse, ig_intr_md.ingress_port );
}
@pragma ternary 1
table Richwood {
   reads {
      Ballville.Mantee : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      ElCentro.CedarKey : exact;
      Shauck.Mayview : ternary;
      Ballville.VanHorn : ternary;
   }
   actions {
      Anvik;
      Faulkner;
      Talkeetna;
      Marlton;
   }
   size : 512;
}
control Biloxi {
   apply( Richwood );
}
counter SeaCliff {
   type : packets_and_bytes;
   instance_count : 1024;
   min_width : 128;
}
action Scotland( Barron ) {
   count( SeaCliff, Barron );
}
table OakLevel {
   reads {
      eg_intr_md.egress_port mask 0x7f: exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }
   actions {
     Scotland;
   }
   size : 1024;
}
control Orlinda {
   apply( OakLevel );
}
action Bicknell()
{
   Maywood();
}
action Grabill()
{
   modify_field(Ballville.Lonepine, 2);
   bit_or(Ballville.Chenequa, 0x2000, Tekonsha.Dumas);
}
action Mabelvale( Trotwood ) {
   modify_field(Ballville.Lonepine, 2);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Trotwood);
   modify_field(Ballville.Chenequa, Trotwood);
}
table Akiachak {
   reads {
      Tekonsha.Spiro : exact;
      Tekonsha.Hurst : exact;
      Tekonsha.Sawyer : exact;
      Tekonsha.Dumas : exact;
   }
   actions {
      Grabill;
      Mabelvale;
      Bicknell;
   }
   default_action : Bicknell();
   size : 256;
}
control Conner {
   apply( Akiachak );
}
action Cadwell( Ellinger, Caguas, Portis, Corinne ) {
   modify_field( Pavillion.Kalaloch, Ellinger );
   modify_field( Mossville.Bridgton, Portis );
   modify_field( Mossville.Catlin, Caguas );
   modify_field( Mossville.Heflin, Corinne );
}
table Shamokin {
   reads {
     Hisle.PineLawn : exact;
     Pimento.Amonate : exact;
   }
   actions {
      Cadwell;
   }
  size : 16384;
}
action Wattsburg(RioHondo, Thomas, Corum) {
   modify_field( Mossville.Catlin, RioHondo );
   modify_field( Mossville.Bridgton, Thomas );
   modify_field( Mossville.Heflin, Corum );
}
table Oskaloosa {
   reads {
     Hisle.Hanamaulu : exact;
     Pavillion.Kalaloch : exact;
   }
   actions {
      Wattsburg;
   }
   size : 16384;
}
action Colona( Washta, Radcliffe, Kipahulu ) {
   modify_field( Temvik.Muncie, Washta );
   modify_field( Temvik.Beatrice, Radcliffe );
   modify_field( Temvik.McManus, Kipahulu );
}
table Gould {
   reads {
     Ballville.Mynard : exact;
     Ballville.Hartford : exact;
     Ballville.Pineland : exact;
   }
   actions {
      Colona;
   }
   size : 16384;
}
action Bairoa() {
   modify_field( Ballville.BlackOak, 1 );
}
action Rushton( Galloway, Cavalier ) {
   Bairoa();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Mossville.Catlin );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Galloway, Mossville.Heflin );
   bit_or( Helotes.Jacobs, Helotes.Jacobs, Cavalier );
}
action Mahopac( Amalga, Pelion ) {
   Bairoa();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Temvik.Muncie );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Amalga, Temvik.McManus );
   bit_or( Helotes.Jacobs, Helotes.Jacobs, Pelion );
}
action BelAir( Ruston, Elkton ) {
   Bairoa();
   add( ig_intr_md_for_tm.mcast_grp_a, Ballville.Pineland,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Ruston );
   bit_or( Helotes.Jacobs, Helotes.Jacobs, Elkton );
}
action Chaires() {
   modify_field( Ballville.Keltys, 1 );
}
table Billett {
   reads {
     Mossville.Bridgton : ternary;
     Mossville.Catlin : ternary;
     Temvik.Muncie : ternary;
     Temvik.Beatrice : ternary;
     Pimento.Volcano :ternary;
     Pimento.Graford:ternary;
   }
   actions {
      Rushton;
      Mahopac;
      BelAir;
      Chaires;
   }
   size : 32;
}
control Ricketts {
   if( Pimento.Slovan == 0 and
       ElCentro.Almelund == 1 and
       Pimento.Lenapah == 1 ) {
      apply( Shamokin );
   }
}
control Domingo {
   if( Pavillion.Kalaloch != 0 ) {
      apply( Oskaloosa );
   }
}
control Tappan {
   if( Pimento.Slovan == 0 and Pimento.Graford==1 ) {
      apply( Gould );
   }
}
action Welaka(Akhiok) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Sagerton.Haverford );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Akhiok );
}
table Poipu {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Welaka;
    }
    size : 512;
}
control Barnsdall {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Poipu);
   }
}
action Nightmute( Boydston, Thach ) {
   modify_field( Ballville.Pineland, Boydston );
   modify_field( Ballville.Indios, Thach );
}
action Stehekin() {
   drop();
}
table Malabar {
   reads {
     eg_intr_md.egress_rid: exact;
   }
   actions {
      Nightmute;
   }
   default_action: Stehekin;
   size : 57344;
}
control Tobique {
   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Malabar);
   }
}
counter Ironside {
   type : packets;
   direct: Kasigluk;
   min_width: 63;
}
table Kasigluk {
   reads {
     Panacea.Hitterdal mask 0x7fff : exact;
   }
   actions {
      Mingus;
   }
   default_action: Mingus();
   size : 32768;
}
action RedCliff() {
   modify_field( ShadeGap.Ridgewood, Pimento.Volcano );
   modify_field( ShadeGap.Leflore, Hisle.Ephesus );
   modify_field( ShadeGap.Linganore, Pimento.Greycliff );
   modify_field( ShadeGap.Westhoff, Pimento.Tascosa );
}
action Brundage() {
   modify_field( ShadeGap.Ridgewood, Pimento.Volcano );
   modify_field( ShadeGap.Leflore, CoalCity.Terry );
   modify_field( ShadeGap.Linganore, Pimento.Greycliff );
   modify_field( ShadeGap.Westhoff, Pimento.Tascosa );
}
action Freeburg( Goodlett ) {
   RedCliff();
   modify_field( ShadeGap.Sonestown, Goodlett );
}
action Silva( Starkey ) {
   Brundage();
   modify_field( ShadeGap.Sonestown, Starkey );
}
table Colstrip {
   reads {
     Hisle.Hanamaulu : ternary;
   }
   actions {
      Freeburg;
   }
   default_action : RedCliff;
  size : 2048;
}
table Almont {
   reads {
     CoalCity.ElmPoint : ternary;
   }
   actions {
      Silva;
   }
   default_action : Brundage;
   size : 1024;
}
action Sofia( Morita ) {
   modify_field( ShadeGap.Justice, Morita );
}
table FarrWest {
   reads {
     Hisle.PineLawn : ternary;
   }
   actions {
      Sofia;
   }
   size : 512;
}
table NantyGlo {
   reads {
     CoalCity.Saranap : ternary;
   }
   actions {
      Sofia;
   }
   size : 512;
}
action Daphne( Oskawalik ) {
   modify_field( ShadeGap.Hokah, Oskawalik );
}
table Jelloway {
   reads {
     Pimento.Salamatof : ternary;
   }
   actions {
      Daphne;
   }
   size : 512;
}
action Mertens( Holcut ) {
   modify_field( ShadeGap.Gordon, Holcut );
}
table Burnett {
   reads {
     Pimento.Belcher : ternary;
   }
   actions {
      Mertens;
   }
   size : 512;
}
action Slocum( Odell ) {
   modify_field( ShadeGap.Corbin, Odell );
}
action Chalco( Juneau ) {
   modify_field( ShadeGap.Corbin, Juneau );
}
table Francisco {
   reads {
     Pimento.Gibson : exact;
     Pimento.Capitola : exact;
     Pimento.Coachella : exact;
     Pimento.Amonate : exact;
   }
   actions {
      Slocum;
      Mingus;
   }
   default_action : Mingus();
   size : 4096;
}
table Schroeder {
   reads {
     Pimento.Gibson : exact;
     Pimento.Capitola : exact;
     Pimento.Coachella : exact;
     Shauck.Rembrandt : exact;
   }
   actions {
      Chalco;
   }
   size : 512;
}
control Nathalie {
   if( Pimento.Gibson == 1 ) {
      apply( Colstrip );
      apply( FarrWest );
   } else if( Pimento.Capitola == 1 ) {
      apply( Almont );
      apply( NantyGlo );
   }
   if( ( Pimento.RedLake != 0 and Pimento.Hollymead == 1 ) or
       ( Pimento.RedLake == 0 and Saragosa.valid == 1 ) ) {
      apply( Jelloway );
      if( Pimento.Volcano != 1 ){
         apply( Burnett );
      }
   }
   apply( Francisco ) {
      Mingus {
         apply( Schroeder );
      }
   }
}
action Idria() {
}
action Ironia() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action Darmstadt() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
}
action Peebles() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
table Pearcy {
   reads {
     Panacea.Hitterdal mask 0x00018000 : ternary;
   }
   actions {
      Idria;
      Ironia;
      Darmstadt;
      Peebles;
   }
   size : 16;
}
control Lewis {
   apply( Pearcy );
   apply( Kasigluk );
}
   metadata Piketon Panacea;
   action Daykin( Telocaset ) {
          max( Panacea.Hitterdal, Panacea.Hitterdal, Telocaset );
   }
@pragma ways 4
table Ripon {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : exact;
      ShadeGap.Justice : exact;
      ShadeGap.Hokah : exact;
      ShadeGap.Gordon : exact;
      ShadeGap.Ridgewood : exact;
      ShadeGap.Leflore : exact;
      ShadeGap.Linganore : exact;
      ShadeGap.Westhoff : exact;
      ShadeGap.SanPablo : exact;
   }
   actions {
      Daykin;
   }
   size : 4096;
}
control Lecompte {
   apply( Ripon );
}
table Cruso {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : ternary;
      ShadeGap.Justice : ternary;
      ShadeGap.Hokah : ternary;
      ShadeGap.Gordon : ternary;
      ShadeGap.Ridgewood : ternary;
      ShadeGap.Leflore : ternary;
      ShadeGap.Linganore : ternary;
      ShadeGap.Westhoff : ternary;
      ShadeGap.SanPablo : ternary;
   }
   actions {
      Daykin;
   }
   size : 512;
}
control Yetter {
   apply( Cruso );
}
@pragma pa_no_init ingress Antlers.Sonestown
@pragma pa_no_init ingress Antlers.Justice
@pragma pa_no_init ingress Antlers.Hokah
@pragma pa_no_init ingress Antlers.Gordon
@pragma pa_no_init ingress Antlers.Ridgewood
@pragma pa_no_init ingress Antlers.Leflore
@pragma pa_no_init ingress Antlers.Linganore
@pragma pa_no_init ingress Antlers.Westhoff
@pragma pa_no_init ingress Antlers.SanPablo
metadata Lincroft Antlers;
@pragma ways 4
table Trenary {
   reads {
      ShadeGap.Corbin : exact;
      Antlers.Sonestown : exact;
      Antlers.Justice : exact;
      Antlers.Hokah : exact;
      Antlers.Gordon : exact;
      Antlers.Ridgewood : exact;
      Antlers.Leflore : exact;
      Antlers.Linganore : exact;
      Antlers.Westhoff : exact;
      Antlers.SanPablo : exact;
   }
   actions {
      Daykin;
   }
   size : 8192;
}
action Husum( Tigard, Villas, Verdemont, Farlin, Jermyn, Raynham, Quinnesec, Longport, Mooreland ) {
   bit_and( Antlers.Sonestown, ShadeGap.Sonestown, Tigard );
   bit_and( Antlers.Justice, ShadeGap.Justice, Villas );
   bit_and( Antlers.Hokah, ShadeGap.Hokah, Verdemont );
   bit_and( Antlers.Gordon, ShadeGap.Gordon, Farlin );
   bit_and( Antlers.Ridgewood, ShadeGap.Ridgewood, Jermyn );
   bit_and( Antlers.Leflore, ShadeGap.Leflore, Raynham );
   bit_and( Antlers.Linganore, ShadeGap.Linganore, Quinnesec );
   bit_and( Antlers.Westhoff, ShadeGap.Westhoff, Longport );
   bit_and( Antlers.SanPablo, ShadeGap.SanPablo, Mooreland );
}
table Kahua {
   reads {
      ShadeGap.Corbin : exact;
   }
   actions {
      Husum;
   }
   default_action : Husum(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Millsboro {
   apply( Kahua );
}
control Dagsboro {
   apply( Trenary );
}
table Macland {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : ternary;
      ShadeGap.Justice : ternary;
      ShadeGap.Hokah : ternary;
      ShadeGap.Gordon : ternary;
      ShadeGap.Ridgewood : ternary;
      ShadeGap.Leflore : ternary;
      ShadeGap.Linganore : ternary;
      ShadeGap.Westhoff : ternary;
      ShadeGap.SanPablo : ternary;
   }
   actions {
      Daykin;
   }
   size : 512;
}
control Endicott {
   apply( Macland );
}
@pragma ways 4
table Lemhi {
   reads {
      ShadeGap.Corbin : exact;
      Antlers.Sonestown : exact;
      Antlers.Justice : exact;
      Antlers.Hokah : exact;
      Antlers.Gordon : exact;
      Antlers.Ridgewood : exact;
      Antlers.Leflore : exact;
      Antlers.Linganore : exact;
      Antlers.Westhoff : exact;
      Antlers.SanPablo : exact;
   }
   actions {
      Daykin;
   }
   size : 4096;
}
action Lansdale( Robbins, Lowland, Ballwin, Ellisburg, Oronogo, Dundalk, Tillamook, Convoy, Protem ) {
   bit_and( Antlers.Sonestown, ShadeGap.Sonestown, Robbins );
   bit_and( Antlers.Justice, ShadeGap.Justice, Lowland );
   bit_and( Antlers.Hokah, ShadeGap.Hokah, Ballwin );
   bit_and( Antlers.Gordon, ShadeGap.Gordon, Ellisburg );
   bit_and( Antlers.Ridgewood, ShadeGap.Ridgewood, Oronogo );
   bit_and( Antlers.Leflore, ShadeGap.Leflore, Dundalk );
   bit_and( Antlers.Linganore, ShadeGap.Linganore, Tillamook );
   bit_and( Antlers.Westhoff, ShadeGap.Westhoff, Convoy );
   bit_and( Antlers.SanPablo, ShadeGap.SanPablo, Protem );
}
table Ravinia {
   reads {
      ShadeGap.Corbin : exact;
   }
   actions {
      Lansdale;
   }
   default_action : Lansdale(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Jones {
   apply( Ravinia );
}
control Belfair {
   apply( Lemhi );
}
table Alvwood {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : ternary;
      ShadeGap.Justice : ternary;
      ShadeGap.Hokah : ternary;
      ShadeGap.Gordon : ternary;
      ShadeGap.Ridgewood : ternary;
      ShadeGap.Leflore : ternary;
      ShadeGap.Linganore : ternary;
      ShadeGap.Westhoff : ternary;
      ShadeGap.SanPablo : ternary;
   }
   actions {
      Daykin;
   }
   size : 512;
}
control BealCity {
   apply( Alvwood );
}
@pragma ways 4
table Petty {
   reads {
      ShadeGap.Corbin : exact;
      Antlers.Sonestown : exact;
      Antlers.Justice : exact;
      Antlers.Hokah : exact;
      Antlers.Gordon : exact;
      Antlers.Ridgewood : exact;
      Antlers.Leflore : exact;
      Antlers.Linganore : exact;
      Antlers.Westhoff : exact;
      Antlers.SanPablo : exact;
   }
   actions {
      Daykin;
   }
   size : 4096;
}
action DuQuoin( Sanchez, Deemer, Cornville, Swain, BurrOak, Sweeny, NewAlbin, Finlayson, Sontag ) {
   bit_and( Antlers.Sonestown, ShadeGap.Sonestown, Sanchez );
   bit_and( Antlers.Justice, ShadeGap.Justice, Deemer );
   bit_and( Antlers.Hokah, ShadeGap.Hokah, Cornville );
   bit_and( Antlers.Gordon, ShadeGap.Gordon, Swain );
   bit_and( Antlers.Ridgewood, ShadeGap.Ridgewood, BurrOak );
   bit_and( Antlers.Leflore, ShadeGap.Leflore, Sweeny );
   bit_and( Antlers.Linganore, ShadeGap.Linganore, NewAlbin );
   bit_and( Antlers.Westhoff, ShadeGap.Westhoff, Finlayson );
   bit_and( Antlers.SanPablo, ShadeGap.SanPablo, Sontag );
}
table Jefferson {
   reads {
      ShadeGap.Corbin : exact;
   }
   actions {
      DuQuoin;
   }
   default_action : DuQuoin(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Vanoss {
   apply( Jefferson );
}
control Lilbert {
   apply( Petty );
}
table Pachuta {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : ternary;
      ShadeGap.Justice : ternary;
      ShadeGap.Hokah : ternary;
      ShadeGap.Gordon : ternary;
      ShadeGap.Ridgewood : ternary;
      ShadeGap.Leflore : ternary;
      ShadeGap.Linganore : ternary;
      ShadeGap.Westhoff : ternary;
      ShadeGap.SanPablo : ternary;
   }
   actions {
      Daykin;
   }
   size : 512;
}
control FlatLick {
   apply( Pachuta );
}
@pragma ways 4
table Junior {
   reads {
      ShadeGap.Corbin : exact;
      Antlers.Sonestown : exact;
      Antlers.Justice : exact;
      Antlers.Hokah : exact;
      Antlers.Gordon : exact;
      Antlers.Ridgewood : exact;
      Antlers.Leflore : exact;
      Antlers.Linganore : exact;
      Antlers.Westhoff : exact;
      Antlers.SanPablo : exact;
   }
   actions {
      Daykin;
   }
   size : 8192;
}
action Hiawassee( Soledad, Fackler, Ludowici, Pioche, McAllen, BigArm, Christmas, Gaston, Petoskey ) {
   bit_and( Antlers.Sonestown, ShadeGap.Sonestown, Soledad );
   bit_and( Antlers.Justice, ShadeGap.Justice, Fackler );
   bit_and( Antlers.Hokah, ShadeGap.Hokah, Ludowici );
   bit_and( Antlers.Gordon, ShadeGap.Gordon, Pioche );
   bit_and( Antlers.Ridgewood, ShadeGap.Ridgewood, McAllen );
   bit_and( Antlers.Leflore, ShadeGap.Leflore, BigArm );
   bit_and( Antlers.Linganore, ShadeGap.Linganore, Christmas );
   bit_and( Antlers.Westhoff, ShadeGap.Westhoff, Gaston );
   bit_and( Antlers.SanPablo, ShadeGap.SanPablo, Petoskey );
}
table Kanab {
   reads {
      ShadeGap.Corbin : exact;
   }
   actions {
      Hiawassee;
   }
   default_action : Hiawassee(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Deerwood {
   apply( Kanab );
}
control Calamus {
   apply( Junior );
}
table WestBend {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : ternary;
      ShadeGap.Justice : ternary;
      ShadeGap.Hokah : ternary;
      ShadeGap.Gordon : ternary;
      ShadeGap.Ridgewood : ternary;
      ShadeGap.Leflore : ternary;
      ShadeGap.Linganore : ternary;
      ShadeGap.Westhoff : ternary;
      ShadeGap.SanPablo : ternary;
   }
   actions {
      Daykin;
   }
   size : 512;
}
control HydePark {
   apply( WestBend );
}
@pragma ways 4
table Milano {
   reads {
      ShadeGap.Corbin : exact;
      Antlers.Sonestown : exact;
      Antlers.Justice : exact;
      Antlers.Hokah : exact;
      Antlers.Gordon : exact;
      Antlers.Ridgewood : exact;
      Antlers.Leflore : exact;
      Antlers.Linganore : exact;
      Antlers.Westhoff : exact;
      Antlers.SanPablo : exact;
   }
   actions {
      Daykin;
   }
   size : 8192;
}
action Antelope( Edgemoor, Lovilia, Samson, McCammon, Shuqualak, Ronan, Pickering, Kniman, Skime ) {
   bit_and( Antlers.Sonestown, ShadeGap.Sonestown, Edgemoor );
   bit_and( Antlers.Justice, ShadeGap.Justice, Lovilia );
   bit_and( Antlers.Hokah, ShadeGap.Hokah, Samson );
   bit_and( Antlers.Gordon, ShadeGap.Gordon, McCammon );
   bit_and( Antlers.Ridgewood, ShadeGap.Ridgewood, Shuqualak );
   bit_and( Antlers.Leflore, ShadeGap.Leflore, Ronan );
   bit_and( Antlers.Linganore, ShadeGap.Linganore, Pickering );
   bit_and( Antlers.Westhoff, ShadeGap.Westhoff, Kniman );
   bit_and( Antlers.SanPablo, ShadeGap.SanPablo, Skime );
}
table Sallisaw {
   reads {
      ShadeGap.Corbin : exact;
   }
   actions {
      Antelope;
   }
   default_action : Antelope(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Grigston {
   apply( Sallisaw );
}
control Easley {
   apply( Milano );
}
table Bufalo {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : ternary;
      ShadeGap.Justice : ternary;
      ShadeGap.Hokah : ternary;
      ShadeGap.Gordon : ternary;
      ShadeGap.Ridgewood : ternary;
      ShadeGap.Leflore : ternary;
      ShadeGap.Linganore : ternary;
      ShadeGap.Westhoff : ternary;
      ShadeGap.SanPablo : ternary;
   }
   actions {
      Daykin;
   }
   size : 512;
}
control Valdosta {
   apply( Bufalo );
}
@pragma ways 4
table Maida {
   reads {
      ShadeGap.Corbin : exact;
      Antlers.Sonestown : exact;
      Antlers.Justice : exact;
      Antlers.Hokah : exact;
      Antlers.Gordon : exact;
      Antlers.Ridgewood : exact;
      Antlers.Leflore : exact;
      Antlers.Linganore : exact;
      Antlers.Westhoff : exact;
      Antlers.SanPablo : exact;
   }
   actions {
      Daykin;
   }
   size : 4096;
}
action Hooven( Clearlake, LaneCity, Otsego, Trego, Friday, Iselin, Ocoee, Darco, Oreland ) {
   bit_and( Antlers.Sonestown, ShadeGap.Sonestown, Clearlake );
   bit_and( Antlers.Justice, ShadeGap.Justice, LaneCity );
   bit_and( Antlers.Hokah, ShadeGap.Hokah, Otsego );
   bit_and( Antlers.Gordon, ShadeGap.Gordon, Trego );
   bit_and( Antlers.Ridgewood, ShadeGap.Ridgewood, Friday );
   bit_and( Antlers.Leflore, ShadeGap.Leflore, Iselin );
   bit_and( Antlers.Linganore, ShadeGap.Linganore, Ocoee );
   bit_and( Antlers.Westhoff, ShadeGap.Westhoff, Darco );
   bit_and( Antlers.SanPablo, ShadeGap.SanPablo, Oreland );
}
table Jericho {
   reads {
      ShadeGap.Corbin : exact;
   }
   actions {
      Hooven;
   }
   default_action : Hooven(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Satus {
   apply( Jericho );
}
control Mentmore {
   apply( Maida );
}
table Wagener {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : ternary;
      ShadeGap.Justice : ternary;
      ShadeGap.Hokah : ternary;
      ShadeGap.Gordon : ternary;
      ShadeGap.Ridgewood : ternary;
      ShadeGap.Leflore : ternary;
      ShadeGap.Linganore : ternary;
      ShadeGap.Westhoff : ternary;
      ShadeGap.SanPablo : ternary;
   }
   actions {
      Daykin;
   }
   size : 512;
}
control Burgin {
   apply( Wagener );
}
@pragma ways 4
table Unionvale {
   reads {
      ShadeGap.Corbin : exact;
      Antlers.Sonestown : exact;
      Antlers.Justice : exact;
      Antlers.Hokah : exact;
      Antlers.Gordon : exact;
      Antlers.Ridgewood : exact;
      Antlers.Leflore : exact;
      Antlers.Linganore : exact;
      Antlers.Westhoff : exact;
      Antlers.SanPablo : exact;
   }
   actions {
      Daykin;
   }
   size : 4096;
}
action Taopi( Nighthawk, CapRock, Schaller, Lordstown, Sharon, Cataract, Alcester, Woodbury, Arnett ) {
   bit_and( Antlers.Sonestown, ShadeGap.Sonestown, Nighthawk );
   bit_and( Antlers.Justice, ShadeGap.Justice, CapRock );
   bit_and( Antlers.Hokah, ShadeGap.Hokah, Schaller );
   bit_and( Antlers.Gordon, ShadeGap.Gordon, Lordstown );
   bit_and( Antlers.Ridgewood, ShadeGap.Ridgewood, Sharon );
   bit_and( Antlers.Leflore, ShadeGap.Leflore, Cataract );
   bit_and( Antlers.Linganore, ShadeGap.Linganore, Alcester );
   bit_and( Antlers.Westhoff, ShadeGap.Westhoff, Woodbury );
   bit_and( Antlers.SanPablo, ShadeGap.SanPablo, Arnett );
}
table Wadley {
   reads {
      ShadeGap.Corbin : exact;
   }
   actions {
      Taopi;
   }
   default_action : Taopi(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Doyline {
   apply( Wadley );
}
control Knights {
   apply( Unionvale );
}
table Goulding {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : ternary;
      ShadeGap.Justice : ternary;
      ShadeGap.Hokah : ternary;
      ShadeGap.Gordon : ternary;
      ShadeGap.Ridgewood : ternary;
      ShadeGap.Leflore : ternary;
      ShadeGap.Linganore : ternary;
      ShadeGap.Westhoff : ternary;
      ShadeGap.SanPablo : ternary;
   }
   actions {
      Daykin;
   }
   size : 512;
}
control NeckCity {
   apply( Goulding );
}
   metadata Piketon Belcourt;
   action Gamewell( Ketchum ) {
          max( Belcourt.Hitterdal, Belcourt.Hitterdal, Ketchum );
   }
   action Dassel() { max( Panacea.Hitterdal, Belcourt.Hitterdal, Panacea.Hitterdal ); } table Hartville { actions { Dassel; } default_action : Dassel; size : 1; } control Enhaut { apply( Hartville ); }
@pragma ways 4
table Hargis {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : exact;
      ShadeGap.Justice : exact;
      ShadeGap.Hokah : exact;
      ShadeGap.Gordon : exact;
      ShadeGap.Ridgewood : exact;
      ShadeGap.Leflore : exact;
      ShadeGap.Linganore : exact;
      ShadeGap.Westhoff : exact;
      ShadeGap.SanPablo : exact;
   }
   actions {
      Gamewell;
   }
   size : 4096;
}
control Green {
   apply( Hargis );
}
table Goldenrod {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : ternary;
      ShadeGap.Justice : ternary;
      ShadeGap.Hokah : ternary;
      ShadeGap.Gordon : ternary;
      ShadeGap.Ridgewood : ternary;
      ShadeGap.Leflore : ternary;
      ShadeGap.Linganore : ternary;
      ShadeGap.Westhoff : ternary;
      ShadeGap.SanPablo : ternary;
   }
   actions {
      Gamewell;
   }
   size : 4096;
}
control Maryville {
   apply( Goldenrod );
}
@pragma pa_no_init ingress Dunnellon.Sonestown
@pragma pa_no_init ingress Dunnellon.Justice
@pragma pa_no_init ingress Dunnellon.Hokah
@pragma pa_no_init ingress Dunnellon.Gordon
@pragma pa_no_init ingress Dunnellon.Ridgewood
@pragma pa_no_init ingress Dunnellon.Leflore
@pragma pa_no_init ingress Dunnellon.Linganore
@pragma pa_no_init ingress Dunnellon.Westhoff
@pragma pa_no_init ingress Dunnellon.SanPablo
metadata Lincroft Dunnellon;
@pragma ways 4
table Lindsborg {
   reads {
      ShadeGap.Corbin : exact;
      Dunnellon.Sonestown : exact;
      Dunnellon.Justice : exact;
      Dunnellon.Hokah : exact;
      Dunnellon.Gordon : exact;
      Dunnellon.Ridgewood : exact;
      Dunnellon.Leflore : exact;
      Dunnellon.Linganore : exact;
      Dunnellon.Westhoff : exact;
      Dunnellon.SanPablo : exact;
   }
   actions {
      Gamewell;
   }
   size : 4096;
}
action Chilson( Covina, Kalkaska, Pfeifer, Woodstown, Malmo, Sneads, Kahului, Rolla, Fabens ) {
   bit_and( Dunnellon.Sonestown, ShadeGap.Sonestown, Covina );
   bit_and( Dunnellon.Justice, ShadeGap.Justice, Kalkaska );
   bit_and( Dunnellon.Hokah, ShadeGap.Hokah, Pfeifer );
   bit_and( Dunnellon.Gordon, ShadeGap.Gordon, Woodstown );
   bit_and( Dunnellon.Ridgewood, ShadeGap.Ridgewood, Malmo );
   bit_and( Dunnellon.Leflore, ShadeGap.Leflore, Sneads );
   bit_and( Dunnellon.Linganore, ShadeGap.Linganore, Kahului );
   bit_and( Dunnellon.Westhoff, ShadeGap.Westhoff, Rolla );
   bit_and( Dunnellon.SanPablo, ShadeGap.SanPablo, Fabens );
}
table Glenside {
   reads {
      ShadeGap.Corbin : exact;
   }
   actions {
      Chilson;
   }
   default_action : Chilson(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Bessie {
   apply( Glenside );
}
control Stone {
   apply( Lindsborg );
}
table Onamia {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : ternary;
      ShadeGap.Justice : ternary;
      ShadeGap.Hokah : ternary;
      ShadeGap.Gordon : ternary;
      ShadeGap.Ridgewood : ternary;
      ShadeGap.Leflore : ternary;
      ShadeGap.Linganore : ternary;
      ShadeGap.Westhoff : ternary;
      ShadeGap.SanPablo : ternary;
   }
   actions {
      Gamewell;
   }
   size : 512;
}
control Geeville {
   apply( Onamia );
}
@pragma ways 4
table Driftwood {
   reads {
      ShadeGap.Corbin : exact;
      Dunnellon.Sonestown : exact;
      Dunnellon.Justice : exact;
      Dunnellon.Hokah : exact;
      Dunnellon.Gordon : exact;
      Dunnellon.Ridgewood : exact;
      Dunnellon.Leflore : exact;
      Dunnellon.Linganore : exact;
      Dunnellon.Westhoff : exact;
      Dunnellon.SanPablo : exact;
   }
   actions {
      Gamewell;
   }
   size : 4096;
}
action Westtown( ElVerano, Exton, Sherwin, Parmele, Missoula, Lahaina, Brookside, Nettleton, Servia ) {
   bit_and( Dunnellon.Sonestown, ShadeGap.Sonestown, ElVerano );
   bit_and( Dunnellon.Justice, ShadeGap.Justice, Exton );
   bit_and( Dunnellon.Hokah, ShadeGap.Hokah, Sherwin );
   bit_and( Dunnellon.Gordon, ShadeGap.Gordon, Parmele );
   bit_and( Dunnellon.Ridgewood, ShadeGap.Ridgewood, Missoula );
   bit_and( Dunnellon.Leflore, ShadeGap.Leflore, Lahaina );
   bit_and( Dunnellon.Linganore, ShadeGap.Linganore, Brookside );
   bit_and( Dunnellon.Westhoff, ShadeGap.Westhoff, Nettleton );
   bit_and( Dunnellon.SanPablo, ShadeGap.SanPablo, Servia );
}
table Millport {
   reads {
      ShadeGap.Corbin : exact;
   }
   actions {
      Westtown;
   }
   default_action : Westtown(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Fletcher {
   apply( Millport );
}
control Wayland {
   apply( Driftwood );
}
table Stanwood {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : ternary;
      ShadeGap.Justice : ternary;
      ShadeGap.Hokah : ternary;
      ShadeGap.Gordon : ternary;
      ShadeGap.Ridgewood : ternary;
      ShadeGap.Leflore : ternary;
      ShadeGap.Linganore : ternary;
      ShadeGap.Westhoff : ternary;
      ShadeGap.SanPablo : ternary;
   }
   actions {
      Gamewell;
   }
   size : 512;
}
control Skyline {
   apply( Stanwood );
}
@pragma ways 4
table Whitman {
   reads {
      ShadeGap.Corbin : exact;
      Dunnellon.Sonestown : exact;
      Dunnellon.Justice : exact;
      Dunnellon.Hokah : exact;
      Dunnellon.Gordon : exact;
      Dunnellon.Ridgewood : exact;
      Dunnellon.Leflore : exact;
      Dunnellon.Linganore : exact;
      Dunnellon.Westhoff : exact;
      Dunnellon.SanPablo : exact;
   }
   actions {
      Gamewell;
   }
   size : 4096;
}
action Norco( PellLake, Kaweah, Tarlton, Pelland, Sublett, Elmhurst, Sparland, Hallville, Tunica ) {
   bit_and( Dunnellon.Sonestown, ShadeGap.Sonestown, PellLake );
   bit_and( Dunnellon.Justice, ShadeGap.Justice, Kaweah );
   bit_and( Dunnellon.Hokah, ShadeGap.Hokah, Tarlton );
   bit_and( Dunnellon.Gordon, ShadeGap.Gordon, Pelland );
   bit_and( Dunnellon.Ridgewood, ShadeGap.Ridgewood, Sublett );
   bit_and( Dunnellon.Leflore, ShadeGap.Leflore, Elmhurst );
   bit_and( Dunnellon.Linganore, ShadeGap.Linganore, Sparland );
   bit_and( Dunnellon.Westhoff, ShadeGap.Westhoff, Hallville );
   bit_and( Dunnellon.SanPablo, ShadeGap.SanPablo, Tunica );
}
table Agency {
   reads {
      ShadeGap.Corbin : exact;
   }
   actions {
      Norco;
   }
   default_action : Norco(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Laplace {
   apply( Agency );
}
control Rendon {
   apply( Whitman );
}
table Diana {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : ternary;
      ShadeGap.Justice : ternary;
      ShadeGap.Hokah : ternary;
      ShadeGap.Gordon : ternary;
      ShadeGap.Ridgewood : ternary;
      ShadeGap.Leflore : ternary;
      ShadeGap.Linganore : ternary;
      ShadeGap.Westhoff : ternary;
      ShadeGap.SanPablo : ternary;
   }
   actions {
      Gamewell;
   }
   size : 512;
}
control LaPryor {
   apply( Diana );
}
@pragma ways 4
table Runnemede {
   reads {
      ShadeGap.Corbin : exact;
      Dunnellon.Sonestown : exact;
      Dunnellon.Justice : exact;
      Dunnellon.Hokah : exact;
      Dunnellon.Gordon : exact;
      Dunnellon.Ridgewood : exact;
      Dunnellon.Leflore : exact;
      Dunnellon.Linganore : exact;
      Dunnellon.Westhoff : exact;
      Dunnellon.SanPablo : exact;
   }
   actions {
      Gamewell;
   }
   size : 4096;
}
action Skokomish( Wyocena, BoyRiver, Nephi, Rodessa, Goodwater, Leonore, Armijo, Wenatchee, Rockland ) {
   bit_and( Dunnellon.Sonestown, ShadeGap.Sonestown, Wyocena );
   bit_and( Dunnellon.Justice, ShadeGap.Justice, BoyRiver );
   bit_and( Dunnellon.Hokah, ShadeGap.Hokah, Nephi );
   bit_and( Dunnellon.Gordon, ShadeGap.Gordon, Rodessa );
   bit_and( Dunnellon.Ridgewood, ShadeGap.Ridgewood, Goodwater );
   bit_and( Dunnellon.Leflore, ShadeGap.Leflore, Leonore );
   bit_and( Dunnellon.Linganore, ShadeGap.Linganore, Armijo );
   bit_and( Dunnellon.Westhoff, ShadeGap.Westhoff, Wenatchee );
   bit_and( Dunnellon.SanPablo, ShadeGap.SanPablo, Rockland );
}
table Eldena {
   reads {
      ShadeGap.Corbin : exact;
   }
   actions {
      Skokomish;
   }
   default_action : Skokomish(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Theba {
   apply( Eldena );
}
control Vigus {
   apply( Runnemede );
}
table Pilottown {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : ternary;
      ShadeGap.Justice : ternary;
      ShadeGap.Hokah : ternary;
      ShadeGap.Gordon : ternary;
      ShadeGap.Ridgewood : ternary;
      ShadeGap.Leflore : ternary;
      ShadeGap.Linganore : ternary;
      ShadeGap.Westhoff : ternary;
      ShadeGap.SanPablo : ternary;
   }
   actions {
      Gamewell;
   }
   size : 512;
}
control Marshall {
   apply( Pilottown );
}
@pragma ways 4
table Laton {
   reads {
      ShadeGap.Corbin : exact;
      Dunnellon.Sonestown : exact;
      Dunnellon.Justice : exact;
      Dunnellon.Hokah : exact;
      Dunnellon.Gordon : exact;
      Dunnellon.Ridgewood : exact;
      Dunnellon.Leflore : exact;
      Dunnellon.Linganore : exact;
      Dunnellon.Westhoff : exact;
      Dunnellon.SanPablo : exact;
   }
   actions {
      Gamewell;
   }
   size : 4096;
}
action Gerlach( Bozeman, Occoquan, Hapeville, McGrady, Torrance, Topanga, Sabina, Allgood, Tingley ) {
   bit_and( Dunnellon.Sonestown, ShadeGap.Sonestown, Bozeman );
   bit_and( Dunnellon.Justice, ShadeGap.Justice, Occoquan );
   bit_and( Dunnellon.Hokah, ShadeGap.Hokah, Hapeville );
   bit_and( Dunnellon.Gordon, ShadeGap.Gordon, McGrady );
   bit_and( Dunnellon.Ridgewood, ShadeGap.Ridgewood, Torrance );
   bit_and( Dunnellon.Leflore, ShadeGap.Leflore, Topanga );
   bit_and( Dunnellon.Linganore, ShadeGap.Linganore, Sabina );
   bit_and( Dunnellon.Westhoff, ShadeGap.Westhoff, Allgood );
   bit_and( Dunnellon.SanPablo, ShadeGap.SanPablo, Tingley );
}
table Belmore {
   reads {
      ShadeGap.Corbin : exact;
   }
   actions {
      Gerlach;
   }
   default_action : Gerlach(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Harlem {
   apply( Belmore );
}
control Rohwer {
   apply( Laton );
}
table Derita {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : ternary;
      ShadeGap.Justice : ternary;
      ShadeGap.Hokah : ternary;
      ShadeGap.Gordon : ternary;
      ShadeGap.Ridgewood : ternary;
      ShadeGap.Leflore : ternary;
      ShadeGap.Linganore : ternary;
      ShadeGap.Westhoff : ternary;
      ShadeGap.SanPablo : ternary;
   }
   actions {
      Gamewell;
   }
   size : 512;
}
control Wabbaseka {
   apply( Derita );
}
@pragma ways 4
table Hamel {
   reads {
      ShadeGap.Corbin : exact;
      Dunnellon.Sonestown : exact;
      Dunnellon.Justice : exact;
      Dunnellon.Hokah : exact;
      Dunnellon.Gordon : exact;
      Dunnellon.Ridgewood : exact;
      Dunnellon.Leflore : exact;
      Dunnellon.Linganore : exact;
      Dunnellon.Westhoff : exact;
      Dunnellon.SanPablo : exact;
   }
   actions {
      Gamewell;
   }
   size : 4096;
}
action Harbor( Homeworth, LaHabra, Logandale, Ashburn, Cascade, Dauphin, Weimar, Arroyo, Notus ) {
   bit_and( Dunnellon.Sonestown, ShadeGap.Sonestown, Homeworth );
   bit_and( Dunnellon.Justice, ShadeGap.Justice, LaHabra );
   bit_and( Dunnellon.Hokah, ShadeGap.Hokah, Logandale );
   bit_and( Dunnellon.Gordon, ShadeGap.Gordon, Ashburn );
   bit_and( Dunnellon.Ridgewood, ShadeGap.Ridgewood, Cascade );
   bit_and( Dunnellon.Leflore, ShadeGap.Leflore, Dauphin );
   bit_and( Dunnellon.Linganore, ShadeGap.Linganore, Weimar );
   bit_and( Dunnellon.Westhoff, ShadeGap.Westhoff, Arroyo );
   bit_and( Dunnellon.SanPablo, ShadeGap.SanPablo, Notus );
}
table Nondalton {
   reads {
      ShadeGap.Corbin : exact;
   }
   actions {
      Harbor;
   }
   default_action : Harbor(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Woodward {
   apply( Nondalton );
}
control Hedrick {
   apply( Hamel );
}
table Timnath {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : ternary;
      ShadeGap.Justice : ternary;
      ShadeGap.Hokah : ternary;
      ShadeGap.Gordon : ternary;
      ShadeGap.Ridgewood : ternary;
      ShadeGap.Leflore : ternary;
      ShadeGap.Linganore : ternary;
      ShadeGap.Westhoff : ternary;
      ShadeGap.SanPablo : ternary;
   }
   actions {
      Gamewell;
   }
   size : 512;
}
control Lantana {
   apply( Timnath );
}
@pragma ways 4
table Bassett {
   reads {
      ShadeGap.Corbin : exact;
      Dunnellon.Sonestown : exact;
      Dunnellon.Justice : exact;
      Dunnellon.Hokah : exact;
      Dunnellon.Gordon : exact;
      Dunnellon.Ridgewood : exact;
      Dunnellon.Leflore : exact;
      Dunnellon.Linganore : exact;
      Dunnellon.Westhoff : exact;
      Dunnellon.SanPablo : exact;
   }
   actions {
      Gamewell;
   }
   size : 4096;
}
action LoonLake( Rawson, Lurton, Broadwell, Neshoba, Tornillo, Navarro, Havana, Millikin, Wewela ) {
   bit_and( Dunnellon.Sonestown, ShadeGap.Sonestown, Rawson );
   bit_and( Dunnellon.Justice, ShadeGap.Justice, Lurton );
   bit_and( Dunnellon.Hokah, ShadeGap.Hokah, Broadwell );
   bit_and( Dunnellon.Gordon, ShadeGap.Gordon, Neshoba );
   bit_and( Dunnellon.Ridgewood, ShadeGap.Ridgewood, Tornillo );
   bit_and( Dunnellon.Leflore, ShadeGap.Leflore, Navarro );
   bit_and( Dunnellon.Linganore, ShadeGap.Linganore, Havana );
   bit_and( Dunnellon.Westhoff, ShadeGap.Westhoff, Millikin );
   bit_and( Dunnellon.SanPablo, ShadeGap.SanPablo, Wewela );
}
table Dougherty {
   reads {
      ShadeGap.Corbin : exact;
   }
   actions {
      LoonLake;
   }
   default_action : LoonLake(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Blairsden {
   apply( Dougherty );
}
control Absarokee {
   apply( Bassett );
}
table Denmark {
   reads {
      ShadeGap.Corbin : exact;
      ShadeGap.Sonestown : ternary;
      ShadeGap.Justice : ternary;
      ShadeGap.Hokah : ternary;
      ShadeGap.Gordon : ternary;
      ShadeGap.Ridgewood : ternary;
      ShadeGap.Leflore : ternary;
      ShadeGap.Linganore : ternary;
      ShadeGap.Westhoff : ternary;
      ShadeGap.SanPablo : ternary;
   }
   actions {
      Gamewell;
   }
   size : 512;
}
control Weehawken {
   apply( Denmark );
}
control ingress {
   Leadpoint();
   if( Shauck.Allison != 0 ) {
      Gunder();
   }
   Moody();
   if( Shauck.Allison != 0 ) {
      Bonner();
      Dunedin();
   }
   Stonefort();
   Nathalie();
   Midas();
   Courtdale();
   Millsboro();
   if( Shauck.Allison != 0 ) {
      Bayshore();
   }
   Dagsboro();
   Jones();
   Belfair();
   Vanoss();
   if( Shauck.Allison != 0 ) {
      Edmondson();
   }
   Colfax();
   Opelousas();
   Lilbert();
   Deerwood();
   if( Shauck.Allison != 0 ) {
      Lushton();
   }
   Calamus();
   Grigston();
   Maryville();
   Piedmont();
   Ricketts();
   if( Shauck.Allison != 0 ) {
      Dunnville();
   }
   Domingo();
   Lizella();
   Easley();
   Thermal();
   if( Ballville.Mantee == 0 ) {
      if( valid( Tekonsha ) ) {
         Conner();
      } else {
         Tappan();
         Calvary();
      }
   }
   if( Tekonsha.valid == 0 ) {
      Fries();
   }
   if( Ballville.Mantee == 0 ) {
      Yorklyn();
   }
   Enhaut();
   if ( Shauck.Allison != 0 ) {
      if( Ballville.Mantee == 0 and Pimento.Graford == 1) {
         apply( Billett );
      } else {
         apply( Fitzhugh );
      }
   }
   if( Shauck.Allison != 0 ) {
      Powelton();
   }
   Belen();
   if( valid( Hemet[0] ) ) {
      Genola();
   }
   if( Ballville.Mantee == 0 ) {
      Barnsdall();
   }
   Biloxi();
   Lewis();
}
control egress {
   Tobique();
   Plateau();
   Merkel();
   if( ( Ballville.Upland == 0 ) and ( Ballville.Lonepine != 2 ) ) {
      Windber();
   }
   Orlinda();
}
