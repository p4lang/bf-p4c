// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 310







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>



#ifndef Lasker
#define Lasker

header_type Mabana {
	fields {
		Coleman : 16;
		Duque : 16;
		Encinitas : 8;
		Melba : 8;
		Suttle : 8;
		Lewistown : 8;
		Rotonda : 1;
		Flatwoods : 1;
		Holyrood : 1;
		Purley : 1;
		Sprout : 1;
	}
}

header_type Cedonia {
	fields {
		Fairfield : 24;
		Caliente : 24;
		Crooks : 24;
		Neubert : 24;
		Cement : 16;
		PellLake : 16;
		Shopville : 16;
		Welaka : 16;
		Nucla : 16;
		Mankato : 8;
		Ferndale : 8;
		Osseo : 6;
		Grizzly : 1;
		Eolia : 1;
		Kenton : 12;
		Biloxi : 2;
		Avondale : 1;
		Biggers : 1;
		Roxobel : 1;
		Vacherie : 1;
		Kingstown : 1;
		Reagan : 1;
		Placedo : 1;
		Highcliff : 1;
		Salome : 1;
		Ellicott : 1;
		Merrill : 1;
		Lakeside : 1;
		LaVale : 1;
		Kekoskee : 3;
		Nicolaus : 1;
	}
}

header_type Mertens {
	fields {
		Goodrich : 24;
		VanHorn : 24;
		Pinetop : 24;
		Campton : 24;
		Paradis : 24;
		LaCenter : 24;
		Westway : 24;
		Lapeer : 24;
		Blakeslee : 16;
		Saranap : 16;
		Placid : 16;
		Traskwood : 16;
		Lucien : 12;
		RockPort : 3;
		Monteview : 1;
		Green : 3;
		Argentine : 1;
		Gobles : 1;
		Melmore : 1;
		Kinsley : 1;
		Nanson : 1;
		Novinger : 1;
		Emerado : 8;
		Nighthawk : 12;
		Shorter : 4;
		Ridgetop : 6;
		Shelby : 10;
		Cullen : 9;
		Powelton : 1;
	}
}


header_type Henning {
	fields {
		Brinkman : 8;
		Crestone : 1;
		Forepaugh : 1;
		RioPecos : 1;
		Anselmo : 1;
		Cowell : 1;
	}
}

header_type Larchmont {
	fields {
		Juneau : 32;
		Barnhill : 32;
		Benitez : 6;
		Suamico : 16;
	}
}

header_type TiffCity {
	fields {
		Parshall : 128;
		Devers : 128;
		Ragley : 20;
		Peosta : 8;
		Hershey : 11;
		Finlayson : 6;
		Nixon : 13;
	}
}

header_type Halltown {
	fields {
		Joyce : 14;
		Carver : 1;
		Drifton : 12;
		Leicester : 1;
		Jarreau : 1;
		Lennep : 6;
		Cascadia : 2;
		Moline : 6;
		Broadford : 3;
	}
}

header_type Mendota {
	fields {
		Elihu : 1;
		Maysfield : 1;
	}
}

header_type Enfield {
	fields {
		Blueberry : 8;
	}
}

header_type Annette {
	fields {
		Riverbank : 16;
		DeBeque : 11;
	}
}

header_type Lesley {
	fields {
		Eucha : 32;
		Abernathy : 32;
		RedLake : 32;
	}
}

header_type Moorewood {
	fields {
		Berwyn : 32;
		Cabery : 32;
	}
}

header_type Sagamore {
	fields {
		Ocilla : 8;
		Whitewood : 4;
		Ironia : 15;
		Tontogany : 1;
	}
}
#endif



#ifndef Yorkshire
#define Yorkshire


header_type Choudrant {
	fields {
		Thomas : 6;
		Edgemont : 10;
		Churchill : 4;
		National : 12;
		Crown : 12;
		LeMars : 2;
		WestEnd : 2;
		Brodnax : 8;
		Gobler : 3;
		Saxis : 5;
	}
}



header_type Amenia {
	fields {
		Edroy : 24;
		Lamboglia : 24;
		Albin : 24;
		Assinippi : 24;
		Ramos : 16;
	}
}



header_type Bergton {
	fields {
		NantyGlo : 3;
		Lathrop : 1;
		Frewsburg : 12;
		Abbott : 16;
	}
}



header_type ElLago {
	fields {
		Amboy : 4;
		Tafton : 4;
		Danbury : 6;
		Luning : 2;
		Scherr : 16;
		Tryon : 16;
		Keener : 3;
		OldMines : 13;
		Tusayan : 8;
		Barnsdall : 8;
		Minneiska : 16;
		Fannett : 32;
		Topton : 32;
	}
}

header_type FoxChase {
	fields {
		RockHill : 4;
		Edmondson : 6;
		Brawley : 2;
		Dolores : 20;
		Bammel : 16;
		Clintwood : 8;
		Rosboro : 8;
		Onslow : 128;
		Dilia : 128;
	}
}




header_type Higganum {
	fields {
		Spenard : 8;
		Jayton : 8;
		Riverland : 16;
	}
}

header_type PellCity {
	fields {
		Welcome : 16;
		Isabela : 16;
	}
}

header_type Ronneby {
	fields {
		Nellie : 32;
		Beaverdam : 32;
		Otsego : 4;
		Rillton : 4;
		Pineland : 8;
		Saugatuck : 16;
		Makawao : 16;
		Lordstown : 16;
	}
}

header_type Kerrville {
	fields {
		Lehigh : 16;
		Cornville : 16;
	}
}



header_type Stonebank {
	fields {
		Goldsboro : 16;
		Coryville : 16;
		Delmont : 8;
		Amity : 8;
		Gregory : 16;
	}
}

header_type Twain {
	fields {
		Wewela : 48;
		LaMarque : 32;
		Wesson : 48;
		Malinta : 32;
	}
}



header_type Annawan {
	fields {
		Plateau : 1;
		Spindale : 1;
		Tingley : 1;
		Sonestown : 1;
		Achille : 1;
		Mulvane : 3;
		BealCity : 5;
		Gratiot : 3;
		Pelican : 16;
	}
}

header_type Elysburg {
	fields {
		Brave : 24;
		Lilymoor : 8;
	}
}



header_type Taconite {
	fields {
		Robbs : 8;
		Havertown : 24;
		Chaska : 24;
		Uncertain : 8;
	}
}

#endif



#ifndef Chatom
#define Chatom

#define LasLomas        0x8100
#define Rugby        0x0800
#define Oroville        0x86dd
#define RioHondo        0x9100
#define Henderson        0x8847
#define Acree         0x0806
#define Progreso        0x8035
#define Mayview        0x88cc
#define Robins        0x8809
#define Burwell      0xBF00

#define Catawba              1
#define Rehoboth              2
#define Kinard              4
#define Flippen               6
#define Callands               17
#define Draketown                47

#define Dobbins         0x501
#define Calhan          0x506
#define Newtok          0x511
#define Bicknell          0x52F


#define Earlham                 4789



#define Gallion               0
#define Elcho              1
#define Bunker                2



#define Currie          0
#define Roswell          4095
#define Adair  4096
#define Napanoch  8191



