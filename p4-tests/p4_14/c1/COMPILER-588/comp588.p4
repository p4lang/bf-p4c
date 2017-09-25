// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 151312

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
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
		Milnor : 1;
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
		Grapevine : 1;
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
		Punaluu : 1;
		Simnasho : 1;
		Rippon : 1;
		Surrey : 16;
		Noonan : 16;
		Newkirk : 8;
		Jefferson : 1;
		Dillsburg : 1;
	}
}
header_type Derita {
	fields {
		Piney : 24;
		Raritan : 24;
		Brainard : 24;
		Dateland : 24;
		Edinburg : 24;
		Grabill : 24;
		Nightmute : 24;
		Kirley : 24;
		Pevely : 16;
		Amherst : 16;
		Adair : 16;
		Salamatof : 16;
		Borup : 12;
		Quinnesec : 1;
		Oakville : 3;
		Naches : 1;
		Baltic : 3;
		Pioche : 1;
		Heidrick : 1;
		Jenkins : 1;
		WindGap : 1;
		Orrstown : 1;
		Rumson : 8;
		Pecos : 12;
		Nephi : 4;
		Dwight : 6;
		Chemult : 10;
		Elsey : 9;
		Alamosa : 1;
		Upson : 1;
		Campbell : 1;
		Nuevo : 1;
		Atlasburg : 1;
	}
}
header_type Tallevast {
	fields {
		Berville : 8;
		Hopland : 1;
		Swaledale : 1;
		Range : 1;
		Freeman : 1;
		SomesBar : 1;
	}
}
header_type Twinsburg {
	fields {
		Huffman : 32;
		Osterdock : 32;
		Honuapo : 6;
		Buras : 16;
	}
}
header_type Mishicot {
	fields {
		Ghent : 128;
		Farthing : 128;
		Edwards : 20;
		Perryton : 8;
		Forkville : 11;
		Wartrace : 6;
		Chevak : 13;
	}
}
header_type Diana {
	fields {
		TonkaBay : 14;
		Houston : 1;
		McClusky : 12;
		Angwin : 1;
		Daniels : 1;
		Shopville : 2;
		Oriskany : 6;
		Colson : 3;
	}
}
header_type Abilene {
	fields {
		Ferrum : 1;
		Duster : 1;
	}
}
header_type Cassadaga {
	fields {
		Wamego : 8;
	}
}
header_type Rosburg {
	fields {
		Armona : 16;
		Higganum : 11;
	}
}
header_type McKenna {
	fields {
		Gotham : 32;
		Knierim : 32;
		Milbank : 32;
	}
}
header_type Dandridge {
	fields {
		Equality : 32;
		DimeBox : 32;
	}
}
header_type Exell {
	fields {
		Boyle : 1;
		Oroville : 1;
		Lapoint : 1;
		Ocilla : 3;
		Berwyn : 1;
		Toulon : 6;
		Paoli : 5;
	}
}
header_type Shelbiana {
	fields {
		Hannibal : 16;
	}
}
header_type Milwaukie {
	fields {
		Tarlton : 14;
		Henry : 1;
		Salome : 1;
	}
}
header_type Valsetz {
	fields {
		Beaman : 14;
		Gassoway : 1;
		Kurten : 1;
	}
}
header_type Hemlock {
	fields {
		Sonora : 16;
		Winger : 16;
		Tolley : 16;
		Sawyer : 16;
		Academy : 8;
		Fairlea : 8;
		Emmalane : 8;
		LasLomas : 8;
		Shirley : 1;
		LeeCity : 6;
	}
}
header_type Baudette {
	fields {
		Livonia : 32;
	}
}
header_type Maury {
	fields {
		Fentress : 6;
		Stonefort : 10;
		Slana : 4;
		Sawpit : 12;
		Alexis : 12;
		Davisboro : 2;
		Clarkdale : 2;
		Hecker : 8;
		Havertown : 3;
		Laneburg : 5;
	}
}
header_type Pridgen {
	fields {
		McFaddin : 24;
		Staunton : 24;
		Nashua : 24;
		BigWater : 24;
		Toklat : 16;
	}
}
header_type Cannelton {
	fields {
		Gullett : 3;
		Persia : 1;
		Bunavista : 12;
		Wainaku : 16;
	}
}
header_type Beechwood {
	fields {
		Venice : 4;
		Heizer : 4;
		Frederika : 6;
		Angus : 2;
		Vieques : 16;
		Fackler : 16;
		Belmond : 3;
		Parker : 13;
		Weissert : 8;
		Lolita : 8;
		Chatanika : 16;
		Camanche : 32;
		Remsen : 32;
	}
}
header_type Uvalde {
	fields {
		Bixby : 4;
		Perrine : 6;
		LaJara : 2;
		Claiborne : 20;
		Nanson : 16;
		Purves : 8;
		FortHunt : 8;
		Patsville : 128;
		Sandoval : 128;
	}
}
header_type Glennie {
	fields {
		Leonore : 8;
		Selvin : 8;
		Cedaredge : 16;
	}
}
header_type Kinde {
	fields {
		Woodcrest : 16;
		Haslet : 16;
	}
}
header_type Clarion {
	fields {
		Seabrook : 32;
		Cecilton : 32;
		Bangor : 4;
		Willette : 4;
		Wailuku : 8;
		Moodys : 16;
		Valmont : 16;
		Weskan : 16;
	}
}
header_type Neubert {
	fields {
		Shelbina : 16;
		Batchelor : 16;
	}
}
header_type Kearns {
	fields {
		Suring : 16;
		Wimberley : 16;
		Donner : 8;
		Pengilly : 8;
		Reynolds : 16;
	}
}
header_type Arvonia {
	fields {
		Pierson : 48;
		Goodlett : 32;
		Roseau : 48;
		Wolsey : 32;
	}
}
header_type Mangham {
	fields {
		Sanatoga : 1;
		Broadford : 1;
		Rixford : 1;
		Ellicott : 1;
		Denby : 1;
		Mather : 3;
		Sylva : 5;
		Cisco : 3;
		Tenino : 16;
	}
}
header_type Colver {
	fields {
		Retrop : 24;
		BelAir : 8;
	}
}
header_type Demarest {
	fields {
		Lakefield : 8;
		Salix : 24;
		Layton : 24;
		Jeddo : 8;
	}
}
header Pridgen Elkader;
header Pridgen Leacock;
header Cannelton Hartwick[ 2 ];
@pragma pa_fragment ingress Maybee.Chatanika
@pragma pa_fragment egress Maybee.Chatanika
header Beechwood Maybee;
@pragma pa_fragment ingress Moorcroft.Chatanika
@pragma pa_fragment egress Moorcroft.Chatanika
header Beechwood Moorcroft;
header Uvalde Pickering;
header Uvalde Robbs;
header Kinde Sidon;
header Kinde Revere;
header Clarion Stone;
header Neubert Brookston;
header Clarion Puryear;
header Neubert Nipton;
header Demarest PineLake;
header Mangham FulksRun;
header Maury Hatfield;
header Pridgen BlueAsh;
parser start {
   return select(current(96, 16)) {
      0xBF00 : Langdon;
      default : Langhorne;
   }
}
parser Goudeau {
   extract( Hatfield );
   return Langhorne;
}
parser Langdon {
   extract( BlueAsh );
   return Goudeau;
}
parser Langhorne {
   extract( Elkader );
   return select( Elkader.Toklat ) {
      0x8100 : Saltdale;
      0x0800 : Phelps;
      0x86dd : LeMars;
      default : ingress;
   }
}
parser Saltdale {
   extract( Hartwick[0] );
   set_metadata(Drake.Macedonia, 1);
   return select( Hartwick[0].Wainaku ) {
      0x0800 : Phelps;
      0x86dd : LeMars;
      default : ingress;
   }
}
field_list Dizney {
    Maybee.Venice;
    Maybee.Heizer;
    Maybee.Frederika;
    Maybee.Angus;
    Maybee.Vieques;
    Maybee.Fackler;
    Maybee.Belmond;
    Maybee.Parker;
    Maybee.Weissert;
    Maybee.Lolita;
    Maybee.Camanche;
    Maybee.Remsen;
}
field_list_calculation Rankin {
    input {
        Dizney;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Maybee.Chatanika {
    verify Rankin;
    update Rankin;
}
parser Phelps {
   extract( Maybee );
   set_metadata(Drake.Gypsum, Maybee.Lolita);
   set_metadata(Drake.Hauppauge, Maybee.Weissert);
   set_metadata(Drake.Wardville, Maybee.Vieques);
   set_metadata(Drake.Donnelly, 1);
   return select(Maybee.Parker, Maybee.Heizer, Maybee.Lolita) {
      0x501 : Skillman;
      0x511 : Goree;
      0x506 : BigWells;
      0 mask 0xFF7000 : ingress;
      default : Westland;
   }
}
parser Westland {
   set_metadata(Waialee.Shirley, 1);
   return ingress;
}
parser LeMars {
   extract( Robbs );
   set_metadata(Drake.Gypsum, Robbs.Purves);
   set_metadata(Drake.Hauppauge, Robbs.FortHunt);
   set_metadata(Drake.Wardville, Robbs.Nanson);
   set_metadata(Drake.McCloud, 1);
   return select(Robbs.Purves) {
      0x3a : Skillman;
      17 : Tillatoba;
      6 : BigWells;
      default : ingress;
   }
}
parser Goree {
   extract(Sidon);
   extract(Brookston);
   return select(Sidon.Haslet) {
      4789 : Gonzalez;
      default : ingress;
    }
}
parser Skillman {
   set_metadata( Sidon.Woodcrest, current( 0, 16 ) );
   return ingress;
}
parser Tillatoba {
   extract(Sidon);
   extract(Brookston);
   return ingress;
}
parser BigWells {
   set_metadata(Tillamook.Jefferson, 1);
   extract(Sidon);
   extract(Stone);
   return ingress;
}
parser Visalia {
   set_metadata(Tillamook.Lisle, 2);
   return Sparland;
}
parser Ledger {
   set_metadata(Tillamook.Lisle, 2);
   return Quinault;
}
parser Tocito {
   extract(FulksRun);
   return select(FulksRun.Sanatoga, FulksRun.Broadford, FulksRun.Rixford, FulksRun.Ellicott, FulksRun.Denby,
             FulksRun.Mather, FulksRun.Sylva, FulksRun.Cisco, FulksRun.Tenino) {
      0x0800 : Visalia;
      0x86dd : Ledger;
      default : ingress;
   }
}
parser Gonzalez {
   extract(PineLake);
   set_metadata(Tillamook.Lisle, 1);
   return Cankton;
}
field_list Woodston {
    Moorcroft.Venice;
    Moorcroft.Heizer;
    Moorcroft.Frederika;
    Moorcroft.Angus;
    Moorcroft.Vieques;
    Moorcroft.Fackler;
    Moorcroft.Belmond;
    Moorcroft.Parker;
    Moorcroft.Weissert;
    Moorcroft.Lolita;
    Moorcroft.Camanche;
    Moorcroft.Remsen;
}
field_list_calculation Nanakuli {
    input {
        Woodston;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Moorcroft.Chatanika {
    verify Nanakuli;
    update Nanakuli;
}
parser Sparland {
   extract( Moorcroft );
   set_metadata(Drake.Storden, Moorcroft.Lolita);
   set_metadata(Drake.Cowpens, Moorcroft.Weissert);
   set_metadata(Drake.Waialua, Moorcroft.Vieques);
   set_metadata(Drake.Youngtown, 1);
   return select(Moorcroft.Parker, Moorcroft.Heizer, Moorcroft.Lolita) {
      0x501 : Wheaton;
      0x511 : Haven;
      0x506 : Parnell;
      0 mask 0xFF7000 : ingress;
      default : Ojibwa;
   }
}
parser Ojibwa {
   set_metadata(Tillamook.Eldora, 1);
   return ingress;
}
parser Quinault {
   extract( Pickering );
   set_metadata(Drake.Storden, Pickering.Purves);
   set_metadata(Drake.Cowpens, Pickering.FortHunt);
   set_metadata(Drake.Waialua, Pickering.Nanson);
   set_metadata(Drake.Sonoita, 1);
   return select(Pickering.Purves) {
      0x3a : Wheaton;
      17 : Haven;
      6 : Parnell;
      default : ingress;
   }
}
parser Wheaton {
   set_metadata( Tillamook.Surrey, current( 0, 16 ) );
   return ingress;
}
parser Haven {
   set_metadata( Tillamook.Surrey, current( 0, 16 ) );
   set_metadata( Tillamook.Noonan, current( 16, 16 ) );
   set_metadata( Tillamook.Rippon, 1 );
   return ingress;
}
parser Parnell {
   set_metadata( Tillamook.Surrey, current( 0, 16 ) );
   set_metadata( Tillamook.Noonan, current( 16, 16 ) );
   set_metadata( Tillamook.Newkirk, current( 104, 8 ) );
   set_metadata( Tillamook.Rippon, 1 );
   set_metadata( Tillamook.Dillsburg, 1 );
   return ingress;
}
parser Cankton {
   extract( Leacock );
   return select( Leacock.Toklat ) {
      0x0800: Sparland;
      0x86dd: Quinault;
      default: ingress;
   }
}
@pragma pa_no_init ingress Tillamook.Huxley
@pragma pa_no_init ingress Tillamook.Gomez
@pragma pa_no_init ingress Tillamook.Paradis
@pragma pa_no_init ingress Tillamook.Blitchton
@pragma pa_solitary ingress Tillamook.Dillsburg
@pragma pa_solitary ingress Tillamook.Eldora

#ifdef MIKE_FIX
@pragma pa_container_size ingress Tillamook.Newkirk 16
@pragma pa_container_size ingress Tillamook.Lisle 16
@pragma pa_container_size ingress Tillamook.Jefferson 16
#endif
@pragma pa_container_size ingress Tillamook.Surrey 16
metadata Coamo Tillamook;
@pragma pa_container_size ingress Wegdahl.Rumson 8
@pragma pa_no_init ingress Wegdahl.Piney
@pragma pa_no_init ingress Wegdahl.Raritan
@pragma pa_no_init ingress Wegdahl.Brainard
@pragma pa_no_init ingress Wegdahl.Dateland
metadata Derita Wegdahl;
@pragma pa_container_size ingress Wegdahl.Rumson 8
metadata Diana Daisytown;
metadata Findlay Drake;
metadata Twinsburg Terrell;
metadata Mishicot Quarry;
@pragma pa_container_size ingress ElmGrove.Duster 32
metadata Abilene ElmGrove;
metadata Tallevast Grandy;
metadata Cassadaga Braselton;
metadata Rosburg Oklahoma;
metadata Dandridge LoonLake;
metadata McKenna Paxico;
metadata Exell Empire;
metadata Shelbiana Harmony;
@pragma pa_no_init ingress Woodland.Tarlton
metadata Milwaukie Woodland;
@pragma pa_no_init ingress Desdemona.Beaman
metadata Valsetz Desdemona;

#ifdef MIKE_FIX
@pragma pa_container_size ingress Waialee.Shirley 16
#endif
metadata Hemlock Waialee;
metadata Hemlock Hammett;
action ViewPark() {
   no_op();
}
action Lucerne() {
   modify_field(Tillamook.Chatom, 1 );
   mark_for_drop();
}
action Waumandee() {
   no_op();
}
action Ericsburg(Bonilla, Needles, ElmCity, Danforth, Florida,
                 Longville, Holcomb, Paisano) {
    modify_field(Daisytown.TonkaBay, Bonilla);
    modify_field(Daisytown.Houston, Needles);
    modify_field(Daisytown.McClusky, ElmCity);
    modify_field(Daisytown.Angwin, Danforth);
    modify_field(Daisytown.Daniels, Florida);
    modify_field(Daisytown.Shopville, Longville);
    modify_field(Daisytown.Colson, Holcomb);
    modify_field(Daisytown.Oriskany, Paisano);
}

@pragma command_line --no-dead-code-elimination
table Silvertip {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Ericsburg;
    }
    size : 288;
}
control Wiota {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Silvertip);
    }
}
action Troup(Lithonia, Walland) {
   modify_field( Wegdahl.Naches, 1 );
   modify_field( Wegdahl.Rumson, Lithonia);
   modify_field( Tillamook.Gause, 1 );
   modify_field( Empire.Lapoint, Walland );
}
action Craigmont() {
   modify_field( Tillamook.Greendale, 1 );
   modify_field( Tillamook.Hanford, 1 );
}
action Lordstown() {
   modify_field( Tillamook.Gause, 1 );
}
action Longdale() {
   modify_field( Tillamook.Gause, 1 );
   modify_field( Tillamook.Perryman, 1 );
}
action Gamaliel() {
   modify_field( Tillamook.Corinne, 1 );
}
action Micro() {
   modify_field( Tillamook.Hanford, 1 );
}
counter Malesus {
   type : packets_and_bytes;
   direct : Flippen;
   min_width: 16;
}
table Flippen {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Elkader.McFaddin : ternary;
      Elkader.Staunton : ternary;
   }
   actions {
      Troup;
      Craigmont;
      Lordstown;
      Gamaliel;
      Micro;
      Longdale;
   }
   size : 1024;
}
action Dorris() {
   modify_field( Tillamook.Parkway, 1 );
}
table Gibbstown {
   reads {
      Elkader.Nashua : ternary;
      Elkader.BigWater : ternary;
   }
   actions {
      Dorris;
   }
   size : 512;
}
control Norseland {
   apply( Flippen );
   apply( Gibbstown );
}
action Northway() {
   modify_field( Terrell.Huffman, Moorcroft.Camanche );
   modify_field( Terrell.Osterdock, Moorcroft.Remsen );
   modify_field( Terrell.Honuapo, Moorcroft.Frederika );
   modify_field( Quarry.Ghent, Pickering.Patsville );
   modify_field( Quarry.Farthing, Pickering.Sandoval );
   modify_field( Quarry.Edwards, Pickering.Claiborne );
   modify_field( Quarry.Wartrace, Pickering.Perrine );
   modify_field( Tillamook.Huxley, Leacock.McFaddin );
   modify_field( Tillamook.Gomez, Leacock.Staunton );
   modify_field( Tillamook.Paradis, Leacock.Nashua );
   modify_field( Tillamook.Blitchton, Leacock.BigWater );
   modify_field( Tillamook.Reddell, Leacock.Toklat );
   modify_field( Tillamook.Mossville, Drake.Waialua );
   modify_field( Tillamook.Cliffs, Drake.Storden );
   modify_field( Tillamook.McDermott, Drake.Cowpens );
   modify_field( Tillamook.Everton, Drake.Youngtown );
   modify_field( Tillamook.Grapevine, Drake.Sonoita );
   modify_field( Tillamook.Punaluu, 0 );
   modify_field( Wegdahl.Baltic, 1 );
   modify_field( Daisytown.Shopville, 1 );
   modify_field( Daisytown.Colson, 0 );
   modify_field( Daisytown.Oriskany, 0 );
   modify_field( Empire.Boyle, 1 );
   modify_field( Empire.Oroville, 1 );
   modify_field( Waialee.Shirley, Tillamook.Eldora );
   modify_field( Tillamook.Jefferson, Tillamook.Dillsburg );
   modify_field( Waialee.Tolley, Tillamook.Surrey );
}
action Aiken() {
   modify_field( Tillamook.Lisle, 0 );
   modify_field( Terrell.Huffman, Maybee.Camanche );
   modify_field( Terrell.Osterdock, Maybee.Remsen );
   modify_field( Terrell.Honuapo, Maybee.Frederika );
   modify_field( Quarry.Ghent, Robbs.Patsville );
   modify_field( Quarry.Farthing, Robbs.Sandoval );
   modify_field( Quarry.Edwards, Robbs.Claiborne );
   modify_field( Quarry.Wartrace, Robbs.Perrine );
   modify_field( Tillamook.Huxley, Elkader.McFaddin );
   modify_field( Tillamook.Gomez, Elkader.Staunton );
   modify_field( Tillamook.Paradis, Elkader.Nashua );
   modify_field( Tillamook.Blitchton, Elkader.BigWater );
   modify_field( Tillamook.Reddell, Elkader.Toklat );
   modify_field( Tillamook.Mossville, Drake.Wardville );
   modify_field( Tillamook.Cliffs, Drake.Gypsum );
   modify_field( Tillamook.McDermott, Drake.Hauppauge );
   modify_field( Tillamook.Everton, Drake.Donnelly );
   modify_field( Tillamook.Grapevine, Drake.McCloud );
   modify_field( Empire.Berwyn, Hartwick[0].Persia );
   modify_field( Tillamook.Punaluu, Drake.Macedonia );
   modify_field( Waialee.Tolley, Sidon.Woodcrest );
   modify_field( Tillamook.Surrey, Sidon.Woodcrest );
   modify_field( Tillamook.Noonan, Sidon.Haslet );
   modify_field( Tillamook.Newkirk, Stone.Wailuku );
}
table Ancho {
   reads {
      Elkader.McFaddin : exact;
      Elkader.Staunton : exact;
      Maybee.Remsen : exact;
      Tillamook.Lisle : exact;
   }
   actions {
      Northway;
      Aiken;
   }
   default_action : Aiken();
   size : 1024;
}
action Brodnax() {
   modify_field( Tillamook.DewyRose, Daisytown.McClusky );
   modify_field( Tillamook.Blossom, Daisytown.TonkaBay);
}
action Pardee( Pasadena ) {
   modify_field( Tillamook.DewyRose, Pasadena );
   modify_field( Tillamook.Blossom, Daisytown.TonkaBay);
}
action Croghan() {
   modify_field( Tillamook.DewyRose, Hartwick[0].Bunavista );
   modify_field( Tillamook.Blossom, Daisytown.TonkaBay);
}
table Paradise {
   reads {
      Daisytown.TonkaBay : ternary;
      Hartwick[0] : valid;
      Hartwick[0].Bunavista : ternary;
   }
   actions {
      Brodnax;
      Pardee;
      Croghan;
   }
   size : 4096;
}
action Brookwood( Cache ) {
   modify_field( Tillamook.Blossom, Cache );
}
action Holden() {
   modify_field( Tillamook.Maybeury, 1 );
   modify_field( Braselton.Wamego,
                 1 );
}
table Selby {
   reads {
      Maybee.Camanche : exact;
   }
   actions {
      Brookwood;
      Holden;
   }
   default_action : Holden;
   size : 4096;
}
action Virgilina( Olyphant, Salitpa, Corinth, Bayville, Separ,
                        Cornell, Ridgetop ) {
   modify_field( Tillamook.DewyRose, Olyphant );
   modify_field( Tillamook.Deferiet, Olyphant );
   modify_field( Tillamook.Blanchard, Ridgetop );
   Gamewell(Salitpa, Corinth, Bayville, Separ,
                        Cornell );
}
action SweetAir() {
   modify_field( Tillamook.Albemarle, 1 );
}
table Halley {
   reads {
      PineLake.Layton : exact;
   }
   actions {
      Virgilina;
      SweetAir;
   }
   size : 4096;
}
action Gamewell(Mikkalo, Sparr, Verdemont, BullRun,
                        Bellport ) {
   modify_field( Grandy.Berville, Mikkalo );
   modify_field( Grandy.Hopland, Sparr );
   modify_field( Grandy.Range, Verdemont );
   modify_field( Grandy.Swaledale, BullRun );
   modify_field( Grandy.Freeman, Bellport );
}
action Floral(Garcia, Ladoga, Finlayson, Tabler,
                        Peebles ) {
   modify_field( Tillamook.Deferiet, Daisytown.McClusky );
   Gamewell(Garcia, Ladoga, Finlayson, Tabler,
                        Peebles );
}
action Palco(Wyndmere, Martelle, WestBay, Keenes,
                        DonaAna, Cairo ) {
   modify_field( Tillamook.Deferiet, Wyndmere );
   Gamewell(Martelle, WestBay, Keenes, DonaAna,
                        Cairo );
}
action Kaeleku(Astor, Uniontown, Plandome, Sherack,
                        FoxChase ) {
   modify_field( Tillamook.Deferiet, Hartwick[0].Bunavista );
   Gamewell(Astor, Uniontown, Plandome, Sherack,
                        FoxChase );
}
table Kaufman {
   reads {
      Daisytown.McClusky : exact;
   }
   actions {
      ViewPark;
      Floral;
   }
   size : 4096;
}
@pragma action_default_only ViewPark
table Trooper {
   reads {
      Daisytown.TonkaBay : exact;
      Hartwick[0].Bunavista : exact;
   }
   actions {
      Palco;
      ViewPark;
   }
   size : 1024;
}
table Jackpot {
   reads {
      Hartwick[0].Bunavista : exact;
   }
   actions {
      ViewPark;
      Kaeleku;
   }
   size : 4096;
}
control Vevay {
   apply( Ancho ) {
         Northway {
            apply( Selby );
            apply( Halley );
         }
         Aiken {
            if ( not valid(Hatfield) and Daisytown.Angwin == 1 ) {
               apply( Paradise );
            }
            if ( valid( Hartwick[ 0 ] ) ) {
               apply( Trooper ) {
                  ViewPark {
                     apply( Jackpot );
                  }
               }
            } else {
               apply( Kaufman );
            }
         }
   }
}
register Bennet {
    width : 1;
    static : Kathleen;
    instance_count : 294912;
}
register OldMinto {
    width : 1;
    static : Beresford;
    instance_count : 294912;
}
blackbox stateful_alu Bramwell {
    reg : Bennet;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : ElmGrove.Ferrum;
}
blackbox stateful_alu Colonias {
    reg : OldMinto;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst : ElmGrove.Duster;
}
field_list Waldport {
    ig_intr_md.ingress_port;
    Hartwick[0].Bunavista;
}
field_list_calculation Crannell {
    input { Waldport; }
    algorithm: identity;
    output_width: 19;
}
action Bosler() {
    Bramwell.execute_stateful_alu_from_hash(Crannell);
}
action Warsaw() {
    Colonias.execute_stateful_alu_from_hash(Crannell);
}
table Kathleen {
    actions {
      Bosler;
    }
    default_action : Bosler;
    size : 1;
}
table Beresford {
    actions {
      Warsaw;
    }
    default_action : Warsaw;
    size : 1;
}
action Bleecker(Owentown) {
    modify_field(ElmGrove.Duster, Owentown);
}
@pragma use_hash_action 0
table Motley {
    reads {
       ig_intr_md.ingress_port mask 0x7f : exact;
    }
    actions {
      Bleecker;
    }
    size : 72;
}
action Tappan() {
   modify_field( Tillamook.Hobart, Daisytown.McClusky );
   modify_field( Tillamook.Goulds, 0 );
}
table Juneau {
   actions {
      Tappan;
   }
   size : 1;
}
action Dunnegan() {
   modify_field( Tillamook.Hobart, Hartwick[0].Bunavista );
   modify_field( Tillamook.Goulds, 1 );
}
table Springlee {
   actions {
      Dunnegan;
   }
   size : 1;
}
control Giltner {
   if ( valid( Hartwick[ 0 ] ) ) {
      apply( Springlee );
      if( Daisytown.Daniels == 1 ) {
         apply( Kathleen );
         apply( Beresford );
      }
   } else {
      apply( Juneau );
      if( Daisytown.Daniels == 1 ) {
         apply( Motley );
      }
   }
}
field_list ElMango {
   Elkader.McFaddin;
   Elkader.Staunton;
   Elkader.Nashua;
   Elkader.BigWater;
   Elkader.Toklat;
}
field_list Stehekin {
   Maybee.Lolita;
   Maybee.Camanche;
   Maybee.Remsen;
}
field_list Eddington {
   Robbs.Patsville;
   Robbs.Sandoval;
   Robbs.Claiborne;
   Robbs.Purves;
}
field_list Mayflower {
   Maybee.Camanche;
   Maybee.Remsen;
   Sidon.Woodcrest;
   Sidon.Haslet;
}
field_list_calculation Kotzebue {
    input {
        ElMango;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Sodaville {
    input {
        Stehekin;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Subiaco {
    input {
        Eddington;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Weslaco {
    input {
        Mayflower;
    }
    algorithm : crc32;
    output_width : 32;
}
action Hookdale() {
    modify_field_with_hash_based_offset(Paxico.Gotham, 0,
                                        Kotzebue, 4294967296);
}
action DeKalb() {
    modify_field_with_hash_based_offset(Paxico.Knierim, 0,
                                        Sodaville, 4294967296);
}
action Cotter() {
    modify_field_with_hash_based_offset(Paxico.Knierim, 0,
                                        Subiaco, 4294967296);
}
action Sieper() {
    modify_field_with_hash_based_offset(Paxico.Milbank, 0,
                                        Weslaco, 4294967296);
}
table Hewitt {
   actions {
      Hookdale;
   }
   size: 1;
}
control Gibsland {
   apply(Hewitt);
}
table Neponset {
   actions {
      DeKalb;
   }
   size: 1;
}
table Jayton {
   actions {
      Cotter;
   }
   size: 1;
}
control Blackman {
   if ( valid( Maybee ) ) {
      apply(Neponset);
   } else {
      if ( valid( Robbs ) ) {
         apply(Jayton);
      }
   }
}
table Greenbush {
   actions {
      Sieper;
   }
   size: 1;
}
control Stewart {
   if ( valid( Brookston ) ) {
      apply(Greenbush);
   }
}
action Yerington() {
    modify_field(LoonLake.Equality, Paxico.Gotham);
}
action Hayfield() {
    modify_field(LoonLake.Equality, Paxico.Knierim);
}
action Harding() {
    modify_field(LoonLake.Equality, Paxico.Milbank);
}
@pragma action_default_only ViewPark
@pragma immediate 0
table Rehobeth {
   reads {
      Puryear.valid : ternary;
      Nipton.valid : ternary;
      Moorcroft.valid : ternary;
      Pickering.valid : ternary;
      Leacock.valid : ternary;
      Stone.valid : ternary;
      Brookston.valid : ternary;
      Maybee.valid : ternary;
      Robbs.valid : ternary;
      Elkader.valid : ternary;
   }
   actions {
      Yerington;
      Hayfield;
      Harding;
      ViewPark;
   }
   size: 256;
}
action Westvaco() {
    modify_field(LoonLake.DimeBox, Paxico.Milbank);
}
@pragma immediate 0
table Poteet {
   reads {
      Puryear.valid : ternary;
      Nipton.valid : ternary;
      Stone.valid : ternary;
      Brookston.valid : ternary;
   }
   actions {
      Westvaco;
      ViewPark;
   }
   size: 6;
}
control Laurelton {
   apply(Poteet);
   apply(Rehobeth);
}
counter Commack {
   type : packets_and_bytes;
   direct : WestBend;
   min_width: 16;
}
table WestBend {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      ElmGrove.Duster : ternary;
      ElmGrove.Ferrum : ternary;
      Tillamook.Albemarle : ternary;
      Tillamook.Parkway : ternary;
      Tillamook.Greendale : ternary;
   }
   actions {
      Lucerne;
      ViewPark;
   }
   default_action : ViewPark();
   size : 512;
}
table Manasquan {
   reads {
      Tillamook.Paradis : exact;
      Tillamook.Blitchton : exact;
      Tillamook.DewyRose : exact;
   }
   actions {
      Lucerne;
      ViewPark;
   }
   default_action : ViewPark();
   size : 4096;
}
action Sawmills() {
   modify_field(Tillamook.Sylvester, 1 );
   modify_field(Braselton.Wamego,
                0);
}
table Glenside {
   reads {
      Tillamook.Paradis : exact;
      Tillamook.Blitchton : exact;
      Tillamook.DewyRose : exact;
      Tillamook.Blossom : exact;
   }
   actions {
      Waumandee;
      Sawmills;
   }
   default_action : Sawmills();
   size : 65536;
   support_timeout : true;
}
action Talkeetna( Delavan, Centre ) {
   modify_field( Tillamook.Simnasho, Delavan );
   modify_field( Tillamook.Blanchard, Centre );
}
action Lilydale() {
   modify_field( Tillamook.Blanchard, 1 );
}
table Admire {
   reads {
      Tillamook.DewyRose mask 0xfff : exact;
   }
   actions {
      Talkeetna;
      Lilydale;
      ViewPark;
   }
   default_action : ViewPark();
   size : 4096;
}
action Dialville() {
   modify_field( Grandy.SomesBar, 1 );
}
table Wellton {
   reads {
      Tillamook.Deferiet : ternary;
      Tillamook.Huxley : exact;
      Tillamook.Gomez : exact;
   }
   actions {
      Dialville;
   }
   size: 512;
}
control Machens {
   apply( WestBend ) {
      ViewPark {
         apply( Manasquan ) {
            ViewPark {
               if (Daisytown.Houston == 0 and Tillamook.Maybeury == 0) {
                  apply( Glenside );
               }
               apply( Admire );
               apply(Wellton);
            }
         }
      }
   }
}
field_list Escatawpa {
    Braselton.Wamego;
    Tillamook.Paradis;
    Tillamook.Blitchton;
    Tillamook.DewyRose;
    Tillamook.Blossom;
}
action Reidland() {
   generate_digest(0, Escatawpa);
}
table Filley {
   actions {
      Reidland;
   }
   size : 1;
}
control Biloxi {
   if (Tillamook.Sylvester == 1) {
      apply( Filley );
   }
}
action Orrick( Altadena, LaLuz ) {
   modify_field( Quarry.Chevak, Altadena );
   modify_field( Oklahoma.Armona, LaLuz );
}
action Ribera( RedCliff, Hueytown ) {
   modify_field( Quarry.Chevak, RedCliff );
   modify_field( Oklahoma.Higganum, Hueytown );
}
@pragma action_default_only Chalco
table Spearman {
   reads {
      Grandy.Berville : exact;
      Quarry.Farthing mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Orrick;
      Chalco;
      Ribera;
   }
   size : 8192;
}
@pragma atcam_partition_index Quarry.Chevak
@pragma atcam_number_partitions 8192
table Kingsland {
   reads {
      Quarry.Chevak : exact;
      Quarry.Farthing mask 0x000007FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Ladner;
      Hennessey;
      ViewPark;
   }
   default_action : ViewPark();
   size : 65536;
}
action Marley( Globe, Virginia ) {
   modify_field( Quarry.Forkville, Globe );
   modify_field( Oklahoma.Armona, Virginia );
}
action Braxton( Canalou, Wickett ) {
   modify_field( Quarry.Forkville, Canalou );
   modify_field( Oklahoma.Higganum, Wickett );
}
@pragma action_default_only ViewPark
table Baker {
   reads {
      Grandy.Berville : exact;
      Quarry.Farthing : lpm;
   }
   actions {
      Marley;
      Braxton;
      ViewPark;
   }
   size : 2048;
}
@pragma atcam_partition_index Quarry.Forkville
@pragma atcam_number_partitions 2048
table Veteran {
   reads {
      Quarry.Forkville : exact;
      Quarry.Farthing mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Ladner;
      Hennessey;
      ViewPark;
   }
   default_action : ViewPark();
   size : 16384;
}
@pragma action_default_only Chalco
@pragma idletime_precision 1
table Parkland {
   reads {
      Grandy.Berville : exact;
      Terrell.Osterdock : lpm;
   }
   actions {
      Ladner;
      Hennessey;
      Chalco;
   }
   size : 1024;
   support_timeout : true;
}
action Oilmont( Joplin, Lydia ) {
   modify_field( Terrell.Buras, Joplin );
   modify_field( Oklahoma.Armona, Lydia );
}
action Alzada( Paulette, Auvergne ) {
   modify_field( Terrell.Buras, Paulette );
   modify_field( Oklahoma.Higganum, Auvergne );
}
@pragma action_default_only ViewPark
table Jelloway {
   reads {
      Grandy.Berville : exact;
      Terrell.Osterdock : lpm;
   }
   actions {
      Oilmont;
      Alzada;
      ViewPark;
   }
   size : 16384;
}
@pragma ways 2
@pragma atcam_partition_index Terrell.Buras
@pragma atcam_number_partitions 16384
table Tonasket {
   reads {
      Terrell.Buras : exact;
      Terrell.Osterdock mask 0x000fffff : lpm;
   }
   actions {
      Ladner;
      Hennessey;
      ViewPark;
   }
   default_action : ViewPark();
   size : 131072;
}
action Ladner( Cutten ) {
   modify_field( Oklahoma.Armona, Cutten );
}
@pragma idletime_precision 1
table Haverford {
   reads {
      Grandy.Berville : exact;
      Terrell.Osterdock : exact;
   }
   actions {
      Ladner;
      Hennessey;
      ViewPark;
   }
   default_action : ViewPark();
   size : 65536;
   support_timeout : true;
}
@pragma idletime_precision 1
@pragma stage 2 28672
@pragma stage 3
table Baidland {
   reads {
      Grandy.Berville : exact;
      Quarry.Farthing : exact;
   }
   actions {
      Ladner;
      Hennessey;
      ViewPark;
   }
   default_action : ViewPark();
   size : 65536;
   support_timeout : true;
}
action Brantford(OldMines, Telma, Wanatah) {
   modify_field(Wegdahl.Pevely, Wanatah);
   modify_field(Wegdahl.Piney, OldMines);
   modify_field(Wegdahl.Raritan, Telma);
   modify_field(Wegdahl.Alamosa, 1);
   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}
action Arriba() {
   Lucerne();
}
action Swain(Bayport) {
   modify_field(Wegdahl.Naches, 1);
   modify_field(Wegdahl.Rumson, Bayport);
}
action Chalco(Fitler) {
   modify_field(Oklahoma.Armona, Fitler);
}
table Wallace {
   reads {
      Oklahoma.Armona : exact;
   }
   actions {
      Brantford;
      Arriba;
      Swain;
   }
   size : 65536;
}
action CityView(Cordell) {
   modify_field(Oklahoma.Armona, Cordell);
}
table Peosta {
   actions {
      CityView;
   }
   default_action: CityView(0);
   size : 1;
}
control Metter {
   if ( Tillamook.Chatom == 0 and Grandy.SomesBar == 1 ) {
      if ( ( Grandy.Hopland == 1 ) and ( Tillamook.Everton == 1 ) ) {
         apply( Haverford ) {
            ViewPark {
               apply(Jelloway);
            }
         }
      } else if ( ( Grandy.Range == 1 ) and ( Tillamook.Grapevine == 1 ) ) {
         apply( Baidland ) {
            ViewPark {
               apply( Baker );
            }
         }
      }
   }
}
control Pineridge {
   if ( Tillamook.Chatom == 0 and Grandy.SomesBar == 1 ) {
      if ( ( Grandy.Hopland == 1 ) and ( Tillamook.Everton == 1 ) ) {
         if ( Terrell.Buras != 0 ) {
            apply( Tonasket );
         } else if ( Oklahoma.Armona == 0 and Oklahoma.Higganum == 0 ) {
            apply( Parkland );
         }
      } else if ( ( Grandy.Range == 1 ) and ( Tillamook.Grapevine == 1 ) ) {
         if ( Quarry.Forkville != 0 ) {
            apply( Veteran );
         } else if ( Oklahoma.Armona == 0 and Oklahoma.Higganum == 0 ) {
            apply( Spearman );
            if ( Quarry.Chevak != 0 ) {
               apply( Kingsland );
            }
         }
      } else if( Tillamook.Blanchard == 1 ) {
         apply( Peosta );
      }
   }
}
control Blakeslee {
   if( Oklahoma.Armona != 0 ) {
      apply( Wallace );
   }
}
action Hennessey( Lacona ) {
   modify_field( Oklahoma.Higganum, Lacona );
}
field_list Ottertail {
   LoonLake.DimeBox;
}
field_list_calculation Bondad {
    input {
        Ottertail;
    }
    algorithm : identity;
    output_width : 66;
}
action_selector Johnsburg {
   selection_key : Bondad;
   selection_mode : resilient;
}
action_profile WoodDale {
   actions {
      Ladner;
   }
   size : 65536;
   dynamic_action_selection : Johnsburg;
}
@pragma selector_max_group_size 256
table Arcanum {
   reads {
      Oklahoma.Higganum : exact;
   }
   action_profile : WoodDale;
   size : 2048;
}
control Driftwood {
   if ( Oklahoma.Higganum != 0 ) {
      apply( Arcanum );
   }
}
field_list Jarreau {
   LoonLake.Equality;
}
field_list_calculation Tonkawa {
    input {
        Jarreau;
    }
    algorithm : identity;
    output_width : 51;
}
action_selector RioPecos {
    selection_key : Tonkawa;
    selection_mode : resilient;
}
action Chappell(Cullen) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Cullen);
}
action_profile Pittsboro {
    actions {
        Chappell;
        ViewPark;
    }
    size : 1024;
    dynamic_action_selection : RioPecos;
}
table Sabetha {
   reads {
      Wegdahl.Adair : exact;
   }
   action_profile: Pittsboro;
   size : 1024;
}
control WolfTrap {
   if ((Wegdahl.Adair & 0x2000) == 0x2000) {
      apply(Sabetha);
   }
}
action RockyGap() {
   modify_field(Wegdahl.Piney, Tillamook.Huxley);
   modify_field(Wegdahl.Raritan, Tillamook.Gomez);
   modify_field(Wegdahl.Brainard, Tillamook.Paradis);
   modify_field(Wegdahl.Dateland, Tillamook.Blitchton);
   modify_field(Wegdahl.Pevely, Tillamook.DewyRose);
   invalidate( ig_intr_md_for_tm.ucast_egress_port );
}
table Cloverly {
   actions {
      RockyGap;
   }
   default_action : RockyGap();
   size : 1;
}
control Papeton {
   apply( Cloverly );
}
action ElPrado() {
   modify_field(Wegdahl.Pioche, 1);
   modify_field(Wegdahl.Nuevo, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Tillamook.Blanchard);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Wegdahl.Pevely);
}
action Depew() {
}
@pragma ways 1
table Pilar {
   reads {
      Wegdahl.Piney : exact;
      Wegdahl.Raritan : exact;
   }
   actions {
      ElPrado;
      Depew;
   }
   default_action : Depew;
   size : 1;
}
action Sebewaing() {
   modify_field(Wegdahl.Heidrick, 1);
   modify_field(Wegdahl.Orrstown, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Wegdahl.Pevely, 4096);
}
table LeSueur {
   actions {
      Sebewaing;
   }
   default_action : Sebewaing;
   size : 1;
}
action Kaltag() {
   modify_field(Wegdahl.WindGap, 1);
   modify_field(Wegdahl.Nuevo, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Wegdahl.Pevely);
}
table Ranburne {
   actions {
      Kaltag;
   }
   default_action : Kaltag();
   size : 1;
}
action Endeavor(Fannett) {
   modify_field(Wegdahl.Jenkins, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Fannett);
   modify_field(Wegdahl.Adair, Fannett);
}
action Boerne(Hayfork) {
   modify_field(Wegdahl.Heidrick, 1);
   modify_field(Wegdahl.Salamatof, Hayfork);
}
action Wauconda() {
}
table Francis {
   reads {
      Wegdahl.Piney : exact;
      Wegdahl.Raritan : exact;
      Wegdahl.Pevely : exact;
   }
   actions {
      Endeavor;
      Boerne;
      Lucerne;
      Wauconda;
   }
   default_action : Wauconda();
   size : 65536;
}
control PawPaw {
   if (Tillamook.Chatom == 0 and not valid(Hatfield) ) {
      apply(Francis) {
         Wauconda {
            apply(Pilar) {
               Depew {
                  if ((Wegdahl.Piney & 0x010000) == 0x010000) {
                     apply(LeSueur);
                  } else {
                     apply(Ranburne);
                  }
               }
            }
         }
      }
   }
}
action Albin() {
   modify_field(Tillamook.Abernathy, 1);
   Lucerne();
}
table LaUnion {
   actions {
      Albin;
   }
   default_action : Albin;
   size : 1;
}
control Edinburgh {
   if (Tillamook.Chatom == 0) {
      if ((Wegdahl.Alamosa==0) and (Tillamook.Gause==0) and (Tillamook.Corinne==0) and (Tillamook.Blossom==Wegdahl.Adair)) {
         apply(LaUnion);
      } else {
         WolfTrap();
      }
   }
}
action Pearland( Monsey ) {
   modify_field( Wegdahl.Borup, Monsey );
}
action Ivanpah() {
   modify_field( Wegdahl.Borup, Wegdahl.Pevely );
}
table NewAlbin {
   reads {
      eg_intr_md.egress_port : exact;
      Wegdahl.Pevely : exact;
   }
   actions {
      Pearland;
      Ivanpah;
   }
   default_action : Ivanpah;
   size : 4096;
}
control Kalvesta {
   apply( NewAlbin );
}
action Kremlin( Lynndyl, Hobson ) {
   modify_field( Wegdahl.Edinburg, Lynndyl );
   modify_field( Wegdahl.Grabill, Hobson );
}
table Mecosta {
   reads {
      Wegdahl.Oakville : exact;
   }
   actions {
      Kremlin;
   }
   size : 8;
}
action Mango() {
   modify_field( Wegdahl.Upson, 1 );
   modify_field( Wegdahl.Oakville, 2 );
}
action Rodeo() {
   modify_field( Wegdahl.Upson, 1 );
   modify_field( Wegdahl.Oakville, 1 );
}
table Waterfall {
   reads {
      Wegdahl.Quinnesec : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Mango;
      Rodeo;
   }
   default_action : ViewPark();
   size : 16;
}
action Kaupo(Nashwauk, Grantfork, Eastman, Ringwood) {
   modify_field( Wegdahl.Dwight, Nashwauk );
   modify_field( Wegdahl.Chemult, Grantfork );
   modify_field( Wegdahl.Nephi, Eastman );
   modify_field( Wegdahl.Pecos, Ringwood );
}
table Ammon {
   reads {
        Wegdahl.Elsey : exact;
   }
   actions {
      Kaupo;
   }
   size : 256;
}
action Salus() {
   no_op();
}
action Talmo() {
   modify_field( Elkader.Toklat, Hartwick[0].Wainaku );
   remove_header( Hartwick[0] );
}
table Cabot {
   actions {
      Talmo;
   }
   default_action : Talmo;
   size : 1;
}
action Bicknell() {
   no_op();
}
action Basalt() {
   add_header( Hartwick[ 0 ] );
   modify_field( Hartwick[0].Bunavista, Wegdahl.Borup );
   modify_field( Hartwick[0].Wainaku, Elkader.Toklat );
   modify_field( Hartwick[0].Gullett, Empire.Ocilla );
   modify_field( Hartwick[0].Persia, Empire.Berwyn );
   modify_field( Elkader.Toklat, 0x8100 );
}
table Adamstown {
   reads {
      Wegdahl.Borup : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Bicknell;
      Basalt;
   }
   default_action : Basalt;
   size : 128;
}
action Hillcrest() {
   modify_field(Elkader.McFaddin, Wegdahl.Piney);
   modify_field(Elkader.Staunton, Wegdahl.Raritan);
   modify_field(Elkader.Nashua, Wegdahl.Edinburg);
   modify_field(Elkader.BigWater, Wegdahl.Grabill);
}
action Jonesport() {
   Hillcrest();
   add_to_field(Maybee.Weissert, -1);
   modify_field(Maybee.Frederika, Empire.Toulon);
}
action LaFayette() {
   Hillcrest();
   add_to_field(Robbs.FortHunt, -1);
   modify_field(Robbs.Perrine, Empire.Toulon);
}
action Orting() {
   modify_field(Maybee.Frederika, Empire.Toulon);
}
action Opelika() {
   modify_field(Robbs.Perrine, Empire.Toulon);
}
action Langlois() {
   Basalt();
}
action Fireco( Nicolaus, Sutherlin, Vallecito, Trona ) {
   add_header( BlueAsh );
   modify_field( BlueAsh.McFaddin, Nicolaus );
   modify_field( BlueAsh.Staunton, Sutherlin );
   modify_field( BlueAsh.Nashua, Vallecito );
   modify_field( BlueAsh.BigWater, Trona );
   modify_field( BlueAsh.Toklat, 0xBF00 );
   add_header( Hatfield );
   modify_field( Hatfield.Fentress, Wegdahl.Dwight );
   modify_field( Hatfield.Stonefort, Wegdahl.Chemult );
   modify_field( Hatfield.Slana, Wegdahl.Nephi );
   modify_field( Hatfield.Sawpit, Wegdahl.Pecos );
   modify_field( Hatfield.Hecker, Wegdahl.Rumson );
}
action MiraLoma() {
   remove_header( PineLake );
   remove_header( Brookston );
   remove_header( Sidon );
   copy_header( Elkader, Leacock );
   remove_header( Leacock );
   remove_header( Maybee );
}
action Algonquin() {
   remove_header( BlueAsh );
   remove_header( Hatfield );
}
action Kisatchie() {
   MiraLoma();
   modify_field(Moorcroft.Frederika, Empire.Toulon);
}
action Craig() {
   MiraLoma();
   modify_field(Pickering.Perrine, Empire.Toulon);
}
table Fernway {
   reads {
      Wegdahl.Baltic : exact;
      Wegdahl.Oakville : exact;
      Wegdahl.Alamosa : exact;
      Maybee.valid : ternary;
      Robbs.valid : ternary;
      Moorcroft.valid : ternary;
      Pickering.valid : ternary;
   }
   actions {
      Jonesport;
      LaFayette;
      Orting;
      Opelika;
      Langlois;
      Fireco;
      Algonquin;
      MiraLoma;
      Kisatchie;
      Craig;
   }
   size : 512;
}
control Magnolia {
   apply( Cabot );
}
control Fallis {
   apply( Adamstown );
}
control Minoa {
   apply( Waterfall ) {
      ViewPark {
         apply( Mecosta );
      }
   }
   apply( Ammon );
   apply( Fernway );
}
field_list Petrolia {
    Braselton.Wamego;
    Tillamook.DewyRose;
    Leacock.Nashua;
    Leacock.BigWater;
    Maybee.Camanche;
}
action Burmester() {
   generate_digest(0, Petrolia);
}
table Honobia {
   actions {
      Burmester;
   }
   default_action : Burmester;
   size : 1;
}
control Weches {
   if (Tillamook.Maybeury == 1) {
      apply(Honobia);
   }
}
action Shongaloo() {
   modify_field( Empire.Ocilla, Daisytown.Colson );
}
action Licking() {
   modify_field( Empire.Ocilla, Hartwick[0].Gullett );
   modify_field( Tillamook.Reddell, Hartwick[0].Wainaku );
}
action ElkFalls() {
   modify_field( Empire.Toulon, Daisytown.Oriskany );
}
action Masontown() {
   modify_field( Empire.Toulon, Terrell.Honuapo );
}
action Aquilla() {
   modify_field( Empire.Toulon, Quarry.Wartrace );
}
action RedBay( Piermont, Maybell ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Piermont );
   modify_field( ig_intr_md_for_tm.qid, Maybell );
}
table Soledad {
   reads {
     Tillamook.Punaluu : exact;
   }
   actions {
     Shongaloo;
     Licking;
   }
   size : 2;
}
table Halltown {
   reads {
     Tillamook.Everton : exact;
     Tillamook.Grapevine : exact;
   }
   actions {
     ElkFalls;
     Masontown;
     Aquilla;
   }
   size : 3;
}
table Grants {
   reads {
      Daisytown.Shopville : ternary;
      Daisytown.Colson : ternary;
      Empire.Ocilla : ternary;
      Empire.Toulon : ternary;
      Empire.Lapoint : ternary;
   }
   actions {
      RedBay;
   }
   size : 81;
}
action Snowflake( Mumford, Rohwer ) {
   bit_or( Empire.Boyle, Empire.Boyle, Mumford );
   bit_or( Empire.Oroville, Empire.Oroville, Rohwer );
}
table Norma {
   actions {
      Snowflake;
   }
   default_action : Snowflake(0, 0);
   size : 1;
}
action Levasy( Dollar ) {
   modify_field( Empire.Toulon, Dollar );
}
action Petroleum( Contact ) {
   modify_field( Empire.Ocilla, Contact );
}
action Offerle( Basye, Lyncourt ) {
   modify_field( Empire.Ocilla, Basye );
   modify_field( Empire.Toulon, Lyncourt );
}
table Arkoe {
   reads {
      Daisytown.Shopville : exact;
      Empire.Boyle : exact;
      Empire.Oroville : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Levasy;
      Petroleum;
      Offerle;
   }
   size : 512;
}
control Caspiana {
   apply( Soledad );
   apply( Halltown );
}
control Clintwood {
   apply( Grants );
}
control Wakita {
   apply( Norma );
   apply( Arkoe );
}
action Exeland( Bonney ) {
   modify_field( Empire.Paoli, Bonney );
}
action Westbury( Garrison, Lenox ) {
   Exeland( Garrison );
   modify_field( ig_intr_md_for_tm.qid, Lenox );
}
table Amenia {
   reads {
      Wegdahl.Naches : ternary;
      ig_intr_md_for_tm.copy_to_cpu : ternary;
      Wegdahl.Rumson : ternary;
      Tillamook.Everton : ternary;
      Tillamook.Grapevine : ternary;
      Tillamook.Reddell : ternary;
      Tillamook.Cliffs : ternary;
      Tillamook.McDermott : ternary;
      Wegdahl.Alamosa : ternary;
      Sidon.Woodcrest : ternary;
      Sidon.Haslet : ternary;
   }
   actions {
      Exeland;
      Westbury;
   }
   size : 512;
}
meter SanJon {
   type : packets;
   static : LaMonte;
   instance_count : 2304;
}
action Tecolote(Schaller) {
   execute_meter( SanJon, Schaller, ig_intr_md_for_tm.packet_color );
}
table LaMonte {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Empire.Paoli : exact;
   }
   actions {
      Tecolote;
   }
   size : 2304;
}
counter Paxtonia {
   type : packets;
   instance_count : 32;
   min_width : 128;
}
action Challis() {
   count( Paxtonia, Empire.Paoli );
}
table RoseBud {
   actions {
     Challis;
   }
   default_action : Challis;
   size : 1;
}
control Eastover {
    if ( (
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x1 ) == 0 ) ) and ( Wegdahl.Naches == 1 ) ) or
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x2 ) == 0 ) ) and ( ig_intr_md_for_tm.copy_to_cpu == 1 ) )
       ) ) {
      apply( LaMonte );
      apply( RoseBud );
   }
}
action Gowanda( Newellton ) {
   modify_field( Wegdahl.Quinnesec, 0 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Newellton );
   modify_field( Wegdahl.Elsey, ig_intr_md.ingress_port );
}
action Lilly( Barclay ) {
   modify_field( Wegdahl.Quinnesec, 1 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Barclay );
   modify_field( Wegdahl.Elsey, ig_intr_md.ingress_port );
}
action Oxford() {
   modify_field( Wegdahl.Quinnesec, 0 );
}
action Sallisaw() {
   modify_field( Wegdahl.Quinnesec, 1 );
   modify_field( Wegdahl.Elsey, ig_intr_md.ingress_port );
}
@pragma ternary 1
table Leola {
   reads {
      Wegdahl.Naches : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      Grandy.SomesBar : exact;
      Daisytown.Angwin : ternary;
      Wegdahl.Rumson : ternary;
   }
   actions {
      Gowanda;
      Lilly;
      Oxford;
      Sallisaw;
   }
   size : 512;
}
control Corfu {
   apply( Leola );
}
counter Coryville {
   type : packets_and_bytes;
   instance_count : 1024;
   min_width : 128;
}
action Oronogo( Negra ) {
   count( Coryville, Negra );
}
table Redondo {
   reads {
      eg_intr_md.egress_port mask 0x7f: exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }
   actions {
     Oronogo;
   }
   size : 1024;
}
control Cantwell {
   apply( Redondo );
}
action Wakefield()
{
   Lucerne();
}
action Finley()
{
   modify_field(Wegdahl.Baltic, 2);
   bit_or(Wegdahl.Adair, 0x2000, Hatfield.Sawpit);
}
action Steger( Islen ) {
   modify_field(Wegdahl.Baltic, 2);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Islen);
   modify_field(Wegdahl.Adair, Islen);
}
table Almond {
   reads {
      Hatfield.Fentress : exact;
      Hatfield.Stonefort : exact;
      Hatfield.Slana : exact;
      Hatfield.Sawpit : exact;
   }
   actions {
      Finley;
      Steger;
      Wakefield;
   }
   default_action : Wakefield();
   size : 256;
}
control Munger {
   apply( Almond );
}
action Neoga( CatCreek, Rehoboth, Wahoo, Iroquois ) {
   modify_field( Harmony.Hannibal, CatCreek );
   modify_field( Desdemona.Gassoway, Wahoo );
   modify_field( Desdemona.Beaman, Rehoboth );
   modify_field( Desdemona.Kurten, Iroquois );
}
table Norland {
   reads {
     Terrell.Osterdock : exact;
     Tillamook.Deferiet : exact;
   }
   actions {
      Neoga;
   }
  size : 16384;
}
action Theba(Fittstown, Monse, Mooreland) {
   modify_field( Desdemona.Beaman, Fittstown );
   modify_field( Desdemona.Gassoway, Monse );
   modify_field( Desdemona.Kurten, Mooreland );
}
table Gambrill {
   reads {
     Terrell.Huffman : exact;
     Harmony.Hannibal : exact;
   }
   actions {
      Theba;
   }
   size : 16384;
}
action Sargeant( Sutter, AvonLake, Powers ) {
   modify_field( Woodland.Tarlton, Sutter );
   modify_field( Woodland.Henry, AvonLake );
   modify_field( Woodland.Salome, Powers );
}
table Rendville {
   reads {
     Wegdahl.Piney : exact;
     Wegdahl.Raritan : exact;
     Wegdahl.Pevely : exact;
   }
   actions {
      Sargeant;
   }
   size : 16384;
}
action Helton() {
   modify_field( Wegdahl.Nuevo, 1 );
}
action Wentworth( Mattson, Roscommon ) {
   Helton();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Desdemona.Beaman );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Mattson, Desdemona.Kurten );
   bit_or( Empire.Paoli, Empire.Paoli, Roscommon );
}
action Herring( Macopin, Zemple ) {
   Helton();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Woodland.Tarlton );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Macopin, Woodland.Salome );
   bit_or( Empire.Paoli, Empire.Paoli, Zemple );
}
action Ashley( Havana, Dunnville ) {
   Helton();
   add( ig_intr_md_for_tm.mcast_grp_a, Wegdahl.Pevely,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Havana );
   bit_or( Empire.Paoli, Empire.Paoli, Dunnville );
}
action Oneonta() {
   modify_field( Wegdahl.Atlasburg, 1 );
}
table Wenatchee {
   reads {
     Desdemona.Gassoway : ternary;
     Desdemona.Beaman : ternary;
     Woodland.Tarlton : ternary;
     Woodland.Henry : ternary;
     Tillamook.Cliffs :ternary;
     Tillamook.Gause:ternary;
   }
   actions {
      Wentworth;
      Herring;
      Ashley;
      Oneonta;
   }
   size : 32;
}
control Unionvale {
   if( Tillamook.Chatom == 0 and
       Grandy.Swaledale == 1 and
       Tillamook.Perryman == 1 ) {
      apply( Norland );
   }
}
control Kokadjo {
   if( Harmony.Hannibal != 0 ) {
      apply( Gambrill );
   }
}
control Hilbert {
   if( Tillamook.Chatom == 0 and Tillamook.Gause==1 ) {
      apply( Rendville );
   }
}
action Coalgate(Larue) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, LoonLake.Equality );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Larue );
}
table Comfrey {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Coalgate;
    }
    size : 512;
}
control Ardenvoir {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Comfrey);
   }
}
action Lucile( Connell, Tullytown ) {
   modify_field( Wegdahl.Pevely, Connell );
   modify_field( Wegdahl.Alamosa, Tullytown );
}
action WestCity() {
   drop();
}
table Keltys {
   reads {
     eg_intr_md.egress_rid: exact;
   }
   actions {
      Lucile;
   }
   default_action: WestCity;
   size : 57344;
}
control Temelec {
   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Keltys);
   }
}
counter Newsoms {
   type : packets;
   direct: Eggleston;
   min_width: 63;
}
table Eggleston {
   reads {
     Parmalee.Livonia mask 0x7fff : exact;
   }
   actions {
      ViewPark;
   }
   default_action: ViewPark();
   size : 32768;
}
action FairPlay() {
   modify_field( Waialee.Academy, Tillamook.Cliffs );
   modify_field( Waialee.LeeCity, Terrell.Honuapo );
   modify_field( Waialee.Fairlea, Tillamook.McDermott );
   modify_field( Waialee.Emmalane, Tillamook.Newkirk );
}
action Hackamore() {
   modify_field( Waialee.Academy, Tillamook.Cliffs );
   modify_field( Waialee.LeeCity, Quarry.Wartrace );
   modify_field( Waialee.Fairlea, Tillamook.McDermott );
   modify_field( Waialee.Emmalane, Tillamook.Newkirk );
}
action Moreland( Bellmead ) {
   FairPlay();
   modify_field( Waialee.Sonora, Bellmead );
}
action Frewsburg( McDougal ) {
   Hackamore();
   modify_field( Waialee.Sonora, McDougal );
}
table Crouch {
   reads {
     Terrell.Huffman : ternary;
   }
   actions {
      Moreland;
   }
   default_action : FairPlay;
  size : 2048;
}
table Merkel {
   reads {
     Quarry.Ghent : ternary;
   }
   actions {
      Frewsburg;
   }
   default_action : Hackamore;
   size : 1024;
}
action Andrade( Dagsboro ) {
   modify_field( Waialee.Winger, Dagsboro );
}
table Senatobia {
   reads {
     Terrell.Osterdock : ternary;
   }
   actions {
      Andrade;
   }
   size : 512;
}
table Elsmere {
   reads {
     Quarry.Farthing : ternary;
   }
   actions {
      Andrade;
   }
   size : 512;
}
action Conejo( Kempton ) {
   modify_field( Waialee.Tolley, Kempton );
}
table NeckCity {
   reads {
     Tillamook.Surrey : ternary;
   }
   actions {
      Conejo;
   }
   size : 512;
}
action WallLake( Marquand ) {
   modify_field( Waialee.Sawyer, Marquand );
}
table Cadley {
   reads {
     Tillamook.Noonan : ternary;
   }
   actions {
      WallLake;
   }
   size : 512;
}
action Ramah( Whitlash ) {
   modify_field( Waialee.LasLomas, Whitlash );
}
action Gobles( Mondovi ) {
   modify_field( Waialee.LasLomas, Mondovi );
}
table Loveland {
   reads {
     Tillamook.Everton : exact;
     Tillamook.Grapevine : exact;
     Tillamook.Jefferson : exact;
     Tillamook.Deferiet : exact;
   }
   actions {
      Ramah;
      ViewPark;
   }
   default_action : ViewPark();
   size : 4096;
}
table Carroll {
   reads {
     Tillamook.Everton : exact;
     Tillamook.Grapevine : exact;
     Tillamook.Jefferson : exact;
     Daisytown.TonkaBay : exact;
   }
   actions {
      Gobles;
   }
   size : 512;
}
control Solomon {
   if( Tillamook.Everton == 1 ) {
      apply( Crouch );
      apply( Senatobia );
   } else if( Tillamook.Grapevine == 1 ) {
      apply( Merkel );
      apply( Elsmere );
   }
   if( ( Tillamook.Lisle != 0 and Tillamook.Rippon == 1 ) or
       ( Tillamook.Lisle == 0 and Sidon.valid == 1 ) ) {
      apply( NeckCity );
      apply( Cadley );
   }
   apply( Loveland ) {
      ViewPark {
         apply( Carroll );
      }
   }
}
action Biscay() {
}
action Pueblo() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action Hutchings() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
}
action Balmorhea() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
table Statham {
   reads {
     Parmalee.Livonia mask 0x00018000 : ternary;
   }
   actions {
      Biscay;
      Pueblo;
      Hutchings;
      Balmorhea;
   }
   size : 16;
}
control ElCentro {
   apply( Statham );
   apply( Eggleston );
}
   metadata Baudette Parmalee;
   action LaMoille( Swenson ) {
          max( Parmalee.Livonia, Parmalee.Livonia, Swenson );
   }
