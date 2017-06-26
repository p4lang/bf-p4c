// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 151312







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>






@pragma pa_solitary ingress Goodlett.DewyRose
@pragma pa_solitary ingress Goodlett.Blossom
@pragma pa_solitary ingress Goodlett.Deferiet
@pragma pa_solitary egress Roseau.Edinburg
@pragma pa_solitary ig_intr_md_for_tm.ucast_egress_port
@pragma pa_atomic ingress Sylva.Wamego
@pragma pa_solitary ingress Sylva.Wamego
@pragma pa_atomic ingress Sylva.Rosburg
@pragma pa_solitary ingress Sylva.Rosburg



#ifndef Kempton
#define Kempton

header_type Findlay {
	fields {
		Wardville : 16;
		Waialua : 16;
		Gypsum : 8;
		Storden : 8;
		Hauppauge : 8;
		Cowpens : 8;
		Donnelly : 1;
		Youngtown : 1;
		McCloud : 1;
		Sonoita : 1;
		Macedonia : 1;
		Milnor : 3;
	}
}

header_type Coamo {
	fields {
		Huxley : 24;
		Gomez : 24;
		Paradis : 24;
		Blitchton : 24;
		Reddell : 16;
		DewyRose : 16;
		Blossom : 16;
		Deferiet : 16;
		Mossville : 16;
		Cliffs : 8;
		McDermott : 8;
		Grapevine : 6;
		Everton : 1;
		Eldora : 1;
		Hobart : 12;
		Lisle : 2;
		Goulds : 1;
		Sylvester : 1;
		Maybeury : 1;
		Chatom : 1;
		Albemarle : 1;
		Blanchard : 1;
		Greendale : 1;
		Parkway : 1;
		Abernathy : 1;
		Gause : 1;
		Corinne : 1;
		Hanford : 1;
		Perryman : 1;
		Punaluu : 3;
	}
}

header_type Simnasho {
	fields {
		Rippon : 24;
		Surrey : 24;
		Noonan : 24;
		Newkirk : 24;
		Jefferson : 24;
		Dillsburg : 24;
		Derita : 24;
		Piney : 24;
		Raritan : 16;
		Brainard : 16;
		Dateland : 16;
		Edinburg : 16;
		Grabill : 12;
		Nightmute : 3;
		Kirley : 1;
		Pevely : 3;
		Amherst : 1;
		Adair : 1;
		Salamatof : 1;
		Borup : 1;
		Quinnesec : 1;
		Oakville : 8;
		Naches : 12;
		Baltic : 4;
		Pioche : 6;
		Heidrick : 10;
		Jenkins : 9;
		WindGap : 1;
		Orrstown : 1;
	}
}


header_type Rumson {
	fields {
		Pecos : 8;
		Nephi : 1;
		Dwight : 1;
		Chemult : 1;
		Elsey : 1;
		Alamosa : 1;
		Upson : 1;
	}
}

header_type Campbell {
	fields {
		Nuevo : 32;
		Atlasburg : 32;
		Tallevast : 6;
		Berville : 16;
	}
}

header_type Hopland {
	fields {
		Swaledale : 128;
		Range : 128;
		Freeman : 20;
		SomesBar : 8;
		Twinsburg : 11;
		Huffman : 8;
		Osterdock : 13;
	}
}

header_type Honuapo {
	fields {
		Buras : 14;
		Mishicot : 1;
		Ghent : 12;
		Farthing : 1;
		Edwards : 1;
		Perryton : 6;
		Forkville : 2;
		Wartrace : 6;
		Chevak : 3;
	}
}

header_type Diana {
	fields {
		TonkaBay : 1;
		Houston : 1;
	}
}

header_type McClusky {
	fields {
		Angwin : 8;
	}
}

header_type Daniels {
	fields {
		Shopville : 16;
		Oriskany : 11;
	}
}

header_type Colson {
	fields {
		Abilene : 32;
		Ferrum : 32;
		Duster : 32;
	}
}

header_type Cassadaga {
	fields {
		Wamego : 32;
		Rosburg : 32;
	}
}

header_type Armona {
	fields {
		Higganum : 2;
	}
}
#endif



#ifndef Marquand
#define Marquand


header_type McKenna {
	fields {
		Gotham : 6;
		Knierim : 10;
		Milbank : 4;
		Dandridge : 12;
		Equality : 12;
		DimeBox : 2;
		Exell : 2;
		Boyle : 8;
		Oroville : 3;
		Lapoint : 5;
	}
}



header_type Ocilla {
	fields {
		Berwyn : 24;
		Toulon : 24;
		Paoli : 24;
		Shelbiana : 24;
		Hannibal : 16;
	}
}



header_type Milwaukie {
	fields {
		Tarlton : 3;
		Henry : 1;
		Salome : 12;
		Valsetz : 16;
	}
}



header_type Beaman {
	fields {
		Gassoway : 4;
		Kurten : 4;
		Hemlock : 6;
		Sonora : 2;
		Winger : 16;
		Tolley : 16;
		Sawyer : 3;
		Academy : 13;
		Fairlea : 8;
		Emmalane : 8;
		LasLomas : 16;
		Shirley : 32;
		LeeCity : 32;
	}
}

header_type Baudette {
	fields {
		Livonia : 4;
		Maury : 6;
		Fentress : 2;
		Stonefort : 20;
		Slana : 16;
		Sawpit : 8;
		Alexis : 8;
		Davisboro : 128;
		Clarkdale : 128;
	}
}




header_type Hecker {
	fields {
		Havertown : 8;
		Laneburg : 8;
		Pridgen : 16;
	}
}

header_type McFaddin {
	fields {
		Staunton : 16;
		Nashua : 16;
		BigWater : 32;
		Toklat : 32;
		Cannelton : 4;
		Gullett : 4;
		Persia : 8;
		Bunavista : 16;
		Wainaku : 16;
		Beechwood : 16;
	}
}

header_type Venice {
	fields {
		Heizer : 16;
		Frederika : 16;
		Angus : 16;
		Vieques : 16;
	}
}



header_type Fackler {
	fields {
		Belmond : 16;
		Parker : 16;
		Weissert : 8;
		Lolita : 8;
		Chatanika : 16;
	}
}

header_type Camanche {
	fields {
		Remsen : 48;
		Uvalde : 32;
		Bixby : 48;
		Perrine : 32;
	}
}



header_type LaJara {
	fields {
		Claiborne : 1;
		Nanson : 1;
		Purves : 1;
		FortHunt : 1;
		Patsville : 1;
		Sandoval : 3;
		Glennie : 5;
		Leonore : 3;
		Selvin : 16;
	}
}

