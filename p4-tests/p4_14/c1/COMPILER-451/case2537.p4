// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 764







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>



#ifndef Issaquah
#define Issaquah

header_type Yscloskey {
	fields {
		Ohiowa : 16;
		Belcher : 16;
		Thistle : 8;
		Neches : 8;
		Tappan : 8;
		Lamona : 8;
		Calcasieu : 1;
		Eddington : 1;
		Anthon : 1;
		Calhan : 1;
		Kiwalik : 1;
		Golden : 3;
	}
}

header_type Whigham {
	fields {
		Newsome : 24;
		Wayland : 24;
		Cantwell : 24;
		MudLake : 24;
		Blevins : 16;
		Borup : 16;
		Rodessa : 16;
		Rainsburg : 16;
		Lisman : 16;
		Cascade : 8;
		Ewing : 8;
		Clintwood : 6;
		Sarepta : 1;
		Hiwasse : 1;
		Calcium : 12;
		Belfair : 2;
		Annandale : 1;
		Trilby : 1;
		Stanwood : 1;
		Waitsburg : 1;
		Deerwood : 1;
		Bluewater : 1;
		Fragaria : 1;
		Herald : 1;
		Wabbaseka : 1;
		Pacifica : 1;
		Lakin : 1;
		Guion : 1;
		Loretto : 1;
		Hartwick : 3;
	}
}

header_type Peoria {
	fields {
		Martelle : 24;
		Metter : 24;
		Kalvesta : 24;
		Komatke : 24;
		Larchmont : 24;
		Ogunquit : 24;
		Belwood : 24;
		Whitlash : 24;
		Shawmut : 16;
		Tanacross : 16;
		Ocracoke : 16;
		Watters : 16;
		Robinson : 12;
		Tenino : 3;
		Bairoa : 1;
		SanSimon : 3;
		Vichy : 1;
		Ahuimanu : 1;
		Neosho : 1;
		Flomot : 1;
		Affton : 1;
		Buckholts : 1;
		Nerstrand : 8;
		Norfork : 12;
		Otsego : 4;
		Bluff : 6;
		Arkoe : 10;
		Riner : 9;
		Oakmont : 1;
	}
}


header_type McDonough {
	fields {
		Parshall : 8;
		Harbor : 1;
		Burwell : 1;
		Daysville : 1;
		McCartys : 1;
		Exell : 1;
	}
}

header_type Placida {
	fields {
		Oskawalik : 32;
		RushHill : 32;
		Mapleview : 6;
		Balmville : 16;
	}
}

header_type Tolono {
	fields {
		Murphy : 128;
		PikeView : 128;
		Hamel : 20;
		Hershey : 8;
		Villanova : 11;
		Millston : 6;
		Riverwood : 13;
	}
}

header_type Bellwood {
	fields {
		Gower : 14;
		Kenton : 1;
		Lathrop : 12;
		McKee : 1;
		ElMirage : 1;
		Honokahua : 6;
		Orrstown : 2;
		Lepanto : 6;
		Palmerton : 3;
	}
}

header_type Honobia {
	fields {
		Telma : 1;
		Chandalar : 1;
	}
}

header_type Zarah {
	fields {
		Ferndale : 8;
	}
}

header_type Lenapah {
	fields {
		Calamus : 16;
		Admire : 11;
	}
}

header_type Cusseta {
	fields {
		Bellville : 32;
		Toxey : 32;
		Lauada : 32;
	}
}

header_type Sugarloaf {
	fields {
		Brush : 32;
		Pease : 32;
	}
}

header_type Cisco {
	fields {
		Glyndon : 8;
		Palco : 4;
		Penzance : 15;
		HillTop : 1;
	}
}
#endif



#ifndef Grampian
#define Grampian


header_type Bedrock {
	fields {
		Lowemont : 6;
		Nettleton : 10;
		Slagle : 4;
		Haworth : 12;
		Cannelton : 12;
		Hargis : 2;
		Cuney : 2;
		Wrens : 8;
		Latham : 3;
		Mathias : 5;
	}
}



header_type Netarts {
	fields {
		Yardley : 24;
		Wanatah : 24;
		Grantfork : 24;
		Walcott : 24;
		Flippen : 16;
	}
}



header_type Sturgeon {
	fields {
		Ranchito : 3;
		Bechyn : 1;
		Mariemont : 12;
		Aplin : 16;
	}
}



header_type Mekoryuk {
	fields {
		Anthony : 4;
		Carlson : 4;
		Utuado : 6;
		Darmstadt : 2;
		Markesan : 16;
		Gowanda : 16;
		Temple : 3;
		Craig : 13;
		Pelican : 8;
		Burmester : 8;
		Bonney : 16;
		Satolah : 32;
		Toluca : 32;
	}
}

header_type Sonestown {
	fields {
		Skime : 4;
		Waipahu : 6;
		Westline : 2;
		RioHondo : 20;
		Quinhagak : 16;
		Salus : 8;
		Othello : 8;
		Nutria : 128;
		Azalia : 128;
	}
}




header_type Manning {
	fields {
		HydePark : 8;
		Vevay : 8;
		Nuremberg : 16;
	}
}

header_type Thawville {
	fields {
		Rosboro : 16;
		Portal : 16;
		Twinsburg : 32;
		Naubinway : 32;
		Cedar : 4;
		Couchwood : 4;
		Chelsea : 8;
		NeckCity : 16;
		Hartwell : 16;
		ElmGrove : 16;
	}
}

header_type Heaton {
	fields {
		Duffield : 16;
		Raeford : 16;
		Neponset : 16;
		Salix : 16;
	}
}



header_type Pittwood {
	fields {
		Turkey : 16;
		Melba : 16;
		Mango : 8;
		Atlantic : 8;
		Wesson : 16;
	}
}

header_type Sabetha {
	fields {
		Angwin : 48;
		Chilson : 32;
		Elkader : 48;
		Delcambre : 32;
	}
}



header_type Bethesda {
	fields {
		Algonquin : 1;
		CleElum : 1;
		Ossipee : 1;
		Orting : 1;
		Lehigh : 1;
		LaJoya : 3;
		PaloAlto : 5;
		Kremlin : 3;
		Munger : 16;
	}
}

header_type Criner {
	fields {
		Trevorton : 24;
		Ephesus : 8;
	}
}



header_type Ralph {
	fields {
		Franktown : 8;
		Renfroe : 24;
		Newland : 24;
		Paragonah : 8;
	}
}

#endif



#ifndef Shickley
#define Shickley

