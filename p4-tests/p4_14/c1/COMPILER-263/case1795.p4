// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 193827







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
#else





header_type Montezuma {
	fields {
		PellLake : 3;
	}
}
metadata Montezuma Barron;

header_type Renville {
	fields {
		Grinnell : 1;
		Wheeling : 9;
		Kosciusko : 48;
		Poplar : 32;
	}
}
metadata Renville Moneta;

header_type Simla {
	fields {
		Wapato : 9;
		Wegdahl : 3;
		Clover : 16;
		Pardee : 16;
		Dasher : 13;
		FlatLick : 13;
		Pinto : 16;
		Maben : 9;
		Mertens : 16;
		Monowi : 1;
		McClusky : 3;
		Hokah : 5;
		Wondervu : 2;
	}
}

metadata Simla Liberal;

header_type Somis {
	fields {
		Heeia : 9;
		Elimsport : 19;
		WestEnd : 2;
		Sharon : 32;
		Wellford : 19;
		Stoystown : 2;
		Ossining : 8;
		LunaPier : 32;
		Forkville : 16;
		Poipu : 1;
		Sparland : 5;
		Gallinas : 3;
		Dunnville : 1;
	}
}

metadata Somis Onida;




action Atlasburg(DeepGap) {
    modify_field(LaMonte, DeepGap);
}

#ifdef BMV2
#define Sherrill     Millican
#else
#define Sherrill         Sahuarita
#endif

header_type Margie {
	fields {
		VanHorn : 8;
		Woodcrest : 48;
	}
}
metadata Margie Felton;

#define Lakeside 0
#define Weathers 1
#define Grasston 2
#define Glendevey 3
#define Macon 4
#define Amboy 5
#define McAdams 6


#define Eddington \
    ((Negra != Lakeside) and \
     (Negra != Amboy))
#define Yatesboro \
    ((Negra == Lakeside) or \
     (Negra == Amboy))
#define Bulverde \
    (Negra == Weathers)
#define Romney \
    (Negra == Grasston)
#endif



#ifndef Otsego
#define Otsego

header_type Harvest {
	fields {
		Lasara : 24;
		Ivanhoe : 24;
		McCune : 24;
		Lignite : 24;
		Monohan : 16;
		Calabash : 16;
		Kasilof : 16;
		Allegan : 16;
		Neches : 12;
		Faulkton : 2;
		Arvada : 1;
		Dushore : 1;
		BeeCave : 1;
		ShowLow : 1;
		Elsey : 1;
		Remington : 1;
		Weslaco : 1;
		Valmont : 1;
		Lindy : 1;
		Browndell : 1;
		KeyWest : 1;
	}
}

header_type Lostine {
	fields {
		Roscommon : 24;
		Bendavis : 24;
		RoyalOak : 24;
		Blueberry : 24;
		Shasta : 24;
		Cabot : 24;
		Dresser : 16;
		Carnero : 16;
		Leonidas : 16;
		Pelion : 12;
		Alston : 3;
		BlueAsh : 3;
		Pittsboro : 1;
		Bowen : 1;
		Benkelman : 1;
		Lapel : 1;
		Fergus : 1;
		Milam : 1;
		Guadalupe : 1;
		Dubuque : 1;
		Vacherie : 8;
	}
}

header_type Asherton {
	fields {
		Higley : 8;
		NantyGlo : 1;
		Hallwood : 1;
		Remsen : 1;
		Yerington : 1;
		Wickett : 1;
	}
}

header_type Stuttgart {
	fields {
		Mendon : 32;
		Waimalu : 32;
		Hewins : 8;
		Chambers : 16;
	}
}

header_type Tulip {
	fields {
		Lumberton : 128;
		Keener : 128;
		Millbrae : 20;
		Newkirk : 8;
	}
}

header_type Isleta {
	fields {
		Bannack : 14;
		Litroe : 1;
		Ruffin : 1;
		Natalbany : 12;
		Montbrook : 1;
		Columbia : 6;
	}
}

header_type Southdown {
	fields {
		Rehobeth : 1;
		Maida : 1;
	}
}

header_type Roxboro {
	fields {
		Rockfield : 8;
	}
}

header_type Accord {
	fields {
		Trimble : 16;
	}
}

header_type Loring {
	fields {
		Candle : 32;
		Wilmore : 32;
	}
}

#endif



#ifndef Joseph
#define Joseph



header_type Knippa {
	fields {
		SanJuan : 24;
		Weatherly : 24;
		Gordon : 24;
		Topton : 24;
		Lilydale : 16;
	}
}



header_type Marie {
	fields {
		Fairborn : 3;
		Equality : 1;
		Jigger : 12;
		Bellmore : 16;
	}
}



