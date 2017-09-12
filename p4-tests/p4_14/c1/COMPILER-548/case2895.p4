// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 6072017







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>


#define NOT_GOOD


#ifndef WolfTrap
#define WolfTrap


header_type Segundo {
	fields {
		Livengood : 16;
		Kneeland : 16;
		Cashmere : 8;
		Mishawaka : 8;
		WestGate : 8;
		Rawson : 8;
		Carnegie : 1;
		Marcus : 1;
		Standard : 1;
		Maybeury : 1;
		Froid : 1;
		Freetown : 1;
	}
}

header_type Gravette {
	fields {
		Leland : 24;
		Newland : 24;
		Arvada : 24;
		Hitterdal : 24;
		Ipava : 16;
		Pardee : 16;
		Dixmont : 16;
		Bemis : 16;
		Cowden : 16;
		Kotzebue : 8;
		Nettleton : 8;
		Tulsa : 1;
		Woodsdale : 1;
		Dante : 12;
		Metzger : 2;
		Amonate : 1;
		Bammel : 1;
		Chugwater : 1;
		Exira : 1;
		Uniopolis : 1;
		Ballville : 1;
		Welch : 1;
		Ogunquit : 1;
		Hodges : 1;
		Washta : 1;
		Golden : 1;
		Colona : 1;
		Kekoskee : 1;
		Marbury : 1;
		Knierim : 1;
	}
}

header_type Tuscumbia {
	fields {
		Blackman : 24;
		Fernway : 24;
		Daphne : 24;
		Annetta : 24;
		Tingley : 24;
		Emida : 24;
		Verdigris : 24;
		Goosport : 24;
		Hackney : 16;
		Pilar : 16;
		Trenary : 16;
		Faith : 16;
		Pawtucket : 12;
		Shirley : 1;
		Siloam : 3;
		Northcote : 1;
		Funkley : 3;
		Tanner : 1;
		McDaniels : 1;
		Bethune : 1;
		Oakford : 1;
		Annawan : 1;
		LaneCity : 8;
		Ivanpah : 12;
		Captiva : 4;
		Loveland : 6;
		Trion : 10;
		NewAlbin : 9;
		Boistfort : 1;
		Brothers : 1;
		Couchwood : 1;
		Fosters : 1;
		Virgin : 1;
	}
}


header_type Chevak {
	fields {
		Wallace : 8;
		Tiburon : 1;
		Laton : 1;
		Covina : 1;
		Bowen : 1;
		Higley : 1;
	}
}

header_type Talent {
	fields {
		Burwell : 32;
		Gardena : 32;
		Heaton : 6;
		Ayden : 16;
	}
}

header_type Satolah {
	fields {
		Coconut : 128;
		Bladen : 128;
		Davant : 20;
		McGrady : 8;
		Salineno : 11;
		Locke : 6;
		Bovina : 13;
	}
}

header_type Huntoon {
	fields {
		Secaucus : 14;
		Lakota : 1;
		Kirkwood : 12;
		Ladelle : 1;
		Neuse : 1;
		Lovilia : 6;
		Topmost : 2;
		Switzer : 6;
		Cadott : 3;
	}
}

header_type Anvik {
	fields {
		Tolleson : 1;
		Mekoryuk : 1;
	}
}

header_type Endeavor {
	fields {
		Leoma : 8;
	}
}

header_type Nicodemus {
	fields {
		Cutler : 16;
		Minneota : 11;
	}
}

header_type ShadeGap {
	fields {
		Monohan : 32;
		Globe : 32;
		Westpoint : 32;
	}
}

header_type Duelm {
	fields {
		Berea : 32;
		Enderlin : 32;
	}
}

header_type Wondervu {
	fields {
		Wapinitia : 1;
		Hartville : 1;
		Wauneta : 1;
		Cistern : 3;
		Hermiston : 1;
		Lizella : 6;
		Coffman : 5;
	}
}

header_type Newkirk {
	fields {
		Raynham : 16;
	}
}

header_type Hohenwald {
	fields {
		Crary : 14;
		Winnebago : 1;
		Braxton : 1;
	}
}

header_type Engle {
	fields {
		Millsboro : 14;
		Westview : 1;
		Calumet : 1;
	}
}

#endif



#ifndef Chackbay
#define Chackbay


header_type Rocheport {
	fields {
		Placid : 6;
		Tahuya : 10;
		Fontana : 4;
		Elsmere : 12;
		Bethania : 12;
		Belfast : 2;
		Parnell : 2;
		WyeMills : 8;
		Seibert : 3;
		Southam : 5;
	}
}



header_type Hobergs {
	fields {
		Lanesboro : 24;
		ElRio : 24;
		Trimble : 24;
		Paulding : 24;
		Brashear : 16;
	}
}



header_type Wolverine {
	fields {
		Elvaston : 3;
		Leona : 1;
		Toxey : 12;
		Hercules : 16;
	}
}



header_type Robinette {
	fields {
		Dryden : 4;
		Talihina : 4;
		Klukwan : 6;
		Brimley : 2;
		Tramway : 16;
		Trilby : 16;
		Callands : 3;
		Valencia : 13;
		Beatrice : 8;
		Becida : 8;
		Tusculum : 16;
		Carlson : 32;
		Turkey : 32;
	}
}

header_type Toluca {
	fields {
		Farlin : 4;
		Finlayson : 6;
		Humeston : 2;
		Quitman : 20;
		Gobler : 16;
		ElkNeck : 8;
		Henderson : 8;
		Parkland : 128;
		Clermont : 128;
	}
}




header_type Minturn {
	fields {
		Lauada : 8;
		GlenRose : 8;
		Lewellen : 16;
	}
}

header_type Magasco {
	fields {
		Dockton : 16;
		Sontag : 16;
	}
}

header_type Talbotton {
	fields {
		Cathay : 32;
		Calverton : 32;
		Ocracoke : 4;
		Ahmeek : 4;
		Hitchland : 8;
		ElmGrove : 16;
		Lueders : 16;
		Hartman : 16;
	}
}

header_type Joseph {
	fields {
		Brinklow : 16;
		Florala : 16;
	}
}



header_type Flaxton {
	fields {
		Chitina : 16;
		Mynard : 16;
		Nipton : 8;
		Boxelder : 8;
		Alcalde : 16;
	}
}

header_type Hopeton {
	fields {
		Brumley : 48;
		Ohiowa : 32;
		Govan : 48;
		Chilson : 32;
	}
}



header_type Geistown {
	fields {
		Pearcy : 1;
		Boysen : 1;
		Calabash : 1;
		Dunmore : 1;
		Hartfield : 1;
		Accomac : 3;
		Decorah : 5;
		Council : 3;
		Heron : 16;
	}
}

header_type Neavitt {
	fields {
		Elsinore : 24;
		Plato : 8;
	}
}



header_type Potosi {
	fields {
		Murdock : 8;
		Ekron : 24;
		Baroda : 24;
		Wesson : 8;
	}
}

#endif



#ifndef Onycha
#define Onycha

#define Dixfield        0x8100
#define Pearland        0x0800
#define Castine        0x86dd
#define Level        0x9100
#define Candle        0x8847
#define Springlee         0x0806
#define Vandling        0x8035
#define CatCreek        0x88cc
#define Renfroe        0x8809
#define Sanchez      0xBF00

#define Fletcher              1
#define Hermleigh              2
#define Lakebay              4
#define Bowlus               6
#define Gladden               17
#define Vergennes                47

#define Jamesburg         0x501
#define Conda          0x506
#define Sherando          0x511
#define Rosario          0x52F


#define Joice                 4789



#define Barney               0
#define Ewing              1
#define Cherokee                2



#define Arroyo          0
#define Chaska          4095
#define Monida  4096
#define Ronneby  8191



#define DeerPark                      0
#define Boquillas                  0
#define Hickox                 1

header Hobergs Thayne;
header Hobergs Lyncourt;
header Wolverine Mondovi[ 2 ];



@pragma pa_fragment ingress Kasilof.Tusculum
@pragma pa_fragment egress Kasilof.Tusculum
header Robinette Kasilof;

