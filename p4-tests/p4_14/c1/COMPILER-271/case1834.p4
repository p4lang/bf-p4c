// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 23101







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
#else





header_type KingCity {
	fields {
		Morrow : 3;
	}
}
metadata KingCity Roscommon;

header_type Milan {
	fields {
		Chatanika : 1;
		Mather : 9;
		Doris : 48;
		Moorman : 32;
	}
}
metadata Milan Prismatic;

header_type Francis {
	fields {
		Luhrig : 9;
		ViewPark : 3;
		Waldo : 16;
		LaMonte : 16;
		Kosciusko : 13;
		Culloden : 13;
		Albany : 16;
		Hampton : 9;
		Paragonah : 16;
		Prosser : 1;
		Petrey : 3;
		Colmar : 5;
		PellLake : 2;
	}
}

metadata Francis Denby;

header_type Terrytown {
	fields {
		Elrosa : 9;
		Jenifer : 19;
		Othello : 2;
		Mondovi : 32;
		Burmah : 19;
		Hillcrest : 2;
		Villas : 8;
		Separ : 32;
		Heizer : 16;
		Macedonia : 1;
		Ponder : 5;
		Nelson : 3;
		Noyes : 1;
	}
}

metadata Terrytown Wadley;




action Plateau(Salduro) {
    modify_field(Covert, Salduro);
}

#ifdef BMV2
#define Broadus     Pelland
#else
#define Broadus         Rainelle
#endif

header_type Sespe {
	fields {
		Gladden : 8;
		Dunedin : 48;
	}
}
metadata Sespe Garwood;

#define Wenatchee 0
#define Brazil 1
#define Rocklin 2
#define Wollochet 3
#define Earling 4
#define Carnegie 5
#define Berkley 6


#define Bayonne \
    ((Hurdtown != Wenatchee) and \
     (Hurdtown != Carnegie))
#define Contact \
    ((Hurdtown == Wenatchee) or \
     (Hurdtown == Carnegie))
#define Mellott \
    (Hurdtown == Brazil)
#define Boquillas \
    (Hurdtown == Rocklin)
#endif



#ifndef Farson
#define Farson

header_type Wyanet {
	fields {
		Bushland : 16;
		Joslin : 16;
		Tarnov : 8;
		Alakanuk : 8;
		Moreland : 8;
		Gifford : 8;
		Wolford : 1;
		Shobonier : 1;
		Farthing : 1;
		Conger : 1;
	}
}

header_type Edmeston {
	fields {
		Tulsa : 24;
		Belmore : 24;
		Boquet : 24;
		Alvwood : 24;
		Elmdale : 16;
		Twisp : 16;
		Holladay : 16;
		Chouteau : 16;
		Westel : 16;
		Adamstown : 8;
		Bowden : 8;
		Hiseville : 1;
		Brothers : 1;
		Forkville : 12;
		Bigspring : 2;
		Pilar : 1;
		Loysburg : 1;
		Pimento : 1;
		Wauseon : 1;
		Essex : 1;
		Lafourche : 1;
		Pikeville : 1;
		UnionGap : 1;
		Seguin : 1;
		Coconut : 1;
		Sisters : 1;
		Slinger : 6;
	}
}

header_type Wapato {
	fields {
		Matheson : 24;
		RedLevel : 24;
		Alcoma : 24;
		Fernway : 24;
		Delavan : 24;
		WestPark : 24;
		BigRiver : 16;
		Poteet : 16;
		Dorothy : 16;
		Hopeton : 12;
		Morgana : 3;
		Lakeside : 3;
		Exton : 1;
		Roseau : 1;
		Brookneal : 1;
		Farragut : 1;
		Pettry : 1;
		Arkoe : 1;
		Nettleton : 1;
		RioPecos : 1;
		Poland : 8;
	}
}


header_type Larsen {
	fields {
		Arvonia : 8;
		Gallinas : 1;
		WebbCity : 1;
		Potter : 1;
		Darmstadt : 1;
		Colonie : 1;
	}
}

header_type Boydston {
	fields {
		Coamo : 32;
		Sherrill : 32;
		Tennessee : 6;
		Parkville : 16;
	}
}

header_type Gorman {
	fields {
		TroutRun : 128;
		Almelund : 128;
		Flomaton : 20;
		Cavalier : 8;
		Greer : 11;
		Oakville : 8;
	}
}

header_type Bowlus {
	fields {
		Dunnegan : 14;
		Stratford : 1;
		Bloomburg : 1;
		Criner : 12;
		Curtin : 1;
		Mishicot : 6;
	}
}

header_type Quealy {
	fields {
		Seagrove : 1;
		Scotland : 1;
	}
}

header_type Brush {
	fields {
		Uhland : 8;
	}
}

header_type Volcano {
	fields {
		Rockvale : 16;
	}
}

header_type Timbo {
	fields {
		Conda : 32;
		Corder : 32;
		Wickett : 32;
	}
}

header_type Lahaina {
	fields {
		Ravinia : 32;
		Kurten : 32;
	}
}

#endif



#ifndef Biloxi
#define Biloxi



header_type Comfrey {
	fields {
		Putnam : 24;
		Stanwood : 24;
		National : 24;
		Rohwer : 24;
		Weleetka : 16;
	}
}



header_type Readsboro {
	fields {
		Loogootee : 3;
		Braymer : 1;
		Sandoval : 12;
		Berville : 16;
	}
}



