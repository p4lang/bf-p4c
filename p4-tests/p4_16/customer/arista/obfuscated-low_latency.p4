// /usr/bin/p4c-stable/bin/p4c-bfn  -DPROFILE_LOW_LATENCY=1 -Ibf_arista_switch_low_latency/includes -I/usr/share/p4c-stable/p4include  -DSTRIPUSER=1 --verbose 2 --display-power-budget -g -Xp4c='--disable-power-check --create-graphs -T table_summary:3,table_placement:3,input_xbar:6,live_range_report:1,clot_info:6 --verbose --Wdisable=uninitialized_out_param --Wdisable=unused --Wdisable=table-placement'  --target tofino-tna --o bf_arista_switch_low_latency --bf-rt-schema bf_arista_switch_low_latency/context/bf-rt.json --disable-egress-latency-padding
// p4c 9.2.1-pr.3 (SHA: c3a6e48)

#include <core.p4>
#include <tna.p4>       /* TOFINO1_ONLY */

@pa_auto_init_metadata
@pa_container_size("ingress" , "Millstone.Livonia.Townville" , 8)
@pa_no_overlay("ingress" , "Jayton.Lindsborg[0].Findlay")
@pa_atomic("ingress" , "Millstone.Ocracoke.Moquah")
@gfm_parity_enable
@pa_alias("ingress" , "Jayton.Crannell.Laurelton" , "Millstone.BealCity.Mendocino")
@pa_alias("ingress" , "Jayton.Crannell.Ronda" , "Millstone.BealCity.Pachuta")
@pa_alias("ingress" , "Jayton.Crannell.LaPalma" , "Millstone.BealCity.Ipava")
@pa_alias("ingress" , "Jayton.Crannell.Idalia" , "Millstone.BealCity.Grabill")
@pa_alias("ingress" , "Jayton.Crannell.Cecilton" , "Millstone.BealCity.Raiford")
@pa_alias("ingress" , "Jayton.Crannell.Horton" , "Millstone.Ocracoke.Higginson")
@pa_alias("ingress" , "ig_intr_md_for_dprsr.mirror_type" , "Millstone.Martelle.Glassboro")
@pa_alias("ingress" , "ig_intr_md_for_tm.ingress_cos" , "Millstone.Belmore.Lathrop")
@pa_alias("ingress" , "Millstone.Gastonia.LaConner" , "Millstone.Gastonia.Goulds")
@pa_alias("egress" , "eg_intr_md.egress_port" , "Millstone.Millhaven.Clarion")
@pa_alias("egress" , "eg_intr_md_for_dprsr.mirror_type" , "Millstone.Martelle.Glassboro")
@pa_alias("egress" , "Jayton.Crannell.Laurelton" , "Millstone.BealCity.Mendocino")
@pa_alias("egress" , "Jayton.Crannell.Ronda" , "Millstone.BealCity.Pachuta")
@pa_alias("egress" , "Jayton.Crannell.LaPalma" , "Millstone.BealCity.Ipava")
@pa_alias("egress" , "Jayton.Crannell.Idalia" , "Millstone.BealCity.Grabill")
@pa_alias("egress" , "Jayton.Crannell.Cecilton" , "Millstone.BealCity.Raiford")
@pa_alias("egress" , "Jayton.Crannell.Horton" , "Millstone.Ocracoke.Higginson")
@pa_alias("egress" , "Millstone.Hillsview.LaConner" , "Millstone.Hillsview.Goulds") header Uintah {
    bit<8> Blitchton;
}

header Avondale {
    bit<8> Glassboro;
    @flexible 
    bit<9> Grabill;
}

@pa_atomic("ingress" , "Millstone.Ocracoke.Oriskany")
@pa_atomic("ingress" , "Millstone.BealCity.McCammon")
@pa_no_init("ingress" , "Millstone.BealCity.Pathfork")
@pa_atomic("ingress" , "Millstone.Dozier.Hulbert")
@pa_no_init("ingress" , "Millstone.Ocracoke.Moquah")
@pa_mutually_exclusive("egress" , "Millstone.BealCity.Sardinia" , "Millstone.BealCity.Barrow")
@pa_no_init("ingress" , "Millstone.Ocracoke.Basic")
@pa_no_init("ingress" , "Millstone.Ocracoke.SoapLake")
@pa_no_init("ingress" , "Millstone.Ocracoke.Rains")
@pa_no_init("ingress" , "Millstone.Ocracoke.Cisco")
@pa_no_init("ingress" , "Millstone.Ocracoke.Connell")
@pa_atomic("ingress" , "Millstone.Toluca.Knoke")
@pa_atomic("ingress" , "Millstone.Toluca.McAllen")
@pa_atomic("ingress" , "Millstone.Toluca.Dairyland")
@pa_atomic("ingress" , "Millstone.Toluca.Daleville")
@pa_atomic("ingress" , "Millstone.Toluca.Basalt")
@pa_atomic("ingress" , "Millstone.Goodwin.SourLake")
@pa_atomic("ingress" , "Millstone.Goodwin.Norma")
@pa_mutually_exclusive("ingress" , "Millstone.Lynch.Armona" , "Millstone.Sanford.Armona")
@pa_mutually_exclusive("ingress" , "Millstone.Lynch.Petrey" , "Millstone.Sanford.Petrey")
@pa_no_init("ingress" , "Millstone.Ocracoke.Piqua")
@pa_no_init("egress" , "Millstone.BealCity.Bonduel")
@pa_no_init("egress" , "Millstone.BealCity.Sardinia")
@pa_no_init("ingress" , "ig_intr_md_for_tm.level1_exclusion_id")
@pa_no_init("ingress" , "ig_intr_md_for_tm.rid")
@pa_no_init("ingress" , "Millstone.BealCity.Rains")
@pa_no_init("ingress" , "Millstone.BealCity.SoapLake")
@pa_no_init("ingress" , "Millstone.BealCity.McCammon")
@pa_no_init("ingress" , "Millstone.BealCity.Grabill")
@pa_no_init("ingress" , "Millstone.BealCity.Raiford")
@pa_no_init("ingress" , "Millstone.BealCity.Traverse")
@pa_no_init("ingress" , "Millstone.Hohenwald.Plains")
@pa_no_init("ingress" , "Millstone.Hohenwald.Sherack")
@pa_no_init("ingress" , "Millstone.Toluca.Dairyland")
@pa_no_init("ingress" , "Millstone.Toluca.Daleville")
@pa_no_init("ingress" , "Millstone.Toluca.Basalt")
@pa_no_init("ingress" , "Millstone.Toluca.Knoke")
@pa_no_init("ingress" , "Millstone.Toluca.McAllen")
@pa_no_init("ingress" , "Millstone.Goodwin.SourLake")
@pa_no_init("ingress" , "Millstone.Goodwin.Norma")
@pa_no_init("ingress" , "Millstone.Kamrar.Salix")
@pa_no_init("ingress" , "Millstone.Shingler.Salix")
@pa_no_init("ingress" , "Millstone.Ocracoke.Rains")
@pa_no_init("ingress" , "Millstone.Ocracoke.SoapLake")
@pa_no_init("ingress" , "Millstone.Ocracoke.Nenana")
@pa_no_init("ingress" , "Millstone.Ocracoke.Connell")
@pa_no_init("ingress" , "Millstone.Ocracoke.Cisco")
@pa_no_init("ingress" , "Millstone.Ocracoke.Guadalupe")
@pa_no_init("ingress" , "Millstone.Gastonia.LaConner")
@pa_no_init("ingress" , "Millstone.Gastonia.Goulds")
@pa_no_init("ingress" , "Millstone.Readsboro.Wisdom")
@pa_no_init("ingress" , "Millstone.Readsboro.Aldan")
@pa_no_init("ingress" , "Millstone.Readsboro.Sunflower")
@pa_no_init("ingress" , "Millstone.Readsboro.Kalida")
@pa_no_init("ingress" , "Millstone.Readsboro.Eldred") struct Moorcroft {
    bit<1>   Toklat;
    bit<2>   Bledsoe;
    PortId_t Blencoe;
    bit<48>  AquaPark;
}

struct Vichy {
    bit<3> Lathrop;
}

struct Clyde {
    PortId_t Clarion;
    bit<16>  Aguilita;
}

struct Harbor {
    bit<48> IttaBena;
}

@flexible struct Adona {
    bit<24> Connell;
    bit<24> Cisco;
    bit<16> Higginson;
    bit<20> Oriskany;
}

@flexible struct Bowden {
    bit<16>  Higginson;
    bit<24>  Connell;
    bit<24>  Cisco;
    bit<32>  Cabot;
    bit<128> Keyes;
    bit<16>  Basic;
    bit<16>  Freeman;
    bit<8>   Exton;
    bit<8>   Floyd;
}

@flexible struct Fayette {
    bit<48> Osterdock;
    bit<20> PineCity;
}

header Alameda {
    @flexible 
    bit<1>  Quinwood;
    @flexible 
    bit<1>  Palatine;
    @flexible 
    bit<1>  Hoagland;
    @flexible 
    bit<9>  Hackett;
    @flexible 
    bit<13> Calcasieu;
    @flexible 
    bit<16> Levittown;
    @flexible 
    bit<5>  Norwood;
    @flexible 
    bit<16> Dassel;
    @flexible 
    bit<9>  Loring;
}

