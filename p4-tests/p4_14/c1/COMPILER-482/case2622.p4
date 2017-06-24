// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 2







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>



#ifndef Bagdad
#define Bagdad

header_type Weathers {
	fields {
		Waring : 16;
		Ballwin : 16;
		Bethesda : 8;
		Skime : 8;
		Poulsbo : 8;
		Okaton : 8;
		Fernway : 1;
		Mingus : 1;
		MintHill : 1;
		McCleary : 1;
		Cathcart : 1;
	}
}

header_type Hughson {
	fields {
		Haslet : 24;
		Pinecrest : 24;
		Yardley : 24;
		Washta : 24;
		Lublin : 16;
		Ivanhoe : 16;
		Edler : 16;
		Aquilla : 16;
		Anawalt : 16;
		Kealia : 8;
		Floyd : 8;
		Halliday : 6;
		Thistle : 1;
		Lewiston : 1;
		Malabar : 12;
		Delmont : 2;
		Amboy : 1;
		FoxChase : 1;
		Cadwell : 1;
		Latham : 1;
		Yukon : 1;
		Onida : 1;
		Clearlake : 1;
		TiePlant : 1;
		Sabula : 1;
		Portville : 1;
		Traskwood : 1;
		Rendon : 1;
		Roswell : 1;
		Godley : 3;
		Winfall : 1;
		Wentworth : 16;
		CeeVee : 16;
	}
}

header_type Raven {
	fields {
		Pettry : 24;
		Kanorado : 24;
		Linganore : 24;
		LaConner : 24;
		Vallejo : 24;
		Lakota : 24;
		Sidon : 24;
		Gobles : 24;
		Tatum : 16;
		Toano : 16;
		Kaluaaha : 16;
		Marfa : 16;
		Unionvale : 12;
		PineLake : 3;
		Konnarock : 1;
		Cypress : 3;
		FortShaw : 1;
		Parmerton : 1;
		Champlin : 1;
		Trevorton : 1;
		Edgemont : 1;
		Truro : 1;
		Fergus : 8;
		Weehawken : 12;
		Pearland : 4;
		LaneCity : 6;
		LeeCity : 10;
		Nickerson : 9;
		McMurray : 1;
	}
}


header_type Filley {
	fields {
		Coverdale : 8;
		Lathrop : 1;
		Vigus : 1;
		Mosinee : 1;
		Bellport : 1;
		Sequim : 1;
	}
}

header_type PinkHill {
	fields {
		Tramway : 32;
		Colona : 32;
		Quealy : 6;
		BarNunn : 16;
	}
}

header_type Niota {
	fields {
		ElPrado : 128;
		Danville : 128;
		Sylvester : 20;
		Boring : 8;
		Lenoir : 11;
		Steele : 8;
		Dixie : 13;
	}
}

header_type Coyote {
	fields {
		Tampa : 14;
		Holliston : 1;
		Phelps : 12;
		Anniston : 1;
		Graford : 1;
		Chehalis : 6;
		OldMinto : 2;
		Bernard : 6;
		Waxhaw : 3;
	}
}

header_type Amite {
	fields {
		Plandome : 1;
		Altadena : 1;
	}
}

header_type Dubuque {
	fields {
		Scherr : 8;
	}
}

header_type Casselman {
	fields {
		Cleta : 16;
		Paisley : 11;
	}
}

header_type Hanford {
	fields {
		Arvonia : 32;
		Worthing : 32;
		Carlson : 32;
	}
}

header_type ArchCape {
	fields {
		Gifford : 32;
		Monowi : 32;
	}
}

header_type Purley {
	fields {
		Brady : 8;
		Gardiner : 4;
		Annawan : 15;
		Jayton : 1;
	}
}


header_type Reynolds {
	fields {
		Progreso : 8;
		Toluca : 16;
		Rayville : 16;
		Suamico : 8;
		Paxtonia : 6;
		Kenton : 16;
		Daphne : 16;
		Novice : 8;
		Flippen : 8;
		Bokeelia : 4;
		JaneLew : 1;
		Sylva : 1;
		Buckholts : 18;
	}
}

header_type McGovern {
	fields {
		Harvard : 24;
	}
}

#endif



#ifndef Crouch
#define Crouch


header_type LeaHill {
	fields {
		Camilla : 6;
		Wells : 10;
		Dunnellon : 4;
		Minburn : 12;
		Hodge : 12;
		Allyn : 2;
		Madras : 2;
		Calimesa : 8;
		Baltimore : 3;
		Antlers : 5;
	}
}



header_type Center {
	fields {
		Blanchard : 24;
		Nathalie : 24;
		Laramie : 24;
		Wolcott : 24;
		Villanova : 16;
	}
}



header_type Yakima {
	fields {
		Deerwood : 3;
		Isleta : 1;
		Doyline : 12;
		Mendocino : 16;
	}
}



header_type Moylan {
	fields {
		Sallisaw : 4;
		Pendroy : 4;
		Dundalk : 6;
		Homeacre : 2;
		Libby : 16;
		Adair : 16;
		Arcanum : 3;
		Hewitt : 13;
		Boysen : 8;
		Pineridge : 8;
		Dilia : 16;
		Blunt : 32;
		Clermont : 32;
	}
}

header_type DeepGap {
	fields {
		Cuprum : 4;
		Leola : 6;
		Keachi : 2;
		Finley : 20;
		Neubert : 16;
		Criner : 8;
		Trail : 8;
		WestEnd : 128;
		Plateau : 128;
	}
}




header_type Hydaburg {
	fields {
		Laurie : 8;
		McClusky : 8;
		Azusa : 16;
	}
}

header_type Hobart {
	fields {
		Liberal : 16;
		Clearco : 16;
	}
}

header_type Bixby {
	fields {
		Sanatoga : 32;
		Greenhorn : 32;
		Lemoyne : 4;
		Urbanette : 4;
		Molson : 8;
		Ericsburg : 16;
		Wittman : 16;
		Guion : 16;
	}
}

header_type Almont {
	fields {
		Overbrook : 16;
		Bolckow : 16;
	}
}



header_type Felida {
	fields {
		SnowLake : 16;
		Olmitz : 16;
		Algoa : 8;
		JimFalls : 8;
		HighRock : 16;
	}
}

header_type Kotzebue {
	fields {
		Cowpens : 48;
		Melrude : 32;
		Bellmead : 48;
		Emmalane : 32;
	}
}



header_type GunnCity {
	fields {
		Vinings : 1;
		Belview : 1;
		Recluse : 1;
		Compton : 1;
		Mattapex : 1;
		Harvest : 3;
		KawCity : 5;
		Raytown : 3;
		Havertown : 16;
	}
}

header_type Brookneal {
	fields {
		Brookside : 24;
		Bergton : 8;
	}
}



header_type Stamford {
	fields {
		Neuse : 8;
		Wellford : 24;
		Panaca : 24;
		Amherst : 8;
	}
}

#endif



#ifndef Haines
#define Haines

#define Mossville        0x8100
#define Storden        0x0800
#define Tonkawa        0x86dd
#define Pickering        0x9100
#define Larchmont        0x8847
#define Twain         0x0806
#define Chaffey        0x8035
#define Boquillas        0x88cc
#define Sedan        0x8809
#define Muncie      0xBF00

#define Craigtown              1
#define Hackney              2
#define Everett              4
#define Hulbert               6
#define HornLake               17
#define Hearne                47

#define Sabina         0x501
#define Sawyer          0x506
#define Mangham          0x511
#define Kevil          0x52F


#define Elysburg                 4789



#define Rexville               0
#define Woodfords              1
#define Davant                2



#define PawCreek          0
#define Parmelee          4095
#define Northcote  4096
#define Ankeny  8191



#define Macedonia                      0
#define Corona                  0
#define Conda                 1

header Center Nuangola;
header Center RockHill;
header Yakima Pineville[ 2 ];



@pragma pa_fragment ingress Lakebay.Dilia
@pragma pa_fragment egress Lakebay.Dilia
header Moylan Lakebay;

@pragma pa_fragment ingress Gosnell.Dilia
@pragma pa_fragment egress Gosnell.Dilia
header Moylan Gosnell;

header DeepGap Kahului;
header DeepGap Salome;
header Hobart ElLago;
header Hobart Linden;
header Bixby Kinsley;
header Almont Wauseon;

header Bixby Sanford;
header Almont Veteran;
header Stamford Skyline;
header Felida Excel;
header GunnCity DeerPark;
header LeaHill LaFayette;
header Center Durant;

parser start {
   return select(current(96, 16)) {
      Muncie : McCammon;
      default : NewTrier;
   }
}

parser MuleBarn {
   extract( LaFayette );
   return NewTrier;
}

parser McCammon {
   extract( Durant );
   return MuleBarn;
}

