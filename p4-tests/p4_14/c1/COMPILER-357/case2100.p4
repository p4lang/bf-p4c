// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 11752







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>






@pragma pa_solitary ingress Nashoba.Allons
@pragma pa_solitary ingress Nashoba.Ekron
@pragma pa_solitary ingress Nashoba.Kekoskee
@pragma pa_solitary egress Barksdale.Range
@pragma pa_solitary ingress ig_intr_md_for_tm.ucast_egress_port
@pragma pa_solitary egress ig_intr_md_for_tm.ucast_egress_port
@pragma pa_atomic ingress Penrose.Philbrook
@pragma pa_solitary ingress Penrose.Philbrook
@pragma pa_atomic ingress Penrose.Lathrop
@pragma pa_solitary ingress Penrose.Lathrop



#ifndef Clover
#define Clover

header_type BigBar {
	fields {
		Caputa : 16;
		Sasser : 16;
		Hadley : 8;
		McHenry : 8;
		Kilbourne : 8;
		Lecanto : 8;
		Somis : 1;
		Gilliam : 1;
		Stillmore : 1;
		Eunice : 1;
		SaintAnn : 1;
		Blanchard : 3;
	}
}

header_type Goodrich {
	fields {
		Yakima : 24;
		Roodhouse : 24;
		Crumstown : 24;
		Hatchel : 24;
		Kerrville : 16;
		Allons : 16;
		Ekron : 16;
		Kekoskee : 16;
		Colstrip : 16;
		Denning : 8;
		Wapinitia : 8;
		Vallejo : 6;
		Portales : 1;
		MuleBarn : 1;
		Ladoga : 12;
		Berea : 2;
		Pollard : 1;
		Success : 1;
		McCammon : 1;
		BigRock : 1;
		Ivanhoe : 1;
		Charters : 1;
		Iselin : 1;
		Chualar : 1;
		Silesia : 1;
		FourTown : 1;
		Belcourt : 1;
		Laxon : 1;
		Noelke : 1;
		Halfa : 3;
	}
}

header_type Herring {
	fields {
		Maywood : 24;
		Greenlawn : 24;
		Thalmann : 24;
		Soledad : 24;
		Ebenezer : 24;
		Lemoyne : 24;
		Rotan : 16;
		Clauene : 16;
		Aspetuck : 16;
		Range : 16;
		Honalo : 12;
		Astatula : 3;
		Auvergne : 3;
		Pickett : 1;
		Powelton : 1;
		Devers : 1;
		Rockaway : 1;
		Mullins : 1;
		Winger : 1;
		Palomas : 1;
		Hannibal : 1;
		Timken : 8;
	}
}


header_type Shasta {
	fields {
		Coqui : 8;
		Bayard : 1;
		Spiro : 1;
		LasLomas : 1;
		Anaconda : 1;
		Glendale : 1;
		Cresco : 1;
	}
}

header_type Geistown {
	fields {
		Millstone : 32;
		Aurora : 32;
		Stennett : 6;
		Hallville : 16;
	}
}

header_type Syria {
	fields {
		Robbins : 128;
		Westpoint : 128;
		Conda : 20;
		Cistern : 8;
		Ohiowa : 11;
		Wyndmere : 8;
		Wanilla : 13;
	}
}

header_type Kingsland {
	fields {
		Walcott : 14;
		Baldwin : 1;
		Hanston : 12;
		Emigrant : 1;
		Oronogo : 1;
		Sitka : 6;
		Emsworth : 2;
		Garwood : 6;
		Layton : 3;
	}
}

header_type Norfork {
	fields {
		Mentone : 1;
		Oneonta : 1;
	}
}

header_type Floris {
	fields {
		Bevington : 8;
	}
}

header_type Halley {
	fields {
		Firesteel : 16;
		Plush : 11;
	}
}

header_type Laurie {
	fields {
		Raven : 32;
		CeeVee : 32;
		Wewela : 32;
	}
}

header_type Swansea {
	fields {
		Philbrook : 32;
		Lathrop : 32;
	}
}

header_type Craigmont {
	fields {
		Glenoma : 2;
	}
}
#endif



#ifndef Upalco
#define Upalco



header_type Dollar {
	fields {
		Waldo : 24;
		Halbur : 24;
		Barclay : 24;
		Bootjack : 24;
		Topanga : 16;
	}
}



header_type Covina {
	fields {
		LongPine : 3;
		Poynette : 1;
		Pinta : 12;
		Wrens : 16;
	}
}



header_type Odessa {
	fields {
		Cahokia : 4;
		Mariemont : 4;
		Anchorage : 6;
		Pearce : 2;
		Nestoria : 16;
		Aguilar : 16;
		Ragley : 3;
		Headland : 13;
		PellLake : 8;
		Attica : 8;
		Blencoe : 16;
		Corfu : 32;
		Ottertail : 32;
	}
}

header_type Lafayette {
	fields {
		Oskawalik : 4;
		Westview : 6;
		Topton : 2;
		Chewalla : 20;
		Suttle : 16;
		Hartford : 8;
		Darco : 8;
		Bayville : 128;
		Bluford : 128;
	}
}




header_type Kapaa {
	fields {
		Huntoon : 8;
		Basalt : 8;
		Albany : 16;
	}
}

header_type Suwannee {
	fields {
		Dorothy : 16;
		Milano : 16;
		Kapowsin : 32;
		Hinkley : 32;
		Hedrick : 4;
		Mecosta : 4;
		Palmdale : 8;
		Lizella : 16;
		Simla : 16;
		Calvary : 16;
	}
}

header_type Endicott {
	fields {
		Stecker : 16;
		Deeth : 16;
		Tinaja : 16;
		Mantee : 16;
	}
}



header_type Toccopola {
	fields {
		Mifflin : 16;
		Montalba : 16;
		Homeland : 8;
		Shawmut : 8;
		Loogootee : 16;
	}
}

