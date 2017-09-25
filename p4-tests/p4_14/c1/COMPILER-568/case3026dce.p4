// BUILD: p4c-tofino --verbose 0 --placement tp4 --no-dead-code-elimination --o bf_obfuscate_arista_switch_default --p4-name=obfuscate_arista_switch --p4-prefix=p4_obfuscate_arista_switch --pipe-mgr-path=pipe_mgr/ --mc-mgr-path=mc_mgr/ --gen-exm-test-pd -S -DPROFILE_DEFAULT Switch.OBFUSCATED.p4


// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 172635

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
header_type Leawood {
	fields {
		Alamosa : 16;
		Wyocena : 16;
		Fletcher : 8;
		Oilmont : 8;
		McKamie : 8;
		Pevely : 8;
		Muenster : 1;
		Metter : 1;
		Mifflin : 1;
		Kaibab : 1;
		Flats : 1;
		Scarville : 1;
	}
}
header_type Kokadjo {
	fields {
		Suffern : 24;
		Welch : 24;
		Natalia : 24;
		Odenton : 24;
		Ganado : 16;
		Perrine : 16;
		McLean : 16;
		Homeworth : 16;
		Cross : 16;
		Aplin : 8;
		Seattle : 8;
		Nuyaka : 1;
		Scissors : 1;
		Hulbert : 1;
		Coulee : 1;
		Ogunquit : 12;
		Antlers : 2;
		Topanga : 1;
		Mogadore : 1;
		Shauck : 1;
		Grannis : 1;
		Moapa : 1;
		Immokalee : 1;
		Virden : 1;
		OakCity : 1;
		Armagh : 1;
		Talkeetna : 1;
		Ackley : 1;
		Vibbard : 1;
		Selby : 1;
		Gibbs : 1;
		Bokeelia : 1;
		Tillatoba : 1;
		Pasadena : 16;
		Omemee : 16;
		Renton : 8;
		Vidal : 1;
		Chackbay : 1;
	}
}
header_type Wenona {
	fields {
		Rocheport : 24;
		Neame : 24;
		Elkader : 24;
		Hanover : 24;
		Trenary : 24;
		BigPlain : 24;
		Hopedale : 24;
		Challis : 24;
		Tarlton : 16;
		Elbing : 16;
		Hanford : 16;
		Forbes : 16;
		Bartolo : 12;
		Penzance : 1;
		Sparkill : 3;
		Aspetuck : 1;
		Alvordton : 3;
		Prunedale : 1;
		Penrose : 1;
		Tabler : 1;
		Trammel : 1;
		Fragaria : 1;
		Lanyon : 8;
		Udall : 12;
		BigFork : 4;
		Newsoms : 6;
		Stoystown : 10;
		Maltby : 9;
		Gardena : 1;
		SanRemo : 1;
		Lucas : 1;
		DeerPark : 1;
		Camino : 1;
	}
}
header_type Algonquin {
	fields {
		Blanchard : 8;
		Fairchild : 1;
		Waynoka : 1;
		Welcome : 1;
		Ribera : 1;
		Buncombe : 1;
	}
}
header_type Cornville {
	fields {
		Euren : 32;
		Joplin : 32;
		Daykin : 6;
		WestPark : 16;
	}
}
header_type Rockvale {
	fields {
		Despard : 128;
		Sasakwa : 128;
		Tinaja : 20;
		LewisRun : 8;
		Woodrow : 11;
		Bagdad : 6;
		Oskawalik : 13;
	}
}
header_type Duchesne {
	fields {
		Vesuvius : 14;
		Goessel : 1;
		LaHabra : 12;
		Swenson : 1;
		Southam : 1;
		Norborne : 6;
		Vallejo : 2;
		Zebina : 6;
		Evelyn : 3;
	}
}
header_type Academy {
	fields {
		Parmele : 1;
		Lugert : 1;
	}
}
header_type LaJara {
	fields {
		Millett : 8;
	}
}
header_type Shellman {
	fields {
		Alcoma : 16;
		Pilger : 11;
	}
}
header_type Sigsbee {
	fields {
		Annawan : 32;
		Pearce : 32;
		Manasquan : 32;
	}
}
header_type Mescalero {
	fields {
		Covelo : 32;
		Kamas : 32;
	}
}
header_type Calamus {
	fields {
		Roosville : 1;
		Canovanas : 1;
		RoseBud : 1;
		Verdemont : 3;
		Clarkdale : 1;
		Moose : 6;
		Stobo : 5;
	}
}
header_type McCartys {
	fields {
		Sudbury : 16;
	}
}
header_type Sparland {
	fields {
		Halley : 14;
		Calimesa : 1;
		Mosinee : 1;
	}
}
header_type Holliston {
	fields {
		Bammel : 14;
		DeLancey : 1;
		Nephi : 1;
	}
}
header_type Calva {
	fields {
		Covina : 16;
		Dubbs : 16;
		Cornell : 16;
		Sitka : 16;
		Havana : 8;
		Quamba : 8;
		Hiwassee : 8;
		Dunmore : 8;
		Greenlawn : 1;
		ElkRidge : 6;
	}
}
header_type Brinkley {
	fields {
		RichHill : 32;
	}
}
header_type Firebrick {
	fields {
		Valdosta : 6;
		Winside : 10;
		Craigmont : 4;
		Illmo : 12;
		Picacho : 12;
		Conklin : 2;
		Lolita : 2;
		Cement : 8;
		Cresco : 3;
		Ortley : 5;
	}
}
header_type Burtrum {
	fields {
		Louviers : 24;
		Felton : 24;
		Duquoin : 24;
		Bellmead : 24;
		Triplett : 16;
	}
}
header_type Otego {
	fields {
		Wegdahl : 3;
		Barnwell : 1;
		Mission : 12;
		Westel : 16;
	}
}
header_type Kahaluu {
	fields {
		Bleecker : 4;
		Mondovi : 4;
		Sabetha : 6;
		Hobson : 2;
		Rosburg : 16;
		Dunnville : 16;
		Grigston : 3;
		Cusick : 13;
		Gonzalez : 8;
		Annandale : 8;
		Kalaloch : 16;
		PellLake : 32;
		Sweeny : 32;
	}
}
header_type Vinemont {
	fields {
		Eddington : 4;
		Bevier : 6;
		Leetsdale : 2;
		Clifton : 20;
		BigPark : 16;
		Basic : 8;
		Olyphant : 8;
		AvonLake : 128;
		Glynn : 128;
	}
}
header_type Croghan {
	fields {
		Napanoch : 8;
		Cornish : 8;
		TroutRun : 16;
	}
}
header_type Energy {
	fields {
		Ferry : 16;
		Moark : 16;
	}
}
header_type Humarock {
	fields {
		Justice : 32;
		Maloy : 32;
		Galestown : 4;
		Grassflat : 4;
		RedLake : 8;
		Lamar : 16;
		Carpenter : 16;
		Neuse : 16;
	}
}
header_type Hoadly {
	fields {
		Idalia : 16;
		Roswell : 16;
	}
}
header_type HighRock {
	fields {
		Molino : 16;
		Tafton : 16;
		Lesley : 8;
		Bechyn : 8;
		Noonan : 16;
	}
}
header_type Petty {
	fields {
		Gilliam : 48;
		Langdon : 32;
		Swifton : 48;
		Lowemont : 32;
	}
}
header_type Cathay {
	fields {
		Brentford : 1;
		Hatchel : 1;
		Stockdale : 1;
		Shanghai : 1;
		Mogote : 1;
		Bajandas : 3;
		BullRun : 5;
		Yantis : 3;
		Taopi : 16;
	}
}
header_type Agawam {
	fields {
		Taneytown : 24;
		Newberg : 8;
	}
}
header_type Towaoc {
	fields {
		Rotterdam : 8;
		Surrency : 24;
		Frewsburg : 24;
		Luttrell : 8;
	}
}
header Burtrum Eclectic;
header Burtrum Tamms;
header Otego Carnero[ 2 ];
@pragma pa_fragment ingress Toccopola.Kalaloch
@pragma pa_fragment egress Toccopola.Kalaloch
header Kahaluu Toccopola;
@pragma pa_fragment ingress Gakona.Kalaloch
@pragma pa_fragment egress Gakona.Kalaloch
header Kahaluu Gakona;
header Vinemont Hiseville;
header Vinemont Linville;
header Energy Plato;
header Energy Gallinas;
header Humarock Wyndmoor;
header Hoadly Froid;
header Humarock Linda;
header Hoadly Panola;
header Towaoc Tenino;
header HighRock Skiatook;
header Cathay Rampart;
header Firebrick Neosho;
header Burtrum Highcliff;
parser start {
   return select(current(96, 16)) {
      0xBF00 : Hillcrest;
      default : Brackett;
   }
}
parser Boyle {
   extract( Neosho );
   return Brackett;
}
parser Hillcrest {
   extract( Highcliff );
   return Boyle;
}
parser Brackett {
   extract( Eclectic );
   return select( Eclectic.Triplett ) {
      0x8100 : Surrey;
      0x0800 : JimFalls;
      0x86dd : Salamonia;
      0x0806 : Woodland;
      default : ingress;
   }
}
parser Surrey {
   extract( Carnero[0] );
   set_metadata(Flourtown.Flats, 1);
   return select( Carnero[0].Westel ) {
      0x0800 : JimFalls;
      0x86dd : Salamonia;
      0x0806 : Woodland;
      default : ingress;
   }
}
field_list Essex {
    Toccopola.Bleecker;
    Toccopola.Mondovi;
    Toccopola.Sabetha;
    Toccopola.Hobson;
    Toccopola.Rosburg;
    Toccopola.Dunnville;
    Toccopola.Grigston;
    Toccopola.Cusick;
    Toccopola.Gonzalez;
    Toccopola.Annandale;
    Toccopola.PellLake;
    Toccopola.Sweeny;
}
field_list_calculation AquaPark {
    input {
        Essex;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Toccopola.Kalaloch {
    verify AquaPark;
    update AquaPark;
}
parser JimFalls {
   extract( Toccopola );
   set_metadata(Flourtown.Fletcher, Toccopola.Annandale);
   set_metadata(Flourtown.McKamie, Toccopola.Gonzalez);
   set_metadata(Flourtown.Alamosa, Toccopola.Rosburg);
   set_metadata(Flourtown.Mifflin, 0);
   set_metadata(Flourtown.Muenster, 1);
   return select(Toccopola.Cusick, Toccopola.Mondovi, Toccopola.Annandale) {
      0x501 : Welaka;
      0x511 : Turkey;
      0x506 : Crumstown;
      0 mask 0xFF7000 : Lansdale;
      default : ingress;
   }
}
parser Lansdale {
   set_metadata(Lisle.Hulbert, 1);
   return ingress;
}
parser Salamonia {
   extract( Linville );
   set_metadata(Flourtown.Fletcher, Linville.Basic);
   set_metadata(Flourtown.McKamie, Linville.Olyphant);
   set_metadata(Flourtown.Alamosa, Linville.BigPark);
   set_metadata(Flourtown.Mifflin, 1);
   set_metadata(Flourtown.Muenster, 0);
   return select(Linville.Basic) {
      0x3a : Welaka;
      17 : Between;
      6 : Crumstown;
      default : Lansdale;
   }
}
parser Woodland {
   extract( Skiatook );
   set_metadata(Flourtown.Scarville, 1);
   return ingress;
}
parser Turkey {
   extract(Plato);
   extract(Froid);
   set_metadata(Lisle.Hulbert, 1);
   return select(Plato.Moark) {
      4789 : Mickleton;
      default : ingress;
    }
}
parser Welaka {
   set_metadata( Plato.Ferry, current( 0, 16 ) );
   set_metadata( Plato.Moark, 0 );
   set_metadata( Lisle.Hulbert, 1 );
   return ingress;
}
parser Between {
   set_metadata(Lisle.Hulbert, 1);
   extract(Plato);
   extract(Froid);
   return ingress;
}
parser Crumstown {
   set_metadata(Lisle.Vidal, 1);
   set_metadata(Lisle.Hulbert, 1);
   extract(Plato);
   extract(Wyndmoor);
   return ingress;
}
parser Odell {
   set_metadata(Lisle.Antlers, 2);
   return Bigspring;
}
parser Eastwood {
   set_metadata(Lisle.Antlers, 2);
   return ElVerano;
}
parser Kapalua {
   extract(Rampart);
   return select(Rampart.Brentford, Rampart.Hatchel, Rampart.Stockdale, Rampart.Shanghai, Rampart.Mogote,
             Rampart.Bajandas, Rampart.BullRun, Rampart.Yantis, Rampart.Taopi) {
      0x0800 : Odell;
      0x86dd : Eastwood;
      default : ingress;
   }
}
parser Mickleton {
   extract(Tenino);
   set_metadata(Lisle.Antlers, 1);
   return Temvik;
}
field_list Bellvue {
    Gakona.Bleecker;
    Gakona.Mondovi;
    Gakona.Sabetha;
    Gakona.Hobson;
    Gakona.Rosburg;
    Gakona.Dunnville;
    Gakona.Grigston;
    Gakona.Cusick;
    Gakona.Gonzalez;
    Gakona.Annandale;
    Gakona.PellLake;
    Gakona.Sweeny;
}
field_list_calculation Rexville {
    input {
        Bellvue;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Gakona.Kalaloch {
    verify Rexville;
    update Rexville;
}
parser Bigspring {
   extract( Gakona );
   set_metadata(Flourtown.Oilmont, Gakona.Annandale);
   set_metadata(Flourtown.Pevely, Gakona.Gonzalez);
   set_metadata(Flourtown.Wyocena, Gakona.Rosburg);
   set_metadata(Flourtown.Kaibab, 0);
   set_metadata(Flourtown.Metter, 1);
   return select(Gakona.Cusick, Gakona.Mondovi, Gakona.Annandale) {
      0x501 : Cornudas;
      0x511 : Lookeba;
      0x506 : Greenbelt;
      0 mask 0xFF7000 : Piney;
      default : ingress;
   }
}
parser Piney {
   set_metadata(Lisle.Coulee, 1);
   return ingress;
}
parser ElVerano {
   extract( Hiseville );
   set_metadata(Flourtown.Oilmont, Hiseville.Basic);
   set_metadata(Flourtown.Pevely, Hiseville.Olyphant);
   set_metadata(Flourtown.Wyocena, Hiseville.BigPark);
   set_metadata(Flourtown.Kaibab, 1);
   set_metadata(Flourtown.Metter, 0);
   return select(Hiseville.Basic) {
      0x3a : Cornudas;
      17 : Lookeba;
      6 : Greenbelt;
      default : Piney;
   }
}
parser Cornudas {
   set_metadata( Lisle.Pasadena, current( 0, 16 ) );
   set_metadata( Lisle.Tillatoba, 1 );
   set_metadata( Lisle.Coulee, 1 );
   return ingress;
}
parser Lookeba {
   set_metadata( Lisle.Pasadena, current( 0, 16 ) );
   set_metadata( Lisle.Omemee, current( 16, 16 ) );
   set_metadata( Lisle.Tillatoba, 1 );
   set_metadata( Lisle.Coulee, 1);
   return ingress;
}
parser Greenbelt {
   set_metadata( Lisle.Pasadena, current( 0, 16 ) );
   set_metadata( Lisle.Omemee, current( 16, 16 ) );
   set_metadata( Lisle.Renton, current( 104, 8 ) );
   set_metadata( Lisle.Tillatoba, 1 );
   set_metadata( Lisle.Coulee, 1 );
   set_metadata( Lisle.Chackbay, 1 );
   extract(Gallinas);
   extract(Linda);
   return ingress;
}
parser Temvik {
   extract( Tamms );
   return select( Tamms.Triplett ) {
      0x0800: Bigspring;
      0x86dd: ElVerano;
      default: ingress;
   }
}
@pragma pa_no_init ingress Lisle.Suffern
@pragma pa_no_init ingress Lisle.Welch
@pragma pa_no_init ingress Lisle.Natalia
@pragma pa_no_init ingress Lisle.Odenton
metadata Kokadjo Lisle;
@pragma pa_no_init ingress Homeacre.Rocheport
@pragma pa_no_init ingress Homeacre.Neame
@pragma pa_no_init ingress Homeacre.Elkader
@pragma pa_no_init ingress Homeacre.Hanover
metadata Wenona Homeacre;
metadata Duchesne CedarKey;
metadata Leawood Flourtown;
metadata Cornville CruzBay;
metadata Rockvale Dorset;
metadata Academy Daysville;
metadata Algonquin Nondalton;
metadata LaJara Cruso;
metadata Shellman Ramah;
metadata Mescalero IttaBena;
metadata Sigsbee Bienville;
metadata Calamus Shivwits;
metadata McCartys Ashley;
@pragma pa_no_init ingress Caban.Halley
metadata Sparland Caban;
@pragma pa_no_init ingress Nicolaus.Bammel
metadata Holliston Nicolaus;
metadata Calva Atlas;
action Sultana() {
   no_op();
}
action Lignite() {
   modify_field(Lisle.Grannis, 1 );
   mark_for_drop();
}
action RyanPark() {
   no_op();
}
action SnowLake(Clearmont, Pineville, Nahunta, Cypress, Colson, Logandale,
                 PawCreek, Dowell, Sugarloaf) {
    modify_field(CedarKey.Vesuvius, Clearmont);
    modify_field(CedarKey.Goessel, Pineville);
    modify_field(CedarKey.LaHabra, Nahunta);
    modify_field(CedarKey.Swenson, Cypress);
    modify_field(CedarKey.Southam, Colson);
    modify_field(CedarKey.Norborne, Logandale);
    modify_field(CedarKey.Vallejo, PawCreek);
    modify_field(CedarKey.Evelyn, Dowell);
    modify_field(CedarKey.Zebina, Sugarloaf);
}
table Crestline {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        SnowLake;
    }
    size : 288;
}
control Diana {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Crestline);
    }
}
action Crannell(Johnstown, Cahokia) {
   modify_field( Homeacre.Aspetuck, 1 );
   modify_field( Homeacre.Lanyon, Johnstown);
   modify_field( Lisle.Talkeetna, 1 );
   modify_field( Shivwits.RoseBud, Cahokia );
}
action Sonoma() {
   modify_field( Lisle.Virden, 1 );
   modify_field( Lisle.Vibbard, 1 );
}
action Nashwauk() {
   modify_field( Lisle.Talkeetna, 1 );
}
action Nunda() {
   modify_field( Lisle.Talkeetna, 1 );
   modify_field( Lisle.Selby, 1 );
}
action Hemet() {
   modify_field( Lisle.Ackley, 1 );
}
action Florien() {
   modify_field( Lisle.Vibbard, 1 );
}
counter Paxico {
   type : packets_and_bytes;
   direct : Maywood;
   min_width: 16;
}
table Maywood {
   reads {
      CedarKey.Norborne : exact;
      Eclectic.Louviers : ternary;
      Eclectic.Felton : ternary;
   }
   actions {
      Crannell;
      Sonoma;
      Nashwauk;
      Hemet;
      Florien;
      Nunda;
   }
   size : 1024;
}
action GunnCity() {
   modify_field( Lisle.OakCity, 1 );
}
table Ririe {
   reads {
      Eclectic.Duquoin : ternary;
      Eclectic.Bellmead : ternary;
   }
   actions {
      GunnCity;
   }
   size : 512;
}
control Dolliver {
   apply( Maywood );
   apply( Ririe );
}
action Mesita() {
   modify_field( CruzBay.Euren, Gakona.PellLake );
   modify_field( CruzBay.Joplin, Gakona.Sweeny );
   modify_field( CruzBay.Daykin, Gakona.Sabetha );
   modify_field( Dorset.Despard, Hiseville.AvonLake );
   modify_field( Dorset.Sasakwa, Hiseville.Glynn );
   modify_field( Dorset.Tinaja, Hiseville.Clifton );
   modify_field( Dorset.Bagdad, Hiseville.Bevier );
   modify_field( Lisle.Suffern, Tamms.Louviers );
   modify_field( Lisle.Welch, Tamms.Felton );
   modify_field( Lisle.Natalia, Tamms.Duquoin );
   modify_field( Lisle.Odenton, Tamms.Bellmead );
   modify_field( Lisle.Ganado, Tamms.Triplett );
   modify_field( Lisle.Cross, Flourtown.Wyocena );
   modify_field( Lisle.Aplin, Flourtown.Oilmont );
   modify_field( Lisle.Seattle, Flourtown.Pevely );
   modify_field( Lisle.Scissors, Flourtown.Metter );
   modify_field( Lisle.Nuyaka, Flourtown.Kaibab );
   modify_field( Lisle.Gibbs, 0 );
   modify_field( Homeacre.Alvordton, 1 );
   modify_field( CedarKey.Vallejo, 1 );
   modify_field( CedarKey.Evelyn, 0 );
   modify_field( CedarKey.Zebina, 0 );
   modify_field( Shivwits.Roosville, 1 );
   modify_field( Shivwits.Canovanas, 1 );
   modify_field( Lisle.Hulbert, Lisle.Coulee );
   modify_field( Lisle.Vidal, Lisle.Chackbay );
}
action Kisatchie() {
   modify_field( Lisle.Antlers, 0 );
   modify_field( CruzBay.Euren, Toccopola.PellLake );
   modify_field( CruzBay.Joplin, Toccopola.Sweeny );
   modify_field( CruzBay.Daykin, Toccopola.Sabetha );
   modify_field( Dorset.Despard, Linville.AvonLake );
   modify_field( Dorset.Sasakwa, Linville.Glynn );
   modify_field( Dorset.Tinaja, Linville.Clifton );
   modify_field( Dorset.Bagdad, Linville.Bevier );
   modify_field( Lisle.Suffern, Eclectic.Louviers );
   modify_field( Lisle.Welch, Eclectic.Felton );
   modify_field( Lisle.Natalia, Eclectic.Duquoin );
   modify_field( Lisle.Odenton, Eclectic.Bellmead );
   modify_field( Lisle.Ganado, Eclectic.Triplett );
   modify_field( Lisle.Cross, Flourtown.Alamosa );
   modify_field( Lisle.Aplin, Flourtown.Fletcher );
   modify_field( Lisle.Seattle, Flourtown.McKamie );
   modify_field( Lisle.Scissors, Flourtown.Muenster );
   modify_field( Lisle.Nuyaka, Flourtown.Mifflin );
   modify_field( Shivwits.Clarkdale, Carnero[0].Barnwell );
   modify_field( Lisle.Gibbs, Flourtown.Flats );
   modify_field( Lisle.Pasadena, Plato.Ferry );
   modify_field( Lisle.Omemee, Plato.Moark );
   modify_field( Lisle.Renton, Wyndmoor.RedLake );
}
table Rosebush {
   reads {
      Eclectic.Louviers : exact;
      Eclectic.Felton : exact;
      Toccopola.Sweeny : exact;
      Lisle.Antlers : exact;
   }
   actions {
      Mesita;
      Kisatchie;
   }
   default_action : Kisatchie();
   size : 1024;
}
action Waterford() {
   modify_field( Lisle.Perrine, CedarKey.LaHabra );
   modify_field( Lisle.McLean, CedarKey.Vesuvius);
}
action CapeFair( Rotan ) {
   modify_field( Lisle.Perrine, Rotan );
   modify_field( Lisle.McLean, CedarKey.Vesuvius);
}
action Suarez() {
   modify_field( Lisle.Perrine, Carnero[0].Mission );
   modify_field( Lisle.McLean, CedarKey.Vesuvius);
}
table Eudora {
   reads {
      CedarKey.Vesuvius : ternary;
      Carnero[0] : valid;
      Carnero[0].Mission : ternary;
   }
   actions {
      Waterford;
      CapeFair;
      Suarez;
   }
   size : 4096;
}
action DeGraff( Piketon ) {
   modify_field( Lisle.McLean, Piketon );
}
action Bridgton() {
   modify_field( Lisle.Shauck, 1 );
   modify_field( Cruso.Millett,
                 1 );
}
table McClusky {
   reads {
      Toccopola.PellLake : exact;
   }
   actions {
      DeGraff;
      Bridgton;
   }
   default_action : Bridgton;
   size : 4096;
}
action Menfro( Tulsa, Everest, Winger, Wauseon, Caputa,
                        Lamine, Maxwelton ) {
   modify_field( Lisle.Perrine, Tulsa );
   modify_field( Lisle.Homeworth, Tulsa );
   modify_field( Lisle.Immokalee, Maxwelton );
   Lamkin(Everest, Winger, Wauseon, Caputa,
                        Lamine );
}
action ElRio() {
   modify_field( Lisle.Moapa, 1 );
}
table Conda {
   reads {
      Tenino.Frewsburg : exact;
   }
   actions {
      Menfro;
      ElRio;
   }
   size : 4096;
}
action Lamkin(Pimento, Talbert, DimeBox, Maryhill,
                        Silva ) {
   modify_field( Nondalton.Blanchard, Pimento );
   modify_field( Nondalton.Fairchild, Talbert );
   modify_field( Nondalton.Welcome, DimeBox );
   modify_field( Nondalton.Waynoka, Maryhill );
   modify_field( Nondalton.Ribera, Silva );
}
action Charm(Charco, Oakford, Danforth, Dilia,
                        Ephesus ) {
   modify_field( Lisle.Homeworth, CedarKey.LaHabra );
   Lamkin(Charco, Oakford, Danforth, Dilia,
                        Ephesus );
}
action Taconite(Philip, Idabel, Iredell, Embarrass,
                        Berenice, Supai ) {
   modify_field( Lisle.Homeworth, Philip );
   Lamkin(Idabel, Iredell, Embarrass, Berenice,
                        Supai );
}
action Holden(Blackwood, Bacton, Beatrice, CleElum,
                        Camelot ) {
   modify_field( Lisle.Homeworth, Carnero[0].Mission );
   Lamkin(Blackwood, Bacton, Beatrice, CleElum,
                        Camelot );
}
table WestEnd {
   reads {
      CedarKey.LaHabra : exact;
   }
   actions {
      Sultana;
      Charm;
   }
   size : 4096;
}
@pragma action_default_only Sultana
table Verndale {
   reads {
      CedarKey.Vesuvius : exact;
      Carnero[0].Mission : exact;
   }
   actions {
      Taconite;
      Sultana;
   }
   size : 1024;
}
table Tekonsha {
   reads {
      Carnero[0].Mission : exact;
   }
   actions {
      Sultana;
      Holden;
   }
   size : 4096;
}
control Sudden {
   apply( Rosebush ) {
         Mesita {
            apply( McClusky );
            apply( Conda );
         }
         Kisatchie {
            if ( not valid(Neosho) and CedarKey.Swenson == 1 ) {
               apply( Eudora );
            }
            if ( valid( Carnero[ 0 ] ) ) {
               apply( Verndale ) {
                  Sultana {
                     apply( Tekonsha );
                  }
               }
            } else {
               apply( WestEnd );
            }
         }
   }
}
register Ontonagon {
    width : 1;
    static : Roodhouse;
    instance_count : 262144;
}
register Parkline {
    width : 1;
    static : Clovis;
    instance_count : 262144;
}
blackbox stateful_alu Woodcrest {
    reg : Ontonagon;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : Daysville.Parmele;
}
blackbox stateful_alu Masardis {
    reg : Parkline;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst : Daysville.Lugert;
}
field_list Boise {
    CedarKey.Norborne;
    Carnero[0].Mission;
}
field_list_calculation Valders {
    input { Boise; }
    algorithm: identity;
    output_width: 18;
}
action Reidland() {
    Woodcrest.execute_stateful_alu_from_hash(Valders);
}
action Tiverton() {
    Masardis.execute_stateful_alu_from_hash(Valders);
}
table Roodhouse {
    actions {
      Reidland;
    }
    default_action : Reidland;
    size : 1;
}
table Clovis {
    actions {
      Tiverton;
    }
    default_action : Tiverton;
    size : 1;
}
action Council(Mabel) {
    modify_field(Daysville.Lugert, Mabel);
}
@pragma use_hash_action 0
table Pachuta {
    reads {
       CedarKey.Norborne : exact;
    }
    actions {
      Council;
    }
    size : 64;
}
action Pathfork() {
   modify_field( Lisle.Ogunquit, CedarKey.LaHabra );
   modify_field( Lisle.Topanga, 0 );
}
table Beresford {
   actions {
      Pathfork;
   }
   size : 1;
}
action Hyrum() {
   modify_field( Lisle.Ogunquit, Carnero[0].Mission );
   modify_field( Lisle.Topanga, 1 );
}
table OldMinto {
   actions {
      Hyrum;
   }
   size : 1;
}
control Lacona {
   if ( valid( Carnero[ 0 ] ) ) {
      apply( OldMinto );
      if( CedarKey.Southam == 1 ) {
         apply( Roodhouse );
         apply( Clovis );
      }
   } else {
      apply( Beresford );
      if( CedarKey.Southam == 1 ) {
         apply( Pachuta );
      }
   }
}
field_list Bevington {
   Eclectic.Louviers;
   Eclectic.Felton;
   Eclectic.Duquoin;
   Eclectic.Bellmead;
   Eclectic.Triplett;
}
field_list Placida {
   Toccopola.Annandale;
   Toccopola.PellLake;
   Toccopola.Sweeny;
}
field_list Asherton {
   Linville.AvonLake;
   Linville.Glynn;
   Linville.Clifton;
   Linville.Basic;
}
field_list Carmel {
   Toccopola.PellLake;
   Toccopola.Sweeny;
   Plato.Ferry;
   Plato.Moark;
}
field_list_calculation Lublin {
    input {
        Bevington;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Paoli {
    input {
        Placida;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Daniels {
    input {
        Asherton;
    }
    algorithm : crc32;
    output_width : 32;
}
field_list_calculation Dorothy {
    input {
        Carmel;
    }
    algorithm : crc32;
    output_width : 32;
}
action Allgood() {
    modify_field_with_hash_based_offset(Bienville.Annawan, 0,
                                        Lublin, 4294967296);
}
action Affton() {
    modify_field_with_hash_based_offset(Bienville.Pearce, 0,
                                        Paoli, 4294967296);
}
action Greenhorn() {
    modify_field_with_hash_based_offset(Bienville.Pearce, 0,
                                        Daniels, 4294967296);
}
action Marley() {
    modify_field_with_hash_based_offset(Bienville.Manasquan, 0,
                                        Dorothy, 4294967296);
}
table Foristell {
   actions {
      Allgood;
   }
   size: 1;
}
control Glassboro {
   apply(Foristell);
}
table Naalehu {
   actions {
      Affton;
   }
   size: 1;
}
table Purdon {
   actions {
      Greenhorn;
   }
   size: 1;
}
control Macksburg {
   if ( valid( Toccopola ) ) {
      apply(Naalehu);
   } else {
      if ( valid( Linville ) ) {
         apply(Purdon);
      }
   }
}
table Wiota {
   actions {
      Marley;
   }
   size: 1;
}
control Belwood {
   if ( valid( Froid ) ) {
      apply(Wiota);
   }
}
action Godley() {
    modify_field(IttaBena.Covelo, Bienville.Annawan);
}
action Quealy() {
    modify_field(IttaBena.Covelo, Bienville.Pearce);
}
action Kanab() {
    modify_field(IttaBena.Covelo, Bienville.Manasquan);
}
@pragma action_default_only Sultana
@pragma immediate 0
table Pajaros {
   reads {
      Linda.valid : ternary;
      Panola.valid : ternary;
      Gakona.valid : ternary;
      Hiseville.valid : ternary;
      Tamms.valid : ternary;
      Wyndmoor.valid : ternary;
      Froid.valid : ternary;
      Toccopola.valid : ternary;
      Linville.valid : ternary;
      Eclectic.valid : ternary;
   }
   actions {
      Godley;
      Quealy;
      Kanab;
      Sultana;
   }
   size: 256;
}
action Haley() {
    modify_field(IttaBena.Kamas, Bienville.Manasquan);
}
@pragma immediate 0
table Gurley {
   reads {
      Linda.valid : ternary;
      Panola.valid : ternary;
      Wyndmoor.valid : ternary;
      Froid.valid : ternary;
   }
   actions {
      Haley;
      Sultana;
   }
   size: 6;
}
control Haverford {
   apply(Gurley);
   apply(Pajaros);
}
counter Hernandez {
   type : packets_and_bytes;
   direct : Miranda;
   min_width: 16;
}
table Miranda {
   reads {
      CedarKey.Norborne : exact;
      Daysville.Lugert : ternary;
      Daysville.Parmele : ternary;
      Lisle.Moapa : ternary;
      Lisle.OakCity : ternary;
      Lisle.Virden : ternary;
   }
   actions {
      Lignite;
      Sultana;
   }
   default_action : Sultana();
   size : 512;
}
table Ayden {
   reads {
      Lisle.Natalia : exact;
      Lisle.Odenton : exact;
      Lisle.Perrine : exact;
   }
   actions {
      Lignite;
      Sultana;
   }
   default_action : Sultana();
   size : 4096;
}
action Yetter() {
   modify_field(Lisle.Mogadore, 1 );
   modify_field(Cruso.Millett,
                0);
}
table Huxley {
   reads {
      Lisle.Natalia : exact;
      Lisle.Odenton : exact;
      Lisle.Perrine : exact;
      Lisle.McLean : exact;
   }
   actions {
      RyanPark;
      Yetter;
   }
   default_action : Yetter();
   size : 65536;
   support_timeout : true;
}
action Currie( Paisley, Westbrook ) {
   modify_field( Lisle.Bokeelia, Paisley );
   modify_field( Lisle.Immokalee, Westbrook );
}
action Cardenas() {
   modify_field( Lisle.Immokalee, 1 );
}
table Pinecrest {
   reads {
      Lisle.Perrine mask 0xfff : exact;
   }
   actions {
      Currie;
      Cardenas;
      Sultana;
   }
   default_action : Sultana();
   size : 4096;
}
action Tobique() {
   modify_field( Nondalton.Buncombe, 1 );
}
table RedCliff {
   reads {
      Lisle.Homeworth : ternary;
      Lisle.Suffern : exact;
      Lisle.Welch : exact;
   }
   actions {
      Tobique;
   }
   size: 512;
}
control Wauregan {
   apply( Miranda ) {
      Sultana {
         apply( Ayden ) {
            Sultana {
               if (CedarKey.Goessel == 0 and Lisle.Shauck == 0) {
                  apply( Huxley );
               }
               apply( Pinecrest );
               apply(RedCliff);
            }
         }
      }
   }
}
field_list Wailuku {
    Cruso.Millett;
    Lisle.Natalia;
    Lisle.Odenton;
    Lisle.Perrine;
    Lisle.McLean;
}
action BoxElder() {
   generate_digest(0, Wailuku);
}
table Kenefic {
   actions {
      BoxElder;
   }
   size : 1;
}
control Quitman {
   if (Lisle.Mogadore == 1) {
      apply( Kenefic );
   }
}
action Sofia( Corum, Rockdell ) {
   modify_field( Dorset.Oskawalik, Corum );
   modify_field( Ramah.Alcoma, Rockdell );
}
@pragma action_default_only Tununak
table Donegal {
   reads {
      Nondalton.Blanchard : exact;
      Dorset.Sasakwa mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Sofia;
      Tununak;
   }
   size : 8192;
}
@pragma atcam_partition_index Dorset.Oskawalik
@pragma atcam_number_partitions 8192
table Yscloskey {
   reads {
      Dorset.Oskawalik : exact;
      Dorset.Sasakwa mask 0x000007FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Ottertail;
      Kennebec;
      Sultana;
   }
   default_action : Sultana();
   size : 65536;
}
action Hackney( Tusayan, Clarinda ) {
   modify_field( Dorset.Woodrow, Tusayan );
   modify_field( Ramah.Alcoma, Clarinda );
}
@pragma action_default_only Sultana
table Frontenac {
   reads {
      Nondalton.Blanchard : exact;
      Dorset.Sasakwa : lpm;
   }
   actions {
      Hackney;
      Sultana;
   }
   size : 2048;
}
@pragma atcam_partition_index Dorset.Woodrow
@pragma atcam_number_partitions 2048
table Addicks {
   reads {
      Dorset.Woodrow : exact;
      Dorset.Sasakwa mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Ottertail;
      Kennebec;
      Sultana;
   }
   default_action : Sultana();
   size : 16384;
}
@pragma action_default_only Tununak
@pragma idletime_precision 1
table BigArm {
   reads {
      Nondalton.Blanchard : exact;
      CruzBay.Joplin : lpm;
   }
   actions {
      Ottertail;
      Kennebec;
      Tununak;
   }
   size : 1024;
   support_timeout : true;
}
action Waterflow( Littleton, Sherando ) {
   modify_field( CruzBay.WestPark, Littleton );
   modify_field( Ramah.Alcoma, Sherando );
}
@pragma action_default_only Sultana
table Coamo {
   reads {
      Nondalton.Blanchard : exact;
      CruzBay.Joplin : lpm;
   }
   actions {
      Waterflow;
      Sultana;
   }
   size : 16384;
}
@pragma ways 2
@pragma atcam_partition_index CruzBay.WestPark
@pragma atcam_number_partitions 16384
table Manning {
   reads {
      CruzBay.WestPark : exact;
      CruzBay.Joplin mask 0x000fffff : lpm;
   }
   actions {
      Ottertail;
      Kennebec;
      Sultana;
   }
   default_action : Sultana();
   size : 131072;
}
action Ottertail( Tagus ) {
   modify_field( Ramah.Alcoma, Tagus );
}
@pragma idletime_precision 1
table Bellville {
   reads {
      Nondalton.Blanchard : exact;
      CruzBay.Joplin : exact;
   }
   actions {
      Ottertail;
      Kennebec;
      Sultana;
   }
   default_action : Sultana();
   size : 65536;
   support_timeout : true;
}
@pragma idletime_precision 1
table Tonasket {
   reads {
      Nondalton.Blanchard : exact;
      Dorset.Sasakwa : exact;
   }
   actions {
      Ottertail;
      Kennebec;
      Sultana;
   }
   default_action : Sultana();
   size : 65536;
   support_timeout : true;
}
action Lecanto(Baytown, Bogota, Oxford) {
   modify_field(Homeacre.Tarlton, Oxford);
   modify_field(Homeacre.Rocheport, Baytown);
   modify_field(Homeacre.Neame, Bogota);
   modify_field(Homeacre.Gardena, 1);
   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}
action LaSal() {
   Lignite();
}
action Rembrandt(LaHoma) {
   modify_field(Homeacre.Aspetuck, 1);
   modify_field(Homeacre.Lanyon, LaHoma);
}
action Tununak(Southdown) {
   modify_field( Homeacre.Aspetuck, 1 );
   modify_field( Homeacre.Lanyon, 9 );
}
table Lyncourt {
   reads {
      Ramah.Alcoma : exact;
   }
   actions {
      Lecanto;
      LaSal;
      Rembrandt;
   }
   size : 65536;
}
action Servia( Ripley ) {
   modify_field(Homeacre.Aspetuck, 1);
   modify_field(Homeacre.Lanyon, Ripley);
}
table Arapahoe {
   actions {
      Servia;
   }
   default_action: Servia(0);
   size : 1;
}
control Radom {
   if ( Lisle.Grannis == 0 and Nondalton.Buncombe == 1 ) {
      if ( ( Nondalton.Fairchild == 1 ) and ( Lisle.Scissors == 1 ) ) {
         apply( Bellville ) {
            Sultana {
               apply(Coamo);
            }
         }
      } else if ( ( Nondalton.Welcome == 1 ) and ( Lisle.Nuyaka == 1 ) ) {
         apply( Tonasket ) {
            Sultana {
               apply( Frontenac );
            }
         }
      }
   }
}
control Elvaston {
   if ( Lisle.Grannis == 0 and Nondalton.Buncombe == 1 ) {
      if ( ( Nondalton.Fairchild == 1 ) and ( Lisle.Scissors == 1 ) ) {
         if ( CruzBay.WestPark != 0 ) {
            apply( Manning );
         } else if ( Ramah.Alcoma == 0 and Ramah.Pilger == 0 ) {
            apply( BigArm );
         }
      } else if ( ( Nondalton.Welcome == 1 ) and ( Lisle.Nuyaka == 1 ) ) {
         if ( Dorset.Woodrow != 0 ) {
            apply( Addicks );
         } else if ( Ramah.Alcoma == 0 and Ramah.Pilger == 0 ) {
            apply( Donegal ) {
               Sofia {
                  apply( Yscloskey );
               }
            }
         }
      } else if( Lisle.Immokalee == 1 ) {
         apply( Arapahoe );
      }
   }
}
control Denning {
   if( Ramah.Alcoma != 0 ) {
      apply( Lyncourt );
   }
}
action Kennebec( Franklin ) {
   modify_field( Ramah.Pilger, Franklin );
}
field_list Chavies {
   IttaBena.Kamas;
}
field_list_calculation Hewins {
    input {
        Chavies;
    }
    algorithm : identity;
    output_width : 66;
}
action_selector Murchison {
   selection_key : Hewins;
   selection_mode : resilient;
}
action_profile Honuapo {
   actions {
      Ottertail;
   }
   size : 65536;
   dynamic_action_selection : Murchison;
}
@pragma selector_max_group_size 256
table Candle {
   reads {
      Ramah.Pilger : exact;
   }
   action_profile : Honuapo;
   size : 2048;
}
control Bagwell {
   if ( Ramah.Pilger != 0 ) {
      apply( Candle );
   }
}
field_list Kress {
   IttaBena.Covelo;
}
field_list_calculation Sylva {
    input {
        Kress;
    }
    algorithm : identity;
    output_width : 51;
}
action_selector Cutten {
    selection_key : Sylva;
    selection_mode : resilient;
}
action Hurdtown(Tusculum) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Tusculum);
}
action_profile Haines {
    actions {
        Hurdtown;
        Sultana;
    }
    size : 1024;
    dynamic_action_selection : Cutten;
}
table Stonefort {
   reads {
      Homeacre.Hanford : exact;
   }
   action_profile: Haines;
   size : 1024;
}
control Mentone {
   if ((Homeacre.Hanford & 0x2000) == 0x2000) {
      apply(Stonefort);
   }
}
action Olivet() {
   modify_field(Homeacre.Rocheport, Lisle.Suffern);
   modify_field(Homeacre.Neame, Lisle.Welch);
   modify_field(Homeacre.Elkader, Lisle.Natalia);
   modify_field(Homeacre.Hanover, Lisle.Odenton);
   modify_field(Homeacre.Tarlton, Lisle.Perrine);
   invalidate( ig_intr_md_for_tm.ucast_egress_port );
}
table Delavan {
   actions {
      Olivet;
   }
   default_action : Olivet();
   size : 1;
}
control Hargis {
   apply( Delavan );
}
action Monkstown() {
   modify_field(Homeacre.Prunedale, 1);
   modify_field(Homeacre.DeerPark, 1);
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Lisle.Immokalee);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Homeacre.Tarlton);
}
action Finlayson() {
}
@pragma ways 1
table Wanilla {
   reads {
      Homeacre.Rocheport : exact;
      Homeacre.Neame : exact;
   }
   actions {
      Monkstown;
      Finlayson;
   }
   default_action : Finlayson;
   size : 1;
}
action Sherack() {
   modify_field(Homeacre.Penrose, 1);
   modify_field(Homeacre.Fragaria, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Homeacre.Tarlton, 4096);
}
table Comunas {
   actions {
      Sherack;
   }
   default_action : Sherack;
   size : 1;
}
action LaPuente() {
   modify_field(Homeacre.Trammel, 1);
   modify_field(Homeacre.DeerPark, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Homeacre.Tarlton);
}
table Excel {
   actions {
      LaPuente;
   }
   default_action : LaPuente();
   size : 1;
}
action RedElm(Correo) {
   modify_field(Homeacre.Tabler, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Correo);
   modify_field(Homeacre.Hanford, Correo);
}
action Tampa(Churchill) {
   modify_field(Homeacre.Penrose, 1);
   modify_field(Homeacre.Forbes, Churchill);
}
action Bowers() {
}
table Hahira {
   reads {
      Homeacre.Rocheport : exact;
      Homeacre.Neame : exact;
      Homeacre.Tarlton : exact;
   }
   actions {
      RedElm;
      Tampa;
      Lignite;
      Bowers;
   }
   default_action : Bowers();
   size : 65536;
}
control Inverness {
   if (Lisle.Grannis == 0 and not valid(Neosho) ) {
      apply(Hahira) {
         Bowers {
            apply(Wanilla) {
               Finlayson {
                  if ((Homeacre.Rocheport & 0x010000) == 0x010000) {
                     apply(Comunas);
                  } else {
                     apply(Excel);
                  }
               }
            }
         }
      }
   }
}
action Menomonie() {
   modify_field(Lisle.Armagh, 1);
   Lignite();
}
table Killen {
   actions {
      Menomonie;
   }
   default_action : Menomonie;
   size : 1;
}
control Gratiot {
   if (Lisle.Grannis == 0) {
      if ((Homeacre.Gardena==0) and (Lisle.Talkeetna==0) and (Lisle.Ackley==0) and (Lisle.McLean==Homeacre.Hanford)) {
         apply(Killen);
      } else {
         Mentone();
      }
   }
}
action Exton( Suwanee ) {
   modify_field( Homeacre.Bartolo, Suwanee );
}
action Belcher() {
   modify_field( Homeacre.Bartolo, Homeacre.Tarlton );
}
table Pelland {
   reads {
      eg_intr_md.egress_port : exact;
      Homeacre.Tarlton : exact;
   }
   actions {
      Exton;
      Belcher;
   }
   default_action : Belcher;
   size : 4096;
}
control Newland {
   apply( Pelland );
}
action Cordell( Norwood, Kinsley ) {
   modify_field( Homeacre.Trenary, Norwood );
   modify_field( Homeacre.BigPlain, Kinsley );
}
table Wewela {
   reads {
      Homeacre.Sparkill : exact;
   }
   actions {
      Cordell;
   }
   size : 8;
}
action Spanaway() {
   modify_field( Homeacre.SanRemo, 1 );
   modify_field( Homeacre.Sparkill, 2 );
}
action Joaquin() {
   modify_field( Homeacre.SanRemo, 1 );
   modify_field( Homeacre.Sparkill, 1 );
}
table Alden {
   reads {
      Homeacre.Penzance : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Spanaway;
      Joaquin;
   }
   default_action : Sultana();
   size : 16;
}
action Flatwoods(Potter, Choptank, EastDuke, Cimarron) {
   modify_field( Homeacre.Newsoms, Potter );
   modify_field( Homeacre.Stoystown, Choptank );
   modify_field( Homeacre.BigFork, EastDuke );
   modify_field( Homeacre.Udall, Cimarron );
}
table Ingleside {
   reads {
        Homeacre.Maltby : exact;
   }
   actions {
      Flatwoods;
   }
   size : 256;
}
action McCammon() {
   no_op();
}
action SwissAlp() {
   modify_field( Eclectic.Triplett, Carnero[0].Westel );
   remove_header( Carnero[0] );
}
table Mecosta {
   actions {
      SwissAlp;
   }
   default_action : SwissAlp;
   size : 1;
}
action Danbury() {
   no_op();
}
action Ferrum() {
   add_header( Carnero[ 0 ] );
   modify_field( Carnero[0].Mission, Homeacre.Bartolo );
   modify_field( Carnero[0].Westel, Eclectic.Triplett );
   modify_field( Carnero[0].Wegdahl, Shivwits.Verdemont );
   modify_field( Carnero[0].Barnwell, Shivwits.Clarkdale );
   modify_field( Eclectic.Triplett, 0x8100 );
}
table McFaddin {
   reads {
      Homeacre.Bartolo : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Danbury;
      Ferrum;
   }
   default_action : Ferrum;
   size : 128;
}
action Indios() {
   modify_field(Eclectic.Louviers, Homeacre.Rocheport);
   modify_field(Eclectic.Felton, Homeacre.Neame);
   modify_field(Eclectic.Duquoin, Homeacre.Trenary);
   modify_field(Eclectic.Bellmead, Homeacre.BigPlain);
}
action Bomarton() {
   Indios();
   add_to_field(Toccopola.Gonzalez, -1);
   modify_field(Toccopola.Sabetha, Shivwits.Moose);
}
action Paskenta() {
   Indios();
   add_to_field(Linville.Olyphant, -1);
   modify_field(Linville.Bevier, Shivwits.Moose);
}
action Alsea() {
   modify_field(Toccopola.Sabetha, Shivwits.Moose);
}
action Twichell() {
   modify_field(Linville.Bevier, Shivwits.Moose);
}
action Struthers() {
   Ferrum();
}
action Antonito( Barron, Earlsboro, Darmstadt, Gracewood ) {
   add_header( Highcliff );
   modify_field( Highcliff.Louviers, Barron );
   modify_field( Highcliff.Felton, Earlsboro );
   modify_field( Highcliff.Duquoin, Darmstadt );
   modify_field( Highcliff.Bellmead, Gracewood );
   modify_field( Highcliff.Triplett, 0xBF00 );
   add_header( Neosho );
   modify_field( Neosho.Valdosta, Homeacre.Newsoms );
   modify_field( Neosho.Winside, Homeacre.Stoystown );
   modify_field( Neosho.Craigmont, Homeacre.BigFork );
   modify_field( Neosho.Illmo, Homeacre.Udall );
   modify_field( Neosho.Cement, Homeacre.Lanyon );
}
action Lebanon() {
   remove_header( Tenino );
   remove_header( Froid );
   remove_header( Plato );
   copy_header( Eclectic, Tamms );
   remove_header( Tamms );
   remove_header( Toccopola );
}
action Conger() {
   remove_header( Highcliff );
   remove_header( Neosho );
}
action Opelousas() {
   Lebanon();
   modify_field(Gakona.Sabetha, Shivwits.Moose);
}
action GlenAvon() {
   Lebanon();
   modify_field(Hiseville.Bevier, Shivwits.Moose);
}
table Hematite {
   reads {
      Homeacre.Alvordton : exact;
      Homeacre.Sparkill : exact;
      Homeacre.Gardena : exact;
      Toccopola.valid : ternary;
      Linville.valid : ternary;
      Gakona.valid : ternary;
      Hiseville.valid : ternary;
   }
   actions {
      Bomarton;
      Paskenta;
      Alsea;
      Twichell;
      Struthers;
      Antonito;
      Conger;
      Lebanon;
      Opelousas;
      GlenAvon;
   }
   size : 512;
}
control Gambrills {
   apply( Mecosta );
}
control Perrin {
   apply( McFaddin );
}
control Goodwater {
   apply( Alden ) {
      Sultana {
         apply( Wewela );
      }
   }
   apply( Ingleside );
   apply( Hematite );
}
field_list Chewalla {
    Cruso.Millett;
    Lisle.Perrine;
    Tamms.Duquoin;
    Tamms.Bellmead;
    Toccopola.PellLake;
}
action Daisytown() {
   generate_digest(0, Chewalla);
}
table Beltrami {
   actions {
      Daisytown;
   }
   default_action : Daisytown;
   size : 1;
}
control Persia {
   if (Lisle.Shauck == 1) {
      apply(Beltrami);
   }
}
action Campbell() {
   modify_field( Shivwits.Verdemont, CedarKey.Evelyn );
}
action Cecilton() {
   modify_field( Shivwits.Verdemont, Carnero[0].Wegdahl );
   modify_field( Lisle.Ganado, Carnero[0].Westel );
}
action Wamego() {
   modify_field( Shivwits.Moose, CedarKey.Zebina );
}
action Stovall() {
   modify_field( Shivwits.Moose, CruzBay.Daykin );
}
action Goree() {
   modify_field( Shivwits.Moose, Dorset.Bagdad );
}
action Berlin( Piedmont, McCallum ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Piedmont );
   modify_field( ig_intr_md_for_tm.qid, McCallum );
}
table Gresston {
   reads {
     Lisle.Gibbs : exact;
   }
   actions {
     Campbell;
     Cecilton;
   }
   size : 2;
}
table Elkland {
   reads {
     Lisle.Scissors : exact;
     Lisle.Nuyaka : exact;
   }
   actions {
     Wamego;
     Stovall;
     Goree;
   }
   size : 3;
}
table Yakutat {
   reads {
      CedarKey.Vallejo : ternary;
      CedarKey.Evelyn : ternary;
      Shivwits.Verdemont : ternary;
      Shivwits.Moose : ternary;
      Shivwits.RoseBud : ternary;
   }
   actions {
      Berlin;
   }
   size : 81;
}
action Koloa( Hoagland, Neponset ) {
   bit_or( Shivwits.Roosville, Shivwits.Roosville, Hoagland );
   bit_or( Shivwits.Canovanas, Shivwits.Canovanas, Neponset );
}
table Kerby {
   actions {
      Koloa;
   }
   default_action : Koloa(0, 0);
   size : 1;
}
action Eddystone( Moultrie ) {
   modify_field( Shivwits.Moose, Moultrie );
}
action Stone( Grabill ) {
   modify_field( Shivwits.Verdemont, Grabill );
}
action Drake( Exeland, BigBay ) {
   modify_field( Shivwits.Verdemont, Exeland );
   modify_field( Shivwits.Moose, BigBay );
}
table Taiban {
   reads {
      CedarKey.Vallejo : exact;
      Shivwits.Roosville : exact;
      Shivwits.Canovanas : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Eddystone;
      Stone;
      Drake;
   }
   size : 512;
}
control Ranchito {
   apply( Gresston );
   apply( Elkland );
}
control Fireco {
   apply( Yakutat );
}
control SourLake {
   apply( Kerby );
   apply( Taiban );
}
action Maiden( Friend ) {
   modify_field( Shivwits.Stobo, Friend );
}
action Hallwood( Hayfork, Tullytown ) {
   Maiden( Hayfork );
   modify_field( ig_intr_md_for_tm.qid, Tullytown );
}
table Sodaville {
   reads {
      Homeacre.Aspetuck : ternary;
      ig_intr_md_for_tm.copy_to_cpu : ternary;
      Homeacre.Lanyon : ternary;
      Lisle.Scissors : ternary;
      Lisle.Nuyaka : ternary;
      Lisle.Ganado : ternary;
      Lisle.Aplin : ternary;
      Lisle.Seattle : ternary;
      Homeacre.Gardena : ternary;
      Plato.Ferry : ternary;
      Plato.Moark : ternary;
   }
   actions {
      Maiden;
      Hallwood;
   }
   size : 512;
}
meter McDougal {
   type : packets;
   static : Esmond;
   instance_count : 2304;
}
action Owyhee(Chatmoss) {
   execute_meter( McDougal, Chatmoss, ig_intr_md_for_tm.packet_color );
}
table Esmond {
   reads {
      CedarKey.Norborne : exact;
      Shivwits.Stobo : exact;
   }
   actions {
      Owyhee;
   }
   size : 2304;
}
control Bemis {
   if ( CedarKey.Southam != 0 ) {
      apply( Sodaville );
   }
}
control Angus {
    if ( (
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x1 ) == 0 ) ) and ( Homeacre.Aspetuck == 1 ) ) or
           ( ( ( ( ig_intr_md_for_tm.drop_ctl & 0x2 ) == 0 ) ) and ( ig_intr_md_for_tm.copy_to_cpu == 1 ) )
       ) ) {
      apply( Esmond );
   }
}
action Adelino( Crossett ) {
   modify_field( Homeacre.Penzance, 0 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Crossett );
   modify_field( Homeacre.Maltby, ig_intr_md.ingress_port );
}
action Pineland( Hallville ) {
   modify_field( Homeacre.Penzance, 1 );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Hallville );
   modify_field( Homeacre.Maltby, ig_intr_md.ingress_port );
}
action Trujillo() {
   modify_field( Homeacre.Penzance, 0 );
}
action NewRoads() {
   modify_field( Homeacre.Penzance, 1 );
   modify_field( Homeacre.Maltby, ig_intr_md.ingress_port );
}
@pragma ternary 1
table Allegan {
   reads {
      Homeacre.Aspetuck : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      Nondalton.Buncombe : exact;
      CedarKey.Swenson : ternary;
      Homeacre.Lanyon : ternary;
   }
   actions {
      Adelino;
      Pineland;
      Trujillo;
      NewRoads;
   }
   size : 512;
}
control Silica {
   apply( Allegan );
}
counter Bosco {
   type : packets_and_bytes;
   instance_count : 1024;
   min_width : 128;
}
action Manakin( Honobia ) {
   count( Bosco, Honobia );
}
table LaSalle {
   reads {
      eg_intr_md.egress_port mask 0x7f: exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }
   actions {
     Manakin;
   }
   size : 1024;
}
control Hayfield {
   apply( LaSalle );
}
action OldMines()
{
   Lignite();
}
action Cloverly()
{
   modify_field(Homeacre.Alvordton, 2);
   bit_or(Homeacre.Hanford, 0x2000, Neosho.Illmo);
}
action Captiva( Escondido ) {
   modify_field(Homeacre.Alvordton, 2);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Escondido);
   modify_field(Homeacre.Hanford, Escondido);
}
table Warba {
   reads {
      Neosho.Valdosta : exact;
      Neosho.Winside : exact;
      Neosho.Craigmont : exact;
      Neosho.Illmo : exact;
   }
   actions {
      Cloverly;
      Captiva;
      OldMines;
   }
   default_action : OldMines();
   size : 256;
}
control Homeland {
   apply( Warba );
}
action Progreso( Dugger, RioLinda, Meyers, Pease ) {
   modify_field( Ashley.Sudbury, Dugger );
   modify_field( Nicolaus.DeLancey, Meyers );
   modify_field( Nicolaus.Bammel, RioLinda );
   modify_field( Nicolaus.Nephi, Pease );
}
table ElMango {
   reads {
     CruzBay.Joplin : exact;
     Lisle.Homeworth : exact;
   }
   actions {
      Progreso;
   }
  size : 16384;
}
action Tindall(Swedeborg, Ripon, Benkelman) {
   modify_field( Nicolaus.Bammel, Swedeborg );
   modify_field( Nicolaus.DeLancey, Ripon );
   modify_field( Nicolaus.Nephi, Benkelman );
}
table Armijo {
   reads {
     CruzBay.Euren : exact;
     Ashley.Sudbury : exact;
   }
   actions {
      Tindall;
   }
   size : 16384;
}
action Fleetwood( Nestoria, Sublett, Bethesda ) {
   modify_field( Caban.Halley, Nestoria );
   modify_field( Caban.Calimesa, Sublett );
   modify_field( Caban.Mosinee, Bethesda );
}
table Mustang {
   reads {
     Homeacre.Rocheport : exact;
     Homeacre.Neame : exact;
     Homeacre.Tarlton : exact;
   }
   actions {
      Fleetwood;
   }
   size : 16384;
}
action Boquet() {
   modify_field( Homeacre.DeerPark, 1 );
}
action Lansing( Montello ) {
   Boquet();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Nicolaus.Bammel );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Montello, Nicolaus.Nephi );
}
action Davie( Goudeau ) {
   Boquet();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Caban.Halley );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Goudeau, Caban.Mosinee );
}
action DelMar( Nason ) {
   Boquet();
   add( ig_intr_md_for_tm.mcast_grp_a, Homeacre.Tarlton,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Nason );
}
action Cullen() {
   modify_field( Homeacre.Camino, 1 );
}
table Kensett {
   reads {
     Nicolaus.DeLancey : ternary;
     Nicolaus.Bammel : ternary;
     Caban.Halley : ternary;
     Caban.Calimesa : ternary;
     Lisle.Aplin :ternary;
     Lisle.Talkeetna:ternary;
   }
   actions {
      Lansing;
      Davie;
      DelMar;
      Cullen;
   }
   size : 32;
}
control Burden {
   if( Lisle.Grannis == 0 and
       Nondalton.Waynoka == 1 and
       Lisle.Selby == 1 ) {
      apply( ElMango );
   }
}
control Pickering {
   if( Ashley.Sudbury != 0 ) {
      apply( Armijo );
   }
}
control Veteran {
   if( Lisle.Grannis == 0 and Lisle.Talkeetna==1 ) {
      apply( Mustang );
   }
}
control Heavener {
   if( Lisle.Talkeetna == 1 ) {
      apply(Kensett);
   }
}
action Montour(Protem) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, IttaBena.Covelo );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Protem );
}
table Sunbury {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Montour;
    }
    size : 512;
}
control Wataga {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Sunbury);
   }
}
action Maytown( Waretown, Chelsea ) {
   modify_field( Homeacre.Tarlton, Waretown );
   modify_field( Homeacre.Gardena, Chelsea );
}
action Plains() {
   drop();
}
table Chunchula {
   reads {
     eg_intr_md.egress_rid: exact;
   }
   actions {
      Maytown;
   }
   default_action: Plains;
   size : 57344;
}
control Borth {
   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Chunchula);
   }
}
counter Boistfort {
   type : packets;
   direct: Muncie;
   min_width: 63;
}
table Muncie {
   reads {
     Sagamore.RichHill mask 0x7fff : exact;
   }
   actions {
      Sultana;
   }
   default_action: Sultana();
   size : 32768;
}
action Alston() {
   modify_field( Atlas.Havana, Lisle.Aplin );
   modify_field( Atlas.ElkRidge, CruzBay.Daykin );
   modify_field( Atlas.Quamba, Lisle.Seattle );
   modify_field( Atlas.Hiwassee, Lisle.Renton );
   bit_xor( Atlas.Greenlawn, Lisle.Hulbert, 1 );
}
action Wyandanch() {
   modify_field( Atlas.Havana, Lisle.Aplin );
   modify_field( Atlas.ElkRidge, Dorset.Bagdad );
   modify_field( Atlas.Quamba, Lisle.Seattle );
   modify_field( Atlas.Hiwassee, Lisle.Renton );
   bit_xor( Atlas.Greenlawn, Lisle.Hulbert, 1 );
}
action Brockton( Tramway ) {
   Alston();
   modify_field( Atlas.Covina, Tramway );
}
action Greycliff( Bonilla ) {
   Wyandanch();
   modify_field( Atlas.Covina, Bonilla );
}
table Woodburn {
   reads {
     CruzBay.Euren : ternary;
   }
   actions {
      Brockton;
   }
   default_action : Alston;
  size : 2048;
}
table Lofgreen {
   reads {
     Dorset.Despard : ternary;
   }
   actions {
      Greycliff;
   }
   default_action : Wyandanch;
   size : 1024;
}
action Dillsburg( Quinnesec ) {
   modify_field( Atlas.Dubbs, Quinnesec );
}
table Bunavista {
   reads {
     CruzBay.Joplin : ternary;
   }
   actions {
      Dillsburg;
   }
   size : 512;
}
table Roseville {
   reads {
     Dorset.Sasakwa : ternary;
   }
   actions {
      Dillsburg;
   }
   size : 512;
}
action Laplace( Slick ) {
   modify_field( Atlas.Cornell, Slick );
}
table Harney {
   reads {
     Lisle.Pasadena : ternary;
   }
   actions {
      Laplace;
   }
   size : 512;
}
action Heizer( Swisher ) {
   modify_field( Atlas.Sitka, Swisher );
}
table Dovray {
   reads {
     Lisle.Omemee : ternary;
   }
   actions {
      Heizer;
   }
   size : 512;
}
action Chaires( Baldridge ) {
   modify_field( Atlas.Dunmore, Baldridge );
}
action Kittredge( Ladner ) {
   modify_field( Atlas.Dunmore, Ladner );
}
table Glendevey {
   reads {
     Lisle.Scissors : exact;
     Lisle.Nuyaka : exact;
     Lisle.Vidal : exact;
     Lisle.Homeworth : exact;
   }
   actions {
      Chaires;
      Sultana;
   }
   default_action : Sultana();
   size : 4096;
}
table Gobler {
   reads {
     Lisle.Scissors : exact;
     Lisle.Nuyaka : exact;
     Lisle.Vidal : exact;
     CedarKey.Vesuvius : exact;
   }
   actions {
      Kittredge;
   }
   size : 512;
}
control Crary {
   if( Lisle.Scissors == 1 ) {
      apply( Woodburn );
      apply( Bunavista );
   } else if( Lisle.Nuyaka == 1 ) {
      apply( Lofgreen );
      apply( Roseville );
   }
   if( ( Lisle.Antlers != 0 and Lisle.Tillatoba == 1 ) or
       ( Lisle.Antlers == 0 and Plato.valid == 1 ) ) {
      apply( Harney );
      if( Lisle.Aplin != 1 ){
         apply( Dovray );
      }
   }
   apply( Glendevey ) {
      Sultana {
         apply( Gobler );
      }
   }
}
action Swansea() {
}
action McClure() {
}
action Azalia() {
   drop();
}
action Rosalie() {
   drop();
}
table Seaforth {
   reads {
     Sagamore.RichHill mask 0x00018000 : ternary;
   }
   actions {
      Swansea;
      McClure;
      Azalia;
      Rosalie;
   }
   size : 16;
}
control Zarah {
   apply( Seaforth );
   apply( Muncie );
}
   metadata Brinkley Sagamore;
   action WindLake( Kaluaaha ) {
          max( Sagamore.RichHill, Sagamore.RichHill, Kaluaaha );
   }
