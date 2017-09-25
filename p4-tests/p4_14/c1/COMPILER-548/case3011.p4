// BUILD: p4c-tofino --verbose 2 --placement tp4 --no-dead-code-elimination --o bf_obfuscate_arista_switch_default --p4-name=obfuscate_arista_switch --p4-prefix=p4_obfuscate_arista_switch --pipe-mgr-path=pipe_mgr/ --mc-mgr-path=mc_mgr/ --gen-exm-test-pd -S -DPROFILE_DEFAULT Switch.OBFUSCATED.p4


// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 230945

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
header_type Essington {
	fields {
		Berenice : 16;
		Flasher : 16;
		Hartfield : 8;
		Higginson : 8;
		SourLake : 8;
		Ardara : 8;
		Virgilina : 1;
		Meservey : 1;
		Amber : 1;
		Renville : 1;
		Nordland : 1;
		Hanover : 1;
	}
}
header_type Offerle {
	fields {
		Robstown : 24;
		Wingate : 24;
		ElToro : 24;
		Rendon : 24;
		Anandale : 16;
		Almont : 16;
		Hiwassee : 16;
		Hanford : 16;
		Siloam : 16;
		Pawtucket : 8;
		Booth : 8;
		Raritan : 1;
		Jenifer : 1;
		Randle : 1;
		Winner : 1;
		Kasilof : 12;
		Pilger : 2;
		Wakita : 1;
		Harriston : 1;
		Hauppauge : 1;
		Lubec : 1;
		Monohan : 1;
		Willard : 1;
		Pinto : 1;
		Fristoe : 1;
		Mayview : 1;
		Heidrick : 1;
		NeckCity : 1;
		Baskin : 1;
		Spanaway : 1;
		Luzerne : 1;
		Coryville : 1;
		Penzance : 1;
		Topanga : 16;
		Rockport : 16;
		Cockrum : 8;
		Timbo : 1;
		Hanapepe : 1;
	}
}
header_type Warba {
	fields {
		PeaRidge : 24;
		Prosser : 24;
		Bridgton : 24;
		Tennessee : 24;
		Houston : 24;
		Barber : 24;
		Pinole : 24;
		Langdon : 24;
		Ulysses : 16;
		Lurton : 16;
		Cornville : 16;
		Sunset : 16;
		Christina : 12;
		Stidham : 1;
		DeLancey : 3;
		Umkumiut : 1;
		Bacton : 3;
		Sunbury : 1;
		Macland : 1;
		Sodaville : 1;
		Luning : 1;
		Chatcolet : 1;
		Ammon : 8;
		Arbyrd : 12;
		Leacock : 4;
		Covina : 6;
		Sagamore : 10;
		Tagus : 9;
		Donald : 1;
		Maupin : 1;
		Isabela : 1;
		Rodeo : 1;
		Darco : 1;
		Renton : 8;
		Moorcroft : 8;
		Wakefield : 16;
		Hahira : 16;
		Speedway : 32;
		Natalbany : 32;
	}
}
header_type Sagerton {
	fields {
		Henrietta : 16;
		Stoutland : 16;
		Peletier : 8;
		Brave : 2;
		Farragut : 10;
		Shelbina : 10;
	}
}
header_type Arroyo {
	fields {
		Bedrock : 8;
		Alabam : 2;
		Benson : 10;
		GlenAvon : 10;
	}
}
header_type LaPlata {
	fields {
		Welcome : 8;
		Saltair : 1;
		Hobergs : 1;
		Goosport : 1;
		Connell : 1;
		McClusky : 1;
	}
}
header_type Ridgeview {
	fields {
		Covington : 32;
		Hotchkiss : 32;
		Forbes : 6;
		Logandale : 16;
	}
}
header_type Bratenahl {
	fields {
		Ickesburg : 128;
		Sully : 128;
		McHenry : 20;
		ElPrado : 8;
		Vinemont : 11;
		Corry : 6;
		Casnovia : 13;
	}
}
header_type Caputa {
	fields {
		Baraboo : 14;
		Saugatuck : 1;
		Wakenda : 12;
		Canjilon : 1;
		Shade : 1;
		Chappells : 6;
		Renick : 2;
		Oakmont : 6;
		Laurelton : 3;
	}
}
header_type Jenera {
	fields {
		Gorman : 1;
		Chaska : 1;
	}
}
header_type RoyalOak {
	fields {
		Bonduel : 8;
	}
}
header_type Bluewater {
	fields {
		Elmwood : 16;
		Wadley : 11;
	}
}
header_type Pollard {
	fields {
		Lueders : 32;
		Camilla : 32;
		Breese : 32;
	}
}
header_type Ashville {
	fields {
		FlatRock : 32;
		Shingler : 32;
	}
}
header_type Hawthorn {
	fields {
		Horton : 1;
		Bonney : 1;
		Caban : 1;
		Madill : 3;
		Franktown : 1;
		SomesBar : 6;
		Maxwelton : 5;
	}
}
header_type OldGlory {
	fields {
		Pensaukee : 16;
	}
}
header_type Allgood {
	fields {
		Gwynn : 14;
		Aberfoil : 1;
		PaloAlto : 1;
	}
}
header_type Pittsburg {
	fields {
		ElMirage : 14;
		Bellville : 1;
		Bayard : 1;
	}
}
header_type Machens {
	fields {
		PawPaw : 16;
		Subiaco : 16;
		Excel : 16;
		Proctor : 16;
		Parkland : 8;
		Sewaren : 8;
		Jenison : 8;
		Wolford : 8;
		Seagate : 1;
		Robins : 6;
	}
}
header_type Waldo {
	fields {
		Jeddo : 32;
	}
}
header_type DosPalos {
	fields {
		Sutherlin : 6;
		RowanBay : 10;
		Melrude : 4;
		Tularosa : 12;
		Elkton : 12;
		Kneeland : 2;
		Clintwood : 2;
		Highcliff : 8;
		Wheeler : 3;
		Wayland : 5;
	}
}
header_type Pierpont {
	fields {
		Lanesboro : 24;
		Harmony : 24;
		Winters : 24;
		Berne : 24;
		Pittsboro : 16;
	}
}
header_type Waitsburg {
	fields {
		Kekoskee : 3;
		Schleswig : 1;
		Bulverde : 12;
		Holden : 16;
	}
}
header_type Panacea {
	fields {
		Sofia : 4;
		Wabbaseka : 4;
		Baldwin : 6;
		Mather : 2;
		Marie : 16;
		Upalco : 16;
		Acree : 3;
		Fairborn : 13;
		Isleta : 8;
		Alderson : 8;
		Makawao : 16;
		Culloden : 32;
		Parrish : 32;
	}
}
header_type Chambers {
	fields {
		Amazonia : 4;
		Petrey : 6;
		Westwego : 2;
		RoseTree : 20;
		Hackney : 16;
		Lubeck : 8;
		Windham : 8;
		WestBend : 128;
		Elsmere : 128;
	}
}
header_type Homeworth {
	fields {
		Tekonsha : 8;
		Pinta : 8;
		Lemhi : 16;
	}
}
header_type Tulalip {
	fields {
		Maljamar : 16;
		Narka : 16;
	}
}
header_type Elsey {
	fields {
		Encinitas : 32;
		Kathleen : 32;
		Minetto : 4;
		Eastman : 4;
		Trona : 8;
		Gurley : 16;
		Antoine : 16;
		Rawson : 16;
	}
}
header_type Onslow {
	fields {
		Calamus : 16;
		Turney : 16;
	}
}
header_type Tununak {
	fields {
		Woodrow : 16;
		Hartman : 16;
		Wenham : 8;
		Monteview : 8;
		Ronan : 16;
	}
}
header_type Simla {
	fields {
		Daguao : 48;
		Hurst : 32;
		Sonestown : 48;
		Trooper : 32;
	}
}
header_type Missoula {
	fields {
		Olcott : 1;
		Chouteau : 1;
		Quamba : 1;
		VanZandt : 1;
		Tonkawa : 1;
		Mancelona : 3;
		Minburn : 5;
		Coronado : 3;
		Cataract : 16;
	}
}
header_type Absarokee {
	fields {
		RichHill : 24;
		BayPort : 8;
	}
}
header_type Hodge {
	fields {
		Riverlea : 8;
		Willits : 24;
		Ramapo : 24;
		Lawnside : 8;
	}
}
header Pierpont Kapalua;
header Pierpont Tanacross;
header Waitsburg Farson[ 2 ];
@pragma pa_fragment ingress Robert.Makawao
@pragma pa_fragment egress Robert.Makawao
header Panacea Robert;
@pragma pa_fragment ingress LaPointe.Makawao
@pragma pa_fragment egress LaPointe.Makawao
header Panacea LaPointe;
header Chambers Crary;
header Chambers Valencia;
header Tulalip Camden;
header Tulalip Wenona;
header Elsey Gandy;
header Onslow Hampton;
header Elsey Azalia;
header Onslow Vacherie;
header Hodge Northlake;
header Tununak Ebenezer;
header Missoula Mishicot;
header DosPalos Levasy;
header Pierpont McAdams;
parser start {
   return select(current(96, 16)) {
      0xBF00 : Halaula;
      default : Nipton;
   }
}
parser Hagewood {
   extract( Levasy );
   return Nipton;
}
parser Halaula {
   extract( McAdams );
   return Hagewood;
}
parser Nipton {
   extract( Kapalua );
   return select( Kapalua.Pittsboro ) {
      0x8100 : Ackerman;
      0x0800 : Netcong;
      0x86dd : RioLinda;
      0x0806 : Chualar;
      default : ingress;
   }
}
parser Ackerman {
   extract( Farson[0] );
   set_metadata(Gambrill.Nordland, 1);
   return select( Farson[0].Holden ) {
      0x0800 : Netcong;
      0x86dd : RioLinda;
      0x0806 : Chualar;
      default : ingress;
   }
}
field_list BealCity {
    Robert.Sofia;
    Robert.Wabbaseka;
    Robert.Baldwin;
    Robert.Mather;
    Robert.Marie;
    Robert.Upalco;
    Robert.Acree;
    Robert.Fairborn;
    Robert.Isleta;
    Robert.Alderson;
    Robert.Culloden;
    Robert.Parrish;
}
field_list_calculation LaMoille {
    input {
        BealCity;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Robert.Makawao {
    verify LaMoille;
    update LaMoille;
}
parser Netcong {
   extract( Robert );
   set_metadata(Gambrill.Hartfield, Robert.Alderson);
   set_metadata(Gambrill.SourLake, Robert.Isleta);
   set_metadata(Gambrill.Berenice, Robert.Marie);
   set_metadata(Gambrill.Amber, 0);
   set_metadata(Gambrill.Virgilina, 1);
   return select(Robert.Fairborn, Robert.Wabbaseka, Robert.Alderson) {
      0x501 : Nunnelly;
      0x511 : Astatula;
      0x506 : Maryville;
      0 mask 0xFF7000 : Frewsburg;
      default : ingress;
   }
}
parser Frewsburg {
   set_metadata(Wimberley.Randle, 1);
   return ingress;
}
parser RioLinda {
   extract( Valencia );
   set_metadata(Gambrill.Hartfield, Valencia.Lubeck);
   set_metadata(Gambrill.SourLake, Valencia.Windham);
   set_metadata(Gambrill.Berenice, Valencia.Hackney);
   set_metadata(Gambrill.Amber, 1);
   set_metadata(Gambrill.Virgilina, 0);
   return select(Valencia.Lubeck) {
      0x3a : Nunnelly;
      17 : Nixon;
      6 : Maryville;
      default : Frewsburg;
   }
}
parser Chualar {
   extract( Ebenezer );
   set_metadata(Gambrill.Hanover, 1);
   return ingress;
}
parser Astatula {
   extract(Camden);
   extract(Hampton);
   set_metadata(Wimberley.Randle, 1);
   return select(Camden.Narka) {
      4789 : Nashoba;
      default : ingress;
    }
}
parser Nunnelly {
   set_metadata( Camden.Maljamar, current( 0, 16 ) );
   set_metadata( Camden.Narka, 0 );
   set_metadata( Wimberley.Randle, 1 );
   return ingress;
}
parser Nixon {
   set_metadata(Wimberley.Randle, 1);
   extract(Camden);
   extract(Hampton);
   return ingress;
}
parser Maryville {
   set_metadata(Wimberley.Timbo, 1);
   set_metadata(Wimberley.Randle, 1);
   extract(Camden);
   extract(Gandy);
   return ingress;
}
parser Sieper {
   set_metadata(Wimberley.Pilger, 2);
   return Wardville;
}
parser Harris {
   set_metadata(Wimberley.Pilger, 2);
   return Gerster;
}
parser Kaltag {
   extract(Mishicot);
   return select(Mishicot.Olcott, Mishicot.Chouteau, Mishicot.Quamba, Mishicot.VanZandt, Mishicot.Tonkawa,
             Mishicot.Mancelona, Mishicot.Minburn, Mishicot.Coronado, Mishicot.Cataract) {
      0x0800 : Sieper;
      0x86dd : Harris;
      default : ingress;
   }
}
parser Nashoba {
   extract(Northlake);
   set_metadata(Wimberley.Pilger, 1);
   return McGrady;
}
field_list Clovis {
    LaPointe.Sofia;
    LaPointe.Wabbaseka;
    LaPointe.Baldwin;
    LaPointe.Mather;
    LaPointe.Marie;
    LaPointe.Upalco;
    LaPointe.Acree;
    LaPointe.Fairborn;
    LaPointe.Isleta;
    LaPointe.Alderson;
    LaPointe.Culloden;
    LaPointe.Parrish;
}
field_list_calculation Switzer {
    input {
        Clovis;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field LaPointe.Makawao {
    verify Switzer;
    update Switzer;
}
parser Wardville {
   extract( LaPointe );
   set_metadata(Gambrill.Higginson, LaPointe.Alderson);
   set_metadata(Gambrill.Ardara, LaPointe.Isleta);
   set_metadata(Gambrill.Flasher, LaPointe.Marie);
   set_metadata(Gambrill.Renville, 0);
   set_metadata(Gambrill.Meservey, 1);
   return select(LaPointe.Fairborn, LaPointe.Wabbaseka, LaPointe.Alderson) {
      0x501 : Steprock;
      0x511 : Sheldahl;
      0x506 : Anita;
      0 mask 0xFF7000 : Swisshome;
      default : ingress;
   }
}
parser Swisshome {
   set_metadata(Wimberley.Winner, 1);
   return ingress;
}
parser Gerster {
   extract( Crary );
   set_metadata(Gambrill.Higginson, Crary.Lubeck);
   set_metadata(Gambrill.Ardara, Crary.Windham);
   set_metadata(Gambrill.Flasher, Crary.Hackney);
   set_metadata(Gambrill.Renville, 1);
   set_metadata(Gambrill.Meservey, 0);
   return select(Crary.Lubeck) {
      0x3a : Steprock;
      17 : Sheldahl;
      6 : Anita;
      default : Swisshome;
   }
}
parser Steprock {
   set_metadata( Wimberley.Topanga, current( 0, 16 ) );
   set_metadata( Wimberley.Penzance, 1 );
   set_metadata( Wimberley.Winner, 1 );
   return ingress;
}
parser Sheldahl {
   set_metadata( Wimberley.Topanga, current( 0, 16 ) );
   set_metadata( Wimberley.Rockport, current( 16, 16 ) );
   set_metadata( Wimberley.Penzance, 1 );
   set_metadata( Wimberley.Winner, 1);
   return ingress;
}
parser Anita {
   set_metadata( Wimberley.Topanga, current( 0, 16 ) );
   set_metadata( Wimberley.Rockport, current( 16, 16 ) );
   set_metadata( Wimberley.Cockrum, current( 104, 8 ) );
   set_metadata( Wimberley.Penzance, 1 );
   set_metadata( Wimberley.Winner, 1 );
   set_metadata( Wimberley.Hanapepe, 1 );
   extract(Wenona);
   extract(Azalia);
   return ingress;
}
parser McGrady {
   extract( Tanacross );
   return select( Tanacross.Pittsboro ) {
      0x0800: Wardville;
      0x86dd: Gerster;
      default: ingress;
   }
}
@pragma pa_no_init ingress Wimberley.Robstown
@pragma pa_no_init ingress Wimberley.Wingate
@pragma pa_no_init ingress Wimberley.ElToro
@pragma pa_no_init ingress Wimberley.Rendon
//@pragma pa_container_size ingress Wimberley.Pilger 32
metadata Offerle Wimberley;
@pragma pa_no_init ingress Mishawaka.PeaRidge
@pragma pa_no_init ingress Mishawaka.Prosser
@pragma pa_no_init ingress Mishawaka.Bridgton
@pragma pa_no_init ingress Mishawaka.Tennessee
metadata Warba Mishawaka;
metadata Sagerton Wyatte;
metadata Arroyo Sargeant;
metadata Caputa Lugert;
metadata Essington Gambrill;
metadata Ridgeview Linganore;
metadata Bratenahl Nelson;

@pragma pa_container_size ingress McLean.Chaska 32
metadata Jenera McLean;
#ifdef VAG_FIX
@pragma pa_container_size ingress Cowen.Saltair  32
@pragma pa_container_size ingress Cowen.Goosport 32
@pragma pa_container_size ingress Cowen.Hobergs  32
@pragma pa_container_size ingress Cowen.Connell  32
#endif
metadata LaPlata Cowen;
metadata RoyalOak Perrin;
metadata Bluewater PoleOjea;
metadata Ashville Neosho;
metadata Pollard Campton;
metadata Hawthorn Willette;
metadata OldGlory Beltrami;
@pragma pa_no_init ingress SneeOosh.Gwynn
metadata Allgood SneeOosh;
@pragma pa_no_init ingress Purdon.ElMirage
metadata Pittsburg Purdon;
metadata Machens Quealy;
metadata Machens Osterdock;
action Rehoboth() {
   no_op();
}
action Beechwood() {
   modify_field(Wimberley.Lubec, 1 );
   mark_for_drop();
}
action WebbCity() {
   no_op();
}
action Lathrop(Theba, Kalida, Cache, Ekwok, Conda, Bechyn,
                 Quinault, Dubuque, Chamois) {
    modify_field(Lugert.Baraboo, Theba);
    modify_field(Lugert.Saugatuck, Kalida);
    modify_field(Lugert.Wakenda, Cache);
    modify_field(Lugert.Canjilon, Ekwok);
    modify_field(Lugert.Shade, Conda);
    modify_field(Lugert.Chappells, Bechyn);
    modify_field(Lugert.Renick, Quinault);
    modify_field(Lugert.Laurelton, Dubuque);
    modify_field(Lugert.Oakmont, Chamois);
}

@pragma command_line --no-dead-code-elimination
table Bloomdale {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Lathrop;
    }
    size : 288;
}
control Lisle {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Bloomdale);
    }
}
action RyanPark(Almond, Wymer) {
   modify_field( Mishawaka.Umkumiut, 1 );
   modify_field( Mishawaka.Ammon, Almond);
   modify_field( Wimberley.Heidrick, 1 );
   modify_field( Willette.Caban, Wymer );
}
action Ivins() {
   modify_field( Wimberley.Pinto, 1 );
   modify_field( Wimberley.Baskin, 1 );
}
action Masontown() {
   modify_field( Wimberley.Heidrick, 1 );
}
action Gladstone() {
   modify_field( Wimberley.Heidrick, 1 );
   modify_field( Wimberley.Spanaway, 1 );
}
action Carnero() {
   modify_field( Wimberley.NeckCity, 1 );
}
action Pecos() {
   modify_field( Wimberley.Baskin, 1 );
}
counter Sidon {
   type : packets_and_bytes;
   direct : Kenton;
   min_width: 16;
}
table Kenton {
   reads {
      Lugert.Chappells : exact;
      Kapalua.Lanesboro : ternary;
      Kapalua.Harmony : ternary;
   }
   actions {
      RyanPark;
      Ivins;
      Masontown;
      Carnero;
      Pecos;
      Gladstone;
   }
   size : 1024;
}
action Eucha() {
   modify_field( Wimberley.Fristoe, 1 );
}
table Casselman {
   reads {
      Kapalua.Winters : ternary;
      Kapalua.Berne : ternary;
   }
   actions {
      Eucha;
   }
   size : 512;
}
control Paicines {
   apply( Kenton );
   apply( Casselman );
}
action Kokadjo() {
   modify_field( Linganore.Covington, LaPointe.Culloden );
   modify_field( Linganore.Hotchkiss, LaPointe.Parrish );
   modify_field( Linganore.Forbes, LaPointe.Baldwin );
   modify_field( Nelson.Ickesburg, Crary.WestBend );
   modify_field( Nelson.Sully, Crary.Elsmere );
   modify_field( Nelson.McHenry, Crary.RoseTree );
   modify_field( Nelson.Corry, Crary.Petrey );
   modify_field( Wimberley.Robstown, Tanacross.Lanesboro );
   modify_field( Wimberley.Wingate, Tanacross.Harmony );
   modify_field( Wimberley.ElToro, Tanacross.Winters );
   modify_field( Wimberley.Rendon, Tanacross.Berne );
   modify_field( Wimberley.Anandale, Tanacross.Pittsboro );
   modify_field( Wimberley.Siloam, Gambrill.Flasher );
   modify_field( Wimberley.Pawtucket, Gambrill.Higginson );
   modify_field( Wimberley.Booth, Gambrill.Ardara );
   modify_field( Wimberley.Jenifer, Gambrill.Meservey );
   modify_field( Wimberley.Raritan, Gambrill.Renville );
   modify_field( Wimberley.Luzerne, 0 );
   modify_field( Mishawaka.Bacton, 1 );
   modify_field( Lugert.Renick, 1 );
   modify_field( Lugert.Laurelton, 0 );
   modify_field( Lugert.Oakmont, 0 );
   modify_field( Willette.Horton, 1 );
   modify_field( Willette.Bonney, 1 );
   modify_field( Wimberley.Randle, Wimberley.Winner );
   modify_field( Wimberley.Timbo, Wimberley.Hanapepe );
}
action Gorum() {
   modify_field( Wimberley.Pilger, 0 );
   modify_field( Linganore.Covington, Robert.Culloden );
   modify_field( Linganore.Hotchkiss, Robert.Parrish );
   modify_field( Linganore.Forbes, Robert.Baldwin );
   modify_field( Nelson.Ickesburg, Valencia.WestBend );
   modify_field( Nelson.Sully, Valencia.Elsmere );
   modify_field( Nelson.McHenry, Valencia.RoseTree );
   modify_field( Nelson.Corry, Valencia.Petrey );
   modify_field( Wimberley.Robstown, Kapalua.Lanesboro );
   modify_field( Wimberley.Wingate, Kapalua.Harmony );
   modify_field( Wimberley.ElToro, Kapalua.Winters );
   modify_field( Wimberley.Rendon, Kapalua.Berne );
   modify_field( Wimberley.Anandale, Kapalua.Pittsboro );
   modify_field( Wimberley.Siloam, Gambrill.Berenice );
   modify_field( Wimberley.Pawtucket, Gambrill.Hartfield );
   modify_field( Wimberley.Booth, Gambrill.SourLake );
   modify_field( Wimberley.Jenifer, Gambrill.Virgilina );
   modify_field( Wimberley.Raritan, Gambrill.Amber );
   modify_field( Willette.Franktown, Farson[0].Schleswig );
   modify_field( Wimberley.Luzerne, Gambrill.Nordland );
   modify_field( Wimberley.Topanga, Camden.Maljamar );
   modify_field( Wimberley.Rockport, Camden.Narka );
   modify_field( Wimberley.Cockrum, Gandy.Trona );
}
table Neshoba {
   reads {
      Kapalua.Lanesboro : exact;
      Kapalua.Harmony : exact;
      Robert.Parrish : exact;
      Wimberley.Pilger : exact;
   }
   actions {
      Kokadjo;
      Gorum;
   }
   default_action : Gorum();
   size : 1024;
}
action Oklahoma() {
   modify_field( Wimberley.Almont, Lugert.Wakenda );
   modify_field( Wimberley.Hiwassee, Lugert.Baraboo);
}
action Molson( Crane ) {
   modify_field( Wimberley.Almont, Crane );
   modify_field( Wimberley.Hiwassee, Lugert.Baraboo);
}
action Blakeslee() {
   modify_field( Wimberley.Almont, Farson[0].Bulverde );
   modify_field( Wimberley.Hiwassee, Lugert.Baraboo);
}
table Chatfield {
   reads {
      Lugert.Baraboo : ternary;
      Farson[0] : valid;
      Farson[0].Bulverde : ternary;
   }
   actions {
      Oklahoma;
      Molson;
      Blakeslee;
   }
   size : 4096;
}
action Wisdom( Tuscumbia ) {
   modify_field( Wimberley.Hiwassee, Tuscumbia );
}
action Placida() {
   modify_field( Wimberley.Hauppauge, 1 );
   modify_field( Perrin.Bonduel,
                 1 );
}
table Century {
   reads {
      Robert.Culloden : exact;
   }
   actions {
      Wisdom;
      Placida;
   }
   default_action : Placida;
   size : 4096;
}
action Hoadly( Edinburg, GlenArm, Belle, Aredale, Chehalis,
                        Newpoint, Freeny ) {
   modify_field( Wimberley.Almont, Edinburg );
   modify_field( Wimberley.Hanford, Edinburg );
   modify_field( Wimberley.Willard, Freeny );
   BigBow(GlenArm, Belle, Aredale, Chehalis,
                        Newpoint );
}
action Advance() {
   modify_field( Wimberley.Monohan, 1 );
}
table Sixteen {
   reads {
      Northlake.Ramapo : exact;
   }
   actions {
      Hoadly;
      Advance;
   }
   size : 4096;
}
action BigBow(Gamewell, Sudbury, DuPont, Odenton,
                        Inola ) {
   modify_field( Cowen.Welcome, Gamewell );
   modify_field( Cowen.Saltair, Sudbury );
   modify_field( Cowen.Goosport, DuPont );
   modify_field( Cowen.Hobergs, Odenton );
   modify_field( Cowen.Connell, Inola );
}
action Jones(Seibert, Ishpeming, Dixfield, OldMinto,
                        Austell ) {
   modify_field( Wimberley.Hanford, Lugert.Wakenda );
   BigBow(Seibert, Ishpeming, Dixfield, OldMinto,
                        Austell );
}
action Lucile(Harvey, Fackler, Overbrook, TenSleep,
                        Grasmere, Laurie ) {
   modify_field( Wimberley.Hanford, Harvey );
   BigBow(Fackler, Overbrook, TenSleep, Grasmere,
                        Laurie );
}
action BigRock(Bigspring, Buckholts, Frontenac, Mendham,
                        Shanghai ) {
   modify_field( Wimberley.Hanford, Farson[0].Bulverde );
   BigBow(Bigspring, Buckholts, Frontenac, Mendham,
                        Shanghai );
}
table Firebrick {
   reads {
      Lugert.Wakenda : exact;
   }
   actions {
      Rehoboth;
      Jones;
   }
   size : 4096;
}
@pragma action_default_only Rehoboth
table Kosmos {
   reads {
      Lugert.Baraboo : exact;
      Farson[0].Bulverde : exact;
   }
   actions {
      Lucile;
      Rehoboth;
   }
   size : 1024;
}
table Buckfield {
   reads {
      Farson[0].Bulverde : exact;
   }
   actions {
      Rehoboth;
      BigRock;
   }
   size : 4096;
}
control Rugby {
   apply( Neshoba ) {
         Kokadjo {
            apply( Century );
            apply( Sixteen );
         }
         Gorum {
            if ( not valid(Levasy) and Lugert.Canjilon == 1 ) {
               apply( Chatfield );
            }
            if ( valid( Farson[ 0 ] ) ) {
               apply( Kosmos ) {
                  Rehoboth {
                     apply( Buckfield );
                  }
               }
            } else {
               apply( Firebrick );
            }
         }
   }
}
register Bosworth {
    width : 1;
    static : Doris;
    instance_count : 262144;
}
register Tuttle {
    width : 1;
    static : Vestaburg;
    instance_count : 262144;
}
blackbox stateful_alu ShadeGap {
    reg : Bosworth;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : McLean.Gorman;
}
blackbox stateful_alu ShowLow {
    reg : Tuttle;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst : McLean.Chaska;
}
field_list Azusa {
    Lugert.Chappells;
    Farson[0].Bulverde;
}
field_list_calculation Parchment {
    input { Azusa; }
    algorithm: identity;
    output_width: 18;
}
action Vining() {
    ShadeGap.execute_stateful_alu_from_hash(Parchment);
}
action Deport() {
    ShowLow.execute_stateful_alu_from_hash(Parchment);
}
table Doris {
    actions {
      Vining;
    }
    default_action : Vining;
    size : 1;
}
table Vestaburg {
    actions {
      Deport;
    }
    default_action : Deport;
    size : 1;
}
action Conner(Headland) {
    modify_field(McLean.Chaska, Headland);
}
@pragma use_hash_action 0
table Seattle {
    reads {
       Lugert.Chappells : exact;
    }
    actions {
      Conner;
    }
    size : 64;
}
action Winside() {
   modify_field( Wimberley.Kasilof, Lugert.Wakenda );
   modify_field( Wimberley.Wakita, 0 );
}
table Depew {
   actions {
      Winside;
   }
   size : 1;
}
action Knights() {
   modify_field( Wimberley.Kasilof, Farson[0].Bulverde );
   modify_field( Wimberley.Wakita, 1 );
}
table Woodridge {
   actions {
      Knights;
   }
   size : 1;
}
control Snowflake {
   if ( valid( Farson[ 0 ] ) ) {
      apply( Woodridge );
      if( Lugert.Shade == 1 ) {
         apply( Doris );
         apply( Vestaburg );
      }
   } else {
      apply( Depew );
      if( Lugert.Shade == 1 ) {
         apply( Seattle );
      }
   }
}
field_list Hyrum {
   Kapalua.Lanesboro;
   Kapalua.Harmony;
   Kapalua.Winters;
   Kapalua.Berne;
   Kapalua.Pittsboro;
}
field_list Alcoma {
   Robert.Alderson;
   Robert.Culloden;
   Robert.Parrish;
}
field_list Wheatland {
   Valencia.WestBend;
   Valencia.Elsmere;
   Valencia.RoseTree;
   Valencia.Lubeck;
}
field_list Kurthwood {
   Robert.Culloden;
   Robert.Parrish;
   Camden.Maljamar;
   Camden.Narka;
}
field_list_calculation Success {
    input {
        Hyrum;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Reager {
    input {
        Alcoma;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Anniston {
    input {
        Wheatland;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Pittwood {
    input {
        Kurthwood;
    }
    algorithm : crc32;
    output_width : 32;
}
action Delmont() {
    modify_field_with_hash_based_offset(Campton.Lueders, 0,
                                        Success, 4294967296);
}
action CapRock() {
    modify_field_with_hash_based_offset(Campton.Camilla, 0,
                                        Reager, 4294967296);
}
action Calcasieu() {
    modify_field_with_hash_based_offset(Campton.Camilla, 0,
                                        Anniston, 4294967296);
}
action Kalaloch() {
    modify_field_with_hash_based_offset(Campton.Breese, 0,
                                        Pittwood, 4294967296);
}
table Galestown {
   actions {
      Delmont;
   }
   size: 1;
}
control Gerlach {
   apply(Galestown);
}
table Arnold {
   actions {
      CapRock;
   }
   size: 1;
}
table Lignite {
   actions {
      Calcasieu;
   }
   size: 1;
}
control Alvwood {
   if ( valid( Robert ) ) {
      apply(Arnold);
   } else {
      if ( valid( Valencia ) ) {
         apply(Lignite);
      }
   }
}
table Gowanda {
   actions {
      Kalaloch;
   }
   size: 1;
}
control Preston {
   if ( valid( Hampton ) ) {
      apply(Gowanda);
   }
}
action Varna() {
    modify_field(Neosho.FlatRock, Campton.Lueders);
}
action Seguin() {
    modify_field(Neosho.FlatRock, Campton.Camilla);
}
action Sumner() {
    modify_field(Neosho.FlatRock, Campton.Breese);
}
@pragma action_default_only Rehoboth
@pragma immediate 0
table Highfill {
   reads {
      Azalia.valid : ternary;
      Vacherie.valid : ternary;
      LaPointe.valid : ternary;
      Crary.valid : ternary;
      Tanacross.valid : ternary;
      Gandy.valid : ternary;
      Hampton.valid : ternary;
      Robert.valid : ternary;
      Valencia.valid : ternary;
      Kapalua.valid : ternary;
   }
   actions {
      Varna;
      Seguin;
      Sumner;
      Rehoboth;
   }
   size: 256;
}
action Daysville() {
    modify_field(Neosho.Shingler, Campton.Breese);
}
@pragma immediate 0
table Goulding {
   reads {
      Azalia.valid : ternary;
      Vacherie.valid : ternary;
      Gandy.valid : ternary;
      Hampton.valid : ternary;
   }
   actions {
      Daysville;
      Rehoboth;
   }
   size: 6;
}
control Beasley {
   apply(Goulding);
   apply(Highfill);
}
counter Penrose {
   type : packets_and_bytes;
   direct : Goulds;
   min_width: 16;
}
table Goulds {
   reads {
      Lugert.Chappells : exact;
      McLean.Chaska : ternary;
      McLean.Gorman : ternary;
      Wimberley.Monohan : ternary;
      Wimberley.Fristoe : ternary;
      Wimberley.Pinto : ternary;
   }
   actions {
      Beechwood;
      Rehoboth;
   }
   default_action : Rehoboth();
   size : 512;
}
table Bowen {
   reads {
      Wimberley.ElToro : exact;
      Wimberley.Rendon : exact;
      Wimberley.Almont : exact;
   }
   actions {
      Beechwood;
      Rehoboth;
   }
   default_action : Rehoboth();
   size : 4096;
}
action Topawa() {
   modify_field(Wimberley.Harriston, 1 );
   modify_field(Perrin.Bonduel,
                0);
}
table Millsboro {
   reads {
      Wimberley.ElToro : exact;
      Wimberley.Rendon : exact;
      Wimberley.Almont : exact;
      Wimberley.Hiwassee : exact;
   }
   actions {
      WebbCity;
      Topawa;
   }
   default_action : Topawa();
   size : 65536;
   support_timeout : true;
}
action National( Korbel, PellLake ) {
   modify_field( Wimberley.Coryville, Korbel );
   modify_field( Wimberley.Willard, PellLake );
}
action Humacao() {
   modify_field( Wimberley.Willard, 1 );
}
table Sandston {
   reads {
      Wimberley.Almont mask 0xfff : exact;
   }
   actions {
      National;
      Humacao;
      Rehoboth;
   }
   default_action : Rehoboth();
   size : 4096;
}
action Pearcy() {
   modify_field( Cowen.McClusky, 1 );
}
table Leoma {
   reads {
      Wimberley.Hanford : ternary;
      Wimberley.Robstown : exact;
      Wimberley.Wingate : exact;
   }
   actions {
      Pearcy;
   }
   size: 512;
}
control Royston {
   apply( Goulds ) {
      Rehoboth {
         apply( Bowen ) {
            Rehoboth {
               if (Lugert.Saugatuck == 0 and Wimberley.Hauppauge == 0) {
                  apply( Millsboro );
               }
               apply( Sandston );
               apply(Leoma);
            }
         }
      }
   }
}
field_list Drifton {
    Perrin.Bonduel;
    Wimberley.ElToro;
    Wimberley.Rendon;
    Wimberley.Almont;
    Wimberley.Hiwassee;
}
action Tusculum() {
   generate_digest(0, Drifton);
}
table Normangee {
   actions {
      Tusculum;
   }
   size : 1;
}
control Floral {
   if (Wimberley.Harriston == 1) {
      apply( Normangee );
   }
}
action Suamico( Rotan, Joice ) {
   modify_field( Nelson.Casnovia, Rotan );
   modify_field( PoleOjea.Elmwood, Joice );
}
@pragma action_default_only Donna
table Quebrada {
   reads {
      Cowen.Welcome : exact;
      Nelson.Sully mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Suamico;
      Donna;
   }
   size : 8192;
}
@pragma atcam_partition_index Nelson.Casnovia
@pragma atcam_number_partitions 8192
table Teaneck {
   reads {
      Nelson.Casnovia : exact;
      Nelson.Sully mask 0x000007FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Newsome;
      SoapLake;
      Rehoboth;
   }
   default_action : Rehoboth();
   size : 65536;
}
action Cedonia( Cragford, Millstone ) {
   modify_field( Nelson.Vinemont, Cragford );
   modify_field( PoleOjea.Elmwood, Millstone );
}
@pragma action_default_only Rehoboth
table Robbs {
   reads {
      Cowen.Welcome : exact;
      Nelson.Sully : lpm;
   }
   actions {
      Cedonia;
      Rehoboth;
   }
   size : 2048;
}
@pragma atcam_partition_index Nelson.Vinemont
@pragma atcam_number_partitions 2048
table Miller {
   reads {
      Nelson.Vinemont : exact;
      Nelson.Sully mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Newsome;
      SoapLake;
      Rehoboth;
   }
   default_action : Rehoboth();
   size : 16384;
}
@pragma action_default_only Donna
@pragma idletime_precision 1
table Swain {
   reads {
      Cowen.Welcome : exact;
      Linganore.Hotchkiss : lpm;
   }
   actions {
      Newsome;
      SoapLake;
      Donna;
   }
   size : 1024;
   support_timeout : true;
}
action Silco( Verndale, Beatrice ) {
   modify_field( Linganore.Logandale, Verndale );
   modify_field( PoleOjea.Elmwood, Beatrice );
}
@pragma action_default_only Rehoboth
table SanJuan {
   reads {
      Cowen.Welcome : exact;
      Linganore.Hotchkiss : lpm;
   }
   actions {
      Silco;
      Rehoboth;
   }
   size : 16384;
}
@pragma ways 2
@pragma atcam_partition_index Linganore.Logandale
@pragma atcam_number_partitions 16384
table Hisle {
   reads {
      Linganore.Logandale : exact;
      Linganore.Hotchkiss mask 0x000fffff : lpm;
   }
   actions {
      Newsome;
      SoapLake;
      Rehoboth;
   }
   default_action : Rehoboth();
   size : 131072;
}
action Newsome( Loysburg ) {
   modify_field( PoleOjea.Elmwood, Loysburg );
}
@pragma idletime_precision 1
table Kilbourne {
   reads {
      Cowen.Welcome : exact;
      Linganore.Hotchkiss : exact;
   }
   actions {
      Newsome;
      SoapLake;
      Rehoboth;
   }
   default_action : Rehoboth();
   size : 65536;
   support_timeout : true;
}
@pragma idletime_precision 1
table Ivanpah {
   reads {
      Cowen.Welcome : exact;
      Nelson.Sully : exact;
   }
   actions {
      Newsome;
      SoapLake;
      Rehoboth;
   }
   default_action : Rehoboth();
   size : 65536;
   support_timeout : true;
}
action WarEagle(Glenolden, Sprout, ElCentro) {
   modify_field(Mishawaka.Ulysses, ElCentro);
   modify_field(Mishawaka.PeaRidge, Glenolden);
   modify_field(Mishawaka.Prosser, Sprout);
   modify_field(Mishawaka.Donald, 1);
   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}
action Hooks() {
   Beechwood();
}
action Waipahu(Lahaina) {
   modify_field(Mishawaka.Umkumiut, 1);
   modify_field(Mishawaka.Ammon, Lahaina);
}
action Donna(Corder) {
   modify_field( Mishawaka.Umkumiut, 1 );
   modify_field( Mishawaka.Ammon, 9 );
}
table Rockland {
   reads {
      PoleOjea.Elmwood : exact;
   }
   actions {
      WarEagle;
      Hooks;
      Waipahu;
   }
   size : 65536;
}
action Slagle( Judson ) {
   modify_field(Mishawaka.Umkumiut, 1);
   modify_field(Mishawaka.Ammon, Judson);
}
table Chenequa {
   actions {
      Slagle;
   }
   default_action: Slagle(0);
   size : 1;
}
control Fajardo {
   if ( Wimberley.Lubec == 0 and Cowen.McClusky == 1 ) {
      if ( ( Cowen.Saltair == 1 ) and ( Wimberley.Jenifer == 1 ) ) {
         apply( Kilbourne ) {
            Rehoboth {
               apply(SanJuan);
            }
         }
      } else if ( ( Cowen.Goosport == 1 ) and ( Wimberley.Raritan == 1 ) ) {
         apply( Ivanpah ) {
            Rehoboth {
               apply( Robbs );
            }
         }
      }
   }
}
control Justice {
   if ( Wimberley.Lubec == 0 and Cowen.McClusky == 1 ) {
      if ( ( Cowen.Saltair == 1 ) and ( Wimberley.Jenifer == 1 ) ) {
         if ( Linganore.Logandale != 0 ) {
            apply( Hisle );
         } else if ( PoleOjea.Elmwood == 0 and PoleOjea.Wadley == 0 ) {
            apply( Swain );
         }
      } else if ( ( Cowen.Goosport == 1 ) and ( Wimberley.Raritan == 1 ) ) {
         if ( Nelson.Vinemont != 0 ) {
            apply( Miller );
         } else if ( PoleOjea.Elmwood == 0 and PoleOjea.Wadley == 0 ) {
            apply( Quebrada ) {
               Suamico {
                  apply( Teaneck );
               }
            }
         }
      } else if( Wimberley.Willard == 1 ) {
         apply( Chenequa );
      }
   }
}
control Haven {
   if( PoleOjea.Elmwood != 0 ) {
      apply( Rockland );
   }
}
action SoapLake( Colmar ) {
   modify_field( PoleOjea.Wadley, Colmar );
}
field_list Newkirk {
   Neosho.Shingler;
}
field_list_calculation Rocklin {
    input {
        Newkirk;
    }
    algorithm : identity;
    output_width : 66;
}
action_selector Wauseon {
   selection_key : Rocklin;
   selection_mode : resilient;
}
action_profile OakLevel {
   actions {
      Newsome;
   }
   size : 65536;
   dynamic_action_selection : Wauseon;
}
@pragma selector_max_group_size 256
table Balmville {
   reads {
      PoleOjea.Wadley : exact;
   }
   action_profile : OakLevel;
   size : 2048;
}
control Caliente {
   if ( PoleOjea.Wadley != 0 ) {
      apply( Balmville );
   }
}
field_list Florien {
   Neosho.FlatRock;
}
field_list_calculation Ramhurst {
    input {
        Florien;
    }
    algorithm : identity;
    output_width : 51;
}
action_selector Canovanas {
    selection_key : Ramhurst;
    selection_mode : resilient;
}
action Homeacre(Pengilly) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Pengilly);
}
action_profile BlueAsh {
    actions {
        Homeacre;
        Rehoboth;
    }
    size : 1024;
    dynamic_action_selection : Canovanas;
}
table Dowell {
   reads {
      Mishawaka.Cornville : exact;
   }
   action_profile: BlueAsh;
   size : 1024;
}
control Mertens {
   if ((Mishawaka.Cornville & 0x2000) == 0x2000) {
      apply(Dowell);
   }
}
action Crown() {
   modify_field(Mishawaka.PeaRidge, Wimberley.Robstown);
   modify_field(Mishawaka.Prosser, Wimberley.Wingate);
   modify_field(Mishawaka.Bridgton, Wimberley.ElToro);
   modify_field(Mishawaka.Tennessee, Wimberley.Rendon);
   modify_field(Mishawaka.Ulysses, Wimberley.Almont);
   invalidate( ig_intr_md_for_tm.ucast_egress_port );
}
table Pekin {
   actions {
      Crown;
   }
   default_action : Crown();
   size : 1;
}
control Cabot {
   apply( Pekin );
}
action Anacortes() {
   modify_field(Mishawaka.Sunbury, 1);
   modify_field(Mishawaka.Rodeo, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Wimberley.Willard);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Mishawaka.Ulysses);
}
action Evendale() {
}
@pragma ways 1
table Silica {
   reads {
      Mishawaka.PeaRidge : exact;
      Mishawaka.Prosser : exact;
   }
   actions {
      Anacortes;
      Evendale;
   }
   default_action : Evendale;
   size : 1;
}
action Gravette() {
   modify_field(Mishawaka.Macland, 1);
   modify_field(Mishawaka.Chatcolet, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Mishawaka.Ulysses, 4096);
}
table Whitten {
   actions {
      Gravette;
   }
   default_action : Gravette;
   size : 1;
}
action Fairhaven() {
   modify_field(Mishawaka.Luning, 1);
   modify_field(Mishawaka.Rodeo, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Mishawaka.Ulysses);
}
table Tappan {
   actions {
      Fairhaven;
   }
   default_action : Fairhaven();
   size : 1;
}
action Donner(CleElum) {
   modify_field(Mishawaka.Sodaville, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, CleElum);
   modify_field(Mishawaka.Cornville, CleElum);
}
action Escondido(Protem) {
   modify_field(Mishawaka.Macland, 1);
   modify_field(Mishawaka.Sunset, Protem);
}
action Tuskahoma() {
}
table BallClub {
   reads {
      Mishawaka.PeaRidge : exact;
      Mishawaka.Prosser : exact;
      Mishawaka.Ulysses : exact;
   }
   actions {
      Donner;
      Escondido;
      Beechwood;
      Tuskahoma;
   }
   default_action : Tuskahoma();
   size : 65536;
}
control Sanford {
   if (Wimberley.Lubec == 0 and not valid(Levasy) ) {
      apply(BallClub) {
         Tuskahoma {
            apply(Silica) {
               Evendale {
                  if ((Mishawaka.PeaRidge & 0x010000) == 0x010000) {
                     apply(Whitten);
                  } else {
                     apply(Tappan);
                  }
               }
            }
         }
      }
   }
}
action Lucien() {
   modify_field(Wimberley.Mayview, 1);
   Beechwood();
}
table Phelps {
   actions {
      Lucien;
   }
   default_action : Lucien;
   size : 1;
}
control Jacobs {
   if (Wimberley.Lubec == 0) {
      if ((Mishawaka.Donald==0) and (Wimberley.Heidrick==0) and (Wimberley.NeckCity==0) and (Wimberley.Hiwassee==Mishawaka.Cornville)) {
         apply(Phelps);
      } else {
         Mertens();
      }
   }
}
action Bienville( Sylvan ) {
   modify_field( Mishawaka.Christina, Sylvan );
}
action Capitola() {
   modify_field( Mishawaka.Christina, Mishawaka.Ulysses );
}
table Goessel {
   reads {
      eg_intr_md.egress_port : exact;
      Mishawaka.Ulysses : exact;
   }
   actions {
      Bienville;
      Capitola;
   }
   default_action : Capitola;
   size : 4096;
}
control Modale {
   apply( Goessel );
}
action Tahuya( RioHondo, Sherwin ) {
   modify_field( Mishawaka.Houston, RioHondo );
   modify_field( Mishawaka.Barber, Sherwin );
}
action Waucousta() {
   modify_field( Mishawaka.Moorcroft, 47 );
   modify_field( Mishawaka.Hahira, 0x0800 );
}
table Pueblo {
   reads {
      Mishawaka.DeLancey : exact;
   }
   actions {
      Tahuya;
      Waucousta;
   }
   size : 8;
}
action Theta( Froid, Ivyland, Wanilla ) {
   modify_field( Mishawaka.Speedway, Froid );
   modify_field( Mishawaka.Natalbany, Ivyland );
   modify_field( Mishawaka.Renton, Wanilla );
}
table Lumberton {
   reads {
      Mishawaka.Wakefield : exact;
   }
   actions {
      Theta;
   }
   size : 4096;
}
action Chalco() {
   modify_field( Mishawaka.Maupin, 1 );
   modify_field( Mishawaka.DeLancey, 2 );
}
action Millikin() {
   modify_field( Mishawaka.Maupin, 1 );
   modify_field( Mishawaka.DeLancey, 1 );
}
table Lenapah {
   reads {
      Mishawaka.Stidham : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Chalco;
      Millikin;
   }
   default_action : Rehoboth();
   size : 16;
}
action Maury(Selby, Valders, Keenes, Kingstown) {
   modify_field( Mishawaka.Covina, Selby );
   modify_field( Mishawaka.Sagamore, Valders );
   modify_field( Mishawaka.Leacock, Keenes );
   modify_field( Mishawaka.Arbyrd, Kingstown );
}
table Virgil {
   reads {
        Mishawaka.Tagus : exact;
   }
   actions {
      Maury;
   }
   size : 256;
}
action Benonine() {
   no_op();
}
action Bowlus() {
   modify_field( Kapalua.Pittsboro, Farson[0].Holden );
   remove_header( Farson[0] );
}
table Felton {
   actions {
      Bowlus;
   }
   default_action : Bowlus;
   size : 1;
}
action Seaforth() {
   no_op();
}
action Salduro() {
   add_header( Farson[ 0 ] );
   modify_field( Farson[0].Bulverde, Mishawaka.Christina );
   modify_field( Farson[0].Holden, Kapalua.Pittsboro );
   modify_field( Farson[0].Kekoskee, Willette.Madill );
   modify_field( Farson[0].Schleswig, Willette.Franktown );
   modify_field( Kapalua.Pittsboro, 0x8100 );
}
table Albin {
   reads {
      Mishawaka.Christina : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Seaforth;
      Salduro;
   }
   default_action : Salduro;
   size : 128;
}
action Nanson() {
   modify_field(Kapalua.Lanesboro, Mishawaka.PeaRidge);
   modify_field(Kapalua.Harmony, Mishawaka.Prosser);
   modify_field(Kapalua.Winters, Mishawaka.Houston);
   modify_field(Kapalua.Berne, Mishawaka.Barber);
}
action Merino() {
   Nanson();
   add_to_field(Robert.Isleta, -1);
   modify_field(Robert.Baldwin, Willette.SomesBar);
}
action Freedom() {
   Nanson();
   add_to_field(Valencia.Windham, -1);
   modify_field(Valencia.Petrey, Willette.SomesBar);
}
action Poulsbo() {
   modify_field(Robert.Baldwin, Willette.SomesBar);
}
action Loogootee() {
   modify_field(Valencia.Petrey, Willette.SomesBar);
}
action Belmore() {
   Salduro();
}
action Reagan( Halfa, Cropper, Livonia, Willows ) {
   add_header( McAdams );
   modify_field( McAdams.Lanesboro, Halfa );
   modify_field( McAdams.Harmony, Cropper );
   modify_field( McAdams.Winters, Livonia );
   modify_field( McAdams.Berne, Willows );
   modify_field( McAdams.Pittsboro, 0xBF00 );
   add_header( Levasy );
   modify_field( Levasy.Sutherlin, Mishawaka.Covina );
   modify_field( Levasy.RowanBay, Mishawaka.Sagamore );
   modify_field( Levasy.Melrude, Mishawaka.Leacock );
   modify_field( Levasy.Tularosa, Mishawaka.Arbyrd );
   modify_field( Levasy.Highcliff, Mishawaka.Ammon );
}
action Husum() {
   remove_header( Northlake );
   remove_header( Hampton );
   remove_header( Camden );
   copy_header( Kapalua, Tanacross );
   remove_header( Tanacross );
   remove_header( Robert );
}
action Ireton() {
   remove_header( McAdams );
   remove_header( Levasy );
}
action Sawyer() {
   Husum();
   modify_field(LaPointe.Baldwin, Willette.SomesBar);
}
action Grigston() {
   Husum();
   modify_field(Crary.Petrey, Willette.SomesBar);
}
table Weslaco {
   reads {
      Mishawaka.Bacton : exact;
      Mishawaka.DeLancey : exact;
      Mishawaka.Donald : exact;
      Robert.valid : ternary;
      Valencia.valid : ternary;
      LaPointe.valid : ternary;
      Crary.valid : ternary;
   }
   actions {
      Merino;
      Freedom;
      Poulsbo;
      Loogootee;
      Belmore;
      Reagan;
      Ireton;
      Husum;
      Sawyer;
      Grigston;
   }
   size : 512;
}
control Myrick {
   apply( Felton );
}
control Shirley {
   apply( Albin );
}
control Tarlton {
   apply( Lenapah ) {
      Rehoboth {
         apply( Pueblo );
         apply( Lumberton );
      }
   }
   apply( Virgil );
   apply( Weslaco );
}
field_list Cloverly {
    Perrin.Bonduel;
    Wimberley.Almont;
    Tanacross.Winters;
    Tanacross.Berne;
    Robert.Culloden;
}
action Huffman() {
   generate_digest(0, Cloverly);
}
table Victoria {
   actions {
      Huffman;
   }
   default_action : Huffman;
   size : 1;
}
control Wamesit {
   if (Wimberley.Hauppauge == 1) {
      apply(Victoria);
   }
}
action Roggen() {
   modify_field( Willette.Madill, Lugert.Laurelton );
}
action Woolsey() {
   modify_field( Willette.Madill, Farson[0].Kekoskee );
   modify_field( Wimberley.Anandale, Farson[0].Holden );
}
action Merrill() {
   modify_field( Willette.SomesBar, Lugert.Oakmont );
}
action Westvaco() {
   modify_field( Willette.SomesBar, Linganore.Forbes );
}
action Milesburg() {
   modify_field( Willette.SomesBar, Nelson.Corry );
}
action Haugan( LaConner, Draketown ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, LaConner );
   modify_field( ig_intr_md_for_tm.qid, Draketown );
}
table Manakin {
   reads {
     Wimberley.Luzerne : exact;
   }
   actions {
     Roggen;
     Woolsey;
   }
   size : 2;
}
table Mecosta {
   reads {
     Wimberley.Jenifer : exact;
     Wimberley.Raritan : exact;
   }
   actions {
     Merrill;
     Westvaco;
     Milesburg;
   }
   size : 3;
}
table Quitman {
   reads {
      Lugert.Renick : ternary;
      Lugert.Laurelton : ternary;
      Willette.Madill : ternary;
      Willette.SomesBar : ternary;
      Willette.Caban : ternary;
   }
   actions {
      Haugan;
   }
   size : 81;
}
action Lindsborg( Owyhee, Lamar ) {
   bit_or( Willette.Horton, Willette.Horton, Owyhee );
   bit_or( Willette.Bonney, Willette.Bonney, Lamar );
}
table Blairsden {
   actions {
      Lindsborg;
   }
   default_action : Lindsborg(0, 0);
   size : 1;
}
action Perdido( Duster ) {
   modify_field( Willette.SomesBar, Duster );
}
action Lefors( Harold ) {
   modify_field( Willette.Madill, Harold );
}
action Leesport( Harviell, Osage ) {
   modify_field( Willette.Madill, Harviell );
   modify_field( Willette.SomesBar, Osage );
}
table GilaBend {
   reads {
      Lugert.Renick : exact;
      Willette.Horton : exact;
      Willette.Bonney : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Perdido;
      Lefors;
      Leesport;
   }
   size : 512;
}
control Wilson {
   apply( Manakin );
   apply( Mecosta );
}
control Tofte {
   apply( Quitman );
}
control Perryton {
   apply( Blairsden );
   apply( GilaBend );
}
action Achille( NewRome ) {
   modify_field( Willette.Maxwelton, NewRome );
}
action ElkFalls( Ridgewood, Floyd ) {
   Achille( Ridgewood );
   modify_field( ig_intr_md_for_tm.qid, Floyd );
}
table Anson {
   reads {
      Mishawaka.Umkumiut : ternary;
      ig_intr_md_for_tm.copy_to_cpu : ternary;
      Mishawaka.Ammon : ternary;
      Wimberley.Jenifer : ternary;
      Wimberley.Raritan : ternary;
      Wimberley.Anandale : ternary;
      Wimberley.Pawtucket : ternary;
      Wimberley.Booth : ternary;
      Mishawaka.Donald : ternary;
      Camden.Maljamar : ternary;
      Camden.Narka : ternary;
   }
   actions {
      Achille;
      ElkFalls;
   }
   size : 512;
}
meter Saxis {
   type : packets;
   static : Caroleen;
   instance_count : 2304;
}
action Satolah(Turkey) {
   execute_meter( Saxis, Turkey, ig_intr_md_for_tm.packet_color );
}
table Caroleen {
   reads {
      Lugert.Chappells : exact;
      Willette.Maxwelton : exact;
   }
   actions {
      Satolah;
   }
   size : 2304;
}
control Magoun {
   if ( Lugert.Shade != 0 ) {
      apply( Anson );
   }
}
control Finley {
    if ( (
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x1 ) == 0 ) ) and ( Mishawaka.Umkumiut == 1 ) ) or
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x2 ) == 0 ) ) and ( ig_intr_md_for_tm.copy_to_cpu == 1 ) )
       ) ) {
      apply( Caroleen );
   }
}
action Ahuimanu( Lasker ) {
   modify_field( Mishawaka.Stidham, 0 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Lasker );
   modify_field( Mishawaka.Tagus, ig_intr_md.ingress_port );
}
action Algonquin( Emden ) {
   modify_field( Mishawaka.Stidham, 1 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Emden );
   modify_field( Mishawaka.Tagus, ig_intr_md.ingress_port );
}
action McKibben() {
   modify_field( Mishawaka.Stidham, 0 );
}
action Goudeau() {
   modify_field( Mishawaka.Stidham, 1 );
   modify_field( Mishawaka.Tagus, ig_intr_md.ingress_port );
}
@pragma ternary 1
table Dagmar {
   reads {
      Mishawaka.Umkumiut : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      Cowen.McClusky : exact;
      Lugert.Canjilon : ternary;
      Mishawaka.Ammon : ternary;
   }
   actions {
      Ahuimanu;
      Algonquin;
      McKibben;
      Goudeau;
   }
   size : 512;
}
control Halliday {
   apply( Dagmar );
}
counter LeSueur {
   type : packets_and_bytes;
   instance_count : 1024;
   min_width : 128;
}
action Snohomish( Deferiet ) {
   count( LeSueur, Deferiet );
}
table Pringle {
   reads {
      eg_intr_md.egress_port mask 0x7f: exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }
   actions {
     Snohomish;
   }
   size : 1024;
}
control Herod {
   apply( Pringle );
}
action Emory()
{
   Beechwood();
}
action Richvale()
{
   modify_field(Mishawaka.Bacton, 2);
   bit_or(Mishawaka.Cornville, 0x2000, Levasy.Tularosa);
}
action Bangor( Padroni ) {
   modify_field(Mishawaka.Bacton, 2);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Padroni);
   modify_field(Mishawaka.Cornville, Padroni);
}
table Gibsland {
   reads {
      Levasy.Sutherlin : exact;
      Levasy.RowanBay : exact;
      Levasy.Melrude : exact;
      Levasy.Tularosa : exact;
   }
   actions {
      Richvale;
      Bangor;
      Emory;
   }
   default_action : Emory();
   size : 256;
}
control Mabelle {
   apply( Gibsland );
}
action SnowLake( Tiller, LaLuz, Vinings, Calabasas ) {
   modify_field( Beltrami.Pensaukee, Tiller );
   modify_field( Purdon.Bellville, Vinings );
   modify_field( Purdon.ElMirage, LaLuz );
   modify_field( Purdon.Bayard, Calabasas );
}
table Abraham {
   reads {
     Linganore.Hotchkiss : exact;
     Wimberley.Hanford : exact;
   }
   actions {
      SnowLake;
   }
  size : 16384;
}
action LeCenter(Nanuet, Worthing, Tontogany) {
   modify_field( Purdon.ElMirage, Nanuet );
   modify_field( Purdon.Bellville, Worthing );
   modify_field( Purdon.Bayard, Tontogany );
}
table Merkel {
   reads {
     Linganore.Covington : exact;
     Beltrami.Pensaukee : exact;
   }
   actions {
      LeCenter;
   }
   size : 16384;
}
action Enfield( McQueen, Waring, Newfield ) {
   modify_field( SneeOosh.Gwynn, McQueen );
   modify_field( SneeOosh.Aberfoil, Waring );
   modify_field( SneeOosh.PaloAlto, Newfield );
}
table Longdale {
   reads {
     Mishawaka.PeaRidge : exact;
     Mishawaka.Prosser : exact;
     Mishawaka.Ulysses : exact;
   }
   actions {
      Enfield;
   }
   size : 16384;
}
action Braselton() {
   modify_field( Mishawaka.Rodeo, 1 );
}
action Demarest( Woodward ) {
   Braselton();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Purdon.ElMirage );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Woodward, Purdon.Bayard );
}
action MillHall( Medulla ) {
   Braselton();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, SneeOosh.Gwynn );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Medulla, SneeOosh.PaloAlto );
}
action Macungie( Hopland ) {
   Braselton();
   add( ig_intr_md_for_tm.mcast_grp_a, Mishawaka.Ulysses,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Hopland );
}
action Uniontown() {
   modify_field( Mishawaka.Darco, 1 );
}
table LaFayette {
   reads {
     Purdon.Bellville : ternary;
     Purdon.ElMirage : ternary;
     SneeOosh.Gwynn : ternary;
     SneeOosh.Aberfoil : ternary;
     Wimberley.Pawtucket :ternary;
     Wimberley.Heidrick:ternary;
   }
   actions {
      Demarest;
      MillHall;
      Macungie;
      Uniontown;
   }
   size : 32;
}
control Burgin {
   if( Wimberley.Lubec == 0 and
       Cowen.Hobergs == 1 and
       Wimberley.Spanaway == 1 ) {
      apply( Abraham );
   }
}
control Tusayan {
   if( Beltrami.Pensaukee != 0 ) {
      apply( Merkel );
   }
}
control McCaulley {
   if( Wimberley.Lubec == 0 and Wimberley.Heidrick==1 ) {
      apply( Longdale );
   }
}
control Leeville {
   if( Wimberley.Heidrick == 1 ) {
      apply(LaFayette);
   }
}
action Veteran(Hatteras) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Neosho.FlatRock );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Hatteras );
}
table Charlotte {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Veteran;
    }
    size : 512;
}
control Pierson {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Charlotte);
   }
}
action Lepanto( Onava, Clearmont ) {
   modify_field( Mishawaka.Ulysses, Onava );
   modify_field( Mishawaka.Donald, Clearmont );
}
action Crump() {
   drop();
}
table Asherton {
   reads {
     eg_intr_md.egress_rid: exact;
   }
   actions {
      Lepanto;
   }
   default_action: Crump;
   size : 57344;
}
control Everett {
   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Asherton);
   }
}
counter Shelby {
   type : packets;
   direct: Westoak;
   min_width: 63;
}
table Westoak {
   reads {
     Vergennes.Jeddo mask 0x7fff : exact;
   }
   actions {
      Rehoboth;
   }
   default_action: Rehoboth();
   size : 32768;
}
action Romero() {
   modify_field( Quealy.Parkland, Wimberley.Pawtucket );
   modify_field( Quealy.Robins, Linganore.Forbes );
   modify_field( Quealy.Sewaren, Wimberley.Booth );
   modify_field( Quealy.Jenison, Wimberley.Cockrum );
   bit_xor( Quealy.Seagate, Wimberley.Randle, 1 );
}
action Baltimore() {
   modify_field( Quealy.Parkland, Wimberley.Pawtucket );
   modify_field( Quealy.Robins, Nelson.Corry );
   modify_field( Quealy.Sewaren, Wimberley.Booth );
   modify_field( Quealy.Jenison, Wimberley.Cockrum );
   bit_xor( Quealy.Seagate, Wimberley.Randle, 1 );
}
action Vibbard( Goodrich ) {
   Romero();
   modify_field( Quealy.PawPaw, Goodrich );
}
action Westland( Donegal ) {
   Baltimore();
   modify_field( Quealy.PawPaw, Donegal );
}
table Resaca {
   reads {
     Linganore.Covington : ternary;
   }
   actions {
      Vibbard;
   }
   default_action : Romero;
  size : 2048;
}
table Nerstrand {
   reads {
     Nelson.Ickesburg : ternary;
   }
   actions {
      Westland;
   }
   default_action : Baltimore;
   size : 1024;
}
action Charco( Pendroy ) {
   modify_field( Quealy.Subiaco, Pendroy );
}
table CassCity {
   reads {
     Linganore.Hotchkiss : ternary;
   }
   actions {
      Charco;
   }
   size : 512;
}
table Glassboro {
   reads {
     Nelson.Sully : ternary;
   }
   actions {
      Charco;
   }
   size : 512;
}
action Oldsmar( Naalehu ) {
   modify_field( Quealy.Excel, Naalehu );
}
table Nichols {
   reads {
     Wimberley.Topanga : ternary;
   }
   actions {
      Oldsmar;
   }
   size : 512;
}
action Bieber( Kansas ) {
   modify_field( Quealy.Proctor, Kansas );
}
table Kinde {
   reads {
     Wimberley.Rockport : ternary;
   }
   actions {
      Bieber;
   }
   size : 512;
}
action Sespe( Corvallis ) {
   modify_field( Quealy.Wolford, Corvallis );
}
action Arthur( August ) {
   modify_field( Quealy.Wolford, August );
}
table Ludlam {
   reads {
     Wimberley.Jenifer : exact;
     Wimberley.Raritan : exact;
     Wimberley.Timbo : exact;
     Wimberley.Hanford : exact;
   }
   actions {
      Sespe;
      Rehoboth;
   }
   default_action : Rehoboth();
   size : 4096;
}
table Murdock {
   reads {
     Wimberley.Jenifer : exact;
     Wimberley.Raritan : exact;
     Wimberley.Timbo : exact;
     Lugert.Baraboo : exact;
   }
   actions {
      Arthur;
   }
   size : 512;
}
control PinkHill {
   if( Wimberley.Jenifer == 1 ) {
      apply( Resaca );
      apply( CassCity );
   } else if( Wimberley.Raritan == 1 ) {
      apply( Nerstrand );
      apply( Glassboro );
   }
   if( ( Wimberley.Pilger != 0 and Wimberley.Penzance == 1 ) or
       ( Wimberley.Pilger == 0 and Camden.valid == 1 ) ) {
      apply( Nichols );
      if( Wimberley.Pawtucket != 1 ){
         apply( Kinde );
      }
   }
   apply( Ludlam ) {
      Rehoboth {
         apply( Murdock );
      }
   }
}
action Whitman() {
}
action Hearne() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action Covert() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
}
action Cisne() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
table Stennett {
   reads {
     Vergennes.Jeddo mask 0x00018000 : ternary;
   }
   actions {
      Whitman;
      Hearne;
      Covert;
      Cisne;
   }
   size : 16;
}
control Ravena {
   apply( Stennett );
   apply( Westoak );
}
   metadata Waldo Vergennes;
   action Shelbiana( Luttrell ) {
          max( Vergennes.Jeddo, Vergennes.Jeddo, Luttrell );
   }