#define Levittown        0x8100
#define Hector        0x0800
#define Weathers        0x86dd
#define Tunica        0x9100
#define Higgston        0x8847
#define Nevis         0x0806
#define Perrin        0x8035
#define Servia        0x88cc
#define WhiteOwl        0x8809
#define Lyndell      0xBF00

#define Abilene              1
#define Lindsborg              2
#define Auburn              4
#define Myton               6
#define Lambrook               17
#define Gerty                47

#define Lyncourt         0x501
#define Leicester          0x506
#define Bluford          0x511
#define Green          0x52F


#define Selvin                 4789



#define Goulds               0
#define Yreka              1
#define Mendham                2



#define Woolwine          0
#define Conda          4095
#define WestPike  4096
#define Boutte  8191



#define Belle                      0
#define LaLuz                  0
#define Bethania                 1

header Netarts Leetsdale;
header Netarts Donna;
header Sturgeon Casper[ 2 ];
header Mekoryuk Bowdon;
header Mekoryuk UtePark;
header Sonestown Wayne;
header Sonestown Strasburg;
header Thawville Syria;
header Heaton Dabney;
header Thawville Wells;
header Heaton Tinaja;
header Ralph Greycliff;
header Pittwood Layton;
header Bethesda Sunflower;
header Bedrock Wallula;
header Netarts Lemhi;

parser start {
   return select(current(96, 16)) {
      Lyndell : Gobles;
      default : Maybell;
   }
}

parser Palmer {
   extract( Wallula );
   return Maybell;
}

parser Gobles {
   extract( Lemhi );
   return Palmer;
}

parser Maybell {
   extract( Leetsdale );
   return select( Leetsdale.Flippen ) {
      Levittown : Wheeler;
      Hector : Forepaugh;
      Weathers : Moorman;
      Nevis  : Kniman;
      default        : ingress;
   }
}

parser Wheeler {
   extract( Casper[0] );

   set_metadata(Renton.Hartwick, Casper[0].Ranchito);
   set_metadata(Spiro.Kiwalik, 1);
   return select( Casper[0].Aplin ) {
      Hector : Forepaugh;
      Weathers : Moorman;
      Nevis  : Kniman;
      default : ingress;
   }
}

parser Forepaugh {
   extract( Bowdon );
   set_metadata(Spiro.Thistle, Bowdon.Burmester);
   set_metadata(Spiro.Tappan, Bowdon.Pelican);
   set_metadata(Spiro.Ohiowa, Bowdon.Markesan);
   set_metadata(Spiro.Anthon, 0);
   set_metadata(Spiro.Calcasieu, 1);
   return select(Bowdon.Craig, Bowdon.Carlson, Bowdon.Burmester) {
      Bluford : Swisshome;
      default : ingress;
   }
}

parser Moorman {
   extract( Strasburg );
   set_metadata(Spiro.Thistle, Strasburg.Salus);
   set_metadata(Spiro.Tappan, Strasburg.Othello);
   set_metadata(Spiro.Ohiowa, Strasburg.Quinhagak);
   set_metadata(Spiro.Anthon, 1);
   set_metadata(Spiro.Calcasieu, 0);
   return ingress;
}

parser Kniman {
   extract( Layton );
   return ingress;
}

parser Swisshome {
   extract(Dabney);
   return select(Dabney.Raeford) {
      Selvin : Advance;
      default : ingress;
    }
}

parser Youngwood {
   set_metadata(Renton.Belfair, Mendham);
   return Gustine;
}

parser Armagh {
   set_metadata(Renton.Belfair, Mendham);
   return Campton;
}

parser Curlew {
   extract(Sunflower);
   return select(Sunflower.Algonquin, Sunflower.CleElum, Sunflower.Ossipee, Sunflower.Orting, Sunflower.Lehigh,
             Sunflower.LaJoya, Sunflower.PaloAlto, Sunflower.Kremlin, Sunflower.Munger) {
      Hector : Youngwood;
      Weathers : Armagh;
      default : ingress;
   }
}

parser Advance {
   extract(Greycliff);
   set_metadata(Renton.Belfair, Yreka);
   return Monteview;
}

parser Gustine {
   extract( UtePark );
   set_metadata(Spiro.Neches, UtePark.Burmester);
   set_metadata(Spiro.Lamona, UtePark.Pelican);
   set_metadata(Spiro.Belcher, UtePark.Markesan);
   set_metadata(Spiro.Calhan, 0);
   set_metadata(Spiro.Eddington, 1);
   return ingress;
}

parser Campton {
   extract( Wayne );
   set_metadata(Spiro.Neches, Wayne.Salus);
   set_metadata(Spiro.Lamona, Wayne.Othello);
   set_metadata(Spiro.Belcher, Wayne.Quinhagak);
   set_metadata(Spiro.Calhan, 1);
   set_metadata(Spiro.Eddington, 0);
   return ingress;
}

parser Monteview {
   extract( Donna );
   return select( Donna.Flippen ) {
      Hector: Gustine;
      Weathers: Campton;
      default: ingress;
   }
}
#endif

metadata Whigham Renton;
metadata Peoria Laplace;

//@pragma pa_solitary ingress Harding.Lathrop
metadata Bellwood Harding;
metadata Yscloskey Spiro;
metadata Placida Antimony;
metadata Tolono Baldridge;
metadata Honobia Nondalton;
metadata McDonough Silva;
metadata Zarah Milesburg;
metadata Lenapah Dellslow;
metadata Sugarloaf Gunder;
metadata Cusseta Speed;
metadata Cisco Nason;













#undef Darien

#undef Ashtola
#undef Waucousta
#undef Fackler
#undef NewCity
#undef Fletcher

#undef Cranbury
#undef Allegan
#undef Roachdale

#undef Northway
#undef Charenton
#undef Maybee
#undef Chitina
#undef Johnsburg
#undef Cuprum
#undef Billett
#undef Grays
#undef Waterflow
#undef Tabler
#undef Candor
#undef Lewistown
#undef Burdette
#undef Christina
#undef Baltic
#undef Gladys
#undef Norias
#undef Bucklin
#undef Vincent
#undef Grants
#undef Crown

#undef DeSart
#undef Biehle
#undef Leeville
#undef Coconut
#undef Lostwood
#undef Mission
#undef Canton
#undef Judson
#undef Ferrum
#undef Malabar
#undef Oketo
#undef Lapoint
#undef Wallace
#undef Fentress
#undef Reynolds
#undef Wyanet
#undef Perma
#undef Yukon
#undef Fontana
#undef Kenvil
#undef Leflore

#undef Folger
#undef Teigen

#undef Akiachak

#undef Wenham







#define Darien 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Ashtola      65536
#define Waucousta      65536
#define Fackler 512
#define NewCity 512
#define Fletcher      512