header Suwannee {
}

header Dugger {
    bit<8>  Glassboro;
    @flexible 
    bit<8>  Laurelton;
    @flexible 
    bit<3>  Ronda;
    @flexible 
    bit<12> LaPalma;
    @flexible 
    bit<9>  Idalia;
    @flexible 
    bit<1>  Cecilton;
    @flexible 
    bit<12> Horton;
}

header Lacona {
    bit<6>  Albemarle;
    bit<10> Algodones;
    bit<4>  Buckeye;
    bit<12> Topanga;
    bit<2>  Spearman;
    bit<2>  Allison;
    bit<12> Chevak;
    bit<8>  Mendocino;
    bit<2>  Eldred;
    bit<3>  Chloride;
    bit<1>  Garibaldi;
    bit<1>  Weinert;
    bit<1>  Cornell;
    bit<4>  Noyes;
    bit<12> Helton;
    bit<16> Grannis;
    bit<16> Basic;
}

header StarLake {
    bit<24> Rains;
    bit<24> SoapLake;
    bit<24> Connell;
    bit<24> Cisco;
}

header Linden {
    bit<16> Basic;
}

header Conner {
    bit<24> Rains;
    bit<24> SoapLake;
    bit<24> Connell;
    bit<24> Cisco;
    bit<16> Basic;
}

header Ledoux {
    bit<16> Basic;
    bit<3>  Steger;
    bit<1>  Quogue;
    bit<12> Findlay;
}

header Dowell {
    bit<20> Glendevey;
    bit<3>  Littleton;
    bit<1>  Killen;
    bit<8>  Turkey;
}

header Riner {
    bit<4>  Palmhurst;
    bit<4>  Comfrey;
    bit<6>  Kalida;
    bit<2>  Wallula;
    bit<16> Dennison;
    bit<16> Fairhaven;
    bit<1>  Woodfield;
    bit<1>  LasVegas;
    bit<1>  Westboro;
    bit<13> Newfane;
    bit<8>  Turkey;
    bit<8>  Norcatur;
    bit<16> Burrel;
    bit<32> Petrey;
    bit<32> Armona;
}

header Dunstable {
    bit<4>   Palmhurst;
    bit<6>   Kalida;
    bit<2>   Wallula;
    bit<20>  Madawaska;
    bit<16>  Hampton;
    bit<8>   Tallassee;
    bit<8>   Irvine;
    bit<128> Petrey;
    bit<128> Armona;
}

header Antlers {
    bit<4>  Palmhurst;
    bit<6>  Kalida;
    bit<2>  Wallula;
    bit<20> Madawaska;
    bit<16> Hampton;
    bit<8>  Tallassee;
    bit<8>  Irvine;
    bit<32> Kendrick;
    bit<32> Solomon;
    bit<32> Garcia;
    bit<32> Coalwood;
    bit<32> Beasley;
    bit<32> Commack;
    bit<32> Bonney;
    bit<32> Pilar;
}

header Loris {
    bit<8>  Mackville;
    bit<8>  McBride;
    bit<16> Vinemont;
}

header Kenbridge {
    bit<32> Parkville;
}

header Mystic {
    bit<16> Kearns;
    bit<16> Malinta;
}

header Blakeley {
    bit<32> Poulan;
    bit<32> Ramapo;
    bit<4>  Bicknell;
    bit<4>  Naruna;
    bit<8>  Suttle;
    bit<16> Galloway;
}

header Ankeny {
    bit<16> Denhoff;
}

header Provo {
    bit<16> Whitten;
}

header Joslin {
    bit<16> Weyauwega;
    bit<16> Powderly;
    bit<8>  Welcome;
    bit<8>  Teigen;
    bit<16> Lowes;
}

header Almedia {
    bit<48> Chugwater;
    bit<32> Charco;
    bit<48> Sutherlin;
    bit<32> Daphne;
}

header Level {
    bit<1>  Algoa;
    bit<1>  Thayne;
    bit<1>  Parkland;
    bit<1>  Coulter;
    bit<1>  Kapalua;
    bit<3>  Halaula;
    bit<5>  Suttle;
    bit<3>  Uvalde;
    bit<16> Tenino;
}

header Pridgen {
    bit<24> Fairland;
    bit<8>  Juniata;
}

header Beaverdam {
    bit<8>  Suttle;
    bit<24> Parkville;
    bit<24> ElVerano;
    bit<8>  Floyd;
}

header Brinkman {
    bit<8> Boerne;
}

header Alamosa {
    bit<32> Elderon;
    bit<32> Knierim;
}

header Montross {
    bit<2>  Palmhurst;
    bit<1>  Glenmora;
    bit<1>  DonaAna;
    bit<4>  Altus;
    bit<1>  Merrill;
    bit<7>  Hickox;
    bit<16> Tehachapi;
    bit<32> Sewaren;
}

header WindGap {
    bit<32> Caroleen;
}

header Lordstown {
    bit<4>  Belfair;
    bit<4>  Luzerne;
    bit<8>  Palmhurst;
    bit<16> Devers;
    bit<8>  Crozet;
    bit<8>  Laxon;
    bit<16> Suttle;
}

header Chaffee {
    bit<48> Brinklow;
    bit<16> Kremlin;
}

header TroutRun {
    bit<16> Basic;
    bit<64> Bradner;
}

typedef bit<16> Ipv4PartIdx_t;
typedef bit<16> Ipv6PartIdx_t;
typedef bit<2> NextHopTable_t;
typedef bit<1> NextHop_t;
struct Ravena {
    bit<16> Redden;
    bit<8>  Yaurel;
    bit<8>  Bucktown;
    bit<4>  Hulbert;
    bit<3>  Philbrook;
    bit<3>  Skyway;
    bit<3>  Rocklin;
    bit<1>  Wakita;
    bit<1>  Latham;
}

struct Dandridge {
    bit<1> Colona;
    bit<1> Wilmore;
}

struct Piperton {
    bit<24> Rains;
    bit<24> SoapLake;
    bit<24> Connell;
    bit<24> Cisco;
    bit<16> Basic;
    bit<12> Higginson;
    bit<20> Oriskany;
    bit<12> Fairmount;
    bit<16> Dennison;
    bit<8>  Norcatur;
    bit<8>  Turkey;
    bit<3>  Guadalupe;
    bit<3>  Buckfield;
    bit<32> Moquah;
    bit<1>  Forkville;
    bit<3>  Mayday;
    bit<1>  Randall;
    bit<1>  Sheldahl;
    bit<1>  Soledad;
    bit<1>  Gasport;
    bit<1>  Chatmoss;
    bit<1>  NewMelle;
    bit<1>  Heppner;
    bit<1>  Wartburg;
    bit<1>  Lakehills;
    bit<1>  Sledge;
    bit<1>  Ambrose;
    bit<1>  Billings;
    bit<1>  Dyess;
    bit<1>  Westhoff;
    bit<1>  Havana;
    bit<1>  Nenana;
    bit<1>  Morstein;
    bit<1>  Waubun;
    bit<1>  Minto;
    bit<1>  Eastwood;
    bit<1>  Placedo;
    bit<1>  Onycha;
    bit<1>  Delavan;
    bit<1>  Bennet;
    bit<1>  Etter;
    bit<16> Freeman;
    bit<8>  Exton;
    bit<8>  Jenners;
    bit<16> Kearns;
    bit<16> Malinta;
    bit<8>  RockPort;
    bit<2>  Piqua;
    bit<2>  Stratford;
    bit<1>  RioPecos;
    bit<1>  Weatherby;
    bit<32> DeGraff;
    bit<3>  Quinhagak;
    bit<1>  Scarville;
}

struct Ivyland {
    bit<1> Edgemoor;
    bit<1> Lovewell;
}

struct Dolores {
    bit<1>  Atoka;
    bit<1>  Panaca;
    bit<1>  Madera;
    bit<16> Kearns;
    bit<16> Malinta;
    bit<32> Elderon;
    bit<32> Knierim;
    bit<1>  Cardenas;
    bit<1>  LakeLure;
    bit<1>  Grassflat;
    bit<1>  Whitewood;
    bit<1>  Tilton;
    bit<1>  Wetonka;
    bit<1>  Lecompte;
    bit<1>  Lenexa;
    bit<1>  Rudolph;
    bit<1>  Bufalo;
    bit<32> Rockham;
    bit<32> Hiland;
}

struct Manilla {
    bit<24> Rains;
    bit<24> SoapLake;
    bit<1>  Hammond;
    bit<3>  Hematite;
    bit<1>  Orrick;
    bit<12> Ipava;
    bit<20> McCammon;
    bit<6>  Lapoint;
    bit<16> Wamego;
    bit<16> Brainard;
    bit<3>  Fristoe;
    bit<12> Findlay;
    bit<10> Traverse;
    bit<3>  Pachuta;
    bit<3>  Whitefish;
    bit<8>  Mendocino;
    bit<1>  Ralls;
    bit<32> Standish;
    bit<32> Blairsden;
    bit<2>  Clover;
    bit<32> Barrow;
    bit<9>  Grabill;
    bit<2>  Spearman;
    bit<1>  Foster;
    bit<12> Higginson;
    bit<1>  Raiford;
    bit<1>  Bennet;
    bit<1>  Garibaldi;
    bit<3>  Ayden;
    bit<32> Bonduel;
    bit<32> Sardinia;
    bit<8>  Kaaawa;
    bit<24> Gause;
    bit<24> Norland;
    bit<2>  Pathfork;
    bit<1>  Tombstone;
    bit<8>  Subiaco;
    bit<12> Marcus;
    bit<1>  Pittsboro;
    bit<1>  Ericsburg;
    bit<6>  Staunton;
    bit<1>  Scarville;
}

