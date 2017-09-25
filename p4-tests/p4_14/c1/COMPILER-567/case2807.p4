// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 104352







#ifdef __TARGET_BMV2__
#define BMV2
#endif



#undef PROFILE_DEFAULT
#define PROFILE_DEFAULT
#define Richvale

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>



#ifndef Onley
#define Onley

header_type Coachella {
	fields {
		Marbleton : 16;
		Idylside : 16;
		Lugert : 8;
		Dillsburg : 8;
		Mosinee : 8;
		Hansell : 8;
		Hooker : 1;
		Filley : 1;
		Paullina : 1;
		Meyers : 1;
		Trevorton : 1;
		Swaledale : 1;
	}
}

header_type Destin {
	fields {
		McClure : 24;
		Novice : 24;
		Nooksack : 24;
		Emlenton : 24;
		Sitka : 16;
		Delcambre : 16;
		Sturgis : 16;
		Billett : 16;
		PineHill : 16;
		Deferiet : 8;
		Vanzant : 8;
		Monowi : 1;
		Earlsboro : 1;
		Scherr : 1;
		Ralls : 1;
		CruzBay : 12;
		Chevak : 2;
		Ozona : 1;
		OakCity : 1;
		Ghent : 1;
		Kapalua : 1;
		Everest : 1;
		Absecon : 1;
		Wollochet : 1;
		Meridean : 1;
		Elmore : 1;
		SomesBar : 1;
		Durant : 1;
		Hickox : 1;
		Alcester : 1;
		Telma : 1;
		Matador : 1;
		Fayette : 1;
		GunnCity : 16;
		Nevis : 16;
		Twodot : 1;
		UnionGap : 1;
	}
}

header_type Fillmore {
	fields {
		Dunmore : 24;
		Jerico : 24;
		Campton : 24;
		RoseBud : 24;
		LakeHart : 24;
		Otego : 24;
		Fosters : 24;
		Cutler : 24;
		Glenvil : 16;
		Lewiston : 16;
		Arredondo : 16;
		Ackley : 16;
		Darby : 12;
		Gervais : 1;
		Careywood : 3;
		Sylvan : 1;
		Shelby : 3;
		Tilghman : 1;
		Poland : 1;
		Jefferson : 1;
		Gonzalez : 1;
		PawCreek : 1;
		Brookwood : 8;
		Pownal : 12;
		Ballwin : 4;
		Punaluu : 6;
		Neosho : 10;
		Hapeville : 9;
		Selby : 1;
		Kalvesta : 1;
		Mesita : 1;
		Tabler : 1;
		Coverdale : 1;
	}
}


header_type Roosville {
	fields {
		Christmas : 8;
		Oklee : 1;
		Bethesda : 1;
		Viroqua : 1;
		Mullins : 1;
		Bechyn : 1;
	}
}

header_type Yardley {
	fields {
		Lambert : 32;
		Ringwood : 32;
		Covington : 6;
		Newburgh : 16;
	}
}

header_type Shelbina {
	fields {
		Sublett : 128;
		TinCity : 128;
		Pelican : 20;
		Westwego : 8;
		Hatfield : 11;
		Aurora : 6;
		Hernandez : 13;
	}
}

header_type Trimble {
	fields {
		Everett : 14;
		Wheeling : 1;
		Telida : 12;
		Wauneta : 1;
		Conneaut : 1;
		Newfolden : 6;
		Wapinitia : 2;
		Corinth : 6;
		Aldan : 3;
	}
}

header_type Champlin {
	fields {
		Manning : 1;
		Lazear : 1;
	}
}

header_type Vinemont {
	fields {
		Moark : 8;
	}
}

header_type Millikin {
	fields {
		Trammel : 16;
		Baird : 11;
	}
}

header_type Woodville {
	fields {
		Halfa : 32;
		Eaton : 32;
		Lenexa : 32;
	}
}

header_type Atlantic {
	fields {
		GlenDean : 32;
		Rhine : 32;
	}
}

header_type Aguila {
	fields {
		Albin : 1;
		Fairchild : 1;
		Abernant : 1;
		Roscommon : 3;
		Genola : 1;
		Lubeck : 6;
		Kelvin : 1;
	}
}

header_type Bowlus {
	fields {
		LeeCreek : 16;
	}
}

header_type Wildorado {
	fields {
		Balmville : 14;
		Cortland : 1;
		Caspian : 1;
	}
}

header_type Medart {
	fields {
		Roberta : 14;
		Barwick : 1;
		Nestoria : 1;
	}
}


header_type Richwood {
	fields {
		Brownson : 16;
		Alakanuk : 16;
		Arvana : 16;
		RushCity : 16;
		Adamstown : 8;
		Callao : 6;
		Rankin : 8;
		Ashtola : 8;
		Ravinia : 1;
		Yakutat : 25;
		Hollymead : 8;
	}
}

header_type DosPalos {
	fields {
		Tavistock : 24;
	}
}

#endif



#ifndef Wheaton
#define Wheaton


header_type Traskwood {
	fields {
		Moodys : 6;
		Eastman : 10;
		Scarville : 4;
		Levasy : 12;
		Minto : 12;
		Joshua : 2;
		Gardiner : 2;
		Anawalt : 8;
		Bains : 3;
		Stonebank : 5;
	}
}



header_type Twinsburg {
	fields {
		Salamatof : 24;
		Greer : 24;
		Suffern : 24;
		Calamine : 24;
		Clearmont : 16;
	}
}



header_type Sherrill {
	fields {
		Storden : 3;
		Elysburg : 1;
		Kinsley : 12;
		McDavid : 16;
	}
}



header_type Tigard {
	fields {
		Sylva : 4;
		Fairhaven : 4;
		Achille : 6;
		Eolia : 2;
		Warba : 16;
		Dunbar : 16;
		McCaulley : 3;
		Newberg : 13;
		Mustang : 8;
		Keltys : 8;
		Berville : 16;
		Sunman : 32;
		Melba : 32;
	}
}

header_type Yulee {
	fields {
		Turney : 4;
		Pathfork : 6;
		Kensett : 2;
		Lindy : 20;
		Delmont : 16;
		Jesup : 8;
		Marshall : 8;
		Stecker : 128;
		Broadmoor : 128;
	}
}




header_type Lemont {
	fields {
		Hughson : 8;
		Heuvelton : 8;
		Thistle : 16;
	}
}

header_type Omemee {
	fields {
		Ardsley : 16;
		Livengood : 16;
	}
}

header_type Ballinger {
	fields {
		Rugby : 32;
		Oldsmar : 32;
		Waupaca : 4;
		Tidewater : 4;
		Cashmere : 8;
		Rotterdam : 16;
		Norridge : 16;
		Panacea : 16;
	}
}

header_type Deloit {
	fields {
		Lushton : 16;
		Westend : 16;
	}
}



header_type Kingman {
	fields {
		RossFork : 16;
		Nambe : 16;
		Langdon : 8;
		Maryhill : 8;
		Kealia : 16;
	}
}

header_type Montague {
	fields {
		Hobergs : 48;
		Kinard : 32;
		Rayville : 48;
		SeaCliff : 32;
	}
}



header_type Warden {
	fields {
		Archer : 1;
		Anandale : 1;
		HighHill : 1;
		Toluca : 1;
		Exton : 1;
		Kneeland : 3;
		Hillister : 5;
		Tatitlek : 3;
		Mikkalo : 16;
	}
}

header_type Rosario {
	fields {
		Sutherlin : 24;
		Volcano : 8;
	}
}



header_type Gillespie {
	fields {
		Brookland : 8;
		Perkasie : 24;
		Emigrant : 24;
		Aylmer : 8;
	}
}

#endif



#ifndef Marbury
#define Marbury

#define Talbert        0x8100
#define Iredell        0x0800
#define Wamego        0x86dd
#define Ambler        0x9100
#define AvonLake        0x8847
#define Coffman         0x0806
#define Leola        0x8035
#define Haena        0x88cc
#define Mangham        0x8809
#define FifeLake      0xBF00

#define Pumphrey              1
#define Anacortes              2
#define Wilbraham              4
#define Bolckow               6
#define Dagsboro               17
#define Seaforth                47

#define Sonestown         0x501
#define Ranburne          0x506
#define ElPrado          0x511
#define Bessie          0x52F

#define Chaumont                 0xFF7000

#define Silco                 4789



#define Sodaville               0
#define Downs              1
#define Vincent                2



#define Terral          0
#define Dutton          4095
#define McIntyre  4096
#define Lewellen  8191



#define Abraham                      0
#define Keokee                  0
#define Tamms                 1

header Twinsburg Notus;
header Twinsburg Burrel;
header Sherrill Pinecreek[ 2 ];



@pragma pa_fragment ingress FulksRun.Berville
@pragma pa_fragment egress FulksRun.Berville
header Tigard FulksRun;

@pragma pa_fragment ingress Atlas.Berville
@pragma pa_fragment egress Atlas.Berville
header Tigard Atlas;

header Yulee Camden;
header Yulee Philip;
header Omemee Bladen;
header Omemee Lofgreen;
header Ballinger Freeville;
header Deloit Catawissa;

header Ballinger MintHill;
header Deloit Bieber;
header Gillespie Coqui;
header Kingman Barclay;
header Warden Laurie;
header Traskwood Neshoba;
header Twinsburg Hanamaulu;

parser start {
   return select(current(96, 16)) {
      FifeLake : Drake;
      default : Belcourt;
   }
}

parser Peoria {
   extract( Neshoba );
   return Belcourt;
}

parser Drake {
   extract( Hanamaulu );
   return Peoria;
}

parser Belcourt {
   extract( Notus );
   return select( Notus.Clearmont ) {
      Talbert : Litroe;
      Iredell : Reidland;
      Wamego : Wellsboro;
      Coffman  : Leflore;
      default        : ingress;
   }
}

