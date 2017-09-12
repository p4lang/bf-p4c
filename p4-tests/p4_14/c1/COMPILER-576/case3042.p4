// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 100

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
header_type Canfield {
	fields {
		Judson : 16;
		Ringold : 16;
		Peebles : 8;
		Polkville : 8;
		Huxley : 8;
		Saltdale : 8;
		Lodoga : 1;
		Benson : 1;
		Junior : 1;
		Attalla : 1;
		Vieques : 1;
		Waretown : 1;
	}
}
header_type Gamaliel {
	fields {
		FifeLake : 24;
		Richlawn : 24;
		Cotuit : 24;
		CityView : 24;
		Colburn : 16;
		GlenArm : 16;
		Munday : 16;
		WestGate : 16;
		Crannell : 16;
		Weathers : 8;
		Madawaska : 8;
		Tolono : 1;
		Selawik : 1;
		Cedar : 1;
		Newsome : 1;
		Brothers : 12;
		Addison : 2;
		Havertown : 1;
		Risco : 1;
		Marbleton : 1;
		Comobabi : 1;
		SoapLake : 1;
		Turkey : 1;
		Deport : 1;
		Jeddo : 1;
		Needham : 1;
		TonkaBay : 1;
		Brush : 1;
		Mackey : 1;
		Westwood : 1;
		Mizpah : 1;
		Picayune : 1;
		Rives : 1;
		Lanyon : 16;
		Ephesus : 16;
		Melrude : 8;
		Lilly : 1;
		Gibbs : 1;
	}
}
header_type Sterling {
	fields {
		Grantfork : 24;
		Knoke : 24;
		Rehoboth : 24;
		Scranton : 24;
		Thawville : 24;
		Nightmute : 24;
		Draketown : 24;
		Speedway : 24;
		Troup : 16;
		Petroleum : 16;
		Reydon : 16;
		Lawai : 16;
		LaPalma : 12;
		McCracken : 1;
		Cankton : 3;
		Onida : 1;
		Suarez : 3;
		Chalco : 1;
		Rapids : 1;
		Pearson : 1;
		Brinklow : 1;
		Averill : 1;
		Merkel : 8;
		Cushing : 12;
		Fieldon : 4;
		Moosic : 6;
		Nicodemus : 10;
		Raiford : 9;
		Marcus : 1;
		Funston : 1;
		Albin : 1;
		Bradner : 1;
		Comfrey : 1;
	}
}
header_type Leucadia {
	fields {
		Piketon : 8;
		Coyote : 1;
		Harpster : 1;
		Viroqua : 1;
		Hedrick : 1;
		Perrytown : 1;
	}
}
header_type Montour {
	fields {
		Nowlin : 32;
		Kilbourne : 32;
		Lublin : 6;
		Paskenta : 16;
	}
}
header_type CedarKey {
	fields {
		Salitpa : 128;
		Sylvan : 128;
		Astor : 20;
		Copemish : 8;
		Donner : 11;
		BirchRun : 6;
		Calcasieu : 13;
	}
}
header_type Neshoba {
	fields {
		Bronaugh : 14;
		Baxter : 1;
		WarEagle : 12;
		Helton : 1;
		Lostwood : 1;
		Kerby : 6;
		Gibbstown : 2;
		Joice : 6;
		Conejo : 3;
	}
}
header_type McCallum {
	fields {
		Dozier : 1;
		Campo : 1;
	}
}
header_type Cragford {
	fields {
		Hildale : 8;
	}
}
header_type Vestaburg {
	fields {
		Mifflin : 16;
		Winnebago : 11;
	}
}
header_type Heeia {
	fields {
		Duster : 32;
		Perkasie : 32;
		Colmar : 32;
	}
}
header_type Yreka {
	fields {
		Harrison : 32;
		ElRio : 32;
	}
}
header_type ElPrado {
	fields {
		FarrWest : 1;
		Visalia : 1;
		Wyman : 1;
		Magna : 3;
		Deemer : 1;
		Akhiok : 6;
		Benitez : 5;
	}
}
header_type Exira {
	fields {
		NewMelle : 16;
	}
}
header_type Munger {
	fields {
		Stennett : 14;
		Sharon : 1;
		Godfrey : 1;
	}
}
header_type Onarga {
	fields {
		Isleta : 14;
		Plata : 1;
		Cleta : 1;
	}
}
header_type Willey {
	fields {
		Amasa : 16;
		Montezuma : 16;
		Gobler : 16;
		Samson : 16;
		Calverton : 8;
		Thermal : 8;
		Achille : 8;
		Pound : 8;
		Paxson : 1;
		Lantana : 6;
	}
}
header_type Chispa {
	fields {
		Hamburg : 32;
	}
}
header_type Jamesburg {
	fields {
		Croft : 6;
		Cecilton : 10;
		Somis : 4;
		Luverne : 12;
		ElMirage : 12;
		Mullins : 2;
		Nashua : 2;
		Butler : 8;
		McIntosh : 3;
		McGrady : 5;
	}
}
header_type Bowen {
	fields {
		Fairlea : 24;
		Summit : 24;
		McAlister : 24;
		Danbury : 24;
		Hatchel : 16;
	}
}
header_type Kalkaska {
	fields {
		Penrose : 3;
		Sublett : 1;
		Bevier : 12;
		Aspetuck : 16;
	}
}
header_type Irondale {
	fields {
		Alston : 4;
		Casco : 4;
		Boquet : 6;
		BigArm : 2;
		Muncie : 16;
		Blackwood : 16;
		Margie : 3;
		Westline : 13;
		Calimesa : 8;
		Reedsport : 8;
		McKamie : 16;
		Chehalis : 32;
		Waterman : 32;
	}
}
header_type Pridgen {
	fields {
		Halley : 4;
		Terrytown : 6;
		Bonilla : 2;
		Skene : 20;
		Sonestown : 16;
		Bratt : 8;
		Twisp : 8;
		Ronda : 128;
		Tuttle : 128;
	}
}
header_type Elwyn {
	fields {
		Progreso : 8;
		Rockland : 8;
		Glendevey : 16;
	}
}
header_type Anvik {
	fields {
		Alderson : 16;
		Lansdowne : 16;
	}
}
header_type Lundell {
	fields {
		Bruce : 32;
		NantyGlo : 32;
		Bacton : 4;
		Kinsey : 4;
		Latham : 8;
		Courtdale : 16;
		Atoka : 16;
		Topton : 16;
	}
}
header_type Stehekin {
	fields {
		Mekoryuk : 16;
		Angus : 16;
	}
}
header_type Lewellen {
	fields {
		WestEnd : 16;
		Richvale : 16;
		Pacifica : 8;
		Armagh : 8;
		Maywood : 16;
	}
}
header_type Dellslow {
	fields {
		Woodland : 48;
		Alameda : 32;
		Daphne : 48;
		Taopi : 32;
	}
}
header_type Broadmoor {
	fields {
		Fajardo : 1;
		Ferrum : 1;
		Tavistock : 1;
		Parkland : 1;
		Vincent : 1;
		Conda : 3;
		BigBay : 5;
		Gilliam : 3;
		Ribera : 16;
	}
}
header_type Moorman {
	fields {
		Vinita : 24;
		Petrolia : 8;
	}
}
header_type Berkey {
	fields {
		Florida : 8;
		Coverdale : 24;
		ElCentro : 24;
		Odessa : 8;
	}
}
header Bowen Issaquah;
header Bowen RedBay;
header Kalkaska Allerton[ 2 ];
@pragma pa_fragment ingress Trotwood.McKamie
@pragma pa_fragment egress Trotwood.McKamie
header Irondale Trotwood;
@pragma pa_fragment ingress Challis.McKamie
@pragma pa_fragment egress Challis.McKamie
header Irondale Challis;
header Pridgen Quamba;
header Pridgen Sopris;
header Anvik Artas;
header Anvik Lowden;
header Lundell Wildell;
header Stehekin Agency;
header Lundell Lafourche;
header Stehekin Hooven;
header Berkey Hammett;
header Lewellen Coolin;
header Broadmoor Clearlake;
header Jamesburg Edwards;
header Bowen Dacono;
parser start {
   return select(current(96, 16)) {
      0xBF00 : Maben;
      default : Booth;
   }
}
parser RockPort {
   extract( Edwards );
   return Booth;
}
parser Maben {
   extract( Dacono );
   return RockPort;
}
parser Booth {
   extract( Issaquah );
   return select( Issaquah.Hatchel ) {
      0x8100 : Blencoe;
      0x0800 : Thomas;
      0x86dd : Salduro;
      0x0806 : Pinesdale;
      default : ingress;
   }
}
parser Blencoe {
   extract( Allerton[0] );
   set_metadata(Earling.Vieques, 1);
   return select( Allerton[0].Aspetuck ) {
      0x0800 : Thomas;
      0x86dd : Salduro;
      0x0806 : Pinesdale;
      default : ingress;
   }
}
field_list Stockton {
    Trotwood.Alston;
    Trotwood.Casco;
    Trotwood.Boquet;
    Trotwood.BigArm;
    Trotwood.Muncie;
    Trotwood.Blackwood;
    Trotwood.Margie;
    Trotwood.Westline;
    Trotwood.Calimesa;
    Trotwood.Reedsport;
    Trotwood.Chehalis;
    Trotwood.Waterman;
}
field_list_calculation Escondido {
    input {
        Stockton;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Trotwood.McKamie {
    verify Escondido;
    update Escondido;
}
parser Thomas {
   extract( Trotwood );
   set_metadata(Earling.Peebles, Trotwood.Reedsport);
   set_metadata(Earling.Huxley, Trotwood.Calimesa);
   set_metadata(Earling.Judson, Trotwood.Muncie);
   set_metadata(Earling.Junior, 0);
   set_metadata(Earling.Lodoga, 1);
   return select(Trotwood.Westline, Trotwood.Casco, Trotwood.Reedsport) {
      0x501 : Moclips;
      0x511 : Amber;
      0x506 : Range;
      0 mask 0xFF7000 : Claypool;
      default : ingress;
   }
}
parser Claypool {
   set_metadata(Everetts.Cedar, 1);
   return ingress;
}
parser Salduro {
   extract( Sopris );
   set_metadata(Earling.Peebles, Sopris.Bratt);
   set_metadata(Earling.Huxley, Sopris.Twisp);
   set_metadata(Earling.Judson, Sopris.Sonestown);
   set_metadata(Earling.Junior, 1);
   set_metadata(Earling.Lodoga, 0);
   return select(Sopris.Bratt) {
      0x3a : Moclips;
      17 : Azusa;
      6 : Range;
      default : Claypool;
   }
}
parser Pinesdale {
   extract( Coolin );
   set_metadata(Earling.Waretown, 1);
   return ingress;
}
parser Amber {
   extract(Artas);
   extract(Agency);
   set_metadata(Everetts.Cedar, 1);
   return select(Artas.Lansdowne) {
      4789 : Remington;
      default : ingress;
    }
}
parser Moclips {
   set_metadata( Artas.Alderson, current( 0, 16 ) );
   set_metadata( Artas.Lansdowne, 0 );
   set_metadata( Everetts.Cedar, 1 );
   return ingress;
}
parser Azusa {
   set_metadata(Everetts.Cedar, 1);
   extract(Artas);
   extract(Agency);
   return ingress;
}
parser Range {
   set_metadata(Everetts.Lilly, 1);
   set_metadata(Everetts.Cedar, 1);
   extract(Artas);
   extract(Wildell);
   return ingress;
}
parser Barrow {
   set_metadata(Everetts.Addison, 2);
   return NewTrier;
}
parser Weleetka {
   set_metadata(Everetts.Addison, 2);
   return LoonLake;
}
parser Ludlam {
   extract(Clearlake);
   return select(Clearlake.Fajardo, Clearlake.Ferrum, Clearlake.Tavistock, Clearlake.Parkland, Clearlake.Vincent,
             Clearlake.Conda, Clearlake.BigBay, Clearlake.Gilliam, Clearlake.Ribera) {
      0x0800 : Barrow;
      0x86dd : Weleetka;
      default : ingress;
   }
}
parser Remington {
   extract(Hammett);
   set_metadata(Everetts.Addison, 1);
   return Rembrandt;
}
field_list Puyallup {
    Challis.Alston;
    Challis.Casco;
    Challis.Boquet;
    Challis.BigArm;
    Challis.Muncie;
    Challis.Blackwood;
    Challis.Margie;
    Challis.Westline;
    Challis.Calimesa;
    Challis.Reedsport;
    Challis.Chehalis;
    Challis.Waterman;
}
field_list_calculation Ladoga {
    input {
        Puyallup;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Challis.McKamie {
    verify Ladoga;
    update Ladoga;
}
parser NewTrier {
   extract( Challis );
   set_metadata(Earling.Polkville, Challis.Reedsport);
   set_metadata(Earling.Saltdale, Challis.Calimesa);
   set_metadata(Earling.Ringold, Challis.Muncie);
   set_metadata(Earling.Attalla, 0);
   set_metadata(Earling.Benson, 1);
   return select(Challis.Westline, Challis.Casco, Challis.Reedsport) {
      0x501 : Bairoa;
      0x511 : Wollochet;
      0x506 : Placid;
      0 mask 0xFF7000 : Kiana;
      default : ingress;
   }
}
parser Kiana {
   set_metadata(Everetts.Newsome, 1);
   return ingress;
}
parser LoonLake {
   extract( Quamba );
   set_metadata(Earling.Polkville, Quamba.Bratt);
   set_metadata(Earling.Saltdale, Quamba.Twisp);
   set_metadata(Earling.Ringold, Quamba.Sonestown);
   set_metadata(Earling.Attalla, 1);
   set_metadata(Earling.Benson, 0);
   return select(Quamba.Bratt) {
      0x3a : Bairoa;
      17 : Wollochet;
      6 : Placid;
      default : Kiana;
   }
}
parser Bairoa {
   set_metadata( Everetts.Lanyon, current( 0, 16 ) );
   set_metadata( Everetts.Rives, 1 );
   set_metadata( Everetts.Newsome, 1 );
   return ingress;
}
parser Wollochet {
   set_metadata( Everetts.Lanyon, current( 0, 16 ) );
   set_metadata( Everetts.Ephesus, current( 16, 16 ) );
   set_metadata( Everetts.Rives, 1 );
   set_metadata( Everetts.Newsome, 1);
   return ingress;
}
parser Placid {
   set_metadata( Everetts.Lanyon, current( 0, 16 ) );
   set_metadata( Everetts.Ephesus, current( 16, 16 ) );
   set_metadata( Everetts.Melrude, current( 104, 8 ) );
   set_metadata( Everetts.Rives, 1 );
   set_metadata( Everetts.Newsome, 1 );
   set_metadata( Everetts.Gibbs, 1 );
   extract(Lowden);
   extract(Lafourche);
   return ingress;
}
parser Rembrandt {
   extract( RedBay );
   return select( RedBay.Hatchel ) {
      0x0800: NewTrier;
      0x86dd: LoonLake;
      default: ingress;
   }
}
@pragma pa_no_init ingress Everetts.FifeLake
@pragma pa_no_init ingress Everetts.Richlawn
@pragma pa_no_init ingress Everetts.Cotuit
@pragma pa_no_init ingress Everetts.CityView
metadata Gamaliel Everetts;
@pragma pa_no_init ingress Tonasket.Grantfork
@pragma pa_no_init ingress Tonasket.Knoke
@pragma pa_no_init ingress Tonasket.Rehoboth
@pragma pa_no_init ingress Tonasket.Scranton
metadata Sterling Tonasket;
metadata Neshoba Waterfall;
metadata Canfield Earling;
metadata Montour Andrade;
metadata CedarKey Ekron;
metadata McCallum Stonefort;
@pragma pa_container_size ingress Stonefort.Campo 32
metadata Leucadia Circle;
metadata Cragford Oakes;
metadata Vestaburg BirchBay;
metadata Yreka Goodrich;
metadata Heeia Chenequa;
metadata ElPrado Montello;
metadata Exira Gully;
@pragma pa_no_init ingress Robbs.Stennett
metadata Munger Robbs;
@pragma pa_no_init ingress Lefors.Isleta
metadata Onarga Lefors;
metadata Willey Hershey;
metadata Willey Amalga;
action Odebolt() {
   no_op();
}
action Dougherty() {
   modify_field(Everetts.Comobabi, 1 );
   mark_for_drop();
}
action Deering() {
   no_op();
}
action Aripine(Royston, Gotham, Verdery, Dustin, McDavid, Maybee,
                 PineLake, Essex, Heidrick) {
    modify_field(Waterfall.Bronaugh, Royston);
    modify_field(Waterfall.Baxter, Gotham);
    modify_field(Waterfall.WarEagle, Verdery);
    modify_field(Waterfall.Helton, Dustin);
    modify_field(Waterfall.Lostwood, McDavid);
    modify_field(Waterfall.Kerby, Maybee);
    modify_field(Waterfall.Gibbstown, PineLake);
    modify_field(Waterfall.Conejo, Essex);
    modify_field(Waterfall.Joice, Heidrick);
}

@pragma command_line --no-dead-code-elimination
table Haven {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Aripine;
    }
    size : 288;
}
control Mango {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Haven);
    }
}
action Bokeelia(Frederic, Uniontown) {
   modify_field( Tonasket.Onida, 1 );
   modify_field( Tonasket.Merkel, Frederic);
   modify_field( Everetts.TonkaBay, 1 );
   modify_field( Montello.Wyman, Uniontown );
}
action Clyde() {
   modify_field( Everetts.Deport, 1 );
   modify_field( Everetts.Mackey, 1 );
}
action Hansboro() {
   modify_field( Everetts.TonkaBay, 1 );
}
action Abbyville() {
   modify_field( Everetts.TonkaBay, 1 );
   modify_field( Everetts.Westwood, 1 );
}
action Scarville() {
   modify_field( Everetts.Brush, 1 );
}
action Celada() {
   modify_field( Everetts.Mackey, 1 );
}
counter Traverse {
   type : packets_and_bytes;
   direct : Marlton;
   min_width: 16;
}
table Marlton {
   reads {
      Waterfall.Kerby : exact;
      Issaquah.Fairlea : ternary;
      Issaquah.Summit : ternary;
   }
   actions {
      Bokeelia;
      Clyde;
      Hansboro;
      Scarville;
      Celada;
      Abbyville;
   }
   size : 1024;
}
action Firebrick() {
   modify_field( Everetts.Jeddo, 1 );
}
table Belcher {
   reads {
      Issaquah.McAlister : ternary;
      Issaquah.Danbury : ternary;
   }
   actions {
      Firebrick;
   }
   size : 512;
}
control Naalehu {
   apply( Marlton );
   apply( Belcher );
}
action Barney() {
   modify_field( Andrade.Nowlin, Challis.Chehalis );
   modify_field( Andrade.Kilbourne, Challis.Waterman );
   modify_field( Andrade.Lublin, Challis.Boquet );
   modify_field( Ekron.Salitpa, Quamba.Ronda );
   modify_field( Ekron.Sylvan, Quamba.Tuttle );
   modify_field( Ekron.Astor, Quamba.Skene );
   modify_field( Ekron.BirchRun, Quamba.Terrytown );
   modify_field( Everetts.FifeLake, RedBay.Fairlea );
   modify_field( Everetts.Richlawn, RedBay.Summit );
   modify_field( Everetts.Cotuit, RedBay.McAlister );
   modify_field( Everetts.CityView, RedBay.Danbury );
   modify_field( Everetts.Colburn, RedBay.Hatchel );
   modify_field( Everetts.Crannell, Earling.Ringold );
   modify_field( Everetts.Weathers, Earling.Polkville );
   modify_field( Everetts.Madawaska, Earling.Saltdale );
   modify_field( Everetts.Selawik, Earling.Benson );
   modify_field( Everetts.Tolono, Earling.Attalla );
   modify_field( Everetts.Mizpah, 0 );
   modify_field( Tonasket.Suarez, 1 );
   modify_field( Waterfall.Gibbstown, 1 );
   modify_field( Waterfall.Conejo, 0 );
   modify_field( Waterfall.Joice, 0 );
   modify_field( Montello.FarrWest, 1 );
   modify_field( Montello.Visalia, 1 );
   modify_field( Everetts.Cedar, Everetts.Newsome );
   modify_field( Everetts.Lilly, Everetts.Gibbs );
}
action FulksRun() {
   modify_field( Everetts.Addison, 0 );
   modify_field( Andrade.Nowlin, Trotwood.Chehalis );
   modify_field( Andrade.Kilbourne, Trotwood.Waterman );
   modify_field( Andrade.Lublin, Trotwood.Boquet );
   modify_field( Ekron.Salitpa, Sopris.Ronda );
   modify_field( Ekron.Sylvan, Sopris.Tuttle );
   modify_field( Ekron.Astor, Sopris.Skene );
   modify_field( Ekron.BirchRun, Sopris.Terrytown );
   modify_field( Everetts.FifeLake, Issaquah.Fairlea );
   modify_field( Everetts.Richlawn, Issaquah.Summit );
   modify_field( Everetts.Cotuit, Issaquah.McAlister );
   modify_field( Everetts.CityView, Issaquah.Danbury );
   modify_field( Everetts.Colburn, Issaquah.Hatchel );
   modify_field( Everetts.Crannell, Earling.Judson );
   modify_field( Everetts.Weathers, Earling.Peebles );
   modify_field( Everetts.Madawaska, Earling.Huxley );
   modify_field( Everetts.Selawik, Earling.Lodoga );
   modify_field( Everetts.Tolono, Earling.Junior );
   modify_field( Montello.Deemer, Allerton[0].Sublett );
   modify_field( Everetts.Mizpah, Earling.Vieques );
   modify_field( Everetts.Lanyon, Artas.Alderson );
   modify_field( Everetts.Ephesus, Artas.Lansdowne );
   modify_field( Everetts.Melrude, Wildell.Latham );
}
table Youngtown {
   reads {
      Issaquah.Fairlea : exact;
      Issaquah.Summit : exact;
      Trotwood.Waterman : exact;
      Everetts.Addison : exact;
   }
   actions {
      Barney;
      FulksRun;
   }
   default_action : FulksRun();
   size : 1024;
}
action Shoup() {
   modify_field( Everetts.GlenArm, Waterfall.WarEagle );
   modify_field( Everetts.Munday, Waterfall.Bronaugh);
}
action Pendroy( Prismatic ) {
   modify_field( Everetts.GlenArm, Prismatic );
   modify_field( Everetts.Munday, Waterfall.Bronaugh);
}
action McGonigle() {
   modify_field( Everetts.GlenArm, Allerton[0].Bevier );
   modify_field( Everetts.Munday, Waterfall.Bronaugh);
}
table Monteview {
   reads {
      Waterfall.Bronaugh : ternary;
      Allerton[0] : valid;
      Allerton[0].Bevier : ternary;
   }
   actions {
      Shoup;
      Pendroy;
      McGonigle;
   }
   size : 4096;
}
action Quitman( Gerty ) {
   modify_field( Everetts.Munday, Gerty );
}
action Talihina() {
   modify_field( Everetts.Marbleton, 1 );
   modify_field( Oakes.Hildale,
                 1 );
}
table Blossom {
   reads {
      Trotwood.Chehalis : exact;
   }
   actions {
      Quitman;
      Talihina;
   }
   default_action : Talihina;
   size : 4096;
}
action Tillicum( Robbins, MoonRun, Dorothy, Lakeside, Bloomburg,
                        Crossnore, Belpre ) {
   modify_field( Everetts.GlenArm, Robbins );
   modify_field( Everetts.WestGate, Robbins );
   modify_field( Everetts.Turkey, Belpre );
   WildRose(MoonRun, Dorothy, Lakeside, Bloomburg,
                        Crossnore );
}
action McClusky() {
   modify_field( Everetts.SoapLake, 1 );
}
table Freeny {
   reads {
      Hammett.ElCentro : exact;
   }
   actions {
      Tillicum;
      McClusky;
   }
   size : 4096;
}
action WildRose(Bergoo, Montbrook, Shuqualak, Skillman,
                        Daleville ) {
   modify_field( Circle.Piketon, Bergoo );
   modify_field( Circle.Coyote, Montbrook );
   modify_field( Circle.Viroqua, Shuqualak );
   modify_field( Circle.Harpster, Skillman );
   modify_field( Circle.Hedrick, Daleville );
}
action Bajandas(Waseca, Garlin, Palmer, Meyers,
                        Kingsgate ) {
   modify_field( Everetts.WestGate, Waterfall.WarEagle );
   WildRose(Waseca, Garlin, Palmer, Meyers,
                        Kingsgate );
}
action Ghent(Paisley, Theta, Parker, Larwill,
                        Success, Radcliffe ) {
   modify_field( Everetts.WestGate, Paisley );
   WildRose(Theta, Parker, Larwill, Success,
                        Radcliffe );
}
action Arcanum(Hackett, WindGap, Herod, Arminto,
                        WestLine ) {
   modify_field( Everetts.WestGate, Allerton[0].Bevier );
   WildRose(Hackett, WindGap, Herod, Arminto,
                        WestLine );
}
table OreCity {
   reads {
      Waterfall.WarEagle : exact;
   }
   actions {
      Odebolt;
      Bajandas;
   }
   size : 4096;
}
@pragma action_default_only Odebolt
table Merrill {
   reads {
      Waterfall.Bronaugh : exact;
      Allerton[0].Bevier : exact;
   }
   actions {
      Ghent;
      Odebolt;
   }
   size : 1024;
}
table Poipu {
   reads {
      Allerton[0].Bevier : exact;
   }
   actions {
      Odebolt;
      Arcanum;
   }
   size : 4096;
}
control Swanlake {
   apply( Youngtown ) {
         Barney {
            apply( Blossom );
            apply( Freeny );
         }
         FulksRun {
            if ( not valid(Edwards) and Waterfall.Helton == 1 ) {
               apply( Monteview );
            }
            if ( valid( Allerton[ 0 ] ) ) {
               apply( Merrill ) {
                  Odebolt {
                     apply( Poipu );
                  }
               }
            } else {
               apply( OreCity );
            }
         }
   }
}
register Flaxton {
    width : 1;
    static : Randall;
    instance_count : 262144;
}
register Proctor {
    width : 1;
    static : Macland;
    instance_count : 262144;
}
blackbox stateful_alu Baskett {
    reg : Flaxton;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : Stonefort.Dozier;
}
blackbox stateful_alu Sunrise {
    reg : Proctor;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst : Stonefort.Campo;
}
field_list Luhrig {
    Waterfall.Kerby;
    Allerton[0].Bevier;
}
field_list_calculation Kaplan {
    input { Luhrig; }
    algorithm: identity;
    output_width: 18;
}
action Stecker() {
    Baskett.execute_stateful_alu_from_hash(Kaplan);
}
action Breda() {
    Sunrise.execute_stateful_alu_from_hash(Kaplan);
}
table Randall {
    actions {
      Stecker;
    }
    default_action : Stecker;
    size : 1;
}
table Macland {
    actions {
      Breda;
    }
    default_action : Breda;
    size : 1;
}
action Antonito(Waldport) {
    modify_field(Stonefort.Campo, Waldport);
}
@pragma use_hash_action 0
table Oakville {
    reads {
       Waterfall.Kerby : exact;
    }
    actions {
      Antonito;
    }
    size : 64;
}
action Philbrook() {
   modify_field( Everetts.Brothers, Waterfall.WarEagle );
   modify_field( Everetts.Havertown, 0 );
}
table Lewis {
   actions {
      Philbrook;
   }
   size : 1;
}
action Macon() {
   modify_field( Everetts.Brothers, Allerton[0].Bevier );
   modify_field( Everetts.Havertown, 1 );
}
table Rixford {
   actions {
      Macon;
   }
   size : 1;
}
control Shickley {
   if ( valid( Allerton[ 0 ] ) ) {
      apply( Rixford );
      if( Waterfall.Lostwood == 1 ) {
         apply( Randall );
         apply( Macland );
      }
   } else {
      apply( Lewis );
      if( Waterfall.Lostwood == 1 ) {
         apply( Oakville );
      }
   }
}
field_list Newport {
   Issaquah.Fairlea;
   Issaquah.Summit;
   Issaquah.McAlister;
   Issaquah.Danbury;
   Issaquah.Hatchel;
}
field_list Pollard {
   Trotwood.Reedsport;
   Trotwood.Chehalis;
   Trotwood.Waterman;
}
field_list Laneburg {
   Sopris.Ronda;
   Sopris.Tuttle;
   Sopris.Skene;
   Sopris.Bratt;
}
field_list Chantilly {
   Trotwood.Chehalis;
   Trotwood.Waterman;
   Artas.Alderson;
   Artas.Lansdowne;
}
field_list_calculation SanSimon {
    input {
        Newport;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Aurora {
    input {
        Pollard;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Chatawa {
    input {
        Laneburg;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Markesan {
    input {
        Chantilly;
    }
    algorithm : crc32;
    output_width : 32;
}
action Grayland() {
    modify_field_with_hash_based_offset(Chenequa.Duster, 0,
                                        SanSimon, 4294967296);
}
action Terral() {
    modify_field_with_hash_based_offset(Chenequa.Perkasie, 0,
                                        Aurora, 4294967296);
}
action Fackler() {
    modify_field_with_hash_based_offset(Chenequa.Perkasie, 0,
                                        Chatawa, 4294967296);
}
action Kranzburg() {
    modify_field_with_hash_based_offset(Chenequa.Colmar, 0,
                                        Markesan, 4294967296);
}
table Collis {
   actions {
      Grayland;
   }
   size: 1;
}
control Sonoma {
   apply(Collis);
}
table Goulding {
   actions {
      Terral;
   }
   size: 1;
}
table Philmont {
   actions {
      Fackler;
   }
   size: 1;
}
control Potter {
   if ( valid( Trotwood ) ) {
      apply(Goulding);
   } else {
      if ( valid( Sopris ) ) {
         apply(Philmont);
      }
   }
}
table Ivyland {
   actions {
      Kranzburg;
   }
   size: 1;
}
control Brave {
   if ( valid( Agency ) ) {
      apply(Ivyland);
   }
}
action WestPark() {
    modify_field(Goodrich.Harrison, Chenequa.Duster);
}
action Ardara() {
    modify_field(Goodrich.Harrison, Chenequa.Perkasie);
}
action Shine() {
    modify_field(Goodrich.Harrison, Chenequa.Colmar);
}
@pragma action_default_only Odebolt
@pragma immediate 0
table Cataract {
   reads {
      Lafourche.valid : ternary;
      Hooven.valid : ternary;
      Challis.valid : ternary;
      Quamba.valid : ternary;
      RedBay.valid : ternary;
      Wildell.valid : ternary;
      Agency.valid : ternary;
      Trotwood.valid : ternary;
      Sopris.valid : ternary;
      Issaquah.valid : ternary;
   }
   actions {
      WestPark;
      Ardara;
      Shine;
      Odebolt;
   }
   size: 256;
}
action Horatio() {
    modify_field(Goodrich.ElRio, Chenequa.Colmar);
}
@pragma immediate 0
table IowaCity {
   reads {
      Lafourche.valid : ternary;
      Hooven.valid : ternary;
      Wildell.valid : ternary;
      Agency.valid : ternary;
   }
   actions {
      Horatio;
      Odebolt;
   }
   size: 6;
}
control Holtville {
   apply(IowaCity);
   apply(Cataract);
}
counter Meeker {
   type : packets_and_bytes;
   direct : Oneonta;
   min_width: 16;
}
table Oneonta {
   reads {
      Waterfall.Kerby : exact;
      Stonefort.Campo : ternary;
      Stonefort.Dozier : ternary;
      Everetts.SoapLake : ternary;
      Everetts.Jeddo : ternary;
      Everetts.Deport : ternary;
   }
   actions {
      Dougherty;
      Odebolt;
   }
   default_action : Odebolt();
   size : 512;
}
table Opelousas {
   reads {
      Everetts.Cotuit : exact;
      Everetts.CityView : exact;
      Everetts.GlenArm : exact;
   }
   actions {
      Dougherty;
      Odebolt;
   }
   default_action : Odebolt();
   size : 4096;
}
action Baytown() {
   modify_field(Everetts.Risco, 1 );
   modify_field(Oakes.Hildale,
                0);
}
table Gresston {
   reads {
      Everetts.Cotuit : exact;
      Everetts.CityView : exact;
      Everetts.GlenArm : exact;
      Everetts.Munday : exact;
   }
   actions {
      Deering;
      Baytown;
   }
   default_action : Baytown();
   size : 65536;
   support_timeout : true;
}
action Colson( Longford, Ranchito ) {
   modify_field( Everetts.Picayune, Longford );
   modify_field( Everetts.Turkey, Ranchito );
}
action Westville() {
   modify_field( Everetts.Turkey, 1 );
}
table Longport {
   reads {
      Everetts.GlenArm mask 0xfff : exact;
   }
   actions {
      Colson;
      Westville;
      Odebolt;
   }
   default_action : Odebolt();
   size : 4096;
}
action Woolwine() {
   modify_field( Circle.Perrytown, 1 );
}
table Crestline {
   reads {
      Everetts.WestGate : ternary;
      Everetts.FifeLake : exact;
      Everetts.Richlawn : exact;
   }
   actions {
      Woolwine;
   }
   size: 512;
}
control Othello {
   apply( Oneonta ) {
      Odebolt {
         apply( Opelousas ) {
            Odebolt {
               if (Waterfall.Baxter == 0 and Everetts.Marbleton == 0) {
                  apply( Gresston );
               }
               apply( Longport );
               apply(Crestline);
            }
         }
      }
   }
}
field_list Lebanon {
    Oakes.Hildale;
    Everetts.Cotuit;
    Everetts.CityView;
    Everetts.GlenArm;
    Everetts.Munday;
}
action Franktown() {
   generate_digest(0, Lebanon);
}
table Columbus {
   actions {
      Franktown;
   }
   size : 1;
}
control Millstone {
   if (Everetts.Risco == 1) {
      apply( Columbus );
   }
}
action Thalia( Paragould, Blueberry ) {
   modify_field( Ekron.Calcasieu, Paragould );
   modify_field( BirchBay.Mifflin, Blueberry );
}
@pragma action_default_only LaCenter
table Lawnside {
   reads {
      Circle.Piketon : exact;
      Ekron.Sylvan mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Thalia;
      LaCenter;
   }
   size : 8192;
}
@pragma atcam_partition_index Ekron.Calcasieu
@pragma atcam_number_partitions 8192
table Wanamassa {
   reads {
      Ekron.Calcasieu : exact;
      Ekron.Sylvan mask 0x000007FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Dunken;
      Glenshaw;
      Odebolt;
   }
   default_action : Odebolt();
   size : 65536;
}
action Tchula( Sabina, Mynard ) {
   modify_field( Ekron.Donner, Sabina );
   modify_field( BirchBay.Mifflin, Mynard );
}
@pragma action_default_only Odebolt
table Berenice {
   reads {
      Circle.Piketon : exact;
      Ekron.Sylvan : lpm;
   }
   actions {
      Tchula;
      Odebolt;
   }
   size : 2048;
}
@pragma atcam_partition_index Ekron.Donner
@pragma atcam_number_partitions 2048
table Ardenvoir {
   reads {
      Ekron.Donner : exact;
      Ekron.Sylvan mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Dunken;
      Glenshaw;
      Odebolt;
   }
   default_action : Odebolt();
   size : 16384;
}
@pragma action_default_only LaCenter
@pragma idletime_precision 1
table Nutria {
   reads {
      Circle.Piketon : exact;
      Andrade.Kilbourne : lpm;
   }
   actions {
      Dunken;
      Glenshaw;
      LaCenter;
   }
   size : 1024;
   support_timeout : true;
}
action Kingstown( Westend, Kinter ) {
   modify_field( Andrade.Paskenta, Westend );
   modify_field( BirchBay.Mifflin, Kinter );
}
@pragma action_default_only Odebolt
table Trevorton {
   reads {
      Circle.Piketon : exact;
      Andrade.Kilbourne : lpm;
   }
   actions {
      Kingstown;
      Odebolt;
   }
   size : 16384;
}
@pragma ways 2
@pragma atcam_partition_index Andrade.Paskenta
@pragma atcam_number_partitions 16384
table Mapleview {
   reads {
      Andrade.Paskenta : exact;
      Andrade.Kilbourne mask 0x000fffff : lpm;
   }
   actions {
      Dunken;
      Glenshaw;
      Odebolt;
   }
   default_action : Odebolt();
   size : 131072;
}
action Dunken( Elmont ) {
   modify_field( BirchBay.Mifflin, Elmont );
}
@pragma idletime_precision 1
table Elkins {
   reads {
      Circle.Piketon : exact;
      Andrade.Kilbourne : exact;
   }
   actions {
      Dunken;
      Glenshaw;
      Odebolt;
   }
   default_action : Odebolt();
   size : 65536;
   support_timeout : true;
}
@pragma idletime_precision 1
table Nuremberg {
   reads {
      Circle.Piketon : exact;
      Ekron.Sylvan : exact;
   }
   actions {
      Dunken;
      Glenshaw;
      Odebolt;
   }
   default_action : Odebolt();
   size : 65536;
   support_timeout : true;
}
action Ionia(Rillton, Mabelle, Switzer) {
   modify_field(Tonasket.Troup, Switzer);
   modify_field(Tonasket.Grantfork, Rillton);
   modify_field(Tonasket.Knoke, Mabelle);
   modify_field(Tonasket.Marcus, 1);
   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}
action Munich() {
   Dougherty();
}
action Coqui(Arvonia) {
   modify_field(Tonasket.Onida, 1);
   modify_field(Tonasket.Merkel, Arvonia);
}
action LaCenter(Osyka) {
   modify_field( Tonasket.Onida, 1 );
   modify_field( Tonasket.Merkel, 9 );
}
table Battles {
   reads {
      BirchBay.Mifflin : exact;
   }
   actions {
      Ionia;
      Munich;
      Coqui;
   }
   size : 65536;
}
action Tulalip( TroutRun ) {
   modify_field(Tonasket.Onida, 1);
   modify_field(Tonasket.Merkel, TroutRun);
}
table SomesBar {
   actions {
      Tulalip;
   }
   default_action: Tulalip;
   size : 1;
}
control Carlsbad {
   if ( Everetts.Comobabi == 0 and Circle.Perrytown == 1 ) {
      if ( ( Circle.Coyote == 1 ) and ( Everetts.Selawik == 1 ) ) {
         apply( Elkins ) {
            Odebolt {
               apply(Trevorton);
            }
         }
      } else if ( ( Circle.Viroqua == 1 ) and ( Everetts.Tolono == 1 ) ) {
         apply( Nuremberg ) {
            Odebolt {
               apply( Berenice );
            }
         }
      }
   }
}
control Bouse {
   if ( Everetts.Comobabi == 0 and Circle.Perrytown == 1 ) {
      if ( ( Circle.Coyote == 1 ) and ( Everetts.Selawik == 1 ) ) {
         if ( Andrade.Paskenta != 0 ) {
            apply( Mapleview );
         } else if ( BirchBay.Mifflin == 0 and BirchBay.Winnebago == 0 ) {
            apply( Nutria );
         }
      } else if ( ( Circle.Viroqua == 1 ) and ( Everetts.Tolono == 1 ) ) {
         if ( Ekron.Donner != 0 ) {
            apply( Ardenvoir );
         } else if ( BirchBay.Mifflin == 0 and BirchBay.Winnebago == 0 ) {
            apply( Lawnside ) {
               Thalia {
                  apply( Wanamassa );
               }
            }
         }
      } else if( Everetts.Turkey == 1 ) {
         apply( SomesBar );
      }
   }
}
control Shopville {
   if( BirchBay.Mifflin != 0 ) {
      apply( Battles );
   }
}
action Glenshaw( Clifton ) {
   modify_field( BirchBay.Winnebago, Clifton );
}
field_list Peletier {
   Goodrich.ElRio;
}
field_list_calculation Ivanpah {
    input {
        Peletier;
    }
    algorithm : identity;
    output_width : 66;
}
action_selector Squire {
   selection_key : Ivanpah;
   selection_mode : resilient;
}
action_profile Selah {
   actions {
      Dunken;
   }
   size : 65536;
   dynamic_action_selection : Squire;
}
@pragma selector_max_group_size 256
table Sheldahl {
   reads {
      BirchBay.Winnebago : exact;
   }
   action_profile : Selah;
   size : 2048;
}
control Twichell {
   if ( BirchBay.Winnebago != 0 ) {
      apply( Sheldahl );
   }
}
field_list Savery {
   Goodrich.Harrison;
}
field_list_calculation Absecon {
    input {
        Savery;
    }
    algorithm : identity;
    output_width : 51;
}
action_selector Nelagoney {
    selection_key : Absecon;
    selection_mode : resilient;
}
action Blairsden(BigWater) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, BigWater);
}
action_profile Tillatoba {
    actions {
        Blairsden;
        Odebolt;
    }
    size : 1024;
    dynamic_action_selection : Nelagoney;
}
table Shelbina {
   reads {
      Tonasket.Reydon : exact;
   }
   action_profile: Tillatoba;
   size : 1024;
}
control Millwood {
   if ((Tonasket.Reydon & 0x2000) == 0x2000) {
      apply(Shelbina);
   }
}
action Hurdtown() {
   modify_field(Tonasket.Grantfork, Everetts.FifeLake);
   modify_field(Tonasket.Knoke, Everetts.Richlawn);
   modify_field(Tonasket.Rehoboth, Everetts.Cotuit);
   modify_field(Tonasket.Scranton, Everetts.CityView);
   modify_field(Tonasket.Troup, Everetts.GlenArm);
   invalidate( ig_intr_md_for_tm.ucast_egress_port );
}
table Ouachita {
   actions {
      Hurdtown;
   }
   default_action : Hurdtown();
   size : 1;
}
control Eustis {
   apply( Ouachita );
}
action Owentown() {
   modify_field(Tonasket.Chalco, 1);
   modify_field(Tonasket.Bradner, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Everetts.Turkey);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Tonasket.Troup);
}
action Wenham() {
}
@pragma ways 1
table Arial {
   reads {
      Tonasket.Grantfork : exact;
      Tonasket.Knoke : exact;
   }
   actions {
      Owentown;
      Wenham;
   }
   default_action : Wenham;
   size : 1;
}
action Hanover() {
   modify_field(Tonasket.Rapids, 1);
   modify_field(Tonasket.Averill, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Tonasket.Troup, 4096);
}
table Sarasota {
   actions {
      Hanover;
   }
   default_action : Hanover;
   size : 1;
}
action Clarkdale() {
   modify_field(Tonasket.Brinklow, 1);
   modify_field(Tonasket.Bradner, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Tonasket.Troup);
}
table Glendale {
   actions {
      Clarkdale;
   }
   default_action : Clarkdale();
   size : 1;
}
action Seguin(LaFayette) {
   modify_field(Tonasket.Pearson, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, LaFayette);
   modify_field(Tonasket.Reydon, LaFayette);
}
action Marfa(Norborne) {
   modify_field(Tonasket.Rapids, 1);
   modify_field(Tonasket.Lawai, Norborne);
}
action Duquoin() {
}
table Headland {
   reads {
      Tonasket.Grantfork : exact;
      Tonasket.Knoke : exact;
      Tonasket.Troup : exact;
   }
   actions {
      Seguin;
      Marfa;
      Dougherty;
      Duquoin;
   }
   default_action : Duquoin();
   size : 65536;
}
control Granbury {
   if (Everetts.Comobabi == 0 and not valid(Edwards) ) {
      apply(Headland) {
         Duquoin {
            apply(Arial) {
               Wenham {
                  if ((Tonasket.Grantfork & 0x010000) == 0x010000) {
                     apply(Sarasota);
                  } else {
                     apply(Glendale);
                  }
               }
            }
         }
      }
   }
}
action Lanesboro() {
   modify_field(Everetts.Needham, 1);
   Dougherty();
}
table Wyncote {
   actions {
      Lanesboro;
   }
   default_action : Lanesboro;
   size : 1;
}
control Domestic {
   if (Everetts.Comobabi == 0) {
      if ((Tonasket.Marcus==0) and (Everetts.TonkaBay==0) and (Everetts.Brush==0) and (Everetts.Munday==Tonasket.Reydon)) {
         apply(Wyncote);
      } else {
         Millwood();
      }
   }
}
action Fonda( Nanson ) {
   modify_field( Tonasket.LaPalma, Nanson );
}
action Thaxton() {
   modify_field( Tonasket.LaPalma, Tonasket.Troup );
}
table Kniman {
   reads {
      eg_intr_md.egress_port : exact;
      Tonasket.Troup : exact;
   }
   actions {
      Fonda;
      Thaxton;
   }
   default_action : Thaxton;
   size : 4096;
}
control Newcomb {
   apply( Kniman );
}
action Sutter( Linda, Geeville ) {
   modify_field( Tonasket.Thawville, Linda );
   modify_field( Tonasket.Nightmute, Geeville );
}
table Boise {
   reads {
      Tonasket.Cankton : exact;
   }
   actions {
      Sutter;
   }
   size : 8;
}
action Cidra() {
   modify_field( Tonasket.Funston, 1 );
   modify_field( Tonasket.Cankton, 2 );
}
action Calumet() {
   modify_field( Tonasket.Funston, 1 );
   modify_field( Tonasket.Cankton, 1 );
}
table Chunchula {
   reads {
      Tonasket.McCracken : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Cidra;
      Calumet;
   }
   default_action : Odebolt();
   size : 16;
}
action Basic(Perdido, Woodville, Langhorne, Haworth) {
   modify_field( Tonasket.Moosic, Perdido );
   modify_field( Tonasket.Nicodemus, Woodville );
   modify_field( Tonasket.Fieldon, Langhorne );
   modify_field( Tonasket.Cushing, Haworth );
}
table Dennison {
   reads {
        Tonasket.Raiford : exact;
   }
   actions {
      Basic;
   }
   size : 256;
}
action Umkumiut() {
   no_op();
}
action Toccopola() {
   modify_field( Issaquah.Hatchel, Allerton[0].Aspetuck );
   remove_header( Allerton[0] );
}
table Otisco {
   actions {
      Toccopola;
   }
   default_action : Toccopola;
   size : 1;
}
action Lathrop() {
   no_op();
}
action Quogue() {
   add_header( Allerton[ 0 ] );
   modify_field( Allerton[0].Bevier, Tonasket.LaPalma );
   modify_field( Allerton[0].Aspetuck, Issaquah.Hatchel );
   modify_field( Allerton[0].Penrose, Montello.Magna );
   modify_field( Allerton[0].Sublett, Montello.Deemer );
   modify_field( Issaquah.Hatchel, 0x8100 );
}
table Waynoka {
   reads {
      Tonasket.LaPalma : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Lathrop;
      Quogue;
   }
   default_action : Quogue;
   size : 128;
}
action Elmwood() {
   modify_field(Issaquah.Fairlea, Tonasket.Grantfork);
   modify_field(Issaquah.Summit, Tonasket.Knoke);
   modify_field(Issaquah.McAlister, Tonasket.Thawville);
   modify_field(Issaquah.Danbury, Tonasket.Nightmute);
}
action Platea() {
   Elmwood();
   add_to_field(Trotwood.Calimesa, -1);
   modify_field(Trotwood.Boquet, Montello.Akhiok);
}
action Buenos() {
   Elmwood();
   add_to_field(Sopris.Twisp, -1);
   modify_field(Sopris.Terrytown, Montello.Akhiok);
}
action Hagerman() {
   modify_field(Trotwood.Boquet, Montello.Akhiok);
}
action Lennep() {
   modify_field(Sopris.Terrytown, Montello.Akhiok);
}
action MudButte() {
   Quogue();
}
action Cowles( Wetumpka, Cistern, Maljamar, Slovan ) {
   add_header( Dacono );
   modify_field( Dacono.Fairlea, Wetumpka );
   modify_field( Dacono.Summit, Cistern );
   modify_field( Dacono.McAlister, Maljamar );
   modify_field( Dacono.Danbury, Slovan );
   modify_field( Dacono.Hatchel, 0xBF00 );
   add_header( Edwards );
   modify_field( Edwards.Croft, Tonasket.Moosic );
   modify_field( Edwards.Cecilton, Tonasket.Nicodemus );
   modify_field( Edwards.Somis, Tonasket.Fieldon );
   modify_field( Edwards.Luverne, Tonasket.Cushing );
   modify_field( Edwards.Butler, Tonasket.Merkel );
}
action Higganum() {
   remove_header( Hammett );
   remove_header( Agency );
   remove_header( Artas );
   copy_header( Issaquah, RedBay );
   remove_header( RedBay );
   remove_header( Trotwood );
}
action Chardon() {
   remove_header( Dacono );
   remove_header( Edwards );
}
action Gowanda() {
   Higganum();
   modify_field(Challis.Boquet, Montello.Akhiok);
}
action Sandston() {
   Higganum();
   modify_field(Quamba.Terrytown, Montello.Akhiok);
}
table DewyRose {
   reads {
      Tonasket.Suarez : exact;
      Tonasket.Cankton : exact;
      Tonasket.Marcus : exact;
      Trotwood.valid : ternary;
      Sopris.valid : ternary;
      Challis.valid : ternary;
      Quamba.valid : ternary;
   }
   actions {
      Platea;
      Buenos;
      Hagerman;
      Lennep;
      MudButte;
      Cowles;
      Chardon;
      Higganum;
      Gowanda;
      Sandston;
   }
   size : 512;
}
control Frankfort {
   apply( Otisco );
}
control MillCity {
   apply( Waynoka );
}
control Colonie {
   apply( Chunchula ) {
      Odebolt {
         apply( Boise );
      }
   }
   apply( Dennison );
   apply( DewyRose );
}
field_list Tatitlek {
    Oakes.Hildale;
    Everetts.GlenArm;
    RedBay.McAlister;
    RedBay.Danbury;
    Trotwood.Chehalis;
}
action Forman() {
   generate_digest(0, Tatitlek);
}
table Fairborn {
   actions {
      Forman;
   }
   default_action : Forman;
   size : 1;
}
control Floris {
   if (Everetts.Marbleton == 1) {
      apply(Fairborn);
   }
}
action Jessie() {
   modify_field( Montello.Magna, Waterfall.Conejo );
}
action Jamesport() {
   modify_field( Montello.Magna, Allerton[0].Penrose );
   modify_field( Everetts.Colburn, Allerton[0].Aspetuck );
}
action Henry() {
   modify_field( Montello.Akhiok, Waterfall.Joice );
}
action Hillcrest() {
   modify_field( Montello.Akhiok, Andrade.Lublin );
}
action Conneaut() {
   modify_field( Montello.Akhiok, Ekron.BirchRun );
}
action BayPort( Rowlett, Ragley ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Rowlett );
   modify_field( ig_intr_md_for_tm.qid, Ragley );
}
table Suntrana {
   reads {
     Everetts.Mizpah : exact;
   }
   actions {
     Jessie;
     Jamesport;
   }
   size : 2;
}
table Skokomish {
   reads {
     Everetts.Selawik : exact;
     Everetts.Tolono : exact;
   }
   actions {
     Henry;
     Hillcrest;
     Conneaut;
   }
   size : 3;
}
table Quijotoa {
   reads {
      Waterfall.Gibbstown : ternary;
      Waterfall.Conejo : ternary;
      Montello.Magna : ternary;
      Montello.Akhiok : ternary;
      Montello.Wyman : ternary;
   }
   actions {
      BayPort;
   }
   size : 81;
}
action Kneeland( Ortley, Jemison ) {
   bit_or( Montello.FarrWest, Montello.FarrWest, Ortley );
   bit_or( Montello.Visalia, Montello.Visalia, Jemison );
}
table Wesson {
   actions {
      Kneeland;
   }
   default_action : Kneeland;
   size : 1;
}
action Bunker( Westhoff ) {
   modify_field( Montello.Akhiok, Westhoff );
}
action Bagwell( Abilene ) {
   modify_field( Montello.Magna, Abilene );
}
action Varnado( Honalo, Jenkins ) {
   modify_field( Montello.Magna, Honalo );
   modify_field( Montello.Akhiok, Jenkins );
}
table Loris {
   reads {
      Waterfall.Gibbstown : exact;
      Montello.FarrWest : exact;
      Montello.Visalia : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Bunker;
      Bagwell;
      Varnado;
   }
   size : 512;
}
control Lookeba {
   apply( Suntrana );
   apply( Skokomish );
}
control Laxon {
   apply( Quijotoa );
}
control Picabo {
   apply( Wesson );
   apply( Loris );
}
action Nunnelly( Pierceton ) {
   modify_field( Montello.Benitez, Pierceton );
}
action Punaluu( Engle, Corinne ) {
   Nunnelly( Engle );
   modify_field( ig_intr_md_for_tm.qid, Corinne );
}
table Larsen {
   reads {
      Tonasket.Onida : ternary;
      ig_intr_md_for_tm.copy_to_cpu : ternary;
      Tonasket.Merkel : ternary;
      Everetts.Selawik : ternary;
      Everetts.Tolono : ternary;
      Everetts.Colburn : ternary;
      Everetts.Weathers : ternary;
      Everetts.Madawaska : ternary;
      Tonasket.Marcus : ternary;
      Artas.Alderson : ternary;
      Artas.Lansdowne : ternary;
   }
   actions {
      Nunnelly;
      Punaluu;
   }
   size : 512;
}
meter Roswell {
   type : packets;
   static : Nursery;
   instance_count : 2304;
}
action Siloam(Jarreau) {
   execute_meter( Roswell, Jarreau, ig_intr_md_for_tm.packet_color );
}
table Nursery {
   reads {
      Waterfall.Kerby : exact;
      Montello.Benitez : exact;
   }
   actions {
      Siloam;
   }
   size : 2304;
}
counter Robinette {
   type : packets;
   instance_count : 32;
   min_width : 128;
}
action Bucktown() {
   count( Robinette, Montello.Benitez );
}
table Inverness {
   actions {
     Bucktown;
   }
   default_action : Bucktown;
   size : 1;
}
control Oketo {
    if ( (
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x1 ) == 0 ) ) and ( Tonasket.Onida == 1 ) ) or
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x2 ) == 0 ) ) and ( ig_intr_md_for_tm.copy_to_cpu == 1 ) )
       ) ) {
      apply( Nursery );
      apply( Inverness );
   }
}
action Petrey( Neavitt ) {
   modify_field( Tonasket.McCracken, 0 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Neavitt );
   modify_field( Tonasket.Raiford, ig_intr_md.ingress_port );
}
action Indrio( Lilbert ) {
   modify_field( Tonasket.McCracken, 1 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Lilbert );
   modify_field( Tonasket.Raiford, ig_intr_md.ingress_port );
}
action Mendota() {
   modify_field( Tonasket.McCracken, 0 );
}
action Telma() {
   modify_field( Tonasket.McCracken, 1 );
   modify_field( Tonasket.Raiford, ig_intr_md.ingress_port );
}
@pragma ternary 1
table Dabney {
   reads {
      Tonasket.Onida : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      Circle.Perrytown : exact;
      Waterfall.Helton : ternary;
      Tonasket.Merkel : ternary;
   }
   actions {
      Petrey;
      Indrio;
      Mendota;
      Telma;
   }
   size : 512;
}
control Eddington {
   apply( Dabney );
}
counter Fairlee {
   type : packets_and_bytes;
   instance_count : 1024;
   min_width : 128;
}
action Cantwell( Tagus ) {
   count( Fairlee, Tagus );
}
table Mickleton {
   reads {
      eg_intr_md.egress_port mask 0x7f: exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }
   actions {
     Cantwell;
   }
   size : 1024;
}
control McDermott {
   apply( Mickleton );
}
action Woodcrest()
{
   Dougherty();
}
action Levittown()
{
   modify_field(Tonasket.Suarez, 2);
   bit_or(Tonasket.Reydon, 0x2000, Edwards.Luverne);
}
action Denby( KentPark ) {
   modify_field(Tonasket.Suarez, 2);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, KentPark);
   modify_field(Tonasket.Reydon, KentPark);
}
table Bonsall {
   reads {
      Edwards.Croft : exact;
      Edwards.Cecilton : exact;
      Edwards.Somis : exact;
      Edwards.Luverne : exact;
   }
   actions {
      Levittown;
      Denby;
      Woodcrest;
   }
   default_action : Woodcrest();
   size : 256;
}
control Mescalero {
   apply( Bonsall );
}
action Calva( Covina, Neuse, Harold, Amonate ) {
   modify_field( Gully.NewMelle, Covina );
   modify_field( Lefors.Plata, Harold );
   modify_field( Lefors.Isleta, Neuse );
   modify_field( Lefors.Cleta, Amonate );
}
table Burmester {
   reads {
     Andrade.Kilbourne : exact;
     Everetts.WestGate : exact;
   }
   actions {
      Calva;
   }
  size : 16384;
}
action Kansas(Hematite, Boyero, Nephi) {
   modify_field( Lefors.Isleta, Hematite );
   modify_field( Lefors.Plata, Boyero );
   modify_field( Lefors.Cleta, Nephi );
}
table Schofield {
   reads {
     Andrade.Nowlin : exact;
     Gully.NewMelle : exact;
   }
   actions {
      Kansas;
   }
   size : 16384;
}
action Equality( Topawa, Poplar, Wegdahl ) {
   modify_field( Robbs.Stennett, Topawa );
   modify_field( Robbs.Sharon, Poplar );
   modify_field( Robbs.Godfrey, Wegdahl );
}
table Egypt {
   reads {
     Tonasket.Grantfork : exact;
     Tonasket.Knoke : exact;
     Tonasket.Troup : exact;
   }
   actions {
      Equality;
   }
   size : 16384;
}
action Badger() {
   modify_field( Tonasket.Bradner, 1 );
}
action WestPike( Camilla, Skagway ) {
   Badger();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Lefors.Isleta );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Camilla, Lefors.Cleta );
   bit_or( Montello.Benitez, Montello.Benitez, Skagway );
}
action SanJon( Renton, Dillsburg ) {
   Badger();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Robbs.Stennett );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Renton, Robbs.Godfrey );
   bit_or( Montello.Benitez, Montello.Benitez, Dillsburg );
}
action Leola( Kenvil, Chilson ) {
   Badger();
   add( ig_intr_md_for_tm.mcast_grp_a, Tonasket.Troup,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Kenvil );
   bit_or( Montello.Benitez, Montello.Benitez, Chilson );
}
action Bellvue() {
   modify_field( Tonasket.Comfrey, 1 );
}
table Waring {
   reads {
     Lefors.Plata : ternary;
     Lefors.Isleta : ternary;
     Robbs.Stennett : ternary;
     Robbs.Sharon : ternary;
     Everetts.Weathers :ternary;
     Everetts.TonkaBay:ternary;
   }
   actions {
      WestPike;
      SanJon;
      Leola;
      Bellvue;
   }
   size : 32;
}
control Millston {
   if( Everetts.Comobabi == 0 and
       Circle.Harpster == 1 and
       Everetts.Westwood == 1 ) {
      apply( Burmester );
   }
}
control Pedro {
   if( Gully.NewMelle != 0 ) {
      apply( Schofield );
   }
}
control Ochoa {
   if( Everetts.Comobabi == 0 and Everetts.TonkaBay==1 ) {
      apply( Egypt );
   }
}
action Mabelvale(Finney) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Goodrich.Harrison );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Finney );
}
table Heuvelton {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Mabelvale;
    }
    size : 512;
}
control Reynolds {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Heuvelton);
   }
}
action BigLake( Lepanto, Harleton ) {
   modify_field( Tonasket.Troup, Lepanto );
   modify_field( Tonasket.Marcus, Harleton );
}
action ElPortal() {
   drop();
}
table Magness {
   reads {
     eg_intr_md.egress_rid: exact;
   }
   actions {
      BigLake;
   }
   default_action: ElPortal;
   size : 57344;
}
control Joslin {
   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Magness);
   }
}
counter LakeFork {
   type : packets;
   direct: Malesus;
   min_width: 63;
}
table Malesus {
   reads {
     Slocum.Hamburg mask 0x7fff : exact;
   }
   actions {
      Odebolt;
   }
   default_action: Odebolt();
   size : 32768;
}
action Bovina() {
   modify_field( Hershey.Calverton, Everetts.Weathers );
   modify_field( Hershey.Lantana, Andrade.Lublin );
   modify_field( Hershey.Thermal, Everetts.Madawaska );
   modify_field( Hershey.Achille, Everetts.Melrude );
   bit_xor( Hershey.Paxson, Everetts.Cedar, 1 );
}
action Chatcolet() {
   modify_field( Hershey.Calverton, Everetts.Weathers );
   modify_field( Hershey.Lantana, Ekron.BirchRun );
   modify_field( Hershey.Thermal, Everetts.Madawaska );
   modify_field( Hershey.Achille, Everetts.Melrude );
   bit_xor( Hershey.Paxson, Everetts.Cedar, 1 );
}
action Adair( Harriet ) {
   Bovina();
   modify_field( Hershey.Amasa, Harriet );
}
action Ocilla( Perma ) {
   Chatcolet();
   modify_field( Hershey.Amasa, Perma );
}
table Netcong {
   reads {
     Andrade.Nowlin : ternary;
   }
   actions {
      Adair;
   }
   default_action : Bovina;
  size : 2048;
}
table Almyra {
   reads {
     Ekron.Salitpa : ternary;
   }
   actions {
      Ocilla;
   }
   default_action : Chatcolet;
   size : 1024;
}
action Congress( Opelika ) {
   modify_field( Hershey.Montezuma, Opelika );
}
table Fowlkes {
   reads {
     Andrade.Kilbourne : ternary;
   }
   actions {
      Congress;
   }
   size : 512;
}
table Sabetha {
   reads {
     Ekron.Sylvan : ternary;
   }
   actions {
      Congress;
   }
   size : 512;
}
action Raceland( Braymer ) {
   modify_field( Hershey.Gobler, Braymer );
}
table Cloverly {
   reads {
     Everetts.Lanyon : ternary;
   }
   actions {
      Raceland;
   }
   size : 512;
}
action Johnsburg( Marshall ) {
   modify_field( Hershey.Samson, Marshall );
}
table McCartys {
   reads {
     Everetts.Ephesus : ternary;
   }
   actions {
      Johnsburg;
   }
   size : 512;
}
action Ruthsburg( Rockdell ) {
   modify_field( Hershey.Pound, Rockdell );
}
action Coalgate( Anson ) {
   modify_field( Hershey.Pound, Anson );
}
table Cowden {
   reads {
     Everetts.Selawik : exact;
     Everetts.Tolono : exact;
     Everetts.Lilly : exact;
     Everetts.WestGate : exact;
   }
   actions {
      Ruthsburg;
      Odebolt;
   }
   default_action : Odebolt();
   size : 4096;
}
table Ripon {
   reads {
     Everetts.Selawik : exact;
     Everetts.Tolono : exact;
     Everetts.Lilly : exact;
     Waterfall.Bronaugh : exact;
   }
   actions {
      Coalgate;
   }
   size : 512;
}
control Panola {
   if( Everetts.Selawik == 1 ) {
      apply( Netcong );
      apply( Fowlkes );
   } else if( Everetts.Tolono == 1 ) {
      apply( Almyra );
      apply( Sabetha );
   }
   if( ( Everetts.Addison != 0 and Everetts.Rives == 1 ) or
       ( Everetts.Addison == 0 and Artas.valid == 1 ) ) {
      apply( Cloverly );
      if( Everetts.Weathers != 1 ){
         apply( McCartys );
      }
   }
   apply( Cowden ) {
      Odebolt {
         apply( Ripon );
      }
   }
}
action Fannett() {
}
action Doerun() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action Irvine() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
}
action Antimony() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
table Motley {
   reads {
     Slocum.Hamburg mask 0x00018000 : ternary;
   }
   actions {
      Fannett;
      Doerun;
      Irvine;
      Antimony;
   }
   size : 16;
}
control Rowden {
   apply( Motley );
   apply( Malesus );
}
   metadata Chispa Slocum;
   action Crozet( Raeford ) {
          max( Slocum.Hamburg, Slocum.Hamburg, Raeford );
   }