header_type Cedaredge {
	fields {
		Kinde : 24;
		Woodcrest : 8;
	}
}



header_type Haslet {
	fields {
		Clarion : 8;
		Seabrook : 24;
		Cecilton : 24;
		Bangor : 8;
	}
}

#endif



#ifndef Whitlash
#define Whitlash

#define Mondovi        0x8100
#define Swenson        0x0800
#define Alvordton        0x86dd
#define Goodrich        0x9100
#define LeaHill        0x8847
#define Lafayette         0x0806
#define Baytown        0x8035
#define Farson        0x88cc
#define Onawa        0x8809
#define Talihina      0xD28B

#define RioLajas              1
#define Tingley              2
#define Belview              4
#define Lisman               6
#define Ambler               17
#define Casper                47

#define Humarock         0x501
#define Montalba          0x506
#define Lardo          0x511
#define Covington          0x52F


#define Dibble                 4789



#define Blevins               0
#define Mystic              1
#define Green                2



#define Lodoga          0
#define Ardmore          4095
#define Alamota  4096
#define Kalaloch  8191



#define Platea                      0
#define Palmdale                  0
#define Telida                 1

header Ocilla Willette;
header Ocilla Wailuku;
header Milwaukie Moodys[ 2 ];
header Beaman Valmont;
header Beaman Weskan;
header Baudette Neubert;
header Baudette Shelbina;
header McFaddin Batchelor;
header Venice Kearns;
header McFaddin Suring;
header Venice Wimberley;
header Haslet Donner;
header Fackler Pengilly;
header LaJara Reynolds;
header McKenna Arvonia;
header Ocilla Pierson;

parser start {
   return select(current(96, 16)) {
      Talihina : Pathfork;
      default : Attica;
   }
}

parser Alcester {
   extract( Arvonia );
   return Attica;
}

parser Pathfork {
   extract( Pierson );
   return Alcester;
}

parser Attica {
   extract( Willette );
   return select( Willette.Hannibal ) {
      Mondovi : Hallville;
      Swenson : Berea;
      Alvordton : Daleville;
      Lafayette  : Epsie;
      default        : ingress;
   }
}

parser Hallville {
   extract( Moodys[0] );


   set_metadata(Mangham.Macedonia, 1);
   return select( Moodys[0].Valsetz ) {
      Swenson : Berea;
      Alvordton : Daleville;
      Lafayette  : Epsie;
      default : ingress;
   }
}

parser Berea {
   extract( Valmont );
   set_metadata(Mangham.Gypsum, Valmont.Emmalane);
   set_metadata(Mangham.Hauppauge, Valmont.Fairlea);
   set_metadata(Mangham.Wardville, Valmont.Winger);
   set_metadata(Mangham.McCloud, 0);
   set_metadata(Mangham.Donnelly, 1);
   return select(Valmont.Academy, Valmont.Kurten, Valmont.Emmalane) {
      Lardo : Gunder;
      default : ingress;
   }
}

parser Daleville {
   extract( Shelbina );
   set_metadata(Mangham.Gypsum, Shelbina.Sawpit);
   set_metadata(Mangham.Hauppauge, Shelbina.Alexis);
   set_metadata(Mangham.Wardville, Shelbina.Slana);
   set_metadata(Mangham.McCloud, 1);
   set_metadata(Mangham.Donnelly, 0);
   return ingress;
}

parser Epsie {
   extract( Pengilly );
   return ingress;
}

parser Gunder {
   extract(Kearns);
   return select(Kearns.Frederika) {
      Dibble : Shipman;
      default : ingress;
    }
}

parser Maumee {
   set_metadata(Goodlett.Lisle, Green);
   return Daguao;
}

parser Crumstown {
   set_metadata(Goodlett.Lisle, Green);
   return Cisne;
}

parser Triplett {
   extract(Reynolds);
   return select(Reynolds.Claiborne, Reynolds.Nanson, Reynolds.Purves, Reynolds.FortHunt, Reynolds.Patsville,
             Reynolds.Sandoval, Reynolds.Glennie, Reynolds.Leonore, Reynolds.Selvin) {
      Swenson : Maumee;
      Alvordton : Crumstown;
      default : ingress;
   }
}

parser Shipman {
   extract(Donner);
   set_metadata(Goodlett.Lisle, Mystic);
   return Verdery;
}

parser Daguao {
   extract( Weskan );
   set_metadata(Mangham.Storden, Weskan.Emmalane);
   set_metadata(Mangham.Cowpens, Weskan.Fairlea);
   set_metadata(Mangham.Waialua, Weskan.Winger);
   set_metadata(Mangham.Sonoita, 0);
   set_metadata(Mangham.Youngtown, 1);
   return ingress;
}

parser Cisne {
   extract( Neubert );
   set_metadata(Mangham.Storden, Neubert.Sawpit);
   set_metadata(Mangham.Cowpens, Neubert.Alexis);
   set_metadata(Mangham.Waialua, Neubert.Slana);
   set_metadata(Mangham.Sonoita, 1);
   set_metadata(Mangham.Youngtown, 0);
   return ingress;
}

parser Verdery {
   extract( Wailuku );
   return select( Wailuku.Hannibal ) {
      Swenson: Daguao;
      Alvordton: Cisne;
      default: ingress;
   }
}
#endif



@pragma pa_no_pack ingress Wolsey.Chevak Roseau.Adair
@pragma pa_no_pack ingress Wolsey.Chevak Goodlett.Punaluu
@pragma pa_no_pack ingress Wolsey.Chevak Mangham.Milnor
@pragma pa_no_pack ingress Wolsey.Perryton Roseau.Adair
@pragma pa_no_pack ingress Wolsey.Perryton Goodlett.Punaluu
@pragma pa_no_pack ingress Wolsey.Perryton Mangham.Milnor

@pragma pa_no_pack ingress Wolsey.Edwards Roseau.Borup
@pragma pa_no_pack ingress Wolsey.Edwards Roseau.Salamatof
@pragma pa_no_pack ingress Wolsey.Edwards Roseau.Amherst
@pragma pa_no_pack ingress Wolsey.Edwards Goodlett.Everton
@pragma pa_no_pack ingress Wolsey.Edwards Goodlett.Everton
@pragma pa_no_pack ingress Wolsey.Edwards Mangham.Sonoita
@pragma pa_no_pack ingress Wolsey.Edwards Mangham.McCloud
@pragma pa_no_pack ingress Wolsey.Edwards Ellicott.Alamosa

@pragma pa_no_pack ingress Wolsey.Perryton Goodlett.Perryman
@pragma pa_no_pack ingress Wolsey.Perryton Mangham.Macedonia

