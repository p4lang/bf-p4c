// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 101327







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>



#ifndef Muenster
#define Muenster

header_type Romeo {
	fields {
		Cutten : 16;
		Olmitz : 16;
		Vidaurri : 8;
		Selawik : 8;
		Rawson : 8;
		Gakona : 8;
		Kiana : 1;
		Onamia : 1;
		Carlson : 1;
		Wanatah : 1;
		RedLake : 1;
		Benitez : 3;
	}
}

header_type Decherd {
	fields {
		Piketon : 24;
		Fiftysix : 24;
		Geeville : 24;
		Hitchland : 24;
		Cammal : 16;
		Edgemoor : 16;
		Wenatchee : 16;
		Farragut : 16;
		Sanchez : 16;
		Vidal : 8;
		Nixon : 8;
		Gillette : 6;
		Tappan : 1;
		Magma : 1;
		Ribera : 12;
		Pierpont : 2;
		Napanoch : 1;
		Bannack : 1;
		Bronaugh : 1;
		Rockaway : 1;
		Hargis : 1;
		Retrop : 1;
		Norias : 1;
		Harshaw : 1;
		Yorkville : 1;
		Reubens : 1;
		Blanchard : 1;
		Sherrill : 1;
		RedBay : 1;
		Tolley : 3;
	}
}

header_type Tatitlek {
	fields {
		Pearland : 24;
		Rippon : 24;
		Joshua : 24;
		Suamico : 24;
		Eddington : 24;
		Standard : 24;
		Grampian : 24;
		Rocklake : 24;
		Hollyhill : 16;
		Balmville : 16;
		Gassoway : 16;
		Benson : 16;
		ElRio : 12;
		Oklahoma : 3;
		Ludden : 1;
		Grinnell : 3;
		WestEnd : 1;
		Toccopola : 1;
		Mancelona : 1;
		Champlain : 1;
		Kranzburg : 1;
		Pownal : 1;
		Ionia : 8;
		Malaga : 12;
		Bairoil : 4;
		Neame : 6;
		Castine : 10;
		Lumberton : 9;
		FairOaks : 1;
	}
}


header_type Angle {
	fields {
		Kiron : 8;
		Mariemont : 1;
		Eldred : 1;
		Lakehills : 1;
		Sublett : 1;
		Saticoy : 1;
	}
}

header_type Caspian {
	fields {
		Hammocks : 32;
		Fordyce : 32;
		Washoe : 6;
		Mossville : 16;
	}
}

header_type Lutsen {
	fields {
		Selby : 128;
		Overton : 128;
		Annville : 20;
		Udall : 8;
		Sharon : 11;
		Jigger : 8;
		Suffolk : 13;
	}
}

header_type Isabela {
	fields {
		Chatanika : 14;
		Terrytown : 1;
		Woodfield : 12;
		Sahuarita : 1;
		Bells : 1;
		Castolon : 6;
		Pearcy : 2;
		Blitchton : 6;
		Excel : 3;
	}
}

header_type Weleetka {
	fields {
		Fackler : 1;
		Yreka : 1;
	}
}

header_type Markesan {
	fields {
		Valdosta : 8;
	}
}

header_type Borup {
	fields {
		VanZandt : 16;
		Choudrant : 11;
	}
}

header_type Gypsum {
	fields {
		Blairsden : 32;
		Aiken : 32;
		Odell : 32;
	}
}

header_type Kinston {
	fields {
		Aberfoil : 32;
		Maytown : 32;
	}
}

header_type Borth {
	fields {
		Armstrong : 8;
		Sabula : 4;
		DeWitt : 15;
		WestLawn : 1;
	}
}
#endif



#ifndef Alsea
#define Alsea


header_type McGrady {
	fields {
		Raynham : 6;
		Valeene : 10;
		Almond : 4;
		Woodburn : 12;
		Boydston : 12;
		Damar : 2;
		Lowland : 2;
		Jones : 8;
		FortShaw : 3;
		Woodsdale : 5;
	}
}



header_type Merrill {
	fields {
		Bloomdale : 24;
		Simla : 24;
		Bovina : 24;
		Craig : 24;
		Hartville : 16;
	}
}



header_type Stidham {
	fields {
		Rolla : 3;
		Hubbell : 1;
		Kansas : 12;
		Ossipee : 16;
	}
}



header_type Safford {
	fields {
		Maxwelton : 4;
		Trilby : 4;
		Piqua : 6;
		Westbury : 2;
		Hanover : 16;
		Chitina : 16;
		Lofgreen : 3;
		Robert : 13;
		Flaherty : 8;
		Renville : 8;
		Ackley : 16;
		Mondovi : 32;
		Hiwassee : 32;
	}
}

header_type Grasmere {
	fields {
		Conover : 4;
		Paicines : 6;
		Charters : 2;
		BigPoint : 20;
		Colson : 16;
		Faulkner : 8;
		Chardon : 8;
		Scranton : 128;
		Newtok : 128;
	}
}




header_type Easley {
	fields {
		Pajaros : 8;
		Ruston : 8;
		Indios : 16;
	}
}

header_type Accomac {
	fields {
		Edmeston : 16;
		Cassa : 16;
		Delmont : 32;
		Crooks : 32;
		HighHill : 4;
		Carlin : 4;
		Tannehill : 8;
		Tyrone : 16;
		Burdette : 16;
		RowanBay : 16;
	}
}

header_type Solomon {
	fields {
		Hector : 16;
		Shubert : 16;
		Waucousta : 16;
		Woodstown : 16;
	}
}



header_type Frederic {
	fields {
		Caguas : 16;
		Oconee : 16;
		Hoagland : 8;
		LaCenter : 8;
		Wimberley : 16;
	}
}

header_type Brashear {
	fields {
		Flomot : 48;
		Longwood : 32;
		Fitzhugh : 48;
		Helen : 32;
	}
}



header_type Irondale {
	fields {
		Natalbany : 1;
		Lackey : 1;
		Louin : 1;
		Redfield : 1;
		WebbCity : 1;
		Adair : 3;
		Taylors : 5;
		FulksRun : 3;
		Dunphy : 16;
	}
}

header_type Hewins {
	fields {
		Tivoli : 24;
		Kirwin : 8;
	}
}



header_type Traskwood {
	fields {
		Boerne : 8;
		Fennimore : 24;
		Gobles : 24;
		Marshall : 8;
	}
}

#endif



#ifndef Moclips
#define Moclips

#define Remington        0x8100
#define Ambrose        0x0800
#define Turkey        0x86dd
#define SneeOosh        0x9100
#define Mabank        0x8847
#define Larchmont         0x0806
#define Burmester        0x8035
#define Eggleston        0x88cc
#define Evelyn        0x8809
#define Wapato      0xBF00

