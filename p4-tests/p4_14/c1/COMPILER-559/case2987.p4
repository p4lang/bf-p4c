// BUILD: p4c-tofino --verbose 0 --placement tp4 --no-dead-code-elimination --o bf_obfuscate_arista_switch_default --p4-name=obfuscate_arista_switch --p4-prefix=p4_obfuscate_arista_switch --pipe-mgr-path=pipe_mgr/ --mc-mgr-path=mc_mgr/ --gen-exm-test-pd -S -DPROFILE_DEFAULT --number-mau-stages 12 Switch.OBFUSCATED.p4


// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 92418







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>



#ifndef Mahomet
#define Mahomet


#define McBrides          0
#define SanPablo   1
#define DeGraff    2
#define Vanzant       3
#define Willmar  4
#define Craig     5
#define FoxChase        6

header_type Topton {
	fields {
		Knippa : 16;
		Seagate : 16;
		Fairland : 8;
		Bigfork : 8;
		Elliston : 8;
		Arroyo : 8;
		Samson : 1;
		Mabelvale : 1;
		Ludell : 1;
		Nordheim : 1;
		DewyRose : 1;
		Macedonia : 1;
		Carnegie : 2;
		SwissAlp : 2;
	}
}

header_type Cahokia {
	fields {
		Snook : 24;
		Blueberry : 24;
		Antonito : 24;
		Chaska : 24;
		Floris : 16;
		Nevis : 16;
		Laramie : 16;
		Dixon : 16;
		Penrose : 16;
		Powderly : 8;
		Trout : 8;
		Micco : 1;
		Kurten : 1;
		Makawao : 12;
		Homeacre : 2;
		Storden : 1;
		Adelino : 1;
		Commack : 1;
		Darmstadt : 1;
		Paulette : 1;
		Realitos : 1;
		Lepanto : 1;
		Clarion : 1;
		Montbrook : 1;
		Corinth : 1;
		Eaton : 1;
		Bangor : 1;
		Occoquan : 1;
		Bernice : 1;
		Redvale : 1;
		Wabuska : 2;
		Basco : 8;
		Champlain : 2;
		Fitler : 10;
		Warba : 10;
	}
}


header_type Rippon {
	fields {
		Kinney : 16;
		Lathrop : 16;
	}
}

header_type Twichell {
	fields {
		Littleton : 24;
		Miltona : 24;
		Pinebluff : 24;
		Levittown : 24;
		Thomas : 24;
		Richvale : 24;
		Excel : 24;
		Odell : 24;
		Charm : 16;
		Lyncourt : 16;
		Glenmora : 16;
		Hilburn : 16;
		Ferrum : 12;
		Salus : 1;
		Lenoir : 3;
		Epsie : 1;
		Sopris : 3;
		Longwood : 1;
		Merkel : 1;
		Sigsbee : 1;
		Timken : 1;
		Lutts : 1;
		LoonLake : 8;
		Gambrills : 12;
		Rehoboth : 4;
		Uhland : 6;
		Perma : 10;
		Elsey : 9;
		Panola : 1;
		Oneonta : 1;
		Grottoes : 1;
		Kenefic : 1;
		Peletier : 1;
		Christina : 16;
		Perkasie : 8;
		Sonoma : 16;
		Killen : 32;
		Weissert : 32;
		Newfield : 8;
		Calverton : 8;
		Romney : 2;
		Gibbstown : 10;
		Goulding : 10;
	}
}

header_type Emigrant {
	fields {
		Flats : 8;
		BallClub : 1;
		Boyero : 1;
		Crary : 1;
		Monmouth : 1;
		LaPuente : 1;
	}
}

header_type Manteo {
	fields {
		UtePark : 32;
		Dixboro : 32;
		Hammonton : 6;
		Hooven : 16;
	}
}

header_type Umkumiut {
	fields {
		Schleswig : 128;
		Lewiston : 128;
		LoneJack : 13;
		Vinings : 11;
		Ashwood : 8;
		Chatom : 20;
		Korona : 6;
	}
}

header_type Flippen {
	fields {
		Euren : 14;
		Hanks : 1;
		Chatcolet : 12;
		Jackpot : 1;
		Westboro : 1;
		Aiken : 6;
		Gladden : 2;
		Newland : 6;
		Stirrat : 3;
	}
}

header_type Badger {
	fields {
		ArchCape : 1;
		Shellman : 1;
	}
}

header_type Currie {
	fields {
		Chackbay : 8;
	}
}

header_type Conger {
	fields {
		Glenshaw : 16;
		Eclectic : 11;
	}
}

header_type Silco {
	fields {
		Rushmore : 32;
		Carlsbad : 32;
		Eustis : 32;
	}
}

header_type Veguita {
	fields {
		Goulds : 32;
		BigWater : 32;
	}
}

header_type Masontown {
	fields {
		Bowlus : 1;
		Yemassee : 1;
		Surrey : 1;
		Grantfork : 3;
		LunaPier : 1;
		Chatanika : 6;
		Lincroft : 1;
	}
}

header_type Onamia {
	fields {
		Coulee : 16;
	}
}

header_type Bellville {
	fields {
		Lakeside : 14;
		Trona : 1;
		Blanding : 1;
	}
}

header_type Chouteau {
	fields {
		Bosler : 14;
		Geismar : 1;
		Russia : 1;
	}
}

#define Lawnside \
   (( standard_metadata.instance_type == SanPablo ) or \
    ( standard_metadata.instance_type == DeGraff ) )

#define Amber \
   ( standard_metadata.instance_type == McBrides )

#endif



#ifndef Millikin
#define Millikin


header_type Emblem {
	fields {
		Campo : 6;
		Horatio : 10;
		Greenland : 4;
		Alden : 12;
		Daphne : 12;
		Millstone : 2;
		Glenvil : 2;
		Sweeny : 8;
		Onava : 3;
		Valmont : 5;
	}
}



header_type PineHill {
	fields {
		Kinard : 24;
		Goodwin : 24;
		Boonsboro : 24;
		Mabana : 24;
		Fishers : 16;
	}
}



header_type Magoun {
	fields {
		Petoskey : 3;
		Homeland : 1;
		Friend : 12;
		Mendota : 16;
	}
}



header_type Jamesburg {
	fields {
		Ottertail : 4;
		Uniontown : 4;
		Laplace : 6;
		Newfane : 2;
		Moclips : 16;
		LaneCity : 16;
		Emerado : 3;
		Tappan : 13;
		Raeford : 8;
		Kupreanof : 8;
		Perdido : 16;
		Graford : 32;
		Lugert : 32;
	}
}

header_type Lecanto {
	fields {
		Tununak : 4;
		Monrovia : 6;
		Endeavor : 2;
		Tocito : 20;
		Kenton : 16;
		MiraLoma : 8;
		Tillson : 8;
		Sahuarita : 128;
		Irondale : 128;
	}
}




header_type Filley {
	fields {
		Verndale : 8;
		Bellmead : 8;
		Baudette : 16;
	}
}

header_type BigWells {
	fields {
		Gorum : 16;
		FairOaks : 16;
	}
}

header_type Robinette {
	fields {
		Franktown : 32;
		Newport : 32;
		Wanatah : 4;
		Biehle : 4;
		Jericho : 8;
		CedarKey : 16;
		Uvalde : 16;
		FulksRun : 16;
	}
}

header_type Brave {
	fields {
		Sparland : 16;
		Burgdorf : 16;
	}
}



header_type Dryden {
	fields {
		Joice : 16;
		Youngwood : 16;
		Rocklake : 8;
		Greer : 8;
		Macungie : 16;
	}
}

header_type Biddle {
	fields {
		Atlantic : 48;
		Colmar : 32;
		McKee : 48;
		Slocum : 32;
	}
}



header_type Woodfords {
	fields {
		Naguabo : 1;
		Gladstone : 1;
		Gracewood : 1;
		Tobique : 1;
		Hillside : 1;
		Missoula : 3;
		Cockrum : 5;
		Clover : 3;
		Maytown : 16;
	}
}

header_type Westel {
	fields {
		Longhurst : 24;
		Valencia : 8;
	}
}



header_type Hartwell {
	fields {
		Muncie : 8;
		Glendevey : 24;
		Hartfield : 24;
		Anandale : 8;
	}
}

#endif



#ifndef Nashua
#define Nashua

#define BlackOak        0x8100
#define LaVale        0x0800
#define Hatfield        0x86dd
#define Edgemoor        0x9100
#define Reynolds        0x8847
#define Redondo         0x0806
#define Robbs        0x8035
#define Hiland        0x88cc
#define Maury        0x8809
#define Lynndyl      0xBF00

#define Brewerton              1
#define Oxnard              2
#define Winnebago              4
#define Padonia               6
#define PineLawn               17
#define Minoa               47

#define Millbrae         0x501
#define Oakmont          0x506
#define Malinta          0x511
#define Paoli          0x52F


#define Slayden                 4789



