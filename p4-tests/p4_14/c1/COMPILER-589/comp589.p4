// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 230331

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
header_type Menifee {
	fields {
		Tonasket : 16;
		Herald : 16;
		BlueAsh : 8;
		Highfill : 8;
		CeeVee : 8;
		Potter : 8;
		Wapato : 1;
		Childs : 1;
		Dubbs : 1;
		Angus : 1;
		Laneburg : 1;
		Perrine : 1;
	}
}
header_type Beasley {
	fields {
		Milan : 24;
		Tavistock : 24;
		Mariemont : 24;
		Pringle : 24;
		Geismar : 16;
		Ellicott : 16;
		Theta : 16;
		Thalmann : 16;
		Ortley : 16;
		Tulia : 8;
		Tonkawa : 8;
		Lebanon : 1;
		Danforth : 1;
		Tidewater : 1;
		Nichols : 1;
		Odessa : 12;
		Timnath : 2;
		Bavaria : 1;
		Plush : 1;
		Sidnaw : 1;
		Kalkaska : 1;
		Hilgard : 1;
		Edmondson : 1;
		Wellsboro : 1;
		Florien : 1;
		Anson : 1;
		Lenwood : 1;
		Zebina : 1;
		Akhiok : 1;
		Wakita : 1;
		Tramway : 1;
		Daniels : 1;
		Calumet : 1;
		Attica : 16;
		BigLake : 16;
		RedElm : 8;
		Evendale : 1;
		Perkasie : 1;
	}
}
header_type Wausaukee {
	fields {
		Covelo : 24;
		Gheen : 24;
		Newborn : 24;
		Harviell : 24;
		Odell : 24;
		Piermont : 24;
		Elcho : 24;
		Kahua : 24;
		Tofte : 16;
		Buncombe : 16;
		Gilman : 16;
		Radom : 16;
		Mifflin : 12;
		Danese : 1;
		Galestown : 3;
		Ragley : 1;
		Licking : 3;
		Wyndmere : 1;
		Thach : 1;
		Twichell : 1;
		Hammocks : 1;
		Lucile : 1;
		Delmar : 8;
		Jonesport : 12;
		Stanwood : 4;
		Novinger : 6;
		Stuttgart : 10;
		SanPablo : 9;
		Doddridge : 1;
		Brohard : 1;
		Parmele : 1;
		Yerington : 1;
		Raceland : 1;
	}
}
header_type Billett {
	fields {
		Allegan : 8;
		Grygla : 1;
		Shauck : 1;
		Petoskey : 1;
		HighRock : 1;
		Greenland : 1;
	}
}
header_type BirchBay {
	fields {
		Tiskilwa : 32;
		Rhinebeck : 32;
		Perrin : 6;
		Sarepta : 16;
	}
}
header_type Valders {
	fields {
		Fittstown : 128;
		Covina : 128;
		Chunchula : 20;
		Rixford : 8;
		HydePark : 11;
		Glennie : 6;
		Hershey : 13;
	}
}
header_type Retrop {
	fields {
		Creston : 14;
		Sawpit : 1;
		Ocilla : 12;
		Uncertain : 1;
		Glendevey : 1;
		Liberal : 2;
		Karluk : 6;
		Algonquin : 3;
	}
}
header_type Manakin {
	fields {
		Upalco : 1;
		Townville : 1;
	}
}
header_type Olivet {
	fields {
		RedBay : 8;
	}
}
header_type Jarrell {
	fields {
		Ronneby : 16;
		Fairlee : 11;
	}
}
header_type Easley {
	fields {
		Poland : 32;
		Roachdale : 32;
		Havana : 32;
	}
}
header_type SweetAir {
	fields {
		Mocane : 32;
		Mantee : 32;
	}
}
header_type Gorum {
	fields {
		Scherr : 1;
		Lesley : 1;
		Chantilly : 1;
		Bronaugh : 3;
		McDaniels : 1;
		Seaford : 6;
		Dunbar : 5;
	}
}
header_type Eggleston {
	fields {
		Hanston : 16;
	}
}
header_type Wayzata {
	fields {
		Dresden : 14;
		Gracewood : 1;
		Malabar : 1;
	}
}
header_type Romeo {
	fields {
		Cardenas : 14;
		Lacombe : 1;
		Fairlea : 1;
	}
}
header_type Norridge {
	fields {
		Glenpool : 16;
		Hotchkiss : 16;
		Bellmore : 16;
		Lubec : 16;
		Ashwood : 8;
		Catlin : 8;
		Veneta : 8;
		Shobonier : 8;
		Armijo : 1;
		BigBar : 6;
	}
}
header_type Cordell {
	fields {
		Tulsa : 32;
	}
}
header_type McCammon {
	fields {
		BigRock : 6;
		Trail : 10;
		Lopeno : 4;
		Edroy : 12;
		Joplin : 12;
		Onawa : 2;
		Haugen : 2;
		Norma : 8;
		Kinard : 3;
		Topawa : 5;
	}
}
header_type Juniata {
	fields {
		Hueytown : 24;
		Scottdale : 24;
		Larose : 24;
		Topmost : 24;
		Montegut : 16;
	}
}
header_type Achilles {
	fields {
		Hoadly : 3;
		Toxey : 1;
		Batchelor : 12;
		Poynette : 16;
	}
}
header_type Montour {
	fields {
		Supai : 4;
		DeSart : 4;
		Naches : 6;
		Claypool : 2;
		Millett : 16;
		LaUnion : 16;
		Emmalane : 3;
		Farlin : 13;
		Weimar : 8;
		Kremlin : 8;
		Waubun : 16;
		Nerstrand : 32;
		Cimarron : 32;
	}
}
header_type Baker {
	fields {
		Bradner : 4;
		Prismatic : 6;
		Colmar : 2;
		Palco : 20;
		Oakes : 16;
		Gunter : 8;
		Caulfield : 8;
		Cloverly : 128;
		Despard : 128;
	}
}
header_type Delavan {
	fields {
		Meridean : 8;
		Brinkman : 8;
		AquaPark : 16;
	}
}
header_type Reidland {
	fields {
		Hendley : 16;
		Chicago : 16;
	}
}
header_type Northlake {
	fields {
		Mishicot : 32;
		Keokee : 32;
		Pinetop : 4;
		Sabana : 4;
		McMurray : 8;
		Grampian : 16;
		Belvue : 16;
		Palatine : 16;
	}
}
header_type Montezuma {
	fields {
		Mecosta : 16;
		Paragonah : 16;
	}
}
header_type Brookwood {
	fields {
		Winner : 16;
		Belcher : 16;
		Ponder : 8;
		Triplett : 8;
		Winters : 16;
	}
}
header_type Nelagoney {
	fields {
		Quijotoa : 48;
		Schroeder : 32;
		Placida : 48;
		Sandstone : 32;
	}
}
header_type Commack {
	fields {
		Kiana : 1;
		Gonzalez : 1;
		Coyote : 1;
		Shickley : 1;
		Galloway : 1;
		Bicknell : 3;
		NeckCity : 5;
		Redden : 3;
		Dougherty : 16;
	}
}
header_type Crossett {
	fields {
		Shasta : 24;
		Barwick : 8;
	}
}
header_type Noyack {
	fields {
		Picacho : 8;
		Ringold : 24;
		Orting : 24;
		Storden : 8;
	}
}
header Juniata Dixboro;
header Juniata Denning;
header Achilles McCaulley[ 2 ];
@pragma pa_fragment ingress CapRock.Waubun
@pragma pa_fragment egress CapRock.Waubun
header Montour CapRock;
@pragma pa_fragment ingress Lepanto.Waubun
@pragma pa_fragment egress Lepanto.Waubun
header Montour Lepanto;
header Baker Wabbaseka;
header Baker Crossnore;
header Reidland Wauregan;
header Reidland Lefors;
header Northlake Yscloskey;
header Montezuma Cusick;
header Northlake Brunson;
header Montezuma Eckman;
header Noyack KawCity;
header Brookwood Richlawn;
header Commack Couchwood;
header McCammon Lamar;
header Juniata Baranof;
parser start {
   return select(current(96, 16)) {
      0xBF00 : Coalton;
      default : Moraine;
   }
}
parser Palmdale {
   extract( Lamar );
   return Moraine;
}
parser Coalton {
   extract( Baranof );
   return Palmdale;
}
parser Moraine {
   extract( Dixboro );
   return select( Dixboro.Montegut ) {
      0x8100 : Trooper;
      0x0800 : OldMines;
      0x86dd : Chenequa;
      0x0806 : Beaverdam;
      default : ingress;
   }
}
parser Trooper {
   extract( McCaulley[0] );
   set_metadata(Duque.Laneburg, 1);
   return select( McCaulley[0].Poynette ) {
      0x0800 : OldMines;
      0x86dd : Chenequa;
      0x0806 : Beaverdam;
      default : ingress;
   }
}
field_list Kennedale {
    CapRock.Supai;
    CapRock.DeSart;
    CapRock.Naches;
    CapRock.Claypool;
    CapRock.Millett;
    CapRock.LaUnion;
    CapRock.Emmalane;
    CapRock.Farlin;
    CapRock.Weimar;
    CapRock.Kremlin;
    CapRock.Nerstrand;
    CapRock.Cimarron;
}
field_list_calculation Parthenon {
    input {
        Kennedale;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field CapRock.Waubun {
    verify Parthenon;
    update Parthenon;
}
parser OldMines {
   extract( CapRock );
   set_metadata(Duque.BlueAsh, CapRock.Kremlin);
   set_metadata(Duque.CeeVee, CapRock.Weimar);
   set_metadata(Duque.Tonasket, CapRock.Millett);
   set_metadata(Duque.Dubbs, 0);
   set_metadata(Duque.Wapato, 1);
   return select(CapRock.Farlin, CapRock.DeSart, CapRock.Kremlin) {
      0x501 : Volens;
      0x511 : Philip;
      0x506 : Woodrow;
      0 mask 0xFF7000 : Knierim;
      default : ingress;
   }
}
parser Knierim {
   set_metadata(Newburgh.Tidewater, 1);
   return ingress;
}
parser Chenequa {
   extract( Crossnore );
   set_metadata(Duque.BlueAsh, Crossnore.Gunter);
   set_metadata(Duque.CeeVee, Crossnore.Caulfield);
   set_metadata(Duque.Tonasket, Crossnore.Oakes);
   set_metadata(Duque.Dubbs, 1);
   set_metadata(Duque.Wapato, 0);
   return select(Crossnore.Gunter) {
      0x3a : Volens;
      17 : Joshua;
      6 : Woodrow;
      default : Knierim;
   }
}
parser Beaverdam {
   extract( Richlawn );
   set_metadata(Duque.Perrine, 1);
   return ingress;
}
parser Philip {
   extract(Wauregan);
   extract(Cusick);
   set_metadata(Newburgh.Tidewater, 1);
   return select(Wauregan.Chicago) {
      4789 : Dixie;
      default : ingress;
    }
}
parser Volens {
   set_metadata( Wauregan.Hendley, current( 0, 16 ) );
   set_metadata( Wauregan.Chicago, 0 );
   set_metadata( Newburgh.Tidewater, 1 );
   return ingress;
}
parser Joshua {
   set_metadata(Newburgh.Tidewater, 1);
   extract(Wauregan);
   extract(Cusick);
   return ingress;
}
parser Woodrow {
   set_metadata(Newburgh.Evendale, 1);
   set_metadata(Newburgh.Tidewater, 1);
   extract(Wauregan);
   extract(Yscloskey);
   return ingress;
}
parser Indios {
   set_metadata(Newburgh.Timnath, 2);
   return Kirkwood;
}
parser Brantford {
   set_metadata(Newburgh.Timnath, 2);
   return Careywood;
}
parser Berrydale {
   extract(Couchwood);
   return select(Couchwood.Kiana, Couchwood.Gonzalez, Couchwood.Coyote, Couchwood.Shickley, Couchwood.Galloway,
             Couchwood.Bicknell, Couchwood.NeckCity, Couchwood.Redden, Couchwood.Dougherty) {
      0x0800 : Indios;
      0x86dd : Brantford;
      default : ingress;
   }
}
parser Dixie {
   extract(KawCity);
   set_metadata(Newburgh.Timnath, 1);
   return Mineral;
}
field_list Weehawken {
    Lepanto.Supai;
    Lepanto.DeSart;
    Lepanto.Naches;
    Lepanto.Claypool;
    Lepanto.Millett;
    Lepanto.LaUnion;
    Lepanto.Emmalane;
    Lepanto.Farlin;
    Lepanto.Weimar;
    Lepanto.Kremlin;
    Lepanto.Nerstrand;
    Lepanto.Cimarron;
}
field_list_calculation Kinards {
    input {
        Weehawken;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Lepanto.Waubun {
    verify Kinards;
    update Kinards;
}
parser Kirkwood {
   extract( Lepanto );
   set_metadata(Duque.Highfill, Lepanto.Kremlin);
   set_metadata(Duque.Potter, Lepanto.Weimar);
   set_metadata(Duque.Herald, Lepanto.Millett);
   set_metadata(Duque.Angus, 0);
   set_metadata(Duque.Childs, 1);
   return select(Lepanto.Farlin, Lepanto.DeSart, Lepanto.Kremlin) {
      0x501 : Veradale;
      0x511 : Brinson;
      0x506 : Berkey;
      0 mask 0xFF7000 : Bethayres;
      default : ingress;
   }
}
parser Bethayres {
   set_metadata(Newburgh.Nichols, 1);
   return ingress;
}
parser Careywood {
   extract( Wabbaseka );
   set_metadata(Duque.Highfill, Wabbaseka.Gunter);
   set_metadata(Duque.Potter, Wabbaseka.Caulfield);
   set_metadata(Duque.Herald, Wabbaseka.Oakes);
   set_metadata(Duque.Angus, 1);
   set_metadata(Duque.Childs, 0);
   return select(Wabbaseka.Gunter) {
      0x3a : Veradale;
      17 : Brinson;
      6 : Berkey;
      default : Bethayres;
   }
}
parser Veradale {
   set_metadata( Newburgh.Attica, current( 0, 16 ) );
   set_metadata( Newburgh.Calumet, 1 );
   set_metadata( Newburgh.Nichols, 1 );
   return ingress;
}
parser Brinson {
   set_metadata( Newburgh.Attica, current( 0, 16 ) );
   set_metadata( Newburgh.BigLake, current( 16, 16 ) );
   set_metadata( Newburgh.Calumet, 1 );
   set_metadata( Newburgh.Nichols, 1);
   return ingress;
}
parser Berkey {
   set_metadata( Newburgh.Attica, current( 0, 16 ) );
   set_metadata( Newburgh.BigLake, current( 16, 16 ) );
   set_metadata( Newburgh.RedElm, current( 104, 8 ) );
   set_metadata( Newburgh.Calumet, 1 );
   set_metadata( Newburgh.Nichols, 1 );
   set_metadata( Newburgh.Perkasie, 1 );
   extract(Lefors);
   extract(Brunson);
   return ingress;
}
parser Mineral {
   extract( Denning );
   return select( Denning.Montegut ) {
      0x0800: Kirkwood;
      0x86dd: Careywood;
      default: ingress;
   }
}
@pragma pa_no_init ingress Newburgh.Milan
@pragma pa_no_init ingress Newburgh.Tavistock
@pragma pa_no_init ingress Newburgh.Mariemont
@pragma pa_no_init ingress Newburgh.Pringle
metadata Beasley Newburgh;
@pragma pa_no_init ingress Holliston.Covelo
@pragma pa_no_init ingress Holliston.Gheen
@pragma pa_no_init ingress Holliston.Newborn
@pragma pa_no_init ingress Holliston.Harviell
metadata Wausaukee Holliston;
metadata Retrop Realitos;
metadata Menifee Duque;
metadata BirchBay Sewaren;
metadata Valders Aurora;
metadata Manakin Terrytown;
@pragma pa_container_size ingress Terrytown.Townville 32
metadata Billett Lolita;
metadata Olivet Newland;
metadata Jarrell Emmet;
metadata SweetAir Maloy;
metadata Easley Sherando;
metadata Gorum Saragosa;
metadata Eggleston Hawthorn;
@pragma pa_no_init ingress Scotland.Dresden
metadata Wayzata Scotland;
@pragma pa_no_init ingress Masardis.Cardenas
metadata Romeo Masardis;
metadata Norridge Burrel;
metadata Norridge IdaGrove;
action Ewing() {
   no_op();
}
action McCallum() {
   modify_field(Newburgh.Kalkaska, 1 );
   mark_for_drop();
}
action Newtok() {
   no_op();
}
action Bellville(Mynard, Truro, Maury, Denby, Mabelle,
                 Hilburn, Bluewater, Kealia) {
    modify_field(Realitos.Creston, Mynard);
    modify_field(Realitos.Sawpit, Truro);
    modify_field(Realitos.Ocilla, Maury);
    modify_field(Realitos.Uncertain, Denby);
    modify_field(Realitos.Glendevey, Mabelle);
    modify_field(Realitos.Liberal, Hilburn);
    modify_field(Realitos.Algonquin, Bluewater);
    modify_field(Realitos.Karluk, Kealia);
}

@pragma command_line --no-dead-code-elimination
table Lostwood {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Bellville;
    }
    size : 288;
}
control Orrum {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Lostwood);
    }
}
action Paxtonia(Nestoria, Surrey) {
   modify_field( Holliston.Ragley, 1 );
   modify_field( Holliston.Delmar, Nestoria);
   modify_field( Newburgh.Lenwood, 1 );
   modify_field( Saragosa.Chantilly, Surrey );
}
action Faysville() {
   modify_field( Newburgh.Wellsboro, 1 );
   modify_field( Newburgh.Akhiok, 1 );
}
action Cozad() {
   modify_field( Newburgh.Lenwood, 1 );
}
action Nason() {
   modify_field( Newburgh.Lenwood, 1 );
   modify_field( Newburgh.Wakita, 1 );
}
action Stockdale() {
   modify_field( Newburgh.Zebina, 1 );
}
action Wilmore() {
   modify_field( Newburgh.Akhiok, 1 );
}
counter Seaside {
   type : packets_and_bytes;
   direct : Luhrig;
   min_width: 16;
}
table Luhrig {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Dixboro.Hueytown : ternary;
      Dixboro.Scottdale : ternary;
   }
   actions {
      Paxtonia;
      Faysville;
      Cozad;
      Stockdale;
      Wilmore;
      Nason;
   }
   size : 1024;
}
action Delcambre() {
   modify_field( Newburgh.Florien, 1 );
}
table Wadley {
   reads {
      Dixboro.Larose : ternary;
      Dixboro.Topmost : ternary;
   }
   actions {
      Delcambre;
   }
   size : 512;
}
control Hatfield {
   apply( Luhrig );
   apply( Wadley );
}
action Samantha() {
   modify_field( Sewaren.Tiskilwa, Lepanto.Nerstrand );
   modify_field( Sewaren.Rhinebeck, Lepanto.Cimarron );
   modify_field( Sewaren.Perrin, Lepanto.Naches );
   modify_field( Aurora.Fittstown, Wabbaseka.Cloverly );
   modify_field( Aurora.Covina, Wabbaseka.Despard );
   modify_field( Aurora.Chunchula, Wabbaseka.Palco );
   modify_field( Aurora.Glennie, Wabbaseka.Prismatic );
   modify_field( Newburgh.Milan, Denning.Hueytown );
   modify_field( Newburgh.Tavistock, Denning.Scottdale );
   modify_field( Newburgh.Mariemont, Denning.Larose );
   modify_field( Newburgh.Pringle, Denning.Topmost );
   modify_field( Newburgh.Geismar, Denning.Montegut );
   modify_field( Newburgh.Ortley, Duque.Herald );
   modify_field( Newburgh.Tulia, Duque.Highfill );
   modify_field( Newburgh.Tonkawa, Duque.Potter );
   modify_field( Newburgh.Danforth, Duque.Childs );
   modify_field( Newburgh.Lebanon, Duque.Angus );
   modify_field( Newburgh.Tramway, 0 );
   modify_field( Holliston.Licking, 1 );
   modify_field( Realitos.Liberal, 1 );
   modify_field( Realitos.Algonquin, 0 );
   modify_field( Realitos.Karluk, 0 );
   modify_field( Saragosa.Scherr, 1 );
   modify_field( Saragosa.Lesley, 1 );
   modify_field( Newburgh.Tidewater, Newburgh.Nichols );
   modify_field( Newburgh.Evendale, Newburgh.Perkasie );
}
action Othello() {
   modify_field( Newburgh.Timnath, 0 );
   modify_field( Sewaren.Tiskilwa, CapRock.Nerstrand );
   modify_field( Sewaren.Rhinebeck, CapRock.Cimarron );
   modify_field( Sewaren.Perrin, CapRock.Naches );
   modify_field( Aurora.Fittstown, Crossnore.Cloverly );
   modify_field( Aurora.Covina, Crossnore.Despard );
   modify_field( Aurora.Chunchula, Crossnore.Palco );
   modify_field( Aurora.Glennie, Crossnore.Prismatic );
   modify_field( Newburgh.Milan, Dixboro.Hueytown );
   modify_field( Newburgh.Tavistock, Dixboro.Scottdale );
   modify_field( Newburgh.Mariemont, Dixboro.Larose );
   modify_field( Newburgh.Pringle, Dixboro.Topmost );
   modify_field( Newburgh.Geismar, Dixboro.Montegut );
   modify_field( Newburgh.Ortley, Duque.Tonasket );
   modify_field( Newburgh.Tulia, Duque.BlueAsh );
   modify_field( Newburgh.Tonkawa, Duque.CeeVee );
   modify_field( Newburgh.Danforth, Duque.Wapato );
   modify_field( Newburgh.Lebanon, Duque.Dubbs );
   modify_field( Saragosa.McDaniels, McCaulley[0].Toxey );
   modify_field( Newburgh.Tramway, Duque.Laneburg );
   modify_field( Newburgh.Attica, Wauregan.Hendley );
   modify_field( Newburgh.BigLake, Wauregan.Chicago );
   modify_field( Newburgh.RedElm, Yscloskey.McMurray );
}
table WildRose {
   reads {
      Dixboro.Hueytown : exact;
      Dixboro.Scottdale : exact;
      CapRock.Cimarron : exact;
      Newburgh.Timnath : exact;
   }
   actions {
      Samantha;
      Othello;
   }
   default_action : Othello();
   size : 1024;
}
action Corfu() {
   modify_field( Newburgh.Ellicott, Realitos.Ocilla );
   modify_field( Newburgh.Theta, Realitos.Creston);
}
action Courtdale( Naguabo ) {
   modify_field( Newburgh.Ellicott, Naguabo );
   modify_field( Newburgh.Theta, Realitos.Creston);
}
action Lowemont() {
   modify_field( Newburgh.Ellicott, McCaulley[0].Batchelor );
   modify_field( Newburgh.Theta, Realitos.Creston);
}
table Perma {
   reads {
      Realitos.Creston : ternary;
      McCaulley[0] : valid;
      McCaulley[0].Batchelor : ternary;
   }
   actions {
      Corfu;
      Courtdale;
      Lowemont;
   }
   size : 4096;
}
action Magazine( Meeker ) {
   modify_field( Newburgh.Theta, Meeker );
}
action Nuevo() {
   modify_field( Newburgh.Sidnaw, 1 );
   modify_field( Newland.RedBay,
                 1 );
}
table Cassa {
   reads {
      CapRock.Nerstrand : exact;
   }
   actions {
      Magazine;
      Nuevo;
   }
   default_action : Nuevo;
   size : 4096;
}
action Coverdale( Trujillo, Harleton, Dairyland, Ricketts, Dabney,
                        Annette, SanRemo ) {
   modify_field( Newburgh.Ellicott, Trujillo );
   modify_field( Newburgh.Thalmann, Trujillo );
   modify_field( Newburgh.Edmondson, SanRemo );
   Dialville(Harleton, Dairyland, Ricketts, Dabney,
                        Annette );
}
action Shopville() {
   modify_field( Newburgh.Hilgard, 1 );
}
table Montague {
   reads {
      KawCity.Orting : exact;
   }
   actions {
      Coverdale;
      Shopville;
   }
   size : 4096;
}
action Dialville(Stampley, Chappells, Scanlon, Farner,
                        Lansing ) {
   modify_field( Lolita.Allegan, Stampley );
   modify_field( Lolita.Grygla, Chappells );
   modify_field( Lolita.Petoskey, Scanlon );
   modify_field( Lolita.Shauck, Farner );
   modify_field( Lolita.HighRock, Lansing );
}
action Stateline(LaneCity, Cowden, Callery, Taneytown,
                        Croft ) {
   modify_field( Newburgh.Thalmann, Realitos.Ocilla );
   Dialville(LaneCity, Cowden, Callery, Taneytown,
                        Croft );
}
action Calamine(Sutter, Lizella, Tontogany, LeCenter,
                        Dandridge, CassCity ) {
   modify_field( Newburgh.Thalmann, Sutter );
   Dialville(Lizella, Tontogany, LeCenter, Dandridge,
                        CassCity );
}
action Villas(Churchill, Frederika, Garcia, Portville,
                        Wibaux ) {
   modify_field( Newburgh.Thalmann, McCaulley[0].Batchelor );
   Dialville(Churchill, Frederika, Garcia, Portville,
                        Wibaux );
}
table Ossining {
   reads {
      Realitos.Ocilla : exact;
   }
   actions {
      Ewing;
      Stateline;
   }
   size : 4096;
}
@pragma action_default_only Ewing
table RoyalOak {
   reads {
      Realitos.Creston : exact;
      McCaulley[0].Batchelor : exact;
   }
   actions {
      Calamine;
      Ewing;
   }
   size : 1024;
}
table Pueblo {
   reads {
      McCaulley[0].Batchelor : exact;
   }
   actions {
      Ewing;
      Villas;
   }
   size : 4096;
}
control Burket {
   apply( WildRose ) {
         Samantha {
            apply( Cassa );
            apply( Montague );
         }
         Othello {
            if ( not valid(Lamar) and Realitos.Uncertain == 1 ) {
               apply( Perma );
            }
            if ( valid( McCaulley[ 0 ] ) ) {
               apply( RoyalOak ) {
                  Ewing {
                     apply( Pueblo );
                  }
               }
            } else {
               apply( Ossining );
            }
         }
   }
}
register Simla {
    width : 1;
    static : Timken;
    instance_count : 294912;
}
register Lowes {
    width : 1;
    static : Elmont;
    instance_count : 294912;
}
blackbox stateful_alu Portal {
    reg : Simla;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : Terrytown.Upalco;
}
blackbox stateful_alu Olene {
    reg : Lowes;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst : Terrytown.Townville;
}
field_list Charters {
    ig_intr_md.ingress_port;
    McCaulley[0].Batchelor;
}
field_list_calculation Cascadia {
    input { Charters; }
    algorithm: identity;
    output_width: 19;
}
action Rawson() {
    Portal.execute_stateful_alu_from_hash(Cascadia);
}
action Sarasota() {
    Olene.execute_stateful_alu_from_hash(Cascadia);
}
table Timken {
    actions {
      Rawson;
    }
    default_action : Rawson;
    size : 1;
}
table Elmont {
    actions {
      Sarasota;
    }
    default_action : Sarasota;
    size : 1;
}
action Manilla(Denhoff) {
    modify_field(Terrytown.Townville, Denhoff);
}
@pragma use_hash_action 0
table Depew {
    reads {
       ig_intr_md.ingress_port mask 0x7f : exact;
    }
    actions {
      Manilla;
    }
    size : 72;
}
action Wardville() {
   modify_field( Newburgh.Odessa, Realitos.Ocilla );
   modify_field( Newburgh.Bavaria, 0 );
}
table Mangham {
   actions {
      Wardville;
   }
   size : 1;
}
action Wenham() {
   modify_field( Newburgh.Odessa, McCaulley[0].Batchelor );
   modify_field( Newburgh.Bavaria, 1 );
}
table LasLomas {
   actions {
      Wenham;
   }
   size : 1;
}
control Calabasas {
   if ( valid( McCaulley[ 0 ] ) ) {
      apply( LasLomas );
      if( Realitos.Glendevey == 1 ) {
         apply( Timken );
         apply( Elmont );
      }
   } else {
      apply( Mangham );
      if( Realitos.Glendevey == 1 ) {
         apply( Depew );
      }
   }
}
field_list Calhan {
   Dixboro.Hueytown;
   Dixboro.Scottdale;
   Dixboro.Larose;
   Dixboro.Topmost;
   Dixboro.Montegut;
}
field_list Blossburg {
   CapRock.Kremlin;
   CapRock.Nerstrand;
   CapRock.Cimarron;
}
field_list Millston {
   Crossnore.Cloverly;
   Crossnore.Despard;
   Crossnore.Palco;
   Crossnore.Gunter;
}
field_list Birds {
   CapRock.Nerstrand;
   CapRock.Cimarron;
   Wauregan.Hendley;
   Wauregan.Chicago;
}
field_list_calculation Mahopac {
    input {
        Calhan;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Danbury {
    input {
        Blossburg;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation NewRoads {
    input {
        Millston;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Stirrat {
    input {
        Birds;
    }
    algorithm : crc32;
    output_width : 32;
}
action ViewPark() {
    modify_field_with_hash_based_offset(Sherando.Poland, 0,
                                        Mahopac, 4294967296);
}
action Dutton() {
    modify_field_with_hash_based_offset(Sherando.Roachdale, 0,
                                        Danbury, 4294967296);
}
action Magasco() {
    modify_field_with_hash_based_offset(Sherando.Roachdale, 0,
                                        NewRoads, 4294967296);
}
action Atoka() {
    modify_field_with_hash_based_offset(Sherando.Havana, 0,
                                        Stirrat, 4294967296);
}
table Gallion {
   actions {
      ViewPark;
   }
   size: 1;
}
control Fiftysix {
   apply(Gallion);
}
table Tabler {
   actions {
      Dutton;
   }
   size: 1;
}
table Magma {
   actions {
      Magasco;
   }
   size: 1;
}
control Pricedale {
   if ( valid( CapRock ) ) {
      apply(Tabler);
   } else {
      if ( valid( Crossnore ) ) {
         apply(Magma);
      }
   }
}
table Rocky {
   actions {
      Atoka;
   }
   size: 1;
}
control Pittsburg {
   if ( valid( Cusick ) ) {
      apply(Rocky);
   }
}
action Blakeley() {
    modify_field(Maloy.Mocane, Sherando.Poland);
}
action Colstrip() {
    modify_field(Maloy.Mocane, Sherando.Roachdale);
}
action Glassboro() {
    modify_field(Maloy.Mocane, Sherando.Havana);
}
@pragma action_default_only Ewing
@pragma immediate 0
table Jones {
   reads {
      Brunson.valid : ternary;
      Eckman.valid : ternary;
      Lepanto.valid : ternary;
      Wabbaseka.valid : ternary;
      Denning.valid : ternary;
      Yscloskey.valid : ternary;
      Cusick.valid : ternary;
      CapRock.valid : ternary;
      Crossnore.valid : ternary;
      Dixboro.valid : ternary;
   }
   actions {
      Blakeley;
      Colstrip;
      Glassboro;
      Ewing;
   }
   size: 256;
}
action StarLake() {
    modify_field(Maloy.Mantee, Sherando.Havana);
}
@pragma immediate 0
table Ramos {
   reads {
      Brunson.valid : ternary;
      Eckman.valid : ternary;
      Yscloskey.valid : ternary;
      Cusick.valid : ternary;
   }
   actions {
      StarLake;
      Ewing;
   }
   size: 6;
}
control Ogunquit {
   apply(Ramos);
   apply(Jones);
}
counter Carlsbad {
   type : packets_and_bytes;
   direct : Laplace;
   min_width: 16;
}
table Laplace {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Terrytown.Townville : ternary;
      Terrytown.Upalco : ternary;
      Newburgh.Hilgard : ternary;
      Newburgh.Florien : ternary;
      Newburgh.Wellsboro : ternary;
   }
   actions {
      McCallum;
      Ewing;
   }
   default_action : Ewing();
   size : 512;
}
table Tuscumbia {
   reads {
      Newburgh.Mariemont : exact;
      Newburgh.Pringle : exact;
      Newburgh.Ellicott : exact;
   }
   actions {
      McCallum;
      Ewing;
   }
   default_action : Ewing();
   size : 4096;
}
action Honokahua() {
   modify_field(Newburgh.Plush, 1 );
   modify_field(Newland.RedBay,
                0);
}
table Motley {
   reads {
      Newburgh.Mariemont : exact;
      Newburgh.Pringle : exact;
      Newburgh.Ellicott : exact;
      Newburgh.Theta : exact;
   }
   actions {
      Newtok;
      Honokahua;
   }
   default_action : Honokahua();
   size : 65536;
   support_timeout : true;
}
action Alvwood( Traskwood, Champlin ) {
   modify_field( Newburgh.Daniels, Traskwood );
   modify_field( Newburgh.Edmondson, Champlin );
}
action Garwood() {
   modify_field( Newburgh.Edmondson, 1 );
}
table Ironside {
   reads {
      Newburgh.Ellicott mask 0xfff : exact;
   }
   actions {
      Alvwood;
      Garwood;
      Ewing;
   }
   default_action : Ewing();
   size : 4096;
}
action Hartfield() {
   modify_field( Lolita.Greenland, 1 );
}
table Vigus {
   reads {
      Newburgh.Thalmann : ternary;
      Newburgh.Milan : exact;
      Newburgh.Tavistock : exact;
   }
   actions {
      Hartfield;
   }
   size: 512;
}
control Henry {
   apply( Laplace ) {
      Ewing {
         apply( Tuscumbia ) {
            Ewing {
               if (Realitos.Sawpit == 0 and Newburgh.Sidnaw == 0) {
                  apply( Motley );
               }
               apply( Ironside );
               apply(Vigus);
            }
         }
      }
   }
}
field_list Honuapo {
    Newland.RedBay;
    Newburgh.Mariemont;
    Newburgh.Pringle;
    Newburgh.Ellicott;
    Newburgh.Theta;
}
action Ipava() {
   generate_digest(0, Honuapo);
}
table Dushore {
   actions {
      Ipava;
   }
   size : 1;
}
control Mentmore {
   if (Newburgh.Plush == 1) {
      apply( Dushore );
   }
}
action Klukwan( Valentine, Hodge ) {
   modify_field( Aurora.Hershey, Valentine );
   modify_field( Emmet.Ronneby, Hodge );
}
action Hanford( Yocemento, Novice ) {
   modify_field( Aurora.Hershey, Yocemento );
   modify_field( Emmet.Fairlee, Novice );
}
@pragma action_default_only Pittwood
table Devers {
   reads {
      Lolita.Allegan : exact;
      Aurora.Covina mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Klukwan;
      Pittwood;
      Hanford;
   }
   size : 8192;
}
@pragma atcam_partition_index Aurora.Hershey
@pragma atcam_number_partitions 8192
table Lakefield {
   reads {
      Aurora.Hershey : exact;
      Aurora.Covina mask 0x000007FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Daphne;
      Jermyn;
      Ewing;
   }
   default_action : Ewing();
   size : 65536;
}
action Pilar( Gastonia, Derita ) {
   modify_field( Aurora.HydePark, Gastonia );
   modify_field( Emmet.Ronneby, Derita );
}
action Almond( SandCity, Springlee ) {
   modify_field( Aurora.HydePark, SandCity );
   modify_field( Emmet.Fairlee, Springlee );
}
@pragma action_default_only Ewing
table Wildorado {
   reads {
      Lolita.Allegan : exact;
      Aurora.Covina : lpm;
   }
   actions {
      Pilar;
      Almond;
      Ewing;
   }
   size : 2048;
}
@pragma atcam_partition_index Aurora.HydePark
@pragma atcam_number_partitions 2048
table McBrides {
   reads {
      Aurora.HydePark : exact;
      Aurora.Covina mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Daphne;
      Jermyn;
      Ewing;
   }
   default_action : Ewing();
   size : 16384;
}
@pragma action_default_only Pittwood
@pragma idletime_precision 1
table RushCity {
   reads {
      Lolita.Allegan : exact;
      Sewaren.Rhinebeck : lpm;
   }
   actions {
      Daphne;
      Jermyn;
      Pittwood;
   }
   size : 1024;
   support_timeout : true;
}
action Monowi( Freeman, Pachuta ) {
   modify_field( Sewaren.Sarepta, Freeman );
   modify_field( Emmet.Ronneby, Pachuta );
}
action Ribera( Bleecker, Swisshome ) {
   modify_field( Sewaren.Sarepta, Bleecker );
   modify_field( Emmet.Fairlee, Swisshome );
}
@pragma action_default_only Ewing
table Miranda {
   reads {
      Lolita.Allegan : exact;
      Sewaren.Rhinebeck : lpm;
   }
   actions {
      Monowi;
      Ribera;
      Ewing;
   }
   size : 16384;
}
@pragma ways 2
@pragma atcam_partition_index Sewaren.Sarepta
@pragma atcam_number_partitions 16384
table DewyRose {
   reads {
      Sewaren.Sarepta : exact;
      Sewaren.Rhinebeck mask 0x000fffff : lpm;
   }
   actions {
      Daphne;
      Jermyn;
      Ewing;
   }
   default_action : Ewing();
   size : 131072;
}
action Daphne( Orrstown ) {
   modify_field( Emmet.Ronneby, Orrstown );
}
@pragma idletime_precision 1
table Skyway {
   reads {
      Lolita.Allegan : exact;
      Sewaren.Rhinebeck : exact;
   }
   actions {
      Daphne;
      Jermyn;
      Ewing;
   }
   default_action : Ewing();
   size : 65536;
   support_timeout : true;
}
@pragma idletime_precision 1
@pragma stage 2 28672
@pragma stage 3
table Sharon {
   reads {
      Lolita.Allegan : exact;
      Aurora.Covina : exact;
   }
   actions {
      Daphne;
      Jermyn;
      Ewing;
   }
   default_action : Ewing();
   size : 65536;
   support_timeout : true;
}
action Longdale(Anguilla, Tunica, Roosville) {
   modify_field(Holliston.Tofte, Roosville);
   modify_field(Holliston.Covelo, Anguilla);
   modify_field(Holliston.Gheen, Tunica);
   modify_field(Holliston.Doddridge, 1);
   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}
action Stella() {
   McCallum();
}
action Ashtola(Ruffin) {
   modify_field(Holliston.Ragley, 1);
   modify_field(Holliston.Delmar, Ruffin);
}
action Pittwood(RockPort) {
   modify_field( Holliston.Ragley, 1 );
   modify_field( Holliston.Delmar, 9 );
}
table Sargeant {
   reads {
      Emmet.Ronneby : exact;
   }
   actions {
      Longdale;
      Stella;
      Ashtola;
   }
   size : 65536;
}
action SnowLake( Wyanet ) {
   modify_field(Holliston.Ragley, 1);
   modify_field(Holliston.Delmar, Wyanet);
}
table Poneto {
   actions {
      SnowLake;
   }
   default_action: SnowLake(0);
   size : 1;
}
control Joslin {
   if ( Newburgh.Kalkaska == 0 and Lolita.Greenland == 1 ) {
      if ( ( Lolita.Grygla == 1 ) and ( Newburgh.Danforth == 1 ) ) {
         apply( Skyway ) {
            Ewing {
               apply(Miranda);
            }
         }
      } else if ( ( Lolita.Petoskey == 1 ) and ( Newburgh.Lebanon == 1 ) ) {
         apply( Sharon ) {
            Ewing {
               apply( Wildorado );
            }
         }
      }
   }
}
control Chatanika {
   if ( Newburgh.Kalkaska == 0 and Lolita.Greenland == 1 ) {
      if ( ( Lolita.Grygla == 1 ) and ( Newburgh.Danforth == 1 ) ) {
         if ( Sewaren.Sarepta != 0 ) {
            apply( DewyRose );
         } else if ( Emmet.Ronneby == 0 and Emmet.Fairlee == 0 ) {
            apply( RushCity );
         }
      } else if ( ( Lolita.Petoskey == 1 ) and ( Newburgh.Lebanon == 1 ) ) {
         if ( Aurora.HydePark != 0 ) {
            apply( McBrides );
         } else if ( Emmet.Ronneby == 0 and Emmet.Fairlee == 0 ) {
            apply( Devers );
            if ( Aurora.Hershey != 0 ) {
               apply( Lakefield );
            }
         }
      } else if( Newburgh.Edmondson == 1 ) {
         apply( Poneto );
      }
   }
}
control Parshall {
   if( Emmet.Ronneby != 0 ) {
      apply( Sargeant );
   }
}
action Jermyn( Honaker ) {
   modify_field( Emmet.Fairlee, Honaker );
}
field_list Covington {
   Maloy.Mantee;
}
field_list_calculation Aguilita {
    input {
        Covington;
    }
    algorithm : identity;
    output_width : 66;
}
action_selector Thawville {
   selection_key : Aguilita;
   selection_mode : resilient;
}
action_profile Ranburne {
   actions {
      Daphne;
   }
   size : 65536;
   dynamic_action_selection : Thawville;
}
@pragma selector_max_group_size 256
table Gilmanton {
   reads {
      Emmet.Fairlee : exact;
   }
   action_profile : Ranburne;
   size : 2048;
}
control CoalCity {
   if ( Emmet.Fairlee != 0 ) {
      apply( Gilmanton );
   }
}
field_list Waialee {
   Maloy.Mocane;
}
field_list_calculation Kahaluu {
    input {
        Waialee;
    }
    algorithm : identity;
    output_width : 51;
}
action_selector Pioche {
    selection_key : Kahaluu;
    selection_mode : resilient;
}
action Twisp(Edler) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Edler);
}
action_profile Ganado {
    actions {
        Twisp;
        Ewing;
    }
    size : 1024;
    dynamic_action_selection : Pioche;
}
table Haley {
   reads {
      Holliston.Gilman : exact;
   }
   action_profile: Ganado;
   size : 1024;
}
control AukeBay {
   if ((Holliston.Gilman & 0x2000) == 0x2000) {
      apply(Haley);
   }
}
action Earling() {
   modify_field(Holliston.Covelo, Newburgh.Milan);
   modify_field(Holliston.Gheen, Newburgh.Tavistock);
   modify_field(Holliston.Newborn, Newburgh.Mariemont);
   modify_field(Holliston.Harviell, Newburgh.Pringle);
   modify_field(Holliston.Tofte, Newburgh.Ellicott);
   invalidate( ig_intr_md_for_tm.ucast_egress_port );
}
table Provencal {
   actions {
      Earling;
   }
   default_action : Earling();
   size : 1;
}
control Chouteau {
   apply( Provencal );
}
action Bunker() {
   modify_field(Holliston.Wyndmere, 1);
   modify_field(Holliston.Yerington, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Newburgh.Edmondson);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Holliston.Tofte);
}
action FairOaks() {
}
@pragma ways 1
table Alamance {
   reads {
      Holliston.Covelo : exact;
      Holliston.Gheen : exact;
   }
   actions {
      Bunker;
      FairOaks;
   }
   default_action : FairOaks;
   size : 1;
}
action Mizpah() {
   modify_field(Holliston.Thach, 1);
   modify_field(Holliston.Lucile, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Holliston.Tofte, 4096);
}
table Kelsey {
   actions {
      Mizpah;
   }
   default_action : Mizpah;
   size : 1;
}
action LeMars() {
   modify_field(Holliston.Hammocks, 1);
   modify_field(Holliston.Yerington, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Holliston.Tofte);
}
table Paisano {
   actions {
      LeMars;
   }
   default_action : LeMars();
   size : 1;
}
action Wyocena(Kathleen) {
   modify_field(Holliston.Twichell, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Kathleen);
   modify_field(Holliston.Gilman, Kathleen);
}
action Raritan(Converse) {
   modify_field(Holliston.Thach, 1);
   modify_field(Holliston.Radom, Converse);
}
action Algodones() {
}
table Kaltag {
   reads {
      Holliston.Covelo : exact;
      Holliston.Gheen : exact;
      Holliston.Tofte : exact;
   }
   actions {
      Wyocena;
      Raritan;
      McCallum;
      Algodones;
   }
   default_action : Algodones();
   size : 65536;
}
control Kiwalik {
   if (Newburgh.Kalkaska == 0 and not valid(Lamar) ) {
      apply(Kaltag) {
         Algodones {
            apply(Alamance) {
               FairOaks {
                  if ((Holliston.Covelo & 0x010000) == 0x010000) {
                     apply(Kelsey);
                  } else {
                     apply(Paisano);
                  }
               }
            }
         }
      }
   }
}
action Melmore() {
   modify_field(Newburgh.Anson, 1);
   McCallum();
}
table Ironia {
   actions {
      Melmore;
   }
   default_action : Melmore;
   size : 1;
}
control Millican {
   if (Newburgh.Kalkaska == 0) {
      if ((Holliston.Doddridge==0) and (Newburgh.Lenwood==0) and (Newburgh.Zebina==0) and (Newburgh.Theta==Holliston.Gilman)) {
         apply(Ironia);
      } else {
         AukeBay();
      }
   }
}
action Sunflower( MiraLoma ) {
   modify_field( Holliston.Mifflin, MiraLoma );
}
action Osseo() {
   modify_field( Holliston.Mifflin, Holliston.Tofte );
}
table ElmGrove {
   reads {
      eg_intr_md.egress_port : exact;
      Holliston.Tofte : exact;
   }
   actions {
      Sunflower;
      Osseo;
   }
   default_action : Osseo;
   size : 4096;
}
control Johnstown {
   apply( ElmGrove );
}
action Tannehill( Cochise, Halbur ) {
   modify_field( Holliston.Odell, Cochise );
   modify_field( Holliston.Piermont, Halbur );
}
table Cresco {
   reads {
      Holliston.Galestown : exact;
   }
   actions {
      Tannehill;
   }
   size : 8;
}
action Marshall() {
   modify_field( Holliston.Brohard, 1 );
   modify_field( Holliston.Galestown, 2 );
}
action Haslet() {
   modify_field( Holliston.Brohard, 1 );
   modify_field( Holliston.Galestown, 1 );
}
table Poulan {
   reads {
      Holliston.Danese : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Marshall;
      Haslet;
   }
   default_action : Ewing();
   size : 16;
}
action Uniontown(Ceiba, Bayshore, Pearland, Bangor) {
   modify_field( Holliston.Novinger, Ceiba );
   modify_field( Holliston.Stuttgart, Bayshore );
   modify_field( Holliston.Stanwood, Pearland );
   modify_field( Holliston.Jonesport, Bangor );
}
table Rudolph {
   reads {
        Holliston.SanPablo : exact;
   }
   actions {
      Uniontown;
   }
   size : 256;
}
action Caballo() {
   no_op();
}
action ElRio() {
   modify_field( Dixboro.Montegut, McCaulley[0].Poynette );
   remove_header( McCaulley[0] );
}
table Stillmore {
   actions {
      ElRio;
   }
   default_action : ElRio;
   size : 1;
}
action Garlin() {
   no_op();
}
action Rippon() {
   add_header( McCaulley[ 0 ] );
   modify_field( McCaulley[0].Batchelor, Holliston.Mifflin );
   modify_field( McCaulley[0].Poynette, Dixboro.Montegut );
   modify_field( McCaulley[0].Hoadly, Saragosa.Bronaugh );
   modify_field( McCaulley[0].Toxey, Saragosa.McDaniels );
   modify_field( Dixboro.Montegut, 0x8100 );
}
table Qulin {
   reads {
      Holliston.Mifflin : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Garlin;
      Rippon;
   }
   default_action : Rippon;
   size : 128;
}
action BigPoint() {
   modify_field(Dixboro.Hueytown, Holliston.Covelo);
   modify_field(Dixboro.Scottdale, Holliston.Gheen);
   modify_field(Dixboro.Larose, Holliston.Odell);
   modify_field(Dixboro.Topmost, Holliston.Piermont);
}
action Holtville() {
   BigPoint();
   add_to_field(CapRock.Weimar, -1);
   modify_field(CapRock.Naches, Saragosa.Seaford);
}
action Greenlawn() {
   BigPoint();
   add_to_field(Crossnore.Caulfield, -1);
   modify_field(Crossnore.Prismatic, Saragosa.Seaford);
}
action Satanta() {
   modify_field(CapRock.Naches, Saragosa.Seaford);
}
action Oneonta() {
   modify_field(Crossnore.Prismatic, Saragosa.Seaford);
}
action Brinklow() {
   Rippon();
}
action Berville( Fleetwood, Hanahan, Driftwood, Petroleum ) {
   add_header( Baranof );
   modify_field( Baranof.Hueytown, Fleetwood );
   modify_field( Baranof.Scottdale, Hanahan );
   modify_field( Baranof.Larose, Driftwood );
   modify_field( Baranof.Topmost, Petroleum );
   modify_field( Baranof.Montegut, 0xBF00 );
   add_header( Lamar );
   modify_field( Lamar.BigRock, Holliston.Novinger );
   modify_field( Lamar.Trail, Holliston.Stuttgart );
   modify_field( Lamar.Lopeno, Holliston.Stanwood );
   modify_field( Lamar.Edroy, Holliston.Jonesport );
   modify_field( Lamar.Norma, Holliston.Delmar );
}
action Kranzburg() {
   remove_header( KawCity );
   remove_header( Cusick );
   remove_header( Wauregan );
   copy_header( Dixboro, Denning );
   remove_header( Denning );
   remove_header( CapRock );
}
action Upland() {
   remove_header( Baranof );
   remove_header( Lamar );
}
action Kosmos() {
   Kranzburg();
   modify_field(Lepanto.Naches, Saragosa.Seaford);
}
action Maupin() {
   Kranzburg();
   modify_field(Wabbaseka.Prismatic, Saragosa.Seaford);
}
table Hilbert {
   reads {
      Holliston.Licking : exact;
      Holliston.Galestown : exact;
      Holliston.Doddridge : exact;
      CapRock.valid : ternary;
      Crossnore.valid : ternary;
      Lepanto.valid : ternary;
      Wabbaseka.valid : ternary;
   }
   actions {
      Holtville;
      Greenlawn;
      Satanta;
      Oneonta;
      Brinklow;
      Berville;
      Upland;
      Kranzburg;
      Kosmos;
      Maupin;
   }
   size : 512;
}
control Leona {
   apply( Stillmore );
}
control Shawmut {
   apply( Qulin );
}
control Elbert {
   apply( Poulan ) {
      Ewing {
         apply( Cresco );
      }
   }
   apply( Rudolph );
   apply( Hilbert );
}
field_list Wimberley {
    Newland.RedBay;
    Newburgh.Ellicott;
    Denning.Larose;
    Denning.Topmost;
    CapRock.Nerstrand;
}
action Chandalar() {
   generate_digest(0, Wimberley);
}
table Poteet {
   actions {
      Chandalar;
   }
   default_action : Chandalar;
   size : 1;
}
control Lamona {
   if (Newburgh.Sidnaw == 1) {
      apply(Poteet);
   }
}
action Lovewell() {
   modify_field( Saragosa.Bronaugh, Realitos.Algonquin );
}
action Pierpont() {
   modify_field( Saragosa.Bronaugh, McCaulley[0].Hoadly );
   modify_field( Newburgh.Geismar, McCaulley[0].Poynette );
}
action Rockdell() {
   modify_field( Saragosa.Seaford, Realitos.Karluk );
}
action SourLake() {
   modify_field( Saragosa.Seaford, Sewaren.Perrin );
}
action Sontag() {
   modify_field( Saragosa.Seaford, Aurora.Glennie );
}
action Zemple( Between, Eddystone ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Between );
   modify_field( ig_intr_md_for_tm.qid, Eddystone );
}
table Skime {
   reads {
     Newburgh.Tramway : exact;
   }
   actions {
     Lovewell;
     Pierpont;
   }
   size : 2;
}
table Arpin {
   reads {
     Newburgh.Danforth : exact;
     Newburgh.Lebanon : exact;
   }
   actions {
     Rockdell;
     SourLake;
     Sontag;
   }
   size : 3;
}
table Holladay {
   reads {
      Realitos.Liberal : ternary;
      Realitos.Algonquin : ternary;
      Saragosa.Bronaugh : ternary;
      Saragosa.Seaford : ternary;
      Saragosa.Chantilly : ternary;
   }
   actions {
      Zemple;
   }
   size : 81;
}
action Jefferson( Leadpoint, Gardena ) {
   bit_or( Saragosa.Scherr, Saragosa.Scherr, Leadpoint );
   bit_or( Saragosa.Lesley, Saragosa.Lesley, Gardena );
}
table ElToro {
   actions {
      Jefferson;
   }
   default_action : Jefferson(0, 0);
   size : 1;
}
action Achille( Aspetuck ) {
   modify_field( Saragosa.Seaford, Aspetuck );
}
action Homeacre( FulksRun ) {
   modify_field( Saragosa.Bronaugh, FulksRun );
}
action Hohenwald( Ackerly, Skagway ) {
   modify_field( Saragosa.Bronaugh, Ackerly );
   modify_field( Saragosa.Seaford, Skagway );
}
table Clifton {
   reads {
      Realitos.Liberal : exact;
      Saragosa.Scherr : exact;
      Saragosa.Lesley : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Achille;
      Homeacre;
      Hohenwald;
   }
   size : 512;
}
control Montello {
   apply( Skime );
   apply( Arpin );
}
control Emlenton {
   apply( Holladay );
}
control McKee {
   apply( ElToro );
   apply( Clifton );
}
action Antonito( Mishawaka ) {
   modify_field( Saragosa.Dunbar, Mishawaka );
}
action Amesville( Noelke, Humacao ) {
   Antonito( Noelke );
   modify_field( ig_intr_md_for_tm.qid, Humacao );
}
table Winger {
   reads {
      Holliston.Ragley : ternary;
      ig_intr_md_for_tm.copy_to_cpu : ternary;
      Holliston.Delmar : ternary;
      Newburgh.Danforth : ternary;
      Newburgh.Lebanon : ternary;
      Newburgh.Geismar : ternary;
      Newburgh.Tulia : ternary;
      Newburgh.Tonkawa : ternary;
      Holliston.Doddridge : ternary;
      Wauregan.Hendley : ternary;
      Wauregan.Chicago : ternary;
   }
   actions {
      Antonito;
      Amesville;
   }
   size : 512;
}
meter Roscommon {
   type : packets;
   static : Emsworth;
   instance_count : 2304;
}
action Lordstown(Dunphy) {
   execute_meter( Roscommon, Dunphy, ig_intr_md_for_tm.packet_color );
}
table Emsworth {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Saragosa.Dunbar : exact;
   }
   actions {
      Lordstown;
   }
   size : 2304;
}
counter Leola {
   type : packets;
   instance_count : 32;
   min_width : 128;
}
action Valsetz() {
   count( Leola, Saragosa.Dunbar );
}
table Salome {
   actions {
     Valsetz;
   }
   default_action : Valsetz;
   size : 1;
}
control Canton {
    if ( (
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x1 ) == 0 ) ) and ( Holliston.Ragley == 1 ) ) or
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x2 ) == 0 ) ) and ( ig_intr_md_for_tm.copy_to_cpu == 1 ) )
       ) ) {
      apply( Emsworth );
      apply( Salome );
   }
}
action Alakanuk( Senatobia ) {
   modify_field( Holliston.Danese, 0 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Senatobia );
   modify_field( Holliston.SanPablo, ig_intr_md.ingress_port );
}
action Samson( Boistfort ) {
   modify_field( Holliston.Danese, 1 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Boistfort );
   modify_field( Holliston.SanPablo, ig_intr_md.ingress_port );
}
action Kiron() {
   modify_field( Holliston.Danese, 0 );
}
action BigWells() {
   modify_field( Holliston.Danese, 1 );
   modify_field( Holliston.SanPablo, ig_intr_md.ingress_port );
}
@pragma ternary 1
table Marcus {
   reads {
      Holliston.Ragley : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      Lolita.Greenland : exact;
      Realitos.Uncertain : ternary;
      Holliston.Delmar : ternary;
   }
   actions {
      Alakanuk;
      Samson;
      Kiron;
      BigWells;
   }
   size : 512;
}
control Magnolia {
   apply( Marcus );
}
counter Shipman {
   type : packets_and_bytes;
   instance_count : 1024;
   min_width : 128;
}
action Lydia( Yorkshire ) {
   count( Shipman, Yorkshire );
}
table Laurie {
   reads {
      eg_intr_md.egress_port mask 0x7f: exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }
   actions {
     Lydia;
   }
   size : 1024;
}
control Nankin {
   apply( Laurie );
}
action Mekoryuk()
{
   McCallum();
}
action OldGlory()
{
   modify_field(Holliston.Licking, 2);
   bit_or(Holliston.Gilman, 0x2000, Lamar.Edroy);
}
action LaMarque( Seguin ) {
   modify_field(Holliston.Licking, 2);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Seguin);
   modify_field(Holliston.Gilman, Seguin);
}
table Horsehead {
   reads {
      Lamar.BigRock : exact;
      Lamar.Trail : exact;
      Lamar.Lopeno : exact;
      Lamar.Edroy : exact;
   }
   actions {
      OldGlory;
      LaMarque;
      Mekoryuk;
   }
   default_action : Mekoryuk();
   size : 256;
}
control Cowen {
   apply( Horsehead );
}
action Sunrise( Uintah, Braymer, Anahola, Hisle ) {
   modify_field( Hawthorn.Hanston, Uintah );
   modify_field( Masardis.Lacombe, Anahola );
   modify_field( Masardis.Cardenas, Braymer );
   modify_field( Masardis.Fairlea, Hisle );
}
table Oilmont {
   reads {
     Sewaren.Rhinebeck : exact;
     Newburgh.Thalmann : exact;
   }
   actions {
      Sunrise;
   }
  size : 16384;
}
action Arroyo(MillCity, Padonia, Astatula) {
   modify_field( Masardis.Cardenas, MillCity );
   modify_field( Masardis.Lacombe, Padonia );
   modify_field( Masardis.Fairlea, Astatula );
}
table Nelson {
   reads {
     Sewaren.Tiskilwa : exact;
     Hawthorn.Hanston : exact;
   }
   actions {
      Arroyo;
   }
   size : 16384;
}
action Tiburon( Bazine, ElMirage, Giltner ) {
   modify_field( Scotland.Dresden, Bazine );
   modify_field( Scotland.Gracewood, ElMirage );
   modify_field( Scotland.Malabar, Giltner );
}
table Heads {
   reads {
     Holliston.Covelo : exact;
     Holliston.Gheen : exact;
     Holliston.Tofte : exact;
   }
   actions {
      Tiburon;
   }
   size : 16384;
}
action Earlham() {
   modify_field( Holliston.Yerington, 1 );
}
action Schaller( Elkville, Wayland ) {
   Earlham();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Masardis.Cardenas );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Elkville, Masardis.Fairlea );
   bit_or( Saragosa.Dunbar, Saragosa.Dunbar, Wayland );
}
action Jayton( Hercules, Armagh ) {
   Earlham();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Scotland.Dresden );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Hercules, Scotland.Malabar );
   bit_or( Saragosa.Dunbar, Saragosa.Dunbar, Armagh );
}
action Dillsboro( Everest, Perrytown ) {
   Earlham();
   add( ig_intr_md_for_tm.mcast_grp_a, Holliston.Tofte,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Everest );
   bit_or( Saragosa.Dunbar, Saragosa.Dunbar, Perrytown );
}
action Attalla() {
   modify_field( Holliston.Raceland, 1 );
}
table Peebles {
   reads {
     Masardis.Lacombe : ternary;
     Masardis.Cardenas : ternary;
     Scotland.Dresden : ternary;
     Scotland.Gracewood : ternary;
     Newburgh.Tulia :ternary;
     Newburgh.Lenwood:ternary;
   }
   actions {
      Schaller;
      Jayton;
      Dillsboro;
      Attalla;
   }
   size : 32;
}
control Petrolia {
   if( Newburgh.Kalkaska == 0 and
       Lolita.Shauck == 1 and
       Newburgh.Wakita == 1 ) {
      apply( Oilmont );
   }
}
control Donner {
   if( Hawthorn.Hanston != 0 ) {
      apply( Nelson );
   }
}
control Jenison {
   if( Newburgh.Kalkaska == 0 and Newburgh.Lenwood==1 ) {
      apply( Heads );
   }
}
action Linganore(Maytown) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Maloy.Mocane );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Maytown );
}
table Conger {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Linganore;
    }
    size : 512;
}
control Amber {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Conger);
   }
}
action Moark( Cleta, Gibson ) {
   modify_field( Holliston.Tofte, Cleta );
   modify_field( Holliston.Doddridge, Gibson );
}
action Marysvale() {
   drop();
}
table Suntrana {
   reads {
     eg_intr_md.egress_rid: exact;
   }
   actions {
      Moark;
   }
   default_action: Marysvale;
   size : 57344;
}
control Abernant {
   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Suntrana);
   }
}
counter Fallis {
   type : packets;
   direct: Darien;
   min_width: 63;
}
table Darien {
   reads {
     Sargent.Tulsa mask 0x7fff : exact;
   }
   actions {
      Ewing;
   }
   default_action: Ewing();
   size : 32768;
}
action Bratenahl() {
   modify_field( Burrel.Ashwood, Newburgh.Tulia );
   modify_field( Burrel.BigBar, Sewaren.Perrin );
   modify_field( Burrel.Catlin, Newburgh.Tonkawa );
   modify_field( Burrel.Veneta, Newburgh.RedElm );
   bit_xor( Burrel.Armijo, Newburgh.Tidewater, 1 );
}
action Macon() {
   modify_field( Burrel.Ashwood, Newburgh.Tulia );
   modify_field( Burrel.BigBar, Aurora.Glennie );
   modify_field( Burrel.Catlin, Newburgh.Tonkawa );
   modify_field( Burrel.Veneta, Newburgh.RedElm );
   bit_xor( Burrel.Armijo, Newburgh.Tidewater, 1 );
}
action Lakehurst( Stratton ) {
   Bratenahl();
   modify_field( Burrel.Glenpool, Stratton );
}
action Paoli( Logandale ) {
   Macon();
   modify_field( Burrel.Glenpool, Logandale );
}
table Edinburgh {
   reads {
     Sewaren.Tiskilwa : ternary;
   }
   actions {
      Lakehurst;
   }
   default_action : Bratenahl;
  size : 2048;
}
table Talco {
   reads {
     Aurora.Fittstown : ternary;
   }
   actions {
      Paoli;
   }
   default_action : Macon;
   size : 1024;
}
action Bloomdale( Tobique ) {
   modify_field( Burrel.Hotchkiss, Tobique );
}
table Higley {
   reads {
     Sewaren.Rhinebeck : ternary;
   }
   actions {
      Bloomdale;
   }
   size : 512;
}
table BigBay {
   reads {
     Aurora.Covina : ternary;
   }
   actions {
      Bloomdale;
   }
   size : 512;
}
action Ripley( Kittredge ) {
   modify_field( Burrel.Bellmore, Kittredge );
}
table Craigmont {
   reads {
     Newburgh.Attica : ternary;
   }
   actions {
      Ripley;
   }
   size : 512;
}
action Gower( Suffolk ) {
   modify_field( Burrel.Lubec, Suffolk );
}
table Swaledale {
   reads {
     Newburgh.BigLake : ternary;
   }
   actions {
      Gower;
   }
   size : 512;
}
action Chatom( Goldman ) {
   modify_field( Burrel.Shobonier, Goldman );
}
action Brodnax( Kinney ) {
   modify_field( Burrel.Shobonier, Kinney );
}
table Nutria {
   reads {
     Newburgh.Danforth : exact;
     Newburgh.Lebanon : exact;
     Newburgh.Evendale : exact;
     Newburgh.Thalmann : exact;
   }
   actions {
      Chatom;
      Ewing;
   }
   default_action : Ewing();
   size : 4096;
}
table Deport {
   reads {
     Newburgh.Danforth : exact;
     Newburgh.Lebanon : exact;
     Newburgh.Evendale : exact;
     Realitos.Creston : exact;
   }
   actions {
      Brodnax;
   }
   size : 512;
}
control Carlin {
   if( Newburgh.Danforth == 1 ) {
      apply( Edinburgh );
      apply( Higley );
   } else if( Newburgh.Lebanon == 1 ) {
      apply( Talco );
      apply( BigBay );
   }
   if( ( Newburgh.Timnath != 0 and Newburgh.Calumet == 1 ) or
       ( Newburgh.Timnath == 0 and Wauregan.valid == 1 ) ) {
      apply( Craigmont );
      if( Newburgh.Tulia != 1 ){
         apply( Swaledale );
      }
   }
   apply( Nutria ) {
      Ewing {
         apply( Deport );
      }
   }
}
action Vanzant() {
}
action Corvallis() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action Anandale() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
}
action Dunnegan() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
table FifeLake {
   reads {
     Sargent.Tulsa mask 0x00018000 : ternary;
   }
   actions {
      Vanzant;
      Corvallis;
      Anandale;
      Dunnegan;
   }
   size : 16;
}
control Anchorage {
   apply( FifeLake );
   apply( Darien );
}
   metadata Cordell Sargent;
   action Pathfork( Pettry ) {
          max( Sargent.Tulsa, Sargent.Tulsa, Pettry );
   }
