@pragma command_line --disable-parse-max-depth-limit

// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 173231

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
#include <tofino/wred_blackbox.p4>
@pragma pa_container_size ingress Mendon.Tunica 16
@pragma pa_container_size ingress Lindsborg.LakePine 16
header_type Wynnewood {
	fields {
		Conda : 16;
		Alameda : 8;
		Dixmont : 8;
		Bartolo : 4;
		Lilydale : 3;
		Salamatof : 3;
		Tonasket : 3;
	}
}
header_type Ahuimanu {
	fields {
		Handley : 24;
		Mogadore : 24;
		Mackville : 24;
		Pineland : 24;
		Monico : 16;
		Amory : 12;
		Bodcaw : 20;
		Woodfield : 12;
		Aguilita : 16;
		Ramapo : 8;
		Arredondo : 8;
		DelRey : 3;
		Alderson : 1;
		Rockville : 1;
		Denhoff : 3;
		Golden : 3;
		Delavan : 1;
		Hillcrest : 1;
		Asher : 1;
		Baudette : 1;
		Lundell : 1;
		Calvary : 1;
		Felton : 1;
		Duque : 1;
		Meeker : 1;
		Andrade : 1;
		Wheeler : 1;
		DeerPark : 1;
		Sanatoga : 1;
		Petrey : 1;
		Ashwood : 1;
		Strevell : 1;
		Ontonagon : 1;
		BigRun : 1;
		Lamine : 1;
		Abilene : 1;
		Pringle : 1;
		Newfane : 1;
		Kulpmont : 1;
		Gibbstown : 1;
		Camden : 1;
		Moorpark : 1;
		Immokalee : 1;
		Chewalla : 1;
		Sheyenne : 11;
		Hackamore : 11;
		Cankton : 16;
		Glynn : 16;
		Woodsboro : 12;
		Claiborne : 12;
		Verdemont : 16;
		Hansell : 16;
		Godley : 8;
		DesPeres : 2;
		Quarry : 2;
		Pittsboro : 1;
		Mattese : 1;
		Wanamassa : 16;
		Palouse : 16;
		Roberta : 2;
		Blitchton : 16;
	}
}
header_type Leawood {
	fields {
		Westpoint : 4;
		Lovewell : 4;
		Altus : 1;
	}
}
header_type MontIda {
	fields {
		Edroy : 1;
		Coulee : 1;
		Wilton : 1;
		AvonLake : 16;
		Juneau : 16;
		Hammond : 32;
		Jamesburg : 32;
		Tavistock : 1;
		Floral : 1;
		NewAlbin : 1;
		Aynor : 1;
		Baroda : 1;
		Mickleton : 1;
		Amanda : 1;
		JimFalls : 1;
		Geeville : 1;
		Frontenac : 1;
	}
}
header_type Folcroft {
	fields {
		Gause : 24;
		Stowe : 24;
		Rockdale : 1;
		Austell : 3;
		Snowball : 1;
		Wallula : 12;
		Chubbuck : 20;
		Trout : 20;
		Coalgate : 16;
		Amalga : 16;
		Miranda : 12;
		Crossnore : 10;
		Edgemoor : 3;
		Trotwood : 8;
		FoxChase : 1;
		Ivanpah : 32;
		Marydel : 32;
		Pengilly : 2;
		Realitos : 32;
		Pittwood : 9;
		Lisman : 2;
		Cassadaga : 1;
		Creston : 1;
		Ellisburg : 12;
		BallClub : 1;
		Billett : 1;
		Annetta : 1;
		Grainola : 2;
		Mendota : 32;
		Catarina : 32;
		Millhaven : 8;
		Union : 24;
		Bevier : 24;
		Tocito : 2;
	}
}
header_type Honobia {
	fields {
		Kiron : 10;
		Merrill : 10;
		Eastman : 2;
	}
}
header_type Enfield {
	fields {
		Algoa : 10;
		Mumford : 10;
		Emerado : 2;
		Puyallup : 8;
		Liberal : 6;
		Tularosa : 16;
		Hilbert : 4;
		Brazos : 4;
	}
}
header_type Copley {
	fields {
		Deloit : 8;
		Wetumpka : 4;
		Basalt : 1;
	}
}
header_type Bowen {
	fields {
		Anacortes : 32;
		BigArm : 32;
		Leicester : 32;
		Pachuta : 6;
		Rotonda : 6;
		Lilbert : 16;
	}
}
header_type Dresser {
	fields {
		Alcoma : 128;
		Squire : 128;
		Tamora : 8;
		ElPrado : 6;
		Valeene : 16;
	}
}
header_type Angwin {
	fields {
		Tunica : 14;
		Moark : 12;
		Rixford : 1;
		Rardin : 2;
	}
}
header_type Frederika {
	fields {
		Poulan : 1;
		Basco : 1;
	}
}
header_type Faysville {
	fields {
		Cedar : 1;
		DuBois : 1;
	}
}
header_type Montello {
	fields {
		Iredell : 2;
	}
}
header_type PineLake {
	fields {
		LakePine : 2;
		Arion : 14;
		Verdery : 14;
		Waitsburg : 2;
		Elderon : 14;
	}
}
header_type Laramie {
	fields {
		Utuado : 16;
		Accomac : 16;
		Blairsden : 16;
		Grigston : 16;
		Clementon : 16;
		Manakin : 16;
	}
}
header_type Greendale {
	fields {
		Raeford : 16;
		Ochoa : 16;
	}
}
header_type Kenvil {
	fields {
		Plata : 2;
		Devore : 6;
		FairOaks : 3;
		Fontana : 1;
		Heads : 1;
		Carlson : 1;
		Moneta : 3;
		Mayday : 1;
		Sheldahl : 6;
		Oneonta : 6;
		Gilmanton : 4;
		KawCity : 5;
		Rapids : 1;
		Lapeer : 1;
		Careywood : 1;
		Alstown : 2;
		BullRun : 12;
		Raritan : 1;
	}
}
header_type Oakes {
	fields {
		Lathrop : 16;
	}
}
header_type Milano {
	fields {
		Amesville : 16;
		Botna : 1;
		Nutria : 1;
	}
}
header_type Roswell {
	fields {
		Twinsburg : 16;
		Eunice : 1;
		Oklahoma : 1;
	}
}
header_type Jenifer {
	fields {
		Hadley : 16;
		Between : 16;
		Rienzi : 16;
		Monida : 16;
		MudLake : 16;
		Newtown : 16;
		Ortley : 8;
		Moylan : 8;
		Westland : 8;
		Agency : 8;
		Clearco : 1;
		Bonney : 6;
	}
}
header_type Courtdale {
	fields {
		Yantis : 32;
	}
}
header_type Cutler {
	fields {
		Lamar : 8;
		Downs : 32;
		Waterfall : 32;
	}
}
header_type Virgin {
	fields {
		Lakefield : 8;
	}
}
header_type Sanchez {
	fields {
		NewTrier : 1;
		Whitewood : 1;
		Allerton : 1;
		Hanford : 20;
	}
}
header_type Milan {
	fields {
		Gonzales : 6;
		Wellsboro : 10;
		Hallville : 4;
		Narka : 12;
		Mondovi : 2;
		Alexis : 2;
		Wattsburg : 12;
		Pearson : 8;
		Uhland : 2;
		Cowden : 3;
		Westoak : 1;
		Dasher : 2;
	}
}
header_type Westwego {
	fields {
		Findlay : 24;
		Lansdowne : 24;
		Sherwin : 24;
		Goldenrod : 24;
		Suamico : 16;
	}
}
header_type Parkway {
	fields {
		Christina : 3;
		Carroll : 1;
		Triplett : 12;
		Maury : 16;
	}
}
header_type Rockland {
	fields {
		Center : 20;
		Dunedin : 3;
		Perez : 1;
		Brookland : 8;
	}
}
header_type Raceland {
	fields {
		RedCliff : 4;
		Micro : 4;
		Fittstown : 6;
		Onava : 2;
		Nisland : 16;
		FarrWest : 16;
		Dacono : 1;
		Breese : 1;
		Temple : 1;
		Atlantic : 13;
		Wildell : 8;
		Terry : 8;
		Milbank : 16;
		Elmhurst : 32;
		Waseca : 32;
	}
}
header_type Longville {
	fields {
		Hubbell : 4;
		Shubert : 6;
		Addicks : 2;
		Clarks : 20;
		Spenard : 16;
		Loveland : 8;
		Thach : 8;
		Carnation : 128;
		Vantage : 128;
	}
}
header_type Rillton {
	fields {
		Tolono : 4;
		Westville : 6;
		Broadwell : 2;
		Euren : 20;
		SwissAlp : 16;
		BirchRun : 8;
		Lyncourt : 8;
		Cherokee : 32;
		Naylor : 32;
		Estrella : 32;
		Cisne : 32;
		RedBay : 32;
		Perrine : 32;
		Wimbledon : 32;
		Malesus : 32;
	}
}
header_type Ossineke {
	fields {
		Harvey : 8;
		Sparkill : 8;
		Chatanika : 16;
	}
}
header_type Range {
	fields {
		Arvana : 16;
		Dagsboro : 16;
	}
}
header_type Ebenezer {
	fields {
		Waxhaw : 32;
		Durant : 32;
		Emory : 4;
		Chaska : 4;
		Goodrich : 8;
		Uncertain : 16;
	}
}
header_type Gully {
	fields {
		Seagate : 16;
	}
}
header_type Balfour {
	fields {
		Ambrose : 16;
	}
}
header_type Ignacio {
	fields {
		Willette : 16;
		Fowlkes : 16;
		Giltner : 8;
		Eaton : 8;
		CoalCity : 16;
	}
}
header_type Locke {
	fields {
		Humeston : 48;
		Belfair : 32;
		Earlham : 48;
		Mellott : 32;
	}
}
header_type Coulter {
	fields {
		Hauppauge : 1;
		Pecos : 1;
		Bremond : 1;
		Lennep : 1;
		Oakridge : 1;
		Edesville : 3;
		Power : 5;
		Tennyson : 3;
		Maida : 16;
	}
}
header_type Bellport {
	fields {
		Poland : 24;
		Ambler : 8;
	}
}
header_type Sturgeon {
	fields {
		Telma : 8;
		Whatley : 24;
		Bunavista : 24;
		Lindy : 8;
	}
}
header_type Amasa {
	fields {
		Ferrum : 8;
	}
}
header_type Licking {
	fields {
		Waialee : 32;
		Fairland : 32;
	}
}
header Westwego Escondido;
header Westwego Hobson;
header Parkway Benkelman;
header Parkway Protivin;
header Rockland Robstown[ 1 ];
@pragma pa_fragment ingress McFaddin.Milbank
@pragma pa_fragment egress McFaddin.Milbank
@pragma pa_container_size ingress McFaddin.Waseca 32
@pragma pa_container_size ingress McFaddin.Elmhurst 32
@pragma pa_container_size egress McFaddin.Dacono 8
@pragma pa_container_size egress McFaddin.Breese 8
@pragma pa_container_size egress McFaddin.Temple 8
@pragma pa_container_size egress McFaddin.Atlantic 8
header Raceland McFaddin;
@pragma pa_fragment ingress Macedonia.Milbank
@pragma pa_fragment egress Macedonia.Milbank
@pragma pa_container_size egress Macedonia.Atlantic 8
@pragma pa_container_size egress Macedonia.Dacono 8
@pragma pa_container_size egress Macedonia.Breese 8
@pragma pa_container_size egress Macedonia.Temple 8
header Raceland Macedonia;
@pragma pa_container_size egress Harriet.Vantage 32
@pragma pa_container_size egress Harriet.Carnation 32
header Longville Harriet;
@pragma pa_container_size ingress Radcliffe.Vantage 32
@pragma pa_container_size egress Radcliffe.Vantage 32
@pragma pa_container_size ingress Radcliffe.Carnation 32
@pragma pa_container_size egress Radcliffe.Carnation 32
header Longville Radcliffe;
header Rillton Holliday;
@pragma disable_deparser_checksum_unit 0 1
header Range Elmsford;
header Range Nowlin;
header Ebenezer Shelbiana;
header Gully Skiatook;
header Balfour Boysen;
header Ebenezer Tenino;
header Gully Reubens;
header Balfour Higganum;
@pragma pa_container_size egress Hookdale.Bunavista 32
@pragma pa_container_size egress Hookdale.Whatley 32
@pragma pa_container_size ingress Hookdale.Whatley 32
// @pragma pa_container_size ingress Hookdale.Telma 8
header Sturgeon Hookdale;
header Coulter Belle;
header Ignacio Barwick;
@pragma pa_container_size egress Tecumseh.Gonzales 32
@pragma not_deparsed ingress
@pragma not_parsed egress
header Milan Tecumseh;
header Amasa Inola;
header Licking Folger;
@pragma parser_value_set_size 2
parser_value_set Morrow;
parser start {
   return select( ig_intr_md.ingress_port ) {
      Morrow : Carrizozo;
      default : Graford;
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
   return select(current(96, 16)) {
      default : Graford;
      0xBF00 : Harshaw;
   }
}
parser Mahopac {
   return select( current(0, 32) ) {
      0x00010800 : Noorvik;
      default : ingress;
   }
}
parser Noorvik {
   extract( Barwick );
   return ingress;
}
@pragma not_critical
parser Harshaw {
   extract( Tecumseh );
   return Graford;
}
@pragma force_shift ingress 112
parser Carrizozo {
   return Floris;
}
@pragma not_critical
parser Floris {
   extract( Tecumseh );
   return Graford;
}
parser KentPark {
   set_metadata(Loysburg.Bartolo, 0x5);
   return ingress;
}
parser Quinwood {
   set_metadata(Loysburg.Bartolo, 0x6);
   return ingress;
}
parser Monowi {
   set_metadata( Loysburg.Bartolo, 0x8 );
   return ingress;
}
parser Graford {
   extract( Escondido );
   return select( current(0, 8), Escondido.Suamico ) {
      0x9100 mask 0xFFFF : Horns;
      0x88a8 mask 0xFFFF : Horns;
      0x8100 mask 0xFFFF : Wadley;
      0x0806 mask 0xFFFF : Mahopac;
      0x450800 : Malinta;
      0x50800 mask 0xFFFFF : KentPark;
      0x0800 mask 0xFFFF : Maybee;
      0x6086dd mask 0xF0FFFF : Wrens;
      0x86dd mask 0xFFFF : Quinwood;
      0x8808 mask 0xFFFF : Monowi;
      default : ingress;
      0 : Clauene;
   }
}
parser Horns {
   extract( Protivin );
   return select( Protivin.Maury ) {
      0x8100 : Eldred;
      0x0806 mask 0xFFFF : Mahopac; 0x450800 : Malinta; 0x50800 mask 0xFFFFF : KentPark; 0x0800 mask 0xFFFF : Maybee; 0x6086dd mask 0xF0FFFF : Wrens; 0x86dd mask 0xFFFF : Quinwood; default : ingress;
   }
}
parser Eldred {
   extract( Benkelman );
   return select( current(0, 8), Benkelman.Maury ) {
      0x0806 mask 0xFFFF : Mahopac; 0x450800 : Malinta; 0x50800 mask 0xFFFFF : KentPark; 0x0800 mask 0xFFFF : Maybee; 0x6086dd mask 0xF0FFFF : Wrens; 0x86dd mask 0xFFFF : Quinwood; default : ingress;
   }
}
parser Wadley {
   extract( Benkelman );
   return select( current(0, 8), Benkelman.Maury ) {
      0x0806 mask 0xFFFF : Mahopac; 0x450800 : Malinta; 0x50800 mask 0xFFFFF : KentPark; 0x0800 mask 0xFFFF : Maybee; 0x6086dd mask 0xF0FFFF : Wrens; 0x86dd mask 0xFFFF : Quinwood; default : ingress;
   }
}
parser Florida {
   set_metadata( Crumstown.Monico, 0x0800 );
   set_metadata(Crumstown.Golden, 4);
   return select(current(0,4), current(4,4)) {
      0x45 mask 0xFF : Ryderwood;
      default : Heflin;
   }
}
parser Bouton {
   set_metadata( Crumstown.Monico, 0x86dd );
   set_metadata(Crumstown.Golden, 4);
   return Yemassee;
}
field_list Mabana {
   McFaddin.RedCliff;
   McFaddin.Micro;
   McFaddin.Fittstown;
   McFaddin.Onava;
   McFaddin.Nisland;
   McFaddin.FarrWest;
   McFaddin.Dacono;
   McFaddin.Breese;
   McFaddin.Temple;
   McFaddin.Atlantic;
   McFaddin.Wildell;
   McFaddin.Terry;
   McFaddin.Elmhurst;
   McFaddin.Waseca;
}
field_list_calculation Franktown {
   input {
      Mabana;
   }
   algorithm : csum16;
   output_width : 16;
}
calculated_field McFaddin.Milbank {
   verify Franktown;
   update Franktown;
}
field_list Kensal {
   Crumstown.Wanamassa;
   Crumstown.Palouse;
   Boysen.Ambrose;
}
@pragma calculated_field_update_location ingress
field_list_calculation Tulalip {
   input {
      Kensal;
   }
   algorithm : csum16;
   output_width : 16;
}
calculated_field Boysen.Ambrose {
   update Tulalip;
}
parser Malinta {
   extract( McFaddin );
   set_metadata(Crumstown.Arredondo, McFaddin.Wildell);
   set_metadata(Loysburg.Bartolo, 0x1);
   return select(McFaddin.Atlantic, McFaddin.Terry) {
      4 : Florida;
      41 : Bouton;
      1 : Filer;
      17 : Fredonia;
      6 : Kinards;
      47 : Green;
      0 mask 0x1fff00 : ingress;
      6 mask 0xff: Wellford;
      default : Magma;
   }
}
parser Maybee {
   set_metadata(McFaddin.Waseca, current(128,32));
   set_metadata(Loysburg.Bartolo, 0x3);
   set_metadata(McFaddin.Fittstown, current(8, 6));
   set_metadata(McFaddin.Terry, current(72,8));
   set_metadata(Crumstown.Arredondo, current(64,8));
   return ingress;
}
parser Wellford {
   set_metadata(Loysburg.Tonasket, 5);
   return ingress;
}
parser Magma {
   set_metadata(Loysburg.Tonasket, 1);
   return ingress;
}
parser Wrens {
   extract( Radcliffe );
   set_metadata(Crumstown.Arredondo, Radcliffe.Thach);
   set_metadata(Loysburg.Bartolo, 0x2);
   return select(Radcliffe.Loveland) {
      0x3a : Filer;
      17 : Advance;
      6 : Kinards;
      4 : Florida;
      41 : Bouton;
      default : ingress;
   }
}
parser Clauene {
   extract( Holliday );
   set_metadata(Crumstown.Arredondo, Holliday.Lyncourt);
   set_metadata(Loysburg.Bartolo, 0x2);
   return select(Holliday.BirchRun) {
      0x3a : Filer;
      17 : Advance;
      6 : Kinards;
      default : ingress;
   }
}
parser Fredonia {
   set_metadata(Loysburg.Tonasket, 2);
   extract(Elmsford);
   extract(Skiatook);
   extract(Boysen);
   return select(Elmsford.Dagsboro) {
      4789 : Bettles;
      65330 : Bettles;
      default : ingress;
    }
}
parser Filer {
   extract(Elmsford);
   return ingress;
}
parser Advance {
   set_metadata(Loysburg.Tonasket, 2);
   extract(Elmsford);
   extract(Skiatook);
   extract(Boysen);
   return select(Elmsford.Dagsboro) {
      default : ingress;
   }
}
parser Kinards {
   set_metadata(Loysburg.Tonasket, 6);
   extract(Elmsford);
   extract(Shelbiana);
   extract(Boysen);
   return ingress;
}
parser Holden {
   set_metadata(Crumstown.Golden, 2);
   return select( current(4, 4) ) {
      0x5 : Ryderwood;
      default : Heflin;
   }
}
parser Chalco {
   return select( current(0,4) ) {
      0x4 : Holden;
      default : ingress;
   }
}
parser Farnham {
   set_metadata(Crumstown.Golden, 2);
   return Yemassee;
}
parser Cowan {
   return select( current(0,4) ) {
      0x6 : Farnham;
      default: ingress;
   }
}
parser Green {
   extract(Belle);
   return select(Belle.Hauppauge, Belle.Pecos, Belle.Bremond, Belle.Lennep, Belle.Oakridge,
             Belle.Edesville, Belle.Power, Belle.Tennyson, Belle.Maida) {
      0x0800 : Chalco;
      0x86dd : Cowan;
      default : ingress;
   }
}
parser Bettles {
   extract(Hookdale);
   set_metadata(Crumstown.Golden, 1);
   return Buckfield;
}
parser Bradner {
   extract(Hookdale);
   set_metadata(Crumstown.Golden, 1);
   return Emblem;
}
field_list Biehle {
   Macedonia.RedCliff;
   Macedonia.Micro;
   Macedonia.Fittstown;
   Macedonia.Onava;
   Macedonia.Nisland;
   Macedonia.FarrWest;
   Macedonia.Dacono;
   Macedonia.Breese;
   Macedonia.Temple;
   Macedonia.Atlantic;
   Macedonia.Wildell;
   Macedonia.Terry;
   Macedonia.Elmhurst;
   Macedonia.Waseca;
}
field_list_calculation Ardenvoir {
   input {
      Biehle;
   }
   algorithm : csum16;
   output_width : 16;
}
calculated_field Macedonia.Milbank {
   verify Ardenvoir;
   update Ardenvoir;
}
parser Ryderwood {
   extract( Macedonia );
   set_metadata(Loysburg.Alameda, Macedonia.Terry);
   set_metadata(Loysburg.Dixmont, Macedonia.Wildell);
   set_metadata(Loysburg.Lilydale, 0x1);
   set_metadata(LaMoille.Anacortes, Macedonia.Elmhurst);
   set_metadata(LaMoille.BigArm, Macedonia.Waseca);
   set_metadata(LaMoille.Pachuta, Macedonia.Fittstown);
   return select(Macedonia.Atlantic, Macedonia.Terry) {
      1 : Amsterdam;
      17 : Roxobel;
      6 : Bushland;
      0 mask 0x1fff00 : ingress;
      6 mask 0xff: Winger;
      default : Greenbelt;
   }
}
parser Heflin {
   set_metadata(Loysburg.Lilydale, 0x3);
   set_metadata(LaMoille.Pachuta, current(8, 6));
   return ingress;
}
parser Winger {
   set_metadata(Loysburg.Salamatof, 5);
   return ingress;
}
parser Greenbelt {
   set_metadata(Loysburg.Salamatof, 1);
   return ingress;
}
parser Yemassee {
   extract( Harriet );
   set_metadata(Loysburg.Alameda, Harriet.Loveland);
   set_metadata(Loysburg.Dixmont, Harriet.Thach);
   set_metadata(Loysburg.Lilydale, 0x2);
   set_metadata(Waterflow.ElPrado, Harriet.Shubert);
   set_metadata(Waterflow.Alcoma, Harriet.Carnation);
   set_metadata(Waterflow.Squire, Harriet.Vantage);
   return select(Harriet.Loveland) {
      0x3a : Amsterdam;
      17 : Roxobel;
      6 : Bushland;
      default : ingress;
   }
}
parser Amsterdam {
   set_metadata( Crumstown.Verdemont, current( 0, 16 ) );
   extract(Nowlin);
   return ingress;
}
parser Roxobel {
   set_metadata( Crumstown.Verdemont, current( 0, 16 ) );
   set_metadata( Crumstown.Hansell, current( 16, 16 ) );
   set_metadata(Loysburg.Salamatof, 2);
   extract(Nowlin);
   extract(Reubens);
   extract(Higganum);
   return ingress;
}
parser Bushland {
   set_metadata( Crumstown.Verdemont, current( 0, 16 ) );
   set_metadata( Crumstown.Hansell, current( 16, 16 ) );
   set_metadata( Crumstown.Godley, current( 104, 8 ) );
   set_metadata(Loysburg.Salamatof, 6);
   extract(Nowlin);
   extract(Tenino);
   extract(Higganum);
   return ingress;
}
parser BigPiney {
   set_metadata(Loysburg.Lilydale, 0x5);
   return ingress;
}
parser Luning {
   set_metadata(Loysburg.Lilydale, 0x6);
   return ingress;
}
parser Buckfield {
   extract( Hobson );
   set_metadata( Crumstown.Handley, Hobson.Findlay );
   set_metadata( Crumstown.Mogadore, Hobson.Lansdowne );
   set_metadata( Crumstown.Monico, Hobson.Suamico );
   return select( current( 0, 8 ), Hobson.Suamico ) {
      0x0806 mask 0xFFFF : Mahopac;
      0x450800 : Ryderwood;
      0x50800 mask 0xFFFFF : BigPiney;
      0x0800 mask 0xFFFF : Heflin;
      0x6086dd mask 0xF0FFFF : Yemassee;
      0x86dd mask 0xFFFF : Luning;
      default: ingress;
   }
}
parser Emblem {
   extract( Hobson );
   set_metadata( Crumstown.Handley, Hobson.Findlay );
   set_metadata( Crumstown.Mogadore, Hobson.Lansdowne );
   set_metadata( Crumstown.Monico, Hobson.Suamico );
   return select( current( 0, 8 ), Hobson.Suamico ) {
      0x0806 mask 0xFFFF : Mahopac;
      0x450800 : Ryderwood;
      0x50800 mask 0xFFFFF : BigPiney;
      0x0800 mask 0xFFFF : Heflin;
      default: ingress;
   }
}
@pragma pa_overlay_stage_separation ingress ig_intr_md_for_tm.qid 1
@pragma pa_container_size ingress ig_intr_md_for_tm.qid 8
@pragma pa_container_size ingress Tecumseh.Wellsboro 32
@pragma pa_container_size ingress Beltrami.Sheldahl 16
@pragma pa_container_size ingress Beltrami.Mayday 16
@pragma pa_container_size ingress Beltrami.Moneta 16
@pragma pa_container_size ingress Crumstown.Amory 16
@pragma pa_container_size ingress WebbCity.Wallula 16
@pragma pa_no_init ingress Crumstown.Handley
@pragma pa_no_init ingress Crumstown.Mogadore
@pragma pa_no_init ingress Crumstown.Mackville
@pragma pa_no_init ingress Crumstown.Pineland
@pragma pa_container_size ingress Crumstown.Lamine 8
@pragma pa_container_size ingress Crumstown.Abilene 8
@pragma pa_no_init ingress Crumstown.DelRey
@pragma pa_container_size ingress Crumstown.Camden 8
metadata Ahuimanu Crumstown;
@pragma pa_allowed_to_share egress WebbCity.Creston Brodnax.Algoa
@pragma pa_container_size ingress WebbCity.Chubbuck 32
@pragma pa_container_size ingress WebbCity.Crossnore 32
@pragma pa_container_size ingress Crumstown.DesPeres 32
@pragma pa_no_init ingress WebbCity.Gause
@pragma pa_no_init ingress WebbCity.Stowe
@pragma pa_container_size ingress WebbCity.Ivanpah 32
@pragma pa_no_overlay ingress WebbCity.Wallula
@pragma pa_solitary ingress WebbCity.Wallula
metadata Folcroft WebbCity;
metadata Honobia Palmer;
metadata Enfield Brodnax;
@pragma pa_container ingress Ashville.Bonney 141
metadata Angwin Mendon;
metadata Wynnewood Loysburg;
@pragma pa_container_size ingress Lindsborg.Arion 16
@pragma pa_container_size ingress Lindsborg.LakePine 16
@pragma pa_container_size ingress Mendon.Tunica 16
@pragma pa_container_size ingress WebbCity.Snowball 8
@pragma pa_container_size ingress LaMoille.Lilbert 16
metadata Bowen LaMoille;
@pragma pa_container_size ingress Waterflow.Valeene 16
metadata Dresser Waterflow;
@pragma pa_mutually_exclusive ingress LaMoille.Anacortes Waterflow.Alcoma
@pragma pa_mutually_exclusive ingress LaMoille.BigArm Waterflow.Squire
@pragma pa_mutually_exclusive ingress LaMoille.Pachuta Waterflow.ElPrado
@pragma pa_alias ingress LaMoille.Lilbert Waterflow.Valeene
@pragma pa_alias ingress Lindsborg.Verdery Lindsborg.Arion
metadata Frederika Madison;
@pragma pa_container_size egress Brunson.DuBois 8
metadata Faysville Brunson;
@pragma pa_container_size ingress Uniontown.Deloit 8
@pragma pa_container_size ingress Uniontown.Basalt 8
metadata Copley Uniontown;
metadata Montello Parkline;
metadata PineLake Lindsborg;
@pragma pa_no_init ingress Crozet.Raeford
@pragma pa_no_init ingress Crozet.Ochoa
@pragma pa_no_init ingress Freeville.Utuado
@pragma pa_no_init ingress Freeville.Accomac
@pragma pa_no_init ingress Freeville.Blairsden
@pragma pa_no_init ingress Freeville.Grigston
@pragma pa_no_init ingress Freeville.Clementon
@pragma pa_no_init ingress Freeville.Manakin
@pragma pa_container_size ingress Crozet.Raeford 16
@pragma pa_mutually_exclusive ingress Crozet.Raeford Crozet.Ochoa
metadata Greendale Crozet;
metadata Laramie Freeville;
metadata Kenvil Beltrami;
metadata Oakes Santos;
@pragma pa_no_init ingress Jesup.Amesville
@pragma pa_solitary ingress Jesup.Nutria
metadata Milano Jesup;
@pragma pa_container_size egress WebbCity.Catarina 32
@pragma pa_alias egress WebbCity.Catarina WebbCity.Realitos
@pragma pa_no_init egress WebbCity.Mendota
@pragma pa_no_init egress WebbCity.Catarina
@pragma pa_container_size ingress Armijo.Eunice 8
@pragma pa_no_init ingress Armijo.Twinsburg
metadata Roswell Armijo;
@pragma pa_no_init ingress Nightmute.Rienzi
@pragma pa_no_init ingress Nightmute.Monida
metadata Jenifer Nightmute;
metadata Jenifer Hickox;
metadata Cutler Hatchel;
metadata Virgin Lamona;
metadata Sanchez Huffman;
action Fleetwood() {
   no_op();
}
action Allyn() {
   modify_field( Crumstown.Delavan, 1 );
}
action Skime() {
   no_op();
}
@pragma pa_container_size ingress Mendon.Tunica 16
@pragma pa_container_size ingress Mendon.Moark 16
action Yscloskey(Chatfield, Meservey, Deport, Nooksack ) {
   modify_field(Mendon.Tunica, Chatfield);
   modify_field(Mendon.Moark, Meservey);
   modify_field(Mendon.Rixford, Deport);
   modify_field(Mendon.Rardin, Nooksack);
}
@pragma phase0 1
table Silesia {
   reads {
      ig_intr_md.ingress_port : exact;
   }
   actions {
      Yscloskey;
   }
   default_action : Yscloskey(0,0,0,0);
   size : 288;
}
control Ovett {
   if (ig_intr_md.resubmit_flag == 0) {
      apply(Silesia);
   }
}
action Shasta(Maryhill, Shirley) {
   modify_field( WebbCity.Snowball, 1 );
   modify_field( WebbCity.Trotwood, Maryhill);
   modify_field( Crumstown.Lamine, 1 );
   modify_field( Beltrami.Carlson, Shirley );
   modify_field( Crumstown.Kulpmont, 1 );
}
action McDavid(Valmont, Ipava) {
   modify_field( WebbCity.Trotwood, Valmont);
   modify_field( Crumstown.Lamine, 1 );
   modify_field( Beltrami.Carlson, Ipava );
}
action Grassy() {
   modify_field( Crumstown.Asher, 1 );
   modify_field( Crumstown.Pringle, 1 );
}
action Penzance() {
   modify_field( Crumstown.Lamine, 1 );
}
action Quealy() {
   modify_field( Crumstown.Lamine, 1 );
   modify_field( Crumstown.Newfane, 1 );
}
action Farson() {
   modify_field( Crumstown.Abilene, 1 );
}
action Azalia() {
   modify_field( Crumstown.Pringle, 1 );
}
counter Jacobs {
   type : packets_and_bytes;
   direct : Grinnell;
   min_width: 16;
}
@pragma immediate 0
table Grinnell {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Escondido.Findlay : ternary;
      Escondido.Lansdowne : ternary;
   }
   actions {
      Shasta;
      Grassy;
      Penzance;
      Farson;
      Azalia;
      Quealy;
      McDavid;
   }
   default_action: Fleetwood();
   size : 1656;
}
action Boistfort() {
   modify_field( Crumstown.Baudette, 1 );
}
table Navarro {
   reads {
      Escondido.Sherwin : ternary;
      Escondido.Goldenrod : ternary;
   }
   actions {
      Boistfort;
   }
   size : 512;
}
control RedElm {
   apply( Grinnell ) {
      Shasta { }
      default {
         Sabula();
      }
   }
   apply( Navarro );
}
action Goldsmith() {
   modify_field( WebbCity.Edgemoor, 5 );
   modify_field( Crumstown.Handley, Escondido.Findlay );
   modify_field( Crumstown.Mogadore, Escondido.Lansdowne );
   modify_field( Crumstown.Mackville, Escondido.Sherwin );
   modify_field( Crumstown.Pineland, Escondido.Goldenrod );
   modify_field( Crumstown.Ramapo, Loysburg.Alameda );
   modify_field( Crumstown.DelRey, Loysburg.Lilydale, 0x7 );
   modify_field( Crumstown.Arredondo, Loysburg.Dixmont );
   modify_field( Nightmute.MudLake, Crumstown.Verdemont );
   modify_field( Crumstown.Denhoff, Loysburg.Salamatof );
   modify_field( Nightmute.Clearco, Loysburg.Salamatof, 1);
   modify_field( Crumstown.Verdemont, Nowlin.Arvana );
   modify_field( Crumstown.Hansell, Nowlin.Dagsboro );
}
action LasVegas() {
   modify_field( Beltrami.Mayday, Benkelman.Carroll );
   modify_field( Crumstown.Gibbstown, Benkelman.valid );
   modify_field( Crumstown.Golden, 0 );
   modify_field( Crumstown.Handley, Escondido.Findlay );
   modify_field( Crumstown.Mogadore, Escondido.Lansdowne );
   modify_field( Crumstown.Mackville, Escondido.Sherwin );
   modify_field( Crumstown.Pineland, Escondido.Goldenrod );
   modify_field( Crumstown.DelRey, Loysburg.Bartolo, 0x7 );
   modify_field( Crumstown.Monico, Escondido.Suamico );
}
action Pawtucket() {
   modify_field( Nightmute.MudLake, Elmsford.Arvana );
   modify_field( Crumstown.Verdemont, Elmsford.Arvana );
   modify_field( Crumstown.Hansell, Elmsford.Dagsboro );
   modify_field( Crumstown.Godley, Shelbiana.Goodrich );
   modify_field( Crumstown.Denhoff, Loysburg.Tonasket );
   modify_field( Nightmute.Clearco, Loysburg.Tonasket, 1);
   modify_field( Crumstown.Cankton, Elmsford.Arvana );
   modify_field( Crumstown.Glynn, Elmsford.Dagsboro );
}
action Horsehead() {
   LasVegas();
   modify_field( Waterflow.Alcoma, Radcliffe.Carnation );
   modify_field( Waterflow.Squire, Radcliffe.Vantage );
   modify_field( Waterflow.ElPrado, Radcliffe.Shubert );
   modify_field( Crumstown.Ramapo, Radcliffe.Loveland );
   Pawtucket();
}
action Kaeleku() {
   LasVegas();
   modify_field( LaMoille.Anacortes, McFaddin.Elmhurst );
   modify_field( LaMoille.BigArm, McFaddin.Waseca );
   modify_field( LaMoille.Pachuta, McFaddin.Fittstown );
   modify_field( Crumstown.Ramapo, McFaddin.Terry );
   Pawtucket();
}
@pragma use_container_valid Radcliffe.valid Radcliffe.Vantage
@pragma action_default_only Kaeleku
table Shelby {
   reads {
      Escondido.Findlay : ternary;
      Escondido.Lansdowne : ternary;
      McFaddin.Waseca : ternary;
      Radcliffe.Vantage : ternary;
      Crumstown.Golden : ternary;
      Radcliffe.valid : exact;
   }
   actions {
      Goldsmith;
      Horsehead;
   }
   default_action : Kaeleku();
   size : 512;
}
action Lasker(Cowen) {
   modify_field( Crumstown.Amory, Mendon.Moark );
   modify_field( Crumstown.Bodcaw, Cowen);
}
action Otsego( Tuckerton, Igloo ) {
   modify_field( Crumstown.Amory, Tuckerton );
   modify_field( Crumstown.Bodcaw, Igloo);
   modify_field( Mendon.Rixford, 1 );
}
action Sawpit(Randall) {
   modify_field( Crumstown.Amory, Benkelman.Triplett );
   modify_field( Crumstown.Bodcaw, Randall);
}
@pragma use_container_valid Benkelman.valid Benkelman.Triplett
table Aptos {
   reads {
      Mendon.Rixford : exact;
      Mendon.Tunica : exact;
      Benkelman : valid;
      Benkelman.Triplett : ternary;
   }
   actions {
      Lasker;
      Otsego;
      Sawpit;
   }
   size : 3072;
}
action Upland( Wataga ) {
   modify_field( Crumstown.Bodcaw, Wataga );
}
action Wewela() {
   modify_field( Parkline.Iredell,
                 3 );
}
action Lefors() {
   modify_field( Parkline.Iredell,
                 1 );
}
@pragma immediate 0
table Hargis {
   reads {
      McFaddin.Elmhurst : exact;
   }
   actions {
      Upland;
      Wewela;
      Lefors;
   }
   default_action : Wewela;
   size : 4096;
}
@pragma immediate 0
table Rhinebeck {
   reads {
      Radcliffe.Carnation : exact;
   }
   actions {
      Upland;
      Wewela;
      Lefors;
   }
   default_action : Wewela;
   size : 4096;
}
action Higgins( Norland, Speed, Onarga, Hampton ) {
   modify_field( Crumstown.Amory, Norland );
   modify_field( Crumstown.Woodfield, Norland );
   Rugby( Speed, Onarga, Hampton );
}
action Lantana() {
   modify_field( Crumstown.Hillcrest, 1 );
}
@pragma immediate 0
table Cavalier {
   reads {
      Hookdale.Bunavista : exact;
   }
   actions {
      Higgins;
      Lantana;
   }
   size : 4096;
}
action Rugby(Palmdale, OreCity, Lamboglia) {
   modify_field( Uniontown.Deloit, OreCity );
   modify_field( LaMoille.Leicester, Palmdale );
   modify_field( Uniontown.Wetumpka, Lamboglia );
}
action Netcong( LaFayette ) {
   modify_field( Crumstown.Woodsboro, LaFayette );
}
action FourTown(Lampasas, Buckholts, Norbeck, Kohrville) {
   modify_field( Crumstown.Woodfield, Mendon.Moark );
   Netcong( Kohrville );
   Rugby( Lampasas, Buckholts, Norbeck );
}
action DeLancey(Madill, KingCity, Fireco, Enderlin, Niota) {
   modify_field( Crumstown.Woodfield, Madill );
   Netcong( Niota );
   Rugby( KingCity, Fireco, Enderlin );
}
action Suffern(Jelloway, EastDuke, Nellie, Isabela) {
   modify_field( Crumstown.Woodfield, Benkelman.Triplett );
   Netcong( Isabela );
   Rugby( Jelloway, EastDuke, Nellie );
}
table Trammel {
   reads {
      Mendon.Moark : exact;
   }
   actions {
      FourTown;
   }
   size : 4096;
}
@pragma action_default_only Fleetwood
table Antoine {
   reads {
      Mendon.Tunica : exact;
      Benkelman.Triplett : exact;
   }
   actions {
      DeLancey;
      Fleetwood;
   }
   size : 1024;
}
@pragma immediate 0
table Newpoint {
   reads {
      Benkelman.Triplett : exact;
   }
   actions {
      Suffern;
   }
   size : 4096;
}
control Parnell {
   apply( Shelby ) {
      default {
         apply( Aptos );
         if ( valid( Benkelman ) and Benkelman.Triplett != 0 ) {
            apply( Antoine ) {
               Fleetwood {
                  apply( Newpoint );
               }
            }
         } else {
            apply( Trammel );
         }
      }
   }
}
action Osakis( Hurdtown ) {
   modify_field( Crumstown.Sheyenne, Hurdtown );
}
action Pearland() {
   modify_field( Crumstown.Sheyenne, 0 );
}
table Parthenon {
   reads {
      LaMoille.Anacortes : ternary;
      Crumstown.Ramapo : ternary;
   }
   actions {
      Osakis;
      Pearland;
   }
   default_action : Pearland();
   size : 2048;
}
action Timken( Shauck, Laplace ) {
   modify_field( LaMoille.BigArm, Shauck );
   modify_field( Crumstown.Palouse, Laplace );
   modify_field( Crumstown.Immokalee, 1 );
}
action Hahira( Molson, Natalbany, Stonebank ) {
   Timken( Molson, Natalbany );
   modify_field( Lindsborg.LakePine, 0 );
   modify_field( Lindsborg.Arion, Stonebank );
}
action Charlack( Westwood, Macon, Argentine ) {
   Timken( Westwood, Macon );
   modify_field( Lindsborg.LakePine, 1 );
   modify_field( Lindsborg.Verdery, Argentine );
}
action Iroquois( Clinchco, Gambrill, Surrey, Lambrook ) {
   modify_field( Crumstown.Glynn, Gambrill );
   Hahira( Clinchco, Surrey, Lambrook );
}
action Grizzly( Caballo, Sneads, Kaaawa,
       Guaynabo ) {
   modify_field( Crumstown.Glynn, Sneads );
   Charlack( Caballo, Kaaawa, Guaynabo );
}
table Segundo {
   reads {
      Crumstown.Sheyenne : exact;
      LaMoille.BigArm : exact;
      Crumstown.Woodsboro : exact;
      Nightmute.Clearco : exact;
   }
   actions {
      Hahira;
      Charlack;
      Fleetwood;
   }
   default_action : Fleetwood();
   size : 4096;
}
table Ossipee {
   reads {
      Crumstown.Sheyenne : exact;
      LaMoille.BigArm : exact;
      Elmsford.Dagsboro : exact;
      Crumstown.Woodsboro : exact;
   }
   actions {
      Hahira;
      Iroquois;
      Charlack;
      Grizzly;
      Fleetwood;
   }
   default_action : Fleetwood();
   size : 4096;
}
action Pelican( Sully ) {
   modify_field( Crumstown.Hackamore, Sully );
}
action Ridgeview() {
   modify_field( Crumstown.Hackamore, 0 );
}
table Iraan {
   reads {
      LaMoille.BigArm : ternary;
      Crumstown.Ramapo : ternary;
   }
   actions {
      Pelican;
      Ridgeview;
   }
   default_action : Ridgeview();
   size : 2048;
}
action Casco( Dunken, CapRock ) {
   modify_field( LaMoille.Anacortes, Dunken );
   modify_field( Crumstown.Wanamassa, CapRock );
   modify_field( Crumstown.Moorpark, 1 );
}
action Schroeder( Lakehurst, Aniak, Escatawpa ) {
   modify_field( Crumstown.Cankton, Aniak );
   Casco( Lakehurst, Escatawpa );
}
table Mesita {
   reads {
      Crumstown.Hackamore : exact;
      LaMoille.Anacortes : exact;
      Crumstown.Claiborne : exact;
      Nightmute.Clearco : exact;
   }
   actions {
      Casco;
      Fleetwood;
   }
   default_action : Fleetwood();
   size : 4096;
}
table Lecompte {
   reads {
      Crumstown.Hackamore : exact;
      LaMoille.Anacortes : exact;
      Elmsford.Arvana : exact;
      Crumstown.Claiborne : exact;
   }
   actions {
      Casco;
      Schroeder;
      Fleetwood;
   }
   default_action : Fleetwood();
   size : 4096;
}
@pragma pa_no_init ingress Crumstown.Claiborne
action Lewellen( Mabel ) {
   modify_field(Crumstown.Claiborne, Mabel );
}
table Farthing {
  reads {
     WebbCity.Wallula : exact;
  }
  actions {
     Lewellen;
  }
  default_action : Lewellen( 0 );
  size : 4096;
}
action Amite() {
   modify_field( Crumstown.Alderson, 1 );
}
action Lazear( Swedeborg, Thurmond, Stockdale ) {
   Hahira( Swedeborg, Thurmond, Stockdale );
   Amite();
}
action Medart( Pacifica, Jenison, Reading ) {
   Charlack( Pacifica, Jenison, Reading );
   Amite();
}
action Burien( Wayland, Tekonsha, Fallis,
                                                    Mattson ) {
   Iroquois( Wayland, Tekonsha, Fallis, Mattson );
   Amite();
}
action Bosco( Arbyrd, Hopedale, Waupaca,
                                                        Hewitt ) {
   Grizzly( Arbyrd, Hopedale, Waupaca, Hewitt );
   Amite();
}
action Challis( Yorkshire, Northlake ) {
   Casco( Yorkshire, Northlake );
   Amite();
}
action Laurelton( Varnado, Mustang, Sutter ) {
   Schroeder( Varnado, Mustang, Sutter );
   Amite();
}
@pragma idletime_precision 1
table Windber {
   reads {
      Crumstown.Ramapo : exact;
      LaMoille.Anacortes : exact;
      Elmsford.Arvana : exact;
      LaMoille.BigArm : exact;
      Elmsford.Dagsboro : exact;
   }
   actions {
      Lazear;
      Burien;
      Medart;
      Bosco;
      Challis;
      Laurelton;
      Fleetwood;
   }
   default_action : Fleetwood();
   size : 97280;
   support_timeout : true;
}
@pragma stage 4 47104
@pragma idletime_precision 1
table Dante {
   reads {
      Crumstown.Ramapo : exact;
      LaMoille.Anacortes : exact;
      Elmsford.Arvana : exact;
      LaMoille.BigArm : exact;
      Elmsford.Dagsboro : exact;
   }
   actions {
      Lazear;
      Burien;
      Medart;
      Bosco;
      Fleetwood;
   }
   default_action : Fleetwood();
   size : 79872;
   support_timeout : true;
}
@pragma idletime_precision 1
table Gurley {
   reads {
      Crumstown.Ramapo : exact;
      LaMoille.Anacortes : exact;
      Elmsford.Arvana : exact;
      LaMoille.BigArm : exact;
      Elmsford.Dagsboro : exact;
   }
   actions {
      Challis;
      Laurelton;
      Fleetwood;
   }
   default_action : Fleetwood();
   size : 67584;
   support_timeout : true;
}
@pragma idletime_precision 1
table Opelika {
   reads {
      Crumstown.Ramapo : exact;
      LaMoille.Anacortes : exact;
      Elmsford.Arvana : exact;
      LaMoille.BigArm : exact;
      Elmsford.Dagsboro : exact;
   }
   actions {
      Challis;
      Laurelton;
      Fleetwood;
   }
   default_action : Fleetwood();
   size : 32768;
   support_timeout : true;
}
control Amboy {
   if ( Crumstown.Delavan == 0 and
        Uniontown.Basalt == 1 and
        Mendon.Rardin != 0 and
        Madison.Poulan == 0 and
        Madison.Basco == 0 ) {
      if ( ( ( Uniontown.Wetumpka & ( 0x1 ) ) == ( ( 0x1 ) ) ) and
           Crumstown.DelRey == 0x1 ) {
         if ( Crumstown.Moorpark == 0 and Crumstown.Immokalee == 0 ) {
            apply( Gurley ) {
               Fleetwood {
                  apply( Iraan );
               }
            }
         }
      }
   }
}
control Metzger {
   if ( Crumstown.Delavan == 0 and
        Uniontown.Basalt == 1 and
        Mendon.Rardin != 0 and
        ( ( Uniontown.Wetumpka & ( 0x1 ) ) == ( ( 0x1 ) ) ) and
        Crumstown.DelRey == 0x1 and
        Crumstown.Moorpark == 0 and Crumstown.Immokalee == 0 ) {
      apply( Opelika ) {
         Fleetwood {
            apply( Farthing );
         }
      }
   }
}
control Stilson {
   if ( Crumstown.Delavan == 0 and
        Uniontown.Basalt == 1 and
        Mendon.Rardin != 0 and
        ( ( Uniontown.Wetumpka & ( 0x1 ) ) == ( ( 0x1 ) ) ) and
        Crumstown.DelRey == 0x1 and
        ig_intr_md_for_tm.copy_to_cpu == 0 ) {
      apply( Lecompte ) {
         Fleetwood {
            apply( Mesita ) {
               miss {
                  if ( Madison.Poulan == 0 and
                       Madison.Basco == 0 ) {
                     apply(Kenbridge);
                  }
               }
            }
         }
      }
   }
}
action Lajitas() {
   modify_field( Crumstown.Rockville, 1 );
}
table Cuthbert {
   actions {
      Lajitas;
   }
   default_action : Lajitas();
   size : 1;
}
control Kenmore {
   if( Nightmute.Clearco != 0 or McFaddin.Temple != 0 ) {
      apply( Cuthbert );
   }
}
action Townville(Captiva) {
   modify_field(WebbCity.Snowball, 1);
   modify_field(WebbCity.Trotwood, Captiva);
   modify_field(WebbCity.Chubbuck, 511);
}
table Kenbridge {
   reads {
      Crumstown.Woodsboro : ternary;
      Crumstown.Claiborne : ternary;
      LaMoille.Anacortes : ternary;
      LaMoille.BigArm : ternary;
      Crumstown.Rockville : ternary;
      Crumstown.Alderson : ternary;
      Shelbiana.valid : ternary;
      Shelbiana.Goodrich : ternary;
   }
   actions {
      Townville;
      Fleetwood;
   }
   size : 1024;
}
action StarLake() {
   bit_not( Boysen.Ambrose, Boysen.Ambrose );
}
action Maupin() {
   bit_not( Boysen.Ambrose, Boysen.Ambrose );
   modify_field( Crumstown.Wanamassa, 0 );
   modify_field( Crumstown.Palouse, 0 );
}
action Ionia() {
   bit_not( Boysen.Ambrose, 0 );
   modify_field( Crumstown.Wanamassa, 0 );
   modify_field( Crumstown.Palouse, 0 );
}
action Nashua() {
   modify_field( McFaddin.Waseca, LaMoille.BigArm );
}
action Samantha() {
   StarLake();
   Nashua();
   modify_field( Crumstown.Wanamassa, 0 );
   modify_field( Elmsford.Dagsboro, Crumstown.Glynn );
}
action SweetAir() {
   Nashua();
   Ionia();
   modify_field( Elmsford.Dagsboro, Crumstown.Glynn );
}
action Jonesport() {
   Nashua();
   modify_field( McFaddin.Elmhurst, LaMoille.Anacortes );
}
action Negra() {
   StarLake();
   Jonesport();
   modify_field( Elmsford.Arvana, Crumstown.Cankton );
}
action Adair() {
   Jonesport();
   Ionia();
   modify_field( Elmsford.Arvana, Crumstown.Cankton );
}
table Foristell {
   reads {
      WebbCity.Trotwood : ternary;
      Crumstown.Immokalee : ternary;
      Crumstown.Moorpark : ternary;
      McFaddin.valid : ternary;
      Boysen.valid : ternary;
      Skiatook.valid : ternary;
      Boysen.Ambrose : ternary;
      WebbCity.Edgemoor : ternary;
   }
   actions {
      Skime;
      Jonesport;
      Negra;
      Adair;
      Nashua;
      Samantha;
      SweetAir;
      Maupin;
   }
   size : 16;
}
control ShadeGap {
   apply( Foristell );
}
action Equality( Fallsburg ) {
   modify_field( Lindsborg.LakePine, 0 );
   modify_field( Lindsborg.Arion, Fallsburg );
}
action Claunch( Hindman ) {
   modify_field( Lindsborg.LakePine, 2 );
   modify_field( Lindsborg.Arion, Hindman );
}
action Balmorhea( Pumphrey ) {
   modify_field( Lindsborg.LakePine, 3 );
   modify_field( Lindsborg.Arion, Pumphrey );
}
action Garrison( Lowemont, Freetown ) {
   modify_field( Lindsborg.LakePine, 0 );
   modify_field( Lindsborg.Arion, Freetown );
}
action McCracken( Helotes ) {
   modify_field( Lindsborg.Verdery, Helotes );
   modify_field( Lindsborg.LakePine, 1 );
}
action Montegut() {
}
action Bowden() {
   Equality( 1 );
}
@pragma idletime_precision 1
@pragma force_immediate 1
@pragma action_default_only Bowden
table McBride {
   reads {
      Uniontown.Deloit : exact;
      LaMoille.BigArm mask 0xFFFFFFFF : lpm;
   }
   actions {
      Equality;
      Claunch;
      Balmorhea;
      McCracken;
   }
   default_action : Bowden();
   size : 8192;
   support_timeout : true;
}
action Gardiner() {
   Equality( 1 );
}
@pragma action_default_only Gardiner
@pragma idletime_precision 1
table Cullen {
   reads {
      Uniontown.Deloit : exact;
      Waterflow.Squire mask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF: lpm;
   }
   actions {
      Equality;
      Claunch;
      Balmorhea;
      McCracken;
      Gardiner;
   }
   size : 4096;
   support_timeout : true;
}
action Nathan(Qulin) {
   Equality( Qulin );
}
table Leona {
   reads {
      Uniontown.Wetumpka mask 0x1 : exact;
      Crumstown.DelRey : exact;
   }
   actions {
      Nathan;
   }
   default_action: Nathan;
   size : 2;
}
control Menfro {
   if ( Crumstown.Delavan == 0 and
        Uniontown.Basalt == 1 and
        Mendon.Rardin != 0 and
        Madison.Poulan == 0 and
        Madison.Basco == 0 ) {
      if ( ( ( Uniontown.Wetumpka & ( 0x2 ) ) == ( ( 0x2 ) ) ) and Crumstown.DelRey == 0x2 ) {
         apply( Cullen );
      } else if ( ( ( Uniontown.Wetumpka & ( 0x1 ) ) == ( ( 0x1 ) ) ) and
                  Crumstown.DelRey == 0x1 ) {
         apply( Windber ) {
            Fleetwood {
               apply( Parthenon );
            }
         }
      } else if ( WebbCity.Snowball == 0 and
                ( Crumstown.Petrey == 1 or
                  ( ( ( Uniontown.Wetumpka & ( 0x1 ) ) == ( ( 0x1 ) ) ) and
                    Crumstown.DelRey == 0x3 ) ) ) {
         apply( Leona );
      }
   }
}
control Berlin {
   if ( Crumstown.Delavan == 0 and
        Uniontown.Basalt == 1 and
        Mendon.Rardin != 0 and
        Madison.Poulan == 0 and
        Madison.Basco == 0 ) {
      if ( ( ( Uniontown.Wetumpka & ( 0x1 ) ) == ( ( 0x1 ) ) ) and
           Crumstown.DelRey == 0x1 ) {
         if ( Lindsborg.Arion == 0 ) {
            apply( Dante ) {
               Fleetwood {
                  apply( Ossipee ) {
                     Fleetwood {
                        apply( Segundo ) {
                           Fleetwood {
                              apply( McBride );
                           }
                        }
                     }
                  }
               }
            }
         }
      }
   }
}
field_list Taopi {
   Crozet.Ochoa;
   ig_intr_md.ingress_port;
}
field_list_calculation Hartville {
   input {
      Taopi;
   }
   algorithm : crc16_extend;
   output_width : 66;
}
action_selector Keenes {
   selection_key : Hartville;
   selection_mode : resilient;
}
action_profile Epsie {
   actions {
      Garrison;
   }
   size : 16384;
   dynamic_action_selection : Keenes;
}
@pragma selector_max_group_size 256
@pragma immediate 0
table Guaynabo {
   reads {
      Lindsborg.Verdery mask 0xff: exact;
   }
   action_profile : Epsie;
   size : 256;
}
action Wolsey() {
   modify_field( Crumstown.BigRun, Crumstown.Strevell );
}
table Poteet {
   actions {
      Wolsey;
   }
   default_action : Wolsey();
   size : 1;
}
action Willey(Toulon) {
   modify_field(WebbCity.Snowball, 1);
   modify_field(WebbCity.Trotwood, Toulon);
}
table Raytown {
   reads {
      Lindsborg.Arion mask 0xF: exact;
   }
   actions {
      Willey;
   }
   size : 16;
}
action Quinnesec(Wyarno, AquaPark, Yorklyn) {
   modify_field(WebbCity.Gause, Wyarno);
   modify_field(WebbCity.Stowe, AquaPark);
   modify_field(WebbCity.Wallula, Yorklyn);
}
@pragma use_hash_action 1
table Villanova {
   reads {
      Lindsborg.Arion mask 0x3FFF : exact;
   }
   actions {
      Quinnesec;
   }
   default_action : Quinnesec(0,0,0);
   size : 16384;
}
action Gerlach(Weskan, Angeles, Topanga) {
   modify_field(WebbCity.Cassadaga, 1);
   modify_field(WebbCity.Chubbuck, Weskan);
   modify_field(WebbCity.Crossnore, Angeles);
   modify_field(Crumstown.DesPeres, Topanga);
}
@pragma use_hash_action 1
table Simnasho {
   reads {
      Lindsborg.Arion mask 0xFFFF : exact;
   }
   actions {
      Gerlach;
   }
   default_action : Gerlach(511,0,0);
   size : 16384;
}
control Grandy {
   if ( Mendon.Rardin != 0 and Lindsborg.LakePine == 1 ) {
      apply( Guaynabo );
   }
}
control Buckhorn {
   if( Lindsborg.Arion != 0 ) {
      apply( Poteet );
      if( ( ( Lindsborg.Arion & 0xFFF0 ) == 0 ) ) {
         apply( Raytown );
      } else {
         apply( Simnasho );
         apply( Villanova );
      }
   }
}
action Barclay( Paisley ) {
   modify_field( Crumstown.Quarry, Paisley );
}
action Biggers() {
   modify_field( Crumstown.Pittsboro, 1 );
}
table Tonkawa {
   reads {
      Crumstown.DelRey : exact;
      Crumstown.Golden : exact;
      McFaddin.valid : exact;
      McFaddin.Nisland mask 0x3FFF: ternary;
      Radcliffe.Spenard mask 0x3FFF: ternary;
   }
   actions {
      Barclay;
      Biggers;
   }
   default_action : Biggers();
   size : 512;
}
control Sunset {
   apply( Tonkawa );
}
action Kinston( Trilby ) {
   modify_field( WebbCity.Snowball, 1 );
   modify_field( WebbCity.Trotwood, Trilby );
}
action Tamms() {
}
table Winside {
   reads {
      Crumstown.Pittsboro : ternary;
      Crumstown.Quarry : ternary;
      Crumstown.DesPeres : ternary;
      WebbCity.Cassadaga : exact;
      WebbCity.Chubbuck mask 0x80000 : ternary;
   }
   actions {
      Kinston;
      Tamms;
   }
   default_action : Tamms;
   size : 512;
}
control Schleswig {
   apply( Winside ) {
      Tamms {
         Stilson();
      }
   }
}
register Richvale {
   width : 1;
   static : Exeter;
   instance_count : 294912;
}
register Ekron {
   width : 1;
   static : Cricket;
   instance_count : 294912;
}
blackbox stateful_alu LeMars {
   reg : Richvale;
   update_lo_1_value: read_bitc;
   output_value : alu_lo;
   output_dst : Madison.Poulan;
}
blackbox stateful_alu Cantwell {
   reg : Ekron;
   update_lo_1_value: read_bit;
   output_value : alu_lo;
   output_dst : Madison.Basco;
}
field_list Daisytown {
   ig_intr_md.ingress_port;
   Benkelman.Triplett;
}
field_list_calculation Neavitt {
   input { Daisytown; }
   algorithm: identity;
   output_width: 19;
}
action ViewPark() {
   LeMars.execute_stateful_alu_from_hash(Neavitt);
}
action LaPointe() {
   Cantwell.execute_stateful_alu_from_hash(Neavitt);
}
table Exeter {
   actions {
      ViewPark;
   }
   default_action : ViewPark;
   size : 1;
}
table Cricket {
   actions {
      LaPointe;
   }
   default_action : LaPointe;
   size : 1;
}
control Sabula {
   if ( valid( Benkelman ) and Benkelman.Triplett != 0
        and Mendon.Rixford == 1 ) {
      apply( Exeter );
   }
   apply( Cricket );
}
register Amazonia {
   width : 1;
   static : Cornudas;
   instance_count : 294912;
}
register Bellville {
   width : 1;
   static : Pardee;
   instance_count : 294912;
}
blackbox stateful_alu Candle {
   reg : Amazonia;
   update_lo_1_value: read_bitc;
   output_value : alu_lo;
   output_dst : Brunson.Cedar;
}
blackbox stateful_alu Ketchum {
   reg : Bellville;
   update_lo_1_value: read_bit;
   output_value : alu_lo;
   output_dst : Brunson.DuBois;
}
field_list Franklin {
   eg_intr_md.egress_port;
   WebbCity.Miranda;
}
field_list_calculation Vanoss {
   input { Franklin; }
   algorithm: identity;
   output_width: 19;
}
action McDonough() {
   Candle.execute_stateful_alu_from_hash(Vanoss);
}
table Cornudas {
   actions {
      McDonough;
   }
   default_action : McDonough;
   size : 1;
}
action Halliday() {
    Ketchum.execute_stateful_alu_from_hash(Vanoss);
}
table Pardee {
   actions {
      Halliday;
   }
   default_action : Halliday;
   size : 1;
}
control Grasmere {
   apply( Cornudas );
   apply( Pardee );
}
field_list Weiser {
   Escondido.Findlay;
   Escondido.Lansdowne;
   Escondido.Sherwin;
   Escondido.Goldenrod;
   Crumstown.Monico;
}
field_list Hilgard {
   Hobson.Findlay;
   Hobson.Lansdowne;
   Hobson.Sherwin;
   Hobson.Goldenrod;
   Hobson.Suamico;
}
field_list Houston {
   McFaddin.Terry;
   McFaddin.Elmhurst;
   McFaddin.Waseca;
}
field_list BoxElder {
   LaMoille.Anacortes;
   LaMoille.BigArm;
   Loysburg.Alameda;
}
field_list Eldena {
   Waterflow.Alcoma;
   Waterflow.Squire;
   4'0;
   Harriet.Clarks;
   Loysburg.Alameda;
}
field_list Cadwell {
   Radcliffe.Carnation;
   Radcliffe.Vantage;
   4'0;
   Radcliffe.Clarks;
   Radcliffe.Loveland;
}
field_list Glenside {
   Freeville.Accomac;
   Elmsford.Arvana;
   Elmsford.Dagsboro;
}
field_list Vanzant {
   Freeville.Clementon;
   Nowlin.Arvana;
   Nowlin.Dagsboro;
}
field_list_calculation Ferndale {
    input {
        Weiser;
    }
    algorithm : crc16;
   output_width : 16;
}
field_list_calculation Kingsland {
   input {
      Hilgard;
   }
   algorithm : crc16;
   output_width : 16;
}
field_list_calculation Cliffs {
   input {
      Houston;
   }
   algorithm : crc16;
   output_width : 16;
}
field_list_calculation Belwood {
   input {
      BoxElder;
   }
    algorithm : crc16;
   output_width : 16;
}
field_list_calculation Brookneal {
   input {
      Eldena;
   }
   algorithm : crc16;
   output_width : 16;
}
field_list_calculation Tillatoba {
   input {
      Cadwell;
   }
   algorithm : crc16;
   output_width : 16;
}
field_list_calculation Cochise {
   input {
      Glenside;
   }
   algorithm : crc16;
   output_width : 16;
}
field_list_calculation Monsey {
   input {
      Vanzant;
   }
   algorithm : crc16;
   output_width : 16;
}
action Malaga() {
   modify_field_with_hash_based_offset( Freeville.Utuado, 0,
                                        Ferndale, 65536 );
}
action Goldsboro() {
   modify_field_with_hash_based_offset( Freeville.Grigston, 0,
                                        Kingsland, 65536 );
}
action Leetsdale() {
   modify_field_with_hash_based_offset( Freeville.Accomac, 0,
                                        Cliffs, 65536 );
}
action Edwards() {
   modify_field_with_hash_based_offset( Freeville.Accomac, 0,
                                        Tillatoba, 65536 );
}
action Jigger() {
   modify_field_with_hash_based_offset( Freeville.Blairsden, 0,
                                        Cochise, 65536 );
}
action Urbanette() {
   modify_field_with_hash_based_offset( Freeville.Clementon, 0,
                                        Belwood, 65536 );
}
action Faulkner() {
   modify_field_with_hash_based_offset( Freeville.Clementon, 0,
                                        Brookneal, 65536 );
}
action Perrytown() {
   modify_field_with_hash_based_offset( Freeville.Manakin, 0,
                                        Monsey, 65536 );
}
@pragma ternary 1
@pragma stage 0
table Fairlea {
   reads {
      Macedonia.valid : exact;
      Harriet.valid : exact;
   }
   actions {
      Urbanette;
      Faulkner;
   }
   size : 2;
}
table Tunis {
   actions {
      Goldsboro;
   }
   default_action : Goldsboro();
   size: 1;
}
control Frederick {
   apply( Tunis );
}
table Tindall {
   actions {
      Leetsdale;
   }
   default_action : Leetsdale();
   size: 1;
}
table Muenster {
   actions {
      Edwards;
   }
   default_action : Edwards();
   size: 1;
}
control Pinetop {
   if ( valid( McFaddin ) ) {
      apply(Tindall);
   } else {
      apply( Muenster );
   }
}
action Sammamish() {
   Jigger();
   Perrytown();
}
table Ickesburg {
   actions {
      Sammamish;
   }
   default_action : Sammamish();
   size: 1;
}
control Robbins {
   apply( Ickesburg );
}
action Anita() {
   modify_field_with_hash_based_offset( Crozet.Raeford, 0,
                                        Ferndale, 65536 );
}
action Ivins() {
   modify_field(Crozet.Raeford, Freeville.Accomac);
}
action Hallowell() {
   modify_field(Crozet.Raeford, Freeville.Blairsden);
}
action Antelope() {
   modify_field( Crozet.Raeford, Freeville.Grigston );
}
action Siloam() {
   modify_field( Crozet.Raeford, Freeville.Clementon );
}
action Robert() {
   modify_field( Crozet.Raeford, Freeville.Manakin );
}
@pragma action_default_only Fleetwood
@pragma immediate 0
table Resaca {
   reads {
      Nowlin.valid : ternary;
      Macedonia.valid : ternary;
      Harriet.valid : ternary;
      Hobson.valid : ternary;
      Elmsford.valid : ternary;
      McFaddin.valid : ternary;
      Radcliffe.valid : ternary;
      Escondido.valid : ternary;
   }
   actions {
      Anita;
      Ivins;
      Hallowell;
      Antelope;
      Siloam;
      Robert;
      Fleetwood;
   }
   size: 256;
}
action Jeddo() {
   modify_field(Crozet.Ochoa, Freeville.Accomac);
}
action Barney() {
   modify_field( Crozet.Ochoa, Freeville.Clementon );
}
action Germano() {
   modify_field(Crozet.Ochoa, Freeville.Blairsden);
}
action Neubert() {
   modify_field( Crozet.Ochoa, Freeville.Manakin );
}
action Marbury() {
   modify_field( Crozet.Ochoa, Freeville.Grigston );
}
@pragma immediate 0
table Seibert {
   reads {
      Nowlin.valid : ternary;
      Macedonia.valid : ternary;
      Harriet.valid : ternary;
      Hobson.valid : ternary;
      Elmsford.valid : ternary;
      Radcliffe.valid : ternary;
      McFaddin.valid : ternary;
   }
   actions {
      Jeddo;
      Germano;
      Barney;
      Neubert;
      Marbury;
      Fleetwood;
   }
   size: 512;
}
counter Joplin {
   type : packets;
   direct : Mogote;
   min_width: 64;
}
table Mogote {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Crumstown.Hillcrest : ternary;
      Crumstown.Baudette : ternary;
      Crumstown.Asher : ternary;
      Loysburg.Bartolo mask 0x8 : ternary;
      ig_intr_md_from_parser_aux.ingress_parser_err mask 0x1000 : ternary;
   }
   actions {
      Allyn;
      Fleetwood;
   }
   default_action : Fleetwood();
   size : 512;
}
action WestPike() {
   modify_field( Crumstown.Lundell, 1 );
}
table Woodfords {
   reads {
      Crumstown.Mackville : exact;
      Crumstown.Pineland : exact;
      Crumstown.Amory : exact;
   }
   actions {
      WestPike;
      Fleetwood;
   }
   default_action : Fleetwood();
   size : 4096;
}
action Whitman() {
   modify_field(Parkline.Iredell,
                2);
}
table Veneta {
   reads {
      Crumstown.Mackville : exact;
      Crumstown.Pineland : exact;
      Crumstown.Amory : exact;
      Crumstown.Bodcaw : exact;
   }
   actions {
      Skime;
      Whitman;
   }
   default_action : Whitman();
   size : 8192;
   support_timeout : true;
}
action Lizella( Accord, Lawnside, Piedmont ) {
   modify_field( Crumstown.Camden, Accord );
   modify_field( Crumstown.Petrey, Lawnside );
   modify_field( Crumstown.Ashwood, Piedmont );
}
@pragma use_hash_action 1
table Coffman {
   reads {
      Crumstown.Amory mask 0xfff : exact;
   }
   actions {
      Lizella;
   }
   default_action : Lizella( 0, 0, 0 );
   size : 4096;
}
action WestEnd() {
   modify_field_with_shift( LaMoille.Leicester, LaMoille.BigArm, 1, 0x7FFFFFFF );
}
action Millett() {
   modify_field( Uniontown.Basalt, 1 );
   WestEnd();
}
table LunaPier {
   reads {
      Crumstown.Woodfield : exact;
      Crumstown.Handley : exact;
      Crumstown.Mogadore : exact;
   }
   actions {
      Millett;
   }
   size: 2048;
}
table DewyRose {
   reads {
      Crumstown.Woodfield : ternary;
      Crumstown.Handley : ternary;
      Crumstown.Mogadore : ternary;
      Crumstown.DelRey : ternary;
   }
   actions {
      Millett;
   }
   default_action : Fleetwood();
   size: 512;
}
control Bennet {
   apply( Mogote ) {
      Fleetwood {
         apply( Woodfords ) {
            Fleetwood {
               if (Parkline.Iredell == 0 and
                   Crumstown.Amory != 0 and
                   (WebbCity.Edgemoor == 1 or
                    Mendon.Rixford == 1) and
                   Crumstown.Baudette == 0 and
                   Crumstown.Asher == 0) {
                  apply( Veneta );
               }
               apply(DewyRose) {
                  Fleetwood {
                     apply(LunaPier);
                  }
               }
            }
         }
      }
   }
}
control Croft {
   apply( Coffman );
}
field_list NewRoads {
   Crumstown.Mackville;
   Crumstown.Pineland;
   Crumstown.Amory;
   Crumstown.Bodcaw;
}
action Glenpool() {
}
action Telephone() {
   generate_digest(0, NewRoads);
   Glenpool();
}
field_list Schofield {
   Crumstown.Amory;
   Hobson.Sherwin;
   Hobson.Goldenrod;
   McFaddin.Elmhurst;
   Radcliffe.Carnation;
   Escondido.Suamico;
}
action Stryker() {
   generate_digest(0, Schofield);
   Glenpool();
}
action Parrish() {
   modify_field( Crumstown.DeerPark, 1 );
   Glenpool();
}
action Forkville() {
   modify_field( WebbCity.Snowball, 1 );
   modify_field( WebbCity.Trotwood, 22 );
   Glenpool();
   modify_field( Madison.Basco, 0 );
   modify_field( Madison.Poulan, 0 );
}
table LoonLake {
   reads {
      Parkline.Iredell : exact;
      Crumstown.Hillcrest : ternary;
      ig_intr_md.ingress_port : ternary;
      Crumstown.Bodcaw mask 0x80000 : ternary;
      Madison.Basco : ternary;
      Madison.Poulan : ternary;
      Crumstown.Kulpmont : ternary;
   }
   actions {
      Telephone;
      Stryker;
      Forkville;
      Parrish;
   }
   default_action : Glenpool();
   size : 512;
}
control Heppner {
   if (Parkline.Iredell != 0) {
      apply( LoonLake );
   }
}
field_list Tobique {
   ig_intr_md.ingress_port;
   Crozet.Raeford;
}
field_list_calculation Chardon {
   input {
      Tobique;
   }
   algorithm : crc16_extend;
   output_width : 51;
}
action_selector Bassett {
   selection_key : Chardon;
   selection_mode : resilient;
}
action RichHill(McLean) {
   modify_field( ig_intr_md_for_tm.ucast_egress_port, McLean );
   bit_or( WebbCity.Ivanpah, WebbCity.Ivanpah, WebbCity.Marydel );
}
action Danbury() {
   modify_field( ig_intr_md_for_tm.ucast_egress_port, WebbCity.Chubbuck, 0x001FF );
   bit_or( WebbCity.Ivanpah, WebbCity.Ivanpah, WebbCity.Marydel );
}
action Cropper() {
   bit_not( ig_intr_md_for_tm.ucast_egress_port, 0 );
}
action Wagener() {
   bit_or( WebbCity.Ivanpah, WebbCity.Ivanpah, WebbCity.Marydel );
   Cropper();
}
action_profile Demarest {
   actions {
      RichHill;
      Danbury;
      Wagener;
      Cropper;
   }
   size : 32768;
   dynamic_action_selection : Bassett;
}
table SantaAna {
   reads {
      WebbCity.Chubbuck : ternary;
   }
   action_profile: Demarest;
   size : 512;
}
control Lushton {
   apply(SantaAna);
}
@pragma pa_no_init ingress WebbCity.Chubbuck
@pragma pa_no_init ingress WebbCity.Crossnore
@pragma pa_no_init ingress ig_intr_md_for_tm.ucast_egress_port
action Curtin(Hitterdal) {
   modify_field(WebbCity.Tocito, Mendon.Rardin );
   modify_field(WebbCity.Gause, Crumstown.Handley);
   modify_field(WebbCity.Stowe, Crumstown.Mogadore);
   modify_field(WebbCity.Wallula, Crumstown.Amory);
   modify_field(WebbCity.Chubbuck, Hitterdal);
   modify_field(WebbCity.Crossnore, 0);
   bit_or( Crumstown.Strevell, Crumstown.Strevell, Crumstown.Ontonagon );
}
@pragma use_hash_action 1
table Dixon {
   reads {
      Escondido.valid : exact;
   }
   actions {
      Curtin;
   }
   default_action : Curtin(511);
   size : 2;
}
control Daykin {
   apply( Dixon );
}
meter Yetter {
   type : bytes;
   direct : Dizney;
   result : Crumstown.Sanatoga;
}
action Bonduel() {
   modify_field( WebbCity.FoxChase, Crumstown.Ashwood );
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Crumstown.Petrey);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, WebbCity.Wallula);
}
action Thalia() {
   add(ig_intr_md_for_tm.mcast_grp_a, WebbCity.Wallula, 4096);
   modify_field( Crumstown.Lamine, 1 );
   modify_field( WebbCity.FoxChase, Crumstown.Ashwood );
}
action Elmore() {
   modify_field(ig_intr_md_for_tm.mcast_grp_a, WebbCity.Wallula);
   modify_field( WebbCity.FoxChase, Crumstown.Ashwood );
}
table Dizney {
   reads {
      ig_intr_md.ingress_port mask 0x7f : ternary;
      WebbCity.Gause : ternary;
      WebbCity.Stowe : ternary;
   }
   actions {
      Bonduel;
      Thalia;
      Elmore;
   }
   size : 512;
}
action Atlas(Noyack) {
   modify_field(WebbCity.Chubbuck, Noyack);
}
action Ralph(Hanamaulu, Hollymead) {
   modify_field(WebbCity.Crossnore, Hollymead);
   Atlas(Hanamaulu);
   modify_field(WebbCity.Austell, 5);
}
action Pettry(Celada) {
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Celada);
}
action Masardis() {
   modify_field( Crumstown.Calvary, 1 );
}
table Barnard {
   reads {
      WebbCity.Gause : exact;
      WebbCity.Stowe : exact;
      WebbCity.Wallula : exact;
   }
   actions {
      Atlas;
      Pettry;
      Ralph;
      Masardis;
      Fleetwood;
   }
   default_action : Fleetwood();
   size : 8192;
}
control Eskridge {
   apply(Barnard) {
      Fleetwood {
         apply(Dizney);
      }
   }
}
field_list Mausdale {
   Crozet.Raeford;
}
field_list_calculation Remington {
   input {
      Mausdale;
   }
   algorithm : identity;
   output_width : 51;
}
action Musella( Scranton, Marquette ) {
   modify_field( WebbCity.Ivanpah, WebbCity.Chubbuck );
   modify_field( WebbCity.Marydel, Marquette );
   modify_field( WebbCity.Chubbuck, Scranton );
   modify_field( WebbCity.Austell, 5 );
   modify_field( ig_intr_md_for_tm.disable_ucast_cutthru, 1 );
}
action_selector Craigmont {
   selection_key : Remington;
   selection_mode : resilient;
}
action_profile Wolcott {
   actions {
      Musella;
   }
   size : 1;
   dynamic_action_selection : Craigmont;
}
@pragma ways 2
table Rattan {
   reads {
      WebbCity.Crossnore : exact;
   }
   action_profile : Wolcott;
   size : 0;
}
action Cooter() {
   modify_field( Crumstown.Duque, 1 );
}
table Alston {
   actions {
      Cooter;
   }
   default_action : Cooter;
   size : 1;
}
action Roscommon() {
   modify_field( Crumstown.Andrade, 1 );
}
@pragma ways 1
table Minto {
   reads {
      WebbCity.Chubbuck mask 0x007FF : exact;
   }
   actions {
      Skime;
      Roscommon;
   }
   default_action : Skime;
   size : 512;
}
control RioLajas {
   if ((Crumstown.Delavan == 0) and (WebbCity.Cassadaga==0) and (Crumstown.Lamine==0)
       and (Crumstown.Abilene==0) and (Madison.Poulan == 0) and (Madison.Basco == 0)) {
      if (((Crumstown.Bodcaw==WebbCity.Chubbuck) or ((WebbCity.Edgemoor == 1) and (WebbCity.Austell == 5))) ) {
         apply(Alston);
      } else if (Mendon.Rardin==2 and
                 ((WebbCity.Chubbuck & 0xFF800) ==
                   0x03800)) {
         apply(Minto);
      }
   }
   apply(Rattan);
}
action Haverford( Oroville ) {
   modify_field( WebbCity.Miranda, Oroville );
}
action Aylmer( Sylvester ) {
   modify_field( WebbCity.Miranda, Sylvester );
   modify_field( WebbCity.Billett, 1 );
}
action Laxon() {
   modify_field( WebbCity.Miranda, WebbCity.Wallula );
}
@pragma pa_container_size egress WebbCity.Billett 32
table Grovetown {
   reads {
      eg_intr_md.egress_port mask 0x7f : exact;
      WebbCity.Wallula : exact;
   }
   actions {
      Haverford;
      Aylmer;
      Laxon;
   }
   default_action : Laxon;
   size : 4096;
}
control Gobles {
   apply( Grovetown );
}
action Tampa( Kountze, Matador, Cannelton ) {
   modify_field( WebbCity.Amalga, Kountze );
   add_to_field( eg_intr_md.pkt_length, Matador );
   bit_and( Crozet.Raeford, Crozet.Raeford, Cannelton );
}
action Inkom( Burgess, Froid, Bethania, Chenequa ) {
   modify_field( WebbCity.Realitos, Burgess );
   Tampa( Froid, Bethania, Chenequa );
}
action Piketon( Glentana, Brinklow, DuPont, Supai ) {
   modify_field( WebbCity.Mendota, WebbCity.Catarina );
   modify_field( WebbCity.Realitos, Glentana );
   Tampa( Brinklow, DuPont, Supai );
}
action Absarokee( Milesburg, Hiwassee ) {
   modify_field( WebbCity.Amalga, Milesburg );
   add_to_field( eg_intr_md.pkt_length, Hiwassee );
}
@pragma no_egress_length_correct 1
@pragma ternary 1
table Lakebay {
   reads {
      WebbCity.Edgemoor : ternary;
      WebbCity.Austell : exact;
      WebbCity.BallClub : ternary;
      WebbCity.Ivanpah mask 0x50000 : ternary;
   }
   actions {
      Tampa;
      Inkom;
      Piketon;
      Absarokee;
   }
   size : 16;
}
action RiceLake( DeBeque ) {
   modify_field( WebbCity.Creston, 1 );
   modify_field( WebbCity.Austell, 2 );
   modify_field( WebbCity.Lisman, DeBeque );
   modify_field( WebbCity.Pengilly, 0);
}
table Perryton {
   reads {
      eg_intr_md.egress_port : exact;
      Mendon.Rixford : exact;
      WebbCity.BallClub : exact;
      WebbCity.Edgemoor : exact;
   }
   actions {
      RiceLake;
   }
   default_action : Fleetwood();
   size : 32;
}
action Zarah(Darmstadt, Terlingua, Humacao, Louin) {
   modify_field( Tecumseh.Gonzales, Darmstadt );
   modify_field( Tecumseh.Wellsboro, Terlingua );
   modify_field( Tecumseh.Hallville, Humacao );
   modify_field( Tecumseh.Narka, Louin );
}
@pragma ternary 1
table Antlers {
   reads {
      WebbCity.Pittwood : exact;
   }
   actions {
      Zarah;
   }
   size : 512;
}
action ElMirage( Coconino, Salineno, Hiland ) {
   modify_field( WebbCity.Union, Coconino );
   modify_field( WebbCity.Bevier, Salineno );
   modify_field( WebbCity.Wallula, Hiland );
}
control Newkirk {
}
control Hawthorn {
}
control CruzBay {
   if( WebbCity.Ivanpah != 0 ) {
   }
}
action Lamoni() {
   modify_field( Escondido.Suamico, Benkelman.Maury );
   remove_header( Benkelman );
}
action Olmitz() {
   modify_field( Protivin.Maury, Benkelman.Maury );
   remove_header( Benkelman );
}
table GlenArm {
   actions {
      Lamoni;
   }
   default_action : Lamoni;
   size : 1;
}
action Granville() {
   no_op();
}
action Homeacre() {
   add_header( Benkelman );
   modify_field( Benkelman.Triplett, WebbCity.Miranda );
   modify_field( Benkelman.Maury, Escondido.Suamico );
   modify_field( Benkelman.Christina, Beltrami.Moneta );
   modify_field( Benkelman.Carroll, Beltrami.Mayday );
   modify_field( Escondido.Suamico, 0x8100 );
}
action Maybell() {
   modify_field( Benkelman.Maury, Protivin.Maury );
   modify_field( Escondido.Suamico, 0x88a8 );
   modify_field( Protivin.Maury, 0x8100 );
}
table Hanover {
   actions {
      Maybell;
   }
   default_action : Maybell;
}
@pragma ways 2
table Bagwell {
   reads {
      WebbCity.Miranda : exact;
      eg_intr_md.egress_port mask 0x7f : exact;
      WebbCity.Billett : exact;
   }
   actions {
      Granville;
      Homeacre;
   }
   default_action : Homeacre;
   size : 128;
}
action Gilliatt(Lansdale, Gorman) {
   modify_field(Escondido.Findlay, WebbCity.Gause);
   modify_field(Escondido.Lansdowne, WebbCity.Stowe);
   modify_field(Escondido.Sherwin, Lansdale);
   modify_field(Escondido.Goldenrod, Gorman);
}
action Retrop(Tuskahoma, Alcester) {
   Gilliatt(Tuskahoma, Alcester);
   add_to_field(McFaddin.Wildell, -1);
}
action Newsome(Chazy, Boring) {
   Gilliatt(Chazy, Boring);
   add_to_field(Radcliffe.Thach, -1);
}
action Aldrich() {
}
action Satanta() {
}
action Bunker() {
   Homeacre();
}
@pragma pa_no_init egress Tecumseh.Gonzales
@pragma pa_no_init egress Tecumseh.Wellsboro
@pragma pa_no_init egress Tecumseh.Hallville
@pragma pa_no_init egress Tecumseh.Narka
@pragma pa_no_init egress Tecumseh.Westoak
@pragma pa_no_init egress Tecumseh.Pearson
@pragma pa_no_init egress Tecumseh.Wattsburg
@pragma pa_no_init egress Tecumseh.Alexis
@pragma pa_no_init egress Tecumseh.Mondovi
@pragma pa_no_init egress Tecumseh.Uhland
action Corfu( Lovelady ) {
   add_header( Tecumseh );
   modify_field( Tecumseh.Westoak, WebbCity.Annetta );
   modify_field( Tecumseh.Pearson, Lovelady );
   modify_field( Tecumseh.Wattsburg, Crumstown.Amory );
   modify_field( Tecumseh.Alexis, WebbCity.Lisman );
   modify_field( Tecumseh.Mondovi, WebbCity.Pengilly );
}
action Greenland() {
   Corfu( WebbCity.Trotwood );
}
action Chatmoss() {
   modify_field( Escondido.Findlay, Escondido.Findlay );
   no_op();
}
action Headland( FortHunt, Grannis ) {
   add_header( Escondido );
   modify_field( Escondido.Findlay, WebbCity.Gause );
   modify_field( Escondido.Lansdowne, WebbCity.Stowe );
   modify_field( Escondido.Sherwin, FortHunt );
   modify_field( Escondido.Goldenrod, Grannis );
   modify_field( Escondido.Suamico, 0x0800 );
}
action Provencal() {
   remove_header( Robstown[0] );
   remove_header( Skiatook );
   remove_header( Boysen );
   remove_header( Elmsford );
   remove_header( McFaddin );
}
action Gullett( LakeHart ) {
   Provencal();
   modify_field( Escondido.Suamico, 0x0800 );
   Corfu( LakeHart );
}
action Dunmore( Termo ) {
   Provencal();
   modify_field( Escondido.Suamico, 0x86dd );
   Corfu( Termo );
}
action Poipu() {
   remove_header( McFaddin );
   remove_header( Radcliffe );
}
action Eucha() {
   Poipu();
   modify_field( Escondido.Suamico, 0x0800 );
   Corfu( WebbCity.Trotwood );
}
action Ladelle() {
   Poipu();
   modify_field( Escondido.Suamico, 0x86dd );
   Corfu( WebbCity.Trotwood );
}
action Kearns( Coamo, Olmstead, Palmhurst, Glenolden ) {
   add( Skiatook.Seagate, Coamo, Olmstead );
   modify_field( Boysen.Ambrose, 0 );
   modify_field( Elmsford.Dagsboro, WebbCity.Amalga );
   bit_or( Elmsford.Arvana, Crozet.Raeford, 0xC000 );
   modify_field( Escondido.Findlay, WebbCity.Union );
   modify_field( Escondido.Lansdowne, WebbCity.Bevier );
   modify_field( Escondido.Sherwin, Palmhurst );
   modify_field( Escondido.Goldenrod, Glenolden );
}
action Neshaminy( Gladden, Soldotna, Tiskilwa, Berkey, Dandridge ) {
   add_header( Skiatook );
   add_header( Boysen );
   add_header( Elmsford );
   add_header( Robstown[0] );
   Kearns( Gladden, Soldotna, Berkey, Dandridge );
   Hannibal( Gladden, Tiskilwa );
}
action Skene( Hooksett, Mifflin ) {
   add_header( Macedonia );
   McGovern( -1 );
   Neshaminy( McFaddin.Nisland, 12, 32,
                         Hooksett, Mifflin );
}
action Lesley( Makawao, Newhalen ) {
   add_header( Harriet );
   Kremlin( -1 );
   add_header( McFaddin );
   Neshaminy( eg_intr_md.pkt_length, -6, 14,
                            Makawao, Newhalen );
   remove_header( Radcliffe );
}
action Wauregan() {
   remove_header( Hookdale );
   remove_header( Skiatook );
   remove_header( Boysen );
   remove_header( Elmsford );
   copy_header( Escondido, Hobson );
   remove_header( Hobson );
   remove_header( McFaddin );
   remove_header( Radcliffe );
}
action Kelsey( Brockton ) {
   Wauregan();
   Corfu( Brockton );
}
action Hammett( Rossburg, Wabasha ) {
   remove_header( Robstown[0] );
   remove_header( Skiatook );
   remove_header( Boysen );
   remove_header( Elmsford );
   remove_header( McFaddin );
   modify_field( Escondido.Findlay, WebbCity.Gause );
   modify_field( Escondido.Lansdowne, WebbCity.Stowe );
   modify_field( Escondido.Sherwin, Rossburg );
   modify_field( Escondido.Goldenrod, Wabasha );
}
action LeaHill( Kaufman, Upalco ) {
   Hammett( Kaufman, Upalco );
   modify_field( Escondido.Suamico, 0x0800 );
   add_to_field( Macedonia.Wildell, -1 );
}
action Dunkerton( Cassa, Achilles ) {
   Hammett( Cassa, Achilles );
   modify_field( Escondido.Suamico, 0x86dd );
   add_to_field( Harriet.Thach, -1 );
}
action Lynne( Deferiet, LakeLure ) {
   Poipu();
   Gilliatt( Deferiet, LakeLure );
   modify_field( Escondido.Suamico, 0x0800 );
   add_to_field( Macedonia.Wildell, -1 );
}
action ElToro( Freeburg, Sarepta ) {
   Poipu();
   Gilliatt( Freeburg, Sarepta );
   modify_field( Escondido.Suamico, 0x86dd );
   add_to_field( Harriet.Thach, -1 );
}
action Akiachak( Rehobeth, Glennie ) {
   remove_header( Hookdale );
   remove_header( Skiatook );
   remove_header( Boysen );
   remove_header( Elmsford );
   remove_header( McFaddin );
   remove_header( Radcliffe );
   modify_field( Escondido.Findlay, WebbCity.Gause );
   modify_field( Escondido.Lansdowne, WebbCity.Stowe );
   modify_field( Escondido.Sherwin, Rehobeth );
   modify_field( Escondido.Goldenrod, Glennie );
   modify_field( Escondido.Suamico, Hobson.Suamico );
   remove_header( Hobson );
}
action Sardinia( Forbes, Wanilla ) {
   Akiachak( Forbes, Wanilla );
   add_to_field( Macedonia.Wildell, -1 );
}
action Montague( Junior, Pierpont ) {
   Akiachak( Junior, Pierpont );
   add_to_field( Harriet.Thach, -1 );
}
action Cascade() {
   modify_field( Escondido.Lansdowne, Escondido.Lansdowne );
}
action McGovern( Nighthawk ) {
   modify_field( Macedonia.RedCliff, McFaddin.RedCliff );
   modify_field( Macedonia.Micro, McFaddin.Micro );
   modify_field( Macedonia.Fittstown, McFaddin.Fittstown );
   modify_field( Macedonia.Onava, McFaddin.Onava );
   modify_field( Macedonia.Nisland, McFaddin.Nisland );
   modify_field( Macedonia.FarrWest, McFaddin.FarrWest );
   modify_field( Macedonia.Dacono, McFaddin.Dacono );
   modify_field( Macedonia.Breese, McFaddin.Breese );
   modify_field( Macedonia.Temple, McFaddin.Temple );
   modify_field( Macedonia.Atlantic, McFaddin.Atlantic );
   add( Macedonia.Wildell, McFaddin.Wildell, Nighthawk );
   modify_field( Macedonia.Terry, McFaddin.Terry );
   modify_field( Macedonia.Elmhurst, McFaddin.Elmhurst );
   modify_field( Macedonia.Waseca, McFaddin.Waseca );
}
action Hartwell( Sonoita, Kokadjo, Newland, Topton, Loring,
                         Marlton, Traskwood ) {
   modify_field( Hobson.Findlay, WebbCity.Gause );
   modify_field( Hobson.Lansdowne, WebbCity.Stowe );
   modify_field( Hobson.Sherwin, Newland );
   modify_field( Hobson.Goldenrod, Topton );
   add( Skiatook.Seagate, Sonoita, Kokadjo );
   modify_field( Boysen.Ambrose, 0 );
   modify_field( Elmsford.Dagsboro, WebbCity.Amalga );
   add( Elmsford.Arvana, Crozet.Raeford, Traskwood );
   modify_field( Escondido.Findlay, WebbCity.Union );
   modify_field( Escondido.Lansdowne, WebbCity.Bevier );
   modify_field( Escondido.Sherwin, Loring );
   modify_field( Escondido.Goldenrod, Marlton );
}
action Oakton( Bulverde, Ackerly, Meridean, Abbyville,
                                Micco, Mattoon, Motley ) {
   add_header( Hobson );
   add_header( Skiatook );
   add_header( Boysen );
   add_header( Elmsford );
   add_header( Hookdale );
   modify_field( Hobson.Suamico, Escondido.Suamico );
   Hartwell( Bulverde, Ackerly, Meridean, Abbyville, Micco,
                     Mattoon, Motley );
}
action Ishpeming( Sutherlin, Ingleside, Livonia, Hanston,
                                    Brumley, Gervais, Arcanum,
                                    Empire ) {
   Oakton( Sutherlin, Ingleside, Hanston, Brumley,
                            Gervais, Arcanum, Empire );
   Hannibal( Sutherlin, Livonia );
}
action Almelund( LaMonte, Mancelona, Felida, Nashwauk,
                                    Chaumont, Twain, Throop,
                                    Elsmere, MintHill, Pricedale, Burdette, Bergton ) {
   remove_header( McFaddin );
   Oakton( LaMonte, Mancelona, Nashwauk, Chaumont,
                            Twain, Throop, Bergton );
   Anthon( LaMonte, Felida, Elsmere, MintHill, Pricedale, Burdette );
}
action Hannibal( Wolverine, Kiana ) {
   modify_field( McFaddin.RedCliff, 0x4 );
   modify_field( McFaddin.Micro, 0x5 );
   modify_field( McFaddin.Fittstown, 0 );
   modify_field( McFaddin.Onava, 0 );
   add( McFaddin.Nisland, Wolverine, Kiana );
   modify_field_rng_uniform(McFaddin.FarrWest, 0, 0xFFFF);
   modify_field( McFaddin.Dacono, 0 );
   modify_field( McFaddin.Breese, 1 );
   modify_field( McFaddin.Temple, 0 );
   modify_field( McFaddin.Atlantic, 0 );
   modify_field( McFaddin.Wildell, 64 );
   modify_field( McFaddin.Terry, 17 );
   modify_field( McFaddin.Elmhurst, WebbCity.Realitos );
   modify_field( McFaddin.Waseca, WebbCity.Mendota );
   modify_field( Escondido.Suamico, 0x0800 );
}
action Anthon( Honuapo, Sabetha, Kalvesta, CeeVee, Overbrook, Timnath ) {
   add_header( Holliday );
   modify_field( Holliday.Tolono, 0x6 );
   modify_field( Holliday.Westville, 0 );
   modify_field( Holliday.Broadwell, 0 );
   modify_field( Holliday.Euren, 0 );
   add( Holliday.SwissAlp, Honuapo, Sabetha );
   modify_field( Holliday.BirchRun, 17 );
   modify_field( Holliday.Cherokee, Kalvesta );
   modify_field( Holliday.Naylor, CeeVee );
   modify_field( Holliday.Estrella, Overbrook );
   modify_field( Holliday.Cisne, Timnath );
   modify_field( Holliday.Perrine, WebbCity.Mendota, 0xFFFF );
   modify_field( Holliday.Wimbledon, 0, 0xFFFFFFF0 );
   modify_field( Holliday.Lyncourt, 64 );
   modify_field( Escondido.Suamico, 0x86dd );
}
action Bevington( Beaman, Boquillas, Moweaqua ) {
   add_header( Macedonia );
   McGovern( -1 );
   Ishpeming( McFaddin.Nisland, 30, 50, Beaman,
                                Boquillas, Beaman, Boquillas,
                                Moweaqua );
}
action Reedsport( Bayville, Camelot, OakCity ) {
   add_header( Macedonia );
   McGovern( 0 );
   Nunnelly( Bayville, Camelot, OakCity );
}
action Kremlin( Temvik ) {
   modify_field( Harriet.Hubbell, Radcliffe.Hubbell );
   modify_field( Harriet.Shubert, Radcliffe.Shubert );
   modify_field( Harriet.Addicks, Radcliffe.Addicks );
   modify_field( Harriet.Clarks, Radcliffe.Clarks );
   modify_field( Harriet.Spenard, Radcliffe.Spenard );
   modify_field( Harriet.Loveland, Radcliffe.Loveland );
   modify_field( Harriet.Carnation, Radcliffe.Carnation );
   modify_field( Harriet.Vantage, Radcliffe.Vantage );
   add( Harriet.Thach, Radcliffe.Thach, Temvik );
}
action Naalehu( Tiburon, Ikatan, Onslow ) {
   add_header( Harriet );
   Kremlin( -1 );
   add_header( McFaddin );
   Ishpeming( eg_intr_md.pkt_length, 12, 32, Tiburon,
                                Ikatan, Tiburon, Ikatan,
                                Onslow );
   remove_header( Radcliffe );
}
action Boonsboro( Lynch, Flaherty, Bogota ) {
   add_header( Harriet );
   Kremlin( 0 );
   remove_header( Radcliffe );
   Nunnelly( Lynch, Flaherty, Bogota );
}
action Nunnelly( Blanchard, Rumson, Pevely ) {
   add_header( McFaddin );
   Ishpeming( eg_intr_md.pkt_length, 12, 32,
                                Escondido.Sherwin, Escondido.Goldenrod,
                                Blanchard, Rumson, Pevely );
}
action Owyhee( Brawley, Adams, Sitka ) {
   Hartwell( Skiatook.Seagate, 0, Brawley, Adams, Brawley, Adams, Sitka );
   Hannibal( McFaddin.Nisland, 0 );
}
action Pavillion( Blackman, Welch, Flourtown ) {
   Owyhee( Blackman, Welch, Flourtown );
   add_to_field( Macedonia.Wildell, -1 );
}
action Swanlake( Eveleth, Jenera, Alcalde ) {
   Owyhee( Eveleth, Jenera, Alcalde );
   add_to_field( Harriet.Thach, -1 );
}
action Wentworth( Barksdale, Stockton, Holcut, Walland, Cammal,
                                Newtok, Sprout )
{
   Almelund( eg_intr_md.pkt_length, 12, 12, Escondido.Sherwin,
                                Escondido.Goldenrod, Barksdale,
                                Stockton, Holcut, Walland, Cammal, Newtok,
                                Sprout );
}
action Macdona( Brackett, Wenham, Ralls, Suarez,
                                        Sabana, Higgston, Macopin ) {
   add_header( Macedonia );
   McGovern( 0 );
   Almelund( McFaddin.Nisland, 30, 30, Escondido.Sherwin,
                                Escondido.Goldenrod, Brackett,
                                Wenham, Ralls, Suarez, Sabana, Higgston,
                                Macopin );
}
action Lodoga( Osseo, Moodys, Eckman, Leflore,
                                       Towaoc, Congress, Onawa ) {
   add_header( Macedonia );
   McGovern( -1 );
   Almelund( McFaddin.Nisland, 30, 30, Osseo,
                                Moodys, Osseo, Moodys,
                                Eckman, Leflore, Towaoc, Congress, Onawa );
}
action Ephesus( Rockdell, Paxico, Newfolden,
                                              Hephzibah, Grassflat, Tulsa, Beechwood ) {
   Hartwell( Skiatook.Seagate, 0, Rockdell, Paxico,
                     Rockdell, Paxico, Beechwood );
   Anthon( eg_intr_md.pkt_length, -58, Newfolden, Hephzibah, Grassflat, Tulsa );
   remove_header( Radcliffe );
   add_to_field( Macedonia.Wildell, -1 );
}
action Truro( Leucadia, McCloud, Stuttgart, Mishawaka,
                                          Lewiston, Nanuet, Tallevast ) {
   Hartwell( Skiatook.Seagate, 0, Leucadia, McCloud,
                     Leucadia, McCloud, Tallevast );
   Anthon( eg_intr_md.pkt_length, -38, Stuttgart, Mishawaka, Lewiston, Nanuet );
   remove_header( McFaddin );
   add_to_field( Macedonia.Wildell, -1 );
}
action Olathe( Vieques, Placid,
                                          Muncie ) {
   add_header( McFaddin );
   Hartwell( Skiatook.Seagate, 0, Vieques, Placid,
                     Vieques, Placid, Muncie );
   Hannibal( eg_intr_md.pkt_length, -38 );
   remove_header( Radcliffe );
   add_to_field( Macedonia.Wildell, -1 );
}
table Bethesda {
   reads {
      WebbCity.Edgemoor : exact;
      WebbCity.Austell : exact;
      WebbCity.Cassadaga : exact;
      McFaddin.valid : ternary;
      Radcliffe.valid : ternary;
      Macedonia.valid : ternary;
      Harriet.valid : ternary;
      WebbCity.Ivanpah mask 0xC0000 : ternary;
   }
   actions {
      Retrop;
      Newsome;
      Aldrich;
      Satanta;
      Bunker;
      Greenland;
      Cascade;
      Headland;
      Chatmoss;
      Eucha;
      Ladelle;
      Lynne;
      ElToro;
   }
   size : 512;
}
control Sublett {
   apply( GlenArm );
}
control Toccopola {
   apply( Bagwell )
   ;
}
action Mayflower() {
   drop();
}
table Gustine {
   reads {
      WebbCity.Tocito : exact;
      eg_intr_md.egress_port mask 0x7F: exact;
   }
   actions {
      Mayflower;
   }
   size : 512;
}
control Belcourt {
   apply( Perryton ) {
      Fleetwood {
         apply( Lakebay );
      }
   }
   apply( Antlers );
   if( WebbCity.Cassadaga == 0 and WebbCity.Edgemoor == 0 and WebbCity.Austell == 0 ) {
      apply( Gustine );
   }
   apply( Bethesda );
}
@pragma pa_no_init ingress Beltrami.FairOaks
@pragma pa_no_init ingress Beltrami.Devore
@pragma pa_no_init ingress Beltrami.Plata
@pragma pa_no_init ingress Beltrami.Moneta
@pragma pa_no_init ingress Beltrami.Sheldahl
action Longford( Maiden, Forman, Marysvale ) {
   modify_field( Beltrami.FairOaks, Maiden );
   modify_field( Beltrami.Devore, Forman );
   modify_field( Beltrami.Plata, Marysvale );
}
table Vidal {
   reads {
      ig_intr_md.ingress_port : exact;
   }
   actions {
      Longford;
   }
   default_action : Longford(0, 0, 0);
   size : 512;
}
action Chispa(Delmont) {
   modify_field( Beltrami.Moneta, Delmont );
}
action Rohwer(Wabuska) {
   modify_field( Beltrami.Moneta, Wabuska );
   modify_field( Crumstown.Monico, Benkelman.Maury );
}
action Renfroe() {
   modify_field( Beltrami.Sheldahl, Beltrami.Devore );
}
action Cabot() {
   modify_field( Beltrami.Sheldahl, 0 );
}
action Wheaton() {
   modify_field( Beltrami.Sheldahl, LaMoille.Pachuta );
}
action Waialua() {
   Wheaton();
}
action Wahoo() {
   modify_field( Beltrami.Sheldahl, Waterflow.ElPrado );
}
action Tennessee( Norcatur, Hamden ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Norcatur );
   modify_field( ig_intr_md_for_tm.qid, Hamden );
}
table Dillsburg {
   reads {
      Crumstown.Gibbstown : exact;
      Beltrami.FairOaks : exact;
      Benkelman.Christina : exact;
   }
   actions {
      Chispa;
      Rohwer;
   }
   size : 128;
}
table Lomax {
   reads {
      WebbCity.Edgemoor : exact;
      Crumstown.DelRey : exact;
   }
   actions {
      Renfroe;
      Cabot;
      Wheaton;
      Waialua;
      Wahoo;
   }
   size : 17;
}
@pragma pa_no_init ingress ig_intr_md_for_tm.ingress_cos
@pragma pa_no_init ingress ig_intr_md_for_tm.qid
table Waterford {
   reads {
      Beltrami.Plata : ternary;
      Beltrami.FairOaks : ternary;
      Beltrami.Moneta : ternary;
      Beltrami.Sheldahl : ternary;
      Beltrami.Carlson : ternary;
      WebbCity.Edgemoor : ternary;
      Tecumseh.Uhland : ternary;
      Tecumseh.Cowden : ternary;
   }
   actions {
      Tennessee;
   }
   default_action : Tennessee( 0, 0 );
   size : 306;
}
action Hettinger( Washoe, Tillson ) {
   modify_field( Beltrami.Fontana, Washoe );
   modify_field( Beltrami.Heads, Tillson );
}
table Tinsman {
   actions {
      Hettinger;
   }
   default_action : Hettinger;
   size : 1;
}
action Yorkville( Moraine ) {
   modify_field( Beltrami.Sheldahl, Moraine );
}
action Friday( Attica ) {
   modify_field( Beltrami.Moneta, Attica );
}
action Funston( Havertown, Joshua ) {
   modify_field( Beltrami.Moneta, Havertown );
   modify_field( Beltrami.Sheldahl, Joshua );
}
@pragma ternary 1
table Benson {
   reads {
      Beltrami.Plata : exact;
      Beltrami.Fontana : exact;
      Beltrami.Heads : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
      WebbCity.Edgemoor : exact;
   }
   actions {
      Yorkville;
      Friday;
      Funston;
   }
   size : 1024;
}
action Baker( Hinkley ) {
   modify_field( Beltrami.Oneonta, Hinkley );
}
@pragma ternary 1
table Portal {
   reads {
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Baker;
   }
   size : 8;
}
action Linganore() {
   modify_field( McFaddin.Fittstown, Beltrami.Sheldahl );
}
action Juniata() {
   modify_field( Radcliffe.Shubert, Beltrami.Sheldahl );
}
action Ballville() {
   modify_field( Macedonia.Fittstown, Beltrami.Sheldahl );
}
action Cashmere() {
   modify_field( Harriet.Shubert, Beltrami.Sheldahl );
}
action Secaucus() {
   modify_field( McFaddin.Fittstown, Beltrami.Oneonta );
}
action Starkey() {
   Secaucus();
   modify_field( Macedonia.Fittstown, Beltrami.Sheldahl );
}
action DonaAna() {
   Secaucus();
   modify_field( Harriet.Shubert, Beltrami.Sheldahl );
}
action Bieber() {
   modify_field( Holliday.Westville, Beltrami.Oneonta );
}
action Blakeley() {
   Bieber();
   modify_field( Macedonia.Fittstown, Beltrami.Sheldahl );
}
table Boxelder {
   reads {
      WebbCity.Austell : ternary;
      WebbCity.Edgemoor : ternary;
      WebbCity.Cassadaga : ternary;
      McFaddin.valid : ternary;
      Radcliffe.valid : ternary;
      Macedonia.valid : ternary;
      Harriet.valid : ternary;
   }
   actions {
      Linganore;
      Juniata;
      Ballville;
      Cashmere;
      Secaucus;
      Starkey;
      DonaAna;
      Bieber;
      Blakeley;
   }
   size : 14;
}
control Wright {
   apply( Vidal );
}
control Ovilla {
   apply( Dillsburg );
   apply( Lomax );
}
control Kaanapali {
   apply( Waterford );
}
control Tramway {
   apply( Tinsman );
   apply( Benson );
}
control Hodge {
   apply( Portal );
}
control Oregon {
   apply( Boxelder );
}
action Biscay( Westend ) {
   modify_field( Beltrami.Gilmanton, Westend );
}
@pragma ternary 1
table Kingstown {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
   }
   actions {
      Biscay;
   }
}
action Beresford( Roggen ) {
   modify_field( Beltrami.KawCity, Roggen );
}
table Kenefic {
   reads {
      Barwick.valid : ternary;
      WebbCity.Trotwood : ternary;
      WebbCity.Snowball : ternary;
      Crumstown.Abilene : ternary;
      Crumstown.Ramapo : ternary;
      Crumstown.Verdemont : ternary;
      Crumstown.Hansell : ternary;
   }
   actions {
      Beresford;
   }
   default_action: Beresford;
   size : 512;
}
meter Newberg {
   type : bytes;
   static : Vigus;
   instance_count : 4096;
}
counter Burrel {
   type : packets;
   static : Vigus;
   instance_count : 4096;
   min_width : 64;
}
field_list Decorah {
   ig_intr_md.ingress_port;
   Beltrami.KawCity;
}
field_list_calculation HornLake {
   input { Decorah; }
   algorithm: identity;
   output_width: 12;
}
action FairPlay() {
   count_from_hash( Burrel, HornLake );
}
action Taconite(Dillsboro) {
   execute_meter( Newberg, Dillsboro, ig_intr_md_for_tm.drop_ctl );
}
action Altadena(Ashburn) {
   Taconite(Ashburn);
   FairPlay();
}
table Vigus {
   reads {
      Beltrami.Gilmanton : exact;
      Beltrami.KawCity : exact;
   }
   actions {
      FairPlay;
      Altadena;
   }
   size : 512;
}
control Plains {
   apply( Kingstown );
}
control LoneJack {
   apply( Kenefic );
}
@pragma pa_mutually_exclusive ingress WebbCity.Pittwood ig_intr_md.ingress_port
@pragma pa_no_init ingress WebbCity.BallClub
@pragma pa_no_init ingress WebbCity.Pittwood
action Menomonie( McHenry, Crump ) {
   modify_field( WebbCity.Pittwood, ig_intr_md.ingress_port );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, McHenry );
   modify_field( ig_intr_md_for_tm.qid, Crump );
}
action Verndale( Eudora ) {
   modify_field( WebbCity.Pittwood, ig_intr_md.ingress_port );
   modify_field( ig_intr_md_for_tm.qid, Eudora, 0x18 );
}
action Pekin( TiffCity, Gladstone ) {
   Menomonie( TiffCity, Gladstone );
   modify_field( WebbCity.BallClub, 0);
}
action Sparr( Dauphin ) {
   Verndale( Dauphin );
   modify_field( WebbCity.BallClub, 0);
}
action Pembine( Jayton, Shine ) {
   Menomonie( Jayton, Shine );
   modify_field( WebbCity.BallClub, 1);
}
action Dassel( Wapella ) {
   Verndale( Wapella );
   modify_field( WebbCity.BallClub, 1);
}
action Sanborn( Quogue, Bladen ) {
   Pembine( Quogue, Bladen );
   modify_field(Crumstown.Amory, Benkelman.Triplett);
}
action Paxtonia( Copemish ) {
   Dassel( Copemish );
   modify_field(Crumstown.Amory, Benkelman.Triplett);
}
table BigBow {
   reads {
      WebbCity.Snowball : exact;
      Crumstown.Gibbstown : exact;
      Mendon.Rixford : ternary;
      WebbCity.Trotwood : ternary;
      Benkelman.valid : ternary;
   }
   actions {
      Pekin;
      Sparr;
      Pembine;
      Dassel;
      Sanborn;
      Paxtonia;
   }
   default_action : Dassel(0);
   size : 512;
}
control Eureka {
   apply( BigBow ) {
      Pekin {
      }
      Pembine {
      }
      Sanborn {
      }
      default {
         Lushton();
      }
   }
}
counter Compton {
   type : packets_and_bytes;
   static : Emden;
   instance_count : 4096;
   min_width : 64;
}
field_list Trion {
   eg_intr_md.egress_port;
   eg_intr_md.egress_qid;
}
field_list_calculation Slick {
   input { Trion; }
   algorithm: identity;
   output_width: 12;
}
action Emajagua() {
   count_from_hash( Compton, Slick );
}
table Emden {
   actions {
      Emajagua;
   }
   default_action : Emajagua;
   size : 1;
}
control Readsboro {
   apply( Emden );
}
action Bigspring() {
   modify_field( Crumstown.Felton, 1 );
}
action Lamkin() {
   remove_header(Tecumseh);
}
action Cedaredge() {
   Lamkin();
   modify_field(WebbCity.Edgemoor, 3);
   modify_field( Crumstown.Camden, 0 );
   modify_field( Crumstown.Petrey, 0 );
}
action Theba( Varna ) {
   Lamkin();
   modify_field(WebbCity.Edgemoor, 2);
   modify_field(WebbCity.Chubbuck, Varna);
   modify_field(WebbCity.Wallula, Crumstown.Amory );
   modify_field(WebbCity.Crossnore, 0);
}
@pragma ternary 1
table Ballwin {
   reads {
      Tecumseh.Gonzales : exact;
      Tecumseh.Wellsboro : exact;
      Tecumseh.Hallville : exact;
      Tecumseh.Narka : exact;
      WebbCity.Edgemoor : ternary;
   }
   actions {
      Theba;
      Cedaredge;
      Bigspring;
      Lamkin;
   }
   default_action : Bigspring();
   size : 1024;
}
control Antonito {
   apply( Ballwin );
}
action ArchCape( Kaolin, Tulia, Fackler, Carmel ) {
   modify_field( Santos.Lathrop, Kaolin );
   modify_field( Armijo.Eunice, Fackler );
   modify_field( Armijo.Twinsburg, Tulia );
   modify_field( Armijo.Oklahoma, Carmel );
}
@pragma ways 2
table DeKalb {
   reads {
      LaMoille.BigArm : exact;
      Crumstown.Woodfield : exact;
   }
   actions {
      ArchCape;
   }
   size : 16384;
}
action Otisco(Tarnov, Manteo, Madawaska) {
   modify_field( Armijo.Twinsburg, Tarnov );
   modify_field( Armijo.Eunice, Manteo );
   modify_field( Armijo.Oklahoma, Madawaska );
}
@pragma ways 2
table Elcho {
   reads {
      LaMoille.Anacortes : exact;
      Santos.Lathrop : exact;
   }
   actions {
      Otisco;
   }
   size : 16384;
}
action Dellslow( Francisco, Sasakwa, ElVerano ) {
   modify_field( Jesup.Amesville, Francisco );
   modify_field( Jesup.Botna, Sasakwa );
   modify_field( Jesup.Nutria, ElVerano );
}
@pragma ways 2
table Colona {
   reads {
      WebbCity.Gause : exact;
      WebbCity.Stowe : exact;
      WebbCity.Wallula : exact;
   }
   actions {
      Dellslow;
   }
   size : 16384;
}
action HighHill() {
}
action Darco( Quebrada ) {
   HighHill();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Armijo.Twinsburg );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Quebrada, Armijo.Oklahoma );
}
action Auberry( Madeira ) {
   HighHill();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Jesup.Amesville );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Madeira, Jesup.Nutria );
}
action Pikeville( Barber ) {
   HighHill();
   add( ig_intr_md_for_tm.mcast_grp_a, WebbCity.Wallula,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Barber );
}
action WestBend( Monse ) {
   HighHill();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, WebbCity.Wallula );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, ig_intr_md_for_tm.copy_to_cpu, Monse );
}
action Plush( Noyes ) {
   modify_field( ig_intr_md_for_tm.mcast_grp_a, 0 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Noyes );
}
action Mango() {
   modify_field( Crumstown.Meeker, 1 );
}
table Fragaria {
   reads {
      Armijo.Eunice : ternary;
      Jesup.Botna : ternary;
      Crumstown.Ramapo :ternary;
      Crumstown.Newfane : ternary;
      Crumstown.Camden: ternary;
      LaMoille.BigArm : ternary;
      WebbCity.Snowball : ternary;
   }
   actions {
      Darco;
      Auberry;
      Pikeville;
      Mango;
      Plush;
      WestBend;
   }
   size : 512;
}
control Pinecrest {
   if( Crumstown.Delavan == 0 and Madison.Poulan == 0 and
       Madison.Basco == 0 and ( ( Uniontown.Wetumpka & ( 0x4 ) ) == ( ( 0x4 ) ) ) and
       Crumstown.Newfane == 1 and Crumstown.DelRey == 0x1) {
      apply( DeKalb );
   }
}
control Bouse {
   if( Santos.Lathrop != 0 and Crumstown.DelRey == 0x1) {
      apply( Elcho );
   }
}
control Pound {
   if( Crumstown.Lamine==1 ) {
      apply( Colona );
   }
}
control Ranier {
   apply(Fragaria);
}
@pragma pa_no_init ingress ig_intr_md_for_tm.level1_mcast_hash
@pragma pa_no_init ingress ig_intr_md_for_tm.level2_mcast_hash
@pragma pa_no_init ingress ig_intr_md_for_tm.level2_exclusion_id
@pragma pa_alias ingress ig_intr_md_for_tm.level1_mcast_hash ig_intr_md_for_tm.level2_mcast_hash
action Oriskany(Hooks) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Crozet.Raeford );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Hooks );
}
@pragma ternary 1
table Coryville {
   reads {
      ig_intr_md.ingress_port : exact;
   }
   actions {
      Oriskany;
   }
   default_action : Oriskany( 0 );
   size : 512;
}
field_list Bains {
   4'0;
   WebbCity.Chubbuck;
}
field_list_calculation Uintah {
   input {
      Bains;
   }
   algorithm : identity;
   output_width : 16;
}
action Balmville( Gwinn ) {
   modify_field(ig_intr_md_for_tm.level1_exclusion_id, Gwinn);
   modify_field(ig_intr_md_for_tm.rid, ig_intr_md_for_tm.mcast_grp_a);
}
action Chaffee(Pittsburg) {
   Balmville( Pittsburg );
}
action Mulliken(Kress) {
   modify_field( ig_intr_md_for_tm.rid, 0xFFFF );
   modify_field( ig_intr_md_for_tm.level1_exclusion_id, Kress );
}
action Oronogo() {
   Mulliken( 0 );
   modify_field_with_hash_based_offset( ig_intr_md_for_tm.mcast_grp_a, 0, Uintah, 65536 );
}
action Goodwater( ElkRidge ) {
   modify_field(ig_intr_md_for_tm.level1_exclusion_id, ElkRidge);
   modify_field( ig_intr_md_for_tm.rid, 0 );
   modify_field_with_hash_based_offset( ig_intr_md_for_tm.mcast_grp_a, 0, Uintah, 65536 );
}
@pragma pa_no_init ingress ig_intr_md_for_tm.rid
table Stampley {
   reads {
      WebbCity.Edgemoor : ternary;
      WebbCity.Cassadaga : ternary;
      Mendon.Rardin : ternary;
      WebbCity.Chubbuck mask 0xF0000 : ternary;
      ig_intr_md_for_tm.mcast_grp_a mask 0xF000 : ternary;
   }
   actions {
      Balmville;
      Chaffee;
      Mulliken;
      Oronogo;
   }
   default_action : Chaffee( 0 );
   size: 512;
}
control Brinson {
   apply(Coryville);
}
control Doerun {
   if( WebbCity.Snowball == 0 ) {
      apply(Stampley);
   }
}
action FifeLake( Boise ) {
   modify_field( WebbCity.Wallula, Boise );
   modify_field( WebbCity.Cassadaga, 1 );
}
@pragma ways 2
table Hawthorne {
   reads {
      eg_intr_md.egress_rid: exact;
   }
   actions {
      FifeLake;
   }
   size : 32768;
}
control Ashtola {
   if (eg_intr_md.egress_rid != 0) {
      apply( Hawthorne );
   }
}
@pragma pa_no_init ingress Crumstown.Strevell
action Catlin() {
   modify_field( Crumstown.Strevell, 0 );
   modify_field( Nightmute.Ortley, Crumstown.Ramapo );
   modify_field( Nightmute.Bonney, LaMoille.Pachuta );
   modify_field( Nightmute.Moylan, Crumstown.Arredondo );
   modify_field( Nightmute.Westland, Crumstown.Godley );
}
action Susank() {
   modify_field( Crumstown.Strevell, 0 );
   modify_field( Nightmute.Ortley, Crumstown.Ramapo );
   modify_field( Nightmute.Bonney, Waterflow.ElPrado );
   modify_field( Nightmute.Moylan, Crumstown.Arredondo );
   modify_field( Nightmute.Westland, Crumstown.Godley );
}
action Harris( Lignite, Nephi ) {
   Catlin();
   modify_field( Nightmute.Hadley, Lignite );
   modify_field( Nightmute.Rienzi, Nephi );
}
action Chantilly( Taylors, Needles ) {
   Susank();
   modify_field( Nightmute.Hadley, Taylors );
   modify_field( Nightmute.Rienzi, Needles );
}
action Latham() {
   modify_field( Crumstown.Strevell, 1 );
}
action Wimberley() {
   modify_field( Crumstown.Ontonagon, 1 );
}
@pragma pa_no_init ingress Nightmute.Hadley
@pragma pa_container_size ingress Nightmute.Hadley 16
@pragma pa_no_init ingress Nightmute.Between
@pragma pa_container_size ingress Nightmute.Between 16
table BoyRiver {
   reads {
      LaMoille.Anacortes : ternary;
   }
   actions {
      Harris;
      Latham;
   }
   default_action : Catlin();
   size : 2048;
}
table Lumberton {
   reads {
      Waterflow.Alcoma : ternary;
   }
   actions {
      Chantilly;
      Latham;
   }
   default_action : Susank();
   size : 1024;
}
action Ririe( WhiteOwl, Pearcy ) {
   modify_field( Nightmute.Between, WhiteOwl );
   modify_field( Nightmute.Monida, Pearcy );
}
table Cruso {
   reads {
      LaMoille.BigArm : ternary;
   }
   actions {
      Ririe;
      Wimberley;
   }
   size : 512;
}
table Glendale {
   reads {
      Waterflow.Squire : ternary;
   }
   actions {
      Ririe;
      Wimberley;
   }
   size : 512;
}
control Francis {
   if( Crumstown.DelRey == 0x1 ) {
      apply( BoyRiver );
      apply( Cruso );
   } else if( Crumstown.DelRey == 0x2 ) {
      apply( Lumberton );
      apply( Glendale );
   }
}
metadata Courtdale Ribera;
counter Burmester {
   type : packets;
   direct: Hagerman;
   min_width: 63;
}
table Hagerman {
   reads {
      Ribera.Yantis mask 0x00007FFF : exact;
   }
   actions {
      Fleetwood;
   }
   default_action: Fleetwood();
   size : 32768;
}
action Tahuya( DeSmet, Orting ) {
   modify_field( Ribera.Yantis, Orting, 0xFFFF );
   modify_field( Nightmute.Agency, DeSmet );
   modify_field( Crumstown.Mattese, 1 );
}
action Twichell( Dundee, Ringold ) {
   modify_field( Ribera.Yantis, Ringold, 0xFFFF );
   modify_field( Nightmute.Agency, Dundee );
}
@pragma ways 3
@pragma immediate 0
table Woodstown {
   reads {
      Crumstown.DelRey mask 0x3 : exact;
      Crumstown.Woodfield : exact;
   }
   actions {
      Tahuya;
   }
   size : 8192;
}
table Boyle {
   reads {
      Crumstown.DelRey mask 0x3 : exact;
      ig_intr_md.ingress_port mask 0x7F : exact;
   }
   actions {
      Twichell;
      Fleetwood;
   }
   default_action : Fleetwood();
   size : 512;
}
action Monahans( Lubec ) {
   modify_field( Nightmute.MudLake, Lubec );
}
table Bigfork {
   reads {
      Crumstown.Verdemont : ternary;
   }
   actions {
      Monahans;
   }
   size : 1024;
}
action Cornell( Broussard ) {
   modify_field( Nightmute.Newtown, Broussard );
}
table Benitez {
   reads {
      Crumstown.Hansell : ternary;
   }
   actions {
      Cornell;
   }
   size : 1024;
}
action LakeFork() {
   modify_field( Ribera.Yantis, 0 );
}
table Roachdale {
   actions {
      LakeFork;
   }
   default_action : LakeFork();
   size : 1;
}
control Shuqualak {
   Francis();
   if( ( Crumstown.Denhoff & 2 ) == 2 ) {
      apply( Bigfork );
      apply( Benitez );
   }
   if( WebbCity.Edgemoor == 0 ) {
      apply( Boyle ) {
         Fleetwood {
            apply( Woodstown );
         }
      }
   } else {
      apply( Woodstown );
   }
}
   action Burgdorf( Mentone ) {
          max( Ribera.Yantis, Ribera.Yantis, Mentone );
   }