#define Revere               0
#define Domingo              1
#define Humacao                2



#define WyeMills          0
#define McGrady          4095
#define Braselton  4096
#define Wymer  8191



#define Wataga                      0
#define Valders                  0
#define Fletcher                 1

header PineHill Wauseon;
header PineHill Nucla;
header Magoun Rockfield[ 2 ];



@pragma pa_fragment ingress Sitka.Perdido
@pragma pa_fragment egress Sitka.Perdido
header Jamesburg Sitka;

@pragma pa_fragment ingress Requa.Perdido
@pragma pa_fragment egress Requa.Perdido
header Jamesburg Requa;

header Lecanto Millstadt;
header Lecanto Lundell;
header BigWells Ovilla;
header Robinette Thurmond;

header Brave Rowlett;
header Robinette Leucadia;
header Brave Triplett;
header Hartwell Milam;
header Dryden Torrance;
header Woodfords Yardville;
header Emblem Ellisburg;
header PineHill Coconino;

parser start {
   return select(current(96, 16)) {
      Lynndyl : Millston;
      default : Albany;
   }
}

parser Udall {
   extract( Ellisburg );
   return Albany;
}

parser Millston {
   extract( Coconino );
   return Udall;
}

parser Albany {
   extract( Wauseon );
   return select( Wauseon.Fishers ) {
      BlackOak : Jones;
      LaVale : Germano;
      Hatfield : Palomas;
      Redondo  : Cotter;
      default        : ingress;
   }
}

parser Jones {
   extract( Rockfield[0] );
   set_metadata(Vernal.DewyRose, 1);
   return select( Rockfield[0].Mendota ) {
      LaVale : Germano;
      Hatfield : Palomas;
      Redondo  : Cotter;
      default : ingress;
   }
}

field_list Ruthsburg {
    Sitka.Ottertail;
    Sitka.Uniontown;
    Sitka.Laplace;
    Sitka.Newfane;
    Sitka.Moclips;
    Sitka.LaneCity;
    Sitka.Emerado;
    Sitka.Tappan;
    Sitka.Raeford;
    Sitka.Kupreanof;
    Sitka.Graford;
    Sitka.Lugert;
}

