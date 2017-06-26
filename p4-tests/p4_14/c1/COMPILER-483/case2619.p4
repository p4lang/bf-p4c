// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 223809







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>



#ifndef Ozona
#define Ozona

header_type Manasquan {
	fields {
		Calabasas : 16;
		Huttig : 16;
		Lizella : 8;
		Valeene : 8;
		DeSart : 8;
		Wolford : 8;
		ElkPoint : 1;
		Millican : 1;
		Tarlton : 1;
		Vinings : 1;
		Kohrville : 1;
	}
}

header_type Hewins {
	fields {
		McCracken : 24;
		SweetAir : 24;
		Alvordton : 24;
		Pittwood : 24;
		Steprock : 16;
		Maybell : 16;
		Readsboro : 16;
		Morgana : 16;
		Crystola : 16;
		Greycliff : 8;
		Volens : 8;
		Agawam : 6;
		Bouton : 1;
		Newcastle : 1;
		Denhoff : 12;
		OakCity : 2;
		Willard : 1;
		Parmerton : 1;
		Halliday : 1;
		Elmdale : 1;
		Stryker : 1;
		Funkley : 1;
		Haworth : 1;
		Bardwell : 1;
		Attalla : 1;
		BigArm : 1;
		Kinde : 1;
		Topmost : 1;
		Sonoma : 1;
		Philbrook : 3;
		Casper : 1;
	}
}

header_type Washoe {
	fields {
		Freetown : 24;
		Comunas : 24;
		Connell : 24;
		CoalCity : 24;
		Arion : 24;
		Pedro : 24;
		Opelousas : 24;
		Tilton : 24;
		Crane : 16;
		Millhaven : 16;
		Pickett : 16;
		Farragut : 16;
		Bergton : 12;
		Issaquah : 3;
		PortVue : 1;
		Devers : 3;
		Ethete : 1;
		PineLake : 1;
		Grainola : 1;
		Anacortes : 1;
		NewCity : 1;
		Talent : 1;
		Metzger : 8;
		Wauseon : 12;
		BigWater : 4;
		Klawock : 6;
		Strasburg : 10;
		Sparland : 9;
		Tuscumbia : 1;
	}
}


header_type Millbrook {
	fields {
		Crossett : 8;
		WebbCity : 1;
		Meeker : 1;
		Towaoc : 1;
		Grapevine : 1;
		Elmhurst : 1;
	}
}

header_type Bonner {
	fields {
		Newberg : 32;
		Ossining : 32;
		Hopedale : 6;
		Neshaminy : 16;
	}
}

header_type Kenney {
	fields {
		Westel : 128;
		Sabina : 128;
		Alabaster : 20;
		Ossineke : 8;
		Woolsey : 11;
		Shelbiana : 6;
		Betterton : 13;
	}
}

header_type Lovilia {
	fields {
		LaSal : 14;
		Almond : 1;
		Carroll : 12;
		Robbs : 1;
		Adamstown : 1;
		Renick : 6;
		Tekonsha : 2;
		Lakebay : 6;
		Kahaluu : 3;
	}
}

header_type Maltby {
	fields {
		LongPine : 1;
		Lepanto : 1;
	}
}

header_type NewTrier {
	fields {
		SeaCliff : 8;
	}
}

header_type Quinhagak {
	fields {
		Orlinda : 16;
		Hopeton : 11;
	}
}

header_type Stewart {
	fields {
		Kalkaska : 32;
		Progreso : 32;
		Encinitas : 32;
	}
}

header_type Puyallup {
	fields {
		Boysen : 32;
		Burtrum : 32;
	}
}

header_type Johnsburg {
	fields {
		Wellton : 8;
		Perryman : 4;
		Edroy : 15;
		SourLake : 1;
	}
}
#endif



#ifndef Mapleton
#define Mapleton


header_type Hallwood {
	fields {
		Bedrock : 6;
		Hapeville : 10;
		Hershey : 4;
		Belen : 12;
		Gonzalez : 12;
		Delmont : 2;
		Macland : 2;
		Wharton : 8;
		Sanborn : 3;
		Wardville : 5;
	}
}



header_type Westbury {
	fields {
		Lewistown : 24;
		Helen : 24;
		Weissert : 24;
		Assinippi : 24;
		Almont : 16;
	}
}



header_type Mulliken {
	fields {
		Nichols : 3;
		Moquah : 1;
		Floris : 12;
		Pickering : 16;
	}
}



header_type Tularosa {
	fields {
		Broussard : 4;
		Miller : 4;
		Geeville : 6;
		Belgrade : 2;
		Sandoval : 16;
		Cutler : 16;
		Biscay : 3;
		Windber : 13;
		DesPeres : 8;
		Chatom : 8;
		Laketown : 16;
		Niota : 32;
		Stonebank : 32;
	}
}

header_type Quealy {
	fields {
		Naguabo : 4;
		Hatchel : 6;
		Kettering : 2;
		Leona : 20;
		Eclectic : 16;
		Berenice : 8;
		Bammel : 8;
		Grannis : 128;
		Lumpkin : 128;
	}
}




header_type Cockrum {
	fields {
		Gibbs : 8;
		Rozet : 8;
		Poteet : 16;
	}
}

header_type Dougherty {
	fields {
		Casnovia : 16;
		Buckhorn : 16;
	}
}

header_type Brunson {
	fields {
		Machens : 32;
		Lardo : 32;
		Montalba : 4;
		Penitas : 4;
		Donegal : 8;
		Lewes : 16;
		Anthon : 16;
		Gordon : 16;
	}
}

header_type Pettigrew {
	fields {
		Balmville : 16;
		Lemhi : 16;
	}
}



header_type Tornillo {
	fields {
		Telida : 16;
		Struthers : 16;
		Donnelly : 8;
		Plateau : 8;
		Jayton : 16;
	}
}

header_type Horns {
	fields {
		Logandale : 48;
		Fittstown : 32;
		ArchCape : 48;
		Bellmead : 32;
	}
}



header_type Christmas {
	fields {
		Verdemont : 1;
		Taconite : 1;
		Millikin : 1;
		Allons : 1;
		Netcong : 1;
		Grisdale : 3;
		Larose : 5;
		Ranburne : 3;
		Quebrada : 16;
	}
}

header_type Bagwell {
	fields {
		Westpoint : 24;
		BigLake : 8;
	}
}



header_type Elyria {
	fields {
		Covina : 8;
		Bazine : 24;
		Juneau : 24;
		Scanlon : 8;
	}
}

#endif



#ifndef Yetter
#define Yetter

#define Dateland        0x8100
#define Reinbeck        0x0800
#define LaPlata        0x86dd
#define Narka        0x9100
#define Millett        0x8847
#define Odell         0x0806
#define Osseo        0x8035
#define Lambrook        0x88cc
#define Kinross        0x8809
#define Bramwell      0xBF00

#define Albin              1
#define Earling              2
#define Bonduel              4
#define Cowan               6
#define Plush               17
#define Hanahan                47

