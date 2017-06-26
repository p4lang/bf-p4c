// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 10000







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>



#ifndef Parkway
#define Parkway

header_type McAdoo {
	fields {
		Remington : 16;
		Westbrook : 16;
		Paisley : 8;
		PellCity : 8;
		Noelke : 8;
		Murchison : 8;
		Accomac : 1;
		Scanlon : 1;
		Langdon : 1;
		Christmas : 1;
		Whitewood : 1;
		Wheeling : 3;
	}
}

header_type Bootjack {
	fields {
		Sparr : 24;
		Gustine : 24;
		Admire : 24;
		Faysville : 24;
		Mattson : 16;
		Syria : 16;
		Vesuvius : 16;
		Fredonia : 16;
		McCartys : 16;
		Scissors : 8;
		Leonore : 8;
		Picabo : 6;
		Ovilla : 1;
		Floyd : 1;
		Higley : 12;
		Ruthsburg : 2;
		Cassa : 1;
		Vacherie : 1;
		Wagener : 1;
		Whatley : 1;
		Sweeny : 1;
		Drifton : 1;
		Gurdon : 1;
		Santos : 1;
		Lahaina : 1;
		Nighthawk : 1;
		Recluse : 1;
		FlyingH : 1;
		Polkville : 1;
		Chappells : 3;
	}
}

header_type Evelyn {
	fields {
		Lovett : 24;
		Yukon : 24;
		Wauregan : 24;
		Humacao : 24;
		Beltrami : 24;
		Cozad : 24;
		Belwood : 24;
		Darden : 24;
		Juniata : 16;
		Powelton : 16;
		Talbert : 16;
		Vantage : 16;
		Rendville : 12;
		Picacho : 3;
		Gabbs : 1;
		Nooksack : 3;
		Anselmo : 1;
		Millstone : 1;
		Annville : 1;
		Shivwits : 1;
		Hanston : 1;
		Kinard : 1;
		Shabbona : 8;
		Glendale : 12;
		Joiner : 4;
		Ocracoke : 6;
		Verbena : 10;
		Lansdowne : 9;
		Lilydale : 1;
	}
}


header_type Norwood {
	fields {
		Goldenrod : 8;
		Pendleton : 1;
		Olcott : 1;
		Barstow : 1;
		Roachdale : 1;
		Clinchco : 1;
		Anandale : 1;
	}
}

header_type Riley {
	fields {
		Gambrill : 32;
		Cammal : 32;
		Elburn : 6;
		OldTown : 16;
	}
}

header_type Eucha {
	fields {
		Moark : 128;
		Coverdale : 128;
		Vinita : 20;
		Bellwood : 8;
		Larue : 11;
		Adair : 8;
		MudLake : 13;
	}
}

header_type Burtrum {
	fields {
		Weslaco : 14;
		Friday : 1;
		Penitas : 12;
		Luverne : 1;
		Wildell : 1;
		Hawthorn : 6;
		BigRun : 2;
		Bayne : 6;
		Fiftysix : 3;
	}
}

header_type Twodot {
	fields {
		Talkeetna : 1;
		Doral : 1;
	}
}

header_type Alcester {
	fields {
		Romney : 8;
	}
}

header_type Mulhall {
	fields {
		Rawson : 16;
		Krupp : 11;
	}
}

header_type Creston {
	fields {
		Menomonie : 32;
		Waukesha : 32;
		Roggen : 32;
	}
}

header_type Veteran {
	fields {
		Carver : 32;
		Arpin : 32;
	}
}

header_type Wabbaseka {
	fields {
		Palmer : 8;
		Rocklake : 4;
		Granville : 15;
		NewAlbin : 1;
	}
}
#endif



#ifndef Stout
#define Stout


header_type National {
	fields {
		Talco : 6;
		Quinnesec : 10;
		Caballo : 4;
		Randle : 12;
		Fairlea : 12;
		Wilton : 2;
		Lyncourt : 2;
		Taconite : 8;
		Edmeston : 3;
		Bulger : 5;
	}
}



header_type Neosho {
	fields {
		Kiron : 24;
		Browndell : 24;
		Janney : 24;
		Bunker : 24;
		Combine : 16;
	}
}



header_type Stryker {
	fields {
		Ballinger : 3;
		Ballwin : 1;
		Russia : 12;
		Sontag : 16;
	}
}



header_type Rocky {
	fields {
		Powers : 4;
		Mizpah : 4;
		Bellmore : 6;
		Killen : 2;
		Almedia : 16;
		Airmont : 16;
		Theta : 3;
		Rosboro : 13;
		Duquoin : 8;
		Kelliher : 8;
		Trammel : 16;
		Sarepta : 32;
		Dixmont : 32;
	}
}

header_type Schroeder {
	fields {
		Tiverton : 4;
		Devore : 6;
		Gladys : 2;
		McCune : 20;
		Matador : 16;
		Doyline : 8;
		Century : 8;
		Gardiner : 128;
		Swansboro : 128;
	}
}




header_type Newkirk {
	fields {
		Belvue : 8;
		Munday : 8;
		Mogadore : 16;
	}
}

header_type Garretson {
	fields {
		Crowheart : 16;
		Eldora : 16;
	}
}

header_type Rankin {
	fields {
		Sultana : 32;
		Saxis : 32;
		Chispa : 4;
		Prismatic : 4;
		Whiteclay : 8;
		Tascosa : 16;
		Waldo : 16;
		Millstadt : 16;
	}
}

header_type Torrance {
	fields {
		Bowden : 16;
		Ozona : 16;
	}
}



header_type Benitez {
	fields {
		Heidrick : 16;
		Alakanuk : 16;
		Woodston : 8;
		Scottdale : 8;
		Crystola : 16;
	}
}

header_type Sespe {
	fields {
		Pinecrest : 48;
		Rozet : 32;
		WolfTrap : 48;
		Freehold : 32;
	}
}



header_type Pinesdale {
	fields {
		Baranof : 1;
		Judson : 1;
		Lakefield : 1;
		McKibben : 1;
		Munich : 1;
		Desdemona : 3;
		Portis : 5;
		Darby : 3;
		Winner : 16;
	}
}

header_type Grigston {
	fields {
		Upson : 24;
		Kaaawa : 8;
	}
}



header_type Freedom {
	fields {
		Elloree : 8;
		Ironside : 24;
		Selawik : 24;
		Hayward : 8;
	}
}

#endif



#ifndef Rhinebeck
#define Rhinebeck