struct Lugert {
    bit<10> Goulds;
    bit<10> LaConner;
    bit<2>  McGrady;
}

struct Oilmont {
    bit<10> Goulds;
    bit<10> LaConner;
    bit<2>  McGrady;
    bit<8>  Tornillo;
    bit<6>  Satolah;
    bit<16> RedElm;
    bit<4>  Renick;
    bit<4>  Pajaros;
}

struct Wauconda {
    bit<32> Petrey;
    bit<32> Armona;
    bit<32> Richvale;
    bit<6>  Kalida;
    bit<6>  SomesBar;
    bit<16> Vergennes;
}

struct Pierceton {
    bit<128> Petrey;
    bit<128> Armona;
    bit<8>   Tallassee;
    bit<6>   Kalida;
    bit<16>  Vergennes;
}

struct FortHunt {
    bit<14> Hueytown;
    bit<12> LaLuz;
    bit<1>  Townville;
    bit<2>  Monahans;
}

struct Pinole {
    bit<1> Bells;
    bit<1> Corydon;
}

struct Heuvelton {
    bit<1> Bells;
    bit<1> Corydon;
}

struct Chavies {
    bit<2> Miranda;
}

struct Peebles {
    bit<2> Wellton;
    bit<1> Kenney;
    bit<5> Crestone;
    bit<7> Buncombe;
    bit<2> Pettry;
    bit<1> Montague;
}

struct Rocklake {
    bit<5>         Fredonia;
    Ipv4PartIdx_t  Stilwell;
    NextHopTable_t Wellton;
    NextHop_t      Kenney;
}

struct LaUnion {
    bit<7>         Fredonia;
    Ipv6PartIdx_t  Stilwell;
    NextHopTable_t Wellton;
    NextHop_t      Kenney;
}

struct Cuprum {
    bit<1>  Belview;
    bit<1>  Randall;
    bit<1>  Broussard;
    bit<32> Arvada;
    bit<16> Kalkaska;
    bit<12> Newfolden;
    bit<12> Fairmount;
    bit<12> Candle;
}

struct Ackley {
    bit<16> Knoke;
    bit<16> McAllen;
    bit<16> Dairyland;
    bit<16> Daleville;
    bit<16> Basalt;
}

struct Darien {
    bit<16> Norma;
    bit<16> SourLake;
}

struct Juneau {
    bit<2>  Eldred;
    bit<6>  Sunflower;
    bit<3>  Aldan;
    bit<1>  RossFork;
    bit<1>  Maddock;
    bit<1>  Sublett;
    bit<3>  Wisdom;
    bit<1>  Quogue;
    bit<6>  Kalida;
    bit<6>  Cutten;
    bit<5>  Lewiston;
    bit<1>  Lamona;
    bit<1>  Naubinway;
    bit<1>  Ovett;
    bit<1>  Murphy;
    bit<2>  Wallula;
    bit<12> Edwards;
    bit<1>  Mausdale;
    bit<8>  Bessie;
}

struct Savery {
    bit<16> Quinault;
}

struct Komatke {
    bit<16> Salix;
    bit<1>  Moose;
    bit<1>  Minturn;
}

struct McCaskill {
    bit<16> Salix;
    bit<1>  Moose;
    bit<1>  Minturn;
}

struct Stennett {
    bit<16> Salix;
    bit<1>  Moose;
}

struct McGonigle {
    bit<16> Petrey;
    bit<16> Armona;
    bit<16> Sherack;
    bit<16> Plains;
    bit<16> Kearns;
    bit<16> Malinta;
    bit<8>  Tenino;
    bit<8>  Turkey;
    bit<8>  Suttle;
    bit<8>  Amenia;
    bit<1>  Tiburon;
    bit<6>  Kalida;
}

struct Freeny {
    bit<32> Sonoma;
}

struct Burwell {
    bit<8>  Belgrade;
    bit<32> Petrey;
    bit<32> Armona;
}

struct Hayfield {
    bit<8> Belgrade;
}

struct Calabash {
    bit<1>  Wondervu;
    bit<1>  Randall;
    bit<1>  GlenAvon;
    bit<20> Maumee;
    bit<12> Broadwell;
}

struct Grays {
    bit<8>  Gotham;
    bit<16> Osyka;
    bit<8>  Brookneal;
    bit<16> Hoven;
    bit<8>  Shirley;
    bit<8>  Ramos;
    bit<8>  Provencal;
    bit<8>  Bergton;
    bit<8>  Cassa;
    bit<4>  Pawtucket;
    bit<8>  Buckhorn;
    bit<8>  Rainelle;
}

struct Paulding {
    bit<8> Millston;
    bit<8> HillTop;
    bit<8> Dateland;
    bit<8> Doddridge;
}

struct Emida {
    bit<1>  Sopris;
    bit<1>  Thaxton;
    bit<32> Lawai;
    bit<16> McCracken;
    bit<10> LaMoille;
    bit<32> Guion;
    bit<20> ElkNeck;
    bit<1>  Nuyaka;
    bit<1>  Mickleton;
    bit<32> Mentone;
    bit<2>  Elvaston;
    bit<1>  Elkville;
}

struct Corvallis {
    bit<1>  Bridger;
    bit<1>  Belmont;
    bit<32> Baytown;
    bit<32> McBrides;
    bit<32> Hapeville;
    bit<32> Barnhill;
    bit<32> NantyGlo;
}

struct Wildorado {
    Ravena    Dozier;
    Piperton  Ocracoke;
    Wauconda  Lynch;
    Pierceton Sanford;
    Manilla   BealCity;
    Ackley    Toluca;
    Darien    Goodwin;
    FortHunt  Livonia;
    Peebles   Bernice;
    Pinole    Greenwood;
    Juneau    Readsboro;
    Freeny    Astor;
    McGonigle Hohenwald;
    McGonigle Sumner;
    Chavies   Eolia;
    McCaskill Kamrar;
    Savery    Greenland;
    Komatke   Shingler;
    Lugert    Gastonia;
    Oilmont   Hillsview;
    Heuvelton Westbury;
    Hayfield  Makawao;
    Burwell   Mather;
    Avondale  Martelle;
    Calabash  Gambrills;
    Dolores   Masontown;
    Ivyland   Wesson;
    Moorcroft Yerington;
    Vichy     Belmore;
    Clyde     Millhaven;
    Harbor    Newhalem;
    Corvallis Westville;
    bit<1>    Baudette;
    bit<1>    Ekron;
    bit<1>    Swisshome;
    Rocklake  Sequim;
    Rocklake  Hallwood;
    LaUnion   Empire;
    LaUnion   Daisytown;
    Cuprum    Balmorhea;
    bool      Earling;
}

struct Udall {
    Dugger    Crannell;
    Lacona    Aniak;
    StarLake  Nevis;
    Ledoux[2] Lindsborg;
    Linden    Magasco;
    Riner     Twain;
    Joslin    Boonsboro;
}

struct Talco {
    bit<32> Terral;
    bit<32> HighRock;
}

struct WebbCity {
    bit<32> Covert;
    bit<32> Ekwok;
}

struct Crump {
    bit<14> Hueytown;
    bit<16> LaLuz;
    bit<1>  Townville;
    bit<2>  Wyndmoor;
}

