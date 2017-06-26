// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 142426







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>






@pragma pa_solitary ingress Counce.Montegut
@pragma pa_solitary ingress Counce.Romero
@pragma pa_solitary ingress Counce.Otranto
@pragma pa_solitary egress Milan.Pensaukee
@pragma pa_solitary ig_intr_md_for_tm.ucast_egress_port
@pragma pa_atomic ingress McGrady.Rhodell
@pragma pa_solitary ingress McGrady.Rhodell
@pragma pa_atomic ingress McGrady.Glennie
@pragma pa_solitary ingress McGrady.Glennie



#ifndef Moraine
#define Moraine

header_type Newsome {
	fields {
		Columbia : 16;
		Sully : 16;
		Minoa : 8;
		Sandpoint : 8;
		Gerty : 8;
		Kremlin : 8;
		OakCity : 1;
		Gratis : 1;
		Grenville : 1;
		Lilly : 1;
		Pecos : 1;
		Maryhill : 3;
	}
}

header_type Chaska {
	fields {
		Rehoboth : 24;
		Kekoskee : 24;
		Carnero : 24;
		Crestline : 24;
		Heidrick : 16;
		Montegut : 16;
		Romero : 16;
		Otranto : 16;
		Jigger : 16;
		Cusseta : 8;
		Riley : 8;
		AukeBay : 6;
		Camilla : 1;
		Narka : 1;
		White : 12;
		DelMar : 2;
		Berkley : 1;
		Blakeslee : 1;
		Ivanpah : 1;
		Harpster : 1;
		Latham : 1;
		Sagerton : 1;
		Immokalee : 1;
		Crown : 1;
		Toklat : 1;
		Piqua : 1;
		Notus : 1;
		SanSimon : 1;
		PineLawn : 1;
		Elcho : 3;
	}
}

header_type Lenexa {
	fields {
		Hobucken : 24;
		Keenes : 24;
		Melder : 24;
		Brimley : 24;
		Pfeifer : 24;
		Kanab : 24;
		Aguada : 24;
		Coverdale : 24;
		OldTown : 16;
		Siloam : 16;
		Nason : 16;
		Pensaukee : 16;
		LaJara : 12;
		Piermont : 3;
		Lolita : 1;
		Tiverton : 3;
		Neoga : 1;
		Ruthsburg : 1;
		Nutria : 1;
		Fairborn : 1;
		Rolla : 1;
		McKamie : 8;
		Loretto : 1;
		Dundalk : 1;
	}
}


header_type Brave {
	fields {
		Pilottown : 8;
		Speedway : 1;
		Carrizozo : 1;
		Suring : 1;
		Piedmont : 1;
		OreCity : 1;
		Yerington : 1;
	}
}

header_type Camelot {
	fields {
		Wartburg : 32;
		Humacao : 32;
		Everetts : 6;
		Mancelona : 16;
	}
}

header_type Rapids {
	fields {
		Manakin : 128;
		Alnwick : 128;
		EastLake : 20;
		Ringwood : 8;
		Flynn : 11;
		Lewellen : 8;
		Hewitt : 13;
	}
}

header_type Wamego {
	fields {
		Evendale : 14;
		Dillsburg : 1;
		Sedan : 12;
		Glenside : 1;
		Neches : 1;
		Glenolden : 6;
		Millbrae : 2;
		Calvary : 6;
		Cushing : 3;
	}
}

header_type Sewaren {
	fields {
		Tarnov : 1;
		Trammel : 1;
	}
}

header_type Cankton {
	fields {
		Stowe : 8;
	}
}

header_type Windham {
	fields {
		Affton : 16;
		Hennessey : 11;
	}
}

header_type Edinburgh {
	fields {
		National : 32;
		Combine : 32;
		Currie : 32;
	}
}

header_type Leola {
	fields {
		Rhodell : 32;
		Glennie : 32;
	}
}

header_type Naches {
	fields {
		WolfTrap : 2;
	}
}
#endif



#ifndef Hibernia
#define Hibernia


header_type Sandoval {
	fields {
		Silvertip : 6;
		Wausaukee : 10;
		Delavan : 4;
		HighHill : 12;
		Mystic : 12;
		Beechwood : 2;
		Elmore : 3;
		Gastonia : 8;
		Fowler : 7;
	}
}



header_type Clementon {
	fields {
		BallClub : 24;
		Wainaku : 24;
		Cathcart : 24;
		Pardee : 24;
		Sahuarita : 16;
	}
}



header_type Renfroe {
	fields {
		Waseca : 3;
		Lilymoor : 1;
		Wenden : 12;
		Fleetwood : 16;
	}
}



header_type Bowdon {
	fields {
		Emlenton : 4;
		Poland : 4;
		Whitakers : 6;
		Barstow : 2;
		Olive : 16;
		Hopland : 16;
		Soledad : 3;
		Faith : 13;
		Malabar : 8;
		Bigfork : 8;
		Browndell : 16;
		Altus : 32;
		Slade : 32;
	}
}

header_type Glenvil {
	fields {
		Mendon : 4;
		Pevely : 6;
		Quinwood : 2;
		Hamden : 20;
		Wyndmere : 16;
		Upland : 8;
		Lambrook : 8;
		TiePlant : 128;
		Dozier : 128;
	}
}




header_type Eureka {
	fields {
		Lawnside : 8;
		Mullins : 8;
		Kaluaaha : 16;
	}
}

header_type Natalbany {
	fields {
		Nooksack : 16;
		Millbrook : 16;
		McCloud : 32;
		Needles : 32;
		Moorewood : 4;
		Shoup : 4;
		Grants : 8;
		Beltrami : 16;
		Raritan : 16;
		MoonRun : 16;
	}
}

header_type Ossineke {
	fields {
		Linda : 16;
		Monteview : 16;
		Gosnell : 16;
		Almeria : 16;
	}
}



header_type Napanoch {
	fields {
		Weskan : 16;
		Ojibwa : 16;
		Centre : 8;
		UtePark : 8;
		Cornell : 16;
	}
}

header_type Virgilina {
	fields {
		Hahira : 48;
		Pocopson : 32;
		Tonasket : 48;
		NantyGlo : 32;
	}
}



header_type Tuscumbia {
	fields {
		Jessie : 1;
		Parmele : 1;
		Rushmore : 1;
		DimeBox : 1;
		Ahuimanu : 1;
		Marydel : 3;
		Hillsview : 5;
		Wollochet : 3;
		Tusayan : 16;
	}
}

