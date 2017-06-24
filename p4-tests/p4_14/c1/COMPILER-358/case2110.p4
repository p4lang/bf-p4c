// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 132830







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>



#ifndef Academy
#define Academy

header_type Bennet {
	fields {
		Hookstown : 16;
		Chambers : 16;
		Wartrace : 8;
		Embarrass : 8;
		Stoystown : 8;
		Alvord : 8;
		Clearmont : 1;
		Sudbury : 1;
		Nightmute : 1;
		Kaanapali : 1;
		Rampart : 1;
		Bufalo : 3;
	}
}

header_type Berlin {
	fields {
		Edinburgh : 24;
		Elvaston : 24;
		Amanda : 24;
		Waucousta : 24;
		Purves : 16;
		Jermyn : 16;
		Tascosa : 16;
		Braselton : 16;
		Penrose : 16;
		ElkMills : 8;
		Tiller : 8;
		Crowheart : 6;
		Trout : 1;
		Sedan : 1;
		McAllen : 12;
		Trion : 2;
		Covington : 1;
		Sebewaing : 1;
		Rockport : 1;
		Hindman : 1;
		Talent : 1;
		Coamo : 1;
		Idalia : 1;
		Horton : 1;
		Creston : 1;
		Arion : 1;
		Stout : 1;
		Okarche : 1;
		RedLake : 1;
		Riner : 3;
	}
}

header_type Pembine {
	fields {
		Provencal : 24;
		Hiland : 24;
		Ocheyedan : 24;
		Cairo : 24;
		Leeville : 24;
		Castle : 24;
		Kneeland : 16;
		Mishawaka : 16;
		Bladen : 16;
		Lapoint : 16;
		Bigfork : 12;
		LeSueur : 3;
		Chouteau : 3;
		Power : 1;
		Sultana : 1;
		Witherbee : 1;
		Tafton : 1;
		Parole : 1;
		Chloride : 1;
		Quivero : 1;
		Wheaton : 1;
		Mabana : 8;
	}
}


header_type Marysvale {
	fields {
		Halltown : 8;
		Allgood : 1;
		Lugert : 1;
		Virden : 1;
		Noonan : 1;
		Varnell : 1;
		Kapaa : 1;
	}
}

header_type Tenstrike {
	fields {
		Bloomburg : 32;
		Youngtown : 32;
		Dunnegan : 6;
		ElMirage : 16;
	}
}

header_type Lanesboro {
	fields {
		Palco : 128;
		IowaCity : 128;
		Rosario : 20;
		Burtrum : 8;
		Jenison : 11;
		Matador : 8;
		Merritt : 13;
	}
}

header_type Sawpit {
	fields {
		Almedia : 14;
		Everest : 1;
		Ottertail : 12;
		Taopi : 1;
		Korona : 1;
		Lamont : 6;
		Triplett : 2;
		Piketon : 6;
		Mammoth : 3;
	}
}

header_type Milam {
	fields {
		Cement : 1;
		Choptank : 1;
	}
}

header_type Reynolds {
	fields {
		Florala : 8;
	}
}

header_type Janney {
	fields {
		Rattan : 16;
		Bayville : 11;
	}
}

header_type Charenton {
	fields {
		Neavitt : 32;
		Petrolia : 32;
		Lauada : 32;
	}
}

header_type Chilson {
	fields {
		MudLake : 32;
		Elwood : 32;
	}
}

header_type Bridger {
	fields {
		Ickesburg : 2;
	}
}
#endif



#ifndef Raytown
#define Raytown



header_type Agency {
	fields {
		Panola : 24;
		Pierson : 24;
		Snowball : 24;
		Waipahu : 24;
		Knolls : 16;
	}
}



header_type Broussard {
	fields {
		Dixon : 3;
		Bozar : 1;
		Holliday : 12;
		Layton : 16;
	}
}



header_type Colona {
	fields {
		Headland : 4;
		Gilmanton : 4;
		Guadalupe : 6;
		Daleville : 2;
		Gastonia : 16;
		Kaluaaha : 16;
		Leucadia : 3;
		Pownal : 13;
		Arthur : 8;
		Crary : 8;
		Calcium : 16;
		Norwood : 32;
		Lofgreen : 32;
	}
}

header_type Neoga {
	fields {
		Phelps : 4;
		Callery : 6;
		BigLake : 2;
		Herring : 20;
		Pound : 16;
		Graford : 8;
		Paisano : 8;
		LaPalma : 128;
		Quarry : 128;
	}
}




header_type Anchorage {
	fields {
		Gallion : 8;
		Burrel : 8;
		Brookland : 16;
	}
}

header_type Tolono {
	fields {
		Poulsbo : 16;
		Pittsboro : 16;
		Wallace : 32;
		Abernant : 32;
		DeLancey : 4;
		Chalco : 4;
		Shawmut : 8;
		Perryman : 16;
		Unionvale : 16;
		Thaxton : 16;
	}
}

header_type Euren {
	fields {
		Scarville : 16;
		PoleOjea : 16;
		Dasher : 16;
		Cowden : 16;
	}
}



header_type RockHill {
	fields {
		Bassett : 16;
		Corfu : 16;
		Philbrook : 8;
		Moorpark : 8;
		Gervais : 16;
	}
}

header_type Absarokee {
	fields {
		Cutten : 48;
		Odell : 32;
		Antonito : 48;
		Doerun : 32;
	}
}



header_type Sagerton {
	fields {
		Nettleton : 1;
		Accomac : 1;
		McFaddin : 1;
		Huxley : 1;
		Pridgen : 1;
		Penitas : 3;
		Vestaburg : 5;
		Fittstown : 3;
		Odenton : 16;
	}
}

header_type Sherando {
	fields {
		Opelousas : 24;
		Bowlus : 8;
	}
}



header_type Crane {
	fields {
		Clintwood : 8;
		Hebbville : 24;
		Elkton : 24;
		Maceo : 8;
	}
}

