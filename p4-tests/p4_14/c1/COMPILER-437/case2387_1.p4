// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 12347







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>



#ifndef Doerun
#define Doerun

header_type Golden {
	fields {
		Shobonier : 16;
		Kurthwood : 16;
		Gerster : 8;
		Escondido : 8;
		Oakmont : 8;
		Geismar : 8;
		Skime : 1;
		Hopeton : 1;
		Bridger : 1;
		Veradale : 1;
		Solomon : 1;
		Taiban : 3;
		Taiban2 : 1;
	}
}

header_type Hobucken {
	fields {
		Cedonia : 24;
		Ekron : 24;
		Comobabi : 24;
		Osakis : 24;
		Olene : 16;
		Crystola : 16;
		Homeworth : 16;
		Onset : 16;
		Alabam : 16;
		Gakona : 8;
		Milbank : 8;
		Nordland : 6;
		Bonney : 1;
		Shanghai : 1;
		Egypt : 12;
		Lushton : 2;
		Borup : 1;
		Cotuit : 1;
		Salix : 1;
		Calimesa : 1;
		Roseau : 1;
		Bowers : 1;
		Dorset : 1;
		Bellmore : 1;
		Brownson : 1;
		Wilbraham : 1;
		Flomot : 1;
		Lutts : 1;
		McHenry : 1;
	}
}

header_type Cowley {
	fields {
		Lisman : 24;
		Bechyn : 24;
		Canjilon : 24;
		Dante : 24;
		Quarry : 3;
		Quarry2 : 1;
		Arion : 24;
		Strevell : 24;
		Colstrip : 24;
		Bucktown : 24;
		Vestaburg : 16;
		Rocky : 16;
		Calverton : 16;
		Wetonka : 16;
		Oriskany : 12;
		Derita : 3;
		Harleton : 1;
		Mystic : 3;
		Warden : 1;
		Meeker : 1;
		Gotham : 1;
		Dellslow : 1;
		MintHill : 1;
		Halliday : 1;
		Palmerton : 8;
		Netarts : 12;
		Samson : 4;
		Mayday : 6;
		Haines : 10;
		Madeira : 9;
		Andrade : 1;
	}
}


header_type Ethete {
	fields {
		Lostine : 8;
		Brazos : 1;
		Grygla : 1;
		Indrio : 1;
		Netcong : 1;
		Longhurst : 1;
		Cropper : 1;
	}
}

header_type Dundalk {
	fields {
		Ocheyedan : 32;
		Darden : 32;
		Kinards : 6;
		Tannehill : 16;
	}
}

header_type Loretto {
	fields {
		Deport : 128;
		Coleman : 128;
		Kensal : 20;
		Epsie : 8;
		Surrey : 11;
		Parthenon : 8;
		Angwin : 13;
	}
}

header_type Letcher {
	fields {
		Oskawalik : 14;
		Theba : 1;
		Dialville : 12;
		Pease : 1;
		Rampart : 1;
		Atoka : 6;
		Brinkman : 2;
		Natalbany : 6;
		Shopville : 3;
	}
}

header_type Kelsey {
	fields {
		FortHunt : 1;
		Swedeborg : 1;
	}
}

header_type Sumner {
	fields {
		Firesteel : 8;
	}
}

header_type Denmark {
	fields {
		PineLake : 16;
		Minetto : 11;
	}
}

header_type Albemarle {
	fields {
		Willows : 32;
		Dovray : 32;
		Elwood : 32;
	}
}

header_type Elbert {
	fields {
		Bleecker : 32;
		Langston : 32;
	}
}

header_type Laneburg {
	fields {
		Frederic : 2;
	}
}
#endif



#ifndef Manning
#define Manning


header_type Flippen {
	fields {
		Barnsboro : 6;
		Elmhurst : 10;
		Samantha : 4;
		Birds : 12;
		Hammonton : 12;
		Tascosa : 2;
		Placid : 2;
		Dixon : 8;
		Covert : 3;
		Elderon : 5;
	}
}



header_type Torrance {
	fields {
		Silesia : 24;
		Flynn : 24;
		Henderson : 24;
		Lookeba : 24;
		Mikkalo : 16;
	}
}



header_type Annville {
	fields {
		Jonesport : 3;
		Dominguez : 1;
		Ladner : 12;
		Achille : 16;
	}
}



header_type Heaton {
	fields {
		Tabler : 4;
		Tallevast : 4;
		ElPrado : 6;
		Wenatchee : 2;
		Luning : 16;
		Sisters : 16;
		Kaweah : 3;
		Millstone : 13;
		Perryton : 8;
		Roxobel : 8;
		Cusseta : 16;
		Biehle : 32;
		Yocemento : 32;
	}
}

header_type Rowden {
	fields {
		Grannis : 4;
		PineLawn : 6;
		Ranburne : 2;
		Decherd : 20;
		Kennedale : 16;
		Waxhaw : 8;
		Anguilla : 8;
		Paxtonia : 128;
		Sixteen : 128;
	}
}




header_type Pueblo {
	fields {
		Rains : 8;
		Mishicot : 8;
		Freeny : 16;
	}
}

header_type Goldenrod {
	fields {
		Woodrow : 16;
		Youngwood : 16;
		Lamoni : 32;
		Baltic : 32;
		LaVale : 4;
		Alston : 4;
		Realitos : 8;
		Fairborn : 16;
		Dubach : 16;
		Geistown : 16;
	}
}

header_type Woodward {
	fields {
		Gobles : 16;
		Laney : 16;
		Coachella : 16;
		Belgrade : 16;
	}
}



header_type Dubbs {
	fields {
		Duncombe : 16;
		Owentown : 16;
		Dutton : 8;
		WebbCity : 8;
		Walnut : 16;
	}
}

header_type Marbury {
	fields {
		Eldena : 48;
		Volens : 32;
		Filley : 48;
		Anson : 32;
	}
}



header_type BelAir {
	fields {
		Quamba : 1;
		Badger : 1;
		Coverdale : 1;
		Monico : 1;
		RedMills : 1;
		NewAlbin : 3;
		Assinippi : 5;
		Brimley : 3;
		Norfork : 16;
	}
}

header_type Christina {
	fields {
		Buenos : 24;
		Deerwood : 8;
	}
}



header_type Snook {
	fields {
		Valmont : 8;
		Gully : 24;
		Pelland : 24;
		Cashmere : 8;
	}
}

