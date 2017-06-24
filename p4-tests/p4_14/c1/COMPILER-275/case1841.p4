// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 172105







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
#else





header_type Covina {
	fields {
		LaHabra : 3;
	}
}
metadata Covina Hesler;

header_type Heaton {
	fields {
		Armona : 1;
		Catskill : 9;
		Tiverton : 48;
		Mayflower : 32;
	}
}
metadata Heaton Reynolds;

header_type Indios {
	fields {
		Gunter : 9;
		Levittown : 3;
		Curlew : 16;
		LaCueva : 16;
		Coachella : 13;
		Potter : 13;
		Canjilon : 16;
		Jenners : 9;
		Daysville : 16;
		Hulbert : 1;
		Louin : 3;
		LasLomas : 5;
		BigWells : 2;
	}
}

metadata Indios Wartburg;

header_type Lofgreen {
	fields {
		Moquah : 9;
		Allyn : 19;
		Millston : 2;
		Chatanika : 32;
		Lefor : 19;
		Loysburg : 2;
		Menfro : 8;
		Aguilar : 32;
		Nixon : 16;
		Chualar : 1;
		Elburn : 5;
		Yardley : 3;
		Shuqualak : 1;
	}
}

metadata Lofgreen Wesson;




action Cornwall(Silva) {
    modify_field(Seagrove, Silva);
}

#ifdef BMV2
#define Newport     Napanoch
#else
#define Newport         Rozet
#endif

header_type Montezuma {
	fields {
		Elihu : 8;
		Natalia : 48;
	}
}
metadata Montezuma Antimony;

#define McCloud 0
#define Devore 1
#define Goulding 2
#define Hiland 3
#define Parkville 4
#define Exell 5
#define Pearce 6


#define Woodbury \
    ((Fallsburg != McCloud) and \
     (Fallsburg != Exell))
#define Endeavor \
    ((Fallsburg == McCloud) or \
     (Fallsburg == Exell))
#define Crossett \
    (Fallsburg == Devore)
#define Ferrum \
    (Fallsburg == Goulding)
#endif



#ifndef Saltdale
#define Saltdale

header_type Yorklyn {
	fields {
		Anoka : 16;
		Venturia : 16;
		Windham : 8;
		Oakton : 8;
		Merino : 8;
		Inverness : 8;
		Bonner : 1;
		Kanab : 1;
		Pavillion : 1;
		Lakebay : 1;
	}
}

header_type Holcut {
	fields {
		Marshall : 24;
		Raritan : 24;
		Paoli : 24;
		Rodessa : 24;
		Dauphin : 16;
		Leland : 16;
		Malabar : 16;
		Creekside : 16;
		RockHall : 16;
		AvonLake : 8;
		Kenbridge : 8;
		Madeira : 1;
		Raeford : 1;
		Caballo : 12;
		Tehachapi : 2;
		Energy : 1;
		Whiteclay : 1;
		Onawa : 1;
		Maiden : 1;
		Flats : 1;
		Shanghai : 1;
		Laplace : 1;
		UnionGap : 1;
		Caguas : 1;
		Fowlkes : 1;
		Thomas : 1;
	}
}

header_type Otranto {
	fields {
		Sonora : 24;
		Willows : 24;
		Stehekin : 24;
		Hodges : 24;
		Veteran : 24;
		McKibben : 24;
		Rockdale : 16;
		Slana : 16;
		Norborne : 16;
		Sarepta : 12;
		Elsmere : 3;
		Cuprum : 3;
		Weleetka : 1;
		Provo : 1;
		Lebanon : 1;
		Osyka : 1;
		Bigfork : 1;
		Dorset : 1;
		Hibernia : 1;
		Amesville : 1;
		Ozona : 8;
	}
}


header_type Harrison {
	fields {
		Roodhouse : 8;
		Panaca : 1;
		Botna : 1;
		Pevely : 1;
		Anthon : 1;
		Hildale : 1;
	}
}

header_type Gilmanton {
	fields {
		Tamaqua : 32;
		Colonie : 32;
		Colonias : 6;
		WestGate : 16;
	}
}

header_type Holcomb {
	fields {
		Leetsdale : 128;
		Coulter : 128;
		Helen : 20;
		Lovelady : 8;
		Redmon : 11;
		Edroy : 8;
		Cotter : 13;
	}
}

header_type Newfane {
	fields {
		Champlain : 14;
		Bunker : 1;
		Morstein : 1;
		Joaquin : 12;
		LaSal : 1;
		Nettleton : 6;
	}
}

header_type Adona {
	fields {
		Anvik : 1;
		Taylors : 1;
	}
}

header_type Camino {
	fields {
		Truro : 8;
	}
}

header_type Everetts {
	fields {
		Komatke : 16;
	}
}

header_type Boxelder {
	fields {
		Boquet : 32;
		Lyman : 32;
		LaMonte : 32;
	}
}

header_type Trevorton {
	fields {
		WestEnd : 32;
		Panacea : 32;
	}
}

#endif



#ifndef Tulsa
#define Tulsa



header_type Haverford {
	fields {
		Ashville : 24;
		Arminto : 24;
		Hobart : 24;
		Ackley : 24;
		Carpenter : 16;
	}
}



header_type RockHill {
	fields {
		MintHill : 3;
		Kamas : 1;
		ElPortal : 12;
		Quogue : 16;
	}
}