parser Picabo(packet_in Circle, out Udall Jayton, out Wildorado Millstone, out ingress_intrinsic_metadata_t Yerington) {
    @name(".Lookeba") value_set<bit<9>>(2) Lookeba;
    state Alstown {
        transition select(Yerington.ingress_port) {
            Lookeba: Longwood;
            default: Knights;
        }
    }
    state Longwood {
        Circle.advance(32w176);
        transition Yorkshire;
    }
    state Yorkshire {
        Circle.extract<Lacona>(Jayton.Aniak);
        transition accept;
    }
    state SanRemo {
        Millstone.Ocracoke.Higginson = Millstone.Livonia.LaLuz;
        Millstone.BealCity.Ipava = Millstone.Livonia.LaLuz;
        transition Thawville;
    }
    state Basco {
        Circle.extract<Ledoux>(Jayton.Lindsborg[0]);
        Circle.extract<Linden>(Jayton.Magasco);
        Millstone.Ocracoke.Basic = Jayton.Magasco.Basic;
        Millstone.Ocracoke.Higginson = Jayton.Lindsborg[0].Findlay;
        Millstone.BealCity.Ipava = Jayton.Lindsborg[0].Findlay;
        transition select(Jayton.Magasco.Basic) {
            16w0x800: Gamaliel;
            16w0x806: Orting;
            default: accept;
        }
    }
    state Armagh {
        Circle.extract<StarLake>(Jayton.Nevis);
        Millstone.Ocracoke.Connell = Jayton.Nevis.Connell;
        Millstone.Ocracoke.Cisco = Jayton.Nevis.Cisco;
        Millstone.BealCity.Rains = Jayton.Nevis.Rains;
        Millstone.BealCity.SoapLake = Jayton.Nevis.SoapLake;
        transition select((Circle.lookahead<bit<16>>())[15:0]) {
            16w0x8100: Basco;
            default: SanRemo;
        }
    }
    state Thawville {
        Circle.extract<Linden>(Jayton.Magasco);
        Millstone.Ocracoke.Basic = Jayton.Magasco.Basic;
        transition select(Jayton.Magasco.Basic) {
            16w0x800: Gamaliel;
            16w0x806: Orting;
            default: accept;
        }
    }
    state Gamaliel {
        Circle.extract<Riner>(Jayton.Twain);
        Millstone.Ocracoke.Norcatur = Jayton.Twain.Norcatur;
        Millstone.Lynch.Armona = Jayton.Twain.Armona;
        transition accept;
    }
    state Orting {
        Circle.extract<Joslin>(Jayton.Boonsboro);
        transition accept;
    }
    state start {
        Circle.extract<ingress_intrinsic_metadata_t>(Yerington);
        Millstone.Yerington.Blencoe = Yerington.ingress_port;
        transition Alstown;
    }
    @override_phase0_table_name("Freeburg") @override_phase0_action_name(".Matheson") state Knights {
        Crump Humeston = port_metadata_unpack<Crump>(Circle);
        Millstone.Livonia.LaLuz = (bit<12>)Humeston.LaLuz;
        Millstone.Livonia.Townville = Humeston.Townville;
        Millstone.Livonia.Hueytown = Humeston.Hueytown;
        Millstone.Livonia.Monahans = Humeston.Wyndmoor;
        transition Armagh;
    }
}

control Harriet(packet_out Circle, inout Udall Jayton, in Wildorado Millstone, in ingress_intrinsic_metadata_for_deparser_t Dushore) {
    @name(".Bratt") Digest<Adona>() Bratt;
    apply {
        if (Dushore.digest_type == 3w1) {
            Bratt.pack({ Millstone.Ocracoke.Connell, Millstone.Ocracoke.Cisco, (bit<16>)Millstone.Ocracoke.Higginson, Millstone.Ocracoke.Oriskany });
        }
        Circle.emit<Dugger>(Jayton.Crannell);
        Circle.emit<StarLake>(Jayton.Nevis);
        Circle.emit<Ledoux>(Jayton.Lindsborg[0]);
        Circle.emit<Linden>(Jayton.Magasco);
        Circle.emit<Riner>(Jayton.Twain);
        Circle.emit<Joslin>(Jayton.Boonsboro);
    }
}

control Tabler(inout Udall Jayton, inout Wildorado Millstone, in ingress_intrinsic_metadata_t Yerington, in ingress_intrinsic_metadata_from_parser_t Hearne, inout ingress_intrinsic_metadata_for_deparser_t Dushore, inout ingress_intrinsic_metadata_for_tm_t Belmore) {
    @name(".Moultrie") action Moultrie(bit<1> Etter, bit<1> Pinetop, bit<1> Garrison) {
        Millstone.Ocracoke.Etter = Etter;
        Millstone.Ocracoke.Westhoff = Pinetop;
        Millstone.Ocracoke.Havana = Garrison;
    }
    @use_hash_action(1) @disable_atomic_modify(1) @name(".Milano") table Milano {
        actions = {
            Moultrie();
        }
        key = {
            Millstone.Ocracoke.Higginson & 12w0xfff: exact @name("Ocracoke.Higginson") ;
        }
        default_action = Moultrie(1w0, 1w0, 1w0);
        size = 4096;
    }
    apply {
        Milano.apply();
    }
}

control Dacono(inout Udall Jayton, inout Wildorado Millstone, in ingress_intrinsic_metadata_t Yerington, in ingress_intrinsic_metadata_from_parser_t Hearne, inout ingress_intrinsic_metadata_for_deparser_t Dushore, inout ingress_intrinsic_metadata_for_tm_t Belmore) {
    @name(".Biggers") Register<bit<1>, bit<32>>(32w294912, 1w0) Biggers;
    @name(".Pineville") RegisterAction<bit<1>, bit<32>, bit<1>>(Biggers) Pineville = {
        void apply(inout bit<1> Nooksack, out bit<1> Courtdale) {
            Courtdale = (bit<1>)1w0;
            bit<1> Swifton;
            Swifton = Nooksack;
            Nooksack = Swifton;
            Courtdale = ~Nooksack;
        }
    };
    @name(".PeaRidge.Florin") Hash<bit<19>>(HashAlgorithm_t.IDENTITY) PeaRidge;
    @name(".Cranbury") action Cranbury() {
        bit<19> Neponset;
        Neponset = PeaRidge.get<tuple<bit<9>, bit<12>>>({ Millstone.Yerington.Blencoe, Jayton.Lindsborg[0].Findlay });
        Millstone.Greenwood.Bells = Pineville.execute((bit<32>)Neponset);
    }
    @name(".Bronwood") Register<bit<1>, bit<32>>(32w294912, 1w0) Bronwood;
    @name(".Cotter") RegisterAction<bit<1>, bit<32>, bit<1>>(Bronwood) Cotter = {
        void apply(inout bit<1> Nooksack, out bit<1> Courtdale) {
            Courtdale = (bit<1>)1w0;
            bit<1> Swifton;
            Swifton = Nooksack;
            Nooksack = Swifton;
            Courtdale = Nooksack;
        }
    };
    @name(".Kinde") action Kinde() {
        bit<19> Neponset;
        Neponset = PeaRidge.get<tuple<bit<9>, bit<12>>>({ Millstone.Yerington.Blencoe, Jayton.Lindsborg[0].Findlay });
        Millstone.Greenwood.Corydon = Cotter.execute((bit<32>)Neponset);
    }
    @disable_atomic_modify(1) @name(".Hillside") table Hillside {
        actions = {
            Cranbury();
        }
        default_action = Cranbury();
        size = 1;
    }
    @disable_atomic_modify(1) @name(".Wanamassa") table Wanamassa {
        actions = {
            Kinde();
        }
        default_action = Kinde();
        size = 1;
    }
    apply {
        Hillside.apply();
        Wanamassa.apply();
    }
}

control Peoria(inout Udall Jayton, inout Wildorado Millstone, in ingress_intrinsic_metadata_t Yerington, in ingress_intrinsic_metadata_from_parser_t Hearne, inout ingress_intrinsic_metadata_for_deparser_t Dushore, inout ingress_intrinsic_metadata_for_tm_t Belmore) {
    @name(".Frederika") action Frederika() {
        Millstone.BealCity.Standish = Millstone.BealCity.Standish | 32w0;
    }
    @name(".Saugatuck") action Saugatuck(bit<9> Flaherty) {
        Belmore.ucast_egress_port = Flaherty;
        Frederika();
    }
    @name(".Sunbury") action Sunbury() {
        Belmore.ucast_egress_port[8:0] = Millstone.BealCity.McCammon[8:0];
        Frederika();
    }
    @name(".Casnovia") action Casnovia() {
        Belmore.ucast_egress_port = 9w511;
    }
    @name(".Sedan") action Sedan() {
        Frederika();
        Casnovia();
    }
    @name(".Almota") action Almota() {
    }
    @name(".Lemont") CRCPolynomial<bit<51>>(51w0x18005, true, false, true, 51w0x0, 51w0x0) Lemont;
    @name(".Hookdale.Sawyer") Hash<bit<51>>(HashAlgorithm_t.CRC16, Lemont) Hookdale;
    @name(".Funston") ActionSelector(32w32768, Hookdale, SelectorMode_t.RESILIENT) Funston;
    @disable_atomic_modify(1) @stage(6) @name(".Mayflower") table Mayflower {
        actions = {
            Saugatuck();
            Sunbury();
            Sedan();
            Casnovia();
            Almota();
        }
        key = {
            Millstone.BealCity.McCammon: ternary @name("BealCity.McCammon") ;
            Millstone.Yerington.Blencoe: selector @name("Yerington.Blencoe") ;
            Millstone.Goodwin.Norma    : selector @name("Goodwin.Norma") ;
        }
        default_action = Sedan();
        size = 512;
        implementation = Funston;
        requires_versioning = false;
    }
    apply {
        Mayflower.apply();
    }
}

control Halltown(inout Udall Jayton, inout Wildorado Millstone, in ingress_intrinsic_metadata_t Yerington, in ingress_intrinsic_metadata_from_parser_t Hearne, inout ingress_intrinsic_metadata_for_deparser_t Dushore, inout ingress_intrinsic_metadata_for_tm_t Belmore) {
    @name(".Recluse") action Recluse() {
    }
    @name(".Arapahoe") action Arapahoe(bit<20> Maumee) {
        Recluse();
        Millstone.BealCity.Pachuta = (bit<3>)3w2;
        Millstone.BealCity.McCammon = Maumee;
        Millstone.BealCity.Ipava = Millstone.Ocracoke.Higginson;
        Millstone.BealCity.Traverse = (bit<10>)10w0;
    }
    @name(".Parkway") action Parkway() {
        Recluse();
        Millstone.BealCity.Pachuta = (bit<3>)3w3;
    }
    @name(".Palouse") action Palouse() {
        Millstone.Ocracoke.Heppner = (bit<1>)1w1;
    }
    @ternary(1) @disable_atomic_modify(1) @name(".Sespe") table Sespe {
        actions = {
            Arapahoe();
            Parkway();
            Palouse();
            Recluse();
        }
        key = {
            Jayton.Aniak.Albemarle    : exact @name("Aniak.Albemarle") ;
            Jayton.Aniak.Algodones    : exact @name("Aniak.Algodones") ;
            Jayton.Aniak.Buckeye      : exact @name("Aniak.Buckeye") ;
            Jayton.Aniak.Topanga      : exact @name("Aniak.Topanga") ;
            Millstone.BealCity.Pachuta: ternary @name("BealCity.Pachuta") ;
        }
        default_action = Palouse();
        size = 1024;
        requires_versioning = false;
    }
    apply {
        Sespe.apply();
    }
}

