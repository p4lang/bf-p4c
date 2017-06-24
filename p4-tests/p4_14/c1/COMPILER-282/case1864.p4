// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 30943







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
#else





header_type Burrel {
	fields {
		Buckeye : 3;
	}
}
metadata Burrel Comal;

header_type Enhaut {
	fields {
		Cadley : 1;
		Lewiston : 9;
		Peebles : 48;
		Tehachapi : 32;
	}
}
metadata Enhaut Tarlton;

header_type Wabbaseka {
	fields {
		Collis : 9;
		Ludden : 3;
		Platea : 16;
		Newborn : 16;
		Glentana : 13;
		Otsego : 13;
		Licking : 16;
		Glendevey : 9;
		Demarest : 16;
		Paradis : 1;
		Nashoba : 3;
		Grandy : 5;
		Glenside : 2;
	}
}

metadata Wabbaseka Mackville;

header_type Wrenshall {
	fields {
		Cedaredge : 9;
		Brookston : 19;
		Floyd : 2;
		Pinebluff : 32;
		Equality : 19;
		Tilton : 2;
		Seguin : 8;
		Fouke : 32;
		Dryden : 16;
		Harlem : 1;
		Moosic : 5;
		Kahului : 3;
		McCartys : 1;
	}
}

metadata Wrenshall Hollyhill;




action ElJebel(Samson) {
    modify_field(Belcher, Samson);
}

#ifdef BMV2
#define Newtok     Musella
#else
#define Newtok         Sunrise
#endif

header_type CedarKey {
	fields {
		Philip : 8;
		Billings : 48;
	}
}
metadata CedarKey Stidham;

#define Madill 0
#define Beeler 1
#define Algodones 2
#define Sparland 3
#define Shobonier 4
#define DelRey 5
#define Champlin 6


#define Gillespie \
    ((Berea != Madill) and \
     (Berea != DelRey))
#define Stilwell \
    ((Berea == Madill) or \
     (Berea == DelRey))
#define Higgins \
    (Berea == Beeler)
#define Earlsboro \
    (Berea == Algodones)
#endif



#ifndef Realitos
#define Realitos

header_type Walnut {
	fields {
		Allegan : 16;
		Baxter : 16;
		Bemis : 8;
		Luning : 8;
		Rembrandt : 8;
		Rockville : 8;
		Campo : 1;
		Ojibwa : 1;
		Fiskdale : 1;
		Greenbelt : 1;
		Montello : 1;
		Flats : 3;
	}
}

header_type Whiteclay {
	fields {
		Naalehu : 24;
		Adair : 24;
		Waialee : 24;
		Lattimore : 24;
		Choudrant : 16;
		Gunter : 16;
		Champlain : 16;
		Kingsland : 16;
		Jones : 16;
		Loris : 8;
		Terral : 8;
		Quinwood : 6;
		Windber : 1;
		Fittstown : 1;
		Timnath : 12;
		Goodlett : 2;
		Sonestown : 1;
		Goulds : 1;
		Filley : 1;
		Saugatuck : 1;
		Newland : 1;
		Palomas : 1;
		Lumpkin : 1;
		Nahunta : 1;
		Louviers : 1;
		Campbell : 1;
		Clearmont : 1;
		Lamboglia : 1;
		DuckHill : 3;
	}
}

header_type Bloomburg {
	fields {
		Storden : 24;
		Osage : 24;
		Oxford : 24;
		Roachdale : 24;
		Tombstone : 24;
		Northway : 24;
		SanRemo : 16;
		Everton : 16;
		Unionvale : 16;
		Kensett : 12;
		Woodrow : 3;
		Elwyn : 3;
		Herring : 1;
		Ackley : 1;
		LakePine : 1;
		Ashtola : 1;
		Munday : 1;
		DeSmet : 1;
		RedBay : 1;
		Hookdale : 1;
		SeaCliff : 8;
		Affton : 3;
		Laton : 6;
		Wegdahl : 6;
	}
}


header_type Eckman {
	fields {
		Littleton : 8;
		Lewistown : 1;
		Hebbville : 1;
		Yatesboro : 1;
		Elsey : 1;
		Siloam : 1;
	}
}

header_type Fentress {
	fields {
		Perryton : 32;
		Domestic : 32;
		Granville : 6;
		Knoke : 16;
	}
}

header_type Stobo {
	fields {
		Calcium : 128;
		EastDuke : 128;
		Glenpool : 20;
		Oklahoma : 8;
		Newhalem : 11;
		Anvik : 8;
		Hughson : 13;
	}
}

header_type Welcome {
	fields {
		PineHill : 14;
		Monahans : 1;
		Toccopola : 1;
		Emblem : 12;
		BigLake : 1;
		Shasta : 6;
		Portville : 2;
		Kaupo : 6;
		Libby : 3;
		Puyallup : 1;
		Blitchton : 1;
	}
}

header_type Barnhill {
	fields {
		Ivanhoe : 1;
		Wanatah : 1;
	}
}

header_type Mather {
	fields {
		Ferrum : 8;
	}
}

header_type Pathfork {
	fields {
		Fergus : 16;
	}
}

header_type Trion {
	fields {
		Patchogue : 32;
		Swansboro : 32;
		Grantfork : 32;
	}
}

header_type TroutRun {
	fields {
		Amenia : 32;
		Munger : 32;
	}
}

#endif



#ifndef Tallassee
#define Tallassee



header_type Mentone {
	fields {
		Homeland : 24;
		Gurdon : 24;
		Aynor : 24;
		Portales : 24;
		Hannibal : 16;
	}
}



header_type Wilbraham {
	fields {
		Ozark : 3;
		Moreland : 1;
		Ivins : 12;
		Meservey : 16;
	}
}



header_type Pricedale {
	fields {
		Honokahua : 4;
		Sabula : 4;
		Plano : 6;
		Dilia : 2;
		Murchison : 16;
		Shickley : 16;
		Clarkdale : 3;
		Ivanpah : 13;
		Chitina : 8;
		Irondale : 8;
		Weches : 16;
		Rudolph : 32;
		Bosler : 32;
	}
}