field_list_calculation Shelby {
    input {
        Ruthsburg;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field Sitka.Perdido  {
    verify Shelby;
    update Shelby;
}

parser Germano {
   extract( Sitka );
   set_metadata(Vernal.Fairland, Sitka.Kupreanof);
   set_metadata(Vernal.Elliston, Sitka.Raeford);
   set_metadata(Vernal.Knippa, Sitka.Moclips);
   set_metadata(Vernal.Ludell, 0);
   set_metadata(Vernal.Samson, 1);
   set_metadata(Vernal.SwissAlp, Sitka.Newfane);
   return select(Sitka.Tappan, Sitka.Uniontown, Sitka.Kupreanof) {
      Malinta : Latham;
      Oakmont : Lewistown;
      Paoli : NewRoads;
      default : ingress;
   }
}

parser Palomas {
   extract( Lundell );
   set_metadata(Vernal.Fairland, Lundell.MiraLoma);
   set_metadata(Vernal.Elliston, Lundell.Tillson);
   set_metadata(Vernal.Knippa, Lundell.Kenton);
   set_metadata(Vernal.Ludell, 1);
   set_metadata(Vernal.Samson, 0);
   return select(Lundell.MiraLoma) {
      Malinta : Sandpoint;
      Oakmont : Lewistown;
      Paoli : NewRoads;
      default : ingress;
   }
}

parser Cotter {
   extract( Torrance );
   set_metadata(Vernal.Macedonia, 1);
   return ingress;
}

parser Latham {
   extract(Ovilla);
   extract(Rowlett);
   return select(Ovilla.FairOaks) {
      Slayden : Criner;
      default : ingress;
    }
}

parser Sandpoint {
   extract(Ovilla);
   extract(Rowlett);
   return ingress;
}

parser Lewistown {
   extract(Ovilla);
   extract(Thurmond);
   return ingress;
}

parser BealCity {
   set_metadata(Pearson.Homeacre, Humacao);
   return Glazier;
}

parser August {
   set_metadata(Pearson.Homeacre, Humacao);
   return HornLake;
}

parser NewRoads {
   extract(Yardville);
   return select(Yardville.Naguabo, Yardville.Gladstone, Yardville.Gracewood, Yardville.Tobique, Yardville.Hillside,
             Yardville.Missoula, Yardville.Cockrum, Yardville.Clover, Yardville.Maytown) {
      LaVale : BealCity;
      Hatfield : August;
      default : ingress;
   }
}

parser Criner {
   extract(Milam);
   set_metadata(Pearson.Homeacre, Domingo);
   return Ronda;
}

field_list Gilliatt {
    Requa.Ottertail;
    Requa.Uniontown;
    Requa.Laplace;
    Requa.Newfane;
    Requa.Moclips;
    Requa.LaneCity;
    Requa.Emerado;
    Requa.Tappan;
    Requa.Raeford;
    Requa.Kupreanof;
    Requa.Graford;
    Requa.Lugert;
}

field_list_calculation Weatherby {
    input {
        Gilliatt;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field Requa.Perdido  {
    verify Weatherby;
    update Weatherby;
}

parser Glazier {
   extract( Requa );
   set_metadata(Vernal.Bigfork, Requa.Kupreanof);
   set_metadata(Vernal.Arroyo, Requa.Raeford);
   set_metadata(Vernal.Carnegie, Requa.Newfane);
   set_metadata(Vernal.Seagate, Requa.Moclips);
   set_metadata(Vernal.Nordheim, 0);
   set_metadata(Vernal.Mabelvale, 1);
   return ingress;
}

parser HornLake {
   extract( Millstadt );
   set_metadata(Vernal.Bigfork, Millstadt.MiraLoma);
   set_metadata(Vernal.Arroyo, Millstadt.Tillson);
   set_metadata(Vernal.Seagate, Millstadt.Kenton);
   set_metadata(Vernal.Nordheim, 1);
   set_metadata(Vernal.Mabelvale, 0);
   return ingress;
}

parser Ronda {
   extract( Nucla );
   return select( Nucla.Fishers ) {
      LaVale: Glazier;
      Hatfield: HornLake;
      default: ingress;
   }
}
#endif

metadata Cahokia Pearson;

@pragma pa_no_init ingress Portal.Littleton
@pragma pa_no_init ingress Portal.Miltona
@pragma pa_no_init ingress Portal.Pinebluff
@pragma pa_no_init ingress Portal.Levittown
metadata Twichell Portal;

metadata Rippon Bucktown;

metadata Flippen Mentone;
metadata Topton Vernal;
metadata Manteo WindLake;
metadata Umkumiut OldGlory;
metadata Badger DuQuoin;
metadata Emigrant Tornillo;
metadata Currie Challis;
metadata Conger Gregory;
metadata Veguita Mackville;
metadata Silco Gifford;
metadata Masontown Kekoskee;

metadata Onamia Kingsland;
metadata Bellville Brothers;
metadata Chouteau Cuthbert;













#undef Crossett
#undef Novinger
#undef Larue
#undef Palatka
#undef Cannelton

#undef DonaAna

#undef Lilbert
#undef Brazil
#undef Nisland
#undef Munich
#undef FifeLake
#undef Hammett
#undef Evansburg

#undef Dixfield
#undef Belview
#undef Herod

#undef Goodlett
#undef Wymore
#undef Bergoo
#undef Gorman
#undef Charenton
#undef Strasburg
#undef Gheen
#undef Maltby
#undef Roxobel
#undef Mabank
#undef Moody
#undef Townville
#undef Allgood
#undef Medart
#undef Saugatuck
#undef Rockleigh
#undef Metzger
#undef Blencoe
#undef BlueAsh
#undef Purves
#undef Minburn

#undef Shidler
#undef Oakley
#undef Shabbona
#undef Satolah
#undef Alburnett
#undef Trooper
#undef Cashmere
#undef Elvaston
#undef Lurton
#undef Quitman
#undef Weyauwega
#undef Natalia
#undef Ketchum
#undef Seabrook
#undef Cross
#undef Lebanon
#undef Saragosa
#undef Lantana
#undef Halfa
#undef Crannell

#undef Ledoux
#undef Willows

#undef Friday

#undef Soldotna
#undef Lapeer

#undef Converse
#undef Walnut
#undef Simnasho
#undef Bonney
#undef Delavan

#undef Berrydale
#undef Amsterdam
#undef Oconee
#undef Claunch
#undef BeeCave
#undef Staunton

#undef Wyatte
#undef Sabina
#undef Platea

#undef Okaton






#define DonaAna 288


#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Crossett

#define Novinger

#define Larue

#define Palatka

#define Cannelton



#define Lilbert      65536
#define Brazil      65536
#define Nisland      4096
#define Munich 1024
#define FifeLake 512
#define Hammett      512
#define Evansburg 4096


#define Dixfield     1024
#define Belview    1024
#define Herod     256


#define Goodlett 512
#define Wymore 65536
#define Bergoo 65536
#define Gorman 28672
#define Charenton   16384
#define Strasburg 8192
#define Gheen         131072
#define Maltby 65536
#define Roxobel 1024
#define Mabank 2048
#define Moody 16384
#define Townville 8192
#define Allgood 65536

#define Medart 0x0000000000000000FFFFFFFFFFFFFFFF


#define Saugatuck 0x000fffff
#define Blencoe 2

#define Rockleigh 0xFFFFFFFFFFFFFFFF0000000000000000

#define Metzger 0x000007FFFFFFFFFF0000000000000000
#define BlueAsh  6
#define Minburn        2048
#define Purves       65536


#define Shidler 1024
#define Oakley 4096
#define Shabbona 4096
#define Satolah 4096
#define Alburnett 4096
#define Trooper 1024
#define Cashmere 4096
#define Lurton 128
#define Quitman 1
#define Weyauwega  8


#define Natalia 512
#define Ledoux 512
#define Willows 256


#define Ketchum 2
#define Seabrook 3
#define Cross 81



#define Lebanon 2048
#define Saragosa 2048
#define Lantana 512

#define Halfa 1
#define Crannell 512



#define Friday 0


#define Soldotna    4096
#define Lapeer    1024


#define Converse    16384
#define Walnut   16384
#define Simnasho            16384

#define Bonney                    57344
#define Delavan         511


#define Berrydale 128
#define Amsterdam  2048
#define Oconee 2
#define Claunch 256
#define Staunton    512


#define Wyatte  1024
#define Sabina  1024
#define Platea 1024


#define Okaton 4096

#endif



#ifndef Lacona
#define Lacona

action Monteview() {
   no_op();
}

action Hecker() {
   modify_field(Pearson.Darmstadt, 1 );
   mark_for_drop();
}

action Whiteclay() {
   no_op();
}
#endif




#define Cuprum         0
#define Raytown        1


#define Jelloway            0
#define Nenana  1
#define Jenera 2
#define Eggleston             3


#define Madison              0
#define Wakefield             1
#define Wrenshall 2


















action Remington(Emajagua, Hearne, Lansdowne, Between, Placid, Cowley,
                 SoapLake, Lushton, Lambert) {
    modify_field(Mentone.Euren, Emajagua);
    modify_field(Mentone.Hanks, Hearne);
    modify_field(Mentone.Chatcolet, Lansdowne);
    modify_field(Mentone.Jackpot, Between);
    modify_field(Mentone.Westboro, Placid);
    modify_field(Mentone.Aiken, Cowley);
    modify_field(Mentone.Gladden, SoapLake);
    modify_field(Mentone.Stirrat, Lushton);
    modify_field(Mentone.Newland, Lambert);
}

@pragma command_line --no-dead-code-elimination
@pragma command_line --metadata-overlay False
table Sonora {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Remington;
    }
    size : DonaAna;
}

control Flomaton {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Sonora);
    }
}





action Suwannee(Newborn, Barney) {
   modify_field( Portal.Epsie, 1 );
   modify_field( Portal.LoonLake, Newborn);
   modify_field( Pearson.Corinth, 1 );
   modify_field( Kekoskee.Surrey, Barney );
}

action Wamego() {
   modify_field( Pearson.Lepanto, 1 );
   modify_field( Pearson.Bangor, 1 );
}

action Hooker() {
   modify_field( Pearson.Corinth, 1 );
}

action Morgana() {
   modify_field( Pearson.Corinth, 1 );
   modify_field( Pearson.Occoquan, 1 );
}

action Branson() {
   modify_field( Pearson.Eaton, 1 );
}

action Fitzhugh() {
   modify_field( Pearson.Bangor, 1 );
}

counter Carpenter {
   type : packets_and_bytes;
   direct : McDavid;
   min_width: 16;
}

table McDavid {
   reads {
      Mentone.Aiken : exact;
      Wauseon.Kinard : ternary;
      Wauseon.Goodwin : ternary;
   }

   actions {
      Suwannee;
      Wamego;
      Hooker;
      Branson;
      Fitzhugh;
      Morgana;
   }
   size : Munich;
}

action Montague() {
   modify_field( Pearson.Clarion, 1 );
}


table Tindall {
   reads {
      Wauseon.Boonsboro : ternary;
      Wauseon.Mabana : ternary;
   }

   actions {
      Montague;
   }
   size : FifeLake;
}


control Nondalton {
   apply( McDavid );
   apply( Tindall );
}




action Bells() {
   modify_field( WindLake.UtePark, Requa.Graford );
   modify_field( WindLake.Dixboro, Requa.Lugert );
   modify_field( WindLake.Hammonton, Requa.Laplace );
   modify_field( OldGlory.Schleswig, Millstadt.Sahuarita );
   modify_field( OldGlory.Lewiston, Millstadt.Irondale );
   modify_field( OldGlory.Chatom, Millstadt.Tocito );
   modify_field( OldGlory.Korona, Millstadt.Monrovia );
   modify_field( Pearson.Snook, Nucla.Kinard );
   modify_field( Pearson.Blueberry, Nucla.Goodwin );
   modify_field( Pearson.Antonito, Nucla.Boonsboro );
   modify_field( Pearson.Chaska, Nucla.Mabana );
   modify_field( Pearson.Floris, Nucla.Fishers );
   modify_field( Pearson.Penrose, Vernal.Seagate );
   modify_field( Pearson.Powderly, Vernal.Bigfork );
   modify_field( Pearson.Trout, Vernal.Arroyo );
   modify_field( Pearson.Wabuska, Vernal.Carnegie );
   modify_field( Pearson.Kurten, Vernal.Mabelvale );
   modify_field( Pearson.Micco, Vernal.Nordheim );
   modify_field( Pearson.Bernice, 0 );
   modify_field( Portal.Sopris, Wakefield );



   modify_field( Mentone.Gladden, 1 );
   modify_field( Mentone.Stirrat, 0 );
   modify_field( Mentone.Newland, 0 );
   modify_field( Kekoskee.Bowlus, 1 );
   modify_field( Kekoskee.Yemassee, 1 );
}

action Flatwoods() {
   modify_field( Pearson.Homeacre, Revere );
   modify_field( WindLake.UtePark, Sitka.Graford );
   modify_field( WindLake.Dixboro, Sitka.Lugert );
   modify_field( WindLake.Hammonton, Sitka.Laplace );
   modify_field( OldGlory.Schleswig, Lundell.Sahuarita );
   modify_field( OldGlory.Lewiston, Lundell.Irondale );
   modify_field( OldGlory.Chatom, Lundell.Tocito );
   modify_field( OldGlory.Korona, Lundell.Monrovia );
   modify_field( Pearson.Snook, Wauseon.Kinard );
   modify_field( Pearson.Blueberry, Wauseon.Goodwin );
   modify_field( Pearson.Antonito, Wauseon.Boonsboro );
   modify_field( Pearson.Chaska, Wauseon.Mabana );
   modify_field( Pearson.Floris, Wauseon.Fishers );
   modify_field( Pearson.Penrose, Vernal.Knippa );
   modify_field( Pearson.Powderly, Vernal.Fairland );
   modify_field( Pearson.Trout, Vernal.Elliston );
   modify_field( Pearson.Wabuska, Vernal.SwissAlp );
   modify_field( Pearson.Kurten, Vernal.Samson );
   modify_field( Pearson.Micco, Vernal.Ludell );
   modify_field( Kekoskee.LunaPier, Rockfield[0].Homeland );
   modify_field( Pearson.Bernice, Vernal.DewyRose );
}

table LongPine {
   reads {
      Wauseon.Kinard : exact;
      Wauseon.Goodwin : exact;
      Sitka.Lugert : exact;
      Pearson.Homeacre : exact;
   }

   actions {
      Bells;
      Flatwoods;
   }

   default_action : Flatwoods();
   size : Shidler;
}


action Picabo() {
   modify_field( Pearson.Nevis, Mentone.Chatcolet );
   modify_field( Pearson.Laramie, Mentone.Euren);
}

action Felida( Webbville ) {
   modify_field( Pearson.Nevis, Webbville );
   modify_field( Pearson.Laramie, Mentone.Euren);
}

action Alcester() {
   modify_field( Pearson.Nevis, Rockfield[0].Friend );
   modify_field( Pearson.Laramie, Mentone.Euren);
}

table Alabam {
   reads {
      Mentone.Euren : ternary;
      Rockfield[0] : valid;
      Rockfield[0].Friend : ternary;
   }

   actions {
      Picabo;
      Felida;
      Alcester;
   }
   size : Satolah;
}

action Bairoa( Poynette ) {
   modify_field( Pearson.Laramie, Poynette );
}

action Lafourche() {

   modify_field( Pearson.Commack, 1 );
   modify_field( Challis.Chackbay,
                 Fletcher );
}

table Tusculum {
   reads {
      Sitka.Graford : exact;
   }

   actions {
      Bairoa;
      Lafourche;
   }
   default_action : Lafourche;
   size : Shabbona;
}

action Mendon( Decherd, Westend, Weskan, Mulliken, Strevell,
                        Opelika, Pollard ) {
   modify_field( Pearson.Nevis, Decherd );
   modify_field( Pearson.Dixon, Decherd );
   modify_field( Pearson.Realitos, Pollard );
   Coryville(Westend, Weskan, Mulliken, Strevell,
                        Opelika );
}

action Panaca() {
   modify_field( Pearson.Paulette, 1 );
}

table Mellott {
   reads {
      Milam.Hartfield : exact;
   }

   actions {
      Mendon;
      Panaca;
   }
   size : Oakley;
}

action Coryville(Kinross, Kalvesta, Rardin, BayPort,
                        English ) {
   modify_field( Tornillo.Flats, Kinross );
   modify_field( Tornillo.BallClub, Kalvesta );
   modify_field( Tornillo.Crary, Rardin );
   modify_field( Tornillo.Boyero, BayPort );
   modify_field( Tornillo.Monmouth, English );
}

action Vantage(Newtonia, Armstrong, Haslet, Theba,
                        Shuqualak ) {
   modify_field( Pearson.Dixon, Mentone.Chatcolet );
   Coryville(Newtonia, Armstrong, Haslet, Theba,
                        Shuqualak );
}

action Grisdale(Geistown, Higbee, Brownson, Bowers,
                        FortHunt, Hansell ) {
   modify_field( Pearson.Dixon, Geistown );
   Coryville(Higbee, Brownson, Bowers, FortHunt,
                        Hansell );
}

action Topsfield(Protivin, Belvidere, Sasakwa, Kiron,
                        Osyka ) {
   modify_field( Pearson.Dixon, Rockfield[0].Friend );
   Coryville(Protivin, Belvidere, Sasakwa, Kiron,
                        Osyka );
}

table Palatine {
   reads {
      Mentone.Chatcolet : exact;
   }


   actions {
      Monteview;
      Vantage;
   }

   size : Alburnett;
}

@pragma action_default_only Monteview
table Coalton {
   reads {
      Mentone.Euren : exact;
      Rockfield[0].Friend : exact;
   }

   actions {
      Grisdale;
      Monteview;
   }

   size : Trooper;
}

table Attalla {
   reads {
      Rockfield[0].Friend : exact;
   }


   actions {
      Monteview;
      Topsfield;
   }

   size : Cashmere;
}

control Covelo {
   apply( LongPine ) {
         Bells {
            apply( Tusculum );
            apply( Mellott );
         }
         Flatwoods {
            if ( not valid(Ellisburg) and Mentone.Jackpot == 1 ) {
               apply( Alabam );
            }
            if ( valid( Rockfield[ 0 ] ) ) {

               apply( Coalton ) {
                  Monteview {

                     apply( Attalla );
                  }
               }
            } else {

               apply( Palatine );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Honuapo {
    width  : 1;
    static : Husum;
    instance_count : 262144;
}

register Dillsboro {
    width  : 1;
    static : Lennep;
    instance_count : 262144;
}

blackbox stateful_alu Plains {
    reg : Honuapo;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : DuQuoin.ArchCape;
}

blackbox stateful_alu Montegut {
    reg : Dillsboro;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : DuQuoin.Shellman;
}

field_list Linda {
    Mentone.Aiken;
    Rockfield[0].Friend;
}

field_list_calculation Cataract {
    input { Linda; }
    algorithm: identity;
    output_width: 18;
}

action Exira() {
    Plains.execute_stateful_alu_from_hash(Cataract);
}

action DeerPark() {
    Montegut.execute_stateful_alu_from_hash(Cataract);
}

table Husum {
    actions {
      Exira;
    }
    default_action : Exira;
    size : 1;
}

table Lennep {
    actions {
      DeerPark;
    }
    default_action : DeerPark;
    size : 1;
}
#endif

action PikeView(Hannibal) {
    modify_field(DuQuoin.Shellman, Hannibal);
}

@pragma  use_hash_action 0
table White {
    reads {
       Mentone.Aiken : exact;
    }
    actions {
      PikeView;
    }
    size : 64;
}

action KentPark() {
   modify_field( Pearson.Makawao, Mentone.Chatcolet );
   modify_field( Pearson.Storden, 0 );
}

table Ranier {
   actions {
      KentPark;
   }
   size : 1;
}

action Corry() {
   modify_field( Pearson.Makawao, Rockfield[0].Friend );
   modify_field( Pearson.Storden, 1 );
}

table BigBow {
   actions {
      Corry;
   }
   size : 1;
}

control Walcott {
   if ( valid( Rockfield[ 0 ] ) ) {
      apply( BigBow );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Mentone.Westboro == 1 ) {
         apply( Husum );
         apply( Lennep );
      }
#endif
   } else {
      apply( Ranier );
      if( Mentone.Westboro == 1 ) {
         apply( White );
      }
   }
}




field_list BigRock {
   Wauseon.Kinard;
   Wauseon.Goodwin;
   Wauseon.Boonsboro;
   Wauseon.Mabana;
   Wauseon.Fishers;
}

field_list Orrick {

   Sitka.Kupreanof;
   Sitka.Graford;
   Sitka.Lugert;
}

field_list IttaBena {
   Lundell.Sahuarita;
   Lundell.Irondale;
   Lundell.Tocito;
   Lundell.MiraLoma;
}

field_list Ipava {
   Sitka.Graford;
   Sitka.Lugert;
   Ovilla.Gorum;
   Ovilla.FairOaks;
}





field_list_calculation Ardenvoir {
    input {
        BigRock;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation EastLake {
    input {
        Orrick;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Dunedin {
    input {
        IttaBena;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Monee {
    input {
        Ipava;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Anita() {
    modify_field_with_hash_based_offset(Gifford.Rushmore, 0,
                                        Ardenvoir, 4294967296);
}

action Holcut() {
    modify_field_with_hash_based_offset(Gifford.Carlsbad, 0,
                                        EastLake, 4294967296);
}

action Stratton() {
    modify_field_with_hash_based_offset(Gifford.Carlsbad, 0,
                                        Dunedin, 4294967296);
}

action Ahmeek() {
    modify_field_with_hash_based_offset(Gifford.Eustis, 0,
                                        Monee, 4294967296);
}

table Palmhurst {
   actions {
      Anita;
   }
   size: 1;
}

control Gould {
   apply(Palmhurst);
}

table LasVegas {
   actions {
      Holcut;
   }
   size: 1;
}

table Hopland {
   actions {
      Stratton;
   }
   size: 1;
}

control Holliday {
   if ( valid( Sitka ) ) {
      apply(LasVegas);
   } else {
      if ( valid( Lundell ) ) {
         apply(Hopland);
      }
   }
}

table Ballville {
   actions {
      Ahmeek;
   }
   size: 1;
}

control Nuyaka {
   if ( valid( Rowlett ) ) {
      apply(Ballville);
   }
}



action Wondervu() {
    modify_field(Mackville.Goulds, Gifford.Rushmore);
}

action Foster() {
    modify_field(Mackville.Goulds, Gifford.Carlsbad);
}

action Gotham() {
    modify_field(Mackville.Goulds, Gifford.Eustis);
}

@pragma action_default_only Monteview
@pragma immediate 0
table Chicago {
   reads {
      Leucadia.valid : ternary;
      Triplett.valid : ternary;
      Requa.valid : ternary;
      Millstadt.valid : ternary;
      Nucla.valid : ternary;
      Thurmond.valid : ternary;
      Rowlett.valid : ternary;
      Sitka.valid : ternary;
      Lundell.valid : ternary;
      Wauseon.valid : ternary;
   }
   actions {
      Wondervu;
      Foster;
      Gotham;
      Monteview;
   }
   size: Herod;
}

action Highfill() {
    modify_field(Mackville.BigWater, Gifford.Eustis);
}

@pragma immediate 0
table Needles {
   reads {
      Leucadia.valid : ternary;
      Triplett.valid : ternary;
      Thurmond.valid : ternary;
      Rowlett.valid : ternary;
   }
   actions {
      Highfill;
      Monteview;
   }
   size: BlueAsh;
}

control Tilghman {
   apply(Needles);
   apply(Chicago);
}



counter Hauppauge {
   type : packets_and_bytes;
   direct : Northome;
   min_width: 16;
}

table Northome {
   reads {
      Mentone.Aiken : exact;
      DuQuoin.Shellman : ternary;
      DuQuoin.ArchCape : ternary;
      Pearson.Paulette : ternary;
      Pearson.Clarion : ternary;
      Pearson.Lepanto : ternary;
   }

   actions {
      Hecker;
      Monteview;
   }
   default_action : Monteview();
   size : Hammett;
}

table Wisdom {
   reads {
      Pearson.Antonito : exact;
      Pearson.Chaska : exact;
      Pearson.Nevis : exact;
   }

   actions {
      Hecker;
      Monteview;
   }
   default_action : Monteview();
   size : Nisland;
}

action National() {

   modify_field(Pearson.Adelino, 1 );
   modify_field(Challis.Chackbay,
                Valders);
}







table Harlem {
   reads {
      Pearson.Antonito : exact;
      Pearson.Chaska : exact;
      Pearson.Nevis : exact;
      Pearson.Laramie : exact;
   }

   actions {
      Whiteclay;
      National;
   }
   default_action : National();
   size : Brazil;
   support_timeout : true;
}

action Sedona( Sidon, Mullins ) {
   modify_field( Pearson.Redvale, Sidon );
   modify_field( Pearson.Realitos, Mullins );
}

action Gannett() {
   modify_field( Pearson.Realitos, 1 );
}

table OakCity {
   reads {
      Pearson.Nevis mask 0xfff : exact;
   }

   actions {
      Sedona;
      Gannett;
      Monteview;
   }

   default_action : Monteview();
   size : Evansburg;
}

action Paisley() {
   modify_field( Tornillo.LaPuente, 1 );
}

table WildRose {
   reads {
      Pearson.Dixon : ternary;
      Pearson.Snook : exact;
      Pearson.Blueberry : exact;
   }
   actions {
      Paisley;
   }
   size: Goodlett;
}

control Swisher {
   apply( Northome ) {
      Monteview {
         apply( Wisdom ) {
            Monteview {



               if (Mentone.Hanks == 0 and Pearson.Commack == 0) {
                  apply( Harlem );
               }
               apply( OakCity );
               apply(WildRose);
            }
         }
      }
   }
}

field_list Newsome {
    Challis.Chackbay;
    Pearson.Antonito;
    Pearson.Chaska;
    Pearson.Nevis;
    Pearson.Laramie;
}

action Bratenahl() {
   generate_digest(Wataga, Newsome);
}

table Sixteen {
   actions {
      Bratenahl;
   }
   size : 1;
}

control Tilton {
   if (Pearson.Adelino == 1) {
      apply( Sixteen );
   }
}



action NewMelle( Dunnville, Rawson ) {
   modify_field( OldGlory.LoneJack, Dunnville );
   modify_field( Gregory.Glenshaw, Rawson );
}

@pragma action_default_only Tontogany
table Scarville {
   reads {
      Tornillo.Flats : exact;
      OldGlory.Lewiston mask Rockleigh : lpm;
   }
   actions {
      NewMelle;
      Tontogany;
   }
   size : Townville;
}

@pragma atcam_partition_index OldGlory.LoneJack
@pragma atcam_number_partitions Townville
table Kohrville {
   reads {
      OldGlory.LoneJack : exact;
      OldGlory.Lewiston mask Metzger : lpm;
   }

   actions {
      Newburgh;
      Faysville;
      Monteview;
   }
   default_action : Monteview();
   size : Allgood;
}

action Dellslow( Ahuimanu, Ravenwood ) {
   modify_field( OldGlory.Vinings, Ahuimanu );
   modify_field( Gregory.Glenshaw, Ravenwood );
}

@pragma action_default_only Monteview
table Stampley {


   reads {
      Tornillo.Flats : exact;
      OldGlory.Lewiston : lpm;
   }

   actions {
      Dellslow;
      Monteview;
   }

   size : Mabank;
}

@pragma atcam_partition_index OldGlory.Vinings
@pragma atcam_number_partitions Mabank
table Neches {
   reads {
      OldGlory.Vinings : exact;


      OldGlory.Lewiston mask Medart : lpm;
   }
   actions {
      Newburgh;
      Faysville;
      Monteview;
   }

   default_action : Monteview();
   size : Moody;
}

@pragma action_default_only Tontogany
@pragma idletime_precision 1
table Pendroy {

   reads {
      Tornillo.Flats : exact;
      WindLake.Dixboro : lpm;
   }

   actions {
      Newburgh;
      Faysville;
      Tontogany;
   }

   size : Roxobel;
   support_timeout : true;
}

action Sheldahl( Agency, Portales ) {
   modify_field( WindLake.Hooven, Agency );
   modify_field( Gregory.Glenshaw, Portales );
}

@pragma action_default_only Monteview
#ifdef PROFILE_DEFAULT


#endif
table Cecilton {
   reads {
      Tornillo.Flats : exact;
      WindLake.Dixboro : lpm;
   }

   actions {
      Sheldahl;
      Monteview;
   }

   size : Charenton;
}

@pragma ways Blencoe
@pragma atcam_partition_index WindLake.Hooven
@pragma atcam_number_partitions Charenton
table WindGap {
   reads {
      WindLake.Hooven : exact;
      WindLake.Dixboro mask Saugatuck : lpm;
   }
   actions {
      Newburgh;
      Faysville;
      Monteview;
   }
   default_action : Monteview();
   size : Gheen;
}

action Newburgh( McCracken ) {
   modify_field( Gregory.Glenshaw, McCracken );
}

@pragma idletime_precision 1
table Hercules {
   reads {
      Tornillo.Flats : exact;
      WindLake.Dixboro : exact;
   }

   actions {
      Newburgh;
      Faysville;
      Monteview;
   }
   default_action : Monteview();
   size : Wymore;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT


#endif
table Sardinia {
   reads {
      Tornillo.Flats : exact;
      OldGlory.Lewiston : exact;
   }

   actions {
      Newburgh;
      Faysville;
      Monteview;
   }
   default_action : Monteview();
   size : Bergoo;
   support_timeout : true;
}

action Poplar(Frontenac, Suwanee, Fosters) {
   modify_field(Portal.Charm, Fosters);
   modify_field(Portal.Littleton, Frontenac);
   modify_field(Portal.Miltona, Suwanee);
   modify_field(Portal.Panola, 1);

   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}

action Leonidas() {
   Hecker();
}

action Parkline(Parmerton) {
   modify_field(Portal.Epsie, 1);
   modify_field(Portal.LoonLake, Parmerton);
}

action Tontogany(Topmost) {
   modify_field( Portal.Epsie, 1 );
   modify_field( Portal.LoonLake, 9 );
}

table Navarro {
   reads {
      Gregory.Glenshaw : exact;
   }

   actions {
      Poplar;
      Leonidas;
      Parkline;
   }
   size : Maltby;
}

action Parshall( Millport ) {
   modify_field(Portal.Epsie, 1);
   modify_field(Portal.LoonLake, Millport);
}

table Bouse {
   actions {
      Parshall;
   }
   default_action: Parshall;
   size : 1;
}

control Secaucus {
   if ( Pearson.Darmstadt == 0 and Tornillo.LaPuente == 1 ) {
      if ( ( Tornillo.BallClub == 1 ) and ( Pearson.Kurten == 1 ) ) {
         apply( Hercules ) {
            Monteview {
               apply( Cecilton ) {
                  Sheldahl {
                     apply( WindGap );
                  }
                  Monteview {
                     apply( Pendroy );
                  }
               }
            }
         }
      } else if ( ( Tornillo.Crary == 1 ) and ( Pearson.Micco == 1 ) ) {
         apply( Sardinia ) {
            Monteview {
               apply( Stampley ) {
                  Dellslow {
                     apply( Neches );
                  }
                  Monteview {

                     apply( Scarville ) {
                        NewMelle {
                           apply( Kohrville );
                        }
                     }
                  }
               }
            }
         }
      } else if( Pearson.Realitos == 1 ) {
         apply( Bouse );
      }
   }
}

control RioLajas {
   if( Gregory.Glenshaw != 0 ) {
      apply( Navarro );
   }
}

action Faysville( Sabana ) {
   modify_field( Gregory.Eclectic, Sabana );
}

field_list Onset {
   Mackville.BigWater;
}

field_list_calculation Ripon {
    input {
        Onset;
    }
    algorithm : identity;
    output_width : 66;
}

action_selector Ebenezer {
   selection_key : Ripon;
   selection_mode : resilient;
}

action_profile Austell {
   actions {
      Newburgh;
   }
   size : Purves;
   dynamic_action_selection : Ebenezer;
}

@pragma selector_max_group_size 256
table ViewPark {
   reads {
      Gregory.Eclectic : exact;
   }
   action_profile : Austell;
   size : Minburn;
}

control Broussard {
   if ( Gregory.Eclectic != 0 ) {
      apply( ViewPark );
   }
}



field_list Stilson {
   Mackville.Goulds;
}

field_list_calculation Mayday {
    input {
        Stilson;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Onslow {
    selection_key : Mayday;
    selection_mode : resilient;
}

action Vacherie(Saticoy) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Saticoy);
}

action_profile Ossineke {
    actions {
        Vacherie;
        Monteview;
    }
    size : Belview;
    dynamic_action_selection : Onslow;
}

table Mattese {
   reads {
      Portal.Glenmora : exact;
   }
   action_profile: Ossineke;
   size : Dixfield;
}

control Bufalo {
   if ((Portal.Glenmora & 0x2000) == 0x2000) {
      apply(Mattese);
   }
}



action Johnsburg() {
   modify_field(Portal.Littleton, Pearson.Snook);
   modify_field(Portal.Miltona, Pearson.Blueberry);
   modify_field(Portal.Pinebluff, Pearson.Antonito);
   modify_field(Portal.Levittown, Pearson.Chaska);
   modify_field(Portal.Charm, Pearson.Nevis);
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
   invalidate( ig_intr_md_for_tm.ucast_egress_port );
#else
   modify_field( ig_intr_md_for_tm.ucast_egress_port, 511 );
#endif
}

table Coronado {
   actions {
      Johnsburg;
   }
   default_action : Johnsburg();
   size : 1;
}

control Estrella {
   apply( Coronado );
}

action FlatRock() {
   modify_field(Portal.Longwood, 1);
   modify_field(Portal.Kenefic, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Pearson.Realitos);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Portal.Charm);
}

action Chevak() {
}



@pragma ways 1
table Belfalls {
   reads {
      Portal.Littleton : exact;
      Portal.Miltona : exact;
   }
   actions {
      FlatRock;
      Chevak;
   }
   default_action : Chevak;
   size : 1;
}

action Grygla() {
   modify_field(Portal.Merkel, 1);
   modify_field(Portal.Lutts, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Portal.Charm, Braselton);
}

table Glentana {
   actions {
      Grygla;
   }
   default_action : Grygla;
   size : 1;
}

action Homeworth() {
   modify_field(Portal.Timken, 1);
   modify_field(Portal.Kenefic, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Portal.Charm);
}

table Chappells {
   actions {
      Homeworth;
   }
   default_action : Homeworth();
   size : 1;
}

action Tahlequah(Marlton) {
   modify_field(Portal.Sigsbee, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Marlton);
   modify_field(Portal.Glenmora, Marlton);
}

action Rainsburg(Tombstone) {
   modify_field(Portal.Merkel, 1);
   modify_field(Portal.Hilburn, Tombstone);
}

action Brockton() {
}

table Tigard {
   reads {
      Portal.Littleton : exact;
      Portal.Miltona : exact;
      Portal.Charm : exact;
   }

   actions {
      Tahlequah;
      Rainsburg;
      Hecker;
      Brockton;
   }
   default_action : Brockton();
   size : Lilbert;
}

control StarLake {
   if (Pearson.Darmstadt == 0 and not valid(Ellisburg) ) {
      apply(Tigard) {
         Brockton {
            apply(Belfalls) {
               Chevak {
                  if ((Portal.Littleton & 0x010000) == 0x010000) {
                     apply(Glentana);
                  } else {
                     apply(Chappells);
                  }
               }
            }
         }
      }
   }
}

action Alamota() {
   modify_field(Pearson.Montbrook, 1);
   Hecker();
}

table Annette {
   actions {
      Alamota;
   }
   default_action : Alamota;
   size : 1;
}

control Loris {
   if (Pearson.Darmstadt == 0) {
      if ((Portal.Panola==0) and (Pearson.Corinth==0) and (Pearson.Eaton==0) and (Pearson.Laramie==Portal.Glenmora)) {
         apply(Annette);
      } else {
         Bufalo();
      }
   }
}




action Paullina( Steele ) {
   modify_field( Portal.Ferrum, Steele );
}

action Magnolia() {
   modify_field( Portal.Ferrum, Portal.Charm );
}

table SantaAna {
   reads {
      eg_intr_md.egress_port : exact;
      Portal.Charm : exact;
   }

   actions {
      Paullina;
      Magnolia;
   }
   default_action : Magnolia;
   size : Soldotna;
}

control Newsoms {
   apply( SantaAna );
}



action Wauconda( Harmony, Quebrada ) {
   modify_field( Portal.Thomas, Harmony );
   modify_field( Portal.Richvale, Quebrada );
}

action Provencal() {
   modify_field( Portal.Perkasie, Minoa );
   modify_field( Portal.Sonoma, LaVale );
}

table Skene {
   reads {
      Portal.Lenoir : exact;
   }

   actions {
      Wauconda;
      Provencal;
   }
   size : Weyauwega;
}

action Aldrich( Osman, Silvertip, Morstein ) {
   modify_field( Portal.Killen, Osman );
   modify_field( Portal.Weissert, Silvertip );
   modify_field( Portal.Newfield, Morstein );
}

table Kurthwood {
   reads {
      Portal.Christina : exact;
   }
   actions {
      Aldrich;
   }
   size : Okaton;
}

action Skyline() {
   modify_field( Portal.Oneonta, 1 );
   modify_field( Portal.Lenoir, Jenera );
}

action Willard() {
   modify_field( Portal.Oneonta, 1 );
   modify_field( Portal.Lenoir, Nenana );
}

table Mosinee {
   reads {
      Portal.Salus : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Skyline;
      Willard;
   }
   default_action : Monteview();
   size : 16;
}

action Holladay(Hannah, Rayville, SourLake, Cowen) {
   modify_field( Portal.Uhland, Hannah );
   modify_field( Portal.Perma, Rayville );
   modify_field( Portal.Rehoboth, SourLake );
   modify_field( Portal.Gambrills, Cowen );
}

table Brainard {
   reads {
        Portal.Elsey : exact;
   }
   actions {
      Holladay;
   }
   size : Willows;
}

action Ivanpah() {
   no_op();
}

action Dixie() {
   modify_field( Wauseon.Fishers, Rockfield[0].Mendota );
   remove_header( Rockfield[0] );
}

table Edler {
   actions {
      Dixie;
   }
   default_action : Dixie;
   size : Quitman;
}

action Mynard() {
   no_op();
}

action Robert() {
   add_header( Rockfield[ 0 ] );
   modify_field( Rockfield[0].Friend, Portal.Ferrum );
   modify_field( Rockfield[0].Mendota, Wauseon.Fishers );
   modify_field( Rockfield[0].Petoskey, Kekoskee.Grantfork );
   modify_field( Rockfield[0].Homeland, Kekoskee.LunaPier );
   modify_field( Wauseon.Fishers, BlackOak );
}



table Omemee {
   reads {
      Portal.Ferrum : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Mynard;
      Robert;
   }
   default_action : Robert;
   size : Lurton;
}

action Scherr() {
   modify_field(Wauseon.Kinard, Portal.Littleton);
   modify_field(Wauseon.Goodwin, Portal.Miltona);
   modify_field(Wauseon.Boonsboro, Portal.Thomas);
   modify_field(Wauseon.Mabana, Portal.Richvale);
}

action Covina() {
   Scherr();
   add_to_field(Sitka.Raeford, -1);
   modify_field(Sitka.Laplace, Kekoskee.Chatanika);
}

action McCaskill() {
   Scherr();
   add_to_field(Lundell.Tillson, -1);
   modify_field(Lundell.Monrovia, Kekoskee.Chatanika);
}

action Korbel() {
   modify_field(Sitka.Laplace, Kekoskee.Chatanika);
}

action SanRemo() {
   modify_field(Lundell.Monrovia, Kekoskee.Chatanika);
}

action Temvik() {
   Robert();
}

action Tabler( Sagamore, Tuttle, Magness, Donner ) {
   add_header( Coconino );
   modify_field( Coconino.Kinard, Sagamore );
   modify_field( Coconino.Goodwin, Tuttle );
   modify_field( Coconino.Boonsboro, Magness );
   modify_field( Coconino.Mabana, Donner );
   modify_field( Coconino.Fishers, Lynndyl );

   add_header( Ellisburg );
   modify_field( Ellisburg.Campo, Portal.Uhland );
   modify_field( Ellisburg.Horatio, Portal.Perma );
   modify_field( Ellisburg.Greenland, Portal.Rehoboth );
   modify_field( Ellisburg.Alden, Portal.Gambrills );
   modify_field( Ellisburg.Sweeny, Portal.LoonLake );
}

action Zarah() {
   add_header( Yardville );
   modify_field( Yardville.Maytown, Wauseon.Fishers );
   add_header( Sitka );
   modify_field( Sitka.Ottertail, 0x4 );
   modify_field( Sitka.Uniontown, 0x5 );
   modify_field( Sitka.Kupreanof, Portal.Perkasie );
   modify_field( Sitka.Raeford, Portal.Newfield );
   modify_field( Sitka.Graford, Portal.Killen );
   modify_field( Sitka.Lugert, Portal.Weissert );
   add( Sitka.Moclips, standard_metadata.packet_length, 24 );
   add_header( Wauseon );
   Scherr();
}

action Brady() {
   remove_header( Milam );
   remove_header( Rowlett );
   remove_header( Ovilla );
   copy_header( Wauseon, Nucla );
   remove_header( Nucla );
   remove_header( Sitka );
}

action Placida() {
   remove_header( Coconino );
   remove_header( Ellisburg );
}

action Tolleson() {
   Brady();
   modify_field(Requa.Laplace, Kekoskee.Chatanika);
}

action Daleville() {
   Brady();
   modify_field(Millstadt.Monrovia, Kekoskee.Chatanika);
}

table Akiachak {
   reads {
      Portal.Sopris : exact;
      Portal.Lenoir : exact;
      Portal.Panola : exact;
      Sitka.valid : ternary;
      Lundell.valid : ternary;
      Requa.valid : ternary;
      Millstadt.valid : ternary;
   }

   actions {
      Covina;
      McCaskill;
      Korbel;
      SanRemo;
      Temvik;
      Tabler;
      Zarah;
      Placida;
      Brady;
      Tolleson;
      Daleville;
   }
   size : Natalia;
}

control Wyanet {
   apply( Edler );
}

control Canjilon {
   apply( Omemee );
}

control Vanoss {
   apply( Mosinee ) {
      Monteview {
         apply( Skene );
         apply( Kurthwood );
      }
   }
   apply( Brainard );
   apply( Akiachak );
}



field_list Lynne {
    Challis.Chackbay;
    Pearson.Nevis;
    Nucla.Boonsboro;
    Nucla.Mabana;
    Sitka.Graford;
}

action Bostic() {
   generate_digest(Wataga, Lynne);
}

table Fount {
   actions {
      Bostic;
   }

   default_action : Bostic;
   size : 1;
}

control Maumee {
   if (Pearson.Commack == 1) {
      apply(Fount);
   }
}



action Cadwell() {
   modify_field( Kekoskee.Grantfork, Mentone.Stirrat );
}

action Clauene() {
   modify_field( Kekoskee.Grantfork, Rockfield[0].Petoskey );
   modify_field( Pearson.Floris, Rockfield[0].Mendota );
}

action RedCliff() {
   modify_field( Kekoskee.Chatanika, Mentone.Newland );
}

action Cooter() {
   modify_field( Kekoskee.Chatanika, WindLake.Hammonton );
}

action Nettleton() {
   modify_field( Kekoskee.Chatanika, OldGlory.Korona );
}

action LaHabra( Illmo, Halaula ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Illmo );
   modify_field( ig_intr_md_for_tm.qid, Halaula );
}

table Stovall {
   reads {
     Pearson.Bernice : exact;
   }

   actions {
     Cadwell;
     Clauene;
   }

   size : Ketchum;
}

table Cowell {
   reads {
     Pearson.Kurten : exact;
     Pearson.Micco : exact;
   }

   actions {
     RedCliff;
     Cooter;
     Nettleton;
   }

   size : Seabrook;
}

table Bayport {
   reads {
      Mentone.Gladden : ternary;
      Mentone.Stirrat : ternary;
      Kekoskee.Grantfork : ternary;
      Kekoskee.Chatanika : ternary;
      Kekoskee.Surrey : ternary;
   }

   actions {
      LaHabra;
   }

   size : Cross;
}

action Stoystown( Bulverde, Melrude ) {
   bit_or( Kekoskee.Bowlus, Kekoskee.Bowlus, Bulverde );
   bit_or( Kekoskee.Yemassee, Kekoskee.Yemassee, Melrude );
}

table Yorklyn {
   actions {
      Stoystown;
   }
   default_action : Stoystown;
   size : Halfa;
}

action Hallville( Paxson ) {
   modify_field( Kekoskee.Chatanika, Paxson );
}

action Atlasburg( Moxley ) {
   modify_field( Kekoskee.Grantfork, Moxley );
}

action Sonestown( Onida, Virgin ) {
   modify_field( Kekoskee.Grantfork, Onida );
   modify_field( Kekoskee.Chatanika, Virgin );
}

table Huttig {
   reads {
      Mentone.Gladden : exact;
      Kekoskee.Bowlus : exact;
      Kekoskee.Yemassee : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }

   actions {
      Hallville;
      Atlasburg;
      Sonestown;
   }

   size : Crannell;
}

control Amenia {
   apply( Stovall );
   apply( Cowell );
}

control Ojibwa {
   apply( Bayport );
}

control Lorane {
   apply( Yorklyn );
   apply( Huttig );
}



action Clearco( Hotchkiss ) {
   modify_field( Portal.LoonLake, Hotchkiss );
   modify_field( Kekoskee.Lincroft, 1 );
}

action Orlinda( Toulon, Slick ) {
   Clearco( Toulon );
   modify_field( ig_intr_md_for_tm.qid, Slick );
}

table Hadley {
   reads {
      Portal.Epsie : ternary;
      ig_intr_md_for_tm.copy_to_cpu : ternary;
      Portal.LoonLake : ternary;
      Pearson.Kurten : ternary;
      Pearson.Micco : ternary;
      Pearson.Floris : ternary;
      Pearson.Powderly : ternary;
      Pearson.Trout : ternary;
      Portal.Panola : ternary;
      Ovilla.FairOaks : ternary;
   }

   actions {
      Clearco;
      Orlinda;
   }

   size : Lantana;
}

meter Forman {
   type : packets;
   static : Marquette;
   instance_count : Lebanon;
}

action Honokahua(Benson) {
   execute_meter( Forman, Benson, ig_intr_md_for_tm.packet_color );
}

table Marquette {
   reads {
      Mentone.Aiken mask 0x3f : exact;
      Portal.LoonLake : exact;
   }
   actions {
      Honokahua;
   }
   size : Saragosa;
}

control Handley {
   if ( Mentone.Westboro != 0 ) {
      apply( Hadley );
   }
}

control PellCity {

    if ( (
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x1 ) == 0 ) ) and ( Portal.Epsie == 1 ) ) or
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x2 ) == 0 ) ) and ( ig_intr_md_for_tm.copy_to_cpu == 1 ) )
         ) and
         ( Kekoskee.Lincroft == 1 ) ) {
      apply( Marquette );
   }
}



action Vallejo( Asherton ) {
   modify_field( Portal.Salus, Cuprum );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Asherton );
   modify_field( Portal.Elsey, ig_intr_md.ingress_port );
}

action Odessa( KingCity ) {
   modify_field( Portal.Salus, Raytown );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, KingCity );
   modify_field( Portal.Elsey, ig_intr_md.ingress_port );
}

action OldTown() {
   modify_field( Portal.Salus, Cuprum );
}

action DeepGap() {
   modify_field( Portal.Salus, Raytown );
   modify_field( Portal.Elsey, ig_intr_md.ingress_port );
}

@pragma ternary 1
table Carver {
   reads {
      Portal.Epsie : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      Tornillo.LaPuente : exact;
      Mentone.Jackpot : ternary;
      Portal.LoonLake : ternary;
   }

   actions {
      Vallejo;
      Odessa;
      OldTown;
      DeepGap;
   }
   size : Ledoux;
}

control Hagewood {
   apply( Carver );
}




counter Shirley {
   type : packets_and_bytes;
   instance_count : Lapeer;

   min_width : 128;


}

action Vieques( RockyGap ) {
   count( Shirley, RockyGap );
}

table Waialua {
   reads {
      eg_intr_md.egress_port mask 0x7f: exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }

   actions {
     Vieques;
   }

   size : Lapeer;
}

control Billett {
   apply( Waialua );
}



action Wenden()
{



   Hecker();
}

action Altus()
{
   modify_field(Portal.Sopris, Wrenshall);
   bit_or(Portal.Glenmora, 0x2000, Ellisburg.Alden);
}

action Ayden( Iroquois ) {
   modify_field(Portal.Sopris, Wrenshall);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Iroquois);
   modify_field(Portal.Glenmora, Iroquois);
}

