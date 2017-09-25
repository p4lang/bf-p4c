// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 221828

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
header_type Pearce {
	fields {
		Bavaria : 16;
		Hawthorne : 16;
		Lomax : 8;
		Spearman : 8;
		Chevak : 8;
		Aiken : 8;
		Bloomburg : 1;
		Delmont : 1;
		RiceLake : 1;
		Dubach : 1;
		Maxwelton : 1;
		MiraLoma : 1;
		Parshall : 1;
	}
}
header_type Auberry {
	fields {
		Burrel : 24;
		Hueytown : 24;
		Callao : 24;
		Dizney : 24;
		Bunker : 16;
		Standish : 16;
		Chloride : 16;
		Swedeborg : 16;
		Bayonne : 16;
		Cedaredge : 8;
		Hospers : 8;
		Menomonie : 1;
		Pachuta : 1;
		Calabasas : 1;
		Potter : 12;
		Slocum : 2;
		Homeland : 1;
		DelMar : 1;
		Gobler : 1;
		WallLake : 1;
		Coupland : 1;
		Pinesdale : 1;
		Kansas : 1;
		Riverwood : 1;
		Kranzburg : 1;
		Seattle : 1;
		Woodstown : 1;
		Fonda : 1;
		Corfu : 1;
		Kinsley : 1;
		Raven : 1;
		Walnut : 1;
		Eolia : 16;
		Northome : 16;
		Tennessee : 8;
		Virginia : 1;
		Marshall : 1;
	}
}
header_type Fries {
	fields {
		Basehor : 24;
		Stratford : 24;
		Rives : 24;
		Arvada : 24;
		Folcroft : 24;
		Peosta : 24;
		Coqui : 24;
		Bajandas : 24;
		Belfair : 16;
		Firesteel : 16;
		Millbrae : 16;
		Gurdon : 16;
		Minturn : 12;
		Willamina : 1;
		Hammond : 3;
		Midas : 1;
		Petrey : 3;
		Anahola : 1;
		Kittredge : 1;
		Jenera : 1;
		Sylvester : 1;
		Willey : 1;
		Paxson : 8;
		Carnation : 12;
		Astatula : 4;
		Juneau : 6;
		Thayne : 10;
		Whitetail : 9;
		Wheeler : 1;
		Tinaja : 1;
		HamLake : 1;
		Branson : 1;
		Boerne : 1;
	}
}
header_type Murchison {
	fields {
		Ammon : 8;
		Wellsboro : 1;
		Leland : 1;
		Longmont : 1;
		Denhoff : 1;
		RockyGap : 1;
	}
}
header_type VanZandt {
	fields {
		Lordstown : 32;
		Wayne : 32;
		Caballo : 6;
		Sparland : 16;
	}
}
header_type Swifton {
	fields {
		Scanlon : 128;
		Darden : 128;
		Ayden : 20;
		Grenville : 8;
		Heppner : 11;
		Sawyer : 6;
		Newtonia : 13;
	}
}
header_type Olyphant {
	fields {
		Floris : 14;
		Crowheart : 1;
		Heidrick : 12;
		Groesbeck : 1;
		Lamona : 1;
		Suamico : 2;
		Nenana : 6;
		Honalo : 3;
	}
}
header_type Anthon {
	fields {
		Vinings : 1;
		Florien : 1;
	}
}
header_type Balmorhea {
	fields {
		Ridgetop : 8;
	}
}
header_type Lisle {
	fields {
		Locke : 16;
		Schleswig : 11;
	}
}
header_type Moultrie {
	fields {
		Woodlake : 32;
		Gilliam : 32;
		Albany : 32;
	}
}
header_type Hanford {
	fields {
		Moraine : 32;
		GlenDean : 32;
	}
}
header_type Nuangola {
	fields {
		Riverbank : 1;
		Excel : 1;
		Pickering : 1;
		Robbins : 3;
		Naubinway : 1;
		Machens : 6;
		Ingleside : 5;
	}
}
header_type Montbrook {
	fields {
		Powelton : 16;
	}
}
header_type Penrose {
	fields {
		Robinette : 14;
		Bonsall : 1;
		Rolla : 1;
	}
}
header_type Dollar {
	fields {
		Moneta : 14;
		Pease : 1;
		SanRemo : 1;
	}
}
header_type Devola {
	fields {
		Harshaw : 16;
		Prosser : 16;
		Cowden : 16;
		DeBeque : 16;
		Lemont : 8;
		Fernway : 8;
		Gomez : 8;
		LaFayette : 8;
		SomesBar : 1;
		Yorklyn : 6;
	}
}
header_type Selawik {
	fields {
		Ashtola : 32;
	}
}
header_type Fishers {
	fields {
		Colson : 6;
		RedBay : 10;
		Riley : 4;
		Croft : 12;
		Orrick : 12;
		Pendleton : 2;
		Ovett : 2;
		Bridgton : 8;
		Woodsdale : 3;
		Hoagland : 5;
	}
}
header_type Mackey {
	fields {
		Valentine : 24;
		ElmPoint : 24;
		Langdon : 24;
		Breda : 24;
		Brodnax : 16;
	}
}
header_type Henning {
	fields {
		Jeddo : 3;
		Heuvelton : 1;
		Robbs : 12;
		Robins : 16;
	}
}
header_type Finney {
	fields {
		Humarock : 4;
		Aguila : 4;
		Monkstown : 6;
		Rockaway : 2;
		OakCity : 16;
		Hamel : 16;
		Hartfield : 3;
		Bladen : 13;
		Ridgeland : 8;
		HillTop : 8;
		Woodward : 16;
		Wahoo : 32;
		Picayune : 32;
	}
}
header_type Bardwell {
	fields {
		Wolverine : 4;
		Sprout : 6;
		Thurston : 2;
		Vibbard : 20;
		Aniak : 16;
		Wapinitia : 8;
		Sequim : 8;
		Lindsborg : 128;
		Bulverde : 128;
	}
}
header_type Dwight {
	fields {
		Convoy : 8;
		Portales : 8;
		Nevis : 16;
	}
}
header_type Ranburne {
	fields {
		Micco : 16;
		Longhurst : 16;
	}
}
header_type Bayville {
	fields {
		Kinard : 32;
		Noyes : 32;
		Brookston : 4;
		Kiron : 4;
		Abilene : 8;
		Madill : 16;
		Biggers : 16;
		Oxnard : 16;
	}
}
header_type Parthenon {
	fields {
		Gobles : 16;
		Norridge : 16;
	}
}
header_type Hollymead {
	fields {
		Shelby : 16;
		Chalco : 16;
		Arvana : 8;
		Belfast : 8;
		Cardenas : 16;
	}
}
header_type Madeira {
	fields {
		Brewerton : 48;
		Champlin : 32;
		Picacho : 48;
		Langtry : 32;
	}
}
header_type Bratt {
	fields {
		Haugen : 1;
		Saluda : 1;
		Bergoo : 1;
		Saticoy : 1;
		Farthing : 1;
		Matheson : 3;
		Kinney : 5;
		Gladden : 3;
		Hydaburg : 16;
	}
}
header_type Fairlee {
	fields {
		Angeles : 24;
		Naylor : 8;
	}
}
header_type Hartwell {
	fields {
		Oilmont : 8;
		Ironia : 24;
		Lovilia : 24;
		Fairborn : 8;
	}
}
header Mackey Parkland;
header Mackey Caspian;
header Henning Owyhee[ 2 ];
@pragma pa_fragment ingress Klukwan.Woodward
@pragma pa_fragment egress Klukwan.Woodward
header Finney Klukwan;
@pragma pa_fragment ingress Sharptown.Woodward
@pragma pa_fragment egress Sharptown.Woodward
header Finney Sharptown;
header Bardwell Dolliver;
@pragma pa_container_size ingress Rehoboth.Lindsborg 32
header Bardwell Rehoboth;
header Ranburne Moapa;
header Ranburne Atlas;
header Bayville Blunt;
header Parthenon Ravinia;
header Bayville Rienzi;
header Parthenon PellCity;
header Hartwell Ironside;
header Hollymead Sitka;
header Bratt Hartwick;
header Fishers Shasta;
header Mackey Servia;
parser start {
   return select(current(96, 16)) {
      0xBF00 : Holladay;
      default : Quitman;
   }
}
parser Nason {
   extract( Shasta );
   return Quitman;
}
parser Holladay {
   extract( Servia );
   return Nason;
}
parser Quitman {
   extract( Parkland );
   return select( Parkland.Brodnax ) {
      0x8100 : LasVegas;
      0x0800 : Philip;
      0x86dd : Livonia;
      0x0806 : Keokee;
      default : ingress;
   }
}
parser LasVegas {
   extract( Owyhee[0] );
   set_metadata(Abernant.Maxwelton, 1);
   return select( Owyhee[0].Robins ) {
      0x0800 : Philip;
      0x86dd : Livonia;
      0x0806 : Keokee;
      default : ingress;
   }
}
field_list Hobucken {
    Klukwan.Humarock;
    Klukwan.Aguila;
    Klukwan.Monkstown;
    Klukwan.Rockaway;
    Klukwan.OakCity;
    Klukwan.Hamel;
    Klukwan.Hartfield;
    Klukwan.Bladen;
    Klukwan.Ridgeland;
    Klukwan.HillTop;
    Klukwan.Wahoo;
    Klukwan.Picayune;
}
field_list_calculation Ripley {
    input {
        Hobucken;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Klukwan.Woodward {
    verify Ripley;
    update Ripley;
}
parser Philip {
   extract( Klukwan );
   set_metadata(Abernant.Lomax, Klukwan.HillTop);
   set_metadata(Abernant.Chevak, Klukwan.Ridgeland);
   set_metadata(Abernant.Bavaria, Klukwan.OakCity);
   set_metadata(Abernant.RiceLake, 0);
   set_metadata(Abernant.Bloomburg, 1);
   return select(Klukwan.Bladen, Klukwan.Aguila, Klukwan.HillTop) {
      0x501 : Waretown;
      0x511 : Hohenwald;
      0x506 : Fentress;
      0 mask 0xFF7000 : ingress;
      default : Coverdale;
   }
}
parser Coverdale {
   set_metadata(Abernant.MiraLoma, 1);
   return ingress;
}
parser Livonia {
   extract( Rehoboth );
   set_metadata(Abernant.Lomax, Rehoboth.Wapinitia);
   set_metadata(Abernant.Chevak, Rehoboth.Sequim);
   set_metadata(Abernant.Bavaria, Rehoboth.Aniak);
   set_metadata(Abernant.RiceLake, 1);
   set_metadata(Abernant.Bloomburg, 0);
   return select(Rehoboth.Wapinitia) {
      0x3a : Waretown;
      17 : Alsea;
      6 : Fentress;
      default : ingress;
   }
}
parser Keokee {
   extract( Sitka );
   set_metadata(Abernant.Parshall, 1);
   return ingress;
}
parser Hohenwald {
   extract(Moapa);
   extract(Ravinia);
   return select(Moapa.Longhurst) {
      4789 : Emerado;
      default : ingress;
    }
}
parser Waretown {
   set_metadata( Moapa.Micco, current( 0, 16 ) );
   set_metadata( Moapa.Longhurst, 0 );
   return ingress;
}
parser Alsea {
   extract(Moapa);
   extract(Ravinia);
   return ingress;
}
parser Fentress {
   set_metadata(Godley.Virginia, 1);
   extract(Moapa);
   extract(Blunt);
   return ingress;
}
parser Wildell {
   set_metadata(Godley.Slocum, 2);
   return Lesley;
}
parser Bixby {
   set_metadata(Godley.Slocum, 2);
   return Amherst;
}
parser Koloa {
   extract(Hartwick);
   return select(Hartwick.Haugen, Hartwick.Saluda, Hartwick.Bergoo, Hartwick.Saticoy, Hartwick.Farthing,
             Hartwick.Matheson, Hartwick.Kinney, Hartwick.Gladden, Hartwick.Hydaburg) {
      0x0800 : Wildell;
      0x86dd : Bixby;
      default : ingress;
   }
}
parser Emerado {
   extract(Ironside);
   set_metadata(Godley.Slocum, 1);
   return Godfrey;
}
field_list Copley {
    Sharptown.Humarock;
    Sharptown.Aguila;
    Sharptown.Monkstown;
    Sharptown.Rockaway;
    Sharptown.OakCity;
    Sharptown.Hamel;
    Sharptown.Hartfield;
    Sharptown.Bladen;
    Sharptown.Ridgeland;
    Sharptown.HillTop;
    Sharptown.Wahoo;
    Sharptown.Picayune;
}
field_list_calculation Sharon {
    input {
        Copley;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Sharptown.Woodward {
    verify Sharon;
    update Sharon;
}
parser Lesley {
   extract( Sharptown );
   set_metadata(Abernant.Spearman, Sharptown.HillTop);
   set_metadata(Abernant.Aiken, Sharptown.Ridgeland);
   set_metadata(Abernant.Hawthorne, Sharptown.OakCity);
   set_metadata(Abernant.Dubach, 0);
   set_metadata(Abernant.Delmont, 1);
   return select(Sharptown.Bladen, Sharptown.Aguila, Sharptown.HillTop) {
      0x501 : Grainola;
      0x511 : Romeo;
      0x506 : DeRidder;
      0 mask 0xFF7000 : ingress;
      default : Dugger;
   }
}
parser Dugger {
   set_metadata(Godley.Calabasas, 1);
   return ingress;
}
parser Amherst {
   extract( Dolliver );
   set_metadata(Abernant.Spearman, Dolliver.Wapinitia);
   set_metadata(Abernant.Aiken, Dolliver.Sequim);
   set_metadata(Abernant.Hawthorne, Dolliver.Aniak);
   set_metadata(Abernant.Dubach, 1);
   set_metadata(Abernant.Delmont, 0);
   return select(Dolliver.Wapinitia) {
      0x3a : Grainola;
      17 : Romeo;
      6 : DeRidder;
      default : ingress;
   }
}
parser Grainola {
   set_metadata( Godley.Eolia, current( 0, 16 ) );
   set_metadata( Godley.Walnut, 1 );
   return ingress;
}
parser Romeo {
   set_metadata( Godley.Eolia, current( 0, 16 ) );
   set_metadata( Godley.Northome, current( 16, 16 ) );
   set_metadata( Godley.Walnut, 1 );
   return ingress;
}
parser DeRidder {
   set_metadata( Godley.Eolia, current( 0, 16 ) );
   set_metadata( Godley.Northome, current( 16, 16 ) );
   set_metadata( Godley.Tennessee, current( 104, 8 ) );
   set_metadata( Godley.Walnut, 1 );
   set_metadata( Godley.Marshall, 1 );
   extract(Atlas);
   extract(Rienzi);
   return ingress;
}
parser Godfrey {
   extract( Caspian );
   return select( Caspian.Brodnax ) {
      0x0800: Lesley;
      0x86dd: Amherst;
      default: ingress;
   }
}
@pragma pa_no_init ingress Godley.Burrel
@pragma pa_no_init ingress Godley.Hueytown
@pragma pa_no_init ingress Godley.Callao
@pragma pa_no_init ingress Godley.Dizney

@pragma pa_allowed_to_share ingress Godley.Callao Godley.Dizney
metadata Auberry Godley;
@pragma pa_no_init ingress Crane.Basehor
@pragma pa_no_init ingress Crane.Stratford
@pragma pa_no_init ingress Crane.Rives
@pragma pa_no_init ingress Crane.Arvada
metadata Fries Crane;
metadata Olyphant Udall;
@pragma pa_solitary ingress Abernant.MiraLoma
metadata Pearce Abernant;
metadata VanZandt Allgood;
metadata Swifton Alberta;
metadata Anthon Pojoaque;
@pragma pa_container_size ingress Pojoaque.Florien 32
metadata Murchison Fajardo;
metadata Balmorhea Levittown;
metadata Lisle Saragosa;
metadata Hanford Webbville;
metadata Moultrie Satus;
metadata Nuangola Bigfork;
metadata Montbrook Yorkshire;
@pragma pa_no_init ingress Cricket.Robinette
metadata Penrose Cricket;
@pragma pa_no_init ingress Saxis.Moneta
metadata Dollar Saxis;
metadata Devola Ankeny;
action Comptche() {
   no_op();
}
action Dauphin() {
   modify_field(Godley.WallLake, 1 );
   mark_for_drop();
}
action Snowball() {
   no_op();
}
action Swandale(Wauna, Rowlett, Greenbush, Shine, Luverne,
                 Waldport, Whitlash, Wharton) {
    modify_field(Udall.Floris, Wauna);
    modify_field(Udall.Crowheart, Rowlett);
    modify_field(Udall.Heidrick, Greenbush);
    modify_field(Udall.Groesbeck, Shine);
    modify_field(Udall.Lamona, Luverne);
    modify_field(Udall.Suamico, Waldport);
    modify_field(Udall.Honalo, Whitlash);
    modify_field(Udall.Nenana, Wharton);
}
table LaPointe {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Swandale;
    }
    size : 288;
}
control Rosario {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(LaPointe);
    }
}
action Mayflower(Newberg, Gullett) {
   modify_field( Crane.Midas, 1 );
   modify_field( Crane.Paxson, Newberg);
   modify_field( Godley.Seattle, 1 );
   modify_field( Bigfork.Pickering, Gullett );
}
action Riner() {
   modify_field( Godley.Kansas, 1 );
   modify_field( Godley.Fonda, 1 );
}
action Cornville() {
   modify_field( Godley.Seattle, 1 );
}
action Wallace() {
   modify_field( Godley.Seattle, 1 );
   modify_field( Godley.Corfu, 1 );
}
action Mabana() {
   modify_field( Godley.Woodstown, 1 );
}
action Leicester() {
   modify_field( Godley.Fonda, 1 );
}
counter SwissAlp {
   type : packets_and_bytes;
   direct : SandLake;
   min_width: 16;
}
table SandLake {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Parkland.Valentine : ternary;
      Parkland.ElmPoint : ternary;
   }
   actions {
      Mayflower;
      Riner;
      Cornville;
      Mabana;
      Leicester;
      Wallace;
   }
   size : 1024;
}
action Cochrane() {
   modify_field( Godley.Riverwood, 1 );
}
table Wakita {
   reads {
      Parkland.Langdon : ternary;
      Parkland.Breda : ternary;
   }
   actions {
      Cochrane;
   }
   size : 512;
}
control Kalida {
   apply( SandLake );
   apply( Wakita );
}
action Yakutat() {
   modify_field( Allgood.Lordstown, Sharptown.Wahoo );
   modify_field( Allgood.Wayne, Sharptown.Picayune );
   modify_field( Allgood.Caballo, Sharptown.Monkstown );
   modify_field( Alberta.Scanlon, Dolliver.Lindsborg );
   modify_field( Alberta.Darden, Dolliver.Bulverde );
   modify_field( Alberta.Ayden, Dolliver.Vibbard );
   modify_field( Alberta.Sawyer, Dolliver.Sprout );
   modify_field( Godley.Burrel, Caspian.Valentine );
   modify_field( Godley.Hueytown, Caspian.ElmPoint );
   modify_field( Godley.Callao, Caspian.Langdon );
   modify_field( Godley.Dizney, Caspian.Breda );
   modify_field( Godley.Bunker, Caspian.Brodnax );
   modify_field( Godley.Bayonne, Abernant.Hawthorne );
   modify_field( Godley.Cedaredge, Abernant.Spearman );
   modify_field( Godley.Hospers, Abernant.Aiken );
   modify_field( Godley.Pachuta, Abernant.Delmont );
   modify_field( Godley.Menomonie, Abernant.Dubach );
   modify_field( Godley.Kinsley, 0 );
   modify_field( Crane.Petrey, 1 );
   modify_field( Udall.Suamico, 1 );
   modify_field( Udall.Honalo, 0 );
   modify_field( Udall.Nenana, 0 );
   modify_field( Bigfork.Riverbank, 1 );
   modify_field( Bigfork.Excel, 1 );
   modify_field( Godley.Virginia, Godley.Marshall );
}
action Kenvil() {
   modify_field( Godley.Slocum, 0 );
   modify_field( Allgood.Lordstown, Klukwan.Wahoo );
   modify_field( Allgood.Wayne, Klukwan.Picayune );
   modify_field( Allgood.Caballo, Klukwan.Monkstown );
   modify_field( Alberta.Scanlon, Rehoboth.Lindsborg );
   modify_field( Alberta.Darden, Rehoboth.Bulverde );
   modify_field( Alberta.Ayden, Rehoboth.Vibbard );
   modify_field( Alberta.Sawyer, Rehoboth.Sprout );
   modify_field( Godley.Burrel, Parkland.Valentine );
   modify_field( Godley.Hueytown, Parkland.ElmPoint );
   modify_field( Godley.Callao, Parkland.Langdon );
   modify_field( Godley.Dizney, Parkland.Breda );
   modify_field( Godley.Bunker, Parkland.Brodnax );
   modify_field( Godley.Bayonne, Abernant.Bavaria );
   modify_field( Godley.Cedaredge, Abernant.Lomax );
   modify_field( Godley.Hospers, Abernant.Chevak );
   modify_field( Godley.Pachuta, Abernant.Bloomburg );
   modify_field( Godley.Menomonie, Abernant.RiceLake );
   modify_field( Bigfork.Naubinway, Owyhee[0].Heuvelton );
   modify_field( Godley.Kinsley, Abernant.Maxwelton );
   modify_field( Godley.Calabasas, Abernant.MiraLoma );
   modify_field( Godley.Eolia, Moapa.Micco );
   modify_field( Godley.Northome, Moapa.Longhurst );
   modify_field( Godley.Tennessee, Blunt.Abilene );
}
table Oskawalik {
   reads {
      Parkland.Valentine : exact;
      Parkland.ElmPoint : exact;
      Klukwan.Picayune : exact;
      Godley.Slocum : exact;
   }
   actions {
      Yakutat;
      Kenvil;
   }
   default_action : Kenvil();
   size : 1024;
}
action Longford() {
   modify_field( Godley.Standish, Udall.Heidrick );
   modify_field( Godley.Chloride, Udall.Floris);
}
action Risco( Bodcaw ) {
   modify_field( Godley.Standish, Bodcaw );
   modify_field( Godley.Chloride, Udall.Floris);
}
action Freetown() {
   modify_field( Godley.Standish, Owyhee[0].Robbs );
   modify_field( Godley.Chloride, Udall.Floris);
}
table Darien {
   reads {
      Udall.Floris : ternary;
      Owyhee[0] : valid;
      Owyhee[0].Robbs : ternary;
   }
   actions {
      Longford;
      Risco;
      Freetown;
   }
   size : 4096;
}
action Moseley( Bothwell ) {
   modify_field( Godley.Chloride, Bothwell );
}
action Buenos() {
   modify_field( Godley.Gobler, 1 );
   modify_field( Levittown.Ridgetop,
                 1 );
}
table ElCentro {
   reads {
      Klukwan.Wahoo : exact;
   }
   actions {
      Moseley;
      Buenos;
   }
   default_action : Buenos;
   size : 4096;
}
action Lacombe( Lolita, Savery, Hooker, Borup, Barron,
                        Tindall, Cross ) {
   modify_field( Godley.Standish, Lolita );
   modify_field( Godley.Swedeborg, Lolita );
   modify_field( Godley.Pinesdale, Cross );
   Lauada(Savery, Hooker, Borup, Barron,
                        Tindall );
}
action Grays() {
   modify_field( Godley.Coupland, 1 );
}
table Berkey {
   reads {
      Ironside.Lovilia : exact;
   }
   actions {
      Lacombe;
      Grays;
   }
   size : 4096;
}
action Lauada(Wenden, Samson, Portville, Gibbs,
                        Flasher ) {
   modify_field( Fajardo.Ammon, Wenden );
   modify_field( Fajardo.Wellsboro, Samson );
   modify_field( Fajardo.Longmont, Portville );
   modify_field( Fajardo.Leland, Gibbs );
   modify_field( Fajardo.Denhoff, Flasher );
}
action Gardena(Wheatland, Freeman, Flomaton, Weissert,
                        Munich ) {
   modify_field( Godley.Swedeborg, Udall.Heidrick );
   Lauada(Wheatland, Freeman, Flomaton, Weissert,
                        Munich );
}
action Berenice(Rollins, Schaller, Platina, Leflore,
                        Claiborne, Rankin ) {
   modify_field( Godley.Swedeborg, Rollins );
   Lauada(Schaller, Platina, Leflore, Claiborne,
                        Rankin );
}
action Lajitas(Kingstown, Pueblo, Silvertip, Atlasburg,
                        Daphne ) {
   modify_field( Godley.Swedeborg, Owyhee[0].Robbs );
   Lauada(Kingstown, Pueblo, Silvertip, Atlasburg,
                        Daphne );
}
table Callimont {
   reads {
      Udall.Heidrick : exact;
   }
   actions {
      Comptche;
      Gardena;
   }
   size : 4096;
}
@pragma action_default_only Comptche
table Astor {
   reads {
      Udall.Floris : exact;
      Owyhee[0].Robbs : exact;
   }
   actions {
      Berenice;
      Comptche;
   }
   size : 1024;
}
table Tahuya {
   reads {
      Owyhee[0].Robbs : exact;
   }
   actions {
      Comptche;
      Lajitas;
   }
   size : 4096;
}
control Abraham {
   apply( Oskawalik ) {
         Yakutat {
            apply( ElCentro );
            apply( Berkey );
         }
         Kenvil {
            if ( not valid(Shasta) and Udall.Groesbeck == 1 ) {
               apply( Darien );
            }
            if ( valid( Owyhee[ 0 ] ) ) {
               apply( Astor ) {
                  Comptche {
                     apply( Tahuya );
                  }
               }
            } else {
               apply( Callimont );
            }
         }
   }
}
register Hibernia {
    width : 1;
    static : Bucktown;
    instance_count : 294912;
}
register Frontier {
    width : 1;
    static : Hookdale;
    instance_count : 294912;
}
blackbox stateful_alu Campton {
    reg : Hibernia;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : Pojoaque.Vinings;
}
blackbox stateful_alu Panaca {
    reg : Frontier;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst : Pojoaque.Florien;
}
field_list Summit {
    ig_intr_md.ingress_port;
    Owyhee[0].Robbs;
}
field_list_calculation Lampasas {
    input { Summit; }
    algorithm: identity;
    output_width: 19;
}
action Buckeye() {
    Campton.execute_stateful_alu_from_hash(Lampasas);
}
action Odebolt() {
    Panaca.execute_stateful_alu_from_hash(Lampasas);
}
table Bucktown {
    actions {
      Buckeye;
    }
    default_action : Buckeye;
    size : 1;
}
table Hookdale {
    actions {
      Odebolt;
    }
    default_action : Odebolt;
    size : 1;
}
action Blossburg(Bennet) {
    modify_field(Pojoaque.Florien, Bennet);
}
@pragma use_hash_action 0
table Roggen {
    reads {
       ig_intr_md.ingress_port mask 0x7f : exact;
    }
    actions {
      Blossburg;
    }
    size : 72;
}
action Coconut() {
   modify_field( Godley.Potter, Udall.Heidrick );
   modify_field( Godley.Homeland, 0 );
}
table Anson {
   actions {
      Coconut;
   }
   size : 1;
}
action Northway() {
   modify_field( Godley.Potter, Owyhee[0].Robbs );
   modify_field( Godley.Homeland, 1 );
}
table Sahuarita {
   actions {
      Northway;
   }
   size : 1;
}
control Netarts {
   if ( valid( Owyhee[ 0 ] ) ) {
      apply( Sahuarita );
      if( Udall.Lamona == 1 ) {
         apply( Bucktown );
         apply( Hookdale );
      }
   } else {
      apply( Anson );
      if( Udall.Lamona == 1 ) {
         apply( Roggen );
      }
   }
}
field_list Newfane {
   Parkland.Valentine;
   Parkland.ElmPoint;
   Parkland.Langdon;
   Parkland.Breda;
   Parkland.Brodnax;
}
field_list Pelland {
   Klukwan.HillTop;
   Klukwan.Wahoo;
   Klukwan.Picayune;
}
field_list Edgemont {
   Rehoboth.Lindsborg;
   Rehoboth.Bulverde;
   Rehoboth.Vibbard;
   Rehoboth.Wapinitia;
}
field_list Endicott {
   Klukwan.Wahoo;
   Klukwan.Picayune;
   Moapa.Micco;
   Moapa.Longhurst;
}
field_list_calculation Broadwell {
    input {
        Newfane;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Odenton {
    input {
        Pelland;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Vanoss {
    input {
        Edgemont;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Calhan {
    input {
        Endicott;
    }
    algorithm : crc32;
    output_width : 32;
}
action Goudeau() {
    modify_field_with_hash_based_offset(Satus.Woodlake, 0,
                                        Broadwell, 4294967296);
}
action Hermiston() {
    modify_field_with_hash_based_offset(Satus.Gilliam, 0,
                                        Odenton, 4294967296);
}
action DelRosa() {
    modify_field_with_hash_based_offset(Satus.Gilliam, 0,
                                        Vanoss, 4294967296);
}
action Wheeling() {
    modify_field_with_hash_based_offset(Satus.Albany, 0,
                                        Calhan, 4294967296);
}
table Lofgreen {
   actions {
      Goudeau;
   }
   size: 1;
}
control Emden {
   apply(Lofgreen);
}
table Coalton {
   actions {
      Hermiston;
   }
   size: 1;
}
table Suffern {
   actions {
      DelRosa;
   }
   size: 1;
}
control Chatmoss {
   if ( valid( Klukwan ) ) {
      apply(Coalton);
   } else {
      if ( valid( Rehoboth ) ) {
         apply(Suffern);
      }
   }
}
table Hester {
   actions {
      Wheeling;
   }
   size: 1;
}
control Holden {
   if ( valid( Ravinia ) ) {
      apply(Hester);
   }
}
action Longport() {
    modify_field(Webbville.Moraine, Satus.Woodlake);
}
action Vidaurri() {
    modify_field(Webbville.Moraine, Satus.Gilliam);
}
action Topanga() {
    modify_field(Webbville.Moraine, Satus.Albany);
}
@pragma action_default_only Comptche
@pragma immediate 0
table Vantage {
   reads {
      Rienzi.valid : ternary;
      PellCity.valid : ternary;
      Sharptown.valid : ternary;
      Dolliver.valid : ternary;
      Caspian.valid : ternary;
      Blunt.valid : ternary;
      Ravinia.valid : ternary;
      Klukwan.valid : ternary;
      Rehoboth.valid : ternary;
      Parkland.valid : ternary;
   }
   actions {
      Longport;
      Vidaurri;
      Topanga;
      Comptche;
   }
   size: 256;
}
action Shelbina() {
    modify_field(Webbville.GlenDean, Satus.Albany);
}
@pragma immediate 0
table Hanahan {
   reads {
      Rienzi.valid : ternary;
      PellCity.valid : ternary;
      Blunt.valid : ternary;
      Ravinia.valid : ternary;
   }
   actions {
      Shelbina;
      Comptche;
   }
   size: 6;
}
control Maybee {
   apply(Hanahan);
   apply(Vantage);
}
counter Ethete {
   type : packets_and_bytes;
   direct : Mapleton;
   min_width: 16;
}
table Mapleton {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Pojoaque.Florien : ternary;
      Pojoaque.Vinings : ternary;
      Godley.Coupland : ternary;
      Godley.Riverwood : ternary;
      Godley.Kansas : ternary;
   }
   actions {
      Dauphin;
      Comptche;
   }
   default_action : Comptche();
   size : 512;
}
table Captiva {
   reads {
      Godley.Callao : exact;
      Godley.Dizney : exact;
      Godley.Standish : exact;
   }
   actions {
      Dauphin;
      Comptche;
   }
   default_action : Comptche();
   size : 4096;
}
action FifeLake() {
   modify_field(Godley.DelMar, 1 );
   modify_field(Levittown.Ridgetop,
                0);
}
table Brashear {
   reads {
      Godley.Callao : exact;
      Godley.Dizney : exact;
      Godley.Standish : exact;
      Godley.Chloride : exact;
   }
   actions {
      Snowball;
      FifeLake;
   }
   default_action : FifeLake();
   size : 65536;
   support_timeout : true;
}
action Attalla( Tonasket, Neavitt ) {
   modify_field( Godley.Raven, Tonasket );
   modify_field( Godley.Pinesdale, Neavitt );
}
action Chappells() {
   modify_field( Godley.Pinesdale, 1 );
}
table Nuremberg {
   reads {
      Godley.Standish mask 0xfff : exact;
   }
   actions {
      Attalla;
      Chappells;
      Comptche;
   }
   default_action : Comptche();
   size : 4096;
}
action Plata() {
   modify_field( Fajardo.RockyGap, 1 );
}
table Hutchings {
   reads {
      Godley.Swedeborg : ternary;
      Godley.Burrel : exact;
      Godley.Hueytown : exact;
   }
   actions {
      Plata;
   }
   size: 512;
}
control Westville {
   apply( Mapleton ) {
      Comptche {
         apply( Captiva ) {
            Comptche {
               if (Udall.Crowheart == 0 and Godley.Gobler == 0) {
                  apply( Brashear );
               }
               apply( Nuremberg );
               apply(Hutchings);
            }
         }
      }
   }
}
field_list Thistle {
    Levittown.Ridgetop;
    Godley.Callao;
    Godley.Dizney;
    Godley.Standish;
    Godley.Chloride;
}
action PortWing() {
   generate_digest(0, Thistle);
}
table Farragut {
   actions {
      PortWing;
   }
   size : 1;
}
control Smithland {
   if (Godley.DelMar == 1) {
      apply( Farragut );
   }
}
action Arcanum( Progreso, Lehigh ) {
   modify_field( Alberta.Newtonia, Progreso );
   modify_field( Saragosa.Locke, Lehigh );
}
action MontIda( Sammamish, Gratis ) {
   modify_field( Alberta.Newtonia, Sammamish );
   modify_field( Saragosa.Schleswig, Gratis );
}
@pragma action_default_only Bowlus
table Vananda {
   reads {
      Fajardo.Ammon : exact;
      Alberta.Darden mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Arcanum;
      Bowlus;
      MontIda;
   }
   size : 8192;
}
@pragma atcam_partition_index Alberta.Newtonia
@pragma atcam_number_partitions 8192
table Telida {
   reads {
      Alberta.Newtonia : exact;
      Alberta.Darden mask 0x000007FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Ringtown;
      Tamaqua;
      Comptche;
   }
   default_action : Comptche();
   size : 65536;
}
action Gakona( Linville, Pathfork ) {
   modify_field( Alberta.Heppner, Linville );
   modify_field( Saragosa.Locke, Pathfork );
}
action SanJon( MoonRun, Runnemede ) {
   modify_field( Alberta.Heppner, MoonRun );
   modify_field( Saragosa.Schleswig, Runnemede );
}
@pragma action_default_only Comptche
table Chaires {
   reads {
      Fajardo.Ammon : exact;
      Alberta.Darden : lpm;
   }
   actions {
      Gakona;
      SanJon;
      Comptche;
   }
   size : 2048;
}
@pragma atcam_partition_index Alberta.Heppner
@pragma atcam_number_partitions 2048
table Roxobel {
   reads {
      Alberta.Heppner : exact;
      Alberta.Darden mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Ringtown;
      Tamaqua;
      Comptche;
   }
   default_action : Comptche();
   size : 16384;
}
@pragma action_default_only Bowlus
@pragma idletime_precision 1
table Bacton {
   reads {
      Fajardo.Ammon : exact;
      Allgood.Wayne : lpm;
   }
   actions {
      Ringtown;
      Tamaqua;
      Bowlus;
   }
   size : 1024;
   support_timeout : true;
}
action Trenary( Edesville, Jackpot ) {
   modify_field( Allgood.Sparland, Edesville );
   modify_field( Saragosa.Locke, Jackpot );
}
action Livengood( Estrella, Merced ) {
   modify_field( Allgood.Sparland, Estrella );
   modify_field( Saragosa.Schleswig, Merced );
}
@pragma action_default_only Comptche
table Monteview {
   reads {
      Fajardo.Ammon : exact;
      Allgood.Wayne : lpm;
   }
   actions {
      Trenary;
      Livengood;
      Comptche;
   }
   size : 16384;
}
@pragma ways 2
@pragma atcam_partition_index Allgood.Sparland
@pragma atcam_number_partitions 16384
table NewRome {
   reads {
      Allgood.Sparland : exact;
      Allgood.Wayne mask 0x000fffff : lpm;
   }
   actions {
      Ringtown;
      Tamaqua;
      Comptche;
   }
   default_action : Comptche();
   size : 131072;
}
action Ringtown( Wewela ) {
   modify_field( Saragosa.Locke, Wewela );
}
@pragma idletime_precision 1
table Missoula {
   reads {
      Fajardo.Ammon : exact;
      Allgood.Wayne : exact;
   }
   actions {
      Ringtown;
      Tamaqua;
      Comptche;
   }
   default_action : Comptche();
   size : 65536;
   support_timeout : true;
}
@pragma idletime_precision 1
@pragma stage 2 28672
@pragma stage 3
table HydePark {
   reads {
      Fajardo.Ammon : exact;
      Alberta.Darden : exact;
   }
   actions {
      Ringtown;
      Tamaqua;
      Comptche;
   }
   default_action : Comptche();
   size : 65536;
   support_timeout : true;
}
action Lucien(Enderlin, Mantee, Combine) {
   modify_field(Crane.Belfair, Combine);
   modify_field(Crane.Basehor, Enderlin);
   modify_field(Crane.Stratford, Mantee);
   modify_field(Crane.Wheeler, 1);
   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}
action Calcasieu() {
   Dauphin();
}
action Belmore(Redmon) {
   modify_field(Crane.Midas, 1);
   modify_field(Crane.Paxson, Redmon);
}
action Bowlus(Gumlog) {
   modify_field( Crane.Midas, 1 );
   modify_field( Crane.Paxson, 9 );
}
table Crannell {
   reads {
      Saragosa.Locke : exact;
   }
   actions {
      Lucien;
      Calcasieu;
      Belmore;
   }
   size : 65536;
}
action Tatum( Mattapex ) {
   modify_field(Crane.Midas, 1);
   modify_field(Crane.Paxson, Mattapex);
}
table NorthRim {
   actions {
      Tatum;
   }
   default_action: Tatum(0);
   size : 1;
}
control Wyandanch {
   if ( Godley.WallLake == 0 and Fajardo.RockyGap == 1 ) {
      if ( ( Fajardo.Wellsboro == 1 ) and ( Godley.Pachuta == 1 ) ) {
         apply( Missoula ) {
            Comptche {
               apply(Monteview);
            }
         }
      } else if ( ( Fajardo.Longmont == 1 ) and ( Godley.Menomonie == 1 ) ) {
         apply( HydePark ) {
            Comptche {
               apply( Chaires );
            }
         }
      }
   }
}
control Lakehurst {
   if ( Godley.WallLake == 0 and Fajardo.RockyGap == 1 ) {
      if ( ( Fajardo.Wellsboro == 1 ) and ( Godley.Pachuta == 1 ) ) {
         if ( Allgood.Sparland != 0 ) {
            apply( NewRome );
         } else if ( Saragosa.Locke == 0 and Saragosa.Schleswig == 0 ) {
            apply( Bacton );
         }
      } else if ( ( Fajardo.Longmont == 1 ) and ( Godley.Menomonie == 1 ) ) {
         if ( Alberta.Heppner != 0 ) {
            apply( Roxobel );
         } else if ( Saragosa.Locke == 0 and Saragosa.Schleswig == 0 ) {
            apply( Vananda );
            if ( Alberta.Newtonia != 0 ) {
               apply( Telida );
            }
         }
      } else if( Godley.Pinesdale == 1 ) {
         apply( NorthRim );
      }
   }
}
control Spalding {
   if( Saragosa.Locke != 0 ) {
      apply( Crannell );
   }
}
action Tamaqua( Newcomb ) {
   modify_field( Saragosa.Schleswig, Newcomb );
}
field_list Bogota {
   Webbville.GlenDean;
}
field_list_calculation Bernice {
    input {
        Bogota;
    }
    algorithm : identity;
    output_width : 66;
}
action_selector Bagdad {
   selection_key : Bernice;
   selection_mode : resilient;
}
action_profile Phelps {
   actions {
      Ringtown;
   }
   size : 65536;
   dynamic_action_selection : Bagdad;
}
@pragma selector_max_group_size 256
table Lubeck {
   reads {
      Saragosa.Schleswig : exact;
   }
   action_profile : Phelps;
   size : 2048;
}
control Norland {
   if ( Saragosa.Schleswig != 0 ) {
      apply( Lubeck );
   }
}
field_list Pawtucket {
   Webbville.Moraine;
}
field_list_calculation Monahans {
    input {
        Pawtucket;
    }
    algorithm : identity;
    output_width : 51;
}
action_selector Weatherly {
    selection_key : Monahans;
    selection_mode : resilient;
}
action Floyd(BayPort) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, BayPort);
}
action_profile Kensal {
    actions {
        Floyd;
        Comptche;
    }
    size : 1024;
    dynamic_action_selection : Weatherly;
}
table Platea {
   reads {
      Crane.Millbrae : exact;
   }
   action_profile: Kensal;
   size : 1024;
}
control Belvue {
   if ((Crane.Millbrae & 0x2000) == 0x2000) {
      apply(Platea);
   }
}
action Bolckow() {
   modify_field(Crane.Basehor, Godley.Burrel);
   modify_field(Crane.Stratford, Godley.Hueytown);
   modify_field(Crane.Rives, Godley.Callao);
   modify_field(Crane.Arvada, Godley.Dizney);
   modify_field(Crane.Belfair, Godley.Standish);
   invalidate( ig_intr_md_for_tm.ucast_egress_port );
}
table Southam {
   actions {
      Bolckow;
   }
   default_action : Bolckow();
   size : 1;
}
control Oklahoma {
   apply( Southam );
}
action Cedar() {
   modify_field(Crane.Anahola, 1);
   modify_field(Crane.Branson, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Godley.Pinesdale);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Crane.Belfair);
}
action Trevorton() {
}
@pragma ways 1
table Annawan {
   reads {
      Crane.Basehor : exact;
      Crane.Stratford : exact;
   }
   actions {
      Cedar;
      Trevorton;
   }
   default_action : Trevorton;
   size : 1;
}
action Tenino() {
   modify_field(Crane.Kittredge, 1);
   modify_field(Crane.Willey, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Crane.Belfair, 4096);
}
table Florahome {
   actions {
      Tenino;
   }
   default_action : Tenino;
   size : 1;
}
action Raceland() {
   modify_field(Crane.Sylvester, 1);
   modify_field(Crane.Branson, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Crane.Belfair);
}
table Macksburg {
   actions {
      Raceland;
   }
   default_action : Raceland();
   size : 1;
}
action Nutria(Gaston) {
   modify_field(Crane.Jenera, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Gaston);
   modify_field(Crane.Millbrae, Gaston);
}
action Oreland(Berrydale) {
   modify_field(Crane.Kittredge, 1);
   modify_field(Crane.Gurdon, Berrydale);
}
action Rocheport() {
}
table Shubert {
   reads {
      Crane.Basehor : exact;
      Crane.Stratford : exact;
      Crane.Belfair : exact;
   }
   actions {
      Nutria;
      Oreland;
      Dauphin;
      Rocheport;
   }
   default_action : Rocheport();
   size : 65536;
}
control Skagway {
   if (Godley.WallLake == 0 and not valid(Shasta) ) {
      apply(Shubert) {
         Rocheport {
            apply(Annawan) {
               Trevorton {
                  if ((Crane.Basehor & 0x010000) == 0x010000) {
                     apply(Florahome);
                  } else {
                     apply(Macksburg);
                  }
               }
            }
         }
      }
   }
}
action Yaurel() {
   modify_field(Godley.Kranzburg, 1);
   Dauphin();
}
table Lepanto {
   actions {
      Yaurel;
   }
   default_action : Yaurel;
   size : 1;
}
control Ruffin {
   if (Godley.WallLake == 0) {
      if ((Crane.Wheeler==0) and (Godley.Seattle==0) and (Godley.Woodstown==0) and (Godley.Chloride==Crane.Millbrae)) {
         apply(Lepanto);
      } else {
         Belvue();
      }
   }
}
action BigPlain( Sterling ) {
   modify_field( Crane.Minturn, Sterling );
}
action Guion() {
   modify_field( Crane.Minturn, Crane.Belfair );
}
table Steprock {
   reads {
      eg_intr_md.egress_port : exact;
      Crane.Belfair : exact;
   }
   actions {
      BigPlain;
      Guion;
   }
   default_action : Guion;
   size : 4096;
}
control Brundage {
   apply( Steprock );
}
action Secaucus( Camargo, Seaforth ) {
   modify_field( Crane.Folcroft, Camargo );
   modify_field( Crane.Peosta, Seaforth );
}
table Markville {
   reads {
      Crane.Hammond : exact;
   }
   actions {
      Secaucus;
   }
   size : 8;
}
action Anaconda() {
   modify_field( Crane.Tinaja, 1 );
   modify_field( Crane.Hammond, 2 );
}
action Florida() {
   modify_field( Crane.Tinaja, 1 );
   modify_field( Crane.Hammond, 1 );
}
table Daniels {
   reads {
      Crane.Willamina : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Anaconda;
      Florida;
   }
   default_action : Comptche();
   size : 16;
}
action Wimbledon(KeyWest, Elcho, Emlenton, Slade) {
   modify_field( Crane.Juneau, KeyWest );
   modify_field( Crane.Thayne, Elcho );
   modify_field( Crane.Astatula, Emlenton );
   modify_field( Crane.Carnation, Slade );
}
table Edroy {
   reads {
        Crane.Whitetail : exact;
   }
   actions {
      Wimbledon;
   }
   size : 256;
}
action Rillton() {
   no_op();
}
action OldTown() {
   modify_field( Parkland.Brodnax, Owyhee[0].Robins );
   remove_header( Owyhee[0] );
}
table Burrton {
   actions {
      OldTown;
   }
   default_action : OldTown;
   size : 1;
}
action Cusick() {
   no_op();
}
action Kettering() {
   add_header( Owyhee[ 0 ] );
   modify_field( Owyhee[0].Robbs, Crane.Minturn );
   modify_field( Owyhee[0].Robins, Parkland.Brodnax );
   modify_field( Owyhee[0].Jeddo, Bigfork.Robbins );
   modify_field( Owyhee[0].Heuvelton, Bigfork.Naubinway );
   modify_field( Parkland.Brodnax, 0x8100 );
}
table Skyline {
   reads {
      Crane.Minturn : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Cusick;
      Kettering;
   }
   default_action : Kettering;
   size : 128;
}
action Cowles() {
   modify_field(Parkland.Valentine, Crane.Basehor);
   modify_field(Parkland.ElmPoint, Crane.Stratford);
   modify_field(Parkland.Langdon, Crane.Folcroft);
   modify_field(Parkland.Breda, Crane.Peosta);
}
action Lugert() {
   Cowles();
   add_to_field(Klukwan.Ridgeland, -1);
   modify_field(Klukwan.Monkstown, Bigfork.Machens);
}
action Hemet() {
   Cowles();
   add_to_field(Rehoboth.Sequim, -1);
   modify_field(Rehoboth.Sprout, Bigfork.Machens);
}
action Helen() {
   modify_field(Klukwan.Monkstown, Bigfork.Machens);
}
action Moquah() {
   modify_field(Rehoboth.Sprout, Bigfork.Machens);
}
action Albemarle() {
   Kettering();
}
action Ribera( Greenlawn, Tannehill, Deerwood, Senatobia ) {
   add_header( Servia );
   modify_field( Servia.Valentine, Greenlawn );
   modify_field( Servia.ElmPoint, Tannehill );
   modify_field( Servia.Langdon, Deerwood );
   modify_field( Servia.Breda, Senatobia );
   modify_field( Servia.Brodnax, 0xBF00 );
   add_header( Shasta );
   modify_field( Shasta.Colson, Crane.Juneau );
   modify_field( Shasta.RedBay, Crane.Thayne );
   modify_field( Shasta.Riley, Crane.Astatula );
   modify_field( Shasta.Croft, Crane.Carnation );
   modify_field( Shasta.Bridgton, Crane.Paxson );
}
action Shorter() {
   remove_header( Ironside );
   remove_header( Ravinia );
   remove_header( Moapa );
   copy_header( Parkland, Caspian );
   remove_header( Caspian );
   remove_header( Klukwan );
}
action Lithonia() {
   remove_header( Servia );
   remove_header( Shasta );
}
action Willits() {
   Shorter();
   modify_field(Sharptown.Monkstown, Bigfork.Machens);
}
action Surrency() {
   Shorter();
   modify_field(Dolliver.Sprout, Bigfork.Machens);
}
table Ladoga {
   reads {
      Crane.Petrey : exact;
      Crane.Hammond : exact;
      Crane.Wheeler : exact;
      Klukwan.valid : ternary;
      Rehoboth.valid : ternary;
      Sharptown.valid : ternary;
      Dolliver.valid : ternary;
   }
   actions {
      Lugert;
      Hemet;
      Helen;
      Moquah;
      Albemarle;
      Ribera;
      Lithonia;
      Shorter;
      Willits;
      Surrency;
   }
   size : 512;
}
control Spivey {
   apply( Burrton );
}
control RioPecos {
   apply( Skyline );
}
control Barwick {
   apply( Daniels ) {
      Comptche {
         apply( Markville );
      }
   }
   apply( Edroy );
   apply( Ladoga );
}
field_list Duncombe {
    Levittown.Ridgetop;
    Godley.Standish;
    Caspian.Langdon;
    Caspian.Breda;
    Klukwan.Wahoo;
}
action Dunnstown() {
   generate_digest(0, Duncombe);
}
table Placida {
   actions {
      Dunnstown;
   }
   default_action : Dunnstown;
   size : 1;
}
control Renfroe {
   if (Godley.Gobler == 1) {
      apply(Placida);
   }
}
action Brazos() {
   modify_field( Bigfork.Robbins, Udall.Honalo );
}
action Escatawpa() {
   modify_field( Bigfork.Robbins, Owyhee[0].Jeddo );
   modify_field( Godley.Bunker, Owyhee[0].Robins );
}
action Christmas() {
   modify_field( Bigfork.Machens, Udall.Nenana );
}
action Hapeville() {
   modify_field( Bigfork.Machens, Allgood.Caballo );
}
action McCleary() {
   modify_field( Bigfork.Machens, Alberta.Sawyer );
}
action Ontonagon( Sherrill, Maltby ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Sherrill );
   modify_field( ig_intr_md_for_tm.qid, Maltby );
}
table Folger {
   reads {
     Godley.Kinsley : exact;
   }
   actions {
     Brazos;
     Escatawpa;
   }
   size : 2;
}
table Olmstead {
   reads {
     Godley.Pachuta : exact;
     Godley.Menomonie : exact;
   }
   actions {
     Christmas;
     Hapeville;
     McCleary;
   }
   size : 3;
}
table Sublett {
   reads {
      Udall.Suamico : ternary;
      Udall.Honalo : ternary;
      Bigfork.Robbins : ternary;
      Bigfork.Machens : ternary;
      Bigfork.Pickering : ternary;
   }
   actions {
      Ontonagon;
   }
   size : 81;
}
action Palisades( Ramhurst, Brinkley ) {
   bit_or( Bigfork.Riverbank, Bigfork.Riverbank, Ramhurst );
   bit_or( Bigfork.Excel, Bigfork.Excel, Brinkley );
}
table Macdona {
   actions {
      Palisades;
   }
   default_action : Palisades(0, 0);
   size : 1;
}
action Corvallis( Aylmer ) {
   modify_field( Bigfork.Machens, Aylmer );
}
action Parmalee( Taopi ) {
   modify_field( Bigfork.Robbins, Taopi );
}
action Clearmont( Raynham, Scarville ) {
   modify_field( Bigfork.Robbins, Raynham );
   modify_field( Bigfork.Machens, Scarville );
}
table Woolwine {
   reads {
      Udall.Suamico : exact;
      Bigfork.Riverbank : exact;
      Bigfork.Excel : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Corvallis;
      Parmalee;
      Clearmont;
   }
   size : 512;
}
control Mosinee {
   apply( Folger );
   apply( Olmstead );
}
control Hartville {
   apply( Sublett );
}
control Bouton {
   apply( Macdona );
   apply( Woolwine );
}
action Delcambre( Elkins ) {
   modify_field( Bigfork.Ingleside, Elkins );
}
action Kenbridge( Amazonia, Harriet ) {
   Delcambre( Amazonia );
   modify_field( ig_intr_md_for_tm.qid, Harriet );
}
table Bethania {
   reads {
      Crane.Midas : ternary;
      ig_intr_md_for_tm.copy_to_cpu : ternary;
      Crane.Paxson : ternary;
      Godley.Pachuta : ternary;
      Godley.Menomonie : ternary;
      Godley.Bunker : ternary;
      Godley.Cedaredge : ternary;
      Godley.Hospers : ternary;
      Crane.Wheeler : ternary;
      Moapa.Micco : ternary;
      Moapa.Longhurst : ternary;
   }
   actions {
      Delcambre;
      Kenbridge;
   }
   size : 512;
}
meter Irondale {
   type : packets;
   static : Sespe;
   instance_count : 2304;
}
action Chaffey(Higbee) {
   execute_meter( Irondale, Higbee, ig_intr_md_for_tm.packet_color );
}
table Sespe {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Bigfork.Ingleside : exact;
   }
   actions {
      Chaffey;
   }
   size : 2304;
}
counter Tusayan {
   type : packets;
   instance_count : 32;
   min_width : 128;
}
action Accord() {
   count( Tusayan, Bigfork.Ingleside );
}
table Wells {
   actions {
     Accord;
   }
   default_action : Accord;
   size : 1;
}
control Cypress {
    if ( (
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x1 ) == 0 ) ) and ( Crane.Midas == 1 ) ) or
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x2 ) == 0 ) ) and ( ig_intr_md_for_tm.copy_to_cpu == 1 ) )
       ) ) {
      apply( Sespe );
      apply( Wells );
   }
}
action Brainard( Gully ) {
   modify_field( Crane.Willamina, 0 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Gully );
   modify_field( Crane.Whitetail, ig_intr_md.ingress_port );
}
action Junior( Pettigrew ) {
   modify_field( Crane.Willamina, 1 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Pettigrew );
   modify_field( Crane.Whitetail, ig_intr_md.ingress_port );
}
action Bosler() {
   modify_field( Crane.Willamina, 0 );
}
action LaPryor() {
   modify_field( Crane.Willamina, 1 );
   modify_field( Crane.Whitetail, ig_intr_md.ingress_port );
}
@pragma ternary 1
table Kaaawa {
   reads {
      Crane.Midas : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      Fajardo.RockyGap : exact;
      Udall.Groesbeck : ternary;
      Crane.Paxson : ternary;
   }
   actions {
      Brainard;
      Junior;
      Bosler;
      LaPryor;
   }
   size : 512;
}
control Sardinia {
   apply( Kaaawa );
}
counter Caplis {
   type : packets_and_bytes;
   instance_count : 1024;
   min_width : 128;
}
action Placedo( Melvina ) {
   count( Caplis, Melvina );
}
table Hanks {
   reads {
      eg_intr_md.egress_port mask 0x7f: exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }
   actions {
     Placedo;
   }
   size : 1024;
}
control Franklin {
   apply( Hanks );
}
action Oakford()
{
   Dauphin();
}
action Solomon()
{
   modify_field(Crane.Petrey, 2);
   bit_or(Crane.Millbrae, 0x2000, Shasta.Croft);
}
action Nellie( Waring ) {
   modify_field(Crane.Petrey, 2);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Waring);
   modify_field(Crane.Millbrae, Waring);
}
table Kennebec {
   reads {
      Shasta.Colson : exact;
      Shasta.RedBay : exact;
      Shasta.Riley : exact;
      Shasta.Croft : exact;
   }
   actions {
      Solomon;
      Nellie;
      Oakford;
   }
   default_action : Oakford();
   size : 256;
}
control Thatcher {
   apply( Kennebec );
}
action Ovilla( Elihu, FlatRock, Lansdowne, Tchula ) {
   modify_field( Yorkshire.Powelton, Elihu );
   modify_field( Saxis.Pease, Lansdowne );
   modify_field( Saxis.Moneta, FlatRock );
   modify_field( Saxis.SanRemo, Tchula );
}
table Lindsay {
   reads {
     Allgood.Wayne : exact;
     Godley.Swedeborg : exact;
   }
   actions {
      Ovilla;
   }
  size : 16384;
}
action Clementon(ElkFalls, Ruston, Strevell) {
   modify_field( Saxis.Moneta, ElkFalls );
   modify_field( Saxis.Pease, Ruston );
   modify_field( Saxis.SanRemo, Strevell );
}
table Santos {
   reads {
     Allgood.Lordstown : exact;
     Yorkshire.Powelton : exact;
   }
   actions {
      Clementon;
   }
   size : 16384;
}
action Talbotton( Edinburg, Caulfield, Barney ) {
   modify_field( Cricket.Robinette, Edinburg );
   modify_field( Cricket.Bonsall, Caulfield );
   modify_field( Cricket.Rolla, Barney );
}
table Pinole {
   reads {
     Crane.Basehor : exact;
     Crane.Stratford : exact;
     Crane.Belfair : exact;
   }
   actions {
      Talbotton;
   }
   size : 16384;
}
action Laurelton() {
   modify_field( Crane.Branson, 1 );
}
action Tidewater( Hollyhill, Madison ) {
   Laurelton();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Saxis.Moneta );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Hollyhill, Saxis.SanRemo );
   bit_or( Bigfork.Ingleside, Bigfork.Ingleside, Madison );
}
action Ephesus( ArchCape, WestCity ) {
   Laurelton();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Cricket.Robinette );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, ArchCape, Cricket.Rolla );
   bit_or( Bigfork.Ingleside, Bigfork.Ingleside, WestCity );
}
action Daysville( Segundo, Selvin ) {
   Laurelton();
   add( ig_intr_md_for_tm.mcast_grp_a, Crane.Belfair,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Segundo );
   bit_or( Bigfork.Ingleside, Bigfork.Ingleside, Selvin );
}
action Auvergne() {
   modify_field( Crane.Boerne, 1 );
}
table SeaCliff {
   reads {
     Saxis.Pease : ternary;
     Saxis.Moneta : ternary;
     Cricket.Robinette : ternary;
     Cricket.Bonsall : ternary;
     Godley.Cedaredge :ternary;
     Godley.Seattle:ternary;
   }
   actions {
      Tidewater;
      Ephesus;
      Daysville;
      Auvergne;
   }
   size : 32;
}
control Caldwell {
   if( Godley.WallLake == 0 and
       Fajardo.Leland == 1 and
       Godley.Corfu == 1 ) {
      apply( Lindsay );
   }
}
control RioLinda {
   if( Yorkshire.Powelton != 0 ) {
      apply( Santos );
   }
}
control Skyway {
   if( Godley.WallLake == 0 and Godley.Seattle==1 ) {
      apply( Pinole );
   }
}
action Westtown(Gastonia) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Webbville.Moraine );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Gastonia );
}
table Dorris {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Westtown;
    }
    size : 512;
}
control Exell {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Dorris);
   }
}
action Copemish( Calcium, Callands ) {
   modify_field( Crane.Belfair, Calcium );
   modify_field( Crane.Wheeler, Callands );
}
action Chaumont() {
   drop();
}
table Palmer {
   reads {
     eg_intr_md.egress_rid: exact;
   }
   actions {
      Copemish;
   }
   default_action: Chaumont;
   size : 57344;
}
control Amasa {
   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Palmer);
   }
}
counter Palmdale {
   type : packets;
   direct: Wakenda;
   min_width: 63;
}
@pragma stage 11
table Wakenda {
   reads {
     Ellinger.Ashtola mask 0x7fff : exact;
   }
   actions {
      Comptche;
   }
   default_action: Comptche();
   size : 32768;
}
action Cutler() {
   modify_field( Ankeny.Lemont, Godley.Cedaredge );
   modify_field( Ankeny.Yorklyn, Allgood.Caballo );
   modify_field( Ankeny.Fernway, Godley.Hospers );
   modify_field( Ankeny.Gomez, Godley.Tennessee );
   modify_field( Ankeny.SomesBar, Godley.Calabasas );
}
action Waipahu() {
   modify_field( Ankeny.Lemont, Godley.Cedaredge );
   modify_field( Ankeny.Yorklyn, Alberta.Sawyer );
   modify_field( Ankeny.Fernway, Godley.Hospers );
   modify_field( Ankeny.Gomez, Godley.Tennessee );
   modify_field( Ankeny.SomesBar, Godley.Calabasas );
}
action Weathers( Okaton ) {
   Cutler();
   modify_field( Ankeny.Harshaw, Okaton );
}
action Turney( Needles ) {
   Waipahu();
   modify_field( Ankeny.Harshaw, Needles );
}
table Golden {
   reads {
     Allgood.Lordstown : ternary;
   }
   actions {
      Weathers;
   }
   default_action : Cutler;
  size : 2048;
}
table Frewsburg {
   reads {
     Alberta.Scanlon : ternary;
   }
   actions {
      Turney;
   }
   default_action : Waipahu;
   size : 1024;
}
action Cargray( Absarokee ) {
   modify_field( Ankeny.Prosser, Absarokee );
}
table Converse {
   reads {
     Allgood.Wayne : ternary;
   }
   actions {
      Cargray;
   }
   size : 512;
}
table Bradner {
   reads {
     Alberta.Darden : ternary;
   }
   actions {
      Cargray;
   }
   size : 512;
}
action Flaherty( Pringle ) {
   modify_field( Ankeny.Cowden, Pringle );
}
table Patsville {
   reads {
     Godley.Eolia : ternary;
   }
   actions {
      Flaherty;
   }
   size : 512;
}
action Brimley( Dasher ) {
   modify_field( Ankeny.DeBeque, Dasher );
}
table Lathrop {
   reads {
     Godley.Northome : ternary;
   }
   actions {
      Brimley;
   }
   size : 512;
}
action Horns( Lucile ) {
   modify_field( Ankeny.LaFayette, Lucile );
}
action Rippon( FortHunt ) {
   modify_field( Ankeny.LaFayette, FortHunt );
}
table Veneta {
   reads {
     Godley.Pachuta : exact;
     Godley.Menomonie : exact;
     Godley.Virginia : exact;
     Godley.Swedeborg : exact;
   }
   actions {
      Horns;
      Comptche;
   }
   default_action : Comptche();
   size : 4096;
}
table Halbur {
   reads {
     Godley.Pachuta : exact;
     Godley.Menomonie : exact;
     Godley.Virginia : exact;
     Udall.Floris : exact;
   }
   actions {
      Rippon;
   }
   size : 512;
}
control Poteet {
   if( Godley.Pachuta == 1 ) {
      apply( Golden );
      apply( Converse );
   } else if( Godley.Menomonie == 1 ) {
      apply( Frewsburg );
      apply( Bradner );
   }
   if( ( Godley.Slocum != 0 and Godley.Walnut == 1 ) or
       ( Godley.Slocum == 0 and Moapa.valid == 1 ) ) {
      apply( Patsville );
      if( Godley.Cedaredge != 1 ){
         apply( Lathrop );
      }
   }
   apply( Veneta ) {
      Comptche {
         apply( Halbur );
      }
   }
}
action Grassy() {
}
action Seagate() {
}
action Purley() {
   drop();
}
action Gilman() {
   drop();
}
table CoosBay {
   reads {
     Ellinger.Ashtola mask 0x00018000 : ternary;
   }
   actions {
      Grassy;
      Seagate;
      Purley;
      Gilman;
   }
   size : 16;
}
control Dougherty {
   apply( Wakenda );
   apply( CoosBay );
}
   metadata Selawik Ellinger;
   action CatCreek( Uhland ) {
          max( Ellinger.Ashtola, Ellinger.Ashtola, Uhland );
   }