@pragma ways 4
table Taylors {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : exact;
      Hershey.Montezuma : exact;
      Hershey.Gobler : exact;
      Hershey.Samson : exact;
      Hershey.Calverton : exact;
      Hershey.Lantana : exact;
      Hershey.Thermal : exact;
      Hershey.Achille : exact;
      Hershey.Paxson : exact;
   }
   actions {
      Crozet;
   }
   size : 4096;
}
control Spraberry {
   apply( Taylors );
}
table Ballwin {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : ternary;
      Hershey.Montezuma : ternary;
      Hershey.Gobler : ternary;
      Hershey.Samson : ternary;
      Hershey.Calverton : ternary;
      Hershey.Lantana : ternary;
      Hershey.Thermal : ternary;
      Hershey.Achille : ternary;
      Hershey.Paxson : ternary;
   }
   actions {
      Crozet;
   }
   size : 512;
}
control Reidland {
   apply( Ballwin );
}
@pragma pa_no_init ingress Armijo.Amasa
@pragma pa_no_init ingress Armijo.Montezuma
@pragma pa_no_init ingress Armijo.Gobler
@pragma pa_no_init ingress Armijo.Samson
@pragma pa_no_init ingress Armijo.Calverton
@pragma pa_no_init ingress Armijo.Lantana
@pragma pa_no_init ingress Armijo.Thermal
@pragma pa_no_init ingress Armijo.Achille
@pragma pa_no_init ingress Armijo.Paxson
metadata Willey Armijo;
@pragma ways 4
table Rodessa {
   reads {
      Hershey.Pound : exact;
      Armijo.Amasa : exact;
      Armijo.Montezuma : exact;
      Armijo.Gobler : exact;
      Armijo.Samson : exact;
      Armijo.Calverton : exact;
      Armijo.Lantana : exact;
      Armijo.Thermal : exact;
      Armijo.Achille : exact;
      Armijo.Paxson : exact;
   }
   actions {
      Crozet;
   }
   size : 8192;
}
action Meridean( Altus, Horton, HamLake, Altadena, Bellmead, Oklahoma, Eggleston, Lefor, Chaires ) {
   bit_and( Armijo.Amasa, Hershey.Amasa, Altus );
   bit_and( Armijo.Montezuma, Hershey.Montezuma, Horton );
   bit_and( Armijo.Gobler, Hershey.Gobler, HamLake );
   bit_and( Armijo.Samson, Hershey.Samson, Altadena );
   bit_and( Armijo.Calverton, Hershey.Calverton, Bellmead );
   bit_and( Armijo.Lantana, Hershey.Lantana, Oklahoma );
   bit_and( Armijo.Thermal, Hershey.Thermal, Eggleston );
   bit_and( Armijo.Achille, Hershey.Achille, Lefor );
   bit_and( Armijo.Paxson, Hershey.Paxson, Chaires );
}
table Dateland {
   reads {
      Hershey.Pound : exact;
   }
   actions {
      Meridean;
   }
   default_action : Meridean(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Killen {
   apply( Dateland );
}
control Waucoma {
   apply( Rodessa );
}
table Milltown {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : ternary;
      Hershey.Montezuma : ternary;
      Hershey.Gobler : ternary;
      Hershey.Samson : ternary;
      Hershey.Calverton : ternary;
      Hershey.Lantana : ternary;
      Hershey.Thermal : ternary;
      Hershey.Achille : ternary;
      Hershey.Paxson : ternary;
   }
   actions {
      Crozet;
   }
   size : 512;
}
control Wenatchee {
   apply( Milltown );
}
@pragma ways 4
table Servia {
   reads {
      Hershey.Pound : exact;
      Armijo.Amasa : exact;
      Armijo.Montezuma : exact;
      Armijo.Gobler : exact;
      Armijo.Samson : exact;
      Armijo.Calverton : exact;
      Armijo.Lantana : exact;
      Armijo.Thermal : exact;
      Armijo.Achille : exact;
      Armijo.Paxson : exact;
   }
   actions {
      Crozet;
   }
   size : 4096;
}
action Midas( Monowi, Vining, Ravenwood, Greenhorn, Weiser, Glenside, Elmdale, Homeacre, Woodburn ) {
   bit_and( Armijo.Amasa, Hershey.Amasa, Monowi );
   bit_and( Armijo.Montezuma, Hershey.Montezuma, Vining );
   bit_and( Armijo.Gobler, Hershey.Gobler, Ravenwood );
   bit_and( Armijo.Samson, Hershey.Samson, Greenhorn );
   bit_and( Armijo.Calverton, Hershey.Calverton, Weiser );
   bit_and( Armijo.Lantana, Hershey.Lantana, Glenside );
   bit_and( Armijo.Thermal, Hershey.Thermal, Elmdale );
   bit_and( Armijo.Achille, Hershey.Achille, Homeacre );
   bit_and( Armijo.Paxson, Hershey.Paxson, Woodburn );
}
table Shawmut {
   reads {
      Hershey.Pound : exact;
   }
   actions {
      Midas;
   }
   default_action : Midas(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Keenes {
   apply( Shawmut );
}
control Calabash {
   apply( Servia );
}
table Lucile {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : ternary;
      Hershey.Montezuma : ternary;
      Hershey.Gobler : ternary;
      Hershey.Samson : ternary;
      Hershey.Calverton : ternary;
      Hershey.Lantana : ternary;
      Hershey.Thermal : ternary;
      Hershey.Achille : ternary;
      Hershey.Paxson : ternary;
   }
   actions {
      Crozet;
   }
   size : 512;
}
control Cornwall {
   apply( Lucile );
}
@pragma ways 4
table Faysville {
   reads {
      Hershey.Pound : exact;
      Armijo.Amasa : exact;
      Armijo.Montezuma : exact;
      Armijo.Gobler : exact;
      Armijo.Samson : exact;
      Armijo.Calverton : exact;
      Armijo.Lantana : exact;
      Armijo.Thermal : exact;
      Armijo.Achille : exact;
      Armijo.Paxson : exact;
   }
   actions {
      Crozet;
   }
   size : 4096;
}
action Bevington( Hapeville, Estrella, Loyalton, Neches, Redondo, Pensaukee, Olive, Hilger, Immokalee ) {
   bit_and( Armijo.Amasa, Hershey.Amasa, Hapeville );
   bit_and( Armijo.Montezuma, Hershey.Montezuma, Estrella );
   bit_and( Armijo.Gobler, Hershey.Gobler, Loyalton );
   bit_and( Armijo.Samson, Hershey.Samson, Neches );
   bit_and( Armijo.Calverton, Hershey.Calverton, Redondo );
   bit_and( Armijo.Lantana, Hershey.Lantana, Pensaukee );
   bit_and( Armijo.Thermal, Hershey.Thermal, Olive );
   bit_and( Armijo.Achille, Hershey.Achille, Hilger );
   bit_and( Armijo.Paxson, Hershey.Paxson, Immokalee );
}
table Leland {
   reads {
      Hershey.Pound : exact;
   }
   actions {
      Bevington;
   }
   default_action : Bevington(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Roberts {
   apply( Leland );
}
control Yulee {
   apply( Faysville );
}
table Redden {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : ternary;
      Hershey.Montezuma : ternary;
      Hershey.Gobler : ternary;
      Hershey.Samson : ternary;
      Hershey.Calverton : ternary;
      Hershey.Lantana : ternary;
      Hershey.Thermal : ternary;
      Hershey.Achille : ternary;
      Hershey.Paxson : ternary;
   }
   actions {
      Crozet;
   }
   size : 512;
}
control Phelps {
   apply( Redden );
}
@pragma ways 4
table Retrop {
   reads {
      Hershey.Pound : exact;
      Armijo.Amasa : exact;
      Armijo.Montezuma : exact;
      Armijo.Gobler : exact;
      Armijo.Samson : exact;
      Armijo.Calverton : exact;
      Armijo.Lantana : exact;
      Armijo.Thermal : exact;
      Armijo.Achille : exact;
      Armijo.Paxson : exact;
   }
   actions {
      Crozet;
   }
   size : 8192;
}
action DeerPark( Winters, LaPuente, Remsen, Goudeau, Alamota, Hartville, Lenoir, Hebbville, Creekside ) {
   bit_and( Armijo.Amasa, Hershey.Amasa, Winters );
   bit_and( Armijo.Montezuma, Hershey.Montezuma, LaPuente );
   bit_and( Armijo.Gobler, Hershey.Gobler, Remsen );
   bit_and( Armijo.Samson, Hershey.Samson, Goudeau );
   bit_and( Armijo.Calverton, Hershey.Calverton, Alamota );
   bit_and( Armijo.Lantana, Hershey.Lantana, Hartville );
   bit_and( Armijo.Thermal, Hershey.Thermal, Lenoir );
   bit_and( Armijo.Achille, Hershey.Achille, Hebbville );
   bit_and( Armijo.Paxson, Hershey.Paxson, Creekside );
}
table Monaca {
   reads {
      Hershey.Pound : exact;
   }
   actions {
      DeerPark;
   }
   default_action : DeerPark(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Tuscumbia {
   apply( Monaca );
}
control Northboro {
   apply( Retrop );
}
table Hallwood {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : ternary;
      Hershey.Montezuma : ternary;
      Hershey.Gobler : ternary;
      Hershey.Samson : ternary;
      Hershey.Calverton : ternary;
      Hershey.Lantana : ternary;
      Hershey.Thermal : ternary;
      Hershey.Achille : ternary;
      Hershey.Paxson : ternary;
   }
   actions {
      Crozet;
   }
   size : 512;
}
control Plano {
   apply( Hallwood );
}
@pragma ways 4
table Tecolote {
   reads {
      Hershey.Pound : exact;
      Armijo.Amasa : exact;
      Armijo.Montezuma : exact;
      Armijo.Gobler : exact;
      Armijo.Samson : exact;
      Armijo.Calverton : exact;
      Armijo.Lantana : exact;
      Armijo.Thermal : exact;
      Armijo.Achille : exact;
      Armijo.Paxson : exact;
   }
   actions {
      Crozet;
   }
   size : 8192;
}
action Hobucken( Ceiba, Azalia, Pelican, Lilymoor, Segundo, Sunbury, Ravinia, Sabula, Topanga ) {
   bit_and( Armijo.Amasa, Hershey.Amasa, Ceiba );
   bit_and( Armijo.Montezuma, Hershey.Montezuma, Azalia );
   bit_and( Armijo.Gobler, Hershey.Gobler, Pelican );
   bit_and( Armijo.Samson, Hershey.Samson, Lilymoor );
   bit_and( Armijo.Calverton, Hershey.Calverton, Segundo );
   bit_and( Armijo.Lantana, Hershey.Lantana, Sunbury );
   bit_and( Armijo.Thermal, Hershey.Thermal, Ravinia );
   bit_and( Armijo.Achille, Hershey.Achille, Sabula );
   bit_and( Armijo.Paxson, Hershey.Paxson, Topanga );
}
table Darien {
   reads {
      Hershey.Pound : exact;
   }
   actions {
      Hobucken;
   }
   default_action : Hobucken(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Gillette {
   apply( Darien );
}
control Piperton {
   apply( Tecolote );
}
table Coulter {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : ternary;
      Hershey.Montezuma : ternary;
      Hershey.Gobler : ternary;
      Hershey.Samson : ternary;
      Hershey.Calverton : ternary;
      Hershey.Lantana : ternary;
      Hershey.Thermal : ternary;
      Hershey.Achille : ternary;
      Hershey.Paxson : ternary;
   }
   actions {
      Crozet;
   }
   size : 512;
}
control Crestone {
   apply( Coulter );
}
@pragma ways 4
table Wenona {
   reads {
      Hershey.Pound : exact;
      Armijo.Amasa : exact;
      Armijo.Montezuma : exact;
      Armijo.Gobler : exact;
      Armijo.Samson : exact;
      Armijo.Calverton : exact;
      Armijo.Lantana : exact;
      Armijo.Thermal : exact;
      Armijo.Achille : exact;
      Armijo.Paxson : exact;
   }
   actions {
      Crozet;
   }
   size : 4096;
}
action Asher( Tusayan, Shade, Tillson, Glassboro, Yocemento, Thurmond, Schroeder, Sprout, Quinnesec ) {
   bit_and( Armijo.Amasa, Hershey.Amasa, Tusayan );
   bit_and( Armijo.Montezuma, Hershey.Montezuma, Shade );
   bit_and( Armijo.Gobler, Hershey.Gobler, Tillson );
   bit_and( Armijo.Samson, Hershey.Samson, Glassboro );
   bit_and( Armijo.Calverton, Hershey.Calverton, Yocemento );
   bit_and( Armijo.Lantana, Hershey.Lantana, Thurmond );
   bit_and( Armijo.Thermal, Hershey.Thermal, Schroeder );
   bit_and( Armijo.Achille, Hershey.Achille, Sprout );
   bit_and( Armijo.Paxson, Hershey.Paxson, Quinnesec );
}
table Bolckow {
   reads {
      Hershey.Pound : exact;
   }
   actions {
      Asher;
   }
   default_action : Asher(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Sargeant {
   apply( Bolckow );
}
control Notus {
   apply( Wenona );
}
table Tarlton {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : ternary;
      Hershey.Montezuma : ternary;
      Hershey.Gobler : ternary;
      Hershey.Samson : ternary;
      Hershey.Calverton : ternary;
      Hershey.Lantana : ternary;
      Hershey.Thermal : ternary;
      Hershey.Achille : ternary;
      Hershey.Paxson : ternary;
   }
   actions {
      Crozet;
   }
   size : 512;
}
control Veradale {
   apply( Tarlton );
}
@pragma ways 4
table Clarks {
   reads {
      Hershey.Pound : exact;
      Armijo.Amasa : exact;
      Armijo.Montezuma : exact;
      Armijo.Gobler : exact;
      Armijo.Samson : exact;
      Armijo.Calverton : exact;
      Armijo.Lantana : exact;
      Armijo.Thermal : exact;
      Armijo.Achille : exact;
      Armijo.Paxson : exact;
   }
   actions {
      Crozet;
   }
   size : 4096;
}
action Portis( Mather, Lecanto, Vernal, Emory, NewSite, ViewPark, Eastwood, Cassadaga, Finlayson ) {
   bit_and( Armijo.Amasa, Hershey.Amasa, Mather );
   bit_and( Armijo.Montezuma, Hershey.Montezuma, Lecanto );
   bit_and( Armijo.Gobler, Hershey.Gobler, Vernal );
   bit_and( Armijo.Samson, Hershey.Samson, Emory );
   bit_and( Armijo.Calverton, Hershey.Calverton, NewSite );
   bit_and( Armijo.Lantana, Hershey.Lantana, ViewPark );
   bit_and( Armijo.Thermal, Hershey.Thermal, Eastwood );
   bit_and( Armijo.Achille, Hershey.Achille, Cassadaga );
   bit_and( Armijo.Paxson, Hershey.Paxson, Finlayson );
}
table Edler {
   reads {
      Hershey.Pound : exact;
   }
   actions {
      Portis;
   }
   default_action : Portis(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Olathe {
   apply( Edler );
}
control Bairoil {
   apply( Clarks );
}
table Ridgewood {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : ternary;
      Hershey.Montezuma : ternary;
      Hershey.Gobler : ternary;
      Hershey.Samson : ternary;
      Hershey.Calverton : ternary;
      Hershey.Lantana : ternary;
      Hershey.Thermal : ternary;
      Hershey.Achille : ternary;
      Hershey.Paxson : ternary;
   }
   actions {
      Crozet;
   }
   size : 512;
}
control Cowen {
   apply( Ridgewood );
}
   metadata Chispa Laketown;
   action Nighthawk( Ipava ) {
          max( Laketown.Hamburg, Laketown.Hamburg, Ipava );
   }
   action Joaquin() { max( Slocum.Hamburg, Laketown.Hamburg, Slocum.Hamburg ); } table Northcote { actions { Joaquin; } default_action : Joaquin; size : 1; } control Hemet { apply( Northcote ); }
@pragma ways 4
table Amboy {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : exact;
      Hershey.Montezuma : exact;
      Hershey.Gobler : exact;
      Hershey.Samson : exact;
      Hershey.Calverton : exact;
      Hershey.Lantana : exact;
      Hershey.Thermal : exact;
      Hershey.Achille : exact;
      Hershey.Paxson : exact;
   }
   actions {
      Nighthawk;
   }
   size : 4096;
}
control Falls {
   apply( Amboy );
}
table Duchesne {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : ternary;
      Hershey.Montezuma : ternary;
      Hershey.Gobler : ternary;
      Hershey.Samson : ternary;
      Hershey.Calverton : ternary;
      Hershey.Lantana : ternary;
      Hershey.Thermal : ternary;
      Hershey.Achille : ternary;
      Hershey.Paxson : ternary;
   }
   actions {
      Nighthawk;
   }
   size : 4096;
}
control Youngwood {
   apply( Duchesne );
}
@pragma pa_no_init ingress Woodstown.Amasa
@pragma pa_no_init ingress Woodstown.Montezuma
@pragma pa_no_init ingress Woodstown.Gobler
@pragma pa_no_init ingress Woodstown.Samson
@pragma pa_no_init ingress Woodstown.Calverton
@pragma pa_no_init ingress Woodstown.Lantana
@pragma pa_no_init ingress Woodstown.Thermal
@pragma pa_no_init ingress Woodstown.Achille
@pragma pa_no_init ingress Woodstown.Paxson
metadata Willey Woodstown;
@pragma ways 4
table Ashville {
   reads {
      Hershey.Pound : exact;
      Woodstown.Amasa : exact;
      Woodstown.Montezuma : exact;
      Woodstown.Gobler : exact;
      Woodstown.Samson : exact;
      Woodstown.Calverton : exact;
      Woodstown.Lantana : exact;
      Woodstown.Thermal : exact;
      Woodstown.Achille : exact;
      Woodstown.Paxson : exact;
   }
   actions {
      Nighthawk;
   }
   size : 4096;
}
action Riverbank( Langston, DelMar, DimeBox, Canjilon, Kendrick, Callao, Glyndon, Chevak, Napanoch ) {
   bit_and( Woodstown.Amasa, Hershey.Amasa, Langston );
   bit_and( Woodstown.Montezuma, Hershey.Montezuma, DelMar );
   bit_and( Woodstown.Gobler, Hershey.Gobler, DimeBox );
   bit_and( Woodstown.Samson, Hershey.Samson, Canjilon );
   bit_and( Woodstown.Calverton, Hershey.Calverton, Kendrick );
   bit_and( Woodstown.Lantana, Hershey.Lantana, Callao );
   bit_and( Woodstown.Thermal, Hershey.Thermal, Glyndon );
   bit_and( Woodstown.Achille, Hershey.Achille, Chevak );
   bit_and( Woodstown.Paxson, Hershey.Paxson, Napanoch );
}
table Burrton {
   reads {
      Hershey.Pound : exact;
   }
   actions {
      Riverbank;
   }
   default_action : Riverbank(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Freetown {
   apply( Burrton );
}
control Pekin {
   apply( Ashville );
}
table Macopin {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : ternary;
      Hershey.Montezuma : ternary;
      Hershey.Gobler : ternary;
      Hershey.Samson : ternary;
      Hershey.Calverton : ternary;
      Hershey.Lantana : ternary;
      Hershey.Thermal : ternary;
      Hershey.Achille : ternary;
      Hershey.Paxson : ternary;
   }
   actions {
      Nighthawk;
   }
   size : 512;
}
control Annetta {
   apply( Macopin );
}
@pragma ways 4
table Elyria {
   reads {
      Hershey.Pound : exact;
      Woodstown.Amasa : exact;
      Woodstown.Montezuma : exact;
      Woodstown.Gobler : exact;
      Woodstown.Samson : exact;
      Woodstown.Calverton : exact;
      Woodstown.Lantana : exact;
      Woodstown.Thermal : exact;
      Woodstown.Achille : exact;
      Woodstown.Paxson : exact;
   }
   actions {
      Nighthawk;
   }
   size : 4096;
}
action Everton( Moorcroft, DeSart, Zebina, Emerado, Tramway, Fairchild, Makawao, Melmore, Maysfield ) {
   bit_and( Woodstown.Amasa, Hershey.Amasa, Moorcroft );
   bit_and( Woodstown.Montezuma, Hershey.Montezuma, DeSart );
   bit_and( Woodstown.Gobler, Hershey.Gobler, Zebina );
   bit_and( Woodstown.Samson, Hershey.Samson, Emerado );
   bit_and( Woodstown.Calverton, Hershey.Calverton, Tramway );
   bit_and( Woodstown.Lantana, Hershey.Lantana, Fairchild );
   bit_and( Woodstown.Thermal, Hershey.Thermal, Makawao );
   bit_and( Woodstown.Achille, Hershey.Achille, Melmore );
   bit_and( Woodstown.Paxson, Hershey.Paxson, Maysfield );
}
table NewRoads {
   reads {
      Hershey.Pound : exact;
   }
   actions {
      Everton;
   }
   default_action : Everton(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Lansdale {
   apply( NewRoads );
}
control Jigger {
   apply( Elyria );
}
table Alcalde {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : ternary;
      Hershey.Montezuma : ternary;
      Hershey.Gobler : ternary;
      Hershey.Samson : ternary;
      Hershey.Calverton : ternary;
      Hershey.Lantana : ternary;
      Hershey.Thermal : ternary;
      Hershey.Achille : ternary;
      Hershey.Paxson : ternary;
   }
   actions {
      Nighthawk;
   }
   size : 512;
}
control Iberia {
   apply( Alcalde );
}
@pragma ways 4
table Kaibab {
   reads {
      Hershey.Pound : exact;
      Woodstown.Amasa : exact;
      Woodstown.Montezuma : exact;
      Woodstown.Gobler : exact;
      Woodstown.Samson : exact;
      Woodstown.Calverton : exact;
      Woodstown.Lantana : exact;
      Woodstown.Thermal : exact;
      Woodstown.Achille : exact;
      Woodstown.Paxson : exact;
   }
   actions {
      Nighthawk;
   }
   size : 4096;
}
action Calvary( Gardiner, Rozet, Morstein, Magoun, Kisatchie, Elwood, Hiawassee, Portville, Pengilly ) {
   bit_and( Woodstown.Amasa, Hershey.Amasa, Gardiner );
   bit_and( Woodstown.Montezuma, Hershey.Montezuma, Rozet );
   bit_and( Woodstown.Gobler, Hershey.Gobler, Morstein );
   bit_and( Woodstown.Samson, Hershey.Samson, Magoun );
   bit_and( Woodstown.Calverton, Hershey.Calverton, Kisatchie );
   bit_and( Woodstown.Lantana, Hershey.Lantana, Elwood );
   bit_and( Woodstown.Thermal, Hershey.Thermal, Hiawassee );
   bit_and( Woodstown.Achille, Hershey.Achille, Portville );
   bit_and( Woodstown.Paxson, Hershey.Paxson, Pengilly );
}
table Maida {
   reads {
      Hershey.Pound : exact;
   }
   actions {
      Calvary;
   }
   default_action : Calvary(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Camelot {
   apply( Maida );
}
control Halaula {
   apply( Kaibab );
}
table Buckfield {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : ternary;
      Hershey.Montezuma : ternary;
      Hershey.Gobler : ternary;
      Hershey.Samson : ternary;
      Hershey.Calverton : ternary;
      Hershey.Lantana : ternary;
      Hershey.Thermal : ternary;
      Hershey.Achille : ternary;
      Hershey.Paxson : ternary;
   }
   actions {
      Nighthawk;
   }
   size : 512;
}
control Goosport {
   apply( Buckfield );
}
@pragma ways 4
table Biehle {
   reads {
      Hershey.Pound : exact;
      Woodstown.Amasa : exact;
      Woodstown.Montezuma : exact;
      Woodstown.Gobler : exact;
      Woodstown.Samson : exact;
      Woodstown.Calverton : exact;
      Woodstown.Lantana : exact;
      Woodstown.Thermal : exact;
      Woodstown.Achille : exact;
      Woodstown.Paxson : exact;
   }
   actions {
      Nighthawk;
   }
   size : 4096;
}
action Mammoth( Yardley, Placedo, Wyatte, Franklin, ElkRidge, Yorkshire, Hooks, McAllen, Sutton ) {
   bit_and( Woodstown.Amasa, Hershey.Amasa, Yardley );
   bit_and( Woodstown.Montezuma, Hershey.Montezuma, Placedo );
   bit_and( Woodstown.Gobler, Hershey.Gobler, Wyatte );
   bit_and( Woodstown.Samson, Hershey.Samson, Franklin );
   bit_and( Woodstown.Calverton, Hershey.Calverton, ElkRidge );
   bit_and( Woodstown.Lantana, Hershey.Lantana, Yorkshire );
   bit_and( Woodstown.Thermal, Hershey.Thermal, Hooks );
   bit_and( Woodstown.Achille, Hershey.Achille, McAllen );
   bit_and( Woodstown.Paxson, Hershey.Paxson, Sutton );
}
table Milam {
   reads {
      Hershey.Pound : exact;
   }
   actions {
      Mammoth;
   }
   default_action : Mammoth(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Wakenda {
   apply( Milam );
}
control Ferndale {
   apply( Biehle );
}
table Brashear {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : ternary;
      Hershey.Montezuma : ternary;
      Hershey.Gobler : ternary;
      Hershey.Samson : ternary;
      Hershey.Calverton : ternary;
      Hershey.Lantana : ternary;
      Hershey.Thermal : ternary;
      Hershey.Achille : ternary;
      Hershey.Paxson : ternary;
   }
   actions {
      Nighthawk;
   }
   size : 512;
}
control Hendley {
   apply( Brashear );
}
@pragma ways 4
table Poynette {
   reads {
      Hershey.Pound : exact;
      Woodstown.Amasa : exact;
      Woodstown.Montezuma : exact;
      Woodstown.Gobler : exact;
      Woodstown.Samson : exact;
      Woodstown.Calverton : exact;
      Woodstown.Lantana : exact;
      Woodstown.Thermal : exact;
      Woodstown.Achille : exact;
      Woodstown.Paxson : exact;
   }
   actions {
      Nighthawk;
   }
   size : 4096;
}
action Desdemona( Brookwood, Brentford, Kearns, Cornell, Baroda, Perryman, Lutts, Jonesport, Nelson ) {
   bit_and( Woodstown.Amasa, Hershey.Amasa, Brookwood );
   bit_and( Woodstown.Montezuma, Hershey.Montezuma, Brentford );
   bit_and( Woodstown.Gobler, Hershey.Gobler, Kearns );
   bit_and( Woodstown.Samson, Hershey.Samson, Cornell );
   bit_and( Woodstown.Calverton, Hershey.Calverton, Baroda );
   bit_and( Woodstown.Lantana, Hershey.Lantana, Perryman );
   bit_and( Woodstown.Thermal, Hershey.Thermal, Lutts );
   bit_and( Woodstown.Achille, Hershey.Achille, Jonesport );
   bit_and( Woodstown.Paxson, Hershey.Paxson, Nelson );
}
table Waxhaw {
   reads {
      Hershey.Pound : exact;
   }
   actions {
      Desdemona;
   }
   default_action : Desdemona(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Dunbar {
   apply( Waxhaw );
}
control Neshaminy {
   apply( Poynette );
}
table Bowden {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : ternary;
      Hershey.Montezuma : ternary;
      Hershey.Gobler : ternary;
      Hershey.Samson : ternary;
      Hershey.Calverton : ternary;
      Hershey.Lantana : ternary;
      Hershey.Thermal : ternary;
      Hershey.Achille : ternary;
      Hershey.Paxson : ternary;
   }
   actions {
      Nighthawk;
   }
   size : 512;
}
control Mayday {
   apply( Bowden );
}
@pragma ways 4
table Ririe {
   reads {
      Hershey.Pound : exact;
      Woodstown.Amasa : exact;
      Woodstown.Montezuma : exact;
      Woodstown.Gobler : exact;
      Woodstown.Samson : exact;
      Woodstown.Calverton : exact;
      Woodstown.Lantana : exact;
      Woodstown.Thermal : exact;
      Woodstown.Achille : exact;
      Woodstown.Paxson : exact;
   }
   actions {
      Nighthawk;
   }
   size : 4096;
}
action Lafayette( Farthing, Havana, Gagetown, Newcastle, Kahului, Maytown, Luning, Marie, Assinippi ) {
   bit_and( Woodstown.Amasa, Hershey.Amasa, Farthing );
   bit_and( Woodstown.Montezuma, Hershey.Montezuma, Havana );
   bit_and( Woodstown.Gobler, Hershey.Gobler, Gagetown );
   bit_and( Woodstown.Samson, Hershey.Samson, Newcastle );
   bit_and( Woodstown.Calverton, Hershey.Calverton, Kahului );
   bit_and( Woodstown.Lantana, Hershey.Lantana, Maytown );
   bit_and( Woodstown.Thermal, Hershey.Thermal, Luning );
   bit_and( Woodstown.Achille, Hershey.Achille, Marie );
   bit_and( Woodstown.Paxson, Hershey.Paxson, Assinippi );
}
table Elysburg {
   reads {
      Hershey.Pound : exact;
   }
   actions {
      Lafayette;
   }
   default_action : Lafayette(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Manteo {
   apply( Elysburg );
}
control Wyanet {
   apply( Ririe );
}
table EastLake {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : ternary;
      Hershey.Montezuma : ternary;
      Hershey.Gobler : ternary;
      Hershey.Samson : ternary;
      Hershey.Calverton : ternary;
      Hershey.Lantana : ternary;
      Hershey.Thermal : ternary;
      Hershey.Achille : ternary;
      Hershey.Paxson : ternary;
   }
   actions {
      Nighthawk;
   }
   size : 512;
}
control Quebrada {
   apply( EastLake );
}
@pragma ways 4
table LoneJack {
   reads {
      Hershey.Pound : exact;
      Woodstown.Amasa : exact;
      Woodstown.Montezuma : exact;
      Woodstown.Gobler : exact;
      Woodstown.Samson : exact;
      Woodstown.Calverton : exact;
      Woodstown.Lantana : exact;
      Woodstown.Thermal : exact;
      Woodstown.Achille : exact;
      Woodstown.Paxson : exact;
   }
   actions {
      Nighthawk;
   }
   size : 4096;
}
action Woodfords( Rodeo, Trion, Beasley, Putnam, Martelle, Pueblo, Allen, AquaPark, Loysburg ) {
   bit_and( Woodstown.Amasa, Hershey.Amasa, Rodeo );
   bit_and( Woodstown.Montezuma, Hershey.Montezuma, Trion );
   bit_and( Woodstown.Gobler, Hershey.Gobler, Beasley );
   bit_and( Woodstown.Samson, Hershey.Samson, Putnam );
   bit_and( Woodstown.Calverton, Hershey.Calverton, Martelle );
   bit_and( Woodstown.Lantana, Hershey.Lantana, Pueblo );
   bit_and( Woodstown.Thermal, Hershey.Thermal, Allen );
   bit_and( Woodstown.Achille, Hershey.Achille, AquaPark );
   bit_and( Woodstown.Paxson, Hershey.Paxson, Loysburg );
}
table Eldora {
   reads {
      Hershey.Pound : exact;
   }
   actions {
      Woodfords;
   }
   default_action : Woodfords(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Stanwood {
   apply( Eldora );
}
control Angwin {
   apply( LoneJack );
}
table Waiehu {
   reads {
      Hershey.Pound : exact;
      Hershey.Amasa : ternary;
      Hershey.Montezuma : ternary;
      Hershey.Gobler : ternary;
      Hershey.Samson : ternary;
      Hershey.Calverton : ternary;
      Hershey.Lantana : ternary;
      Hershey.Thermal : ternary;
      Hershey.Achille : ternary;
      Hershey.Paxson : ternary;
   }
   actions {
      Nighthawk;
   }
   size : 512;
}
control Ayden {
   apply( Waiehu );
}
control ingress {
   Mango();
   if( Waterfall.Lostwood != 0 ) {
      Naalehu();
   }
   Swanlake();
   if( Waterfall.Lostwood != 0 ) {
      Shickley();
      Othello();
   }
   Sonoma();
   Panola();
   Potter();
   Brave();
   Killen();
   if( Waterfall.Lostwood != 0 ) {
      Carlsbad();
   }
   Waucoma();
   Keenes();
   Calabash();
   Roberts();
   if( Waterfall.Lostwood != 0 ) {
      Bouse();
   }
   Holtville();
   Lookeba();
   Yulee();
   Tuscumbia();
   if( Waterfall.Lostwood != 0 ) {
      Twichell();
   }
   Northboro();
   Gillette();
   Youngwood();
   Eustis();
   Millston();
   if( Waterfall.Lostwood != 0 ) {
      Shopville();
   }
   Pedro();
   Floris();
   Piperton();
   Millstone();
   if( Tonasket.Onida == 0 ) {
      if( valid( Edwards ) ) {
         Mescalero();
      } else {
         Ochoa();
         Granbury();
      }
   }
   if( not valid( Edwards ) ) {
      Laxon();
   }
   if( Tonasket.Onida == 0 ) {
      Domestic();
   }
   Hemet();
   if ( Waterfall.Lostwood != 0 ) {
      if( Tonasket.Onida == 0 and Everetts.TonkaBay == 1) {
         apply( Waring );
      } else {
         apply( Larsen );
      }
   }
   if( Waterfall.Lostwood != 0 ) {
      Picabo();
   }
   Oketo();
   if( valid( Allerton[0] ) ) {
      Frankfort();
   }
   if( Tonasket.Onida == 0 ) {
      Reynolds();
   }
   Eddington();
   Rowden();
}
control egress {
   Joslin();
   Newcomb();
   Colonie();
   if( ( Tonasket.Funston == 0 ) and ( Tonasket.Suarez != 2 ) ) {
      MillCity();
   }
   McDermott();
}