header_type Rocklin {
	fields {
		Welch : 4;
		LaPryor : 6;
		Piketon : 2;
		RushCity : 20;
		Harris : 16;
		Gasport : 8;
		Switzer : 8;
		Hephzibah : 128;
		Redvale : 128;
	}
}




header_type Bardwell {
	fields {
		Prunedale : 8;
		Delcambre : 8;
		Steprock : 16;
	}
}

header_type Bagdad {
	fields {
		Nanson : 16;
		Portis : 16;
		Statham : 32;
		Claiborne : 32;
		Bellville : 4;
		Bushland : 4;
		Nightmute : 8;
		Corfu : 16;
		Rehobeth : 16;
		Potosi : 16;
	}
}

header_type Amboy {
	fields {
		Hiland : 16;
		Lamar : 16;
		Renton : 16;
		Dairyland : 16;
	}
}



header_type Brookland {
	fields {
		Vinemont : 16;
		Basalt : 16;
		Barnard : 8;
		Swaledale : 8;
		Emsworth : 16;
	}
}

header_type Teaneck {
	fields {
		Hauppauge : 48;
		Linville : 32;
		Gambrill : 48;
		Dacono : 32;
	}
}



header_type Negra {
	fields {
		Melrose : 1;
		CoalCity : 1;
		IdaGrove : 1;
		Oldsmar : 1;
		Bowden : 1;
		Sargent : 3;
		Chamois : 5;
		Ankeny : 3;
		Barrow : 16;
	}
}

header_type Faysville {
	fields {
		McFaddin : 24;
		Baltic : 8;
	}
}



header_type Crown {
	fields {
		Donnelly : 8;
		Hatteras : 24;
		Boonsboro : 24;
		Gorum : 8;
	}
}

#endif



#ifndef Claypool
#define Claypool

parser start {
   return Tillson;
}

#define Nuevo        0x8100
#define Baird        0x0800
#define PellLake        0x86dd
#define Lyndell        0x9100
#define Whatley        0x8847
#define Leawood         0x0806
#define Henrietta        0x8035
#define Currie        0x88cc
#define Norias        0x8809

#define Separ              1
#define Moody              2
#define Bevier              4
#define LunaPier               6
#define Midas               17
#define Crumstown                47

#define Stryker         0x501
#define Madeira          0x506
#define Longmont          0x511
#define RoseBud          0x52F


#define LaJara                 4789



#define Caplis               0
#define Timken              1
#define Sunbury                2



#define Meyers          0
#define Bowers          4095
#define Hanapepe  4096
#define Orrville  8191



#define Moraine                      0
#define Ocilla                  0
#define Leadpoint                 1

header Mentone Saranap;
header Mentone Wyatte;
header Wilbraham LaMarque[ 2 ];
header Pricedale Uhland;
header Pricedale Spiro;
header Rocklin Ralph;
header Rocklin Maloy;
header Bagdad Aldrich;
header Amboy Clauene;
header Bagdad Wyndmoor;
header Amboy VanHorn;
header Crown Hobart;
header Brookland Dandridge;
header Negra Rockdale;

parser Tillson {
   extract( Saranap );
   return select( Saranap.Hannibal ) {
      Nuevo : Kremlin;
      Baird : Russia;
      PellLake : Hillside;
      Leawood  : Fishers;
      default        : ingress;
   }
}

parser Kremlin {
   extract( LaMarque[0] );


   set_metadata(Angwin.Montello, 1);
   return select( LaMarque[0].Meservey ) {
      Baird : Russia;
      PellLake : Hillside;
      Leawood  : Fishers;
      default : ingress;
   }
}

parser Russia {
   extract( Uhland );
   set_metadata(Angwin.Bemis, Uhland.Irondale);
   set_metadata(Angwin.Rembrandt, Uhland.Chitina);
   set_metadata(Angwin.Allegan, Uhland.Murchison);
   set_metadata(Angwin.Fiskdale, 0);
   set_metadata(Angwin.Campo, 1);
   return select(Uhland.Ivanpah, Uhland.Sabula, Uhland.Irondale) {
      Longmont : Clearco;
      default : ingress;
   }
}

parser Hillside {
   extract( Maloy );
   set_metadata(Angwin.Bemis, Maloy.Gasport);
   set_metadata(Angwin.Rembrandt, Maloy.Switzer);
   set_metadata(Angwin.Allegan, Maloy.Harris);
   set_metadata(Angwin.Fiskdale, 1);
   set_metadata(Angwin.Campo, 0);
   return ingress;
}

parser Fishers {
   extract( Dandridge );
   return ingress;
}

parser Clearco {
   extract(Clauene);
   return select(Clauene.Lamar) {
      LaJara : Hiwassee;
      default : ingress;
    }
}

parser Weimar {
   set_metadata(Neshoba.Goodlett, Sunbury);
   return Lesley;
}

parser Arminto {
   set_metadata(Neshoba.Goodlett, Sunbury);
   return Carnero;
}

parser Casselman {
   extract(Rockdale);
   return select(Rockdale.Melrose, Rockdale.CoalCity, Rockdale.IdaGrove, Rockdale.Oldsmar, Rockdale.Bowden,
             Rockdale.Sargent, Rockdale.Chamois, Rockdale.Ankeny, Rockdale.Barrow) {
      Baird : Weimar;
      PellLake : Arminto;
      default : ingress;
   }
}

parser Hiwassee {
   extract(Hobart);
   set_metadata(Neshoba.Goodlett, Timken);
   return Germano;
}

parser Lesley {
   extract( Spiro );
   set_metadata(Angwin.Luning, Spiro.Irondale);
   set_metadata(Angwin.Rockville, Spiro.Chitina);
   set_metadata(Angwin.Baxter, Spiro.Murchison);
   set_metadata(Angwin.Greenbelt, 0);
   set_metadata(Angwin.Ojibwa, 1);
   return ingress;
}

parser Carnero {
   extract( Ralph );
   set_metadata(Angwin.Luning, Ralph.Gasport);
   set_metadata(Angwin.Rockville, Ralph.Switzer);
   set_metadata(Angwin.Baxter, Ralph.Harris);
   set_metadata(Angwin.Greenbelt, 1);
   set_metadata(Angwin.Ojibwa, 0);
   return ingress;
}

