// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 205955







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
#else





header_type Lovilia {
	fields {
		Pollard : 3;
	}
}
metadata Lovilia Stirrat;

header_type Aredale {
	fields {
		Bazine : 1;
		Cammal : 9;
		Bridger : 48;
		Welaka : 32;
	}
}
metadata Aredale LaMoille;

header_type Molino {
	fields {
		Tonkawa : 9;
		Deloit : 3;
		Nenana : 16;
		Arapahoe : 16;
		Alzada : 13;
		Farthing : 13;
		Gunder : 16;
		Bremond : 9;
		Duffield : 16;
		Shuqualak : 1;
		Academy : 3;
		Amanda : 5;
		Buenos : 2;
	}
}

metadata Molino Sandston;

header_type Jauca {
	fields {
		Sherando : 9;
		Milbank : 19;
		Cathcart : 2;
		Aguilita : 32;
		Thalia : 19;
		Depew : 2;
		Hammett : 8;
		Grantfork : 32;
		Finney : 16;
		Wheeler : 1;
		Glennie : 5;
		Wagener : 3;
		Gastonia : 1;
	}
}

metadata Jauca Grayland;




action Ellisport(PawPaw) {
    modify_field(Dorothy, PawPaw);
}

#ifdef BMV2
#define Ocheyedan     Christmas
#else
#define Ocheyedan         Boutte
#endif

header_type Wauneta {
	fields {
		Vichy : 8;
		Crary : 48;
	}
}
metadata Wauneta Snohomish;

#define Heflin 0
#define Bayville 1
#define Canjilon 2
#define Paragould 3
#define Schroeder 4
#define Kaeleku 5
#define Shorter 6


#define Sarasota \
    ((Louin != Heflin) and \
     (Louin != Kaeleku))
#define Borup \
    ((Louin == Heflin) or \
     (Louin == Kaeleku))
#define Celada \
    (Louin == Bayville)
#define Hubbell \
    (Louin == Canjilon)
#endif



#ifndef Faulkton
#define Faulkton

header_type Camilla {
	fields {
		Sturgeon : 16;
		Zebina : 16;
		Placedo : 8;
		Cecilton : 8;
		Klawock : 8;
		Remsen : 8;
		Copley : 1;
		Pumphrey : 1;
		Miller : 1;
		Mendocino : 1;
	}
}

header_type Almont {
	fields {
		Wrenshall : 24;
		Choptank : 24;
		Millbrook : 24;
		Baxter : 24;
		Ryderwood : 16;
		Dauphin : 16;
		Rocklin : 16;
		Bonner : 16;
		Caliente : 16;
		Bluford : 8;
		TinCity : 8;
		Kiwalik : 1;
		Bernard : 1;
		Buras : 12;
		Colson : 2;
		Rosario : 1;
		Wellford : 1;
		Chunchula : 1;
		Spraberry : 1;
		Rhinebeck : 1;
		Nuevo : 1;
		Hooks : 1;
		Parkville : 1;
		SandCity : 1;
		Rainelle : 1;
		Oregon : 1;
	}
}

header_type Duster {
	fields {
		Bajandas : 24;
		Holyoke : 24;
		Woodfield : 24;
		Moreland : 24;
		Wabbaseka : 24;
		Hebbville : 24;
		Prismatic : 16;
		Waukesha : 16;
		Collis : 16;
		Kranzburg : 12;
		Grenville : 3;
		Carbonado : 3;
		Calamine : 1;
		Rosboro : 1;
		Driftwood : 1;
		HornLake : 1;
		Emerado : 1;
		Hauppauge : 1;
		Geistown : 1;
		Raceland : 1;
		Lucien : 8;
	}
}


header_type Woolwine {
	fields {
		Maxwelton : 8;
		Ingraham : 1;
		Kosmos : 1;
		Kinards : 1;
		IowaCity : 1;
		Maljamar : 1;
	}
}

header_type DuBois {
	fields {
		Ruston : 32;
		Dialville : 32;
		Govan : 6;
		Hawthorne : 16;
	}
}

header_type Challis {
	fields {
		Everetts : 128;
		Rossburg : 128;
		Waupaca : 20;
		Bayard : 8;
		BigPiney : 11;
		Alvordton : 8;
		Coleman : 13;
	}
}

header_type Melmore {
	fields {
		Fairchild : 14;
		Seguin : 1;
		Ludlam : 1;
		Almelund : 12;
		CapeFair : 1;
		Lowden : 6;
	}
}

header_type Ardara {
	fields {
		Maybeury : 1;
		Goodlett : 1;
	}
}

header_type Fletcher {
	fields {
		Sedona : 8;
	}
}

header_type Wayne {
	fields {
		Requa : 16;
	}
}

header_type Converse {
	fields {
		Hobart : 32;
		Monaca : 32;
		Graford : 32;
	}
}

header_type Willmar {
	fields {
		Findlay : 32;
		Carnero : 32;
	}
}

#endif



#ifndef Hettinger
#define Hettinger



header_type Waucoma {
	fields {
		Ruthsburg : 24;
		Mulliken : 24;
		Gomez : 24;
		Starkey : 24;
		Annette : 16;
	}
}



header_type Longview {
	fields {
		Charters : 3;
		Barrow : 1;
		KawCity : 12;
		NewRoads : 16;
	}
}