table Livonia {
   reads {
      Ellisburg.Campo : exact;
      Ellisburg.Horatio : exact;
      Ellisburg.Greenland : exact;
      Ellisburg.Alden : exact;
   }

   actions {
      Altus;
      Ayden;
      Wenden;
   }
   default_action : Wenden();
   size : Willows;
}

control Lardo {
   apply( Livonia );
}



action Halbur( Hephzibah, Sasser, Silica, Telocaset ) {
   modify_field( Kingsland.Coulee, Hephzibah );
   modify_field( Cuthbert.Geismar, Silica );
   modify_field( Cuthbert.Bosler, Sasser );
   modify_field( Cuthbert.Russia, Telocaset );
}

table Hahira {
   reads {
     WindLake.Dixboro : exact;
     Pearson.Dixon : exact;
   }

   actions {
      Halbur;
   }
  size : Converse;
}

action Kanab(Dolliver, Quealy, Jesup) {
   modify_field( Cuthbert.Bosler, Dolliver );
   modify_field( Cuthbert.Geismar, Quealy );
   modify_field( Cuthbert.Russia, Jesup );
}

table Cheyenne {
   reads {
     WindLake.UtePark : exact;
     Kingsland.Coulee : exact;
   }
   actions {
      Kanab;
   }
   size : Walnut;
}