parser Germano {
   extract( Wyatte );
   return select( Wyatte.Hannibal ) {
      Baird: Lesley;
      PellLake: Carnero;
      default: ingress;
   }
}
#endif

@pragma pa_no_pack ingress Fosston.Monahans Neshoba.Fittstown
@pragma pa_no_pack ingress Fosston.Monahans Angwin.Ojibwa
@pragma pa_no_pack ingress Fosston.Monahans Angwin.Campo

@pragma pa_no_pack ingress Fosston.BigLake Neshoba.Fittstown
@pragma pa_no_pack ingress Fosston.BigLake Angwin.Ojibwa
@pragma pa_no_pack ingress Fosston.BigLake Angwin.Campo

@pragma pa_no_pack ingress Fosston.Portville Dabney.Hughson
@pragma pa_no_pack ingress Fosston.Puyallup Dabney.Hughson
@pragma pa_no_pack ingress Fosston.Portville Dabney.Newhalem
@pragma pa_no_pack ingress Fosston.Puyallup Dabney.Newhalem

@pragma pa_no_pack ingress Fosston.Toccopola Calabasas.Affton
@pragma pa_no_pack ingress Fosston.Toccopola Neshoba.Fittstown
@pragma pa_no_pack ingress Fosston.Toccopola Angwin.Ojibwa
@pragma pa_no_pack ingress Fosston.Toccopola Angwin.Campo
@pragma pa_no_pack ingress Fosston.Toccopola Neshoba.Sonestown

@pragma pa_no_pack ingress Fosston.Libby Neshoba.DuckHill
@pragma pa_no_pack ingress Fosston.Libby Angwin.Flats
@pragma pa_no_pack ingress Fosston.Libby Neshoba.Saugatuck
@pragma pa_no_pack ingress Fosston.Shasta Neshoba.DuckHill
@pragma pa_no_pack ingress Fosston.Shasta Angwin.Flats
@pragma pa_no_pack ingress Fosston.Shasta Neshoba.Saugatuck

@pragma pa_no_pack ingress Fosston.Portville Neshoba.DuckHill
@pragma pa_no_pack ingress Fosston.Portville Angwin.Flats

@pragma pa_no_pack ingress Fosston.Puyallup Neshoba.Goulds
@pragma pa_no_pack ingress Fosston.Puyallup Neshoba.DuckHill
@pragma pa_no_pack ingress Fosston.Puyallup Angwin.Flats

@pragma pa_no_pack ingress Fosston.Blitchton Calabasas.Affton
@pragma pa_no_pack ingress Fosston.Blitchton Neshoba.Fittstown
@pragma pa_no_pack ingress Fosston.Blitchton Angwin.Ojibwa
@pragma pa_no_pack ingress Fosston.Blitchton Angwin.Campo
@pragma pa_no_pack ingress Fosston.Blitchton Kerrville.Wanatah

metadata Whiteclay Neshoba;
metadata Bloomburg Calabasas;
metadata Welcome Fosston;
metadata Walnut Angwin;
metadata Fentress Duelm;
metadata Stobo Dabney;
metadata Barnhill Kerrville;
metadata Eckman Sunset;
metadata Mather Candor;
metadata Pathfork McGrady;
metadata TroutRun ElPrado;
metadata Trion Ravena;













#undef KeyWest

#undef Oshoto
#undef Sylva
#undef Hines
#undef Slocum
#undef Sammamish

#undef Biehle
#undef Lincroft
#undef Sonora

#undef Flourtown
#undef Dizney
#undef Marlton
#undef Mulliken
#undef Magna
#undef Sandstone
#undef Kinsley
#undef Davant
#undef Sparkill
#undef Palmdale
#undef Cornwall
#undef Trujillo
#undef Grottoes
#undef Croft
#undef Ranburne
#undef Twinsburg
#undef Franktown
#undef Uniontown

#undef Norma
#undef Parkland
#undef Grainola
#undef Dagmar
#undef Craig
#undef Redondo
#undef Noonan
#undef Waubun
#undef Taneytown
#undef Cotter
#undef Ladelle
#undef Lemhi
#undef Olene
#undef Milesburg
#undef Floris
#undef Edgemoor


#undef Montegut

#undef Flomot







#define KeyWest 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Oshoto      65536
#define Sylva      65536
#define Hines 512
#define Slocum 512
#define Sammamish      512


#define Biehle     1024
#define Lincroft    1024
#define Sonora     256


#define Flourtown 512
#define Dizney 65536
#define Marlton 65536
#define Mulliken   16384
#define Magna         131072
#define Sandstone 65536
#define Kinsley 1024
#define Davant 2048
#define Sparkill 16384
#define Palmdale 8192
#define Cornwall 65536
#define Trujillo 8192
#define Grottoes 2048
#define Croft 16384

#define Ranburne 0x0000000000000000FFFFFFFFFFFFFFFF


#define Twinsburg 0x000fffff

#define Franktown 0xFFFFFFFFFFFFFFFF0000000000000000

#define Uniontown 0x000007FFFFFFFFFF0000000000000000


#define Norma 1024
#define Parkland 4096
#define Grainola 4096
#define Dagmar 4096
#define Craig 4096
#define Redondo 1024
#define Noonan 4096
#define Taneytown 64
#define Cotter 1
#define Ladelle  8
#define Lemhi 512


#define Olene 1
#define Milesburg 3
#define Floris 80
#define Edgemoor 64


#define Montegut 0


#define Flomot    4096

#endif



#ifndef Naruna
#define Naruna

action Shauck() {
   no_op();
}

#endif

















action Ozona(Braselton, Burgin, Pridgen, MudButte, Dunnellon, McGonigle,
                 Lundell, Oregon, Remington, Nelagoney, Trilby) {
    modify_field(Fosston.PineHill, Braselton);
    modify_field(Fosston.Monahans, Burgin);
    modify_field(Fosston.Emblem, Pridgen);
    modify_field(Fosston.Toccopola, MudButte);
    modify_field(Fosston.BigLake, Dunnellon);
    modify_field(Fosston.Shasta, McGonigle);
    modify_field(Fosston.Portville, Lundell);
    modify_field(Fosston.Libby, Oregon);
    modify_field(Fosston.Kaupo, Remington);
    modify_field(Fosston.Puyallup, Nelagoney);
    modify_field(Fosston.Blitchton, Trilby);
}