parser Litroe {
   extract( Pinecreek[0] );
   set_metadata(Seagrove.Trevorton, 1);
   return select( Pinecreek[0].McDavid ) {
      Iredell : Reidland;
      Wamego : Wellsboro;
      Coffman  : Leflore;
      default : ingress;
   }
}

field_list Colstrip {
    FulksRun.Sylva;
    FulksRun.Fairhaven;
    FulksRun.Achille;
    FulksRun.Eolia;
    FulksRun.Warba;
    FulksRun.Dunbar;
    FulksRun.McCaulley;
    FulksRun.Newberg;
    FulksRun.Mustang;
    FulksRun.Keltys;
    FulksRun.Sunman;
    FulksRun.Melba;
}

field_list_calculation Cataract {
    input {
        Colstrip;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field FulksRun.Berville  {
    verify Cataract;
    update Cataract;
}

parser Reidland {
   extract( FulksRun );
   set_metadata(Seagrove.Lugert, FulksRun.Keltys);
   set_metadata(Seagrove.Mosinee, FulksRun.Mustang);
   set_metadata(Seagrove.Marbleton, FulksRun.Warba);
   set_metadata(Seagrove.Paullina, 0);
   set_metadata(Seagrove.Hooker, 1);
   return select(FulksRun.Newberg, FulksRun.Fairhaven, FulksRun.Keltys) {

      Sonestown : LeSueur;
      ElPrado : Marie;
      Ranburne : Fitler;
      0 mask Chaumont : ElCentro;
      default : ingress;
   }
}

parser ElCentro {
   set_metadata(Maddock.Scherr, 1);
   return ingress;
}

parser Wellsboro {
   extract( Philip );
   set_metadata(Seagrove.Lugert, Philip.Jesup);
   set_metadata(Seagrove.Mosinee, Philip.Marshall);
   set_metadata(Seagrove.Marbleton, Philip.Delmont);
   set_metadata(Seagrove.Paullina, 1);
   set_metadata(Seagrove.Hooker, 0);
   return select(Philip.Jesup) {
      Pumphrey : LeSueur;
      Dagsboro : Vallecito;
      Bolckow : Fitler;
      default : ElCentro;
   }
}

parser Leflore {
   extract( Barclay );
   set_metadata(Seagrove.Swaledale, 1);
   return ingress;
}

parser Marie {
   extract(Bladen);
   extract(Catawissa);
   set_metadata(Maddock.Scherr, 1);
   return select(Bladen.Livengood) {
      Silco : Amsterdam;
      default : ingress;
    }
}

parser LeSueur {


   extract(Bladen);
   set_metadata(Maddock.Scherr, 1);
   set_metadata(Bladen.Livengood, 0);
   return ingress;
}

parser Vallecito {
   set_metadata(Maddock.Scherr, 1);
   extract(Bladen);
   extract(Catawissa);
   return ingress;
}

parser Fitler {
   set_metadata(Maddock.Twodot, 1);
   set_metadata(Maddock.Scherr, 1);
   extract(Bladen);
   extract(Freeville);
   return ingress;
}

parser Needham {
   set_metadata(Maddock.Chevak, Vincent);
   return Oroville;
}

parser Indrio {
   set_metadata(Maddock.Chevak, Vincent);
   return Colburn;
}

parser Tehachapi {
   extract(Laurie);
   return select(Laurie.Archer, Laurie.Anandale, Laurie.HighHill, Laurie.Toluca, Laurie.Exton,
             Laurie.Kneeland, Laurie.Hillister, Laurie.Tatitlek, Laurie.Mikkalo) {
      Iredell : Needham;
      Wamego : Indrio;
      default : ingress;
   }
}

parser Amsterdam {
   extract(Coqui);
   set_metadata(Maddock.Chevak, Downs);
   return Murdock;
}

field_list Sonoma {
    Atlas.Sylva;
    Atlas.Fairhaven;
    Atlas.Achille;
    Atlas.Eolia;
    Atlas.Warba;
    Atlas.Dunbar;
    Atlas.McCaulley;
    Atlas.Newberg;
    Atlas.Mustang;
    Atlas.Keltys;
    Atlas.Sunman;
    Atlas.Melba;
}

field_list_calculation Delmar {
    input {
        Sonoma;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field Atlas.Berville  {
    verify Delmar;
    update Delmar;
}

parser Oroville {
   extract( Atlas );
   set_metadata(Seagrove.Dillsburg, Atlas.Keltys);
   set_metadata(Seagrove.Hansell, Atlas.Mustang);
   set_metadata(Seagrove.Idylside, Atlas.Warba);
   set_metadata(Seagrove.Meyers, 0);
   set_metadata(Seagrove.Filley, 1);
   return select(Atlas.Newberg, Atlas.Fairhaven, Atlas.Keltys) {

      Sonestown : Gwynn;
      ElPrado : Jenifer;
      Ranburne : Trout;
      0 mask Chaumont : BeeCave;
      default : ingress;
   }
}

parser BeeCave {
   set_metadata(Maddock.Ralls, 1);
   return ingress;
}

parser Colburn {
   extract( Camden );
   set_metadata(Seagrove.Dillsburg, Camden.Jesup);
   set_metadata(Seagrove.Hansell, Camden.Marshall);
   set_metadata(Seagrove.Idylside, Camden.Delmont);
   set_metadata(Seagrove.Meyers, 1);
   set_metadata(Seagrove.Filley, 0);
   return select(Camden.Jesup) {
      Pumphrey : Gwynn;
      Dagsboro : Jenifer;
      Bolckow : Trout;
      default : BeeCave;
   }
}



parser Gwynn {

   set_metadata( Maddock.GunnCity, current( 0, 16 ) );
   set_metadata( Maddock.Fayette, 1 );
   set_metadata( Maddock.Ralls, 1 );
   return ingress;
}

parser Jenifer {
   set_metadata( Maddock.GunnCity, current( 0, 16 ) );
   set_metadata( Maddock.Nevis, current( 16, 16 ) );
   set_metadata( Maddock.Fayette, 1 );
   set_metadata( Maddock.Ralls, 1);
   return ingress;
}

parser Trout {
   set_metadata( Maddock.GunnCity, current( 0, 16 ) );
   set_metadata( Maddock.Nevis, current( 16, 16 ) );
   set_metadata( Maddock.Fayette, 1 );
   set_metadata( Maddock.Ralls, 1 );
   set_metadata( Maddock.UnionGap, 1 );

   extract(Lofgreen);
   extract(MintHill);
   return ingress;
}

parser Murdock {
   extract( Burrel );
   return select( Burrel.Clearmont ) {
      Iredell: Oroville;
      Wamego: Colburn;
      default: ingress;
   }
}
#endif

@pragma pa_no_init ingress Maddock.McClure
@pragma pa_no_init ingress Maddock.Novice
@pragma pa_no_init ingress Maddock.Nooksack
@pragma pa_no_init ingress Maddock.Emlenton
metadata Destin Maddock;

@pragma pa_no_init ingress Trenary.Dunmore
@pragma pa_no_init ingress Trenary.Jerico
@pragma pa_no_init ingress Trenary.Campton
@pragma pa_no_init ingress Trenary.RoseBud
metadata Fillmore Trenary;

metadata Trimble Kaweah;
metadata Coachella Seagrove;
metadata Yardley Roggen;
metadata Shelbina Wauregan;
metadata Champlin PortVue;
metadata Roosville Ladelle;
metadata Vinemont Belvue;
metadata Millikin Langlois;
metadata Atlantic Segundo;
metadata Woodville Loogootee;
metadata Aguila Cushing;

metadata Bowlus Woodfords;
metadata Wildorado Scottdale;
metadata Medart Pinta;
metadata Richwood Keyes;
metadata Richwood Barksdale;
metadata DosPalos Allgood;
metadata DosPalos Fairborn;













#undef Newfane
#undef Penrose
#undef Hotevilla
#undef Newland
#undef Beeler

#undef Kellner

#undef Parmelee
#undef Greenbelt
#undef McCleary
#undef Sonoita
#undef Conger
#undef Whitten

#undef Virgilina
#undef Nunnelly
#undef Ishpeming

#undef Uniontown
#undef Encinitas
#undef Benitez
#undef Lostine
#undef DesPeres
#undef Wadley
#undef Wartrace
#undef Shine
#undef Hewitt
#undef Hallville
#undef Palmdale
#undef Seabrook
#undef Battles
#undef Overlea
#undef Ugashik
#undef Wimberley
#undef CatCreek
#undef Lilymoor
#undef Brainard
#undef Harviell
#undef Milesburg

#undef Konnarock
#undef Humacao
#undef Flippen
#undef Newcastle
#undef Hodges
#undef Dowell
#undef Otisco
#undef Ellinger
#undef Blueberry
#undef Kennebec
#undef Mattoon
#undef LeeCity
#undef Carlson
#undef Joseph
#undef Stockton
#undef Donald
#undef Caputa
#undef Servia
#undef Petoskey
#undef RiceLake

#undef Burmester
#undef Amity

#undef Heavener

#undef Moultrie
#undef Komatke

#undef Ovett
#undef Hebbville
#undef Shasta
#undef Arapahoe
#undef Westland







#define Kellner 288


#ifdef PROFILE_DEFAULT

#define Newfane

#define Penrose

#define Hotevilla

#define Newland

#define Beeler



#define Parmelee      65536
#define Greenbelt      65536
#define McCleary 1024
#define Sonoita 512
#define Conger      512
#define Whitten 4096


#define Virgilina     1024
#define Nunnelly    1024
#define Ishpeming     256


#define Uniontown 512
#define Encinitas 65536
#define Benitez 65536
#define Lostine 28672
#define DesPeres   16384
#define Wadley 8192
#define Wartrace         131072
#define Shine 65536
#define Hewitt 1024
#define Hallville 2048
#define Palmdale 16384
#define Seabrook 8192
#define Battles 65536

#define Overlea 0x0000000000000000FFFFFFFFFFFFFFFF


#define Ugashik 0x000fffff
#define Lilymoor 2

#define Wimberley 0xFFFFFFFFFFFFFFFF0000000000000000

#define CatCreek 0x000007FFFFFFFFFF0000000000000000
#define Brainard  6
#define Milesburg        2048
#define Harviell       65536


#define Konnarock 1024
#define Humacao 4096
#define Flippen 4096
#define Newcastle 4096
#define Hodges 4096
#define Dowell 1024
#define Otisco 4096
#define Blueberry 128
#define Kennebec 1
#define Mattoon  8


#define LeeCity 512
#define Burmester 512
#define Amity 256


#define Carlson 2
#define Joseph 3
#define Stockton 81



#define Donald 2048
#define Caputa 2048
#define Servia 512

#define Petoskey 1
#define RiceLake 512



#define Heavener 0


#define Moultrie    4096
#define Komatke    1024


#define Ovett    16384
#define Hebbville   16384
#define Shasta            16384

#define Arapahoe                    57344
#define Westland         511


#endif




#ifdef Richvale

#define Newfane

#define Penrose "/usr/lib/libar_bf_pd_default.so"
#define Hotevilla "/usr/lib/libar_bf_resource_info_default.so"
#define Newland "/usr/share/p4/arista_switch_default/tofino.bin"
#define Beeler "/usr/share/p4/arista_switch_default/mau.context.json"


#define Parmelee        512
#define Greenbelt      3072
#define McCleary 512
#define Sonoita 512
#define Conger      512
#define Whitten 512


#define Virgilina     3072
#define Nunnelly    512
#define Ishpeming     512


#define Uniontown 512
#define Encinitas 3071
//#define Benitez 3071


//#define DesPeres   1024
#define Wartrace         8192
#define Shine 3072
#define Hewitt 512
#define Hallville 512
#define Palmdale 4096
#define Seabrook 1024
#define Battles 8192

#define Overlea 0x0000000000000000FFFFFFFFFFFFFFFF


#define Ugashik 0x000fffff
#define Lilymoor 2

#define Wimberley 0xFFFFFFFFFFFFFFFF0000000000000000

#define CatCreek 0x000007FFFFFFFFFF0000000000000000
#define Brainard  6
#define Milesburg        2048
#define Harviell       4096


#define Konnarock 3072
#define Humacao 3071
#define Flippen 3071
#define Newcastle 512
#define Hodges 3071
#define Dowell 3071
#define Otisco 3071
#define Blueberry 3071
#define Kennebec 1
#define Mattoon  8


#define LeeCity 512
#define Burmester 512
#define Amity 256


#define Carlson 2
#define Joseph 3
#define Stockton 81



#define Donald 2048
#define Caputa 2048
#define Servia 512

#define Petoskey 1
#define RiceLake 512



#define Heavener 0


#define Moultrie    3072
#define Komatke    1024


#define Ovett    16384
#define Hebbville   16384
#define Shasta            16384

#define Arapahoe                    57344
#define Westland         511


#define Mondovi 256
#define Anita 512
#define Fouke 512
#define Quinhagak 512
#define NewTrier 512
#define Madill 512
#define Shabbona 512
#define Yukon 4095
#define Amherst 4095
#define Holcomb 4096
#define Coolin 4096
#define Raven 4096
#define CeeVee 4096
#define Bellamy 4096

#define Oconee 4096

#endif




#ifndef Cozad
#define Cozad

action Calabash() {
   no_op();
}

action Challis() {
   modify_field(Maddock.Kapalua, 1 );
   mark_for_drop();
}

action Hamel() {
   no_op();
}
#endif




#define Earlimart         0
#define Preston        1


#define Cammal            0
#define PeaRidge  1
#define Armstrong 2


#define Cathay              0
#define Waitsburg             1
#define RedHead 2


















action Bayshore(Iroquois, Diomede, Vidaurri, Almelund, BigWater, Idria,
                 Taconite, Kaolin, Cotter) {
    modify_field(Kaweah.Everett, Iroquois);
    modify_field(Kaweah.Wheeling, Diomede);
    modify_field(Kaweah.Telida, Vidaurri);
    modify_field(Kaweah.Wauneta, Almelund);
    modify_field(Kaweah.Conneaut, BigWater);
    modify_field(Kaweah.Newfolden, Idria);
    modify_field(Kaweah.Wapinitia, Taconite);
    modify_field(Kaweah.Aldan, Kaolin);
    modify_field(Kaweah.Corinth, Cotter);
}

@pragma command_line --no-dead-code-elimination
table Carpenter {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Bayshore;
    }
    size : Kellner;
}

control Coamo {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Carpenter);
    }
}





action Jenners(Fannett, LasLomas) {
   modify_field( Trenary.Sylvan, 1 );
   modify_field( Trenary.Brookwood, Fannett);
   modify_field( Maddock.SomesBar, 1 );
   modify_field( Cushing.Abernant, LasLomas );
}

action WallLake() {
   modify_field( Maddock.Wollochet, 1 );
   modify_field( Maddock.Hickox, 1 );
}

action Ashwood() {
   modify_field( Maddock.SomesBar, 1 );
}

action Mabelvale() {
   modify_field( Maddock.SomesBar, 1 );
   modify_field( Maddock.Alcester, 1 );
}

action Marley() {
   modify_field( Maddock.Durant, 1 );
}

action Thermal() {
   modify_field( Maddock.Hickox, 1 );
}

counter Goldenrod {
   type : packets_and_bytes;
   direct : Campo;
   min_width: 16;
}

table Campo {
   reads {
      Kaweah.Newfolden : exact;
      Notus.Salamatof : ternary;
      Notus.Greer : ternary;
   }

   actions {
      Jenners;
      WallLake;
      Ashwood;
      Marley;
      Thermal;
      Mabelvale;
   }
   size : McCleary;
}

action Karlsruhe() {
   modify_field( Maddock.Meridean, 1 );
}


table RedLevel {
   reads {
      Notus.Suffern : ternary;
      Notus.Calamine : ternary;
   }

   actions {
      Karlsruhe;
   }
   size : Sonoita;
}


control Lublin {
   apply( Campo );
   apply( RedLevel );
}




action Virgil() {
   modify_field( Roggen.Lambert, Atlas.Sunman );
   modify_field( Roggen.Ringwood, Atlas.Melba );
   modify_field( Roggen.Covington, Atlas.Achille );
   modify_field( Wauregan.Sublett, Camden.Stecker );
   modify_field( Wauregan.TinCity, Camden.Broadmoor );
   modify_field( Wauregan.Pelican, Camden.Lindy );
   modify_field( Wauregan.Aurora, Camden.Pathfork );
   modify_field( Maddock.McClure, Burrel.Salamatof );
   modify_field( Maddock.Novice, Burrel.Greer );
   modify_field( Maddock.Nooksack, Burrel.Suffern );
   modify_field( Maddock.Emlenton, Burrel.Calamine );
   modify_field( Maddock.Sitka, Burrel.Clearmont );
   modify_field( Maddock.PineHill, Seagrove.Idylside );
   modify_field( Maddock.Deferiet, Seagrove.Dillsburg );
   modify_field( Maddock.Vanzant, Seagrove.Hansell );
   modify_field( Maddock.Earlsboro, Seagrove.Filley );
   modify_field( Maddock.Monowi, Seagrove.Meyers );
   modify_field( Maddock.Telma, 0 );
   modify_field( Trenary.Shelby, Waitsburg );



   modify_field( Kaweah.Wapinitia, 1 );
   modify_field( Kaweah.Aldan, 0 );
   modify_field( Kaweah.Corinth, 0 );
   modify_field( Cushing.Albin, 1 );
   modify_field( Cushing.Fairchild, 1 );
   modify_field( Maddock.Scherr, Maddock.Ralls );
   modify_field( Maddock.Twodot, Maddock.UnionGap );
}

action Canfield() {
   modify_field( Maddock.Chevak, Sodaville );
   modify_field( Roggen.Lambert, FulksRun.Sunman );
   modify_field( Roggen.Ringwood, FulksRun.Melba );
   modify_field( Roggen.Covington, FulksRun.Achille );
   modify_field( Wauregan.Sublett, Philip.Stecker );
   modify_field( Wauregan.TinCity, Philip.Broadmoor );
   modify_field( Wauregan.Pelican, Philip.Lindy );
   modify_field( Wauregan.Aurora, Philip.Pathfork );
   modify_field( Maddock.McClure, Notus.Salamatof );
   modify_field( Maddock.Novice, Notus.Greer );
   modify_field( Maddock.Nooksack, Notus.Suffern );
   modify_field( Maddock.Emlenton, Notus.Calamine );
   modify_field( Maddock.Sitka, Notus.Clearmont );
   modify_field( Maddock.PineHill, Seagrove.Marbleton );
   modify_field( Maddock.Deferiet, Seagrove.Lugert );
   modify_field( Maddock.Vanzant, Seagrove.Mosinee );
   modify_field( Maddock.Earlsboro, Seagrove.Hooker );
   modify_field( Maddock.Monowi, Seagrove.Paullina );
   modify_field( Cushing.Genola, Pinecreek[0].Elysburg );
   modify_field( Maddock.Telma, Seagrove.Trevorton );



   modify_field( Maddock.GunnCity, Bladen.Ardsley );
   modify_field( Maddock.Nevis, Bladen.Livengood );
}

table Sigsbee {
   reads {
      Notus.Salamatof : exact;
      Notus.Greer : exact;
      FulksRun.Melba : exact;
      Maddock.Chevak : exact;
   }

   actions {
      Virgil;
      Canfield;
   }

   default_action : Canfield();
   size : Konnarock;
}


action Unity() {
   modify_field( Maddock.Delcambre, Kaweah.Telida );
   modify_field( Maddock.Sturgis, Kaweah.Everett);
}

action Mecosta( Lapel ) {
   modify_field( Maddock.Delcambre, Lapel );
   modify_field( Maddock.Sturgis, Kaweah.Everett);
}

action Woodston() {
   modify_field( Maddock.Delcambre, Pinecreek[0].Kinsley );
   modify_field( Maddock.Sturgis, Kaweah.Everett);
}

table Garwood {
   reads {
      Kaweah.Everett : ternary;
      Pinecreek[0] : valid;
      Pinecreek[0].Kinsley : ternary;
   }

   actions {
      Unity;
      Mecosta;
      Woodston;
   }
   size : Newcastle;
}

action Duquoin( Moylan ) {
   modify_field( Maddock.Sturgis, Moylan );
}

action Ekron() {

   modify_field( Maddock.Ghent, 1 );
   modify_field( Belvue.Moark,
                 Tamms );
}

table Tunis {
   reads {
      FulksRun.Sunman : exact;
   }

   actions {
      Duquoin;
      Ekron;
   }
   default_action : Ekron;
   size : Flippen;
}

action Paradis( Kamas, LaSalle, Laketown, PineLawn, Tampa,
                        Mausdale, Poteet ) {
   modify_field( Maddock.Delcambre, Kamas );
   modify_field( Maddock.Billett, Kamas );
   modify_field( Maddock.Absecon, Poteet );
   Wataga(LaSalle, Laketown, PineLawn, Tampa,
                        Mausdale );
}

action Newcomb() {
   modify_field( Maddock.Everest, 1 );
}

table Tilton {
   reads {
      Coqui.Emigrant : exact;
   }

   actions {
      Paradis;
      Newcomb;
   }
   size : Humacao;
}

action Wataga(Grants, Sargent, Harlem, Riley,
                        Barnhill ) {
   modify_field( Ladelle.Christmas, Grants );
   modify_field( Ladelle.Oklee, Sargent );
   modify_field( Ladelle.Viroqua, Harlem );
   modify_field( Ladelle.Bethesda, Riley );
   modify_field( Ladelle.Mullins, Barnhill );
}

action Milam(Janney, Shoreview, Dunnville, Trotwood,
                        Ralph ) {
   modify_field( Maddock.Billett, Kaweah.Telida );
   modify_field( Maddock.Absecon, 1 );
   Wataga(Janney, Shoreview, Dunnville, Trotwood,
                        Ralph );
}

action GlenRose(Godfrey, Westboro, Bammel, Forkville,
                        Larwill, Watters ) {
   modify_field( Maddock.Billett, Godfrey );
   modify_field( Maddock.Absecon, 1 );
   Wataga(Westboro, Bammel, Forkville, Larwill,
                        Watters );
}

action Iberia(Agency, LakeFork, Millstadt, Ontonagon,
                        Webbville ) {
   modify_field( Maddock.Billett, Pinecreek[0].Kinsley );
   modify_field( Maddock.Absecon, 1 );
   Wataga(Agency, LakeFork, Millstadt, Ontonagon,
                        Webbville );
}

table OldMinto {
   reads {
      Kaweah.Telida : exact;
   }


   actions {
      Calabash;
      Milam;
   }

   size : Hodges;
}

@pragma action_default_only Calabash
table Juniata {
   reads {
      Kaweah.Everett : exact;
      Pinecreek[0].Kinsley : exact;
   }

   actions {
      GlenRose;
      Calabash;
   }

   size : Dowell;
}

table Filer {
   reads {
      Pinecreek[0].Kinsley : exact;
   }


   actions {
      Calabash;
      Iberia;
   }

   size : Otisco;
}

control Kinston {
   apply( Sigsbee ) {
         Virgil {
            apply( Tunis );
            apply( Tilton );
         }
         Canfield {
            if ( not valid(Neshoba) and Kaweah.Wauneta == 1 ) {
               apply( Garwood );
            }
            if ( valid( Pinecreek[ 0 ] ) ) {

               apply( Juniata ) {
                  Calabash {

                     apply( Filer );
                  }
               }
            } else {

               apply( OldMinto );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Longwood {
    width  : 1;
    static : Bowden;
    instance_count : 262144;
}

register Willshire {
    width  : 1;
    static : Dubuque;
    instance_count : 262144;
}

blackbox stateful_alu RioPecos {
    reg : Longwood;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : PortVue.Manning;
}

blackbox stateful_alu Mattapex {
    reg : Willshire;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : PortVue.Lazear;
}

field_list Currie {
    Kaweah.Newfolden;
    Pinecreek[0].Kinsley;
}

field_list_calculation Purdon {
    input { Currie; }
    algorithm: identity;
    output_width: 18;
}

action Lardo() {
    RioPecos.execute_stateful_alu_from_hash(Purdon);
}

action Homeland() {
    Mattapex.execute_stateful_alu_from_hash(Purdon);
}

table Bowden {
    actions {
      Lardo;
    }
    default_action : Lardo;
    size : 1;
}

table Dubuque {
    actions {
      Homeland;
    }
    default_action : Homeland;
    size : 1;
}
#endif

action Kamrar(LasVegas) {
    modify_field(PortVue.Lazear, LasVegas);
}

@pragma  use_hash_action 0
table Dunkerton {
    reads {
       Kaweah.Newfolden : exact;
    }
    actions {
      Kamrar;
    }
    size : 64;
}

action Juneau() {
   modify_field( Maddock.CruzBay, Kaweah.Telida );
   modify_field( Maddock.Ozona, 0 );
}

table Rockdale {
   actions {
      Juneau;
   }
   size : 1;
}

action Alnwick() {
   modify_field( Maddock.CruzBay, Pinecreek[0].Kinsley );
   modify_field( Maddock.Ozona, 1 );
}

table RyanPark {
   actions {
      Alnwick;
   }
   size : 1;
}

control Ashburn {
   if ( valid( Pinecreek[ 0 ] ) ) {
      apply( RyanPark );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Kaweah.Conneaut == 1 ) {
         apply( Bowden );
         apply( Dubuque );
      }
#endif
   } else {
      apply( Rockdale );
      if( Kaweah.Conneaut == 1 ) {
         apply( Dunkerton );
      }
   }
}




field_list WhiteOwl {
   Notus.Salamatof;
   Notus.Greer;
   Notus.Suffern;
   Notus.Calamine;
   Notus.Clearmont;
}

field_list Daisytown {

   FulksRun.Keltys;
   FulksRun.Sunman;
   FulksRun.Melba;
}

field_list Jamesport {
   Philip.Stecker;
   Philip.Broadmoor;
   Philip.Lindy;
   Philip.Jesup;
}

field_list McQueen {
   FulksRun.Sunman;
   FulksRun.Melba;
   Bladen.Ardsley;
   Bladen.Livengood;
}





field_list_calculation Hilbert {
    input {
        WhiteOwl;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Phelps {
    input {
        Daisytown;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Waumandee {
    input {
        Jamesport;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Dubach {
    input {
        McQueen;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Edinburg() {
    modify_field_with_hash_based_offset(Loogootee.Halfa, 0,
                                        Hilbert, 4294967296);
}

action Pekin() {
    modify_field_with_hash_based_offset(Loogootee.Eaton, 0,
                                        Phelps, 4294967296);
}

action Carbonado() {
    modify_field_with_hash_based_offset(Loogootee.Eaton, 0,
                                        Waumandee, 4294967296);
}

action Moraine() {
    modify_field_with_hash_based_offset(Loogootee.Lenexa, 0,
                                        Dubach, 4294967296);
}

table Ossineke {
   actions {
      Edinburg;
   }
   size: 1;
}

control Hawthorn {
   apply(Ossineke);
}

table Frankston {
   actions {
      Pekin;
   }
   size: 1;
}

table Winger {
   actions {
      Carbonado;
   }
   size: 1;
}

control Casnovia {
   if ( valid( FulksRun ) ) {
      apply(Frankston);
   } else {
      if ( valid( Philip ) ) {
         apply(Winger);
      }
   }
}

table Ellicott {
   actions {
      Moraine;
   }
   size: 1;
}

control Arnett {
   if ( valid( Catawissa ) ) {
      apply(Ellicott);
   }
}



action Weehawken() {
    modify_field(Segundo.GlenDean, Loogootee.Halfa);
}

action LaPryor() {
    modify_field(Segundo.GlenDean, Loogootee.Eaton);
}

action Buckeye() {
    modify_field(Segundo.GlenDean, Loogootee.Lenexa);
}

@pragma action_default_only Calabash
@pragma immediate 0
table Monida {
   reads {
      MintHill.valid : ternary;
      Bieber.valid : ternary;
      Atlas.valid : ternary;
      Camden.valid : ternary;
      Burrel.valid : ternary;
      Freeville.valid : ternary;
      Catawissa.valid : ternary;
      FulksRun.valid : ternary;
      Philip.valid : ternary;
      Notus.valid : ternary;
   }
   actions {
      Weehawken;
      LaPryor;
      Buckeye;
      Calabash;
   }
   size: Ishpeming;
}

action Rocklake() {
    modify_field(Segundo.Rhine, Loogootee.Lenexa);
}

@pragma immediate 0
table KawCity {
   reads {
      MintHill.valid : ternary;
      Bieber.valid : ternary;
      Freeville.valid : ternary;
      Catawissa.valid : ternary;
   }
   actions {
      Rocklake;
      Calabash;
   }
   size: Brainard;
}

control Dateland {
   apply(KawCity);
   apply(Monida);
}



counter Bayne {
   type : packets_and_bytes;
   direct : Lecompte;
   min_width: 16;
}

table Lecompte {
   reads {
      Kaweah.Newfolden : exact;
      PortVue.Lazear : ternary;
      PortVue.Manning : ternary;
      Maddock.Everest : ternary;
      Maddock.Meridean : ternary;
      Maddock.Wollochet : ternary;
   }

   actions {
      Challis;
      Calabash;
   }
   default_action : Calabash();
   size : Conger;
}

action Kapowsin() {

   modify_field(Maddock.OakCity, 1 );
   modify_field(Belvue.Moark,
                Keokee);
}







table Ringold {
   reads {
      Maddock.Nooksack : exact;
      Maddock.Emlenton : exact;
      Maddock.Delcambre : exact;
      Maddock.Sturgis : exact;
   }

   actions {
      Hamel;
      Kapowsin;
   }
   default_action : Kapowsin();
   size : Greenbelt;
   support_timeout : true;
}

action Bavaria( Stout ) {
   modify_field( Maddock.Matador, Stout );
}

table Norco {
   reads {
      Maddock.Delcambre : exact;
   }

   actions {
      Bavaria;
      Calabash;
   }

   default_action : Calabash();
   size : Whitten;
}

action Topanga() {
   modify_field( Ladelle.Bechyn, 1 );
}

table Rienzi {
   reads {
      Maddock.Billett : ternary;
      Maddock.McClure : exact;
      Maddock.Novice : exact;
   }
   actions {
      Topanga;
   }
   size: Uniontown;
}

control Neame {
   apply( Lecompte ) {
      Calabash {



         if (Kaweah.Wheeling == 0 and Maddock.Ghent == 0) {
            apply( Ringold );
         }
         apply( Norco );
         apply(Rienzi);
      }
   }
}

field_list Arminto {
    Belvue.Moark;
    Maddock.Nooksack;
    Maddock.Emlenton;
    Maddock.Delcambre;
    Maddock.Sturgis;
}

action Helen() {
   generate_digest(Abraham, Arminto);
}

table Keauhou {
   actions {
      Helen;
   }
   size : 1;
}

control Valencia {
   if (Maddock.OakCity == 1) {
      apply( Keauhou );
   }
}



action Yreka( Deport, ElPortal ) {
   modify_field( Wauregan.Hernandez, Deport );
   modify_field( Langlois.Trammel, ElPortal );
}

@pragma action_default_only Corydon
table Lakota {
   reads {
      Ladelle.Christmas : exact;
      Wauregan.TinCity mask Wimberley : lpm;
   }
   actions {
      Yreka;
      Corydon;
   }
   size : Seabrook;
}

@pragma atcam_partition_index Wauregan.Hernandez
@pragma atcam_number_partitions Seabrook
table Loughman {
   reads {
      Wauregan.Hernandez : exact;
      Wauregan.TinCity mask CatCreek : lpm;
   }

   actions {
      Freeburg;
      Elwood;
      Calabash;
   }
   default_action : Calabash();
   size : Battles;
}

action Gerlach( Elmwood, Malinta ) {
   modify_field( Wauregan.Hatfield, Elmwood );
   modify_field( Langlois.Trammel, Malinta );
}

@pragma action_default_only Calabash
table Royston {


   reads {
      Ladelle.Christmas : exact;
      Wauregan.TinCity : lpm;
   }

   actions {
      Gerlach;
      Calabash;
   }

   size : Hallville;
}

@pragma atcam_partition_index Wauregan.Hatfield
@pragma atcam_number_partitions Hallville
table Ironside {
   reads {
      Wauregan.Hatfield : exact;


      Wauregan.TinCity mask Overlea : lpm;
   }
   actions {
      Freeburg;
      Elwood;
      Calabash;
   }

   default_action : Calabash();
   size : Palmdale;
}

@pragma action_default_only Corydon
@pragma idletime_precision 1
table Midas {

   reads {
      Ladelle.Christmas : exact;
      Roggen.Ringwood : lpm;
   }

   actions {
      Freeburg;
      Elwood;
      Corydon;
   }

   size : Hewitt;
   support_timeout : true;
}

action Maybee( Toccopola, Beechwood ) {
   modify_field( Roggen.Newburgh, Toccopola );
   modify_field( Langlois.Trammel, Beechwood );
}

@pragma action_default_only Calabash
#ifdef PROFILE_DEFAULT
//@pragma stage 2 Wadley
//@pragma stage 3
#endif
table Ramos {
   reads {
      Ladelle.Christmas : exact;
      Roggen.Ringwood : lpm;
   }

   actions {
      Maybee;
      Calabash;
   }

   size : DesPeres;
}

@pragma ways Lilymoor
@pragma atcam_partition_index Roggen.Newburgh
@pragma atcam_number_partitions DesPeres
table Pedro {
   reads {
      Roggen.Newburgh : exact;
      Roggen.Ringwood mask Ugashik : lpm;
   }
   actions {
      Freeburg;
      Elwood;
      Calabash;
   }
   default_action : Calabash();
   size : Wartrace;
}

action Freeburg( Kearns ) {
   modify_field( Langlois.Trammel, Kearns );
}

@pragma idletime_precision 1
table Beltrami {
   reads {
      Ladelle.Christmas : exact;
      Roggen.Ringwood : exact;
   }

   actions {
      Freeburg;
      Elwood;
      Calabash;
   }
   default_action : Calabash();
   size : Encinitas;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
//@pragma stage 2 Lostine
//@pragma stage 3
#endif
table Trail {
   reads {
      Ladelle.Christmas : exact;
      Wauregan.TinCity : exact;
   }

   actions {
      Freeburg;
      Elwood;
      Calabash;
   }
   default_action : Calabash();
   size : Benitez;
   support_timeout : true;
}

action Putnam(Blunt, Collis, Freehold) {
   modify_field(Trenary.Glenvil, Freehold);
   modify_field(Trenary.Dunmore, Blunt);
   modify_field(Trenary.Jerico, Collis);
   modify_field(Trenary.Selby, 1);

   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}

action Lopeno() {
   Challis();
}

action Pawtucket(Glyndon) {
   modify_field(Trenary.Sylvan, 1);
   modify_field(Trenary.Brookwood, Glyndon);
}

action Corydon(Macdona) {
   modify_field( Trenary.Sylvan, 1 );
   modify_field( Trenary.Brookwood, 9 );
}

table Freetown {
   reads {
      Langlois.Trammel : exact;
   }

   actions {
      Putnam;
      Lopeno;
      Pawtucket;
   }
   size : Shine;
}

action Mendham( Opelousas ) {
   modify_field(Trenary.Sylvan, 1);
   modify_field(Trenary.Brookwood, Opelousas);
}

table Poynette {
   actions {
      Mendham;
   }
   default_action: Mendham(0);
   size : 1;
}

control Baranof {
   if ( Maddock.Kapalua == 0 and Ladelle.Bechyn == 1 ) {
      if ( ( Ladelle.Oklee == 1 ) and ( Maddock.Earlsboro == 1 ) ) {
         apply( Beltrami ) {
            Calabash {
               apply( Ramos ) {
                  Maybee {
                     apply( Pedro );
                  }
                  Calabash {
                     apply( Midas );
                  }
               }
            }
         }
      } else if ( ( Ladelle.Viroqua == 1 ) and ( Maddock.Monowi == 1 ) ) {
         apply( Trail ) {
            Calabash {
               apply( Royston ) {
                  Gerlach {
                     apply( Ironside );
                  }
                  Calabash {

                     apply( Lakota ) {
                        Yreka {
                           apply( Loughman );
                        }
                     }
                  }
               }
            }
         }
      } else if( Maddock.Absecon == 1 ) {
         apply( Poynette );
      }
   }
}

control Harriston {
   if( Langlois.Trammel != 0 ) {
      apply( Freetown );
   }
}

action Elwood( Oketo ) {
   modify_field( Langlois.Baird, Oketo );
}

field_list Chantilly {
   Segundo.Rhine;
}

field_list_calculation Weinert {
    input {
        Chantilly;
    }
    algorithm : identity;
    output_width : 66;
}

action_selector Stoystown {
   selection_key : Weinert;
   selection_mode : resilient;
}

action_profile Loris {
   actions {
      Freeburg;
   }
   size : Harviell;
   dynamic_action_selection : Stoystown;
}

@pragma selector_max_group_size 256
table Purley {
   reads {
      Langlois.Baird : exact;
   }
   action_profile : Loris;
   size : Milesburg;
}

control Shanghai {
   if ( Langlois.Baird != 0 ) {
      apply( Purley );
   }
}



field_list Christina {
   Segundo.GlenDean;
}

field_list_calculation Elsmere {
    input {
        Christina;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Churchill {
    selection_key : Elsmere;
    selection_mode : resilient;
}

action Waukegan(CityView) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, CityView);
}

action_profile Quivero {
    actions {
        Waukegan;
        Calabash;
    }
    size : Nunnelly;
    dynamic_action_selection : Churchill;
}

table Strasburg {
   reads {
      Trenary.Arredondo : exact;
   }
   action_profile: Quivero;
   size : Virgilina;
}

control Wrenshall {
   if ((Trenary.Arredondo & 0x2000) == 0x2000) {
      apply(Strasburg);
   }
}



action Calumet() {
   modify_field(Trenary.Dunmore, Maddock.McClure);
   modify_field(Trenary.Jerico, Maddock.Novice);
   modify_field(Trenary.Campton, Maddock.Nooksack);
   modify_field(Trenary.RoseBud, Maddock.Emlenton);
   modify_field(Trenary.Glenvil, Maddock.Delcambre);
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
   invalidate( ig_intr_md_for_tm.ucast_egress_port );
#endif
}

table Parkville {
   actions {
      Calumet;
   }
   default_action : Calumet();
   size : 1;
}

control BlueAsh {
   apply( Parkville );
}

action Dixie() {
   modify_field(Trenary.Tilghman, 1);
   modify_field(Trenary.Tabler, 1);

   bit_or(ig_intr_md_for_tm.copy_to_cpu, Maddock.Absecon, Seagrove.Swaledale);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Trenary.Glenvil);
}

action Moquah() {
}



@pragma ways 1
table Maljamar {
   reads {
      Trenary.Dunmore : exact;
      Trenary.Jerico : exact;
   }
   actions {
      Dixie;
      Moquah;
   }
   default_action : Moquah;
   size : 1;
}

action HydePark() {
   modify_field(Trenary.Poland, 1);
   modify_field(Trenary.PawCreek, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Trenary.Glenvil, McIntyre);
}

table Foster {
   actions {
      HydePark;
   }
   default_action : HydePark;
   size : 1;
}

action Horsehead() {
   modify_field(Trenary.Gonzalez, 1);
   modify_field(Trenary.Tabler, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Trenary.Glenvil);
}

table FoxChase {
   actions {
      Horsehead;
   }
   default_action : Horsehead();
   size : 1;
}

action Kaluaaha(Onawa) {
   modify_field(Trenary.Jefferson, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Onawa);
   modify_field(Trenary.Arredondo, Onawa);
}

action DelMar(Kalkaska) {
   modify_field(Trenary.Poland, 1);
   modify_field(Trenary.Ackley, Kalkaska);
}

action Eastover() {
}

table Lampasas {
   reads {
      Trenary.Dunmore : exact;
      Trenary.Jerico : exact;
      Trenary.Glenvil : exact;
   }

   actions {
      Kaluaaha;
      DelMar;
      Eastover;
   }
   default_action : Eastover();
   size : Parmelee;
}

control Pineville {
   if (Maddock.Kapalua == 0 and not valid(Neshoba) ) {
      apply(Lampasas) {
         Eastover {
            apply(Maljamar) {
               Moquah {
                  if ((Trenary.Dunmore & 0x010000) == 0x010000) {
                     apply(Foster);
                  } else {
                     apply(FoxChase);
                  }
               }
            }
         }
      }
   }
}

action Riverwood() {
   modify_field(Maddock.Elmore, 1);
   Challis();
}

table Catawba {
   actions {
      Riverwood;
   }
   default_action : Riverwood;
   size : 1;
}

control Weimar {
   if (Maddock.Kapalua == 0) {
      if ((Trenary.Selby==0) and (Maddock.SomesBar==0) and (Maddock.Durant==0) and (Maddock.Sturgis==Trenary.Arredondo)) {
         apply(Catawba);
      } else {
         Wrenshall();
      }
   }
}

action Dairyland(Bratenahl) {
    modify_field(ig_intr_md_for_tm.level2_exclusion_id, Bratenahl);
}

table Benonine {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Dairyland;
    }
    size : 512;
}

control Hiwasse {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Benonine);
   }
}



action Holyrood( Angle ) {
   modify_field( Trenary.Darby, Angle );
}

action Oklahoma() {
   modify_field( Trenary.Darby, Trenary.Glenvil );
}

table Tolley {
   reads {
      eg_intr_md.egress_port : exact;
      Trenary.Glenvil : exact;
   }

   actions {
      Holyrood;
      Oklahoma;
   }
   default_action : Oklahoma;
   size : Moultrie;
}

control Prunedale {
   apply( Tolley );
}



action Macksburg( Hallwood, Dumas ) {
   modify_field( Trenary.LakeHart, Hallwood );
   modify_field( Trenary.Otego, Dumas );
}

table Madras {
   reads {
      Trenary.Careywood : exact;
   }

   actions {
      Macksburg;
   }
   size : Mattoon;
}

action Coyote() {
   modify_field( Trenary.Kalvesta, 1 );
   modify_field( Trenary.Careywood, Armstrong );
}

action Finlayson() {
   modify_field( Trenary.Kalvesta, 1 );
   modify_field( Trenary.Careywood, PeaRidge );
}

table Mapleton {
   reads {
      Trenary.Gervais : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Coyote;
      Finlayson;
   }
   default_action : Calabash();
   size : 16;
}

action Newhalem(Maytown, Uncertain, Kinter, Bowers) {
   modify_field( Trenary.Punaluu, Maytown );
   modify_field( Trenary.Neosho, Uncertain );
   modify_field( Trenary.Ballwin, Kinter );
   modify_field( Trenary.Pownal, Bowers );
}

table Vandling {
   reads {
        Trenary.Hapeville : exact;
   }
   actions {
      Newhalem;
   }
   size : Amity;
}

action Isabela() {
   no_op();
}

action Thalia() {
   modify_field( Notus.Clearmont, Pinecreek[0].McDavid );
   remove_header( Pinecreek[0] );
}

table Ankeny {
   actions {
      Thalia;
   }
   default_action : Thalia;
   size : Kennebec;
}

action Sallisaw() {
   no_op();
}

action Elsey() {
   add_header( Pinecreek[ 0 ] );
   modify_field( Pinecreek[0].Kinsley, Trenary.Darby );
   modify_field( Pinecreek[0].McDavid, Notus.Clearmont );
   modify_field( Pinecreek[0].Storden, Cushing.Roscommon );
   modify_field( Pinecreek[0].Elysburg, Cushing.Genola );
   modify_field( Notus.Clearmont, Talbert );
}



table Havana {
   reads {
      Trenary.Darby : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Sallisaw;
      Elsey;
   }
   default_action : Elsey;
   size : Blueberry;
}

action Hesler() {
   modify_field(Notus.Salamatof, Trenary.Dunmore);
   modify_field(Notus.Greer, Trenary.Jerico);
   modify_field(Notus.Suffern, Trenary.LakeHart);
   modify_field(Notus.Calamine, Trenary.Otego);
}

action Cowden() {
   Hesler();
   add_to_field(FulksRun.Mustang, -1);
   modify_field(FulksRun.Achille, Cushing.Lubeck);
}

action Essex() {
   Hesler();
   add_to_field(Philip.Marshall, -1);
   modify_field(Philip.Pathfork, Cushing.Lubeck);
}

action Derita() {
   modify_field(FulksRun.Achille, Cushing.Lubeck);
}

action Blackwood() {
   modify_field(Philip.Pathfork, Cushing.Lubeck);
}

action Kirley() {
   Elsey();
}

action Termo( Cordell, WebbCity, Verdemont, Davie ) {
   add_header( Hanamaulu );
   modify_field( Hanamaulu.Salamatof, Cordell );
   modify_field( Hanamaulu.Greer, WebbCity );
   modify_field( Hanamaulu.Suffern, Verdemont );
   modify_field( Hanamaulu.Calamine, Davie );
   modify_field( Hanamaulu.Clearmont, FifeLake );

   add_header( Neshoba );
   modify_field( Neshoba.Moodys, Trenary.Punaluu );
   modify_field( Neshoba.Eastman, Trenary.Neosho );
   modify_field( Neshoba.Scarville, Trenary.Ballwin );
   modify_field( Neshoba.Levasy, Trenary.Pownal );
   modify_field( Neshoba.Anawalt, Trenary.Brookwood );
}

action Nashoba() {
   remove_header( Coqui );
   remove_header( Catawissa );
   remove_header( Bladen );
   copy_header( Notus, Burrel );
   remove_header( Burrel );
   remove_header( FulksRun );
}

action Maida() {
   remove_header( Hanamaulu );
   remove_header( Neshoba );
}

action Jacobs() {
   Nashoba();
   modify_field(Atlas.Achille, Cushing.Lubeck);
}

action ElRio() {
   Nashoba();
   modify_field(Camden.Pathfork, Cushing.Lubeck);
}

table Slovan {
   reads {
      Trenary.Shelby : exact;
      Trenary.Careywood : exact;
      Trenary.Selby : exact;
      FulksRun.valid : ternary;
      Philip.valid : ternary;
      Atlas.valid : ternary;
      Camden.valid : ternary;
   }

   actions {
      Cowden;
      Essex;
      Derita;
      Blackwood;
      Kirley;
      Termo;
      Maida;
      Nashoba;
      Jacobs;
      ElRio;
   }
   size : LeeCity;
}

control Heeia {
   apply( Ankeny );
}

control Loysburg {
   apply( Havana );
}

control McGovern {
   apply( Mapleton ) {
      Calabash {
         apply( Madras );
      }
   }
   apply( Vandling );
   apply( Slovan );
}



field_list Mendocino {
    Belvue.Moark;
    Maddock.Delcambre;
    Burrel.Suffern;
    Burrel.Calamine;
    FulksRun.Sunman;
}

action Nanson() {
   generate_digest(Abraham, Mendocino);
}

table Whitefish {
   actions {
      Nanson;
   }

   default_action : Nanson;
   size : 1;
}

control Pearl {
   if (Maddock.Ghent == 1) {
      apply(Whitefish);
   }
}



action Henning() {
   modify_field( Cushing.Roscommon, Kaweah.Aldan );
}

action Doddridge() {
   modify_field( Cushing.Roscommon, Pinecreek[0].Storden );
   modify_field( Maddock.Sitka, Pinecreek[0].McDavid );
}

action Higginson() {
   modify_field( Cushing.Lubeck, Kaweah.Corinth );
}

action Baltimore() {
   modify_field( Cushing.Lubeck, Roggen.Covington );
}

action Spenard() {
   modify_field( Cushing.Lubeck, Wauregan.Aurora );
}

action Bellport( McMurray, Alvord ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, McMurray );
   modify_field( ig_intr_md_for_tm.qid, Alvord );
}

table Leonore {
   reads {
     Maddock.Telma : exact;
   }

   actions {
     Henning;
     Doddridge;
   }

   size : Carlson;
}

table Finley {
   reads {
     Maddock.Earlsboro : exact;
     Maddock.Monowi : exact;
   }

   actions {
     Higginson;
     Baltimore;
     Spenard;
   }

   size : Joseph;
}

table Newpoint {
   reads {
      Kaweah.Wapinitia : ternary;
      Kaweah.Aldan : ternary;
      Cushing.Roscommon : ternary;
      Cushing.Lubeck : ternary;
      Cushing.Abernant : ternary;
   }

   actions {
      Bellport;
   }

   size : Stockton;
}

action Corry( CoalCity, Hahira ) {
   bit_or( Cushing.Albin, Cushing.Albin, CoalCity );
   bit_or( Cushing.Fairchild, Cushing.Fairchild, Hahira );
}

table Theta {
   actions {
      Corry;
   }
   default_action : Corry(0, 0);
   size : Petoskey;
}

action Qulin( Greenland ) {
   modify_field( Cushing.Lubeck, Greenland );
}

action Ribera( Covina ) {
   modify_field( Cushing.Roscommon, Covina );
}

action Margie( Alsen, Garcia ) {
   modify_field( Cushing.Roscommon, Alsen );
   modify_field( Cushing.Lubeck, Garcia );
}

table Norias {
   reads {
      Kaweah.Wapinitia : exact;
      Cushing.Albin : exact;
      Cushing.Fairchild : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }

   actions {
      Qulin;
      Ribera;
      Margie;
   }

   size : RiceLake;
}

control SanJon {
   apply( Leonore );
   apply( Finley );
}

control Nisland {
   apply( Newpoint );
}

control Aptos {
   apply( Theta );
   apply( Norias );
}



action Tontogany( Roswell ) {
   modify_field( Trenary.Brookwood, Roswell );
   modify_field( Cushing.Kelvin, 1 );
}

action Antoine( Hargis, Redden ) {
   Tontogany( Hargis );
   modify_field( ig_intr_md_for_tm.qid, Redden );
}

table Westline {
   reads {
      Trenary.Sylvan : ternary;
      ig_intr_md_for_tm.copy_to_cpu : ternary;
      Trenary.Brookwood : ternary;
      Maddock.Earlsboro : ternary;
      Maddock.Monowi : ternary;
      Maddock.Sitka : ternary;
      Maddock.Deferiet : ternary;
      Maddock.Vanzant : ternary;
      Trenary.Selby : ternary;
      Bladen.Livengood : ternary;
   }

   actions {
      Tontogany;
      Antoine;
   }

   size : Servia;
}

meter Neoga {
   type : packets;
   static : AukeBay;
   instance_count : Donald;
}

action Oakridge(Yemassee) {
   execute_meter( Neoga, Yemassee, ig_intr_md_for_tm.packet_color );
}

table AukeBay {
   reads {
      Kaweah.Newfolden mask 0x3f : exact;
      Trenary.Brookwood : exact;
   }
   actions {
      Oakridge;
   }
   size : Caputa;
}

control Baskett {
   if ( Kaweah.Conneaut != 0 ) {
      apply( Westline );
   }
}

control Armijo {

    if ( (
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x1 ) == 0 ) ) and ( Trenary.Sylvan == 1 ) ) or
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x2 ) == 0 ) ) and ( ig_intr_md_for_tm.copy_to_cpu == 1 ) )
         ) and
         ( Cushing.Kelvin == 1 ) ) {
      apply( AukeBay );
   }
}