parser NewTrier {
   extract( Nuangola );
   return select( Nuangola.Villanova ) {
      Mossville : Pumphrey;
      Storden : PawPaw;
      Tonkawa : Kinard;
      Twain  : Atlasburg;
      default        : ingress;
   }
}

parser Pumphrey {
   extract( Pineville[0] );
   set_metadata(McManus.Cathcart, 1);
   return select( Pineville[0].Mendocino ) {
      Storden : PawPaw;
      Tonkawa : Kinard;
      Twain  : Atlasburg;
      default : ingress;
   }
}

field_list Ripon {
    Lakebay.Sallisaw;
    Lakebay.Pendroy;
    Lakebay.Dundalk;
    Lakebay.Homeacre;
    Lakebay.Libby;
    Lakebay.Adair;
    Lakebay.Arcanum;
    Lakebay.Hewitt;
    Lakebay.Boysen;
    Lakebay.Pineridge;
    Lakebay.Blunt;
    Lakebay.Clermont;
}

field_list_calculation Shelbiana {
    input {
        Ripon;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field Lakebay.Dilia  {
    verify Shelbiana;
    update Shelbiana;
}

parser PawPaw {
   extract( Lakebay );
   set_metadata(McManus.Bethesda, Lakebay.Pineridge);
   set_metadata(McManus.Poulsbo, Lakebay.Boysen);
   set_metadata(McManus.Waring, Lakebay.Libby);
   set_metadata(McManus.MintHill, 0);
   set_metadata(McManus.Fernway, 1);
   return select(Lakebay.Hewitt, Lakebay.Pendroy, Lakebay.Pineridge) {
      Sabina : Skiatook;
      Mangham : Mickleton;
      Sawyer : Argentine;
      default : ingress;
   }
}

parser Kinard {
   extract( Salome );
   set_metadata(McManus.Bethesda, Salome.Criner);
   set_metadata(McManus.Poulsbo, Salome.Trail);
   set_metadata(McManus.Waring, Salome.Neubert);
   set_metadata(McManus.MintHill, 1);
   set_metadata(McManus.Fernway, 0);
   return select(Salome.Criner) {
      Craigtown : Skiatook;
      HornLake : Connell;
      Hulbert : Argentine;
      default : ingress;
   }
}

parser Atlasburg {
   extract( Excel );
   return ingress;
}

parser Mickleton {
   extract(ElLago);
   extract(Wauseon);
   return select(ElLago.Clearco) {
      Elysburg : Bowden;
      default : ingress;
    }
}

parser Skiatook {


   extract(ElLago);
   set_metadata( ElLago.Clearco, 0 );
   return ingress;
}

parser Connell {
   extract(ElLago);
   extract(Wauseon);
   return ingress;
}

parser Argentine {
   extract(ElLago);
   extract(Kinsley);
   return ingress;
}

parser National {
   set_metadata(Horton.Delmont, Davant);
   return Lueders;
}

parser Coalton {
   set_metadata(Horton.Delmont, Davant);
   return Waynoka;
}

parser Willmar {
   extract(DeerPark);
   return select(DeerPark.Vinings, DeerPark.Belview, DeerPark.Recluse, DeerPark.Compton, DeerPark.Mattapex,
             DeerPark.Harvest, DeerPark.KawCity, DeerPark.Raytown, DeerPark.Havertown) {
      Storden : National;
      Tonkawa : Coalton;
      default : ingress;
   }
}

parser Bowden {
   extract(Skyline);
   set_metadata(Horton.Delmont, Woodfords);
   return Tinsman;
}

field_list Kasilof {
    Gosnell.Sallisaw;
    Gosnell.Pendroy;
    Gosnell.Dundalk;
    Gosnell.Homeacre;
    Gosnell.Libby;
    Gosnell.Adair;
    Gosnell.Arcanum;
    Gosnell.Hewitt;
    Gosnell.Boysen;
    Gosnell.Pineridge;
    Gosnell.Blunt;
    Gosnell.Clermont;
}

field_list_calculation Equality {
    input {
        Kasilof;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field Gosnell.Dilia  {
    verify Equality;
    update Equality;
}

parser Lueders {
   extract( Gosnell );
   set_metadata(McManus.Skime, Gosnell.Pineridge);
   set_metadata(McManus.Okaton, Gosnell.Boysen);
   set_metadata(McManus.Ballwin, Gosnell.Libby);
   set_metadata(McManus.McCleary, 0);
   set_metadata(McManus.Mingus, 1);
   return select(Gosnell.Hewitt, Gosnell.Pendroy, Gosnell.Pineridge) {
      Sabina : Cowles;
      Mangham : Shelby;
      Sawyer : Paskenta;
      default : ingress;
   }
}

parser Waynoka {
   extract( Kahului );
   set_metadata(McManus.Skime, Kahului.Criner);
   set_metadata(McManus.Okaton, Kahului.Trail);
   set_metadata(McManus.Ballwin, Kahului.Neubert);
   set_metadata(McManus.McCleary, 1);
   set_metadata(McManus.Mingus, 0);
   return select(Kahului.Criner) {
      Craigtown : Cowles;
      HornLake : Shelby;
      Hulbert : Paskenta;
      default : ingress;
   }
}



parser Cowles {

   set_metadata( Horton.Wentworth, current( 0, 16 ) );
   return ingress;
}

parser Shelby {
   set_metadata( Horton.Wentworth, current( 0, 16 ) );
   set_metadata( Horton.CeeVee, current( 16, 16 ) );
   return ingress;
}

parser Paskenta {
   set_metadata( Horton.Wentworth, current( 0, 16 ) );
   set_metadata( Horton.CeeVee, current( 16, 16 ) );

   extract(Linden);
   extract(Sanford);
   return ingress;
}

parser Tinsman {
   extract( RockHill );
   return select( RockHill.Villanova ) {
      Storden: Lueders;
      Tonkawa: Waynoka;
      default: ingress;
   }
}
#endif

metadata Hughson Horton;
metadata Raven Orrum;
metadata Coyote Ulysses;
metadata Weathers McManus;
metadata PinkHill Selby;
metadata Niota Blanding;
metadata Amite Goodwater;
metadata Filley Youngtown;
metadata Dubuque Cantwell;
metadata Casselman Hitterdal;
metadata ArchCape Bayport;
metadata Hanford Bieber;
metadata Purley Tillamook;

metadata Reynolds Woodston;
metadata Reynolds Newsome;
metadata Reynolds Buncombe;
metadata Reynolds Excello;
metadata Reynolds Deeth;
metadata Reynolds OldGlory;
metadata Reynolds Oskawalik;
metadata Reynolds Inola;
metadata McGovern Lewistown;













#undef Elkins

#undef Tolley
#undef Marley
#undef Hiland
#undef Hillside
#undef Pikeville

#undef Joseph
#undef Notus
#undef Brockton

#undef Paullina
#undef ElRio
#undef Troup
#undef Cropper
#undef Frontenac
#undef Lostine
#undef Harshaw
#undef Lilly
#undef Valentine
#undef Cornell
#undef Ripley
#undef PaloAlto
#undef Roodhouse
#undef Jamesport
#undef Joiner
#undef Gibbstown
#undef Kettering
#undef DuQuoin
#undef Colburn
#undef Kingsland
#undef Colonie

#undef Kennebec
#undef Mattoon
#undef Ferndale
#undef Chatawa
#undef Miltona
#undef Strevell
#undef Dagmar
#undef MontIda
#undef Nowlin
#undef Teigen
#undef Ossipee
#undef Faulkner
#undef Covelo
#undef Slana
#undef Exeland
#undef Albany
#undef Swain
#undef Contact
#undef Fiskdale
#undef FlyingH
#undef Duffield

#undef Pinta
#undef Gerster

#undef Inverness

#undef Hobucken
#undef Simnasho







#define Elkins 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Tolley      65536
#define Marley      65536
#define Hiland 512
#define Hillside 512
#define Pikeville      512


#define Joseph     1024
#define Notus    1024
#define Brockton     256


#define Paullina 512
#define ElRio 65536
#define Troup 65536
#define Cropper 28672
#define Frontenac   16384
#define Lostine 8192
#define Harshaw         131072
#define Lilly 65536
#define Valentine 1024
#define Cornell 2048
#define Ripley 16384
#define PaloAlto 8192
#define Roodhouse 65536

#define Jamesport 0x0000000000000000FFFFFFFFFFFFFFFF


#define Joiner 0x000fffff
#define DuQuoin 2

#define Gibbstown 0xFFFFFFFFFFFFFFFF0000000000000000

#define Kettering 0x000007FFFFFFFFFF0000000000000000
#define Colburn  6
#define Colonie        2048
#define Kingsland       65536


#define Kennebec 1024
#define Mattoon 4096
#define Ferndale 4096
#define Chatawa 4096
#define Miltona 4096
#define Strevell 1024
#define Dagmar 4096
#define Nowlin 128
#define Teigen 1
#define Ossipee  8


#define Faulkner 512
#define Pinta 512
#define Gerster 256


#define Covelo 2
#define Slana 3
#define Exeland 80



#define Albany 512
#define Swain 512
#define Contact 512
#define Fiskdale 512

#define FlyingH 2048
#define Duffield 1024



#define Inverness 0


#define Hobucken    4096
#define Simnasho    1024

#endif



#ifndef Allons
#define Allons

action McCartys() {
   no_op();
}

action Bunker() {
   modify_field(Horton.Latham, 1 );
   mark_for_drop();
}

action Careywood() {
   no_op();
}
#endif




#define Minto            0
#define Gurdon  1
#define Basco 2


#define Melba              0
#define Tusculum             1
#define Newcastle 2


















action Lajitas(Brainard, Lubec, Washoe, RedElm, Bleecker, Leeville,
                 Philippi, Dunnegan, Tidewater) {
    modify_field(Ulysses.Tampa, Brainard);
    modify_field(Ulysses.Holliston, Lubec);
    modify_field(Ulysses.Phelps, Washoe);
    modify_field(Ulysses.Anniston, RedElm);
    modify_field(Ulysses.Graford, Bleecker);
    modify_field(Ulysses.Chehalis, Leeville);
    modify_field(Ulysses.OldMinto, Philippi);
    modify_field(Ulysses.Waxhaw, Dunnegan);
    modify_field(Ulysses.Bernard, Tidewater);
}

@pragma command_line --no-dead-code-elimination
table Sammamish {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Lajitas;
    }
    size : Elkins;
}

control Twinsburg {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Sammamish);
    }
}





action Carlsbad(Meyers) {
   modify_field( Orrum.Konnarock, 1 );
   modify_field( Orrum.Fergus, Meyers);
   modify_field( Horton.Portville, 1 );
}

action Exeter() {
   modify_field( Horton.Clearlake, 1 );
   modify_field( Horton.Rendon, 1 );
}

action Westel() {
   modify_field( Horton.Portville, 1 );
}

action Vantage() {
   modify_field( Horton.Traskwood, 1 );
}

action Correo() {
   modify_field( Horton.Rendon, 1 );
}

counter Pearson {
   type : packets_and_bytes;
   direct : Swisshome;
   min_width: 16;
}

table Swisshome {
   reads {
      Ulysses.Chehalis : exact;
      Nuangola.Blanchard : ternary;
      Nuangola.Nathalie : ternary;
   }

   actions {
      Carlsbad;
      Exeter;
      Westel;
      Vantage;
      Correo;
   }
   size : Hiland;
}

action Mendon() {
   modify_field( Horton.TiePlant, 1 );
}


table Pawtucket {
   reads {
      Nuangola.Laramie : ternary;
      Nuangola.Wolcott : ternary;
   }

   actions {
      Mendon;
   }
   size : Hillside;
}


control Lewes {
   apply( Swisshome );
   apply( Pawtucket );
}




action DelRosa() {
   modify_field( Selby.Tramway, Gosnell.Blunt );
   modify_field( Selby.Colona, Gosnell.Clermont );
   modify_field( Selby.Quealy, Gosnell.Dundalk );
   modify_field( Blanding.ElPrado, Kahului.WestEnd );
   modify_field( Blanding.Danville, Kahului.Plateau );
   modify_field( Blanding.Sylvester, Kahului.Finley );
   modify_field( Blanding.Steele, Kahului.Leola );
   modify_field( Horton.Haslet, RockHill.Blanchard );
   modify_field( Horton.Pinecrest, RockHill.Nathalie );
   modify_field( Horton.Yardley, RockHill.Laramie );
   modify_field( Horton.Washta, RockHill.Wolcott );
   modify_field( Horton.Lublin, RockHill.Villanova );
   modify_field( Horton.Anawalt, McManus.Ballwin );
   modify_field( Horton.Kealia, McManus.Skime );
   modify_field( Horton.Floyd, McManus.Okaton );
   modify_field( Horton.Lewiston, McManus.Mingus );
   modify_field( Horton.Thistle, McManus.McCleary );
   modify_field( Horton.Roswell, 0 );
   modify_field( Ulysses.OldMinto, 2 );
   modify_field( Ulysses.Waxhaw, 0 );
   modify_field( Ulysses.Bernard, 0 );
   modify_field( Orrum.Cypress, Tusculum );
}

action Creston() {
   modify_field( Horton.Delmont, Rexville );
   modify_field( Selby.Tramway, Lakebay.Blunt );
   modify_field( Selby.Colona, Lakebay.Clermont );
   modify_field( Selby.Quealy, Lakebay.Dundalk );
   modify_field( Blanding.ElPrado, Salome.WestEnd );
   modify_field( Blanding.Danville, Salome.Plateau );
   modify_field( Blanding.Sylvester, Salome.Finley );
   modify_field( Blanding.Steele, Salome.Leola );
   modify_field( Horton.Haslet, Nuangola.Blanchard );
   modify_field( Horton.Pinecrest, Nuangola.Nathalie );
   modify_field( Horton.Yardley, Nuangola.Laramie );
   modify_field( Horton.Washta, Nuangola.Wolcott );
   modify_field( Horton.Lublin, Nuangola.Villanova );
   modify_field( Horton.Anawalt, McManus.Waring );
   modify_field( Horton.Kealia, McManus.Bethesda );
   modify_field( Horton.Floyd, McManus.Poulsbo );
   modify_field( Horton.Lewiston, McManus.Fernway );
   modify_field( Horton.Thistle, McManus.MintHill );
   modify_field( Horton.Winfall, Pineville[0].Isleta );
   modify_field( Horton.Roswell, McManus.Cathcart );
   modify_field( Horton.Wentworth, ElLago.Liberal );
   modify_field( Horton.CeeVee, ElLago.Clearco );
}

table Barney {
   reads {
      Nuangola.Blanchard : exact;
      Nuangola.Nathalie : exact;
      Lakebay.Clermont : exact;
      Horton.Delmont : exact;
   }

   actions {
      DelRosa;
      Creston;
   }

   default_action : Creston();
   size : Kennebec;
}


action Ocilla() {
   modify_field( Horton.Ivanhoe, Ulysses.Phelps );
   modify_field( Horton.Edler, Ulysses.Tampa);
}

action Cacao( Claypool ) {
   modify_field( Horton.Ivanhoe, Claypool );
   modify_field( Horton.Edler, Ulysses.Tampa);
}

action Moreland() {
   modify_field( Horton.Ivanhoe, Pineville[0].Doyline );
   modify_field( Horton.Edler, Ulysses.Tampa);
}

table Harris {
   reads {
      Ulysses.Tampa : ternary;
      Pineville[0] : valid;
      Pineville[0].Doyline : ternary;
   }

   actions {
      Ocilla;
      Cacao;
      Moreland;
   }
   size : Chatawa;
}

action Idalia( Kniman ) {
   modify_field( Horton.Edler, Kniman );
}

action Wheaton() {

   modify_field( Horton.Cadwell, 1 );
   modify_field( Cantwell.Scherr,
                 Conda );
}

table Harriston {
   reads {
      Lakebay.Blunt : exact;
   }

   actions {
      Idalia;
      Wheaton;
   }
   default_action : Wheaton;
   size : Ferndale;
}

action Kingman( Perkasie, Virgilina, Peebles, Kerby, Weslaco,
                        Fries, Radom ) {
   modify_field( Horton.Ivanhoe, Perkasie );
   modify_field( Horton.Aquilla, Perkasie );
   modify_field( Horton.Onida, Radom );
   Hagewood(Virgilina, Peebles, Kerby, Weslaco,
                        Fries );
}

action Crossett() {
   modify_field( Horton.Yukon, 1 );
}

table Dalkeith {
   reads {
      Skyline.Panaca : exact;
   }

   actions {
      Kingman;
      Crossett;
   }
   size : Mattoon;
}

action Hagewood(Natalbany, Alamance, Kaupo, Perryman,
                        Tatitlek ) {
   modify_field( Youngtown.Coverdale, Natalbany );
   modify_field( Youngtown.Lathrop, Alamance );
   modify_field( Youngtown.Mosinee, Kaupo );
   modify_field( Youngtown.Vigus, Perryman );
   modify_field( Youngtown.Bellport, Tatitlek );
}

action Longmont(Minneiska, Topsfield, Teaneck, Bogota,
                        Seagate ) {
   modify_field( Horton.Aquilla, Ulysses.Phelps );
   modify_field( Horton.Onida, 1 );
   Hagewood(Minneiska, Topsfield, Teaneck, Bogota,
                        Seagate );
}

action Seibert(SandLake, Calabash, Molino, Hurdtown,
                        DuBois, Manning ) {
   modify_field( Horton.Aquilla, SandLake );
   modify_field( Horton.Onida, 1 );
   Hagewood(Calabash, Molino, Hurdtown, DuBois,
                        Manning );
}

action Bienville(Slagle, NorthRim, Reading, Knolls,
                        Onamia ) {
   modify_field( Horton.Aquilla, Pineville[0].Doyline );
   modify_field( Horton.Onida, 1 );
   Hagewood(Slagle, NorthRim, Reading, Knolls,
                        Onamia );
}

table Wanilla {
   reads {
      Ulysses.Phelps : exact;
   }


   actions {
      McCartys;
      Longmont;
   }

   size : Miltona;
}

@pragma action_default_only McCartys
table Onslow {
   reads {
      Ulysses.Tampa : exact;
      Pineville[0].Doyline : exact;
   }

   actions {
      Seibert;
      McCartys;
   }

   size : Strevell;
}

table Bacton {
   reads {
      Pineville[0].Doyline : exact;
   }


   actions {
      McCartys;
      Bienville;
   }

   size : Dagmar;
}

control Penitas {
   apply( Barney ) {
         DelRosa {
            apply( Harriston );
            apply( Dalkeith );
         }
         Creston {
            if ( not valid(LaFayette) and Ulysses.Anniston == 1 ) {
               apply( Harris );
            }
            if ( valid( Pineville[ 0 ] ) ) {

               apply( Onslow ) {
                  McCartys {

                     apply( Bacton );
                  }
               }
            } else {

               apply( Wanilla );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Helotes {
    width  : 1;
    static : Ledger;
    instance_count : 262144;
}

register Bloomdale {
    width  : 1;
    static : Lawai;
    instance_count : 262144;
}

blackbox stateful_alu Leoma {
    reg : Helotes;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Goodwater.Plandome;
}

blackbox stateful_alu Rodessa {
    reg : Bloomdale;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Goodwater.Altadena;
}

field_list McClure {
    Ulysses.Chehalis;
    Pineville[0].Doyline;
}

field_list_calculation PellCity {
    input { McClure; }
    algorithm: identity;
    output_width: 18;
}

action Powelton() {
    Leoma.execute_stateful_alu_from_hash(PellCity);
}

action Cutler() {
    Rodessa.execute_stateful_alu_from_hash(PellCity);
}

table Ledger {
    actions {
      Powelton;
    }
    default_action : Powelton;
    size : 1;
}

table Lawai {
    actions {
      Cutler;
    }
    default_action : Cutler;
    size : 1;
}
#endif

action Ambler(Rawson) {
    modify_field(Goodwater.Altadena, Rawson);
}

@pragma  use_hash_action 0
table Kiron {
    reads {
       Ulysses.Chehalis : exact;
    }
    actions {
      Ambler;
    }
    size : 64;
}

action Buckhorn() {
   modify_field( Horton.Malabar, Ulysses.Phelps );
   modify_field( Horton.Amboy, 0 );
}

table Callands {
   actions {
      Buckhorn;
   }
   size : 1;
}

action Forepaugh() {
   modify_field( Horton.Malabar, Pineville[0].Doyline );
   modify_field( Horton.Amboy, 1 );
}

table Lovilia {
   actions {
      Forepaugh;
   }
   size : 1;
}

control Montegut {
   if ( valid( Pineville[ 0 ] ) ) {
      apply( Lovilia );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Ulysses.Graford == 1 ) {
         apply( Ledger );
         apply( Lawai );
      }
#endif
   } else {
      apply( Callands );
      if( Ulysses.Graford == 1 ) {
         apply( Kiron );
      }
   }
}




field_list Newhalen {
   Nuangola.Blanchard;
   Nuangola.Nathalie;
   Nuangola.Laramie;
   Nuangola.Wolcott;
   Nuangola.Villanova;
}

field_list Waldport {

   Lakebay.Pineridge;
   Lakebay.Blunt;
   Lakebay.Clermont;
}

field_list Blueberry {
   Salome.WestEnd;
   Salome.Plateau;
   Salome.Finley;
   Salome.Criner;
}

field_list Mahopac {
   Lakebay.Blunt;
   Lakebay.Clermont;
   ElLago.Liberal;
   ElLago.Clearco;
}





field_list_calculation Berwyn {
    input {
        Newhalen;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Oldsmar {
    input {
        Waldport;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Ignacio {
    input {
        Blueberry;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Calcasieu {
    input {
        Mahopac;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Fillmore() {
    modify_field_with_hash_based_offset(Bieber.Arvonia, 0,
                                        Berwyn, 4294967296);
}

action Nuyaka() {
    modify_field_with_hash_based_offset(Bieber.Worthing, 0,
                                        Oldsmar, 4294967296);
}

action KeyWest() {
    modify_field_with_hash_based_offset(Bieber.Worthing, 0,
                                        Ignacio, 4294967296);
}

action Wamego() {
    modify_field_with_hash_based_offset(Bieber.Carlson, 0,
                                        Calcasieu, 4294967296);
}

table Goessel {
   actions {
      Fillmore;
   }
   size: 1;
}

control Garwood {
   apply(Goessel);
}

table Valeene {
   actions {
      Nuyaka;
   }
   size: 1;
}

table Minoa {
   actions {
      KeyWest;
   }
   size: 1;
}

control Boquet {
   if ( valid( Lakebay ) ) {
      apply(Valeene);
   } else {
      if ( valid( Salome ) ) {
         apply(Minoa);
      }
   }
}

table Roosville {
   actions {
      Wamego;
   }
   size: 1;
}

control Grampian {
   if ( valid( Wauseon ) ) {
      apply(Roosville);
   }
}



action Waretown() {
    modify_field(Bayport.Gifford, Bieber.Arvonia);
}

action Neches() {
    modify_field(Bayport.Gifford, Bieber.Worthing);
}

action Saragosa() {
    modify_field(Bayport.Gifford, Bieber.Carlson);
}

@pragma action_default_only McCartys
@pragma immediate 0
table Tiller {
   reads {
      Sanford.valid : ternary;
      Veteran.valid : ternary;
      Gosnell.valid : ternary;
      Kahului.valid : ternary;
      RockHill.valid : ternary;
      Kinsley.valid : ternary;
      Wauseon.valid : ternary;
      Lakebay.valid : ternary;
      Salome.valid : ternary;
      Nuangola.valid : ternary;
   }
   actions {
      Waretown;
      Neches;
      Saragosa;
      McCartys;
   }
   size: Brockton;
}

action LasVegas() {
    modify_field(Bayport.Monowi, Bieber.Carlson);
}

@pragma immediate 0
table Westway {
   reads {
      Sanford.valid : ternary;
      Veteran.valid : ternary;
      Kinsley.valid : ternary;
      Wauseon.valid : ternary;
   }
   actions {
      LasVegas;
      McCartys;
   }
   size: Colburn;
}

control Amenia {
   apply(Westway);
   apply(Tiller);
}



counter Garrison {
   type : packets_and_bytes;
   direct : Slovan;
   min_width: 16;
}

table Slovan {
   reads {
      Ulysses.Chehalis : exact;
      Goodwater.Altadena : ternary;
      Goodwater.Plandome : ternary;
      Horton.Yukon : ternary;
      Horton.TiePlant : ternary;
      Horton.Clearlake : ternary;
   }

   actions {
      Bunker;
      McCartys;
   }
   default_action : McCartys();
   size : Pikeville;
}

action Agawam() {

   modify_field(Horton.FoxChase, 1 );
   modify_field(Cantwell.Scherr,
                Corona);
}







table Onawa {
   reads {
      Horton.Yardley : exact;
      Horton.Washta : exact;
      Horton.Ivanhoe : exact;
      Horton.Edler : exact;
   }

   actions {
      Careywood;
      Agawam;
   }
   default_action : Agawam();
   size : Marley;
   support_timeout : true;
}

action Zebina() {
   modify_field( Youngtown.Sequim, 1 );
}

table Pidcoke {
   reads {
      Horton.Aquilla : ternary;
      Horton.Haslet : exact;
      Horton.Pinecrest : exact;
   }
   actions {
      Zebina;
   }
   size: Paullina;
}

control Suarez {
   apply( Slovan ) {
      McCartys {



         if (Ulysses.Holliston == 0 and Horton.Cadwell == 0) {
            apply( Onawa );
         }
         apply(Pidcoke);
      }
   }
}

field_list Belgrade {
    Cantwell.Scherr;
    Horton.Yardley;
    Horton.Washta;
    Horton.Ivanhoe;
    Horton.Edler;
}

action Loyalton() {
   generate_digest(Macedonia, Belgrade);
}

table Mizpah {
   actions {
      Loyalton;
   }
   size : 1;
}

control Huxley {
   if (Horton.FoxChase == 1) {
      apply( Mizpah );
   }
}



action Hoagland( Ranchito, Ronda ) {
   modify_field( Blanding.Dixie, Ranchito );
   modify_field( Hitterdal.Cleta, Ronda );
}

@pragma action_default_only Rowlett
table Ceiba {
   reads {
      Youngtown.Coverdale : exact;
      Blanding.Danville mask Gibbstown : lpm;
   }
   actions {
      Hoagland;
      Rowlett;
   }
   size : PaloAlto;
}

@pragma atcam_partition_index Blanding.Dixie
@pragma atcam_number_partitions PaloAlto
table Asher {
   reads {
      Blanding.Dixie : exact;
      Blanding.Danville mask Kettering : lpm;
   }

   actions {
      Mentone;
      Westpoint;
      McCartys;
   }
   default_action : McCartys();
   size : Roodhouse;
}

action Shirley( Rosebush, Suffolk ) {
   modify_field( Blanding.Lenoir, Rosebush );
   modify_field( Hitterdal.Cleta, Suffolk );
}

@pragma action_default_only McCartys
table Oneonta {


   reads {
      Youngtown.Coverdale : exact;
      Blanding.Danville : lpm;
   }

   actions {
      Shirley;
      McCartys;
   }

   size : Cornell;
}

@pragma atcam_partition_index Blanding.Lenoir
@pragma atcam_number_partitions Cornell
table Estero {
   reads {
      Blanding.Lenoir : exact;


      Blanding.Danville mask Jamesport : lpm;
   }
   actions {
      Mentone;
      Westpoint;
      McCartys;
   }

   default_action : McCartys();
   size : Ripley;
}

@pragma action_default_only Rowlett
@pragma idletime_precision 1
table Topanga {

   reads {
      Youngtown.Coverdale : exact;
      Selby.Colona : lpm;
   }

   actions {
      Mentone;
      Westpoint;
      Rowlett;
   }

   size : Valentine;
   support_timeout : true;
}

action Armijo( Halfa, Karluk ) {
   modify_field( Selby.BarNunn, Halfa );
   modify_field( Hitterdal.Cleta, Karluk );
}

@pragma action_default_only McCartys
#ifdef PROFILE_DEFAULT


#endif
table Domingo {
   reads {
      Youngtown.Coverdale : exact;
      Selby.Colona : lpm;
   }

   actions {
      Armijo;
      McCartys;
   }

   size : Frontenac;
}

@pragma ways DuQuoin
@pragma atcam_partition_index Selby.BarNunn
@pragma atcam_number_partitions Frontenac
table Roseau {
   reads {
      Selby.BarNunn : exact;
      Selby.Colona mask Joiner : lpm;
   }
   actions {
      Mentone;
      Westpoint;
      McCartys;
   }
   default_action : McCartys();
   size : Harshaw;
}

action Mentone( Madill ) {
   modify_field( Hitterdal.Cleta, Madill );
}

@pragma idletime_precision 1
table Thurmond {
   reads {
      Youngtown.Coverdale : exact;
      Selby.Colona : exact;
   }

   actions {
      Mentone;
      Westpoint;
      McCartys;
   }
   default_action : McCartys();
   size : ElRio;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT


#endif
table Heizer {
   reads {
      Youngtown.Coverdale : exact;
      Blanding.Danville : exact;
   }

   actions {
      Mentone;
      Westpoint;
      McCartys;
   }
   default_action : McCartys();
   size : Troup;
   support_timeout : true;
}

action Trion(Grassy, Loring, Halltown) {
   modify_field(Orrum.Tatum, Halltown);
   modify_field(Orrum.Pettry, Grassy);
   modify_field(Orrum.Kanorado, Loring);
   modify_field(Orrum.McMurray, 1);
}

action BoxElder() {
   Bunker();
}

action Mesita(Newkirk) {
   modify_field(Orrum.Konnarock, 1);
   modify_field(Orrum.Fergus, Newkirk);
}

action Rowlett() {
   modify_field( Orrum.Konnarock, 1 );
   modify_field( Orrum.Fergus, 9 );
}

table Bavaria {
   reads {
      Hitterdal.Cleta : exact;
   }

   actions {
      Trion;
      BoxElder;
      Mesita;
   }
   size : Lilly;
}

control DelMar {
   if ( Horton.Latham == 0 and Youngtown.Sequim == 1 ) {
      if ( ( Youngtown.Lathrop == 1 ) and ( Horton.Lewiston == 1 ) ) {
         apply( Thurmond ) {
            McCartys {
               apply( Domingo ) {
                  Armijo {
                     apply( Roseau );
                  }
                  McCartys {
                     apply( Topanga );
                  }
               }
            }
         }
      } else if ( ( Youngtown.Mosinee == 1 ) and ( Horton.Thistle == 1 ) ) {
         apply( Heizer ) {
            McCartys {
               apply( Oneonta ) {
                  Shirley {
                     apply( Estero );
                  }
                  McCartys {

                     apply( Ceiba ) {
                        Hoagland {
                           apply( Asher );
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Coconino {
   if( Hitterdal.Cleta != 0 ) {
      apply( Bavaria );
   }
}

action Westpoint( Lostwood ) {
   modify_field( Hitterdal.Paisley, Lostwood );
}

field_list Addison {
   Bayport.Monowi;
}

field_list_calculation Hercules {
    input {
        Addison;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Lamboglia {
   selection_key : Hercules;
   selection_mode : resilient;
}

action_profile Elmdale {
   actions {
      Mentone;
   }
   size : Kingsland;
   dynamic_action_selection : Lamboglia;
}

table Nooksack {
   reads {
      Hitterdal.Paisley : exact;
   }
   action_profile : Elmdale;
   size : Colonie;
}

control Aynor {
   if ( Hitterdal.Paisley != 0 ) {
      apply( Nooksack );
   }
}



field_list Lehigh {
   Bayport.Gifford;
}

field_list_calculation Litroe {
    input {
        Lehigh;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Hemlock {
    selection_key : Litroe;
    selection_mode : resilient;
}

action Turney(Belpre) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Belpre);
}

action_profile Brule {
    actions {
        Turney;
        McCartys;
    }
    size : Notus;
    dynamic_action_selection : Hemlock;
}

table Hooven {
   reads {
      Orrum.Kaluaaha : exact;
   }
   action_profile: Brule;
   size : Joseph;
}

control Kalvesta {
   if ((Orrum.Kaluaaha & 0x2000) == 0x2000) {
      apply(Hooven);
   }
}



action Grinnell() {
   modify_field(Orrum.Pettry, Horton.Haslet);
   modify_field(Orrum.Kanorado, Horton.Pinecrest);
   modify_field(Orrum.Linganore, Horton.Yardley);
   modify_field(Orrum.LaConner, Horton.Washta);
   modify_field(Orrum.Tatum, Horton.Ivanhoe);
}

table Whitten {
   actions {
      Grinnell;
   }
   default_action : Grinnell();
   size : 1;
}

control Matheson {
   if (Horton.Ivanhoe!=0 ) {
      apply( Whitten );
   }
}

action Leflore() {
   modify_field(Orrum.Parmerton, 1);
   modify_field(Orrum.FortShaw, 1);
   modify_field(Orrum.Marfa, Orrum.Tatum);
}

action Ingraham() {
}



@pragma ways 1
table Ihlen {
   reads {
      Orrum.Pettry : exact;
      Orrum.Kanorado : exact;
   }
   actions {
      Leflore;
      Ingraham;
   }
   default_action : Ingraham;
   size : 1;
}

action Wattsburg() {
   modify_field(Orrum.Champlin, 1);
   modify_field(Orrum.Truro, 1);
   add(Orrum.Marfa, Orrum.Tatum, Northcote);
}

table Salix {
   actions {
      Wattsburg;
   }
   default_action : Wattsburg;
   size : 1;
}

action Newtok() {
   modify_field(Orrum.Edgemont, 1);
   modify_field(Orrum.Marfa, Orrum.Tatum);
}

table Cedonia {
   actions {
      Newtok;
   }
   default_action : Newtok();
   size : 1;
}

action Merritt(Fallsburg) {
   modify_field(Orrum.Trevorton, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Fallsburg);
   modify_field(Orrum.Kaluaaha, Fallsburg);
}

action Brunson(Noelke) {
   modify_field(Orrum.Champlin, 1);
   modify_field(Orrum.Marfa, Noelke);
}

action GlenDean() {
}

table Alzada {
   reads {
      Orrum.Pettry : exact;
      Orrum.Kanorado : exact;
      Orrum.Tatum : exact;
   }

   actions {
      Merritt;
      Brunson;
      GlenDean;
   }
   default_action : GlenDean();
   size : Tolley;
}

control Pendleton {
   if (Horton.Latham == 0 and not valid(LaFayette) ) {
      apply(Alzada) {
         GlenDean {
            apply(Ihlen) {
               Ingraham {
                  if ((Orrum.Pettry & 0x010000) == 0x010000) {
                     apply(Salix);
                  } else {
                     apply(Cedonia);
                  }
               }
            }
         }
      }
   }
}

action Willshire() {
   modify_field(Horton.Sabula, 1);
   Bunker();
}

//@pragma stage 10
table Nelagoney {
   actions {
      Willshire;
   }
   default_action : Willshire;
   size : 1;
}

control Marvin {
   if (Horton.Latham == 0) {
      if ((Orrum.McMurray==0) and (Horton.Edler==Orrum.Kaluaaha)) {
         apply(Nelagoney);
      } else {
         Dovray();
      }
   }
}



action Irvine( Snyder ) {
   modify_field( Orrum.Unionvale, Snyder );
}

action Keauhou() {
   modify_field( Orrum.Unionvale, Orrum.Tatum );
}

table Hollymead {
   reads {
      eg_intr_md.egress_port : exact;
      Orrum.Tatum : exact;
   }

   actions {
      Irvine;
      Keauhou;
   }
   default_action : Keauhou;
   size : Hobucken;
}

control Edwards {
   apply( Hollymead );
}



action Currie( Nanson, Harleton ) {
   modify_field( Orrum.Vallejo, Nanson );
   modify_field( Orrum.Lakota, Harleton );
}

action Rapids( Salamatof, Murchison, Fayette, Dedham ) {
   modify_field( Orrum.Vallejo, Salamatof );
   modify_field( Orrum.Lakota, Murchison );
   modify_field( Orrum.Sidon, Fayette );
   modify_field( Orrum.Gobles, Dedham );
}


table Waukegan {
   reads {
      Orrum.PineLake : exact;
   }

   actions {
      Currie;
      Rapids;
   }
   size : Ossipee;
}

action Sharptown(Brackett, Servia, Hackett, Granbury) {
   modify_field( Orrum.LaneCity, Brackett );
   modify_field( Orrum.LeeCity, Servia );
   modify_field( Orrum.Pearland, Hackett );
   modify_field( Orrum.Weehawken, Granbury );
}

table Motley {
   reads {
        Orrum.Nickerson : exact;
   }
   actions {
      Sharptown;
   }
   size : Gerster;
}

action Anandale() {
   no_op();
}

action Fairborn() {
   modify_field( Nuangola.Villanova, Pineville[0].Mendocino );
   remove_header( Pineville[0] );
}

table Sodaville {
   actions {
      Fairborn;
   }
   default_action : Fairborn;
   size : Teigen;
}

action Whitetail() {
   no_op();
}

action Lynch() {
   add_header( Pineville[ 0 ] );
   modify_field( Pineville[0].Doyline, Orrum.Unionvale );
   modify_field( Pineville[0].Mendocino, Nuangola.Villanova );
   modify_field( Pineville[0].Deerwood, Horton.Godley );
   modify_field( Pineville[0].Isleta, Horton.Winfall );
   modify_field( Nuangola.Villanova, Mossville );
}



table Marshall {
   reads {
      Orrum.Unionvale : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Whitetail;
      Lynch;
   }
   default_action : Lynch;
   size : Nowlin;
}

action Padonia() {
   modify_field(Nuangola.Blanchard, Orrum.Pettry);
   modify_field(Nuangola.Nathalie, Orrum.Kanorado);
   modify_field(Nuangola.Laramie, Orrum.Vallejo);
   modify_field(Nuangola.Wolcott, Orrum.Lakota);
}

action Domestic() {
   Padonia();
   add_to_field(Lakebay.Boysen, -1);
}

action Philbrook() {
   Padonia();
   add_to_field(Salome.Trail, -1);
}

action Grainola() {
   Lynch();
}

action Speedway() {
   add_header( Durant );
   modify_field( Durant.Blanchard, Orrum.Vallejo );
   modify_field( Durant.Nathalie, Orrum.Lakota );
   modify_field( Durant.Laramie, Orrum.Sidon );
   modify_field( Durant.Wolcott, Orrum.Gobles );
   modify_field( Durant.Villanova, Muncie );
   add_header( LaFayette );
   modify_field( LaFayette.Camilla, Orrum.LaneCity );
   modify_field( LaFayette.Wells, Orrum.LeeCity );
   modify_field( LaFayette.Dunnellon, Orrum.Pearland );
   modify_field( LaFayette.Minburn, Orrum.Weehawken );
   modify_field( LaFayette.Calimesa, Orrum.Fergus );
}

action Kaolin() {
   remove_header( Skyline );
   remove_header( Wauseon );
   remove_header( ElLago );
   copy_header( Nuangola, RockHill );
   remove_header( RockHill );
   remove_header( Lakebay );
}

action Occoquan() {
   remove_header( Durant );
   remove_header( LaFayette );
}

table Madison {
   reads {
      Orrum.Cypress : exact;
      Orrum.PineLake : exact;
      Orrum.McMurray : exact;
      Lakebay.valid : ternary;
      Salome.valid : ternary;
   }

   actions {
      Domestic;
      Philbrook;
      Grainola;
      Speedway;
      Kaolin;
      Occoquan;
   }
   size : Faulkner;
}

control Longwood {
   apply( Sodaville );
}

control Kaltag {
   apply( Marshall );
}

control Wauconda {
   apply( Waukegan );
   apply( Motley );
   apply( Madison );
}



field_list RedCliff {
    Cantwell.Scherr;
    Horton.Ivanhoe;
    RockHill.Laramie;
    RockHill.Wolcott;
    Lakebay.Blunt;
}

action Hisle() {
   generate_digest(Macedonia, RedCliff);
}

table Langtry {
   actions {
      Hisle;
   }

   default_action : Hisle;
   size : 1;
}

control Timbo {
   if (Horton.Cadwell == 1) {
      apply(Langtry);
   }
}



action Rains( IowaCity ) {
   modify_field( Tillamook.Brady, IowaCity );
}

action Norco() {
   modify_field( Tillamook.Brady, 0 );
}

table Welch {
   reads {
     Horton.Edler : ternary;
     Horton.Aquilla : ternary;
     Youngtown.Sequim : ternary;
   }

   actions {
     Rains;
     Norco;
   }

   default_action : Norco();
   size : Albany;
}

action Brave( Tilghman ) {
   modify_field( Tillamook.Gardiner, Tilghman );
   modify_field( Tillamook.Annawan, 0 );
   modify_field( Tillamook.Jayton, 0 );
}

action Mikkalo( Ionia, Nellie ) {
   modify_field( Tillamook.Gardiner, 0 );
   modify_field( Tillamook.Annawan, Ionia );
   modify_field( Tillamook.Jayton, Nellie );
}

action Muenster( Bluff, Deport, Colfax ) {
   modify_field( Tillamook.Gardiner, Bluff );
   modify_field( Tillamook.Annawan, Deport );
   modify_field( Tillamook.Jayton, Colfax );
}

action Jigger() {
   modify_field( Tillamook.Gardiner, 0 );
   modify_field( Tillamook.Annawan, 0 );
   modify_field( Tillamook.Jayton, 0 );
}

table WestLawn {
   reads {
     Tillamook.Brady : exact;
     Horton.Haslet : ternary;
     Horton.Pinecrest : ternary;
     Horton.Lublin : ternary;
   }

   actions {
     Brave;
     Mikkalo;
     Muenster;
     Jigger;
   }

   default_action : Jigger();
   size : Swain;
}

table Westville {
   reads {
     Tillamook.Brady : exact;
     Selby.Colona mask 0xffff0000 : ternary;
     Horton.Kealia : ternary;
     Horton.Floyd : ternary;
     Horton.Halliday : ternary;
     Hitterdal.Cleta : ternary;

   }

   actions {
     Brave;
     Mikkalo;
     Muenster;
     Jigger;
   }

   default_action : Jigger();
   size : Contact;
}

table Handley {
   reads {
     Tillamook.Brady : exact;
     Blanding.Danville mask 0xffff0000 : ternary;
     Horton.Kealia : ternary;
     Horton.Floyd : ternary;
     Horton.Halliday : ternary;
     Hitterdal.Cleta : ternary;

   }

   actions {
     Brave;
     Mikkalo;
     Muenster;
     Jigger;
   }

   default_action : Jigger();
   size : Fiskdale;
}

meter Montalba {
   type : packets;
   static : RichBar;
   instance_count: FlyingH;
}

action Parkway( Ruthsburg ) {
   execute_meter( Montalba, Ruthsburg, ig_intr_md_for_tm.packet_color );
}

action Gordon() {
   execute_meter( Montalba, Tillamook.Annawan, ig_intr_md_for_tm.packet_color );
}

table RichBar {
   reads {
     Tillamook.Annawan : ternary;
     Horton.Edler : ternary;
     Horton.Aquilla : ternary;
     Youngtown.Sequim : ternary;
     Tillamook.Jayton : ternary;
   }
   actions {
      Parkway;
      Gordon;
   }
   size : Duffield;
}

control Salamonia {
   apply( Welch );
}

control Dovray {
   if ( Horton.Lewiston == 1 ) {
      apply( Westville );
   } else if ( Horton.Thistle == 1 ) {
      apply( Handley );
   } else {
      apply( WestLawn );
   }
}

control Gibbs {
   apply( RichBar );
}



action Candle() {
   modify_field( Horton.Godley, Ulysses.Waxhaw );
}

action Ochoa() {
   modify_field( Horton.Godley, Pineville[0].Deerwood );
}

action Nicodemus() {
   modify_field( Horton.Halliday, Ulysses.Bernard );
}

action Herald() {
   modify_field( Horton.Halliday, Selby.Quealy );
}

action LakeHart() {
   modify_field( Horton.Halliday, Blanding.Steele );
}

action Woodsdale( Satus, NantyGlo ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Satus );
   modify_field( ig_intr_md_for_tm.qid, NantyGlo );
}

table Satanta {
   reads {
     Horton.Roswell : exact;
   }

   actions {
     Candle;
     Ochoa;
   }

   size : Covelo;
}

table Hemet {
   reads {
     Horton.Lewiston : exact;
     Horton.Thistle : exact;
   }

   actions {
     Nicodemus;
     Herald;
     LakeHart;
   }

   size : Slana;
}

table TroutRun {
   reads {
      Ulysses.OldMinto : ternary;
      Ulysses.Waxhaw : ternary;
      Horton.Godley : ternary;
      Horton.Halliday : ternary;
      Tillamook.Gardiner : ternary;
   }

   actions {
      Woodsdale;
   }

   size : Exeland;
}

control Marquand {
   apply( Satanta );
   apply( Hemet );
}

control Hecker {
   apply( TroutRun );
}



action Newfane( Geistown ) {
   modify_field( Orrum.PineLake, Gurdon );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Geistown );
   modify_field(Orrum.Kaluaaha, Geistown );
}

action Roggen( Lamont ) {
   modify_field( Orrum.PineLake, Basco );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Lamont );
   modify_field(Orrum.Kaluaaha, Lamont );
   modify_field( Orrum.Nickerson, ig_intr_md.ingress_port );
}

table Thurston {
   reads {
      Youngtown.Sequim : exact;
      Ulysses.Anniston : ternary;
      Orrum.Fergus : ternary;
   }

   actions {
      Newfane;
      Roggen;
   }

   size : Pinta;
}

control OldTown {
   apply( Thurston );
}




counter Ogunquit {
   type : packets_and_bytes;
   direct : Haugen;
   min_width: 32;
}

table Haugen {
   reads {
      eg_intr_md.egress_port mask 0x7f : exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }

   actions {
      Careywood;
   }

   size : Simnasho;
}

control Armagh {
   apply( Haugen );
}



action Jermyn()
{
   modify_field(Orrum.Cypress, Newcastle);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, 0);
   modify_field(Orrum.Kaluaaha, 0);
   Bunker();
}

action Boyes()
{
   modify_field(Orrum.Cypress, Newcastle);
   bit_or(Orrum.Kaluaaha, 0x2000, LaFayette.Minburn);
}

action Wainaku( Puryear ) {
   modify_field(Orrum.Cypress, Newcastle);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Puryear);
   modify_field(Orrum.Kaluaaha, Puryear);
}

table Gonzales {
   reads {
      LaFayette.Camilla : exact;
      LaFayette.Wells : exact;
      LaFayette.Dunnellon : exact;
      LaFayette.Minburn : exact;
   }

   actions {
      Boyes;
      Wainaku;
      Jermyn;
   }
   default_action : Jermyn();
   size : Gerster;
}

control Millstadt {
   apply( Gonzales );
}



action Potosi() {
   modify_field( Woodston.Suamico, Horton.Kealia );

}

action Christina( Vinita ) {
   Potosi();
   modify_field( Woodston.Toluca, Vinita );
}

table Simla {
   reads {
     Selby.Tramway : ternary;
   }
   actions {
      Christina;
   }
   default_action : Potosi;
  size : 512;
}

action Follett( Wilton ) {
   modify_field( Woodston.Rayville, Wilton );
}


table Belvidere {
   reads {
     Selby.Colona : ternary;
   }
   actions {
      Follett;
   }
  size : 512;
}

action Mifflin( Moose ) {
   modify_field( Woodston.Daphne, Moose );
}


table Hawthorn {
   reads {
     Horton.Wentworth : exact;
   }
   actions {
      Mifflin;
   }
  size : 512;
}

action Umpire( Grasston ) {
   modify_field( Woodston.Kenton, Grasston );
}


table Ironia {
   reads {
     Horton.CeeVee : exact;
   }
   actions {
      Umpire;
   }
  size : 512;
}

action BigRock( Chilson ) {
   modify_field( Woodston.Progreso, Chilson );
}


table Allison {
   reads {
     Horton.Lewiston : exact;
     Horton.Thistle : exact;
     Horton.Aquilla : exact;
   }
   actions {
      BigRock;
      McCartys;
   }
  size : 4096;
}


control Anita {
   apply( Simla );
   apply( Belvidere );
   apply( Hawthorn );
   apply( Ironia );
   apply( Allison );
}

action LaPointe( Glenpool ) {
       max( Lewistown.Harvard, Lewistown.Harvard, Glenpool );
}

action Pickett( Theta, Clyde, Wenden, Brush, Angeles, GlenAvon, Goodwin ) {
   bit_and( Newsome.Toluca, Woodston.Toluca, Theta );
   bit_and( Newsome.Rayville, Woodston.Rayville, Clyde );
   bit_and( Newsome.Suamico, Woodston.Suamico, Wenden );
   bit_and( Newsome.Paxtonia, Woodston.Paxtonia, Brush );
   bit_and( Newsome.Kenton, Woodston.Kenton, Angeles );
   bit_and( Newsome.Daphne, Woodston.Daphne, GlenAvon );
   bit_and( Newsome.Buckholts, Woodston.Buckholts, Goodwin );
}

action Averill( Hapeville, Elsmere, Navarro, Cardenas, FlatRock, VanHorn, Birds ) {
   bit_and( Buncombe.Toluca, Woodston.Toluca, Hapeville );
   bit_and( Buncombe.Rayville, Woodston.Rayville, Elsmere );
   bit_and( Buncombe.Suamico, Woodston.Suamico, Navarro );
   bit_and( Buncombe.Paxtonia, Woodston.Paxtonia, Cardenas );
   bit_and( Buncombe.Kenton, Woodston.Kenton, FlatRock );
   bit_and( Buncombe.Daphne, Woodston.Daphne, VanHorn );
   bit_and( Buncombe.Buckholts, Woodston.Buckholts, Birds );
}

action Fount( Destin, Moark, Galloway, Grubbs, Ridgeland, Barnsboro, Camden ) {
   bit_and( Excello.Toluca, Woodston.Toluca, Destin );
   bit_and( Excello.Rayville, Woodston.Rayville, Moark );
   bit_and( Excello.Suamico, Woodston.Suamico, Galloway );
   bit_and( Excello.Paxtonia, Woodston.Paxtonia, Grubbs );
   bit_and( Excello.Kenton, Woodston.Kenton, Ridgeland );
   bit_and( Excello.Daphne, Woodston.Daphne, Barnsboro );
   bit_and( Excello.Buckholts, Woodston.Buckholts, Camden );
}

action Kinsey( Ridgetop, Moapa, Hatteras, Yorkshire, Hartford, Kiana, MoonRun ) {
   bit_and( Deeth.Toluca, Woodston.Toluca, Ridgetop );
   bit_and( Deeth.Rayville, Woodston.Rayville, Moapa );
   bit_and( Deeth.Suamico, Woodston.Suamico, Hatteras );
   bit_and( Deeth.Paxtonia, Woodston.Paxtonia, Yorkshire );
   bit_and( Deeth.Kenton, Woodston.Kenton, Hartford );
   bit_and( Deeth.Daphne, Woodston.Daphne, Kiana );
   bit_and( Deeth.Buckholts, Woodston.Buckholts, MoonRun );
}

action Tillicum( Snohomish, Jones, HighHill, LewisRun, Assinippi, Botna, Yardville ) {
   bit_and( OldGlory.Toluca, Woodston.Toluca, Snohomish );
   bit_and( OldGlory.Rayville, Woodston.Rayville, Jones );
   bit_and( OldGlory.Suamico, Woodston.Suamico, HighHill );
   bit_and( OldGlory.Paxtonia, Woodston.Paxtonia, LewisRun );
   bit_and( OldGlory.Kenton, Woodston.Kenton, Assinippi );
   bit_and( OldGlory.Daphne, Woodston.Daphne, Botna );
   bit_and( OldGlory.Buckholts, Woodston.Buckholts, Yardville );
}

action Whigham( Aguilar, Borth, GlenRock, Chevak, Cannelton, Ojibwa, BigRiver ) {
   bit_and( Oskawalik.Toluca, Woodston.Toluca, Aguilar );
   bit_and( Oskawalik.Rayville, Woodston.Rayville, Borth );
   bit_and( Oskawalik.Suamico, Woodston.Suamico, GlenRock );
   bit_and( Oskawalik.Paxtonia, Woodston.Paxtonia, Chevak );
   bit_and( Oskawalik.Kenton, Woodston.Kenton, Cannelton );
   bit_and( Oskawalik.Daphne, Woodston.Daphne, Ojibwa );
   bit_and( Oskawalik.Buckholts, Woodston.Buckholts, BigRiver );
}

action SwissAlp( Calabasas, Laneburg, Bardwell, Cordell, Udall, Shamokin, Levasy ) {
   bit_and( Inola.Toluca, Woodston.Toluca, Calabasas );
   bit_and( Inola.Rayville, Woodston.Rayville, Laneburg );
   bit_and( Inola.Suamico, Woodston.Suamico, Bardwell );
   bit_and( Inola.Paxtonia, Woodston.Paxtonia, Cordell );
   bit_and( Inola.Kenton, Woodston.Kenton, Udall );
   bit_and( Inola.Daphne, Woodston.Daphne, Shamokin );
   bit_and( Inola.Buckholts, Woodston.Buckholts, Levasy );
}

@pragma ways 1
table Needles {
   reads {
     Woodston.Progreso : exact;
     Woodston.Toluca : exact;
     Woodston.Rayville : exact;
     Woodston.Suamico : exact;
     Woodston.Paxtonia : exact;
     Woodston.Kenton : exact;
     Woodston.Daphne : exact;
     Woodston.Buckholts : exact;
   }

   actions {
      LaPointe;
  }
  size : 4096;
}

table Mattese {
   reads {
     Woodston.Progreso : exact;
   }
   actions {
      Pickett;
   }
  size : 512;
}

control Cusseta {
   apply( Needles );
}


@pragma ways 1
table Monaca {
   reads {
      Woodston.Progreso : exact;
      Newsome.Toluca : exact;
      Newsome.Rayville : exact;
      Newsome.Suamico : exact;
      Newsome.Paxtonia : exact;
      Newsome.Kenton : exact;
      Newsome.Daphne : exact;
      Newsome.Buckholts : exact;
   }

   actions {
      LaPointe;
  }
  size : 1024;
}

table Chalco {
   reads {
     Woodston.Progreso:exact;
   }
   actions {
      Averill;
   }
  size : 256;
}

control Everton {
   apply( Mattese );
}

control ShowLow {
   apply( Monaca );
}

@pragma ways 1
table Mapleview {
   reads {
      Woodston.Progreso : exact;
      Buncombe.Toluca : exact;
      Buncombe.Rayville : exact;
      Buncombe.Suamico : exact;
      Buncombe.Paxtonia : exact;
      Buncombe.Kenton : exact;
      Buncombe.Daphne : exact;
      Buncombe.Buckholts : exact;
   }

   actions {
      LaPointe;
  }
  size : 512;
}

table Plata {
   reads {
     Woodston.Progreso:exact;
   }
   actions {
      Fount;
   }
  size : 256;
}

control Kasigluk {
   apply( Chalco );
}

control Elihu {
   apply( Mapleview );
}

@pragma ways 1
table Lamoni {
   reads {
      Woodston.Progreso : exact;
      Excello.Toluca : exact;
      Excello.Rayville : exact;
      Excello.Suamico : exact;
      Excello.Paxtonia : exact;
      Excello.Kenton : exact;
      Excello.Daphne : exact;
      Excello.Buckholts : exact;
   }

   actions {
      LaPointe;
  }
  size : 512;
}

table Masontown {
   reads {
     Woodston.Progreso:exact;
   }
   actions {
      Kinsey;
   }
  size : 256;
}

control Despard {
   apply( Plata );
}

control Spanaway {
   apply( Lamoni );
}

@pragma ways 1
table Winner {
   reads {
      Woodston.Progreso : exact;
      Deeth.Toluca : exact;
      Deeth.Rayville : exact;
      Deeth.Suamico : exact;
      Deeth.Paxtonia : exact;
      Deeth.Kenton : exact;
      Deeth.Daphne : exact;
      Deeth.Buckholts : exact;
   }

   actions {
      LaPointe;
  }
  size : 512;
}

table Cimarron {
   reads {
     Woodston.Progreso:exact;
   }
   actions {
      Tillicum;
   }
  size : 256;
}

control Devola {
   apply( Masontown );
}

control Scanlon {
   apply( Winner );
}

@pragma ways 1
table Piney {
   reads {
      Woodston.Progreso : exact;
      OldGlory.Toluca : exact;
      OldGlory.Rayville : exact;
      OldGlory.Suamico : exact;
      OldGlory.Paxtonia : exact;
      OldGlory.Kenton : exact;
      OldGlory.Daphne : exact;
      OldGlory.Buckholts : exact;
   }

   actions {
      LaPointe;
  }
  size : 512;
}

table Dagsboro {
   reads {
     Woodston.Progreso:exact;
   }
   actions {
      Whigham;
   }
  size : 256;
}

control McGrady {
   apply( Cimarron );
}

control Delmar {
   apply( Piney );
}

@pragma ways 1
table Sublett {
   reads {
      Woodston.Progreso : exact;
      Oskawalik.Toluca : exact;
      Oskawalik.Rayville : exact;
      Oskawalik.Suamico : exact;
      Oskawalik.Paxtonia : exact;
      Oskawalik.Kenton : exact;
      Oskawalik.Daphne : exact;
      Oskawalik.Buckholts : exact;
   }

   actions {
      LaPointe;
  }
  size : 512;
}

table McKenna {
   reads {
     Woodston.Progreso:exact;
   }
   actions {
      SwissAlp;
   }
  size : 256;
}

control Larue {
   apply( Dagsboro );
}

control Catawissa {
   apply( Sublett );
}

@pragma ways 1
table Hedrick {
   reads {
      Woodston.Progreso : exact;
      Inola.Toluca : exact;
      Inola.Rayville : exact;
      Inola.Suamico : exact;
      Inola.Paxtonia : exact;
      Inola.Kenton : exact;
      Inola.Daphne : exact;
      Inola.Buckholts : exact;
   }

   actions {
      LaPointe;
  }
  size : 512;
}

control Kensal {
   apply( McKenna );
}

control Goldsmith {
      apply( Hedrick );
}

action Chubbuck( Creekside ) {

}

action Comunas() {
   modify_field( Horton.Latham, 1 );
}

action Paxico() {

}

table Valmont {
   reads {






     Lewistown.Harvard mask 0x000f8000 : ternary;
   }

   actions {
      Chubbuck;
      Comunas;
      Paxico;
   }
  size : 16;
}

control Sontag {
   apply( Valmont );
}

control ingress {

   Twinsburg();

   if( Ulysses.Graford != 0 ) {

      Lewes();
   }

   Penitas();

   if( Ulysses.Graford != 0 ) {
      Montegut();


      Marquand();
      Suarez();
   }

   Garwood();
   Anita();


   Boquet();
   Grampian();

   if( Ulysses.Graford != 0 ) {

      DelMar();
   }


   Amenia();


   if( Ulysses.Graford != 0 ) {
      Aynor();
   }

   Matheson();


   if( Ulysses.Graford != 0 ) {
      Coconino();
   }




   if( Orrum.Konnarock == 0 ) {
      Pendleton();
   } else {
      OldTown();
   }

   Salamonia();

   if( valid( LaFayette ) ){
      Millstadt();
   }


   if( not valid(LaFayette) ) {
      Marvin();
   }


   Hecker();
   Gibbs();
   Kalvesta();
   Timbo();
   Huxley();


   if( valid( Pineville[0] ) ) {
      Longwood();
   }
}

control egress {
   Edwards();
   Wauconda();

   if( ( Orrum.Konnarock == 0 ) and ( Orrum.Cypress != Newcastle ) ) {
      Kaltag();
   }
   Armagh();
}