#endif



#ifndef Wapato
#define Wapato

parser start {
   return Winger;
}

#define Reydon        0x8100
#define Olmitz        0x0800
#define Flomaton        0x86dd
#define Placedo        0x9100
#define Wanilla        0x8847
#define Penzance         0x0806
#define Sidnaw        0x8035
#define Strevell        0x88cc
#define Clearlake        0x8809

#define Owyhee              1
#define Staunton              2
#define Waterford              4
#define Wildell               6
#define Oronogo               17
#define Bremond                47

#define Corbin         0x501
#define Emmalane          0x506
#define Baker          0x511
#define Gypsum          0x52F


#define Margie                 4789



#define Bruce               0
#define Opelika              1
#define Donegal                2



#define LaneCity          0
#define Pengilly          4095
#define Mulhall  4096
#define Kenney  8191



#define Fireco                      0
#define Naubinway                  0
#define Collis                 1

header Agency Nuremberg;
header Agency Gerty;
header Broussard Kinston[ 2 ];
header Colona Aredale;
header Colona Yardville;
header Neoga Silesia;
header Neoga Ackerman;
header Tolono Cankton;
header Euren Hitchland;
header Tolono Palmer;
header Euren Quijotoa;
header Crane Cantwell;
header RockHill McCallum;
header Sagerton Baird;

parser Winger {
   extract( Nuremberg );
   return select( Nuremberg.Knolls ) {
      Reydon : Valeene;
      Olmitz : BigRock;
      Flomaton : Seagate;
      Penzance  : Doyline;
      default        : ingress;
   }
}

parser Valeene {
   extract( Kinston[0] );


   set_metadata(Redmon.Rampart, 1);
   return select( Kinston[0].Layton ) {
      Olmitz : BigRock;
      Flomaton : Seagate;
      Penzance  : Doyline;
      default : ingress;
   }
}

parser BigRock {
   extract( Aredale );
   set_metadata(Redmon.Wartrace, Aredale.Crary);
   set_metadata(Redmon.Stoystown, Aredale.Arthur);
   set_metadata(Redmon.Hookstown, Aredale.Gastonia);
   set_metadata(Redmon.Nightmute, 0);
   set_metadata(Redmon.Clearmont, 1);
   return select(Aredale.Pownal, Aredale.Gilmanton, Aredale.Crary) {
      Baker : TiffCity;
      default : ingress;
   }
}

parser Seagate {
   extract( Ackerman );
   set_metadata(Redmon.Wartrace, Ackerman.Graford);
   set_metadata(Redmon.Stoystown, Ackerman.Paisano);
   set_metadata(Redmon.Hookstown, Ackerman.Pound);
   set_metadata(Redmon.Nightmute, 1);
   set_metadata(Redmon.Clearmont, 0);
   return ingress;
}

parser Doyline {
   extract( McCallum );
   return ingress;
}

parser TiffCity {
   extract(Hitchland);
   return select(Hitchland.PoleOjea) {
      Margie : Oreland;
      default : ingress;
    }
}

parser Vibbard {
   set_metadata(Seagrove.Trion, Donegal);
   return Sheldahl;
}

parser Rockdale {
   set_metadata(Seagrove.Trion, Donegal);
   return Veradale;
}

parser Brookneal {
   extract(Baird);
   return select(Baird.Nettleton, Baird.Accomac, Baird.McFaddin, Baird.Huxley, Baird.Pridgen,
             Baird.Penitas, Baird.Vestaburg, Baird.Fittstown, Baird.Odenton) {
      Olmitz : Vibbard;
      Flomaton : Rockdale;
      default : ingress;
   }
}

parser Oreland {
   extract(Cantwell);
   set_metadata(Seagrove.Trion, Opelika);
   return Winnebago;
}

parser Sheldahl {
   extract( Yardville );
   set_metadata(Redmon.Embarrass, Yardville.Crary);
   set_metadata(Redmon.Alvord, Yardville.Arthur);
   set_metadata(Redmon.Chambers, Yardville.Gastonia);
   set_metadata(Redmon.Kaanapali, 0);
   set_metadata(Redmon.Sudbury, 1);
   return ingress;
}

parser Veradale {
   extract( Silesia );
   set_metadata(Redmon.Embarrass, Silesia.Graford);
   set_metadata(Redmon.Alvord, Silesia.Paisano);
   set_metadata(Redmon.Chambers, Silesia.Pound);
   set_metadata(Redmon.Kaanapali, 1);
   set_metadata(Redmon.Sudbury, 0);
   return ingress;
}

parser Winnebago {
   extract( Gerty );
   return select( Gerty.Knolls ) {
      Olmitz: Sheldahl;
      Flomaton: Veradale;
      default: ingress;
   }
}
#endif

metadata Berlin Seagrove;
metadata Pembine CedarKey;
metadata Sawpit Mapleview;
metadata Bennet Redmon;
metadata Tenstrike Dialville;
metadata Lanesboro Arroyo;
metadata Milam Trammel;
metadata Marysvale Ahuimanu;
metadata Reynolds Yukon;
metadata Janney FairOaks;
metadata Chilson Elmdale;
metadata Charenton Woodfield;
metadata Bridger Durant;













#undef Myton

#undef Duquoin
#undef Gorman
#undef Overbrook
#undef Mogote
#undef Petrey

#undef Martelle
#undef Blanchard
#undef Falmouth

#undef Ironia
#undef Wetonka
#undef Blairsden
#undef Pilar
#undef Harriet
#undef Geneva
#undef Arnold
#undef LakeHart
#undef Whitlash
#undef Pavillion
#undef Farner
#undef Olive
#undef Escondido
#undef Pricedale
#undef Altus
#undef LaFayette
#undef Nanakuli
#undef Pendroy
#undef Somis
#undef Helen
#undef Henry

