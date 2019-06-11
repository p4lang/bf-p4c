// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.
//
// Random Seed: 150111

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
#include <tofino/wred_blackbox.p4>
#include <tofino/meter_blackbox.p4>
header_type Knolls {
	fields {
		LongPine : 16;
		Ardsley : 8;
		Williams : 8;
		Snohomish : 4;
		Ishpeming : 3;
		Trego : 3;
		Victoria : 3;
	}
}
header_type Lynndyl {
	fields {
		Dizney : 24;
		Ralls : 24;
		Havana : 24;
		Jamesport : 24;
		Domestic : 16;
		Osseo : 12;
		BlackOak : 20;
		Kalskag : 12;
		Hutchings : 16;
		Bernstein : 8;
		Lattimore : 8;
		Virginia : 3;
		Biddle : 1;
		Elloree : 3;
		Pinecreek : 3;
		Adona : 1;
		Clarinda : 1;
		Hooker : 1;
		Arpin : 1;
		Emmet : 1;
		Dubuque : 1;
		Skiatook : 1;
		Westway : 1;
		Bernard : 1;
		LaPalma : 1;
		Cornell : 1;
		Quinhagak : 1;
		Quinnesec : 1;
		Dubach : 1;
		Amazonia : 1;
		Lesley : 1;
		Tekonsha : 1;
		Oldsmar : 1;
		Headland : 1;
		Sunrise : 1;
		Kaplan : 1;
		Grays : 1;
		Lamar : 1;
		Minatare : 1;
		Harshaw : 1;
		Freeny : 1;
		Tiverton : 16;
		PawCreek : 16;
		Hephzibah : 8;
		Easley : 2;
		MoonRun : 2;
		Agency : 1;
		Culloden : 1;
		Toxey : 16;
	}
}
header_type Taylors {
	fields {
		Badger : 4;
		Layton : 4;
		Elcho : 1;
		Carroll : 1;
		Poteet : 1;
		Felida : 1;
		Burmah : 1;
		Naches : 13;
		Pachuta : 13;
	}
}
header_type BigArm {
	fields {
		Menfro : 1;
		Veguita : 1;
		Tampa : 1;
		Tiller : 16;
		Beresford : 16;
		Ringwood : 32;
		Raritan : 32;
		Nursery : 1;
		Duque : 1;
		Whitten : 1;
		Wailuku : 1;
		McClusky : 1;
		Roberts : 1;
		Elsey : 1;
		LeCenter : 1;
		Bunker : 1;
		Borup : 1;
	}
}
header_type Minburn {
	fields {
		Summit : 24;
		Lookeba : 24;
		Monrovia : 1;
		Westel : 3;
		Verbena : 1;
		Lueders : 12;
		Munich : 20;
		Agawam : 20;
		Telegraph : 16;
		Cardenas : 16;
		Birds : 12;
		Parkland : 10;
		Campo : 3;
		Mahopac : 8;
		Pierpont : 1;
		Bozar : 32;
		Oronogo : 32;
		Gervais : 24;
		Nuiqsut : 8;
		Dasher : 2;
		Golden : 32;
		McIntosh : 9;
		Mattawan : 2;
		Junior : 1;
		Eaton : 1;
		Springlee : 12;
		Contact : 1;
		Abbyville : 1;
		Ladelle : 1;
		Domingo : 2;
		Shelbina : 32;
		AvonLake : 32;
		Hobson : 8;
		Dunkerton : 24;
		Vinemont : 24;
		Boutte : 2;
		Norwood : 1;
	}
}
header_type Otranto {
	fields {
		Dante : 10;
		Ruffin : 10;
		ElkNeck : 2;
	}
}
header_type Sunset {
	fields {
		Oklee : 10;
		Webbville : 10;
		Westview : 2;
		Dougherty : 8;
		Verndale : 6;
		Murchison : 16;
		Swisshome : 4;
		Sylva : 4;
	}
}
header_type Geismar {
	fields {
		Pelican : 8;
		Nuremberg : 4;
		Frederika : 1;
	}
}
header_type Roberta {
	fields {
		LaMoille : 32;
		SanSimon : 32;
		Leola : 32;
		Kress : 6;
		SoapLake : 6;
		Quinwood : 16;
	}
}
header_type Nashua {
	fields {
		Hamden : 128;
		Varnado : 128;
		Green : 8;
		Fairlea : 6;
		Milano : 16;
	}
}
header_type Gilman {
	fields {
		Bells : 14;
		Harold : 12;
		Coventry : 1;
		Geeville : 2;
	}
}
header_type Cotuit {
	fields {
		Roxboro : 1;
		Harris : 1;
	}
}
header_type Plata {
	fields {
		Magasco : 1;
		SneeOosh : 1;
	}
}
header_type Charlack {
	fields {
		Bonner : 2;
	}
}
header_type Sturgis {
	fields {
		LaSal : 2;
		Attica : 15;
		Gomez : 15;
		Windber : 2;
		Haugen : 15;
	}
}
header_type Mentmore {
	fields {
		Tanana : 16;
		Wauna : 16;
		Danese : 16;
		Taconite : 16;
		Vigus : 16;
		Provo : 16;
	}
}
header_type Naalehu {
	fields {
		Brinson : 16;
		Vananda : 16;
	}
}
header_type Woodward {
	fields {
		Baltimore : 2;
		Amboy : 6;
		Resaca : 3;
		Fonda : 1;
		Dunedin : 1;
		McCammon : 1;
		Jenifer : 3;
		Coachella : 1;
		LaSalle : 6;
		Akiachak : 6;
		Ingleside : 5;
		Steprock : 1;
		Chubbuck : 1;
		Baudette : 1;
		Manilla : 2;
		Dunmore : 12;
		Barrow : 1;
	}
}
header_type Glenvil {
	fields {
		IowaCity : 16;
	}
}
header_type Kaibab {
	fields {
		Gerlach : 16;
		DosPalos : 1;
		Risco : 1;
	}
}
header_type Allen {
	fields {
		Konnarock : 16;
		Oskaloosa : 1;
		Neponset : 1;
	}
}
header_type MuleBarn {
	fields {
		TiePlant : 16;
		Corfu : 16;
		Alcester : 16;
		Worthing : 16;
		Caliente : 16;
		Rushton : 16;
		Reagan : 8;
		Woodfords : 8;
		Elmont : 8;
		Crooks : 8;
		Hanford : 1;
		Telephone : 6;
	}
}
header_type Sugarloaf {
	fields {
		Osage : 32;
	}
}
header_type Wheeler {
	fields {
		Waldo : 8;
		Camden : 32;
		Heeia : 32;
	}
}
header_type Grabill {
	fields {
		RedBay : 8;
	}
}
header_type Hector {
	fields {
		Croft : 1;
		Whatley : 1;
		Bellport : 1;
		Highcliff : 20;
		Radcliffe : 12;
	}
}
header_type Wyocena {
	fields {
		Haven : 16;
		RioLajas : 8;
		Callery : 16;
		Pathfork : 8;
		Challenge : 4;
		White : 4;
		Coamo : 4;
	}
}
header_type Moorman {
	fields {
		Carbonado : 16;
		Alvordton : 16;
		Keenes : 16;
		Joaquin : 16;
	}
}
header_type Cannelton {
	fields {
		Viroqua : 6;
		Hatchel : 10;
		Orting : 4;
		Holyoke : 12;
		Reidville : 2;
		Swenson : 2;
		Opelika : 12;
		Bergoo : 8;
		Oklahoma : 2;
		Padonia : 3;
		Gordon : 1;
		Mulliken : 1;
		Lakehurst : 1;
		Richlawn : 4;
		Lansing : 12;
	}
}
header_type Ramah {
	fields {
		Emden : 24;
		Comobabi : 24;
		Faulkner : 24;
		ShowLow : 24;
		Excello : 16;
	}
}
header_type Sheyenne {
	fields {
		Govan : 3;
		LaPointe : 1;
		Woodridge : 12;
		Wagener : 16;
	}
}
header_type Slinger {
	fields {
		LakeLure : 20;
		Berwyn : 3;
		Hopland : 1;
		Silvertip : 8;
	}
}
header_type Moodys {
	fields {
		Dunnegan : 4;
		Kewanee : 4;
		McAllen : 6;
		Fairlee : 2;
		Diomede : 16;
		Wakeman : 16;
		Slana : 1;
		Robinson : 1;
		Raytown : 1;
		Mogote : 13;
		Buncombe : 8;
		RushCity : 8;
		Sagerton : 16;
		Reidland : 32;
		Ballville : 32;
	}
}
header_type Roseworth {
	fields {
		Benonine : 4;
		Osterdock : 6;
		Berea : 2;
		Absecon : 20;
		Bammel : 16;
		Millport : 8;
		Udall : 8;
		Chualar : 128;
		Rollins : 128;
	}
}
header_type Tafton {
	fields {
		Alamota : 4;
		Mulhall : 6;
		Safford : 2;
		Ravena : 20;
		Wakefield : 16;
		Macland : 8;
		Bonsall : 8;
		McCaulley : 32;
		Talihina : 32;
		Brave : 32;
		Haena : 32;
		Pinetop : 32;
		Patchogue : 32;
		Wenden : 32;
		Lundell : 32;
	}
}
header_type Hatteras {
	fields {
		Westboro : 8;
		Biehle : 8;
		Pacifica : 16;
	}
}
header_type Lisle {
	fields {
		Roodhouse : 16;
		Dunnellon : 16;
	}
}
header_type Rendville {
	fields {
		Berrydale : 32;
		Samson : 32;
		Millikin : 4;
		Mantee : 4;
		Sonestown : 8;
		Coulee : 16;
	}
}
header_type Dolores {
	fields {
		Othello : 16;
	}
}
header_type Hobergs {
	fields {
		Keltys : 16;
	}
}
header_type Arroyo {
	fields {
		Rosebush : 16;
		Covina : 16;
		Pardee : 8;
		Carlin : 8;
		Susank : 16;
	}
}
header_type Bienville {
	fields {
		Lemhi : 48;
		Mackville : 32;
		Kenyon : 48;
		Cornudas : 32;
	}
}
header_type Pound {
	fields {
		Cedar : 1;
		Terry : 1;
		Chaffey : 1;
		Ruthsburg : 1;
		Twisp : 1;
		Kerby : 3;
		Wrenshall : 5;
		Dwight : 3;
		Waseca : 16;
	}
}
header_type Newsoms {
	fields {
		BigWater : 24;
		Rendon : 8;
	}
}
header_type Dowell {
	fields {
		Frankston : 8;
		Madawaska : 24;
		Monowi : 24;
		Suntrana : 8;
	}
}
header_type Casco {
	fields {
		Huffman : 8;
	}
}
header_type SwissAlp {
	fields {
		Chicago : 32;
		Coffman : 32;
	}
}
header_type Neosho {
	fields {
		Klondike : 2;
		Drifton : 1;
		Tahuya : 1;
		Hilbert : 4;
		Paragonah : 1;
		Tabler : 7;
		Tusayan : 16;
		Diana : 32;
		National : 32;
	}
}
header_type Higgston {
	fields {
		Strevell : 32;
	}
}
header Ramah Linganore;
header Ramah Duffield;
header Sheyenne Nathan[2];
header Slinger Aguila[ 1 ];
@pragma pa_fragment ingress Idria.Sagerton
@pragma pa_fragment egress Idria.Sagerton
@pragma pa_container_size ingress Idria.Ballville 32
@pragma pa_container_size ingress Idria.Reidland 32
@pragma pa_container_size egress Idria.Slana 8
@pragma pa_container_size egress Idria.Robinson 8
@pragma pa_container_size egress Idria.Raytown 8
@pragma pa_container_size egress Idria.Mogote 8
header Moodys Idria;
@pragma pa_fragment ingress Pueblo.Sagerton
@pragma pa_fragment egress Pueblo.Sagerton
@pragma pa_container_size egress Pueblo.Mogote 8
@pragma pa_container_size egress Pueblo.Slana 8
@pragma pa_container_size egress Pueblo.Robinson 8
@pragma pa_container_size egress Pueblo.Raytown 8
header Moodys Pueblo;
@pragma pa_container_size egress LaVale.Rollins 32
@pragma pa_container_size egress LaVale.Chualar 32
header Roseworth LaVale;
@pragma pa_container_size ingress LaPryor.Rollins 32
@pragma pa_container_size egress LaPryor.Rollins 32
@pragma pa_container_size ingress LaPryor.Chualar 32
@pragma pa_container_size egress LaPryor.Chualar 32
header Roseworth LaPryor;
header Tafton Parshall;
@pragma disable_deparser_checksum_unit 0 1
header Lisle MillCity;
header Lisle Lafayette;
header Rendville Woodstown;
header Dolores Villanova;
header Hobergs Elbing;
header Rendville OldMinto;
header Dolores Hilburn;
header Hobergs Blackman;
@pragma pa_container_size egress Absarokee.Monowi 32
@pragma pa_container_size egress Absarokee.Madawaska 32
@pragma pa_container_size ingress Absarokee.Madawaska 32
header Dowell Absarokee;
header Pound Wanatah;
header Arroyo Titonka;
// @pragma pa_container_size egress NewTrier.Viroqua 32
@pragma not_deparsed ingress
@pragma not_parsed egress
header Cannelton NewTrier;
@pragma not_deparsed ingress
@pragma not_parsed egress
header Casco Parkway;
header SwissAlp Gowanda;
@pragma parser_value_set_size 2
parser_value_set Gahanna;
@pragma parser_value_set_size 32
parser_value_set Monahans;
parser start {
   return select( ig_intr_md.ingress_port ) {
      Gahanna : Lemoyne;
      default : Waukesha;
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
      default : Waukesha;
      0xBF00 : Molson;
   }
}
parser Lopeno {
   return select( current(0, 32) ) {
      0x00010800 : Cidra;
      default : ingress;
   }
}
parser Cidra {
   extract( Titonka );
   return ingress;
}
@pragma not_critical
parser Molson {
   extract( NewTrier );
   return Waukesha;
}
@pragma force_shift ingress 112
parser Lemoyne {
   return Alberta;
}
@pragma not_critical
parser Alberta {
   extract( NewTrier );
   return Waukesha;
}
parser Homeworth {
   set_metadata(Chardon.Snohomish, 0x5);
   return ingress;
}
parser Fabens {
   set_metadata(Chardon.Snohomish, 0x6);
   return ingress;
}
parser Crystola {
   set_metadata( Chardon.Snohomish, 0x8 );
   return ingress;
}
parser Waukesha {
   extract( Linganore );
   return select( current(0, 8), Linganore.Excello ) {
      0x9100 mask 0xFFFF : Baranof;
      0x88a8 mask 0xFFFF : Baranof;
      0x8100 mask 0xFFFF : Baranof;
      0x0806 mask 0xFFFF : Lopeno;
      0x450800 : Talmo;
      0x50800 mask 0xFFFFF : Homeworth;
      0x0800 mask 0xFFFF : Driftwood;
      0x6086dd mask 0xF0FFFF : Azalia;
      0x86dd mask 0xFFFF : Fabens;
      0x8808 mask 0xFFFF : Crystola;
      default : ingress;
      0 : DelRey;
   }
}
parser Pinebluff {
   extract( Nathan[1] );
   return select( current(0, 8), Nathan[1].Wagener ) {
      0x0806 mask 0xFFFF : Lopeno; 0x450800 : Talmo; 0x50800 mask 0xFFFFF : Homeworth; 0x0800 mask 0xFFFF : Driftwood; 0x6086dd mask 0xF0FFFF : Azalia; 0x86dd mask 0xFFFF : Fabens; default : ingress;
   }
}
parser Baranof {
   extract( Nathan[0] );
   return select( current(0, 8), Nathan[0].Wagener ) {
      0x8100 mask 0xFFFF : Pinebluff;
      0x0806 mask 0xFFFF : Lopeno; 0x450800 : Talmo; 0x50800 mask 0xFFFFF : Homeworth; 0x0800 mask 0xFFFF : Driftwood; 0x6086dd mask 0xF0FFFF : Azalia; 0x86dd mask 0xFFFF : Fabens; default : ingress;
   }
}
field_list Komatke {
   Idria.Dunnegan;
   Idria.Kewanee;
   Idria.McAllen;
   Idria.Fairlee;
   Idria.Diomede;
   Idria.Wakeman;
   Idria.Slana;
   Idria.Robinson;
   Idria.Raytown;
   Idria.Mogote;
   Idria.Buncombe;
   Idria.RushCity;
   Idria.Reidland;
   Idria.Ballville;
}
field_list_calculation Hobucken {
   input {
      Komatke;
   }
   algorithm : csum16;
   output_width : 16;
}
calculated_field Idria.Sagerton {
   verify Hobucken;
   update Hobucken;
}
parser Talmo {
   extract( Idria );
   set_metadata(Allison.Lattimore, Idria.Buncombe);
   set_metadata(Chardon.Snohomish, 0x1);
   return select(Idria.Mogote, Idria.RushCity) {
      1 : Cement;
      17 : Yantis;
      6 : Farner;
      47 : Issaquah;
      0 mask 0x1fff00 : ingress;
      6 mask 0xff: Cresco;
      default : Gardena;
   }
}
parser Driftwood {
   set_metadata(Idria.Ballville, current(128,32));
   set_metadata(Chardon.Snohomish, 0x3);
   set_metadata(Idria.McAllen, current(8, 6));
   set_metadata(Idria.RushCity, current(72,8));
   set_metadata(Allison.Lattimore, current(64,8));
   return ingress;
}
parser Cresco {
   set_metadata(Chardon.Victoria, 5);
   return ingress;
}
parser Gardena {
   set_metadata(Chardon.Victoria, 1);
   return ingress;
}
parser Azalia {
   extract( LaPryor );
   set_metadata(Allison.Lattimore, LaPryor.Udall);
   set_metadata(Chardon.Snohomish, 0x2);
   return select(LaPryor.Millport) {
      0x3a : Cement;
      17 : Harvest;
      6 : Farner;
      default : ingress;
   }
}
parser DelRey {
   extract( Parshall );
   set_metadata(Allison.Lattimore, Parshall.Bonsall);
   set_metadata(Chardon.Snohomish, 0x2);
   return select(Parshall.Macland) {
      0x3a : Cement;
      17 : Harvest;
      6 : Farner;
      default : ingress;
   }
}
parser Yantis {
   set_metadata(Chardon.Victoria, 2);
   extract(MillCity);
   extract(Villanova);
   extract(Elbing);
   return select(MillCity.Dunnellon) {
      4789 : Daleville;
      65330 : Daleville;
      default : ingress;
    }
}
header Neosho Lauada;
parser LaCueva {
   extract( Lauada );
   return ingress;
}
parser Cement {
   extract(MillCity);
   return ingress;
}
parser Harvest {
   set_metadata(Chardon.Victoria, 2);
   extract(MillCity);
   extract(Villanova);
   extract(Elbing);
   return select(MillCity.Dunnellon) {
      default : ingress;
   }
}
parser Farner {
   set_metadata(Chardon.Victoria, 6);
   extract(MillCity);
   extract(Woodstown);
   extract(Elbing);
   return ingress;
}
parser Bayard {
   set_metadata(Allison.Pinecreek, 2);
   return select( current(4, 4) ) {
      0x5 : Nathalie;
      default : Romeo;
   }
}
parser Merino {
   return select( current(0,4) ) {
      0x4 : Bayard;
      default : ingress;
   }
}
parser Gregory {
   set_metadata(Allison.Pinecreek, 2);
   return WestPike;
}
parser Rotonda {
   return select( current(0,4) ) {
      0x6 : Gregory;
      default: ingress;
   }
}
parser Issaquah {
   extract(Wanatah);
   return select(Wanatah.Cedar, Wanatah.Terry, Wanatah.Chaffey, Wanatah.Ruthsburg, Wanatah.Twisp,
             Wanatah.Kerby, Wanatah.Wrenshall, Wanatah.Dwight, Wanatah.Waseca) {
      0x0800 : Merino;
      0x86dd : Rotonda;
      default : ingress;
   }
}
parser Daleville {
   extract(Absarokee);
   set_metadata(Allison.Pinecreek, 1);
   return DeLancey;
}
parser Farnham {
   extract(Absarokee);
   set_metadata(Allison.Pinecreek, 1);
   return Kinney;
}
field_list Mathias {
   Pueblo.Dunnegan;
   Pueblo.Kewanee;
   Pueblo.McAllen;
   Pueblo.Fairlee;
   Pueblo.Diomede;
   Pueblo.Wakeman;
   Pueblo.Slana;
   Pueblo.Robinson;
   Pueblo.Raytown;
   Pueblo.Mogote;
   Pueblo.Buncombe;
   Pueblo.RushCity;
   Pueblo.Reidland;
   Pueblo.Ballville;
}
field_list_calculation Carlson {
   input {
      Mathias;
   }
   algorithm : csum16;
   output_width : 16;
}
calculated_field Pueblo.Sagerton {
   verify Carlson;
   update Carlson;
}
parser Nathalie {
   extract( Pueblo );
   set_metadata(Chardon.Ardsley, Pueblo.RushCity);
   set_metadata(Chardon.Williams, Pueblo.Buncombe);
   set_metadata(Chardon.Ishpeming, 0x1);
   set_metadata(MudLake.LaMoille, Pueblo.Reidland);
   set_metadata(MudLake.SanSimon, Pueblo.Ballville);
   set_metadata(MudLake.Kress, Pueblo.McAllen);
   return select(Pueblo.Mogote, Pueblo.RushCity) {
      1 : Offerle;
      17 : Almota;
      6 : Strasburg;
      0 mask 0x1fff00 : ingress;
      6 mask 0xff: Korbel;
      default : Newfolden;
   }
}
parser Romeo {
   set_metadata(Chardon.Ishpeming, 0x3);
   set_metadata(MudLake.Kress, current(8, 6));
   return ingress;
}
parser Korbel {
   set_metadata(Chardon.Trego, 5);
   return ingress;
}
parser Newfolden {
   set_metadata(Chardon.Trego, 1);
   return ingress;
}
parser WestPike {
   extract( LaVale );
   set_metadata(Chardon.Ardsley, LaVale.Millport);
   set_metadata(Chardon.Williams, LaVale.Udall);
   set_metadata(Chardon.Ishpeming, 0x2);
   set_metadata(Gunder.Fairlea, LaVale.Osterdock);
   set_metadata(Gunder.Hamden, LaVale.Chualar);
   set_metadata(Gunder.Varnado, LaVale.Rollins);
   return select(LaVale.Millport) {
      0x3a : Offerle;
      17 : Almota;
      6 : Strasburg;
      default : ingress;
   }
}
parser Offerle {
   set_metadata( Allison.Tiverton, current( 0, 16 ) );
   extract(Lafayette);
   return ingress;
}
parser Almota {
   set_metadata( Allison.Tiverton, current( 0, 16 ) );
   set_metadata( Allison.PawCreek, current( 16, 16 ) );
   set_metadata(Chardon.Trego, 2);
   extract(Lafayette);
   extract(Hilburn);
   extract(Blackman);
   return ingress;
}
parser Strasburg {
   set_metadata( Allison.Tiverton, current( 0, 16 ) );
   set_metadata( Allison.PawCreek, current( 16, 16 ) );
   set_metadata( Allison.Hephzibah, current( 104, 8 ) );
   set_metadata(Chardon.Trego, 6);
   extract(Lafayette);
   extract(OldMinto);
   extract(Blackman);
   return ingress;
}
parser Moark {
   set_metadata(Chardon.Ishpeming, 0x5);
   return ingress;
}
parser Clarissa {
   set_metadata(Chardon.Ishpeming, 0x6);
   return ingress;
}
parser DeLancey {
   extract( Duffield );
   set_metadata( Allison.Dizney, Duffield.Emden );
   set_metadata( Allison.Ralls, Duffield.Comobabi );
   set_metadata( Allison.Domestic, Duffield.Excello );
   return select( current( 0, 8 ), Duffield.Excello ) {
      0x0806 mask 0xFFFF : Lopeno;
      0x450800 : Nathalie;
      0x50800 mask 0xFFFFF : Moark;
      0x0800 mask 0xFFFF : Romeo;
      0x6086dd mask 0xF0FFFF : WestPike;
      0x86dd mask 0xFFFF : Clarissa;
      default: ingress;
   }
}
parser Kinney {
   extract( Duffield );
   set_metadata( Allison.Dizney, Duffield.Emden );
   set_metadata( Allison.Ralls, Duffield.Comobabi );
   set_metadata( Allison.Domestic, Duffield.Excello );
   return select( current( 0, 8 ), Duffield.Excello ) {
      0x0806 mask 0xFFFF : Lopeno;
      0x450800 : Nathalie;
      0x50800 mask 0xFFFFF : Moark;
      0x0800 mask 0xFFFF : Romeo;
      default: ingress;
   }
}
@pragma pa_overlay_stage_separation ingress ig_intr_md_for_tm.qid 1
@pragma pa_container_size ingress ig_intr_md_for_tm.qid 8
// @pragma pa_container_size ingress NewTrier.Hatchel 32
@pragma pa_container_size ingress PineHill.LaSalle 16
@pragma pa_container_size ingress PineHill.Coachella 16
@pragma pa_container_size ingress PineHill.Jenifer 16
@pragma pa_container_size ingress Allison.Osseo 16
@pragma pa_container_size ingress Stillmore.Lueders 16
@pragma pa_no_init ingress Allison.Dizney
@pragma pa_no_init ingress Allison.Ralls
@pragma pa_no_init ingress Allison.Havana
@pragma pa_no_init ingress Allison.Jamesport
@pragma pa_container_size ingress Allison.Sunrise 8
@pragma pa_container_size ingress Allison.Kaplan 8
@pragma pa_no_init ingress Allison.Virginia
@pragma pa_container_size ingress Allison.Freeny 8
metadata Lynndyl Allison;
@pragma pa_allowed_to_share egress Stillmore.Eaton Moreland.Oklee
@pragma pa_container_size ingress Stillmore.Munich 32
@pragma pa_container_size ingress Stillmore.Parkland 32
@pragma pa_container_size ingress Allison.Easley 32
@pragma pa_no_init ingress Stillmore.Summit
@pragma pa_no_init ingress Stillmore.Lookeba
@pragma pa_container_size ingress Stillmore.Bozar 32
@pragma pa_no_overlay ingress Stillmore.Lueders
@pragma pa_solitary ingress Stillmore.Lueders
metadata Minburn Stillmore;
metadata Otranto Mondovi;
metadata Sunset Moreland;
metadata Gilman Townville;
metadata Knolls Chardon;
@pragma pa_container_size ingress Comptche.Attica 16
@pragma pa_container_size ingress MudLake.Quinwood 16
metadata Roberta MudLake;
@pragma pa_container_size ingress Gunder.Milano 16
metadata Nashua Gunder;
@pragma pa_mutually_exclusive ingress MudLake.LaMoille Gunder.Hamden
@pragma pa_mutually_exclusive ingress MudLake.SanSimon Gunder.Varnado
@pragma pa_mutually_exclusive ingress MudLake.Kress Gunder.Fairlea
@pragma pa_alias ingress MudLake.Quinwood Gunder.Milano
@pragma pa_alias ingress Comptche.Gomez Comptche.Attica
metadata Cotuit Basalt;
@pragma pa_container_size egress Kenefic.SneeOosh 8
metadata Plata Kenefic;
@pragma pa_container_size ingress Shorter.Pelican 8
@pragma pa_container_size ingress Shorter.Frederika 8
metadata Geismar Shorter;
metadata Charlack Nanakuli;
metadata Sturgis Comptche;
@pragma pa_no_init ingress Lenoir.Brinson
@pragma pa_no_init ingress Lenoir.Vananda
@pragma pa_no_init ingress Martelle.Tanana
@pragma pa_no_init ingress Martelle.Wauna
@pragma pa_no_init ingress Martelle.Danese
@pragma pa_no_init ingress Martelle.Taconite
@pragma pa_no_init ingress Martelle.Vigus
@pragma pa_no_init ingress Martelle.Provo
@pragma pa_container_size ingress Lenoir.Brinson 16
@pragma pa_mutually_exclusive ingress Lenoir.Brinson Lenoir.Vananda
metadata Naalehu Lenoir;
metadata Mentmore Martelle;
metadata Woodward PineHill;
metadata Glenvil Chitina;
@pragma pa_no_init ingress Allerton.Gerlach
@pragma pa_solitary ingress Allerton.Risco
metadata Kaibab Allerton;
@pragma pa_container_size egress Stillmore.AvonLake 32
@pragma pa_alias egress Stillmore.AvonLake Stillmore.Golden
@pragma pa_no_init egress Stillmore.Shelbina
@pragma pa_no_init egress Stillmore.AvonLake
@pragma pa_container_size ingress Rippon.Oskaloosa 8
@pragma pa_no_init ingress Rippon.Konnarock
metadata Allen Rippon;
@pragma pa_no_init ingress Wanilla.Alcester
@pragma pa_no_init ingress Wanilla.Worthing
metadata MuleBarn Wanilla;
metadata MuleBarn Redvale;
metadata Wheeler Paisano;
metadata Grabill Gotham;
metadata Hector Coleman;
action Sonora() {
   no_op();
}
action Brazos() {
   modify_field( Allison.Adona, 1 );
}
action Edwards() {
   no_op();
}
@pragma pa_container_size ingress Townville.Bells 16
@pragma pa_container_size ingress Townville.Harold 16
action Tununak(Oneonta, Champlin, Bajandas, Callao ) {
   modify_field(Townville.Bells, Oneonta);
   modify_field(Townville.Harold, Champlin);
   modify_field(Townville.Coventry, Bajandas);
   modify_field(Townville.Geeville, Callao);
}
@pragma phase0 1
table Coyote {
   reads {
      ig_intr_md.ingress_port : exact;
   }
   actions {
      Tununak;
   }
   default_action : Tununak(0,0,0,0);
   size : 288;
}
control Troutman {
   if (ig_intr_md.resubmit_flag == 0) {
      apply(Coyote);
   }
}
action Weimar(Valeene, Langston) {
   modify_field( Stillmore.Verbena, 1 );
   modify_field( Stillmore.Mahopac, Valeene);
   modify_field( Allison.Sunrise, 1 );
   modify_field( PineHill.McCammon, Langston );
   modify_field( Allison.Minatare, 1 );
}
action Hoven(Bellmead, GilaBend) {
   modify_field( Stillmore.Mahopac, Bellmead);
   modify_field( Allison.Sunrise, 1 );
   modify_field( PineHill.McCammon, GilaBend );
}
action Spindale() {
   modify_field( Allison.Hooker, 1 );
   modify_field( Allison.Grays, 1 );
}
action Union() {
   modify_field( Allison.Sunrise, 1 );
}
action Ingraham() {
   modify_field( Allison.Sunrise, 1 );
   modify_field( Allison.Lamar, 1 );
}
action Myoma() {
   modify_field( Allison.Kaplan, 1 );
}
action Hadley() {
   modify_field( Allison.Grays, 1 );
}
counter Frederick {
   type : packets_and_bytes;
   direct : Emlenton;
   min_width: 16;
}
@pragma immediate 0
table Emlenton {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Linganore.Emden : ternary;
      Linganore.Comobabi : ternary;
   }
   actions {
      Weimar;
      Spindale;
      Union;
      Myoma;
      Hadley;
      Ingraham;
      Hoven;
   }
   default_action: Sonora();
   size : 2048;
}
action Earlsboro() {
   modify_field( Allison.Arpin, 1 );
}
table Oilmont {
   reads {
      Linganore.Faulkner : ternary;
      Linganore.ShowLow : ternary;
   }
   actions {
      Earlsboro;
   }
   size : 512;
}
control Jesup {
   apply( Emlenton ) {
      Weimar { }
      default {
         LeaHill();
      }
   }
   apply( Oilmont );
}
action Naguabo() {
   modify_field( Wanilla.Caliente, MillCity.Roodhouse );
   modify_field( Wanilla.Hanford, Chardon.Victoria, 1);
}
action Mabel() {
   modify_field( Wanilla.Caliente, Allison.Tiverton );
   modify_field( Wanilla.Hanford, Chardon.Trego, 1);
}
action Westvaco() {
   modify_field( Allison.Havana, Duffield.Faulkner );
   modify_field( Allison.Jamesport, Duffield.ShowLow );
   modify_field( Allison.Bernstein, Chardon.Ardsley );
   modify_field( Allison.Lattimore, Chardon.Williams );
   modify_field( Allison.Virginia, Chardon.Ishpeming, 0x7 );
   modify_field( Stillmore.Campo, 1 );
   modify_field( Allison.Elloree, Chardon.Trego );
   Mabel();
}
action Poynette() {
   modify_field( PineHill.Coachella, Nathan[0].LaPointe );
   modify_field( Allison.Harshaw, Nathan[0].valid );
   modify_field( Allison.Pinecreek, 0 );
   modify_field( Allison.Dizney, Linganore.Emden );
   modify_field( Allison.Ralls, Linganore.Comobabi );
   modify_field( Allison.Havana, Linganore.Faulkner );
   modify_field( Allison.Jamesport, Linganore.ShowLow );
   modify_field( Allison.Virginia, Chardon.Snohomish, 0x7 );
   modify_field( Allison.Domestic, Linganore.Excello );
}
action Brawley() {
   modify_field( Allison.Tiverton, MillCity.Roodhouse );
   modify_field( Allison.PawCreek, MillCity.Dunnellon );
   modify_field( Allison.Hephzibah, Woodstown.Sonestown );
   modify_field( Allison.Elloree, Chardon.Victoria );
   Naguabo();
}
action Homeacre() {
   Poynette();
   modify_field( Gunder.Hamden, LaPryor.Chualar );
   modify_field( Gunder.Varnado, LaPryor.Rollins );
   modify_field( Gunder.Fairlea, LaPryor.Osterdock );
   modify_field( Allison.Bernstein, LaPryor.Millport );
   Brawley();
}
action Boquillas() {
   Poynette();
   modify_field( MudLake.LaMoille, Idria.Reidland );
   modify_field( MudLake.SanSimon, Idria.Ballville );
   modify_field( MudLake.Kress, Idria.McAllen );
   modify_field( Allison.Bernstein, Idria.RushCity );
   Brawley();
}
@pragma action_default_only Boquillas
table BigWells {
   reads {
      Linganore.Emden : ternary;
      Linganore.Comobabi : ternary;
      Idria.Ballville : ternary;
      Allison.Pinecreek : ternary;
      LaPryor.valid : exact;
   }
   actions {
      Westvaco;
      Homeacre;
   }
   default_action : Boquillas();
   size : 512;
}
action Tennyson(Shoreview) {
   modify_field( Allison.Osseo, Townville.Harold );
   modify_field( Allison.BlackOak, Shoreview);
}
action Minneiska( Humacao, Maybeury ) {
   modify_field( Allison.Osseo, Humacao );
   modify_field( Allison.BlackOak, Maybeury);
   modify_field( Townville.Coventry, 1 );
}
action Belwood(Gurdon) {
   modify_field( Allison.Osseo, Nathan[0].Woodridge );
   modify_field( Allison.BlackOak, Gurdon);
}
@pragma use_container_valid Nathan[0].valid Nathan[0].Woodridge
table Harvey {
   reads {
      Townville.Coventry : exact;
      Townville.Bells : exact;
      Nathan[0] : valid;
      Nathan[0].Woodridge : ternary;
   }
   actions {
      Tennyson;
      Minneiska;
      Belwood;
   }
   size : 16;
}
action Maida( Lasker ) {
   modify_field( Allison.BlackOak, Lasker );
}
action Washoe() {
   modify_field( Nanakuli.Bonner,
                 3 );
}
action Harriet() {
   modify_field( Nanakuli.Bonner,
                 1 );
}
@pragma immediate 0
table Kaluaaha {
   reads {
      Idria.Reidland : exact;
   }
   actions {
      Maida;
      Washoe;
      Harriet;
   }
   default_action : Washoe;
   size : 4096;
}
@pragma immediate 0
table Kapowsin {
   reads {
      LaPryor.Chualar : exact;
   }
   actions {
      Maida;
      Washoe;
      Harriet;
   }
   default_action : Washoe;
   size : 4096;
}
action Montalba( Latham, Chehalis, Cusick, Monida ) {
   modify_field( Allison.Osseo, Latham );
   modify_field( Allison.Kalskag, Latham );
   Cusseta( Chehalis, Cusick, Monida );
}
action Brodnax() {
   modify_field( Allison.Clarinda, 1 );
}
@pragma immediate 0
table Leonidas {
   reads {
      Absarokee.Monowi : exact;
   }
   actions {
      Montalba;
      Brodnax;
   }
   size : 4096;
}
action Cusseta(Cadott, Nondalton, Amite) {
   modify_field( Shorter.Pelican, Nondalton );
   modify_field( MudLake.Leola, Cadott );
   modify_field( Shorter.Nuremberg, Amite );
}
action Ulysses( Cahokia ) {
}
action Niota(LoonLake, Cushing, Bodcaw, McCaskill) {
   modify_field( Allison.Kalskag, Townville.Harold );
   Ulysses( McCaskill );
   Cusseta( LoonLake, Cushing, Bodcaw );
}
action Forman(Parmelee, Tecumseh, Paullina, Burtrum, LaUnion) {
   modify_field( Allison.Kalskag, Parmelee );
   Ulysses( LaUnion );
   Cusseta( Tecumseh, Paullina, Burtrum );
}
action Caban(Lutts, Hiawassee, Vinita, Brimley) {
   modify_field( Allison.Kalskag, Nathan[0].Woodridge );
   Ulysses( Brimley );
   Cusseta( Lutts, Hiawassee, Vinita );
}
table Overton {
   reads {
      Townville.Harold : exact;
   }
   actions {
      Niota;
   }
   size : 16;
}
@pragma action_default_only Sonora
table Reinbeck {
   reads {
      Townville.Bells : exact;
      Nathan[0].Woodridge : exact;
   }
   actions {
      Forman;
      Sonora;
   }
   size : 16;
}
action Calhan() {
   modify_field( Allison.Biddle, 1);
}
@pragma immediate 0
@pragma ignore_table_dependency Harvey
table Smithland {
   reads {
      Townville.Coventry :exact;
      Nathan[0].Woodridge : exact;
   }
   actions {
      Caban;
   }
   default_action : Calhan();
   size : 16;
}
control Dixfield {
   apply( BigWells ) {
      Westvaco {
         if( Idria.valid == 1 ) {
            apply( Kaluaaha );
         } else {
            apply( Kapowsin );
         }
         apply( Leonidas );
      }
      default {
         apply( Harvey );
         if ( valid( Nathan[0] ) and Nathan[0].Woodridge != 0 ) {
            apply( Reinbeck ) {
               Sonora {
                  apply( Smithland );
               }
            }
         } else {
            apply( Overton );
         }
      }
   }
}
@pragma idletime_precision 1
@pragma force_immediate 1
@pragma ways 4
table Mammoth {
   reads {
      Shorter.Pelican : exact;
      MudLake.SanSimon : exact;
   }
   actions {
      Rodessa;
      Pecos;
      Steger;
      Margie;
      Sonora;
   }
   default_action : Sonora();
   size : 512;
   support_timeout : true;
}
@pragma idletime_precision 1
@pragma stage 2 128
@pragma stage 3
@pragma force_immediate 1
@pragma ways 4
table Hanston {
   reads {
      Shorter.Pelican : exact;
      Gunder.Varnado : exact;
   }
   actions {
      Rodessa;
      Pecos;
      Steger;
      Margie;
      Sonora;
   }
   default_action : Sonora();
   size : 512;
   support_timeout : true;
}
action Garlin( Laxon, Walnut ) {
   modify_field( Comptche.Windber, Laxon );
   modify_field( Comptche.Haugen, Walnut );
}
action Negra( Ossipee, Panacea ) {
   modify_field( MudLake.Quinwood, Ossipee );
   Rodessa( Panacea );
}
action Croghan( Nuevo, Newcastle ) {
   modify_field( MudLake.Quinwood, Nuevo );
   Pecos( Newcastle );
}
action Kalida( Lafourche, Lofgreen ) {
   modify_field( MudLake.Quinwood, Lafourche );
   Steger( Lofgreen );
}
action Waxhaw( Okaton, Colona ) {
   modify_field( MudLake.Quinwood, Okaton );
   Margie( Colona );
}
action Corvallis( Neches ) {
   modify_field( MudLake.Quinwood, Neches );
}
@pragma force_immediate 1
table Coverdale {
   reads {
      Shorter.Pelican mask 0x7F : exact;
      MudLake.Leola: lpm;
   }
   actions {
      Negra;
      Croghan;
      Kalida;
      Waxhaw;
      Corvallis;
      Sonora;
   }
   size : 1024;
}
action Woodston( Lampasas, Saragosa ) {
   modify_field( Gunder.Milano, Lampasas );
   Rodessa( Saragosa );
}
action Hackett( Sylvester, Tamaqua ) {
   modify_field( Gunder.Milano, Sylvester );
   Pecos( Tamaqua );
}
action Portis( Jamesburg, Edmeston ) {
   modify_field( Gunder.Milano, Jamesburg );
   Steger( Edmeston );
}
action Barnhill( Sunflower, Colfax ) {
   modify_field( Gunder.Milano, Sunflower );
   Margie( Colfax );
}
@pragma force_immediate 1
table Comfrey {
   reads {
      Shorter.Pelican : exact;
      Gunder.Varnado mask 0xFFFFFFFFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Woodston;
      Hackett;
      Portis;
      Barnhill;
      Sonora;
   }
   default_action : Sonora();
   size : 1024;
}
action Clarendon( HornLake, RockPort ) {
   modify_field( Gunder.Milano, HornLake );
   Rodessa( RockPort );
}
action Sigsbee( Francis, Dorothy ) {
   modify_field( Gunder.Milano, Francis );
   Pecos( Dorothy );
}
action Boquet( Cadwell, Newsome ) {
   modify_field( Gunder.Milano, Cadwell );
   Steger( Newsome );
}
action Belfalls( Aniak, SantaAna ) {
   modify_field( Gunder.Milano, Aniak );
   Margie( SantaAna );
}
@pragma action_default_only Sonora
@pragma force_immediate 1
table Lenapah {
   reads {
      Shorter.Pelican : exact;
      Gunder.Varnado : lpm;
   }
   actions {
      Clarendon;
      Sigsbee;
      Boquet;
      Belfalls;
      Sonora;
   }
   size : 1024;
}
control Thistle {
   apply( Mammoth ) {
      Sonora {
         apply( Coverdale );
      }
   }
}
control Ballinger {
   apply( Hanston ) {
      Sonora {
         apply( Lenapah );
      }
   }
}
@pragma ways 2
@pragma atcam_partition_index MudLake.Quinwood
@pragma atcam_number_partitions 1024
@pragma force_immediate 1
@pragma action_default_only Upalco
table Atlantic {
   reads {
      MudLake.Quinwood mask 0x7fff: exact;
      MudLake.SanSimon mask 0x000fffff : lpm;
   }
   actions {
      Rodessa;
      Pecos;
      Steger;
      Margie;
      Upalco;
   }
   default_action : Upalco();
   size : 16384;
}
@pragma atcam_partition_index Gunder.Milano
@pragma atcam_number_partitions 1024
table Hookdale {
   reads {
      Gunder.Milano mask 0x7FF : exact;
      Gunder.Varnado mask 0x0000000000000000FFFFFFFFFFFFFFFF : lpm;
   }
   actions {
      Rodessa;
      Pecos;
      Steger;
      Margie;
      Sonora;
   }
   default_action : Sonora();
   size : 8192;
}
  @pragma ways 1