#define Cranbury     1024
#define Allegan    1024
#define Roachdale     256


#define Northway 512
#define Charenton 65536
#define Maybee 65536
#define Chitina 28672
#define Johnsburg   16384
#define Cuprum 8192
#define Billett         131072
#define Grays 65536
#define Waterflow 1024
#define Tabler 2048
#define Candor 16384
#define Lewistown 8192
#define Burdette 65536

#define Christina 0x0000000000000000FFFFFFFFFFFFFFFF


#define Baltic 0x000fffff
#define Bucklin 2

#define Gladys 0xFFFFFFFFFFFFFFFF0000000000000000

#define Norias 0x000007FFFFFFFFFF0000000000000000
#define Vincent  6
#define Crown        2048
#define Grants       65536


#define DeSart 1024
#define Biehle 4096
#define Leeville 4096
#define Coconut 4096
#define Lostwood 4096
#define Mission 1024
#define Canton 4096
#define Ferrum 128
#define Malabar 1
#define Oketo  8


#define Lapoint 512
#define Folger 512
#define Teigen 256


#define Wallace 1
#define Fentress 3
#define Reynolds 80



#define Wyanet 512
#define Perma 512
#define Yukon 512
#define Fontana 512

#define Kenvil 2048
#define Leflore 1024



#define Akiachak 0


#define Wenham    4096

#endif



#ifndef Stonefort
#define Stonefort

action Whitefish() {
   no_op();
}

action Hollyhill() {
   modify_field(Renton.Waitsburg, 1 );
   mark_for_drop();
}

action Onley() {
   no_op();
}
#endif

















action Pridgen(Handley, Belfalls, Panaca, Langlois, Macon, Clearco,
                 Bosworth, Kaibab, OldGlory) {
    modify_field(Harding.Gower, Handley);
    modify_field(Harding.Kenton, Belfalls);
    modify_field(Harding.Lathrop, Panaca);
    modify_field(Harding.McKee, Langlois);
    modify_field(Harding.ElMirage, Macon);
    modify_field(Harding.Honokahua, Clearco);
    modify_field(Harding.Orrstown, Bosworth);
    modify_field(Harding.Palmerton, Kaibab);
    modify_field(Harding.Lepanto, OldGlory);
}

@pragma command_line --no-dead-code-elimination
table Wetumpka {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Pridgen;
    }
    size : Darien;
}

control Neavitt {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Wetumpka);
    }
}





action Achille(Halsey) {
   modify_field( Laplace.Bairoa, 1 );
   modify_field( Laplace.Nerstrand, Halsey);
   modify_field( Renton.Pacifica, 1 );
}

action Maupin() {
   modify_field( Renton.Fragaria, 1 );
   modify_field( Renton.Guion, 1 );
}

action Finlayson() {
   modify_field( Renton.Pacifica, 1 );
}

action Bernard() {
   modify_field( Renton.Lakin, 1 );
}

action Alnwick() {
   modify_field( Renton.Guion, 1 );
}

counter Orrville {
   type : packets_and_bytes;
   direct : Kealia;
   min_width: 16;
}

table Kealia {
   reads {
      Harding.Honokahua : exact;
      Leetsdale.Yardley : ternary;
      Leetsdale.Wanatah : ternary;
   }

   actions {
      Achille;
      Maupin;
      Finlayson;
      Bernard;
      Alnwick;
   }
   size : Fackler;
}

action Owanka() {
   modify_field( Renton.Herald, 1 );
}


table Eugene {
   reads {
      Leetsdale.Grantfork : ternary;
      Leetsdale.Walcott : ternary;
   }

   actions {
      Owanka;
   }
   size : NewCity;
}


control Cement {
   apply( Kealia );
   apply( Eugene );
}




action Faulkton() {
   modify_field( Antimony.Oskawalik, UtePark.Satolah );
   modify_field( Antimony.RushHill, UtePark.Toluca );
   modify_field( Antimony.Mapleview, UtePark.Utuado );
   modify_field( Baldridge.Murphy, Wayne.Nutria );
   modify_field( Baldridge.PikeView, Wayne.Azalia );
   modify_field( Baldridge.Hamel, Wayne.RioHondo );
   modify_field( Baldridge.Millston, Wayne.Waipahu );
   modify_field( Renton.Newsome, Donna.Yardley );
   modify_field( Renton.Wayland, Donna.Wanatah );
   modify_field( Renton.Cantwell, Donna.Grantfork );
   modify_field( Renton.MudLake, Donna.Walcott );
   modify_field( Renton.Blevins, Donna.Flippen );
   modify_field( Renton.Lisman, Spiro.Belcher );
   modify_field( Renton.Cascade, Spiro.Neches );
   modify_field( Renton.Ewing, Spiro.Lamona );
   modify_field( Renton.Hiwasse, Spiro.Eddington );
   modify_field( Renton.Sarepta, Spiro.Calhan );
   modify_field( Renton.Loretto, 0 );
   modify_field( Renton.Hartwick, 0 );
   modify_field( Harding.Orrstown, 2 );
   modify_field( Harding.Palmerton, 0 );
   modify_field( Harding.Lepanto, 0 );
}

action Waukesha() {
   modify_field( Renton.Belfair, Goulds );
   modify_field( Antimony.Oskawalik, Bowdon.Satolah );
   modify_field( Antimony.RushHill, Bowdon.Toluca );
   modify_field( Antimony.Mapleview, Bowdon.Utuado );
   modify_field( Baldridge.Murphy, Strasburg.Nutria );
   modify_field( Baldridge.PikeView, Strasburg.Azalia );
   modify_field( Baldridge.Hamel, Strasburg.RioHondo );
   modify_field( Baldridge.Millston, Strasburg.Waipahu );
   modify_field( Renton.Newsome, Leetsdale.Yardley );
   modify_field( Renton.Wayland, Leetsdale.Wanatah );
   modify_field( Renton.Cantwell, Leetsdale.Grantfork );
   modify_field( Renton.MudLake, Leetsdale.Walcott );
   modify_field( Renton.Blevins, Leetsdale.Flippen );
   modify_field( Renton.Lisman, Spiro.Ohiowa );
   modify_field( Renton.Cascade, Spiro.Thistle );
   modify_field( Renton.Ewing, Spiro.Tappan );
   modify_field( Renton.Hiwasse, Spiro.Calcasieu );
   modify_field( Renton.Sarepta, Spiro.Anthon );

   modify_field( Renton.Loretto, Spiro.Kiwalik );
}

