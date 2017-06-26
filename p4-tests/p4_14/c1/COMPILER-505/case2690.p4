// BUILD: p4c-tofino --verbose 2 --placement tp4 --no-dead-code-elimination --o bf_obfuscate_arista_switch_default --p4-name=obfuscate_arista_switch --p4-prefix=p4_obfuscate_arista_switch --pipe-mgr-path=pipe_mgr/ --mc-mgr-path=mc_mgr/ --gen-exm-test-pd -S -DPROFILE_DEFAULT Switch.OBFUSCATED.p4


// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 235822







#ifdef __TARGET_BMV2__
#define BMV2
#endif

@pragma pa_solitary ingress Holliday.RockHall

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>



#ifndef Koloa
#define Koloa

header_type Wayland {
	fields {
		Potter : 16;
		Exell : 16;
		Brockton : 8;
		Bunavista : 8;
		Throop : 8;
		Roxobel : 8;
		Madison : 1;
		Sherwin : 1;
		Granville : 1;
		Rendon : 1;
		Weimar : 1;
	}
}

header_type Kingsdale {
	fields {
		Cochrane : 24;
		Swenson : 24;
		Angwin : 24;
		Wondervu : 24;
		Barksdale : 16;
		Catlin : 16;
		Seagrove : 16;
		Corbin : 16;
		Bellmead : 16;
		Elderon : 8;
		Dutton : 8;
		Rosario : 1;
		Caulfield : 1;
		Johnstown : 12;
		Honalo : 2;
		Candle : 1;
		Cropper : 1;
		Sardinia : 1;
		Knolls : 1;
		CoalCity : 1;
		LaCueva : 1;
		Paradise : 1;
		Wartrace : 1;
		Cabery : 1;
		Leland : 1;
		Thawville : 1;
		Kewanee : 1;
		Kentwood : 1;
		Catarina : 10;
		Hildale : 1;
		Alamota : 2;
	}
}

header_type Wynnewood {
	fields {
		Boerne : 24;
		Miltona : 24;
		Blanding : 24;
		MillCity : 24;
		Wellton : 24;
		Rehobeth : 24;
		Ethete : 24;
		HydePark : 24;
		Suarez : 16;
		Clover : 16;
		WestPike : 16;
		Talco : 16;
		Iroquois : 12;
		Perrytown : 3;
		Amenia : 1;
		Botna : 3;
		Kenova : 1;
		Lisle : 1;
		Sammamish : 1;
		Overton : 1;
		Myton : 1;
		Stone : 1;
		Dyess : 8;
		Venice : 12;
		Belvidere : 4;
		Wakeman : 6;
		Peebles : 10;
		Dunken : 9;
		WindGap : 1;
		Maljamar : 10;
		Telephone : 2;
		Monse : 16;
	}
}


header_type Range {
	fields {
		Epsie : 8;
		Hilburn : 1;
		Lamkin : 1;
		Ledford : 1;
		Simla : 1;
		Dizney : 1;
	}
}

header_type Fordyce {
	fields {
		Philippi : 32;
		Huttig : 32;
		RockHall : 8;
		Dresden : 16;
	}
}

header_type Forman {
	fields {
		Kennebec : 128;
		Clearlake : 128;
		Kathleen : 20;
		Lafourche : 8;
		Roswell : 11;
		Fergus : 6;
		Mahomet : 13;
	}
}

header_type Seibert {
	fields {
		Flats : 14;
		McCracken : 1;
		Wataga : 12;
		Bowlus : 1;
		Issaquah : 1;
		Raceland : 6;
		ElmGrove : 2;
		Kupreanof : 6;
		Wanatah : 3;
	}
}

header_type Centre {
	fields {
		ElkFalls : 1;
		Larchmont : 1;
	}
}

header_type Lennep {
	fields {
		Sagerton : 8;
	}
}

header_type Tindall {
	fields {
		Muenster : 16;
		Cordell : 11;
	}
}

header_type Verdemont {
	fields {
		Shields : 32;
		Knollwood : 32;
		Warba : 32;
	}
}

header_type Reidville {
	fields {
		Bammel : 32;
		Bluewater : 32;
	}
}

header_type McManus {
	fields {
		Lehigh : 8;
		Hayward : 4;
		Whitlash : 15;
		Onava : 1;
		Germano : 1;
		Fredonia : 1;
		Hamburg : 3;
		Frontenac : 1;
		Telida : 6;
	}
}


#define Chambers          0
#define Gannett   1
#define Metter    2
#define Bloomdale       3
#define Dorothy  4
#define Tombstone     5
#define Ravenwood        6

#endif



#ifndef Lanesboro
#define Lanesboro


header_type Pacifica {
	fields {
		Telegraph : 6;
		Anchorage : 10;
		Clearmont : 4;
		Alvord : 12;
		Cowen : 12;
		Micro : 2;
		Admire : 2;
		Kasigluk : 8;
		Hilltop : 3;
		Weehawken : 5;
	}
}



header_type Ellisburg {
	fields {
		CassCity : 24;
		LaMoille : 24;
		Husum : 24;
		Kinard : 24;
		Tingley : 16;
	}
}



header_type Crossett {
	fields {
		Salduro : 3;
		Sieper : 1;
		Yakima : 12;
		Neubert : 16;
	}
}



header_type Oshoto {
	fields {
		Lovett : 4;
		Slagle : 4;
		Titonka : 6;
		Wyandanch : 2;
		Warden : 16;
		Tulia : 16;
		Macon : 3;
		Salamonia : 13;
		Lindsborg : 8;
		Brashear : 8;
		McGovern : 16;
		Sedan : 32;
		Kinross : 32;
	}
}

header_type Davant {
	fields {
		Ireton : 4;
		Maben : 6;
		Bosler : 2;
		Atwater : 20;
		Hawley : 16;
		Grassflat : 8;
		Yaurel : 8;
		Oilmont : 128;
		Duster : 128;
	}
}




header_type Halliday {
	fields {
		Accomac : 8;
		Farlin : 8;
		Amite : 16;
	}
}

header_type Woodcrest {
	fields {
		Hopland : 16;
		Bonney : 16;
	}
}

header_type Toxey {
	fields {
		Uhland : 32;
		Redden : 32;
		Madawaska : 4;
		Manistee : 4;
		Darco : 8;
		Thurston : 16;
		Honaker : 16;
		Sheldahl : 16;
	}
}

header_type Sanchez {
	fields {
		Brewerton : 16;
		Tusayan : 16;
	}
}



header_type Blossom {
	fields {
		Madras : 16;
		Chitina : 16;
		Trammel : 8;
		Poipu : 8;
		Korbel : 16;
	}
}

header_type Sabana {
	fields {
		Reydon : 48;
		Plata : 32;
		Shuqualak : 48;
		Waucoma : 32;
	}
}



header_type Macksburg {
	fields {
		Tarnov : 1;
		Bethania : 1;
		Mabank : 1;
		Ludden : 1;
		WebbCity : 1;
		Tanana : 3;
		Pridgen : 5;
		Lamont : 3;
		Bayne : 16;
	}
}

header_type Grandy {
	fields {
		Nuiqsut : 24;
		Yorklyn : 8;
	}
}



header_type Monmouth {
	fields {
		Waring : 8;
		Termo : 24;
		Seabrook : 24;
		Reading : 8;
	}
}

#endif



#ifndef Levittown
#define Levittown

#define Magness        0x8100
#define Chelsea        0x0800
#define Correo        0x86dd
#define Braxton        0x9100
#define Academy        0x8847
#define Union         0x0806
#define Lenoir        0x8035
#define Truro        0x88cc
#define Lamona        0x8809
#define Vieques      0xBF00

