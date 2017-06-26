// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 2







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>



#ifndef Barnsboro
#define Barnsboro

header_type Weathers {
	fields {
		Waring : 16;
		Ballwin : 16;
		Bethesda : 8;
		Skime : 8;
		Poulsbo : 8;
		Okaton : 8;
		Fernway : 1;
		Mingus : 1;
		MintHill : 1;
		McCleary : 1;
		Cathcart : 1;
		Hughson : 3;
	}
}

header_type Haslet {
	fields {
		Pinecrest : 24;
		Yardley : 24;
		Washta : 24;
		Lublin : 24;
		Ivanhoe : 16;
		Edler : 16;
		Aquilla : 16;
		Anawalt : 16;
		Kealia : 16;
		Floyd : 8;
		Halliday : 8;
		Thistle : 6;
		Lewiston : 1;
		Malabar : 1;
		Delmont : 12;
		Amboy : 2;
		FoxChase : 1;
		Cadwell : 1;
		Latham : 1;
		Yukon : 1;
		Onida : 1;
		Clearlake : 1;
		TiePlant : 1;
		Sabula : 1;
		Portville : 1;
		Traskwood : 1;
		Rendon : 1;
		Roswell : 1;
		Godley : 1;
		Winfall : 1;
		Wentworth : 3;
	}
}

header_type CeeVee {
	fields {
		Raven : 24;
		Pettry : 24;
		Kanorado : 24;
		Linganore : 24;
		LaConner : 24;
		Vallejo : 24;
		Lakota : 24;
		Sidon : 24;
		Gobles : 16;
		Tatum : 16;
		Toano : 16;
		Kaluaaha : 12;
		Marfa : 3;
		Unionvale : 1;
		PineLake : 3;
		Konnarock : 1;
		Cypress : 1;
		FortShaw : 1;
		Parmerton : 1;
		Champlin : 1;
		Trevorton : 1;
		Edgemont : 8;
		Truro : 12;
		Fergus : 4;
		Weehawken : 6;
		Pearland : 10;
		LaneCity : 9;
		LeeCity : 1;
		Nickerson : 1;
		McMurray : 1;
	}
}


header_type Filley {
	fields {
		Coverdale : 8;
		Lathrop : 1;
		Vigus : 1;
		Mosinee : 1;
		Bellport : 1;
		Sequim : 1;
	}
}

header_type PinkHill {
	fields {
		Tramway : 32;
		Colona : 32;
		Quealy : 6;
		BarNunn : 16;
	}
}

header_type Niota {
	fields {
		ElPrado : 128;
		Danville : 128;
		Sylvester : 20;
		Boring : 8;
		Lenoir : 11;
		Steele : 6;
		Dixie : 13;
	}
}

header_type Coyote {
	fields {
		Tampa : 14;
		Holliston : 1;
		Phelps : 12;
		Anniston : 1;
		Graford : 1;
		Chehalis : 6;
		OldMinto : 2;
		Bernard : 6;
		Waxhaw : 3;
	}
}

header_type Amite {
	fields {
		Plandome : 1;
		Altadena : 1;
	}
}

header_type Dubuque {
	fields {
		Scherr : 8;
	}
}

header_type Casselman {
	fields {
		Cleta : 16;
		Paisley : 11;
	}
}

header_type Hanford {
	fields {
		Arvonia : 32;
		Worthing : 32;
		Carlson : 32;
	}
}

header_type ArchCape {
	fields {
		Gifford : 32;
		Monowi : 32;
	}
}

header_type Purley {
	fields {
		Brady : 8;
		Gardiner : 4;
		Annawan : 15;
		Jayton : 1;
	}
}

header_type Reynolds {
	fields {
		Progreso : 16;
	}
}

header_type Toluca {
	fields {
		Rayville : 14;
		Suamico : 1;
		Paxtonia : 1;
	}
}

header_type Kenton {
	fields {
		Daphne : 14;
		Novice : 1;
		Flippen : 1;
	}
}