header_type Roggen {
	fields {
		LaUnion : 48;
		Newtok : 32;
		Chispa : 48;
		Thatcher : 32;
	}
}



header_type Sunflower {
	fields {
		Heidrick : 1;
		Rhinebeck : 1;
		Burgdorf : 1;
		Cusick : 1;
		Dahlgren : 1;
		Highcliff : 3;
		Ingleside : 5;
		Pocopson : 3;
		Nipton : 16;
	}
}

header_type Whitten {
	fields {
		Broadmoor : 24;
		Brinkman : 8;
	}
}



header_type Ronan {
	fields {
		Paxtonia : 8;
		Ilwaco : 24;
		Hargis : 24;
		Annawan : 8;
	}
}

#endif



#ifndef Heppner
#define Heppner

parser start {
   return Catawba;
}

#define Rockleigh        0x8100
#define Hiwasse        0x0800
#define Bellwood        0x86dd
#define Arnold        0x9100
#define VanZandt        0x8847
#define Lapeer         0x0806
#define Troutman        0x8035
#define Mackey        0x88cc
#define Rankin        0x8809

#define Geismar              1
#define LakeHart              2
#define Goodyear              4
#define BigRiver               6
#define Immokalee               17
#define Ravenwood                47

#define Gratiot         0x501
#define Jayton          0x506
#define Novinger          0x511
#define Gardena          0x52F


#define Billett                 4789



#define Waumandee               0
#define Gwynn              1
#define Roswell                2



#define BigFork          0
#define Chilson          4095
#define Rains  4096
#define Hapeville  8191



#define Hobson                      0
#define Konnarock                  0
#define Burket                 1

header Dollar Skillman;
header Dollar Maydelle;
header Covina Ahmeek[ 2 ];
header Odessa Slick;
header Odessa Dialville;
header Lafayette Sylvester;
header Lafayette DuPont;
header Suwannee Santos;
header Endicott Tahlequah;
header Suwannee Hookstown;
header Endicott Anoka;
header Ronan Holliday;
header Toccopola Kingsdale;
header Sunflower Hamden;

parser Catawba {
   extract( Skillman );
   return select( Skillman.Topanga ) {
      Rockleigh : Tallevast;
      Hiwasse : Lenox;
      Bellwood : Olmstead;
      Lapeer  : McBride;
      default        : ingress;
   }
}

parser Tallevast {
   extract( Ahmeek[0] );

   set_metadata(Alamance.Blanchard, Ahmeek[0].LongPine );
   set_metadata(Alamance.SaintAnn, 1);
   return select( Ahmeek[0].Wrens ) {
      Hiwasse : Lenox;
      Bellwood : Olmstead;
      Lapeer  : McBride;
      default : ingress;
   }
}

parser Lenox {
   extract( Slick );
   set_metadata(Alamance.Hadley, Slick.Attica);
   set_metadata(Alamance.Kilbourne, Slick.PellLake);
   set_metadata(Alamance.Caputa, Slick.Nestoria);
   set_metadata(Alamance.Stillmore, 0);
   set_metadata(Alamance.Somis, 1);
   return select(Slick.Headland, Slick.Mariemont, Slick.Attica) {
      Novinger : KingCity;
      default : ingress;
   }
}

parser Olmstead {
   extract( DuPont );
   set_metadata(Alamance.Hadley, DuPont.Hartford);
   set_metadata(Alamance.Kilbourne, DuPont.Darco);
   set_metadata(Alamance.Caputa, DuPont.Suttle);
   set_metadata(Alamance.Stillmore, 1);
   set_metadata(Alamance.Somis, 0);
   return ingress;
}

parser McBride {
   extract( Kingsdale );
   return ingress;
}

parser KingCity {
   extract(Tahlequah);
   return select(Tahlequah.Deeth) {
      Billett : Leeville;
      default : ingress;
    }
}

parser Lyncourt {
   set_metadata(Nashoba.Berea, Roswell);
   return Booth;
}

parser WarEagle {
   set_metadata(Nashoba.Berea, Roswell);
   return Arminto;
}

parser Elbing {
   extract(Hamden);
   return select(Hamden.Heidrick, Hamden.Rhinebeck, Hamden.Burgdorf, Hamden.Cusick, Hamden.Dahlgren,
             Hamden.Highcliff, Hamden.Ingleside, Hamden.Pocopson, Hamden.Nipton) {
      Hiwasse : Lyncourt;
      Bellwood : WarEagle;
      default : ingress;
   }
}

parser Leeville {
   extract(Holliday);
   set_metadata(Nashoba.Berea, Gwynn);
   return Ephesus;
}

parser Booth {
   extract( Dialville );
   set_metadata(Alamance.McHenry, Dialville.Attica);
   set_metadata(Alamance.Lecanto, Dialville.PellLake);
   set_metadata(Alamance.Sasser, Dialville.Nestoria);
   set_metadata(Alamance.Eunice, 0);
   set_metadata(Alamance.Gilliam, 1);
   return ingress;
}

parser Arminto {
   extract( Sylvester );
   set_metadata(Alamance.McHenry, Sylvester.Hartford);
   set_metadata(Alamance.Lecanto, Sylvester.Darco);
   set_metadata(Alamance.Sasser, Sylvester.Suttle);
   set_metadata(Alamance.Eunice, 1);
   set_metadata(Alamance.Gilliam, 0);
   return ingress;
}

parser Ephesus {
   extract( Maydelle );
   return select( Maydelle.Topanga ) {
      Hiwasse: Booth;
      Bellwood: Arminto;
      default: ingress;
   }
}
#endif

metadata Goodrich Nashoba;
metadata Herring Barksdale;
metadata Kingsland Shine;
metadata BigBar Alamance;
metadata Geistown Moline;
metadata Syria Braxton;
metadata Norfork Comobabi;
metadata Shasta Wagener;
metadata Floris Quivero;
metadata Halley Roseau;
metadata Swansea Penrose;
metadata Laurie Edesville;
metadata Craigmont Cabot;