header_type Rienzi {
	fields {
		Pilottown : 4;
		Dollar : 4;
		Dacono : 6;
		Cloverly : 2;
		Tunis : 16;
		Alabaster : 16;
		BoxElder : 3;
		Polkville : 13;
		Guadalupe : 8;
		Angus : 8;
		Bendavis : 16;
		Rankin : 32;
		Norwood : 32;
	}
}

header_type LaHabra {
	fields {
		Aspetuck : 4;
		Adona : 8;
		Woodfords : 20;
		Musella : 16;
		Hackney : 8;
		TiePlant : 8;
		Waterman : 128;
		Domingo : 128;
	}
}




header_type Skagway {
	fields {
		Richvale : 8;
		Gifford : 8;
		Belcourt : 16;
	}
}

header_type Cooter {
	fields {
		Radom : 16;
		Stamford : 16;
		BigPark : 32;
		Fireco : 32;
		Markesan : 4;
		Cusick : 4;
		Lumberton : 8;
		Chemult : 16;
		Calcasieu : 16;
		Marbury : 16;
	}
}

header_type Coronado {
	fields {
		Dasher : 16;
		Tomato : 16;
		Laton : 16;
		Unionvale : 16;
	}
}



header_type Arvonia {
	fields {
		Seagate : 16;
		Standish : 16;
		Flats : 8;
		Belmont : 8;
		Kewanee : 16;
	}
}

header_type Yardley {
	fields {
		Anoka : 48;
		Darby : 32;
		Stella : 48;
		Robbins : 32;
	}
}



header_type PineCity {
	fields {
		Elmhurst : 1;
		Holcomb : 1;
		Munich : 1;
		Picayune : 1;
		RioPecos : 1;
		Pineville : 3;
		ElmPoint : 5;
		Nanson : 3;
		SanPablo : 16;
	}
}

header_type Trona {
	fields {
		McGrady : 24;
		Buncombe : 8;
	}
}



header_type Sonoma {
	fields {
		Ponder : 8;
		Hayward : 24;
		Newhalen : 24;
		Biddle : 8;
	}
}

#endif



#ifndef Mikkalo
#define Mikkalo

parser start {
   return Houston;
}

#define Council        0x8100
#define Lenoir        0x0800
#define Wakeman        0x86dd
#define Baltimore        0x9100
#define Berkley        0x8847
#define Mattson         0x0806
#define Earlsboro        0x8035
#define Elderon        0x88cc
#define Baskett        0x8809

#define Bonsall              1
#define CassCity              2
#define Laneburg              4
#define Sharon               6
#define Baranof               17
#define Suwanee                47

#define Breda         0x501
#define Calva          0x506
#define Magazine          0x511
#define Tinaja          0x52F


#define Francis                 4789



#define Tolleson               0
#define Bemis              1
#define Cairo                2



#define Palmdale          0
#define Telegraph          4095
#define Hammonton  4096
#define Slana  8191



#define Heidrick                      0
#define McCracken                  0
#define Lorane                 1

header Waucoma Bellport;
header Waucoma Neuse;
header Longview Cornish[ 2 ];
header Rienzi Pensaukee;
header Rienzi Highcliff;
header LaHabra Menomonie;
header LaHabra Abbyville;
header Cooter LoonLake;
header Coronado Yatesboro;
header Cooter Waretown;
header Coronado Waitsburg;
header Sonoma Coventry;
header Arvonia Morita;
header PineCity LeeCreek;

parser Houston {
   extract( Bellport );
   return select( Bellport.Annette ) {
      Council : Dockton;
      Lenoir : Moapa;
      Wakeman : Tehachapi;
      Mattson  : Penitas;
      default        : ingress;
   }
}

parser Dockton {
   extract( Cornish[0] );
   return select( Cornish[0].NewRoads ) {
      Lenoir : Moapa;
      Wakeman : Tehachapi;
      Mattson  : Penitas;
      default : ingress;
   }
}

parser Moapa {
   extract( Pensaukee );
   set_metadata(Ringwood.Placedo, Pensaukee.Angus);
   set_metadata(Ringwood.Klawock, Pensaukee.Guadalupe);
   set_metadata(Ringwood.Sturgeon, Pensaukee.Tunis);
   set_metadata(Ringwood.Miller, 0);
   set_metadata(Ringwood.Copley, 1);
   return select(Pensaukee.Polkville, Pensaukee.Dollar, Pensaukee.Angus) {
      Magazine : Stambaugh;
      default : ingress;
   }
}

parser Tehachapi {
   extract( Abbyville );
   set_metadata(Ringwood.Placedo, Abbyville.Hackney);
   set_metadata(Ringwood.Klawock, Abbyville.TiePlant);
   set_metadata(Ringwood.Sturgeon, Abbyville.Musella);
   set_metadata(Ringwood.Miller, 1);
   set_metadata(Ringwood.Copley, 0);
   return ingress;
}

parser Penitas {
   extract( Morita );
   return ingress;
}

parser Stambaugh {
   extract(Yatesboro);
   return select(Yatesboro.Tomato) {
      Francis : Klukwan;
      default : ingress;
    }
}

parser Winnebago {
   set_metadata(Wentworth.Colson, Cairo);
   return Saltair;
}

parser DeGraff {
   set_metadata(Wentworth.Colson, Cairo);
   return McDougal;
}

parser Darco {
   extract(LeeCreek);
   return select(LeeCreek.Elmhurst, LeeCreek.Holcomb, LeeCreek.Munich, LeeCreek.Picayune, LeeCreek.RioPecos,
             LeeCreek.Pineville, LeeCreek.ElmPoint, LeeCreek.Nanson, LeeCreek.SanPablo) {
      Lenoir : Winnebago;
      Wakeman : DeGraff;
      default : ingress;
   }
}