table Grasston {
   reads {
      Leetsdale.Yardley : exact;
      Leetsdale.Wanatah : exact;
      Bowdon.Toluca : exact;
      Renton.Belfair : exact;
   }

   actions {
      Faulkton;
      Waukesha;
   }

   default_action : Waukesha();
   size : DeSart;
}


action Baskett() {
   modify_field( Renton.Borup, Harding.Lathrop );
   modify_field( Renton.Rodessa, Harding.Gower);
}

action Waretown( Yardville ) {
   modify_field( Renton.Borup, Yardville );
   modify_field( Renton.Rodessa, Harding.Gower);
}

action Woodfords() {
   modify_field( Renton.Borup, Casper[0].Mariemont );
   modify_field( Renton.Rodessa, Harding.Gower);
}

table Petrolia {
   reads {
      Harding.Gower : ternary;
      Casper[0] : valid;
      Casper[0].Mariemont : ternary;
   }

   actions {
      Baskett;
      Waretown;
      Woodfords;
   }
   size : Coconut;
}

action Wabuska( Hilburn ) {
   modify_field( Renton.Rodessa, Hilburn );
}

action Harviell() {

   modify_field( Renton.Stanwood, 1 );
   modify_field( Milesburg.Ferndale,
                 Bethania );
}

table Lilymoor {
   reads {
      Bowdon.Satolah : exact;
   }

   actions {
      Wabuska;
      Harviell;
   }
   default_action : Harviell;
   size : Leeville;
}

action Amboy( Corona, Barrow, Dizney, Blitchton, Montour,
                        Wheeling, Frederick ) {
   modify_field( Renton.Borup, Corona );
   modify_field( Renton.Rainsburg, Corona );
   modify_field( Renton.Bluewater, Frederick );
   Valsetz(Barrow, Dizney, Blitchton, Montour,
                        Wheeling );
}

action PortVue() {
   modify_field( Renton.Deerwood, 1 );
}

table Nooksack {
   reads {
      Greycliff.Newland : exact;
   }

   actions {
      Amboy;
      PortVue;
   }
   size : Biehle;
}

action Valsetz(Glendale, Burgdorf, Frankston, Wharton,
                        Almond ) {
   modify_field( Silva.Parshall, Glendale );
   modify_field( Silva.Harbor, Burgdorf );
   modify_field( Silva.Daysville, Frankston );
   modify_field( Silva.Burwell, Wharton );
   modify_field( Silva.McCartys, Almond );
}

action Bufalo(Larwill, Edmeston, Bloomdale, Salamatof,
                        Roodhouse ) {
   modify_field( Renton.Rainsburg, Harding.Lathrop );
   modify_field( Renton.Bluewater, 1 );
   Valsetz(Larwill, Edmeston, Bloomdale, Salamatof,
                        Roodhouse );
}

action WestPark(Edesville, Edwards, Nenana, Clauene,
                        Bagdad, Braxton ) {
   modify_field( Renton.Rainsburg, Edesville );
   modify_field( Renton.Bluewater, 1 );
   Valsetz(Edwards, Nenana, Clauene, Bagdad,
                        Braxton );
}

action Lakota(GlenRose, Geistown, Henrietta, Penrose,
                        Bouton ) {
   modify_field( Renton.Rainsburg, Casper[0].Mariemont );
   modify_field( Renton.Bluewater, 1 );
   Valsetz(GlenRose, Geistown, Henrietta, Penrose,
                        Bouton );
}

table Dixfield {
   reads {
      Harding.Lathrop : exact;
   }


   actions {
      Whitefish;
      Bufalo;
   }

   size : Lostwood;
}

@pragma action_default_only Whitefish
table Natalbany {
   reads {
      Harding.Gower : exact;
      Casper[0].Mariemont : exact;
   }

   actions {
      WestPark;
      Whitefish;
   }

   size : Mission;
}

table Twain {
   reads {
      Casper[0].Mariemont : exact;
   }


   actions {
      Whitefish;
      Lakota;
   }

   size : Canton;
}