@pragma atcam_partition_index Gunder.Milano
@pragma atcam_number_partitions 1024
table Kaweah {
   reads {
      Gunder.Milano mask 0x1fff: exact;
      Gunder.Varnado mask 0x000003FFFFFFFFFF0000000000000000 : lpm;
   }
   actions {
      Margie;
      Rodessa;
      Pecos;
      Steger;
      Sonora;
   }
   default_action : Sonora();
   size : 8192;
}
action Rodessa( HighRock ) {
   modify_field( Comptche.LaSal, 0 );
   modify_field( Comptche.Attica, HighRock );
}
action Pecos( Gratis ) {
   modify_field( Comptche.LaSal, 2 );
   modify_field( Comptche.Attica, Gratis );
}
action Steger( Warsaw ) {
   modify_field( Comptche.LaSal, 3 );
   modify_field( Comptche.Attica, Warsaw );
}
action Oketo( Brownson, Merrill ) {
   modify_field( Comptche.LaSal, 0 );
   modify_field( Comptche.Attica, Merrill );
}
action Margie( Leawood ) {
   modify_field( Comptche.Gomez, Leawood );
   modify_field( Comptche.LaSal, 1 );
}
action Upalco() {
}
action Doyline() {
   Rodessa( 1 );
}
@pragma idletime_precision 1
@pragma force_immediate 1
@pragma action_default_only Doyline
table Grygla {
   reads {
      Shorter.Pelican : exact;
      MudLake.SanSimon mask 0xFFF00000 : lpm;
   }
   actions {
      Rodessa;
      Pecos;
      Steger;
      Margie;
   }
   default_action : Doyline();
   size : 128;
   support_timeout : true;
}
action Miller() {
   Rodessa( 1 );
}
@pragma action_default_only Miller
@pragma idletime_precision 1
@pragma force_immediate 1
table Purley {
   reads {
      Shorter.Pelican : exact;
      Gunder.Varnado mask 0xFFFFFC00000000000000000000000000: lpm;
   }
   actions {
      Rodessa;
      Pecos;
      Steger;
      Margie;
      Miller;
   }
   size : 64;
   support_timeout : true;
}
action Westbrook(Pedro) {
   Rodessa( Pedro );
}
table Milwaukie {
   reads {
      Shorter.Nuremberg mask 0x1 : exact;
      Allison.Virginia : exact;
   }
   actions {
      Westbrook;
   }
   default_action: Westbrook;
   size : 2;
}
control Hiwassee {
   if ( Allison.Adona == 0 and Shorter.Frederika == 1 and
        Basalt.Roxboro == 0 and Basalt.Harris == 0 ) {
      if ( ( ( Shorter.Nuremberg & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Allison.Virginia == 0x1 ) ) {
         if ( MudLake.Quinwood != 0 ) {
            apply( Atlantic );
         } else if ( Comptche.Attica == 0 ) {
            apply( Grygla );
         }
      } else if ( ( ( Shorter.Nuremberg & ( 0x2 ) ) == ( ( 0x2 ) ) ) and Allison.Virginia == 0x2 ) {
         if ( Gunder.Milano != 0 ) {
            apply( Hookdale );
         } else if ( Comptche.Attica == 0 ) {
            apply( Comfrey );
            if ( Gunder.Milano != 0 ) {
               apply( Kaweah );
            } else if ( Comptche.Attica == 0 ) {
               apply( Purley );
            }
         }
      } else if ( ( Stillmore.Verbena == 0 ) and ( ( Allison.Amazonia == 1 ) or
            ( ( ( Shorter.Nuremberg & ( 0x1 ) ) == ( ( 0x1 ) ) ) and ( Allison.Virginia == 0x3 ) ) ) ) {
         apply( Milwaukie );
      }
   }
}
field_list NewRome {
   Lenoir.Vananda;
   ig_intr_md.ingress_port;
}
field_list_calculation Orlinda {
   input {
      NewRome;
   }
   algorithm : crc16_extend;
   output_width : 66;
}
action_selector Tchula {
   selection_key : Orlinda;
   selection_mode : resilient;
}
action_profile Glennie {
   actions {
      Oketo;
   }
   size : 65536;
   dynamic_action_selection : Tchula;
}
@pragma selector_max_group_size 256
@pragma immediate 0
table Tenstrike {
   reads {
      Comptche.Gomez mask 0x3ff: exact;
   }
   action_profile : Glennie;
   size : 1024;
}
action Naubinway() {
   modify_field( Allison.Headland, Allison.Tekonsha );
}
table Merced {
   actions {
      Naubinway;
   }
   default_action : Naubinway();
   size : 1;
}
action Waterflow(Buckholts) {
   modify_field(Stillmore.Verbena, 1);
   modify_field(Stillmore.Mahopac, Buckholts);
}
table Albin {
   reads {
      Comptche.Attica mask 0xF: exact;
   }
   actions {
      Waterflow;
   }
   size : 16;
}
action Macungie(Burwell, Sarepta, Madeira) {
   modify_field(Stillmore.Summit, Burwell);
   modify_field(Stillmore.Lookeba, Sarepta);
   modify_field(Stillmore.Lueders, Madeira);
}
@pragma use_hash_action 1
table Craigmont {
   reads {
      Comptche.Attica mask 0x7FFF : exact;
   }
   actions {
      Macungie;
   }
   default_action : Macungie(0,0,0);
   size : 32768;
}
action Temvik(Quivero, Goosport, Lilly) {
   modify_field(Stillmore.Junior, 1);
   modify_field(Stillmore.Munich, Quivero);
   modify_field(Stillmore.Parkland, Goosport);
   modify_field(Allison.Easley, Lilly);
}
@pragma use_hash_action 1
table Escatawpa {
   reads {
      Comptche.Attica mask 0xFFFF : exact;
   }
   actions {
      Temvik;
   }
   default_action : Temvik(511,0,0);
   size : 32768;
}
control Corinne {
   if ( Comptche.LaSal == 1 ) {
      apply( Tenstrike );
   }
}
control DeepGap {
   if( Comptche.Attica != 0 ) {
      apply( Merced );
      if( ( ( Comptche.Attica & 0xFFF0 ) == 0 ) ) {
         apply( Albin );
      } else {
         apply( Escatawpa );
      }
   }
}
action Kingman() {
   modify_field(Stillmore.Campo, 0);
   modify_field(Stillmore.Verbena, 1);
   modify_field(Stillmore.Mahopac, 16);
}
table Larchmont {
   actions {
      Kingman;
   }
   default_action : Kingman();
   size : 1;
}
action Rotterdam() {
   modify_field(Allison.Cornell, 1);
}
@pragma ways 1
table Highfill {
   reads {
      Duffield.Emden : ternary;
      Duffield.Comobabi : ternary;
      Idria.Ballville : exact;
   }
   actions {
      Rotterdam;
      Edwards;
   }
   default_action : Rotterdam();
   size : 512;
}
control Lovewell {
   if(Townville.Geeville != 0 and Stillmore.Campo == 1 and Shorter.Frederika == 1) {
      apply(Highfill);
   }
}
control Madison {
   if(Townville.Geeville != 0 and Stillmore.Campo == 1 and ( ( Shorter.Nuremberg & ( 0x1 ) ) == ( ( 0x1 ) ) ) and Duffield.Excello==0x0806) {
      apply(Larchmont);
   }
}
register Hammocks {
   width : 1;
   static : Portal;
   instance_count : 294912;
}
register Gully {
   width : 1;
   static : Rampart;
   instance_count : 294912;
}
blackbox stateful_alu Higganum {
   reg : Hammocks;
   update_lo_1_value: read_bitc;
   output_value : alu_lo;
   output_dst : Basalt.Roxboro;
}
blackbox stateful_alu Holcomb {
   reg : Gully;
   update_lo_1_value: read_bit;
   output_value : alu_lo;
   output_dst : Basalt.Harris;
}
field_list PoleOjea {
   ig_intr_md.ingress_port;
   Nathan[0].Woodridge;
}
field_list_calculation Lawnside {
   input { PoleOjea; }
   algorithm: identity;
   output_width: 19;
}
action Boerne() {
   Higganum.execute_stateful_alu_from_hash(Lawnside);
}
action Salineno() {
   Holcomb.execute_stateful_alu_from_hash(Lawnside);
}
table Portal {
   actions {
      Boerne;
   }
   default_action : Boerne;
   size : 1;
}
table Rampart {
   actions {
      Salineno;
   }
   default_action : Salineno;
   size : 1;
}
control LeaHill {
   if ( valid( Nathan[0] ) and Nathan[0].Woodridge != 0
        and Townville.Coventry == 1 ) {
      apply( Portal );
   }
   apply( Rampart );
}
register Aguada {
   width : 1;
   static : Valdosta;
   instance_count : 294912;
}
register Addison {
   width : 1;
   static : Sawpit;
   instance_count : 294912;
}
blackbox stateful_alu Preston {
   reg : Aguada;
   update_lo_1_value: read_bitc;
   output_value : alu_lo;
   output_dst : Kenefic.Magasco;
}
blackbox stateful_alu Parrish {
   reg : Addison;
   update_lo_1_value: read_bit;
   output_value : alu_lo;
   output_dst : Kenefic.SneeOosh;
}
field_list Nuangola {
   eg_intr_md.egress_port;
   Stillmore.Birds;
}
field_list_calculation Claiborne {
   input { Nuangola; }
   algorithm: identity;
   output_width: 19;
}
action Solomon() {
   Preston.execute_stateful_alu_from_hash(Claiborne);
}
table Valdosta {
   actions {
      Solomon;
   }
   default_action : Solomon;
   size : 1;
}
action Wharton() {
    Parrish.execute_stateful_alu_from_hash(Claiborne);
}
table Sawpit {
   actions {
      Wharton;
   }
   default_action : Wharton;
   size : 1;
}
control Royston {
   apply( Valdosta );
   apply( Sawpit );
}
@pragma all_fields_optional
field_list Swaledale {
   Linganore.Emden;
   Linganore.Comobabi;
   Linganore.Faulkner;
   Linganore.ShowLow;
   Allison.Domestic;
}
@pragma all_fields_optional
field_list Beasley {
   Duffield.Emden;
   Duffield.Comobabi;
   Duffield.Faulkner;
   Duffield.ShowLow;
   Duffield.Excello;
}
@pragma all_fields_optional
field_list Hamburg {
   Idria.RushCity;
   Idria.Reidland;
   Idria.Ballville;
}
@pragma all_fields_optional
field_list Manasquan {
   LaPryor.Chualar;
   LaPryor.Rollins;
   LaPryor.Absecon;
   LaPryor.Millport;
}
@pragma all_fields_optional
field_list Bridger {
   Martelle.Wauna;
   MillCity.Roodhouse;
   MillCity.Dunnellon;
}
@pragma all_fields_optional
field_list Kellner {
   Martelle.Vigus;
   Lafayette.Roodhouse;
   Lafayette.Dunnellon;
}
field_list_calculation MontIda {
    input {
        Swaledale;
    }
    algorithm : crc16;
   output_width : 16;
}
field_list_calculation Kasigluk {
   input {
      Beasley;
   }
   algorithm : crc16;
   output_width : 16;
}
field_list_calculation Thawville {
   input {
      Hamburg;
   }
   algorithm : crc16;
   output_width : 16;
}
field_list_calculation Boyce {
   input {
      Manasquan;
   }
   algorithm : crc16;
   output_width : 16;
}
field_list_calculation Randle {
   input {
      Bridger;
   }
   algorithm : crc16;
   output_width : 16;
}
field_list_calculation Chalco {
   input {
      Kellner;
   }
   algorithm : crc16;
   output_width : 16;
}
action Ripley() {
   modify_field_with_hash_based_offset( Martelle.Tanana, 0,
                                        MontIda, 65536 );
}
action Longford() {
   modify_field_with_hash_based_offset( Martelle.Taconite, 0,
                                        Kasigluk, 65536 );
}
action Coalwood() {
   modify_field_with_hash_based_offset( Martelle.Wauna, 0,
                                        Thawville, 65536 );
}
action Perrytown() {
   modify_field_with_hash_based_offset( Martelle.Wauna, 0,
                                        Boyce, 65536 );
}
action Achilles() {
   modify_field_with_hash_based_offset( Martelle.Danese, 0,
                                        Randle, 65536 );
}
@pragma all_fields_optional
field_list Pricedale {
   MudLake.LaMoille;
   MudLake.SanSimon;
   Chardon.Ardsley;
}
field_list_calculation Ipava {
   input {
      Pricedale;
   }
    algorithm : crc16;
   output_width : 16;
}
action Bladen() {
   modify_field_with_hash_based_offset( Martelle.Vigus, 0,
                                        Ipava, 65536 );
}
@pragma all_fields_optional
field_list Wimbledon {
   Gunder.Hamden;
   Gunder.Varnado;
   LaVale.Absecon;
   Chardon.Ardsley;
}
field_list_calculation Mahomet {
   input {
      Wimbledon;
   }
   algorithm : crc16;
   output_width : 16;
}
action Bairoil() {
   modify_field_with_hash_based_offset( Martelle.Vigus, 0,
                                        Mahomet, 65536 );
}
@pragma ternary 1
@pragma stage 0
table Taiban {
   reads {
      Pueblo.valid : exact;
      LaVale.valid : exact;
   }
   actions {
      Bladen;
      Bairoil;
   }
   size : 0;
}
table Rhodell {
   actions {
      Longford;
   }
   default_action : Longford();
   size: 1;
}
control Mapleview {
   apply( Rhodell );
}
table Wapato {
   actions {
      Coalwood;
   }
   default_action : Coalwood();
   size: 1;
}
table Hartwell {
   actions {
      Perrytown;
   }
   default_action : Perrytown();
   size: 1;
}
control Anvik {
   if ( valid( Idria ) ) {
      apply(Wapato);
   } else {
      apply( Hartwell );
   }
}
action Barstow() {
   modify_field_with_hash_based_offset( Martelle.Provo, 0,
                                        Chalco, 65536 );
}
action Garcia() {
   Achilles();
   Barstow();
}
table Bledsoe {
   actions {
      Garcia;
   }
   default_action : Garcia();
   size: 1;
}
control Berenice {
   apply( Bledsoe );
}
action Rotan() {
   modify_field_with_hash_based_offset( Lenoir.Brinson, 0,
                                        MontIda, 65536 );
}
action Donnelly() {
   modify_field(Lenoir.Brinson, Martelle.Wauna);
}
action Utuado() {
   modify_field(Lenoir.Brinson, Martelle.Danese);
}
action Sonoma() {
   modify_field( Lenoir.Brinson, Martelle.Taconite );
}
action Orrick() {
   modify_field( Lenoir.Brinson, Martelle.Vigus );
}
action Dunstable() {
   modify_field( Lenoir.Brinson, Martelle.Provo );
}
@pragma action_default_only Sonora
@pragma immediate 0
table Calumet {
   reads {
      Lafayette.valid : ternary;
      Pueblo.valid : ternary;
      LaVale.valid : ternary;
      Duffield.valid : ternary;
      MillCity.valid : ternary;
      Idria.valid : ternary;
      LaPryor.valid : ternary;
      Linganore.valid : ternary;
   }
   actions {
      Rotan;
      Donnelly;
      Utuado;
      Sonoma;
      Orrick;
      Dunstable;
      Sonora;
   }
   size: 256;
}
action Lowden() {
   modify_field(Lenoir.Vananda, Martelle.Wauna);
}
action Windham() {
   modify_field( Lenoir.Vananda, Martelle.Vigus );
}
action Rhinebeck() {
   modify_field(Lenoir.Vananda, Martelle.Danese);
}
action Battles() {
   modify_field( Lenoir.Vananda, Martelle.Provo );
}
action Cairo() {
   modify_field( Lenoir.Vananda, Martelle.Taconite );
}
@pragma immediate 0
table BoxElder {
   reads {
      Lafayette.valid : ternary;
      Pueblo.valid : ternary;
      LaVale.valid : ternary;
      Duffield.valid : ternary;
      MillCity.valid : ternary;
      LaPryor.valid : ternary;
      Idria.valid : ternary;
   }
   actions {
      Lowden;
      Rhinebeck;
      Windham;
      Battles;
      Cairo;
      Sonora;
   }
   size: 512;
}
counter Enfield {
   type : packets;
   direct : Moseley;
   min_width: 64;
}
table Moseley {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      Allison.Clarinda : ternary;
      Allison.Arpin : ternary;
      Allison.Hooker : ternary;
      Chardon.Snohomish mask 0x8 : ternary;
      ig_intr_md_from_parser_aux.ingress_parser_err mask 0x1000 : ternary;
   }
   actions {
      Brazos;
      Sonora;
   }
   default_action : Sonora();
   size : 512;
}
action Millstone() {
   modify_field( Allison.Emmet, 1 );
}
table Snook {
   reads {
      Allison.Havana : exact;
      Allison.Jamesport : exact;
      Allison.Osseo : exact;
   }
   actions {
      Millstone;
      Sonora;
   }
   default_action : Sonora();
   size : 128;
}
action Speedway() {
   modify_field(Nanakuli.Bonner,
                2);
}
table Trevorton {
   reads {
      Allison.Havana : exact;
      Allison.Jamesport : exact;
      Allison.Osseo : exact;
      Allison.BlackOak : exact;
   }
   actions {
      Edwards;
      Speedway;
   }
   default_action : Speedway();
   size : 256;
   support_timeout : true;
}
action Lefors( Okarche, Carrizozo, BigLake ) {
   modify_field( Allison.Freeny, Okarche );
   modify_field( Allison.Amazonia, Carrizozo );
   modify_field( Allison.Lesley, BigLake );
}
@pragma use_hash_action 1
table Biscay {
   reads {
      Allison.Osseo mask 0xfff : exact;
   }
   actions {
      Lefors;
   }
   default_action : Lefors( 0, 0, 0 );
   size : 4096;
}
action Chandalar() {
   modify_field_with_shift( MudLake.Leola, MudLake.SanSimon, 2, 0x3FFFFFFF );
}
action Rehoboth() {
   modify_field( Shorter.Frederika, 0 );
}
action Kealia() {
   modify_field( Shorter.Frederika, 1 );
   Chandalar();
}
table Kendrick {
   reads {
      Allison.Kalskag : exact;
      Allison.Dizney : exact;
      Allison.Ralls : exact;
   }
   actions {
      Kealia;
   }
   size: 2048;
}
table Whitefish {
   reads {
      Allison.Kalskag : ternary;
      Allison.Dizney : ternary;
      Allison.Ralls : ternary;
      Allison.Virginia : ternary;
      Townville.Geeville : ternary;
   }
   actions {
      Rehoboth;
      Kealia;
   }
   default_action : Sonora();
   size: 512;
}
control Knollwood {
if( Townville.Geeville != 0 ) {
   apply( Moseley ) {
      Sonora {
         apply( Snook ) {
            Sonora {
               if (Nanakuli.Bonner == 0 and
                   Allison.Osseo != 0 and
                   (Stillmore.Campo == 1 or
                    Townville.Coventry == 1) and
                   Allison.Arpin == 0 and
                   Allison.Hooker == 0) {
                  apply( Trevorton );
               }
               apply(Whitefish) {
                  Sonora {
                     apply(Kendrick);
                  }
               }
            }
         }
       }
     }
   }
   else if( NewTrier.Mulliken == 1 ) {
               apply(Whitefish) {
                  Sonora {
                     apply(Kendrick);
                  }
               }
   }
}
control Overlea {
   apply( Biscay );
}
field_list Kupreanof {
   Allison.Havana;
   Allison.Jamesport;
   Allison.Osseo;
   Allison.BlackOak;
}
action Cruso() {
}
action PawPaw() {
   generate_digest(0, Kupreanof);
   Cruso();
}
field_list Cuprum {
   Allison.Osseo;
   Duffield.Faulkner;
   Duffield.ShowLow;
   Idria.Reidland;
   LaPryor.Chualar;
   Linganore.Excello;
   Absarokee.Monowi;
   Absarokee.Suntrana;
}
action McLean() {
   generate_digest(0, Cuprum);
   Cruso();
}
action BullRun() {
   modify_field( Allison.Quinnesec, 1 );
   Cruso();
}
action Evelyn() {
   modify_field( Stillmore.Verbena, 1 );
   modify_field( Stillmore.Mahopac, 22 );
   Cruso();
   modify_field( Basalt.Harris, 0 );
   modify_field( Basalt.Roxboro, 0 );
}
table Conejo {
   reads {
      Nanakuli.Bonner : exact;
      Allison.Clarinda : ternary;
      ig_intr_md.ingress_port : ternary;
      Allison.BlackOak mask 0x80000 : ternary;
      Basalt.Harris : ternary;
      Basalt.Roxboro : ternary;
      Allison.Minatare : ternary;
   }
   actions {
      PawPaw;
      McLean;
      Evelyn;
      BullRun;
   }
   default_action : Cruso();
   size : 512;
}
control Levittown {
   if (Nanakuli.Bonner != 0) {
      apply( Conejo );
   }
}
field_list Buckfield {
   ig_intr_md.ingress_port;
   Lenoir.Brinson;
}
field_list_calculation Brentford {
   input {
      Buckfield;
   }
   algorithm : crc16_extend;
   output_width : 51;
}
action_selector Farthing {
   selection_key : Brentford;
   selection_mode : resilient;
}
@pragma pa_container egress Stillmore.Agawam 31
@pragma pa_overlay_stage_separation ingress Stillmore.Agawam 1
action Amasa(Dateland) {
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Dateland );
   modify_field( Stillmore.Agawam, 0 );
   bit_or( Stillmore.Bozar, Stillmore.Bozar, Stillmore.Oronogo );
}
action Riner() {
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Stillmore.Munich, 0x001FF );
   modify_field_with_shift( Stillmore.Agawam, Stillmore.Munich, 9, 0xfffff );
   bit_or( Stillmore.Bozar, Stillmore.Bozar, Stillmore.Oronogo );
}
action Twichell() {
   bit_not( ig_intr_md_for_tm.ucast_egress_port, 0 );
}
action Beatrice() {
   bit_or( Stillmore.Bozar, Stillmore.Bozar, Stillmore.Oronogo );
   Twichell();
}
action_profile Palco {
   actions {
      Amasa;
      Riner;
      Beatrice;
      Twichell;
   }
   size : 32768;
   dynamic_action_selection : Farthing;
}
table Baldwin {
   reads {
      Stillmore.Munich : ternary;
   }
   action_profile: Palco;
   size : 512;
}
control Ivanhoe {
   apply(Baldwin);
}
@pragma pa_no_init ingress Stillmore.Munich
@pragma pa_no_init ingress Stillmore.Parkland
@pragma pa_no_init ingress ig_intr_md_for_tm.ucast_egress_port
action Gasport(Montour) {
   modify_field(Stillmore.Boutte, Townville.Geeville );
   modify_field(Stillmore.Summit, Allison.Dizney);
   modify_field(Stillmore.Lookeba, Allison.Ralls);
   modify_field(Stillmore.Lueders, Allison.Osseo);
   modify_field(Stillmore.Munich, Montour);
   modify_field(Stillmore.Parkland, 0);
   bit_or( Allison.Tekonsha, Allison.Tekonsha, Allison.Oldsmar );
   modify_field( ig_intr_md_for_tm.mcast_grp_a, 0 );
}
@pragma use_hash_action 1
table Folkston {
   reads {
      Linganore.valid : exact;
   }
   actions {
      Gasport;
   }
   default_action : Gasport(511);
   size : 2;
}
control ViewPark {
   apply( Folkston );
}
meter Anthon {
   type : bytes;
   direct : Mickleton;
   result : Allison.Dubach;
}
action Onawa() {
   modify_field( Stillmore.Pierpont, Allison.Lesley );
   modify_field(ig_intr_md_for_tm.copy_to_cpu, Allison.Amazonia);
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Stillmore.Lueders);
}
action Musella() {
   add(ig_intr_md_for_tm.mcast_grp_a, Stillmore.Lueders, 4096);
   modify_field( Allison.Sunrise, 1 );
   modify_field( Stillmore.Pierpont, Allison.Lesley );
}
action Mystic() {
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Stillmore.Lueders);
   modify_field( Stillmore.Pierpont, Allison.Lesley );
}
table Mickleton {
   reads {
      ig_intr_md.ingress_port mask 0x7f : ternary;
      Stillmore.Summit : ternary;
      Stillmore.Lookeba : ternary;
   }
   actions {
      Onawa;
      Musella;
      Mystic;
   }
   size : 512;
}
action Hammond(Folger) {
   modify_field(Stillmore.Munich, Folger);
}
action Sardinia(Maloy, Alcoma) {
   modify_field(Stillmore.Parkland, Alcoma);
   Hammond(Maloy);
   modify_field(Stillmore.Westel, 5);
}
action Basehor(Waterman) {
   modify_field(ig_intr_md_for_tm.mcast_grp_a, Waterman);
}
action Mendocino() {
   modify_field( Allison.Dubuque, 1 );
}
table Circle {
   reads {
      Stillmore.Summit : exact;
      Stillmore.Lookeba : exact;
      Stillmore.Lueders : exact;
   }
   actions {
      Hammond;
      Basehor;
      Sardinia;
      Mendocino;
      Sonora;
   }
   default_action : Sonora();
   size : 256;
}
control Fennimore {
   apply(Circle) {
      Sonora {
         apply(Mickleton);
      }
   }
}
field_list Traverse {
   Lenoir.Brinson;
}
field_list_calculation Iraan {
   input {
      Traverse;
   }
   algorithm : identity;
   output_width : 51;
}
action Berkley( Seaforth, Sagamore ) {
   modify_field( Stillmore.Bozar, Stillmore.Munich );
   modify_field( Stillmore.Oronogo, Sagamore );
   modify_field( Stillmore.Munich, Seaforth );
   modify_field( Stillmore.Westel, 5 );
   modify_field( ig_intr_md_for_tm.disable_ucast_cutthru, 1 );
}
action_selector Adams {
   selection_key : Iraan;
   selection_mode : resilient;
}
action_profile Potter {
   actions {
      Berkley;
   }
   size : 8;
   dynamic_action_selection : Adams;
}
@pragma ways 2
table Ramos {
   reads {
      Stillmore.Parkland : exact;
   }
   action_profile : Potter;
   size : 2;
}
action Guayabal() {
   modify_field( Allison.Westway, 1 );
}
table Mattese {
   actions {
      Guayabal;
   }
   default_action : Guayabal;
   size : 1;
}
action Berkey() {
   modify_field( Allison.LaPalma, 1 );
}
@pragma ways 1
table Spanaway {
   reads {
      Stillmore.Munich mask 0x007FF : exact;
   }
   actions {
      Edwards;
      Berkey;
   }
   default_action : Edwards;
   size : 512;
}
control Frewsburg {
   if ((Allison.Adona == 0) and (Stillmore.Junior==0) and (Allison.Sunrise==0)
       and (Allison.Kaplan==0) and (Basalt.Roxboro == 0) and (Basalt.Harris == 0)) {
      if (((Allison.BlackOak==Stillmore.Munich) or ((Stillmore.Campo == 1) and (Stillmore.Westel == 5))) ) {
         apply(Mattese);
      } else if (Townville.Geeville==2 and
                 ((Stillmore.Munich & 0xFF800) ==
                   0x03800)) {
         apply(Spanaway);
      }
   }
}
action Shellman( Reydon ) {
   modify_field( Stillmore.Birds, Reydon );
}
action Tryon( ElLago ) {
   modify_field( Stillmore.Birds, ElLago );
   modify_field( Stillmore.Abbyville, 1 );
}
action Westwego() {
   modify_field( Stillmore.Birds, Stillmore.Lueders );
}
table OakLevel {
   reads {
      eg_intr_md.egress_port mask 0x7f : exact;
      Stillmore.Lueders : exact;
      Stillmore.Agawam mask 0x0003F : exact;
   }
   actions {
      Shellman;
      Tryon;
      Westwego;
   }
   default_action : Westwego;
   size : 16;
}
control Bedrock {
   apply( OakLevel );
}
action Westline( CassCity, Norma, Rochert ) {
   modify_field( Stillmore.Cardenas, CassCity );
   add_to_field( eg_intr_md.pkt_length, Norma );
   bit_and( Lenoir.Brinson, Lenoir.Brinson, Rochert );
}
action Maljamar( Hospers, Gabbs, Moody, Grottoes ) {
   modify_field( Stillmore.Golden, Hospers );
   Westline( Gabbs, Moody, Grottoes );
}
action Piketon( Wegdahl, Shawmut, Reager, Tappan ) {
   modify_field( Stillmore.Shelbina, Stillmore.AvonLake );
   modify_field( Stillmore.Golden, Wegdahl );
   Westline( Shawmut, Reager, Tappan );
}
action Allons( Requa, Firesteel ) {
   modify_field( Stillmore.Cardenas, Requa );
   add_to_field( eg_intr_md.pkt_length, Firesteel );
}
@pragma no_egress_length_correct 1
@pragma ternary 1
table Koloa {
   reads {
      Stillmore.Campo : ternary;
      Stillmore.Westel : exact;
      Stillmore.Contact : ternary;
      Stillmore.Bozar mask 0x50000 : ternary;
   }
   actions {
      Westline;
      Maljamar;
      Piketon;
      Allons;
   }
   size : 16;
}
action Bradner( Greenland ) {
   modify_field( Stillmore.Eaton, 1 );
   modify_field( Stillmore.Westel, 2 );
   modify_field( Stillmore.Mattawan, Greenland );
   modify_field( Stillmore.Dasher, 0);
   modify_field( NewTrier.Richlawn, 0 );
}
@pragma ternary 1
table Yakima {
   reads {
      eg_intr_md.egress_port : exact;
      Townville.Coventry : exact;
      Stillmore.Contact : exact;
      Stillmore.Campo : exact;
   }
   actions {
      Bradner;
   }
   default_action : Sonora();
   size : 32;
}
action Fenwick(Chavies, Norias, Goodwater, Wamesit) {
   modify_field( NewTrier.Viroqua, Chavies );
   modify_field( NewTrier.Hatchel, Norias );
   modify_field( NewTrier.Orting, Goodwater );
   modify_field( NewTrier.Holyoke, Wamesit );
}
@pragma ternary 1
table Luverne {
   reads {
      Stillmore.McIntosh : exact;
   }
   actions {
      Fenwick;
   }
   size : 512;
}
action Graford( Oakley, Funston ) {
   modify_field( Stillmore.Shelbina, Oakley );
   modify_field( Stillmore.AvonLake, Funston );
}
table Carpenter {
   reads {
      Stillmore.Bozar mask 0x1 : exact;
   }
   actions {
      Graford;
   }
   default_action : Graford(0, 0);
   size : 1;
}
action Manakin( Armijo, Coronado, Raynham ) {
   modify_field( Stillmore.Dunkerton, Armijo );
   modify_field( Stillmore.Vinemont, Coronado );
   modify_field( Stillmore.Lueders, Raynham );
}
table Falmouth {
   reads {
      Stillmore.Bozar mask 0xFF000000: exact;
   }
   actions {
      Manakin;
   }
   default_action : Manakin(0,0,0);
   size : 256;
}
action FlyingH( Crane, Piermont ) {
   modify_field( Stillmore.Gervais, Crane );
   modify_field( Stillmore.Nuiqsut, Piermont );
}
action Stateline() {
   modify_field( Stillmore.Norwood, 0x1 );
}
table Coconut {
   reads {
      Stillmore.Lueders mask 0xFFF : exact;
   }
   actions {
      FlyingH;
      Stateline;
   }
   default_action : Stateline;
   size : 4096;
}
action Harrison( Johnsburg, JaneLew, Eustis, Hooven, Upland ) {
   Graford( Johnsburg, Johnsburg );
   Manakin( JaneLew, Eustis, Hooven );
   modify_field( Stillmore.Westel, Upland );
}
table Melrude {
   reads {
      eg_intr_md.egress_rid: exact;
   }
   actions {
      Harrison;
   }
   default_action: Sonora();
   size : 4096;
}
control Conner {
   apply( Carpenter );
   if( Stillmore.Bozar != 0 ) {
      apply( Coconut );
   }
}
action Kenvil( Osakis, Lakota ) {
   modify_field( Parshall.Pinetop, Osakis );
   modify_field( Parshall.Patchogue, Lakota, 0xFFFF0000 );
   modify_field_with_shift( Parshall.Wenden, Stillmore.Shelbina, 16, 0xF );
   modify_field( Parshall.Lundell, Stillmore.AvonLake );
}
table Dominguez {
   reads {
      Stillmore.Shelbina mask 0xFF000000 : exact;
   }
   actions {
      Kenvil;
   }
   default_action: Sonora();
   size : 256;
}
control SourLake {
   if( Stillmore.Bozar != 0 ) {
      apply( Falmouth );
   }
}
control GlenAvon {
   if( Stillmore.Bozar != 0 ) {
      if( ( Stillmore.Bozar & 0xC0000 ) ==
          0x80000 ) {
         apply( Dominguez );
      }
   }
}
action Ricketts() {
   modify_field( Linganore.Excello, Nathan[0].Wagener );
   remove_header( Nathan[0] );
}
table Sharptown {
   actions {
      Ricketts;
   }
   default_action : Ricketts;
   size : 1;
}
action McAdoo() {
   no_op();
}
action VanWert() {
   add_header( Nathan[0] );
   modify_field( Nathan[0].Woodridge, Stillmore.Birds );
   modify_field( Nathan[0].Wagener, Linganore.Excello );
   modify_field( Nathan[0].Govan, PineHill.Jenifer );
   modify_field( Nathan[0].LaPointe, PineHill.Coachella );
   modify_field( Linganore.Excello, 0x8100 );
}
@pragma ways 2
table Tilghman {
   reads {
      Stillmore.Birds : exact;
      eg_intr_md.egress_port mask 0x7f : exact;
      Stillmore.Abbyville : exact;
   }
   actions {
      McAdoo;
      VanWert;
   }
   default_action : VanWert;
   size : 128;
}
action Chazy(Pettry, Newkirk) {
   modify_field(Linganore.Emden, Stillmore.Summit);
   modify_field(Linganore.Comobabi, Stillmore.Lookeba);
   modify_field(Linganore.Faulkner, Pettry);
   modify_field(Linganore.ShowLow, Newkirk);
}
action Quijotoa(Dunken, Colonie) {
   Chazy(Dunken, Colonie);
   add_to_field(Idria.Buncombe, -1);
}
action Bevington(Tontogany, Sahuarita) {
   Chazy(Tontogany, Sahuarita);
   add_to_field(LaPryor.Udall, -1);
}
action Clarion() {
}
action Santos() {
}
action Lanyon() {
   VanWert();
}
@pragma pa_no_init egress NewTrier.Viroqua
@pragma pa_no_init egress NewTrier.Hatchel
@pragma pa_no_init egress NewTrier.Orting
@pragma pa_no_init egress NewTrier.Holyoke
@pragma pa_no_init egress NewTrier.Gordon
@pragma pa_no_init egress NewTrier.Bergoo
@pragma pa_no_init egress NewTrier.Opelika
@pragma pa_no_init egress NewTrier.Swenson
@pragma pa_no_init egress NewTrier.Reidville
@pragma pa_no_init egress NewTrier.Oklahoma
@pragma pa_no_init egress NewTrier.Lansing
@pragma pa_no_init egress NewTrier.Richlawn
action FlatRock( Gracewood ) {
   add_header( NewTrier );
   modify_field( NewTrier.Gordon, Stillmore.Ladelle );
   modify_field( NewTrier.Bergoo, Gracewood );
   modify_field( NewTrier.Opelika, Allison.Osseo );
   modify_field( NewTrier.Swenson, Stillmore.Mattawan );
   modify_field( NewTrier.Reidville, Stillmore.Dasher );
   modify_field( NewTrier.Lansing, Allison.Kalskag );
}
action Piperton() {
   FlatRock( Stillmore.Mahopac );
}
action Metter() {
   modify_field( Linganore.Emden, Linganore.Emden );
   no_op();
}
action Granbury( Goodlett, Ludden ) {
   add_header( Linganore );
   modify_field( Linganore.Emden, Stillmore.Summit );
   modify_field( Linganore.Comobabi, Stillmore.Lookeba );
   modify_field( Linganore.Faulkner, Goodlett );
   modify_field( Linganore.ShowLow, Ludden );
   modify_field( Linganore.Excello, 0x0800 );
}
action RioPecos() {
   remove_header( Aguila[0] );
   remove_header( Villanova );
   remove_header( Elbing );
   remove_header( MillCity );
   remove_header( Idria );
}
action Philbrook( Burdette ) {
   RioPecos();
   modify_field( Linganore.Excello, 0x0800 );
   FlatRock( Burdette );
}
action Cantwell( Berville ) {
   RioPecos();
   modify_field( Linganore.Excello, 0x86dd );
   FlatRock( Berville );
}
action Wenatchee() {
   modify_field( Linganore.Excello, 0x0800 );
   FlatRock( Stillmore.Mahopac );
}
action Mattoon() {
   modify_field( Linganore.Excello, 0x86dd );
   FlatRock( Stillmore.Mahopac );
}
action Sully( BlueAsh, Lewiston, Tatum, Ojibwa ) {
   add( Villanova.Othello, BlueAsh, Lewiston );
   modify_field( Elbing.Keltys, 0 );
   modify_field( MillCity.Dunnellon, Stillmore.Cardenas );
   bit_or( MillCity.Roodhouse, Lenoir.Brinson, 0xC000 );
   modify_field( Linganore.Emden, Stillmore.Dunkerton );
   modify_field( Linganore.Comobabi, Stillmore.Vinemont );
   modify_field( Linganore.Faulkner, Tatum );
   modify_field( Linganore.ShowLow, Ojibwa );
}
action Pineridge( Lindsborg, Kinsley, Lumberton, Ozona, Armstrong ) {
   add_header( Villanova );
   add_header( Elbing );
   add_header( MillCity );
   add_header( Aguila[0] );
   Sully( Lindsborg, Kinsley, Ozona, Armstrong );
   Kaolin( Lindsborg, Lumberton );
}
action McDaniels( Bogota, Skagway ) {
   add_header( Pueblo );
   Oxford( -1 );
   Pineridge( Idria.Diomede, 12, 32,
                         Bogota, Skagway );
}
action Almedia( SanPablo, Mankato ) {
   add_header( LaVale );
   Auberry( -1 );
   add_header( Idria );
   Pineridge( eg_intr_md.pkt_length, -6, 14,
                            SanPablo, Mankato );
   remove_header( LaPryor );
}
action Sudden() {
   remove_header( Absarokee );
   remove_header( Villanova );
   remove_header( Elbing );
   remove_header( MillCity );
   copy_header( Linganore, Duffield );
   remove_header( Duffield );
   remove_header( Idria );
   remove_header( LaPryor );
}
action Calamus( Lapel ) {
   Sudden();
   FlatRock( Lapel );
}
action Gastonia( Humble, Oriskany ) {
   remove_header( Aguila[0] );
   remove_header( Villanova );
   remove_header( Elbing );
   remove_header( MillCity );
   remove_header( Idria );
   modify_field( Linganore.Emden, Stillmore.Summit );
   modify_field( Linganore.Comobabi, Stillmore.Lookeba );
   modify_field( Linganore.Faulkner, Humble );
   modify_field( Linganore.ShowLow, Oriskany );
}
action Captiva( Burket, Jauca ) {
   Gastonia( Burket, Jauca );
   modify_field( Linganore.Excello, 0x0800 );
   add_to_field( Pueblo.Buncombe, -1 );
}
action Myrick( Brazil, Dustin ) {
   Gastonia( Brazil, Dustin );
   modify_field( Linganore.Excello, 0x86dd );
   add_to_field( LaVale.Udall, -1 );
}
action Lisman( Noorvik, Bouton ) {
   Chazy( Noorvik, Bouton );
   modify_field( Linganore.Excello, 0x0800 );
   add_to_field( Idria.Buncombe, -1 );
}
action Raceland( Creston, Jeddo ) {
   Chazy( Creston, Jeddo );
   modify_field( Linganore.Excello, 0x86dd );
   add_to_field( LaPryor.Udall, -1 );
}
action Burrton( Neavitt, Wakenda ) {
   remove_header( Absarokee );
   remove_header( Villanova );
   remove_header( Elbing );
   remove_header( MillCity );
   remove_header( Idria );
   remove_header( LaPryor );
   modify_field( Linganore.Emden, Stillmore.Summit );
   modify_field( Linganore.Comobabi, Stillmore.Lookeba );
   modify_field( Linganore.Faulkner, Neavitt );
   modify_field( Linganore.ShowLow, Wakenda );
   modify_field( Linganore.Excello, Duffield.Excello );
   remove_header( Duffield );
}
action Woodbury( Bosco, DeKalb ) {
   Burrton( Bosco, DeKalb );
   add_to_field( Pueblo.Buncombe, -1 );
}
action Stella( OreCity, Pineland ) {
   Burrton( OreCity, Pineland );
   add_to_field( LaVale.Udall, -1 );
}
action Chispa() {
   modify_field( Linganore.Comobabi, Linganore.Comobabi );
}
action Oxford( DeBeque ) {
   modify_field( Pueblo.Dunnegan, Idria.Dunnegan );
   modify_field( Pueblo.Kewanee, Idria.Kewanee );
   modify_field( Pueblo.McAllen, Idria.McAllen );
   modify_field( Pueblo.Fairlee, Idria.Fairlee );
   modify_field( Pueblo.Diomede, Idria.Diomede );
   modify_field( Pueblo.Wakeman, Idria.Wakeman );
   modify_field( Pueblo.Slana, Idria.Slana );
   modify_field( Pueblo.Robinson, Idria.Robinson );
   modify_field( Pueblo.Raytown, Idria.Raytown );
   modify_field( Pueblo.Mogote, Idria.Mogote );
   add( Pueblo.Buncombe, Idria.Buncombe, DeBeque );
   modify_field( Pueblo.RushCity, Idria.RushCity );
   modify_field( Pueblo.Reidland, Idria.Reidland );
   modify_field( Pueblo.Ballville, Idria.Ballville );
}
action Conneaut( Callands, Mabelvale, Brush, Henrietta, Funkley,
                         Slater, Lewis ) {
   modify_field( Duffield.Emden, Stillmore.Summit );
   modify_field( Duffield.Comobabi, Stillmore.Lookeba );
   modify_field( Duffield.Faulkner, Brush );
   modify_field( Duffield.ShowLow, Henrietta );
   add( Villanova.Othello, Callands, Mabelvale );
   modify_field( Elbing.Keltys, 0 );
   modify_field( MillCity.Dunnellon, Stillmore.Cardenas );
   add( MillCity.Roodhouse, Lenoir.Brinson, Lewis );
   modify_field( Absarokee.Frankston, 0x8 );
   modify_field( Absarokee.Madawaska, 0 );
   modify_field( Absarokee.Monowi, Stillmore.Gervais );
   modify_field( Absarokee.Suntrana, Stillmore.Nuiqsut );
   modify_field( Linganore.Emden, Stillmore.Dunkerton );
   modify_field( Linganore.Comobabi, Stillmore.Vinemont );
   modify_field( Linganore.Faulkner, Funkley );
   modify_field( Linganore.ShowLow, Slater );
}
action Breese( Algoa, Holliday, Kekoskee, Buckeye,
                                Larue, Arvada, Sonoita ) {
   add_header( Duffield );
   add_header( Villanova );
   add_header( Elbing );
   add_header( MillCity );
   add_header( Absarokee );
   modify_field( Duffield.Excello, Linganore.Excello );
   Conneaut( Algoa, Holliday, Kekoskee, Buckeye, Larue,
                     Arvada, Sonoita );
}
action Cascadia( Skyforest, Sutherlin, Kaufman, Henning,
                                    Millett, SandLake, Barber,
                                    Kenney ) {
   Breese( Skyforest, Sutherlin, Henning, Millett,
                            SandLake, Barber, Kenney );
   Kaolin( Skyforest, Kaufman );
}
action Philippi( Holden, PineLawn, Ugashik, Olyphant,
                                    Lurton, Ocilla, Aripine,
                                    Fittstown, Wapella, Aquilla, Gustine, Kensett ) {
   remove_header( Idria );
   Breese( Holden, PineLawn, Olyphant, Lurton,
                            Ocilla, Aripine, Kensett );
   Keachi( Holden, Ugashik, Fittstown, Wapella, Aquilla, Gustine );
}
action Kaolin( Melder, Milesburg ) {
   modify_field( Idria.Dunnegan, 0x4 );
   modify_field( Idria.Kewanee, 0x5 );
   modify_field( Idria.McAllen, 0 );
   modify_field( Idria.Fairlee, 0 );
   add( Idria.Diomede, Melder, Milesburg );
   modify_field_rng_uniform(Idria.Wakeman, 0, 0xFFFF);
   modify_field( Idria.Slana, 0 );
   modify_field( Idria.Robinson, 1 );
   modify_field( Idria.Raytown, 0 );
   modify_field( Idria.Mogote, 0 );
   modify_field( Idria.Buncombe, 64 );
   modify_field( Idria.RushCity, 17 );
   modify_field( Idria.Reidland, Stillmore.Golden );
   modify_field( Idria.Ballville, Stillmore.Shelbina );
   modify_field( Linganore.Excello, 0x0800 );
}
action Keachi( Cuthbert, Rainsburg, Council, Waucousta, Blanchard, Between ) {
   add_header( Parshall );
   modify_field( Parshall.Alamota, 0x6 );
   modify_field( Parshall.Mulhall, 0 );
   modify_field( Parshall.Safford, 0 );
   modify_field( Parshall.Ravena, 0 );
   add( Parshall.Wakefield, Cuthbert, Rainsburg );
   modify_field( Parshall.Macland, 17 );
   modify_field( Parshall.McCaulley, Council );
   modify_field( Parshall.Talihina, Waucousta );
   modify_field( Parshall.Brave, Blanchard );
   modify_field( Parshall.Haena, Between );
   modify_field( Parshall.Patchogue, Stillmore.Shelbina, 0xFFFF );
   modify_field( Parshall.Wenden, 0, 0xFFFFFFF0 );
   modify_field( Parshall.Bonsall, 64 );
   modify_field( Linganore.Excello, 0x86dd );
}
action Unionvale( Kisatchie, Keyes, Gwynn ) {
   add_header( Pueblo );
   Oxford( -1 );
   Cascadia( Idria.Diomede, 30, 50, Kisatchie,
                                Keyes, Kisatchie, Keyes,
                                Gwynn );
}
action Albemarle( Vanzant, Annawan, Skyway ) {
   add_header( Pueblo );
   Oxford( 0 );
   Sheldahl( Vanzant, Annawan, Skyway );
}
action Auberry( Wausaukee ) {
   modify_field( LaVale.Benonine, LaPryor.Benonine );
   modify_field( LaVale.Osterdock, LaPryor.Osterdock );
   modify_field( LaVale.Berea, LaPryor.Berea );
   modify_field( LaVale.Absecon, LaPryor.Absecon );
   modify_field( LaVale.Bammel, LaPryor.Bammel );
   modify_field( LaVale.Millport, LaPryor.Millport );
   modify_field( LaVale.Chualar, LaPryor.Chualar );
   modify_field( LaVale.Rollins, LaPryor.Rollins );
   add( LaVale.Udall, LaPryor.Udall, Wausaukee );
}
action Wolverine( Beechwood, Kelvin, Whitman ) {
   add_header( LaVale );
   Auberry( -1 );
   add_header( Idria );
   Cascadia( eg_intr_md.pkt_length, 12, 32, Beechwood,
                                Kelvin, Beechwood, Kelvin,
                                Whitman );
   remove_header( LaPryor );
}
action Waterford( Readsboro, Greendale, Ortley ) {
   add_header( LaVale );
   Auberry( 0 );
   remove_header( LaPryor );
   Sheldahl( Readsboro, Greendale, Ortley );
}
action Sheldahl( Waipahu, Almond, Alakanuk ) {
   add_header( Idria );
   Cascadia( eg_intr_md.pkt_length, 12, 32,
                                Linganore.Faulkner, Linganore.ShowLow,
                                Waipahu, Almond, Alakanuk );
}
action Curtin( Wheatland, Lewellen, Leadpoint ) {
   Conneaut( Villanova.Othello, 0, Wheatland, Lewellen, Wheatland, Lewellen, Leadpoint );
   Kaolin( Idria.Diomede, 0 );
}
action Talbert( Gosnell, Bowdon, Lithonia ) {
   Curtin( Gosnell, Bowdon, Lithonia );
   add_to_field( Pueblo.Buncombe, -1 );
}
action Shopville( Punaluu, Spalding, Nettleton ) {
   Curtin( Punaluu, Spalding, Nettleton );
   add_to_field( LaVale.Udall, -1 );
}
action Ashville( Anandale, Gibbstown, Cammal, Halley, Florala,
                                GlenDean, Halltown )
{
   Philippi( eg_intr_md.pkt_length, 12, 12, Linganore.Faulkner,
                                Linganore.ShowLow, Anandale,
                                Gibbstown, Cammal, Halley, Florala, GlenDean,
                                Halltown );
}
action Lamoni( Barnard, Honokahua, Oakford, Kempner,
                                        Higginson, Bacton, Hopedale ) {
   add_header( Pueblo );
   Oxford( 0 );
   Philippi( Idria.Diomede, 30, 30, Linganore.Faulkner,
                                Linganore.ShowLow, Barnard,
                                Honokahua, Oakford, Kempner, Higginson, Bacton,
                                Hopedale );
}
action Juniata( Waucoma, Ranier, Froid, Lamboglia,
                                       Silesia, Woodburn, Despard ) {
   add_header( Pueblo );
   Oxford( -1 );
   Philippi( Idria.Diomede, 30, 30, Waucoma,
                                Ranier, Waucoma, Ranier,
                                Froid, Lamboglia, Silesia, Woodburn, Despard );
}
action Filer( Gonzalez, Spearman, Frontier,
                                              Belmont, Dedham, Gretna, Gullett ) {
   Conneaut( Villanova.Othello, 0, Gonzalez, Spearman,
                     Gonzalez, Spearman, Gullett );
   Keachi( eg_intr_md.pkt_length, -58, Frontier, Belmont, Dedham, Gretna );
   remove_header( LaPryor );
   add_to_field( Pueblo.Buncombe, -1 );
}
action Jericho( Plateau, Newpoint, Whitetail, Grasmere,
                                          Berne, DoeRun, Manistee ) {
   Conneaut( Villanova.Othello, 0, Plateau, Newpoint,
                     Plateau, Newpoint, Manistee );
   Keachi( eg_intr_md.pkt_length, -38, Whitetail, Grasmere, Berne, DoeRun );
   remove_header( Idria );
   add_to_field( Pueblo.Buncombe, -1 );
}
action Bucktown( Stobo, Greenhorn,
                                          Flynn ) {
   add_header( Idria );
   Conneaut( Villanova.Othello, 0, Stobo, Greenhorn,
                     Stobo, Greenhorn, Flynn );
   Kaolin( eg_intr_md.pkt_length, -38 );
   remove_header( LaPryor );
   add_to_field( Pueblo.Buncombe, -1 );
}
table Hargis {
   reads {
      Stillmore.Campo : exact;
      Stillmore.Westel : exact;
      Stillmore.Junior : exact;
      Idria.valid : ternary;
      LaPryor.valid : ternary;
      Pueblo.valid : ternary;
      LaVale.valid : ternary;
      Stillmore.Bozar mask 0xC0000 : ternary;
   }
   actions {
      Quijotoa;
      Bevington;
      Clarion;
      Santos;
      Lanyon;
      Piperton;
      Chispa;
      Granbury;
      Metter;
      Calamus;
      Sudden;
      Woodbury;
      Stella;
      Talbert;
      Shopville;
      Albemarle;
      Waterford;
      Unionvale;
      Wolverine;
      Sheldahl;
   }
   size : 512;
}
control Skillman {
   apply( Sharptown );
}
control Aplin {
   apply( Tilghman );
}
action Placid() {
   drop();
}
table Bethesda {
   reads {
      Stillmore.Boutte : exact;
      eg_intr_md.egress_port mask 0x7F: exact;
   }
   actions {
      Placid;
   }
   size : 512;
}
control Needham {
   apply( Yakima ) {
      Sonora {
         apply( Koloa );
      }
   }
   apply( Luverne );
   if( Stillmore.Junior == 0 and Stillmore.Campo == 0 and Stillmore.Westel == 0 ) {
      apply( Bethesda );
   }
   apply( Hargis );
}
@pragma pa_no_init ingress PineHill.Resaca
@pragma pa_no_init ingress PineHill.Amboy
@pragma pa_no_init ingress PineHill.Baltimore
@pragma pa_no_init ingress PineHill.Jenifer
@pragma pa_no_init ingress PineHill.LaSalle
action Dunnville( Maceo, Gower, Winside ) {
   modify_field( PineHill.Resaca, Maceo );
   modify_field( PineHill.Amboy, Gower );
   modify_field( PineHill.Baltimore, Winside );
}
table SandCity {
   reads {
      ig_intr_md.ingress_port : exact;
   }
   actions {
      Dunnville;
   }
   default_action : Dunnville(0, 0, 0);
   size : 512;
}
action Ekwok(Chelsea) {
   modify_field( PineHill.Jenifer, Chelsea );
}
action SanJon(Laurie) {
   modify_field( PineHill.Jenifer, Laurie );
   modify_field( Allison.Domestic, Nathan[0].Wagener );
}
action BarNunn(Minetto) {
   modify_field( PineHill.Jenifer, Minetto );
   modify_field( Allison.Domestic, Nathan[1].Wagener );
}
action Anoka() {
   modify_field( PineHill.LaSalle, PineHill.Amboy );
}
action Caballo() {
   modify_field( PineHill.LaSalle, 0 );
}
action PineCity() {
   modify_field( PineHill.LaSalle, MudLake.Kress );
}
action Mocane() {
   PineCity();
}
action ElToro() {
   modify_field( PineHill.LaSalle, Gunder.Fairlea );
}
action Suring( Albany, Batchelor ) {
   modify_field( ig_intr_md_for_tm.ingress_cos, Albany );
   modify_field( ig_intr_md_for_tm.qid, Batchelor );
}
table Joseph {
   reads {
      Allison.Harshaw : exact;
      PineHill.Resaca : exact;
      Nathan[0].Govan : exact;
      Nathan[1].valid : exact;
   }
   actions {
      Ekwok;
      SanJon;
      BarNunn;
   }
   size : 256;
}
table Miranda {
   reads {
      Stillmore.Campo : exact;
      Allison.Virginia : exact;
   }
   actions {
      Anoka;
      Caballo;
      PineCity;
      Mocane;
      ElToro;
   }
   size : 1024;
}
@pragma pa_no_init ingress ig_intr_md_for_tm.ingress_cos
@pragma pa_no_init ingress ig_intr_md_for_tm.qid
table Keller {
   reads {
      PineHill.Baltimore : ternary;
      PineHill.Resaca : ternary;
      PineHill.Jenifer : ternary;
      PineHill.LaSalle : ternary;
      PineHill.McCammon : ternary;
      Stillmore.Campo : ternary;
      NewTrier.Oklahoma : ternary;
      NewTrier.Padonia : ternary;
   }
   actions {
      Suring;
   }
   default_action : Suring( 0, 0 );
   size : 306;
}
action Lovelady( Energy, Wartrace ) {
   modify_field( PineHill.Fonda, Energy );
   modify_field( PineHill.Dunedin, Wartrace );
}
table BeeCave {
   actions {
      Lovelady;
   }
   default_action : Lovelady;
   size : 1;
}
action Exira( Robbs ) {
   modify_field( PineHill.LaSalle, Robbs );
}
action Auvergne( McAdams ) {
   modify_field( PineHill.Jenifer, McAdams );
}
action Florien( Rembrandt, ElRio ) {
   modify_field( PineHill.Jenifer, Rembrandt );
   modify_field( PineHill.LaSalle, ElRio );
}
@pragma ternary 1
table Crump {
   reads {
      PineHill.Baltimore : exact;
      PineHill.Fonda : exact;
      PineHill.Dunedin : exact;
      ig_intr_md_for_tm.ingress_cos : exact;
      Stillmore.Campo : exact;
   }
   actions {
      Exira;
      Auvergne;
      Florien;
   }
   size : 1024;
}
action Crowheart( Bavaria ) {
   modify_field( PineHill.Akiachak, Bavaria );
}
@pragma ternary 1
table Belcourt {
   reads {
      ig_intr_md_for_tm.ingress_cos : exact;
   }
   actions {
      Crowheart;
   }
   size : 8;
}
action Clover() {
   modify_field( Idria.McAllen, PineHill.LaSalle );
}
action Wilmore() {
   modify_field( LaPryor.Osterdock, PineHill.LaSalle );
}
action Yerington() {
   modify_field( Pueblo.McAllen, PineHill.LaSalle );
}
action Moquah() {
   modify_field( LaVale.Osterdock, PineHill.LaSalle );
}
action Bellamy() {
   modify_field( Idria.McAllen, PineHill.Akiachak );
}
action Hodges() {
   Bellamy();
   modify_field( Pueblo.McAllen, PineHill.LaSalle );
}
action Moweaqua() {
   Bellamy();
   modify_field( LaVale.Osterdock, PineHill.LaSalle );
}
action Cotter() {
   modify_field( Parshall.Mulhall, PineHill.Akiachak );
}
action Chatfield() {
   Cotter();
   modify_field( Pueblo.McAllen, PineHill.LaSalle );
}
table Sanford {
   reads {
      Stillmore.Westel : ternary;
      Stillmore.Campo : ternary;
      Stillmore.Junior : ternary;
      Idria.valid : ternary;
      LaPryor.valid : ternary;
      Pueblo.valid : ternary;
      LaVale.valid : ternary;
   }
   actions {
      Clover;
      Wilmore;
      Yerington;
      Moquah;
      Bellamy;
      Hodges;
      Moweaqua;
      Cotter;
      Chatfield;
   }
   size : 14;
}
control Wadley {
   apply( SandCity );
}
control Lecompte {
   apply( Joseph );
   apply( Miranda );
}
control Waretown {
   apply( Keller );
}
control Haverford {
   apply( BeeCave );
   apply( Crump );
}
control Roachdale {
   apply( Belcourt );
}
control Iselin {
   apply( Sanford );
}
action Balfour( Doddridge ) {
   modify_field( PineHill.Ingleside, Doddridge );
}
@pragma ignore_table_dependency Canalou
table Saugatuck {
   reads {
      Titonka.valid : ternary;
      Stillmore.Mahopac : ternary;
      Stillmore.Verbena : ternary;
      Allison.Kaplan : ternary;
      Allison.Bernstein : ternary;
      Allison.Tiverton : ternary;
      Allison.PawCreek : ternary;
   }
   actions {
      Balfour;
   }
   default_action: Balfour;
   size : 512;
}
blackbox meter Gratiot {
   type : bytes;
   static : Waldport;
   instance_count : 4096;
   yellow_value : 2;
}
counter McCartys {
   type : packets;
   static : Waldport;
   instance_count : 4096;
   min_width : 64;
}
action Fleetwood(Kanorado) {
   count( McCartys, Kanorado );
}
action Adamstown(Dundalk) {
   Gratiot.execute( ig_intr_md_for_tm.drop_ctl, Dundalk );
}
action Roxobel(Waynoka) {
   Adamstown(Waynoka);
   Fleetwood(Waynoka);
}
table Waldport {
   reads {
      ig_intr_md.ingress_port mask 0x7f : exact;
      PineHill.Ingleside : exact;
   }
   actions {
      Fleetwood;
      Roxobel;
   }
   size : 4096;
}
control Volcano {
   apply( Saugatuck );
}
@pragma pa_mutually_exclusive ingress Stillmore.McIntosh ig_intr_md.ingress_port
@pragma pa_no_init ingress Stillmore.Contact
@pragma pa_no_init ingress Stillmore.McIntosh
action Dairyland( Oregon, Kaupo ) {
   modify_field( Stillmore.McIntosh, ig_intr_md.ingress_port );
   modify_field( ig_intr_md_for_tm.ucast_egress_port, Oregon );
   modify_field( ig_intr_md_for_tm.qid, Kaupo );
}
action Gheen( Bagdad ) {
   modify_field( Stillmore.McIntosh, ig_intr_md.ingress_port );
   modify_field( ig_intr_md_for_tm.qid, Bagdad, 0x18 );
}
action Thalmann( Goessel, Wabuska ) {
   Dairyland( Goessel, Wabuska );
   modify_field( Stillmore.Contact, 0);
}
action Herring( Mabank ) {
   Gheen( Mabank );
   modify_field( Stillmore.Contact, 0);
}
action Otego( Catawissa, Emory ) {
   Dairyland( Catawissa, Emory );
   modify_field( Stillmore.Contact, 1);
}
action WestGate( Hampton ) {
   Gheen( Hampton );
   modify_field( Stillmore.Contact, 1);
}
action TenSleep( Osyka, Simnasho ) {
   Otego( Osyka, Simnasho );
   modify_field(Allison.Osseo, Nathan[0].Woodridge);
}
action Vevay( Billings ) {
   WestGate( Billings );
   modify_field(Allison.Osseo, Nathan[0].Woodridge);
}
table Plandome {
   reads {
      Stillmore.Verbena : exact;
      Allison.Harshaw : exact;
      Townville.Coventry : ternary;
      Stillmore.Mahopac : ternary;
      Nathan[0].valid : ternary;
   }
   actions {
      Thalmann;
      Herring;
      Otego;
      WestGate;
      TenSleep;
      Vevay;
   }
   default_action : WestGate(0);
   size : 512;
}
control Ossineke {
   apply( Plandome ) {
      Thalmann {
      }
      Otego {
      }
      TenSleep {
      }
      default {
         Ivanhoe();
      }
   }
}
counter Conklin {
   type : packets_and_bytes;
   static : Anawalt;
   instance_count : 4096;
   min_width : 64;
}
field_list Newport {
   eg_intr_md.egress_port;
   eg_intr_md.egress_qid;
}
field_list_calculation Standish {
   input { Newport; }
   algorithm: identity;
   output_width: 12;
}
action PortVue() {
   count_from_hash( Conklin, Standish );
}
table Anawalt {
   actions {
      PortVue;
   }
   default_action : PortVue;
   size : 1;
}
control Swisher {
   apply( Anawalt );
}
action Glendale() {
   modify_field( Allison.Skiatook, 1 );
}
action Ivanpah() {
   remove_header(NewTrier);
}
action Harleton() {
   Ivanpah();
   modify_field(Stillmore.Campo, 3);
   modify_field( Allison.Freeny, 0 );
   modify_field( Allison.Amazonia, 0 );
}
action Fergus( Anson ) {
   Ivanpah();
   modify_field(Stillmore.Campo, 2);
   modify_field(Stillmore.Munich, Anson);
   modify_field(Stillmore.Lueders, Allison.Osseo );
   modify_field(Stillmore.Parkland, 0);
}
@pragma ternary 1
table Almeria {
   reads {
      NewTrier.Viroqua : exact;
      NewTrier.Hatchel : exact;
      NewTrier.Orting : exact;
      NewTrier.Holyoke : exact;
      Stillmore.Campo : ternary;
   }
   actions {
      Fergus;
      Harleton;
      Glendale;
      Ivanpah;
   }
   default_action : Glendale();
   size : 512;
}
control Kirwin {
   apply( Almeria );
}
action WildRose( Hoagland, LakeHart, Malabar, Stockton ) {
   modify_field( Chitina.IowaCity, Hoagland );
   modify_field( Rippon.Oskaloosa, Malabar );
   modify_field( Rippon.Konnarock, LakeHart );
   modify_field( Rippon.Neponset, Stockton );
}
@pragma idletime_precision 1
table Lepanto {
   reads {
      MudLake.SanSimon : exact;
      Allison.Kalskag : exact;
   }
   actions {
      WildRose;
   }
   size : 16384;
   support_timeout : true;
}
action Rugby(Bowen, CruzBay) {
   modify_field( Rippon.Konnarock, Bowen );
   modify_field( Rippon.Oskaloosa, 1 );
   modify_field( Rippon.Neponset, CruzBay );
}
@pragma idletime_precision 1
table Thatcher {
   reads {
      MudLake.LaMoille : exact;
      Chitina.IowaCity : exact;
   }
   actions {
      Rugby;
   }
   size : 16384;
   support_timeout : true;
}
action Petrolia( Nelson, Aguilar, Quinault ) {
   modify_field( Allerton.Gerlach, Nelson );
   modify_field( Allerton.DosPalos, Aguilar );
   modify_field( Allerton.Risco, Quinault );
}
table NewMelle {
   reads {
      Stillmore.Summit : exact;
      Stillmore.Lookeba : exact;
      Stillmore.Lueders : exact;
   }
   actions {
      Petrolia;
   }
   size : 16384;
}
action Halsey() {
}
action Odell( Mekoryuk ) {
   Halsey();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Rippon.Konnarock );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Mekoryuk, Rippon.Neponset );
}
action Austell( Dozier ) {
   Halsey();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Allerton.Gerlach );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, Dozier, Allerton.Risco );
}
action Huntoon( LoneJack ) {
   Halsey();
   add( ig_intr_md_for_tm.mcast_grp_a, Stillmore.Lueders,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, LoneJack );
}
action Cabot() {
   Halsey();
   add( ig_intr_md_for_tm.mcast_grp_a, Stillmore.Lueders,
        4096 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
   modify_field( Stillmore.Mahopac, 26 );
}
action Talent( Monse ) {
   Halsey();
   modify_field( ig_intr_md_for_tm.mcast_grp_a, Stillmore.Lueders );
   bit_or( ig_intr_md_for_tm.copy_to_cpu, ig_intr_md_for_tm.copy_to_cpu, Monse );
}
action Warden( Hartfield ) {
   modify_field( ig_intr_md_for_tm.mcast_grp_a, 0 );
   modify_field( ig_intr_md_for_tm.copy_to_cpu, Hartfield );
}
action Nashwauk() {
   modify_field( Allison.Bernard, 1 );
}
@pragma ignore_table_dependency Saugatuck
table Canalou {
   reads {
      Rippon.Oskaloosa : ternary;
      Allerton.DosPalos : ternary;
      Allison.Bernstein :ternary;
      Allison.Lamar : ternary;
      Allison.Freeny: ternary;
      MudLake.SanSimon mask 0xFFFFFF00 : ternary;
      Stillmore.Verbena : ternary;
      Shorter.Nuremberg : ternary;
   }
   actions {
      Odell;
      Austell;
      Huntoon;
      Warden;
      Talent;
      Cabot;
   }
   size : 512;
}
control Whigham {
   if( Allison.Adona == 0 and Basalt.Roxboro == 0 and
       Basalt.Harris == 0 and ( ( Shorter.Nuremberg & ( 0x4 ) ) == ( ( 0x4 ) ) ) and
       Allison.Lamar == 1 and Allison.Virginia == 0x1) {
      apply( Lepanto );
   }
}
control Telocaset {
   if( Chitina.IowaCity != 0 and Allison.Virginia == 0x1) {
      apply( Thatcher );
   }
}
control RioLinda {
   if( Allison.Sunrise==1 ) {
      apply( NewMelle );
   }
}
control Plains {
   if( Stillmore.Campo != 2 ) {
      apply(Canalou);
   }
}
@pragma pa_no_init ingress ig_intr_md_for_tm.level1_mcast_hash
@pragma pa_no_init ingress ig_intr_md_for_tm.level2_mcast_hash
@pragma pa_no_init ingress ig_intr_md_for_tm.level2_exclusion_id
@pragma pa_alias ingress ig_intr_md_for_tm.level1_mcast_hash ig_intr_md_for_tm.level2_mcast_hash
action Tulia(BigRun) {
   modify_field( ig_intr_md_for_tm.level2_mcast_hash, Lenoir.Brinson );
   modify_field( ig_intr_md_for_tm.level2_exclusion_id, BigRun );
}
table Isleta {
   reads {
      ig_intr_md.ingress_port : exact;
   }
   actions {
      Tulia;
   }
   default_action : Tulia( 0 );
   size : 512;
}
field_list Sidon {
   4'0;
   Stillmore.Munich;
}
field_list_calculation Noyack {
   input {
      Sidon;
   }
   algorithm : identity;
   output_width : 16;
}
action Swain( RossFork ) {
   modify_field(ig_intr_md_for_tm.level1_exclusion_id, RossFork);
   modify_field(ig_intr_md_for_tm.rid, ig_intr_md_for_tm.mcast_grp_a);
}
action Murdock(Hawley) {
   Swain( Hawley );
}
action Amanda(Daykin) {
   modify_field( ig_intr_md_for_tm.rid, 0xFFFF );
   modify_field( ig_intr_md_for_tm.level1_exclusion_id, Daykin );
}
action Eunice() {
   Amanda( 0 );
   modify_field_with_hash_based_offset( ig_intr_md_for_tm.mcast_grp_a, 0, Noyack, 65536 );
}
action Estero( Exton ) {
   modify_field(ig_intr_md_for_tm.level1_exclusion_id, Exton);
   modify_field( ig_intr_md_for_tm.rid, 0 );
   modify_field_with_hash_based_offset( ig_intr_md_for_tm.mcast_grp_a, 0, Noyack, 65536 );
}
@pragma pa_no_init ingress ig_intr_md_for_tm.rid
table Moylan {
   reads {
      Stillmore.Campo : ternary;
      Stillmore.Junior : ternary;
      Townville.Geeville : ternary;
      Stillmore.Munich mask 0xF0000 : ternary;
      ig_intr_md_for_tm.mcast_grp_a mask 0xF000 : ternary;
   }
   actions {
      Swain;
      Murdock;
      Amanda;
      Eunice;
   }
   default_action : Murdock( 0 );
   size: 512;
}
control Sodaville {
   apply(Isleta);
}
control Crestone {
   if( Stillmore.Verbena == 0 ) {
      apply(Moylan);
   }
}
action NeckCity( Kulpmont ) {
   modify_field( Stillmore.Lueders, Kulpmont );
   modify_field( Stillmore.Junior, 1 );
}
table Flaxton {
   reads {
      eg_intr_md.egress_rid: exact;
   }
   actions {
      NeckCity;
   }
   size : 16384;
}
control Peoria {
   if (eg_intr_md.egress_rid != 0) {
      apply( Melrude ) {
         Sonora {
            apply( Flaxton );
         }
      }
   }
}
@pragma pa_no_init ingress Allison.Tekonsha
action Grantfork() {
   modify_field( Allison.Tekonsha, 0 );
   modify_field( Wanilla.Reagan, Allison.Bernstein );
   modify_field( Wanilla.Telephone, MudLake.Kress );
   modify_field( Wanilla.Woodfords, Allison.Lattimore );
   modify_field( Wanilla.Elmont, Allison.Hephzibah );
}
action Hillcrest() {
   modify_field( Allison.Tekonsha, 0 );
   modify_field( Wanilla.Reagan, Allison.Bernstein );
   modify_field( Wanilla.Telephone, Gunder.Fairlea );
   modify_field( Wanilla.Woodfords, Allison.Lattimore );
   modify_field( Wanilla.Elmont, Allison.Hephzibah );
}
action Crumstown( Woodsboro, Perryton ) {
   Grantfork();
   modify_field( Wanilla.TiePlant, Woodsboro );
   modify_field( Wanilla.Alcester, Perryton );
}
action Kasilof( Shingler, Hennessey ) {
   Hillcrest();
   modify_field( Wanilla.TiePlant, Shingler );
   modify_field( Wanilla.Alcester, Hennessey );
}
action Trimble() {
   modify_field( Allison.Tekonsha, 1 );
}
action Fristoe() {
   modify_field( Allison.Oldsmar, 1 );
}
@pragma pa_no_init ingress Wanilla.TiePlant
@pragma pa_container_size ingress Wanilla.TiePlant 16
@pragma pa_no_init ingress Wanilla.Corfu
@pragma pa_container_size ingress Wanilla.Corfu 16
table Coalgate {
   reads {
      MudLake.LaMoille : ternary;
   }
   actions {
      Crumstown;
      Trimble;
   }
   default_action : Grantfork();
   size : 2048;
}
table Magna {
   reads {
      Gunder.Hamden : ternary;
   }
   actions {
      Kasilof;
      Trimble;
   }
   default_action : Hillcrest();
   size : 1024;
}
action Lindsay( Armagh, Belfast ) {
   modify_field( Wanilla.Corfu, Armagh );
   modify_field( Wanilla.Worthing, Belfast );
}
table Bootjack {
   reads {
      MudLake.SanSimon : ternary;
   }
   actions {
      Lindsay;
      Fristoe;
   }
   size : 512;
}
table Blossburg {
   reads {
      Gunder.Varnado : ternary;
   }
   actions {
      Lindsay;
      Fristoe;
   }
   size : 512;
}
control Dixon {
   if( Allison.Virginia == 0x1 ) {
      apply( Coalgate );
      apply( Bootjack );
   } else if( Allison.Virginia == 0x2 ) {
      apply( Magna );
      apply( Blossburg );
   }
}
metadata Sugarloaf Petty;
counter Nordheim {
   type : packets;
   direct: Bardwell;
   min_width: 63;
}
table Bardwell {
   reads {
      Petty.Osage mask 0x00007FFF : exact;
   }
   actions {
      Sonora;
   }
   default_action: Sonora();
   size : 32768;
}
action FortShaw( Brashear, Moorcroft ) {
   modify_field( Petty.Osage, Moorcroft, 0xFFFF );
   modify_field( Wanilla.Crooks, Brashear );
   modify_field( Allison.Culloden, 1 );
}
action Quarry( Pillager, RoseBud ) {
   modify_field( Petty.Osage, RoseBud, 0xFFFF );
   modify_field( Wanilla.Crooks, Pillager );
}
@pragma ways 3
@pragma immediate 0
table Winters {
   reads {
      Allison.Virginia mask 0x3 : exact;
      Allison.Kalskag : exact;
   }
   actions {
      FortShaw;
   }
   size : 8192;
}
table Oakton {
   reads {
      Allison.Virginia mask 0x3 : exact;
      ig_intr_md.ingress_port mask 0x7F : exact;
   }
   actions {
      Quarry;
      Sonora;
   }
   default_action : Sonora();
   size : 512;
}
action Luning( Atlas ) {
   modify_field( Wanilla.Caliente, Atlas );
}
table Peosta {
   reads {
      Allison.Tiverton : ternary;
   }
   actions {
      Luning;
   }
   size : 1024;
}
action Engle( FifeLake ) {
   modify_field( Wanilla.Rushton, FifeLake );
}
table Bratenahl {
   reads {
      Allison.PawCreek : ternary;
   }
   actions {
      Engle;
   }
   size : 1024;
}
action Madras() {
   modify_field( Petty.Osage, 0 );
}
table Bosler {
   actions {
      Madras;
   }
   default_action : Madras();
   size : 1;
}
control Hamel {
   Dixon();
   if( ( Allison.Elloree & 2 ) == 2 ) {
      apply( Peosta );
      apply( Bratenahl );
   }
   if( Stillmore.Campo == 0 ) {
      apply( Oakton ) {
         Sonora {
            apply( Winters );
         }
      }
   } else {
      apply( Winters );
   }
}
   action Mingus( Antelope ) {
          max( Petty.Osage, Petty.Osage, Antelope );
   }
@pragma ways 1
table Toano {
   reads {
      Wanilla.Crooks : exact;
      Wanilla.TiePlant : exact;
      Wanilla.Corfu : exact;
      Wanilla.Caliente : exact;
      Wanilla.Rushton : exact;
      Wanilla.Reagan : exact;
      Wanilla.Telephone : exact;
      Wanilla.Woodfords : exact;
      Wanilla.Elmont : exact;
      Wanilla.Hanford : exact;
   }
   actions {
      Mingus;
   }
   size : 4096;
}
control Habersham {
   apply( Toano );
}
@pragma pa_no_init ingress Logandale.TiePlant
@pragma pa_no_init ingress Logandale.Corfu
@pragma pa_no_init ingress Logandale.Caliente
@pragma pa_no_init ingress Logandale.Rushton
@pragma pa_no_init ingress Logandale.Reagan
@pragma pa_no_init ingress Logandale.Telephone
@pragma pa_no_init ingress Logandale.Woodfords
@pragma pa_no_init ingress Logandale.Elmont
@pragma pa_no_init ingress Logandale.Hanford
metadata MuleBarn Logandale;
@pragma ways 1
table Skokomish {
   reads {
      Wanilla.Crooks : exact;
      Logandale.TiePlant : exact;
      Logandale.Corfu : exact;
      Logandale.Caliente : exact;
      Logandale.Rushton : exact;
      Logandale.Reagan : exact;
      Logandale.Telephone : exact;
      Logandale.Woodfords : exact;
      Logandale.Elmont : exact;
      Logandale.Hanford : exact;
   }
   actions {
      Mingus;
   }
   size : 8192;
}
action Shongaloo( Yukon, Arbyrd, Sledge, Kenton, Bonney, Pajaros, ElJebel, Gagetown, Riverwood ) {
   bit_and( Logandale.TiePlant, Wanilla.TiePlant, Yukon );
   bit_and( Logandale.Corfu, Wanilla.Corfu, Arbyrd );
   bit_and( Logandale.Caliente, Wanilla.Caliente, Sledge );
   bit_and( Logandale.Rushton, Wanilla.Rushton, Kenton );
   bit_and( Logandale.Reagan, Wanilla.Reagan, Bonney );
   bit_and( Logandale.Telephone, Wanilla.Telephone, Pajaros );
   bit_and( Logandale.Woodfords, Wanilla.Woodfords, ElJebel );
   bit_and( Logandale.Elmont, Wanilla.Elmont, Gagetown );
   bit_and( Logandale.Hanford, Wanilla.Hanford, Riverwood );
}
table Emsworth {
   reads {
      Wanilla.Crooks : exact;
   }
   actions {
      Shongaloo;
   }
   default_action : Shongaloo(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Anthony {
   apply( Emsworth );
}
control Petrey {
   apply( Skokomish );
}
@pragma ways 1
table Ackerman {
   reads {
      Wanilla.Crooks : exact;
      Logandale.TiePlant : exact;
      Logandale.Corfu : exact;
      Logandale.Caliente : exact;
      Logandale.Rushton : exact;
      Logandale.Reagan : exact;
      Logandale.Telephone : exact;
      Logandale.Woodfords : exact;
      Logandale.Elmont : exact;
      Logandale.Hanford : exact;
   }
   actions {
      Mingus;
   }
   size : 4096;
}
action Waitsburg( Hooks, Goulding, Rawson, Bayonne, Moultrie, Seattle, Winfall, Borth, Annville ) {
   bit_and( Logandale.TiePlant, Wanilla.TiePlant, Hooks );
   bit_and( Logandale.Corfu, Wanilla.Corfu, Goulding );
   bit_and( Logandale.Caliente, Wanilla.Caliente, Rawson );
   bit_and( Logandale.Rushton, Wanilla.Rushton, Bayonne );
   bit_and( Logandale.Reagan, Wanilla.Reagan, Moultrie );
   bit_and( Logandale.Telephone, Wanilla.Telephone, Seattle );
   bit_and( Logandale.Woodfords, Wanilla.Woodfords, Winfall );
   bit_and( Logandale.Elmont, Wanilla.Elmont, Borth );
   bit_and( Logandale.Hanford, Wanilla.Hanford, Annville );
}
table Garrison {
   reads {
      Wanilla.Crooks : exact;
   }
   actions {
      Waitsburg;
   }
   default_action : Waitsburg(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Libby {
   apply( Garrison );
}
control Ranchito {
   apply( Ackerman );
}
@pragma ways 1
table Endicott {
   reads {
      Wanilla.Crooks : exact;
      Logandale.TiePlant : exact;
      Logandale.Corfu : exact;
      Logandale.Caliente : exact;
      Logandale.Rushton : exact;
      Logandale.Reagan : exact;
      Logandale.Telephone : exact;
      Logandale.Woodfords : exact;
      Logandale.Elmont : exact;
      Logandale.Hanford : exact;
   }
   actions {
      Mingus;
   }
   size : 4096;
}
action Center( Louin, Fayette, Portales, Level, Gakona, Sabina, Patsville, Brohard, Holliston ) {
   bit_and( Logandale.TiePlant, Wanilla.TiePlant, Louin );
   bit_and( Logandale.Corfu, Wanilla.Corfu, Fayette );
   bit_and( Logandale.Caliente, Wanilla.Caliente, Portales );
   bit_and( Logandale.Rushton, Wanilla.Rushton, Level );
   bit_and( Logandale.Reagan, Wanilla.Reagan, Gakona );
   bit_and( Logandale.Telephone, Wanilla.Telephone, Sabina );
   bit_and( Logandale.Woodfords, Wanilla.Woodfords, Patsville );
   bit_and( Logandale.Elmont, Wanilla.Elmont, Brohard );
   bit_and( Logandale.Hanford, Wanilla.Hanford, Holliston );
}
table Nellie {
   reads {
      Wanilla.Crooks : exact;
   }
   actions {
      Center;
   }
   default_action : Center(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Dagsboro {
   apply( Nellie );
}
control LeeCreek {
   apply( Endicott );
}
@pragma ways 1
table Hanahan {
   reads {
      Wanilla.Crooks : exact;
      Logandale.TiePlant : exact;
      Logandale.Corfu : exact;
      Logandale.Caliente : exact;
      Logandale.Rushton : exact;
      Logandale.Reagan : exact;
      Logandale.Telephone : exact;
      Logandale.Woodfords : exact;
      Logandale.Elmont : exact;
      Logandale.Hanford : exact;
   }
   actions {
      Mingus;
   }
   size : 8192;
}
action Surrey( McClure, Brookside, Shipman, Exeland, Penalosa, Tuskahoma, Murphy, Crouch, Pineville ) {
   bit_and( Logandale.TiePlant, Wanilla.TiePlant, McClure );
   bit_and( Logandale.Corfu, Wanilla.Corfu, Brookside );
   bit_and( Logandale.Caliente, Wanilla.Caliente, Shipman );
   bit_and( Logandale.Rushton, Wanilla.Rushton, Exeland );
   bit_and( Logandale.Reagan, Wanilla.Reagan, Penalosa );
   bit_and( Logandale.Telephone, Wanilla.Telephone, Tuskahoma );
   bit_and( Logandale.Woodfords, Wanilla.Woodfords, Murphy );
   bit_and( Logandale.Elmont, Wanilla.Elmont, Crouch );
   bit_and( Logandale.Hanford, Wanilla.Hanford, Pineville );
}
table Alamance {
   reads {
      Wanilla.Crooks : exact;
   }
   actions {
      Surrey;
   }
   default_action : Surrey(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Eolia {
   apply( Alamance );
}
control Sieper {
   apply( Hanahan );
}
@pragma ways 1
table Huttig {
   reads {
      Wanilla.Crooks : exact;
      Logandale.TiePlant : exact;
      Logandale.Corfu : exact;
      Logandale.Caliente : exact;
      Logandale.Rushton : exact;
      Logandale.Reagan : exact;
      Logandale.Telephone : exact;
      Logandale.Woodfords : exact;
      Logandale.Elmont : exact;
      Logandale.Hanford : exact;
   }
   actions {
      Mingus;
   }
   size : 8192;
}
action Trona( Satanta, Matheson, Eggleston, Rosburg, Kamas, Belfair, Basye, Brumley, Orrum ) {
   bit_and( Logandale.TiePlant, Wanilla.TiePlant, Satanta );
   bit_and( Logandale.Corfu, Wanilla.Corfu, Matheson );
   bit_and( Logandale.Caliente, Wanilla.Caliente, Eggleston );
   bit_and( Logandale.Rushton, Wanilla.Rushton, Rosburg );
   bit_and( Logandale.Reagan, Wanilla.Reagan, Kamas );
   bit_and( Logandale.Telephone, Wanilla.Telephone, Belfair );
   bit_and( Logandale.Woodfords, Wanilla.Woodfords, Basye );
   bit_and( Logandale.Elmont, Wanilla.Elmont, Brumley );
   bit_and( Logandale.Hanford, Wanilla.Hanford, Orrum );
}
table Alabam {
   reads {
      Wanilla.Crooks : exact;
   }
   actions {
      Trona;
   }
   default_action : Trona(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Sparkill {
   apply( Alabam );
}
control Calvary {
   apply( Huttig );
}
@pragma ways 1
table Fentress {
   reads {
      Wanilla.Crooks : exact;
      Logandale.TiePlant : exact;
      Logandale.Corfu : exact;
      Logandale.Caliente : exact;
      Logandale.Rushton : exact;
      Logandale.Reagan : exact;
      Logandale.Telephone : exact;
      Logandale.Woodfords : exact;
      Logandale.Elmont : exact;
      Logandale.Hanford : exact;
   }
   actions {
      Mingus;
   }
   size : 4096;
}
action Varna( Stratford, Daysville, Kalvesta, Hesler, Butler, Broadus, Hagaman, Kennedale, Craigtown ) {
   bit_and( Logandale.TiePlant, Wanilla.TiePlant, Stratford );
   bit_and( Logandale.Corfu, Wanilla.Corfu, Daysville );
   bit_and( Logandale.Caliente, Wanilla.Caliente, Kalvesta );
   bit_and( Logandale.Rushton, Wanilla.Rushton, Hesler );
   bit_and( Logandale.Reagan, Wanilla.Reagan, Butler );
   bit_and( Logandale.Telephone, Wanilla.Telephone, Broadus );
   bit_and( Logandale.Woodfords, Wanilla.Woodfords, Hagaman );
   bit_and( Logandale.Elmont, Wanilla.Elmont, Kennedale );
   bit_and( Logandale.Hanford, Wanilla.Hanford, Craigtown );
}
table Honaker {
   reads {
      Wanilla.Crooks : exact;
   }
   actions {
      Varna;
   }
   default_action : Varna(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Duster {
}
control Menomonie {
}
@pragma ways 1
table LeMars {
   reads {
      Wanilla.Crooks : exact;
      Logandale.TiePlant : exact;
      Logandale.Corfu : exact;
      Logandale.Caliente : exact;
      Logandale.Rushton : exact;
      Logandale.Reagan : exact;
      Logandale.Telephone : exact;
      Logandale.Woodfords : exact;
      Logandale.Elmont : exact;
      Logandale.Hanford : exact;
   }
   actions {
      Mingus;
   }
   size : 4096;
}
action KawCity( NewCity, NewRoads, Fairborn, Pearson, Gould, Valsetz, Kenmore, Baldridge, Gibbs ) {
   bit_and( Logandale.TiePlant, Wanilla.TiePlant, NewCity );
   bit_and( Logandale.Corfu, Wanilla.Corfu, NewRoads );
   bit_and( Logandale.Caliente, Wanilla.Caliente, Fairborn );
   bit_and( Logandale.Rushton, Wanilla.Rushton, Pearson );
   bit_and( Logandale.Reagan, Wanilla.Reagan, Gould );
   bit_and( Logandale.Telephone, Wanilla.Telephone, Valsetz );
   bit_and( Logandale.Woodfords, Wanilla.Woodfords, Kenmore );
   bit_and( Logandale.Elmont, Wanilla.Elmont, Baldridge );
   bit_and( Logandale.Hanford, Wanilla.Hanford, Gibbs );
}
table Donna {
   reads {
      Wanilla.Crooks : exact;
   }
   actions {
      KawCity;
   }
   default_action : KawCity(0xffff, 0xffff, 0xffff, 0xffff, 0xff, 0x3f, 0xff, 0xff, 1);
   size : 256;
}
control Conda {
   apply( Donna );
}
control Hannibal {
   apply( LeMars );
}
counter Charters {
   type : packets;
   direct : Zemple;
   min_width: 64;
}
action Jerico() {
   bit_or( ig_intr_md_for_tm.copy_to_cpu, ig_intr_md_for_tm.copy_to_cpu, 0 );
}
action Bramwell() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
}
action Maury() {
   bit_or( ig_intr_md_for_tm.drop_ctl, ig_intr_md_for_tm.drop_ctl, 3 );
}
action Bayport() {
   bit_or( ig_intr_md_for_tm.copy_to_cpu, ig_intr_md_for_tm.copy_to_cpu, 0 );
   Maury();
}
action Ovett() {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
   Maury();
}
table Zemple {
   reads {
      ig_intr_md.ingress_port mask 0x7f : ternary;
      Petty.Osage mask 0x00018000 : ternary;
      Allison.Adona : ternary;
      Allison.Emmet : ternary;
      Allison.Dubuque : ternary;
      Allison.Skiatook : ternary;
      Allison.Westway : ternary;
      Allison.Headland : ternary;
      Allison.LaPalma : ternary;
      Allison.Virginia mask 0x4 : ternary;
      Stillmore.Munich : ternary;
      ig_intr_md_for_tm.mcast_grp_a : ternary;
      Stillmore.Junior : ternary;
      Stillmore.Verbena : ternary;
      Allison.Cornell : ternary;
      Allison.Quinhagak : ternary;
      Basalt.Harris : ternary;
      Basalt.Roxboro : ternary;
      Allison.Quinnesec : ternary;
      ig_intr_md_for_tm.copy_to_cpu : ternary;
      Allison.Dubach : ternary;
      Allison.Kaplan : ternary;
      Allison.Sunrise : ternary;
      Allison.Biddle : ternary;
      Townville.Coventry : ternary;
   }
   actions {
      Jerico;
      Bramwell;
      Bayport;
      Ovett;
      Maury;
   }
   default_action: Jerico();
   size : 1536;
}
control Sherwin {
   apply( Zemple ) {
      Maury {
      }
      Bayport {
      }
      Ovett {
      }
      default {
         apply( Waldport );
         apply( Bardwell );
      }
   }
}
action Hueytown( PortWing ) {
   modify_field( Stillmore.Domingo, PortWing );
}
action Hopeton() {
   remove_header( Idria );
}
action Hotchkiss() {
   remove_header( LaPryor );
}
action Columbia( Ethete ) {
   modify_field( Stillmore.Monrovia, Ethete );
   bit_or( Idria.RushCity, Idria.RushCity, 0x80 );
}
action Amonate( Rawlins ) {
   modify_field( Stillmore.Monrovia, Rawlins );
   bit_or( LaPryor.Millport, LaPryor.Millport, 0x80 );
}
table Barron {
   reads {
      Stillmore.Campo : exact;
      Allison.Bernstein mask 0x80 : exact;
      Idria.valid : exact;
      LaPryor.valid : exact;
   }
   actions {
      Columbia;
      Amonate;
      Hopeton;
      Hotchkiss;
   }
   size : 1024;
}
action Forbes() {
   modify_field( Idria.RushCity, 0, 0x80 );
}
action Cornwall() {
   modify_field( LaPryor.Millport, 0, 0x80 );
}
table Avondale {
   reads {
      Stillmore.Monrovia : exact;
      Idria.valid : exact;
      LaPryor.valid : exact;
   }
   actions {
      Forbes;
      Cornwall;
   }
   size : 16;
}
action Mackey(Alden) {
   modify_field( ig_intr_md_for_tm.mcast_grp_a, 0 );
   modify_field( Stillmore.Verbena, 1 );
   modify_field( Stillmore.Mahopac, Alden);
}
action Achille(Longmont) {
   modify_field( ig_intr_md_for_tm.copy_to_cpu, 1 );
   modify_field( Stillmore.Mahopac, Longmont);
}
counter Pelion {
   type : packets_and_bytes;
   direct : Heads;
   min_width: 64;
}
table Heads {
   reads {
      Allison.Domestic : ternary;
      Allison.Kaplan : ternary;
      Allison.Sunrise : ternary;
      Allison.Kalskag : ternary;
      Allison.Elloree : ternary;
      Allison.Tiverton : ternary;
      Allison.PawCreek : ternary;
      Townville.Bells : ternary;
      Shorter.Frederika : ternary;
      Allison.Lattimore : ternary;
      Titonka.valid : ternary;
      Titonka.Susank : ternary;
      Allison.Freeny : ternary;
      MudLake.SanSimon : ternary;
      Allison.Bernstein : ternary;
      Stillmore.Pierpont : ternary;
      Stillmore.Campo : ternary;
      Gunder.Varnado mask 0xffff0000000000000000000000000000 : ternary;
      Allison.Amazonia :ternary;
      Stillmore.Mahopac :ternary;
   }
   actions {
      Mackey;
      Achille;
      Edwards;
   }
   size : 512;
}
control DuBois {
   apply( Heads );
}
field_list Halfa {
   Allison.Osseo;
   Stillmore.McIntosh;
}
field_list Anniston {
   Allison.Osseo;
   Stillmore.McIntosh;
}
field_list Dassel {
   Lenoir.Brinson;
}
field_list_calculation Minoa {
   input {
      Dassel;
   }
   algorithm : identity;
   output_width : 51;
}
field_list Wamego {
   Lenoir.Brinson;
}
field_list_calculation Neshaminy {
   input {
      Wamego;
   }
   algorithm : identity;
   output_width : 51;
}
action McDermott( Braymer ) {
   modify_field( Mondovi.Dante, Braymer );
}
action Needles() {
   modify_field( Allison.Quinhagak, 1 );
}
table Rienzi {
   reads {
      Townville.Bells : ternary;
      ig_intr_md.ingress_port : ternary;
      Wanilla.Alcester : ternary;
      Wanilla.Worthing : ternary;
      PineHill.LaSalle : ternary;
      Allison.Bernstein : ternary;
      Allison.Lattimore : ternary;
      MillCity.Roodhouse : ternary;
      MillCity.Dunnellon : ternary;
      MillCity.valid : ternary;
      Wanilla.Hanford : ternary;
      Wanilla.Elmont : ternary;
      Allison.Virginia : ternary;
   }
   actions {
      Needles;
      McDermott;
   }
   default_action : McDermott(0);
   size : 1024;
}
control Magazine {
   apply( Rienzi );
}
meter Vesuvius {
   type : bytes;
   static : Parmerton;
   instance_count : 128;
}
action Chantilly( Arthur ) {
   execute_meter( Vesuvius, Arthur, Mondovi.ElkNeck );
}
action Hettinger() {
   modify_field( Mondovi.ElkNeck, 2 );
}
@pragma pa_alias ingress Mondovi.Dante Mondovi.Ruffin
@pragma pa_no_init ingress Mondovi.Ruffin
@pragma force_table_dependency Darco
table Parmerton {
   reads {
      Mondovi.Ruffin : exact;
   }
   actions {
      Chantilly;
      Hettinger;
   }
   default_action : Hettinger();
   size : 1024;
}
control Blairsden {
   apply( Parmerton );
}
action Shivwits() {
   clone_ingress_pkt_to_egress( Mondovi.Dante, Halfa );
}
table Lovett {
   reads {
      Mondovi.ElkNeck : exact;
   }
   actions {
      Shivwits;
   }
   size : 2;
}
control DelMar {
   if( Mondovi.Dante != 0 ) {
      apply( Lovett );
   }
}
action_selector Langtry {
    selection_key : Minoa;
    selection_mode : resilient;
}
action Shevlin( Placedo ) {
   bit_or( Mondovi.Dante, Mondovi.Dante, Placedo );
}
action_profile Eastover {
   actions {
      Shevlin;
   }
   size : 512;
   dynamic_action_selection : Langtry;
}
@pragma ternary 1
table Darco {
   reads {
      Mondovi.Dante mask 0x7F : exact;
   }
   action_profile : Eastover;
   size : 128;
}
control Freeburg {
   apply( Darco );
}
action Sofia() {
   modify_field( Stillmore.Campo, 0 );
   modify_field( Stillmore.Westel, 3 );
}
action LeSueur( Marlton, Stewart, Altadena, Jarrell, Christmas, Palomas,
      Melstrand, Wells ) {
   modify_field( Stillmore.Campo, 0 );
   modify_field( Stillmore.Westel, 4 );
   add_header( Idria );
   modify_field( Idria.Dunnegan, 0x4);
   modify_field( Idria.Kewanee, 0x5);
   modify_field( Idria.McAllen, Jarrell);
   modify_field( Idria.RushCity, 47 );
   modify_field( Idria.Buncombe, Altadena);
   modify_field( Idria.Wakeman, 0 );
   modify_field( Idria.Slana, 0 );
   modify_field( Idria.Robinson, 0 );
   modify_field( Idria.Raytown, 0 );
   modify_field( Idria.Mogote, 0 );
   modify_field( Idria.Reidland, Marlton);
   modify_field( Idria.Ballville, Stewart);
   add( Idria.Diomede, eg_intr_md.pkt_length, 15 );
   add_header( Wanatah );
   modify_field( Wanatah.Waseca, Christmas);
   modify_field( Stillmore.Birds, Palomas );
   modify_field( Stillmore.Summit, Melstrand );
   modify_field( Stillmore.Lookeba, Wells );
   modify_field( Stillmore.Junior, 0 );
}
action Perryman( BigBow ) {
   modify_field( Stillmore.Mahopac, BigBow );
   modify_field( Stillmore.Ladelle, 1 );
   modify_field( Stillmore.Campo, 0 );
   modify_field( Stillmore.Westel, 2 );
   modify_field( Stillmore.Eaton, 1 );
   modify_field( Stillmore.Junior, 0 );
}
@pragma ternary 1
table Magnolia {
   reads {
      eg_intr_md.egress_rid : exact;
      eg_intr_md.egress_port : exact;
   }
   actions {
      Sofia;
      Perryman;
      LeSueur;
   }
   size : 8;
}
control Olivet {
   apply( Magnolia );
}
action Tuttle( Neame ) {
   modify_field( Moreland.Oklee, Neame );
}
table Lazear {
   reads {
      eg_intr_md.egress_port : exact;
   }
   actions {
      Tuttle;
   }
   default_action : Tuttle(0);
   size : 128;
}
control Pettigrew {
   apply( Lazear );
}
action_selector Catlin {
   selection_key : Neshaminy;
   selection_mode : resilient;
}
action Supai( Penrose ) {
   bit_or( Moreland.Oklee, Moreland.Oklee, Penrose );
}
action_profile Slayden {
   actions {
      Supai;
   }
   size : 512;
   dynamic_action_selection : Catlin;
}
@pragma ternary 1
table Lyndell {
   reads {
      Moreland.Oklee mask 0x7F : exact;
   }
   action_profile : Slayden;
   size : 128;
}
control English {
   apply( Lyndell );
}
meter Lordstown {
   type : bytes;
   static : Lenox;
   instance_count : 128;
}
action Arvonia( WebbCity ) {
   execute_meter( Lordstown, WebbCity, Moreland.Westview );
}
action Ragley() {
   modify_field( Moreland.Westview, 2 );
}
@pragma pa_alias egress Moreland.Oklee Moreland.Webbville
@pragma pa_container_size egress Moreland.Westview 16
@pragma ternary 1
table Lenox {
   reads {
      Moreland.Webbville : exact;
   }
   actions {
      Arvonia;
      Ragley;
   }
   default_action : Ragley();
   size : 1024;
}
control Ozark {
   apply( Lenox );
}
action Sultana() {
   modify_field( Stillmore.McIntosh, eg_intr_md.egress_port );
   modify_field( Allison.Osseo, Stillmore.Lueders );
   clone_egress_pkt_to_egress( Moreland.Oklee, Anniston );
}
table Darmstadt {
   actions {
      Sultana;
   }
   default_action: Sultana();
   size : 1;
}
control WarEagle {
   if( Moreland.Oklee != 0 and Moreland.Westview == 0 ) {
      apply( Darmstadt );
   }
}
counter Quogue {
   type : packets;
   direct : Cowell;
   min_width: 64;
}
action Corydon() {
   drop();
}
table Cowell {
   reads {
      eg_intr_md.egress_port mask 0x7f : exact;
      Kenefic.SneeOosh : ternary;
      Kenefic.Magasco : ternary;
      PineHill.Baudette : ternary;
      Stillmore.Domingo : ternary;
      Stillmore.Norwood : ternary;
   }
   actions {
      Corydon;
      Sonora;
   }
   default_action : Sonora();
   size : 512;
}
control Ladoga {
   apply( Cowell ) {
      Sonora {
         WarEagle();
      }
   }
}
counter Lewes {
   type : packets_and_bytes;
   direct: Flatwoods;
   min_width: 32;
}
table Flatwoods {
   reads {
      Stillmore.Campo : exact;
      Allison.Kalskag mask 0xfff : exact;
   }
   actions {
      Sonora;
   }
   default_action: Sonora();
   size : 512;
}
control Goldman {
   if( Stillmore.Junior == 1 ) {
      apply( Flatwoods );
   }
}
counter Corbin {
   type : packets_and_bytes;
   direct: Mulvane;
   min_width: 64;
}
table Mulvane {
   reads {
      Stillmore.Campo mask 1: exact;
      Stillmore.Lueders mask 0xfff : exact;
   }
   actions {
      Sonora;
   }
   default_action: Sonora();
   size : 512;
}
control Dunbar {
   if( Stillmore.Junior == 1 ) {
      apply( Mulvane );
   }
}
control Cullen {
}
control Waialua {
}
control Wayne {
}
control Salome {
}
control ingress {
   Troutman();
   {
      apply( Taiban );
      if( Townville.Geeville != 0 ) {
         Jesup();
      }
      Dixfield();
      Hamel();
      Knollwood();
      Anthony();
      Anvik();
      Overlea();
      ViewPark();
      if ( Allison.Adona == 0 and Basalt.Roxboro == 0 and
         Basalt.Harris == 0 ) {
         if ( ( ( Shorter.Nuremberg & ( 0x2 ) ) == ( ( 0x2 ) ) ) and Allison.Virginia == 0x2 and Shorter.Frederika == 1 ) {
            Ballinger();
         } else {
            if ( ( ( Shorter.Nuremberg & ( 0x1 ) ) == ( ( 0x1 ) ) ) and Allison.Virginia == 0x1 and Shorter.Frederika == 1 ) {
               Thistle();
            } else {
               if( valid( NewTrier ) ) {
                  Kirwin();
               }
               if( Stillmore.Verbena == 0 and Stillmore.Campo != 2 ) {
                  Fennimore();
               }
            }
         }
      }
      Lovewell();
      Madison();
      Mapleview();
      Petrey();
      Libby();
      Wadley();

      Cullen();
      Berenice();
      Ranchito();
      Dagsboro();
      Hiwassee();
      Wayne();
      Lecompte();
      LeeCreek();
      Eolia();

      apply( BoxElder );


      Levittown();
      Corinne();
      apply( Calumet );
      Sieper();
      Sparkill();
      Whigham();

      Waretown();
      Magazine();
      DuBois();
      Waialua();
   }

   {
      RioLinda();
      Freeburg();
            DeepGap();
      Telocaset();
      Menomonie();
      Duster();
      Calvary();



      Blairsden();
      if( Stillmore.Verbena == 0 ) {
         Frewsburg();
         apply( Ramos );
      }
      apply(Barron);
      Volcano();
      {
         Plains();
      }
      if( ( Comptche.Attica & 0xFFF0) != 0 ) {
         apply( Craigmont );
      }
      if( Allison.Culloden == 1 and Shorter.Frederika == 0 ) {
         apply( Bosler );
      }
      if( Townville.Geeville != 0 ) {
         Haverford();
      }
      Sodaville();

      Ossineke();
      if( valid( Nathan[0] ) and Stillmore.Campo != 2 ) {
         Skillman();
      }
      DelMar();
   }
   Sherwin();
   {
      Crestone();


   }
}
control egress {
   {

   }
   {
      Conner();
      Swisher();
      if( ( (eg_intr_md_from_parser_aux.clone_src == NOT_CLONED) ) ) {
         Roachdale();
         Pettigrew();
         Peoria();
         if( ( eg_intr_md.egress_rid == 0 ) and
            ( eg_intr_md.egress_port != 66 ) ) {
            Goldman();
         }
         if( Stillmore.Campo == 0 or Stillmore.Campo == 3 ) {
            apply( Avondale );
         }

         SourLake();
         Ozark();
         Bedrock();

      } else {
         Olivet();
      }
      Needham();
      if( ( (eg_intr_md_from_parser_aux.clone_src == NOT_CLONED) ) and Stillmore.Eaton == 0 ) {
         Dunbar();
         if( Stillmore.Campo != 2 and Stillmore.Abbyville == 0 ) {
            Royston();
         }
         English();
         Iselin();
         GlenAvon();
         Ladoga();
      }
      if( Stillmore.Eaton == 0 and Stillmore.Campo != 2 and Stillmore.Westel != 3 ) {
         Aplin();
      }
      Salome();
   }
}

