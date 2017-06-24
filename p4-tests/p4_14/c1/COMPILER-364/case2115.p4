// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 114834







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>






@pragma pa_solitary ingress Roxboro.Okarche
@pragma pa_solitary ingress Roxboro.Dietrich
@pragma pa_solitary ingress Roxboro.Cuprum
@pragma pa_solitary egress Skyway.Wyandanch
@pragma pa_solitary ig_intr_md_for_tm.ucast_egress_port
@pragma pa_atomic ingress Ramah.Quinwood
@pragma pa_solitary ingress Ramah.Quinwood
@pragma pa_atomic ingress Ramah.RowanBay
@pragma pa_solitary ingress Ramah.RowanBay



#ifndef Edinburgh
#define Edinburgh

header_type Ankeny {
	fields {
		Pioche : 16;
		Cisne : 16;
		Renville : 8;
		Lucien : 8;
		Lewistown : 8;
		Horsehead : 8;
		Henning : 1;
		Berne : 1;
		Gardiner : 1;
		Osage : 1;
		Lueders : 1;
		Nelson : 3;
	}
}

header_type Rhine {
	fields {
		Rockville : 24;
		Jigger : 24;
		Kennedale : 24;
		Kapalua : 24;
		Lamkin : 16;
		Okarche : 16;
		Dietrich : 16;
		Cuprum : 16;
		Cushing : 16;
		Elmsford : 8;
		Clyde : 8;
		Newhalem : 6;
		Illmo : 1;
		Monmouth : 1;
		Gully : 12;
		Hannah : 2;
		Bridgton : 1;
		Boydston : 1;
		Cleator : 1;
		Cotuit : 1;
		SourLake : 1;
		Crozet : 1;
		Mabana : 1;
		Maddock : 1;
		Billett : 1;
		Pierpont : 1;
		Leicester : 1;
		Santos : 1;
		Brownson : 1;
		Altus : 3;
	}
}

header_type Offerle {
	fields {
		Yreka : 24;
		Talbert : 24;
		Rowden : 24;
		Elbing : 24;
		Remington : 24;
		Bondad : 24;
		Alsea : 16;
		Ekwok : 16;
		Johnstown : 16;
		Wyandanch : 16;
		August : 12;
		Keokee : 3;
		Norma : 3;
		Pearson : 1;
		Hokah : 1;
		Tombstone : 1;
		Krupp : 1;
		Ironside : 1;
		NewRome : 1;
		Bacton : 1;
		Chatom : 1;
		Hartwell : 8;
	}
}


header_type Janney {
	fields {
		Grassy : 8;
		Sherack : 1;
		Iraan : 1;
		Nashua : 1;
		Gratiot : 1;
		Sidon : 1;
		Martelle : 1;
	}
}

header_type CapeFair {
	fields {
		Basehor : 32;
		Manasquan : 32;
		ArchCape : 6;
		Inkom : 16;
	}
}

header_type Maceo {
	fields {
		Mankato : 128;
		Rienzi : 128;
		Kniman : 20;
		Menomonie : 8;
		Hernandez : 11;
		Lizella : 8;
		Hargis : 13;
	}
}

header_type Mogadore {
	fields {
		ElkRidge : 14;
		Nankin : 1;
		BeeCave : 12;
		Hitchland : 1;
		Seaford : 1;
		Braselton : 6;
		Gilliam : 2;
		Dustin : 6;
		Arnett : 3;
	}
}

header_type Skene {
	fields {
		Orting : 1;
		Angeles : 1;
	}
}

header_type Woodrow {
	fields {
		Powelton : 8;
	}
}

header_type PeaRidge {
	fields {
		Achilles : 16;
		Weleetka : 11;
	}
}

header_type Forman {
	fields {
		Cullen : 32;
		Haley : 32;
		Washta : 32;
	}
}

header_type Joshua {
	fields {
		Quinwood : 32;
		RowanBay : 32;
	}
}

header_type Bosworth {
	fields {
		Maryville : 2;
	}
}
#endif



#ifndef Auberry
#define Auberry



header_type BigWells {
	fields {
		Brashear : 24;
		Thistle : 24;
		PineAire : 24;
		Topanga : 24;
		Rocklake : 16;
	}
}



header_type Destin {
	fields {
		Bangor : 3;
		Longford : 1;
		Harney : 12;
		Camilla : 16;
	}
}



header_type Sherando {
	fields {
		Farner : 4;
		Chunchula : 4;
		Masontown : 6;
		Moorpark : 2;
		Elcho : 16;
		Kinard : 16;
		Suwannee : 3;
		Bucklin : 13;
		Amherst : 8;
		DeSart : 8;
		Ashtola : 16;
		TroutRun : 32;
		Burgess : 32;
	}
}

header_type ElmGrove {
	fields {
		Fajardo : 4;
		Haugan : 6;
		Hawthorne : 2;
		Biscay : 20;
		Bluford : 16;
		Rawson : 8;
		Ocilla : 8;
		Aldrich : 128;
		Varnell : 128;
	}
}




header_type Slovan {
	fields {
		Burmah : 8;
		Bellville : 8;
		Ludell : 16;
	}
}

header_type Lenox {
	fields {
		Manakin : 16;
		Dundalk : 16;
		Hooksett : 32;
		Higgston : 32;
		Quinault : 4;
		Baranof : 4;
		Coachella : 8;
		Shingler : 16;
		Crooks : 16;
		Lardo : 16;
	}
}

header_type Jemison {
	fields {
		Temple : 16;
		ElCentro : 16;
		Aurora : 16;
		Kekoskee : 16;
	}
}



header_type Franklin {
	fields {
		Coconut : 16;
		Madera : 16;
		Marbury : 8;
		Shivwits : 8;
		Sagamore : 16;
	}
}

header_type Kinston {
	fields {
		Killen : 48;
		Fordyce : 32;
		Wamego : 48;
		Sweeny : 32;
	}
}



header_type Fredonia {
	fields {
		Lilbert : 1;
		Balmorhea : 1;
		Florin : 1;
		Mishawaka : 1;
		Aredale : 1;
		Korona : 3;
		Coleman : 5;
		PikeView : 3;
		Emlenton : 16;
	}
}