#undef Gregory
#undef McQueen
#undef Cresco
#undef Greenlawn
#undef SwissAlp
#undef Pacifica
#undef Cuney
#undef McMurray
#undef Tingley
#undef Almont
#undef Millikin
#undef Lyndell
#undef Hewitt
#undef Dalton
#undef ElVerano


#undef Saticoy

#undef Ravinia
#undef Disney
#undef Tulalip
#undef Wamego

#undef Stowe







#define Myton 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Duquoin      65536
#define Gorman      65536
#define Overbrook 512
#define Mogote 512
#define Petrey      512


#define Martelle     1024
#define Blanchard    1024
#define Falmouth     256


#define Ironia 512
#define Wetonka 65536
#define Blairsden 65536
#define Pilar 28672
#define Harriet   16384
#define Geneva 8192
#define Arnold         131072
#define LakeHart 65536
#define Whitlash 1024
#define Pavillion 2048
#define Farner 16384
#define Olive 8192
#define Escondido 65536

#define Pricedale 0x0000000000000000FFFFFFFFFFFFFFFF


#define Altus 0x000fffff
#define Pendroy 2

#define LaFayette 0xFFFFFFFFFFFFFFFF0000000000000000

#define Nanakuli 0x000007FFFFFFFFFF0000000000000000
#define Somis  6
#define Henry        2048
#define Helen       65536


#define Gregory 1024
#define McQueen 4096
#define Cresco 4096
#define Greenlawn 4096
#define SwissAlp 4096
#define Pacifica 1024
#define Cuney 4096
#define Tingley 64
#define Almont 1
#define Millikin  8
#define Lyndell 512


#define Hewitt 1
#define Dalton 3
#define ElVerano 80


#define Saticoy 0



#define Ravinia 2048


#define Disney 4096



#define Tulalip 2048
#define Wamego 4096




#define Stowe    4096

#endif



#ifndef Loring
#define Loring

action Pawtucket() {
   no_op();
}

action Gibson() {
   modify_field(Seagrove.Hindman, 1 );
}

action Wausaukee() {
   no_op();
}
#endif

















action Nederland(Heaton, Almond, Caputa, Netarts, Lamison, Emsworth,
                 McKenna, FortShaw, Cashmere) {
    modify_field(Mapleview.Almedia, Heaton);
    modify_field(Mapleview.Everest, Almond);
    modify_field(Mapleview.Ottertail, Caputa);
    modify_field(Mapleview.Taopi, Netarts);
    modify_field(Mapleview.Korona, Lamison);
    modify_field(Mapleview.Lamont, Emsworth);
    modify_field(Mapleview.Triplett, McKenna);
    modify_field(Mapleview.Mammoth, FortShaw);
    modify_field(Mapleview.Piketon, Cashmere);
}

@pragma command_line --no-dead-code-elimination
table Uniontown {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Nederland;
    }
    size : Myton;
}

control Stella {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Uniontown);
    }
}





action Sarepta(Rosebush) {
   modify_field( CedarKey.Power, 1 );
   modify_field( CedarKey.Mabana, Rosebush);
   modify_field( Seagrove.Arion, 1 );
}

action Colver() {
   modify_field( Seagrove.Idalia, 1 );
   modify_field( Seagrove.Okarche, 1 );
}

action Wolsey() {
   modify_field( Seagrove.Arion, 1 );
}

action McGovern() {
   modify_field( Seagrove.Stout, 1 );
}

action Newcomb() {
   modify_field( Seagrove.Okarche, 1 );
}

counter BigPlain {
   type : packets_and_bytes;
   direct : WestEnd;
   min_width: 16;
}

table WestEnd {
   reads {
      Mapleview.Lamont : exact;
      Nuremberg.Panola : ternary;
      Nuremberg.Pierson : ternary;
   }

   actions {
      Sarepta;
      Colver;
      Wolsey;
      McGovern;
      Newcomb;
   }
   size : Overbrook;
}

action Weslaco() {
   modify_field( Seagrove.Horton, 1 );
}


table Holcomb {
   reads {
      Nuremberg.Snowball : ternary;
      Nuremberg.Waipahu : ternary;
   }

   actions {
      Weslaco;
   }
   size : Mogote;
}


control Iberia {
   apply( WestEnd );
   apply( Holcomb );
}




action Cornudas() {
   modify_field( Dialville.Bloomburg, Yardville.Norwood );
   modify_field( Dialville.Youngtown, Yardville.Lofgreen );
   modify_field( Dialville.Dunnegan, Yardville.Guadalupe );
   modify_field( Arroyo.Palco, Silesia.LaPalma );
   modify_field( Arroyo.IowaCity, Silesia.Quarry );
   modify_field( Arroyo.Rosario, Silesia.Herring );


   modify_field( Seagrove.Edinburgh, Gerty.Panola );
   modify_field( Seagrove.Elvaston, Gerty.Pierson );
   modify_field( Seagrove.Amanda, Gerty.Snowball );
   modify_field( Seagrove.Waucousta, Gerty.Waipahu );
   modify_field( Seagrove.Purves, Gerty.Knolls );
   modify_field( Seagrove.Penrose, Redmon.Chambers );
   modify_field( Seagrove.ElkMills, Redmon.Embarrass );
   modify_field( Seagrove.Tiller, Redmon.Alvord );
   modify_field( Seagrove.Sedan, Redmon.Sudbury );
   modify_field( Seagrove.Trout, Redmon.Kaanapali );
   modify_field( Seagrove.RedLake, 0 );
   modify_field( Mapleview.Triplett, 2 );
   modify_field( Mapleview.Mammoth, 0 );
   modify_field( Mapleview.Piketon, 0 );
}