@pragma pa_fragment ingress Sprout.Tusculum
@pragma pa_fragment egress Sprout.Tusculum
header Robinette Sprout;

header Toluca Heppner;
header Toluca Holliday;
header Magasco Alberta;
header Talbotton BlackOak;

header Joseph Comunas;
header Talbotton Corum;
header Joseph Varnell;
header Potosi Harney;
header Flaxton Krupp;
header Geistown Orosi;
header Rocheport Louin;
header Hobergs Teaneck;

parser start {
   return select(current(96, 16)) {
      Sanchez : Bolckow;
      default : Wabuska;
   }
}

parser Casnovia {
   extract( Louin );
   return Wabuska;
}

parser Bolckow {
   extract( Teaneck );
   return Casnovia;
}

parser Wabuska {
   extract( Thayne );
   return select( Thayne.Brashear ) {
      Dixfield : Penzance;
      Pearland : Rendon;
      Castine : Sherrill;
      Springlee  : Cartago;
      default        : ingress;
   }
}

parser Penzance {
   extract( Mondovi[0] );
   set_metadata(Loogootee.Froid, 1);
   return select( Mondovi[0].Hercules ) {
      Pearland : Rendon;
      Castine : Sherrill;
      Springlee  : Cartago;
      default : ingress;
   }
}

field_list Brookland {
    Kasilof.Dryden;
    Kasilof.Talihina;
    Kasilof.Klukwan;
    Kasilof.Brimley;
    Kasilof.Tramway;
    Kasilof.Trilby;
    Kasilof.Callands;
    Kasilof.Valencia;
    Kasilof.Beatrice;
    Kasilof.Becida;
    Kasilof.Carlson;
    Kasilof.Turkey;
}