#define Heppner         0x501
#define Columbus          0x506
#define Pachuta          0x511
#define Minto          0x52F


#define Mayflower                 4789



#define Wailuku               0
#define Viroqua              1
#define Soledad                2



#define SandLake          0
#define Murdock          4095
#define Harpster  4096
#define RedBay  8191



#define Charenton                      0
#define Coolin                  0
#define Chambers                 1

header Westbury Rankin;
header Westbury Kittredge;
header Mulliken Lamison[ 2 ];



@pragma pa_fragment ingress Halfa.Laketown
@pragma pa_fragment egress Halfa.Laketown
header Tularosa Halfa;

@pragma pa_fragment ingress Palatine.Laketown
@pragma pa_fragment egress Palatine.Laketown
header Tularosa Palatine;

header Quealy Stamford;
header Quealy Pinetop;
header Dougherty Grantfork;
header Brunson Equality;

header Pettigrew Almeria;
header Brunson Yorkshire;
header Pettigrew Cantwell;
header Elyria Mendon;
header Tornillo Wyncote;
header Christmas Reagan;
header Hallwood Mattapex;
header Westbury Chantilly;

parser start {
   return select(current(96, 16)) {
      Bramwell : Sledge;
      default : WestBend;
   }
}

parser Holtville {
   extract( Mattapex );
   return WestBend;
}

parser Sledge {
   extract( Chantilly );
   return Holtville;
}

parser WestBend {
   extract( Rankin );
   return select( Rankin.Almont ) {
      Dateland : Hilger;
      Reinbeck : McCaskill;
      LaPlata : Bosler;
      Odell  : Rugby;
      default        : ingress;
   }
}

parser Hilger {
   extract( Lamison[0] );
   set_metadata(Brave.Kohrville, 1);
   return select( Lamison[0].Pickering ) {
      Reinbeck : McCaskill;
      LaPlata : Bosler;
      Odell  : Rugby;
      default : ingress;
   }
}

field_list Miranda {
    Halfa.Broussard;
    Halfa.Miller;
    Halfa.Geeville;
    Halfa.Belgrade;
    Halfa.Sandoval;
    Halfa.Cutler;
    Halfa.Biscay;
    Halfa.Windber;
    Halfa.DesPeres;
    Halfa.Chatom;
    Halfa.Niota;
    Halfa.Stonebank;
}