header_type Bokeelia {
	fields {
		JaneLew : 8;
		Sylva : 16;
		Buckholts : 16;
		McGovern : 8;
		Harvard : 6;
		LeaHill : 16;
		Camilla : 16;
		Wells : 42;
	}
}

header_type Dunnellon {
	fields {
		Minburn : 32;
	}
}



#endif



#ifndef Camden
#define Camden


header_type Hodge {
	fields {
		Allyn : 6;
		Madras : 10;
		Calimesa : 4;
		Baltimore : 12;
		Antlers : 12;
		Center : 2;
		Blanchard : 2;
		Nathalie : 8;
		Laramie : 3;
		Wolcott : 5;
	}
}



header_type Villanova {
	fields {
		Yakima : 24;
		Deerwood : 24;
		Isleta : 24;
		Doyline : 24;
		Mendocino : 16;
	}
}



header_type Moylan {
	fields {
		Sallisaw : 3;
		Pendroy : 1;
		Dundalk : 12;
		Homeacre : 16;
	}
}



header_type Libby {
	fields {
		Adair : 4;
		Arcanum : 4;
		Hewitt : 6;
		Boysen : 2;
		Pineridge : 16;
		Dilia : 16;
		Blunt : 3;
		Clermont : 13;
		DeepGap : 8;
		Cuprum : 8;
		Leola : 16;
		Keachi : 32;
		Finley : 32;
	}
}

header_type Neubert {
	fields {
		Criner : 4;
		Trail : 6;
		WestEnd : 2;
		Plateau : 20;
		Hydaburg : 16;
		Laurie : 8;
		McClusky : 8;
		Azusa : 128;
		Hobart : 128;
	}
}




header_type Liberal {
	fields {
		Clearco : 8;
		Bixby : 8;
		Sanatoga : 16;
	}
}

header_type Greenhorn {
	fields {
		Lemoyne : 16;
		Urbanette : 16;
		Molson : 32;
		Ericsburg : 32;
		Wittman : 4;
		Guion : 4;
		Almont : 8;
		Overbrook : 16;
		Bolckow : 16;
		Felida : 16;
	}
}

header_type SnowLake {
	fields {
		Olmitz : 16;
		Algoa : 16;
		JimFalls : 16;
		HighRock : 16;
	}
}



header_type Kotzebue {
	fields {
		Cowpens : 16;
		Melrude : 16;
		Bellmead : 8;
		Emmalane : 8;
		GunnCity : 16;
	}
}

header_type Vinings {
	fields {
		Belview : 48;
		Recluse : 32;
		Compton : 48;
		Mattapex : 32;
	}
}



header_type Harvest {
	fields {
		KawCity : 1;
		Raytown : 1;
		Havertown : 1;
		Brookneal : 1;
		Brookside : 1;
		Bergton : 3;
		Stamford : 5;
		Neuse : 3;
		Wellford : 16;
	}
}

header_type Panaca {
	fields {
		Amherst : 24;
		Nuangola : 8;
	}
}



header_type RockHill {
	fields {
		Pineville : 8;
		Lakebay : 24;
		Gosnell : 24;
		Kahului : 8;
	}
}

#endif



#ifndef Stambaugh
#define Stambaugh

#define Hoven        0x8100
#define RockPort        0x0800
#define Burien        0x86dd
#define Levittown        0x9100
#define SourLake        0x8847
#define Gandy         0x0806
#define Ridgetop        0x8035
#define Moapa        0x88cc
#define Hatteras        0x8809
#define Yorkshire      0xBF00

#define Hartford              1
#define Kiana              2
#define MoonRun              4
#define Flaxton               6
#define Slater               17
#define Metzger                47

#define McQueen         0x501
#define Louviers          0x506
#define Wondervu          0x511
#define Woodville          0x52F


#define Snohomish                 4789



#define Jones               0
#define HighHill              1
#define LewisRun                2



#define Assinippi          0
#define Botna          4095
#define Yardville  4096
#define Buckfield  8191



#define Viroqua                      0
#define Orrstown                  0
#define Tunis                 1

header Villanova Salome;
header Villanova ElLago;
header Moylan Linden[ 2 ];