field_list_calculation Spraberry {
    input {
        Brookland;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field Kasilof.Tusculum  {
    verify Spraberry;
    update Spraberry;
}

parser Rendon {
   extract( Kasilof );
   set_metadata(Loogootee.Cashmere, Kasilof.Becida);
   set_metadata(Loogootee.WestGate, Kasilof.Beatrice);
   set_metadata(Loogootee.Livengood, Kasilof.Tramway);
   set_metadata(Loogootee.Standard, 0);
   set_metadata(Loogootee.Carnegie, 1);
   return select(Kasilof.Valencia, Kasilof.Talihina, Kasilof.Becida) {
      Sherando : Abbyville;
      Conda : Hilbert;
      default : ingress;
   }
}

parser Sherrill {
   extract( Holliday );
   set_metadata(Loogootee.Cashmere, Holliday.ElkNeck);
   set_metadata(Loogootee.WestGate, Holliday.Henderson);
   set_metadata(Loogootee.Livengood, Holliday.Gobler);
   set_metadata(Loogootee.Standard, 1);
   set_metadata(Loogootee.Carnegie, 0);
   return select(Holliday.ElkNeck) {
      Sherando : Netcong;
      Conda : Hilbert;
      default : ingress;
   }
}

parser Cartago {
   extract( Krupp );
   set_metadata(Loogootee.Freetown, 1);
   return ingress;
}

parser Abbyville {
   extract(Alberta);
   extract(Comunas);
   return select(Alberta.Sontag) {
      Joice : Williams;
      default : ingress;
    }
}

parser Netcong {
   extract(Alberta);
   extract(Comunas);
   return ingress;
}

parser Hilbert {
   extract(Alberta);
   extract(BlackOak);
   return ingress;
}

parser Elyria {
   set_metadata(Miranda.Metzger, Cherokee);
   return Duncombe;
}

parser Perryton {
   set_metadata(Miranda.Metzger, Cherokee);
   return Elderon;
}

parser Miller {
   extract(Orosi);
   return select(Orosi.Pearcy, Orosi.Boysen, Orosi.Calabash, Orosi.Dunmore, Orosi.Hartfield,
             Orosi.Accomac, Orosi.Decorah, Orosi.Council, Orosi.Heron) {
      Pearland : Elyria;
      Castine : Perryton;
      default : ingress;
   }
}

parser Williams {
   extract(Harney);
   set_metadata(Miranda.Metzger, Ewing);
   return Machens;
}

field_list Simnasho {
    Sprout.Dryden;
    Sprout.Talihina;
    Sprout.Klukwan;
    Sprout.Brimley;
    Sprout.Tramway;
    Sprout.Trilby;
    Sprout.Callands;
    Sprout.Valencia;
    Sprout.Beatrice;
    Sprout.Becida;
    Sprout.Carlson;
    Sprout.Turkey;
}

field_list_calculation Parkville {
    input {
        Simnasho;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field Sprout.Tusculum  {
    verify Parkville;
    update Parkville;
}

parser Duncombe {
   extract( Sprout );
   set_metadata(Loogootee.Mishawaka, Sprout.Becida);
   set_metadata(Loogootee.Rawson, Sprout.Beatrice);
   set_metadata(Loogootee.Kneeland, Sprout.Tramway);
   set_metadata(Loogootee.Maybeury, 0);
   set_metadata(Loogootee.Marcus, 1);
   return ingress;
}

parser Elderon {
   extract( Heppner );
   set_metadata(Loogootee.Mishawaka, Heppner.ElkNeck);
   set_metadata(Loogootee.Rawson, Heppner.Henderson);
   set_metadata(Loogootee.Kneeland, Heppner.Gobler);
   set_metadata(Loogootee.Maybeury, 1);
   set_metadata(Loogootee.Marcus, 0);
   return ingress;
}

parser Machens {
   extract( Lyncourt );
   return select( Lyncourt.Brashear ) {
      Pearland: Duncombe;
      Castine: Elderon;
      default: ingress;
   }
}
#endif

metadata Gravette Miranda;

@pragma pa_no_init ingress Stanwood.Blackman
@pragma pa_no_init ingress Stanwood.Fernway
@pragma pa_no_init ingress Stanwood.Daphne
@pragma pa_no_init ingress Stanwood.Annetta
metadata Tuscumbia Stanwood;

metadata Huntoon ElkFalls;
metadata Segundo Loogootee;
metadata Talent Roxboro;
metadata Satolah Rockham;

#ifdef NOT_GOOD
@pragma pa_container_size ingress Biscay.Mekoryuk 32
#endif
metadata Anvik Biscay;
metadata Chevak Tuskahoma;
metadata Endeavor Kingsland;
metadata Nicodemus Sallisaw;
metadata Duelm DuckHill;
metadata ShadeGap Mesita;
metadata Wondervu Selawik;

metadata Newkirk Shivwits;
metadata Hohenwald Lumberton;
metadata Engle Ringwood;













#undef LewisRun
#undef Rattan
#undef Elimsport
#undef Choudrant
#undef CeeVee

#undef Trotwood

#undef Philip
#undef Elburn
#undef Kempner
#undef Skyforest
#undef Exeter
#undef Recluse
#undef Revere

#undef Cricket
#undef Ouachita
#undef Westhoff

#undef Lostwood
#undef Adona
#undef Kaplan
#undef Shelbiana
#undef Quarry
#undef NantyGlo
#undef Abraham
#undef Moline
#undef Northboro
#undef Bairoil
#undef Gamewell
#undef Fennimore
#undef Longville
#undef Patchogue
#undef Sturgis
#undef Smithland
#undef Madeira
#undef Hines
#undef Perkasie
#undef Petty
#undef Higgins

#undef Swansea
#undef McDougal
#undef Tinsman
#undef Sherack
#undef Latham
#undef Marie
#undef Readsboro
#undef Waubun
#undef Whigham
#undef Oshoto
#undef Junior
#undef Gregory
#undef Wauna
#undef Tappan
#undef Sunbury
#undef Kelso
#undef Nathalie
#undef Ardara
#undef Ragley
#undef Requa

#undef Ramapo
#undef Summit

#undef Asher

#undef SanPablo
#undef Armagh

#undef Mooreland
#undef Mystic
#undef Longmont
#undef Sharon
#undef Kathleen







#define Trotwood 288


#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define LewisRun

#define Rattan

#define Elimsport

#define Choudrant

#define CeeVee



#define Philip      65536
#define Elburn      65536
#define Kempner      4096
#define Skyforest 1024
#define Exeter 512
#define Recluse      512
#define Revere 4096


#define Cricket     1024
#define Ouachita    1024
#define Westhoff     256


#define Lostwood 512
#define Adona 65536
#define Kaplan 65536
#define Shelbiana 28672
#define Quarry   16384
#define NantyGlo 8192
#define Abraham         131072
#define Moline 65536
#define Northboro 1024
#define Bairoil 2048
#define Gamewell 16384
#define Fennimore 8192
#define Longville 65536

#define Patchogue 0x0000000000000000FFFFFFFFFFFFFFFF


#define Sturgis 0x000fffff
#define Hines 2

#define Smithland 0xFFFFFFFFFFFFFFFF0000000000000000

#define Madeira 0x000007FFFFFFFFFF0000000000000000
#define Perkasie  6
#define Higgins        2048
#define Petty       65536


#define Swansea 1024
#define McDougal 4096
#define Tinsman 4096
#define Sherack 4096
#define Latham 4096
#define Marie 1024
#define Readsboro 4096
#define Whigham 128
#define Oshoto 1
#define Junior  8


#define Gregory 512
#define Ramapo 512
#define Summit 256


#define Wauna 2
#define Tappan 3
#define Sunbury 81



#define Kelso 2304
#define Nathalie 2304
#define Ardara 512

#define Ragley 1
#define Requa 512



#define Asher 0


#define SanPablo    4096
#define Armagh    1024


#define Mooreland    16384
#define Mystic   16384
#define Longmont            16384

#define Sharon                    57344
#define Kathleen         511


#endif



#ifndef Edinburgh
#define Edinburgh

action Margie() {
   no_op();
}

action Columbia() {
   modify_field(Miranda.Exira, 1 );
   mark_for_drop();
}

action Brazil() {
   no_op();
}
#endif




#define Nursery         0
#define Elmsford        1


#define Rembrandt            0
#define Rocklake  1
#define Haley 2


#define Petrey              0
#define Falmouth             1
#define Capitola 2


















action Harshaw(RedBay, Danese, Hamel, Emden, Netarts, Edler,
                 Broadwell, Headland, Friday) {
    modify_field(ElkFalls.Secaucus, RedBay);
    modify_field(ElkFalls.Lakota, Danese);
    modify_field(ElkFalls.Kirkwood, Hamel);
    modify_field(ElkFalls.Ladelle, Emden);
    modify_field(ElkFalls.Neuse, Netarts);
    modify_field(ElkFalls.Lovilia, Edler);
    modify_field(ElkFalls.Topmost, Broadwell);
    modify_field(ElkFalls.Cadott, Headland);
    modify_field(ElkFalls.Switzer, Friday);
}

@pragma command_line --no-dead-code-elimination
table Raeford {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Harshaw;
    }
    size : Trotwood;
}

control Vinita {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Raeford);
    }
}





action Olene(Advance, Dunbar) {
   modify_field( Stanwood.Northcote, 1 );
   modify_field( Stanwood.LaneCity, Advance);
   modify_field( Miranda.Washta, 1 );
   modify_field( Selawik.Wauneta, Dunbar );
}

action Odenton() {
   modify_field( Miranda.Welch, 1 );
   modify_field( Miranda.Colona, 1 );
}

action Cisne() {
   modify_field( Miranda.Washta, 1 );
}

action White() {
   modify_field( Miranda.Washta, 1 );
   modify_field( Miranda.Kekoskee, 1 );
}

action Thomas() {
   modify_field( Miranda.Golden, 1 );
}

action Berne() {
   modify_field( Miranda.Colona, 1 );
}

counter Nellie {
   type : packets_and_bytes;
   direct : Pensaukee;
   min_width: 16;
}

table Pensaukee {
   reads {
      ElkFalls.Lovilia : exact;
      Thayne.Lanesboro : ternary;
      Thayne.ElRio : ternary;
   }

   actions {
      Olene;
      Odenton;
      Cisne;
      Thomas;
      Berne;
      White;
   }
   size : Skyforest;
}

action Milan() {
   modify_field( Miranda.Ogunquit, 1 );
}


table Jacobs {
   reads {
      Thayne.Trimble : ternary;
      Thayne.Paulding : ternary;
   }

   actions {
      Milan;
   }
   size : Exeter;
}


control Mogadore {
   apply( Pensaukee );
   apply( Jacobs );
}




action Camargo() {
   modify_field( Roxboro.Burwell, Sprout.Carlson );
   modify_field( Roxboro.Gardena, Sprout.Turkey );
   modify_field( Roxboro.Heaton, Sprout.Klukwan );
   modify_field( Rockham.Coconut, Heppner.Parkland );
   modify_field( Rockham.Bladen, Heppner.Clermont );
   modify_field( Rockham.Davant, Heppner.Quitman );
   modify_field( Rockham.Locke, Heppner.Finlayson );
   modify_field( Miranda.Leland, Lyncourt.Lanesboro );
   modify_field( Miranda.Newland, Lyncourt.ElRio );
   modify_field( Miranda.Arvada, Lyncourt.Trimble );
   modify_field( Miranda.Hitterdal, Lyncourt.Paulding );
   modify_field( Miranda.Ipava, Lyncourt.Brashear );
   modify_field( Miranda.Cowden, Loogootee.Kneeland );
   modify_field( Miranda.Kotzebue, Loogootee.Mishawaka );
   modify_field( Miranda.Nettleton, Loogootee.Rawson );
   modify_field( Miranda.Woodsdale, Loogootee.Marcus );
   modify_field( Miranda.Tulsa, Loogootee.Maybeury );
   modify_field( Miranda.Marbury, 0 );
   modify_field( Stanwood.Funkley, Falmouth );



   modify_field( ElkFalls.Topmost, 1 );
   modify_field( ElkFalls.Cadott, 0 );
   modify_field( ElkFalls.Switzer, 0 );
   modify_field( Selawik.Wapinitia, 1 );
   modify_field( Selawik.Hartville, 1 );
}

action Skime() {
   modify_field( Miranda.Metzger, Barney );
   modify_field( Roxboro.Burwell, Kasilof.Carlson );
   modify_field( Roxboro.Gardena, Kasilof.Turkey );
   modify_field( Roxboro.Heaton, Kasilof.Klukwan );
   modify_field( Rockham.Coconut, Holliday.Parkland );
   modify_field( Rockham.Bladen, Holliday.Clermont );
   modify_field( Rockham.Davant, Holliday.Quitman );
   modify_field( Rockham.Locke, Holliday.Finlayson );
   modify_field( Miranda.Leland, Thayne.Lanesboro );
   modify_field( Miranda.Newland, Thayne.ElRio );
   modify_field( Miranda.Arvada, Thayne.Trimble );
   modify_field( Miranda.Hitterdal, Thayne.Paulding );
   modify_field( Miranda.Ipava, Thayne.Brashear );
   modify_field( Miranda.Cowden, Loogootee.Livengood );
   modify_field( Miranda.Kotzebue, Loogootee.Cashmere );
   modify_field( Miranda.Nettleton, Loogootee.WestGate );
   modify_field( Miranda.Woodsdale, Loogootee.Carnegie );
   modify_field( Miranda.Tulsa, Loogootee.Standard );
   modify_field( Selawik.Hermiston, Mondovi[0].Leona );
   modify_field( Miranda.Marbury, Loogootee.Froid );
}

table Supai {
   reads {
      Thayne.Lanesboro : exact;
      Thayne.ElRio : exact;
      Kasilof.Turkey : exact;
      Miranda.Metzger : exact;
   }

   actions {
      Camargo;
      Skime;
   }

   default_action : Skime();
   size : Swansea;
}


action Sarepta() {
   modify_field( Miranda.Pardee, ElkFalls.Kirkwood );
   modify_field( Miranda.Dixmont, ElkFalls.Secaucus);
}

action Dowell( Norias ) {
   modify_field( Miranda.Pardee, Norias );
   modify_field( Miranda.Dixmont, ElkFalls.Secaucus);
}

action Palmer() {
   modify_field( Miranda.Pardee, Mondovi[0].Toxey );
   modify_field( Miranda.Dixmont, ElkFalls.Secaucus);
}

table Pittsboro {
   reads {
      ElkFalls.Secaucus : ternary;
      Mondovi[0] : valid;
      Mondovi[0].Toxey : ternary;
   }

   actions {
      Sarepta;
      Dowell;
      Palmer;
   }
   size : Sherack;
}

action Rolla( Triplett ) {
   modify_field( Miranda.Dixmont, Triplett );
}

action Silica() {

   modify_field( Miranda.Chugwater, 1 );
   modify_field( Kingsland.Leoma,
                 Hickox );
}

table Jenera {
   reads {
      Kasilof.Carlson : exact;
   }

   actions {
      Rolla;
      Silica;
   }
   default_action : Silica;
   size : Tinsman;
}

action Newtonia( Point, Bunavista, Mathias, Canfield, Hooker,
                        Darden, Francisco ) {
   modify_field( Miranda.Pardee, Point );
   modify_field( Miranda.Bemis, Point );
   modify_field( Miranda.Ballville, Francisco );
   Yreka(Bunavista, Mathias, Canfield, Hooker,
                        Darden );
}

action Islen() {
   modify_field( Miranda.Uniopolis, 1 );
}

table Paxico {
   reads {
      Harney.Baroda : exact;
   }

   actions {
      Newtonia;
      Islen;
   }
   size : McDougal;
}

action Yreka(Lapeer, Harriet, Goodrich, Cowan,
                        Needham ) {
   modify_field( Tuskahoma.Wallace, Lapeer );
   modify_field( Tuskahoma.Tiburon, Harriet );
   modify_field( Tuskahoma.Covina, Goodrich );
   modify_field( Tuskahoma.Laton, Cowan );
   modify_field( Tuskahoma.Bowen, Needham );
}

action Guion(Trail, Seattle, Bridgton, RockyGap,
                        Slayden ) {
   modify_field( Miranda.Bemis, ElkFalls.Kirkwood );
   modify_field( Miranda.Ballville, 1 );
   Yreka(Trail, Seattle, Bridgton, RockyGap,
                        Slayden );
}

action Tuttle(Huffman, Diomede, Grays, Leucadia,
                        Waupaca, Claypool ) {
   modify_field( Miranda.Bemis, Huffman );
   modify_field( Miranda.Ballville, 1 );
   Yreka(Diomede, Grays, Leucadia, Waupaca,
                        Claypool );
}

action Derita(Basic, Hatteras, Theta, Higgston,
                        Caborn ) {
   modify_field( Miranda.Bemis, Mondovi[0].Toxey );
   modify_field( Miranda.Ballville, 1 );
   Yreka(Basic, Hatteras, Theta, Higgston,
                        Caborn );
}

table Wyman {
   reads {
      ElkFalls.Kirkwood : exact;
   }


   actions {
      Margie;
      Guion;
   }

   size : Latham;
}

@pragma action_default_only Margie
table Micco {
   reads {
      ElkFalls.Secaucus : exact;
      Mondovi[0].Toxey : exact;
   }

   actions {
      Tuttle;
      Margie;
   }

   size : Marie;
}

table Westbrook {
   reads {
      Mondovi[0].Toxey : exact;
   }


   actions {
      Margie;
      Derita;
   }

   size : Readsboro;
}

control Hooks {
   apply( Supai ) {
         Camargo {
            apply( Jenera );
            apply( Paxico );
         }
         Skime {
            if ( not valid(Louin) and ElkFalls.Ladelle == 1 ) {
               apply( Pittsboro );
            }
            if ( valid( Mondovi[ 0 ] ) ) {

               apply( Micco ) {
                  Margie {

                     apply( Westbrook );
                  }
               }
            } else {

               apply( Wyman );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Denby {
    width  : 1;
    static : Paradise;
    instance_count : 262144;
}

register Aniak {
    width  : 1;
    static : Kenefic;
    instance_count : 262144;
}

blackbox stateful_alu Bogota {
    reg : Denby;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Biscay.Tolleson;
}

blackbox stateful_alu McIntosh {
    reg : Aniak;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Biscay.Mekoryuk;
}

field_list Gerster {
    ElkFalls.Lovilia;
    Mondovi[0].Toxey;
}

field_list_calculation Franktown {
    input { Gerster; }
    algorithm: identity;
    output_width: 18;
}

action Gannett() {
    Bogota.execute_stateful_alu_from_hash(Franktown);
}

action Dateland() {
    McIntosh.execute_stateful_alu_from_hash(Franktown);
}

table Paradise {
    actions {
      Gannett;
    }
    default_action : Gannett;
    size : 1;
}

table Kenefic {
    actions {
      Dateland;
    }
    default_action : Dateland;
    size : 1;
}
#endif

action Lynch(Lenox) {
    modify_field(Biscay.Mekoryuk, Lenox);
}

@pragma  use_hash_action 0
table Ambler {
    reads {
       ElkFalls.Lovilia : exact;
    }
    actions {
      Lynch;
    }
    size : 64;
}

action Hamburg() {
   modify_field( Miranda.Dante, ElkFalls.Kirkwood );
   modify_field( Miranda.Amonate, 0 );
}

table Hawthorne {
   actions {
      Hamburg;
   }
   size : 1;
}

action Bellamy() {
   modify_field( Miranda.Dante, Mondovi[0].Toxey );
   modify_field( Miranda.Amonate, 1 );
}

table Elwood {
   actions {
      Bellamy;
   }
   size : 1;
}

control Bienville {
   if ( valid( Mondovi[ 0 ] ) ) {
      apply( Elwood );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( ElkFalls.Neuse == 1 ) {
         apply( Paradise );
         apply( Kenefic );
      }
#endif
   } else {
      apply( Hawthorne );
      if( ElkFalls.Neuse == 1 ) {
         apply( Ambler );
      }
   }
}




field_list Gretna {
   Thayne.Lanesboro;
   Thayne.ElRio;
   Thayne.Trimble;
   Thayne.Paulding;
   Thayne.Brashear;
}

field_list Riner {

   Kasilof.Becida;
   Kasilof.Carlson;
   Kasilof.Turkey;
}

field_list Billett {
   Holliday.Parkland;
   Holliday.Clermont;
   Holliday.Quitman;
   Holliday.ElkNeck;
}

field_list Midville {
   Kasilof.Carlson;
   Kasilof.Turkey;
   Alberta.Dockton;
   Alberta.Sontag;
}





field_list_calculation Bagwell {
    input {
        Gretna;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Hiawassee {
    input {
        Riner;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Stirrat {
    input {
        Billett;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Carlsbad {
    input {
        Midville;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Wittman() {
    modify_field_with_hash_based_offset(Mesita.Monohan, 0,
                                        Bagwell, 4294967296);
}

action Sabana() {
    modify_field_with_hash_based_offset(Mesita.Globe, 0,
                                        Hiawassee, 4294967296);
}

action Tununak() {
    modify_field_with_hash_based_offset(Mesita.Globe, 0,
                                        Stirrat, 4294967296);
}

action Corinth() {
    modify_field_with_hash_based_offset(Mesita.Westpoint, 0,
                                        Carlsbad, 4294967296);
}

table Anguilla {
   actions {
      Wittman;
   }
   size: 1;
}

control Campbell {
   apply(Anguilla);
}

table Lebanon {
   actions {
      Sabana;
   }
   size: 1;
}

table Shabbona {
   actions {
      Tununak;
   }
   size: 1;
}

control Bronaugh {
   if ( valid( Kasilof ) ) {
      apply(Lebanon);
   } else {
      if ( valid( Holliday ) ) {
         apply(Shabbona);
      }
   }
}

table Kaolin {
   actions {
      Corinth;
   }
   size: 1;
}

control Sparkill {
   if ( valid( Comunas ) ) {
      apply(Kaolin);
   }
}



action Almont() {
    modify_field(DuckHill.Berea, Mesita.Monohan);
}

action Moclips() {
    modify_field(DuckHill.Berea, Mesita.Globe);
}

action Deerwood() {
    modify_field(DuckHill.Berea, Mesita.Westpoint);
}

@pragma action_default_only Margie
@pragma immediate 0
table Frewsburg {
   reads {
      Corum.valid : ternary;
      Varnell.valid : ternary;
      Sprout.valid : ternary;
      Heppner.valid : ternary;
      Lyncourt.valid : ternary;
      BlackOak.valid : ternary;
      Comunas.valid : ternary;
      Kasilof.valid : ternary;
      Holliday.valid : ternary;
      Thayne.valid : ternary;
   }
   actions {
      Almont;
      Moclips;
      Deerwood;
      Margie;
   }
   size: Westhoff;
}

action Excel() {
    modify_field(DuckHill.Enderlin, Mesita.Westpoint);
}

@pragma immediate 0
table Alzada {
   reads {
      Corum.valid : ternary;
      Varnell.valid : ternary;
      BlackOak.valid : ternary;
      Comunas.valid : ternary;
   }
   actions {
      Excel;
      Margie;
   }
   size: Perkasie;
}

control Hanks {
   apply(Alzada);
   apply(Frewsburg);
}



counter Waring {
   type : packets_and_bytes;
   direct : Monetta;
   min_width: 16;
}

table Monetta {
   reads {
      ElkFalls.Lovilia : exact;
      Biscay.Mekoryuk : ternary;
      Biscay.Tolleson : ternary;
      Miranda.Uniopolis : ternary;
      Miranda.Ogunquit : ternary;
      Miranda.Welch : ternary;
   }

   actions {
      Columbia;
      Margie;
   }
   default_action : Margie();
   size : Recluse;
}

table Jelloway {
   reads {
      Miranda.Arvada : exact;
      Miranda.Hitterdal : exact;
      Miranda.Pardee : exact;
   }

   actions {
      Columbia;
      Margie;
   }
   default_action : Margie();
   size : Kempner;
}

action CoosBay() {

   modify_field(Miranda.Bammel, 1 );
   modify_field(Kingsland.Leoma,
                Boquillas);
}







table Annandale {
   reads {
      Miranda.Arvada : exact;
      Miranda.Hitterdal : exact;
      Miranda.Pardee : exact;
      Miranda.Dixmont : exact;
   }

   actions {
      Brazil;
      CoosBay;
   }
   default_action : CoosBay();
   size : Elburn;
   support_timeout : true;
}

action Temple( Decherd ) {
   modify_field( Miranda.Knierim, Decherd );
}

table Hagewood {
   reads {
      Miranda.Pardee : exact;
   }

   actions {
      Temple;
      Margie;
   }

   default_action : Margie();
   size : Revere;
}

action Rockland() {
   modify_field( Tuskahoma.Higley, 1 );
}

table Newtok {
   reads {
      Miranda.Bemis : ternary;
      Miranda.Leland : exact;
      Miranda.Newland : exact;
   }
   actions {
      Rockland;
   }
   size: Lostwood;
}

control CapeFair {
   apply( Monetta ) {
      Margie {
         apply( Jelloway ) {
            Margie {



               if (ElkFalls.Lakota == 0 and Miranda.Chugwater == 0) {
                  apply( Annandale );
               }
               apply( Hagewood );
               apply(Newtok);
            }
         }
      }
   }
}

field_list Genola {
    Kingsland.Leoma;
    Miranda.Arvada;
    Miranda.Hitterdal;
    Miranda.Pardee;
    Miranda.Dixmont;
}

action McCartys() {
   generate_digest(DeerPark, Genola);
}

table Talco {
   actions {
      McCartys;
   }
   size : 1;
}

control Hilburn {
   if (Miranda.Bammel == 1) {
      apply( Talco );
   }
}



action Godley( Pettigrew, Antlers ) {
   modify_field( Rockham.Bovina, Pettigrew );
   modify_field( Sallisaw.Cutler, Antlers );
}

@pragma action_default_only Tontogany
table Dunnellon {
   reads {
      Tuskahoma.Wallace : exact;
      Rockham.Bladen mask Smithland : lpm;
   }
   actions {
      Godley;
      Tontogany;
   }
   size : Fennimore;
}

@pragma atcam_partition_index Rockham.Bovina
@pragma atcam_number_partitions Fennimore
table Hiland {
   reads {
      Rockham.Bovina : exact;
      Rockham.Bladen mask Madeira : lpm;
   }

   actions {
      Jones;
      Burgdorf;
      Margie;
   }
   default_action : Margie();
   size : Longville;
}

action FoxChase( Veteran, Nordland ) {
   modify_field( Rockham.Salineno, Veteran );
   modify_field( Sallisaw.Cutler, Nordland );
}

@pragma action_default_only Margie
table Ferrum {


   reads {
      Tuskahoma.Wallace : exact;
      Rockham.Bladen : lpm;
   }

   actions {
      FoxChase;
      Margie;
   }

   size : Bairoil;
}

@pragma atcam_partition_index Rockham.Salineno
@pragma atcam_number_partitions Bairoil
table Levasy {
   reads {
      Rockham.Salineno : exact;


      Rockham.Bladen mask Patchogue : lpm;
   }
   actions {
      Jones;
      Burgdorf;
      Margie;
   }

   default_action : Margie();
   size : Gamewell;
}

@pragma action_default_only Tontogany
@pragma idletime_precision 1
table Sarasota {

   reads {
      Tuskahoma.Wallace : exact;
      Roxboro.Gardena : lpm;
   }

   actions {
      Jones;
      Burgdorf;
      Tontogany;
   }

   size : Northboro;
   support_timeout : true;
}

action Gonzalez( Shoup, Chatfield ) {
   modify_field( Roxboro.Ayden, Shoup );
   modify_field( Sallisaw.Cutler, Chatfield );
}

@pragma action_default_only Margie
#ifdef PROFILE_DEFAULT
#ifndef PRAGMA_STAGE
@pragma stage 2 NantyGlo
@pragma stage 3
#endif
#endif
table Merkel {
   reads {
      Tuskahoma.Wallace : exact;
      Roxboro.Gardena : lpm;
   }

   actions {
      Gonzalez;
      Margie;
   }

   size : Quarry;
}

@pragma ways Hines
@pragma atcam_partition_index Roxboro.Ayden
@pragma atcam_number_partitions Quarry
table Gower {
   reads {
      Roxboro.Ayden : exact;
      Roxboro.Gardena mask Sturgis : lpm;
   }
   actions {
      Jones;
      Burgdorf;
      Margie;
   }
   default_action : Margie();
   size : Abraham;
}

action Jones( Sheldahl ) {
   modify_field( Sallisaw.Cutler, Sheldahl );
}

@pragma idletime_precision 1
table BullRun {
   reads {
      Tuskahoma.Wallace : exact;
      Roxboro.Gardena : exact;
   }

   actions {
      Jones;
      Burgdorf;
      Margie;
   }
   default_action : Margie();
   size : Adona;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
#ifdef PRAGMA_STAGE
@pragma stage 2 Shelbiana
@pragma stage 3
#endif
#endif
table Mackville {
   reads {
      Tuskahoma.Wallace : exact;
      Rockham.Bladen : exact;
   }

   actions {
      Jones;
      Burgdorf;
      Margie;
   }
   default_action : Margie();
   size : Kaplan;
   support_timeout : true;
}

action RoyalOak(Betterton, Friend, Loyalton) {
   modify_field(Stanwood.Hackney, Loyalton);
   modify_field(Stanwood.Blackman, Betterton);
   modify_field(Stanwood.Fernway, Friend);
   modify_field(Stanwood.Boistfort, 1);

   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}

action FarrWest() {
   Columbia();
}

action Hampton(Sudden) {
   modify_field(Stanwood.Northcote, 1);
   modify_field(Stanwood.LaneCity, Sudden);
}

action Tontogany(Occoquan) {
   modify_field( Stanwood.Northcote, 1 );
   modify_field( Stanwood.LaneCity, 9 );
}

table Bremond {
   reads {
      Sallisaw.Cutler : exact;
   }

   actions {
      RoyalOak;
      FarrWest;
      Hampton;
   }
   size : Moline;
}

action Allerton( Plush ) {
   modify_field(Stanwood.Northcote, 1);
   modify_field(Stanwood.LaneCity, Plush);
}

table Valmeyer {
   actions {
      Allerton;
   }
   default_action: Allerton;
   size : 1;
}

control Vining {
   if ( Miranda.Exira == 0 and Tuskahoma.Higley == 1 ) {
      if ( ( Tuskahoma.Tiburon == 1 ) and ( Miranda.Woodsdale == 1 ) ) {
         apply( BullRun ) {
            Margie {
               apply( Merkel ) {
                  Gonzalez {
                     apply( Gower );
                  }
                  Margie {
                     apply( Sarasota );
                  }
               }
            }
         }
      } else if ( ( Tuskahoma.Covina == 1 ) and ( Miranda.Tulsa == 1 ) ) {
         apply( Mackville ) {
            Margie {
               apply( Ferrum ) {
                  FoxChase {
                     apply( Levasy );
                  }
                  Margie {

                     apply( Dunnellon ) {
                        Godley {
                           apply( Hiland );
                        }
                     }
                  }
               }
            }
         }
      } else if( Miranda.Ballville == 1 ) {
         apply( Valmeyer );
      }
   }
}

control Armona {
   if( Sallisaw.Cutler != 0 ) {
      apply( Bremond );
   }
}

action Burgdorf( Excello ) {
   modify_field( Sallisaw.Minneota, Excello );
}

field_list Lilbert {
   DuckHill.Enderlin;
}

field_list_calculation Plateau {
    input {
        Lilbert;
    }
    algorithm : identity;
    output_width : 66;
}

action_selector Hayfield {
   selection_key : Plateau;
   selection_mode : resilient;
}

action_profile Skokomish {
   actions {
      Jones;
   }
   size : Petty;
   dynamic_action_selection : Hayfield;
}

@pragma selector_max_group_size 256
table Subiaco {
   reads {
      Sallisaw.Minneota : exact;
   }
   action_profile : Skokomish;
   size : Higgins;
}

control Silesia {
   if ( Sallisaw.Minneota != 0 ) {
      apply( Subiaco );
   }
}



field_list Lenoir {
   DuckHill.Berea;
}

field_list_calculation Calcasieu {
    input {
        Lenoir;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Brinson {
    selection_key : Calcasieu;
    selection_mode : resilient;
}

action Humacao(Wardville) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Wardville);
}

action_profile Wisdom {
    actions {
        Humacao;
        Margie;
    }
    size : Ouachita;
    dynamic_action_selection : Brinson;
}

table Glenshaw {
   reads {
      Stanwood.Trenary : exact;
   }
   action_profile: Wisdom;
   size : Cricket;
}

control Sewaren {
   if ((Stanwood.Trenary & 0x2000) == 0x2000) {
      apply(Glenshaw);
   }
}



action Wabasha() {
   modify_field(Stanwood.Blackman, Miranda.Leland);
   modify_field(Stanwood.Fernway, Miranda.Newland);
   modify_field(Stanwood.Daphne, Miranda.Arvada);
   modify_field(Stanwood.Annetta, Miranda.Hitterdal);
   modify_field(Stanwood.Hackney, Miranda.Pardee);
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
   invalidate( ig_intr_md_for_tm.ucast_egress_port );
#else
   modify_field( ig_intr_md_for_tm.ucast_egress_port, 511 );
#endif
}

table Barksdale {
   actions {
      Wabasha;
   }
   default_action : Wabasha();
   size : 1;
}

control Beaman {
   apply( Barksdale );
}

action CityView() {
   modify_field(Stanwood.Tanner, 1);
   modify_field(Stanwood.Fosters, 1);

   bit_or(ig_intr_md_for_tm.copy_to_cpu, Miranda.Ballville, Loogootee.Freetown);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Stanwood.Hackney);
}

action Loysburg() {
}



@pragma ways 1
table Palomas {
   reads {
      Stanwood.Blackman : exact;
      Stanwood.Fernway : exact;
   }
   actions {
      CityView;
      Loysburg;
   }
   default_action : Loysburg;
   size : 1;
}

action Linville() {
   modify_field(Stanwood.McDaniels, 1);
   modify_field(Stanwood.Annawan, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Stanwood.Hackney, Monida);
}

table Boyce {
   actions {
      Linville;
   }
   default_action : Linville;
   size : 1;
}

action Gorman() {
   modify_field(Stanwood.Oakford, 1);
   modify_field(Stanwood.Fosters, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Stanwood.Hackney);
}

table Kahaluu {
   actions {
      Gorman;
   }
   default_action : Gorman();
   size : 1;
}

action Barwick(Oilmont) {
   modify_field(Stanwood.Bethune, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Oilmont);
   modify_field(Stanwood.Trenary, Oilmont);
}

action ElMango(Wimberley) {
   modify_field(Stanwood.McDaniels, 1);
   modify_field(Stanwood.Faith, Wimberley);
}

action Kenvil() {
}

table Norland {
   reads {
      Stanwood.Blackman : exact;
      Stanwood.Fernway : exact;
      Stanwood.Hackney : exact;
   }

   actions {
      Barwick;
      ElMango;
      Columbia;
      Kenvil;
   }
   default_action : Kenvil();
   size : Philip;
}

control Chalco {
   if (Miranda.Exira == 0 and not valid(Louin) ) {
      apply(Norland) {
         Kenvil {
            apply(Palomas) {
               Loysburg {
                  if ((Stanwood.Blackman & 0x010000) == 0x010000) {
                     apply(Boyce);
                  } else {
                     apply(Kahaluu);
                  }
               }
            }
         }
      }
   }
}

action Skagway() {
   modify_field(Miranda.Hodges, 1);
   Columbia();
}

table Potter {
   actions {
      Skagway;
   }
   default_action : Skagway;
   size : 1;
}

control Lennep {
   if (Miranda.Exira == 0) {
      if ((Stanwood.Boistfort==0) and (Miranda.Washta==0) and (Miranda.Golden==0) and (Miranda.Dixmont==Stanwood.Trenary)) {
         apply(Potter);
      } else {
         Sewaren();
      }
   }
}




action Wellford( Hilltop ) {
   modify_field( Stanwood.Pawtucket, Hilltop );
}

action LaPlant() {
   modify_field( Stanwood.Pawtucket, Stanwood.Hackney );
}

table Cockrum {
   reads {
      eg_intr_md.egress_port : exact;
      Stanwood.Hackney : exact;
   }

   actions {
      Wellford;
      LaPlant;
   }
   default_action : LaPlant;
   size : SanPablo;
}

control Lurton {
   apply( Cockrum );
}



action Sutter( Mabelvale, Maxwelton ) {
   modify_field( Stanwood.Tingley, Mabelvale );
   modify_field( Stanwood.Emida, Maxwelton );
}

table Ivydale {
   reads {
      Stanwood.Siloam : exact;
   }

   actions {
      Sutter;
   }
   size : Junior;
}

action Cotter() {
   modify_field( Stanwood.Brothers, 1 );
   modify_field( Stanwood.Siloam, Haley );
}

action Nerstrand() {
   modify_field( Stanwood.Brothers, 1 );
   modify_field( Stanwood.Siloam, Rocklake );
}

table RichBar {
   reads {
      Stanwood.Shirley : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Cotter;
      Nerstrand;
   }
   default_action : Margie();
   size : 16;
}

action Deferiet(Pachuta, Baker, Kooskia, Despard) {
   modify_field( Stanwood.Loveland, Pachuta );
   modify_field( Stanwood.Trion, Baker );
   modify_field( Stanwood.Captiva, Kooskia );
   modify_field( Stanwood.Ivanpah, Despard );
}

table Vernal {
   reads {
        Stanwood.NewAlbin : exact;
   }
   actions {
      Deferiet;
   }
   size : Summit;
}

action Olyphant() {
   no_op();
}

action Anchorage() {
   modify_field( Thayne.Brashear, Mondovi[0].Hercules );
   remove_header( Mondovi[0] );
}

table Baskett {
   actions {
      Anchorage;
   }
   default_action : Anchorage;
   size : Oshoto;
}

action Lakeside() {
   no_op();
}

action Dobbins() {
   add_header( Mondovi[ 0 ] );
   modify_field( Mondovi[0].Toxey, Stanwood.Pawtucket );
   modify_field( Mondovi[0].Hercules, Thayne.Brashear );
   modify_field( Mondovi[0].Elvaston, Selawik.Cistern );
   modify_field( Mondovi[0].Leona, Selawik.Hermiston );
   modify_field( Thayne.Brashear, Dixfield );
}



table Coalton {
   reads {
      Stanwood.Pawtucket : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Lakeside;
      Dobbins;
   }
   default_action : Dobbins;
   size : Whigham;
}

action Alabaster() {
   modify_field(Thayne.Lanesboro, Stanwood.Blackman);
   modify_field(Thayne.ElRio, Stanwood.Fernway);
   modify_field(Thayne.Trimble, Stanwood.Tingley);
   modify_field(Thayne.Paulding, Stanwood.Emida);
}

action Horsehead() {
   Alabaster();
   add_to_field(Kasilof.Beatrice, -1);
   modify_field(Kasilof.Klukwan, Selawik.Lizella);
}

action Lowland() {
   Alabaster();
   add_to_field(Holliday.Henderson, -1);
   modify_field(Holliday.Finlayson, Selawik.Lizella);
}

action Wheatland() {
   modify_field(Kasilof.Klukwan, Selawik.Lizella);
}

action Tatum() {
   modify_field(Holliday.Finlayson, Selawik.Lizella);
}

action Greycliff() {
   Dobbins();
}

action Kerrville( Estrella, Kansas, Blanding, Riley ) {
   add_header( Teaneck );
   modify_field( Teaneck.Lanesboro, Estrella );
   modify_field( Teaneck.ElRio, Kansas );
   modify_field( Teaneck.Trimble, Blanding );
   modify_field( Teaneck.Paulding, Riley );
   modify_field( Teaneck.Brashear, Sanchez );

   add_header( Louin );
   modify_field( Louin.Placid, Stanwood.Loveland );
   modify_field( Louin.Tahuya, Stanwood.Trion );
   modify_field( Louin.Fontana, Stanwood.Captiva );
   modify_field( Louin.Elsmere, Stanwood.Ivanpah );
   modify_field( Louin.WyeMills, Stanwood.LaneCity );
}

action Dialville() {
   remove_header( Harney );
   remove_header( Comunas );
   remove_header( Alberta );
   copy_header( Thayne, Lyncourt );
   remove_header( Lyncourt );
   remove_header( Kasilof );
}

action Trevorton() {
   remove_header( Teaneck );
   remove_header( Louin );
}

action Powhatan() {
   Dialville();
   modify_field(Sprout.Klukwan, Selawik.Lizella);
}

action Buckholts() {
   Dialville();
   modify_field(Heppner.Finlayson, Selawik.Lizella);
}

table Tyrone {
   reads {
      Stanwood.Funkley : exact;
      Stanwood.Siloam : exact;
      Stanwood.Boistfort : exact;
      Kasilof.valid : ternary;
      Holliday.valid : ternary;
      Sprout.valid : ternary;
      Heppner.valid : ternary;
   }

   actions {
      Horsehead;
      Lowland;
      Wheatland;
      Tatum;
      Greycliff;
      Kerrville;
      Trevorton;
      Dialville;
      Powhatan;
      Buckholts;
   }
   size : Gregory;
}

control Bains {
   apply( Baskett );
}

control Goodyear {
   apply( Coalton );
}

control SanRemo {
   apply( RichBar ) {
      Margie {
         apply( Ivydale );
      }
   }
   apply( Vernal );
   apply( Tyrone );
}



field_list Geneva {
    Kingsland.Leoma;
    Miranda.Pardee;
    Lyncourt.Trimble;
    Lyncourt.Paulding;
    Kasilof.Carlson;
}

action Milam() {
   generate_digest(DeerPark, Geneva);
}

table Bloomburg {
   actions {
      Milam;
   }

   default_action : Milam;
   size : 1;
}

control Malabar {
   if (Miranda.Chugwater == 1) {
      apply(Bloomburg);
   }
}



action Vallejo() {
   modify_field( Selawik.Cistern, ElkFalls.Cadott );
}

action Everest() {
   modify_field( Selawik.Cistern, Mondovi[0].Elvaston );
   modify_field( Miranda.Ipava, Mondovi[0].Hercules );
}

action Ivyland() {
   modify_field( Selawik.Lizella, ElkFalls.Switzer );
}

action Comobabi() {
   modify_field( Selawik.Lizella, Roxboro.Heaton );
}

action Gurdon() {
   modify_field( Selawik.Lizella, Rockham.Locke );
}

action Fairchild( Juneau, Adelino ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Juneau );
   modify_field( ig_intr_md_for_tm.qid, Adelino );
}

table Overton {
   reads {
     Miranda.Marbury : exact;
   }

   actions {
     Vallejo;
     Everest;
   }

   size : Wauna;
}

table Pineridge {
   reads {
     Miranda.Woodsdale : exact;
     Miranda.Tulsa : exact;
   }

   actions {
     Ivyland;
     Comobabi;
     Gurdon;
   }

   size : Tappan;
}

table Toano {
   reads {
      ElkFalls.Topmost : ternary;
      ElkFalls.Cadott : ternary;
      Selawik.Cistern : ternary;
      Selawik.Lizella : ternary;
      Selawik.Wauneta : ternary;
   }

   actions {
      Fairchild;
   }

   size : Sunbury;
}

action Sunman( Davie, Ochoa ) {
   bit_or( Selawik.Wapinitia, Selawik.Wapinitia, Davie );
   bit_or( Selawik.Hartville, Selawik.Hartville, Ochoa );
}

table Termo {
   actions {
      Sunman;
   }
   default_action : Sunman;
   size : Ragley;
}

action Speedway( Suwanee ) {
   modify_field( Selawik.Lizella, Suwanee );
}

action Halltown( Ferry ) {
   modify_field( Selawik.Cistern, Ferry );
}

action Muncie( Piperton, Wyocena ) {
   modify_field( Selawik.Cistern, Piperton );
   modify_field( Selawik.Lizella, Wyocena );
}

table Sopris {
   reads {
      ElkFalls.Topmost : exact;
      Selawik.Wapinitia : exact;
      Selawik.Hartville : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }

   actions {
      Speedway;
      Halltown;
      Muncie;
   }

   size : Requa;
}

control BigPiney {
   apply( Overton );
   apply( Pineridge );
}

control Rankin {
   apply( Toano );
}

control Gwinn {
   apply( Termo );
   apply( Sopris );
}



action Cahokia( Callery ) {
   modify_field( Selawik.Coffman, Callery );
}

action Greenbelt( Romeo, Caplis ) {
   Cahokia( Romeo );
   modify_field( ig_intr_md_for_tm.qid, Caplis );
}

table Steprock {
   reads {
      Stanwood.Northcote : ternary;
      ig_intr_md_for_tm.copy_to_cpu : ternary;
      Stanwood.LaneCity : ternary;
      Miranda.Woodsdale : ternary;
      Miranda.Tulsa : ternary;
      Miranda.Ipava : ternary;
      Miranda.Kotzebue : ternary;
      Miranda.Nettleton : ternary;
      Stanwood.Boistfort : ternary;
      Alberta.Sontag : ternary;
   }

   actions {
      Cahokia;
      Greenbelt;
   }

   size : Ardara;
}

meter SwissAlp {
   type : packets;
   static : Talkeetna;
   instance_count : Kelso;
}

action McGonigle(ElLago) {
   execute_meter( SwissAlp, ElLago, ig_intr_md_for_tm.packet_color );
}

table Talkeetna {
   reads {
      ElkFalls.Lovilia : exact;
      Selawik.Coffman : exact;
   }
   actions {
      McGonigle;
   }
   size : Nathalie;
}

control LaPalma {

    if ( (
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x1 ) == 0 ) ) and ( Stanwood.Northcote == 1 ) ) or
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x2 ) == 0 ) ) and ( ig_intr_md_for_tm.copy_to_cpu == 1 ) )
       ) ) {
      apply( Talkeetna );
   }
}



action Brunson( Walnut ) {
   modify_field( Stanwood.Shirley, Nursery );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Walnut );
   modify_field( Stanwood.NewAlbin, ig_intr_md.ingress_port );
}

action Tuckerton( Menomonie ) {
   modify_field( Stanwood.Shirley, Elmsford );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Menomonie );
   modify_field( Stanwood.NewAlbin, ig_intr_md.ingress_port );
}

action Barber() {
   modify_field( Stanwood.Shirley, Nursery );
}

action Varnado() {
   modify_field( Stanwood.Shirley, Elmsford );
   modify_field( Stanwood.NewAlbin, ig_intr_md.ingress_port );
}

@pragma ternary 1
table Rosebush {
   reads {
      Stanwood.Northcote : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      Tuskahoma.Higley : exact;
      ElkFalls.Ladelle : ternary;
      Stanwood.LaneCity : ternary;
   }

   actions {
      Brunson;
      Tuckerton;
      Barber;
      Varnado;
   }
   size : Ramapo;
}

control Dixboro {
   apply( Rosebush );
}




counter Gabbs {
   type : packets_and_bytes;
   instance_count : Armagh;

   min_width : 128;


}

action Hillsview( Norborne ) {
   count( Gabbs, Norborne );
}

table Fragaria {
   reads {
      eg_intr_md.egress_port mask 0x7f: exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }

   actions {
     Hillsview;
   }

   size : Armagh;
}

control Wanamassa {
   apply( Fragaria );
}



action Runnemede()
{



   Columbia();
}

action WestBend()
{
   modify_field(Stanwood.Funkley, Capitola);
   bit_or(Stanwood.Trenary, 0x2000, Louin.Elsmere);
}

action Emory( Hospers ) {
   modify_field(Stanwood.Funkley, Capitola);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Hospers);
   modify_field(Stanwood.Trenary, Hospers);
}

table Hoven {
   reads {
      Louin.Placid : exact;
      Louin.Tahuya : exact;
      Louin.Fontana : exact;
      Louin.Elsmere : exact;
   }

   actions {
      WestBend;
      Emory;
      Runnemede;
   }
   default_action : Runnemede();
   size : Summit;
}

control Risco {
   apply( Hoven );
}



action Cascade( Tiskilwa, Hahira, Bardwell, Willows ) {
   modify_field( Shivwits.Raynham, Tiskilwa );
   modify_field( Ringwood.Westview, Bardwell );
   modify_field( Ringwood.Millsboro, Hahira );
   modify_field( Ringwood.Calumet, Willows );
}

table Sutton {
   reads {
     Roxboro.Gardena : exact;
     Miranda.Bemis : exact;
   }

   actions {
      Cascade;
   }
  size : Mooreland;
}

action Kinsey(Danbury, Langford, Reynolds) {
   modify_field( Ringwood.Millsboro, Danbury );
   modify_field( Ringwood.Westview, Langford );
   modify_field( Ringwood.Calumet, Reynolds );
}

table Wauregan {
   reads {
     Roxboro.Burwell : exact;
     Shivwits.Raynham : exact;
   }
   actions {
      Kinsey;
   }
   size : Mystic;
}

action Kaufman( Oskawalik, Dougherty, DeSmet ) {
   modify_field( Lumberton.Crary, Oskawalik );
   modify_field( Lumberton.Winnebago, Dougherty );
   modify_field( Lumberton.Braxton, DeSmet );
}

table Alabam {


   reads {
     Stanwood.Blackman : exact;
     Stanwood.Fernway : exact;
     Stanwood.Hackney : exact;
   }
   actions {
      Kaufman;
   }
   size : Longmont;
}

action Linden() {
   modify_field( Stanwood.Fosters, 1 );
}

action Fentress( Homeacre ) {
   Linden();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Ringwood.Millsboro );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Homeacre, Ringwood.Calumet );
}