parser Klukwan {
   extract(Coventry);
   set_metadata(Wentworth.Colson, Bemis);
   return Woodstown;
}

parser Saltair {
   extract( Highcliff );
   set_metadata(Ringwood.Cecilton, Highcliff.Angus);
   set_metadata(Ringwood.Remsen, Highcliff.Guadalupe);
   set_metadata(Ringwood.Zebina, Highcliff.Tunis);
   set_metadata(Ringwood.Mendocino, 0);
   set_metadata(Ringwood.Pumphrey, 1);
   return ingress;
}

parser McDougal {
   extract( Menomonie );
   set_metadata(Ringwood.Cecilton, Menomonie.Hackney);
   set_metadata(Ringwood.Remsen, Menomonie.TiePlant);
   set_metadata(Ringwood.Zebina, Menomonie.Musella);
   set_metadata(Ringwood.Mendocino, 1);
   set_metadata(Ringwood.Pumphrey, 0);
   return ingress;
}

parser Woodstown {
   extract( Neuse );
   return select( Neuse.Annette ) {
      Lenoir: Saltair;
      Wakeman: McDougal;
      default: ingress;
   }
}
#endif

metadata Almont Wentworth;
metadata Duster Paxico;
metadata Melmore DewyRose;
metadata Camilla Ringwood;
metadata DuBois Belcher;
metadata Challis Biscay;
metadata Ardara Lemhi;
metadata Woolwine IdaGrove;
metadata Fletcher Donna;
metadata Wayne Natalbany;
metadata Willmar Thach;
metadata Converse Alden;






@pragma pa_solitary ingress Wentworth.Dauphin
@pragma pa_solitary ingress Wentworth.Rocklin
@pragma pa_solitary ingress Wentworth.Bonner
@pragma pa_solitary egress Paxico.Collis
@pragma pa_solitary ig_intr_md_for_tm.ucast_egress_port

@pragma pa_atomic ingress Thach.Findlay
@pragma pa_solitary ingress Thach.Findlay
@pragma pa_atomic ingress Thach.Carnero
@pragma pa_solitary ingress Thach.Carnero













#undef Ketchum

#undef CoalCity
#undef Kaibab
#undef Hennessey
#undef Mulvane
#undef Weyauwega

#undef Embarrass
#undef Alakanuk
#undef Ozona

#undef Ferrum
#undef Barclay
#undef Silvertip
#undef Castle
#undef Wakefield
#undef Frewsburg
#undef Swanlake
#undef Baytown
#undef McCleary
#undef Throop
#undef DuPont
#undef Lonepine
#undef Moorcroft

#undef Dryden
#undef Goldsboro
#undef Elbing
#undef Seaforth
#undef Cornwall
#undef Dundee
#undef Norias
#undef EastDuke
#undef Ocilla
#undef Spanaway
#undef Newsoms
#undef Ahmeek

#undef Carlson

#undef Azalia







#define Ketchum 288


#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define CoalCity      65536
#define Kaibab      65536
#define Hennessey 512
#define Mulvane 512
#define Weyauwega      512


#define Embarrass     1024
#define Alakanuk    1024
#define Ozona     256


#define Ferrum 512
#define Barclay 65536
#define Silvertip 65536
#define Castle   16384
#define Wakefield         131072
#define Frewsburg 65536
#define Swanlake 1024
#define Baytown 2048
#define McCleary 16384
#define Throop 8192
#define DuPont 65536
#define Lonepine 8192
#define Moorcroft 2048


#define Dryden 1024
#define Goldsboro 4096
#define Elbing 4096
#define Seaforth 4096
#define Cornwall 4096
#define Dundee 1024
#define Norias 4096
#define Ocilla 64
#define Spanaway 1
#define Newsoms  8
#define Ahmeek 512


#define Carlson 0


#define Azalia    4096

#endif



#ifndef Norridge
#define Norridge

action Roseau() {
   no_op();
}

#endif

















action Keltys(Flomaton, Swifton, Cabot, Paisano, Nightmute, BoyRiver) {
    modify_field(DewyRose.Fairchild, Flomaton);
    modify_field(DewyRose.Seguin, Swifton);
    modify_field(DewyRose.Almelund, Cabot);
    modify_field(DewyRose.Ludlam, Paisano);
    modify_field(DewyRose.CapeFair, Nightmute);
    modify_field(DewyRose.Lowden, BoyRiver);
}

@pragma command_line --no-dead-code-elimination
table RiceLake {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Keltys;
    }
    size : Ketchum;
}

control UtePark {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(RiceLake);
    }
}





action Wyncote(Parthenon) {
   modify_field( Paxico.Calamine, 1 );
   modify_field( Paxico.Lucien, Parthenon);
   modify_field( Wentworth.SandCity, 1 );
}

action Poneto() {
   modify_field( Wentworth.Hooks, 1 );
   modify_field( Wentworth.Oregon, 1 );
}

action Sumner() {
   modify_field( Wentworth.SandCity, 1 );
}

action Belmond() {
   modify_field( Wentworth.Rainelle, 1 );
}

action Frankston() {
   modify_field( Wentworth.Oregon, 1 );
}