header_type Waucousta {
	fields {
		Kensal : 4;
		Crumstown : 4;
		Saxis : 6;
		Joyce : 2;
		Davie : 16;
		Heuvelton : 16;
		Tiskilwa : 3;
		Duchesne : 13;
		Decherd : 8;
		Stovall : 8;
		Affton : 16;
		Natalia : 32;
		Everetts : 32;
	}
}

header_type Basye {
	fields {
		Downs : 4;
		Thurmond : 6;
		Lodoga : 2;
		Natalbany : 20;
		Weyauwega : 16;
		Bosco : 8;
		Somis : 8;
		Kenova : 128;
		Verdemont : 128;
	}
}




header_type Rampart {
	fields {
		ElmGrove : 8;
		Laney : 8;
		Winger : 16;
	}
}

header_type Piermont {
	fields {
		Newport : 16;
		Corvallis : 16;
		Lemhi : 32;
		Hitterdal : 32;
		Ozona : 4;
		Lakefield : 4;
		Crouch : 8;
		Dietrich : 16;
		Newcastle : 16;
		Ravenwood : 16;
	}
}

header_type Elkton {
	fields {
		Cammal : 16;
		Hutchings : 16;
		Nanakuli : 16;
		Longford : 16;
	}
}



header_type LeeCreek {
	fields {
		Brunson : 16;
		Williams : 16;
		Nixon : 8;
		Tidewater : 8;
		Ripley : 16;
	}
}

header_type Horatio {
	fields {
		Longmont : 48;
		Converse : 32;
		Honokahua : 48;
		Ambler : 32;
	}
}



header_type Petty {
	fields {
		Wattsburg : 1;
		Maryville : 1;
		Matador : 1;
		Rosebush : 1;
		Fosters : 1;
		Normangee : 3;
		Bovina : 5;
		Frederic : 3;
		Emory : 16;
	}
}

header_type Melmore {
	fields {
		Olmstead : 24;
		Coalgate : 8;
	}
}



header_type Killen {
	fields {
		Deloit : 8;
		Gotham : 24;
		Pittsburg : 24;
		Cozad : 8;
	}
}

#endif



#ifndef Medulla
#define Medulla

parser start {
   return Waseca;
}

#define Moxley        0x8100
#define LoonLake        0x0800
#define Pound        0x86dd
#define Ronda        0x9100
#define Ironside        0x8847
#define Vevay         0x0806
#define Dixfield        0x8035
#define Sargeant        0x88cc
#define Allgood        0x8809

#define Yardley              1
#define Deport              2
#define Trotwood              4
#define Biehle               6
#define Faulkton               17
#define Stuttgart                47

#define Beltrami         0x501
#define Levittown          0x506
#define Bagwell          0x511
#define Dryden          0x52F


#define Madera                 4789



#define Johnsburg               0
#define Bernstein              1
#define Iselin                2



#define Loughman          0
#define Evendale          4095
#define Demarest  4096
#define BirchRun  8191



#define Hebbville                      0
#define Toccopola                  0
#define Inverness                 1

header Comfrey WhiteOwl;
header Comfrey Burrel;
header Readsboro Talbert[ 2 ];
header Waucousta Sardinia;
header Waucousta Kellner;
header Basye Corry;
header Basye Atlas;
header Piermont Jemison;
header Elkton Nuangola;
header Piermont Cowpens;
header Elkton BigBay;
header Killen Breese;
header LeeCreek Thurston;
header Petty Pojoaque;

parser Waseca {
   extract( WhiteOwl );
   return select( WhiteOwl.Weleetka ) {
      Moxley : Domestic;
      LoonLake : Webbville;
      Pound : Coalwood;
      Vevay  : Renick;
      default        : ingress;
   }
}

parser Domestic {
   extract( Talbert[0] );
   return select( Talbert[0].Berville ) {
      LoonLake : Webbville;
      Pound : Coalwood;
      Vevay  : Renick;
      default : ingress;
   }
}

parser Webbville {
   extract( Sardinia );
   set_metadata(Miller.Tarnov, Sardinia.Stovall);
   set_metadata(Miller.Moreland, Sardinia.Decherd);
   set_metadata(Miller.Bushland, Sardinia.Davie);
   set_metadata(Miller.Farthing, 0);
   set_metadata(Miller.Wolford, 1);
   return select(Sardinia.Duchesne, Sardinia.Crumstown, Sardinia.Stovall) {
      Bagwell : Brodnax;
      default : ingress;
   }
}

parser Coalwood {
   extract( Atlas );
   set_metadata(Miller.Tarnov, Atlas.Bosco);
   set_metadata(Miller.Moreland, Atlas.Somis);
   set_metadata(Miller.Bushland, Atlas.Weyauwega);
   set_metadata(Miller.Farthing, 1);
   set_metadata(Miller.Wolford, 0);
   return ingress;
}

parser Renick {
   extract( Thurston );
   return ingress;
}

parser Brodnax {
   extract(Nuangola);
   return select(Nuangola.Hutchings) {
      Madera : Waipahu;
      default : ingress;
    }
}

parser Ishpeming {
   set_metadata(Rhodell.Bigspring, Iselin);
   return Whiteclay;
}

parser FulksRun {
   set_metadata(Rhodell.Bigspring, Iselin);
   return Neosho;
}