control Callao(inout Udall Jayton, inout Wildorado Millstone, in ingress_intrinsic_metadata_t Yerington, in ingress_intrinsic_metadata_from_parser_t Hearne, inout ingress_intrinsic_metadata_for_deparser_t Dushore, inout ingress_intrinsic_metadata_for_tm_t Belmore) {
    @name(".Wagener") DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) Wagener;
    @name(".Monrovia") action Monrovia(bit<8> Mendocino) {
        Wagener.count();
        Millstone.BealCity.Orrick = (bit<1>)1w1;
        Millstone.BealCity.Mendocino = Mendocino;
    }
    @name(".Rienzi") action Rienzi(bit<8> Mendocino, bit<1> Weatherby) {
        Wagener.count();
        Belmore.copy_to_cpu = (bit<1>)1w1;
        Millstone.BealCity.Mendocino = Mendocino;
        Millstone.Ocracoke.Weatherby = Weatherby;
    }
    @name(".Ambler") action Ambler() {
        Wagener.count();
        Millstone.Ocracoke.Weatherby = (bit<1>)1w1;
    }
    @name(".Noyack") action Olmitz() {
        Wagener.count();
        ;
    }
    @disable_atomic_modify(1) @name(".Orrick") table Orrick {
        actions = {
            Monrovia();
            Rienzi();
            Ambler();
            Olmitz();
            @defaultonly NoAction();
        }
        key = {
            Millstone.Ocracoke.Basic                                         : ternary @name("Ocracoke.Basic") ;
            Millstone.Ocracoke.Minto                                         : ternary @name("Ocracoke.Minto") ;
            Millstone.Ocracoke.Waubun                                        : ternary @name("Ocracoke.Waubun") ;
            Millstone.Ocracoke.Buckfield                                     : ternary @name("Ocracoke.Buckfield") ;
            Millstone.Ocracoke.Kearns                                        : ternary @name("Ocracoke.Kearns") ;
            Millstone.Ocracoke.Malinta                                       : ternary @name("Ocracoke.Malinta") ;
            Millstone.Livonia.Hueytown                                       : ternary @name("Livonia.Hueytown") ;
            Millstone.Ocracoke.Turkey                                        : ternary @name("Ocracoke.Turkey") ;
            Jayton.Boonsboro.isValid()                                       : ternary @name("Boonsboro") ;
            Jayton.Boonsboro.Lowes                                           : ternary @name("Boonsboro.Lowes") ;
            Millstone.Ocracoke.Etter                                         : ternary @name("Ocracoke.Etter") ;
            Millstone.Lynch.Armona                                           : ternary @name("Lynch.Armona") ;
            Millstone.Ocracoke.Norcatur                                      : ternary @name("Ocracoke.Norcatur") ;
            Millstone.BealCity.Ralls                                         : ternary @name("BealCity.Ralls") ;
            Millstone.BealCity.Pachuta                                       : ternary @name("BealCity.Pachuta") ;
            Millstone.Sanford.Armona & 128w0xffff0000000000000000000000000000: ternary @name("Sanford.Armona") ;
            Millstone.Ocracoke.Westhoff                                      : ternary @name("Ocracoke.Westhoff") ;
            Millstone.BealCity.Mendocino                                     : ternary @name("BealCity.Mendocino") ;
        }
        size = 512;
        counters = Wagener;
        requires_versioning = false;
        default_action = NoAction();
    }
    apply {
        Orrick.apply();
    }
}

control Baker(inout Udall Jayton, inout Wildorado Millstone, in ingress_intrinsic_metadata_t Yerington, in ingress_intrinsic_metadata_from_parser_t Hearne, inout ingress_intrinsic_metadata_for_deparser_t Dushore, inout ingress_intrinsic_metadata_for_tm_t Belmore) {
    @name(".Glenoma") action Glenoma(bit<9> Thurmond, QueueId_t Lauada) {
        Millstone.BealCity.Grabill = Millstone.Yerington.Blencoe;
        Belmore.ucast_egress_port = Thurmond;
        Belmore.qid = Lauada;
        Belmore.mcast_grp_a = 16w0;
    }
    @name(".RichBar") action RichBar(bit<9> Thurmond, QueueId_t Lauada) {
        Glenoma(Thurmond, Lauada);
        Millstone.BealCity.Raiford = (bit<1>)1w0;
    }
    @name(".Harding") action Harding(QueueId_t Nephi) {
        Millstone.BealCity.Grabill = Millstone.Yerington.Blencoe;
        Belmore.qid[4:3] = Nephi[4:3];
    }
    @name(".Tofte") action Tofte(QueueId_t Nephi) {
        Harding(Nephi);
        Millstone.BealCity.Raiford = (bit<1>)1w0;
    }
    @name(".Jerico") action Jerico(bit<9> Thurmond, QueueId_t Lauada) {
        Glenoma(Thurmond, Lauada);
        Millstone.BealCity.Raiford = (bit<1>)1w1;
    }
    @name(".Wabbaseka") action Wabbaseka(QueueId_t Nephi) {
        Harding(Nephi);
        Millstone.BealCity.Raiford = (bit<1>)1w1;
    }
    @name(".Clearmont") action Clearmont(bit<9> Thurmond, QueueId_t Lauada) {
        Jerico(Thurmond, Lauada);
        Millstone.Ocracoke.Higginson = (bit<12>)Jayton.Lindsborg[0].Findlay;
    }
    @name(".Ruffin") action Ruffin(QueueId_t Nephi) {
        Wabbaseka(Nephi);
        Millstone.Ocracoke.Higginson = (bit<12>)Jayton.Lindsborg[0].Findlay;
    }
    @disable_atomic_modify(1) @stage(6) @name(".Rochert") table Rochert {
        actions = {
            RichBar();
            Tofte();
            Jerico();
            Wabbaseka();
            Clearmont();
            Ruffin();
        }
        key = {
            Millstone.BealCity.Orrick    : exact @name("BealCity.Orrick") ;
            Millstone.Ocracoke.Delavan   : exact @name("Ocracoke.Delavan") ;
            Millstone.Livonia.Townville  : ternary @name("Livonia.Townville") ;
            Millstone.BealCity.Mendocino : ternary @name("BealCity.Mendocino") ;
            Millstone.Ocracoke.Bennet    : ternary @name("Ocracoke.Bennet") ;
            Jayton.Lindsborg[0].isValid(): ternary @name("Lindsborg[0]") ;
        }
        default_action = Wabbaseka(5w0);
        size = 512;
        requires_versioning = false;
    }
    @name(".Swanlake") Peoria() Swanlake;
    apply {
        switch (Rochert.apply().action_run) {
            RichBar: {
            }
            Jerico: {
            }
            Clearmont: {
            }
            default: {
                Swanlake.apply(Jayton, Millstone, Yerington, Hearne, Dushore, Belmore);
            }
        }

    }
}

control Geistown(inout Udall Jayton, inout Wildorado Millstone, in egress_intrinsic_metadata_t Millhaven, in egress_intrinsic_metadata_from_parser_t Lindy, inout egress_intrinsic_metadata_for_deparser_t Brady, inout egress_intrinsic_metadata_for_output_port_t Emden) {
    @name(".Skillman") action Skillman() {
    }
    @name(".Olcott") action Olcott() {
        Jayton.Lindsborg[0].setValid();
        Jayton.Lindsborg[0].Findlay = Millstone.BealCity.Findlay;
        Jayton.Lindsborg[0].Basic = (bit<16>)16w0x8100;
        Jayton.Lindsborg[0].Steger = Millstone.Readsboro.Wisdom;
        Jayton.Lindsborg[0].Quogue = Millstone.Readsboro.Quogue;
    }
    @ways(2) @disable_atomic_modify(1) @name(".Westoak") table Westoak {
        actions = {
            Skillman();
            Olcott();
        }
        key = {
            Millstone.BealCity.Findlay    : exact @name("BealCity.Findlay") ;
            Millhaven.egress_port & 9w0x7f: exact @name("Millhaven.Clarion") ;
            Millstone.BealCity.Bennet     : exact @name("BealCity.Bennet") ;
        }
        default_action = Olcott();
        size = 128;
    }
    apply {
        Westoak.apply();
    }
}