header_type Southdown {
	fields {
		Humacao : 24;
		Rhodell : 8;
	}
}



header_type Struthers {
	fields {
		Fristoe : 8;
		McCammon : 24;
		Gullett : 24;
		Palatine : 8;
	}
}

#endif



#ifndef Dowell
#define Dowell

parser start {
   return Hotchkiss;
}

#define Goree        0x8100
#define Niota        0x0800
#define Virginia        0x86dd
#define Northlake        0x9100
#define Pease        0x8847
#define Chavies         0x0806
#define Fragaria        0x8035
#define Ackley        0x88cc
#define Mossville        0x8809

#define Tarlton              1
#define Harriston              2
#define Boerne              4
#define LaPryor               6
#define Parkway               17
#define Bridger                47

#define Bavaria         0x501
#define Kenova          0x506
#define Susank          0x511
#define Chambers          0x52F


#define Jenners                 4789



#define Camino               0
#define Liberal              1
#define BealCity                2



#define Sallisaw          0
#define Lacona          4095
#define Millett  4096
#define Angwin  8191



#define Calimesa                      0
#define Delmont                  0
#define Westboro                 1

header BigWells Ickesburg;
header BigWells Pillager;
header Destin Kentwood[ 2 ];
header Sherando Tappan;
header Sherando Plains;
header ElmGrove Canovanas;
header ElmGrove Bothwell;
header Lenox Mabel;
header Jemison Lapel;
header Lenox Sutherlin;
header Jemison Heron;
header Struthers LakeFork;
header Franklin Catarina;
header Fredonia RyanPark;

parser Hotchkiss {
   extract( Ickesburg );
   return select( Ickesburg.Rocklake ) {
      Goree : Viroqua;
      Niota : Marquand;
      Virginia : Chitina;
      Chavies  : Fairlee;
      default        : ingress;
   }
}

parser Viroqua {
   extract( Kentwood[0] );


   set_metadata(Gregory.Lueders, 1);
   return select( Kentwood[0].Camilla ) {
      Niota : Marquand;
      Virginia : Chitina;
      Chavies  : Fairlee;
      default : ingress;
   }
}

parser Marquand {
   extract( Tappan );
   set_metadata(Gregory.Renville, Tappan.DeSart);
   set_metadata(Gregory.Lewistown, Tappan.Amherst);
   set_metadata(Gregory.Pioche, Tappan.Elcho);
   set_metadata(Gregory.Gardiner, 0);
   set_metadata(Gregory.Henning, 1);
   return select(Tappan.Bucklin, Tappan.Chunchula, Tappan.DeSart) {
      Susank : Holladay;
      default : ingress;
   }
}

parser Chitina {
   extract( Bothwell );
   set_metadata(Gregory.Renville, Bothwell.Rawson);
   set_metadata(Gregory.Lewistown, Bothwell.Ocilla);
   set_metadata(Gregory.Pioche, Bothwell.Bluford);
   set_metadata(Gregory.Gardiner, 1);
   set_metadata(Gregory.Henning, 0);
   return ingress;
}

parser Fairlee {
   extract( Catarina );
   return ingress;
}

parser Holladay {
   extract(Lapel);
   return select(Lapel.ElCentro) {
      Jenners : Contact;
      default : ingress;
    }
}

parser WestBend {
   set_metadata(Roxboro.Hannah, BealCity);
   return Cantwell;
}

parser Dushore {
   set_metadata(Roxboro.Hannah, BealCity);
   return Lawai;
}

parser Craigmont {
   extract(RyanPark);
   return select(RyanPark.Lilbert, RyanPark.Balmorhea, RyanPark.Florin, RyanPark.Mishawaka, RyanPark.Aredale,
             RyanPark.Korona, RyanPark.Coleman, RyanPark.PikeView, RyanPark.Emlenton) {
      Niota : WestBend;
      Virginia : Dushore;
      default : ingress;
   }
}

parser Contact {
   extract(LakeFork);
   set_metadata(Roxboro.Hannah, Liberal);
   return VanZandt;
}

parser Cantwell {
   extract( Plains );
   set_metadata(Gregory.Lucien, Plains.DeSart);
   set_metadata(Gregory.Horsehead, Plains.Amherst);
   set_metadata(Gregory.Cisne, Plains.Elcho);
   set_metadata(Gregory.Osage, 0);
   set_metadata(Gregory.Berne, 1);
   return ingress;
}

parser Lawai {
   extract( Canovanas );
   set_metadata(Gregory.Lucien, Canovanas.Rawson);
   set_metadata(Gregory.Horsehead, Canovanas.Ocilla);
   set_metadata(Gregory.Cisne, Canovanas.Bluford);
   set_metadata(Gregory.Osage, 1);
   set_metadata(Gregory.Berne, 0);
   return ingress;
}

parser VanZandt {
   extract( Pillager );
   return select( Pillager.Rocklake ) {
      Niota: Cantwell;
      Virginia: Lawai;
      default: ingress;
   }
}
#endif



@pragma pa_no_pack ingress Wenona.Arnett Skyway.Tombstone
@pragma pa_no_pack ingress Wenona.Arnett Roxboro.Altus
@pragma pa_no_pack ingress Wenona.Arnett Gregory.Nelson
@pragma pa_no_pack ingress Wenona.Braselton Skyway.Tombstone
@pragma pa_no_pack ingress Wenona.Braselton Roxboro.Altus
@pragma pa_no_pack ingress Wenona.Braselton Gregory.Nelson

@pragma pa_no_pack ingress Wenona.Seaford Skyway.Ironside
@pragma pa_no_pack ingress Wenona.Seaford Skyway.Krupp
@pragma pa_no_pack ingress Wenona.Seaford Skyway.Hokah
@pragma pa_no_pack ingress Wenona.Seaford Roxboro.Illmo
@pragma pa_no_pack ingress Wenona.Seaford Roxboro.Illmo
@pragma pa_no_pack ingress Wenona.Seaford Gregory.Osage
@pragma pa_no_pack ingress Wenona.Seaford Gregory.Gardiner
@pragma pa_no_pack ingress Wenona.Seaford Merkel.Sidon