table Engle {
   reads {
      Bellport.Ruthsburg : ternary;
      Bellport.Mulliken : ternary;
   }

   actions {
      Wyncote;
      Poneto;
      Sumner;
      Belmond;
      Frankston;
   }
   default_action : Frankston;
   size : Hennessey;
}

action Lindy() {
   modify_field( Wentworth.Parkville, 1 );
}


table Kotzebue {
   reads {
      Bellport.Gomez : ternary;
      Bellport.Starkey : ternary;
   }

   actions {
      Lindy;
   }
   size : Mulvane;
}


control Valencia {
   apply( Engle );
   apply( Kotzebue );
}




action Heizer() {
   modify_field( Belcher.Ruston, Highcliff.Rankin );
   modify_field( Belcher.Dialville, Highcliff.Norwood );
   modify_field( Belcher.Govan, Highcliff.Dacono );
   modify_field( Biscay.Everetts, Menomonie.Waterman );
   modify_field( Biscay.Rossburg, Menomonie.Domingo );
   modify_field( Biscay.Waupaca, Menomonie.Woodfords );


   modify_field( Wentworth.Wrenshall, Neuse.Ruthsburg );
   modify_field( Wentworth.Choptank, Neuse.Mulliken );
   modify_field( Wentworth.Millbrook, Neuse.Gomez );
   modify_field( Wentworth.Baxter, Neuse.Starkey );
   modify_field( Wentworth.Ryderwood, Neuse.Annette );
   modify_field( Wentworth.Caliente, Ringwood.Zebina );
   modify_field( Wentworth.Bluford, Ringwood.Cecilton );
   modify_field( Wentworth.TinCity, Ringwood.Remsen );
   modify_field( Wentworth.Bernard, Ringwood.Pumphrey );
   modify_field( Wentworth.Kiwalik, Ringwood.Mendocino );
}

action Reidland() {
   modify_field( Wentworth.Colson, Tolleson );
   modify_field( Belcher.Ruston, Pensaukee.Rankin );
   modify_field( Belcher.Dialville, Pensaukee.Norwood );
   modify_field( Belcher.Govan, Pensaukee.Dacono );
   modify_field( Biscay.Everetts, Abbyville.Waterman );
   modify_field( Biscay.Rossburg, Abbyville.Domingo );
   modify_field( Biscay.Waupaca, Abbyville.Woodfords );


   modify_field( Wentworth.Wrenshall, Bellport.Ruthsburg );
   modify_field( Wentworth.Choptank, Bellport.Mulliken );
   modify_field( Wentworth.Millbrook, Bellport.Gomez );
   modify_field( Wentworth.Baxter, Bellport.Starkey );
   modify_field( Wentworth.Ryderwood, Bellport.Annette );
   modify_field( Wentworth.Caliente, Ringwood.Sturgeon );
   modify_field( Wentworth.Bluford, Ringwood.Placedo );
   modify_field( Wentworth.TinCity, Ringwood.Klawock );
   modify_field( Wentworth.Bernard, Ringwood.Copley );
   modify_field( Wentworth.Kiwalik, Ringwood.Miller );
}

table Kaaawa {
   reads {
      Bellport.Ruthsburg : exact;
      Bellport.Mulliken : exact;
      Pensaukee.Norwood : exact;
      Wentworth.Colson : exact;
   }

   actions {
      Heizer;
      Reidland;
   }

   default_action : Reidland();
   size : Dryden;
}


action Belvidere() {
   modify_field( Wentworth.Dauphin, DewyRose.Almelund );
   modify_field( Wentworth.Rocklin, DewyRose.Fairchild);
}

action SeaCliff( Garrison ) {
   modify_field( Wentworth.Dauphin, Garrison );
   modify_field( Wentworth.Rocklin, DewyRose.Fairchild);
}

action Madawaska() {
   modify_field( Wentworth.Dauphin, Cornish[0].KawCity );
   modify_field( Wentworth.Rocklin, DewyRose.Fairchild);
}

table Fennimore {
   reads {
      DewyRose.Fairchild : ternary;
      Cornish[0] : valid;
      Cornish[0].KawCity : ternary;
   }

   actions {
      Belvidere;
      SeaCliff;
      Madawaska;
   }
   size : Seaforth;
}

action McCaskill( Leetsdale ) {
   modify_field( Wentworth.Rocklin, Leetsdale );
}

action Goessel() {

   modify_field( Wentworth.Chunchula, 1 );
   modify_field( Donna.Sedona,
                 Lorane );
}

table Uhland {
   reads {
      Pensaukee.Rankin : exact;
   }

   actions {
      McCaskill;
      Goessel;
   }
   default_action : Goessel;
   size : Elbing;
}

action Epsie( Maiden, Oconee, Ghent, Rotan, Decherd,
                        Almeria, Saluda ) {
   modify_field( Wentworth.Dauphin, Maiden );
   modify_field( Wentworth.Nuevo, Saluda );
   Gratiot(Oconee, Ghent, Rotan, Decherd,
                        Almeria );
}

action Millstadt() {
   modify_field( Wentworth.Rhinebeck, 1 );
}

table LaVale {
   reads {
      Coventry.Newhalen : exact;
   }

   actions {
      Epsie;
      Millstadt;
   }
   size : Goldsboro;
}

action Gratiot(Oconee, Ghent, Rotan, Decherd,
                        Almeria ) {
   modify_field( IdaGrove.Maxwelton, Oconee );
   modify_field( IdaGrove.Ingraham, Ghent );
   modify_field( IdaGrove.Kinards, Rotan );
   modify_field( IdaGrove.Kosmos, Decherd );
   modify_field( IdaGrove.IowaCity, Almeria );
}