#define Cusick              1
#define Dennison              2
#define Lambert              4
#define Ranier               6
#define Kingsland               17
#define Devore                47

#define Millsboro         0x501
#define Nason          0x506
#define Snook          0x511
#define Bacton          0x52F


#define Loogootee                 4789



#define Edinburgh               0
#define Gallion              1
#define Paulding                2



#define Novinger          0
#define Branson          4095
#define Netcong  4096
#define Needham  8191



#define ElPrado                      0
#define Moraine                  0
#define Quogue                 1

header Ellisburg Filley;
header Ellisburg Trooper;
header Crossett Dougherty[ 2 ];



@pragma pa_fragment ingress Uniopolis.McGovern
@pragma pa_fragment egress Uniopolis.McGovern
header Oshoto Uniopolis;

@pragma pa_fragment ingress Longford.McGovern
@pragma pa_fragment egress Longford.McGovern
header Oshoto Longford;

header Davant Joslin;
header Davant Bairoil;
header Woodcrest Jerico;
header Toxey Rosburg;

header Sanchez Makawao;
header Toxey Gibson;
header Sanchez Renfroe;
header Monmouth Inverness;
header Blossom Fennimore;
header Macksburg Wenden;
header Pacifica Toano;
header Ellisburg RiceLake;

parser start {
   return select(current(96, 16)) {
      Vieques : Mendoza;
      default : Glenvil;
   }
}

parser Skyway {
   extract( Toano );
   return Glenvil;
}

parser Mendoza {
   extract( RiceLake );
   return Skyway;
}

parser Glenvil {
   extract( Filley );
   return select( Filley.Tingley ) {
      Magness : Keokee;
      Chelsea : Ammon;
      Correo : Hooker;
      Union  : Rotterdam;
      default        : ingress;
   }
}

parser Keokee {
   extract( Dougherty[0] );
   set_metadata(WildRose.Weimar, 1);
   return select( Dougherty[0].Neubert ) {
      Chelsea : Ammon;
      Correo : Hooker;
      Union  : Rotterdam;
      default : ingress;
   }
}

field_list Boyle {
    Uniopolis.Lovett;
    Uniopolis.Slagle;
    Uniopolis.Titonka;
    Uniopolis.Wyandanch;
    Uniopolis.Warden;
    Uniopolis.Tulia;
    Uniopolis.Macon;
    Uniopolis.Salamonia;
    Uniopolis.Lindsborg;
    Uniopolis.Brashear;
    Uniopolis.Sedan;
    Uniopolis.Kinross;
}