action DuckHill() {
   modify_field( Seagrove.Trion, Bruce );
   modify_field( Dialville.Bloomburg, Aredale.Norwood );
   modify_field( Dialville.Youngtown, Aredale.Lofgreen );
   modify_field( Dialville.Dunnegan, Aredale.Guadalupe );
   modify_field( Arroyo.Palco, Ackerman.LaPalma );
   modify_field( Arroyo.IowaCity, Ackerman.Quarry );
   modify_field( Arroyo.Rosario, Ackerman.Herring );


   modify_field( Seagrove.Edinburgh, Nuremberg.Panola );
   modify_field( Seagrove.Elvaston, Nuremberg.Pierson );
   modify_field( Seagrove.Amanda, Nuremberg.Snowball );
   modify_field( Seagrove.Waucousta, Nuremberg.Waipahu );
   modify_field( Seagrove.Purves, Nuremberg.Knolls );
   modify_field( Seagrove.Penrose, Redmon.Hookstown );
   modify_field( Seagrove.ElkMills, Redmon.Wartrace );
   modify_field( Seagrove.Tiller, Redmon.Stoystown );
   modify_field( Seagrove.Sedan, Redmon.Clearmont );
   modify_field( Seagrove.Trout, Redmon.Nightmute );
   modify_field( Seagrove.Riner, Redmon.Bufalo );
   modify_field( Seagrove.RedLake, Redmon.Rampart );
}

table BullRun {
   reads {
      Nuremberg.Panola : exact;
      Nuremberg.Pierson : exact;
      Aredale.Lofgreen : exact;
      Seagrove.Trion : exact;
   }

   actions {
      Cornudas;
      DuckHill;
   }

   default_action : DuckHill();
   size : Gregory;
}


action Hershey() {
   modify_field( Seagrove.Jermyn, Mapleview.Ottertail );
   modify_field( Seagrove.Tascosa, Mapleview.Almedia);
}

action DeGraff( Champlain ) {
   modify_field( Seagrove.Jermyn, Champlain );
   modify_field( Seagrove.Tascosa, Mapleview.Almedia);
}

action Frontier() {
   modify_field( Seagrove.Jermyn, Kinston[0].Holliday );
   modify_field( Seagrove.Tascosa, Mapleview.Almedia);
}

table Lodoga {
   reads {
      Mapleview.Almedia : ternary;
      Kinston[0] : valid;
      Kinston[0].Holliday : ternary;
   }

   actions {
      Hershey;
      DeGraff;
      Frontier;
   }
   size : Greenlawn;
}

action Yulee( Hewins ) {
   modify_field( Seagrove.Tascosa, Hewins );
}

action Richvale() {

   modify_field( Seagrove.Rockport, 1 );
   modify_field( Yukon.Florala,
                 Collis );
}

table Wrens {
   reads {
      Aredale.Norwood : exact;
   }

   actions {
      Yulee;
      Richvale;
   }
   default_action : Richvale;
   size : Cresco;
}

action Ridgeland( Mattawan, Ronneby, Dilia, Holyoke, Wibaux,
                        Bouton, Salduro ) {
   modify_field( Seagrove.Jermyn, Mattawan );
   modify_field( Seagrove.Braselton, Mattawan );
   modify_field( Seagrove.Coamo, Salduro );
   Thomas(Ronneby, Dilia, Holyoke, Wibaux,
                        Bouton );
}

action Redondo() {
   modify_field( Seagrove.Talent, 1 );
}

table Crooks {
   reads {
      Cantwell.Elkton : exact;
   }

   actions {
      Ridgeland;
      Redondo;
   }
   size : McQueen;
}

action Thomas(Firesteel, Ishpeming, Igloo, Wetumpka,
                        Springlee ) {
   modify_field( Ahuimanu.Halltown, Firesteel );
   modify_field( Ahuimanu.Allgood, Ishpeming );
   modify_field( Ahuimanu.Virden, Igloo );
   modify_field( Ahuimanu.Lugert, Wetumpka );
   modify_field( Ahuimanu.Noonan, Springlee );
}

action Catskill(Powderly, Sammamish, Mentone, Bernice,
                        Connell ) {
   modify_field( Seagrove.Braselton, Mapleview.Ottertail );
   modify_field( Seagrove.Coamo, 1 );
   Thomas(Powderly, Sammamish, Mentone, Bernice,
                        Connell );
}

action Forman(Hibernia, Hokah, Tillicum, Macedonia,
                        Harts, Arminto ) {
   modify_field( Seagrove.Braselton, Hibernia );
   modify_field( Seagrove.Coamo, 1 );
   Thomas(Hokah, Tillicum, Macedonia, Harts,
                        Arminto );
}

action Maury(Sabina, Johnsburg, Baudette, Edwards,
                        Herod ) {
   modify_field( Seagrove.Braselton, Kinston[0].Holliday );
   modify_field( Seagrove.Coamo, 1 );
   Thomas(Sabina, Johnsburg, Baudette, Edwards,
                        Herod );
}

table Felton {
   reads {
      Mapleview.Ottertail : exact;
   }


   actions {
      Pawtucket;
      Catskill;
   }

   size : SwissAlp;
}

@pragma action_default_only Pawtucket
table Bonduel {
   reads {
      Mapleview.Almedia : exact;
      Kinston[0].Holliday : exact;
   }

   actions {
      Forman;
      Pawtucket;
   }

   size : Pacifica;
}

table BigPiney {
   reads {
      Kinston[0].Holliday : exact;
   }


   actions {
      Pawtucket;
      Maury;
   }

   size : Cuney;
}