@pragma pa_no_pack ingress Wenona.Braselton Roxboro.Brownson
@pragma pa_no_pack ingress Wenona.Braselton Gregory.Lueders

@pragma pa_no_pack ingress Wenona.Gilliam Roxboro.Altus
@pragma pa_no_pack ingress Wenona.Gilliam Gregory.Nelson

@pragma pa_no_pack ingress Wenona.Seaford Roxboro.Altus
@pragma pa_no_pack ingress Wenona.Seaford Gregory.Nelson
@pragma pa_no_pack ingress Wenona.Seaford Roxboro.SourLake

@pragma pa_no_pack ingress Wenona.Seaford Roxboro.Brownson
@pragma pa_no_pack ingress Wenona.Seaford Skyway.Bacton
@pragma pa_no_pack ingress Wenona.Seaford Gregory.Lueders
@pragma pa_no_pack ingress Wenona.Seaford Skyway.NewRome

metadata Rhine Roxboro;
metadata Offerle Skyway;
metadata Mogadore Wenona;
metadata Ankeny Gregory;
metadata CapeFair Chaumont;
metadata Maceo Accomac;
metadata Skene Hyrum;
metadata Janney Merkel;
metadata Woodrow Gerlach;
metadata PeaRidge Skillman;
metadata Joshua Ramah;
metadata Forman Hillcrest;
metadata Bosworth Paisley;













#undef Ridgeview

#undef VanHorn
#undef Shipman
#undef Amsterdam
#undef Wilsey
#undef Moorcroft

#undef Almond
#undef Varna
#undef Ririe

#undef Hackett
#undef Minturn
#undef Glendevey
#undef LaHoma
#undef Suamico
#undef Hopeton
#undef Calabasas
#undef Bellwood
#undef Cornell
#undef Seguin
#undef Twain
#undef Pinecreek
#undef Sawpit
#undef Westwego
#undef Floral
#undef Sugarloaf
#undef Jefferson
#undef Cabery
#undef Fowler
#undef Mabelvale
#undef Pachuta

#undef Raven
#undef Mathias
#undef Lithonia
#undef Geeville
#undef Crowheart
#undef Langhorne
#undef Glyndon
#undef Blossburg
#undef Suntrana
#undef Carroll
#undef Oshoto
#undef Florala
#undef Piedmont
#undef Swain
#undef Ashburn


#undef Shopville

#undef Frontenac
#undef Alamosa
#undef Merit
#undef Tyrone

#undef Juneau







#define Ridgeview 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define VanHorn      65536
#define Shipman      65536
#define Amsterdam 512
#define Wilsey 512
#define Moorcroft      512


#define Almond     1024
#define Varna    1024
#define Ririe     256


#define Hackett 512
#define Minturn 65536
#define Glendevey 65536
#define LaHoma 28672
#define Suamico   16384
#define Hopeton 8192
#define Calabasas         131072
#define Bellwood 65536
#define Cornell 1024
#define Seguin 2048
#define Twain 16384
#define Pinecreek 8192
#define Sawpit 65536

#define Westwego 0x0000000000000000FFFFFFFFFFFFFFFF


#define Floral 0x000fffff
#define Cabery 2

#define Sugarloaf 0xFFFFFFFFFFFFFFFF0000000000000000

#define Jefferson 0x000007FFFFFFFFFF0000000000000000
#define Fowler  6
#define Pachuta        2048
#define Mabelvale       65536


#define Raven 1024
#define Mathias 4096
#define Lithonia 4096
#define Geeville 4096
#define Crowheart 4096
#define Langhorne 1024
#define Glyndon 4096
#define Suntrana 64
#define Carroll 1
#define Oshoto  8
#define Florala 512


#define Piedmont 1
#define Swain 3
#define Ashburn 80


#define Shopville 0



#define Frontenac 2048


#define Alamosa 4096



#define Merit 2048
#define Tyrone 4096




#define Juneau    4096

#endif



#ifndef Tidewater
#define Tidewater

action Millston() {
   no_op();
}

action Airmont() {
   modify_field(Roxboro.Cotuit, 1 );
}

action Armstrong() {
   no_op();
}
#endif

















action Gumlog(Exeter, Paradis, Emsworth, Rossburg, PortVue, Hooks,
                 Chewalla, Stratford, Sheldahl) {
    modify_field(Wenona.ElkRidge, Exeter);
    modify_field(Wenona.Nankin, Paradis);
    modify_field(Wenona.BeeCave, Emsworth);
    modify_field(Wenona.Hitchland, Rossburg);
    modify_field(Wenona.Seaford, PortVue);
    modify_field(Wenona.Braselton, Hooks);
    modify_field(Wenona.Gilliam, Chewalla);
    modify_field(Wenona.Arnett, Stratford);
    modify_field(Wenona.Dustin, Sheldahl);
}

table GunnCity {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Gumlog;
    }
    size : Ridgeview;
}

control Radcliffe {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(GunnCity);
    }
}





action Montalba(Gravette) {
   modify_field( Skyway.Pearson, 1 );
   modify_field( Skyway.Hartwell, Gravette);
   modify_field( Roxboro.Pierpont, 1 );
}

action Iselin() {
   modify_field( Roxboro.Mabana, 1 );
   modify_field( Roxboro.Santos, 1 );
}

action Bairoil() {
   modify_field( Roxboro.Pierpont, 1 );
}

action Topsfield() {
   modify_field( Roxboro.Leicester, 1 );
}

action Summit() {
   modify_field( Roxboro.Santos, 1 );
}

counter Southam {
   type : packets_and_bytes;
   direct : Sledge;
   min_width: 16;
}

table Sledge {
   reads {
      Wenona.Braselton : exact;
      Ickesburg.Brashear : ternary;
      Ickesburg.Thistle : ternary;
   }

   actions {
      Montalba;
      Iselin;
      Bairoil;
      Topsfield;
      Summit;
   }
   size : Amsterdam;
}

action Hillister() {
   modify_field( Roxboro.Maddock, 1 );
}


table Tekonsha {
   reads {
      Ickesburg.PineAire : ternary;
      Ickesburg.Topanga : ternary;
   }

   actions {
      Hillister;
   }
   size : Wilsey;
}