@pragma ways 4
table Rushton {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : exact;
      Burrel.Hotchkiss : exact;
      Burrel.Bellmore : exact;
      Burrel.Lubec : exact;
      Burrel.Ashwood : exact;
      Burrel.BigBar : exact;
      Burrel.Catlin : exact;
      Burrel.Veneta : exact;
      Burrel.Armijo : exact;
   }
   actions {
      Pathfork;
   }
   size : 4096;
}
control Oakridge {
   apply( Rushton );
}
table Blencoe {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : ternary;
      Burrel.Hotchkiss : ternary;
      Burrel.Bellmore : ternary;
      Burrel.Lubec : ternary;
      Burrel.Ashwood : ternary;
      Burrel.BigBar : ternary;
      Burrel.Catlin : ternary;
      Burrel.Veneta : ternary;
      Burrel.Armijo : ternary;
   }
   actions {
      Pathfork;
   }
   size : 512;
}
control Palatka {
   apply( Blencoe );
}
@pragma pa_no_init ingress Edwards.Glenpool
@pragma pa_no_init ingress Edwards.Hotchkiss
@pragma pa_no_init ingress Edwards.Bellmore
@pragma pa_no_init ingress Edwards.Lubec
@pragma pa_no_init ingress Edwards.Ashwood
@pragma pa_no_init ingress Edwards.BigBar
@pragma pa_no_init ingress Edwards.Catlin
@pragma pa_no_init ingress Edwards.Veneta
@pragma pa_no_init ingress Edwards.Armijo
metadata Norridge Edwards;
@pragma ways 4
table Baskin {
   reads {
      Burrel.Shobonier : exact;
      Edwards.Glenpool : exact;
      Edwards.Hotchkiss : exact;
      Edwards.Bellmore : exact;
      Edwards.Lubec : exact;
      Edwards.Ashwood : exact;
      Edwards.BigBar : exact;
      Edwards.Catlin : exact;
      Edwards.Veneta : exact;
      Edwards.Armijo : exact;
   }
   actions {
      Pathfork;
   }
   size : 8192;
}
action BelAir( ElkNeck, KeyWest, CityView, RowanBay, Woolsey, Camelot, Tecumseh, Oconee, Hopeton ) {
   bit_and( Edwards.Glenpool, Burrel.Glenpool, ElkNeck );
   bit_and( Edwards.Hotchkiss, Burrel.Hotchkiss, KeyWest );
   bit_and( Edwards.Bellmore, Burrel.Bellmore, CityView );
   bit_and( Edwards.Lubec, Burrel.Lubec, RowanBay );
   bit_and( Edwards.Ashwood, Burrel.Ashwood, Woolsey );
   bit_and( Edwards.BigBar, Burrel.BigBar, Camelot );
   bit_and( Edwards.Catlin, Burrel.Catlin, Tecumseh );
   bit_and( Edwards.Veneta, Burrel.Veneta, Oconee );
   bit_and( Edwards.Armijo, Burrel.Armijo, Hopeton );
}
table Dunken {
   reads {
      Burrel.Shobonier : exact;
   }
   actions {
      BelAir;
   }
   default_action : BelAir(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Tappan {
   apply( Dunken );
}
control Brazos {
   apply( Baskin );
}
table Brighton {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : ternary;
      Burrel.Hotchkiss : ternary;
      Burrel.Bellmore : ternary;
      Burrel.Lubec : ternary;
      Burrel.Ashwood : ternary;
      Burrel.BigBar : ternary;
      Burrel.Catlin : ternary;
      Burrel.Veneta : ternary;
      Burrel.Armijo : ternary;
   }
   actions {
      Pathfork;
   }
   size : 512;
}
control Coachella {
   apply( Brighton );
}
@pragma ways 4
table Verdemont {
   reads {
      Burrel.Shobonier : exact;
      Edwards.Glenpool : exact;
      Edwards.Hotchkiss : exact;
      Edwards.Bellmore : exact;
      Edwards.Lubec : exact;
      Edwards.Ashwood : exact;
      Edwards.BigBar : exact;
      Edwards.Catlin : exact;
      Edwards.Veneta : exact;
      Edwards.Armijo : exact;
   }
   actions {
      Pathfork;
   }
   size : 4096;
}
action Ankeny( PaloAlto, Amboy, Keltys, Academy, Waialua, Yorklyn, Broadwell, Willard, Linville ) {
   bit_and( Edwards.Glenpool, Burrel.Glenpool, PaloAlto );
   bit_and( Edwards.Hotchkiss, Burrel.Hotchkiss, Amboy );
   bit_and( Edwards.Bellmore, Burrel.Bellmore, Keltys );
   bit_and( Edwards.Lubec, Burrel.Lubec, Academy );
   bit_and( Edwards.Ashwood, Burrel.Ashwood, Waialua );
   bit_and( Edwards.BigBar, Burrel.BigBar, Yorklyn );
   bit_and( Edwards.Catlin, Burrel.Catlin, Broadwell );
   bit_and( Edwards.Veneta, Burrel.Veneta, Willard );
   bit_and( Edwards.Armijo, Burrel.Armijo, Linville );
}
table Bouton {
   reads {
      Burrel.Shobonier : exact;
   }
   actions {
      Ankeny;
   }
   default_action : Ankeny(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Speed {
   apply( Bouton );
}
control Heron {
   apply( Verdemont );
}
table Minneiska {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : ternary;
      Burrel.Hotchkiss : ternary;
      Burrel.Bellmore : ternary;
      Burrel.Lubec : ternary;
      Burrel.Ashwood : ternary;
      Burrel.BigBar : ternary;
      Burrel.Catlin : ternary;
      Burrel.Veneta : ternary;
      Burrel.Armijo : ternary;
   }
   actions {
      Pathfork;
   }
   size : 512;
}
control Skyline {
   apply( Minneiska );
}
@pragma ways 4
table Hannah {
   reads {
      Burrel.Shobonier : exact;
      Edwards.Glenpool : exact;
      Edwards.Hotchkiss : exact;
      Edwards.Bellmore : exact;
      Edwards.Lubec : exact;
      Edwards.Ashwood : exact;
      Edwards.BigBar : exact;
      Edwards.Catlin : exact;
      Edwards.Veneta : exact;
      Edwards.Armijo : exact;
   }
   actions {
      Pathfork;
   }
   size : 4096;
}
action Manning( BarNunn, Saxis, Baytown, Bramwell, Varnell, Glyndon, Corum, Wauseon, Ancho ) {
   bit_and( Edwards.Glenpool, Burrel.Glenpool, BarNunn );
   bit_and( Edwards.Hotchkiss, Burrel.Hotchkiss, Saxis );
   bit_and( Edwards.Bellmore, Burrel.Bellmore, Baytown );
   bit_and( Edwards.Lubec, Burrel.Lubec, Bramwell );
   bit_and( Edwards.Ashwood, Burrel.Ashwood, Varnell );
   bit_and( Edwards.BigBar, Burrel.BigBar, Glyndon );
   bit_and( Edwards.Catlin, Burrel.Catlin, Corum );
   bit_and( Edwards.Veneta, Burrel.Veneta, Wauseon );
   bit_and( Edwards.Armijo, Burrel.Armijo, Ancho );
}
table Rockport {
   reads {
      Burrel.Shobonier : exact;
   }
   actions {
      Manning;
   }
   default_action : Manning(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Green {
   apply( Rockport );
}
control Homeland {
   apply( Hannah );
}
table WyeMills {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : ternary;
      Burrel.Hotchkiss : ternary;
      Burrel.Bellmore : ternary;
      Burrel.Lubec : ternary;
      Burrel.Ashwood : ternary;
      Burrel.BigBar : ternary;
      Burrel.Catlin : ternary;
      Burrel.Veneta : ternary;
      Burrel.Armijo : ternary;
   }
   actions {
      Pathfork;
   }
   size : 512;
}
control Nickerson {
   apply( WyeMills );
}
@pragma ways 4
table Brentford {
   reads {
      Burrel.Shobonier : exact;
      Edwards.Glenpool : exact;
      Edwards.Hotchkiss : exact;
      Edwards.Bellmore : exact;
      Edwards.Lubec : exact;
      Edwards.Ashwood : exact;
      Edwards.BigBar : exact;
      Edwards.Catlin : exact;
      Edwards.Veneta : exact;
      Edwards.Armijo : exact;
   }
   actions {
      Pathfork;
   }
   size : 8192;
}
action Emida( Hyrum, Fairhaven, Mescalero, LoonLake, Dante, Lakota, Vernal, Powers, Camargo ) {
   bit_and( Edwards.Glenpool, Burrel.Glenpool, Hyrum );
   bit_and( Edwards.Hotchkiss, Burrel.Hotchkiss, Fairhaven );
   bit_and( Edwards.Bellmore, Burrel.Bellmore, Mescalero );
   bit_and( Edwards.Lubec, Burrel.Lubec, LoonLake );
   bit_and( Edwards.Ashwood, Burrel.Ashwood, Dante );
   bit_and( Edwards.BigBar, Burrel.BigBar, Lakota );
   bit_and( Edwards.Catlin, Burrel.Catlin, Vernal );
   bit_and( Edwards.Veneta, Burrel.Veneta, Powers );
   bit_and( Edwards.Armijo, Burrel.Armijo, Camargo );
}
table Rossburg {
   reads {
      Burrel.Shobonier : exact;
   }
   actions {
      Emida;
   }
   default_action : Emida(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Simnasho {
   apply( Rossburg );
}
control Woodridge {
   apply( Brentford );
}
table Bixby {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : ternary;
      Burrel.Hotchkiss : ternary;
      Burrel.Bellmore : ternary;
      Burrel.Lubec : ternary;
      Burrel.Ashwood : ternary;
      Burrel.BigBar : ternary;
      Burrel.Catlin : ternary;
      Burrel.Veneta : ternary;
      Burrel.Armijo : ternary;
   }
   actions {
      Pathfork;
   }
   size : 512;
}
control Gakona {
   apply( Bixby );
}
@pragma ways 4
table DeRidder {
   reads {
      Burrel.Shobonier : exact;
      Edwards.Glenpool : exact;
      Edwards.Hotchkiss : exact;
      Edwards.Bellmore : exact;
      Edwards.Lubec : exact;
      Edwards.Ashwood : exact;
      Edwards.BigBar : exact;
      Edwards.Catlin : exact;
      Edwards.Veneta : exact;
      Edwards.Armijo : exact;
   }
   actions {
      Pathfork;
   }
   size : 8192;
}
action Northcote( DelRosa, Levittown, Oakton, Oronogo, McDavid, Biehle, Palouse, Lajitas, Claiborne ) {
   bit_and( Edwards.Glenpool, Burrel.Glenpool, DelRosa );
   bit_and( Edwards.Hotchkiss, Burrel.Hotchkiss, Levittown );
   bit_and( Edwards.Bellmore, Burrel.Bellmore, Oakton );
   bit_and( Edwards.Lubec, Burrel.Lubec, Oronogo );
   bit_and( Edwards.Ashwood, Burrel.Ashwood, McDavid );
   bit_and( Edwards.BigBar, Burrel.BigBar, Biehle );
   bit_and( Edwards.Catlin, Burrel.Catlin, Palouse );
   bit_and( Edwards.Veneta, Burrel.Veneta, Lajitas );
   bit_and( Edwards.Armijo, Burrel.Armijo, Claiborne );
}
table Burdette {
   reads {
      Burrel.Shobonier : exact;
   }
   actions {
      Northcote;
   }
   default_action : Northcote(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Ocoee {
   apply( Burdette );
}
control Accord {
   apply( DeRidder );
}
table Oskawalik {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : ternary;
      Burrel.Hotchkiss : ternary;
      Burrel.Bellmore : ternary;
      Burrel.Lubec : ternary;
      Burrel.Ashwood : ternary;
      Burrel.BigBar : ternary;
      Burrel.Catlin : ternary;
      Burrel.Veneta : ternary;
      Burrel.Armijo : ternary;
   }
   actions {
      Pathfork;
   }
   size : 512;
}
control Montross {
   apply( Oskawalik );
}
@pragma ways 4
table Menomonie {
   reads {
      Burrel.Shobonier : exact;
      Edwards.Glenpool : exact;
      Edwards.Hotchkiss : exact;
      Edwards.Bellmore : exact;
      Edwards.Lubec : exact;
      Edwards.Ashwood : exact;
      Edwards.BigBar : exact;
      Edwards.Catlin : exact;
      Edwards.Veneta : exact;
      Edwards.Armijo : exact;
   }
   actions {
      Pathfork;
   }
   size : 4096;
}
action Magoun( Shellman, Munger, Matador, Tusayan, Tahlequah, Ohiowa, Roodhouse, Bendavis, Komatke ) {
   bit_and( Edwards.Glenpool, Burrel.Glenpool, Shellman );
   bit_and( Edwards.Hotchkiss, Burrel.Hotchkiss, Munger );
   bit_and( Edwards.Bellmore, Burrel.Bellmore, Matador );
   bit_and( Edwards.Lubec, Burrel.Lubec, Tusayan );
   bit_and( Edwards.Ashwood, Burrel.Ashwood, Tahlequah );
   bit_and( Edwards.BigBar, Burrel.BigBar, Ohiowa );
   bit_and( Edwards.Catlin, Burrel.Catlin, Roodhouse );
   bit_and( Edwards.Veneta, Burrel.Veneta, Bendavis );
   bit_and( Edwards.Armijo, Burrel.Armijo, Komatke );
}
table Aynor {
   reads {
      Burrel.Shobonier : exact;
   }
   actions {
      Magoun;
   }
   default_action : Magoun(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Alamota {
   apply( Aynor );
}
control Arvonia {
   apply( Menomonie );
}
table Cortland {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : ternary;
      Burrel.Hotchkiss : ternary;
      Burrel.Bellmore : ternary;
      Burrel.Lubec : ternary;
      Burrel.Ashwood : ternary;
      Burrel.BigBar : ternary;
      Burrel.Catlin : ternary;
      Burrel.Veneta : ternary;
      Burrel.Armijo : ternary;
   }
   actions {
      Pathfork;
   }
   size : 512;
}
control Faulkner {
   apply( Cortland );
}
@pragma ways 4
table Caldwell {
   reads {
      Burrel.Shobonier : exact;
      Edwards.Glenpool : exact;
      Edwards.Hotchkiss : exact;
      Edwards.Bellmore : exact;
      Edwards.Lubec : exact;
      Edwards.Ashwood : exact;
      Edwards.BigBar : exact;
      Edwards.Catlin : exact;
      Edwards.Veneta : exact;
      Edwards.Armijo : exact;
   }
   actions {
      Pathfork;
   }
   size : 4096;
}
action Lamison( Ovilla, Cockrum, Floral, Urbanette, Newsome, Donegal, Quinault, Makawao, Micco ) {
   bit_and( Edwards.Glenpool, Burrel.Glenpool, Ovilla );
   bit_and( Edwards.Hotchkiss, Burrel.Hotchkiss, Cockrum );
   bit_and( Edwards.Bellmore, Burrel.Bellmore, Floral );
   bit_and( Edwards.Lubec, Burrel.Lubec, Urbanette );
   bit_and( Edwards.Ashwood, Burrel.Ashwood, Newsome );
   bit_and( Edwards.BigBar, Burrel.BigBar, Donegal );
   bit_and( Edwards.Catlin, Burrel.Catlin, Quinault );
   bit_and( Edwards.Veneta, Burrel.Veneta, Makawao );
   bit_and( Edwards.Armijo, Burrel.Armijo, Micco );
}
table Bosler {
   reads {
      Burrel.Shobonier : exact;
   }
   actions {
      Lamison;
   }
   default_action : Lamison(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Killen {
   apply( Bosler );
}
control Selby {
   apply( Caldwell );
}
table Hotevilla {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : ternary;
      Burrel.Hotchkiss : ternary;
      Burrel.Bellmore : ternary;
      Burrel.Lubec : ternary;
      Burrel.Ashwood : ternary;
      Burrel.BigBar : ternary;
      Burrel.Catlin : ternary;
      Burrel.Veneta : ternary;
      Burrel.Armijo : ternary;
   }
   actions {
      Pathfork;
   }
   size : 512;
}
control Protem {
   apply( Hotevilla );
}
   metadata Cordell Timbo;
   action Madison( Suamico ) {
          max( Timbo.Tulsa, Timbo.Tulsa, Suamico );
   }
   action Clovis() { max( Sargent.Tulsa, Timbo.Tulsa, Sargent.Tulsa ); } table Bergton { actions { Clovis; } default_action : Clovis; size : 1; } control Sylvan { apply( Bergton ); }
@pragma ways 4
table Cornish {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : exact;
      Burrel.Hotchkiss : exact;
      Burrel.Bellmore : exact;
      Burrel.Lubec : exact;
      Burrel.Ashwood : exact;
      Burrel.BigBar : exact;
      Burrel.Catlin : exact;
      Burrel.Veneta : exact;
      Burrel.Armijo : exact;
   }
   actions {
      Madison;
   }
   size : 4096;
}
control Ririe {
   apply( Cornish );
}
table Eaton {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : ternary;
      Burrel.Hotchkiss : ternary;
      Burrel.Bellmore : ternary;
      Burrel.Lubec : ternary;
      Burrel.Ashwood : ternary;
      Burrel.BigBar : ternary;
      Burrel.Catlin : ternary;
      Burrel.Veneta : ternary;
      Burrel.Armijo : ternary;
   }
   actions {
      Madison;
   }
   size : 4096;
}
control TonkaBay {
   apply( Eaton );
}
@pragma pa_no_init ingress Vandling.Glenpool
@pragma pa_no_init ingress Vandling.Hotchkiss
@pragma pa_no_init ingress Vandling.Bellmore
@pragma pa_no_init ingress Vandling.Lubec
@pragma pa_no_init ingress Vandling.Ashwood
@pragma pa_no_init ingress Vandling.BigBar
@pragma pa_no_init ingress Vandling.Catlin
@pragma pa_no_init ingress Vandling.Veneta
@pragma pa_no_init ingress Vandling.Armijo
metadata Norridge Vandling;
@pragma ways 4
table Pinta {
   reads {
      Burrel.Shobonier : exact;
      Vandling.Glenpool : exact;
      Vandling.Hotchkiss : exact;
      Vandling.Bellmore : exact;
      Vandling.Lubec : exact;
      Vandling.Ashwood : exact;
      Vandling.BigBar : exact;
      Vandling.Catlin : exact;
      Vandling.Veneta : exact;
      Vandling.Armijo : exact;
   }
   actions {
      Madison;
   }
   size : 4096;
}
action Phelps( Hospers, Mackeys, Coupland, Langston, Hiwassee, Wyatte, Shade, Atlas, Pearce ) {
   bit_and( Vandling.Glenpool, Burrel.Glenpool, Hospers );
   bit_and( Vandling.Hotchkiss, Burrel.Hotchkiss, Mackeys );
   bit_and( Vandling.Bellmore, Burrel.Bellmore, Coupland );
   bit_and( Vandling.Lubec, Burrel.Lubec, Langston );
   bit_and( Vandling.Ashwood, Burrel.Ashwood, Hiwassee );
   bit_and( Vandling.BigBar, Burrel.BigBar, Wyatte );
   bit_and( Vandling.Catlin, Burrel.Catlin, Shade );
   bit_and( Vandling.Veneta, Burrel.Veneta, Atlas );
   bit_and( Vandling.Armijo, Burrel.Armijo, Pearce );
}
table Savery {
   reads {
      Burrel.Shobonier : exact;
   }
   actions {
      Phelps;
   }
   default_action : Phelps(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control WhiteOwl {
   apply( Savery );
}
control BayPort {
   apply( Pinta );
}
table Lochbuie {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : ternary;
      Burrel.Hotchkiss : ternary;
      Burrel.Bellmore : ternary;
      Burrel.Lubec : ternary;
      Burrel.Ashwood : ternary;
      Burrel.BigBar : ternary;
      Burrel.Catlin : ternary;
      Burrel.Veneta : ternary;
      Burrel.Armijo : ternary;
   }
   actions {
      Madison;
   }
   size : 512;
}
control Cullen {
   apply( Lochbuie );
}
@pragma ways 4
table Alvordton {
   reads {
      Burrel.Shobonier : exact;
      Vandling.Glenpool : exact;
      Vandling.Hotchkiss : exact;
      Vandling.Bellmore : exact;
      Vandling.Lubec : exact;
      Vandling.Ashwood : exact;
      Vandling.BigBar : exact;
      Vandling.Catlin : exact;
      Vandling.Veneta : exact;
      Vandling.Armijo : exact;
   }
   actions {
      Madison;
   }
   size : 4096;
}
action Bayard( Sawmills, Pease, Barron, Kaufman, Baudette, Paulding, FortHunt, Moorman, Marbleton ) {
   bit_and( Vandling.Glenpool, Burrel.Glenpool, Sawmills );
   bit_and( Vandling.Hotchkiss, Burrel.Hotchkiss, Pease );
   bit_and( Vandling.Bellmore, Burrel.Bellmore, Barron );
   bit_and( Vandling.Lubec, Burrel.Lubec, Kaufman );
   bit_and( Vandling.Ashwood, Burrel.Ashwood, Baudette );
   bit_and( Vandling.BigBar, Burrel.BigBar, Paulding );
   bit_and( Vandling.Catlin, Burrel.Catlin, FortHunt );
   bit_and( Vandling.Veneta, Burrel.Veneta, Moorman );
   bit_and( Vandling.Armijo, Burrel.Armijo, Marbleton );
}
table Keener {
   reads {
      Burrel.Shobonier : exact;
   }
   actions {
      Bayard;
   }
   default_action : Bayard(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Oregon {
   apply( Keener );
}
control Shirley {
   apply( Alvordton );
}
table Ardara {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : ternary;
      Burrel.Hotchkiss : ternary;
      Burrel.Bellmore : ternary;
      Burrel.Lubec : ternary;
      Burrel.Ashwood : ternary;
      Burrel.BigBar : ternary;
      Burrel.Catlin : ternary;
      Burrel.Veneta : ternary;
      Burrel.Armijo : ternary;
   }
   actions {
      Madison;
   }
   size : 512;
}
control Chloride {
   apply( Ardara );
}
@pragma ways 4
table WestBay {
   reads {
      Burrel.Shobonier : exact;
      Vandling.Glenpool : exact;
      Vandling.Hotchkiss : exact;
      Vandling.Bellmore : exact;
      Vandling.Lubec : exact;
      Vandling.Ashwood : exact;
      Vandling.BigBar : exact;
      Vandling.Catlin : exact;
      Vandling.Veneta : exact;
      Vandling.Armijo : exact;
   }
   actions {
      Madison;
   }
   size : 4096;
}
action Umkumiut( Sunman, Tingley, Lantana, Angeles, RichHill, Slick, Bruce, Overlea, Goodwater ) {
   bit_and( Vandling.Glenpool, Burrel.Glenpool, Sunman );
   bit_and( Vandling.Hotchkiss, Burrel.Hotchkiss, Tingley );
   bit_and( Vandling.Bellmore, Burrel.Bellmore, Lantana );
   bit_and( Vandling.Lubec, Burrel.Lubec, Angeles );
   bit_and( Vandling.Ashwood, Burrel.Ashwood, RichHill );
   bit_and( Vandling.BigBar, Burrel.BigBar, Slick );
   bit_and( Vandling.Catlin, Burrel.Catlin, Bruce );
   bit_and( Vandling.Veneta, Burrel.Veneta, Overlea );
   bit_and( Vandling.Armijo, Burrel.Armijo, Goodwater );
}
table Fragaria {
   reads {
      Burrel.Shobonier : exact;
   }
   actions {
      Umkumiut;
   }
   default_action : Umkumiut(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Norcatur {
   apply( Fragaria );
}
control Barclay {
   apply( WestBay );
}
table Puryear {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : ternary;
      Burrel.Hotchkiss : ternary;
      Burrel.Bellmore : ternary;
      Burrel.Lubec : ternary;
      Burrel.Ashwood : ternary;
      Burrel.BigBar : ternary;
      Burrel.Catlin : ternary;
      Burrel.Veneta : ternary;
      Burrel.Armijo : ternary;
   }
   actions {
      Madison;
   }
   size : 512;
}
control McLaurin {
   apply( Puryear );
}
@pragma ways 4
table RedLake {
   reads {
      Burrel.Shobonier : exact;
      Vandling.Glenpool : exact;
      Vandling.Hotchkiss : exact;
      Vandling.Bellmore : exact;
      Vandling.Lubec : exact;
      Vandling.Ashwood : exact;
      Vandling.BigBar : exact;
      Vandling.Catlin : exact;
      Vandling.Veneta : exact;
      Vandling.Armijo : exact;
   }
   actions {
      Madison;
   }
   size : 4096;
}
action Unity( Wymore, Kotzebue, Marlton, Halaula, Hobson, Eolia, Aldan, Fosters, Copley ) {
   bit_and( Vandling.Glenpool, Burrel.Glenpool, Wymore );
   bit_and( Vandling.Hotchkiss, Burrel.Hotchkiss, Kotzebue );
   bit_and( Vandling.Bellmore, Burrel.Bellmore, Marlton );
   bit_and( Vandling.Lubec, Burrel.Lubec, Halaula );
   bit_and( Vandling.Ashwood, Burrel.Ashwood, Hobson );
   bit_and( Vandling.BigBar, Burrel.BigBar, Eolia );
   bit_and( Vandling.Catlin, Burrel.Catlin, Aldan );
   bit_and( Vandling.Veneta, Burrel.Veneta, Fosters );
   bit_and( Vandling.Armijo, Burrel.Armijo, Copley );
}
table Sylva {
   reads {
      Burrel.Shobonier : exact;
   }
   actions {
      Unity;
   }
   default_action : Unity(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Clearco {
   apply( Sylva );
}
control Crowheart {
   apply( RedLake );
}
table Vallecito {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : ternary;
      Burrel.Hotchkiss : ternary;
      Burrel.Bellmore : ternary;
      Burrel.Lubec : ternary;
      Burrel.Ashwood : ternary;
      Burrel.BigBar : ternary;
      Burrel.Catlin : ternary;
      Burrel.Veneta : ternary;
      Burrel.Armijo : ternary;
   }
   actions {
      Madison;
   }
   size : 512;
}
control Hampton {
   apply( Vallecito );
}
@pragma ways 4
table Fitler {
   reads {
      Burrel.Shobonier : exact;
      Vandling.Glenpool : exact;
      Vandling.Hotchkiss : exact;
      Vandling.Bellmore : exact;
      Vandling.Lubec : exact;
      Vandling.Ashwood : exact;
      Vandling.BigBar : exact;
      Vandling.Catlin : exact;
      Vandling.Veneta : exact;
      Vandling.Armijo : exact;
   }
   actions {
      Madison;
   }
   size : 4096;
}
action Bryan( Bagwell, Ossipee, MoonRun, Boyes, Falmouth, Gurley, Minburn, Petrey, Honalo ) {
   bit_and( Vandling.Glenpool, Burrel.Glenpool, Bagwell );
   bit_and( Vandling.Hotchkiss, Burrel.Hotchkiss, Ossipee );
   bit_and( Vandling.Bellmore, Burrel.Bellmore, MoonRun );
   bit_and( Vandling.Lubec, Burrel.Lubec, Boyes );
   bit_and( Vandling.Ashwood, Burrel.Ashwood, Falmouth );
   bit_and( Vandling.BigBar, Burrel.BigBar, Gurley );
   bit_and( Vandling.Catlin, Burrel.Catlin, Minburn );
   bit_and( Vandling.Veneta, Burrel.Veneta, Petrey );
   bit_and( Vandling.Armijo, Burrel.Armijo, Honalo );
}
table Jamesport {
   reads {
      Burrel.Shobonier : exact;
   }
   actions {
      Bryan;
   }
   default_action : Bryan(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Arnold {
   apply( Jamesport );
}
control Irvine {
   apply( Fitler );
}
table Lakin {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : ternary;
      Burrel.Hotchkiss : ternary;
      Burrel.Bellmore : ternary;
      Burrel.Lubec : ternary;
      Burrel.Ashwood : ternary;
      Burrel.BigBar : ternary;
      Burrel.Catlin : ternary;
      Burrel.Veneta : ternary;
      Burrel.Armijo : ternary;
   }
   actions {
      Madison;
   }
   size : 512;
}
control Molson {
   apply( Lakin );
}
@pragma ways 4
table Wailuku {
   reads {
      Burrel.Shobonier : exact;
      Vandling.Glenpool : exact;
      Vandling.Hotchkiss : exact;
      Vandling.Bellmore : exact;
      Vandling.Lubec : exact;
      Vandling.Ashwood : exact;
      Vandling.BigBar : exact;
      Vandling.Catlin : exact;
      Vandling.Veneta : exact;
      Vandling.Armijo : exact;
   }
   actions {
      Madison;
   }
   size : 4096;
}
action Buckfield( Carmel, WindLake, Kenyon, Destin, Ruston, Mondovi, Rotterdam, DeSmet, Minneota ) {
   bit_and( Vandling.Glenpool, Burrel.Glenpool, Carmel );
   bit_and( Vandling.Hotchkiss, Burrel.Hotchkiss, WindLake );
   bit_and( Vandling.Bellmore, Burrel.Bellmore, Kenyon );
   bit_and( Vandling.Lubec, Burrel.Lubec, Destin );
   bit_and( Vandling.Ashwood, Burrel.Ashwood, Ruston );
   bit_and( Vandling.BigBar, Burrel.BigBar, Mondovi );
   bit_and( Vandling.Catlin, Burrel.Catlin, Rotterdam );
   bit_and( Vandling.Veneta, Burrel.Veneta, DeSmet );
   bit_and( Vandling.Armijo, Burrel.Armijo, Minneota );
}
table Diomede {
   reads {
      Burrel.Shobonier : exact;
   }
   actions {
      Buckfield;
   }
   default_action : Buckfield(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Wenatchee {
   apply( Diomede );
}
control Gordon {
   apply( Wailuku );
}
table DuQuoin {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : ternary;
      Burrel.Hotchkiss : ternary;
      Burrel.Bellmore : ternary;
      Burrel.Lubec : ternary;
      Burrel.Ashwood : ternary;
      Burrel.BigBar : ternary;
      Burrel.Catlin : ternary;
      Burrel.Veneta : ternary;
      Burrel.Armijo : ternary;
   }
   actions {
      Madison;
   }
   size : 512;
}
control Summit {
   apply( DuQuoin );
}
@pragma ways 4
table Sequim {
   reads {
      Burrel.Shobonier : exact;
      Vandling.Glenpool : exact;
      Vandling.Hotchkiss : exact;
      Vandling.Bellmore : exact;
      Vandling.Lubec : exact;
      Vandling.Ashwood : exact;
      Vandling.BigBar : exact;
      Vandling.Catlin : exact;
      Vandling.Veneta : exact;
      Vandling.Armijo : exact;
   }
   actions {
      Madison;
   }
   size : 4096;
}
action Waterflow( Paullina, Ellisburg, Rendon, Weissert, Cedonia, Grottoes, Gully, Assinippi, Burgdorf ) {
   bit_and( Vandling.Glenpool, Burrel.Glenpool, Paullina );
   bit_and( Vandling.Hotchkiss, Burrel.Hotchkiss, Ellisburg );
   bit_and( Vandling.Bellmore, Burrel.Bellmore, Rendon );
   bit_and( Vandling.Lubec, Burrel.Lubec, Weissert );
   bit_and( Vandling.Ashwood, Burrel.Ashwood, Cedonia );
   bit_and( Vandling.BigBar, Burrel.BigBar, Grottoes );
   bit_and( Vandling.Catlin, Burrel.Catlin, Gully );
   bit_and( Vandling.Veneta, Burrel.Veneta, Assinippi );
   bit_and( Vandling.Armijo, Burrel.Armijo, Burgdorf );
}
table DeLancey {
   reads {
      Burrel.Shobonier : exact;
   }
   actions {
      Waterflow;
   }
   default_action : Waterflow(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Armstrong {
   apply( DeLancey );
}
control Moorcroft {
   apply( Sequim );
}
table Hildale {
   reads {
      Burrel.Shobonier : exact;
      Burrel.Glenpool : ternary;
      Burrel.Hotchkiss : ternary;
      Burrel.Bellmore : ternary;
      Burrel.Lubec : ternary;
      Burrel.Ashwood : ternary;
      Burrel.BigBar : ternary;
      Burrel.Catlin : ternary;
      Burrel.Veneta : ternary;
      Burrel.Armijo : ternary;
   }
   actions {
      Madison;
   }
   size : 512;
}
control Norco {
   apply( Hildale );
}
control ingress {
   Orrum();
   if( Realitos.Glendevey != 0 ) {
      Hatfield();
   }
   Burket();
   if( Realitos.Glendevey != 0 ) {
      Calabasas();
      Henry();
   }
   Fiftysix();
   Carlin();
   Pricedale();
   Pittsburg();
   Tappan();
   if( Realitos.Glendevey != 0 ) {
      Joslin();
   }
   Brazos();
   Speed();
   Heron();
   Green();
   if( Realitos.Glendevey != 0 ) {
      Chatanika();
   }
   Ogunquit();
   Montello();
   Homeland();
   Simnasho();
   if( Realitos.Glendevey != 0 ) {
      CoalCity();
   }
   Woodridge();
   Ocoee();
   TonkaBay();
   Chouteau();
   Petrolia();
   if( Realitos.Glendevey != 0 ) {
      Parshall();
   }
   Donner();
   Lamona();
   Accord();
   Mentmore();
   if( Holliston.Ragley == 0 ) {
      if( valid( Lamar ) ) {
         Cowen();
      } else {
         Jenison();
         Kiwalik();
      }
   }
   if( Lamar.valid == 0 ) {
      Emlenton();
   }
   if( Holliston.Ragley == 0 ) {
      Millican();
   }
   Sylvan();
   if ( Realitos.Glendevey != 0 ) {
      if( Holliston.Ragley == 0 and Newburgh.Lenwood == 1) {
         apply( Peebles );
      } else {
         apply( Winger );
      }
   }
   if( Realitos.Glendevey != 0 ) {
      McKee();
   }
   Canton();
   if( valid( McCaulley[0] ) ) {
      Leona();
   }
   if( Holliston.Ragley == 0 ) {
      Amber();
   }
   Magnolia();
   Anchorage();
}
control egress {
   Abernant();
   Johnstown();
   Elbert();
   if( ( Holliston.Brohard == 0 ) and ( Holliston.Licking != 2 ) ) {
      Shawmut();
   }
   Nankin();
}