control Suarez {
   apply( BullRun ) {
         Cornudas {
            apply( Wrens );
            apply( Crooks );
         }
         DuckHill {
            if ( Mapleview.Taopi == 1 ) {
               apply( Lodoga );
            }
            if ( valid( Kinston[ 0 ] ) ) {

               apply( Bonduel ) {
                  Pawtucket {

                     apply( BigPiney );
                  }
               }
            } else {

               apply( Felton );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Buenos {
    width  : 1;
    static : Kaibab;
    instance_count : 262144;
}

register Tryon {
    width  : 1;
    static : Ivanhoe;
    instance_count : 262144;
}

blackbox stateful_alu Klondike {
    reg : Buenos;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Trammel.Cement;
}

blackbox stateful_alu Theba {
    reg : Tryon;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Trammel.Choptank;
}

field_list Pelland {
    Mapleview.Lamont;
    Kinston[0].Holliday;
}

field_list_calculation Belcher {
    input { Pelland; }
    algorithm: identity;
    output_width: 18;
}

action Cisne() {
    Klondike.execute_stateful_alu_from_hash(Belcher);
}

action Flaxton() {
    Theba.execute_stateful_alu_from_hash(Belcher);
}

table Kaibab {
    actions {
      Cisne;
    }
    default_action : Cisne;
    size : 1;
}

table Ivanhoe {
    actions {
      Flaxton;
    }
    default_action : Flaxton;
    size : 1;
}
#endif

action Prosser(Carlin) {
    modify_field(Trammel.Choptank, Carlin);
}

@pragma  use_hash_action 0
table Meeker {
    reads {
       Mapleview.Lamont : exact;
    }
    actions {
      Prosser;
    }
    size : 64;
}

action Chubbuck() {
   modify_field( Seagrove.McAllen, Mapleview.Ottertail );
   modify_field( Seagrove.Covington, 0 );
}

table Papeton {
   actions {
      Chubbuck;
   }
   size : 1;
}

action Virgil() {
   modify_field( Seagrove.McAllen, Kinston[0].Holliday );
   modify_field( Seagrove.Covington, 1 );
}

table Parkville {
   actions {
      Virgil;
   }
   size : 1;
}

control Sitka {
   if ( valid( Kinston[ 0 ] ) ) {
      apply( Parkville );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Mapleview.Korona == 1 ) {
         apply( Kaibab );
         apply( Ivanhoe );
      }
#endif
   } else {
      apply( Papeton );
      if( Mapleview.Korona == 1 ) {
         apply( Meeker );
      }
   }
}




field_list Amity {
   Nuremberg.Panola;
   Nuremberg.Pierson;
   Nuremberg.Snowball;
   Nuremberg.Waipahu;
   Nuremberg.Knolls;
}

field_list MudButte {

   Aredale.Crary;
   Aredale.Norwood;
   Aredale.Lofgreen;
}

field_list Havana {
   Ackerman.LaPalma;
   Ackerman.Quarry;
   Ackerman.Herring;
   Ackerman.Graford;
}

field_list Melvina {
   Aredale.Norwood;
   Aredale.Lofgreen;
   Hitchland.Scarville;
   Hitchland.PoleOjea;
}





field_list_calculation Annawan {
    input {
        Amity;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Asher {
    input {
        MudButte;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Guion {
    input {
        Havana;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Ihlen {
    input {
        Melvina;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Franklin() {
    modify_field_with_hash_based_offset(Woodfield.Neavitt, 0,
                                        Annawan, 4294967296);
}

action Charters() {
    modify_field_with_hash_based_offset(Woodfield.Petrolia, 0,
                                        Asher, 4294967296);
}

action Carver() {
    modify_field_with_hash_based_offset(Woodfield.Petrolia, 0,
                                        Guion, 4294967296);
}

action Novinger() {
    modify_field_with_hash_based_offset(Woodfield.Lauada, 0,
                                        Ihlen, 4294967296);
}

table Barnsboro {
   actions {
      Franklin;
   }
   size: 1;
}

control Cisco {
   apply(Barnsboro);
}

table Atlasburg {
   actions {
      Charters;
   }
   size: 1;
}

table Hines {
   actions {
      Carver;
   }
   size: 1;
}

control Troutman {
   if ( valid( Aredale ) ) {
      apply(Atlasburg);
   } else {
      if ( valid( Ackerman ) ) {
         apply(Hines);
      }
   }
}

table Couchwood {
   actions {
      Novinger;
   }
   size: 1;
}

control Kaltag {
   if ( valid( Hitchland ) ) {
      apply(Couchwood);
   }
}



action Alcester() {
    modify_field(Elmdale.MudLake, Woodfield.Neavitt);
}

action Monowi() {
    modify_field(Elmdale.MudLake, Woodfield.Petrolia);
}

action Florida() {
    modify_field(Elmdale.MudLake, Woodfield.Lauada);
}

@pragma action_default_only Pawtucket
@pragma immediate 0
table Taneytown {
   reads {
      Palmer.valid : ternary;
      Quijotoa.valid : ternary;
      Yardville.valid : ternary;
      Silesia.valid : ternary;
      Gerty.valid : ternary;
      Cankton.valid : ternary;
      Hitchland.valid : ternary;
      Aredale.valid : ternary;
      Ackerman.valid : ternary;
      Nuremberg.valid : ternary;
   }
   actions {
      Alcester;
      Monowi;
      Florida;
      Pawtucket;
   }
   size: Falmouth;
}

action Riverwood() {
    modify_field(Elmdale.Elwood, Woodfield.Lauada);
}

@pragma immediate 0
table Converse {
   reads {
      Palmer.valid : ternary;
      Quijotoa.valid : ternary;
      Cankton.valid : ternary;
      Hitchland.valid : ternary;
   }
   actions {
      Riverwood;
      Pawtucket;
   }
   size: Somis;
}

control Walcott {
   apply(Converse);
   apply(Taneytown);
}



counter Terrell {
   type : packets_and_bytes;
   direct : Allyn;
   min_width: 16;
}

@pragma action_default_only Pawtucket
table Allyn {
   reads {
      Mapleview.Lamont : exact;
      Trammel.Choptank : ternary;
      Trammel.Cement : ternary;
      Seagrove.Talent : ternary;
      Seagrove.Horton : ternary;
      Seagrove.Idalia : ternary;
   }

   actions {
      Gibson;
      Pawtucket;
   }
   size : Petrey;
}

action Dalkeith() {

   modify_field(Seagrove.Sebewaing, 1 );
   modify_field(Yukon.Florala,
                Naubinway);
}







table Hisle {
   reads {
      Seagrove.Amanda : exact;
      Seagrove.Waucousta : exact;
      Seagrove.Jermyn : exact;
      Seagrove.Tascosa : exact;
   }

   actions {
      Wausaukee;
      Dalkeith;
   }
   size : Gorman;
   support_timeout : true;
}

action Wingate() {
   modify_field( Ahuimanu.Varnell, 1 );
}

table Mifflin {
   reads {
      Seagrove.Braselton : ternary;
      Seagrove.Edinburgh : exact;
      Seagrove.Elvaston : exact;
   }
   actions {
      Wingate;
   }
   size: Ironia;
}

control Osage {
   apply( Allyn ) {
      Pawtucket {



         if (Mapleview.Everest == 0 and Seagrove.Rockport == 0) {
            apply( Hisle );
         }
         apply(Mifflin);
      }
   }
}

field_list Rhine {
    Yukon.Florala;
    Seagrove.Amanda;
    Seagrove.Waucousta;
    Seagrove.Jermyn;
    Seagrove.Tascosa;
}

action Dubach() {
   generate_digest(Fireco, Rhine);
}

table Hedrick {
   actions {
      Dubach;
   }
   size : 1;
}

control Magma {
   if (Seagrove.Sebewaing == 1) {
      apply( Hedrick );
   }
}



action Kamrar( Hillside, Crump ) {
   modify_field( Arroyo.Merritt, Hillside );
   modify_field( FairOaks.Rattan, Crump );
}

@pragma action_default_only Pawtucket
table Stateline {
   reads {
      Ahuimanu.Halltown : exact;
      Arroyo.IowaCity mask LaFayette : lpm;
   }
   actions {
      Kamrar;
      Pawtucket;
   }
   size : Olive;
}

@pragma atcam_partition_index Arroyo.Merritt
@pragma atcam_number_partitions Olive
table Creekside {
   reads {
      Arroyo.Merritt : exact;
      Arroyo.IowaCity mask Nanakuli : lpm;
   }

   actions {
      Tuskahoma;
      Qulin;
      Pawtucket;
   }
   default_action : Pawtucket();
   size : Escondido;
}

action Chatmoss( Darden, Oxnard ) {
   modify_field( Arroyo.Jenison, Darden );
   modify_field( FairOaks.Rattan, Oxnard );
}

@pragma action_default_only Pawtucket
table Caban {


   reads {
      Ahuimanu.Halltown : exact;
      Arroyo.IowaCity : lpm;
   }

   actions {
      Chatmoss;
      Pawtucket;
   }

   size : Pavillion;
}

@pragma atcam_partition_index Arroyo.Jenison
@pragma atcam_number_partitions Pavillion
table LasLomas {
   reads {
      Arroyo.Jenison : exact;


      Arroyo.IowaCity mask Pricedale : lpm;
   }
   actions {
      Tuskahoma;
      Qulin;
      Pawtucket;
   }

   default_action : Pawtucket();
   size : Farner;
}

@pragma action_default_only Pawtucket
@pragma idletime_precision 1
table Baldwin {

   reads {
      Ahuimanu.Halltown : exact;
      Dialville.Youngtown : lpm;
   }

   actions {
      Tuskahoma;
      Qulin;
      Pawtucket;
   }

   size : Whitlash;
   support_timeout : true;
}

action Enhaut( Pierre, Berea ) {
   modify_field( Dialville.ElMirage, Pierre );
   modify_field( FairOaks.Rattan, Berea );
}

@pragma action_default_only Pawtucket
table Piqua {
   reads {
      Ahuimanu.Halltown : exact;
      Dialville.Youngtown : lpm;
   }

   actions {
      Enhaut;
      Pawtucket;
   }

   size : Harriet;
}

@pragma ways Pendroy
@pragma atcam_partition_index Dialville.ElMirage
@pragma atcam_number_partitions Harriet
table Becida {
   reads {
      Dialville.ElMirage : exact;
      Dialville.Youngtown mask Altus : lpm;
   }
   actions {
      Tuskahoma;
      Qulin;
      Pawtucket;
   }
   default_action : Pawtucket();
   size : Arnold;
}

action Tuskahoma( Fristoe ) {
   modify_field( FairOaks.Rattan, Fristoe );
}

@pragma idletime_precision 1
table Carmel {
   reads {
      Ahuimanu.Halltown : exact;
      Dialville.Youngtown : exact;
   }

   actions {
      Tuskahoma;
      Qulin;
      Pawtucket;
   }
   default_action : Pawtucket();
   size : Wetonka;
   support_timeout : true;
}

@pragma idletime_precision 1
table Steger {
   reads {
      Ahuimanu.Halltown : exact;
      Arroyo.IowaCity : exact;
   }

   actions {
      Tuskahoma;
      Qulin;
      Pawtucket;
   }
   default_action : Pawtucket();
   size : Blairsden;
   support_timeout : true;
}

action RioLinda(Ricketts, Muncie, Rugby) {
   modify_field(CedarKey.Kneeland, Rugby);
   modify_field(CedarKey.Provencal, Ricketts);
   modify_field(CedarKey.Hiland, Muncie);
   modify_field(CedarKey.Wheaton, 1);
}

table Manning {
   reads {
      FairOaks.Rattan : exact;
   }

   actions {
      RioLinda;
   }
   size : LakeHart;
}

control Dresser {
   if ( Seagrove.Hindman == 0 and Ahuimanu.Varnell == 1 ) {
      if ( ( Ahuimanu.Allgood == 1 ) and ( Seagrove.Sedan == 1 ) ) {
         apply( Carmel ) {
            Pawtucket {
               apply( Piqua ) {
                  Enhaut {
                     apply( Becida );
                  }
                  Pawtucket {
                     apply( Baldwin );
                  }
               }
            }
         }
      } else if ( ( Ahuimanu.Virden == 1 ) and ( Seagrove.Trout == 1 ) ) {
         apply( Steger ) {
            Pawtucket {
               apply( Caban ) {
                  Chatmoss {
                     apply( LasLomas );
                  }
                  Pawtucket {

                     apply( Stateline ) {
                        Kamrar {
                           apply( Creekside );
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Onava {
   if( FairOaks.Rattan != 0 ) {
      apply( Manning );
   }
}

action Qulin( Tulia ) {
   modify_field( FairOaks.Bayville, Tulia );
   modify_field( Ahuimanu.Kapaa, 1 );
}

field_list Salamonia {
   Elmdale.Elwood;
}

field_list_calculation Fordyce {
    input {
        Salamonia;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Arvana {
   selection_key : Fordyce;
   selection_mode : resilient;
}

action_profile Whitakers {
   actions {
      Tuskahoma;
   }
   size : Helen;
   dynamic_action_selection : Arvana;
}

table Hallowell {
   reads {
      FairOaks.Bayville : exact;
   }
   action_profile : Whitakers;
   size : Henry;
}

control Tidewater {
   if ( FairOaks.Bayville != 0 ) {
      apply( Hallowell );
   }
}



field_list Fairborn {
   Elmdale.MudLake;
}

field_list_calculation Garcia {
    input {
        Fairborn;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Cornwall {
    selection_key : Garcia;
    selection_mode : resilient;
}

action Wattsburg(DeSmet) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, DeSmet);
}

action_profile Husum {
    actions {
        Wattsburg;
        Pawtucket;
    }
    size : Blanchard;
    dynamic_action_selection : Cornwall;
}

table Hotevilla {
   reads {
      CedarKey.Bladen : exact;
   }
   action_profile: Husum;
   size : Martelle;
}

control Lordstown {
   if ((CedarKey.Bladen & 0x2000) == 0x2000) {
      apply(Hotevilla);
   }
}



meter Almyra {
   type : packets;
   static : Emden;
   instance_count: Ravinia;
}

action Oakes(Brockton) {
   execute_meter(Almyra, Brockton, Durant.Ickesburg);
}

table Emden {
   reads {
      Mapleview.Lamont : exact;
      CedarKey.Mabana : exact;
   }
   actions {
      Oakes;
   }
   size : Tulalip;
}

counter Candor {
   type : packets;
   static : Maysfield;
   instance_count : Disney;
   min_width: 64;
}

action Albany(Cochise) {
   modify_field(Seagrove.Hindman, 1);
   count(Candor, Cochise);
}

action Portis(Montbrook) {
   count(Candor, Montbrook);
}

action BlackOak(Unity, McDougal) {
   modify_field(ig_intr_md_for_tm.qid, Unity);
   count(Candor, McDougal);
}

action Daniels(Crannell, Leland, MillCity) {
   modify_field(ig_intr_md_for_tm.qid, Crannell);
   modify_field(ig_intr_md_for_tm.ingress_cos, Leland);
   count(Candor, MillCity);
}

action Brookston(Syria) {
   modify_field(ig_intr_md_for_tm.copy_to_cpu, 1);
   count(Candor, Syria);
}

table Maysfield {
   reads {
      Mapleview.Lamont : exact;
      CedarKey.Mabana : exact;
      Durant.Ickesburg : exact;
   }

   actions {
      Albany;
      BlackOak;
      Daniels;
      Portis;
      Brookston;
   }
size : Wamego;
}



action Dizney() {
   modify_field(CedarKey.Provencal, Seagrove.Edinburgh);
   modify_field(CedarKey.Hiland, Seagrove.Elvaston);
   modify_field(CedarKey.Ocheyedan, Seagrove.Amanda);
   modify_field(CedarKey.Cairo, Seagrove.Waucousta);
   modify_field(CedarKey.Kneeland, Seagrove.Jermyn);
}

table Ashtola {
   actions {
      Dizney;
   }
   default_action : Dizney();
   size : 1;
}

control Sledge {
   if (Seagrove.Jermyn!=0) {
      apply( Ashtola );
   }
}

action Paskenta() {
   modify_field(CedarKey.Witherbee, 1);
   modify_field(CedarKey.Sultana, 1);
   modify_field(CedarKey.Lapoint, CedarKey.Kneeland);
}

action Bellamy() {
}



@pragma ways 1
table Thayne {
   reads {
      CedarKey.Provencal : exact;
      CedarKey.Hiland : exact;
   }
   actions {
      Paskenta;
      Bellamy;
   }
   default_action : Bellamy;
   size : 1;
}

action Mendoza() {
   modify_field(CedarKey.Tafton, 1);
   modify_field(CedarKey.Quivero, 1);
   add(CedarKey.Lapoint, CedarKey.Kneeland, Mulhall);
}

table Langtry {
   actions {
      Mendoza;
   }
   default_action : Mendoza;
   size : 1;
}

action Valders() {
   modify_field(CedarKey.Chloride, 1);
   modify_field(CedarKey.Lapoint, CedarKey.Kneeland);
}

table FairPlay {
   actions {
      Valders;
   }
   default_action : Valders();
   size : 1;
}

action Goulding(Fenwick) {
   modify_field(CedarKey.Parole, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Fenwick);
   modify_field(CedarKey.Bladen, Fenwick);
}

action Mellott(Ladoga) {
   modify_field(CedarKey.Tafton, 1);
   modify_field(CedarKey.Lapoint, Ladoga);
}

action Osterdock() {
}

table Weinert {
   reads {
      CedarKey.Provencal : exact;
      CedarKey.Hiland : exact;
      CedarKey.Kneeland : exact;
   }

   actions {
      Goulding;
      Mellott;
      Osterdock;
   }
   default_action : Osterdock();
   size : Duquoin;
}

control Silva {
   if (Seagrove.Hindman == 0) {
      apply(Weinert) {
         Osterdock {
            apply(Thayne) {
               Bellamy {
                  if ((CedarKey.Provencal & 0x010000) == 0x010000) {
                     apply(Langtry);
                  } else {
                     apply(FairPlay);
                  }
               }
            }
         }
      }
   }
}

action Leetsdale() {
   modify_field(Seagrove.Creston, 1);
   modify_field(Seagrove.Hindman, 1);
}

table Avondale {
   actions {
      Leetsdale;
   }
   default_action : Leetsdale;
   size : 1;
}

control Mekoryuk {
   if (Seagrove.Hindman == 0) {
      if ((CedarKey.Wheaton==0) and (Seagrove.Tascosa==CedarKey.Bladen)) {
         apply(Avondale);
      } else {
         apply(Emden);
         apply(Maysfield);
      }
   }
}



action Lepanto( Slana ) {
   modify_field( CedarKey.Bigfork, Slana );
}

action Anthony() {
   modify_field( CedarKey.Bigfork, CedarKey.Kneeland );
}

table Motley {
   reads {
      eg_intr_md.egress_port : exact;
      CedarKey.Kneeland : exact;
   }

   actions {
      Lepanto;
      Anthony;
   }
   default_action : Anthony;
   size : Stowe;
}

control Huttig {
   apply( Motley );
}



action Telegraph( Blossom, Annville ) {
   modify_field( CedarKey.Leeville, Blossom );
   modify_field( CedarKey.Castle, Annville );
}


table Campbell {
   reads {
      CedarKey.LeSueur : exact;
   }

   actions {
      Telegraph;
   }
   size : Millikin;
}

action PineAire() {
   no_op();
}

action Burdette() {
   modify_field( Nuremberg.Knolls, Kinston[0].Layton );
   remove_header( Kinston[0] );
}

table Corry {
   actions {
      Burdette;
   }
   default_action : Burdette;
   size : Almont;
}

action Bairoa() {
   no_op();
}

action HydePark() {
   add_header( Kinston[ 0 ] );
   modify_field( Kinston[0].Holliday, CedarKey.Bigfork );
   modify_field( Kinston[0].Layton, Nuremberg.Knolls );
   modify_field( Nuremberg.Knolls, Reydon );
}



table Ellisburg {
   reads {
      CedarKey.Bigfork : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Bairoa;
      HydePark;
   }
   default_action : HydePark;
   size : Tingley;
}

action Mullins() {
   modify_field(Nuremberg.Panola, CedarKey.Provencal);
   modify_field(Nuremberg.Pierson, CedarKey.Hiland);
   modify_field(Nuremberg.Snowball, CedarKey.Leeville);
   modify_field(Nuremberg.Waipahu, CedarKey.Castle);
}

action WallLake() {
   Mullins();
   add_to_field(Aredale.Arthur, -1);
}

action Faith() {
   Mullins();
   add_to_field(Ackerman.Paisano, -1);
}

table Barrow {
   reads {
      CedarKey.Chouteau : exact;
      CedarKey.LeSueur : exact;
      CedarKey.Wheaton : exact;
      Aredale.valid : ternary;
      Ackerman.valid : ternary;
   }

   actions {
      WallLake;
      Faith;
   }
   size : Lyndell;
}

control Neuse {
   apply( Corry );
}

control Orrum {
   apply( Ellisburg );
}

control Bonilla {
   apply( Campbell );
   apply( Barrow );
}



field_list Shelby {
    Yukon.Florala;
    Seagrove.Jermyn;
    Gerty.Snowball;
    Gerty.Waipahu;
    Aredale.Norwood;
}

action Amite() {
   generate_digest(Fireco, Shelby);
}

table Satolah {
   actions {
      Amite;
   }

   default_action : Amite;
   size : 1;
}

control Hollyhill {
   if (Seagrove.Rockport == 1) {
      apply(Satolah);
   }
}



action Sparland() {
   modify_field( Seagrove.Riner, Mapleview.Mammoth );
}

action WestBay() {
   modify_field( Seagrove.Crowheart, Mapleview.Piketon );
}

action Denmark() {
   modify_field( Seagrove.Crowheart, Dialville.Dunnegan );
}

action Cranbury() {
   modify_field( Seagrove.Crowheart, Arroyo.Matador );
}

action PineCity( Knippa, Keauhou ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Knippa );
   modify_field( ig_intr_md_for_tm.qid, Keauhou );
}

table Daysville {
   reads {
     Seagrove.RedLake : exact;
   }

   actions {
     Sparland;
   }

   size : Hewitt;
}

table LeeCreek {
   reads {
     Seagrove.Sedan : exact;
     Seagrove.Trout : exact;
   }

   actions {
     WestBay;
     Denmark;
     Cranbury;
   }

   size : Dalton;
}

//@pragma stage 10
table Duchesne {
   reads {
      Mapleview.Triplett : exact;
      Mapleview.Mammoth : ternary;
      Seagrove.Riner : ternary;
      Seagrove.Crowheart : ternary;
   }

   actions {
      PineCity;
   }

   size : ElVerano;
}

control Northlake {
   apply( Daysville );
   apply( LeeCreek );
}

control Parmelee {
   apply( Duchesne );
}

control ingress {

   Stella();
   Iberia();
   Suarez();
   Sitka();
   Cisco();


   Northlake();
   Osage();

   Troutman();
   Kaltag();


   Dresser();
   Walcott();
   Tidewater();

   Sledge();

   Onava();





   Silva();
   Parmelee();


   Mekoryuk();
   Lordstown();
   Hollyhill();
   Magma();


   if( valid( Kinston[0] ) ) {
      Neuse();
   }






}

control egress {
   Huttig();
   Bonilla();
   Orrum();
}