@pragma pa_no_pack ingress Wolsey.Forkville Goodlett.Punaluu
@pragma pa_no_pack ingress Wolsey.Forkville Mangham.Milnor

@pragma pa_no_pack ingress Wolsey.Edwards Goodlett.Punaluu
@pragma pa_no_pack ingress Wolsey.Edwards Mangham.Milnor
@pragma pa_no_pack ingress Wolsey.Edwards Goodlett.Albemarle

@pragma pa_no_pack ingress Wolsey.Edwards Goodlett.Perryman
@pragma pa_no_pack ingress Wolsey.Edwards Roseau.WindGap
@pragma pa_no_pack ingress Wolsey.Edwards Mangham.Macedonia
@pragma pa_no_pack ingress Wolsey.Edwards Roseau.Quinnesec

metadata Coamo Goodlett;
metadata Simnasho Roseau;
metadata Honuapo Wolsey;
metadata Findlay Mangham;
metadata Campbell Sanatoga;
metadata Hopland Broadford;
metadata Diana Rixford;
metadata Rumson Ellicott;
metadata McClusky Denby;
metadata Daniels Mather;
metadata Cassadaga Sylva;
metadata Colson Cisco;
metadata Armona Tenino;













#undef Kanorado

#undef Westwood
#undef Nelagoney
#undef Edler
#undef Thurmond
#undef Knollwood

#undef Charco
#undef Barksdale
#undef Nankin

#undef Sarasota
#undef Cruso
#undef MillHall
#undef Nursery
#undef Pound
#undef Bogota
#undef BoxElder
#undef Enderlin
#undef Eugene
#undef Beltrami
#undef RowanBay
#undef Lamboglia
#undef Amalga
#undef Lefors
#undef Belpre
#undef DelRosa
#undef Oklee
#undef Libby
#undef Emblem
#undef Thurston
#undef Victoria

#undef Pekin
#undef Clearco
#undef Hapeville
#undef Willows
#undef Lucas
#undef Hillsview
#undef Ugashik
#undef Lamont
#undef Earlsboro
#undef Center
#undef Pearcy
#undef ShowLow
#undef Piperton
#undef Leoma
#undef RoseTree
#undef Almedia
#undef Conneaut


#undef Friday

#undef Hilburn
#undef Sneads
#undef Tannehill
#undef Wapella

#undef Inola






#define Kanorado 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Westwood      65536
#define Nelagoney      65536
#define Edler 512
#define Thurmond 512
#define Knollwood      512


#define Charco     1024
#define Barksdale    1024
#define Nankin     256


#define Sarasota 512
#define Cruso 65536
#define MillHall 65536
#define Nursery 28672
#define Pound   16384
#define Bogota 8192
#define BoxElder         131072
#define Enderlin 65536
#define Eugene 1024
#define Beltrami 2048
#define RowanBay 16384
#define Lamboglia 8192
#define Amalga 65536

#define Lefors 0x0000000000000000FFFFFFFFFFFFFFFF


#define Belpre 0x000fffff
#define Libby 2

#define DelRosa 0xFFFFFFFFFFFFFFFF0000000000000000

#define Oklee 0x000007FFFFFFFFFF0000000000000000
#define Emblem  6
#define Victoria        2048
#define Thurston       65536


#define Pekin 1024
#define Clearco 4096
#define Hapeville 4096
#define Willows 4096
#define Lucas 4096
#define Hillsview 1024
#define Ugashik 4096
#define Earlsboro 64
#define Center 1
#define Pearcy  8
#define ShowLow 512
#define Almedia 512
#define Conneaut 256


#define Piperton 1
#define Leoma 3
#define RoseTree 80


#define Friday 0



#define Hilburn 2048


#define Sneads 4096



#define Tannehill 2048
#define Wapella 4096




#define Inola    4096

#endif



#ifndef Gonzales
#define Gonzales

action DosPalos() {
   no_op();
}

action DeLancey() {
   modify_field(Goodlett.Chatom, 1 );
}

action Waretown() {
   no_op();
}
#endif

















action Fallsburg(Leacock, Hartwick, Maybee, Moorcroft, Pickering, Robbs,
                 Sidon, Revere, Stone) {
    modify_field(Wolsey.Buras, Leacock);
    modify_field(Wolsey.Mishicot, Hartwick);
    modify_field(Wolsey.Ghent, Maybee);
    modify_field(Wolsey.Farthing, Moorcroft);
    modify_field(Wolsey.Edwards, Pickering);
    modify_field(Wolsey.Perryton, Robbs);
    modify_field(Wolsey.Forkville, Sidon);
    modify_field(Wolsey.Chevak, Revere);
    modify_field(Wolsey.Wartrace, Stone);
}

@pragma command_line --metadata-overlay False
@pragma command_line --no-dead-code-elimination
table Lapeer {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Fallsburg;
    }
    size : Kanorado;
}

control Flasher {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Lapeer);
    }
}





action Stampley(Puryear) {
   modify_field( Roseau.Kirley, 1 );
   modify_field( Roseau.Oakville, Puryear);
   modify_field( Goodlett.Gause, 1 );
}

action Bienville() {
   modify_field( Goodlett.Greendale, 1 );
   modify_field( Goodlett.Hanford, 1 );
}

action Washta() {
   modify_field( Goodlett.Gause, 1 );
}

action Vestaburg() {
   modify_field( Goodlett.Corinne, 1 );
}

action Camelot() {
   modify_field( Goodlett.Hanford, 1 );
}

counter Stuttgart {
   type : packets_and_bytes;
   direct : Jauca;
   min_width: 16;
}

table Jauca {
   reads {
      Wolsey.Perryton : exact;
      Willette.Berwyn : ternary;
      Willette.Toulon : ternary;
   }

   actions {
      Stampley;
      Bienville;
      Washta;
      Vestaburg;
      Camelot;
   }
   size : Edler;
}

action Parmelee() {
   modify_field( Goodlett.Parkway, 1 );
}


table Faysville {
   reads {
      Willette.Paoli : ternary;
      Willette.Shelbiana : ternary;
   }

   actions {
      Parmelee;
   }
   size : Thurmond;
}


control Nixon {
   apply( Jauca );
   apply( Faysville );
}




