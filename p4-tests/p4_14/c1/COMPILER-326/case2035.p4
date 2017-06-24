// BUILD: p4c-tofino --verbose 2 --placement tp4 --no-dead-code-elimination --o bf_obfuscate_arista_switch --p4-name=obfuscate_arista_switch --pipe-mgr-path=pipe_mgr/ --mc-mgr-path=mc_mgr/ --gen-exm-test-pd -S --p4-prefix=p4_obfuscate_arista_switch -DPROFILE_DEFAULT --no-phv-swap  Switch.OBFUSCATED.p4


// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 110134







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>





#ifndef Meridean
#define Meridean

header_type Godfrey {
	fields {
		Gassoway : 16;
		Florahome : 16;
		Slick : 8;
		Topton : 8;
		Waldport : 8;
		Kensett : 8;
		Hagewood : 1;
		Bostic : 1;
		Higgins : 1;
		Jenkins : 1;
		Bechyn : 1;
		Makawao : 3;
	}
}

header_type Guadalupe {
	fields {
		Salduro : 24;
		HydePark : 24;
		Sandstone : 24;
		Ivyland : 24;
		Hilger : 16;
		Sudden : 12;
		MuleBarn : 16;
		Lyman : 16;
		Prunedale : 16;
		LoneJack : 8;
		Goldsmith : 8;
		Vining : 6;
		Kenmore : 1;
		Paxtonia : 1;
		Calabash : 12;
		Ferry : 2;
		Pinole : 1;
		Crystola : 1;
		Newborn : 1;
		Blanding : 1;
		Rumson : 1;
		KawCity : 1;
		Omemee : 1;
		Escatawpa : 1;
		Mackville : 1;
		Clarinda : 1;
		Pinto : 1;
		Harvard : 1;
		Hagaman : 1;
		Ashwood : 1;
		Helotes : 3;
		Donald : 16;
	}
}

header_type WolfTrap {
	fields {
		Branson : 24;
		Rehoboth : 24;
		Waialee : 24;
		Sedan : 24;
		Magma : 24;
		Kempton : 24;
		Montello : 12;
		Deport : 16;
		Holyoke : 16;
		Hannah : 16;
		Ashburn : 12;
		Skiatook : 3;
		Basye : 3;
		MontIda : 1;
		Mankato : 1;
		Strevell : 1;
		Earling : 1;
		Asharoken : 1;
		Westvaco : 1;
		Waterman : 1;
		Miller : 1;
		Boistfort : 8;
		Temple : 1;
		Rendville : 1;
	}
}


header_type Fristoe {
	fields {
		Camino : 8;
		Tappan : 1;
		Narka : 1;
		Chackbay : 1;
		Glennie : 1;
		Belview : 1;
		Troutman : 1;
	}
}

header_type Badger {
	fields {
		Langlois : 32;
		Yreka : 32;
		Picayune : 6;
		Wyman : 16;
	}
}

header_type Gallinas {
	fields {
		Caulfield : 128;
		Lepanto : 128;
		Amory : 20;
		Lutsen : 8;
		Lovelady : 11;
		Green : 8;
		Winfall : 13;
	}
}

header_type Dassel {
	fields {
		Brohard : 14;
		Tomato : 1;
		Calcium : 12;
		Kinsey : 1;
		Mattoon : 1;
		Despard : 6;
		Lindsborg : 2;
		Palouse : 6;
		Mendon : 3;
	}
}

header_type BigFork {
	fields {
		Moquah : 1;
		Oakes : 1;
	}
}

header_type Fouke {
	fields {
		Eclectic : 8;
	}
}

header_type Pridgen {
	fields {
		Haverford : 16;
		Fowlkes : 11;
	}
}

header_type Maytown {
	fields {
		Westway : 32;
		Purves : 32;
		Wenona : 32;
	}
}

header_type Lewis {
	fields {
		Valentine : 32;
		Shoup : 32;
		Cement : 16;
	}
}

header_type Almont {
	fields {
		ElLago : 2;
	}
}

header_type Bellvue {
	fields {
		Menifee : 16;
	}
}

header_type Nenana {
	fields {
		Turkey : 16;
		Alcester : 1;
	}
}

#endif



#ifndef Hinkley
#define Hinkley



header_type Ihlen {
	fields {
		Milwaukie : 24;
		PellLake : 24;
		Bardwell : 24;
		Donner : 24;
		Atlantic : 16;
	}
}



header_type Joiner {
	fields {
		Couchwood : 3;
		Cathay : 1;
		Nichols : 12;
		Hopkins : 16;
	}
}



header_type Skagway {
	fields {
		Hayward : 4;
		Cashmere : 4;
		Comal : 6;
		Enfield : 2;
		Canfield : 16;
		Gerty : 16;
		Hoven : 3;
		Kennebec : 13;
		WebbCity : 8;
		Alsea : 8;
		Arvonia : 16;
		Cedonia : 32;
		Panacea : 32;
	}
}

header_type Barnsdall {
	fields {
		Lewiston : 4;
		Crossett : 6;
		Pineridge : 2;
		Eastover : 20;
		Bayonne : 16;
		Cavalier : 8;
		Bicknell : 8;
		Darco : 128;
		Wilson : 128;
	}
}




header_type AvonLake {
	fields {
		DuPont : 8;
		Johnstown : 8;
		Laneburg : 16;
	}
}

header_type Coulter {
	fields {
		Geeville : 16;
		Dunkerton : 16;
		Grays : 32;
		Vinita : 32;
		Gibbstown : 4;
		Achilles : 4;
		FlatRock : 8;
		Isleta : 16;
		Forman : 16;
		Duelm : 16;
	}
}

header_type Lowden {
	fields {
		Klukwan : 16;
		BigArm : 16;
		Clearco : 16;
		Catawba : 16;
	}
}



header_type Wright {
	fields {
		Sturgis : 16;
		Millbrae : 16;
		Kenova : 8;
		Cartago : 8;
		Cooter : 16;
	}
}

header_type DuQuoin {
	fields {
		LaJara : 48;
		Elkton : 32;
		Whigham : 48;
		Honokahua : 32;
	}
}



header_type Pavillion {
	fields {
		Ojibwa : 1;
		TiffCity : 1;
		Nixon : 1;
		Buras : 1;
		Camanche : 1;
		Creekside : 3;
		Cadley : 5;
		Jenners : 3;
		Millican : 16;
	}
}

header_type Jerico {
	fields {
		Torrance : 24;
		Anthon : 8;
	}
}



header_type Beatrice {
	fields {
		Altadena : 8;
		Needham : 24;
		Ballville : 24;
		Uniontown : 8;
	}
}