control Pekin {
   apply( Sledge );
   apply( Tekonsha );
}




action Shoshone() {
   modify_field( Chaumont.Basehor, Plains.TroutRun );
   modify_field( Chaumont.Manasquan, Plains.Burgess );
   modify_field( Chaumont.ArchCape, Plains.Masontown );
   modify_field( Accomac.Mankato, Canovanas.Aldrich );
   modify_field( Accomac.Rienzi, Canovanas.Varnell );
   modify_field( Accomac.Kniman, Canovanas.Biscay );


   modify_field( Roxboro.Rockville, Pillager.Brashear );
   modify_field( Roxboro.Jigger, Pillager.Thistle );
   modify_field( Roxboro.Kennedale, Pillager.PineAire );
   modify_field( Roxboro.Kapalua, Pillager.Topanga );
   modify_field( Roxboro.Lamkin, Pillager.Rocklake );
   modify_field( Roxboro.Cushing, Gregory.Cisne );
   modify_field( Roxboro.Elmsford, Gregory.Lucien );
   modify_field( Roxboro.Clyde, Gregory.Horsehead );
   modify_field( Roxboro.Monmouth, Gregory.Berne );
   modify_field( Roxboro.Illmo, Gregory.Osage );
   modify_field( Roxboro.Brownson, 0 );
   modify_field( Wenona.Gilliam, 2 );
   modify_field( Wenona.Arnett, 0 );
   modify_field( Wenona.Dustin, 0 );
}

action SoapLake() {
   modify_field( Roxboro.Hannah, Camino );
   modify_field( Chaumont.Basehor, Tappan.TroutRun );
   modify_field( Chaumont.Manasquan, Tappan.Burgess );
   modify_field( Chaumont.ArchCape, Tappan.Masontown );
   modify_field( Accomac.Mankato, Bothwell.Aldrich );
   modify_field( Accomac.Rienzi, Bothwell.Varnell );
   modify_field( Accomac.Kniman, Bothwell.Biscay );


   modify_field( Roxboro.Rockville, Ickesburg.Brashear );
   modify_field( Roxboro.Jigger, Ickesburg.Thistle );
   modify_field( Roxboro.Kennedale, Ickesburg.PineAire );
   modify_field( Roxboro.Kapalua, Ickesburg.Topanga );
   modify_field( Roxboro.Lamkin, Ickesburg.Rocklake );
   modify_field( Roxboro.Cushing, Gregory.Pioche );
   modify_field( Roxboro.Elmsford, Gregory.Renville );
   modify_field( Roxboro.Clyde, Gregory.Lewistown );
   modify_field( Roxboro.Monmouth, Gregory.Henning );
   modify_field( Roxboro.Illmo, Gregory.Gardiner );
   modify_field( Roxboro.Altus, Gregory.Nelson );
   modify_field( Roxboro.Brownson, Gregory.Lueders );
}

table Beechwood {
   reads {
      Ickesburg.Brashear : exact;
      Ickesburg.Thistle : exact;
      Tappan.Burgess : exact;
      Roxboro.Hannah : exact;
   }

   actions {
      Shoshone;
      SoapLake;
   }

   default_action : SoapLake();
   size : Raven;
}


action Bells() {
   modify_field( Roxboro.Okarche, Wenona.BeeCave );
   modify_field( Roxboro.Dietrich, Wenona.ElkRidge);
}

action Rudolph( Rardin ) {
   modify_field( Roxboro.Okarche, Rardin );
   modify_field( Roxboro.Dietrich, Wenona.ElkRidge);
}

action Dagsboro() {
   modify_field( Roxboro.Okarche, Kentwood[0].Harney );
   modify_field( Roxboro.Dietrich, Wenona.ElkRidge);
}

table Telma {
   reads {
      Wenona.ElkRidge : ternary;
      Kentwood[0] : valid;
      Kentwood[0].Harney : ternary;
   }

   actions {
      Bells;
      Rudolph;
      Dagsboro;
   }
   size : Geeville;
}

action Eucha( Victoria ) {
   modify_field( Roxboro.Dietrich, Victoria );
}

action Lafayette() {

   modify_field( Roxboro.Cleator, 1 );
   modify_field( Gerlach.Powelton,
                 Westboro );
}

table PawPaw {
   reads {
      Tappan.TroutRun : exact;
   }

   actions {
      Eucha;
      Lafayette;
   }
   default_action : Lafayette;
   size : Lithonia;
}

action Mendon( Caliente, Hoagland, Weehawken, Bonsall, Sunman,
                        Bleecker, Gunter ) {
   modify_field( Roxboro.Okarche, Caliente );
   modify_field( Roxboro.Cuprum, Caliente );
   modify_field( Roxboro.Crozet, Gunter );
   Drake(Hoagland, Weehawken, Bonsall, Sunman,
                        Bleecker );
}

action Ivins() {
   modify_field( Roxboro.SourLake, 1 );
}

table Ulysses {
   reads {
      LakeFork.Gullett : exact;
   }

   actions {
      Mendon;
      Ivins;
   }
   size : Mathias;
}

action Drake(Birds, Carpenter, Averill, Micco,
                        Leeville ) {
   modify_field( Merkel.Grassy, Birds );
   modify_field( Merkel.Sherack, Carpenter );
   modify_field( Merkel.Nashua, Averill );
   modify_field( Merkel.Iraan, Micco );
   modify_field( Merkel.Gratiot, Leeville );
}

action Wolford(Plateau, Lenoir, McDougal, Bunker,
                        Aspetuck ) {
   modify_field( Roxboro.Cuprum, Wenona.BeeCave );
   modify_field( Roxboro.Crozet, 1 );
   Drake(Plateau, Lenoir, McDougal, Bunker,
                        Aspetuck );
}

action Norfork(Bouse, Maywood, Brumley, Holcut,
                        Maltby, Mulliken ) {
   modify_field( Roxboro.Cuprum, Bouse );
   modify_field( Roxboro.Crozet, 1 );
   Drake(Maywood, Brumley, Holcut, Maltby,
                        Mulliken );
}