action Manville() {
   modify_field( Sanatoga.Nuevo, Weskan.Shirley );
   modify_field( Sanatoga.Atlasburg, Weskan.LeeCity );
   modify_field( Sanatoga.Tallevast, Weskan.Hemlock );
   modify_field( Broadford.Swaledale, Neubert.Davisboro );
   modify_field( Broadford.Range, Neubert.Clarkdale );
   modify_field( Broadford.Freeman, Neubert.Stonefort );


   modify_field( Goodlett.Huxley, Wailuku.Berwyn );
   modify_field( Goodlett.Gomez, Wailuku.Toulon );
   modify_field( Goodlett.Paradis, Wailuku.Paoli );
   modify_field( Goodlett.Blitchton, Wailuku.Shelbiana );
   modify_field( Goodlett.Reddell, Wailuku.Hannibal );
   modify_field( Goodlett.Mossville, Mangham.Waialua );
   modify_field( Goodlett.Cliffs, Mangham.Storden );
   modify_field( Goodlett.McDermott, Mangham.Cowpens );
   modify_field( Goodlett.Eldora, Mangham.Youngtown );
   modify_field( Goodlett.Everton, Mangham.Sonoita );
   modify_field( Goodlett.Perryman, 0 );
   modify_field( Wolsey.Forkville, 2 );
   modify_field( Wolsey.Chevak, 0 );
   modify_field( Wolsey.Wartrace, 0 );
}

action Ballville() {
   modify_field( Goodlett.Lisle, Blevins );
   modify_field( Sanatoga.Nuevo, Valmont.Shirley );
   modify_field( Sanatoga.Atlasburg, Valmont.LeeCity );
   modify_field( Sanatoga.Tallevast, Valmont.Hemlock );
   modify_field( Broadford.Swaledale, Shelbina.Davisboro );
   modify_field( Broadford.Range, Shelbina.Clarkdale );
   modify_field( Broadford.Freeman, Shelbina.Stonefort );


   modify_field( Goodlett.Huxley, Willette.Berwyn );
   modify_field( Goodlett.Gomez, Willette.Toulon );
   modify_field( Goodlett.Paradis, Willette.Paoli );
   modify_field( Goodlett.Blitchton, Willette.Shelbiana );
   modify_field( Goodlett.Reddell, Willette.Hannibal );
   modify_field( Goodlett.Mossville, Mangham.Wardville );
   modify_field( Goodlett.Cliffs, Mangham.Gypsum );
   modify_field( Goodlett.McDermott, Mangham.Hauppauge );
   modify_field( Goodlett.Eldora, Mangham.Donnelly );
   modify_field( Goodlett.Everton, Mangham.McCloud );
   modify_field( Goodlett.Punaluu, Mangham.Milnor );
   modify_field( Goodlett.Perryman, Mangham.Macedonia );
}

table Pembine {
   reads {
      Willette.Berwyn : exact;
      Willette.Toulon : exact;
      Valmont.LeeCity : exact;
      Goodlett.Lisle : exact;
   }

   actions {
      Manville;
      Ballville;
   }

   default_action : Ballville();
   size : Pekin;
}


action Toccopola() {
   modify_field( Goodlett.DewyRose, Wolsey.Ghent );
   modify_field( Goodlett.Blossom, Wolsey.Buras);
}

action Kountze( PineLake ) {
   modify_field( Goodlett.DewyRose, PineLake );
   modify_field( Goodlett.Blossom, Wolsey.Buras);
}

action Elysburg() {
   modify_field( Goodlett.DewyRose, Moodys[0].Salome );
   modify_field( Goodlett.Blossom, Wolsey.Buras);
}

table Othello {
   reads {
      Wolsey.Buras : ternary;
      Moodys[0] : valid;
      Moodys[0].Salome : ternary;
   }

   actions {
      Toccopola;
      Kountze;
      Elysburg;
   }
   size : Willows;
}

action Merit( Hatfield ) {
   modify_field( Goodlett.Blossom, Hatfield );
}

action Sisters() {

   modify_field( Goodlett.Maybeury, 1 );
   modify_field( Denby.Angwin,
                 Telida );
}

table Gibson {
   reads {
      Valmont.Shirley : exact;
   }

   actions {
      Merit;
      Sisters;
   }
   default_action : Sisters;
   size : Hapeville;
}

action Absarokee( Grandy, Oklahoma, LoonLake, Paxico, Empire,
                        Harmony, Braselton ) {
   modify_field( Goodlett.DewyRose, Grandy );
   modify_field( Goodlett.Deferiet, Grandy );
   modify_field( Goodlett.Blanchard, Braselton );
   Milltown(Oklahoma, LoonLake, Paxico, Empire,
                        Harmony );
}

action Hackney() {
   modify_field( Goodlett.Albemarle, 1 );
}

table Langdon {
   reads {
      Donner.Cecilton : exact;
   }

   actions {
      Absarokee;
      Hackney;
   }
   size : Clearco;
}

action Milltown(Corry, Newsome, Kalskag, Bonilla,
                        Needles ) {
   modify_field( Ellicott.Pecos, Corry );
   modify_field( Ellicott.Nephi, Newsome );
   modify_field( Ellicott.Chemult, Kalskag );
   modify_field( Ellicott.Dwight, Bonilla );
   modify_field( Ellicott.Elsey, Needles );
}

action Langhorne(Paisano, Lithonia, Walland, Pasadena,
                        Cache ) {
   modify_field( Goodlett.Deferiet, Wolsey.Ghent );
   modify_field( Goodlett.Blanchard, 1 );
   Milltown(Paisano, Lithonia, Walland, Pasadena,
                        Cache );
}

action Goudeau(Ridgetop, Mikkalo, Sparr, Verdemont,
                        BullRun, Bellport ) {
   modify_field( Goodlett.Deferiet, Ridgetop );
   modify_field( Goodlett.Blanchard, 1 );
   Milltown(Mikkalo, Sparr, Verdemont, BullRun,
                        Bellport );
}

action Saltdale(Wyndmere, Martelle, WestBay, Keenes,
                        DonaAna ) {
   modify_field( Goodlett.Deferiet, Moodys[0].Salome );
   modify_field( Goodlett.Blanchard, 1 );
   Milltown(Wyndmere, Martelle, WestBay, Keenes,
                        DonaAna );
}

table Phelps {
   reads {
      Wolsey.Ghent : exact;
   }


   actions {
      DosPalos;
      Langhorne;
   }

   size : Lucas;
}

@pragma action_default_only DosPalos
table LeMars {
   reads {
      Wolsey.Buras : exact;
      Moodys[0].Salome : exact;
   }

   actions {
      Goudeau;
      DosPalos;
   }

   size : Hillsview;
}

table Dizney {
   reads {
      Moodys[0].Salome : exact;
   }


   actions {
      DosPalos;
      Saltdale;
   }

   size : Ugashik;
}

