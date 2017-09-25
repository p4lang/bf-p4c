// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 95521

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
header_type Alcester {
	fields {
		Tusayan : 16;
		Pocopson : 16;
		Yaurel : 8;
		Greenlawn : 8;
		Viroqua : 8;
		Requa : 8;
		Comptche : 1;
		Moorpark : 1;
		DuPont : 1;
		Fairmount : 1;
		SandCity : 1;
		GlenRose : 1;
	}
}
header_type SomesBar {
	fields {
		Corona : 24;
		Halsey : 24;
		Tillamook : 24;
		Rohwer : 24;
		Lazear : 16;
		Holtville : 16;
		Paisley : 16;
		Naches : 16;
		Pilottown : 16;
		Glenmora : 8;
		FourTown : 8;
		Ontonagon : 1;
		Lecompte : 1;
		Ewing : 1;
		Paulding : 1;
		Raiford : 12;
		Farthing : 2;
		Pojoaque : 1;
		Reydon : 1;
		Weyauwega : 1;
		Clarkdale : 1;
		Lefors : 1;
		Highfill : 1;
		Pittwood : 1;
		Proctor : 1;
		OjoFeliz : 1;
		August : 1;
		Pownal : 1;
		Courtdale : 1;
		Coronado : 1;
		Altus : 1;
		McDonough : 1;
		Bluff : 1;
		Yardville : 16;
		Leawood : 16;
		Bostic : 8;
		Brunson : 1;
		Penrose : 1;
	}
}
header_type Parthenon {
	fields {
		Oakville : 24;
		Elsmere : 24;
		Bleecker : 24;
		Udall : 24;
		Stoutland : 24;
		Grays : 24;
		Dumas : 24;
		LaSal : 24;
		Cadott : 16;
		Arvonia : 16;
		Okaton : 16;
		Mickleton : 16;
		Monkstown : 12;
		Lenox : 1;
		Linville : 3;
		Newfolden : 1;
		DeRidder : 3;
		Freedom : 1;
		Crozet : 1;
		Castle : 1;
		Westville : 1;
		Fernway : 1;
		Maida : 8;
		Trammel : 12;
		Wollochet : 4;
		Hartville : 6;
		Horns : 10;
		Bernard : 9;
		Knierim : 1;
		Canton : 1;
		Allerton : 1;
		Woodland : 1;
		Wakeman : 1;
	}
}
header_type Fishers {
	fields {
		Copemish : 8;
		Padonia : 1;
		Sharptown : 1;
		Duster : 1;
		Northway : 1;
		Virgilina : 1;
		Wimberley : 2;
		Henrietta : 2;
	}
}
header_type FlyingH {
	fields {
		Pembine : 32;
		Maxwelton : 32;
		Clarks : 6;
		Dubach : 16;
	}
}
header_type Newfane {
	fields {
		Swedeborg : 128;
		Unity : 128;
		Stovall : 20;
		Fieldon : 8;
		Waxhaw : 11;
		Moark : 6;
		Hilbert : 13;
	}
}
header_type Clearmont {
	fields {
		Pierre : 14;
		ElCentro : 1;
		Bufalo : 12;
		Placida : 1;
		Louviers : 1;
		Leetsdale : 6;
		Carlin : 2;
		Pinecreek : 6;
		Knights : 3;
	}
}
header_type Tennyson {
	fields {
		Bulverde : 1;
		Weatherby : 1;
	}
}
header_type Averill {
	fields {
		Accomac : 8;
	}
}
header_type Hutchings {
	fields {
		Sodaville : 16;
		LakeHart : 11;
	}
}
header_type Conda {
	fields {
		Durant : 32;
		Redmon : 32;
		Desdemona : 32;
	}
}
header_type Garretson {
	fields {
		Brookston : 32;
		Burden : 32;
	}
}
header_type Lemoyne {
	fields {
		Myrick : 1;
		Ignacio : 1;
		Benkelman : 1;
		Topmost : 3;
		Earling : 1;
		Sagerton : 6;
		Tontogany : 5;
	}
}
header_type Cahokia {
	fields {
		Ossipee : 16;
	}
}
header_type Cropper {
	fields {
		Bagdad : 14;
		Tiller : 1;
		Gerlach : 1;
	}
}
header_type Bellmead {
	fields {
		BayPort : 14;
		Chubbuck : 1;
		Vevay : 1;
	}
}
header_type Chaires {
	fields {
		Beasley : 16;
		Perkasie : 16;
		Triplett : 16;
		Waterflow : 16;
		Nixon : 8;
		Rumson : 8;
		Buenos : 8;
		Perrytown : 8;
		Lostwood : 1;
		Hookdale : 6;
	}
}
header_type Levittown {
	fields {
		Darmstadt : 32;
	}
}
header_type Unionvale {
	fields {
		Rotonda : 6;
		Edwards : 10;
		MintHill : 4;
		Florida : 12;
		Duquoin : 12;
		Mekoryuk : 2;
		Quivero : 2;
		Amonate : 8;
		Parrish : 3;
		ElToro : 5;
	}
}
header_type Portville {
	fields {
		Bairoa : 24;
		Burnett : 24;
		Harmony : 24;
		Brundage : 24;
		Sarepta : 16;
	}
}
header_type Shoshone {
	fields {
		Yakutat : 3;
		Crowheart : 1;
		Denmark : 12;
		Butler : 16;
	}
}
header_type Wamego {
	fields {
		Correo : 4;
		Veradale : 4;
		Hearne : 6;
		Machens : 2;
		Korbel : 16;
		Nevis : 16;
		Iredell : 3;
		Gaston : 13;
		Disney : 8;
		Azalia : 8;
		Fairhaven : 16;
		Haines : 32;
		Windber : 32;
	}
}
header_type Hiseville {
	fields {
		Attica : 4;
		Nephi : 6;
		Hartman : 2;
		Halbur : 20;
		Pineridge : 16;
		Belwood : 8;
		Alberta : 8;
		Cimarron : 128;
		Stirrat : 128;
	}
}
header_type Mayview {
	fields {
		Neuse : 8;
		Minneiska : 8;
		Resaca : 16;
	}
}
header_type Smithland {
	fields {
		Farlin : 16;
		Thalmann : 16;
	}
}
header_type Iselin {
	fields {
		Convoy : 32;
		Dutton : 32;
		Topawa : 4;
		Baroda : 4;
		Bellvue : 8;
		Carpenter : 16;
		Ivins : 16;
		Armona : 16;
	}
}
header_type Westboro {
	fields {
		Elkville : 16;
		Denning : 16;
	}
}
header_type Ladelle {
	fields {
		Plains : 16;
		Pevely : 16;
		Gahanna : 8;
		BirchRun : 8;
		Kerby : 16;
	}
}
header_type Gillespie {
	fields {
		HydePark : 48;
		Lofgreen : 32;
		Vanoss : 48;
		Watters : 32;
	}
}
header_type Owanka {
	fields {
		Duffield : 1;
		Roodhouse : 1;
		Savery : 1;
		Mantee : 1;
		Weinert : 1;
		Madill : 3;
		Donald : 5;
		Tunis : 3;
		Ludden : 16;
	}
}
header_type Cliffs {
	fields {
		Farson : 24;
		Krupp : 8;
	}
}
header_type Gervais {
	fields {
		Hagerman : 8;
		Oskaloosa : 24;
		DeKalb : 24;
		Swanlake : 8;
	}
}
header Portville Heeia;
header Portville Millikin;
header Shoshone Wamesit[ 2 ];
@pragma pa_fragment ingress Maljamar.Fairhaven
@pragma pa_fragment egress Maljamar.Fairhaven
header Wamego Maljamar;
@pragma pa_fragment ingress Tiverton.Fairhaven
@pragma pa_fragment egress Tiverton.Fairhaven
header Wamego Tiverton;
header Hiseville Goree;
header Hiseville Skyforest;
header Smithland Emmorton;
header Smithland Cassa;
header Iselin Alzada;
header Westboro Leacock;
header Iselin Vergennes;
header Westboro Grants;
header Gervais Blossom;
header Ladelle Knollwood;
header Owanka Statham;
header Unionvale PineHill;
header Portville Littleton;
parser start {
   return select(current(96, 16)) {
      0xBF00 : Gunder;
      default : Hanapepe;
   }
}
parser Naubinway {
   extract( PineHill );
   return Hanapepe;
}
parser Gunder {
   extract( Littleton );
   return Naubinway;
}
parser Hanapepe {
   extract( Heeia );
   return select( Heeia.Sarepta ) {
      0x8100 : Malesus;
      0x0800 : Chazy;
      0x86dd : Roxboro;
      0x0806 : Keener;
      default : ingress;
   }
}
parser Malesus {
   extract( Wamesit[0] );
   set_metadata(OldMinto.SandCity, 1);
   return select( Wamesit[0].Butler ) {
      0x0800 : Chazy;
      0x86dd : Roxboro;
      0x0806 : Keener;
      default : ingress;
   }
}
field_list Bremond {
    Maljamar.Correo;
    Maljamar.Veradale;
    Maljamar.Hearne;
    Maljamar.Machens;
    Maljamar.Korbel;
    Maljamar.Nevis;
    Maljamar.Iredell;
    Maljamar.Gaston;
    Maljamar.Disney;
    Maljamar.Azalia;
    Maljamar.Haines;
    Maljamar.Windber;
}
field_list_calculation Fenwick {
    input {
        Bremond;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Maljamar.Fairhaven {
    verify Fenwick;
    update Fenwick;
}
parser Chazy {
   extract( Maljamar );
   set_metadata(OldMinto.Yaurel, Maljamar.Azalia);
   set_metadata(OldMinto.Viroqua, Maljamar.Disney);
   set_metadata(OldMinto.Tusayan, Maljamar.Korbel);
   set_metadata(OldMinto.DuPont, 0);
   set_metadata(OldMinto.Comptche, 1);
   return select(Maljamar.Gaston, Maljamar.Veradale, Maljamar.Azalia) {
      0x501 : Basehor;
      0x511 : Higgston;
      0x506 : Philippi;
      0 mask 0xFF7000 : Qulin;
      default : ingress;
   }
}
parser Qulin {
   set_metadata(Gerster.Ewing, 1);
   return ingress;
}
parser Roxboro {
   extract( Skyforest );
   set_metadata(OldMinto.Yaurel, Skyforest.Belwood);
   set_metadata(OldMinto.Viroqua, Skyforest.Alberta);
   set_metadata(OldMinto.Tusayan, Skyforest.Pineridge);
   set_metadata(OldMinto.DuPont, 1);
   set_metadata(OldMinto.Comptche, 0);
   return select(Skyforest.Belwood) {
      0x3a : Basehor;
      17 : Lynne;
      6 : Philippi;
      default : Qulin;
   }
}
parser Keener {
   extract( Knollwood );
   set_metadata(OldMinto.GlenRose, 1);
   return ingress;
}
parser Higgston {
   extract(Emmorton);
   extract(Leacock);
   set_metadata(Gerster.Ewing, 1);
   return select(Emmorton.Thalmann) {
      4789 : Engle;
      default : ingress;
    }
}
parser Basehor {
   set_metadata( Emmorton.Farlin, current( 0, 16 ) );
   set_metadata( Emmorton.Thalmann, 0 );
   set_metadata( Gerster.Ewing, 1 );
   return ingress;
}
parser Lynne {
   set_metadata(Gerster.Ewing, 1);
   extract(Emmorton);
   extract(Leacock);
   return ingress;
}
parser Philippi {
   set_metadata(Gerster.Brunson, 1);
   set_metadata(Gerster.Ewing, 1);
   extract(Emmorton);
   extract(Alzada);
   return ingress;
}
parser Hobson {
   set_metadata(Gerster.Farthing, 2);
   return Gilmanton;
}
parser Lisman {
   set_metadata(Gerster.Farthing, 2);
   return Burdette;
}
parser Prosser {
   extract(Statham);
   return select(Statham.Duffield, Statham.Roodhouse, Statham.Savery, Statham.Mantee, Statham.Weinert,
             Statham.Madill, Statham.Donald, Statham.Tunis, Statham.Ludden) {
      0x0800 : Hobson;
      0x86dd : Lisman;
      default : ingress;
   }
}
parser Engle {
   extract(Blossom);
   set_metadata(Gerster.Farthing, 1);
   return Angle;
}
field_list Tularosa {
    Tiverton.Correo;
    Tiverton.Veradale;
    Tiverton.Hearne;
    Tiverton.Machens;
    Tiverton.Korbel;
    Tiverton.Nevis;
    Tiverton.Iredell;
    Tiverton.Gaston;
    Tiverton.Disney;
    Tiverton.Azalia;
    Tiverton.Haines;
    Tiverton.Windber;
}
field_list_calculation Kalaloch {
    input {
        Tularosa;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Tiverton.Fairhaven {
    verify Kalaloch;
    update Kalaloch;
}
parser Gilmanton {
   extract( Tiverton );
   set_metadata(OldMinto.Greenlawn, Tiverton.Azalia);
   set_metadata(OldMinto.Requa, Tiverton.Disney);
   set_metadata(OldMinto.Pocopson, Tiverton.Korbel);
   set_metadata(OldMinto.Fairmount, 0);
   set_metadata(OldMinto.Moorpark, 1);
   return select(Tiverton.Gaston, Tiverton.Veradale, Tiverton.Azalia) {
      0x501 : Honuapo;
      0x511 : WyeMills;
      0x506 : Onarga;
      0 mask 0xFF7000 : Lookeba;
      default : ingress;
   }
}
parser Lookeba {
   set_metadata(Gerster.Paulding, 1);
   return ingress;
}
parser Burdette {
   extract( Goree );
   set_metadata(OldMinto.Greenlawn, Goree.Belwood);
   set_metadata(OldMinto.Requa, Goree.Alberta);
   set_metadata(OldMinto.Pocopson, Goree.Pineridge);
   set_metadata(OldMinto.Fairmount, 1);
   set_metadata(OldMinto.Moorpark, 0);
   return select(Goree.Belwood) {
      0x3a : Honuapo;
      17 : WyeMills;
      6 : Onarga;
      default : Lookeba;
   }
}
parser Honuapo {
   set_metadata( Gerster.Yardville, current( 0, 16 ) );
   set_metadata( Gerster.Bluff, 1 );
   set_metadata( Gerster.Paulding, 1 );
   return ingress;
}
parser WyeMills {
   set_metadata( Gerster.Yardville, current( 0, 16 ) );
   set_metadata( Gerster.Leawood, current( 16, 16 ) );
   set_metadata( Gerster.Bluff, 1 );
   set_metadata( Gerster.Paulding, 1);
   return ingress;
}
parser Onarga {
   set_metadata( Gerster.Yardville, current( 0, 16 ) );
   set_metadata( Gerster.Leawood, current( 16, 16 ) );
   set_metadata( Gerster.Bostic, current( 104, 8 ) );
   set_metadata( Gerster.Bluff, 1 );
   set_metadata( Gerster.Paulding, 1 );
   set_metadata( Gerster.Penrose, 1 );
   extract(Cassa);
   extract(Vergennes);
   return ingress;
}
parser Angle {
   extract( Millikin );
   return select( Millikin.Sarepta ) {
      0x0800: Gilmanton;
      0x86dd: Burdette;
      default: ingress;
   }
}
@pragma pa_no_init ingress Gerster.Corona
@pragma pa_no_init ingress Gerster.Halsey
@pragma pa_no_init ingress Gerster.Tillamook
@pragma pa_no_init ingress Gerster.Rohwer
metadata SomesBar Gerster;
@pragma pa_no_init ingress PineCity.Oakville
@pragma pa_no_init ingress PineCity.Elsmere
@pragma pa_no_init ingress PineCity.Bleecker
@pragma pa_no_init ingress PineCity.Udall
metadata Parthenon PineCity;
metadata Clearmont Acree;
metadata Alcester OldMinto;
metadata FlyingH WestBay;
metadata Newfane Kingsgate;
metadata Tennyson Berrydale;

#ifdef VAG_FIX
@pragma pa_solitary ingress IdaGrove.Henrietta
@pragma pa_solitary ingress IdaGrove.Wimberley
#endif
metadata Fishers IdaGrove;

metadata Averill Trona;
metadata Hutchings Calhan;
metadata Garretson Newfield;
metadata Conda Coalton;
metadata Lemoyne Lublin;
metadata Cahokia Frankston;
@pragma pa_no_init ingress Chenequa.Bagdad
metadata Cropper Chenequa;
@pragma pa_no_init ingress Ringold.BayPort
metadata Bellmead Ringold;
metadata Chaires Stillmore;
metadata Chaires Westend;
action Rosburg() {
   no_op();
}
action Ronneby() {
   modify_field(Gerster.Clarkdale, 1 );
   mark_for_drop();
}
action Harshaw() {
   no_op();
}
action Cochise(Ancho, Panacea, Braselton, Leoma, Wewela, Daleville,
                 Wyarno, Caroleen, Manasquan) {
    modify_field(Acree.Pierre, Ancho);
    modify_field(Acree.ElCentro, Panacea);
    modify_field(Acree.Bufalo, Braselton);
    modify_field(Acree.Placida, Leoma);
    modify_field(Acree.Louviers, Wewela);
    modify_field(Acree.Leetsdale, Daleville);
    modify_field(Acree.Carlin, Wyarno);
    modify_field(Acree.Knights, Caroleen);
    modify_field(Acree.Pinecreek, Manasquan);
}

@pragma command_line --no-dead-code-elimination
table Higbee {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Cochise;
    }
    size : 288;
}
control Chappell {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Higbee);
    }
}
action Royston(Newcastle, Orosi) {
   modify_field( PineCity.Newfolden, 1 );
   modify_field( PineCity.Maida, Newcastle);
   modify_field( Gerster.August, 1 );
   modify_field( Lublin.Benkelman, Orosi );
}
action Selah() {
   modify_field( Gerster.Pittwood, 1 );
   modify_field( Gerster.Courtdale, 1 );
}
action English() {
   modify_field( Gerster.August, 1 );
}
action Elburn() {
   modify_field( Gerster.August, 1 );
   modify_field( Gerster.Coronado, 1 );
}
action Cardenas() {
   modify_field( Gerster.Pownal, 1 );
}
action Schofield() {
   modify_field( Gerster.Courtdale, 1 );
}
counter Topsfield {
   type : packets_and_bytes;
   direct : Pathfork;
   min_width: 16;
}
table Pathfork {
   reads {
      Acree.Leetsdale : exact;
      Heeia.Bairoa : ternary;
      Heeia.Burnett : ternary;
   }
   actions {
      Royston;
      Selah;
      English;
      Cardenas;
      Schofield;
      Elburn;
   }
   size : 1024;
}
action McCracken() {
   modify_field( Gerster.Proctor, 1 );
}
table Corydon {
   reads {
      Heeia.Harmony : ternary;
      Heeia.Brundage : ternary;
   }
   actions {
      McCracken;
   }
   size : 512;
}
control Fiskdale {
   apply( Pathfork );
   apply( Corydon );
}
action Gustine() {
   modify_field( WestBay.Pembine, Tiverton.Haines );
   modify_field( WestBay.Maxwelton, Tiverton.Windber );
   modify_field( WestBay.Clarks, Tiverton.Hearne );
   modify_field( Kingsgate.Swedeborg, Goree.Cimarron );
   modify_field( Kingsgate.Unity, Goree.Stirrat );
   modify_field( Kingsgate.Stovall, Goree.Halbur );
   modify_field( Kingsgate.Moark, Goree.Nephi );
   modify_field( Gerster.Corona, Millikin.Bairoa );
   modify_field( Gerster.Halsey, Millikin.Burnett );
   modify_field( Gerster.Tillamook, Millikin.Harmony );
   modify_field( Gerster.Rohwer, Millikin.Brundage );
   modify_field( Gerster.Lazear, Millikin.Sarepta );
   modify_field( Gerster.Pilottown, OldMinto.Pocopson );
   modify_field( Gerster.Glenmora, OldMinto.Greenlawn );
   modify_field( Gerster.FourTown, OldMinto.Requa );
   modify_field( Gerster.Lecompte, OldMinto.Moorpark );
   modify_field( Gerster.Ontonagon, OldMinto.Fairmount );
   modify_field( Gerster.Altus, 0 );
   modify_field( PineCity.DeRidder, 1 );
   modify_field( Acree.Carlin, 1 );
   modify_field( Acree.Knights, 0 );
   modify_field( Acree.Pinecreek, 0 );
   modify_field( Lublin.Myrick, 1 );
   modify_field( Lublin.Ignacio, 1 );
   modify_field( Gerster.Ewing, Gerster.Paulding );
   modify_field( Gerster.Brunson, Gerster.Penrose );
}
action Kinde() {
   modify_field( Gerster.Farthing, 0 );
   modify_field( WestBay.Pembine, Maljamar.Haines );
   modify_field( WestBay.Maxwelton, Maljamar.Windber );
   modify_field( WestBay.Clarks, Maljamar.Hearne );
   modify_field( Kingsgate.Swedeborg, Skyforest.Cimarron );
   modify_field( Kingsgate.Unity, Skyforest.Stirrat );
   modify_field( Kingsgate.Stovall, Skyforest.Halbur );
   modify_field( Kingsgate.Moark, Skyforest.Nephi );
   modify_field( Gerster.Corona, Heeia.Bairoa );
   modify_field( Gerster.Halsey, Heeia.Burnett );
   modify_field( Gerster.Tillamook, Heeia.Harmony );
   modify_field( Gerster.Rohwer, Heeia.Brundage );
   modify_field( Gerster.Lazear, Heeia.Sarepta );
   modify_field( Gerster.Pilottown, OldMinto.Tusayan );
   modify_field( Gerster.Glenmora, OldMinto.Yaurel );
   modify_field( Gerster.FourTown, OldMinto.Viroqua );
   modify_field( Gerster.Lecompte, OldMinto.Comptche );
   modify_field( Gerster.Ontonagon, OldMinto.DuPont );
   modify_field( Lublin.Earling, Wamesit[0].Crowheart );
   modify_field( Gerster.Altus, OldMinto.SandCity );
   modify_field( Gerster.Yardville, Emmorton.Farlin );
   modify_field( Gerster.Leawood, Emmorton.Thalmann );
   modify_field( Gerster.Bostic, Alzada.Bellvue );
}
table KeyWest {
   reads {
      Heeia.Bairoa : exact;
      Heeia.Burnett : exact;
      Maljamar.Windber : exact;
      Gerster.Farthing : exact;
   }
   actions {
      Gustine;
      Kinde;
   }
   default_action : Kinde();
   size : 1024;
}
action Stonebank() {
   modify_field( Gerster.Holtville, Acree.Bufalo );
   modify_field( Gerster.Paisley, Acree.Pierre);
}
action Hurdtown( Charlack ) {
   modify_field( Gerster.Holtville, Charlack );
   modify_field( Gerster.Paisley, Acree.Pierre);
}
action Benonine() {
   modify_field( Gerster.Holtville, Wamesit[0].Denmark );
   modify_field( Gerster.Paisley, Acree.Pierre);
}
table Santos {
   reads {
      Acree.Pierre : ternary;
      Wamesit[0] : valid;
      Wamesit[0].Denmark : ternary;
   }
   actions {
      Stonebank;
      Hurdtown;
      Benonine;
   }
   size : 4096;
}
action Boonsboro( Uintah ) {
   modify_field( Gerster.Paisley, Uintah );
}
action Fonda() {
   modify_field( Gerster.Weyauwega, 1 );
   modify_field( Trona.Accomac,
                 1 );
}
table Heaton {
   reads {
      Maljamar.Haines : exact;
   }
   actions {
      Boonsboro;
      Fonda;
   }
   default_action : Fonda;
   size : 4096;
}
action ArchCape( Lynch, Almeria, Onamia, Callimont, Center,
                        Millston, Wapato ) {
   modify_field( Gerster.Holtville, Lynch );
   modify_field( Gerster.Naches, Lynch );
   modify_field( Gerster.Highfill, Wapato );
   Atwater(Almeria, Onamia, Callimont, Center,
                        Millston );
}
action Otranto() {
   modify_field( Gerster.Lefors, 1 );
}
table Joiner {
   reads {
      Blossom.DeKalb : exact;
   }
   actions {
      ArchCape;
      Otranto;
   }
   size : 4096;
}
action Atwater(Scarville, Marquand, Leflore, Halfa,
                        Finley ) {
   modify_field( IdaGrove.Copemish, Scarville );
   modify_field( IdaGrove.Padonia, Marquand );
   modify_field( IdaGrove.Duster, Leflore );
   modify_field( IdaGrove.Sharptown, Halfa );
   modify_field( IdaGrove.Northway, Finley );
}
action Brookside(Loris, Stilwell, Energy, Goessel,
                        Elrosa ) {
   modify_field( Gerster.Naches, Acree.Bufalo );
   Atwater(Loris, Stilwell, Energy, Goessel,
                        Elrosa );
}
action Glassboro(Maiden, Sudden, Burmah, Lesley,
                        LakePine, Havana ) {
   modify_field( Gerster.Naches, Maiden );
   Atwater(Sudden, Burmah, Lesley, LakePine,
                        Havana );
}
action Pilger(Counce, JimFalls, Nuyaka, Devers,
                        Kapowsin ) {
   modify_field( Gerster.Naches, Wamesit[0].Denmark );
   Atwater(Counce, JimFalls, Nuyaka, Devers,
                        Kapowsin );
}
table Catlin {
   reads {
      Acree.Bufalo : exact;
   }
   actions {
      Rosburg;
      Brookside;
   }
   size : 4096;
}
@pragma action_default_only Rosburg
table Atlas {
   reads {
      Acree.Pierre : exact;
      Wamesit[0].Denmark : exact;
   }
   actions {
      Glassboro;
      Rosburg;
   }
   size : 1024;
}
table Soldotna {
   reads {
      Wamesit[0].Denmark : exact;
   }
   actions {
      Rosburg;
      Pilger;
   }
   size : 4096;
}
control Canfield {
   apply( KeyWest ) {
         Gustine {
            apply( Heaton );
            apply( Joiner );
         }
         Kinde {
            if ( not valid(PineHill) and Acree.Placida == 1 ) {
               apply( Santos );
            }
            if ( valid( Wamesit[ 0 ] ) ) {
               apply( Atlas ) {
                  Rosburg {
                     apply( Soldotna );
                  }
               }
            } else {
               apply( Catlin );
            }
         }
   }
}
register Servia {
    width : 1;
    static : Terrell;
    instance_count : 262144;
}
register Verdery {
    width : 1;
    static : Olene;
    instance_count : 262144;
}
blackbox stateful_alu FulksRun {
    reg : Servia;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : Berrydale.Bulverde;
}
blackbox stateful_alu Oilmont {
    reg : Verdery;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst : Berrydale.Weatherby;
}
field_list Hackamore {
    Acree.Leetsdale;
    Wamesit[0].Denmark;
}
field_list_calculation Bethune {
    input { Hackamore; }
    algorithm: identity;
    output_width: 18;
}
action Quarry() {
    FulksRun.execute_stateful_alu_from_hash(Bethune);
}
action Clementon() {
    Oilmont.execute_stateful_alu_from_hash(Bethune);
}
table Terrell {
    actions {
      Quarry;
    }
    default_action : Quarry;
    size : 1;
}
table Olene {
    actions {
      Clementon;
    }
    default_action : Clementon;
    size : 1;
}
action Judson(Cannelton) {
    modify_field(Berrydale.Weatherby, Cannelton);
}
@pragma use_hash_action 0
table Cowan {
    reads {
       Acree.Leetsdale : exact;
    }
    actions {
      Judson;
    }
    size : 64;
}
action Bergton() {
   modify_field( Gerster.Raiford, Acree.Bufalo );
   modify_field( Gerster.Pojoaque, 0 );
}
table Odessa {
   actions {
      Bergton;
   }
   size : 1;
}
action Glazier() {
   modify_field( Gerster.Raiford, Wamesit[0].Denmark );
   modify_field( Gerster.Pojoaque, 1 );
}
table Estero {
   actions {
      Glazier;
   }
   size : 1;
}
control Howland {
   if ( valid( Wamesit[ 0 ] ) ) {
      apply( Estero );
      if( Acree.Louviers == 1 ) {
         apply( Terrell );
         apply( Olene );
      }
   } else {
      apply( Odessa );
      if( Acree.Louviers == 1 ) {
         apply( Cowan );
      }
   }
}
field_list Marquette {
   Heeia.Bairoa;
   Heeia.Burnett;
   Heeia.Harmony;
   Heeia.Brundage;
   Heeia.Sarepta;
}
field_list Dickson {
   Maljamar.Azalia;
   Maljamar.Haines;
   Maljamar.Windber;
}
field_list Prunedale {
   Skyforest.Cimarron;
   Skyforest.Stirrat;
   Skyforest.Halbur;
   Skyforest.Belwood;
}
field_list Barnard {
   Maljamar.Haines;
   Maljamar.Windber;
   Emmorton.Farlin;
   Emmorton.Thalmann;
}
field_list_calculation McLaurin {
    input {
        Marquette;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Ekron {
    input {
        Dickson;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Veneta {
    input {
        Prunedale;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Algodones {
    input {
        Barnard;
    }
    algorithm : crc32;
    output_width : 32;
}
action Montague() {
    modify_field_with_hash_based_offset(Coalton.Durant, 0,
                                        McLaurin, 4294967296);
}
action Goulds() {
    modify_field_with_hash_based_offset(Coalton.Redmon, 0,
                                        Ekron, 4294967296);
}
action Fairland() {
    modify_field_with_hash_based_offset(Coalton.Redmon, 0,
                                        Veneta, 4294967296);
}
action Wauseon() {
    modify_field_with_hash_based_offset(Coalton.Desdemona, 0,
                                        Algodones, 4294967296);
}
table Gause {
   actions {
      Montague;
   }
   size: 1;
}
control Braymer {
   apply(Gause);
}
table Aldan {
   actions {
      Goulds;
   }
   size: 1;
}
table Newberg {
   actions {
      Fairland;
   }
   size: 1;
}
control Longwood {
   if ( valid( Maljamar ) ) {
      apply(Aldan);
   } else {
      if ( valid( Skyforest ) ) {
         apply(Newberg);
      }
   }
}
table Chaska {
   actions {
      Wauseon;
   }
   size: 1;
}
control Wanamassa {
   if ( valid( Leacock ) ) {
      apply(Chaska);
   }
}
action PineLawn() {
    modify_field(Newfield.Brookston, Coalton.Durant);
}
action LaJoya() {
    modify_field(Newfield.Brookston, Coalton.Redmon);
}
action LaJara() {
    modify_field(Newfield.Brookston, Coalton.Desdemona);
}
@pragma action_default_only Rosburg
@pragma immediate 0
table Halliday {
   reads {
      Vergennes.valid : ternary;
      Grants.valid : ternary;
      Tiverton.valid : ternary;
      Goree.valid : ternary;
      Millikin.valid : ternary;
      Alzada.valid : ternary;
      Leacock.valid : ternary;
      Maljamar.valid : ternary;
      Skyforest.valid : ternary;
      Heeia.valid : ternary;
   }
   actions {
      PineLawn;
      LaJoya;
      LaJara;
      Rosburg;
   }
   size: 256;
}
action Reagan() {
    modify_field(Newfield.Burden, Coalton.Desdemona);
}
@pragma immediate 0
table Barron {
   reads {
      Vergennes.valid : ternary;
      Grants.valid : ternary;
      Alzada.valid : ternary;
      Leacock.valid : ternary;
   }
   actions {
      Reagan;
      Rosburg;
   }
   size: 6;
}
control Astor {
   apply(Barron);
   apply(Halliday);
}
counter Wyanet {
   type : packets_and_bytes;
   direct : Onida;
   min_width: 16;
}
table Onida {
   reads {
      Acree.Leetsdale : exact;
      Berrydale.Weatherby : ternary;
      Berrydale.Bulverde : ternary;
      Gerster.Lefors : ternary;
      Gerster.Proctor : ternary;
      Gerster.Pittwood : ternary;
   }
   actions {
      Ronneby;
      Rosburg;
   }
   default_action : Rosburg();
   size : 512;
}
table Longport {
   reads {
      Gerster.Tillamook : exact;
      Gerster.Rohwer : exact;
      Gerster.Holtville : exact;
   }
   actions {
      Ronneby;
      Rosburg;
   }
   default_action : Rosburg();
   size : 4096;
}
action Cordell() {
   modify_field(Gerster.Reydon, 1 );
   modify_field(Trona.Accomac,
                0);
}
table Hauppauge {
   reads {
      Gerster.Tillamook : exact;
      Gerster.Rohwer : exact;
      Gerster.Holtville : exact;
      Gerster.Paisley : exact;
   }
   actions {
      Harshaw;
      Cordell;
   }
   default_action : Cordell();
   size : 65536;
   support_timeout : true;
}
action TiePlant( Anniston, Draketown ) {
   modify_field( Gerster.McDonough, Anniston );
   modify_field( Gerster.Highfill, Draketown );
}
action Flaxton() {
   modify_field( Gerster.Highfill, 1 );
}
table Claypool {
   reads {
      Gerster.Holtville mask 0xfff : exact;
   }
   actions {
      TiePlant;
      Flaxton;
      Rosburg;
   }
   default_action : Rosburg();
   size : 4096;
}
action Berne() {
   modify_field( IdaGrove.Virgilina, 1 );
}
table Mission {
   reads {
      Gerster.Naches : ternary;
      Gerster.Corona : exact;
      Gerster.Halsey : exact;
   }
   actions {
      Berne;
   }
   size: 512;
}
control Hurst {
   apply( Onida ) {
      Rosburg {
         apply( Longport ) {
            Rosburg {
               if (Acree.ElCentro == 0 and Gerster.Weyauwega == 0) {
                  apply( Hauppauge );
               }
               apply( Claypool );
               apply(Mission);
            }
         }
      }
   }
}
field_list Flippen {
    Trona.Accomac;
    Gerster.Tillamook;
    Gerster.Rohwer;
    Gerster.Holtville;
    Gerster.Paisley;
}
action KentPark() {
   generate_digest(0, Flippen);
}
table Rushmore {
   actions {
      KentPark;
   }
   size : 1;
}
control Kenyon {
   if (Gerster.Reydon == 1) {
      apply( Rushmore );
   }
}
action RioHondo( Browning, Carlson ) {
   modify_field( Kingsgate.Hilbert, Browning );
   modify_field( Calhan.Sodaville, Carlson );
}
@pragma action_default_only Chatfield
table Cresco {
   reads {
      IdaGrove.Copemish : exact;
      Kingsgate.Unity mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      RioHondo;
      Chatfield;
   }
   size : 8192;
}
@pragma atcam_partition_index Kingsgate.Hilbert
@pragma atcam_number_partitions 8192
table Parkline {
   reads {
      Kingsgate.Hilbert : exact;
      Kingsgate.Unity mask 0x000007FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Bethania;
      Hanford;
      Rosburg;
   }
   default_action : Rosburg();
   size : 65536;
}
action Marysvale( Stanwood, RioLajas ) {
   modify_field( Kingsgate.Waxhaw, Stanwood );
   modify_field( Calhan.Sodaville, RioLajas );
}
@pragma action_default_only Rosburg
table Earlham {
   reads {
      IdaGrove.Copemish : exact;
      Kingsgate.Unity : lpm;
   }
   actions {
      Marysvale;
      Rosburg;
   }
   size : 2048;
}
@pragma atcam_partition_index Kingsgate.Waxhaw
@pragma atcam_number_partitions 2048
table Poynette {
   reads {
      Kingsgate.Waxhaw : exact;
      Kingsgate.Unity mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Bethania;
      Hanford;
      Rosburg;
   }
   default_action : Rosburg();
   size : 16384;
}
@pragma action_default_only Chatfield
@pragma idletime_precision 1
table Seabrook {
   reads {
      IdaGrove.Copemish : exact;
      WestBay.Maxwelton : lpm;
   }
   actions {
      Bethania;
      Hanford;
      Chatfield;
   }
   size : 1024;
   support_timeout : true;
}
action Florahome( Isleta, Leesport ) {
   modify_field( WestBay.Dubach, Isleta );
   modify_field( Calhan.Sodaville, Leesport );
}
@pragma action_default_only Rosburg
table Saluda {
   reads {
      IdaGrove.Copemish : exact;
      WestBay.Maxwelton : lpm;
   }
   actions {
      Florahome;
      Rosburg;
   }
   size : 16384;
}
@pragma ways 2
@pragma atcam_partition_index WestBay.Dubach
@pragma atcam_number_partitions 16384
table Bulger {
   reads {
      WestBay.Dubach : exact;
      WestBay.Maxwelton mask 0x000fffff : lpm;
   }
   actions {
      Bethania;
      Hanford;
      Rosburg;
   }
   default_action : Rosburg();
   size : 131072;
}
action Bethania( Azusa ) {
   modify_field( Calhan.Sodaville, Azusa );
}
@pragma idletime_precision 1
table Haven {
   reads {
      IdaGrove.Copemish : exact;
      WestBay.Maxwelton : exact;
   }
   actions {
      Bethania;
      Hanford;
      Rosburg;
   }
   default_action : Rosburg();
   size : 65536;
   support_timeout : true;
}
@pragma idletime_precision 1
table Fries {
   reads {
      IdaGrove.Copemish : exact;
      Kingsgate.Unity : exact;
   }
   actions {
      Bethania;
      Hanford;
      Rosburg;
   }
   default_action : Rosburg();
   size : 65536;
   support_timeout : true;
}
action Milano(Elkland, Latham, Tannehill) {
   modify_field(PineCity.Cadott, Tannehill);
   modify_field(PineCity.Oakville, Elkland);
   modify_field(PineCity.Elsmere, Latham);
   modify_field(PineCity.Knierim, 1);
   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}
action Weslaco() {
   Ronneby();
}
action Hawthorne(WestEnd) {
   modify_field(PineCity.Newfolden, 1);
   modify_field(PineCity.Maida, WestEnd);
}
action Chatfield(Arbyrd) {
   modify_field( PineCity.Newfolden, 1 );
   modify_field( PineCity.Maida, 9 );
}
table Dandridge {
   reads {
      Calhan.Sodaville : exact;
   }
   actions {
      Milano;
      Weslaco;
      Hawthorne;
   }
   size : 65536;
}
action Rosebush( Exira ) {
   modify_field(PineCity.Newfolden, 1);
   modify_field(PineCity.Maida, Exira);
}
table Carnation {
   actions {
      Rosebush;
   }
   default_action: Rosebush(0);
   size : 1;
}
control Strasburg {
   if ( Gerster.Clarkdale == 0 and IdaGrove.Virgilina == 1 ) {
      if ( ( IdaGrove.Padonia == 1 ) and ( Gerster.Lecompte == 1 ) ) {
         apply( Haven ) {
            Rosburg {
               apply(Saluda);
            }
         }
      } else if ( ( IdaGrove.Duster == 1 ) and ( Gerster.Ontonagon == 1 ) ) {
         apply( Fries ) {
            Rosburg {
               apply( Earlham );
            }
         }
      }
   }
}
control Boyce {
   if ( Gerster.Clarkdale == 0 and IdaGrove.Virgilina == 1 and IdaGrove.Wimberley == 0 and IdaGrove.Henrietta == 0 ) {
      if ( ( IdaGrove.Padonia == 1 ) and ( Gerster.Lecompte == 1 ) ) {
         if ( WestBay.Dubach != 0 ) {
            apply( Bulger );
         } else if ( Calhan.Sodaville == 0 and Calhan.LakeHart == 0 ) {
            apply( Seabrook );
         }
      } else if ( ( IdaGrove.Duster == 1 ) and ( Gerster.Ontonagon == 1 ) ) {
         if ( Kingsgate.Waxhaw != 0 ) {
            apply( Poynette );
         } else if ( Calhan.Sodaville == 0 and Calhan.LakeHart == 0 ) {
            apply( Cresco ) {
               RioHondo {
                  apply( Parkline );
               }
            }
         }
      } else if( Gerster.Highfill == 1 ) {
         apply( Carnation );
      }
   }
}
control Windham {
   if( Calhan.Sodaville != 0 ) {
      apply( Dandridge );
   }
}
action Hanford( Tenino ) {
   modify_field( Calhan.LakeHart, Tenino );
}
field_list Ambler {
   Newfield.Burden;
}
field_list_calculation Archer {
    input {
        Ambler;
    }
    algorithm : identity;
    output_width : 66;
}
action_selector Cairo {
   selection_key : Archer;
   selection_mode : resilient;
}
action_profile Allegan {
   actions {
      Bethania;
   }
   size : 65536;
   dynamic_action_selection : Cairo;
}
@pragma selector_max_group_size 256
table Aguilita {
   reads {
      Calhan.LakeHart : exact;
   }
   action_profile : Allegan;
   size : 2048;
}
control Raceland {
   if ( Calhan.LakeHart != 0 ) {
      apply( Aguilita );
   }
}
field_list Harlem {
   Newfield.Brookston;
}
field_list_calculation Sprout {
    input {
        Harlem;
    }
    algorithm : identity;
    output_width : 51;
}
action_selector Toano {
    selection_key : Sprout;
    selection_mode : resilient;
}
action Cotuit(Arthur) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Arthur);
}
action_profile Dowell {
    actions {
        Cotuit;
        Rosburg;
    }
    size : 1024;
    dynamic_action_selection : Toano;
}
table Manilla {
   reads {
      PineCity.Okaton : exact;
   }
   action_profile: Dowell;
   size : 1024;
}
control Nelagoney {
   if ((PineCity.Okaton & 0x2000) == 0x2000) {
      apply(Manilla);
   }
}
action Jesup() {
   modify_field(PineCity.Oakville, Gerster.Corona);
   modify_field(PineCity.Elsmere, Gerster.Halsey);
   modify_field(PineCity.Bleecker, Gerster.Tillamook);
   modify_field(PineCity.Udall, Gerster.Rohwer);
   modify_field(PineCity.Cadott, Gerster.Holtville);
   invalidate( ig_intr_md_for_tm.ucast_egress_port );
}
table Hoagland {
   actions {
      Jesup;
   }
   default_action : Jesup();
   size : 1;
}
control Kotzebue {
   apply( Hoagland );
}
action Lepanto() {
   modify_field(PineCity.Freedom, 1);
   modify_field(PineCity.Woodland, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Gerster.Highfill);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, PineCity.Cadott);
}
action Elimsport() {
}
@pragma ways 1
table Poulsbo {
   reads {
      PineCity.Oakville : exact;
      PineCity.Elsmere : exact;
   }
   actions {
      Lepanto;
      Elimsport;
   }
   default_action : Elimsport;
   size : 1;
}
action Hoven() {
   modify_field(PineCity.Crozet, 1);
   modify_field(PineCity.Fernway, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, PineCity.Cadott, 4096);
}
table Alamance {
   actions {
      Hoven;
   }
   default_action : Hoven;
   size : 1;
}
action Troup() {
   modify_field(PineCity.Westville, 1);
   modify_field(PineCity.Woodland, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, PineCity.Cadott);
}
table Alden {
   actions {
      Troup;
   }
   default_action : Troup();
   size : 1;
}
action Darien(Hopeton) {
   modify_field(PineCity.Castle, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Hopeton);
   modify_field(PineCity.Okaton, Hopeton);
}
action Wadley(Moseley) {
   modify_field(PineCity.Crozet, 1);
   modify_field(PineCity.Mickleton, Moseley);
}
action Lincroft() {
}
table Brodnax {
   reads {
      PineCity.Oakville : exact;
      PineCity.Elsmere : exact;
      PineCity.Cadott : exact;
   }
   actions {
      Darien;
      Wadley;
      Ronneby;
      Lincroft;
   }
   default_action : Lincroft();
   size : 65536;
}
control ElDorado {
   if (Gerster.Clarkdale == 0 and not valid(PineHill) ) {
      apply(Brodnax) {
         Lincroft {
            apply(Poulsbo) {
               Elimsport {
                  if ((PineCity.Oakville & 0x010000) == 0x010000) {
                     apply(Alamance);
                  } else {
                     apply(Alden);
                  }
               }
            }
         }
      }
   }
}
action Ebenezer() {
   modify_field(Gerster.OjoFeliz, 1);
   Ronneby();
}
table BoyRiver {
   actions {
      Ebenezer;
   }
   default_action : Ebenezer;
   size : 1;
}
control RockyGap {
   if (Gerster.Clarkdale == 0) {
      if ((PineCity.Knierim==0) and (Gerster.August==0) and (Gerster.Pownal==0) and (Gerster.Paisley==PineCity.Okaton)) {
         apply(BoyRiver);
      } else {
         Nelagoney();
      }
   }
}
action Trilby( Union ) {
   modify_field( PineCity.Monkstown, Union );
}
action Gobles() {
   modify_field( PineCity.Monkstown, PineCity.Cadott );
}
table Arvada {
   reads {
      eg_intr_md.egress_port : exact;
      PineCity.Cadott : exact;
   }
   actions {
      Trilby;
      Gobles;
   }
   default_action : Gobles;
   size : 4096;
}
control Onycha {
   apply( Arvada );
}
action Benwood( Hiawassee, Valencia ) {
   modify_field( PineCity.Stoutland, Hiawassee );
   modify_field( PineCity.Grays, Valencia );
}
table Lewellen {
   reads {
      PineCity.Linville : exact;
   }
   actions {
      Benwood;
   }
   size : 8;
}
action SoapLake() {
   modify_field( PineCity.Canton, 1 );
   modify_field( PineCity.Linville, 2 );
}
action Wymer() {
   modify_field( PineCity.Canton, 1 );
   modify_field( PineCity.Linville, 1 );
}
table Power {
   reads {
      PineCity.Lenox : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      SoapLake;
      Wymer;
   }
   default_action : Rosburg();
   size : 16;
}
action Tallevast(Suarez, LaPryor, FairPlay, Lyndell) {
   modify_field( PineCity.Hartville, Suarez );
   modify_field( PineCity.Horns, LaPryor );
   modify_field( PineCity.Wollochet, FairPlay );
   modify_field( PineCity.Trammel, Lyndell );
}
table Baraboo {
   reads {
        PineCity.Bernard : exact;
   }
   actions {
      Tallevast;
   }
   size : 256;
}
action Camden() {
   no_op();
}
action Ackerman() {
   modify_field( Heeia.Sarepta, Wamesit[0].Butler );
   remove_header( Wamesit[0] );
}
table Bothwell {
   actions {
      Ackerman;
   }
   default_action : Ackerman;
   size : 1;
}
action Nicollet() {
   no_op();
}
action Kalskag() {
   add_header( Wamesit[ 0 ] );
   modify_field( Wamesit[0].Denmark, PineCity.Monkstown );
   modify_field( Wamesit[0].Butler, Heeia.Sarepta );
   modify_field( Wamesit[0].Yakutat, Lublin.Topmost );
   modify_field( Wamesit[0].Crowheart, Lublin.Earling );
   modify_field( Heeia.Sarepta, 0x8100 );
}
table Coachella {
   reads {
      PineCity.Monkstown : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Nicollet;
      Kalskag;
   }
   default_action : Kalskag;
   size : 128;
}
action Osage() {
   modify_field(Heeia.Bairoa, PineCity.Oakville);
   modify_field(Heeia.Burnett, PineCity.Elsmere);
   modify_field(Heeia.Harmony, PineCity.Stoutland);
   modify_field(Heeia.Brundage, PineCity.Grays);
}
action Trion() {
   Osage();
   add_to_field(Maljamar.Disney, -1);
   modify_field(Maljamar.Hearne, Lublin.Sagerton);
}
action Salineno() {
   Osage();
   add_to_field(Skyforest.Alberta, -1);
   modify_field(Skyforest.Nephi, Lublin.Sagerton);
}
action Ricketts() {
   modify_field(Maljamar.Hearne, Lublin.Sagerton);
}
action Vinemont() {
   modify_field(Skyforest.Nephi, Lublin.Sagerton);
}
action Monteview() {
   Kalskag();
}
action Pittsboro( Monowi, Beaverdam, Bangor, Powhatan ) {
   add_header( Littleton );
   modify_field( Littleton.Bairoa, Monowi );
   modify_field( Littleton.Burnett, Beaverdam );
   modify_field( Littleton.Harmony, Bangor );
   modify_field( Littleton.Brundage, Powhatan );
   modify_field( Littleton.Sarepta, 0xBF00 );
   add_header( PineHill );
   modify_field( PineHill.Rotonda, PineCity.Hartville );
   modify_field( PineHill.Edwards, PineCity.Horns );
   modify_field( PineHill.MintHill, PineCity.Wollochet );
   modify_field( PineHill.Florida, PineCity.Trammel );
   modify_field( PineHill.Amonate, PineCity.Maida );
}
action Caguas() {
   remove_header( Blossom );
   remove_header( Leacock );
   remove_header( Emmorton );
   copy_header( Heeia, Millikin );
   remove_header( Millikin );
   remove_header( Maljamar );
}
action Clearco() {
   remove_header( Littleton );
   remove_header( PineHill );
}
action Dunnellon() {
   Caguas();
   modify_field(Tiverton.Hearne, Lublin.Sagerton);
}
action Grayland() {
   Caguas();
   modify_field(Goree.Nephi, Lublin.Sagerton);
}
table Protem {
   reads {
      PineCity.DeRidder : exact;
      PineCity.Linville : exact;
      PineCity.Knierim : exact;
      Maljamar.valid : ternary;
      Skyforest.valid : ternary;
      Tiverton.valid : ternary;
      Goree.valid : ternary;
   }
   actions {
      Trion;
      Salineno;
      Ricketts;
      Vinemont;
      Monteview;
      Pittsboro;
      Clearco;
      Caguas;
      Dunnellon;
      Grayland;
   }
   size : 512;
}
control WindGap {
   apply( Bothwell );
}
control Melvina {
   apply( Coachella );
}
control Ringtown {
   apply( Power ) {
      Rosburg {
         apply( Lewellen );
      }
   }
   apply( Baraboo );
   apply( Protem );
}
field_list Kupreanof {
    Trona.Accomac;
    Gerster.Holtville;
    Millikin.Harmony;
    Millikin.Brundage;
    Maljamar.Haines;
}
action Camilla() {
   generate_digest(0, Kupreanof);
}
table Ellisburg {
   actions {
      Camilla;
   }
   default_action : Camilla;
   size : 1;
}
control Belcourt {
   if (Gerster.Weyauwega == 1) {
      apply(Ellisburg);
   }
}
action RedCliff() {
   modify_field( Lublin.Topmost, Acree.Knights );
}
action Pound() {
   modify_field( Lublin.Topmost, Wamesit[0].Yakutat );
   modify_field( Gerster.Lazear, Wamesit[0].Butler );
}
action Pendroy() {
   modify_field( Lublin.Sagerton, Acree.Pinecreek );
}
action Gould() {
   modify_field( Lublin.Sagerton, WestBay.Clarks );
}
action Terlingua() {
   modify_field( Lublin.Sagerton, Kingsgate.Moark );
}
action Radcliffe( Alcalde, Milam ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Alcalde );
   modify_field( ig_intr_md_for_tm.qid, Milam );
}
table Firesteel {
   reads {
     Gerster.Altus : exact;
   }
   actions {
     RedCliff;
     Pound;
   }
   size : 2;
}
table DosPalos {
   reads {
     Gerster.Lecompte : exact;
     Gerster.Ontonagon : exact;
   }
   actions {
     Pendroy;
     Gould;
     Terlingua;
   }
   size : 3;
}
table Kokadjo {
   reads {
      Acree.Carlin : ternary;
      Acree.Knights : ternary;
      Lublin.Topmost : ternary;
      Lublin.Sagerton : ternary;
      Lublin.Benkelman : ternary;
   }
   actions {
      Radcliffe;
   }
   size : 81;
}
action Enderlin( Samantha, Brawley ) {
   bit_or( Lublin.Myrick, Lublin.Myrick, Samantha );
   bit_or( Lublin.Ignacio, Lublin.Ignacio, Brawley );
}
table Eldred {
   actions {
      Enderlin;
   }
   default_action : Enderlin(0, 0);
   size : 1;
}
action Armagh( Pengilly ) {
   modify_field( Lublin.Sagerton, Pengilly );
}
action UtePark( BigLake ) {
   modify_field( Lublin.Topmost, BigLake );
}
action Huttig( Croft, Sargent ) {
   modify_field( Lublin.Topmost, Croft );
   modify_field( Lublin.Sagerton, Sargent );
}
table Bokeelia {
   reads {
      Acree.Carlin : exact;
      Lublin.Myrick : exact;
      Lublin.Ignacio : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Armagh;
      UtePark;
      Huttig;
   }
   size : 512;
}
control Champlain {
   apply( Firesteel );
   apply( DosPalos );
}
control Trujillo {
   apply( Kokadjo );
}
control Powderly {
   apply( Eldred );
   apply( Bokeelia );
}
action Bledsoe( Bayne ) {
   modify_field( Lublin.Tontogany, Bayne );
}
action Lundell( LakeFork, Eastman ) {
   Bledsoe( LakeFork );
   modify_field( ig_intr_md_for_tm.qid, Eastman );
}
table Dorris {
   reads {
      PineCity.Newfolden : ternary;
      ig_intr_md_for_tm.copy_to_cpu : ternary;
      PineCity.Maida : ternary;
      Gerster.Lecompte : ternary;
      Gerster.Ontonagon : ternary;
      Gerster.Lazear : ternary;
      Gerster.Glenmora : ternary;
      Gerster.FourTown : ternary;
      PineCity.Knierim : ternary;
      Emmorton.Farlin : ternary;
      Emmorton.Thalmann : ternary;
   }
   actions {
      Bledsoe;
      Lundell;
   }
   size : 512;
}
meter Hooks {
   type : packets;
   static : Perma;
   instance_count : 2304;
}
action Vibbard(McCaulley) {
   execute_meter( Hooks, McCaulley, ig_intr_md_for_tm.packet_color );
}
table Perma {
   reads {
      Acree.Leetsdale : exact;
      Lublin.Tontogany : exact;
   }
   actions {
      Vibbard;
   }
   size : 2304;
}
control RichBar {
   if ( Acree.Louviers != 0 ) {
      apply( Dorris );
   }
}
control Lefor {
    if ( (
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x1 ) == 0 ) ) and ( PineCity.Newfolden == 1 ) ) or
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x2 ) == 0 ) ) and ( ig_intr_md_for_tm.copy_to_cpu == 1 ) )
       ) ) {
      apply( Perma );
   }
}
action Cascade( Maury ) {
   modify_field( PineCity.Lenox, 0 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Maury );
   modify_field( PineCity.Bernard, ig_intr_md.ingress_port );
}
action Columbia( Excello ) {
   modify_field( PineCity.Lenox, 1 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Excello );
   modify_field( PineCity.Bernard, ig_intr_md.ingress_port );
}
action Jenera() {
   modify_field( PineCity.Lenox, 0 );
}
action Shields() {
   modify_field( PineCity.Lenox, 1 );
   modify_field( PineCity.Bernard, ig_intr_md.ingress_port );
}
@pragma ternary 1
table CassCity {
   reads {
      PineCity.Newfolden : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      IdaGrove.Virgilina : exact;
      Acree.Placida : ternary;
      PineCity.Maida : ternary;
   }
   actions {
      Cascade;
      Columbia;
      Jenera;
      Shields;
   }
   size : 512;
}
control Greycliff {
   apply( CassCity );
}
counter Tatitlek {
   type : packets_and_bytes;
   instance_count : 1024;
   min_width : 128;
}
action Shipman( Groesbeck ) {
   count( Tatitlek, Groesbeck );
}
table LasLomas {
   reads {
      eg_intr_md.egress_port mask 0x7f: exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }
   actions {
     Shipman;
   }
   size : 1024;
}
control Hayfield {
   apply( LasLomas );
}
action Norseland()
{
   Ronneby();
}
action Orrick()
{
   modify_field(PineCity.DeRidder, 2);
   bit_or(PineCity.Okaton, 0x2000, PineHill.Florida);
}
action LeSueur( Renfroe ) {
   modify_field(PineCity.DeRidder, 2);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Renfroe);
   modify_field(PineCity.Okaton, Renfroe);
}
table Senatobia {
   reads {
      PineHill.Rotonda : exact;
      PineHill.Edwards : exact;
      PineHill.MintHill : exact;
      PineHill.Florida : exact;
   }
   actions {
      Orrick;
      LeSueur;
      Norseland;
   }
   default_action : Norseland();
   size : 256;
}
control Micco {
   apply( Senatobia );
}
action Yorklyn( Amanda, Miranda, BigRock, Chambers ) {
   modify_field( Frankston.Ossipee, Amanda );
   modify_field( Ringold.Chubbuck, BigRock );
   modify_field( Ringold.BayPort, Miranda );
   modify_field( Ringold.Vevay, Chambers );
}
table Wenham {
   reads {
     WestBay.Maxwelton : exact;
     Gerster.Naches : exact;
   }
   actions {
      Yorklyn;
   }
  size : 16384;
}
action Anacortes(Bettles, Sherando, Magazine) {
   modify_field( Ringold.BayPort, Bettles );
   modify_field( Ringold.Chubbuck, Sherando );
   modify_field( Ringold.Vevay, Magazine );
}
table Rodeo {
   reads {
     WestBay.Pembine : exact;
     Frankston.Ossipee : exact;
   }
   actions {
      Anacortes;
   }
   size : 16384;
}
action Snohomish( Abbott, FlatRock, Perryman ) {
   modify_field( Chenequa.Bagdad, Abbott );
   modify_field( Chenequa.Tiller, FlatRock );
   modify_field( Chenequa.Gerlach, Perryman );
}
table LaPointe {
   reads {
     PineCity.Oakville : exact;
     PineCity.Elsmere : exact;
     PineCity.Cadott : exact;
   }
   actions {
      Snohomish;
   }
   size : 16384;
}
action Cornwall() {
   modify_field( PineCity.Woodland, 1 );
}
action Youngwood( Lindsay ) {
   Cornwall();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Ringold.BayPort );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Lindsay, Ringold.Vevay );
}
action Sparr( Ramah ) {
   Cornwall();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Chenequa.Bagdad );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Ramah, Chenequa.Gerlach );
}
action Nettleton( Colburn ) {
   Cornwall();
   add( ig_intr_md_for_tm.mcast_grp_a, PineCity.Cadott,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Colburn );
}
action Perdido() {
   modify_field( PineCity.Wakeman, 1 );
}
table Cogar {
   reads {
     Ringold.Chubbuck : ternary;
     Ringold.BayPort : ternary;
     Chenequa.Bagdad : ternary;
     Chenequa.Tiller : ternary;
     Gerster.Glenmora :ternary;
     Gerster.August:ternary;
   }
   actions {
      Youngwood;
      Sparr;
      Nettleton;
      Perdido;
   }
   size : 32;
}
control Wellsboro {
   if( Gerster.Clarkdale == 0 and
       IdaGrove.Sharptown == 1 and
       Gerster.Coronado == 1 ) {
      apply( Wenham );
   }
}
control Saranap {
   if( Frankston.Ossipee != 0 ) {
      apply( Rodeo );
   }
}
control Charenton {
   if( Gerster.Clarkdale == 0 and Gerster.August==1 ) {
      apply( LaPointe );
   }
}
control Ahuimanu {
   if( Gerster.August == 1 ) {
      apply(Cogar);
   }
}
action Macksburg(Westway) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Newfield.Brookston );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Westway );
}
table Talco {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Macksburg;
    }
    size : 512;
}
control Vandling {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Talco);
   }
}
action Purley( Lewis, Ironia ) {
   modify_field( PineCity.Cadott, Lewis );
   modify_field( PineCity.Knierim, Ironia );
}
action Normangee() {
   drop();
}
table Catawba {
   reads {
     eg_intr_md.egress_rid: exact;
   }
   actions {
      Purley;
   }
   default_action: Normangee;
   size : 57344;
}
control Bassett {
   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Catawba);
   }
}
counter Gypsum {
   type : packets;
   direct: Ogunquit;
   min_width: 63;
}
table Ogunquit {
   reads {
     Boyle.Darmstadt mask 0x7fff : exact;
   }
   actions {
      Rosburg;
   }
   default_action: Rosburg();
   size : 32768;
}
action Stuttgart() {
   modify_field( Stillmore.Nixon, Gerster.Glenmora );
   modify_field( Stillmore.Hookdale, WestBay.Clarks );
   modify_field( Stillmore.Rumson, Gerster.FourTown );
   modify_field( Stillmore.Buenos, Gerster.Bostic );
   bit_xor( Stillmore.Lostwood, Gerster.Ewing, 1 );
}
action Moorman() {
   modify_field( Stillmore.Nixon, Gerster.Glenmora );
   modify_field( Stillmore.Hookdale, Kingsgate.Moark );
   modify_field( Stillmore.Rumson, Gerster.FourTown );
   modify_field( Stillmore.Buenos, Gerster.Bostic );
   bit_xor( Stillmore.Lostwood, Gerster.Ewing, 1 );
}
action Battles( Dalkeith, Cragford ) {
   Stuttgart();
   modify_field( Stillmore.Beasley, Dalkeith );
   modify_field( IdaGrove.Wimberley, Cragford );
}
action Mayflower( Pittsburg, Slovan ) {
   Moorman();
   modify_field( Stillmore.Beasley, Pittsburg );
   modify_field( IdaGrove.Wimberley, Slovan );
}
table Telida {
   reads {
     WestBay.Pembine : ternary;
   }
   actions {
      Battles;
   }
   default_action : Stuttgart;
  size : 2048;
}
table Kelvin {
   reads {
     Kingsgate.Swedeborg : ternary;
   }
   actions {
      Mayflower;
   }
   default_action : Moorman;
   size : 1024;
}
action Papeton( Handley, Madawaska ) {
   modify_field( Stillmore.Perkasie, Handley );
   modify_field( IdaGrove.Henrietta, Madawaska );
}
table KawCity {
   reads {
     WestBay.Maxwelton : ternary;
   }
   actions {
      Papeton;
   }
   size : 512;
}
table Florala {
   reads {
     Kingsgate.Unity : ternary;
   }
   actions {
      Papeton;
   }
   size : 512;
}
action Mumford( Wenona ) {
   modify_field( Stillmore.Triplett, Wenona );
}
table Shuqualak {
   reads {
     Gerster.Yardville : ternary;
   }
   actions {
      Mumford;
   }
   size : 512;
}
action Pelion( Bemis ) {
   modify_field( Stillmore.Waterflow, Bemis );
}
table Swenson {
   reads {
     Gerster.Leawood : ternary;
   }
   actions {
      Pelion;
   }
   size : 512;
}
action Hahira( Shelbina ) {
   modify_field( Stillmore.Perrytown, Shelbina );
}
action Caborn( Whitten ) {
   modify_field( Stillmore.Perrytown, Whitten );
}
table Bucklin {
   reads {
     Gerster.Lecompte : exact;
     Gerster.Ontonagon : exact;
     Gerster.Brunson : exact;
     Gerster.Naches : exact;
   }
   actions {
      Hahira;
      Rosburg;
   }
   default_action : Rosburg();
   size : 4096;
}
table OldTown {
   reads {
     Gerster.Lecompte : exact;
     Gerster.Ontonagon : exact;
     Gerster.Brunson : exact;
     Acree.Pierre : exact;
   }
   actions {
      Caborn;
   }
   size : 512;
}
control Burwell {
   if( Gerster.Lecompte == 1 ) {
      apply( Telida );
      apply( KawCity );
   } else if( Gerster.Ontonagon == 1 ) {
      apply( Kelvin );
      apply( Florala );
   }
   if( ( Gerster.Farthing != 0 and Gerster.Bluff == 1 ) or
       ( Gerster.Farthing == 0 and Emmorton.valid == 1 ) ) {
      apply( Shuqualak );
      if( Gerster.Glenmora != 1 ){
         apply( Swenson );
      }
   }
   apply( Bucklin ) {
      Rosburg {
         apply( OldTown );
      }
   }
}
action DeLancey() {
}
action Piney() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action Lumberton() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
}
action Palatine() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 1 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
table Pricedale {
   reads {
     Boyle.Darmstadt mask 0x00018000 : ternary;
   }
   actions {
      DeLancey;
      Piney;
      Lumberton;
      Palatine;
   }
   size : 16;
}
control Linganore {
   apply( Pricedale );
   apply( Ogunquit );
}
   metadata Levittown Boyle;
   action Connell( RoseTree ) {
          max( Boyle.Darmstadt, Boyle.Darmstadt, RoseTree );
   }