#endif



#ifndef Monkstown
#define Monkstown

#define Noyes        0x8100
#define Comal        0x0800
#define Peoria        0x86dd
#define BigWater        0x9100
#define Chualar        0x8847
#define Stillmore         0x0806
#define Eolia        0x8035
#define Berwyn        0x88cc
#define Summit        0x8809
#define Pittsboro      0xBF00

#define Wilsey              1
#define Kendrick              2
#define Berea              4
#define Ketchum               6
#define Asher               17
#define Mabana                47

#define RedLake         0x501
#define McGrady          0x506
#define Lafayette          0x511
#define Alnwick          0x52F


#define Kremlin                 4789



#define Honokahua               0
#define Coalton              1
#define Oneonta                2



#define Kirkwood          0
#define Staunton          4095
#define CapeFair  4096
#define Kilbourne  8191



#define Bradner                      0
#define Lundell                  0
#define Oskaloosa                 1

header Torrance Cricket;
header Torrance Radcliffe;
header Annville Maryhill[ 2 ];
header Heaton Harlem;
header Heaton Magnolia;
header Rowden Moody;
header Rowden Lugert;
header Goldenrod Telocaset;
header Woodward Lamkin;
header Goldenrod Juneau;
header Woodward Joiner;
header Snook Sharptown;
header Dubbs Emsworth;
header BelAir Kahaluu;
header Flippen Clearmont;
header Torrance Manakin;

parser start {
   return select(current(96, 16)) {
      Pittsboro : Edgemoor;
      default : Northcote;
   }
}

parser Rockland {
   extract( Clearmont );
   return Northcote;
}

parser Edgemoor {
   extract( Manakin );
   return Rockland;
}

parser Northcote {
   extract( Cricket );
   return select( Cricket.Mikkalo ) {
      Noyes : Coffman;
      Comal : Amsterdam;
      Peoria : Wenden;
      Stillmore  : LongPine;
      default        : ingress;
   }
}

parser Coffman {
   extract( Maryhill[0] );

   // FIXME: If comment out these two set_metadata calls, compilation succeeds
   set_metadata(Wayland.Taiban, Maryhill[0].Jonesport );
   set_metadata(Wayland.Taiban2, Maryhill[0].Dominguez );

   set_metadata(Wayland.Solomon, 1);
   return select( Maryhill[0].Achille ) {
      Comal : Amsterdam;
      Peoria : Wenden;
      Stillmore  : LongPine;
      default : ingress;
   }
}

parser Amsterdam {
   extract( Harlem );
   set_metadata(Wayland.Gerster, Harlem.Roxobel);
   set_metadata(Wayland.Oakmont, Harlem.Perryton);
   set_metadata(Wayland.Shobonier, Harlem.Luning);
   set_metadata(Wayland.Bridger, 0);
   set_metadata(Wayland.Skime, 1);
   return select(Harlem.Millstone, Harlem.Tallevast, Harlem.Roxobel) {
      Lafayette : Haley;
      default : ingress;
   }
}

parser Wenden {
   extract( Lugert );
   set_metadata(Wayland.Gerster, Lugert.Waxhaw);
   set_metadata(Wayland.Oakmont, Lugert.Anguilla);
   set_metadata(Wayland.Shobonier, Lugert.Kennedale);
   set_metadata(Wayland.Bridger, 1);
   set_metadata(Wayland.Skime, 0);
   return ingress;
}

parser LongPine {
   extract( Emsworth );
   return ingress;
}

parser Haley {
   extract(Lamkin);
   return select(Lamkin.Laney) {
      Kremlin : Almont;
      default : ingress;
    }
}

parser Valencia {
   set_metadata(Timken.Lushton, Oneonta);
   return Powelton;
}

parser Kempner {
   set_metadata(Timken.Lushton, Oneonta);
   return Reidland;
}

parser Bangor {
   extract(Kahaluu);
   return select(Kahaluu.Quamba, Kahaluu.Badger, Kahaluu.Coverdale, Kahaluu.Monico, Kahaluu.RedMills,
             Kahaluu.NewAlbin, Kahaluu.Assinippi, Kahaluu.Brimley, Kahaluu.Norfork) {
      Comal : Valencia;
      Peoria : Kempner;
      default : ingress;
   }
}

parser Almont {
   extract(Sharptown);
   set_metadata(Timken.Lushton, Coalton);
   return Aplin;
}

parser Powelton {
   extract( Magnolia );
   set_metadata(Wayland.Escondido, Magnolia.Roxobel);
   set_metadata(Wayland.Geismar, Magnolia.Perryton);
   set_metadata(Wayland.Kurthwood, Magnolia.Luning);
   set_metadata(Wayland.Veradale, 0);
   set_metadata(Wayland.Hopeton, 1);
   return ingress;
}

parser Reidland {
   extract( Moody );
   set_metadata(Wayland.Escondido, Moody.Waxhaw);
   set_metadata(Wayland.Geismar, Moody.Anguilla);
   set_metadata(Wayland.Kurthwood, Moody.Kennedale);
   set_metadata(Wayland.Veradale, 1);
   set_metadata(Wayland.Hopeton, 0);
   return ingress;
}

parser Aplin {
   extract( Radcliffe );
   return select( Radcliffe.Mikkalo ) {
      Comal: Powelton;
      Peoria: Reidland;
      default: ingress;
   }
}
#endif

metadata Hobucken Timken;
metadata Cowley Fontana;
metadata Letcher Tarlton;
metadata Golden Wayland;
metadata Dundalk Whitetail;
metadata Loretto Saticoy;
metadata Kelsey Junior;
metadata Ethete Gorman;
metadata Sumner Pearcy;
metadata Denmark Arapahoe;
metadata Elbert Watters;
metadata Albemarle Thermal;
metadata Laneburg Wamesit;













#undef Alsea

#undef Centre
#undef Wanatah
#undef Callery
#undef Biggers
#undef Chubbuck

#undef Eddystone
#undef Owyhee
#undef Willey

#undef Bixby
#undef Westboro
#undef Cullen
#undef Runnemede
#undef Sturgeon
#undef Twain
#undef Dugger
#undef Fiftysix
#undef DelRey
#undef Corinne
#undef Shamokin
#undef Wheeling
#undef Depew
#undef Zebina
#undef Calumet
#undef Shorter
#undef Bozeman
#undef Tappan
#undef Almeria
#undef Separ
#undef Greenwood