header_type Alamosa {
	fields {
		Sunrise : 4;
		Logandale : 4;
		Radcliffe : 8;
		Melstrand : 16;
		NorthRim : 16;
		Ranier : 3;
		Ravena : 13;
		Robinette : 8;
		Tunica : 8;
		VanZandt : 16;
		Finney : 32;
		Alamota : 32;
	}
}

header_type Grenville {
	fields {
		Melba : 4;
		Meeker : 8;
		Lacona : 20;
		Ralph : 16;
		Belgrade : 8;
		Silesia : 8;
		Noelke : 128;
		Kipahulu : 128;
	}
}




header_type Dunnegan {
	fields {
		Glenolden : 8;
		Perma : 8;
		Wollochet : 16;
	}
}

header_type Beaverton {
	fields {
		Claunch : 16;
		Longdale : 16;
		Daykin : 32;
		Hammett : 32;
		Hartford : 4;
		Oklee : 4;
		Correo : 8;
		Alexis : 16;
		Bowdon : 16;
		Bunker : 16;
	}
}

header_type Donnelly {
	fields {
		Linville : 16;
		McKee : 16;
		Broadus : 16;
		Kinston : 16;
	}
}



header_type Manteo {
	fields {
		Taylors : 16;
		Salduro : 16;
		Driftwood : 8;
		Oskaloosa : 8;
		Susank : 16;
	}
}

header_type Machens {
	fields {
		Tiller : 48;
		Helotes : 32;
		Wheaton : 48;
		Hilgard : 32;
	}
}



header_type Langhorne {
	fields {
		Surrency : 1;
		Combine : 1;
		Rozet : 1;
		Lenexa : 1;
		Polkville : 1;
		Laplace : 3;
		Charenton : 5;
		Kansas : 3;
		Wauconda : 16;
	}
}

header_type Milnor {
	fields {
		Mahopac : 24;
		Batchelor : 8;
	}
}



header_type Caldwell {
	fields {
		McManus : 8;
		Manilla : 24;
		Greenwood : 24;
		Melrose : 8;
	}
}

#endif



#ifndef Safford
#define Safford

parser start {
   return Brawley;
}

#define RichBar        0x8100
#define Dunken        0x0800
#define Vallecito        0x86dd
#define Terral        0x9100
#define Neoga        0x8847
#define Owyhee         0x0806
#define Onamia        0x8035
#define Sudden        0x88cc
#define Tramway        0x8809

#define Berenice              1
#define Corinne              2
#define Prismatic              4
#define Addison               6
#define Kingsdale               17
#define Guayabal                47

#define Kapaa         0x501
#define Rippon          0x506
#define Kennedale          0x511
#define Brookland          0x52F


#define Murdock                 4789



#define Suarez               0
#define Murchison              1
#define Seibert                2



#define Daguao          0
#define Wingate          4095
#define Callery  4096
#define Novinger  8191



#define Boonsboro                      0
#define Sublimity                  0
#define McDaniels                 1

header Knippa Twain;
header Knippa TroutRun;
header Marie Jayton[ 2 ];
header Alamosa Switzer;
header Alamosa Fitzhugh;
header Grenville Frewsburg;
header Grenville Baidland;
header Beaverton Lovelady;
header Donnelly Otranto;
header Beaverton Youngwood;
header Donnelly Nanson;
header Caldwell Needles;
header Manteo Crestone;
header Langhorne Mather;

parser Brawley {
   extract( Twain );
   return select( Twain.Lilydale ) {
      RichBar : Alvwood;
      Dunken : Armona;
      Vallecito : Lansdale;
      Owyhee  : Rexville;
      default        : ingress;
   }
}

parser Alvwood {
   extract( Jayton[0] );
   return select( Jayton[0].Bellmore ) {
      Dunken : Armona;
      Vallecito : Lansdale;
      Owyhee  : Rexville;
      default : ingress;
   }
}

parser Armona {
   extract( Switzer );
   return select(Switzer.Ravena, Switzer.Logandale, Switzer.Tunica) {
      Kennedale : Paxico;
      default : ingress;
   }
}

parser Lansdale {
   extract( Baidland );
   return ingress;
}

parser Rexville {
   extract( Crestone );
   return ingress;
}

parser Paxico {
   extract(Otranto);
   return select(Otranto.McKee) {
      Murdock : Pittwood;
      default : ingress;
    }
}

parser Purdon {
   set_metadata(Algoa.Faulkton, Seibert);
   return Stecker;
}

parser Charlack {
   set_metadata(Algoa.Faulkton, Seibert);
   return Masardis;
}