@pragma ways 4
table Sunset {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : exact;
      Stillmore.Perkasie : exact;
      Stillmore.Triplett : exact;
      Stillmore.Waterflow : exact;
      Stillmore.Nixon : exact;
      Stillmore.Hookdale : exact;
      Stillmore.Rumson : exact;
      Stillmore.Buenos : exact;
      Stillmore.Lostwood : exact;
   }
   actions {
      Connell;
   }
   size : 4096;
}
control Hamburg {
   apply( Sunset );
}
table Billett {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : ternary;
      Stillmore.Perkasie : ternary;
      Stillmore.Triplett : ternary;
      Stillmore.Waterflow : ternary;
      Stillmore.Nixon : ternary;
      Stillmore.Hookdale : ternary;
      Stillmore.Rumson : ternary;
      Stillmore.Buenos : ternary;
      Stillmore.Lostwood : ternary;
   }
   actions {
      Connell;
   }
   size : 512;
}
control Villanova {
   apply( Billett );
}
@pragma pa_no_init ingress Helotes.Beasley
@pragma pa_no_init ingress Helotes.Perkasie
@pragma pa_no_init ingress Helotes.Triplett
@pragma pa_no_init ingress Helotes.Waterflow
@pragma pa_no_init ingress Helotes.Nixon
@pragma pa_no_init ingress Helotes.Hookdale
@pragma pa_no_init ingress Helotes.Rumson
@pragma pa_no_init ingress Helotes.Buenos
@pragma pa_no_init ingress Helotes.Lostwood
metadata Chaires Helotes;
@pragma ways 4
table Cheyenne {
   reads {
      Stillmore.Perrytown : exact;
      Helotes.Beasley : exact;
      Helotes.Perkasie : exact;
      Helotes.Triplett : exact;
      Helotes.Waterflow : exact;
      Helotes.Nixon : exact;
      Helotes.Hookdale : exact;
      Helotes.Rumson : exact;
      Helotes.Buenos : exact;
      Helotes.Lostwood : exact;
   }
   actions {
      Connell;
   }
   size : 8192;
}
action Libby( Wittman, Bajandas, Otisco, Keachi, Mulliken, Korona, Dugger, Occoquan, Hammocks ) {
   bit_and( Helotes.Beasley, Stillmore.Beasley, Wittman );
   bit_and( Helotes.Perkasie, Stillmore.Perkasie, Bajandas );
   bit_and( Helotes.Triplett, Stillmore.Triplett, Otisco );
   bit_and( Helotes.Waterflow, Stillmore.Waterflow, Keachi );
   bit_and( Helotes.Nixon, Stillmore.Nixon, Mulliken );
   bit_and( Helotes.Hookdale, Stillmore.Hookdale, Korona );
   bit_and( Helotes.Rumson, Stillmore.Rumson, Dugger );
   bit_and( Helotes.Buenos, Stillmore.Buenos, Occoquan );
   bit_and( Helotes.Lostwood, Stillmore.Lostwood, Hammocks );
}
table Parkland {
   reads {
      Stillmore.Perrytown : exact;
   }
   actions {
      Libby;
   }
   default_action : Libby(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Hubbell {
   apply( Parkland );
}
control Greenhorn {
   apply( Cheyenne );
}
table Paxico {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : ternary;
      Stillmore.Perkasie : ternary;
      Stillmore.Triplett : ternary;
      Stillmore.Waterflow : ternary;
      Stillmore.Nixon : ternary;
      Stillmore.Hookdale : ternary;
      Stillmore.Rumson : ternary;
      Stillmore.Buenos : ternary;
      Stillmore.Lostwood : ternary;
   }
   actions {
      Connell;
   }
   size : 512;
}
control Mooreland {
   apply( Paxico );
}
@pragma ways 4
table Bains {
   reads {
      Stillmore.Perrytown : exact;
      Helotes.Beasley : exact;
      Helotes.Perkasie : exact;
      Helotes.Triplett : exact;
      Helotes.Waterflow : exact;
      Helotes.Nixon : exact;
      Helotes.Hookdale : exact;
      Helotes.Rumson : exact;
      Helotes.Buenos : exact;
      Helotes.Lostwood : exact;
   }
   actions {
      Connell;
   }
   size : 4096;
}
action Oakford( Bovina, Kapaa, Kellner, Almond, Syria, Dilia, Dennison, Cowley, Lakehurst ) {
   bit_and( Helotes.Beasley, Stillmore.Beasley, Bovina );
   bit_and( Helotes.Perkasie, Stillmore.Perkasie, Kapaa );
   bit_and( Helotes.Triplett, Stillmore.Triplett, Kellner );
   bit_and( Helotes.Waterflow, Stillmore.Waterflow, Almond );
   bit_and( Helotes.Nixon, Stillmore.Nixon, Syria );
   bit_and( Helotes.Hookdale, Stillmore.Hookdale, Dilia );
   bit_and( Helotes.Rumson, Stillmore.Rumson, Dennison );
   bit_and( Helotes.Buenos, Stillmore.Buenos, Cowley );
   bit_and( Helotes.Lostwood, Stillmore.Lostwood, Lakehurst );
}
table Torrance {
   reads {
      Stillmore.Perrytown : exact;
   }
   actions {
      Oakford;
   }
   default_action : Oakford(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Elyria {
   apply( Torrance );
}
control Fennimore {
   apply( Bains );
}
table Fairborn {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : ternary;
      Stillmore.Perkasie : ternary;
      Stillmore.Triplett : ternary;
      Stillmore.Waterflow : ternary;
      Stillmore.Nixon : ternary;
      Stillmore.Hookdale : ternary;
      Stillmore.Rumson : ternary;
      Stillmore.Buenos : ternary;
      Stillmore.Lostwood : ternary;
   }
   actions {
      Connell;
   }
   size : 512;
}
control Pfeifer {
   apply( Fairborn );
}
@pragma ways 4
table Absarokee {
   reads {
      Stillmore.Perrytown : exact;
      Helotes.Beasley : exact;
      Helotes.Perkasie : exact;
      Helotes.Triplett : exact;
      Helotes.Waterflow : exact;
      Helotes.Nixon : exact;
      Helotes.Hookdale : exact;
      Helotes.Rumson : exact;
      Helotes.Buenos : exact;
      Helotes.Lostwood : exact;
   }
   actions {
      Connell;
   }
   size : 4096;
}
action Eldena( Kisatchie, Picayune, Cedonia, Hamel, Bolckow, Lamison, Ludowici, Biehle, Helen ) {
   bit_and( Helotes.Beasley, Stillmore.Beasley, Kisatchie );
   bit_and( Helotes.Perkasie, Stillmore.Perkasie, Picayune );
   bit_and( Helotes.Triplett, Stillmore.Triplett, Cedonia );
   bit_and( Helotes.Waterflow, Stillmore.Waterflow, Hamel );
   bit_and( Helotes.Nixon, Stillmore.Nixon, Bolckow );
   bit_and( Helotes.Hookdale, Stillmore.Hookdale, Lamison );
   bit_and( Helotes.Rumson, Stillmore.Rumson, Ludowici );
   bit_and( Helotes.Buenos, Stillmore.Buenos, Biehle );
   bit_and( Helotes.Lostwood, Stillmore.Lostwood, Helen );
}
table Sheldahl {
   reads {
      Stillmore.Perrytown : exact;
   }
   actions {
      Eldena;
   }
   default_action : Eldena(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Drake {
   apply( Sheldahl );
}
control Hollymead {
   apply( Absarokee );
}
table Humacao {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : ternary;
      Stillmore.Perkasie : ternary;
      Stillmore.Triplett : ternary;
      Stillmore.Waterflow : ternary;
      Stillmore.Nixon : ternary;
      Stillmore.Hookdale : ternary;
      Stillmore.Rumson : ternary;
      Stillmore.Buenos : ternary;
      Stillmore.Lostwood : ternary;
   }
   actions {
      Connell;
   }
   size : 512;
}
control Faulkton {
   apply( Humacao );
}
@pragma ways 4
table Oldsmar {
   reads {
      Stillmore.Perrytown : exact;
      Helotes.Beasley : exact;
      Helotes.Perkasie : exact;
      Helotes.Triplett : exact;
      Helotes.Waterflow : exact;
      Helotes.Nixon : exact;
      Helotes.Hookdale : exact;
      Helotes.Rumson : exact;
      Helotes.Buenos : exact;
      Helotes.Lostwood : exact;
   }
   actions {
      Connell;
   }
   size : 8192;
}
action Mather( ElkMills, Alnwick, Fannett, Jenkins, Troutman, Dassel, Mattapex, Beaverton, Talkeetna ) {
   bit_and( Helotes.Beasley, Stillmore.Beasley, ElkMills );
   bit_and( Helotes.Perkasie, Stillmore.Perkasie, Alnwick );
   bit_and( Helotes.Triplett, Stillmore.Triplett, Fannett );
   bit_and( Helotes.Waterflow, Stillmore.Waterflow, Jenkins );
   bit_and( Helotes.Nixon, Stillmore.Nixon, Troutman );
   bit_and( Helotes.Hookdale, Stillmore.Hookdale, Dassel );
   bit_and( Helotes.Rumson, Stillmore.Rumson, Mattapex );
   bit_and( Helotes.Buenos, Stillmore.Buenos, Beaverton );
   bit_and( Helotes.Lostwood, Stillmore.Lostwood, Talkeetna );
}
table Gregory {
   reads {
      Stillmore.Perrytown : exact;
   }
   actions {
      Mather;
   }
   default_action : Mather(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Millsboro {
   apply( Gregory );
}
control Meservey {
   apply( Oldsmar );
}
table Arkoe {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : ternary;
      Stillmore.Perkasie : ternary;
      Stillmore.Triplett : ternary;
      Stillmore.Waterflow : ternary;
      Stillmore.Nixon : ternary;
      Stillmore.Hookdale : ternary;
      Stillmore.Rumson : ternary;
      Stillmore.Buenos : ternary;
      Stillmore.Lostwood : ternary;
   }
   actions {
      Connell;
   }
   size : 512;
}
control Bouton {
   apply( Arkoe );
}
@pragma ways 4
table NorthRim {
   reads {
      Stillmore.Perrytown : exact;
      Helotes.Beasley : exact;
      Helotes.Perkasie : exact;
      Helotes.Triplett : exact;
      Helotes.Waterflow : exact;
      Helotes.Nixon : exact;
      Helotes.Hookdale : exact;
      Helotes.Rumson : exact;
      Helotes.Buenos : exact;
      Helotes.Lostwood : exact;
   }
   actions {
      Connell;
   }
   size : 8192;
}
action Petoskey( Duchesne, Clarinda, TinCity, Heizer, Lizella, Towaoc, Mabank, CleElum, Protivin ) {
   bit_and( Helotes.Beasley, Stillmore.Beasley, Duchesne );
   bit_and( Helotes.Perkasie, Stillmore.Perkasie, Clarinda );
   bit_and( Helotes.Triplett, Stillmore.Triplett, TinCity );
   bit_and( Helotes.Waterflow, Stillmore.Waterflow, Heizer );
   bit_and( Helotes.Nixon, Stillmore.Nixon, Lizella );
   bit_and( Helotes.Hookdale, Stillmore.Hookdale, Towaoc );
   bit_and( Helotes.Rumson, Stillmore.Rumson, Mabank );
   bit_and( Helotes.Buenos, Stillmore.Buenos, CleElum );
   bit_and( Helotes.Lostwood, Stillmore.Lostwood, Protivin );
}
table Gilman {
   reads {
      Stillmore.Perrytown : exact;
   }
   actions {
      Petoskey;
   }
   default_action : Petoskey(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Hephzibah {
   apply( Gilman );
}
control Cotter {
   apply( NorthRim );
}
table Redondo {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : ternary;
      Stillmore.Perkasie : ternary;
      Stillmore.Triplett : ternary;
      Stillmore.Waterflow : ternary;
      Stillmore.Nixon : ternary;
      Stillmore.Hookdale : ternary;
      Stillmore.Rumson : ternary;
      Stillmore.Buenos : ternary;
      Stillmore.Lostwood : ternary;
   }
   actions {
      Connell;
   }
   size : 512;
}
control Pavillion {
   apply( Redondo );
}
@pragma ways 4
table McBrides {
   reads {
      Stillmore.Perrytown : exact;
      Helotes.Beasley : exact;
      Helotes.Perkasie : exact;
      Helotes.Triplett : exact;
      Helotes.Waterflow : exact;
      Helotes.Nixon : exact;
      Helotes.Hookdale : exact;
      Helotes.Rumson : exact;
      Helotes.Buenos : exact;
      Helotes.Lostwood : exact;
   }
   actions {
      Connell;
   }
   size : 4096;
}
action Parksley( Orrstown, Marvin, Hewitt, Kniman, Timbo, Laton, Aguila, Waipahu, Campton ) {
   bit_and( Helotes.Beasley, Stillmore.Beasley, Orrstown );
   bit_and( Helotes.Perkasie, Stillmore.Perkasie, Marvin );
   bit_and( Helotes.Triplett, Stillmore.Triplett, Hewitt );
   bit_and( Helotes.Waterflow, Stillmore.Waterflow, Kniman );
   bit_and( Helotes.Nixon, Stillmore.Nixon, Timbo );
   bit_and( Helotes.Hookdale, Stillmore.Hookdale, Laton );
   bit_and( Helotes.Rumson, Stillmore.Rumson, Aguila );
   bit_and( Helotes.Buenos, Stillmore.Buenos, Waipahu );
   bit_and( Helotes.Lostwood, Stillmore.Lostwood, Campton );
}
table Meeker {
   reads {
      Stillmore.Perrytown : exact;
   }
   actions {
      Parksley;
   }
   default_action : Parksley(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Humble {
   apply( Meeker );
}
control Netarts {
   apply( McBrides );
}
table Raynham {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : ternary;
      Stillmore.Perkasie : ternary;
      Stillmore.Triplett : ternary;
      Stillmore.Waterflow : ternary;
      Stillmore.Nixon : ternary;
      Stillmore.Hookdale : ternary;
      Stillmore.Rumson : ternary;
      Stillmore.Buenos : ternary;
      Stillmore.Lostwood : ternary;
   }
   actions {
      Connell;
   }
   size : 512;
}
control Hernandez {
   apply( Raynham );
}
@pragma ways 4
table Minneota {
   reads {
      Stillmore.Perrytown : exact;
      Helotes.Beasley : exact;
      Helotes.Perkasie : exact;
      Helotes.Triplett : exact;
      Helotes.Waterflow : exact;
      Helotes.Nixon : exact;
      Helotes.Hookdale : exact;
      Helotes.Rumson : exact;
      Helotes.Buenos : exact;
      Helotes.Lostwood : exact;
   }
   actions {
      Connell;
   }
   size : 4096;
}
action Sargeant( Shabbona, Comal, Westland, Cloverly, Retrop, WestCity, Ottertail, Neosho, Valmont ) {
   bit_and( Helotes.Beasley, Stillmore.Beasley, Shabbona );
   bit_and( Helotes.Perkasie, Stillmore.Perkasie, Comal );
   bit_and( Helotes.Triplett, Stillmore.Triplett, Westland );
   bit_and( Helotes.Waterflow, Stillmore.Waterflow, Cloverly );
   bit_and( Helotes.Nixon, Stillmore.Nixon, Retrop );
   bit_and( Helotes.Hookdale, Stillmore.Hookdale, WestCity );
   bit_and( Helotes.Rumson, Stillmore.Rumson, Ottertail );
   bit_and( Helotes.Buenos, Stillmore.Buenos, Neosho );
   bit_and( Helotes.Lostwood, Stillmore.Lostwood, Valmont );
}
table CedarKey {
   reads {
      Stillmore.Perrytown : exact;
   }
   actions {
      Sargeant;
   }
   default_action : Sargeant(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Kenvil {
   apply( CedarKey );
}
control Stockdale {
   apply( Minneota );
}
table Veguita {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : ternary;
      Stillmore.Perkasie : ternary;
      Stillmore.Triplett : ternary;
      Stillmore.Waterflow : ternary;
      Stillmore.Nixon : ternary;
      Stillmore.Hookdale : ternary;
      Stillmore.Rumson : ternary;
      Stillmore.Buenos : ternary;
      Stillmore.Lostwood : ternary;
   }
   actions {
      Connell;
   }
   size : 512;
}
control Plano {
   apply( Veguita );
}
   metadata Levittown Welch;
   action Hillcrest( Lasara ) {
          max( Welch.Darmstadt, Welch.Darmstadt, Lasara );
   }
   action Pilar() { max( Boyle.Darmstadt, Welch.Darmstadt, Boyle.Darmstadt ); } table Sanborn { actions { Pilar; } default_action : Pilar; size : 1; } control Skiatook { apply( Sanborn ); }
@pragma ways 4
table Boysen {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : exact;
      Stillmore.Perkasie : exact;
      Stillmore.Triplett : exact;
      Stillmore.Waterflow : exact;
      Stillmore.Nixon : exact;
      Stillmore.Hookdale : exact;
      Stillmore.Rumson : exact;
      Stillmore.Buenos : exact;
      Stillmore.Lostwood : exact;
   }
   actions {
      Hillcrest;
   }
   size : 4096;
}
control Hemlock {
   apply( Boysen );
}
table ElMirage {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : ternary;
      Stillmore.Perkasie : ternary;
      Stillmore.Triplett : ternary;
      Stillmore.Waterflow : ternary;
      Stillmore.Nixon : ternary;
      Stillmore.Hookdale : ternary;
      Stillmore.Rumson : ternary;
      Stillmore.Buenos : ternary;
      Stillmore.Lostwood : ternary;
   }
   actions {
      Hillcrest;
   }
   size : 4096;
}
control Lambert {
   apply( ElMirage );
}
@pragma pa_no_init ingress Diomede.Beasley
@pragma pa_no_init ingress Diomede.Perkasie
@pragma pa_no_init ingress Diomede.Triplett
@pragma pa_no_init ingress Diomede.Waterflow
@pragma pa_no_init ingress Diomede.Nixon
@pragma pa_no_init ingress Diomede.Hookdale
@pragma pa_no_init ingress Diomede.Rumson
@pragma pa_no_init ingress Diomede.Buenos
@pragma pa_no_init ingress Diomede.Lostwood
metadata Chaires Diomede;
@pragma ways 4
table LaLuz {
   reads {
      Stillmore.Perrytown : exact;
      Diomede.Beasley : exact;
      Diomede.Perkasie : exact;
      Diomede.Triplett : exact;
      Diomede.Waterflow : exact;
      Diomede.Nixon : exact;
      Diomede.Hookdale : exact;
      Diomede.Rumson : exact;
      Diomede.Buenos : exact;
      Diomede.Lostwood : exact;
   }
   actions {
      Hillcrest;
   }
   size : 4096;
}
action FortGay( Salamonia, Grapevine, Herod, Kalkaska, Lewes, Esmond, Dahlgren, Teaneck, Potosi ) {
   bit_and( Diomede.Beasley, Stillmore.Beasley, Salamonia );
   bit_and( Diomede.Perkasie, Stillmore.Perkasie, Grapevine );
   bit_and( Diomede.Triplett, Stillmore.Triplett, Herod );
   bit_and( Diomede.Waterflow, Stillmore.Waterflow, Kalkaska );
   bit_and( Diomede.Nixon, Stillmore.Nixon, Lewes );
   bit_and( Diomede.Hookdale, Stillmore.Hookdale, Esmond );
   bit_and( Diomede.Rumson, Stillmore.Rumson, Dahlgren );
   bit_and( Diomede.Buenos, Stillmore.Buenos, Teaneck );
   bit_and( Diomede.Lostwood, Stillmore.Lostwood, Potosi );
}
table Traskwood {
   reads {
      Stillmore.Perrytown : exact;
   }
   actions {
      FortGay;
   }
   default_action : FortGay(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Ethete {
   apply( Traskwood );
}
control Grantfork {
   apply( LaLuz );
}
table Newhalem {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : ternary;
      Stillmore.Perkasie : ternary;
      Stillmore.Triplett : ternary;
      Stillmore.Waterflow : ternary;
      Stillmore.Nixon : ternary;
      Stillmore.Hookdale : ternary;
      Stillmore.Rumson : ternary;
      Stillmore.Buenos : ternary;
      Stillmore.Lostwood : ternary;
   }
   actions {
      Hillcrest;
   }
   size : 512;
}
control LaPlata {
   apply( Newhalem );
}
@pragma ways 4
table Quitman {
   reads {
      Stillmore.Perrytown : exact;
      Diomede.Beasley : exact;
      Diomede.Perkasie : exact;
      Diomede.Triplett : exact;
      Diomede.Waterflow : exact;
      Diomede.Nixon : exact;
      Diomede.Hookdale : exact;
      Diomede.Rumson : exact;
      Diomede.Buenos : exact;
      Diomede.Lostwood : exact;
   }
   actions {
      Hillcrest;
   }
   size : 4096;
}
action Grubbs( Nuremberg, Auburn, Malinta, Selawik, Fount, Kranzburg, Waukesha, Furman, Separ ) {
   bit_and( Diomede.Beasley, Stillmore.Beasley, Nuremberg );
   bit_and( Diomede.Perkasie, Stillmore.Perkasie, Auburn );
   bit_and( Diomede.Triplett, Stillmore.Triplett, Malinta );
   bit_and( Diomede.Waterflow, Stillmore.Waterflow, Selawik );
   bit_and( Diomede.Nixon, Stillmore.Nixon, Fount );
   bit_and( Diomede.Hookdale, Stillmore.Hookdale, Kranzburg );
   bit_and( Diomede.Rumson, Stillmore.Rumson, Waukesha );
   bit_and( Diomede.Buenos, Stillmore.Buenos, Furman );
   bit_and( Diomede.Lostwood, Stillmore.Lostwood, Separ );
}
table Gassoway {
   reads {
      Stillmore.Perrytown : exact;
   }
   actions {
      Grubbs;
   }
   default_action : Grubbs(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Talbert {
   apply( Gassoway );
}
control Gibson {
   apply( Quitman );
}
table Beeler {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : ternary;
      Stillmore.Perkasie : ternary;
      Stillmore.Triplett : ternary;
      Stillmore.Waterflow : ternary;
      Stillmore.Nixon : ternary;
      Stillmore.Hookdale : ternary;
      Stillmore.Rumson : ternary;
      Stillmore.Buenos : ternary;
      Stillmore.Lostwood : ternary;
   }
   actions {
      Hillcrest;
   }
   size : 512;
}
control ElkPoint {
   apply( Beeler );
}
@pragma ways 4
table ElkRidge {
   reads {
      Stillmore.Perrytown : exact;
      Diomede.Beasley : exact;
      Diomede.Perkasie : exact;
      Diomede.Triplett : exact;
      Diomede.Waterflow : exact;
      Diomede.Nixon : exact;
      Diomede.Hookdale : exact;
      Diomede.Rumson : exact;
      Diomede.Buenos : exact;
      Diomede.Lostwood : exact;
   }
   actions {
      Hillcrest;
   }
   size : 4096;
}
action Hartfield( LaMonte, Algoa, Nellie, Daphne, Kaluaaha, Terrytown, Wesson, Prismatic, Slagle ) {
   bit_and( Diomede.Beasley, Stillmore.Beasley, LaMonte );
   bit_and( Diomede.Perkasie, Stillmore.Perkasie, Algoa );
   bit_and( Diomede.Triplett, Stillmore.Triplett, Nellie );
   bit_and( Diomede.Waterflow, Stillmore.Waterflow, Daphne );
   bit_and( Diomede.Nixon, Stillmore.Nixon, Kaluaaha );
   bit_and( Diomede.Hookdale, Stillmore.Hookdale, Terrytown );
   bit_and( Diomede.Rumson, Stillmore.Rumson, Wesson );
   bit_and( Diomede.Buenos, Stillmore.Buenos, Prismatic );
   bit_and( Diomede.Lostwood, Stillmore.Lostwood, Slagle );
}
table Tecumseh {
   reads {
      Stillmore.Perrytown : exact;
   }
   actions {
      Hartfield;
   }
   default_action : Hartfield(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Allen {
   apply( Tecumseh );
}
control Sandpoint {
   apply( ElkRidge );
}
table Ragley {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : ternary;
      Stillmore.Perkasie : ternary;
      Stillmore.Triplett : ternary;
      Stillmore.Waterflow : ternary;
      Stillmore.Nixon : ternary;
      Stillmore.Hookdale : ternary;
      Stillmore.Rumson : ternary;
      Stillmore.Buenos : ternary;
      Stillmore.Lostwood : ternary;
   }
   actions {
      Hillcrest;
   }
   size : 512;
}
control Powers {
   apply( Ragley );
}
@pragma ways 4
table Owyhee {
   reads {
      Stillmore.Perrytown : exact;
      Diomede.Beasley : exact;
      Diomede.Perkasie : exact;
      Diomede.Triplett : exact;
      Diomede.Waterflow : exact;
      Diomede.Nixon : exact;
      Diomede.Hookdale : exact;
      Diomede.Rumson : exact;
      Diomede.Buenos : exact;
      Diomede.Lostwood : exact;
   }
   actions {
      Hillcrest;
   }
   size : 4096;
}
action Allison( BigPlain, Hotevilla, Markesan, Northlake, Verdemont, Oroville, Hokah, Oshoto, Pollard ) {
   bit_and( Diomede.Beasley, Stillmore.Beasley, BigPlain );
   bit_and( Diomede.Perkasie, Stillmore.Perkasie, Hotevilla );
   bit_and( Diomede.Triplett, Stillmore.Triplett, Markesan );
   bit_and( Diomede.Waterflow, Stillmore.Waterflow, Northlake );
   bit_and( Diomede.Nixon, Stillmore.Nixon, Verdemont );
   bit_and( Diomede.Hookdale, Stillmore.Hookdale, Oroville );
   bit_and( Diomede.Rumson, Stillmore.Rumson, Hokah );
   bit_and( Diomede.Buenos, Stillmore.Buenos, Oshoto );
   bit_and( Diomede.Lostwood, Stillmore.Lostwood, Pollard );
}
table Blitchton {
   reads {
      Stillmore.Perrytown : exact;
   }
   actions {
      Allison;
   }
   default_action : Allison(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Bacton {
   apply( Blitchton );
}
control Woolsey {
   apply( Owyhee );
}
table Anguilla {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : ternary;
      Stillmore.Perkasie : ternary;
      Stillmore.Triplett : ternary;
      Stillmore.Waterflow : ternary;
      Stillmore.Nixon : ternary;
      Stillmore.Hookdale : ternary;
      Stillmore.Rumson : ternary;
      Stillmore.Buenos : ternary;
      Stillmore.Lostwood : ternary;
   }
   actions {
      Hillcrest;
   }
   size : 512;
}
control Millstone {
   apply( Anguilla );
}
@pragma ways 4
table FarrWest {
   reads {
      Stillmore.Perrytown : exact;
      Diomede.Beasley : exact;
      Diomede.Perkasie : exact;
      Diomede.Triplett : exact;
      Diomede.Waterflow : exact;
      Diomede.Nixon : exact;
      Diomede.Hookdale : exact;
      Diomede.Rumson : exact;
      Diomede.Buenos : exact;
      Diomede.Lostwood : exact;
   }
   actions {
      Hillcrest;
   }
   size : 4096;
}
action Gagetown( Lawai, Dalton, Kelso, Trego, Moultrie, Bellwood, Blevins, Ravenwood, Hershey ) {
   bit_and( Diomede.Beasley, Stillmore.Beasley, Lawai );
   bit_and( Diomede.Perkasie, Stillmore.Perkasie, Dalton );
   bit_and( Diomede.Triplett, Stillmore.Triplett, Kelso );
   bit_and( Diomede.Waterflow, Stillmore.Waterflow, Trego );
   bit_and( Diomede.Nixon, Stillmore.Nixon, Moultrie );
   bit_and( Diomede.Hookdale, Stillmore.Hookdale, Bellwood );
   bit_and( Diomede.Rumson, Stillmore.Rumson, Blevins );
   bit_and( Diomede.Buenos, Stillmore.Buenos, Ravenwood );
   bit_and( Diomede.Lostwood, Stillmore.Lostwood, Hershey );
}
table Eastover {
   reads {
      Stillmore.Perrytown : exact;
   }
   actions {
      Gagetown;
   }
   default_action : Gagetown(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Benitez {
   apply( Eastover );
}
control Arvana {
   apply( FarrWest );
}
table Waialua {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : ternary;
      Stillmore.Perkasie : ternary;
      Stillmore.Triplett : ternary;
      Stillmore.Waterflow : ternary;
      Stillmore.Nixon : ternary;
      Stillmore.Hookdale : ternary;
      Stillmore.Rumson : ternary;
      Stillmore.Buenos : ternary;
      Stillmore.Lostwood : ternary;
   }
   actions {
      Hillcrest;
   }
   size : 512;
}
control Timnath {
   apply( Waialua );
}
@pragma ways 4
table Marfa {
   reads {
      Stillmore.Perrytown : exact;
      Diomede.Beasley : exact;
      Diomede.Perkasie : exact;
      Diomede.Triplett : exact;
      Diomede.Waterflow : exact;
      Diomede.Nixon : exact;
      Diomede.Hookdale : exact;
      Diomede.Rumson : exact;
      Diomede.Buenos : exact;
      Diomede.Lostwood : exact;
   }
   actions {
      Hillcrest;
   }
   size : 4096;
}
action Runnemede( Hopkins, Provo, Glenpool, Reddell, Progreso, NewTrier, Laclede, Aplin, Speedway ) {
   bit_and( Diomede.Beasley, Stillmore.Beasley, Hopkins );
   bit_and( Diomede.Perkasie, Stillmore.Perkasie, Provo );
   bit_and( Diomede.Triplett, Stillmore.Triplett, Glenpool );
   bit_and( Diomede.Waterflow, Stillmore.Waterflow, Reddell );
   bit_and( Diomede.Nixon, Stillmore.Nixon, Progreso );
   bit_and( Diomede.Hookdale, Stillmore.Hookdale, NewTrier );
   bit_and( Diomede.Rumson, Stillmore.Rumson, Laclede );
   bit_and( Diomede.Buenos, Stillmore.Buenos, Aplin );
   bit_and( Diomede.Lostwood, Stillmore.Lostwood, Speedway );
}
table SwissAlp {
   reads {
      Stillmore.Perrytown : exact;
   }
   actions {
      Runnemede;
   }
   default_action : Runnemede(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control UnionGap {
   apply( SwissAlp );
}
control Gwynn {
   apply( Marfa );
}
table Shade {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : ternary;
      Stillmore.Perkasie : ternary;
      Stillmore.Triplett : ternary;
      Stillmore.Waterflow : ternary;
      Stillmore.Nixon : ternary;
      Stillmore.Hookdale : ternary;
      Stillmore.Rumson : ternary;
      Stillmore.Buenos : ternary;
      Stillmore.Lostwood : ternary;
   }
   actions {
      Hillcrest;
   }
   size : 512;
}
control Crooks {
   apply( Shade );
}
@pragma ways 4
table Cricket {
   reads {
      Stillmore.Perrytown : exact;
      Diomede.Beasley : exact;
      Diomede.Perkasie : exact;
      Diomede.Triplett : exact;
      Diomede.Waterflow : exact;
      Diomede.Nixon : exact;
      Diomede.Hookdale : exact;
      Diomede.Rumson : exact;
      Diomede.Buenos : exact;
      Diomede.Lostwood : exact;
   }
   actions {
      Hillcrest;
   }
   size : 4096;
}
action Belcher( Dasher, Stonefort, Ovett, Locke, Beltrami, Gretna, Neponset, Lubeck, Botna ) {
   bit_and( Diomede.Beasley, Stillmore.Beasley, Dasher );
   bit_and( Diomede.Perkasie, Stillmore.Perkasie, Stonefort );
   bit_and( Diomede.Triplett, Stillmore.Triplett, Ovett );
   bit_and( Diomede.Waterflow, Stillmore.Waterflow, Locke );
   bit_and( Diomede.Nixon, Stillmore.Nixon, Beltrami );
   bit_and( Diomede.Hookdale, Stillmore.Hookdale, Gretna );
   bit_and( Diomede.Rumson, Stillmore.Rumson, Neponset );
   bit_and( Diomede.Buenos, Stillmore.Buenos, Lubeck );
   bit_and( Diomede.Lostwood, Stillmore.Lostwood, Botna );
}
table Bowdon {
   reads {
      Stillmore.Perrytown : exact;
   }
   actions {
      Belcher;
   }
   default_action : Belcher(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Nanuet {
   apply( Bowdon );
}
control Pinta {
   apply( Cricket );
}
table Bucktown {
   reads {
      Stillmore.Perrytown : exact;
      Stillmore.Beasley : ternary;
      Stillmore.Perkasie : ternary;
      Stillmore.Triplett : ternary;
      Stillmore.Waterflow : ternary;
      Stillmore.Nixon : ternary;
      Stillmore.Hookdale : ternary;
      Stillmore.Rumson : ternary;
      Stillmore.Buenos : ternary;
      Stillmore.Lostwood : ternary;
   }
   actions {
      Hillcrest;
   }
   size : 512;
}
control Rainsburg {
   apply( Bucktown );
}
control ingress {
   Chappell();
   if( Acree.Louviers != 0 ) {
      Fiskdale();
   }
   Canfield();
   if( Acree.Louviers != 0 ) {
      Howland();
      Hurst();
   }
   Braymer();
   Burwell();
   Longwood();
   Wanamassa();
   Hubbell();
   if( Acree.Louviers != 0 ) {
      Strasburg();
   }
   Greenhorn();
   Elyria();
   Fennimore();
   Drake();
   if( Acree.Louviers != 0 ) {
      Boyce();
   }
   Astor();
   Champlain();
   Hollymead();
   Millsboro();
   if( Acree.Louviers != 0 ) {
      Raceland();
   }
   Meservey();
   Hephzibah();
   Lambert();
   Kotzebue();
   Wellsboro();
   if( Acree.Louviers != 0 ) {
      Windham();
   }
   Saranap();
   Belcourt();
   Cotter();
   Kenyon();
   if( PineCity.Newfolden == 0 ) {
      if( valid( PineHill ) ) {
         Micco();
      } else {
         Charenton();
         ElDorado();
      }
   }
   if( not valid( PineHill ) ) {
      Trujillo();
   }
   if( PineCity.Newfolden == 0 ) {
      RockyGap();
   }
   RichBar();
   Skiatook();
   if( PineCity.Newfolden == 0 ) {
      Ahuimanu();
   }
   if( Acree.Louviers != 0 ) {
      Powderly();
   }
   Lefor();
   if( valid( Wamesit[0] ) ) {
      WindGap();
   }
   if( PineCity.Newfolden == 0 ) {
      Vandling();
   }
   Greycliff();
   Linganore();
}
control egress {
   Bassett();
   Onycha();
   Ringtown();
   if( ( PineCity.Canton == 0 ) and ( PineCity.DeRidder != 2 ) ) {
      Melvina();
   }
   Hayfield();
}
