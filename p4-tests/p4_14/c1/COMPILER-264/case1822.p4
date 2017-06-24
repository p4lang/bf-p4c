// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 155113







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
#else





header_type Carnegie {
	fields {
		Hubbell : 3;
	}
}
metadata Carnegie Micro;

header_type Chaffee {
	fields {
		Brinkman : 1;
		Tombstone : 9;
		Higbee : 48;
		Westhoff : 32;
	}
}
metadata Chaffee Oklee;

header_type Upland {
	fields {
		Kingsdale : 9;
		Corydon : 3;
		Beaverton : 16;
		NantyGlo : 16;
		Ragley : 13;
		Belcourt : 13;
		Wildorado : 16;
		Lamoni : 9;
		Goodwin : 16;
		Bluewater : 1;
		Seabrook : 3;
		Arbyrd : 5;
		Volens : 2;
	}
}

metadata Upland Berne;

header_type Wondervu {
	fields {
		Ramhurst : 9;
		Dunnellon : 19;
		Bellvue : 2;
		Yantis : 32;
		Loughman : 19;
		Bulverde : 2;
		Keltys : 8;
		Stella : 32;
		Duchesne : 16;
		Novice : 1;
		Noonan : 5;
		Garwood : 3;
		Akhiok : 1;
	}
}

metadata Wondervu Kinde;




action Woodstown(Vandling) {
    modify_field(Toxey, Vandling);
}

#ifdef BMV2
#define Plato     Placid
#else
#define Plato         Anoka
#endif

header_type SandCity {
	fields {
		Haven : 8;
		Plush : 48;
	}
}
metadata SandCity Joice;

#define Lepanto 0
#define Konnarock 1
#define Rowden 2
#define Nuevo 3
#define Mescalero 4
#define WestPike 5
#define Potter 6


#define Benitez \
    ((Roscommon != Lepanto) and \
     (Roscommon != WestPike))
#define Gause \
    ((Roscommon == Lepanto) or \
     (Roscommon == WestPike))
#define Betterton \
    (Roscommon == Konnarock)
#define Hermleigh \
    (Roscommon == Rowden)
#endif



#ifndef Carlson
#define Carlson

header_type Wyanet {
	fields {
		Alvwood : 24;
		Scottdale : 24;
		Cisco : 24;
		Tilghman : 24;
		Tennyson : 16;
		Brunson : 12;
		Sonoita : 16;
		Kingman : 16;
		Petroleum : 12;
		Kountze : 2;
		Berwyn : 1;
		Laney : 1;
		Connell : 1;
		Ringwood : 1;
		Ranchito : 1;
		FlatRock : 1;
		Nambe : 1;
		Skene : 1;
		Blueberry : 1;
		Weatherly : 1;
		Stanwood : 1;
	}
}

header_type Cullen {
	fields {
		Stillmore : 24;
		Mayview : 24;
		Tornillo : 24;
		Advance : 24;
		Coamo : 24;
		Moclips : 24;
		Rosalie : 12;
		Goodlett : 16;
		Lenapah : 12;
		Malaga : 3;
		Mentone : 3;
		Tigard : 1;
		Skokomish : 1;
		Goulds : 1;
		Montello : 1;
		Lushton : 1;
		Bevington : 1;
		Reager : 1;
		Greenbush : 1;
		Calabash : 8;
	}
}

header_type Harriston {
	fields {
		Brewerton : 8;
		Crary : 1;
		Lecompte : 1;
		Bellville : 1;
		Almont : 1;
		Gerster : 1;
	}
}

header_type Crumstown {
	fields {
		Combine : 32;
		Jones : 32;
		Edler : 8;
		LaMarque : 16;
	}
}

header_type Fenwick {
	fields {
		Bryan : 128;
		Nashua : 128;
		Hanover : 20;
		Ellicott : 8;
	}
}

header_type Verdigris {
	fields {
		Capitola : 14;
		GlenDean : 1;
		Cornish : 1;
		Millsboro : 12;
		Barnhill : 1;
		Monahans : 6;
	}
}

header_type Tanner {
	fields {
		Globe : 1;
		IowaCity : 1;
	}
}

header_type Antonito {
	fields {
		Licking : 8;
	}
}

header_type NewTrier {
	fields {
		Karluk : 16;
	}
}

header_type Stidham {
	fields {
		Santos : 32;
		Arminto : 32;
	}
}

#endif



#ifndef Tatum
#define Tatum



header_type Anguilla {
	fields {
		Lakebay : 24;
		GunnCity : 24;
		Amity : 24;
		Silica : 24;
		Browning : 16;
	}
}