parser Schaller {
   extract(Mather);
   return select(Mather.Surrency, Mather.Combine, Mather.Rozet, Mather.Lenexa, Mather.Polkville,
             Mather.Laplace, Mather.Charenton, Mather.Kansas, Mather.Wauconda) {
      Dunken : Purdon;
      Vallecito : Charlack;
      default : ingress;
   }
}

parser Pittwood {
   extract(Needles);
   set_metadata(Algoa.Faulkton, Murchison);
   return Folger;
}

parser Stecker {
   extract( Fitzhugh );
   return ingress;
}

parser Masardis {
   extract( Frewsburg );
   return ingress;
}

parser Folger {
   extract( TroutRun );
   return select( TroutRun.Lilydale ) {
      Dunken: Stecker;
      Vallecito: Masardis;
      default: ingress;
   }
}
#endif

@pragma pa_solitary ingress Algoa.Calabash
@pragma pa_solitary ingress Algoa.Kasilof
@pragma pa_solitary ingress Algoa.Allegan
@pragma pa_solitary egress Roachdale.Leonidas

metadata Harvest Algoa;
metadata Lostine Roachdale;
metadata Isleta Brodnax;
metadata Stuttgart ElJebel;
metadata Tulip Blevins;
metadata Southdown Boyle;
metadata Asherton Downs;
metadata Roxboro DonaAna;
metadata Accord Collis;
metadata Loring Buckeye;


//@pragma pa_solitary ig_intr_md_for_tm.ucast_egress_port




#ifndef Joshua
#define Joshua

action Kapowsin() {
   no_op();
}

#endif

















#define Baldridge 288

action Ganado(Abernant, Roseworth, Cadott, Sutter, Hauppauge, Grantfork) {
    modify_field(Brodnax.Bannack, Abernant);
    modify_field(Brodnax.Litroe, Roseworth);
    modify_field(Brodnax.Natalbany, Cadott);
    modify_field(Brodnax.Ruffin, Sutter);
    modify_field(Brodnax.Montbrook, Hauppauge);
    modify_field(Brodnax.Columbia, Grantfork);
}

@pragma command_line --no-dead-code-elimination
table Waterman {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Ganado;
    }
    size : Baldridge;
}

control Caspian {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Waterman);
    }
}





#define Doral 512
#define Muncie 512


action RockHill(Springlee) {
   modify_field( Roachdale.Pittsboro, 1 );
   modify_field( Roachdale.Vacherie, Springlee);
   modify_field( Algoa.Lindy, 1 );
}

action Wapinitia() {
   modify_field( Algoa.Weslaco, 1 );
   modify_field( Algoa.KeyWest, 1 );
}

action Jackpot() {
   modify_field( Algoa.Lindy, 1 );
}

action Piketon() {
   modify_field( Algoa.Browndell, 1 );
}

action Moodys() {
   modify_field( Algoa.KeyWest, 1 );
}


table Clintwood {
   reads {
      Twain.SanJuan : ternary;
      Twain.Weatherly : ternary;
   }

   actions {
      RockHill;
      Wapinitia;
      Jackpot;
      Piketon;
      Moodys;
   }
   default_action : Moodys;
   size : Doral;
}

action Lemoyne() {
   modify_field( Algoa.Valmont, 1 );
}


table Orlinda {
   reads {
      Twain.Gordon : ternary;
      Twain.Topton : ternary;
   }

   actions {
      Lemoyne;
   }
   size : Muncie;
}


control Overlea {
   apply( Clintwood );
   apply( Orlinda );
}




#define Standard 1024
#define Mesita 4096
#define Salix 4096
#define Kittredge 4096
#define Kalida 4096
#define Joslin 1024
#define Willette 4096

action Carroll() {
   modify_field( ElJebel.Mendon, Fitzhugh.Finney );
   modify_field( ElJebel.Waimalu, Fitzhugh.Alamota );
   modify_field( ElJebel.Hewins, Fitzhugh.Tunica );
   modify_field( Blevins.Lumberton, Frewsburg.Noelke );
   modify_field( Blevins.Keener, Frewsburg.Kipahulu );
   modify_field( Blevins.Millbrae, Frewsburg.Lacona );
   modify_field( Algoa.Lasara, TroutRun.SanJuan );
   modify_field( Algoa.Ivanhoe, TroutRun.Weatherly );
   modify_field( Algoa.McCune, TroutRun.Gordon );
   modify_field( Algoa.Lignite, TroutRun.Topton );
   modify_field( Algoa.Monohan, TroutRun.Lilydale );
}