header_type Stamford {
	fields {
		Lafayette : 4;
		Powelton : 4;
		Stanwood : 6;
		Snowball : 2;
		Burnett : 16;
		Aniak : 16;
		Lambert : 3;
		Chemult : 13;
		Rockfield : 8;
		Kenvil : 8;
		McMurray : 16;
		Wyanet : 32;
		Storden : 32;
	}
}

header_type Battles {
	fields {
		Raynham : 4;
		Sheldahl : 8;
		Rushmore : 20;
		Tyrone : 16;
		Dalkeith : 8;
		Broadmoor : 8;
		Philippi : 128;
		HornLake : 128;
	}
}




header_type Colfax {
	fields {
		Strasburg : 8;
		Auberry : 8;
		Offerle : 16;
	}
}

header_type Valencia {
	fields {
		Ganado : 16;
		Lehigh : 16;
		Placida : 32;
		Albemarle : 32;
		Amory : 4;
		Crossnore : 4;
		Elkland : 8;
		Jenkins : 16;
		Powers : 16;
		Somis : 16;
	}
}

header_type Mendota {
	fields {
		ElMirage : 16;
		Romney : 16;
		Parmerton : 16;
		Bagwell : 16;
	}
}



header_type Topsfield {
	fields {
		Disney : 16;
		Harney : 16;
		Nephi : 8;
		Niota : 8;
		Mishawaka : 16;
	}
}

header_type Dixon {
	fields {
		Traverse : 48;
		Brockton : 32;
		Quinnesec : 48;
		Stone : 32;
	}
}



header_type Rankin {
	fields {
		Greenwood : 1;
		TinCity : 1;
		Ardara : 1;
		Parthenon : 1;
		Millstone : 1;
		Owentown : 3;
		BigPoint : 5;
		Lansing : 3;
		Gower : 16;
	}
}

header_type Halley {
	fields {
		RowanBay : 24;
		Clementon : 8;
	}
}



header_type Strevell {
	fields {
		TenSleep : 8;
		Lakin : 24;
		Berkley : 24;
		Brothers : 8;
	}
}

#endif



#ifndef Butler
#define Butler

parser start {
   return Orlinda;
}

#define Putnam        0x8100
#define Amazonia        0x0800
#define HighRock        0x86dd
#define Rains        0x9100
#define Odell        0x8847
#define Talco         0x0806
#define Idylside        0x8035
#define Bavaria        0x88cc
#define Soldotna        0x8809

#define Gratiot              1
#define Edler              2
#define Nerstrand              4
#define Redfield               6
#define Accord               17
#define Kapalua                47

#define Malinta         0x501
#define Harleton          0x506
#define Clinchco          0x511
#define Claunch          0x52F


#define McDonough                 4789



#define Tomato               0
#define Contact              1
#define Eastman                2



#define Bronwood          0
#define Brave          4095
#define Creston  4096
#define Montross  8191



#define Dunmore                      0
#define Houston                  0
#define Goldman                 1

header Haverford ElmGrove;
header Haverford Perrin;
header RockHill Oklee[ 2 ];
header Stamford Arapahoe;
header Stamford Oshoto;
header Battles MuleBarn;
header Battles Sargent;
header Valencia Coronado;
header Mendota Segundo;
header Valencia Weinert;
header Mendota Jenera;
header Strevell Kaluaaha;
header Topsfield Mausdale;
header Rankin Spanaway;

parser Orlinda {
   extract( ElmGrove );
   return select( ElmGrove.Carpenter ) {
      Putnam : Palmdale;
      Amazonia : Taconite;
      HighRock : Wenham;
      Talco  : Alston;
      default        : ingress;
   }
}

parser Palmdale {
   extract( Oklee[0] );
   return select( Oklee[0].Quogue ) {
      Amazonia : Taconite;
      HighRock : Wenham;
      Talco  : Alston;
      default : ingress;
   }
}

parser Taconite {
   extract( Arapahoe );
   set_metadata(Gaston.Windham, Arapahoe.Kenvil);
   set_metadata(Gaston.Merino, Arapahoe.Rockfield);
   set_metadata(Gaston.Anoka, Arapahoe.Burnett);
   set_metadata(Gaston.Pavillion, 0);
   set_metadata(Gaston.Bonner, 1);
   return select(Arapahoe.Chemult, Arapahoe.Powelton, Arapahoe.Kenvil) {
      Clinchco : Ekwok;
      default : ingress;
   }
}

parser Wenham {
   extract( Sargent );
   set_metadata(Gaston.Windham, Sargent.Dalkeith);
   set_metadata(Gaston.Merino, Sargent.Broadmoor);
   set_metadata(Gaston.Anoka, Sargent.Tyrone);
   set_metadata(Gaston.Pavillion, 1);
   set_metadata(Gaston.Bonner, 0);
   return ingress;
}

parser Alston {
   extract( Mausdale );
   return ingress;
}

parser Ekwok {
   extract(Segundo);
   return select(Segundo.Romney) {
      McDonough : Circle;
      default : ingress;
    }
}

parser ElJebel {
   set_metadata(Wayne.Tehachapi, Eastman);
   return Freeburg;
}

parser Heppner {
   set_metadata(Wayne.Tehachapi, Eastman);
   return Bolckow;
}

parser Delmar {
   extract(Spanaway);
   return select(Spanaway.Greenwood, Spanaway.TinCity, Spanaway.Ardara, Spanaway.Parthenon, Spanaway.Millstone,
             Spanaway.Owentown, Spanaway.BigPoint, Spanaway.Lansing, Spanaway.Gower) {
      Amazonia : ElJebel;
      HighRock : Heppner;
      default : ingress;
   }
}