#define Fiskdale              1
#define Tennyson              2
#define RoseTree              4
#define Hitterdal               6
#define BoyRiver               17
#define Ekron                47

#define McCracken         0x501
#define Lawnside          0x506
#define IttaBena          0x511
#define HillCity          0x52F


#define Macungie                 4789



#define Maryville               0
#define Point              1
#define LaLuz                2



#define Biggers          0
#define Sigsbee          4095
#define Mumford  4096
#define Salus  8191



#define Overbrook                      0
#define Ignacio                  0
#define Donnelly                 1

header Merrill Gratis;
header Merrill Moxley;
header Stidham Dunnstown[ 2 ];
header Safford Thaxton;
header Safford Fonda;
header Grasmere Cruso;
header Grasmere Gilliatt;
header Accomac NantyGlo;
header Solomon Edmondson;
header Accomac Masardis;
header Solomon Florala;
header Traskwood Olyphant;
header Frederic Masontown;
header Irondale Gabbs;
header McGrady Davie;
header Merrill Ayden;

parser start {
   return select(current(96, 16)) {
      Wapato : Culloden;
      default : Neosho;
   }
}

parser Klukwan {
   extract( Davie );
   return Neosho;
}

parser Culloden {
   extract( Ayden );
   return Klukwan;
}

parser Neosho {
   extract( Gratis );
   return select( Gratis.Hartville ) {
      Remington : Rienzi;
      Ambrose : DelMar;
      Turkey : Telocaset;
      Larchmont  : Amalga;
      default        : ingress;
   }
}

parser Rienzi {
   extract( Dunnstown[0] );
   set_metadata(Nucla.Benitez, Dunnstown[0].Rolla );
   set_metadata(Nucla.RedLake, 1);
   return select( Dunnstown[0].Ossipee ) {
      Ambrose : DelMar;
      Turkey : Telocaset;
      Larchmont  : Amalga;
      default : ingress;
   }
}

parser DelMar {
   extract( Thaxton );
   set_metadata(Nucla.Vidaurri, Thaxton.Renville);
   set_metadata(Nucla.Rawson, Thaxton.Flaherty);
   set_metadata(Nucla.Cutten, Thaxton.Hanover);
   set_metadata(Nucla.Carlson, 0);
   set_metadata(Nucla.Kiana, 1);
   return select(Thaxton.Robert, Thaxton.Trilby, Thaxton.Renville) {
      IttaBena : Pinta;
      default : ingress;
   }
}

parser Telocaset {
   extract( Gilliatt );
   set_metadata(Nucla.Vidaurri, Gilliatt.Faulkner);
   set_metadata(Nucla.Rawson, Gilliatt.Chardon);
   set_metadata(Nucla.Cutten, Gilliatt.Colson);
   set_metadata(Nucla.Carlson, 1);
   set_metadata(Nucla.Kiana, 0);
   return ingress;
}

parser Amalga {
   extract( Masontown );
   return ingress;
}

parser Pinta {
   extract(Edmondson);
   return select(Edmondson.Shubert) {
      Macungie : Ingleside;
      default : ingress;
    }
}

parser Weslaco {
   set_metadata(Goodrich.Pierpont, LaLuz);
   return Millstone;
}

parser Ronneby {
   set_metadata(Goodrich.Pierpont, LaLuz);
   return Whitetail;
}

parser Rixford {
   extract(Gabbs);
   return select(Gabbs.Natalbany, Gabbs.Lackey, Gabbs.Louin, Gabbs.Redfield, Gabbs.WebbCity,
             Gabbs.Adair, Gabbs.Taylors, Gabbs.FulksRun, Gabbs.Dunphy) {
      Ambrose : Weslaco;
      Turkey : Ronneby;
      default : ingress;
   }
}

parser Ingleside {
   extract(Olyphant);
   set_metadata(Goodrich.Pierpont, Point);
   return Coventry;
}

parser Millstone {
   extract( Fonda );
   set_metadata(Nucla.Selawik, Fonda.Renville);
   set_metadata(Nucla.Gakona, Fonda.Flaherty);
   set_metadata(Nucla.Olmitz, Fonda.Hanover);
   set_metadata(Nucla.Wanatah, 0);
   set_metadata(Nucla.Onamia, 1);
   return ingress;
}

parser Whitetail {
   extract( Cruso );
   set_metadata(Nucla.Selawik, Cruso.Faulkner);
   set_metadata(Nucla.Gakona, Cruso.Chardon);
   set_metadata(Nucla.Olmitz, Cruso.Colson);
   set_metadata(Nucla.Wanatah, 1);
   set_metadata(Nucla.Onamia, 0);
   return ingress;
}

parser Coventry {
   extract( Moxley );
   return select( Moxley.Hartville ) {
      Ambrose: Millstone;
      Turkey: Whitetail;
      default: ingress;
   }
}
#endif

metadata Decherd Goodrich;
metadata Tatitlek Cusseta;
metadata Isabela Waseca;
metadata Romeo Nucla;
metadata Caspian Fredonia;
metadata Lutsen Mabel;
metadata Weleetka Rockleigh;
metadata Angle Westville;
metadata Markesan Saragosa;
metadata Borup Sudden;
metadata Kinston Ancho;
metadata Gypsum Champlin;
metadata Borth Romero;













#undef Charenton

#undef Crouch
#undef Frankston
#undef Minetto
#undef Tabler
#undef Cidra

#undef Wilsey
#undef Bethesda
#undef Covert

#undef Menomonie
#undef Ruthsburg
#undef Ouachita
#undef Seattle
#undef Saxonburg
#undef Odessa
#undef Bozar
#undef Decorah
#undef McFaddin
#undef Tinaja
#undef Wakenda
#undef Lattimore
#undef Monee
#undef Shoreview
#undef Belmont
#undef Sanford
#undef Westwood
#undef Brundage
#undef McIntosh
#undef Anandale
#undef Isleta

#undef Glenvil
#undef Corvallis
#undef Okaton
#undef Pilottown
#undef Kentwood
#undef Sandstone
#undef Vallejo
#undef Holyoke
#undef Eskridge
#undef Rhodell
#undef Franklin
#undef Ossining
#undef Goosport
#undef Cathcart
#undef Pittsburg
#undef Calimesa
#undef GilaBend
#undef Stovall
#undef Sarepta
#undef Wimbledon
#undef Throop

#undef Counce
#undef Duchesne

#undef Moorcroft

#undef Lyncourt







#define Charenton 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Crouch      65536
#define Frankston      65536
#define Minetto 512
#define Tabler 512
#define Cidra      512