parser Staunton {
   extract(Pojoaque);
   return select(Pojoaque.Wattsburg, Pojoaque.Maryville, Pojoaque.Matador, Pojoaque.Rosebush, Pojoaque.Fosters,
             Pojoaque.Normangee, Pojoaque.Bovina, Pojoaque.Frederic, Pojoaque.Emory) {
      LoonLake : Ishpeming;
      Pound : FulksRun;
      default : ingress;
   }
}

parser Waipahu {
   extract(Breese);
   set_metadata(Rhodell.Bigspring, Bernstein);
   return Sawpit;
}

parser Whiteclay {
   extract( Kellner );
   set_metadata(Miller.Alakanuk, Kellner.Stovall);
   set_metadata(Miller.Gifford, Kellner.Decherd);
   set_metadata(Miller.Joslin, Kellner.Davie);
   set_metadata(Miller.Conger, 0);
   set_metadata(Miller.Shobonier, 1);
   return ingress;
}

parser Neosho {
   extract( Corry );
   set_metadata(Miller.Alakanuk, Corry.Bosco);
   set_metadata(Miller.Gifford, Corry.Somis);
   set_metadata(Miller.Joslin, Corry.Weyauwega);
   set_metadata(Miller.Conger, 1);
   set_metadata(Miller.Shobonier, 0);
   return ingress;
}

parser Sawpit {
   extract( Burrel );
   return select( Burrel.Weleetka ) {
      LoonLake: Whiteclay;
      Pound: Neosho;
      default: ingress;
   }
}
#endif

@pragma pa_solitary ingress Rhodell.Twisp
@pragma pa_solitary ingress Rhodell.Holladay
@pragma pa_solitary ingress Rhodell.Chouteau
@pragma pa_solitary egress  Macksburg.Dorothy
//@pragma pa_solitary ingress ig_intr_md_for_tm.ucast_egress_port

//@pragma pa_atomic   ingress Crump.Ravinia
//@pragma pa_solitary ingress Crump.Ravinia
//@pragma pa_atomic   ingress Crump.Kurten
//@pragma pa_solitary ingress Crump.Kurten

metadata Edmeston Rhodell;
metadata Wapato Macksburg;
metadata Bowlus Azusa;
metadata Wyanet Miller;
metadata Boydston Cascadia;
metadata Gorman WestLawn;
metadata Quealy Uvalde;
metadata Larsen Blackwood;
metadata Brush Aguilar;
metadata Volcano Olivet;
metadata Lahaina Crump;
metadata Timbo Halley;



















#undef Tascosa

#undef Wauneta
#undef Tinsman
#undef Soledad
#undef Leacock
#undef Tennyson

#undef Norfork
#undef Center
#undef Kirkwood

#undef Lecompte
#undef Valdosta
#undef Nisland
#undef Frederika
#undef Hayward
#undef Darco
#undef LaUnion
#undef Hartville
#undef Dunken

#undef Abbyville
#undef Champlain
#undef Gaston
#undef Martelle
#undef Cassa
#undef Sparland
#undef DeSart
#undef Forbes
#undef Quivero
#undef Eaton
#undef Brainard
#undef Pickett

#undef Campo

#undef Nursery







#define Tascosa 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Wauneta      65536
#define Tinsman      65536
#define Soledad 512
#define Leacock 512
#define Tennyson      512


#define Norfork     1024
#define Center    1024
#define Kirkwood     256


#define Lecompte 512
#define Valdosta 65536
#define Nisland 65536
#define Frederika   16384
#define Hayward         131072
#define Darco 65536
#define LaUnion 1024
#define Hartville 2048
#define Dunken 16384


#define Abbyville 1024
#define Champlain 4096
#define Gaston 4096
#define Martelle 4096
#define Cassa 4096
#define Sparland 1024
#define DeSart 4096
#define Quivero 64
#define Eaton 1
#define Brainard  8
#define Pickett 512


#define Campo 0


#define Nursery    4096

#endif



#ifndef Almyra
#define Almyra

action Glazier() {
   no_op();
}

#endif

















action Euren(Baidland, Topmost, Magoun, Minto, Tornillo, Woodsboro) {
    modify_field(Azusa.Dunnegan, Baidland);
    modify_field(Azusa.Stratford, Topmost);
    modify_field(Azusa.Criner, Magoun);
    modify_field(Azusa.Bloomburg, Minto);
    modify_field(Azusa.Curtin, Tornillo);
    modify_field(Azusa.Mishicot, Woodsboro);
}

@pragma command_line --no-dead-code-elimination
table Forepaugh {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Euren;
    }
    size : Tascosa;
}

control Jarrell {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Forepaugh);
    }
}





action Sudbury(Dilia) {
   modify_field( Macksburg.Exton, 1 );
   modify_field( Macksburg.Poland, Dilia);
   modify_field( Rhodell.Seguin, 1 );
}

action Bondad() {
   modify_field( Rhodell.Pikeville, 1 );
   modify_field( Rhodell.Sisters, 1 );
}

action Puyallup() {
   modify_field( Rhodell.Seguin, 1 );
}

action Nooksack() {
   modify_field( Rhodell.Coconut, 1 );
}

action Basco() {
   modify_field( Rhodell.Sisters, 1 );
}


table Westtown {
   reads {
      WhiteOwl.Putnam : ternary;
      WhiteOwl.Stanwood : ternary;
   }

   actions {
      Sudbury;
      Bondad;
      Puyallup;
      Nooksack;
      Basco;
   }
   default_action : Basco;
   size : Soledad;
}