#undef Volcano
#undef Hephzibah
#undef Becida
#undef Ludell
#undef Lakota
#undef Longville
#undef Wausaukee
#undef Mattson
#undef Magma
#undef ElMango
#undef Wyandanch
#undef Wyndmere
#undef Sasser
#undef Dunken
#undef Mesita
#undef Allgood
#undef NewTrier

#undef LaSal

#undef Burdette
#undef Buckeye
#undef Wyanet
#undef Needham

#undef ElkNeck







#define Alsea 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Centre      65536
#define Wanatah      65536
#define Callery 512
#define Biggers 512
#define Chubbuck      512


#define Eddystone     1024
#define Owyhee    1024
#define Willey     256


#define Bixby 512
#define Westboro 65536
#define Cullen 65536
#define Runnemede 28672
#define Sturgeon   16384
#define Twain 8192
#define Dugger         131072
#define Fiftysix 65536
#define DelRey 1024
#define Corinne 2048
#define Shamokin 16384
#define Wheeling 8192
#define Depew 65536

#define Zebina 0x0000000000000000FFFFFFFFFFFFFFFF


#define Calumet 0x000fffff
#define Tappan 2

#define Shorter 0xFFFFFFFFFFFFFFFF0000000000000000

#define Bozeman 0x000007FFFFFFFFFF0000000000000000
#define Almeria  6
#define Greenwood        2048
#define Separ       65536


#define Volcano 1024
#define Hephzibah 4096
#define Becida 4096
#define Ludell 4096
#define Lakota 4096
#define Longville 1024
#define Wausaukee 4096
#define Magma 128
#define ElMango 1
#define Wyandanch  8


#define Wyndmere 512
#define Allgood 512
#define NewTrier 256


#define Sasser 1
#define Dunken 3
#define Mesita 80


#define LaSal 0



#define Burdette 2048


#define Buckeye 4096



#define Wyanet 2048
#define Needham 4096




#define ElkNeck    4096

#endif



#ifndef Nowlin
#define Nowlin

action Barnwell() {
   no_op();
}

action Suwannee() {
   modify_field(Timken.Calimesa, 1 );
}

action Earling() {
   no_op();
}
#endif

















action Olathe(Matheson, Whitefish, Higgins, Mosinee, Mineral, Allyn,
                 IowaCity, Minatare, Tulsa) {
    modify_field(Tarlton.Oskawalik, Matheson);
    modify_field(Tarlton.Theba, Whitefish);
    modify_field(Tarlton.Dialville, Higgins);
    modify_field(Tarlton.Pease, Mosinee);
    modify_field(Tarlton.Rampart, Mineral);
    modify_field(Tarlton.Atoka, Allyn);
    modify_field(Tarlton.Brinkman, IowaCity);
    modify_field(Tarlton.Shopville, Minatare);
    modify_field(Tarlton.Natalbany, Tulsa);
}

@pragma command_line --no-dead-code-elimination
table Goulding {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Olathe;
    }
    size : Alsea;
}

control Macksburg {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Goulding);
    }
}





action Sarasota(Bostic) {
   modify_field( Fontana.Harleton, 1 );
   modify_field( Fontana.Palmerton, Bostic);
   modify_field( Timken.Wilbraham, 1 );
}

action Lepanto() {
   modify_field( Timken.Dorset, 1 );
   modify_field( Timken.Lutts, 1 );
}

action Thatcher() {
   modify_field( Timken.Wilbraham, 1 );
}

action Jessie() {
   modify_field( Timken.Flomot, 1 );
}

action RedLevel() {
   modify_field( Timken.Lutts, 1 );
}

counter Hilbert {
   type : packets_and_bytes;
   direct : Midville;
   min_width: 16;
}

table Midville {
   reads {
      Tarlton.Atoka : exact;
      Cricket.Silesia : ternary;
      Cricket.Flynn : ternary;
   }

   actions {
      Sarasota;
      Lepanto;
      Thatcher;
      Jessie;
      RedLevel;
   }
   size : Callery;
}

action Exira() {
   modify_field( Timken.Bellmore, 1 );
}


table Wadley {
   reads {
      Cricket.Henderson : ternary;
      Cricket.Lookeba : ternary;
   }

   actions {
      Exira;
   }
   size : Biggers;
}


control Benwood {
   apply( Midville );
   apply( Wadley );
}




action Isabela() {
   modify_field( Whitetail.Ocheyedan, Magnolia.Biehle );
   modify_field( Whitetail.Darden, Magnolia.Yocemento );
   modify_field( Whitetail.Kinards, Magnolia.ElPrado );
   modify_field( Saticoy.Deport, Moody.Paxtonia );
   modify_field( Saticoy.Coleman, Moody.Sixteen );
   modify_field( Saticoy.Kensal, Moody.Decherd );
   modify_field( Saticoy.Parthenon, Moody.PineLawn );
   modify_field( Timken.Cedonia, Radcliffe.Silesia );
   modify_field( Timken.Ekron, Radcliffe.Flynn );
   modify_field( Timken.Comobabi, Radcliffe.Henderson );
   modify_field( Timken.Osakis, Radcliffe.Lookeba );
   modify_field( Timken.Olene, Radcliffe.Mikkalo );
   modify_field( Timken.Alabam, Wayland.Kurthwood );
   modify_field( Timken.Gakona, Wayland.Escondido );
   modify_field( Timken.Milbank, Wayland.Geismar );
   modify_field( Timken.Shanghai, Wayland.Hopeton );
   modify_field( Timken.Bonney, Wayland.Veradale );
   modify_field( Timken.McHenry, 0 );
   modify_field( Tarlton.Brinkman, 2 );
   modify_field( Tarlton.Shopville, 0 );
   modify_field( Tarlton.Natalbany, 0 );
}