action Parnell( Stambaugh ) {
   modify_field( Trenary.Gervais, Earlimart );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Stambaugh );
   modify_field( Trenary.Hapeville, ig_intr_md.ingress_port );
}

action Wynnewood( Ottertail ) {
   modify_field( Trenary.Gervais, Preston );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Ottertail );
   modify_field( Trenary.Hapeville, ig_intr_md.ingress_port );
}

action Raritan() {
   modify_field( Trenary.Gervais, Earlimart );
}

action Placid() {
   modify_field( Trenary.Gervais, Preston );
   modify_field( Trenary.Hapeville, ig_intr_md.ingress_port );
}

@pragma ternary 1
table Council {
   reads {
      Trenary.Sylvan : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      Ladelle.Bechyn : exact;
      Kaweah.Wauneta : ternary;
      Trenary.Brookwood : ternary;
   }

   actions {
      Parnell;
      Wynnewood;
      Raritan;
      Placid;
   }
   size : Burmester;
}

control Salix {
   apply( Council );
}




counter Balfour {
   type : packets_and_bytes;
   instance_count : Komatke;

   min_width : 128;


}

action Tocito( Silva ) {
   count( Balfour, Silva );
}

table Abernathy {
   reads {
      eg_intr_md.egress_port mask 0x7f: exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }

   actions {
     Tocito;
   }

   size : Komatke;
}

