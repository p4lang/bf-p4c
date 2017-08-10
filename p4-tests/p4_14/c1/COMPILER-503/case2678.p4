// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 162215







#ifdef __TARGET_BMV2__
#define BMV2
#endif

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>



#ifndef Colburn
#define Colburn

header_type Norbeck {
	fields {
		Abilene : 16;
		Layton : 16;
		Gibbs : 8;
		Snowflake : 8;
		Daphne : 8;
		Valier : 8;
		Findlay : 1;
		Annandale : 1;
		Craigtown : 1;
		Blencoe : 1;
		Bartolo : 1;
		Grubbs : 1;
	}
}

header_type Bechyn {
	fields {
		Abbott : 24;
		Needles : 24;
		Rawlins : 24;
		Kittredge : 24;
		Bradner : 16;
		Eucha : 16;
		Mantee : 16;
		Captiva : 16;
		FortShaw : 16;
		Greenbush : 8;
		Samson : 8;
		Seattle : 1;
		Trenary : 1;
		Metter : 12;
		Mingus : 2;
		Wellton : 1;
		FortGay : 1;
		Burnett : 1;
		Barney : 1;
		Stateline : 1;
		Gannett : 1;
		Montour : 1;
		Punaluu : 1;
		IowaCity : 1;
		Sieper : 1;
		Wellford : 1;
		Yulee : 1;
		Parmerton : 1;
	}
}

header_type Boyle {
	fields {
		Fentress : 24;
		Bajandas : 24;
		Musella : 24;
		Vacherie : 24;
		Skyway : 24;
		McDermott : 24;
		Randall : 24;
		Deerwood : 24;
		Silco : 16;
		Bosco : 16;
		Subiaco : 16;
		Inverness : 16;
		Copley : 12;
		Calverton : 1;
		Boonsboro : 3;
		Tappan : 1;
		Platina : 3;
		Wyandanch : 1;
		Goosport : 1;
		Corinne : 1;
		NewTrier : 1;
		Elloree : 1;
		Sandoval : 8;
		Tarlton : 12;
		Bonsall : 4;
		DeLancey : 6;
		BlackOak : 10;
		Ashburn : 9;
		Waucoma : 1;
		Kipahulu : 1;
	}
}


header_type CapRock {
	fields {
		Rocheport : 8;
		Greenbelt : 1;
		Lajitas : 1;
		Renton : 1;
		Melmore : 1;
		Wabbaseka : 1;
	}
}

header_type Piketon {
	fields {
		Nicodemus : 32;
		Elsmere : 32;
		Coolin : 8;
		Lofgreen : 16;
	}
}

header_type Burmah {
	fields {
		Nelson : 128;
		Hiawassee : 128;
		Dagmar : 20;
		Sonestown : 8;
		Poneto : 11;
		Wharton : 6;
		Fosters : 13;
	}
}

header_type Chaires {
	fields {
		Highcliff : 14;
		Wallace : 1;
		Elmhurst : 12;
		Grandy : 1;
		Blakeman : 1;
		Rocky : 6;
		Ramapo : 2;
		Rockaway : 6;
		ElCentro : 3;
	}
}

header_type Palmdale {
	fields {
		Verndale : 1;
		Ashville : 1;
	}
}

header_type OakLevel {
	fields {
		Pinecreek : 8;
	}
}

header_type Langtry {
	fields {
		Wenham : 16;
		Rillton : 11;
	}
}

header_type Niota {
	fields {
		Wiota : 32;
		Cochise : 32;
		Vananda : 32;
	}
}

header_type Hopedale {
	fields {
		Ivydale : 32;
		Macksburg : 32;
	}
}

header_type Loretto {
	fields {
		Waring : 8;
		Creekside : 4;
		Empire : 15;
		Steger : 1;
		Lawai : 1;
		Greycliff : 1;
		Sawyer : 3;
		CleElum : 1;
		Virgin : 6;
	}
}
#endif



#ifndef Arredondo
#define Arredondo


header_type Heads {
	fields {
		Gastonia : 6;
		Floral : 10;
		Woodward : 4;
		Wadley : 12;
		ElJebel : 12;
		Bruce : 2;
		Kelliher : 2;
		LaConner : 8;
		Madras : 3;
		Weiser : 5;
	}
}



header_type Etter {
	fields {
		Hilltop : 24;
		Govan : 24;
		Tahuya : 24;
		Kennedale : 24;
		Rudolph : 16;
	}
}



header_type Haslet {
	fields {
		BelAir : 3;
		Palmerton : 1;
		Chamois : 12;
		Darien : 16;
	}
}



header_type Trimble {
	fields {
		Woodbury : 4;
		Munich : 4;
		Lansdale : 6;
		Deport : 2;
		Eureka : 16;
		Litroe : 16;
		Neavitt : 3;
		Heavener : 13;
		Elderon : 8;
		Columbia : 8;
		Angeles : 16;
		Kalaloch : 32;
		Tilton : 32;
	}
}

header_type Butler {
	fields {
		Perez : 4;
		Plano : 6;
		Wheaton : 2;
		Keener : 20;
		Stella : 16;
		Gorum : 8;
		Lamine : 8;
		Lefors : 128;
		Ouachita : 128;
	}
}




header_type Hodges {
	fields {
		Cisco : 8;
		Thomas : 8;
		Longhurst : 16;
	}
}

header_type Horsehead {
	fields {
		Clover : 16;
		Holtville : 16;
	}
}

header_type Couchwood {
	fields {
		Winnebago : 32;
		SanJon : 32;
		Susank : 4;
		Dahlgren : 4;
		Shobonier : 8;
		Cimarron : 16;
		Lemoyne : 16;
		LaUnion : 16;
	}
}

header_type DeWitt {
	fields {
		Monteview : 16;
		Marshall : 16;
	}
}



header_type Brighton {
	fields {
		UnionGap : 16;
		Sontag : 16;
		Kennebec : 8;
		Lemhi : 8;
		Terrell : 16;
	}
}

header_type Proctor {
	fields {
		Pekin : 48;
		Berlin : 32;
		Daysville : 48;
		Exton : 32;
	}
}



header_type Willamina {
	fields {
		Courtdale : 1;
		Downs : 1;
		Foristell : 1;
		Ashwood : 1;
		Philippi : 1;
		Judson : 3;
		Ferndale : 5;
		Wakenda : 3;
		Wibaux : 16;
	}
}

header_type Centre {
	fields {
		Hanks : 24;
		CassCity : 8;
	}
}



header_type Ridgetop {
	fields {
		Skene : 8;
		Gibbstown : 24;
		Bagwell : 24;
		Nevis : 8;
	}
}

#endif



#ifndef Hatchel
#define Hatchel

#define DeKalb        0x8100
#define Sprout        0x0800
#define Morita        0x86dd
#define Tolono        0x9100
#define Brumley        0x8847
#define Quebrada         0x0806
#define Olmstead        0x8035
#define Cabot        0x88cc
#define Coffman        0x8809
#define Suwannee      0xBF00

#define LeMars              1
#define Daisytown              2
#define Paxtonia              4
#define Terry               6
#define Sawmills               17
#define Flats                47

#define Armijo         0x501
#define Leola          0x506
#define Catskill          0x511
#define Clintwood          0x52F


#define Newkirk                 4789



#define Darmstadt               0
#define Williams              1
#define Antoine                2



#define Earlimart          0
#define NewRome          4095
#define Cypress  4096
#define Twodot  8191



#define AquaPark                      0
#define Winger                  0
#define Prunedale                 1

header Etter Bavaria;
header Etter Brush;
header Haslet Melrude[ 2 ];