#define Mingus                      0
#define Ishpeming                  0
#define Hiseville                 1

header Amenia Thalia;
header Amenia Molino;
header Bergton Trimble[ 2 ];



@pragma pa_fragment ingress Denmark.Minneiska
@pragma pa_fragment egress Denmark.Minneiska
header ElLago Denmark;

@pragma pa_fragment ingress Nutria.Minneiska
@pragma pa_fragment egress Nutria.Minneiska
header ElLago Nutria;

header FoxChase Ilwaco;
header FoxChase Valders;
header PellCity Auburn;
header Ronneby Enderlin;

header Kerrville Chambers;
header Ronneby Kinsey;
header Kerrville Klukwan;
header Taconite Cadley;
header Stonebank Linville;
header Annawan Wimbledon;
header Choudrant Berlin;
header Amenia Wondervu;

parser start {
   return select(current(96, 16)) {
      Burwell : RockyGap;
      default : Vandling;
   }
}

parser Natalbany {
   extract( Berlin );
   return Vandling;
}

parser RockyGap {
   extract( Wondervu );
   return Natalbany;
}

parser Vandling {
   extract( Thalia );
   return select( Thalia.Ramos ) {
      LasLomas : Neches;
      Rugby : Padroni;
      Oroville : Thayne;
      Acree  : Humarock;
      default        : ingress;
   }
}

parser Neches {
   extract( Trimble[0] );
   set_metadata(Archer.Sprout, 1);
   return select( Trimble[0].Abbott ) {
      Rugby : Padroni;
      Oroville : Thayne;
      Acree  : Humarock;
      default : ingress;
   }
}

field_list Tilghman {
    Denmark.Amboy;
    Denmark.Tafton;
    Denmark.Danbury;
    Denmark.Luning;
    Denmark.Scherr;
    Denmark.Tryon;
    Denmark.Keener;
    Denmark.OldMines;
    Denmark.Tusayan;
    Denmark.Barnsdall;
    Denmark.Fannett;
    Denmark.Topton;
}

