// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 143314

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
header_type Parksley {
	fields {
		Willey : 16;
		Arion : 16;
		Nanson : 8;
		Johnsburg : 8;
		Panacea : 8;
		Diomede : 8;
		LaHoma : 2;
		Kirwin : 2;
		Lodoga : 1;
		Follett : 3;
		Rotan : 3;
	}
}
header_type Lamar {
	fields {
		Elliston : 24;
		LaHabra : 24;
		WolfTrap : 24;
		Farlin : 24;
		Paxtonia : 16;
		Alvordton : 12;
		Rosburg : 16;
		Goldsmith : 16;
		Braxton : 16;
		Bozeman : 8;
		Salduro : 8;
		Iberia : 1;
		Colmar : 1;
		Stidham : 3;
		Onava : 2;
		BigPlain : 1;
		Naches : 1;
		Almota : 1;
		National : 1;
		Bayville : 1;
		Pineville : 1;
		Nichols : 1;
		Bayport : 1;
		Dowell : 1;
		Callao : 1;
		Wheeler : 1;
		Norseland : 1;
		Morgana : 16;
		Cathcart : 16;
		Moseley : 8;
	}
}
header_type Youngwood {
	fields {
		Haverford : 24;
		Abbott : 24;
		Highfill : 24;
		Embarrass : 24;
		Perdido : 24;
		Harpster : 24;
		Lumpkin : 1;
		Ivanhoe : 3;
		McDonough : 1;
		CruzBay : 12;
		Skene : 16;
		Balmville : 16;
		Plandome : 16;
		Luttrell : 12;
		RoseTree : 3;
		Burgess : 1;
		Tryon : 1;
		Pierceton : 1;
		Shubert : 1;
		Highcliff : 1;
		Coulee : 8;
		Towaoc : 12;
		Midas : 4;
		McClure : 6;
		Sherwin : 10;
		RockyGap : 18;
		Kempner : 32;
		Vestaburg : 8;
		McCaulley : 24;
		Plata : 24;
		Mattson : 24;
		Armagh : 32;
		Sherando : 9;
		Asher : 2;
		FlatRock : 1;
		Machens : 1;
		Oakton : 1;
		Riverbank : 1;
		GilaBend : 1;
		Bangor : 32;
		Verndale : 12;
		Calumet : 1;
	}
}
header_type Sieper {
	fields {
		Corvallis : 8;
		Alstown : 4;
		Suwanee : 1;
	}
}
header_type Baxter {
	fields {
		Leoma : 32;
		Myoma : 32;
		Forkville : 6;
		Egypt : 16;
	}
}
header_type Odebolt {
	fields {
		CityView : 128;
		Puryear : 128;
		PineHill : 20;
		DewyRose : 8;
		Conejo : 11;
		Shelbina : 6;
		Eastover : 13;
	}
}
header_type Nanakuli {
	fields {
		Devola : 14;
		Larue : 1;
		McKenna : 12;
		Slagle : 1;
		Yukon : 1;
		Ellisport : 2;
		SanPablo : 6;
		Chatfield : 3;
	}
}
header_type Norcatur {
	fields {
		Overton : 1;
		Ladoga : 1;
	}
}
header_type Petroleum {
	fields {
		Struthers : 8;
	}
}
header_type PortWing {
	fields {
		Odessa : 16;
		Cedaredge : 11;
	}
}
header_type Gagetown {
	fields {
		Kaufman : 32;
		Agency : 32;
		Vieques : 32;
	}
}
header_type Rembrandt {
	fields {
		Sheldahl : 32;
		Slater : 32;
	}
}
header_type Blencoe {
	fields {
		Sunbury : 1;
		Westville : 1;
		Swedeborg : 1;
		Littleton : 3;
		Marshall : 1;
		Dairyland : 6;
		Eckman : 4;
		Weehawken : 5;
	}
}
header_type Ozona {
	fields {
		Earlham : 16;
	}
}
header_type Sopris {
	fields {
		Portis : 14;
		Ellicott : 1;
		EastLake : 1;
	}
}
header_type Konnarock {
	fields {
		Bairoa : 14;
		PawCreek : 1;
		Seguin : 1;
	}
}
header_type Eddystone {
	fields {
		Rocky : 16;
		Komatke : 16;
		Caban : 16;
		VanHorn : 16;
		Accord : 8;
		Fitler : 8;
		Bosco : 8;
		DeepGap : 8;
		Oroville : 1;
		Milam : 6;
	}
}
header_type Rapids {
	fields {
		Omemee : 32;
	}
}
header_type Valier {
	fields {
		Kelso : 6;
		Alburnett : 10;
		Sanatoga : 4;
		Everetts : 12;
		Funkley : 2;
		Donald : 2;
		Sugarloaf : 12;
		Idylside : 8;
		Shoshone : 3;
		Dalton : 5;
	}
}
header_type Marbleton {
	fields {
		Energy : 24;
		Suwannee : 24;
		Sherack : 24;
		LoonLake : 24;
		Harviell : 16;
	}
}
header_type Pickett {
	fields {
		Renick : 3;
		Schleswig : 1;
		Lincroft : 12;
		Missoula : 16;
	}
}
header_type Driftwood {
	fields {
		Ovilla : 4;
		TenSleep : 4;
		Pinole : 6;
		Garlin : 2;
		Kipahulu : 16;
		Maybell : 16;
		WestPike : 3;
		Satanta : 13;
		Separ : 8;
		Lemhi : 8;
		Blackwood : 16;
		Stirrat : 32;
		Bains : 32;
	}
}
header_type Gower {
	fields {
		Manasquan : 4;
		ArchCape : 6;
		Belvidere : 2;
		Worthing : 20;
		Florien : 16;
		Minturn : 8;
		Lizella : 8;
		RiceLake : 128;
		Engle : 128;
	}
}
header_type Verdigris {
	fields {
		Norco : 8;
		Utuado : 8;
		Copley : 16;
	}
}
header_type Minto {
	fields {
		Nooksack : 16;
		Scarville : 16;
	}
}
header_type Durant {
	fields {
		Mayday : 32;
		Pensaukee : 32;
		Comobabi : 4;
		ElkMills : 4;
		Wyndmoor : 8;
		Celada : 16;
		Mabelle : 16;
		Hulbert : 16;
	}
}
header_type Paicines {
	fields {
		Keokee : 16;
		Leona : 16;
	}
}
header_type Chewalla {
	fields {
		Olene : 16;
		Skiatook : 16;
		McDermott : 8;
		Amalga : 8;
		Merino : 16;
	}
}
header_type Ipava {
	fields {
		Mickleton : 48;
		RockHall : 32;
		Arnett : 48;
		Wenham : 32;
	}
}
header_type Holtville {
	fields {
		Allen : 1;
		WestLine : 1;
		Casper : 1;
		Mabel : 1;
		Asharoken : 1;
		Malaga : 3;
		Perrine : 5;
		Orrstown : 3;
		BigLake : 16;
	}
}
header_type Halfa {
	fields {
		Cochrane : 24;
		Annette : 8;
	}
}
header_type Waterflow {
	fields {
		Conneaut : 8;
		Graford : 24;
		Ronneby : 24;
		Flasher : 8;
	}
}
header Marbleton Pecos;
header Marbleton Ishpeming;
header Pickett Lebanon[ 2 ];
@pragma pa_fragment ingress Easley.Blackwood
@pragma pa_fragment egress Easley.Blackwood
header Driftwood Easley;
@pragma pa_fragment ingress Jarrell.Blackwood
@pragma pa_fragment egress Jarrell.Blackwood
header Driftwood Jarrell;
header Gower Alakanuk;
header Gower Eolia;
header Minto Kenefic;
header Minto Quebrada;
header Durant Cranbury;
header Paicines Fairborn;
header Durant Waialua;
header Paicines Colstrip;
header Waterflow Calcium;
header Holtville Knollwood;
header Valier Bratt;
header Marbleton Pinesdale;
parser start {
   return select(current(96, 16)) {
      0xBF00 : Cornwall;
      default : Kaaawa;
   }
}
parser BayPort {
   extract( Bratt );
   return Kaaawa;
}
parser Cornwall {
   extract( Pinesdale );
   return BayPort;
}
parser Kaaawa {
   extract( Pecos );
   return select( Pecos.Harviell ) {
      0x8100 : Onida;
      0x0800 : Latham;
      0x86dd : Berville;
      default : ingress;
   }
}
parser Onida {
   extract( Lebanon[0] );
   set_metadata(Oxford.Lodoga, 1);
   return select( Lebanon[0].Missoula ) {
      0x0800 : Latham;
      0x86dd : Berville;
      default : ingress;
   }
}
field_list Frontenac {
    Easley.Ovilla;
    Easley.TenSleep;
    Easley.Pinole;
    Easley.Garlin;
    Easley.Kipahulu;
    Easley.Maybell;
    Easley.WestPike;
    Easley.Satanta;
    Easley.Separ;
    Easley.Lemhi;
    Easley.Stirrat;
    Easley.Bains;
}
field_list_calculation Benwood {
    input {
        Frontenac;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Easley.Blackwood {
    verify Benwood;
    update Benwood;
}
parser Latham {
   extract( Easley );
   set_metadata(Oxford.Nanson, Easley.Lemhi);
   set_metadata(Oxford.Panacea, Easley.Separ);
   set_metadata(Oxford.LaHoma, 1);
   set_metadata( MoonRun.Bangor, current(0, 32));
   return select(Easley.Satanta, Easley.TenSleep, Easley.Lemhi) {
      0x501 : NewRoads;
      0x511 : Ivydale;
      0x506 : Yardville;
      0 mask 0xFF7000 : ingress;
      0x506 mask 0xfff: Cornudas;
      default : Wakita;
   }
}
parser Cornudas {
   set_metadata(Oxford.Rotan, 5);
   return ingress;
}
parser Wakita {
   set_metadata(Oxford.Rotan, 1);
   return ingress;
}
parser Berville {
   extract( Eolia );
   set_metadata(Oxford.Nanson, Eolia.Minturn);
   set_metadata(Oxford.Panacea, Eolia.Lizella);
   set_metadata(Oxford.LaHoma, 2);
   return select(Eolia.Minturn) {
      0x3a : NewRoads;
      17 : Pimento;
      6 : Yardville;
      default : ingress;
   }
}
parser Ivydale {
   set_metadata(Oxford.Rotan, 2);
   extract(Kenefic);
   extract(Fairborn);
   return select(Kenefic.Scarville) {
      4789 : Tularosa;
      default : ingress;
    }
}
parser NewRoads {
   set_metadata( Kenefic.Nooksack, current( 0, 16 ) );
   return ingress;
}
parser Pimento {
   set_metadata(Oxford.Rotan, 2);
   extract(Kenefic);
   extract(Fairborn);
   return ingress;
}
parser Yardville {
   set_metadata(Oxford.Rotan, 6);
   extract(Kenefic);
   extract(Cranbury);
   return ingress;
}
parser Pinecrest {
   set_metadata(Weyauwega.Onava, 2);
   return McManus;
}
parser Hartwell {
   set_metadata(Weyauwega.Onava, 2);
   return Vanzant;
}
parser PawPaw {
   extract(Knollwood);
   return select(Knollwood.Allen, Knollwood.WestLine, Knollwood.Casper, Knollwood.Mabel, Knollwood.Asharoken,
             Knollwood.Malaga, Knollwood.Perrine, Knollwood.Orrstown, Knollwood.BigLake) {
      0x0800 : Pinecrest;
      0x86dd : Hartwell;
      default : ingress;
   }
}
parser Tularosa {
   extract(Calcium);
   set_metadata(Weyauwega.Onava, 1);
   return Fonda;
}
field_list Kohrville {
    Jarrell.Ovilla;
    Jarrell.TenSleep;
    Jarrell.Pinole;
    Jarrell.Garlin;
    Jarrell.Kipahulu;
    Jarrell.Maybell;
    Jarrell.WestPike;
    Jarrell.Satanta;
    Jarrell.Separ;
    Jarrell.Lemhi;
    Jarrell.Stirrat;
    Jarrell.Bains;
}
field_list_calculation Pojoaque {
    input {
        Kohrville;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Jarrell.Blackwood {
    verify Pojoaque;
    update Pojoaque;
}
parser McManus {
   extract( Jarrell );
   set_metadata(Oxford.Johnsburg, Jarrell.Lemhi);
   set_metadata(Oxford.Diomede, Jarrell.Separ);
   set_metadata(Oxford.Kirwin, 1);
   set_metadata(Grisdale.Leoma, Jarrell.Stirrat);
   set_metadata(Grisdale.Myoma, Jarrell.Bains);
   return select(Jarrell.Satanta, Jarrell.TenSleep, Jarrell.Lemhi) {
      0x501 : Welch;
      0x511 : Anahola;
      0x506 : Yaurel;
      0 mask 0xFF7000 : ingress;
      0x506 mask 0xfff: Chemult;
      default : RoseBud;
   }
}
parser Chemult {
   set_metadata(Oxford.Follett, 5);
   return ingress;
}
parser RoseBud {
   set_metadata(Oxford.Follett, 1);
   return ingress;
}
parser Vanzant {
   extract( Alakanuk );
   set_metadata(Oxford.Johnsburg, Alakanuk.Minturn);
   set_metadata(Oxford.Diomede, Alakanuk.Lizella);
   set_metadata(Oxford.Arion, Alakanuk.Florien);
   set_metadata(Oxford.Kirwin, 2);
   set_metadata(Wallula.CityView, Alakanuk.RiceLake);
   set_metadata(Wallula.Puryear, Alakanuk.Engle);
   return select(Alakanuk.Minturn) {
      0x3a : Welch;
      17 : Anahola;
      6 : Yaurel;
      default : ingress;
   }
}
parser Welch {
   set_metadata( Weyauwega.Morgana, current( 0, 16 ) );
   return ingress;
}
parser Anahola {
   set_metadata( Weyauwega.Morgana, current( 0, 16 ) );
   set_metadata( Weyauwega.Cathcart, current( 16, 16 ) );
   set_metadata(Oxford.Follett, 2);
   return ingress;
}
parser Yaurel {
   set_metadata( Weyauwega.Morgana, current( 0, 16 ) );
   set_metadata( Weyauwega.Cathcart, current( 16, 16 ) );
   set_metadata( Weyauwega.Moseley, current( 104, 8 ) );
   set_metadata(Oxford.Follett, 6);
   extract(Quebrada);
   extract(Waialua);
   return ingress;
}
parser Fonda {
   extract( Ishpeming );
   set_metadata( Weyauwega.Elliston, Ishpeming.Energy );
   set_metadata( Weyauwega.LaHabra, Ishpeming.Suwannee );
   set_metadata( Weyauwega.Paxtonia, Ishpeming.Harviell );
   return select( Ishpeming.Harviell ) {
      0x0800: McManus;
      0x86dd: Vanzant;
      default: ingress;
   }
}
@pragma pa_no_init ingress Weyauwega.Elliston
@pragma pa_no_init ingress Weyauwega.LaHabra
@pragma pa_no_init ingress Weyauwega.WolfTrap
@pragma pa_no_init ingress Weyauwega.Farlin
@pragma pa_container_size ingress Weyauwega.Onava 16
metadata Lamar Weyauwega;
@pragma pa_no_init ingress MoonRun.Haverford
@pragma pa_no_init ingress MoonRun.Abbott
@pragma pa_no_init ingress MoonRun.Highfill
@pragma pa_no_init ingress MoonRun.Embarrass
@pragma pa_do_not_bridge egress MoonRun.Bangor
@pragma pa_container_size egress MoonRun.Bangor 32
metadata Youngwood MoonRun;
metadata Nanakuli Osman;
@pragma pa_do_not_bridge egress Oxford.Nanson
metadata Parksley Oxford;
metadata Baxter Grisdale;
metadata Odebolt Wallula;
metadata Norcatur Kingman;
@pragma pa_container_size ingress Kingman.Ladoga 32
metadata Sieper Biscay;
metadata Petroleum Duchesne;
metadata PortWing Willmar;
metadata Rembrandt Lazear;
metadata Gagetown Trotwood;
metadata Blencoe Charco;
metadata Ozona Gurley;
@pragma pa_no_init ingress Newcastle.Portis
@pragma pa_solitary ingress Newcastle.EastLake
metadata Sopris Newcastle;
@pragma pa_no_init ingress Robstown.Bairoa
metadata Konnarock Robstown;
metadata Eddystone Minoa;
metadata Eddystone LaSalle;
action Sigsbee() {
   no_op();
}
action Canfield() {
   modify_field(Weyauwega.BigPlain, 1 );
   mark_for_drop();
}
action DeGraff() {
   no_op();
}
action Halstead(Motley, Newfield, Manistee, Licking, Millett,
                 Menomonie, Spivey, Skyline) {
    modify_field(Osman.Devola, Motley);
    modify_field(Osman.Larue, Newfield);
    modify_field(Osman.McKenna, Manistee);
    modify_field(Osman.Slagle, Licking);
    modify_field(Osman.Yukon, Millett);
    modify_field(Osman.Ellisport, Menomonie);
    modify_field(Osman.Chatfield, Spivey);
    modify_field(Osman.SanPablo, Skyline);
}
table Blakeley {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Halstead;
    }
    size : 288;
}
control Cross {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Blakeley);
    }
}
action Elburn(Odenton, Marquand) {
   modify_field( MoonRun.McDonough, 1 );
   modify_field( MoonRun.Coulee, Odenton);
   modify_field( Weyauwega.Nichols, 1 );
   modify_field( Charco.Swedeborg, Marquand );
}
action Clarissa() {
   modify_field( Weyauwega.National, 1 );
   modify_field( Weyauwega.Dowell, 1 );
}
action Rayville() {
   modify_field( Weyauwega.Nichols, 1 );
}
action Novinger() {
   modify_field( Weyauwega.Nichols, 1 );
   modify_field( Weyauwega.Callao, 1 );
}
action Olcott() {
   modify_field( Weyauwega.Bayport, 1 );
}
action Greenhorn() {
   modify_field( Weyauwega.Dowell, 1 );
}
counter Orting {
   type : packets_and_bytes;
   direct : Faulkner;
   min_width: 16;
}
table Faulkner {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Pecos.Energy : ternary;
      Pecos.Suwannee : ternary;
   }
   actions {
      Elburn;
      Clarissa;
      Rayville;
      Olcott;
      Greenhorn;
      Novinger;
   }
   size : 2048;
}
action Lowden() {
   modify_field( Weyauwega.Bayville, 1 );
}
table Maljamar {
   reads {
      Pecos.Sherack : ternary;
      Pecos.LoonLake : ternary;
   }
   actions {
      Lowden;
   }
   size : 512;
}
control MintHill {
   apply( Faulkner );
   apply( Maljamar );
}
action Montegut() {
   modify_field( Grisdale.Forkville, Jarrell.Pinole );
   modify_field( Wallula.PineHill, Alakanuk.Worthing );
   modify_field( Wallula.Shelbina, Alakanuk.ArchCape );
   modify_field( Weyauwega.WolfTrap, Ishpeming.Sherack );
   modify_field( Weyauwega.Farlin, Ishpeming.LoonLake );
   modify_field( Weyauwega.Braxton, Oxford.Arion );
   modify_field( Weyauwega.Bozeman, Oxford.Johnsburg );
   modify_field( Weyauwega.Salduro, Oxford.Diomede );
   modify_field( Weyauwega.Colmar, Oxford.Kirwin, 1 );
   shift_right( Weyauwega.Iberia, Oxford.Kirwin, 1 );
   modify_field( Weyauwega.Wheeler, 0 );
   modify_field( MoonRun.RoseTree, 1 );
   modify_field( Osman.Ellisport, 1 );
   modify_field( Osman.Chatfield, 0 );
   modify_field( Osman.SanPablo, 0 );
   modify_field( Charco.Sunbury, 1 );
   modify_field( Charco.Westville, 1 );
   modify_field( Minoa.Caban, Weyauwega.Morgana );
   modify_field( Weyauwega.Stidham, Oxford.Follett );
   modify_field( Minoa.Oroville, Oxford.Follett, 1);
}
action Flats() {
   modify_field( Weyauwega.Onava, 0 );
   modify_field( Grisdale.Leoma, Easley.Stirrat );
   modify_field( Grisdale.Myoma, Easley.Bains );
   modify_field( Grisdale.Forkville, Easley.Pinole );
   modify_field( Wallula.CityView, Eolia.RiceLake );
   modify_field( Wallula.Puryear, Eolia.Engle );
   modify_field( Wallula.PineHill, Eolia.Worthing );
   modify_field( Wallula.Shelbina, Eolia.ArchCape );
   modify_field( Weyauwega.Elliston, Pecos.Energy );
   modify_field( Weyauwega.LaHabra, Pecos.Suwannee );
   modify_field( Weyauwega.WolfTrap, Pecos.Sherack );
   modify_field( Weyauwega.Farlin, Pecos.LoonLake );
   modify_field( Weyauwega.Paxtonia, Pecos.Harviell );
   modify_field( Weyauwega.Bozeman, Oxford.Nanson );
   modify_field( Weyauwega.Salduro, Oxford.Panacea );
   modify_field( Weyauwega.Colmar, Oxford.LaHoma, 1 );
   shift_right( Weyauwega.Iberia, Oxford.LaHoma, 1 );
   modify_field( Charco.Marshall, Lebanon[0].Schleswig );
   modify_field( Weyauwega.Wheeler, Oxford.Lodoga );
   modify_field( Minoa.Caban, Kenefic.Nooksack );
   modify_field( Weyauwega.Morgana, Kenefic.Nooksack );
   modify_field( Weyauwega.Cathcart, Kenefic.Scarville );
   modify_field( Weyauwega.Moseley, Cranbury.Wyndmoor );
   modify_field( Weyauwega.Stidham, Oxford.Rotan );
   modify_field( Minoa.Oroville, Oxford.Rotan, 1);
}
table RoyalOak {
   reads {
      Pecos.Energy : exact;
      Pecos.Suwannee : exact;
      Easley.Bains : exact;
      Weyauwega.Onava : exact;
   }
   actions {
      Montegut;
      Flats;
   }
   default_action : Flats();
   size : 1024;
}
action McMurray() {
   modify_field( Weyauwega.Alvordton, Osman.McKenna );
   modify_field( Weyauwega.Rosburg, Osman.Devola);
}
action Heaton( OldTown ) {
   modify_field( Weyauwega.Alvordton, OldTown );
   modify_field( Weyauwega.Rosburg, Osman.Devola);
}
action Hoadly() {
   modify_field( Weyauwega.Alvordton, Lebanon[0].Lincroft );
   modify_field( Weyauwega.Rosburg, Osman.Devola);
}
table Wellsboro {
   reads {
      Osman.Devola : ternary;
      Lebanon[0] : valid;
      Lebanon[0].Lincroft : ternary;
   }
   actions {
      McMurray;
      Heaton;
      Hoadly;
   }
   size : 4096;
}
action Strasburg( MontIda ) {
   modify_field( Weyauwega.Rosburg, MontIda );
}
action Hearne() {
   modify_field( Duchesne.Struthers,
                 2 );
}
table Mahopac {
   reads {
      Easley.Stirrat : exact;
   }
   actions {
      Strasburg;
      Hearne;
   }
   default_action : Hearne;
   size : 4096;
}
action Romero( Brinkley, Spearman, Shingler, Lepanto ) {
   modify_field( Weyauwega.Alvordton, Brinkley );
   modify_field( Weyauwega.Goldsmith, Brinkley );
   modify_field( Weyauwega.Almota, Lepanto );
   Brumley(Spearman, Shingler);
}
action Macksburg() {
   modify_field( Weyauwega.Naches, 1 );
}
table Richvale {
   reads {
      Calcium.Ronneby : exact;
   }
   actions {
      Romero;
      Macksburg;
   }
   size : 4096;
}
action Brumley(Exeter, Gahanna) {
   modify_field( Biscay.Corvallis, Exeter );
   modify_field( Biscay.Alstown, Gahanna );
}
action Hematite(Villanova, Gambrill) {
   modify_field( Weyauwega.Goldsmith, Osman.McKenna );
   Brumley(Villanova, Gambrill);
}
action Cashmere(Virgil, Harris, Tilghman) {
   modify_field( Weyauwega.Goldsmith, Virgil );
   Brumley(Harris, Tilghman);
}
action Kinsley(Retrop, Trammel) {
   modify_field( Weyauwega.Goldsmith, Lebanon[0].Lincroft );
   Brumley(Retrop, Trammel);
}
@pragma ternary 1
table Atoka {
   reads {
      Osman.McKenna : exact;
   }
   actions {
      Sigsbee;
      Hematite;
   }
   size : 512;
}
@pragma action_default_only Sigsbee
table Aynor {
   reads {
      Osman.Devola : exact;
      Lebanon[0].Lincroft : exact;
   }
   actions {
      Cashmere;
      Sigsbee;
   }
   size : 1024;
}
table Knierim {
   reads {
      Lebanon[0].Lincroft : exact;
   }
   actions {
      Sigsbee;
      Kinsley;
   }
   size : 4096;
}
control Wamego {
   apply( RoyalOak ) {
         Montegut {
            apply( Mahopac );
            apply( Richvale );
         }
         Flats {
            if ( Osman.Slagle == 1 ) {
               apply( Wellsboro );
            }
            if ( valid( Lebanon[ 0 ] ) and Lebanon[ 0 ].Lincroft != 0 ) {
               apply( Aynor ) {
                  Sigsbee {
                     apply( Knierim );
                  }
               }
            } else {
               apply( Atoka );
            }
         }
   }
}
register Abernathy {
    width : 1;
    static : Nankin;
    instance_count : 294912;
}
register Pittsburg {
    width : 1;
    static : Altus;
    instance_count : 294912;
}
blackbox stateful_alu Valmeyer {
    reg : Abernathy;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : Kingman.Overton;
}
blackbox stateful_alu Seibert {
    reg : Pittsburg;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst : Kingman.Ladoga;
}
field_list Sparr {
    ig_intr_md.ingress_port;
    Lebanon[0].Lincroft;
}
field_list_calculation Edler {
    input { Sparr; }
    algorithm: identity;
    output_width: 19;
}
action Shirley() {
    Valmeyer.execute_stateful_alu_from_hash(Edler);
}
action Shamokin() {
    Seibert.execute_stateful_alu_from_hash(Edler);
}
table Nankin {
    actions {
      Shirley;
    }
    default_action : Shirley;
    size : 1;
}
table Altus {
    actions {
      Shamokin;
    }
    default_action : Shamokin;
    size : 1;
}
action Nipton(Brush) {
    modify_field(Kingman.Ladoga, Brush);
}
@pragma ternary 1
table Stateline {
    reads {
       ig_intr_md.ingress_port mask 0x7f : exact;
    }
    actions {
      Nipton;
    }
    size : 72;
}
control Hinkley {
   if ( valid( Lebanon[ 0 ] ) and Lebanon[ 0 ].Lincroft != 0 ) {
      if( Osman.Yukon == 1 ) {
         apply( Nankin );
         apply( Altus );
      }
   } else {
      if( Osman.Yukon == 1 ) {
         apply( Stateline );
      }
   }
}
field_list Ralph {
   Pecos.Energy;
   Pecos.Suwannee;
   Pecos.Sherack;
   Pecos.LoonLake;
   Pecos.Harviell;
}
field_list Hilger {
   Easley.Lemhi;
   Easley.Stirrat;
   Easley.Bains;
}
field_list Immokalee {
   Eolia.RiceLake;
   Eolia.Engle;
   Eolia.Worthing;
   Eolia.Minturn;
}
field_list Canton {
   Easley.Stirrat;
   Easley.Bains;
   Kenefic.Nooksack;
   Kenefic.Scarville;
}
field_list_calculation Waipahu {
    input {
        Ralph;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Raiford {
    input {
        Hilger;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Pearson {
    input {
        Immokalee;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Harvey {
    input {
        Canton;
    }
    algorithm : crc32;
    output_width : 32;
}
action Modale() {
    modify_field_with_hash_based_offset(Trotwood.Kaufman, 0,
                                        Waipahu, 4294967296);
}
action Harrison() {
    modify_field_with_hash_based_offset(Trotwood.Agency, 0,
                                        Raiford, 4294967296);
}
action Deeth() {
    modify_field_with_hash_based_offset(Trotwood.Agency, 0,
                                        Pearson, 4294967296);
}
action Nunda() {
    modify_field_with_hash_based_offset(Trotwood.Vieques, 0,
                                        Harvey, 4294967296);
}
table Grasston {
   actions {
      Modale;
   }
   size: 1;
}
control Sanborn {
   apply(Grasston);
}
table Uniopolis {
   actions {
      Harrison;
   }
   size: 1;
}
table Bammel {
   actions {
      Deeth;
   }
   size: 1;
}
control Brady {
   if ( valid( Easley ) ) {
      apply(Uniopolis);
   } else {
      if ( valid( Eolia ) ) {
         apply(Bammel);
      }
   }
}
table Minneota {
   actions {
      Nunda;
   }
   size: 1;
}
control Maiden {
   if ( valid( Fairborn ) ) {
      apply(Minneota);
   }
}
action LaCenter() {
    modify_field(Lazear.Sheldahl, Trotwood.Kaufman);
}
action Anthon() {
    modify_field(Lazear.Sheldahl, Trotwood.Agency);
}
action Crystola() {
    modify_field(Lazear.Sheldahl, Trotwood.Vieques);
}
@pragma action_default_only Sigsbee
@pragma immediate 0
table Crestone {
   reads {
      Waialua.valid : ternary;
      Colstrip.valid : ternary;
      Jarrell.valid : ternary;
      Alakanuk.valid : ternary;
      Ishpeming.valid : ternary;
      Cranbury.valid : ternary;
      Fairborn.valid : ternary;
      Easley.valid : ternary;
      Eolia.valid : ternary;
      Pecos.valid : ternary;
   }
   actions {
      LaCenter;
      Anthon;
      Crystola;
      Sigsbee;
   }
   size: 256;
}
action Visalia() {
    modify_field(Lazear.Slater, Trotwood.Vieques);
}
@pragma immediate 0
table Fairlea {
   reads {
      Waialua.valid : ternary;
      Colstrip.valid : ternary;
      Cranbury.valid : ternary;
      Fairborn.valid : ternary;
   }
   actions {
      Visalia;
      Sigsbee;
   }
   size: 6;
}
control Wabuska {
   apply(Fairlea);
   apply(Crestone);
}
counter Hamel {
   type : packets_and_bytes;
   direct : Brookneal;
   min_width: 16;
}
table Brookneal {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Kingman.Ladoga : ternary;
      Kingman.Overton : ternary;
      Weyauwega.Naches : ternary;
      Weyauwega.Bayville : ternary;
      Weyauwega.National : ternary;
   }
   actions {
      Canfield;
      Sigsbee;
   }
   default_action : Sigsbee();
   size : 512;
}
table Philmont {
   reads {
      Weyauwega.WolfTrap : exact;
      Weyauwega.Farlin : exact;
      Weyauwega.Alvordton : exact;
   }
   actions {
      Canfield;
      Sigsbee;
   }
   default_action : Sigsbee();
   size : 4096;
}
action Tofte() {
   modify_field(Duchesne.Struthers,
                1);
}
table Kasigluk {
   reads {
      Weyauwega.WolfTrap : exact;
      Weyauwega.Farlin : exact;
      Weyauwega.Alvordton : exact;
      Weyauwega.Rosburg : exact;
   }
   actions {
      DeGraff;
      Tofte;
   }
   default_action : Tofte();
   size : 65536;
   support_timeout : true;
}
action Warden( Woolwine, Rockvale ) {
   modify_field( Weyauwega.Norseland, Woolwine );
   modify_field( Weyauwega.Almota, Rockvale );
}
action Broussard() {
   modify_field( Weyauwega.Almota, 1 );
}
table Reidville {
   reads {
      Weyauwega.Alvordton mask 0xfff : exact;
   }
   actions {
      Warden;
      Broussard;
      Sigsbee;
   }
   default_action : Sigsbee();
   size : 4096;
}
action Goulds() {
   modify_field( Biscay.Suwanee, 1 );
}
table Dubach {
   reads {
      Weyauwega.Goldsmith : ternary;
      Weyauwega.Elliston : exact;
      Weyauwega.LaHabra : exact;
   }
   actions {
      Goulds;
   }
   size: 512;
}
control Swisshome {
   apply( Brookneal ) {
      Sigsbee {
         apply( Philmont ) {
            Sigsbee {
               if (Osman.Larue == 0 and Duchesne.Struthers == 0) {
                  apply( Kasigluk );
               }
               apply( Reidville );
               apply(Dubach);
            }
         }
      }
   }
}
field_list Seaforth {
    Duchesne.Struthers;
    Weyauwega.WolfTrap;
    Weyauwega.Farlin;
    Weyauwega.Alvordton;
    Weyauwega.Rosburg;
}
action Empire() {
   generate_digest(0, Seaforth);
}
table Grovetown {
   actions {
      Empire;
   }
   size : 1;
}
control Huxley {
   if (Duchesne.Struthers == 1) {
      apply( Grovetown );
   }
}
action Everton( Wrens, Lenwood ) {
   modify_field( Wallula.Eastover, Wrens );
   modify_field( Willmar.Odessa, Lenwood );
}
action Norias( Lapoint, Convoy ) {
   modify_field( Wallula.Eastover, Lapoint );
   modify_field( Willmar.Cedaredge, Convoy );
}
@pragma action_default_only Finlayson
table Belen {
   reads {
      Biscay.Corvallis : exact;
      Wallula.Puryear mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Everton;
      Finlayson;
      Norias;
   }
   size : 8192;
}
@pragma atcam_partition_index Wallula.Eastover
@pragma atcam_number_partitions 8192
table Rehobeth {
   reads {
      Wallula.Eastover : exact;
      Wallula.Puryear mask 0x000007FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Holcomb;
      Hargis;
      Sigsbee;
   }
   default_action : Sigsbee();
   size : 65536;
}
action Craigtown( Walland, Fordyce ) {
   modify_field( Wallula.Conejo, Walland );
   modify_field( Willmar.Odessa, Fordyce );
}
action Boistfort( Gorman, Edroy ) {
   modify_field( Wallula.Conejo, Gorman );
   modify_field( Willmar.Cedaredge, Edroy );
}
@pragma action_default_only Sigsbee
table Tilton {
   reads {
      Biscay.Corvallis : exact;
      Wallula.Puryear : lpm;
   }
   actions {
      Craigtown;
      Boistfort;
      Sigsbee;
   }
   size : 2048;
}
@pragma atcam_partition_index Wallula.Conejo
@pragma atcam_number_partitions 2048
table Waldport {
   reads {
      Wallula.Conejo : exact;
      Wallula.Puryear mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Holcomb;
      Hargis;
      Sigsbee;
   }
   default_action : Sigsbee();
   size : 16384;
}
@pragma action_default_only Finlayson
@pragma idletime_precision 1
table Westview {
   reads {
      Biscay.Corvallis : exact;
      Grisdale.Myoma : lpm;
   }
   actions {
      Holcomb;
      Hargis;
      Finlayson;
   }
   size : 1024;
   support_timeout : true;
}
action Hoagland( SnowLake, WarEagle ) {
   modify_field( Grisdale.Egypt, SnowLake );
   modify_field( Willmar.Odessa, WarEagle );
}
action Lushton( Marydel, Wesson ) {
   modify_field( Grisdale.Egypt, Marydel );
   modify_field( Willmar.Cedaredge, Wesson );
}
@pragma action_default_only Sigsbee
table Wimbledon {
   reads {
      Biscay.Corvallis : exact;
      Grisdale.Myoma : lpm;
   }
   actions {
      Hoagland;
      Lushton;
      Sigsbee;
   }
   size : 16384;
}
@pragma ways 2
@pragma atcam_partition_index Grisdale.Egypt
@pragma atcam_number_partitions 16384
table China {
   reads {
      Grisdale.Egypt : exact;
      Grisdale.Myoma mask 0x000fffff : lpm;
   }
   actions {
      Holcomb;
      Hargis;
      Sigsbee;
   }
   default_action : Sigsbee();
   size : 131072;
}
action Holcomb( Wolford ) {
   modify_field( Willmar.Odessa, Wolford );
}
@pragma idletime_precision 1
table Moclips {
   reads {
      Biscay.Corvallis : exact;
      Grisdale.Myoma : exact;
   }
   actions {
      Holcomb;
      Hargis;
      Sigsbee;
   }
   default_action : Sigsbee();
   size : 65536;
   support_timeout : true;
}
@pragma idletime_precision 1
@pragma stage 2 28672
@pragma stage 3
table Whitten {
   reads {
      Biscay.Corvallis : exact;
      Wallula.Puryear : exact;
   }
   actions {
      Holcomb;
      Hargis;
      Sigsbee;
   }
   default_action : Sigsbee();
   size : 65536;
   support_timeout : true;
}
action Skyway(Brazos, Rendon, Carlsbad) {
   modify_field(MoonRun.CruzBay, Carlsbad);
   modify_field(MoonRun.Haverford, Brazos);
   modify_field(MoonRun.Abbott, Rendon);
   modify_field(MoonRun.FlatRock, 1);
   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}
action Sabina() {
   Canfield();
}
action Yakima(Thalia) {
   modify_field(MoonRun.McDonough, 1);
   modify_field(MoonRun.Coulee, Thalia);
}
action Finlayson(Jefferson) {
   modify_field(Willmar.Odessa, Jefferson);
}
table Success {
   reads {
      Willmar.Odessa : exact;
   }
   actions {
      Skyway;
      Sabina;
      Yakima;
   }
   size : 65536;
}
action Dunphy(Eldora) {
   modify_field(Willmar.Odessa, Eldora);
}
table Corydon {
   actions {
      Dunphy;
   }
   default_action: Dunphy;
   size : 1;
}
control Akiachak {
   if ( ( ( Biscay.Alstown & ( 0x2 ) ) == ( ( 0x2 ) ) ) and ( Weyauwega.Iberia == 1 ) ) {
      if ( Weyauwega.BigPlain == 0 and Biscay.Suwanee == 1 ) {
         apply( Whitten ) {
            Sigsbee {
               apply( Tilton );
            }
         }
      }
   } else if ( ( ( Biscay.Alstown & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Weyauwega.Colmar == 1 ) ) {
      if ( Weyauwega.BigPlain == 0 ) {
         if ( Biscay.Suwanee == 1 ) {
            apply( Moclips ) {
               Sigsbee {
                  apply(Wimbledon);
               }
            }
         }
      }
  }
}
control Montalba {
   if ( Weyauwega.BigPlain == 0 and Biscay.Suwanee == 1 ) {
      if ( ( ( Biscay.Alstown & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Weyauwega.Colmar == 1 ) ) {
         if ( Grisdale.Egypt != 0 ) {
            apply( China );
         } else if ( Willmar.Odessa == 0 and Willmar.Cedaredge == 0 ) {
            apply( Westview );
         }
      } else if ( ( ( Biscay.Alstown & ( 0x2 ) ) == ( ( 0x2 ) ) ) and ( Weyauwega.Iberia == 1 ) ) {
         if ( Wallula.Conejo != 0 ) {
            apply( Waldport );
         } else if ( Willmar.Odessa == 0 and Willmar.Cedaredge == 0 ) {
            apply( Belen );
            if ( Wallula.Eastover != 0 ) {
               apply( Rehobeth );
            }
         }
      } else if( Weyauwega.Almota == 1 ) {
         apply( Corydon );
      }
   }
}
control Kalkaska {
   if( Willmar.Odessa != 0 ) {
      apply( Success );
   }
}
action Hargis( Naalehu ) {
   modify_field( Willmar.Cedaredge, Naalehu );
}
field_list Belmont {
   Lazear.Slater;
}
field_list_calculation Petoskey {
    input {
        Belmont;
    }
    algorithm : identity;
    output_width : 66;
}
action_selector Toluca {
   selection_key : Petoskey;
   selection_mode : resilient;
}
action_profile RowanBay {
   actions {
      Holcomb;
   }
   size : 65536;
   dynamic_action_selection : Toluca;
}
@pragma command_line --no-dead-code-elimination
@pragma selector_max_group_size 256
table Riverland {
   reads {
      Willmar.Cedaredge : exact;
   }
   action_profile : RowanBay;
   size : 2048;
}
control Buckfield {
   if ( Willmar.Cedaredge != 0 ) {
      apply( Riverland );
   }
}
field_list Molson {
   Lazear.Sheldahl;
}
field_list_calculation Faysville {
    input {
        Molson;
    }
    algorithm : identity;
    output_width : 51;
}
action_selector BigWater {
    selection_key : Faysville;
    selection_mode : resilient;
}
action Twinsburg(Onley) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Onley);
}
action_profile Brantford {
    actions {
        Twinsburg;
        Sigsbee;
    }
    size : 1024;
    dynamic_action_selection : BigWater;
}
action Picacho() {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, MoonRun.Balmville);
}
table Elrosa {
   actions {
        Picacho;
   }
   default_action : Picacho();
   size : 1;
}
table Remington {
   reads {
      MoonRun.Balmville mask 0x3FF : exact;
   }
   action_profile: Brantford;
   size : 1024;
}
control Candle {
   if ((MoonRun.Pierceton == 1) or valid(Bratt)) {
      if ((MoonRun.Balmville & 0x3C00) == 0x3C00) {
         apply(Remington);
      } else {
         apply(Elrosa);
      }
   }
}
action Urbanette() {
   modify_field(MoonRun.Haverford, Weyauwega.Elliston);
   modify_field(MoonRun.Abbott, Weyauwega.LaHabra);
   modify_field(MoonRun.Highfill, Weyauwega.WolfTrap);
   modify_field(MoonRun.Embarrass, Weyauwega.Farlin);
   modify_field(MoonRun.CruzBay, Weyauwega.Alvordton);
   invalidate( ig_intr_md_for_tm.ucast_egress_port );
}
table Marley {
   actions {
      Urbanette;
   }
   default_action : Urbanette();
   size : 1;
}
control Marysvale {
   apply( Marley );
}
action Magma() {
   modify_field(MoonRun.Burgess, 1);
   modify_field(MoonRun.Riverbank, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Weyauwega.Almota);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, MoonRun.CruzBay);
}
action Prosser() {
}
@pragma ways 1
table Rumson {
   reads {
      MoonRun.Haverford : exact;
      MoonRun.Abbott : exact;
   }
   actions {
      Magma;
      Prosser;
   }
   default_action : Prosser;
   size : 1;
}
action Pittwood() {
   modify_field(MoonRun.Tryon, 1);
   modify_field(MoonRun.Highcliff, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, MoonRun.CruzBay, 4096);
}
@pragma stage 9
table Bendavis {
   actions {
      Pittwood;
   }
   default_action : Pittwood;
   size : 1;
}
action Pierre() {
   modify_field(MoonRun.Shubert, 1);
   modify_field(MoonRun.Riverbank, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, MoonRun.CruzBay);
}
table Truro {
   actions {
      Pierre;
   }
   default_action : Pierre();
   size : 1;
}
action Archer(Ironia) {
   modify_field(MoonRun.Pierceton, 1);
   modify_field(MoonRun.Balmville, Ironia);
}
action Barnwell(Vevay) {
   modify_field(MoonRun.Tryon, 1);
   modify_field(MoonRun.Plandome, Vevay);
}
action Leadpoint() {
}
table ElkPoint {
   reads {
      MoonRun.Haverford : exact;
      MoonRun.Abbott : exact;
      MoonRun.CruzBay : exact;
   }
   actions {
      Archer;
      Barnwell;
      Canfield;
      Leadpoint;
   }
   default_action : Leadpoint();
   size : 65536;
}
control Firebrick {
   if (Weyauwega.BigPlain == 0 ) {
      apply(ElkPoint) {
         Leadpoint {
            apply(Rumson) {
               Prosser {
                  if ((MoonRun.Haverford & 0x010000) == 0x010000) {
                     apply(Bendavis);
                  } else {
                     apply(Truro);
                  }
               }
            }
         }
      }
   }
}
action FourTown() {
   modify_field(Weyauwega.Pineville, 1);
   Canfield();
}
table Idalia {
   actions {
      FourTown;
   }
   default_action : FourTown;
   size : 1;
}
control Suffern {
   if (Weyauwega.BigPlain == 0) {
      if ((MoonRun.FlatRock==0) and (Weyauwega.Nichols==0) and (Weyauwega.Bayport==0) and (Weyauwega.Rosburg==MoonRun.Balmville)) {
         apply(Idalia);
      }
   }
}
action Findlay( Boring ) {
   modify_field( MoonRun.Luttrell, Boring );
}
action Steele() {
   modify_field( MoonRun.Luttrell, MoonRun.CruzBay );
}
table Tuscumbia {
   reads {
      eg_intr_md.egress_port : exact;
      MoonRun.CruzBay : exact;
   }
   actions {
      Findlay;
      Steele;
   }
   default_action : Steele;
   size : 4096;
}
control Fairlee {
   apply( Tuscumbia );
}
action McDavid( Reynolds, Ackerly ) {
   modify_field( MoonRun.Perdido, Reynolds );
   modify_field( MoonRun.Harpster, Ackerly );
}
action McCammon( Westboro, Corbin, Salamonia ) {
   modify_field( MoonRun.Perdido, Westboro );
   modify_field( MoonRun.Harpster, Corbin );
   modify_field( MoonRun.Armagh, Salamonia );
}
table Lucas {
   reads {
      MoonRun.Ivanhoe : exact;
   }
   actions {
      McDavid;
      McCammon;
   }
   size : 8;
}
action Halsey( Brinson ) {
   modify_field( MoonRun.Machens, 1 );
   modify_field( MoonRun.Ivanhoe, 2 );
   modify_field( MoonRun.Asher, Brinson );
}
table Evelyn {
   reads {
      eg_intr_md.egress_port : exact;
      Osman.Slagle : exact;
      MoonRun.Calumet : exact;
   }
   actions {
      Halsey;
   }
   default_action : Sigsbee();
   size : 16;
}
action BigPark(Slovan, Antoine, Servia, Broadmoor) {
   modify_field( MoonRun.McClure, Slovan );
   modify_field( MoonRun.Sherwin, Antoine );
   modify_field( MoonRun.Midas, Servia );
   modify_field( MoonRun.Towaoc, Broadmoor );
}
table Mackeys {
   reads {
        MoonRun.Sherando : exact;
   }
   actions {
      BigPark;
   }
   size : 512;
}
action Cahokia( Soledad ) {
   modify_field( MoonRun.Kempner, Soledad );
}
table Crump {
   reads {
      MoonRun.RockyGap mask 0x1FFFF : exact;
   }
   actions {
      Cahokia;
   }
   default_action : Cahokia(0);
   size : 4096;
}
action Belfast( Panola, Hackamore ) {
   modify_field( MoonRun.McCaulley, Panola );
   modify_field( MoonRun.Plata, Hackamore );
}
@pragma use_hash_action 1
table Vesuvius {
   reads {
      MoonRun.Vestaburg : exact;
   }
   actions {
      Belfast;
   }
   default_action : Belfast(0,0);
   size : 256;
}
action GlenAvon( Hillside ) {
   modify_field( MoonRun.Mattson, Hillside );
}
table Sudden {
   reads {
      MoonRun.CruzBay mask 0xFFF : exact;
   }
   actions {
      GlenAvon;
   }
   default_action : GlenAvon( 0 );
   size : 4096;
}
control Joyce {
   if( ( MoonRun.RockyGap & 0x20000 ) == 0 ) {
      apply( Crump );
   }
   if( MoonRun.Vestaburg != 0 ) {
      apply( Vesuvius );
   }
   apply( Sudden );
}
action Monetta() {
   no_op();
}
action Wimberley() {
   modify_field( Pecos.Harviell, Lebanon[0].Missoula );
   remove_header( Lebanon[0] );
}
table SantaAna {
   actions {
      Wimberley;
   }
   default_action : Wimberley;
   size : 1;
}
action Braymer() {
   no_op();
}
action Poynette() {
   add_header( Lebanon[ 0 ] );
   modify_field( Lebanon[0].Lincroft, MoonRun.Luttrell );
   modify_field( Lebanon[0].Missoula, Pecos.Harviell );
   modify_field( Lebanon[0].Renick, Charco.Littleton );
   modify_field( Lebanon[0].Schleswig, Charco.Marshall );
   modify_field( Pecos.Harviell, 0x8100 );
}
table RedBay {
   reads {
      MoonRun.Luttrell : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Braymer;
      Poynette;
   }
   default_action : Poynette;
   size : 128;
}
action Fieldon() {
   modify_field(Pecos.Energy, MoonRun.Haverford);
   modify_field(Pecos.Suwannee, MoonRun.Abbott);
   modify_field(Pecos.Sherack, MoonRun.Perdido);
   modify_field(Pecos.LoonLake, MoonRun.Harpster);
}
action Longford() {
   Fieldon();
   add_to_field(Easley.Separ, -1);
   modify_field(Easley.Pinole, Charco.Dairyland);
}
action Millbrook() {
   Fieldon();
   add_to_field(Eolia.Lizella, -1);
   modify_field(Eolia.ArchCape, Charco.Dairyland);
}
action Caspian() {
   modify_field(Easley.Pinole, Charco.Dairyland);
}
action Gardiner() {
   modify_field(Eolia.ArchCape, Charco.Dairyland);
}
action Gilliam() {
   Poynette();
}
action Loring( Albin, Clearlake, Hester, Udall ) {
   add_header( Pinesdale );
   modify_field( Pinesdale.Energy, Albin );
   modify_field( Pinesdale.Suwannee, Clearlake );
   modify_field( Pinesdale.Sherack, Hester );
   modify_field( Pinesdale.LoonLake, Udall );
   modify_field( Pinesdale.Harviell, 0xBF00 );
   add_header( Bratt );
   modify_field( Bratt.Kelso, MoonRun.McClure );
   modify_field( Bratt.Alburnett, MoonRun.Sherwin );
   modify_field( Bratt.Sanatoga, MoonRun.Midas );
   modify_field( Bratt.Everetts, MoonRun.Towaoc );
   modify_field( Bratt.Idylside, MoonRun.Coulee );
   modify_field( Bratt.Sugarloaf, Weyauwega.Alvordton );
   modify_field( Bratt.Donald, MoonRun.Asher );
}
action Oregon() {
   remove_header( Calcium );
   remove_header( Fairborn );
   remove_header( Kenefic );
   copy_header( Pecos, Ishpeming );
   remove_header( Ishpeming );
   remove_header( Easley );
}
action Anaconda() {
   remove_header( Pinesdale );
   remove_header( Bratt );
}
action Dolores() {
   Oregon();
   modify_field(Jarrell.Pinole, Charco.Dairyland);
}
action Hospers() {
   Oregon();
   modify_field(Alakanuk.ArchCape, Charco.Dairyland);
}
action Rampart( Rotterdam ) {
   modify_field( Jarrell.Ovilla, Easley.Ovilla );
   modify_field( Jarrell.TenSleep, Easley.TenSleep );
   modify_field( Jarrell.Pinole, Easley.Pinole );
   modify_field( Jarrell.Garlin, Easley.Garlin );
   modify_field( Jarrell.Kipahulu, Easley.Kipahulu );
   modify_field( Jarrell.WestPike, Easley.WestPike );
   modify_field( Jarrell.Satanta, Easley.Satanta );
   add( Jarrell.Separ, Easley.Separ, Rotterdam );
   modify_field( Jarrell.Lemhi, Easley.Lemhi );
   modify_field( Jarrell.Blackwood, Easley.Blackwood );
   modify_field( Jarrell.Stirrat, Easley.Stirrat );
   modify_field( Jarrell.Bains, Easley.Bains );
}
field_list Castle {
   Easley.Stirrat;
   Easley.Bains;
   Easley.Lemhi;
   MoonRun.Bangor;
}
field_list_calculation LaUnion {
    input {
       Castle;
    }
    algorithm : crc32;
    output_width : 16;
}
action Wayzata( Rexville ) {
   add_header( Ishpeming );
   add_header( Fairborn );
   add_header( Kenefic );
   add_header( Calcium );
   modify_field( Ishpeming.Energy, MoonRun.Haverford );
   modify_field( Ishpeming.Suwannee, MoonRun.Abbott );
   modify_field( Ishpeming.Sherack, Pecos.Sherack );
   modify_field( Ishpeming.LoonLake, Pecos.LoonLake );
   modify_field( Ishpeming.Harviell, Pecos.Harviell );
   add( Fairborn.Keokee, Easley.Kipahulu, 16 );
   modify_field( Fairborn.Leona, 0 );
   modify_field( Kenefic.Scarville, 4789 );
   modify_field_with_hash_based_offset( Kenefic.Nooksack, 0, Rexville, 16384 );
   modify_field( Calcium.Conneaut, 0x10 );
   modify_field( Calcium.Ronneby, MoonRun.Mattson );
   modify_field( Pecos.Energy, MoonRun.McCaulley );
   modify_field( Pecos.Suwannee, MoonRun.Plata );
   modify_field( Pecos.Sherack, MoonRun.Perdido );
   modify_field( Pecos.LoonLake, MoonRun.Harpster );
}
action Daguao() {
   add_header( Jarrell );
   Rampart( -1 );
   Wayzata( LaUnion );
   modify_field( Easley.Ovilla, 0x4 );
   modify_field( Easley.TenSleep, 0x5 );
   modify_field( Easley.Pinole, 0 );
   modify_field( Easley.Garlin, 0 );
   add_to_field( Easley.Kipahulu, 36 );
   modify_field( Easley.Maybell, eg_intr_md_from_parser_aux.egress_global_tstamp, 0xFFFF );
   modify_field( Easley.WestPike, 0 );
   modify_field( Easley.Satanta, 0 );
   modify_field( Easley.Separ, 64 );
   modify_field( Easley.Lemhi, 17 );
   modify_field( Easley.Stirrat, MoonRun.Armagh );
   modify_field( Easley.Bains, MoonRun.Kempner );
   modify_field( Pecos.Harviell, 0x0800 );
}
table Bloomburg {
   reads {
      MoonRun.RoseTree : exact;
      MoonRun.Ivanhoe : exact;
      MoonRun.FlatRock : exact;
      Easley.valid : ternary;
      Eolia.valid : ternary;
      Jarrell.valid : ternary;
      Alakanuk.valid : ternary;
   }
   actions {
      Longford;
      Millbrook;
      Caspian;
      Gardiner;
      Gilliam;
      Loring;
      Anaconda;
      Oregon;
      Dolores;
      Hospers;
      Daguao;
   }
   size : 512;
}
control Leawood {
   apply( SantaAna );
}
control NewTrier {
   apply( RedBay );
}
control Merritt {
   apply( Evelyn ) {
      Sigsbee {
         apply( Lucas );
      }
   }
   apply( Mackeys );
   apply( Bloomburg );
}
field_list Elysburg {
    Duchesne.Struthers;
    Weyauwega.Alvordton;
    Ishpeming.Sherack;
    Ishpeming.LoonLake;
    Easley.Stirrat;
}
action BirchBay() {
   generate_digest(0, Elysburg);
}
table Sanford {
   actions {
      BirchBay;
   }
   default_action : BirchBay;
   size : 1;
}
control Hayfork {
   if (Duchesne.Struthers == 2) {
      apply(Sanford);
   }
}
action Norma() {
   modify_field( Charco.Littleton, Osman.Chatfield );
}
action Zeeland() {
   modify_field( Charco.Littleton, Lebanon[0].Renick );
   modify_field( Weyauwega.Paxtonia, Lebanon[0].Missoula );
}
action Bettles() {
   modify_field( Charco.Dairyland, Osman.SanPablo );
}
action Chaumont() {
   modify_field( Charco.Dairyland, Grisdale.Forkville );
}
action Moylan() {
   modify_field( Charco.Dairyland, Wallula.Shelbina );
}
action ElRio( Lefors, Osseo ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Lefors );
   modify_field( ig_intr_md_for_tm.qid, Osseo );
}
table Chubbuck {
   reads {
     Weyauwega.Wheeler : exact;
   }
   actions {
     Norma;
     Zeeland;
   }
   size : 2;
}
table Tidewater {
   reads {
     Weyauwega.Colmar : exact;
     Weyauwega.Iberia : exact;
   }
   actions {
     Bettles;
     Chaumont;
     Moylan;
   }
   size : 3;
}
table Musella {
   reads {
      Osman.Ellisport : ternary;
      Osman.Chatfield : ternary;
      Charco.Littleton : ternary;
      Charco.Dairyland : ternary;
      Charco.Swedeborg : ternary;
   }
   actions {
      ElRio;
   }
   size : 81;
}
action DeerPark( Bratenahl, Samantha ) {
   bit_or( Charco.Sunbury, Charco.Sunbury, Bratenahl );
   bit_or( Charco.Westville, Charco.Westville, Samantha );
}
table Standish {
   actions {
      DeerPark;
   }
   default_action : DeerPark;
   size : 1;
}
action Edwards( Childs ) {
   modify_field( Charco.Dairyland, Childs );
}
action Peosta( Inkom ) {
   modify_field( Charco.Littleton, Inkom );
}
action Donna( Millston, Kingsgate ) {
   modify_field( Charco.Littleton, Millston );
   modify_field( Charco.Dairyland, Kingsgate );
}
table Higginson {
   reads {
      Osman.Ellisport : exact;
      Charco.Sunbury : exact;
      Charco.Westville : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Edwards;
      Peosta;
      Donna;
   }
   size : 512;
}
control Chappells {
   apply( Chubbuck );
   apply( Tidewater );
}
control Bigspring {
   apply( Musella );
}
control NeckCity {
   apply( Standish );
   apply( Higginson );
}
action Heron( Caroleen ) {
   modify_field( Charco.Eckman, Caroleen );
}
table FarrWest {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
   }
   actions {
      Heron;
   }
}
action Gotebo( Millport ) {
   modify_field( Charco.Weehawken, Millport );
}
table ShowLow {
   reads {
      Charco.Eckman : ternary;
      Weyauwega.Paxtonia : ternary;
      Weyauwega.Bayport : ternary;
      MoonRun.Abbott : ternary;
      MoonRun.Haverford : ternary;
      Willmar.Odessa : ternary;
   }
   actions {
      Gotebo;
   }
   default_action: Gotebo;
   size : 512;
}
table WindLake {
   reads {
      Charco.Eckman : ternary;
      Weyauwega.Colmar : ternary;
      Weyauwega.Iberia : ternary;
      Weyauwega.Bayport : ternary;
      Grisdale.Myoma : ternary;
      Wallula.Puryear mask 0xffff0000000000000000000000000000 : ternary;
      Weyauwega.Bozeman : ternary;
      Weyauwega.Salduro : ternary;
      MoonRun.FlatRock : ternary;
      Willmar.Odessa : ternary;
      Kenefic.Nooksack : ternary;
      Kenefic.Scarville : ternary;
   }
   actions {
      Gotebo;
   }
   default_action: Gotebo;
   size : 512;
}
meter Centre {
   type : packets;
   static : Westway;
   instance_count : 4096;
}
counter McFaddin {
   type : packets;
   static : Westway;
   instance_count : 4096;
   min_width : 64;
}
action Edesville(Kinston) {
   execute_meter( Centre, Kinston, ig_intr_md_for_tm.packet_color );
}
action Montague(Roberta) {
   count( McFaddin, Roberta );
}
action Amherst(Baker) {
   Edesville(Baker);
   Montague(Baker);
}
table Westway {
   reads {
      Charco.Eckman : exact;
      Charco.Weehawken : exact;
   }
   actions {
     Montague;
     Amherst;
   }
   size : 512;
}
control Palmdale {
   apply( FarrWest );
}
control Tanana {
      if ( ( Weyauwega.Colmar == 0 ) and ( Weyauwega.Iberia == 0 ) ) {
         apply( ShowLow );
      } else {
         apply( WindLake );
      }
}
control PineLake {
    if ( Weyauwega.BigPlain == 0 ) {
      apply( Westway );
   }
}
counter Rosalie {
   type : packets;
   direct : FordCity;
   min_width : 64;
}
action Temvik( Powderly, Venturia ) {
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Powderly );
   modify_field( MoonRun.Sherando, ig_intr_md.ingress_port );
   modify_field( ig_intr_md_for_tm.qid, Venturia );
}
action Elmhurst() {
   modify_field( MoonRun.Sherando, ig_intr_md.ingress_port );
}
action RyanPark( Stout, Fiskdale ) {
   Temvik( Stout, Fiskdale );
   modify_field( MoonRun.Calumet, 0);
}
action Montezuma() {
   Elmhurst();
   modify_field( MoonRun.Calumet, 0);
}
action Swansboro( Yemassee, Boerne ) {
   Temvik( Yemassee, Boerne );
   modify_field( MoonRun.Calumet, 1);
}
action Rozet() {
   Elmhurst();
   modify_field( MoonRun.Calumet, 1);
}
@pragma ternary 1
table FordCity {
   reads {
      MoonRun.McDonough : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      Lebanon[0] : valid;
      MoonRun.Coulee : ternary;
   }
   actions {
      RyanPark;
      Montezuma;
      Swansboro;
      Rozet;
   }
   default_action : Sigsbee();
   size : 512;
}
control Dwight {
   apply( FordCity ) {
      RyanPark {
      }
      Swansboro {
      }
      default {
         Candle();
      }
   }
}
counter Aripine {
   type : packets_and_bytes;
   instance_count : 1024;
   min_width : 128;
}
action DuBois( Anselmo ) {
   count( Aripine, Anselmo );
}
table Ayden {
   reads {
      eg_intr_md.egress_port mask 0x7f: exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }
   actions {
     DuBois;
   }
   size : 1024;
}
control Catarina {
   apply( Ayden );
}
action Kalskag()
{
   Canfield();
}
action Mammoth() {
   modify_field(MoonRun.RoseTree, 3);
}
action Lordstown()
{
   modify_field(MoonRun.RoseTree, 2);
   bit_or(MoonRun.Balmville, 0x3C00, Bratt.Everetts);
}
action Shopville( Kountze ) {
   modify_field(MoonRun.RoseTree, 2);
   modify_field(MoonRun.Balmville, Kountze);
}
table Sagerton {
   reads {
      Bratt.Kelso : exact;
      Bratt.Alburnett : exact;
      Bratt.Sanatoga : exact;
      Bratt.Everetts : exact;
   }
   actions {
      Lordstown;
      Shopville;
      Mammoth;
      Kalskag;
   }
   default_action : Kalskag();
   size : 512;
}
control Grampian {
   apply( Sagerton );
}
action McGovern( Goodlett, Kekoskee, Thatcher, Kaplan ) {
   modify_field( Gurley.Earlham, Goodlett );
   modify_field( Robstown.PawCreek, Thatcher );
   modify_field( Robstown.Bairoa, Kekoskee );
   modify_field( Robstown.Seguin, Kaplan );
}
table Jonesport {
   reads {
     Grisdale.Myoma : exact;
     Weyauwega.Goldsmith : exact;
   }
   actions {
      McGovern;
   }
  size : 16384;
}
action Pachuta(Wapato, BigPoint, Pelland) {
   modify_field( Robstown.Bairoa, Wapato );
   modify_field( Robstown.PawCreek, BigPoint );
   modify_field( Robstown.Seguin, Pelland );
}
table Arredondo {
   reads {
     Grisdale.Leoma : exact;
     Gurley.Earlham : exact;
   }
   actions {
      Pachuta;
   }
   size : 16384;
}
action Allison( Munger, Gurdon, Amasa ) {
   modify_field( Newcastle.Portis, Munger );
   modify_field( Newcastle.Ellicott, Gurdon );
   modify_field( Newcastle.EastLake, Amasa );
}
table Comunas {
   reads {
     MoonRun.Haverford : exact;
     MoonRun.Abbott : exact;
     MoonRun.CruzBay : exact;
   }
   actions {
      Allison;
   }
   size : 16384;
}
action Cowden() {
   modify_field( MoonRun.Riverbank, 1 );
}
action Advance( Lonepine ) {
   Cowden();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Robstown.Bairoa );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Lonepine, Robstown.Seguin );
}
action Taylors( Stowe ) {
   Cowden();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Newcastle.Portis );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Stowe, Newcastle.EastLake );
}
action Fairhaven( Steprock ) {
   Cowden();
   add( ig_intr_md_for_tm.mcast_grp_a, MoonRun.CruzBay,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Steprock );
}
action Mullins() {
   modify_field( MoonRun.GilaBend, 1 );
}
table Parker {
   reads {
     Robstown.PawCreek : ternary;
     Robstown.Bairoa : ternary;
     Newcastle.Portis : ternary;
     Newcastle.Ellicott : ternary;
     Weyauwega.Bozeman :ternary;
     Weyauwega.Nichols:ternary;
   }
   actions {
      Advance;
      Taylors;
      Fairhaven;
      Mullins;
   }
   size : 32;
}
control Redden {
   if( Weyauwega.BigPlain == 0 and
       ( ( Biscay.Alstown & ( 0x4 ) ) == ( ( 0x4 ) ) ) and
       Weyauwega.Callao == 1 ) {
      apply( Jonesport );
   }
}
control Fouke {
   if( Gurley.Earlham != 0 ) {
      apply( Arredondo );
   }
}
control Etter {
   if( Weyauwega.BigPlain == 0 and Weyauwega.Nichols==1 ) {
      apply( Comunas );
   }
}
control Klukwan {
   if( Weyauwega.Nichols == 1 ) {
      apply(Parker);
   }
}
action Ballville(Stratton) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Lazear.Sheldahl );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Stratton );
}
table Garrison {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Ballville;
    }
    size : 512;
}
control Raytown {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Garrison);
   }
}
action Tahlequah( Millbrae, Roggen, Gladstone ) {
   modify_field( MoonRun.CruzBay, Millbrae );
   modify_field( MoonRun.FlatRock, Roggen );
   bit_or( eg_intr_md_for_oport.drop_ctl, eg_intr_md_for_oport.drop_ctl, Gladstone );
}
@pragma use_hash_action 1
table Denning {
   reads {
     eg_intr_md.egress_rid: exact;
   }
   actions {
      Tahlequah;
   }
   default_action: Tahlequah( 0, 0, 1 );
   size : 65536;
}
control Cedonia {
   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Denning);
   }
}
counter Stone {
   type : packets;
   direct: Branson;
   min_width: 63;
}
@pragma stage 11
table Branson {
   reads {
     Salix.Omemee mask 0x7fff : exact;
   }
   actions {
      Sigsbee;
   }
   default_action: Sigsbee();
   size : 32768;
}
action Wyncote() {
   modify_field( Minoa.Accord, Weyauwega.Bozeman );
   modify_field( Minoa.Milam, Grisdale.Forkville );
   modify_field( Minoa.Fitler, Weyauwega.Salduro );
   modify_field( Minoa.Bosco, Weyauwega.Moseley );
}
action Verdemont() {
   modify_field( Minoa.Accord, Weyauwega.Bozeman );
   modify_field( Minoa.Milam, Wallula.Shelbina );
   modify_field( Minoa.Fitler, Weyauwega.Salduro );
   modify_field( Minoa.Bosco, Weyauwega.Moseley );
}
action Exton( Monowi ) {
   Wyncote();
   modify_field( Minoa.Rocky, Monowi );
}
action Hibernia( Millwood ) {
   Verdemont();
   modify_field( Minoa.Rocky, Millwood );
}
table Dialville {
   reads {
     Grisdale.Leoma : ternary;
   }
   actions {
      Exton;
   }
   default_action : Wyncote;
  size : 2048;
}
table Chatanika {
   reads {
     Wallula.CityView : ternary;
   }
   actions {
      Hibernia;
   }
   default_action : Verdemont;
   size : 1024;
}
action Eaton( Dovray ) {
   modify_field( Minoa.Komatke, Dovray );
}
table Weiser {
   reads {
     Grisdale.Myoma : ternary;
   }
   actions {
      Eaton;
   }
   size : 512;
}
table Lanesboro {
   reads {
     Wallula.Puryear : ternary;
   }
   actions {
      Eaton;
   }
   size : 512;
}
action Cowell( Amonate ) {
   modify_field( Minoa.Caban, Amonate );
}
table Union {
   reads {
     Weyauwega.Morgana : ternary;
   }
   actions {
      Cowell;
   }
   size : 512;
}
action Sherrill( Tununak ) {
   modify_field( Minoa.VanHorn, Tununak );
}
table LeeCity {
   reads {
     Weyauwega.Cathcart : ternary;
   }
   actions {
      Sherrill;
   }
   size : 512;
}
action Picabo( Lovewell ) {
   modify_field( Minoa.DeepGap, Lovewell );
}
action GlenArm( Brookland ) {
   modify_field( Minoa.DeepGap, Brookland );
}
table Tunis {
   reads {
     Weyauwega.Colmar : exact;
     Weyauwega.Iberia : exact;
     Weyauwega.Stidham mask 4 : exact;
     Weyauwega.Goldsmith : exact;
   }
   actions {
      Picabo;
      Sigsbee;
   }
   default_action : Sigsbee();
   size : 4096;
}
table Frankfort {
   reads {
     Weyauwega.Colmar : exact;
     Weyauwega.Iberia : exact;
     Weyauwega.Stidham mask 4 : exact;
     Osman.Devola : exact;
   }
   actions {
      GlenArm;
   }
   size : 512;
}
control Lolita {
   if( Weyauwega.Colmar == 1 ) {
      apply( Dialville );
      apply( Weiser );
   } else if( Weyauwega.Iberia == 1 ) {
      apply( Chatanika );
      apply( Lanesboro );
   }
   if( ( Weyauwega.Stidham & 2 ) == 2 ) {
      apply( Union );
      apply( LeeCity );
   }
   apply( Tunis ) {
      Sigsbee {
         apply( Frankfort );
      }
   }
}
action Belmond() {
}
action Syria() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action Chehalis() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
}
action Dasher() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
table Daniels {
   reads {
     Salix.Omemee mask 0x00018000 : ternary;
   }
   actions {
      Belmond;
      Syria;
      Chehalis;
      Dasher;
   }
   size : 16;
}
control Timken {
   apply( Daniels );
   apply( Branson );
}
   metadata Rapids Salix;
   action Escondido( Goodrich ) {
          max( Salix.Omemee, Salix.Omemee, Goodrich );
   }