parser Circle {
   extract(Kaluaaha);
   set_metadata(Wayne.Tehachapi, Contact);
   return Domingo;
}

parser Freeburg {
   extract( Oshoto );
   set_metadata(Gaston.Oakton, Oshoto.Kenvil);
   set_metadata(Gaston.Inverness, Oshoto.Rockfield);
   set_metadata(Gaston.Venturia, Oshoto.Burnett);
   set_metadata(Gaston.Lakebay, 0);
   set_metadata(Gaston.Kanab, 1);
   return ingress;
}

parser Bolckow {
   extract( MuleBarn );
   set_metadata(Gaston.Oakton, MuleBarn.Dalkeith);
   set_metadata(Gaston.Inverness, MuleBarn.Broadmoor);
   set_metadata(Gaston.Venturia, MuleBarn.Tyrone);
   set_metadata(Gaston.Lakebay, 1);
   set_metadata(Gaston.Kanab, 0);
   return ingress;
}

parser Domingo {
   extract( Perrin );
   return select( Perrin.Carpenter ) {
      Amazonia: Freeburg;
      HighRock: Bolckow;
      default: ingress;
   }
}
#endif

metadata Holcut Wayne;
metadata Otranto Brazil;
metadata Newfane Harpster;
metadata Yorklyn Gaston;
metadata Gilmanton Kahului;
metadata Holcomb Cadwell;
metadata Adona Noelke;
metadata Harrison Pimento;
metadata Camino Beaverdam;
metadata Everetts LoneJack;
metadata Trevorton Orrum;
metadata Boxelder Rosburg;






@pragma pa_solitary ingress Wayne.Leland
@pragma pa_solitary ingress Wayne.Malabar
@pragma pa_solitary ingress Wayne.Creekside
@pragma pa_solitary egress Brazil.Norborne
@pragma pa_solitary ig_intr_md_for_tm.ucast_egress_port

@pragma pa_atomic ingress Orrum.WestEnd
@pragma pa_solitary ingress Orrum.WestEnd
@pragma pa_atomic ingress Orrum.Panacea
@pragma pa_solitary ingress Orrum.Panacea













#undef Waitsburg

#undef Fenwick
#undef Edinburg
#undef Gakona
#undef Antlers
#undef Jarrell

#undef Bufalo
#undef Bridger
#undef Knolls

#undef Nondalton
#undef Laney
#undef Emory
#undef LaConner
#undef Moorpark
#undef August
#undef Charlotte
#undef Havana
#undef Halsey
#undef Sespe
#undef Christina
#undef Zarah
#undef Blackwood
#undef SanSimon
#undef HighHill
#undef Flippen
#undef Buckfield
#undef Hartwell

#undef DosPalos
#undef Hearne
#undef Estero
#undef RedHead
#undef Medulla
#undef Newcomb
#undef Pfeifer
#undef Maddock
#undef Whitefish
#undef Brinkley
#undef Hurst
#undef McFaddin

#undef Burtrum

#undef Lamison







#define Waitsburg 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Fenwick      65536
#define Edinburg      65536
#define Gakona 512
#define Antlers 512
#define Jarrell      512


#define Bufalo     1024
#define Bridger    1024
#define Knolls     256


#define Nondalton 512
#define Laney 65536
#define Emory 65536
#define LaConner   16384
#define Moorpark         131072
#define August 65536
#define Charlotte 1024
#define Havana 2048
#define Halsey 16384
#define Sespe 8192
#define Christina 65536
#define Zarah 8192
#define Blackwood 2048
#define SanSimon 16384

#define HighHill 0x0000000000000000FFFFFFFFFFFFFFFF


#define Flippen 0x000fffff

#define Buckfield 0xFFFFFFFFFFFFFFFF0000000000000000

#define Hartwell 0x000007FFFFFFFFFF0000000000000000


#define DosPalos 1024
#define Hearne 4096
#define Estero 4096
#define RedHead 4096
#define Medulla 4096
#define Newcomb 1024
#define Pfeifer 4096
#define Whitefish 64
#define Brinkley 1
#define Hurst  8
#define McFaddin 512


#define Burtrum 0


#define Lamison    4096

#endif



#ifndef Shipman
#define Shipman

action Isleta() {
   no_op();
}

#endif

















action Willamina(PaloAlto, Enderlin, Ozark, Nanakuli, Minneiska, Masardis) {
    modify_field(Harpster.Champlain, PaloAlto);
    modify_field(Harpster.Bunker, Enderlin);
    modify_field(Harpster.Joaquin, Ozark);
    modify_field(Harpster.Morstein, Nanakuli);
    modify_field(Harpster.LaSal, Minneiska);
    modify_field(Harpster.Nettleton, Masardis);
}

@pragma command_line --no-dead-code-elimination
table Wapinitia {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Willamina;
    }
    size : Waitsburg;
}

control Elvaston {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Wapinitia);
    }
}





action Bayville(Davie) {
   modify_field( Brazil.Weleetka, 1 );
   modify_field( Brazil.Ozona, Davie);
   modify_field( Wayne.Caguas, 1 );
}

action Tingley() {
   modify_field( Wayne.Laplace, 1 );
   modify_field( Wayne.Thomas, 1 );
}

action Wellsboro() {
   modify_field( Wayne.Caguas, 1 );
}

action Yemassee() {
   modify_field( Wayne.Fowlkes, 1 );
}

action Fragaria() {
   modify_field( Wayne.Thomas, 1 );
}