#define Wilsey     1024
#define Bethesda    1024
#define Covert     256


#define Menomonie 512
#define Ruthsburg 65536
#define Ouachita 65536
#define Seattle 28672
#define Saxonburg   16384
#define Odessa 8192
#define Bozar         131072
#define Decorah 65536
#define McFaddin 1024
#define Tinaja 2048
#define Wakenda 16384
#define Lattimore 8192
#define Monee 65536

#define Shoreview 0x0000000000000000FFFFFFFFFFFFFFFF


#define Belmont 0x000fffff
#define Brundage 2

#define Sanford 0xFFFFFFFFFFFFFFFF0000000000000000

#define Westwood 0x000007FFFFFFFFFF0000000000000000
#define McIntosh  6
#define Isleta        2048
#define Anandale       65536


#define Glenvil 1024
#define Corvallis 4096
#define Okaton 4096
#define Pilottown 4096
#define Kentwood 4096
#define Sandstone 1024
#define Vallejo 4096
#define Eskridge 128
#define Rhodell 1
#define Franklin  8


#define Ossining 512
#define Counce 512
#define Duchesne 256


#define Goosport 1
#define Cathcart 3
#define Pittsburg 80



#define Calimesa 512
#define GilaBend 512
#define Stovall 512
#define Sarepta 512

#define Wimbledon 2048
#define Throop 1024



#define Moorcroft 0


#define Lyncourt    4096

#endif



#ifndef Hooker
#define Hooker

action Norland() {
   no_op();
}

action McLaurin() {
   modify_field(Goodrich.Rockaway, 1 );
   mark_for_drop();
}

action Captiva() {
   no_op();
}
#endif

















action Juniata(Waretown, Burgin, Bradner, Cochise, Gheen, Vevay,
                 Robins, McQueen, Skagway) {
    modify_field(Waseca.Chatanika, Waretown);
    modify_field(Waseca.Terrytown, Burgin);
    modify_field(Waseca.Woodfield, Bradner);
    modify_field(Waseca.Sahuarita, Cochise);
    modify_field(Waseca.Bells, Gheen);
    modify_field(Waseca.Castolon, Vevay);
    modify_field(Waseca.Pearcy, Robins);
    modify_field(Waseca.Excel, McQueen);
    modify_field(Waseca.Blitchton, Skagway);
}

@pragma command_line --no-dead-code-elimination
table Lyman {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Juniata;
    }
    size : Charenton;
}

control Cataract {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Lyman);
    }
}





action Ruffin(Aguilita) {
   modify_field( Cusseta.Ludden, 1 );
   modify_field( Cusseta.Ionia, Aguilita);
   modify_field( Goodrich.Reubens, 1 );
}

action Madill() {
   modify_field( Goodrich.Norias, 1 );
   modify_field( Goodrich.Sherrill, 1 );
}

action Gomez() {
   modify_field( Goodrich.Reubens, 1 );
}

action Northboro() {
   modify_field( Goodrich.Blanchard, 1 );
}

action Arminto() {
   modify_field( Goodrich.Sherrill, 1 );
}

counter Lahaina {
   type : packets_and_bytes;
   direct : RockHall;
   min_width: 16;
}

table RockHall {
   reads {
      Waseca.Castolon : exact;
      Gratis.Bloomdale : ternary;
      Gratis.Simla : ternary;
   }

   actions {
      Ruffin;
      Madill;
      Gomez;
      Northboro;
      Arminto;
   }
   size : Minetto;
}

action Escondido() {
   modify_field( Goodrich.Harshaw, 1 );
}


table Ishpeming {
   reads {
      Gratis.Bovina : ternary;
      Gratis.Craig : ternary;
   }

   actions {
      Escondido;
   }
   size : Tabler;
}


control Grassflat {
   apply( RockHall );
   apply( Ishpeming );
}




action Brookston() {
   modify_field( Fredonia.Hammocks, Fonda.Mondovi );
   modify_field( Fredonia.Fordyce, Fonda.Hiwassee );
   modify_field( Fredonia.Washoe, Fonda.Piqua );
   modify_field( Mabel.Selby, Cruso.Scranton );
   modify_field( Mabel.Overton, Cruso.Newtok );
   modify_field( Mabel.Annville, Cruso.BigPoint );
   modify_field( Mabel.Jigger, Cruso.Paicines );
   modify_field( Goodrich.Piketon, Moxley.Bloomdale );
   modify_field( Goodrich.Fiftysix, Moxley.Simla );
   modify_field( Goodrich.Geeville, Moxley.Bovina );
   modify_field( Goodrich.Hitchland, Moxley.Craig );
   modify_field( Goodrich.Cammal, Moxley.Hartville );
   modify_field( Goodrich.Sanchez, Nucla.Olmitz );
   modify_field( Goodrich.Vidal, Nucla.Selawik );
   modify_field( Goodrich.Nixon, Nucla.Gakona );
   modify_field( Goodrich.Magma, Nucla.Onamia );
   modify_field( Goodrich.Tappan, Nucla.Wanatah );
   modify_field( Goodrich.RedBay, 0 );
   modify_field( Waseca.Pearcy, 2 );
   modify_field( Waseca.Excel, 0 );
   modify_field( Waseca.Blitchton, 0 );
}

action Daguao() {
   modify_field( Goodrich.Pierpont, Maryville );
   modify_field( Fredonia.Hammocks, Thaxton.Mondovi );
   modify_field( Fredonia.Fordyce, Thaxton.Hiwassee );
   modify_field( Fredonia.Washoe, Thaxton.Piqua );
   modify_field( Mabel.Selby, Gilliatt.Scranton );
   modify_field( Mabel.Overton, Gilliatt.Newtok );
   modify_field( Mabel.Annville, Gilliatt.BigPoint );
   modify_field( Mabel.Jigger, Gilliatt.Paicines );
   modify_field( Goodrich.Piketon, Gratis.Bloomdale );
   modify_field( Goodrich.Fiftysix, Gratis.Simla );
   modify_field( Goodrich.Geeville, Gratis.Bovina );
   modify_field( Goodrich.Hitchland, Gratis.Craig );
   modify_field( Goodrich.Cammal, Gratis.Hartville );
   modify_field( Goodrich.Sanchez, Nucla.Cutten );
   modify_field( Goodrich.Vidal, Nucla.Vidaurri );
   modify_field( Goodrich.Nixon, Nucla.Rawson );
   modify_field( Goodrich.Magma, Nucla.Kiana );
   modify_field( Goodrich.Tappan, Nucla.Carlson );
   modify_field( Goodrich.Tolley, Nucla.Benitez );
   modify_field( Goodrich.RedBay, Nucla.RedLake );
}