action Whatley() {
   modify_field( Algoa.Faulkton, Suarez );
   modify_field( ElJebel.Mendon, Switzer.Finney );
   modify_field( ElJebel.Waimalu, Switzer.Alamota );
   modify_field( ElJebel.Hewins, Switzer.Tunica );
   modify_field( Blevins.Lumberton, Baidland.Noelke );
   modify_field( Blevins.Keener, Baidland.Kipahulu );
   modify_field( Blevins.Millbrae, Frewsburg.Lacona );
   modify_field( Algoa.Lasara, Twain.SanJuan );
   modify_field( Algoa.Ivanhoe, Twain.Weatherly );
   modify_field( Algoa.McCune, Twain.Gordon );
   modify_field( Algoa.Lignite, Twain.Topton );
   modify_field( Algoa.Monohan, Twain.Lilydale );
}

table Colstrip {
   reads {
      Twain.SanJuan : exact;
      Twain.Weatherly : exact;
      Switzer.Alamota : exact;
      Algoa.Faulkton : exact;
   }

   actions {
      Carroll;
      Whatley;
   }

   default_action : Whatley();
   size : Standard;
}


action Olcott() {
   modify_field( Algoa.Calabash, Brodnax.Natalbany );
   modify_field( Algoa.Kasilof, Brodnax.Bannack);
}

action Cleta( Sublett ) {
   modify_field( Algoa.Calabash, Sublett );
   modify_field( Algoa.Kasilof, Brodnax.Bannack);
}

action Lofgreen() {
   modify_field( Algoa.Calabash, Jayton[0].Jigger );
   modify_field( Algoa.Kasilof, Brodnax.Bannack);
}

table Filley {
   reads {
      Brodnax.Bannack : ternary;
      Jayton[0] : valid;
      Jayton[0].Jigger : ternary;
   }

   actions {
      Olcott;
      Cleta;
      Lofgreen;
   }
   size : Kittredge;
}

action McAllen( Salus ) {
   modify_field( Algoa.Kasilof, Salus );
}

action Gibson() {

   modify_field( Algoa.BeeCave, 1 );
   modify_field( DonaAna.Rockfield,
                 McDaniels );
}

table Brinson {
   reads {
      Switzer.Finney : exact;
   }

   actions {
      McAllen;
      Gibson;
   }
   default_action : Gibson;
   size : Salix;
}

action Rendville( Oriskany, Kurthwood, Fowler, Newcomb, Ortley,
                        Viroqua, Gerlach ) {
   modify_field( Algoa.Calabash, Oriskany );
   modify_field( Algoa.Remington, Gerlach );
   LoneJack(Kurthwood, Fowler, Newcomb, Ortley,
                        Viroqua );
}

action Egypt() {
   modify_field( Algoa.Elsey, 1 );
}

table Flomot {
   reads {
      Needles.Greenwood : exact;
   }

   actions {
      Rendville;
      Egypt;
   }
   size : Mesita;
}

action LoneJack(Kurthwood, Fowler, Newcomb, Ortley,
                        Viroqua ) {
   modify_field( Downs.Higley, Kurthwood );
   modify_field( Downs.NantyGlo, Fowler );
   modify_field( Downs.Remsen, Newcomb );
   modify_field( Downs.Hallwood, Ortley );
   modify_field( Downs.Yerington, Viroqua );
}

action Kenyon(Kurthwood, Fowler, Newcomb, Ortley,
                        Viroqua ) {
   modify_field( Algoa.Allegan, Brodnax.Natalbany );
   modify_field( Algoa.Remington, 1 );
   LoneJack(Kurthwood, Fowler, Newcomb, Ortley,
                        Viroqua );
}

action Dilia(Gladstone, Kurthwood, Fowler, Newcomb,
                        Ortley, Viroqua ) {
   modify_field( Algoa.Allegan, Gladstone );
   modify_field( Algoa.Remington, 1 );
   LoneJack(Kurthwood, Fowler, Newcomb, Ortley,
                        Viroqua );
}

action Kamas(Kurthwood, Fowler, Newcomb, Ortley,
                        Viroqua ) {
   modify_field( Algoa.Allegan, Jayton[0].Jigger );
   modify_field( Algoa.Remington, 1 );
   LoneJack(Kurthwood, Fowler, Newcomb, Ortley,
                        Viroqua );
}

table Elburn {
   reads {
      Brodnax.Natalbany : exact;
   }

   actions {
      Kenyon;
   }

   size : Kalida;
}

table Hilburn {
   reads {
      Brodnax.Bannack : exact;
      Jayton[0].Jigger : exact;
   }

   actions {
      Dilia;
      Kapowsin;
   }
   default_action : Kapowsin;

   size : Joslin;
}

