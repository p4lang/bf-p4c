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



#ifndef Shickley
#define Shickley

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



#ifndef Levittown
#define Levittown


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



#ifndef Hector
#define Hector

#define Weathers        0x8100
#define Tunica        0x0800
#define Higgston        0x86dd
#define Nevis        0x9100
#define Perrin        0x8847
#define Servia         0x0806
#define WhiteOwl        0x8035
#define Lyndell        0x88cc
#define Abilene        0x8809
#define Lindsborg      0xBF00

#define Auburn              1
#define Myton              2
#define Lambrook              4
#define Gerty               6
#define Lyncourt               17
#define Leicester                47

#define Bluford         0x501
#define Green          0x506
#define Selvin          0x511
#define Goulds          0x52F


#define Yreka                 4789



#define Mendham               0
#define Woolwine              1
#define Conda                2



#define WestPike          0
#define Boutte          4095
#define Belle  4096
#define LaLuz  8191



#define Bethania                      0
#define Gobles                  0
#define Maybell                 1

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
      Lindsborg : Palmer;
      default : Wheeler;
   }
}

parser Forepaugh {
   extract( Wallula );
   return Wheeler;
}

parser Palmer {
   extract( Lemhi );
   return Forepaugh;
}

parser Wheeler {
   extract( Leetsdale );
   return select( Leetsdale.Flippen ) {
      Weathers : Moorman;
      Tunica : Kniman;
      Higgston : Swisshome;
      Servia  : Advance;
      default        : ingress;
   }
}

parser Moorman {
   extract( Casper[0] );

   set_metadata(Spiro.Kiwalik, 1);


    set_metadata(Renton.Hartwick, Casper[0].Ranchito);

   return select( Casper[0].Aplin ) {
      Tunica : Kniman;
      Higgston : Swisshome;
      Servia  : Advance;
      default : ingress;
   }
}

parser Kniman {
   extract( Bowdon );
   set_metadata(Spiro.Thistle, Bowdon.Burmester);
   set_metadata(Spiro.Tappan, Bowdon.Pelican);
   set_metadata(Spiro.Ohiowa, Bowdon.Markesan);






   set_metadata(Renton.Hiwasse, 1);

   return select(Bowdon.Craig, Bowdon.Carlson, Bowdon.Burmester) {
      Selvin : Youngwood;
      default : ingress;
   }
}

parser Swisshome {
   extract( Strasburg );

   set_metadata(Spiro.Thistle, Strasburg.Salus);
   set_metadata(Spiro.Tappan, Strasburg.Othello);
   set_metadata(Spiro.Ohiowa, Strasburg.Quinhagak);






   set_metadata(Renton.Sarepta, 1);

   return ingress;
}

parser Advance {
   extract( Layton );
   return ingress;
}

parser Youngwood {
   extract(Dabney);
   return select(Dabney.Raeford) {
      Yreka : Gustine;
      default : ingress;
    }
}

parser Armagh {
   set_metadata(Renton.Belfair, Conda);
   return Campton;
}

parser Curlew {
   set_metadata(Renton.Belfair, Conda);
   return Monteview;
}

parser Darien {
   extract(Sunflower);
   return select(Sunflower.Algonquin, Sunflower.CleElum, Sunflower.Ossipee, Sunflower.Orting, Sunflower.Lehigh,
             Sunflower.LaJoya, Sunflower.PaloAlto, Sunflower.Kremlin, Sunflower.Munger) {
      Tunica : Armagh;
      Higgston : Curlew;
      default : ingress;
   }
}

parser Gustine {
   extract(Greycliff);
   set_metadata(Renton.Belfair, Woolwine);
   return Ashtola;
}

parser Campton {
   extract( UtePark );
   set_metadata(Spiro.Neches, UtePark.Burmester);
   set_metadata(Spiro.Lamona, UtePark.Pelican);
   set_metadata(Spiro.Belcher, UtePark.Markesan);
   set_metadata(Spiro.Calhan, 0);
   set_metadata(Spiro.Eddington, 1);
   return ingress;
}

parser Monteview {
   extract( Wayne );
   set_metadata(Spiro.Neches, Wayne.Salus);
   set_metadata(Spiro.Lamona, Wayne.Othello);
   set_metadata(Spiro.Belcher, Wayne.Quinhagak);
   set_metadata(Spiro.Calhan, 1);
   set_metadata(Spiro.Eddington, 0);
   return ingress;
}