#define Pilger        0x8100
#define ViewPark        0x0800
#define Mancelona        0x86dd
#define Berrydale        0x9100
#define Buncombe        0x8847
#define LoneJack         0x0806
#define Litroe        0x8035
#define Chatcolet        0x88cc
#define Skiatook        0x8809
#define ElmPoint      0xBF00

#define Prosser              1
#define Hueytown              2
#define Nathalie              4
#define Lenexa               6
#define Moneta               17
#define Longview                47

#define PineLake         0x501
#define LeeCreek          0x506
#define Bunavista          0x511
#define LaPointe          0x52F


#define Calabasas                 4789



#define Tigard               0
#define Fallis              1
#define Candor                2



#define Hutchings          0
#define Botna          4095
#define Preston  4096
#define Rollins  8191



#define Equality                      0
#define Needles                  0
#define Newborn                 1

header Neosho BigPlain;
header Neosho Danville;
header Stryker Allgood[ 2 ];
header Rocky Winnebago;
header Rocky Sledge;
header Schroeder Bremond;
header Schroeder Woodburn;
header Garretson Holliday;
header Rankin Yardley;
header Torrance Greenbelt;
header Rankin Bethune;
header Torrance Jacobs;
header Freedom Eldena;
header Benitez Petrey;
header Pinesdale Sudbury;
header National Crossnore;
header Neosho Molson;

parser start {
   return select(current(96, 16)) {
      ElmPoint : Geismar;
      default : Brodnax;
   }
}

parser Gresston {
   extract( Crossnore );
   return Brodnax;
}

parser Geismar {
   extract( Molson );
   return Gresston;
}

parser Brodnax {
   extract( BigPlain );
   return select( BigPlain.Combine ) {
      Pilger : Kaweah;
      ViewPark : Lovelady;
      Mancelona : Bayport;
      LoneJack  : Noyes;
      default        : ingress;
   }
}

parser Kaweah {
   extract( Allgood[0] );
   set_metadata(Berne.Wheeling, Allgood[0].Ballinger );
   set_metadata(Berne.Whitewood, 1);
   return select( Allgood[0].Sontag ) {
      ViewPark : Lovelady;
      Mancelona : Bayport;
      LoneJack  : Noyes;
      default : ingress;
   }
}

parser Lovelady {
   extract( Winnebago );
   set_metadata(Berne.Paisley, Winnebago.Kelliher);
   set_metadata(Berne.Noelke, Winnebago.Duquoin);
   set_metadata(Berne.Remington, Winnebago.Almedia);
   set_metadata(Berne.Langdon, 0);
   set_metadata(Berne.Accomac, 1);
   return select(Winnebago.Rosboro, Winnebago.Mizpah, Winnebago.Kelliher) {
      Bunavista : Amherst;
      LeeCreek : Palmdale;
      default : ingress;
   }
}

parser Bayport {
   extract( Woodburn );
   set_metadata(Berne.Paisley, Woodburn.Doyline);
   set_metadata(Berne.Noelke, Woodburn.Century);
   set_metadata(Berne.Remington, Woodburn.Matador);
   set_metadata(Berne.Langdon, 1);
   set_metadata(Berne.Accomac, 0);
   return ingress;
}

parser Noyes {
   extract( Petrey );
   return ingress;
}

parser Amherst {
   extract(Holliday);
   extract(Greenbelt);
   return select(Holliday.Eldora) {
      Calabasas : Tularosa;
      default : ingress;
    }
}

parser Palmdale {
   extract(Holliday);
   extract(Yardley);
   return ingress;
}

parser Hillside {
   set_metadata(Conneaut.Ruthsburg, Candor);
   return Luzerne;
}

parser Jermyn {
   set_metadata(Conneaut.Ruthsburg, Candor);
   return Acree;
}

parser Filer {
   extract(Sudbury);
   return select(Sudbury.Baranof, Sudbury.Judson, Sudbury.Lakefield, Sudbury.McKibben, Sudbury.Munich,
             Sudbury.Desdemona, Sudbury.Portis, Sudbury.Darby, Sudbury.Winner) {
      ViewPark : Hillside;
      Mancelona : Jermyn;
      default : ingress;
   }
}

parser Tularosa {
   extract(Eldena);
   set_metadata(Conneaut.Ruthsburg, Fallis);
   return Ekron;
}

parser Luzerne {
   extract( Sledge );
   set_metadata(Berne.PellCity, Sledge.Kelliher);
   set_metadata(Berne.Murchison, Sledge.Duquoin);
   set_metadata(Berne.Westbrook, Sledge.Almedia);
   set_metadata(Berne.Christmas, 0);
   set_metadata(Berne.Scanlon, 1);
   return ingress;
}

parser Acree {
   extract( Bremond );
   set_metadata(Berne.PellCity, Bremond.Doyline);
   set_metadata(Berne.Murchison, Bremond.Century);
   set_metadata(Berne.Westbrook, Bremond.Matador);
   set_metadata(Berne.Christmas, 1);
   set_metadata(Berne.Scanlon, 0);
   return ingress;
}

parser Ekron {
   extract( Danville );
   return select( Danville.Combine ) {
      ViewPark: Luzerne;
      Mancelona: Acree;
      default: ingress;
   }
}
#endif

metadata Bootjack Conneaut;
metadata Evelyn Clementon;
metadata Burtrum Flynn;
metadata McAdoo Berne;
metadata Riley Lindsborg;
metadata Eucha Sheldahl;
metadata Twodot Wentworth;
metadata Norwood Padroni;
metadata Alcester Darmstadt;
metadata Mulhall Reager;
metadata Veteran Danbury;
metadata Creston Braxton;
metadata Wabbaseka Piermont;













#undef Umpire

#undef Standard
#undef Lakota
#undef Langlois
#undef Neche
#undef Piney

#undef Lewistown
#undef Perrin
#undef Albany

#undef Magness
#undef Jenera
#undef Felida
#undef Newland
#undef Browning
#undef Locke
#undef Mondovi
#undef Sonoma
#undef Hoagland
#undef Norma
#undef Realitos
#undef Thalia
#undef Brinkley
#undef Fragaria
#undef Pelion
#undef Paullina
#undef Pedro
#undef Stuttgart
#undef Runnemede
#undef Reagan
#undef Negra

#undef Puyallup
#undef Hillsview
#undef Lumberton
#undef Heaton
#undef Pound
#undef Daniels
#undef Roseworth
#undef Brookwood
#undef Markville
#undef NorthRim
#undef Westland
#undef Chilson
#undef Paulding
#undef Daysville
#undef Gerty
#undef Cassadaga
#undef Woodlake
#undef Nuiqsut
#undef Heflin
#undef Halstead
#undef Wyarno

#undef Ephesus
#undef Wakenda