#endif



#ifndef Pringle
#define Pringle

parser start {
   return Sawpit;
}

#define Petty        0x8100
#define Lodoga        0x0800
#define Yetter        0x86dd
#define Bridger        0x9100
#define Faulkton        0x8847
#define Oronogo         0x0806
#define Walcott        0x8035
#define Gibbs        0x88cc
#define DelMar        0x8809

#define Youngwood              1
#define Shanghai              2
#define Whitman              4
#define Lefors               6
#define Accomac               17
#define Finlayson                47

#define Balmorhea         0x501
#define Weatherby          0x506
#define WestPike          0x511
#define Cypress          0x52F


#define Mekoryuk                 4789



#define Stidham               0
#define Sofia              1
#define Rocklin                2



#define Tiverton          0
#define Burrel          4095
#define Thach  4096
#define Nerstrand  8191



#define Maltby                      0
#define Barnhill                  0
#define Tobique                 1

header Ihlen Roxobel;
header Ihlen Boquet;
header Joiner Aplin[ 2 ];
header Skagway Sherack;
header Skagway Endeavor;
header Barnsdall Bunker;
header Barnsdall Gastonia;
header Coulter Barclay;
header Lowden WestLawn;
header Coulter Elvaston;
header Lowden Henry;
header Beatrice Ochoa;
header Wright Gwinn;
header Pavillion Redden;

parser Sawpit {
   extract( Roxobel );
   return select( Roxobel.Atlantic ) {
      Petty : Camden;
      Lodoga : Parmelee;
      Yetter : Mango;
      Oronogo  : Eureka;
      default        : ingress;
   }
}

parser Camden {
   extract( Aplin[0] );


   set_metadata(Cochise.Bechyn, 1);
   return select( Aplin[0].Hopkins ) {
      Lodoga : Parmelee;
      Yetter : Mango;
      Oronogo  : Eureka;
      default : ingress;
   }
}

parser Parmelee {
   extract( Sherack );
   set_metadata(Cochise.Slick, Sherack.Alsea);
   set_metadata(Cochise.Waldport, Sherack.WebbCity);
   set_metadata(Cochise.Gassoway, Sherack.Canfield);
   set_metadata(Cochise.Higgins, 0);
   set_metadata(Cochise.Hagewood, 1);
   return select(Sherack.Kennebec, Sherack.Cashmere, Sherack.Alsea) {
      WestPike : Caputa;
      default : ingress;
   }
}

parser Mango {
   extract( Gastonia );
   set_metadata(Cochise.Slick, Gastonia.Cavalier);
   set_metadata(Cochise.Waldport, Gastonia.Bicknell);
   set_metadata(Cochise.Gassoway, Gastonia.Bayonne);
   set_metadata(Cochise.Higgins, 1);
   set_metadata(Cochise.Hagewood, 0);
   return ingress;
}

parser Eureka {
   extract( Gwinn );
   return ingress;
}

parser Caputa {
   extract(WestLawn);
   return select(WestLawn.BigArm) {
      Mekoryuk : Marvin;
      default : ingress;
    }
}

parser Gustine {
   set_metadata(Egypt.Ferry, Rocklin);
   return Harpster;
}

parser McManus {
   set_metadata(Egypt.Ferry, Rocklin);
   return Brainard;
}

parser Slana {
   extract(Redden);
   return select(Redden.Ojibwa, Redden.TiffCity, Redden.Nixon, Redden.Buras, Redden.Camanche,
             Redden.Creekside, Redden.Cadley, Redden.Jenners, Redden.Millican) {
      Lodoga : Gustine;
      Yetter : McManus;
      default : ingress;
   }
}

parser Marvin {
   extract(Ochoa);
   set_metadata(Egypt.Ferry, Sofia);
   return Musella;
}

parser Harpster {
   extract( Endeavor );
   set_metadata(Cochise.Topton, Endeavor.Alsea);
   set_metadata(Cochise.Kensett, Endeavor.WebbCity);
   set_metadata(Cochise.Florahome, Endeavor.Canfield);
   set_metadata(Cochise.Jenkins, 0);
   set_metadata(Cochise.Bostic, 1);
   return ingress;
}

parser Brainard {
   extract( Bunker );
   set_metadata(Cochise.Topton, Bunker.Cavalier);
   set_metadata(Cochise.Kensett, Bunker.Bicknell);
   set_metadata(Cochise.Florahome, Bunker.Bayonne);
   set_metadata(Cochise.Jenkins, 1);
   set_metadata(Cochise.Bostic, 0);
   return ingress;
}

parser Musella {
   extract( Boquet );
   return select( Boquet.Atlantic ) {
      Lodoga: Harpster;
      Yetter: Brainard;
      default: ingress;
   }
}
#endif





@pragma pa_solitary ingress Egypt.Sudden
@pragma pa_solitary ingress Egypt.MuleBarn
@pragma pa_solitary ingress Egypt.Lyman

@pragma pa_atomic ingress Higley.Valentine
@pragma pa_solitary ingress Higley.Valentine







@pragma pa_no_pack ingress Norridge.Mendon Egypt.Helotes
@pragma pa_no_pack ingress Norridge.Mendon Cochise.Makawao
@pragma pa_no_pack ingress Norridge.Despard Egypt.Helotes
@pragma pa_no_pack ingress Norridge.Despard Cochise.Makawao

@pragma pa_no_pack ingress Norridge.Mattoon DuBois.Asharoken
@pragma pa_no_pack ingress Norridge.Mattoon Egypt.Kenmore
@pragma pa_no_pack ingress Norridge.Mattoon Egypt.Kenmore
@pragma pa_no_pack ingress Norridge.Mattoon Cochise.Jenkins
@pragma pa_no_pack ingress Norridge.Mattoon Cochise.Higgins
@pragma pa_no_pack ingress Norridge.Mattoon Avondale.Belview

@pragma pa_no_pack ingress Norridge.Despard Egypt.Ashwood
@pragma pa_no_pack ingress Norridge.Despard Cochise.Bechyn

@pragma pa_no_pack ingress Norridge.Lindsborg Egypt.Helotes
@pragma pa_no_pack ingress Norridge.Lindsborg Cochise.Makawao

@pragma pa_no_pack ingress Norridge.Mattoon Egypt.Helotes
@pragma pa_no_pack ingress Norridge.Mattoon Cochise.Makawao
@pragma pa_no_pack ingress Norridge.Mattoon Egypt.Rumson

