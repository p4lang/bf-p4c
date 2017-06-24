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



#ifndef Hector
#define Hector

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
		Millston : 8;
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



#ifndef Weathers
#define Weathers


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



#ifndef Tunica
#define Tunica

#define Higgston        0x8100
#define Nevis        0x0800
#define Perrin        0x86dd
#define Servia        0x9100
#define WhiteOwl        0x8847
#define Lyndell         0x0806
#define Abilene        0x8035
#define Lindsborg        0x88cc
#define Auburn        0x8809
#define Myton      0xBF00

#define Lambrook              1
#define Gerty              2
#define Lyncourt              4
#define Leicester               6
#define Bluford               17
#define Green                47

#define Selvin         0x501
#define Goulds          0x506
#define Yreka          0x511
#define Mendham          0x52F


#define Woolwine                 4789



#define Conda               0
#define WestPike              1
#define Boutte                2



#define Belle          0
#define LaLuz          4095
#define Bethania  4096
#define Gobles  8191



#define Maybell                      0
#define Palmer                  0
#define Wheeler                 1

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
      Myton : Forepaugh;
      default : Moorman;
   }
}

parser Kniman {
   extract( Wallula );
   return Moorman;
}

parser Forepaugh {
   extract( Lemhi );
   return Kniman;
}

parser Moorman {
   extract( Leetsdale );
   return select( Leetsdale.Flippen ) {
      Higgston : Swisshome;
      Nevis : Advance;
      Perrin : Youngwood;
      Lyndell  : Gustine;
      default        : ingress;
   }
}

parser Swisshome {
   extract( Casper[0] );

   set_metadata(Spiro.Kiwalik, 1);


    set_metadata(Renton.Hartwick, Casper[0].Ranchito);

   return select( Casper[0].Aplin ) {
      Nevis : Advance;
      Perrin : Youngwood;
      Lyndell  : Gustine;
      default : ingress;
   }
}

parser Advance {
   extract( Bowdon );
   set_metadata(Spiro.Thistle, Bowdon.Burmester);
   set_metadata(Spiro.Tappan, Bowdon.Pelican);
   set_metadata(Spiro.Ohiowa, Bowdon.Markesan);






   set_metadata(Renton.Hiwasse, 1);

   return select(Bowdon.Craig, Bowdon.Carlson, Bowdon.Burmester) {
      Yreka : Armagh;
      default : ingress;
   }
}

parser Youngwood {
   extract( Strasburg );

   set_metadata(Spiro.Thistle, Strasburg.Salus);
   set_metadata(Spiro.Tappan, Strasburg.Othello);
   set_metadata(Spiro.Ohiowa, Strasburg.Quinhagak);






   set_metadata(Renton.Sarepta, 1);

   return ingress;
}

parser Gustine {
   extract( Layton );
   return ingress;
}

parser Armagh {
   extract(Dabney);
   return select(Dabney.Raeford) {
      Woolwine : Campton;
      default : ingress;
    }
}

parser Curlew {
   set_metadata(Renton.Belfair, Boutte);
   return Monteview;
}

parser Darien {
   set_metadata(Renton.Belfair, Boutte);
   return Ashtola;
}

parser Waucousta {
   extract(Sunflower);
   return select(Sunflower.Algonquin, Sunflower.CleElum, Sunflower.Ossipee, Sunflower.Orting, Sunflower.Lehigh,
             Sunflower.LaJoya, Sunflower.PaloAlto, Sunflower.Kremlin, Sunflower.Munger) {
      Nevis : Curlew;
      Perrin : Darien;
      default : ingress;
   }
}

parser Campton {
   extract(Greycliff);
   set_metadata(Renton.Belfair, WestPike);
   return Fackler;
}

parser Monteview {
   extract( UtePark );
   set_metadata(Spiro.Neches, UtePark.Burmester);
   set_metadata(Spiro.Lamona, UtePark.Pelican);
   set_metadata(Spiro.Belcher, UtePark.Markesan);
   set_metadata(Spiro.Calhan, 0);
   set_metadata(Spiro.Eddington, 1);
   return ingress;
}

parser Ashtola {
   extract( Wayne );
   set_metadata(Spiro.Neches, Wayne.Salus);
   set_metadata(Spiro.Lamona, Wayne.Othello);
   set_metadata(Spiro.Belcher, Wayne.Quinhagak);
   set_metadata(Spiro.Calhan, 1);
   set_metadata(Spiro.Eddington, 0);
   return ingress;
}

parser Fackler {
   extract( Donna );
   return select( Donna.Flippen ) {
      Nevis: Monteview;
      Perrin: Ashtola;
      default: ingress;
   }
}
#endif


metadata Whigham Renton;
metadata Peoria Laplace;
metadata Bellwood Harding;
metadata Yscloskey Spiro;
metadata Placida Antimony;
metadata Tolono Baldridge;
@pragma pa_container_size ingress Nondalton.Chandalar 32
metadata Honobia Nondalton;
metadata McDonough Silva;
metadata Zarah Milesburg;
metadata Lenapah Dellslow;
metadata Sugarloaf Gunder;
metadata Cusseta Speed;
metadata Cisco Nason;













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

#undef Stonefort
#undef Whitefish

#undef Hollyhill

#undef Onley