@pragma pa_fragment ingress Scherr.Angeles
@pragma pa_fragment egress Scherr.Angeles
header Trimble Scherr;

@pragma pa_fragment ingress HornLake.Angeles
@pragma pa_fragment egress HornLake.Angeles
header Trimble HornLake;

header Butler Tusayan;
header Butler McCracken;
header Horsehead Wondervu;
header Couchwood Woodridge;

header DeWitt Plato;
header Couchwood Joyce;
header DeWitt Herod;
header Ridgetop Combine;
header Brighton Flynn;
header Willamina Gullett;
header Heads Foster;
header Etter Hayfork;

parser start {
   return select(current(96, 16)) {
      Suwannee : Pilger;
      default : Osterdock;
   }
}

parser Leesport {
   extract( Foster );
   return Osterdock;
}

parser Pilger {
   extract( Hayfork );
   return Leesport;
}

parser Osterdock {
   extract( Bavaria );
   return select( Bavaria.Rudolph ) {
      DeKalb : Allerton;
      Sprout : McDaniels;
      Morita : Aquilla;
      Quebrada  : Elkader;
      default        : ingress;
   }
}

parser Allerton {
   extract( Melrude[0] );
   set_metadata(Mescalero.Bartolo, 1);
   return select( Melrude[0].Darien ) {
      Sprout : McDaniels;
      Morita : Aquilla;
      Quebrada  : Elkader;
      default : ingress;
   }
}

field_list Chugwater {
    Scherr.Woodbury;
    Scherr.Munich;
    Scherr.Lansdale;
    Scherr.Deport;
    Scherr.Eureka;
    Scherr.Litroe;
    Scherr.Neavitt;
    Scherr.Heavener;
    Scherr.Elderon;
    Scherr.Columbia;
    Scherr.Kalaloch;
    Scherr.Tilton;
}