parser Ashtola {
   extract( Donna );
   return select( Donna.Flippen ) {
      Tunica: Campton;
      Higgston: Monteview;
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

#undef Stonefort

#undef Whitefish







#define Waucousta 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Fackler      65536
#define NewCity      65536
#define Fletcher 512
#define Cranbury 512
#define Allegan      512


#define Roachdale     1024
#define Northway    1024
#define Charenton     256


#define Maybee 512
#define Chitina 65536
#define Johnsburg 65536
#define Cuprum 28672
#define Billett   16384
#define Grays 8192
#define Waterflow         131072
#define Tabler 65536
#define Candor 1024
#define Lewistown 2048
#define Burdette 16384
#define Christina 8192
#define Baltic 65536

#define Gladys 0x0000000000000000FFFFFFFFFFFFFFFF


#define Norias 0x000fffff
#define Grants 2

#define Bucklin 0xFFFFFFFFFFFFFFFF0000000000000000

#define Vincent 0x000007FFFFFFFFFF0000000000000000
#define Crown  6
#define Biehle        2048
#define DeSart       65536


#define Leeville 1024
#define Coconut 4096
#define Lostwood 4096
#define Mission 4096
#define Canton 4096
#define Judson 1024
#define Ferrum 4096
#define Oketo 128
#define Lapoint 1
#define Wallace  8


#define Fentress 512
#define Akiachak 512
#define Wenham 256


#define Reynolds 1
#define Wyanet 3
#define Perma 80



#define Yukon 512
#define Fontana 512
#define Kenvil 512
#define Leflore 512

#define Folger 2048
#define Teigen 1024



#define Stonefort 0


#define Whitefish    4096

#endif



#ifndef Hollyhill
#define Hollyhill

action Onley() {
   no_op();
}

action Pridgen() {
   modify_field(Renton.Waitsburg, 1 );
   mark_for_drop();
}

action Wetumpka() {
   no_op();
}
#endif

















action Neavitt(Handley, Belfalls, Panaca, Langlois, Macon, Clearco,
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
table Achille {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Neavitt;
    }
    size : Waucousta;
}

control Maupin {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Achille);
    }
}





action Finlayson(Halsey) {
   modify_field( Laplace.Bairoa, 1 );
   modify_field( Laplace.Nerstrand, Halsey);
   modify_field( Renton.Pacifica, 1 );
}

action Bernard() {
   modify_field( Renton.Fragaria, 1 );
   modify_field( Renton.Guion, 1 );
}

action Alnwick() {
   modify_field( Renton.Pacifica, 1 );
}

action Orrville() {
   modify_field( Renton.Lakin, 1 );
}

action Kealia() {
   modify_field( Renton.Guion, 1 );
}

counter Owanka {
   type : packets_and_bytes;
   direct : Eugene;
   min_width: 16;
}

table Eugene {
   reads {
      Harding.Honokahua : exact;
      Leetsdale.Yardley : ternary;
      Leetsdale.Wanatah : ternary;
   }

   actions {
      Finlayson;
      Bernard;
      Alnwick;
      Orrville;
      Kealia;
   }
   size : Fletcher;
}

action Cement() {
   modify_field( Renton.Herald, 1 );
}


table Faulkton {
   reads {
      Leetsdale.Grantfork : ternary;
      Leetsdale.Walcott : ternary;
   }

   actions {
      Cement;
   }
   size : Cranbury;
}


control Waukesha {
   apply( Eugene );
   apply( Faulkton );
}