@pragma pa_no_pack ingress Norridge.Mattoon Egypt.Ashwood
@pragma pa_no_pack ingress Norridge.Mattoon Cochise.Bechyn
@pragma pa_no_pack ingress Norridge.Mattoon DuBois.Westvaco

metadata Guadalupe Egypt;

metadata WolfTrap DuBois;
metadata Dassel Norridge;
metadata Godfrey Cochise;
metadata Badger Sieper;
metadata Gallinas Energy;
metadata BigFork Almota;
metadata Fristoe Avondale;
metadata Fouke Merrill;
metadata Pridgen Orlinda;
metadata Lewis Higley;
metadata Maytown Cherokee;
metadata Almont Weslaco;
metadata Bellvue Lolita;
metadata Nenana Bigspring;
metadata Nenana Irondale;
metadata Nenana Killen;













#undef Dalton

#undef Coolin
#undef Bethesda
#undef Brookland
#undef Connell
#undef Brinklow

#undef Petrolia
#undef Danbury
#undef Tekonsha

#undef Almelund
#undef Keller
#undef Darden
#undef Dacono
#undef Nelson
#undef Hillcrest
#undef Leesport
#undef Swansboro
#undef Helton
#undef Meservey
#undef Bushland
#undef Kenefic
#undef Buncombe
#undef Forepaugh
#undef Seaforth
#undef Auberry
#undef Elihu
#undef ElDorado
#undef Arriba
#undef Inola
#undef McDavid

#undef Hamburg
#undef Angeles
#undef MoonRun
#undef Milesburg
#undef HillCity
#undef Booth
#undef Hanover
#undef LaJoya
#undef Cidra
#undef Wapato
#undef IowaCity
#undef Caroleen
#undef Careywood
#undef Lakefield
#undef Knierim


#undef Kaeleku

#undef Karlsruhe
#undef Tenino
#undef Sunset
#undef Licking

#undef McIntosh

#undef Mecosta
#undef Farnham
#undef Leetsdale
#undef Jesup
#undef Friday







#define Dalton 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Coolin      65536
#define Bethesda      65536
#define Brookland 512
#define Connell 512
#define Brinklow      512


#define Petrolia     1024
#define Danbury    1024
#define Tekonsha     256


#define Almelund 512
#define Keller 65536
#define Darden 65536
#define Dacono 28672
#define Nelson   16384
#define Hillcrest 8192
#define Leesport         131072
#define Swansboro 65536
#define Helton 1024
#define Meservey 2048
#define Bushland 16384
#define Kenefic 8192
#define Buncombe 65536

#define Forepaugh 0x0000000000000000FFFFFFFFFFFFFFFF


#define Seaforth 0x000fffff
#define ElDorado 2

#define Auberry 0xFFFFFFFFFFFFFFFF0000000000000000

#define Elihu 0x000007FFFFFFFFFF0000000000000000
#define Arriba  6
#define McDavid        2048
#define Inola       65536


#define Hamburg 1024
#define Angeles 4096
#define MoonRun 4096
#define Milesburg 4096
#define HillCity 4096
#define Booth 1024
#define Hanover 4096
#define Cidra 64
#define Wapato 1
#define IowaCity  8
#define Caroleen 512


#define Careywood 1
#define Lakefield 3
#define Knierim 80


#define Kaeleku 0



#define Karlsruhe 2048


#define Tenino 4096



#define Sunset 2048
#define Licking 4096




#define McIntosh    4096


#define Mecosta    16384
#define Farnham   16384
#define Leetsdale            16384

#define Jesup                    57344
#define Friday         511


#endif



#ifndef GlenAvon
#define GlenAvon

action Handley() {
   no_op();
}

action Sargent() {
   modify_field(Egypt.Blanding, 1 );
}

action Shauck() {
   no_op();
}
#endif

















action Amesville(Unity, Rohwer, Salome, Shawmut, Whitefish, Floral,
                 Holden, Bluewater, Prismatic) {
    modify_field(Norridge.Brohard, Unity);
    modify_field(Norridge.Tomato, Rohwer);
    modify_field(Norridge.Calcium, Salome);
    modify_field(Norridge.Kinsey, Shawmut);
    modify_field(Norridge.Mattoon, Whitefish);
    modify_field(Norridge.Despard, Floral);
    modify_field(Norridge.Lindsborg, Holden);
    modify_field(Norridge.Mendon, Bluewater);
    modify_field(Norridge.Palouse, Prismatic);
}

@pragma command_line --no-dead-code-elimination
table Speedway {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Amesville;
    }
    size : Dalton;
}

control Raiford {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Speedway);
    }
}





action Higganum(Craigtown) {
   modify_field( DuBois.MontIda, 1 );
   modify_field( DuBois.Boistfort, Craigtown);
   modify_field( Egypt.Clarinda, 1 );
}

action Bayshore() {
   modify_field( Egypt.Omemee, 1 );
   modify_field( Egypt.Harvard, 1 );
}

action Renick() {


   modify_field( ig_intr_md_for_tm.ucast_egress_port, Friday );
   modify_field( Egypt.Clarinda, 1 );
}

action LeCenter() {
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Friday );
   modify_field( Egypt.Clarinda, 1 );
   modify_field( Egypt.Hagaman, 1 );
}

action Sparland() {
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Friday );
   modify_field( Egypt.Pinto, 1 );
}

action Lundell() {
   modify_field( Egypt.Harvard, 1 );
}


table Mossville {
   reads {
      Roxobel.Milwaukie : ternary;
      Roxobel.PellLake : ternary;
   }

   actions {
      Higganum;
      Bayshore;
      Renick;
      Sparland;
      Lundell;
      LeCenter;
   }
   default_action : Lundell;
   size : Brookland;
}

action Bassett() {
   modify_field( Egypt.Escatawpa, 1 );
}


table Phelps {
   reads {
      Roxobel.Bardwell : ternary;
      Roxobel.Donner : ternary;
   }

   actions {
      Bassett;
   }
   size : Connell;
}


control Lushton {
   apply( Mossville );
   apply( Phelps );
}