table Elmhurst {
   reads {
      Gratis.Bloomdale : exact;
      Gratis.Simla : exact;
      Thaxton.Hiwassee : exact;
      Goodrich.Pierpont : exact;
   }

   actions {
      Brookston;
      Daguao;
   }

   default_action : Daguao();
   size : Glenvil;
}


action Wanamassa() {
   modify_field( Goodrich.Edgemoor, Waseca.Woodfield );
   modify_field( Goodrich.Wenatchee, Waseca.Chatanika);
}

action Konnarock( Persia ) {
   modify_field( Goodrich.Edgemoor, Persia );
   modify_field( Goodrich.Wenatchee, Waseca.Chatanika);
}

action Walnut() {
   modify_field( Goodrich.Edgemoor, Dunnstown[0].Kansas );
   modify_field( Goodrich.Wenatchee, Waseca.Chatanika);
}

table Shorter {
   reads {
      Waseca.Chatanika : ternary;
      Dunnstown[0] : valid;
      Dunnstown[0].Kansas : ternary;
   }

   actions {
      Wanamassa;
      Konnarock;
      Walnut;
   }
   size : Pilottown;
}

action Holladay( Westwego ) {
   modify_field( Goodrich.Wenatchee, Westwego );
}

action Jenifer() {

   modify_field( Goodrich.Bronaugh, 1 );
   modify_field( Saragosa.Valdosta,
                 Donnelly );
}

table Denhoff {
   reads {
      Thaxton.Mondovi : exact;
   }

   actions {
      Holladay;
      Jenifer;
   }
   default_action : Jenifer;
   size : Okaton;
}

action Putnam( Joiner, Talihina, Mendocino, Capitola, Newellton,
                        Moquah, Marquette ) {
   modify_field( Goodrich.Edgemoor, Joiner );
   modify_field( Goodrich.Farragut, Joiner );
   modify_field( Goodrich.Retrop, Marquette );
   Fleetwood(Talihina, Mendocino, Capitola, Newellton,
                        Moquah );
}

action Otisco() {
   modify_field( Goodrich.Hargis, 1 );
}

table Millsboro {
   reads {
      Olyphant.Gobles : exact;
   }

   actions {
      Putnam;
      Otisco;
   }
   size : Corvallis;
}

action Fleetwood(RedHead, Domestic, Mendon, Sargent,
                        Kaweah ) {
   modify_field( Westville.Kiron, RedHead );
   modify_field( Westville.Mariemont, Domestic );
   modify_field( Westville.Lakehills, Mendon );
   modify_field( Westville.Eldred, Sargent );
   modify_field( Westville.Sublett, Kaweah );
}

action Netcong(Clintwood, Fairchild, Hanks, Mantee,
                        Brinklow ) {
   modify_field( Goodrich.Farragut, Waseca.Woodfield );
   modify_field( Goodrich.Retrop, 1 );
   Fleetwood(Clintwood, Fairchild, Hanks, Mantee,
                        Brinklow );
}

action Urbanette(Mattapex, Elsinore, Myrick, Whitakers,
                        Friend, Harmony ) {
   modify_field( Goodrich.Farragut, Mattapex );
   modify_field( Goodrich.Retrop, 1 );
   Fleetwood(Elsinore, Myrick, Whitakers, Friend,
                        Harmony );
}

action Lambrook(Sharptown, Pickett, TenSleep, Larsen,
                        Sawmills ) {
   modify_field( Goodrich.Farragut, Dunnstown[0].Kansas );
   modify_field( Goodrich.Retrop, 1 );
   Fleetwood(Sharptown, Pickett, TenSleep, Larsen,
                        Sawmills );
}

table Pimento {
   reads {
      Waseca.Woodfield : exact;
   }


   actions {
      Norland;
      Netcong;
   }

   size : Kentwood;
}

@pragma action_default_only Norland
table Garcia {
   reads {
      Waseca.Chatanika : exact;
      Dunnstown[0].Kansas : exact;
   }

   actions {
      Urbanette;
      Norland;
   }

   size : Sandstone;
}

table McCaulley {
   reads {
      Dunnstown[0].Kansas : exact;
   }


   actions {
      Norland;
      Lambrook;
   }

   size : Vallejo;
}