action Grasston() {
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

action Baskett() {
   modify_field( Renton.Belfair, Mendham );
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

table Waretown {
   reads {
      Leetsdale.Yardley : exact;
      Leetsdale.Wanatah : exact;
      Bowdon.Toluca : exact;
      Renton.Belfair : exact;
   }

   actions {
      Grasston;
      Baskett;
   }

   default_action : Baskett();
   size : Leeville;
}


action Woodfords() {
   modify_field( Renton.Borup, Harding.Lathrop );
   modify_field( Renton.Rodessa, Harding.Gower);
}

action Petrolia( Yardville ) {
   modify_field( Renton.Borup, Yardville );
   modify_field( Renton.Rodessa, Harding.Gower);
}

action Wabuska() {
   modify_field( Renton.Borup, Casper[0].Mariemont );
   modify_field( Renton.Rodessa, Harding.Gower);
}

table Harviell {
   reads {
      Harding.Gower : ternary;
      Casper[0] : valid;
      Casper[0].Mariemont : ternary;
   }

   actions {
      Woodfords;
      Petrolia;
      Wabuska;
   }
   size : Mission;
}

action Lilymoor( Hilburn ) {
   modify_field( Renton.Rodessa, Hilburn );
}

action Amboy() {

   modify_field( Renton.Stanwood, 1 );
   modify_field( Milesburg.Ferndale,
                 Maybell );
}

table Valsetz {
   reads {
      Bowdon.Satolah : exact;
   }

   actions {
      Lilymoor;
      Amboy;
   }
   default_action : Amboy;
   size : Lostwood;
}

action PortVue( Corona, Barrow, Dizney, Blitchton, Montour,
                        Wheeling, Frederick ) {
   modify_field( Renton.Borup, Corona );
   modify_field( Renton.Rainsburg, Corona );
   modify_field( Renton.Bluewater, Frederick );
   Nooksack(Barrow, Dizney, Blitchton, Montour,
                        Wheeling );
}

action Bufalo() {
   modify_field( Renton.Deerwood, 1 );
}

table WestPark {
   reads {
      Greycliff.Newland : exact;
   }

   actions {
      PortVue;
      Bufalo;
   }
   size : Coconut;
}

action Nooksack(Glendale, Burgdorf, Frankston, Wharton,
                        Almond ) {
   modify_field( Silva.Parshall, Glendale );
   modify_field( Silva.Harbor, Burgdorf );
   modify_field( Silva.Daysville, Frankston );
   modify_field( Silva.Burwell, Wharton );
   modify_field( Silva.McCartys, Almond );
}

action Lakota(Larwill, Edmeston, Bloomdale, Salamatof,
                        Roodhouse ) {
   modify_field( Renton.Rainsburg, Harding.Lathrop );
   modify_field( Renton.Bluewater, 1 );
   Nooksack(Larwill, Edmeston, Bloomdale, Salamatof,
                        Roodhouse );
}

action Dixfield(Edesville, Edwards, Nenana, Clauene,
                        Bagdad, Braxton ) {
   modify_field( Renton.Rainsburg, Edesville );
   modify_field( Renton.Bluewater, 1 );
   Nooksack(Edwards, Nenana, Clauene, Bagdad,
                        Braxton );
}

action Natalbany(GlenRose, Geistown, Henrietta, Penrose,
                        Bouton ) {
   modify_field( Renton.Rainsburg, Casper[0].Mariemont );
   modify_field( Renton.Bluewater, 1 );
   Nooksack(GlenRose, Geistown, Henrietta, Penrose,
                        Bouton );
}

table Twain {
   reads {
      Harding.Lathrop : exact;
   }


   actions {
      Onley;
      Lakota;
   }

   size : Canton;
}

@pragma action_default_only Onley
table Battles {
   reads {
      Harding.Gower : exact;
      Casper[0].Mariemont : exact;
   }

   actions {
      Dixfield;
      Onley;
   }

   size : Judson;
}

table Tarnov {
   reads {
      Casper[0].Mariemont : exact;
   }


   actions {
      Onley;
      Natalbany;
   }

   size : Ferrum;
}

control Furman {
   apply( Waretown ) {
         Grasston {
            apply( Valsetz );
            apply( WestPark );
         }
         Baskett {
            if ( Harding.McKee == 1 ) {
               apply( Harviell );
            }
            if ( valid( Casper[ 0 ] ) ) {

               apply( Battles ) {
                  Onley {

                     apply( Tarnov );
                  }
               }
            } else {

               apply( Twain );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Hobucken {
    width  : 1;
    static : Langston;
    instance_count : 262144;
}

register Noyack {
    width  : 1;
    static : Kasilof;
    instance_count : 262144;
}

blackbox stateful_alu Hulbert {
    reg : Hobucken;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Nondalton.Telma;
}

blackbox stateful_alu Goodwin {
    reg : Noyack;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Nondalton.Chandalar;
}

field_list Riverlea {
    Harding.Honokahua;
    Casper[0].Mariemont;
}

field_list_calculation Cedonia {
    input { Riverlea; }
    algorithm: identity;
    output_width: 18;
}

action Glazier() {
    Hulbert.execute_stateful_alu_from_hash(Cedonia);
}

action Woodland() {
    Goodwin.execute_stateful_alu_from_hash(Cedonia);
}

table Langston {
    actions {
      Glazier;
    }
    default_action : Glazier;
    size : 1;
}

table Kasilof {
    actions {
      Woodland;
    }
    default_action : Woodland;
    size : 1;
}
#endif

action Grannis(Moraine) {
    modify_field(Nondalton.Chandalar, Moraine);
}

@pragma  use_hash_action 0
table Newpoint {
    reads {
       Harding.Honokahua : exact;
    }
    actions {
      Grannis;
    }
    size : 64;
}

action Sudbury() {
   modify_field( Renton.Calcium, Harding.Lathrop );
   modify_field( Renton.Annandale, 0 );
}

table Darby {
   actions {
      Sudbury;
   }
   size : 1;
}

action Hiawassee() {
   modify_field( Renton.Calcium, Casper[0].Mariemont );
   modify_field( Renton.Annandale, 1 );
}

table Slinger {
   actions {
      Hiawassee;
   }
   size : 1;
}

control Bagwell {
   if ( valid( Casper[ 0 ] ) ) {
      apply( Slinger );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Harding.ElMirage == 1 ) {
         apply( Langston );
         apply( Kasilof );
      }
#endif
   } else {
      apply( Darby );
      if( Harding.ElMirage == 1 ) {
         apply( Newpoint );
      }
   }
}




field_list Whitewood {
   Leetsdale.Yardley;
   Leetsdale.Wanatah;
   Leetsdale.Grantfork;
   Leetsdale.Walcott;
   Leetsdale.Flippen;





}

field_list Tiverton {

   Bowdon.Burmester;
   Bowdon.Satolah;
   Bowdon.Toluca;
}

field_list Claypool {
   Strasburg.Nutria;
   Strasburg.Azalia;
   Strasburg.RioHondo;
   Strasburg.Salus;
}

field_list Napanoch {
   Bowdon.Satolah;
   Bowdon.Toluca;
   Dabney.Duffield;
   Dabney.Raeford;
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



action Boxelder() {
    modify_field_with_hash_based_offset(Speed.Bellville, 0,
                                        Dustin, 4294967296);
}

action NewSite() {
    modify_field_with_hash_based_offset(Speed.Toxey, 0,
                                        FourTown, 4294967296);
}

action Claiborne() {
    modify_field_with_hash_based_offset(Speed.Toxey, 0,
                                        Swansea, 4294967296);
}

action Gonzales() {
    modify_field_with_hash_based_offset(Speed.Lauada, 0,
                                        Casco, 4294967296);
}

table Mantee {
   actions {
      Boxelder;
   }
   size: 1;
}

control Cozad {
   apply(Mantee);
}

table Purves {
   actions {
      NewSite;
   }
   size: 1;
}

table Knolls {
   actions {
      Claiborne;
   }
   size: 1;
}

control BoyRiver {
   if ( valid( Bowdon ) ) {
      apply(Purves);
   } else {
      if ( valid( Strasburg ) ) {
         apply(Knolls);
      }
   }
}

table GunnCity {
   actions {
      Gonzales;
   }
   size: 1;
}

control Fowler {
   if ( valid( Dabney ) ) {
      apply(GunnCity);
   }
}



action Jonesport() {
    modify_field(Gunder.Brush, Speed.Bellville);
}

action Monkstown() {
    modify_field(Gunder.Brush, Speed.Toxey);
}

action Ponder() {
    modify_field(Gunder.Brush, Speed.Lauada);
}

@pragma action_default_only Onley
@pragma immediate 0
table Maltby {
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
      Jonesport;
      Monkstown;
      Ponder;
      Onley;
   }
   size: Charenton;
}

action Samson() {
    modify_field(Gunder.Pease, Speed.Lauada);
}

@pragma immediate 0
table Marshall {
   reads {
      Wells.valid : ternary;
      Tinaja.valid : ternary;
      Syria.valid : ternary;
      Dabney.valid : ternary;
   }
   actions {
      Samson;
      Onley;
   }
   size: Crown;
}

control Pinole {
   apply(Marshall);
   apply(Maltby);
}



counter Lovett {
   type : packets_and_bytes;
   direct : Bladen;
   min_width: 16;
}

table Bladen {
   reads {
      Harding.Honokahua : exact;
      Nondalton.Chandalar : ternary;
      Nondalton.Telma : ternary;
      Renton.Deerwood : ternary;
      Renton.Herald : ternary;
      Renton.Fragaria : ternary;
   }

   actions {
      Pridgen;
      Onley;
   }
   default_action : Onley();
   size : Allegan;
}

action Moody() {

   modify_field(Renton.Trilby, 1 );
   modify_field(Milesburg.Ferndale,
                Gobles);
}







table SnowLake {
   reads {
      Renton.Cantwell : exact;
      Renton.MudLake : exact;
      Renton.Borup : exact;
      Renton.Rodessa : exact;
   }

   actions {
      Wetumpka;
      Moody;
   }
   default_action : Moody();
   size : NewCity;
   support_timeout : true;
}

action Bicknell() {
   modify_field( Silva.Exell, 1 );
}

table Allison {
   reads {
      Renton.Rainsburg : ternary;
      Renton.Newsome : exact;
      Renton.Wayland : exact;
   }
   actions {
      Bicknell;
   }
   size: Maybee;
}

control Etter {
   apply( Bladen ) {
      Onley {



         if (Harding.Kenton == 0 and Renton.Stanwood == 0) {
            apply( SnowLake );
         }
         apply(Allison);
      }
   }
}

field_list Panola {
    Milesburg.Ferndale;
    Renton.Cantwell;
    Renton.MudLake;
    Renton.Borup;
    Renton.Rodessa;
}

action Moapa() {
   generate_digest(Bethania, Panola);
}


table TenSleep {
   actions {
      Moapa;
   }
   size : 1;
}

control Flaherty {
   if (Renton.Trilby == 1) {
      apply( TenSleep );
   }
}



action BoxElder( Abraham, HighRock ) {
   modify_field( Baldridge.Riverwood, Abraham );
   modify_field( Dellslow.Calamus, HighRock );
}

@pragma action_default_only Waldport
table Ebenezer {
   reads {
      Silva.Parshall : exact;
      Baldridge.PikeView mask Bucklin : lpm;
   }
   actions {
      BoxElder;
      Waldport;
   }
   size : Christina;
}

@pragma atcam_partition_index Baldridge.Riverwood
@pragma atcam_number_partitions Christina
table Kingsdale {
   reads {
      Baldridge.Riverwood : exact;
      Baldridge.PikeView mask Vincent : lpm;
   }

   actions {
      Kirkwood;
      Alburnett;
      Onley;
   }
   default_action : Onley();
   size : Baltic;
}

action Gambrills( Poland, Luttrell ) {
   modify_field( Baldridge.Villanova, Poland );
   modify_field( Dellslow.Calamus, Luttrell );
}

@pragma action_default_only Onley
table Sodaville {


   reads {
      Silva.Parshall : exact;
      Baldridge.PikeView : lpm;
   }

   actions {
      Gambrills;
      Onley;
   }

   size : Lewistown;
}

@pragma atcam_partition_index Baldridge.Villanova
@pragma atcam_number_partitions Lewistown
table Allgood {
   reads {
      Baldridge.Villanova : exact;


      Baldridge.PikeView mask Gladys : lpm;
   }
   actions {
      Kirkwood;
      Alburnett;
      Onley;
   }

   default_action : Onley();
   size : Burdette;
}

@pragma action_default_only Waldport
@pragma idletime_precision 1
table Eureka {

   reads {
      Silva.Parshall : exact;
      Antimony.RushHill : lpm;
   }

   actions {
      Kirkwood;
      Alburnett;
      Waldport;
   }

   size : Candor;
   support_timeout : true;
}

action Veradale( LaHabra, Caputa ) {
   modify_field( Antimony.Balmville, LaHabra );
   modify_field( Dellslow.Calamus, Caputa );
}

@pragma action_default_only Onley
#ifdef PROFILE_DEFAULT
//@pragma stage 2 Grays
//@pragma stage 3
#endif
table Driftwood {
   reads {
      Silva.Parshall : exact;
      Antimony.RushHill : lpm;
   }

   actions {
      Veradale;
      Onley;
   }

   size : Billett;
}

@pragma ways Grants
@pragma atcam_partition_index Antimony.Balmville
@pragma atcam_number_partitions Billett
table Berville {
   reads {
      Antimony.Balmville : exact;
      Antimony.RushHill mask Norias : lpm;
   }
   actions {
      Kirkwood;
      Alburnett;
      Onley;
   }
   default_action : Onley();
   size : Waterflow;
}

action Kirkwood( Picayune ) {
   modify_field( Dellslow.Calamus, Picayune );
}

@pragma idletime_precision 1
table Hoagland {
   reads {
      Silva.Parshall : exact;
      Antimony.RushHill : exact;
   }

   actions {
      Kirkwood;
      Alburnett;
      Onley;
   }
   default_action : Onley();
   size : Chitina;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
//@pragma stage 2 Cuprum
//@pragma stage 3
#endif
table Kensett {
   reads {
      Silva.Parshall : exact;
      Baldridge.PikeView : exact;
   }

   actions {
      Kirkwood;
      Alburnett;
      Onley;
   }
   default_action : Onley();
   size : Johnsburg;
   support_timeout : true;
}

action Overton(Henderson, Hamburg, Bouse) {
   modify_field(Laplace.Shawmut, Bouse);
   modify_field(Laplace.Martelle, Henderson);
   modify_field(Laplace.Metter, Hamburg);
   modify_field(Laplace.Oakmont, 1);

   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}

action Dahlgren() {
   Pridgen();
}

action Pearl(Coleman) {
   modify_field(Laplace.Bairoa, 1);
   modify_field(Laplace.Nerstrand, Coleman);
}

action Waldport() {
   modify_field( Laplace.Bairoa, 1 );
   modify_field( Laplace.Nerstrand, 9 );
}


table Naruna {
   reads {
      Dellslow.Calamus : exact;
   }

   actions {
      Overton;
      Dahlgren;
      Pearl;
   }
   size : Tabler;
}

control Russia {
   if ( Renton.Waitsburg == 0 and Silva.Exell == 1 ) {
      if ( ( Silva.Harbor == 1 ) and ( Renton.Hiwasse == 1 ) ) {
         apply( Hoagland ) {
            Onley {
               apply( Driftwood ) {
                  Veradale {
                     apply( Berville );
                  }
                  Onley {
                     apply( Eureka );
                  }
               }
            }
         }
      } else if ( ( Silva.Daysville == 1 ) and ( Renton.Sarepta == 1 ) ) {
         apply( Kensett ) {
            Onley {
               apply( Sodaville ) {
                  Gambrills {
                     apply( Allgood );
                  }
                  Onley {

                     apply( Ebenezer ) {
                        BoxElder {
                           apply( Kingsdale );
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Decorah {
   if( Dellslow.Calamus != 0 ) {
      apply( Naruna );
   }
}

action Alburnett( Rainelle ) {
   modify_field( Dellslow.Admire, Rainelle );
}

field_list Hospers {
   Gunder.Pease;
}

field_list_calculation Corvallis {
    input {
        Hospers;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Trujillo {
   selection_key : Corvallis;
   selection_mode : resilient;
}

action_profile Jessie {
   actions {
      Kirkwood;
   }
   size : DeSart;
   dynamic_action_selection : Trujillo;
}

table Locke {
   reads {
      Dellslow.Admire : exact;
   }
   action_profile : Jessie;
   size : Biehle;
}

control Minto {
   if ( Dellslow.Admire != 0 ) {
      apply( Locke );
   }
}



field_list Exeland {
   Gunder.Brush;
}

field_list_calculation Missoula {
    input {
        Exeland;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Troup {
    selection_key : Missoula;
    selection_mode : resilient;
}

action Winfall(Vining) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Vining);
}

action_profile Nichols {
    actions {
        Winfall;
        Onley;
    }
    size : Northway;
    dynamic_action_selection : Troup;
}

table Eldena {
   reads {
      Laplace.Ocracoke : exact;
   }
   action_profile: Nichols;
   size : Roachdale;
}

control Oxford {
   if ((Laplace.Ocracoke & 0x2000) == 0x2000) {
      apply(Eldena);
   }
}



action Desdemona() {
   modify_field(Laplace.Martelle, Renton.Newsome);
   modify_field(Laplace.Metter, Renton.Wayland);
   modify_field(Laplace.Kalvesta, Renton.Cantwell);
   modify_field(Laplace.Komatke, Renton.MudLake);
   modify_field(Laplace.Shawmut, Renton.Borup);

}

table Embarrass {
   actions {
      Desdemona;
   }
   default_action : Desdemona();
   size : 1;
}

control Arthur {
   if (Renton.Borup!=0) {
      apply( Embarrass );
   }
}

action Hawthorn() {
   modify_field(Laplace.Ahuimanu, 1);
   modify_field(Laplace.Vichy, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Laplace.Shawmut);
}

action Worland() {
}



@pragma ways 1
table Duelm {
   reads {
      Laplace.Martelle : exact;
      Laplace.Metter : exact;
   }
   actions {
      Hawthorn;
      Worland;
   }
   default_action : Worland;
   size : 1;
}

action Gilman() {
   modify_field(Laplace.Neosho, 1);
   modify_field(Laplace.Buckholts, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Laplace.Shawmut, Belle);
}

table Montague {
   actions {
      Gilman;
   }
   default_action : Gilman;
   size : 1;
}

action BigPoint() {
   modify_field(Laplace.Affton, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Laplace.Shawmut);
}

table Ladoga {
   actions {
      BigPoint;
   }
   default_action : BigPoint();
   size : 1;
}

action Stamford(Kanab) {
   modify_field(Laplace.Flomot, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Kanab);
   modify_field(Laplace.Ocracoke, Kanab);
}

action Adair(Sylva) {
   modify_field(Laplace.Neosho, 1);
   modify_field(Laplace.Watters, Sylva);
}

action Alzada() {
}

table Switzer {
   reads {
      Laplace.Martelle : exact;
      Laplace.Metter : exact;
      Laplace.Shawmut : exact;
   }

   actions {
      Stamford;
      Adair;
      Alzada;
   }
   default_action : Alzada();
   size : Fackler;
}

control Rendville {
   if (Renton.Waitsburg == 0) {
      apply(Switzer) {
         Alzada {
            apply(Duelm) {
               Worland {
                  if ((Laplace.Martelle & 0x010000) == 0x010000) {
                     apply(Montague);
                  } else if (Laplace.Oakmont == 0) {
                     apply(Ladoga);
                  } else {
                     apply(Ladoga);
                  }
               }
            }
         }
      }
   }
}

action Lumpkin() {

   Pridgen();
}

table BigBar {
   actions {
      Lumpkin;
   }
   default_action : Lumpkin;
   size : 1;
}

control Level {
   if (Renton.Waitsburg == 0) {
      if ((Laplace.Oakmont==0) and (Renton.Pacifica==0) and (Renton.Lakin==0) and (Renton.Rodessa==Laplace.Ocracoke)) {
         apply(BigBar);
      }
   }
}

action GlenRock(Cochise) {
    modify_field(ig_intr_md_for_tm.level2_exclusion_id, Cochise);
}

table Monahans {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       GlenRock;
    }
    size : 512;
}

control Saugatuck {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Monahans);
   }
}



action Lumberton( Volcano ) {
   modify_field( Laplace.Robinson, Volcano );
}

action Lowden() {
   modify_field( Laplace.Robinson, Laplace.Shawmut );
}

table Flaxton {
   reads {
      eg_intr_md.egress_port : exact;
      Laplace.Shawmut : exact;
   }

   actions {
      Lumberton;
      Lowden;
   }
   default_action : Lowden;
   size : Whitefish;
}

control Poteet {
   apply( Flaxton );
}



action Edinburgh( Jackpot, Newhalen ) {
   modify_field( Laplace.Larchmont, Jackpot );
   modify_field( Laplace.Ogunquit, Newhalen );
}

action Hickox( Madeira, Cooter, Meyers, Vacherie ) {
   modify_field( Laplace.Larchmont, Madeira );
   modify_field( Laplace.Ogunquit, Cooter );
   modify_field( Laplace.Belwood, Meyers );
   modify_field( Laplace.Whitlash, Vacherie );
}


table Hitterdal {
   reads {
      Laplace.Tenino : exact;
   }

   actions {
      Edinburgh;
      Hickox;
   }
   size : Wallace;
}

action Marie(Rosburg, Hoven, Glenoma, Talkeetna) {
   modify_field( Laplace.Bluff, Rosburg );
   modify_field( Laplace.Arkoe, Hoven );
   modify_field( Laplace.Otsego, Glenoma );
   modify_field( Laplace.Norfork, Talkeetna );
}

table Lordstown {
   reads {

        Laplace.Riner : exact;
   }
   actions {
      Marie;
   }
   size : Wenham;
}

action Trail() {
   no_op();
}

action FortHunt() {
   modify_field( Leetsdale.Flippen, Casper[0].Aplin );
   remove_header( Casper[0] );
}

table Krupp {
   actions {
      FortHunt;
   }
   default_action : FortHunt;
   size : Lapoint;
}

action Paulding() {
   no_op();
}

action Holden() {
   add_header( Casper[ 0 ] );
   modify_field( Casper[0].Mariemont, Laplace.Robinson );
   modify_field( Casper[0].Aplin, Leetsdale.Flippen );
   modify_field( Leetsdale.Flippen, Weathers );
}



table Odebolt {
   reads {
      Laplace.Robinson : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Paulding;
      Holden;
   }
   default_action : Holden;
   size : Oketo;
}

action Wimberley() {
   modify_field(Leetsdale.Yardley, Laplace.Martelle);
   modify_field(Leetsdale.Wanatah, Laplace.Metter);
   modify_field(Leetsdale.Grantfork, Laplace.Larchmont);
   modify_field(Leetsdale.Walcott, Laplace.Ogunquit);
}

action Phelps() {
   Wimberley();
   add_to_field(Bowdon.Pelican, -1);
}

action Ackley() {
   Wimberley();
   add_to_field(Strasburg.Othello, -1);
}

action Hanapepe() {
   Holden();
}

action Nipton() {
   add_header( Lemhi );
   modify_field( Lemhi.Yardley, Laplace.Larchmont );
   modify_field( Lemhi.Wanatah, Laplace.Ogunquit );
   modify_field( Lemhi.Grantfork, Laplace.Belwood );
   modify_field( Lemhi.Walcott, Laplace.Whitlash );
   modify_field( Lemhi.Flippen, Lindsborg );
   add_header( Wallula );
   modify_field( Wallula.Lowemont, Laplace.Bluff );
   modify_field( Wallula.Nettleton, Laplace.Arkoe );
   modify_field( Wallula.Slagle, Laplace.Otsego );
   modify_field( Wallula.Haworth, Laplace.Norfork );
   modify_field( Wallula.Wrens, Laplace.Nerstrand );
}

table Yocemento {
   reads {
      Laplace.SanSimon : exact;
      Laplace.Tenino : exact;
      Laplace.Oakmont : exact;
      Bowdon.valid : ternary;
      Strasburg.valid : ternary;
   }

   actions {
      Phelps;
      Ackley;
      Hanapepe;
      Nipton;

   }
   size : Fentress;
}

control Ericsburg {
   apply( Krupp );
}

control Moorewood {
   apply( Odebolt );
}

control Seaford {
   apply( Hitterdal );
   apply( Lordstown );
   apply( Yocemento );
}



field_list Medart {
    Milesburg.Ferndale;
    Renton.Borup;
    Donna.Grantfork;
    Donna.Walcott;
    Bowdon.Satolah;
}

action Amasa() {
   generate_digest(Bethania, Medart);
}


table Chatcolet {
   actions {
      Amasa;
   }

   default_action : Amasa;
   size : 1;
}

control Maddock {
   if (Renton.Stanwood == 1) {
      apply(Chatcolet);
   }
}



action Yemassee( Anaconda ) {
   modify_field( Nason.Glyndon, Anaconda );
}

action Oconee() {
   modify_field( Nason.Glyndon, 0 );
}

table Dobbins {
   reads {
     Renton.Rodessa : ternary;
     Renton.Rainsburg : ternary;
     Silva.Exell : ternary;
   }

   actions {
     Yemassee;
     Oconee;
   }

   default_action : Oconee();
   size : Yukon;
}

action Thomas( Dugger ) {
   modify_field( Nason.Palco, Dugger );
   modify_field( Nason.Penzance, 0 );
   modify_field( Nason.HillTop, 0 );
}

action Mabank( Addicks, Energy ) {
   modify_field( Nason.Palco, 0 );
   modify_field( Nason.Penzance, Addicks );
   modify_field( Nason.HillTop, Energy );
}

action Westway( Lakehills, Joiner, PineHill ) {
   modify_field( Nason.Palco, Lakehills );
   modify_field( Nason.Penzance, Joiner );
   modify_field( Nason.HillTop, PineHill );
}

action Victoria() {
   modify_field( Nason.Palco, 0 );
   modify_field( Nason.Penzance, 0 );
   modify_field( Nason.HillTop, 0 );
}

table Kenbridge {
   reads {
     Nason.Glyndon : exact;
     Renton.Newsome : ternary;
     Renton.Wayland : ternary;
     Renton.Blevins : ternary;
   }

   actions {
     Thomas;
     Mabank;
     Westway;
     Victoria;
   }

   default_action : Victoria();
   size : Fontana;
}

table Camanche {
   reads {
     Nason.Glyndon : exact;
     Antimony.RushHill mask 0xffff0000 : ternary;
     Renton.Cascade : ternary;
     Renton.Ewing : ternary;
     Renton.Clintwood : ternary;
     Dellslow.Calamus : ternary;

   }

   actions {
     Thomas;
     Mabank;
     Westway;
     Victoria;
   }

   default_action : Victoria();
   size : Kenvil;
}

table Yorklyn {
   reads {
     Nason.Glyndon : exact;
     Baldridge.PikeView mask 0xffff0000 : ternary;
     Renton.Cascade : ternary;
     Renton.Ewing : ternary;
     Renton.Clintwood : ternary;
     Dellslow.Calamus : ternary;

   }

   actions {
     Thomas;
     Mabank;
     Westway;
     Victoria;
   }

   default_action : Victoria();
   size : Leflore;
}

meter Alamosa {
   type : packets;
   static : Cadott;
   instance_count: Folger;
}

action Olivet( Hettinger ) {
   // Unsupported address mode
   //execute_meter( Alamosa, Hettinger, ig_intr_md_for_tm.packet_color );
}

action Ceiba() {
   execute_meter( Alamosa, Nason.Penzance, ig_intr_md_for_tm.packet_color );
}

table Cadott {
   reads {
     Nason.Penzance : ternary;
     Renton.Rodessa : ternary;
     Renton.Rainsburg : ternary;
     Silva.Exell : ternary;
     Nason.HillTop : ternary;
   }
   actions {
      Olivet;
      Ceiba;
   }
   size : Teigen;
}

control Gause {
   apply( Dobbins );
}

control PineAire {
   if ( Renton.Hiwasse == 1 ) {
      apply( Camanche );
   } else if ( Renton.Sarepta == 1 ) {
      apply( Yorklyn );
   } else {
      apply( Kenbridge );
   }
}

control Hallwood {
   apply( Cadott );
}



action Careywood() {
   modify_field( Renton.Hartwick, Harding.Palmerton );
}

action Parmalee() {
   modify_field( Renton.Hartwick, Casper[0].Ranchito );
}

action Farragut() {
   modify_field( Renton.Clintwood, Harding.Lepanto );
}

action Coalgate() {
   modify_field( Renton.Clintwood, Antimony.Mapleview );
}

action Engle() {
   modify_field( Renton.Clintwood, Baldridge.Millston );
}

action Broadford( Dorothy, Floral ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Dorothy );
   modify_field( ig_intr_md_for_tm.qid, Floral );
}


table Cornish {
   reads {
     Renton.Loretto : exact;
   }

   actions {
     Careywood;
     Parmalee;
   }


   size : Reynolds;
}

table Wheatland {
   reads {
     Renton.Hiwasse : exact;
     Renton.Sarepta : exact;
   }

   actions {
     Farragut;
     Coalgate;
     Engle;
   }

   size : Wyanet;
}

table Kinsley {
   reads {
      Harding.Orrstown : ternary;
      Harding.Palmerton : ternary;


      Renton.Hartwick : ternary;
      Renton.Clintwood : ternary;
      Nason.Palco : ternary;
   }

   actions {
      Broadford;
   }

   size : Perma;
}

control Rardin {
   apply( Cornish );
   apply( Wheatland );
}

control Livengood {
   apply( Kinsley );
}




#define Suamico            0
#define Vieques  1
#define Folcroft 2


#define Shoreview           0




action Wyncote( Bieber ) {
   modify_field( Laplace.Tenino, Vieques );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Bieber );
}

action Stennett( Issaquah, Grampian ) {
   modify_field( Laplace.Tenino, Folcroft );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Issaquah );
   modify_field( Laplace.Riner, Grampian );

}

action Almelund() {



   modify_field(ig_intr_md_for_tm.drop_ctl, 1);

}

@pragma action_default_only Almelund

table Greenlawn {
   reads {
      Silva.Exell : exact;
      Harding.McKee : ternary;
      Laplace.Nerstrand : ternary;
   }

   actions {
      Wyncote;
      Stennett;
   }

   default_action: Almelund;
   size : Akiachak;
}

control Fallis {
   apply( Greenlawn );
}


control ingress {

   Maupin();


   Waukesha();
   Furman();
   Bagwell();


   Etter();
   Cozad();


   BoyRiver();
   Fowler();


   Russia();


   Pinole();


   Minto();
   Arthur();


   Decorah();
   Rardin();
   Gause();




   Maddock();
   Flaherty();
   if( Laplace.Bairoa == 0 ) {
      Rendville();
   }


   PineAire();
   if( Laplace.Bairoa == 0 ) {
      Level();
      Oxford();
   }


   if( valid( Casper[0] ) ) {
      Ericsburg();
   }





   Livengood();
   if( Renton.Waitsburg == 0 ) {
      Hallwood();
   }
   if( Laplace.Bairoa == 0 ) {
      Saugatuck();
   }
   if( Laplace.Bairoa == 1 ) {
      Fallis();
   }
}

control egress {
   Poteet();
   Seaford();

   if( Laplace.Bairoa == 0 ) {
      Moorewood();
   }
}