#undef Kentwood

#undef Lurton







#define Umpire 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Standard      65536
#define Lakota      65536
#define Langlois 512
#define Neche 512
#define Piney      512


#define Lewistown     1024
#define Perrin    1024
#define Albany     256


#define Magness 512
#define Jenera 65536
#define Felida 65536
#define Newland 28672
#define Browning   16384
#define Locke 8192
#define Mondovi         131072
#define Sonoma 65536
#define Hoagland 1024
#define Norma 2048
#define Realitos 16384
#define Thalia 8192
#define Brinkley 65536

#define Fragaria 0x0000000000000000FFFFFFFFFFFFFFFF


#define Pelion 0x000fffff
#define Stuttgart 2

#define Paullina 0xFFFFFFFFFFFFFFFF0000000000000000

#define Pedro 0x000007FFFFFFFFFF0000000000000000
#define Runnemede  6
#define Negra        2048
#define Reagan       65536


#define Puyallup 1024
#define Hillsview 4096
#define Lumberton 4096
#define Heaton 4096
#define Pound 4096
#define Daniels 1024
#define Roseworth 4096
#define Markville 128
#define NorthRim 1
#define Westland  8


#define Chilson 512
#define Ephesus 512
#define Wakenda 256


#define Paulding 1
#define Daysville 3
#define Gerty 80



#define Cassadaga 512
#define Woodlake 512
#define Nuiqsut 512
#define Heflin 512

#define Halstead 2048
#define Wyarno 1024



#define Kentwood 0


#define Lurton    4096

#endif



#ifndef Revere
#define Revere

action Leoma() {
   no_op();
}

action Elsmere() {
   modify_field(Conneaut.Whatley, 1 );
}

action LaPryor() {
   no_op();
}
#endif

















action Fairfield(Akhiok, IowaCity, Casnovia, Bendavis, Ponder, Nucla,
                 Merit, Newburgh, Vining) {
    modify_field(Flynn.Weslaco, Akhiok);
    modify_field(Flynn.Friday, IowaCity);
    modify_field(Flynn.Penitas, Casnovia);
    modify_field(Flynn.Luverne, Bendavis);
    modify_field(Flynn.Wildell, Ponder);
    modify_field(Flynn.Hawthorn, Nucla);
    modify_field(Flynn.BigRun, Merit);
    modify_field(Flynn.Fiftysix, Newburgh);
    modify_field(Flynn.Bayne, Vining);
}

@pragma command_line --no-dead-code-elimination
table Meyers {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Fairfield;
    }
    size : Umpire;
}

control Toulon {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Meyers);
    }
}





action Harvest(Sixteen) {
   modify_field( Clementon.Gabbs, 1 );
   modify_field( Clementon.Shabbona, Sixteen);
   modify_field( Conneaut.Nighthawk, 1 );
}

action Frewsburg() {
   modify_field( Conneaut.Gurdon, 1 );
   modify_field( Conneaut.FlyingH, 1 );
}

action Arnold() {
   modify_field( Conneaut.Nighthawk, 1 );
}

action Suffolk() {
   modify_field( Conneaut.Recluse, 1 );
}

action Weimar() {
   modify_field( Conneaut.FlyingH, 1 );
}

counter Patchogue {
   type : packets_and_bytes;
   direct : Weiser;
   min_width: 16;
}

table Weiser {
   reads {
      Flynn.Hawthorn : exact;
      BigPlain.Kiron : ternary;
      BigPlain.Browndell : ternary;
   }

   actions {
      Harvest;
      Frewsburg;
      Arnold;
      Suffolk;
      Weimar;
   }
   size : Langlois;
}

action Elvaston() {
   modify_field( Conneaut.Santos, 1 );
}


table Haworth {
   reads {
      BigPlain.Janney : ternary;
      BigPlain.Bunker : ternary;
   }

   actions {
      Elvaston;
   }
   size : Neche;
}


control Ledoux {
   apply( Weiser );
   apply( Haworth );
}




action Donegal() {
   modify_field( Lindsborg.Gambrill, Sledge.Sarepta );
   modify_field( Lindsborg.Cammal, Sledge.Dixmont );
   modify_field( Lindsborg.Elburn, Sledge.Bellmore );
   modify_field( Sheldahl.Moark, Bremond.Gardiner );
   modify_field( Sheldahl.Coverdale, Bremond.Swansboro );
   modify_field( Sheldahl.Vinita, Bremond.McCune );
   modify_field( Sheldahl.Adair, Bremond.Devore );
   modify_field( Conneaut.Sparr, Danville.Kiron );
   modify_field( Conneaut.Gustine, Danville.Browndell );
   modify_field( Conneaut.Admire, Danville.Janney );
   modify_field( Conneaut.Faysville, Danville.Bunker );
   modify_field( Conneaut.Mattson, Danville.Combine );
   modify_field( Conneaut.McCartys, Berne.Westbrook );
   modify_field( Conneaut.Scissors, Berne.PellCity );
   modify_field( Conneaut.Leonore, Berne.Murchison );
   modify_field( Conneaut.Floyd, Berne.Scanlon );
   modify_field( Conneaut.Ovilla, Berne.Christmas );
   modify_field( Conneaut.Polkville, 0 );
   modify_field( Flynn.BigRun, 2 );
   modify_field( Flynn.Fiftysix, 0 );
   modify_field( Flynn.Bayne, 0 );
}

action Willits() {
   modify_field( Conneaut.Ruthsburg, Tigard );
   modify_field( Lindsborg.Gambrill, Winnebago.Sarepta );
   modify_field( Lindsborg.Cammal, Winnebago.Dixmont );
   modify_field( Lindsborg.Elburn, Winnebago.Bellmore );
   modify_field( Sheldahl.Moark, Woodburn.Gardiner );
   modify_field( Sheldahl.Coverdale, Woodburn.Swansboro );
   modify_field( Sheldahl.Vinita, Woodburn.McCune );
   modify_field( Sheldahl.Adair, Woodburn.Devore );
   modify_field( Conneaut.Sparr, BigPlain.Kiron );
   modify_field( Conneaut.Gustine, BigPlain.Browndell );
   modify_field( Conneaut.Admire, BigPlain.Janney );
   modify_field( Conneaut.Faysville, BigPlain.Bunker );
   modify_field( Conneaut.Mattson, BigPlain.Combine );
   modify_field( Conneaut.McCartys, Berne.Remington );
   modify_field( Conneaut.Scissors, Berne.Paisley );
   modify_field( Conneaut.Leonore, Berne.Noelke );
   modify_field( Conneaut.Floyd, Berne.Accomac );
   modify_field( Conneaut.Ovilla, Berne.Langdon );
   modify_field( Conneaut.Chappells, Berne.Wheeling );
   modify_field( Conneaut.Polkville, Berne.Whitewood );
}