header_type Baltimore {
	fields {
		Tillicum : 3;
		Otisco : 1;
		McGonigle : 12;
		Mumford : 16;
	}
}



header_type Burrel {
	fields {
		Fontana : 4;
		Eckman : 4;
		Ahmeek : 8;
		Wymer : 16;
		Paxtonia : 16;
		Wrens : 3;
		Monetta : 13;
		Raytown : 8;
		WestBay : 8;
		Shongaloo : 16;
		Dowell : 32;
		Taopi : 32;
	}
}

header_type Anawalt {
	fields {
		Fosters : 4;
		Bonsall : 8;
		Idalia : 20;
		Boyero : 16;
		Louviers : 8;
		WestLawn : 8;
		Samson : 128;
		Troutman : 128;
	}
}




header_type Tolleson {
	fields {
		Canton : 8;
		Nixon : 8;
		Wyncote : 16;
	}
}

header_type RockPort {
	fields {
		Buncombe : 16;
		Willard : 16;
		Wenham : 32;
		Belpre : 32;
		Rainsburg : 4;
		Nunda : 4;
		Silco : 8;
		Chalco : 16;
		Rockvale : 16;
		McClure : 16;
	}
}

header_type Makawao {
	fields {
		Danbury : 16;
		Between : 16;
		Bammel : 16;
		Noelke : 16;
	}
}



header_type Kerby {
	fields {
		Newtonia : 16;
		ElVerano : 16;
		Standard : 8;
		Luzerne : 8;
		Susank : 16;
	}
}

header_type Gilman {
	fields {
		Dubbs : 48;
		Hamel : 32;
		Theta : 48;
		Salome : 32;
	}
}



header_type Harvard {
	fields {
		Careywood : 1;
		Isabela : 1;
		Leesport : 1;
		RedCliff : 1;
		Mackey : 1;
		BullRun : 3;
		Ingleside : 5;
		Pringle : 3;
		Hartwell : 16;
	}
}

header_type DeSart {
	fields {
		TiffCity : 24;
		Astor : 8;
	}
}



header_type Charm {
	fields {
		Rhinebeck : 8;
		WhiteOwl : 24;
		Tavistock : 24;
		Placida : 8;
	}
}

#endif



#ifndef Glennie
#define Glennie

parser start {
   return Kentwood;
}

#define Ashburn        0x8100
#define Chatanika        0x0800
#define Waialee        0x86dd
#define Homeland        0x9100
#define SanRemo        0x8847
#define Youngwood         0x0806
#define Swansea        0x8035
#define Cresco        0x88cc
#define Lubeck        0x8809

#define Lignite              1
#define Moorpark              2
#define Dockton              4
#define Calvary               6
#define Fackler               17
#define Mariemont                47

#define Kekoskee         0x501
#define Absecon          0x506
#define Biddle          0x511
#define Mulvane          0x52F


#define Plateau                 4789



#define Harrison               0
#define Cruso              1
#define Grigston                2



#define Marquette          0
#define Miranda          4095
#define Fragaria  4096
#define Thurmond  8191



#define Negra                      0
#define Browndell                  0
#define Parmele                 1

header Anguilla Charco;
header Anguilla Counce;
header Baltimore Tarlton[ 2 ];
header Burrel McQueen;
header Burrel Ashley;
header Anawalt Nuremberg;
header Anawalt Lampasas;
header RockPort Sagamore;
header Makawao Lenox;
header RockPort Ganado;
header Makawao Bogota;
header Charm Markville;
header Kerby Stone;
header Harvard Belen;

parser Kentwood {
   extract( Charco );
   return select( Charco.Browning ) {
      Ashburn : Padonia;
      Chatanika : Yocemento;
      Waialee : Wolcott;
      Youngwood  : Johnsburg;
      default        : ingress;
   }
}

parser Padonia {
   extract( Tarlton[0] );
   return select( Tarlton[0].Mumford ) {
      Chatanika : Yocemento;
      Waialee : Wolcott;
      Youngwood  : Johnsburg;
      default : ingress;
   }
}

parser Yocemento {
   extract( McQueen );
   return select(McQueen.Monetta, McQueen.Eckman, McQueen.WestBay) {
      Biddle : Monmouth;
      default : ingress;
   }
}

parser Wolcott {
   extract( Lampasas );
   return ingress;
}

parser Johnsburg {
   extract( Stone );
   return ingress;
}

parser Monmouth {
   extract(Lenox);
   return select(Lenox.Between) {
      Plateau : Despard;
      default : ingress;
    }
}

parser Berenice {
   set_metadata(SomesBar.Kountze, Grigston);
   return Cowen;
}

parser Merino {
   set_metadata(SomesBar.Kountze, Grigston);
   return Dresser;
}