field_list_calculation Burnett {
    input {
        Miranda;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field Halfa.Laketown  {
    verify Burnett;
    update Burnett;
}

parser McCaskill {
   extract( Halfa );
   set_metadata(Brave.Lizella, Halfa.Chatom);
   set_metadata(Brave.DeSart, Halfa.DesPeres);
   set_metadata(Brave.Calabasas, Halfa.Sandoval);
   set_metadata(Brave.Tarlton, 0);
   set_metadata(Brave.ElkPoint, 1);
   return select(Halfa.Windber, Halfa.Miller, Halfa.Chatom) {
      Pachuta : Mondovi;
      Columbus : Uintah;
      default : ingress;
   }
}

parser Bosler {
   extract( Pinetop );
   set_metadata(Brave.Lizella, Pinetop.Berenice);
   set_metadata(Brave.DeSart, Pinetop.Bammel);
   set_metadata(Brave.Calabasas, Pinetop.Eclectic);
   set_metadata(Brave.Tarlton, 1);
   set_metadata(Brave.ElkPoint, 0);
   return select(Pinetop.Berenice) {
      Pachuta : Hydaburg;
      Columbus : Uintah;
      default : ingress;
   }
}

parser Rugby {
   extract( Wyncote );
   return ingress;
}

parser Mondovi {
   extract(Grantfork);
   extract(Almeria);
   return select(Grantfork.Buckhorn) {
      Mayflower : Clover;
      default : ingress;
    }
}

parser Hydaburg {
   extract(Grantfork);
   extract(Almeria);
   return ingress;
}

parser Uintah {
   extract(Grantfork);
   extract(Equality);
   return ingress;
}

parser Mission {
   set_metadata(Perrin.OakCity, Soledad);
   return Clarendon;
}

parser Saltdale {
   set_metadata(Perrin.OakCity, Soledad);
   return Darden;
}

parser Owentown {
   extract(Reagan);
   return select(Reagan.Verdemont, Reagan.Taconite, Reagan.Millikin, Reagan.Allons, Reagan.Netcong,
             Reagan.Grisdale, Reagan.Larose, Reagan.Ranburne, Reagan.Quebrada) {
      Reinbeck : Mission;
      LaPlata : Saltdale;
      default : ingress;
   }
}

parser Clover {
   extract(Mendon);
   set_metadata(Perrin.OakCity, Viroqua);
   return Marcus;
}

field_list Warba {
    Palatine.Broussard;
    Palatine.Miller;
    Palatine.Geeville;
    Palatine.Belgrade;
    Palatine.Sandoval;
    Palatine.Cutler;
    Palatine.Biscay;
    Palatine.Windber;
    Palatine.DesPeres;
    Palatine.Chatom;
    Palatine.Niota;
    Palatine.Stonebank;
}

field_list_calculation Charlack {
    input {
        Warba;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field Palatine.Laketown  {
    verify Charlack;
    update Charlack;
}

parser Clarendon {
   extract( Palatine );
   set_metadata(Brave.Valeene, Palatine.Chatom);
   set_metadata(Brave.Wolford, Palatine.DesPeres);
   set_metadata(Brave.Huttig, Palatine.Sandoval);
   set_metadata(Brave.Vinings, 0);
   set_metadata(Brave.Millican, 1);
   return ingress;
}

parser Darden {
   extract( Stamford );
   set_metadata(Brave.Valeene, Stamford.Berenice);
   set_metadata(Brave.Wolford, Stamford.Bammel);
   set_metadata(Brave.Huttig, Stamford.Eclectic);
   set_metadata(Brave.Vinings, 1);
   set_metadata(Brave.Millican, 0);
   return ingress;
}

parser Marcus {
   extract( Kittredge );
   return select( Kittredge.Almont ) {
      Reinbeck: Clarendon;
      LaPlata: Darden;
      default: ingress;
   }
}
#endif

metadata Hewins Perrin;
metadata Washoe Century;
metadata Lovilia Riverwood;
metadata Manasquan Brave;
metadata Bonner Magma;
metadata Kenney Mishawaka;
metadata Maltby Wanatah;
metadata Millbrook Abernant;
metadata NewTrier Stockton;
metadata Quinhagak Corder;
metadata Puyallup Firesteel;
metadata Stewart Summit;
metadata Johnsburg Coronado;













#undef Wabuska

#undef Garibaldi
#undef Beechwood
#undef Jenifer
#undef Laurelton
#undef Lapel

#undef Bethesda
#undef Troutman
#undef Carlin

#undef Hurst
#undef Willows
#undef Mathias
#undef Karluk
#undef Pendroy
#undef BigRock
#undef Norcatur
#undef Dutton
#undef Devore
#undef Anniston
#undef Ankeny
#undef Beasley
#undef Mahomet
#undef Atwater
#undef Ardsley
#undef Castle
#undef Lowland
#undef Fairmount
#undef Anaconda
#undef Walcott
#undef Maybeury

#undef Pittsboro
#undef Tomato
#undef Ivins
#undef Brinkley
#undef MoonRun
#undef Elkton
#undef Whitewood
#undef Berkey
#undef Richwood
#undef Yakima
#undef Hartville
#undef Indrio
#undef Nanakuli
#undef Willette
#undef Rippon
#undef Yorkville
#undef UnionGap
#undef Emigrant
#undef Paradise
#undef Inverness
#undef Dunbar

#undef Higgston
#undef Separ

#undef Petroleum

#undef Belmore
#undef Gorman







#define Wabuska 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Garibaldi      65536
#define Beechwood      65536
#define Jenifer 512
#define Laurelton 512
#define Lapel      512


#define Bethesda     1024
#define Troutman    1024
#define Carlin     256


#define Hurst 512
#define Willows 65536
#define Mathias 65536
#define Karluk 28672
#define Pendroy   16384
#define BigRock 8192
#define Norcatur         131072
#define Dutton 65536
#define Devore 1024
#define Anniston 2048
#define Ankeny 16384
#define Beasley 8192
#define Mahomet 65536

#define Atwater 0x0000000000000000FFFFFFFFFFFFFFFF


#define Ardsley 0x000fffff
#define Fairmount 2

#define Castle 0xFFFFFFFFFFFFFFFF0000000000000000

#define Lowland 0x000007FFFFFFFFFF0000000000000000
#define Anaconda  6
#define Maybeury        2048
#define Walcott       65536


#define Pittsboro 1024
#define Tomato 4096
#define Ivins 4096
#define Brinkley 4096
#define MoonRun 4096
#define Elkton 1024
#define Whitewood 4096
#define Richwood 128
#define Yakima 1
#define Hartville  8


#define Indrio 512
#define Higgston 512
#define Separ 256


#define Nanakuli 2
#define Willette 3
#define Rippon 80



#define Yorkville 512
#define UnionGap 512
#define Emigrant 512
#define Paradise 512

#define Inverness 2048
#define Dunbar 1024



#define Petroleum 0


#define Belmore    4096
#define Gorman    1024

#endif



#ifndef Jonesport
#define Jonesport

action LasLomas() {
   no_op();
}

action Ramapo() {
   modify_field(Perrin.Elmdale, 1 );
   mark_for_drop();
}

action Monkstown() {
   no_op();
}
#endif




#define Terry            0
#define Harvest  1
#define Rives 2


#define Lydia              0
#define Power             1
#define Germano 2


















action Loris(RioLajas, Revere, Neubert, Nederland, Fennimore, Tennessee,
                 Domestic, Lansing, Mammoth) {
    modify_field(Riverwood.LaSal, RioLajas);
    modify_field(Riverwood.Almond, Revere);
    modify_field(Riverwood.Carroll, Neubert);
    modify_field(Riverwood.Robbs, Nederland);
    modify_field(Riverwood.Adamstown, Fennimore);
    modify_field(Riverwood.Renick, Tennessee);
    modify_field(Riverwood.Tekonsha, Domestic);
    modify_field(Riverwood.Kahaluu, Lansing);
    modify_field(Riverwood.Lakebay, Mammoth);
}

@pragma command_line --no-dead-code-elimination
table Amalga {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Loris;
    }
    size : Wabuska;
}

control Handley {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Amalga);
    }
}





action Upson(Tyrone) {
   modify_field( Century.PortVue, 1 );
   modify_field( Century.Metzger, Tyrone);
   modify_field( Perrin.BigArm, 1 );
}

action Maupin() {
   modify_field( Perrin.Haworth, 1 );
   modify_field( Perrin.Topmost, 1 );
}

action Lenwood() {
   modify_field( Perrin.BigArm, 1 );
}

action Gratiot() {
   modify_field( Perrin.Kinde, 1 );
}

action Kinsley() {
   modify_field( Perrin.Topmost, 1 );
}

counter Frankfort {
   type : packets_and_bytes;
   direct : Lamkin;
   min_width: 16;
}

table Lamkin {
   reads {
      Riverwood.Renick : exact;
      Rankin.Lewistown : ternary;
      Rankin.Helen : ternary;
   }

   actions {
      Upson;
      Maupin;
      Lenwood;
      Gratiot;
      Kinsley;
   }
   size : Jenifer;
}

action Swedeborg() {
   modify_field( Perrin.Bardwell, 1 );
}


table Chaires {
   reads {
      Rankin.Weissert : ternary;
      Rankin.Assinippi : ternary;
   }

   actions {
      Swedeborg;
   }
   size : Laurelton;
}


control Kenyon {
   apply( Lamkin );
   apply( Chaires );
}




action Penrose() {
   modify_field( Magma.Newberg, Palatine.Niota );
   modify_field( Magma.Ossining, Palatine.Stonebank );
   modify_field( Magma.Hopedale, Palatine.Geeville );
   modify_field( Mishawaka.Westel, Stamford.Grannis );
   modify_field( Mishawaka.Sabina, Stamford.Lumpkin );
   modify_field( Mishawaka.Alabaster, Stamford.Leona );
   modify_field( Mishawaka.Shelbiana, Stamford.Hatchel );
   modify_field( Perrin.McCracken, Kittredge.Lewistown );
   modify_field( Perrin.SweetAir, Kittredge.Helen );
   modify_field( Perrin.Alvordton, Kittredge.Weissert );
   modify_field( Perrin.Pittwood, Kittredge.Assinippi );
   modify_field( Perrin.Steprock, Kittredge.Almont );
   modify_field( Perrin.Crystola, Brave.Huttig );
   modify_field( Perrin.Greycliff, Brave.Valeene );
   modify_field( Perrin.Volens, Brave.Wolford );
   modify_field( Perrin.Newcastle, Brave.Millican );
   modify_field( Perrin.Bouton, Brave.Vinings );
   modify_field( Perrin.Sonoma, 0 );
   modify_field( Perrin.Philbrook, 0 );
   modify_field( Riverwood.Tekonsha, 2 );
   modify_field( Riverwood.Kahaluu, 0 );
   modify_field( Riverwood.Lakebay, 0 );
   modify_field( Century.Devers, Power );
}

action Anthony() {
   modify_field( Perrin.OakCity, Wailuku );
   modify_field( Magma.Newberg, Halfa.Niota );
   modify_field( Magma.Ossining, Halfa.Stonebank );
   modify_field( Magma.Hopedale, Halfa.Geeville );
   modify_field( Mishawaka.Westel, Pinetop.Grannis );
   modify_field( Mishawaka.Sabina, Pinetop.Lumpkin );
   modify_field( Mishawaka.Alabaster, Pinetop.Leona );
   modify_field( Mishawaka.Shelbiana, Pinetop.Hatchel );
   modify_field( Perrin.McCracken, Rankin.Lewistown );
   modify_field( Perrin.SweetAir, Rankin.Helen );
   modify_field( Perrin.Alvordton, Rankin.Weissert );
   modify_field( Perrin.Pittwood, Rankin.Assinippi );
   modify_field( Perrin.Steprock, Rankin.Almont );
   modify_field( Perrin.Crystola, Brave.Calabasas );
   modify_field( Perrin.Greycliff, Brave.Lizella );
   modify_field( Perrin.Volens, Brave.DeSart );
   modify_field( Perrin.Newcastle, Brave.ElkPoint );
   modify_field( Perrin.Bouton, Brave.Tarlton );
   modify_field( Perrin.Casper, Lamison[0].Moquah );
   modify_field( Perrin.Sonoma, Brave.Kohrville );
}

table Basehor {
   reads {
      Rankin.Lewistown : exact;
      Rankin.Helen : exact;
      Halfa.Stonebank : exact;
      Perrin.OakCity : exact;
   }

   actions {
      Penrose;
      Anthony;
   }

   default_action : Anthony();
   size : Pittsboro;
}


action Monahans() {
   modify_field( Perrin.Maybell, Riverwood.Carroll );
   modify_field( Perrin.Readsboro, Riverwood.LaSal);
}

action Onarga( Oronogo ) {
   modify_field( Perrin.Maybell, Oronogo );
   modify_field( Perrin.Readsboro, Riverwood.LaSal);
}

action Talmo() {
   modify_field( Perrin.Maybell, Lamison[0].Floris );
   modify_field( Perrin.Readsboro, Riverwood.LaSal);
}

table Caulfield {
   reads {
      Riverwood.LaSal : ternary;
      Lamison[0] : valid;
      Lamison[0].Floris : ternary;
   }

   actions {
      Monahans;
      Onarga;
      Talmo;
   }
   size : Brinkley;
}

action Elliston( Waialua ) {
   modify_field( Perrin.Readsboro, Waialua );
}

action Diomede() {

   modify_field( Perrin.Halliday, 1 );
   modify_field( Stockton.SeaCliff,
                 Chambers );
}

table Ronan {
   reads {
      Halfa.Niota : exact;
   }

   actions {
      Elliston;
      Diomede;
   }
   default_action : Diomede;
   size : Ivins;
}

action Laton( Kremlin, Rocky, Bergoo, Selvin, Mooreland,
                        Halltown, Leola ) {
   modify_field( Perrin.Maybell, Kremlin );
   modify_field( Perrin.Morgana, Kremlin );
   modify_field( Perrin.Funkley, Leola );
   Onycha(Rocky, Bergoo, Selvin, Mooreland,
                        Halltown );
}

action Ivanpah() {
   modify_field( Perrin.Stryker, 1 );
}

table Cochise {
   reads {
      Mendon.Juneau : exact;
   }

   actions {
      Laton;
      Ivanpah;
   }
   size : Tomato;
}

action Onycha(Lucien, Cabery, Lenoir, Tallassee,
                        Monaca ) {
   modify_field( Abernant.Crossett, Lucien );
   modify_field( Abernant.WebbCity, Cabery );
   modify_field( Abernant.Towaoc, Lenoir );
   modify_field( Abernant.Meeker, Tallassee );
   modify_field( Abernant.Grapevine, Monaca );
}

action Russia(Kulpmont, Tramway, Ionia, Algodones,
                        Martelle ) {
   modify_field( Perrin.Morgana, Riverwood.Carroll );
   modify_field( Perrin.Funkley, 1 );
   Onycha(Kulpmont, Tramway, Ionia, Algodones,
                        Martelle );
}

action Slana(Campton, Radom, Onava, WallLake,
                        Tamaqua, Covington ) {
   modify_field( Perrin.Morgana, Campton );
   modify_field( Perrin.Funkley, 1 );
   Onycha(Radom, Onava, WallLake, Tamaqua,
                        Covington );
}

action VanWert(Stillmore, Moxley, Onley, Murchison,
                        Reydon ) {
   modify_field( Perrin.Morgana, Lamison[0].Floris );
   modify_field( Perrin.Funkley, 1 );
   Onycha(Stillmore, Moxley, Onley, Murchison,
                        Reydon );
}

table Manistee {
   reads {
      Riverwood.Carroll : exact;
   }


   actions {
      LasLomas;
      Russia;
   }

   size : MoonRun;
}

@pragma action_default_only LasLomas
table Alcester {
   reads {
      Riverwood.LaSal : exact;
      Lamison[0].Floris : exact;
   }

   actions {
      Slana;
      LasLomas;
   }

   size : Elkton;
}

table Accomac {
   reads {
      Lamison[0].Floris : exact;
   }


   actions {
      LasLomas;
      VanWert;
   }

   size : Whitewood;
}

control Joplin {
   apply( Basehor ) {
         Penrose {
            apply( Ronan );
            apply( Cochise );
         }
         Anthony {
            if ( not valid(Mattapex) and Riverwood.Robbs == 1 ) {
               apply( Caulfield );
            }
            if ( valid( Lamison[ 0 ] ) ) {

               apply( Alcester ) {
                  LasLomas {

                     apply( Accomac );
                  }
               }
            } else {

               apply( Manistee );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Alcalde {
    width  : 1;
    static : Catawissa;
    instance_count : 262144;
}

register NewSite {
    width  : 1;
    static : Enhaut;
    instance_count : 262144;
}

blackbox stateful_alu Goldsmith {
    reg : Alcalde;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Wanatah.LongPine;
}

blackbox stateful_alu Mizpah {
    reg : NewSite;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Wanatah.Lepanto;
}

field_list Pierpont {
    Riverwood.Renick;
    Lamison[0].Floris;
}

field_list_calculation OjoFeliz {
    input { Pierpont; }
    algorithm: identity;
    output_width: 18;
}

action Craigmont() {
    Goldsmith.execute_stateful_alu_from_hash(OjoFeliz);
}

action Baytown() {
    Mizpah.execute_stateful_alu_from_hash(OjoFeliz);
}

table Catawissa {
    actions {
      Craigmont;
    }
    default_action : Craigmont;
    size : 1;
}

table Enhaut {
    actions {
      Baytown;
    }
    default_action : Baytown;
    size : 1;
}
#endif

action Osakis(Naubinway) {
    modify_field(Wanatah.Lepanto, Naubinway);
}

@pragma  use_hash_action 0
table Elkville {
    reads {
       Riverwood.Renick : exact;
    }
    actions {
      Osakis;
    }
    size : 64;
}

action Luttrell() {
   modify_field( Perrin.Denhoff, Riverwood.Carroll );
   modify_field( Perrin.Willard, 0 );
}

table Tununak {
   actions {
      Luttrell;
   }
   size : 1;
}

action Eaton() {
   modify_field( Perrin.Denhoff, Lamison[0].Floris );
   modify_field( Perrin.Willard, 1 );
}

table Belmont {
   actions {
      Eaton;
   }
   size : 1;
}

control Tahuya {
   if ( valid( Lamison[ 0 ] ) ) {
      apply( Belmont );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Riverwood.Adamstown == 1 ) {
         apply( Catawissa );
         apply( Enhaut );
      }
#endif
   } else {
      apply( Tununak );
      if( Riverwood.Adamstown == 1 ) {
         apply( Elkville );
      }
   }
}




field_list Ellinger {
   Rankin.Lewistown;
   Rankin.Helen;
   Rankin.Weissert;
   Rankin.Assinippi;
   Rankin.Almont;
}

field_list Haines {

   Halfa.Chatom;
   Halfa.Niota;
   Halfa.Stonebank;
}

field_list Westvaco {
   Pinetop.Grannis;
   Pinetop.Lumpkin;
   Pinetop.Leona;
   Pinetop.Berenice;
}

field_list Northboro {
   Halfa.Niota;
   Halfa.Stonebank;
   Grantfork.Casnovia;
   Grantfork.Buckhorn;
}





field_list_calculation ViewPark {
    input {
        Ellinger;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation BigBow {
    input {
        Haines;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Slick {
    input {
        Westvaco;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Foster {
    input {
        Northboro;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Lackey() {
    modify_field_with_hash_based_offset(Summit.Kalkaska, 0,
                                        ViewPark, 4294967296);
}

action Florida() {
    modify_field_with_hash_based_offset(Summit.Progreso, 0,
                                        BigBow, 4294967296);
}

action Flasher() {
    modify_field_with_hash_based_offset(Summit.Progreso, 0,
                                        Slick, 4294967296);
}

action Monida() {
    modify_field_with_hash_based_offset(Summit.Encinitas, 0,
                                        Foster, 4294967296);
}

table Caroleen {
   actions {
      Lackey;
   }
   size: 1;
}

control Blevins {
   apply(Caroleen);
}

table Anson {
   actions {
      Florida;
   }
   size: 1;
}

table Yscloskey {
   actions {
      Flasher;
   }
   size: 1;
}

control Perrytown {
   if ( valid( Halfa ) ) {
      apply(Anson);
   } else {
      if ( valid( Pinetop ) ) {
         apply(Yscloskey);
      }
   }
}

table Humacao {
   actions {
      Monida;
   }
   size: 1;
}

control Gould {
   if ( valid( Almeria ) ) {
      apply(Humacao);
   }
}



action Woodridge() {
    modify_field(Firesteel.Boysen, Summit.Kalkaska);
}

action Dassel() {
    modify_field(Firesteel.Boysen, Summit.Progreso);
}

action Camilla() {
    modify_field(Firesteel.Boysen, Summit.Encinitas);
}

@pragma action_default_only LasLomas
@pragma immediate 0
table Christina {
   reads {
      Yorkshire.valid : ternary;
      Cantwell.valid : ternary;
      Palatine.valid : ternary;
      Stamford.valid : ternary;
      Kittredge.valid : ternary;
      Equality.valid : ternary;
      Almeria.valid : ternary;
      Halfa.valid : ternary;
      Pinetop.valid : ternary;
      Rankin.valid : ternary;
   }
   actions {
      Woodridge;
      Dassel;
      Camilla;
      LasLomas;
   }
   size: Carlin;
}

action ElPortal() {
    modify_field(Firesteel.Burtrum, Summit.Encinitas);
}

@pragma immediate 0
table BallClub {
   reads {
      Yorkshire.valid : ternary;
      Cantwell.valid : ternary;
      Equality.valid : ternary;
      Almeria.valid : ternary;
   }
   actions {
      ElPortal;
      LasLomas;
   }
   size: Anaconda;
}

control Riverland {
   apply(BallClub);
   apply(Christina);
}



counter Pathfork {
   type : packets_and_bytes;
   direct : Telephone;
   min_width: 16;
}

table Telephone {
   reads {
      Riverwood.Renick : exact;
      Wanatah.Lepanto : ternary;
      Wanatah.LongPine : ternary;
      Perrin.Stryker : ternary;
      Perrin.Bardwell : ternary;
      Perrin.Haworth : ternary;
   }

   actions {
      Ramapo;
      LasLomas;
   }
   default_action : LasLomas();
   size : Lapel;
}

action Skyway() {

   modify_field(Perrin.Parmerton, 1 );
   modify_field(Stockton.SeaCliff,
                Coolin);
}







table Mango {
   reads {
      Perrin.Alvordton : exact;
      Perrin.Pittwood : exact;
      Perrin.Maybell : exact;
      Perrin.Readsboro : exact;
   }

   actions {
      Monkstown;
      Skyway;
   }
   default_action : Skyway();
   size : Beechwood;
   support_timeout : true;
}

action Baldridge() {
   modify_field( Abernant.Elmhurst, 1 );
}

table Sturgis {
   reads {
      Perrin.Morgana : ternary;
      Perrin.McCracken : exact;
      Perrin.SweetAir : exact;
   }
   actions {
      Baldridge;
   }
   size: Hurst;
}

control Luverne {
   apply( Telephone ) {
      LasLomas {



         if (Riverwood.Almond == 0 and Perrin.Halliday == 0) {
            apply( Mango );
         }
         apply(Sturgis);
      }
   }
}

field_list Madras {
    Stockton.SeaCliff;
    Perrin.Alvordton;
    Perrin.Pittwood;
    Perrin.Maybell;
    Perrin.Readsboro;
}

action Tatum() {
   generate_digest(Charenton, Madras);
}

table Shields {
   actions {
      Tatum;
   }
   size : 1;
}

control BigPlain {
   if (Perrin.Parmerton == 1) {
      apply( Shields );
   }
}



action Richlawn( Sanford, Belvue ) {
   modify_field( Mishawaka.Betterton, Sanford );
   modify_field( Corder.Orlinda, Belvue );
}

@pragma action_default_only Mecosta
table Qulin {
   reads {
      Abernant.Crossett : exact;
      Mishawaka.Sabina mask Castle : lpm;
   }
   actions {
      Richlawn;
      Mecosta;
   }
   size : Beasley;
}

@pragma atcam_partition_index Mishawaka.Betterton
@pragma atcam_number_partitions Beasley
table Nestoria {
   reads {
      Mishawaka.Betterton : exact;
      Mishawaka.Sabina mask Lowland : lpm;
   }

   actions {
      Keenes;
      Kaaawa;
      LasLomas;
   }
   default_action : LasLomas();
   size : Mahomet;
}

action Loretto( Guayabal, Sixteen ) {
   modify_field( Mishawaka.Woolsey, Guayabal );
   modify_field( Corder.Orlinda, Sixteen );
}

@pragma action_default_only LasLomas
table Maiden {


   reads {
      Abernant.Crossett : exact;
      Mishawaka.Sabina : lpm;
   }

   actions {
      Loretto;
      LasLomas;
   }

   size : Anniston;
}

@pragma atcam_partition_index Mishawaka.Woolsey
@pragma atcam_number_partitions Anniston
table Melba {
   reads {
      Mishawaka.Woolsey : exact;


      Mishawaka.Sabina mask Atwater : lpm;
   }
   actions {
      Keenes;
      Kaaawa;
      LasLomas;
   }

   default_action : LasLomas();
   size : Ankeny;
}

@pragma action_default_only Mecosta
@pragma idletime_precision 1
table Alakanuk {

   reads {
      Abernant.Crossett : exact;
      Magma.Ossining : lpm;
   }

   actions {
      Keenes;
      Kaaawa;
      Mecosta;
   }

   size : Devore;
   support_timeout : true;
}

action Nickerson( Powderly, Plandome ) {
   modify_field( Magma.Neshaminy, Powderly );
   modify_field( Corder.Orlinda, Plandome );
}

@pragma action_default_only LasLomas
#ifdef PROFILE_DEFAULT
@pragma stage 2 BigRock
@pragma stage 3
#endif
table MillHall {
   reads {
      Abernant.Crossett : exact;
      Magma.Ossining : lpm;
   }

   actions {
      Nickerson;
      LasLomas;
   }

   size : Pendroy;
}

@pragma ways Fairmount
@pragma atcam_partition_index Magma.Neshaminy
@pragma atcam_number_partitions Pendroy
table Balmorhea {
   reads {
      Magma.Neshaminy : exact;
      Magma.Ossining mask Ardsley : lpm;
   }
   actions {
      Keenes;
      Kaaawa;
      LasLomas;
   }
   default_action : LasLomas();
   size : Norcatur;
}

action Keenes( WestPark ) {
   modify_field( Corder.Orlinda, WestPark );
}

@pragma idletime_precision 1
table Alexis {
   reads {
      Abernant.Crossett : exact;
      Magma.Ossining : exact;
   }

   actions {
      Keenes;
      Kaaawa;
      LasLomas;
   }
   default_action : LasLomas();
   size : Willows;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
@pragma stage 2 Karluk
@pragma stage 3
#endif
table Bowdon {
   reads {
      Abernant.Crossett : exact;
      Mishawaka.Sabina : exact;
   }

   actions {
      Keenes;
      Kaaawa;
      LasLomas;
   }
   default_action : LasLomas();
   size : Mathias;
   support_timeout : true;
}

action EastDuke(Macdona, Hobucken, Timnath) {
   modify_field(Century.Crane, Timnath);
   modify_field(Century.Freetown, Macdona);
   modify_field(Century.Comunas, Hobucken);
   modify_field(Century.Tuscumbia, 1);

   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}

action Loysburg() {
   Ramapo();
}

action Grandy(Harshaw) {
   modify_field(Century.PortVue, 1);
   modify_field(Century.Metzger, Harshaw);
}

action Mecosta() {
   modify_field( Century.PortVue, 1 );
   modify_field( Century.Metzger, 9 );
}

table Lafayette {
   reads {
      Corder.Orlinda : exact;
   }

   actions {
      EastDuke;
      Loysburg;
      Grandy;
   }
   size : Dutton;
}

control McLaurin {
   if ( Perrin.Elmdale == 0 and Abernant.Elmhurst == 1 ) {
      if ( ( Abernant.WebbCity == 1 ) and ( Perrin.Newcastle == 1 ) ) {
         apply( Alexis ) {
            LasLomas {
               apply( MillHall ) {
                  Nickerson {
                     apply( Balmorhea );
                  }
                  LasLomas {
                     apply( Alakanuk );
                  }
               }
            }
         }
      } else if ( ( Abernant.Towaoc == 1 ) and ( Perrin.Bouton == 1 ) ) {
         apply( Bowdon ) {
            LasLomas {
               apply( Maiden ) {
                  Loretto {
                     apply( Melba );
                  }
                  LasLomas {

                     apply( Qulin ) {
                        Richlawn {
                           apply( Nestoria );
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Protivin {
   if( Corder.Orlinda != 0 ) {
      apply( Lafayette );
   }
}

action Kaaawa( Silesia ) {
   modify_field( Corder.Hopeton, Silesia );
}

field_list Sneads {
   Firesteel.Burtrum;
}

field_list_calculation Bevington {
    input {
        Sneads;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Powelton {
   selection_key : Bevington;
   selection_mode : resilient;
}

action_profile Forman {
   actions {
      Keenes;
   }
   size : Walcott;
   dynamic_action_selection : Powelton;
}

table Belvidere {
   reads {
      Corder.Hopeton : exact;
   }
   action_profile : Forman;
   size : Maybeury;
}

control Ballinger {
   if ( Corder.Hopeton != 0 ) {
      apply( Belvidere );
   }
}



field_list Bellport {
   Firesteel.Boysen;
}

field_list_calculation Fayette {
    input {
        Bellport;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Hopkins {
    selection_key : Fayette;
    selection_mode : resilient;
}

action Nettleton(Sherrill) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Sherrill);
}

action_profile Minneiska {
    actions {
        Nettleton;
        LasLomas;
    }
    size : Troutman;
    dynamic_action_selection : Hopkins;
}

table TiffCity {
   reads {
      Century.Pickett : exact;
   }
   action_profile: Minneiska;
   size : Bethesda;
}

control JimFalls {
   if ((Century.Pickett & 0x2000) == 0x2000) {
      apply(TiffCity);
   }
}



action Hines() {
   modify_field(Century.Freetown, Perrin.McCracken);
   modify_field(Century.Comunas, Perrin.SweetAir);
   modify_field(Century.Connell, Perrin.Alvordton);
   modify_field(Century.CoalCity, Perrin.Pittwood);
   modify_field(Century.Crane, Perrin.Maybell);
}

table Jigger {
   actions {
      Hines;
   }
   default_action : Hines();
   size : 1;
}

control Lathrop {
   if (Perrin.Maybell!=0 ) {
      apply( Jigger );
   }
}

action Mangham() {
   modify_field(Century.PineLake, 1);
   modify_field(Century.Ethete, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Perrin.Funkley);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Century.Crane);
}

action Pridgen() {
}



@pragma ways 1
table Hannah {
   reads {
      Century.Freetown : exact;
      Century.Comunas : exact;
   }
   actions {
      Mangham;
      Pridgen;
   }
   default_action : Pridgen;
   size : 1;
}

action Arkoe() {
   modify_field(Century.Grainola, 1);
   modify_field(Century.Talent, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Century.Crane, Harpster);
}

table Occoquan {
   actions {
      Arkoe;
   }
   default_action : Arkoe;
   size : 1;
}

action Mattese() {
   modify_field(Century.NewCity, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Century.Crane);
}

table LaMoille {
   actions {
      Mattese;
   }
   default_action : Mattese();
   size : 1;
}

action Sultana(Luhrig) {
   modify_field(Century.Anacortes, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Luhrig);
   modify_field(Century.Pickett, Luhrig);
}

action Topawa(Hayfield) {
   modify_field(Century.Grainola, 1);
   modify_field(Century.Farragut, Hayfield);
}

action Between() {
}

table Bouse {
   reads {
      Century.Freetown : exact;
      Century.Comunas : exact;
      Century.Crane : exact;
   }

   actions {
      Sultana;
      Topawa;
      Between;
   }
   default_action : Between();
   size : Garibaldi;
}

control Robbins {
   if (Perrin.Elmdale == 0 and not valid(Mattapex) ) {
      apply(Bouse) {
         Between {
            apply(Hannah) {
               Pridgen {
                  if ((Century.Freetown & 0x010000) == 0x010000) {
                     apply(Occoquan);
                  } else {
                     apply(LaMoille);
                  }
               }
            }
         }
      }
   }
}

action Catskill() {
   modify_field(Perrin.Attalla, 1);
   Ramapo();
}

table Danforth {
   actions {
      Catskill;
   }
   default_action : Catskill;
   size : 1;
}

control Rapids {
   if (Perrin.Elmdale == 0) {
      if ((Century.Tuscumbia==0) and (Perrin.BigArm==0) and (Perrin.Kinde==0) and (Perrin.Readsboro==Century.Pickett)) {
         apply(Danforth);
      }
   }
}

action Nipton(August) {
    modify_field(ig_intr_md_for_tm.level2_exclusion_id, August);
}

table Barnhill {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Nipton;
    }
    size : 512;
}

control Bethania {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Barnhill);
   }
}



action Oakmont( Macedonia ) {
   modify_field( Century.Bergton, Macedonia );
}

action Elwood() {
   modify_field( Century.Bergton, Century.Crane );
}

table Arminto {
   reads {
      eg_intr_md.egress_port : exact;
      Century.Crane : exact;
   }

   actions {
      Oakmont;
      Elwood;
   }
   default_action : Elwood;
   size : Belmore;
}

control Barnard {
   apply( Arminto );
}



action Alden( Altus, Butler ) {
   modify_field( Century.Arion, Altus );
   modify_field( Century.Pedro, Butler );
}

action LeCenter( Benkelman, Heavener, Piermont, Holcut ) {
   modify_field( Century.Arion, Benkelman );
   modify_field( Century.Pedro, Heavener );
   modify_field( Century.Opelousas, Piermont );
   modify_field( Century.Tilton, Holcut );
}


table Madawaska {
   reads {
      Century.Issaquah : exact;
   }

   actions {
      Alden;
      LeCenter;
   }
   size : Hartville;
}

action Pinto(Fallis, Marley, Dauphin, Ozark) {
   modify_field( Century.Klawock, Fallis );
   modify_field( Century.Strasburg, Marley );
   modify_field( Century.BigWater, Dauphin );
   modify_field( Century.Wauseon, Ozark );
}

table Pinebluff {
   reads {
        Century.Sparland : exact;
   }
   actions {
      Pinto;
   }
   size : Separ;
}

action Shine() {
   no_op();
}

action Sunflower() {
   modify_field( Rankin.Almont, Lamison[0].Pickering );
   remove_header( Lamison[0] );
}

table Parmalee {
   actions {
      Sunflower;
   }
   default_action : Sunflower;
   size : Yakima;
}

action Gretna() {
   no_op();
}

action Burrel() {
   add_header( Lamison[ 0 ] );
   modify_field( Lamison[0].Floris, Century.Bergton );
   modify_field( Lamison[0].Pickering, Rankin.Almont );
   modify_field( Lamison[0].Nichols, Perrin.Philbrook );
   modify_field( Lamison[0].Moquah, Perrin.Casper );
   modify_field( Rankin.Almont, Dateland );
}



table Nunda {
   reads {
      Century.Bergton : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Gretna;
      Burrel;
   }
   default_action : Burrel;
   size : Richwood;
}

action Toulon() {
   modify_field(Rankin.Lewistown, Century.Freetown);
   modify_field(Rankin.Helen, Century.Comunas);
   modify_field(Rankin.Weissert, Century.Arion);
   modify_field(Rankin.Assinippi, Century.Pedro);
}

action Ovett() {
   Toulon();
   add_to_field(Halfa.DesPeres, -1);
}

action Oxford() {
   Toulon();
   add_to_field(Pinetop.Bammel, -1);
}

action Utuado() {
   Burrel();
}

action Novice() {
   add_header( Chantilly );
   modify_field( Chantilly.Lewistown, Century.Arion );
   modify_field( Chantilly.Helen, Century.Pedro );
   modify_field( Chantilly.Weissert, Century.Opelousas );
   modify_field( Chantilly.Assinippi, Century.Tilton );
   modify_field( Chantilly.Almont, Bramwell );
   add_header( Mattapex );
   modify_field( Mattapex.Bedrock, Century.Klawock );
   modify_field( Mattapex.Hapeville, Century.Strasburg );
   modify_field( Mattapex.Hershey, Century.BigWater );
   modify_field( Mattapex.Belen, Century.Wauseon );
   modify_field( Mattapex.Wharton, Century.Metzger );
}

action RoseBud() {
   remove_header( Mendon );
   remove_header( Almeria );
   remove_header( Grantfork );
   copy_header( Rankin, Kittredge );
   remove_header( Kittredge );
   remove_header( Halfa );
}

action Haena() {
   remove_header( Chantilly );
   remove_header( Mattapex );
}

table Wymer {
   reads {
      Century.Devers : exact;
      Century.Issaquah : exact;
      Century.Tuscumbia : exact;
      Halfa.valid : ternary;
      Pinetop.valid : ternary;
   }

   actions {
      Ovett;
      Oxford;
      Utuado;
      Novice;
      RoseBud;
      Haena;
   }
   size : Indrio;
}

control Lennep {
   apply( Parmalee );
}

control Haven {
   apply( Nunda );
}

control Borup {
   apply( Madawaska );
   apply( Pinebluff );
   apply( Wymer );
}



field_list Montour {
    Stockton.SeaCliff;
    Perrin.Maybell;
    Kittredge.Weissert;
    Kittredge.Assinippi;
    Halfa.Niota;
}

action Sandston() {
   generate_digest(Charenton, Montour);
}

table Avondale {
   actions {
      Sandston;
   }

   default_action : Sandston;
   size : 1;
}

control Valdosta {
   if (Perrin.Halliday == 1) {
      apply(Avondale);
   }
}



action Castine( Medart ) {
   modify_field( Coronado.Wellton, Medart );
}

action Estrella() {
   modify_field( Coronado.Wellton, 0 );
}

table Robins {
   reads {
     Perrin.Readsboro : ternary;
     Perrin.Morgana : ternary;
     Abernant.Elmhurst : ternary;
   }

   actions {
     Castine;
     Estrella;
   }

   default_action : Estrella();
   size : Yorkville;
}

action Daphne( WildRose ) {
   modify_field( Coronado.Perryman, WildRose );
   modify_field( Coronado.Edroy, 0 );
   modify_field( Coronado.SourLake, 0 );
}

action Northway( Wenham, Montegut ) {
   modify_field( Coronado.Perryman, 0 );
   modify_field( Coronado.Edroy, Wenham );
   modify_field( Coronado.SourLake, Montegut );
}

action Herald( Silva, Fowler, Turney ) {
   modify_field( Coronado.Perryman, Silva );
   modify_field( Coronado.Edroy, Fowler );
   modify_field( Coronado.SourLake, Turney );
}

action Clarinda() {
   modify_field( Coronado.Perryman, 0 );
   modify_field( Coronado.Edroy, 0 );
   modify_field( Coronado.SourLake, 0 );
}

table Bratenahl {
   reads {
     Coronado.Wellton : exact;
     Perrin.McCracken : ternary;
     Perrin.SweetAir : ternary;
     Perrin.Steprock : ternary;
   }

   actions {
     Daphne;
     Northway;
     Herald;
     Clarinda;
   }

   default_action : Clarinda();
   size : UnionGap;
}

table Whitetail {
   reads {
     Coronado.Wellton : exact;
     Magma.Ossining mask 0xffff0000 : ternary;
     Perrin.Greycliff : ternary;
     Perrin.Volens : ternary;
     Perrin.Agawam : ternary;
     Corder.Orlinda : ternary;

   }

   actions {
     Daphne;
     Northway;
     Herald;
     Clarinda;
   }

   default_action : Clarinda();
   size : Emigrant;
}

table Tontogany {
   reads {
     Coronado.Wellton : exact;
     Mishawaka.Sabina mask 0xffff0000 : ternary;
     Perrin.Greycliff : ternary;
     Perrin.Volens : ternary;
     Perrin.Agawam : ternary;
     Corder.Orlinda : ternary;

   }

   actions {
     Daphne;
     Northway;
     Herald;
     Clarinda;
   }

   default_action : Clarinda();
   size : Paradise;
}

meter Aldan {
   type : packets;
   static : Recluse;
   instance_count: Inverness;
}

action BigRiver( Odenton ) {
   // Unsupported address mode
   //execute_meter( Aldan, Odenton, ig_intr_md_for_tm.packet_color );
}

action Lansdale() {
   execute_meter( Aldan, Coronado.Edroy, ig_intr_md_for_tm.packet_color );
}

table Recluse {
   reads {
     Coronado.Edroy : ternary;
     Perrin.Readsboro : ternary;
     Perrin.Morgana : ternary;
     Abernant.Elmhurst : ternary;
     Coronado.SourLake : ternary;
   }
   actions {
      BigRiver;
      Lansdale;
   }
   size : Dunbar;
}

control Kalaloch {
   apply( Robins );
}

control LaHabra {
   if ( Perrin.Newcastle == 1 ) {
      apply( Whitetail );
   } else if ( Perrin.Bouton == 1 ) {
      apply( Tontogany );
   } else {
      apply( Bratenahl );
   }
}

control Twinsburg {
   apply( Recluse );
}



action China() {
   modify_field( Perrin.Philbrook, Riverwood.Kahaluu );
}



action Biddle() {
   modify_field( Perrin.Philbrook, Lamison[0].Nichols );
}

action Gobles() {
   modify_field( Perrin.Agawam, Riverwood.Lakebay );
}

action Hollyhill() {
   modify_field( Perrin.Agawam, Magma.Hopedale );
}

action Bridgton() {
   modify_field( Perrin.Agawam, Mishawaka.Shelbiana );
}

action Peletier( Chatawa, Joshua ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Chatawa );
   modify_field( ig_intr_md_for_tm.qid, Joshua );
}

table Rockham {
   reads {
     Perrin.Sonoma : exact;
   }

   actions {
     China;
     Biddle;
   }

   size : Nanakuli;
}

table Rixford {
   reads {
     Perrin.Newcastle : exact;
     Perrin.Bouton : exact;
   }

   actions {
     Gobles;
     Hollyhill;
     Bridgton;
   }

   size : Willette;
}

table Missoula {
   reads {
      Riverwood.Tekonsha : ternary;
      Riverwood.Kahaluu : ternary;
      Perrin.Philbrook : ternary;
      Perrin.Agawam : ternary;
      Coronado.Perryman : ternary;
   }

   actions {
      Peletier;
   }

   size : Rippon;
}

control Ferrum {
   apply( Rockham );
   apply( Rixford );
}

control Ledford {
   apply( Missoula );
}



action Newsoms( Telegraph ) {
   modify_field( Century.Issaquah, Harvest );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Telegraph );
}

action FairOaks( Kaltag ) {
   modify_field( Century.Issaquah, Rives );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Kaltag );
   modify_field( Century.Sparland, ig_intr_md.ingress_port );
}

table Skiatook {
   reads {
      Abernant.Elmhurst : exact;
      Riverwood.Robbs : ternary;
      Century.Metzger : ternary;
   }

   actions {
      Newsoms;
      FairOaks;
   }

   size : Higgston;
}

control Pacifica {
   apply( Skiatook );
}





counter Redvale {
   type : packets_and_bytes;
   direct : Bains;
   min_width: 32;
}

table Bains {
   reads {
      eg_intr_md.egress_port mask 0x7f : exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }

   actions {
      Monkstown;
   }

   size : Gorman;
}

control Knoke {
   apply( Bains );
}



action Iredell()
{



   Ramapo();
}

action Bairoil()
{
   modify_field(Century.Devers, Germano);
   bit_or(Century.Pickett, 0x2000, Mattapex.Belen);
}

action Antonito( Laney ) {
   modify_field(Century.Devers, Germano);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Laney);
   modify_field(Century.Pickett, Laney);
}

table DoeRun {
   reads {
      Mattapex.Bedrock : exact;
      Mattapex.Hapeville : exact;
      Mattapex.Hershey : exact;
      Mattapex.Belen : exact;
   }

   actions {
      Bairoil;
      Antonito;
      Iredell;
   }
   default_action : Iredell();
   size : Separ;
}

control Battles {
   apply( DoeRun );
}

control ingress {

   Handley();

   if( Riverwood.Adamstown != 0 ) {

      Kenyon();
   }

   Joplin();

   if( Riverwood.Adamstown != 0 ) {
      Tahuya();
      Luverne();
   }

   Blevins();


   Perrytown();
   Gould();

   if( Riverwood.Adamstown != 0 ) {

      McLaurin();
   }


   Riverland();


   if( Riverwood.Adamstown != 0 ) {
      Ballinger();
   }

   Lathrop();


   if( Riverwood.Adamstown != 0 ) {
      Protivin();
   }
   Ferrum();
   Kalaloch();




   Valdosta();
   BigPlain();
   if( Century.PortVue == 0 ) {
      Robbins();
   }


   LaHabra();

   if( Century.PortVue == 0 ) {
      if( not valid(Mattapex) ) {
         Rapids();
      } else {
         Battles();
      }
   } else {
      Pacifica();
   }


   if( valid( Lamison[0] ) ) {
      Lennep();
   }


   Ledford();
   if( Perrin.Elmdale == 0 ) {
      Twinsburg();
   }
   if( Century.PortVue == 0 ) {
      JimFalls();
      Bethania();
   }
}

control egress {
   Barnard();
   Borup();

   if( ( Century.PortVue == 0 ) and ( Century.Devers != Germano ) ) {
      Haven();
   }
   Knoke();
}