action Sparr( LaPointe, Waucoma, Isabela ) {
   modify_field( Brothers.Lakeside, LaPointe );
   modify_field( Brothers.Trona, Waucoma );
   modify_field( Brothers.Blanding, Isabela );
}

table Skyway {


   reads {
     Portal.Littleton : exact;
     Portal.Miltona : exact;
     Portal.Charm : exact;
   }
   actions {
      Sparr;
   }
   size : Simnasho;
}

action Pumphrey() {
   modify_field( Portal.Kenefic, 1 );
}

action Swenson( Keltys ) {
   Pumphrey();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Cuthbert.Bosler );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Keltys, Cuthbert.Russia );
}

action Brentford( PineAire ) {
   Pumphrey();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Brothers.Lakeside );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, PineAire, Brothers.Blanding );
}

action Froid( Twodot ) {
   Pumphrey();
   add( ig_intr_md_for_tm.mcast_grp_a, Portal.Charm,
        Braselton );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Twodot );
}

action Candle() {
   modify_field( Portal.Peletier, 1 );
}

table Camino {
   reads {
     Cuthbert.Geismar : ternary;
     Cuthbert.Bosler : ternary;
     Brothers.Lakeside : ternary;
     Brothers.Trona : ternary;
     Pearson.Powderly :ternary;
     Pearson.Corinth:ternary;
   }
   actions {
      Swenson;
      Brentford;
      Froid;
      Candle;
   }
   size : 32;
}

