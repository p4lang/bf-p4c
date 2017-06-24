// BUILD: p4c-tofino --verbose 0 --placement tp4 --no-dead-code-elimination --o bf_obfuscate_arista_switch --p4-name=obfuscate_arista_switch --pipe-mgr-path=pipe_mgr/ --mc-mgr-path=mc_mgr/ --gen-exm-test-pd -S --p4-prefix=p4_obfuscate_arista_switch -DPROFILE_DEFAULT --no-phv-swap  Switch.OBFUSCATED.p4


// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 152645







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>



#ifndef Sasakwa
#define Sasakwa

header_type Madawaska {
	fields {
		Atoka : 16;
		Marlton : 16;
		Norcatur : 8;
		Haines : 8;
		Bellville : 8;
		Laclede : 8;
		Harts : 1;
		Freeville : 1;
		Bemis : 1;
		Zeeland : 1;
	}
}

header_type Ellinger {
	fields {
		Palatine : 24;
		Clearco : 24;
		Plateau : 24;
		McGovern : 24;
		Brackett : 16;
		Bramwell : 12;
		Ireton : 16;
		Mulliken : 16;
		Sammamish : 16;
		Clover : 8;
		Belgrade : 8;
		Rhine : 1;
		Huntoon : 1;
		Williams : 12;
		Pearce : 2;
		Lauada : 1;
		Devore : 1;
		Seabrook : 1;
		Blossburg : 1;
		Penrose : 1;
		Isabela : 1;
		Tillson : 1;
		Lenapah : 1;
		NewSite : 1;
		Virgilina : 1;
		Loyalton : 1;
		Fleetwood : 1;
		Bayville : 16;
	}
}

header_type Valders {
	fields {
		Cowpens : 24;
		Ignacio : 24;
		Gregory : 24;
		Snohomish : 24;
		Raeford : 24;
		Parmele : 24;
		Angle : 12;
		Yreka : 16;
		Joiner : 16;
		Longdale : 12;
		Ambrose : 3;
		Camanche : 3;
		NewRome : 1;
		Lucile : 1;
		Davant : 1;
		Ancho : 1;
		Rehoboth : 1;
		Paragould : 1;
		Rhodell : 1;
		Borup : 1;
		Choudrant : 8;
		Dellslow : 1;
		Timken : 1;
		Bulverde : 12;
		Mondovi : 16;
		Cassadaga : 16;
	}
}


header_type Dockton {
	fields {
		Boyce : 8;
		Kneeland : 1;
		Headland : 1;
		Kalvesta : 1;
		Maury : 1;
		CityView : 1;
		Belfair : 1;
	}
}

header_type Chambers {
	fields {
		Wanatah : 32;
		Randle : 32;
		Decorah : 6;
		Holliday : 16;
	}
}

header_type Triplett {
	fields {
		Eunice : 128;
		Kelvin : 128;
		Lutts : 20;
		OreCity : 8;
		Shingler : 11;
		Bettles : 8;
	}
}

header_type Betterton {
	fields {
		Kenton : 14;
		Carbonado : 1;
		Telocaset : 1;
		Pelland : 12;
		CassCity : 1;
		Hobucken : 6;
	}
}

header_type Mackeys {
	fields {
		Alameda : 1;
		Fries : 1;
	}
}

header_type Folkston {
	fields {
		Steele : 8;
	}
}

header_type Leoma {
	fields {
		Farner : 16;
	}
}

header_type Pridgen {
	fields {
		Fairhaven : 32;
		Wibaux : 32;
		McCune : 32;
	}
}

header_type Karlsruhe {
	fields {
		Alakanuk : 32;
		RioHondo : 32;
		Paisano : 16;
	}
}

header_type RedCliff {
	fields {
		Walnut : 16;
	}
}

header_type Bayport {
	fields {
		Knierim : 16;
		BirchBay : 1;
	}
}

#endif



#ifndef Pelican
#define Pelican



header_type Garibaldi {
	fields {
		Catarina : 24;
		Lemhi : 24;
		Brookston : 24;
		Hamden : 24;
		Oreland : 16;
	}
}



header_type Spearman {
	fields {
		Mellott : 3;
		Shawville : 1;
		Montague : 12;
		Jackpot : 16;
	}
}



header_type Rockdale {
	fields {
		Suttle : 4;
		Cropper : 4;
		Weyauwega : 6;
		Highfill : 2;
		Dateland : 16;
		Conda : 16;
		Amanda : 3;
		Longhurst : 13;
		Rains : 8;
		Bedrock : 8;
		Whitlash : 16;
		Peletier : 32;
		Moapa : 32;
	}
}

header_type Ryderwood {
	fields {
		Snook : 4;
		NewTrier : 8;
		Conneaut : 20;
		BullRun : 16;
		Charters : 8;
		Arion : 8;
		Endicott : 128;
		McFaddin : 128;
	}
}




header_type Northway {
	fields {
		Lenox : 8;
		Daysville : 8;
		Moylan : 16;
	}
}

header_type Chatom {
	fields {
		Hueytown : 16;
		Tryon : 16;
		Lucien : 32;
		Lenwood : 32;
		Gannett : 4;
		Sawyer : 4;
		English : 8;
		Bieber : 16;
		Tontogany : 16;
		Greenland : 16;
	}
}

header_type Urbanette {
	fields {
		Tingley : 16;
		Cadwell : 16;
		Villanova : 16;
		Maysfield : 16;
	}
}



header_type SanJon {
	fields {
		Nanson : 16;
		Vidal : 16;
		Dustin : 8;
		Woodcrest : 8;
		BarNunn : 16;
	}
}