@pragma command_line --no-dead-code-elimination
table Bells {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Ozona;
    }
    size : KeyWest;
}

control Mumford {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Bells);
    }
}





action Shelbina(Chatawa) {
   modify_field( Calabasas.Herring, 1 );
   modify_field( Calabasas.SeaCliff, Chatawa);
   modify_field( Neshoba.Louviers, 1 );
}

action Neches() {
   modify_field( Neshoba.Lumpkin, 1 );
   modify_field( Neshoba.Clearmont, 1 );
}

action Hooker() {
   modify_field( Neshoba.Louviers, 1 );
}

action Petroleum() {
   modify_field( Neshoba.Campbell, 1 );
}

action Barnwell() {
   modify_field( Neshoba.Clearmont, 1 );
}


table Altadena {
   reads {
      Saranap.Homeland : ternary;
      Saranap.Gurdon : ternary;
   }

   actions {
      Shelbina;
      Neches;
      Hooker;
      Petroleum;
      Barnwell;
   }
   default_action : Barnwell;
   size : Hines;
}

action Forman() {
   modify_field( Neshoba.Nahunta, 1 );
}


table Goodwin {
   reads {
      Saranap.Aynor : ternary;
      Saranap.Portales : ternary;
   }

   actions {
      Forman;
   }
   size : Slocum;
}


control Thayne {
   apply( Altadena );
   apply( Goodwin );
}




action Novinger() {
   modify_field( Duelm.Perryton, Spiro.Rudolph );
   modify_field( Duelm.Domestic, Spiro.Bosler );
   modify_field( Duelm.Granville, Spiro.Plano );
   modify_field( Dabney.Calcium, Ralph.Hephzibah );
   modify_field( Dabney.EastDuke, Ralph.Redvale );
   modify_field( Dabney.Glenpool, Ralph.RushCity );


   modify_field( Neshoba.Naalehu, Wyatte.Homeland );
   modify_field( Neshoba.Adair, Wyatte.Gurdon );
   modify_field( Neshoba.Waialee, Wyatte.Aynor );
   modify_field( Neshoba.Lattimore, Wyatte.Portales );
   modify_field( Neshoba.Choudrant, Wyatte.Hannibal );
   modify_field( Neshoba.Jones, Angwin.Baxter );
   modify_field( Neshoba.Loris, Angwin.Luning );
   modify_field( Neshoba.Terral, Angwin.Rockville );
   modify_field( Neshoba.Fittstown, Angwin.Ojibwa );
   modify_field( Neshoba.Windber, Angwin.Greenbelt );
   modify_field( Neshoba.Lamboglia, 0 );
   modify_field( Fosston.Portville, 2 );
   modify_field( Fosston.Libby, 0 );
   modify_field( Fosston.Kaupo, 0 );
   modify_field( Fosston.Puyallup, 1 );
}

action Pueblo() {
   modify_field( Neshoba.Goodlett, Caplis );
   modify_field( Duelm.Perryton, Uhland.Rudolph );
   modify_field( Duelm.Domestic, Uhland.Bosler );
   modify_field( Duelm.Granville, Uhland.Plano );
   modify_field( Dabney.Calcium, Maloy.Hephzibah );
   modify_field( Dabney.EastDuke, Maloy.Redvale );
   modify_field( Dabney.Glenpool, Maloy.RushCity );


   modify_field( Neshoba.Naalehu, Saranap.Homeland );
   modify_field( Neshoba.Adair, Saranap.Gurdon );
   modify_field( Neshoba.Waialee, Saranap.Aynor );
   modify_field( Neshoba.Lattimore, Saranap.Portales );
   modify_field( Neshoba.Choudrant, Saranap.Hannibal );
   modify_field( Neshoba.Jones, Angwin.Allegan );
   modify_field( Neshoba.Loris, Angwin.Bemis );
   modify_field( Neshoba.Terral, Angwin.Rembrandt );
   modify_field( Neshoba.Fittstown, Angwin.Campo );
   modify_field( Neshoba.Windber, Angwin.Fiskdale );
   modify_field( Neshoba.DuckHill, Angwin.Flats );
   modify_field( Neshoba.Lamboglia, Angwin.Montello );
}

table Weslaco {
   reads {
      Saranap.Homeland : exact;
      Saranap.Gurdon : exact;
      Uhland.Bosler : exact;
      Neshoba.Goodlett : exact;
   }

   actions {
      Novinger;
      Pueblo;
   }

   default_action : Pueblo();
   size : Norma;
}


action Tiverton() {
   modify_field( Neshoba.Gunter, Fosston.Emblem );
   modify_field( Neshoba.Champlain, Fosston.PineHill);
}

action Schofield( Lecompte ) {
   modify_field( Neshoba.Gunter, Lecompte );
   modify_field( Neshoba.Champlain, Fosston.PineHill);
}

action Caliente() {
   modify_field( Neshoba.Gunter, LaMarque[0].Ivins );
   modify_field( Neshoba.Champlain, Fosston.PineHill);
}

table Gallinas {
   reads {
      Fosston.PineHill : ternary;
      LaMarque[0] : valid;
      LaMarque[0].Ivins : ternary;
   }

   actions {
      Tiverton;
      Schofield;
      Caliente;
   }
   size : Dagmar;
}

action Aniak( Yantis ) {
   modify_field( Neshoba.Champlain, Yantis );
}

action Hollymead() {

   modify_field( Neshoba.Filley, 1 );
   modify_field( Candor.Ferrum,
                 Leadpoint );
}

table Glyndon {
   reads {
      Uhland.Rudolph : exact;
   }

   actions {
      Aniak;
      Hollymead;
   }
   default_action : Hollymead;
   size : Grainola;
}

action Bozar( RockyGap, Greer, Bacton, Bunavista, Waterflow,
                        Punaluu, Rotterdam ) {
   modify_field( Neshoba.Gunter, RockyGap );
   modify_field( Neshoba.Palomas, Rotterdam );
   Jerico(Greer, Bacton, Bunavista, Waterflow,
                        Punaluu );
}