header_type Callery {
	fields {
		Kerrville : 24;
		Tontogany : 8;
	}
}



header_type DewyRose {
	fields {
		Mulvane : 8;
		Brownson : 24;
		Ambrose : 24;
		Blanchard : 8;
	}
}

#endif



#ifndef Ronan
#define Ronan

#define Maxwelton        0x8100
#define Trooper        0x0800
#define Conneaut        0x86dd
#define Gambrill        0x9100
#define Mabank        0x8847
#define Norborne         0x0806
#define Eastwood        0x8035
#define Wittman        0x88cc
#define Nashoba        0x8809
#define Pettigrew      0xD28B

#define Albemarle              1
#define WhiteOwl              2
#define Calva              4
#define Sharptown               6
#define GilaBend               17
#define Kilbourne                47

#define Cortland         0x501
#define Hurst          0x506
#define OldMines          0x511
#define Grabill          0x52F


#define Talent                 4789



#define Laneburg               0
#define Palatine              1
#define Revere                2



#define Laxon          0
#define Creston          4095
#define Weatherby  4096
#define FairOaks  8191



#define Monico                      0
#define Halley                  0
#define Edinburg                 1

header Clementon McDavid;
header Clementon Poulan;
header Renfroe Walcott[ 2 ];
header Bowdon Harviell;
header Bowdon Tivoli;
header Glenvil Dunedin;
header Glenvil Anaconda;
header Natalbany Luttrell;
header Ossineke Picabo;
header Natalbany Danforth;
header Ossineke Sabina;
header DewyRose Mammoth;
header Napanoch McDermott;
header Tuscumbia Ledoux;
header Sandoval Ramapo;
header Clementon Coolin;

parser start {
   return select(current(96, 16)) {
      Pettigrew : Kurthwood;
      default : Mapleview;
   }
}

parser Struthers {
   extract( Ramapo );
   return Mapleview;
}

parser Kurthwood {
   extract( Coolin );
   return Struthers;
}

parser Mapleview {
   extract( McDavid );
   return select( McDavid.Sahuarita ) {
      Maxwelton : CleElum;
      Trooper : Talco;
      Conneaut : Willard;
      Norborne  : Comfrey;
      default        : ingress;
   }
}

parser CleElum {
   extract( Walcott[0] );


   set_metadata(Tyrone.Pecos, 1);
   return select( Walcott[0].Fleetwood ) {
      Trooper : Talco;
      Conneaut : Willard;
      Norborne  : Comfrey;
      default : ingress;
   }
}

parser Talco {
   extract( Harviell );
   set_metadata(Tyrone.Minoa, Harviell.Bigfork);
   set_metadata(Tyrone.Gerty, Harviell.Malabar);
   set_metadata(Tyrone.Columbia, Harviell.Olive);
   set_metadata(Tyrone.Grenville, 0);
   set_metadata(Tyrone.OakCity, 1);
   return select(Harviell.Faith, Harviell.Poland, Harviell.Bigfork) {
      OldMines : Cahokia;
      default : ingress;
   }
}

parser Willard {
   extract( Anaconda );
   set_metadata(Tyrone.Minoa, Anaconda.Upland);
   set_metadata(Tyrone.Gerty, Anaconda.Lambrook);
   set_metadata(Tyrone.Columbia, Anaconda.Wyndmere);
   set_metadata(Tyrone.Grenville, 1);
   set_metadata(Tyrone.OakCity, 0);
   return ingress;
}

parser Comfrey {
   extract( McDermott );
   return ingress;
}

parser Cahokia {
   extract(Picabo);
   return select(Picabo.Monteview) {
      Talent : Pelican;
      default : ingress;
    }
}

parser NewSite {
   set_metadata(Counce.DelMar, Revere);
   return Choptank;
}

parser Waucousta {
   set_metadata(Counce.DelMar, Revere);
   return Truro;
}

parser Lofgreen {
   extract(Ledoux);
   return select(Ledoux.Jessie, Ledoux.Parmele, Ledoux.Rushmore, Ledoux.DimeBox, Ledoux.Ahuimanu,
             Ledoux.Marydel, Ledoux.Hillsview, Ledoux.Wollochet, Ledoux.Tusayan) {
      Trooper : NewSite;
      Conneaut : Waucousta;
      default : ingress;
   }
}

parser Pelican {
   extract(Mammoth);
   set_metadata(Counce.DelMar, Palatine);
   return Lakin;
}

parser Choptank {
   extract( Tivoli );
   set_metadata(Tyrone.Sandpoint, Tivoli.Bigfork);
   set_metadata(Tyrone.Kremlin, Tivoli.Malabar);
   set_metadata(Tyrone.Sully, Tivoli.Olive);
   set_metadata(Tyrone.Lilly, 0);
   set_metadata(Tyrone.Gratis, 1);
   return ingress;
}

parser Truro {
   extract( Dunedin );
   set_metadata(Tyrone.Sandpoint, Dunedin.Upland);
   set_metadata(Tyrone.Kremlin, Dunedin.Lambrook);
   set_metadata(Tyrone.Sully, Dunedin.Wyndmere);
   set_metadata(Tyrone.Lilly, 1);
   set_metadata(Tyrone.Gratis, 0);
   return ingress;
}

parser Lakin {
   extract( Poulan );
   return select( Poulan.Sahuarita ) {
      Trooper: Choptank;
      Conneaut: Truro;
      default: ingress;
   }
}
#endif



@pragma pa_no_pack ingress Naylor.Cushing Milan.Ruthsburg
@pragma pa_no_pack ingress Naylor.Cushing Counce.Elcho
@pragma pa_no_pack ingress Naylor.Cushing Tyrone.Maryhill
@pragma pa_no_pack ingress Naylor.Glenolden Milan.Ruthsburg
@pragma pa_no_pack ingress Naylor.Glenolden Counce.Elcho
@pragma pa_no_pack ingress Naylor.Glenolden Tyrone.Maryhill

@pragma pa_no_pack ingress Naylor.Neches Milan.Fairborn
@pragma pa_no_pack ingress Naylor.Neches Milan.Nutria
@pragma pa_no_pack ingress Naylor.Neches Milan.Neoga
@pragma pa_no_pack ingress Naylor.Neches Counce.Camilla
@pragma pa_no_pack ingress Naylor.Neches Counce.Camilla
@pragma pa_no_pack ingress Naylor.Neches Tyrone.Lilly
@pragma pa_no_pack ingress Naylor.Neches Tyrone.Grenville
@pragma pa_no_pack ingress Naylor.Neches Wildell.OreCity