table Metzger {
   reads {
      Jayton[0].Jigger : exact;
   }

   actions {
      Kamas;
   }
   default_action : Kamas(0, 1, 2, 3, 4);

   size : Willette;
}

control Mantee {
   apply( Colstrip ) {
         Carroll {
            apply( Brinson );
            apply( Flomot );
         }
         Whatley {
            if ( Brodnax.Ruffin == 1 ) {
               apply( Filley );
            }
            if ( valid( Jayton[ 0 ] ) ) {

               apply( Hilburn ) {
                  Kapowsin {

                     apply( Metzger );
                  }
               }
            } else {

               apply( Elburn );
            }
         }
   }
}





#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Seagrove {
    width  : 1;
    static : Harpster;
    instance_count : 262144;
}

register Lackey {
    width  : 1;
    static : Estrella;
    instance_count : 262144;
}

blackbox stateful_alu Cricket {
    reg : Seagrove;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Boyle.Rehobeth;
}

blackbox stateful_alu Jerico {
    reg : Lackey;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Boyle.Maida;
}

field_list McFaddin {
    Brodnax.Columbia;
    Jayton[0].Jigger;
}

field_list_calculation Caputa {
    input { McFaddin; }
    algorithm: identity;
    output_width: 18;
}

action Clementon() {
    Cricket.execute_stateful_alu_from_hash(Caputa);
}

action Telephone() {
    Jerico.execute_stateful_alu_from_hash(Caputa);
}

table Harpster {
    actions {
      Clementon;
    }
    default_action : Clementon;
    size : 1;
}

table Estrella {
    actions {
      Telephone;
    }
    default_action : Telephone;
    size : 1;
}
#endif

action Moosic(Ossineke) {
    modify_field(Boyle.Maida, Ossineke);
}

@pragma  use_hash_action 0
table Hillister {
    reads {
       Brodnax.Columbia : exact;
    }
    actions {
      Moosic;
    }
    size : 64;
}

action Advance() {
   modify_field( Algoa.Neches, Brodnax.Natalbany );
   modify_field( Algoa.Arvada, 0 );
}

table BigPiney {
   actions {
      Advance;
   }
   size : 1;
}

action Ackerman() {
   modify_field( Algoa.Neches, Jayton[0].Jigger );
   modify_field( Algoa.Arvada, 1 );
}

table Whitewood {
   actions {
      Ackerman;
   }
   size : 1;
}

control Alakanuk {
   if ( valid( Jayton[ 0 ] ) ) {
      apply( Whitewood );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Brodnax.Montbrook == 1 ) {
         apply( Harpster );
         apply( Estrella );
      }
#endif
   } else {
      apply( BigPiney );
      if( Brodnax.Montbrook == 1 ) {
         apply( Hillister );
      }
   }
}




#define Wallace     256

field_list Kentwood {
   Twain.SanJuan;
   Twain.Weatherly;
   Twain.Gordon;
   Twain.Topton;
   Twain.Lilydale;
}

field_list Corry {
   Switzer.Finney;
   Switzer.Alamota;
   Switzer.Tunica;
}

field_list Rankin {
   Baidland.Noelke;
   Baidland.Kipahulu;
   Baidland.Lacona;
   Baidland.Belgrade;
}