parser Castolon {
   extract(Belen);
   return select(Belen.Careywood, Belen.Isabela, Belen.Leesport, Belen.RedCliff, Belen.Mackey,
             Belen.BullRun, Belen.Ingleside, Belen.Pringle, Belen.Hartwell) {
      Chatanika : Berenice;
      Waialee : Merino;
      default : ingress;
   }
}

parser Despard {
   extract(Markville);
   set_metadata(SomesBar.Kountze, Cruso);
   return Flomaton;
}

parser Cowen {
   extract( Ashley );
   return ingress;
}

parser Dresser {
   extract( Nuremberg );
   return ingress;
}

parser Flomaton {
   extract( Counce );
   return select( Counce.Browning ) {
      Chatanika: Cowen;
      Waialee: Dresser;
      default: ingress;
   }
}
#endif

metadata Wyanet SomesBar;
metadata Cullen Larue;
metadata Verdigris Moylan;
metadata Crumstown Bonduel;
metadata Fenwick Weskan;
metadata Tanner Myrick;
metadata Harriston ElkPoint;
metadata Antonito Cascadia;
metadata NewTrier Coalgate;
metadata Stidham Anthon;






@pragma pa_solitary ingress SomesBar.Brunson
@pragma pa_solitary ingress SomesBar.Sonoita
@pragma pa_solitary ingress SomesBar.Kingman


@pragma pa_solitary ig_intr_md_for_tm.ucast_egress_port
@pragma pa_solitary ingress ig_intr_md_for_tm.mcast_grp_a




#ifndef Langtry
#define Langtry

action Dushore() {
   no_op();
}

#endif

















#define Arroyo 288

action Vevay(Castine, ElkRidge, Navarro, Wattsburg, Levasy, Dollar) {
    modify_field(Moylan.Capitola, Castine);
    modify_field(Moylan.GlenDean, ElkRidge);
    modify_field(Moylan.Millsboro, Navarro);
    modify_field(Moylan.Cornish, Wattsburg);
    modify_field(Moylan.Barnhill, Levasy);
    modify_field(Moylan.Monahans, Dollar);
}

@pragma command_line --no-dead-code-elimination
table Scranton {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Vevay;
    }
    size : Arroyo;
}

control Perryton {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Scranton);
    }
}





#define FoxChase 512
#define Renton 512


action Geeville(Daniels) {
   modify_field( Larue.Tigard, 1 );
   modify_field( Larue.Calabash, Daniels);
   modify_field( SomesBar.Blueberry, 1 );
}

action Calamus() {
   modify_field( SomesBar.Nambe, 1 );
   modify_field( SomesBar.Stanwood, 1 );
}

action Jenera() {
   modify_field( SomesBar.Blueberry, 1 );
}

action Wilmore() {
   modify_field( SomesBar.Weatherly, 1 );
}

action RedMills() {
   modify_field( SomesBar.Stanwood, 1 );
}


table Talmo {
   reads {
      Charco.Lakebay : ternary;
      Charco.GunnCity : ternary;
   }

   actions {
      Geeville;
      Calamus;
      Jenera;
      Wilmore;
      RedMills;
   }
   default_action : RedMills;
   size : FoxChase;
}

action Hotevilla() {
   modify_field( SomesBar.Skene, 1 );
}


table Paxico {
   reads {
      Charco.Amity : ternary;
      Charco.Silica : ternary;
   }

   actions {
      Hotevilla;
   }
   size : Renton;
}


control Sudden {
   apply( Talmo );
   apply( Paxico );
}




#define Leola 1024
#define Lucien 4096
#define BigPoint 4096
#define Platina 4096
#define Westville 4096
#define Doris 1024
#define Congress 4096

action Airmont() {
   modify_field( Bonduel.Combine, Ashley.Dowell );
   modify_field( Bonduel.Jones, Ashley.Taopi );
   modify_field( Bonduel.Edler, Ashley.WestBay );
   modify_field( Weskan.Bryan, Nuremberg.Samson );
   modify_field( Weskan.Nashua, Nuremberg.Troutman );
   modify_field( Weskan.Hanover, Nuremberg.Idalia );
   modify_field( SomesBar.Alvwood, Counce.Lakebay );
   modify_field( SomesBar.Scottdale, Counce.GunnCity );
   modify_field( SomesBar.Cisco, Counce.Amity );
   modify_field( SomesBar.Tilghman, Counce.Silica );
   modify_field( SomesBar.Tennyson, Counce.Browning );
}