field_list_calculation Arkoe {
    input {
        Tilghman;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field Denmark.Minneiska  {
    verify Arkoe;
    update Arkoe;
}

parser Padroni {
   extract( Denmark );
   set_metadata(Archer.Encinitas, Denmark.Barnsdall);
   set_metadata(Archer.Suttle, Denmark.Tusayan);
   set_metadata(Archer.Coleman, Denmark.Scherr);
   set_metadata(Archer.Holyrood, 0);
   set_metadata(Archer.Rotonda, 1);
   return select(Denmark.OldMines, Denmark.Tafton, Denmark.Barnsdall) {
      Newtok : Hettinger;
      Calhan : Quinault;
      default : ingress;
   }
}

parser Thayne {
   extract( Valders );
   set_metadata(Archer.Encinitas, Valders.Clintwood);
   set_metadata(Archer.Suttle, Valders.Rosboro);
   set_metadata(Archer.Coleman, Valders.Bammel);
   set_metadata(Archer.Holyrood, 1);
   set_metadata(Archer.Rotonda, 0);
   return select(Valders.Clintwood) {
      Newtok : Otego;
      Calhan : Quinault;
      default : ingress;
   }
}

parser Humarock {
   extract( Linville );
   return ingress;
}

parser Hettinger {
   extract(Auburn);
   extract(Chambers);
   return select(Auburn.Isabela) {
      Earlham : Crestline;
      default : ingress;
    }
}

parser Otego {
   extract(Auburn);
   extract(Chambers);
   return ingress;
}

parser Quinault {
   extract(Auburn);
   extract(Enderlin);
   return ingress;
}

parser Almyra {
   set_metadata(Millhaven.Biloxi, Bunker);
   return Guadalupe;
}

parser Nisland {
   set_metadata(Millhaven.Biloxi, Bunker);
   return Jelloway;
}

parser Topsfield {
   extract(Wimbledon);
   return select(Wimbledon.Plateau, Wimbledon.Spindale, Wimbledon.Tingley, Wimbledon.Sonestown, Wimbledon.Achille,
             Wimbledon.Mulvane, Wimbledon.BealCity, Wimbledon.Gratiot, Wimbledon.Pelican) {
      Rugby : Almyra;
      Oroville : Nisland;
      default : ingress;
   }
}

parser Crestline {
   extract(Cadley);
   set_metadata(Millhaven.Biloxi, Elcho);
   return Lochbuie;
}

field_list Blakeman {
    Nutria.Amboy;
    Nutria.Tafton;
    Nutria.Danbury;
    Nutria.Luning;
    Nutria.Scherr;
    Nutria.Tryon;
    Nutria.Keener;
    Nutria.OldMines;
    Nutria.Tusayan;
    Nutria.Barnsdall;
    Nutria.Fannett;
    Nutria.Topton;
}

field_list_calculation Wells {
    input {
        Blakeman;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field Nutria.Minneiska  {
    verify Wells;
    update Wells;
}

parser Guadalupe {
   extract( Nutria );
   set_metadata(Archer.Melba, Nutria.Barnsdall);
   set_metadata(Archer.Lewistown, Nutria.Tusayan);
   set_metadata(Archer.Duque, Nutria.Scherr);
   set_metadata(Archer.Purley, 0);
   set_metadata(Archer.Flatwoods, 1);
   return ingress;
}

parser Jelloway {
   extract( Ilwaco );
   set_metadata(Archer.Melba, Ilwaco.Clintwood);
   set_metadata(Archer.Lewistown, Ilwaco.Rosboro);
   set_metadata(Archer.Duque, Ilwaco.Bammel);
   set_metadata(Archer.Purley, 1);
   set_metadata(Archer.Flatwoods, 0);
   return ingress;
}

parser Lochbuie {
   extract( Molino );
   return select( Molino.Ramos ) {
      Rugby: Guadalupe;
      Oroville: Jelloway;
      default: ingress;
   }
}
#endif

metadata Cedonia Millhaven;
metadata Mertens Sigsbee;
metadata Halltown Owentown;
metadata Mabana Archer;
metadata Larchmont Cannelton;
metadata TiffCity IttaBena;
metadata Mendota Gibbstown;
metadata Henning GunnCity;
metadata Enfield Cherokee;
metadata Annette GlenRose;
metadata Moorewood Richlawn;
metadata Lesley Loyalton;
metadata Sagamore Klawock;













#undef Willette

#undef Mangham
#undef Wellford
#undef English
#undef Anthony
#undef Pridgen

#undef Range
#undef Belfast
#undef Littleton

#undef Tidewater
#undef EastDuke
#undef Senatobia
#undef Kaanapali
#undef Ekron
#undef Philmont
#undef Amber
#undef Albany
#undef Homeland
#undef Yaurel
#undef ElMirage
#undef Tolley
#undef Greenwood
#undef Paullina
#undef Belcher
#undef Danville
#undef Chazy
#undef Excello
#undef Minto
#undef Sneads
#undef Woodston

#undef Caspian
#undef Chatanika
#undef OldTown
#undef Surrey
#undef Brunson
#undef Rixford
#undef Lowes
#undef Coulee
#undef Felton
#undef Myrick
#undef Veteran
#undef Udall
#undef Caplis
#undef Covington
#undef Bayne
#undef Kokadjo
#undef Lacombe
#undef Poipu
#undef Kranzburg
#undef Casselman
#undef Couchwood

#undef Emmorton
#undef Flaxton

#undef Garwood

#undef Whiteclay
#undef Madras







#define Willette 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Mangham      65536
#define Wellford      65536
#define English 512
#define Anthony 512
#define Pridgen      512


#define Range     1024
#define Belfast    1024
#define Littleton     256


#define Tidewater 512
#define EastDuke 65536
#define Senatobia 65536
#define Kaanapali 28672
#define Ekron   16384
#define Philmont 8192
#define Amber         131072
#define Albany 65536
#define Homeland 1024
#define Yaurel 2048
#define ElMirage 16384
#define Tolley 8192
#define Greenwood 65536

#define Paullina 0x0000000000000000FFFFFFFFFFFFFFFF


#define Belcher 0x000fffff
#define Excello 2

#define Danville 0xFFFFFFFFFFFFFFFF0000000000000000

#define Chazy 0x000007FFFFFFFFFF0000000000000000
#define Minto  6
#define Woodston        2048
#define Sneads       65536


#define Caspian 1024
#define Chatanika 4096
#define OldTown 4096
#define Surrey 4096
#define Brunson 4096
#define Rixford 1024
#define Lowes 4096
#define Felton 128
#define Myrick 1
#define Veteran  8


#define Udall 512
#define Emmorton 512
#define Flaxton 256


#define Caplis 2
#define Covington 3
#define Bayne 80



#define Kokadjo 512
#define Lacombe 512
#define Poipu 512
#define Kranzburg 512

#define Casselman 2048
#define Couchwood 1024



#define Garwood 0


#define Whiteclay    4096
#define Madras    1024

#endif



#ifndef Dunnstown
#define Dunnstown

action Wentworth() {
   no_op();
}

action Enhaut() {
   modify_field(Millhaven.Vacherie, 1 );
   mark_for_drop();
}

action McDaniels() {
   no_op();
}
#endif




#define Renton            0
#define Cochrane  1
#define Lucerne 2


#define Pineville              0
#define Cleator             1
#define Hackamore 2


















action Burmester(Menomonie, Norbeck, Carnero, Oakes, Pearland, BurrOak,
                 Harris, Cornell, Poynette) {
    modify_field(Owentown.Joyce, Menomonie);
    modify_field(Owentown.Carver, Norbeck);
    modify_field(Owentown.Drifton, Carnero);
    modify_field(Owentown.Leicester, Oakes);
    modify_field(Owentown.Jarreau, Pearland);
    modify_field(Owentown.Lennep, BurrOak);
    modify_field(Owentown.Cascadia, Harris);
    modify_field(Owentown.Broadford, Cornell);
    modify_field(Owentown.Moline, Poynette);
}

@pragma command_line --no-dead-code-elimination
table Mosinee {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Burmester;
    }
    size : Willette;
}

control Elkville {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Mosinee);
    }
}





action Ashwood(Gladys) {
   modify_field( Sigsbee.Monteview, 1 );
   modify_field( Sigsbee.Emerado, Gladys);
   modify_field( Millhaven.Ellicott, 1 );
}

action Marcus() {
   modify_field( Millhaven.Placedo, 1 );
   modify_field( Millhaven.Lakeside, 1 );
}

action Daisytown() {
   modify_field( Millhaven.Ellicott, 1 );
}

action Bellmore() {
   modify_field( Millhaven.Merrill, 1 );
}

action Davie() {
   modify_field( Millhaven.Lakeside, 1 );
}

counter Sutherlin {
   type : packets_and_bytes;
   direct : Lyman;
   min_width: 16;
}

table Lyman {
   reads {
      Owentown.Lennep : exact;
      Thalia.Edroy : ternary;
      Thalia.Lamboglia : ternary;
   }

   actions {
      Ashwood;
      Marcus;
      Daisytown;
      Bellmore;
      Davie;
   }
   size : English;
}

action Sudden() {
   modify_field( Millhaven.Highcliff, 1 );
}


table Umpire {
   reads {
      Thalia.Albin : ternary;
      Thalia.Assinippi : ternary;
   }

   actions {
      Sudden;
   }
   size : Anthony;
}


control Lanyon {
   apply( Lyman );
   apply( Umpire );
}




action Danforth() {
   modify_field( Cannelton.Juneau, Nutria.Fannett );
   modify_field( Cannelton.Barnhill, Nutria.Topton );
   modify_field( Cannelton.Benitez, Nutria.Danbury );
   modify_field( IttaBena.Parshall, Ilwaco.Onslow );
   modify_field( IttaBena.Devers, Ilwaco.Dilia );
   modify_field( IttaBena.Ragley, Ilwaco.Dolores );
   modify_field( IttaBena.Finlayson, Ilwaco.Edmondson );
   modify_field( Millhaven.Fairfield, Molino.Edroy );
   modify_field( Millhaven.Caliente, Molino.Lamboglia );
   modify_field( Millhaven.Crooks, Molino.Albin );
   modify_field( Millhaven.Neubert, Molino.Assinippi );
   modify_field( Millhaven.Cement, Molino.Ramos );
   modify_field( Millhaven.Nucla, Archer.Duque );
   modify_field( Millhaven.Mankato, Archer.Melba );
   modify_field( Millhaven.Ferndale, Archer.Lewistown );
   modify_field( Millhaven.Eolia, Archer.Flatwoods );
   modify_field( Millhaven.Grizzly, Archer.Purley );
   modify_field( Millhaven.LaVale, 0 );
   modify_field( Millhaven.Kekoskee, 0 );
   modify_field( Owentown.Cascadia, 2 );
   modify_field( Owentown.Broadford, 0 );
   modify_field( Owentown.Moline, 0 );
   modify_field( Sigsbee.Green, Cleator );
}

action Leeville() {
   modify_field( Millhaven.Biloxi, Gallion );
   modify_field( Cannelton.Juneau, Denmark.Fannett );
   modify_field( Cannelton.Barnhill, Denmark.Topton );
   modify_field( Cannelton.Benitez, Denmark.Danbury );
   modify_field( IttaBena.Parshall, Valders.Onslow );
   modify_field( IttaBena.Devers, Valders.Dilia );
   modify_field( IttaBena.Ragley, Valders.Dolores );
   modify_field( IttaBena.Finlayson, Valders.Edmondson );
   modify_field( Millhaven.Fairfield, Thalia.Edroy );
   modify_field( Millhaven.Caliente, Thalia.Lamboglia );
   modify_field( Millhaven.Crooks, Thalia.Albin );
   modify_field( Millhaven.Neubert, Thalia.Assinippi );
   modify_field( Millhaven.Cement, Thalia.Ramos );
   modify_field( Millhaven.Nucla, Archer.Coleman );
   modify_field( Millhaven.Mankato, Archer.Encinitas );
   modify_field( Millhaven.Ferndale, Archer.Suttle );
   modify_field( Millhaven.Eolia, Archer.Rotonda );
   modify_field( Millhaven.Grizzly, Archer.Holyrood );
   modify_field( Millhaven.Nicolaus, Trimble[0].Lathrop );
   modify_field( Millhaven.LaVale, Archer.Sprout );
}

table Baskin {
   reads {
      Thalia.Edroy : exact;
      Thalia.Lamboglia : exact;
      Denmark.Topton : exact;
      Millhaven.Biloxi : exact;
   }

   actions {
      Danforth;
      Leeville;
   }

   default_action : Leeville();
   size : Caspian;
}


action Hoadly() {
   modify_field( Millhaven.PellLake, Owentown.Drifton );
   modify_field( Millhaven.Shopville, Owentown.Joyce);
}

action Rockvale( Shipman ) {
   modify_field( Millhaven.PellLake, Shipman );
   modify_field( Millhaven.Shopville, Owentown.Joyce);
}

action Billett() {
   modify_field( Millhaven.PellLake, Trimble[0].Frewsburg );
   modify_field( Millhaven.Shopville, Owentown.Joyce);
}

table Ridgeland {
   reads {
      Owentown.Joyce : ternary;
      Trimble[0] : valid;
      Trimble[0].Frewsburg : ternary;
   }

   actions {
      Hoadly;
      Rockvale;
      Billett;
   }
   size : Surrey;
}

action RioLajas( Hinkley ) {
   modify_field( Millhaven.Shopville, Hinkley );
}

action Retrop() {

   modify_field( Millhaven.Roxobel, 1 );
   modify_field( Cherokee.Blueberry,
                 Hiseville );
}

table Protivin {
   reads {
      Denmark.Fannett : exact;
   }

   actions {
      RioLajas;
      Retrop;
   }
   default_action : Retrop;
   size : OldTown;
}

action RedMills( Airmont, Allerton, Parker, Mancelona, Marie,
                        Beasley, Virginia ) {
   modify_field( Millhaven.PellLake, Airmont );
   modify_field( Millhaven.Welaka, Airmont );
   modify_field( Millhaven.Reagan, Virginia );
   Conklin(Allerton, Parker, Mancelona, Marie,
                        Beasley );
}

action Maida() {
   modify_field( Millhaven.Kingstown, 1 );
}

table Hewitt {
   reads {
      Cadley.Chaska : exact;
   }

   actions {
      RedMills;
      Maida;
   }
   size : Chatanika;
}

action Conklin(Heppner, Ferry, Wapato, Luttrell,
                        McBride ) {
   modify_field( GunnCity.Brinkman, Heppner );
   modify_field( GunnCity.Crestone, Ferry );
   modify_field( GunnCity.RioPecos, Wapato );
   modify_field( GunnCity.Forepaugh, Luttrell );
   modify_field( GunnCity.Anselmo, McBride );
}

action Schaller(Bassett, Bucktown, Hospers, Gastonia,
                        Logandale ) {
   modify_field( Millhaven.Welaka, Owentown.Drifton );
   modify_field( Millhaven.Reagan, 1 );
   Conklin(Bassett, Bucktown, Hospers, Gastonia,
                        Logandale );
}

action Anthon(Deloit, Wyarno, Mathias, Moweaqua,
                        Bunavista, Millwood ) {
   modify_field( Millhaven.Welaka, Deloit );
   modify_field( Millhaven.Reagan, 1 );
   Conklin(Wyarno, Mathias, Moweaqua, Bunavista,
                        Millwood );
}

action Caspiana(Lubec, Montbrook, Holliday, Sagerton,
                        Monahans ) {
   modify_field( Millhaven.Welaka, Trimble[0].Frewsburg );
   modify_field( Millhaven.Reagan, 1 );
   Conklin(Lubec, Montbrook, Holliday, Sagerton,
                        Monahans );
}

table Rockdale {
   reads {
      Owentown.Drifton : exact;
   }


   actions {
      Wentworth;
      Schaller;
   }

   size : Brunson;
}

@pragma action_default_only Wentworth
table Honalo {
   reads {
      Owentown.Joyce : exact;
      Trimble[0].Frewsburg : exact;
   }

   actions {
      Anthon;
      Wentworth;
   }

   size : Rixford;
}

@pragma immediate 0
table Ledoux {
   reads {
      Trimble[0].Frewsburg : exact;
   }


   actions {
      Wentworth;
      Caspiana;
   }

   size : Lowes;
}

control Tunis {
   apply( Baskin ) {
         Danforth {
            apply( Protivin );
            apply( Hewitt );
         }
         Leeville {
            if ( not valid(Berlin) and Owentown.Leicester == 1 ) {
               apply( Ridgeland );
            }
            if ( valid( Trimble[ 0 ] ) ) {

               apply( Honalo ) {
                  Wentworth {

                     apply( Ledoux );
                  }
               }
            } else {

               apply( Rockdale );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Correo {
    width  : 1;
    static : Latham;
    instance_count : 262144;
}

register Pierpont {
    width  : 1;
    static : Radom;
    instance_count : 262144;
}

blackbox stateful_alu Waxhaw {
    reg : Correo;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Gibbstown.Elihu;
}

blackbox stateful_alu Barney {
    reg : Pierpont;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Gibbstown.Maysfield;
}

field_list Rawson {
    Owentown.Lennep;
    Trimble[0].Frewsburg;
}

field_list_calculation Varnell {
    input { Rawson; }
    algorithm: identity;
    output_width: 18;
}

action Tatum() {
    Waxhaw.execute_stateful_alu_from_hash(Varnell);
}

action Mendocino() {
    Barney.execute_stateful_alu_from_hash(Varnell);
}

table Latham {
    actions {
      Tatum;
    }
    default_action : Tatum;
    size : 1;
}

table Radom {
    actions {
      Mendocino;
    }
    default_action : Mendocino;
    size : 1;
}
#endif

action NewSite(Rohwer) {
    modify_field(Gibbstown.Maysfield, Rohwer);
}

@pragma  use_hash_action 0
table Idalia {
    reads {
       Owentown.Lennep : exact;
    }
    actions {
      NewSite;
    }
    size : 64;
}

action Freeny() {
   modify_field( Millhaven.Kenton, Owentown.Drifton );
   modify_field( Millhaven.Avondale, 0 );
}

table Tulip {
   actions {
      Freeny;
   }
   size : 1;
}

action Wyndmere() {
   modify_field( Millhaven.Kenton, Trimble[0].Frewsburg );
   modify_field( Millhaven.Avondale, 1 );
}

table Ivydale {
   actions {
      Wyndmere;
   }
   size : 1;
}

control Eastover {
   if ( valid( Trimble[ 0 ] ) ) {
      apply( Ivydale );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Owentown.Jarreau == 1 ) {
         apply( Latham );
         apply( Radom );
      }
#endif
   } else {
      apply( Tulip );
      if( Owentown.Jarreau == 1 ) {
         apply( Idalia );
      }
   }
}




field_list Newfolden {
   Thalia.Edroy;
   Thalia.Lamboglia;
   Thalia.Albin;
   Thalia.Assinippi;
   Thalia.Ramos;
}

field_list TinCity {

   Denmark.Barnsdall;
   Denmark.Fannett;
   Denmark.Topton;
}

field_list Mogadore {
   Valders.Onslow;
   Valders.Dilia;
   Valders.Dolores;
   Valders.Clintwood;
}

field_list Poland {
   Denmark.Fannett;
   Denmark.Topton;
   Auburn.Welcome;
   Auburn.Isabela;
}





field_list_calculation Wallula {
    input {
        Newfolden;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Angola {
    input {
        TinCity;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Buckfield {
    input {
        Mogadore;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Florien {
    input {
        Poland;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Nevis() {
    modify_field_with_hash_based_offset(Loyalton.Eucha, 0,
                                        Wallula, 4294967296);
}

action Kathleen() {
    modify_field_with_hash_based_offset(Loyalton.Abernathy, 0,
                                        Angola, 4294967296);
}

action Emmalane() {
    modify_field_with_hash_based_offset(Loyalton.Abernathy, 0,
                                        Buckfield, 4294967296);
}

action Haven() {
    modify_field_with_hash_based_offset(Loyalton.RedLake, 0,
                                        Florien, 4294967296);
}

table Haines {
   actions {
      Nevis;
   }
   size: 1;
}

control Pearce {
   apply(Haines);
}

table Hickox {
   actions {
      Kathleen;
   }
   size: 1;
}

table Lowland {
   actions {
      Emmalane;
   }
   size: 1;
}

control Maltby {
   if ( valid( Denmark ) ) {
      apply(Hickox);
   } else {
      if ( valid( Valders ) ) {
         apply(Lowland);
      }
   }
}

table Sturgis {
   actions {
      Haven;
   }
   size: 1;
}

control Oriskany {
   if ( valid( Chambers ) ) {
      apply(Sturgis);
   }
}



action Baldwin() {
    modify_field(Richlawn.Berwyn, Loyalton.Eucha);
}

action Mahomet() {
    modify_field(Richlawn.Berwyn, Loyalton.Abernathy);
}

action Equality() {
    modify_field(Richlawn.Berwyn, Loyalton.RedLake);
}

@pragma action_default_only Wentworth
@pragma immediate 0
table Bellamy {
   reads {
      Kinsey.valid : ternary;
      Klukwan.valid : ternary;
      Nutria.valid : ternary;
      Ilwaco.valid : ternary;
      Molino.valid : ternary;
      Enderlin.valid : ternary;
      Chambers.valid : ternary;
      Denmark.valid : ternary;
      Valders.valid : ternary;
      Thalia.valid : ternary;
   }
   actions {
      Baldwin;
      Mahomet;
      Equality;
      Wentworth;
   }
   size: Littleton;
}

action LaSalle() {
    modify_field(Richlawn.Cabery, Loyalton.RedLake);
}

@pragma immediate 0
table Hotchkiss {
   reads {
      Kinsey.valid : ternary;
      Klukwan.valid : ternary;
      Enderlin.valid : ternary;
      Chambers.valid : ternary;
   }
   actions {
      LaSalle;
      Wentworth;
   }
   size: Minto;
}

control Finney {
   apply(Hotchkiss);
   apply(Bellamy);
}



counter Hallowell {
   type : packets_and_bytes;
   direct : Rochert;
   min_width: 16;
}

table Rochert {
   reads {
      Owentown.Lennep : exact;
      Gibbstown.Maysfield : ternary;
      Gibbstown.Elihu : ternary;
      Millhaven.Kingstown : ternary;
      Millhaven.Highcliff : ternary;
      Millhaven.Placedo : ternary;
   }

   actions {
      Enhaut;
      Wentworth;
   }
   default_action : Wentworth();
   size : Pridgen;
}

action Schleswig() {

   modify_field(Millhaven.Biggers, 1 );
   modify_field(Cherokee.Blueberry,
                Ishpeming);
}







table Woolsey {
   reads {
      Millhaven.Crooks : exact;
      Millhaven.Neubert : exact;
      Millhaven.PellLake : exact;
      Millhaven.Shopville : exact;
   }

   actions {
      McDaniels;
      Schleswig;
   }
   default_action : Schleswig();
   size : Wellford;
   support_timeout : true;
}

action LeCenter() {
   modify_field( GunnCity.Cowell, 1 );
}

table Woodridge {
   reads {
      Millhaven.Welaka : ternary;
      Millhaven.Fairfield : exact;
      Millhaven.Caliente : exact;
   }
   actions {
      LeCenter;
   }
   size: Tidewater;
}

control BlackOak {
   apply( Rochert ) {
      Wentworth {



         if (Owentown.Carver == 0 and Millhaven.Roxobel == 0) {
            apply( Woolsey );
         }
         apply(Woodridge);
      }
   }
}

field_list Twinsburg {
    Cherokee.Blueberry;
    Millhaven.Crooks;
    Millhaven.Neubert;
    Millhaven.PellLake;
    Millhaven.Shopville;
}

action Oxnard() {
   generate_digest(Mingus, Twinsburg);
}

table Lydia {
   actions {
      Oxnard;
   }
   size : 1;
}

control Montross {
   if (Millhaven.Biggers == 1) {
      apply( Lydia );
   }
}



action Elmhurst( Wauseon, Kurthwood ) {
   modify_field( IttaBena.Nixon, Wauseon );
   modify_field( GlenRose.Riverbank, Kurthwood );
}

@pragma action_default_only Holcomb
table Flats {
   reads {
      GunnCity.Brinkman : exact;
      IttaBena.Devers mask Danville : lpm;
   }
   actions {
      Elmhurst;
      Holcomb;
   }
   size : Tolley;
}

@pragma atcam_partition_index IttaBena.Nixon
@pragma atcam_number_partitions Tolley
table Licking {
   reads {
      IttaBena.Nixon : exact;
      IttaBena.Devers mask Chazy : lpm;
   }

   actions {
      Arapahoe;
      Wrenshall;
      Wentworth;
   }
   default_action : Wentworth();
   size : Greenwood;
}

action RoseTree( Frankston, Westwego ) {
   modify_field( IttaBena.Hershey, Frankston );
   modify_field( GlenRose.Riverbank, Westwego );
}

@pragma action_default_only Wentworth
table Vananda {


   reads {
      GunnCity.Brinkman : exact;
      IttaBena.Devers : lpm;
   }

   actions {
      RoseTree;
      Wentworth;
   }

   size : Yaurel;
}

@pragma atcam_partition_index IttaBena.Hershey
@pragma atcam_number_partitions Yaurel
table Union {
   reads {
      IttaBena.Hershey : exact;


      IttaBena.Devers mask Paullina : lpm;
   }
   actions {
      Arapahoe;
      Wrenshall;
      Wentworth;
   }

   default_action : Wentworth();
   size : ElMirage;
}

@pragma action_default_only Holcomb
@pragma idletime_precision 1
table Arpin {

   reads {
      GunnCity.Brinkman : exact;
      Cannelton.Barnhill : lpm;
   }

   actions {
      Arapahoe;
      Wrenshall;
      Holcomb;
   }

   size : Homeland;
   support_timeout : true;
}

action WestLine( Chubbuck, Dominguez ) {
   modify_field( Cannelton.Suamico, Chubbuck );
   modify_field( GlenRose.Riverbank, Dominguez );
}

@pragma action_default_only Wentworth
#ifdef PROFILE_DEFAULT
@pragma stage 2 Philmont
@pragma stage 3
#endif
table Oreland {
   reads {
      GunnCity.Brinkman : exact;
      Cannelton.Barnhill : lpm;
   }

   actions {
      WestLine;
      Wentworth;
   }

   size : Ekron;
}

@pragma ways Excello
@pragma atcam_partition_index Cannelton.Suamico
@pragma atcam_number_partitions Ekron
table Swanlake {
   reads {
      Cannelton.Suamico : exact;
      Cannelton.Barnhill mask Belcher : lpm;
   }
   actions {
      Arapahoe;
      Wrenshall;
      Wentworth;
   }
   default_action : Wentworth();
   size : Amber;
}

action Arapahoe( Fiskdale ) {
   modify_field( GlenRose.Riverbank, Fiskdale );
}

@pragma idletime_precision 1
table Lazear {
   reads {
      GunnCity.Brinkman : exact;
      Cannelton.Barnhill : exact;
   }

   actions {
      Arapahoe;
      Wrenshall;
      Wentworth;
   }
   default_action : Wentworth();
   size : EastDuke;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
@pragma stage 2 Kaanapali
@pragma stage 3
#endif
table Joiner {
   reads {
      GunnCity.Brinkman : exact;
      IttaBena.Devers : exact;
   }

   actions {
      Arapahoe;
      Wrenshall;
      Wentworth;
   }
   default_action : Wentworth();
   size : Senatobia;
   support_timeout : true;
}

action Arbyrd(Faith, Excel, Coulter) {
   modify_field(Sigsbee.Blakeslee, Coulter);
   modify_field(Sigsbee.Goodrich, Faith);
   modify_field(Sigsbee.VanHorn, Excel);
   modify_field(Sigsbee.Powelton, 1);

   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}

action WebbCity() {
   Enhaut();
}

action Moclips(MiraLoma) {
   modify_field(Sigsbee.Monteview, 1);
   modify_field(Sigsbee.Emerado, MiraLoma);
}

action Holcomb() {
   modify_field( Sigsbee.Monteview, 1 );
   modify_field( Sigsbee.Emerado, 9 );
}

table Egypt {
   reads {
      GlenRose.Riverbank : exact;
   }

   actions {
      Arbyrd;
      WebbCity;
      Moclips;
   }
   size : Albany;
}

control Oshoto {
   if ( Millhaven.Vacherie == 0 and GunnCity.Cowell == 1 ) {
      if ( ( GunnCity.Crestone == 1 ) and ( Millhaven.Eolia == 1 ) ) {
         apply( Lazear ) {
            Wentworth {
               apply( Oreland ) {
                  WestLine {
                     apply( Swanlake );
                  }
                  Wentworth {
                     apply( Arpin );
                  }
               }
            }
         }
      } else if ( ( GunnCity.RioPecos == 1 ) and ( Millhaven.Grizzly == 1 ) ) {
         apply( Joiner ) {
            Wentworth {
               apply( Vananda ) {
                  RoseTree {
                     apply( Union );
                  }
                  Wentworth {

                     apply( Flats ) {
                        Elmhurst {
                           apply( Licking );
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Tindall {
   if( GlenRose.Riverbank != 0 ) {
      apply( Egypt );
   }
}

action Wrenshall( Grantfork ) {
   modify_field( GlenRose.DeBeque, Grantfork );
}

field_list Sharon {
   Richlawn.Cabery;
}

field_list_calculation Ovilla {
    input {
        Sharon;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Timken {
   selection_key : Ovilla;
   selection_mode : resilient;
}

action_profile Salus {
   actions {
      Arapahoe;
   }
   size : Sneads;
   dynamic_action_selection : Timken;
}

table Valeene {
   reads {
      GlenRose.DeBeque : exact;
   }
   action_profile : Salus;
   size : Woodston;
}

control Penrose {
   if ( GlenRose.DeBeque != 0 ) {
      apply( Valeene );
   }
}



field_list Almedia {
   Richlawn.Berwyn;
}

field_list_calculation Strevell {
    input {
        Almedia;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Maytown {
    selection_key : Strevell;
    selection_mode : resilient;
}

action Pillager(Bowden) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Bowden);
}

action_profile Bairoa {
    actions {
        Pillager;
        Wentworth;
    }
    size : Belfast;
    dynamic_action_selection : Maytown;
}

table Ravenwood {
   reads {
      Sigsbee.Placid : exact;
   }
   action_profile: Bairoa;
   size : Range;
}

control Coventry {
   if ((Sigsbee.Placid & 0x2000) == 0x2000) {
      apply(Ravenwood);
   }
}



action ElkPoint() {
   modify_field(Sigsbee.Goodrich, Millhaven.Fairfield);
   modify_field(Sigsbee.VanHorn, Millhaven.Caliente);
   modify_field(Sigsbee.Pinetop, Millhaven.Crooks);
   modify_field(Sigsbee.Campton, Millhaven.Neubert);
   modify_field(Sigsbee.Blakeslee, Millhaven.PellLake);
}

table Bulverde {
   actions {
      ElkPoint;
   }
   default_action : ElkPoint();
   size : 1;
}

control FortHunt {
   if (Millhaven.PellLake!=0 ) {
      apply( Bulverde );
   }
}

action Halbur() {
   modify_field(Sigsbee.Gobles, 1);
   modify_field(Sigsbee.Argentine, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Millhaven.Reagan);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Sigsbee.Blakeslee);
}

action Bayshore() {
}



@pragma ways 1
table Stewart {
   reads {
      Sigsbee.Goodrich : exact;
      Sigsbee.VanHorn : exact;
   }
   actions {
      Halbur;
      Bayshore;
   }
   default_action : Bayshore;
   size : 1;
}

action Essex() {
   modify_field(Sigsbee.Melmore, 1);
   modify_field(Sigsbee.Novinger, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Sigsbee.Blakeslee, Adair);
}

table Kaplan {
   actions {
      Essex;
   }
   default_action : Essex;
   size : 1;
}

action Casnovia() {
   modify_field(Sigsbee.Nanson, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Sigsbee.Blakeslee);
}

table Beeler {
   actions {
      Casnovia;
   }
   default_action : Casnovia();
   size : 1;
}

action Boutte(Herring) {
   modify_field(Sigsbee.Kinsley, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Herring);
   modify_field(Sigsbee.Placid, Herring);
}

action Moseley(PaloAlto) {
   modify_field(Sigsbee.Melmore, 1);
   modify_field(Sigsbee.Traskwood, PaloAlto);
}

action Chemult() {
}

table Moorcroft {
   reads {
      Sigsbee.Goodrich : exact;
      Sigsbee.VanHorn : exact;
      Sigsbee.Blakeslee : exact;
   }

   actions {
      Boutte;
      Moseley;
      Chemult;
   }
   default_action : Chemult();
   size : Mangham;
}

control Norcatur {
   if (Millhaven.Vacherie == 0 and not valid(Berlin) ) {
      apply(Moorcroft) {
         Chemult {
            apply(Stewart) {
               Bayshore {
                  if ((Sigsbee.Goodrich & 0x010000) == 0x010000) {
                     apply(Kaplan);
                  } else {
                     apply(Beeler);
                  }
               }
            }
         }
      }
   }
}

action Habersham() {
   modify_field(Millhaven.Salome, 1);
   Enhaut();
}

table Biscay {
   actions {
      Habersham;
   }
   default_action : Habersham;
   size : 1;
}

control Abilene {
   if (Millhaven.Vacherie == 0) {
      if ((Sigsbee.Powelton==0) and (Millhaven.Ellicott==0) and (Millhaven.Merrill==0) and (Millhaven.Shopville==Sigsbee.Placid)) {
         apply(Biscay);
      }
   }
}

action Joice(Coconut) {
    modify_field(ig_intr_md_for_tm.level2_exclusion_id, Coconut);
}

table Curlew {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Joice;
    }
    size : 512;
}

control Burrel {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Curlew);
   }
}



action Munich( Weyauwega ) {
   modify_field( Sigsbee.Lucien, Weyauwega );
}

action Plano() {
   modify_field( Sigsbee.Lucien, Sigsbee.Blakeslee );
}

table Attalla {
   reads {
      eg_intr_md.egress_port : exact;
      Sigsbee.Blakeslee : exact;
   }

   actions {
      Munich;
      Plano;
   }
   default_action : Plano;
   size : Whiteclay;
}

control Lofgreen {
   apply( Attalla );
}



action Annville( Westboro, Highfill ) {
   modify_field( Sigsbee.Paradis, Westboro );
   modify_field( Sigsbee.LaCenter, Highfill );
}

action Clearlake( Glynn, Shoup, Jackpot, Ponder ) {
   modify_field( Sigsbee.Paradis, Glynn );
   modify_field( Sigsbee.LaCenter, Shoup );
   modify_field( Sigsbee.Westway, Jackpot );
   modify_field( Sigsbee.Lapeer, Ponder );
}


table Grays {
   reads {
      Sigsbee.RockPort : exact;
   }

   actions {
      Annville;
      Clearlake;
   }
   size : Veteran;
}

action Maceo(Torrance, Layton, Mustang, Rumson) {
   modify_field( Sigsbee.Ridgetop, Torrance );
   modify_field( Sigsbee.Shelby, Layton );
   modify_field( Sigsbee.Shorter, Mustang );
   modify_field( Sigsbee.Nighthawk, Rumson );
}

table Fallis {
   reads {
        Sigsbee.Cullen : exact;
   }
   actions {
      Maceo;
   }
   size : Flaxton;
}

action Unity() {
   no_op();
}

action Junior() {
   modify_field( Thalia.Ramos, Trimble[0].Abbott );
   remove_header( Trimble[0] );
}

table EastLake {
   actions {
      Junior;
   }
   default_action : Junior;
   size : Myrick;
}

action Maxwelton() {
   no_op();
}

action Peletier() {
   add_header( Trimble[ 0 ] );
   modify_field( Trimble[0].Frewsburg, Sigsbee.Lucien );
   modify_field( Trimble[0].Abbott, Thalia.Ramos );
   modify_field( Trimble[0].NantyGlo, Millhaven.Kekoskee );
   modify_field( Trimble[0].Lathrop, Millhaven.Nicolaus );
   modify_field( Thalia.Ramos, LasLomas );
}



table Milano {
   reads {
      Sigsbee.Lucien : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Maxwelton;
      Peletier;
   }
   default_action : Peletier;
   size : Felton;
}

action Blencoe() {
   modify_field(Thalia.Edroy, Sigsbee.Goodrich);
   modify_field(Thalia.Lamboglia, Sigsbee.VanHorn);
   modify_field(Thalia.Albin, Sigsbee.Paradis);
   modify_field(Thalia.Assinippi, Sigsbee.LaCenter);
}

action Speed() {
   Blencoe();
   add_to_field(Denmark.Tusayan, -1);
}

action Segundo() {
   Blencoe();
   add_to_field(Valders.Rosboro, -1);
}

action Varnado() {
   Peletier();
}

action Nestoria() {
   add_header( Wondervu );
   modify_field( Wondervu.Edroy, Sigsbee.Paradis );
   modify_field( Wondervu.Lamboglia, Sigsbee.LaCenter );
   modify_field( Wondervu.Albin, Sigsbee.Westway );
   modify_field( Wondervu.Assinippi, Sigsbee.Lapeer );
   modify_field( Wondervu.Ramos, Burwell );
   add_header( Berlin );
   modify_field( Berlin.Thomas, Sigsbee.Ridgetop );
   modify_field( Berlin.Edgemont, Sigsbee.Shelby );
   modify_field( Berlin.Churchill, Sigsbee.Shorter );
   modify_field( Berlin.National, Sigsbee.Nighthawk );
   modify_field( Berlin.Brodnax, Sigsbee.Emerado );
}

action Biehle() {
   remove_header( Cadley );
   remove_header( Chambers );
   remove_header( Auburn );
   copy_header( Thalia, Molino );
   remove_header( Molino );
   remove_header( Denmark );
}

action Waubun() {
   remove_header( Wondervu );
   remove_header( Berlin );
}

table Ireton {
   reads {
      Sigsbee.Green : exact;
      Sigsbee.RockPort : exact;
      Sigsbee.Powelton : exact;
      Denmark.valid : ternary;
      Valders.valid : ternary;
   }

   actions {
      Speed;
      Segundo;
      Varnado;
      Nestoria;
      Biehle;
      Waubun;
   }
   size : Udall;
}

control McHenry {
   apply( EastLake );
}

control McIntosh {
   apply( Milano );
}

control Farson {
   apply( Grays );
   apply( Fallis );
   apply( Ireton );
}



field_list Verndale {
    Cherokee.Blueberry;
    Millhaven.PellLake;
    Molino.Albin;
    Molino.Assinippi;
    Denmark.Fannett;
}

action LaFayette() {
   generate_digest(Mingus, Verndale);
}

table Lynne {
   actions {
      LaFayette;
   }

   default_action : LaFayette;
   size : 1;
}

control Zemple {
   if (Millhaven.Roxobel == 1) {
      apply(Lynne);
   }
}



action Kahua( Maiden ) {
   modify_field( Klawock.Ocilla, Maiden );
}

action Waldport() {
   modify_field( Klawock.Ocilla, 0 );
}

table Telegraph {
   reads {
     Millhaven.Shopville : ternary;
     Millhaven.Welaka : ternary;
     GunnCity.Cowell : ternary;
   }

   actions {
     Kahua;
     Waldport;
   }

   default_action : Waldport();
   size : Kokadjo;
}

action Dubach( Decorah ) {
   modify_field( Klawock.Whitewood, Decorah );
   modify_field( Klawock.Ironia, 0 );
   modify_field( Klawock.Tontogany, 0 );
}

action Bouton( Eureka, Rosalie ) {
   modify_field( Klawock.Whitewood, 0 );
   modify_field( Klawock.Ironia, Eureka );
   modify_field( Klawock.Tontogany, Rosalie );
}

action Seagate( Twichell, Weskan, Sublett ) {
   modify_field( Klawock.Whitewood, Twichell );
   modify_field( Klawock.Ironia, Weskan );
   modify_field( Klawock.Tontogany, Sublett );
}

action Havana() {
   modify_field( Klawock.Whitewood, 0 );
   modify_field( Klawock.Ironia, 0 );
   modify_field( Klawock.Tontogany, 0 );
}

table Covert {
   reads {
     Klawock.Ocilla : exact;
     Millhaven.Fairfield : ternary;
     Millhaven.Caliente : ternary;
     Millhaven.Cement : ternary;
   }

   actions {
     Dubach;
     Bouton;
     Seagate;
     Havana;
   }

   default_action : Havana();
   size : Lacombe;
}

table Donnelly {
   reads {
     Klawock.Ocilla : exact;
     Cannelton.Barnhill mask 0xffff0000 : ternary;
     Millhaven.Mankato : ternary;
     Millhaven.Ferndale : ternary;
     Millhaven.Osseo : ternary;
     GlenRose.Riverbank : ternary;

   }

   actions {
     Dubach;
     Bouton;
     Seagate;
     Havana;
   }

   default_action : Havana();
   size : Poipu;
}

table Glenpool {
   reads {
     Klawock.Ocilla : exact;
     IttaBena.Devers mask 0xffff0000 : ternary;
     Millhaven.Mankato : ternary;
     Millhaven.Ferndale : ternary;
     Millhaven.Osseo : ternary;
     GlenRose.Riverbank : ternary;

   }

   actions {
     Dubach;
     Bouton;
     Seagate;
     Havana;
   }

   default_action : Havana();
   size : Kranzburg;
}

meter VanZandt {
   type : packets;
   static : Rudolph;
   instance_count: Casselman;
}

action Caulfield( Melstrand ) {
   // Unsupported address mode
   //execute_meter( VanZandt, Melstrand, ig_intr_md_for_tm.packet_color );
}

action Captiva() {
   execute_meter( VanZandt, Klawock.Ironia, ig_intr_md_for_tm.packet_color );
}

table Rudolph {
   reads {
     Klawock.Ironia : ternary;
     Millhaven.Shopville : ternary;
     Millhaven.Welaka : ternary;
     GunnCity.Cowell : ternary;
     Klawock.Tontogany : ternary;
   }
   actions {
      Caulfield;
      Captiva;
   }
   size : Couchwood;
}

control Hueytown {
   apply( Telegraph );
}

control Knierim {
   if ( Millhaven.Eolia == 1 ) {
      apply( Donnelly );
   } else if ( Millhaven.Grizzly == 1 ) {
      apply( Glenpool );
   } else {
      apply( Covert );
   }
}

control Telephone {
   apply( Rudolph );
}



action Gardiner() {
   modify_field( Millhaven.Kekoskee, Owentown.Broadford );
}



action Terrytown() {
   modify_field( Millhaven.Kekoskee, Trimble[0].NantyGlo );
}

action Hamburg() {
   modify_field( Millhaven.Osseo, Owentown.Moline );
}

action Uvalde() {
   modify_field( Millhaven.Osseo, Cannelton.Benitez );
}

action Westend() {
   modify_field( Millhaven.Osseo, IttaBena.Finlayson );
}

action Quivero( Annandale, Higbee ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Annandale );
   modify_field( ig_intr_md_for_tm.qid, Higbee );
}

table Unionvale {
   reads {
     Millhaven.LaVale : exact;
   }

   actions {
     Gardiner;
     Terrytown;
   }

   size : Caplis;
}

table Camargo {
   reads {
     Millhaven.Eolia : exact;
     Millhaven.Grizzly : exact;
   }

   actions {
     Hamburg;
     Uvalde;
     Westend;
   }

   size : Covington;
}

table Holcut {
   reads {
      Owentown.Cascadia : ternary;
      Owentown.Broadford : ternary;
      Millhaven.Kekoskee : ternary;
      Millhaven.Osseo : ternary;
      Klawock.Whitewood : ternary;
   }

   actions {
      Quivero;
   }

   size : Bayne;
}

control Suffern {
   apply( Unionvale );
   apply( Camargo );
}

control Morgana {
   apply( Holcut );
}



action Eugene( ElJebel ) {
   modify_field( Sigsbee.RockPort, Cochrane );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, ElJebel );
}

action Comunas( BoyRiver ) {
   modify_field( Sigsbee.RockPort, Lucerne );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, BoyRiver );
   modify_field( Sigsbee.Cullen, ig_intr_md.ingress_port );
}

table Floris {
   reads {
      GunnCity.Cowell : exact;
      Owentown.Leicester : ternary;
      Sigsbee.Emerado : ternary;
   }

   actions {
      Eugene;
      Comunas;
   }

   size : Emmorton;
}

control Center {
   apply( Floris );
}





counter Crump {
   type : packets_and_bytes;
   direct : Minburn;
   min_width: 32;
}

table Minburn {
   reads {
      eg_intr_md.egress_port mask 0x7f : exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }

   actions {
      McDaniels;
   }

   size : Madras;
}

control Thermal {
   apply( Minburn );
}



action Marydel()
{



   Enhaut();
}

action Parkline()
{
   modify_field(Sigsbee.Green, Hackamore);
   bit_or(Sigsbee.Placid, 0x2000, Berlin.National);
}

action Pembine( Fairborn ) {
   modify_field(Sigsbee.Green, Hackamore);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Fairborn);
   modify_field(Sigsbee.Placid, Fairborn);
}

table Westoak {
   reads {
      Berlin.Thomas : exact;
      Berlin.Edgemont : exact;
      Berlin.Churchill : exact;
      Berlin.National : exact;
   }

   actions {
      Parkline;
      Pembine;
      Marydel;
   }
   default_action : Marydel();
   size : Flaxton;
}

control Bramwell {
   apply( Westoak );
}

control ingress {

   Elkville();

   if( Owentown.Jarreau != 0 ) {

      Lanyon();
   }

   Tunis();

   if( Owentown.Jarreau != 0 ) {
      Eastover();
      BlackOak();
   }

   Pearce();


   Maltby();
   Oriskany();

   if( Owentown.Jarreau != 0 ) {

      Oshoto();
   }


   Finney();


   if( Owentown.Jarreau != 0 ) {
      Penrose();
   }

   FortHunt();


   if( Owentown.Jarreau != 0 ) {
      Tindall();
   }
   Suffern();
   Hueytown();




   Zemple();
   Montross();
   if( Sigsbee.Monteview == 0 ) {
      Norcatur();
   }


   Knierim();

   if( Sigsbee.Monteview == 0 ) {
   if( not valid(Berlin) ) {
      Abilene();
   } else {
      Bramwell();
   }
   }


   if( valid( Trimble[0] ) ) {
      McHenry();
   }


   Morgana();
   if( Millhaven.Vacherie == 0 ) {
      Telephone();
   }
   if( Sigsbee.Monteview == 0 ) {
      Burrel();
   }
   if( Sigsbee.Monteview == 1 ) {
      Center();
   } else {
      Coventry();
   }
}

control egress {
   Lofgreen();
   Farson();

   if( ( Sigsbee.Monteview == 0 ) and ( Sigsbee.Green != Hackamore ) ) {
      McIntosh();
   }
   Thermal();
}