#define NewCity 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Fletcher      65536
#define Cranbury      65536
#define Allegan 512
#define Roachdale 512
#define Northway      512


#define Charenton     1024
#define Maybee    1024
#define Chitina     256


#define Johnsburg 512
#define Cuprum 65536
#define Billett 65536
#define Grays 28672
#define Waterflow   16384
#define Tabler 8192
#define Candor         131072
#define Lewistown 65536
#define Burdette 1024
#define Christina 2048
#define Baltic 16384
#define Gladys 8192
#define Norias 65536

#define Bucklin 0x0000000000000000FFFFFFFFFFFFFFFF


#define Vincent 0x000fffff
#define DeSart 2

#define Grants 0xFFFFFFFFFFFFFFFF0000000000000000

#define Crown 0x000007FFFFFFFFFF0000000000000000
#define Biehle  6
#define Coconut        2048
#define Leeville       65536


#define Lostwood 1024
#define Mission 4096
#define Canton 4096
#define Judson 4096
#define Ferrum 4096
#define Malabar 1024
#define Oketo 4096
#define Wallace 128
#define Fentress 1
#define Reynolds  8


#define Wyanet 512
#define Stonefort 512
#define Whitefish 256


#define Perma 1
#define Yukon 3
#define Fontana 80



#define Kenvil 512
#define Leflore 512
#define Folger 512
#define Teigen 512

#define Akiachak 2048
#define Wenham 1024



#define Hollyhill 0


#define Onley    4096

#endif



#ifndef Pridgen
#define Pridgen

action Wetumpka() {
   no_op();
}

action Neavitt() {
   modify_field(Renton.Waitsburg, 1 );
   mark_for_drop();
}

action Achille() {
   no_op();
}
#endif

















action Maupin(Handley, Belfalls, Panaca, Langlois, Macon, Clearco,
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
table Finlayson {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Maupin;
    }
    size : NewCity;
}

control Bernard {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Finlayson);
    }
}





action Alnwick(Halsey) {
   modify_field( Laplace.Bairoa, 1 );
   modify_field( Laplace.Nerstrand, Halsey);
   modify_field( Renton.Pacifica, 1 );
}

action Orrville() {
   modify_field( Renton.Fragaria, 1 );
   modify_field( Renton.Guion, 1 );
}

action Kealia() {
   modify_field( Renton.Pacifica, 1 );
}

action Owanka() {
   modify_field( Renton.Lakin, 1 );
}

action Eugene() {
   modify_field( Renton.Guion, 1 );
}

counter Cement {
   type : packets_and_bytes;
   direct : Faulkton;
   min_width: 16;
}

table Faulkton {
   reads {
      Harding.Honokahua : exact;
      Leetsdale.Yardley : ternary;
      Leetsdale.Wanatah : ternary;
   }

   actions {
      Alnwick;
      Orrville;
      Kealia;
      Owanka;
      Eugene;
   }
   size : Allegan;
}

action Waukesha() {
   modify_field( Renton.Herald, 1 );
}


table Grasston {
   reads {
      Leetsdale.Grantfork : ternary;
      Leetsdale.Walcott : ternary;
   }

   actions {
      Waukesha;
   }
   size : Roachdale;
}


control Baskett {
   apply( Faulkton );
   apply( Grasston );
}




action Waretown() {
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
   modify_field( Harding.Orrstown, 2 );
   modify_field( Harding.Palmerton, 0 );
   modify_field( Harding.Lepanto, 0 );
}

action Woodfords() {
   modify_field( Renton.Belfair, Conda );
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



   modify_field( Renton.Loretto, Spiro.Kiwalik );
}

table Petrolia {
   reads {
      Leetsdale.Yardley : exact;
      Leetsdale.Wanatah : exact;
      Bowdon.Toluca : exact;
      Renton.Belfair : exact;
   }

   actions {
      Waretown;
      Woodfords;
   }

   default_action : Woodfords();
   size : Lostwood;
}


action Wabuska() {
   modify_field( Renton.Borup, Harding.Lathrop );
   modify_field( Renton.Rodessa, Harding.Gower);
}

action Harviell( Yardville ) {
   modify_field( Renton.Borup, Yardville );
   modify_field( Renton.Rodessa, Harding.Gower);
}

action Lilymoor() {
   modify_field( Renton.Borup, Casper[0].Mariemont );
   modify_field( Renton.Rodessa, Harding.Gower);
}

table Amboy {
   reads {
      Harding.Gower : ternary;
      Casper[0] : valid;
      Casper[0].Mariemont : ternary;
   }

   actions {
      Wabuska;
      Harviell;
      Lilymoor;
   }
   size : Judson;
}

action Valsetz( Hilburn ) {
   modify_field( Renton.Rodessa, Hilburn );
}

action PortVue() {

   modify_field( Renton.Stanwood, 1 );
   modify_field( Milesburg.Ferndale,
                 Wheeler );
}

table Nooksack {
   reads {
      Bowdon.Satolah : exact;
   }

   actions {
      Valsetz;
      PortVue;
   }
   default_action : PortVue;
   size : Canton;
}