header_type Clarendon {
	fields {
		Issaquah : 48;
		Skokomish : 32;
		Craigmont : 48;
		Brinkman : 32;
	}
}



header_type Lushton {
	fields {
		Hisle : 1;
		Levittown : 1;
		Antlers : 1;
		Goodwater : 1;
		Hester : 1;
		Ilwaco : 3;
		Bazine : 5;
		Johnstown : 3;
		Swisshome : 16;
	}
}

header_type Noorvik {
	fields {
		McClusky : 24;
		Pettigrew : 8;
	}
}



header_type Marquette {
	fields {
		Orting : 8;
		Aguada : 24;
		Lanyon : 24;
		Dushore : 8;
	}
}

#endif



#ifndef RoyalOak
#define RoyalOak

parser start {
   return Harlem;
}

#define Vinita        0x8100
#define Holcomb        0x0800
#define Rossburg        0x86dd
#define Anaconda        0x9100
#define WestBay        0x8847
#define Ludden         0x0806
#define Hapeville        0x8035
#define Oakley        0x88cc
#define Chugwater        0x8809

#define Makawao              1
#define Heuvelton              2
#define Cannelton              4
#define Saltair               6
#define Clermont               17
#define Fosters                47

#define Coconut         0x501
#define Falmouth          0x506
#define Santos          0x511
#define Keenes          0x52F


#define Bosler                 4789



#define Kiana               0
#define Luverne              1
#define Maiden                2



#define Cuney          0
#define Fallsburg          4095
#define WestBend  4096
#define ElmGrove  8191



#define Hughson                      0
#define Lodoga                  0
#define Jesup                 1

header Garibaldi Stennett;
header Garibaldi Chualar;
header Spearman Basalt[ 2 ];
header Rockdale Dixfield;
header Rockdale Montross;
header Ryderwood Fiftysix;
header Ryderwood Achille;
header Chatom Lindy;
header Urbanette Vigus;
header Chatom Chewalla;
header Urbanette Bufalo;
header Marquette Piqua;
header SanJon Penalosa;
header Lushton Valier;

parser Harlem {
   extract( Stennett );
   return select( Stennett.Oreland ) {
      Vinita : Bouse;
      Holcomb : Maloy;
      Rossburg : Shabbona;
      Ludden  : Langhorne;
      default        : ingress;
   }
}

parser Bouse {
   extract( Basalt[0] );
   return select( Basalt[0].Jackpot ) {
      Holcomb : Maloy;
      Rossburg : Shabbona;
      Ludden  : Langhorne;
      default : ingress;
   }
}

parser Maloy {
   extract( Dixfield );
   set_metadata(Dozier.Norcatur, Dixfield.Bedrock);
   set_metadata(Dozier.Bellville, Dixfield.Rains);
   set_metadata(Dozier.Atoka, Dixfield.Dateland);
   set_metadata(Dozier.Bemis, 0);
   set_metadata(Dozier.Harts, 1);
   return select(Dixfield.Longhurst, Dixfield.Cropper, Dixfield.Bedrock) {
      Santos : Caputa;
      default : ingress;
   }
}

parser Shabbona {
   extract( Achille );
   set_metadata(Dozier.Norcatur, Achille.Charters);
   set_metadata(Dozier.Bellville, Achille.Arion);
   set_metadata(Dozier.Atoka, Achille.BullRun);
   set_metadata(Dozier.Bemis, 1);
   set_metadata(Dozier.Harts, 0);
   return ingress;
}

parser Langhorne {
   extract( Penalosa );
   return ingress;
}

parser Caputa {
   extract(Vigus);
   return select(Vigus.Cadwell) {
      Bosler : Newburgh;
      default : ingress;
    }
}

parser Rollins {
   set_metadata(Waialua.Pearce, Maiden);
   return Murphy;
}

parser Odenton {
   set_metadata(Waialua.Pearce, Maiden);
   return Bremond;
}

parser Belle {
   extract(Valier);
   return select(Valier.Hisle, Valier.Levittown, Valier.Antlers, Valier.Goodwater, Valier.Hester,
             Valier.Ilwaco, Valier.Bazine, Valier.Johnstown, Valier.Swisshome) {
      Holcomb : Rollins;
      Rossburg : Odenton;
      default : ingress;
   }
}

parser Newburgh {
   extract(Piqua);
   set_metadata(Waialua.Pearce, Luverne);
   return LaConner;
}

parser Murphy {
   extract( Montross );
   set_metadata(Dozier.Haines, Montross.Bedrock);
   set_metadata(Dozier.Laclede, Montross.Rains);
   set_metadata(Dozier.Marlton, Montross.Dateland);
   set_metadata(Dozier.Zeeland, 0);
   set_metadata(Dozier.Freeville, 1);
   return ingress;
}

parser Bremond {
   extract( Fiftysix );
   set_metadata(Dozier.Haines, Fiftysix.Charters);
   set_metadata(Dozier.Laclede, Fiftysix.Arion);
   set_metadata(Dozier.Marlton, Fiftysix.BullRun);
   set_metadata(Dozier.Zeeland, 1);
   set_metadata(Dozier.Freeville, 0);
   return ingress;
}

parser LaConner {
   extract( Chualar );
   return select( Chualar.Oreland ) {
      Holcomb: Murphy;
      Rossburg: Bremond;
      default: ingress;
   }
}
#endif

metadata Ellinger Waialua;

metadata Valders Higganum;
metadata Betterton Orrum;
metadata Madawaska Dozier;
metadata Chambers Evendale;
metadata Triplett Reager;
metadata Mackeys Mantee;
metadata Dockton UtePark;
metadata Folkston RoseTree;
metadata Leoma Grants;
metadata Karlsruhe Donegal;
metadata Pridgen Cochrane;
metadata RedCliff Lafourche;
metadata Bayport Markville;
metadata Bayport Larchmont;
metadata Bayport Crozet;