control Lefor(inout Udall Jayton, inout Wildorado Millstone, in ingress_intrinsic_metadata_t Yerington, in ingress_intrinsic_metadata_from_parser_t Hearne, inout ingress_intrinsic_metadata_for_deparser_t Dushore, inout ingress_intrinsic_metadata_for_tm_t Belmore) {
    @name(".Starkey") action Starkey(bit<9> Volens) {
        Belmore.level2_mcast_hash = (bit<13>)Millstone.Goodwin.Norma;
        Belmore.level2_exclusion_id = Volens;
    }
    @disable_atomic_modify(1) @stage(6) @name(".Ravinia") table Ravinia {
        actions = {
            Starkey();
        }
        key = {
            Millstone.Yerington.Blencoe: exact @name("Yerington.Blencoe") ;
        }
        default_action = Starkey(9w0);
        size = 512;
    }
    apply {
        Ravinia.apply();
    }
}

control Virgilina(inout Udall Jayton, inout Wildorado Millstone, in egress_intrinsic_metadata_t Millhaven, in egress_intrinsic_metadata_from_parser_t Lindy, inout egress_intrinsic_metadata_for_deparser_t Brady, inout egress_intrinsic_metadata_for_output_port_t Emden) {
    @name(".Dwight") Register<bit<1>, bit<32>>(32w294912, 1w0) Dwight;
    @name(".RockHill") RegisterAction<bit<1>, bit<32>, bit<1>>(Dwight) RockHill = {
        void apply(inout bit<1> Nooksack, out bit<1> Courtdale) {
            Courtdale = (bit<1>)1w0;
            bit<1> Swifton;
            Swifton = Nooksack;
            Nooksack = Swifton;
            Courtdale = ~Nooksack;
        }
    };
    @name(".Robstown.Allgood") Hash<bit<19>>(HashAlgorithm_t.IDENTITY) Robstown;
    @name(".Ponder") action Ponder() {
        bit<19> Neponset;
        Neponset = Robstown.get<tuple<bit<9>, bit<12>>>({ Millhaven.egress_port, (bit<12>)Millstone.BealCity.Ipava });
        Millstone.Westbury.Bells = RockHill.execute((bit<32>)Neponset);
    }
    @name(".Fishers") Register<bit<1>, bit<32>>(32w294912, 1w0) Fishers;
    @name(".Philip") RegisterAction<bit<1>, bit<32>, bit<1>>(Fishers) Philip = {
        void apply(inout bit<1> Nooksack, out bit<1> Courtdale) {
            Courtdale = (bit<1>)1w0;
            bit<1> Swifton;
            Swifton = Nooksack;
            Nooksack = Swifton;
            Courtdale = Nooksack;
        }
    };
    @name(".Levasy") action Levasy() {
        bit<19> Neponset;
        Neponset = Robstown.get<tuple<bit<9>, bit<12>>>({ Millhaven.egress_port, (bit<12>)Millstone.BealCity.Ipava });
        Millstone.Westbury.Corydon = Philip.execute((bit<32>)Neponset);
    }
    @disable_atomic_modify(1) @name(".Indios") table Indios {
        actions = {
            Ponder();
        }
        default_action = Ponder();
        size = 1;
    }
    @disable_atomic_modify(1) @name(".Larwill") table Larwill {
        actions = {
            Levasy();
        }
        default_action = Levasy();
        size = 1;
    }
    apply {
        Indios.apply();
        Larwill.apply();
    }
}

control Rhinebeck(inout Udall Jayton, inout Wildorado Millstone, in ingress_intrinsic_metadata_t Yerington, in ingress_intrinsic_metadata_from_parser_t Hearne, inout ingress_intrinsic_metadata_for_deparser_t Dushore, inout ingress_intrinsic_metadata_for_tm_t Belmore) {
    @name(".Chatanika") action Chatanika() {
        {
            {
                Jayton.Crannell.setValid();
            }
        }
    }
    @disable_atomic_modify(1) @stage(6) @name(".Boyle") table Boyle {
        actions = {
            Chatanika();
        }
        default_action = Chatanika();
        size = 1;
    }
    apply {
        Boyle.apply();
    }
}