@pragma pa_fragment ingress Kinsley.Leola
@pragma pa_fragment egress Kinsley.Leola
header Libby Kinsley;

@pragma pa_fragment ingress Wauseon.Leola
@pragma pa_fragment egress Wauseon.Leola
header Libby Wauseon;

header Neubert Sanford;
header Neubert Veteran;

header Greenhorn Skyline;

header SnowLake Excel;
header Greenhorn DeerPark;
header SnowLake LaFayette;
header RockHill Durant;
header Kotzebue Horton;
header Harvest Orrum;
header Hodge Ulysses;
header Villanova McManus;

parser start {
   return select(current(96, 16)) {
      Yorkshire : Bellville;
      default : Fallis;
   }
}

parser Safford {
   extract( Ulysses );
   return Fallis;
}

parser Bellville {
   extract( McManus );
   return Safford;
}

parser Fallis {
   extract( Salome );
   return select( Salome.Mendocino ) {
      Hoven : Aguilar;
      RockPort : Borth;
      Burien : GlenRock;
      Gandy  : Chevak;
      default        : ingress;
   }
}

parser Aguilar {
   extract( Linden[0] );

   set_metadata(Selby.Wentworth, Linden[0].Sallisaw);
   set_metadata(Youngtown.Cathcart, 1);
   return select( Linden[0].Homeacre ) {
      RockPort : Borth;
      Burien : GlenRock;
      Gandy  : Chevak;
      default : ingress;
   }
}

field_list Cannelton {
    Kinsley.Adair;
    Kinsley.Arcanum;
    Kinsley.Hewitt;
    Kinsley.Boysen;
    Kinsley.Pineridge;
    Kinsley.Dilia;
    Kinsley.Blunt;
    Kinsley.Clermont;
    Kinsley.DeepGap;
    Kinsley.Cuprum;
    Kinsley.Keachi;
    Kinsley.Finley;
}