#undef Goulds

#undef Gorman
#undef Pillager
#undef Tamms
#undef Blanding
#undef Malabar

#undef Neshoba
#undef Pekin
#undef Quinhagak

#undef Saticoy
#undef Rowlett
#undef Milam
#undef McIntosh
#undef Nuangola
#undef Godfrey
#undef Draketown
#undef Cardenas
#undef Kranzburg
#undef Uniopolis
#undef Mapleview
#undef Perrin
#undef Millstadt
#undef Darden
#undef Buckfield
#undef Metzger
#undef Westbury
#undef Corry
#undef Toklat
#undef Burtrum
#undef PawPaw

#undef Bosco
#undef Fleetwood
#undef Strevell
#undef Shelbiana
#undef Fenwick
#undef Oketo
#undef Nuyaka
#undef Wimbledon
#undef Scottdale
#undef Wolsey
#undef BallClub
#undef Paoli
#undef Randall
#undef Oskaloosa
#undef Oklee


#undef Borth

#undef Quarry
#undef Barwick
#undef Doris
#undef Domingo

#undef Furman







#define Goulds 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Gorman      65536
#define Pillager      65536
#define Tamms 512
#define Blanding 512
#define Malabar      512


#define Neshoba     1024
#define Pekin    1024
#define Quinhagak     256


#define Saticoy 512
#define Rowlett 65536
#define Milam 65536
#define McIntosh 28672
#define Nuangola   16384
#define Godfrey 8192
#define Draketown         131072
#define Cardenas 65536
#define Kranzburg 1024
#define Uniopolis 2048
#define Mapleview 16384
#define Perrin 8192
#define Millstadt 65536

#define Darden 0x0000000000000000FFFFFFFFFFFFFFFF


#define Buckfield 0x000fffff
#define Corry 2

#define Metzger 0xFFFFFFFFFFFFFFFF0000000000000000

#define Westbury 0x000007FFFFFFFFFF0000000000000000
#define Toklat  6
#define PawPaw        2048
#define Burtrum       65536


#define Bosco 1024
#define Fleetwood 4096
#define Strevell 4096
#define Shelbiana 4096
#define Fenwick 4096
#define Oketo 1024
#define Nuyaka 4096
#define Scottdale 64
#define Wolsey 1
#define BallClub  8
#define Paoli 512


#define Randall 1
#define Oskaloosa 3
#define Oklee 80


#define Borth 0



#define Quarry 2048


#define Barwick 4096



#define Doris 2048
#define Domingo 4096




#define Furman    4096

#endif



#ifndef Bazine
#define Bazine

action Tarnov() {
   no_op();
}

action McCune() {
   modify_field(Nashoba.BigRock, 1 );
}

action Winside() {
   no_op();
}
#endif

















action Panaca(WestLine, Bucklin, Normangee, Neoga, Myrick, Malmo,
                 Amenia, Telida, Mattson) {
    modify_field(Shine.Walcott, WestLine);
    modify_field(Shine.Baldwin, Bucklin);
    modify_field(Shine.Hanston, Normangee);
    modify_field(Shine.Emigrant, Neoga);
    modify_field(Shine.Oronogo, Myrick);
    modify_field(Shine.Sitka, Malmo);
    modify_field(Shine.Emsworth, Amenia);
    modify_field(Shine.Layton, Telida);
    modify_field(Shine.Garwood, Mattson);
}

@pragma command_line --no-dead-code-elimination
table Lapoint {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Panaca;
    }
    size : Goulds;
}

control Chemult {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Lapoint);
    }
}





action Duffield(Hamburg) {
   modify_field( Barksdale.Pickett, 1 );
   modify_field( Barksdale.Timken, Hamburg);
   modify_field( Nashoba.FourTown, 1 );
}

action Bowden() {
   modify_field( Nashoba.Iselin, 1 );
   modify_field( Nashoba.Laxon, 1 );
}

action Crystola() {
   modify_field( Nashoba.FourTown, 1 );
}

action Belmore() {
   modify_field( Nashoba.Belcourt, 1 );
}

action Ferndale() {
   modify_field( Nashoba.Laxon, 1 );
}

counter Gastonia {
   type : packets_and_bytes;
   direct : Wilmore;
   min_width: 16;
}

table Wilmore {
   reads {
      Shine.Sitka : exact;
      Skillman.Waldo : ternary;
      Skillman.Halbur : ternary;
   }

   actions {
      Duffield;
      Bowden;
      Crystola;
      Belmore;
      Ferndale;
   }
   size : Tamms;
}

action SweetAir() {
   modify_field( Nashoba.Chualar, 1 );
}


table Inola {
   reads {
      Skillman.Barclay : ternary;
      Skillman.Bootjack : ternary;
   }

   actions {
      SweetAir;
   }
   size : Blanding;
}


control Sutton {
   apply( Wilmore );
   apply( Inola );
}




action Naylor() {
   modify_field( Moline.Millstone, Dialville.Corfu );
   modify_field( Moline.Aurora, Dialville.Ottertail );
   modify_field( Moline.Stennett, Dialville.Anchorage );
   modify_field( Braxton.Robbins, Sylvester.Bayville );
   modify_field( Braxton.Westpoint, Sylvester.Bluford );
   modify_field( Braxton.Conda, Sylvester.Chewalla );

   modify_field( Braxton.Wyndmere, Sylvester.Westview );
   modify_field( Nashoba.Yakima, Maydelle.Waldo );
   modify_field( Nashoba.Roodhouse, Maydelle.Halbur );
   modify_field( Nashoba.Crumstown, Maydelle.Barclay );
   modify_field( Nashoba.Hatchel, Maydelle.Bootjack );
   modify_field( Nashoba.Kerrville, Maydelle.Topanga );
   modify_field( Nashoba.Colstrip, Alamance.Sasser );
   modify_field( Nashoba.Denning, Alamance.McHenry );
   modify_field( Nashoba.Wapinitia, Alamance.Lecanto );
   modify_field( Nashoba.MuleBarn, Alamance.Gilliam );
   modify_field( Nashoba.Portales, Alamance.Eunice );
   modify_field( Nashoba.Noelke, 0 );
   modify_field( Shine.Emsworth, 2 );
   modify_field( Shine.Layton, 0 );
   modify_field( Shine.Garwood, 0 );
}