action Walcott() {
   modify_field( Neshoba.Newland, 1 );
}

table Hector {
   reads {
      Hobart.Boonsboro : exact;
   }

   actions {
      Bozar;
      Walcott;
   }
   size : Parkland;
}

action Jerico(Greer, Bacton, Bunavista, Waterflow,
                        Punaluu ) {
   modify_field( Sunset.Littleton, Greer );
   modify_field( Sunset.Lewistown, Bacton );
   modify_field( Sunset.Yatesboro, Bunavista );
   modify_field( Sunset.Hebbville, Waterflow );
   modify_field( Sunset.Elsey, Punaluu );
}

action Dominguez(Greer, Bacton, Bunavista, Waterflow,
                        Punaluu ) {
   modify_field( Neshoba.Kingsland, Fosston.Emblem );
   modify_field( Neshoba.Palomas, 1 );
   Jerico(Greer, Bacton, Bunavista, Waterflow,
                        Punaluu );
}

action Bevington(Council, Greer, Bacton, Bunavista,
                        Waterflow, Punaluu ) {
   modify_field( Neshoba.Kingsland, Council );
   modify_field( Neshoba.Palomas, 1 );
   Jerico(Greer, Bacton, Bunavista, Waterflow,
                        Punaluu );
}

action Frankfort(Greer, Bacton, Bunavista, Waterflow,
                        Punaluu ) {
   modify_field( Neshoba.Kingsland, LaMarque[0].Ivins );
   modify_field( Neshoba.Palomas, 1 );
   Jerico(Greer, Bacton, Bunavista, Waterflow,
                        Punaluu );
}

table Cannelton {
   reads {
      Fosston.Emblem : exact;
   }

   actions {
      Dominguez;
   }

   size : Craig;
}

table Hookstown {
   reads {
      Fosston.PineHill : exact;
      LaMarque[0].Ivins : exact;
   }

   actions {
      Bevington;
      Shauck;
   }
   default_action : Shauck;

   size : Redondo;
}

table Newberg {
   reads {
      LaMarque[0].Ivins : exact;
   }

   actions {
      Frankfort;
   }

   size : Noonan;
}

