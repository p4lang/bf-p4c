// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 941

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
#include <tofino/wred_blackbox.p4>
#include <tofino/meter_blackbox.p4>

// Test program exceeds Tof1 egress parse depth
@pragma command_line --disable-parse-max-depth-limit

@pragma pa_container_size ingress Jenkins.Amesville 32
@pragma pa_container_size ingress Auburn.Ralls 32
@pragma pa_container_size ingress Millsboro.Sespe 16
@pragma pa_container_size egress Arial.Magma 16
header_type Gorman {
	fields {
		Lofgreen : 16;
		Prismatic : 8;
		Osseo : 8;
		Point : 4;
		Morrow : 3;
		Thistle : 3;
		Toxey : 3;
	}
}
header_type SaintAnn {
	fields {
		Snyder : 24;
		Radcliffe : 24;
		Fragaria : 24;
		Darien : 24;
		Midville : 16;
		Kiwalik : 12;
		Boise : 20;
		Biggers : 12;
		Cruso : 16;
		Washoe : 8;
		SanPablo : 8;
		Micro : 3;
		Manteo : 3;
		Dedham : 24;
		Wrens : 1;
		Cairo : 3;
		Sontag : 1;
		Minto : 1;
		Waterford : 1;
		Bellvue : 1;
		Maryhill : 1;
		Hendley : 1;
		Lochbuie : 1;
		Beaverton : 1;
		RoyalOak : 1;
		Lutsen : 1;
		Terrell : 1;
		Rocheport : 1;
		Challis : 1;
		Bluford : 1;
		Ledford : 3;
		Whitewood : 1;
		Tyrone : 1;
		Surrey : 1;
		Purdon : 1;
		Charlotte : 1;
		Nipton : 1;
		Aberfoil : 1;
		Pengilly : 1;
		Alamosa : 1;
		Halbur : 1;
		Flats : 1;
		Donnelly : 1;
		Ranburne : 1;
		OldTown : 1;
		Berlin : 1;
		Chevak : 12;
		Yantis : 12;
		Lenox : 16;
		Vananda : 16;
		Sequim : 16;
		Waupaca : 8;
		Duchesne : 16;
		Neubert : 16;
		Hodges : 8;
		Empire : 2;
		Absecon : 2;
		LaUnion : 1;
		Faulkner : 1;
		HighHill : 1;
		Belpre : 32;
		Sieper : 2;
	}
}
header_type Amity {
	fields {
		Ludowici : 1;
	}
}
header_type Otego {
	fields {
		Oxford : 1;
		Palmer : 1;
		Oneonta : 1;
		Wrenshall : 16;
		Boquet : 16;
		Dunmore : 32;
		Elihu : 32;
		Botna : 1;
		LoneJack : 1;
		Oreland : 1;
		Merit : 1;
		Castolon : 1;
		Chilson : 1;
		Haverford : 1;
		Thalmann : 1;
		Glazier : 1;
		Basalt : 1;
		Opelika : 32;
		Norseland : 32;
	}
}
header_type Fowlkes {
	fields {
		Whitakers : 24;
		PawCreek : 24;
		Tappan : 1;
		Cecilton : 3;
		Finney : 1;
		Salome : 12;
		Benitez : 20;
		Telida : 20;
		Bostic : 16;
		Mabel : 16;
		Hartford : 12;
		Bacton : 10;
		Louviers : 3;
		Auberry : 8;
		Clintwood : 1;
		Vestaburg : 32;
		Florahome : 32;
		Wenham : 24;
		Kennedale : 8;
		Herald : 2;
		Winnebago : 32;
		Cartago : 9;
		Leonore : 2;
		Earlimart : 1;
		Nevis : 1;
		Munger : 12;
		Everett : 1;
		Casco : 1;
		Baroda : 1;
		Islen : 2;
		Wauneta : 32;
		Wibaux : 32;
		Philbrook : 8;
		Milam : 24;
		Neavitt : 24;
		Purves : 2;
		Gobler : 1;
		Kingsland : 12;
		Wolford : 1;
		Forkville : 1;
	}
}
header_type Brohard {
	fields {
		Dunkerton : 10;
		Wagener : 10;
		Heppner : 2;
	}
}
header_type Barnsboro {
	fields {
		Tecumseh : 10;
		Edler : 10;
		Frankston : 2;
		Berkley : 8;
		Gowanda : 6;
		Sparland : 16;
		Achille : 4;
		Gibsland : 4;
	}
}
header_type Belvidere {
	fields {
		Viroqua : 10;
		Alnwick : 4;
		Donna : 1;
	}
}
header_type Dundalk {
	fields {
		Brookside : 32;
		Portales : 32;
		Hubbell : 32;
		Darco : 6;
		Tontogany : 6;
		Lovewell : 16;
	}
}
header_type Gibbstown {
	fields {
		ElkNeck : 128;
		LaHabra : 128;
		Micco : 8;
		Helton : 6;
		Rocky : 16;
	}
}
header_type Centre {
	fields {
		Cedar : 14;
		Illmo : 12;
		Baudette : 1;
		Kenova : 2;
	}
}
header_type Tununak {
	fields {
		Wyncote : 1;
		Joshua : 1;
	}
}
header_type Clearmont {
	fields {
		Uncertain : 1;
		Bladen : 1;
	}
}
header_type Cordell {
	fields {
		DelRosa : 2;
	}
}
header_type Rohwer {
	fields {
		Wabuska : 2;
		Sandoval : 16;
		Wallace : 16;
		Newsoms : 2;
		Fayette : 16;
	}
}
header_type Milltown {
	fields {
		Brewerton : 16;
		Grasston : 16;
		Coolin : 16;
		McFaddin : 16;
		OakCity : 16;
	}
}
header_type Winner {
	fields {
		Pettigrew : 16;
		Dillsboro : 16;
	}
}
header_type Dairyland {
	fields {
		Hulbert : 2;
		Sebewaing : 6;
		LasLomas : 3;
		Gravette : 1;
		Ralph : 1;
		Corbin : 1;
		Myton : 3;
		Pevely : 1;
		Nooksack : 6;
		Cranbury : 6;
		Luverne : 5;
		Essex : 1;
		Monkstown : 1;
		Selvin : 1;
		Rockdell : 2;
		Allons : 12;
		Baskin : 1;
	}
}
header_type McClusky {
	fields {
		Belfast : 16;
	}
}
header_type BayPort {
	fields {
		Cutten : 16;
		Puryear : 1;
		Dalton : 1;
	}
}
header_type Sunflower {
	fields {
		Quivero : 16;
		Rendville : 1;
		Novice : 1;
	}
}
header_type Syria {
	fields {
		Gurdon : 16;
		Daysville : 16;
		Carnero : 16;
		Mifflin : 16;
		Compton : 16;
		Ralls : 16;
		Lecanto : 8;
		Hewitt : 8;
		NantyGlo : 8;
		Seaford : 8;
		Green : 1;
		Boerne : 6;
	}
}
header_type Gardiner {
	fields {
		Mayview : 32;
	}
}
header_type Lansdowne {
	fields {
		Amesville : 8;
		Dunstable : 32;
		Gilmanton : 32;
	}
}
header_type Hackett {
	fields {
		Plata : 8;
	}
}
header_type Lovelady {
	fields {
		Kinde : 1;
		Camelot : 1;
		Milesburg : 1;
		Lanesboro : 20;
		BelAir : 12;
	}
}
header_type Shelbina {
	fields {
		Dumas : 8;
		Kasigluk : 16;
		WestLine : 8;
		Brothers : 16;
		Walcott : 8;
		Stehekin : 8;
		Newtok : 8;
		Wheaton : 8;
		Cammal : 8;
		Antoine : 4;
		Utuado : 8;
		SanJuan : 8;
	}
}
header_type Crozet {
	fields {
		Lakefield : 8;
		Ozark : 8;
		Slick : 8;
		BoxElder : 8;
	}
}
header_type Bettles {
	fields {
		Callands : 1;
		Kamas : 1;
		Chardon : 32;
		Nucla : 16;
		Biloxi : 10;
		Cotter : 32;
		Franklin : 20;
		Laneburg : 1;
		Holliday : 1;
		Freeman : 32;
		Picabo : 2;
		Sedona : 1;
	}
}
header_type Olive {
	fields {
		Retrop : 6;
		Delavan : 10;
		Lafayette : 4;
		Granbury : 12;
		Accomac : 2;
		Hoagland : 2;
		Fouke : 12;
		Lemoyne : 8;
		Bluff : 2;
		Fairfield : 3;
		Rosario : 1;
		Saugatuck : 1;
		Christina : 1;
		Barksdale : 4;
		Starkey : 12;
	}
}
header_type NewTrier {
	fields {
		Pembine : 24;
		Yukon : 24;
		Troutman : 24;
		Bucktown : 24;
		Blakeley : 16;
	}
}
header_type Lemhi {
	fields {
		Leeville : 3;
		Saltair : 1;
		Duelm : 12;
		Myoma : 16;
	}
}
header_type BigPlain {
	fields {
		Marlton : 20;
		Benwood : 3;
		Garrison : 1;
		DelRey : 8;
	}
}
header_type Higganum {
	fields {
		Rockvale : 4;
		Tennyson : 4;
		Ribera : 6;
		Pekin : 2;
		Fonda : 16;
		Magma : 16;
		Tulia : 1;
		Excello : 1;
		Homeland : 1;
		Schofield : 13;
		Colonias : 8;
		RioPecos : 8;
		Rosburg : 16;
		Osage : 32;
		Larchmont : 32;
	}
}
header_type Kosciusko {
	fields {
		Holcomb : 4;
		Roggen : 6;
		Suamico : 2;
		Brentford : 20;
		Mellott : 16;
		Rollins : 8;
		Perez : 8;
		Veguita : 128;
		Braselton : 128;
	}
}
header_type Bavaria {
	fields {
		Deloit : 4;
		Wynnewood : 6;
		Laplace : 2;
		Goodyear : 20;
		Biehle : 16;
		Brookneal : 8;
		Roxboro : 8;
		Alabam : 32;
		MiraLoma : 32;
		Craigmont : 32;
		Bellville : 32;
		Hauppauge : 32;
		Goldsboro : 32;
		Welaka : 32;
		Ganado : 32;
	}
}
header_type ElmPoint {
	fields {
		Bridgton : 8;
		Oroville : 8;
		Fosston : 16;
	}
}
header_type Manistee {
	fields {
		McDonough : 32;
	}
}
header_type Ruston {
	fields {
		VanWert : 16;
		Sespe : 16;
	}
}
header_type Lacona {
	fields {
		Mumford : 32;
		Lackey : 32;
		Nordland : 4;
		Marysvale : 4;
		Sultana : 8;
		Bozar : 16;
	}
}
header_type Wyndmere {
	fields {
		Oregon : 16;
	}
}
header_type Marbury {
	fields {
		Mekoryuk : 16;
	}
}
header_type Millstone {
	fields {
		Grapevine : 16;
		Ackley : 16;
		Gullett : 8;
		Suttle : 8;
		Gaston : 16;
	}
}
header_type Pearcy {
	fields {
		Alcalde : 48;
		Arion : 32;
		Conda : 48;
		Ravinia : 32;
	}
}
header_type Parchment {
	fields {
		Hagaman : 1;
		Twisp : 1;
		Frewsburg : 1;
		Macland : 1;
		Baltic : 1;
		Clauene : 3;
		Columbus : 5;
		Tramway : 3;
		McKee : 16;
	}
}
header_type Elderon {
	fields {
		Kaaawa : 24;
		Bolckow : 8;
	}
}
header_type Tehachapi {
	fields {
		Powers : 8;
		Langdon : 24;
		Dunphy : 24;
		Saltdale : 8;
	}
}
header_type Marvin {
	fields {
		Warba : 8;
	}
}
header_type Arvonia {
	fields {
		Heeia : 32;
		Whitten : 32;
	}
}
header_type Roberta {
	fields {
		WestCity : 2;
		Roxobel : 1;
		Lefor : 1;
		Ephesus : 4;
		Nunnelly : 1;
		Verdigris : 7;
		Penalosa : 16;
		Plato : 32;
		Faysville : 32;
	}
}
header_type Parshall {
	fields {
		BigFork : 32;
	}
}
header NewTrier Sutton;
header NewTrier Holliston;
header Lemhi Kress[2];
header BigPlain Ludden[ 1 ];
@pragma pa_fragment ingress Arial.Rosburg
@pragma pa_fragment egress Arial.Rosburg
@pragma pa_container_size ingress Arial.Larchmont 32
@pragma pa_container_size ingress Arial.Osage 32
@pragma pa_container_size egress Arial.Tulia 8
@pragma pa_container_size egress Arial.Excello 8
@pragma pa_container_size egress Arial.Homeland 8
@pragma pa_container_size egress Arial.Schofield 8
header Higganum Arial;
@pragma pa_fragment ingress Parnell.Rosburg
@pragma pa_fragment egress Parnell.Rosburg
@pragma pa_container_size egress Parnell.Schofield 8
@pragma pa_container_size egress Parnell.Tulia 8
@pragma pa_container_size egress Parnell.Excello 8
@pragma pa_container_size egress Parnell.Homeland 8
header Higganum Parnell;
@pragma pa_container_size egress Captiva.Braselton 32
@pragma pa_container_size egress Captiva.Veguita 32
header Kosciusko Captiva;
@pragma pa_container_size ingress Talkeetna.Braselton 32
@pragma pa_container_size egress Talkeetna.Braselton 32
@pragma pa_container_size ingress Talkeetna.Veguita 32
@pragma pa_container_size egress Talkeetna.Veguita 32
header Kosciusko Talkeetna;
header Bavaria Clarinda;
@pragma disable_deparser_checksum_unit 0 1
header Ruston LeaHill;
header Ruston Millsboro;
header Lacona Midas;
header Wyndmere Patchogue;
header Marbury BigRiver;
header Lacona Affton;
header Wyndmere Leland;
header Marbury Brinklow;
@pragma pa_container_size egress Exira.Dunphy 32
@pragma pa_container_size egress Exira.Langdon 32
@pragma pa_container_size ingress Exira.Langdon 32
header Tehachapi Exira;
header Parchment Sterling;
header Millstone Abraham;
header Manistee Clearco;
@pragma pa_container_size egress RedElm.Retrop 32
@pragma not_deparsed ingress
@pragma not_parsed egress
header Olive RedElm;
@pragma not_deparsed ingress
@pragma not_parsed egress
header Marvin Requa;
header Arvonia Meridean;
@pragma parser_value_set_size 2
parser_value_set Gannett;
@pragma parser_value_set_size 32
parser_value_set BigBar;
parser start {
   return select( ig_intr_md.ingress_port ) {
      Gannett : Wellford;
      default : Knoke;
   }
}
@pragma dont_trim
@pragma packet_entry
parser start_i2e_mirrored {
   return ingress;
}
@pragma dont_trim
@pragma packet_entry
parser start_e2e_mirrored {
   return ingress;
}
@pragma dont_trim
@pragma packet_entry
parser start_egress {
   return select( current( 96, 16 ) ) {
     default : Knoke;
      0xBF00 : Othello;
   }
}
parser Lanyon {
   return select( current( 0, 32 ) ) {
      0x00010800 : WyeMills;
      default : ingress;
   }
}
parser WyeMills {
   extract( Abraham );
   return ingress;
}
@pragma not_critical
parser Othello {
   extract( RedElm );
   return Knoke;
}
@pragma force_shift ingress 112
parser Wellford {
   return Dunnville;
}
@pragma not_critical
parser Dunnville {
   extract( RedElm );
   return Knoke;
}
parser Lacombe {
   set_metadata( Lewiston.Point, 0x5 );
   return ingress;
}
parser Herring {
   set_metadata( Lewiston.Point, 0x6 );
   return ingress;
}
parser Tinaja {
   set_metadata( Lewiston.Point, 0x8 );
   return ingress;
}
parser Knoke {
   extract( Sutton );
   return select( current( 0, 8 ), Sutton.Blakeley ) {
      0x9100 mask 0xFFFF : Sitka;
      0x88a8 mask 0xFFFF : Sitka;
      0x8100 mask 0xFFFF : Sitka;
      0x0806 mask 0xFFFF : Lanyon;
      0x450800 : Downs;
      0x50800 mask 0xFFFFF : Lacombe;
      0x0800 mask 0xFFFF : Cadley;
      0x6086dd mask 0xF0FFFF : Sneads;
      0x86dd mask 0xFFFF : Herring;
      0x8808 mask 0xFFFF : Tinaja;
      default : ingress;
      0 : Neponset;
   }
}
parser Suwanee {
   extract( Kress[1] );
   return select( current( 0, 8 ), Kress[1].Myoma ) {
      0x0806 mask 0xFFFF : Lanyon; 0x450800 : Downs; 0x50800 mask 0xFFFFF : Lacombe; 0x0800 mask 0xFFFF : Cadley; 0x6086dd mask 0xF0FFFF : Sneads; 0x86dd mask 0xFFFF : Herring; 0x8808 mask 0xFFFF : Tinaja; default : ingress;
   }
}
parser Sitka {
   extract( Kress[0] );
   return select( current( 0, 8 ), Kress[0].Myoma ) {
      0x8100 mask 0xFFFF : Suwanee;
      0x0806 mask 0xFFFF : Lanyon; 0x450800 : Downs; 0x50800 mask 0xFFFFF : Lacombe; 0x0800 mask 0xFFFF : Cadley; 0x6086dd mask 0xF0FFFF : Sneads; 0x86dd mask 0xFFFF : Herring; 0x8808 mask 0xFFFF : Tinaja; default : ingress;
      0 : Neponset;
   }
}
parser Yemassee {
   set_metadata( Azalia.Midville, 0x0800 );
   set_metadata( Azalia.Cairo, 4 );
   return select( current( 0, 8 ) ) {
      0x45 mask 0xFF : Oakton;
      default : Bechyn;
   }
}
parser Sonora {
   set_metadata( Azalia.Midville, 0x86dd );
   set_metadata( Azalia.Cairo, 4 );
   return Proctor;
}
parser Bradner {
   set_metadata( Azalia.Midville, 0x86dd );
   set_metadata( Azalia.Cairo, 5 );
   return ingress;
}
field_list Childs {
   Arial.Rockvale;
   Arial.Tennyson;
   Arial.Ribera;
   Arial.Pekin;
   Arial.Fonda;
   Arial.Magma;
   Arial.Tulia;
   Arial.Excello;
   Arial.Homeland;
   Arial.Schofield;
   Arial.Colonias;
   Arial.RioPecos;
   Arial.Osage;
   Arial.Larchmont;
}
field_list_calculation Convoy {
   input {
      Childs;
   }
   algorithm : csum16;
   output_width : 16;
}
calculated_field Arial.Rosburg {
   verify Convoy;
   update Convoy;
}
field_list Tolley {
   Azalia.Belpre;
   BigRiver.Mekoryuk;
}
@pragma calculated_field_update_location ingress
field_list_calculation Lilydale {
   input {
      Tolley;
   }
   algorithm : csum16;
   output_width : 16;
}
calculated_field BigRiver.Mekoryuk {
   update Lilydale;
}
parser Downs {
   extract( Arial );
   set_metadata( Azalia.SanPablo, Arial.Colonias );
   set_metadata( Lewiston.Point, 0x1 );
   return select( Arial.Schofield, Arial.RioPecos ) {
      4 : Yemassee;
      41 : Sonora;
      1 : Lumberton;
      17 : Anandale;
      6 : LongPine;
      47 : Duster;
      0 mask 0x1fff00 : ingress;
      6 mask 0xff: Piney;
      default : Shipman;
   }
}
parser Cadley {
   set_metadata( Arial.Larchmont, current( 128, 32 ) );
   set_metadata( Lewiston.Point, 0x3 );
   set_metadata( Arial.Ribera, current( 8, 6 ) );
   set_metadata( Arial.RioPecos, current( 72, 8 ) );
   set_metadata( Azalia.SanPablo, current( 64, 8 ) );
   return ingress;
}
parser Piney {
   set_metadata( Lewiston.Toxey, 5 );
   return ingress;
}
parser Shipman {
   set_metadata( Lewiston.Toxey, 1 );
   return ingress;
}
parser Sneads {
   extract( Talkeetna );
   set_metadata( Azalia.SanPablo, Talkeetna.Perez );
   set_metadata( Lewiston.Point, 0x2 );
   return select( Talkeetna.Rollins ) {
      0x3a : Lumberton;
      17 : Weimar;
      6 : LongPine;
      4 : Yemassee;
      41 : Bradner;
      default : ingress;
   }
}
parser Neponset {
   extract( Clarinda );
   set_metadata( Azalia.SanPablo, Clarinda.Roxboro );
   set_metadata( Lewiston.Point, 0x2 );
   return select( Clarinda.Brookneal ) {
      0x3a : Lumberton;
      17 : Weimar;
      6 : LongPine;
      default : ingress;
   }
}
parser Anandale {
   set_metadata( Lewiston.Toxey, 2 );
   extract( LeaHill );
   extract( Patchogue );
   extract( BigRiver );
   return select( LeaHill.Sespe ) {
      4789 : Throop;
      65330 : Throop;
      default : ingress;
   }
}
header Roberta Gillespie;
parser Longview {
   extract( Gillespie );
   return ingress;
}
parser Lumberton {
   extract( LeaHill );
   return ingress;
}
parser Weimar {
   set_metadata( Lewiston.Toxey, 2 );
   extract( LeaHill );
   extract( Patchogue );
   extract( BigRiver );
   return select( LeaHill.Sespe ) {
      4789 : Corum;
      65330 : Corum;
      default : ingress;
   }
}
parser LongPine {
   set_metadata( Lewiston.Toxey, 6 );
   extract( LeaHill );
   extract( Midas );
   extract( BigRiver );
   return ingress;
}
parser Orosi {
   set_metadata( Azalia.Cairo, 2 );
   return select( current( 4, 4 ) ) {
      0x5 : Oakton;
      default : Bechyn;
   }
}
parser Mendham {
   return select( current( 0, 4 ) ) {
      0x4 : Orosi;
      default : ingress;
   }
}
parser Gamewell {
   set_metadata( Azalia.Cairo, 2 );
   return Proctor;
}
parser Hutchings {
   return select( current( 0, 4 ) ) {
      0x6 : Gamewell;
      default: ingress;
   }
}
parser Duster {
   extract( Sterling );
   return select( Sterling.Hagaman, Sterling.Twisp, Sterling.Frewsburg, Sterling.Macland, Sterling.Baltic,
             Sterling.Clauene, Sterling.Columbus, Sterling.Tramway, Sterling.McKee ) {
      0x0800 : Mendham;
      0x86dd : Hutchings;
      default : ingress;
   }
}
parser Throop {
   set_metadata( Azalia.Cairo, 1 );
   set_metadata( Azalia.Sequim, current( 32, 16 ) );
   set_metadata( Azalia.Waupaca, current( 48, 8 ) );
   extract( Exira );
   return Ekron;
}
parser Corum {
   set_metadata( Azalia.Sequim, current( 32, 16 ) );
   set_metadata( Azalia.Waupaca, current( 48, 8 ) );
   extract( Exira );
   set_metadata( Azalia.Cairo, 1 );
   return Chamois;
}
field_list Alsea {
   Parnell.Rockvale;
   Parnell.Tennyson;
   Parnell.Ribera;
   Parnell.Pekin;
   Parnell.Fonda;
   Parnell.Magma;
   Parnell.Tulia;
   Parnell.Excello;
   Parnell.Homeland;
   Parnell.Schofield;
   Parnell.Colonias;
   Parnell.RioPecos;
   Parnell.Osage;
   Parnell.Larchmont;
}
field_list_calculation GlenRock {
   input {
      Alsea;
   }
   algorithm : csum16;
   output_width : 16;
}
calculated_field Parnell.Rosburg {
   verify GlenRock;
   update GlenRock;
}
parser Oakton {
   extract( Parnell );
   set_metadata( Lewiston.Prismatic, Parnell.RioPecos );
   set_metadata( Lewiston.Osseo, Parnell.Colonias );
   set_metadata( Lewiston.Morrow, 0x1 );
   set_metadata( DewyRose.Brookside, Parnell.Osage );
   set_metadata( DewyRose.Portales, Parnell.Larchmont );
   set_metadata( DewyRose.Darco, Parnell.Ribera );
   return select( Parnell.Schofield, Parnell.RioPecos ) {
      1 : Sparkill;
      17 : Parthenon;
      6 : Callao;
      0 mask 0x1fff00 : ingress;
      6 mask 0xff: Northway;
      default : Chalco;
   }
}
parser Bechyn {
   set_metadata( Lewiston.Morrow, 0x3 );
   set_metadata( DewyRose.Darco, current( 8, 6 ) );
   return ingress;
}
parser Northway {
   set_metadata( Lewiston.Thistle, 5 );
   return ingress;
}
parser Chalco {
   set_metadata( Lewiston.Thistle, 1 );
   return ingress;
}
parser Proctor {
   extract( Captiva );
   set_metadata( Lewiston.Prismatic, Captiva.Rollins );
   set_metadata( Lewiston.Osseo, Captiva.Perez );
   set_metadata( Lewiston.Morrow, 0x2 );
   set_metadata( Picayune.Helton, Captiva.Roggen );
   set_metadata( Picayune.ElkNeck, Captiva.Veguita );
   set_metadata( Picayune.LaHabra, Captiva.Braselton );
   return select( Captiva.Rollins ) {
      0x3a : Sparkill;
      17 : Parthenon;
      6 : Callao;
      default : ingress;
   }
}
parser Sparkill {
   set_metadata( Azalia.Duchesne, current( 0, 16 ) );
   extract( Millsboro );
   return ingress;
}
parser Parthenon {
   set_metadata( Azalia.Duchesne, current( 0, 16 ) );
   set_metadata( Azalia.Neubert, current( 16, 16 ) );
   set_metadata( Lewiston.Thistle, 2 );
   extract( Millsboro );
   extract( Leland );
   extract( Brinklow );
   return ingress;
}
parser Callao {
   set_metadata( Azalia.Duchesne, current( 0, 16 ) );
   set_metadata( Azalia.Neubert, current( 16, 16 ) );
   set_metadata( Azalia.Hodges, current( 104, 8 ) );
   set_metadata( Lewiston.Thistle, 6 );
   extract( Millsboro );
   extract( Affton );
   extract( Brinklow );
   return ingress;
}
parser Venice {
   set_metadata( Lewiston.Morrow, 0x5 );
   return ingress;
}
parser Wells {
   set_metadata( Lewiston.Morrow, 0x6 );
   return ingress;
}
parser Ekron {
   extract( Holliston );
   set_metadata( Azalia.Snyder, Holliston.Pembine );
   set_metadata( Azalia.Radcliffe, Holliston.Yukon );
   set_metadata( Azalia.Midville, Holliston.Blakeley );
   return select( current( 0, 8 ), Holliston.Blakeley ) {
      0x0806 mask 0xFFFF : Lanyon;
      0x450800 : Oakton;
      0x50800 mask 0xFFFFF : Venice;
      0x0800 mask 0xFFFF : Bechyn;
      0x6086dd mask 0xF0FFFF : Proctor;
      0x86dd mask 0xFFFF : Wells;
      default: ingress;
   }
}
parser Chamois {
   extract( Holliston );
   set_metadata( Azalia.Snyder, Holliston.Pembine );
   set_metadata( Azalia.Radcliffe, Holliston.Yukon );
   set_metadata( Azalia.Midville, Holliston.Blakeley );
   return select( current( 0, 8 ), Holliston.Blakeley ) {
      0x0806 mask 0xFFFF : Lanyon;
      0x450800 : Oakton;
      0x50800 mask 0xFFFFF : Venice;
      0x0800 mask 0xFFFF : Bechyn;
      default: ingress;
   }
}
@pragma pa_overlay_stage_separation ingress ig_intr_md_for_tm.qid 1
@pragma pa_container_size ingress ig_intr_md_for_tm.qid 8
@pragma pa_container_size ingress RedElm.Delavan 32
@pragma pa_container_size ingress Antlers.Nooksack 16
@pragma pa_container_size ingress Antlers.Pevely 16
@pragma pa_container_size ingress Antlers.Myton 16
@pragma pa_container_size ingress Azalia.Kiwalik 16
@pragma pa_container_size ingress Sisters.Salome 16
@pragma pa_no_init ingress Azalia.Snyder
@pragma pa_no_init ingress Azalia.Radcliffe
@pragma pa_no_init ingress Azalia.Fragaria
@pragma pa_no_init ingress Azalia.Darien
@pragma pa_container_size ingress Azalia.Nipton 8
@pragma pa_container_size ingress Azalia.Aberfoil 8
@pragma pa_no_init ingress Azalia.Micro
@pragma pa_container_size ingress Azalia.Donnelly 8
@pragma pa_do_not_bridge egress Azalia.Belpre
metadata SaintAnn Azalia;
@pragma pa_allowed_to_share egress Sisters.Nevis Solomon.Tecumseh
@pragma pa_container_size ingress Sisters.Benitez 32
@pragma pa_container_size ingress Sisters.Bacton 32
@pragma pa_container_size ingress Azalia.Empire 32
@pragma pa_no_init ingress Sisters.Whitakers
@pragma pa_no_init ingress Sisters.PawCreek
@pragma pa_container_size ingress Sisters.Vestaburg 32
@pragma pa_no_overlay ingress Sisters.Salome
@pragma pa_solitary ingress Sisters.Salome
metadata Fowlkes Sisters;
metadata Brohard Mausdale;
metadata Barnsboro Solomon;
@pragma pa_container egress Solomon.Edler 159
@pragma pa_container ingress Mausdale.Dunkerton 52
metadata Centre Tarlton;
metadata Gorman Lewiston;
@pragma pa_container_size ingress Naylor.Sandoval 16
@pragma pa_container_size ingress DewyRose.Lovewell 16
metadata Dundalk DewyRose;
@pragma pa_container_size ingress Picayune.Rocky 16
metadata Gibbstown Picayune;
@pragma pa_mutually_exclusive ingress DewyRose.Brookside Picayune.ElkNeck
@pragma pa_mutually_exclusive ingress DewyRose.Portales Picayune.LaHabra
@pragma pa_mutually_exclusive ingress DewyRose.Darco Picayune.Helton
@pragma pa_alias ingress DewyRose.Lovewell Picayune.Rocky
@pragma pa_alias ingress Naylor.Wallace Naylor.Sandoval
metadata Tununak Pikeville;
@pragma pa_container_size egress Stone.Bladen 8
metadata Clearmont Stone;
@pragma pa_container_size ingress Leoma.Viroqua 16
@pragma pa_container_size ingress Leoma.Donna 8
metadata Belvidere Leoma;
metadata Cordell Union;
metadata Rohwer Naylor;
@pragma pa_no_init ingress Riner.Pettigrew
@pragma pa_no_init ingress Riner.Dillsboro
@pragma pa_container_size ingress Riner.Pettigrew 16
@pragma pa_mutually_exclusive ingress Riner.Pettigrew Riner.Dillsboro
metadata Winner Riner;
@pragma pa_no_init ingress McDermott.Brewerton
@pragma pa_no_init ingress McDermott.Grasston
@pragma pa_no_init ingress McDermott.Coolin
@pragma pa_no_init ingress McDermott.McFaddin
@pragma pa_no_init ingress McDermott.OakCity
metadata Milltown McDermott;
metadata Dairyland Antlers;
metadata McClusky Rosalie;
@pragma pa_no_init ingress Bryan.Cutten
@pragma pa_solitary ingress Bryan.Dalton
metadata BayPort Bryan;
@pragma pa_container_size egress Sisters.Wibaux 32
@pragma pa_alias egress Sisters.Wibaux Sisters.Winnebago
@pragma pa_no_init egress Sisters.Wauneta
@pragma pa_no_init egress Sisters.Wibaux
@pragma pa_container_size ingress Navarro.Rendville 8
@pragma pa_no_init ingress Navarro.Quivero
@pragma pa_container_size ingress Navarro.Rendville 8
metadata Sunflower Navarro;
@pragma pa_no_init ingress Auburn.Carnero
@pragma pa_no_init ingress Auburn.Mifflin
metadata Syria Auburn;
metadata Syria Talbert;
metadata Lansdowne Jenkins;
metadata Hackett Wardville;
metadata Lovelady Dialville;
action Northlake() {
   no_op();
}
action Isabel() {
   no_op();
}
@pragma pa_container_size ingress Tarlton.Cedar 16
@pragma pa_container_size ingress Tarlton.Illmo 16
action Giltner(Flippen, Marie, Johnsburg, Hesler ) {
   modify_field(Tarlton.Cedar, Flippen);
   modify_field(Tarlton.Illmo, Marie);
   modify_field(Tarlton.Baudette, Johnsburg);
   modify_field(Tarlton.Kenova, Hesler);
}
@pragma phase0 1
table Summit {
   reads {
      ig_intr_md.ingress_port : exact;
   }
   actions {
      Giltner;
   }
   default_action : Giltner(0,0,0,0);
   size : 288;
}
control Northboro {
   if (ig_intr_md.resubmit_flag == 0) {
      apply(Summit);
   }
}
action MoonRun(McManus, Bozeman) {
   modify_field( Sisters.Finney, 1 );
   modify_field( Sisters.Auberry, McManus);
   modify_field( Azalia.Nipton, 1 );
   modify_field( Antlers.Corbin, Bozeman );
   modify_field( Azalia.Halbur, 1 );
}
action Westland(Mackey, Lutts) {
   modify_field( Sisters.Auberry, Mackey);
   modify_field( Azalia.Nipton, 1 );
   modify_field( Antlers.Corbin, Lutts );
}
action HydePark() {
   modify_field( Azalia.Waterford, 1 );
   modify_field( Azalia.Pengilly, 1 );
}
action McAdams() {
   modify_field( Azalia.Nipton, 1 );
}
action Maloy() {
   modify_field( Azalia.Nipton, 1 );
   modify_field( Azalia.Alamosa, 1 );
}
action Santos() {
   modify_field( Azalia.Aberfoil, 1 );
}
action Selah() {
   modify_field( Azalia.Pengilly, 1 );
}
counter Schroeder {
   type : packets_and_bytes;
   direct : Slayden;
   min_width: 16;
}
@pragma immediate 0
table Slayden {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Sutton.Pembine : ternary;
      Sutton.Yukon : ternary;
   }
   actions {
      MoonRun;
      HydePark;
      McAdams;
      Santos;
      Selah;
      Maloy;
      Westland;
   }
   default_action: Northlake();
   size : 2048;
}
action Cricket() {
   modify_field( Azalia.Bellvue, 1 );
}
table Bayonne {
   reads {
      Sutton.Troutman : ternary;
      Sutton.Bucktown : ternary;
   }
   actions {
      Cricket;
   }
   size : 512;
}
control Galestown {
   apply( Slayden ) {
      MoonRun {
      }
      default {
         Ghent();
      }
   }
   apply( Bayonne );
}
@pragma pa_container ingress Azalia.Halbur 125
@pragma pa_container ingress Dialville.Kinde 125
action LaPlata( Burmah ) {
   modify_field( Dialville.BelAir, Burmah );
}
action Eskridge( Perrin ) {
   LaPlata( Perrin );
}
action Naches( McKamie ) {
   LaPlata( McKamie );
   modify_field( Dialville.Camelot, 1 );
   modify_field( Dialville.Kinde, 1 );
}
action Selawik( Skime, Hallville ) {
   LaPlata( Skime );
   modify_field( Dialville.Kinde, 1 );
   modify_field( Dialville.Milesburg, 1 );
   modify_field( Dialville.Lanesboro, Hallville );
   modify_field( Kress[0].Myoma, Kress[1].Myoma );
   remove_header( Kress[1] );
}
action GlenDean( Woodland ) {
   Eskridge( Woodland );
   modify_field( Kress[0].Myoma, Kress[1].Myoma );
   remove_header( Kress[1] );
}
action Hebbville( Creston, Mattawan ) {
   LaPlata( Creston );
   modify_field( Dialville.Kinde, 1 );
   modify_field( Sisters.Earlimart, 0 );
   modify_field( Sisters.Benitez, Mattawan );
}
action Ladelle( Sandstone, Crestline, Yardville ) {
   LaPlata( Sandstone );
   modify_field( Dialville.Kinde, 1 );
   modify_field( Sisters.Earlimart, 0 );
   modify_field( Sisters.Benitez, Crestline );
   modify_field( Sisters.Salome, Yardville );
}
action Absarokee() {
   modify_field( Sisters.Benitez, Dialville.Lanesboro );
}
action Cascade( Mariemont ) {
   LaPlata( Mariemont );
   modify_field( Sisters.Earlimart, 0 );
   modify_field( Dialville.Kinde, 1 );
}
action Jigger( Swifton, Larose, Henning, WildRose ) {
   LaPlata( Swifton );
   add_header( Kress[1] );
   modify_field( Kress[1].Duelm, Henning );
   modify_field( Kress[1].Myoma, Kress[0].Myoma );
   modify_field( Kress[1].Leeville, WildRose );
   modify_field( Kress[1].Saltair, 0 );
   modify_field( Kress[0].Myoma, 0x8100 );
   modify_field( Sisters.Benitez, Larose );
   modify_field( Dialville.Kinde, 1 );
   modify_field( Sisters.Earlimart, 0 );
}
action Gladys( Petty, Pueblo, Onarga ) {
   LaPlata( Petty );
   add_header( Kress[1] );
   modify_field( Kress[1].Duelm, Pueblo );
   modify_field( Kress[1].Myoma, Kress[0].Myoma );
   modify_field( Kress[1].Leeville, Onarga );
   modify_field( Kress[1].Saltair, 0 );
   modify_field( Kress[0].Myoma, 0x8100 );
   modify_field( Dialville.Kinde, 1 );
   modify_field( Sisters.Earlimart, 0 );
}
action Kensett( Engle, Langlois, Anselmo ) {
   LaPlata( Engle );
   add_header( Kress[1] );
   modify_field( Kress[1].Duelm, Langlois );
   modify_field( Kress[1].Myoma, Kress[0].Myoma );
   modify_field( Kress[1].Leeville, Anselmo );
   modify_field( Kress[1].Saltair, 0 );
   modify_field( Kress[0].Myoma, 0x8100 );
}
action Felida( Gandy, Nanson, Skillman, MintHill ) {
   LaPlata( Gandy );
   modify_field( Dialville.Kinde, 1 );
   modify_field( Sisters.Earlimart, 0 );
   modify_field( Sisters.Benitez, Nanson );
   modify_field( Sisters.Whitakers, Skillman );
   modify_field( Sisters.PawCreek, MintHill );
}
action Kaweah( Ridgetop, Lakota, Bethania ) {
   LaPlata( Ridgetop );
   Chualar( Lakota, Bethania, Azalia.Kiwalik, 511 );
}
table DeLancey {
   reads {
      RedElm.valid : exact;
      Tarlton.Cedar : ternary;
      Azalia.Kiwalik : ternary;
      Azalia.Flats : ternary;
      Kress[0].Myoma : ternary;
      Sutton.Blakeley : ternary;
      Azalia.Fragaria : ternary;
      Azalia.Darien : ternary;
      Azalia.Snyder : ternary;
      Azalia.Radcliffe : ternary;
      Azalia.Duchesne : ternary;
      Azalia.Neubert : ternary;
      Azalia.Washoe : ternary;
      DewyRose.Brookside : ternary;
      DewyRose.Portales : ternary;
      Azalia.Halbur : ternary;
   }
   actions {
      Naches;
      Eskridge;
      Hebbville;
      Ladelle;
      Felida;
      Kaweah;
   }
   default_action : Eskridge( 0 );
   size : 0;
}
@pragma use_container_valid Kress[1].valid Kress[1].Duelm
table Mendon {
   reads {
      Tarlton.Cedar : ternary;
      Kress[1].valid : ternary;
      Kress[1].Duelm : ternary;
      Azalia.Halbur : ternary;
   }
   actions {
      Naches;
      Selawik;
      GlenDean;
      Eskridge;
   }
   default_action : Eskridge( 0 );
   size : 0;
}
table Fairlea {
   reads {
      RedElm.valid : exact;
      Tarlton.Cedar : ternary;
      Azalia.Kiwalik : ternary;
      Dialville.Kinde : ternary;
      Azalia.Halbur : ternary;
   }
   actions {
      Hebbville;
      Ladelle;
      Naches;
      Cascade;
      Eskridge;
   }
   default_action : Eskridge( 0 );
   size : 0;
}
table Chewalla {
   actions {
      Absarokee;
   }
   default_action : Absarokee;
   size : 1;
}
table Harriet {
   reads {
      RedElm.valid : exact;
      Dialville.Kinde : ternary;
      Tarlton.Cedar : ternary;
      Azalia.Kiwalik : ternary;
      Azalia.Midville : ternary;
      Azalia.Duchesne : ternary;
      Azalia.Neubert : ternary;
      Azalia.Washoe : ternary;
      DewyRose.Brookside : ternary;
      DewyRose.Portales : ternary;
      Kress[0].valid : ternary;
      Azalia.Halbur : ternary;
   }
   actions {
      Hebbville;
      Ladelle;
      Jigger;
      Gladys;
      Kensett;
      Naches;
      Cascade;
      Eskridge;
   }
   default_action: Eskridge( 0 );
   size : 0;
}
counter Mullins {
   type : packets_and_bytes;
   direct : Lamine;
   min_width : 64;
}
table Lamine {
   reads {
      Dialville.BelAir mask 0 : exact;
   }
   actions {
      Northlake;
   }
   default_action : Northlake();
   size : 0;
}
control Horsehead {
}
counter Linville {
   type : packets_and_bytes;
   direct : Edwards;
   min_width : 64;
}
table Edwards {
   reads {
      Dialville.BelAir mask 0 : exact;
   }
   actions {
      Northlake;
   }
   default_action : Northlake();
   size : 0;
}
counter Etter {
   type : packets_and_bytes;
   direct : Grigston;
   min_width : 64;
}
table Grigston {
   reads {
      Dialville.BelAir mask 0 : exact;
   }
   actions {
      Northlake;
   }
   default_action : Northlake();
   size : 0;
}
counter Idylside {
   type : packets_and_bytes;
   direct : Elloree;
   min_width : 64;
}
table Elloree {
   reads {
      Dialville.BelAir mask 0 : exact;
   }
   actions {
      Northlake;
   }
   default_action : Northlake();
   size : 0;
}
action Anahola() {
   modify_field( Auburn.Compton, LeaHill.VanWert );
   modify_field( Auburn.Green, Lewiston.Toxey, 1);
}
action Cotuit() {
   modify_field( Auburn.Compton, Azalia.Duchesne );
   modify_field( Auburn.Green, Lewiston.Thistle, 1);
}
action Ahmeek() {
   modify_field( Azalia.Manteo, Lewiston.Thistle );
   modify_field( Azalia.Washoe, Lewiston.Prismatic );
   modify_field( Azalia.SanPablo, Lewiston.Osseo );
   modify_field( Azalia.Micro, Lewiston.Morrow, 0x7 );
}
action Somis() {
   Ahmeek();
   modify_field( Sisters.Louviers, 1 );
   modify_field( Azalia.Fragaria, Holliston.Troutman );
   modify_field( Azalia.Darien, Holliston.Bucktown );
   Cotuit();
}
action Hiwasse() {
   modify_field( Sisters.Louviers, 6 );
   modify_field( Azalia.Snyder, Sutton.Pembine );
   modify_field( Azalia.Radcliffe, Sutton.Yukon );
   modify_field( Azalia.Fragaria, Sutton.Troutman );
   modify_field( Azalia.Darien, Sutton.Bucktown );
   modify_field( Azalia.Micro, 0x0 );
}
action Morstein() {
   modify_field( Sisters.Louviers, 5 );
   modify_field( Azalia.Snyder, Sutton.Pembine );
   modify_field( Azalia.Radcliffe, Sutton.Yukon );
   modify_field( Azalia.Fragaria, Sutton.Troutman );
   modify_field( Azalia.Darien, Sutton.Bucktown );
   modify_field( Sutton.Blakeley, Azalia.Midville );
   Ahmeek();
   Cotuit();
}
action Ishpeming() {
   modify_field( Antlers.Pevely, Kress[0].Saltair );
   modify_field( Azalia.Flats, Kress[0].valid );
   modify_field( Azalia.Cairo, 0 );
   modify_field( Azalia.Snyder, Sutton.Pembine );
   modify_field( Azalia.Radcliffe, Sutton.Yukon );
   modify_field( Azalia.Fragaria, Sutton.Troutman );
   modify_field( Azalia.Darien, Sutton.Bucktown );
   modify_field( Azalia.Micro, Lewiston.Point, 0x7 );
   modify_field( Azalia.Midville, Sutton.Blakeley );
}
action Wamego() {
   modify_field( Azalia.Duchesne, LeaHill.VanWert );
   modify_field( Azalia.Neubert, LeaHill.Sespe );
   modify_field( Azalia.Hodges, Midas.Sultana );
   modify_field( Azalia.Manteo, Lewiston.Toxey );
   Anahola();
}
action Greendale() {
   Ishpeming();
   modify_field( Picayune.ElkNeck, Talkeetna.Veguita );
   modify_field( Picayune.LaHabra, Talkeetna.Braselton );
   modify_field( Picayune.Helton, Talkeetna.Roggen );
   modify_field( Azalia.Washoe, Talkeetna.Rollins );
   Wamego();
}
action Aplin() {
   Ishpeming();
   modify_field( DewyRose.Brookside, Arial.Osage );
   modify_field( DewyRose.Portales, Arial.Larchmont );
   modify_field( DewyRose.Darco, Arial.Ribera );
   modify_field( Azalia.Washoe, Arial.RioPecos );
   Wamego();
}
@pragma use_container_valid Talkeetna.valid Talkeetna.Braselton
@pragma action_default_only Aplin
table Kellner {
   reads {
      Sutton.Pembine : ternary;
      Sutton.Yukon : ternary;
      Arial.Larchmont : ternary;
      Talkeetna.Braselton : ternary;
      Azalia.Cairo : ternary;
      Talkeetna.valid : exact;
   }
   actions {
      Somis;
      Morstein;
      Hiwasse;
      Greendale;
   }
   default_action : Aplin();
   size : 512;
}
action Gretna(Moultrie) {
   modify_field( Azalia.Kiwalik, Tarlton.Illmo );
   modify_field( Azalia.Boise, Moultrie);
}
action Montezuma( Coverdale, Lushton ) {
   modify_field( Azalia.Kiwalik, Coverdale );
   modify_field( Azalia.Boise, Lushton);
   modify_field( Tarlton.Baudette, 1 );
}
action Covina(Darby) {
   modify_field( Azalia.Kiwalik, Kress[0].Duelm );
   modify_field( Azalia.Boise, Darby);
}
@pragma use_container_valid Kress[0].valid Kress[0].Duelm
table Jericho {
   reads {
      Tarlton.Baudette : exact;
      Tarlton.Cedar : exact;
      Kress[0] : valid;
      Kress[0].Duelm : ternary;
   }
   actions {
      Gretna;
      Montezuma;
      Covina;
   }
   size : 3072;
}
action Tusculum( VanHorn ) {
   modify_field( Azalia.Boise, VanHorn );
}
action Surrency() {
   modify_field( Union.DelRosa,
                 3 );
   modify_field( Azalia.Boise, 510 );
}
action Provo() {
   modify_field( Union.DelRosa,
                 1 );
   modify_field( Azalia.Boise, 510 );
}
action Wakita() {
   modify_field( Azalia.Minto, 1 );
}
@pragma immediate 0
table Ihlen {
   reads {
      Arial.Osage : exact;
   }
   actions {
      Tusculum;
      Wakita;
      Surrency;
      Provo;
   }
   default_action : Surrency;
   size : 4096;
}
@pragma immediate 0
table Minneota {
   reads {
      Talkeetna.Veguita : exact;
   }
   actions {
      Tusculum;
      Wakita;
      Surrency;
      Provo;
   }
   default_action : Surrency;
   size : 4096;
}
action Montello( Tunica, Vevay, Braxton, Grinnell ) {
   modify_field( Azalia.Kiwalik, Tunica );
   modify_field( Azalia.Biggers, Tunica );
   Zemple( Vevay, Braxton, Grinnell );
}
action Tilghman() {
   modify_field( Azalia.Minto, 1 );
}
@pragma immediate 0
table Westboro {
   reads {
      Azalia.Waupaca : exact;
      Azalia.Sequim : exact;
      Azalia.Cairo : exact;
      Exira.Saltdale : ternary;
   }
   actions {
      Montello;
      Tilghman;
   }
   size : 1024;
}
action Zemple(Latham, August, LunaPier) {
   modify_field( Leoma.Viroqua, August );
   modify_field( DewyRose.Hubbell, Latham );
   modify_field( Leoma.Alnwick, LunaPier );
}
action Easley( Upson ) {
}
action Wimberley(Chaska, Longville, Iraan, PineAire) {
   modify_field( Azalia.Biggers, Tarlton.Illmo );
   Easley( PineAire );
   Zemple( Chaska, Longville, Iraan );
}
action Kempton(Mayflower, Geistown, Melrose, Bixby, Hilger) {
   modify_field( Azalia.Biggers, Mayflower );
   Easley( Hilger );
   Zemple( Geistown, Melrose, Bixby );
}
action Derita(Neosho, Bayard, Sardinia, Trenary) {
   modify_field( Azalia.Biggers, Kress[0].Duelm );
   Easley( Trenary );
   Zemple( Neosho, Bayard, Sardinia );
}
table Tulip {
   reads {
      Tarlton.Illmo : exact;
   }
   actions {
      Wimberley;
   }
   size : 4096;
}
@pragma action_default_only Northlake
table WestGate {
   reads {
      Tarlton.Cedar : exact;
      Kress[0].Duelm : exact;
   }
   actions {
      Kempton;
      Northlake;
   }
   default_action : Northlake();
   size : 1024;
}
@pragma immediate 0
table Stovall {
   reads {
      Kress[0].Duelm : exact;
   }
   actions {
      Derita;
   }
   size : 4096;
}
control Floris {
   apply( Kellner ) {
      Somis {
         if( Arial.valid == 1 ) {
            apply( Ihlen ) {
               Wakita {
               }
               default {
                  apply( Westboro );
               }
            }
         } else {
            apply( Minneota ) {
               Wakita {
               }
               default {
                  apply( Westboro );
               }
            }
         }
      }
      default {
         apply( Jericho );
         if ( valid( Kress[0] ) and Kress[0].Duelm != 0 ) {
            apply( WestGate ) {
               Northlake {
                  apply( Stovall );
               }
            }
         } else {
            apply( Tulip );
         }
      }
   }
}
action Hopedale( Ossipee ) {
   modify_field( Azalia.Belpre, Ossipee, 0xffff );
}
action Clarion() {
}
@pragma ignore_table_dependency Chispa
table Murdock {
   reads {
      Leoma.Viroqua : ternary;
      Azalia.Biggers : ternary;
      DewyRose.Brookside : ternary;
   }
   actions {
      Clarion;
      Northlake;
   }
   default_action : Northlake();
   size : 1024;
}
action Burien( Addicks, Boyce, Lakehurst, Elcho ) {
   modify_field( Leoma.Viroqua, Addicks );
   modify_field( DewyRose.Hubbell, Elcho );
   modify_field( DewyRose.Portales, Boyce );
   Hopedale( Lakehurst );
   modify_field( Azalia.OldTown, 1 );
}
@pragma ways 2
table DuPont {
   reads {
      DewyRose.Portales : exact;
   }
   actions {
      Burien;
   }
   size : 8192;
}
control Laclede {
   if( Sisters.Louviers == 0 ) {
      apply( Murdock ) {
         Clarion {
            apply( DuPont );
         }
      }
   }
}
action Pardee() {
   bit_not( BigRiver.Mekoryuk, BigRiver.Mekoryuk );
}
action Rendon() {
   bit_not( BigRiver.Mekoryuk, BigRiver.Mekoryuk );
   modify_field( Azalia.Belpre, 0 );
}
action Lindy() {
   bit_not( BigRiver.Mekoryuk, 0 );
   modify_field( Azalia.Belpre, 0 );
}
action Neshoba() {
   modify_field( BigRiver.Mekoryuk, 0 );
   modify_field( Azalia.Belpre, 0 );
}
action Tolono() {
   modify_field( Arial.Osage, DewyRose.Brookside );
   modify_field( Arial.Larchmont, DewyRose.Portales );
}
action Kranzburg() {
   Pardee();
   Tolono();
}
action Slade() {
   Neshoba();
   Tolono();
}
action Kaanapali() {
   Tolono();
   Lindy();
}
table Onslow {
   reads {
      Sisters.Auberry : ternary;
      Azalia.OldTown : ternary;
      Azalia.Ranburne : ternary;
      Azalia.Belpre mask 0xFFFF : ternary;
      Arial.valid : ternary;
      BigRiver.valid : ternary;
      Patchogue.valid : ternary;
      BigRiver.Mekoryuk : ternary;
      Sisters.Louviers : ternary;
   }
   actions {
      Isabel;
      Tolono;
      Kranzburg;
      Kaanapali;
      Slade;
      Rendon;
   }
   size : 512;
}
control Boistfort {
   apply( Onslow );
}
meter Seagate {
   type: bytes;
   static : Spindale;
   instance_count : 512;
}
action Crannell(Anguilla) {
   execute_meter( Seagate, Anguilla, Azalia.Sieper );
}
table Spindale {
   reads {
      Leoma.Viroqua : exact;
   }
   actions {
       Crannell;
   }
   size : 512;
}
control Basco {
   if( Azalia.Ranburne == 1) {
      apply( Spindale );
   }
}
control Kniman {
}
control Igloo {
}
control Montour {
}
control Dalkeith {
}
@pragma idletime_precision 1
@pragma force_immediate 1
@pragma ways 4
table Devola {
   reads {
      Leoma.Viroqua : exact;
      DewyRose.Portales : exact;
   }
   actions {
      Wyanet;
      Powderly;
      Daniels;
      Telma;
      Northlake;
   }
   default_action : Northlake();
   size : 98304;
   support_timeout : true;
}
@pragma idletime_precision 1
@pragma force_immediate 1
@pragma ways 4
table Egypt {
   reads {
      Leoma.Viroqua : exact;
      Picayune.LaHabra : exact;
   }
   actions {
      Wyanet;
      Powderly;
      Daniels;
      Telma;
      Northlake;
   }
   default_action : Northlake();
   size : 16384;
   support_timeout : true;
}
action Amazonia( Runnemede, Louin ) {
   modify_field( Naylor.Newsoms, Runnemede );
   modify_field( Naylor.Fayette, Louin );
}
action PaloAlto( Bemis, DuBois ) {
   modify_field( DewyRose.Lovewell, Bemis );
   Amazonia( 0, 0 );
   Wyanet( DuBois );
}
action Waucousta( Patsville, Hoven ) {
   modify_field( DewyRose.Lovewell, Patsville );
   Amazonia( 0, 0 );
   Powderly( Hoven );
}
action Helen( Guaynabo, Scranton ) {
   modify_field( DewyRose.Lovewell, Guaynabo );
   Amazonia( 0, 0 );
   Daniels( Scranton );
}
action Moorewood( Wymore, Plandome ) {
   modify_field( DewyRose.Lovewell, Wymore );
   Amazonia( 0, 0 );
   Telma( Plandome );
}
action Lincroft( Wanilla ) {
   modify_field( DewyRose.Lovewell, Wanilla );
}
@pragma idletime_precision 1
@pragma force_immediate 1
table Woodfords {
   reads {
      Leoma.Viroqua mask 0xFF : exact;
      DewyRose.Hubbell: lpm;
   }
   actions {
      PaloAlto;
      Waucousta;
      Helen;
      Moorewood;
      Lincroft;
      Northlake;
   }
   size : 10240;
   support_timeout : true;
}
action Panola( Joyce, Crestone ) {
   modify_field( Picayune.Rocky, Joyce );
   Wyanet( Crestone );
}
action Ladner( Ingleside, Rodeo ) {
   modify_field( Picayune.Rocky, Ingleside );
   Powderly( Rodeo );
}
action Harpster( Bluewater, Westbrook ) {
   modify_field( Picayune.Rocky, Bluewater );
   Daniels( Westbrook );
}
action Hilgard( Brashear, Shoreview ) {
   modify_field( Picayune.Rocky, Brashear );
   Telma( Shoreview );
}
@pragma idletime_precision 1
@pragma force_immediate 1
table Norfork {
   reads {
      Leoma.Viroqua : exact;
      Picayune.LaHabra mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Panola;
      Ladner;
      Harpster;
      Hilgard;
      Northlake;
   }
   default_action : Northlake();
   size : 2048;
   support_timeout : true;
}
action Malaga( Toccopola, Estrella ) {
   modify_field( Picayune.Rocky, Toccopola );
   Wyanet( Estrella );
}
action Pound( Bennet, Ebenezer ) {
   modify_field( Picayune.Rocky, Bennet );
   Powderly( Ebenezer );
}
action Artas( Riverwood, Lowden ) {
   modify_field( Picayune.Rocky, Riverwood );
   Daniels( Lowden );
}
action Miller( Reidville, Tivoli ) {
   modify_field( Picayune.Rocky, Reidville );
   Telma( Tivoli );
}
@pragma idletime_precision 1
@pragma action_default_only Northlake
@pragma force_immediate 1
table Bovina {
   reads {
      Leoma.Viroqua : exact;
      Picayune.LaHabra : lpm;
   }
   actions {
      Malaga;
      Pound;
      Artas;
      Miller;
      Northlake;
   }
   size : 1024;
   support_timeout : true;
}
@pragma ways 2
@pragma atcam_partition_index DewyRose.Lovewell
@pragma atcam_number_partitions 10240
@pragma idletime_precision 1
@pragma force_immediate 1
@pragma action_default_only Salamonia
table AquaPark {
   reads {
      DewyRose.Lovewell mask 0x7fff: exact;
      DewyRose.Portales mask 0x000fffff : lpm;
   }
   actions {
      Wyanet;
      Powderly;
      Daniels;
      Telma;
      Salamonia;
   }
   default_action : Salamonia();
   size : 163840;
   support_timeout : true;
}
@pragma idletime_precision 1
@pragma atcam_partition_index Picayune.Rocky
@pragma atcam_number_partitions 1024
@pragma force_immediate 1
table Mulliken {
   reads {
      Picayune.Rocky mask 0x7FF : exact;
      Picayune.LaHabra mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Wyanet;
      Powderly;
      Daniels;
      Telma;
      Northlake;
   }
   default_action : Northlake();
   size : 8192;
   support_timeout : true;
}
@pragma idletime_precision 1
@pragma atcam_partition_index Picayune.Rocky
@pragma atcam_number_partitions 2048
@pragma force_immediate 1
table Salamatof {
   reads {
      Picayune.Rocky mask 0x1fff: exact;
      Picayune.LaHabra mask 0x000003FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Telma;
      Wyanet;
      Powderly;
      Daniels;
      Northlake;
   }
   default_action : Northlake();
   size : 16384;
   support_timeout : true;
}
@pragma idletime_precision 1
@pragma ignore_table_dependency DuPont
table Hobson {
   reads {
      DewyRose.Portales : lpm;
   }
   actions {
      Amazonia;
   }
   size : 1024;
   support_timeout : true;
}
action Charm( Readsboro, Arkoe ) {
   modify_field( DewyRose.Brookside, Readsboro );
   Hopedale( Arkoe );
   modify_field( Azalia.Berlin, 1 );
}
@pragma ignore_table_dependency Murdock
table Chispa {
   reads {
      DewyRose.Brookside : exact;
      Leoma.Viroqua : exact;
   }
   actions {
      Charm;
   }
   default_action : Northlake();
   size : 8192;
}
control Guadalupe {
   if( Leoma.Viroqua == 0 ) {
      Laclede();
      apply( Hobson );
   } else if( Sisters.Louviers == 0 ) {
      apply( Chispa ) {
         Charm {
            apply( Hobson );
         }
      }
   }
}
control Emerado {
   apply( Devola ) {
      Northlake {
         apply( Woodfords );
      }
   }
}
control Haworth {
   apply( Egypt ) {
      Northlake {
         apply( Bovina );
      }
   }
}
action Wyanet( Orrstown ) {
   modify_field( Naylor.Wabuska, 0 );
   modify_field( Naylor.Sandoval, Orrstown );
}
action Powderly( Humeston ) {
   modify_field( Naylor.Wabuska, 2 );
   modify_field( Naylor.Sandoval, Humeston );
}
action Daniels( Mikkalo ) {
   modify_field( Naylor.Wabuska, 3 );
   modify_field( Naylor.Sandoval, Mikkalo );
}
action Sanborn( Salineno, Mankato ) {
   modify_field( Naylor.Wabuska, Salineno );
   modify_field( Naylor.Sandoval, Mankato );
}
action Telma( Fentress ) {
   modify_field( Naylor.Wallace, Fentress );
   modify_field( Naylor.Wabuska, 1 );
}
action Salamonia() {
   modify_field( Azalia.Ranburne, Azalia.Berlin );
   modify_field( Azalia.OldTown, 0 );
   bit_or( Naylor.Wabuska, Naylor.Wabuska, Naylor.Newsoms );
   bit_or( Naylor.Sandoval, Naylor.Sandoval, Naylor.Fayette );
}
action Olathe() {
   Salamonia();
}
@pragma idletime_precision 1
@pragma force_immediate 1
@pragma action_default_only Olathe
table Reynolds {
   reads {
      Leoma.Viroqua : exact;
      DewyRose.Portales mask 0xFFF00000 : lpm;
   }
   actions {
      Wyanet;
      Powderly;
      Daniels;
      Telma;
   }
   default_action : Olathe();
   size : 8192;
   support_timeout : true;
}
action Trimble() {
   Wyanet( 1 );
}
@pragma action_default_only Trimble
@pragma idletime_precision 1
@pragma force_immediate 1
table Yerington {
   reads {
      Leoma.Viroqua : exact;
      Picayune.LaHabra mask 0xFFFFFC00000000000000000000000000: lpm;
   }
   actions {
      Wyanet;
      Powderly;
      Daniels;
      Telma;
      Trimble;
   }
   size : 1024;
   support_timeout : true;
}
action Neches(LaJara) {
   Wyanet( LaJara );
}
table DuQuoin {
   reads {
      Leoma.Alnwick mask 0x1 : exact;
      Azalia.Micro : exact;
   }
   actions {
      Neches;
   }
   default_action: Neches;
   size : 2;
}
control Onset {
   if ( Azalia.Sontag == 0 and Leoma.Donna == 1 and
        Pikeville.Wyncote == 0 and Pikeville.Joshua == 0 ) {
      if ( ( ( Leoma.Alnwick & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Azalia.Micro == 0x1 ) ) {
         if ( DewyRose.Lovewell != 0 ) {
            apply( AquaPark );
         } else if ( Naylor.Sandoval == 0 ) {
            apply( Reynolds );
         }
      } else if ( ( ( Leoma.Alnwick & ( 0x2 ) ) == ( ( 0x2 ) ) ) and Azalia.Micro == 0x2 ) {
         if ( Picayune.Rocky != 0 ) {
            apply( Mulliken );
         } else if ( Naylor.Sandoval == 0 ) {
            apply( Norfork );
            if ( Picayune.Rocky != 0 ) {
               apply( Salamatof );
            } else if ( Naylor.Sandoval == 0 ) {
               apply( Yerington );
            }
         }
      } else if ( ( Sisters.Finney == 0 ) and ( ( Azalia.Whitewood == 1 ) or
            ( ( ( Leoma.Alnwick & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Azalia.Micro == 0x3 ) ) ) ) {
         apply( DuQuoin );
      }
   }
}
field_list Broussard {
   Riner.Dillsboro;
   ig_intr_md.ingress_port;
}
field_list_calculation Litroe {
   input {
      Broussard;
   }
   algorithm : crc16_extend;
   output_width : 66;
}
action_selector SandLake {
   selection_key : Litroe;
   selection_mode : resilient;
}
action_profile Arroyo {
   actions {
      Sanborn;
   }
   size : 65536;
   dynamic_action_selection : SandLake;
}
@pragma selector_max_group_size 256
table Grisdale {
   reads {
      Naylor.Wallace mask 0x3ff: exact;
   }
   action_profile : Arroyo;
   size : 1024;
}
action Congress() {
   modify_field( Azalia.Charlotte, Azalia.Surrey );
}
table Arvana {
   actions {
      Congress;
   }
   default_action : Congress();
   size : 1;
}
action Astor(Elkton) {
   modify_field(Sisters.Finney, 1);
   modify_field(Sisters.Auberry, Elkton);
}
table Haugan {
   reads {
      Naylor.Sandoval mask 0xF: exact;
   }
   actions {
      Astor;
   }
   size : 16;
}
action Klukwan(Verndale, Idabel, Nuevo) {
   modify_field(Sisters.Whitakers, Verndale);
   modify_field(Sisters.PawCreek, Idabel);
   modify_field(Sisters.Salome, Nuevo);
}
@pragma use_hash_action 1
table Shuqualak {
   reads {
      Naylor.Sandoval mask 0xFFFF : exact;
   }
   actions {
      Klukwan;
   }
   default_action : Klukwan(0,0,0);
   size : 65536;
}
@pragma use_hash_action 1
table Calabash {
   reads {
      Naylor.Wabuska mask 0x1 : exact;
      Naylor.Sandoval mask 0xFFFF : exact;
   }
   actions {
      Klukwan;
   }
   default_action : Klukwan(0, 0, 0);
   size : 131072;
}
action Ripley(Ingraham, Manville, Jackpot) {
   modify_field(Sisters.Earlimart, 1);
   modify_field(Sisters.Benitez, Ingraham);
   modify_field(Sisters.Bacton, Manville);
   modify_field(Azalia.Empire, Jackpot);
}
@pragma use_hash_action 1
table Drifton {
   reads {
      Naylor.Sandoval mask 0xFFFF : exact;
   }
   actions {
      Ripley;
   }
   default_action : Ripley(511,0,0);
   size : 65536;
}
@pragma use_hash_action 1
table Williams {
   reads {
      Naylor.Wabuska mask 0x1 : exact;
      Naylor.Sandoval mask 0xFFFF : exact;
   }
   actions {
      Ripley;
   }
   default_action : Ripley(511,0,0);
   size : 131072;
}
control Keyes {
   if ( Naylor.Wabuska == 1 ) {
      apply( Grisdale );
   }
}
control Tamora {
   if( Naylor.Sandoval != 0 ) {
      apply( Arvana );
      if( ( ( Naylor.Sandoval & ( 0xFFF0 & 0xFFFF ) ) == 0 ) ) {
         apply( Haugan );
      } else {
         if( Naylor.Wabuska == 0 ) {
            apply( Drifton );
         } else {
            apply( Williams );
         }
      }
   }
}
control Paisano {
   if( Naylor.Sandoval != 0 and Naylor.Wabuska == 0 ) {
      apply( Shuqualak );
   }
}
control Kisatchie {
   if( ( Naylor.Sandoval != 0 ) and ( ( Naylor.Wabuska & 2 ) == 2 ) ) {
      apply( Calabash );
   }
}
action Hisle( Waseca ) {
   modify_field( Azalia.Absecon, Waseca );
}
action National() {
   modify_field( Azalia.LaUnion, 1 );
}
table Shine {
   reads {
      Azalia.Micro : exact;
      Azalia.Cairo : exact;
      Arial.valid : exact;
      Arial.Fonda mask 0x3FFF: ternary;
      Talkeetna.Mellott mask 0x3FFF: ternary;
   }
   actions {
      Hisle;
      National;
   }
   default_action : National();
   size : 1024;
}
control KingCity {
   apply( Shine );
}
action Belcourt( Cozad ) {
   modify_field( Sisters.Finney, 1 );
   modify_field( Sisters.Auberry, Cozad );
}
action PineLawn() {
}
table Kountze {
   reads {
      Azalia.LaUnion : ternary;
      Azalia.Absecon : ternary;
      Azalia.Empire : ternary;
      Sisters.Earlimart : exact;
      Sisters.Benitez mask 0x80000 : ternary;
   }
   actions {
      Belcourt;
      PineLawn;
   }
   default_action : PineLawn;
   size : 512;
}
control Gully {
   apply( Kountze );
}
control Shauck {
   apply( Kountze );
}
action Muenster() {
   modify_field(Sisters.Louviers, 0);
   modify_field(Sisters.Finney, 1);
   modify_field(Sisters.Auberry, 16);
}
table PineLake {
   actions {
      Muenster;
   }
   default_action : Muenster();
   size : 1;
}
action Pickering() {
   modify_field(Azalia.Terrell, 1);
}
@pragma ways 1
table Amber {
   reads {
      Holliston.Pembine : ternary;
      Holliston.Yukon : ternary;
      Arial.Larchmont : exact;
   }
   actions {
      Pickering;
      Isabel;
   }
   default_action : Pickering();
   size : 512;
}
control Lublin {
   if( RedElm.valid == 0 and Sisters.Louviers == 1 and Leoma.Donna == 1 ) {
      apply(Amber);
   }
}
control TiePlant {
   if( RedElm.valid == 0 and Sisters.Louviers == 1 and ( ( Leoma.Alnwick & ( 0x1 ) ) == ( ( 0x1 ) ) ) and Holliston.Blakeley == 0x0806 ) {
      apply(PineLake);
   }
}
register Dunbar {
   width : 1;
   static : Hawley;
   instance_count : 294912;
}
register Coulee {
   width : 1;
   static : Biddle;
   instance_count : 294912;
}
blackbox stateful_alu Kenbridge {
   reg : Dunbar;
   update_lo_1_value: read_bitc;
   output_value : alu_lo;
   output_dst : Pikeville.Wyncote;
}
blackbox stateful_alu RedLake {
   reg : Coulee;
   update_lo_1_value: read_bit;
   output_value : alu_lo;
   output_dst : Pikeville.Joshua;
}
field_list Joiner {
   ig_intr_md.ingress_port;
   Kress[0].Duelm;
}
field_list_calculation Alvwood {
   input { Joiner; }
   algorithm: identity;
   output_width: 19;
}
action NewAlbin() {
   Kenbridge.execute_stateful_alu_from_hash(Alvwood);
}
action Macopin() {
   RedLake.execute_stateful_alu_from_hash(Alvwood);
}
table Hawley {
   actions {
      NewAlbin;
   }
   default_action : NewAlbin;
   size : 1;
}
table Biddle {
   actions {
      Macopin;
   }
   default_action : Macopin;
   size : 1;
}
control Ghent {
   apply( Hawley );
   apply( Biddle );
}
register Yorklyn {
   width : 1;
   static : Niota;
   instance_count : 294912;
}
register TenSleep {
   width : 1;
   static : Reydon;
   instance_count : 294912;
}
blackbox stateful_alu Wingate {
   reg : Yorklyn;
   update_lo_1_value: read_bitc;
   output_value : alu_lo;
   output_dst : Stone.Uncertain;
}
blackbox stateful_alu Handley {
   reg : TenSleep;
   update_lo_1_value: read_bit;
   output_value : alu_lo;
   output_dst : Stone.Bladen;
}
field_list Minoa {
   eg_intr_md.egress_port;
   Sisters.Hartford;
}
field_list_calculation Newcomb {
   input { Minoa; }
   algorithm: identity;
   output_width: 19;
}
action Elmore() {
   Wingate.execute_stateful_alu_from_hash(Newcomb);
}
table Niota {
   actions {
      Elmore;
   }
   default_action : Elmore;
   size : 1;
}
action Arpin() {
   Handley.execute_stateful_alu_from_hash(Newcomb);
}
table Reydon {
   actions {
      Arpin;
   }
   default_action : Arpin;
   size : 1;
}
control Bendavis {
   apply( Niota );
   apply( Reydon );
}
@pragma all_fields_optional
field_list Albany {
   Holliston.Pembine;
   Holliston.Yukon;
   Holliston.Troutman;
   Holliston.Bucktown;
   Holliston.Blakeley;
}
@pragma all_fields_optional
field_list Caroleen {
   Arial.RioPecos;
   Arial.Osage;
   Arial.Larchmont;
}
@pragma all_fields_optional
field_list Richlawn {
   Talkeetna.Veguita;
   Talkeetna.Braselton;
   Talkeetna.Brentford;
   Talkeetna.Rollins;
}
@pragma all_fields_optional
field_list Dante {
   McDermott.Brewerton;
   LeaHill.VanWert;
   LeaHill.Sespe;
}
@pragma all_fields_optional
field_list Anoka {
   McDermott.McFaddin;
   Millsboro.VanWert;
   Millsboro.Sespe;
}
field_list_calculation LaMoille {
   input {
      Albany;
   }
   algorithm : crc16;
   output_width : 16;
}
field_list_calculation Eolia {
   input {
      Caroleen;
   }
   algorithm : crc16;
   output_width : 16;
}
field_list_calculation Wabasha {
   input {
      Richlawn;
   }
   algorithm : crc16;
   output_width : 16;
}
field_list_calculation Lumpkin {
   input {
      Dante;
   }
   algorithm : crc16;
   output_width : 16;
}
field_list_calculation LewisRun {
   input {
      Anoka;
   }
   algorithm : crc16;
   output_width : 16;
}
action Portville() {
   modify_field_with_hash_based_offset( McDermott.Coolin, 0,
                                        LaMoille, 65536 );
}
action Sylva() {
   modify_field_with_hash_based_offset( McDermott.Brewerton, 0,
                                        Eolia, 65536 );
}
action Hanamaulu() {
   modify_field_with_hash_based_offset( McDermott.Brewerton, 0,
                                        Wabasha, 65536 );
}
action Kathleen() {
   modify_field_with_hash_based_offset( McDermott.Grasston, 0,
                                        Lumpkin, 65536 );
}
@pragma all_fields_optional
field_list Crary {
   DewyRose.Brookside;
   DewyRose.Portales;
   Lewiston.Prismatic;
}
field_list_calculation Toklat {
   input {
      Crary;
   }
   algorithm : crc16;
   output_width : 16;
}
action Blanding() {
   modify_field_with_hash_based_offset( McDermott.McFaddin, 0,
                                        Toklat, 65536 );
}
@pragma all_fields_optional
field_list Monrovia {
   Picayune.ElkNeck;
   Picayune.LaHabra;
   Captiva.Brentford;
   Lewiston.Prismatic;
}
field_list_calculation Cassadaga {
   input {
      Monrovia;
   }
   algorithm : crc16;
   output_width : 16;
}
action Ronda() {
   modify_field_with_hash_based_offset( McDermott.McFaddin, 0,
                                        Cassadaga, 65536 );
}
@pragma ternary 1
@pragma stage 0
table Markesan {
   reads {
      Parnell.valid : exact;
      Captiva.valid : exact;
   }
   actions {
      Blanding;
      Ronda;
   }
   size : 2;
}
table Bronaugh {
   actions {
      Portville;
   }
   default_action : Portville();
   size: 1;
}
control RedLevel {
   apply( Bronaugh );
}
table Pierson {
   actions {
      Sylva;
   }
   default_action : Sylva();
   size: 1;
}
table Rehobeth {
   actions {
      Hanamaulu;
   }
   default_action : Hanamaulu();
   size: 1;
}
control Telephone {
   if ( valid( Arial ) ) {
      apply(Pierson);
   } else {
      apply( Rehobeth );
   }
}
action Kearns() {
   modify_field_with_hash_based_offset( McDermott.OakCity, 0,
                                        LewisRun, 65536 );
}
action Purley() {
   Kathleen();
   Kearns();
}
table Welcome {
   actions {
      Purley;
   }
   default_action : Purley();
   size: 1;
}
control Lisman {
   apply( Welcome );
}
@pragma all_fields_optional
field_list Kendrick {
   Sutton.Pembine;
   Sutton.Yukon;
   Sutton.Troutman;
   Sutton.Bucktown;
   Azalia.Midville;
}
field_list_calculation Malabar {
   input {
       Kendrick;
   }
   algorithm : crc16;
   output_width : 16;
}
action Theba() {
   modify_field_with_hash_based_offset( Riner.Pettigrew, 0,
                                        Malabar, 65536 );
}
action ElMango() {
   modify_field(Riner.Pettigrew, McDermott.Brewerton);
}
action Collis() {
   modify_field(Riner.Pettigrew, McDermott.Grasston);
}
action Golden() {
   modify_field( Riner.Pettigrew, McDermott.Coolin );
}
action Southdown() {
   modify_field( Riner.Pettigrew, McDermott.McFaddin );
}
action Newport() {
   modify_field( Riner.Pettigrew, McDermott.OakCity );
}
@pragma action_default_only Northlake
table Lynndyl {
   reads {
      Millsboro.valid : ternary;
      Parnell.valid : ternary;
      Captiva.valid : ternary;
      Holliston.valid : ternary;
      LeaHill.valid : ternary;
      Arial.valid : ternary;
      Talkeetna.valid : ternary;
      Sutton.valid : ternary;
   }
   actions {
      Theba;
      ElMango;
      Collis;
      Golden;
      Southdown;
      Newport;
      Northlake;
   }
   size: 256;
}
action Vesuvius() {
   modify_field(Riner.Dillsboro, McDermott.Brewerton);
}
action Bairoil() {
   modify_field( Riner.Dillsboro, McDermott.McFaddin );
}
action BigBow() {
   modify_field(Riner.Dillsboro, McDermott.Grasston);
}
action CedarKey() {
   modify_field( Riner.Dillsboro, McDermott.OakCity );
}
action Power() {
   modify_field( Riner.Dillsboro, McDermott.Coolin );
}
table Seabrook {
   reads {
      Millsboro.valid : ternary;
      Parnell.valid : ternary;
      Captiva.valid : ternary;
      Holliston.valid : ternary;
      LeaHill.valid : ternary;
      Talkeetna.valid : ternary;
      Arial.valid : ternary;
   }
   actions {
      Vesuvius;
      BigBow;
      Bairoil;
      CedarKey;
      Power;
      Northlake;
   }
   size: 512;
}
counter Rockdale {
   type : packets;
   direct : ElLago;
   min_width: 64;
}
action Ponder() {
   modify_field( Azalia.Sontag, 1 );
}
table ElLago {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Azalia.Minto : ternary;
      Azalia.Bellvue : ternary;
      Azalia.Waterford : ternary;
      Lewiston.Point mask 0x8 : ternary;
      ig_intr_md_from_parser_aux.ingress_parser_err mask 0x1000 : ternary;
   }
   actions {
      Ponder;
      Northlake;
   }
   default_action : Northlake();
   size : 512;
}
action Iselin() {
   modify_field( Azalia.Maryhill, 1 );
}
table Glynn {
   reads {
      Azalia.Fragaria : exact;
      Azalia.Darien : exact;
      Azalia.Kiwalik : exact;
   }
   actions {
      Iselin;
      Northlake;
   }
   default_action : Northlake();
   size : 4096;
}
action Buckeye() {
   modify_field(Union.DelRosa,
                2);
}
table Stowe {
   reads {
      Azalia.Fragaria : exact;
      Azalia.Darien : exact;
      Azalia.Kiwalik : exact;
      Azalia.Boise : exact;
   }
   actions {
      Isabel;
      Buckeye;
   }
   default_action : Buckeye();
   size : 16384;
   support_timeout : true;
}
action Calumet( Between, MillCity, Marquette ) {
   modify_field( Azalia.Donnelly, Between );
   modify_field( Azalia.Whitewood, MillCity );
   modify_field( Azalia.Tyrone, Marquette );
}
@pragma use_hash_action 1
table Reedsport {
   reads {
      Azalia.Kiwalik mask 0xfff : exact;
   }
   actions {
      Calumet;
   }
   default_action : Calumet( 0, 0, 0 );
   size : 4096;
}
action LaPuente() {
   modify_field_with_shift( DewyRose.Hubbell, DewyRose.Portales, 2, 0x3FFFFFFF );
}
action Corona() {
   modify_field( Leoma.Donna, 0 );
}
action Lefors() {
   modify_field( Leoma.Donna, 1 );
   LaPuente();
   Amazonia( 0, 1 );
}
table Poipu {
   reads {
      Azalia.Biggers : exact;
      Azalia.Snyder : exact;
      Azalia.Radcliffe : exact;
   }
   actions {
      Lefors;
   }
   size: 2048;
}
table Filer {
   reads {
      Azalia.Biggers : ternary;
      Azalia.Snyder : ternary;
      Azalia.Radcliffe : ternary;
      Azalia.Micro : ternary;
      Tarlton.Kenova : ternary;
   }
   actions {
      Corona;
      Lefors;
   }
   default_action : Northlake();
   size: 512;
}
control Machens {
   if( RedElm.valid == 0 ) {
      apply( ElLago ) {
         Northlake {
            apply( Glynn ) {
               Northlake {
                  if (Union.DelRosa == 0 and
                      Azalia.Kiwalik != 0 and
                      (Sisters.Louviers == 1 or
                       Tarlton.Baudette == 1) and
                      Azalia.Bellvue == 0 and
                      Azalia.Waterford == 0) {
                     apply( Stowe );
                  }
                  apply(Filer) {
                     Northlake {
                        apply(Poipu);
                     }
                  }
               }
            }
         }
      }
   }
   else if( RedElm.Saugatuck == 1 ) {
      apply(Filer) {
         Northlake {
            apply(Poipu);
         }
      }
   }
}
control Rockleigh {
   apply( Reedsport );
}
field_list Wolsey {
   Azalia.Fragaria;
   Azalia.Darien;
   Azalia.Kiwalik;
   Azalia.Boise;
}
action Theta() {
}
action Berwyn() {
   generate_digest(0, Wolsey);
   Theta();
}
field_list Basic {
   Azalia.Kiwalik;
   Holliston.Troutman;
   Holliston.Bucktown;
   Arial.Osage;
   Talkeetna.Veguita;
   Sutton.Blakeley;
   Azalia.Sequim;
   Azalia.Waupaca;
   Exira.Saltdale;
}
action Colburn() {
   generate_digest(0, Basic);
   Theta();
}
action Poulsbo() {
   modify_field( Azalia.Challis, 1 );
   Theta();
}
action Millikin() {
   modify_field( Sisters.Finney, 1 );
   modify_field( Sisters.Auberry, 22 );
   Theta();
   modify_field( Pikeville.Joshua, 0 );
   modify_field( Pikeville.Wyncote, 0 );
}
table Gilliam {
   reads {
      Union.DelRosa : exact;
      Azalia.Minto : ternary;
      ig_intr_md.ingress_port : ternary;
      Azalia.Boise mask 0x80000 : ternary;
      Pikeville.Joshua : ternary;
      Pikeville.Wyncote : ternary;
      Azalia.Halbur : ternary;
   }
   actions {
      Berwyn;
      Colburn;
      Millikin;
      Poulsbo;
   }
   default_action : Theta();
   size : 512;
}
control Bains {
   if (Union.DelRosa != 0) {
      apply( Gilliam );
   }
}
field_list Hooker {
   ig_intr_md.ingress_port;
   Riner.Pettigrew;
}
field_list_calculation Grovetown {
   input {
      Hooker;
   }
   algorithm : crc16_extend;
   output_width : 51;
}
action_selector LaVale {
   selection_key : Grovetown;
   selection_mode : resilient;
}
action Aldan() {
   bit_or( Sisters.Vestaburg, Sisters.Vestaburg, Sisters.Florahome );
}
action Revere(Cabot) {
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Cabot );
   Aldan();
}
action DeSmet() {
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Sisters.Benitez, 0x001FF );
   Aldan();
}
action SanSimon() {
   bit_not( ig_intr_md_for_tm.ucast_egress_port, 0 );
}
action Goulds() {
   Aldan();
   SanSimon();
}
action Anita() {
}
action_profile Noyes {
   actions {
      Revere;
      DeSmet;
      Goulds;
      SanSimon;
      Anita;
   }
   size : 32768;
   dynamic_action_selection : LaVale;
}
table Goessel {
   reads {
      Sisters.Benitez : ternary;
   }
   action_profile: Noyes;
   default_action: Goulds();
   size : 512;
}
control Grainola {
   apply(Goessel);
}
@pragma pa_no_init ingress Sisters.Benitez
@pragma pa_no_init ingress Sisters.Bacton
@pragma pa_overlay_stage_separation ingress ig_intr_md_for_tm.ucast_egress_port 1
action Garwood( Weleetka ) {
   Chualar( Azalia.Snyder, Azalia.Radcliffe, Azalia.Kiwalik, Weleetka );
}
action Chualar( Ellinger, Ackerly, DeRidder, Bangor ) {
   modify_field(Sisters.Purves, Tarlton.Kenova );
   modify_field(Sisters.Whitakers, Ellinger);
   modify_field(Sisters.PawCreek, Ackerly );
   modify_field(Sisters.Salome, DeRidder );
   modify_field(Sisters.Benitez, Bangor );
   modify_field(Sisters.Bacton, 0);
   bit_or( Azalia.Surrey, Azalia.Surrey, Azalia.Purdon );
   modify_field( ig_intr_md_for_tm.mcast_grp_a, 0 );
}
@pragma use_hash_action 1
table Yakutat {
   reads {
      Sutton.valid : exact;
   }
   actions {
      Garwood;
   }
   default_action : Garwood(511);
   size : 2;
}
control Folcroft {
   apply( Yakutat );
}
meter Dixfield {
   type : bytes;
   direct : Maryville;
   result : Azalia.Bluford;
}
action Nicodemus() {
   modify_field( Sisters.Clintwood, Azalia.Tyrone );
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Azalia.Whitewood);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Sisters.Salome);
}
action Rapids() {
   add(ig_intr_md_for_tm.mcast_grp_a, Sisters.Salome, 4096);
   modify_field( Azalia.Nipton, 1 );
   modify_field( Sisters.Clintwood, Azalia.Tyrone );
}
action Ferrum() {
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Sisters.Salome);
   modify_field( Sisters.Clintwood, Azalia.Tyrone );
}
table Maryville {
   reads {
      ig_intr_md.ingress_port mask 0x7f : ternary;
      Sisters.Whitakers : ternary;
      Sisters.PawCreek : ternary;
   }
   actions {
      Nicodemus;
      Rapids;
      Ferrum;
   }
   size : 512;
}
action McCartys(Joice) {
   modify_field(Sisters.Benitez, Joice);
}
action Brainard(VanZandt, Struthers) {
   modify_field(Sisters.Bacton, Struthers);
   McCartys(VanZandt);
   modify_field(Sisters.Cecilton, 5);
}
action Tenino(Oketo) {
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Oketo);
}
action Rushmore() {
   modify_field( Azalia.Hendley, 1 );
}
table OakLevel {
   reads {
      Sisters.Whitakers : exact;
      Sisters.PawCreek : exact;
      Sisters.Salome : exact;
   }
   actions {
      McCartys;
      Tenino;
      Brainard;
      Rushmore;
      Northlake;
   }
   default_action : Northlake();
   size : 16384;
}
control Tulsa {
   apply(OakLevel) {
      Northlake {
         apply(Maryville);
      }
   }
}
field_list Secaucus {
   Riner.Pettigrew;
}
field_list_calculation Peoria {
   input {
      Secaucus;
   }
   algorithm : crc16_extend;
   output_width : 51;
}
action Honobia( Oskawalik, Anniston ) {
   modify_field( Sisters.Vestaburg, Sisters.Benitez );
   modify_field( Sisters.Florahome, Anniston );
   modify_field( Sisters.Benitez, Oskawalik );
   modify_field( ig_intr_md_for_tm.disable_ucast_cutthru, 1 );
}
action McCloud( Waialee, EastLake ) {
   Honobia( Waialee, EastLake );
   modify_field( Sisters.Cecilton, 5 );
}
action_selector Roseau {
   selection_key : Peoria;
   selection_mode : resilient;
}
action_profile Montbrook {
   actions {
      McCloud;
   }
   size : 2048;
   dynamic_action_selection : Roseau;
}
@pragma ways 2
table Tamaqua {
   reads {
      Sisters.Bacton : exact;
   }
   action_profile : Montbrook;
   size : 512;
}
action Acree() {
   modify_field( Azalia.Beaverton, 1 );
}
table LasVegas {
   actions {
      Acree;
   }
   default_action : Acree;
   size : 1;
}
action Canton() {
   modify_field( Azalia.Lutsen, 1 );
}
@pragma ways 1
table Sturgeon {
   reads {
      Sisters.Benitez mask 0x007FF : exact;
   }
   actions {
      Isabel;
      Canton;
   }
   default_action : Isabel;
   size : 512;
}
control Calvary {
   if ((Sisters.Finney == 0) and (Azalia.Sontag == 0) and (Sisters.Earlimart==0) and (Azalia.Nipton==0)
       and (Azalia.Aberfoil==0) and (Pikeville.Wyncote == 0) and (Pikeville.Joshua == 0)) {
      if (((Azalia.Boise == Sisters.Benitez) or ((Sisters.Louviers == 1) and (Sisters.Cecilton == 5))) ) {
         apply(LasVegas);
      } else if (Tarlton.Kenova==2 and
                 ((Sisters.Benitez & 0xFF800) ==
                   0x03800)) {
         apply(Sturgeon);
      }
   }
}
action Advance( Adamstown ) {
   modify_field( Sisters.Hartford, Adamstown );
}
action Seaforth( Sherrill ) {
   modify_field( Sisters.Hartford, Sherrill );
   modify_field( Sisters.Casco, 1 );
}
action RoseTree() {
   modify_field( Sisters.Hartford, Sisters.Salome );
}
table Uhland {
   reads {
      eg_intr_md.egress_port mask 0x7f : exact;
      Sisters.Salome : exact;
   }
   actions {
      Advance;
      Seaforth;
      RoseTree;
   }
   default_action : RoseTree;
   size : 4096;
}
control Valdosta {
   apply( Uhland );
}
action Danbury( Holladay, McBrides, Alabaster ) {
   modify_field( Sisters.Mabel, Holladay );
   add_to_field( eg_intr_md.pkt_length, McBrides );
   bit_and( Riner.Pettigrew, Riner.Pettigrew, Alabaster );
}
action Lilbert( Ledger, Nicolaus, Waxhaw, Sharon ) {
   modify_field( Sisters.Winnebago, Ledger );
   Danbury( Nicolaus, Waxhaw, Sharon );
}
action FlatLick( Garretson, Belfalls, Algonquin, Moorpark ) {
   modify_field( Sisters.Wauneta, Sisters.Wibaux );
   modify_field( Sisters.Winnebago, Garretson );
   Danbury( Belfalls, Algonquin, Moorpark );
}
action McAdoo( Blitchton, Kokadjo ) {
   modify_field( Sisters.Mabel, Blitchton );
   add_to_field( eg_intr_md.pkt_length, Kokadjo );
}
action Blackwood( Clementon ) {
   add_to_field( eg_intr_md.pkt_length, Clementon );
}
@pragma no_egress_length_correct 1
table Waretown {
   reads {
      Sisters.Louviers : ternary;
      Sisters.Cecilton : exact;
      Sisters.Everett : ternary;
      Sisters.Vestaburg mask 0x50000 : ternary;
   }
   actions {
      Danbury;
      Lilbert;
      FlatLick;
      McAdoo;
      Blackwood;
   }
   size : 16;
}
action Carver( Magness ) {
   modify_field( Sisters.Nevis, 1 );
   modify_field( Sisters.Cecilton, 2 );
   modify_field( Sisters.Leonore, Magness );
   modify_field( Sisters.Herald, 0);
   modify_field( RedElm.Barksdale, 0 );
}
@pragma ternary 1
table Angwin {
   reads {
      eg_intr_md.egress_port : exact;
      Tarlton.Baudette : exact;
      Sisters.Everett : exact;
      Sisters.Louviers : exact;
   }
   actions {
      Carver;
   }
   default_action : Northlake();
   size : 128;
}
action Burgdorf(Bethesda, Hermiston, Lomax, Shongaloo) {
   modify_field( RedElm.Retrop, Bethesda );
   modify_field( RedElm.Delavan, Hermiston );
   modify_field( RedElm.Lafayette, Lomax );
   modify_field( RedElm.Granbury, Shongaloo );
}
@pragma ternary 1
table Abernant {
   reads {
      Sisters.Cartago : exact;
   }
   actions {
      Burgdorf;
   }
   size : 512;
}
action LaMonte( Cacao, Cisne ) {
   modify_field( Sutton.Troutman, Cacao );
   modify_field( Sutton.Bucktown, Cisne );
}
action Ambrose( Rawson, Eustis ) {
   modify_field( Sisters.Wauneta, Rawson );
   modify_field( Sisters.Wibaux, Eustis );
}
@pragma use_hash_action 1
table Holcut {
   reads {
      Sisters.Vestaburg mask 0xffff : exact;
   }
   actions {
      Ambrose;
   }
   default_action : Ambrose(0, 0);
   size : 65536;
}
@pragma use_hash_action 1
table Murphy {
   reads {
      Sisters.Vestaburg mask 0xffff : exact;
   }
   actions {
      Ambrose;
   }
   default_action : Ambrose(0, 0);
   size : 65536;
}
action Cropper( Success, Tuttle, Flatwoods ) {
   modify_field( Sisters.Milam, Success );
   modify_field( Sisters.Neavitt, Tuttle );
   modify_field( Sisters.Salome, Flatwoods );
}
table Nambe {
   reads {
      Sisters.Vestaburg mask 0xFF000000: exact;
   }
   actions {
      Cropper;
   }
   default_action : Cropper(0,0,0);
   size : 256;
}
action Almyra( Dorset, Swedeborg ) {
   modify_field( Sisters.Wenham, Dorset );
   modify_field( Sisters.Kennedale, Swedeborg );
}
action Kenmore() {
   modify_field( Sisters.Gobler, 0x1 );
}
@pragma stage 2
table Cowpens {
   reads {
      Sisters.Salome mask 0xFFF : exact;
   }
   actions {
      Almyra;
      Kenmore;
   }
   default_action : Kenmore;
   size : 4096;
}
control Shivwits {
   if( ( Sisters.Vestaburg & 0x20000 ) == 0 ) {
      apply( Holcut );
   } else {
      apply( Murphy );
   }
   if( Sisters.Vestaburg != 0 ) {
      apply( Cowpens );
   }
}
action Ripon( Loogootee, Wanatah ) {
   modify_field( Clarinda.Hauppauge, Loogootee );
   modify_field( Clarinda.Goldsboro, Wanatah, 0xFFFF0000 );
   modify_field_with_shift( Clarinda.Welaka, Sisters.Wauneta, 16, 0xF );
   modify_field( Clarinda.Ganado, Sisters.Wibaux );
}
table Redvale {
   reads {
      Sisters.Wauneta mask 0xFF000000 : exact;
   }
   actions {
      Ripon;
   }
   default_action: Northlake();
   size : 256;
}
control Skene {
   if( Sisters.Vestaburg != 0 ) {
      apply( Nambe );
   }
}
control Moraine {
   if( Sisters.Vestaburg != 0 ) {
      if( ( Sisters.Vestaburg & 0xC0000 ) ==
          0x80000 ) {
         apply( Redvale );
      }
   }
}
action Moreland() {
   modify_field( Sutton.Blakeley, Kress[0].Myoma );
   remove_header( Kress[0] );
}
table ElToro {
   actions {
      Moreland;
   }
   default_action : Moreland;
   size : 1;
}
action Odell() {
}
action Kinsley() {
   add_header( Kress[0] );
   modify_field( Kress[0].Duelm, Sisters.Hartford );
   modify_field( Kress[0].Myoma, Sutton.Blakeley );
   modify_field( Kress[0].Leeville, Antlers.Myton );
   modify_field( Kress[0].Saltair, Antlers.Pevely );
   modify_field( Sutton.Blakeley, 0x8100 );
}
@pragma ways 2
table Shawville {
   reads {
      Sisters.Hartford : exact;
      eg_intr_md.egress_port mask 0x7f : exact;
      Sisters.Casco : exact;
   }
   actions {
      Odell;
      Kinsley;
   }
   default_action : Kinsley;
   size : 128;
}
action Maywood(Rixford, Riverbank) {
   modify_field(Sutton.Pembine, Sisters.Whitakers);
   modify_field(Sutton.Yukon, Sisters.PawCreek);
   modify_field(Sutton.Troutman, Rixford);
   modify_field(Sutton.Bucktown, Riverbank);
}
action Satanta(Albemarle, Skyline) {
   Maywood(Albemarle, Skyline);
   add_to_field(Arial.Colonias, -1);
}
action Nutria(Dwight, Carlson) {
   Maywood(Dwight, Carlson);
   add_to_field(Talkeetna.Perez, -1);
}
action Hector() {
   modify_field( Sutton.Pembine, Sisters.Whitakers );
   modify_field( Sutton.Yukon, Sisters.PawCreek );
}
action Bucklin() {
   modify_field( Sutton.Pembine, Sisters.Whitakers );
   modify_field( Sutton.Yukon, Sisters.PawCreek );
   modify_field(Talkeetna.Perez, Talkeetna.Perez);
}
action Firebrick() {
   Kinsley();
}
@pragma pa_no_init egress RedElm.Retrop
@pragma pa_no_init egress RedElm.Delavan
@pragma pa_no_init egress RedElm.Lafayette
@pragma pa_no_init egress RedElm.Granbury
@pragma pa_no_init egress RedElm.Rosario
@pragma pa_no_init egress RedElm.Lemoyne
@pragma pa_no_init egress RedElm.Fouke
@pragma pa_no_init egress RedElm.Hoagland
@pragma pa_no_init egress RedElm.Accomac
@pragma pa_no_init egress RedElm.Bluff
@pragma pa_no_init egress RedElm.Starkey
@pragma pa_no_init egress RedElm.Barksdale
action Woodlake( Craig ) {
   add_header( RedElm );
   modify_field( RedElm.Rosario, Sisters.Baroda );
   modify_field( RedElm.Lemoyne, Craig );
   modify_field( RedElm.Fouke, Azalia.Kiwalik );
   modify_field( RedElm.Hoagland, Sisters.Leonore );
   modify_field( RedElm.Accomac, Sisters.Herald );
   modify_field( RedElm.Starkey, Azalia.Biggers );
}
action Council() {
   Woodlake( Sisters.Auberry );
}
action Thawville() {
   modify_field( Sutton.Pembine, Sisters.Whitakers );
   modify_field( Sutton.Yukon, Sisters.PawCreek );
}
action Trout( Natalia, Kurthwood ) {
   add_header( Sutton );
   modify_field( Sutton.Pembine, Sisters.Whitakers );
   modify_field( Sutton.Yukon, Sisters.PawCreek );
   modify_field( Sutton.Troutman, Natalia );
   modify_field( Sutton.Bucktown, Kurthwood );
   modify_field( Sutton.Blakeley, 0x0800 );
}
action FlatRock() {
   remove_header( Ludden[0] );
   remove_header( Patchogue );
   remove_header( BigRiver );
   remove_header( LeaHill );
   remove_header( Arial );
}
action Mancelona( Vichy ) {
   FlatRock();
   modify_field( Sutton.Blakeley, 0x0800 );
   Woodlake( Vichy );
}
action Talco( Lydia ) {
   FlatRock();
   modify_field( Sutton.Blakeley, 0x86dd );
   Woodlake( Lydia );
}
action Boxelder() {
   modify_field( Sutton.Blakeley, 0x0800 );
   Woodlake( Sisters.Auberry );
}
action Atoka() {
   modify_field( Sutton.Blakeley, 0x86dd );
   Woodlake( Sisters.Auberry );
}
action Wenden() {
   remove_header( Exira );
   remove_header( Patchogue );
   remove_header( BigRiver );
   remove_header( LeaHill );
   copy_header( Sutton, Holliston );
   remove_header( Holliston );
   remove_header( Arial );
   remove_header( Talkeetna );
}
action Shade( Thermal ) {
   Wenden();
   Woodlake( Thermal );
}
action Wayland( Findlay, Taneytown ) {
   remove_header( Ludden[0] );
   remove_header( Patchogue );
   remove_header( BigRiver );
   remove_header( LeaHill );
   remove_header( Arial );
   modify_field( Sutton.Pembine, Sisters.Whitakers );
   modify_field( Sutton.Yukon, Sisters.PawCreek );
   modify_field( Sutton.Troutman, Findlay );
   modify_field( Sutton.Bucktown, Taneytown );
}
action Fletcher( Logandale, Owentown ) {
   Wayland( Logandale, Owentown );
   modify_field( Sutton.Blakeley, 0x0800 );
   add_to_field( Parnell.Colonias, -1 );
}
action Miltona( Macksburg, Coupland ) {
   Wayland( Macksburg, Coupland );
   modify_field( Sutton.Blakeley, 0x86dd );
   add_to_field( Captiva.Perez, -1 );
}
action Rockland( Salix, Wausaukee ) {
   Maywood( Salix, Wausaukee );
   modify_field( Sutton.Blakeley, 0x0800 );
   add_to_field( Arial.Colonias, -1 );
}
action Oklee( Earling, Exell ) {
   Maywood( Earling, Exell );
   modify_field( Sutton.Blakeley, 0x86dd );
   add_to_field( Talkeetna.Perez, -1 );
}
action Jenison( Swisher, Roachdale ) {
   remove_header( Exira );
   remove_header( Patchogue );
   remove_header( BigRiver );
   remove_header( LeaHill );
   remove_header( Arial );
   remove_header( Talkeetna );
   modify_field( Sutton.Pembine, Sisters.Whitakers );
   modify_field( Sutton.Yukon, Sisters.PawCreek );
   modify_field( Sutton.Troutman, Swisher );
   modify_field( Sutton.Bucktown, Roachdale );
   modify_field( Sutton.Blakeley, Holliston.Blakeley );
   remove_header( Holliston );
}
action Uintah( PellCity, Lynch ) {
   Jenison( PellCity, Lynch );
   add_to_field( Parnell.Colonias, -1 );
}
action Kelvin( Hilbert, Indios ) {
   Jenison( Hilbert, Indios );
   add_to_field( Captiva.Perez, -1 );
}
action Gassoway() {
   modify_field( Sutton.Yukon, Sutton.Yukon );
}
action Modale( Oakville ) {
   modify_field( Parnell.Rockvale, Arial.Rockvale );
   modify_field( Parnell.Tennyson, Arial.Tennyson );
   modify_field( Parnell.Ribera, Arial.Ribera );
   modify_field( Parnell.Pekin, Arial.Pekin );
   modify_field( Parnell.Fonda, Arial.Fonda );
   modify_field( Parnell.Magma, Arial.Magma );
   modify_field( Parnell.Tulia, Arial.Tulia );
   modify_field( Parnell.Excello, Arial.Excello );
   modify_field( Parnell.Homeland, Arial.Homeland );
   modify_field( Parnell.Schofield, Arial.Schofield );
   add( Parnell.Colonias, Arial.Colonias, Oakville );
   modify_field( Parnell.RioPecos, Arial.RioPecos );
   modify_field( Parnell.Osage, Arial.Osage );
   modify_field( Parnell.Larchmont, Arial.Larchmont );
}
action Lennep( Stilson, Lonepine, Monsey, Greenland, CatCreek,
                         Ruthsburg, Tornillo ) {
   modify_field( Holliston.Pembine, Sisters.Whitakers );
   modify_field( Holliston.Yukon, Sisters.PawCreek );
   modify_field( Holliston.Troutman, Monsey );
   modify_field( Holliston.Bucktown, Greenland );
   add( Patchogue.Oregon, Stilson, Lonepine );
   modify_field( BigRiver.Mekoryuk, 0 );
   modify_field( LeaHill.Sespe, Sisters.Mabel );
   add( LeaHill.VanWert, Riner.Pettigrew, Tornillo );
   modify_field( Exira.Powers, 0x8 );
   modify_field( Exira.Langdon, 0 );
   modify_field( Exira.Dunphy, Sisters.Wenham );
   modify_field( Exira.Saltdale, Sisters.Kennedale );
   modify_field( Sutton.Pembine, Sisters.Milam );
   modify_field( Sutton.Yukon, Sisters.Neavitt );
   modify_field( Sutton.Troutman, CatCreek );
   modify_field( Sutton.Bucktown, Ruthsburg );
}
action Halltown( Larsen, Grants, Newborn, Kelsey,
                                Weiser, Ellisport, Caguas ) {
   add_header( Holliston );
   add_header( Patchogue );
   add_header( BigRiver );
   add_header( LeaHill );
   add_header( Exira );
   modify_field( Holliston.Blakeley, Sutton.Blakeley );
   Lennep( Larsen, Grants, Newborn, Kelsey, Weiser,
                     Ellisport, Caguas );
}
action Buckhorn( Greenwood, Shirley, Lawnside, Melba,
                                    Jarrell, Hartwell, Bogota,
                                    Brookston ) {
   Halltown( Greenwood, Shirley, Melba, Jarrell,
                            Hartwell, Bogota, Brookston );
   Nuremberg( Greenwood, Lawnside );
}
action Goudeau( Ellisburg, Adair, HamLake, Glendale,
                                    Quogue, Quinault, Ashtola,
                                    Garibaldi, Wetumpka, Pecos, Pollard, Thatcher ) {
   remove_header( Arial );
   Halltown( Ellisburg, Adair, Glendale, Quogue,
                            Quinault, Ashtola, Thatcher );
   Eastover( Ellisburg, HamLake, Garibaldi, Wetumpka, Pecos, Pollard );
}
action Nuremberg( Newhalem, Callery ) {
   modify_field( Arial.Rockvale, 0x4 );
   modify_field( Arial.Tennyson, 0x5 );
   modify_field( Arial.Ribera, 0 );
   modify_field( Arial.Pekin, 0 );
   add( Arial.Fonda, Newhalem, Callery );
   modify_field_rng_uniform(Arial.Magma, 0, 0xFFFF);
   modify_field( Arial.Tulia, 0 );
   modify_field( Arial.Excello, 1 );
   modify_field( Arial.Homeland, 0 );
   modify_field( Arial.Schofield, 0 );
   modify_field( Arial.Colonias, 64 );
   modify_field( Arial.RioPecos, 17 );
   modify_field( Arial.Osage, Sisters.Winnebago );
   modify_field( Arial.Larchmont, Sisters.Wauneta );
   modify_field( Sutton.Blakeley, 0x0800 );
}
action Eastover( Lyndell, Comfrey, Virgilina, Swansboro, Wetonka, Remsen ) {
   add_header( Clarinda );
   modify_field( Clarinda.Deloit, 0x6 );
   modify_field( Clarinda.Wynnewood, 0 );
   modify_field( Clarinda.Laplace, 0 );
   modify_field( Clarinda.Goodyear, 0 );
   add( Clarinda.Biehle, Lyndell, Comfrey );
   modify_field( Clarinda.Brookneal, 17 );
   modify_field( Clarinda.Alabam, Virgilina );
   modify_field( Clarinda.MiraLoma, Swansboro );
   modify_field( Clarinda.Craigmont, Wetonka );
   modify_field( Clarinda.Bellville, Remsen );
   modify_field( Clarinda.Goldsboro, Sisters.Wauneta, 0xFFFF );
   modify_field( Clarinda.Welaka, 0, 0xFFFFFFF0 );
   modify_field( Clarinda.Roxboro, 64 );
   modify_field( Sutton.Blakeley, 0x86dd );
}
action Mather( White, Lebanon, Adelino ) {
   add_header( Parnell );
   Modale( -1 );
   Buckhorn( Arial.Fonda, 30, 50, White,
                                Lebanon, White, Lebanon,
                                Adelino );
}
action Halfa( Harbor, Pettry, Riverland ) {
   add_header( Parnell );
   Modale( 0 );
   Nixon( Harbor, Pettry, Riverland );
}
action Alexis( Kanab ) {
   modify_field( Captiva.Holcomb, Talkeetna.Holcomb );
   modify_field( Captiva.Roggen, Talkeetna.Roggen );
   modify_field( Captiva.Suamico, Talkeetna.Suamico );
   modify_field( Captiva.Brentford, Talkeetna.Brentford );
   modify_field( Captiva.Mellott, Talkeetna.Mellott );
   modify_field( Captiva.Rollins, Talkeetna.Rollins );
   modify_field( Captiva.Veguita, Talkeetna.Veguita );
   modify_field( Captiva.Braselton, Talkeetna.Braselton );
   add( Captiva.Perez, Talkeetna.Perez, Kanab );
}
action Brackett( FairOaks, Sonestown, Pasadena ) {
   add_header( Captiva );
   Alexis( -1 );
   add_header( Arial );
   Buckhorn( Talkeetna.Mellott, 70, 90, FairOaks,
                                Sonestown, FairOaks, Sonestown,
                                Pasadena );
   remove_header( Talkeetna );
}
action Wahoo( Kaolin, Bodcaw, Flourtown ) {
   add_header( Captiva );
   Alexis( 0 );
   remove_header( Talkeetna );
   Nixon( Kaolin, Bodcaw, Flourtown );
}
action Nixon( Poulan, Denhoff, Cement ) {
   add_header( Arial );
   Buckhorn( eg_intr_md.pkt_length, 12, 32,
                                Sutton.Troutman, Sutton.Bucktown,
                                Poulan, Denhoff, Cement );
}
action LaPryor( Lolita, Dagmar, Metter ) {
   Lennep( Patchogue.Oregon, 0, Lolita, Dagmar, Lolita, Dagmar, Metter );
   Nuremberg( Arial.Fonda, 0 );
}
action Youngwood( Fleetwood, Covington, Meservey ) {
   LaPryor( Fleetwood, Covington, Meservey );
   add_to_field( Parnell.Colonias, -1 );
}
action Bonduel( Willits, Harris, Duffield ) {
   LaPryor( Willits, Harris, Duffield );
   add_to_field( Captiva.Perez, -1 );
}
action Sofia( Lepanto, Blunt, Malmo, Glenpool, Allyn,
                                McIntosh, BeeCave ) {
   Goudeau( eg_intr_md.pkt_length, 12, 12, Sutton.Troutman,
                                Sutton.Bucktown, Lepanto,
                                Blunt, Malmo, Glenpool, Allyn, McIntosh,
                                BeeCave );
}
action Emden( Pumphrey, Aspetuck, Jefferson, Alvord,
                                        Caplis, Melvina, Caban ) {
   add_header( Parnell );
   Modale( 0 );
   Goudeau( Arial.Fonda, 30, 30, Sutton.Troutman,
                                Sutton.Bucktown, Pumphrey,
                                Aspetuck, Jefferson, Alvord, Caplis, Melvina,
                                Caban );
}
action Kaltag( Millbrook, Bannack, Elmdale, Dubuque,
                                       Strasburg, Pioche, Parmelee ) {
   add_header( Parnell );
   Modale( -1 );
   Goudeau( Arial.Fonda, 30, 30, Millbrook,
                                Bannack, Millbrook, Bannack,
                                Elmdale, Dubuque, Strasburg, Pioche, Parmelee );
}
action Sledge( Piqua, Almota, Umkumiut,
                                              Magazine, Rains, Scarville, Agency ) {
   Lennep( Patchogue.Oregon, 0, Piqua, Almota,
                     Piqua, Almota, Agency );
   Eastover( eg_intr_md.pkt_length, -58, Umkumiut, Magazine, Rains, Scarville );
   remove_header( Talkeetna );
   add_to_field( Parnell.Colonias, -1 );
}
action Foster( Layton, Henry, TinCity, Nenana,
                                          Victoria, Sasakwa, Lapoint ) {
   Lennep( Patchogue.Oregon, 0, Layton, Henry,
                     Layton, Henry, Lapoint );
   Eastover( eg_intr_md.pkt_length, -38, TinCity, Nenana, Victoria, Sasakwa );
   remove_header( Arial );
   add_to_field( Parnell.Colonias, -1 );
}
action Barstow( Emblem, Westoak,
                                          Baidland ) {
   add_header( Arial );
   Lennep( Patchogue.Oregon, 0, Emblem, Westoak,
                     Emblem, Westoak, Baidland );
   Nuremberg( eg_intr_md.pkt_length, -38 );
   remove_header( Talkeetna );
   add_to_field( Parnell.Colonias, -1 );
}
table ElPrado {
   reads {
      Sisters.Louviers : exact;
      Sisters.Cecilton : exact;
      Sisters.Earlimart : exact;
      Arial.valid : ternary;
      Talkeetna.valid : ternary;
      Parnell.valid : ternary;
      Captiva.valid : ternary;
      Sisters.Vestaburg mask 0xC0000 : ternary;
   }
   actions {
      Satanta;
      Nutria;
      Hector;
      Bucklin;
      Firebrick;
      Council;
      Gassoway;
      Trout;
      Thawville;
      Boxelder;
      Atoka;
      Rockland;
      Oklee;
      Shade;
      Wenden;
      Uintah;
      Kelvin;
      Youngwood;
      Bonduel;
      Halfa;
      Wahoo;
      Mather;
      Brackett;
      Nixon;
      Sofia;
      Emden;
      Kaltag;
      Sledge;
      Foster;
      Barstow;
   }
   size : 512;
}
control CeeVee {
   apply( ElToro );
}
control McGrady {
         apply( Shawville );
}
action RioLinda() {
   drop();
}
table Thomas {
   reads {
      Sisters.Purves : exact;
      eg_intr_md.egress_port mask 0x7F: exact;
   }
   actions {
      RioLinda;
   }
   size : 512;
}
control Wharton {
   apply( Angwin ) {
      Northlake {
         apply( Waretown );
      }
   }
   apply( Abernant );
   if( Sisters.Earlimart == 0 and Sisters.Louviers == 0 and Sisters.Cecilton == 0 ) {
      apply( Thomas );
   }
   apply( ElPrado );
}
@pragma pa_no_init ingress Antlers.LasLomas
@pragma pa_no_init ingress Antlers.Sebewaing
@pragma pa_no_init ingress Antlers.Hulbert
@pragma pa_no_init ingress Antlers.Myton
@pragma pa_no_init ingress Antlers.Nooksack
action Soldotna( Saluda, Dixon, Overton ) {
   modify_field( Antlers.LasLomas, Saluda );
   modify_field( Antlers.Sebewaing, Dixon );
   modify_field( Antlers.Hulbert, Overton );
}
table Ferndale {
   reads {
      ig_intr_md.ingress_port : exact;
   }
   actions {
      Soldotna;
   }
   default_action : Soldotna(0, 0, 0);
   size : 512;
}
action Glendevey(Alcester) {
   modify_field( Antlers.Myton, Alcester );
}
action Troup(Delmont) {
   modify_field( Antlers.Myton, Delmont );
   modify_field( Azalia.Midville, Kress[0].Myoma );
}
action Danese(Penrose) {
   modify_field( Antlers.Myton, Penrose );
   modify_field( Azalia.Midville, Kress[1].Myoma );
}
action Nathalie() {
   modify_field( Antlers.Nooksack, Antlers.Sebewaing );
}
action Kelso() {
   modify_field( Antlers.Nooksack, 0 );
}
action Wilton() {
   modify_field( Antlers.Nooksack, DewyRose.Darco );
}
action Norland() {
   Wilton();
}
action Greenlawn() {
   modify_field( Antlers.Nooksack, Picayune.Helton );
}
action Tafton( Equality, Robinson ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Equality );
   modify_field( ig_intr_md_for_tm.qid, Robinson );
}
table UtePark {
   reads {
      Azalia.Flats : exact;
      Antlers.LasLomas : exact;
      Kress[0].Leeville : exact;
      Kress[1].valid : exact;
   }
   actions {
      Glendevey;
      Troup;
      Danese;
   }
   size : 256;
}
table Corder {
   reads {
      Sisters.Louviers : exact;
      Azalia.Micro : exact;
   }
   actions {
      Nathalie;
      Kelso;
      Wilton;
      Norland;
      Greenlawn;
   }
   size : 1024;
}
@pragma pa_no_init ingress ig_intr_md_for_tm.ingress_cos
@pragma pa_no_init ingress ig_intr_md_for_tm.qid
table Stratton {
   reads {
      Antlers.Hulbert : ternary;
      Antlers.LasLomas : ternary;
      Antlers.Myton : ternary;
      Antlers.Nooksack : ternary;
      Antlers.Corbin : ternary;
      Sisters.Louviers : ternary;
      RedElm.Bluff : ternary;
      RedElm.Fairfield : ternary;
   }
   actions {
      Tafton;
   }
   default_action : Tafton( 0, 0 );
   size : 306;
}
action KawCity( Calamine, Vieques ) {
   modify_field( Antlers.Gravette, Calamine );
   modify_field( Antlers.Ralph, Vieques );
}
table Ammon {
   actions {
      KawCity;
   }
   default_action : KawCity;
   size : 1;
}
action Kinston( Candle ) {
   modify_field( Antlers.Nooksack, Candle );
}
action Poteet( Millport ) {
   modify_field( Antlers.Myton, Millport );
}
action Conneaut( Kurten, ElCentro ) {
   modify_field( Antlers.Myton, Kurten );
   modify_field( Antlers.Nooksack, ElCentro );
}
table Orrville {
   reads {
      Antlers.Hulbert : exact;
      Antlers.Gravette : exact;
      Antlers.Ralph : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
      Sisters.Louviers : exact;
   }
   actions {
      Kinston;
      Poteet;
      Conneaut;
   }
   size : 1024;
}
action Slagle( McKenna, Rockport ) {
   modify_field( Antlers.Cranbury, McKenna );
}
@pragma ternary 1
table Cross {
   reads {
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Slagle;
   }
   size : 8;
}
action Rockfield() {
   modify_field( Arial.Ribera, Antlers.Nooksack );
}
action Overbrook() {
   modify_field( Talkeetna.Roggen, Antlers.Nooksack );
}
action Wymer() {
   modify_field( Parnell.Ribera, Antlers.Nooksack );
}
action Dushore() {
   modify_field( Captiva.Roggen, Antlers.Nooksack );
}
action Astatula() {
   modify_field( Arial.Ribera, Antlers.Cranbury );
}
action Emsworth() {
   Astatula();
   modify_field( Parnell.Ribera, Antlers.Nooksack );
}
action McCaulley() {
   Astatula();
   modify_field( Captiva.Roggen, Antlers.Nooksack );
}
action CoosBay() {
   modify_field( Clarinda.Wynnewood, Antlers.Cranbury );
}
action Lattimore() {
   CoosBay();
   modify_field( Parnell.Ribera, Antlers.Nooksack );
}
table Ackerman {
   reads {
      Sisters.Cecilton : ternary;
      Sisters.Louviers : ternary;
      Sisters.Earlimart : ternary;
      Arial.valid : ternary;
      Talkeetna.valid : ternary;
      Parnell.valid : ternary;
      Captiva.valid : ternary;
   }
   actions {
      Rockfield;
      Overbrook;
      Wymer;
      Dushore;
      Astatula;
      Emsworth;
      McCaulley;
      CoosBay;
      Lattimore;
   }
   size : 14;
}
control StarLake {
   apply( Ferndale );
}
control Dateland {
   apply( UtePark );
   apply( Corder );
}
control Linda {
   apply( Stratton );
}
control Humarock {
   apply( Ammon );
   apply( Orrville );
}
control Decherd {
   apply( Cross );
}
control Carroll {
   apply( Ackerman );
}
action Kooskia( PawPaw ) {
   modify_field( Antlers.Luverne, PawPaw );
}
@pragma ignore_table_dependency Urbanette
table Froid {
   reads {
      Abraham.valid : ternary;
      Sisters.Auberry : ternary;
      Sisters.Finney : ternary;
      Azalia.Aberfoil : ternary;
      Azalia.Washoe : ternary;
      Azalia.Duchesne : ternary;
      Azalia.Neubert : ternary;
   }
   actions {
      Kooskia;
   }
   default_action: Kooskia;
   size : 512;
}
blackbox meter Airmont {
   type : bytes;
   static : Narka;
   instance_count : 4096;
   yellow_value : 2;
}
counter Placid {
   type : packets;
   static : Narka;
   instance_count : 4096;
   min_width : 64;
}
action Lakebay(Lovilia) {
   count( Placid, Lovilia );
}
action Camden(Stratford) {
   Airmont.execute( ig_intr_md_for_tm.drop_ctl, Stratford );
}
action Funston(Bloomburg) {
   Camden(Bloomburg);
   Lakebay(Bloomburg);
}
table Narka {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Antlers.Luverne : exact;
   }
   actions {
      Lakebay;
      Funston;
   }
   size : 4096;
}
control Carlsbad {
   apply( Froid );
}
@pragma pa_mutually_exclusive ingress Sisters.Cartago ig_intr_md.ingress_port
@pragma pa_no_init ingress Sisters.Everett
@pragma pa_no_init ingress Sisters.Cartago
action Supai( Falls, Nuyaka ) {
   modify_field( Sisters.Cartago, ig_intr_md.ingress_port );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Falls );
   modify_field( ig_intr_md_for_tm.qid, Nuyaka );
}
action Nahunta( Francisco ) {
   modify_field( Sisters.Cartago, ig_intr_md.ingress_port );
   modify_field( ig_intr_md_for_tm.qid, Francisco, 0x18 );
}
action Oronogo( Funkley, Scotland ) {
   Supai( Funkley, Scotland );
   modify_field( Sisters.Everett, 0);
}
action Westline( Redondo ) {
   Nahunta( Redondo );
   modify_field( Sisters.Everett, 0);
}
action Grays( RichHill, Sandston ) {
   Supai( RichHill, Sandston );
   modify_field( Sisters.Everett, 1);
}
action Angle( Wayne ) {
   Nahunta( Wayne );
   modify_field( Sisters.Everett, 1);
}
action Burrel( Ledoux, Chappell ) {
   Grays( Ledoux, Chappell );
   modify_field(Azalia.Kiwalik, Kress[0].Duelm);
}
action Eclectic( Criner ) {
   Angle( Criner );
   modify_field(Azalia.Kiwalik, Kress[0].Duelm);
}
table Brinkley {
   reads {
      Sisters.Finney : exact;
      Azalia.Flats : exact;
      Tarlton.Baudette : ternary;
      Sisters.Auberry : ternary;
      Kress[0].valid : ternary;
   }
   actions {
      Oronogo;
      Westline;
      Grays;
      Angle;
      Burrel;
      Eclectic;
   }
   default_action : Angle(0);
   size : 512;
}
control Arnett {
   apply( Brinkley ) {
      Oronogo {
      }
      Grays {
      }
      Burrel {
      }
      default {
         Grainola();
      }
   }
}
counter Wabbaseka {
   type : packets_and_bytes;
   static : Dorothy;
   instance_count : 4096;
   min_width : 64;
}
field_list Bigfork {
   eg_intr_md.egress_port;
   eg_intr_md.egress_qid;
}
field_list_calculation Dietrich {
   input { Bigfork; }
   algorithm: identity;
   output_width: 12;
}
action Edgemont() {
   count_from_hash( Wabbaseka, Dietrich );
}
table Dorothy {
   actions {
      Edgemont;
   }
   default_action : Edgemont;
   size : 1;
}
control Moorman {
   apply( Dorothy );
}
action Westway() {
   modify_field( Azalia.Lochbuie, 1 );
}
action Tingley() {
}
action Caulfield() {
   Tingley();
   modify_field(Sisters.Louviers, 3);
   modify_field( Azalia.Donnelly, 0 );
   modify_field( Azalia.Whitewood, 0 );
}
action Paragonah( Brockton ) {
   Tingley();
   modify_field(Sisters.Louviers, 2);
   modify_field(Sisters.Benitez, Brockton);
   modify_field(Sisters.Salome, Azalia.Kiwalik );
   modify_field(Sisters.Bacton, 0);
}
@pragma ternary 1
table Rattan {
   reads {
      RedElm.Retrop : exact;
      RedElm.Delavan : exact;
      RedElm.Lafayette : exact;
      RedElm.Granbury : exact;
      Sisters.Louviers : ternary;
   }
   actions {
      Paragonah;
      Caulfield;
      Westway;
      Tingley;
   }
   default_action : Westway();
   size : 1024;
}
control Covelo {
   apply( Rattan );
}
action Slocum( Colstrip, Longwood, Lauada, Charters ) {
   modify_field( Rosalie.Belfast, Colstrip );
   modify_field( Navarro.Rendville, Lauada );
   modify_field( Navarro.Quivero, Longwood );
   modify_field( Navarro.Novice, Charters );
}
@pragma idletime_precision 1
table Grayland {
   reads {
      DewyRose.Portales : exact;
      Azalia.Biggers : exact;
   }
   actions {
      Slocum;
   }
   size : 16384;
   support_timeout : true;
}
action Renville(Cornville, Oklahoma) {
   modify_field( Navarro.Quivero, Cornville );
   modify_field( Navarro.Rendville, 1 );
   modify_field( Navarro.Novice, Oklahoma );
}
@pragma idletime_precision 1
table Chemult {
   reads {
      DewyRose.Brookside : exact;
      Rosalie.Belfast : exact;
   }
   actions {
      Renville;
   }
   size : 16384;
   support_timeout : true;
}
action Ridgeview( Conover, Columbia, GlenAvon ) {
   modify_field( Bryan.Cutten, Conover );
   modify_field( Bryan.Puryear, Columbia );
   modify_field( Bryan.Dalton, GlenAvon );
}
table Jacobs {
   reads {
      Sisters.Whitakers : exact;
      Sisters.PawCreek : exact;
      Sisters.Salome : exact;
   }
   actions {
      Ridgeview;
   }
   size : 16384;
}
action Lindsborg() {
}
action Maydelle( Pearl ) {
   Lindsborg();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Navarro.Quivero );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Pearl, Navarro.Novice );
}
action Eunice( Anaconda ) {
   Lindsborg();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Bryan.Cutten );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Anaconda, Bryan.Dalton );
}
action Fieldon( Wegdahl ) {
   Lindsborg();
   add( ig_intr_md_for_tm.mcast_grp_a, Sisters.Salome,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Wegdahl );
}
action Neche() {
   Lindsborg();
   add( ig_intr_md_for_tm.mcast_grp_a, Sisters.Salome,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
   modify_field( Sisters.Auberry, 26 );
}
action Dougherty( Caspiana ) {
   Lindsborg();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Sisters.Salome );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, ig_intr_md_for_tm.copy_to_cpu, Caspiana );
}
action Susank( Cleta ) {
   modify_field( ig_intr_md_for_tm.mcast_grp_a, 0 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Cleta );
}
action Nichols() {
   modify_field( Azalia.RoyalOak, 1 );
}
@pragma ignore_table_dependency Froid
table Urbanette {
   reads {
      Navarro.Rendville : ternary;
      Bryan.Puryear : ternary;
      Azalia.Washoe :ternary;
      Azalia.Alamosa : ternary;
      Azalia.Donnelly: ternary;
      Azalia.Faulkner : ternary;
      Sisters.Finney : ternary;
      Azalia.SanPablo : ternary;
      Leoma.Alnwick : ternary;
   }
   actions {
      Maydelle;
      Eunice;
      Fieldon;
      Susank;
      Dougherty;
      Neche;
   }
   size : 512;
}
control Dunedin {
   if( Azalia.Sontag == 0 and Pikeville.Wyncote == 0 and
       Pikeville.Joshua == 0 and ( ( Leoma.Alnwick & ( 0x4 ) ) == ( ( 0x4 ) ) ) and
       Azalia.Alamosa == 1 and Azalia.Micro == 0x1) {
      apply( Grayland );
   }
}
control Edgemoor {
   if( Rosalie.Belfast != 0 and Azalia.Micro == 0x1) {
      apply( Chemult );
   }
}
control Royston {
   if( Azalia.Nipton==1 ) {
      apply( Jacobs );
   }
}
control Parkland {
   if( Sisters.Louviers != 2 ) {
      apply(Urbanette);
   }
}
@pragma pa_no_init ingress ig_intr_md_for_tm.level1_mcast_hash
@pragma pa_no_init ingress ig_intr_md_for_tm.level2_mcast_hash
@pragma pa_no_init ingress ig_intr_md_for_tm.level2_exclusion_id
@pragma pa_alias ingress ig_intr_md_for_tm.level1_mcast_hash ig_intr_md_for_tm.level2_mcast_hash
action Montague(Nordheim) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Riner.Pettigrew );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Nordheim );
}
@pragma ternary 0
@pragma use_hash_action 0
table Mescalero {
   reads {
      ig_intr_md.ingress_port : exact;
   }
   actions {
      Montague;
   }
   default_action : Montague( 0 );
   size : 512;
}
field_list Farner {
   4'0;
   Sisters.Benitez;
}
field_list_calculation Marydel {
   input {
      Farner;
   }
   algorithm : identity;
   output_width : 16;
}
action Ocilla( Berville ) {
   modify_field(ig_intr_md_for_tm.level1_exclusion_id, Berville);
   modify_field(ig_intr_md_for_tm.rid, ig_intr_md_for_tm.mcast_grp_a);
}
action Hermleigh(Ulysses) {
   Ocilla( Ulysses );
}
action Sully(Chambers) {
   modify_field( ig_intr_md_for_tm.rid, 0xFFFF );
   modify_field( ig_intr_md_for_tm.level1_exclusion_id, Chambers );
}
action Jermyn() {
   Sully( 0 );
   modify_field_with_hash_based_offset( ig_intr_md_for_tm.mcast_grp_a, 0, Marydel, 65536 );
}
action DeSart( Fallsburg ) {
   modify_field(ig_intr_md_for_tm.level1_exclusion_id, Fallsburg);
   modify_field( ig_intr_md_for_tm.rid, 0 );
   modify_field_with_hash_based_offset( ig_intr_md_for_tm.mcast_grp_a, 0, Marydel, 65536 );
}
@pragma pa_no_init ingress ig_intr_md_for_tm.rid
table Ethete {
   reads {
      Sisters.Louviers : ternary;
      Sisters.Earlimart : ternary;
      Tarlton.Kenova : ternary;
      Sisters.Benitez mask 0xF0000 : ternary;
      ig_intr_md_for_tm.mcast_grp_a mask 0xF000 : ternary;
   }
   actions {
      Ocilla;
      Hermleigh;
      Sully;
      Jermyn;
   }
   default_action : Hermleigh( 0 );
   size: 512;
}
control Hartfield {
   apply(Mescalero);
}
control Pinecrest {
   if( Sisters.Finney == 0 ) {
      apply(Ethete);
   }
}
action Ravena( Gibbs ) {
   modify_field( Sisters.Salome, Gibbs );
   modify_field( Sisters.Earlimart, 1 );
}
table Irondale {
   reads {
      eg_intr_md.egress_rid: exact;
   }
   actions {
      Ravena;
   }
   size : 16384;
}
action Blairsden( Guion, Sedan, Varna, Campton, Castle ) {
   Ambrose( Guion, Guion );
   Cropper( Sedan, Varna, Campton );
   modify_field( Sisters.Cecilton, Castle );
}
table Cullen {
   reads {
      eg_intr_md.egress_rid: exact;
   }
   actions {
      Blairsden;
   }
   default_action: Northlake();
   size : 4096;
}
control Sanchez {
   if (eg_intr_md.egress_rid != 0) {
      apply( Cullen ) {
         Northlake {
            apply( Irondale );
         }
      }
   }
}
@pragma pa_no_init ingress Azalia.Surrey
action Dixmont() {
   modify_field( Azalia.Surrey, 0 );
   modify_field( Auburn.Lecanto, Azalia.Washoe );
   modify_field( Auburn.Boerne, DewyRose.Darco );
   modify_field( Auburn.Hewitt, Azalia.SanPablo );
   modify_field( Auburn.NantyGlo, Azalia.Hodges );
}
action Dunken() {
   modify_field( Azalia.Surrey, 0 );
   modify_field( Auburn.Lecanto, Azalia.Washoe );
   modify_field( Auburn.Boerne, Picayune.Helton );
   modify_field( Auburn.Hewitt, Azalia.SanPablo );
   modify_field( Auburn.NantyGlo, Azalia.Hodges );
}
action Bomarton( Kealia, Tamms ) {
   Dixmont();
   modify_field( Auburn.Gurdon, Kealia );
   modify_field( Auburn.Carnero, Tamms );
}
action Fairchild( Miranda, Trail ) {
   Dunken();
   modify_field( Auburn.Gurdon, Miranda );
   modify_field( Auburn.Carnero, Trail );
}
action Bigspring() {
   modify_field( Azalia.Surrey, 1 );
}
action Sunbury() {
   modify_field( Azalia.Purdon, 1 );
}
@pragma pa_no_init ingress Auburn.Gurdon
@pragma pa_container_size ingress Auburn.Gurdon 16
@pragma pa_no_init ingress Auburn.Daysville
@pragma pa_container_size ingress Auburn.Daysville 16
table Shawmut {
   reads {
      DewyRose.Brookside : ternary;
   }
   actions {
      Bomarton;
      Bigspring;
   }
   default_action : Dixmont();
   size : 4096;
}
table Century {
   reads {
      Picayune.ElkNeck : ternary;
   }
   actions {
      Fairchild;
      Bigspring;
   }
   default_action : Dunken();
   size : 512;
}
action Weinert( Simla, Palco ) {
   modify_field( Auburn.Daysville, Simla );
   modify_field( Auburn.Mifflin, Palco );
}
table Yorkshire {
   reads {
      DewyRose.Portales : ternary;
   }
   actions {
      Weinert;
      Sunbury;
   }
   size : 1024;
}
table Wolverine {
   reads {
      Picayune.LaHabra : ternary;
   }
   actions {
      Weinert;
      Sunbury;
   }
   size : 512;
}
control Sahuarita {
   if( Azalia.Micro == 0x1 ) {
      apply( Shawmut );
      apply( Yorkshire );
   } else if( Azalia.Micro == 0x2 ) {
      apply( Century );
      apply( Wolverine );
   }
}
metadata Gardiner NewRoads;
counter BullRun {
   type : packets;
   direct: Rossburg;
   min_width: 63;
}
table Rossburg {
   reads {
      NewRoads.Mayview mask 0x00007FFF : exact;
   }
   actions {
      Northlake;
   }
   default_action: Northlake();
   size : 32768;
}
action Moody( Bayshore, Daguao ) {
   modify_field( NewRoads.Mayview, Daguao, 0xFFFF );
   modify_field( Auburn.Seaford, Bayshore );
   modify_field( Azalia.HighHill, 1 );
}
action RioHondo( Altus, Aquilla ) {
   modify_field( NewRoads.Mayview, Aquilla, 0xFFFF );
   modify_field( Auburn.Seaford, Altus );
}
@pragma ways 3
@pragma immediate 0
table Tilton {
   reads {
      Azalia.Micro mask 0x3 : exact;
      Azalia.Biggers : exact;
   }
   actions {
      Moody;
   }
   size : 8192;
}
table Castine {
   reads {
      Azalia.Micro mask 0x3 : exact;
      ig_intr_md.ingress_port mask 0x7F : exact;
   }
   actions {
      RioHondo;
      Northlake;
   }
   default_action : Northlake();
   size : 512;
}
action Hernandez( Jessie ) {
   modify_field( Auburn.Compton, Jessie );
}
table Folger {
   reads {
      Azalia.Duchesne : ternary;
   }
   actions {
      Hernandez;
   }
   size : 1024;
}
action Fowler( Umpire ) {
   modify_field( Auburn.Ralls, Umpire );
}
table Valeene {
   reads {
      Azalia.Neubert : ternary;
   }
   actions {
      Fowler;
   }
   size : 1024;
}
action China() {
   modify_field( NewRoads.Mayview, 0 );
}
table Gheen {
   actions {
      China;
   }
   default_action : China();
   size : 1;
}
control Nunda {
   Sahuarita();
   if( ( Azalia.Manteo & 2 ) == 2 ) {
      apply( Folger );
      apply( Valeene );
   }
   if( Sisters.Louviers == 0 ) {
      apply( Castine ) {
         Northlake {
            apply( Tilton );
         }
      }
   } else {
      apply( Tilton );
   }
}
   action Bartolo( Vigus ) {
          max( NewRoads.Mayview, NewRoads.Mayview, Vigus );
   }