@pa_solitary("ingress" , "Millstone.Ocracoke.Soledad")
@pa_solitary("ingress" , "Millstone.Ocracoke.Gasport")
@pa_solitary("ingress" , "Millstone.Ocracoke.Chatmoss")
@pa_solitary("ingress" , "Millstone.Ocracoke.NewMelle")
@pa_solitary("ingress" , "Millstone.Ocracoke.Randall")
@pa_solitary("ingress" , "Millstone.BealCity.McCammon")
@pa_solitary("ingress" , "ig_intr_md_for_tm.level2_exclusion_id")
@pa_solitary("ingress" , "ig_intr_md_for_tm.level2_mcast_hash")
@pa_solitary("ingress" , "Millstone.Ocracoke.Wartburg")
@pa_solitary("ingress" , "Millstone.Greenwood.Corydon")
@pa_solitary("ingress" , "Millstone.Greenwood.Bells")
@pa_solitary("ingress" , "Millstone.Ocracoke.Etter")
@pa_solitary("ingress" , "ig_intr_md_for_dprsr.drop_ctl")
@pa_solitary("ingress" , "ig_intr_md_for_tm.copy_to_cpu")
@pa_solitary("ingress" , "ig_intr_md_for_tm.bypass_egress")
@pa_solitary("ingress" , "ig_intr_md_for_tm.enable_mcast_cutthru")
@pa_solitary("ingress" , "Millstone.Ocracoke.Dyess")
@pa_solitary("egress" , "eg_intr_md_for_dprsr.drop_ctl")
@pa_solitary("egress" , "Millstone.Westbury.Bells")
@pa_solitary("egress" , "Millstone.BealCity.Findlay") control Ackerly(inout Udall Jayton, inout Wildorado Millstone, in ingress_intrinsic_metadata_t Yerington, in ingress_intrinsic_metadata_from_parser_t Hearne, inout ingress_intrinsic_metadata_for_deparser_t Dushore, inout ingress_intrinsic_metadata_for_tm_t Belmore) {
    @name(".Noyack") action Noyack() {
        ;
    }
    @name(".Hettinger") action Hettinger() {
        ;
    }
    @name(".Coryville") DirectMeter(MeterType_t.BYTES) Coryville;
    @name(".Bellamy") action Bellamy() {
        Millstone.Ocracoke.Dyess = (bit<1>)Coryville.execute();
        Belmore.enable_mcast_cutthru = (bit<1>)1w1;
        Belmore.mcast_grp_a = (bit<16>)Millstone.BealCity.Ipava;
    }
    @name(".Tularosa") action Tularosa() {
        Millstone.Ocracoke.Dyess = (bit<1>)Coryville.execute();
        Belmore.enable_mcast_cutthru = (bit<1>)1w1;
        Belmore.mcast_grp_a = (bit<16>)Millstone.BealCity.Ipava + 16w4096;
    }
    @name(".Uniopolis") action Uniopolis() {
        Millstone.Ocracoke.Dyess = (bit<1>)Coryville.execute();
        Belmore.enable_mcast_cutthru = (bit<1>)1w1;
        Belmore.mcast_grp_a = (bit<16>)Millstone.BealCity.Ipava;
    }
    @name(".Moosic") action Moosic(bit<20> Maumee) {
        Millstone.BealCity.McCammon = Maumee;
    }
    @name(".Ossining") action Ossining() {
        Millstone.Ocracoke.NewMelle = (bit<1>)1w1;
    }
    @disable_atomic_modify(1) @name(".Nason") table Nason {
        actions = {
            Bellamy();
            Tularosa();
            Uniopolis();
            @defaultonly NoAction();
        }
        key = {
            Millstone.Yerington.Blencoe & 9w0x7f: ternary @name("Yerington.Blencoe") ;
            Millstone.BealCity.Rains            : ternary @name("BealCity.Rains") ;
            Millstone.BealCity.SoapLake         : ternary @name("BealCity.SoapLake") ;
        }
        size = 512;
        requires_versioning = false;
        meters = Coryville;
        default_action = NoAction();
    }
    @disable_atomic_modify(1) @stage(0) @name(".Marquand") table Marquand {
        actions = {
            Moosic();
            Ossining();
            Hettinger();
        }
        key = {
            Millstone.BealCity.Rains   : exact @name("BealCity.Rains") ;
            Millstone.BealCity.SoapLake: exact @name("BealCity.SoapLake") ;
            Millstone.BealCity.Ipava   : exact @name("BealCity.Ipava") ;
        }
        default_action = Hettinger();
        size = 53248;
    }
    @name(".Kempton") DirectCounter<bit<64>>(CounterType_t.PACKETS) Kempton;
    @name(".GunnCity") action GunnCity() {
        Kempton.count();
        Millstone.Ocracoke.Randall = (bit<1>)1w1;
    }
    @name(".Hettinger") action Oneonta() {
        Kempton.count();
        ;
    }
    @name(".Sneads") action Sneads() {
        Millstone.Ocracoke.Chatmoss = (bit<1>)1w1;
    }
    @name(".Hemlock") action Hemlock() {
        Dushore.digest_type = (bit<3>)3w1;
    }
    @disable_atomic_modify(1) @name(".Mabana") table Mabana {
        actions = {
            GunnCity();
            Oneonta();
        }
        key = {
            Millstone.Yerington.Blencoe & 9w0x7f: exact @name("Yerington.Blencoe") ;
            Millstone.Ocracoke.Sheldahl         : ternary @name("Ocracoke.Sheldahl") ;
            Millstone.Ocracoke.Gasport          : ternary @name("Ocracoke.Gasport") ;
            Millstone.Ocracoke.Soledad          : ternary @name("Ocracoke.Soledad") ;
            Millstone.Dozier.Hulbert & 4w0x8    : ternary @name("Dozier.Hulbert") ;
            Millstone.Dozier.Wakita             : ternary @name("Dozier.Wakita") ;
        }
        default_action = Oneonta();
        size = 512;
        counters = Kempton;
        requires_versioning = false;
    }
    @disable_atomic_modify(1) @name(".Hester") table Hester {
        actions = {
            Sneads();
            Hettinger();
        }
        key = {
            Millstone.Ocracoke.Connell  : exact @name("Ocracoke.Connell") ;
            Millstone.Ocracoke.Cisco    : exact @name("Ocracoke.Cisco") ;
            Millstone.Ocracoke.Higginson: exact @name("Ocracoke.Higginson") ;
        }
        default_action = Hettinger();
        size = 4096;
    }
    @disable_atomic_modify(1) @name(".Goodlett") table Goodlett {
        actions = {
            Noyack();
            Hemlock();
        }
        key = {
            Millstone.Ocracoke.Connell  : exact @name("Ocracoke.Connell") ;
            Millstone.Ocracoke.Cisco    : exact @name("Ocracoke.Cisco") ;
            Millstone.Ocracoke.Higginson: exact @name("Ocracoke.Higginson") ;
            Millstone.Ocracoke.Oriskany : exact @name("Ocracoke.Oriskany") ;
        }
        default_action = Hemlock();
        size = 53248;
        idle_timeout = true;
    }
    @name(".BigPoint") DirectCounter<bit<16>>(CounterType_t.PACKETS_AND_BYTES) BigPoint;
    @name(".Tenstrike") action Tenstrike(bit<8> Mendocino, bit<1> Sublett) {
        BigPoint.count();
        Millstone.BealCity.Orrick = (bit<1>)1w1;
        Millstone.BealCity.Mendocino = Mendocino;
        Millstone.Ocracoke.Waubun = (bit<1>)1w1;
        Millstone.Readsboro.Sublett = Sublett;
        Millstone.Ocracoke.Onycha = (bit<1>)1w1;
    }
    @name(".Castle") action Castle() {
        BigPoint.count();
        Millstone.Ocracoke.Soledad = (bit<1>)1w1;
        Millstone.Ocracoke.Eastwood = (bit<1>)1w1;
    }
    @name(".Aguila") action Aguila() {
        BigPoint.count();
        Millstone.Ocracoke.Waubun = (bit<1>)1w1;
    }
    @name(".Nixon") action Nixon() {
        BigPoint.count();
    }
    @name(".Mattapex") action Mattapex() {
        BigPoint.count();
        Millstone.Ocracoke.Eastwood = (bit<1>)1w1;
    }
    @name(".Midas") action Midas() {
        BigPoint.count();
        Millstone.Ocracoke.Waubun = (bit<1>)1w1;
        Millstone.Ocracoke.Placedo = (bit<1>)1w1;
    }
    @name(".Kapowsin") action Kapowsin(bit<8> Mendocino, bit<1> Sublett) {
        BigPoint.count();
        Millstone.BealCity.Mendocino = Mendocino;
        Millstone.Ocracoke.Waubun = (bit<1>)1w1;
        Millstone.Readsboro.Sublett = Sublett;
    }
    @name(".Hettinger") action Crown() {
        BigPoint.count();
        ;
    }
    @name(".Vanoss") action Vanoss() {
        Millstone.Ocracoke.Gasport = (bit<1>)1w1;
    }
    @disable_atomic_modify(1) @name(".Potosi") table Potosi {
        actions = {
            Tenstrike();
            Castle();
            Aguila();
            Nixon();
            Mattapex();
            Midas();
            Kapowsin();
            Crown();
        }
        key = {
            Millstone.Yerington.Blencoe & 9w0x7f: exact @name("Yerington.Blencoe") ;
            Jayton.Nevis.Rains                  : ternary @name("Nevis.Rains") ;
            Jayton.Nevis.SoapLake               : ternary @name("Nevis.SoapLake") ;
        }
        default_action = Crown();
        size = 2048;
        counters = BigPoint;
        requires_versioning = false;
    }
    @disable_atomic_modify(1) @name(".Mulvane") table Mulvane {
        actions = {
            Vanoss();
            @defaultonly NoAction();
        }
        key = {
            Jayton.Nevis.Connell: ternary @name("Nevis.Connell") ;
            Jayton.Nevis.Cisco  : ternary @name("Nevis.Cisco") ;
        }
        size = 512;
        requires_versioning = false;
        default_action = NoAction();
    }
    @name(".Luning") DirectCounter<bit<64>>(CounterType_t.PACKETS) Luning;
    @name(".Flippen") action Flippen() {
        Luning.count();
    }
    @name(".Cadwell") action Cadwell(bit<8> Mendocino) {
        Luning.count();
    }
    @name(".Boring") action Boring() {
        Luning.count();
        Dushore.drop_ctl = (bit<3>)3w3;
    }
    @name(".Nucla") action Nucla() {
        Boring();
    }
    @name(".Tillson") action Tillson(bit<8> Mendocino) {
        Luning.count();
        Dushore.drop_ctl = (bit<3>)3w1;
    }
    @disable_atomic_modify(1) @stage(6) @name(".Micro") table Micro {
        actions = {
            Flippen();
            Cadwell();
            Nucla();
            Tillson();
            Boring();
        }
        key = {
            Millstone.Yerington.Blencoe & 9w0x7f: ternary @name("Yerington.Blencoe") ;
            Millstone.Ocracoke.Randall          : ternary @name("Ocracoke.Randall") ;
            Millstone.Ocracoke.Chatmoss         : ternary @name("Ocracoke.Chatmoss") ;
            Millstone.Ocracoke.NewMelle         : ternary @name("Ocracoke.NewMelle") ;
            Millstone.Ocracoke.Heppner          : ternary @name("Ocracoke.Heppner") ;
            Millstone.Ocracoke.Wartburg         : ternary @name("Ocracoke.Wartburg") ;
            Millstone.Readsboro.Lamona          : ternary @name("Readsboro.Lamona") ;
            Millstone.Ocracoke.Sledge           : ternary @name("Ocracoke.Sledge") ;
            Millstone.Ocracoke.Guadalupe & 3w0x4: ternary @name("Ocracoke.Guadalupe") ;
            Millstone.BealCity.McCammon         : ternary @name("BealCity.McCammon") ;
            Belmore.mcast_grp_a                 : ternary @name("Belmore.mcast_grp_a") ;
            Millstone.BealCity.Foster           : ternary @name("BealCity.Foster") ;
            Millstone.BealCity.Orrick           : ternary @name("BealCity.Orrick") ;
            Millstone.Ocracoke.Ambrose          : ternary @name("Ocracoke.Ambrose") ;
            Millstone.Greenwood.Corydon         : ternary @name("Greenwood.Corydon") ;
            Millstone.Greenwood.Bells           : ternary @name("Greenwood.Bells") ;
            Millstone.Ocracoke.Billings         : ternary @name("Ocracoke.Billings") ;
            Belmore.copy_to_cpu                 : ternary @name("Belmore.copy_to_cpu") ;
            Millstone.Ocracoke.Dyess            : ternary @name("Ocracoke.Dyess") ;
            Millstone.Ocracoke.Minto            : ternary @name("Ocracoke.Minto") ;
            Millstone.Ocracoke.Waubun           : ternary @name("Ocracoke.Waubun") ;
        }
        default_action = Flippen();
        size = 1536;
        counters = Luning;
        requires_versioning = false;
    }
    @name(".Lattimore") action Lattimore(bit<16> Salix, bit<1> Moose, bit<1> Minturn) {
        Belmore.mcast_grp_a = Salix;
        Belmore.enable_mcast_cutthru = (bit<1>)1w1;
    }
    @disable_atomic_modify(1) @name(".Cheyenne") table Cheyenne {
        actions = {
            Lattimore();
            Hettinger();
        }
        key = {
            Millstone.BealCity.Rains   : exact @name("BealCity.Rains") ;
            Millstone.BealCity.SoapLake: exact @name("BealCity.SoapLake") ;
            Millstone.BealCity.Ipava   : exact @name("BealCity.Ipava") ;
        }
        default_action = Hettinger();
        size = 16384;
    }
    @name(".Pacifica.Fabens") Hash<bit<16>>(HashAlgorithm_t.CRC16) Pacifica;
    @name(".Judson") action Judson() {
        Millstone.Goodwin.Norma = Pacifica.get<tuple<bit<24>, bit<24>, bit<24>, bit<24>, bit<16>>>({ Jayton.Nevis.Rains, Jayton.Nevis.SoapLake, Jayton.Nevis.Connell, Jayton.Nevis.Cisco, Millstone.Ocracoke.Basic });
    }
    @name(".Mogadore.Quebrada") Hash<bit<16>>(HashAlgorithm_t.CRC16) Mogadore;
    @name(".Westview") action Westview() {
        Millstone.Goodwin.Norma = Mogadore.get<tuple<bit<8>, bit<32>, bit<32>>>({ Jayton.Twain.Norcatur, Jayton.Twain.Petrey, Jayton.Twain.Armona });
    }
    @name(".Pimento") action Pimento() {
        Millstone.Goodwin.Norma = Millstone.Toluca.McAllen;
    }
    @name(".Campo") action Campo() {
        Millstone.Goodwin.Norma = Millstone.Toluca.Dairyland;
    }
    @name(".SanPablo") action SanPablo() {
        Millstone.Goodwin.Norma = Millstone.Toluca.Daleville;
    }
    @name(".Forepaugh") action Forepaugh() {
        Millstone.Goodwin.Norma = Millstone.Toluca.Basalt;
    }
    @disable_atomic_modify(1) @name(".Chewalla") table Chewalla {
        actions = {
            Judson();
            Westview();
            Pimento();
            Campo();
            SanPablo();
            Forepaugh();
            @defaultonly Hettinger();
        }
        key = {
            Jayton.Twain.isValid(): ternary @name("Twain") ;
            Jayton.Nevis.isValid(): ternary @name("Nevis") ;
        }
        default_action = Hettinger();
        size = 256;
        requires_versioning = false;
    }
    @name(".WildRose.Chaska") Hash<bit<20>>(HashAlgorithm_t.IDENTITY) WildRose;
    @name(".Kellner") action Kellner() {
        Millstone.Ocracoke.Oriskany = WildRose.get<tuple<bit<6>, bit<14>>>({ 6w0, Millstone.Livonia.Hueytown });
    }
    @disable_atomic_modify(1) @name(".Hagaman") table Hagaman {
        actions = {
            Kellner();
        }
        default_action = Kellner();
        size = 1;
    }
    @name(".McKenney") Halltown() McKenney;
    @name(".Decherd") Rhinebeck() Decherd;
    @name(".Bucklin") Dacono() Bucklin;
    @name(".Bernard") Lefor() Bernard;
    @name(".Owanka") Baker() Owanka;
    @name(".Natalia") Tabler() Natalia;
    @name(".Sunman") Callao() Sunman;
    apply {
        Belmore.bypass_egress = 1w1;
        Hagaman.apply();
        Natalia.apply(Jayton, Millstone, Yerington, Hearne, Dushore, Belmore);
        Chewalla.apply();
        if (Jayton.Aniak.isValid() == false) {
            Mulvane.apply();
            Hester.apply();
            switch (Potosi.apply().action_run) {
                Tenstrike: {
                }
                default: {
                    Bucklin.apply(Jayton, Millstone, Yerington, Hearne, Dushore, Belmore);
                }
            }

            switch (Marquand.apply().action_run) {
                Hettinger: {
                    Millstone.BealCity.McCammon = (bit<20>)20w511;
                    switch (Cheyenne.apply().action_run) {
                        Hettinger: {
                            Nason.apply();
                        }
                    }

                }
            }

            Sunman.apply(Jayton, Millstone, Yerington, Hearne, Dushore, Belmore);
            switch (Mabana.apply().action_run) {
                Oneonta: {
                    if (Millstone.Ocracoke.Onycha == 1w0) {
                        Goodlett.apply();
                    }
                }
            }

            if (Millstone.Ocracoke.Oriskany == Millstone.BealCity.McCammon) {
                Millstone.Ocracoke.Wartburg = 1w1;
            }
            Bernard.apply(Jayton, Millstone, Yerington, Hearne, Dushore, Belmore);
            Belmore.rid = (bit<16>)16w0;
        } else {
            McKenney.apply(Jayton, Millstone, Yerington, Hearne, Dushore, Belmore);
        }
        Micro.apply();
        Owanka.apply(Jayton, Millstone, Yerington, Hearne, Dushore, Belmore);
        if (Millstone.BealCity.Orrick == 1w1 || Belmore.copy_to_cpu == 1w1) {
            Decherd.apply(Jayton, Millstone, Yerington, Hearne, Dushore, Belmore);
            Belmore.bypass_egress = 1w0;
            Jayton.Lindsborg[0].setInvalid();
        }
    }
}