@pragma ways 1
table Lemont {
   reads {
      Nightmute.Agency : exact;
      Nightmute.Hadley : exact;
      Nightmute.Between : exact;
      Nightmute.MudLake : exact;
      Nightmute.Newtown : exact;
      Nightmute.Ortley : exact;
      Nightmute.Bonney : exact;
      Nightmute.Moylan : exact;
      Nightmute.Westland : exact;
      Nightmute.Clearco : exact;
   }
   actions {
      Burgdorf;
   }
   size : 4096;
}
control Spindale {
   apply( Lemont );
}
@pragma pa_no_init ingress Ashville.Hadley
@pragma pa_no_init ingress Ashville.Between
@pragma pa_no_init ingress Ashville.MudLake
@pragma pa_no_init ingress Ashville.Newtown
@pragma pa_no_init ingress Ashville.Ortley
@pragma pa_no_init ingress Ashville.Bonney
@pragma pa_no_init ingress Ashville.Moylan
@pragma pa_no_init ingress Ashville.Westland
@pragma pa_no_init ingress Ashville.Clearco
metadata Jenifer Ashville;
@pragma ways 1
table Valders {
   reads {
      Nightmute.Agency : exact;
      Ashville.Hadley : exact;
      Ashville.Between : exact;
      Ashville.MudLake : exact;
      Ashville.Newtown : exact;
      Ashville.Ortley : exact;
      Ashville.Bonney : exact;
      Ashville.Moylan : exact;
      Ashville.Westland : exact;
      Ashville.Clearco : exact;
   }
   actions {
      Burgdorf;
   }
   size : 8192;
}
action Elkville( Haena, Cedonia, Shidler, Hamburg, Piermont, Roodhouse, Bovina, Haley, Gassoway ) {
   bit_and( Ashville.Hadley, Nightmute.Hadley, Haena );
   bit_and( Ashville.Between, Nightmute.Between, Cedonia );
   bit_and( Ashville.MudLake, Nightmute.MudLake, Shidler );
   bit_and( Ashville.Newtown, Nightmute.Newtown, Hamburg );
   bit_and( Ashville.Ortley, Nightmute.Ortley, Piermont );
   bit_and( Ashville.Bonney, Nightmute.Bonney, Roodhouse );
   bit_and( Ashville.Moylan, Nightmute.Moylan, Bovina );
   bit_and( Ashville.Westland, Nightmute.Westland, Haley );
   bit_and( Ashville.Clearco, Nightmute.Clearco, Gassoway );
}
table Lackey {
   reads {
      Nightmute.Agency : exact;
   }
   actions {
      Elkville;
   }
   default_action : Elkville(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Silco {
   apply( Lackey );
}
control Danese {
   apply( Valders );
}
@pragma ways 1
table Slayden {
   reads {
      Nightmute.Agency : exact;
      Ashville.Hadley : exact;
      Ashville.Between : exact;
      Ashville.MudLake : exact;
      Ashville.Newtown : exact;
      Ashville.Ortley : exact;
      Ashville.Bonney : exact;
      Ashville.Moylan : exact;
      Ashville.Westland : exact;
      Ashville.Clearco : exact;
   }
   actions {
      Burgdorf;
   }
   size : 4096;
}
action Chelsea( Wharton, Tununak, Aguila, Switzer, Bellvue, Calabash, Derita, Browning, Welaka ) {
   bit_and( Ashville.Hadley, Nightmute.Hadley, Wharton );
   bit_and( Ashville.Between, Nightmute.Between, Tununak );
   bit_and( Ashville.MudLake, Nightmute.MudLake, Aguila );
   bit_and( Ashville.Newtown, Nightmute.Newtown, Switzer );
   bit_and( Ashville.Ortley, Nightmute.Ortley, Bellvue );
   bit_and( Ashville.Bonney, Nightmute.Bonney, Calabash );
   bit_and( Ashville.Moylan, Nightmute.Moylan, Derita );
   bit_and( Ashville.Westland, Nightmute.Westland, Browning );
   bit_and( Ashville.Clearco, Nightmute.Clearco, Welaka );
}
table Miller {
   reads {
      Nightmute.Agency : exact;
   }
   actions {
      Chelsea;
   }
   default_action : Chelsea(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Cusick {
   apply( Miller );
}
control Arpin {
   apply( Slayden );
}
@pragma ways 1
table Brookside {
   reads {
      Nightmute.Agency : exact;
      Ashville.Hadley : exact;
      Ashville.Between : exact;
      Ashville.MudLake : exact;
      Ashville.Newtown : exact;
      Ashville.Ortley : exact;
      Ashville.Bonney : exact;
      Ashville.Moylan : exact;
      Ashville.Westland : exact;
      Ashville.Clearco : exact;
   }
   actions {
      Burgdorf;
   }
   size : 4096;
}
action Snook( Plano, Brush, Melmore, Mulhall, Sunflower, Oklee, Abernathy, Chandalar, Baskin ) {
   bit_and( Ashville.Hadley, Nightmute.Hadley, Plano );
   bit_and( Ashville.Between, Nightmute.Between, Brush );
   bit_and( Ashville.MudLake, Nightmute.MudLake, Melmore );
   bit_and( Ashville.Newtown, Nightmute.Newtown, Mulhall );
   bit_and( Ashville.Ortley, Nightmute.Ortley, Sunflower );
   bit_and( Ashville.Bonney, Nightmute.Bonney, Oklee );
   bit_and( Ashville.Moylan, Nightmute.Moylan, Abernathy );
   bit_and( Ashville.Westland, Nightmute.Westland, Chandalar );
   bit_and( Ashville.Clearco, Nightmute.Clearco, Baskin );
}
table English {
   reads {
      Nightmute.Agency : exact;
   }
   actions {
      Snook;
   }
   default_action : Snook(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Estero {
   apply( English );
}
control Arminto {
   apply( Brookside );
}
@pragma ways 1
table Marquand {
   reads {
      Nightmute.Agency : exact;
      Ashville.Hadley : exact;
      Ashville.Between : exact;
      Ashville.MudLake : exact;
      Ashville.Newtown : exact;
      Ashville.Ortley : exact;
      Ashville.Bonney : exact;
      Ashville.Moylan : exact;
      Ashville.Westland : exact;
      Ashville.Clearco : exact;
   }
   actions {
      Burgdorf;
   }
   size : 8192;
}
action Attalla( Sharon, Goodlett, Valencia, Welcome, Markesan, Dunnegan, Topmost, Dryden, Thaxton ) {
   bit_and( Ashville.Hadley, Nightmute.Hadley, Sharon );
   bit_and( Ashville.Between, Nightmute.Between, Goodlett );
   bit_and( Ashville.MudLake, Nightmute.MudLake, Valencia );
   bit_and( Ashville.Newtown, Nightmute.Newtown, Welcome );
   bit_and( Ashville.Ortley, Nightmute.Ortley, Markesan );
   bit_and( Ashville.Bonney, Nightmute.Bonney, Dunnegan );
   bit_and( Ashville.Moylan, Nightmute.Moylan, Topmost );
   bit_and( Ashville.Westland, Nightmute.Westland, Dryden );
   bit_and( Ashville.Clearco, Nightmute.Clearco, Thaxton );
}
table Lamison {
   reads {
      Nightmute.Agency : exact;
   }
   actions {
      Attalla;
   }
   default_action : Attalla(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Pickett {
   apply( Lamison );
}
control Abbott {
   apply( Marquand );
}
@pragma ways 1
table Kasigluk {
   reads {
      Nightmute.Agency : exact;
      Ashville.Hadley : exact;
      Ashville.Between : exact;
      Ashville.MudLake : exact;
      Ashville.Newtown : exact;
      Ashville.Ortley : exact;
      Ashville.Bonney : exact;
      Ashville.Moylan : exact;
      Ashville.Westland : exact;
      Ashville.Clearco : exact;
   }
   actions {
      Burgdorf;
   }
   size : 8192;
}
action Admire( Convoy, Dixboro, Kapalua, Seaforth, Pettigrew, Korbel, Leacock, Arnold, Anoka ) {
   bit_and( Ashville.Hadley, Nightmute.Hadley, Convoy );
   bit_and( Ashville.Between, Nightmute.Between, Dixboro );
   bit_and( Ashville.MudLake, Nightmute.MudLake, Kapalua );
   bit_and( Ashville.Newtown, Nightmute.Newtown, Seaforth );
   bit_and( Ashville.Ortley, Nightmute.Ortley, Pettigrew );
   bit_and( Ashville.Bonney, Nightmute.Bonney, Korbel );
   bit_and( Ashville.Moylan, Nightmute.Moylan, Leacock );
   bit_and( Ashville.Westland, Nightmute.Westland, Arnold );
   bit_and( Ashville.Clearco, Nightmute.Clearco, Anoka );
}
table Burnett {
   reads {
      Nightmute.Agency : exact;
   }
   actions {
      Admire;
   }
   default_action : Admire(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Dorothy {
   apply( Burnett );
}
control Castle {
   apply( Kasigluk );
}
@pragma ways 1
table Covelo {
   reads {
      Nightmute.Agency : exact;
      Ashville.Hadley : exact;
      Ashville.Between : exact;
      Ashville.MudLake : exact;
      Ashville.Newtown : exact;
      Ashville.Ortley : exact;
      Ashville.Bonney : exact;
      Ashville.Moylan : exact;
      Ashville.Westland : exact;
      Ashville.Clearco : exact;
   }
   actions {
      Burgdorf;
   }
   size : 4096;
}
action LongPine( Herring, Topawa, Levasy, Lemhi, Simla, Tombstone, Gallion, Charco, PellCity ) {
   bit_and( Ashville.Hadley, Nightmute.Hadley, Herring );
   bit_and( Ashville.Between, Nightmute.Between, Topawa );
   bit_and( Ashville.MudLake, Nightmute.MudLake, Levasy );
   bit_and( Ashville.Newtown, Nightmute.Newtown, Lemhi );
   bit_and( Ashville.Ortley, Nightmute.Ortley, Simla );
   bit_and( Ashville.Bonney, Nightmute.Bonney, Tombstone );
   bit_and( Ashville.Moylan, Nightmute.Moylan, Gallion );
   bit_and( Ashville.Westland, Nightmute.Westland, Charco );
   bit_and( Ashville.Clearco, Nightmute.Clearco, PellCity );
}
table GlenAvon {
   reads {
      Nightmute.Agency : exact;
   }
   actions {
      LongPine;
   }
   default_action : LongPine(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Sunman {
}
control Selby {
}
@pragma ways 1
table Comptche {
   reads {
      Nightmute.Agency : exact;
      Ashville.Hadley : exact;
      Ashville.Between : exact;
      Ashville.MudLake : exact;
      Ashville.Newtown : exact;
      Ashville.Ortley : exact;
      Ashville.Bonney : exact;
      Ashville.Moylan : exact;
      Ashville.Westland : exact;
      Ashville.Clearco : exact;
   }
   actions {
      Burgdorf;
   }
   size : 4096;
}
action McDougal( Ruffin, Benwood, Freeman, Requa, Torrance, Frontier, Fairlee, PortWing, FlyingH ) {
   bit_and( Ashville.Hadley, Nightmute.Hadley, Ruffin );
   bit_and( Ashville.Between, Nightmute.Between, Benwood );
   bit_and( Ashville.MudLake, Nightmute.MudLake, Freeman );
   bit_and( Ashville.Newtown, Nightmute.Newtown, Requa );
   bit_and( Ashville.Ortley, Nightmute.Ortley, Torrance );
   bit_and( Ashville.Bonney, Nightmute.Bonney, Frontier );
   bit_and( Ashville.Moylan, Nightmute.Moylan, Fairlee );
   bit_and( Ashville.Westland, Nightmute.Westland, PortWing );
   bit_and( Ashville.Clearco, Nightmute.Clearco, FlyingH );
}
table Chaffey {
   reads {
      Nightmute.Agency : exact;
   }
   actions {
      McDougal;
   }
   default_action : McDougal(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Palatine {
   apply( Chaffey );
}
control Korona {
   apply( Comptche );
}
counter Macland {
   type : packets;
   direct : Craigtown;
   min_width: 64;
}
action Wanatah() {
   bit_or( ig_intr_md_for_tm.copy_to_cpu, ig_intr_md_for_tm.copy_to_cpu, 0 );
}
action Monohan() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action Morita() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 3 );
}
action Elkins() {
   bit_or( ig_intr_md_for_tm.copy_to_cpu, ig_intr_md_for_tm.copy_to_cpu, 0 );
   Morita();
}
action Gardena() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
   Morita();
}
table Craigtown {
   reads {
      ig_intr_md.ingress_port mask 0x7f : ternary;
      Ribera.Yantis mask 0x00018000 : ternary;
      Crumstown.Delavan : ternary;
      Crumstown.Lundell : ternary;
      Crumstown.Calvary : ternary;
      Crumstown.Felton : ternary;
      Crumstown.Duque : ternary;
      Crumstown.Meeker : ternary;
      Crumstown.BigRun : ternary;
      Crumstown.Andrade : ternary;
      Beltrami.Raritan : ternary;
      Crumstown.DelRey mask 0x4 : ternary;
      WebbCity.Chubbuck : ternary;
      ig_intr_md_for_tm.mcast_grp_a : ternary;
      WebbCity.Cassadaga : ternary;
      WebbCity.Snowball : ternary;
      Crumstown.Wheeler : ternary;
      Crumstown.Roberta : ternary;
      Madison.Basco : ternary;
      Madison.Poulan : ternary;
      Crumstown.DeerPark : ternary;
      ig_intr_md_for_tm.copy_to_cpu : ternary;
      Crumstown.Sanatoga : ternary;
      Crumstown.Abilene : ternary;
      Crumstown.Lamine : ternary;
   }
   actions {
      Wanatah;
      Monohan;
      Elkins;
      Gardena;
      Morita;
   }
   default_action: Wanatah();
   size : 1536;
}
control NewMelle {
   apply( Craigtown ) {
      Morita {
      }
      Elkins {
      }
      Gardena {
      }
      default {
         apply( Vigus );
         apply( Hagerman );
      }
   }
}
@pragma pa_no_init egress Lamona.Lakefield
@pragma pa_no_init egress WebbCity.Grainola
action LewisRun( Sunrise ) {
   modify_field( Lamona.Lakefield, Sunrise );
   modify_field( WebbCity.Grainola, 0 );
}
@pragma ternary 1
table RushCity {
   reads {
     WebbCity.Cassadaga : exact;
     Radcliffe.valid : exact;
     McFaddin.valid : exact;
     WebbCity.Wallula : exact;
   }
   actions {
      LewisRun;
   }
   default_action : LewisRun( 0 );
   size : 1024;
}
control Criner {
   apply( RushCity );
}
action Redvale( Belfalls ) {
   modify_field( WebbCity.Grainola, Belfalls );
}
counter Lehigh {
   type : packets;
   direct : Whigham;
   min_width: 64;
}
@pragma ignore_table_dependency Bethesda
table Whigham {
   reads {
      Lamona.Lakefield : ternary;
      McFaddin.Elmhurst : ternary;
      McFaddin.Waseca : ternary;
      McFaddin.Terry : ternary;
      Elmsford.Arvana: ternary;
      Elmsford.Dagsboro : ternary;
      Shelbiana.Goodrich : ternary;
      Nightmute.Clearco : ternary;
      }
   actions {
      Redvale;
   }
   size : 2048;
}
control Vestaburg {
      apply( Whigham );
}
control Hackney {
}
counter Kendrick {
   type : packets;
   direct : Garibaldi;
   min_width: 64;
}
@pragma ignore_table_dependency Bethesda
table Garibaldi {
   reads {
      Lamona.Lakefield : ternary;
      Radcliffe.Carnation : ternary;
      Radcliffe.Vantage : ternary;
      Radcliffe.Loveland : ternary;
      Elmsford.Arvana: ternary;
      Elmsford.Dagsboro : ternary;
      Shelbiana.Goodrich : ternary;
   }
   actions {
      Redvale;
   }
   size : 1024;
}
control Duelm {
      apply( Garibaldi );
}
action Chunchula( Highfill ) {
   modify_field( WebbCity.Rockdale, Highfill );
   bit_or( McFaddin.Terry, McFaddin.Terry, 0x80 );
}
action Justice( Weehawken ) {
   modify_field( WebbCity.Rockdale, Weehawken );
   bit_or( Radcliffe.Loveland, Radcliffe.Loveland, 0x80 );
}
table Oakford {
   reads {
      Crumstown.Ramapo mask 0x80 : exact;
      McFaddin.valid : exact;
      Radcliffe.valid : exact;
   }
   actions {
      Chunchula;
      Justice;
   }
   size : 8;
}
action Humble() {
   modify_field( McFaddin.Terry, 0, 0x80 );
}
action Elmdale() {
   modify_field( Radcliffe.Loveland, 0, 0x80 );
}
@pragma ternary 1
@pragma stage 5
table Sargent {
   reads {
      WebbCity.Rockdale : exact;
      McFaddin.valid : exact;
      Radcliffe.valid : exact;
   }
   actions {
      Humble;
      Elmdale;
   }
   size : 16;
}
action Storden(SanJon) {
   modify_field( ig_intr_md_for_tm.mcast_grp_a, 0 );
   modify_field( WebbCity.Snowball, 1 );
   modify_field( WebbCity.Trotwood, SanJon);
}
action Tanner(Kahului) {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
   modify_field( WebbCity.Trotwood, Kahului);
}
counter Seattle {
   type : packets_and_bytes;
   direct : Sanford;
   min_width: 64;
}
table Sanford {
   reads {
      Crumstown.Monico : ternary;
      Crumstown.Abilene : ternary;
      Crumstown.Lamine : ternary;
      Crumstown.Woodfield : ternary;
      Crumstown.Denhoff : ternary;
      Crumstown.Verdemont : ternary;
      Crumstown.Hansell : ternary;
      Mendon.Tunica : ternary;
      Uniontown.Basalt : ternary;
      Crumstown.Arredondo : ternary;
      Barwick.valid : ternary;
      Barwick.CoalCity : ternary;
      Crumstown.Camden : ternary;
      LaMoille.BigArm : ternary;
      Crumstown.Ramapo : ternary;
      WebbCity.FoxChase : ternary;
      WebbCity.Edgemoor : ternary;
      Waterflow.Squire mask 0xffff0000000000000000000000000000 : ternary;
      Crumstown.Petrey :ternary;
      WebbCity.Trotwood :ternary;
   }
   actions {
      Storden;
      Tanner;
      Skime;
   }
   size : 512;
}
control Knierim {
   apply( Sanford );
}
field_list Tillamook {
   Crumstown.Amory;
   WebbCity.Pittwood;
}
field_list Kinard {
   Crumstown.Amory;
   WebbCity.Pittwood;
}
field_list Caguas {
   Crozet.Raeford;
}
field_list_calculation Bechyn {
   input {
      Caguas;
   }
   algorithm : identity;
   output_width : 51;
}
field_list Ludlam {
   Crozet.Raeford;
}
field_list_calculation Heidrick {
   input {
      Ludlam;
   }
   algorithm : identity;
   output_width : 51;
}
action Verdigris( Kaltag ) {
   modify_field( Palmer.Kiron, Kaltag );
}
action Harold() {
   modify_field( Crumstown.Wheeler, 1 );
}
table Roseworth {
   reads {
      Mendon.Tunica : ternary;
      ig_intr_md.ingress_port : ternary;
      Nightmute.Rienzi : ternary;
      Nightmute.Monida : ternary;
      Beltrami.Sheldahl : ternary;
      Crumstown.Ramapo : ternary;
      Crumstown.Arredondo : ternary;
      Elmsford.Arvana : ternary;
      Elmsford.Dagsboro : ternary;
      Elmsford.valid : ternary;
      Nightmute.Clearco : ternary;
      Nightmute.Westland : ternary;
   }
   actions {
      Harold;
      Verdigris;
   }
   default_action : Verdigris(0);
   size : 1024;
}
control Swandale {
   apply( Roseworth );
}
meter Berrydale {
   type : bytes;
   static : RioHondo;
   instance_count : 128;
}
action Hermleigh( GlenDean ) {
   execute_meter( Berrydale, GlenDean, Palmer.Eastman );
}
action Bienville() {
   modify_field( Palmer.Eastman, 2 );
}
@pragma pa_alias ingress Palmer.Kiron Palmer.Merrill
@pragma pa_no_init ingress Palmer.Merrill
@pragma force_table_dependency Fosston
table RioHondo {
   reads {
      Palmer.Merrill : exact;
   }
   actions {
      Hermleigh;
      Bienville;
   }
   default_action : Bienville();
   size : 1024;
}
control Waukegan {
   apply( RioHondo );
}
action Allison() {
   clone_ingress_pkt_to_egress( Palmer.Kiron, Tillamook );
}
table Longview {
   reads {
      Palmer.Eastman : exact;
   }
   actions {
      Allison;
   }
   size : 2;
}
control Omemee {
   if( Palmer.Kiron != 0 ) {
      apply( Longview );
   }
}
action_selector Saltdale {
    selection_key : Bechyn;
    selection_mode : resilient;
}
action Russia( Reidville ) {
   bit_or( Palmer.Kiron, Palmer.Kiron, Reidville );
}
action_profile Wenatchee {
   actions {
      Russia;
   }
   size : 1024;
   dynamic_action_selection : Saltdale;
}
@pragma ternary 1
table Fosston {
   reads {
      Palmer.Kiron mask 0x7F : exact;
   }
   action_profile : Wenatchee;
   size : 128;
}
control Luzerne {
   apply( Fosston );
}
action Clarion() {
   modify_field( WebbCity.Edgemoor, 0 );
   modify_field( WebbCity.Austell, 3 );
}
action Rocklake( Sherack, Odessa, Bendavis, Keyes, Barrow, Sontag,
      Gibson, Crannell ) {
   modify_field( WebbCity.Edgemoor, 0 );
   modify_field( WebbCity.Austell, 4 );
   add_header( McFaddin );
   modify_field( McFaddin.RedCliff, 0x4);
   modify_field( McFaddin.Micro, 0x5);
   modify_field( McFaddin.Fittstown, Keyes);
   modify_field( McFaddin.Terry, 47 );
   modify_field( McFaddin.Wildell, Bendavis);
   modify_field( McFaddin.FarrWest, 0 );
   modify_field( McFaddin.Dacono, 0 );
   modify_field( McFaddin.Breese, 0 );
   modify_field( McFaddin.Temple, 0 );
   modify_field( McFaddin.Atlantic, 0 );
   modify_field( McFaddin.Elmhurst, Sherack);
   modify_field( McFaddin.Waseca, Odessa);
   add( McFaddin.Nisland, eg_intr_md.pkt_length, 15 );
   add_header( Belle );
   modify_field( Belle.Maida, Barrow);
   modify_field( WebbCity.Miranda, Sontag );
   modify_field( WebbCity.Gause, Gibson );
   modify_field( WebbCity.Stowe, Crannell );
   modify_field( WebbCity.Cassadaga, 0 );
}
action Shivwits( Kneeland ) {
   modify_field( WebbCity.Trotwood, Kneeland );
   modify_field( WebbCity.Annetta, 1 );
   modify_field( WebbCity.Edgemoor, 0 );
   modify_field( WebbCity.Austell, 2 );
   modify_field( WebbCity.Creston, 1 );
   modify_field( WebbCity.Cassadaga, 0 );
}
@pragma ternary 1
table Wapato {
   reads {
      eg_intr_md.egress_rid : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Clarion;
      Shivwits;
      Rocklake;
   }
   size : 512;
}
control Rosburg {
   apply( Wapato );
}
action Lakehills( RyanPark ) {
   modify_field( Brodnax.Algoa, RyanPark );
}
table Mission {
   reads {
      eg_intr_md.egress_port : exact;
   }
   actions {
      Lakehills;
   }
   default_action : Lakehills(0);
   size : 128;
}
control Ravenwood {
   apply( Mission );
}
action_selector Belfast {
   selection_key : Heidrick;
   selection_mode : resilient;
}
action Cozad( AukeBay ) {
   bit_or( Brodnax.Algoa, Brodnax.Algoa, AukeBay );
}
action_profile HighRock {
   actions {
      Cozad;
   }
   size : 1024;
   dynamic_action_selection : Belfast;
}
@pragma ternary 1
table Punaluu {
   reads {
      Brodnax.Algoa mask 0x7F : exact;
   }
   action_profile : HighRock;
   size : 128;
}
control Beaverdam {
   apply( Punaluu );
}
meter Maben {
   type : bytes;
   static : Melvina;
   instance_count : 128;
}
action BigRock( Monmouth ) {
   execute_meter( Maben, Monmouth, Brodnax.Emerado );
}
action Gravette() {
   modify_field( Brodnax.Emerado, 2 );
}
@pragma pa_alias egress Brodnax.Algoa Brodnax.Mumford
@pragma pa_container_size egress Brodnax.Emerado 16
@pragma ternary 1
table Melvina {
   reads {
      Brodnax.Mumford : exact;
   }
   actions {
      BigRock;
      Gravette;
   }
   default_action : Gravette();
   size : 1024;
}
control Canton {
   apply( Melvina );
}
action Herod() {
   modify_field( WebbCity.Pittwood, eg_intr_md.egress_port );
   modify_field( Crumstown.Amory, WebbCity.Wallula );
   clone_egress_pkt_to_egress( Brodnax.Algoa, Kinard );
}
table Abraham {
   actions {
      Herod;
   }
   default_action: Herod();
   size : 1;
}
control Moorman {
   if( Brodnax.Algoa != 0 and Brodnax.Emerado == 0 ) {
      apply( Abraham );
   }
}
counter Petroleum {
   type : packets;
   direct : WallLake;
   min_width: 64;
}
action Agawam() {
   drop();
}
table WallLake {
   reads {
      eg_intr_md.egress_port mask 0x7f : exact;
      Brunson.DuBois : ternary;
      Brunson.Cedar : ternary;
      Beltrami.Careywood : ternary;
      WebbCity.Grainola : ternary;
   }
   actions {
      Agawam;
      Fleetwood;
   }
   default_action : Fleetwood();
   size : 512;
}
control Willows {
   apply( WallLake ) {
      Fleetwood {
         Moorman();
      }
   }
}
counter Claysburg {
   type : packets_and_bytes;
   direct: Husum;
   min_width: 32;
}
table Husum {
   reads {
      WebbCity.Edgemoor : exact;
      Crumstown.Woodfield mask 0xfff : exact;
   }
   actions {
      Fleetwood;
   }
   default_action: Fleetwood();
   size : 0;
}
control Platina {
}
counter Karlsruhe {
   type : packets_and_bytes;
   direct: Thomas;
   min_width: 64;
}
table Thomas {
   reads {
      WebbCity.Edgemoor mask 1: exact;
      WebbCity.Wallula mask 0xfff : exact;
   }
   actions {
      Fleetwood;
   }
   default_action: Fleetwood();
   size : 0;
}
control Penalosa {
}
control ingress {
   Ovett();
   {
      apply( Fairlea );
      if( Mendon.Rardin != 0 ) {
         RedElm();
      }
      Parnell();
      Shuqualak();
      if( Mendon.Rardin != 0 ) {
         Bennet();
      }
      Silco();
      Pinetop();
      Croft();
      Menfro();
      Frederick();
      Danese();
      Cusick();
      Wright();
      Robbins();
      Arpin();
      Estero();
    Sunset();
      Berlin();
      Ovilla();
      Arminto();
      Pickett();

      apply( Seibert );


      if( Mendon.Rardin != 0 ) {
         Grandy();
      } else {
         if( valid( Tecumseh ) ) {
            Antonito();
         }
      }
      apply( Resaca );
      Abbott();
      Dorothy();
      if( WebbCity.Edgemoor != 2 ) {
         Daykin();
      }
      Pinecrest();

      Kaanapali();
      Swandale();
      Knierim();
   }

   {
      Amboy();
      Pound();
      Luzerne();
            Buckhorn();
      Bouse();
      Selby();
      Sunman();
            if( WebbCity.Snowball == 0 and
               WebbCity.Edgemoor != 2 and
               Crumstown.Delavan == 0 and
               Madison.Poulan == 0 and Madison.Basco == 0 ) {
               if( WebbCity.Chubbuck == 511 ) {
                  Eskridge();
               }
            }
      Heppner();
      Kenmore();
      Metzger();
      Castle();


      Schleswig();
      Plains();

      Waukegan();
      if( WebbCity.Snowball == 0 ) {
         RioLajas();
      }
      Ranier();
      if( WebbCity.Edgemoor == 0 or WebbCity.Edgemoor == 3 ) {
         apply(Oakford);
      }
      LoneJack();
      if( Crumstown.Mattese == 1 and Uniontown.Basalt == 0 ) {
         apply( Roachdale );
      }
      if( Mendon.Rardin != 0 ) {
         Tramway();
      }
      Brinson();

      Eureka();
      if( valid( Benkelman ) and WebbCity.Edgemoor != 2 ) {
         Sublett();
      }
      Omemee();
   }
   NewMelle();
   {
      Doerun();
      ShadeGap();


   }
}
control egress {
   {

   }
   {
      Newkirk();
      Readsboro();
      if( ( (eg_intr_md_from_parser_aux.clone_src == NOT_CLONED) ) ) {
         Hodge();
         Ravenwood();
         Ashtola();
         Criner();
         if( ( eg_intr_md.egress_rid == 0 ) and
            ( eg_intr_md.egress_port != 66 ) ) {
            Platina();
         }
         if( WebbCity.Edgemoor == 0 or WebbCity.Edgemoor == 3 ) {
            apply( Sargent );
         }
         Hawthorn();
         Canton();
         Gobles();
      } else {
         Rosburg();
      }
      Belcourt();
      if( ( (eg_intr_md_from_parser_aux.clone_src == NOT_CLONED) ) and WebbCity.Creston == 0 ) {
         Penalosa();
         if( WebbCity.Edgemoor != 2 and WebbCity.Billett == 0 ) {
            Grasmere();
         }
         if( Radcliffe.valid == 0 ) {
            Vestaburg();
         } else {
            Duelm();
         }
         Beaverdam();
         Oregon();
         CruzBay();
         Willows();
      }
      if( WebbCity.Creston == 0 and WebbCity.Edgemoor != 2 and WebbCity.Austell != 3 ) {
         Toccopola();
      }
   }
}