action Bufalo( Corona, Barrow, Dizney, Blitchton, Montour,
                        Wheeling, Frederick ) {
   modify_field( Renton.Borup, Corona );
   modify_field( Renton.Rainsburg, Corona );
   modify_field( Renton.Bluewater, Frederick );
   WestPark(Barrow, Dizney, Blitchton, Montour,
                        Wheeling );
}

action Lakota() {
   modify_field( Renton.Deerwood, 1 );
}

table Dixfield {
   reads {
      Greycliff.Newland : exact;
   }

   actions {
      Bufalo;
      Lakota;
   }
   size : Mission;
}

action WestPark(Glendale, Burgdorf, Frankston, Wharton,
                        Almond ) {
   modify_field( Silva.Parshall, Glendale );
   modify_field( Silva.Harbor, Burgdorf );
   modify_field( Silva.Daysville, Frankston );
   modify_field( Silva.Burwell, Wharton );
   modify_field( Silva.McCartys, Almond );
}

action Natalbany(Larwill, Edmeston, Bloomdale, Salamatof,
                        Roodhouse ) {
   modify_field( Renton.Rainsburg, Harding.Lathrop );
   modify_field( Renton.Bluewater, 1 );
   WestPark(Larwill, Edmeston, Bloomdale, Salamatof,
                        Roodhouse );
}

action Twain(Edesville, Edwards, Nenana, Clauene,
                        Bagdad, Braxton ) {
   modify_field( Renton.Rainsburg, Edesville );
   modify_field( Renton.Bluewater, 1 );
   WestPark(Edwards, Nenana, Clauene, Bagdad,
                        Braxton );
}

action Battles(GlenRose, Geistown, Henrietta, Penrose,
                        Bouton ) {
   modify_field( Renton.Rainsburg, Casper[0].Mariemont );
   modify_field( Renton.Bluewater, 1 );
   WestPark(GlenRose, Geistown, Henrietta, Penrose,
                        Bouton );
}

table Tarnov {
   reads {
      Harding.Lathrop : exact;
   }


   actions {
      Wetumpka;
      Natalbany;
   }

   size : Ferrum;
}

@pragma action_default_only Wetumpka
table Furman {
   reads {
      Harding.Gower : exact;
      Casper[0].Mariemont : exact;
   }

   actions {
      Twain;
      Wetumpka;
   }

   size : Malabar;
}

table Hobucken {
   reads {
      Casper[0].Mariemont : exact;
   }


   actions {
      Wetumpka;
      Battles;
   }

   size : Oketo;
}