control Glentana {
   apply( Abernathy );
}



action Millstone()
{



   Challis();
}

action Magnolia()
{
   modify_field(Trenary.Shelby, RedHead);
   bit_or(Trenary.Arredondo, 0x2000, Neshoba.Levasy);
}

action Bernice( Rotonda ) {
   modify_field(Trenary.Shelby, RedHead);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Rotonda);
   modify_field(Trenary.Arredondo, Rotonda);
}

table Sopris {
   reads {
      Neshoba.Moodys : exact;
      Neshoba.Eastman : exact;
      Neshoba.Scarville : exact;
      Neshoba.Levasy : exact;
   }

   actions {
      Magnolia;
      Bernice;
      Millstone;
   }
   default_action : Millstone();
   size : Amity;
}

control Ponder {
   apply( Sopris );
}



action Vibbard( Elihu, Broussard, Attalla, Hartwick ) {
   modify_field( Woodfords.LeeCreek, Elihu );
   modify_field( Pinta.Barwick, Attalla );
   modify_field( Pinta.Roberta, Broussard );
   modify_field( Pinta.Nestoria, Hartwick );
}

table Southdown {
   reads {
     Roggen.Ringwood : exact;
     Maddock.Billett : exact;
   }

   actions {
      Vibbard;
   }
  size : Ovett;
}