control McKenna {
   apply( Weslaco ) {
         Novinger {
            apply( Glyndon );
            apply( Hector );
         }
         Pueblo {
            if ( Fosston.Toccopola == 1 ) {
               apply( Gallinas );
            }
            if ( valid( LaMarque[ 0 ] ) ) {

               apply( Hookstown ) {
                  Shauck {

                     apply( Newberg );
                  }
               }
            } else {

               apply( Cannelton );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Mentmore {
    width  : 1;
    static : Slovan;
    instance_count : 262144;
}

register Ceiba {
    width  : 1;
    static : Eaton;
    instance_count : 262144;
}

blackbox stateful_alu Selah {
    reg : Mentmore;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Kerrville.Ivanhoe;
}

blackbox stateful_alu Clermont {
    reg : Ceiba;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Kerrville.Wanatah;
}

field_list FordCity {
    Fosston.Shasta;
    LaMarque[0].Ivins;
}

field_list_calculation Bradner {
    input { FordCity; }
    algorithm: identity;
    output_width: 18;
}

action Hawthorn() {
    Selah.execute_stateful_alu_from_hash(Bradner);
}

action Essex() {
    Clermont.execute_stateful_alu_from_hash(Bradner);
}

table Slovan {
    actions {
      Hawthorn;
    }
    default_action : Hawthorn;
    size : 1;
}

table Eaton {
    actions {
      Essex;
    }
    default_action : Essex;
    size : 1;
}
#endif

action Beatrice(Westpoint) {
    modify_field(Kerrville.Wanatah, Westpoint);
}

@pragma  use_hash_action 0
table Tillatoba {
    reads {
       Fosston.Shasta : exact;
    }
    actions {
      Beatrice;
    }
    size : 64;
}

action Maltby() {
   modify_field( Neshoba.Timnath, Fosston.Emblem );
   modify_field( Neshoba.Sonestown, 0 );
}

table Abernant {
   actions {
      Maltby;
   }
   size : 1;
}

action Wauregan() {
   modify_field( Neshoba.Timnath, LaMarque[0].Ivins );
   modify_field( Neshoba.Sonestown, 1 );
}

table Fitler {
   actions {
      Wauregan;
   }
   size : 1;
}

control Cypress {
   if ( valid( LaMarque[ 0 ] ) ) {
      apply( Fitler );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Fosston.BigLake == 1 ) {
         apply( Slovan );
         apply( Eaton );
      }
#endif
   } else {
      apply( Abernant );
      if( Fosston.BigLake == 1 ) {
         apply( Tillatoba );
      }
   }
}




field_list Kaltag {
   Saranap.Homeland;
   Saranap.Gurdon;
   Saranap.Aynor;
   Saranap.Portales;
   Saranap.Hannibal;
}

field_list LaVale {

   Uhland.Irondale;
   Uhland.Rudolph;
   Uhland.Bosler;
}

field_list Rankin {
   Maloy.Hephzibah;
   Maloy.Redvale;
   Maloy.RushCity;
   Maloy.Gasport;
}

field_list Westway {
   Uhland.Irondale;
   Uhland.Rudolph;
   Uhland.Bosler;
   Clauene.Hiland;
   Clauene.Lamar;
}





field_list_calculation Pownal {
    input {
        Kaltag;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Putnam {
    input {
        LaVale;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Poipu {
    input {
        Rankin;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation CapRock {
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



action Hanford() {
    modify_field_with_hash_based_offset(Ravena.Patchogue, 0,
                                        Pownal, 4294967296);
}

action Felida() {
    modify_field_with_hash_based_offset(Ravena.Swansboro, 0,
                                        Putnam, 4294967296);
}

action Vanzant() {
    modify_field_with_hash_based_offset(Ravena.Swansboro, 0,
                                        Poipu, 4294967296);
}

action Pavillion() {
    modify_field_with_hash_based_offset(Ravena.Grantfork, 0,
                                        CapRock, 4294967296);
}

table Blackman {
   actions {
      Hanford;
   }
   size: 1;
}

control Kenova {
   apply(Blackman);
}

table Harpster {
   actions {
      Felida;
   }
   size: 1;
}

table Richwood {
   actions {
      Vanzant;
   }
   size: 1;
}

control Locke {
   if ( valid( Uhland ) ) {
      apply(Harpster);
   } else {
      if ( valid( Maloy ) ) {
         apply(Richwood);
      }
   }
}

table Virgil {
   actions {
      Pavillion;
   }
   size: 1;
}

control Sherwin {
   if ( valid( Clauene ) ) {
      apply(Virgil);
   }
}



action Eldred() {
    modify_field(ElPrado.Amenia, Ravena.Patchogue);
}

action Ridgeview() {
    modify_field(ElPrado.Amenia, Ravena.Swansboro);
}

action Rawlins() {
    modify_field(ElPrado.Amenia, Ravena.Grantfork);
}

@pragma immediate 0
table Flasher {
   reads {
      Wyndmoor.valid : ternary;
      VanHorn.valid : ternary;
      Spiro.valid : ternary;
      Ralph.valid : ternary;
      Wyatte.valid : ternary;
      Aldrich.valid : ternary;
      Clauene.valid : ternary;
      Uhland.valid : ternary;
      Maloy.valid : ternary;
      Saranap.valid : ternary;
   }
   actions {
      Eldred;
      Ridgeview;
      Rawlins;
      Shauck;
   }
   default_action : Shauck();
   size: Sonora;
}

control Hurst {
   apply(Flasher);
}





counter Silvertip {
   type : packets_and_bytes;
   direct : DuPont;
   min_width: 16;
}

action Cankton() {
   modify_field(Neshoba.Saugatuck, 1 );
}

table DuPont {
   reads {
      Fosston.Shasta : exact;
      Kerrville.Wanatah : ternary;
      Kerrville.Ivanhoe : ternary;
      Neshoba.Newland : ternary;
      Neshoba.Nahunta : ternary;
      Neshoba.Lumpkin : ternary;
   }

   actions {
      Cankton;
      Shauck;
   }
   default_action : Shauck;
   size : Sammamish;
}

register Brinson {
   width: 1;
   static: Lowemont;
   instance_count: Sylva;
}

#ifdef __TARGET_TOFINO__
blackbox stateful_alu Mabelle{
    reg: Brinson;
    update_lo_1_value: set_bit;
}
#endif

action Perkasie(Everett) {
#if defined(BMV2) || defined(BMV2TOFINO)
   register_write(Brinson, Everett, 1);
#else
   Mabelle.execute_stateful_alu();
#endif

}

action White() {

   modify_field(Neshoba.Goulds, 1 );
   modify_field(Candor.Ferrum,
                Ocilla);
}

table Lowemont {
   reads {
      Neshoba.Waialee : exact;
      Neshoba.Lattimore : exact;
      Neshoba.Gunter : exact;
      Neshoba.Champlain : exact;
   }

   actions {
      Perkasie;
      White;
   }
   size : Sylva;
}

action Bowlus() {
   modify_field( Sunset.Siloam, 1 );
}

table Chenequa {
   reads {
      Neshoba.Kingsland : ternary;
      Neshoba.Naalehu : exact;
      Neshoba.Adair : exact;
   }
   actions {
      Bowlus;
   }
   size: Flourtown;
}

control Bigfork {
   if( Neshoba.Saugatuck == 0 ) {
      apply( Chenequa );
   }
}

control Moark {
   apply( DuPont ) {
      Shauck {



         if (Fosston.Monahans == 0 and Neshoba.Filley == 0) {
            apply( Lowemont );
         }
         apply(Chenequa);
      }
   }
}

field_list Coalgate {
    Candor.Ferrum;
    Neshoba.Waialee;
    Neshoba.Lattimore;
    Neshoba.Gunter;
    Neshoba.Champlain;
}

action Evelyn() {
   generate_digest(Moraine, Coalgate);
}

table Jessie {
   actions {
      Evelyn;
   }
   size : 1;
}

control Wapinitia {
   if (Neshoba.Goulds == 1) {
      apply( Jessie );
   }
}



table Yardley {


   reads {
      Duelm.Knoke : exact;
   }
   actions {
      Wyandanch;
   }
   size : Croft;
}

table Cabot {


   reads {
      Dabney.Newhalem : exact;
   }
   actions {
      Wyandanch;
   }
   size : Grottoes;
}

table Guion {



   reads {
      Dabney.Hughson : exact;
   }
   actions {
      Wyandanch;
   }
   size : Trujillo;
}

action Micco( Churchill ) {
   modify_field( Dabney.Hughson, Churchill );
}

table Burwell {
   reads {
      Sunset.Littleton : exact;
      Dabney.EastDuke mask Franktown : lpm;
   }
   actions {
      Micco;
      Shauck;
   }
   default_action : Shauck();
   size : Palmdale;
}

@pragma atcam_partition_index Dabney.Hughson
@pragma atcam_number_partitions Palmdale
table Westvaco {
   reads {
      Dabney.Hughson : exact;
      Dabney.EastDuke mask Uniontown : lpm;
   }

   actions {
      Wyandanch;
      Shauck;
   }
   default_action : Shauck();
   size : Cornwall;
}

action Maumee( Parmelee ) {
   modify_field( Dabney.Newhalem, Parmelee );
}

table Powers {


   reads {
      Sunset.Littleton : exact;
      Dabney.EastDuke : lpm;
   }

   actions {
      Maumee;
      Shauck;
   }

   default_action : Shauck();
   size : Davant;
}

@pragma atcam_partition_index Dabney.Newhalem
@pragma atcam_number_partitions Davant
table Hannah {
   reads {
      Dabney.Newhalem : exact;


      Dabney.EastDuke mask Ranburne : lpm;
   }
   actions {
      Wyandanch;
      Shauck;
   }

   default_action : Shauck();
   size : Sparkill;
}

@pragma idletime_precision 1
table RowanBay {

   reads {
      Sunset.Littleton : exact;
      Duelm.Domestic : lpm;
   }

   actions {
      Wyandanch;
      Shauck;
   }

   default_action : Shauck();
   size : Kinsley;
   support_timeout : true;
}

action Weskan(Amazonia) {
   modify_field(Duelm.Knoke, Amazonia);
}

table Peoria {
   reads {
      Sunset.Littleton : exact;
      Duelm.Domestic : lpm;
   }

   actions {
      Weskan;
      Shauck;
   }

   default_action : Shauck();
   size : Mulliken;
}

@pragma atcam_partition_index Duelm.Knoke
@pragma atcam_number_partitions Mulliken
table ElCentro {
   reads {
      Duelm.Knoke : exact;
      Duelm.Domestic mask Twinsburg : lpm;
   }
   actions {
      Wyandanch;
      Shauck;
   }
   default_action : Shauck();
   size : Magna;
}

action Wyandanch( Plato ) {
   modify_field( Calabasas.Hookdale, 1 );
   modify_field( McGrady.Fergus, Plato );
}

@pragma idletime_precision 1
table Cecilton {
   reads {
      Sunset.Littleton : exact;
      Duelm.Domestic : exact;
   }

   actions {
      Wyandanch;
      Shauck;
   }
   default_action : Shauck();
   size : Dizney;
   support_timeout : true;
}

@pragma idletime_precision 1
table Nickerson {
   reads {
      Sunset.Littleton : exact;
      Dabney.EastDuke : exact;
   }

   actions {
      Wyandanch;
      Shauck;
   }
   default_action : Shauck();
   size : Marlton;
   support_timeout : true;
}

action Telephone(Maiden, Minneiska, Delmar) {
   modify_field(Calabasas.SanRemo, Delmar);
   modify_field(Calabasas.Storden, Maiden);
   modify_field(Calabasas.Osage, Minneiska);
   modify_field(Calabasas.Hookdale, 1);
}

table Govan {
   reads {
      McGrady.Fergus : exact;
   }

   actions {
      Telephone;
   }
   size : Sandstone;
}

control Kewanee {
   if ( Neshoba.Saugatuck == 0 and Sunset.Siloam == 1 ) {
      if ( ( Sunset.Lewistown == 1 ) and ( Neshoba.Fittstown == 1 ) ) {
         apply( Cecilton ) {
            Shauck {
               apply( Peoria ) {
                  Weskan {
                     apply( ElCentro ) {
                        Shauck {
                           apply( Yardley );
                        }
                     }
                  }
                  Shauck {
                     apply( RowanBay );
                  }
               }
            }
         }
      } else if ( ( Sunset.Yatesboro == 1 ) and ( Neshoba.Windber == 1 ) ) {
         apply( Nickerson ) {
            Shauck {
               apply( Powers ) {
                  Maumee {
                     apply( Hannah ) {
                        Shauck {
                           apply( Cabot );
                        }
                     }
                  }
                  Shauck {

                     apply( Burwell ) {
                        Micco {
                           apply( Westvaco ) {
                              Shauck {
                                 apply( Guion );
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

control Moultrie {
   if( McGrady.Fergus != 0 ) {
      apply( Govan );
   }
}



field_list Nunda {
   ElPrado.Amenia;
}

field_list_calculation Brodnax {
    input {
        Nunda;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Northcote {
    selection_key : Brodnax;
    selection_mode : resilient;
}

action Excello(Bonduel) {
   modify_field(Calabasas.Everton, Bonduel);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Bonduel);
}

action_profile Nunnelly {
    actions {
        Excello;
        Shauck;
    }
    size : Lincroft;
    dynamic_action_selection : Northcote;
}

table Brashear {
   reads {
      Calabasas.Everton : exact;
   }
   action_profile: Nunnelly;
   size : Biehle;
}

control Boyle {
   if ((Neshoba.Saugatuck == 0) and (Calabasas.Everton & 0x2000) == 0x2000) {
      apply(Brashear);
   }
}



action Gladys() {
   modify_field(Calabasas.Storden, Neshoba.Naalehu);
   modify_field(Calabasas.Osage, Neshoba.Adair);
   modify_field(Calabasas.Oxford, Neshoba.Waialee);
   modify_field(Calabasas.Roachdale, Neshoba.Lattimore);
   modify_field(Calabasas.SanRemo, Neshoba.Gunter);
}

table Hillsview {
   actions {
      Gladys;
   }
   default_action : Gladys();
   size : 1;
}

control Ragley {
   if (Neshoba.Gunter!=0) {
      apply( Hillsview );
   }
}

action Doris() {
   modify_field(Calabasas.LakePine, 1);
   modify_field(Calabasas.Ackley, 1);
   modify_field(Calabasas.Unionvale, Calabasas.SanRemo);
}

action Diana() {
}



@pragma ways 1
table Kentwood {
   reads {
      Calabasas.Storden : exact;
      Calabasas.Osage : exact;
   }
   actions {
      Doris;
      Diana;
   }
   default_action : Diana;
   size : 1;
}

action Amory() {
   modify_field(Calabasas.Ashtola, 1);
   modify_field(Calabasas.RedBay, 1);
   add(Calabasas.Unionvale, Calabasas.SanRemo, Hanapepe);
}

table Bonney {
   actions {
      Amory;
   }
   default_action : Amory;
   size : 1;
}

action Gibson() {
   modify_field(Calabasas.DeSmet, 1);
   modify_field(Calabasas.Unionvale, Calabasas.SanRemo);
}

table Navarro {
   actions {
      Gibson;
   }
   default_action : Gibson();
   size : 1;
}

action ElkPoint(MintHill) {
   modify_field(Calabasas.Munday, 1);
   modify_field(Calabasas.Everton, MintHill);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, MintHill);
}

action Mabank(Gonzalez) {
   modify_field(Calabasas.Ashtola, 1);
   modify_field(Calabasas.Unionvale, Gonzalez);
}

action Danforth() {
}

table Langston {
   reads {
      Calabasas.Storden : exact;
      Calabasas.Osage : exact;
      Calabasas.SanRemo : exact;
   }

   actions {
      ElkPoint;
      Mabank;
      Danforth;
   }
   default_action : Danforth();
   size : Oshoto;
}

control Glenshaw {
   if (Neshoba.Saugatuck == 0) {
      apply(Langston) {
         Danforth {
            apply(Kentwood) {
               Diana {
                  if ((Calabasas.Storden & 0x010000) == 0x010000) {
                     apply(Bonney);
                  } else {
                     apply(Navarro);
                  }
               }
            }
         }
      }
   }
}


action Valders() {
   modify_field(Neshoba.Saugatuck, 1);
}

table Westboro {
   actions {
      Valders;
   }
   default_action : Valders;
   size : 1;
}

control Brimley {
   if ((Calabasas.Hookdale==0) and (Neshoba.Champlain==Calabasas.Everton)) {
      apply(Westboro);
   }
}



action Padonia( Somis ) {
   modify_field( Calabasas.Kensett, Somis );
}

action Lapoint() {
   modify_field( Calabasas.Kensett, Calabasas.SanRemo );
}

table Alamota {
   reads {
      eg_intr_md.egress_port : exact;
      Calabasas.SanRemo : exact;
   }

   actions {
      Padonia;
      Lapoint;
   }
   default_action : Lapoint;
   size : Flomot;
}

control Hartwick {
   apply( Alamota );
}



action Stella( Greenbush, NorthRim ) {
   modify_field( Calabasas.Tombstone, Greenbush );
   modify_field( Calabasas.Northway, NorthRim );
}


table Virgilina {
   reads {
      Calabasas.Woodrow : exact;
   }

   actions {
      Stella;
   }
   size : Ladelle;
}

action Wiota() {
   no_op();
}

action Toxey() {
   modify_field( Saranap.Hannibal, LaMarque[0].Meservey );
   remove_header( LaMarque[0] );
}

table Ruston {
   actions {
      Toxey;
   }
   default_action : Toxey;
   size : Cotter;
}

action Wimberley() {
   no_op();
}

action Macopin() {
   add_header( LaMarque[ 0 ] );
   modify_field( LaMarque[0].Ivins, Calabasas.Kensett );


   modify_field( LaMarque[0].Meservey, Saranap.Hannibal );
   modify_field( Saranap.Hannibal, Nuevo );
}



table Tullytown {
   reads {
      Calabasas.Kensett : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Wimberley;
      Macopin;
   }
   default_action : Macopin;
   size : Taneytown;
}

action Tulalip() {
   modify_field(Saranap.Homeland, Calabasas.Storden);
   modify_field(Saranap.Gurdon, Calabasas.Osage);
   modify_field(Saranap.Aynor, Calabasas.Tombstone);
   modify_field(Saranap.Portales, Calabasas.Northway);
}

action Progreso() {
   Tulalip();
   add_to_field(Uhland.Chitina, -1);
   modify_field(Uhland.Plano, Calabasas.Laton );
}

action Cistern() {
   Tulalip();
   add_to_field(Maloy.Switzer, -1);
   modify_field(Maloy.LaPryor, Calabasas.Laton );
}






@pragma stage 2
table Kurthwood {
   reads {
      Calabasas.Elwyn : exact;
      Calabasas.Woodrow : exact;
      Calabasas.Hookdale : exact;
      Uhland.valid : ternary;
      Maloy.valid : ternary;
   }

   actions {
      Progreso;
      Cistern;
   }
   size : Lemhi;
}

control Glazier {
   apply( Ruston );
}

control Idylside {
   apply( Tullytown );
}

control DimeBox {
   apply( Virgilina );
   apply( Kurthwood );
}



field_list Covington {
    Candor.Ferrum;
    Neshoba.Gunter;
    Wyatte.Aynor;
    Wyatte.Portales;
    Uhland.Rudolph;
}

action Tindall() {
   generate_digest(Moraine, Covington);
}

table Goldsmith {
   actions {
      Tindall;
   }

   default_action : Tindall;
   size : 1;
}

control Cassa {
   if (Neshoba.Filley == 1) {
      apply(Goldsmith);
   }
}



action Harmony() {
   modify_field( Neshoba.DuckHill, Fosston.Libby );
}

action Malaga() {
   modify_field( Neshoba.Quinwood, Fosston.Kaupo );
}

action Sledge() {
   modify_field( Neshoba.Quinwood, Duelm.Granville );
}

action Gardiner() {
   modify_field( Neshoba.Quinwood, Dabney.Anvik );
}

action Atlantic( Vesuvius, Chalco ) {


}

action Clarinda( Montross, Faith, Sunman ) {
   modify_field( Calabasas.Affton, Montross );
   modify_field( Calabasas.Laton, Faith );
   modify_field( Calabasas.Wegdahl, Sunman );
}

table Floral {
   reads {
     Neshoba.Lamboglia : exact;
   }

   actions {
     Harmony;
   }

   size : Olene;
}

table Stirrat {
   reads {
     Neshoba.Fittstown : exact;
     Neshoba.Windber : exact;
   }

   actions {
     Malaga;
     Sledge;
     Gardiner;
   }

   size : Milesburg;
}

table Sutherlin {
   reads {
      Fosston.Portville : exact;
      Fosston.Libby : ternary;
      Neshoba.DuckHill : ternary;
      Neshoba.Quinwood : ternary;
   }

   actions {
      Atlantic;
   }

   size : Floris;
}

table Blanding {
   reads {
      Fosston.Portville : exact;
      Fosston.Puyallup : ternary;
      Fosston.Blitchton : ternary;

   }

   actions {
      Clarinda;
   }

   size : Edgemoor;
}

control DelRosa {
   apply( Floral );
   apply( Stirrat );
}

control Gannett {
   apply( Sutherlin );
   apply( Blanding );
}

control ingress {

   Mumford();
   Thayne();
   McKenna();
   Cypress();
   Kenova();


   DelRosa();
   Moark();

   Locke();
   Sherwin();


   Kewanee();

   Ragley();

   Moultrie();


   Hurst();



   Glenshaw();


   Brimley();
   Cassa();
   Wapinitia();


   if( valid( LaMarque[0] ) ) {
      Glazier();
   }


   Gannett();


   Boyle();
}

control egress {
   Hartwick();
   DimeBox();
   Idylside();
}