@pragma pa_solitary ingress Waialua.Bramwell
@pragma pa_solitary ingress Waialua.Ireton
@pragma pa_solitary ingress Waialua.Mulliken
@pragma pa_solitary ig_intr_md_for_tm.ucast_egress_port
@pragma pa_atomic ingress Donegal.Paisano
@pragma pa_solitary ingress Donegal.Paisano

@pragma pa_atomic ingress Donegal.Alakanuk
@pragma pa_solitary ingress Donegal.Alakanuk
@pragma pa_atomic ingress Donegal.RioHondo
@pragma pa_solitary ingress Donegal.RioHondo













#undef Ugashik

#undef Baranof
#undef Wamego
#undef Traverse
#undef Trion
#undef Eclectic

#undef Bowdon
#undef Crystola
#undef Devola

#undef Trilby
#undef Green
#undef Eudora
#undef Norco
#undef Paxtonia
#undef Boonsboro
#undef Fowler
#undef Calvary
#undef Bushland

#undef Bairoil
#undef Mogote
#undef Gerster
#undef Olmitz
#undef Elvaston
#undef Geneva
#undef Naches
#undef Essington
#undef Coachella
#undef Wolsey
#undef Silco
#undef Gibbstown

#undef Brockton

#undef Skiatook

#undef Lakin
#undef Waucousta
#undef Tusayan
#undef Victoria







#define Ugashik 288

#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Baranof      65536
#define Wamego      65536
#define Traverse 512
#define Trion 512
#define Eclectic      512


#define Bowdon     1024
#define Crystola    1024
#define Devola     256


#define Trilby 512
#define Green 65536
#define Eudora 65536
#define Norco   16384
#define Paxtonia         131072
#define Boonsboro 65536
#define Fowler 1024
#define Calvary 2048
#define Bushland 16384


#define Bairoil 1024
#define Mogote 4096
#define Gerster 4096
#define Olmitz 4096
#define Elvaston 4096
#define Geneva 1024
#define Naches 4096
#define Coachella 64
#define Wolsey 1
#define Silco  8
#define Gibbstown 512


#define Brockton 0


#define Skiatook    4096


#define Lakin    16384
#define Waucousta   16384
#define Tusayan            16384

#define Victoria                    57344

#endif



#ifndef Karluk
#define Karluk

action Yemassee() {
   no_op();
}

#endif

















action IttaBena(Coyote, Elloree, Roodhouse, Asharoken, Ozona, Henrietta) {
    modify_field(Orrum.Kenton, Coyote);
    modify_field(Orrum.Carbonado, Elloree);
    modify_field(Orrum.Pelland, Roodhouse);
    modify_field(Orrum.Telocaset, Asharoken);
    modify_field(Orrum.CassCity, Ozona);
    modify_field(Orrum.Hobucken, Henrietta);
}

@pragma command_line --no-dead-code-elimination
table Stovall {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        IttaBena;
    }
    size : Ugashik;
}

control Cacao {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Stovall);
    }
}





action Larose(Bouton) {
   modify_field( Higganum.NewRome, 1 );
   modify_field( Higganum.Choudrant, Bouton);
   modify_field( Waialua.NewSite, 1 );
}

action Colver() {
   modify_field( Waialua.Tillson, 1 );
   modify_field( Waialua.Loyalton, 1 );
}

action Suntrana() {
   modify_field( Waialua.NewSite, 1 );
}

action Cloverly() {
   modify_field( Waialua.Fleetwood, 1 );
}

action Caguas() {
   modify_field( Waialua.Virgilina, 1 );
}

action Biggers() {
   modify_field( Waialua.Loyalton, 1 );
}


table Edgemont {
   reads {
      Stennett.Catarina : ternary;
      Stennett.Lemhi : ternary;
   }

   actions {
      Larose;
      Colver;
      Suntrana;
      Caguas;
      Biggers;
      Cloverly;
   }
   default_action : Biggers;
   size : Traverse;
}

action Lakota() {
   modify_field( Waialua.Lenapah, 1 );
}


table Monkstown {
   reads {
      Stennett.Brookston : ternary;
      Stennett.Hamden : ternary;
   }

   actions {
      Lakota;
   }
   size : Trion;
}


control Forbes {
   apply( Edgemont );
   apply( Monkstown );
}




action Lydia() {
   modify_field( Evendale.Wanatah, Montross.Peletier );
   modify_field( Evendale.Randle, Montross.Moapa );
   modify_field( Evendale.Decorah, Montross.Weyauwega );
   modify_field( Reager.Eunice, Fiftysix.Endicott );
   modify_field( Reager.Kelvin, Fiftysix.McFaddin );
   modify_field( Reager.Lutts, Fiftysix.Conneaut );


   modify_field( Waialua.Palatine, Chualar.Catarina );
   modify_field( Waialua.Clearco, Chualar.Lemhi );
   modify_field( Waialua.Plateau, Chualar.Brookston );
   modify_field( Waialua.McGovern, Chualar.Hamden );
   modify_field( Waialua.Brackett, Chualar.Oreland );
   modify_field( Waialua.Sammamish, Dozier.Marlton );
   modify_field( Waialua.Clover, Dozier.Haines );
   modify_field( Waialua.Belgrade, Dozier.Laclede );
   modify_field( Waialua.Huntoon, Dozier.Freeville );
   modify_field( Waialua.Rhine, Dozier.Zeeland );
}