table Provencal {
   reads {
      ElmGrove.Ashville : ternary;
      ElmGrove.Arminto : ternary;
   }

   actions {
      Bayville;
      Tingley;
      Wellsboro;
      Yemassee;
      Fragaria;
   }
   default_action : Fragaria;
   size : Gakona;
}

action Lovewell() {
   modify_field( Wayne.UnionGap, 1 );
}


table Castle {
   reads {
      ElmGrove.Hobart : ternary;
      ElmGrove.Ackley : ternary;
   }

   actions {
      Lovewell;
   }
   size : Antlers;
}


control Westpoint {
   apply( Provencal );
   apply( Castle );
}




action Maywood() {
   modify_field( Kahului.Tamaqua, Oshoto.Wyanet );
   modify_field( Kahului.Colonie, Oshoto.Storden );
   modify_field( Kahului.Colonias, Oshoto.Stanwood );
   modify_field( Cadwell.Leetsdale, MuleBarn.Philippi );
   modify_field( Cadwell.Coulter, MuleBarn.HornLake );
   modify_field( Cadwell.Helen, MuleBarn.Rushmore );


   modify_field( Wayne.Marshall, Perrin.Ashville );
   modify_field( Wayne.Raritan, Perrin.Arminto );
   modify_field( Wayne.Paoli, Perrin.Hobart );
   modify_field( Wayne.Rodessa, Perrin.Ackley );
   modify_field( Wayne.Dauphin, Perrin.Carpenter );
   modify_field( Wayne.RockHall, Gaston.Venturia );
   modify_field( Wayne.AvonLake, Gaston.Oakton );
   modify_field( Wayne.Kenbridge, Gaston.Inverness );
   modify_field( Wayne.Raeford, Gaston.Kanab );
   modify_field( Wayne.Madeira, Gaston.Lakebay );
}

action LakePine() {
   modify_field( Wayne.Tehachapi, Tomato );
   modify_field( Kahului.Tamaqua, Arapahoe.Wyanet );
   modify_field( Kahului.Colonie, Arapahoe.Storden );
   modify_field( Kahului.Colonias, Arapahoe.Stanwood );
   modify_field( Cadwell.Leetsdale, Sargent.Philippi );
   modify_field( Cadwell.Coulter, Sargent.HornLake );
   modify_field( Cadwell.Helen, Sargent.Rushmore );


   modify_field( Wayne.Marshall, ElmGrove.Ashville );
   modify_field( Wayne.Raritan, ElmGrove.Arminto );
   modify_field( Wayne.Paoli, ElmGrove.Hobart );
   modify_field( Wayne.Rodessa, ElmGrove.Ackley );
   modify_field( Wayne.Dauphin, ElmGrove.Carpenter );
   modify_field( Wayne.RockHall, Gaston.Anoka );
   modify_field( Wayne.AvonLake, Gaston.Windham );
   modify_field( Wayne.Kenbridge, Gaston.Merino );
   modify_field( Wayne.Raeford, Gaston.Bonner );
   modify_field( Wayne.Madeira, Gaston.Pavillion );
}

table Sixteen {
   reads {
      ElmGrove.Ashville : exact;
      ElmGrove.Arminto : exact;
      Arapahoe.Storden : exact;
      Wayne.Tehachapi : exact;
   }

   actions {
      Maywood;
      LakePine;
   }

   default_action : LakePine();
   size : DosPalos;
}


action Hopkins() {
   modify_field( Wayne.Leland, Harpster.Joaquin );
   modify_field( Wayne.Malabar, Harpster.Champlain);
}

action Gobles( Croghan ) {
   modify_field( Wayne.Leland, Croghan );
   modify_field( Wayne.Malabar, Harpster.Champlain);
}

action Windber() {
   modify_field( Wayne.Leland, Oklee[0].ElPortal );
   modify_field( Wayne.Malabar, Harpster.Champlain);
}

table Elrosa {
   reads {
      Harpster.Champlain : ternary;
      Oklee[0] : valid;
      Oklee[0].ElPortal : ternary;
   }

   actions {
      Hopkins;
      Gobles;
      Windber;
   }
   size : RedHead;
}

action Whigham( Blueberry ) {
   modify_field( Wayne.Malabar, Blueberry );
}

action Littleton() {

   modify_field( Wayne.Onawa, 1 );
   modify_field( Beaverdam.Truro,
                 Goldman );
}

table RioHondo {
   reads {
      Arapahoe.Wyanet : exact;
   }

   actions {
      Whigham;
      Littleton;
   }
   default_action : Littleton;
   size : Estero;
}

action Kempner( Austell, Bammel, RushHill, CapeFair, Nunda,
                        Baraboo, McAdams ) {
   modify_field( Wayne.Leland, Austell );
   modify_field( Wayne.Shanghai, McAdams );
   Dandridge(Bammel, RushHill, CapeFair, Nunda,
                        Baraboo );
}

action Duffield() {
   modify_field( Wayne.Flats, 1 );
}

table Fittstown {
   reads {
      Kaluaaha.Berkley : exact;
   }

   actions {
      Kempner;
      Duffield;
   }
   size : Hearne;
}

action Dandridge(Bammel, RushHill, CapeFair, Nunda,
                        Baraboo ) {
   modify_field( Pimento.Roodhouse, Bammel );
   modify_field( Pimento.Panaca, RushHill );
   modify_field( Pimento.Pevely, CapeFair );
   modify_field( Pimento.Botna, Nunda );
   modify_field( Pimento.Anthon, Baraboo );
}

