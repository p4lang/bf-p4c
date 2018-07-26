// ver: 5.2.0 (593ccef)
// BUILD: p4c-tofino --verbose 2 --placement tp4 --no-dead-code-elimination --o bf_arista_switch_baremetal_obfuscated/ --p4-name=arista_switch --p4-prefix=p4_arista_switch --pipe-mgr-path=pipe_mgr/ --mc-mgr-path=mc_mgr/ -S -DPROFILE_BAREMETAL -j16 --print-pa-constraints --disable-power-check  bf_arista_switch_baremetal_obfuscated/Switch.OBFUSCATED.p4 


// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 155405

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
header_type Gonzalez {
	fields {
		Gerty : 16;
		Nixon : 16;
		Abernathy : 8;
		Pearl : 8;
		DeepGap : 8;
		Oregon : 8;
		Sharon : 4;
		Monse : 3;
		Tennyson : 1;
		Gannett : 3;
		Charm : 3;
		Lewis : 6;
	}
}
header_type Devola {
	fields {
		Greenhorn : 24;
		Medart : 24;
		Muncie : 24;
		Baudette : 24;
		Woodstown : 16;
		Vallecito : 12;
		Annetta : 20;
		Tehachapi : 12;
		Virginia : 1;
		Kamrar : 16;
		Bovina : 8;
		HillCity : 8;
		Arroyo : 3;
		Oklee : 3;
		Cotuit : 2;
		Nelagoney : 1;
		Center : 1;
		Rushmore : 1;
		Hawthorn : 1;
		Leicester : 1;
		Eaton : 1;
		Evansburg : 1;
		Alstown : 1;
		DosPalos : 1;
		Kalvesta : 1;
		Shidler : 1;
		Lumpkin : 1;
		Delmont : 1;
		Jelloway : 1;
		Gowanda : 1;
		Haley : 1;
		Swedeborg : 1;
		Fowler : 1;
		OjoFeliz : 1;
		Netarts : 1;
		Calhan : 1;
		Norland : 1;
		Asher : 1;
		Tusayan : 1;
		Cascadia : 1;
		Folger : 16;
		Bennet : 16;
		Norco : 8;
		Carpenter : 2;
		Hartwell : 2;
		Conejo : 1;
		Couchwood : 1;
		Naguabo : 16;
		Cowan : 16;
	}
}
header_type Wollochet {
	fields {
		Stone : 24;
		Accomac : 24;
		Belview : 24;
		Newtown : 24;
		Eustis : 24;
		Pajaros : 24;
		Litroe : 1;
		RedElm : 3;
		OakCity : 1;
		FortHunt : 12;
		Annville : 20;
		FourTown : 16;
		Millwood : 16;
		Freedom : 12;
		Almeria : 10;
		Zebina : 3;
		Kelsey : 8;
		Homeacre : 1;
		Puryear : 12;
		Spanaway : 4;
		Osyka : 6;
		Vining : 10;
		Camanche : 32;
		Rockfield : 32;
		Naches : 24;
		Wheeling : 8;
		Ladoga : 2;
		Sagerton : 32;
		Pinebluff : 9;
		Tonkawa : 2;
		Chatom : 1;
		Calamus : 1;
		LaConner : 12;
		Calumet : 1;
		Gasport : 1;
		Bangor : 1;
		Cedonia : 32;
		Junior : 32;
		Dominguez : 8;
		Hilburn : 24;
		Wakenda : 24;
		McCaskill : 2;
	}
}
header_type Aplin {
	fields {
		Watters : 10;
		Trout : 2;
	}
}
header_type Bagdad {
	fields {
		Polkville : 10;
		Winters : 2;
		Fentress : 8;
		Filley : 6;
		Vallejo : 16;
		Ivanhoe : 4;
		Tahuya : 4;
	}
}
header_type Readsboro {
	fields {
		Bodcaw : 8;
		DuPont : 4;
		LongPine : 1;
	}
}
header_type Atlasburg {
	fields {
		Mendoza : 32;
		Lostwood : 32;
		Kinney : 6;
		Reubens : 6;
		Millikin : 16;
	}
}
header_type Otisco {
	fields {
		Lanyon : 128;
		Maceo : 128;
		Kalskag : 8;
		Galestown : 6;
		Moneta : 16;
	}
}
header_type Kinsey {
	fields {
		Ingraham : 14;
		Herald : 1;
		Markesan : 12;
		Timken : 1;
		Mission : 2;
	}
}
header_type Culloden {
	fields {
		Ingleside : 1;
		Clover : 1;
	}
}
header_type Kaluaaha {
	fields {
		LakePine : 1;
		Belcher : 1;
	}
}
header_type Lennep {
	fields {
		Vernal : 2;
	}
}
header_type Ridgeland {
	fields {
		Truro : 2;
		Cutler : 16;
		Tatitlek : 16;
		Mertens : 2;
		Lakebay : 16;
	}
}
header_type Shoshone {
	fields {
		TroutRun : 16;
		Boistfort : 16;
		Pidcoke : 16;
		Harvard : 16;
		Olene : 16;
		NeckCity : 16;
	}
}
header_type Collis {
	fields {
		Laneburg : 16;
		VanWert : 16;
	}
}
header_type BelAir {
	fields {
		Shoup : 2;
		Steger : 6;
		Saranap : 3;
		Luhrig : 1;
		Torrance : 1;
		ElDorado : 1;
		Kansas : 3;
		Sparr : 1;
		Shauck : 6;
		Perdido : 6;
		Northway : 4;
		Brundage : 5;
	}
}
header_type Wanamassa {
	fields {
		Walland : 16;
	}
}
header_type Soledad {
	fields {
		Taopi : 16;
		Cimarron : 1;
		Lopeno : 1;
	}
}
header_type Minto {
	fields {
		Wakita : 16;
		Gambrills : 1;
		Ralls : 1;
	}
}
header_type Firesteel {
	fields {
		Currie : 16;
		Greycliff : 16;
		Oroville : 16;
		Lyncourt : 16;
		Twisp : 16;
		Gunter : 16;
		Allen : 8;
		Edesville : 8;
		Wakeman : 8;
		Cedar : 8;
		Larose : 1;
		Craig : 6;
	}
}
header_type Battles {
	fields {
		Chevak : 32;
	}
}
header_type Basalt {
	fields {
		Absecon : 6;
		Upland : 10;
		Catawba : 4;
		Florien : 12;
		Tarnov : 2;
		Lakehurst : 2;
		Hackamore : 12;
		Energy : 8;
		Scherr : 2;
		WestBend : 3;
		Worland : 1;
		Larsen : 2;
	}
}
header_type Copley {
	fields {
		ElMango : 24;
		Monahans : 24;
		Sieper : 24;
		Rendon : 24;
		Goodlett : 16;
	}
}
header_type Beechwood {
	fields {
		Selawik : 3;
		Gobler : 1;
		Blackwood : 12;
		Averill : 16;
	}
}
header_type Elderon {
	fields {
		Gladstone : 20;
		Theta : 3;
		DelRosa : 1;
		Capitola : 8;
	}
}
header_type Haverford {
	fields {
		Amazonia : 4;
		Morita : 4;
		Mullins : 6;
		Brockton : 2;
		Portal : 16;
		Orrville : 16;
		Hagaman : 3;
		Grants : 13;
		Biggers : 8;
		Arthur : 8;
		Newhalen : 16;
		Lisle : 32;
		Chatawa : 32;
	}
}
header_type Bucktown {
	fields {
		Dorothy : 4;
		Fennimore : 6;
		Bellmore : 2;
		Krupp : 20;
		Lathrop : 16;
		RockHall : 8;
		Riverbank : 8;
		Gould : 128;
		Bavaria : 128;
	}
}
header_type Corvallis {
	fields {
		Joslin : 8;
		Elysburg : 8;
		Eolia : 16;
	}
}
header_type Westway {
	fields {
		Justice : 16;
		Mogadore : 16;
	}
}
header_type Longford {
	fields {
		Huxley : 32;
		Nicolaus : 32;
		Bieber : 4;
		Valmeyer : 4;
		Oldsmar : 8;
		Magnolia : 16;
		Escondido : 16;
		Bluford : 16;
	}
}
header_type Raynham {
	fields {
		Sedona : 16;
		PineLake : 16;
	}
}
header_type Poulsbo {
	fields {
		Yatesboro : 16;
		Almyra : 16;
		Dennison : 8;
		Belen : 8;
		Crooks : 16;
	}
}
header_type Toano {
	fields {
		Tuttle : 48;
		Bergoo : 32;
		WindGap : 48;
		Brinkley : 32;
	}
}
header_type OldMinto {
	fields {
		Melder : 1;
		Aspetuck : 1;
		Govan : 1;
		Honalo : 1;
		Falmouth : 1;
		SnowLake : 3;
		Westland : 5;
		Morgana : 3;
		Addison : 16;
	}
}
header_type Balmorhea {
	fields {
		Gabbs : 24;
		Owentown : 8;
	}
}
header_type Makawao {
	fields {
		Renick : 8;
		Monmouth : 24;
		Canovanas : 24;
		Konnarock : 8;
	}
}
header Copley Anandale;
header Copley Trona;
header Beechwood Emden[ 2 ];
@pragma pa_fragment ingress Covelo.Newhalen
@pragma pa_fragment egress Covelo.Newhalen
@pragma pa_container_size ingress Covelo.Lisle 32
@pragma pa_container_size ingress Covelo.Chatawa 32
@pragma pa_container_size egress Covelo.Hagaman 8
@pragma pa_container_size egress Covelo.Grants 8
header Haverford Covelo;
@pragma pa_fragment ingress Varnell.Newhalen
@pragma pa_fragment egress Varnell.Newhalen
@pragma pa_container_size egress Varnell.Grants 8
@pragma pa_container_size egress Varnell.Hagaman 8
header Haverford Varnell;
@pragma pa_container_size egress Harvest.Bavaria 32
@pragma pa_container_size egress Harvest.Gould 32
header Bucktown Harvest;
@pragma pa_overlay_new_container_stop ingress Waiehu 1
header Bucktown Waiehu;
header Westway Blakeslee;
header Westway RushHill;
header Longford WestEnd;
header Raynham Motley;
header Longford Swansea;
header Raynham Stambaugh;
@pragma pa_container_size egress Illmo.Canovanas 32
@pragma pa_container_size egress Illmo.Monmouth 32
@pragma pa_container_size ingress Illmo.Monmouth 32
@pragma pa_container_size ingress Illmo.Renick 8
header Makawao Illmo;
header OldMinto Hopeton;
header Poulsbo Oxford;
@pragma pa_container_size egress Larchmont.Absecon 32
@pragma not_parsed egress
header Basalt Larchmont;
@pragma not_deparsed ingress
@pragma not_parsed egress
header Copley Callao;
@pragma parser_value_set_size 2
parser_value_set Caldwell;
parser start {
   return select( ig_intr_md.ingress_port ) {
      Caldwell : Fergus;
      default : Absarokee;
   }
}
@pragma dont_trim
@pragma packet_entry
parser start_i2e_mirrored {
   return ingress;
}
@pragma dont_trim
@pragma packet_entry
parser start_e2e_mirrored {
   return ingress;
}
@pragma dont_trim
@pragma packet_entry
parser start_egress {
   return select(current(96, 16)) {
      default : Absarokee;
      0xBF00 : Knolls;
   }
}
parser Grabill {
   return select( current(0, 32) ) {
      0x00010800 : McMurray;
      default : ingress;
   }
}
parser McMurray {
   extract( Oxford );
   return ingress;
}
parser Knolls {
   extract( Callao );
   extract( Larchmont );
   return Absarokee;
}
parser Walcott {
   extract( Larchmont );
   return Absarokee;
}
@pragma force_shift ingress 112
parser Fergus {
   return Walcott;
}
parser Pierceton {
   set_metadata(Oshoto.Sharon, 0x5);
   return ingress;
}
parser Vanzant {
   set_metadata(Oshoto.Sharon, 0x6);
   return ingress;
}
parser Tilghman {
   set_metadata( Oshoto.Sharon, 0x8 );
   return ingress;
}
parser Absarokee {
   extract( Anandale );
   return select( current(0, 8), Anandale.Goodlett ) {
      0x8100 mask 0xFFFF : Creston;
      0x0806 mask 0xFFFF : Grabill;
      0x450800 : Earlsboro;
      0x50800 mask 0xFFFFF : Pierceton;
      0x0800 mask 0xFFFF : Wamego;
      0x6086dd mask 0xF0FFFF : Protem;
      0x86dd mask 0xFFFF : Vanzant;
      0x8808 mask 0xFFFF : Tilghman;
      default : ingress;
   }
}
parser Creston {
   extract( Emden[0] );
   return select( current(0, 8), Emden[0].Averill ) {
      0x0806 mask 0xFFFF : Grabill;
      0x450800 : Earlsboro;
      0x50800 mask 0xFFFFF : Pierceton;
      0x0800 mask 0xFFFF : Wamego;
      0x6086dd mask 0xF0FFFF : Protem;
      0x86dd mask 0xFFFF : Vanzant;
      default : ingress;
   }
}
field_list Kalkaska {
    Covelo.Amazonia;
    Covelo.Morita;
    Covelo.Mullins;
    Covelo.Brockton;
    Covelo.Portal;
    Covelo.Orrville;
    Covelo.Hagaman;
    Covelo.Grants;
    Covelo.Biggers;
    Covelo.Arthur;
    Covelo.Lisle;
    Covelo.Chatawa;
}
field_list_calculation Goulds {
    input {
        Kalkaska;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Covelo.Newhalen {
    verify Goulds;
    update Goulds;
}
parser Earlsboro {
   extract( Covelo );
   set_metadata(Oshoto.Abernathy, Covelo.Arthur);
   set_metadata(Naylor.HillCity, Covelo.Biggers);
   set_metadata(Oshoto.Sharon, 0x1);
   return select(Covelo.Grants, Covelo.Arthur) {
      1 : Tulsa;
      17 : Lodoga;
      6 : Meeker;
      47 : Cotter;
      0 mask 0x1fff00 : ingress;
      6 mask 0xff: Montalba;
      default : Jauca;
   }
}
parser Wamego {
   set_metadata(Covelo.Chatawa, current(128,32));
   set_metadata(Oshoto.Sharon, 0x3);
   set_metadata(Oshoto.Lewis, current(8, 6));
   set_metadata(Oshoto.Abernathy, current(72,8));
   return ingress;
}
parser Montalba {
   set_metadata(Oshoto.Charm, 5);
   return ingress;
}
parser Jauca {
   set_metadata(Oshoto.Charm, 1);
   return ingress;
}
parser Protem {
   extract( Waiehu );
   set_metadata(Oshoto.Abernathy, Waiehu.RockHall);
   set_metadata(Naylor.HillCity, Waiehu.Riverbank);
   set_metadata(Oshoto.Sharon, 0x2);
   return select(Waiehu.RockHall) {
      0x3a : Tulsa;
      17 : Shasta;
      6 : Meeker;
      default : ingress;
   }
}
parser Lodoga {
   set_metadata(Oshoto.Charm, 2);
   extract(Blakeslee);
   extract(Motley);
   return select(Blakeslee.Mogadore) {
      4789 : Lushton;
      65330 : Lushton;
      default : ingress;
    }
}
parser Tulsa {
   set_metadata( Blakeslee.Justice, current( 0, 16 ) );
   return ingress;
}
parser Shasta {
   set_metadata(Oshoto.Charm, 2);
   extract(Blakeslee);
   extract(Motley);
   return ingress;
}
parser Meeker {
   set_metadata(Oshoto.Charm, 6);
   extract(Blakeslee);
   extract(WestEnd);
   return ingress;
}
parser Paragould {
   set_metadata(Naylor.Cotuit, 2);
   return select( current(4, 4) ) {
      0x5 : Wynnewood;
      default : Coamo;
   }
}
parser Hansboro {
   return select( current(0,4) ) {
      0x4 : Paragould;
      default : ingress;
   }
}
parser Lantana {
   set_metadata(Naylor.Cotuit, 2);
   return Berkley;
}
parser Glassboro {
   return select( current(0,4) ) {
      0x6 : Lantana;
      default: ingress;
   }
}
parser Cotter {
   extract(Hopeton);
   return select(Hopeton.Melder, Hopeton.Aspetuck, Hopeton.Govan, Hopeton.Honalo, Hopeton.Falmouth,
             Hopeton.SnowLake, Hopeton.Westland, Hopeton.Morgana, Hopeton.Addison) {
      0x0800 : Hansboro;
      0x86dd : Glassboro;
      default : ingress;
   }
}
parser Lushton {
   extract(Illmo);
   set_metadata(Naylor.Cotuit, 1);
   return Aurora;
}
field_list Duster {
    Varnell.Amazonia;
    Varnell.Morita;
    Varnell.Mullins;
    Varnell.Brockton;
    Varnell.Portal;
    Varnell.Orrville;
    Varnell.Hagaman;
    Varnell.Grants;
    Varnell.Biggers;
    Varnell.Arthur;
    Varnell.Lisle;
    Varnell.Chatawa;
}
field_list_calculation Chackbay {
    input {
        Duster;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field Varnell.Newhalen {
    verify Chackbay;
    update Chackbay;
}
parser Coamo {
   set_metadata(Oshoto.Monse, 0x3);
   set_metadata(Oshoto.Lewis, current(8, 6));
   return ingress;
}
parser Wynnewood {
   extract( Varnell );
   set_metadata(Oshoto.Pearl, Varnell.Arthur);
   set_metadata(Oshoto.Oregon, Varnell.Biggers);
   set_metadata(Oshoto.Monse, 0x1);
   set_metadata(Suffern.Mendoza, Varnell.Lisle);
   set_metadata(Suffern.Lostwood, Varnell.Chatawa);
   return select(Varnell.Grants, Varnell.Arthur) {
      1 : Raven;
      17 : Waubun;
      6 : Clarks;
      0 mask 0x1fff00 : ingress;
      6 mask 0xff: Statham;
      default : Kathleen;
   }
}
parser Statham {
   set_metadata(Oshoto.Gannett, 5);
   return ingress;
}
parser Kathleen {
   set_metadata(Oshoto.Gannett, 1);
   return ingress;
}
parser Berkley {
   extract( Harvest );
   set_metadata(Oshoto.Pearl, Harvest.RockHall);
   set_metadata(Oshoto.Oregon, Harvest.Riverbank);
   set_metadata(Oshoto.Monse, 0x2);
   set_metadata(Coolin.Lanyon, Harvest.Gould);
   set_metadata(Coolin.Maceo, Harvest.Bavaria);
   return select(Harvest.RockHall) {
      0x3a : Raven;
      17 : Waubun;
      6 : Clarks;
      default : ingress;
   }
}
parser Raven {
   set_metadata( Naylor.Folger, current( 0, 16 ) );
   return ingress;
}
parser Waubun {
   set_metadata( Naylor.Folger, current( 0, 16 ) );
   set_metadata( Naylor.Bennet, current( 16, 16 ) );
   set_metadata(Oshoto.Gannett, 2);
   extract(RushHill);
   extract(Stambaugh);
   return ingress;
}
parser Clarks {
   set_metadata( Naylor.Folger, current( 0, 16 ) );
   set_metadata( Naylor.Bennet, current( 16, 16 ) );
   set_metadata( Naylor.Norco, current( 104, 8 ) );
   set_metadata(Oshoto.Gannett, 6);
   extract(RushHill);
   extract(Swansea);
   return ingress;
}
parser Newtok {
   set_metadata(Oshoto.Monse, 0x5);
   return ingress;
}
parser Brinkman {
   set_metadata(Oshoto.Monse, 0x6);
   return ingress;
}
parser Aurora {
   extract( Trona );
   set_metadata( Naylor.Greenhorn, Trona.ElMango );
   set_metadata( Naylor.Medart, Trona.Monahans );
   set_metadata( Naylor.Woodstown, Trona.Goodlett );
   return select( current( 0, 8 ), Trona.Goodlett ) {
      0x0806 mask 0xFFFF : Grabill;
      0x450800 : Wynnewood;
      0x50800 mask 0xFFFFF : Newtok;
      0x0800 mask 0xFFFF : Coamo;
      0x6086dd mask 0xF0FFFF : Berkley;
      0x86dd mask 0xFFFF : Brinkman;
      default: ingress;
   }
}
@pragma pa_container_size ingress Larchmont.Upland 32
@pragma pa_container_size ingress LaVale.Shauck 16
@pragma pa_container_size ingress LaVale.Sparr 16
@pragma pa_container_size ingress LaVale.Kansas 16
@pragma pa_container_size ingress Naylor.Vallecito 16
@pragma pa_container_size ingress Cargray.FortHunt 16
@pragma pa_no_init ingress Naylor.Greenhorn
@pragma pa_no_init ingress Naylor.Medart
@pragma pa_no_init ingress Naylor.Muncie
@pragma pa_no_init ingress Naylor.Baudette
@pragma pa_container_size ingress Naylor.Hawthorn 32
@pragma pa_container_size ingress Naylor.Center 32
@pragma pa_container_size ingress Naylor.Fowler 8
@pragma pa_container_size ingress Naylor.OjoFeliz 8
@pragma pa_container_size ingress Buenos.Clover 8
@pragma pa_container_size ingress Buenos.Ingleside 32
@pragma pa_no_init ingress Buenos.Clover
@pragma pa_no_init ingress Buenos.Ingleside
@pragma pa_no_init ingress Naylor.Arroyo
@pragma pa_container_size ingress Naylor.Asher 8
metadata Devola Naylor;
@pragma pa_allowed_to_share egress Cargray.Calamus Marysvale.Polkville
@pragma pa_container_size ingress Cargray.Annville 32
@pragma pa_container_size ingress Cargray.Almeria 32
@pragma pa_container_size ingress Naylor.Carpenter 32
@pragma pa_no_init ingress Cargray.Stone
@pragma pa_no_init ingress Cargray.Accomac
@pragma pa_no_init ingress Cargray.Belview
@pragma pa_no_init ingress Cargray.Newtown
@pragma pa_container_size ingress Cargray.Camanche 32
@pragma pa_no_overlay ingress Cargray.FortHunt
@pragma pa_solitary ingress Cargray.FortHunt
metadata Wollochet Cargray;
metadata Aplin Kapowsin;
metadata Bagdad Marysvale;
@pragma pa_container egress Marysvale.Polkville 159
metadata Kinsey LaCueva;
metadata Gonzalez Oshoto;
@pragma pa_container ingress Suffern.Mendoza 32
@pragma pa_container_size ingress Naalehu.Cutler 16
@pragma pa_container_size ingress Suffern.Millikin 16
metadata Atlasburg Suffern;
@pragma pa_container_size ingress Coolin.Moneta 16
metadata Otisco Coolin;
@pragma pa_alias ingress Suffern.Millikin Coolin.Moneta
@pragma pa_alias ingress Naalehu.Tatitlek Naalehu.Cutler
metadata Culloden Buenos;
@pragma pa_container_size egress Downs.Belcher 8
metadata Kaluaaha Downs;
@pragma pa_container_size ingress Igloo.LongPine 8
metadata Readsboro Igloo;
metadata Lennep Weinert;
metadata Ridgeland Naalehu;
@pragma pa_no_init ingress Kealia.Laneburg
@pragma pa_no_init ingress Kealia.VanWert
@pragma pa_no_init ingress Shivwits.TroutRun
@pragma pa_no_init ingress Shivwits.Boistfort
@pragma pa_no_init ingress Shivwits.Pidcoke
@pragma pa_no_init ingress Shivwits.Harvard
@pragma pa_no_init ingress Shivwits.Olene
@pragma pa_no_init ingress Shivwits.NeckCity
@pragma pa_container_size ingress Kealia.Laneburg 16
@pragma pa_mutually_exclusive ingress Kealia.Laneburg Kealia.VanWert
metadata Collis Kealia;
metadata Shoshone Shivwits;
metadata BelAir LaVale;
metadata Wanamassa RoseBud;
@pragma pa_no_init ingress Kingman.Taopi
@pragma pa_solitary ingress Kingman.Lopeno
metadata Soledad Kingman;
@pragma pa_no_init egress Cargray.Junior
@pragma pa_no_init ingress Baird.Wakita
metadata Minto Baird;
@pragma pa_no_init ingress Mackville.Oroville
@pragma pa_no_init ingress Mackville.Lyncourt
metadata Firesteel Mackville;
metadata Firesteel Elkader;
action Buncombe() {
   no_op();
}
action Hadley() {
   modify_field( Naylor.Nelagoney, 1 );
}
action Clementon() {
   no_op();
}
action Shorter(Hoadly, Mendocino, Breese, Quebrada, Langtry ) {
    modify_field(LaCueva.Ingraham, Hoadly);
    modify_field(LaCueva.Herald, Mendocino);
    modify_field(LaCueva.Markesan, Breese);
    modify_field(LaCueva.Timken, Quebrada);
    modify_field(LaCueva.Mission, Langtry);
}
@pragma phase0 1
table Ridgewood {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        Shorter;
    }
    size : 288;
}
control Chatmoss {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(Ridgewood);
    }
}
action Granbury(Newsome, Wellsboro) {
   modify_field( Cargray.OakCity, 1 );
   modify_field( Cargray.Kelsey, Newsome);
   modify_field( Naylor.Fowler, 1 );
   modify_field( LaVale.ElDorado, Wellsboro );
   modify_field( LaCueva.Herald, 1 );
}
action Pardee(Lenoir, WarEagle) {
   modify_field( Cargray.Kelsey, Lenoir);
   modify_field( Naylor.Fowler, 1 );
   modify_field( LaVale.ElDorado, WarEagle );
}
action Snohomish() {
   modify_field( Naylor.Rushmore, 1 );
   modify_field( Naylor.Netarts, 1 );
}
action Edler() {
   modify_field( Naylor.Fowler, 1 );
}
action Topton() {
   modify_field( Naylor.Fowler, 1 );
   modify_field( Naylor.Calhan, 1 );
}
action Branson() {
   modify_field( Naylor.OjoFeliz, 1 );
}
action Northlake() {
   modify_field( Naylor.Netarts, 1 );
}
counter Archer {
   type : packets_and_bytes;
   direct : Rawson;
   min_width: 16;
}
@pragma immediate 0
table Rawson {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Anandale.ElMango : ternary;
      Anandale.Monahans : ternary;
   }
   actions {
      Granbury;
      Snohomish;
      Edler;
      Branson;
      Northlake;
      Topton;
      Pardee;
   }
   default_action: Buncombe();
   size : 1656;
}
action Encinitas() {
   modify_field( Naylor.Hawthorn, 1 );
}
table McDaniels {
   reads {
      Anandale.Sieper : ternary;
      Anandale.Rendon : ternary;
   }
   actions {
      Encinitas;
   }
   size : 512;
}
control Coqui {
   apply( Rawson ) {
      Granbury { }
      default {
         Irvine();
      }
   }
   apply( McDaniels );
}
action Amenia() {
   modify_field( Suffern.Kinney, Varnell.Mullins );
   modify_field( Coolin.Galestown, Harvest.Fennimore );
   modify_field( Naylor.Muncie, Trona.Sieper );
   modify_field( Naylor.Baudette, Trona.Rendon );
   modify_field( Naylor.Bovina, Oshoto.Pearl );
   modify_field( Naylor.HillCity, Oshoto.Oregon );
   modify_field( Naylor.Arroyo, Oshoto.Monse, 0x7 );
   modify_field( Cargray.Zebina, 1 );
   modify_field( Mackville.Twisp, Naylor.Folger );
   modify_field( Naylor.Oklee, Oshoto.Gannett );
   modify_field( Mackville.Larose, Oshoto.Gannett, 1);
}
action Udall() {
   modify_field( LaVale.Sparr, Emden[0].Gobler );
   modify_field( Naylor.Norland, Emden[ 0 ].valid );
   modify_field( Naylor.Cotuit, 0 );
   modify_field( Suffern.Mendoza, Covelo.Lisle );
   modify_field( Suffern.Lostwood, Covelo.Chatawa );
   modify_field( Suffern.Kinney, Covelo.Mullins );
   modify_field( Coolin.Lanyon, Waiehu.Gould );
   modify_field( Coolin.Maceo, Waiehu.Bavaria );
   modify_field( Coolin.Galestown, Waiehu.Fennimore );
   modify_field( Naylor.Greenhorn, Anandale.ElMango );
   modify_field( Naylor.Medart, Anandale.Monahans );
   modify_field( Naylor.Muncie, Anandale.Sieper );
   modify_field( Naylor.Baudette, Anandale.Rendon );
   modify_field( Naylor.Woodstown, Anandale.Goodlett );
   modify_field( Naylor.Bovina, Oshoto.Abernathy );
   modify_field( Naylor.Arroyo, Oshoto.Sharon, 0x7 );
   modify_field( Mackville.Twisp, Blakeslee.Justice );
   modify_field( Naylor.Folger, Blakeslee.Justice );
   modify_field( Naylor.Bennet, Blakeslee.Mogadore );
   modify_field( Naylor.Norco, WestEnd.Oldsmar );
   modify_field( Naylor.Oklee, Oshoto.Charm );
   modify_field( Mackville.Larose, Oshoto.Charm, 1);
}
table Willey {
   reads {
      Anandale.ElMango : exact;
      Anandale.Monahans : exact;
      Covelo.Chatawa : ternary;
      Naylor.Cotuit : exact;
   }
   actions {
      Amenia;
      Udall;
   }
   default_action : Udall();
   size : 1024;
}
action Donna(Sparland) {
   modify_field( Naylor.Vallecito, LaCueva.Markesan );
   modify_field( Naylor.Annetta, Sparland);
}
action VanZandt( Hiland, Lardo ) {
   modify_field( Naylor.Vallecito, Hiland );
   modify_field( Naylor.Annetta, Lardo);
}
action CassCity(Elloree) {
   modify_field( Naylor.Vallecito, Emden[0].Blackwood );
   modify_field( Naylor.Annetta, Elloree);
}
table Monee {
   reads {
      LaCueva.Ingraham : exact;
      Emden[0] : valid;
      Emden[0].Blackwood : ternary;
   }
   actions {
      Donna;
      VanZandt;
      CassCity;
   }
   size : 4096;
}
action Tulip( Isleta ) {
   modify_field( Naylor.Annetta, Isleta );
}
action Mabel() {
   modify_field( Weinert.Vernal,
                 3 );
}
action McCloud() {
   modify_field( Weinert.Vernal,
                 1 );
}
@pragma immediate 0
table Ladner {
   reads {
      Covelo.Lisle : exact;
   }
   actions {
      Tulip;
      Mabel;
      McCloud;
   }
   default_action : Mabel;
   size : 4096;
}
action Galloway( Hammond, Staunton, Wyndmere ) {
   modify_field( Naylor.Vallecito, Hammond );
   modify_field( Naylor.Tehachapi, Hammond );
   Sutton(Staunton, Wyndmere);
}
action Vinita() {
   modify_field( Naylor.Center, 1 );
}
@pragma immediate 0
table Raytown {
   reads {
      Illmo.Canovanas : exact;
   }
   actions {
      Galloway;
      Vinita;
   }
   size : 4096;
}
action Sutton(Saltdale, Retrop) {
   modify_field( Igloo.Bodcaw, Saltdale );
   modify_field( Igloo.DuPont, Retrop );
}
action Dustin(Mattapex, Kaibab) {
   modify_field( Naylor.Tehachapi, LaCueva.Markesan );
   Sutton(Mattapex, Kaibab);
}
action Magoun(Gotebo, Pineland, Macopin) {
   modify_field( Naylor.Tehachapi, Gotebo );
   Sutton(Pineland, Macopin);
}
action Bernstein(Lamona, Ralph) {
   modify_field( Naylor.Tehachapi, Emden[0].Blackwood );
   Sutton(Lamona, Ralph);
}
table Rainelle {
   reads {
      LaCueva.Markesan : exact;
   }
   actions {
      Dustin;
   }
   size : 4096;
}
@pragma action_default_only Buncombe
table Inola {
   reads {
      LaCueva.Ingraham : exact;
      Emden[0].Blackwood : exact;
   }
   actions {
      Magoun;
      Buncombe;
   }
   size : 1024;
}
@pragma immediate 0
table Grandy {
   reads {
      Emden[0].Blackwood : exact;
   }
   actions {
      Bernstein;
   }
   size : 4096;
}
control OldTown {
   apply( Willey ) {
         Amenia {
            apply( Ladner );
            apply( Raytown );
         }
         Udall {
            if ( LaCueva.Timken == 1 ) {
               apply( Monee );
            }
            if ( valid( Emden[0] ) and Emden[0].Blackwood != 0 ) {
               apply( Inola ) {
                  Buncombe {
                     apply( Grandy );
                  }
               }
            } else {
               apply( Rainelle );
            }
         }
   }
}
action Chatanika() {
}
action Tenstrike() {
}
action Claunch( Vanoss ) {
   modify_field( Suffern.Lostwood, Vanoss );
   modify_field( Naylor.Cascadia, 1 );
}
action Kisatchie( Fairchild, Twodot, Baker ) {
   modify_field( Igloo.Bodcaw, Fairchild );
   modify_field( Naylor.Cowan, Baker );
   Claunch( Twodot );
}
table Clyde {
   reads {
      Igloo.Bodcaw : ternary;
      Naylor.Tehachapi : ternary;
      Suffern.Mendoza : ternary;
   }
   actions {
      Chatanika;
      Tenstrike;
      Buncombe;
   }
   default_action : Buncombe();
   size : 2048;
}
table AquaPark {
   reads {
      Suffern.Lostwood : exact;
      Naylor.Tehachapi : exact;
   }
   actions {
      Claunch;
   }
   size : 16384;
}
@pragma ways 2
table Odebolt {
   reads {
     Suffern.Lostwood : exact;
   }
   actions {
      Kisatchie;
   }
  size : 4096;
}
control Halstead {
   if ( ( ( Igloo.DuPont & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Naylor.Arroyo == 0x1 ) and ( LaCueva.Mission != 0 ) and ( Naylor.Nelagoney == 0 ) ) {
      apply( Clyde ) {
         Tenstrike {
            apply( Odebolt );
         }
      }
   }
}
action ElToro( Wartrace ) {
   modify_field( Suffern.Mendoza, Wartrace );
   modify_field( Naylor.Tusayan, 1 );
}
table Aynor {
   reads {
      Cargray.FortHunt : exact;
      Suffern.Lostwood : ternary;
   }
   actions {
      Chatanika;
      Buncombe;
   }
   default_action : Buncombe();
   size : 2048;
}
table Beaverton {
   reads {
      Suffern.Mendoza : exact;
      Cargray.FortHunt : exact;
   }
   actions {
      ElToro;
   }
   size : 16384;
}
control Trenary {
   apply( Aynor ) {
      Chatanika {
         apply( Beaverton );
      }
   }
}
action Lorane(Nashua) {
   modify_field(Cargray.OakCity, 1);
   modify_field(Cargray.Kelsey, Nashua);
}
table Iselin {
   reads {
      Cargray.FortHunt : exact;
      Suffern.Mendoza : ternary;
      Suffern.Lostwood : ternary;
   }
   actions {
      Lorane;
   }
   size : 0;
}
control Talmo {
   if( ( ( Igloo.DuPont & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Naylor.Arroyo == 0x1 ) and ( Naylor.Tusayan == 0 ) and ( Naylor.Cascadia == 0 ) ) {
      apply( Iselin );
   }
}
action Elbing() {
   modify_field( Naylor.Naguabo, Naylor.Cowan );
}
table Cowley {
   reads {
      Cargray.OakCity : ternary;
      Covelo.valid : ternary;
      Motley.valid : ternary;
      WestEnd.valid : ternary;
      Motley.PineLake : ternary;
   }
   actions {
      Elbing;
   }
   size : 16;
}
control Deloit {
   apply( Cowley );
}
register Newport {
    width : 1;
    static : Veguita;
    instance_count : 294912;
}
register Lucas {
    width : 1;
    static : Beatrice;
    instance_count : 294912;
}
blackbox stateful_alu Lacona {
    reg : Newport;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : Buenos.Ingleside;
}
blackbox stateful_alu Trilby {
    reg : Lucas;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst : Buenos.Clover;
}
field_list SwissAlp {
    ig_intr_md.ingress_port;
    Emden[0].Blackwood;
}
field_list_calculation McDavid {
    input { SwissAlp; }
    algorithm: identity;
    output_width: 19;
}
action Placedo() {
    Lacona.execute_stateful_alu_from_hash(McDavid);
}
action Tularosa() {
    Trilby.execute_stateful_alu_from_hash(McDavid);
}
table Veguita {
    actions {
      Placedo;
    }
    default_action : Placedo;
    size : 1;
}
table Beatrice {
    actions {
      Tularosa;
    }
    default_action : Tularosa;
    size : 1;
}
control Irvine {
   if ( valid( Emden[0] ) and Emden[0].Blackwood != 0
        and LaCueva.Timken == 1 ) {
      apply( Veguita );
   }
   apply( Beatrice );
}
register BoyRiver {
    width : 1;
    static : Coulter;
    instance_count : 294912;
}
register Marfa {
    width : 1;
    static : Domingo;
    instance_count : 294912;
}
blackbox stateful_alu Steele {
    reg : BoyRiver;
    update_lo_1_value: read_bitc;
    output_value : alu_lo;
    output_dst : Downs.LakePine;
}
blackbox stateful_alu Geeville {
    reg : Marfa;
    update_lo_1_value: read_bit;
    output_value : alu_lo;
    output_dst : Downs.Belcher;
}
field_list Sawyer {
   eg_intr_md.egress_port;
   Cargray.Freedom;
}
field_list_calculation Attica {
   input { Sawyer; }
   algorithm: identity;
   output_width: 19;
}
action Leola() {
   Steele.execute_stateful_alu_from_hash(Attica);
}
table Coulter {
   actions {
     Leola;
   }
   default_action : Leola;
   size : 1;
}
action Canton() {
    Geeville.execute_stateful_alu_from_hash(Attica);
}
table Domingo {
    actions {
      Canton;
    }
    default_action : Canton;
    size : 1;
}
control Hatchel {
   apply( Coulter );
   apply( Domingo );
}
field_list Gagetown {
   Anandale.ElMango;
   Anandale.Monahans;
   Anandale.Sieper;
   Anandale.Rendon;
   Anandale.Goodlett;
}
field_list Harrison {
   Trona.ElMango;
   Trona.Monahans;
   Trona.Sieper;
   Trona.Rendon;
   Trona.Goodlett;
}
field_list Pittsburg {
   Covelo.Arthur;
   Covelo.Lisle;
   Covelo.Chatawa;
}
field_list Humeston {
   Suffern.Mendoza;
   Suffern.Lostwood;
   Oshoto.Pearl;
}
field_list Ragley {
   Coolin.Lanyon;
   Coolin.Maceo;
   Harvest.Krupp;
   Oshoto.Pearl;
}
field_list FairOaks {
   Waiehu.Gould;
   Waiehu.Bavaria;
   Waiehu.Krupp;
   Waiehu.RockHall;
}
field_list Madawaska {
   Shivwits.Boistfort;
   Blakeslee.Justice;
   Blakeslee.Mogadore;
}
field_list Pittwood {
   Shivwits.Olene;
   RushHill.Justice;
   RushHill.Mogadore;
}
field_list_calculation Chatfield {
    input {
        Gagetown;
    }
    algorithm : crc16;
    output_width : 16;
}
field_list_calculation Arvonia {
    input {
        Harrison;
    }
    algorithm : crc16;
    output_width : 16;
}
field_list_calculation Birds {
    input {
        Pittsburg;
    }
    algorithm : crc16;
    output_width : 16;
}
field_list_calculation Casco {
    input {
        Humeston;
    }
    algorithm : crc16;
    output_width : 16;
}
field_list_calculation Nisland {
    input {
        Ragley;
    }
    algorithm : crc16;
    output_width : 16;
}
field_list_calculation Nipton {
    input {
        FairOaks;
    }
    algorithm : crc16;
    output_width : 16;
}
field_list_calculation ElkFalls {
    input {
        Madawaska;
    }
    algorithm : crc16;
    output_width : 16;
}
field_list_calculation Sabina {
    input {
        Pittwood;
    }
    algorithm : crc16;
    output_width : 16;
}
action Tolley() {
    modify_field_with_hash_based_offset(Shivwits.TroutRun, 0,
                                        Chatfield, 65536 );
}
action Newburgh() {
    modify_field_with_hash_based_offset( Shivwits.Harvard, 0,
                                        Arvonia, 65536 );
}
action Perrine() {
    modify_field_with_hash_based_offset(Shivwits.Boistfort, 0,
                                        Birds, 65536 );
}
action Suttle() {
    modify_field_with_hash_based_offset(Shivwits.Boistfort, 0,
                                        Nipton, 65536 );
}
action Philip() {
    modify_field_with_hash_based_offset(Shivwits.Pidcoke, 0,
                                        ElkFalls, 65536 );
}
action Stowe() {
    modify_field_with_hash_based_offset(Shivwits.Olene, 0,
                                        Casco, 65536 );
}
action Saxonburg() {
   modify_field_with_hash_based_offset( Shivwits.Olene, 0,
                                        Nisland, 65536 );
}
action Wayland() {
   modify_field_with_hash_based_offset( Shivwits.NeckCity, 0,
                                        Sabina, 65536 );
}
@pragma ternary 1
table Reager {
   reads {
     Varnell.valid : exact;
     Harvest.valid : exact;
   }
   actions {
      Stowe;
      Saxonburg;
   }
  size : 2;
}
table Tombstone {
   actions {
      Newburgh;
   }
   size: 1;
}
control Carlin {
   apply( Tombstone );
}
table Tullytown {
   actions {
      Perrine;
   }
   size: 1;
}
table Combine {
   actions {
      Suttle;
   }
   size: 1;
}
control Dumas {
   if ( valid( Covelo ) ) {
      apply(Tullytown);
   } else {
      apply( Combine );
   }
}
action Naubinway() {
   Philip();
   Wayland();
}
table Fleetwood {
   actions {
      Naubinway;
   }
   size: 1;
}
control Sarasota {
   apply( Fleetwood );
}
action Ronan() {
    modify_field_with_hash_based_offset(Kealia.Laneburg, 0,
                                        Chatfield, 65536 );
}
action Placida() {
    modify_field(Kealia.Laneburg, Shivwits.Boistfort);
}
action Elmdale() {
    modify_field(Kealia.Laneburg, Shivwits.Pidcoke);
}
action Sutter() {
    modify_field( Kealia.Laneburg, Shivwits.Harvard );
}
action Rhine() {
    modify_field( Kealia.Laneburg, Shivwits.Olene );
}
action Fireco() {
    modify_field( Kealia.Laneburg, Shivwits.NeckCity );
}
@pragma action_default_only Buncombe
@pragma immediate 0
table Lauada {
   reads {
      RushHill.valid : ternary;
      Varnell.valid : ternary;
      Harvest.valid : ternary;
      Trona.valid : ternary;
      Blakeslee.valid : ternary;
      Covelo.valid : ternary;
      Waiehu.valid : ternary;
      Anandale.valid : ternary;
   }
   actions {
      Ronan;
      Placida;
      Elmdale;
      Sutter;
      Rhine;
      Fireco;
      Buncombe;
   }
   size: 256;
}
action Stratford() {
    modify_field(Kealia.VanWert, Shivwits.Boistfort);
}
action Gardena() {
    modify_field( Kealia.VanWert, Shivwits.Olene );
}
action RioPecos() {
    modify_field(Kealia.VanWert, Shivwits.Pidcoke);
}
action Waupaca() {
    modify_field( Kealia.VanWert, Shivwits.NeckCity );
}
action Congress() {
    modify_field( Kealia.VanWert, Shivwits.Harvard );
}
@pragma immediate 0
table Mapleton {
   reads {
      RushHill.valid : ternary;
      Varnell.valid : ternary;
      Harvest.valid : ternary;
      Trona.valid : ternary;
      Blakeslee.valid : ternary;
      Waiehu.valid : ternary;
      Covelo.valid : ternary;
   }
   actions {
      Stratford;
      RioPecos;
      Gardena;
      Waupaca;
      Congress;
      Buncombe;
   }
   size: 512;
}
counter Murdock {
   type : packets;
   direct : Marley;
   min_width: 64;
}
table Marley {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Buenos.Clover : ternary;
      Buenos.Ingleside : ternary;
      Naylor.Center : ternary;
      Naylor.Hawthorn : ternary;
      Naylor.Rushmore : ternary;
      Oshoto.Sharon mask 0x8 : ternary;
      ig_intr_md_from_parser_aux.ingress_parser_err mask 0x1000 : ternary;
   }
   actions {
      Buncombe;
   }
   default_action : Buncombe();
   size : 512;
}
table Woodburn {
   reads {
      Buenos.Clover : exact;
      Buenos.Ingleside : exact;
      Naylor.Center : exact;
      Naylor.Hawthorn : exact;
      Naylor.Rushmore : exact;
      Oshoto.Sharon mask 0x8 : exact;
      ig_intr_md_from_parser_aux.ingress_parser_err mask 0x1000 : exact;
   }
   actions {
      Hadley;
      Buncombe;
   }
   default_action : Hadley();
   size : 2;
}
action Darmstadt() {
   modify_field( Naylor.Leicester, 1 );
}
table Trammel {
   reads {
      Naylor.Muncie : exact;
      Naylor.Baudette : exact;
      Naylor.Vallecito : exact;
   }
   actions {
      Darmstadt;
      Buncombe;
   }
   default_action : Buncombe();
   size : 4096;
}
action Basco() {
   modify_field(Weinert.Vernal,
                2);
}
table Comfrey {
   reads {
      Naylor.Muncie : exact;
      Naylor.Baudette : exact;
      Naylor.Vallecito : exact;
      Naylor.Annetta : exact;
   }
   actions {
      Clementon;
      Basco;
   }
   default_action : Basco();
   size : 16384;
   support_timeout : true;
}
action Kendrick( Standish, Paoli, Pillager ) {
   modify_field( Naylor.Asher, Standish );
   modify_field( Naylor.Delmont, Paoli );
   modify_field( Naylor.Jelloway, Pillager );
}
@pragma use_hash_action 1
table Bosco {
   reads {
      Naylor.Vallecito mask 0xfff : exact;
   }
   actions {
      Kendrick;
   }
   default_action : Kendrick( 0, 0, 0 );
   size : 4096;
}
action Westoak() {
   modify_field( Igloo.LongPine, 1 );
}
table Parksley {
   reads {
      Naylor.Tehachapi : ternary;
      Naylor.Greenhorn : exact;
      Naylor.Medart : exact;
   }
   actions {
      Westoak;
   }
   size: 512;
}
control Silesia {
   apply( Marley );
   apply( Woodburn ) {
      Buncombe {
         apply( Trammel ) {
            Buncombe {
               if (Weinert.Vernal == 0 and
                   Naylor.Vallecito != 0 and
                   (Cargray.Zebina == 1 or
                    LaCueva.Herald == 0) and
                   Buenos.Ingleside == 0 and
                   Buenos.Clover == 0 and
                   Naylor.Hawthorn == 0 and
                   Naylor.Rushmore == 0) {
                  apply( Comfrey );
               }
               apply(Parksley);
            }
         }
      }
   }
}
control Mosinee {
    apply( Bosco );
}
field_list Weehawken {
    Weinert.Vernal;
    Naylor.Muncie;
    Naylor.Baudette;
    Naylor.Vallecito;
    Naylor.Annetta;
}
action Campton() {
   generate_digest(0, Weehawken);
}
field_list Montello {
    Weinert.Vernal;
    Naylor.Vallecito;
    Trona.Sieper;
    Trona.Rendon;
    Covelo.Lisle;
}
action Hercules() {
   generate_digest(0, Montello);
}
table Richlawn {
   reads {
      Weinert.Vernal : exact;
   }
   actions {
      Campton;
      Hercules;
      Buncombe;
   }
   default_action : Buncombe();
   size : 512;
}
control Woodsdale {
   if (Weinert.Vernal != 0) {
      apply( Richlawn );
   }
}
action Virgilina( Lublin, Niota ) {
   modify_field( Coolin.Moneta, Lublin );
   Wilson( Niota );
}
action Ribera( ElLago, Allons ) {
   modify_field( Coolin.Moneta, ElLago );
   Vantage( Allons );
}
action Longport( Overlea, Hooks ) {
   modify_field( Coolin.Moneta, Overlea );
   Lucile( Hooks );
}
action Hemlock( Metzger, Hettinger ) {
   modify_field( Coolin.Moneta, Metzger );
   Parmalee( Hettinger );
}
@pragma force_immediate 1
table Freehold {
   reads {
      Igloo.Bodcaw : exact;
      Coolin.Maceo mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Virgilina;
      Ribera;
      Longport;
      Hemlock;
      Buncombe;
   }
   default_action : Buncombe();
   size : 2048;
}
action Wilson( Putnam ) {
   modify_field( Naalehu.Truro, 0 );
   modify_field( Naalehu.Cutler, Putnam );
}
action Vantage( Bonilla ) {
   modify_field( Naalehu.Truro, 2 );
   modify_field( Naalehu.Cutler, Bonilla );
}
action Lucile( Ravena ) {
   modify_field( Naalehu.Truro, 3 );
   modify_field( Naalehu.Cutler, Ravena );
}
action Kulpmont( Chandalar, Airmont ) {
   modify_field( Naalehu.Truro, Chandalar );
   modify_field( Naalehu.Cutler, Airmont );
}
action Parmalee( Muenster ) {
   modify_field( Naalehu.Tatitlek, Muenster );
   modify_field( Naalehu.Truro, 1 );
}
action Rudolph(Pinecrest) {
   Wilson( Pinecrest );
}
@pragma atcam_partition_index Coolin.Moneta
@pragma atcam_number_partitions 2048
table Secaucus {
   reads {
      Coolin.Moneta mask 0x1fff: exact;
      Coolin.Maceo mask 0x000007FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Parmalee;
      Wilson;
      Vantage;
      Lucile;
      Buncombe;
   }
   default_action : Buncombe();
   size : 16384;
}
action Petrey( Camden, Lilly ) {
   modify_field( Coolin.Moneta, Camden );
   Wilson( Lilly );
}
action Norwood( Decherd, Lynndyl ) {
   modify_field( Coolin.Moneta, Decherd );
   Vantage( Lynndyl );
}
action Separ( Ahuimanu, Coronado ) {
   modify_field( Coolin.Moneta, Ahuimanu );
   Lucile( Coronado );
}
action Sandston( Tofte, Pierpont ) {
   modify_field( Coolin.Moneta, Tofte );
   Parmalee( Pierpont );
}
@pragma action_default_only Buncombe
@pragma force_immediate 1
table Loyalton {
   reads {
      Igloo.Bodcaw : exact;
      Coolin.Maceo : lpm;
   }
   actions {
      Petrey;
      Norwood;
      Separ;
      Sandston;
      Buncombe;
   }
   size : 1024;
}
@pragma atcam_partition_index Coolin.Moneta
@pragma atcam_number_partitions 1024
table Jenkins {
   reads {
      Coolin.Moneta mask 0x7FF : exact;
      Coolin.Maceo mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Wilson;
      Vantage;
      Lucile;
      Parmalee;
      Buncombe;
   }
   default_action : Buncombe();
   size : 8192;
}
@pragma action_default_only Rudolph
@pragma idletime_precision 1
@pragma force_immediate 1
table Sugarloaf {
   reads {
      Igloo.Bodcaw : exact;
      Coolin.Maceo mask 0xFFFFFFFF000000000000000000000000: lpm;
   }
   actions {
      Wilson;
      Vantage;
      Lucile;
      Parmalee;
      Rudolph;
   }
   size : 512;
   support_timeout : true;
}
@pragma action_default_only Rudolph
@pragma idletime_precision 1
@pragma force_immediate 1
table Manistee {
   reads {
      Igloo.Bodcaw : exact;
      Suffern.Lostwood : lpm;
   }
   actions {
      Wilson;
      Vantage;
      Lucile;
      Parmalee;
      Rudolph;
      Biddle;
      Buncombe;
   }
   size : 8192;
   support_timeout : true;
}
action Maybell( Browndell, Tigard ) {
   modify_field( Suffern.Millikin, Browndell );
   Wilson( Tigard );
}
action Masardis( Mattoon, Mekoryuk ) {
   modify_field( Suffern.Millikin, Mattoon );
   Vantage( Mekoryuk );
}
action Plato( TinCity, Belcourt ) {
   modify_field( Suffern.Millikin, TinCity );
   Lucile( Belcourt );
}
action Bowden( Malabar, Ledford ) {
   modify_field( Suffern.Millikin, Malabar );
   Parmalee( Ledford );
}
@pragma force_immediate 1
table Pachuta {
   reads {
      Igloo.Bodcaw : exact;
      Suffern.Lostwood : lpm;
   }
   actions {
      Maybell;
      Masardis;
      Plato;
      Bowden;
      Buncombe;
   }
   size : 10240;
}
action Biddle() {
   modify_field( Naalehu.Truro, Naalehu.Mertens );
   modify_field( Naalehu.Cutler, Naalehu.Lakebay );
   modify_field( Naylor.Tusayan, Naylor.Virginia );
}
@pragma ways 2
@pragma atcam_partition_index Suffern.Millikin
@pragma atcam_number_partitions 10240
@pragma force_immediate 1
@pragma action_default_only Buncombe
table KentPark {
   reads {
      Suffern.Millikin mask 0x7fff: exact;
      Suffern.Lostwood mask 0x000fffff : lpm;
   }
   actions {
      Wilson;
      Vantage;
      Lucile;
      Parmalee;
      Biddle;
      Buncombe;
   }
   default_action : Buncombe();
   size : 163840;
}
@pragma idletime_precision 1
@pragma force_immediate 1
@pragma ways 4
table Centre {
   reads {
      Igloo.Bodcaw : exact;
      Suffern.Lostwood : exact;
   }
   actions {
      Wilson;
      Vantage;
      Lucile;
      Parmalee;
      Buncombe;
   }
   default_action : Buncombe();
   size : 98304;
   support_timeout : true;
}
@pragma idletime_precision 1
@pragma force_immediate 1
@pragma ways 4
table Raiford {
   reads {
      Igloo.Bodcaw : exact;
      Coolin.Maceo : exact;
   }
   actions {
      Wilson;
      Vantage;
      Lucile;
      Parmalee;
      Buncombe;
   }
   default_action : Buncombe();
   size : 32768;
   support_timeout : true;
}
action Oakford(Webbville) {
   Wilson( Webbville );
}
table Yukon {
   reads {
      Igloo.DuPont mask 0x1 : exact;
      Naylor.Arroyo : exact;
   }
   actions {
      Oakford;
   }
   default_action: Oakford;
   size : 2;
}
field_list Robert {
   Kealia.VanWert;
   ig_intr_md.ingress_port;
}
field_list_calculation Zeeland {
    input {
        Robert;
    }
    algorithm : crc16_extend;
    output_width : 66;
}
action_selector Chappells {
   selection_key : Zeeland;
   selection_mode : resilient;
}
action_profile Brave {
   actions {
      Kulpmont;
   }
   size : 65536;
   dynamic_action_selection : Chappells;
}
@pragma selector_max_group_size 256
@pragma immediate 0
table Cushing {
   reads {
      Naalehu.Tatitlek mask 0x7FF: exact;
   }
   action_profile : Brave;
   size : 2048;
}
action Bladen(Woodfield) {
   modify_field(Cargray.OakCity, 1);
   modify_field(Cargray.Kelsey, Woodfield);
}
table Beaman {
   reads {
      Naalehu.Cutler mask 0xF: exact;
   }
   actions {
      Bladen;
   }
   size : 16;
}
action Crump(Quinnesec, Brothers, Hamburg) {
   modify_field(Cargray.Stone, Quinnesec);
   modify_field(Cargray.Accomac, Brothers);
   modify_field(Cargray.FortHunt, Hamburg);
}
@pragma use_hash_action 1
table Macksburg {
   reads {
      Naalehu.Cutler mask 0xFFFF : exact;
   }
   actions {
      Crump;
   }
   default_action : Crump(0,0,0);
   size : 65536;
}
@pragma use_hash_action 1
table Klondike {
   reads {
      Naalehu.Truro mask 0x1 : exact;
      Naalehu.Cutler mask 0xFFFF : exact;
   }
   actions {
      Crump;
   }
   default_action : Crump(0, 0, 0);
   size : 131072;
}
action Biloxi(Redfield, CoosBay, RockPort) {
   modify_field(Cargray.Chatom, 1);
   modify_field(Cargray.Annville, Redfield);
   modify_field(Cargray.Almeria, CoosBay);
   modify_field(Naylor.Carpenter, RockPort);
}
@pragma use_hash_action 1
table Troup {
   reads {
      Naalehu.Cutler mask 0xFFFF : exact;
   }
   actions {
      Biloxi;
   }
   default_action : Biloxi(511,0,0);
   size : 65536;
}
@pragma use_hash_action 1
table Moapa {
   reads {
      Naalehu.Truro mask 0x1 : exact;
      Naalehu.Cutler mask 0xFFFF : exact;
   }
   actions {
      Biloxi;
   }
   default_action : Biloxi(511,0,0);
   size : 131072;
}
control Arriba {
   apply( Raiford ) {
      Buncombe {
         apply( Loyalton );
      }
   }
}
control Malmo {
   apply( Centre ) {
      Buncombe {
         apply( Pachuta );
         if( Igloo.Bodcaw == 0 ) {
            apply( Borth );
         } else {
            apply( PineCity ) {
               Munich {
                  apply( Borth );
               }
            }
         }
      }
   }
}
control Seabrook {
   if ( ( ( Igloo.DuPont & ( 0x2 ) ) == ( ( 0x2 ) ) ) and ( Naylor.Arroyo == 0x2 ) and
        (LaCueva.Mission != 0) and Naylor.Nelagoney == 0 and Igloo.LongPine == 1 ) {
         apply( Raiford ) {
            Buncombe {
               apply( Loyalton );
            }
         }
   } else if ( ( ( Igloo.DuPont & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Naylor.Arroyo == 0x1 ) and
               (LaCueva.Mission != 0) and Naylor.Nelagoney == 0 ) {
         Halstead();
         if ( Igloo.LongPine == 1 ) {
            apply( Centre ) {
               Buncombe {
                  apply(Pachuta);
               }
            }
         }
  }
}
action Cartago() {
     modify_field( Naylor.Swedeborg, Naylor.Gowanda );
}
table Dixie {
   actions {
      Cartago;
   }
   default_action : Cartago();
   size : 1;
}
action LaPryor( Gillespie, Hotevilla ) {
   modify_field( Naalehu.Mertens, Gillespie );
   modify_field( Naalehu.Lakebay, Hotevilla );
}
table Borth {
   reads {
     Suffern.Lostwood : lpm;
   }
   actions {
      LaPryor;
   }
  size : 512;
}
action Munich( Tennessee ) {
   modify_field( Suffern.Mendoza, Tennessee );
   modify_field( Naylor.Virginia, 1 );
   modify_field( Naylor.Tusayan, 0 );
}
table PineCity {
   reads {
     Suffern.Mendoza : exact;
     Igloo.Bodcaw : exact;
   }
   actions {
      Munich;
   }
  size : 4096;
}
control Hookdale {
   if ( Naylor.Nelagoney == 0 and Igloo.LongPine == 1 and LaCueva.Mission != 0 ) {
      if ( ( ( Igloo.DuPont & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Naylor.Arroyo == 0x1 ) ) {
         if ( Suffern.Millikin != 0 ) {
            apply( KentPark );
         } else if ( Naalehu.Cutler == 0 ) {
            apply( Manistee );
         }
      } else if ( ( ( Igloo.DuPont & ( 0x2 ) ) == ( ( 0x2 ) ) ) and Naylor.Arroyo == 0x2 ) {
         if ( Coolin.Moneta != 0 ) {
            apply( Jenkins );
         } else if ( Naalehu.Cutler == 0 ) {
            apply( Freehold );
            if ( Coolin.Moneta != 0 ) {
               apply( Secaucus );
            } else if ( Naalehu.Cutler == 0 ) {
               apply( Sugarloaf );
            }
         }
      } else if ( ( Cargray.OakCity == 0 ) and ( ( Naylor.Delmont == 1 ) or
            ( ( ( Igloo.DuPont & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Naylor.Arroyo == 0x3 ) ) ) ) {
         apply( Yukon );
      }
   }
}
control Missoula {
   if ( Naalehu.Truro == 1 ) {
      apply( Cushing );
   }
}
control Nathan {
   if( Naalehu.Cutler != 0 ) {
      apply( Dixie );
      if( ( ( Naalehu.Cutler & 0xFFF0 ) == 0 ) ) {
         apply( Beaman );
      } else {
         if( Naalehu.Truro == 0 ) {
            apply( Troup );
         } else {
            apply( Moapa );
         }
      }
   }
}
control Rushton {
   if( Naalehu.Cutler != 0 ) {
      if( Naalehu.Truro == 0 ) {
         apply( Macksburg );
      }
   }
}
control Moraine {
   if( Naalehu.Cutler != 0 ) {
      if( Naalehu.Truro != 0 ) {
         apply( Klondike );
      }
   }
}
action Yorklyn( Parmerton ) {
   modify_field( Naylor.Hartwell, Parmerton );
}
action Ironia() {
   modify_field( Naylor.Conejo, 1 );
}
table Yaurel {
   reads {
      Naylor.Arroyo : exact;
      Naylor.Cotuit : exact;
      Covelo.Portal mask 0x3FFF: ternary;
      Waiehu.Lathrop mask 0x3FFF: ternary;
   }
   actions {
      Yorklyn;
      Ironia;
   }
   default_action : Ironia();
   size : 512;
}
control Tanana {
   apply( Yaurel );
}
action Sarepta( Hitchland ) {
   modify_field( Cargray.OakCity, 1 );
   modify_field( Cargray.Kelsey, Hitchland );
}
action Coalwood() {
}
table Hagewood {
   reads {
      Naylor.Conejo : exact;
      Naylor.Hartwell : ternary;
      Naylor.Carpenter : ternary;
   }
   actions {
      Sarepta;
      Coalwood;
   }
   default_action : Coalwood;
   size : 512;
}
control Milbank {
   if( Cargray.Chatom == 1 ) {
      apply( Hagewood );
   }
}
field_list Rohwer {
   Kealia.Laneburg;
   ig_intr_md.ingress_port;
}
field_list_calculation Chatcolet {
    input {
        Rohwer;
    }
    algorithm : crc16_extend;
    output_width : 51;
}
action_selector Yantis {
    selection_key : Chatcolet;
    selection_mode : resilient;
}
action Nuremberg(Hayfield) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Hayfield);
   bit_or( Cargray.Camanche, Cargray.Camanche, Cargray.Rockfield );
}
action Bammel() {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, Cargray.Annville);
   bit_or( Cargray.Camanche, Cargray.Camanche, Cargray.Rockfield );
}
action Greenlawn() {
   bit_or( Cargray.Camanche, Cargray.Camanche, Cargray.Rockfield );
}
action_profile Luzerne {
    actions {
        Nuremberg;
        Bammel;
        Greenlawn;
        Buncombe;
    }
    size : 32768;
    dynamic_action_selection : Yantis;
}
table Gomez {
   reads {
      Cargray.Annville : ternary;
   }
   action_profile: Luzerne;
   size : 258;
}
control Hayfork {
   apply(Gomez);
}
@pragma pa_no_init ingress Cargray.Annville
@pragma pa_no_init ingress Cargray.Almeria
@pragma pa_no_init ingress ig_intr_md_for_tm.ucast_egress_port
action WolfTrap(Golden) {
   modify_field(Cargray.McCaskill, LaCueva.Mission );
   modify_field(Cargray.Stone, Naylor.Greenhorn);
   modify_field(Cargray.Accomac, Naylor.Medart);
   modify_field(Cargray.Belview, Naylor.Muncie);
   modify_field(Cargray.Newtown, Naylor.Baudette);
   modify_field(Cargray.FortHunt, Naylor.Vallecito);
   modify_field(Cargray.Annville, Golden);
   modify_field(Cargray.Almeria, 0);
   bit_not(ig_intr_md_for_tm.ucast_egress_port, 0);
   bit_or( Naylor.Gowanda, Naylor.Gowanda, Naylor.Haley );
}
@pragma use_hash_action 1
table Euren {
   reads {
      Anandale.valid : exact;
   }
   actions {
      WolfTrap;
   }
   default_action : WolfTrap(511);
   size : 2;
}
control Kerby {
   apply( Euren );
}
action Garrison() {
   modify_field( Cargray.Homeacre, Naylor.Jelloway );
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Naylor.Delmont);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Cargray.FortHunt);
}
action Westbrook() {
   add(ig_intr_md_for_tm.mcast_grp_a, Cargray.FortHunt, 4096);
   modify_field( Naylor.Fowler, 1 );
   modify_field( Cargray.Homeacre, Naylor.Jelloway );
}
action Ryderwood() {
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Cargray.FortHunt);
   modify_field( Cargray.Homeacre, Naylor.Jelloway );
}
table Achilles {
   reads {
      Cargray.Stone : ternary;
      Cargray.Accomac : ternary;
   }
   actions {
      Garrison;
      Westbrook;
   }
   default_action : Ryderwood();
   size : 4;
}
action Markville(Florahome) {
   modify_field(Cargray.Annville, Florahome);
}
action Suring(Greer, Crouch) {
   modify_field(Cargray.Almeria, Crouch);
   Markville(Greer);
   modify_field(Cargray.RedElm, 5);
}
action Asherton(Padonia) {
   modify_field(Cargray.FourTown, Padonia);
}
action Exeter() {
   modify_field( Naylor.Eaton, 1 );
}
table Boutte {
   reads {
      Cargray.Stone : exact;
      Cargray.Accomac : exact;
      Cargray.FortHunt : exact;
   }
   actions {
      Markville;
      Asherton;
      Suring;
      Exeter;
      Buncombe;
   }
   default_action : Buncombe();
   size : 16384;
}
control Cabery {
   apply(Boutte) {
      Buncombe {
         apply(Achilles);
      }
   }
}
field_list Balmville {
   Kealia.Laneburg;
}
field_list_calculation Lowemont {
    input {
        Balmville;
    }
    algorithm : identity;
    output_width : 51;
}
action Comptche( Folkston, Littleton ) {
   modify_field( Cargray.Camanche, Cargray.Annville );
   modify_field( Cargray.Rockfield, Littleton );
   modify_field( Cargray.Annville, Folkston );
   modify_field( Cargray.RedElm, 5 );
   modify_field( ig_intr_md_for_tm.disable_ucast_cutthru, 1 );
}
action_selector Mentone {
    selection_key : Lowemont;
    selection_mode : resilient;
}
action_profile Sneads {
    actions {
       Comptche;
    }
    size : 1024;
    dynamic_action_selection : Mentone;
}
@pragma ways 2
table Eggleston {
   reads {
      Cargray.Almeria : exact;
   }
   action_profile : Sneads;
   size : 512;
}
action Finney() {
   modify_field( Naylor.Alstown, 1 );
}
table Cochise {
   actions {
      Finney;
   }
   default_action : Finney;
   size : 1;
}
action Floris() {
   modify_field( Naylor.Kalvesta, 1 );
}
table Ruston {
   reads {
      Cargray.Annville mask 0x7FF : exact;
   }
   actions {
      Clementon;
      Floris;
   }
   default_action : Clementon;
   size : 258;
}
control Sanatoga {
   if ((Naylor.Nelagoney == 0) and (Cargray.Chatom==0) and (Naylor.Fowler==0)
       and (Naylor.OjoFeliz==0)) {
      if ((Naylor.Annetta==Cargray.Annville) or ((Cargray.Zebina == 1) and (Cargray.RedElm == 5))) {
         apply(Cochise);
      } else if (LaCueva.Mission==2 and
                 ((Cargray.Annville & 0xFF800) ==
                   0x3800)) {
         apply(Ruston);
      }
   }
   apply(Eggleston);
}
action Lewiston( Hernandez ) {
   modify_field( Cargray.Freedom, Hernandez );
}
action Sturgeon( Nuyaka ) {
   modify_field( Cargray.Freedom, Nuyaka );
   modify_field( Cargray.Gasport, 1 );
}
action Burgess() {
   modify_field( Cargray.Freedom, Cargray.FortHunt );
}
table Cathcart {
   reads {
      eg_intr_md.egress_port : exact;
      Cargray.FortHunt : exact;
   }
   actions {
      Lewiston;
      Sturgeon;
      Burgess;
   }
   default_action : Burgess;
   size : 4096;
}
control Ancho {
   apply( Cathcart );
}
action Gibbs( Farlin, Runnemede ) {
   modify_field( Cargray.Eustis, Farlin );
   modify_field( Cargray.Pajaros, Runnemede );
}
action Stewart( Gracewood, Cliffs, Donald, Disney, Wainaku ) {
   modify_field( Cargray.Eustis, Gracewood );
   modify_field( Cargray.Pajaros, Cliffs );
   modify_field( Cargray.Sagerton, Donald );
   modify_field( Cargray.Millwood, Disney );
   add_to_field( eg_intr_md.pkt_length, Wainaku );
}
action Wartburg( Horns, Auberry ) {
   modify_field( Cargray.Eustis, Horns );
   modify_field( Cargray.Pajaros, Auberry );
}
@pragma no_egress_length_correct 1
@pragma ternary 1
table Sherack {
   reads {
      Cargray.Zebina : ternary;
      Cargray.RedElm : exact;
      Cargray.Calumet : ternary;
   }
   actions {
      Gibbs;
      Stewart;
      Wartburg;
   }
   size : 8;
}
action Islen( Boerne ) {
   modify_field( Cargray.Calamus, 1 );
   modify_field( Cargray.RedElm, 2 );
   modify_field( Cargray.Tonkawa, Boerne );
   modify_field( Cargray.Ladoga, 0);
}
@pragma ternary 1
table Lanesboro {
   reads {
      eg_intr_md.egress_port : exact;
      LaCueva.Timken : exact;
      Cargray.Calumet : exact;
   }
   actions {
      Islen;
   }
   default_action : Buncombe();
   size : 16;
}
action Remington(Vinemont, Baroda, Pilottown, Maysfield) {
   modify_field( Cargray.Osyka, Vinemont );
   modify_field( Cargray.Vining, Baroda );
   modify_field( Cargray.Spanaway, Pilottown );
   modify_field( Cargray.Puryear, Maysfield );
}
@pragma ternary 1
table Frewsburg {
   reads {
        Cargray.Pinebluff : exact;
   }
   actions {
      Remington;
   }
   size : 512;
}
action Struthers( Cullen ) {
   modify_field( Cargray.Junior, Cullen );
}
@pragma use_hash_action 1
table MiraLoma {
   reads {
      Cargray.Camanche mask 0x1ffff : exact;
   }
   actions {
      Struthers;
   }
   default_action : Struthers(0);
   size : 131072;
}
@pragma use_hash_action 1
table Madeira {
   reads {
      Cargray.Camanche mask 0xFFFF : exact;
   }
   actions {
      Struthers;
   }
   default_action : Struthers(0);
   size : 65536;
}
action Provencal( Newpoint, Harris, Micco ) {
   modify_field( Cargray.Hilburn, Newpoint );
   modify_field( Cargray.Wakenda, Harris );
   modify_field( Cargray.FortHunt, Micco );
}
table Darco {
   reads {
      Cargray.Camanche mask 0xFF000000: exact;
   }
   actions {
      Provencal;
   }
   default_action : Provencal(0,0,0);
   size : 256;
}
action Boquillas( Rocheport ) {
   modify_field( Cargray.Naches, Rocheport );
}
table Onslow {
   reads {
      Cargray.FortHunt mask 0xFFF : exact;
   }
   actions {
      Boquillas;
   }
   default_action : Boquillas( 0 );
   size : 4096;
}
action Excello( Dunnellon, Brookneal, LaPlant, Robins, McCaulley ) {
   Struthers( Dunnellon );
   Provencal( Brookneal, LaPlant, Robins );
   modify_field( Cargray.RedElm, McCaulley );
}
table Coyote {
   reads {
     eg_intr_md.egress_rid: exact;
   }
   actions {
      Excello;
   }
  default_action: Buncombe();
  size : 4096;
}
control Aptos {
   if( ( Cargray.Camanche & 0x60000 ) == 0x60000 ) {
      apply( Madeira );
   }
   if( ( Cargray.Camanche & 0x60000 ) == 0x40000 ) {
      apply( MiraLoma );
   }
   apply( Onslow );
}
control Pickering {
   if( Cargray.Camanche != 0 ) {
      apply( Darco );
   }
}
action Sublett() {
   no_op();
}
action Lovilia() {
   modify_field( Anandale.Goodlett, Emden[0].Averill );
   remove_header( Emden[0] );
}
table Marshall {
   actions {
      Lovilia;
   }
   default_action : Lovilia;
   size : 1;
}
action Brookland() {
   no_op();
}
action Hookstown() {
   add_header( Emden[ 0 ] );
   modify_field( Emden[0].Blackwood, Cargray.Freedom );
   modify_field( Emden[0].Averill, Anandale.Goodlett );
   modify_field( Emden[0].Selawik, LaVale.Kansas );
   modify_field( Emden[0].Gobler, LaVale.Sparr );
   modify_field( Anandale.Goodlett, 0x8100 );
}
@pragma ways 2
table Salamonia {
   reads {
      Cargray.Freedom : exact;
      eg_intr_md.egress_port mask 0x7f : exact;
   }
   actions {
      Brookland;
      Hookstown;
   }
   default_action : Hookstown;
   size : 128;
}
action Onawa() {
   modify_field(Anandale.ElMango, Cargray.Stone);
   modify_field(Anandale.Monahans, Cargray.Accomac);
   modify_field(Anandale.Sieper, Cargray.Eustis);
   modify_field(Anandale.Rendon, Cargray.Pajaros);
}
action Sterling() {
   Onawa();
   modify_field(Covelo.Chatawa, Suffern.Lostwood);
   modify_field(Covelo.Lisle, Suffern.Mendoza);
   add_to_field(Covelo.Biggers, -1);
}
action Amesville() {
   Onawa();
   add_to_field(Waiehu.Riverbank, -1);
}
action Farragut() {
   modify_field(Covelo.Chatawa, Suffern.Lostwood);
   modify_field(Covelo.Lisle, Suffern.Mendoza);
}
action Skokomish() {
   Hookstown();
}
@pragma pa_no_init egress Callao.ElMango
@pragma pa_no_init egress Callao.Monahans
@pragma pa_no_init egress Callao.Sieper
@pragma pa_no_init egress Callao.Rendon
@pragma pa_no_init egress Callao.Goodlett
@pragma pa_no_init egress Larchmont.Absecon
@pragma pa_no_init egress Larchmont.Upland
@pragma pa_no_init egress Larchmont.Catawba
@pragma pa_no_init egress Larchmont.Florien
@pragma pa_no_init egress Larchmont.Worland
@pragma pa_no_init egress Larchmont.Energy
@pragma pa_no_init egress Larchmont.Hackamore
@pragma pa_no_init egress Larchmont.Lakehurst
@pragma pa_no_init egress Larchmont.Tarnov
action Crary( Burmester, Caplis, Castolon, Catlin, Tannehill ) {
   add_header( Callao );
   modify_field( Callao.ElMango, Burmester );
   modify_field( Callao.Monahans, Caplis );
   modify_field( Callao.Sieper, Castolon );
   modify_field( Callao.Rendon, Catlin );
   modify_field( Callao.Goodlett, 0xBF00 );
   add_header( Larchmont );
   modify_field( Larchmont.Absecon, Cargray.Osyka );
   modify_field( Larchmont.Upland, Cargray.Vining );
   modify_field( Larchmont.Catawba, Cargray.Spanaway );
   modify_field( Larchmont.Florien, Cargray.Puryear );
   modify_field( Larchmont.Worland, Cargray.Bangor );
   modify_field( Larchmont.Energy, Tannehill );
   modify_field( Larchmont.Hackamore, Naylor.Vallecito );
   modify_field( Larchmont.Lakehurst, Cargray.Tonkawa );
   modify_field( Larchmont.Tarnov, Cargray.Ladoga );
}
action Westline( Venturia, Groesbeck, Bosworth, Fackler ) {
   Crary( Venturia, Groesbeck, Bosworth, Fackler, Cargray.Kelsey );
}
action Nathalie() {
   modify_field( Anandale.ElMango, Anandale.ElMango );
   no_op();
}
action Montezuma() {
   add_header( Anandale );
   modify_field( Anandale.ElMango, Cargray.Stone );
   modify_field( Anandale.Monahans, Cargray.Accomac );
   modify_field( Anandale.Sieper, Cargray.Eustis );
   modify_field( Anandale.Rendon, Cargray.Pajaros );
   modify_field( Anandale.Goodlett, 0x0800 );
}
action Nucla() {
   remove_header( Illmo );
   remove_header( Motley );
   remove_header( Blakeslee );
   copy_header( Anandale, Trona );
   remove_header( Trona );
   remove_header( Covelo );
}
action Olmitz( Ocilla, Doerun, Guayabal, Rockleigh, Woolwine ) {
   Nucla();
   Crary( Ocilla, Doerun, Guayabal, Rockleigh, Woolwine );
}
action Ballville() {
   remove_header( Illmo );
   remove_header( Motley );
   remove_header( Blakeslee );
   remove_header( Covelo );
   modify_field( Anandale.ElMango, Cargray.Stone );
   modify_field( Anandale.Monahans, Cargray.Accomac );
   modify_field( Anandale.Sieper, Cargray.Eustis );
   modify_field( Anandale.Rendon, Cargray.Pajaros );
   modify_field( Anandale.Goodlett, Trona.Goodlett );
   remove_header( Trona );
}
action Fairfield() {
   Ballville();
   add_to_field( Varnell.Biggers, -1 );
}
action Egypt() {
   Ballville();
   add_to_field( Harvest.Riverbank, -1 );
}
action Saugatuck() {
   modify_field( Anandale.Monahans, Anandale.Monahans );
}
action Westboro( Tallassee ) {
   modify_field( Varnell.Amazonia, Covelo.Amazonia );
   modify_field( Varnell.Morita, Covelo.Morita );
   modify_field( Varnell.Mullins, Covelo.Mullins );
   modify_field( Varnell.Brockton, Covelo.Brockton );
   modify_field( Varnell.Portal, Covelo.Portal );
   modify_field( Varnell.Orrville, Covelo.Orrville );
   modify_field( Varnell.Hagaman, Covelo.Hagaman );
   modify_field( Varnell.Grants, Covelo.Grants );
   add( Varnell.Biggers, Covelo.Biggers, Tallassee );
   modify_field( Varnell.Arthur, Covelo.Arthur );
   modify_field( Varnell.Lisle, Covelo.Lisle );
   modify_field( Varnell.Chatawa, Covelo.Chatawa );
}
action Shubert( Tonasket, Shuqualak, Almedia, Cowen ) {
   modify_field( Trona.ElMango, Cargray.Stone );
   modify_field( Trona.Monahans, Cargray.Accomac );
   modify_field( Trona.Sieper, Almedia );
   modify_field( Trona.Rendon, Cowen );
   add( Motley.Sedona, Tonasket, Shuqualak );
   modify_field( Motley.PineLake, 0 );
   modify_field( Blakeslee.Mogadore, Cargray.Millwood );
   bit_or( Blakeslee.Justice, Kealia.Laneburg, 0xC000 );
   modify_field( Illmo.Renick, 0x8 );
   modify_field( Illmo.Monmouth, 0 );
   modify_field( Illmo.Canovanas, Cargray.Naches );
   modify_field( Illmo.Konnarock, Cargray.Wheeling );
   modify_field( Anandale.ElMango, Cargray.Hilburn );
   modify_field( Anandale.Monahans, Cargray.Wakenda );
   modify_field( Anandale.Sieper, Cargray.Eustis );
   modify_field( Anandale.Rendon, Cargray.Pajaros );
}
action Charco( Jefferson, Whiteclay, McKamie, Bostic, Masontown ) {
   add_header( Trona );
   add_header( Motley );
   add_header( Blakeslee );
   add_header( Illmo );
   modify_field( Trona.Goodlett, Anandale.Goodlett );
   Shubert( Jefferson, Whiteclay, Bostic, Masontown );
   Kotzebue( Jefferson, McKamie );
}
action Kotzebue( Ruthsburg, Jericho ) {
   modify_field( Covelo.Amazonia, 0x4 );
   modify_field( Covelo.Morita, 0x5 );
   modify_field( Covelo.Mullins, 0 );
   modify_field( Covelo.Brockton, 0 );
   add( Covelo.Portal, Ruthsburg, Jericho );
   modify_field( Covelo.Orrville, eg_intr_md_from_parser_aux.egress_global_tstamp, 0xFFFF );
   modify_field( Covelo.Hagaman, 0x2 );
   modify_field( Covelo.Grants, 0 );
   modify_field( Covelo.Biggers, 64 );
   modify_field( Covelo.Arthur, 17 );
   modify_field( Covelo.Lisle, Cargray.Sagerton );
   modify_field( Covelo.Chatawa, Cargray.Junior );
   modify_field( Anandale.Goodlett, 0x0800 );
}
action Wilmore() {
   add_header( Varnell );
   Westboro( -1 );
   Charco( Covelo.Portal, 30, 50,
                         Cargray.Eustis, Cargray.Pajaros );
}
action Monico() {
   add_header( Varnell );
   Westboro( 0 );
   Coconino();
}
action Loveland( Roosville ) {
   modify_field( Harvest.Dorothy, Waiehu.Dorothy );
   modify_field( Harvest.Fennimore, Waiehu.Fennimore );
   modify_field( Harvest.Bellmore, Waiehu.Bellmore );
   modify_field( Harvest.Krupp, Waiehu.Krupp );
   modify_field( Harvest.Lathrop, Waiehu.Lathrop );
   modify_field( Harvest.RockHall, Waiehu.RockHall );
   modify_field( Harvest.Gould, Waiehu.Gould );
   modify_field( Harvest.Bavaria, Waiehu.Bavaria );
   add( Harvest.Riverbank, Waiehu.Riverbank, Roosville );
}
action Vergennes() {
   add_header( Harvest );
   Loveland( -1 );
   add_header( Covelo );
   Charco( eg_intr_md.pkt_length, 12, 32,
                            Cargray.Eustis, Cargray.Pajaros );
   remove_header( Waiehu );
}
action Rattan() {
   add_header( Harvest );
   Loveland( 0 );
   remove_header( Waiehu );
   Coconino();
}
action Coconino() {
   add_header( Covelo );
   Charco( eg_intr_md.pkt_length, 12, 32,
                            Anandale.Sieper, Anandale.Rendon );
}
action Billings( Redvale, Challis ) {
   Shubert( Motley.Sedona, 0, Redvale, Challis );
   Kotzebue( Covelo.Portal, 0 );
}
action MintHill() {
   Billings( Cargray.Eustis, Cargray.Pajaros );
   add_to_field( Varnell.Biggers, -1 );
}
action Plateau() {
   Billings( Cargray.Eustis, Cargray.Pajaros );
   add_to_field( Harvest.Riverbank, -1 );
}
table Kenyon {
   reads {
      Cargray.Zebina : exact;
      Cargray.RedElm : exact;
      Cargray.Chatom : exact;
      Covelo.valid : ternary;
      Waiehu.valid : ternary;
      Varnell.valid : ternary;
      Harvest.valid : ternary;
   }
   actions {
      Sterling;
      Amesville;
      Farragut;
      Olmitz;
      Skokomish;
      Westline;
      Saugatuck;
      Nucla;
      Fairfield;
      Egypt;
      MintHill;
      Plateau;
      Monico;
      Rattan;
      Wilmore;
      Vergennes;
      Coconino;
      Montezuma;
      Nathalie;
   }
   size : 512;
}
control Oketo {
   apply( Marshall );
}
control Estrella {
   apply( Salamonia );
}
action Langhorne() {
   drop();
}
table Hillister {
   reads {
        Cargray.McCaskill : exact;
        eg_intr_md.egress_port mask 0x7F: exact;
   }
   actions {
      Langhorne;
   }
   size : 512;
}
control Franktown {
   apply( Lanesboro ) {
      Buncombe {
         apply( Sherack );
      }
   }
   apply( Frewsburg );
   if( Cargray.Chatom == 0 and Cargray.Zebina == 0 and Cargray.RedElm == 0 ) {
      apply( Hillister );
   }
   apply( Kenyon );
}
@pragma pa_no_init ingress LaVale.Saranap
@pragma pa_no_init ingress LaVale.Steger
@pragma pa_no_init ingress LaVale.Shoup
@pragma pa_no_init ingress LaVale.Kansas
@pragma pa_no_init ingress LaVale.Shauck
action Leesport( Natalbany, Telegraph, Falls ) {
   modify_field( LaVale.Saranap, Natalbany );
   modify_field( LaVale.Steger, Telegraph );
   modify_field( LaVale.Shoup, Falls );
}
table Sprout {
   reads {
     ig_intr_md.ingress_port : exact;
   }
   actions {
      Leesport;
   }
   default_action : Leesport(0, 0, 0);
   size : 512;
}
action Kewanee(Montour) {
   modify_field( LaVale.Kansas, Montour );
}
action Rembrandt(Onley) {
   modify_field( LaVale.Kansas, Onley );
   modify_field( Naylor.Woodstown, Emden[0].Averill );
}
action Jesup() {
   modify_field( LaVale.Shauck, LaVale.Steger );
}
action Bushland() {
   modify_field( LaVale.Shauck, 0 );
}
action Barnhill() {
   modify_field( LaVale.Shauck, Suffern.Kinney );
}
action BigArm() {
   modify_field( LaVale.Shauck, Oshoto.Lewis );
}
action Gosnell() {
   modify_field( LaVale.Shauck, Coolin.Galestown );
}
action HornLake( IttaBena, Purves ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, IttaBena );
   modify_field( ig_intr_md_for_tm.qid, Purves );
}
table Fiftysix {
   reads {
     Naylor.Norland : exact;
     LaVale.Saranap : exact;
     Emden[0].Selawik : exact;
   }
   actions {
     Kewanee;
     Rembrandt;
   }
   size : 128;
}
table Mustang {
   reads {
     Cargray.Zebina : exact;
     Naylor.Arroyo : exact;
   }
   actions {
     Jesup;
     Bushland;
     Barnhill;
     BigArm;
     Gosnell;
   }
   size : 14;
}
@pragma pa_no_init ingress ig_intr_md_for_tm.ingress_cos
@pragma pa_no_init ingress ig_intr_md_for_tm.qid
table Calcium {
   reads {
      LaVale.Shoup : ternary;
      LaVale.Saranap : ternary;
      LaVale.Kansas : ternary;
      LaVale.Shauck : ternary;
      LaVale.ElDorado : ternary;
      Cargray.Zebina : ternary;
      Larchmont.Scherr : ternary;
      Larchmont.WestBend : ternary;
   }
   actions {
      HornLake;
   }
   default_action : HornLake( 0, 0 );
   size : 305;
}
action Umkumiut( Adamstown, McHenry ) {
   modify_field( LaVale.Luhrig, Adamstown );
   modify_field( LaVale.Torrance, McHenry );
}
table Pollard {
   actions {
      Umkumiut;
   }
   default_action : Umkumiut;
   size : 1;
}
action Heppner( Ahmeek ) {
   modify_field( LaVale.Shauck, Ahmeek );
}
action Swaledale( McGonigle ) {
   modify_field( LaVale.Kansas, McGonigle );
}
action Coventry( Lewellen, Alsea ) {
   modify_field( LaVale.Kansas, Lewellen );
   modify_field( LaVale.Shauck, Alsea );
}
@pragma ternary 1
table Bozar {
   reads {
      LaVale.Shoup : exact;
      LaVale.Luhrig : exact;
      LaVale.Torrance : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
      Cargray.Zebina : exact;
   }
   actions {
      Heppner;
      Swaledale;
      Coventry;
   }
   size : 1024;
}
action Neshaminy( Quivero ) {
   modify_field( LaVale.Perdido, Quivero );
}
@pragma ternary 1
table Lawnside {
   reads {
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Neshaminy;
   }
   size : 8;
}
action Renton() {
   modify_field( Covelo.Mullins, LaVale.Shauck );
}
action Caputa() {
   modify_field( Waiehu.Fennimore, LaVale.Shauck );
}
action Upalco() {
   modify_field( Varnell.Mullins, LaVale.Shauck );
}
action Homeworth() {
   modify_field( Harvest.Fennimore, LaVale.Shauck );
}
action Beresford() {
   modify_field( Covelo.Mullins, LaVale.Perdido );
}
action Helton() {
   Beresford();
   modify_field( Varnell.Mullins, LaVale.Shauck );
}
action Leacock() {
   Beresford();
   modify_field( Harvest.Fennimore, LaVale.Shauck );
}
table Notus {
   reads {
      Cargray.RedElm : ternary;
      Cargray.Zebina : ternary;
      Cargray.Chatom : ternary;
      Covelo.valid : ternary;
      Waiehu.valid : ternary;
      Varnell.valid : ternary;
      Harvest.valid : ternary;
   }
   actions {
      Renton;
      Caputa;
      Upalco;
      Homeworth;
      Beresford;
      Helton;
      Leacock;
   }
   size : 7;
}
control Bufalo {
   apply( Sprout );
}
control Safford {
   apply( Fiftysix );
   apply( Mustang );
}
control Monetta {
   apply( Calcium );
}
control Poulan {
   apply( Pollard );
   apply( Bozar );
}
control Hiwasse {
   apply( Lawnside );
}
control Wyarno {
   apply( Notus );
}
action Laurelton( Evelyn ) {
   modify_field( LaVale.Northway, Evelyn );
}
table Hitterdal {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
   }
   actions {
      Laurelton;
   }
}
action Ledoux( Philbrook ) {
   modify_field( LaVale.Brundage, Philbrook );
}
table Wayzata {
   reads {
      Naylor.Woodstown : ternary;
      Naylor.OjoFeliz : ternary;
      Cargray.Accomac : ternary;
      Cargray.Stone : ternary;
      Naalehu.Truro : ternary;
      Naalehu.Cutler : ternary;
      Cargray.Zebina : ternary;
      Cargray.Homeacre : ternary;
   }
   actions {
      Ledoux;
   }
   default_action: Ledoux;
   size : 512;
}
table Sebewaing {
   reads {
      Naylor.Arroyo : ternary;
      Naylor.OjoFeliz : ternary;
      Suffern.Lostwood : ternary;
      Coolin.Maceo mask 0xffff0000000000000000000000000000 : ternary;
      Naylor.Bovina : ternary;
      Naylor.HillCity : ternary;
      Cargray.Chatom : ternary;
      Naalehu.Truro : ternary;
      Naalehu.Cutler : ternary;
      Blakeslee.Justice : ternary;
      Blakeslee.Mogadore : ternary;
      Naylor.Conejo : ternary;
      Naylor.Hartwell : ternary;
      Naylor.Carpenter : ternary;
      Cargray.Zebina : ternary;
      Cargray.Homeacre : ternary;
   }
   actions {
      Ledoux;
   }
   default_action: Ledoux;
   size : 512;
}
meter Weyauwega {
   type : bytes;
   static : Nondalton;
   instance_count : 4096;
}
counter Wyocena {
   type : packets;
   static : Nondalton;
   instance_count : 4096;
   min_width : 64;
}
field_list Sofia {
   ig_intr_md.ingress_port;
   LaVale.Brundage;
}
field_list_calculation Temple {
    input { Sofia; }
    algorithm: identity;
    output_width: 12;
}
action National() {
   count_from_hash( Wyocena, Temple );
}
action Riverland(Moultrie) {
   execute_meter( Weyauwega, Moultrie, ig_intr_md_for_tm.drop_ctl );
}
action Rawlins(Monowi) {
   Riverland(Monowi);
   National();
}
table Nondalton {
   reads {
      LaVale.Northway : exact;
      LaVale.Brundage : exact;
   }
   actions {
     National;
     Rawlins;
   }
   size : 512;
}
control Pelion {
   apply( Hitterdal );
}
control Roberta {
      if ( Naylor.Arroyo == 0 ) {
         apply( Wayzata );
      } else {
         apply( Sebewaing );
      }
}
@pragma pa_mutually_exclusive ingress Cargray.Pinebluff ig_intr_md.ingress_port
@pragma pa_no_init ingress Cargray.Calumet
@pragma pa_no_init ingress Cargray.Pinebluff
action Prismatic( Havana, Lasara ) {
   modify_field( Cargray.Pinebluff, ig_intr_md.ingress_port );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Havana );
   modify_field( ig_intr_md_for_tm.qid, Lasara );
}
action Tobique() {
   modify_field( Cargray.Pinebluff, ig_intr_md.ingress_port );
}
action Perrytown( Salome, Subiaco ) {
   Prismatic( Salome, Subiaco );
   modify_field( Cargray.Calumet, 0);
}
action Lindsay() {
   Tobique();
   modify_field( Cargray.Calumet, 0);
}
action Pinesdale( Sylva, Hagerman ) {
   Prismatic( Sylva, Hagerman );
   modify_field( Cargray.Calumet, 1);
}
action Eastman() {
   Tobique();
   modify_field( Cargray.Calumet, 1);
}
action Slana( Pierre, Throop ) {
   Pinesdale( Pierre, Throop );
   modify_field(Naylor.Vallecito, Emden[0].Blackwood);
}
action Kaltag() {
   Eastman();
   modify_field(Naylor.Vallecito, Emden[0].Blackwood);
}
table Rosburg {
   reads {
      Cargray.OakCity : exact;
      Emden[0] : valid;
      LaCueva.Timken : ternary;
      Cargray.Kelsey : ternary;
   }
   actions {
      Perrytown;
      Lindsay;
      Pinesdale;
      Eastman;
      Slana;
      Kaltag;
   }
   default_action : Eastman();
   size : 512;
}
control Sully {
   apply( Rosburg ) {
      Perrytown {
      }
      Pinesdale {
      }
      Slana {
      }
      default {
         Hayfork();
      }
   }
}
counter Tyrone {
   type : packets_and_bytes;
   static : Sidon;
   instance_count : 4096;
   min_width : 128;
}
field_list Wapinitia {
   eg_intr_md.egress_port;
   eg_intr_md.egress_qid;
}
field_list_calculation Sisters {
    input { Wapinitia; }
    algorithm: identity;
    output_width: 12;
}
action Sargent() {
   count_from_hash( Tyrone, Sisters );
}
table Sidon {
   actions {
      Sargent;
   }
   default_action : Sargent;
   size : 1;
}
control Cleta {
   apply( Sidon );
}
action Sandoval()
{
   modify_field( Naylor.Evansburg, 1 );
}
action Overbrook() {
   remove_header(Larchmont);
}
action Magazine() {
   Overbrook();
   modify_field(Cargray.Zebina, 3);
   modify_field( Naylor.Asher, 0 );
   modify_field( Naylor.Delmont, 0 );
}
action Lamine( Valier ) {
   Overbrook();
   modify_field(Cargray.Zebina, 2);
   modify_field(Cargray.Annville, Valier);
   modify_field(Cargray.FortHunt, Naylor.Vallecito );
   modify_field(Cargray.Almeria, 0);
}
@pragma ternary 1
table Lilbert {
   reads {
      Larchmont.Absecon : exact;
      Larchmont.Upland : exact;
      Larchmont.Catawba : exact;
      Larchmont.Florien : exact;
      Cargray.Zebina : ternary;
   }
   actions {
      Lamine;
      Magazine;
      Sandoval;
      Overbrook;
   }
   default_action : Sandoval();
   size : 1024;
}
control Hahira {
   apply( Lilbert );
}
action Spalding( Floral, Speed, Locke, Alabaster ) {
   modify_field( RoseBud.Walland, Floral );
   modify_field( Baird.Gambrills, Locke );
   modify_field( Baird.Wakita, Speed );
   modify_field( Baird.Ralls, Alabaster );
}
@pragma ways 2
table Winside {
   reads {
     Suffern.Lostwood : exact;
     Naylor.Tehachapi : exact;
   }
   actions {
      Spalding;
   }
  size : 16384;
}
action Vesuvius(Lizella, Valmont, Poteet) {
   modify_field( Baird.Wakita, Lizella );
   modify_field( Baird.Gambrills, Valmont );
   modify_field( Baird.Ralls, Poteet );
}
@pragma ways 2
table Riner {
   reads {
     Suffern.Mendoza : exact;
     RoseBud.Walland : exact;
   }
   actions {
      Vesuvius;
   }
   size : 16384;
}
action Oakes( Millbrook, Glenoma, Cropper ) {
   modify_field( Kingman.Taopi, Millbrook );
   modify_field( Kingman.Cimarron, Glenoma );
   modify_field( Kingman.Lopeno, Cropper );
}
@pragma ways 2
table Cowden {
   reads {
     Cargray.Stone : exact;
     Cargray.Accomac : exact;
     Cargray.FortHunt : exact;
   }
   actions {
      Oakes;
   }
   size : 16384;
}
action Wyandanch() {
}
action Destin( Eugene ) {
   Wyandanch();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Baird.Wakita );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Eugene, Baird.Ralls );
}
action Monaca( Stanwood ) {
   Wyandanch();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Kingman.Taopi );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Stanwood, Kingman.Lopeno );
}
action Palomas( Osseo ) {
   Wyandanch();
   add( ig_intr_md_for_tm.mcast_grp_a, Cargray.FortHunt,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Osseo );
}
action Grinnell( Dillsboro ) {
   Wyandanch();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Cargray.FortHunt );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, ig_intr_md_for_tm.copy_to_cpu, Dillsboro );
}
action Jarrell( Cathay ) {
   modify_field( ig_intr_md_for_tm.mcast_grp_a, 0 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Cathay );
}
action Kranzburg() {
   modify_field( Naylor.DosPalos, 1 );
}
table Noyack {
   reads {
     Baird.Gambrills : ternary;
     Kingman.Cimarron : ternary;
     Naylor.Bovina :ternary;
     Naylor.Calhan : ternary;
     Naylor.Asher: ternary;
     Suffern.Lostwood : ternary;
     Cargray.OakCity : ternary;
   }
   actions {
      Destin;
      Monaca;
      Palomas;
      Kranzburg;
      Jarrell;
      Grinnell;
   }
   size : 512;
}
control Gullett {
   if( Naylor.Nelagoney == 0 and
       ( ( Igloo.DuPont & ( 0x4 ) ) == ( ( 0x4 ) ) ) and
       Naylor.Calhan == 1 and Naylor.Arroyo == 0x1) {
      apply( Winside );
   }
}
control Elsmere {
   if( RoseBud.Walland != 0 and Naylor.Arroyo == 0x1) {
      apply( Riner );
   }
}
control Leonore {
   if( Naylor.Fowler==1 ) {
      apply( Cowden );
   }
}
control Tuscumbia {
   apply(Noyack);
}
@pragma pa_no_init ingress ig_intr_md_for_tm.level1_mcast_hash
@pragma pa_no_init ingress ig_intr_md_for_tm.level2_mcast_hash
@pragma pa_no_init ingress ig_intr_md_for_tm.level2_exclusion_id
@pragma pa_alias ingress ig_intr_md_for_tm.level1_mcast_hash ig_intr_md_for_tm.level2_mcast_hash
action Empire(Martelle) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Kealia.Laneburg );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, Martelle );
}
@pragma ternary 1
table Ivydale {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
       Empire;
    }
    default_action : Empire( 0 );
    size : 512;
}
field_list Laplace {
   4'0;
   Cargray.Annville;
}
field_list_calculation Onycha {
   input {
      Laplace;
   }
  algorithm : identity;
  output_width : 16;
}
action BoxElder( OldMines ) {
    modify_field(ig_intr_md_for_tm.level1_exclusion_id, OldMines);
    modify_field(ig_intr_md_for_tm.rid, ig_intr_md_for_tm.mcast_grp_a);
}
action Bessie(LaSalle) {
   BoxElder( LaSalle );
}
action GlenArm(Chappell) {
   modify_field( ig_intr_md_for_tm.rid, 0xFFFF );
   modify_field( ig_intr_md_for_tm.level1_exclusion_id, Chappell );
}
action Rotonda() {
   GlenArm( 0 );
   modify_field_with_hash_based_offset( ig_intr_md_for_tm.mcast_grp_a, 0, Onycha, 65536 );
}
action Foristell( Piqua ) {
   modify_field(ig_intr_md_for_tm.level1_exclusion_id, Piqua);
   modify_field( ig_intr_md_for_tm.rid, 0 );
   modify_field_with_hash_based_offset( ig_intr_md_for_tm.mcast_grp_a, 0, Onycha, 65536 );
}
@pragma pa_no_init ingress ig_intr_md_for_tm.rid
table Endeavor {
   reads {
      Cargray.Zebina : ternary;
      Cargray.Chatom : ternary;
      LaCueva.Mission : ternary;
      Cargray.Annville mask 0xF0000 : ternary;
      ig_intr_md_for_tm.mcast_grp_a mask 0xF000 : ternary;
   }
   actions {
      BoxElder;
      Bessie;
      GlenArm;
      Rotonda;
   }
  default_action : Bessie( 0 );
  size: 512;
}
control Volcano {
   apply(Ivydale);
}
control Caspiana {
   apply(Endeavor);
}
action Colstrip( Bethania ) {
   modify_field( Cargray.FortHunt, Bethania );
   modify_field( Cargray.Chatom, 1 );
}
@pragma ways 2
table Ishpeming {
   reads {
     eg_intr_md.egress_rid: exact;
   }
   actions {
      Colstrip;
   }
   size : 16384;
}
control Colfax {
   if (eg_intr_md.egress_rid != 0) {
      apply( Coyote ) {
         Buncombe {
            apply( Ishpeming );
         }
      }
   }
}
counter Rocky {
   type : packets;
   direct: Beeler;
   min_width: 63;
}
counter Benkelman {
   type : packets;
   direct : Willette;
   min_width: 64;
}
table Beeler {
   reads {
     Windber.Chevak mask 0x00007FFF : exact;
   }
   actions {
      Buncombe;
   }
   default_action: Buncombe();
   size : 32768;
}
@pragma pa_no_init ingress Naylor.Gowanda
action Pfeifer() {
   modify_field( Naylor.Gowanda, 0 );
   modify_field( Mackville.Allen, Naylor.Bovina );
   modify_field( Mackville.Craig, Suffern.Kinney );
   modify_field( Mackville.Edesville, Naylor.HillCity );
   modify_field( Mackville.Wakeman, Naylor.Norco );
}
action Slater() {
   modify_field( Naylor.Gowanda, 0 );
   modify_field( Mackville.Allen, Naylor.Bovina );
   modify_field( Mackville.Craig, Coolin.Galestown );
   modify_field( Mackville.Edesville, Naylor.HillCity );
   modify_field( Mackville.Wakeman, Naylor.Norco );
}
action Childs( Pelican, Pricedale ) {
   Pfeifer();
   modify_field( Mackville.Currie, Pelican );
   modify_field( Mackville.Oroville, Pricedale );
}
action Mangham( Manakin, Stratton ) {
   Slater();
   modify_field( Mackville.Currie, Manakin );
   modify_field( Mackville.Oroville, Stratton );
}
action Koloa() {
   modify_field( Naylor.Gowanda, 1 );
}
action Molino() {
   modify_field( Naylor.Haley, 1 );
}
@pragma pa_no_init ingress Mackville.Currie
@pragma pa_container_size ingress Mackville.Currie 16
@pragma pa_no_init ingress Mackville.Greycliff
@pragma pa_container_size ingress Mackville.Greycliff 16
table Cedaredge {
   reads {
     Suffern.Mendoza : ternary;
   }
   actions {
      Childs;
      Koloa;
   }
   default_action : Pfeifer();
  size : 4096;
}
table Elvaston {
   reads {
     Coolin.Lanyon : ternary;
   }
   actions {
      Mangham;
      Koloa;
   }
   default_action : Slater();
   size : 512;
}
action Gambrill( Bevington, Ludell ) {
   modify_field( Mackville.Greycliff, Bevington );
   modify_field( Mackville.Lyncourt, Ludell );
}
table Bulger {
   reads {
     Suffern.Lostwood : ternary;
   }
   actions {
      Gambrill;
      Molino;
   }
   size : 1024;
}
table Kinard {
   reads {
     Coolin.Maceo : ternary;
   }
   actions {
      Gambrill;
      Molino;
   }
   size : 512;
}
action Hibernia( Petoskey ) {
   modify_field( Mackville.Twisp, Petoskey );
}
table Kentwood {
   reads {
     Naylor.Folger : ternary;
   }
   actions {
      Hibernia;
   }
   size : 1024;
}
action Glentana( Calabasas ) {
   modify_field( Mackville.Gunter, Calabasas );
}
table Hewitt {
   reads {
     Naylor.Bennet : ternary;
   }
   actions {
      Glentana;
   }
   size : 1024;
}
action Eveleth( Equality, Luning ) {
   modify_field( Windber.Chevak, Luning, 0xFFFF );
   modify_field( Mackville.Cedar, Equality );
   modify_field( Naylor.Couchwood, 1 );
}
action Boxelder( Wegdahl, Winner ) {
   modify_field( Windber.Chevak, Winner, 0xFFFF );
   modify_field( Mackville.Cedar, Wegdahl );
}
@pragma ways 2
table Magasco {
   reads {
     Naylor.Arroyo mask 0x3 : exact;
     Naylor.Tehachapi : exact;
   }
   actions {
      Eveleth;
   }
   size : 8192;
}
@pragma ways 1
table Bazine {
   reads {
     Naylor.Arroyo mask 0x3 : exact;
     ig_intr_md.ingress_port mask 0x7F : exact;
   }
   actions {
      Boxelder;
      Buncombe;
   }
   default_action : Buncombe();
   size : 512;
}
control Teigen {
   if( Naylor.Arroyo == 0x1 ) {
      apply( Cedaredge );
      apply( Bulger );
   } else if( Naylor.Arroyo == 0x2 ) {
      apply( Elvaston );
      apply( Kinard );
   }
   if( ( Naylor.Oklee & 2 ) == 2 ) {
      apply( Kentwood );
      apply( Hewitt );
   }
   if( Cargray.Zebina == 0 ) {
      apply( Bazine ) {
         Buncombe {
            apply( Magasco );
         }
      }
   } else {
      apply( Magasco );
   }
}
action Brinson() {
   bit_or( ig_intr_md_for_tm.copy_to_cpu, ig_intr_md_for_tm.copy_to_cpu, 0 );
}
action Lasker() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action BigPlain() {
   bit_or( ig_intr_md_for_tm.copy_to_cpu, ig_intr_md_for_tm.copy_to_cpu, 0 );
}
action Korbel() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action SourLake() {
}
table Willette {
   reads {
      ig_intr_md.ingress_port mask 0x7f : ternary;
      Windber.Chevak mask 0x00018000 : ternary;
      Naylor.Nelagoney : ternary;
      Naylor.Leicester : ternary;
      Naylor.Eaton : ternary;
      Naylor.Evansburg : ternary;
      Naylor.Alstown : ternary;
      Naylor.DosPalos : ternary;
      Naylor.Swedeborg : ternary;
      Naylor.Kalvesta : ternary;
      Naylor.Arroyo mask 0x4 : ternary;
      Cargray.Annville : ternary;
      ig_intr_md_for_tm.mcast_grp_a : ternary;
      Cargray.Chatom : ternary;
      Cargray.OakCity : ternary;
      Naylor.Shidler : ternary;
      Naylor.Lumpkin : ternary;
   }
   actions {
      Brinson;
      Lasker;
      BigPlain;
      Korbel;
      SourLake;
   }
   default_action: Brinson();
   size : 1024;
}
action Lesley() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 3 );
}
@pragma ways 1
table Hesler {
   reads {
     Windber.Chevak mask 0x00008000 : exact;
     Naylor.Nelagoney : exact;
     Naylor.Leicester : exact;
     Naylor.Eaton : exact;
     Naylor.Evansburg : exact;
     Naylor.Alstown : exact;
     Naylor.DosPalos : exact;
     Naylor.Swedeborg: exact;
     Naylor.Kalvesta : exact;
     Naylor.Arroyo mask 0x4 : exact;
     Naylor.Shidler : exact;
   }
   actions {
      Lesley;
      Buncombe;
   }
   default_action : Lesley();
   size : 2;
}
control Desdemona {
   apply( Willette );
   apply( Hesler ) {
      Lesley {
      }
      default {
         apply( Nondalton );
         apply( Beeler );
      }
   }
}
action Allison() {
   modify_field( Windber.Chevak, 0 );
}
table Modale {
   actions {
      Allison;
   }
   default_action : Allison();
   size : 1;
}
   metadata Battles Windber;
   action Sherwin( Burdette ) {
          max( Windber.Chevak, Windber.Chevak, Burdette );
   }