@pragma ways 1
table Oronogo {
   reads {
      Atlas.Dunmore : exact;
      Atlas.Covina : exact;
      Atlas.Dubbs : exact;
      Atlas.Cornell : exact;
      Atlas.Sitka : exact;
      Atlas.Havana : exact;
      Atlas.ElkRidge : exact;
      Atlas.Quamba : exact;
      Atlas.Hiwassee : exact;
      Atlas.Greenlawn : exact;
   }
   actions {
      WindLake;
   }
   size : 4096;
}
control Cadwell {
   apply( Oronogo );
}
table Anselmo {
   reads {
      Atlas.Dunmore : exact;
      Atlas.Covina : ternary;
      Atlas.Dubbs : ternary;
      Atlas.Cornell : ternary;
      Atlas.Sitka : ternary;
      Atlas.Havana : ternary;
      Atlas.ElkRidge : ternary;
      Atlas.Quamba : ternary;
      Atlas.Hiwassee : ternary;
      Atlas.Greenlawn : ternary;
   }
   actions {
      WindLake;
   }
   size : 512;
}
control Pickett {
   apply( Anselmo );
}
@pragma pa_no_init ingress Wenden.Covina
@pragma pa_no_init ingress Wenden.Dubbs
@pragma pa_no_init ingress Wenden.Cornell
@pragma pa_no_init ingress Wenden.Sitka
@pragma pa_no_init ingress Wenden.Havana
@pragma pa_no_init ingress Wenden.ElkRidge
@pragma pa_no_init ingress Wenden.Quamba
@pragma pa_no_init ingress Wenden.Hiwassee
@pragma pa_no_init ingress Wenden.Greenlawn
metadata Calva Wenden;
@pragma ways 1
table Valentine {
   reads {
      Atlas.Dunmore : exact;
      Wenden.Covina : exact;
      Wenden.Dubbs : exact;
      Wenden.Cornell : exact;
      Wenden.Sitka : exact;
      Wenden.Havana : exact;
      Wenden.ElkRidge : exact;
      Wenden.Quamba : exact;
      Wenden.Hiwassee : exact;
      Wenden.Greenlawn : exact;
   }
   actions {
      WindLake;
   }
   size : 8192;
}
action Novinger( Weehawken, Tillicum, Tanana, Amonate, Newtown, Bowlus, Heaton, Hiland, Risco ) {
   bit_and( Wenden.Covina, Atlas.Covina, Weehawken );
   bit_and( Wenden.Dubbs, Atlas.Dubbs, Tillicum );
   bit_and( Wenden.Cornell, Atlas.Cornell, Tanana );
   bit_and( Wenden.Sitka, Atlas.Sitka, Amonate );
   bit_and( Wenden.Havana, Atlas.Havana, Newtown );
   bit_and( Wenden.ElkRidge, Atlas.ElkRidge, Bowlus );
   bit_and( Wenden.Quamba, Atlas.Quamba, Heaton );
   bit_and( Wenden.Hiwassee, Atlas.Hiwassee, Hiland );
   bit_and( Wenden.Greenlawn, Atlas.Greenlawn, Risco );
}
table Accord {
   reads {
      Atlas.Dunmore : exact;
   }
   actions {
      Novinger;
   }
   default_action : Novinger(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Fishers {
   apply( Accord );
}
control Freeville {
   apply( Valentine );
}
table Venturia {
   reads {
      Atlas.Dunmore : exact;
      Atlas.Covina : ternary;
      Atlas.Dubbs : ternary;
      Atlas.Cornell : ternary;
      Atlas.Sitka : ternary;
      Atlas.Havana : ternary;
      Atlas.ElkRidge : ternary;
      Atlas.Quamba : ternary;
      Atlas.Hiwassee : ternary;
      Atlas.Greenlawn : ternary;
   }
   actions {
      WindLake;
   }
   size : 512;
}
control Normangee {
   apply( Venturia );
}
@pragma ways 1
table Twisp {
   reads {
      Atlas.Dunmore : exact;
      Wenden.Covina : exact;
      Wenden.Dubbs : exact;
      Wenden.Cornell : exact;
      Wenden.Sitka : exact;
      Wenden.Havana : exact;
      Wenden.ElkRidge : exact;
      Wenden.Quamba : exact;
      Wenden.Hiwassee : exact;
      Wenden.Greenlawn : exact;
   }
   actions {
      WindLake;
   }
   size : 4096;
}
action Balfour( Gillette, Frontier, Asher, Riverland, Mather, Kalkaska, Glenolden, Frankston, Roachdale ) {
   bit_and( Wenden.Covina, Atlas.Covina, Gillette );
   bit_and( Wenden.Dubbs, Atlas.Dubbs, Frontier );
   bit_and( Wenden.Cornell, Atlas.Cornell, Asher );
   bit_and( Wenden.Sitka, Atlas.Sitka, Riverland );
   bit_and( Wenden.Havana, Atlas.Havana, Mather );
   bit_and( Wenden.ElkRidge, Atlas.ElkRidge, Kalkaska );
   bit_and( Wenden.Quamba, Atlas.Quamba, Glenolden );
   bit_and( Wenden.Hiwassee, Atlas.Hiwassee, Frankston );
   bit_and( Wenden.Greenlawn, Atlas.Greenlawn, Roachdale );
}
table Alameda {
   reads {
      Atlas.Dunmore : exact;
   }
   actions {
      Balfour;
   }
   default_action : Balfour(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Litroe {
   apply( Alameda );
}
control Wyncote {
   apply( Twisp );
}
table Pinebluff {
   reads {
      Atlas.Dunmore : exact;
      Atlas.Covina : ternary;
      Atlas.Dubbs : ternary;
      Atlas.Cornell : ternary;
      Atlas.Sitka : ternary;
      Atlas.Havana : ternary;
      Atlas.ElkRidge : ternary;
      Atlas.Quamba : ternary;
      Atlas.Hiwassee : ternary;
      Atlas.Greenlawn : ternary;
   }
   actions {
      WindLake;
   }
   size : 512;
}
control Halbur {
   apply( Pinebluff );
}
@pragma ways 1
table Tahuya {
   reads {
      Atlas.Dunmore : exact;
      Wenden.Covina : exact;
      Wenden.Dubbs : exact;
      Wenden.Cornell : exact;
      Wenden.Sitka : exact;
      Wenden.Havana : exact;
      Wenden.ElkRidge : exact;
      Wenden.Quamba : exact;
      Wenden.Hiwassee : exact;
      Wenden.Greenlawn : exact;
   }
   actions {
      WindLake;
   }
   size : 4096;
}
action Linden( Lindsay, Globe, Panacea, Buckeye, Inkom, Nevis, DuBois, Laton, Aldrich ) {
   bit_and( Wenden.Covina, Atlas.Covina, Lindsay );
   bit_and( Wenden.Dubbs, Atlas.Dubbs, Globe );
   bit_and( Wenden.Cornell, Atlas.Cornell, Panacea );
   bit_and( Wenden.Sitka, Atlas.Sitka, Buckeye );
   bit_and( Wenden.Havana, Atlas.Havana, Inkom );
   bit_and( Wenden.ElkRidge, Atlas.ElkRidge, Nevis );
   bit_and( Wenden.Quamba, Atlas.Quamba, DuBois );
   bit_and( Wenden.Hiwassee, Atlas.Hiwassee, Laton );
   bit_and( Wenden.Greenlawn, Atlas.Greenlawn, Aldrich );
}
table Arriba {
   reads {
      Atlas.Dunmore : exact;
   }
   actions {
      Linden;
   }
   default_action : Linden(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Cowen {
   apply( Arriba );
}
control Campo {
   apply( Tahuya );
}
table Rippon {
   reads {
      Atlas.Dunmore : exact;
      Atlas.Covina : ternary;
      Atlas.Dubbs : ternary;
      Atlas.Cornell : ternary;
      Atlas.Sitka : ternary;
      Atlas.Havana : ternary;
      Atlas.ElkRidge : ternary;
      Atlas.Quamba : ternary;
      Atlas.Hiwassee : ternary;
      Atlas.Greenlawn : ternary;
   }
   actions {
      WindLake;
   }
   size : 512;
}
control Wheaton {
   apply( Rippon );
}
@pragma ways 1
table Lakefield {
   reads {
      Atlas.Dunmore : exact;
      Wenden.Covina : exact;
      Wenden.Dubbs : exact;
      Wenden.Cornell : exact;
      Wenden.Sitka : exact;
      Wenden.Havana : exact;
      Wenden.ElkRidge : exact;
      Wenden.Quamba : exact;
      Wenden.Hiwassee : exact;
      Wenden.Greenlawn : exact;
   }
   actions {
      WindLake;
   }
   size : 8192;
}
action BealCity( Rumson, Bayville, Bennet, Portville, Sully, Weiser, Palco, LaPalma, Mankato ) {
   bit_and( Wenden.Covina, Atlas.Covina, Rumson );
   bit_and( Wenden.Dubbs, Atlas.Dubbs, Bayville );
   bit_and( Wenden.Cornell, Atlas.Cornell, Bennet );
   bit_and( Wenden.Sitka, Atlas.Sitka, Portville );
   bit_and( Wenden.Havana, Atlas.Havana, Sully );
   bit_and( Wenden.ElkRidge, Atlas.ElkRidge, Weiser );
   bit_and( Wenden.Quamba, Atlas.Quamba, Palco );
   bit_and( Wenden.Hiwassee, Atlas.Hiwassee, LaPalma );
   bit_and( Wenden.Greenlawn, Atlas.Greenlawn, Mankato );
}
table Loyalton {
   reads {
      Atlas.Dunmore : exact;
   }
   actions {
      BealCity;
   }
   default_action : BealCity(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Parksley {
   apply( Loyalton );
}
control Peosta {
   apply( Lakefield );
}
table Caborn {
   reads {
      Atlas.Dunmore : exact;
      Atlas.Covina : ternary;
      Atlas.Dubbs : ternary;
      Atlas.Cornell : ternary;
      Atlas.Sitka : ternary;
      Atlas.Havana : ternary;
      Atlas.ElkRidge : ternary;
      Atlas.Quamba : ternary;
      Atlas.Hiwassee : ternary;
      Atlas.Greenlawn : ternary;
   }
   actions {
      WindLake;
   }
   size : 512;
}
control Noorvik {
   apply( Caborn );
}
@pragma ways 1
table Wausaukee {
   reads {
      Atlas.Dunmore : exact;
      Wenden.Covina : exact;
      Wenden.Dubbs : exact;
      Wenden.Cornell : exact;
      Wenden.Sitka : exact;
      Wenden.Havana : exact;
      Wenden.ElkRidge : exact;
      Wenden.Quamba : exact;
      Wenden.Hiwassee : exact;
      Wenden.Greenlawn : exact;
   }
   actions {
      WindLake;
   }
   size : 8192;
}
action Corvallis( Kranzburg, Abernant, Manteo, Wymore, Philbrook, Pittsboro, Ambrose, Yulee, Campton ) {
   bit_and( Wenden.Covina, Atlas.Covina, Kranzburg );
   bit_and( Wenden.Dubbs, Atlas.Dubbs, Abernant );
   bit_and( Wenden.Cornell, Atlas.Cornell, Manteo );
   bit_and( Wenden.Sitka, Atlas.Sitka, Wymore );
   bit_and( Wenden.Havana, Atlas.Havana, Philbrook );
   bit_and( Wenden.ElkRidge, Atlas.ElkRidge, Pittsboro );
   bit_and( Wenden.Quamba, Atlas.Quamba, Ambrose );
   bit_and( Wenden.Hiwassee, Atlas.Hiwassee, Yulee );
   bit_and( Wenden.Greenlawn, Atlas.Greenlawn, Campton );
}
table Broadwell {
   reads {
      Atlas.Dunmore : exact;
   }
   actions {
      Corvallis;
   }
   default_action : Corvallis(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Dutton {
   apply( Broadwell );
}
control Pelican {
   apply( Wausaukee );
}
table Range {
   reads {
      Atlas.Dunmore : exact;
      Atlas.Covina : ternary;
      Atlas.Dubbs : ternary;
      Atlas.Cornell : ternary;
      Atlas.Sitka : ternary;
      Atlas.Havana : ternary;
      Atlas.ElkRidge : ternary;
      Atlas.Quamba : ternary;
      Atlas.Hiwassee : ternary;
      Atlas.Greenlawn : ternary;
   }
   actions {
      WindLake;
   }
   size : 512;
}
control Milam {
   apply( Range );
}
@pragma ways 1
table Pearl {
   reads {
      Atlas.Dunmore : exact;
      Wenden.Covina : exact;
      Wenden.Dubbs : exact;
      Wenden.Cornell : exact;
      Wenden.Sitka : exact;
      Wenden.Havana : exact;
      Wenden.ElkRidge : exact;
      Wenden.Quamba : exact;
      Wenden.Hiwassee : exact;
      Wenden.Greenlawn : exact;
   }
   actions {
      WindLake;
   }
   size : 4096;
}
action Steprock( Pierson, Offerle, Wimberley, Newburgh, Cutler, Moweaqua, Caguas, Alsen, Williams ) {
   bit_and( Wenden.Covina, Atlas.Covina, Pierson );
   bit_and( Wenden.Dubbs, Atlas.Dubbs, Offerle );
   bit_and( Wenden.Cornell, Atlas.Cornell, Wimberley );
   bit_and( Wenden.Sitka, Atlas.Sitka, Newburgh );
   bit_and( Wenden.Havana, Atlas.Havana, Cutler );
   bit_and( Wenden.ElkRidge, Atlas.ElkRidge, Moweaqua );
   bit_and( Wenden.Quamba, Atlas.Quamba, Caguas );
   bit_and( Wenden.Hiwassee, Atlas.Hiwassee, Alsen );
   bit_and( Wenden.Greenlawn, Atlas.Greenlawn, Williams );
}
table Poneto {
   reads {
      Atlas.Dunmore : exact;
   }
   actions {
      Steprock;
   }
   default_action : Steprock(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Ocilla {
   apply( Poneto );
}
control Lapeer {
   apply( Pearl );
}
table Burket {
   reads {
      Atlas.Dunmore : exact;
      Atlas.Covina : ternary;
      Atlas.Dubbs : ternary;
      Atlas.Cornell : ternary;
      Atlas.Sitka : ternary;
      Atlas.Havana : ternary;
      Atlas.ElkRidge : ternary;
      Atlas.Quamba : ternary;
      Atlas.Hiwassee : ternary;
      Atlas.Greenlawn : ternary;
   }
   actions {
      WindLake;
   }
   size : 512;
}
control ElmGrove {
   apply( Burket );
}
@pragma pa_no_init egress Coolin.Covina
@pragma pa_no_init egress Coolin.Dubbs
@pragma pa_no_init egress Coolin.Cornell
@pragma pa_no_init egress Coolin.Sitka
@pragma pa_no_init egress Coolin.Havana
@pragma pa_no_init egress Coolin.ElkRidge
@pragma pa_no_init egress Coolin.Quamba
@pragma pa_no_init egress Coolin.Hiwassee
@pragma pa_no_init egress Coolin.Greenlawn
metadata Calva Coolin;
@pragma ways 1
table Raeford {
   reads {
      Atlas.Dunmore : exact;
      Coolin.Covina : exact;
      Coolin.Dubbs : exact;
      Coolin.Cornell : exact;
      Coolin.Sitka : exact;
      Coolin.Havana : exact;
      Coolin.ElkRidge : exact;
      Coolin.Quamba : exact;
      Coolin.Hiwassee : exact;
      Coolin.Greenlawn : exact;
   }
   actions {
      WindLake;
   }
   size : 4096;
}
action Newtonia( LaMarque, Groesbeck, RedLevel, Mellott, Flippen, Traverse, Lepanto, FlyingH, Power ) {
   bit_and( Coolin.Covina, Atlas.Covina, LaMarque );
   bit_and( Coolin.Dubbs, Atlas.Dubbs, Groesbeck );
   bit_and( Coolin.Cornell, Atlas.Cornell, RedLevel );
   bit_and( Coolin.Sitka, Atlas.Sitka, Mellott );
   bit_and( Coolin.Havana, Atlas.Havana, Flippen );
   bit_and( Coolin.ElkRidge, Atlas.ElkRidge, Traverse );
   bit_and( Coolin.Quamba, Atlas.Quamba, Lepanto );
   bit_and( Coolin.Hiwassee, Atlas.Hiwassee, FlyingH );
   bit_and( Coolin.Greenlawn, Atlas.Greenlawn, Power );
}
table Deport {
   reads {
      Atlas.Dunmore : exact;
   }
   actions {
      Newtonia;
   }
   default_action : Newtonia(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Millhaven {
   apply( Deport );
}
control Paulette {
   apply( Raeford );
}
table Montalba {
   reads {
      Atlas.Dunmore : exact;
      Atlas.Covina : ternary;
      Atlas.Dubbs : ternary;
      Atlas.Cornell : ternary;
      Atlas.Sitka : ternary;
      Atlas.Havana : ternary;
      Atlas.ElkRidge : ternary;
      Atlas.Quamba : ternary;
      Atlas.Hiwassee : ternary;
      Atlas.Greenlawn : ternary;
   }
   actions {
      WindLake;
   }
   size : 512;
}
control Corder {
   apply( Montalba );
}
@pragma ways 1
table Jones {
   reads {
      Atlas.Dunmore : exact;
      Coolin.Covina : exact;
      Coolin.Dubbs : exact;
      Coolin.Cornell : exact;
      Coolin.Sitka : exact;
      Coolin.Havana : exact;
      Coolin.ElkRidge : exact;
      Coolin.Quamba : exact;
      Coolin.Hiwassee : exact;
      Coolin.Greenlawn : exact;
   }
   actions {
      WindLake;
   }
   size : 4096;
}
action Bernice( Lenoir, Odebolt, Mattoon, Lutts, Bodcaw, Ardara, Langtry, Ballville, Barnsdall ) {
   bit_and( Coolin.Covina, Atlas.Covina, Lenoir );
   bit_and( Coolin.Dubbs, Atlas.Dubbs, Odebolt );
   bit_and( Coolin.Cornell, Atlas.Cornell, Mattoon );
   bit_and( Coolin.Sitka, Atlas.Sitka, Lutts );
   bit_and( Coolin.Havana, Atlas.Havana, Bodcaw );
   bit_and( Coolin.ElkRidge, Atlas.ElkRidge, Ardara );
   bit_and( Coolin.Quamba, Atlas.Quamba, Langtry );
   bit_and( Coolin.Hiwassee, Atlas.Hiwassee, Ballville );
   bit_and( Coolin.Greenlawn, Atlas.Greenlawn, Barnsdall );
}
table Ardsley {
   reads {
      Atlas.Dunmore : exact;
   }
   actions {
      Bernice;
   }
   default_action : Bernice(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Dixmont {
   apply( Ardsley );
}
control Caplis {
   apply( Jones );
}
table RiceLake {
   reads {
      Atlas.Dunmore : exact;
      Atlas.Covina : ternary;
      Atlas.Dubbs : ternary;
      Atlas.Cornell : ternary;
      Atlas.Sitka : ternary;
      Atlas.Havana : ternary;
      Atlas.ElkRidge : ternary;
      Atlas.Quamba : ternary;
      Atlas.Hiwassee : ternary;
      Atlas.Greenlawn : ternary;
   }
   actions {
      WindLake;
   }
   size : 512;
}
control Equality {
   apply( RiceLake );
}
@pragma ways 1
table Joyce {
   reads {
      Atlas.Dunmore : exact;
      Coolin.Covina : exact;
      Coolin.Dubbs : exact;
      Coolin.Cornell : exact;
      Coolin.Sitka : exact;
      Coolin.Havana : exact;
      Coolin.ElkRidge : exact;
      Coolin.Quamba : exact;
      Coolin.Hiwassee : exact;
      Coolin.Greenlawn : exact;
   }
   actions {
      WindLake;
   }
   size : 4096;
}
action Yerington( Francisco, Cadott, Onycha, Desdemona, LaUnion, DoeRun, Spivey, Penitas, PineHill ) {
   bit_and( Coolin.Covina, Atlas.Covina, Francisco );
   bit_and( Coolin.Dubbs, Atlas.Dubbs, Cadott );
   bit_and( Coolin.Cornell, Atlas.Cornell, Onycha );
   bit_and( Coolin.Sitka, Atlas.Sitka, Desdemona );
   bit_and( Coolin.Havana, Atlas.Havana, LaUnion );
   bit_and( Coolin.ElkRidge, Atlas.ElkRidge, DoeRun );
   bit_and( Coolin.Quamba, Atlas.Quamba, Spivey );
   bit_and( Coolin.Hiwassee, Atlas.Hiwassee, Penitas );
   bit_and( Coolin.Greenlawn, Atlas.Greenlawn, PineHill );
}
table Knierim {
   reads {
      Atlas.Dunmore : exact;
   }
   actions {
      Yerington;
   }
   default_action : Yerington(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Claiborne {
   apply( Knierim );
}
control Redmon {
   apply( Joyce );
}
table Hotevilla {
   reads {
      Atlas.Dunmore : exact;
      Atlas.Covina : ternary;
      Atlas.Dubbs : ternary;
      Atlas.Cornell : ternary;
      Atlas.Sitka : ternary;
      Atlas.Havana : ternary;
      Atlas.ElkRidge : ternary;
      Atlas.Quamba : ternary;
      Atlas.Hiwassee : ternary;
      Atlas.Greenlawn : ternary;
   }
   actions {
      WindLake;
   }
   size : 512;
}
control Macedonia {
   apply( Hotevilla );
}
@pragma ways 1
table Rhodell {
   reads {
      Atlas.Dunmore : exact;
      Coolin.Covina : exact;
      Coolin.Dubbs : exact;
      Coolin.Cornell : exact;
      Coolin.Sitka : exact;
      Coolin.Havana : exact;
      Coolin.ElkRidge : exact;
      Coolin.Quamba : exact;
      Coolin.Hiwassee : exact;
      Coolin.Greenlawn : exact;
   }
   actions {
      WindLake;
   }
   size : 4096;
}
action Malaga( Hewitt, Emlenton, Ranburne, Petrey, Cogar, Browndell, Yemassee, Natalbany, Gasport ) {
   bit_and( Coolin.Covina, Atlas.Covina, Hewitt );
   bit_and( Coolin.Dubbs, Atlas.Dubbs, Emlenton );
   bit_and( Coolin.Cornell, Atlas.Cornell, Ranburne );
   bit_and( Coolin.Sitka, Atlas.Sitka, Petrey );
   bit_and( Coolin.Havana, Atlas.Havana, Cogar );
   bit_and( Coolin.ElkRidge, Atlas.ElkRidge, Browndell );
   bit_and( Coolin.Quamba, Atlas.Quamba, Yemassee );
   bit_and( Coolin.Hiwassee, Atlas.Hiwassee, Natalbany );
   bit_and( Coolin.Greenlawn, Atlas.Greenlawn, Gasport );
}
table Melmore {
   reads {
      Atlas.Dunmore : exact;
   }
   actions {
      Malaga;
   }
   default_action : Malaga(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Haven {
   apply( Melmore );
}
control Ridgetop {
   apply( Rhodell );
}
table DelRosa {
   reads {
      Atlas.Dunmore : exact;
      Atlas.Covina : ternary;
      Atlas.Dubbs : ternary;
      Atlas.Cornell : ternary;
      Atlas.Sitka : ternary;
      Atlas.Havana : ternary;
      Atlas.ElkRidge : ternary;
      Atlas.Quamba : ternary;
      Atlas.Hiwassee : ternary;
      Atlas.Greenlawn : ternary;
   }
   actions {
      WindLake;
   }
   size : 512;
}
control LeaHill {
   apply( DelRosa );
}
@pragma ways 1
table Edroy {
   reads {
      Atlas.Dunmore : exact;
      Coolin.Covina : exact;
      Coolin.Dubbs : exact;
      Coolin.Cornell : exact;
      Coolin.Sitka : exact;
      Coolin.Havana : exact;
      Coolin.ElkRidge : exact;
      Coolin.Quamba : exact;
      Coolin.Hiwassee : exact;
      Coolin.Greenlawn : exact;
   }
   actions {
      WindLake;
   }
   size : 4096;
}
action Navarro( August, Watters, Gerster, Suttle, Klukwan, Compton, Leoma, Tchula, Antoine ) {
   bit_and( Coolin.Covina, Atlas.Covina, August );
   bit_and( Coolin.Dubbs, Atlas.Dubbs, Watters );
   bit_and( Coolin.Cornell, Atlas.Cornell, Gerster );
   bit_and( Coolin.Sitka, Atlas.Sitka, Suttle );
   bit_and( Coolin.Havana, Atlas.Havana, Klukwan );
   bit_and( Coolin.ElkRidge, Atlas.ElkRidge, Compton );
   bit_and( Coolin.Quamba, Atlas.Quamba, Leoma );
   bit_and( Coolin.Hiwassee, Atlas.Hiwassee, Tchula );
   bit_and( Coolin.Greenlawn, Atlas.Greenlawn, Antoine );
}
table Hagewood {
   reads {
      Atlas.Dunmore : exact;
   }
   actions {
      Navarro;
   }
   default_action : Navarro(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Wheeler {
   apply( Hagewood );
}
control Wisdom {
   apply( Edroy );
}
table Ashtola {
   reads {
      Atlas.Dunmore : exact;
      Atlas.Covina : ternary;
      Atlas.Dubbs : ternary;
      Atlas.Cornell : ternary;
      Atlas.Sitka : ternary;
      Atlas.Havana : ternary;
      Atlas.ElkRidge : ternary;
      Atlas.Quamba : ternary;
      Atlas.Hiwassee : ternary;
      Atlas.Greenlawn : ternary;
   }
   actions {
      WindLake;
   }
   size : 512;
}
control Whigham {
   apply( Ashtola );
}
control ingress {
   Diana();
   if( CedarKey.Southam != 0 ) {
      Dolliver();
   }
   Sudden();
   if( CedarKey.Southam != 0 ) {
      Lacona();
      Wauregan();
   }
   Glassboro();
   Crary();
   Macksburg();
   Belwood();
   Fishers();
   if( CedarKey.Southam != 0 ) {
      Radom();
   }
   Freeville();
   Litroe();
   Wyncote();
   Cowen();
   if( CedarKey.Southam != 0 ) {
      Elvaston();
   }
   Haverford();
   Ranchito();
   Campo();
   Parksley();
   if( CedarKey.Southam != 0 ) {
      Bagwell();
   }
   Peosta();
   Dutton();
   Hargis();
   Burden();
   if( CedarKey.Southam != 0 ) {
      Denning();
   }
   Pickering();
   Persia();
   Pelican();
   Quitman();
   if( Homeacre.Aspetuck == 0 ) {
      if( valid( Neosho ) ) {
         Homeland();
      } else {
         Veteran();
         Inverness();
      }
   }
   if( not valid( Neosho ) ) {
      Fireco();
   }
   if( Homeacre.Aspetuck == 0 ) {
      Gratiot();
   }
   Bemis();
   if( Homeacre.Aspetuck == 0 ) {
      Heavener();
   }
   if( CedarKey.Southam != 0 ) {
      SourLake();
   }
   Angus();
   if( valid( Carnero[0] ) ) {
      Gambrills();
   }
   if( Homeacre.Aspetuck == 0 ) {
      Wataga();
   }
   Silica();
}
control egress {
   Millhaven();
   Paulette();
   Borth();
   Hayfield();
   Newland();
   Goodwater();
   if( ( Homeacre.SanRemo == 0 ) and ( Homeacre.Alvordton != 2 ) ) {
      Perrin();
   }
   Zarah();
}