field_list_calculation Duncombe {
    input {
        Chugwater;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field Scherr.Angeles  {
    verify Duncombe;
    update Duncombe;
}

parser McDaniels {
   extract( Scherr );
   set_metadata(Mescalero.Gibbs, Scherr.Columbia);
   set_metadata(Mescalero.Daphne, Scherr.Elderon);
   set_metadata(Mescalero.Abilene, Scherr.Eureka);
   set_metadata(Mescalero.Craigtown, 0);
   set_metadata(Mescalero.Findlay, 1);
   return select(Scherr.Heavener, Scherr.Munich, Scherr.Columbia) {
      Catskill : Joseph;
      Leola : Joice;
      default : ingress;
   }
}

parser Aquilla {
   extract( McCracken );
   set_metadata(Mescalero.Gibbs, McCracken.Gorum);
   set_metadata(Mescalero.Daphne, McCracken.Lamine);
   set_metadata(Mescalero.Abilene, McCracken.Stella);
   set_metadata(Mescalero.Craigtown, 1);
   set_metadata(Mescalero.Findlay, 0);
   return select(McCracken.Gorum) {
      Catskill : Mikkalo;
      Leola : Joice;
      default : ingress;
   }
}

parser Elkader {
   extract( Flynn );
   set_metadata(Mescalero.Grubbs, 1);
   return ingress;
}

parser Joseph {
   extract(Wondervu);
   extract(Plato);
   return select(Wondervu.Holtville) {
      Newkirk : Ekwok;
      default : ingress;
    }
}

parser Mikkalo {
   extract(Wondervu);
   extract(Plato);
   return ingress;
}

parser Joice {
   extract(Wondervu);
   extract(Woodridge);
   return ingress;
}

parser Pardee {
   set_metadata(Netcong.Mingus, Antoine);
   return Korona;
}

parser Glenshaw {
   set_metadata(Netcong.Mingus, Antoine);
   return Victoria;
}

parser Braymer {
   extract(Gullett);
   return select(Gullett.Courtdale, Gullett.Downs, Gullett.Foristell, Gullett.Ashwood, Gullett.Philippi,
             Gullett.Judson, Gullett.Ferndale, Gullett.Wakenda, Gullett.Wibaux) {
      Sprout : Pardee;
      Morita : Glenshaw;
      default : ingress;
   }
}

parser Ekwok {
   extract(Combine);
   set_metadata(Netcong.Mingus, Williams);
   return LaHabra;
}

field_list Ladoga {
    HornLake.Woodbury;
    HornLake.Munich;
    HornLake.Lansdale;
    HornLake.Deport;
    HornLake.Eureka;
    HornLake.Litroe;
    HornLake.Neavitt;
    HornLake.Heavener;
    HornLake.Elderon;
    HornLake.Columbia;
    HornLake.Kalaloch;
    HornLake.Tilton;
}

field_list_calculation Anacortes {
    input {
        Ladoga;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field HornLake.Angeles  {
    verify Anacortes;
    update Anacortes;
}

parser Korona {
   extract( HornLake );
   set_metadata(Mescalero.Snowflake, HornLake.Columbia);
   set_metadata(Mescalero.Valier, HornLake.Elderon);
   set_metadata(Mescalero.Layton, HornLake.Eureka);
   set_metadata(Mescalero.Blencoe, 0);
   set_metadata(Mescalero.Annandale, 1);
   return ingress;
}

parser Victoria {
   extract( Tusayan );
   set_metadata(Mescalero.Snowflake, Tusayan.Gorum);
   set_metadata(Mescalero.Valier, Tusayan.Lamine);
   set_metadata(Mescalero.Layton, Tusayan.Stella);
   set_metadata(Mescalero.Blencoe, 1);
   set_metadata(Mescalero.Annandale, 0);
   return ingress;
}

parser LaHabra {
   extract( Brush );
   return select( Brush.Rudolph ) {
      Sprout: Korona;
      Morita: Victoria;
      default: ingress;
   }
}
#endif

metadata Bechyn Netcong;


@pragma pa_no_init ingress Peebles.Fentress
@pragma pa_no_init ingress Peebles.Bajandas
@pragma pa_no_init ingress Peebles.Musella
@pragma pa_no_init ingress Peebles.Vacherie
@pragma pa_container_size ingress Peebles.Sandoval 8
metadata Boyle Peebles;

metadata Chaires Lowemont;
metadata Norbeck Mescalero;
metadata Piketon Reinbeck;
metadata Burmah Humacao;

@pragma pa_container_size ingress Stout.Ashville 32
@pragma pa_container_size ingress Stout.Verndale 32
metadata Palmdale Stout;
metadata CapRock Chloride;
metadata OakLevel Elkins;
metadata Langtry Gheen;
metadata Hopedale Funston;
metadata Niota Cropper;
metadata Loretto Burrel;













#undef Cowpens
#undef Snohomish
#undef Fillmore
#undef Pojoaque

#undef Broadwell

#undef Bethesda
#undef Pickett
#undef BallClub
#undef Klawock
#undef Owanka

#undef VanZandt
#undef Hiwasse
#undef Winfall

#undef Atlantic
#undef Naalehu
#undef Ihlen
#undef Desdemona
#undef Thawville
#undef Champlin
#undef Lamoni
#undef Noorvik
#undef Grigston
#undef BigBay
#undef Hecker
#undef Jenera
#undef Varna
#undef Hoven
#undef Bridgton
#undef Lecompte
#undef Nuangola
#undef Lonepine
#undef Jenison
#undef Dugger
#undef Jarreau

#undef Tiller
#undef Truro
#undef Gratis
#undef Clarkdale
#undef Stampley
#undef Hoadly
#undef Renfroe
#undef Cortland
#undef Justice
#undef IdaGrove
#undef Oakville
#undef WestEnd
#undef BigFork
#undef Troutman
#undef Dunkerton
#undef Elysburg
#undef Brundage
#undef Philip
#undef Renick
#undef Sunset
#undef Hillside
#undef Hitchland
#undef Dixboro

#undef Fairlea
#undef Advance

#undef Taylors

#undef Blackman
#undef Saltair







#define Broadwell 288


#define PROFILE_DEFAULT
#ifdef PROFILE_DEFAULT


#define Snohomish

#define Cowpens

#define Fillmore

#define Pojoaque



#define Bethesda      65536
#define Pickett      65536
#define BallClub 512
#define Klawock 512
#define Owanka      512


#define VanZandt     1024
#define Hiwasse    1024
#define Winfall     256


#define Atlantic 512
#define Naalehu 65536
#define Ihlen 65536
#define Desdemona 28672
#define Thawville   16384
#define Champlin 8192
#define Lamoni         131072
#define Noorvik 65536
#define Grigston 1024
#define BigBay 2048
#define Hecker 16384
#define Jenera 8192
#define Varna 65536

#define Hoven 0x0000000000000000FFFFFFFFFFFFFFFF


#define Bridgton 0x000fffff
#define Lonepine 2

#define Lecompte 0xFFFFFFFFFFFFFFFF0000000000000000

#define Nuangola 0x000007FFFFFFFFFF0000000000000000
#define Jenison  6
#define Jarreau        2048
#define Dugger       65536


#define Tiller 1024
#define Truro 4096
#define Gratis 4096
#define Clarkdale 4096
#define Stampley 4096
#define Hoadly 1024
#define Renfroe 4096
#define Justice 128
#define IdaGrove 1
#define Oakville  8


#define WestEnd 512
#define Fairlea 512
#define Advance 256


#define BigFork 2
#define Troutman 3
#define Dunkerton 80



#define Elysburg 512
#define Brundage 512
#define Philip 512
#define Renick 512

#define Sunset 2048
#define Hillside 1024

#define Hitchland 1
#define Dixboro 512



#define Taylors 0


#define Blackman    4096
#define Saltair    1024

#endif



#ifndef Horatio
#define Horatio

action Shoshone() {
   no_op();
}

action Wolsey() {
   modify_field(Netcong.Barney, 1 );
   mark_for_drop();
}

action Blitchton() {
   no_op();
}
#endif




#define Attalla         0
#define Onset        1


#define Florida            0
#define Higgins  1
#define Rhinebeck 2


#define Delmar              0
#define Nichols             1
#define Waseca 2


















action Bessie(Montbrook, Charenton, Ackley, Kinsley, Coalgate, Weyauwega,
                 Ririe, Gurdon, Correo) {
    modify_field(Lowemont.Highcliff, Montbrook);
    modify_field(Lowemont.Wallace, Charenton);
    modify_field(Lowemont.Elmhurst, Ackley);
    modify_field(Lowemont.Grandy, Kinsley);
    modify_field(Lowemont.Blakeman, Coalgate);
    modify_field(Lowemont.Rocky, Weyauwega);
    modify_field(Lowemont.Ramapo, Ririe);
    modify_field(Lowemont.ElCentro, Gurdon);
    modify_field(Lowemont.Rockaway, Correo);
}

@pragma command_line --no-dead-code-elimination
table Alexis {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Bessie;
    }
    size : Broadwell;
}

control Grays {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Alexis);
    }
}





action Biggers(Cement) {
   modify_field( Peebles.Tappan, 1 );
   modify_field( Peebles.Sandoval, Cement);
   modify_field( Netcong.Sieper, 1 );
}

action RoseBud() {
   modify_field( Netcong.Montour, 1 );
   modify_field( Netcong.Yulee, 1 );
}

action Lovilia() {
   modify_field( Netcong.Sieper, 1 );
}

action Stuttgart() {
   modify_field( Netcong.Wellford, 1 );
}

action Kranzburg() {
   modify_field( Netcong.Yulee, 1 );
}

counter Ardsley {
   type : packets_and_bytes;
   direct : Bunker;
   min_width: 16;
}

table Bunker {
   reads {
      Lowemont.Rocky : exact;
      Bavaria.Hilltop : ternary;
      Bavaria.Govan : ternary;
   }

   actions {
      Biggers;
      RoseBud;
      Lovilia;
      Stuttgart;
      Kranzburg;
   }
   size : BallClub;
}

action Addison() {
   modify_field( Netcong.Punaluu, 1 );
}


table Bucktown {
   reads {
      Bavaria.Tahuya : ternary;
      Bavaria.Kennedale : ternary;
   }

   actions {
      Addison;
   }
   size : Klawock;
}


control Terral {
   apply( Bunker );
   apply( Bucktown );
}




action Sidon() {
   modify_field( Reinbeck.Nicodemus, HornLake.Kalaloch );
   modify_field( Reinbeck.Elsmere, HornLake.Tilton );
   modify_field( Reinbeck.Coolin, HornLake.Lansdale );
   modify_field( Humacao.Nelson, Tusayan.Lefors );
   modify_field( Humacao.Hiawassee, Tusayan.Ouachita );
   modify_field( Humacao.Dagmar, Tusayan.Keener );
   modify_field( Humacao.Wharton, Tusayan.Plano );
   modify_field( Netcong.Abbott, Brush.Hilltop );
   modify_field( Netcong.Needles, Brush.Govan );
   modify_field( Netcong.Rawlins, Brush.Tahuya );
   modify_field( Netcong.Kittredge, Brush.Kennedale );
   modify_field( Netcong.Bradner, Brush.Rudolph );
   modify_field( Netcong.FortShaw, Mescalero.Layton );
   modify_field( Netcong.Greenbush, Mescalero.Snowflake );
   modify_field( Netcong.Samson, Mescalero.Valier );
   modify_field( Netcong.Trenary, Mescalero.Annandale );
   modify_field( Netcong.Seattle, Mescalero.Blencoe );
   modify_field( Netcong.Parmerton, 0 );
   modify_field( Peebles.Platina, Nichols );



   modify_field( Lowemont.Ramapo, 1 );
   modify_field( Lowemont.ElCentro, 0 );
   modify_field( Lowemont.Rockaway, 0 );
   modify_field( Burrel.Lawai, 1 );
   modify_field( Burrel.Greycliff, 1 );
}

action Embarrass() {
   modify_field( Netcong.Mingus, Darmstadt );
   modify_field( Reinbeck.Nicodemus, Scherr.Kalaloch );
   modify_field( Reinbeck.Elsmere, Scherr.Tilton );
   modify_field( Reinbeck.Coolin, Scherr.Lansdale );
   modify_field( Humacao.Nelson, McCracken.Lefors );
   modify_field( Humacao.Hiawassee, McCracken.Ouachita );
   modify_field( Humacao.Dagmar, McCracken.Keener );
   modify_field( Humacao.Wharton, McCracken.Plano );
   modify_field( Netcong.Abbott, Bavaria.Hilltop );
   modify_field( Netcong.Needles, Bavaria.Govan );
   modify_field( Netcong.Rawlins, Bavaria.Tahuya );
   modify_field( Netcong.Kittredge, Bavaria.Kennedale );
   modify_field( Netcong.Bradner, Bavaria.Rudolph );
   modify_field( Netcong.FortShaw, Mescalero.Abilene );
   modify_field( Netcong.Greenbush, Mescalero.Gibbs );
   modify_field( Netcong.Samson, Mescalero.Daphne );
   modify_field( Netcong.Trenary, Mescalero.Findlay );
   modify_field( Netcong.Seattle, Mescalero.Craigtown );
   modify_field( Burrel.CleElum, Melrude[0].Palmerton );
   modify_field( Netcong.Parmerton, Mescalero.Bartolo );
}

table Ortley {
   reads {
      Bavaria.Hilltop : exact;
      Bavaria.Govan : exact;
      Scherr.Tilton : exact;
      Netcong.Mingus : exact;
   }

   actions {
      Sidon;
      Embarrass;
   }

   default_action : Embarrass();
   size : Tiller;
}


action PortVue() {
   modify_field( Netcong.Eucha, Lowemont.Elmhurst );
   modify_field( Netcong.Mantee, Lowemont.Highcliff);
}

action Deemer( Owyhee ) {
   modify_field( Netcong.Eucha, Owyhee );
   modify_field( Netcong.Mantee, Lowemont.Highcliff);
}

action Flourtown() {
   modify_field( Netcong.Eucha, Melrude[0].Chamois );
   modify_field( Netcong.Mantee, Lowemont.Highcliff);
}

table Emida {
   reads {
      Lowemont.Highcliff : ternary;
      Melrude[0] : valid;
      Melrude[0].Chamois : ternary;
   }

   actions {
      PortVue;
      Deemer;
      Flourtown;
   }
   size : Clarkdale;
}

action Mackville( Kalida ) {
   modify_field( Netcong.Mantee, Kalida );
}

action Chaffee() {

   modify_field( Netcong.Burnett, 1 );
   modify_field( Elkins.Pinecreek,
                 Prunedale );
}

table MillHall {
   reads {
      Scherr.Kalaloch : exact;
   }

   actions {
      Mackville;
      Chaffee;
   }
   default_action : Chaffee;
   size : Gratis;
}

action BigPiney( Tomato, Macdona, Trego, Ballville, Westoak,
                        Berenice, Meyers ) {
   modify_field( Netcong.Eucha, Tomato );
   modify_field( Netcong.Captiva, Tomato );
   modify_field( Netcong.Gannett, Meyers );
   Prismatic(Macdona, Trego, Ballville, Westoak,
                        Berenice );
}

action Stockdale() {
   modify_field( Netcong.Stateline, 1 );
}

table Nipton {
   reads {
      Combine.Bagwell : exact;
   }

   actions {
      BigPiney;
      Stockdale;
   }
   size : Truro;
}

action Prismatic(Baroda, Calimesa, Kasilof, RowanBay,
                        Dabney ) {
   modify_field( Chloride.Rocheport, Baroda );
   modify_field( Chloride.Greenbelt, Calimesa );
   modify_field( Chloride.Renton, Kasilof );
   modify_field( Chloride.Lajitas, RowanBay );
   modify_field( Chloride.Melmore, Dabney );
}

action Endicott(Risco, Carver, Merced, Otsego,
                        Staunton ) {
   modify_field( Netcong.Captiva, Lowemont.Elmhurst );
   modify_field( Netcong.Gannett, 1 );
   Prismatic(Risco, Carver, Merced, Otsego,
                        Staunton );
}

action Brownson(Isabela, Ledoux, Lynch, Moultrie,
                        Newtonia, Molino ) {
   modify_field( Netcong.Captiva, Isabela );
   modify_field( Netcong.Gannett, 1 );
   Prismatic(Ledoux, Lynch, Moultrie, Newtonia,
                        Molino );
}

action Allison(Sugarloaf, Catarina, Stone, Newtok,
                        Eastwood ) {
   modify_field( Netcong.Captiva, Melrude[0].Chamois );
   modify_field( Netcong.Gannett, 1 );
   Prismatic(Sugarloaf, Catarina, Stone, Newtok,
                        Eastwood );
}

table Loris {
   reads {
      Lowemont.Elmhurst : exact;
   }


   actions {
      Shoshone;
      Endicott;
   }

   size : Stampley;
}

@pragma action_default_only Shoshone
table Fowlkes {
   reads {
      Lowemont.Highcliff : exact;
      Melrude[0].Chamois : exact;
   }

   actions {
      Brownson;
      Shoshone;
   }

   size : Hoadly;
}

table Loveland {
   reads {
      Melrude[0].Chamois : exact;
   }


   actions {
      Shoshone;
      Allison;
   }

   size : Renfroe;
}

control Neuse {
   apply( Ortley ) {
         Sidon {
            apply( MillHall );
            apply( Nipton );
         }
         Embarrass {
            if ( not valid(Foster) and Lowemont.Grandy == 1 ) {
               apply( Emida );
            }
            if ( valid( Melrude[ 0 ] ) ) {

               apply( Fowlkes ) {
                  Shoshone {

                     apply( Loveland );
                  }
               }
            } else {

               apply( Loris );
            }
         }
   }
}






#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
register Elmdale {
    width  : 1;
    static : Kamas;
    instance_count : 262144;
}

register Ilwaco {
    width  : 1;
    static : Rains;
    instance_count : 262144;
}

blackbox stateful_alu Vinita {
    reg : Elmdale;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst   : Stout.Verndale;
}

blackbox stateful_alu Gerlach {
    reg : Ilwaco;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst   : Stout.Ashville;
}

field_list Moneta {
    Lowemont.Rocky;
    Melrude[0].Chamois;
}

field_list_calculation Agawam {
    input { Moneta; }
    algorithm: identity;
    output_width: 18;
}

action Leeville() {
    Vinita.execute_stateful_alu_from_hash(Agawam);
}

action Kaweah() {
    Gerlach.execute_stateful_alu_from_hash(Agawam);
}

table Kamas {
    actions {
      Leeville;
    }
    default_action : Leeville;
    size : 1;
}

table Rains {
    actions {
      Kaweah;
    }
    default_action : Kaweah;
    size : 1;
}
#endif

action PikeView(Saluda) {
    modify_field(Stout.Ashville, Saluda);
}

@pragma  use_hash_action 0
table Rayville {
    reads {
       Lowemont.Rocky : exact;
    }
    actions {
      PikeView;
    }
    size : 64;
}

action Lowland() {
   modify_field( Netcong.Metter, Lowemont.Elmhurst );
   modify_field( Netcong.Wellton, 0 );
}

table Johnstown {
   actions {
      Lowland;
   }
   size : 1;
}

action Omemee() {
   modify_field( Netcong.Metter, Melrude[0].Chamois );
   modify_field( Netcong.Wellton, 1 );
}

table StarLake {
   actions {
      Omemee;
   }
   size : 1;
}

control Devore {
   if ( valid( Melrude[ 0 ] ) ) {
      apply( StarLake );
#if defined(__TARGET_TOFINO__) && !defined(BMV2TOFINO)
      if( Lowemont.Blakeman == 1 ) {
         apply( Kamas );
         apply( Rains );
      }
#endif
   } else {
      apply( Johnstown );
      if( Lowemont.Blakeman == 1 ) {
         apply( Rayville );
      }
   }
}




field_list Baskin {
   Bavaria.Hilltop;
   Bavaria.Govan;
   Bavaria.Tahuya;
   Bavaria.Kennedale;
   Bavaria.Rudolph;
}

field_list Thurston {

   Scherr.Columbia;
   Scherr.Kalaloch;
   Scherr.Tilton;
}

field_list Ethete {
   McCracken.Lefors;
   McCracken.Ouachita;
   McCracken.Keener;
   McCracken.Gorum;
}

field_list Bulger {
   Scherr.Kalaloch;
   Scherr.Tilton;
   Wondervu.Clover;
   Wondervu.Holtville;
}





field_list_calculation Carlsbad {
    input {
        Baskin;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Ackerly {
    input {
        Thurston;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Ekron {
    input {
        Ethete;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}

field_list_calculation Raven {
    input {
        Bulger;
    }
#if defined(BMV2) || defined(BMV2TOFINO)
    algorithm : crc32_custom;
#else
    algorithm : crc32;
#endif
    output_width : 32;
}



action PortWing() {
    modify_field_with_hash_based_offset(Cropper.Wiota, 0,
                                        Carlsbad, 4294967296);
}

action Exira() {
    modify_field_with_hash_based_offset(Cropper.Cochise, 0,
                                        Ackerly, 4294967296);
}

action Wegdahl() {
    modify_field_with_hash_based_offset(Cropper.Cochise, 0,
                                        Ekron, 4294967296);
}

action Wyanet() {
    modify_field_with_hash_based_offset(Cropper.Vananda, 0,
                                        Raven, 4294967296);
}

table Reagan {
   actions {
      PortWing;
   }
   size: 1;
}

control Willshire {
   apply(Reagan);
}

table Newberg {
   actions {
      Exira;
   }
   size: 1;
}

table Bulverde {
   actions {
      Wegdahl;
   }
   size: 1;
}

control Kapalua {
   if ( valid( Scherr ) ) {
      apply(Newberg);
   } else {
      if ( valid( McCracken ) ) {
         apply(Bulverde);
      }
   }
}

table Caspiana {
   actions {
      Wyanet;
   }
   size: 1;
}

control Abernant {
   if ( valid( Plato ) ) {
      apply(Caspiana);
   }
}



action Bootjack() {
    modify_field(Funston.Ivydale, Cropper.Wiota);
}

action Nahunta() {
    modify_field(Funston.Ivydale, Cropper.Cochise);
}

action Henry() {
    modify_field(Funston.Ivydale, Cropper.Vananda);
}

@pragma action_default_only Shoshone
@pragma immediate 0
table Gillespie {
   reads {
      Joyce.valid : ternary;
      Herod.valid : ternary;
      HornLake.valid : ternary;
      Tusayan.valid : ternary;
      Brush.valid : ternary;
      Woodridge.valid : ternary;
      Plato.valid : ternary;
      Scherr.valid : ternary;
      McCracken.valid : ternary;
      Bavaria.valid : ternary;
   }
   actions {
      Bootjack;
      Nahunta;
      Henry;
      Shoshone;
   }
   size: Winfall;
}

action Benson() {
    modify_field(Funston.Macksburg, Cropper.Vananda);
}

@pragma immediate 0
table Grassy {
   reads {
      Joyce.valid : ternary;
      Herod.valid : ternary;
      Woodridge.valid : ternary;
      Plato.valid : ternary;
   }
   actions {
      Benson;
      Shoshone;
   }
   size: Jenison;
}

control Harvest {
   apply(Grassy);
   apply(Gillespie);
}



counter Mekoryuk {
   type : packets_and_bytes;
   direct : Johnsburg;
   min_width: 16;
}

table Johnsburg {
   reads {
      Lowemont.Rocky : exact;
      Stout.Ashville : ternary;
      Stout.Verndale : ternary;
      Netcong.Stateline : ternary;
      Netcong.Punaluu : ternary;
      Netcong.Montour : ternary;
   }

   actions {
      Wolsey;
      Shoshone;
   }
   default_action : Shoshone();
   size : Owanka;
}

action LunaPier() {

   modify_field(Netcong.FortGay, 1 );
   modify_field(Elkins.Pinecreek,
                Winger);
}







table Caulfield {
   reads {
      Netcong.Rawlins : exact;
      Netcong.Kittredge : exact;
      Netcong.Eucha : exact;
      Netcong.Mantee : exact;
   }

   actions {
      Blitchton;
      LunaPier;
   }
   default_action : LunaPier();
   size : Pickett;
   support_timeout : true;
}

action Newsoms() {
   modify_field( Chloride.Wabbaseka, 1 );
}

table Halley {
   reads {
      Netcong.Captiva : ternary;
      Netcong.Abbott : exact;
      Netcong.Needles : exact;
   }
   actions {
      Newsoms;
   }
   size: Atlantic;
}

control Urbanette {
   apply( Johnsburg ) {
      Shoshone {



         if (Lowemont.Wallace == 0 and Netcong.Burnett == 0) {
            apply( Caulfield );
         }
         apply(Halley);
      }
   }
}

field_list Henning {
    Elkins.Pinecreek;
    Netcong.Rawlins;
    Netcong.Kittredge;
    Netcong.Eucha;
    Netcong.Mantee;
}

action Hayfield() {
   generate_digest(AquaPark, Henning);
}

table Comobabi {
   actions {
      Hayfield;
   }
   size : 1;
}

control Antelope {
   if (Netcong.FortGay == 1) {
      apply( Comobabi );
   }
}



action Hanford( Gerty, Davisboro ) {
   modify_field( Humacao.Fosters, Gerty );
   modify_field( Gheen.Wenham, Davisboro );
}

@pragma action_default_only Maljamar
table Rexville {
   reads {
      Chloride.Rocheport : exact;
      Humacao.Hiawassee mask Lecompte : lpm;
   }
   actions {
      Hanford;
      Maljamar;
   }
   size : Jenera;
}

@pragma atcam_partition_index Humacao.Fosters
@pragma atcam_number_partitions Jenera
table Jerico {
   reads {
      Humacao.Fosters : exact;
      Humacao.Hiawassee mask Nuangola : lpm;
   }

   actions {
      Weehawken;
      Lisle;
      Shoshone;
   }
   default_action : Shoshone();
   size : Varna;
}

action Copemish( Nederland, Valentine ) {
   modify_field( Humacao.Poneto, Nederland );
   modify_field( Gheen.Wenham, Valentine );
}

@pragma action_default_only Shoshone
table Cross {


   reads {
      Chloride.Rocheport : exact;
      Humacao.Hiawassee : lpm;
   }

   actions {
      Copemish;
      Shoshone;
   }

   size : BigBay;
}

@pragma atcam_partition_index Humacao.Poneto
@pragma atcam_number_partitions BigBay
table Leadpoint {
   reads {
      Humacao.Poneto : exact;


      Humacao.Hiawassee mask Hoven : lpm;
   }
   actions {
      Weehawken;
      Lisle;
      Shoshone;
   }

   default_action : Shoshone();
   size : Hecker;
}

@pragma action_default_only Maljamar
@pragma idletime_precision 1
table Idylside {

   reads {
      Chloride.Rocheport : exact;
      Reinbeck.Elsmere : lpm;
   }

   actions {
      Weehawken;
      Lisle;
      Maljamar;
   }

   size : Grigston;
   support_timeout : true;
}

action Brohard( Boise, Hammocks ) {
   modify_field( Reinbeck.Lofgreen, Boise );
   modify_field( Gheen.Wenham, Hammocks );
}

@pragma action_default_only Shoshone
#ifdef PROFILE_DEFAULT
@pragma stage 2 Champlin
@pragma stage 3
#endif
table Jacobs {
   reads {
      Chloride.Rocheport : exact;
      Reinbeck.Elsmere : lpm;
   }

   actions {
      Brohard;
      Shoshone;
   }

   size : Thawville;
}

@pragma ways Lonepine
@pragma atcam_partition_index Reinbeck.Lofgreen
@pragma atcam_number_partitions Thawville
table BigWater {
   reads {
      Reinbeck.Lofgreen : exact;
      Reinbeck.Elsmere mask Bridgton : lpm;
   }
   actions {
      Weehawken;
      Lisle;
      Shoshone;
   }
   default_action : Shoshone();
   size : Lamoni;
}

action Weehawken( Corvallis ) {
   modify_field( Gheen.Wenham, Corvallis );
}

@pragma idletime_precision 1
table Francisco {
   reads {
      Chloride.Rocheport : exact;
      Reinbeck.Elsmere : exact;
   }

   actions {
      Weehawken;
      Lisle;
      Shoshone;
   }
   default_action : Shoshone();
   size : Naalehu;
   support_timeout : true;
}

@pragma idletime_precision 1
#ifdef PROFILE_DEFAULT
@pragma stage 2 Desdemona
@pragma stage 3
#endif
table Boxelder {
   reads {
      Chloride.Rocheport : exact;
      Humacao.Hiawassee : exact;
   }

   actions {
      Weehawken;
      Lisle;
      Shoshone;
   }
   default_action : Shoshone();
   size : Ihlen;
   support_timeout : true;
}

action Lewiston(Helton, Bixby, Rockleigh) {
   modify_field(Peebles.Silco, Rockleigh);
   modify_field(Peebles.Fentress, Helton);
   modify_field(Peebles.Bajandas, Bixby);
   modify_field(Peebles.Waucoma, 1);

   modify_field(ig_intr_md_for_tm.rid, 0xffff);
}

action Greer() {
   Wolsey();
}

action Camargo(Oronogo) {
   modify_field(Peebles.Tappan, 1);
   modify_field(Peebles.Sandoval, Oronogo);
}

action Maljamar(McDonough) {
#ifdef VAG_FIX
   bit_or(Peebles.Sandoval, Peebles.Sandoval, 0);
#endif
   Weehawken(McDonough);
}

table Tryon {
   reads {
      Gheen.Wenham : exact;
   }

   actions {
      Lewiston;
      Greer;
      Camargo;
   }
   size : Noorvik;
}

action Waubun( Lorane ) {
   Weehawken( Lorane );
}

table LaSal {
   actions {
      Waubun;
   }
   default_action: Waubun(2);
   size : 1;
}

control Forman {
   if ( Netcong.Barney == 0 and Chloride.Wabbaseka == 1 ) {
      if ( ( Chloride.Greenbelt == 1 ) and ( Netcong.Trenary == 1 ) ) {
         apply( Francisco ) {
            Shoshone {
               apply( Jacobs ) {
                  Brohard {
                     apply( BigWater );
                  }
                  Shoshone {
                     apply( Idylside );
                  }
               }
            }
         }
      } else if ( ( Chloride.Renton == 1 ) and ( Netcong.Seattle == 1 ) ) {
         apply( Boxelder ) {
            Shoshone {
               apply( Cross ) {
                  Copemish {
                     apply( Leadpoint );
                  }
                  Shoshone {

                     apply( Rexville ) {
                        Hanford {
                           apply( Jerico );
                        }
                     }
                  }
               }
            }
         }
      } else if( Netcong.Gannett == 1 ) {
         apply( LaSal );
      }
   }
}

control Osakis {
   if( Gheen.Wenham != 0 ) {
      apply( Tryon );
   }
}

action Lisle( Talbert ) {
   modify_field( Gheen.Rillton, Talbert );
}

field_list Anthon {
   Funston.Macksburg;
}

field_list_calculation Scissors {
    input {
        Anthon;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Verdigris {
   selection_key : Scissors;
   selection_mode : resilient;
}

action_profile Kinde {
   actions {
      Weehawken;
   }
   size : Dugger;
   dynamic_action_selection : Verdigris;
}

table Glenolden {
   reads {
      Gheen.Rillton : exact;
   }
   action_profile : Kinde;
   size : Jarreau;
}

control Jigger {
   if ( Gheen.Rillton != 0 ) {
      apply( Glenolden );
   }
}



field_list Ericsburg {
   Funston.Ivydale;
}

field_list_calculation Arvana {
    input {
        Ericsburg;
    }
    algorithm : identity;
    output_width : 51;
}

action_selector Tamms {
    selection_key : Arvana;
    selection_mode : resilient;
}

action Cutler(Hollymead) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Hollymead);
}

action_profile Sedan {
    actions {
        Cutler;
        Shoshone;
    }
    size : Hiwasse;
    dynamic_action_selection : Tamms;
}

table Garibaldi {
   reads {
      Peebles.Subiaco : exact;
   }
   action_profile: Sedan;
   size : VanZandt;
}

control Hallwood {
   if ((Peebles.Subiaco & 0x2000) == 0x2000) {
      apply(Garibaldi);
   }
}



action Glenside() {
   modify_field(Peebles.Fentress, Netcong.Abbott);
   modify_field(Peebles.Bajandas, Netcong.Needles);
   modify_field(Peebles.Musella, Netcong.Rawlins);
   modify_field(Peebles.Vacherie, Netcong.Kittredge);
   modify_field(Peebles.Silco, Netcong.Eucha);
}

table Gandy {
   actions {
      Glenside;
   }
   default_action : Glenside();
   size : 1;
}

control Nunnelly {
   apply( Gandy );
}

action Hermiston() {
   modify_field(Peebles.Wyandanch, 1);

   bit_or(ig_intr_md_for_tm.copy_to_cpu, Netcong.Gannett, Mescalero.Grubbs);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Peebles.Silco);
}

action Dougherty() {
}



@pragma ways 1
table Breda {
   reads {
      Peebles.Fentress : exact;
      Peebles.Bajandas : exact;
   }
   actions {
      Hermiston;
      Dougherty;
   }
   default_action : Dougherty;
   size : 1;
}

action August() {
   modify_field(Peebles.Goosport, 1);
   modify_field(Peebles.Elloree, 1);
   add(ig_intr_md_for_tm.mcast_grp_a, Peebles.Silco, Cypress);
}

table Hickox {
   actions {
      August;
   }
   default_action : August;
   size : 1;
}

action Stennett() {
   modify_field(Peebles.NewTrier, 1);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Peebles.Silco);
}

table Bieber {
   actions {
      Stennett;
   }
   default_action : Stennett();
   size : 1;
}

action Powelton(Tillatoba) {
   modify_field(Peebles.Corinne, 1);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Tillatoba);
   modify_field(Peebles.Subiaco, Tillatoba);
}

action Dixon(Barnsdall) {
   modify_field(Peebles.Goosport, 1);
   modify_field(Peebles.Inverness, Barnsdall);
}

action LeSueur() {
}

table Ionia {
   reads {
      Peebles.Fentress : exact;
      Peebles.Bajandas : exact;
      Peebles.Silco : exact;
   }

   actions {
      Powelton;
      Dixon;
      LeSueur;
   }
   default_action : LeSueur();
   size : Bethesda;
}

control Daguao {
   if (Netcong.Barney == 0 and not valid(Foster) ) {
      apply(Ionia) {
         LeSueur {
            apply(Breda) {
               Dougherty {
                  if ((Peebles.Fentress & 0x010000) == 0x010000) {
                     apply(Hickox);
                  } else {
                     apply(Bieber);
                  }
               }
            }
         }
      }
   }
}

action Guaynabo() {
   modify_field(Netcong.IowaCity, 1);
   Wolsey();
}

table Ulysses {
   actions {
      Guaynabo;
   }
   default_action : Guaynabo;
   size : 1;
}

control Juneau {
   if (Netcong.Barney == 0) {
      if ((Peebles.Waucoma==0) and (Netcong.Sieper==0) and (Netcong.Wellford==0) and (Netcong.Mantee==Peebles.Subiaco)) {
         apply(Ulysses);
      } else {
         Hallwood();
      }
   }
}

action Zemple(Coamo) {
    modify_field(ig_intr_md_for_tm.level2_exclusion_id, Coamo);
}

table Boquillas {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Zemple;
    }
    size : 512;
}

control Schroeder {
   if( ig_intr_md_for_tm.mcast_grp_a != 0 ) {
      apply(Boquillas);
   }
}



action Hanover( Clarendon ) {
   modify_field( Peebles.Copley, Clarendon );
}

action Umpire() {
   modify_field( Peebles.Copley, Peebles.Silco );
}

table Claypool {
   reads {
      eg_intr_md.egress_port : exact;
      Peebles.Silco : exact;
   }

   actions {
      Hanover;
      Umpire;
   }
   default_action : Umpire;
   size : Blackman;
}

control Sonora {
   apply( Claypool );
}



action Poynette( Bondad, Pearl ) {
   modify_field( Peebles.Skyway, Bondad );
   modify_field( Peebles.McDermott, Pearl );
}

table Alstown {
   reads {
      Peebles.Boonsboro : exact;
   }

   actions {
      Poynette;
   }
   size : Oakville;
}

action Guion() {
   modify_field( Peebles.Kipahulu, 1 );
   modify_field( Peebles.Boonsboro, Rhinebeck );
}

action Montross() {
   modify_field( Peebles.Kipahulu, 1 );
   modify_field( Peebles.Boonsboro, Higgins );
}

table Earlham {
   reads {
      Peebles.Calverton : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Guion;
      Montross;
   }
   default_action : Shoshone();
   size : 16;
}

action Glynn(Lublin, Marcus, Hargis, Halaula) {
   modify_field( Peebles.DeLancey, Lublin );
   modify_field( Peebles.BlackOak, Marcus );
   modify_field( Peebles.Bonsall, Hargis );
   modify_field( Peebles.Tarlton, Halaula );
}

table Roggen {
   reads {
        Peebles.Ashburn : exact;
   }
   actions {
      Glynn;
   }
   size : Advance;
}

action Allegan() {
   no_op();
}

action Otranto() {
   modify_field( Bavaria.Rudolph, Melrude[0].Darien );
   remove_header( Melrude[0] );
}

table Gonzales {
   actions {
      Otranto;
   }
   default_action : Otranto;
   size : IdaGrove;
}

action Topawa() {
   no_op();
}

action Remsen() {
   add_header( Melrude[ 0 ] );
   modify_field( Melrude[0].Chamois, Peebles.Copley );
   modify_field( Melrude[0].Darien, Bavaria.Rudolph );
   modify_field( Melrude[0].BelAir, Burrel.Sawyer );
   modify_field( Melrude[0].Palmerton, Burrel.CleElum );
   modify_field( Bavaria.Rudolph, DeKalb );
}



table Eldora {
   reads {
      Peebles.Copley : exact;
      eg_intr_md.egress_port : exact;
   }

   actions {
      Topawa;
      Remsen;
   }
   default_action : Remsen;
   size : Justice;
}

action Sutter() {
   modify_field(Bavaria.Hilltop, Peebles.Fentress);
   modify_field(Bavaria.Govan, Peebles.Bajandas);
   modify_field(Bavaria.Tahuya, Peebles.Skyway);
   modify_field(Bavaria.Kennedale, Peebles.McDermott);
}

action Chaumont() {
   Sutter();
   add_to_field(Scherr.Elderon, -1);
   modify_field(Scherr.Lansdale, Burrel.Virgin);
}

action Campo() {
   Sutter();
   add_to_field(McCracken.Lamine, -1);
   modify_field(McCracken.Plano, Burrel.Virgin);
}

action Locke() {
   modify_field(Scherr.Lansdale, Burrel.Virgin);
}

action Claunch() {
   modify_field(McCracken.Plano, Burrel.Virgin);
}

action Stilson() {
   Remsen();
}

action Enderlin( LaVale, SweetAir, Arbyrd, Suntrana ) {
   add_header( Hayfork );
   modify_field( Hayfork.Hilltop, LaVale );
   modify_field( Hayfork.Govan, SweetAir );
   modify_field( Hayfork.Tahuya, Arbyrd );
   modify_field( Hayfork.Kennedale, Suntrana );
   modify_field( Hayfork.Rudolph, Suwannee );

   add_header( Foster );
   modify_field( Foster.Gastonia, Peebles.DeLancey );
   modify_field( Foster.Floral, Peebles.BlackOak );
   modify_field( Foster.Woodward, Peebles.Bonsall );
   modify_field( Foster.Wadley, Peebles.Tarlton );
   modify_field( Foster.LaConner, Peebles.Sandoval );
}

action Altadena() {
   remove_header( Combine );
   remove_header( Plato );
   remove_header( Wondervu );
   copy_header( Bavaria, Brush );
   remove_header( Brush );
   remove_header( Scherr );
}

action Almota() {
   remove_header( Hayfork );
   remove_header( Foster );
}

action Tekonsha() {
   Altadena();
   modify_field(HornLake.Lansdale, Burrel.Virgin);
}

action Roxboro() {
   Altadena();
   modify_field(Tusayan.Plano, Burrel.Virgin);
}

table LaMonte {
   reads {
      Peebles.Platina : exact;
      Peebles.Boonsboro : exact;
      Peebles.Waucoma : exact;
      Scherr.valid : ternary;
      McCracken.valid : ternary;
      HornLake.valid : ternary;
      Tusayan.valid : ternary;
   }

   actions {
      Chaumont;
      Campo;
      Locke;
      Claunch;
      Stilson;
      Enderlin;
      Almota;
      Altadena;
      Tekonsha;
      Roxboro;
   }
   size : WestEnd;
}

control Selby {
   apply( Gonzales );
}

control Nickerson {
   apply( Eldora );
}

control Garlin {
   apply( Earlham ) {
      Shoshone {
         apply( Alstown );
      }
   }
   apply( Roggen );
   apply( LaMonte );
}



field_list Grottoes {
    Elkins.Pinecreek;
    Netcong.Eucha;
    Brush.Tahuya;
    Brush.Kennedale;
    Scherr.Kalaloch;
}

action McIntyre() {
   generate_digest(AquaPark, Grottoes);
}

table Mizpah {
   actions {
      McIntyre;
   }

   default_action : McIntyre;
   size : 1;
}

control GilaBend {
   if (Netcong.Burnett == 1) {
      apply(Mizpah);
   }
}



action Visalia( Tocito ) {
   modify_field( Burrel.Waring, Tocito );
}

action Mattson() {
   modify_field( Burrel.Waring, 0 );
}

table Leicester {
   reads {
     Netcong.Mantee : ternary;
     Netcong.Captiva : ternary;
     Chloride.Wabbaseka : ternary;
   }

   actions {
     Visalia;
     Mattson;
   }

   default_action : Mattson();
   size : Elysburg;
}

action Neosho( Thayne ) {
   modify_field( Burrel.Creekside, Thayne );
   modify_field( Burrel.Empire, 0 );
   modify_field( Burrel.Steger, 0 );
}

action Anthony( Heidrick, Hester ) {
   modify_field( Burrel.Creekside, 0 );
   modify_field( Burrel.Empire, Heidrick );
   modify_field( Burrel.Steger, Hester );
}

action Adair( Lookeba, Amsterdam, Elmwood ) {
   modify_field( Burrel.Creekside, Lookeba );
   modify_field( Burrel.Empire, Amsterdam );
   modify_field( Burrel.Steger, Elmwood );
}

action Odell() {
   modify_field( Burrel.Creekside, 0 );
   modify_field( Burrel.Empire, 0 );
   modify_field( Burrel.Steger, 0 );
}

table Marysvale {
   reads {
     Burrel.Waring : exact;
     Netcong.Abbott : ternary;
     Netcong.Needles : ternary;
     Netcong.Bradner : ternary;
   }

   actions {
     Neosho;
     Anthony;
     Adair;
     Odell;
   }

   default_action : Odell();
   size : Brundage;
}

table Licking {
   reads {
     Burrel.Waring : exact;
     Reinbeck.Elsmere mask 0xffff0000 : ternary;
     Netcong.Greenbush : ternary;
     Netcong.Samson : ternary;
     Burrel.Virgin : ternary;
     Gheen.Wenham : ternary;

   }

   actions {
     Neosho;
     Anthony;
     Adair;
     Odell;
   }

   default_action : Odell();
   size : Philip;
}

table Pathfork {
   reads {
     Burrel.Waring : exact;
     Humacao.Hiawassee mask 0xffff0000 : ternary;
     Netcong.Greenbush : ternary;
     Netcong.Samson : ternary;
     Burrel.Virgin : ternary;
     Gheen.Wenham : ternary;

   }

   actions {
     Neosho;
     Anthony;
     Adair;
     Odell;
   }

   default_action : Odell();
   size : Renick;
}

meter Amasa {
   type : packets;
   static : Rampart;
   instance_count: Sunset;
}

action Rotonda( Rockland ) {
   // Unsupported addressing mode
   //execute_meter( Amasa, Rockland, ig_intr_md_for_tm.packet_color );
}

action Satanta() {
   execute_meter( Amasa, Burrel.Empire, ig_intr_md_for_tm.packet_color );
}

table Rampart {
   reads {
     Burrel.Empire : ternary;
     Netcong.Mantee : ternary;
     Netcong.Captiva : ternary;
     Chloride.Wabbaseka : ternary;
     Burrel.Steger : ternary;
   }
   actions {
      Rotonda;
      Satanta;
   }
   size : Hillside;
}

control NewAlbin {
   apply( Leicester );
}

control Roseville {
   if( Netcong.Trenary == 1 ) {
      apply( Licking );
   } else if ( Netcong.Seattle == 1 ) {
      apply( Pathfork );
   } else {
      apply( Marysvale );
   }
}

control Astatula {
   if( Netcong.Barney == 0 ) {
      apply( Rampart );
   }
}



action LaJara() {
   modify_field( Burrel.Sawyer, Lowemont.ElCentro );
}



action Larose() {
   modify_field( Burrel.Sawyer, Melrude[0].BelAir );
}

action Dowell() {
   modify_field( Burrel.Virgin, Lowemont.Rockaway );
}

action Mancelona() {
   modify_field( Burrel.Virgin, Reinbeck.Coolin );
}

action Craig() {
   modify_field( Burrel.Virgin, Humacao.Wharton );
}

action Alden( Wakita, SnowLake ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Wakita );
   modify_field( ig_intr_md_for_tm.qid, SnowLake );
}

table Lyman {
   reads {
     Netcong.Parmerton : exact;
   }

   actions {
     LaJara;
     Larose;
   }

   size : BigFork;
}

table Gordon {
   reads {
     Netcong.Trenary : exact;
     Netcong.Seattle : exact;
   }

   actions {
     Dowell;
     Mancelona;
     Craig;
   }

   size : Troutman;
}

table McManus {
   reads {
      Lowemont.Ramapo : ternary;
      Lowemont.ElCentro : ternary;
      Burrel.Sawyer : ternary;
      Burrel.Virgin : ternary;
      Burrel.Creekside : ternary;
   }

   actions {
      Alden;
   }

   size : Dunkerton;
}

action Padonia( Sudden, Dolliver ) {
   bit_or( Burrel.Lawai, Burrel.Lawai, Sudden );
   bit_or( Burrel.Greycliff, Burrel.Greycliff, Dolliver );
}

table Merrill {
   actions {
      Padonia;
   }
   default_action : Padonia(1, 1);
   size : Hitchland;
}

action Vallejo( Vidaurri ) {
   modify_field( Burrel.Virgin, Vidaurri );
}

action Trotwood( Rosebush ) {
   modify_field( Burrel.Sawyer, Rosebush );
}

action Westend( ElLago, Jamesburg ) {
   modify_field( Burrel.Sawyer, ElLago );
   modify_field( Burrel.Virgin, Jamesburg );
}

table Ojibwa {
   reads {
      Lowemont.Ramapo : exact;
      Burrel.Lawai : exact;
      Burrel.Greycliff : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
   }

   actions {
      Vallejo;
      Trotwood;
      Westend;
   }

   size : Dixboro;
}

control Wardville {
   apply( Lyman );
   apply( Gordon );
}

control Salitpa {
   apply( McManus );
}

control Dollar {
   apply( Merrill );
   apply( Ojibwa );
}



action Pawtucket( Bemis ) {
   modify_field( Peebles.Calverton, Attalla );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Bemis );
}