table Challis {
   reads {
      BigPlain.Kiron : exact;
      BigPlain.Browndell : exact;
      Winnebago.Dixmont : exact;
      Conneaut.Ruthsburg : exact;
   }

   actions {
      Donegal;
      Willits;
   }

   default_action : Willits();
   size : Puyallup;
}


action Blackwood() {
   modify_field( Conneaut.Syria, Flynn.Penitas );
   modify_field( Conneaut.Vesuvius, Flynn.Weslaco);
}

action Heeia( Tillatoba ) {
   modify_field( Conneaut.Syria, Tillatoba );
   modify_field( Conneaut.Vesuvius, Flynn.Weslaco);
}

action Uncertain() {
   modify_field( Conneaut.Syria, Allgood[0].Russia );
   modify_field( Conneaut.Vesuvius, Flynn.Weslaco);
}

table Berlin {
   reads {
      Flynn.Weslaco : ternary;
      Allgood[0] : valid;
      Allgood[0].Russia : ternary;
   }

   actions {
      Blackwood;
      Heeia;
      Uncertain;
   }
   size : Heaton;
}

action Rienzi( Catawissa ) {
   modify_field( Conneaut.Vesuvius, Catawissa );
}

action Arredondo() {

   modify_field( Conneaut.Wagener, 1 );
   modify_field( Darmstadt.Romney,
                 Newborn );
}

table Segundo {
   reads {
      Winnebago.Sarepta : exact;
   }

   actions {
      Rienzi;
      Arredondo;
   }
   default_action : Arredondo;
   size : Lumberton;
}

action CoosBay( Thomas, Trooper, Atwater, Netcong, GunnCity,
                        Stowe, Gallion ) {
   modify_field( Conneaut.Syria, Thomas );
   modify_field( Conneaut.Fredonia, Thomas );
   modify_field( Conneaut.Drifton, Gallion );
   Booth(Trooper, Atwater, Netcong, GunnCity,
                        Stowe );
}

action LaPlata() {
   modify_field( Conneaut.Sweeny, 1 );
}

table Tatitlek {
   reads {
      Eldena.Selawik : exact;
   }

   actions {
      CoosBay;
      LaPlata;
   }
   size : Hillsview;
}

action Booth(Olmstead, Bigfork, Harts, Topawa,
                        Harleton ) {
   modify_field( Padroni.Goldenrod, Olmstead );
   modify_field( Padroni.Pendleton, Bigfork );
   modify_field( Padroni.Barstow, Harts );
   modify_field( Padroni.Olcott, Topawa );
   modify_field( Padroni.Roachdale, Harleton );
}

action Moreland(Magazine, Encinitas, CoalCity, Dunmore,
                        Derita ) {
   modify_field( Conneaut.Fredonia, Flynn.Penitas );
   modify_field( Conneaut.Drifton, 1 );
   Booth(Magazine, Encinitas, CoalCity, Dunmore,
                        Derita );
}

action Virgin(McAlister, Bayard, Corinth, Myrick,
                        ElkFalls, Varna ) {
   modify_field( Conneaut.Fredonia, McAlister );
   modify_field( Conneaut.Drifton, 1 );
   Booth(Bayard, Corinth, Myrick, ElkFalls,
                        Varna );
}

action SaintAnn(Barnsdall, SandCity, Dresden, Union,
                        Aberfoil ) {
   modify_field( Conneaut.Fredonia, Allgood[0].Russia );
   modify_field( Conneaut.Drifton, 1 );
   Booth(Barnsdall, SandCity, Dresden, Union,
                        Aberfoil );
}

table Sitka {
   reads {
      Flynn.Penitas : exact;
   }


   actions {
      Leoma;
      Moreland;
   }

   size : Pound;
}

@pragma action_default_only Leoma
table Southam {
   reads {
      Flynn.Weslaco : exact;
      Allgood[0].Russia : exact;
   }

   actions {
      Virgin;
      Leoma;
   }

   size : Daniels;
}

table Uniontown {
   reads {
      Allgood[0].Russia : exact;
   }


   actions {
      Leoma;
      SaintAnn;
   }

   size : Roseworth;
}