action Fairmount(Fordyce, RioLinda, Kaanapali) {
   modify_field( Pinta.Roberta, Fordyce );
   modify_field( Pinta.Barwick, RioLinda );
   modify_field( Pinta.Nestoria, Kaanapali );
}

table Lasker {
   reads {
     Roggen.Lambert : exact;
     Woodfords.LeeCreek : exact;
   }
   actions {
      Fairmount;
   }
   size : Hebbville;
}

action Grottoes( Indios, Husum, Florala ) {
   modify_field( Scottdale.Balmville, Indios );
   modify_field( Scottdale.Cortland, Husum );
   modify_field( Scottdale.Caspian, Florala );
}

table Anniston {


   reads {
     Trenary.Dunmore : exact;
     Trenary.Jerico : exact;
     Trenary.Glenvil : exact;
   }
   actions {
      Grottoes;
   }
   size : Shasta;
}

action Bannack() {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Segundo.GlenDean );
   modify_field( Trenary.Tabler, 1 );
}

action Nahunta( Gratis ) {
   Bannack();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Pinta.Roberta );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Gratis, Pinta.Nestoria );
}

action Florahome( Despard ) {
   Bannack();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Scottdale.Balmville );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Despard, Scottdale.Caspian );
}

action Gasport( TenSleep ) {
   Bannack();
   add( ig_intr_md_for_tm.mcast_grp_a, Trenary.Glenvil,
        McIntyre );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, TenSleep );
}