action Newfane() {
   modify_field( SomesBar.Kountze, Harrison );
   modify_field( Bonduel.Combine, McQueen.Dowell );
   modify_field( Bonduel.Jones, McQueen.Taopi );
   modify_field( Bonduel.Edler, McQueen.WestBay );
   modify_field( Weskan.Bryan, Lampasas.Samson );
   modify_field( Weskan.Nashua, Lampasas.Troutman );
   modify_field( Weskan.Hanover, Nuremberg.Idalia );
   modify_field( SomesBar.Alvwood, Charco.Lakebay );
   modify_field( SomesBar.Scottdale, Charco.GunnCity );
   modify_field( SomesBar.Cisco, Charco.Amity );
   modify_field( SomesBar.Tilghman, Charco.Silica );
   modify_field( SomesBar.Tennyson, Charco.Browning );
}

table Eastover {
   reads {
      Charco.Lakebay : exact;
      Charco.GunnCity : exact;
      McQueen.Taopi : exact;
      SomesBar.Kountze : exact;
   }

   actions {
      Airmont;
      Newfane;
   }

   default_action : Newfane();
   size : Leola;
}


action Kendrick() {
   modify_field( SomesBar.Brunson, Moylan.Millsboro );
   modify_field( SomesBar.Sonoita, Moylan.Capitola);
}

action Bernstein( Enderlin ) {
   modify_field( SomesBar.Brunson, Enderlin );
   modify_field( SomesBar.Sonoita, Moylan.Capitola);
}

action Billings() {
   modify_field( SomesBar.Brunson, Tarlton[0].McGonigle );
   modify_field( SomesBar.Sonoita, Moylan.Capitola);
}

table Wardville {
   reads {
      Moylan.Capitola : ternary;
      Tarlton[0] : valid;
      Tarlton[0].McGonigle : ternary;
   }

   actions {
      Kendrick;
      Bernstein;
      Billings;
   }
   size : Platina;
}

action Egypt( Roswell ) {
   modify_field( SomesBar.Sonoita, Roswell );
}

action Palomas() {

   modify_field( SomesBar.Connell, 1 );
   modify_field( Cascadia.Licking,
                 Parmele );
}

table Senatobia {
   reads {
      McQueen.Dowell : exact;
   }

   actions {
      Egypt;
      Palomas;
   }
   default_action : Palomas;
   size : BigPoint;
}

action Mabelle( Molson, GlenArm, Kasigluk, Hodge, Taylors,
                        Westbury, Waterflow ) {
   modify_field( SomesBar.Brunson, Molson );
   modify_field( SomesBar.FlatRock, Waterflow );
   Shamokin(GlenArm, Kasigluk, Hodge, Taylors,
                        Westbury );
}

action Jemison() {
   modify_field( SomesBar.Ranchito, 1 );
}

table Muenster {
   reads {
      Markville.Tavistock : exact;
   }

   actions {
      Mabelle;
      Jemison;
   }
   size : Lucien;
}

action Shamokin(GlenArm, Kasigluk, Hodge, Taylors,
                        Westbury ) {
   modify_field( ElkPoint.Brewerton, GlenArm );
   modify_field( ElkPoint.Crary, Kasigluk );
   modify_field( ElkPoint.Bellville, Hodge );
   modify_field( ElkPoint.Lecompte, Taylors );
   modify_field( ElkPoint.Almont, Westbury );
}

action Helotes(GlenArm, Kasigluk, Hodge, Taylors,
                        Westbury ) {
   modify_field( SomesBar.Kingman, Moylan.Millsboro );
   modify_field( SomesBar.FlatRock, 1 );
   Shamokin(GlenArm, Kasigluk, Hodge, Taylors,
                        Westbury );
}

action Ladner(Mertens, GlenArm, Kasigluk, Hodge,
                        Taylors, Westbury ) {
   modify_field( SomesBar.Kingman, Mertens );
   modify_field( SomesBar.FlatRock, 1 );
   Shamokin(GlenArm, Kasigluk, Hodge, Taylors,
                        Westbury );
}

action McKee(GlenArm, Kasigluk, Hodge, Taylors,
                        Westbury ) {
   modify_field( SomesBar.Kingman, Tarlton[0].McGonigle );
   modify_field( SomesBar.FlatRock, 1 );
   Shamokin(GlenArm, Kasigluk, Hodge, Taylors,
                        Westbury );
}

table Weleetka {
   reads {
      Moylan.Millsboro : exact;
   }

   actions {
      Helotes;
   }

   size : Westville;
}

table Bessie {
   reads {
      Moylan.Capitola : exact;
      Tarlton[0].McGonigle : exact;
   }

   actions {
      Ladner;
      Dushore;
   }
   default_action : Dushore;

   size : Doris;
}