control FlatRock {
   apply( Challis ) {
         Donegal {
            apply( Segundo );
            apply( Tatitlek );
         }
         Willits {
            if ( Flynn.Luverne == 1 ) {
               apply( Berlin );
            }
            if ( valid( Allgood[ 0 ] ) ) {

               apply( Southam ) {
                  Leoma {

                     apply( Uniontown );
                  }
               }
            } else {

               apply( Sitka );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Kennedale {
    width  : 1;
    static : Gosnell;
    instance_count : 262144;
}

register Abraham {
    width  : 1;
    static : Kahaluu;
    instance_count : 262144;
}

blackbox stateful_alu Skene {
    reg : Kennedale;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Wentworth.Talkeetna;
}

blackbox stateful_alu Silco {
    reg : Abraham;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Wentworth.Doral;
}

field_list McAdams {
    Flynn.Hawthorn;
    Allgood[0].Russia;
}

field_list_calculation Conda {
    input { McAdams; }
    algorithm: identity;
    output_width: 18;
}

action Kniman() {
    Skene.execute_stateful_alu_from_hash(Conda);
}

action Shirley() {
    Silco.execute_stateful_alu_from_hash(Conda);
}

table Gosnell {
    actions {
      Kniman;
    }
    default_action : Kniman;
    size : 1;
}

table Kahaluu {
    actions {
      Shirley;
    }
    default_action : Shirley;
    size : 1;
}
#endif

action Allison(LasLomas) {
    modify_field(Wentworth.Doral, LasLomas);
}

@pragma  use_hash_action 0
table Kellner {
    reads {
       Flynn.Hawthorn : exact;
    }
    actions {
      Allison;
    }
    size : 64;
}

action Maltby() {
   modify_field( Conneaut.Higley, Flynn.Penitas );
   modify_field( Conneaut.Cassa, 0 );
}

table Grisdale {
   actions {
      Maltby;
   }
   size : 1;
}

action Greenbush() {
   modify_field( Conneaut.Higley, Allgood[0].Russia );
   modify_field( Conneaut.Cassa, 1 );
}

table Bardwell {
   actions {
      Greenbush;
   }
   size : 1;
}

control Carrizozo {
   if ( valid( Allgood[ 0 ] ) ) {
      apply( Bardwell );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Flynn.Wildell == 1 ) {
         apply( Gosnell );
         apply( Kahaluu );
      }
#endif
   } else {
      apply( Grisdale );
      if( Flynn.Wildell == 1 ) {
         apply( Kellner );
      }
   }
}




field_list Shawmut {
   BigPlain.Kiron;
   BigPlain.Browndell;
   BigPlain.Janney;
   BigPlain.Bunker;
   BigPlain.Combine;
}

field_list Kensett {

   Winnebago.Kelliher;
   Winnebago.Sarepta;
   Winnebago.Dixmont;
}

field_list Storden {
   Woodburn.Gardiner;
   Woodburn.Swansboro;
   Woodburn.McCune;
   Woodburn.Doyline;
}

field_list Trout {
   Winnebago.Sarepta;
   Winnebago.Dixmont;
   Holliday.Crowheart;
   Holliday.Eldora;
}





field_list_calculation Portales {
    input {
        Shawmut;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Placedo {
    input {
        Kensett;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Masardis {
    input {
        Storden;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Belle {
    input {
        Trout;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Mentone() {
    modify_field_with_hash_based_offset(Braxton.Menomonie, 0,
                                        Portales, 4294967296);
}

action Destin() {
    modify_field_with_hash_based_offset(Braxton.Waukesha, 0,
                                        Placedo, 4294967296);
}

action Keauhou() {
    modify_field_with_hash_based_offset(Braxton.Waukesha, 0,
                                        Masardis, 4294967296);
}

action Verdery() {
    modify_field_with_hash_based_offset(Braxton.Roggen, 0,
                                        Belle, 4294967296);
}

table Quogue {
   actions {
      Mentone;
   }
   size: 1;
}

control Reedsport {
   apply(Quogue);
}

table Haslet {
   actions {
      Destin;
   }
   size: 1;
}

table Malaga {
   actions {
      Keauhou;
   }
   size: 1;
}

control Klukwan {
   if ( valid( Winnebago ) ) {
      apply(Haslet);
   } else {
      if ( valid( Woodburn ) ) {
         apply(Malaga);
      }
   }
}

table Academy {
   actions {
      Verdery;
   }
   size: 1;
}

control Noonan {
   if ( valid( Greenbelt ) ) {
      apply(Academy);
   }
}



action Neame() {
    modify_field(Danbury.Carver, Braxton.Menomonie);
}

action Tusayan() {
    modify_field(Danbury.Carver, Braxton.Waukesha);
}

action Pownal() {
    modify_field(Danbury.Carver, Braxton.Roggen);
}

@pragma action_default_only Leoma
@pragma immediate 0
table Auberry {
   reads {
      Bethune.valid : ternary;
      Jacobs.valid : ternary;
      Sledge.valid : ternary;
      Bremond.valid : ternary;
      Danville.valid : ternary;
      Yardley.valid : ternary;
      Greenbelt.valid : ternary;
      Winnebago.valid : ternary;
      Woodburn.valid : ternary;
      BigPlain.valid : ternary;
   }
   actions {
      Neame;
      Tusayan;
      Pownal;
      Leoma;
   }
   size: Albany;
}

action Wauna() {
    modify_field(Danbury.Arpin, Braxton.Roggen);
}

@pragma immediate 0
table Kirkwood {
   reads {
      Bethune.valid : ternary;
      Jacobs.valid : ternary;
      Yardley.valid : ternary;
      Greenbelt.valid : ternary;
   }
   actions {
      Wauna;
      Leoma;
   }
   size: Runnemede;
}

control LeaHill {
   apply(Kirkwood);
   apply(Auberry);
}



counter Veguita {
   type : packets_and_bytes;
   direct : Riverland;
   min_width: 16;
}

@pragma action_default_only Leoma
table Riverland {
   reads {
      Flynn.Hawthorn : exact;
      Wentworth.Doral : ternary;
      Wentworth.Talkeetna : ternary;
      Conneaut.Sweeny : ternary;
      Conneaut.Santos : ternary;
      Conneaut.Gurdon : ternary;
   }

   actions {
      Elsmere;
      Leoma;
   }
   size : Piney;
}

action Hooker() {

   modify_field(Conneaut.Vacherie, 1 );
   modify_field(Darmstadt.Romney,
                Needles);
}







table Buckholts {
   reads {
      Conneaut.Admire : exact;
      Conneaut.Faysville : exact;
      Conneaut.Syria : exact;
      Conneaut.Vesuvius : exact;
   }

   actions {
      LaPryor;
      Hooker;
   }
   size : Lakota;
   support_timeout : true;
}

action Bonner() {
   modify_field( Padroni.Clinchco, 1 );
}

table Mattawan {
   reads {
      Conneaut.Fredonia : ternary;
      Conneaut.Sparr : exact;
      Conneaut.Gustine : exact;
   }
   actions {
      Bonner;
   }
   size: Magness;
}

control Connell {
   apply( Riverland ) {
      Leoma {



         if (Flynn.Friday == 0 and Conneaut.Wagener == 0) {
            apply( Buckholts );
         }
         apply(Mattawan);
      }
   }
}

field_list Honokahua {
    Darmstadt.Romney;
    Conneaut.Admire;
    Conneaut.Faysville;
    Conneaut.Syria;
    Conneaut.Vesuvius;
}

action Soledad() {
   generate_digest(Equality, Honokahua);
}

table Yaurel {
   actions {
      Soledad;
   }
   size : 1;
}

control Hodges {
   if (Conneaut.Vacherie == 1) {
      apply( Yaurel );
   }
}



action Northboro( Dunnegan, Hilburn ) {
   modify_field( Sheldahl.MudLake, Dunnegan );
   modify_field( Reager.Rawson, Hilburn );
}

@pragma action_default_only Ebenezer
table Nason {
   reads {
      Padroni.Goldenrod : exact;
      Sheldahl.Coverdale mask Paullina : lpm;
   }
   actions {
      Northboro;
      Ebenezer;
   }
   size : Thalia;
}

@pragma atcam_partition_index Sheldahl.MudLake
@pragma atcam_number_partitions Thalia
table Nuremberg {
   reads {
      Sheldahl.MudLake : exact;
      Sheldahl.Coverdale mask Pedro : lpm;
   }

   actions {
      Wabuska;
      Moraine;
      Leoma;
   }
   default_action : Leoma();
   size : Brinkley;
}

action Lisle( Stockton, Lamar ) {
   modify_field( Sheldahl.Larue, Stockton );
   modify_field( Reager.Rawson, Lamar );
}

@pragma action_default_only Leoma
table Gibbs {


   reads {
      Padroni.Goldenrod : exact;
      Sheldahl.Coverdale : lpm;
   }

   actions {
      Lisle;
      Leoma;
   }

   size : Norma;
}

@pragma atcam_partition_index Sheldahl.Larue
@pragma atcam_number_partitions Norma
table Pringle {
   reads {
      Sheldahl.Larue : exact;


      Sheldahl.Coverdale mask Fragaria : lpm;
   }
   actions {
      Wabuska;
      Moraine;
      Leoma;
   }

   default_action : Leoma();
   size : Realitos;
}

@pragma action_default_only Ebenezer
@pragma idletime_precision 1
table Sebewaing {

   reads {
      Padroni.Goldenrod : exact;
      Lindsborg.Cammal : lpm;
   }

   actions {
      Wabuska;
      Moraine;
      Ebenezer;
   }

   size : Hoagland;
   support_timeout : true;
}

action Oshoto( Levittown, Putnam ) {
   modify_field( Lindsborg.OldTown, Levittown );
   modify_field( Reager.Rawson, Putnam );
}

@pragma action_default_only Leoma
#ifdef PROFILE_DEFAULT
@pragma stage 2 Locke
@pragma stage 3
#endif
table Ireton {
   reads {
      Padroni.Goldenrod : exact;
      Lindsborg.Cammal : lpm;
   }

   actions {
      Oshoto;
      Leoma;
   }

   size : Browning;
}

@pragma ways Stuttgart
@pragma atcam_partition_index Lindsborg.OldTown
@pragma atcam_number_partitions Browning
table Linden {
   reads {
      Lindsborg.OldTown : exact;
      Lindsborg.Cammal mask Pelion : lpm;
   }
   actions {
      Wabuska;
      Moraine;
      Leoma;
   }
   default_action : Leoma();
   size : Mondovi;
}

action Wabuska( Plano ) {
   modify_field( Reager.Rawson, Plano );
}

@pragma idletime_precision 1
table Cathcart {
   reads {
      Padroni.Goldenrod : exact;
      Lindsborg.Cammal : exact;
   }

   actions {
      Wabuska;
      Moraine;
      Leoma;
   }
   default_action : Leoma();
   size : Jenera;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
@pragma stage 2 Newland
@pragma stage 3
#endif
table Malmo {
   reads {
      Padroni.Goldenrod : exact;
      Sheldahl.Coverdale : exact;
   }

   actions {
      Wabuska;
      Moraine;
      Leoma;
   }
   default_action : Leoma();
   size : Felida;
   support_timeout : true;
}

action Calamus(Mellott, McDermott, Curlew) {
   modify_field(Clementon.Juniata, Curlew);
   modify_field(Clementon.Lovett, Mellott);
   modify_field(Clementon.Yukon, McDermott);
   modify_field(Clementon.Lilydale, 1);
}

action Kahua() {
   modify_field(Conneaut.Whatley, 1);
}

action Seaford(Higginson) {
   modify_field(Clementon.Gabbs, 1);
   modify_field(Clementon.Shabbona, Higginson);
}

action Ebenezer() {
   modify_field( Clementon.Gabbs, 1 );
   modify_field( Clementon.Shabbona, 9 );
}

table Edgemont {
   reads {
      Reager.Rawson : exact;
   }

   actions {
      Calamus;
      Kahua;
      Seaford;
   }
   size : Sonoma;
}

control Exell {
   if ( Conneaut.Whatley == 0 and Padroni.Clinchco == 1 ) {
      if ( ( Padroni.Pendleton == 1 ) and ( Conneaut.Floyd == 1 ) ) {
         apply( Cathcart ) {
            Leoma {
               apply( Ireton ) {
                  Oshoto {
                     apply( Linden );
                  }
                  Leoma {
                     apply( Sebewaing );
                  }
               }
            }
         }
      } else if ( ( Padroni.Barstow == 1 ) and ( Conneaut.Ovilla == 1 ) ) {
         apply( Malmo ) {
            Leoma {
               apply( Gibbs ) {
                  Lisle {
                     apply( Pringle );
                  }
                  Leoma {

                     apply( Nason ) {
                        Northboro {
                           apply( Nuremberg );
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Abernathy {
   if( Reager.Rawson != 0 ) {
      apply( Edgemont );
   }
}

action Moraine( Ramah ) {
   modify_field( Reager.Krupp, Ramah );
   modify_field( Padroni.Anandale, 1 );
}

field_list Hillcrest {
   Danbury.Arpin;
}

field_list_calculation Harrison {
    input {
        Hillcrest;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Colfax {
   selection_key : Harrison;
   selection_mode : resilient;
}

action_profile Toluca {
   actions {
      Wabuska;
   }
   size : Reagan;
   dynamic_action_selection : Colfax;
}

table Heads {
   reads {
      Reager.Krupp : exact;
   }
   action_profile : Toluca;
   size : Negra;
}

control Penalosa {
   if ( Reager.Krupp != 0 ) {
      apply( Heads );
   }
}



field_list Fiskdale {
   Danbury.Carver;
}

field_list_calculation Stonefort {
    input {
        Fiskdale;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Wartburg {
    selection_key : Stonefort;
    selection_mode : resilient;
}

action Raceland(Paxico) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Paxico);
}

action_profile Osman {
    actions {
        Raceland;
        Leoma;
    }
    size : Perrin;
    dynamic_action_selection : Wartburg;
}

table Northway {
   reads {
      Clementon.Talbert : exact;
   }
   action_profile: Osman;
   size : Lewistown;
}

control Slinger {
   if ((Clementon.Talbert & 0x2000) == 0x2000) {
      apply(Northway);
   }
}



action Lugert() {
   modify_field(Clementon.Lovett, Conneaut.Sparr);
   modify_field(Clementon.Yukon, Conneaut.Gustine);
   modify_field(Clementon.Wauregan, Conneaut.Admire);
   modify_field(Clementon.Humacao, Conneaut.Faysville);
   modify_field(Clementon.Juniata, Conneaut.Syria);
}

table Duchesne {
   actions {
      Lugert;
   }
   default_action : Lugert();
   size : 1;
}

control Columbus {
   if (Conneaut.Syria!=0) {
      apply( Duchesne );
   }
}

action Toano() {
   modify_field(Clementon.Millstone, 1);
   modify_field(Clementon.Anselmo, 1);
   modify_field(Clementon.Vantage, Clementon.Juniata);
}

action Cowles() {
}



@pragma ways 1
table Waucoma {
   reads {
      Clementon.Lovett : exact;
      Clementon.Yukon : exact;
   }
   actions {
      Toano;
      Cowles;
   }
   default_action : Cowles;
   size : 1;
}

action Poynette() {
   modify_field(Clementon.Annville, 1);
   modify_field(Clementon.Kinard, 1);
   add(Clementon.Vantage, Clementon.Juniata, Preston);
}

table Westtown {
   actions {
      Poynette;
   }
   default_action : Poynette;
   size : 1;
}

action Emigrant() {
   modify_field(Clementon.Hanston, 1);
   modify_field(Clementon.Vantage, Clementon.Juniata);
}

table Kittredge {
   actions {
      Emigrant;
   }
   default_action : Emigrant();
   size : 1;
}

action Bowdon(Richvale) {
   modify_field(Clementon.Shivwits, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Richvale);
   modify_field(Clementon.Talbert, Richvale);
}

action Magnolia(Caliente) {
   modify_field(Clementon.Annville, 1);
   modify_field(Clementon.Vantage, Caliente);
}

action Suwanee() {
}

table Virden {
   reads {
      Clementon.Lovett : exact;
      Clementon.Yukon : exact;
      Clementon.Juniata : exact;
   }

   actions {
      Bowdon;
      Magnolia;
      Suwanee;
   }
   default_action : Suwanee();
   size : Standard;
}

control Westel {
   if (Conneaut.Whatley == 0) {
      apply(Virden) {
         Suwanee {
            apply(Waucoma) {
               Cowles {
                  if ((Clementon.Lovett & 0x010000) == 0x010000) {
                     apply(Westtown);
                  } else {
                     apply(Kittredge);
                  }
               }
            }
         }
      }
   }
}

action Findlay() {
   modify_field(Conneaut.Lahaina, 1);
   modify_field(Conneaut.Whatley, 1);
}

@pragma stage 10
table Elmdale {
   actions {
      Findlay;
   }
   default_action : Findlay;
   size : 1;
}

control Hopedale {
   if (Conneaut.Whatley == 0) {
      if ((Clementon.Lilydale==0) and (Conneaut.Vesuvius==Clementon.Talbert)) {
         apply(Elmdale);
      } else {
         Cusick();
      }
   }
}



action Cliffs( Taneytown ) {
   modify_field( Clementon.Rendville, Taneytown );
}

action Pelican() {
   modify_field( Clementon.Rendville, Clementon.Juniata );
}

table Talent {
   reads {
      eg_intr_md.egress_port : exact;
      Clementon.Juniata : exact;
   }

   actions {
      Cliffs;
      Pelican;
   }
   default_action : Pelican;
   size : Lurton;
}

control Novinger {
   apply( Talent );
}



action Rives( Higgston, Delmont ) {
   modify_field( Clementon.Beltrami, Higgston );
   modify_field( Clementon.Cozad, Delmont );
}

action IttaBena( Kendrick, Craigtown, Midas, Atlantic ) {
   modify_field( Clementon.Beltrami, Kendrick );
   modify_field( Clementon.Cozad, Craigtown );
   modify_field( Clementon.Belwood, Midas );
   modify_field( Clementon.Darden, Atlantic );
}


table BayPort {
   reads {
      Clementon.Picacho : exact;
   }

   actions {
      Rives;
      IttaBena;
   }
   size : Westland;
}

action Worthing(Coventry, Lonepine, Oskaloosa, Gallinas) {
   modify_field( Clementon.Ocracoke, Coventry );
   modify_field( Clementon.Verbena, Lonepine );
   modify_field( Clementon.Joiner, Oskaloosa );
   modify_field( Clementon.Glendale, Gallinas );
}

table Tappan {
   reads {
        Clementon.Lansdowne : exact;
   }
   actions {
      Worthing;
   }
   size : Wakenda;
}

action Tuskahoma() {
   no_op();
}

action Edroy() {
   modify_field( BigPlain.Combine, Allgood[0].Sontag );
   remove_header( Allgood[0] );
}

table Amsterdam {
   actions {
      Edroy;
   }
   default_action : Edroy;
   size : NorthRim;
}

action Whigham() {
   no_op();
}

action Bernice() {
   add_header( Allgood[ 0 ] );
   modify_field( Allgood[0].Russia, Clementon.Rendville );
   modify_field( Allgood[0].Sontag, BigPlain.Combine );
   modify_field( BigPlain.Combine, Pilger );
}



table Woolwine {
   reads {
      Clementon.Rendville : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Whigham;
      Bernice;
   }
   default_action : Bernice;
   size : Markville;
}

action Lovewell() {
   modify_field(BigPlain.Kiron, Clementon.Lovett);
   modify_field(BigPlain.Browndell, Clementon.Yukon);
   modify_field(BigPlain.Janney, Clementon.Beltrami);
   modify_field(BigPlain.Bunker, Clementon.Cozad);
}

action Rocklin() {
   Lovewell();
   add_to_field(Winnebago.Duquoin, -1);
}

action Humeston() {
   Lovewell();
   add_to_field(Woodburn.Century, -1);
}

action WoodDale() {
   Bernice();
}

action Ramhurst() {
   add_header( Molson );
   modify_field( Molson.Kiron, Clementon.Beltrami );
   modify_field( Molson.Browndell, Clementon.Cozad );
   modify_field( Molson.Janney, Clementon.Belwood );
   modify_field( Molson.Bunker, Clementon.Darden );
   modify_field( Molson.Combine, ElmPoint );
   add_header( Crossnore );
   modify_field( Crossnore.Talco, Clementon.Ocracoke );
   modify_field( Crossnore.Quinnesec, Clementon.Verbena );
   modify_field( Crossnore.Caballo, Clementon.Joiner );
   modify_field( Crossnore.Randle, Clementon.Glendale );
   modify_field( Crossnore.Taconite, Clementon.Shabbona );
}

table Manilla {
   reads {
      Clementon.Nooksack : exact;
      Clementon.Picacho : exact;
      Clementon.Lilydale : exact;
      Winnebago.valid : ternary;
      Woodburn.valid : ternary;
   }

   actions {
      Rocklin;
      Humeston;
      WoodDale;
      Ramhurst;

   }
   size : Chilson;
}

control Vigus {
   apply( Amsterdam );
}

control Sofia {
   apply( Woolwine );
}

control LeCenter {
   apply( BayPort );
   apply( Tappan );
   apply( Manilla );
}



field_list Reidland {
    Darmstadt.Romney;
    Conneaut.Syria;
    Danville.Janney;
    Danville.Bunker;
    Winnebago.Sarepta;
}

action Horsehead() {
   generate_digest(Equality, Reidland);
}

table Suamico {
   actions {
      Horsehead;
   }

   default_action : Horsehead;
   size : 1;
}

control ElkRidge {
   if (Conneaut.Wagener == 1) {
      apply(Suamico);
   }
}



action Boydston( Bostic ) {
   modify_field( Piermont.Palmer, Bostic );
}

action Gobles() {
   modify_field( Piermont.Palmer, 0 );
}

@pragma stage 9
table Safford {
   reads {
     Conneaut.Vesuvius : ternary;
     Conneaut.Fredonia : ternary;
     Padroni.Clinchco : ternary;
   }

   actions {
     Boydston;
     Gobles;
   }

   default_action : Gobles();
   size : Cassadaga;
}

action Beeler( Cheyenne ) {
   modify_field( Piermont.Rocklake, Cheyenne );
   modify_field( Piermont.Granville, 0 );
   modify_field( Piermont.NewAlbin, 0 );
}

action Machens( Cleta, Nanson ) {
   modify_field( Piermont.Rocklake, 0 );
   modify_field( Piermont.Granville, Cleta );
   modify_field( Piermont.NewAlbin, Nanson );
}

action DeRidder( Moapa, Dunnellon, Albin ) {
   modify_field( Piermont.Rocklake, Moapa );
   modify_field( Piermont.Granville, Dunnellon );
   modify_field( Piermont.NewAlbin, Albin );
}

action Nursery() {
   modify_field( Piermont.Rocklake, 0 );
   modify_field( Piermont.Granville, 0 );
   modify_field( Piermont.NewAlbin, 0 );
}

@pragma stage 10
table Madera {
   reads {
     Piermont.Palmer : exact;
     Conneaut.Sparr : ternary;
     Conneaut.Gustine : ternary;
     Conneaut.Mattson : ternary;
   }

   actions {
     Beeler;
     Machens;
     DeRidder;
     Nursery;
   }

   default_action : Nursery();
   size : Woodlake;
}

@pragma stage 10
table Woodfords {
   reads {
     Piermont.Palmer : exact;
     Lindsborg.Cammal mask 0xffff0000 : ternary;
     Conneaut.Scissors : ternary;
     Conneaut.Leonore : ternary;
     Conneaut.Picabo : ternary;
     Reager.Rawson : ternary;

   }

   actions {
     Beeler;
     Machens;
     DeRidder;
     Nursery;
   }

   default_action : Nursery();
   size : Nuiqsut;
}

@pragma stage 10
table Pekin {
   reads {
     Piermont.Palmer : exact;
     Sheldahl.Coverdale mask 0xffff0000 : ternary;
     Conneaut.Scissors : ternary;
     Conneaut.Leonore : ternary;
     Conneaut.Picabo : ternary;
     Reager.Rawson : ternary;

   }

   actions {
     Beeler;
     Machens;
     DeRidder;
     Nursery;
   }

   default_action : Nursery();
   size : Heflin;
}

meter Harriston {
   type : packets;
   static : Paskenta;
   instance_count: Halstead;
}

action Myton( Moylan ) {
   // Unsupported address mode
   //execute_meter( Harriston, Moylan, ig_intr_md_for_tm.packet_color );
}

action Lomax() {
   execute_meter( Harriston, Piermont.Granville, ig_intr_md_for_tm.packet_color );
}

@pragma stage 11
table Paskenta {
   reads {
     Piermont.Granville : ternary;
     Conneaut.Vesuvius : ternary;
     Conneaut.Fredonia : ternary;
     Padroni.Clinchco : ternary;
     Piermont.NewAlbin : ternary;
   }
   actions {
      Myton;
      Lomax;
   }
   size : Wyarno;
}

control Challenge {
   apply( Safford );
}

control Cusick {
   if ( Conneaut.Floyd == 1 ) {
      apply( Woodfords );
   } else if ( Conneaut.Ovilla == 1 ) {
      apply( Pekin );
   } else {
      apply( Madera );
   }
}

control Cochise {
   apply( Paskenta );
}



action Trotwood() {
   modify_field( Conneaut.Chappells, Flynn.Fiftysix );
}

action Renfroe() {
   modify_field( Conneaut.Picabo, Flynn.Bayne );
}

action McGrady() {
   modify_field( Conneaut.Picabo, Lindsborg.Elburn );
}

action LoonLake() {
   modify_field( Conneaut.Picabo, Sheldahl.Adair );
}

action Tindall( Havana, Helotes ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Havana );
   modify_field( ig_intr_md_for_tm.qid, Helotes );
}

table Bieber {
   reads {
     Conneaut.Polkville : exact;
   }

   actions {
     Trotwood;
   }

   size : Paulding;
}

table Powderly {
   reads {
     Conneaut.Floyd : exact;
     Conneaut.Ovilla : exact;
   }

   actions {
     Renfroe;
     McGrady;
     LoonLake;
   }

   size : Daysville;
}

@pragma stage 11
table Medulla {
   reads {
      Flynn.BigRun : ternary;
      Flynn.Fiftysix : ternary;
      Conneaut.Chappells : ternary;
      Conneaut.Picabo : ternary;
      Piermont.Rocklake : ternary;
   }

   actions {
      Tindall;
   }

   size : Gerty;
}

control Livengood {
   apply( Bieber );
   apply( Powderly );
}

control Tallevast {
   apply( Medulla );
}




#define Sutherlin            0
#define Goulding  1
#define Northlake 2


#define Rockfield           0




action Swaledale( Ralph ) {
   modify_field( Clementon.Picacho, Goulding );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Ralph );
}

action Monaca( Nestoria ) {
   modify_field( Clementon.Picacho, Northlake );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Nestoria );
   modify_field( Clementon.Lansdowne, ig_intr_md.ingress_port );
}

table Bonney {
   reads {
      Padroni.Clinchco : exact;
      Flynn.Luverne : ternary;
      Clementon.Shabbona : ternary;
   }

   actions {
      Swaledale;
      Monaca;
   }

   size : Ephesus;
}

control Tuscumbia {
   apply( Bonney );
}


control ingress {

   Toulon();


   Ledoux();
   FlatRock();
   Carrizozo();


   Livengood();
   Connell();
   Reedsport();


   Klukwan();
   Noonan();


   Exell();


   LeaHill();


   Penalosa();
   Columbus();


   Abernathy();




   if( Clementon.Gabbs == 0 ) {
      Westel();
   } else {
      Tuscumbia();
   }

   Challenge();


   Hopedale();


   Tallevast();
   Cochise();
   Slinger();
   ElkRidge();
   Hodges();


   if( valid( Allgood[0] ) ) {
      Vigus();
   }
}

control egress {
   Novinger();
   LeCenter();

   if( Clementon.Gabbs == 0 ) {
      Sofia();
   }
}