action McKenna(Bammel, RushHill, CapeFair, Nunda,
                        Baraboo ) {
   modify_field( Wayne.Creekside, Harpster.Joaquin );
   modify_field( Wayne.Shanghai, 1 );
   Dandridge(Bammel, RushHill, CapeFair, Nunda,
                        Baraboo );
}

action Dialville(Mabel, Bammel, RushHill, CapeFair,
                        Nunda, Baraboo ) {
   modify_field( Wayne.Creekside, Mabel );
   modify_field( Wayne.Shanghai, 1 );
   Dandridge(Bammel, RushHill, CapeFair, Nunda,
                        Baraboo );
}

action Tappan(Bammel, RushHill, CapeFair, Nunda,
                        Baraboo ) {
   modify_field( Wayne.Creekside, Oklee[0].ElPortal );
   modify_field( Wayne.Shanghai, 1 );
   Dandridge(Bammel, RushHill, CapeFair, Nunda,
                        Baraboo );
}

table Mapleview {
   reads {
      Harpster.Joaquin : exact;
   }

   actions {
      McKenna;
   }

   size : Medulla;
}

table Renick {
   reads {
      Harpster.Champlain : exact;
      Oklee[0].ElPortal : exact;
   }

   actions {
      Dialville;
      Isleta;
   }
   default_action : Isleta;

   size : Newcomb;
}

table Pecos {
   reads {
      Oklee[0].ElPortal : exact;
   }

   actions {
      Tappan;
   }

   size : Pfeifer;
}