action Youngtown() {
   modify_field( Nashoba.Berea, Waumandee );
   modify_field( Moline.Millstone, Slick.Corfu );
   modify_field( Moline.Aurora, Slick.Ottertail );
   modify_field( Moline.Stennett, Slick.Anchorage );
   modify_field( Braxton.Robbins, DuPont.Bayville );
   modify_field( Braxton.Westpoint, DuPont.Bluford );
   modify_field( Braxton.Conda, DuPont.Chewalla );

   modify_field( Braxton.Wyndmere, DuPont.Westview );
   modify_field( Nashoba.Yakima, Skillman.Waldo );
   modify_field( Nashoba.Roodhouse, Skillman.Halbur );
   modify_field( Nashoba.Crumstown, Skillman.Barclay );
   modify_field( Nashoba.Hatchel, Skillman.Bootjack );
   modify_field( Nashoba.Kerrville, Skillman.Topanga );
   modify_field( Nashoba.Colstrip, Alamance.Caputa );
   modify_field( Nashoba.Denning, Alamance.Hadley );
   modify_field( Nashoba.Wapinitia, Alamance.Kilbourne );
   modify_field( Nashoba.MuleBarn, Alamance.Somis );
   modify_field( Nashoba.Portales, Alamance.Stillmore );
   modify_field( Nashoba.Halfa, Alamance.Blanchard );
   modify_field( Nashoba.Noelke, Alamance.SaintAnn );
}

table Wenona {
   reads {
      Skillman.Waldo : exact;
      Skillman.Halbur : exact;
      Slick.Ottertail : exact;
      Nashoba.Berea : exact;
   }

   actions {
      Naylor;
      Youngtown;
   }

   default_action : Youngtown();
   size : Bosco;
}


action Hanford() {
   modify_field( Nashoba.Allons, Shine.Hanston );
   modify_field( Nashoba.Ekron, Shine.Walcott);
}

action Edinburg( Yemassee ) {
   modify_field( Nashoba.Allons, Yemassee );
   modify_field( Nashoba.Ekron, Shine.Walcott);
}

action Moseley() {
   modify_field( Nashoba.Allons, Ahmeek[0].Pinta );
   modify_field( Nashoba.Ekron, Shine.Walcott);
}

table Crump {
   reads {
      Shine.Walcott : ternary;
      Ahmeek[0] : valid;
      Ahmeek[0].Pinta : ternary;
   }

   actions {
      Hanford;
      Edinburg;
      Moseley;
   }
   size : Shelbiana;
}

action Honokahua( TenSleep ) {
   modify_field( Nashoba.Ekron, TenSleep );
}

action Valeene() {

   modify_field( Nashoba.McCammon, 1 );
   modify_field( Quivero.Bevington,
                 Burket );
}

table Kaeleku {
   reads {
      Slick.Corfu : exact;
   }

   actions {
      Honokahua;
      Valeene;
   }
   default_action : Valeene;
   size : Strevell;
}

action PeaRidge( Shoreview, Surrency, Gullett, Conejo, Shingler,
                        Haslet, Edgemoor ) {
   modify_field( Nashoba.Allons, Shoreview );
   modify_field( Nashoba.Kekoskee, Shoreview );
   modify_field( Nashoba.Charters, Edgemoor );
   Duque(Surrency, Gullett, Conejo, Shingler,
                        Haslet );
}

action Glenolden() {
   modify_field( Nashoba.Ivanhoe, 1 );
}

table Myton {
   reads {
      Holliday.Hargis : exact;
   }

   actions {
      PeaRidge;
      Glenolden;
   }
   size : Fleetwood;
}

action Duque(Easley, Bicknell, Makawao, KeyWest,
                        Reynolds ) {
   modify_field( Wagener.Coqui, Easley );
   modify_field( Wagener.Bayard, Bicknell );
   modify_field( Wagener.LasLomas, Makawao );
   modify_field( Wagener.Spiro, KeyWest );
   modify_field( Wagener.Anaconda, Reynolds );
}

action Shabbona(Hooksett, Wetonka, Gotebo, Larsen,
                        Earlimart ) {
   modify_field( Nashoba.Kekoskee, Shine.Hanston );
   modify_field( Nashoba.Charters, 1 );
   Duque(Hooksett, Wetonka, Gotebo, Larsen,
                        Earlimart );
}

action Grygla(Gordon, Poipu, Ambler, Coronado,
                        Vieques, Virgin ) {
   modify_field( Nashoba.Kekoskee, Gordon );
   modify_field( Nashoba.Charters, 1 );
   Duque(Poipu, Ambler, Coronado, Vieques,
                        Virgin );
}

action Leland(Menifee, DewyRose, Lambert, Fergus,
                        Parkville ) {
   modify_field( Nashoba.Kekoskee, Ahmeek[0].Pinta );
   modify_field( Nashoba.Charters, 1 );
   Duque(Menifee, DewyRose, Lambert, Fergus,
                        Parkville );
}

table Bleecker {
   reads {
      Shine.Hanston : exact;
   }


   actions {
      Tarnov;
      Shabbona;
   }

   size : Fenwick;
}

@pragma action_default_only Tarnov
table Biggers {
   reads {
      Shine.Walcott : exact;
      Ahmeek[0].Pinta : exact;
   }

   actions {
      Grygla;
      Tarnov;
   }

   size : Oketo;
}

table Wyatte {
   reads {
      Ahmeek[0].Pinta : exact;
   }


   actions {
      Tarnov;
      Leland;
   }

   size : Nuyaka;
}