control Rankin {
   apply( Pembine ) {
         Manville {
            apply( Gibson );
            apply( Langdon );
         }
         Ballville {
            if ( Wolsey.Farthing == 1 ) {
               apply( Othello );
            }
            if ( valid( Moodys[ 0 ] ) ) {

               apply( LeMars ) {
                  DosPalos {

                     apply( Dizney );
                  }
               }
            } else {

               apply( Phelps );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Skillman {
    width  : 1;
    static : Goree;
    instance_count : 262144;
}

register BigWells {
    width  : 1;
    static : Westland;
    instance_count : 262144;
}

blackbox stateful_alu Tillatoba {
    reg : Skillman;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Rixford.TonkaBay;
}

blackbox stateful_alu Gonzalez {
    reg : BigWells;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Rixford.Houston;
}

field_list Visalia {
    Wolsey.Perryton;
    Moodys[0].Salome;
}

field_list_calculation Sparland {
    input { Visalia; }
    algorithm: identity;
    output_width: 18;
}

action Ledger() {
    Tillatoba.execute_stateful_alu_from_hash(Sparland);
}

action Quinault() {
    Gonzalez.execute_stateful_alu_from_hash(Sparland);
}

table Goree {
    actions {
      Ledger;
    }
    default_action : Ledger;
    size : 1;
}

table Westland {
    actions {
      Quinault;
    }
    default_action : Quinault;
    size : 1;
}
#endif

action Tocito(Astor) {
    modify_field(Rixford.Houston, Astor);
}

@pragma  use_hash_action 0
table Cankton {
    reads {
       Wolsey.Perryton : exact;
    }
    actions {
      Tocito;
    }
    size : 64;
}

action Woodston() {
   modify_field( Goodlett.Hobart, Wolsey.Ghent );
   modify_field( Goodlett.Goulds, 0 );
}

table Nanakuli {
   actions {
      Woodston;
   }
   size : 1;
}

action Wheaton() {
   modify_field( Goodlett.Hobart, Moodys[0].Salome );
   modify_field( Goodlett.Goulds, 1 );
}

table Haven {
   actions {
      Wheaton;
   }
   size : 1;
}

control Parnell {
   if ( valid( Moodys[ 0 ] ) ) {
      apply( Haven );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Wolsey.Edwards == 1 ) {
         apply( Goree );
         apply( Westland );
      }
#endif
   } else {
      apply( Nanakuli );
      if( Wolsey.Edwards == 1 ) {
         apply( Cankton );
      }
   }
}




field_list Ojibwa {
   Willette.Berwyn;
   Willette.Toulon;
   Willette.Paoli;
   Willette.Shelbiana;
   Willette.Hannibal;
}

field_list ViewPark {

   Valmont.Emmalane;
   Valmont.Shirley;
   Valmont.LeeCity;
}

field_list Lucerne {
   Shelbina.Davisboro;
   Shelbina.Clarkdale;
   Shelbina.Stonefort;
   Shelbina.Sawpit;
}

field_list Waumandee {
   Valmont.Shirley;
   Valmont.LeeCity;
   Kearns.Heizer;
   Kearns.Frederika;
}





field_list_calculation Ericsburg {
    input {
        Ojibwa;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Silvertip {
    input {
        ViewPark;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Wiota {
    input {
        Lucerne;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Troup {
    input {
        Waumandee;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Craigmont() {
    modify_field_with_hash_based_offset(Cisco.Abilene, 0,
                                        Ericsburg, 4294967296);
}

action Lordstown() {
    modify_field_with_hash_based_offset(Cisco.Ferrum, 0,
                                        Silvertip, 4294967296);
}

action Longdale() {
    modify_field_with_hash_based_offset(Cisco.Ferrum, 0,
                                        Wiota, 4294967296);
}

action Gamaliel() {
    modify_field_with_hash_based_offset(Cisco.Duster, 0,
                                        Troup, 4294967296);
}

table Micro {
   actions {
      Craigmont;
   }
   size: 1;
}

control Malesus {
   apply(Micro);
}

table Flippen {
   actions {
      Lordstown;
   }
   size: 1;
}

table Dorris {
   actions {
      Longdale;
   }
   size: 1;
}

control Gibbstown {
   if ( valid( Valmont ) ) {
      apply(Flippen);
   } else {
      if ( valid( Shelbina ) ) {
         apply(Dorris);
      }
   }
}

table Norseland {
   actions {
      Gamaliel;
   }
   size: 1;
}

control Northway {
   if ( valid( Kearns ) ) {
      apply(Norseland);
   }
}



action Aiken() {
    modify_field(Sylva.Wamego, Cisco.Abilene);
}

action Ancho() {
    modify_field(Sylva.Wamego, Cisco.Ferrum);
}

action Brodnax() {
    modify_field(Sylva.Wamego, Cisco.Duster);
}

@pragma action_default_only DosPalos
@pragma immediate 0
table Pardee {
   reads {
      Suring.valid : ternary;
      Wimberley.valid : ternary;
      Weskan.valid : ternary;
      Neubert.valid : ternary;
      Wailuku.valid : ternary;
      Batchelor.valid : ternary;
      Kearns.valid : ternary;
      Valmont.valid : ternary;
      Shelbina.valid : ternary;
      Willette.valid : ternary;
   }
   actions {
      Aiken;
      Ancho;
      Brodnax;
      DosPalos;
   }
   size: Nankin;
}

action Croghan() {
    modify_field(Sylva.Rosburg, Cisco.Duster);
}

@pragma immediate 0
table Paradise {
   reads {
      Suring.valid : ternary;
      Wimberley.valid : ternary;
      Batchelor.valid : ternary;
      Kearns.valid : ternary;
   }
   actions {
      Croghan;
      DosPalos;
   }
   size: Emblem;
}

control Brookwood {
   apply(Paradise);
   apply(Pardee);
}



counter Holden {
   type : packets_and_bytes;
   direct : Selby;
   min_width: 16;
}

@pragma action_default_only DosPalos
table Selby {
   reads {
      Wolsey.Perryton : exact;
      Rixford.Houston : ternary;
      Rixford.TonkaBay : ternary;
      Goodlett.Albemarle : ternary;
      Goodlett.Parkway : ternary;
      Goodlett.Greendale : ternary;
   }

   actions {
      DeLancey;
      DosPalos;
   }
   size : Knollwood;
}

action Virgilina() {

   modify_field(Goodlett.Sylvester, 1 );
   modify_field(Denby.Angwin,
                Palmdale);
}







table Gamewell {
   reads {
      Goodlett.Paradis : exact;
      Goodlett.Blitchton : exact;
      Goodlett.DewyRose : exact;
      Goodlett.Blossom : exact;
   }

   actions {
      Waretown;
      Virgilina;
   }
   size : Nelagoney;
   support_timeout : true;
}

action SweetAir() {
   modify_field( Ellicott.Alamosa, 1 );
}

table Halley {
   reads {
      Goodlett.Deferiet : ternary;
      Goodlett.Huxley : exact;
      Goodlett.Gomez : exact;
   }
   actions {
      SweetAir;
   }
   size: Sarasota;
}

control Floral {
   apply( Selby ) {
      DosPalos {



         if (Wolsey.Mishicot == 0 and Goodlett.Maybeury == 0) {
            apply( Gamewell );
         }
         apply(Halley);
      }
   }
}

field_list Palco {
    Denby.Angwin;
    Goodlett.Paradis;
    Goodlett.Blitchton;
    Goodlett.DewyRose;
    Goodlett.Blossom;
}

action Kaeleku() {
   generate_digest(Platea, Palco);
}

table Kaufman {
   actions {
      Kaeleku;
   }
   size : 1;
}

control Trooper {
   if (Goodlett.Sylvester == 1) {
      apply( Kaufman );
   }
}



action Jackpot( Sherack, FoxChase ) {
   modify_field( Broadford.Osterdock, Sherack );
   modify_field( Mather.Shopville, FoxChase );
}

@pragma action_default_only Vevay
table Bennet {
   reads {
      Ellicott.Pecos : exact;
      Broadford.Range mask DelRosa : lpm;
   }
   actions {
      Jackpot;
      Vevay;
   }
   size : Lamboglia;
}

@pragma atcam_partition_index Broadford.Osterdock
@pragma atcam_number_partitions Lamboglia
table Kathleen {
   reads {
      Broadford.Osterdock : exact;
      Broadford.Range mask Oklee : lpm;
   }

   actions {
      OldMinto;
      Beresford;
      DosPalos;
   }
   default_action : DosPalos();
   size : Amalga;
}

action Bramwell( Centre, Altadena ) {
   modify_field( Broadford.Twinsburg, Centre );
   modify_field( Mather.Shopville, Altadena );
}

@pragma action_default_only DosPalos
table Colonias {


   reads {
      Ellicott.Pecos : exact;
      Broadford.Range : lpm;
   }

   actions {
      Bramwell;
      DosPalos;
   }

   size : Beltrami;
}

@pragma atcam_partition_index Broadford.Twinsburg
@pragma atcam_number_partitions Beltrami
table Waldport {
   reads {
      Broadford.Twinsburg : exact;


      Broadford.Range mask Lefors : lpm;
   }
   actions {
      OldMinto;
      Beresford;
      DosPalos;
   }

   default_action : DosPalos();
   size : RowanBay;
}

@pragma action_default_only Vevay
@pragma idletime_precision 1
table Crannell {

   reads {
      Ellicott.Pecos : exact;
      Sanatoga.Atlasburg : lpm;
   }

   actions {
      OldMinto;
      Beresford;
      Vevay;
   }

   size : Eugene;
   support_timeout : true;
}

action Bosler( Hueytown, Globe ) {
   modify_field( Sanatoga.Berville, Hueytown );
   modify_field( Mather.Shopville, Globe );
}

@pragma action_default_only DosPalos
#ifdef PROFILE_DEFAULT
@pragma stage 2 Bogota
@pragma stage 3
#endif
table Warsaw {
   reads {
      Ellicott.Pecos : exact;
      Sanatoga.Atlasburg : lpm;
   }

   actions {
      Bosler;
      DosPalos;
   }

   size : Pound;
}

@pragma ways Libby
@pragma atcam_partition_index Sanatoga.Berville
@pragma atcam_number_partitions Pound
table Bleecker {
   reads {
      Sanatoga.Berville : exact;
      Sanatoga.Atlasburg mask Belpre : lpm;
   }
   actions {
      OldMinto;
      Beresford;
      DosPalos;
   }
   default_action : DosPalos();
   size : BoxElder;
}

action OldMinto( Canalou ) {
   modify_field( Mather.Shopville, Canalou );
}

@pragma idletime_precision 1
table Motley {
   reads {
      Ellicott.Pecos : exact;
      Sanatoga.Atlasburg : exact;
   }

   actions {
      OldMinto;
      Beresford;
      DosPalos;
   }
   default_action : DosPalos();
   size : Cruso;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
@pragma stage 2 Nursery
@pragma stage 3
#endif
table Tappan {
   reads {
      Ellicott.Pecos : exact;
      Broadford.Range : exact;
   }

   actions {
      OldMinto;
      Beresford;
      DosPalos;
   }
   default_action : DosPalos();
   size : MillHall;
   support_timeout : true;
}

action Juneau(Auvergne, Cutten, Paulette) {
   modify_field(Roseau.Raritan, Paulette);
   modify_field(Roseau.Rippon, Auvergne);
   modify_field(Roseau.Surrey, Cutten);
   modify_field(Roseau.Orrstown, 1);
}

action Dunnegan() {
   modify_field(Goodlett.Chatom, 1);
}

action Springlee(Telma) {
   modify_field(Roseau.Kirley, 1);
   modify_field(Roseau.Oakville, Telma);
}

action Vevay() {
   modify_field( Roseau.Kirley, 1 );
   modify_field( Roseau.Oakville, 9 );
}

table Giltner {
   reads {
      Mather.Shopville : exact;
   }

   actions {
      Juneau;
      Dunnegan;
      Springlee;
   }
   size : Enderlin;
}

control ElMango {
   if ( Goodlett.Chatom == 0 and Ellicott.Alamosa == 1 ) {
      if ( ( Ellicott.Nephi == 1 ) and ( Goodlett.Eldora == 1 ) ) {
         apply( Motley ) {
            DosPalos {
               apply( Warsaw ) {
                  Bosler {
                     apply( Bleecker );
                  }
                  DosPalos {
                     apply( Crannell );
                  }
               }
            }
         }
      } else if ( ( Ellicott.Chemult == 1 ) and ( Goodlett.Everton == 1 ) ) {
         apply( Tappan ) {
            DosPalos {
               apply( Colonias ) {
                  Bramwell {
                     apply( Waldport );
                  }
                  DosPalos {

                     apply( Bennet ) {
                        Jackpot {
                           apply( Kathleen ) ;
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Stehekin {
   if( Mather.Shopville != 0 ) {
      apply( Giltner );
   }
}

action Beresford( Bayport ) {
   modify_field( Mather.Oriskany, Bayport );
   modify_field( Ellicott.Upson, 1 );
}

field_list Eddington {
   Sylva.Rosburg;
}

field_list_calculation Mayflower {
    input {
        Eddington;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Kotzebue {
   selection_key : Mayflower;
   selection_mode : resilient;
}

action_profile Sodaville {
   actions {
      OldMinto;
   }
   size : Thurston;
   dynamic_action_selection : Kotzebue;
}

table Subiaco {
   reads {
      Mather.Oriskany : exact;
   }
   action_profile : Sodaville;
   size : Victoria;
}

control Weslaco {
   if ( Mather.Oriskany != 0 ) {
      apply( Subiaco );
   }
}



field_list Hookdale {
   Sylva.Wamego;
}

field_list_calculation DeKalb {
    input {
        Hookdale;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Cotter {
    selection_key : DeKalb;
    selection_mode : resilient;
}

action Sieper(Cordell) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Cordell);
}

action_profile Hewitt {
    actions {
        Sieper;
        DosPalos;
    }
    size : Barksdale;
    dynamic_action_selection : Cotter;
}

table Gibsland {
   reads {
      Roseau.Dateland : exact;
   }
   action_profile: Hewitt;
   size : Charco;
}

control Neponset {
   if ((Roseau.Dateland & 0x2000) == 0x2000) {
      apply(Gibsland);
   }
}



meter Jayton {
   type : packets;
   static : Blackman;
   instance_count: Hilburn;
}

action Greenbush(Cullen) {
   execute_meter(Jayton, Cullen, Tenino.Higganum);
}

table Blackman {
   reads {
      Wolsey.Perryton : exact;
      Roseau.Oakville : exact;
   }
   actions {
      Greenbush;
   }
   size : Tannehill;
}

counter Stewart {
   type : packets;
   static : Yerington;
   instance_count : Sneads;
   min_width: 64;
}

action Hayfield(Hayfork) {
   modify_field(Goodlett.Chatom, 1);
   count(Stewart, Hayfork);
}

action Harding(Lynndyl) {
   count(Stewart, Lynndyl);
}

action Rehobeth(Grantfork, Eastman) {
   modify_field(ig_intr_md_for_tm.qid, Grantfork);
   count(Stewart, Eastman);
}

action Westvaco(Vallecito, Trona, Piermont) {
   modify_field(ig_intr_md_for_tm.qid, Vallecito);
   modify_field(ig_intr_md_for_tm.ingress_cos, Trona);
   count(Stewart, Piermont);
}

action Poteet(Mumford) {
   modify_field(ig_intr_md_for_tm.copy_to_cpu, 1);
   count(Stewart, Mumford);
}

table Yerington {
   reads {
      Wolsey.Perryton : exact;
      Roseau.Oakville : exact;
      Tenino.Higganum : exact;
   }

   actions {
      Hayfield;
      Rehobeth;
      Westvaco;
      Harding;
      Poteet;
   }
size : Wapella;
}



action Laurelton() {
   modify_field(Roseau.Rippon, Goodlett.Huxley);
   modify_field(Roseau.Surrey, Goodlett.Gomez);
   modify_field(Roseau.Noonan, Goodlett.Paradis);
   modify_field(Roseau.Newkirk, Goodlett.Blitchton);
   modify_field(Roseau.Raritan, Goodlett.DewyRose);
}

table Commack {
   actions {
      Laurelton;
   }
   default_action : Laurelton();
   size : 1;
}

control WestBend {
   if (Goodlett.DewyRose!=0) {
      apply( Commack );
   }
}

action Manasquan() {
   modify_field(Roseau.Adair, 1);
   modify_field(Roseau.Amherst, 1);
   modify_field(Roseau.Edinburg, Roseau.Raritan);
}

action Sawmills() {
}



@pragma ways 1
table Glenside {
   reads {
      Roseau.Rippon : exact;
      Roseau.Surrey : exact;
   }
   actions {
      Manasquan;
      Sawmills;
   }
   default_action : Sawmills;
   size : 1;
}

action Talkeetna() {
   modify_field(Roseau.Salamatof, 1);
   modify_field(Roseau.WindGap, 1);
   add(Roseau.Edinburg, Roseau.Raritan, Alamota);
}

table Lilydale {
   actions {
      Talkeetna;
   }
   default_action : Talkeetna;
   size : 1;
}

action Admire() {
   modify_field(Roseau.Quinnesec, 1);
   modify_field(Roseau.Edinburg, Roseau.Raritan);
}

table Dialville {
   actions {
      Admire;
   }
   default_action : Admire();
   size : 1;
}

action Wellton(Contact) {
   modify_field(Roseau.Borup, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Contact);
   modify_field(Roseau.Dateland, Contact);
}

action Machens(Lyncourt) {
   modify_field(Roseau.Salamatof, 1);
   modify_field(Roseau.Edinburg, Lyncourt);
}

action Escatawpa() {
}

table Reidland {
   reads {
      Roseau.Rippon : exact;
      Roseau.Surrey : exact;
      Roseau.Raritan : exact;
   }

   actions {
      Wellton;
      Machens;
      Escatawpa;
   }
   default_action : Escatawpa();
   size : Westwood;
}

control Filley {
   if (Goodlett.Chatom == 0 ) {
      apply(Reidland) {
         Escatawpa {
            apply(Glenside) {
               Sawmills {
                  if ((Roseau.Rippon & 0x010000) == 0x010000) {
                     apply(Lilydale);
                  } else {
                     apply(Dialville);
                  }
               }
            }
         }
      }
   }
}

action Biloxi() {
   modify_field(Goodlett.Abernathy, 1);
   modify_field(Goodlett.Chatom, 1);
}

table Orrick {
   actions {
      Biloxi;
   }
   default_action : Biloxi;
   size : 1;
}

control Ribera {
   if (Goodlett.Chatom == 0) {
      if ((Roseau.Orrstown==0) and (Goodlett.Blossom==Roseau.Dateland)) {
         apply(Orrick);
      } else {
         apply(Blackman);
         apply(Yerington);
      }
   }
}



action Chalco( Garrison ) {
   modify_field( Roseau.Grabill, Garrison );
}

action Spearman() {
   modify_field( Roseau.Grabill, Roseau.Raritan );
}

table Kingsland {
   reads {
      eg_intr_md.egress_port : exact;
      Roseau.Raritan : exact;
   }

   actions {
      Chalco;
      Spearman;
   }
   default_action : Spearman;
   size : Inola;
}

control Ladner {
   apply( Kingsland );
}



action Hennessey( Newellton, Barclay ) {
   modify_field( Roseau.Jefferson, Newellton );
   modify_field( Roseau.Dillsburg, Barclay );
}

action Marley( Wahoo, Iroquois, Fittstown, Monse ) {
   modify_field( Roseau.Jefferson, Wahoo );
   modify_field( Roseau.Dillsburg, Iroquois );
   modify_field( Roseau.Derita, Fittstown );
   modify_field( Roseau.Piney, Monse );
}


table Braxton {
   reads {
      Roseau.Nightmute : exact;
   }

   actions {
      Hennessey;
      Marley;
   }
   size : Pearcy;
}

action Baker(Mattson, Roscommon, Macopin, Zemple) {
   modify_field( Roseau.Pioche, Mattson );
   modify_field( Roseau.Heidrick, Roscommon );
   modify_field( Roseau.Baltic, Macopin );
   modify_field( Roseau.Naches, Zemple );
}

table Veteran {
   reads {
        Roseau.Jenkins : exact;
   }
   actions {
      Baker;
   }
   size : Conneaut;
}

action Parkland() {
   no_op();
}

action Oilmont() {
   modify_field( Willette.Hannibal, Moodys[0].Valsetz );
   remove_header( Moodys[0] );
}

table Alzada {
   actions {
      Oilmont;
   }
   default_action : Oilmont;
   size : Center;
}

action Jelloway() {
   no_op();
}

action Tonasket() {
   add_header( Moodys[ 0 ] );
   modify_field( Moodys[0].Salome, Roseau.Grabill );
   modify_field( Moodys[0].Valsetz, Willette.Hannibal );
   modify_field( Willette.Hannibal, Mondovi );
}



table Haverford {
   reads {
      Roseau.Grabill : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Jelloway;
      Tonasket;
   }
   default_action : Tonasket;
   size : Earlsboro;
}

action Baidland() {
   modify_field(Willette.Berwyn, Roseau.Rippon);
   modify_field(Willette.Toulon, Roseau.Surrey);
   modify_field(Willette.Paoli, Roseau.Jefferson);
   modify_field(Willette.Shelbiana, Roseau.Dillsburg);
}

action Brantford() {
   Baidland();
   add_to_field(Valmont.Fairlea, -1);
}

action Arriba() {
   Baidland();
   add_to_field(Shelbina.Alexis, -1);
}

action Swain() {
   Tonasket();
}

action Wallace() {
   add_header( Pierson );
   modify_field( Pierson.Berwyn, Roseau.Jefferson );
   modify_field( Pierson.Toulon, Roseau.Dillsburg );
   modify_field( Pierson.Paoli, 0x020000 );
   modify_field( Pierson.Shelbiana, 0 );





   modify_field( Pierson.Hannibal, Talihina );
   add_header( Arvonia );
   modify_field( Arvonia.Gotham, Roseau.Pioche );
   modify_field( Arvonia.Knierim, Roseau.Heidrick );
   modify_field( Arvonia.Milbank, Roseau.Baltic );
   modify_field( Arvonia.Dandridge, Roseau.Naches );
   modify_field( Arvonia.Boyle, Roseau.Oakville );
}

table CityView {
   reads {
      Roseau.Pevely : exact;
      Roseau.Nightmute : exact;
      Roseau.Orrstown : exact;
      Valmont.valid : ternary;
      Shelbina.valid : ternary;
   }

   actions {
      Brantford;
      Arriba;
      Swain;
      Wallace;
   }
   size : ShowLow;
}

control Peosta {
   apply( Alzada );
}

control Metter {
   apply( Haverford );
}

control Pineridge {
   apply( Braxton );
   apply( Veteran );
   apply( CityView );
}



field_list Blakeslee {
    Denby.Angwin;
    Goodlett.DewyRose;
    Wailuku.Paoli;
    Wailuku.Shelbiana;
    Valmont.Shirley;
}

action Ottertail() {
   generate_digest(Platea, Blakeslee);
}

table Bondad {
   actions {
      Ottertail;
   }

   default_action : Ottertail;
   size : 1;
}

control Johnsburg {
   if (Goodlett.Maybeury == 1) {
      apply(Bondad);
   }
}



action WoodDale() {
   modify_field( Goodlett.Punaluu, Wolsey.Chevak );
}

action Arcanum() {
   modify_field( Goodlett.Grapevine, Wolsey.Wartrace );
}

action Driftwood() {
   modify_field( Goodlett.Grapevine, Sanatoga.Tallevast );
}

action Jarreau() {
   modify_field( Goodlett.Grapevine, Broadford.Huffman );
}

action Tonkawa( Larue, Connell ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Larue );
   modify_field( ig_intr_md_for_tm.qid, Connell );
}

table RioPecos {
   reads {
     Goodlett.Perryman : exact;
   }

   actions {
     WoodDale;
   }

   size : Piperton;
}

table Chappell {
   reads {
     Goodlett.Eldora : exact;
     Goodlett.Everton : exact;
   }

   actions {
     Arcanum;
     Driftwood;
     Jarreau;
   }

   size : Leoma;
}

@pragma stage 10
table Pittsboro {
   reads {
      Wolsey.Forkville : exact;
      Wolsey.Chevak : ternary;
      Goodlett.Punaluu : ternary;
      Goodlett.Grapevine : ternary;
   }

   actions {
      Tonkawa;
   }

   size : RoseTree;
}

control Sabetha {
   apply( RioPecos );
   apply( Chappell );
}

control WolfTrap {
   apply( Pittsboro );
}




#define RockyGap            0
#define Cloverly  1
#define Papeton 2


#define ElPrado           0




action Depew( Bellmead ) {
   modify_field( Roseau.Nightmute, Cloverly );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Bellmead );
}

action Pilar( Dagsboro ) {
   modify_field( Roseau.Nightmute, Papeton );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Dagsboro );
   modify_field( Roseau.Jenkins, ig_intr_md.ingress_port );
}

table Sebewaing {
   reads {
      Ellicott.Alamosa : exact;
      Wolsey.Farthing : ternary;
      Roseau.Oakville : ternary;
   }

   actions {
      Depew;
      Pilar;
   }

   size : Almedia;
}

control LeSueur {
   apply( Sebewaing );
}


control ingress {

   Flasher();
   Nixon();
   Rankin();
   Parnell();
   Malesus();


   Sabetha();
   Floral();

   Gibbstown();
   Northway();


   ElMango();
   Brookwood();
   Weslaco();

   WestBend();

   Stehekin();






   if( Roseau.Kirley == 0 ) {
      Filley();
   } else {
      LeSueur();
   }
   WolfTrap();


   Ribera();
   Neponset();
   Johnsburg();
   Trooper();


   if( valid( Moodys[0] ) ) {
      Peosta();
   }






}

control egress {
   Ladner();
   Pineridge();

   if( Roseau.Kirley == 0 ) {
      Metter();
   }
}