action Temvik() {
   modify_field( Sieper.Langlois, Endeavor.Cedonia );
   modify_field( Sieper.Yreka, Endeavor.Panacea );
   modify_field( Sieper.Picayune, Endeavor.Comal );
   modify_field( Energy.Caulfield, Bunker.Darco );
   modify_field( Energy.Lepanto, Bunker.Wilson );
   modify_field( Energy.Amory, Bunker.Eastover );


   modify_field( Egypt.Salduro, Boquet.Milwaukie );
   modify_field( Egypt.HydePark, Boquet.PellLake );
   modify_field( Egypt.Sandstone, Boquet.Bardwell );
   modify_field( Egypt.Ivyland, Boquet.Donner );
   modify_field( Egypt.Hilger, Boquet.Atlantic );
   modify_field( Egypt.Prunedale, Cochise.Florahome );
   modify_field( Egypt.LoneJack, Cochise.Topton );
   modify_field( Egypt.Goldsmith, Cochise.Kensett );
   modify_field( Egypt.Paxtonia, Cochise.Bostic );
   modify_field( Egypt.Kenmore, Cochise.Jenkins );
   modify_field( Egypt.Ashwood, 0 );
   modify_field( Norridge.Lindsborg, 2 );
   modify_field( Norridge.Mendon, 0 );
   modify_field( Norridge.Palouse, 0 );
}

action Suffern() {
   modify_field( Egypt.Ferry, Stidham );
   modify_field( Sieper.Langlois, Sherack.Cedonia );
   modify_field( Sieper.Yreka, Sherack.Panacea );
   modify_field( Sieper.Picayune, Sherack.Comal );
   modify_field( Energy.Caulfield, Gastonia.Darco );
   modify_field( Energy.Lepanto, Gastonia.Wilson );
   modify_field( Energy.Amory, Gastonia.Eastover );


   modify_field( Egypt.Salduro, Roxobel.Milwaukie );
   modify_field( Egypt.HydePark, Roxobel.PellLake );
   modify_field( Egypt.Sandstone, Roxobel.Bardwell );
   modify_field( Egypt.Ivyland, Roxobel.Donner );
   modify_field( Egypt.Hilger, Roxobel.Atlantic );
   modify_field( Egypt.Prunedale, Cochise.Gassoway );
   modify_field( Egypt.LoneJack, Cochise.Slick );
   modify_field( Egypt.Goldsmith, Cochise.Waldport );
   modify_field( Egypt.Paxtonia, Cochise.Hagewood );
   modify_field( Egypt.Kenmore, Cochise.Higgins );
   modify_field( Egypt.Helotes, Cochise.Makawao );
   modify_field( Egypt.Ashwood, Cochise.Bechyn );
}

table Lignite {
   reads {
      Roxobel.Milwaukie : exact;
      Roxobel.PellLake : exact;
      Sherack.Panacea : exact;
      Egypt.Ferry : exact;
   }

   actions {
      Temvik;
      Suffern;
   }

   default_action : Suffern();
   size : Hamburg;
}


action Duque() {
   modify_field( Egypt.Sudden, Norridge.Calcium );
   modify_field( Egypt.MuleBarn, Norridge.Brohard);
}

action Ravinia( Logandale ) {
   modify_field( Egypt.Sudden, Logandale );
   modify_field( Egypt.MuleBarn, Norridge.Brohard);
}

action Greendale() {
   modify_field( Egypt.Sudden, Aplin[0].Nichols );
   modify_field( Egypt.MuleBarn, Norridge.Brohard);
}

table Tulalip {
   reads {
      Norridge.Brohard : ternary;
      Aplin[0] : valid;
      Aplin[0].Nichols : ternary;
   }

   actions {
      Duque;
      Ravinia;
      Greendale;
   }
   size : Milesburg;
}

action Heavener( Wausaukee ) {
   modify_field( Egypt.MuleBarn, Wausaukee );
}

action Dominguez() {

   modify_field( Egypt.Newborn, 1 );
   modify_field( Merrill.Eclectic,
                 Tobique );
}

table Allen {
   reads {
      Sherack.Cedonia : exact;
   }

   actions {
      Heavener;
      Dominguez;
   }
   default_action : Dominguez;
   size : MoonRun;
}

action Telida( Annette, RoyalOak, Aberfoil, Sturgeon, Deering,
                        Locke, Thistle ) {
   modify_field( Egypt.Sudden, Annette );
   modify_field( Egypt.KawCity, Thistle );
   Reubens(RoyalOak, Aberfoil, Sturgeon, Deering,
                        Locke );
}

action Dennison() {
   modify_field( Egypt.Rumson, 1 );
}

table Gwynn {
   reads {
      Ochoa.Ballville : exact;
   }

   actions {
      Telida;
      Dennison;
   }
   size : Angeles;
}

action Reubens(Kaanapali, Benkelman, Anaconda, Coalwood,
                        Aniak ) {
   modify_field( Avondale.Camino, Kaanapali );
   modify_field( Avondale.Tappan, Benkelman );
   modify_field( Avondale.Chackbay, Anaconda );
   modify_field( Avondale.Narka, Coalwood );
   modify_field( Avondale.Glennie, Aniak );
}

action Kinsley(Fount, Bairoa, Casper, Ingraham,
                        Oketo ) {
   modify_field( Egypt.Lyman, Norridge.Calcium );
   modify_field( Egypt.KawCity, 1 );
   Reubens(Fount, Bairoa, Casper, Ingraham,
                        Oketo );
}

action Hettinger(Twodot, Hallwood, Kenton, Harvest,
                        Umkumiut, Quinwood ) {
   modify_field( Egypt.Lyman, Twodot );
   modify_field( Egypt.KawCity, 1 );
   Reubens(Hallwood, Kenton, Harvest, Umkumiut,
                        Quinwood );
}

action Sonora(Jauca, Hamden, Magazine, Chubbuck,
                        Arapahoe ) {
   modify_field( Egypt.Lyman, Aplin[0].Nichols );
   modify_field( Egypt.KawCity, 1 );
   Reubens(Jauca, Hamden, Magazine, Chubbuck,
                        Arapahoe );
}

table Emmorton {
   reads {
      Norridge.Calcium : exact;
   }


   actions {
      Handley;
      Kinsley;
   }

   size : HillCity;
}

@pragma action_default_only Handley
table Mattese {
   reads {
      Norridge.Brohard : exact;
      Aplin[0].Nichols : exact;
   }

   actions {
      Hettinger;
      Handley;
   }

   size : Booth;
}

table Merritt {
   reads {
      Aplin[0].Nichols : exact;
   }


   actions {
      Handley;
      Sonora;
   }

   size : Hanover;
}