action Lutsen() {
   modify_field( Trenary.Coverdale, 1 );
}

table Panaca {
   reads {
     Pinta.Barwick : ternary;
     Pinta.Roberta : ternary;
     Scottdale.Balmville : ternary;
     Scottdale.Cortland : ternary;
     Maddock.Deferiet :ternary;
     Maddock.SomesBar:ternary;
   }
   actions {
      Nahunta;
      Florahome;
      Gasport;
      Lutsen;
   }
   size : 32;
}

control Harts {
   if( Maddock.Kapalua == 0 and
       Ladelle.Bethesda == 1 and
       Maddock.Alcester == 1 ) {
      apply( Southdown );
   }
}

control Almedia {
   if( Woodfords.LeeCreek != 0 ) {
      apply( Lasker );
   }
}


control Grayland {
   if( Maddock.Kapalua == 0 and Maddock.SomesBar==1 ) {
      apply( Anniston );
   }
}

control Petrey {


   if( Maddock.SomesBar == 1 ) {
      apply(Panaca);
   }
}




action Manilla( Richlawn, Cornudas ) {
   modify_field( Trenary.Glenvil, Richlawn );


   modify_field( Trenary.Selby, Cornudas );
}

action Elvaston() {

   drop();
}

table LaHoma {
   reads {
     eg_intr_md.egress_rid: exact;
   }

   actions {
      Manilla;
   }
   default_action: Elvaston;
   size : Arapahoe;
}