action Weatherby() {
   modify_field( Timken.Lushton, Honokahua );
   modify_field( Whitetail.Ocheyedan, Harlem.Biehle );
   modify_field( Whitetail.Darden, Harlem.Yocemento );
   modify_field( Whitetail.Kinards, Harlem.ElPrado );
   modify_field( Saticoy.Deport, Lugert.Paxtonia );
   modify_field( Saticoy.Coleman, Lugert.Sixteen );
   modify_field( Saticoy.Kensal, Lugert.Decherd );
   modify_field( Saticoy.Parthenon, Lugert.PineLawn );
   modify_field( Timken.Cedonia, Cricket.Silesia );
   modify_field( Timken.Ekron, Cricket.Flynn );
   modify_field( Timken.Comobabi, Cricket.Henderson );
   modify_field( Timken.Osakis, Cricket.Lookeba );
   modify_field( Timken.Olene, Cricket.Mikkalo );
   modify_field( Timken.Alabam, Wayland.Shobonier );
   modify_field( Timken.Gakona, Wayland.Gerster );
   modify_field( Timken.Milbank, Wayland.Oakmont );
   modify_field( Timken.Shanghai, Wayland.Skime );
   modify_field( Timken.Bonney, Wayland.Bridger );
   modify_field( Fontana.Quarry, Wayland.Taiban );
   modify_field( Fontana.Quarry2, Wayland.Taiban2 );
   modify_field( Timken.McHenry, Wayland.Solomon );
}

table Snowball {
   reads {
      Cricket.Silesia : exact;
      Cricket.Flynn : exact;
      Harlem.Yocemento : exact;
      Timken.Lushton : exact;
   }

   actions {
      Isabela;
      Weatherby;
   }

   default_action : Weatherby();
   size : Volcano;
}


action LeSueur() {
   modify_field( Timken.Crystola, Tarlton.Dialville );
   modify_field( Timken.Homeworth, Tarlton.Oskawalik);
}

action SwissAlp( Hearne ) {
   modify_field( Timken.Crystola, Hearne );
   modify_field( Timken.Homeworth, Tarlton.Oskawalik);
}

action Gibbstown() {
   modify_field( Timken.Crystola, Maryhill[0].Ladner );
   modify_field( Timken.Homeworth, Tarlton.Oskawalik);
}

table Hecker {
   reads {
      Tarlton.Oskawalik : ternary;
      Maryhill[0] : valid;
      Maryhill[0].Ladner : ternary;
   }

   actions {
      LeSueur;
      SwissAlp;
      Gibbstown;
   }
   size : Ludell;
}

action Hatteras( Hartwick ) {
   modify_field( Timken.Homeworth, Hartwick );
}

action TinCity() {

   modify_field( Timken.Salix, 1 );
   modify_field( Pearcy.Firesteel,
                 Oskaloosa );
}

table Salitpa {
   reads {
      Harlem.Biehle : exact;
   }

   actions {
      Hatteras;
      TinCity;
   }
   default_action : TinCity;
   size : Becida;
}

action Lutsen( Tennyson, Hueytown, Allerton, Moclips, Malesus,
                        Ashley, Newcastle ) {
   modify_field( Timken.Crystola, Tennyson );
   modify_field( Timken.Onset, Tennyson );
   modify_field( Timken.Bowers, Newcastle );
   SanRemo(Hueytown, Allerton, Moclips, Malesus,
                        Ashley );
}

action Pillager() {
   modify_field( Timken.Roseau, 1 );
}

table Cistern {
   reads {
      Sharptown.Pelland : exact;
   }

   actions {
      Lutsen;
      Pillager;
   }
   size : Hephzibah;
}

action SanRemo(Gause, CeeVee, Elkville, Estero,
                        Talkeetna ) {
   modify_field( Gorman.Lostine, Gause );
   modify_field( Gorman.Brazos, CeeVee );
   modify_field( Gorman.Indrio, Elkville );
   modify_field( Gorman.Grygla, Estero );
   modify_field( Gorman.Netcong, Talkeetna );
}

action Cimarron(Lewes, Yakima, Anniston, Huttig,
                        Justice ) {
   modify_field( Timken.Onset, Tarlton.Dialville );
   modify_field( Timken.Bowers, 1 );
   SanRemo(Lewes, Yakima, Anniston, Huttig,
                        Justice );
}

action Raeford(Cascadia, Mulhall, Aberfoil, Brady,
                        Amesville, FortGay ) {
   modify_field( Timken.Onset, Cascadia );
   modify_field( Timken.Bowers, 1 );
   SanRemo(Mulhall, Aberfoil, Brady, Amesville,
                        FortGay );
}

action Kalaloch(Sigsbee, Pearson, Ivins, Elrosa,
                        Heppner ) {
   modify_field( Timken.Onset, Maryhill[0].Ladner );
   modify_field( Timken.Bowers, 1 );
   SanRemo(Sigsbee, Pearson, Ivins, Elrosa,
                        Heppner );
}

table Chaumont {
   reads {
      Tarlton.Dialville : exact;
   }


   actions {
      Barnwell;
      Cimarron;
   }

   size : Lakota;
}

@pragma action_default_only Barnwell
table Archer {
   reads {
      Tarlton.Oskawalik : exact;
      Maryhill[0].Ladner : exact;
   }

   actions {
      Raeford;
      Barnwell;
   }

   size : Longville;
}

table Salineno {
   reads {
      Maryhill[0].Ladner : exact;
   }


   actions {
      Barnwell;
      Kalaloch;
   }

   size : Wausaukee;
}