action Skyway() {
   modify_field( Waialua.Pearce, Kiana );
   modify_field( Evendale.Wanatah, Dixfield.Peletier );
   modify_field( Evendale.Randle, Dixfield.Moapa );
   modify_field( Evendale.Decorah, Dixfield.Weyauwega );
   modify_field( Reager.Eunice, Achille.Endicott );
   modify_field( Reager.Kelvin, Achille.McFaddin );
   modify_field( Reager.Lutts, Achille.Conneaut );


   modify_field( Waialua.Palatine, Stennett.Catarina );
   modify_field( Waialua.Clearco, Stennett.Lemhi );
   modify_field( Waialua.Plateau, Stennett.Brookston );
   modify_field( Waialua.McGovern, Stennett.Hamden );
   modify_field( Waialua.Brackett, Stennett.Oreland );
   modify_field( Waialua.Sammamish, Dozier.Atoka );
   modify_field( Waialua.Clover, Dozier.Norcatur );
   modify_field( Waialua.Belgrade, Dozier.Bellville );
   modify_field( Waialua.Huntoon, Dozier.Harts );
   modify_field( Waialua.Rhine, Dozier.Bemis );
}

table Broussard {
   reads {
      Stennett.Catarina : exact;
      Stennett.Lemhi : exact;
      Dixfield.Moapa : exact;
      Waialua.Pearce : exact;
   }

   actions {
      Lydia;
      Skyway;
   }

   default_action : Skyway();
   size : Bairoil;
}


action Rockdell() {
   modify_field( Waialua.Bramwell, Orrum.Pelland );
   modify_field( Waialua.Ireton, Orrum.Kenton);
}

action Cutler( Ardsley ) {
   modify_field( Waialua.Bramwell, Ardsley );
   modify_field( Waialua.Ireton, Orrum.Kenton);
}

action Piketon() {
   modify_field( Waialua.Bramwell, Basalt[0].Montague );
   modify_field( Waialua.Ireton, Orrum.Kenton);
}

table Sudden {
   reads {
      Orrum.Kenton : ternary;
      Basalt[0] : valid;
      Basalt[0].Montague : ternary;
   }

   actions {
      Rockdell;
      Cutler;
      Piketon;
   }
   size : Olmitz;
}

action Quarry( Cavalier ) {
   modify_field( Waialua.Ireton, Cavalier );
}

action Othello() {

   modify_field( Waialua.Seabrook, 1 );
   modify_field( RoseTree.Steele,
                 Jesup );
}

table Tenino {
   reads {
      Dixfield.Peletier : exact;
   }

   actions {
      Quarry;
      Othello;
   }
   default_action : Othello;
   size : Gerster;
}

action BigWater( Friend, Nathalie, Knollwood, Donald, Monteview,
                        Philip, Almeria ) {
   modify_field( Waialua.Bramwell, Friend );
   modify_field( Waialua.Isabela, Almeria );
   UnionGap(Nathalie, Knollwood, Donald, Monteview,
                        Philip );
}

action Milbank() {
   modify_field( Waialua.Penrose, 1 );
}

table Mekoryuk {
   reads {
      Piqua.Lanyon : exact;
   }

   actions {
      BigWater;
      Milbank;
   }
   size : Mogote;
}

action UnionGap(Nathalie, Knollwood, Donald, Monteview,
                        Philip ) {
   modify_field( UtePark.Boyce, Nathalie );
   modify_field( UtePark.Kneeland, Knollwood );
   modify_field( UtePark.Kalvesta, Donald );
   modify_field( UtePark.Headland, Monteview );
   modify_field( UtePark.Maury, Philip );
}

action Freeburg(Nathalie, Knollwood, Donald, Monteview,
                        Philip ) {
   modify_field( Waialua.Mulliken, Orrum.Pelland );
   modify_field( Waialua.Isabela, 1 );
   UnionGap(Nathalie, Knollwood, Donald, Monteview,
                        Philip );
}

action Bootjack(Ketchum, Nathalie, Knollwood, Donald,
                        Monteview, Philip ) {
   modify_field( Waialua.Mulliken, Ketchum );
   modify_field( Waialua.Isabela, 1 );
   UnionGap(Nathalie, Knollwood, Donald, Monteview,
                        Philip );
}

action Merino(Nathalie, Knollwood, Donald, Monteview,
                        Philip ) {
   modify_field( Waialua.Mulliken, Basalt[0].Montague );
   modify_field( Waialua.Isabela, 1 );
   UnionGap(Nathalie, Knollwood, Donald, Monteview,
                        Philip );
}

table Ballinger {
   reads {
      Orrum.Pelland : exact;
   }

   actions {
      Freeburg;
   }

   size : Elvaston;
}

table Edler {
   reads {
      Orrum.Kenton : exact;
      Basalt[0].Montague : exact;
   }

   actions {
      Bootjack;
      Yemassee;
   }
   default_action : Yemassee;

   size : Geneva;
}

table Thach {
   reads {
      Basalt[0].Montague : exact;
   }

   actions {
      Merino;
   }

   size : Naches;
}