@pragma pa_no_pack ingress Naylor.Glenolden Counce.PineLawn
@pragma pa_no_pack ingress Naylor.Glenolden Tyrone.Pecos

@pragma pa_no_pack ingress Naylor.Millbrae Counce.Elcho
@pragma pa_no_pack ingress Naylor.Millbrae Tyrone.Maryhill

@pragma pa_no_pack ingress Naylor.Neches Counce.Elcho
@pragma pa_no_pack ingress Naylor.Neches Tyrone.Maryhill
@pragma pa_no_pack ingress Naylor.Neches Counce.Latham

@pragma pa_no_pack ingress Naylor.Neches Counce.PineLawn
@pragma pa_no_pack ingress Naylor.Neches Milan.Loretto
@pragma pa_no_pack ingress Naylor.Neches Tyrone.Pecos
@pragma pa_no_pack ingress Naylor.Neches Milan.Rolla

metadata Chaska Counce;
metadata Lenexa Milan;
metadata Wamego Naylor;
metadata Newsome Tyrone;
metadata Camelot Bowers;
metadata Rapids Panola;
metadata Sewaren Snowball;
metadata Brave Wildell;
metadata Cankton Ridgewood;
metadata Windham Tiskilwa;
metadata Leola McGrady;
metadata Edinburgh Contact;
metadata Naches Daleville;













#undef Woodbury

#undef Schofield
#undef NewCity
#undef Homeland
#undef GunnCity
#undef Anguilla

#undef Shipman
#undef Norbeck
#undef Center

#undef SantaAna
#undef Pinetop
#undef Eggleston
#undef Leeville
#undef Gasport
#undef Ramos
#undef Placid
#undef Fairland
#undef Palatka
#undef Burmah
#undef Portis
#undef Theta
#undef Bleecker
#undef Burien
#undef SoapLake
#undef Pathfork
#undef Manasquan
#undef Euren
#undef Worthing
#undef Onslow
#undef Mattapex

#undef KingCity
#undef Despard
#undef Anawalt
#undef Kosciusko
#undef Cropper
#undef Protem
#undef VanHorn
#undef Ashwood
#undef Gamaliel
#undef Lyndell
#undef Ochoa
#undef Ragley
#undef Omemee
#undef Bellamy
#undef Kamas
#undef Remsen


#undef Amite

#undef Papeton
#undef BirchBay
#undef Emmorton
#undef Iraan

#undef Hemlock






#define Woodbury 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Schofield      65536
#define NewCity      65536
#define Homeland 512
#define GunnCity 512
#define Anguilla      512


#define Shipman     1024
#define Norbeck    1024
#define Center     256


#define SantaAna 512
#define Pinetop 65536
#define Eggleston 65536
#define Leeville 28672
#define Gasport   16384
#define Ramos 8192
#define Placid         131072
#define Fairland 65536
#define Palatka 1024
#define Burmah 2048
#define Portis 16384
#define Theta 8192
#define Bleecker 65536

#define Burien 0x0000000000000000FFFFFFFFFFFFFFFF


#define SoapLake 0x000fffff
#define Euren 2

#define Pathfork 0xFFFFFFFFFFFFFFFF0000000000000000

#define Manasquan 0x000007FFFFFFFFFF0000000000000000
#define Worthing  6
#define Mattapex        2048
#define Onslow       65536


#define KingCity 1024
#define Despard 4096
#define Anawalt 4096
#define Kosciusko 4096
#define Cropper 4096
#define Protem 1024
#define VanHorn 4096
#define Gamaliel 64
#define Lyndell 1
#define Ochoa  8
#define Ragley 512
#define Remsen 256


#define Omemee 1
#define Bellamy 3
#define Kamas 80


#define Amite 0



#define Papeton 2048


#define BirchBay 4096



#define Emmorton 2048
#define Iraan 4096




#define Hemlock    4096

#endif



#ifndef Auburn
#define Auburn

action FlatLick() {
   no_op();
}

action Hatteras() {
   modify_field(Counce.Harpster, 1 );
}

action Hanford() {
   no_op();
}
#endif

















action StarLake(Ramah, Meyers, Kaweah, Conejo, Canfield, Bergton,
                 Chugwater, Moneta, Orting) {
    modify_field(Naylor.Evendale, Ramah);
    modify_field(Naylor.Dillsburg, Meyers);
    modify_field(Naylor.Sedan, Kaweah);
    modify_field(Naylor.Glenside, Conejo);
    modify_field(Naylor.Neches, Canfield);
    modify_field(Naylor.Glenolden, Bergton);
    modify_field(Naylor.Millbrae, Chugwater);
    modify_field(Naylor.Cushing, Moneta);
    modify_field(Naylor.Calvary, Orting);
}

@pragma command_line --no-dead-code-elimination
table Pilar {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        StarLake;
    }
    size : Woodbury;
}

control Tecumseh {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Pilar);
    }
}





action Mescalero(Egypt) {
   modify_field( Milan.Lolita, 1 );
   modify_field( Milan.McKamie, Egypt);
   modify_field( Counce.Piqua, 1 );
}

action Aurora() {
   modify_field( Counce.Immokalee, 1 );
   modify_field( Counce.SanSimon, 1 );
}

action Elrosa() {
   modify_field( Counce.Piqua, 1 );
}

action Baltic() {
   modify_field( Counce.Notus, 1 );
}

action Dunnellon() {
   modify_field( Counce.SanSimon, 1 );
}


table Wellsboro {
   reads {
      McDavid.BallClub : ternary;
      McDavid.Wainaku : ternary;
   }

   actions {
      Mescalero;
      Aurora;
      Elrosa;
      Baltic;
      Dunnellon;
   }
   default_action : Dunnellon();
   size : Homeland;
}

action Coachella() {
   modify_field( Counce.Crown, 1 );
}


table Romney {
   reads {
      McDavid.Cathcart : ternary;
      McDavid.Pardee : ternary;
   }

   actions {
      Coachella;
   }
   size : GunnCity;
}


control LaPlant {
   apply( Wellsboro );
   apply( Romney );
}