control Ugashik {
   apply( Lignite ) {
         Temvik {
            apply( Allen );
            apply( Gwynn );
         }
         Suffern {
            if ( Norridge.Kinsey == 1 ) {
               apply( Tulalip );
            }
            if ( valid( Aplin[ 0 ] ) ) {

               apply( Mattese ) {
                  Handley {

                     apply( Merritt );
                  }
               }
            } else {

               apply( Emmorton );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Mayday {
    width  : 1;
    static : Frederika;
    instance_count : 262144;
}

register Hernandez {
    width  : 1;
    static : Perkasie;
    instance_count : 262144;
}

blackbox stateful_alu Valdosta {
    reg : Mayday;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Almota.Moquah;
}

blackbox stateful_alu Kewanee {
    reg : Hernandez;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Almota.Oakes;
}

field_list Petroleum {
    Norridge.Despard;
    Aplin[0].Nichols;
}

field_list_calculation Marysvale {
    input { Petroleum; }
    algorithm: identity;
    output_width: 18;
}

action Grassflat() {
    Valdosta.execute_stateful_alu_from_hash(Marysvale);
}

action Moorpark() {
    Kewanee.execute_stateful_alu_from_hash(Marysvale);
}

table Frederika {
    actions {
      Grassflat;
    }
    default_action : Grassflat;
    size : 1;
}

table Perkasie {
    actions {
      Moorpark;
    }
    default_action : Moorpark;
    size : 1;
}
#endif

action Belcher(Antelope) {
    modify_field(Almota.Oakes, Antelope);
}

@pragma  use_hash_action 0
table Trimble {
    reads {
       Norridge.Despard : exact;
    }
    actions {
      Belcher;
    }
    size : 64;
}

action Potter() {
   modify_field( Egypt.Calabash, Norridge.Calcium );
   modify_field( Egypt.Pinole, 0 );
}

table Oxnard {
   actions {
      Potter;
   }
   size : 1;
}

action Gosnell() {
   modify_field( Egypt.Calabash, Aplin[0].Nichols );
   modify_field( Egypt.Pinole, 1 );
}

table Cassadaga {
   actions {
      Gosnell;
   }
   size : 1;
}

control Addison {
   if ( valid( Aplin[ 0 ] ) ) {
      apply( Cassadaga );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Norridge.Mattoon == 1 ) {
         apply( Frederika );
         apply( Perkasie );
      }
#endif
   } else {
      apply( Oxnard );
      if( Norridge.Mattoon == 1 ) {
         apply( Trimble );
      }
   }
}




field_list OjoFeliz {
   Roxobel.Milwaukie;
   Roxobel.PellLake;
   Roxobel.Bardwell;
   Roxobel.Donner;
   Roxobel.Atlantic;
}

field_list ElmPoint {

   Sherack.Alsea;
   Sherack.Cedonia;
   Sherack.Panacea;
}

field_list Cliffs {
   Gastonia.Darco;
   Gastonia.Wilson;
   Gastonia.Eastover;
   Gastonia.Cavalier;
}

field_list Naubinway {
   Sherack.Cedonia;
   Sherack.Panacea;
   WestLawn.Klukwan;
   WestLawn.BigArm;
}





field_list_calculation Northlake {
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

field_list_calculation Hillsview {
    input {
        ElmPoint;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Everest {
    input {
        Cliffs;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Sarasota {
    input {
        Naubinway;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Lakebay() {
    modify_field_with_hash_based_offset(Cherokee.Westway, 0,
                                        Northlake, 4294967296);
}

action Ravena() {
    modify_field_with_hash_based_offset(Cherokee.Purves, 0,
                                        Hillsview, 4294967296);
}

action NewSite() {
    modify_field_with_hash_based_offset(Cherokee.Purves, 0,
                                        Everest, 4294967296);
}

action Vinings() {
    modify_field_with_hash_based_offset(Cherokee.Wenona, 0,
                                        Sarasota, 4294967296);
}

table Myoma {
   actions {
      Lakebay;
   }
   size: 1;
}

control Penalosa {
   apply(Myoma);
}

table Switzer {
   actions {
      Ravena;
   }
   size: 1;
}

table Eddington {
   actions {
      NewSite;
   }
   size: 1;
}

control Agawam {
   if ( valid( Sherack ) ) {
      apply(Switzer);
   } else {
      if ( valid( Gastonia ) ) {
         apply(Eddington);
      }
   }
}

table Ranburne {
   actions {
      Vinings;
   }
   size: 1;
}

control Corona {
   if ( valid( WestLawn ) ) {
      apply(Ranburne);
   }
}



action Newkirk() {
    modify_field(Higley.Valentine, Cherokee.Westway);
}

action Pownal() {
    modify_field(Higley.Valentine, Cherokee.Purves);
}

action Clearlake() {
    modify_field(Higley.Valentine, Cherokee.Wenona);
}

@pragma action_default_only Handley
@pragma immediate 0
table Keener {
   reads {
      Elvaston.valid : ternary;
      Henry.valid : ternary;
      Endeavor.valid : ternary;
      Bunker.valid : ternary;
      Boquet.valid : ternary;
      Barclay.valid : ternary;
      WestLawn.valid : ternary;
      Sherack.valid : ternary;
      Gastonia.valid : ternary;
      Roxobel.valid : ternary;
   }
   actions {
      Newkirk;
      Pownal;
      Clearlake;
      Handley;
   }
   size: Tekonsha;
}

action Montross() {
    modify_field(Higley.Shoup, Cherokee.Wenona);
}

@pragma immediate 0
table Kenney {
   reads {
      Elvaston.valid : ternary;
      Henry.valid : ternary;
      Barclay.valid : ternary;
      WestLawn.valid : ternary;
   }
   actions {
      Montross;
      Handley;
   }
   size: Arriba;
}

field_list Tatum {
   Higley.Valentine;
}

field_list_calculation Carrizozo {
   input {
       Tatum;
   }
   algorithm : crc16;
   output_width : 16;
}

action Snowflake() {
   modify_field_with_hash_based_offset(Higley.Cement, 0,Carrizozo, 32768);
}

table NewTrier {
   actions {
      Snowflake;
   }
   default_action : Snowflake;
   size : 1;
}

control Delcambre {
   apply(Kenney);
   apply(Keener);
}

control Havertown {
   apply(NewTrier);
}



counter Ceiba {
   type : packets_and_bytes;
   direct : Tontogany;
   min_width: 16;
}

@pragma action_default_only Handley
table Tontogany {
   reads {
      Norridge.Despard : exact;
      Almota.Oakes : ternary;
      Almota.Moquah : ternary;
      Egypt.Rumson : ternary;
      Egypt.Escatawpa : ternary;
      Egypt.Omemee : ternary;
   }

   actions {
      Sargent;
      Handley;
   }
   size : Brinklow;
}

action Shelby() {

   modify_field(Egypt.Crystola, 1 );
   modify_field(Merrill.Eclectic,
                Barnhill);
}







table Claysburg {
   reads {
      Egypt.Sandstone : exact;
      Egypt.Ivyland : exact;
      Egypt.Sudden : exact;
      Egypt.MuleBarn : exact;
   }

   actions {
      Shauck;
      Shelby;
   }
   size : Bethesda;
   support_timeout : true;
}

action Mangham() {
   modify_field( Avondale.Belview, 1 );
}

table Fiskdale {
   reads {
      Egypt.Lyman : ternary;
      Egypt.Salduro : exact;
      Egypt.HydePark : exact;
   }
   actions {
      Mangham;
   }
   size: Almelund;
}

control Medulla {
   apply( Tontogany ) {
      Handley {



         if (Norridge.Tomato == 0 and Egypt.Newborn == 0) {
            apply( Claysburg );
         }
         apply(Fiskdale);
      }
   }
}

field_list Oklee {
    Merrill.Eclectic;
    Egypt.Sandstone;
    Egypt.Ivyland;
    Egypt.Sudden;
    Egypt.MuleBarn;
}

action Lefor() {
   generate_digest(Maltby, Oklee);
}

table BigBow {
   actions {
      Lefor;
   }
   size : 1;
}

control Amazonia {
   if (Egypt.Crystola == 1) {
      apply( BigBow );
   }
}



action Notus( Homeland, Neponset ) {
   modify_field( Energy.Winfall, Homeland );
   modify_field( Orlinda.Haverford, Neponset );
}

@pragma action_default_only Handley
table Hurdtown {
   reads {
      Avondale.Camino : exact;
      Energy.Lepanto mask Auberry : lpm;
   }
   actions {
      Notus;
      Handley;
   }
   size : Kenefic;
}

@pragma atcam_partition_index Energy.Winfall
@pragma atcam_number_partitions Kenefic
table Emerado {
   reads {
      Energy.Winfall : exact;
      Energy.Lepanto mask Elihu : lpm;
   }

   actions {
      Harris;
      Hemet;
      Handley;
   }
   default_action : Handley();
   size : Buncombe;
}

action Aguila( Cargray, Waseca ) {
   modify_field( Energy.Lovelady, Cargray );
   modify_field( Orlinda.Haverford, Waseca );
}

@pragma action_default_only Handley
table Biloxi {


   reads {
      Avondale.Camino : exact;
      Energy.Lepanto : lpm;
   }

   actions {
      Aguila;
      Handley;
   }

   size : Meservey;
}

@pragma atcam_partition_index Energy.Lovelady
@pragma atcam_number_partitions Meservey
table Blackman {
   reads {
      Energy.Lovelady : exact;


      Energy.Lepanto mask Forepaugh : lpm;
   }
   actions {
      Harris;
      Hemet;
      Handley;
   }

   default_action : Handley();
   size : Bushland;
}

@pragma action_default_only Handley
@pragma idletime_precision 1
table Loris {

   reads {
      Avondale.Camino : exact;
      Sieper.Yreka : lpm;
   }

   actions {
      Harris;
      Hemet;
      Handley;
   }

   size : Helton;
   support_timeout : true;
}

action Minetto( Laxon, Westoak ) {
   modify_field( Sieper.Wyman, Laxon );
   modify_field( Orlinda.Haverford, Westoak );
}

@pragma action_default_only Handley
#ifdef PROFILE_DEFAULT
@pragma stage 2 Hillcrest
@pragma stage 3
#endif
table Stockton {
   reads {
      Avondale.Camino : exact;
      Sieper.Yreka : lpm;
   }

   actions {
      Minetto;
      Handley;
   }

   size : Nelson;
}

@pragma ways ElDorado
@pragma atcam_partition_index Sieper.Wyman
@pragma atcam_number_partitions Nelson
table Resaca {
   reads {
      Sieper.Wyman : exact;
      Sieper.Yreka mask Seaforth : lpm;
   }
   actions {
      Harris;
      Hemet;
      Handley;
   }
   default_action : Handley();
   size : Leesport;
}

action Harris( Noorvik ) {
   modify_field( Orlinda.Haverford, Noorvik );
}

@pragma action_default_only Handley
@pragma idletime_precision 1
table Azusa {
   reads {
      Avondale.Camino : exact;
      Sieper.Yreka : exact;
   }

   actions {
      Harris;
      Hemet;
      Handley;
   }
   size : Keller;
   support_timeout : true;
}

@pragma action_default_only Handley
@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
@pragma stage 2 Dacono
@pragma stage 3
#endif
table Wauconda {
   reads {
      Avondale.Camino : exact;
      Energy.Lepanto : exact;
   }

   actions {
      Harris;
      Hemet;
      Handley;
   }
   size : Darden;
   support_timeout : true;
}

action Centre(Onley, Holliston, PinkHill) {
   modify_field(DuBois.Montello, PinkHill);
   modify_field(DuBois.Branson, Onley);
   modify_field(DuBois.Rehoboth, Holliston);
   modify_field(DuBois.Miller, 1);
}

table MillHall {
   reads {
      Orlinda.Haverford : exact;
   }

   actions {
      Centre;
   }
   size : Swansboro;
}

control Orrum {
   if ( Egypt.Blanding == 0 and Avondale.Belview == 1 ) {
      if ( ( Avondale.Tappan == 1 ) and ( Egypt.Paxtonia == 1 ) ) {
         apply( Azusa ) {
            Handley {
               apply( Stockton ) {
                  Minetto {
                     apply( Resaca );
                  }
                  Handley {
                     apply( Loris );
                  }
               }
            }
         }
      } else if ( ( Avondale.Chackbay == 1 ) and ( Egypt.Kenmore == 1 ) ) {
         apply( Wauconda ) {
            Handley {
               apply( Biloxi ) {
                  Aguila {
                     apply( Blackman );
                  }
                  Handley {

                     apply( Hurdtown ) {
                        Notus {
                           apply( Emerado );
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Illmo {
   if( Orlinda.Haverford != 0 ) {
      apply( MillHall );
   }
}

action Hemet( Hemlock ) {
   modify_field( Orlinda.Fowlkes, Hemlock );
   modify_field( Avondale.Troutman, 1 );
}

field_list Storden {
   Higley.Shoup;
}

field_list_calculation Mineral {
    input {
        Storden;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Crown {
   selection_key : Mineral;
   selection_mode : resilient;
}

action_profile Canjilon {
   actions {
      Harris;
   }
   size : Inola;
   dynamic_action_selection : Crown;
}

table Andrade {
   reads {
      Orlinda.Fowlkes : exact;
   }
   action_profile : Canjilon;
   size : McDavid;
}

control Francisco {
   if ( Orlinda.Fowlkes != 0 ) {
      apply( Andrade );
   }
}



field_list Gypsum {
   Higley.Valentine;
}

field_list_calculation Steger {
    input {
        Gypsum;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Downs {
    selection_key : Steger;
    selection_mode : resilient;
}

action Bells(Kaufman) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Kaufman);
}

action_profile Anselmo {
    actions {
        Bells;
        Handley;
    }
    size : Danbury;
    dynamic_action_selection : Downs;
}

table Sheldahl {
   reads {
      DuBois.Holyoke : exact;
   }
   action_profile: Anselmo;
   size : Petrolia;
}

control Clinchco {
   if ((DuBois.Holyoke & 0x2000) == 0x2000) {
      apply(Sheldahl);
   }
}



meter Columbia {
   type : packets;
   static : Carnation;
   instance_count: Karlsruhe;
}

action TiePlant(Newhalen) {
   execute_meter(Columbia, Newhalen, Weslaco.ElLago);
}



table Carnation {
   reads {
      Norridge.Despard : exact;
      DuBois.Boistfort : exact;
   }
   actions {
      TiePlant;
   }
   size : Sunset;
}

counter Timnath {
   type : packets;
   static : Germano;
   instance_count : Tenino;
   min_width: 64;
}

action Lansdale(Emmet) {
   modify_field(Egypt.Blanding, 1);
   count(Timnath, Emmet);
}

action Sharon(Counce) {
   count(Timnath, Counce);
}

action Knollwood(Goodlett, Ankeny) {
   modify_field(ig_intr_md_for_tm.qid, Goodlett);
   count(Timnath, Ankeny);
}

action Nuevo(Cross, Kaluaaha, Mattson) {
   modify_field(ig_intr_md_for_tm.qid, Cross);
   modify_field(ig_intr_md_for_tm.ingress_cos, Kaluaaha);
   count(Timnath, Mattson);
}

action Hermiston(Kaweah) {
   modify_field(ig_intr_md_for_tm.copy_to_cpu, 1);
   count(Timnath, Kaweah);
}

table Germano {
   reads {
      Norridge.Despard : exact;
      DuBois.Boistfort : exact;
      Weslaco.ElLago : exact;
   }

   actions {
      Lansdale;
      Knollwood;
      Nuevo;
      Sharon;
      Hermiston;
   }
size : Licking;
}



action Judson() {
   modify_field(DuBois.Branson, Egypt.Salduro);
   modify_field(DuBois.Rehoboth, Egypt.HydePark);
   modify_field(DuBois.Waialee, Egypt.Sandstone);
   modify_field(DuBois.Sedan, Egypt.Ivyland);
   modify_field(DuBois.Montello, Egypt.Sudden);
}

table Ledford {
   actions {
      Judson;
   }
   default_action : Judson();
   size : 1;
}

control Pidcoke {
   if (Egypt.Sudden!=0 or Egypt.Harvard==0) {
      apply( Ledford );
   }
}

action Parmele() {
   modify_field(DuBois.Westvaco, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, DuBois.Montello);
   modify_field(DuBois.Holyoke, Friday);
}

action Hobson(Rowlett) {
   modify_field(DuBois.Asharoken, 1);



   modify_field(ig_intr_md_for_tm.ucast_egress_port, Rowlett);
   modify_field(DuBois.Holyoke, Rowlett);
}

table Myrick {
   reads {
      DuBois.Branson : exact;
      DuBois.Rehoboth : exact;
      DuBois.Montello : exact;
   }

   actions {
      Hobson;
      Parmele;
   }
   default_action : Parmele();
   size : Coolin;
}

control Milano {
   if ((Egypt.Blanding == 0) and ((DuBois.Branson & 0x010000) == 0x000000)) {
      apply(Myrick);
   }
}

action Chatom() {
   modify_field(Egypt.Mackville, 1);
   modify_field(Egypt.Blanding, 1);
}

table Isabela {
   actions {
      Chatom;
   }
   default_action : Chatom;
   size : 1;
}

control Raeford {
   if ((Egypt.Blanding == 0) and (Egypt.Harvard==1)) {
      if ((DuBois.Miller==0) and (Egypt.MuleBarn==DuBois.Holyoke)) {
         apply(Isabela);
      }
   }
}



action Berkey( BigRiver ) {
   modify_field( DuBois.Ashburn, BigRiver );
}

action Croghan() {
   modify_field( DuBois.Ashburn, DuBois.Montello );
}

table Perrytown {
   reads {
      eg_intr_md.egress_port : exact;
      DuBois.Montello : exact;
   }

   actions {
      Berkey;
      Croghan;
   }
   default_action : Croghan;
   size : McIntosh;
}

control Southam {
   apply( Perrytown );
}



action Firebrick( Ironside, BigRun ) {
   modify_field( DuBois.Magma, Ironside );
   modify_field( DuBois.Kempton, BigRun );
}


table Wittman {
   reads {
      DuBois.Skiatook : exact;
   }

   actions {
      Firebrick;
   }
   size : IowaCity;
}

action Quinnesec() {
   no_op();
}

action Tocito() {
   modify_field( Roxobel.Atlantic, Aplin[0].Hopkins );
   remove_header( Aplin[0] );
}


table Shidler {
   actions {
      Tocito;
   }
   default_action : Tocito;
   size : Wapato;
}

action Westbury() {
   no_op();
}

action Olcott() {
   add_header( Aplin[ 0 ] );
   modify_field( Aplin[0].Nichols, DuBois.Ashburn );
   modify_field( Aplin[0].Hopkins, Roxobel.Atlantic );
   modify_field( Roxobel.Atlantic, Petty );
}



table Belmond {
   reads {
      DuBois.Ashburn : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Westbury;
      Olcott;
   }
   default_action : Olcott;
   size : Cidra;
}

action Ossipee() {
   modify_field(Roxobel.Milwaukie, DuBois.Branson);
   modify_field(Roxobel.PellLake, DuBois.Rehoboth);
   modify_field(Roxobel.Bardwell, DuBois.Magma);
   modify_field(Roxobel.Donner, DuBois.Kempton);
}

action Davie() {
   Ossipee();
   add_to_field(Sherack.WebbCity, -1);
}

action Merkel() {
   Ossipee();
   add_to_field(Gastonia.Bicknell, -1);
}

table Ganado {
   reads {
      DuBois.Basye : exact;
      DuBois.Skiatook : exact;
      DuBois.Miller : exact;
      Sherack.valid : ternary;
      Gastonia.valid : ternary;
   }

   actions {
      Davie;
      Merkel;
   }
   size : Caroleen;
}

control Cornudas {
   apply( Shidler );
}

control Callands {
   apply( Belmond );
}

control Clarendon {
   apply( Wittman );
   apply( Ganado );
}



field_list Langhorne {
    Merrill.Eclectic;
    Egypt.Sudden;
    Boquet.Bardwell;
    Boquet.Donner;
    Sherack.Cedonia;
}

action Trenary() {
   generate_digest(Maltby, Langhorne);
}

table Paulette {
   actions {
      Trenary;
   }

   default_action : Trenary;
   size : 1;
}

control Westtown {
   if (Egypt.Newborn == 1) {
      apply(Paulette);
   }
}



action Remington() {
   modify_field( Egypt.Helotes, Norridge.Mendon );
}

action Madill() {
   modify_field( Egypt.Vining, Norridge.Palouse );
}

action Butler() {
   modify_field( Egypt.Vining, Sieper.Picayune );
}

action ElkRidge() {
   modify_field( Egypt.Vining, Energy.Green );
}

action Rotterdam( Furman, Bettles ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Furman );
   modify_field( ig_intr_md_for_tm.qid, Bettles );
}

table Nooksack {
   reads {
     Egypt.Ashwood : exact;
   }

   actions {
     Remington;
   }

   size : Careywood;
}

table Piketon {
   reads {
     Egypt.Paxtonia : exact;
     Egypt.Kenmore : exact;
   }

   actions {
     Madill;
     Butler;
     ElkRidge;
   }

   size : Lakefield;
}

@pragma stage 10
table Jenera {
   reads {
      Norridge.Lindsborg : exact;
      Norridge.Mendon : ternary;
      Egypt.Helotes : ternary;
      Egypt.Vining : ternary;
   }

   actions {
      Rotterdam;
   }

   size : Knierim;
}

control Dagmar {
   apply( Nooksack );
   apply( Piketon );
}

control Kahua {
   apply( Jenera );
}



action Everett( Rockdell, Weinert ) {
   modify_field( Lolita.Menifee, Rockdell );
   modify_field( Killen.Turkey, Weinert );
   modify_field( Killen.Alcester, 1 );
}

table Macedonia {
   reads {
     Sieper.Yreka : exact;
     Egypt.Lyman : exact;
   }

   actions {
      Everett;
   }
  size : Mecosta;
}

action Gandy(Pierre) {
   modify_field( Irondale.Turkey, Pierre );
   modify_field( Irondale.Alcester, 1 );
}

table Monahans {
   reads {
     Sieper.Langlois : exact;
     Lolita.Menifee : exact;
   }
   actions {
      Gandy;
   }
   size : Farnham;
}

action Anguilla( Carnegie ) {
   modify_field( Bigspring.Turkey, Carnegie );
   modify_field( Bigspring.Alcester, 1 );
}





action Spanaway() {
   modify_field( Egypt.Donald, Egypt.Sudden );
}

table Cortland {
   reads {
     Egypt.Salduro mask 0xfeffff : exact;
     Egypt.HydePark : exact;
     Egypt.Sudden : exact;
   }
   actions {
      Anguilla;
   }
   default_action : Spanaway;
   size : Leetsdale;
}


action Conover() {
   modify_field(ig_intr_md_for_tm.level2_mcast_hash, Higley.Cement);
   modify_field(ig_intr_md_for_tm.level2_exclusion_id, ig_intr_md.ingress_port);






}






action Hawthorne(PawPaw, Kenbridge) {


   Conover();
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Irondale.Turkey);
   modify_field(DuBois.Temple, PawPaw);
   modify_field(DuBois.Rendville, Kenbridge);
}
action Whitewood(Burien, LaPlata) {
   Conover();
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Killen.Turkey);
   modify_field(DuBois.Temple, Burien);
   modify_field(DuBois.Rendville, LaPlata);
}
action Maryville(Alvordton, Hartford) {
   Conover();
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Bigspring.Turkey);
   modify_field(DuBois.Temple, Alvordton);
   modify_field(DuBois.Rendville, Hartford);
}
action Bonduel() {
   Conover();

   add(ig_intr_md_for_tm.mcast_grp_a, Egypt.Donald, Thach);
   modify_field(DuBois.Montello, Egypt.Sudden);
}

action Fredonia() {
   Conover();

   modify_field(ig_intr_md_for_tm.mcast_grp_a, Egypt.Donald);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Egypt.KawCity);
}

@pragma stage 9
table Bucklin {
   reads {
     Irondale.Turkey : ternary;
     Irondale.Alcester : ternary;
     Killen.Turkey : ternary;
     Killen.Alcester : ternary;
     Bigspring.Turkey : ternary;
     Bigspring.Alcester : ternary;
     Egypt.Pinto : ternary;
     Egypt.LoneJack :ternary;
     Egypt.Clarinda:ternary;
     Egypt.Hagaman:ternary;

     }
   actions {
      Whitewood;
      Hawthorne;
      Maryville;
      Bonduel;
      Fredonia;
   }
   default_action: Bonduel;
   size : 16;
}

control BigPoint {
   if (Egypt.Blanding == 0 and
       Avondale.Narka == 1 and
       Egypt.Hagaman == 1) {
       apply(Macedonia) {
          hit {
             apply(Monahans);
          }
       }
   }





   if(Egypt.Blanding ==0 and Egypt.Harvard==0) {




      apply(Cortland);
   }
}

control Gillespie {




   if(Egypt.Blanding ==0 and Egypt.Harvard==0) {
      apply(Bucklin);


   }
}




action Pensaukee(Netarts, Funkley) {
   modify_field(DuBois.Montello, Netarts);


   modify_field(DuBois.Miller, Funkley);
}

action Averill() {











   drop();
}

@pragma stage 7
table Edmeston {
   reads {
     eg_intr_md.egress_rid: exact;
   }

   actions {
      Pensaukee;
   }
   default_action: Averill;
   size : Jesup;
}


control IttaBena {


   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Edmeston);
   }
}

control ingress {

   Raiford();
   Lushton();
   Ugashik();
   Addison();
   Penalosa();


   Dagmar();
   Medulla();

   Agawam();
   Corona();


   Orrum();
   Delcambre();
   Francisco();

   Pidcoke();

   Illmo();





   BigPoint();
   Milano();
   Havertown();


   Raeford();
   Clinchco();
   Westtown();
   Amazonia();


   Gillespie();


   apply(Carnation);



   apply(Germano);

   if( valid( Aplin[0] ) ) {
      Cornudas();
   }

}

control egress {
   IttaBena();
   Southam();
   Clarendon();
   Callands();
}