action Millport( Bunavista ) {
   modify_field( Peebles.Calverton, Onset );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Bunavista );
   modify_field( Peebles.Ashburn, ig_intr_md.ingress_port );
}

action Moodys() {
   modify_field( Peebles.Calverton, Attalla );
}

action Bevier() {
   modify_field( Peebles.Calverton, Onset );
   modify_field( Peebles.Ashburn, ig_intr_md.ingress_port );
}

@pragma ternary 1
table Ewing {
   reads {
      Peebles.Tappan : exact;
      ig_intr_md_for_tm.copy_to_cpu : exact;
      Chloride.Wabbaseka : exact;
      Lowemont.Grandy : ternary;
      Peebles.Sandoval : ternary;
   }

   actions {
      Pawtucket;
      Millport;
      Moodys;
      Bevier;
   }

   size : Fairlea;
}

control Lenoir {
   apply( Ewing );
}





counter Stidham {
   type : packets_and_bytes;
   direct : Arvonia;
   min_width: 32;
}

table Arvonia {
   reads {
      eg_intr_md.egress_port mask 0x7f : exact;
      eg_intr_md.egress_qid mask 0x7: exact;
   }

   actions {
      Blitchton;
   }

   size : Saltair;
}

control Fieldon {
   apply( Arvonia );
}