control Trego {


   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(LaHoma);
   }
}
#ifdef Richvale



action Thayne() {
   modify_field( Keyes.Adamstown, Maddock.Deferiet );
   modify_field( Keyes.Callao, Roggen.Covington );
   modify_field( Keyes.Rankin, Maddock.Vanzant );
   bit_xor( Keyes.Ravinia, Maddock.Scherr, 1 );
}

action Faith() {
   modify_field( Keyes.Adamstown, Maddock.Deferiet );
   modify_field( Keyes.Callao, Wauregan.Aurora );
   modify_field( Keyes.Rankin, Maddock.Vanzant );
   bit_xor( Keyes.Ravinia, Maddock.Scherr, 1 );
}

action Monico( Lowes ) {
   Thayne();
   modify_field( Keyes.Brownson, Lowes );
}

action Robbs( Daleville ) {
   Faith();
   modify_field( Keyes.Brownson, Daleville );
}

table Quinnesec {
   reads {
     Roggen.Lambert : ternary;
   }
   actions {
      Monico;
   }
   default_action : Thayne;
  size : Anita;
}

table Silesia {
   reads {
     Wauregan.Sublett : ternary;
   }
   actions {
      Robbs;
   }
   default_action : Faith;
  size : Quinhagak;
}

action Farragut( Hammett ) {
   modify_field( Keyes.Alakanuk, Hammett );
}