action Vacherie(Oconee, Ghent, Rotan, Decherd,
                        Almeria ) {
   modify_field( Wentworth.Bonner, DewyRose.Almelund );
   modify_field( Wentworth.Nuevo, 1 );
   Gratiot(Oconee, Ghent, Rotan, Decherd,
                        Almeria );
}

action Claunch(Senatobia, Oconee, Ghent, Rotan,
                        Decherd, Almeria ) {
   modify_field( Wentworth.Bonner, Senatobia );
   modify_field( Wentworth.Nuevo, 1 );
   Gratiot(Oconee, Ghent, Rotan, Decherd,
                        Almeria );
}

action Millican(Oconee, Ghent, Rotan, Decherd,
                        Almeria ) {
   modify_field( Wentworth.Bonner, Cornish[0].KawCity );
   modify_field( Wentworth.Nuevo, 1 );
   Gratiot(Oconee, Ghent, Rotan, Decherd,
                        Almeria );
}

table Laney {
   reads {
      DewyRose.Almelund : exact;
   }

   actions {
      Vacherie;
   }

   size : Cornwall;
}

table Finley {
   reads {
      DewyRose.Fairchild : exact;
      Cornish[0].KawCity : exact;
   }

   actions {
      Claunch;
      Roseau;
   }
   default_action : Roseau;

   size : Dundee;
}

table Meyers {
   reads {
      Cornish[0].KawCity : exact;
   }

   actions {
      Millican;
   }

   size : Norias;
}