@pragma ways 4
table Rehobeth {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : exact;
      Quealy.Subiaco : exact;
      Quealy.Excel : exact;
      Quealy.Proctor : exact;
      Quealy.Parkland : exact;
      Quealy.Robins : exact;
      Quealy.Sewaren : exact;
      Quealy.Jenison : exact;
      Quealy.Seagate : exact;
   }
   actions {
      Shelbiana;
   }
   size : 4096;
}
control Tallassee {
   apply( Rehobeth );
}
table SwissAlp {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Quealy.Excel : ternary;
      Quealy.Proctor : ternary;
      Quealy.Parkland : ternary;
      Quealy.Robins : ternary;
      Quealy.Sewaren : ternary;
      Quealy.Jenison : ternary;
      Quealy.Seagate : ternary;
   }
   actions {
      Shelbiana;
   }
   size : 512;
}
control Livengood {
   apply( SwissAlp );
}
@pragma pa_no_init ingress Paoli.PawPaw
@pragma pa_no_init ingress Paoli.Subiaco
@pragma pa_no_init ingress Paoli.Excel
@pragma pa_no_init ingress Paoli.Proctor
@pragma pa_no_init ingress Paoli.Parkland
@pragma pa_no_init ingress Paoli.Robins
@pragma pa_no_init ingress Paoli.Sewaren
@pragma pa_no_init ingress Paoli.Jenison
@pragma pa_no_init ingress Paoli.Seagate
metadata Machens Paoli;
@pragma ways 4
table Stilson {
   reads {
      Quealy.Wolford : exact;
      Paoli.PawPaw : exact;
      Paoli.Subiaco : exact;
      Paoli.Excel : exact;
      Paoli.Proctor : exact;
      Paoli.Parkland : exact;
      Paoli.Robins : exact;
      Paoli.Sewaren : exact;
      Paoli.Jenison : exact;
      Paoli.Seagate : exact;
   }
   actions {
      Shelbiana;
   }
   size : 8192;
}
action Fireco( Bernice, Sharptown, Wauna, Talbotton, Riverwood, Ontonagon, Sylvester, Waumandee, Grassflat ) {
   bit_and( Paoli.PawPaw, Quealy.PawPaw, Bernice );
   bit_and( Paoli.Subiaco, Quealy.Subiaco, Sharptown );
   bit_and( Paoli.Excel, Quealy.Excel, Wauna );
   bit_and( Paoli.Proctor, Quealy.Proctor, Talbotton );
   bit_and( Paoli.Parkland, Quealy.Parkland, Riverwood );
   bit_and( Paoli.Robins, Quealy.Robins, Ontonagon );
   bit_and( Paoli.Sewaren, Quealy.Sewaren, Sylvester );
   bit_and( Paoli.Jenison, Quealy.Jenison, Waumandee );
   bit_and( Paoli.Seagate, Quealy.Seagate, Grassflat );
}
table Rapids {
   reads {
      Quealy.Wolford : exact;
   }
   actions {
      Fireco;
   }
   default_action : Fireco(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Niota {
   apply( Rapids );
}
control Callimont {
   apply( Stilson );
}
table Suring {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Quealy.Excel : ternary;
      Quealy.Proctor : ternary;
      Quealy.Parkland : ternary;
      Quealy.Robins : ternary;
      Quealy.Sewaren : ternary;
      Quealy.Jenison : ternary;
      Quealy.Seagate : ternary;
   }
   actions {
      Shelbiana;
   }
   size : 512;
}
control Exeter {
   apply( Suring );
}
@pragma ways 4
table Endicott {
   reads {
      Quealy.Wolford : exact;
      Paoli.PawPaw : exact;
      Paoli.Subiaco : exact;
      Paoli.Excel : exact;
      Paoli.Proctor : exact;
      Paoli.Parkland : exact;
      Paoli.Robins : exact;
      Paoli.Sewaren : exact;
      Paoli.Jenison : exact;
      Paoli.Seagate : exact;
   }
   actions {
      Shelbiana;
   }
   size : 4096;
}
action Venice( DeRidder, Cadott, Slick, Abernathy, Fairfield, Piqua, Stanwood, Marysvale, Emblem ) {
   bit_and( Paoli.PawPaw, Quealy.PawPaw, DeRidder );
   bit_and( Paoli.Subiaco, Quealy.Subiaco, Cadott );
   bit_and( Paoli.Excel, Quealy.Excel, Slick );
   bit_and( Paoli.Proctor, Quealy.Proctor, Abernathy );
   bit_and( Paoli.Parkland, Quealy.Parkland, Fairfield );
   bit_and( Paoli.Robins, Quealy.Robins, Piqua );
   bit_and( Paoli.Sewaren, Quealy.Sewaren, Stanwood );
   bit_and( Paoli.Jenison, Quealy.Jenison, Marysvale );
   bit_and( Paoli.Seagate, Quealy.Seagate, Emblem );
}
table Cartago {
   reads {
      Quealy.Wolford : exact;
   }
   actions {
      Venice;
   }
   default_action : Venice(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Segundo {
   apply( Cartago );
}
control Freetown {
   apply( Endicott );
}
table Hiawassee {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Quealy.Excel : ternary;
      Quealy.Proctor : ternary;
      Quealy.Parkland : ternary;
      Quealy.Robins : ternary;
      Quealy.Sewaren : ternary;
      Quealy.Jenison : ternary;
      Quealy.Seagate : ternary;
   }
   actions {
      Shelbiana;
   }
   size : 512;
}
control Nicodemus {
   apply( Hiawassee );
}
@pragma ways 4
table Boutte {
   reads {
      Quealy.Wolford : exact;
      Paoli.PawPaw : exact;
      Paoli.Subiaco : exact;
      Paoli.Excel : exact;
      Paoli.Proctor : exact;
      Paoli.Parkland : exact;
      Paoli.Robins : exact;
      Paoli.Sewaren : exact;
      Paoli.Jenison : exact;
      Paoli.Seagate : exact;
   }
   actions {
      Shelbiana;
   }
   size : 4096;
}
action RichBar( Langtry, Holcut, Cecilton, Rainsburg, Lansdowne, Woodland, Mifflin, Powelton, Parkline ) {
   bit_and( Paoli.PawPaw, Quealy.PawPaw, Langtry );
   bit_and( Paoli.Subiaco, Quealy.Subiaco, Holcut );
   bit_and( Paoli.Excel, Quealy.Excel, Cecilton );
   bit_and( Paoli.Proctor, Quealy.Proctor, Rainsburg );
   bit_and( Paoli.Parkland, Quealy.Parkland, Lansdowne );
   bit_and( Paoli.Robins, Quealy.Robins, Woodland );
   bit_and( Paoli.Sewaren, Quealy.Sewaren, Mifflin );
   bit_and( Paoli.Jenison, Quealy.Jenison, Powelton );
   bit_and( Paoli.Seagate, Quealy.Seagate, Parkline );
}
table Ashley {
   reads {
      Quealy.Wolford : exact;
   }
   actions {
      RichBar;
   }
   default_action : RichBar(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Hillsview {
   apply( Ashley );
}
control Reynolds {
   apply( Boutte );
}
table Elwyn {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Quealy.Excel : ternary;
      Quealy.Proctor : ternary;
      Quealy.Parkland : ternary;
      Quealy.Robins : ternary;
      Quealy.Sewaren : ternary;
      Quealy.Jenison : ternary;
      Quealy.Seagate : ternary;
   }
   actions {
      Shelbiana;
   }
   size : 512;
}
control Tillicum {
   apply( Elwyn );
}
@pragma ways 4
table Othello {
   reads {
      Quealy.Wolford : exact;
      Paoli.PawPaw : exact;
      Paoli.Subiaco : exact;
      Paoli.Excel : exact;
      Paoli.Proctor : exact;
      Paoli.Parkland : exact;
      Paoli.Robins : exact;
      Paoli.Sewaren : exact;
      Paoli.Jenison : exact;
      Paoli.Seagate : exact;
   }
   actions {
      Shelbiana;
   }
   size : 8192;
}
action Antonito( Coachella, Keltys, Ryderwood, Palatine, Neavitt, Radom, Elcho, Doddridge, Absecon ) {
   bit_and( Paoli.PawPaw, Quealy.PawPaw, Coachella );
   bit_and( Paoli.Subiaco, Quealy.Subiaco, Keltys );
   bit_and( Paoli.Excel, Quealy.Excel, Ryderwood );
   bit_and( Paoli.Proctor, Quealy.Proctor, Palatine );
   bit_and( Paoli.Parkland, Quealy.Parkland, Neavitt );
   bit_and( Paoli.Robins, Quealy.Robins, Radom );
   bit_and( Paoli.Sewaren, Quealy.Sewaren, Elcho );
   bit_and( Paoli.Jenison, Quealy.Jenison, Doddridge );
   bit_and( Paoli.Seagate, Quealy.Seagate, Absecon );
}
table Gotham {
   reads {
      Quealy.Wolford : exact;
   }
   actions {
      Antonito;
   }
   default_action : Antonito(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Tramway {
   apply( Gotham );
}
control Green {
   apply( Othello );
}
table Kapowsin {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Quealy.Excel : ternary;
      Quealy.Proctor : ternary;
      Quealy.Parkland : ternary;
      Quealy.Robins : ternary;
      Quealy.Sewaren : ternary;
      Quealy.Jenison : ternary;
      Quealy.Seagate : ternary;
   }
   actions {
      Shelbiana;
   }
   size : 512;
}
control Dabney {
   apply( Kapowsin );
}
@pragma ways 4
table Woodsboro {
   reads {
      Quealy.Wolford : exact;
      Paoli.PawPaw : exact;
      Paoli.Subiaco : exact;
      Paoli.Excel : exact;
      Paoli.Proctor : exact;
      Paoli.Parkland : exact;
      Paoli.Robins : exact;
      Paoli.Sewaren : exact;
      Paoli.Jenison : exact;
      Paoli.Seagate : exact;
   }
   actions {
      Shelbiana;
   }
   size : 8192;
}
action Floris( Rhinebeck, Golden, Franklin, Sunflower, Harbor, Challenge, Protivin, Moorman, Fayette ) {
   bit_and( Paoli.PawPaw, Quealy.PawPaw, Rhinebeck );
   bit_and( Paoli.Subiaco, Quealy.Subiaco, Golden );
   bit_and( Paoli.Excel, Quealy.Excel, Franklin );
   bit_and( Paoli.Proctor, Quealy.Proctor, Sunflower );
   bit_and( Paoli.Parkland, Quealy.Parkland, Harbor );
   bit_and( Paoli.Robins, Quealy.Robins, Challenge );
   bit_and( Paoli.Sewaren, Quealy.Sewaren, Protivin );
   bit_and( Paoli.Jenison, Quealy.Jenison, Moorman );
   bit_and( Paoli.Seagate, Quealy.Seagate, Fayette );
}
table Euren {
   reads {
      Quealy.Wolford : exact;
   }
   actions {
      Floris;
   }
   default_action : Floris(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Hargis {
   apply( Euren );
}
control Kanab {
   apply( Woodsboro );
}
table Weskan {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Quealy.Excel : ternary;
      Quealy.Proctor : ternary;
      Quealy.Parkland : ternary;
      Quealy.Robins : ternary;
      Quealy.Sewaren : ternary;
      Quealy.Jenison : ternary;
      Quealy.Seagate : ternary;
   }
   actions {
      Shelbiana;
   }
   size : 512;
}
control Wyocena {
   apply( Weskan );
}
@pragma ways 4
table Chewalla {
   reads {
      Quealy.Wolford : exact;
      Paoli.PawPaw : exact;
      Paoli.Subiaco : exact;
      Paoli.Excel : exact;
      Paoli.Proctor : exact;
      Paoli.Parkland : exact;
      Paoli.Robins : exact;
      Paoli.Sewaren : exact;
      Paoli.Jenison : exact;
      Paoli.Seagate : exact;
   }
   actions {
      Shelbiana;
   }
   size : 4096;
}
action Calva( Selawik, Aylmer, Atwater, Graford, BigWells, Bogota, Calcium, JimFalls, Lyncourt ) {
   bit_and( Paoli.PawPaw, Quealy.PawPaw, Selawik );
   bit_and( Paoli.Subiaco, Quealy.Subiaco, Aylmer );
   bit_and( Paoli.Excel, Quealy.Excel, Atwater );
   bit_and( Paoli.Proctor, Quealy.Proctor, Graford );
   bit_and( Paoli.Parkland, Quealy.Parkland, BigWells );
   bit_and( Paoli.Robins, Quealy.Robins, Bogota );
   bit_and( Paoli.Sewaren, Quealy.Sewaren, Calcium );
   bit_and( Paoli.Jenison, Quealy.Jenison, JimFalls );
   bit_and( Paoli.Seagate, Quealy.Seagate, Lyncourt );
}
table Hanks {
   reads {
      Quealy.Wolford : exact;
   }
   actions {
      Calva;
   }
   default_action : Calva(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Whitewood {
   apply( Hanks );
}
control Annette {
   apply( Chewalla );
}
table Ludell {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Quealy.Excel : ternary;
      Quealy.Proctor : ternary;
      Quealy.Parkland : ternary;
      Quealy.Robins : ternary;
      Quealy.Sewaren : ternary;
      Quealy.Jenison : ternary;
      Quealy.Seagate : ternary;
   }
   actions {
      Shelbiana;
   }
   size : 512;
}
control Hanahan {
   apply( Ludell );
}
@pragma ways 4
table Parmele {
   reads {
      Quealy.Wolford : exact;
      Paoli.PawPaw : exact;
      Paoli.Subiaco : exact;
      Paoli.Excel : exact;
      Paoli.Proctor : exact;
      Paoli.Parkland : exact;
      Paoli.Robins : exact;
      Paoli.Sewaren : exact;
      Paoli.Jenison : exact;
      Paoli.Seagate : exact;
   }
   actions {
      Shelbiana;
   }
   size : 4096;
}
action Kaeleku( Temelec, Mayday, LakeFork, Montegut, Penitas, Frontier, Twisp, Northboro, Telida ) {
   bit_and( Paoli.PawPaw, Quealy.PawPaw, Temelec );
   bit_and( Paoli.Subiaco, Quealy.Subiaco, Mayday );
   bit_and( Paoli.Excel, Quealy.Excel, LakeFork );
   bit_and( Paoli.Proctor, Quealy.Proctor, Montegut );
   bit_and( Paoli.Parkland, Quealy.Parkland, Penitas );
   bit_and( Paoli.Robins, Quealy.Robins, Frontier );
   bit_and( Paoli.Sewaren, Quealy.Sewaren, Twisp );
   bit_and( Paoli.Jenison, Quealy.Jenison, Northboro );
   bit_and( Paoli.Seagate, Quealy.Seagate, Telida );
}
table Pioche {
   reads {
      Quealy.Wolford : exact;
   }
   actions {
      Kaeleku;
   }
   default_action : Kaeleku(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Castle {
   apply( Pioche );
}
control Simnasho {
   apply( Parmele );
}
table Finlayson {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Quealy.Excel : ternary;
      Quealy.Proctor : ternary;
      Quealy.Parkland : ternary;
      Quealy.Robins : ternary;
      Quealy.Sewaren : ternary;
      Quealy.Jenison : ternary;
      Quealy.Seagate : ternary;
   }
   actions {
      Shelbiana;
   }
   size : 512;
}
control Shobonier {
   apply( Finlayson );
}
   metadata Waldo Murphy;
   action Kenefic( Gresston ) {
          max( Murphy.Jeddo, Murphy.Jeddo, Gresston );
   }
   action Speed() { max( Vergennes.Jeddo, Murphy.Jeddo, Vergennes.Jeddo ); } table LaMarque { actions { Speed; } default_action : Speed; size : 1; } control Leicester { apply( LaMarque ); }
@pragma ways 4
table Dunmore {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : exact;
      Quealy.Subiaco : exact;
      Quealy.Excel : exact;
      Quealy.Proctor : exact;
      Quealy.Parkland : exact;
      Quealy.Robins : exact;
      Quealy.Sewaren : exact;
      Quealy.Jenison : exact;
      Quealy.Seagate : exact;
   }
   actions {
      Kenefic;
   }
   size : 4096;
}
control Carver {
   apply( Dunmore );
}
table LaSalle {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Quealy.Excel : ternary;
      Quealy.Proctor : ternary;
      Quealy.Parkland : ternary;
      Quealy.Robins : ternary;
      Quealy.Sewaren : ternary;
      Quealy.Jenison : ternary;
      Quealy.Seagate : ternary;
   }
   actions {
      Kenefic;
   }
   size : 4096;
}
control Boydston {
   apply( LaSalle );
}
@pragma pa_no_init ingress Newcomb.PawPaw
@pragma pa_no_init ingress Newcomb.Subiaco
@pragma pa_no_init ingress Newcomb.Excel
@pragma pa_no_init ingress Newcomb.Proctor
@pragma pa_no_init ingress Newcomb.Parkland
@pragma pa_no_init ingress Newcomb.Robins
@pragma pa_no_init ingress Newcomb.Sewaren
@pragma pa_no_init ingress Newcomb.Jenison
@pragma pa_no_init ingress Newcomb.Seagate
metadata Machens Newcomb;
@pragma ways 4
table Magma {
   reads {
      Quealy.Wolford : exact;
      Newcomb.PawPaw : exact;
      Newcomb.Subiaco : exact;
      Newcomb.Excel : exact;
      Newcomb.Proctor : exact;
      Newcomb.Parkland : exact;
      Newcomb.Robins : exact;
      Newcomb.Sewaren : exact;
      Newcomb.Jenison : exact;
      Newcomb.Seagate : exact;
   }
   actions {
      Kenefic;
   }
   size : 4096;
}
action Macedonia( Northway, Gower, Domestic, Rowlett, Govan, Westline, Follett, Suwannee, Trilby ) {
   bit_and( Newcomb.PawPaw, Quealy.PawPaw, Northway );
   bit_and( Newcomb.Subiaco, Quealy.Subiaco, Gower );
   bit_and( Newcomb.Excel, Quealy.Excel, Domestic );
   bit_and( Newcomb.Proctor, Quealy.Proctor, Rowlett );
   bit_and( Newcomb.Parkland, Quealy.Parkland, Govan );
   bit_and( Newcomb.Robins, Quealy.Robins, Westline );
   bit_and( Newcomb.Sewaren, Quealy.Sewaren, Follett );
   bit_and( Newcomb.Jenison, Quealy.Jenison, Suwannee );
   bit_and( Newcomb.Seagate, Quealy.Seagate, Trilby );
}
table Pearl {
   reads {
      Quealy.Wolford : exact;
   }
   actions {
      Macedonia;
   }
   default_action : Macedonia(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Readsboro {
   apply( Pearl );
}
control FordCity {
   apply( Magma );
}
table Norfork {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Quealy.Excel : ternary;
      Quealy.Proctor : ternary;
      Quealy.Parkland : ternary;
      Quealy.Robins : ternary;
      Quealy.Sewaren : ternary;
      Quealy.Jenison : ternary;
      Quealy.Seagate : ternary;
   }
   actions {
      Kenefic;
   }
   size : 512;
}
control Rienzi {
   apply( Norfork );
}
@pragma ways 4
table Berea {
   reads {
      Quealy.Wolford : exact;
      Newcomb.PawPaw : exact;
      Newcomb.Subiaco : exact;
      Newcomb.Excel : exact;
      Newcomb.Proctor : exact;
      Newcomb.Parkland : exact;
      Newcomb.Robins : exact;
      Newcomb.Sewaren : exact;
      Newcomb.Jenison : exact;
      Newcomb.Seagate : exact;
   }
   actions {
      Kenefic;
   }
   size : 4096;
}
action Ayden( Raiford, Sopris, Maywood, Weyauwega, Sledge, Cordell, Paisley, Hines, Sweeny ) {
   bit_and( Newcomb.PawPaw, Quealy.PawPaw, Raiford );
   bit_and( Newcomb.Subiaco, Quealy.Subiaco, Sopris );
   bit_and( Newcomb.Excel, Quealy.Excel, Maywood );
   bit_and( Newcomb.Proctor, Quealy.Proctor, Weyauwega );
   bit_and( Newcomb.Parkland, Quealy.Parkland, Sledge );
   bit_and( Newcomb.Robins, Quealy.Robins, Cordell );
   bit_and( Newcomb.Sewaren, Quealy.Sewaren, Paisley );
   bit_and( Newcomb.Jenison, Quealy.Jenison, Hines );
   bit_and( Newcomb.Seagate, Quealy.Seagate, Sweeny );
}
table CoalCity {
   reads {
      Quealy.Wolford : exact;
   }
   actions {
      Ayden;
   }
   default_action : Ayden(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Opelousas {
   apply( CoalCity );
}
control Newhalem {
   apply( Berea );
}
table Grottoes {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Quealy.Excel : ternary;
      Quealy.Proctor : ternary;
      Quealy.Parkland : ternary;
      Quealy.Robins : ternary;
      Quealy.Sewaren : ternary;
      Quealy.Jenison : ternary;
      Quealy.Seagate : ternary;
   }
   actions {
      Kenefic;
   }
   size : 512;
}
control Alvordton {
   apply( Grottoes );
}
@pragma ways 4
table RedMills {
   reads {
      Quealy.Wolford : exact;
      Newcomb.PawPaw : exact;
      Newcomb.Subiaco : exact;
      Newcomb.Excel : exact;
      Newcomb.Proctor : exact;
      Newcomb.Parkland : exact;
      Newcomb.Robins : exact;
      Newcomb.Sewaren : exact;
      Newcomb.Jenison : exact;
      Newcomb.Seagate : exact;
   }
   actions {
      Kenefic;
   }
   size : 4096;
}
action Dilia( Gillette, Slovan, Inverness, Barron, Grizzly, Brookside, Altus, Skyforest, Tamora ) {
   bit_and( Newcomb.PawPaw, Quealy.PawPaw, Gillette );
   bit_and( Newcomb.Subiaco, Quealy.Subiaco, Slovan );
   bit_and( Newcomb.Excel, Quealy.Excel, Inverness );
   bit_and( Newcomb.Proctor, Quealy.Proctor, Barron );
   bit_and( Newcomb.Parkland, Quealy.Parkland, Grizzly );
   bit_and( Newcomb.Robins, Quealy.Robins, Brookside );
   bit_and( Newcomb.Sewaren, Quealy.Sewaren, Altus );
   bit_and( Newcomb.Jenison, Quealy.Jenison, Skyforest );
   bit_and( Newcomb.Seagate, Quealy.Seagate, Tamora );
}
table Chaires {
   reads {
      Quealy.Wolford : exact;
   }
   actions {
      Dilia;
   }
   default_action : Dilia(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Buckhorn {
   apply( Chaires );
}
control Magasco {
   apply( RedMills );
}
table Candor {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Quealy.Excel : ternary;
      Quealy.Proctor : ternary;
      Quealy.Parkland : ternary;
      Quealy.Robins : ternary;
      Quealy.Sewaren : ternary;
      Quealy.Jenison : ternary;
      Quealy.Seagate : ternary;
   }
   actions {
      Kenefic;
   }
   size : 512;
}
control LaPryor {
   apply( Candor );
}
@pragma ways 4
table Oketo {
   reads {
      Quealy.Wolford : exact;
      Newcomb.PawPaw : exact;
      Newcomb.Subiaco : exact;
      Newcomb.Excel : exact;
      Newcomb.Proctor : exact;
      Newcomb.Parkland : exact;
      Newcomb.Robins : exact;
      Newcomb.Sewaren : exact;
      Newcomb.Jenison : exact;
      Newcomb.Seagate : exact;
   }
   actions {
      Kenefic;
   }
   size : 4096;
}
action Colonie( Maydelle, Hagerman, Rotterdam, Moose, Aynor, Salineno, Saltdale, Lorane, Staunton ) {
   bit_and( Newcomb.PawPaw, Quealy.PawPaw, Maydelle );
   bit_and( Newcomb.Subiaco, Quealy.Subiaco, Hagerman );
   bit_and( Newcomb.Excel, Quealy.Excel, Rotterdam );
   bit_and( Newcomb.Proctor, Quealy.Proctor, Moose );
   bit_and( Newcomb.Parkland, Quealy.Parkland, Aynor );
   bit_and( Newcomb.Robins, Quealy.Robins, Salineno );
   bit_and( Newcomb.Sewaren, Quealy.Sewaren, Saltdale );
   bit_and( Newcomb.Jenison, Quealy.Jenison, Lorane );
   bit_and( Newcomb.Seagate, Quealy.Seagate, Staunton );
}
table Polkville {
   reads {
      Quealy.Wolford : exact;
   }
   actions {
      Colonie;
   }
   default_action : Colonie(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Heaton {
   apply( Polkville );
}
control Lithonia {
   apply( Oketo );
}
table Oskawalik {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Quealy.Excel : ternary;
      Quealy.Proctor : ternary;
      Quealy.Parkland : ternary;
      Quealy.Robins : ternary;
      Quealy.Sewaren : ternary;
      Quealy.Jenison : ternary;
      Quealy.Seagate : ternary;
   }
   actions {
      Kenefic;
   }
   size : 512;
}
control Sylva {
   apply( Oskawalik );
}
@pragma ways 4
table Burgdorf {
   reads {
      Quealy.Wolford : exact;
      Newcomb.PawPaw : exact;
      Newcomb.Subiaco : exact;
      Newcomb.Excel : exact;
      Newcomb.Proctor : exact;
      Newcomb.Parkland : exact;
      Newcomb.Robins : exact;
      Newcomb.Sewaren : exact;
      Newcomb.Jenison : exact;
      Newcomb.Seagate : exact;
   }
   actions {
      Kenefic;
   }
   size : 4096;
}
action Cross( Swords, Licking, Millbrae, Harlem, Quinnesec, Argentine, Trotwood, LongPine, Yaurel ) {
   bit_and( Newcomb.PawPaw, Quealy.PawPaw, Swords );
   bit_and( Newcomb.Subiaco, Quealy.Subiaco, Licking );
   bit_and( Newcomb.Excel, Quealy.Excel, Millbrae );
   bit_and( Newcomb.Proctor, Quealy.Proctor, Harlem );
   bit_and( Newcomb.Parkland, Quealy.Parkland, Quinnesec );
   bit_and( Newcomb.Robins, Quealy.Robins, Argentine );
   bit_and( Newcomb.Sewaren, Quealy.Sewaren, Trotwood );
   bit_and( Newcomb.Jenison, Quealy.Jenison, LongPine );
   bit_and( Newcomb.Seagate, Quealy.Seagate, Yaurel );
}
table Brady {
   reads {
      Quealy.Wolford : exact;
   }
   actions {
      Cross;
   }
   default_action : Cross(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Talkeetna {
   apply( Brady );
}
control Canton {
   apply( Burgdorf );
}
table Jackpot {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Quealy.Excel : ternary;
      Quealy.Proctor : ternary;
      Quealy.Parkland : ternary;
      Quealy.Robins : ternary;
      Quealy.Sewaren : ternary;
      Quealy.Jenison : ternary;
      Quealy.Seagate : ternary;
   }
   actions {
      Kenefic;
   }
   size : 512;
}
control Perkasie {
   apply( Jackpot );
}
@pragma ways 4
table Combine {
   reads {
      Quealy.Wolford : exact;
      Newcomb.PawPaw : exact;
      Newcomb.Subiaco : exact;
      Newcomb.Excel : exact;
      Newcomb.Proctor : exact;
      Newcomb.Parkland : exact;
      Newcomb.Robins : exact;
      Newcomb.Sewaren : exact;
      Newcomb.Jenison : exact;
      Newcomb.Seagate : exact;
   }
   actions {
      Kenefic;
   }
   size : 4096;
}
action Mahopac( Cushing, Brazos, Goodyear, Karluk, Thalmann, Fosters, Grasston, Rochert, Neubert ) {
   bit_and( Newcomb.PawPaw, Quealy.PawPaw, Cushing );
   bit_and( Newcomb.Subiaco, Quealy.Subiaco, Brazos );
   bit_and( Newcomb.Excel, Quealy.Excel, Goodyear );
   bit_and( Newcomb.Proctor, Quealy.Proctor, Karluk );
   bit_and( Newcomb.Parkland, Quealy.Parkland, Thalmann );
   bit_and( Newcomb.Robins, Quealy.Robins, Fosters );
   bit_and( Newcomb.Sewaren, Quealy.Sewaren, Grasston );
   bit_and( Newcomb.Jenison, Quealy.Jenison, Rochert );
   bit_and( Newcomb.Seagate, Quealy.Seagate, Neubert );
}
table Coconino {
   reads {
      Quealy.Wolford : exact;
   }
   actions {
      Mahopac;
   }
   default_action : Mahopac(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Funston {
   apply( Coconino );
}
control Mossville {
   apply( Combine );
}
table Braxton {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Quealy.Excel : ternary;
      Quealy.Proctor : ternary;
      Quealy.Parkland : ternary;
      Quealy.Robins : ternary;
      Quealy.Sewaren : ternary;
      Quealy.Jenison : ternary;
      Quealy.Seagate : ternary;
   }
   actions {
      Kenefic;
   }
   size : 512;
}
control Palisades {
   apply( Braxton );
}
@pragma ways 4
table Ladner {
   reads {
      Quealy.Wolford : exact;
      Newcomb.PawPaw : exact;
      Newcomb.Subiaco : exact;
      Newcomb.Excel : exact;
      Newcomb.Proctor : exact;
      Newcomb.Parkland : exact;
      Newcomb.Robins : exact;
      Newcomb.Sewaren : exact;
      Newcomb.Jenison : exact;
      Newcomb.Seagate : exact;
   }
   actions {
      Kenefic;
   }
   size : 4096;
}
action Dunnegan( Moultrie, Verbena, Laramie, Mattapex, Talbert, Chazy, Bayport, Villas, Edmeston ) {
   bit_and( Newcomb.PawPaw, Quealy.PawPaw, Moultrie );
   bit_and( Newcomb.Subiaco, Quealy.Subiaco, Verbena );
   bit_and( Newcomb.Excel, Quealy.Excel, Laramie );
   bit_and( Newcomb.Proctor, Quealy.Proctor, Mattapex );
   bit_and( Newcomb.Parkland, Quealy.Parkland, Talbert );
   bit_and( Newcomb.Robins, Quealy.Robins, Chazy );
   bit_and( Newcomb.Sewaren, Quealy.Sewaren, Bayport );
   bit_and( Newcomb.Jenison, Quealy.Jenison, Villas );
   bit_and( Newcomb.Seagate, Quealy.Seagate, Edmeston );
}
table RedHead {
   reads {
      Quealy.Wolford : exact;
   }
   actions {
      Dunnegan;
   }
   default_action : Dunnegan(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Amanda {
   apply( RedHead );
}
control Osyka {
   apply( Ladner );
}
table Trion {
   reads {
      Quealy.Wolford : exact;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Quealy.Excel : ternary;
      Quealy.Proctor : ternary;
      Quealy.Parkland : ternary;
      Quealy.Robins : ternary;
      Quealy.Sewaren : ternary;
      Quealy.Jenison : ternary;
      Quealy.Seagate : ternary;
   }
   actions {
      Kenefic;
   }
   size : 512;
}
control Wattsburg {
   apply( Trion );
}
header_type Fenwick {
	fields {
		Despard : 8;
		Vanoss : 32;
	}
}
metadata Fenwick Seagrove;
field_list Rumson {
   Seagrove.Despard;
}
field_list Marfa {
   Neosho.FlatRock;
}
field_list_calculation Paullina {
    input {
        Marfa;
    }
    algorithm : identity;
    output_width : 51;
}
action Eldena( Waiehu ) {
   modify_field( Wyatte.Peletier, Waiehu );
}
table Humeston {
   reads {
      Lugert.Baraboo : ternary;
      Quealy.PawPaw : ternary;
      Quealy.Subiaco : ternary;
      Wimberley.Pawtucket : ternary;
      Wimberley.Booth : ternary;
      Willette.SomesBar : ternary;
      Camden.Maljamar : ternary;
      Camden.Narka : ternary;
   }
   actions {
      Eldena;
   }
   size : 2048;
}
control Cotter {
    apply( Humeston );
}
meter Crestone {
   type : bytes;
   static : Disney;
   instance_count : 128;
}
action Comal( Heads, FlyingH ) {
   execute_meter( Crestone, Heads, Wyatte.Brave );
}
table Disney {
   reads {
      Wyatte.Peletier mask 0x7F : exact;
   }
   actions {
      Comal;
   }
   size : 128;
}
control Fowlkes {
   apply( Disney );
}
action Wilton( ) {
   clone_ingress_pkt_to_egress( Wyatte.Shelbina, Rumson );
   modify_field( Seagrove.Despard, Wyatte.Peletier );
   modify_field( Seagrove.Vanoss, Neosho.FlatRock );
   bit_or( Wyatte.Shelbina, Wyatte.Peletier, Wyatte.Farragut );
}
table Godfrey {
   reads {
      Wyatte.Brave : exact;
   }
   actions {
      Wilton;
   }
   size : 2;
}

control ElPortal {
   if( Wyatte.Peletier != 0 ) {
      apply( Godfrey );
   }
}

action_selector Callands {
    selection_key : Paullina;
    selection_mode : resilient;
}
action Tullytown( Buncombe ) {
   modify_field( Wyatte.Farragut, Buncombe );
}
action_profile Locke {
    actions {
        Tullytown;
    }
    size : 512;
    dynamic_action_selection : Callands;
}
table Lakefield {
   reads {
      Wyatte.Peletier mask 0x7F : exact;
   }
   action_profile : Locke;
   size : 128;
}
control Boxelder {
   if( ( Wyatte.Peletier & 0x80 ) == 0x80 ) {
      apply( Lakefield );
   }
}
action Goldsmith() {
   modify_field( Mishawaka.Bacton, 0 );
   modify_field( Mishawaka.DeLancey, 0 );
}
action Larchmont( Belview ) {
   modify_field( Mishawaka.Bacton, 0 );
   modify_field( Mishawaka.DeLancey, 3 );
   modify_field( Mishawaka.Wakefield, Belview );
}
action Loring() {
   modify_field( Mishawaka.Bacton, 0 );
   modify_field( Mishawaka.Stidham, 1 );
}
table Belmond {
   reads {
      Seagrove.Despard mask 0x7F : exact;
   }
   actions {
      Goldsmith;
      Larchmont;
      Loring;
   }
   size : 128;
}
control Frederick {
   if( (( standard_metadata.instance_type == 1 ) or ( standard_metadata.instance_type == 2 ) ) ) {
      apply( Belmond );
   }
}
control ingress {
   Lisle();
   if( Lugert.Shade != 0 ) {
      Paicines();
   }
   Rugby();
   if( Lugert.Shade != 0 ) {
      Snowflake();
      Royston();
   }
   Gerlach();
   PinkHill();
   Alvwood();
   Preston();
   Niota();
   if( Lugert.Shade != 0 ) {
      Fajardo();
   }
   Callimont();
   Segundo();
   Freetown();
   Hillsview();
   if( Lugert.Shade != 0 ) {
      Justice();
   }
   Cotter();
   Beasley();
   Wilson();
   Reynolds();
   Tramway();
   Boxelder();
   if( Lugert.Shade != 0 ) {
      Caliente();
   }
   Green();
   Hargis();
   Boydston();
   Cabot();
   Burgin();
   if( Lugert.Shade != 0 ) {
      Haven();
   }
   Tusayan();
   Wamesit();
   Kanab();
   Floral();
   if( Mishawaka.Umkumiut == 0 ) {
      if( valid( Levasy ) ) {
         Mabelle();
      } else {
         McCaulley();
         Sanford();
      }
   }
   if( not valid( Levasy ) ) {
      Tofte();
   }
   Fowlkes();
   if( Mishawaka.Umkumiut == 0 ) {
      Jacobs();
   }
   Magoun();
   Leicester();
   if( Mishawaka.Umkumiut == 0 ) {
      Leeville();
   }
   if( Lugert.Shade != 0 ) {
      Perryton();
    }
   ElPortal();
   Finley();
   if( valid( Farson[0] ) ) {
      Myrick();
   }
   if( Mishawaka.Umkumiut == 0 ) {
      Pierson();
   }
   Halliday();
   Ravena();
}
control egress {
   Everett();
   Modale();
   Tarlton();
   if( ( Mishawaka.Maupin == 0 ) and ( Mishawaka.Bacton != 2 ) ) {
      Shirley();
   }
   Herod();
}