control Keachi {
   apply( Snowball ) {
         Isabela {
            apply( Salitpa );
            apply( Cistern );
         }
         Weatherby {
            if ( Tarlton.Pease == 1 ) {
               apply( Hecker );
            }
            if ( valid( Maryhill[ 0 ] ) ) {

               apply( Archer ) {
                  Barnwell {

                     apply( Salineno );
                  }
               }
            } else {

               apply( Chaumont );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Merrill {
    width  : 1;
    static : Topton;
    instance_count : 262144;
}

register Illmo {
    width  : 1;
    static : Duelm;
    instance_count : 262144;
}

blackbox stateful_alu Kekoskee {
    reg : Merrill;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Junior.FortHunt;
}

blackbox stateful_alu Woodsboro {
    reg : Illmo;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Junior.Swedeborg;
}

field_list Rattan {
    Tarlton.Atoka;
    Maryhill[0].Ladner;
}

field_list_calculation Miranda {
    input { Rattan; }
    algorithm: identity;
    output_width: 18;
}

action Kerrville() {
    Kekoskee.execute_stateful_alu_from_hash(Miranda);
}

action Pacifica() {
    Woodsboro.execute_stateful_alu_from_hash(Miranda);
}

table Topton {
    actions {
      Kerrville;
    }
    default_action : Kerrville;
    size : 1;
}

table Duelm {
    actions {
      Pacifica;
    }
    default_action : Pacifica;
    size : 1;
}
#endif

action Garcia(Lathrop) {
    modify_field(Junior.Swedeborg, Lathrop);
}

@pragma  use_hash_action 0
table Freeville {
    reads {
       Tarlton.Atoka : exact;
    }
    actions {
      Garcia;
    }
    size : 64;
}

action Conklin() {
   modify_field( Timken.Egypt, Tarlton.Dialville );
   modify_field( Timken.Borup, 0 );
}

table Panaca {
   actions {
      Conklin;
   }
   size : 1;
}

action Lapoint() {
   modify_field( Timken.Egypt, Maryhill[0].Ladner );
   modify_field( Timken.Borup, 1 );
}

table Oakridge {
   actions {
      Lapoint;
   }
   size : 1;
}

control Victoria {
   if ( valid( Maryhill[ 0 ] ) ) {
      apply( Oakridge );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Tarlton.Rampart == 1 ) {
         apply( Topton );
         apply( Duelm );
      }
#endif
   } else {
      apply( Panaca );
      if( Tarlton.Rampart == 1 ) {
         apply( Freeville );
      }
   }
}




field_list Myton {
   Cricket.Silesia;
   Cricket.Flynn;
   Cricket.Henderson;
   Cricket.Lookeba;
   Cricket.Mikkalo;
}

field_list Hanks {

   Harlem.Roxobel;
   Harlem.Biehle;
   Harlem.Yocemento;
}

field_list Simnasho {
   Lugert.Paxtonia;
   Lugert.Sixteen;
   Lugert.Decherd;
   Lugert.Waxhaw;
}

field_list Mabank {
   Harlem.Biehle;
   Harlem.Yocemento;
   Lamkin.Gobles;
   Lamkin.Laney;
}





field_list_calculation Uintah {
    input {
        Myton;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Kotzebue {
    input {
        Hanks;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Cabery {
    input {
        Simnasho;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Willmar {
    input {
        Mabank;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Cozad() {
    modify_field_with_hash_based_offset(Thermal.Willows, 0,
                                        Uintah, 4294967296);
}

action Livengood() {
    modify_field_with_hash_based_offset(Thermal.Dovray, 0,
                                        Kotzebue, 4294967296);
}

action Shoshone() {
    modify_field_with_hash_based_offset(Thermal.Dovray, 0,
                                        Cabery, 4294967296);
}

action Baltimore() {
    modify_field_with_hash_based_offset(Thermal.Elwood, 0,
                                        Willmar, 4294967296);
}

table Hoven {
   actions {
      Cozad;
   }
   size: 1;
}

control ElkRidge {
   apply(Hoven);
}

table Burket {
   actions {
      Livengood;
   }
   size: 1;
}

table Cranbury {
   actions {
      Shoshone;
   }
   size: 1;
}

control Nightmute {
   if ( valid( Harlem ) ) {
      apply(Burket);
   } else {
      if ( valid( Lugert ) ) {
         apply(Cranbury);
      }
   }
}

table Wheaton {
   actions {
      Baltimore;
   }
   size: 1;
}

control Holtville {
   if ( valid( Lamkin ) ) {
      apply(Wheaton);
   }
}



action Reynolds() {
    modify_field(Watters.Bleecker, Thermal.Willows);
}

action Alsen() {
    modify_field(Watters.Bleecker, Thermal.Dovray);
}

action Brackett() {
    modify_field(Watters.Bleecker, Thermal.Elwood);
}

@pragma action_default_only Barnwell
@pragma immediate 0
table Beeler {
   reads {
      Juneau.valid : ternary;
      Joiner.valid : ternary;
      Magnolia.valid : ternary;
      Moody.valid : ternary;
      Radcliffe.valid : ternary;
      Telocaset.valid : ternary;
      Lamkin.valid : ternary;
      Harlem.valid : ternary;
      Lugert.valid : ternary;
      Cricket.valid : ternary;
   }
   actions {
      Reynolds;
      Alsen;
      Brackett;
      Barnwell;
   }
   size: Willey;
}

action Thurston() {
    modify_field(Watters.Langston, Thermal.Elwood);
}

@pragma immediate 0
table Longdale {
   reads {
      Juneau.valid : ternary;
      Joiner.valid : ternary;
      Telocaset.valid : ternary;
      Lamkin.valid : ternary;
   }
   actions {
      Thurston;
      Barnwell;
   }
   size: Almeria;
}

control Monohan {
   apply(Longdale);
   apply(Beeler);
}



counter HillCity {
   type : packets_and_bytes;
   direct : Umpire;
   min_width: 16;
}

@pragma action_default_only Barnwell
table Umpire {
   reads {
      Tarlton.Atoka : exact;
      Junior.Swedeborg : ternary;
      Junior.FortHunt : ternary;
      Timken.Roseau : ternary;
      Timken.Bellmore : ternary;
      Timken.Dorset : ternary;
   }

   actions {
      Suwannee;
      Barnwell;
   }
   size : Chubbuck;
}

action Comunas() {

   modify_field(Timken.Cotuit, 1 );
   modify_field(Pearcy.Firesteel,
                Lundell);
}







table Covina {
   reads {
      Timken.Comobabi : exact;
      Timken.Osakis : exact;
      Timken.Crystola : exact;
      Timken.Homeworth : exact;
   }

   actions {
      Earling;
      Comunas;
   }
   size : Wanatah;
   support_timeout : true;
}

action Rozet() {
   modify_field( Gorman.Longhurst, 1 );
}

table SourLake {
   reads {
      Timken.Onset : ternary;
      Timken.Cedonia : exact;
      Timken.Ekron : exact;
   }
   actions {
      Rozet;
   }
   size: Bixby;
}

control Munger {
   apply( Umpire ) {
      Barnwell {



         if (Tarlton.Theba == 0 and Timken.Salix == 0) {
            apply( Covina );
         }
         apply(SourLake);
      }
   }
}

field_list Berlin {
    Pearcy.Firesteel;
    Timken.Comobabi;
    Timken.Osakis;
    Timken.Crystola;
    Timken.Homeworth;
}

action Stilwell() {
   generate_digest(Bradner, Berlin);
}

table WindLake {
   actions {
      Stilwell;
   }
   size : 1;
}

control Layton {
   if (Timken.Cotuit == 1) {
      apply( WindLake );
   }
}



action Arial( Barnhill, Cecilton ) {
   modify_field( Saticoy.Angwin, Barnhill );
   modify_field( Arapahoe.PineLake, Cecilton );
}

@pragma action_default_only Heron
table Springlee {
   reads {
      Gorman.Lostine : exact;
      Saticoy.Coleman mask Shorter : lpm;
   }
   actions {
      Arial;
      Heron;
   }
   size : Wheeling;
}

@pragma atcam_partition_index Saticoy.Angwin
@pragma atcam_number_partitions Wheeling
table Cooter {
   reads {
      Saticoy.Angwin : exact;
      Saticoy.Coleman mask Bozeman : lpm;
   }

   actions {
      Hermleigh;
      Haworth;
      Barnwell;
   }
   default_action : Barnwell();
   size : Depew;
}

action Anacortes( Warsaw, Earlsboro ) {
   modify_field( Saticoy.Surrey, Warsaw );
   modify_field( Arapahoe.PineLake, Earlsboro );
}

@pragma action_default_only Barnwell
table Wellton {


   reads {
      Gorman.Lostine : exact;
      Saticoy.Coleman : lpm;
   }

   actions {
      Anacortes;
      Barnwell;
   }

   size : Corinne;
}

@pragma atcam_partition_index Saticoy.Surrey
@pragma atcam_number_partitions Corinne
table Delavan {
   reads {
      Saticoy.Surrey : exact;


      Saticoy.Coleman mask Zebina : lpm;
   }
   actions {
      Hermleigh;
      Haworth;
      Barnwell;
   }

   default_action : Barnwell();
   size : Shamokin;
}

@pragma action_default_only Heron
@pragma idletime_precision 1
table Bellwood {

   reads {
      Gorman.Lostine : exact;
      Whitetail.Darden : lpm;
   }

   actions {
      Hermleigh;
      Haworth;
      Heron;
   }

   size : DelRey;
   support_timeout : true;
}

action Marlton( Fireco, Visalia ) {
   modify_field( Whitetail.Tannehill, Fireco );
   modify_field( Arapahoe.PineLake, Visalia );
}

@pragma action_default_only Barnwell
#ifdef PROFILE_DEFAULT
@pragma stage 2 Twain
@pragma stage 3
#endif
table Sunflower {
   reads {
      Gorman.Lostine : exact;
      Whitetail.Darden : lpm;
   }

   actions {
      Marlton;
      Barnwell;
   }

   size : Sturgeon;
}

@pragma ways Tappan
@pragma atcam_partition_index Whitetail.Tannehill
@pragma atcam_number_partitions Sturgeon
table Annandale {
   reads {
      Whitetail.Tannehill : exact;
      Whitetail.Darden mask Calumet : lpm;
   }
   actions {
      Hermleigh;
      Haworth;
      Barnwell;
   }
   default_action : Barnwell();
   size : Dugger;
}

action Hermleigh( Covelo ) {
   modify_field( Arapahoe.PineLake, Covelo );
}

@pragma idletime_precision 1
table CedarKey {
   reads {
      Gorman.Lostine : exact;
      Whitetail.Darden : exact;
   }

   actions {
      Hermleigh;
      Haworth;
      Barnwell;
   }
   default_action : Barnwell();
   size : Westboro;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
@pragma stage 2 Runnemede
@pragma stage 3
#endif
table Tillatoba {
   reads {
      Gorman.Lostine : exact;
      Saticoy.Coleman : exact;
   }

   actions {
      Hermleigh;
      Haworth;
      Barnwell;
   }
   default_action : Barnwell();
   size : Cullen;
   support_timeout : true;
}

action Laclede(Helen, Wagener, ElRio) {
   modify_field(Fontana.Vestaburg, ElRio);
   modify_field(Fontana.Lisman, Helen);
   modify_field(Fontana.Bechyn, Wagener);
   modify_field(Fontana.Andrade, 1);
}

action Heidrick() {
   modify_field(Timken.Calimesa, 1);
}

action Lovett(Ringwood) {
   modify_field(Fontana.Harleton, 1);
   modify_field(Fontana.Palmerton, Ringwood);
}

action Heron() {
   modify_field( Fontana.Harleton, 1 );
   modify_field( Fontana.Palmerton, 9 );
}

table Coryville {
   reads {
      Arapahoe.PineLake : exact;
   }

   actions {
      Laclede;
      Heidrick;
      Lovett;
   }
   size : Fiftysix;
}

control English {
   if ( Timken.Calimesa == 0 and Gorman.Longhurst == 1 ) {
      if ( ( Gorman.Brazos == 1 ) and ( Timken.Shanghai == 1 ) ) {
         apply( CedarKey ) {
            Barnwell {
               apply( Sunflower ) {
                  Marlton {
                     apply( Annandale );
                  }
                  Barnwell {
                     apply( Bellwood );
                  }
               }
            }
         }
      } else if ( ( Gorman.Indrio == 1 ) and ( Timken.Bonney == 1 ) ) {
         apply( Tillatoba ) {
            Barnwell {
               apply( Wellton ) {
                  Anacortes {
                     apply( Delavan );
                  }
                  Barnwell {

                     apply( Springlee ) {
                        Arial {
                           apply( Cooter );
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Jermyn {
   if( Arapahoe.PineLake != 0 ) {
      apply( Coryville );
   }
}

action Haworth( Wolford ) {
   modify_field( Arapahoe.Minetto, Wolford );
   modify_field( Gorman.Cropper, 1 );
}

field_list Devore {
   Watters.Langston;
}

field_list_calculation Osman {
    input {
        Devore;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Udall {
   selection_key : Osman;
   selection_mode : resilient;
}

action_profile Poneto {
   actions {
      Hermleigh;
   }
   size : Separ;
   dynamic_action_selection : Udall;
}

table Tchula {
   reads {
      Arapahoe.Minetto : exact;
   }
   action_profile : Poneto;
   size : Greenwood;
}

control Elsmere {
   if ( Arapahoe.Minetto != 0 ) {
      apply( Tchula );
   }
}



field_list Moraine {
   Watters.Bleecker;
}

field_list_calculation Ionia {
    input {
        Moraine;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Heeia {
    selection_key : Ionia;
    selection_mode : resilient;
}

action Olivet(Sitka) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Sitka);
}

action_profile Tagus {
    actions {
        Olivet;
        Barnwell;
    }
    size : Owyhee;
    dynamic_action_selection : Heeia;
}

table Willard {
   reads {
      Fontana.Calverton : exact;
   }
   action_profile: Tagus;
   size : Eddystone;
}

control Sugarloaf {
   if ((Fontana.Calverton & 0x2000) == 0x2000) {
      apply(Willard);
   }
}



meter Coyote {
   type : packets;
   static : FordCity;
   instance_count: Burdette;
}

action Vantage(Ripon) {
   execute_meter(Coyote, Ripon, Wamesit.Frederic);
}

@pragma stage 10
table FordCity {
   reads {
      Tarlton.Atoka : exact;
      Fontana.Palmerton : exact;
   }
   actions {
      Vantage;
   }
   size : Wyanet;
}

counter Bloomdale {
   type : packets;
   static : Ivyland;
   instance_count : Buckeye;
   min_width: 64;
}

action Marbleton(ElLago) {
   modify_field(Timken.Calimesa, 1);
   count(Bloomdale, ElLago);
}

action Lilydale(Brazil) {
   count(Bloomdale, Brazil);
}

action Allison(Thawville, Bushland) {
   modify_field(ig_intr_md_for_tm.qid, Thawville);
   count(Bloomdale, Bushland);
}

action Hotevilla(Slater, Elliston, Pettigrew) {
   modify_field(ig_intr_md_for_tm.qid, Slater);
   modify_field(ig_intr_md_for_tm.ingress_cos, Elliston);
   count(Bloomdale, Pettigrew);
}

action Preston(Suwanee) {
   modify_field(ig_intr_md_for_tm.copy_to_cpu, 1);
   count(Bloomdale, Suwanee);
}

@pragma stage 11
table Ivyland {
   reads {
      Tarlton.Atoka : exact;
      Fontana.Palmerton : exact;
      Wamesit.Frederic : exact;
   }

   actions {
      Marbleton;
      Allison;
      Hotevilla;
      Lilydale;
      Preston;
   }
size : Needham;
}



action Peosta() {
   modify_field(Fontana.Lisman, Timken.Cedonia);
   modify_field(Fontana.Bechyn, Timken.Ekron);
   modify_field(Fontana.Canjilon, Timken.Comobabi);
   modify_field(Fontana.Dante, Timken.Osakis);
   modify_field(Fontana.Vestaburg, Timken.Crystola);
}

table Verbena {
   actions {
      Peosta;
   }
   default_action : Peosta();
   size : 1;
}

control VanZandt {
   if (Timken.Crystola!=0) {
      apply( Verbena );
   }
}

action Tillson() {
   modify_field(Fontana.Meeker, 1);
   modify_field(Fontana.Warden, 1);
   modify_field(Fontana.Wetonka, Fontana.Vestaburg);
}

action Billett() {
}



@pragma ways 1
table Talbotton {
   reads {
      Fontana.Lisman : exact;
      Fontana.Bechyn : exact;
   }
   actions {
      Tillson;
      Billett;
   }
   default_action : Billett;
   size : 1;
}

action Flourtown() {
   modify_field(Fontana.Gotham, 1);
   modify_field(Fontana.Halliday, 1);
   add(Fontana.Wetonka, Fontana.Vestaburg, CapeFair);
}

table Auburn {
   actions {
      Flourtown;
   }
   default_action : Flourtown;
   size : 1;
}

action BigPiney() {
   modify_field(Fontana.MintHill, 1);
   modify_field(Fontana.Wetonka, Fontana.Vestaburg);
}

table Redmon {
   actions {
      BigPiney;
   }
   default_action : BigPiney();
   size : 1;
}

action Poulsbo(Pardee) {
   modify_field(Fontana.Dellslow, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Pardee);
   modify_field(Fontana.Calverton, Pardee);
}

action Cowles(Dedham) {
   modify_field(Fontana.Gotham, 1);
   modify_field(Fontana.Wetonka, Dedham);
}

action Kealia() {
}

table Pickett {
   reads {
      Fontana.Lisman : exact;
      Fontana.Bechyn : exact;
      Fontana.Vestaburg : exact;
   }

   actions {
      Poulsbo;
      Cowles;
      Kealia;
   }
   default_action : Kealia();
   size : Centre;
}

control Guion {
   if (Timken.Calimesa == 0) {
      apply(Pickett) {
         Kealia {
            apply(Talbotton) {
               Billett {
                  if ((Fontana.Lisman & 0x010000) == 0x010000) {
                     apply(Auburn);
                  } else {
                     apply(Redmon);
                  }
               }
            }
         }
      }
   }
}

action Cidra() {
   modify_field(Timken.Brownson, 1);
   modify_field(Timken.Calimesa, 1);
}

@pragma stage 10
table Carmel {
   actions {
      Cidra;
   }
   default_action : Cidra;
   size : 1;
}

control Canovanas {
   if (Timken.Calimesa == 0) {
      if ((Fontana.Andrade==0) and (Timken.Homeworth==Fontana.Calverton)) {
         apply(Carmel);
      } else {
         apply(FordCity);
         apply(Ivyland);
      }
   }
}



action Glenoma( Rembrandt ) {
   modify_field( Fontana.Oriskany, Rembrandt );
}

action Joseph() {
   modify_field( Fontana.Oriskany, Fontana.Vestaburg );
}

table Mayview {
   reads {
      eg_intr_md.egress_port : exact;
      Fontana.Vestaburg : exact;
   }

   actions {
      Glenoma;
      Joseph;
   }
   default_action : Joseph;
   size : ElkNeck;
}

control Manilla {
   apply( Mayview );
}



action Snowflake( Brule, Teigen ) {
   modify_field( Fontana.Arion, Brule );
   modify_field( Fontana.Strevell, Teigen );
}

action Absarokee( Kathleen, Mancelona, Eunice, Chicago ) {
   modify_field( Fontana.Arion, Kathleen );
   modify_field( Fontana.Strevell, Mancelona );
   modify_field( Fontana.Colstrip, Eunice );
   modify_field( Fontana.Bucktown, Chicago );
}


table Onley {
   reads {
      Fontana.Derita : exact;
   }

   actions {
      Snowflake;
      Absarokee;
   }
   size : Wyandanch;
}

action Odessa(Matador, WestCity, Boring, Argentine) {
   modify_field( Fontana.Mayday, Matador );
   modify_field( Fontana.Haines, WestCity );
   modify_field( Fontana.Samson, Boring );
   modify_field( Fontana.Netarts, Argentine );
}

table Hillsview {
   reads {
        Fontana.Madeira : exact;
   }
   actions {
      Odessa;
   }
   size : NewTrier;
}

action KentPark() {
   no_op();
}

action Ouachita() {
   modify_field( Cricket.Mikkalo, Maryhill[0].Achille );
   remove_header( Maryhill[0] );
}

table Hilltop {
   actions {
      Ouachita;
   }
   default_action : Ouachita;
   size : ElMango;
}

action SoapLake() {
   no_op();
}

action Willette() {
   add_header( Maryhill[ 0 ] );
   modify_field( Maryhill[0].Ladner, Fontana.Oriskany );
   modify_field( Maryhill[0].Jonesport, Fontana.Quarry );
   modify_field( Maryhill[0].Dominguez, Fontana.Quarry2 );
   modify_field( Maryhill[0].Achille, Cricket.Mikkalo );
   modify_field( Cricket.Mikkalo, Noyes );
}



table Lovilia {
   reads {
      Fontana.Oriskany : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      SoapLake;
      Willette;
   }
   default_action : Willette;
   size : Magma;
}

action Hookstown() {
   modify_field(Cricket.Silesia, Fontana.Lisman);
   modify_field(Cricket.Flynn, Fontana.Bechyn);
   modify_field(Cricket.Henderson, Fontana.Arion);
   modify_field(Cricket.Lookeba, Fontana.Strevell);
}

action NorthRim() {
   Hookstown();
   add_to_field(Harlem.Perryton, -1);
}

action MiraLoma() {
   Hookstown();
   add_to_field(Lugert.Anguilla, -1);
}

action Jerico() {
   Willette();
}

action Gamewell() {
   add_header( Manakin );
   modify_field( Manakin.Silesia, Fontana.Arion );
   modify_field( Manakin.Flynn, Fontana.Strevell );
   modify_field( Manakin.Henderson, Fontana.Colstrip );
   modify_field( Manakin.Lookeba, Fontana.Bucktown );
   modify_field( Manakin.Mikkalo, Pittsboro );
   add_header( Clearmont );
   modify_field( Clearmont.Barnsboro, Fontana.Mayday );
   modify_field( Clearmont.Elmhurst, Fontana.Haines );
   modify_field( Clearmont.Samantha, Fontana.Samson );
   modify_field( Clearmont.Birds, Fontana.Netarts );
   modify_field( Clearmont.Dixon, Fontana.Palmerton );
}

table Lansdowne {
   reads {
      Fontana.Mystic : exact;
      Fontana.Derita : exact;
      Fontana.Andrade : exact;
      Harlem.valid : ternary;
      Lugert.valid : ternary;
   }

   actions {
      NorthRim;
      MiraLoma;
      Jerico;
      Gamewell;

   }
   size : Wyndmere;
}

control Pekin {
   apply( Hilltop );
}

control Monmouth {
   apply( Lovilia );
}

control Hooksett {
   apply( Onley );
   apply( Hillsview );
   apply( Lansdowne );
}



field_list Burmester {
    Pearcy.Firesteel;
    Timken.Crystola;
    Radcliffe.Henderson;
    Radcliffe.Lookeba;
    Harlem.Biehle;
}

action Unity() {
   generate_digest(Bradner, Burmester);
}

table Westwood {
   actions {
      Unity;
   }

   default_action : Unity;
   size : 1;
}

control Shauck {
   if (Timken.Salix == 1) {
      apply(Westwood);
   }
}



action PineAire() {
   modify_field( Fontana.Quarry, Tarlton.Shopville );
}

action Sieper() {
   modify_field( Timken.Nordland, Tarlton.Natalbany );
}

action Earlimart() {
   modify_field( Timken.Nordland, Whitetail.Kinards );
}

action Dandridge() {
   modify_field( Timken.Nordland, Saticoy.Parthenon );
}

action Horsehead( Kaaawa, Ironside ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Kaaawa );
   modify_field( ig_intr_md_for_tm.qid, Ironside );
}

table Kevil {
   reads {
     Timken.McHenry : exact;
   }

   actions {
     PineAire;
   }

   size : Sasser;
}

table Metter {
   reads {
     Timken.Shanghai : exact;
     Timken.Bonney : exact;
   }

   actions {
     Sieper;
     Earlimart;
     Dandridge;
   }

   size : Dunken;
}

@pragma stage 10
table Hagaman {
   reads {
      Tarlton.Brinkman : exact;
      Tarlton.Shopville : ternary;
      Fontana.Quarry : ternary;
      Timken.Nordland : ternary;
   }

   actions {
      Horsehead;
   }

   size : Mesita;
}

control Kamrar {
   apply( Kevil );
   apply( Metter );
}

control Linganore {
   apply( Hagaman );
}




#define Harold            0
#define WestLine  1
#define Boyes 2


#define Skiatook           0




action Speed( Habersham ) {
   modify_field( Fontana.Derita, WestLine );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Habersham );
}

action Friend( Jeddo ) {
   modify_field( Fontana.Derita, Boyes );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Jeddo );
   modify_field( Fontana.Madeira, ig_intr_md.ingress_port );
}

table Riverland {
   reads {
      Gorman.Longhurst : exact;
      Tarlton.Pease : ternary;
      Fontana.Palmerton : ternary;
   }

   actions {
      Speed;
      Friend;
   }

   size : Allgood;
}

control Dougherty {
   apply( Riverland );
}


control ingress {

   Macksburg();
   Benwood();
   Keachi();
   Victoria();
   ElkRidge();


   Kamrar();
   Munger();

   Nightmute();
   Holtville();


   English();
   Monohan();
   Elsmere();

   VanZandt();

   Jermyn();






   if( Fontana.Harleton == 0 ) {
      Guion();
   } else {
      Dougherty();
   }

   Linganore();


   Canovanas();
   Sugarloaf();
   Shauck();
   Layton();


   if( valid( Maryhill[0] ) ) {
      Pekin();
   }






}

control egress {
   Manilla();
   Hooksett();

   if( Fontana.Harleton == 0 ) {
      Monmouth();
   }
}