field_list_calculation Benonine {
    input {
        Boyle;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field Uniopolis.McGovern  {
    verify Benonine;
    update Benonine;
}

parser Ammon {
   extract( Uniopolis );
   set_metadata(WildRose.Brockton, Uniopolis.Brashear);
   set_metadata(WildRose.Throop, Uniopolis.Lindsborg);
   set_metadata(WildRose.Potter, Uniopolis.Warden);
   set_metadata(WildRose.Granville, 0);
   set_metadata(WildRose.Madison, 1);
   return select(Uniopolis.Salamonia, Uniopolis.Slagle, Uniopolis.Brashear) {
      Snook : Dunkerton;
      Nason : Barron;
      default : ingress;
   }
}

parser Hooker {
   extract( Bairoil );
   set_metadata(WildRose.Brockton, Bairoil.Grassflat);
   set_metadata(WildRose.Throop, Bairoil.Yaurel);
   set_metadata(WildRose.Potter, Bairoil.Hawley);
   set_metadata(WildRose.Granville, 1);
   set_metadata(WildRose.Madison, 0);
   return select(Bairoil.Grassflat) {
      Snook : Molson;
      Nason : Barron;
      default : ingress;
   }
}

parser Rotterdam {
   extract( Fennimore );
   return ingress;
}

parser Dunkerton {
   extract(Jerico);
   extract(Makawao);
   return select(Jerico.Bonney) {
      Loogootee : Amanda;
      default : ingress;
    }
}

parser Molson {
   extract(Jerico);
   extract(Makawao);
   return ingress;
}

parser Barron {
   extract(Jerico);
   extract(Rosburg);
   return ingress;
}

parser Indrio {
   set_metadata(Deeth.Honalo, Paulding);
   return Gibbstown;
}

parser Samson {
   set_metadata(Deeth.Honalo, Paulding);
   return Edler;
}

parser Trevorton {
   extract(Wenden);
   return select(Wenden.Tarnov, Wenden.Bethania, Wenden.Mabank, Wenden.Ludden, Wenden.WebbCity,
             Wenden.Tanana, Wenden.Pridgen, Wenden.Lamont, Wenden.Bayne) {
      Chelsea : Indrio;
      Correo : Samson;
      default : ingress;
   }
}

parser Amanda {
   extract(Inverness);
   set_metadata(Deeth.Honalo, Gallion);
   return Edmeston;
}

field_list Rosboro {
    Longford.Lovett;
    Longford.Slagle;
    Longford.Titonka;
    Longford.Wyandanch;
    Longford.Warden;
    Longford.Tulia;
    Longford.Macon;
    Longford.Salamonia;
    Longford.Lindsborg;
    Longford.Brashear;
    Longford.Sedan;
    Longford.Kinross;
}

field_list_calculation Menifee {
    input {
        Rosboro;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field Longford.McGovern  {
    verify Menifee;
    update Menifee;
}

parser Gibbstown {
   extract( Longford );
   set_metadata(WildRose.Bunavista, Longford.Brashear);
   set_metadata(WildRose.Roxobel, Longford.Lindsborg);
   set_metadata(WildRose.Exell, Longford.Warden);
   set_metadata(WildRose.Rendon, 0);
   set_metadata(WildRose.Sherwin, 1);
   return ingress;
}

parser Edler {
   extract( Joslin );
   set_metadata(WildRose.Bunavista, Joslin.Grassflat);
   set_metadata(WildRose.Roxobel, Joslin.Yaurel);
   set_metadata(WildRose.Exell, Joslin.Hawley);
   set_metadata(WildRose.Rendon, 1);
   set_metadata(WildRose.Sherwin, 0);
   return ingress;
}

parser Edmeston {
   extract( Trooper );
   return select( Trooper.Tingley ) {
      Chelsea: Gibbstown;
      Correo: Edler;
      default: ingress;
   }
}
#endif

metadata Kingsdale Deeth;
metadata Wynnewood Carver;
metadata Seibert Weinert;
metadata Wayland WildRose;
metadata Fordyce Holliday;
metadata Forman Terrytown;
metadata Centre Swisher;
metadata Range Rillton;
metadata Lennep Terral;
metadata Tindall Clarion;
metadata Reidville Lakin;
metadata Verdemont Lemoyne;
metadata McManus Redmon;













#undef Glentana

#undef Strasburg
#undef Angle
#undef Isleta
#undef Ledger
#undef Barstow

#undef Ulysses
#undef Anthon
#undef Hokah

#undef Penalosa
#undef Gorman
#undef Guion
#undef Dassel
#undef Bunker
#undef Bremond
#undef Wyncote
#undef Colmar
#undef Trona
#undef LoonLake
#undef Clarissa
#undef Belfast
#undef Ossipee
#undef Brookside
#undef Paragonah
#undef Mendota
#undef Nordland
#undef Westline
#undef Milam
#undef Weslaco
#undef Wapato

#undef Eldena
#undef BigRock
#undef Milan
#undef Kranzburg
#undef Basco
#undef Quinwood
#undef Stidham
#undef Artas
#undef Willey
#undef Woodfords
#undef Parmele
#undef Roachdale
#undef Chehalis
#undef LeeCity
#undef Naubinway
#undef Glenshaw
#undef ShadeGap
#undef Newhalen
#undef Daisytown
#undef RushCity
#undef Clyde
#undef Casselman
#undef Micco

#undef MoonRun
#undef Abernant

#undef Kiana

#undef Sonoita
#undef Lantana

#undef Pearcy
#undef Rotonda
#undef Cairo
#undef Lumpkin






#define Glentana 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Strasburg      65536
#define Angle      65536
#define Isleta 512
#define Ledger 512
#define Barstow      512


#define Ulysses     1024
#define Anthon    1024
#define Hokah     256


#define Penalosa 512
#define Gorman 65536
#define Guion 65536
#define Dassel 28672
#define Bunker   16384
#define Bremond 8192
#define Wyncote         131072
#define Colmar 65536
#define Trona 1024
#define LoonLake 2048
#define Clarissa 16384
#define Belfast 8192
#define Ossipee 65536

#define Brookside 0x0000000000000000FFFFFFFFFFFFFFFF


#define Paragonah 0x000fffff
#define Westline 2

#define Mendota 0xFFFFFFFFFFFFFFFF0000000000000000

#define Nordland 0x000007FFFFFFFFFF0000000000000000
#define Milam  6
#define Wapato        2048
#define Weslaco       65536


#define Eldena 1024
#define BigRock 4096
#define Milan 4096
#define Kranzburg 4096
#define Basco 4096
#define Quinwood 1024
#define Stidham 4096
#define Willey 128
#define Woodfords 1
#define Parmele  8


#define Roachdale 512
#define MoonRun 512
#define Abernant 256


#define Chehalis 2
#define LeeCity 3
#define Naubinway 80



#define Glenshaw 512
#define ShadeGap 512
#define Newhalen 512
#define Daisytown 512

#define RushCity 2048
#define Clyde 1024

#define Casselman 1
#define Micco 512



#define Kiana 0


#define Sonoita    4096
#define Lantana    1024


#define Pearcy        64
#define Rotonda 256
#define Cairo 256
#define Lumpkin    2


#endif



#ifndef Rocklin
#define Rocklin

action Scherr() {
   no_op();
}

action Dellslow() {
   modify_field(Deeth.Knolls, 1 );
   mark_for_drop();
}

action Gilman() {
   no_op();
}
#endif




#define Cuprum            0
#define Montbrook  1
#define Holcut 2


#define Tallassee              0
#define Newland             1
#define BigPoint 2


















action Riverland(Roodhouse, Mabana, WestEnd, Ribera, Paradis, Point,
                 Tehachapi, Lewiston, Nashua) {
    modify_field(Weinert.Flats, Roodhouse);
    modify_field(Weinert.McCracken, Mabana);
    modify_field(Weinert.Wataga, WestEnd);
    modify_field(Weinert.Bowlus, Ribera);
    modify_field(Weinert.Issaquah, Paradis);
    modify_field(Weinert.Raceland, Point);
    modify_field(Weinert.ElmGrove, Tehachapi);
    modify_field(Weinert.Wanatah, Lewiston);
    modify_field(Weinert.Kupreanof, Nashua);
}

@pragma command_line --no-dead-code-elimination
table Upland {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Riverland;
    }
    size : Glentana;
}

control PineLawn {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Upland);
    }
}





action Charco(Wilson) {
   modify_field( Carver.Amenia, 1 );
   modify_field( Carver.Dyess, Wilson);
   modify_field( Deeth.Leland, 1 );
}

action Eastover() {
   modify_field( Deeth.Paradise, 1 );
   modify_field( Deeth.Kewanee, 1 );
}

action Newhalem() {
   modify_field( Deeth.Leland, 1 );
}

action Fiskdale() {
   modify_field( Deeth.Thawville, 1 );
}

action Mangham() {
   modify_field( Deeth.Kewanee, 1 );
}

counter Hobergs {
   type : packets_and_bytes;
   direct : Litroe;
   min_width: 16;
}

table Litroe {
   reads {
      Weinert.Raceland : exact;
      Filley.CassCity : ternary;
      Filley.LaMoille : ternary;
   }

   actions {
      Charco;
      Eastover;
      Newhalem;
      Fiskdale;
      Mangham;
   }
   size : Isleta;
}

action BigWells() {
   modify_field( Deeth.Wartrace, 1 );
}


table Irvine {
   reads {
      Filley.Husum : ternary;
      Filley.Kinard : ternary;
   }

   actions {
      BigWells;
   }
   size : Ledger;
}


control Airmont {
   apply( Litroe );
   apply( Irvine );
}




action Otego() {
   modify_field( Holliday.Philippi, Longford.Sedan );
   modify_field( Holliday.Huttig, Longford.Kinross );
   modify_field( Holliday.RockHall, Longford.Titonka );
   modify_field( Terrytown.Kennebec, Joslin.Oilmont );
   modify_field( Terrytown.Clearlake, Joslin.Duster );
   modify_field( Terrytown.Kathleen, Joslin.Atwater );
   modify_field( Terrytown.Fergus, Joslin.Maben );
   modify_field( Deeth.Cochrane, Trooper.CassCity );
   modify_field( Deeth.Swenson, Trooper.LaMoille );
   modify_field( Deeth.Angwin, Trooper.Husum );
   modify_field( Deeth.Wondervu, Trooper.Kinard );
   modify_field( Deeth.Barksdale, Trooper.Tingley );
   modify_field( Deeth.Bellmead, WildRose.Exell );
   modify_field( Deeth.Elderon, WildRose.Bunavista );
   modify_field( Deeth.Dutton, WildRose.Roxobel );
   modify_field( Deeth.Caulfield, WildRose.Sherwin );
   modify_field( Deeth.Rosario, WildRose.Rendon );
   modify_field( Deeth.Kentwood, 0 );
   modify_field( Carver.Botna, Newland );



   modify_field( Weinert.ElmGrove, 1 );
   modify_field( Weinert.Wanatah, 0 );
   modify_field( Weinert.Kupreanof, 0 );
   modify_field( Redmon.Germano, 1 );
   modify_field( Redmon.Fredonia, 1 );
}

action Struthers() {
   modify_field( Deeth.Honalo, Edinburgh );
   modify_field( Holliday.Philippi, Uniopolis.Sedan );
   modify_field( Holliday.Huttig, Uniopolis.Kinross );
   modify_field( Holliday.RockHall, Uniopolis.Titonka );
   modify_field( Terrytown.Kennebec, Bairoil.Oilmont );
   modify_field( Terrytown.Clearlake, Bairoil.Duster );
   modify_field( Terrytown.Kathleen, Bairoil.Atwater );
   modify_field( Terrytown.Fergus, Bairoil.Maben );
   modify_field( Deeth.Cochrane, Filley.CassCity );
   modify_field( Deeth.Swenson, Filley.LaMoille );
   modify_field( Deeth.Angwin, Filley.Husum );
   modify_field( Deeth.Wondervu, Filley.Kinard );
   modify_field( Deeth.Barksdale, Filley.Tingley );
   modify_field( Deeth.Bellmead, WildRose.Potter );
   modify_field( Deeth.Elderon, WildRose.Brockton );
   modify_field( Deeth.Dutton, WildRose.Throop );
   modify_field( Deeth.Caulfield, WildRose.Madison );
   modify_field( Deeth.Rosario, WildRose.Granville );
   modify_field( Redmon.Frontenac, Dougherty[0].Sieper );
   modify_field( Deeth.Kentwood, WildRose.Weimar );
}

table Brundage {
   reads {
      Filley.CassCity : exact;
      Filley.LaMoille : exact;
      Uniopolis.Kinross : exact;
      Deeth.Honalo : exact;
   }

   actions {
      Otego;
      Struthers;
   }

   default_action : Struthers();
   size : Eldena;
}


action Isabel() {
   modify_field( Deeth.Catlin, Weinert.Wataga );
   modify_field( Deeth.Seagrove, Weinert.Flats);
}

action Orrville( Kinards ) {
   modify_field( Deeth.Catlin, Kinards );
   modify_field( Deeth.Seagrove, Weinert.Flats);
}

action Rocklake() {
   modify_field( Deeth.Catlin, Dougherty[0].Yakima );
   modify_field( Deeth.Seagrove, Weinert.Flats);
}

table Millston {
   reads {
      Weinert.Flats : ternary;
      Dougherty[0] : valid;
      Dougherty[0].Yakima : ternary;
   }

   actions {
      Isabel;
      Orrville;
      Rocklake;
   }
   size : Kranzburg;
}

action Hammocks( Penzance ) {
   modify_field( Deeth.Seagrove, Penzance );
}

action Almedia() {

   modify_field( Deeth.Sardinia, 1 );
   modify_field( Terral.Sagerton,
                 Quogue );
}

table Uniontown {
   reads {
      Uniopolis.Sedan : exact;
   }

   actions {
      Hammocks;
      Almedia;
   }
   default_action : Almedia;
   size : Milan;
}

action Castolon( Emerado, Mekoryuk, Lansing, Hamel, Kenefic,
                        Waterman, Lepanto ) {
   modify_field( Deeth.Catlin, Emerado );
   modify_field( Deeth.Corbin, Emerado );
   modify_field( Deeth.LaCueva, Lepanto );
   Kipahulu(Mekoryuk, Lansing, Hamel, Kenefic,
                        Waterman );
}

action Tramway() {
   modify_field( Deeth.CoalCity, 1 );
}

table Wyndmoor {
   reads {
      Inverness.Seabrook : exact;
   }

   actions {
      Castolon;
      Tramway;
   }
   size : BigRock;
}

action Kipahulu(Minto, Pinecrest, Barber, Trimble,
                        Lebanon ) {
   modify_field( Rillton.Epsie, Minto );
   modify_field( Rillton.Hilburn, Pinecrest );
   modify_field( Rillton.Ledford, Barber );
   modify_field( Rillton.Lamkin, Trimble );
   modify_field( Rillton.Simla, Lebanon );
}

action Bothwell(Sandstone, Oxford, Blakeslee, Hillister,
                        Osseo ) {
   modify_field( Deeth.Corbin, Weinert.Wataga );
   modify_field( Deeth.LaCueva, 1 );
   Kipahulu(Sandstone, Oxford, Blakeslee, Hillister,
                        Osseo );
}

action Atlantic(Putnam, Heppner, Dibble, Winfall,
                        Cullen, Gordon ) {
   modify_field( Deeth.Corbin, Putnam );
   modify_field( Deeth.LaCueva, 1 );
   Kipahulu(Heppner, Dibble, Winfall, Cullen,
                        Gordon );
}

action Millbrook(Vergennes, Dahlgren, Provencal, Kalskag,
                        Chaska ) {
   modify_field( Deeth.Corbin, Dougherty[0].Yakima );
   modify_field( Deeth.LaCueva, 1 );
   Kipahulu(Vergennes, Dahlgren, Provencal, Kalskag,
                        Chaska );
}

table Charlack {
   reads {
      Weinert.Wataga : exact;
   }


   actions {
      Scherr;
      Bothwell;
   }

   size : Basco;
}

@pragma action_default_only Scherr
table Selah {
   reads {
      Weinert.Flats : exact;
      Dougherty[0].Yakima : exact;
   }

   actions {
      Atlantic;
      Scherr;
   }

   size : Quinwood;
}

table Genola {
   reads {
      Dougherty[0].Yakima : exact;
   }


   actions {
      Scherr;
      Millbrook;
   }

   size : Stidham;
}

control Enderlin {
   apply( Brundage ) {
         Otego {
            apply( Uniontown );
            apply( Wyndmoor );
         }
         Struthers {
            if ( not valid(Toano) and Weinert.Bowlus == 1 ) {
               apply( Millston );
            }
            if ( valid( Dougherty[ 0 ] ) ) {

               apply( Selah ) {
                  Scherr {

                     apply( Genola );
                  }
               }
            } else {

               apply( Charlack );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Gregory {
    width  : 1;
    static : Troutman;
    instance_count : 262144;
}

register Argentine {
    width  : 1;
    static : Westhoff;
    instance_count : 262144;
}

blackbox stateful_alu Saluda {
    reg : Gregory;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Swisher.ElkFalls;
}

blackbox stateful_alu SomesBar {
    reg : Argentine;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Swisher.Larchmont;
}

field_list Calamus {
    Weinert.Raceland;
    Dougherty[0].Yakima;
}

field_list_calculation RedMills {
    input { Calamus; }
    algorithm: identity;
    output_width: 18;
}

action Delcambre() {
    Saluda.execute_stateful_alu_from_hash(RedMills);
}

action Surrency() {
    SomesBar.execute_stateful_alu_from_hash(RedMills);
}

table Troutman {
    actions {
      Delcambre;
    }
    default_action : Delcambre;
    size : 1;
}

table Westhoff {
    actions {
      Surrency;
    }
    default_action : Surrency;
    size : 1;
}
#endif

action Rockvale(Eaton) {
    modify_field(Swisher.Larchmont, Eaton);
}

@pragma  use_hash_action 0
table Brinson {
    reads {
       Weinert.Raceland : exact;
    }
    actions {
      Rockvale;
    }
    size : 64;
}

action Gobles() {
   modify_field( Deeth.Johnstown, Weinert.Wataga );
   modify_field( Deeth.Candle, 0 );
}

table Wymer {
   actions {
      Gobles;
   }
   size : 1;
}

action McBrides() {
   modify_field( Deeth.Johnstown, Dougherty[0].Yakima );
   modify_field( Deeth.Candle, 1 );
}

table Hammond {
   actions {
      McBrides;
   }
   size : 1;
}

control Oakford {
   if ( valid( Dougherty[ 0 ] ) ) {
      apply( Hammond );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Weinert.Issaquah == 1 ) {
         apply( Troutman );
         apply( Westhoff );
      }
#endif
   } else {
      apply( Wymer );
      if( Weinert.Issaquah == 1 ) {
         apply( Brinson );
      }
   }
}




field_list Virginia {
   Filley.CassCity;
   Filley.LaMoille;
   Filley.Husum;
   Filley.Kinard;
   Filley.Tingley;
}

field_list Placid {

   Uniopolis.Brashear;
   Uniopolis.Sedan;
   Uniopolis.Kinross;
}

field_list OjoFeliz {
   Bairoil.Oilmont;
   Bairoil.Duster;
   Bairoil.Atwater;
   Bairoil.Grassflat;
}

field_list OldMines {
   Uniopolis.Sedan;
   Uniopolis.Kinross;
   Jerico.Hopland;
   Jerico.Bonney;
}





field_list_calculation Chualar {
    input {
        Virginia;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Sylvan {
    input {
        Placid;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Sidnaw {
    input {
        OjoFeliz;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Ebenezer {
    input {
        OldMines;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Corry() {
    modify_field_with_hash_based_offset(Lemoyne.Shields, 0,
                                        Chualar, 4294967296);
}

action PellLake() {
    modify_field_with_hash_based_offset(Lemoyne.Knollwood, 0,
                                        Sylvan, 4294967296);
}

action Dubach() {
    modify_field_with_hash_based_offset(Lemoyne.Knollwood, 0,
                                        Sidnaw, 4294967296);
}

action Piketon() {
    modify_field_with_hash_based_offset(Lemoyne.Warba, 0,
                                        Ebenezer, 4294967296);
}

table Crump {
   actions {
      Corry;
   }
   size: 1;
}

control Slinger {
   apply(Crump);
}

table Preston {
   actions {
      PellLake;
   }
   size: 1;
}

table Chavies {
   actions {
      Dubach;
   }
   size: 1;
}

control Jamesburg {
   if ( valid( Uniopolis ) ) {
      apply(Preston);
   } else {
      if ( valid( Bairoil ) ) {
         apply(Chavies);
      }
   }
}

table Mapleton {
   actions {
      Piketon;
   }
   size: 1;
}

control Gowanda {
   if ( valid( Makawao ) ) {
      apply(Mapleton);
   }
}



action Gotebo() {
    modify_field(Lakin.Bammel, Lemoyne.Shields);
}

action Sargeant() {
    modify_field(Lakin.Bammel, Lemoyne.Knollwood);
}

action Judson() {
    modify_field(Lakin.Bammel, Lemoyne.Warba);
}

@pragma action_default_only Scherr
@pragma immediate 0
table Tilghman {
   reads {
      Gibson.valid : ternary;
      Renfroe.valid : ternary;
      Longford.valid : ternary;
      Joslin.valid : ternary;
      Trooper.valid : ternary;
      Rosburg.valid : ternary;
      Makawao.valid : ternary;
      Uniopolis.valid : ternary;
      Bairoil.valid : ternary;
      Filley.valid : ternary;
   }
   actions {
      Gotebo;
      Sargeant;
      Judson;
      Scherr;
   }
   size: Hokah;
}

action Conejo() {
    modify_field(Lakin.Bluewater, Lemoyne.Warba);
}

@pragma immediate 0
table Virden {
   reads {
      Gibson.valid : ternary;
      Renfroe.valid : ternary;
      Rosburg.valid : ternary;
      Makawao.valid : ternary;
   }
   actions {
      Conejo;
      Scherr;
   }
   size: Milam;
}

control Biddle {
   apply(Virden);
   apply(Tilghman);
}



counter Lansdowne {
   type : packets_and_bytes;
   direct : Saltair;
   min_width: 16;
}

table Saltair {
   reads {
      Weinert.Raceland : exact;
      Swisher.Larchmont : ternary;
      Swisher.ElkFalls : ternary;
      Deeth.CoalCity : ternary;
      Deeth.Wartrace : ternary;
      Deeth.Paradise : ternary;
   }

   actions {
      Dellslow;
      Scherr;
   }
   default_action : Scherr();
   size : Barstow;
}

action Wauregan() {

   modify_field(Deeth.Cropper, 1 );
   modify_field(Terral.Sagerton,
                Moraine);
}







table Ekron {
   reads {
      Deeth.Angwin : exact;
      Deeth.Wondervu : exact;
      Deeth.Catlin : exact;
      Deeth.Seagrove : exact;
   }

   actions {
      Gilman;
      Wauregan;
   }
   default_action : Wauregan();
   size : Angle;
   support_timeout : true;
}

action Haugan() {
   modify_field( Rillton.Dizney, 1 );
}

table Risco {
   reads {
      Deeth.Corbin : ternary;
      Deeth.Cochrane : exact;
      Deeth.Swenson : exact;
   }
   actions {
      Haugan;
   }
   size: Penalosa;
}

control Eckman {
   apply( Saltair ) {
      Scherr {



         if (Weinert.McCracken == 0 and Deeth.Sardinia == 0) {
            apply( Ekron );
         }
         apply(Risco);
      }
   }
}

field_list Andrade {
    Terral.Sagerton;
    Deeth.Angwin;
    Deeth.Wondervu;
    Deeth.Catlin;
    Deeth.Seagrove;
}

action Verbena() {
   generate_digest(ElPrado, Andrade);
}

table Villanova {
   actions {
      Verbena;
   }
   size : 1;
}

control Cedaredge {
   if (Deeth.Cropper == 1) {
      apply( Villanova );
   }
}



action Kahaluu( Bowdon, Gould ) {
   modify_field( Terrytown.Mahomet, Bowdon );
   modify_field( Clarion.Muenster, Gould );
}

@pragma action_default_only Grinnell
table Earlimart {
   reads {
      Rillton.Epsie : exact;
      Terrytown.Clearlake mask Mendota : lpm;
   }
   actions {
      Kahaluu;
      Grinnell;
   }
   size : Belfast;
}

@pragma atcam_partition_index Terrytown.Mahomet
@pragma atcam_number_partitions Belfast
table Youngtown {
   reads {
      Terrytown.Mahomet : exact;
      Terrytown.Clearlake mask Nordland : lpm;
   }

   actions {
      DelRey;
      Maydelle;
      Scherr;
   }
   default_action : Scherr();
   size : Ossipee;
}

action Clementon( Delmont, Watters ) {
   modify_field( Terrytown.Roswell, Delmont );
   modify_field( Clarion.Muenster, Watters );
}

@pragma action_default_only Scherr
table ElPortal {


   reads {
      Rillton.Epsie : exact;
      Terrytown.Clearlake : lpm;
   }

   actions {
      Clementon;
      Scherr;
   }

   size : LoonLake;
}

@pragma atcam_partition_index Terrytown.Roswell
@pragma atcam_number_partitions LoonLake
table Houston {
   reads {
      Terrytown.Roswell : exact;


      Terrytown.Clearlake mask Brookside : lpm;
   }
   actions {
      DelRey;
      Maydelle;
      Scherr;
   }

   default_action : Scherr();
   size : Clarissa;
}

@pragma action_default_only Grinnell
@pragma idletime_precision 1
table Buncombe {

   reads {
      Rillton.Epsie : exact;
      Holliday.Huttig : lpm;
   }

   actions {
      DelRey;
      Maydelle;
      Grinnell;
   }

   size : Trona;
   support_timeout : true;
}

action Villas( McCaskill, RedCliff ) {
   modify_field( Holliday.Dresden, McCaskill );
   modify_field( Clarion.Muenster, RedCliff );
}

@pragma action_default_only Scherr
#ifdef PROFILE_DEFAULT
//@pragma stage 2 Bremond
//@pragma stage 3
#endif
table Emida {
   reads {
      Rillton.Epsie : exact;
      Holliday.Huttig : lpm;
   }

   actions {
      Villas;
      Scherr;
   }

   size : Bunker;
}

@pragma ways Westline
@pragma atcam_partition_index Holliday.Dresden
@pragma atcam_number_partitions Bunker
table Noyack {
   reads {
      Holliday.Dresden : exact;
      Holliday.Huttig mask Paragonah : lpm;
   }
   actions {
      DelRey;
      Maydelle;
      Scherr;
   }
   default_action : Scherr();
   size : Wyncote;
}

action DelRey( Blackwood ) {
   modify_field( Clarion.Muenster, Blackwood );
}

@pragma idletime_precision 1
table DeLancey {
   reads {
      Rillton.Epsie : exact;
      Holliday.Huttig : exact;
   }

   actions {
      DelRey;
      Maydelle;
      Scherr;
   }
   default_action : Scherr();
   size : Gorman;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
//@pragma stage 2 Dassel
//@pragma stage 3
#endif
table Statham {
   reads {
      Rillton.Epsie : exact;
      Terrytown.Clearlake : exact;
   }

   actions {
      DelRey;
      Maydelle;
      Scherr;
   }
   default_action : Scherr();
   size : Guion;
   support_timeout : true;
}

action Grovetown(Abraham, Tolleson, Merkel) {
   modify_field(Carver.Suarez, Merkel);
   modify_field(Carver.Boerne, Abraham);
   modify_field(Carver.Miltona, Tolleson);
   modify_field(Carver.WindGap, 1);

   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}

action Danbury() {
   Dellslow();
}

action Crary(Level) {
   modify_field(Carver.Amenia, 1);
   modify_field(Carver.Dyess, Level);
}

action Grinnell() {
   modify_field( Carver.Amenia, 1 );
   modify_field( Carver.Dyess, 9 );
}

table Diomede {
   reads {
      Clarion.Muenster : exact;
   }

   actions {
      Grovetown;
      Danbury;
      Crary;
   }
   size : Colmar;
}

control Paragould {
   if ( Deeth.Knolls == 0 and Rillton.Dizney == 1 ) {
      if ( ( Rillton.Hilburn == 1 ) and ( Deeth.Caulfield == 1 ) ) {
         apply( DeLancey ) {
            Scherr {
               apply( Emida ) {
                  Villas {
                     apply( Noyack );
                  }
                  Scherr {
                     apply( Buncombe );
                  }
               }
            }
         }
      } else if ( ( Rillton.Ledford == 1 ) and ( Deeth.Rosario == 1 ) ) {
         apply( Statham ) {
            Scherr {
               apply( ElPortal ) {
                  Clementon {
                     apply( Houston );
                  }
                  Scherr {

                     apply( Earlimart ) {
                        Kahaluu {
                           apply( Youngtown );
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Remsen {
   if( Clarion.Muenster != 0 ) {
      apply( Diomede );
   }
}

action Maydelle( Kinsley ) {
   modify_field( Clarion.Cordell, Kinsley );
}

field_list Sudden {
   Lakin.Bluewater;
}

field_list_calculation Kittredge {
    input {
        Sudden;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Wallace {
   selection_key : Kittredge;
   selection_mode : resilient;
}

action_profile Basalt {
   actions {
      DelRey;
   }
   size : Weslaco;
   dynamic_action_selection : Wallace;
}

table Millstone {
   reads {
      Clarion.Cordell : exact;
   }
   action_profile : Basalt;
   size : Wapato;
}

control Newfield {
   if ( Clarion.Cordell != 0 ) {
      apply( Millstone );
   }
}



field_list Orrum {
   Lakin.Bammel;
}

field_list_calculation Parshall {
    input {
        Orrum;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Montour {
    selection_key : Parshall;
    selection_mode : resilient;
}

action Chewalla(Kirwin) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Kirwin);
}

action_profile Taconite {
    actions {
        Chewalla;
        Scherr;
    }
    size : Anthon;
    dynamic_action_selection : Montour;
}

table Brave {
   reads {
      Carver.WestPike : exact;
   }
   action_profile: Taconite;
   size : Ulysses;
}

control Goulding {
   if ((Carver.WestPike & 0x2000) == 0x2000) {
      apply(Brave);
   }
}



action Kerrville() {
   modify_field(Carver.Boerne, Deeth.Cochrane);
   modify_field(Carver.Miltona, Deeth.Swenson);
   modify_field(Carver.Blanding, Deeth.Angwin);
   modify_field(Carver.MillCity, Deeth.Wondervu);
   modify_field(Carver.Suarez, Deeth.Catlin);
}

table Kendrick {
   actions {
      Kerrville;
   }
   default_action : Kerrville();
   size : 1;
}

control Allen {
   if (Deeth.Catlin!=0 ) {
      apply( Kendrick );
   }
}

action Dozier() {
   modify_field(Carver.Lisle, 1);
   modify_field(Carver.Kenova, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Deeth.LaCueva);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Carver.Suarez);
}

action BirchBay() {
}



@pragma ways 1
table Quealy {
   reads {
      Carver.Boerne : exact;
      Carver.Miltona : exact;
   }
   actions {
      Dozier;
      BirchBay;
   }
   default_action : BirchBay;
   size : 1;
}

action Gillespie() {
   modify_field(Carver.Sammamish, 1);
   modify_field(Carver.Stone, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Carver.Suarez, Netcong);
}

table Newpoint {
   actions {
      Gillespie;
   }
   default_action : Gillespie;
   size : 1;
}

action Standish() {
   modify_field(Carver.Myton, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Carver.Suarez);
}

table Ketchum {
   actions {
      Standish;
   }
   default_action : Standish();
   size : 1;
}

action Denmark(FlyingH) {
   modify_field(Carver.Overton, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, FlyingH);
   modify_field(Carver.WestPike, FlyingH);
}

action Barnsdall(Terrell) {
   modify_field(Carver.Sammamish, 1);
   modify_field(Carver.Talco, Terrell);
}

action Eddington() {
}

table Westville {
   reads {
      Carver.Boerne : exact;
      Carver.Miltona : exact;
      Carver.Suarez : exact;
   }

   actions {
      Denmark;
      Barnsdall;
      Eddington;
   }
   default_action : Eddington();
   size : Strasburg;
}

control Fowler {
   if (Deeth.Knolls == 0 and not valid(Toano) ) {
      apply(Westville) {
         Eddington {
            apply(Quealy) {
               BirchBay {
                  if ((Carver.Boerne & 0x010000) == 0x010000) {
                     apply(Newpoint);
                  } else {
                     apply(Ketchum);
                  }
               }
            }
         }
      }
   }
}

action SanPablo() {
   modify_field(Deeth.Cabery, 1);
   Dellslow();
}

table Mertens {
   actions {
      SanPablo;
   }
   default_action : SanPablo;
   size : 1;
}

control Amonate {
   if (Deeth.Knolls == 0) {
      if ((Carver.WindGap==0) and (Deeth.Leland==0) and (Deeth.Thawville==0) and (Deeth.Seagrove==Carver.WestPike)) {
         apply(Mertens);
      }
   }
}

action Sawpit(Saltdale) {
    modify_field(ig_intr_md_for_tm.level2_exclusion_id, Saltdale);
}

table Orrstown {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Sawpit;
    }
    size : 512;
}

control Valier {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Orrstown);
   }
}



action Mumford( Donna ) {
   modify_field( Carver.Iroquois, Donna );
}

action Elmore() {
   modify_field( Carver.Iroquois, Carver.Suarez );
}

table Godley {
   reads {
      eg_intr_md.egress_port : exact;
      Carver.Suarez : exact;
   }

   actions {
      Mumford;
      Elmore;
   }
   default_action : Elmore;
   size : Sonoita;
}

control Monrovia {
   apply( Godley );
}



action Kerby( Idylside, Rhine ) {
   modify_field( Carver.Wellton, Idylside );
   modify_field( Carver.Rehobeth, Rhine );
}

action BlackOak( Meservey, Wailuku, Laketown, Duelm ) {
   modify_field( Carver.Wellton, Meservey );
   modify_field( Carver.Rehobeth, Wailuku );
   modify_field( Carver.Ethete, Laketown );
   modify_field( Carver.HydePark, Duelm );
}


table Hester {
   reads {
      Carver.Perrytown : exact;
   }

   actions {
      Kerby;
      BlackOak;
   }
   size : Parmele;
}

action Barclay(Tillamook, Shine, Ranburne, Unity) {
   modify_field( Carver.Wakeman, Tillamook );
   modify_field( Carver.Peebles, Shine );
   modify_field( Carver.Belvidere, Ranburne );
   modify_field( Carver.Venice, Unity );
}

table Ludowici {
   reads {
        Carver.Dunken : exact;
   }
   actions {
      Barclay;
   }
   size : Abernant;
}

action Greenhorn() {
   no_op();
}

action Safford() {
   modify_field( Filley.Tingley, Dougherty[0].Neubert );
   remove_header( Dougherty[0] );
}

table Moseley {
   actions {
      Safford;
   }
   default_action : Safford;
   size : Woodfords;
}

action Kamas() {
   no_op();
}

action Fonda() {
   add_header( Dougherty[ 0 ] );
   modify_field( Dougherty[0].Yakima, Carver.Iroquois );
   modify_field( Dougherty[0].Neubert, Filley.Tingley );
   modify_field( Dougherty[0].Salduro, Redmon.Hamburg );
   modify_field( Dougherty[0].Sieper, Redmon.Frontenac );
   modify_field( Filley.Tingley, Magness );
}



table Humarock {
   reads {
      Carver.Iroquois : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Kamas;
      Fonda;
   }
   default_action : Fonda;
   size : Willey;
}

action Moweaqua() {
   modify_field(Filley.CassCity, Carver.Boerne);
   modify_field(Filley.LaMoille, Carver.Miltona);
   modify_field(Filley.Husum, Carver.Wellton);
   modify_field(Filley.Kinard, Carver.Rehobeth);
}

action Flourtown() {
   Moweaqua();
   add_to_field(Uniopolis.Lindsborg, -1);
   modify_field(Uniopolis.Titonka, Redmon.Telida);
}

action Heeia() {
   Moweaqua();
   add_to_field(Bairoil.Yaurel, -1);
   modify_field(Bairoil.Maben, Redmon.Telida);
}

action Chubbuck() {
   modify_field(Uniopolis.Titonka, Redmon.Telida);
}

action Biehle() {
   modify_field(Bairoil.Maben, Redmon.Telida);
}

action Whitman() {
   Fonda();
}

action Atoka() {
   add_header( RiceLake );
   modify_field( RiceLake.CassCity, Carver.Wellton );
   modify_field( RiceLake.LaMoille, Carver.Rehobeth );
   modify_field( RiceLake.Husum, Carver.Ethete );
   modify_field( RiceLake.Kinard, Carver.HydePark );
   modify_field( RiceLake.Tingley, Vieques );
   add_header( Toano );
   modify_field( Toano.Telegraph, Carver.Wakeman );
   modify_field( Toano.Anchorage, Carver.Peebles );
   modify_field( Toano.Clearmont, Carver.Belvidere );
   modify_field( Toano.Alvord, Carver.Venice );
   modify_field( Toano.Kasigluk, Carver.Dyess );
}

action Baytown() {
   remove_header( Inverness );
   remove_header( Makawao );
   remove_header( Jerico );
   copy_header( Filley, Trooper );
   remove_header( Trooper );
   remove_header( Uniopolis );
}

action Grayland() {
   remove_header( RiceLake );
   remove_header( Toano );
}

action Norfork() {
   Baytown();
   modify_field(Longford.Titonka, Redmon.Telida);
}

action Roseville() {
   Baytown();
   modify_field(Joslin.Maben, Redmon.Telida);
}

table Yorkshire {
   reads {
      Carver.Botna : exact;
      Carver.Perrytown : exact;
      Carver.WindGap : exact;
      Uniopolis.valid : ternary;
      Bairoil.valid : ternary;
      Longford.valid : ternary;
      Joslin.valid : ternary;
   }

   actions {
      Flourtown;
      Heeia;
      Chubbuck;
      Biehle;
      Whitman;
      Atoka;
      Grayland;
      Baytown;
      Norfork;
      Roseville;
   }
   size : Roachdale;
}

control Parkville {
   apply( Moseley );
}

control OldMinto {
   apply( Humarock );
}

control Sabula {
   apply( Hester );
   apply( Ludowici );
   apply( Yorkshire );
}



field_list Lacombe {
    Terral.Sagerton;
    Deeth.Catlin;
    Trooper.Husum;
    Trooper.Kinard;
    Uniopolis.Sedan;
}

action Linville() {
   generate_digest(ElPrado, Lacombe);
}

table Welcome {
   actions {
      Linville;
   }

   default_action : Linville;
   size : 1;
}

control Cushing {
   if (Deeth.Sardinia == 1) {
      apply(Welcome);
   }
}



action Billings( Harpster ) {
   modify_field( Redmon.Lehigh, Harpster );
}

action Falmouth() {
   modify_field( Redmon.Lehigh, 0 );
}

table Frewsburg {
   reads {
     Deeth.Seagrove : ternary;
     Deeth.Corbin : ternary;
     Rillton.Dizney : ternary;
   }

   actions {
     Billings;
     Falmouth;
   }

   default_action : Falmouth();
   size : Glenshaw;
}

action Larue( Hampton ) {
   modify_field( Redmon.Hayward, Hampton );
   modify_field( Redmon.Whitlash, 0 );
   modify_field( Redmon.Onava, 0 );
}

action Nunda( Kinter, Arnett ) {
   modify_field( Redmon.Hayward, 0 );
   modify_field( Redmon.Whitlash, Kinter );
   modify_field( Redmon.Onava, Arnett );
}

action Cacao( Kansas, Poneto, Ladelle ) {
   modify_field( Redmon.Hayward, Kansas );
   modify_field( Redmon.Whitlash, Poneto );
   modify_field( Redmon.Onava, Ladelle );
}

action Pendleton() {
   modify_field( Redmon.Hayward, 0 );
   modify_field( Redmon.Whitlash, 0 );
   modify_field( Redmon.Onava, 0 );
}

table Rixford {
   reads {
     Redmon.Lehigh : exact;
     Deeth.Cochrane : ternary;
     Deeth.Swenson : ternary;
     Deeth.Barksdale : ternary;
   }

   actions {
     Larue;
     Nunda;
     Cacao;
     Pendleton;
   }

   default_action : Pendleton();
   size : ShadeGap;
}

table Dolliver {
   reads {
     Redmon.Lehigh : exact;
     Holliday.Huttig mask 0xffff0000 : ternary;
     Deeth.Elderon : ternary;
     Deeth.Dutton : ternary;
     Redmon.Telida : ternary;
     Clarion.Muenster : ternary;

   }

   actions {
     Larue;
     Nunda;
     Cacao;
     Pendleton;
   }

   default_action : Pendleton();
   size : Newhalen;
}

table Darien {
   reads {
     Redmon.Lehigh : exact;
     Terrytown.Clearlake mask 0xffff0000 : ternary;
     Deeth.Elderon : ternary;
     Deeth.Dutton : ternary;
     Redmon.Telida : ternary;
     Clarion.Muenster : ternary;

   }

   actions {
     Larue;
     Nunda;
     Cacao;
     Pendleton;
   }

   default_action : Pendleton();
   size : Daisytown;
}

meter RioLinda {
   type : packets;
   static : VanWert;
   instance_count: RushCity;
}

action Garibaldi( Doddridge ) {
   // Unsupported addressing mode
   //execute_meter( RioLinda, Doddridge, ig_intr_md_for_tm.packet_color );
}

action Pilger() {
   execute_meter( RioLinda, Redmon.Whitlash, ig_intr_md_for_tm.packet_color );
}

table VanWert {
   reads {
     Redmon.Whitlash : ternary;
     Deeth.Seagrove : ternary;
     Deeth.Corbin : ternary;
     Rillton.Dizney : ternary;
     Redmon.Onava : ternary;
   }
   actions {
      Garibaldi;
      Pilger;
   }
   size : Clyde;
}

control Joiner {
   apply( Frewsburg );
}

control Comal {
   if( Deeth.Caulfield == 1 ) {
      apply( Dolliver );
   } else if ( Deeth.Rosario == 1 ) {
      apply( Darien );
   } else {
      apply( Rixford );
   }
}

control Woolsey {
   if( Deeth.Knolls == 0 ) {
      apply( VanWert );
   }
}



action Nevis() {
   modify_field( Redmon.Hamburg, Weinert.Wanatah );
}



action Visalia() {
   modify_field( Redmon.Hamburg, Dougherty[0].Salduro );
}

action Goldsboro() {
   modify_field( Redmon.Telida, Weinert.Kupreanof );
}

action Ruthsburg() {
   modify_field( Redmon.Telida, Holliday.RockHall );
}

action Attica() {
   modify_field( Redmon.Telida, Terrytown.Fergus );
}

action Glenmora( Comunas, Amity ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Comunas );
   modify_field( ig_intr_md_for_tm.qid, Amity );
}

table Yreka {
   reads {
     Deeth.Kentwood : exact;
   }

   actions {
     Nevis;
     Visalia;
   }

   size : Chehalis;
}

table Earlham {
   reads {
     Deeth.Caulfield : exact;
     Deeth.Rosario : exact;
   }

   actions {
     Goldsboro;
     Ruthsburg;
     Attica;
   }

   size : LeeCity;
}

table Leetsdale {
   reads {
      Weinert.ElmGrove : ternary;
      Weinert.Wanatah : ternary;
      Redmon.Hamburg : ternary;
      Redmon.Telida : ternary;
      Redmon.Hayward : ternary;
   }

   actions {
      Glenmora;
   }

   size : Naubinway;
}

action Seattle( Mission, Normangee ) {
   bit_or( Redmon.Germano, Redmon.Germano, Mission );
   bit_or( Redmon.Fredonia, Redmon.Fredonia, Normangee );
}

table Grampian {
   actions {
      Seattle;
   }
   default_action : Seattle;
   size : Casselman;
}

action Coyote( Shopville ) {
   modify_field( Redmon.Telida, Shopville );
}

action Ringold( Kensett ) {
   modify_field( Redmon.Hamburg, Kensett );
}

action Segundo( Dobbins, DeKalb ) {
   modify_field( Redmon.Hamburg, Dobbins );
   modify_field( Redmon.Telida, DeKalb );
}

table Cowley {
   reads {
      Weinert.ElmGrove : exact;
      Redmon.Germano : exact;
      Redmon.Fredonia : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }

   actions {
      Coyote;
      Ringold;
      Segundo;
   }

   size : Micco;
}

control Swansea {
   apply( Yreka );
   apply( Earlham );
}

control WyeMills {
   apply( Leetsdale );
}

control Tunis {
   apply( Grampian );
   apply( Cowley );
}



action Gunter( Gwynn ) {
   modify_field( Carver.Perrytown, Montbrook );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Gwynn );
}

action Ovett( Gagetown ) {
   modify_field( Carver.Perrytown, Holcut );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Gagetown );
   modify_field( Carver.Dunken, ig_intr_md.ingress_port );
}

table Gonzales {
   reads {
      Rillton.Dizney : exact;
      Weinert.Bowlus : ternary;
      Carver.Dyess : ternary;
   }

   actions {
      Gunter;
      Ovett;
   }

   size : MoonRun;
}

control Depew {
   apply( Gonzales );
}





counter FlatLick {
   type : packets_and_bytes;
   direct : Lapoint;
   min_width: 32;
}

table Lapoint {
   reads {
      eg_intr_md.egress_port mask 0x7f : exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }

   actions {
      Gilman;
   }

   size : Lantana;
}

control Capitola {
   apply( Lapoint );
}



action Hiseville()
{



   Dellslow();
}

action Manasquan()
{
   modify_field(Carver.Botna, BigPoint);
   bit_or(Carver.WestPike, 0x2000, Toano.Alvord);
}

action NorthRim( Joice ) {
   modify_field(Carver.Botna, BigPoint);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Joice);
   modify_field(Carver.WestPike, Joice);
}

table Alzada {
   reads {
      Toano.Telegraph : exact;
      Toano.Anchorage : exact;
      Toano.Clearmont : exact;
      Toano.Alvord : exact;
   }

   actions {
      Manasquan;
      NorthRim;
      Hiseville;
   }
   default_action : Hiseville();
   size : Abernant;
}

control Flaherty {
   apply( Alzada );
}



#define EastLake   0
#define RowanBay  1
#define Amalga     2

action Gahanna(Homeland) {
    modify_field(Deeth.Catarina, Homeland);
}


@pragma ternary 1
table Slade {
   reads {
      Weinert.Flats : exact;
   }
   actions {
      Gahanna;
   }
   size : Pearcy;
}

control Gosnell {
   apply(Slade);
}

action Minneota(Kempton) {
   modify_field(Deeth.Hildale, Kempton);
}

action Mapleview() {
   modify_field(Deeth.Hildale, 1);
}

table Baskin {
   reads {
      Weinert.Flats : ternary;
      Holliday.Philippi : ternary;
      Holliday.Huttig : ternary;
      Jerico.Hopland : ternary;
      Jerico.Bonney : ternary;
   }
   actions {
      Minneota;
      Mapleview;
   }
   default_action : Mapleview();
   size : Rotonda;
}

table Oakton {
   reads {
      Weinert.Flats : ternary;
      Terrytown.Kennebec : ternary;
      Terrytown.Clearlake : ternary;
      Jerico.Hopland : ternary;
      Jerico.Bonney : ternary;
   }
   actions {
      Minneota;
      Mapleview;
   }
   default_action : Mapleview();
   size : Cairo;
}

control Silesia {
   if (Deeth.Catarina != 0) {
      if (Deeth.Caulfield == 1) {
         apply(Baskin);
      } else if (Deeth.Rosario == 1) {
         apply(Oakton);
      }
   }
}

meter Tatum {
   type : bytes;
   direct : Slade;
   result : Deeth.Alamota;
}

action Suffern() {
   clone_ingress_pkt_to_egress(Deeth.Catarina);
}

table Arcanum {
   reads {
      Deeth.Hildale : exact;
      Deeth.Alamota : exact;
   }
   actions {
      Suffern;
   }
   size : Lumpkin;
}

control Missoula {
   if (Deeth.Catarina != 0) {
      apply(Arcanum);
   }
}

action SandLake(Natalia) {
    modify_field(Carver.Maljamar, Natalia);
}

table Skiatook {
   reads {
      Carver.WestPike : exact;
   }
   actions {
      SandLake;
   }
   size : Pearcy;
}

control Grapevine {
   apply(Skiatook);
}

#if 0
meter Cricket {
   type : bytes;
   direct : Skiatook;
   Bangor : Carver.Telephone;
}

action Richlawn() {
   Secaucus(Carver.Maljamar);
}

table Hemlock {
   reads {
      Carver.Telephone : exact;
   }
   actions {
      Richlawn;
   }
   size : Lumpkin;
}

control Anson {
   if (Carver.Maljamar != 0) {
      apply(Hemlock);
   }
}
#endif


control ingress {

   PineLawn();

   if( Weinert.Issaquah != 0 ) {

      Airmont();
   }

   Enderlin();

   if( Weinert.Issaquah != 0 ) {
      Oakford();


      Eckman();
      Swansea();
   }

   Slinger();

   Gosnell();


   Jamesburg();
   Gowanda();

   if( Weinert.Issaquah != 0 ) {

      Paragould();
   }


   Biddle();

   Silesia();


   if( Weinert.Issaquah != 0 ) {
      Newfield();
   }

   Allen();


   Joiner();
   if( Weinert.Issaquah != 0 ) {
      Remsen();
   }




   Cushing();
   Cedaredge();
   Comal();
   if( Carver.Amenia == 0 ) {
      Fowler();
   }


   WyeMills();
   if( Carver.Amenia == 0 ) {
      if( not valid(Toano) ) {
         Amonate();
      } else {
         Flaherty();
      }
   } else {
      Depew();
   }

   if( Weinert.Issaquah != 0 ) {
      Tunis();
   }


   Woolsey();
   Goulding();


   if( valid( Dougherty[0] ) ) {
      Parkville();
   }

   if( Carver.Amenia == 0 ) {
      Valier();
   }
   Missoula();
}

control egress {
   Monrovia();
   Sabula();

   if( ( Carver.Amenia == 0 ) and ( Carver.Botna != BigPoint ) ) {
      OldMinto();
   }
   Grapevine();
   Capitola();
}