action Oskawalik()
{



   Wolsey();
}

action Moorman()
{
   modify_field(Peebles.Platina, Waseca);
   bit_or(Peebles.Subiaco, 0x2000, Foster.Wadley);
}

action McCallum( Lisman ) {
   modify_field(Peebles.Platina, Waseca);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Lisman);
   modify_field(Peebles.Subiaco, Lisman);
}

table LaFayette {
   reads {
      Foster.Gastonia : exact;
      Foster.Floral : exact;
      Foster.Woodward : exact;
      Foster.Wadley : exact;
   }

   actions {
      Moorman;
      McCallum;
      Oskawalik;
   }
   default_action : Oskawalik();
   size : Advance;
}

control ShadeGap {
   apply( LaFayette );
}

control ingress {

   Grays();

   if( Lowemont.Blakeman != 0 ) {

      Terral();
   }

   Neuse();

   if( Lowemont.Blakeman != 0 ) {
      Devore();


      Urbanette();
   }

   Willshire();


   Kapalua();
   Abernant();

   if( Lowemont.Blakeman != 0 ) {

      Forman();
   }


   Harvest();


   if( Lowemont.Blakeman != 0 ) {
      Jigger();
   }

   Wardville();
   Nunnelly();


   NewAlbin();
   if( Lowemont.Blakeman != 0 ) {
      Osakis();
   }




   GilaBend();
   Antelope();
   Roseville();
   if( Peebles.Tappan == 0 ) {
      if( valid( Foster ) ) {
         ShadeGap();
      } else {
         Daguao();
      }
   }


   Salitpa();
   if( Peebles.Tappan == 0 ) {
      Juneau();
   }

   if( Lowemont.Blakeman != 0 ) {
      Dollar();
   }


   Astatula();


   if( valid( Melrude[0] ) ) {
      Selby();
   }

   if( Peebles.Tappan == 0 ) {
      Schroeder();
   }



   Lenoir();
}

control egress {
   Sonora();
   Garlin();

   if( ( Peebles.Kipahulu == 0 ) and ( Peebles.Platina != Waseca ) ) {
      Nickerson();
   }
   Fieldon();
}