control Langston {
   apply( Petrolia ) {
         Waretown {
            apply( Nooksack );
            apply( Dixfield );
         }
         Woodfords {
            if ( Harding.McKee == 1 ) {
               apply( Amboy );
            }
            if ( valid( Casper[ 0 ] ) ) {

               apply( Furman ) {
                  Wetumpka {

                     apply( Hobucken );
                  }
               }
            } else {

               apply( Tarnov );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Noyack {
    width  : 1;
    static : Kasilof;
    instance_count : 262144;
}

register Hulbert {
    width  : 1;
    static : Goodwin;
    instance_count : 262144;
}

blackbox stateful_alu Riverlea {
    reg : Noyack;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Nondalton.Telma;
}

blackbox stateful_alu Cedonia {
    reg : Hulbert;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Nondalton.Chandalar;
}

field_list Glazier {
    Harding.Honokahua;
    Casper[0].Mariemont;
}

field_list_calculation Woodland {
    input { Glazier; }
    algorithm: identity;
    output_width: 18;
}

action Grannis() {
    Riverlea.execute_stateful_alu_from_hash(Woodland);
}

action Newpoint() {
    Cedonia.execute_stateful_alu_from_hash(Woodland);
}

table Kasilof {
    actions {
      Grannis;
    }
    default_action : Grannis;
    size : 1;
}

table Goodwin {
    actions {
      Newpoint;
    }
    default_action : Newpoint;
    size : 1;
}
#endif

action Sudbury(Moraine) {
    modify_field(Nondalton.Chandalar, Moraine);
}

@pragma  use_hash_action 0
table Darby {
    reads {
       Harding.Honokahua : exact;
    }
    actions {
      Sudbury;
    }
    size : 64;
}

action Hiawassee() {
   modify_field( Renton.Calcium, Harding.Lathrop );
   modify_field( Renton.Annandale, 0 );
}

table Slinger {
   actions {
      Hiawassee;
   }
   size : 1;
}

action Bagwell() {
   modify_field( Renton.Calcium, Casper[0].Mariemont );
   modify_field( Renton.Annandale, 1 );
}

table Whitewood {
   actions {
      Bagwell;
   }
   size : 1;
}

control Tiverton {
   if ( valid( Casper[ 0 ] ) ) {
      apply( Whitewood );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Harding.ElMirage == 1 ) {
         apply( Kasilof );
         apply( Goodwin );
      }
#endif
   } else {
      apply( Slinger );
      if( Harding.ElMirage == 1 ) {
         apply( Darby );
      }
   }
}




field_list Claypool {
   Leetsdale.Yardley;
   Leetsdale.Wanatah;
   Leetsdale.Grantfork;
   Leetsdale.Walcott;
   Leetsdale.Flippen;





}

field_list Napanoch {

   Bowdon.Burmester;
   Bowdon.Satolah;
   Bowdon.Toluca;
}

field_list Dustin {
   Strasburg.Nutria;
   Strasburg.Azalia;
   Strasburg.RioHondo;
   Strasburg.Salus;
}

field_list FourTown {
   Bowdon.Satolah;
   Bowdon.Toluca;
   Dabney.Duffield;
   Dabney.Raeford;
}





field_list_calculation Swansea {
    input {
        Claypool;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Casco {
    input {
        Napanoch;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Boxelder {
    input {
        Dustin;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation NewSite {
    input {
        FourTown;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Claiborne() {
    modify_field_with_hash_based_offset(Speed.Bellville, 0,
                                        Swansea, 4294967296);
}

action Gonzales() {
    modify_field_with_hash_based_offset(Speed.Toxey, 0,
                                        Casco, 4294967296);
}

action Mantee() {
    modify_field_with_hash_based_offset(Speed.Toxey, 0,
                                        Boxelder, 4294967296);
}

action Cozad() {
    modify_field_with_hash_based_offset(Speed.Lauada, 0,
                                        NewSite, 4294967296);
}

table Purves {
   actions {
      Claiborne;
   }
   size: 1;
}

control Knolls {
   apply(Purves);
}

table BoyRiver {
   actions {
      Gonzales;
   }
   size: 1;
}

table GunnCity {
   actions {
      Mantee;
   }
   size: 1;
}

control Fowler {
   if ( valid( Bowdon ) ) {
      apply(BoyRiver);
   } else {
      if ( valid( Strasburg ) ) {
         apply(GunnCity);
      }
   }
}

table Jonesport {
   actions {
      Cozad;
   }
   size: 1;
}

control Monkstown {
   if ( valid( Dabney ) ) {
      apply(Jonesport);
   }
}



action Ponder() {
    modify_field(Gunder.Brush, Speed.Bellville);
}

action Maltby() {
    modify_field(Gunder.Brush, Speed.Toxey);
}

action Samson() {
    modify_field(Gunder.Brush, Speed.Lauada);
}

@pragma action_default_only Wetumpka
@pragma immediate 0
table Marshall {
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
      Ponder;
      Maltby;
      Samson;
      Wetumpka;
   }
   size: Chitina;
}

action Pinole() {
    modify_field(Gunder.Pease, Speed.Lauada);
}

@pragma immediate 0
table Lovett {
   reads {
      Wells.valid : ternary;
      Tinaja.valid : ternary;
      Syria.valid : ternary;
      Dabney.valid : ternary;
   }
   actions {
      Pinole;
      Wetumpka;
   }
   size: Biehle;
}

control Bladen {
   apply(Lovett);
   apply(Marshall);
}



counter Moody {
   type : packets_and_bytes;
   direct : SnowLake;
   min_width: 16;
}

table SnowLake {
   reads {
      Harding.Honokahua : exact;
      Nondalton.Chandalar : ternary;
      Nondalton.Telma : ternary;
      Renton.Deerwood : ternary;
      Renton.Herald : ternary;
      Renton.Fragaria : ternary;
   }

   actions {
      Neavitt;
      Wetumpka;
   }
   default_action : Wetumpka();
   size : Northway;
}

action Bicknell() {

   modify_field(Renton.Trilby, 1 );
   modify_field(Milesburg.Ferndale,
                Palmer);
}







table Allison {
   reads {
      Renton.Cantwell : exact;
      Renton.MudLake : exact;
      Renton.Borup : exact;
      Renton.Rodessa : exact;
   }

   actions {
      Achille;
      Bicknell;
   }
   default_action : Bicknell();
   size : Cranbury;
   support_timeout : true;
}

action Etter() {
   modify_field( Silva.Exell, 1 );
}

table Panola {
   reads {
      Renton.Rainsburg : ternary;
      Renton.Newsome : exact;
      Renton.Wayland : exact;
   }
   actions {
      Etter;
   }
   size: Johnsburg;
}

control Moapa {
   apply( SnowLake ) {
      Wetumpka {



         if (Harding.Kenton == 0 and Renton.Stanwood == 0) {
            apply( Allison );
         }
         apply(Panola);
      }
   }
}

field_list TenSleep {
    Milesburg.Ferndale;
    Renton.Cantwell;
    Renton.MudLake;
    Renton.Borup;
    Renton.Rodessa;
}

action Flaherty() {
   generate_digest(Maybell, TenSleep);
}


table BoxElder {
   actions {
      Flaherty;
   }
   size : 1;
}

control Waldport {
   if (Renton.Trilby == 1) {
      apply( BoxElder );
   }
}



action Ebenezer( Abraham, HighRock ) {
   modify_field( Baldridge.Riverwood, Abraham );
   modify_field( Dellslow.Calamus, HighRock );
}

@pragma action_default_only Kingsdale
table Kirkwood {
   reads {
      Silva.Parshall : exact;
      Baldridge.PikeView mask Grants : lpm;
   }
   actions {
      Ebenezer;
      Kingsdale;
   }
   size : Gladys;
}

@pragma atcam_partition_index Baldridge.Riverwood
@pragma atcam_number_partitions Gladys
table Alburnett {
   reads {
      Baldridge.Riverwood : exact;
      Baldridge.PikeView mask Crown : lpm;
   }

   actions {
      Gambrills;
      Sodaville;
      Wetumpka;
   }
   default_action : Wetumpka();
   size : Norias;
}

action Allgood( Poland, Luttrell ) {
   modify_field( Baldridge.Villanova, Poland );
   modify_field( Dellslow.Calamus, Luttrell );
}

@pragma action_default_only Wetumpka
table Eureka {


   reads {
      Silva.Parshall : exact;
      Baldridge.PikeView : lpm;
   }

   actions {
      Allgood;
      Wetumpka;
   }

   size : Christina;
}

@pragma atcam_partition_index Baldridge.Villanova
@pragma atcam_number_partitions Christina
table Veradale {
   reads {
      Baldridge.Villanova : exact;


      Baldridge.PikeView mask Bucklin : lpm;
   }
   actions {
      Gambrills;
      Sodaville;
      Wetumpka;
   }

   default_action : Wetumpka();
   size : Baltic;
}

@pragma action_default_only Kingsdale
@pragma idletime_precision 1
table Driftwood {

   reads {
      Silva.Parshall : exact;
      Antimony.RushHill : lpm;
   }

   actions {
      Gambrills;
      Sodaville;
      Kingsdale;
   }

   size : Burdette;
   support_timeout : true;
}

action Berville( LaHabra, Caputa ) {
   modify_field( Antimony.Balmville, LaHabra );
   modify_field( Dellslow.Calamus, Caputa );
}

@pragma action_default_only Wetumpka
#ifdef PROFILE_DEFAULT
@pragma stage 2 Tabler
@pragma stage 3
#endif
table Hoagland {
   reads {
      Silva.Parshall : exact;
      Antimony.RushHill : lpm;
   }

   actions {
      Berville;
      Wetumpka;
   }

   size : Waterflow;
}

@pragma ways DeSart
@pragma atcam_partition_index Antimony.Balmville
@pragma atcam_number_partitions Waterflow
table Kensett {
   reads {
      Antimony.Balmville : exact;
      Antimony.RushHill mask Vincent : lpm;
   }
   actions {
      Gambrills;
      Sodaville;
      Wetumpka;
   }
   default_action : Wetumpka();
   size : Candor;
}

action Gambrills( Picayune ) {
   modify_field( Dellslow.Calamus, Picayune );
}

@pragma idletime_precision 1
table Overton {
   reads {
      Silva.Parshall : exact;
      Antimony.RushHill : exact;
   }

   actions {
      Gambrills;
      Sodaville;
      Wetumpka;
   }
   default_action : Wetumpka();
   size : Cuprum;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
@pragma stage 2 Grays
@pragma stage 3
#endif
table Dahlgren {
   reads {
      Silva.Parshall : exact;
      Baldridge.PikeView : exact;
   }

   actions {
      Gambrills;
      Sodaville;
      Wetumpka;
   }
   default_action : Wetumpka();
   size : Billett;
   support_timeout : true;
}

action Pearl(Henderson, Hamburg, Bouse) {
   modify_field(Laplace.Shawmut, Bouse);
   modify_field(Laplace.Martelle, Henderson);
   modify_field(Laplace.Metter, Hamburg);
   modify_field(Laplace.Oakmont, 1);

   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}

action Naruna() {
   Neavitt();
}

action Russia(Coleman) {
   modify_field(Laplace.Bairoa, 1);
   modify_field(Laplace.Nerstrand, Coleman);
}

action Kingsdale() {
   modify_field( Laplace.Bairoa, 1 );
   modify_field( Laplace.Nerstrand, 9 );
}


table Decorah {
   reads {
      Dellslow.Calamus : exact;
   }

   actions {
      Pearl;
      Naruna;
      Russia;
   }
   size : Lewistown;
}

control Hospers {
   if ( Renton.Waitsburg == 0 and Silva.Exell == 1 ) {
      if ( ( Silva.Harbor == 1 ) and ( Renton.Hiwasse == 1 ) ) {
         apply( Overton ) {
            Wetumpka {
               apply( Hoagland ) {
                  Berville {
                     apply( Kensett );
                  }
                  Wetumpka {
                     apply( Driftwood );
                  }
               }
            }
         }
      } else if ( ( Silva.Daysville == 1 ) and ( Renton.Sarepta == 1 ) ) {
         apply( Dahlgren ) {
            Wetumpka {
               apply( Eureka ) {
                  Allgood {
                     apply( Veradale );
                  }
                  Wetumpka {

                     apply( Kirkwood ) {
                        Ebenezer {
                           apply( Alburnett );
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Corvallis {
   if( Dellslow.Calamus != 0 ) {
      apply( Decorah );
   }
}

action Sodaville( Rainelle ) {
   modify_field( Dellslow.Admire, Rainelle );
}

field_list Trujillo {
   Gunder.Pease;
}

field_list_calculation Jessie {
    input {
        Trujillo;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Locke {
   selection_key : Jessie;
   selection_mode : resilient;
}

action_profile Minto {
   actions {
      Gambrills;
   }
   size : Leeville;
   dynamic_action_selection : Locke;
}

table Exeland {
   reads {
      Dellslow.Admire : exact;
   }
   action_profile : Minto;
   size : Coconut;
}

control Missoula {
   if ( Dellslow.Admire != 0 ) {
      apply( Exeland );
   }
}



field_list Troup {
   Gunder.Brush;
}

field_list_calculation Winfall {
    input {
        Troup;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Nichols {
    selection_key : Winfall;
    selection_mode : resilient;
}

action Eldena(Vining) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Vining);
}

action_profile Oxford {
    actions {
        Eldena;
        Wetumpka;
    }
    size : Maybee;
    dynamic_action_selection : Nichols;
}

table Desdemona {
   reads {
      Laplace.Ocracoke : exact;
   }
   action_profile: Oxford;
   size : Charenton;
}

control Embarrass {
   if ((Laplace.Ocracoke & 0x2000) == 0x2000) {
      apply(Desdemona);
   }
}



action Arthur() {
   modify_field(Laplace.Martelle, Renton.Newsome);
   modify_field(Laplace.Metter, Renton.Wayland);
   modify_field(Laplace.Kalvesta, Renton.Cantwell);
   modify_field(Laplace.Komatke, Renton.MudLake);
   modify_field(Laplace.Shawmut, Renton.Borup);

}

table Hawthorn {
   actions {
      Arthur;
   }
   default_action : Arthur();
   size : 1;
}

control Worland {
   if (Renton.Borup!=0) {
      apply( Hawthorn );
   }
}

action Duelm() {
   modify_field(Laplace.Ahuimanu, 1);
   modify_field(Laplace.Vichy, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Laplace.Shawmut);
}

action Gilman() {
}



@pragma ways 1
table Montague {
   reads {
      Laplace.Martelle : exact;
      Laplace.Metter : exact;
   }
   actions {
      Duelm;
      Gilman;
   }
   default_action : Gilman;
   size : 1;
}

action BigPoint() {
   modify_field(Laplace.Neosho, 1);
   modify_field(Laplace.Buckholts, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Laplace.Shawmut, Bethania);
}

table Ladoga {
   actions {
      BigPoint;
   }
   default_action : BigPoint;
   size : 1;
}

action Stamford() {
   modify_field(Laplace.Affton, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Laplace.Shawmut);
}

table Adair {
   actions {
      Stamford;
   }
   default_action : Stamford();
   size : 1;
}

action Alzada(Kanab) {
   modify_field(Laplace.Flomot, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Kanab);
   modify_field(Laplace.Ocracoke, Kanab);
}

action Switzer(Sylva) {
   modify_field(Laplace.Neosho, 1);
   modify_field(Laplace.Watters, Sylva);
}

action Rendville() {
}

table Lumpkin {
   reads {
      Laplace.Martelle : exact;
      Laplace.Metter : exact;
      Laplace.Shawmut : exact;
   }

   actions {
      Alzada;
      Switzer;
      Rendville;
   }
   default_action : Rendville();
   size : Fletcher;
}

control BigBar {
   if (Renton.Waitsburg == 0) {
      apply(Lumpkin) {
         Rendville {
            apply(Montague) {
               Gilman {
                  if ((Laplace.Martelle & 0x010000) == 0x010000) {
                     apply(Ladoga);
                  } else if (Laplace.Oakmont == 0) {
                     apply(Adair);
                  } else {
                     apply(Adair);
                  }
               }
            }
         }
      }
   }
}

action Level() {

   Neavitt();
}

table GlenRock {
   actions {
      Level;
   }
   default_action : Level;
   size : 1;
}

control Monahans {
   if (Renton.Waitsburg == 0) {
      if ((Laplace.Oakmont==0) and (Renton.Pacifica==0) and (Renton.Lakin==0) and (Renton.Rodessa==Laplace.Ocracoke)) {
         apply(GlenRock);
      }
   }
}

action Saugatuck(Cochise) {
    modify_field(ig_intr_md_for_tm.level2_exclusion_id, Cochise);
}

table Lumberton {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Saugatuck;
    }
    size : 512;
}

control Lowden {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Lumberton);
   }
}



action Flaxton( Volcano ) {
   modify_field( Laplace.Robinson, Volcano );
}

action Poteet() {
   modify_field( Laplace.Robinson, Laplace.Shawmut );
}

table Edinburgh {
   reads {
      eg_intr_md.egress_port : exact;
      Laplace.Shawmut : exact;
   }

   actions {
      Flaxton;
      Poteet;
   }
   default_action : Poteet;
   size : Onley;
}

control Hickox {
   apply( Edinburgh );
}



action Hitterdal( Jackpot, Newhalen ) {
   modify_field( Laplace.Larchmont, Jackpot );
   modify_field( Laplace.Ogunquit, Newhalen );
}

action Marie( Madeira, Cooter, Meyers, Vacherie ) {
   modify_field( Laplace.Larchmont, Madeira );
   modify_field( Laplace.Ogunquit, Cooter );
   modify_field( Laplace.Belwood, Meyers );
   modify_field( Laplace.Whitlash, Vacherie );
}


table Lordstown {
   reads {
      Laplace.Tenino : exact;
   }

   actions {
      Hitterdal;
      Marie;
   }
   size : Reynolds;
}

action Trail(Rosburg, Hoven, Glenoma, Talkeetna) {
   modify_field( Laplace.Bluff, Rosburg );
   modify_field( Laplace.Arkoe, Hoven );
   modify_field( Laplace.Otsego, Glenoma );
   modify_field( Laplace.Norfork, Talkeetna );
}

table FortHunt {
   reads {

        Laplace.Riner : exact;
   }
   actions {
      Trail;
   }
   size : Whitefish;
}

action Krupp() {
   no_op();
}

action Paulding() {
   modify_field( Leetsdale.Flippen, Casper[0].Aplin );
   remove_header( Casper[0] );
}

table Holden {
   actions {
      Paulding;
   }
   default_action : Paulding;
   size : Fentress;
}

action Odebolt() {
   no_op();
}

action Wimberley() {
   add_header( Casper[ 0 ] );
   modify_field( Casper[0].Mariemont, Laplace.Robinson );
   modify_field( Casper[0].Aplin, Leetsdale.Flippen );
   modify_field( Leetsdale.Flippen, Higgston );
}



table Phelps {
   reads {
      Laplace.Robinson : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Odebolt;
      Wimberley;
   }
   default_action : Wimberley;
   size : Wallace;
}

action Ackley() {
   modify_field(Leetsdale.Yardley, Laplace.Martelle);
   modify_field(Leetsdale.Wanatah, Laplace.Metter);
   modify_field(Leetsdale.Grantfork, Laplace.Larchmont);
   modify_field(Leetsdale.Walcott, Laplace.Ogunquit);
}

action Hanapepe() {
   Ackley();
   add_to_field(Bowdon.Pelican, -1);
}

action Nipton() {
   Ackley();
   add_to_field(Strasburg.Othello, -1);
}

action Yocemento() {
   Wimberley();
}

action Ericsburg() {
   add_header( Lemhi );
   modify_field( Lemhi.Yardley, Laplace.Larchmont );
   modify_field( Lemhi.Wanatah, Laplace.Ogunquit );
   modify_field( Lemhi.Grantfork, Laplace.Belwood );
   modify_field( Lemhi.Walcott, Laplace.Whitlash );
   modify_field( Lemhi.Flippen, Myton );
   add_header( Wallula );
   modify_field( Wallula.Lowemont, Laplace.Bluff );
   modify_field( Wallula.Nettleton, Laplace.Arkoe );
   modify_field( Wallula.Slagle, Laplace.Otsego );
   modify_field( Wallula.Haworth, Laplace.Norfork );
   modify_field( Wallula.Wrens, Laplace.Nerstrand );
}

table Moorewood {
   reads {
      Laplace.SanSimon : exact;
      Laplace.Tenino : exact;
      Laplace.Oakmont : exact;
      Bowdon.valid : ternary;
      Strasburg.valid : ternary;
   }

   actions {
      Hanapepe;
      Nipton;
      Yocemento;
      Ericsburg;

   }
   size : Wyanet;
}

control Seaford {
   apply( Holden );
}

control Medart {
   apply( Phelps );
}

control Amasa {
   apply( Lordstown );
   apply( FortHunt );
   apply( Moorewood );
}



field_list Chatcolet {
    Milesburg.Ferndale;
    Renton.Borup;
    Donna.Grantfork;
    Donna.Walcott;
    Bowdon.Satolah;
}

action Maddock() {
   generate_digest(Maybell, Chatcolet);
}


table Yemassee {
   actions {
      Maddock;
   }

   default_action : Maddock;
   size : 1;
}

control Oconee {
   if (Renton.Stanwood == 1) {
      apply(Yemassee);
   }
}



action Dobbins( Anaconda ) {
   modify_field( Nason.Glyndon, Anaconda );
}

action Thomas() {
   modify_field( Nason.Glyndon, 0 );
}

table Mabank {
   reads {
     Renton.Rodessa : ternary;
     Renton.Rainsburg : ternary;
     Silva.Exell : ternary;
   }

   actions {
     Dobbins;
     Thomas;
   }

   default_action : Thomas();
   size : Kenvil;
}

action Westway( Dugger ) {
   modify_field( Nason.Palco, Dugger );
   modify_field( Nason.Penzance, 0 );
   modify_field( Nason.HillTop, 0 );
}

action Victoria( Addicks, Energy ) {
   modify_field( Nason.Palco, 0 );
   modify_field( Nason.Penzance, Addicks );
   modify_field( Nason.HillTop, Energy );
}

action Kenbridge( Lakehills, Joiner, PineHill ) {
   modify_field( Nason.Palco, Lakehills );
   modify_field( Nason.Penzance, Joiner );
   modify_field( Nason.HillTop, PineHill );
}

action Camanche() {
   modify_field( Nason.Palco, 0 );
   modify_field( Nason.Penzance, 0 );
   modify_field( Nason.HillTop, 0 );
}

table Yorklyn {
   reads {
     Nason.Glyndon : exact;
     Renton.Newsome : ternary;
     Renton.Wayland : ternary;
     Renton.Blevins : ternary;
   }

   actions {
     Westway;
     Victoria;
     Kenbridge;
     Camanche;
   }

   default_action : Camanche();
   size : Leflore;
}

table Alamosa {
   reads {
     Nason.Glyndon : exact;
     Antimony.RushHill mask 0xffff0000 : ternary;
     Renton.Cascade : ternary;
     Renton.Ewing : ternary;
     Renton.Clintwood : ternary;
     Dellslow.Calamus : ternary;

   }

   actions {
     Westway;
     Victoria;
     Kenbridge;
     Camanche;
   }

   default_action : Camanche();
   size : Folger;
}

table Cadott {
   reads {
     Nason.Glyndon : exact;
     Baldridge.PikeView mask 0xffff0000 : ternary;
     Renton.Cascade : ternary;
     Renton.Ewing : ternary;
     Renton.Clintwood : ternary;
     Dellslow.Calamus : ternary;

   }

   actions {
     Westway;
     Victoria;
     Kenbridge;
     Camanche;
   }

   default_action : Camanche();
   size : Teigen;
}

meter Olivet {
   type : packets;
   static : Ceiba;
   instance_count: Akiachak;
}

action Gause( Hettinger ) {
   // Unsupported address mode
   //execute_meter( Olivet, Hettinger, ig_intr_md_for_tm.packet_color );
}

action PineAire() {
   execute_meter( Olivet, Nason.Penzance, ig_intr_md_for_tm.packet_color );
}

table Ceiba {
   reads {
     Nason.Penzance : ternary;
     Renton.Rodessa : ternary;
     Renton.Rainsburg : ternary;
     Silva.Exell : ternary;
     Nason.HillTop : ternary;
   }
   actions {
      Gause;
      PineAire;
   }
   size : Wenham;
}

control Hallwood {
   apply( Mabank );
}

control Careywood {
   if ( Renton.Hiwasse == 1 ) {
      apply( Alamosa );
   } else if ( Renton.Sarepta == 1 ) {
      apply( Cadott );
   } else {
      apply( Yorklyn );
   }
}

control Parmalee {
   apply( Ceiba );
}



action Farragut() {
   modify_field( Renton.Hartwick, Harding.Palmerton );
}

action Coalgate() {
   modify_field( Renton.Hartwick, Casper[0].Ranchito );
}

action Engle() {
   modify_field( Renton.Clintwood, Harding.Lepanto );
}

action Broadford() {
   modify_field( Renton.Clintwood, Antimony.Mapleview );
}

action Cornish() {
   modify_field( Renton.Clintwood, Baldridge.Millston );
}

action Wheatland( Dorothy, Floral ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Dorothy );
   modify_field( ig_intr_md_for_tm.qid, Floral );
}


table Kinsley {
   reads {
     Renton.Loretto : exact;
   }

   actions {
     Farragut;
     Coalgate;
   }


   size : Perma;
}

table Rardin {
   reads {
     Renton.Hiwasse : exact;
     Renton.Sarepta : exact;
   }

   actions {
     Engle;
     Broadford;
     Cornish;
   }

   size : Yukon;
}

table Livengood {
   reads {
      Harding.Orrstown : ternary;
      Harding.Palmerton : ternary;


      Renton.Hartwick : ternary;
      Renton.Clintwood : ternary;
      Nason.Palco : ternary;
   }

   actions {
      Wheatland;
   }

   size : Fontana;
}

control Suamico {
   apply( Kinsley );
   apply( Rardin );
}

control Vieques {
   apply( Livengood );
}




#define Folcroft            0
#define Shoreview  1
#define Wyncote 2


#define Stennett           0




action Almelund( Bieber ) {
   modify_field( Laplace.Tenino, Shoreview );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Bieber );
}

//#define Greenlawn
#ifdef Greenlawn
action Fallis( Levittown, Grampian ) {
   modify_field( Laplace.Tenino, Wyncote );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Levittown );
   modify_field( Laplace.Riner, Grampian );
}
#else
action Fallis( Levittown ) {
   modify_field( Laplace.Tenino, Wyncote );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Levittown );
   modify_field( Laplace.Riner, ig_intr_md.ingress_port );
}
#endif

action Trammel() {





}

@pragma action_default_only Trammel

table Hammonton {
   reads {
      Silva.Exell : exact;
      Harding.McKee : ternary;
      Laplace.Nerstrand : ternary;
   }

   actions {
      Almelund;
      Fallis;
   }

   default_action: Trammel;
   size : Stonefort;
}

control Nanuet {
   apply( Hammonton );
}

action Anvik() {
   modify_field( Laplace.Riner, ig_intr_md.ingress_port );
}

table Kenefic {
   actions {
      Anvik;
   }
   size : 1;
}


control ingress {

   Bernard();


   Baskett();
   Langston();
   Tiverton();


   Moapa();
   Knolls();


   Fowler();
   Monkstown();


   Hospers();


   Bladen();


   Missoula();
   Worland();


   Corvallis();
   Suamico();
   Hallwood();




   Oconee();
   Waldport();
   if( Laplace.Bairoa == 0 ) {
      BigBar();
   }


   Careywood();

   if( Laplace.Bairoa == 0 ) {
      Monahans();
      Embarrass();
   }



   if( valid( Casper[0] ) ) {
      Seaford();
   }





   Vieques();
   if( Renton.Waitsburg == 0 ) {
      Parmalee();
   }
   if( Laplace.Bairoa == 0 ) {
      Lowden();
   }
   if( Laplace.Bairoa == 1 ) {
      Nanuet();
   }
}

control egress {
   Hickox();
   Amasa();

   if( Laplace.Bairoa == 0 ) {
      Medart();
   }
}

