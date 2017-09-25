// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 175234

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
header_type Norfork {
	fields {
		Arthur : 16;
		Termo : 16;
		Albemarle : 8;
		Masontown : 8;
		NewSite : 8;
		Iraan : 8;
		Bethune : 2;
		Annville : 2;
		Robinson : 2;
		LaMoille : 1;
		Overton : 1;
	}
}
header_type Newburgh {
	fields {
		Palmhurst : 24;
		Waterman : 24;
		Jenera : 24;
		Monahans : 24;
		Coulter : 16;
		Seaforth : 16;
		Capitola : 16;
		Dedham : 16;
		Sunrise : 16;
		Lafayette : 8;
		Parmerton : 8;
		Talmo : 2;
		Waldport : 1;
		Baxter : 1;
		Boyce : 12;
		Annetta : 2;
		Crane : 1;
		Merino : 1;
		Valeene : 1;
		Bowen : 1;
		Nunnelly : 1;
		Seagrove : 1;
		Sanford : 1;
		Titonka : 1;
		Broadmoor : 1;
		Topawa : 1;
		Finlayson : 1;
		Penzance : 1;
		Garibaldi : 1;
		LeeCity : 1;
		Amherst : 1;
		Northboro : 1;
		Hillside : 16;
		Salamonia : 16;
		Narka : 8;
		Tamora : 1;
		Waumandee : 1;
	}
}
header_type Escatawpa {
	fields {
		Micro : 24;
		Proctor : 24;
		Norseland : 24;
		Bassett : 24;
		Reinbeck : 24;
		Munich : 24;
		Waterfall : 24;
		Yantis : 24;
		Horns : 16;
		China : 16;
		Boise : 16;
		Ironia : 16;
		Paxico : 12;
		Nelson : 1;
		Scherr : 3;
		Saticoy : 1;
		Hebbville : 3;
		Armstrong : 1;
		Sparr : 1;
		Hilburn : 1;
		RockPort : 1;
		Parnell : 1;
		Excello : 8;
		Caliente : 12;
		Conklin : 4;
		Kelsey : 6;
		Nevis : 10;
		OreCity : 9;
		Wymer : 1;
		Elvaston : 1;
		Snohomish : 1;
		ViewPark : 1;
		Beatrice : 1;
	}
}
header_type Spiro {
	fields {
		ElMango : 8;
		Parkville : 4;
		Welcome : 1;
	}
}
header_type Renick {
	fields {
		Monaca : 32;
		Slayden : 32;
		Knierim : 6;
		Callao : 16;
	}
}
header_type Woodburn {
	fields {
		Walnut : 128;
		OldGlory : 128;
		Brodnax : 20;
		Nenana : 8;
		Conner : 11;
		Berlin : 6;
		Schaller : 13;
	}
}
header_type Wyndmere {
	fields {
		Deport : 14;
		Ilwaco : 1;
		Billings : 12;
		Crozet : 1;
		Ludell : 1;
		Flatwoods : 2;
		Stamford : 6;
		Gunter : 3;
	}
}
header_type Wynnewood {
	fields {
		Sublett : 1;
		Dolliver : 1;
	}
}
header_type Grizzly {
	fields {
		Eustis : 8;
	}
}
header_type Miller {
	fields {
		Malinta : 16;
		RedLake : 11;
	}
}
header_type Fillmore {
	fields {
		Oregon : 32;
		Sasakwa : 32;
		Longwood : 32;
	}
}
header_type Aguada {
	fields {
		Pelion : 32;
		Exell : 32;
	}
}
header_type Nankin {
	fields {
		Strevell : 1;
		NewCity : 2;
		Bryan : 1;
		Talbert : 3;
		Burien : 1;
		Lathrop : 6;
		Edler : 5;
	}
}
header_type Tannehill {
	fields {
		Lindsborg : 16;
	}
}
header_type Neshoba {
	fields {
		Jauca : 14;
		Tusayan : 1;
		BeeCave : 1;
	}
}
header_type Benwood {
	fields {
		Engle : 14;
		Satanta : 1;
		Gilliam : 1;
	}
}
header_type Donald {
	fields {
		LaFayette : 16;
		Hitterdal : 16;
		Cuprum : 16;
		WestPark : 16;
		Metzger : 8;
		Charters : 8;
		Akiachak : 8;
		McMurray : 8;
		Elderon : 1;
		Yetter : 6;
	}
}
header_type Whitman {
	fields {
		Chappells : 32;
	}
}
header_type Larwill {
	fields {
		Coryville : 6;
		Sandston : 10;
		Wright : 4;
		Rardin : 12;
		Lapeer : 12;
		DeSmet : 2;
		Elmdale : 2;
		Elbing : 8;
		Creekside : 3;
		Pease : 5;
	}
}
header_type Vacherie {
	fields {
		Cassa : 24;
		WoodDale : 24;
		Kalaloch : 24;
		Radcliffe : 24;
		Wayzata : 16;
	}
}
header_type Riley {
	fields {
		Clearmont : 3;
		Mulvane : 1;
		Flomaton : 12;
		Doyline : 16;
	}
}
header_type Aguila {
	fields {
		Rumson : 4;
		Forkville : 4;
		Nutria : 6;
		Orrville : 2;
		Gresston : 16;
		Lebanon : 16;
		Mabana : 3;
		Lambrook : 13;
		Elsinore : 8;
		Century : 8;
		Domingo : 16;
		WolfTrap : 32;
		Trout : 32;
	}
}
header_type Ririe {
	fields {
		Conover : 4;
		Tularosa : 6;
		Lewis : 2;
		Rodessa : 20;
		Idria : 16;
		Verdery : 8;
		Fentress : 8;
		Yatesboro : 128;
		Fordyce : 128;
	}
}
header_type Ihlen {
	fields {
		Silco : 8;
		Wickett : 8;
		Tulia : 16;
	}
}
header_type Maloy {
	fields {
		GlenRock : 16;
		Clarendon : 16;
	}
}
header_type Ludlam {
	fields {
		Myoma : 32;
		Colburn : 32;
		Nanakuli : 4;
		Mendon : 4;
		Roswell : 8;
		Gullett : 16;
		Craig : 16;
		Gassoway : 16;
	}
}
header_type Haworth {
	fields {
		Idylside : 16;
		Gustine : 16;
	}
}
header_type Huntoon {
	fields {
		FordCity : 16;
		Petrey : 16;
		Bleecker : 8;
		Stanwood : 8;
		Bozar : 16;
	}
}
header_type Ipava {
	fields {
		Macopin : 48;
		Kathleen : 32;
		Perdido : 48;
		Salome : 32;
	}
}
header_type Cement {
	fields {
		Fackler : 1;
		Fletcher : 1;
		Stockton : 1;
		Baranof : 1;
		Branson : 1;
		Florin : 3;
		Stonebank : 5;
		Hanamaulu : 3;
		Baker : 16;
	}
}
header_type Dominguez {
	fields {
		Biehle : 24;
		Curtin : 8;
	}
}
header_type Coalgate {
	fields {
		Menfro : 8;
		Terlingua : 24;
		Norma : 24;
		Gibbstown : 8;
	}
}
header Vacherie Lamar;
header Vacherie Duncombe;
header Riley Despard[ 2 ];
@pragma pa_fragment ingress Halley.Domingo
@pragma pa_fragment egress Halley.Domingo
header Aguila Halley;
@pragma pa_fragment ingress Glenside.Domingo
@pragma pa_fragment egress Glenside.Domingo
header Aguila Glenside;
header Ririe Elkton;
header Ririe Chubbuck;
header Maloy Mulhall;
header Maloy Grandy;
header Ludlam Lovelady;
header Haworth Lemoyne;
header Ludlam Trenary;
header Haworth Nuangola;
header Coalgate Harriet;
header Cement Libby;
header Larwill Miltona;
header Vacherie Hauppauge;
parser start {
   return select(current(96, 16)) {
      0xBF00 : Attica;
      default : Fenwick;
   }
}
parser Masardis {
   extract( Miltona );
   return Fenwick;
}
parser Attica {
   extract( Hauppauge );
   return Masardis;
}
parser Fenwick {
   extract( Lamar );
   return select( Lamar.Wayzata ) {
      0x8100 : Perma;
      0x0800 : Azalia;
      0x86dd : McClure;
      0x0806 : CityView;
      default : ingress;
   }
}
parser Perma {
   extract( Despard[0] );
   set_metadata(Garretson.LeeCity, 1 );
   return select( Despard[0].Doyline ) {
      0x0800 : Azalia;
      0x86dd : McClure;
      0x0806 : CityView;
      default : ingress;
   }
}
field_list PineCity {
    Halley.Rumson;
    Halley.Forkville;
    Halley.Nutria;
    Halley.Orrville;
    Halley.Gresston;
    Halley.Lebanon;
    Halley.Mabana;
    Halley.Lambrook;
    Halley.Elsinore;
    Halley.Century;
    Halley.WolfTrap;
    Halley.Trout;
}
field_list_calculation Ballville {
    input {
        PineCity;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Halley.Domingo {
    verify Ballville;
    update Ballville;
}
parser Azalia {
   extract( Halley );
   return select(Halley.Lambrook, Halley.Forkville, Halley.Century) {
      0x501 : Rossburg;
      0x511 : Magness;
      0x506 : Twichell;
      0 mask 0xFF7000 : ingress;
      default : Harrison;
   }
}
parser Harrison {
   set_metadata(Garretson.Waldport, 1);
   return ingress;
}
parser McClure {
   extract( Chubbuck );
   set_metadata(Harpster.Robinson, 2);
   return select(Chubbuck.Verdery) {
      0x3a : Rossburg;
      17 : Eolia;
      6 : Twichell;
    default : ingress;
   }
}
parser CityView {
   set_metadata(Harpster.Overton, 1);
   return ingress;
}
parser Magness {
   extract(Mulhall);
   extract(Lemoyne);
   return select(Mulhall.Clarendon) {
      4789 : Cochise;
      default : ingress;
    }
}
parser Rossburg {
   set_metadata( Mulhall.GlenRock, current( 0, 16 ) );
   set_metadata( Mulhall.Clarendon, 0 );
   return ingress;
}
parser Eolia {
   extract(Mulhall);
   extract(Lemoyne);
   return ingress;
}
parser Twichell {
   extract(Mulhall);
   extract(Lovelady);
   return ingress;
}
parser Derita {
   set_metadata(Garretson.Annetta, 2);
   return Pacifica;
}
parser Stonefort {
   set_metadata(Garretson.Annetta, 2);
   return Lewiston;
}
parser LasLomas {
   extract(Libby);
   return select(Libby.Fackler, Libby.Fletcher, Libby.Stockton, Libby.Baranof, Libby.Branson,
             Libby.Florin, Libby.Stonebank, Libby.Hanamaulu, Libby.Baker) {
      0x0800 : Derita;
      0x86dd : Stonefort;
      default : ingress;
   }
}
parser Cochise {
   extract(Harriet);
   set_metadata(Garretson.Annetta, 1);
   return Greendale;
}
field_list Dockton {
    Glenside.Rumson;
    Glenside.Forkville;
    Glenside.Nutria;
    Glenside.Orrville;
    Glenside.Gresston;
    Glenside.Lebanon;
    Glenside.Mabana;
    Glenside.Lambrook;
    Glenside.Elsinore;
    Glenside.Century;
    Glenside.WolfTrap;
    Glenside.Trout;
}
field_list_calculation Newtonia {
    input {
        Dockton;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Glenside.Domingo {
    verify Newtonia;
    update Newtonia;
}
parser Pacifica {
   extract( Glenside );
   set_metadata( Shanghai.Monaca, Glenside.WolfTrap );
   set_metadata( Shanghai.Slayden, Glenside.Trout );
   set_metadata( Garretson.Sunrise, Glenside.Gresston );
   set_metadata( Garretson.Lafayette, Glenside.Century );
   set_metadata( Garretson.Parmerton, Glenside.Elsinore );
   set_metadata( Garretson.Talmo, 2);
   return select(Glenside.Lambrook, Glenside.Forkville, Glenside.Century) {
      0x501 : Davisboro;
      0x511 : Kenney;
      0x506 : Spivey;
      0 mask 0xFF7000 : ingress;
      default : Swedeborg;
   }
}
parser Swedeborg {
   set_metadata(Garretson.Baxter, 1);
   return ingress;
}
parser Lewiston {
   extract( Elkton );
   set_metadata( StarLake.Walnut, Elkton.Yatesboro );
   set_metadata( StarLake.OldGlory, Elkton.Fordyce );
   set_metadata( Garretson.Sunrise, Elkton.Idria );
   set_metadata( Garretson.Lafayette, Elkton.Verdery );
   set_metadata( Garretson.Parmerton, Elkton.Fentress );
   set_metadata( Garretson.Talmo, 2);
   return select(Elkton.Verdery) {
      0x3a : Davisboro;
      17 : Kenney;
      6 : Spivey;
      default : ingress;
   }
}
parser Davisboro {
   set_metadata( Garretson.Hillside, current( 0, 16 ) );
   set_metadata( Garretson.Northboro, 1 );
   return ingress;
}
parser Kenney {
   set_metadata( Garretson.Hillside, current( 0, 16 ) );
   set_metadata( Garretson.Salamonia, current( 16, 16 ) );
   set_metadata( Garretson.Northboro, 1 );
   return ingress;
}
parser Spivey {
   set_metadata( Garretson.Hillside, current( 0, 16 ) );
   set_metadata( Garretson.Salamonia, current( 16, 16 ) );
   set_metadata( Garretson.Narka, current( 104, 8 ) );
   set_metadata( Garretson.Northboro, 1 );
   set_metadata( Garretson.Tamora, 1 );
   return ingress;
}
parser Greendale {
   extract( Duncombe );
   set_metadata( Garretson.Palmhurst, Duncombe.Cassa );
   set_metadata( Garretson.Waterman, Duncombe.WoodDale );
   set_metadata( Garretson.Jenera, Duncombe.Kalaloch );
   set_metadata( Garretson.Monahans, Duncombe.Radcliffe );
   set_metadata( Garretson.Coulter, Duncombe.Wayzata );
   return select( Duncombe.Wayzata ) {
      0x0800: Pacifica;
      0x86dd: Lewiston;
      default: ingress;
   }
}
@pragma pa_solitary ingress Garretson.Waldport
@pragma pa_solitary ingress Garretson.Baxter
@pragma pa_no_init ingress Garretson.Palmhurst
@pragma pa_no_init ingress Garretson.Waterman
@pragma pa_no_init ingress Garretson.Jenera
@pragma pa_no_init ingress Garretson.Monahans
metadata Newburgh Garretson;
@pragma pa_no_init ingress Weehawken.Micro
@pragma pa_no_init ingress Weehawken.Proctor
@pragma pa_no_init ingress Weehawken.Norseland
@pragma pa_no_init ingress Weehawken.Bassett
metadata Escatawpa Weehawken;
metadata Wyndmere Fernway;
metadata Norfork Harpster;
metadata Renick Shanghai;
metadata Woodburn StarLake;
metadata Wynnewood Dahlgren;
@pragma pa_container_size ingress Dahlgren.Dolliver 32
metadata Spiro Elbert;
metadata Grizzly Wapinitia;
metadata Miller Stoystown;
metadata Aguada Benonine;
metadata Fillmore Venice;
metadata Nankin Success;
metadata Tannehill Donegal;
@pragma pa_no_init ingress Goudeau.Jauca
metadata Neshoba Goudeau;
@pragma pa_no_init ingress Dundee.Engle
metadata Benwood Dundee;
metadata Donald Yorkville;
metadata Donald Samantha;
action Millstadt() {
   no_op();
}
action Keener() {
   modify_field(Garretson.Bowen, 1 );
   mark_for_drop();
}
action Janney() {
   no_op();
}
action Burgess(TiffCity, Nighthawk, Elcho, Sahuarita, Garwood,
                 Westvaco, Laxon, Edwards) {
    modify_field(Fernway.Deport, TiffCity);
    modify_field(Fernway.Ilwaco, Nighthawk);
    modify_field(Fernway.Billings, Elcho);
    modify_field(Fernway.Crozet, Sahuarita);
    modify_field(Fernway.Ludell, Garwood);
    modify_field(Fernway.Flatwoods, Westvaco);
    modify_field(Fernway.Gunter, Laxon);
    modify_field(Fernway.Stamford, Edwards);
}
table Amalga {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Burgess;
    }
    size : 288;
}
control Conda {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Amalga);
    }
}
action Vergennes(Shoshone, Elimsport) {
   modify_field( Weehawken.Saticoy, 1 );
   modify_field( Weehawken.Excello, Shoshone);
   modify_field( Garretson.Topawa, 1 );
   modify_field( Success.Bryan, Elimsport );
}
action Magma() {
   modify_field( Garretson.Sanford, 1 );
   modify_field( Garretson.Penzance, 1 );
}
action Waubun() {
   modify_field( Garretson.Topawa, 1 );
}
action Townville() {
   modify_field( Garretson.Topawa, 1 );
   modify_field( Garretson.Garibaldi, 1 );
}
action Sutherlin() {
   modify_field( Garretson.Finlayson, 1 );
}
action Fishers() {
   modify_field( Garretson.Penzance, 1 );
}
counter Carnation {
   type : packets_and_bytes;
   direct : Agawam;
   min_width: 16;
}
table Agawam {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Lamar.Cassa : ternary;
      Lamar.WoodDale : ternary;
   }
   actions {
      Vergennes;
      Magma;
      Waubun;
      Sutherlin;
      Fishers;
      Townville;
   }
   size : 1024;
}
action Panola() {
   modify_field( Garretson.Titonka, 1 );
}
table Plush {
   reads {
      Lamar.Kalaloch : ternary;
      Lamar.Radcliffe : ternary;
   }
   actions {
      Panola;
   }
   size : 512;
}
control Sneads {
   apply( Agawam );
   apply( Plush );
}
action Gerster() {
   modify_field( Shanghai.Knierim, Glenside.Nutria );
   modify_field( StarLake.Brodnax, Elkton.Rodessa );
   modify_field( StarLake.Berlin, Elkton.Tularosa );
   modify_field( Garretson.LeeCity, 0 );
   modify_field( Weehawken.Hebbville, 1 );
   modify_field( Fernway.Flatwoods, 1 );
   modify_field( Fernway.Gunter, 0 );
   modify_field( Fernway.Stamford, 0 );
   modify_field( Success.Strevell, 1 );
   modify_field( Success.NewCity, 1 );
   modify_field( Garretson.Waldport, Garretson.Baxter );
}
action Fennimore(Altus) {
   modify_field( Garretson.Annetta, 0 );
   modify_field( Shanghai.Monaca, Halley.WolfTrap );
   modify_field( Shanghai.Slayden, Halley.Trout );
   modify_field( Shanghai.Knierim, Halley.Nutria );
   modify_field( StarLake.Walnut, Chubbuck.Yatesboro );
   modify_field( StarLake.OldGlory, Chubbuck.Fordyce );
   modify_field( StarLake.Brodnax, Chubbuck.Rodessa );
   modify_field( StarLake.Berlin, Chubbuck.Tularosa );
   modify_field( Garretson.Palmhurst, Lamar.Cassa );
   modify_field( Garretson.Waterman, Lamar.WoodDale );
   modify_field( Garretson.Jenera, Lamar.Kalaloch );
   modify_field( Garretson.Monahans, Lamar.Radcliffe );
   modify_field( Garretson.Coulter, Lamar.Wayzata );
   modify_field( Garretson.Sunrise, Harpster.Arthur );
   modify_field( Garretson.Lafayette, Harpster.Albemarle );
   modify_field( Garretson.Parmerton, Harpster.NewSite );
   modify_field( Success.Burien, Despard[0].Mulvane );
   modify_field( Garretson.Hillside, Mulhall.GlenRock );
   modify_field( Garretson.Salamonia, Mulhall.Clarendon );
   modify_field( Garretson.Narka, Lovelady.Roswell );
   modify_field( Garretson.Talmo, Harpster.Robinson);
}
table Trammel {
   reads {
      Lamar.Cassa : exact;
      Lamar.WoodDale : exact;
      Halley.Trout : exact;
      Garretson.Annetta : exact;
   }
   actions {
      Gerster;
   }
  default_action : Millstadt();
   size : 1024;
}
action Oakton() {
   modify_field( Garretson.Palmhurst, Lamar.Cassa );
   modify_field( Garretson.Waterman, Lamar.WoodDale );
   modify_field( Garretson.Jenera, Lamar.Kalaloch );
   modify_field( Garretson.Monahans, Lamar.Radcliffe );
   modify_field( Garretson.Coulter, Lamar.Wayzata );
   modify_field( Garretson.Annetta, 0 );
   modify_field( Success.Burien, Despard[0].Mulvane );
}
action Neche( Chappell ) {
   modify_field( Garretson.Hillside, Mulhall.GlenRock );
   modify_field( Garretson.Salamonia, Mulhall.Clarendon );
   modify_field( Garretson.Narka, Lovelady.Roswell );
   modify_field( Garretson.Tamora, Chappell );
}
action Otranto( Paulette ) {
   Oakton();
   Neche( Paulette );
   modify_field( Shanghai.Monaca, Halley.WolfTrap );
   modify_field( Shanghai.Slayden, Halley.Trout );
   modify_field( Shanghai.Knierim, Halley.Nutria );
   modify_field( Garretson.Lafayette, Halley.Century);
   modify_field( Garretson.Parmerton, Halley.Elsinore );
   modify_field( Garretson.Sunrise, Halley.Gresston);
   modify_field( Garretson.Talmo, 1 );
}
action Nashwauk( Excel ) {
   Oakton();
   Neche( Excel );
   modify_field( StarLake.Walnut, Chubbuck.Yatesboro );
   modify_field( StarLake.OldGlory, Chubbuck.Fordyce );
   modify_field( StarLake.Brodnax, Chubbuck.Rodessa );
   modify_field( StarLake.Berlin, Chubbuck.Tularosa );
   modify_field( Garretson.Parmerton, Chubbuck.Fentress );
   modify_field( Garretson.Sunrise, Chubbuck.Idria );
   modify_field( Garretson.Lafayette, Chubbuck.Verdery );
   modify_field( Garretson.Talmo, 2 );
}
table Sherando {
   reads {
     Harpster.Robinson: ternary;
     Lovelady.valid : exact;
   }
   actions {
      Otranto;
      Nashwauk;
      Oakton;
   }
  size: 4;
}
action Artas() {
   modify_field( Garretson.Seaforth, Fernway.Billings );
   modify_field( Garretson.Capitola, Fernway.Deport);
}
action VanWert( Denning ) {
   modify_field( Garretson.Seaforth, Denning );
   modify_field( Garretson.Capitola, Fernway.Deport);
}
action SantaAna() {
   modify_field( Garretson.Seaforth, Despard[0].Flomaton );
   modify_field( Garretson.Capitola, Fernway.Deport);
}
table Elmore {
   reads {
      Fernway.Deport : ternary;
      Despard[0] : valid;
      Despard[0].Flomaton : ternary;
   }
   actions {
      Artas;
      VanWert;
      SantaAna;
   }
   size : 4096;
}
action Cantwell( Tyrone ) {
   modify_field( Garretson.Capitola, Tyrone );
}
action Kupreanof() {
   modify_field( Garretson.Valeene, 1 );
   modify_field( Wapinitia.Eustis,
                 1 );
}
table LaPlant {
   reads {
      Halley.WolfTrap : exact;
   }
   actions {
      Cantwell;
      Kupreanof;
   }
   default_action : Kupreanof;
   size : 4096;
}
action Rudolph( Westpoint, Isabela, Boquet, Ralph ) {
   modify_field( Garretson.Seaforth, Westpoint );
   modify_field( Garretson.Dedham, Westpoint );
   modify_field( Garretson.Seagrove, Ralph );
   Freeburg(Isabela, Boquet );
}
action Tomato() {
   modify_field( Garretson.Nunnelly, 1 );
}
table LaPryor {
   reads {
      Harriet.Norma : exact;
   }
   actions {
      Rudolph;
      Tomato;
   }
   size : 4096;
}
action Freeburg(Kerrville, Shamokin ) {
   modify_field( Elbert.ElMango, Kerrville );
   modify_field( Elbert.Parkville, Shamokin );
}
action Shuqualak(Trilby, Vestaburg ) {
   Freeburg(Trilby, Vestaburg );
}
action Parthenon(Valentine, Haley, Toluca ) {
   modify_field( Garretson.Dedham, Valentine );
   Freeburg(Haley, Toluca );
}
action McCracken(Renfroe, Wabasha ) {
   modify_field( Garretson.Dedham, Despard[0].Flomaton );
   Freeburg(Renfroe, Wabasha );
}
table Floris {
   reads {
      Fernway.Billings : exact;
   }
   actions {
      Millstadt;
      Shuqualak;
   }
   size : 4096;
}
@pragma action_default_only Millstadt
table Molson {
   reads {
      Fernway.Deport : exact;
      Despard[0].Flomaton : exact;
   }
   actions {
      Parthenon;
      Millstadt;
   }
   size : 1024;
}
table Osakis {
   reads {
      Despard[0].Flomaton : exact;
   }
   actions {
      Millstadt;
      McCracken;
   }
   size : 4096;
}
control Hobart {
   apply( Trammel ) {
         Gerster {
            apply( LaPlant );
            apply( LaPryor );
         }
         Millstadt {
            apply( Sherando );
            if ( not valid(Miltona) and Fernway.Crozet == 1 ) {
               apply( Elmore );
            }
            if ( valid( Despard[ 0 ] ) ) {
               apply( Molson ) {
                  Millstadt {
                     apply( Osakis );
                  }
               }
            } else {
               apply( Floris );
            }
         }
   }
}
register Oxford {
    width : 1;
    static : Earlham;
    instance_count : 294912;
}
register Sagamore {
    width : 1;
    static : Olyphant;
    instance_count : 294912;
}
blackbox stateful_alu Wheaton {
    reg : Oxford;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : Dahlgren.Sublett;
}
blackbox stateful_alu Fittstown {
    reg : Sagamore;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst : Dahlgren.Dolliver;
}
field_list Orting {
    ig_intr_md.ingress_port;
    Despard[0].Flomaton;
}
field_list_calculation Kirwin {
    input { Orting; }
    algorithm: identity;
    output_width: 19;
}
action Houston() {
    Wheaton.execute_stateful_alu_from_hash(Kirwin);
}
action Maben() {
    Fittstown.execute_stateful_alu_from_hash(Kirwin);
}
table Earlham {
    actions {
      Houston;
    }
    default_action : Houston;
    size : 1;
}
table Olyphant {
    actions {
      Maben;
    }
    default_action : Maben;
    size : 1;
}
action Hobucken(Bufalo) {
    modify_field(Dahlgren.Dolliver, Bufalo);
}
@pragma use_hash_action 0
table Bayne {
    reads {
       ig_intr_md.ingress_port mask 0x7f : exact;
    }
    actions {
      Hobucken;
    }
    size : 72;
}
action Moreland() {
   modify_field( Garretson.Boyce, Fernway.Billings );
   modify_field( Garretson.Crane, 0 );
}
table MintHill {
   actions {
      Moreland;
   }
   size : 1;
}
action Whitewood() {
   modify_field( Garretson.Boyce, Despard[0].Flomaton );
   modify_field( Garretson.Crane, 1 );
}
table Clarks {
   actions {
      Whitewood;
   }
   size : 1;
}
control Ranchito {
   if ( valid( Despard[ 0 ] ) ) {
      apply( Clarks );
         apply( Earlham );
         apply( Olyphant );
   } else {
      apply( MintHill );
         apply( Bayne );
   }
}
field_list Blakeman {
   Lamar.Cassa;
   Lamar.WoodDale;
   Lamar.Kalaloch;
   Lamar.Radcliffe;
   Lamar.Wayzata;
}
field_list Helotes {
   Halley.Century;
   Halley.WolfTrap;
   Halley.Trout;
}
field_list Overlea {
   Chubbuck.Yatesboro;
   Chubbuck.Fordyce;
   Chubbuck.Rodessa;
   Chubbuck.Verdery;
}
field_list Sonora {
   Halley.WolfTrap;
   Halley.Trout;
   Mulhall.GlenRock;
   Mulhall.Clarendon;
}
field_list_calculation Oldsmar {
    input {
        Blakeman;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation ElVerano {
    input {
        Helotes;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Tingley {
    input {
        Overlea;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Sylvester {
    input {
        Sonora;
    }
    algorithm : crc32;
    output_width : 32;
}
action Owanka() {
    modify_field_with_hash_based_offset(Venice.Oregon, 0,
                                        Oldsmar, 4294967296);
}
action Rankin() {
    modify_field_with_hash_based_offset(Venice.Sasakwa, 0,
                                        ElVerano, 4294967296);
}
action PortWing() {
    modify_field_with_hash_based_offset(Venice.Sasakwa, 0,
                                        Tingley, 4294967296);
}
action Hilger() {
    modify_field_with_hash_based_offset(Venice.Longwood, 0,
                                        Sylvester, 4294967296);
}
table Requa {
   actions {
      Owanka;
   }
   size: 1;
}
control Baytown {
   apply(Requa);
}
table TiePlant {
   actions {
      Rankin;
   }
   size: 1;
}
table Stratford {
   actions {
      PortWing;
   }
   size: 1;
}
control GlenRose {
   if ( valid( Halley ) ) {
      apply(TiePlant);
   } else {
      if ( valid( Chubbuck ) ) {
         apply(Stratford);
      }
   }
}
table Newfield {
   actions {
      Hilger;
   }
   size: 1;
}
control Crooks {
   if ( valid( Lemoyne ) ) {
      apply(Newfield);
   }
}
action Agency() {
    modify_field(Benonine.Pelion, Venice.Oregon);
}
action Laney() {
    modify_field(Benonine.Pelion, Venice.Sasakwa);
}
action Sieper() {
    modify_field(Benonine.Pelion, Venice.Longwood);
}
@pragma action_default_only Millstadt
@pragma immediate 0
table Canfield {
   reads {
      Grandy.valid : ternary;
      Glenside.valid : ternary;
      Elkton.valid : ternary;
      Duncombe.valid : ternary;
      Mulhall.valid : ternary;
      Halley.valid : ternary;
      Chubbuck.valid : ternary;
      Lamar.valid : ternary;
   }
   actions {
      Agency;
      Laney;
      Sieper;
      Millstadt;
   }
   size: 256;
}
action Raceland() {
    modify_field(Benonine.Exell, Venice.Longwood);
}
@pragma immediate 0
table Ferndale {
   reads {
        Grandy.valid : ternary;
        Mulhall.valid : ternary;
   }
   actions {
      Raceland;
      Millstadt;
   }
   size: 6;
}
control Friday {
   apply(Ferndale);
   apply(Canfield);
}
counter Saragosa {
   type : packets_and_bytes;
   direct : Hooven;
   min_width: 16;
}
table Hooven {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Dahlgren.Dolliver : ternary;
      Dahlgren.Sublett : ternary;
      Garretson.Nunnelly : ternary;
      Garretson.Titonka : ternary;
      Garretson.Sanford : ternary;
   }
   actions {
      Keener;
      Millstadt;
   }
   default_action : Millstadt();
   size : 512;
}
table Joiner {
   reads {
      Garretson.Jenera : exact;
      Garretson.Monahans : exact;
      Garretson.Seaforth : exact;
   }
   actions {
      Keener;
      Millstadt;
   }
   default_action : Millstadt();
   size : 4096;
}
action Between() {
   modify_field(Garretson.Merino, 1 );
   modify_field(Wapinitia.Eustis,
                0);
}
table Ambrose {
   reads {
      Garretson.Jenera : exact;
      Garretson.Monahans : exact;
      Garretson.Seaforth : exact;
      Garretson.Capitola : exact;
   }
   actions {
      Janney;
      Between;
   }
   default_action : Between();
   size : 65536;
   support_timeout : true;
}
action Lubeck( Earlimart, Hiwassee ) {
   modify_field( Garretson.Amherst, Earlimart );
   modify_field( Garretson.Seagrove, Hiwassee );
}
action Amity() {
   modify_field( Garretson.Seagrove, 1 );
}
table Dilia {
   reads {
      Garretson.Seaforth mask 0xfff : exact;
   }
   actions {
      Lubeck;
      Amity;
      Millstadt;
   }
   default_action : Millstadt();
   size : 4096;
}
action Mizpah() {
   modify_field( Elbert.Welcome, 1 );
}
table Lawnside {
   reads {
      Garretson.Dedham : ternary;
      Garretson.Palmhurst : exact;
      Garretson.Waterman : exact;
   }
   actions {
      Mizpah;
   }
   size: 512;
}
control Albany {
   apply( Hooven ) {
      Millstadt {
         apply( Joiner ) {
            Millstadt {
               if (Fernway.Ilwaco == 0 and Garretson.Valeene == 0) {
                  apply( Ambrose );
               }
               apply( Dilia );
               apply(Lawnside);
            }
         }
      }
   }
}
field_list Vallejo {
    Wapinitia.Eustis;
    Garretson.Jenera;
    Garretson.Monahans;
    Garretson.Seaforth;
    Garretson.Capitola;
}
action Caspiana() {
   generate_digest(0, Vallejo);
}
table RichHill {
   actions {
      Caspiana;
   }
   size : 1;
}
control Milano {
   if (Garretson.Merino == 1) {
      apply( RichHill );
   }
}
action Kekoskee( Fairchild, Suwanee ) {
   modify_field( StarLake.Schaller, Fairchild );
   modify_field( Stoystown.Malinta, Suwanee );
}
action Fontana( Eveleth, Edgemont ) {
   modify_field( StarLake.Schaller, Eveleth );
   modify_field( Stoystown.RedLake, Edgemont );
}
@pragma action_default_only Lilbert
table Truro {
   reads {
      Elbert.ElMango : exact;
      StarLake.OldGlory mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Kekoskee;
      Lilbert;
      Fontana;
   }
   size : 8192;
}
@pragma atcam_partition_index StarLake.Schaller
@pragma atcam_number_partitions 8192
table LaConner {
   reads {
      StarLake.Schaller : exact;
      StarLake.OldGlory mask 0x000007FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Marvin;
      Broadus;
      Millstadt;
   }
   default_action : Millstadt();
   size : 65536;
}
action OldTown( Kohrville, Dunkerton ) {
   modify_field( StarLake.Conner, Kohrville );
   modify_field( Stoystown.Malinta, Dunkerton );
}
action Faulkton( Shingler, LaPlata ) {
   modify_field( StarLake.Conner, Shingler );
   modify_field( Stoystown.RedLake, LaPlata );
}
@pragma action_default_only Millstadt
table Valsetz {
   reads {
      Elbert.ElMango : exact;
      StarLake.OldGlory : lpm;
   }
   actions {
      OldTown;
      Faulkton;
      Millstadt;
   }
   size : 2048;
}
@pragma atcam_partition_index StarLake.Conner
@pragma atcam_number_partitions 2048
table Hilgard {
   reads {
      StarLake.Conner : exact;
      StarLake.OldGlory mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Marvin;
      Broadus;
      Millstadt;
   }
   default_action : Millstadt();
   size : 16384;
}
@pragma action_default_only Lilbert
@pragma idletime_precision 1
table Lydia {
   reads {
      Elbert.ElMango : exact;
      Shanghai.Slayden : lpm;
   }
   actions {
      Marvin;
      Broadus;
      Lilbert;
   }
   size : 1024;
   support_timeout : true;
}
action Hemlock( Couchwood, Kingsdale ) {
   modify_field( Shanghai.Callao, Couchwood );
   modify_field( Stoystown.Malinta, Kingsdale );
}
action Skime( Cordell, Zemple ) {
   modify_field( Shanghai.Callao, Cordell );
   modify_field( Stoystown.RedLake, Zemple );
}
@pragma action_default_only Millstadt
table Oronogo {
   reads {
      Elbert.ElMango : exact;
      Shanghai.Slayden : lpm;
   }
   actions {
      Hemlock;
      Skime;
      Millstadt;
   }
   size : 16384;
}
@pragma ways 2
@pragma atcam_partition_index Shanghai.Callao
@pragma atcam_number_partitions 16384
table Nuyaka {
   reads {
      Shanghai.Callao : exact;
      Shanghai.Slayden mask 0x000fffff : lpm;
   }
   actions {
      Marvin;
      Broadus;
      Millstadt;
   }
   default_action : Millstadt();
   size : 131072;
}
action Marvin( Ocilla ) {
   modify_field( Stoystown.Malinta, Ocilla );
}
@pragma idletime_precision 1
table Vigus {
   reads {
      Elbert.ElMango : exact;
      Shanghai.Slayden : exact;
   }
   actions {
      Marvin;
      Broadus;
      Millstadt;
   }
   default_action : Millstadt();
   size : 65536;
   support_timeout : true;
}
@pragma idletime_precision 1
@pragma stage 2 28672
@pragma stage 3
table Compton {
   reads {
      Elbert.ElMango : exact;
      StarLake.OldGlory : exact;
   }
   actions {
      Marvin;
      Broadus;
      Millstadt;
   }
   default_action : Millstadt();
   size : 65536;
   support_timeout : true;
}
action Lithonia(Ashwood, Stratton, Casnovia) {
   modify_field(Weehawken.Horns, Casnovia);
   modify_field(Weehawken.Micro, Ashwood);
   modify_field(Weehawken.Proctor, Stratton);
   modify_field(Weehawken.Wymer, 1);
   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}
action Portis() {
   Keener();
}
action Cliffs(Camino) {
   modify_field(Weehawken.Saticoy, 1);
   modify_field(Weehawken.Excello, Camino);
}
action Lilbert(Gambrill) {
   modify_field( Weehawken.Saticoy, 1 );
   modify_field( Weehawken.Excello, 9 );
}
table Baird {
   reads {
      Stoystown.Malinta : exact;
   }
   actions {
      Lithonia;
      Portis;
      Cliffs;
   }
   size : 65536;
}
action Frederika( Baskin ) {
   modify_field(Weehawken.Saticoy, 1);
   modify_field(Weehawken.Excello, Baskin);
}
table Weathers {
   actions {
      Frederika;
   }
   default_action: Frederika(0);
   size : 1;
}
control Lemont {
   if ( Garretson.Bowen == 0 and Elbert.Welcome == 1 ) {
      if ( ( ( Elbert.Parkville & 1 ) == 1 ) and ( ( Garretson.Talmo & 1 ) == 1 ) ) {
         apply( Vigus ) {
            Millstadt {
               apply(Oronogo);
            }
         }
      } else if ( ( ( Elbert.Parkville & 2 ) == 2 ) and ( ( Garretson.Talmo & 2 ) == 2 ) ) {
         apply( Compton ) {
            Millstadt {
               apply( Valsetz );
            }
         }
      }
   }
}
control Hotchkiss {
   if ( Garretson.Bowen == 0 and Elbert.Welcome == 1 ) {
      if ( ( ( Elbert.Parkville & 1 ) == 1 ) and ( ( Garretson.Talmo & 1) == 1 ) ) {
         if ( Shanghai.Callao != 0 ) {
            apply( Nuyaka );
         } else if ( Stoystown.Malinta == 0 and Stoystown.RedLake == 0 ) {
            apply( Lydia );
         }
      } else if ( ( ( Elbert.Parkville & 2) == 2 ) and ( ( Garretson.Talmo & 2 ) == 2 ) ) {
         if ( StarLake.Conner != 0 ) {
            apply( Hilgard );
         } else if ( Stoystown.Malinta == 0 and Stoystown.RedLake == 0 ) {
            apply( Truro );
            if ( StarLake.Schaller != 0 ) {
               apply( LaConner );
            }
         }
      } else if( Garretson.Seagrove == 1 ) {
         apply( Weathers );
      }
   }
}
control Belen {
   if( Stoystown.Malinta != 0 ) {
      apply( Baird );
   }
}
action Broadus( Kaupo ) {
   modify_field( Stoystown.RedLake, Kaupo );
}
field_list Grampian {
   Benonine.Exell;
}
field_list_calculation Clarkdale {
    input {
        Grampian;
    }
    algorithm : identity;
    output_width : 66;
}
action_selector Camelot {
   selection_key : Clarkdale;
   selection_mode : resilient;
}
action_profile Kaibab {
   actions {
      Marvin;
   }
   size : 65536;
   dynamic_action_selection : Camelot;
}
@pragma selector_max_group_size 256
table Stobo {
   reads {
      Stoystown.RedLake : exact;
   }
   action_profile : Kaibab;
   size : 2048;
}
control Cartago {
   if ( Stoystown.RedLake != 0 ) {
      apply( Stobo );
   }
}
field_list Joshua {
   Benonine.Pelion;
}
field_list_calculation Beltrami {
    input {
        Joshua;
    }
    algorithm : identity;
    output_width : 51;
}
action_selector Paisano {
    selection_key : Beltrami;
    selection_mode : resilient;
}
action Varnell(Dunphy) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Dunphy);
}
action_profile Tanacross {
    actions {
        Varnell;
        Millstadt;
    }
    size : 1024;
    dynamic_action_selection : Paisano;
}
table LaPalma {
   reads {
      Weehawken.Boise : exact;
   }
   action_profile: Tanacross;
   size : 1024;
}
control Kranzburg {
   if ((Weehawken.Boise & 0x2000) == 0x2000) {
      apply(LaPalma);
   }
}
action Wartburg() {
   modify_field(Weehawken.Micro, Garretson.Palmhurst);
   modify_field(Weehawken.Proctor, Garretson.Waterman);
   modify_field(Weehawken.Norseland, Garretson.Jenera);
   modify_field(Weehawken.Bassett, Garretson.Monahans);
   modify_field(Weehawken.Horns, Garretson.Seaforth);
   invalidate( ig_intr_md_for_tm.ucast_egress_port );
}
table Monetta {
   actions {
      Wartburg;
   }
   default_action : Wartburg();
   size : 1;
}
control Ozona {
   apply( Monetta );
}
action Anniston() {
   modify_field(Weehawken.Armstrong, 1);
   modify_field(Weehawken.ViewPark, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Garretson.Seagrove);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Weehawken.Horns);
}
action Rexville() {
}
@pragma ways 1
table Lehigh {
   reads {
      Weehawken.Micro : exact;
      Weehawken.Proctor : exact;
   }
   actions {
      Anniston;
      Rexville;
   }
   default_action : Rexville;
   size : 1;
}
action Maiden() {
   modify_field(Weehawken.Sparr, 1);
   modify_field(Weehawken.Parnell, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Weehawken.Horns, 4096);
}
table Powderly {
   actions {
      Maiden;
   }
   default_action : Maiden;
   size : 1;
}
action Cabot() {
   modify_field(Weehawken.RockPort, 1);
   modify_field(Weehawken.ViewPark, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Weehawken.Horns);
}
table Dabney {
   actions {
      Cabot;
   }
   default_action : Cabot();
   size : 1;
}
action BealCity(Rehobeth) {
   modify_field(Weehawken.Hilburn, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Rehobeth);
   modify_field(Weehawken.Boise, Rehobeth);
}
action Taylors(Luttrell) {
   modify_field(Weehawken.Sparr, 1);
   modify_field(Weehawken.Ironia, Luttrell);
}
action Whigham() {
}
table Timken {
   reads {
      Weehawken.Micro : exact;
      Weehawken.Proctor : exact;
      Weehawken.Horns : exact;
   }
   actions {
      BealCity;
      Taylors;
      Keener;
      Whigham;
   }
   default_action : Whigham();
   size : 65536;
}
control Barnwell {
   if (Garretson.Bowen == 0 and not valid(Miltona) ) {
      apply(Timken) {
         Whigham {
            apply(Lehigh) {
               Rexville {
                  if ((Weehawken.Micro & 0x010000) == 0x010000) {
                     apply(Powderly);
                  } else {
                     apply(Dabney);
                  }
               }
            }
         }
      }
   }
}
action Southam() {
   modify_field(Garretson.Broadmoor, 1);
   Keener();
}
table Karluk {
   actions {
      Southam;
   }
   default_action : Southam;
   size : 1;
}
control Ardara {
   if (Garretson.Bowen == 0) {
      if ((Weehawken.Wymer==0) and (Garretson.Topawa==0) and (Garretson.Finlayson==0) and (Garretson.Capitola==Weehawken.Boise)) {
         apply(Karluk);
      } else {
         Kranzburg();
      }
   }
}
action Gaston( Umpire ) {
   modify_field( Weehawken.Paxico, Umpire );
}
action Burden() {
   modify_field( Weehawken.Paxico, Weehawken.Horns );
}
table Blakeslee {
   reads {
      eg_intr_md.egress_port : exact;
      Weehawken.Horns : exact;
   }
   actions {
      Gaston;
      Burden;
   }
   default_action : Burden;
   size : 4096;
}
control Kinards {
   apply( Blakeslee );
}
action Estero( RiceLake, Carpenter ) {
   modify_field( Weehawken.Reinbeck, RiceLake );
   modify_field( Weehawken.Munich, Carpenter );
}
table Honaker {
   reads {
      Weehawken.Scherr : exact;
   }
   actions {
      Estero;
   }
   size : 8;
}
action Emsworth() {
   modify_field( Weehawken.Elvaston, 1 );
   modify_field( Weehawken.Scherr, 2 );
}
action Jefferson() {
   modify_field( Weehawken.Elvaston, 1 );
   modify_field( Weehawken.Scherr, 1 );
}
table Ackley {
   reads {
      Weehawken.Nelson : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Emsworth;
      Jefferson;
   }
   default_action : Millstadt();
   size : 16;
}
action Margie(Keyes, Morita, Grygla, Berkley) {
   modify_field( Weehawken.Kelsey, Keyes );
   modify_field( Weehawken.Nevis, Morita );
   modify_field( Weehawken.Conklin, Grygla );
   modify_field( Weehawken.Caliente, Berkley );
}
table Waukegan {
   reads {
        Weehawken.OreCity : exact;
   }
   actions {
      Margie;
   }
   size : 256;
}
action Kaolin() {
   no_op();
}
action Kahua() {
   modify_field( Lamar.Wayzata, Despard[0].Doyline );
   remove_header( Despard[0] );
}
table Wallula {
   actions {
      Kahua;
   }
   default_action : Kahua;
   size : 1;
}
action Attalla() {
   no_op();
}
action ElmPoint() {
   add_header( Despard[ 0 ] );
   modify_field( Despard[0].Flomaton, Weehawken.Paxico );
   modify_field( Despard[0].Doyline, Lamar.Wayzata );
   modify_field( Despard[0].Clearmont, Success.Talbert );
   modify_field( Despard[0].Mulvane, Success.Burien );
   modify_field( Lamar.Wayzata, 0x8100 );
}
table Coverdale {
   reads {
      Weehawken.Paxico : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Attalla;
      ElmPoint;
   }
   default_action : ElmPoint;
   size : 128;
}
action Bledsoe() {
   modify_field(Lamar.Cassa, Weehawken.Micro);
   modify_field(Lamar.WoodDale, Weehawken.Proctor);
   modify_field(Lamar.Kalaloch, Weehawken.Reinbeck);
   modify_field(Lamar.Radcliffe, Weehawken.Munich);
}
action LaCenter() {
   Bledsoe();
   add_to_field(Halley.Elsinore, -1);
   modify_field(Halley.Nutria, Success.Lathrop);
}
action Samson() {
   Bledsoe();
   add_to_field(Chubbuck.Fentress, -1);
   modify_field(Chubbuck.Tularosa, Success.Lathrop);
}
action Caulfield() {
   modify_field(Halley.Nutria, Success.Lathrop);
}
action Grabill() {
   modify_field(Chubbuck.Tularosa, Success.Lathrop);
}
action Gibbs() {
   ElmPoint();
}
action Rockaway( Avondale, Kaeleku, Cimarron, Gonzalez ) {
   add_header( Hauppauge );
   modify_field( Hauppauge.Cassa, Avondale );
   modify_field( Hauppauge.WoodDale, Kaeleku );
   modify_field( Hauppauge.Kalaloch, Cimarron );
   modify_field( Hauppauge.Radcliffe, Gonzalez );
   modify_field( Hauppauge.Wayzata, 0xBF00 );
   add_header( Miltona );
   modify_field( Miltona.Coryville, Weehawken.Kelsey );
   modify_field( Miltona.Sandston, Weehawken.Nevis );
   modify_field( Miltona.Wright, Weehawken.Conklin );
   modify_field( Miltona.Rardin, Weehawken.Caliente );
   modify_field( Miltona.Elbing, Weehawken.Excello );
}
action Westboro() {
   remove_header( Harriet );
   remove_header( Lemoyne );
   remove_header( Mulhall );
   copy_header( Lamar, Duncombe );
   remove_header( Duncombe );
   remove_header( Halley );
}
action Charenton() {
   remove_header( Hauppauge );
   remove_header( Miltona );
}
action Aguilar() {
   Westboro();
   modify_field(Glenside.Nutria, Success.Lathrop);
}
action Dandridge() {
   Westboro();
   modify_field(Elkton.Tularosa, Success.Lathrop);
}
table Norcatur {
   reads {
      Weehawken.Hebbville : exact;
      Weehawken.Scherr : exact;
      Weehawken.Wymer : exact;
      Halley.valid : ternary;
      Chubbuck.valid : ternary;
      Glenside.valid : ternary;
      Elkton.valid : ternary;
   }
   actions {
      LaCenter;
      Samson;
      Caulfield;
      Grabill;
      Gibbs;
      Rockaway;
      Charenton;
      Westboro;
      Aguilar;
      Dandridge;
   }
   size : 512;
}
control Davie {
   apply( Wallula );
}
control HighHill {
   apply( Coverdale );
}
control Udall {
   apply( Ackley ) {
      Millstadt {
         apply( Honaker );
      }
   }
   apply( Waukegan );
   apply( Norcatur );
}
field_list Jesup {
    Wapinitia.Eustis;
    Garretson.Seaforth;
    Duncombe.Kalaloch;
    Duncombe.Radcliffe;
    Halley.WolfTrap;
}
action Glynn() {
   generate_digest(0, Jesup);
}
table DeSart {
   actions {
      Glynn;
   }
   default_action : Glynn;
   size : 1;
}
control Mabelvale {
   if (Garretson.Valeene == 1) {
      apply(DeSart);
   }
}
action Browning() {
   modify_field( Success.Talbert, Fernway.Gunter );
}
action Burwell() {
   modify_field( Success.Talbert, Despard[0].Clearmont );
   modify_field( Garretson.Coulter, Despard[0].Doyline );
}
action Harvey() {
   modify_field( Success.Lathrop, Fernway.Stamford );
}
action Cresco() {
   modify_field( Success.Lathrop, Shanghai.Knierim );
}
action Bluford() {
   modify_field( Success.Lathrop, StarLake.Berlin );
}
action Tindall( Easley, Sharon ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Easley );
   modify_field( ig_intr_md_for_tm.qid, Sharon );
}
table Ugashik {
   reads {
     Garretson.LeeCity : exact;
   }
   actions {
     Browning;
     Burwell;
   }
   size : 2;
}
table LaPuente {
   reads {
         Garretson.Talmo : exact;
   }
   actions {
     Harvey;
     Cresco;
     Bluford;
   }
   size : 3;
}
table McCune {
   reads {
      Fernway.Flatwoods : ternary;
      Fernway.Gunter : ternary;
      Success.Talbert : ternary;
      Success.Lathrop : ternary;
      Success.Bryan : ternary;
   }
   actions {
      Tindall;
   }
   size : 81;
}
action Turney( Hodges, Lostwood ) {
   bit_or( Success.NewCity, Success.NewCity, Lostwood );
}
table Dovray {
   actions {
      Turney;
   }
   default_action : Turney(0, 0);
   size : 1;
}
action Glazier( Rocklake ) {
   modify_field( Success.Lathrop, Rocklake );
}
action Hopedale( Choptank ) {
   modify_field( Success.Talbert, Choptank );
}
action Rosario( Hulbert, Amasa ) {
   modify_field( Success.Talbert, Hulbert );
   modify_field( Success.Lathrop, Amasa );
}
table Newborn {
   reads {
      Fernway.Flatwoods : exact;
      Success.Strevell : exact;
      Success.NewCity : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Glazier;
      Hopedale;
      Rosario;
   }
   size : 512;
}
control Farragut {
   apply( Ugashik );
   apply( LaPuente );
}
control Cuney {
   apply( McCune );
}
control Ramapo {
   apply( Dovray );
   apply( Newborn );
}
action Steger( Pembine ) {
   modify_field( Success.Edler, Pembine );
}
action Cadott( Quebrada, Pajaros ) {
   Steger( Quebrada );
   modify_field( ig_intr_md_for_tm.qid, Pajaros );
}
table Burtrum {
   reads {
      Weehawken.Saticoy : ternary;
      ig_intr_md_for_tm.copy_to_cpu : ternary;
      Weehawken.Excello : ternary;
      Garretson.Talmo : ternary;
      Garretson.Coulter : ternary;
      Garretson.Lafayette : ternary;
      Garretson.Parmerton : ternary;
      Weehawken.Wymer : ternary;
      Mulhall.GlenRock : ternary;
      Mulhall.Clarendon : ternary;
   }
   actions {
      Steger;
      Cadott;
   }
   size : 512;
}
meter Woodlake {
   type : packets;
   static : Edinburgh;
   instance_count : 2304;
}
action ShadeGap(Denhoff) {
   execute_meter( Woodlake, Denhoff, ig_intr_md_for_tm.packet_color );
}
table Edinburgh {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Success.Edler : exact;
   }
   actions {
      ShadeGap;
   }
   size : 2304;
}
counter Ingleside {
   type : packets;
   instance_count : 32;
   min_width : 128;
}
action Kendrick() {
   count( Ingleside, Success.Edler );
}
table Arnold {
   actions {
     Kendrick;
   }
   default_action : Kendrick;
   size : 1;
}
control Cammal {
    if ( (
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x1 ) == 0 ) ) and ( Weehawken.Saticoy == 1 ) ) or
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x2 ) == 0 ) ) and ( ig_intr_md_for_tm.copy_to_cpu == 1 ) )
       ) ) {
      apply( Edinburgh );
      apply( Arnold );
   }
}
action Coupland( Francisco ) {
   modify_field( Weehawken.Nelson, 0 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Francisco );
   modify_field( Weehawken.OreCity, ig_intr_md.ingress_port );
}
action Lantana( Squire ) {
   modify_field( Weehawken.Nelson, 1 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Squire );
   modify_field( Weehawken.OreCity, ig_intr_md.ingress_port );
}
action Leland() {
   modify_field( Weehawken.Nelson, 0 );
}
action Tullytown() {
   modify_field( Weehawken.Nelson, 1 );
   modify_field( Weehawken.OreCity, ig_intr_md.ingress_port );
}
@pragma ternary 1
table Quinault {
   reads {
      Weehawken.Saticoy : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      Elbert.Welcome : exact;
      Fernway.Crozet : ternary;
      Weehawken.Excello : ternary;
   }
   actions {
      Coupland;
      Lantana;
      Leland;
      Tullytown;
   }
   size : 512;
}
control DeRidder {
   apply( Quinault );
}
counter Copley {
   type : packets_and_bytes;
   instance_count : 1024;
   min_width : 128;
}
action Hagewood( Roberts ) {
   count( Copley, Roberts );
}
table Neponset {
   reads {
      eg_intr_md.egress_port mask 0x7f: exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }
   actions {
     Hagewood;
   }
   size : 1024;
}
control GunnCity {
   apply( Neponset );
}
action Hollymead()
{
   Keener();
}
action CoosBay()
{
   modify_field(Weehawken.Hebbville, 2);
   bit_or(Weehawken.Boise, 0x2000, Miltona.Rardin);
}
action Virgil( Vernal ) {
   modify_field(Weehawken.Hebbville, 2);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Vernal);
   modify_field(Weehawken.Boise, Vernal);
}
table LeeCreek {
   reads {
      Miltona.Coryville : exact;
      Miltona.Sandston : exact;
      Miltona.Wright : exact;
      Miltona.Rardin : exact;
   }
   actions {
      CoosBay;
      Virgil;
      Hollymead;
   }
   default_action : Hollymead();
   size : 256;
}
control Helton {
   apply( LeeCreek );
}
action Geneva( Courtdale, Inverness, Elsey, Hennessey ) {
   modify_field( Donegal.Lindsborg, Courtdale );
   modify_field( Dundee.Satanta, Elsey );
   modify_field( Dundee.Engle, Inverness );
   modify_field( Dundee.Gilliam, Hennessey );
}
table LaneCity {
   reads {
     Shanghai.Slayden : exact;
     Garretson.Dedham : exact;
   }
   actions {
      Geneva;
   }
  size : 16384;
}
action Hickox(Moapa, Sandstone, Magazine) {
   modify_field( Dundee.Engle, Moapa );
   modify_field( Dundee.Satanta, Sandstone );
   modify_field( Dundee.Gilliam, Magazine );
}
table Hanahan {
   reads {
     Shanghai.Monaca : exact;
     Donegal.Lindsborg : exact;
   }
   actions {
      Hickox;
   }
   size : 16384;
}
action Sugarloaf( Stilson, Arroyo, Notus ) {
   modify_field( Goudeau.Jauca, Stilson );
   modify_field( Goudeau.Tusayan, Arroyo );
   modify_field( Goudeau.BeeCave, Notus );
}
table Vidal {
   reads {
     Weehawken.Micro : exact;
     Weehawken.Proctor : exact;
     Weehawken.Horns : exact;
   }
   actions {
      Sugarloaf;
   }
   size : 16384;
}
action Mabelle() {
   modify_field( Weehawken.ViewPark, 1 );
}
action Glassboro( Harold, Loyalton ) {
   Mabelle();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Dundee.Engle );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Harold, Dundee.Gilliam );
   bit_or( Success.Edler, Success.Edler, Loyalton );
}
action Belgrade( Willamina, Asharoken ) {
   Mabelle();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Goudeau.Jauca );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Willamina, Goudeau.BeeCave );
   bit_or( Success.Edler, Success.Edler, Asharoken );
}
action Gahanna( Stout, Tombstone ) {
   Mabelle();
   add( ig_intr_md_for_tm.mcast_grp_a, Weehawken.Horns,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Stout );
   bit_or( Success.Edler, Success.Edler, Tombstone );
}
action Lasker() {
   modify_field( Weehawken.Beatrice, 1 );
}
table Cheyenne {
   reads {
     Dundee.Satanta : ternary;
     Dundee.Engle : ternary;
     Goudeau.Jauca : ternary;
     Goudeau.Tusayan : ternary;
     Garretson.Lafayette :ternary;
     Garretson.Topawa:ternary;
   }
   actions {
      Glassboro;
      Belgrade;
      Gahanna;
      Lasker;
   }
   size : 32;
}
control Dustin {
   if( Garretson.Bowen == 0 and
       ( Elbert.Parkville & 4 ) == 4 and
       Garretson.Garibaldi == 1 ) {
      apply( LaneCity );
   }
}
control Deering {
   if( Donegal.Lindsborg != 0 ) {
      apply( Hanahan );
   }
}
control Minturn {
   if( Garretson.Bowen == 0 and Garretson.Topawa==1 ) {
      apply( Vidal );
   }
}
action Frankfort(Verdemont) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Benonine.Pelion );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Verdemont );
}
table Draketown {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Frankfort;
    }
    size : 512;
}
control Steele {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Draketown);
   }
}
action Sonoma( Deemer, Coleman ) {
   modify_field( Weehawken.Horns, Deemer );
   modify_field( Weehawken.Wymer, Coleman );
}
action Niota() {
   drop();
}
table Alvord {
   reads {
     eg_intr_md.egress_rid: exact;
   }
   actions {
      Sonoma;
   }
   default_action: Niota;
   size : 57344;
}
control Amenia {
   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Alvord);
   }
}
counter Atoka {
   type : packets;
   direct: Absarokee;
   min_width: 63;
}
table Absarokee {
   reads {
     Elkins.Chappells mask 0x7fff : exact;
   }
   actions {
      Millstadt;
   }
   default_action: Millstadt();
   size : 32768;
}
action WestCity() {
   modify_field( Yorkville.Metzger, Garretson.Lafayette );
   modify_field( Yorkville.Yetter, Shanghai.Knierim );
   modify_field( Yorkville.Charters, Garretson.Parmerton );
   modify_field( Yorkville.Akiachak, Garretson.Narka );
   modify_field( Yorkville.Elderon, Garretson.Waldport );
}
action Tulsa() {
   modify_field( Yorkville.Metzger, Garretson.Lafayette );
   modify_field( Yorkville.Yetter, StarLake.Berlin );
   modify_field( Yorkville.Charters, Garretson.Parmerton );
   modify_field( Yorkville.Akiachak, Garretson.Narka );
   modify_field( Yorkville.Elderon, Garretson.Waldport );
}
action Lynndyl( Duster ) {
   WestCity();
   modify_field( Yorkville.LaFayette, Duster );
}
action Gunder( Thurmond ) {
   Tulsa();
   modify_field( Yorkville.LaFayette, Thurmond );
}
table Alvordton {
   reads {
     Shanghai.Monaca : ternary;
   }
   actions {
      Lynndyl;
   }
   default_action : WestCity;
  size : 2048;
}
table Rotan {
   reads {
     StarLake.Walnut : ternary;
   }
   actions {
      Gunder;
   }
   default_action : Tulsa;
   size : 1024;
}
action Tiverton( Ashburn ) {
   modify_field( Yorkville.Hitterdal, Ashburn );
}
table MiraLoma {
   reads {
     Shanghai.Slayden : ternary;
   }
   actions {
      Tiverton;
   }
   size : 512;
}
table Coachella {
   reads {
     StarLake.OldGlory : ternary;
   }
   actions {
      Tiverton;
   }
   size : 512;
}
action Munger( Tillson ) {
   modify_field( Yorkville.Cuprum, Tillson );
}
table Ballinger {
   reads {
     Garretson.Hillside : ternary;
   }
   actions {
      Munger;
   }
   size : 512;
}
action Quinnesec( WestBend ) {
   modify_field( Yorkville.WestPark, WestBend );
}
table Larsen {
   reads {
     Garretson.Salamonia : ternary;
   }
   actions {
      Quinnesec;
   }
   size : 512;
}
action Angola( Moose ) {
   modify_field( Yorkville.McMurray, Moose );
}
action Evendale( Ocracoke ) {
   modify_field( Yorkville.McMurray, Ocracoke );
}
table Trego {
   reads {
     Garretson.Talmo : exact;
     Garretson.Tamora : exact;
     Garretson.Dedham : exact;
   }
   actions {
      Angola;
      Millstadt;
   }
   default_action : Millstadt();
   size : 4096;
}
table Everetts {
   reads {
     Garretson.Talmo : exact;
     Garretson.Tamora : exact;
     Fernway.Deport : exact;
   }
   actions {
      Evendale;
   }
   size : 512;
}
control Iberia {
   if( ( Garretson.Talmo & 1 ) == 1 ) {
      apply( Alvordton );
      apply( MiraLoma );
   } else if( ( Garretson.Talmo & 2 ) == 2 ) {
      apply( Rotan );
      apply( Coachella );
   }
   if( ( Garretson.Annetta != 0 and Garretson.Northboro == 1 ) or
       ( Garretson.Annetta == 0 and Mulhall.valid == 1 ) ) {
      apply( Ballinger );
      if( Garretson.Lafayette != 1 ){
         apply( Larsen );
      }
   }
   apply( Trego ) {
      Millstadt {
         apply( Everetts );
      }
   }
}
action Redfield() {
}
action Padonia() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action HornLake() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
}
action Brinson() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
table McKamie {
   reads {
     Elkins.Chappells mask 0x00018000 : ternary;
   }
   actions {
      Redfield;
      Padonia;
      HornLake;
      Brinson;
   }
   size : 16;
}
control Harts {
   apply( McKamie );
   apply( Absarokee );
}
   metadata Whitman Elkins;
   action Blakeley( DuQuoin ) {
          max( Elkins.Chappells, Elkins.Chappells, DuQuoin );
   }