control Doyline {
   if( Pearson.Darmstadt == 0 and
       Tornillo.Boyero == 1 and
       Pearson.Occoquan == 1 ) {
      apply( Hahira );
   }
}

control Squire {
   if( Kingsland.Coulee != 0 ) {
      apply( Cheyenne );
   }
}


control Elrosa {
   if( Pearson.Darmstadt == 0 and Pearson.Corinth==1 ) {
      apply( Skyway );
   }
}

control Weiser {


   if( Pearson.Corinth == 1 ) {
      apply(Camino);
   }
}

action Everton(Blakeman) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Mackville.Goulds );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Blakeman );
}

table Faulkton {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Everton;
    }
    size : 512;
}

control Salitpa {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Faulkton);
   }
}




action MoonRun( Calamus, Portville ) {
   modify_field( Portal.Charm, Calamus );


   modify_field( Portal.Panola, Portville );
}

action Kendrick() {

   drop();
}

table Woodburn {
   reads {
     eg_intr_md.egress_rid: exact;
   }

   actions {
      MoonRun;
   }
   default_action: Kendrick;
   size : Bonney;
}


control Pedro {


   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Woodburn);
   }
}



action Bethania( Wardville ) {
   modify_field( Bucktown.Kinney, Wardville );
}

table Hilbert {
   reads {
      WindLake.UtePark : ternary;
   }
   actions {
      Bethania;
   }
   size : Wyatte;
}