control Othello {
   apply( Sixteen ) {
         Maywood {
            apply( RioHondo );
            apply( Fittstown );
         }
         LakePine {
            if ( Harpster.Morstein == 1 ) {
               apply( Elrosa );
            }
            if ( valid( Oklee[ 0 ] ) ) {

               apply( Renick ) {
                  Isleta {

                     apply( Pecos );
                  }
               }
            } else {

               apply( Mapleview );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Steger {
    width  : 1;
    static : Russia;
    instance_count : 262144;
}

register Robinette {
    width  : 1;
    static : Hyrum;
    instance_count : 262144;
}

blackbox stateful_alu Sitka {
    reg : Steger;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Noelke.Anvik;
}

blackbox stateful_alu Donegal {
    reg : Robinette;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Noelke.Taylors;
}

field_list Lapeer {
    Harpster.Nettleton;
    Oklee[0].ElPortal;
}

field_list_calculation Chamois {
    input { Lapeer; }
    algorithm: identity;
    output_width: 18;
}

action Colona() {
    Sitka.execute_stateful_alu_from_hash(Chamois);
}

action Rawlins() {
    Donegal.execute_stateful_alu_from_hash(Chamois);
}

table Russia {
    actions {
      Colona;
    }
    default_action : Colona;
    size : 1;
}

table Hyrum {
    actions {
      Rawlins;
    }
    default_action : Rawlins;
    size : 1;
}
#endif

action Blanding(Convoy) {
    modify_field(Noelke.Taylors, Convoy);
}

@pragma  use_hash_action 0
table Affton {
    reads {
       Harpster.Nettleton : exact;
    }
    actions {
      Blanding;
    }
    size : 64;
}

action Pumphrey() {
   modify_field( Wayne.Caballo, Harpster.Joaquin );
   modify_field( Wayne.Energy, 0 );
}

table Goldsboro {
   actions {
      Pumphrey;
   }
   size : 1;
}

action Lacombe() {
   modify_field( Wayne.Caballo, Oklee[0].ElPortal );
   modify_field( Wayne.Energy, 1 );
}

table Donna {
   actions {
      Lacombe;
   }
   size : 1;
}

control Homeacre {
   if ( valid( Oklee[ 0 ] ) ) {
      apply( Donna );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Harpster.LaSal == 1 ) {
         apply( Russia );
         apply( Hyrum );
      }
#endif
   } else {
      apply( Goldsboro );
      if( Harpster.LaSal == 1 ) {
         apply( Affton );
      }
   }
}




field_list Farragut {
   ElmGrove.Ashville;
   ElmGrove.Arminto;
   ElmGrove.Hobart;
   ElmGrove.Ackley;
   ElmGrove.Carpenter;
}

field_list DelRey {

   Arapahoe.Kenvil;
   Arapahoe.Wyanet;
   Arapahoe.Storden;
}

field_list Hallowell {
   Sargent.Philippi;
   Sargent.HornLake;
   Sargent.Rushmore;
   Sargent.Dalkeith;
}

field_list Brule {
   Arapahoe.Kenvil;
   Arapahoe.Wyanet;
   Arapahoe.Storden;
   Segundo.ElMirage;
   Segundo.Romney;
}





field_list_calculation Langlois {
    input {
        Farragut;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Waukesha {
    input {
        DelRey;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation LaFayette {
    input {
        Hallowell;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Gypsum {
    input {
        Brule;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Occoquan() {
    modify_field_with_hash_based_offset(Rosburg.Boquet, 0,
                                        Langlois, 4294967296);
}

action Raceland() {
    modify_field_with_hash_based_offset(Rosburg.Lyman, 0,
                                        Waukesha, 4294967296);
}

action Cache() {
    modify_field_with_hash_based_offset(Rosburg.Lyman, 0,
                                        LaFayette, 4294967296);
}

action Wiota() {
    modify_field_with_hash_based_offset(Rosburg.LaMonte, 0,
                                        Gypsum, 4294967296);
}

table Montour {
   actions {
      Occoquan;
   }
   size: 1;
}

control Layton {
   apply(Montour);
}

table Sandoval {
   actions {
      Raceland;
   }
   size: 1;
}

table Duchesne {
   actions {
      Cache;
   }
   size: 1;
}

control Alzada {
   if ( valid( Arapahoe ) ) {
      apply(Sandoval);
   } else {
      if ( valid( Sargent ) ) {
         apply(Duchesne);
      }
   }
}

table Casper {
   actions {
      Wiota;
   }
   size: 1;
}

control Kansas {
   if ( valid( Segundo ) ) {
      apply(Casper);
   }
}



action Knippa() {
    modify_field(Orrum.WestEnd, Rosburg.Boquet);
}

action Hollymead() {
    modify_field(Orrum.WestEnd, Rosburg.Lyman);
}

action Woodland() {
    modify_field(Orrum.WestEnd, Rosburg.LaMonte);
}

@pragma immediate 0
table Kooskia {
   reads {
      Weinert.valid : ternary;
      Jenera.valid : ternary;
      Oshoto.valid : ternary;
      MuleBarn.valid : ternary;
      Perrin.valid : ternary;
      Coronado.valid : ternary;
      Segundo.valid : ternary;
      Arapahoe.valid : ternary;
      Sargent.valid : ternary;
      ElmGrove.valid : ternary;
   }
   actions {
      Knippa;
      Hollymead;
      Woodland;
      Isleta;
   }
   default_action : Isleta();
   size: Knolls;
}

control LaMoille {
   apply(Kooskia);
}





counter Marquand {
   type : packets_and_bytes;
   direct : Yreka;
   min_width: 16;
}

action Reedsport() {
   modify_field(Wayne.Maiden, 1 );
}

table Yreka {
   reads {
      Harpster.Nettleton : exact;
      Noelke.Taylors : ternary;
      Noelke.Anvik : ternary;
      Wayne.Flats : ternary;
      Wayne.UnionGap : ternary;
      Wayne.Laplace : ternary;
   }

   actions {
      Reedsport;
      Isleta;
   }
   default_action : Isleta;
   size : Jarrell;
}

register Grants {
   width: 1;
   static: Boistfort;
   instance_count: Edinburg;
}

#ifdef __TARGET_TOFINO__
blackbox stateful_alu Chaumont{
    reg: Grants;
    update_lo_1_value: set_bit;
}
#endif

action Lemhi(Quarry) {
#if defined(BMV2) || defined(BMV2TOFINO)
   register_write(Grants, Quarry, 1);
#else
   Chaumont.execute_stateful_alu();
#endif

}

action Mulhall() {

   modify_field(Wayne.Whiteclay, 1 );
   modify_field(Beaverdam.Truro,
                Houston);
}

table Boistfort {
   reads {
      Wayne.Paoli : exact;
      Wayne.Rodessa : exact;
      Wayne.Leland : exact;
      Wayne.Malabar : exact;
   }

   actions {
      Lemhi;
      Mulhall;
   }
   size : Edinburg;
}

action Arvonia() {
   modify_field( Pimento.Hildale, 1 );
}

table Sopris {
   reads {
      Wayne.Creekside : ternary;
      Wayne.Marshall : exact;
      Wayne.Raritan : exact;
   }
   actions {
      Arvonia;
   }
   size: Nondalton;
}

control McAdoo {
   if( Wayne.Maiden == 0 ) {
      apply( Sopris );
   }
}

control Puyallup {
   apply( Yreka ) {
      Isleta {



         if (Harpster.Bunker == 0 and Wayne.Onawa == 0) {
            apply( Boistfort );
         }
         apply(Sopris);
      }
   }
}

field_list Connell {
    Beaverdam.Truro;
    Wayne.Paoli;
    Wayne.Rodessa;
    Wayne.Leland;
    Wayne.Malabar;
}

action McHenry() {
   generate_digest(Dunmore, Connell);
}

table Macopin {
   actions {
      McHenry;
   }
   size : 1;
}

control WallLake {
   if (Wayne.Whiteclay == 1) {
      apply( Macopin );
   }
}



table Virginia {


   reads {
      Kahului.WestGate : exact;
   }
   actions {
      Eclectic;
   }
   size : SanSimon;
}

table Jonesport {


   reads {
      Cadwell.Redmon : exact;
   }
   actions {
      Eclectic;
   }
   size : Blackwood;
}

table Paulding {



   reads {
      Cadwell.Cotter : exact;
   }
   actions {
      Eclectic;
   }
   size : Zarah;
}

action Gosnell( Donnelly ) {
   modify_field( Cadwell.Cotter, Donnelly );
}

table Garibaldi {
   reads {
      Pimento.Roodhouse : exact;
      Cadwell.Coulter mask Buckfield : lpm;
   }
   actions {
      Gosnell;
      Isleta;
   }
   default_action : Isleta();
   size : Sespe;
}

@pragma atcam_partition_index Cadwell.Cotter
@pragma atcam_number_partitions Sespe
table Ammon {
   reads {
      Cadwell.Cotter : exact;
      Cadwell.Coulter mask Hartwell : lpm;
   }

   actions {
      Eclectic;
      Isleta;
   }
   default_action : Isleta();
   size : Christina;
}

action Canalou( Pinesdale ) {
   modify_field( Cadwell.Redmon, Pinesdale );
}

table Schaller {


   reads {
      Pimento.Roodhouse : exact;
      Cadwell.Coulter : lpm;
   }

   actions {
      Canalou;
      Isleta;
   }

   default_action : Isleta();
   size : Havana;
}

@pragma atcam_partition_index Cadwell.Redmon
@pragma atcam_number_partitions Havana
table Goldsmith {
   reads {
      Cadwell.Redmon : exact;


      Cadwell.Coulter mask HighHill : lpm;
   }
   actions {
      Eclectic;
      Isleta;
   }

   default_action : Isleta();
   size : Halsey;
}

@pragma idletime_precision 1
table Daykin {

   reads {
      Pimento.Roodhouse : exact;
      Kahului.Colonie : lpm;
   }

   actions {
      Eclectic;
      Isleta;
   }

   default_action : Isleta();
   size : Charlotte;
   support_timeout : true;
}

action Ronneby(Wayzata) {
   modify_field(Kahului.WestGate, Wayzata);
}

table Sylva {
   reads {
      Pimento.Roodhouse : exact;
      Kahului.Colonie : lpm;
   }

   actions {
      Ronneby;
      Isleta;
   }

   default_action : Isleta();
   size : LaConner;
}

//@pragma ways 2
@pragma atcam_partition_index Kahului.WestGate
@pragma atcam_number_partitions LaConner
table Admire {
   reads {
      Kahului.WestGate : exact;
      Kahului.Colonie mask Flippen : lpm;
   }
   actions {
      Eclectic;
      Isleta;
   }
   default_action : Isleta();
   size : Moorpark;
}

action Eclectic( Nisland ) {
   modify_field( Brazil.Amesville, 1 );
   modify_field( LoneJack.Komatke, Nisland );
}

@pragma idletime_precision 1
table Squire {
   reads {
      Pimento.Roodhouse : exact;
      Kahului.Colonie : exact;
   }

   actions {
      Eclectic;
      Isleta;
   }
   default_action : Isleta();
   size : Laney;
   support_timeout : true;
}

@pragma idletime_precision 1
table Geneva {
   reads {
      Pimento.Roodhouse : exact;
      Cadwell.Coulter : exact;
   }

   actions {
      Eclectic;
      Isleta;
   }
   default_action : Isleta();
   size : Emory;
   support_timeout : true;
}

action Westhoff(McAllen, Floris, McDaniels) {
   modify_field(Brazil.Rockdale, McDaniels);
   modify_field(Brazil.Sonora, McAllen);
   modify_field(Brazil.Willows, Floris);
   modify_field(Brazil.Amesville, 1);
}

table Bellwood {
   reads {
      LoneJack.Komatke : exact;
   }

   actions {
      Westhoff;
   }
   size : August;
}

control Sunset {
   if ( Wayne.Maiden == 0 and Pimento.Hildale == 1 ) {
      if ( ( Pimento.Panaca == 1 ) and ( Wayne.Raeford == 1 ) ) {
         apply( Squire ) {
            Isleta {
               apply( Sylva ) {
                  Ronneby {
                     apply( Admire ) {
                        Isleta {
                           apply( Virginia );
                        }
                     }
                  }
                  Isleta {
                     apply( Daykin );
                  }
               }
            }
         }
      } else if ( ( Pimento.Pevely == 1 ) and ( Wayne.Madeira == 1 ) ) {
         apply( Geneva ) {
            Isleta {
               apply( Schaller ) {
                  Canalou {
                     apply( Goldsmith ) {
                        Isleta {
                           apply( Jonesport );
                        }
                     }
                  }
                  Isleta {

                     apply( Garibaldi ) {
                        Gosnell {
                           apply( Ammon ) {
                              Isleta {
                                 apply( Paulding );
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

control Charters {
   if( LoneJack.Komatke != 0 ) {
      apply( Bellwood );
   }
}



field_list Oneonta {
   Orrum.WestEnd;
}

field_list_calculation Heuvelton {
    input {
        Oneonta;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Kealia {
    selection_key : Heuvelton;
    selection_mode : resilient;
}

action Chevak(Burien) {
   modify_field(Brazil.Slana, Burien);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Burien);
}

action_profile Steprock {
    actions {
        Chevak;
        Isleta;
    }
    size : Bridger;
    dynamic_action_selection : Kealia;
}

table Sylvan {
   reads {
      Brazil.Slana : exact;
   }
   action_profile: Steprock;
   size : Bufalo;
}

control Perez {
   if ((Wayne.Maiden == 0) and (Brazil.Slana & 0x2000) == 0x2000) {
      apply(Sylvan);
   }
}



action Ardenvoir() {
   modify_field(Brazil.Sonora, Wayne.Marshall);
   modify_field(Brazil.Willows, Wayne.Raritan);
   modify_field(Brazil.Stehekin, Wayne.Paoli);
   modify_field(Brazil.Hodges, Wayne.Rodessa);
   modify_field(Brazil.Rockdale, Wayne.Leland);
}

table McBride {
   actions {
      Ardenvoir;
   }
   default_action : Ardenvoir();
   size : 1;
}

control Hammonton {
   if (Wayne.Leland!=0) {
      apply( McBride );
   }
}

action Hanahan() {
   modify_field(Brazil.Lebanon, 1);
   modify_field(Brazil.Provo, 1);
   modify_field(Brazil.Norborne, Brazil.Rockdale);
}

action Fairlee() {
}



@pragma ways 1
table Pineland {
   reads {
      Brazil.Sonora : exact;
      Brazil.Willows : exact;
   }
   actions {
      Hanahan;
      Fairlee;
   }
   default_action : Fairlee;
   size : 1;
}

action Hammocks() {
   modify_field(Brazil.Osyka, 1);
   modify_field(Brazil.Hibernia, 1);
   add(Brazil.Norborne, Brazil.Rockdale, Creston);
}

table GlenRock {
   actions {
      Hammocks;
   }
   default_action : Hammocks;
   size : 1;
}

action Roswell() {
   modify_field(Brazil.Dorset, 1);
   modify_field(Brazil.Norborne, Brazil.Rockdale);
}

table Harvard {
   actions {
      Roswell;
   }
   default_action : Roswell();
   size : 1;
}

action BigPlain(PeaRidge) {
   modify_field(Brazil.Bigfork, 1);
   modify_field(Brazil.Slana, PeaRidge);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, PeaRidge);
}

action Haslet(Gwynn) {
   modify_field(Brazil.Osyka, 1);
   modify_field(Brazil.Norborne, Gwynn);
}

action Elkville() {
}

table Cherokee {
   reads {
      Brazil.Sonora : exact;
      Brazil.Willows : exact;
      Brazil.Rockdale : exact;
   }

   actions {
      BigPlain;
      Haslet;
      Elkville;
   }
   default_action : Elkville();
   size : Fenwick;
}

control Needles {
   if (Wayne.Maiden == 0) {
      apply(Cherokee) {
         Elkville {
            apply(Pineland) {
               Fairlee {
                  if ((Brazil.Sonora & 0x010000) == 0x010000) {
                     apply(GlenRock);
                  } else {
                     apply(Harvard);
                  }
               }
            }
         }
      }
   }
}


action Telida() {
   modify_field(Wayne.Maiden, 1);
}

table Genola {
   actions {
      Telida;
   }
   default_action : Telida;
   size : 1;
}

control Waxhaw {
   if ((Brazil.Amesville==0) and (Wayne.Malabar==Brazil.Slana)) {
      apply(Genola);
   }
}



action Ruffin( Winters ) {
   modify_field( Brazil.Sarepta, Winters );
}

action Valier() {
   modify_field( Brazil.Sarepta, Brazil.Rockdale );
}

table Brownson {
   reads {
      eg_intr_md.egress_port : exact;
      Brazil.Rockdale : exact;
   }

   actions {
      Ruffin;
      Valier;
   }
   default_action : Valier;
   size : Lamison;
}

control Glenshaw {
   apply( Brownson );
}



action Montbrook( Gotebo, Uvalde ) {
   modify_field( Brazil.Veteran, Gotebo );
   modify_field( Brazil.McKibben, Uvalde );
}


table Lolita {
   reads {
      Brazil.Elsmere : exact;
   }

   actions {
      Montbrook;
   }
   size : Hurst;
}

action Pilar() {
   no_op();
}

action Dunphy() {
   modify_field( ElmGrove.Carpenter, Oklee[0].Quogue );
   remove_header( Oklee[0] );
}

table Nestoria {
   actions {
      Dunphy;
   }
   default_action : Dunphy;
   size : Brinkley;
}

action Royston() {
   no_op();
}

action Taneytown() {
   add_header( Oklee[ 0 ] );
   modify_field( Oklee[0].ElPortal, Brazil.Sarepta );
   modify_field( Oklee[0].Quogue, ElmGrove.Carpenter );
   modify_field( ElmGrove.Carpenter, Putnam );
}



table Cragford {
   reads {
      Brazil.Sarepta : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Royston;
      Taneytown;
   }
   default_action : Taneytown;
   size : Whitefish;
}

action Mather() {
   modify_field(ElmGrove.Ashville, Brazil.Sonora);
   modify_field(ElmGrove.Arminto, Brazil.Willows);
   modify_field(ElmGrove.Hobart, Brazil.Veteran);
   modify_field(ElmGrove.Ackley, Brazil.McKibben);
}

action Wickett() {
   Mather();
   add_to_field(Arapahoe.Rockfield, -1);
}

action Trego() {
   Mather();
   add_to_field(Sargent.Broadmoor, -1);
}

table Tolleson {
   reads {
      Brazil.Cuprum : exact;
      Brazil.Elsmere : exact;
      Brazil.Amesville : exact;
      Arapahoe.valid : ternary;
      Sargent.valid : ternary;
   }

   actions {
      Wickett;
      Trego;
   }
   size : McFaddin;
}

control Wapato {
   apply( Nestoria );
}

control Killen {
   apply( Cragford );
}

control Hephzibah {
   apply( Lolita );
   apply( Tolleson );
}



field_list Aquilla {
    Beaverdam.Truro;
    Wayne.Leland;
    Perrin.Hobart;
    Perrin.Ackley;
    Arapahoe.Wyanet;
}

action Hisle() {
   generate_digest(Dunmore, Aquilla);
}

table Calcasieu {
   actions {
      Hisle;
   }

   default_action : Hisle;
   size : 1;
}

control Husum {
   if (Wayne.Onawa == 1) {
      apply(Calcasieu);
   }
}

control ingress {

   Elvaston();
   Westpoint();
   Othello();
   Homeacre();
   Layton();


   Puyallup();

   Alzada();
   Kansas();


   Sunset();

   Hammonton();

   Charters();


   LaMoille();



   Needles();


   Waxhaw();
   Husum();
   WallLake();


   if( valid( Oklee[0] ) ) {
      Wapato();
   }


   Perez();
}

control egress {
   Glenshaw();
   Hephzibah();
   Killen();
}