control Pierpont {
   apply( Kaaawa ) {
         Heizer {
            apply( Uhland );
            apply( LaVale );
         }
         Reidland {
            if ( DewyRose.Ludlam == 1 ) {
               apply( Fennimore );
            }
            if ( valid( Cornish[ 0 ] ) ) {

               apply( Finley ) {
                  Roseau {

                     apply( Meyers );
                  }
               }
            } else {

               apply( Laney );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Patchogue {
    width  : 1;
    static : Realitos;
    instance_count : 262144;
}

register LaConner {
    width  : 1;
    static : Kinney;
    instance_count : 262144;
}

blackbox stateful_alu Flourtown {
    reg : Patchogue;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Lemhi.Maybeury;
}

blackbox stateful_alu Lordstown {
    reg : LaConner;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Lemhi.Goodlett;
}

field_list Harleton {
    DewyRose.Lowden;
    Cornish[0].KawCity;
}

field_list_calculation Millsboro {
    input { Harleton; }
    algorithm: identity;
    output_width: 18;
}

action Basehor() {
    Flourtown.execute_stateful_alu_from_hash(Millsboro);
}

action Mishicot() {
    Lordstown.execute_stateful_alu_from_hash(Millsboro);
}

table Realitos {
    actions {
      Basehor;
    }
    default_action : Basehor;
    size : 1;
}

table Kinney {
    actions {
      Mishicot;
    }
    default_action : Mishicot;
    size : 1;
}
#endif

action ElLago(Calimesa) {
    modify_field(Lemhi.Goodlett, Calimesa);
}

@pragma  use_hash_action 0
table Catskill {
    reads {
       DewyRose.Lowden : exact;
    }
    actions {
      ElLago;
    }
    size : 64;
}

action McFaddin() {
   modify_field( Wentworth.Buras, DewyRose.Almelund );
   modify_field( Wentworth.Rosario, 0 );
}

table Zemple {
   actions {
      McFaddin;
   }
   size : 1;
}

action Omemee() {
   modify_field( Wentworth.Buras, Cornish[0].KawCity );
   modify_field( Wentworth.Rosario, 1 );
}

table Shields {
   actions {
      Omemee;
   }
   size : 1;
}

control Ottertail {
   if ( valid( Cornish[ 0 ] ) ) {
      apply( Shields );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( DewyRose.CapeFair == 1 ) {
         apply( Realitos );
         apply( Kinney );
      }
#endif
   } else {
      apply( Zemple );
      if( DewyRose.CapeFair == 1 ) {
         apply( Catskill );
      }
   }
}




field_list Boyce {
   Bellport.Ruthsburg;
   Bellport.Mulliken;
   Bellport.Gomez;
   Bellport.Starkey;
   Bellport.Annette;
}

field_list Oakley {

   Pensaukee.Angus;
   Pensaukee.Rankin;
   Pensaukee.Norwood;
}

field_list Westway {
   Abbyville.Waterman;
   Abbyville.Domingo;
   Abbyville.Woodfords;
   Abbyville.Hackney;
}

field_list Florien {
   Pensaukee.Angus;
   Pensaukee.Rankin;
   Pensaukee.Norwood;
   Yatesboro.Dasher;
   Yatesboro.Tomato;
}





field_list_calculation Myton {
    input {
        Boyce;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Challenge {
    input {
        Oakley;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Mesita {
    input {
        Westway;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Liberal {
    input {
        Florien;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Alnwick() {
    modify_field_with_hash_based_offset(Alden.Hobart, 0,
                                        Myton, 4294967296);
}

action Kenvil() {
    modify_field_with_hash_based_offset(Alden.Monaca, 0,
                                        Challenge, 4294967296);
}

action Minto() {
    modify_field_with_hash_based_offset(Alden.Monaca, 0,
                                        Mesita, 4294967296);
}

action Moylan() {
    modify_field_with_hash_based_offset(Alden.Graford, 0,
                                        Liberal, 4294967296);
}

table Eddington {
   actions {
      Alnwick;
   }
   size: 1;
}

control Evendale {
   apply(Eddington);
}

table Kempner {
   actions {
      Kenvil;
   }
   size: 1;
}

table Cortland {
   actions {
      Minto;
   }
   size: 1;
}

control Humeston {
   if ( valid( Pensaukee ) ) {
      apply(Kempner);
   } else {
      if ( valid( Abbyville ) ) {
         apply(Cortland);
      }
   }
}

table Parkline {
   actions {
      Moylan;
   }
   size: 1;
}

control Varnell {
   if ( valid( Yatesboro ) ) {
      apply(Parkline);
   }
}



action Frederick() {
    modify_field(Thach.Findlay, Alden.Hobart);
}

action Belpre() {
    modify_field(Thach.Findlay, Alden.Monaca);
}

action Manville() {
    modify_field(Thach.Findlay, Alden.Graford);
}

@pragma immediate 0
table Rockland {
   reads {
      Waretown.valid : ternary;
      Waitsburg.valid : ternary;
      Highcliff.valid : ternary;
      Menomonie.valid : ternary;
      Neuse.valid : ternary;
      LoonLake.valid : ternary;
      Yatesboro.valid : ternary;
      Pensaukee.valid : ternary;
      Abbyville.valid : ternary;
      Bellport.valid : ternary;
   }
   actions {
      Frederick;
      Belpre;
      Manville;
      Roseau;
   }
   default_action : Roseau();
   size: Ozona;
}

control Kingsgate {
   apply(Rockland);
}





counter BigBay {
   type : packets_and_bytes;
   direct : Stewart;
   min_width: 16;
}

action Hayfork() {
   modify_field(Wentworth.Spraberry, 1 );
}

table Stewart {
   reads {
      DewyRose.Lowden : exact;
      Lemhi.Goodlett : ternary;
      Lemhi.Maybeury : ternary;
      Wentworth.Rhinebeck : ternary;
      Wentworth.Parkville : ternary;
      Wentworth.Hooks : ternary;
   }

   actions {
      Hayfork;
      Roseau;
   }
   default_action : Roseau;
   size : Weyauwega;
}

register Pueblo {
   width: 1;
   static: Westview;
   instance_count: Kaibab;
}

#ifdef __TARGET_TOFINO__
blackbox stateful_alu Sunrise{
    reg: Pueblo;
    update_lo_1_value: set_bit;
}
#endif

action Traskwood(Manilla) {
#if defined(BMV2) || defined(BMV2TOFINO)
   register_write(Pueblo, Manilla, 1);
#else
   Sunrise.execute_stateful_alu();
#endif

}

action Melstrand() {

   modify_field(Wentworth.Wellford, 1 );
   modify_field(Donna.Sedona,
                McCracken);
}

table Westview {
   reads {
      Wentworth.Millbrook : exact;
      Wentworth.Baxter : exact;
      Wentworth.Dauphin : exact;
      Wentworth.Rocklin : exact;
   }

   actions {
      Traskwood;
      Melstrand;
   }
   size : Kaibab;
}

action Reidville() {
   modify_field( IdaGrove.Maljamar, 1 );
}

table Abernant {
   reads {
      Wentworth.Bonner : ternary;
      Wentworth.Wrenshall : exact;
      Wentworth.Choptank : exact;
   }
   actions {
      Reidville;
   }
   size: Ferrum;
}

control Kathleen {
   if( Wentworth.Spraberry == 0 ) {
      apply( Abernant );
   }
}

control Achille {
   apply( Stewart ) {
      Roseau {



         if (DewyRose.Seguin == 0 and Wentworth.Chunchula == 0) {
            apply( Westview );
         }
         apply(Abernant);
      }
   }
}

field_list Kalvesta {
    Donna.Sedona;
    Wentworth.Millbrook;
    Wentworth.Baxter;
    Wentworth.Dauphin;
    Wentworth.Rocklin;
}

action Dabney() {
   generate_digest(Heidrick, Kalvesta);
}

table Verbena {
   actions {
      Dabney;
   }
   size : 1;
}

control Gully {
   if (Wentworth.Wellford == 1) {
      apply( Verbena );
   }
}



table Murdock {


   reads {
      Biscay.BigPiney : exact;
   }
   actions {
      Otisco;
   }
   size : Moorcroft;
}

table Ralls {



   reads {
      Biscay.Coleman : exact;
   }
   actions {
      Otisco;
   }
   size : Lonepine;
}

action Cross( Nisland ) {
   modify_field( Biscay.Coleman, Nisland );
}

table Onley {
   reads {
      IdaGrove.Maxwelton : exact;

      Biscay.Rossburg mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Cross;
      Roseau;
   }
   default_action : Roseau();
   size : Throop;
}

@pragma atcam_partition_index Biscay.Coleman
@pragma atcam_number_partitions Throop
table Goosport {
   reads {
      Biscay.Coleman : exact;

      Biscay.Rossburg mask 0x000007FFFFFFFFFF0000000000000000 : lpm;
   }

   actions {
      Otisco;
      Roseau;
   }
   default_action : Roseau();
   size : DuPont;
}

action Brookneal( Anahola ) {
   modify_field( Biscay.BigPiney, Anahola );
}

table Yakutat {

   reads {
      IdaGrove.Maxwelton : exact;
      Biscay.Rossburg : lpm;
   }

   actions {
      Brookneal;
      Roseau;
   }

   default_action : Roseau();
   size : Baytown;
}

@pragma atcam_partition_index Biscay.BigPiney
@pragma atcam_number_partitions Baytown
table Hurst {
   reads {
      Biscay.BigPiney : exact;


      Biscay.Rossburg mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Otisco;
      Roseau;
   }

   default_action : Roseau();
   size : McCleary;
}

@pragma idletime_precision 1
table Wells {

   reads {
      IdaGrove.Maxwelton : exact;
      Belcher.Dialville : lpm;
   }

   actions {
      Otisco;
      Roseau;
   }

   default_action : Roseau();
   size : Swanlake;
   support_timeout : true;
}

action Libby(Shabbona) {
   modify_field(Belcher.Hawthorne, Shabbona);
}

table Peebles {
   reads {
      IdaGrove.Maxwelton : exact;
      Belcher.Dialville : lpm;
   }

   actions {
      Libby;
   }

   size : Castle;
}

@pragma atcam_partition_index Belcher.Hawthorne
@pragma atcam_number_partitions Castle
table Okarche {
   reads {
      Belcher.Hawthorne : exact;



      Belcher.Dialville mask 0x000fffff : lpm;
   }
   actions {
      Otisco;
      Roseau;
   }

   size : Wakefield;
}

action Otisco( Highfill ) {
   modify_field( Paxico.Raceland, 1 );
   modify_field( Natalbany.Requa, Highfill );
}

@pragma idletime_precision 1
table Balmville {
   reads {
      IdaGrove.Maxwelton : exact;
      Belcher.Dialville : exact;
   }

   actions {
      Otisco;
      Roseau;
   }
   default_action : Roseau();
   size : Barclay;
   support_timeout : true;
}

@pragma idletime_precision 1
table Waimalu {
   reads {
      IdaGrove.Maxwelton : exact;
      Biscay.Rossburg : exact;
   }

   actions {
      Otisco;
      Roseau;
   }
   default_action : Roseau();
   size : Silvertip;
   support_timeout : true;
}

action RioLajas(Hopkins, Northlake, Lynndyl) {
   modify_field(Paxico.Prismatic, Lynndyl);
   modify_field(Paxico.Bajandas, Hopkins);
   modify_field(Paxico.Holyoke, Northlake);
   modify_field(Paxico.Raceland, 1);
}

table Philip {
   reads {
      Natalbany.Requa : exact;
   }

   actions {
      RioLajas;
   }
   size : Frewsburg;
}

control Winfall {
   if ( Wentworth.Spraberry == 0 and IdaGrove.Maljamar == 1 ) {
      if ( ( IdaGrove.Ingraham == 1 ) and ( Wentworth.Bernard == 1 ) ) {
         apply( Balmville ) {
            Roseau {
               apply( Peebles );
               if( Belcher.Hawthorne != 0 ) {
                  apply( Okarche );
               }
               if (Natalbany.Requa == 0 ) {
                  apply( Wells );
               }
            }
         }
      } else if ( ( IdaGrove.Kinards == 1 ) and ( Wentworth.Kiwalik == 1 ) ) {
         apply( Waimalu ) {
            Roseau {
               apply( Yakutat ) {
                  Brookneal {
                     apply( Hurst ) {
                        Roseau {
                           apply( Murdock );
                        }
                     }
                  }
                  Roseau {

                     apply( Onley ) {
                        Cross {
                           apply( Goosport ) {
                              Roseau {
                                 apply( Ralls );
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Waxhaw {
   if( Natalbany.Requa != 0 ) {
      apply( Philip );
   }
}



field_list Coolin {
   Thach.Findlay;
}

field_list_calculation Shawmut {
    input {
        Coolin;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Hackamore {
    selection_key : Shawmut;
    selection_mode : resilient;
}

action ElMango(Fontana) {
   modify_field(Paxico.Waukesha, Fontana);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Fontana);
}

action_profile Coulee {
    actions {
        ElMango;
        Roseau;
    }
    size : Alakanuk;
    dynamic_action_selection : Hackamore;
}

table Millhaven {
   reads {
      Paxico.Waukesha : exact;
   }
   action_profile: Coulee;
   size : Embarrass;
}

control Lapoint {
   if ((Wentworth.Spraberry == 0) and (Paxico.Waukesha & 0x2000) == 0x2000) {
      apply(Millhaven);
   }
}



action Henderson() {
   modify_field(Paxico.Bajandas, Wentworth.Wrenshall);
   modify_field(Paxico.Holyoke, Wentworth.Choptank);
   modify_field(Paxico.Woodfield, Wentworth.Millbrook);
   modify_field(Paxico.Moreland, Wentworth.Baxter);
   modify_field(Paxico.Prismatic, Wentworth.Dauphin);
}

table Micco {
   actions {
      Henderson;
   }
   default_action : Henderson();
   size : 1;
}

control Flasher {
   if (Wentworth.Dauphin!=0) {
      apply( Micco );
   }
}

action Knolls() {
   modify_field(Paxico.Driftwood, 1);
   modify_field(Paxico.Rosboro, 1);
   modify_field(Paxico.Collis, Paxico.Prismatic);
}

action Harpster() {
}



@pragma ways 1
table Hemet {
   reads {
      Paxico.Bajandas : exact;
      Paxico.Holyoke : exact;
   }
   actions {
      Knolls;
      Harpster;
   }
   default_action : Harpster;
   size : 1;
}

action Powers() {
   modify_field(Paxico.HornLake, 1);
   modify_field(Paxico.Geistown, 1);
   add(Paxico.Collis, Paxico.Prismatic, Hammonton);
}

table Nighthawk {
   actions {
      Powers;
   }
   default_action : Powers;
   size : 1;
}

action McLean() {
   modify_field(Paxico.Hauppauge, 1);
   modify_field(Paxico.Collis, Paxico.Prismatic);
}

table Wetonka {
   actions {
      McLean;
   }
   default_action : McLean();
   size : 1;
}

action Newhalem(Riverbank) {
   modify_field(Paxico.Emerado, 1);
   modify_field(Paxico.Waukesha, Riverbank);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Riverbank);
}

action RichBar(Orrick) {
   modify_field(Paxico.HornLake, 1);
   modify_field(Paxico.Collis, Orrick);
}

action Kooskia() {
}

table Peoria {
   reads {
      Paxico.Bajandas : exact;
      Paxico.Holyoke : exact;
      Paxico.Prismatic : exact;
   }

   actions {
      Newhalem;
      RichBar;
      Kooskia;
   }
   default_action : Kooskia();
   size : CoalCity;
}

control Bogota {
   if (Wentworth.Spraberry == 0) {
      apply(Peoria) {
         Kooskia {
            apply(Hemet) {
               Harpster {
                  if ((Paxico.Bajandas & 0x010000) == 0x010000) {
                     apply(Nighthawk);
                  } else {
                     apply(Wetonka);
                  }
               }
            }
         }
      }
   }
}


action Idylside() {
   modify_field(Wentworth.Spraberry, 1);
}

table Mynard {
   actions {
      Idylside;
   }
   default_action : Idylside;
   size : 1;
}

control Weches {
   if ((Paxico.Raceland==0) and (Wentworth.Rocklin==Paxico.Waukesha)) {
      apply(Mynard);
   }
}



action Malinta( Coalwood ) {
   modify_field( Paxico.Kranzburg, Coalwood );
}

action Crossnore() {
   modify_field( Paxico.Kranzburg, Paxico.Prismatic );
}

table Cypress {
   reads {
      eg_intr_md.egress_port : exact;
      Paxico.Prismatic : exact;
   }

   actions {
      Malinta;
      Crossnore;
   }
   default_action : Crossnore;
   size : Azalia;
}

control Sylva {
   apply( Cypress );
}



action Caplis( Lakota, Parker ) {
   modify_field( Paxico.Wabbaseka, Lakota );
   modify_field( Paxico.Hebbville, Parker );
}


table Bayonne {
   reads {
      Paxico.Grenville : exact;
   }

   actions {
      Caplis;
   }
   size : Newsoms;
}

action Remington() {
   no_op();
}

action Kenton() {
   modify_field( Bellport.Annette, Cornish[0].NewRoads );
   remove_header( Cornish[0] );
}

table Chatom {
   actions {
      Kenton;
   }
   default_action : Kenton;
   size : Spanaway;
}

action Hibernia() {
   no_op();
}

action Needham() {
   add_header( Cornish[ 0 ] );
   modify_field( Cornish[0].KawCity, Paxico.Kranzburg );
   modify_field( Cornish[0].NewRoads, Bellport.Annette );
   modify_field( Bellport.Annette, Council );
}



table Jenkins {
   reads {
      Paxico.Kranzburg : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Hibernia;
      Needham;
   }
   default_action : Needham;
   size : Ocilla;
}

action Harris() {
   modify_field(Bellport.Ruthsburg, Paxico.Bajandas);
   modify_field(Bellport.Mulliken, Paxico.Holyoke);
   modify_field(Bellport.Gomez, Paxico.Wabbaseka);
   modify_field(Bellport.Starkey, Paxico.Hebbville);
}

action Stockdale() {
   Harris();
   add_to_field(Pensaukee.Guadalupe, -1);
}

action Cadwell() {
   Harris();
   add_to_field(Abbyville.TiePlant, -1);
}






table Sledge {
   reads {
      Paxico.Carbonado : exact;
      Paxico.Grenville : exact;
      Paxico.Raceland : exact;
      Pensaukee.valid : ternary;
      Abbyville.valid : ternary;
   }

   actions {
      Stockdale;
      Cadwell;
   }
   size : Ahmeek;
}

control Hobson {
   apply( Chatom );
}

control Power {
   apply( Jenkins );
}

control Haverford {
   apply( Bayonne );
   apply( Sledge );
}



field_list LaUnion {
    Donna.Sedona;
    Wentworth.Dauphin;
    Neuse.Gomez;
    Neuse.Starkey;
    Pensaukee.Rankin;
}

action Tingley() {
   generate_digest(Heidrick, LaUnion);
}

table Pearl {
   actions {
      Tingley;
   }

   default_action : Tingley;
   size : 1;
}

control Yreka {
   if (Wentworth.Chunchula == 1) {
      apply(Pearl);
   }
}

control ingress {

   UtePark();
   Valencia();
   Pierpont();
   Ottertail();
   Evendale();


   Achille();

   Humeston();
   Varnell();


   Winfall();

   Flasher();

   Waxhaw();


   Kingsgate();



   Bogota();


   Weches();
   Yreka();
   Gully();


   if( valid( Cornish[0] ) ) {
      Hobson();
   }


   Lapoint();
}

control egress {
   Sylva();
   Haverford();
   Power();
}