action ElToro( Hollymead ) {
   modify_field( Bucktown.Lathrop, Hollymead );
}

table Greenbelt {
   reads {
      WindLake.Dixboro : ternary;
   }
   actions {
      ElToro;
   }
   size : Wyatte;
}

action Funkley( Rotonda ) {
   modify_field( Bucktown.Kinney, Rotonda );
}

table Newellton {
   reads {
      OldGlory.Schleswig : ternary;
   }
   actions {
      Funkley;
   }
   size : Sabina;
}

action Wilson( Oriskany ) {
   modify_field( Bucktown.Lathrop, Oriskany );
}

table Goessel {
   reads {
      OldGlory.Lewiston : ternary;
   }
   actions {
      Wilson;
   }
   size : Sabina;
}

control Halltown {
   if( Pearson.Kurten != 0 ) {
      apply( Hilbert );
      apply( Greenbelt );
   } else if( Pearson.Micco != 0 ) {
      apply( Newellton );
      apply( Goessel );
   }
}



header_type Syria {
	fields {
		Hewitt : 8;
		Iselin : 32;
	}
}
metadata Syria Alzada;

field_list Lapel {
   Alzada.Hewitt;
}

field_list Trenary {
   Mackville.Goulds;
}

field_list_calculation Enfield {
    input {
        Trenary;
    }
    algorithm : identity;
    output_width : 51;
}