action Oklahoma() {
   modify_field( Rhodell.UnionGap, 1 );
}


table Surrey {
   reads {
      WhiteOwl.National : ternary;
      WhiteOwl.Rohwer : ternary;
   }

   actions {
      Oklahoma;
   }
   size : Leacock;
}


control Angus {
   apply( Westtown );
   apply( Surrey );
}




action Higgston() {
   modify_field( Cascadia.Coamo, Kellner.Natalia );
   modify_field( Cascadia.Sherrill, Kellner.Everetts );
   modify_field( Cascadia.Tennessee, Kellner.Saxis );
   modify_field( WestLawn.TroutRun, Corry.Kenova );
   modify_field( WestLawn.Almelund, Corry.Verdemont );
   modify_field( WestLawn.Flomaton, Corry.Natalbany );


   modify_field( Rhodell.Tulsa, Burrel.Putnam );
   modify_field( Rhodell.Belmore, Burrel.Stanwood );
   modify_field( Rhodell.Boquet, Burrel.National );
   modify_field( Rhodell.Alvwood, Burrel.Rohwer );
   modify_field( Rhodell.Elmdale, Burrel.Weleetka );
   modify_field( Rhodell.Westel, Miller.Joslin );
   modify_field( Rhodell.Adamstown, Miller.Alakanuk );
   modify_field( Rhodell.Bowden, Miller.Gifford );
   modify_field( Rhodell.Brothers, Miller.Shobonier );
   modify_field( Rhodell.Hiseville, Miller.Conger );
}

action Hanahan() {
   modify_field( Rhodell.Bigspring, Johnsburg );
   modify_field( Cascadia.Coamo, Sardinia.Natalia );
   modify_field( Cascadia.Sherrill, Sardinia.Everetts );
   modify_field( Cascadia.Tennessee, Sardinia.Saxis );
   modify_field( WestLawn.TroutRun, Atlas.Kenova );
   modify_field( WestLawn.Almelund, Atlas.Verdemont );
   modify_field( WestLawn.Flomaton, Atlas.Natalbany );


   modify_field( Rhodell.Tulsa, WhiteOwl.Putnam );
   modify_field( Rhodell.Belmore, WhiteOwl.Stanwood );
   modify_field( Rhodell.Boquet, WhiteOwl.National );
   modify_field( Rhodell.Alvwood, WhiteOwl.Rohwer );
   modify_field( Rhodell.Elmdale, WhiteOwl.Weleetka );
   modify_field( Rhodell.Westel, Miller.Bushland );
   modify_field( Rhodell.Adamstown, Miller.Tarnov );
   modify_field( Rhodell.Bowden, Miller.Moreland );
   modify_field( Rhodell.Brothers, Miller.Wolford );
   modify_field( Rhodell.Hiseville, Miller.Farthing );
}

table Glouster {
   reads {
      WhiteOwl.Putnam : exact;
      WhiteOwl.Stanwood : exact;
      Sardinia.Everetts : exact;
      Rhodell.Bigspring : exact;
   }

   actions {
      Higgston;
      Hanahan;
   }

   default_action : Hanahan();
   size : Abbyville;
}


action McBrides() {
   modify_field( Rhodell.Twisp, Azusa.Criner );
   modify_field( Rhodell.Holladay, Azusa.Dunnegan);
}

action Scranton( BigPlain ) {
   modify_field( Rhodell.Twisp, BigPlain );
   modify_field( Rhodell.Holladay, Azusa.Dunnegan);
}

action Colburn() {
   modify_field( Rhodell.Twisp, Talbert[0].Sandoval );
   modify_field( Rhodell.Holladay, Azusa.Dunnegan);
}

table Flynn {
   reads {
      Azusa.Dunnegan : ternary;
      Talbert[0] : valid;
      Talbert[0].Sandoval : ternary;
   }

   actions {
      McBrides;
      Scranton;
      Colburn;
   }
   size : Martelle;
}

action Elmwood( Cairo ) {
   modify_field( Rhodell.Holladay, Cairo );
}

action Maljamar() {

   modify_field( Rhodell.Pimento, 1 );
   modify_field( Aguilar.Uhland,
                 Inverness );
}

table Colstrip {
   reads {
      Sardinia.Natalia : exact;
   }

   actions {
      Elmwood;
      Maljamar;
   }
   default_action : Maljamar;
   size : Gaston;
}

action Newburgh( Kempner, Hilbert, Green, DeKalb, Berenice,
                        Greycliff, Pumphrey ) {
   modify_field( Rhodell.Twisp, Kempner );
   modify_field( Rhodell.Lafourche, Pumphrey );
   Knierim(Hilbert, Green, DeKalb, Berenice,
                        Greycliff );
}

action Robins() {
   modify_field( Rhodell.Essex, 1 );
}

table Telida {
   reads {
      Breese.Pittsburg : exact;
   }

   actions {
      Newburgh;
      Robins;
   }
   size : Champlain;
}

action Knierim(Hilbert, Green, DeKalb, Berenice,
                        Greycliff ) {
   modify_field( Blackwood.Arvonia, Hilbert );
   modify_field( Blackwood.Gallinas, Green );
   modify_field( Blackwood.Potter, DeKalb );
   modify_field( Blackwood.WebbCity, Berenice );
   modify_field( Blackwood.Darmstadt, Greycliff );
}