table LaFayette {
   reads {
      Tarlton[0].McGonigle : exact;
   }

   actions {
      McKee;
   }

   size : Congress;
}

control Caban {
   apply( Eastover ) {
         Airmont {
            apply( Senatobia );
            apply( Muenster );
         }
         Newfane {
            if ( Moylan.Cornish == 1 ) {
               apply( Wardville );
            }
            if ( valid( Tarlton[ 0 ] ) ) {

               apply( Bessie ) {
                  Dushore {

                     apply( LaFayette );
                  }
               }
            } else {

               apply( Weleetka );
            }
         }
   }
}





#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Onamia {
    width  : 1;
    static : Arvada;
    instance_count : 262144;
}

register Mahopac {
    width  : 1;
    static : Glynn;
    instance_count : 262144;
}

blackbox stateful_alu Fajardo {
    reg : Onamia;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Myrick.Globe;
}

blackbox stateful_alu Gastonia {
    reg : Mahopac;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Myrick.IowaCity;
}

field_list Wharton {
    Moylan.Monahans;
    Tarlton[0].McGonigle;
}

field_list_calculation Angwin {
    input { Wharton; }
    algorithm: identity;
    output_width: 18;
}

action Wyatte() {
    Fajardo.execute_stateful_alu_from_hash(Angwin);
}

action Renville() {
    Gastonia.execute_stateful_alu_from_hash(Angwin);
}

table Arvada {
    actions {
      Wyatte;
    }
    default_action : Wyatte;
    size : 1;
}

table Glynn {
    actions {
      Renville;
    }
    default_action : Renville;
    size : 1;
}
#endif

action Lewellen(HydePark) {
    modify_field(Myrick.IowaCity, HydePark);
}

@pragma  use_hash_action 0
table Manasquan {
    reads {
       Moylan.Monahans : exact;
    }
    actions {
      Lewellen;
    }
    size : 64;
}

action Janney() {
   modify_field( SomesBar.Petroleum, Moylan.Millsboro );
   modify_field( SomesBar.Berwyn, 0 );
}

table Cantwell {
   actions {
      Janney;
   }
   size : 1;
}

action Hiwassee() {
   modify_field( SomesBar.Petroleum, Tarlton[0].McGonigle );
   modify_field( SomesBar.Berwyn, 1 );
}

table Tallevast {
   actions {
      Hiwassee;
   }
   size : 1;
}

control Halaula {
   if ( valid( Tarlton[ 0 ] ) ) {
      apply( Tallevast );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Moylan.Barnhill == 1 ) {
         apply( Arvada );
         apply( Glynn );
      }
#endif
   } else {
      apply( Cantwell );
      if( Moylan.Barnhill == 1 ) {
         apply( Manasquan );
      }
   }
}




#define Asharoken     256

field_list Harbor {
   Charco.Lakebay;
   Charco.GunnCity;
   Charco.Amity;
   Charco.Silica;
   Charco.Browning;
}

field_list Koloa {
   McQueen.Dowell;
   McQueen.Taopi;
   McQueen.WestBay;
}

field_list Saluda {
   Lampasas.Samson;
   Lampasas.Troutman;
   Lampasas.Idalia;
   Lampasas.Louviers;
}