control Juneau {
   apply( Elmhurst ) {
         Brookston {
            apply( Denhoff );
            apply( Millsboro );
         }
         Daguao {
            if ( Waseca.Sahuarita == 1 ) {
               apply( Shorter );
            }
            if ( valid( Dunnstown[ 0 ] ) ) {

               apply( Garcia ) {
                  Norland {

                     apply( McCaulley );
                  }
               }
            } else {

               apply( Pimento );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Lucien {
    width  : 1;
    static : Cuprum;
    instance_count : 262144;
}

register Midas {
    width  : 1;
    static : Rainelle;
    instance_count : 262144;
}

blackbox stateful_alu Sisters {
    reg : Lucien;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Rockleigh.Fackler;
}

blackbox stateful_alu Salamatof {
    reg : Midas;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Rockleigh.Yreka;
}

field_list TonkaBay {
    Waseca.Castolon;
    Dunnstown[0].Kansas;
}

field_list_calculation Luttrell {
    input { TonkaBay; }
    algorithm: identity;
    output_width: 18;
}

action Billings() {
    Sisters.execute_stateful_alu_from_hash(Luttrell);
}

action Spenard() {
    Salamatof.execute_stateful_alu_from_hash(Luttrell);
}

table Cuprum {
    actions {
      Billings;
    }
    default_action : Billings;
    size : 1;
}

table Rainelle {
    actions {
      Spenard;
    }
    default_action : Spenard;
    size : 1;
}
#endif

action Waring(Markville) {
    modify_field(Rockleigh.Yreka, Markville);
}

@pragma  use_hash_action 0
table Edler {
    reads {
       Waseca.Castolon : exact;
    }
    actions {
      Waring;
    }
    size : 64;
}

action Brothers() {
   modify_field( Goodrich.Ribera, Waseca.Woodfield );
   modify_field( Goodrich.Napanoch, 0 );
}

table Hilburn {
   actions {
      Brothers;
   }
   size : 1;
}

action Heflin() {
   modify_field( Goodrich.Ribera, Dunnstown[0].Kansas );
   modify_field( Goodrich.Napanoch, 1 );
}

table Caplis {
   actions {
      Heflin;
   }
   size : 1;
}

control Chunchula {
   if ( valid( Dunnstown[ 0 ] ) ) {
      apply( Caplis );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Waseca.Bells == 1 ) {
         apply( Cuprum );
         apply( Rainelle );
      }
#endif
   } else {
      apply( Hilburn );
      if( Waseca.Bells == 1 ) {
         apply( Edler );
      }
   }
}




field_list Riner {
   Gratis.Bloomdale;
   Gratis.Simla;
   Gratis.Bovina;
   Gratis.Craig;
   Gratis.Hartville;
}

field_list Litroe {

   Thaxton.Renville;
   Thaxton.Mondovi;
   Thaxton.Hiwassee;
}

field_list Biddle {
   Gilliatt.Scranton;
   Gilliatt.Newtok;
   Gilliatt.BigPoint;
   Gilliatt.Faulkner;
}

field_list Barber {
   Thaxton.Mondovi;
   Thaxton.Hiwassee;
   Edmondson.Hector;
   Edmondson.Shubert;
}





field_list_calculation Silica {
    input {
        Riner;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Naylor {
    input {
        Litroe;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Grubbs {
    input {
        Biddle;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Coalgate {
    input {
        Barber;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Seguin() {
    modify_field_with_hash_based_offset(Champlin.Blairsden, 0,
                                        Silica, 4294967296);
}

action Sonoita() {
    modify_field_with_hash_based_offset(Champlin.Aiken, 0,
                                        Naylor, 4294967296);
}

action Garibaldi() {
    modify_field_with_hash_based_offset(Champlin.Aiken, 0,
                                        Grubbs, 4294967296);
}

action Yetter() {
    modify_field_with_hash_based_offset(Champlin.Odell, 0,
                                        Coalgate, 4294967296);
}

table Livonia {
   actions {
      Seguin;
   }
   size: 1;
}

control Estrella {
   apply(Livonia);
}

table Dandridge {
   actions {
      Sonoita;
   }
   size: 1;
}

table Freedom {
   actions {
      Garibaldi;
   }
   size: 1;
}

control Naubinway {
   if ( valid( Thaxton ) ) {
      apply(Dandridge);
   } else {
      if ( valid( Gilliatt ) ) {
         apply(Freedom);
      }
   }
}

table Dunmore {
   actions {
      Yetter;
   }
   size: 1;
}

control Annandale {
   if ( valid( Edmondson ) ) {
      apply(Dunmore);
   }
}



action Cecilton() {
    modify_field(Ancho.Aberfoil, Champlin.Blairsden);
}

action Waterfall() {
    modify_field(Ancho.Aberfoil, Champlin.Aiken);
}

action Ghent() {
    modify_field(Ancho.Aberfoil, Champlin.Odell);
}

@pragma action_default_only Norland
@pragma immediate 0
table Newfane {
   reads {
      Masardis.valid : ternary;
      Florala.valid : ternary;
      Fonda.valid : ternary;
      Cruso.valid : ternary;
      Moxley.valid : ternary;
      NantyGlo.valid : ternary;
      Edmondson.valid : ternary;
      Thaxton.valid : ternary;
      Gilliatt.valid : ternary;
      Gratis.valid : ternary;
   }
   actions {
      Cecilton;
      Waterfall;
      Ghent;
      Norland;
   }
   size: Covert;
}

action Morstein() {
    modify_field(Ancho.Maytown, Champlin.Odell);
}

@pragma immediate 0
table Ashburn {
   reads {
      Masardis.valid : ternary;
      Florala.valid : ternary;
      NantyGlo.valid : ternary;
      Edmondson.valid : ternary;
   }
   actions {
      Morstein;
      Norland;
   }
   size: McIntosh;
}

control Elkader {
   apply(Ashburn);
   apply(Newfane);
}



counter Maltby {
   type : packets_and_bytes;
   direct : Ridgetop;
   min_width: 16;
}

table Ridgetop {
   reads {
      Waseca.Castolon : exact;
      Rockleigh.Yreka : ternary;
      Rockleigh.Fackler : ternary;
      Goodrich.Hargis : ternary;
      Goodrich.Harshaw : ternary;
      Goodrich.Norias : ternary;
   }

   actions {
      McLaurin;
      Norland;
   }
   default_action : Norland();
   size : Cidra;
}

action Grigston() {

   modify_field(Goodrich.Bannack, 1 );
   modify_field(Saragosa.Valdosta,
                Ignacio);
}







table Vandling {
   reads {
      Goodrich.Geeville : exact;
      Goodrich.Hitchland : exact;
      Goodrich.Edgemoor : exact;
      Goodrich.Wenatchee : exact;
   }

   actions {
      Captiva;
      Grigston;
   }
   default_action : Grigston();
   size : Frankston;
   support_timeout : true;
}

action Grandy() {
   modify_field( Westville.Saticoy, 1 );
}

table Paulette {
   reads {
      Goodrich.Farragut : ternary;
      Goodrich.Piketon : exact;
      Goodrich.Fiftysix : exact;
   }
   actions {
      Grandy;
   }
   size: Menomonie;
}

control Lamona {
   apply( Ridgetop ) {
      Norland {



         if (Waseca.Terrytown == 0 and Goodrich.Bronaugh == 0) {
            apply( Vandling );
         }
         apply(Paulette);
      }
   }
}

field_list Foristell {
    Saragosa.Valdosta;
    Goodrich.Geeville;
    Goodrich.Hitchland;
    Goodrich.Edgemoor;
    Goodrich.Wenatchee;
}

action Sewaren() {
   generate_digest(Overbrook, Foristell);
}

table Merced {
   actions {
      Sewaren;
   }
   size : 1;
}

control Ethete {
   if (Goodrich.Bannack == 1) {
      apply( Merced );
   }
}



action BealCity( Kalskag, Wenona ) {
   modify_field( Mabel.Suffolk, Kalskag );
   modify_field( Sudden.VanZandt, Wenona );
}

@pragma action_default_only Tarlton
table Floris {
   reads {
      Westville.Kiron : exact;
      Mabel.Overton mask Sanford : lpm;
   }
   actions {
      BealCity;
      Tarlton;
   }
   size : Lattimore;
}

@pragma atcam_partition_index Mabel.Suffolk
@pragma atcam_number_partitions Lattimore
table Lakota {
   reads {
      Mabel.Suffolk : exact;
      Mabel.Overton mask Westwood : lpm;
   }

   actions {
      Higbee;
      Thayne;
      Norland;
   }
   default_action : Norland();
   size : Monee;
}

action Roberta( Essington, Cowden ) {
   modify_field( Mabel.Sharon, Essington );
   modify_field( Sudden.VanZandt, Cowden );
}

@pragma action_default_only Norland
table WhiteOwl {


   reads {
      Westville.Kiron : exact;
      Mabel.Overton : lpm;
   }

   actions {
      Roberta;
      Norland;
   }

   size : Tinaja;
}

@pragma atcam_partition_index Mabel.Sharon
@pragma atcam_number_partitions Tinaja
table Gardena {
   reads {
      Mabel.Sharon : exact;


      Mabel.Overton mask Shoreview : lpm;
   }
   actions {
      Higbee;
      Thayne;
      Norland;
   }

   default_action : Norland();
   size : Wakenda;
}

@pragma action_default_only Tarlton
@pragma idletime_precision 1
table Adamstown {

   reads {
      Westville.Kiron : exact;
      Fredonia.Fordyce : lpm;
   }

   actions {
      Higbee;
      Thayne;
      Tarlton;
   }

   size : McFaddin;
   support_timeout : true;
}

action Roseville( Freeville, Pacifica ) {
   modify_field( Fredonia.Mossville, Freeville );
   modify_field( Sudden.VanZandt, Pacifica );
}

@pragma action_default_only Norland
#ifdef PROFILE_DEFAULT
@pragma stage 2 Odessa
@pragma stage 3
#endif
table Coronado {
   reads {
      Westville.Kiron : exact;
      Fredonia.Fordyce : lpm;
   }

   actions {
      Roseville;
      Norland;
   }

   size : Saxonburg;
}

@pragma ways Brundage
@pragma atcam_partition_index Fredonia.Mossville
@pragma atcam_number_partitions Saxonburg
table Lenoir {
   reads {
      Fredonia.Mossville : exact;
      Fredonia.Fordyce mask Belmont : lpm;
   }
   actions {
      Higbee;
      Thayne;
      Norland;
   }
   default_action : Norland();
   size : Bozar;
}

action Higbee( Edroy ) {
   modify_field( Sudden.VanZandt, Edroy );
}

@pragma idletime_precision 1
table Powhatan {
   reads {
      Westville.Kiron : exact;
      Fredonia.Fordyce : exact;
   }

   actions {
      Higbee;
      Thayne;
      Norland;
   }
   default_action : Norland();
   size : Ruthsburg;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
@pragma stage 2 Seattle
@pragma stage 3
#endif
table Topawa {
   reads {
      Westville.Kiron : exact;
      Mabel.Overton : exact;
   }

   actions {
      Higbee;
      Thayne;
      Norland;
   }
   default_action : Norland();
   size : Ouachita;
   support_timeout : true;
}

action Merit(Peoria, Tunis, Astor) {
   modify_field(Cusseta.Hollyhill, Astor);
   modify_field(Cusseta.Pearland, Peoria);
   modify_field(Cusseta.Rippon, Tunis);
   modify_field(Cusseta.FairOaks, 1);
}

action Sasakwa() {
   McLaurin();
}

action PawCreek(Colmar) {
   modify_field(Cusseta.Ludden, 1);
   modify_field(Cusseta.Ionia, Colmar);
}

action Tarlton() {
   modify_field( Cusseta.Ludden, 1 );
   modify_field( Cusseta.Ionia, 9 );
}

table Mystic {
   reads {
      Sudden.VanZandt : exact;
   }

   actions {
      Merit;
      Sasakwa;
      PawCreek;
   }
   size : Decorah;
}

control PortVue {
   if ( Goodrich.Rockaway == 0 and Westville.Saticoy == 1 ) {
      if ( ( Westville.Mariemont == 1 ) and ( Goodrich.Magma == 1 ) ) {
         apply( Powhatan ) {
            Norland {
               apply( Coronado ) {
                  Roseville {
                     apply( Lenoir );
                  }
                  Norland {
                     apply( Adamstown );
                  }
               }
            }
         }
      } else if ( ( Westville.Lakehills == 1 ) and ( Goodrich.Tappan == 1 ) ) {
         apply( Topawa ) {
            Norland {
               apply( WhiteOwl ) {
                  Roberta {
                     apply( Gardena );
                  }
                  Norland {

                     apply( Floris ) {
                        BealCity {
                           apply( Lakota );
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Hernandez {
   if( Sudden.VanZandt != 0 ) {
      apply( Mystic );
   }
}

action Thayne( Luverne ) {
   modify_field( Sudden.Choudrant, Luverne );
}

field_list Sheyenne {
   Ancho.Maytown;
}

field_list_calculation Tillatoba {
    input {
        Sheyenne;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Matador {
   selection_key : Tillatoba;
   selection_mode : resilient;
}

action_profile DeepGap {
   actions {
      Higbee;
   }
   size : Anandale;
   dynamic_action_selection : Matador;
}

table KingCity {
   reads {
      Sudden.Choudrant : exact;
   }
   action_profile : DeepGap;
   size : Isleta;
}

control Oskaloosa {
   if ( Sudden.Choudrant != 0 ) {
      apply( KingCity );
   }
}



field_list Bleecker {
   Ancho.Aberfoil;
}

field_list_calculation Supai {
    input {
        Bleecker;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Pierre {
    selection_key : Supai;
    selection_mode : resilient;
}

action Steger(Monowi) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Monowi);
}

action_profile Pensaukee {
    actions {
        Steger;
        Norland;
    }
    size : Bethesda;
    dynamic_action_selection : Pierre;
}

table Nichols {
   reads {
      Cusseta.Gassoway : exact;
   }
   action_profile: Pensaukee;
   size : Wilsey;
}

control Wyanet {
   if ((Cusseta.Gassoway & 0x2000) == 0x2000) {
      apply(Nichols);
   }
}



action Chugwater() {
   modify_field(Cusseta.Pearland, Goodrich.Piketon);
   modify_field(Cusseta.Rippon, Goodrich.Fiftysix);
   modify_field(Cusseta.Joshua, Goodrich.Geeville);
   modify_field(Cusseta.Suamico, Goodrich.Hitchland);
   modify_field(Cusseta.Hollyhill, Goodrich.Edgemoor);
}

table Alburnett {
   actions {
      Chugwater;
   }
   default_action : Chugwater();
   size : 1;
}

control Hematite {
   if (Goodrich.Edgemoor!=0) {
      apply( Alburnett );
   }
}

action Minneota() {
   modify_field(Cusseta.Toccopola, 1);
   modify_field(Cusseta.WestEnd, 1);
   modify_field(Cusseta.Benson, Cusseta.Hollyhill);
}

action Nunda() {
}



@pragma ways 1
table Boquillas {
   reads {
      Cusseta.Pearland : exact;
      Cusseta.Rippon : exact;
   }
   actions {
      Minneota;
      Nunda;
   }
   default_action : Nunda;
   size : 1;
}

action Harriet() {
   modify_field(Cusseta.Mancelona, 1);
   modify_field(Cusseta.Pownal, 1);
   add(Cusseta.Benson, Cusseta.Hollyhill, Mumford);
}

table Saltair {
   actions {
      Harriet;
   }
   default_action : Harriet;
   size : 1;
}

action Aquilla() {
   modify_field(Cusseta.Kranzburg, 1);
   modify_field(Cusseta.Benson, Cusseta.Hollyhill);
}

table Strevell {
   actions {
      Aquilla;
   }
   default_action : Aquilla();
   size : 1;
}

action Shanghai(Rhinebeck) {
   modify_field(Cusseta.Champlain, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Rhinebeck);
   modify_field(Cusseta.Gassoway, Rhinebeck);
}

action Escatawpa(Baxter) {
   modify_field(Cusseta.Mancelona, 1);
   modify_field(Cusseta.Benson, Baxter);
}

action Tagus() {
}

table Bagwell {
   reads {
      Cusseta.Pearland : exact;
      Cusseta.Rippon : exact;
      Cusseta.Hollyhill : exact;
   }

   actions {
      Shanghai;
      Escatawpa;
      Tagus;
   }
   default_action : Tagus();
   size : Crouch;
}

control Ringtown {
   if (Goodrich.Rockaway == 0) {
      apply(Bagwell) {
         Tagus {
            apply(Boquillas) {
               Nunda {
                  if ((Cusseta.Pearland & 0x010000) == 0x010000) {
                     apply(Saltair);
                  } else {
                     apply(Strevell);
                  }
               }
            }
         }
      }
   }
}

action Parrish() {
   modify_field(Goodrich.Yorkville, 1);
   McLaurin();
}

@pragma stage 10
table Diomede {
   actions {
      Parrish;
   }
   default_action : Parrish;
   size : 1;
}

control Onarga {
   if (Goodrich.Rockaway == 0) {
      if ((Cusseta.FairOaks==0) and (Goodrich.Wenatchee==Cusseta.Gassoway)) {
         apply(Diomede);
      } else {
         Trout();
      }
   }
}



action Saluda( Luhrig ) {
   modify_field( Cusseta.ElRio, Luhrig );
}

action Campo() {
   modify_field( Cusseta.ElRio, Cusseta.Hollyhill );
}

table Fouke {
   reads {
      eg_intr_md.egress_port : exact;
      Cusseta.Hollyhill : exact;
   }

   actions {
      Saluda;
      Campo;
   }
   default_action : Campo;
   size : Lyncourt;
}

control Horsehead {
   apply( Fouke );
}



action Mayflower( Baudette, Grainola ) {
   modify_field( Cusseta.Eddington, Baudette );
   modify_field( Cusseta.Standard, Grainola );
}

action Absarokee( Verdigris, Renick, Lindsborg, Moreland ) {
   modify_field( Cusseta.Eddington, Verdigris );
   modify_field( Cusseta.Standard, Renick );
   modify_field( Cusseta.Grampian, Lindsborg );
   modify_field( Cusseta.Rocklake, Moreland );
}


table Oakton {
   reads {
      Cusseta.Oklahoma : exact;
   }

   actions {
      Mayflower;
      Absarokee;
   }
   size : Franklin;
}

action Newburgh(SweetAir, WestCity, Rockham, Henderson) {
   modify_field( Cusseta.Neame, SweetAir );
   modify_field( Cusseta.Castine, WestCity );
   modify_field( Cusseta.Bairoil, Rockham );
   modify_field( Cusseta.Malaga, Henderson );
}

table Chalco {
   reads {
        Cusseta.Lumberton : exact;
   }
   actions {
      Newburgh;
   }
   size : Duchesne;
}

action Stateline() {
   no_op();
}

action Bettles() {
   modify_field( Gratis.Hartville, Dunnstown[0].Ossipee );
   remove_header( Dunnstown[0] );
}

table Conejo {
   actions {
      Bettles;
   }
   default_action : Bettles;
   size : Rhodell;
}

action Kaupo() {
   no_op();
}

action White() {
   add_header( Dunnstown[ 0 ] );
   modify_field( Dunnstown[0].Kansas, Cusseta.ElRio );
   modify_field( Dunnstown[0].Ossipee, Gratis.Hartville );
   modify_field( Gratis.Hartville, Remington );
}



table Ketchum {
   reads {
      Cusseta.ElRio : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Kaupo;
      White;
   }
   default_action : White;
   size : Eskridge;
}

action Elkton() {
   modify_field(Gratis.Bloomdale, Cusseta.Pearland);
   modify_field(Gratis.Simla, Cusseta.Rippon);
   modify_field(Gratis.Bovina, Cusseta.Eddington);
   modify_field(Gratis.Craig, Cusseta.Standard);
}

action Maybell() {
   Elkton();
   add_to_field(Thaxton.Flaherty, -1);
}

action Varna() {
   Elkton();
   add_to_field(Gilliatt.Chardon, -1);
}

action Wyman() {
   White();
}

action Adelino() {
   add_header( Ayden );
   modify_field( Ayden.Bloomdale, Cusseta.Eddington );
   modify_field( Ayden.Simla, Cusseta.Standard );
   modify_field( Ayden.Bovina, Cusseta.Grampian );
   modify_field( Ayden.Craig, Cusseta.Rocklake );
   modify_field( Ayden.Hartville, Wapato );
   add_header( Davie );
   modify_field( Davie.Raynham, Cusseta.Neame );
   modify_field( Davie.Valeene, Cusseta.Castine );
   modify_field( Davie.Almond, Cusseta.Bairoil );
   modify_field( Davie.Woodburn, Cusseta.Malaga );
   modify_field( Davie.Jones, Cusseta.Ionia );
}

table Dunken {
   reads {
      Cusseta.Grinnell : exact;
      Cusseta.Oklahoma : exact;
      Cusseta.FairOaks : exact;
      Thaxton.valid : ternary;
      Gilliatt.valid : ternary;
   }

   actions {
      Maybell;
      Varna;
      Wyman;
      Adelino;

   }
   size : Ossining;
}

control Patchogue {
   apply( Conejo );
}

control Ironia {
   apply( Ketchum );
}

control Neponset {
   apply( Oakton );
   apply( Chalco );
   apply( Dunken );
}



field_list Tonasket {
    Saragosa.Valdosta;
    Goodrich.Edgemoor;
    Moxley.Bovina;
    Moxley.Craig;
    Thaxton.Mondovi;
}

action Myton() {
   generate_digest(Overbrook, Tonasket);
}

table Farthing {
   actions {
      Myton;
   }

   default_action : Myton;
   size : 1;
}

control Thalmann {
   if (Goodrich.Bronaugh == 1) {
      apply(Farthing);
   }
}



action Badger( ElCentro ) {
   modify_field( Romero.Armstrong, ElCentro );
}

action Shoshone() {
   modify_field( Romero.Armstrong, 0 );
}

@pragma stage 9
table Pelican {
   reads {
     Goodrich.Wenatchee : ternary;
     Goodrich.Farragut : ternary;
     Westville.Saticoy : ternary;
   }

   actions {
     Badger;
     Shoshone;
   }

   default_action : Shoshone();
   size : Calimesa;
}

action Buncombe( Pachuta ) {
   modify_field( Romero.Sabula, Pachuta );
   modify_field( Romero.DeWitt, 0 );
   modify_field( Romero.WestLawn, 0 );
}

action Brackett( Joaquin, Swain ) {
   modify_field( Romero.Sabula, 0 );
   modify_field( Romero.DeWitt, Joaquin );
   modify_field( Romero.WestLawn, Swain );
}

action Hanahan( Paxtonia, Stilson, Kekoskee ) {
   modify_field( Romero.Sabula, Paxtonia );
   modify_field( Romero.DeWitt, Stilson );
   modify_field( Romero.WestLawn, Kekoskee );
}

action Charlotte() {
   modify_field( Romero.Sabula, 0 );
   modify_field( Romero.DeWitt, 0 );
   modify_field( Romero.WestLawn, 0 );
}

@pragma stage 10
table Lenox {
   reads {
     Romero.Armstrong : exact;
     Goodrich.Piketon : ternary;
     Goodrich.Fiftysix : ternary;
     Goodrich.Cammal : ternary;
   }

   actions {
     Buncombe;
     Brackett;
     Hanahan;
     Charlotte;
   }

   default_action : Charlotte();
   size : GilaBend;
}

@pragma stage 10
table Flats {
   reads {
     Romero.Armstrong : exact;
     Fredonia.Fordyce mask 0xffff0000 : ternary;
     Goodrich.Vidal : ternary;
     Goodrich.Nixon : ternary;
     Goodrich.Gillette : ternary;
     Sudden.VanZandt : ternary;

   }

   actions {
     Buncombe;
     Brackett;
     Hanahan;
     Charlotte;
   }

   default_action : Charlotte();
   size : Stovall;
}

@pragma stage 10
table Elmsford {
   reads {
     Romero.Armstrong : exact;
     Mabel.Overton mask 0xffff0000 : ternary;
     Goodrich.Vidal : ternary;
     Goodrich.Nixon : ternary;
     Goodrich.Gillette : ternary;
     Sudden.VanZandt : ternary;

   }

   actions {
     Buncombe;
     Brackett;
     Hanahan;
     Charlotte;
   }

   default_action : Charlotte();
   size : Sarepta;
}

meter Dundee {
   type : packets;
   static : Eldena;
   instance_count: Wimbledon;
}

action Parmele( LaPryor ) {
   // Unsupported address mode
   //execute_meter( Dundee, LaPryor, ig_intr_md_for_tm.packet_color );
}

action Affton() {
   execute_meter( Dundee, Romero.DeWitt, ig_intr_md_for_tm.packet_color );
}

@pragma stage 11
table Eldena {
   reads {
     Romero.DeWitt : ternary;
     Goodrich.Wenatchee : ternary;
     Goodrich.Farragut : ternary;
     Westville.Saticoy : ternary;
     Romero.WestLawn : ternary;
   }
   actions {
      Parmele;
      Affton;
   }
   size : Throop;
}

control Portal {
   apply( Pelican );
}

control Trout {
   if ( Goodrich.Magma == 1 ) {
      apply( Flats );
   } else if ( Goodrich.Tappan == 1 ) {
      apply( Elmsford );
   } else {
      apply( Lenox );
   }
}

control Lapoint {
   apply( Eldena );
}



action Breda() {
   modify_field( Goodrich.Tolley, Waseca.Excel );
}

action Panola() {
   modify_field( Goodrich.Gillette, Waseca.Blitchton );
}

action Grottoes() {
   modify_field( Goodrich.Gillette, Fredonia.Washoe );
}

action Bartolo() {
   modify_field( Goodrich.Gillette, Mabel.Jigger );
}

action BirchBay( Southam, Tamaqua ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Southam );
   modify_field( ig_intr_md_for_tm.qid, Tamaqua );
}

table Nathalie {
   reads {
     Goodrich.RedBay : exact;
   }

   actions {
     Breda;
   }

   size : Goosport;
}

table Ramos {
   reads {
     Goodrich.Magma : exact;
     Goodrich.Tappan : exact;
   }

   actions {
     Panola;
     Grottoes;
     Bartolo;
   }

   size : Cathcart;
}

@pragma stage 11
table BigArm {
   reads {
      Waseca.Pearcy : ternary;
      Waseca.Excel : ternary;
      Goodrich.Tolley : ternary;
      Goodrich.Gillette : ternary;
      Romero.Sabula : ternary;
   }

   actions {
      BirchBay;
   }

   size : Pittsburg;
}

control Waxhaw {
   apply( Nathalie );
   apply( Ramos );
}

control Naguabo {
   apply( BigArm );
}




#define Quebrada            0
#define Chatmoss  1
#define Woodrow 2


#define Rocklin           0




action Neuse( Emsworth ) {
   modify_field( Cusseta.Oklahoma, Chatmoss );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Emsworth );
   modify_field(Cusseta.Gassoway, Emsworth );
}

action Newport( Cascade ) {
   modify_field( Cusseta.Oklahoma, Woodrow );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Cascade );
   modify_field(Cusseta.Gassoway, Cascade );
   modify_field( Cusseta.Lumberton, ig_intr_md.ingress_port );
}

table Yakutat {
   reads {
      Westville.Saticoy : exact;
      Waseca.Sahuarita : ternary;
      Cusseta.Ionia : ternary;
   }

   actions {
      Neuse;
      Newport;
   }

   size : Counce;
}

control Burgess {
   apply( Yakutat );
}


control ingress {

   Cataract();


   Grassflat();
   Juneau();
   Chunchula();


   Waxhaw();
   Lamona();
   Estrella();


   Naubinway();
   Annandale();


   PortVue();


   Elkader();


   Oskaloosa();
   Hematite();


   Hernandez();




   if( Cusseta.Ludden == 0 ) {
      Ringtown();
   } else {
      Burgess();
   }

   Portal();


   Onarga();


   Naguabo();
   Lapoint();
   Wyanet();
   Thalmann();
   Ethete();


   if( valid( Dunnstown[0] ) ) {
      Patchogue();
   }
}

control egress {
   Horsehead();
   Neponset();

   if( Cusseta.Ludden == 0 ) {
      Ironia();
   }
}