action Putnam() {
   modify_field( Bowers.Wartburg, Tivoli.Altus );
   modify_field( Bowers.Humacao, Tivoli.Slade );
   modify_field( Bowers.Everetts, Tivoli.Whitakers );
   modify_field( Panola.Manakin, Dunedin.TiePlant );
   modify_field( Panola.Alnwick, Dunedin.Dozier );
   modify_field( Panola.EastLake, Dunedin.Hamden );


   modify_field( Counce.Rehoboth, Poulan.BallClub );
   modify_field( Counce.Kekoskee, Poulan.Wainaku );
   modify_field( Counce.Carnero, Poulan.Cathcart );
   modify_field( Counce.Crestline, Poulan.Pardee );
   modify_field( Counce.Heidrick, Poulan.Sahuarita );
   modify_field( Counce.Jigger, Tyrone.Sully );
   modify_field( Counce.Cusseta, Tyrone.Sandpoint );
   modify_field( Counce.Riley, Tyrone.Kremlin );
   modify_field( Counce.Narka, Tyrone.Gratis );
   modify_field( Counce.Camilla, Tyrone.Lilly );
   modify_field( Counce.PineLawn, 0 );
   modify_field( Naylor.Millbrae, 2 );
   modify_field( Naylor.Cushing, 0 );
   modify_field( Naylor.Calvary, 0 );
}

action Thach() {
   modify_field( Counce.DelMar, Laneburg );
   modify_field( Bowers.Wartburg, Harviell.Altus );
   modify_field( Bowers.Humacao, Harviell.Slade );
   modify_field( Bowers.Everetts, Harviell.Whitakers );
   modify_field( Panola.Manakin, Anaconda.TiePlant );
   modify_field( Panola.Alnwick, Anaconda.Dozier );
   modify_field( Panola.EastLake, Anaconda.Hamden );


   modify_field( Counce.Rehoboth, McDavid.BallClub );
   modify_field( Counce.Kekoskee, McDavid.Wainaku );
   modify_field( Counce.Carnero, McDavid.Cathcart );
   modify_field( Counce.Crestline, McDavid.Pardee );
   modify_field( Counce.Heidrick, McDavid.Sahuarita );
   modify_field( Counce.Jigger, Tyrone.Columbia );
   modify_field( Counce.Cusseta, Tyrone.Minoa );
   modify_field( Counce.Riley, Tyrone.Gerty );
   modify_field( Counce.Narka, Tyrone.OakCity );
   modify_field( Counce.Camilla, Tyrone.Grenville );
   modify_field( Counce.Elcho, Tyrone.Maryhill );
   modify_field( Counce.PineLawn, Tyrone.Pecos );
}

table Separ {
   reads {
      McDavid.BallClub : exact;
      McDavid.Wainaku : exact;
      Harviell.Slade : exact;
      Counce.DelMar : exact;
   }

   actions {
      Putnam;
      Thach;
   }

   default_action : Thach();
   size : KingCity;
}


action Trujillo() {
   modify_field( Counce.Montegut, Naylor.Sedan );
   modify_field( Counce.Romero, Naylor.Evendale);
}

action Neubert( Dumas ) {
   modify_field( Counce.Montegut, Dumas );
   modify_field( Counce.Romero, Naylor.Evendale);
}

action Marcus() {
   modify_field( Counce.Montegut, Walcott[0].Wenden );
   modify_field( Counce.Romero, Naylor.Evendale);
}

table Pickering {
   reads {
      Naylor.Evendale : ternary;
      Walcott[0] : valid;
      Walcott[0].Wenden : ternary;
   }

   actions {
      Trujillo;
      Neubert;
      Marcus;
   }
   size : Kosciusko;
}

action Grampian( Dushore ) {
   modify_field( Counce.Romero, Dushore );
}

action Blakeley() {

   modify_field( Counce.Ivanpah, 1 );
   modify_field( Ridgewood.Stowe,
                 Edinburg );
}

table Grays {
   reads {
      Harviell.Altus : exact;
   }

   actions {
      Grampian;
      Blakeley;
   }
   default_action : Blakeley;
   size : Anawalt;
}

action Hisle( Esmond, ElDorado, Macungie, Durant, Oakton,
                        Sanford, Levittown ) {
   modify_field( Counce.Montegut, Esmond );
   modify_field( Counce.Sagerton, Levittown );
   Milltown(ElDorado, Macungie, Durant, Oakton,
                        Sanford );
}

action Lovilia() {
   modify_field( Counce.Latham, 1 );
}

table Accord {
   reads {
      Mammoth.Ambrose : exact;
   }

   actions {
      Hisle;
      Lovilia;
   }
   size : Despard;
}

action Milltown(Union, Vinings, Switzer, Hansell,
                        Foristell ) {
   modify_field( Wildell.Pilottown, Union );
   modify_field( Wildell.Speedway, Vinings );
   modify_field( Wildell.Suring, Switzer );
   modify_field( Wildell.Carrizozo, Hansell );
   modify_field( Wildell.Piedmont, Foristell );
}

action Algodones(Finlayson, RedLevel, Damar, Upalco,
                        LaUnion ) {
   modify_field( Counce.Otranto, Naylor.Sedan );
   modify_field( Counce.Sagerton, 1 );
   Milltown(Finlayson, RedLevel, Damar, Upalco,
                        LaUnion );
}

action Dwight(Neshoba, Goulding, Heizer, Joice,
                        LakeFork, Golden ) {
   modify_field( Counce.Otranto, Neshoba );
   modify_field( Counce.Sagerton, 1 );
   Milltown(Goulding, Heizer, Joice, LakeFork,
                        Golden );
}

action Suntrana(Sarasota, Cochrane, Gully, Whitman,
                        Hagewood ) {
   modify_field( Counce.Otranto, Walcott[0].Wenden );
   modify_field( Counce.Sagerton, 1 );
   Milltown(Sarasota, Cochrane, Gully, Whitman,
                        Hagewood );
}

table Diana {
   reads {
      Naylor.Sedan : exact;
   }


   actions {
      FlatLick;
      Algodones;
   }

   size : Cropper;
}

@pragma action_default_only FlatLick
table Atlantic {
   reads {
      Naylor.Evendale : exact;
      Walcott[0].Wenden : exact;
   }

   actions {
      Dwight;
      FlatLick;
   }

   size : Protem;
}