field_list_calculation Idria {
    input {
        Kentwood;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation FourTown {
    input {
        Corry;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Destin {
    input {
        Rankin;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action Grasmere() {
    modify_field_with_hash_based_offset(Buckeye.Candle, 0,
                                        Idria, 65536);
}

action Keller() {
    modify_field_with_hash_based_offset(Buckeye.Candle, 0,
                                        FourTown, 65536);
}

action Reagan() {
    modify_field_with_hash_based_offset(Buckeye.Candle, 0,
                                        Destin, 65536);
}

@pragma immediate 0
table Bernard {
   reads {
      Youngwood.valid : ternary;
      Nanson.valid : ternary;
      Fitzhugh.valid : ternary;
      Frewsburg.valid : ternary;
      TroutRun.valid : ternary;
      Lovelady.valid : ternary;
      Otranto.valid : ternary;
      Switzer.valid : ternary;
      Baidland.valid : ternary;
      Twain.valid : ternary;
   }
   actions {
      Grasmere;
      // Keller;  // Hardware cannot write 2 unique 32-bit hash values (they OR together)
      Kapowsin;
   }
   default_action : Kapowsin();
   size: Wallace;
}

control Columbus {
   apply(Bernard);
}



#define Coulee      65536
#define Bosco      512
#define Rosario 512

counter Elihu {
   type : packets_and_bytes;
   direct : Layton;
   min_width: 16;
}

action Colonias() {
   modify_field(Algoa.ShowLow, 1 );
}

table Layton {
   reads {
      Brodnax.Columbia : exact;
      Boyle.Maida : ternary;
      Boyle.Rehobeth : ternary;
      Algoa.Elsey : ternary;
      Algoa.Valmont : ternary;
      Algoa.Weslaco : ternary;
   }

   actions {
      Colonias;
      Kapowsin;
   }
   default_action : Kapowsin;
   size : Bosco;
}

register Floyd {
   width: 1;
   static: Talbotton;
   instance_count: Coulee;
}

#ifdef __TARGET_TOFINO__
blackbox stateful_alu Fowlkes{
    reg: Floyd;
    update_lo_1_value: set_bit;
}
#endif

action Fentress(Abernathy) {
#if defined(BMV2) || defined(BMV2TOFINO)
   register_write(Floyd, Abernathy, 1);
#else
   Fowlkes.execute_stateful_alu();
#endif

}

action Chunchula() {

   modify_field(Algoa.Dushore, 1 );
   modify_field(DonaAna.Rockfield,
                Sublimity);
}

table Talbotton {
   reads {
      Algoa.McCune : exact;
      Algoa.Lignite : exact;
      Algoa.Calabash : exact;
      Algoa.Kasilof : exact;
   }

   actions {
      Fentress;
      Chunchula;
   }
   size : Coulee;
}

action Tolleson() {
   modify_field( Downs.Wickett, 1 );
}

table Tiburon {
   reads {
      Algoa.Allegan : ternary;
      Algoa.Lasara : exact;
      Algoa.Ivanhoe : exact;
   }
   actions {
      Tolleson;
   }
   size: Rosario;
}

control Hawthorne {
   if( Algoa.ShowLow == 0 ) {
      apply( Tiburon );
   }
}

control NewRoads {
   apply( Layton ) {
      Kapowsin {



         if (Brodnax.Litroe == 0 and Algoa.BeeCave == 0) {
            apply( Talbotton );
         }
         apply(Tiburon);
      }
   }
}

field_list Benson {
    DonaAna.Rockfield;
    Algoa.McCune;
    Algoa.Lignite;
    Algoa.Calabash;
    Algoa.Kasilof;
}

action Naalehu() {
   generate_digest(Boonsboro, Benson);
}

table Powhatan {
   actions {
      Naalehu;
   }
   size : 1;
}

control Vieques {
   if (Algoa.Dushore == 1) {
      apply( Powhatan );
   }
}


#define Jefferson 65536
#define Lennep 65536
#define Perryton   16384
#define Attalla         131072
#define Idalia 65536
#define Mathias 1024

@pragma idletime_precision 1
table Mumford {

   reads {
      Downs.Higley : exact;
      ElJebel.Waimalu : lpm;
   }

   actions {
      McCartys;
      Kapowsin;
   }

   default_action : Kapowsin();
   size : Mathias;
   support_timeout : true;
}

action Burgin(Point) {
   modify_field(ElJebel.Chambers, Point);
}

table Nashoba {
   reads {
      Downs.Higley : exact;
      ElJebel.Waimalu : lpm;
   }

   actions {
      Burgin;
   }

   size : Perryton;
}

@pragma atcam_partition_index ElJebel.Chambers
@pragma atcam_number_partitions Perryton
table Leland {
   reads {
      ElJebel.Chambers : exact;



      ElJebel.Waimalu mask 0x000fffff : lpm;
   }
   actions {
      McCartys;
      Kapowsin;
   }
   default_action : Kapowsin();
   size : Attalla;
}

action McCartys( Cornell ) {
   modify_field( Roachdale.Dubuque, 1 );
   modify_field( Collis.Trimble, Cornell );
}

@pragma idletime_precision 1
table RioLajas {
   reads {
      Downs.Higley : exact;
      ElJebel.Waimalu : exact;
   }

   actions {
      McCartys;
      Kapowsin;
   }
   default_action : Kapowsin();
   size : Jefferson;
   support_timeout : true;
}

@pragma idletime_precision 1
table WestPike {
   reads {
      Downs.Higley : exact;
      Blevins.Keener : exact;
   }

   actions {
      McCartys;
      Kapowsin;
   }
   default_action : Kapowsin();
   size : Lennep;
   support_timeout : true;
}

action Hoadly(Piperton, Freeville, Edwards) {
   modify_field(Roachdale.Dresser, Edwards);
   modify_field(Roachdale.Roscommon, Piperton);
   modify_field(Roachdale.Bendavis, Freeville);
   modify_field(Roachdale.Dubuque, 1);
}

table Missoula {
   reads {
      Collis.Trimble : exact;
   }

   actions {
      Hoadly;
   }
   default_action : Hoadly(0, 1, 2);
   size : Idalia;
}

control Reynolds {




   if ( Algoa.ShowLow == 0 and Downs.Wickett == 1 ) {
      if ( ( Downs.NantyGlo == 1 ) and
           ( ( Algoa.Faulkton == Suarez and valid( Switzer ) ) or
             ( Algoa.Faulkton != Suarez and valid( Fitzhugh ) ) ) ) {
         apply( RioLajas ) {
            Kapowsin {
               apply( Nashoba );
               if( ElJebel.Chambers != 0 ) {
                  apply( Leland );
               }
               if (Collis.Trimble == 0 ) {
                  apply( Mumford );
               }
            }
         }
      } else if ( ( Downs.Remsen == 1 ) and
            ( Algoa.Faulkton == Suarez and valid( Baidland ) ) or
             ( Algoa.Faulkton != Suarez and valid( Frewsburg ) ) ) {
         apply( WestPike );
      }
   }
}

control Nuiqsut {
   if( Collis.Trimble != 0 ) {
      apply( Missoula );
   }
}



#define Blackwood     1024
#define Ripley    1024

#define Rossburg
#define Haverford

field_list Giltner {
   Buckeye.Candle;
}

field_list_calculation OreCity {
    input {
        Giltner;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Belview {
    selection_key : OreCity;
    selection_mode : resilient;
}

action Tascosa(Almelund) {
   modify_field(Roachdale.Carnero, Almelund);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Almelund);
}

action_profile FlyingH {
    actions {
        Tascosa;
        Kapowsin;
    }
    size : Ripley;
    dynamic_action_selection : Belview;
}

table Twisp {
   reads {
      Roachdale.Carnero : exact;
   }
   action_profile: FlyingH;
   size : Blackwood;
}

control Neavitt {
   if ((Roachdale.Carnero & 0x2000) == 0x2000) {
      apply(Twisp);
   }
}



#define Thach      65536

action Coleman() {
   modify_field(Roachdale.Roscommon, Algoa.Lasara);
   modify_field(Roachdale.Bendavis, Algoa.Ivanhoe);
   modify_field(Roachdale.RoyalOak, Algoa.McCune);
   modify_field(Roachdale.Blueberry, Algoa.Lignite);
   modify_field(Roachdale.Dresser, Algoa.Calabash);
}

table Traverse {
   actions {
      Coleman;
   }
   default_action : Coleman();
   size : 1;
}

control Kaibab {
   if (Algoa.Calabash!=0) {
      apply( Traverse );
   }
}

action Sigsbee() {
   modify_field(Roachdale.Benkelman, 1);
   modify_field(Roachdale.Bowen, 1);
   modify_field(Roachdale.Leonidas, Roachdale.Dresser);
}

action Norco() {
}



@pragma ways 1
table Gotebo {
   reads {
      Roachdale.Roscommon : exact;
      Roachdale.Bendavis : exact;
   }
   actions {
      Sigsbee;
      Norco;
   }
   default_action : Norco;
   size : 1;
}

action Earlham() {
   modify_field(Roachdale.Lapel, 1);
   modify_field(Roachdale.Guadalupe, 1);
   add(Roachdale.Leonidas, Roachdale.Dresser, Callery);
}

table Karlsruhe {
   actions {
      Earlham;
   }
   default_action : Earlham;
   size : 1;
}

action Larsen() {
   modify_field(Roachdale.Milam, 1);
   modify_field(Roachdale.Leonidas, Roachdale.Dresser);
}

table Sanchez {
   actions {
      Larsen;
   }
   default_action : Larsen();
   size : 1;
}

action ElCentro(Norborne) {
   modify_field(Roachdale.Fergus, 1);
   modify_field(Roachdale.Carnero, Norborne);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Norborne);
}

action Wells(Mizpah) {
   modify_field(Roachdale.Lapel, 1);
   modify_field(Roachdale.Leonidas, Mizpah);
}

action Balfour() {
}

table Blakeman {
   reads {
      Roachdale.Roscommon : exact;
      Roachdale.Bendavis : exact;
      Roachdale.Dresser : exact;
   }

   actions {
      ElCentro;
      Wells;
      Balfour;
   }
   default_action : Balfour();
   size : Thach;
}

control Vantage {
   if (Algoa.ShowLow == 0) {
      apply(Blakeman) {
         Balfour {
            apply(Gotebo) {
               Norco {
                  if ((Roachdale.Roscommon & 0x010000) == 0x010000) {
                     apply(Karlsruhe);
                  } else {
                     apply(Sanchez);
                  }
               }
            }
         }
      }
   }
}


action Bowlus() {
   modify_field(Algoa.ShowLow, 1);
}

table Browning {
   actions {
      Bowlus;
   }
   default_action : Bowlus();
   size : 1;
}

control OakLevel {
   if ((Roachdale.Dubuque==0) and (Algoa.Kasilof==Roachdale.Carnero)) {
      apply(Browning);
   }
}


#ifndef Lantana
#define Lantana

#define Norwood    4096

action Celada( Inola ) {
   modify_field( Roachdale.Pelion, Inola );
}

action Elsmere() {
   modify_field( Roachdale.Pelion, Roachdale.Dresser );
}

table Cacao {
   reads {
      eg_intr_md.egress_port : exact;
      Roachdale.Dresser : exact;
   }

   actions {
      Celada;
      Elsmere;
   }
   default_action : Elsmere;
   size : Norwood;
}

action Luhrig() {
   modify_field( Roachdale.Dresser, eg_intr_md.egress_rid );
}

table Gratiot {
   reads {
      eg_intr_md.egress_rid : exact;
   }

   actions {
      Luhrig;
   }
   size : 65536;
}

control Lamoni {
   if (eg_intr_md.egress_rid != 0) {
      apply(Gratiot);
   }
   apply( Cacao );
}


#endif


#ifndef Suwannee
#define Suwannee

#define Waldo 64
#define Resaca 1
#define Lawai  8
#define BoxElder 512

#define Kinross 0

action Whitman( MiraLoma, Isabela ) {
   modify_field( Roachdale.Shasta, MiraLoma );
   modify_field( Roachdale.Cabot, Isabela );
}


table Ozark {
   reads {
      Roachdale.Alston : exact;
   }

   actions {
      Whitman;
   }
   default_action : Whitman(0, 1);
   size : Lawai;
}

action Kirley() {
   no_op();
}

action Nederland() {
   modify_field( Twain.Lilydale, Jayton[0].Bellmore );
   remove_header( Jayton[0] );
}

table Gowanda {
   actions {
      Nederland;
   }
   default_action : Nederland;
   size : Resaca;
}

action Naguabo() {
   no_op();
}

action Martelle() {
   add_header( Jayton[ 0 ] );
   modify_field( Jayton[0].Jigger, Roachdale.Pelion );
   modify_field( Jayton[0].Bellmore, Twain.Lilydale );
   modify_field( Twain.Lilydale, RichBar );
}



table Chatanika {
   reads {
      Roachdale.Pelion : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Naguabo;
      Martelle;
   }
   default_action : Martelle;
   size : Waldo;
}

action Hopkins() {
   modify_field(Twain.SanJuan, Roachdale.Roscommon);
   modify_field(Twain.Weatherly, Roachdale.Bendavis);
   modify_field(Twain.Gordon, Roachdale.Shasta);
   modify_field(Twain.Topton, Roachdale.Cabot);
}

action Greenland() {
   Hopkins();
   add_to_field(Switzer.Robinette, -1);
}

action Wyatte() {
   Hopkins();
   add_to_field(Baidland.Silesia, -1);
}






table Parkline {
   reads {
      Roachdale.BlueAsh : exact;
      Roachdale.Alston : exact;
      Roachdale.Dubuque : exact;
      Switzer.valid : ternary;
      Baidland.valid : ternary;
   }

   actions {
      Greenland;
      Wyatte;
   }
   size : BoxElder;
}

control Fleetwood {
   apply( Gowanda );
}

control Tecumseh {
   apply( Chatanika );
}

control Hanston {
   apply( Ozark );
   apply( Parkline );
}
#endif



field_list Aredale {
    DonaAna.Rockfield;
    Algoa.Calabash;
    TroutRun.Gordon;
    TroutRun.Topton;
    Switzer.Finney;
}

action Morita() {
   generate_digest(Boonsboro, Aredale);
}

table Vernal {
   actions {
      Morita;
   }

   default_action : Morita;
   size : 1;
}

control Haugen {
   if (Algoa.BeeCave == 1) {
      apply(Vernal);
   }
}

control ingress {
   Caspian();

   Overlea();
   Mantee();
   Alakanuk();

   NewRoads();


   Reynolds();
   Kaibab();
   Nuiqsut();

   Columbus();


   Vantage();

   OakLevel();


   Neavitt();


   Haugen();
   Vieques();


   if( valid( Jayton[0] ) ) {
      Fleetwood();
   }
}

control egress {
   Lamoni();
   Hanston();
   Tecumseh();
}