@pragma ways 4
table Scranton {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : exact;
      Waialee.Winger : exact;
      Waialee.Tolley : exact;
      Waialee.Sawyer : exact;
      Waialee.Academy : exact;
      Waialee.LeeCity : exact;
      Waialee.Fairlea : exact;
      Waialee.Emmalane : exact;
      Waialee.Shirley : exact;
   }
   actions {
      LaMoille;
   }
   size : 4096;
}
control Norbeck {
   apply( Scranton );
}
table Protivin {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : ternary;
      Waialee.Winger : ternary;
      Waialee.Tolley : ternary;
      Waialee.Sawyer : ternary;
      Waialee.Academy : ternary;
      Waialee.LeeCity : ternary;
      Waialee.Fairlea : ternary;
      Waialee.Emmalane : ternary;
      Waialee.Shirley : ternary;
   }
   actions {
      LaMoille;
   }
   size : 512;
}
control Eaton {
   apply( Protivin );
}
@pragma pa_no_init ingress Corry.Sonora
@pragma pa_no_init ingress Corry.Winger
@pragma pa_no_init ingress Corry.Tolley
@pragma pa_no_init ingress Corry.Sawyer
@pragma pa_no_init ingress Corry.Academy
@pragma pa_no_init ingress Corry.LeeCity
@pragma pa_no_init ingress Corry.Fairlea
@pragma pa_no_init ingress Corry.Emmalane
@pragma pa_no_init ingress Corry.Shirley
metadata Hemlock Corry;
@pragma ways 4
table Coffman {
   reads {
      Waialee.LasLomas : exact;
      Corry.Sonora : exact;
      Corry.Winger : exact;
      Corry.Tolley : exact;
      Corry.Sawyer : exact;
      Corry.Academy : exact;
      Corry.LeeCity : exact;
      Corry.Fairlea : exact;
      Corry.Emmalane : exact;
      Corry.Shirley : exact;
   }
   actions {
      LaMoille;
   }
   size : 8192;
}
action DelMar( Alvordton, Goodrich, LeaHill, Lafayette, Baytown, Farson, Onawa, Talihina, RioLajas ) {
   bit_and( Corry.Sonora, Waialee.Sonora, Alvordton );
   bit_and( Corry.Winger, Waialee.Winger, Goodrich );
   bit_and( Corry.Tolley, Waialee.Tolley, LeaHill );
   bit_and( Corry.Sawyer, Waialee.Sawyer, Lafayette );
   bit_and( Corry.Academy, Waialee.Academy, Baytown );
   bit_and( Corry.LeeCity, Waialee.LeeCity, Farson );
   bit_and( Corry.Fairlea, Waialee.Fairlea, Onawa );
   bit_and( Corry.Emmalane, Waialee.Emmalane, Talihina );
   bit_and( Corry.Shirley, Waialee.Shirley, RioLajas );
}
table LaMarque {
   reads {
      Waialee.LasLomas : exact;
   }
   actions {
      DelMar;
   }
   default_action : DelMar(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Koloa {
   apply( LaMarque );
}
control Odebolt {
   apply( Coffman );
}
table Myrick {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : ternary;
      Waialee.Winger : ternary;
      Waialee.Tolley : ternary;
      Waialee.Sawyer : ternary;
      Waialee.Academy : ternary;
      Waialee.LeeCity : ternary;
      Waialee.Fairlea : ternary;
      Waialee.Emmalane : ternary;
      Waialee.Shirley : ternary;
   }
   actions {
      LaMoille;
   }
   size : 512;
}
control Madeira {
   apply( Myrick );
}
@pragma ways 4
table Kirkwood {
   reads {
      Waialee.LasLomas : exact;
      Corry.Sonora : exact;
      Corry.Winger : exact;
      Corry.Tolley : exact;
      Corry.Sawyer : exact;
      Corry.Academy : exact;
      Corry.LeeCity : exact;
      Corry.Fairlea : exact;
      Corry.Emmalane : exact;
      Corry.Shirley : exact;
   }
   actions {
      LaMoille;
   }
   size : 4096;
}
action Knippa( Tingley, Belview, Lisman, Ambler, Casper, Humarock, Montalba, Lardo, Covington ) {
   bit_and( Corry.Sonora, Waialee.Sonora, Tingley );
   bit_and( Corry.Winger, Waialee.Winger, Belview );
   bit_and( Corry.Tolley, Waialee.Tolley, Lisman );
   bit_and( Corry.Sawyer, Waialee.Sawyer, Ambler );
   bit_and( Corry.Academy, Waialee.Academy, Casper );
   bit_and( Corry.LeeCity, Waialee.LeeCity, Humarock );
   bit_and( Corry.Fairlea, Waialee.Fairlea, Montalba );
   bit_and( Corry.Emmalane, Waialee.Emmalane, Lardo );
   bit_and( Corry.Shirley, Waialee.Shirley, Covington );
}
table Belmont {
   reads {
      Waialee.LasLomas : exact;
   }
   actions {
      Knippa;
   }
   default_action : Knippa(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Corum {
   apply( Belmont );
}
control Yulee {
   apply( Kirkwood );
}
table Orosi {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : ternary;
      Waialee.Winger : ternary;
      Waialee.Tolley : ternary;
      Waialee.Sawyer : ternary;
      Waialee.Academy : ternary;
      Waialee.LeeCity : ternary;
      Waialee.Fairlea : ternary;
      Waialee.Emmalane : ternary;
      Waialee.Shirley : ternary;
   }
   actions {
      LaMoille;
   }
   size : 512;
}
control Tuskahoma {
   apply( Orosi );
}
@pragma ways 4
table Myton {
   reads {
      Waialee.LasLomas : exact;
      Corry.Sonora : exact;
      Corry.Winger : exact;
      Corry.Tolley : exact;
      Corry.Sawyer : exact;
      Corry.Academy : exact;
      Corry.LeeCity : exact;
      Corry.Fairlea : exact;
      Corry.Emmalane : exact;
      Corry.Shirley : exact;
   }
   actions {
      LaMoille;
   }
   size : 4096;
}
action Caroleen( Dibble, Blevins, Mystic, Green, Lodoga, Ardmore, Alamota, Kalaloch, Platea ) {
   bit_and( Corry.Sonora, Waialee.Sonora, Dibble );
   bit_and( Corry.Winger, Waialee.Winger, Blevins );
   bit_and( Corry.Tolley, Waialee.Tolley, Mystic );
   bit_and( Corry.Sawyer, Waialee.Sawyer, Green );
   bit_and( Corry.Academy, Waialee.Academy, Lodoga );
   bit_and( Corry.LeeCity, Waialee.LeeCity, Ardmore );
   bit_and( Corry.Fairlea, Waialee.Fairlea, Alamota );
   bit_and( Corry.Emmalane, Waialee.Emmalane, Kalaloch );
   bit_and( Corry.Shirley, Waialee.Shirley, Platea );
}
table Poneto {
   reads {
      Waialee.LasLomas : exact;
   }
   actions {
      Caroleen;
   }
   default_action : Caroleen(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Govan {
   apply( Poneto );
}
control Chambers {
   apply( Myton );
}
table Hokah {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : ternary;
      Waialee.Winger : ternary;
      Waialee.Tolley : ternary;
      Waialee.Sawyer : ternary;
      Waialee.Academy : ternary;
      Waialee.LeeCity : ternary;
      Waialee.Fairlea : ternary;
      Waialee.Emmalane : ternary;
      Waialee.Shirley : ternary;
   }
   actions {
      LaMoille;
   }
   size : 512;
}
control Bonsall {
   apply( Hokah );
}
@pragma ways 4
table Omemee {
   reads {
      Waialee.LasLomas : exact;
      Corry.Sonora : exact;
      Corry.Winger : exact;
      Corry.Tolley : exact;
      Corry.Sawyer : exact;
      Corry.Academy : exact;
      Corry.LeeCity : exact;
      Corry.Fairlea : exact;
      Corry.Emmalane : exact;
      Corry.Shirley : exact;
   }
   actions {
      LaMoille;
   }
   size : 8192;
}
action Mulhall( Palmdale, Telida, Pathfork, Attica, Alcester, Hallville, Berea, Daleville, Epsie ) {
   bit_and( Corry.Sonora, Waialee.Sonora, Palmdale );
   bit_and( Corry.Winger, Waialee.Winger, Telida );
   bit_and( Corry.Tolley, Waialee.Tolley, Pathfork );
   bit_and( Corry.Sawyer, Waialee.Sawyer, Attica );
   bit_and( Corry.Academy, Waialee.Academy, Alcester );
   bit_and( Corry.LeeCity, Waialee.LeeCity, Hallville );
   bit_and( Corry.Fairlea, Waialee.Fairlea, Berea );
   bit_and( Corry.Emmalane, Waialee.Emmalane, Daleville );
   bit_and( Corry.Shirley, Waialee.Shirley, Epsie );
}
table McCallum {
   reads {
      Waialee.LasLomas : exact;
   }
   actions {
      Mulhall;
   }
   default_action : Mulhall(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Burtrum {
   apply( McCallum );
}
control RushCity {
   apply( Omemee );
}
table Hansboro {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : ternary;
      Waialee.Winger : ternary;
      Waialee.Tolley : ternary;
      Waialee.Sawyer : ternary;
      Waialee.Academy : ternary;
      Waialee.LeeCity : ternary;
      Waialee.Fairlea : ternary;
      Waialee.Emmalane : ternary;
      Waialee.Shirley : ternary;
   }
   actions {
      LaMoille;
   }
   size : 512;
}
control Lamona {
   apply( Hansboro );
}
@pragma ways 4
table Bassett {
   reads {
      Waialee.LasLomas : exact;
      Corry.Sonora : exact;
      Corry.Winger : exact;
      Corry.Tolley : exact;
      Corry.Sawyer : exact;
      Corry.Academy : exact;
      Corry.LeeCity : exact;
      Corry.Fairlea : exact;
      Corry.Emmalane : exact;
      Corry.Shirley : exact;
   }
   actions {
      LaMoille;
   }
   size : 8192;
}
action Elwood( Gunder, Shipman, Maumee, Daguao, Crumstown, Cisne, Triplett, Verdery, Kanorado ) {
   bit_and( Corry.Sonora, Waialee.Sonora, Gunder );
   bit_and( Corry.Winger, Waialee.Winger, Shipman );
   bit_and( Corry.Tolley, Waialee.Tolley, Maumee );
   bit_and( Corry.Sawyer, Waialee.Sawyer, Daguao );
   bit_and( Corry.Academy, Waialee.Academy, Crumstown );
   bit_and( Corry.LeeCity, Waialee.LeeCity, Cisne );
   bit_and( Corry.Fairlea, Waialee.Fairlea, Triplett );
   bit_and( Corry.Emmalane, Waialee.Emmalane, Verdery );
   bit_and( Corry.Shirley, Waialee.Shirley, Kanorado );
}
table Hartwell {
   reads {
      Waialee.LasLomas : exact;
   }
   actions {
      Elwood;
   }
   default_action : Elwood(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control LeeCreek {
   apply( Hartwell );
}
control LaPlata {
   apply( Bassett );
}
table Robinson {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : ternary;
      Waialee.Winger : ternary;
      Waialee.Tolley : ternary;
      Waialee.Sawyer : ternary;
      Waialee.Academy : ternary;
      Waialee.LeeCity : ternary;
      Waialee.Fairlea : ternary;
      Waialee.Emmalane : ternary;
      Waialee.Shirley : ternary;
   }
   actions {
      LaMoille;
   }
   size : 512;
}
control Winters {
   apply( Robinson );
}
@pragma ways 4
table Nooksack {
   reads {
      Waialee.LasLomas : exact;
      Corry.Sonora : exact;
      Corry.Winger : exact;
      Corry.Tolley : exact;
      Corry.Sawyer : exact;
      Corry.Academy : exact;
      Corry.LeeCity : exact;
      Corry.Fairlea : exact;
      Corry.Emmalane : exact;
      Corry.Shirley : exact;
   }
   actions {
      LaMoille;
   }
   size : 4096;
}
action Honaker( Westwood, Nelagoney, Edler, Thurmond, Knollwood, Charco, Barksdale, Nankin, Sarasota ) {
   bit_and( Corry.Sonora, Waialee.Sonora, Westwood );
   bit_and( Corry.Winger, Waialee.Winger, Nelagoney );
   bit_and( Corry.Tolley, Waialee.Tolley, Edler );
   bit_and( Corry.Sawyer, Waialee.Sawyer, Thurmond );
   bit_and( Corry.Academy, Waialee.Academy, Knollwood );
   bit_and( Corry.LeeCity, Waialee.LeeCity, Charco );
   bit_and( Corry.Fairlea, Waialee.Fairlea, Barksdale );
   bit_and( Corry.Emmalane, Waialee.Emmalane, Nankin );
   bit_and( Corry.Shirley, Waialee.Shirley, Sarasota );
}
table Ossining {
   reads {
      Waialee.LasLomas : exact;
   }
   actions {
      Honaker;
   }
   default_action : Honaker(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Smithland {
   apply( Ossining );
}
control Dryden {
   apply( Nooksack );
}
table Ivyland {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : ternary;
      Waialee.Winger : ternary;
      Waialee.Tolley : ternary;
      Waialee.Sawyer : ternary;
      Waialee.Academy : ternary;
      Waialee.LeeCity : ternary;
      Waialee.Fairlea : ternary;
      Waialee.Emmalane : ternary;
      Waialee.Shirley : ternary;
   }
   actions {
      LaMoille;
   }
   size : 512;
}
control VanWert {
   apply( Ivyland );
}
@pragma ways 4
table Disney {
   reads {
      Waialee.LasLomas : exact;
      Corry.Sonora : exact;
      Corry.Winger : exact;
      Corry.Tolley : exact;
      Corry.Sawyer : exact;
      Corry.Academy : exact;
      Corry.LeeCity : exact;
      Corry.Fairlea : exact;
      Corry.Emmalane : exact;
      Corry.Shirley : exact;
   }
   actions {
      LaMoille;
   }
   size : 4096;
}
action AquaPark( Cruso, MillHall, Nursery, Pound, Bogota, BoxElder, Enderlin, Eugene, Beltrami ) {
   bit_and( Corry.Sonora, Waialee.Sonora, Cruso );
   bit_and( Corry.Winger, Waialee.Winger, MillHall );
   bit_and( Corry.Tolley, Waialee.Tolley, Nursery );
   bit_and( Corry.Sawyer, Waialee.Sawyer, Pound );
   bit_and( Corry.Academy, Waialee.Academy, Bogota );
   bit_and( Corry.LeeCity, Waialee.LeeCity, BoxElder );
   bit_and( Corry.Fairlea, Waialee.Fairlea, Enderlin );
   bit_and( Corry.Emmalane, Waialee.Emmalane, Eugene );
   bit_and( Corry.Shirley, Waialee.Shirley, Beltrami );
}
table LaHoma {
   reads {
      Waialee.LasLomas : exact;
   }
   actions {
      AquaPark;
   }
   default_action : AquaPark(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Pettigrew {
   apply( LaHoma );
}
control Richlawn {
   apply( Disney );
}
table Otego {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : ternary;
      Waialee.Winger : ternary;
      Waialee.Tolley : ternary;
      Waialee.Sawyer : ternary;
      Waialee.Academy : ternary;
      Waialee.LeeCity : ternary;
      Waialee.Fairlea : ternary;
      Waialee.Emmalane : ternary;
      Waialee.Shirley : ternary;
   }
   actions {
      LaMoille;
   }
   size : 512;
}
control Calamus {
   apply( Otego );
}
   metadata Baudette Newsome;
   action Ironside( RowanBay ) {
          max( Newsome.Livonia, Newsome.Livonia, RowanBay );
   }
   action Tunis() { max( Parmalee.Livonia, Newsome.Livonia, Parmalee.Livonia ); } table Jermyn { actions { Tunis; } default_action : Tunis; size : 1; } control Fajardo { apply( Jermyn ); }
@pragma ways 4
table Marysvale {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : exact;
      Waialee.Winger : exact;
      Waialee.Tolley : exact;
      Waialee.Sawyer : exact;
      Waialee.Academy : exact;
      Waialee.LeeCity : exact;
      Waialee.Fairlea : exact;
      Waialee.Emmalane : exact;
      Waialee.Shirley : exact;
   }
   actions {
      Ironside;
   }
   size : 4096;
}
control Edgemont {
   apply( Marysvale );
}
table McHenry {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : ternary;
      Waialee.Winger : ternary;
      Waialee.Tolley : ternary;
      Waialee.Sawyer : ternary;
      Waialee.Academy : ternary;
      Waialee.LeeCity : ternary;
      Waialee.Fairlea : ternary;
      Waialee.Emmalane : ternary;
      Waialee.Shirley : ternary;
   }
   actions {
      Ironside;
   }
   size : 4096;
}
control CeeVee {
   apply( McHenry );
}
@pragma pa_no_init ingress Kalskag.Sonora
@pragma pa_no_init ingress Kalskag.Winger
@pragma pa_no_init ingress Kalskag.Tolley
@pragma pa_no_init ingress Kalskag.Sawyer
@pragma pa_no_init ingress Kalskag.Academy
@pragma pa_no_init ingress Kalskag.LeeCity
@pragma pa_no_init ingress Kalskag.Fairlea
@pragma pa_no_init ingress Kalskag.Emmalane
@pragma pa_no_init ingress Kalskag.Shirley
metadata Hemlock Kalskag;
@pragma ways 4
table Talbotton {
   reads {
      Waialee.LasLomas : exact;
      Kalskag.Sonora : exact;
      Kalskag.Winger : exact;
      Kalskag.Tolley : exact;
      Kalskag.Sawyer : exact;
      Kalskag.Academy : exact;
      Kalskag.LeeCity : exact;
      Kalskag.Fairlea : exact;
      Kalskag.Emmalane : exact;
      Kalskag.Shirley : exact;
   }
   actions {
      Ironside;
   }
   size : 4096;
}
action Redmon( Lamboglia, Amalga, Lefors, Belpre, DelRosa, Oklee, Libby, Emblem, Thurston ) {
   bit_and( Kalskag.Sonora, Waialee.Sonora, Lamboglia );
   bit_and( Kalskag.Winger, Waialee.Winger, Amalga );
   bit_and( Kalskag.Tolley, Waialee.Tolley, Lefors );
   bit_and( Kalskag.Sawyer, Waialee.Sawyer, Belpre );
   bit_and( Kalskag.Academy, Waialee.Academy, DelRosa );
   bit_and( Kalskag.LeeCity, Waialee.LeeCity, Oklee );
   bit_and( Kalskag.Fairlea, Waialee.Fairlea, Libby );
   bit_and( Kalskag.Emmalane, Waialee.Emmalane, Emblem );
   bit_and( Kalskag.Shirley, Waialee.Shirley, Thurston );
}
table Hopedale {
   reads {
      Waialee.LasLomas : exact;
   }
   actions {
      Redmon;
   }
   default_action : Redmon(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Tolleson {
   apply( Hopedale );
}
control Lasker {
   apply( Talbotton );
}
table Louin {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : ternary;
      Waialee.Winger : ternary;
      Waialee.Tolley : ternary;
      Waialee.Sawyer : ternary;
      Waialee.Academy : ternary;
      Waialee.LeeCity : ternary;
      Waialee.Fairlea : ternary;
      Waialee.Emmalane : ternary;
      Waialee.Shirley : ternary;
   }
   actions {
      Ironside;
   }
   size : 512;
}
control AukeBay {
   apply( Louin );
}
@pragma ways 4
table Vernal {
   reads {
      Waialee.LasLomas : exact;
      Kalskag.Sonora : exact;
      Kalskag.Winger : exact;
      Kalskag.Tolley : exact;
      Kalskag.Sawyer : exact;
      Kalskag.Academy : exact;
      Kalskag.LeeCity : exact;
      Kalskag.Fairlea : exact;
      Kalskag.Emmalane : exact;
      Kalskag.Shirley : exact;
   }
   actions {
      Ironside;
   }
   size : 4096;
}
action Onley( Victoria, Pekin, Clearco, Hapeville, Willows, Lucas, Hillsview, Ugashik, Lamont ) {
   bit_and( Kalskag.Sonora, Waialee.Sonora, Victoria );
   bit_and( Kalskag.Winger, Waialee.Winger, Pekin );
   bit_and( Kalskag.Tolley, Waialee.Tolley, Clearco );
   bit_and( Kalskag.Sawyer, Waialee.Sawyer, Hapeville );
   bit_and( Kalskag.Academy, Waialee.Academy, Willows );
   bit_and( Kalskag.LeeCity, Waialee.LeeCity, Lucas );
   bit_and( Kalskag.Fairlea, Waialee.Fairlea, Hillsview );
   bit_and( Kalskag.Emmalane, Waialee.Emmalane, Ugashik );
   bit_and( Kalskag.Shirley, Waialee.Shirley, Lamont );
}
table Poplar {
   reads {
      Waialee.LasLomas : exact;
   }
   actions {
      Onley;
   }
   default_action : Onley(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Satanta {
   apply( Poplar );
}
control Denmark {
   apply( Vernal );
}
table Laxon {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : ternary;
      Waialee.Winger : ternary;
      Waialee.Tolley : ternary;
      Waialee.Sawyer : ternary;
      Waialee.Academy : ternary;
      Waialee.LeeCity : ternary;
      Waialee.Fairlea : ternary;
      Waialee.Emmalane : ternary;
      Waialee.Shirley : ternary;
   }
   actions {
      Ironside;
   }
   size : 512;
}
control Termo {
   apply( Laxon );
}
@pragma ways 4
table Varnell {
   reads {
      Waialee.LasLomas : exact;
      Kalskag.Sonora : exact;
      Kalskag.Winger : exact;
      Kalskag.Tolley : exact;
      Kalskag.Sawyer : exact;
      Kalskag.Academy : exact;
      Kalskag.LeeCity : exact;
      Kalskag.Fairlea : exact;
      Kalskag.Emmalane : exact;
      Kalskag.Shirley : exact;
   }
   actions {
      Ironside;
   }
   size : 4096;
}
action Benkelman( Earlsboro, Center, Pearcy, ShowLow, Piperton, Leoma, RoseTree, Almedia, Conneaut ) {
   bit_and( Kalskag.Sonora, Waialee.Sonora, Earlsboro );
   bit_and( Kalskag.Winger, Waialee.Winger, Center );
   bit_and( Kalskag.Tolley, Waialee.Tolley, Pearcy );
   bit_and( Kalskag.Sawyer, Waialee.Sawyer, ShowLow );
   bit_and( Kalskag.Academy, Waialee.Academy, Piperton );
   bit_and( Kalskag.LeeCity, Waialee.LeeCity, Leoma );
   bit_and( Kalskag.Fairlea, Waialee.Fairlea, RoseTree );
   bit_and( Kalskag.Emmalane, Waialee.Emmalane, Almedia );
   bit_and( Kalskag.Shirley, Waialee.Shirley, Conneaut );
}
table Beaverton {
   reads {
      Waialee.LasLomas : exact;
   }
   actions {
      Benkelman;
   }
   default_action : Benkelman(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Willits {
   apply( Beaverton );
}
control Poipu {
   apply( Varnell );
}
table Calhan {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : ternary;
      Waialee.Winger : ternary;
      Waialee.Tolley : ternary;
      Waialee.Sawyer : ternary;
      Waialee.Academy : ternary;
      Waialee.LeeCity : ternary;
      Waialee.Fairlea : ternary;
      Waialee.Emmalane : ternary;
      Waialee.Shirley : ternary;
   }
   actions {
      Ironside;
   }
   size : 512;
}
control Hammocks {
   apply( Calhan );
}
@pragma ways 4
table Moorpark {
   reads {
      Waialee.LasLomas : exact;
      Kalskag.Sonora : exact;
      Kalskag.Winger : exact;
      Kalskag.Tolley : exact;
      Kalskag.Sawyer : exact;
      Kalskag.Academy : exact;
      Kalskag.LeeCity : exact;
      Kalskag.Fairlea : exact;
      Kalskag.Emmalane : exact;
      Kalskag.Shirley : exact;
   }
   actions {
      Ironside;
   }
   size : 4096;
}
action Anaconda( Friday, Hilburn, Sneads, Tannehill, Wapella, Inola, Gonzales, DosPalos, DeLancey ) {
   bit_and( Kalskag.Sonora, Waialee.Sonora, Friday );
   bit_and( Kalskag.Winger, Waialee.Winger, Hilburn );
   bit_and( Kalskag.Tolley, Waialee.Tolley, Sneads );
   bit_and( Kalskag.Sawyer, Waialee.Sawyer, Tannehill );
   bit_and( Kalskag.Academy, Waialee.Academy, Wapella );
   bit_and( Kalskag.LeeCity, Waialee.LeeCity, Inola );
   bit_and( Kalskag.Fairlea, Waialee.Fairlea, Gonzales );
   bit_and( Kalskag.Emmalane, Waialee.Emmalane, DosPalos );
   bit_and( Kalskag.Shirley, Waialee.Shirley, DeLancey );
}
table Kress {
   reads {
      Waialee.LasLomas : exact;
   }
   actions {
      Anaconda;
   }
   default_action : Anaconda(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Norborne {
   apply( Kress );
}
control Bayshore {
   apply( Moorpark );
}
table Hearne {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : ternary;
      Waialee.Winger : ternary;
      Waialee.Tolley : ternary;
      Waialee.Sawyer : ternary;
      Waialee.Academy : ternary;
      Waialee.LeeCity : ternary;
      Waialee.Fairlea : ternary;
      Waialee.Emmalane : ternary;
      Waialee.Shirley : ternary;
   }
   actions {
      Ironside;
   }
   size : 512;
}
control Riverbank {
   apply( Hearne );
}
@pragma ways 4
table Atlas {
   reads {
      Waialee.LasLomas : exact;
      Kalskag.Sonora : exact;
      Kalskag.Winger : exact;
      Kalskag.Tolley : exact;
      Kalskag.Sawyer : exact;
      Kalskag.Academy : exact;
      Kalskag.LeeCity : exact;
      Kalskag.Fairlea : exact;
      Kalskag.Emmalane : exact;
      Kalskag.Shirley : exact;
   }
   actions {
      Ironside;
   }
   size : 4096;
}
action Genola( Waretown, Fallsburg, Lapeer, Flasher, Stampley, Bienville, Washta, Vestaburg, Camelot ) {
   bit_and( Kalskag.Sonora, Waialee.Sonora, Waretown );
   bit_and( Kalskag.Winger, Waialee.Winger, Fallsburg );
   bit_and( Kalskag.Tolley, Waialee.Tolley, Lapeer );
   bit_and( Kalskag.Sawyer, Waialee.Sawyer, Flasher );
   bit_and( Kalskag.Academy, Waialee.Academy, Stampley );
   bit_and( Kalskag.LeeCity, Waialee.LeeCity, Bienville );
   bit_and( Kalskag.Fairlea, Waialee.Fairlea, Washta );
   bit_and( Kalskag.Emmalane, Waialee.Emmalane, Vestaburg );
   bit_and( Kalskag.Shirley, Waialee.Shirley, Camelot );
}
table Ronneby {
   reads {
      Waialee.LasLomas : exact;
   }
   actions {
      Genola;
   }
   default_action : Genola(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control DesPeres {
   apply( Ronneby );
}
control Harvard {
   apply( Atlas );
}
table Panacea {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : ternary;
      Waialee.Winger : ternary;
      Waialee.Tolley : ternary;
      Waialee.Sawyer : ternary;
      Waialee.Academy : ternary;
      Waialee.LeeCity : ternary;
      Waialee.Fairlea : ternary;
      Waialee.Emmalane : ternary;
      Waialee.Shirley : ternary;
   }
   actions {
      Ironside;
   }
   size : 512;
}
control Hanover {
   apply( Panacea );
}
@pragma ways 4
table SaintAnn {
   reads {
      Waialee.LasLomas : exact;
      Kalskag.Sonora : exact;
      Kalskag.Winger : exact;
      Kalskag.Tolley : exact;
      Kalskag.Sawyer : exact;
      Kalskag.Academy : exact;
      Kalskag.LeeCity : exact;
      Kalskag.Fairlea : exact;
      Kalskag.Emmalane : exact;
      Kalskag.Shirley : exact;
   }
   actions {
      Ironside;
   }
   size : 4096;
}
action Wyncote( Stuttgart, Jauca, Parmelee, Faysville, Nixon, Manville, Ballville, Pembine, Toccopola ) {
   bit_and( Kalskag.Sonora, Waialee.Sonora, Stuttgart );
   bit_and( Kalskag.Winger, Waialee.Winger, Jauca );
   bit_and( Kalskag.Tolley, Waialee.Tolley, Parmelee );
   bit_and( Kalskag.Sawyer, Waialee.Sawyer, Faysville );
   bit_and( Kalskag.Academy, Waialee.Academy, Nixon );
   bit_and( Kalskag.LeeCity, Waialee.LeeCity, Manville );
   bit_and( Kalskag.Fairlea, Waialee.Fairlea, Ballville );
   bit_and( Kalskag.Emmalane, Waialee.Emmalane, Pembine );
   bit_and( Kalskag.Shirley, Waialee.Shirley, Toccopola );
}
table Humeston {
   reads {
      Waialee.LasLomas : exact;
   }
   actions {
      Wyncote;
   }
   default_action : Wyncote(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control DeSmet {
   apply( Humeston );
}
control Lambrook {
   apply( SaintAnn );
}
table Pineland {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : ternary;
      Waialee.Winger : ternary;
      Waialee.Tolley : ternary;
      Waialee.Sawyer : ternary;
      Waialee.Academy : ternary;
      Waialee.LeeCity : ternary;
      Waialee.Fairlea : ternary;
      Waialee.Emmalane : ternary;
      Waialee.Shirley : ternary;
   }
   actions {
      Ironside;
   }
   size : 512;
}
control Vidal {
   apply( Pineland );
}
@pragma ways 4
table LaConner {
   reads {
      Waialee.LasLomas : exact;
      Kalskag.Sonora : exact;
      Kalskag.Winger : exact;
      Kalskag.Tolley : exact;
      Kalskag.Sawyer : exact;
      Kalskag.Academy : exact;
      Kalskag.LeeCity : exact;
      Kalskag.Fairlea : exact;
      Kalskag.Emmalane : exact;
      Kalskag.Shirley : exact;
   }
   actions {
      Ironside;
   }
   size : 4096;
}
action Shanghai( Kountze, Elysburg, Othello, Merit, Sisters, Gibson, Absarokee, Milltown, Hackney ) {
   bit_and( Kalskag.Sonora, Waialee.Sonora, Kountze );
   bit_and( Kalskag.Winger, Waialee.Winger, Elysburg );
   bit_and( Kalskag.Tolley, Waialee.Tolley, Othello );
   bit_and( Kalskag.Sawyer, Waialee.Sawyer, Merit );
   bit_and( Kalskag.Academy, Waialee.Academy, Sisters );
   bit_and( Kalskag.LeeCity, Waialee.LeeCity, Gibson );
   bit_and( Kalskag.Fairlea, Waialee.Fairlea, Absarokee );
   bit_and( Kalskag.Emmalane, Waialee.Emmalane, Milltown );
   bit_and( Kalskag.Shirley, Waialee.Shirley, Hackney );
}
table Stovall {
   reads {
      Waialee.LasLomas : exact;
   }
   actions {
      Shanghai;
   }
   default_action : Shanghai(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Olcott {
   apply( Stovall );
}
control Lansdowne {
   apply( LaConner );
}
table NewRome {
   reads {
      Waialee.LasLomas : exact;
      Waialee.Sonora : ternary;
      Waialee.Winger : ternary;
      Waialee.Tolley : ternary;
      Waialee.Sawyer : ternary;
      Waialee.Academy : ternary;
      Waialee.LeeCity : ternary;
      Waialee.Fairlea : ternary;
      Waialee.Emmalane : ternary;
      Waialee.Shirley : ternary;
   }
   actions {
      Ironside;
   }
   size : 512;
}
control Belmore {
   apply( NewRome );
}
control ingress {
   Wiota();
   if( Daisytown.Daniels != 0 ) {
      Norseland();
   }
   Vevay();
   if( Daisytown.Daniels != 0 ) {
      Giltner();
      Machens();
   }
   Gibsland();
   Solomon();
   Blackman();
   Stewart();
   Koloa();
   if( Daisytown.Daniels != 0 ) {
      Metter();
   }
   Odebolt();
   Corum();
   Yulee();
   Govan();
   if( Daisytown.Daniels != 0 ) {
      Pineridge();
   }
   Laurelton();
   Caspiana();
   Chambers();
   Burtrum();
   if( Daisytown.Daniels != 0 ) {
      Driftwood();
   }
   RushCity();
   LeeCreek();
   CeeVee();
   Papeton();
   Unionvale();
   if( Daisytown.Daniels != 0 ) {
      Blakeslee();
   }
   Kokadjo();
   Weches();
   LaPlata();
   Biloxi();
   if( Wegdahl.Naches == 0 ) {
      if( valid( Hatfield ) ) {
         Munger();
      } else {
         Hilbert();
         PawPaw();
      }
   }
   if( Hatfield.valid == 0 ) {
      Clintwood();
   }
   if( Wegdahl.Naches == 0 ) {
      Edinburgh();
   }
   Fajardo();
   if ( Daisytown.Daniels != 0 ) {
      if( Wegdahl.Naches == 0 and Tillamook.Gause == 1) {
         apply( Wenatchee );
      } else {
         apply( Amenia );
      }
   }
   if( Daisytown.Daniels != 0 ) {
      Wakita();
   }
   Eastover();
   if( valid( Hartwick[0] ) ) {
      Magnolia();
   }
   if( Wegdahl.Naches == 0 ) {
      Ardenvoir();
   }
   Corfu();
   ElCentro();
}
control egress {
   Temelec();
   Kalvesta();
   Minoa();
   if( ( Wegdahl.Upson == 0 ) and ( Wegdahl.Baltic != 2 ) ) {
      Fallis();
   }
   Cantwell();
}