@pragma ways 4
table Dickson {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : exact;
      Minoa.Komatke : exact;
      Minoa.Caban : exact;
      Minoa.VanHorn : exact;
      Minoa.Accord : exact;
      Minoa.Milam : exact;
      Minoa.Fitler : exact;
      Minoa.Bosco : exact;
      Minoa.Oroville : exact;
   }
   actions {
      Escondido;
   }
   size : 4096;
}
control Ferndale {
   apply( Dickson );
}
table Rochert {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : ternary;
      Minoa.Komatke : ternary;
      Minoa.Caban : ternary;
      Minoa.VanHorn : ternary;
      Minoa.Accord : ternary;
      Minoa.Milam : ternary;
      Minoa.Fitler : ternary;
      Minoa.Bosco : ternary;
      Minoa.Oroville : ternary;
   }
   actions {
      Escondido;
   }
   size : 512;
}
control Mackey {
   apply( Rochert );
}
@pragma pa_no_init ingress Mackville.Rocky
@pragma pa_no_init ingress Mackville.Komatke
@pragma pa_no_init ingress Mackville.Caban
@pragma pa_no_init ingress Mackville.VanHorn
@pragma pa_no_init ingress Mackville.Accord
@pragma pa_no_init ingress Mackville.Milam
@pragma pa_no_init ingress Mackville.Fitler
@pragma pa_no_init ingress Mackville.Bosco
@pragma pa_no_init ingress Mackville.Oroville
metadata Eddystone Mackville;
@pragma ways 4
table Longville {
   reads {
      Minoa.DeepGap : exact;
      Mackville.Rocky : exact;
      Mackville.Komatke : exact;
      Mackville.Caban : exact;
      Mackville.VanHorn : exact;
      Mackville.Accord : exact;
      Mackville.Milam : exact;
      Mackville.Fitler : exact;
      Mackville.Bosco : exact;
      Mackville.Oroville : exact;
   }
   actions {
      Escondido;
   }
   size : 8192;
}
action Sabana( Angle, Lindy, Hartford, Youngtown, Jenifer, Carnero, Rockfield, Brinkman, Lafourche ) {
   bit_and( Mackville.Rocky, Minoa.Rocky, Angle );
   bit_and( Mackville.Komatke, Minoa.Komatke, Lindy );
   bit_and( Mackville.Caban, Minoa.Caban, Hartford );
   bit_and( Mackville.VanHorn, Minoa.VanHorn, Youngtown );
   bit_and( Mackville.Accord, Minoa.Accord, Jenifer );
   bit_and( Mackville.Milam, Minoa.Milam, Carnero );
   bit_and( Mackville.Fitler, Minoa.Fitler, Rockfield );
   bit_and( Mackville.Bosco, Minoa.Bosco, Brinkman );
   bit_and( Mackville.Oroville, Minoa.Oroville, Lafourche );
}
table Ravinia {
   reads {
      Minoa.DeepGap : exact;
   }
   actions {
      Sabana;
   }
   default_action : Sabana(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Topawa {
   apply( Ravinia );
}
control Palmhurst {
   apply( Longville );
}
table Jacobs {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : ternary;
      Minoa.Komatke : ternary;
      Minoa.Caban : ternary;
      Minoa.VanHorn : ternary;
      Minoa.Accord : ternary;
      Minoa.Milam : ternary;
      Minoa.Fitler : ternary;
      Minoa.Bosco : ternary;
      Minoa.Oroville : ternary;
   }
   actions {
      Escondido;
   }
   size : 512;
}
control Luning {
   apply( Jacobs );
}
@pragma ways 4
table Cascade {
   reads {
      Minoa.DeepGap : exact;
      Mackville.Rocky : exact;
      Mackville.Komatke : exact;
      Mackville.Caban : exact;
      Mackville.VanHorn : exact;
      Mackville.Accord : exact;
      Mackville.Milam : exact;
      Mackville.Fitler : exact;
      Mackville.Bosco : exact;
      Mackville.Oroville : exact;
   }
   actions {
      Escondido;
   }
   size : 4096;
}
action Uniontown( Kelsey, Humeston, Hammonton, Samson, Cadley, Holliston, Wyarno, Finney, English ) {
   bit_and( Mackville.Rocky, Minoa.Rocky, Kelsey );
   bit_and( Mackville.Komatke, Minoa.Komatke, Humeston );
   bit_and( Mackville.Caban, Minoa.Caban, Hammonton );
   bit_and( Mackville.VanHorn, Minoa.VanHorn, Samson );
   bit_and( Mackville.Accord, Minoa.Accord, Cadley );
   bit_and( Mackville.Milam, Minoa.Milam, Holliston );
   bit_and( Mackville.Fitler, Minoa.Fitler, Wyarno );
   bit_and( Mackville.Bosco, Minoa.Bosco, Finney );
   bit_and( Mackville.Oroville, Minoa.Oroville, English );
}
table McCune {
   reads {
      Minoa.DeepGap : exact;
   }
   actions {
      Uniontown;
   }
   default_action : Uniontown(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Topsfield {
   apply( McCune );
}
control Verdery {
   apply( Cascade );
}
table Casnovia {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : ternary;
      Minoa.Komatke : ternary;
      Minoa.Caban : ternary;
      Minoa.VanHorn : ternary;
      Minoa.Accord : ternary;
      Minoa.Milam : ternary;
      Minoa.Fitler : ternary;
      Minoa.Bosco : ternary;
      Minoa.Oroville : ternary;
   }
   actions {
      Escondido;
   }
   size : 512;
}
control Eveleth {
   apply( Casnovia );
}
@pragma ways 4
table Kettering {
   reads {
      Minoa.DeepGap : exact;
      Mackville.Rocky : exact;
      Mackville.Komatke : exact;
      Mackville.Caban : exact;
      Mackville.VanHorn : exact;
      Mackville.Accord : exact;
      Mackville.Milam : exact;
      Mackville.Fitler : exact;
      Mackville.Bosco : exact;
      Mackville.Oroville : exact;
   }
   actions {
      Escondido;
   }
   size : 4096;
}
action Wailuku( Ardara, Alabaster, Barrow, Aldrich, Wyndmere, Horsehead, Belwood, Ephesus, Ronan ) {
   bit_and( Mackville.Rocky, Minoa.Rocky, Ardara );
   bit_and( Mackville.Komatke, Minoa.Komatke, Alabaster );
   bit_and( Mackville.Caban, Minoa.Caban, Barrow );
   bit_and( Mackville.VanHorn, Minoa.VanHorn, Aldrich );
   bit_and( Mackville.Accord, Minoa.Accord, Wyndmere );
   bit_and( Mackville.Milam, Minoa.Milam, Horsehead );
   bit_and( Mackville.Fitler, Minoa.Fitler, Belwood );
   bit_and( Mackville.Bosco, Minoa.Bosco, Ephesus );
   bit_and( Mackville.Oroville, Minoa.Oroville, Ronan );
}
table Piperton {
   reads {
      Minoa.DeepGap : exact;
   }
   actions {
      Wailuku;
   }
   default_action : Wailuku(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Heads {
   apply( Piperton );
}
control Claypool {
   apply( Kettering );
}
table Pioche {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : ternary;
      Minoa.Komatke : ternary;
      Minoa.Caban : ternary;
      Minoa.VanHorn : ternary;
      Minoa.Accord : ternary;
      Minoa.Milam : ternary;
      Minoa.Fitler : ternary;
      Minoa.Bosco : ternary;
      Minoa.Oroville : ternary;
   }
   actions {
      Escondido;
   }
   size : 512;
}
control Laton {
   apply( Pioche );
}
@pragma ways 4
table Leonore {
   reads {
      Minoa.DeepGap : exact;
      Mackville.Rocky : exact;
      Mackville.Komatke : exact;
      Mackville.Caban : exact;
      Mackville.VanHorn : exact;
      Mackville.Accord : exact;
      Mackville.Milam : exact;
      Mackville.Fitler : exact;
      Mackville.Bosco : exact;
      Mackville.Oroville : exact;
   }
   actions {
      Escondido;
   }
   size : 8192;
}
action Point( JaneLew, Tahuya, Parmelee, Downs, Dubuque, Cassa, Lakefield, Grannis, Elderon ) {
   bit_and( Mackville.Rocky, Minoa.Rocky, JaneLew );
   bit_and( Mackville.Komatke, Minoa.Komatke, Tahuya );
   bit_and( Mackville.Caban, Minoa.Caban, Parmelee );
   bit_and( Mackville.VanHorn, Minoa.VanHorn, Downs );
   bit_and( Mackville.Accord, Minoa.Accord, Dubuque );
   bit_and( Mackville.Milam, Minoa.Milam, Cassa );
   bit_and( Mackville.Fitler, Minoa.Fitler, Lakefield );
   bit_and( Mackville.Bosco, Minoa.Bosco, Grannis );
   bit_and( Mackville.Oroville, Minoa.Oroville, Elderon );
}
table Elbert {
   reads {
      Minoa.DeepGap : exact;
   }
   actions {
      Point;
   }
   default_action : Point(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Magazine {
   apply( Elbert );
}
control Fairchild {
   apply( Leonore );
}
table Pidcoke {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : ternary;
      Minoa.Komatke : ternary;
      Minoa.Caban : ternary;
      Minoa.VanHorn : ternary;
      Minoa.Accord : ternary;
      Minoa.Milam : ternary;
      Minoa.Fitler : ternary;
      Minoa.Bosco : ternary;
      Minoa.Oroville : ternary;
   }
   actions {
      Escondido;
   }
   size : 512;
}
control Muenster {
   apply( Pidcoke );
}
@pragma ways 4
table Carmel {
   reads {
      Minoa.DeepGap : exact;
      Mackville.Rocky : exact;
      Mackville.Komatke : exact;
      Mackville.Caban : exact;
      Mackville.VanHorn : exact;
      Mackville.Accord : exact;
      Mackville.Milam : exact;
      Mackville.Fitler : exact;
      Mackville.Bosco : exact;
      Mackville.Oroville : exact;
   }
   actions {
      Escondido;
   }
   size : 8192;
}
action Shongaloo( Mendoza, Aylmer, Sabula, Kokadjo, Aurora, Oakridge, Lenoir, Orosi, Marvin ) {
   bit_and( Mackville.Rocky, Minoa.Rocky, Mendoza );
   bit_and( Mackville.Komatke, Minoa.Komatke, Aylmer );
   bit_and( Mackville.Caban, Minoa.Caban, Sabula );
   bit_and( Mackville.VanHorn, Minoa.VanHorn, Kokadjo );
   bit_and( Mackville.Accord, Minoa.Accord, Aurora );
   bit_and( Mackville.Milam, Minoa.Milam, Oakridge );
   bit_and( Mackville.Fitler, Minoa.Fitler, Lenoir );
   bit_and( Mackville.Bosco, Minoa.Bosco, Orosi );
   bit_and( Mackville.Oroville, Minoa.Oroville, Marvin );
}
table Masardis {
   reads {
      Minoa.DeepGap : exact;
   }
   actions {
      Shongaloo;
   }
   default_action : Shongaloo(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Cleator {
   apply( Masardis );
}
control Maddock {
   apply( Carmel );
}
table Kempton {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : ternary;
      Minoa.Komatke : ternary;
      Minoa.Caban : ternary;
      Minoa.VanHorn : ternary;
      Minoa.Accord : ternary;
      Minoa.Milam : ternary;
      Minoa.Fitler : ternary;
      Minoa.Bosco : ternary;
      Minoa.Oroville : ternary;
   }
   actions {
      Escondido;
   }
   size : 512;
}
control Careywood {
   apply( Kempton );
}
@pragma ways 4
table Lehigh {
   reads {
      Minoa.DeepGap : exact;
      Mackville.Rocky : exact;
      Mackville.Komatke : exact;
      Mackville.Caban : exact;
      Mackville.VanHorn : exact;
      Mackville.Accord : exact;
      Mackville.Milam : exact;
      Mackville.Fitler : exact;
      Mackville.Bosco : exact;
      Mackville.Oroville : exact;
   }
   actions {
      Escondido;
   }
   size : 4096;
}
action Tocito( Nambe, Roseville, Ardsley, Waxhaw, Paxico, Alamance, Platea, Ashtola, Bayne ) {
   bit_and( Mackville.Rocky, Minoa.Rocky, Nambe );
   bit_and( Mackville.Komatke, Minoa.Komatke, Roseville );
   bit_and( Mackville.Caban, Minoa.Caban, Ardsley );
   bit_and( Mackville.VanHorn, Minoa.VanHorn, Waxhaw );
   bit_and( Mackville.Accord, Minoa.Accord, Paxico );
   bit_and( Mackville.Milam, Minoa.Milam, Alamance );
   bit_and( Mackville.Fitler, Minoa.Fitler, Platea );
   bit_and( Mackville.Bosco, Minoa.Bosco, Ashtola );
   bit_and( Mackville.Oroville, Minoa.Oroville, Bayne );
}
table Wilbraham {
   reads {
      Minoa.DeepGap : exact;
   }
   actions {
      Tocito;
   }
   default_action : Tocito(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Canalou {
   apply( Wilbraham );
}
control Maybee {
   apply( Lehigh );
}
table LoneJack {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : ternary;
      Minoa.Komatke : ternary;
      Minoa.Caban : ternary;
      Minoa.VanHorn : ternary;
      Minoa.Accord : ternary;
      Minoa.Milam : ternary;
      Minoa.Fitler : ternary;
      Minoa.Bosco : ternary;
      Minoa.Oroville : ternary;
   }
   actions {
      Escondido;
   }
   size : 512;
}
control Meyers {
   apply( LoneJack );
}
@pragma ways 4
table McCartys {
   reads {
      Minoa.DeepGap : exact;
      Mackville.Rocky : exact;
      Mackville.Komatke : exact;
      Mackville.Caban : exact;
      Mackville.VanHorn : exact;
      Mackville.Accord : exact;
      Mackville.Milam : exact;
      Mackville.Fitler : exact;
      Mackville.Bosco : exact;
      Mackville.Oroville : exact;
   }
   actions {
      Escondido;
   }
   size : 4096;
}
action Muncie( Herod, Selawik, Rockleigh, Challis, Spanaway, Maytown, Gilliatt, Emsworth, Sprout ) {
   bit_and( Mackville.Rocky, Minoa.Rocky, Herod );
   bit_and( Mackville.Komatke, Minoa.Komatke, Selawik );
   bit_and( Mackville.Caban, Minoa.Caban, Rockleigh );
   bit_and( Mackville.VanHorn, Minoa.VanHorn, Challis );
   bit_and( Mackville.Accord, Minoa.Accord, Spanaway );
   bit_and( Mackville.Milam, Minoa.Milam, Maytown );
   bit_and( Mackville.Fitler, Minoa.Fitler, Gilliatt );
   bit_and( Mackville.Bosco, Minoa.Bosco, Emsworth );
   bit_and( Mackville.Oroville, Minoa.Oroville, Sprout );
}
table Millsboro {
   reads {
      Minoa.DeepGap : exact;
   }
   actions {
      Muncie;
   }
   default_action : Muncie(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Croft {
   apply( Millsboro );
}
control Moultrie {
   apply( McCartys );
}
table Slana {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : ternary;
      Minoa.Komatke : ternary;
      Minoa.Caban : ternary;
      Minoa.VanHorn : ternary;
      Minoa.Accord : ternary;
      Minoa.Milam : ternary;
      Minoa.Fitler : ternary;
      Minoa.Bosco : ternary;
      Minoa.Oroville : ternary;
   }
   actions {
      Escondido;
   }
   size : 512;
}
control Wattsburg {
   apply( Slana );
}
   metadata Rapids Gotham;
   action Ridgewood( Perkasie ) {
          max( Gotham.Omemee, Gotham.Omemee, Perkasie );
   }
   action Lawnside() { max( Salix.Omemee, Gotham.Omemee, Salix.Omemee ); } table Skyforest { actions { Lawnside; } default_action : Lawnside; size : 1; } control Hitterdal { apply( Skyforest ); }
@pragma ways 4
table Eastwood {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : exact;
      Minoa.Komatke : exact;
      Minoa.Caban : exact;
      Minoa.VanHorn : exact;
      Minoa.Accord : exact;
      Minoa.Milam : exact;
      Minoa.Fitler : exact;
      Minoa.Bosco : exact;
      Minoa.Oroville : exact;
   }
   actions {
      Ridgewood;
   }
   size : 4096;
}
control Gamewell {
   apply( Eastwood );
}
table Norridge {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : ternary;
      Minoa.Komatke : ternary;
      Minoa.Caban : ternary;
      Minoa.VanHorn : ternary;
      Minoa.Accord : ternary;
      Minoa.Milam : ternary;
      Minoa.Fitler : ternary;
      Minoa.Bosco : ternary;
      Minoa.Oroville : ternary;
   }
   actions {
      Ridgewood;
   }
   size : 4096;
}
control Monsey {
   apply( Norridge );
}
@pragma pa_no_init ingress Haworth.Rocky
@pragma pa_no_init ingress Haworth.Komatke
@pragma pa_no_init ingress Haworth.Caban
@pragma pa_no_init ingress Haworth.VanHorn
@pragma pa_no_init ingress Haworth.Accord
@pragma pa_no_init ingress Haworth.Milam
@pragma pa_no_init ingress Haworth.Fitler
@pragma pa_no_init ingress Haworth.Bosco
@pragma pa_no_init ingress Haworth.Oroville
metadata Eddystone Haworth;
@pragma ways 4
table Tappan {
   reads {
      Minoa.DeepGap : exact;
      Haworth.Rocky : exact;
      Haworth.Komatke : exact;
      Haworth.Caban : exact;
      Haworth.VanHorn : exact;
      Haworth.Accord : exact;
      Haworth.Milam : exact;
      Haworth.Fitler : exact;
      Haworth.Bosco : exact;
      Haworth.Oroville : exact;
   }
   actions {
      Ridgewood;
   }
   size : 4096;
}
action Otego( Tulia, Giltner, Burmah, Slayden, Whiteclay, Trujillo, Magna, Kranzburg, Cricket ) {
   bit_and( Haworth.Rocky, Minoa.Rocky, Tulia );
   bit_and( Haworth.Komatke, Minoa.Komatke, Giltner );
   bit_and( Haworth.Caban, Minoa.Caban, Burmah );
   bit_and( Haworth.VanHorn, Minoa.VanHorn, Slayden );
   bit_and( Haworth.Accord, Minoa.Accord, Whiteclay );
   bit_and( Haworth.Milam, Minoa.Milam, Trujillo );
   bit_and( Haworth.Fitler, Minoa.Fitler, Magna );
   bit_and( Haworth.Bosco, Minoa.Bosco, Kranzburg );
   bit_and( Haworth.Oroville, Minoa.Oroville, Cricket );
}
table Norbeck {
   reads {
      Minoa.DeepGap : exact;
   }
   actions {
      Otego;
   }
   default_action : Otego(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Everest {
   apply( Norbeck );
}
control Oakes {
   apply( Tappan );
}
table Safford {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : ternary;
      Minoa.Komatke : ternary;
      Minoa.Caban : ternary;
      Minoa.VanHorn : ternary;
      Minoa.Accord : ternary;
      Minoa.Milam : ternary;
      Minoa.Fitler : ternary;
      Minoa.Bosco : ternary;
      Minoa.Oroville : ternary;
   }
   actions {
      Ridgewood;
   }
   size : 512;
}
control Markville {
   apply( Safford );
}
@pragma ways 4
table Kosmos {
   reads {
      Minoa.DeepGap : exact;
      Haworth.Rocky : exact;
      Haworth.Komatke : exact;
      Haworth.Caban : exact;
      Haworth.VanHorn : exact;
      Haworth.Accord : exact;
      Haworth.Milam : exact;
      Haworth.Fitler : exact;
      Haworth.Bosco : exact;
      Haworth.Oroville : exact;
   }
   actions {
      Ridgewood;
   }
   size : 4096;
}
action Hanamaulu( Galestown, Sixteen, Tuttle, Kaanapali, Elkville, Moraine, Olive, Bemis, Allerton ) {
   bit_and( Haworth.Rocky, Minoa.Rocky, Galestown );
   bit_and( Haworth.Komatke, Minoa.Komatke, Sixteen );
   bit_and( Haworth.Caban, Minoa.Caban, Tuttle );
   bit_and( Haworth.VanHorn, Minoa.VanHorn, Kaanapali );
   bit_and( Haworth.Accord, Minoa.Accord, Elkville );
   bit_and( Haworth.Milam, Minoa.Milam, Moraine );
   bit_and( Haworth.Fitler, Minoa.Fitler, Olive );
   bit_and( Haworth.Bosco, Minoa.Bosco, Bemis );
   bit_and( Haworth.Oroville, Minoa.Oroville, Allerton );
}
table Taneytown {
   reads {
      Minoa.DeepGap : exact;
   }
   actions {
      Hanamaulu;
   }
   default_action : Hanamaulu(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Kinney {
   apply( Taneytown );
}
control Cropper {
   apply( Kosmos );
}
table Algonquin {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : ternary;
      Minoa.Komatke : ternary;
      Minoa.Caban : ternary;
      Minoa.VanHorn : ternary;
      Minoa.Accord : ternary;
      Minoa.Milam : ternary;
      Minoa.Fitler : ternary;
      Minoa.Bosco : ternary;
      Minoa.Oroville : ternary;
   }
   actions {
      Ridgewood;
   }
   size : 512;
}
control Candor {
   apply( Algonquin );
}
@pragma ways 4
table Kapalua {
   reads {
      Minoa.DeepGap : exact;
      Haworth.Rocky : exact;
      Haworth.Komatke : exact;
      Haworth.Caban : exact;
      Haworth.VanHorn : exact;
      Haworth.Accord : exact;
      Haworth.Milam : exact;
      Haworth.Fitler : exact;
      Haworth.Bosco : exact;
      Haworth.Oroville : exact;
   }
   actions {
      Ridgewood;
   }
   size : 4096;
}
action Flippen( Caballo, Ridgetop, Sandston, Coconino, Calabasas, Longwood, Elsey, Idabel, Cement ) {
   bit_and( Haworth.Rocky, Minoa.Rocky, Caballo );
   bit_and( Haworth.Komatke, Minoa.Komatke, Ridgetop );
   bit_and( Haworth.Caban, Minoa.Caban, Sandston );
   bit_and( Haworth.VanHorn, Minoa.VanHorn, Coconino );
   bit_and( Haworth.Accord, Minoa.Accord, Calabasas );
   bit_and( Haworth.Milam, Minoa.Milam, Longwood );
   bit_and( Haworth.Fitler, Minoa.Fitler, Elsey );
   bit_and( Haworth.Bosco, Minoa.Bosco, Idabel );
   bit_and( Haworth.Oroville, Minoa.Oroville, Cement );
}
table Washoe {
   reads {
      Minoa.DeepGap : exact;
   }
   actions {
      Flippen;
   }
   default_action : Flippen(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Talkeetna {
   apply( Washoe );
}
control WestLawn {
   apply( Kapalua );
}
table Weinert {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : ternary;
      Minoa.Komatke : ternary;
      Minoa.Caban : ternary;
      Minoa.VanHorn : ternary;
      Minoa.Accord : ternary;
      Minoa.Milam : ternary;
      Minoa.Fitler : ternary;
      Minoa.Bosco : ternary;
      Minoa.Oroville : ternary;
   }
   actions {
      Ridgewood;
   }
   size : 512;
}
control Halley {
   apply( Weinert );
}
@pragma ways 4
table Astor {
   reads {
      Minoa.DeepGap : exact;
      Haworth.Rocky : exact;
      Haworth.Komatke : exact;
      Haworth.Caban : exact;
      Haworth.VanHorn : exact;
      Haworth.Accord : exact;
      Haworth.Milam : exact;
      Haworth.Fitler : exact;
      Haworth.Bosco : exact;
      Haworth.Oroville : exact;
   }
   actions {
      Ridgewood;
   }
   size : 4096;
}
action Fragaria( Emmet, Cardenas, Lauada, Tamms, Blanding, Vallejo, BigRiver, Grandy, Honobia ) {
   bit_and( Haworth.Rocky, Minoa.Rocky, Emmet );
   bit_and( Haworth.Komatke, Minoa.Komatke, Cardenas );
   bit_and( Haworth.Caban, Minoa.Caban, Lauada );
   bit_and( Haworth.VanHorn, Minoa.VanHorn, Tamms );
   bit_and( Haworth.Accord, Minoa.Accord, Blanding );
   bit_and( Haworth.Milam, Minoa.Milam, Vallejo );
   bit_and( Haworth.Fitler, Minoa.Fitler, BigRiver );
   bit_and( Haworth.Bosco, Minoa.Bosco, Grandy );
   bit_and( Haworth.Oroville, Minoa.Oroville, Honobia );
}
table Milwaukie {
   reads {
      Minoa.DeepGap : exact;
   }
   actions {
      Fragaria;
   }
   default_action : Fragaria(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Bluford {
   apply( Milwaukie );
}
control Lenexa {
   apply( Astor );
}
table Emida {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : ternary;
      Minoa.Komatke : ternary;
      Minoa.Caban : ternary;
      Minoa.VanHorn : ternary;
      Minoa.Accord : ternary;
      Minoa.Milam : ternary;
      Minoa.Fitler : ternary;
      Minoa.Bosco : ternary;
      Minoa.Oroville : ternary;
   }
   actions {
      Ridgewood;
   }
   size : 512;
}
control Mango {
   apply( Emida );
}
@pragma ways 4
table Fernway {
   reads {
      Minoa.DeepGap : exact;
      Haworth.Rocky : exact;
      Haworth.Komatke : exact;
      Haworth.Caban : exact;
      Haworth.VanHorn : exact;
      Haworth.Accord : exact;
      Haworth.Milam : exact;
      Haworth.Fitler : exact;
      Haworth.Bosco : exact;
      Haworth.Oroville : exact;
   }
   actions {
      Ridgewood;
   }
   size : 4096;
}
action Honuapo( RossFork, Risco, Knights, Ririe, Brinklow, Gheen, Tusayan, Waimalu, Casselman ) {
   bit_and( Haworth.Rocky, Minoa.Rocky, RossFork );
   bit_and( Haworth.Komatke, Minoa.Komatke, Risco );
   bit_and( Haworth.Caban, Minoa.Caban, Knights );
   bit_and( Haworth.VanHorn, Minoa.VanHorn, Ririe );
   bit_and( Haworth.Accord, Minoa.Accord, Brinklow );
   bit_and( Haworth.Milam, Minoa.Milam, Gheen );
   bit_and( Haworth.Fitler, Minoa.Fitler, Tusayan );
   bit_and( Haworth.Bosco, Minoa.Bosco, Waimalu );
   bit_and( Haworth.Oroville, Minoa.Oroville, Casselman );
}
table Tekonsha {
   reads {
      Minoa.DeepGap : exact;
   }
   actions {
      Honuapo;
   }
   default_action : Honuapo(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Atlas {
   apply( Tekonsha );
}
control McCracken {
   apply( Fernway );
}
table Bonner {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : ternary;
      Minoa.Komatke : ternary;
      Minoa.Caban : ternary;
      Minoa.VanHorn : ternary;
      Minoa.Accord : ternary;
      Minoa.Milam : ternary;
      Minoa.Fitler : ternary;
      Minoa.Bosco : ternary;
      Minoa.Oroville : ternary;
   }
   actions {
      Ridgewood;
   }
   size : 512;
}
control DeSmet {
   apply( Bonner );
}
@pragma ways 4
table Saxis {
   reads {
      Minoa.DeepGap : exact;
      Haworth.Rocky : exact;
      Haworth.Komatke : exact;
      Haworth.Caban : exact;
      Haworth.VanHorn : exact;
      Haworth.Accord : exact;
      Haworth.Milam : exact;
      Haworth.Fitler : exact;
      Haworth.Bosco : exact;
      Haworth.Oroville : exact;
   }
   actions {
      Ridgewood;
   }
   size : 4096;
}
action Ranchito( Baldwin, Weatherby, Belfair, Isabel, Burwell, Russia, Rockdell, Onawa, MiraLoma ) {
   bit_and( Haworth.Rocky, Minoa.Rocky, Baldwin );
   bit_and( Haworth.Komatke, Minoa.Komatke, Weatherby );
   bit_and( Haworth.Caban, Minoa.Caban, Belfair );
   bit_and( Haworth.VanHorn, Minoa.VanHorn, Isabel );
   bit_and( Haworth.Accord, Minoa.Accord, Burwell );
   bit_and( Haworth.Milam, Minoa.Milam, Russia );
   bit_and( Haworth.Fitler, Minoa.Fitler, Rockdell );
   bit_and( Haworth.Bosco, Minoa.Bosco, Onawa );
   bit_and( Haworth.Oroville, Minoa.Oroville, MiraLoma );
}
table Kaeleku {
   reads {
      Minoa.DeepGap : exact;
   }
   actions {
      Ranchito;
   }
   default_action : Ranchito(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control LakeFork {
   apply( Kaeleku );
}
control Riverlea {
   apply( Saxis );
}
table Chaires {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : ternary;
      Minoa.Komatke : ternary;
      Minoa.Caban : ternary;
      Minoa.VanHorn : ternary;
      Minoa.Accord : ternary;
      Minoa.Milam : ternary;
      Minoa.Fitler : ternary;
      Minoa.Bosco : ternary;
      Minoa.Oroville : ternary;
   }
   actions {
      Ridgewood;
   }
   size : 512;
}
control TiePlant {
   apply( Chaires );
}
@pragma ways 4
table Tallevast {
   reads {
      Minoa.DeepGap : exact;
      Haworth.Rocky : exact;
      Haworth.Komatke : exact;
      Haworth.Caban : exact;
      Haworth.VanHorn : exact;
      Haworth.Accord : exact;
      Haworth.Milam : exact;
      Haworth.Fitler : exact;
      Haworth.Bosco : exact;
      Haworth.Oroville : exact;
   }
   actions {
      Ridgewood;
   }
   size : 4096;
}
action Lahaina( Skagway, Netcong, Greycliff, Marcus, DuckHill, Cidra, Woodward, Snowball, Wollochet ) {
   bit_and( Haworth.Rocky, Minoa.Rocky, Skagway );
   bit_and( Haworth.Komatke, Minoa.Komatke, Netcong );
   bit_and( Haworth.Caban, Minoa.Caban, Greycliff );
   bit_and( Haworth.VanHorn, Minoa.VanHorn, Marcus );
   bit_and( Haworth.Accord, Minoa.Accord, DuckHill );
   bit_and( Haworth.Milam, Minoa.Milam, Cidra );
   bit_and( Haworth.Fitler, Minoa.Fitler, Woodward );
   bit_and( Haworth.Bosco, Minoa.Bosco, Snowball );
   bit_and( Haworth.Oroville, Minoa.Oroville, Wollochet );
}
table Braselton {
   reads {
      Minoa.DeepGap : exact;
   }
   actions {
      Lahaina;
   }
   default_action : Lahaina(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Redmon {
   apply( Braselton );
}
control Almeria {
   apply( Tallevast );
}
table Champlin {
   reads {
      Minoa.DeepGap : exact;
      Minoa.Rocky : ternary;
      Minoa.Komatke : ternary;
      Minoa.Caban : ternary;
      Minoa.VanHorn : ternary;
      Minoa.Accord : ternary;
      Minoa.Milam : ternary;
      Minoa.Fitler : ternary;
      Minoa.Bosco : ternary;
      Minoa.Oroville : ternary;
   }
   actions {
      Ridgewood;
   }
   size : 512;
}
control Willshire {
   apply( Champlin );
}
action Deloit( Morstein ) {
   modify_field( MoonRun.Lumpkin, Morstein );
   bit_or( Easley.Lemhi, Oxford.Nanson, 0x80 );
}
action Inola( Suntrana ) {
   modify_field( MoonRun.Lumpkin, Suntrana );
   bit_or( Eolia.Minturn, Oxford.Nanson, 0x80 );
}
table Hickox {
   reads {
      Oxford.Nanson mask 0x80 : exact;
      Easley.valid : exact;
      Eolia.valid : exact;
   }
   actions {
      Deloit;
      Inola;
   }
   size : 8;
}
action Mentmore() {
   modify_field( Easley.Lemhi, 0, 0x80 );
}
action Willits() {
   modify_field( Eolia.Minturn, 0, 0x80 );
}
action Parole(Prunedale) {
   modify_field( Easley.Lemhi, Prunedale, 0x80 );
   modify_field( MoonRun.Bangor, 0);
}
action Wabbaseka(Fosston) {
   modify_field( Eolia.Minturn, Fosston, 0x80 );
   modify_field( MoonRun.Bangor, 0);
}
table Browndell {
   reads {
     MoonRun.Lumpkin : exact;
     Easley.valid : exact;
     Eolia.valid : exact;
     Oxford.Nanson mask 0x7f : ternary;
   }
   actions {
      Mentmore;
      Willits;
      Parole;
      Wabbaseka;
   }
   size : 8;
}
control ingress {
   Cross();
   if( Osman.Yukon != 0 ) {
      MintHill();
   }
   Wamego();
   if( Osman.Yukon != 0 ) {
      Hinkley();
      Swisshome();
   }
   Sanborn();
   Lolita();
   Brady();
   Maiden();
   Topawa();
   if( Osman.Yukon != 0 ) {
      Akiachak();
   }
   Palmhurst();
   Topsfield();
   Verdery();
   Heads();
   if( Osman.Yukon != 0 ) {
      Montalba();
   }
   Wabuska();
   Chappells();
   Claypool();
   Magazine();
   if( Osman.Yukon != 0 ) {
      Buckfield();
   } else {
      if( valid( Bratt ) ) {
         Grampian();
      }
   }
   Fairchild();
   Cleator();
   if( MoonRun.RoseTree != 2 ) {
      Marysvale();
   }
   Redden();
   if( Osman.Yukon != 0 ) {
      Kalkaska();
   }
   Fouke();
    Hayfork();
   Maddock();
   Huxley();
   if( MoonRun.McDonough == 0 and MoonRun.RoseTree != 2 ) {
      Etter();
      Firebrick();
   }
   if( Bratt.valid == 0 ) {
      Bigspring();
   }
   Palmdale();
   if( MoonRun.RoseTree == 0 ) {
      apply(Hickox);
   }
   Tanana();
   if( MoonRun.McDonough == 0 ) {
      Suffern();
   }
   if ( MoonRun.McDonough == 0 ) {
      Klukwan();
   }
   if( Osman.Yukon != 0 ) {
      NeckCity();
   }
   PineLake();
   if( MoonRun.McDonough == 0 ) {
      Raytown();
   }
   Dwight();
   if( valid( Lebanon[0] ) ) {
      Leawood();
   }
   Timken();
}
control egress {
   Joyce();
   Cedonia();
   Fairlee();
   if( MoonRun.RoseTree == 0 ) {
      apply( Browndell );
   }
   Merritt();
   if( ( MoonRun.Machens == 0 ) and ( MoonRun.RoseTree != 2 ) ) {
      NewTrier();
   }
   Catarina();
}