@pragma ways 1
table Tombstone {
   reads {
      Auburn.Seaford : exact;
      Auburn.Gurdon : exact;
      Auburn.Daysville : exact;
      Auburn.Compton : exact;
      Auburn.Ralls : exact;
      Auburn.Lecanto : exact;
      Auburn.Boerne : exact;
      Auburn.Hewitt : exact;
      Auburn.NantyGlo : exact;
      Auburn.Green : exact;
   }
   actions {
      Bartolo;
   }
   size : 4096;
}
control Center {
   apply( Tombstone );
}
@pragma pa_no_init ingress Burrton.Gurdon
@pragma pa_no_init ingress Burrton.Daysville
@pragma pa_no_init ingress Burrton.Compton
@pragma pa_no_init ingress Burrton.Ralls
@pragma pa_no_init ingress Burrton.Lecanto
@pragma pa_no_init ingress Burrton.Boerne
@pragma pa_no_init ingress Burrton.Hewitt
@pragma pa_no_init ingress Burrton.NantyGlo
@pragma pa_no_init ingress Burrton.Green
metadata Syria Burrton;
@pragma ways 1
@pragma hash_algorithm poly_0x142F0E1EBA9EA3693_init_0xFFFFFFFFFFFFFFFF
table Hadley {
   reads {
      Auburn.Seaford : exact;
      Burrton.Gurdon : exact;
      Burrton.Daysville : exact;
      Burrton.Compton : exact;
      Burrton.Ralls : exact;
      Burrton.Lecanto : exact;
      Burrton.Boerne : exact;
      Burrton.Hewitt : exact;
      Burrton.NantyGlo : exact;
      Burrton.Green : exact;
   }
   actions {
      Bartolo;
   }
   size : 4096;
}
action BealCity( Prosser, Fairmount, Shasta, Rosebush, Neshaminy, Opelousas, GunnCity, FairPlay, Idria ) {
   bit_and( Burrton.Gurdon, Auburn.Gurdon, Prosser );
   bit_and( Burrton.Daysville, Auburn.Daysville, Fairmount );
   bit_and( Burrton.Compton, Auburn.Compton, Shasta );
   bit_and( Burrton.Ralls, Auburn.Ralls, Rosebush );
   bit_and( Burrton.Lecanto, Auburn.Lecanto, Neshaminy );
   bit_and( Burrton.Boerne, Auburn.Boerne, Opelousas );
   bit_and( Burrton.Hewitt, Auburn.Hewitt, GunnCity );
   bit_and( Burrton.NantyGlo, Auburn.NantyGlo, FairPlay );
   bit_and( Burrton.Green, Auburn.Green, Idria );
}
table BurrOak {
   reads {
      Auburn.Seaford : exact;
   }
   actions {
      BealCity;
   }
   default_action : BealCity(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Burden {
   apply( BurrOak );
}
control Parkline {
   apply( Hadley );
}
@pragma ways 1
@pragma hash_algorithm poly_0x142F0E1EBA9EA3693_init_0xaaaaaaaaaaaaaaaa
table Laramie {
   reads {
      Auburn.Seaford : exact;
      Burrton.Gurdon : exact;
      Burrton.Daysville : exact;
      Burrton.Compton : exact;
      Burrton.Ralls : exact;
      Burrton.Lecanto : exact;
      Burrton.Boerne : exact;
      Burrton.Hewitt : exact;
      Burrton.NantyGlo : exact;
      Burrton.Green : exact;
   }
   actions {
      Bartolo;
   }
   size : 4096;
}
action Grenville( Immokalee, Karlsruhe, Cornudas, Rampart, Hopkins, Upalco, Winfall, Clovis, Beaufort ) {
   bit_and( Burrton.Gurdon, Auburn.Gurdon, Immokalee );
   bit_and( Burrton.Daysville, Auburn.Daysville, Karlsruhe );
   bit_and( Burrton.Compton, Auburn.Compton, Cornudas );
   bit_and( Burrton.Ralls, Auburn.Ralls, Rampart );
   bit_and( Burrton.Lecanto, Auburn.Lecanto, Hopkins );
   bit_and( Burrton.Boerne, Auburn.Boerne, Upalco );
   bit_and( Burrton.Hewitt, Auburn.Hewitt, Winfall );
   bit_and( Burrton.NantyGlo, Auburn.NantyGlo, Clovis );
   bit_and( Burrton.Green, Auburn.Green, Beaufort );
}
table Oakford {
   reads {
      Auburn.Seaford : exact;
   }
   actions {
      Grenville;
   }
   default_action : Grenville(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Cashmere {
   apply( Oakford );
}
control Waukesha {
   apply( Laramie );
}
@pragma ways 1
@pragma hash_algorithm poly_0x142F0E1EBA9EA3693_init_0x5555555555555555
table Protem {
   reads {
      Auburn.Seaford : exact;
      Burrton.Gurdon : exact;
      Burrton.Daysville : exact;
      Burrton.Compton : exact;
      Burrton.Ralls : exact;
      Burrton.Lecanto : exact;
      Burrton.Boerne : exact;
      Burrton.Hewitt : exact;
      Burrton.NantyGlo : exact;
      Burrton.Green : exact;
   }
   actions {
      Bartolo;
   }
   size : 8192;
}
action Esmond( Montegut, Boring, McMurray, Yaurel, Converse, Glyndon, Attica, Catlin, BigPark ) {
   bit_and( Burrton.Gurdon, Auburn.Gurdon, Montegut );
   bit_and( Burrton.Daysville, Auburn.Daysville, Boring );
   bit_and( Burrton.Compton, Auburn.Compton, McMurray );
   bit_and( Burrton.Ralls, Auburn.Ralls, Yaurel );
   bit_and( Burrton.Lecanto, Auburn.Lecanto, Converse );
   bit_and( Burrton.Boerne, Auburn.Boerne, Glyndon );
   bit_and( Burrton.Hewitt, Auburn.Hewitt, Attica );
   bit_and( Burrton.NantyGlo, Auburn.NantyGlo, Catlin );
   bit_and( Burrton.Green, Auburn.Green, BigPark );
}
table Milano {
   reads {
      Auburn.Seaford : exact;
   }
   actions {
      Esmond;
   }
   default_action : Esmond(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Newpoint {
   apply( Milano );
}
control Edinburgh {
   apply( Protem );
}
@pragma ways 1
@pragma hash_algorithm poly_0x142F0E1EBA9EA3693_init_0xcccccccccccccccc
table Putnam {
   reads {
      Auburn.Seaford : exact;
      Burrton.Gurdon : exact;
      Burrton.Daysville : exact;
      Burrton.Compton : exact;
      Burrton.Ralls : exact;
      Burrton.Lecanto : exact;
      Burrton.Boerne : exact;
      Burrton.Hewitt : exact;
      Burrton.NantyGlo : exact;
      Burrton.Green : exact;
   }
   actions {
      Bartolo;
   }
   size : 8192;
}
action WindLake( Hooksett, Linden, Crouch, Owanka, Occoquan, McCleary, Contact, Vallejo, Dustin ) {
   bit_and( Burrton.Gurdon, Auburn.Gurdon, Hooksett );
   bit_and( Burrton.Daysville, Auburn.Daysville, Linden );
   bit_and( Burrton.Compton, Auburn.Compton, Crouch );
   bit_and( Burrton.Ralls, Auburn.Ralls, Owanka );
   bit_and( Burrton.Lecanto, Auburn.Lecanto, Occoquan );
   bit_and( Burrton.Boerne, Auburn.Boerne, McCleary );
   bit_and( Burrton.Hewitt, Auburn.Hewitt, Contact );
   bit_and( Burrton.NantyGlo, Auburn.NantyGlo, Vallejo );
   bit_and( Burrton.Green, Auburn.Green, Dustin );
}
table Averill {
   reads {
      Auburn.Seaford : exact;
   }
   actions {
      WindLake;
   }
   default_action : WindLake(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Hahira {
   apply( Averill );
}
control Lewes {
   apply( Putnam );
}
@pragma ways 1
@pragma hash_algorithm poly_0x142F0E1EBA9EA3693_init_0x3333333333333333
table English {
   reads {
      Auburn.Seaford : exact;
      Burrton.Gurdon : exact;
      Burrton.Daysville : exact;
      Burrton.Compton : exact;
      Burrton.Ralls : exact;
      Burrton.Lecanto : exact;
      Burrton.Boerne : exact;
      Burrton.Hewitt : exact;
      Burrton.NantyGlo : exact;
      Burrton.Green : exact;
   }
   actions {
      Bartolo;
   }
   size : 4096;
}
action Locke( Beeler, Diomede, Westbury, Longmont, Hatchel, Stennett, Bethayres, Vincent, Belle ) {
   bit_and( Burrton.Gurdon, Auburn.Gurdon, Beeler );
   bit_and( Burrton.Daysville, Auburn.Daysville, Diomede );
   bit_and( Burrton.Compton, Auburn.Compton, Westbury );
   bit_and( Burrton.Ralls, Auburn.Ralls, Longmont );
   bit_and( Burrton.Lecanto, Auburn.Lecanto, Hatchel );
   bit_and( Burrton.Boerne, Auburn.Boerne, Stennett );
   bit_and( Burrton.Hewitt, Auburn.Hewitt, Bethayres );
   bit_and( Burrton.NantyGlo, Auburn.NantyGlo, Vincent );
   bit_and( Burrton.Green, Auburn.Green, Belle );
}
table Winside {
   reads {
      Auburn.Seaford : exact;
   }
   actions {
      Locke;
   }
   default_action : Locke(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Sublett {
   apply( Winside );
}
control Kenvil {
   apply( English );
}
@pragma ways 1
@pragma hash_algorithm poly_0x142F0E1EBA9EA3693_init_0x7878787878787878
table Slater {
   reads {
      Auburn.Seaford : exact;
      Burrton.Gurdon : exact;
      Burrton.Daysville : exact;
      Burrton.Compton : exact;
      Burrton.Ralls : exact;
      Burrton.Lecanto : exact;
      Burrton.Boerne : exact;
      Burrton.Hewitt : exact;
      Burrton.NantyGlo : exact;
      Burrton.Green : exact;
   }
   actions {
      Bartolo;
   }
   size : 4096;
}
action Rhine( Kingsdale, Homeworth, Poplar, Vibbard, Odessa, Merritt, Amalga, Meyers, Orrick ) {
   bit_and( Burrton.Gurdon, Auburn.Gurdon, Kingsdale );
   bit_and( Burrton.Daysville, Auburn.Daysville, Homeworth );
   bit_and( Burrton.Compton, Auburn.Compton, Poplar );
   bit_and( Burrton.Ralls, Auburn.Ralls, Vibbard );
   bit_and( Burrton.Lecanto, Auburn.Lecanto, Odessa );
   bit_and( Burrton.Boerne, Auburn.Boerne, Merritt );
   bit_and( Burrton.Hewitt, Auburn.Hewitt, Amalga );
   bit_and( Burrton.NantyGlo, Auburn.NantyGlo, Meyers );
   bit_and( Burrton.Green, Auburn.Green, Orrick );
}
table McCallum {
   reads {
      Auburn.Seaford : exact;
   }
   actions {
      Rhine;
   }
   default_action : Rhine(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Choudrant {
}
control Visalia {
}
@pragma ways 1
@pragma hash_algorithm poly_0x142F0E1EBA9EA3693_init_0x7878787878787878
table Baytown {
   reads {
      Auburn.Seaford : exact;
      Burrton.Gurdon : exact;
      Burrton.Daysville : exact;
      Burrton.Compton : exact;
      Burrton.Ralls : exact;
      Burrton.Lecanto : exact;
      Burrton.Boerne : exact;
      Burrton.Hewitt : exact;
      Burrton.NantyGlo : exact;
      Burrton.Green : exact;
   }
   actions {
      Bartolo;
   }
   size : 4096;
}
action Yocemento( Paulding, Belmore, Tabler, Tahlequah, Belvue, Henrietta, Coulter, Raiford, Cimarron ) {
   bit_and( Burrton.Gurdon, Auburn.Gurdon, Paulding );
   bit_and( Burrton.Daysville, Auburn.Daysville, Belmore );
   bit_and( Burrton.Compton, Auburn.Compton, Tabler );
   bit_and( Burrton.Ralls, Auburn.Ralls, Tahlequah );
   bit_and( Burrton.Lecanto, Auburn.Lecanto, Belvue );
   bit_and( Burrton.Boerne, Auburn.Boerne, Henrietta );
   bit_and( Burrton.Hewitt, Auburn.Hewitt, Coulter );
   bit_and( Burrton.NantyGlo, Auburn.NantyGlo, Raiford );
   bit_and( Burrton.Green, Auburn.Green, Cimarron );
}
table Panaca {
   reads {
      Auburn.Seaford : exact;
   }
   actions {
      Yocemento;
   }
   default_action : Yocemento(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Pickett {
   apply( Panaca );
}
control Doris {
   apply( Baytown );
}
counter LaSal {
   type : packets;
   direct : RoseBud;
   min_width: 64;
}
action Resaca() {
   bit_or( ig_intr_md_for_tm.copy_to_cpu, ig_intr_md_for_tm.copy_to_cpu, 0 );
}
action Nankin() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action Philippi() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 3 );
}
action DelMar() {
   bit_or( ig_intr_md_for_tm.copy_to_cpu, ig_intr_md_for_tm.copy_to_cpu, 0 );
   Philippi();
}
action Sudden() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
   Philippi();
}
table RoseBud {
   reads {
      ig_intr_md.ingress_port mask 0x7f : ternary;
      NewRoads.Mayview mask 0x00018000 : ternary;
      Azalia.Sontag : ternary;
      Azalia.Maryhill : ternary;
      Azalia.Hendley : ternary;
      Azalia.Lochbuie : ternary;
      Azalia.Beaverton : ternary;
      Azalia.Charlotte : ternary;
      Azalia.Lutsen : ternary;
      Azalia.Micro mask 0x4 : ternary;
      Sisters.Benitez : ternary;
      ig_intr_md_for_tm.mcast_grp_a : ternary;
      Sisters.Earlimart : ternary;
      Sisters.Finney : ternary;
      Azalia.Terrell : ternary;
      Azalia.Rocheport : ternary;
      Azalia.Sieper : ternary;
      Pikeville.Joshua : ternary;
      Pikeville.Wyncote : ternary;
      Azalia.Challis : ternary;
      Azalia.Ledford mask 0x2 : ternary;
      ig_intr_md_for_tm.copy_to_cpu : ternary;
      Azalia.Bluford : ternary;
      Azalia.Aberfoil : ternary;
      Azalia.Nipton : ternary;
   }
   actions {
      Resaca;
      Nankin;
      DelMar;
      Sudden;
      Philippi;
   }
   default_action: Resaca();
   size : 1536;
}
control PortVue {
   apply( Rossburg );
   apply( RoseBud ) {
      Philippi {
      }
      DelMar {
      }
      Sudden {
      }
      default {
         apply( Narka );
         {

         }
      }
   }
}
@pragma lrt_enable 0
counter PinkHill {
   type : packets;
   direct : Hammonton;
   min_width: 16;
}
@pragma pa_no_init ingress Jenkins.Dunstable
@pragma pa_no_init ingress Jenkins.Gilmanton
action Belview( Gladstone ) {
   modify_field( Jenkins.Amesville, Gladstone );
   modify_field( Azalia.Ledford, 0 );
   modify_field( Jenkins.Dunstable, DewyRose.Brookside );
   modify_field( Jenkins.Gilmanton, DewyRose.Portales );
}
@pragma ternary 1
table Hammonton {
   reads {
      Azalia.Biggers : exact;
   }
   actions {
      Belview;
   }
   size : 4094;
}
control Pinebluff {
   if( Azalia.Micro == 0x1 and Leoma.Donna != 0) {
      apply( Hammonton );
   }
}
action WestPike( Pelican ) {
   modify_field( Azalia.Ledford, Pelican );
}
action Dizney() {
   modify_field( Azalia.Ledford, 0x1 );
}
action Hampton() {
   modify_field( Azalia.Ledford, 0x5 );
}
action Browndell() {
   modify_field( Azalia.Ledford, 0x3 );
}
action Worland() {
   modify_field( Azalia.Ledford, 0x7 );
}
@pragma lrt_enable 0
counter Saticoy {
   type : packets;
   direct : Tryon;
   min_width: 16;
}
table Tryon {
   reads {
      Jenkins.Amesville : ternary;
      Jenkins.Dunstable : ternary;
      Jenkins.Gilmanton : ternary;
      Auburn.Green: ternary;
      Auburn.NantyGlo: ternary;
      Azalia.Washoe : ternary;
      Azalia.Duchesne : ternary;
      Azalia.Neubert : ternary;
   }
   actions {
      WestPike;
   }
   size : 3072;
}
control Foristell {
   if( Jenkins.Amesville != 0 and ( Azalia.Ledford & 0x1 ) == 0 ) {
      apply( Tryon );
   }
}
table Exeland {
   reads {
      Jenkins.Amesville : ternary;
      Jenkins.Dunstable : ternary;
      Jenkins.Gilmanton : ternary;
      Auburn.Green: ternary;
      Auburn.NantyGlo: ternary;
      Azalia.Washoe : ternary;
      Azalia.Duchesne : ternary;
      Azalia.Neubert : ternary;
   }
   actions {
      WestPike;
   }
   size : 2048;
}
control Hillister {
   if( Jenkins.Amesville != 0 and ( Azalia.Ledford & 0x1 ) == 0 ) {
      apply( Exeland );
   }
}
control Cleator {
}
control Peebles {
}
action Quealy( Whiteclay ) {
   modify_field( Sisters.Islen, Whiteclay );
}
action Harvard() {
   remove_header( Arial );
   remove_header( Kress[0] );
   modify_field( Sutton.Blakeley, Azalia.Midville );
}
action Shoshone() {
   remove_header( Talkeetna );
   remove_header( Kress[0] );
   modify_field( Sutton.Blakeley, Azalia.Midville );
}
action Hohenwald( Flomaton ) {
   modify_field( Sisters.Tappan, Flomaton );
   bit_or( Arial.RioPecos, Arial.RioPecos, 0x80 );
}
action Kalvesta( Gould ) {
   modify_field( Sisters.Tappan, Gould );
   bit_or( Talkeetna.Rollins, Talkeetna.Rollins, 0x80 );
}
table Hartville {
   reads {
      Sisters.Louviers : exact;
      Azalia.Washoe mask 0x80 : exact;
      Arial.valid : exact;
      Talkeetna.valid : exact;
   }
   actions {
      Hohenwald;
      Kalvesta;
      Harvard;
      Shoshone;
   }
   size : 1024;
}
action CleElum() {
   modify_field( Arial.RioPecos, 0, 0x80 );
}
action Montross() {
   modify_field( Talkeetna.Rollins, 0, 0x80 );
}
table Clarks {
   reads {
      Sisters.Tappan : exact;
      Arial.valid : exact;
      Talkeetna.valid : exact;
   }
   actions {
      CleElum;
      Montross;
   }
   size : 16;
}
action LaPalma() {
   modify_field( Azalia.Faulkner, 1 );
}
action Sutherlin(Emida) {
   modify_field( ig_intr_md_for_tm.mcast_grp_a, 0 );
   modify_field( Sisters.Finney, 1 );
   modify_field( Sisters.Auberry, Emida);
}
action LeeCreek(Mertens, Hitchland) {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
   modify_field( Sisters.Auberry, Mertens );
   modify_field( Azalia.Faulkner, Hitchland );
}
counter Ridgeland {
   type : packets_and_bytes;
   direct : Negra;
   min_width: 64;
}
table Negra {
   reads {
      Azalia.Midville : ternary;
      Azalia.Aberfoil : ternary;
      Azalia.Nipton : ternary;
      Azalia.Manteo : ternary;
      Azalia.Duchesne : ternary;
      Azalia.Neubert : ternary;
      Tarlton.Cedar : ternary;
      Azalia.Biggers : ternary;
      Leoma.Donna : ternary;
      Azalia.SanPablo : ternary;
      Abraham.valid : ternary;
      Abraham.Gaston : ternary;
      Azalia.Donnelly : ternary;
      DewyRose.Portales : ternary;
      Azalia.Washoe : ternary;
      Sisters.Clintwood : ternary;
      Sisters.Louviers : ternary;
      Picayune.LaHabra mask 0xffff0000000000000000000000000000 : ternary;
      Azalia.Whitewood :ternary;
      Sisters.Auberry :ternary;
   }
   actions {
      Sutherlin;
      LeeCreek;
      LaPalma;
      Isabel;
   }
   size : 512;
}
control Nashoba {
   apply( Negra );
}
field_list Weskan {
   Azalia.Kiwalik;
   Sisters.Cartago;
}
field_list Aniak {
   Azalia.Kiwalik;
   Sisters.Cartago;
}
field_list Ronan {
   Riner.Pettigrew;
}
field_list_calculation Suffolk {
   input {
      Ronan;
   }
   algorithm : crc16_extend;
   output_width : 51;
}
field_list Hettinger {
   Riner.Pettigrew;
}
field_list_calculation Fackler {
   input {
      Hettinger;
   }
   algorithm : crc16_extend;
   output_width : 51;
}
action Protivin( Valmont ) {
   modify_field_rng_uniform( Azalia.Dedham, 0, 0xffffffff );
   modify_field( Mausdale.Dunkerton, Valmont );
}
action Trona() {
   modify_field( Azalia.Rocheport, 1 );
}
table Woodward {
   reads {
      Tarlton.Cedar : ternary;
      ig_intr_md.ingress_port : ternary;
      Antlers.Nooksack : ternary;
      Auburn.Carnero : ternary;
      Auburn.Mifflin : ternary;
      Azalia.Washoe : ternary;
      Azalia.SanPablo : ternary;
      LeaHill.VanWert : ternary;
      LeaHill.Sespe : ternary;
      LeaHill.valid : ternary;
      Auburn.Green : ternary;
      Auburn.NantyGlo : ternary;
      Azalia.Micro : ternary;
   }
   actions {
      Trona;
      Protivin;
   }
   size : 1024;
}
control Sutter {
   apply( Woodward );
}
meter Korona {
   type : bytes;
   static : Maysfield;
   instance_count : 128;
}
action Holtville( Tillson ) {
   execute_meter( Korona, Tillson, Mausdale.Heppner );
}
action Emmet() {
   modify_field( Mausdale.Heppner, 2 );
}
@pragma pa_alias ingress Mausdale.Dunkerton Mausdale.Wagener
@pragma pa_no_init ingress Mausdale.Wagener
@pragma force_table_dependency Naguabo
table Maysfield {
   reads {
      Mausdale.Wagener : exact;
   }
   actions {
      Holtville;
      Emmet;
   }
   default_action : Emmet();
   size : 1024;
}
control Wyocena {
   apply( Maysfield );
}
action Northome() {
   modify_field(Azalia.Wrens, 1);
}
table Chatfield {
  reads {
     ig_intr_md.ingress_port : ternary;
     Azalia.Dedham : ternary;
  }
  actions {
     Northome;
     Northlake;
  }
  default_action : Northlake;
  size : 512;
}
control Camino {
   apply( Chatfield );
}

@pragma disable_reserved_i2e_drop_implementation
action Boyero( Westtown ) {
   clone_ingress_pkt_to_egress( Westtown, Weskan );
}
table Buenos {
   reads {
      Mausdale.Heppner mask 0x2 : exact;
      Mausdale.Dunkerton : exact;
     Azalia.Wrens : exact;
   }
   actions {
      Boyero;
   }
   size : 4096;
}
control Goree {
   apply( Buenos );
}
action_selector Temvik {
   selection_key : Suffolk;
   selection_mode : resilient;
}
action Catawba( Lostwood ) {
   bit_or( Mausdale.Dunkerton, Mausdale.Dunkerton, Lostwood );
}
action_profile Markville {
   actions {
      Catawba;
   }
   size : 1024;
   dynamic_action_selection : Temvik;
}
@pragma ternary 1
table Naguabo {
   reads {
      Mausdale.Dunkerton mask 0x7F : exact;
   }
   action_profile : Markville;
   size : 128;
}
control Wartrace {
   apply( Naguabo );
}
action Brownson() {
   modify_field( Sisters.Louviers, 0 );
   modify_field( Sisters.Cecilton, 3 );
}
action Philip( Quarry, Gustine, TiffCity, Traverse, Lynne, Ironside,
      Paoli, Jonesport ) {
   modify_field( Sisters.Louviers, 0 );
   modify_field( Sisters.Cecilton, 4 );
   add_header( Arial );
   modify_field( Arial.Rockvale, 0x4);
   modify_field( Arial.Tennyson, 0x5);
   modify_field( Arial.Ribera, Traverse);
   modify_field( Arial.RioPecos, 47 );
   modify_field( Arial.Colonias, TiffCity);
   modify_field( Arial.Magma, 0 );
   modify_field( Arial.Tulia, 0 );
   modify_field( Arial.Excello, 0 );
   modify_field( Arial.Homeland, 0 );
   modify_field( Arial.Schofield, 0 );
   modify_field( Arial.Osage, Quarry);
   modify_field( Arial.Larchmont, Gustine);
   add( Arial.Fonda, eg_intr_md.pkt_length, 15 );
   add_header( Sterling );
   modify_field( Sterling.McKee, Lynne);
   modify_field( Sisters.Hartford, Ironside );
   modify_field( Sisters.Whitakers, Paoli );
   modify_field( Sisters.PawCreek, Jonesport );
   modify_field( Sisters.Earlimart, 0 );
}
action Tuscumbia( Melrude ) {
   modify_field( Sisters.Auberry, Melrude );
   modify_field( Sisters.Baroda, 1 );
   modify_field( Sisters.Louviers, 0 );
   modify_field( Sisters.Cecilton, 2 );
   modify_field( Sisters.Nevis, 1 );
   modify_field( Sisters.Earlimart, 0 );
   modify_field( Azalia.Kiwalik, 0 );
}
@pragma ternary 1
table Owyhee {
   reads {
      eg_intr_md.egress_rid : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Brownson;
      Tuscumbia;
      Philip;
   }
   size : 1024;
}
control Ireton {
   apply( Owyhee );
}
action Mabana( Quebrada ) {
   modify_field( Solomon.Tecumseh, Quebrada );
}
table Havertown {
   reads {
      eg_intr_md.egress_port : exact;
   }
   actions {
      Mabana;
   }
   default_action : Mabana(0);
   size : 128;
}
control Joaquin {
   apply( Havertown );
}
action_selector Raritan {
   selection_key : Fackler;
   selection_mode : resilient;
}
action Campbell( Lazear ) {
   bit_or( Solomon.Tecumseh, Solomon.Tecumseh, Lazear );
}
action_profile Cisco {
   actions {
      Campbell;
   }
   size : 1024;
   dynamic_action_selection : Raritan;
}
@pragma ternary 1
table Woodsboro {
   reads {
      Solomon.Tecumseh mask 0x7F : exact;
   }
   action_profile : Cisco;
   size : 128;
}
control Benson {
   apply( Woodsboro );
}
meter Wadley {
   type : bytes;
   static : Rembrandt;
   instance_count : 128;
}
action Noelke( Arnold ) {
   execute_meter( Wadley, Arnold, Solomon.Frankston );
}
action Calimesa() {
   modify_field( Solomon.Frankston, 2 );
}
@pragma pa_alias egress Solomon.Tecumseh Solomon.Edler
@pragma pa_container_size egress Solomon.Frankston 16
table Rembrandt {
   reads {
      Solomon.Edler : exact;
   }
   actions {
      Noelke;
      Calimesa;
   }
   default_action : Calimesa();
   size : 1024;
}
control Rawlins {
   apply( Rembrandt );
}
action Dunnellon() {
   modify_field( Sisters.Cartago, eg_intr_md.egress_port );
   modify_field( Azalia.Kiwalik, Sisters.Salome );
   clone_egress_pkt_to_egress( Solomon.Tecumseh, Aniak );
}
table Talbotton {
   actions {
      Dunnellon;
   }
   default_action: Dunnellon();
   size : 1;
}
control Norborne {
   if( Solomon.Tecumseh != 0 and Solomon.Frankston == 0 ) {
      apply( Talbotton );
   }
}
counter Teigen {
   type : packets;
   direct : Lovett;
   min_width: 64;
}
action Courtdale() {
   drop();
}
table Lovett {
   reads {
      eg_intr_md.egress_port mask 0x7f : exact;
      Stone.Bladen : ternary;
      Stone.Uncertain : ternary;
      Sisters.Gobler : ternary;
      Arial.Colonias : ternary;
      Arial.valid : ternary;
      Sisters.Earlimart : ternary;
   }
   actions {
      Courtdale;
      Northlake;
   }
   default_action : Northlake();
   size : 512;
}
control ShadeGap {
   apply( Lovett ) {
      Northlake {
         Norborne();
      }
   }
}
counter Kulpmont {
   type : packets_and_bytes;
   direct: Wimbledon;
   min_width: 32;
}
table Wimbledon {
   reads {
      Azalia.Ranburne : exact;
      Sisters.Louviers : exact;
      Azalia.Biggers mask 0xfff : exact;
   }
   actions {
      Northlake;
   }
   default_action: Northlake();
   size : 12288;
}
control Wauna {
   if( Sisters.Earlimart == 1 ) {
      apply( Wimbledon );
   }
}
counter Waialua {
   type : packets_and_bytes;
   direct: Kenefic;
   min_width: 64;
}
table Kenefic {
   reads {
      Sisters.Louviers mask 1: exact;
      Sisters.Salome mask 0xfff : exact;
   }
   actions {
      Northlake;
   }
   default_action: Northlake();
   size : 8192;
}
control Disney {
   if( Sisters.Earlimart == 1 ) {
      apply( Kenefic );
   }
}
control Belmont {
}
control Sarasota {
}
control DeKalb {
}
control Bayport {
}
control Valentine {
}
control Sublimity {
}
control ingress {
   Northboro();
   {
      apply( Markesan );
      if( RedElm.valid == 0 ) {
         Galestown();
      }
      Floris();
      Nunda();
      Machens();
      Burden();
      Telephone();
      Rockleigh();
            Folcroft();
      if ( Azalia.Sontag == 0 and Pikeville.Wyncote == 0 and
         Pikeville.Joshua == 0 ) {
         KingCity();
         if ( ( ( Leoma.Alnwick & ( 0x2 ) ) == ( ( 0x2 ) ) ) and Azalia.Micro == 0x2 and Leoma.Donna == 1 ) {
            Haworth();
         } else {
            if ( ( ( Leoma.Alnwick & ( 0x1 ) ) == ( ( 0x1 ) ) ) and Azalia.Micro == 0x1 and Leoma.Donna == 1 ) {
               Guadalupe();
               Emerado();
            } else {
               if( valid( RedElm ) ) {
                  Covelo();
               }
               if( Sisters.Finney == 0 and Sisters.Louviers != 2 ) {
                  Tulsa();
               }
            }
         }
      }
      Horsehead();
      Lublin();
      TiePlant();
      RedLevel();
      Parkline();
      Cashmere();
      StarLake();

      Belmont();
      Lisman();
      Visalia();
      Choudrant();
      Onset();
      Pinebluff();
      Bayport();
      Dateland();
      Waukesha();
      Newpoint();

      apply( Seabrook );


      Bains();
      Basco();
      Keyes();
      apply( Lynndyl );
      Edinburgh();
      Hahira();
      Dunedin();

      Linda();
      Sutter();
      Nashoba();
      DeKalb();
   }

   {
      Royston();
      Camino();
      Wartrace();
      {
            Tamora();
      }
      Edgemoor();
      Lewes();
      Sublett();
      Paisano();
      Kenvil();


      Gully();
      Foristell();
      Hartfield();


      Wyocena();
      Calvary();
      apply( Tamaqua );
      apply(Hartville);
      Carlsbad();
      {
         Parkland();
      }
      Kisatchie();
      Hillister();
      if( Azalia.HighHill == 1 and Leoma.Donna == 0 ) {
         apply( Gheen );
      }
      if( RedElm.valid == 0 ) {
         Humarock();
      }

      Arnett();
      if( valid( Kress[0] ) and Sisters.Louviers != 2 ) {
         CeeVee();
      }
      Goree();
   PortVue();
      Pinecrest();
      Boistfort();

      Sarasota();
   }
}
control egress {
   {

   }
   {
      Shivwits();
      Moorman();
      if( ( (eg_intr_md_from_parser_aux.clone_src == NOT_CLONED) ) ) {
         Decherd();
         Sanchez();
         Joaquin();
         if( ( eg_intr_md.egress_rid == 0 ) and
            ( eg_intr_md.egress_port != 66 ) ) {
            Wauna();
         }
         if( Sisters.Louviers == 0 or Sisters.Louviers == 3 ) {
            apply( Clarks );
         }
         Skene();
         Rawlins();
         Valdosta();
      } else {
         Ireton();
      }
      Wharton();
      if( ( (eg_intr_md_from_parser_aux.clone_src == NOT_CLONED) ) and Sisters.Nevis == 0 ) {
         Disney();
         if( Sisters.Louviers != 2 and Sisters.Casco == 0 ) {
            Bendavis();
         }
         Benson();
         Carroll();
         Moraine();
         ShadeGap();
      }
      if( Sisters.Nevis == 0 and Sisters.Louviers != 2 and Sisters.Cecilton != 3 ) {
         McGrady();
      }
   }
   Sublimity();
}