field_list_calculation Tyrone {
    input {
        Harbor;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Valier {
    input {
        Koloa;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Minto {
    input {
        Saluda;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Olmstead() {
    modify_field_with_hash_based_offset(Anthon.Santos, 0,
                                        Tyrone, 65536);
}

action Everetts() {
    modify_field_with_hash_based_offset(Anthon.Santos, 0,
                                        Valier, 65536);
}

action Holladay() {
    modify_field_with_hash_based_offset(Anthon.Santos, 0,
                                        Minto, 65536);
}

@pragma immediate 0
table Baranof {
   reads {
      Ganado.valid : ternary;
      Bogota.valid : ternary;
      Ashley.valid : ternary;
      Nuremberg.valid : ternary;
      Counce.valid : ternary;
      Sagamore.valid : ternary;
      Lenox.valid : ternary;
      McQueen.valid : ternary;
      Lampasas.valid : ternary;
      Charco.valid : ternary;
   }
   actions {
      Olmstead;
      //Everetts;  // Hardware cannot write 2 unique 32-bit hash values (they OR together)
      Dushore;
   }
   default_action : Dushore();
   size: Asharoken;
}

control Oakes {
   apply(Baranof);
}



#define Conda      65536
#define Bethesda      512
#define Townville 512

counter Norborne {
   type : packets_and_bytes;
   direct : Elihu;
   min_width: 16;
}

action Marie() {
   modify_field(SomesBar.Ringwood, 1 );
}

table Elihu {
   reads {
      Moylan.Monahans : exact;
      Myrick.IowaCity : ternary;
      Myrick.Globe : ternary;
      SomesBar.Ranchito : ternary;
      SomesBar.Skene : ternary;
      SomesBar.Nambe : ternary;
   }

   actions {
      Marie;
      Dushore;
   }
   default_action : Dushore;
   size : Bethesda;
}

register Ashville {
   width: 1;
   static: Hammocks;
   instance_count: Conda;
}

#ifdef __TARGET_TOFINO__
blackbox stateful_alu Challenge{
    reg: Ashville;
    update_lo_1_value: set_bit;
}
#endif

action Lawai(Tahuya) {
#if defined(BMV2) || defined(BMV2TOFINO)
   register_write(Ashville, Tahuya, 1);
#else
   Challenge.execute_stateful_alu();
#endif

}

action Pueblo() {

   modify_field(SomesBar.Laney, 1 );
   modify_field(Cascadia.Licking,
                Browndell);
}

table Hammocks {
   reads {
      SomesBar.Cisco : exact;
      SomesBar.Tilghman : exact;
      SomesBar.Brunson : exact;
      SomesBar.Sonoita : exact;
   }

   actions {
      Lawai;
      Pueblo;
   }
   size : Conda;
}

action Northboro() {
   modify_field( ElkPoint.Gerster, 1 );
}

table Risco {
   reads {
      SomesBar.Kingman : ternary;
      SomesBar.Alvwood : exact;
      SomesBar.Scottdale : exact;
   }
   actions {
      Northboro;
   }
   size: Townville;
}

control Equality {
   if( SomesBar.Ringwood == 0 ) {
      apply( Risco );
   }
}

control Parshall {
   apply( Elihu ) {
      Dushore {



         if (Moylan.GlenDean == 0 and SomesBar.Connell == 0) {
            apply( Hammocks );
         }
         apply(Risco);
      }
   }
}

field_list Tahlequah {
    Cascadia.Licking;
    SomesBar.Cisco;
    SomesBar.Tilghman;
    SomesBar.Brunson;
    SomesBar.Sonoita;
}

action Tunis() {
   generate_digest(Negra, Tahlequah);
}

table Elbert {
   actions {
      Tunis;
   }
   size : 1;
}

control Barnwell {
   if (SomesBar.Laney == 1) {
      apply( Elbert );
   }
}


#define Chatom 65536
#define Saxonburg 65536
#define Tanana   16384
#define Edmeston         131072
#define Illmo 65536
#define Riner 1024

@pragma idletime_precision 1
table Calva {

   reads {
      ElkPoint.Brewerton : exact;
      Bonduel.Jones : lpm;
   }

   actions {
      Unionvale;
      Dushore;
   }

   default_action : Dushore();
   size : Riner;
   support_timeout : true;
}

action Chaska(Upson) {
   modify_field(Bonduel.LaMarque, Upson);
}

table Ridgetop {
   reads {
      ElkPoint.Brewerton : exact;
      Bonduel.Jones : lpm;
   }

   actions {
      Chaska;
   }

   size : Tanana;
}

@pragma atcam_partition_index Bonduel.LaMarque
@pragma atcam_number_partitions Tanana
table Rapids {
   reads {
      Bonduel.LaMarque : exact;



      Bonduel.Jones mask 0x000fffff : lpm;
   }
   actions {
      Unionvale;
      Dushore;
   }
   default_action : Dushore();
   size : Edmeston;
}

action Unionvale( Ionia ) {
   modify_field( Larue.Greenbush, 1 );
   modify_field( Coalgate.Karluk, Ionia );
}

@pragma idletime_precision 1
table Visalia {
   reads {
      ElkPoint.Brewerton : exact;
      Bonduel.Jones : exact;
   }

   actions {
      Unionvale;
      Dushore;
   }
   default_action : Dushore();
   size : Chatom;
   support_timeout : true;
}

@pragma idletime_precision 1
table Barnsboro {
   reads {
      ElkPoint.Brewerton : exact;
      Weskan.Nashua : exact;
   }

   actions {
      Unionvale;
      Dushore;
   }
   default_action : Dushore();
   size : Saxonburg;
   support_timeout : true;
}

action Altadena(Grainola, Sabina, Livengood) {
   modify_field(Larue.Rosalie, Livengood);
   modify_field(Larue.Stillmore, Grainola);
   modify_field(Larue.Mayview, Sabina);
   modify_field(Larue.Greenbush, 1);
}

table Aurora {
   reads {
      Coalgate.Karluk : exact;
   }

   actions {
      Altadena;
   }
   size : Illmo;
}

control DuQuoin {




   if ( SomesBar.Ringwood == 0 and ElkPoint.Gerster == 1 ) {
      if ( ( ElkPoint.Crary == 1 ) and
           ( ( SomesBar.Kountze == Harrison and valid( McQueen ) ) or
             ( SomesBar.Kountze != Harrison and valid( Ashley ) ) ) ) {
         apply( Visalia ) {
            Dushore {
               apply( Ridgetop );
               if( Bonduel.LaMarque != 0 ) {
                  apply( Rapids );
               }
               if (Coalgate.Karluk == 0 ) {
                  apply( Calva );
               }
            }
         }
      } else if ( ( ElkPoint.Bellville == 1 ) and
            ( SomesBar.Kountze == Harrison and valid( Lampasas ) ) or
             ( SomesBar.Kountze != Harrison and valid( Nuremberg ) ) ) {
         apply( Barnsboro );
      }
   }
}

control Cornell {
   if( Coalgate.Karluk != 0 ) {
      apply( Aurora );
   }
}



#define Verndale     1024
#define McManus    1024

#define Weathers
#define Melmore

field_list Temelec {
   Anthon.Santos;
}

field_list_calculation Salamonia {
    input {
        Temelec;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector JaneLew {
    selection_key : Salamonia;
    selection_mode : resilient;
}

action Valsetz(Sunrise) {
   modify_field(Larue.Goodlett, Sunrise);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Sunrise);
}

action_profile Macungie {
    actions {
        Valsetz;
        Dushore;
    }
    size : McManus;
    dynamic_action_selection : JaneLew;
}

table LaJoya {
   reads {
      Larue.Goodlett : exact;
   }
   action_profile: Macungie;
   size : Verndale;
}

control Brodnax {
   if ((Larue.Goodlett & 0x2000) == 0x2000) {
      apply(LaJoya);
   }
}



#define Polkville      65536

action Pickering() {
   modify_field(Larue.Stillmore, SomesBar.Alvwood);
   modify_field(Larue.Mayview, SomesBar.Scottdale);
   modify_field(Larue.Tornillo, SomesBar.Cisco);
   modify_field(Larue.Advance, SomesBar.Tilghman);
   modify_field(Larue.Rosalie, SomesBar.Brunson);
}

table Gerlach {
   actions {
      Pickering;
   }
   default_action : Pickering();
   size : 1;
}

control BurrOak {
   if (SomesBar.Brunson!=0) {
      apply( Gerlach );
   }
}

action Crossett() {
   modify_field(Larue.Goulds, 1);
   modify_field(Larue.Skokomish, 1);

   add(ig_intr_md_for_tm.mcast_grp_a, Larue.Rosalie,0);
//   bit_and(ig_intr_md_for_tm.mcast_grp_a, Larue.Rosalie,0xFFF);
//   modify_field(ig_intr_md_for_tm.mcast_grp_a, Larue.Rosalie /* , 0xFFF */);
}

action Abbott() {
}



@pragma ways 1
table Hartfield {
   reads {
      Larue.Stillmore : exact;
      Larue.Mayview : exact;
   }
   actions {
      Crossett;
      Abbott;
   }
   default_action : Abbott;
   size : 1;
}

action Harlem() {
   modify_field(Larue.Montello, 1);
   modify_field(Larue.Reager, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Larue.Rosalie, Fragaria);
//   bit_or(ig_intr_md_for_tm.mcast_grp_a, Larue.Rosalie, Fragaria);

}

table Valentine {
   actions {
      Harlem;
   }
   default_action : Harlem;
   size : 1;
}

action Cypress() {
   modify_field(Larue.Bevington, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Larue.Rosalie, 0);
//   bit_and(ig_intr_md_for_tm.mcast_grp_a, Larue.Rosalie,0xFFF);
//   modify_field(ig_intr_md_for_tm.mcast_grp_a, Larue.Rosalie /*, 0xFFF */);
}

table Hallowell {
   actions {
      Cypress;
   }
   default_action : Cypress();
   size : 1;
}

action Odenton(Miltona) {
   modify_field(Larue.Lushton, 1);
   modify_field(Larue.Goodlett, Miltona);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Miltona);
}

action Dunbar(Noyack) {
   modify_field(Larue.Montello, 1);

   modify_field(ig_intr_md_for_tm.mcast_grp_a, Noyack);
}

action Piedmont() {
}

table Wrenshall {
   reads {
      Larue.Stillmore : exact;
      Larue.Mayview : exact;
      Larue.Rosalie : exact;
   }

   actions {
      Odenton;
      Dunbar;
      Piedmont;
   }
   default_action : Piedmont();
   size : Polkville;
}

control Mabelvale {
   if (SomesBar.Ringwood == 0) {
      apply(Wrenshall) {
         Piedmont {
            apply(Hartfield) {
               Abbott {
                  if ((Larue.Stillmore & 0x010000) == 0x010000) {
                     apply(Valentine);
                  } else {
                     apply(Hallowell);
                  }
               }
            }
         }
      }
   }
}


action Pelican() {
   modify_field(SomesBar.Ringwood, 1);
}

table Bomarton {
   actions {
      Pelican;
   }
   default_action : Pelican();
   size : 1;
}

control Rocklake {
   if ((Larue.Greenbush==0) and (SomesBar.Sonoita==Larue.Goodlett)) {
      apply(Bomarton);
   }
}


#ifndef Attica
#define Attica

#define Reynolds    4096

action Garrison( Exton ) {
   modify_field( Larue.Lenapah, Exton );
}

action HighRock() {
   modify_field( Larue.Lenapah, Larue.Rosalie );
}

table Columbia {
   reads {
      eg_intr_md.egress_port : exact;
      Larue.Rosalie : exact;
   }

   actions {
      Garrison;
      HighRock;
   }
   default_action : HighRock;
   size : Reynolds;
}

action Pfeifer() {
   modify_field( Larue.Rosalie, eg_intr_md.egress_rid );
}

table Paragonah {
   reads {
      eg_intr_md.egress_rid : exact;
   }

   actions {
      Pfeifer;
   }
   size : 65536;
}

control Warden {



   apply( Columbia );
}


#endif


#ifndef Lanyon
#define Lanyon

#define Westbrook 64
#define Sledge 1
#define Glenside  8
#define Pinta 512

#define Tuskahoma 0

action Rosebush( BigRun, Blakeley ) {
   modify_field( Larue.Coamo, BigRun );
   modify_field( Larue.Moclips, Blakeley );
}


table Penitas {
   reads {
      Larue.Malaga : exact;
   }

   actions {
      Rosebush;
   }
   size : Glenside;
}

action Traverse() {
   no_op();
}

action Conger() {
   modify_field( Charco.Browning, Tarlton[0].Mumford );
   remove_header( Tarlton[0] );
}

table Helen {
   actions {
      Conger;
   }
   default_action : Conger;
   size : Sledge;
}

action Twinsburg() {
   no_op();
}

action Auberry() {
   add_header( Tarlton[ 0 ] );
   modify_field( Tarlton[0].McGonigle, Larue.Lenapah );
   modify_field( Tarlton[0].Mumford, Charco.Browning );
   modify_field( Charco.Browning, Ashburn );
}



table Paullina {
   reads {
      Larue.Lenapah : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Twinsburg;
      Auberry;
   }
   default_action : Auberry;
   size : Westbrook;
}

action Salineno() {
   modify_field(Charco.Lakebay, Larue.Stillmore);
   modify_field(Charco.GunnCity, Larue.Mayview);
   modify_field(Charco.Amity, Larue.Coamo);
   modify_field(Charco.Silica, Larue.Moclips);
}

action Domingo() {
   Salineno();
   add_to_field(McQueen.Raytown, -1);
}

action Petoskey() {
   Salineno();
   add_to_field(Lampasas.WestLawn, -1);
}






table Callimont {
   reads {
      Larue.Mentone : exact;
      Larue.Malaga : exact;
      Larue.Greenbush : exact;
      McQueen.valid : ternary;
      Lampasas.valid : ternary;
      Larue.Coamo mask 0x1 : ternary;
   }

   actions {
      Domingo;
      Petoskey;
   }
   size : Pinta;
}

control AukeBay {
   apply( Helen );
}

control Hendley {
   apply( Paullina );
}

control Hanapepe {
   apply( Penitas );
   apply( Callimont );
}
#endif



field_list Lamison {
    Cascadia.Licking;
    SomesBar.Brunson;
    Counce.Amity;
    Counce.Silica;
    McQueen.Dowell;
}

action Powelton() {
   generate_digest(Negra, Lamison);
}

table RioLajas {
   actions {
      Powelton;
   }

   default_action : Powelton;
   size : 1;
}

control Volcano {
   if (SomesBar.Connell == 1) {
      apply(RioLajas);
   }
}

control ingress {
   Perryton();

   Sudden();
   Caban();
   Halaula();

   Parshall();


   DuQuoin();
   BurrOak();
   Cornell();

   Oakes();


   Mabelvale();

   Rocklake();


   Brodnax();


   Volcano();
   Barnwell();


   if( valid( Tarlton[0] ) ) {
      AukeBay();
   }
}

control egress {
   Warden();
   Hanapepe();
   Hendley();
}