action Chugwater(Neoga, Floyd, Kanorado, Roberta,
                        Calamine ) {
   modify_field( Roxboro.Cuprum, Kentwood[0].Harney );
   modify_field( Roxboro.Crozet, 1 );
   Drake(Neoga, Floyd, Kanorado, Roberta,
                        Calamine );
}

table Brave {
   reads {
      Wenona.BeeCave : exact;
   }


   actions {
      Millston;
      Wolford;
   }

   size : Crowheart;
}

@pragma action_default_only Millston
table Pinebluff {
   reads {
      Wenona.ElkRidge : exact;
      Kentwood[0].Harney : exact;
   }

   actions {
      Norfork;
      Millston;
   }

   size : Langhorne;
}

table Ferrum {
   reads {
      Kentwood[0].Harney : exact;
   }


   actions {
      Millston;
      Chugwater;
   }

   size : Glyndon;
}

control Globe {
   apply( Beechwood ) {
         Shoshone {
            apply( PawPaw );
            apply( Ulysses );
         }
         SoapLake {
            if ( Wenona.Hitchland == 1 ) {
               apply( Telma );
            }
            if ( valid( Kentwood[ 0 ] ) ) {

               apply( Pinebluff ) {
                  Millston {

                     apply( Ferrum );
                  }
               }
            } else {

               apply( Brave );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Arnold {
    width  : 1;
    static : Kelliher;
    instance_count : 262144;
}

register Redfield {
    width  : 1;
    static : HydePark;
    instance_count : 262144;
}

blackbox stateful_alu LaConner {
    reg : Arnold;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Hyrum.Orting;
}

blackbox stateful_alu ShowLow {
    reg : Redfield;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Hyrum.Angeles;
}

field_list Hackney {
    Wenona.Braselton;
    Kentwood[0].Harney;
}

field_list_calculation Deering {
    input { Hackney; }
    algorithm: identity;
    output_width: 18;
}

action Garibaldi() {
    LaConner.execute_stateful_alu_from_hash(Deering);
}

action Troutman() {
    ShowLow.execute_stateful_alu_from_hash(Deering);
}

table Kelliher {
    actions {
      Garibaldi;
    }
    default_action : Garibaldi;
    size : 1;
}

table HydePark {
    actions {
      Troutman;
    }
    default_action : Troutman;
    size : 1;
}
#endif

action Royston(Tahlequah) {
    modify_field(Hyrum.Angeles, Tahlequah);
}

@pragma  use_hash_action 0
table Knoke {
    reads {
       Wenona.Braselton : exact;
    }
    actions {
      Royston;
    }
    size : 64;
}

action Clearco() {
   modify_field( Roxboro.Gully, Wenona.BeeCave );
   modify_field( Roxboro.Bridgton, 0 );
}

table Firesteel {
   actions {
      Clearco;
   }
   size : 1;
}

action Endicott() {
   modify_field( Roxboro.Gully, Kentwood[0].Harney );
   modify_field( Roxboro.Bridgton, 1 );
}

table Chubbuck {
   actions {
      Endicott;
   }
   size : 1;
}

control OjoFeliz {
   if ( valid( Kentwood[ 0 ] ) ) {
      apply( Chubbuck );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Wenona.Seaford == 1 ) {
         apply( Kelliher );
         apply( HydePark );
      }
#endif
   } else {
      apply( Firesteel );
      if( Wenona.Seaford == 1 ) {
         apply( Knoke );
      }
   }
}




field_list Petrolia {
   Ickesburg.Brashear;
   Ickesburg.Thistle;
   Ickesburg.PineAire;
   Ickesburg.Topanga;
   Ickesburg.Rocklake;
}

field_list Rosboro {

   Tappan.DeSart;
   Tappan.TroutRun;
   Tappan.Burgess;
}

field_list Honaker {
   Bothwell.Aldrich;
   Bothwell.Varnell;
   Bothwell.Biscay;
   Bothwell.Rawson;
}

field_list Caban {
   Tappan.TroutRun;
   Tappan.Burgess;
   Lapel.Temple;
   Lapel.ElCentro;
}





field_list_calculation Follett {
    input {
        Petrolia;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation LunaPier {
    input {
        Rosboro;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Inola {
    input {
        Honaker;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Newtok {
    input {
        Caban;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Orrum() {
    modify_field_with_hash_based_offset(Hillcrest.Cullen, 0,
                                        Follett, 4294967296);
}

action Colonie() {
    modify_field_with_hash_based_offset(Hillcrest.Haley, 0,
                                        LunaPier, 4294967296);
}

action Panacea() {
    modify_field_with_hash_based_offset(Hillcrest.Haley, 0,
                                        Inola, 4294967296);
}

action Baird() {
    modify_field_with_hash_based_offset(Hillcrest.Washta, 0,
                                        Newtok, 4294967296);
}

table Rockdale {
   actions {
      Orrum;
   }
   size: 1;
}

control Halsey {
   apply(Rockdale);
}

table Alvord {
   actions {
      Colonie;
   }
   size: 1;
}

table Houston {
   actions {
      Panacea;
   }
   size: 1;
}

control Casco {
   if ( valid( Tappan ) ) {
      apply(Alvord);
   } else {
      if ( valid( Bothwell ) ) {
         apply(Houston);
      }
   }
}

table Sublimity {
   actions {
      Baird;
   }
   size: 1;
}

control Gratis {
   if ( valid( Lapel ) ) {
      apply(Sublimity);
   }
}



action Glynn() {
    modify_field(Ramah.Quinwood, Hillcrest.Cullen);
}

action Needham() {
    modify_field(Ramah.Quinwood, Hillcrest.Haley);
}

action Watters() {
    modify_field(Ramah.Quinwood, Hillcrest.Washta);
}

@pragma action_default_only Millston
@pragma immediate 0
table Goessel {
   reads {
      Sutherlin.valid : ternary;
      Heron.valid : ternary;
      Plains.valid : ternary;
      Canovanas.valid : ternary;
      Pillager.valid : ternary;
      Mabel.valid : ternary;
      Lapel.valid : ternary;
      Tappan.valid : ternary;
      Bothwell.valid : ternary;
      Ickesburg.valid : ternary;
   }
   actions {
      Glynn;
      Needham;
      Watters;
      Millston;
   }
   size: Ririe;
}

action PineHill() {
    modify_field(Ramah.RowanBay, Hillcrest.Washta);
}

@pragma immediate 0
table Romney {
   reads {
      Sutherlin.valid : ternary;
      Heron.valid : ternary;
      Mabel.valid : ternary;
      Lapel.valid : ternary;
   }
   actions {
      PineHill;
      Millston;
   }
   size: Fowler;
}

control Kranzburg {
   apply(Romney);
   apply(Goessel);
}



counter Waiehu {
   type : packets_and_bytes;
   direct : Scottdale;
   min_width: 16;
}

@pragma action_default_only Millston
table Scottdale {
   reads {
      Wenona.Braselton : exact;
      Hyrum.Angeles : ternary;
      Hyrum.Orting : ternary;
      Roxboro.SourLake : ternary;
      Roxboro.Maddock : ternary;
      Roxboro.Mabana : ternary;
   }

   actions {
      Airmont;
      Millston;
   }
   size : Moorcroft;
}

action WestPark() {

   modify_field(Roxboro.Boydston, 1 );
   modify_field(Gerlach.Powelton,
                Delmont);
}







table Pierre {
   reads {
      Roxboro.Kennedale : exact;
      Roxboro.Kapalua : exact;
      Roxboro.Okarche : exact;
      Roxboro.Dietrich : exact;
   }

   actions {
      Armstrong;
      WestPark;
   }
   size : Shipman;
   support_timeout : true;
}

action Lenapah() {
   modify_field( Merkel.Sidon, 1 );
}

table Proctor {
   reads {
      Roxboro.Cuprum : ternary;
      Roxboro.Rockville : exact;
      Roxboro.Jigger : exact;
   }
   actions {
      Lenapah;
   }
   size: Hackett;
}

control Rehobeth {
   apply( Scottdale ) {
      Millston {



         if (Wenona.Nankin == 0 and Roxboro.Cleator == 0) {
            apply( Pierre );
         }
         apply(Proctor);
      }
   }
}

field_list Hemet {
    Gerlach.Powelton;
    Roxboro.Kennedale;
    Roxboro.Kapalua;
    Roxboro.Okarche;
    Roxboro.Dietrich;
}

action Marcus() {
   generate_digest(Calimesa, Hemet);
}

table Tatum {
   actions {
      Marcus;
   }
   size : 1;
}

control Mapleview {
   if (Roxboro.Boydston == 1) {
      apply( Tatum );
   }
}



action Napanoch( Caldwell, Jermyn ) {
   modify_field( Accomac.Hargis, Caldwell );
   modify_field( Skillman.Achilles, Jermyn );
}

@pragma action_default_only Millston
table Bluff {
   reads {
      Merkel.Grassy : exact;
      Accomac.Rienzi mask Sugarloaf : lpm;
   }
   actions {
      Napanoch;
      Millston;
   }
   size : Pinecreek;
}

@pragma atcam_partition_index Accomac.Hargis
@pragma atcam_number_partitions Pinecreek
table Kanab {
   reads {
      Accomac.Hargis : exact;
      Accomac.Rienzi mask Jefferson : lpm;
   }

   actions {
      LoonLake;
      Nunnelly;
      Millston;
   }
   default_action : Millston();
   size : Sawpit;
}

action Needles( Marfa, Turkey ) {
   modify_field( Accomac.Hernandez, Marfa );
   modify_field( Skillman.Achilles, Turkey );
}

@pragma action_default_only Millston
table Nordland {


   reads {
      Merkel.Grassy : exact;
      Accomac.Rienzi : lpm;
   }

   actions {
      Needles;
      Millston;
   }

   size : Seguin;
}

@pragma atcam_partition_index Accomac.Hernandez
@pragma atcam_number_partitions Seguin
table Rillton {
   reads {
      Accomac.Hernandez : exact;


      Accomac.Rienzi mask Westwego : lpm;
   }
   actions {
      LoonLake;
      Nunnelly;
      Millston;
   }

   default_action : Millston();
   size : Twain;
}

@pragma action_default_only Millston
@pragma idletime_precision 1
table Sparkill {

   reads {
      Merkel.Grassy : exact;
      Chaumont.Manasquan : lpm;
   }

   actions {
      LoonLake;
      Nunnelly;
      Millston;
   }

   size : Cornell;
   support_timeout : true;
}

action Stuttgart( Leoma, Vergennes ) {
   modify_field( Chaumont.Inkom, Leoma );
   modify_field( Skillman.Achilles, Vergennes );
}

@pragma action_default_only Millston
#ifdef PROFILE_DEFAULT
@pragma stage 2 Hopeton
@pragma stage 3
#endif
table Witherbee {
   reads {
      Merkel.Grassy : exact;
      Chaumont.Manasquan : lpm;
   }

   actions {
      Stuttgart;
      Millston;
   }

   size : Suamico;
}

@pragma ways Cabery
@pragma atcam_partition_index Chaumont.Inkom
@pragma atcam_number_partitions Suamico
table Wanamassa {
   reads {
      Chaumont.Inkom : exact;
      Chaumont.Manasquan mask Floral : lpm;
   }
   actions {
      LoonLake;
      Nunnelly;
      Millston;
   }
   default_action : Millston();
   size : Calabasas;
}

action LoonLake( Hookstown ) {
   modify_field( Skillman.Achilles, Hookstown );
}

@pragma idletime_precision 1
table Milano {
   reads {
      Merkel.Grassy : exact;
      Chaumont.Manasquan : exact;
   }

   actions {
      LoonLake;
      Nunnelly;
      Millston;
   }
   default_action : Millston();
   size : Minturn;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
@pragma stage 2 LaHoma
@pragma stage 3
#endif
table Ekron {
   reads {
      Merkel.Grassy : exact;
      Accomac.Rienzi : exact;
   }

   actions {
      LoonLake;
      Nunnelly;
      Millston;
   }
   default_action : Millston();
   size : Glendevey;
   support_timeout : true;
}

action Shelbiana(Sultana, Overlea, Kingman) {
   modify_field(Skyway.Alsea, Kingman);
   modify_field(Skyway.Yreka, Sultana);
   modify_field(Skyway.Talbert, Overlea);
   modify_field(Skyway.Chatom, 1);
}

table Wapella {
   reads {
      Skillman.Achilles : exact;
   }

   actions {
      Shelbiana;
   }
   size : Bellwood;
}

control Green {
   if ( Roxboro.Cotuit == 0 and Merkel.Sidon == 1 ) {
      if ( ( Merkel.Sherack == 1 ) and ( Roxboro.Monmouth == 1 ) ) {
         apply( Milano ) {
            Millston {
               apply( Witherbee ) {
                  Stuttgart {
                     apply( Wanamassa );
                  }
                  Millston {
                     apply( Sparkill );
                  }
               }
            }
         }
      } else if ( ( Merkel.Nashua == 1 ) and ( Roxboro.Illmo == 1 ) ) {
         apply( Ekron ) {
            Millston {
               apply( Nordland ) {
                  Needles {
                     apply( Rillton );
                  }
                  Millston {

                     apply( Bluff ) {
                        Napanoch {
                           apply( Kanab );
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Millstadt {
   if( Skillman.Achilles != 0 ) {
      apply( Wapella );
   }
}

action Nunnelly( Hansboro ) {
   modify_field( Skillman.Weleetka, Hansboro );
   modify_field( Merkel.Martelle, 1 );
}

field_list Sturgeon {
   Ramah.RowanBay;
}

field_list_calculation Accord {
    input {
        Sturgeon;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Sharon {
   selection_key : Accord;
   selection_mode : resilient;
}

action_profile Gerty {
   actions {
      LoonLake;
   }
   size : Mabelvale;
   dynamic_action_selection : Sharon;
}

table Merced {
   reads {
      Skillman.Weleetka : exact;
   }
   action_profile : Gerty;
   size : Pachuta;
}

control Allen {
   if ( Skillman.Weleetka != 0 ) {
      apply( Merced );
   }
}



field_list Farragut {
   Ramah.Quinwood;
}

field_list_calculation Battles {
    input {
        Farragut;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Gassoway {
    selection_key : Battles;
    selection_mode : resilient;
}

action Joyce(LaPlant) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, LaPlant);
}

action_profile Newburgh {
    actions {
        Joyce;
        Millston;
    }
    size : Varna;
    dynamic_action_selection : Gassoway;
}

table Fowlkes {
   reads {
      Skyway.Johnstown : exact;
   }
   action_profile: Newburgh;
   size : Almond;
}

control Bethesda {
   if ((Skyway.Johnstown & 0x2000) == 0x2000) {
      apply(Fowlkes);
   }
}



meter Brookside {
   type : packets;
   static : Verdery;
   instance_count: Frontenac;
}

action Hanamaulu(Ephesus) {
   execute_meter(Brookside, Ephesus, Paisley.Maryville);
}

table Verdery {
   reads {
      Wenona.Braselton : exact;
      Skyway.Hartwell : exact;
   }
   actions {
      Hanamaulu;
   }
   size : Merit;
}

counter Seabrook {
   type : packets;
   static : Chatawa;
   instance_count : Alamosa;
   min_width: 64;
}

action Tagus(Dutton) {
   modify_field(Roxboro.Cotuit, 1);
   count(Seabrook, Dutton);
}

action Yerington(Flasher) {
   count(Seabrook, Flasher);
}

action Mondovi(Laxon, Elliston) {
   modify_field(ig_intr_md_for_tm.qid, Laxon);
   count(Seabrook, Elliston);
}

action Kelvin(Blackwood, Cartago, Ramapo) {
   modify_field(ig_intr_md_for_tm.qid, Blackwood);
   modify_field(ig_intr_md_for_tm.ingress_cos, Cartago);
   count(Seabrook, Ramapo);
}

action Belmond(Goodrich) {
   modify_field(ig_intr_md_for_tm.copy_to_cpu, 1);
   count(Seabrook, Goodrich);
}

table Chatawa {
   reads {
      Wenona.Braselton : exact;
      Skyway.Hartwell : exact;
      Paisley.Maryville : exact;
   }

   actions {
      Tagus;
      Mondovi;
      Kelvin;
      Yerington;
      Belmond;
   }
size : Tyrone;
}



action Mishicot() {
   modify_field(Skyway.Yreka, Roxboro.Rockville);
   modify_field(Skyway.Talbert, Roxboro.Jigger);
   modify_field(Skyway.Rowden, Roxboro.Kennedale);
   modify_field(Skyway.Elbing, Roxboro.Kapalua);
   modify_field(Skyway.Alsea, Roxboro.Okarche);
}

table Monse {
   actions {
      Mishicot;
   }
   default_action : Mishicot();
   size : 1;
}

control Carlson {
   if (Roxboro.Okarche!=0) {
      apply( Monse );
   }
}

action Kaltag() {
   modify_field(Skyway.Tombstone, 1);
   modify_field(Skyway.Hokah, 1);
   modify_field(Skyway.Wyandanch, Skyway.Alsea);
}

action Gibson() {
}



@pragma ways 1
table Duncombe {
   reads {
      Skyway.Yreka : exact;
      Skyway.Talbert : exact;
   }
   actions {
      Kaltag;
      Gibson;
   }
   default_action : Gibson;
   size : 1;
}

action MudLake() {
   modify_field(Skyway.Krupp, 1);
   modify_field(Skyway.Bacton, 1);
   add(Skyway.Wyandanch, Skyway.Alsea, Millett);
}

table Lowes {
   actions {
      MudLake;
   }
   default_action : MudLake;
   size : 1;
}

action Shawmut() {
   modify_field(Skyway.NewRome, 1);
   modify_field(Skyway.Wyandanch, Skyway.Alsea);
}

table Cascadia {
   actions {
      Shawmut;
   }
   default_action : Shawmut();
   size : 1;
}

action Enderlin(Corona) {
   modify_field(Skyway.Ironside, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Corona);
   modify_field(Skyway.Johnstown, Corona);
}

action Punaluu(Ovett) {
   modify_field(Skyway.Krupp, 1);
   modify_field(Skyway.Wyandanch, Ovett);
}

action Dassel() {
}

table Elmhurst {
   reads {
      Skyway.Yreka : exact;
      Skyway.Talbert : exact;
      Skyway.Alsea : exact;
   }

   actions {
      Enderlin;
      Punaluu;
      Dassel;
   }
   default_action : Dassel();
   size : VanHorn;
}

control Brimley {
   if (Roxboro.Cotuit == 0) {
      apply(Elmhurst) {
         Dassel {
            apply(Duncombe) {
               Gibson {
                  if ((Skyway.Yreka & 0x010000) == 0x010000) {
                     apply(Lowes);
                  } else {
                     apply(Cascadia);
                  }
               }
            }
         }
      }
   }
}

action McFaddin() {
   modify_field(Roxboro.Billett, 1);
   modify_field(Roxboro.Cotuit, 1);
}

table Kilbourne {
   actions {
      McFaddin;
   }
   default_action : McFaddin;
   size : 1;
}

control Folkston {
   if (Roxboro.Cotuit == 0) {
      if ((Skyway.Chatom==0) and (Roxboro.Dietrich==Skyway.Johnstown)) {
         apply(Kilbourne);
      } else {
         apply(Verdery);
         apply(Chatawa);
      }
   }
}



action Garwood( Raritan ) {
   modify_field( Skyway.August, Raritan );
}

action BoyRiver() {
   modify_field( Skyway.August, Skyway.Alsea );
}

table UnionGap {
   reads {
      eg_intr_md.egress_port : exact;
      Skyway.Alsea : exact;
   }

   actions {
      Garwood;
      BoyRiver;
   }
   default_action : BoyRiver;
   size : Juneau;
}

control Mariemont {
   apply( UnionGap );
}



action Dickson( Biloxi, Neshoba ) {
   modify_field( Skyway.Remington, Biloxi );
   modify_field( Skyway.Bondad, Neshoba );
}


table Monida {
   reads {
      Skyway.Keokee : exact;
   }

   actions {
      Dickson;
   }
   size : Oshoto;
}

action Comptche() {
   no_op();
}

action Wauconda() {
   modify_field( Ickesburg.Rocklake, Kentwood[0].Camilla );
   remove_header( Kentwood[0] );
}

table Barclay {
   actions {
      Wauconda;
   }
   default_action : Wauconda;
   size : Carroll;
}

action Davant() {
   no_op();
}

action Ricketts() {
   add_header( Kentwood[ 0 ] );
   modify_field( Kentwood[0].Harney, Skyway.August );
   modify_field( Kentwood[0].Camilla, Ickesburg.Rocklake );
   modify_field( Ickesburg.Rocklake, Goree );
}



table Villanova {
   reads {
      Skyway.August : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Davant;
      Ricketts;
   }
   default_action : Ricketts;
   size : Suntrana;
}

action Slagle() {
   modify_field(Ickesburg.Brashear, Skyway.Yreka);
   modify_field(Ickesburg.Thistle, Skyway.Talbert);
   modify_field(Ickesburg.PineAire, Skyway.Remington);
   modify_field(Ickesburg.Topanga, Skyway.Bondad);
}

action LaHabra() {
   Slagle();
   add_to_field(Tappan.Amherst, -1);
}

action Mahopac() {
   Slagle();
   add_to_field(Bothwell.Ocilla, -1);
}

table Camelot {
   reads {
      Skyway.Norma : exact;
      Skyway.Keokee : exact;
      Skyway.Chatom : exact;
      Tappan.valid : ternary;
      Bothwell.valid : ternary;
   }

   actions {
      LaHabra;
      Mahopac;
   }
   size : Florala;
}

control Spiro {
   apply( Barclay );
}

control Freeville {
   apply( Villanova );
}

control TiffCity {
   apply( Monida );
   apply( Camelot );
}



field_list Slick {
    Gerlach.Powelton;
    Roxboro.Okarche;
    Pillager.PineAire;
    Pillager.Topanga;
    Tappan.TroutRun;
}

action Burmester() {
   generate_digest(Calimesa, Slick);
}

table Hubbell {
   actions {
      Burmester;
   }

   default_action : Burmester;
   size : 1;
}

control Kapowsin {
   if (Roxboro.Cleator == 1) {
      apply(Hubbell);
   }
}



action Dasher() {
   modify_field( Roxboro.Altus, Wenona.Arnett );
}

action Noyes() {
   modify_field( Roxboro.Newhalem, Wenona.Dustin );
}

action Oskawalik() {
   modify_field( Roxboro.Newhalem, Chaumont.ArchCape );
}

action Hagerman() {
   modify_field( Roxboro.Newhalem, Accomac.Lizella );
}

action McKenna( Licking, Koloa ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Licking );
   modify_field( ig_intr_md_for_tm.qid, Koloa );
}

table Melstrand {
   reads {
     Roxboro.Brownson : exact;
   }

   actions {
     Dasher;
   }

   size : Piedmont;
}

table BigPiney {
   reads {
     Roxboro.Monmouth : exact;
     Roxboro.Illmo : exact;
   }

   actions {
     Noyes;
     Oskawalik;
     Hagerman;
   }

   size : Swain;
}

@pragma stage 10
table Noonan {
   reads {
      Wenona.Gilliam : exact;
      Wenona.Arnett : ternary;
      Roxboro.Altus : ternary;
      Roxboro.Newhalem : ternary;
   }

   actions {
      McKenna;
   }

   size : Ashburn;
}

control WindGap {
   apply( Melstrand );
   apply( BigPiney );
}

control Glendale {
   apply( Noonan );
}

control ingress {

   Radcliffe();
   Pekin();
   Globe();
   OjoFeliz();
   Halsey();


   WindGap();
   Rehobeth();

   Casco();
   Gratis();


   Green();
   Kranzburg();
   Allen();

   Carlson();

   Millstadt();





   Brimley();
   Glendale();


   Folkston();
   Bethesda();
   Kapowsin();
   Mapleview();


   if( valid( Kentwood[0] ) ) {
      Spiro();
   }






}

control egress {
   Mariemont();
   TiffCity();
   Freeville();
}