field_list_calculation Ojibwa {
    input {
        Cannelton;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field Kinsley.Leola  {
    verify Ojibwa;
    update Ojibwa;
}

parser Borth {
   extract( Kinsley );
   set_metadata(Youngtown.Bethesda, Kinsley.Cuprum);
   set_metadata(Youngtown.Poulsbo, Kinsley.DeepGap);
   set_metadata(Youngtown.Waring, Kinsley.Pineridge);
   set_metadata(Youngtown.MintHill, 0);
   set_metadata(Youngtown.Fernway, 1);
   return select(Kinsley.Clermont, Kinsley.Arcanum, Kinsley.Cuprum) {
      Wondervu : BigRiver;
      Louviers : Wheeling;
      default : ingress;
   }
}

parser GlenRock {
   extract( Veteran );
   set_metadata(Youngtown.Bethesda, Veteran.Laurie);
   set_metadata(Youngtown.Poulsbo, Veteran.McClusky);
   set_metadata(Youngtown.Waring, Veteran.Hydaburg);
   set_metadata(Youngtown.MintHill, 1);
   set_metadata(Youngtown.Fernway, 0);
   return ingress;
}

parser Chevak {
   extract( Horton );
   return ingress;
}

parser BigRiver {
   extract(Excel);
   return select(Excel.Algoa) {
      Snohomish : Newport;
      default : ingress;
    }
}

parser Wheeling {
   extract(Skyline);
   return ingress;
}

parser Aurora {
   set_metadata(Selby.Amboy, LewisRun);
   return Tinaja;
}

parser Dibble {
   set_metadata(Selby.Amboy, LewisRun);
   return Kneeland;
}

parser Mahomet {
   extract(Orrum);
   return select(Orrum.KawCity, Orrum.Raytown, Orrum.Havertown, Orrum.Brookneal, Orrum.Brookside,
             Orrum.Bergton, Orrum.Stamford, Orrum.Neuse, Orrum.Wellford) {
      RockPort : Aurora;
      Burien : Dibble;
      default : ingress;
   }
}

parser Newport {
   extract(Durant);
   set_metadata(Selby.Amboy, HighHill);
   return Calabasas;
}

field_list Laneburg {
    Wauseon.Adair;
    Wauseon.Arcanum;
    Wauseon.Hewitt;
    Wauseon.Boysen;
    Wauseon.Pineridge;
    Wauseon.Dilia;
    Wauseon.Blunt;
    Wauseon.Clermont;
    Wauseon.DeepGap;
    Wauseon.Cuprum;
    Wauseon.Keachi;
    Wauseon.Finley;
}

field_list_calculation Bardwell {
    input {
        Laneburg;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field Wauseon.Leola  {
    verify Bardwell;
    update Bardwell;
}

parser Tinaja {
   extract( Wauseon );
   set_metadata(Youngtown.Skime, Wauseon.Cuprum);
   set_metadata(Youngtown.Okaton, Wauseon.DeepGap);
   set_metadata(Youngtown.Ballwin, Wauseon.Pineridge);
   set_metadata(Youngtown.McCleary, 0);
   set_metadata(Youngtown.Mingus, 1);
   return ingress;
}

parser Kneeland {
   extract( Sanford );
   set_metadata(Youngtown.Skime, Sanford.Laurie);
   set_metadata(Youngtown.Okaton, Sanford.McClusky);
   set_metadata(Youngtown.Ballwin, Sanford.Hydaburg);
   set_metadata(Youngtown.McCleary, 1);
   set_metadata(Youngtown.Mingus, 0);
   return ingress;
}

parser Calabasas {
   extract( ElLago );
   return select( ElLago.Mendocino ) {
      RockPort: Tinaja;
      Burien: Kneeland;
      default: ingress;
   }
}
#endif

metadata Haslet Selby;
metadata CeeVee Blanding;


metadata Weathers Youngtown;
metadata PinkHill Cantwell;
metadata Niota Hitterdal;
metadata Filley Bieber;
metadata Casselman Woodston;
metadata Bokeelia Brainard;
metadata Dunnellon Washoe;













#undef Cordell

#undef Udall
#undef Shamokin
#undef Levasy
#undef Osseo
#undef Swords

#undef Caldwell
#undef LaPryor
#undef Burgess

#undef Brazil
#undef Boutte
#undef Creekside
#undef Bagdad
#undef Crouch
#undef Haines
#undef Mossville
#undef Storden
#undef Tonkawa
#undef Pickering
#undef Larchmont
#undef Twain
#undef Chaffey
#undef Boquillas
#undef Sedan
#undef Muncie
#undef Craigtown
#undef Hackney
#undef Everett
#undef Hulbert
#undef HornLake

#undef Hearne
#undef Sabina
#undef Sawyer
#undef Mangham
#undef Kevil
#undef Elysburg
#undef Rexville
#undef Woodfords
#undef Davant
#undef PawCreek
#undef Parmelee
#undef Northcote
#undef Ankeny
#undef Macedonia
#undef Corona
#undef Conda
#undef McCammon
#undef NewTrier
#undef MuleBarn
#undef Pumphrey
#undef PawPaw

#undef Kinard
#undef Atlasburg

#undef Ripon

#undef Shelbiana

#undef Skiatook
#undef Mickleton
#undef Argentine
#undef Connell
#undef Bowden







#define Cordell 288

#define Thurston
#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Udall      65536
#define Shamokin      65536
#define Levasy 512
#define Osseo 512
#define Swords      512


#define Caldwell     1024
#define LaPryor    1024
#define Burgess     256


#define Brazil 512
#define Boutte 65536

#define Creekside 65536
#define Bagdad 28672



#define Crouch   16384
#define Haines 8192
#define Mossville         131072
#define Storden 65536
#define Tonkawa 1024
#define Pickering 2048
#define Larchmont 16384

#define Twain 8192
#define Chaffey 65536




#define Boquillas 0x0000000000000000FFFFFFFFFFFFFFFF


#define Sedan 0x000fffff
#define Hackney 2

#define Muncie 0xFFFFFFFFFFFFFFFF0000000000000000

#define Craigtown 0x000007FFFFFFFFFF0000000000000000
#define Everett  6
#define HornLake        2048
#define Hulbert       65536


#define Hearne 1024
#define Sabina 4096
#define Sawyer 4096
#define Mangham 4096
#define Kevil 4096
#define Elysburg 1024
#define Rexville 4096
#define Davant 128
#define PawCreek 1
#define Parmelee  8


#define Northcote 512
#define Kinard 512
#define Atlasburg 256


#define Ankeny 1
#define Macedonia 3
#define Corona 80



#define Conda 512
#define McCammon 512
#define NewTrier 512
#define MuleBarn 512

#define Pumphrey 2048
#define PawPaw 1024



#define Ripon 0


#define Shelbiana    4096


#define Skiatook    16384
#define Mickleton   16384
#define Argentine            16384

#define Connell                    57344
#define Bowden         511


#endif



#ifndef National
#define National

action Lueders() {
   no_op();
}

action Coalton() {
   modify_field(Selby.Yukon, 1 );
   mark_for_drop();
}

action Waynoka() {
   no_op();
}
#endif



action Calcasieu( BirchBay, Nanson ) {
   modify_field( Hitterdal.Dixie, BirchBay );
   modify_field( Woodston.Cleta, Nanson );
}

@pragma command_line --no-dead-code-elimination
@pragma action_default_only Fillmore
table Nuyaka {
   reads {
      Bieber.Coverdale : exact;
      Hitterdal.Danville mask Muncie : lpm;
   }
   actions {
      Calcasieu;
      Fillmore;
   }
   size : Twain;
}

@pragma atcam_partition_index Hitterdal.Dixie
@pragma atcam_number_partitions Twain
table KeyWest {
   reads {
      Hitterdal.Dixie : exact;
      Hitterdal.Danville mask Craigtown : lpm;
   }

   actions {
      Wamego;
      Goessel;
      Lueders;
   }
   default_action : Lueders();
   size : Chaffey;
}

action Garwood( Stanwood, Salamatof ) {
   modify_field( Hitterdal.Lenoir, Stanwood );
   modify_field( Woodston.Cleta, Salamatof );
}

@pragma action_default_only Lueders
table Valeene {


   reads {
      Bieber.Coverdale : exact;
      Hitterdal.Danville : lpm;
   }

   actions {
      Garwood;
      Lueders;
   }

   size : Pickering;
}

@pragma atcam_partition_index Hitterdal.Lenoir
@pragma atcam_number_partitions Pickering
table Minoa {
   reads {
      Hitterdal.Lenoir : exact;


      Hitterdal.Danville mask Boquillas : lpm;
   }
   actions {
      Wamego;
      Goessel;
      Lueders;
   }

   default_action : Lueders();
   size : Larchmont;
}

@pragma action_default_only Fillmore
@pragma idletime_precision 1
table Boquet {

   reads {
      Bieber.Coverdale : exact;
      Cantwell.Colona : lpm;
   }

   actions {
      Wamego;
      Goessel;
      Fillmore;
   }

   size : Tonkawa;
   support_timeout : true;
}

action Roosville( Dedham, Joyce ) {
   modify_field( Cantwell.BarNunn, Dedham );
   modify_field( Woodston.Cleta, Joyce );
}

@pragma action_default_only Lueders
#ifdef PROFILE_DEFAULT


#endif
table Grampian {
   reads {
      Bieber.Coverdale : exact;
      Cantwell.Colona : lpm;
   }

   actions {
      Roosville;
      Lueders;
   }

   size : Crouch;
}

@pragma ways Hackney
@pragma atcam_partition_index Cantwell.BarNunn
@pragma atcam_number_partitions Crouch
table Waretown {
   reads {
      Cantwell.BarNunn : exact;
      Cantwell.Colona mask Sedan : lpm;
   }
   actions {
      Wamego;
      Goessel;
      Lueders;
   }
   default_action : Lueders();
   size : Mossville;
}

action Wamego( Elkton ) {
   modify_field( Woodston.Cleta, Elkton );
}

@pragma idletime_precision 1
table Neches {
   reads {
      Bieber.Coverdale : exact;
      Cantwell.Colona : exact;
   }

   actions {
      Wamego;
      Goessel;
      Lueders;
   }
   default_action : Lueders();
   size : Boutte;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT


#endif
table Saragosa {
   reads {
      Bieber.Coverdale : exact;
      Hitterdal.Danville : exact;
   }

   actions {
      Wamego;
      Goessel;
      Lueders;
   }
   default_action : Lueders();
   size : Creekside;
   support_timeout : true;
}

action Tiller(Granbury, Florien, Hackett) {
   modify_field(Blanding.Gobles, Hackett);
   modify_field(Blanding.Raven, Granbury);
   modify_field(Blanding.Pettry, Florien);
   modify_field(Blanding.LeeCity, 1);

   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}

action LasVegas() {
   Coalton();
}

action Westway(Juniata) {
   modify_field(Blanding.Unionvale, 1);
   modify_field(Blanding.Edgemont, Juniata);
}

action Fillmore() {
   modify_field( Blanding.Unionvale, 1 );
   modify_field( Blanding.Edgemont, 9 );
}

control Garrison {
   if ( Selby.Yukon == 0 and Bieber.Sequim == 1 ) {
      if ( ( Bieber.Lathrop == 1 ) and ( Selby.Malabar == 1 ) ) {
         apply( Neches ) {
            Lueders {
               apply( Grampian ) {
                  Roosville {
                     apply( Waretown );
                  }
                  Lueders {
                     apply( Boquet );
                  }
               }
            }
         }
      } else if ( ( Bieber.Mosinee == 1 ) and ( Selby.Lewiston == 1 ) ) {
         apply( Saragosa ) {
            Lueders {
               apply( Valeene ) {
                  Garwood {
                     apply( Minoa );
                  }
                  Lueders {

                     apply( Nuyaka ) {
                        Calcasieu {
                           apply( KeyWest );
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

action Angus( Rohwer ) {
   max( Washoe.Minburn, Washoe.Minburn, Rohwer );
}

@pragma stage 0
table Meyers {
   reads {
      Brainard.JaneLew : exact;
   }

   actions {
      Angus;
   }
   size : 256;
}

@pragma stage 1
table Angus {
   reads {
      Brainard.JaneLew : exact;
   }

   actions {
      Angus;
   }
   size : 256;
}

@pragma stage 2
table London {
   reads {
      Brainard.JaneLew : exact;
   }

   actions {
      Angus;
   }
   size : 256;
}
@pragma stage 3
table Taopi {
   reads {
      Brainard.JaneLew : exact;
   }

   actions {
      Angus;
   }
   size : 256;
}
@pragma stage 4
table Claypool {
   reads {
      Brainard.JaneLew : exact;
   }

   actions {
      Angus;
   }
   size : 256;
}


action Goessel( IowaCity ) {
   modify_field( Woodston.Paisley, IowaCity );
}

control ingress {
#ifdef Thurston
    apply( Meyers );
    apply( Angus );
    apply( London );
    apply( Taopi );
    apply( Claypool );
#endif
    
    //  Garrison();
    if ( Selby.Yukon == 0 and Bieber.Sequim == 1 ) {
        if ( ( Bieber.Lathrop == 1 ) and ( Selby.Malabar == 1 ) ) {
            apply( Neches ) {
                Lueders {
                    apply( Grampian ) {
                        Roosville {
                            apply( Waretown );
                        }
                        Lueders {
                            apply( Boquet );
                        }
                    }
                }
            }
        } else if ( ( Bieber.Mosinee == 1 ) and ( Selby.Lewiston == 1 ) ) {
            apply( Saragosa ) {
                Lueders {
                    apply( Valeene ) {
                        Garwood {
                            apply( Minoa );
                        }
                        Lueders {
                            apply( Nuyaka ) {
                                Calcasieu {
                                    apply( KeyWest );
                                }
                            }
                        }
                    }
                }
            }
        }
    }

#ifndef Thurston
    apply( Meyers );
    apply( Angus );
    apply( London );
    apply( Taopi );
    apply( Claypool );
#endif
}

control egress {
}