action Weslaco( Foster ) {
   Linden();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Lumberton.Crary );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Foster, Lumberton.Braxton );
}

action Chatanika( Redondo ) {
   Linden();
   add( ig_intr_md_for_tm.mcast_grp_a, Stanwood.Hackney,
        Monida );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Redondo );
}

action Farnham() {
   modify_field( Stanwood.Virgin, 1 );
}

table Sandpoint {
   reads {
     Ringwood.Westview : ternary;
     Ringwood.Millsboro : ternary;
     Lumberton.Crary : ternary;
     Lumberton.Winnebago : ternary;
     Miranda.Kotzebue :ternary;
     Miranda.Washta:ternary;
   }
   actions {
      Fentress;
      Weslaco;
      Chatanika;
      Farnham;
   }
   size : 32;
}

control Belle {
   if( Miranda.Exira == 0 and
       Tuskahoma.Laton == 1 and
       Miranda.Kekoskee == 1 ) {
      apply( Sutton );
   }
}

control BigBow {
   if( Shivwits.Raynham != 0 ) {
      apply( Wauregan );
   }
}


control Geismar {
   if( Miranda.Exira == 0 and Miranda.Washta==1 ) {
      apply( Alabam );
   }
}

action Hoadly(Howland) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, DuckHill.Berea );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Howland );
}