control Pinole {
   apply( Wenona ) {
         Naylor {
            apply( Kaeleku );
            apply( Myton );
         }
         Youngtown {
            if ( Shine.Emigrant == 1 ) {
               apply( Crump );
            }
            if ( valid( Ahmeek[ 0 ] ) ) {

               apply( Biggers ) {
                  Tarnov {

                     apply( Wyatte );
                  }
               }
            } else {

               apply( Bleecker );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Jemison {
    width  : 1;
    static : Tulalip;
    instance_count : 262144;
}

register Sprout {
    width  : 1;
    static : Duchesne;
    instance_count : 262144;
}

blackbox stateful_alu Pierpont {
    reg : Jemison;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Comobabi.Mentone;
}

blackbox stateful_alu Millikin {
    reg : Sprout;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Comobabi.Oneonta;
}

field_list Onarga {
    Shine.Sitka;
    Ahmeek[0].Pinta;
}

field_list_calculation Talbert {
    input { Onarga; }
    algorithm: identity;
    output_width: 18;
}

action Cadott() {
    Pierpont.execute_stateful_alu_from_hash(Talbert);
}

action Sequim() {
    Millikin.execute_stateful_alu_from_hash(Talbert);
}

table Tulalip {
    actions {
      Cadott;
    }
    default_action : Cadott;
    size : 1;
}

table Duchesne {
    actions {
      Sequim;
    }
    default_action : Sequim;
    size : 1;
}
#endif

action Hartwick(Beresford) {
    modify_field(Comobabi.Oneonta, Beresford);
}

@pragma  use_hash_action 0
table EastDuke {
    reads {
       Shine.Sitka : exact;
    }
    actions {
      Hartwick;
    }
    size : 64;
}

action Woodrow() {
   modify_field( Nashoba.Ladoga, Shine.Hanston );
   modify_field( Nashoba.Pollard, 0 );
}

table Fairhaven {
   actions {
      Woodrow;
   }
   size : 1;
}

action Evendale() {
   modify_field( Nashoba.Ladoga, Ahmeek[0].Pinta );
   modify_field( Nashoba.Pollard, 1 );
}

table Elihu {
   actions {
      Evendale;
   }
   size : 1;
}

control Chamois {
   if ( valid( Ahmeek[ 0 ] ) ) {
      apply( Elihu );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Shine.Oronogo == 1 ) {
         apply( Tulalip );
         apply( Duchesne );
      }
#endif
   } else {
      apply( Fairhaven );
      if( Shine.Oronogo == 1 ) {
         apply( EastDuke );
      }
   }
}




field_list Winnebago {
   Skillman.Waldo;
   Skillman.Halbur;
   Skillman.Barclay;
   Skillman.Bootjack;
   Skillman.Topanga;
}

field_list Padonia {

   Slick.Attica;
   Slick.Corfu;
   Slick.Ottertail;
}

field_list Picacho {
   DuPont.Bayville;
   DuPont.Bluford;
   DuPont.Chewalla;
   DuPont.Hartford;
}

field_list Shuqualak {
   Slick.Corfu;
   Slick.Ottertail;
   Tahlequah.Stecker;
   Tahlequah.Deeth;
}





field_list_calculation Virden {
    input {
        Winnebago;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Wellton {
    input {
        Padonia;
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
        Picacho;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Linville {
    input {
        Shuqualak;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Dolores() {
    modify_field_with_hash_based_offset(Edesville.Raven, 0,
                                        Virden, 4294967296);
}

action Croft() {
    modify_field_with_hash_based_offset(Edesville.CeeVee, 0,
                                        Wellton, 4294967296);
}

action Alnwick() {
    modify_field_with_hash_based_offset(Edesville.CeeVee, 0,
                                        LunaPier, 4294967296);
}

action ElkNeck() {
    modify_field_with_hash_based_offset(Edesville.Wewela, 0,
                                        Linville, 4294967296);
}

table Blossom {
   actions {
      Dolores;
   }
   size: 1;
}

control Brothers {
   apply(Blossom);
}

table RoseBud {
   actions {
      Croft;
   }
   size: 1;
}

table Rollins {
   actions {
      Alnwick;
   }
   size: 1;
}

control Greendale {
   if ( valid( Slick ) ) {
      apply(RoseBud);
   } else {
      if ( valid( DuPont ) ) {
         apply(Rollins);
      }
   }
}

table Anthon {
   actions {
      ElkNeck;
   }
   size: 1;
}

control Tingley {
   if ( valid( Tahlequah ) ) {
      apply(Anthon);
   }
}



action Skene() {
    modify_field(Penrose.Philbrook, Edesville.Raven);
}

action Kewanee() {
    modify_field(Penrose.Philbrook, Edesville.CeeVee);
}

action Mooreland() {
    modify_field(Penrose.Philbrook, Edesville.Wewela);
}

@pragma action_default_only Tarnov
@pragma immediate 0
table PineCity {
   reads {
      Hookstown.valid : ternary;
      Anoka.valid : ternary;
      Dialville.valid : ternary;
      Sylvester.valid : ternary;
      Maydelle.valid : ternary;
      Santos.valid : ternary;
      Tahlequah.valid : ternary;
      Slick.valid : ternary;
      DuPont.valid : ternary;
      Skillman.valid : ternary;
   }
   actions {
      Skene;
      Kewanee;
      Mooreland;
      Tarnov;
   }
   size: Quinhagak;
}

action Jessie() {
    modify_field(Penrose.Lathrop, Edesville.Wewela);
}

@pragma immediate 0
table Joshua {
   reads {
      Hookstown.valid : ternary;
      Anoka.valid : ternary;
      Santos.valid : ternary;
      Tahlequah.valid : ternary;
   }
   actions {
      Jessie;
      Tarnov;
   }
   size: Toklat;
}

control Ewing {
   apply(Joshua);
   apply(PineCity);
}



counter Trotwood {
   type : packets_and_bytes;
   direct : Shamokin;
   min_width: 16;
}

@pragma action_default_only Tarnov
table Shamokin {
   reads {
      Shine.Sitka : exact;
      Comobabi.Oneonta : ternary;
      Comobabi.Mentone : ternary;
      Nashoba.Ivanhoe : ternary;
      Nashoba.Chualar : ternary;
      Nashoba.Iselin : ternary;
   }

   actions {
      McCune;
      Tarnov;
   }
   size : Malabar;
}

action Indrio() {

   modify_field(Nashoba.Success, 1 );
   modify_field(Quivero.Bevington,
                Konnarock);
}







table Durant {
   reads {
      Nashoba.Crumstown : exact;
      Nashoba.Hatchel : exact;
      Nashoba.Allons : exact;
      Nashoba.Ekron : exact;
   }

   actions {
      Winside;
      Indrio;
   }
   size : Pillager;
   support_timeout : true;
}

action Stoystown() {
   modify_field( Wagener.Glendale, 1 );
}

table Dillsburg {
   reads {
      Nashoba.Kekoskee : ternary;
      Nashoba.Yakima : exact;
      Nashoba.Roodhouse : exact;
   }
   actions {
      Stoystown;
   }
   size: Saticoy;
}

control Manning {
   apply( Shamokin ) {
      Tarnov {



         if (Shine.Baldwin == 0 and Nashoba.McCammon == 0) {
            apply( Durant );
         }
         apply(Dillsburg);
      }
   }
}

field_list Monkstown {
    Quivero.Bevington;
    Nashoba.Crumstown;
    Nashoba.Hatchel;
    Nashoba.Allons;
    Nashoba.Ekron;
}

action Eveleth() {
   generate_digest(Hobson, Monkstown);
}

table Riner {
   actions {
      Eveleth;
   }
   size : 1;
}

control Mabel {
   if (Nashoba.Success == 1) {
      apply( Riner );
   }
}



action EastLake( Quijotoa, Pelican ) {
   modify_field( Braxton.Wanilla, Quijotoa );
   modify_field( Roseau.Firesteel, Pelican );
}

@pragma action_default_only Tarnov
table Madera {
   reads {
      Wagener.Coqui : exact;
      Braxton.Westpoint mask Metzger : lpm;
   }
   actions {
      EastLake;
      Tarnov;
   }
   size : Perrin;
}

@pragma atcam_partition_index Braxton.Wanilla
@pragma atcam_number_partitions Perrin
table Hurdtown {
   reads {
      Braxton.Wanilla : exact;
      Braxton.Westpoint mask Westbury : lpm;
   }

   actions {
      Gobles;
      Kaweah;
      Tarnov;
   }
   default_action : Tarnov();
   size : Millstadt;
}

action Reubens( Hobart, Malesus ) {
   modify_field( Braxton.Ohiowa, Hobart );
   modify_field( Roseau.Firesteel, Malesus );
}

@pragma action_default_only Tarnov
table Edinburgh {


   reads {
      Wagener.Coqui : exact;
      Braxton.Westpoint : lpm;
   }

   actions {
      Reubens;
      Tarnov;
   }

   size : Uniopolis;
}

@pragma atcam_partition_index Braxton.Ohiowa
@pragma atcam_number_partitions Uniopolis
table Braymer {
   reads {
      Braxton.Ohiowa : exact;


      Braxton.Westpoint mask Darden : lpm;
   }
   actions {
      Gobles;
      Kaweah;
      Tarnov;
   }

   default_action : Tarnov();
   size : Mapleview;
}

@pragma action_default_only Tarnov
@pragma idletime_precision 1
table Metter {

   reads {
      Wagener.Coqui : exact;
      Moline.Aurora : lpm;
   }

   actions {
      Gobles;
      Kaweah;
      Tarnov;
   }

   size : Kranzburg;
   support_timeout : true;
}

action Bowen( Monahans, Ramah ) {
   modify_field( Moline.Hallville, Monahans );
   modify_field( Roseau.Firesteel, Ramah );
}

@pragma action_default_only Tarnov
#ifdef PROFILE_DEFAULT
//@pragma stage 2 Godfrey
//@pragma stage 3
#endif
table MillCity {
   reads {
      Wagener.Coqui : exact;
      Moline.Aurora : lpm;
   }

   actions {
      Bowen;
      Tarnov;
   }

   size : Nuangola;
}

@pragma ways Corry
@pragma atcam_partition_index Moline.Hallville
@pragma atcam_number_partitions Nuangola
table Browndell {
   reads {
      Moline.Hallville : exact;
      Moline.Aurora mask Buckfield : lpm;
   }
   actions {
      Gobles;
      Kaweah;
      Tarnov;
   }
   default_action : Tarnov();
   size : Draketown;
}

action Gobles( Putnam ) {
   modify_field( Roseau.Firesteel, Putnam );
}

@pragma idletime_precision 1
table Woodridge {
   reads {
      Wagener.Coqui : exact;
      Moline.Aurora : exact;
   }

   actions {
      Gobles;
      Kaweah;
      Tarnov;
   }
   default_action : Tarnov();
   size : Rowlett;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
//@pragma stage 2 McIntosh
//@pragma stage 3
#endif
table Hiland {
   reads {
      Wagener.Coqui : exact;
      Braxton.Westpoint : exact;
   }

   actions {
      Gobles;
      Kaweah;
      Tarnov;
   }
   default_action : Tarnov();
   size : Milam;
   support_timeout : true;
}

action Canton(Lilydale, Hewins, BirchRun) {
   modify_field(Barksdale.Rotan, BirchRun);
   modify_field(Barksdale.Maywood, Lilydale);
   modify_field(Barksdale.Greenlawn, Hewins);
   modify_field(Barksdale.Hannibal, 1);
}

table Honaker {
   reads {
      Roseau.Firesteel : exact;
   }

   actions {
      Canton;
   }
   size : Cardenas;
}

control Arial {
   if ( Nashoba.BigRock == 0 and Wagener.Glendale == 1 ) {
      if ( ( Wagener.Bayard == 1 ) and ( Nashoba.MuleBarn == 1 ) ) {
         apply( Woodridge ) {
            Tarnov {
               apply( MillCity ) {
                  Bowen {
                     apply( Browndell );
                  }
                  Tarnov {
                     apply( Metter );
                  }
               }
            }
         }
      } else if ( ( Wagener.LasLomas == 1 ) and ( Nashoba.Portales == 1 ) ) {
         apply( Hiland ) {
            Tarnov {
               apply( Edinburgh ) {
                  Reubens {
                     apply( Braymer );
                  }
                  Tarnov {

                     apply( Madera ) {
                        EastLake {
                           apply( Hurdtown );
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Dockton {
   if( Roseau.Firesteel != 0 ) {
      apply( Honaker );
   }
}

action Kaweah( Benkelman ) {
   modify_field( Roseau.Plush, Benkelman );
   modify_field( Wagener.Cresco, 1 );
}

field_list Contact {
   Penrose.Lathrop;
}

field_list_calculation Natalbany {
    input {
        Contact;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Sonoma {
   selection_key : Natalbany;
   selection_mode : resilient;
}

action_profile Tabler {
   actions {
      Gobles;
   }
   size : Burtrum;
   dynamic_action_selection : Sonoma;
}

table Petty {
   reads {
      Roseau.Plush : exact;
   }
   action_profile : Tabler;
   size : PawPaw;
}

control Meridean {
   if ( Roseau.Plush != 0 ) {
      apply( Petty );
   }
}



field_list Hartman {
   Penrose.Philbrook;
}

field_list_calculation Levasy {
    input {
        Hartman;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Ringwood {
    selection_key : Levasy;
    selection_mode : resilient;
}

action Maybell(Wilton) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Wilton);
}

action_profile Brazil {
    actions {
        Maybell;
        Tarnov;
    }
    size : Pekin;
    dynamic_action_selection : Ringwood;
}

table Mekoryuk {
   reads {
      Barksdale.Aspetuck : exact;
   }
   action_profile: Brazil;
   size : Neshoba;
}

control Longwood {
   if ((Barksdale.Aspetuck & 0x2000) == 0x2000) {
      apply(Mekoryuk);
   }
}



meter ElkFalls {
   type : packets;
   static : Amasa;
   instance_count: Quarry;
}

action Olathe(Gould) {
   execute_meter(ElkFalls, Gould, Cabot.Glenoma);
}

table Amasa {
   reads {
      Shine.Sitka : exact;
      Barksdale.Timken : exact;
   }
   actions {
      Olathe;
   }
   size : Doris;
}

counter Cornell {
   type : packets;
   static : Philip;
   instance_count : Barwick;
   min_width: 64;
}

action Tamora(Lenexa) {
   modify_field(Nashoba.BigRock, 1);
   count(Cornell, Lenexa);
}

action Lisman(Belpre) {
   count(Cornell, Belpre);
}

action Coalgate(Senatobia, Tramway) {
   modify_field(ig_intr_md_for_tm.qid, Senatobia);
   count(Cornell, Tramway);
}

action Hartwell(Redmon, Rembrandt, Cooter) {
   modify_field(ig_intr_md_for_tm.qid, Redmon);
   modify_field(ig_intr_md_for_tm.ingress_cos, Rembrandt);
   count(Cornell, Cooter);
}

action Buckholts(Maben) {
   modify_field(ig_intr_md_for_tm.copy_to_cpu, 1);
   count(Cornell, Maben);
}

table Philip {
   reads {
      Shine.Sitka : exact;
      Barksdale.Timken : exact;
      Cabot.Glenoma : exact;
   }

   actions {
      Tamora;
      Coalgate;
      Hartwell;
      Lisman;
      Buckholts;
   }
size : Domingo;
}



action Chenequa() {
   modify_field(Barksdale.Maywood, Nashoba.Yakima);
   modify_field(Barksdale.Greenlawn, Nashoba.Roodhouse);
   modify_field(Barksdale.Thalmann, Nashoba.Crumstown);
   modify_field(Barksdale.Soledad, Nashoba.Hatchel);
   modify_field(Barksdale.Rotan, Nashoba.Allons);
}

table Youngwood {
   actions {
      Chenequa;
   }
   default_action : Chenequa();
   size : 1;
}

control Cowell {
   if (Nashoba.Allons!=0) {
      apply( Youngwood );
   }
}

action Suwanee() {
   modify_field(Barksdale.Devers, 1);
   modify_field(Barksdale.Powelton, 1);
   modify_field(Barksdale.Range, Barksdale.Rotan);
}

action Longport() {
}



@pragma ways 1
table Century {
   reads {
      Barksdale.Maywood : exact;
      Barksdale.Greenlawn : exact;
   }
   actions {
      Suwanee;
      Longport;
   }
   default_action : Longport;
   size : 1;
}

action SanJuan() {
   modify_field(Barksdale.Rockaway, 1);
   modify_field(Barksdale.Palomas, 1);
   add(Barksdale.Range, Barksdale.Rotan, Rains);
}

table Maryhill {
   actions {
      SanJuan;
   }
   default_action : SanJuan;
   size : 1;
}

action Hulbert() {
   modify_field(Barksdale.Winger, 1);
   modify_field(Barksdale.Range, Barksdale.Rotan);
}

table Almeria {
   actions {
      Hulbert;
   }
   default_action : Hulbert();
   size : 1;
}

action Stonefort(Chloride) {
   modify_field(Barksdale.Mullins, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Chloride);
   modify_field(Barksdale.Aspetuck, Chloride);
}

action RossFork(Pilger) {
   modify_field(Barksdale.Rockaway, 1);
   modify_field(Barksdale.Range, Pilger);
}

action PineLawn() {
}

table Ripon {
   reads {
      Barksdale.Maywood : exact;
      Barksdale.Greenlawn : exact;
      Barksdale.Rotan : exact;
   }

   actions {
      Stonefort;
      RossFork;
      PineLawn;
   }
   default_action : PineLawn();
   size : Gorman;
}

control Wellford {
   if (Nashoba.BigRock == 0) {
      apply(Ripon) {
         PineLawn {
            apply(Century) {
               Longport {
                  if ((Barksdale.Maywood & 0x010000) == 0x010000) {
                     apply(Maryhill);
                  } else {
                     apply(Almeria);
                  }
               }
            }
         }
      }
   }
}

action Gonzales() {
   modify_field(Nashoba.Silesia, 1);
   modify_field(Nashoba.BigRock, 1);
}

table Plata {
   actions {
      Gonzales;
   }
   default_action : Gonzales;
   size : 1;
}

control Purley {
   if (Nashoba.BigRock == 0) {
      if ((Barksdale.Hannibal==0) and (Nashoba.Ekron==Barksdale.Aspetuck)) {
         apply(Plata);
      } else {
         apply(Amasa);
         apply(Philip);
      }
   }
}



action Eclectic( Kaplan ) {
   modify_field( Barksdale.Honalo, Kaplan );
}

action Yerington() {
   modify_field( Barksdale.Honalo, Barksdale.Rotan );
}

table Towaoc {
   reads {
      eg_intr_md.egress_port : exact;
      Barksdale.Rotan : exact;
   }

   actions {
      Eclectic;
      Yerington;
   }
   default_action : Yerington;
   size : Furman;
}

control Averill {
   apply( Towaoc );
}



action Shickley( Hahira, Escondido ) {
   modify_field( Barksdale.Ebenezer, Hahira );
   modify_field( Barksdale.Lemoyne, Escondido );
}


table Magnolia {
   reads {
      Barksdale.Astatula : exact;
   }

   actions {
      Shickley;
   }
   size : BallClub;
}

action Ferrum() {
   no_op();
}

action ElMirage() {
   modify_field( Skillman.Topanga, Ahmeek[0].Wrens );
   remove_header( Ahmeek[0] );
}

table Tolleson {
   actions {
      ElMirage;
   }
   default_action : ElMirage;
   size : Wolsey;
}

action Renick() {
   no_op();
}

action Coyote() {
   add_header( Ahmeek[ 0 ] );
   modify_field( Ahmeek[0].Pinta, Barksdale.Honalo );
   modify_field( Ahmeek[0].Wrens, Skillman.Topanga );
   modify_field( Skillman.Topanga, Rockleigh );
}



table LakePine {
   reads {
      Barksdale.Honalo : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Renick;
      Coyote;
   }
   default_action : Coyote;
   size : Scottdale;
}

action Reading() {
   modify_field(Skillman.Waldo, Barksdale.Maywood);
   modify_field(Skillman.Halbur, Barksdale.Greenlawn);
   modify_field(Skillman.Barclay, Barksdale.Ebenezer);
   modify_field(Skillman.Bootjack, Barksdale.Lemoyne);
}

action Junior() {
   Reading();
   add_to_field(Slick.PellLake, -1);
}

action Quinwood() {
   Reading();
   add_to_field(DuPont.Darco, -1);
}

table Markville {
   reads {
      Barksdale.Auvergne : exact;
      Barksdale.Astatula : exact;
      Barksdale.Hannibal : exact;
      Slick.valid : ternary;
      DuPont.valid : ternary;
   }

   actions {
      Junior;
      Quinwood;
   }
   size : Paoli;
}

control Hibernia {
   apply( Tolleson );
}

control Elvaston {
   apply( LakePine );
}

control SneeOosh {
   apply( Magnolia );
   apply( Markville );
}



field_list Charm {
    Quivero.Bevington;
    Nashoba.Allons;
    Maydelle.Barclay;
    Maydelle.Bootjack;
    Slick.Corfu;
}

action Correo() {
   generate_digest(Hobson, Charm);
}

table Corum {
   actions {
      Correo;
   }

   default_action : Correo;
   size : 1;
}

control Nahunta {
   if (Nashoba.McCammon == 1) {
      apply(Corum);
   }
}



action Ocheyedan() {
   modify_field( Nashoba.Halfa, Shine.Layton );
}

action Antlers() {
   modify_field( Nashoba.Vallejo, Shine.Garwood );
}

action Harbor() {
   modify_field( Nashoba.Vallejo, Moline.Stennett );
}

action Alakanuk() {
   modify_field( Nashoba.Vallejo, Braxton.Wyndmere );
}

action Davant( Bangor, Eldena ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Bangor );
   modify_field( ig_intr_md_for_tm.qid, Eldena );
}

table FlatRock {
   reads {
     Nashoba.Noelke : exact;
   }

   actions {
     Ocheyedan;
   }

   size : Randall;
}

table Volcano {
   reads {
     Nashoba.MuleBarn : exact;
     Nashoba.Portales : exact;
   }

   actions {
     Antlers;
     Harbor;
     Alakanuk;
   }

   size : Oskaloosa;
}

//@pragma stage 10
table Hester {
   reads {
      Shine.Emsworth : exact;
      Shine.Layton : ternary;
      Nashoba.Halfa : ternary;
      Nashoba.Vallejo : ternary;
   }

   actions {
      Davant;
   }

   size : Oklee;
}

control Wimberley {
   apply( FlatRock );
   apply( Volcano );
}

control DelMar {
   apply( Hester );
}

control ingress {

   Chemult();
   Sutton();
   Pinole();
   Chamois();
   Brothers();


   Wimberley();
   Manning();

   Greendale();
   Tingley();


   Arial();
   Ewing();
   Meridean();

   Cowell();

   Dockton();





   Wellford();
   DelMar();


   Purley();
   Longwood();
   Nahunta();
   Mabel();


   if( valid( Ahmeek[0] ) ) {
      Hibernia();
   }






}

control egress {
   Averill();
   SneeOosh();
   Elvaston();
}