control FairOaks(inout Udall Jayton, inout Wildorado Millstone, in egress_intrinsic_metadata_t Millhaven, in egress_intrinsic_metadata_from_parser_t Lindy, inout egress_intrinsic_metadata_for_deparser_t Brady, inout egress_intrinsic_metadata_for_output_port_t Emden) {
    @name(".Baranof") action Baranof(bit<6> Anita, bit<10> Cairo, bit<4> Exeter, bit<12> Yulee) {
        Jayton.Aniak.Albemarle = Anita;
        Jayton.Aniak.Algodones = Cairo;
        Jayton.Aniak.Buckeye = Exeter;
        Jayton.Aniak.Topanga = Yulee;
        Jayton.Aniak.Garibaldi = (bit<1>)1w0;
        Jayton.Aniak.Mendocino = Millstone.BealCity.Mendocino;
        Jayton.Aniak.Chevak = Millstone.Ocracoke.Higginson;
        Jayton.Aniak.Allison = 2w0;
        Jayton.Aniak.Noyes = 4w0;
        Jayton.Aniak.Helton = Millstone.Ocracoke.Fairmount;
        Jayton.Aniak.Grannis = 16w0;
        Jayton.Aniak.Basic = 16w0xc000;
    }
    @disable_atomic_modify(1) @stage(6) @name(".Oconee") table Oconee {
        actions = {
            Baranof();
            @defaultonly NoAction();
        }
        key = {
            Millstone.BealCity.Grabill: exact @name("BealCity.Grabill") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".Salitpa") DirectCounter<bit<64>>(CounterType_t.PACKETS) Salitpa;
    @name(".Spanaway") action Spanaway() {
        Salitpa.count();
        Brady.drop_ctl = (bit<3>)3w7;
    }
    @name(".Hettinger") action Notus() {
        Salitpa.count();
        ;
    }
    @disable_atomic_modify(1) @stage(6) @name(".Dahlgren") table Dahlgren {
        actions = {
            Spanaway();
            Notus();
        }
        key = {
            Millhaven.egress_port & 9w0x7f: exact @name("Millhaven.Clarion") ;
            Millstone.Westbury.Corydon    : ternary @name("Westbury.Corydon") ;
            Millstone.Westbury.Bells      : ternary @name("Westbury.Bells") ;
        }
        default_action = Notus();
        size = 512;
        counters = Salitpa;
        requires_versioning = false;
    }
    @name(".Andrade") Virgilina() Andrade;
    @name(".McDonough") Geistown() McDonough;
    apply {
        if (Jayton.Aniak.isValid() == false) {
            Millstone.BealCity.Findlay = Millstone.BealCity.Ipava;
            Andrade.apply(Jayton, Millstone, Millhaven, Lindy, Brady, Emden);
            Dahlgren.apply();
            if (Millstone.BealCity.Pachuta != 3w2) {
                McDonough.apply(Jayton, Millstone, Millhaven, Lindy, Brady, Emden);
            }
        } else {
            Oconee.apply();
            Jayton.Aniak.Helton = Millstone.Ocracoke.Fairmount;
            Jayton.Aniak.Mendocino = Millstone.BealCity.Mendocino;
            Jayton.Aniak.Chevak = Millstone.Ocracoke.Higginson;
            if (Millstone.BealCity.Raiford == 1w1) {
                Jayton.Aniak.Spearman = 2w1;
            }
        }
    }
}

parser Ozona(packet_in Circle, out Udall Jayton, out Wildorado Millstone, out egress_intrinsic_metadata_t Millhaven) {
    @name(".Leland") value_set<bit<17>>(2) Leland;
    state start {
        Circle.extract<egress_intrinsic_metadata_t>(Millhaven);
        transition select(Millhaven.egress_port ++ (Circle.lookahead<Avondale>()).Glassboro) {
            Leland: Aynor;
            default: McIntyre;
        }
    }
    state Aynor {
        Jayton.Aniak.setValid();
        {
            Circle.extract(Jayton.Crannell);
        }
        transition accept;
    }
    state McIntyre {
        {
            Circle.extract(Jayton.Crannell);
        }
        transition Thawville;
    }
    state Thawville {
        Circle.extract<StarLake>(Jayton.Nevis);
        transition select((Circle.lookahead<bit<16>>())[15:0]) {
            16w0x8100: Basco;
            default: Millikin;
        }
    }
    state Basco {
        Circle.extract<Ledoux>(Jayton.Lindsborg[0]);
        transition Millikin;
    }
    state Millikin {
        Circle.extract<Linden>(Jayton.Magasco);
        transition accept;
    }
}

control Meyers(packet_out Circle, inout Udall Jayton, in Wildorado Millstone, in egress_intrinsic_metadata_for_deparser_t Brady) {
    apply {
        Circle.emit<Lacona>(Jayton.Aniak);
        Circle.emit<StarLake>(Jayton.Nevis);
        Circle.emit<Ledoux>(Jayton.Lindsborg[0]);
        Circle.emit<Linden>(Jayton.Magasco);
    }
}

@name(".pipe") Pipeline<Udall, Wildorado, Udall, Wildorado>(Picabo(), Ackerly(), Harriet(), Ozona(), FairOaks(), Meyers()) pipe;

@name(".main") Switch<Udall, Wildorado, Udall, Wildorado, _, _, _, _, _, _, _, _, _, _, _, _>(pipe) main;