action Barstow(Hilbert, Green, DeKalb, Berenice,
                        Greycliff ) {
   modify_field( Rhodell.Chouteau, Azusa.Criner );
   modify_field( Rhodell.Lafourche, 1 );
   Knierim(Hilbert, Green, DeKalb, Berenice,
                        Greycliff );
}

action Norwood(Bratt, Hilbert, Green, DeKalb,
                        Berenice, Greycliff ) {
   modify_field( Rhodell.Chouteau, Bratt );
   modify_field( Rhodell.Lafourche, 1 );
   Knierim(Hilbert, Green, DeKalb, Berenice,
                        Greycliff );
}

action Harviell(Hilbert, Green, DeKalb, Berenice,
                        Greycliff ) {
   modify_field( Rhodell.Chouteau, Talbert[0].Sandoval );
   modify_field( Rhodell.Lafourche, 1 );
   Knierim(Hilbert, Green, DeKalb, Berenice,
                        Greycliff );
}

table McCartys {
   reads {
      Azusa.Criner : exact;
   }

   actions {
      Barstow;
   }

   size : Cassa;
}

table ElJebel {
   reads {
      Azusa.Dunnegan : exact;
      Talbert[0].Sandoval : exact;
   }

   actions {
      Norwood;
      Glazier;
   }
   default_action : Glazier;

   size : Sparland;
}

table Parole {
   reads {
      Talbert[0].Sandoval : exact;
   }

   actions {
      Harviell;
   }

   size : DeSart;
}

action Annville() {
   modify_field( Rhodell.Slinger, Sardinia.Saxis );
}

action Corona() {
   modify_field( Rhodell.Slinger, Atlas.Thurmond );
}

action Ganado() {
   modify_field( Rhodell.Slinger, Kellner.Saxis );
}

action Stidham() {
   modify_field( Rhodell.Slinger, Corry.Thurmond );
}

table Eldred {
   reads {
      Rhodell.Bigspring : exact;
      Sardinia.valid : exact;
      Atlas.valid : exact;
      Kellner.valid : exact;
      Corry.valid : exact;
   }

   actions {
      Ganado;
      Stidham;
      Annville;
      Corona;
   }

   size : 4;

}

control Diana {
   apply( Glouster ) {
         Higgston {
            apply( Colstrip );
            apply( Telida );
         }
         Hanahan {
            if ( Azusa.Bloomburg == 1 ) {
               apply( Flynn );
            }
            if ( valid( Talbert[ 0 ] ) ) {

               apply( ElJebel ) {
                  Glazier {

                     apply( Parole );
                  }
               }
            } else {

               apply( McCartys );
            }
         }
   }
   apply( Eldred );
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Newfane {
    width  : 1;
    static : Naguabo;
    instance_count : 262144;
}

register Sonora {
    width  : 1;
    static : McKee;
    instance_count : 262144;
}

blackbox stateful_alu Exeter {
    reg : Newfane;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Uvalde.Seagrove;
}

blackbox stateful_alu Ackerman {
    reg : Sonora;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Uvalde.Scotland;
}

field_list LaPlata {
    Azusa.Mishicot;
    Talbert[0].Sandoval;
}

field_list_calculation Polkville {
    input { LaPlata; }
    algorithm: identity;
    output_width: 18;
}

action Palmdale() {
    Exeter.execute_stateful_alu_from_hash(Polkville);
}

action Lucien() {
    Ackerman.execute_stateful_alu_from_hash(Polkville);
}

table Naguabo {
    actions {
      Palmdale;
    }
    default_action : Palmdale;
    size : 1;
}

table McKee {
    actions {
      Lucien;
    }
    default_action : Lucien;
    size : 1;
}
#endif

action Carrizozo(Lyman) {
    modify_field(Uvalde.Scotland, Lyman);
}

@pragma  use_hash_action 0
table KawCity {
    reads {
       Azusa.Mishicot : exact;
    }
    actions {
      Carrizozo;
    }
    size : 64;
}

action Mertens() {
   modify_field( Rhodell.Forkville, Azusa.Criner );
   modify_field( Rhodell.Pilar, 0 );
}

table Kremlin {
   actions {
      Mertens;
   }
   size : 1;
}

action Boring() {
   modify_field( Rhodell.Forkville, Talbert[0].Sandoval );
   modify_field( Rhodell.Pilar, 1 );
}

table Jenison {
   actions {
      Boring;
   }
   size : 1;
}

control Satanta {
   if ( valid( Talbert[ 0 ] ) ) {
      apply( Jenison );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Azusa.Curtin == 1 ) {
         apply( Naguabo );
         apply( McKee );
      }
#endif
   } else {
      apply( Kremlin );
      if( Azusa.Curtin == 1 ) {
         apply( KawCity );
      }
   }
}




field_list Emsworth {
   WhiteOwl.Putnam;
   WhiteOwl.Stanwood;
   WhiteOwl.National;
   WhiteOwl.Rohwer;
   WhiteOwl.Weleetka;
}

field_list Glyndon {

   Sardinia.Stovall;
   Sardinia.Natalia;
   Sardinia.Everetts;
}

field_list Elkland {
   Atlas.Kenova;
   Atlas.Verdemont;
   Atlas.Natalbany;
   Atlas.Bosco;
}