table Dresser {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Hoadly;
    }
    size : 512;
}

control Sonoma {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Dresser);
   }
}




action Reydon( Glendevey, Grottoes ) {
   modify_field( Stanwood.Hackney, Glendevey );


   modify_field( Stanwood.Boistfort, Grottoes );
}

action Ashley() {

   drop();
}

table Leawood {
   reads {
     eg_intr_md.egress_rid: exact;
   }

   actions {
      Reydon;
   }
   default_action: Ashley;
   size : Sharon;
}


control Belvue {


   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Leawood);
   }
}

control ingress {

   Vinita();

   if( ElkFalls.Neuse != 0 ) {

      Mogadore();
   }

   Hooks();

   if( ElkFalls.Neuse != 0 ) {
      Bienville();


      CapeFair();
   }

   Campbell();


   Bronaugh();
   Sparkill();

   if( ElkFalls.Neuse != 0 ) {

      Vining();
   }


   Hanks();
   BigPiney();


   if( ElkFalls.Neuse != 0 ) {
      Silesia();
   }

   Beaman();
   Belle();


   if( ElkFalls.Neuse != 0 ) {
      Armona();
   }
   BigBow();




   Malabar();
   Hilburn();
   if( Stanwood.Northcote == 0 ) {
      if( valid( Louin ) ) {
         Risco();
      } else {
         Geismar();
         Chalco();
      }
   }
   if( not valid( Louin ) ) {
      Rankin();
   }


   if( Stanwood.Northcote == 0 ) {
      Lennep();
   }

   if ( ElkFalls.Neuse != 0 ) {
#ifndef NOT_GOOD        
        apply( Steprock );
#endif
        if( Stanwood.Northcote == 0 and Miranda.Washta == 1) {
            apply( Sandpoint );
        }
#ifdef NOT_GOOD
        else {
            apply(Steprock);
        }
#endif
    }

   if( ElkFalls.Neuse != 0 ) {
      Gwinn();
   }


   LaPalma();


   if( valid( Mondovi[0] ) ) {
      Bains();
   }

   if( Stanwood.Northcote == 0 ) {
      Sonoma();
   }




   Dixboro();
}

control egress {
   Belvue();
   Lurton();
   SanRemo();

   if( ( Stanwood.Brothers == 0 ) and ( Stanwood.Funkley != Capitola ) ) {
      Goodyear();
   }
   Wanamassa();
}