table Mantee {
   reads {
      Walcott[0].Wenden : exact;
   }


   actions {
      FlatLick;
      Suntrana;
   }

   size : VanHorn;
}

control Donner {
   apply( Separ ) {
         Putnam {
            apply( Grays );
            apply( Accord );
         }
         Thach {
            if ( Naylor.Glenside == 1 ) {
               apply( Pickering );
            }
            if ( valid( Walcott[ 0 ] ) ) {

               apply( Atlantic ) {
                  FlatLick {

                     apply( Mantee );
                  }
               }
            } else {

               apply( Diana );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Shidler {
    width  : 1;
    static : Maiden;
    instance_count : 262144;
}

register Jefferson {
    width  : 1;
    static : RedHead;
    instance_count : 262144;
}

blackbox stateful_alu Moxley {
    reg : Shidler;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Snowball.Tarnov;
}

blackbox stateful_alu Shorter {
    reg : Jefferson;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Snowball.Trammel;
}

field_list Kiana {
    Naylor.Glenolden;
    Walcott[0].Wenden;
}

field_list_calculation Topawa {
    input { Kiana; }
    algorithm: identity;
    output_width: 18;
}

action Pringle() {
    Moxley.execute_stateful_alu_from_hash(Topawa);
}

action Rardin() {
    Shorter.execute_stateful_alu_from_hash(Topawa);
}

table Maiden {
    actions {
      Pringle;
    }
    default_action : Pringle;
    size : 1;
}

table RedHead {
    actions {
      Rardin;
    }
    default_action : Rardin;
    size : 1;
}
#endif

action Endicott(Callao) {
    modify_field(Snowball.Trammel, Callao);
}

@pragma  use_hash_action 0
table Gower {
    reads {
       Naylor.Glenolden : exact;
    }
    actions {
      Endicott;
    }
    size : 64;
}

action Grigston() {
   modify_field( Counce.White, Naylor.Sedan );
   modify_field( Counce.Berkley, 0 );
}

table Olmitz {
   actions {
      Grigston;
   }
   size : 1;
}

action Penzance() {
   modify_field( Counce.White, Walcott[0].Wenden );
   modify_field( Counce.Berkley, 1 );
}

table Cotuit {
   actions {
      Penzance;
   }
   size : 1;
}

control Amber {
   if ( valid( Walcott[ 0 ] ) ) {
      apply( Cotuit );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Naylor.Neches == 1 ) {
         apply( Maiden );
         apply( RedHead );
      }
#endif
   } else {
      apply( Olmitz );
      if( Naylor.Neches == 1 ) {
         apply( Gower );
      }
   }
}




field_list Brackett {
   McDavid.BallClub;
   McDavid.Wainaku;
   McDavid.Cathcart;
   McDavid.Pardee;
   McDavid.Sahuarita;
}

field_list Quinault {

   Harviell.Bigfork;
   Harviell.Altus;
   Harviell.Slade;
}

field_list LaSal {
   Anaconda.TiePlant;
   Anaconda.Dozier;
   Anaconda.Hamden;
   Anaconda.Upland;
}

field_list Dillsboro {
   Harviell.Altus;
   Harviell.Slade;
   Picabo.Linda;
   Picabo.Monteview;
}





field_list_calculation Tamora {
    input {
        Brackett;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Campton {
    input {
        Quinault;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Gillette {
    input {
        LaSal;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Boyle {
    input {
        Dillsboro;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Gilliatt() {
    modify_field_with_hash_based_offset(Contact.National, 0,
                                        Tamora, 4294967296);
}

action Calabash() {
    modify_field_with_hash_based_offset(Contact.Combine, 0,
                                        Campton, 4294967296);
}

action Waimalu() {
    modify_field_with_hash_based_offset(Contact.Combine, 0,
                                        Gillette, 4294967296);
}

action Hammonton() {
    modify_field_with_hash_based_offset(Contact.Currie, 0,
                                        Boyle, 4294967296);
}

table Plateau {
   actions {
      Gilliatt;
   }
   size: 1;
}

control Wells {
   apply(Plateau);
}

table Stateline {
   actions {
      Calabash;
   }
   size: 1;
}

table Menomonie {
   actions {
      Waimalu;
   }
   size: 1;
}

control Mission {
   if ( valid( Harviell ) ) {
      apply(Stateline);
   } else {
      if ( valid( Anaconda ) ) {
         apply(Menomonie);
      }
   }
}

table Keltys {
   actions {
      Hammonton;
   }
   size: 1;
}

control Hector {
   if ( valid( Picabo ) ) {
      apply(Keltys);
   }
}



action Osage() {
    modify_field(McGrady.Rhodell, Contact.National);
}

action MiraLoma() {
    modify_field(McGrady.Rhodell, Contact.Combine);
}

action Flaxton() {
    modify_field(McGrady.Rhodell, Contact.Currie);
}

@pragma action_default_only FlatLick
@pragma immediate 0
table Andrade {
   reads {
      Danforth.valid : ternary;
      Sabina.valid : ternary;
      Tivoli.valid : ternary;
      Dunedin.valid : ternary;
      Poulan.valid : ternary;
      Luttrell.valid : ternary;
      Picabo.valid : ternary;
      Harviell.valid : ternary;
      Anaconda.valid : ternary;
      McDavid.valid : ternary;
   }
   actions {
      Osage;
      MiraLoma;
      Flaxton;
      FlatLick;
   }
   size: Center;
}

action Unionvale() {
    modify_field(McGrady.Glennie, Contact.Currie);
}

@pragma immediate 0
table Forbes {
   reads {
      Danforth.valid : ternary;
      Sabina.valid : ternary;
      Luttrell.valid : ternary;
      Picabo.valid : ternary;
   }
   actions {
      Unionvale;
      FlatLick;
   }
   size: Worthing;
}

control Higgins {
   apply(Forbes);
   apply(Andrade);
}



counter Barwick {
   type : packets_and_bytes;
   direct : Hokah;
   min_width: 16;
}

@pragma action_default_only FlatLick
table Hokah {
   reads {
      Naylor.Glenolden : exact;
      Snowball.Trammel : ternary;
      Snowball.Tarnov : ternary;
      Counce.Latham : ternary;
      Counce.Crown : ternary;
      Counce.Immokalee : ternary;
   }

   actions {
      Hatteras;
      FlatLick;
   }
   size : Anguilla;
}

action Vacherie() {

   modify_field(Counce.Blakeslee, 1 );
   modify_field(Ridgewood.Stowe,
                Halley);
}







table Frewsburg {
   reads {
      Counce.Carnero : exact;
      Counce.Crestline : exact;
      Counce.Montegut : exact;
      Counce.Romero : exact;
   }

   actions {
      Hanford;
      Vacherie;
   }
   size : NewCity;
   support_timeout : true;
}

action Ocoee() {
   modify_field( Wildell.OreCity, 1 );
}

table Klawock {
   reads {
      Counce.Otranto : ternary;
      Counce.Rehoboth : exact;
      Counce.Kekoskee : exact;
   }
   actions {
      Ocoee;
   }
   size: SantaAna;
}

control Retrop {
   apply( Hokah ) {
      FlatLick {



         if (Naylor.Dillsburg == 0 and Counce.Ivanpah == 0) {
            apply( Frewsburg );
         }
         apply(Klawock);
      }
   }
}

field_list Dunnstown {
    Ridgewood.Stowe;
    Counce.Carnero;
    Counce.Crestline;
    Counce.Montegut;
    Counce.Romero;
}

action Vinemont() {
   generate_digest(Monico, Dunnstown);
}

table Stirrat {
   actions {
      Vinemont;
   }
   size : 1;
}

control Ridgeview {
   if (Counce.Blakeslee == 1) {
      apply( Stirrat );
   }
}



action Monsey( LoonLake, Baskett ) {
   modify_field( Panola.Hewitt, LoonLake );
   modify_field( Tiskilwa.Affton, Baskett );
}

@pragma action_default_only Pollard
table Margie {
   reads {
      Wildell.Pilottown : exact;
      Panola.Alnwick mask Pathfork : lpm;
   }
   actions {
      Monsey;
      Pollard;
   }
   size : Theta;
}

@pragma atcam_partition_index Panola.Hewitt
@pragma atcam_number_partitions Theta
table Tinsman {
   reads {
      Panola.Hewitt : exact;
      Panola.Alnwick mask Manasquan : lpm;
   }

   actions {
      Yorkville;
      Richwood;
      FlatLick;
   }
   default_action : FlatLick();
   size : Bleecker;
}

action Welch( Mendota, Bremond ) {
   modify_field( Panola.Flynn, Mendota );
   modify_field( Tiskilwa.Affton, Bremond );
}

@pragma action_default_only FlatLick
table Pidcoke {


   reads {
      Wildell.Pilottown : exact;
      Panola.Alnwick : lpm;
   }

   actions {
      Welch;
      FlatLick;
   }

   size : Burmah;
}

@pragma atcam_partition_index Panola.Flynn
@pragma atcam_number_partitions Burmah
table Rendon {
   reads {
      Panola.Flynn : exact;


      Panola.Alnwick mask Burien : lpm;
   }
   actions {
      Yorkville;
      Richwood;
      FlatLick;
   }

   default_action : FlatLick();
   size : Portis;
}

@pragma action_default_only Pollard
@pragma idletime_precision 1
table SomesBar {

   reads {
      Wildell.Pilottown : exact;
      Bowers.Humacao : lpm;
   }

   actions {
      Yorkville;
      Richwood;
      Pollard;
   }

   size : Palatka;
   support_timeout : true;
}

action Lynne( WoodDale, Montague ) {
   modify_field( Bowers.Mancelona, WoodDale );
   modify_field( Tiskilwa.Affton, Montague );
}

@pragma action_default_only FlatLick
#ifdef PROFILE_DEFAULT
@pragma stage 2 Ramos
@pragma stage 3
#endif
table Denmark {
   reads {
      Wildell.Pilottown : exact;
      Bowers.Humacao : lpm;
   }

   actions {
      Lynne;
      FlatLick;
   }

   size : Gasport;
}

@pragma ways Euren
@pragma atcam_partition_index Bowers.Mancelona
@pragma atcam_number_partitions Gasport
table Brantford {
   reads {
      Bowers.Mancelona : exact;
      Bowers.Humacao mask SoapLake : lpm;
   }
   actions {
      Yorkville;
      Richwood;
      FlatLick;
   }
   default_action : FlatLick();
   size : Placid;
}

action Yorkville( Amity ) {
   modify_field( Tiskilwa.Affton, Amity );
}

@pragma idletime_precision 1
table Cairo {
   reads {
      Wildell.Pilottown : exact;
      Bowers.Humacao : exact;
   }

   actions {
      Yorkville;
      Richwood;
      FlatLick;
   }
   default_action : FlatLick();
   size : Pinetop;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
@pragma stage 2 Leeville
@pragma stage 3
#endif
table Monowi {
   reads {
      Wildell.Pilottown : exact;
      Panola.Alnwick : exact;
   }

   actions {
      Yorkville;
      Richwood;
      FlatLick;
   }
   default_action : FlatLick();
   size : Eggleston;
   support_timeout : true;
}

action Hayward(Sallisaw, RyanPark, Duchesne) {
   modify_field(Milan.OldTown, Duchesne);
   modify_field(Milan.Hobucken, Sallisaw);
   modify_field(Milan.Keenes, RyanPark);
   modify_field(Milan.Dundalk, 1);
}

action Santos() {
   modify_field(Counce.Harpster, 1);
}

action Crossett(Bokeelia) {
   modify_field(Milan.Lolita, 1);
   modify_field(Milan.McKamie, Bokeelia);
}

action Pollard() {
   modify_field( Milan.Lolita, 1 );
   modify_field( Milan.McKamie, 9 );
}

table Broadwell {
   reads {
      Tiskilwa.Affton : exact;
   }

   actions {
      Hayward;
      Santos;
      Crossett;
   }
   size : Fairland;
}

control SandCity {
   if ( Counce.Harpster == 0 and Wildell.OreCity == 1 ) {
      if ( ( Wildell.Speedway == 1 ) and ( Counce.Narka == 1 ) ) {
         apply( Cairo ) {
            FlatLick {
               apply( Denmark ) {
                  Lynne {
                     apply( Brantford );
                  }
                  FlatLick {
                     apply( SomesBar );
                  }
               }
            }
         }
      } else if ( ( Wildell.Suring == 1 ) and ( Counce.Camilla == 1 ) ) {
         apply( Monowi ) {
            FlatLick {
               apply( Pidcoke ) {
                  Welch {
                     apply( Rendon );
                  }
                  FlatLick {

                     apply( Margie ) {
                        Monsey {
                           apply( Tinsman ) ;
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

control Algonquin {
   if( Tiskilwa.Affton != 0 ) {
      apply( Broadwell );
   }
}

action Richwood( LaPuente ) {
   modify_field( Tiskilwa.Hennessey, LaPuente );
   modify_field( Wildell.Yerington, 1 );
}

field_list Rankin {
   McGrady.Glennie;
}

field_list_calculation Sumner {
    input {
        Rankin;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Duque {
   selection_key : Sumner;
   selection_mode : resilient;
}

action_profile Fontana {
   actions {
      Yorkville;
   }
   size : Onslow;
   dynamic_action_selection : Duque;
}

table PinkHill {
   reads {
      Tiskilwa.Hennessey : exact;
   }
   action_profile : Fontana;
   size : Mattapex;
}

control Blanding {
   if ( Tiskilwa.Hennessey != 0 ) {
      apply( PinkHill );
   }
}



field_list Lapel {
   McGrady.Rhodell;
}

field_list_calculation DeSmet {
    input {
        Lapel;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Weimar {
    selection_key : DeSmet;
    selection_mode : resilient;
}

action Waring(Cantwell) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Cantwell);
}

action_profile Masontown {
    actions {
        Waring;
        FlatLick;
    }
    size : Norbeck;
    dynamic_action_selection : Weimar;
}

table Cross {
   reads {
      Milan.Nason : exact;
   }
   action_profile: Masontown;
   size : Shipman;
}

control Lookeba {
   if ((Milan.Nason & 0x2000) == 0x2000) {
      apply(Cross);
   }
}



meter Davisboro {
   type : packets;
   static : Opelousas;
   instance_count: Papeton;
}

action Glassboro(Oregon) {
   execute_meter(Davisboro, Oregon, Daleville.WolfTrap);
}

table Opelousas {
   reads {
      Naylor.Glenolden : exact;
      Milan.McKamie : exact;
   }
   actions {
      Glassboro;
   }
   size : Emmorton;
}

counter Lanesboro {
   type : packets;
   static : Scottdale;
   instance_count : BirchBay;
   min_width: 64;
}

action Kiron(DeRidder) {
   modify_field(Counce.Harpster, 1);
   count(Lanesboro, DeRidder);
}

action Deering(Woodsdale) {
   count(Lanesboro, Woodsdale);
}

action Duelm(Nashwauk, Gorman) {
   modify_field(ig_intr_md_for_tm.qid, Nashwauk);
   count(Lanesboro, Gorman);
}

action Mariemont(Hydaburg, Timken, Cidra) {
   modify_field(ig_intr_md_for_tm.qid, Hydaburg);
   modify_field(ig_intr_md_for_tm.ingress_cos, Timken);
   count(Lanesboro, Cidra);
}

action DoeRun(Guayabal) {
   modify_field(ig_intr_md_for_tm.copy_to_cpu, 1);
   count(Lanesboro, Guayabal);
}

table Scottdale {
   reads {
      Naylor.Glenolden : exact;
      Milan.McKamie : exact;
      Daleville.WolfTrap : exact;
   }

   actions {
      Kiron;
      Duelm;
      Mariemont;
      Deering;
      DoeRun;
   }
size : Iraan;
}



action Suffern() {
   modify_field(Milan.Hobucken, Counce.Rehoboth);
   modify_field(Milan.Keenes, Counce.Kekoskee);
   modify_field(Milan.Melder, Counce.Carnero);
   modify_field(Milan.Brimley, Counce.Crestline);
   modify_field(Milan.OldTown, Counce.Montegut);
}

table Robinette {
   actions {
      Suffern;
   }
   default_action : Suffern();
   size : 1;
}

control Halsey {
   if (Counce.Montegut!=0) {
      apply( Robinette );
   }
}

action Calverton() {
   modify_field(Milan.Ruthsburg, 1);
   modify_field(Milan.Neoga, 1);
   modify_field(Milan.Pensaukee, Milan.OldTown);
}

action Clarendon() {
}



@pragma ways 1
table Findlay {
   reads {
      Milan.Hobucken : exact;
      Milan.Keenes : exact;
   }
   actions {
      Calverton;
      Clarendon;
   }
   default_action : Clarendon;
   size : 1;
}

action Biloxi() {
   modify_field(Milan.Nutria, 1);
   modify_field(Milan.Loretto, 1);
   add(Milan.Pensaukee, Milan.OldTown, Weatherby);
}

table Sylvan {
   actions {
      Biloxi;
   }
   default_action : Biloxi;
   size : 1;
}

action Lilydale() {
   modify_field(Milan.Rolla, 1);
   modify_field(Milan.Pensaukee, Milan.OldTown);
}

table NewTrier {
   actions {
      Lilydale;
   }
   default_action : Lilydale();
   size : 1;
}

action Spivey(Anandale) {
   modify_field(Milan.Fairborn, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Anandale);
   modify_field(Milan.Nason, Anandale);
}

action Gresston(Cabery) {
   modify_field(Milan.Nutria, 1);
   modify_field(Milan.Pensaukee, Cabery);
}

action Jayton() {
}

table Sedona {
   reads {
      Milan.Hobucken : exact;
      Milan.Keenes : exact;
      Milan.OldTown : exact;
   }

   actions {
      Spivey;
      Gresston;
      Jayton;
   }
   default_action : Jayton();
   size : Schofield;
}

control Reddell {
   if (Counce.Harpster == 0 ) {
      apply(Sedona) {
         Jayton {
            apply(Findlay) {
               Clarendon {
                  if ((Milan.Hobucken & 0x010000) == 0x010000) {
                     apply(Sylvan);
                  } else {
                     apply(NewTrier);
                  }
               }
            }
         }
      }
   }
}

action Colver() {
   modify_field(Counce.Toklat, 1);
   modify_field(Counce.Harpster, 1);
}

table Westvaco {
   actions {
      Colver;
   }
   default_action : Colver;
   size : 1;
}

control Helotes {
   if (Counce.Harpster == 0) {
      if ((Milan.Dundalk==0) and (Counce.Romero==Milan.Nason)) {
         apply(Westvaco);
      } else {
         apply(Opelousas);
         apply(Scottdale);
      }
   }
}



action Saticoy( Rudolph ) {
   modify_field( Milan.LaJara, Rudolph );
}

action Leoma() {
   modify_field( Milan.LaJara, Milan.OldTown );
}

table Raven {
   reads {
      eg_intr_md.egress_port : exact;
      Milan.OldTown : exact;
   }

   actions {
      Saticoy;
      Leoma;
   }
   default_action : Leoma;
   size : Hemlock;
}

control Merced {
   apply( Raven );
}



action Whitefish( Joshua, Roseau ) {
   modify_field( Milan.Pfeifer, Joshua );
   modify_field( Milan.Kanab, Roseau );
}

action Manteo( Craigmont, Hanamaulu, Kennedale, Lacona ) {
   modify_field( Milan.Pfeifer, Craigmont );
   modify_field( Milan.Kanab, Hanamaulu );
   modify_field( Milan.Aguada, Kennedale );
   modify_field( Milan.Coverdale, Lacona );
}


table Vananda {
   reads {
      Milan.Piermont : exact;
   }

   actions {
      Whitefish;
      Manteo;
   }
   size : Ochoa;
}

action Newberg() {
   no_op();
}

action ElPortal() {
   modify_field( McDavid.Sahuarita, Walcott[0].Fleetwood );
   remove_header( Walcott[0] );
}

table Cowen {
   actions {
      ElPortal;
   }
   default_action : ElPortal;
   size : Lyndell;
}

action Tununak() {
   no_op();
}

action Emmet() {
   add_header( Walcott[ 0 ] );
   modify_field( Walcott[0].Wenden, Milan.LaJara );
   modify_field( Walcott[0].Fleetwood, McDavid.Sahuarita );
   modify_field( McDavid.Sahuarita, Maxwelton );
}



table Maumee {
   reads {
      Milan.LaJara : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Tununak;
      Emmet;
   }
   default_action : Emmet;
   size : Gamaliel;
}

action Gladden() {
   modify_field(McDavid.BallClub, Milan.Hobucken);
   modify_field(McDavid.Wainaku, Milan.Keenes);
   modify_field(McDavid.Cathcart, Milan.Pfeifer);
   modify_field(McDavid.Pardee, Milan.Kanab);
}

action Holliday() {
   Gladden();
   add_to_field(Harviell.Malabar, -1);
}

action Chatfield() {
   Gladden();
   add_to_field(Anaconda.Lambrook, -1);
}

action McCallum() {
   Emmet();
}

action Letcher() {
   add_header( Coolin );
   modify_field( Coolin.BallClub, Milan.Pfeifer );
   modify_field( Coolin.Wainaku, Milan.Kanab );
   modify_field( Coolin.Cathcart, 0x020000 );
   modify_field( Coolin.Pardee, 0 );


   modify_field( Coolin.Sahuarita, Pettigrew );
   add_header( Ramapo );
   modify_field( Ramapo.Gastonia, Milan.McKamie );
}

table Whatley {
   reads {
      Milan.Tiverton : exact;
      Milan.Piermont : exact;
      Milan.Dundalk : exact;
      Harviell.valid : ternary;
      Anaconda.valid : ternary;
   }

   actions {
      Holliday;
      Chatfield;
      McCallum;
      Letcher;
   }
   size : Ragley;
}

control RioLinda {
   apply( Cowen );
}

control Sespe {
   apply( Maumee );
}

control Farragut {
   apply( Vananda );
   apply( Whatley );
}



field_list Neponset {
    Ridgewood.Stowe;
    Counce.Montegut;
    Poulan.Cathcart;
    Poulan.Pardee;
    Harviell.Altus;
}

action Jericho() {
   generate_digest(Monico, Neponset);
}

table Pearl {
   actions {
      Jericho;
   }

   default_action : Jericho;
   size : 1;
}

control Raiford {
   if (Counce.Ivanpah == 1) {
      apply(Pearl);
   }
}



action Burtrum() {
   modify_field( Counce.Elcho, Naylor.Cushing );
}

action Newpoint() {
   modify_field( Counce.AukeBay, Naylor.Calvary );
}

action Orrville() {
   modify_field( Counce.AukeBay, Bowers.Everetts );
}

action Kosmos() {
   modify_field( Counce.AukeBay, Panola.Lewellen );
}

action Samantha( Shauck, Willows ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Shauck );
   modify_field( ig_intr_md_for_tm.qid, Willows );
}

table Suarez {
   reads {
     Counce.PineLawn : exact;
   }

   actions {
     Burtrum;
   }

   size : Omemee;
}

table Mentmore {
   reads {
     Counce.Narka : exact;
     Counce.Camilla : exact;
   }

   actions {
     Newpoint;
     Orrville;
     Kosmos;
   }

   size : Bellamy;
}

@pragma stage 10
table Annville {
   reads {
      Naylor.Millbrae : exact;
      Naylor.Cushing : ternary;
      Counce.Elcho : ternary;
      Counce.AukeBay : ternary;
   }

   actions {
      Samantha;
   }

   size : Kamas;
}

control Ravena {
   apply( Suarez );
   apply( Mentmore );
}

control Mattawan {
   apply( Annville );
}




#define Melrose            0
#define Cardenas  1
#define Careywood 2


#define Amsterdam           0



action Corvallis( Lyncourt ) {
   modify_field( Milan.Piermont, Cardenas );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Lyncourt );
}

action Daysville( Seaforth ) {
   modify_field( Milan.Piermont, Careywood );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Seaforth );
}










table Exeter {
   reads {
      Wildell.OreCity : exact;
      Counce.PineLawn :ternary;
      Naylor.Glenside : ternary;
      Milan.McKamie : ternary;
   }

   actions {
      Corvallis;
      Daysville;
   }

   size : Remsen;
}

control Longdale {
   apply( Exeter );
}


control ingress {

   Tecumseh();
   LaPlant();
   Donner();
   Amber();
   Wells();


   Ravena();
   Retrop();

   Mission();
   Hector();


   SandCity();
   Higgins();
   Blanding();

   Halsey();

   Algonquin();






   if( Milan.Lolita == 0 ) {
      Reddell();
   } else {
      Longdale();
   }
   Mattawan();


   Helotes();
   Lookeba();
   Raiford();
   Ridgeview();


   if( valid( Walcott[0] ) ) {
      RioLinda();
   }






}

control egress {
   Merced();
   Farragut();

   if( Milan.Lolita == 0 ) {
      Sespe();
   }
}