field_list Harvey {
   Sardinia.Stovall;
   Sardinia.Natalia;
   Sardinia.Everetts;
   Nuangola.Cammal;
   Nuangola.Hutchings;
}





field_list_calculation RioHondo {
    input {
        Emsworth;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Onset {
    input {
        Glyndon;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Kapowsin {
    input {
        Elkland;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Noorvik {
    input {
        Harvey;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Bremond() {
    modify_field_with_hash_based_offset(Halley.Conda, 0,
                                        RioHondo, 4294967296);
}

action Stoystown() {
    modify_field_with_hash_based_offset(Halley.Corder, 0,
                                        Onset, 4294967296);
}

action Pickering() {
    modify_field_with_hash_based_offset(Halley.Corder, 0,
                                        Kapowsin, 4294967296);
}

action Bethayres() {
    modify_field_with_hash_based_offset(Halley.Wickett, 0,
                                        Noorvik, 4294967296);
}

table Swifton {
   actions {
      Bremond;
   }
   size: 1;
}

control Kneeland {
   apply(Swifton);
}

table Oxnard {
   actions {
      Stoystown;
   }
   size: 1;
}

table Billett {
   actions {
      Pickering;
   }
   size: 1;
}

control Paoli {
   if ( valid( Sardinia ) ) {
      apply(Oxnard);
   } else {
      if ( valid( Atlas ) ) {
         apply(Billett);
      }
   }
}

table Anita {
   actions {
      Bethayres;
   }
   size: 1;
}

control Tiller {
   if ( valid( Nuangola ) ) {
      apply(Anita);
   }
}



action Caban() {
    modify_field(Crump.Ravinia, Halley.Conda);
}

action Jones() {
    modify_field(Crump.Ravinia, Halley.Corder);
}

action Arbyrd() {
    modify_field(Crump.Ravinia, Halley.Wickett);
}

@pragma immediate 0
table Energy {
   reads {
      Cowpens.valid : ternary;
      BigBay.valid : ternary;
      Kellner.valid : ternary;
      Corry.valid : ternary;
      Burrel.valid : ternary;
      Jemison.valid : ternary;
      Nuangola.valid : ternary;
      Sardinia.valid : ternary;
      Atlas.valid : ternary;
      WhiteOwl.valid : ternary;
   }
   actions {
      Caban;
      Jones;
      Arbyrd;
      Glazier;
   }
   default_action : Glazier();
   size: Kirkwood;
}

control Harriston {
   apply(Energy);
}





counter Amanda {
   type : packets_and_bytes;
   direct : Sully;
   min_width: 16;
}

action WestEnd() {
   modify_field(Rhodell.Wauseon, 1 );
}

table Sully {
   reads {
      Azusa.Mishicot : exact;
      Uvalde.Scotland : ternary;
      Uvalde.Seagrove : ternary;
      Rhodell.Essex : ternary;
      Rhodell.UnionGap : ternary;
      Rhodell.Pikeville : ternary;
   }

   actions {
      WestEnd;
      Glazier;
   }
   default_action : Glazier;
   size : Tennyson;
}

register Hobson {
   width: 1;
   static: Chappell;
   instance_count: Tinsman;
}

#ifdef __TARGET_TOFINO__
blackbox stateful_alu Warsaw{
    reg: Hobson;
    update_lo_1_value: set_bit;
}
#endif

action Jamesport(Davant) {
#if defined(BMV2) || defined(BMV2TOFINO)
   register_write(Hobson, Davant, 1);
#else
   Warsaw.execute_stateful_alu();
#endif

}

action Lesley() {

   modify_field(Rhodell.Loysburg, 1 );
   modify_field(Aguilar.Uhland,
                Toccopola);
}

table Chappell {
   reads {
      Rhodell.Boquet : exact;
      Rhodell.Alvwood : exact;
      Rhodell.Twisp : exact;
      Rhodell.Holladay : exact;
   }

   actions {
      Jamesport;
      Lesley;
   }
   size : Tinsman;
}

action Onawa() {
   modify_field( Blackwood.Colonie, 1 );
}

table Blevins {
   reads {
      Rhodell.Chouteau : ternary;
      Rhodell.Tulsa : exact;
      Rhodell.Belmore : exact;
   }
   actions {
      Onawa;
   }
   size: Lecompte;
}

control Cartago {
   if( Rhodell.Wauseon == 0 ) {
      apply( Blevins );
   }
}

control Devers {
   apply( Sully ) {
      Glazier {



         if (Azusa.Stratford == 0 and Rhodell.Pimento == 0) {
            apply( Chappell );
         }
         apply(Blevins);
      }
   }
}

field_list Burgess {
    Aguilar.Uhland;
    Rhodell.Boquet;
    Rhodell.Alvwood;
    Rhodell.Twisp;
    Rhodell.Holladay;
}

action Hewins() {
   generate_digest(Hebbville, Burgess);
}

table Longhurst {
   actions {
      Hewins;
   }
   size : 1;
}

control Marcus {
   if (Rhodell.Loysburg == 1) {
      apply( Longhurst );
   }
}



action Maybee( Heflin ) {
   modify_field( WestLawn.Greer, Heflin );
}

table Holyrood {

   reads {
      Blackwood.Arvonia : exact;
      WestLawn.Almelund : lpm;
   }

   actions {
      Maybee;
      Glazier;
   }

   default_action : Glazier();
   size : Hartville;
}

@pragma atcam_partition_index WestLawn.Greer
@pragma atcam_number_partitions Hartville
table Tallassee {
   reads {
      WestLawn.Greer : exact;


      WestLawn.Almelund mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Alston;
      Glazier;
   }

   default_action : Glazier();
   size : Dunken;
}

@pragma idletime_precision 1
table Ricketts {

   reads {
      Blackwood.Arvonia : exact;
      Cascadia.Sherrill : lpm;
   }

   actions {
      Alston;
      Glazier;
   }

   default_action : Glazier();
   size : LaUnion;
   support_timeout : true;
}

action Gibbs(Denhoff) {
   modify_field(Cascadia.Parkville, Denhoff);
}

table Fieldon {
   reads {
      Blackwood.Arvonia : exact;
      Cascadia.Sherrill : lpm;
   }

   actions {
      Gibbs;
   }

   size : Frederika;
}

@pragma atcam_partition_index Cascadia.Parkville
@pragma atcam_number_partitions Frederika
table Gorum {
   reads {
      Cascadia.Parkville : exact;



      Cascadia.Sherrill mask 0x000fffff : lpm;
   }
   actions {
      Alston;
      Glazier;
   }

   size : Hayward;
}

action Alston( Henrietta ) {
   modify_field( Macksburg.RioPecos, 1 );
   modify_field( Olivet.Rockvale, Henrietta );
}

@pragma idletime_precision 1
table Waring {
   reads {
      Blackwood.Arvonia : exact;
      Cascadia.Sherrill : exact;
   }

   actions {
      Alston;
      Glazier;
   }
   default_action : Glazier();
   size : Valdosta;
   support_timeout : true;
}

@pragma idletime_precision 1
table Melder {
   reads {
      Blackwood.Arvonia : exact;
      WestLawn.Almelund : exact;
   }

   actions {
      Alston;
      Glazier;
   }
   default_action : Glazier();
   size : Nisland;
   support_timeout : true;
}

action Barnsboro(Ladner, Millstadt, Worland) {
   modify_field(Macksburg.BigRiver, Worland);
   modify_field(Macksburg.Matheson, Ladner);
   modify_field(Macksburg.RedLevel, Millstadt);
   modify_field(Macksburg.RioPecos, 1);
}

table Hayfield {
   reads {
      Olivet.Rockvale : exact;
   }

   actions {
      Barnsboro;
   }
   size : Darco;
}

control Parmelee {
   apply( Fieldon );
   if ( Rhodell.Wauseon == 0 and Blackwood.Colonie == 1 ) {
      if ( ( Blackwood.Gallinas == 1 ) and ( Rhodell.Brothers == 1 ) ) {
         apply( Waring ) {
            Glazier {
               if( Cascadia.Parkville != 0 ) {
                  apply( Gorum );
               }
               if (Olivet.Rockvale == 0 ) {
                  apply( Ricketts );
               }
            }
         }
      } else if ( ( Blackwood.Potter == 1 ) and ( Rhodell.Hiseville == 1 ) ) {
         apply( Melder ) {
            Glazier {
               apply( Holyrood ) {
                  Maybee {
                     apply( Tallassee );
                  }
               }
            }
         }
      }
   }
}

control Westline {
   if( Olivet.Rockvale != 0 ) {
      apply( Hayfield );
   }
}



field_list FourTown {
   Crump.Ravinia;
}

field_list_calculation Panola {
    input {
        FourTown;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Skyforest {
    selection_key : Panola;
    selection_mode : resilient;
}

action Inola(Yatesboro) {
   modify_field(Macksburg.Poteet, Yatesboro);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Yatesboro);
}

action_profile Picayune {
    actions {
        Inola;
        Glazier;
    }
    size : Center;
    dynamic_action_selection : Skyforest;
}

table Leucadia {
   reads {
      Macksburg.Poteet : exact;
   }
   action_profile: Picayune;
   size : Norfork;
}

control Novinger {
   if ((Rhodell.Wauseon == 0) and (Macksburg.Poteet & 0x2000) == 0x2000) {
      apply(Leucadia);
   }
}



action Lathrop() {
   modify_field(Macksburg.Matheson, Rhodell.Tulsa);
   modify_field(Macksburg.RedLevel, Rhodell.Belmore);
   modify_field(Macksburg.Alcoma, Rhodell.Boquet);
   modify_field(Macksburg.Fernway, Rhodell.Alvwood);
   modify_field(Macksburg.BigRiver, Rhodell.Twisp);
}

table Cornwall {
   actions {
      Lathrop;
   }
   default_action : Lathrop();
   size : 1;
}

control Tullytown {
   if (Rhodell.Twisp!=0) {
      apply( Cornwall );
   }
}

action Lambert() {
   modify_field(Macksburg.Brookneal, 1);
   modify_field(Macksburg.Roseau, 1);
   modify_field(Macksburg.Dorothy, Macksburg.BigRiver);
}

action Cheyenne() {
}



@pragma ways 1
table Kosmos {
   reads {
      Macksburg.Matheson : exact;
      Macksburg.RedLevel : exact;
   }
   actions {
      Lambert;
      Cheyenne;
   }
   default_action : Cheyenne;
   size : 1;
}

action Naylor() {
   modify_field(Macksburg.Farragut, 1);
   modify_field(Macksburg.Nettleton, 1);
   add(Macksburg.Dorothy, Macksburg.BigRiver, Demarest);
}

table Monahans {
   actions {
      Naylor;
   }
   default_action : Naylor;
   size : 1;
}

action Brewerton() {
   modify_field(Macksburg.Arkoe, 1);
   modify_field(Macksburg.Dorothy, Macksburg.BigRiver);
}

table Choudrant {
   actions {
      Brewerton;
   }
   default_action : Brewerton();
   size : 1;
}

action Dalkeith(Sturgis) {
   modify_field(Macksburg.Pettry, 1);
   modify_field(Macksburg.Poteet, Sturgis);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Sturgis);
}

action Peoria(Pilger) {
   modify_field(Macksburg.Farragut, 1);
   modify_field(Macksburg.Dorothy, Pilger);
}

action Wenona() {
}

table Charco {
   reads {
      Macksburg.Matheson : exact;
      Macksburg.RedLevel : exact;
      Macksburg.BigRiver : exact;
   }

   actions {
      Dalkeith;
      Peoria;
      Wenona;
   }
   default_action : Wenona();
   size : Wauneta;
}

control Watters {
   if (Rhodell.Wauseon == 0) {
      apply(Charco) {
         Wenona {
            apply(Kosmos) {
               Cheyenne {
                  if ((Macksburg.Matheson & 0x010000) == 0x010000) {
                     apply(Monahans);
                  } else {
                     apply(Choudrant);
                  }
               }
            }
         }
      }
   }
}


action Hanks() {
   modify_field(Rhodell.Wauseon, 1);
}

table Hadley {
   actions {
      Hanks;
   }
   default_action : Hanks;
   size : 1;
}

control Goldman {
   if ((Macksburg.RioPecos==0) and (Rhodell.Holladay==Macksburg.Poteet)) {
      apply(Hadley);
   }
}



action Dorset( Corfu ) {
   modify_field( Macksburg.Hopeton, Corfu );
}

action Hines() {
   modify_field( Macksburg.Hopeton, Macksburg.BigRiver );
}

table HillTop {
   reads {
      eg_intr_md.egress_port : exact;
      Macksburg.BigRiver : exact;
   }

   actions {
      Dorset;
      Hines;
   }
   default_action : Hines;
   size : Nursery;
}

control Sublimity {
   apply( HillTop );
}



action Nucla( Haverford, Sandston ) {
   modify_field( Macksburg.Delavan, Haverford );
   modify_field( Macksburg.WestPark, Sandston );
}


table Mynard {
   reads {
      Macksburg.Morgana : exact;
   }

   actions {
      Nucla;
   }
   size : Brainard;
}

action Auvergne() {
   no_op();
}

action Traverse() {
   modify_field( WhiteOwl.Weleetka, Talbert[0].Berville );
   remove_header( Talbert[0] );
}

table Almedia {
   actions {
      Traverse;
   }
   default_action : Traverse;
   size : Eaton;
}

action Chemult() {
   no_op();
}

action Childs() {
   add_header( Talbert[ 0 ] );
   modify_field( Talbert[0].Sandoval, Macksburg.Hopeton );
   modify_field( Talbert[0].Berville, WhiteOwl.Weleetka );
   modify_field( WhiteOwl.Weleetka, Moxley );
}



table Aylmer {
   reads {
      Macksburg.Hopeton : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Chemult;
      Childs;
   }
   default_action : Childs;
   size : Quivero;
}

action Tigard() {
   modify_field(WhiteOwl.Putnam, Macksburg.Matheson);
   modify_field(WhiteOwl.Stanwood, Macksburg.RedLevel);
   modify_field(WhiteOwl.National, Macksburg.Delavan);
   modify_field(WhiteOwl.Rohwer, Macksburg.WestPark);
}

action Toano() {
   Tigard();
   add_to_field(Sardinia.Decherd, -1);
}

action Gracewood() {
   Tigard();
   add_to_field(Atlas.Somis, -1);
}






@pragma stage 2
table Coulee {
   reads {
      Macksburg.Lakeside : exact;
      Macksburg.Morgana : exact;
      Macksburg.RioPecos : exact;
      Sardinia.valid : ternary;
      Atlas.valid : ternary;
   }

   actions {
      Toano;
      Gracewood;
   }
   size : Pickett;
}

control Ardara {
   apply( Almedia );
}

control Aldrich {
   apply( Aylmer );
}

control Paradise {
   apply( Mynard );
   apply( Coulee );
}



field_list Callimont {
    Aguilar.Uhland;
    Rhodell.Twisp;
    Burrel.National;
    Burrel.Rohwer;
    Sardinia.Natalia;
}

action Courtdale() {
   generate_digest(Hebbville, Callimont);
}

table Freedom {
   actions {
      Courtdale;
   }

   default_action : Courtdale;
   size : 1;
}

control Nanson {
   if (Rhodell.Pimento == 1) {
      apply(Freedom);
   }
}

control ingress {

   Jarrell();
   Angus();
   Diana();
   Satanta();
   Kneeland();


   Devers();

   Paoli();
   Tiller();


   Parmelee();

   Tullytown();

   Westline();


   Harriston();



   Watters();


   Goldman();
   Nanson();
   Marcus();


   if( valid( Talbert[0] ) ) {
      Ardara();
   }


   Novinger();
}

control egress {
   Sublimity();
   Paradise();
   Aldrich();
}