@pragma ways 1
table NorthRim {
   reads {
      Mackville.Cedar : exact;
      Mackville.Currie : exact;
      Mackville.Greycliff : exact;
      Mackville.Twisp : exact;
      Mackville.Gunter : exact;
      Mackville.Allen : exact;
      Mackville.Craig : exact;
      Mackville.Edesville : exact;
      Mackville.Wakeman : exact;
      Mackville.Larose : exact;
   }
   actions {
      Sherwin;
   }
   size : 4096;
}
control Celada {
   apply( NorthRim );
}
@pragma pa_no_init ingress Mattson.Currie
@pragma pa_no_init ingress Mattson.Greycliff
@pragma pa_no_init ingress Mattson.Twisp
@pragma pa_no_init ingress Mattson.Gunter
@pragma pa_no_init ingress Mattson.Allen
@pragma pa_no_init ingress Mattson.Craig
@pragma pa_no_init ingress Mattson.Edesville
@pragma pa_no_init ingress Mattson.Wakeman
@pragma pa_no_init ingress Mattson.Larose
metadata Firesteel Mattson;
@pragma ways 1
table Newtonia {
   reads {
      Mackville.Cedar : exact;
      Mattson.Currie : exact;
      Mattson.Greycliff : exact;
      Mattson.Twisp : exact;
      Mattson.Gunter : exact;
      Mattson.Allen : exact;
      Mattson.Craig : exact;
      Mattson.Edesville : exact;
      Mattson.Wakeman : exact;
      Mattson.Larose : exact;
   }
   actions {
      Sherwin;
   }
   size : 4096;
}
action Tillson( Fannett, Delavan, Camelot, Wisdom, Honobia, Lakeside, Gilmanton, Rains, Miller ) {
   bit_and( Mattson.Currie, Mackville.Currie, Fannett );
   bit_and( Mattson.Greycliff, Mackville.Greycliff, Delavan );
   bit_and( Mattson.Twisp, Mackville.Twisp, Camelot );
   bit_and( Mattson.Gunter, Mackville.Gunter, Wisdom );
   bit_and( Mattson.Allen, Mackville.Allen, Honobia );
   bit_and( Mattson.Craig, Mackville.Craig, Lakeside );
   bit_and( Mattson.Edesville, Mackville.Edesville, Gilmanton );
   bit_and( Mattson.Wakeman, Mackville.Wakeman, Rains );
   bit_and( Mattson.Larose, Mackville.Larose, Miller );
}
table Kinross {
   reads {
      Mackville.Cedar : exact;
   }
   actions {
      Tillson;
   }
   default_action : Tillson(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Yakima {
   apply( Kinross );
}
control Gravette {
   apply( Newtonia );
}
@pragma ways 1
table Summit {
   reads {
      Mackville.Cedar : exact;
      Mattson.Currie : exact;
      Mattson.Greycliff : exact;
      Mattson.Twisp : exact;
      Mattson.Gunter : exact;
      Mattson.Allen : exact;
      Mattson.Craig : exact;
      Mattson.Edesville : exact;
      Mattson.Wakeman : exact;
      Mattson.Larose : exact;
   }
   actions {
      Sherwin;
   }
   size : 4096;
}
action Charenton( Catarina, Roodhouse, Duffield, Dunken, Edmondson, Veneta, Meservey, Pekin, Jigger ) {
   bit_and( Mattson.Currie, Mackville.Currie, Catarina );
   bit_and( Mattson.Greycliff, Mackville.Greycliff, Roodhouse );
   bit_and( Mattson.Twisp, Mackville.Twisp, Duffield );
   bit_and( Mattson.Gunter, Mackville.Gunter, Dunken );
   bit_and( Mattson.Allen, Mackville.Allen, Edmondson );
   bit_and( Mattson.Craig, Mackville.Craig, Veneta );
   bit_and( Mattson.Edesville, Mackville.Edesville, Meservey );
   bit_and( Mattson.Wakeman, Mackville.Wakeman, Pekin );
   bit_and( Mattson.Larose, Mackville.Larose, Jigger );
}
table Bigfork {
   reads {
      Mackville.Cedar : exact;
   }
   actions {
      Charenton;
   }
   default_action : Charenton(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Plata {
   apply( Bigfork );
}
control Lajitas {
   apply( Summit );
}
@pragma ways 1
table Meridean {
   reads {
      Mackville.Cedar : exact;
      Mattson.Currie : exact;
      Mattson.Greycliff : exact;
      Mattson.Twisp : exact;
      Mattson.Gunter : exact;
      Mattson.Allen : exact;
      Mattson.Craig : exact;
      Mattson.Edesville : exact;
      Mattson.Wakeman : exact;
      Mattson.Larose : exact;
   }
   actions {
      Sherwin;
   }
   size : 8192;
}
action Angwin( Radom, Weissert, Skime, Norfork, Glenside, Comal, Waretown, Gamewell, Crystola ) {
   bit_and( Mattson.Currie, Mackville.Currie, Radom );
   bit_and( Mattson.Greycliff, Mackville.Greycliff, Weissert );
   bit_and( Mattson.Twisp, Mackville.Twisp, Skime );
   bit_and( Mattson.Gunter, Mackville.Gunter, Norfork );
   bit_and( Mattson.Allen, Mackville.Allen, Glenside );
   bit_and( Mattson.Craig, Mackville.Craig, Comal );
   bit_and( Mattson.Edesville, Mackville.Edesville, Waretown );
   bit_and( Mattson.Wakeman, Mackville.Wakeman, Gamewell );
   bit_and( Mattson.Larose, Mackville.Larose, Crystola );
}
table Azusa {
   reads {
      Mackville.Cedar : exact;
   }
   actions {
      Angwin;
   }
   default_action : Angwin(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Bronaugh {
   apply( Azusa );
}
control Dozier {
   apply( Meridean );
}
@pragma ways 1
table Alcester {
   reads {
      Mackville.Cedar : exact;
      Mattson.Currie : exact;
      Mattson.Greycliff : exact;
      Mattson.Twisp : exact;
      Mattson.Gunter : exact;
      Mattson.Allen : exact;
      Mattson.Craig : exact;
      Mattson.Edesville : exact;
      Mattson.Wakeman : exact;
      Mattson.Larose : exact;
   }
   actions {
      Sherwin;
   }
   size : 8192;
}
action Timnath( Dubach, Verdemont, Oreland, Naruna, Cahokia, CedarKey, Assinippi, Dresser, Bridger ) {
   bit_and( Mattson.Currie, Mackville.Currie, Dubach );
   bit_and( Mattson.Greycliff, Mackville.Greycliff, Verdemont );
   bit_and( Mattson.Twisp, Mackville.Twisp, Oreland );
   bit_and( Mattson.Gunter, Mackville.Gunter, Naruna );
   bit_and( Mattson.Allen, Mackville.Allen, Cahokia );
   bit_and( Mattson.Craig, Mackville.Craig, CedarKey );
   bit_and( Mattson.Edesville, Mackville.Edesville, Assinippi );
   bit_and( Mattson.Wakeman, Mackville.Wakeman, Dresser );
   bit_and( Mattson.Larose, Mackville.Larose, Bridger );
}
table Amsterdam {
   reads {
      Mackville.Cedar : exact;
   }
   actions {
      Timnath;
   }
   default_action : Timnath(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Mackeys {
   apply( Amsterdam );
}
control Conover {
   apply( Alcester );
}
@pragma ways 1
table PellCity {
   reads {
      Mackville.Cedar : exact;
      Mattson.Currie : exact;
      Mattson.Greycliff : exact;
      Mattson.Twisp : exact;
      Mattson.Gunter : exact;
      Mattson.Allen : exact;
      Mattson.Craig : exact;
      Mattson.Edesville : exact;
      Mattson.Wakeman : exact;
      Mattson.Larose : exact;
   }
   actions {
      Sherwin;
   }
   size : 8192;
}
action Alderson( Atoka, Lindsborg, Robinson, Gilman, Kelso, Heeia, Chavies, Chazy, McLaurin ) {
   bit_and( Mattson.Currie, Mackville.Currie, Atoka );
   bit_and( Mattson.Greycliff, Mackville.Greycliff, Lindsborg );
   bit_and( Mattson.Twisp, Mackville.Twisp, Robinson );
   bit_and( Mattson.Gunter, Mackville.Gunter, Gilman );
   bit_and( Mattson.Allen, Mackville.Allen, Kelso );
   bit_and( Mattson.Craig, Mackville.Craig, Heeia );
   bit_and( Mattson.Edesville, Mackville.Edesville, Chavies );
   bit_and( Mattson.Wakeman, Mackville.Wakeman, Chazy );
   bit_and( Mattson.Larose, Mackville.Larose, McLaurin );
}
table Hallowell {
   reads {
      Mackville.Cedar : exact;
   }
   actions {
      Alderson;
   }
   default_action : Alderson(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Raritan {
   apply( Hallowell );
}
control McFaddin {
   apply( PellCity );
}
@pragma ways 1
table JimFalls {
   reads {
      Mackville.Cedar : exact;
      Mattson.Currie : exact;
      Mattson.Greycliff : exact;
      Mattson.Twisp : exact;
      Mattson.Gunter : exact;
      Mattson.Allen : exact;
      Mattson.Craig : exact;
      Mattson.Edesville : exact;
      Mattson.Wakeman : exact;
      Mattson.Larose : exact;
   }
   actions {
      Sherwin;
   }
   size : 4096;
}
action Lefors( Lacombe, CityView, Laclede, Fristoe, Barwick, Alburnett, Lansdowne, Coulee, Helotes ) {
   bit_and( Mattson.Currie, Mackville.Currie, Lacombe );
   bit_and( Mattson.Greycliff, Mackville.Greycliff, CityView );
   bit_and( Mattson.Twisp, Mackville.Twisp, Laclede );
   bit_and( Mattson.Gunter, Mackville.Gunter, Fristoe );
   bit_and( Mattson.Allen, Mackville.Allen, Barwick );
   bit_and( Mattson.Craig, Mackville.Craig, Alburnett );
   bit_and( Mattson.Edesville, Mackville.Edesville, Lansdowne );
   bit_and( Mattson.Wakeman, Mackville.Wakeman, Coulee );
   bit_and( Mattson.Larose, Mackville.Larose, Helotes );
}
table Reynolds {
   reads {
      Mackville.Cedar : exact;
   }
   actions {
      Lefors;
   }
   default_action : Lefors(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Anoka {
}
control Bassett {
}
@pragma ways 1
table Rehoboth {
   reads {
      Mackville.Cedar : exact;
      Mattson.Currie : exact;
      Mattson.Greycliff : exact;
      Mattson.Twisp : exact;
      Mattson.Gunter : exact;
      Mattson.Allen : exact;
      Mattson.Craig : exact;
      Mattson.Edesville : exact;
      Mattson.Wakeman : exact;
      Mattson.Larose : exact;
   }
   actions {
      Sherwin;
   }
   size : 4096;
}
action Seagrove( Curtin, Neuse, Harbor, Yerington, DoeRun, Cascade, Fragaria, Lumberton, Ravenwood ) {
   bit_and( Mattson.Currie, Mackville.Currie, Curtin );
   bit_and( Mattson.Greycliff, Mackville.Greycliff, Neuse );
   bit_and( Mattson.Twisp, Mackville.Twisp, Harbor );
   bit_and( Mattson.Gunter, Mackville.Gunter, Yerington );
   bit_and( Mattson.Allen, Mackville.Allen, DoeRun );
   bit_and( Mattson.Craig, Mackville.Craig, Cascade );
   bit_and( Mattson.Edesville, Mackville.Edesville, Fragaria );
   bit_and( Mattson.Wakeman, Mackville.Wakeman, Lumberton );
   bit_and( Mattson.Larose, Mackville.Larose, Ravenwood );
}
table Ipava {
   reads {
      Mackville.Cedar : exact;
   }
   actions {
      Seagrove;
   }
   default_action : Seagrove(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Dougherty {
   apply( Ipava );
}
control Camargo {
   apply( Rehoboth );
}
action Jerico( Poipu ) {
   modify_field( Cargray.Litroe, Poipu );
   bit_or( Covelo.Arthur, Oshoto.Abernathy, 0x80 );
}
action Uncertain( Maybeury ) {
   modify_field( Cargray.Litroe, Maybeury );
   bit_or( Waiehu.RockHall, Oshoto.Abernathy, 0x80 );
}
table Abbyville {
   reads {
      Oshoto.Abernathy mask 0x80 : exact;
      Covelo.valid : exact;
      Waiehu.valid : exact;
   }
   actions {
      Jerico;
      Uncertain;
   }
   size : 8;
}
action Mulliken() {
   modify_field( Covelo.Arthur, 0, 0x80 );
}
action Sledge() {
   modify_field( Waiehu.RockHall, 0, 0x80 );
}
table Lazear {
   reads {
     Cargray.Litroe : exact;
     Covelo.valid : exact;
     Waiehu.valid : exact;
   }
   actions {
      Mulliken;
      Sledge;
   }
   size : 16;
}
action Fallis(Larwill)
{
   modify_field( ig_intr_md_for_tm.mcast_grp_a, 0 );
   modify_field( Cargray.OakCity, 1 );
   modify_field( Cargray.Kelsey, Larwill);
}
action Farthing(Belvidere) {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
   modify_field( Cargray.Kelsey, Belvidere);
}
counter Sawpit {
   type : packets_and_bytes;
   direct : Lewistown;
   min_width: 64;
}
table Lewistown {
   reads {
      Naylor.Woodstown : ternary;
      Naylor.OjoFeliz : ternary;
      Naylor.Fowler : ternary;
      Naylor.Tehachapi : ternary;
      Naylor.Oklee : ternary;
      Naylor.Folger : ternary;
      Naylor.Bennet : ternary;
      LaCueva.Ingraham : ternary;
      Igloo.LongPine : ternary;
      Naylor.HillCity : ternary;
      Oxford.valid : ternary;
      Oxford.Crooks : ternary;
      Naylor.Asher : ternary;
      Suffern.Lostwood : ternary;
      Naylor.Bovina : ternary;
      Cargray.Homeacre : ternary;
      Cargray.Zebina : ternary;
      Coolin.Maceo mask 0xffff0000000000000000000000000000 : ternary;
      Naylor.Delmont :ternary;
      Cargray.Kelsey :ternary;
   }
   actions {
      Fallis;
      Farthing;
      Clementon;
   }
   size : 512;
}
control Dyess {
   apply( Lewistown );
}
field_list Hisle {
   Naylor.Vallecito;
   Cargray.Pinebluff;
}
field_list Swansboro {
   Naylor.Vallecito;
   Cargray.Pinebluff;
}
field_list Sturgis {
   Kealia.Laneburg;
}
field_list_calculation Everetts {
    input {
        Sturgis;
    }
    algorithm : identity;
    output_width : 51;
}
field_list Nestoria {
   Kealia.Laneburg;
}
field_list_calculation Kosciusko {
    input {
        Nestoria;
    }
    algorithm : identity;
    output_width : 51;
}
action Higgins( Manilla ) {
   modify_field( Kapowsin.Watters, Manilla );
}
action Idria() {
   modify_field( Naylor.Lumpkin, 1 );
}
table Toulon {
   reads {
      LaCueva.Ingraham : ternary;
      Mackville.Oroville : ternary;
      Mackville.Lyncourt : ternary;
      LaVale.Shauck : ternary;
      Naylor.Bovina : ternary;
      Naylor.HillCity : ternary;
      Blakeslee.Justice : ternary;
      Blakeslee.Mogadore : ternary;
   }
   actions {
      Idria;
      Higgins;
   }
   default_action : Higgins(0);
   size : 1024;
}
control Westel {
   apply( Toulon );
}
meter Dillsburg {
   type : bytes;
   static : Cuprum;
   instance_count : 128;
}
action Tontogany( Picayune ) {
   execute_meter( Dillsburg, Picayune, Kapowsin.Trout );
}
table Cuprum {
   reads {
      Kapowsin.Watters mask 0x7F : exact;
   }
   actions {
      Tontogany;
      Buncombe;
   }
   default_action : Buncombe();
   size : 128;
}
control WestGate {
   apply( Cuprum );
}
action Coalton() {
   clone_ingress_pkt_to_egress( Kapowsin.Watters, Hisle );
}
table Arkoe {
   reads {
      Kapowsin.Trout : exact;
   }
   actions {
      Coalton;
   }
   size : 2;
}
control Shabbona {
   if( Kapowsin.Watters != 0 ) {
      apply( Arkoe );
   }
}
action_selector Rochert {
    selection_key : Everetts;
    selection_mode : resilient;
}
action Froid( Fries ) {
   bit_or( Kapowsin.Watters, Kapowsin.Watters, Fries );
}
action_profile Napanoch {
   actions {
      Froid;
   }
   size : 512;
   dynamic_action_selection : Rochert;
}
@pragma ternary 1
table Ossining {
   reads {
      Kapowsin.Watters mask 0x7F : exact;
   }
   action_profile : Napanoch;
   size : 128;
}
control Varnado {
   apply( Ossining );
}
action Cusseta() {
   modify_field( Cargray.Zebina, 0 );
   modify_field( Cargray.RedElm, 3 );
}
action Colonias( Dante, Becida, Glenolden, English, Macungie, Faith,
      Ankeny, Peebles ) {
   modify_field( Cargray.Zebina, 0 );
   modify_field( Cargray.RedElm, 4 );
   add_header( Covelo );
   modify_field( Covelo.Amazonia, 0x4);
   modify_field( Covelo.Morita, 0x5);
   modify_field( Covelo.Mullins, English);
   modify_field( Covelo.Arthur, 47 );
   modify_field( Covelo.Biggers, Glenolden);
   modify_field( Covelo.Orrville, 0 );
   modify_field( Covelo.Hagaman, 0 );
   modify_field( Covelo.Grants, 0 );
   modify_field( Covelo.Lisle, Dante);
   modify_field( Covelo.Chatawa, Becida);
   add( Covelo.Portal, eg_intr_md.pkt_length, 15 );
   add_header( Hopeton );
   modify_field( Hopeton.Addison, Macungie);
   modify_field( Cargray.Freedom, Faith );
   modify_field( Cargray.Stone, Ankeny );
   modify_field( Cargray.Accomac, Peebles );
   modify_field( Cargray.Chatom, 0 );
}
action BirchBay( AukeBay ) {
   modify_field( Cargray.Kelsey, AukeBay );
   modify_field( Cargray.Bangor, 1 );
   modify_field( Cargray.Zebina, 0 );
   modify_field( Cargray.RedElm, 2 );
   modify_field( Cargray.Calamus, 1 );
   modify_field( Cargray.Chatom, 0 );
}
@pragma ternary 1
table Pecos {
   reads {
      eg_intr_md.egress_rid : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Cusseta;
      BirchBay;
      Colonias;
   }
   size : 256;
}
control Hilger {
   apply( Pecos );
}
action Uniopolis( Courtdale ) {
   modify_field( Marysvale.Polkville, Courtdale );
}
table Hilgard {
   reads {
      eg_intr_md.egress_port : exact;
   }
   actions {
      Uniopolis;
   }
   default_action : Uniopolis(0);
   size : 128;
}
control Endicott {
    apply( Hilgard );
}
action_selector RockHill {
    selection_key : Kosciusko;
    selection_mode : resilient;
}
action LeSueur( Natalia ) {
   bit_or( Marysvale.Polkville, Marysvale.Polkville, Natalia );
}
action_profile Belfalls {
   actions {
      LeSueur;
   }
   size : 512;
   dynamic_action_selection : RockHill;
}
@pragma ternary 1
table Lyndell {
   reads {
      Marysvale.Polkville mask 0x7F : exact;
   }
   action_profile : Belfalls;
   size : 128;
}
control DimeBox {
   apply( Lyndell );
}
meter Gonzales {
   type : bytes;
   static : Benson;
   instance_count : 128;
}
action SeaCliff( DewyRose ) {
   execute_meter( Gonzales, DewyRose, Marysvale.Winters );
}
@pragma ternary 1
table Benson {
   reads {
      Marysvale.Polkville mask 0x7F: exact;
   }
   actions {
      SeaCliff;
   }
   default_action : SeaCliff( 0 );
   size : 128;
}
control Choudrant {
   apply( Benson );
}
action Burwell() {
   modify_field( Cargray.Pinebluff, eg_intr_md.egress_port );
   modify_field( Naylor.Vallecito, Cargray.FortHunt );
   clone_egress_pkt_to_egress( Marysvale.Polkville, Swansboro );
}
table Stovall {
   actions {
      Burwell;
   }
   size : 1;
}
control Gratis {
   if( Marysvale.Polkville != 0 and Marysvale.Winters == 0 ) {
      apply( Stovall );
   }
}
counter Edgemoor {
   type : packets;
   direct : Daykin;
   min_width: 64;
}
table Daykin {
   reads {
      eg_intr_md.egress_port mask 0x7f : exact;
      Downs.Belcher : ternary;
      Downs.LakePine : ternary;
   }
   actions {
      Buncombe;
   }
   default_action : Buncombe();
   size : 256;
}
action Tinaja() {
   drop();
}
table Chubbuck {
   reads {
      Downs.Belcher : exact;
      Downs.LakePine : exact;
   }
   actions {
      Tinaja;
      Buncombe;
   }
   default_action : Tinaja();
   size : 2;
}
control Rocklin {
   apply( Daykin );
   apply( Chubbuck ) {
      Buncombe {
         Gratis();
      }
   }
}
action Norridge() {
   modify_field(Cargray.Zebina, 0);
   modify_field(Cargray.OakCity, 1);
   modify_field(Cargray.Kelsey, 16);
}
table Florin {
   actions {
      Norridge;
   }
   default_action : Norridge();
   size : 1;
}
action Cypress() {
   modify_field(Naylor.Shidler, 1);
}
@pragma ways 1
table Denhoff {
   reads {
      Trona.ElMango : exact;
      Trona.Monahans : exact;
      Covelo.Chatawa : exact;
   }
   actions {
      Cypress;
      Clementon;
   }
   default_action : Cypress();
   size : 512;
}
control Roxboro {
   if(Cargray.Zebina == 1 and Igloo.LongPine == 1) {
      apply(Denhoff);
   }
}
control Yakutat {
   if(Cargray.Zebina == 1 and ( ( Igloo.DuPont & ( 0x1 ) ) == ( ( 0x1 ) ) ) and Trona.Goodlett==0x0806) {
      apply(Florin);
   }
}
control ingress {
   Chatmoss();
   apply( Reager );
   if( LaCueva.Mission != 0 ) {
      Coqui();
   }
   OldTown();
   Teigen();
   if( LaCueva.Mission != 0 ) {
      Silesia();
   }
   Mosinee();
   Yakima();
   Dumas();
   Kerby();
   if ( Naylor.Nelagoney == 0 ) {
      Tanana();
      if ( ( ( Igloo.DuPont & ( 0x2 ) ) == ( ( 0x2 ) ) ) and Naylor.Arroyo == 0x2 and LaCueva.Mission != 0 and Igloo.LongPine == 1 ) {
         Arriba();
      } else {
      Halstead();
         if ( ( ( Igloo.DuPont & ( 0x1 ) ) == ( ( 0x1 ) ) ) and Naylor.Arroyo == 0x1 and LaCueva.Mission != 0 and Igloo.LongPine == 1 ) {
            Malmo();
         } else {
            if( valid( Larchmont ) ) {
               Hahira();
            }
            if( Cargray.OakCity == 0 and Cargray.Zebina != 2 ) {
               Cabery();
            }
         }
      }
   }
   if( LaCueva.Mission != 0 ) {
      Roxboro();
      Yakutat();
   }
   Carlin();
   Gravette();
   Plata();
   Bufalo();
   Sarasota();
   Bassett();
   Anoka();
   Hookdale();
   Safford();
   Lajitas();
   Bronaugh();
   apply( Mapleton );
   if( LaCueva.Mission != 0 ) {
      Missoula();
   } else {
   }
   apply( Lauada );
   Dozier();
   Mackeys();
   Gullett();
   Monetta();
   Westel();
   Dyess();
   Leonore();
   Varnado();
   if( LaCueva.Mission != 0 ) {
      Nathan();
   }
   Elsmere();
   Woodsdale();
   Conover();
   Raritan();
   if( LaCueva.Mission != 0 ) {
      Rushton();
   }
   McFaddin();
   Milbank();
   Pelion();
   WestGate();
   if( Cargray.OakCity == 0 ) {
      Sanatoga();
   }
   Tuscumbia();
   if( Cargray.Zebina == 0 or Cargray.Zebina == 3 ) {
      apply(Abbyville);
   }
   Roberta();
   if( LaCueva.Mission != 0 ) {
      Moraine();
   }
   if( Naylor.Couchwood == 1 and Igloo.LongPine == 0 ) {
      apply( Modale );
   }
   if( LaCueva.Mission != 0 ) {
      Poulan();
   }
   Volcano();
   Sully();
   if( valid( Emden[0] ) and Cargray.Zebina != 2 ) {
      Oketo();
   }
   Shabbona();
   Desdemona();
   Caspiana();
   Deloit();
}
control egress {
   Cleta();
   Aptos();
   if( ( (eg_intr_md_from_parser_aux.clone_src == NOT_CLONED) ) ) {
      Hiwasse();
      Endicott();
      Colfax();
      if( Cargray.Zebina == 0 or Cargray.Zebina == 3 ) {
         apply( Lazear );
      }
      Pickering();
      Choudrant();
      Ancho();
   } else {
      Hilger();
   }
   Franktown();
   if( ( (eg_intr_md_from_parser_aux.clone_src == NOT_CLONED) ) and Cargray.Calamus == 0 ) {
      if( Cargray.Zebina != 2 and Cargray.Gasport == 0 ) {
         Hatchel();
      }
      DimeBox();
      Wyarno();
      Rocklin();
   }
   if( Cargray.Calamus == 0 and Cargray.Zebina != 2 and Cargray.RedElm != 3 ) {
      Estrella();
   }
}