@pragma ways 4
table Kenton {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : exact;
      Yorkville.Hitterdal : exact;
      Yorkville.Cuprum : exact;
      Yorkville.WestPark : exact;
      Yorkville.Metzger : exact;
      Yorkville.Yetter : exact;
      Yorkville.Charters : exact;
      Yorkville.Akiachak : exact;
      Yorkville.Elderon : exact;
   }
   actions {
      Blakeley;
   }
   size : 4096;
}
control MillCity {
   apply( Kenton );
}
table Tunica {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : ternary;
      Yorkville.Hitterdal : ternary;
      Yorkville.Cuprum : ternary;
      Yorkville.WestPark : ternary;
      Yorkville.Metzger : ternary;
      Yorkville.Yetter : ternary;
      Yorkville.Charters : ternary;
      Yorkville.Akiachak : ternary;
      Yorkville.Elderon : ternary;
   }
   actions {
      Blakeley;
   }
   size : 512;
}
control Jarrell {
   apply( Tunica );
}
@pragma pa_no_init ingress Klawock.LaFayette
@pragma pa_no_init ingress Klawock.Hitterdal
@pragma pa_no_init ingress Klawock.Cuprum
@pragma pa_no_init ingress Klawock.WestPark
@pragma pa_no_init ingress Klawock.Metzger
@pragma pa_no_init ingress Klawock.Yetter
@pragma pa_no_init ingress Klawock.Charters
@pragma pa_no_init ingress Klawock.Akiachak
@pragma pa_no_init ingress Klawock.Elderon
metadata Donald Klawock;
@pragma ways 4
table Bevington {
   reads {
      Yorkville.McMurray : exact;
      Klawock.LaFayette : exact;
      Klawock.Hitterdal : exact;
      Klawock.Cuprum : exact;
      Klawock.WestPark : exact;
      Klawock.Metzger : exact;
      Klawock.Yetter : exact;
      Klawock.Charters : exact;
      Klawock.Akiachak : exact;
      Klawock.Elderon : exact;
   }
   actions {
      Blakeley;
   }
   size : 8192;
}
action Joyce( Greenlawn, Bomarton, Provo, Adona, Gilmanton, Readsboro, Montross, Anawalt, Recluse ) {
   bit_and( Klawock.LaFayette, Yorkville.LaFayette, Greenlawn );
   bit_and( Klawock.Hitterdal, Yorkville.Hitterdal, Bomarton );
   bit_and( Klawock.Cuprum, Yorkville.Cuprum, Provo );
   bit_and( Klawock.WestPark, Yorkville.WestPark, Adona );
   bit_and( Klawock.Metzger, Yorkville.Metzger, Gilmanton );
   bit_and( Klawock.Yetter, Yorkville.Yetter, Readsboro );
   bit_and( Klawock.Charters, Yorkville.Charters, Montross );
   bit_and( Klawock.Akiachak, Yorkville.Akiachak, Anawalt );
   bit_and( Klawock.Elderon, Yorkville.Elderon, Recluse );
}
table Hiawassee {
   reads {
      Yorkville.McMurray : exact;
   }
   actions {
      Joyce;
   }
   default_action : Joyce(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Pueblo {
   apply( Hiawassee );
}
control Komatke {
   apply( Bevington );
}
table Edmeston {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : ternary;
      Yorkville.Hitterdal : ternary;
      Yorkville.Cuprum : ternary;
      Yorkville.WestPark : ternary;
      Yorkville.Metzger : ternary;
      Yorkville.Yetter : ternary;
      Yorkville.Charters : ternary;
      Yorkville.Akiachak : ternary;
      Yorkville.Elderon : ternary;
   }
   actions {
      Blakeley;
   }
   size : 512;
}
control Gurley {
   apply( Edmeston );
}
@pragma ways 4
table Campo {
   reads {
      Yorkville.McMurray : exact;
      Klawock.LaFayette : exact;
      Klawock.Hitterdal : exact;
      Klawock.Cuprum : exact;
      Klawock.WestPark : exact;
      Klawock.Metzger : exact;
      Klawock.Yetter : exact;
      Klawock.Charters : exact;
      Klawock.Akiachak : exact;
      Klawock.Elderon : exact;
   }
   actions {
      Blakeley;
   }
   size : 4096;
}
action Rains( Dixie, Nuevo, Groesbeck, Rapids, Heeia, ElkMills, Anoka, Argentine, Junior ) {
   bit_and( Klawock.LaFayette, Yorkville.LaFayette, Dixie );
   bit_and( Klawock.Hitterdal, Yorkville.Hitterdal, Nuevo );
   bit_and( Klawock.Cuprum, Yorkville.Cuprum, Groesbeck );
   bit_and( Klawock.WestPark, Yorkville.WestPark, Rapids );
   bit_and( Klawock.Metzger, Yorkville.Metzger, Heeia );
   bit_and( Klawock.Yetter, Yorkville.Yetter, ElkMills );
   bit_and( Klawock.Charters, Yorkville.Charters, Anoka );
   bit_and( Klawock.Akiachak, Yorkville.Akiachak, Argentine );
   bit_and( Klawock.Elderon, Yorkville.Elderon, Junior );
}
table Roachdale {
   reads {
      Yorkville.McMurray : exact;
   }
   actions {
      Rains;
   }
   default_action : Rains(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Longville {
   apply( Roachdale );
}
control Nixon {
   apply( Campo );
}
table Macedonia {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : ternary;
      Yorkville.Hitterdal : ternary;
      Yorkville.Cuprum : ternary;
      Yorkville.WestPark : ternary;
      Yorkville.Metzger : ternary;
      Yorkville.Yetter : ternary;
      Yorkville.Charters : ternary;
      Yorkville.Akiachak : ternary;
      Yorkville.Elderon : ternary;
   }
   actions {
      Blakeley;
   }
   size : 512;
}
control Natalia {
   apply( Macedonia );
}
@pragma ways 4
table Placedo {
   reads {
      Yorkville.McMurray : exact;
      Klawock.LaFayette : exact;
      Klawock.Hitterdal : exact;
      Klawock.Cuprum : exact;
      Klawock.WestPark : exact;
      Klawock.Metzger : exact;
      Klawock.Yetter : exact;
      Klawock.Charters : exact;
      Klawock.Akiachak : exact;
      Klawock.Elderon : exact;
   }
   actions {
      Blakeley;
   }
   size : 4096;
}
action Ishpeming( Ferrum, Bevier, Kellner, Lomax, Oakley, Mentone, Burrel, Brazos, Baudette ) {
   bit_and( Klawock.LaFayette, Yorkville.LaFayette, Ferrum );
   bit_and( Klawock.Hitterdal, Yorkville.Hitterdal, Bevier );
   bit_and( Klawock.Cuprum, Yorkville.Cuprum, Kellner );
   bit_and( Klawock.WestPark, Yorkville.WestPark, Lomax );
   bit_and( Klawock.Metzger, Yorkville.Metzger, Oakley );
   bit_and( Klawock.Yetter, Yorkville.Yetter, Mentone );
   bit_and( Klawock.Charters, Yorkville.Charters, Burrel );
   bit_and( Klawock.Akiachak, Yorkville.Akiachak, Brazos );
   bit_and( Klawock.Elderon, Yorkville.Elderon, Baudette );
}
table Belfalls {
   reads {
      Yorkville.McMurray : exact;
   }
   actions {
      Ishpeming;
   }
   default_action : Ishpeming(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Sedona {
   apply( Belfalls );
}
control Benitez {
   apply( Placedo );
}
table Mescalero {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : ternary;
      Yorkville.Hitterdal : ternary;
      Yorkville.Cuprum : ternary;
      Yorkville.WestPark : ternary;
      Yorkville.Metzger : ternary;
      Yorkville.Yetter : ternary;
      Yorkville.Charters : ternary;
      Yorkville.Akiachak : ternary;
      Yorkville.Elderon : ternary;
   }
   actions {
      Blakeley;
   }
   size : 512;
}
control LaHabra {
   apply( Mescalero );
}
@pragma ways 4
table Forepaugh {
   reads {
      Yorkville.McMurray : exact;
      Klawock.LaFayette : exact;
      Klawock.Hitterdal : exact;
      Klawock.Cuprum : exact;
      Klawock.WestPark : exact;
      Klawock.Metzger : exact;
      Klawock.Yetter : exact;
      Klawock.Charters : exact;
      Klawock.Akiachak : exact;
      Klawock.Elderon : exact;
   }
   actions {
      Blakeley;
   }
   size : 8192;
}
action Arapahoe( Marydel, Gladden, Clintwood, Ganado, Berkey, Bayport, Traverse, Provencal, Tahuya ) {
   bit_and( Klawock.LaFayette, Yorkville.LaFayette, Marydel );
   bit_and( Klawock.Hitterdal, Yorkville.Hitterdal, Gladden );
   bit_and( Klawock.Cuprum, Yorkville.Cuprum, Clintwood );
   bit_and( Klawock.WestPark, Yorkville.WestPark, Ganado );
   bit_and( Klawock.Metzger, Yorkville.Metzger, Berkey );
   bit_and( Klawock.Yetter, Yorkville.Yetter, Bayport );
   bit_and( Klawock.Charters, Yorkville.Charters, Traverse );
   bit_and( Klawock.Akiachak, Yorkville.Akiachak, Provencal );
   bit_and( Klawock.Elderon, Yorkville.Elderon, Tahuya );
}
table Chaffee {
   reads {
      Yorkville.McMurray : exact;
   }
   actions {
      Arapahoe;
   }
   default_action : Arapahoe(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Russia {
   apply( Chaffee );
}
control Bannack {
   apply( Forepaugh );
}
table Mathias {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : ternary;
      Yorkville.Hitterdal : ternary;
      Yorkville.Cuprum : ternary;
      Yorkville.WestPark : ternary;
      Yorkville.Metzger : ternary;
      Yorkville.Yetter : ternary;
      Yorkville.Charters : ternary;
      Yorkville.Akiachak : ternary;
      Yorkville.Elderon : ternary;
   }
   actions {
      Blakeley;
   }
   size : 512;
}
control Glendale {
   apply( Mathias );
}
@pragma ways 4
table Mustang {
   reads {
      Yorkville.McMurray : exact;
      Klawock.LaFayette : exact;
      Klawock.Hitterdal : exact;
      Klawock.Cuprum : exact;
      Klawock.WestPark : exact;
      Klawock.Metzger : exact;
      Klawock.Yetter : exact;
      Klawock.Charters : exact;
      Klawock.Akiachak : exact;
      Klawock.Elderon : exact;
   }
   actions {
      Blakeley;
   }
   size : 8192;
}
action Pendroy( Pfeifer, Lakin, Pendleton, Belle, OakCity, Sprout, Beaverton, Knollwood, Willey ) {
   bit_and( Klawock.LaFayette, Yorkville.LaFayette, Pfeifer );
   bit_and( Klawock.Hitterdal, Yorkville.Hitterdal, Lakin );
   bit_and( Klawock.Cuprum, Yorkville.Cuprum, Pendleton );
   bit_and( Klawock.WestPark, Yorkville.WestPark, Belle );
   bit_and( Klawock.Metzger, Yorkville.Metzger, OakCity );
   bit_and( Klawock.Yetter, Yorkville.Yetter, Sprout );
   bit_and( Klawock.Charters, Yorkville.Charters, Beaverton );
   bit_and( Klawock.Akiachak, Yorkville.Akiachak, Knollwood );
   bit_and( Klawock.Elderon, Yorkville.Elderon, Willey );
}
table Bayonne {
   reads {
      Yorkville.McMurray : exact;
   }
   actions {
      Pendroy;
   }
   default_action : Pendroy(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Paxson {
   apply( Bayonne );
}
control Canovanas {
   apply( Mustang );
}
table Rochert {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : ternary;
      Yorkville.Hitterdal : ternary;
      Yorkville.Cuprum : ternary;
      Yorkville.WestPark : ternary;
      Yorkville.Metzger : ternary;
      Yorkville.Yetter : ternary;
      Yorkville.Charters : ternary;
      Yorkville.Akiachak : ternary;
      Yorkville.Elderon : ternary;
   }
   actions {
      Blakeley;
   }
   size : 512;
}
control Westel {
   apply( Rochert );
}
@pragma ways 4
table Chambers {
   reads {
      Yorkville.McMurray : exact;
      Klawock.LaFayette : exact;
      Klawock.Hitterdal : exact;
      Klawock.Cuprum : exact;
      Klawock.WestPark : exact;
      Klawock.Metzger : exact;
      Klawock.Yetter : exact;
      Klawock.Charters : exact;
      Klawock.Akiachak : exact;
      Klawock.Elderon : exact;
   }
   actions {
      Blakeley;
   }
   size : 4096;
}
action Stidham( Biloxi, Brookneal, Terral, Revere, Globe, Grisdale, Garrison, NewMelle, Ortley ) {
   bit_and( Klawock.LaFayette, Yorkville.LaFayette, Biloxi );
   bit_and( Klawock.Hitterdal, Yorkville.Hitterdal, Brookneal );
   bit_and( Klawock.Cuprum, Yorkville.Cuprum, Terral );
   bit_and( Klawock.WestPark, Yorkville.WestPark, Revere );
   bit_and( Klawock.Metzger, Yorkville.Metzger, Globe );
   bit_and( Klawock.Yetter, Yorkville.Yetter, Grisdale );
   bit_and( Klawock.Charters, Yorkville.Charters, Garrison );
   bit_and( Klawock.Akiachak, Yorkville.Akiachak, NewMelle );
   bit_and( Klawock.Elderon, Yorkville.Elderon, Ortley );
}
table Loveland {
   reads {
      Yorkville.McMurray : exact;
   }
   actions {
      Stidham;
   }
   default_action : Stidham(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Helen {
   apply( Loveland );
}
control LongPine {
   apply( Chambers );
}
table Trimble {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : ternary;
      Yorkville.Hitterdal : ternary;
      Yorkville.Cuprum : ternary;
      Yorkville.WestPark : ternary;
      Yorkville.Metzger : ternary;
      Yorkville.Yetter : ternary;
      Yorkville.Charters : ternary;
      Yorkville.Akiachak : ternary;
      Yorkville.Elderon : ternary;
   }
   actions {
      Blakeley;
   }
   size : 512;
}
control Luhrig {
   apply( Trimble );
}
@pragma ways 4
table Waring {
   reads {
      Yorkville.McMurray : exact;
      Klawock.LaFayette : exact;
      Klawock.Hitterdal : exact;
      Klawock.Cuprum : exact;
      Klawock.WestPark : exact;
      Klawock.Metzger : exact;
      Klawock.Yetter : exact;
      Klawock.Charters : exact;
      Klawock.Akiachak : exact;
      Klawock.Elderon : exact;
   }
   actions {
      Blakeley;
   }
   size : 4096;
}
action Minto( Mayview, Wetonka, McHenry, Pearcy, Casco, Celada, Hospers, Bouton, Oskawalik ) {
   bit_and( Klawock.LaFayette, Yorkville.LaFayette, Mayview );
   bit_and( Klawock.Hitterdal, Yorkville.Hitterdal, Wetonka );
   bit_and( Klawock.Cuprum, Yorkville.Cuprum, McHenry );
   bit_and( Klawock.WestPark, Yorkville.WestPark, Pearcy );
   bit_and( Klawock.Metzger, Yorkville.Metzger, Casco );
   bit_and( Klawock.Yetter, Yorkville.Yetter, Celada );
   bit_and( Klawock.Charters, Yorkville.Charters, Hospers );
   bit_and( Klawock.Akiachak, Yorkville.Akiachak, Bouton );
   bit_and( Klawock.Elderon, Yorkville.Elderon, Oskawalik );
}
table Schleswig {
   reads {
      Yorkville.McMurray : exact;
   }
   actions {
      Minto;
   }
   default_action : Minto(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Reager {
   apply( Schleswig );
}
control Rawlins {
   apply( Waring );
}
table Arnett {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : ternary;
      Yorkville.Hitterdal : ternary;
      Yorkville.Cuprum : ternary;
      Yorkville.WestPark : ternary;
      Yorkville.Metzger : ternary;
      Yorkville.Yetter : ternary;
      Yorkville.Charters : ternary;
      Yorkville.Akiachak : ternary;
      Yorkville.Elderon : ternary;
   }
   actions {
      Blakeley;
   }
   size : 512;
}
control Oconee {
   apply( Arnett );
}
   metadata Whitman Eddington;
   action Newport( Tahlequah ) {
          max( Eddington.Chappells, Eddington.Chappells, Tahlequah );
   }
   action Milan() { max( Elkins.Chappells, Eddington.Chappells, Elkins.Chappells ); } table Sparland { actions { Milan; } default_action : Milan; size : 1; } control Fristoe { apply( Sparland ); }
@pragma ways 4
table Absecon {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : exact;
      Yorkville.Hitterdal : exact;
      Yorkville.Cuprum : exact;
      Yorkville.WestPark : exact;
      Yorkville.Metzger : exact;
      Yorkville.Yetter : exact;
      Yorkville.Charters : exact;
      Yorkville.Akiachak : exact;
      Yorkville.Elderon : exact;
   }
   actions {
      Newport;
   }
   size : 4096;
}
control Crumstown {
   apply( Absecon );
}
table Needham {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : ternary;
      Yorkville.Hitterdal : ternary;
      Yorkville.Cuprum : ternary;
      Yorkville.WestPark : ternary;
      Yorkville.Metzger : ternary;
      Yorkville.Yetter : ternary;
      Yorkville.Charters : ternary;
      Yorkville.Akiachak : ternary;
      Yorkville.Elderon : ternary;
   }
   actions {
      Newport;
   }
   size : 4096;
}
control Brazil {
   apply( Needham );
}
@pragma pa_no_init ingress Kenyon.LaFayette
@pragma pa_no_init ingress Kenyon.Hitterdal
@pragma pa_no_init ingress Kenyon.Cuprum
@pragma pa_no_init ingress Kenyon.WestPark
@pragma pa_no_init ingress Kenyon.Metzger
@pragma pa_no_init ingress Kenyon.Yetter
@pragma pa_no_init ingress Kenyon.Charters
@pragma pa_no_init ingress Kenyon.Akiachak
@pragma pa_no_init ingress Kenyon.Elderon
metadata Donald Kenyon;
@pragma ways 4
table Boquillas {
   reads {
      Yorkville.McMurray : exact;
      Kenyon.LaFayette : exact;
      Kenyon.Hitterdal : exact;
      Kenyon.Cuprum : exact;
      Kenyon.WestPark : exact;
      Kenyon.Metzger : exact;
      Kenyon.Yetter : exact;
      Kenyon.Charters : exact;
      Kenyon.Akiachak : exact;
      Kenyon.Elderon : exact;
   }
   actions {
      Newport;
   }
   size : 4096;
}
action Hookdale( Newsome, Pilottown, Springlee, Holliday, Blitchton, BigFork, Leonore, Tuskahoma, Powelton ) {
   bit_and( Kenyon.LaFayette, Yorkville.LaFayette, Newsome );
   bit_and( Kenyon.Hitterdal, Yorkville.Hitterdal, Pilottown );
   bit_and( Kenyon.Cuprum, Yorkville.Cuprum, Springlee );
   bit_and( Kenyon.WestPark, Yorkville.WestPark, Holliday );
   bit_and( Kenyon.Metzger, Yorkville.Metzger, Blitchton );
   bit_and( Kenyon.Yetter, Yorkville.Yetter, BigFork );
   bit_and( Kenyon.Charters, Yorkville.Charters, Leonore );
   bit_and( Kenyon.Akiachak, Yorkville.Akiachak, Tuskahoma );
   bit_and( Kenyon.Elderon, Yorkville.Elderon, Powelton );
}
table Belvidere {
   reads {
      Yorkville.McMurray : exact;
   }
   actions {
      Hookdale;
   }
   default_action : Hookdale(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control MudButte {
   apply( Belvidere );
}
control Viroqua {
   apply( Boquillas );
}
table Valmont {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : ternary;
      Yorkville.Hitterdal : ternary;
      Yorkville.Cuprum : ternary;
      Yorkville.WestPark : ternary;
      Yorkville.Metzger : ternary;
      Yorkville.Yetter : ternary;
      Yorkville.Charters : ternary;
      Yorkville.Akiachak : ternary;
      Yorkville.Elderon : ternary;
   }
   actions {
      Newport;
   }
   size : 512;
}
control Tilghman {
   apply( Valmont );
}
@pragma ways 4
table Crystola {
   reads {
      Yorkville.McMurray : exact;
      Kenyon.LaFayette : exact;
      Kenyon.Hitterdal : exact;
      Kenyon.Cuprum : exact;
      Kenyon.WestPark : exact;
      Kenyon.Metzger : exact;
      Kenyon.Yetter : exact;
      Kenyon.Charters : exact;
      Kenyon.Akiachak : exact;
      Kenyon.Elderon : exact;
   }
   actions {
      Newport;
   }
   size : 4096;
}
action Onley( Chaumont, Marfa, Taneytown, Hecker, Barber, Amite, Newtown, Claypool, Platea ) {
   bit_and( Kenyon.LaFayette, Yorkville.LaFayette, Chaumont );
   bit_and( Kenyon.Hitterdal, Yorkville.Hitterdal, Marfa );
   bit_and( Kenyon.Cuprum, Yorkville.Cuprum, Taneytown );
   bit_and( Kenyon.WestPark, Yorkville.WestPark, Hecker );
   bit_and( Kenyon.Metzger, Yorkville.Metzger, Barber );
   bit_and( Kenyon.Yetter, Yorkville.Yetter, Amite );
   bit_and( Kenyon.Charters, Yorkville.Charters, Newtown );
   bit_and( Kenyon.Akiachak, Yorkville.Akiachak, Claypool );
   bit_and( Kenyon.Elderon, Yorkville.Elderon, Platea );
}
table Goldman {
   reads {
      Yorkville.McMurray : exact;
   }
   actions {
      Onley;
   }
   default_action : Onley(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control MuleBarn {
   apply( Goldman );
}
control Neame {
   apply( Crystola );
}
table Dundalk {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : ternary;
      Yorkville.Hitterdal : ternary;
      Yorkville.Cuprum : ternary;
      Yorkville.WestPark : ternary;
      Yorkville.Metzger : ternary;
      Yorkville.Yetter : ternary;
      Yorkville.Charters : ternary;
      Yorkville.Akiachak : ternary;
      Yorkville.Elderon : ternary;
   }
   actions {
      Newport;
   }
   size : 512;
}
control Caban {
   apply( Dundalk );
}
@pragma ways 4
table Chelsea {
   reads {
      Yorkville.McMurray : exact;
      Kenyon.LaFayette : exact;
      Kenyon.Hitterdal : exact;
      Kenyon.Cuprum : exact;
      Kenyon.WestPark : exact;
      Kenyon.Metzger : exact;
      Kenyon.Yetter : exact;
      Kenyon.Charters : exact;
      Kenyon.Akiachak : exact;
      Kenyon.Elderon : exact;
   }
   actions {
      Newport;
   }
   size : 4096;
}
action Odebolt( LoonLake, Remington, Herod, Mackey, Tarlton, WestLawn, Gretna, Shade, Pachuta ) {
   bit_and( Kenyon.LaFayette, Yorkville.LaFayette, LoonLake );
   bit_and( Kenyon.Hitterdal, Yorkville.Hitterdal, Remington );
   bit_and( Kenyon.Cuprum, Yorkville.Cuprum, Herod );
   bit_and( Kenyon.WestPark, Yorkville.WestPark, Mackey );
   bit_and( Kenyon.Metzger, Yorkville.Metzger, Tarlton );
   bit_and( Kenyon.Yetter, Yorkville.Yetter, WestLawn );
   bit_and( Kenyon.Charters, Yorkville.Charters, Gretna );
   bit_and( Kenyon.Akiachak, Yorkville.Akiachak, Shade );
   bit_and( Kenyon.Elderon, Yorkville.Elderon, Pachuta );
}
table Secaucus {
   reads {
      Yorkville.McMurray : exact;
   }
   actions {
      Odebolt;
   }
   default_action : Odebolt(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Placida {
   apply( Secaucus );
}
control KentPark {
   apply( Chelsea );
}
table Talbotton {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : ternary;
      Yorkville.Hitterdal : ternary;
      Yorkville.Cuprum : ternary;
      Yorkville.WestPark : ternary;
      Yorkville.Metzger : ternary;
      Yorkville.Yetter : ternary;
      Yorkville.Charters : ternary;
      Yorkville.Akiachak : ternary;
      Yorkville.Elderon : ternary;
   }
   actions {
      Newport;
   }
   size : 512;
}
control Yukon {
   apply( Talbotton );
}
@pragma ways 4
table Idabel {
   reads {
      Yorkville.McMurray : exact;
      Kenyon.LaFayette : exact;
      Kenyon.Hitterdal : exact;
      Kenyon.Cuprum : exact;
      Kenyon.WestPark : exact;
      Kenyon.Metzger : exact;
      Kenyon.Yetter : exact;
      Kenyon.Charters : exact;
      Kenyon.Akiachak : exact;
      Kenyon.Elderon : exact;
   }
   actions {
      Newport;
   }
   size : 4096;
}
action Ladelle( LeaHill, Leonidas, Rosboro, Antelope, Greenbelt, Wenatchee, Galestown, Sofia, Lyndell ) {
   bit_and( Kenyon.LaFayette, Yorkville.LaFayette, LeaHill );
   bit_and( Kenyon.Hitterdal, Yorkville.Hitterdal, Leonidas );
   bit_and( Kenyon.Cuprum, Yorkville.Cuprum, Rosboro );
   bit_and( Kenyon.WestPark, Yorkville.WestPark, Antelope );
   bit_and( Kenyon.Metzger, Yorkville.Metzger, Greenbelt );
   bit_and( Kenyon.Yetter, Yorkville.Yetter, Wenatchee );
   bit_and( Kenyon.Charters, Yorkville.Charters, Galestown );
   bit_and( Kenyon.Akiachak, Yorkville.Akiachak, Sofia );
   bit_and( Kenyon.Elderon, Yorkville.Elderon, Lyndell );
}
table CapRock {
   reads {
      Yorkville.McMurray : exact;
   }
   actions {
      Ladelle;
   }
   default_action : Ladelle(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Snowflake {
   apply( CapRock );
}
control Cockrum {
   apply( Idabel );
}
table Bonney {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : ternary;
      Yorkville.Hitterdal : ternary;
      Yorkville.Cuprum : ternary;
      Yorkville.WestPark : ternary;
      Yorkville.Metzger : ternary;
      Yorkville.Yetter : ternary;
      Yorkville.Charters : ternary;
      Yorkville.Akiachak : ternary;
      Yorkville.Elderon : ternary;
   }
   actions {
      Newport;
   }
   size : 512;
}
control FlyingH {
   apply( Bonney );
}
@pragma ways 4
table Olmstead {
   reads {
      Yorkville.McMurray : exact;
      Kenyon.LaFayette : exact;
      Kenyon.Hitterdal : exact;
      Kenyon.Cuprum : exact;
      Kenyon.WestPark : exact;
      Kenyon.Metzger : exact;
      Kenyon.Yetter : exact;
      Kenyon.Charters : exact;
      Kenyon.Akiachak : exact;
      Kenyon.Elderon : exact;
   }
   actions {
      Newport;
   }
   size : 4096;
}
action Washoe( PawCreek, Abernathy, Wauseon, Decherd, Allison, Cozad, Kettering, Vantage, Lamkin ) {
   bit_and( Kenyon.LaFayette, Yorkville.LaFayette, PawCreek );
   bit_and( Kenyon.Hitterdal, Yorkville.Hitterdal, Abernathy );
   bit_and( Kenyon.Cuprum, Yorkville.Cuprum, Wauseon );
   bit_and( Kenyon.WestPark, Yorkville.WestPark, Decherd );
   bit_and( Kenyon.Metzger, Yorkville.Metzger, Allison );
   bit_and( Kenyon.Yetter, Yorkville.Yetter, Cozad );
   bit_and( Kenyon.Charters, Yorkville.Charters, Kettering );
   bit_and( Kenyon.Akiachak, Yorkville.Akiachak, Vantage );
   bit_and( Kenyon.Elderon, Yorkville.Elderon, Lamkin );
}
table Frederick {
   reads {
      Yorkville.McMurray : exact;
   }
   actions {
      Washoe;
   }
   default_action : Washoe(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Grainola {
   apply( Frederick );
}
control Chewalla {
   apply( Olmstead );
}
table Mapleton {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : ternary;
      Yorkville.Hitterdal : ternary;
      Yorkville.Cuprum : ternary;
      Yorkville.WestPark : ternary;
      Yorkville.Metzger : ternary;
      Yorkville.Yetter : ternary;
      Yorkville.Charters : ternary;
      Yorkville.Akiachak : ternary;
      Yorkville.Elderon : ternary;
   }
   actions {
      Newport;
   }
   size : 512;
}
control Coamo {
   apply( Mapleton );
}
@pragma ways 4
table Breda {
   reads {
      Yorkville.McMurray : exact;
      Kenyon.LaFayette : exact;
      Kenyon.Hitterdal : exact;
      Kenyon.Cuprum : exact;
      Kenyon.WestPark : exact;
      Kenyon.Metzger : exact;
      Kenyon.Yetter : exact;
      Kenyon.Charters : exact;
      Kenyon.Akiachak : exact;
      Kenyon.Elderon : exact;
   }
   actions {
      Newport;
   }
   size : 4096;
}
action Lovett( Fount, Spindale, Honuapo, Kevil, Manakin, Tulip, Petrolia, JaneLew, Wilsey ) {
   bit_and( Kenyon.LaFayette, Yorkville.LaFayette, Fount );
   bit_and( Kenyon.Hitterdal, Yorkville.Hitterdal, Spindale );
   bit_and( Kenyon.Cuprum, Yorkville.Cuprum, Honuapo );
   bit_and( Kenyon.WestPark, Yorkville.WestPark, Kevil );
   bit_and( Kenyon.Metzger, Yorkville.Metzger, Manakin );
   bit_and( Kenyon.Yetter, Yorkville.Yetter, Tulip );
   bit_and( Kenyon.Charters, Yorkville.Charters, Petrolia );
   bit_and( Kenyon.Akiachak, Yorkville.Akiachak, JaneLew );
   bit_and( Kenyon.Elderon, Yorkville.Elderon, Wilsey );
}
table Gallinas {
   reads {
      Yorkville.McMurray : exact;
   }
   actions {
      Lovett;
   }
   default_action : Lovett(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Salix {
   apply( Gallinas );
}
control Goulds {
   apply( Breda );
}
table Marquette {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : ternary;
      Yorkville.Hitterdal : ternary;
      Yorkville.Cuprum : ternary;
      Yorkville.WestPark : ternary;
      Yorkville.Metzger : ternary;
      Yorkville.Yetter : ternary;
      Yorkville.Charters : ternary;
      Yorkville.Akiachak : ternary;
      Yorkville.Elderon : ternary;
   }
   actions {
      Newport;
   }
   size : 512;
}
control Mahomet {
   apply( Marquette );
}
@pragma ways 4
table Wyndmoor {
   reads {
      Yorkville.McMurray : exact;
      Kenyon.LaFayette : exact;
      Kenyon.Hitterdal : exact;
      Kenyon.Cuprum : exact;
      Kenyon.WestPark : exact;
      Kenyon.Metzger : exact;
      Kenyon.Yetter : exact;
      Kenyon.Charters : exact;
      Kenyon.Akiachak : exact;
      Kenyon.Elderon : exact;
   }
   actions {
      Newport;
   }
   size : 4096;
}
action Gregory( Chevak, Oakmont, Bratenahl, Pittsboro, Academy, Westland, Roggen, Troup, Deloit ) {
   bit_and( Kenyon.LaFayette, Yorkville.LaFayette, Chevak );
   bit_and( Kenyon.Hitterdal, Yorkville.Hitterdal, Oakmont );
   bit_and( Kenyon.Cuprum, Yorkville.Cuprum, Bratenahl );
   bit_and( Kenyon.WestPark, Yorkville.WestPark, Pittsboro );
   bit_and( Kenyon.Metzger, Yorkville.Metzger, Academy );
   bit_and( Kenyon.Yetter, Yorkville.Yetter, Westland );
   bit_and( Kenyon.Charters, Yorkville.Charters, Roggen );
   bit_and( Kenyon.Akiachak, Yorkville.Akiachak, Troup );
   bit_and( Kenyon.Elderon, Yorkville.Elderon, Deloit );
}
table SourLake {
   reads {
      Yorkville.McMurray : exact;
   }
   actions {
      Gregory;
   }
   default_action : Gregory(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Chazy {
   apply( SourLake );
}
control Naguabo {
   apply( Wyndmoor );
}
table Grubbs {
   reads {
      Yorkville.McMurray : exact;
      Yorkville.LaFayette : ternary;
      Yorkville.Hitterdal : ternary;
      Yorkville.Cuprum : ternary;
      Yorkville.WestPark : ternary;
      Yorkville.Metzger : ternary;
      Yorkville.Yetter : ternary;
      Yorkville.Charters : ternary;
      Yorkville.Akiachak : ternary;
      Yorkville.Elderon : ternary;
   }
   actions {
      Newport;
   }
   size : 512;
}
control Paisley {
   apply( Grubbs );
}
control ingress {
   Conda();
   if( Fernway.Ludell != 0 ) {
      Sneads();
   }
   Hobart();
   if( Fernway.Ludell != 0 ) {
      Ranchito();
      Albany();
   }
   Baytown();
   Iberia();
   GlenRose();
   Crooks();
   Pueblo();
   if( Fernway.Ludell != 0 ) {
      Lemont();
   }
   Komatke();
   Longville();
   Nixon();
   Sedona();
   if( Fernway.Ludell != 0 ) {
      Hotchkiss();
   }
   Friday();
   Farragut();
   Benitez();
   Russia();
   if( Fernway.Ludell != 0 ) {
      Cartago();
   }
   Bannack();
   Paxson();
   Brazil();
   Ozona();
   Dustin();
   if( Fernway.Ludell != 0 ) {
      Belen();
   }
   Deering();
   Mabelvale();
   Canovanas();
   Milano();
   if( Weehawken.Saticoy == 0 ) {
      if( valid( Miltona ) ) {
         Helton();
      } else {
         Minturn();
         Barnwell();
      }
   }
   if( not valid( Miltona ) ) {
      Cuney();
   }
   if( Weehawken.Saticoy == 0 ) {
      Ardara();
   }
   Fristoe();
   if ( Fernway.Ludell != 0 ) {
      if( Weehawken.Saticoy == 0 and Garretson.Topawa == 1) {
         apply( Cheyenne );
      } else {
         apply( Burtrum );
      }
   }
   if( Fernway.Ludell != 0 ) {
      Ramapo();
   }
   Cammal();
   if( valid( Despard[0] ) ) {
      Davie();
   }
   if( Weehawken.Saticoy == 0 ) {
      Steele();
   }
   DeRidder();
   Harts();
}
control egress {
   Amenia();
   Kinards();
   Udall();
   if( ( Weehawken.Elvaston == 0 ) and ( Weehawken.Hebbville != 2 ) ) {
      HighHill();
   }
   GunnCity();
}