control Battles {
   apply( Grasston ) {
         Faulkton {
            apply( Lilymoor );
            apply( Nooksack );
         }
         Waukesha {
            if ( Harding.McKee == 1 ) {
               apply( Petrolia );
            }
            if ( valid( Casper[ 0 ] ) ) {

               apply( Natalbany ) {
                  Whitefish {

                     apply( Twain );
                  }
               }
            } else {

               apply( Dixfield );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Tarnov {
    width  : 1;
    static : Furman;
    instance_count : 262144;
}

register Hobucken {
    width  : 1;
    static : Langston;
    instance_count : 262144;
}

blackbox stateful_alu Noyack {
    reg : Tarnov;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Nondalton.Telma;
}

blackbox stateful_alu Kasilof {
    reg : Hobucken;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Nondalton.Chandalar;
}

field_list Hulbert {
    Harding.Honokahua;
    Casper[0].Mariemont;
}

field_list_calculation Goodwin {
    input { Hulbert; }
    algorithm: identity;
    output_width: 18;
}

action Riverlea() {
    Noyack.execute_stateful_alu_from_hash(Goodwin);
}

action Cedonia() {
    Kasilof.execute_stateful_alu_from_hash(Goodwin);
}

table Furman {
    actions {
      Riverlea;
    }
    default_action : Riverlea;
    size : 1;
}

table Langston {
    actions {
      Cedonia;
    }
    default_action : Cedonia;
    size : 1;
}
#endif

action Glazier(Moraine) {
    modify_field(Nondalton.Chandalar, Moraine);
}

@pragma  use_hash_action 0
table Woodland {
    reads {
       Harding.Honokahua : exact;
    }
    actions {
      Glazier;
    }
    size : 64;
}

action Grannis() {
   modify_field( Renton.Calcium, Harding.Lathrop );
   modify_field( Renton.Annandale, 0 );
}

table Newpoint {
   actions {
      Grannis;
   }
   size : 1;
}

action Sudbury() {
   modify_field( Renton.Calcium, Casper[0].Mariemont );
   modify_field( Renton.Annandale, 1 );
}

table Darby {
   actions {
      Sudbury;
   }
   size : 1;
}

control Hiawassee {
   if ( valid( Casper[ 0 ] ) ) {
      apply( Darby );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Harding.ElMirage == 1 ) {
         apply( Furman );
         apply( Langston );
      }
#endif
   } else {
      apply( Newpoint );
      if( Harding.ElMirage == 1 ) {
         apply( Woodland );
      }
   }
}




field_list Slinger {
   Leetsdale.Yardley;
   Leetsdale.Wanatah;
   Leetsdale.Grantfork;
   Leetsdale.Walcott;
   Leetsdale.Flippen;
}

field_list Bagwell {

   Bowdon.Burmester;
   Bowdon.Satolah;
   Bowdon.Toluca;
}

field_list Whitewood {
   Strasburg.Nutria;
   Strasburg.Azalia;
   Strasburg.RioHondo;
   Strasburg.Salus;
}

field_list Tiverton {
   Bowdon.Satolah;
   Bowdon.Toluca;
   Dabney.Duffield;
   Dabney.Raeford;
}





field_list_calculation Claypool {
    input {
        Slinger;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Napanoch {
    input {
        Bagwell;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Dustin {
    input {
        Whitewood;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation FourTown {
    input {
        Tiverton;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Swansea() {
    modify_field_with_hash_based_offset(Speed.Bellville, 0,
                                        Claypool, 4294967296);
}

action Casco() {
    modify_field_with_hash_based_offset(Speed.Toxey, 0,
                                        Napanoch, 4294967296);
}

action Boxelder() {
    modify_field_with_hash_based_offset(Speed.Toxey, 0,
                                        Dustin, 4294967296);
}

action NewSite() {
    modify_field_with_hash_based_offset(Speed.Lauada, 0,
                                        FourTown, 4294967296);
}

table Claiborne {
   actions {
      Swansea;
   }
   size: 1;
}

control Gonzales {
   apply(Claiborne);
}

table Mantee {
   actions {
      Casco;
   }
   size: 1;
}

table Cozad {
   actions {
      Boxelder;
   }
   size: 1;
}

control Purves {
   if ( valid( Bowdon ) ) {
      apply(Mantee);
   } else {
      if ( valid( Strasburg ) ) {
         apply(Cozad);
      }
   }
}

table Knolls {
   actions {
      NewSite;
   }
   size: 1;
}

control BoyRiver {
   if ( valid( Dabney ) ) {
      apply(Knolls);
   }
}



action GunnCity() {
    modify_field(Gunder.Brush, Speed.Bellville);
}

action Fowler() {
    modify_field(Gunder.Brush, Speed.Toxey);
}

action Jonesport() {
    modify_field(Gunder.Brush, Speed.Lauada);
}

@pragma action_default_only Whitefish
@pragma immediate 0
table Monkstown {
   reads {
      Wells.valid : ternary;
      Tinaja.valid : ternary;
      UtePark.valid : ternary;
      Wayne.valid : ternary;
      Donna.valid : ternary;
      Syria.valid : ternary;
      Dabney.valid : ternary;
      Bowdon.valid : ternary;
      Strasburg.valid : ternary;
      Leetsdale.valid : ternary;
   }
   actions {
      GunnCity;
      Fowler;
      Jonesport;
      Whitefish;
   }
   size: Roachdale;
}

action Ponder() {
    modify_field(Gunder.Pease, Speed.Lauada);
}

@pragma immediate 0
table Maltby {
   reads {
      Wells.valid : ternary;
      Tinaja.valid : ternary;
      Syria.valid : ternary;
      Dabney.valid : ternary;
   }
   actions {
      Ponder;
      Whitefish;
   }
   size: Vincent;
}

control Samson {
   apply(Maltby);
   apply(Monkstown);
}



counter Marshall {
   type : packets_and_bytes;
   direct : Pinole;
   min_width: 16;
}

table Pinole {
   reads {
      Harding.Honokahua : exact;
      Nondalton.Chandalar : ternary;
      Nondalton.Telma : ternary;
      Renton.Deerwood : ternary;
      Renton.Herald : ternary;
      Renton.Fragaria : ternary;
   }

   actions {
      Hollyhill;
      Whitefish;
   }
   default_action : Whitefish();
   size : Fletcher;
}

action Lovett() {

   modify_field(Renton.Trilby, 1 );
   modify_field(Milesburg.Ferndale,
                LaLuz);
}







table Bladen {
   reads {
      Renton.Cantwell : exact;
      Renton.MudLake : exact;
      Renton.Borup : exact;
      Renton.Rodessa : exact;
   }

   actions {
      Onley;
      Lovett;
   }
   default_action : Lovett();
   size : Waucousta;
   support_timeout : true;
}

action Moody() {
   modify_field( Silva.Exell, 1 );
}

table SnowLake {
   reads {
      Renton.Rainsburg : ternary;
      Renton.Newsome : exact;
      Renton.Wayland : exact;
   }
   actions {
      Moody;
   }
   size: Northway;
}

control Bicknell {
   apply( Pinole ) {
      Whitefish {



         if (Harding.Kenton == 0 and Renton.Stanwood == 0) {
            apply( Bladen );
         }
         apply(SnowLake);
      }
   }
}

field_list Allison {
    Milesburg.Ferndale;
    Renton.Cantwell;
    Renton.MudLake;
    Renton.Borup;
    Renton.Rodessa;
}

action Etter() {
   generate_digest(Belle, Allison);
}


table Panola {
   actions {
      Etter;
   }
   size : 1;
}

control Moapa {
   if (Renton.Trilby == 1) {
      apply( Panola );
   }
}



action TenSleep( Abraham, HighRock ) {
   modify_field( Baldridge.Riverwood, Abraham );
   modify_field( Dellslow.Calamus, HighRock );
}

@pragma action_default_only Flaherty
table BoxElder {
   reads {
      Silva.Parshall : exact;
      Baldridge.PikeView mask Gladys : lpm;
   }
   actions {
      TenSleep;
      Flaherty;
   }
   size : Lewistown;
}

@pragma atcam_partition_index Baldridge.Riverwood
@pragma atcam_number_partitions Lewistown
table Waldport {
   reads {
      Baldridge.Riverwood : exact;
      Baldridge.PikeView mask Norias : lpm;
   }

   actions {
      Ebenezer;
      Kingsdale;
      Whitefish;
   }
   default_action : Whitefish();
   size : Burdette;
}

action Kirkwood( Poland, Luttrell ) {
   modify_field( Baldridge.Villanova, Poland );
   modify_field( Dellslow.Calamus, Luttrell );
}

@pragma action_default_only Whitefish
table Alburnett {


   reads {
      Silva.Parshall : exact;
      Baldridge.PikeView : lpm;
   }

   actions {
      Kirkwood;
      Whitefish;
   }

   size : Tabler;
}

@pragma atcam_partition_index Baldridge.Villanova
@pragma atcam_number_partitions Tabler
table Gambrills {
   reads {
      Baldridge.Villanova : exact;


      Baldridge.PikeView mask Christina : lpm;
   }
   actions {
      Ebenezer;
      Kingsdale;
      Whitefish;
   }

   default_action : Whitefish();
   size : Candor;
}

@pragma action_default_only Flaherty
@pragma idletime_precision 1
table Sodaville {

   reads {
      Silva.Parshall : exact;
      Antimony.RushHill : lpm;
   }

   actions {
      Ebenezer;
      Kingsdale;
      Flaherty;
   }

   size : Waterflow;
   support_timeout : true;
}

action Allgood( LaHabra, Caputa ) {
   modify_field( Antimony.Balmville, LaHabra );
   modify_field( Dellslow.Calamus, Caputa );
}

@pragma action_default_only Whitefish
#ifdef PROFILE_DEFAULT
@pragma stage 2 Cuprum
@pragma stage 3
#endif
table Eureka {
   reads {
      Silva.Parshall : exact;
      Antimony.RushHill : lpm;
   }

   actions {
      Allgood;
      Whitefish;
   }

   size : Johnsburg;
}

@pragma ways Bucklin
@pragma atcam_partition_index Antimony.Balmville
@pragma atcam_number_partitions Johnsburg
table Veradale {
   reads {
      Antimony.Balmville : exact;
      Antimony.RushHill mask Baltic : lpm;
   }
   actions {
      Ebenezer;
      Kingsdale;
      Whitefish;
   }
   default_action : Whitefish();
   size : Billett;
}

action Ebenezer( Picayune ) {
   modify_field( Dellslow.Calamus, Picayune );
}

@pragma idletime_precision 1
table Driftwood {
   reads {
      Silva.Parshall : exact;
      Antimony.RushHill : exact;
   }

   actions {
      Ebenezer;
      Kingsdale;
      Whitefish;
   }
   default_action : Whitefish();
   size : Charenton;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
@pragma stage 2 Chitina
@pragma stage 3
#endif
table Berville {
   reads {
      Silva.Parshall : exact;
      Baldridge.PikeView : exact;
   }

   actions {
      Ebenezer;
      Kingsdale;
      Whitefish;
   }
   default_action : Whitefish();
   size : Maybee;
   support_timeout : true;
}

action Hoagland(Henderson, Hamburg, Bouse) {
   modify_field(Laplace.Shawmut, Bouse);
   modify_field(Laplace.Martelle, Henderson);
   modify_field(Laplace.Metter, Hamburg);
   modify_field(Laplace.Oakmont, 1);

   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}

action Kensett() {
   Hollyhill();
}

action Overton(Coleman) {
   modify_field(Laplace.Bairoa, 1);
   modify_field(Laplace.Nerstrand, Coleman);
}

action Flaherty() {
   modify_field( Laplace.Bairoa, 1 );
   modify_field( Laplace.Nerstrand, 9 );
}


table Dahlgren {
   reads {
      Dellslow.Calamus : exact;
   }

   actions {
      Hoagland;
      Kensett;
      Overton;
   }
   size : Grays;
}

control Pearl {
   if ( Renton.Waitsburg == 0 and Silva.Exell == 1 ) {
      if ( ( Silva.Harbor == 1 ) and ( Renton.Hiwasse == 1 ) ) {
         apply( Driftwood ) {
            Whitefish {
               apply( Eureka ) {
                  Allgood {
                     apply( Veradale );
                  }
                  Whitefish {
                     apply( Sodaville );
                  }
               }
            }
         }
      } else if ( ( Silva.Daysville == 1 ) and ( Renton.Sarepta == 1 ) ) {
         apply( Berville ) {
            Whitefish {
               apply( Alburnett ) {
                  Kirkwood {
                     apply( Gambrills );
                  }
                  Whitefish {

                     apply( BoxElder ) {
                        TenSleep {
                           apply( Waldport );
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Naruna {
   if( Dellslow.Calamus != 0 ) {
      apply( Dahlgren );
   }
}

action Kingsdale( Rainelle ) {
   modify_field( Dellslow.Admire, Rainelle );
}

field_list Russia {
   Gunder.Pease;
}

field_list_calculation Decorah {
    input {
        Russia;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Hospers {
   selection_key : Decorah;
   selection_mode : resilient;
}

action_profile Corvallis {
   actions {
      Ebenezer;
   }
   size : Grants;
   dynamic_action_selection : Hospers;
}

table Trujillo {
   reads {
      Dellslow.Admire : exact;
   }
   action_profile : Corvallis;
   size : Crown;
}

control Jessie {
   if ( Dellslow.Admire != 0 ) {
      apply( Trujillo );
   }
}



field_list Locke {
   Gunder.Brush;
}

field_list_calculation Minto {
    input {
        Locke;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Exeland {
    selection_key : Minto;
    selection_mode : resilient;
}

action Missoula(Vining) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Vining);
}

action_profile Troup {
    actions {
        Missoula;
        Whitefish;
    }
    size : Allegan;
    dynamic_action_selection : Exeland;
}

table Winfall {
   reads {
      Laplace.Ocracoke : exact;
   }
   action_profile: Troup;
   size : Cranbury;
}

control Nichols {
   if ((Laplace.Ocracoke & 0x2000) == 0x2000) {
      apply(Winfall);
   }
}



action Eldena() {
   modify_field(Laplace.Martelle, Renton.Newsome);
   modify_field(Laplace.Metter, Renton.Wayland);
   modify_field(Laplace.Kalvesta, Renton.Cantwell);
   modify_field(Laplace.Komatke, Renton.MudLake);
   modify_field(Laplace.Shawmut, Renton.Borup);

}

table Oxford {
   actions {
      Eldena;
   }
   default_action : Eldena();
   size : 1;
}

control Desdemona {
   if (Renton.Borup!=0) {
      apply( Oxford );
   }
}

action Embarrass() {
   modify_field(Laplace.Ahuimanu, 1);
   modify_field(Laplace.Vichy, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Laplace.Shawmut);
}

action Arthur() {
}



@pragma ways 1
table Hawthorn {
   reads {
      Laplace.Martelle : exact;
      Laplace.Metter : exact;
   }
   actions {
      Embarrass;
      Arthur;
   }
   default_action : Arthur;
   size : 1;
}

action Worland() {
   modify_field(Laplace.Neosho, 1);
   modify_field(Laplace.Buckholts, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Laplace.Shawmut, WestPike);
}

table Duelm {
   actions {
      Worland;
   }
   default_action : Worland;
   size : 1;
}

action Gilman() {
   modify_field(Laplace.Affton, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Laplace.Shawmut);
}

table Montague {
   actions {
      Gilman;
   }
   default_action : Gilman();
   size : 1;
}

action BigPoint(Kanab) {
   modify_field(Laplace.Flomot, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Kanab);
   modify_field(Laplace.Ocracoke, Kanab);
}

action Ladoga(Sylva) {
   modify_field(Laplace.Neosho, 1);
   modify_field(Laplace.Watters, Sylva);
}

action Stamford() {
}

table Adair {
   reads {
      Laplace.Martelle : exact;
      Laplace.Metter : exact;
      Laplace.Shawmut : exact;
   }

   actions {
      BigPoint;
      Ladoga;
      Stamford;
   }
   default_action : Stamford();
   size : Ashtola;
}

control Alzada {
   if (Renton.Waitsburg == 0) {
      apply(Adair) {
         Stamford {
            apply(Hawthorn) {
               Arthur {
                  if ((Laplace.Martelle & 0x010000) == 0x010000) {
                     apply(Duelm);
                  } else if (Laplace.Oakmont == 0) {
                     apply(Montague);
                  } else {
                     apply(Montague);
                  }
               }
            }
         }
      }
   }
}

action Switzer() {

   Hollyhill();
}

table Rendville {
   actions {
      Switzer;
   }
   default_action : Switzer;
   size : 1;
}

control Lumpkin {
   if (Renton.Waitsburg == 0) {
      if ((Laplace.Oakmont==0) and (Renton.Pacifica==0) and (Renton.Lakin==0) and (Renton.Rodessa==Laplace.Ocracoke)) {
         apply(Rendville);
      }
   }
}

action BigBar(Cochise) {
    modify_field(ig_intr_md_for_tm.level2_exclusion_id, Cochise);
}

table Level {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       BigBar;
    }
    size : 512;
}

control GlenRock {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Level);
   }
}



action Monahans( Volcano ) {
   modify_field( Laplace.Robinson, Volcano );
}

action Saugatuck() {
   modify_field( Laplace.Robinson, Laplace.Shawmut );
}

table Lumberton {
   reads {
      eg_intr_md.egress_port : exact;
      Laplace.Shawmut : exact;
   }

   actions {
      Monahans;
      Saugatuck;
   }
   default_action : Saugatuck;
   size : Wenham;
}

control Lowden {
   apply( Lumberton );
}



action Flaxton( Jackpot, Newhalen ) {
   modify_field( Laplace.Larchmont, Jackpot );
   modify_field( Laplace.Ogunquit, Newhalen );
}

action Poteet( Madeira, Cooter, Meyers, Vacherie ) {
   modify_field( Laplace.Larchmont, Madeira );
   modify_field( Laplace.Ogunquit, Cooter );
   modify_field( Laplace.Belwood, Meyers );
   modify_field( Laplace.Whitlash, Vacherie );
}


table Edinburgh {
   reads {
      Laplace.Tenino : exact;
   }

   actions {
      Flaxton;
      Poteet;
   }
   size : Oketo;
}

action Hickox(Rosburg, Hoven, Glenoma, Talkeetna) {
   modify_field( Laplace.Bluff, Rosburg );
   modify_field( Laplace.Arkoe, Hoven );
   modify_field( Laplace.Otsego, Glenoma );
   modify_field( Laplace.Norfork, Talkeetna );
}

table Hitterdal {
   reads {

        Laplace.Riner : exact;
   }
   actions {
      Hickox;
   }
   size : Teigen;
}

action Marie() {
   no_op();
}

action Lordstown() {
   modify_field( Leetsdale.Flippen, Casper[0].Aplin );
   remove_header( Casper[0] );
}

table Trail {
   actions {
      Lordstown;
   }
   default_action : Lordstown;
   size : Malabar;
}

action FortHunt() {
   no_op();
}

action Krupp() {
   add_header( Casper[ 0 ] );
   modify_field( Casper[0].Mariemont, Laplace.Robinson );
   modify_field( Casper[0].Aplin, Leetsdale.Flippen );
   modify_field( Leetsdale.Flippen, Levittown );
}



table Paulding {
   reads {
      Laplace.Robinson : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      FortHunt;
      Krupp;
   }
   default_action : Krupp;
   size : Ferrum;
}

action Holden() {
   modify_field(Leetsdale.Yardley, Laplace.Martelle);
   modify_field(Leetsdale.Wanatah, Laplace.Metter);
   modify_field(Leetsdale.Grantfork, Laplace.Larchmont);
   modify_field(Leetsdale.Walcott, Laplace.Ogunquit);
}

action Odebolt() {
   Holden();
   add_to_field(Bowdon.Pelican, -1);
}

action Wimberley() {
   Holden();
   add_to_field(Strasburg.Othello, -1);
}

action Phelps() {
   Krupp();
}

action Ackley() {
   add_header( Lemhi );
   modify_field( Lemhi.Yardley, Laplace.Larchmont );
   modify_field( Lemhi.Wanatah, Laplace.Ogunquit );
   modify_field( Lemhi.Grantfork, Laplace.Belwood );
   modify_field( Lemhi.Walcott, Laplace.Whitlash );
   modify_field( Lemhi.Flippen, Lyndell );
   add_header( Wallula );
   modify_field( Wallula.Lowemont, Laplace.Bluff );
   modify_field( Wallula.Nettleton, Laplace.Arkoe );
   modify_field( Wallula.Slagle, Laplace.Otsego );
   modify_field( Wallula.Haworth, Laplace.Norfork );
   modify_field( Wallula.Wrens, Laplace.Nerstrand );
}

table Hanapepe {
   reads {
      Laplace.SanSimon : exact;
      Laplace.Tenino : exact;
      Laplace.Oakmont : exact;
      Bowdon.valid : ternary;
      Strasburg.valid : ternary;
   }

   actions {
      Odebolt;
      Wimberley;
      Phelps;
      Ackley;

   }
   size : Lapoint;
}

control Nipton {
   apply( Trail );
}

control Yocemento {
   apply( Paulding );
}

control Ericsburg {
   apply( Edinburgh );
   apply( Hitterdal );
   apply( Hanapepe );
}



field_list Moorewood {
    Milesburg.Ferndale;
    Renton.Borup;
    Donna.Grantfork;
    Donna.Walcott;
    Bowdon.Satolah;
}

action Seaford() {
   generate_digest(Belle, Moorewood);
}


table Medart {
   actions {
      Seaford;
   }

   default_action : Seaford;
   size : 1;
}

control Amasa {
   if (Renton.Stanwood == 1) {
      apply(Medart);
   }
}



action Chatcolet( Anaconda ) {
   modify_field( Nason.Glyndon, Anaconda );
}

action Maddock() {
   modify_field( Nason.Glyndon, 0 );
}

table Yemassee {
   reads {
     Renton.Rodessa : ternary;
     Renton.Rainsburg : ternary;
     Silva.Exell : ternary;
   }

   actions {
     Chatcolet;
     Maddock;
   }

   default_action : Maddock();
   size : Wyanet;
}

action Oconee( Dugger ) {
   modify_field( Nason.Palco, Dugger );
   modify_field( Nason.Penzance, 0 );
   modify_field( Nason.HillTop, 0 );
}

action Dobbins( Addicks, Energy ) {
   modify_field( Nason.Palco, 0 );
   modify_field( Nason.Penzance, Addicks );
   modify_field( Nason.HillTop, Energy );
}

action Thomas( Lakehills, Joiner, PineHill ) {
   modify_field( Nason.Palco, Lakehills );
   modify_field( Nason.Penzance, Joiner );
   modify_field( Nason.HillTop, PineHill );
}

action Mabank() {
   modify_field( Nason.Palco, 0 );
   modify_field( Nason.Penzance, 0 );
   modify_field( Nason.HillTop, 0 );
}

table Westway {
   reads {
     Nason.Glyndon : exact;
     Renton.Newsome : ternary;
     Renton.Wayland : ternary;
     Renton.Blevins : ternary;
   }

   actions {
     Oconee;
     Dobbins;
     Thomas;
     Mabank;
   }

   default_action : Mabank();
   size : Perma;
}

table Victoria {
   reads {
     Nason.Glyndon : exact;
     Antimony.RushHill mask 0xffff0000 : ternary;
     Renton.Cascade : ternary;
     Renton.Ewing : ternary;
     Renton.Clintwood : ternary;
     Dellslow.Calamus : ternary;

   }

   actions {
     Oconee;
     Dobbins;
     Thomas;
     Mabank;
   }

   default_action : Mabank();
   size : Yukon;
}

table Kenbridge {
   reads {
     Nason.Glyndon : exact;
     Baldridge.PikeView mask 0xffff0000 : ternary;
     Renton.Cascade : ternary;
     Renton.Ewing : ternary;
     Renton.Clintwood : ternary;
     Dellslow.Calamus : ternary;

   }

   actions {
     Oconee;
     Dobbins;
     Thomas;
     Mabank;
   }

   default_action : Mabank();
   size : Fontana;
}

meter Camanche {
   type : packets;
   static : Yorklyn;
   instance_count: Kenvil;
}

action Alamosa( Hettinger ) {
   // Unsupported address mode
   //execute_meter( Camanche, Hettinger, ig_intr_md_for_tm.packet_color );
}

action Cadott() {
   execute_meter( Camanche, Nason.Penzance, ig_intr_md_for_tm.packet_color );
}

table Yorklyn {
   reads {
     Nason.Penzance : ternary;
     Renton.Rodessa : ternary;
     Renton.Rainsburg : ternary;
     Silva.Exell : ternary;
     Nason.HillTop : ternary;
   }
   actions {
      Alamosa;
      Cadott;
   }
   size : Leflore;
}

control Olivet {
   apply( Yemassee );
}

control Ceiba {
   if ( Renton.Hiwasse == 1 ) {
      apply( Victoria );
   } else if ( Renton.Sarepta == 1 ) {
      apply( Kenbridge );
   } else {
      apply( Westway );
   }
}

control Gause {
   apply( Yorklyn );
}



action PineAire() {
   modify_field( Renton.Hartwick, Harding.Palmerton );
}

action Hallwood() {
   modify_field( Renton.Hartwick, Casper[0].Ranchito );

}

action Careywood() {
   modify_field( Renton.Clintwood, Harding.Lepanto );
}

action Parmalee() {
   modify_field( Renton.Clintwood, Antimony.Mapleview );
}

action Farragut() {
   modify_field( Renton.Clintwood, Baldridge.Millston );
}

action Coalgate( Dorothy, Floral ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Dorothy );
   modify_field( ig_intr_md_for_tm.qid, Floral );
}


table Engle {
   reads {
     Renton.Loretto : exact;
   }

   actions {
     PineAire;
//     Hallwood;
   }


   size : Wallace;
}

table Broadford {
   reads {
     Renton.Hiwasse : exact;
     Renton.Sarepta : exact;
   }

   actions {
     Careywood;
     Parmalee;
     Farragut;
   }

   size : Fentress;
}

table Cornish {
   reads {
      Harding.Orrstown : ternary;
      Harding.Palmerton : ternary;
      Renton.Hartwick : ternary;
      Renton.Clintwood : ternary;
      Nason.Palco : ternary;
   }

   actions {
      Coalgate;
   }

   size : Reynolds;
}

control Wheatland {
   apply( Engle );
   apply( Broadford );
}

control Kinsley {
   apply( Cornish );
}




#define Rardin            0
#define Livengood  1
#define Suamico 2


#define Vieques           0




action Folcroft( Bieber ) {
   modify_field( Laplace.Tenino, Livengood );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Bieber );
}

action Shoreview( Tillicum ) {
   modify_field( Laplace.Tenino, Suamico );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Tillicum );
   modify_field( Laplace.Riner, ig_intr_md.ingress_port );
}

action Wyncote() {




}

@pragma action_default_only Wyncote
table Stennett {
   reads {
      Silva.Exell : exact;
      Harding.McKee : ternary;
      Laplace.Nerstrand : ternary;
   }

   actions {
      Folcroft;
      Shoreview;
   }

   default_action: Wyncote;
   size : Folger;
}

control Almelund {
   apply( Stennett );
}

action Greenlawn() {
   modify_field( Laplace.Riner, ig_intr_md.ingress_port );
}

table Fallis {
   actions {
      Greenlawn;
   }
   size : 1;
}

control Trammel {
   apply(Fallis);
}
control ingress {

   Neavitt();


   Cement();
   Battles();
   Hiawassee();


   Bicknell();
   Gonzales();


   Purves();
   BoyRiver();


   Pearl();


   Samson();


   Jessie();
   Desdemona();


   Naruna();
   Wheatland();
   Olivet();




   Amasa();
   Moapa();
   if( Laplace.Bairoa == 0 ) {
      Alzada();
   }


   Ceiba();

   if( Laplace.Bairoa == 0 ) {
      Lumpkin();
      Nichols();
   }
   Trammel();


   if( valid( Casper[0] ) ) {
      Nipton();
   }


   Kinsley();
   if( ig_intr_md_for_tm.drop_ctl == 0 ) {
      Gause();
   }
   if( Laplace.Bairoa == 0 ) {
      GlenRock();
   }
   if( Laplace.Bairoa == 1 ) {
      Almelund();
   }
}

control egress {
   Lowden();
   Ericsburg();

   if( Laplace.Bairoa == 0 ) {
      Yocemento();
   }
}