@pragma ways 1
table Annandale {
   reads {
      Ankeny.LaFayette : exact;
      Ankeny.Harshaw : exact;
      Ankeny.Prosser : exact;
      Ankeny.Cowden : exact;
      Ankeny.DeBeque : exact;
      Ankeny.Lemont : exact;
      Ankeny.Yorklyn : exact;
      Ankeny.Fernway : exact;
      Ankeny.Gomez : exact;
      Godley.Calabasas : exact;
   }
   actions {
      CatCreek;
   }
   size : 4096;
}
control Pecos {
   apply( Annandale );
}
table ElPortal {
   reads {
      Ankeny.LaFayette : exact;
      Ankeny.Harshaw : ternary;
      Ankeny.Prosser : ternary;
      Ankeny.Cowden : ternary;
      Ankeny.DeBeque : ternary;
      Ankeny.Lemont : ternary;
      Ankeny.Yorklyn : ternary;
      Ankeny.Fernway : ternary;
      Ankeny.Gomez : ternary;
      Godley.Calabasas : ternary;
   }
   actions {
      CatCreek;
   }
   size : 512;
}
control Lynch {
   apply( ElPortal );
}
@pragma pa_no_init ingress Cascade.Harshaw
@pragma pa_no_init ingress Cascade.Prosser
@pragma pa_no_init ingress Cascade.Cowden
@pragma pa_no_init ingress Cascade.DeBeque
@pragma pa_no_init ingress Cascade.Lemont
@pragma pa_no_init ingress Cascade.Yorklyn
@pragma pa_no_init ingress Cascade.Fernway
@pragma pa_no_init ingress Cascade.Gomez
@pragma pa_no_init ingress Cascade.SomesBar
@pragma pa_do_not_bridge egress Cascade.Harshaw
@pragma pa_do_not_bridge egress Cascade.Prosser
@pragma pa_do_not_bridge egress Cascade.Cowden
@pragma pa_do_not_bridge egress Cascade.DeBeque
@pragma pa_do_not_bridge egress Cascade.Lemont
@pragma pa_do_not_bridge egress Cascade.Yorklyn
@pragma pa_do_not_bridge egress Cascade.Fernway
@pragma pa_do_not_bridge egress Cascade.Gomez
@pragma pa_do_not_bridge egress Cascade.SomesBar
metadata Devola Cascade;
@pragma ways 1
table Davie {
   reads {
      Ankeny.LaFayette : exact;
      Cascade.Harshaw : exact;
      Cascade.Prosser : exact;
      Cascade.Cowden : exact;
      Cascade.DeBeque : exact;
      Cascade.Lemont : exact;
      Cascade.Yorklyn : exact;
      Cascade.Fernway : exact;
      Cascade.Gomez : exact;
      Cascade.SomesBar : exact;
   }
   actions {
      CatCreek;
   }
   size : 4096;
}
action Randall( DeSmet, Ballinger, Miller, Catawba, Tascosa, Homeworth, Comobabi, Talco, RioHondo ) {
   bit_and( Cascade.Harshaw, Ankeny.Harshaw, DeSmet );
   bit_and( Cascade.Prosser, Ankeny.Prosser, Ballinger );
   bit_and( Cascade.Cowden, Ankeny.Cowden, Miller );
   bit_and( Cascade.DeBeque, Ankeny.DeBeque, Catawba );
   bit_and( Cascade.Lemont, Ankeny.Lemont, Tascosa );
   bit_and( Cascade.Yorklyn, Ankeny.Yorklyn, Homeworth );
   bit_and( Cascade.Fernway, Ankeny.Fernway, Comobabi );
   bit_and( Cascade.Gomez, Ankeny.Gomez, Talco );
   bit_and( Cascade.SomesBar, Ankeny.SomesBar, RioHondo );
}
table Hansell {
   reads {
      Ankeny.LaFayette : exact;
   }
   actions {
      Randall;
   }
   default_action : Randall(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Grants {
   apply( Hansell );
}
control Cropper {
   apply( Davie );
}
table Onamia {
   reads {
      Ankeny.LaFayette : exact;
      Ankeny.Harshaw : ternary;
      Ankeny.Prosser : ternary;
      Ankeny.Cowden : ternary;
      Ankeny.DeBeque : ternary;
      Ankeny.Lemont : ternary;
      Ankeny.Yorklyn : ternary;
      Ankeny.Fernway : ternary;
      Ankeny.Gomez : ternary;
      Godley.Calabasas : ternary;
   }
   actions {
      CatCreek;
   }
   size : 512;
}
control Waldo {
   apply( Onamia );
}
@pragma ways 1
table Turkey {
   reads {
      Ankeny.LaFayette : exact;
      Cascade.Harshaw : exact;
      Cascade.Prosser : exact;
      Cascade.Cowden : exact;
      Cascade.DeBeque : exact;
      Cascade.Lemont : exact;
      Cascade.Yorklyn : exact;
      Cascade.Fernway : exact;
      Cascade.Gomez : exact;
      Cascade.SomesBar : exact;
   }
   actions {
      CatCreek;
   }
   size : 4096;
}
action Horatio( Celada, Terlingua, Kaupo, Belmond, Milan, Walland, McKenna, DeGraff, Atwater ) {
   bit_and( Cascade.Harshaw, Ankeny.Harshaw, Celada );
   bit_and( Cascade.Prosser, Ankeny.Prosser, Terlingua );
   bit_and( Cascade.Cowden, Ankeny.Cowden, Kaupo );
   bit_and( Cascade.DeBeque, Ankeny.DeBeque, Belmond );
   bit_and( Cascade.Lemont, Ankeny.Lemont, Milan );
   bit_and( Cascade.Yorklyn, Ankeny.Yorklyn, Walland );
   bit_and( Cascade.Fernway, Ankeny.Fernway, McKenna );
   bit_and( Cascade.Gomez, Ankeny.Gomez, DeGraff );
   bit_and( Cascade.SomesBar, Ankeny.SomesBar, Atwater );
}
table Lutsen {
   reads {
      Ankeny.LaFayette : exact;
   }
   actions {
      Horatio;
   }
   default_action : Horatio(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Fiskdale {
   apply( Lutsen );
}
control Loogootee {
   apply( Turkey );
}
table Kirwin {
   reads {
      Ankeny.LaFayette : exact;
      Ankeny.Harshaw : ternary;
      Ankeny.Prosser : ternary;
      Ankeny.Cowden : ternary;
      Ankeny.DeBeque : ternary;
      Ankeny.Lemont : ternary;
      Ankeny.Yorklyn : ternary;
      Ankeny.Fernway : ternary;
      Ankeny.Gomez : ternary;
      Godley.Calabasas : ternary;
   }
   actions {
      CatCreek;
   }
   size : 512;
}
control Waitsburg {
   apply( Kirwin );
}
@pragma ways 1
table Monsey {
   reads {
      Ankeny.LaFayette : exact;
      Cascade.Harshaw : exact;
      Cascade.Prosser : exact;
      Cascade.Cowden : exact;
      Cascade.DeBeque : exact;
      Cascade.Lemont : exact;
      Cascade.Yorklyn : exact;
      Cascade.Fernway : exact;
      Cascade.Gomez : exact;
      Cascade.SomesBar : exact;
   }
   actions {
      CatCreek;
   }
   size : 4096;
}
action CeeVee( Barclay, Fairfield, Reager, Olive, McCaskill, Dilia, Puyallup, Grampian, Davisboro ) {
   bit_and( Cascade.Harshaw, Ankeny.Harshaw, Barclay );
   bit_and( Cascade.Prosser, Ankeny.Prosser, Fairfield );
   bit_and( Cascade.Cowden, Ankeny.Cowden, Reager );
   bit_and( Cascade.DeBeque, Ankeny.DeBeque, Olive );
   bit_and( Cascade.Lemont, Ankeny.Lemont, McCaskill );
   bit_and( Cascade.Yorklyn, Ankeny.Yorklyn, Dilia );
   bit_and( Cascade.Fernway, Ankeny.Fernway, Puyallup );
   bit_and( Cascade.Gomez, Ankeny.Gomez, Grampian );
   bit_and( Cascade.SomesBar, Ankeny.SomesBar, Davisboro );
}
table Konnarock {
   reads {
      Ankeny.LaFayette : exact;
   }
   actions {
      CeeVee;
   }
   default_action : CeeVee(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Rockville {
   apply( Konnarock );
}
control Trilby {
   apply( Monsey );
}
table ElmGrove {
   reads {
      Ankeny.LaFayette : exact;
      Ankeny.Harshaw : ternary;
      Ankeny.Prosser : ternary;
      Ankeny.Cowden : ternary;
      Ankeny.DeBeque : ternary;
      Ankeny.Lemont : ternary;
      Ankeny.Yorklyn : ternary;
      Ankeny.Fernway : ternary;
      Ankeny.Gomez : ternary;
      Godley.Calabasas : ternary;
   }
   actions {
      CatCreek;
   }
   size : 512;
}
control Everton {
   apply( ElmGrove );
}
@pragma ways 1
table Thalia {
   reads {
      Ankeny.LaFayette : exact;
      Cascade.Harshaw : exact;
      Cascade.Prosser : exact;
      Cascade.Cowden : exact;
      Cascade.DeBeque : exact;
      Cascade.Lemont : exact;
      Cascade.Yorklyn : exact;
      Cascade.Fernway : exact;
      Cascade.Gomez : exact;
      Cascade.SomesBar : exact;
   }
   actions {
      CatCreek;
   }
   size : 4096;
}
action Ludden( Nettleton, Minetto, WarEagle, Parchment, Lenapah, Wellford, Dryden, Donegal, Paxtonia ) {
   bit_and( Cascade.Harshaw, Ankeny.Harshaw, Nettleton );
   bit_and( Cascade.Prosser, Ankeny.Prosser, Minetto );
   bit_and( Cascade.Cowden, Ankeny.Cowden, WarEagle );
   bit_and( Cascade.DeBeque, Ankeny.DeBeque, Parchment );
   bit_and( Cascade.Lemont, Ankeny.Lemont, Lenapah );
   bit_and( Cascade.Yorklyn, Ankeny.Yorklyn, Wellford );
   bit_and( Cascade.Fernway, Ankeny.Fernway, Dryden );
   bit_and( Cascade.Gomez, Ankeny.Gomez, Donegal );
   bit_and( Cascade.SomesBar, Ankeny.SomesBar, Paxtonia );
}
table Stillmore {
   reads {
      Ankeny.LaFayette : exact;
   }
   actions {
      Ludden;
   }
   default_action : Ludden(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Belwood {
   apply( Stillmore );
}
control Puryear {
   apply( Thalia );
}
table Parrish {
   reads {
      Ankeny.LaFayette : exact;
      Ankeny.Harshaw : ternary;
      Ankeny.Prosser : ternary;
      Ankeny.Cowden : ternary;
      Ankeny.DeBeque : ternary;
      Ankeny.Lemont : ternary;
      Ankeny.Yorklyn : ternary;
      Ankeny.Fernway : ternary;
      Ankeny.Gomez : ternary;
      Godley.Calabasas : ternary;
   }
   actions {
      CatCreek;
   }
   size : 512;
}
control PaloAlto {
   apply( Parrish );
}
@pragma ways 1
table Ponder {
   reads {
      Ankeny.LaFayette : exact;
      Cascade.Harshaw : exact;
      Cascade.Prosser : exact;
      Cascade.Cowden : exact;
      Cascade.DeBeque : exact;
      Cascade.Lemont : exact;
      Cascade.Yorklyn : exact;
      Cascade.Fernway : exact;
      Cascade.Gomez : exact;
      Cascade.SomesBar : exact;
   }
   actions {
      CatCreek;
   }
   size : 4096;
}
action Lawai( Folkston, DuPont, Newland, Union, Donner, Mescalero, Alnwick, Mapleview, Pardee ) {
   bit_and( Cascade.Harshaw, Ankeny.Harshaw, Folkston );
   bit_and( Cascade.Prosser, Ankeny.Prosser, DuPont );
   bit_and( Cascade.Cowden, Ankeny.Cowden, Newland );
   bit_and( Cascade.DeBeque, Ankeny.DeBeque, Union );
   bit_and( Cascade.Lemont, Ankeny.Lemont, Donner );
   bit_and( Cascade.Yorklyn, Ankeny.Yorklyn, Mescalero );
   bit_and( Cascade.Fernway, Ankeny.Fernway, Alnwick );
   bit_and( Cascade.Gomez, Ankeny.Gomez, Mapleview );
   bit_and( Cascade.SomesBar, Ankeny.SomesBar, Pardee );
}
table Norfork {
   reads {
      Ankeny.LaFayette : exact;
   }
   actions {
      Lawai;
   }
   default_action : Lawai(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Rawlins {
   apply( Norfork );
}
control Doddridge {
   apply( Ponder );
}
table FourTown {
   reads {
      Ankeny.LaFayette : exact;
      Ankeny.Harshaw : ternary;
      Ankeny.Prosser : ternary;
      Ankeny.Cowden : ternary;
      Ankeny.DeBeque : ternary;
      Ankeny.Lemont : ternary;
      Ankeny.Yorklyn : ternary;
      Ankeny.Fernway : ternary;
      Ankeny.Gomez : ternary;
      Godley.Calabasas : ternary;
   }
   actions {
      CatCreek;
   }
   size : 512;
}
control Anita {
   apply( FourTown );
}
@pragma ways 1
table Kempton {
   reads {
      Ankeny.LaFayette : exact;
      Cascade.Harshaw : exact;
      Cascade.Prosser : exact;
      Cascade.Cowden : exact;
      Cascade.DeBeque : exact;
      Cascade.Lemont : exact;
      Cascade.Yorklyn : exact;
      Cascade.Fernway : exact;
      Cascade.Gomez : exact;
      Cascade.SomesBar : exact;
   }
   actions {
      CatCreek;
   }
   size : 4096;
}
action PineAire( Ranchito, DosPalos, Emmorton, Barnwell, Lafourche, Oakridge, Basalt, Jelloway, Wyanet ) {
   bit_and( Cascade.Harshaw, Ankeny.Harshaw, Ranchito );
   bit_and( Cascade.Prosser, Ankeny.Prosser, DosPalos );
   bit_and( Cascade.Cowden, Ankeny.Cowden, Emmorton );
   bit_and( Cascade.DeBeque, Ankeny.DeBeque, Barnwell );
   bit_and( Cascade.Lemont, Ankeny.Lemont, Lafourche );
   bit_and( Cascade.Yorklyn, Ankeny.Yorklyn, Oakridge );
   bit_and( Cascade.Fernway, Ankeny.Fernway, Basalt );
   bit_and( Cascade.Gomez, Ankeny.Gomez, Jelloway );
   bit_and( Cascade.SomesBar, Ankeny.SomesBar, Wyanet );
}
table Ganado {
   reads {
      Ankeny.LaFayette : exact;
   }
   actions {
      PineAire;
   }
   default_action : PineAire(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Paragould {
   apply( Ganado );
}
control Gotebo {
   apply( Kempton );
}
table Filley {
   reads {
      Ankeny.LaFayette : exact;
      Ankeny.Harshaw : ternary;
      Ankeny.Prosser : ternary;
      Ankeny.Cowden : ternary;
      Ankeny.DeBeque : ternary;
      Ankeny.Lemont : ternary;
      Ankeny.Yorklyn : ternary;
      Ankeny.Fernway : ternary;
      Ankeny.Gomez : ternary;
      Godley.Calabasas : ternary;
   }
   actions {
      CatCreek;
   }
   size : 512;
}
control Dunmore {
   apply( Filley );
}
@pragma ways 1
table GlenRock {
   reads {
      Ankeny.LaFayette : exact;
      Cascade.Harshaw : exact;
      Cascade.Prosser : exact;
      Cascade.Cowden : exact;
      Cascade.DeBeque : exact;
      Cascade.Lemont : exact;
      Cascade.Yorklyn : exact;
      Cascade.Fernway : exact;
      Cascade.Gomez : exact;
      Cascade.SomesBar : exact;
   }
   actions {
      CatCreek;
   }
   size : 4096;
}
action Sewaren( Bootjack, Dubbs, Arroyo, Ripon, MudButte, Tramway, Lamoni, Kahului, Mulhall ) {
   bit_and( Cascade.Harshaw, Ankeny.Harshaw, Bootjack );
   bit_and( Cascade.Prosser, Ankeny.Prosser, Dubbs );
   bit_and( Cascade.Cowden, Ankeny.Cowden, Arroyo );
   bit_and( Cascade.DeBeque, Ankeny.DeBeque, Ripon );
   bit_and( Cascade.Lemont, Ankeny.Lemont, MudButte );
   bit_and( Cascade.Yorklyn, Ankeny.Yorklyn, Tramway );
   bit_and( Cascade.Fernway, Ankeny.Fernway, Lamoni );
   bit_and( Cascade.Gomez, Ankeny.Gomez, Kahului );
   bit_and( Cascade.SomesBar, Ankeny.SomesBar, Mulhall );
}
table Canovanas {
   reads {
      Ankeny.LaFayette : exact;
   }
   actions {
      Sewaren;
   }
   default_action : Sewaren(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Euren {
   apply( Canovanas );
}
control Meridean {
   apply( GlenRock );
}
table Boyero {
   reads {
      Ankeny.LaFayette : exact;
      Ankeny.Harshaw : ternary;
      Ankeny.Prosser : ternary;
      Ankeny.Cowden : ternary;
      Ankeny.DeBeque : ternary;
      Ankeny.Lemont : ternary;
      Ankeny.Yorklyn : ternary;
      Ankeny.Fernway : ternary;
      Ankeny.Gomez : ternary;
      Godley.Calabasas : ternary;
   }
   actions {
      CatCreek;
   }
   size : 512;
}
control Pittsburg {
   apply( Boyero );
}
@pragma ways 1
table Hitterdal {
   reads {
      Ankeny.LaFayette : exact;
      Cascade.Harshaw : exact;
      Cascade.Prosser : exact;
      Cascade.Cowden : exact;
      Cascade.DeBeque : exact;
      Cascade.Lemont : exact;
      Cascade.Yorklyn : exact;
      Cascade.Fernway : exact;
      Cascade.Gomez : exact;
      Cascade.SomesBar : exact;
   }
   actions {
      CatCreek;
   }
   size : 4096;
}
action Bayport( Ringwood, Chatom, Trout, Cotter, Darco, Range, Canton, Pekin, Blairsden ) {
   bit_and( Cascade.Harshaw, Ankeny.Harshaw, Ringwood );
   bit_and( Cascade.Prosser, Ankeny.Prosser, Chatom );
   bit_and( Cascade.Cowden, Ankeny.Cowden, Trout );
   bit_and( Cascade.DeBeque, Ankeny.DeBeque, Cotter );
   bit_and( Cascade.Lemont, Ankeny.Lemont, Darco );
   bit_and( Cascade.Yorklyn, Ankeny.Yorklyn, Range );
   bit_and( Cascade.Fernway, Ankeny.Fernway, Canton );
   bit_and( Cascade.Gomez, Ankeny.Gomez, Pekin );
   bit_and( Cascade.SomesBar, Ankeny.SomesBar, Blairsden );
}
table Ilwaco {
   reads {
      Ankeny.LaFayette : exact;
   }
   actions {
      Bayport;
   }
   default_action : Bayport(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Talkeetna {
   apply( Ilwaco );
}
control Hobergs {
   apply( Hitterdal );
}
table Skyforest {
   reads {
      Ankeny.LaFayette : exact;
      Ankeny.Harshaw : ternary;
      Ankeny.Prosser : ternary;
      Ankeny.Cowden : ternary;
      Ankeny.DeBeque : ternary;
      Ankeny.Lemont : ternary;
      Ankeny.Yorklyn : ternary;
      Ankeny.Fernway : ternary;
      Ankeny.Gomez : ternary;
      Godley.Calabasas : ternary;
   }
   actions {
      CatCreek;
   }
   size : 512;
}
control LaneCity {
   apply( Skyforest );
}
@pragma ways 1
table Granbury {
   reads {
      Ankeny.LaFayette : exact;
      Cascade.Harshaw : exact;
      Cascade.Prosser : exact;
      Cascade.Cowden : exact;
      Cascade.DeBeque : exact;
      Cascade.Lemont : exact;
      Cascade.Yorklyn : exact;
      Cascade.Fernway : exact;
      Cascade.Gomez : exact;
      Cascade.SomesBar : exact;
   }
   actions {
      CatCreek;
   }
   size : 4096;
}
action LaHabra( Longview, Christina, Delmar, Stennett, Mendon, Norwood, Ignacio, LewisRun, Brawley ) {
   bit_and( Cascade.Harshaw, Ankeny.Harshaw, Longview );
   bit_and( Cascade.Prosser, Ankeny.Prosser, Christina );
   bit_and( Cascade.Cowden, Ankeny.Cowden, Delmar );
   bit_and( Cascade.DeBeque, Ankeny.DeBeque, Stennett );
   bit_and( Cascade.Lemont, Ankeny.Lemont, Mendon );
   bit_and( Cascade.Yorklyn, Ankeny.Yorklyn, Norwood );
   bit_and( Cascade.Fernway, Ankeny.Fernway, Ignacio );
   bit_and( Cascade.Gomez, Ankeny.Gomez, LewisRun );
   bit_and( Cascade.SomesBar, Ankeny.SomesBar, Brawley );
}
table Wesson {
   reads {
      Ankeny.LaFayette : exact;
   }
   actions {
      LaHabra;
   }
   default_action : LaHabra(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Wilbraham {
   apply( Wesson );
}
control Perrine {
   apply( Granbury );
}
table Jamesport {
   reads {
      Ankeny.LaFayette : exact;
      Ankeny.Harshaw : ternary;
      Ankeny.Prosser : ternary;
      Ankeny.Cowden : ternary;
      Ankeny.DeBeque : ternary;
      Ankeny.Lemont : ternary;
      Ankeny.Yorklyn : ternary;
      Ankeny.Fernway : ternary;
      Ankeny.Gomez : ternary;
      Godley.Calabasas : ternary;
   }
   actions {
      CatCreek;
   }
   size : 512;
}
control Tocito {
   apply( Jamesport );
}
@pragma ways 1
table Kupreanof {
   reads {
      Ankeny.LaFayette : exact;
      Cascade.Harshaw : exact;
      Cascade.Prosser : exact;
      Cascade.Cowden : exact;
      Cascade.DeBeque : exact;
      Cascade.Lemont : exact;
      Cascade.Yorklyn : exact;
      Cascade.Fernway : exact;
      Cascade.Gomez : exact;
      Cascade.SomesBar : exact;
   }
   actions {
      CatCreek;
   }
   size : 4096;
}
action Kaluaaha( Padonia, Storden, Minburn, Swanlake, Linganore, Chardon, LeCenter, Clovis, Power ) {
   bit_and( Cascade.Harshaw, Ankeny.Harshaw, Padonia );
   bit_and( Cascade.Prosser, Ankeny.Prosser, Storden );
   bit_and( Cascade.Cowden, Ankeny.Cowden, Minburn );
   bit_and( Cascade.DeBeque, Ankeny.DeBeque, Swanlake );
   bit_and( Cascade.Lemont, Ankeny.Lemont, Linganore );
   bit_and( Cascade.Yorklyn, Ankeny.Yorklyn, Chardon );
   bit_and( Cascade.Fernway, Ankeny.Fernway, LeCenter );
   bit_and( Cascade.Gomez, Ankeny.Gomez, Clovis );
   bit_and( Cascade.SomesBar, Ankeny.SomesBar, Power );
}
table Dobbins {
   reads {
      Ankeny.LaFayette : exact;
   }
   actions {
      Kaluaaha;
   }
   default_action : Kaluaaha(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Neshoba {
   apply( Dobbins );
}
control CleElum {
   apply( Kupreanof );
}
table Raeford {
   reads {
      Ankeny.LaFayette : exact;
      Ankeny.Harshaw : ternary;
      Ankeny.Prosser : ternary;
      Ankeny.Cowden : ternary;
      Ankeny.DeBeque : ternary;
      Ankeny.Lemont : ternary;
      Ankeny.Yorklyn : ternary;
      Ankeny.Fernway : ternary;
      Ankeny.Gomez : ternary;
      Godley.Calabasas : ternary;
   }
   actions {
      CatCreek;
   }
   size : 512;
}
control Merrill {
   apply( Raeford );
}
@pragma ways 1
table Bethune {
   reads {
      Ankeny.LaFayette : exact;
      Cascade.Harshaw : exact;
      Cascade.Prosser : exact;
      Cascade.Cowden : exact;
      Cascade.DeBeque : exact;
      Cascade.Lemont : exact;
      Cascade.Yorklyn : exact;
      Cascade.Fernway : exact;
      Cascade.Gomez : exact;
      Cascade.SomesBar : exact;
   }
   actions {
      CatCreek;
   }
   size : 4096;
}
action KingCity( Bevington, RockPort, Lisman, Miranda, Hoadly, Mineral, Sabina, Salus, DeKalb ) {
   bit_and( Cascade.Harshaw, Ankeny.Harshaw, Bevington );
   bit_and( Cascade.Prosser, Ankeny.Prosser, RockPort );
   bit_and( Cascade.Cowden, Ankeny.Cowden, Lisman );
   bit_and( Cascade.DeBeque, Ankeny.DeBeque, Miranda );
   bit_and( Cascade.Lemont, Ankeny.Lemont, Hoadly );
   bit_and( Cascade.Yorklyn, Ankeny.Yorklyn, Mineral );
   bit_and( Cascade.Fernway, Ankeny.Fernway, Sabina );
   bit_and( Cascade.Gomez, Ankeny.Gomez, Salus );
   bit_and( Cascade.SomesBar, Ankeny.SomesBar, DeKalb );
}
table Chatawa {
   reads {
      Ankeny.LaFayette : exact;
   }
   actions {
      KingCity;
   }
   default_action : KingCity(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Oneonta {
   apply( Chatawa );
}
control Chazy {
   apply( Bethune );
}
table Lyman {
   reads {
      Ankeny.LaFayette : exact;
      Ankeny.Harshaw : ternary;
      Ankeny.Prosser : ternary;
      Ankeny.Cowden : ternary;
      Ankeny.DeBeque : ternary;
      Ankeny.Lemont : ternary;
      Ankeny.Yorklyn : ternary;
      Ankeny.Fernway : ternary;
      Ankeny.Gomez : ternary;
      Godley.Calabasas : ternary;
   }
   actions {
      CatCreek;
   }
   size : 512;
}
control Sturgis {
   apply( Lyman );
}
@pragma ways 1
table BelAir {
   reads {
      Ankeny.LaFayette : exact;
      Cascade.Harshaw : exact;
      Cascade.Prosser : exact;
      Cascade.Cowden : exact;
      Cascade.DeBeque : exact;
      Cascade.Lemont : exact;
      Cascade.Yorklyn : exact;
      Cascade.Fernway : exact;
      Cascade.Gomez : exact;
      Cascade.SomesBar : exact;
   }
   actions {
      CatCreek;
   }
   size : 4096;
}
action Meservey( Stobo, Almont, Brinson, Grizzly, Gallinas, Beaverdam, Naches, Wapella, Houston ) {
   bit_and( Cascade.Harshaw, Ankeny.Harshaw, Stobo );
   bit_and( Cascade.Prosser, Ankeny.Prosser, Almont );
   bit_and( Cascade.Cowden, Ankeny.Cowden, Brinson );
   bit_and( Cascade.DeBeque, Ankeny.DeBeque, Grizzly );
   bit_and( Cascade.Lemont, Ankeny.Lemont, Gallinas );
   bit_and( Cascade.Yorklyn, Ankeny.Yorklyn, Beaverdam );
   bit_and( Cascade.Fernway, Ankeny.Fernway, Naches );
   bit_and( Cascade.Gomez, Ankeny.Gomez, Wapella );
   bit_and( Cascade.SomesBar, Ankeny.SomesBar, Houston );
}
table Louin {
   reads {
      Ankeny.LaFayette : exact;
   }
   actions {
      Meservey;
   }
   default_action : Meservey(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Paisley {
   apply( Louin );
}
control Normangee {
   apply( BelAir );
}
table Stockton {
   reads {
      Ankeny.LaFayette : exact;
      Ankeny.Harshaw : ternary;
      Ankeny.Prosser : ternary;
      Ankeny.Cowden : ternary;
      Ankeny.DeBeque : ternary;
      Ankeny.Lemont : ternary;
      Ankeny.Yorklyn : ternary;
      Ankeny.Fernway : ternary;
      Ankeny.Gomez : ternary;
      Godley.Calabasas : ternary;
   }
   actions {
      CatCreek;
   }
   size : 512;
}
control Francisco {
   apply( Stockton );
}
@pragma ways 1
table McDonough {
   reads {
      Ankeny.LaFayette : exact;
      Cascade.Harshaw : exact;
      Cascade.Prosser : exact;
      Cascade.Cowden : exact;
      Cascade.DeBeque : exact;
      Cascade.Lemont : exact;
      Cascade.Yorklyn : exact;
      Cascade.Fernway : exact;
      Cascade.Gomez : exact;
      Cascade.SomesBar : exact;
   }
   actions {
      CatCreek;
   }
   size : 4096;
}
action Brule( ElkPoint, Quealy, Wellton, Henry, Castine, Elmsford, Liberal, Oregon, RichBar ) {
   bit_and( Cascade.Harshaw, Ankeny.Harshaw, ElkPoint );
   bit_and( Cascade.Prosser, Ankeny.Prosser, Quealy );
   bit_and( Cascade.Cowden, Ankeny.Cowden, Wellton );
   bit_and( Cascade.DeBeque, Ankeny.DeBeque, Henry );
   bit_and( Cascade.Lemont, Ankeny.Lemont, Castine );
   bit_and( Cascade.Yorklyn, Ankeny.Yorklyn, Elmsford );
   bit_and( Cascade.Fernway, Ankeny.Fernway, Liberal );
   bit_and( Cascade.Gomez, Ankeny.Gomez, Oregon );
   bit_and( Cascade.SomesBar, Ankeny.SomesBar, RichBar );
}
table Wentworth {
   reads {
      Ankeny.LaFayette : exact;
   }
   actions {
      Brule;
   }
   default_action : Brule(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Powers {
   apply( Wentworth );
}
control Rampart {
   apply( McDonough );
}
table Gowanda {
   reads {
      Ankeny.LaFayette : exact;
      Ankeny.Harshaw : ternary;
      Ankeny.Prosser : ternary;
      Ankeny.Cowden : ternary;
      Ankeny.DeBeque : ternary;
      Ankeny.Lemont : ternary;
      Ankeny.Yorklyn : ternary;
      Ankeny.Fernway : ternary;
      Ankeny.Gomez : ternary;
      Godley.Calabasas : ternary;
   }
   actions {
      CatCreek;
   }
   size : 512;
}
control Jermyn {
   apply( Gowanda );
}
control ingress {
   Rosario();
   if( Udall.Lamona != 0 ) {
      Kalida();
   }
   Abraham();
   if( Udall.Lamona != 0 ) {
      Netarts();
      Westville();
   }
   Emden();
   Poteet();
   Chatmoss();
   Holden();
   Grants();
   if( Udall.Lamona != 0 ) {
      Wyandanch();
   }
   Cropper();
   Fiskdale();
   Loogootee();
   Rockville();
   if( Udall.Lamona != 0 ) {
      Lakehurst();
   }
   Maybee();
   Mosinee();
   Trilby();
   Belwood();
   if( Udall.Lamona != 0 ) {
      Norland();
   }
   Puryear();
   Rawlins();
   Oklahoma();
   Caldwell();
   if( Udall.Lamona != 0 ) {
      Spalding();
   }
   RioLinda();
   Renfroe();
   Doddridge();
   Smithland();
   if( Crane.Midas == 0 ) {
      if( valid( Shasta ) ) {
         Thatcher();
      } else {
         Skyway();
         Skagway();
      }
   }
   if( not valid( Shasta ) ) {
      Hartville();
   }
   if( Crane.Midas == 0 ) {
      Ruffin();
   }
   if ( Udall.Lamona != 0 ) {
      if( Crane.Midas == 0 and Godley.Seattle == 1) {
         apply( SeaCliff );
      } else {
         apply( Bethania );
      }
   }
   if( Udall.Lamona != 0 ) {
      Bouton();
   }
   Cypress();
   if( valid( Owyhee[0] ) ) {
      Spivey();
   }
   if( Crane.Midas == 0 ) {
      Exell();
   }
   Sardinia();
}
control egress {
   Paragould();
   Amasa();
   Gotebo();
   Euren();
   Brundage();
   Meridean();
   Barwick();
   if( ( Crane.Tinaja == 0 ) and ( Crane.Petrey != 2 ) ) {
      RioPecos();
   }
   Franklin();
   Dougherty();
}