control Greer {
   apply( Broussard ) {
         Lydia {
            apply( Tenino );
            apply( Mekoryuk );
         }
         Skyway {
            if ( Orrum.Telocaset == 1 ) {
               apply( Sudden );
            }
            if ( valid( Basalt[ 0 ] ) ) {

               apply( Edler ) {
                  Yemassee {

                     apply( Thach );
                  }
               }
            } else {

               apply( Ballinger );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Venice {
    width  : 1;
    static : Belen;
    instance_count : 262144;
}

register Goessel {
    width  : 1;
    static : Longport;
    instance_count : 262144;
}

blackbox stateful_alu Westboro {
    reg : Venice;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Mantee.Alameda;
}

blackbox stateful_alu Tavistock {
    reg : Goessel;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Mantee.Fries;
}

field_list Barnsboro {
    Orrum.Hobucken;
    Basalt[0].Montague;
}

field_list_calculation Iredell {
    input { Barnsboro; }
    algorithm: identity;
    output_width: 18;
}

action Lansing() {
    Westboro.execute_stateful_alu_from_hash(Iredell);
}

action Brainard() {
    Tavistock.execute_stateful_alu_from_hash(Iredell);
}

table Belen {
    actions {
      Lansing;
    }
    default_action : Lansing;
    size : 1;
}

table Longport {
    actions {
      Brainard;
    }
    default_action : Brainard;
    size : 1;
}
#endif

action Altus(Rotterdam) {
    modify_field(Mantee.Fries, Rotterdam);
}

@pragma  use_hash_action 0
table Barnard {
    reads {
       Orrum.Hobucken : exact;
    }
    actions {
      Altus;
    }
    size : 64;
}

action Lasara() {
   modify_field( Waialua.Williams, Orrum.Pelland );
   modify_field( Waialua.Lauada, 0 );
}

table Wakeman {
   actions {
      Lasara;
   }
   size : 1;
}

action Chantilly() {
   modify_field( Waialua.Williams, Basalt[0].Montague );
   modify_field( Waialua.Lauada, 1 );
}

table Advance {
   actions {
      Chantilly;
   }
   size : 1;
}

control Rockville {
   if ( valid( Basalt[ 0 ] ) ) {
      apply( Advance );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Orrum.CassCity == 1 ) {
         apply( Belen );
         apply( Longport );
      }
#endif
   } else {
      apply( Wakeman );
      if( Orrum.CassCity == 1 ) {
         apply( Barnard );
      }
   }
}




field_list Berkey {
   Stennett.Catarina;
   Stennett.Lemhi;
   Stennett.Brookston;
   Stennett.Hamden;
   Stennett.Oreland;
}

field_list Laplace {

   Dixfield.Bedrock;
   Dixfield.Peletier;
   Dixfield.Moapa;
}

field_list Fernway {
   Achille.Endicott;
   Achille.McFaddin;
   Achille.Conneaut;
   Achille.Charters;
}

field_list Lefors {
   Dixfield.Bedrock;
   Dixfield.Peletier;
   Dixfield.Moapa;
   Vigus.Tingley;
   Vigus.Cadwell;
}





field_list_calculation Tenstrike {
    input {
        Berkey;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Kettering {
    input {
        Laplace;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Craigtown {
    input {
        Fernway;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Quinnesec {
    input {
        Lefors;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Corder() {
    modify_field_with_hash_based_offset(Cochrane.Fairhaven, 0,
                                        Tenstrike, 4294967296);
}

action Hartford() {
    modify_field_with_hash_based_offset(Cochrane.Wibaux, 0,
                                        Kettering, 4294967296);
}

action Wyman() {
    modify_field_with_hash_based_offset(Cochrane.Wibaux, 0,
                                        Craigtown, 4294967296);
}

action Aguilita() {
    modify_field_with_hash_based_offset(Cochrane.McCune, 0,
                                        Quinnesec, 4294967296);
}

table Stamford {
   actions {
      Corder;
   }
   size: 1;
}

control Wapella {
   apply(Stamford);
}

table Kentwood {
   actions {
      Hartford;
   }
   size: 1;
}

table Bellport {
   actions {
      Wyman;
   }
   size: 1;
}

control Azusa {
   if ( valid( Dixfield ) ) {
      apply(Kentwood);
   } else {
      if ( valid( Achille ) ) {
         apply(Bellport);
      }
   }
}

table Talbotton {
   actions {
      Aguilita;
   }
   size: 1;
}

control Creekside {
   if ( valid( Vigus ) ) {
      apply(Talbotton);
   }
}



action Fireco() {
    modify_field(Donegal.Alakanuk, Cochrane.Fairhaven);
}

action Powers() {
    modify_field(Donegal.Alakanuk, Cochrane.Wibaux);
}

action GilaBend() {
    modify_field(Donegal.Alakanuk, Cochrane.McCune);
}

@pragma immediate 0
table MontIda {
   reads {
      Chewalla.valid : ternary;
      Bufalo.valid : ternary;
      Montross.valid : ternary;
      Fiftysix.valid : ternary;
      Chualar.valid : ternary;
      Lindy.valid : ternary;
      Vigus.valid : ternary;
      Dixfield.valid : ternary;
      Achille.valid : ternary;
      Stennett.valid : ternary;
   }
   actions {
      Fireco;
      Powers;
      GilaBend;
      Yemassee;
   }
   default_action : Yemassee();
   size: Devola;
}

field_list WestPike {
   Donegal.Alakanuk;
}

field_list_calculation Wakeman {
   input {
       WestPike;
   }
   algorithm : Paulette;
   output_width : 16;
}

action Kinsley() {


}

table Valier {
   actions {
      Kinsley;
   }
   default_action : Kinsley;
   size : 1;
}

control Grygla {
   apply(MontIda);
   apply(Valier);
}





counter LaHoma {
   type : packets_and_bytes;
   direct : Kremlin;
   min_width: 16;
}

action Tununak() {
   modify_field(Waialua.Blossburg, 1 );
}

table Kremlin {
   reads {
      Orrum.Hobucken : exact;
      Mantee.Fries : ternary;
      Mantee.Alameda : ternary;
      Waialua.Penrose : ternary;
      Waialua.Lenapah : ternary;
      Waialua.Tillson : ternary;
   }

   actions {
      Tununak;
      Yemassee;
   }
   default_action : Yemassee;
   size : Eclectic;
}

register Linville {
   width: 1;
   static: Hallville;
   instance_count: Wamego;
}

#ifdef __TARGET_TOFINO__
blackbox stateful_alu Veteran{
    reg: Linville;
    update_lo_1_value: set_bit;
}
#endif

action Callao(Cecilton) {
#if defined(BMV2) || defined(BMV2TOFINO)
   register_write(Linville, Cecilton, 1);
#else
   Veteran.execute_stateful_alu();
#endif

}

action Newellton() {

   modify_field(Waialua.Devore, 1 );
   modify_field(RoseTree.Steele,
                Lodoga);
}

table Hallville {
   reads {
      Waialua.Plateau : exact;
      Waialua.McGovern : exact;
      Waialua.Bramwell : exact;
      Waialua.Ireton : exact;
   }

   actions {
      Callao;
      Newellton;
   }
   size : Wamego;
}

action Saxis() {
   modify_field( UtePark.CityView, 1 );
}

table Grays {
   reads {
      Waialua.Mulliken : ternary;
      Waialua.Palatine : exact;
      Waialua.Clearco : exact;
   }
   actions {
      Saxis;
   }
   size: Trilby;
}

control Stewart {
   if( Waialua.Blossburg == 0 ) {
      apply( Grays );
   }
}

control Hebbville {
   apply( Kremlin ) {
      Yemassee {



         if (Orrum.Carbonado == 0 and Waialua.Seabrook == 0) {
            apply( Hallville );
         }
         apply(Grays);
      }
   }
}

field_list Sherwin {
    RoseTree.Steele;
    Waialua.Plateau;
    Waialua.McGovern;
    Waialua.Bramwell;
    Waialua.Ireton;
}

action Orrville() {
   generate_digest(Hughson, Sherwin);
}

table Calcasieu {
   actions {
      Orrville;
   }
   size : 1;
}

control Bayshore {
   if (Waialua.Devore == 1) {
      apply( Calcasieu );
   }
}



action Comunas( Norbeck ) {
   modify_field( Reager.Shingler, Norbeck );
}

table Thurmond {

   reads {
      UtePark.Boyce : exact;
      Reager.Kelvin : lpm;
   }

   actions {
      Comunas;
      Yemassee;
   }

   default_action : Yemassee();
   size : Calvary;
}

@pragma atcam_partition_index Reager.Shingler
@pragma atcam_number_partitions Calvary
table Hatfield {
   reads {
      Reager.Shingler : exact;


      Reager.Kelvin mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Lookeba;
      Yemassee;
   }

   default_action : Yemassee();
   size : Bushland;
}

@pragma idletime_precision 1
table Lucerne {

   reads {
      UtePark.Boyce : exact;
      Evendale.Randle : lpm;
   }

   actions {
      Lookeba;
      Yemassee;
   }

   default_action : Yemassee();
   size : Fowler;
   support_timeout : true;
}

action Fletcher(Anita) {
   modify_field(Evendale.Holliday, Anita);
}

table Segundo {
   reads {
      UtePark.Boyce : exact;
      Evendale.Randle : lpm;
   }

   actions {
      Fletcher;
   }

   size : Norco;
}

@pragma command_line --metadata-overlay False
@pragma ways 4  // FIXME: Adding this pragma allows the program to fit in 12 stages
@pragma atcam_partition_index Evendale.Holliday
@pragma atcam_number_partitions Norco
table Cross {
   reads {
      Evendale.Holliday : exact;



      Evendale.Randle mask 0x000fffff : lpm;
   }
   actions {
      Lookeba;
      Yemassee;
   }

   size : Paxtonia;
}

action Lookeba( Maltby ) {
   modify_field( Higganum.Borup, 1 );
   modify_field( Grants.Farner, Maltby );
}

@pragma idletime_precision 1
table Hannibal {
   reads {
      UtePark.Boyce : exact;
      Evendale.Randle : exact;
   }

   actions {
      Lookeba;
      Yemassee;
   }
   default_action : Yemassee();
   size : Green;
   support_timeout : true;
}

@pragma idletime_precision 1
table Taneytown {
   reads {
      UtePark.Boyce : exact;
      Reager.Kelvin : exact;
   }

   actions {
      Lookeba;
      Yemassee;
   }
   default_action : Yemassee();
   size : Eudora;
   support_timeout : true;
}

action Dilia(WebbCity, Shubert, Riley) {
   modify_field(Higganum.Angle, Riley);
   modify_field(Higganum.Cowpens, WebbCity);
   modify_field(Higganum.Ignacio, Shubert);
   modify_field(Higganum.Borup, 1);
}

table Haslet {
   reads {
      Grants.Farner : exact;
   }

   actions {
      Dilia;
   }
   size : Boonsboro;
}

control Shanghai {
   apply( Segundo );
   if ( Waialua.Blossburg == 0 and UtePark.CityView == 1 ) {
      if ( ( UtePark.Kneeland == 1 ) and ( Waialua.Huntoon == 1 ) ) {
         apply( Hannibal ) {
            Yemassee {
               if( Evendale.Holliday != 0 ) {
                  apply( Cross );
               }
               if (Grants.Farner == 0 ) {
                  apply( Lucerne );
               }
            }
         }
      } else if ( ( UtePark.Kalvesta == 1 ) and ( Waialua.Rhine == 1 ) ) {
         apply( Taneytown ) {
            Yemassee {
               apply( Thurmond ) {
                  Comunas {
                     apply( Hatfield );
                  }
               }
            }
         }
      }
   }
}

control Mattawan {
   if( Grants.Farner != 0 ) {
      apply( Haslet );
   }
}



field_list Daniels {
   Donegal.Alakanuk;
}

field_list_calculation Lennep {
    input {
        Daniels;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Bagdad {
    selection_key : Lennep;
    selection_mode : resilient;
}

action Yorklyn(Dennison) {
   modify_field(Higganum.Yreka, Dennison);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Dennison);
}

action_profile Claiborne {
    actions {
        Yorklyn;
        Yemassee;
    }
    size : Crystola;
    dynamic_action_selection : Bagdad;
}

table Riverland {
   reads {
      Higganum.Yreka : exact;
   }
   action_profile: Claiborne;
   size : Bowdon;
}

control Harvest {
   if ((Waialua.Blossburg == 0) and (Higganum.Yreka & 0x2000) == 0x2000) {
      apply(Riverland);
   }
}



action Halsey() {
   modify_field(Higganum.Cowpens, Waialua.Palatine);
   modify_field(Higganum.Ignacio, Waialua.Clearco);
   modify_field(Higganum.Gregory, Waialua.Plateau);
   modify_field(Higganum.Snohomish, Waialua.McGovern);
   modify_field(Higganum.Angle, Waialua.Bramwell);
}

table Dixon {
   actions {
      Halsey;
   }
   default_action : Halsey();
   size : 1;
}

control Gibbs {
   if (Waialua.Bramwell!=0) {
      apply( Dixon );
   }
}

action Slocum() {
   modify_field(Higganum.Davant, 1);
   modify_field(Higganum.Lucile, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Higganum.Angle);
}

action Keyes() {
}



@pragma ways 1
table Marbury {
   reads {
      Higganum.Cowpens : exact;
      Higganum.Ignacio : exact;
   }
   actions {
      Slocum;
      Keyes;
   }
   default_action : Keyes;
   size : 1;
}

action Bledsoe() {
   modify_field(Higganum.Paragould, 1);
   modify_field(Higganum.Joiner, Higganum.Angle);
}

table Ikatan {
   actions {
      Bledsoe;
   }
   default_action : Bledsoe();
   size : 1;
}

action LaCueva(Edinburg) {
   modify_field(Higganum.Rehoboth, 1);




   modify_field(Higganum.Yreka, Edinburg);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Edinburg);
}

action Elliston(Grassy) {
   modify_field(Higganum.Ancho, 1);
   modify_field(Higganum.Joiner, Grassy);
}

action Papeton() {
}

table Hobson {
   reads {
      Higganum.Cowpens : exact;
      Higganum.Ignacio : exact;
      Higganum.Angle : exact;
   }

   actions {
      LaCueva;
      Elliston;
      Papeton;
   }
   default_action : Papeton();
   size : Baranof;
}

control Granbury {
   if (Waialua.Blossburg == 0) {
      apply(Hobson) {
         Papeton {
            apply(Marbury) {
               Keyes {
                  if ((Higganum.Cowpens & 0x010000) == 0x000000) {
                     apply(Ikatan);
                  }
               }
            }
         }
      }
   }
}


action Groesbeck() {
   modify_field(Waialua.Blossburg, 1);
}

table Panaca {
   actions {
      Groesbeck;
   }
   default_action : Groesbeck;
   size : 1;
}

control Youngtown {
   if ((Higganum.Borup==0) and (Waialua.Ireton==Higganum.Yreka) and
       (Waialua.NewSite == 0 and Waialua.Fleetwood == 0)) {
      apply(Panaca);
   }
}



action Fowlkes( CruzBay ) {
   modify_field( Higganum.Longdale, CruzBay );
}

action Roswell() {
   modify_field( Higganum.Longdale, Higganum.Angle );
}

table Meservey {
   reads {
      eg_intr_md.egress_port : exact;
      Higganum.Angle : exact;
   }

   actions {
      Fowlkes;
      Roswell;
   }
   default_action : Roswell;
   size : Skiatook;
}

control Taconite {
   apply( Meservey );
}



action Yetter( Terral, Coupland ) {
   modify_field( Higganum.Raeford, Terral );
   modify_field( Higganum.Parmele, Coupland );
}


table Whiteclay {
   reads {
      Higganum.Ambrose : exact;
   }

   actions {
      Yetter;
   }
   size : Silco;
}

action Trego() {
   no_op();
}

action Slayden() {
   modify_field( Stennett.Oreland, Basalt[0].Jackpot );
   remove_header( Basalt[0] );
}

table BoxElder {
   actions {
      Slayden;
   }
   default_action : Slayden;
   size : Wolsey;
}

action Florahome() {
   no_op();
}

action Wabuska() {
   add_header( Basalt[ 0 ] );
   modify_field( Basalt[0].Montague, Higganum.Longdale );
   modify_field( Basalt[0].Jackpot, Stennett.Oreland );
   modify_field( Stennett.Oreland, Vinita );
}



table Lansdale {
   reads {
      Higganum.Longdale : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Florahome;
      Wabuska;
   }
   default_action : Wabuska;
   size : Coachella;
}

action Eckman() {
   modify_field(Stennett.Catarina, Higganum.Cowpens);
   modify_field(Stennett.Lemhi, Higganum.Ignacio);
   modify_field(Stennett.Brookston, Higganum.Raeford);
   modify_field(Stennett.Hamden, Higganum.Parmele);
}

action Faith() {
   Eckman();
   add_to_field(Dixfield.Rains, -1);
}

action Sylvan() {
   Eckman();
   add_to_field(Achille.Arion, -1);
}

table Neame {
   reads {
      Higganum.Camanche : exact;
      Higganum.Ambrose : exact;
      Higganum.Borup : exact;
      Dixfield.valid : ternary;
      Achille.valid : ternary;



      Higganum.Raeford mask 0x1 : ternary;
   }

   actions {
      Faith;
      Sylvan;
   }
   size : Gibbstown;
}

control Kelsey {
   apply( BoxElder );
}

control Carrizozo {
   apply( Lansdale );
}

control McKamie {
   apply( Whiteclay );
   apply( Neame );
}



field_list Balfour {
    RoseTree.Steele;
    Waialua.Bramwell;
    Chualar.Brookston;
    Chualar.Hamden;
    Dixfield.Peletier;
}

action Northlake() {
   generate_digest(Hughson, Balfour);
}

table Almond {
   actions {
      Northlake;
   }

   default_action : Northlake;
   size : 1;
}

control Skyline {
   if (Waialua.Seabrook == 1) {
      apply(Almond);
   }
}



#define Blakeley         511

action Sugarloaf( Lakeside, Coverdale ) {
   modify_field( Lafourche.Walnut, Lakeside );
   modify_field( Crozet.Knierim, Coverdale );
   modify_field( Crozet.BirchBay, 1 );
}

table Anguilla {
   reads {
     Evendale.Randle : exact;
     Waialua.Mulliken : exact;
   }

   actions {
      Sugarloaf;
   }
  size : Lakin;
}

action Goudeau(Wenham) {
   modify_field( Larchmont.Knierim, Wenham );
   modify_field( Larchmont.BirchBay, 1 );
}

table Lansdowne {
   reads {
     Evendale.Wanatah : exact;
     Lafourche.Walnut : exact;
   }
   actions {
      Goudeau;
   }
   size : Waucousta;
}

action Armona( Baraboo ) {
   modify_field( Markville.Knierim, Baraboo );
   modify_field( Markville.BirchBay, 1 );
}





action Waupaca() {
   modify_field( Waialua.Bayville, Waialua.Bramwell );
}

table Pinta {
   reads {
     Waialua.Palatine mask 0xfeffff : exact;
     Waialua.Clearco : exact;
     Waialua.Bramwell : exact;
   }
   actions {
      Armona;
   }
   default_action : Waupaca;
   size : Tusayan;
}


action Burden() {


   modify_field(ig_intr_md_for_tm.level2_mcast_hash, Donegal.Alakanuk);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Blakeley);
   modify_field(ig_intr_md_for_tm.level2_exclusion_id, ig_intr_md.ingress_port);

   modify_field(Higganum.Cowpens, Waialua.Palatine);
   modify_field(Higganum.Ignacio, Waialua.Clearco);
   modify_field(Higganum.Gregory, Waialua.Plateau);
   modify_field(Higganum.Snohomish, Waialua.McGovern);
}






action Habersham(Crane, Almyra) {


   Burden();
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Larchmont.Knierim);
   modify_field(Higganum.Angle, 0);
   modify_field(Higganum.Dellslow, Crane);
   modify_field(Higganum.Timken, Almyra);
}
action Finlayson(Cornudas, Nursery) {
   Burden();
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Crozet.Knierim);
   modify_field(Higganum.Angle, 0);
   modify_field(Higganum.Dellslow, Cornudas);
   modify_field(Higganum.Timken, Nursery);
}
action Power(Monetta, Bartolo) {
   Burden();
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Markville.Knierim);
   modify_field(Higganum.Angle, 0);
   modify_field(Higganum.Dellslow, Monetta);
   modify_field(Higganum.Timken, Bartolo);
}
action Blanding() {
   Burden();

   add(ig_intr_md_for_tm.mcast_grp_a, Waialua.Bayville, WestBend);
   modify_field(Higganum.Angle, Waialua.Bramwell);
}

table Gabbs {
   reads {
     Larchmont.Knierim : ternary;
     Larchmont.BirchBay : ternary;
     Crozet.Knierim : ternary;
     Crozet.BirchBay : ternary;
     Markville.Knierim : ternary;
     Markville.BirchBay : ternary;
     Waialua.Clover :ternary;


   }
   actions {
      Finlayson;
      Habersham;
      Power;
      Blanding;
   }
   default_action : Blanding;
   size : 16;
}

control Haley {






   if (Mantee.Alameda == 0 and
       Mantee.Fries == 0 and
       UtePark.Headland == 1 and
       Waialua.Fleetwood == 1) {
       apply(Anguilla) {
          hit {
             apply(Lansdowne);
          }
       }
   }





   if ((Waialua.NewSite == 1 or Waialua.Fleetwood == 1) and
       Mantee.Alameda == 0 and
       Mantee.Fries == 0) {




      apply(Pinta);
   }




   if ((Mantee.Alameda == 0) and
       (Mantee.Fries == 0) and
       (Waialua.NewSite == 1 or Waialua.Fleetwood == 1) and
       (Waialua.Blossburg == 0)) {
      apply(Gabbs);
   }
}





action Forman(Corum, Attalla) {
   modify_field(Higganum.Angle, Corum);


   modify_field(Higganum.Borup, Attalla);
}

action Hearne() {











   drop();
}


table Grainola {
   reads {
     eg_intr_md.egress_rid: exact;
   }

   actions {
      Forman;
   }
   default_action: Hearne;
   size : Victoria;
}


control Dixmont {


   if ((eg_intr_md.egress_rid != 0) and
       (eg_intr_md.egress_rid & 0xE000) != 0xE000) {
      apply(Grainola);
   }
}

control ingress {

   Cacao();
   Forbes();
   Greer();
   Rockville();
   Wapella();


   Hebbville();

   Azusa();
   Creekside();


   Shanghai();

   Gibbs();

   Mattawan();


   Grygla();



   Granbury();
   Haley();


   Youngtown();
   Skyline();
   Bayshore();


   if( valid( Basalt[0] ) ) {
      Kelsey();
   }


   Harvest();
}

control egress {
   Dixmont();
   Taconite();
   McKamie();
   Carrizozo();
}