table Devers {
   reads {
     Roggen.Ringwood : ternary;
   }
   actions {
      Farragut;
   }
  size : Fouke;
}

table Corfu {
   reads {
     Wauregan.TinCity : ternary;
   }
   actions {
      Farragut;
   }
  size : NewTrier;
}

action Laurelton( Hayward ) {
   modify_field( Keyes.Arvana, Hayward );
}


table Ocoee {
   reads {
     Maddock.GunnCity : ternary;
   }
   actions {
      Laurelton;
   }
  size : Madill;
}

action Gannett( Foristell ) {
   modify_field( Keyes.RushCity, Foristell );
}


table Burrton {
   reads {
     Maddock.Nevis : ternary;
   }
   actions {
      Gannett;
   }
  size : Shabbona;
}



action DeGraff( Tallevast ) {
   modify_field( Keyes.Hollymead, Tallevast );
}
action Slagle( Farlin ) {
   modify_field( Keyes.Hollymead, Farlin );
}

action Andrade(){
}

table Vieques {
   reads {
     Maddock.Earlsboro : exact;
     Maddock.Monowi : exact;
     Maddock.Twodot : exact;
     Maddock.Billett : exact;
   }
   actions {
      DeGraff;
      Andrade;
   }
   default_action : Andrade();
  size : Yukon;
}

table OldGlory {
   reads {
     Maddock.Earlsboro : exact;
     Maddock.Monowi : exact;
     Maddock.Twodot : exact;
     Kaweah.Everett : exact;
   }
   actions {
      Slagle;
   }
  size : Amherst;
}

control Kenney {
   if( Maddock.Earlsboro == 1 ) {
      apply( Quinnesec );
      apply( Devers );
   } else if( Maddock.Monowi == 1 ) {
      apply( Silesia );
      apply( Corfu );
   }

   if( ( Maddock.Chevak != Sodaville and Maddock.Fayette == 1 ) or
       ( Maddock.Chevak == Sodaville and Bladen.valid == 1 ) ) {
      apply( Ocoee );
      if( Maddock.Deferiet != Pumphrey ){
         apply( Burrton );
      }
   }

   apply( Vieques ) {
      Andrade {
         apply( OldGlory );
      }
   }
}

action Alstown( Ericsburg ) {

#ifndef BMV2TOFINO
       max( Allgood.Tavistock, Allgood.Tavistock, Ericsburg );
#endif
}
action Emajagua( Hershey ) {

#ifndef BMV2TOFINO
       max( Fairborn.Tavistock, Fairborn.Tavistock, Hershey );
#endif
}
action Dobbins() {

#ifndef BMV2TOFINO
       max( Allgood.Tavistock, Fairborn.Tavistock, Allgood.Tavistock );
#endif
}

action Onslow( Enfield, Coventry, Bloomburg, SantaAna, Mayview, Monaca, Resaca, Samantha,
                    McBrides, Henry ) {
   bit_and( Barksdale.Brownson, Keyes.Brownson, Enfield );
   bit_and( Barksdale.Alakanuk, Keyes.Alakanuk, Coventry );
   bit_and( Barksdale.Arvana, Keyes.Arvana, Bloomburg );
   bit_and( Barksdale.RushCity, Keyes.RushCity, SantaAna );
   bit_and( Barksdale.Adamstown, Keyes.Adamstown, Mayview );
   bit_and( Barksdale.Callao, Keyes.Callao, Monaca );
   bit_and( Barksdale.Rankin, Keyes.Rankin, Resaca );
   bit_and( Barksdale.Ashtola, Keyes.Ashtola, Samantha );
   bit_and( Barksdale.Ravinia, Keyes.Ravinia, McBrides );
   bit_and( Barksdale.Yakutat, Keyes.Yakutat, Henry );
}

@pragma ways 1
table Eldora {
   reads {
     Keyes.Hollymead : exact;
     Keyes.Brownson : exact;
     Keyes.Alakanuk : exact;
     Keyes.Arvana : exact;
     Keyes.RushCity : exact;
     Keyes.Adamstown : exact;
     Keyes.Callao : exact;
     Keyes.Rankin : exact;
     Keyes.Ashtola : exact;
     Keyes.Ravinia : exact;
     Keyes.Yakutat : exact;
   }

   actions {
      Alstown;
  }
  size : Holcomb;
}

control Colonias {
   apply( Eldora );
}


#define Bemis( Rowlett, Wenona )         \
   table Catskill ## Rowlett {                \
      reads {                            \
         Keyes.Hollymead : exact;      \
         Barksdale.Brownson : exact;      \
         Barksdale.Alakanuk : exact;      \
         Barksdale.Arvana : exact;  \
         Barksdale.RushCity : exact;  \
         Barksdale.Adamstown : exact;    \
         Barksdale.Callao : exact;     \
         Barksdale.Rankin : exact;      \
         Barksdale.Ashtola : exact;    \
         Barksdale.Ravinia : exact;   \
         Barksdale.Yakutat : exact;   \
      }                                  \
                                         \
      actions {                          \
         Alstown;              \
     }                                   \
     size : Wenona ;                          \
   }                                     \
                                         \
   table Domingo ## Rowlett {      \
      reads {                            \
        Keyes.Hollymead : exact;       \
      }                                  \
      actions {                          \
         Onslow;                    \
      }                                  \
     size : Mondovi;    \
   }                                     \
                                         \
   control Lubec ## Rowlett {         \
      apply( Domingo ## Rowlett ); \
   }                                     \
                                         \
   control Alamosa ## Rowlett {            \
      apply( Catskill ## Rowlett );           \
   }


#define Camilla( Rowlett, Wenona )    \
   table Goulds ## Rowlett {            \
      reads {                            \
         Keyes.Hollymead : exact;      \
         Keyes.Brownson : ternary;      \
         Keyes.Alakanuk : ternary;      \
         Keyes.Arvana : ternary;  \
         Keyes.RushCity : ternary;  \
         Keyes.Adamstown : ternary;    \
         Keyes.Callao : ternary;     \
         Keyes.Rankin : ternary;      \
         Keyes.Ashtola : ternary;    \
         Keyes.Ravinia : ternary;   \
         Keyes.Yakutat : ternary;   \
      }                                  \
                                         \
      actions {                          \
         Emajagua;          \
     }                                   \
     size : Wenona ;                          \
   }                                     \
                                         \
   control Woodsboro ## Rowlett {        \
      apply( Goulds ## Rowlett );       \
   }

@pragma ways 1
Bemis( 2, Coolin )
@pragma ways 1
Bemis( 3, Raven )
@pragma ways 1
Bemis( 4, CeeVee )
@pragma ways 1
Bemis( 5, Bellamy )

Camilla( 1, Oconee )

#define Connell( Rowlett ) Alamosa ## Rowlett()
#define Ivyland( Rowlett ) Lubec ## Rowlett()

table Fabens {
   actions {
      Dobbins;
   }
   default_action : Dobbins;
   size : 1;
}

control Louviers {
   apply( Fabens );
}

action Woodward() {
}

action MoonRun() {
   modify_field( Trenary.Kalvesta, 1 );
}

action Harleton() {
   modify_field( Maddock.Kapalua, 1 );
}

action Haworth() {

   modify_field( Maddock.Kapalua, 1 );
   modify_field( Trenary.Sylvan, 1 );
}

table Paxtonia {
   reads {





     Allgood.Tavistock mask 0x00018000 : ternary;
   }

   actions {
      Woodward;
      MoonRun;
      Harleton;
      Haworth;
   }
  size : 16;
}

control Dassel {
   apply( Paxtonia );
}
#endif
control ingress {

   Coamo();

   if( Kaweah.Conneaut != 0 ) {

      Lublin();
   }

   Kinston();

   if( Kaweah.Conneaut != 0 ) {
      Ashburn();


      Neame();
   }

   Hawthorn();
#ifdef Richvale
   Kenney();
   Colonias();
   Ivyland( 2 );
#endif


   Casnovia();
   Arnett();

   if( Kaweah.Conneaut != 0 ) {

      Baranof();
   }
#ifdef Richvale
   Connell( 2 );
   Ivyland( 3 );
#endif

   Dateland();
   SanJon();


   if( Kaweah.Conneaut != 0 ) {
      Shanghai();
   }
#ifdef Richvale
   Connell( 3 );
   Ivyland( 4 );
#endif

   BlueAsh();
   Harts();


   if( Kaweah.Conneaut != 0 ) {
      Harriston();
   }
   Almedia();
#ifdef Richvale
   Connell( 4 );
#endif




   Pearl();
   Valencia();
   if( Trenary.Sylvan == 0 ) {
      if( valid( Neshoba ) ) {
         Ponder();
      } else {
         Grayland();
         Pineville();
      }
   }
   if( not valid( Neshoba ) ) {
      Nisland();
   }


   if( Trenary.Sylvan == 0 ) {
      Weimar();
   }

   Baskett();

   if( Trenary.Sylvan == 0 ) {
      Petrey();
   }

   if( Kaweah.Conneaut != 0 ) {
      Aptos();
   }


   Armijo();


   if( valid( Pinecreek[0] ) ) {
      Heeia();
   }

   if( Trenary.Sylvan == 0 ) {
      Hiwasse();
   }



   Salix();
#ifdef Richvale
   Dassel();
#endif
}

control egress {
   Trego();
   Prunedale();
   McGovern();

   if( ( Trenary.Kalvesta == 0 ) and ( Trenary.Shelby != RedHead ) ) {
      Loysburg();
   }
   Glentana();
}