action Deloit( Whitefish ) {
   modify_field( Pearson.Basco, Whitefish );
}

table Pueblo {
   reads {
      Mentone.Euren : ternary;
      Bucktown.Kinney : ternary;
      Bucktown.Lathrop : ternary;
      Pearson.Powderly : ternary;
      Pearson.Trout : ternary;
      Pearson.Wabuska : ternary;
      Kekoskee.Chatanika : ternary;
      Ovilla.Gorum : ternary;
      Ovilla.FairOaks : ternary;
   }
   actions {
      Deloit;
   }
   size : Amsterdam;
}

control Durant {
    apply( Pueblo );
}

meter Osseo {
   type : bytes;
   static : Alnwick;
   instance_count : Berrydale;
}

action Crane( Petroleum, Calcium ) {
   execute_meter( Osseo, Petroleum, Pearson.Champlain );
}

table Alnwick {
   reads {
      Pearson.Basco mask 0x7F : exact;
   }
   actions {
      Crane;
   }
   size : Berrydale;
}

control Issaquah {
   apply( Alnwick );
}

action Parthenon( ) {
   clone_ingress_pkt_to_egress( Pearson.Warba, Lapel );
   modify_field( Alzada.Hewitt, Pearson.Basco );
   modify_field( Alzada.Iselin, Mackville.Goulds );
   bit_or( Pearson.Warba, Pearson.Basco, Pearson.Fitler );
}

table Carlson {
   reads {
      Pearson.Champlain : exact;
   }
   actions {
      Parthenon;
   }
   size : Oconee;
}

control Greenlawn {
   if( Pearson.Basco != 0 ) {
      apply( Carlson );
   }
}

action_selector Camilla {
    selection_key : Enfield;
    selection_mode : resilient;
}

action TroutRun( Bondad ) {
   modify_field( Pearson.Fitler, Bondad );
}

action_profile Burgin {
    actions {
        TroutRun;
    }
    size : Staunton;
    dynamic_action_selection : Camilla;
}

table PeaRidge {
   reads {
      Pearson.Basco mask 0x7F : exact;
   }
   action_profile : Burgin;
   size : Berrydale;
}

control Lonepine {
   if( ( Pearson.Basco & 0x80 ) == 0x80 ) {
      apply( PeaRidge );
   }
}

action Lordstown() {
   modify_field( Portal.Sopris, 0 );
   modify_field( Portal.Lenoir, Jelloway );
}

action Baskin( Fristoe ) {
   modify_field( Portal.Sopris, 0 );
   modify_field( Portal.Lenoir, Eggleston );
   modify_field( Portal.Christina, Fristoe );
}

action Melba() {
   modify_field( Portal.Sopris, 0 );
   modify_field( Portal.Salus, Raytown );
}

table Hiwasse {
   reads {
      Alzada.Hewitt mask 0x7F : exact;
   }
   actions {
      Lordstown;
      Baskin;
      Melba;
   }
   size : Berrydale;
}

control Catawissa {
   if( Lawnside ) {
      apply( Hiwasse );
   }
}

control ingress {

   Flomaton();

   if( Mentone.Westboro != 0 ) {

      Nondalton();
   }

   Covelo();

   if( Mentone.Westboro != 0 ) {
      Walcott();


      Swisher();
   }

   Gould();
   Halltown();


   Holliday();
   Nuyaka();

   if( Mentone.Westboro != 0 ) {

      Secaucus();
   }


   Durant();
   Tilghman();
   Amenia();


   Issaquah();
   if( Mentone.Westboro != 0 ) {
      Broussard();
   }

   Estrella();
   Doyline();


   Lonepine();
   if( Mentone.Westboro != 0 ) {
      RioLajas();
   }
   Squire();




   Maumee();
   Tilton();
   if( Portal.Epsie == 0 ) {
      if( valid( Ellisburg ) ) {
         Lardo();
      } else {
         Elrosa();
         StarLake();
      }
   }
   if( not valid( Ellisburg ) ) {
      Ojibwa();
   }


   if( Portal.Epsie == 0 ) {
      Loris();
   }

   Handley();

   if( Portal.Epsie == 0 ) {
      Weiser();
   }

   if( Mentone.Westboro != 0 ) {
      Lorane();
   }


   PellCity();


   if( valid( Rockfield[0] ) ) {
      Wyanet();
   }

   if( Portal.Epsie == 0 ) {
      Salitpa();
   }




   Hagewood();
   Greenlawn();
}

control egress {
   Pedro();
   Catawissa();
   Newsoms();
   Vanoss();

   if( ( Portal.Oneonta == 0 ) and ( Portal.Sopris != Wrenshall ) ) {
      Canjilon();
   }
   Billett();
}
