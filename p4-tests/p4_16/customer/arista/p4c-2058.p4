#include <core.p4>
#include <tofino.p4>
#include <tna.p4>       /* TOFINO1_ONLY */

struct Sagerton {
    bit<1>   Exell;
    bit<2>   Toccopola;
    PortId_t Roachdale;
    bit<48>  Miller;
}

struct Breese {
    bit<3> Churchill;
}

struct Waialua {
    bit<16> Arnold;
    bit<16> Wimberley;
    bit<8>  Wheaton;
    bit<8>  Dunedin;
    bit<8>  BigRiver;
    bit<8>  Sawyer;
    bit<4>  Iberia;
    bit<3>  Skime;
    bit<1>  Goldsboro;
    bit<3>  Fabens;
    bit<3>  CeeVee;
    bit<6>  Quebrada;
}

struct Haugan {
    bit<24>  Paisano;
    bit<24>  Boquillas;
    bit<24>  McCaulley;
    bit<24>  Everton;
    bit<16>  Lafayette;
    bit<12>  Roosville;
    bit<20>  Homeacre;
    bit<12>  Dixboro;
    bit<16>  Rayville;
    bit<8>   Rugby;
    bit<8>   Davie;
    bit<3>   Cacao;
    bit<3>   Mankato;
    bit<3>   Rockport;
    bit<1>   Union;
    bit<1>   Virgil;
    bit<1>   Florin;
    bit<1>   Requa;
    bit<1>   Sudbury;
    bit<1>   Allgood;
    bit<1>   Chaska;
    bit<1>   Selawik;
    bit<1>   Waipahu;
    bit<1>   Shabbona;
    bit<1>   Ronan;
    bit<1>   Anacortes;
    bit<1>   Corinth;
    bit<1>   Willard;
    bit<3>   Bayshore;
    bit<1>   Florien;
    bit<1>   Freeburg;
    bit<1>   Matheson;
    bit<1>   Uintah;
    bit<1>   Blitchton;
    bit<1>   Avondale;
    bit<1>   Glassboro;
    bit<1>   Grabill;
    bit<1>   Moorcroft;
    bit<1>   Toklat;
    bit<1>   Bledsoe;
    bit<1>   Blencoe;
    bit<1>   AquaPark;
    bit<1>   Vichy;
    bit<1>   Lathrop;
    bit<11>  Clyde;
    bit<11>  Clarion;
    bit<16>  Aguilita;
    bit<16>  Harbor;
    bit<8>   IttaBena;
    bit<2>   Adona;
    bit<2>   Connell;
    bit<1>   Cisco;
    bit<1>   Higginson;
    bit<16>  Oriskany;
    bit<16>  Bowden;
    bit<2>   Cabot;
    bit<16>  Keyes;
    bit<16>  Basic;
    bit<8>   Freeman;
    Sagerton Exton;
}

struct Floyd {
    bit<32> Fayette;
    bit<32> Osterdock;
    bit<32> PineCity;
    bit<6>  Alameda;
    bit<6>  Rexville;
    bit<16> Quinwood;
}

struct Marfa {
    bit<128> Fayette;
    bit<128> Osterdock;
    bit<8>   Palatine;
    bit<6>   Alameda;
    bit<16>  Quinwood;
}

struct Mabelle {
    bit<24> Paisano;
    bit<24> Boquillas;
    bit<1>  Hoagland;
    bit<3>  Ocoee;
    bit<1>  Hackett;
    bit<12> Kaluaaha;
    bit<20> Calcasieu;
    bit<16> Levittown;
    bit<16> Maryhill;
    bit<12> Norwood;
    bit<10> Dassel;
    bit<3>  Bushland;
    bit<8>  Loring;
    bit<1>  Suwannee;
    bit<32> Dugger;
    bit<32> Laurelton;
    bit<24> Ronda;
    bit<8>  LaPalma;
    bit<2>  Idalia;
    bit<32> Cecilton;
    bit<9>  Horton;
    bit<2>  Lacona;
    bit<1>  Albemarle;
    bit<1>  Algodones;
    bit<12> Roosville;
    bit<1>  Buckeye;
    bit<1>  Topanga;
    bit<1>  Allison;
    bit<32> Spearman;
    bit<32> Chevak;
    bit<8>  Mendocino;
    bit<24> Eldred;
    bit<24> Chloride;
    bit<2>  Garibaldi;
    bit<16> Weinert;
}

struct Cornell {
    bit<16> Noyes;
    bit<16> Helton;
    bit<16> Grannis;
    bit<16> StarLake;
    bit<16> Rains;
    bit<16> SoapLake;
}

struct Linden {
    bit<16> Conner;
    bit<16> Ledoux;
}

struct Steger {
    bit<32> Quogue;
}

struct Findlay {
    bit<14> Dowell;
    bit<12> Glendevey;
    bit<1>  Littleton;
    bit<2>  Killen;
}

struct Turkey {
    bit<14> Dowell;
    bit<12> Glendevey;
    bit<1>  Littleton;
    bit<2>  Riner;
}

struct Palmhurst {
    bit<2>  Comfrey;
    bit<15> Kalida;
    bit<15> Wallula;
    bit<2>  Dennison;
    bit<15> Fairhaven;
}

struct Woodfield {
    bit<8> LasVegas;
    bit<4> Westboro;
    bit<1> Newfane;
}

struct Norcatur {
    bit<2> Burrel;
    bit<6> Petrey;
    bit<3> Armona;
    bit<1> Dunstable;
    bit<1> Madawaska;
    bit<1> Hampton;
    bit<3> Tallassee;
    bit<1> Irvine;
    bit<6> Alameda;
    bit<6> Antlers;
    bit<4> Kendrick;
    bit<5> Solomon;
    bit<1> Garcia;
    bit<1> Coalwood;
    bit<1> Beasley;
    bit<2> Commack;
}

struct Bonney {
    bit<1> Pilar;
    bit<1> Loris;
}

struct Mackville {
    bit<16> Fayette;
    bit<16> Osterdock;
    bit<16> McBride;
    bit<16> Vinemont;
    bit<16> Aguilita;
    bit<16> Harbor;
    bit<8>  Kenbridge;
    bit<8>  Davie;
    bit<8>  Parkville;
    bit<8>  Mystic;
    bit<1>  Kearns;
    bit<6>  Alameda;
}

struct Malinta {
    bit<2> Blakeley;
}

struct Poulan {
    bit<16> Ramapo;
    bit<1>  Bicknell;
    bit<1>  Naruna;
}

struct Suttle {
    bit<16> Galloway;
}

struct Ankeny {
    bit<16> Ramapo;
    bit<1>  Bicknell;
    bit<1>  Naruna;
}

header Denhoff {
    bit<8> Provo;
    @flexible 
    bit<9> Horton;
}

struct Whitten {
    bit<10> Joslin;
    bit<10> Weyauwega;
    bit<2>  Powderly;
}

struct Welcome {
    bit<10> Joslin;
    bit<10> Weyauwega;
    bit<2>  Powderly;
    bit<8>  Teigen;
    bit<6>  Lowes;
    bit<16> Almedia;
    bit<4>  Chugwater;
    bit<4>  Charco;
}

struct Sutherlin {
    bit<1> Pilar;
    bit<1> Loris;
}

@pa_alias("ingress" , "Tombstone.Thayne.Quinwood" , "Tombstone.Parkland.Quinwood") @pa_alias("ingress" , "Tombstone.Tenino.Wallula" , "Tombstone.Tenino.Kalida") @pa_alias("ingress" , "Tombstone.Montross.Joslin" , "Tombstone.Montross.Weyauwega") @pa_alias("egress" , "Tombstone.Coulter.Chevak" , "Tombstone.Coulter.Cecilton") @pa_alias("egress" , "Tombstone.DonaAna.Joslin" , "Tombstone.DonaAna.Weyauwega") @pa_no_init("ingress" , "Tombstone.Coulter.Paisano") @pa_no_init("ingress" , "Tombstone.Coulter.Boquillas") @pa_no_init("ingress" , "Tombstone.Brinkman.Fayette") @pa_no_init("ingress" , "Tombstone.Brinkman.Osterdock") @pa_no_init("ingress" , "Tombstone.Brinkman.Aguilita") @pa_no_init("ingress" , "Tombstone.Brinkman.Harbor") @pa_no_init("ingress" , "Tombstone.Brinkman.Kenbridge") @pa_no_init("ingress" , "Tombstone.Brinkman.Alameda") @pa_no_init("ingress" , "Tombstone.Brinkman.Davie") @pa_no_init("ingress" , "Tombstone.Brinkman.Parkville") @pa_no_init("ingress" , "Tombstone.Brinkman.Kearns") @pa_no_init("ingress" , "Tombstone.ElVerano.McBride") @pa_no_init("ingress" , "Tombstone.ElVerano.Vinemont") @pa_no_init("ingress" , "Tombstone.Halaula.Conner") @pa_no_init("ingress" , "Tombstone.Halaula.Ledoux") @pa_no_init("ingress" , "Tombstone.Kapalua.Noyes") @pa_no_init("ingress" , "Tombstone.Kapalua.Helton") @pa_no_init("ingress" , "Tombstone.Kapalua.Grannis") @pa_no_init("ingress" , "Tombstone.Kapalua.StarLake") @pa_no_init("ingress" , "Tombstone.Kapalua.Rains") @pa_no_init("ingress" , "Tombstone.Kapalua.SoapLake") @pa_no_init("egress" , "Tombstone.Coulter.Spearman") @pa_no_init("egress" , "Tombstone.Coulter.Chevak") @pa_no_init("ingress" , "Tombstone.Alamosa.Ramapo") @pa_no_init("ingress" , "Tombstone.Knierim.Ramapo") @pa_no_init("ingress" , "Tombstone.Algoa.Paisano") @pa_no_init("ingress" , "Tombstone.Algoa.Boquillas") @pa_no_init("ingress" , "Tombstone.Algoa.McCaulley") @pa_no_init("ingress" , "Tombstone.Algoa.Everton") @pa_no_init("ingress" , "Tombstone.Algoa.Cacao") @pa_no_init("ingress" , "Tombstone.Algoa.Matheson") @pa_no_init("ingress" , "Tombstone.ElVerano.Fayette") @pa_no_init("ingress" , "Tombstone.ElVerano.Osterdock") @pa_no_init("ingress" , "Tombstone.Montross.Weyauwega") @pa_no_init("ingress" , "Tombstone.Coulter.Calcasieu") @pa_no_init("ingress" , "Tombstone.Coulter.Dassel") @pa_no_init("ingress" , "Tombstone.Juniata.Armona") @pa_no_init("ingress" , "Tombstone.Juniata.Petrey") @pa_no_init("ingress" , "Tombstone.Juniata.Burrel") @pa_no_init("ingress" , "Tombstone.Juniata.Tallassee") @pa_no_init("ingress" , "Tombstone.Juniata.Alameda") @pa_no_init("ingress" , "Tombstone.Coulter.Buckeye") @pa_no_init("ingress" , "Tombstone.Coulter.Horton") @pa_mutually_exclusive("ingress" , "Tombstone.Thayne.Osterdock" , "Tombstone.Parkland.Osterdock") @pa_mutually_exclusive("ingress" , "Pathfork.Brainard.Osterdock" , "Pathfork.Fristoe.Osterdock") @pa_mutually_exclusive("ingress" , "Tombstone.Thayne.Fayette" , "Tombstone.Parkland.Fayette") @pa_container_size("ingress" , "Tombstone.Parkland.Fayette" , 32) @pa_container_size("egress" , "Pathfork.Fristoe.Fayette" , 32) @pa_atomic("ingress" , "ig_intr_md_for_tm.mcast_grp_a") @pa_atomic("ingress" , "Tombstone.Tenino.Kalida") @pa_atomic("ingress" , "Tombstone.Tenino.Wallula") @pa_container_size("ingress" , "Tombstone.Tenino.Kalida" , 16) @pa_container_size("ingress" , "Tombstone.Tenino.Wallula" , 16) @pa_atomic("ingress" , "Tombstone.Kapalua.Grannis") @pa_atomic("ingress" , "Tombstone.Kapalua.SoapLake") @pa_atomic("ingress" , "Tombstone.Kapalua.Noyes") @pa_atomic("ingress" , "Tombstone.Kapalua.StarLake") @pa_atomic("ingress" , "Tombstone.Kapalua.Helton") @pa_atomic("ingress" , "Tombstone.Kapalua.Rains") @pa_atomic("ingress" , "Tombstone.Halaula.Ledoux") @pa_atomic("ingress" , "Tombstone.Halaula.Conner") struct Daphne {
    Waialua   Level;
    Haugan    Algoa;
    Floyd     Thayne;
    Marfa     Parkland;
    Mabelle   Coulter;
    Cornell   Kapalua;
    Linden    Halaula;
    Findlay   Uvalde;
    Palmhurst Tenino;
    Woodfield Pridgen;
    Bonney    Fairland;
    Norcatur  Juniata;
    Steger    Beaverdam;
    Mackville ElVerano;
    Mackville Brinkman;
    Malinta   Boerne;
    Poulan    Alamosa;
    Suttle    Elderon;
    Ankeny    Knierim;
    Whitten   Montross;
    Denhoff   Glenmora;
    Welcome   DonaAna;
    Sutherlin Altus;
    bit<3>    Churchill;
    Sagerton  Exton;
    Breese    Merrill;
}

@flexible struct Hickox {
    bit<24> McCaulley;
    bit<24> Everton;
    bit<12> Roosville;
    bit<20> Homeacre;
}

@flexible struct Tehachapi {
    bit<12>  Roosville;
    bit<24>  McCaulley;
    bit<24>  Everton;
    bit<32>  Sewaren;
    bit<128> WindGap;
    bit<16>  Lafayette;
    bit<24>  Caroleen;
    bit<8>   Lordstown;
}

header Belfair {
    bit<6>  Luzerne;
    bit<10> Devers;
    bit<4>  Crozet;
    bit<12> Laxon;
    bit<2>  Chaffee;
    bit<2>  Lacona;
    bit<12> Brinklow;
    bit<8>  Loring;
    bit<2>  Burrel;
    bit<3>  Kremlin;
    bit<1>  Allison;
    bit<2>  TroutRun;
}

header Bradner {
    bit<24> Paisano;
    bit<24> Boquillas;
    bit<24> McCaulley;
    bit<24> Everton;
    bit<16> Lafayette;
}

header Ravena {
    bit<16> Redden;
    bit<16> Yaurel;
    bit<8>  Bucktown;
    bit<8>  Hulbert;
    bit<16> Philbrook;
}

header Skyway {
    bit<1>  Rocklin;
    bit<1>  Wakita;
    bit<1>  Latham;
    bit<1>  Dandridge;
    bit<1>  Colona;
    bit<3>  Wilmore;
    bit<5>  Parkville;
    bit<3>  Piperton;
    bit<16> Kenbridge;
}

header Fairmount {
    bit<4>  Guadalupe;
    bit<4>  Buckfield;
    bit<6>  Alameda;
    bit<2>  Commack;
    bit<16> Rayville;
    bit<16> Weinert;
    bit<3>  Parkville;
    bit<13> Moquah;
    bit<8>  Davie;
    bit<8>  Rugby;
    bit<16> Forkville;
    bit<32> Fayette;
    bit<32> Osterdock;
}

header Mayday {
    bit<4>   Guadalupe;
    bit<6>   Alameda;
    bit<2>   Commack;
    bit<20>  Randall;
    bit<16>  Sheldahl;
    bit<8>   Palatine;
    bit<8>   Soledad;
    bit<128> Fayette;
    bit<128> Osterdock;
}

header Gasport {
    bit<16> Chatmoss;
}

header NewMelle {
    bit<16> Aguilita;
    bit<16> Harbor;
}

header Heppner {
    bit<32> Wartburg;
    bit<32> Lakehills;
    bit<4>  Sledge;
    bit<4>  Ambrose;
    bit<8>  Parkville;
    bit<16> Billings;
}

header Dyess {
    bit<16> Westhoff;
}

header Havana {
    bit<4>  Guadalupe;
    bit<6>  Alameda;
    bit<2>  Commack;
    bit<20> Randall;
    bit<16> Sheldahl;
    bit<8>  Palatine;
    bit<8>  Soledad;
    bit<32> Nenana;
    bit<32> Morstein;
    bit<32> Waubun;
    bit<32> Minto;
    bit<32> Eastwood;
    bit<32> Placedo;
    bit<32> Onycha;
    bit<32> Delavan;
}

header Bennet {
    bit<8>  Parkville;
    bit<24> Etter;
    bit<24> Caroleen;
    bit<8>  TroutRun;
}

header Jenners {
    bit<20> RockPort;
    bit<3>  Piqua;
    bit<1>  Stratford;
    bit<8>  Davie;
}

header RioPecos {
    bit<3>  Weatherby;
    bit<1>  Irvine;
    bit<12> Norwood;
    bit<16> Lafayette;
}

header DeGraff {
}

header Quinhagak {
    bit<8> Provo;
}

@pa_alias("ingress" , "Tombstone.Juniata.Irvine" , "Pathfork.Orrick.Edgemoor") @pa_alias("ingress" , "Tombstone.Juniata.Tallassee" , "Pathfork.Orrick.Ivyland") @pa_alias("egress" , "Tombstone.Juniata.Irvine" , "Pathfork.Orrick.Edgemoor") @pa_alias("egress" , "Tombstone.Juniata.Tallassee" , "Pathfork.Orrick.Ivyland") @pa_alias("ingress" , "Tombstone.Coulter.Loring" , "Pathfork.Orrick.Dolores") @pa_alias("egress" , "Tombstone.Coulter.Loring" , "Pathfork.Orrick.Dolores") @pa_alias("ingress" , "Tombstone.Coulter.Hoagland" , "Pathfork.Orrick.Atoka") @pa_alias("egress" , "Tombstone.Coulter.Hoagland" , "Pathfork.Orrick.Atoka") @pa_alias("ingress" , "Tombstone.Coulter.Bushland" , "Pathfork.Orrick.Panaca") @pa_alias("egress" , "Tombstone.Coulter.Bushland" , "Pathfork.Orrick.Panaca") @pa_alias("ingress" , "Tombstone.Coulter.Paisano" , "Pathfork.Orrick.Madera") @pa_alias("egress" , "Tombstone.Coulter.Paisano" , "Pathfork.Orrick.Madera") @pa_alias("ingress" , "Tombstone.Coulter.Boquillas" , "Pathfork.Orrick.Cardenas") @pa_alias("egress" , "Tombstone.Coulter.Boquillas" , "Pathfork.Orrick.Cardenas") @pa_alias("ingress" , "Tombstone.Coulter.Kaluaaha" , "Pathfork.Orrick.LakeLure") @pa_alias("egress" , "Tombstone.Coulter.Kaluaaha" , "Pathfork.Orrick.LakeLure") @pa_alias("ingress" , "Tombstone.Coulter.Ocoee" , "Pathfork.Orrick.Grassflat") @pa_alias("egress" , "Tombstone.Coulter.Ocoee" , "Pathfork.Orrick.Grassflat") @pa_alias("ingress" , "Tombstone.Coulter.Horton" , "Pathfork.Orrick.Whitewood") @pa_alias("egress" , "Tombstone.Coulter.Horton" , "Pathfork.Orrick.Whitewood") @pa_alias("ingress" , "Tombstone.Coulter.Garibaldi" , "Pathfork.Orrick.Tilton") @pa_alias("egress" , "Tombstone.Coulter.Garibaldi" , "Pathfork.Orrick.Tilton") @pa_alias("ingress" , "Tombstone.Coulter.Buckeye" , "Pathfork.Orrick.Wetonka") @pa_alias("egress" , "Tombstone.Coulter.Buckeye" , "Pathfork.Orrick.Wetonka") @pa_alias("ingress" , "Tombstone.Coulter.Albemarle" , "Pathfork.Orrick.Lecompte") @pa_alias("egress" , "Tombstone.Coulter.Albemarle" , "Pathfork.Orrick.Lecompte") @pa_alias("ingress" , "Tombstone.Coulter.Dugger" , "Pathfork.Orrick.Lenexa") @pa_alias("egress" , "Tombstone.Coulter.Dugger" , "Pathfork.Orrick.Lenexa") @pa_alias("ingress" , "Tombstone.Halaula.Conner" , "Pathfork.Orrick.Rudolph") @pa_alias("egress" , "Tombstone.Halaula.Conner" , "Pathfork.Orrick.Rudolph") @pa_alias("ingress" , "Tombstone.Merrill.Churchill" , "Pathfork.Orrick.Bufalo") @pa_alias("egress" , "Tombstone.Merrill.Churchill" , "Pathfork.Orrick.Bufalo") @pa_alias("ingress" , "Tombstone.Algoa.Roosville" , "Pathfork.Orrick.Rockham") @pa_alias("egress" , "Tombstone.Algoa.Roosville" , "Pathfork.Orrick.Rockham") @pa_alias("ingress" , "Tombstone.Algoa.Dixboro" , "Pathfork.Orrick.Hiland") @pa_alias("egress" , "Tombstone.Algoa.Dixboro" , "Pathfork.Orrick.Hiland") @pa_alias("egress" , "Tombstone.Uvalde.Littleton" , "Pathfork.Orrick.Manilla") @pa_alias("ingress" , "Tombstone.Juniata.Alameda" , "Pathfork.Orrick.Hammond") @pa_alias("egress" , "Tombstone.Juniata.Alameda" , "Pathfork.Orrick.Hammond") header Scarville {
    bit<8>  Provo;
    bit<3>  Ivyland;
    bit<1>  Edgemoor;
    bit<4>  Lovewell;
    @flexible 
    bit<8>  Dolores;
    @flexible 
    bit<1>  Atoka;
    @flexible 
    bit<3>  Panaca;
    @flexible 
    bit<24> Madera;
    @flexible 
    bit<24> Cardenas;
    @flexible 
    bit<12> LakeLure;
    @flexible 
    bit<3>  Grassflat;
    @flexible 
    bit<9>  Whitewood;
    @flexible 
    bit<2>  Tilton;
    @flexible 
    bit<1>  Wetonka;
    @flexible 
    bit<1>  Lecompte;
    @flexible 
    bit<32> Lenexa;
    @flexible 
    bit<16> Rudolph;
    @flexible 
    bit<3>  Bufalo;
    @flexible 
    bit<12> Rockham;
    @flexible 
    bit<12> Hiland;
    @flexible 
    bit<1>  Manilla;
    @flexible 
    bit<6>  Hammond;
}

struct Hematite {
    Scarville   Orrick;
    Belfair     Ipava;
    Bradner     McCammon;
    RioPecos[2] Lapoint;
    Ravena      Wamego;
    Fairmount   Brainard;
    Mayday      Fristoe;
    Havana      Traverse;
    Skyway      Pachuta;
    NewMelle    Whitefish;
    Dyess       Ralls;
    Heppner     Standish;
    Gasport     Blairsden;
    Bennet      Clover;
    Bradner     Barrow;
    Fairmount   Foster;
    Mayday      Raiford;
    NewMelle    Ayden;
    Heppner     Bonduel;
    Dyess       Sardinia;
    Gasport     Kaaawa;
}

parser Gause(packet_in Norland, out Hematite Pathfork, out Daphne Tombstone, out ingress_intrinsic_metadata_t Exton) {
    value_set<bit<9>>(2) Subiaco;
    state start {
        Norland.extract<ingress_intrinsic_metadata_t>(Exton);
        transition Marcus;
    }
    state Marcus {
        {
            Turkey Pittsboro = port_metadata_unpack<Turkey>(Norland);
            Tombstone.Uvalde.Dowell = Pittsboro.Dowell;
            Tombstone.Uvalde.Glendevey = Pittsboro.Glendevey;
            Tombstone.Uvalde.Littleton = Pittsboro.Littleton;
            Tombstone.Uvalde.Killen = Pittsboro.Riner;
            Tombstone.Exton.Roachdale = Exton.ingress_port;
        }
        transition select(Exton.ingress_port) {
            Subiaco: Ericsburg;
            default: Staunton;
        }
    }
    state Ericsburg {
        {
            Norland.advance(32w112);
        }
        Norland.extract<Belfair>(Pathfork.Ipava);
        transition Staunton;
    }
    state Staunton {
        Norland.extract<Bradner>(Pathfork.McCammon);
        transition select((Norland.lookahead<bit<8>>())[7:0], Pathfork.McCammon.Lafayette) {
            (8w0x0 &&& 8w0x0, 16w0x8100): Lugert;
            (8w0x0 &&& 8w0x0, 16w0x806): Goulds;
            (8w0x45, 16w0x800): McGrady;
            (8w0x5 &&& 8w0xf, 16w0x800): Peebles;
            (8w0x0 &&& 8w0x0, 16w0x800): Wellton;
            (8w0x60 &&& 8w0xf0, 16w0x86dd): Kenney;
            (8w0x0 &&& 8w0x0, 16w0x86dd): Montague;
            (8w0x0 &&& 8w0x0, 16w0x8808): Fredonia;
            default: accept;
        }
    }
    state Rocklake {
        Norland.extract<RioPecos>(Pathfork.Lapoint[1]);
        transition accept;
    }
    state Lugert {
        Norland.extract<RioPecos>(Pathfork.Lapoint[0]);
        transition select((Norland.lookahead<bit<8>>())[7:0], Pathfork.Lapoint[0].Lafayette) {
            (8w0x0 &&& 8w0x0, 16w0x806): Goulds;
            (8w0x45, 16w0x800): McGrady;
            (8w0x5 &&& 8w0xf, 16w0x800): Peebles;
            (8w0x0 &&& 8w0x0, 16w0x800): Wellton;
            (8w0x60 &&& 8w0xf0, 16w0x86dd): Kenney;
            (8w0x0 &&& 8w0x0, 16w0x86dd): Montague;
            (8w0 &&& 8w0, 16w0x8100): Rocklake;
            default: accept;
        }
    }
    state Goulds {
        transition select((Norland.lookahead<bit<32>>())[31:0]) {
            32w0x10800: LaConner;
            default: accept;
        }
    }
    state LaConner {
        Norland.extract<Ravena>(Pathfork.Wamego);
        transition accept;
    }
    state McGrady {
        Norland.extract<Fairmount>(Pathfork.Brainard);
        {
            Tombstone.Level.Wheaton = Pathfork.Brainard.Rugby;
            Tombstone.Algoa.Davie = Pathfork.Brainard.Davie;
            Tombstone.Level.Iberia = 4w0x1;
        }
        transition select(Pathfork.Brainard.Moquah, Pathfork.Brainard.Rugby) {
            (13w0, 8w1): Oilmont;
            (13w0, 8w17): Tornillo;
            (13w0, 8w6): Townville;
            (13w0, 8w47): Monahans;
            (13w0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): accept;
            (13w0 &&& 13w0x0, 8w6 &&& 8w0xff): Chavies;
            default: Miranda;
        }
    }
    state Pierceton {
        {
            Tombstone.Level.Skime = (bit<3>)3w0x5;
        }
        transition accept;
    }
    state LaLuz {
        {
            Tombstone.Level.Skime = (bit<3>)3w0x6;
        }
        transition accept;
    }
    state Peebles {
        {
            Tombstone.Level.Iberia = (bit<4>)4w0x5;
        }
        transition accept;
    }
    state Montague {
        {
            Tombstone.Level.Iberia = (bit<4>)4w0x6;
        }
        transition accept;
    }
    state Fredonia {
        {
            Tombstone.Level.Iberia = (bit<4>)4w0x8;
        }
        transition accept;
    }
    state Monahans {
        Norland.extract<Skyway>(Pathfork.Pachuta);
        transition select(Pathfork.Pachuta.Rocklin, Pathfork.Pachuta.Wakita, Pathfork.Pachuta.Latham, Pathfork.Pachuta.Dandridge, Pathfork.Pachuta.Colona, Pathfork.Pachuta.Wilmore, Pathfork.Pachuta.Parkville, Pathfork.Pachuta.Piperton, Pathfork.Pachuta.Kenbridge) {
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x800): Pinole;
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x86dd): Corydon;
            default: accept;
        }
    }
    state Bells {
        {
            Tombstone.Algoa.Rockport = (bit<3>)3w2;
        }
        transition select((Norland.lookahead<bit<8>>())[3:0]) {
            4w0x5: Renick;
            default: FortHunt;
        }
    }
    state Heuvelton {
        {
            Tombstone.Algoa.Rockport = (bit<3>)3w2;
        }
        transition Hueytown;
    }
    state Oilmont {
        transition accept;
    }
    state RedElm {
        Norland.extract<Bradner>(Pathfork.Barrow);
        {
            Tombstone.Algoa.Paisano = Pathfork.Barrow.Paisano;
            Tombstone.Algoa.Boquillas = Pathfork.Barrow.Boquillas;
            Tombstone.Algoa.Lafayette = Pathfork.Barrow.Lafayette;
        }
        transition select((Norland.lookahead<bit<8>>())[7:0], Pathfork.Barrow.Lafayette) {
            (8w0x0 &&& 8w0x0, 16w0x806): Goulds;
            (8w0x45, 16w0x800): Renick;
            (8w0x5 &&& 8w0xf, 16w0x800): Pierceton;
            (8w0x0 &&& 8w0x0, 16w0x800): FortHunt;
            (8w0x60 &&& 8w0xf0, 16w0x86dd): Hueytown;
            (8w0x0 &&& 8w0x0, 16w0x86dd): LaLuz;
            default: accept;
        }
    }
    state Pettry {
        Norland.extract<Bradner>(Pathfork.Barrow);
        {
            Tombstone.Algoa.Paisano = Pathfork.Barrow.Paisano;
            Tombstone.Algoa.Boquillas = Pathfork.Barrow.Boquillas;
            Tombstone.Algoa.Lafayette = Pathfork.Barrow.Lafayette;
        }
        transition select((Norland.lookahead<bit<8>>())[7:0], Pathfork.Barrow.Lafayette) {
            (8w0x0 &&& 8w0x0, 16w0x806): Goulds;
            (8w0x45, 16w0x800): Renick;
            (8w0x5 &&& 8w0xf, 16w0x800): Pierceton;
            (8w0x0 &&& 8w0x0, 16w0x800): FortHunt;
            default: accept;
        }
    }
    state Pajaros {
        {
            Tombstone.Algoa.Aguilita = (Norland.lookahead<bit<16>>())[15:0];
        }
        transition accept;
    }
    state Renick {
        Norland.extract<Fairmount>(Pathfork.Foster);
        {
            Tombstone.Level.Dunedin = Pathfork.Foster.Rugby;
            Tombstone.Level.Sawyer = Pathfork.Foster.Davie;
            Tombstone.Level.Skime = 3w0x1;
            Tombstone.Thayne.Fayette = Pathfork.Foster.Fayette;
            Tombstone.Thayne.Osterdock = Pathfork.Foster.Osterdock;
        }
        transition select(Pathfork.Foster.Moquah, Pathfork.Foster.Rugby) {
            (13w0, 8w1): Pajaros;
            (13w0, 8w17): Wauconda;
            (13w0, 8w6): Richvale;
            (13w0 &&& 13w0x1fff, 8w0 &&& 8w0x0): accept;
            (13w0 &&& 13w0x0, 8w6 &&& 8w0xff): SomesBar;
            default: Vergennes;
        }
    }
    state Pinole {
        transition select((Norland.lookahead<bit<4>>())[3:0]) {
            4w0x4: Bells;
            default: accept;
        }
    }
    state FortHunt {
        {
            Tombstone.Level.Skime = 3w0x3;
        }
        Pathfork.Foster.Alameda = (Norland.lookahead<bit<14>>())[5:0];
        transition accept;
    }
    state Hueytown {
        Norland.extract<Mayday>(Pathfork.Raiford);
        {
            Tombstone.Level.Dunedin = Pathfork.Raiford.Palatine;
            Tombstone.Level.Sawyer = Pathfork.Raiford.Soledad;
            Tombstone.Level.Skime = (bit<3>)3w0x2;
            Tombstone.Parkland.Fayette = Pathfork.Raiford.Fayette;
            Tombstone.Parkland.Osterdock = Pathfork.Raiford.Osterdock;
        }
        transition select(Pathfork.Raiford.Palatine) {
            8w0x3a: Pajaros;
            8w17: Wauconda;
            8w6: Richvale;
            default: accept;
        }
    }
    state Corydon {
        transition select((Norland.lookahead<bit<4>>())[3:0]) {
            4w0x6: Heuvelton;
            default: accept;
        }
    }
    state Richvale {
        {
            Tombstone.Algoa.Aguilita = (Norland.lookahead<bit<16>>())[15:0];
            Tombstone.Algoa.Harbor = (Norland.lookahead<bit<32>>())[15:0];
            Tombstone.Algoa.IttaBena = (Norland.lookahead<bit<112>>())[7:0];
            Tombstone.Level.Fabens = (bit<3>)3w6;
        }
        Norland.extract<NewMelle>(Pathfork.Ayden);
        Norland.extract<Heppner>(Pathfork.Bonduel);
        Norland.extract<Gasport>(Pathfork.Kaaawa);
        transition accept;
    }
    state Wauconda {
        {
            Tombstone.Algoa.Aguilita = (Norland.lookahead<bit<16>>())[15:0];
            Tombstone.Algoa.Harbor = (Norland.lookahead<bit<32>>())[15:0];
            Tombstone.Level.Fabens = (bit<3>)3w2;
        }
        Norland.extract<NewMelle>(Pathfork.Ayden);
        Norland.extract<Dyess>(Pathfork.Sardinia);
        Norland.extract<Gasport>(Pathfork.Kaaawa);
        transition accept;
    }
    state Wellton {
        Pathfork.Brainard.Osterdock = (Norland.lookahead<bit<160>>())[31:0];
        Pathfork.Brainard.Alameda = (Norland.lookahead<bit<14>>())[5:0];
        {
            Tombstone.Level.Iberia = (bit<4>)4w0x3;
            Tombstone.Level.Wheaton = (Norland.lookahead<bit<80>>())[7:0];
            Tombstone.Algoa.Davie = (Norland.lookahead<bit<72>>())[7:0];
        }
        transition accept;
    }
    state Tornillo {
        {
            Tombstone.Level.CeeVee = (bit<3>)3w2;
        }
        Norland.extract<NewMelle>(Pathfork.Whitefish);
        Norland.extract<Dyess>(Pathfork.Ralls);
        Norland.extract<Gasport>(Pathfork.Blairsden);
        transition select(Pathfork.Whitefish.Harbor) {
            16w4789: Satolah;
            16w65330: Satolah;
            default: accept;
        }
    }
    state Kenney {
        Norland.extract<Mayday>(Pathfork.Fristoe);
        {
            Tombstone.Level.Wheaton = Pathfork.Fristoe.Palatine;
            Tombstone.Algoa.Davie = Pathfork.Fristoe.Soledad;
            Tombstone.Level.Iberia = (bit<4>)4w0x2;
        }
        transition select(Pathfork.Fristoe.Palatine) {
            8w0x3a: Oilmont;
            8w17: Crestone;
            8w6: Townville;
            default: accept;
        }
    }
    state Crestone {
        {
            Tombstone.Level.CeeVee = (bit<3>)3w2;
        }
        Norland.extract<NewMelle>(Pathfork.Whitefish);
        Norland.extract<Dyess>(Pathfork.Ralls);
        Norland.extract<Gasport>(Pathfork.Blairsden);
        transition select(Pathfork.Whitefish.Harbor) {
            16w4789: Buncombe;
            default: accept;
        }
    }
    state Buncombe {
        Norland.extract<Bennet>(Pathfork.Clover);
        {
            Tombstone.Algoa.Rockport = (bit<3>)3w1;
        }
        transition Pettry;
    }
    state Townville {
        {
            Tombstone.Level.CeeVee = (bit<3>)3w6;
        }
        Norland.extract<NewMelle>(Pathfork.Whitefish);
        Norland.extract<Heppner>(Pathfork.Standish);
        Norland.extract<Gasport>(Pathfork.Blairsden);
        transition accept;
    }
    state Satolah {
        Tombstone.Algoa.Basic = (Norland.lookahead<bit<48>>())[15:0];
        Tombstone.Algoa.Freeman = (Norland.lookahead<bit<56>>())[7:0];
        Norland.extract<Bennet>(Pathfork.Clover);
        {
            Tombstone.Algoa.Rockport = (bit<3>)3w1;
        }
        transition RedElm;
    }
    state Miranda {
        {
            Tombstone.Level.CeeVee = (bit<3>)3w1;
        }
        transition accept;
    }
    state Vergennes {
        {
            Tombstone.Level.Fabens = (bit<3>)3w1;
        }
        transition accept;
    }
    state SomesBar {
        {
            Tombstone.Level.Fabens = (bit<3>)3w5;
        }
        transition accept;
    }
    state Chavies {
        {
            Tombstone.Level.CeeVee = (bit<3>)3w5;
        }
        transition accept;
    }
}

control Stilwell(packet_out Norland, inout Hematite Pathfork, in Daphne Tombstone, in ingress_intrinsic_metadata_for_deparser_t LaUnion) {
    Mirror() Cuprum;
    Digest<Hickox>() Belview;
    Digest<Tehachapi>() Broussard;
    apply {
        {
            if (LaUnion.mirror_type == 3w1) {
                Cuprum.emit<Denhoff>(Tombstone.Montross.Joslin, Tombstone.Glenmora);
            }
        }
        {
            if (LaUnion.digest_type == 3w2) {
                Belview.pack({ Tombstone.Algoa.McCaulley, Tombstone.Algoa.Everton, Tombstone.Algoa.Roosville, Tombstone.Algoa.Homeacre });
            }
            else 
                if (LaUnion.digest_type == 3w3) {
                    Broussard.pack({ Tombstone.Algoa.Roosville, Pathfork.Barrow.McCaulley, Pathfork.Barrow.Everton, Pathfork.Brainard.Fayette, Pathfork.Fristoe.Fayette, Pathfork.McCammon.Lafayette, Pathfork.Clover.Caroleen, Pathfork.Clover.TroutRun });
                }
        }
        Norland.emit<Hematite>(Pathfork);
    }
}

Register<bit<1>, bit<32>>(32w294912, 1w0) Arvada;

Register<bit<1>, bit<32>>(32w294912, 1w0) Kalkaska;

control Newfolden(inout Hematite Pathfork, inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton) {
    RegisterAction<bit<1>, bit<32>, bit<1>>(Arvada) Candle = {
        void apply(inout bit<1> Ackley, out bit<1> Knoke) {
            Knoke = (bit<1>)1w0;
            bit<1> McAllen;
            McAllen = Ackley;
            Ackley = McAllen;
            Knoke = Ackley;
        }
    };
    RegisterAction<bit<1>, bit<32>, bit<1>>(Kalkaska) Dairyland = {
        void apply(inout bit<1> Ackley, out bit<1> Knoke) {
            Knoke = (bit<1>)1w0;
            bit<1> McAllen;
            McAllen = Ackley;
            Ackley = McAllen;
            Knoke = ~Ackley;
        }
    };
    Hash<bit<19>>(HashAlgorithm_t.IDENTITY) Daleville;
    action Basalt() {
        {
            bit<19> Darien;
            Darien = Daleville.get<tuple<bit<9>, bit<12>>>({ Tombstone.Exton.Roachdale, Pathfork.Lapoint[0].Norwood });
            Tombstone.Fairland.Loris = Candle.execute((bit<32>)Darien);
        }
    }
    action Norma() {
        {
            bit<19> SourLake;
            SourLake = Daleville.get<tuple<bit<9>, bit<12>>>({ Tombstone.Exton.Roachdale, Pathfork.Lapoint[0].Norwood });
            Tombstone.Fairland.Pilar = Dairyland.execute((bit<32>)SourLake);
        }
    }
    table Juneau {
        actions = {
            Basalt();
        }
        size = 1;
        default_action = Basalt();
    }
    table Sunflower {
        actions = {
            Norma();
        }
        size = 1;
        default_action = Norma();
    }
    apply {
        if (Pathfork.Lapoint[0].isValid() && Pathfork.Lapoint[0].Norwood != 12w0 && Tombstone.Uvalde.Littleton == 1w1) {
            Sunflower.apply();
        }
        Juneau.apply();
    }
}

control Aldan(inout Hematite Pathfork, inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton) {
    DirectCounter<bit<16>>(CounterType_t.PACKETS_AND_BYTES) RossFork;
    action Maddock() {
        ;
    }
    action Sublett() {
        Tombstone.Algoa.Requa = (bit<1>)1w1;
    }
    action Wisdom(bit<8> Loring, bit<1> Hampton) {
        RossFork.count();
        Tombstone.Coulter.Hackett = (bit<1>)1w1;
        Tombstone.Coulter.Loring = Loring;
        Tombstone.Algoa.Avondale = (bit<1>)1w1;
        Tombstone.Juniata.Hampton = Hampton;
        Tombstone.Algoa.Toklat = (bit<1>)1w1;
    }
    action Cutten() {
        RossFork.count();
        Tombstone.Algoa.Florin = (bit<1>)1w1;
        Tombstone.Algoa.Grabill = (bit<1>)1w1;
    }
    action Lewiston() {
        RossFork.count();
        Tombstone.Algoa.Avondale = (bit<1>)1w1;
    }
    action Lamona() {
        RossFork.count();
        Tombstone.Algoa.Glassboro = (bit<1>)1w1;
    }
    action Naubinway() {
        RossFork.count();
        Tombstone.Algoa.Grabill = (bit<1>)1w1;
    }
    action Ovett() {
        RossFork.count();
        Tombstone.Algoa.Avondale = (bit<1>)1w1;
        Tombstone.Algoa.Moorcroft = (bit<1>)1w1;
    }
    action Murphy(bit<8> Loring, bit<1> Hampton) {
        RossFork.count();
        Tombstone.Coulter.Loring = Loring;
        Tombstone.Algoa.Avondale = (bit<1>)1w1;
        Tombstone.Juniata.Hampton = Hampton;
    }
    table Edwards {
        actions = {
            Wisdom();
            Cutten();
            Lewiston();
            Lamona();
            Naubinway();
            Ovett();
            Murphy();
            @defaultonly Maddock();
        }
        key = {
            Tombstone.Exton.Roachdale & 9w0x7f: exact;
            Pathfork.McCammon.Paisano         : ternary;
            Pathfork.McCammon.Boquillas       : ternary;
        }
        size = 1656;
        default_action = Maddock();
        counters = RossFork;
    }
    table Mausdale {
        actions = {
            Sublett();
            @defaultonly NoAction();
        }
        key = {
            Pathfork.McCammon.McCaulley: ternary;
            Pathfork.McCammon.Everton  : ternary;
        }
        size = 512;
        default_action = NoAction();
    }
    Newfolden() Bessie;
    apply {
        switch (Edwards.apply().action_run) {
            Wisdom: {
            }
            default: {
                Bessie.apply(Pathfork, Tombstone, Exton);
            }
        }

        Mausdale.apply();
    }
}

control Savery(inout Hematite Pathfork, inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton) {
    action Quinault(bit<20> Komatke) {
        Tombstone.Algoa.Roosville = Tombstone.Uvalde.Glendevey;
        Tombstone.Algoa.Homeacre = Komatke;
    }
    action Salix(bit<12> Moose, bit<20> Komatke) {
        Tombstone.Algoa.Roosville = Moose;
        Tombstone.Algoa.Homeacre = Komatke;
    }
    action Minturn(bit<20> Komatke) {
        Tombstone.Algoa.Roosville = Pathfork.Lapoint[0].Norwood;
        Tombstone.Algoa.Homeacre = Komatke;
    }
    action McCaskill(bit<32> Stennett, bit<8> LasVegas, bit<4> Westboro) {
        Tombstone.Pridgen.LasVegas = LasVegas;
        Tombstone.Thayne.PineCity = Stennett;
        Tombstone.Pridgen.Westboro = Westboro;
    }
    action McGonigle(bit<32> Stennett, bit<8> LasVegas, bit<4> Westboro, bit<16> Sherack) {
        Tombstone.Algoa.Dixboro = Pathfork.Lapoint[0].Norwood;
        McCaskill(Stennett, LasVegas, Westboro);
    }
    action Plains(bit<12> Moose, bit<32> Stennett, bit<8> LasVegas, bit<4> Westboro, bit<16> Sherack) {
        Tombstone.Algoa.Dixboro = Moose;
        McCaskill(Stennett, LasVegas, Westboro);
    }
    action Maddock() {
        ;
    }
    action Amenia() {
        Tombstone.ElVerano.Aguilita = Pathfork.Whitefish.Aguilita;
        Tombstone.ElVerano.Kearns[0:0] = ((bit<1>)Tombstone.Level.CeeVee)[0:0];
    }
    action Tiburon() {
        Tombstone.ElVerano.Aguilita = Tombstone.Algoa.Aguilita;
        Tombstone.ElVerano.Kearns[0:0] = ((bit<1>)Tombstone.Level.Fabens)[0:0];
    }
    action Freeny() {
        Tombstone.Algoa.McCaulley = Pathfork.Barrow.McCaulley;
        Tombstone.Algoa.Everton = Pathfork.Barrow.Everton;
        Tombstone.Algoa.Rugby = Tombstone.Level.Dunedin;
        Tombstone.Algoa.Davie = Tombstone.Level.Sawyer;
        Tombstone.Algoa.Cacao[2:0] = Tombstone.Level.Skime[2:0];
        Tombstone.Coulter.Bushland = 3w1;
        Tombstone.Algoa.Mankato = Tombstone.Level.Fabens;
        Tiburon();
    }
    action Sonoma() {
        Tombstone.Juniata.Irvine = Pathfork.Lapoint[0].Irvine;
        Tombstone.Algoa.Bledsoe = (bit<1>)Pathfork.Lapoint[0].isValid();
        Tombstone.Algoa.Rockport = (bit<3>)3w0;
        Tombstone.Algoa.Paisano = Pathfork.McCammon.Paisano;
        Tombstone.Algoa.Boquillas = Pathfork.McCammon.Boquillas;
        Tombstone.Algoa.McCaulley = Pathfork.McCammon.McCaulley;
        Tombstone.Algoa.Everton = Pathfork.McCammon.Everton;
        Tombstone.Algoa.Cacao[2:0] = ((bit<3>)Tombstone.Level.Iberia)[2:0];
        Tombstone.Algoa.Lafayette = Pathfork.McCammon.Lafayette;
    }
    action Burwell() {
        Tombstone.Algoa.Aguilita = Pathfork.Whitefish.Aguilita;
        Tombstone.Algoa.Harbor = Pathfork.Whitefish.Harbor;
        Tombstone.Algoa.IttaBena = Pathfork.Standish.Parkville;
        Tombstone.Algoa.Mankato = Tombstone.Level.CeeVee;
        Amenia();
    }
    action Belgrade() {
        Sonoma();
        Tombstone.Parkland.Fayette = Pathfork.Fristoe.Fayette;
        Tombstone.Thayne.Osterdock = Pathfork.Brainard.Osterdock;
        Tombstone.Thayne.Alameda = Pathfork.Brainard.Alameda;
        Tombstone.Algoa.Rugby = Pathfork.Fristoe.Palatine;
        Burwell();
    }
    action Hayfield() {
        Sonoma();
        Tombstone.Thayne.Fayette = Pathfork.Brainard.Fayette;
        Tombstone.Thayne.Osterdock = Pathfork.Brainard.Osterdock;
        Tombstone.Thayne.Alameda = Pathfork.Brainard.Alameda;
        Tombstone.Algoa.Rugby = Pathfork.Brainard.Rugby;
        Burwell();
    }
    action Calabash(bit<32> Stennett, bit<8> LasVegas, bit<4> Westboro, bit<16> Sherack) {
        Tombstone.Algoa.Dixboro = Tombstone.Uvalde.Glendevey;
        McCaskill(Stennett, LasVegas, Westboro);
    }
    action Wondervu(bit<20> Homeacre) {
        Tombstone.Algoa.Homeacre = Homeacre;
    }
    action GlenAvon() {
        Tombstone.Boerne.Blakeley = 2w3;
    }
    action Maumee() {
        Tombstone.Boerne.Blakeley = 2w1;
    }
    action Broadwell(bit<12> Norwood, bit<32> Stennett, bit<8> LasVegas, bit<4> Westboro) {
        Tombstone.Algoa.Roosville = Norwood;
        Tombstone.Algoa.Dixboro = Norwood;
        McCaskill(Stennett, LasVegas, Westboro);
    }
    action Grays() {
        Tombstone.Algoa.Virgil = (bit<1>)1w1;
    }
    table Gotham {
        actions = {
            Quinault();
            Salix();
            Minturn();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Uvalde.Dowell      : exact;
            Pathfork.Lapoint[0].isValid(): exact;
            Pathfork.Lapoint[0].Norwood  : ternary;
        }
        size = 3072;
        default_action = NoAction();
    }
    table Osyka {
        actions = {
            McGonigle();
            @defaultonly NoAction();
        }
        key = {
            Pathfork.Lapoint[0].Norwood: exact;
        }
        size = 16;
        default_action = NoAction();
    }
    table Brookneal {
        actions = {
            Plains();
            Maddock();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Uvalde.Dowell    : exact;
            Pathfork.Lapoint[0].Norwood: exact;
        }
        size = 16;
        default_action = NoAction();
    }
    table Hoven {
        actions = {
            Freeny();
            Belgrade();
            Hayfield();
        }
        key = {
            Pathfork.McCammon.Paisano  : ternary;
            Pathfork.McCammon.Boquillas: ternary;
            Pathfork.Brainard.Osterdock: ternary;
            Pathfork.Fristoe.Osterdock : ternary;
            Tombstone.Algoa.Rockport   : ternary;
            Pathfork.Fristoe.isValid() : exact;
        }
        size = 512;
        default_action = Hayfield();
    }
    table Shirley {
        actions = {
            Calabash();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Uvalde.Glendevey: exact;
        }
        size = 16;
        default_action = NoAction();
    }
    table Ramos {
        actions = {
            Wondervu();
            GlenAvon();
            Maumee();
        }
        key = {
            Pathfork.Fristoe.Fayette: exact;
        }
        size = 4096;
        default_action = GlenAvon();
    }
    table Provencal {
        actions = {
            Wondervu();
            GlenAvon();
            Maumee();
        }
        key = {
            Pathfork.Brainard.Fayette: exact;
        }
        size = 4096;
        default_action = GlenAvon();
    }
    table Bergton {
        actions = {
            Broadwell();
            Grays();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Algoa.Freeman : exact;
            Tombstone.Algoa.Basic   : exact;
            Tombstone.Algoa.Rockport: exact;
        }
        size = 4096;
        default_action = NoAction();
    }
    apply {
        switch (Hoven.apply().action_run) {
            Freeny: {
                if (Pathfork.Brainard.isValid()) {
                    Provencal.apply();
                }
                else {
                    Ramos.apply();
                }
                Bergton.apply();
            }
            default: {
                if (Tombstone.Uvalde.Littleton == 1w1) {
                    Gotham.apply();
                }
                if (Pathfork.Lapoint[0].isValid() && Pathfork.Lapoint[0].Norwood != 12w0) {
                    switch (Brookneal.apply().action_run) {
                        Maddock: {
                            Osyka.apply();
                        }
                    }

                }
                else {
                    Shirley.apply();
                }
            }
        }

    }
}

control Cassa(inout Hematite Pathfork, inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton) {
    action Pawtucket(bit<8> Mystic, bit<32> Buckhorn) {
        Tombstone.Beaverdam.Quogue[15:0] = Buckhorn[15:0];
        Tombstone.ElVerano.Mystic = Mystic;
    }
    action Maddock() {
        ;
    }
    action Rainelle(bit<8> Mystic, bit<32> Buckhorn) {
        Tombstone.Beaverdam.Quogue[15:0] = Buckhorn[15:0];
        Tombstone.ElVerano.Mystic = Mystic;
        Tombstone.Algoa.Higginson = (bit<1>)1w1;
    }
    action Paulding(bit<16> Millston) {
        Tombstone.ElVerano.Harbor = Millston;
    }
    action HillTop(bit<16> Millston, bit<16> Dateland) {
        Tombstone.ElVerano.Osterdock = Millston;
        Tombstone.ElVerano.Vinemont = Dateland;
    }
    action Doddridge() {
        Tombstone.Algoa.Uintah = (bit<1>)1w1;
    }
    action Emida() {
        Tombstone.Algoa.Matheson = (bit<1>)1w0;
        Tombstone.ElVerano.Kenbridge = Tombstone.Algoa.Rugby;
        Tombstone.ElVerano.Alameda = Tombstone.Thayne.Alameda;
        Tombstone.ElVerano.Davie = Tombstone.Algoa.Davie;
        Tombstone.ElVerano.Parkville = Tombstone.Algoa.IttaBena;
    }
    action Sopris(bit<16> Millston, bit<16> Dateland) {
        Emida();
        Tombstone.ElVerano.Fayette = Millston;
        Tombstone.ElVerano.McBride = Dateland;
    }
    action Thaxton() {
        Tombstone.Algoa.Matheson = 1w1;
    }
    action Lawai() {
        Tombstone.Algoa.Matheson = (bit<1>)1w0;
        Tombstone.ElVerano.Kenbridge = Tombstone.Algoa.Rugby;
        Tombstone.ElVerano.Alameda = Tombstone.Parkland.Alameda;
        Tombstone.ElVerano.Davie = Tombstone.Algoa.Davie;
        Tombstone.ElVerano.Parkville = Tombstone.Algoa.IttaBena;
    }
    action McCracken(bit<16> Millston, bit<16> Dateland) {
        Lawai();
        Tombstone.ElVerano.Fayette = Millston;
        Tombstone.ElVerano.McBride = Dateland;
    }
    action LaMoille(bit<16> Millston) {
        Tombstone.ElVerano.Aguilita = Millston;
    }
    table Guion {
        actions = {
            Pawtucket();
            Maddock();
        }
        key = {
            Tombstone.Algoa.Cacao & 3w0x3     : exact;
            Tombstone.Exton.Roachdale & 9w0x7f: exact;
        }
        size = 512;
        default_action = Maddock();
    }
    table ElkNeck {
        actions = {
            Rainelle();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Algoa.Cacao & 3w0x3: exact;
            Tombstone.Algoa.Dixboro      : exact;
        }
        size = 8192;
        default_action = NoAction();
    }
    table Nuyaka {
        actions = {
            Paulding();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Algoa.Harbor: ternary;
        }
        size = 1024;
        default_action = NoAction();
    }
    table Mickleton {
        actions = {
            HillTop();
            Doddridge();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Thayne.Osterdock: ternary;
        }
        size = 512;
        default_action = NoAction();
    }
    table Mentone {
        actions = {
            Sopris();
            Thaxton();
            @defaultonly Emida();
        }
        key = {
            Tombstone.Thayne.Fayette: ternary;
        }
        size = 2048;
        default_action = Emida();
    }
    table Elvaston {
        actions = {
            HillTop();
            Doddridge();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Parkland.Osterdock: ternary;
        }
        size = 512;
        default_action = NoAction();
    }
    table Elkville {
        actions = {
            McCracken();
            Thaxton();
            @defaultonly Lawai();
        }
        key = {
            Tombstone.Parkland.Fayette: ternary;
        }
        size = 1024;
        default_action = Lawai();
    }
    table Corvallis {
        actions = {
            LaMoille();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Algoa.Aguilita: ternary;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (Tombstone.Algoa.Cacao == 3w0x1) {
            Mentone.apply();
            Mickleton.apply();
        }
        else {
            if (Tombstone.Algoa.Cacao == 3w0x2) {
                Elkville.apply();
                Elvaston.apply();
            }
        }
        if (Tombstone.Algoa.Mankato & 3w2 == 3w2) {
            Corvallis.apply();
            Nuyaka.apply();
        }
        if (Tombstone.Coulter.Bushland == 3w0) {
            switch (Guion.apply().action_run) {
                Maddock: {
                    ElkNeck.apply();
                }
            }

        }
        else {
            ElkNeck.apply();
        }
    }
}

control Bridger(inout Hematite Pathfork, inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton, in ingress_intrinsic_metadata_from_parser_t Belmont) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS) Baytown;
    action Maddock() {
        ;
    }
    action McBrides() {
        ;
    }
    action Hapeville() {
        Tombstone.Boerne.Blakeley = (bit<2>)2w2;
    }
    action Barnhill() {
        Tombstone.Algoa.Sudbury = (bit<1>)1w1;
    }
    action NantyGlo() {
        Tombstone.Thayne.PineCity[30:0] = (Tombstone.Thayne.Osterdock >> 1)[30:0];
    }
    action Wildorado() {
        Tombstone.Pridgen.Newfane = 1w1;
        NantyGlo();
    }
    action Dozier() {
        Baytown.count();
        Tombstone.Algoa.Union = (bit<1>)1w1;
    }
    action Ocracoke() {
        Baytown.count();
        ;
    }
    table Lynch {
        actions = {
            Dozier();
            Ocracoke();
        }
        key = {
            Tombstone.Exton.Roachdale & 9w0x7f: exact;
            Tombstone.Algoa.Virgil            : ternary;
            Tombstone.Algoa.Requa             : ternary;
            Tombstone.Algoa.Florin            : ternary;
            Tombstone.Level.Iberia & 4w0x8    : ternary;
            Belmont.parser_err & 16w0x1000    : ternary;
        }
        size = 512;
        default_action = Ocracoke();
        counters = Baytown;
    }
    table Sanford {
        idle_timeout = true;
        actions = {
            McBrides();
            Hapeville();
        }
        key = {
            Tombstone.Algoa.McCaulley: exact;
            Tombstone.Algoa.Everton  : exact;
            Tombstone.Algoa.Roosville: exact;
            Tombstone.Algoa.Homeacre : exact;
        }
        size = 256;
        default_action = Hapeville();
    }
    table BealCity {
        actions = {
            Barnhill();
            Maddock();
        }
        key = {
            Tombstone.Algoa.McCaulley: exact;
            Tombstone.Algoa.Everton  : exact;
            Tombstone.Algoa.Roosville: exact;
        }
        size = 128;
        default_action = Maddock();
    }
    table Toluca {
        actions = {
            Wildorado();
            @defaultonly Maddock();
        }
        key = {
            Tombstone.Algoa.Dixboro  : ternary;
            Tombstone.Algoa.Paisano  : ternary;
            Tombstone.Algoa.Boquillas: ternary;
            Tombstone.Algoa.Cacao    : ternary;
        }
        size = 512;
        default_action = Maddock();
    }
    table Goodwin {
        actions = {
            Wildorado();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Algoa.Dixboro  : exact;
            Tombstone.Algoa.Paisano  : exact;
            Tombstone.Algoa.Boquillas: exact;
        }
        size = 2048;
        default_action = NoAction();
    }
    apply {
        switch (Lynch.apply().action_run) {
            Ocracoke: {
                switch (BealCity.apply().action_run) {
                    Maddock: {
                        if (Tombstone.Boerne.Blakeley == 2w0 && Tombstone.Algoa.Roosville != 12w0 && (Tombstone.Coulter.Bushland == 3w1 || Tombstone.Uvalde.Littleton == 1w1) && Tombstone.Algoa.Requa == 1w0 && Tombstone.Algoa.Florin == 1w0) {
                            Sanford.apply();
                        }
                        switch (Toluca.apply().action_run) {
                            Maddock: {
                                Goodwin.apply();
                            }
                        }

                    }
                }

            }
        }

    }
}

control Livonia(inout Hematite Pathfork, inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton) {
    action Bernice(bit<16> Fayette, bit<16> Osterdock, bit<16> Aguilita, bit<16> Harbor, bit<8> Kenbridge, bit<6> Alameda, bit<8> Davie, bit<8> Parkville, bit<1> Kearns) {
        Tombstone.Brinkman.Fayette = Tombstone.ElVerano.Fayette & Fayette;
        Tombstone.Brinkman.Osterdock = Tombstone.ElVerano.Osterdock & Osterdock;
        Tombstone.Brinkman.Aguilita = Tombstone.ElVerano.Aguilita & Aguilita;
        Tombstone.Brinkman.Harbor = Tombstone.ElVerano.Harbor & Harbor;
        Tombstone.Brinkman.Kenbridge = Tombstone.ElVerano.Kenbridge & Kenbridge;
        Tombstone.Brinkman.Alameda = Tombstone.ElVerano.Alameda & Alameda;
        Tombstone.Brinkman.Davie = Tombstone.ElVerano.Davie & Davie;
        Tombstone.Brinkman.Parkville = Tombstone.ElVerano.Parkville & Parkville;
        Tombstone.Brinkman.Kearns = Tombstone.ElVerano.Kearns & Kearns;
    }
    table Greenwood {
        actions = {
            Bernice();
        }
        key = {
            Tombstone.ElVerano.Mystic: exact;
        }
        size = 256;
        default_action = Bernice(16w0xffff, 16w0xffff, 16w0xffff, 16w0xffff, 8w0xff, 6w0x3f, 8w0xff, 8w0xff, 1w1);
    }
    apply {
        Greenwood.apply();
    }
}

control Readsboro(inout Hematite Pathfork, inout Daphne Tombstone) {
    Hash<bit<16>>(HashAlgorithm_t.CRC16) Astor;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) Hohenwald;
    action Sumner() {
        Tombstone.Kapalua.Helton = Astor.get<tuple<bit<8>, bit<32>, bit<32>>>({ Pathfork.Brainard.Rugby, Pathfork.Brainard.Fayette, Pathfork.Brainard.Osterdock });
    }
    action Eolia() {
        Tombstone.Kapalua.Helton = Hohenwald.get<tuple<bit<128>, bit<128>, bit<4>, bit<20>, bit<8>>>({ Pathfork.Fristoe.Fayette, Pathfork.Fristoe.Osterdock, 4w0, Pathfork.Fristoe.Randall, Pathfork.Fristoe.Palatine });
    }
    table Kamrar {
        actions = {
            Sumner();
        }
        size = 1;
        default_action = Sumner();
    }
    table Greenland {
        actions = {
            Eolia();
        }
        size = 1;
        default_action = Eolia();
    }
    apply {
        if (Pathfork.Brainard.isValid()) {
            Kamrar.apply();
        }
        else {
            Greenland.apply();
        }
    }
}

control Shingler(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Gastonia(bit<1> Blencoe, bit<1> Hillsview, bit<1> Westbury) {
        Tombstone.Algoa.Blencoe = Blencoe;
        Tombstone.Algoa.Florien = Hillsview;
        Tombstone.Algoa.Freeburg = Westbury;
    }
    table Makawao {
        actions = {
            Gastonia();
        }
        key = {
            Tombstone.Algoa.Roosville: exact;
        }
        size = 4096;
        default_action = Gastonia(1w0, 1w0, 1w0);
    }
    apply {
        Makawao.apply();
    }
}

control Mather(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Martelle(bit<20> Devers) {
        Tombstone.Coulter.Garibaldi = Tombstone.Uvalde.Killen;
        Tombstone.Coulter.Paisano = Tombstone.Algoa.Paisano;
        Tombstone.Coulter.Boquillas = Tombstone.Algoa.Boquillas;
        Tombstone.Coulter.Kaluaaha = Tombstone.Algoa.Roosville;
        Tombstone.Coulter.Calcasieu = Devers;
        Tombstone.Coulter.Dassel = (bit<10>)10w0;
        Tombstone.Algoa.Matheson = Tombstone.Algoa.Matheson | Tombstone.Algoa.Uintah;
    }
    table Gambrills {
        actions = {
            Martelle();
        }
        key = {
            Pathfork.McCammon.isValid(): exact;
        }
        size = 2;
        default_action = Martelle(20w511);
    }
    apply {
        Gambrills.apply();
    }
}

action Masontown(inout Daphne Tombstone, bit<15> Kalida) {
    Tombstone.Tenino.Comfrey = (bit<2>)2w0;
    Tombstone.Tenino.Kalida = Kalida;
}
control Wesson(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Yerington(bit<15> Kalida) {
        Tombstone.Tenino.Comfrey = (bit<2>)2w0;
        Tombstone.Tenino.Kalida = Kalida;
    }
    action Belmore(bit<15> Kalida) {
        Tombstone.Tenino.Comfrey = (bit<2>)2w2;
        Tombstone.Tenino.Kalida = Kalida;
    }
    action Millhaven(bit<15> Kalida) {
        Tombstone.Tenino.Comfrey = (bit<2>)2w3;
        Tombstone.Tenino.Kalida = Kalida;
    }
    action Newhalem(bit<15> Wallula) {
        Tombstone.Tenino.Wallula = Wallula;
        Tombstone.Tenino.Comfrey = (bit<2>)2w1;
    }
    action Maddock() {
        ;
    }
    action Westville(bit<16> Baudette, bit<15> Kalida) {
        Tombstone.Thayne.Quinwood = Baudette;
        Yerington(Kalida);
    }
    action Ekron(bit<16> Baudette, bit<15> Kalida) {
        Tombstone.Thayne.Quinwood = Baudette;
        Belmore(Kalida);
    }
    action Swisshome(bit<16> Baudette, bit<15> Kalida) {
        Tombstone.Thayne.Quinwood = Baudette;
        Millhaven(Kalida);
    }
    action Sequim(bit<16> Baudette, bit<15> Wallula) {
        Tombstone.Thayne.Quinwood = Baudette;
        Newhalem(Wallula);
    }
    action Hallwood(bit<16> Baudette) {
        Tombstone.Thayne.Quinwood = Baudette;
    }
    @idletime_precision(1) table Empire {
        idle_timeout = true;
        actions = {
            Masontown(Tombstone);
            Belmore();
            Millhaven();
            Newhalem();
            Maddock();
        }
        key = {
            Tombstone.Pridgen.LasVegas: exact;
            Tombstone.Thayne.Osterdock: exact;
        }
        size = 512;
        default_action = Maddock();
    }
    @idletime_precision(1) table Daisytown {
        idle_timeout = true;
        actions = {
            Westville();
            Ekron();
            Swisshome();
            Sequim();
            Hallwood();
            Maddock();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Pridgen.LasVegas & 8w0x7f: exact;
            Tombstone.Thayne.PineCity          : lpm;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        switch (Empire.apply().action_run) {
            Maddock: {
                Daisytown.apply();
            }
        }

    }
}

control Balmorhea(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Yerington(bit<15> Kalida) {
        Tombstone.Tenino.Comfrey = (bit<2>)2w0;
        Tombstone.Tenino.Kalida = Kalida;
    }
    action Belmore(bit<15> Kalida) {
        Tombstone.Tenino.Comfrey = (bit<2>)2w2;
        Tombstone.Tenino.Kalida = Kalida;
    }
    action Millhaven(bit<15> Kalida) {
        Tombstone.Tenino.Comfrey = (bit<2>)2w3;
        Tombstone.Tenino.Kalida = Kalida;
    }
    action Newhalem(bit<15> Wallula) {
        Tombstone.Tenino.Wallula = Wallula;
        Tombstone.Tenino.Comfrey = (bit<2>)2w1;
    }
    action Maddock() {
        ;
    }
    action Earling(bit<16> Baudette, bit<15> Kalida) {
        Tombstone.Parkland.Quinwood = Baudette;
        Yerington(Kalida);
    }
    action Udall(bit<16> Baudette, bit<15> Kalida) {
        Tombstone.Parkland.Quinwood = Baudette;
        Belmore(Kalida);
    }
    action Crannell(bit<16> Baudette, bit<15> Kalida) {
        Tombstone.Parkland.Quinwood = Baudette;
        Millhaven(Kalida);
    }
    action Aniak(bit<16> Baudette, bit<15> Wallula) {
        Tombstone.Parkland.Quinwood = Baudette;
        Newhalem(Wallula);
    }
    @idletime_precision(1) table Nevis {
        idle_timeout = true;
        actions = {
            Yerington();
            Belmore();
            Millhaven();
            Newhalem();
            Maddock();
        }
        key = {
            Tombstone.Pridgen.LasVegas  : exact;
            Tombstone.Parkland.Osterdock: exact;
        }
        size = 512;
        default_action = Maddock();
    }
    @action_default_only("Maddock") @idletime_precision(1) table Lindsborg {
        idle_timeout = true;
        actions = {
            Earling();
            Udall();
            Crannell();
            Aniak();
            Maddock();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Pridgen.LasVegas  : exact;
            Tombstone.Parkland.Osterdock: lpm;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        switch (Nevis.apply().action_run) {
            Maddock: {
                Lindsborg.apply();
            }
        }

    }
}

control Magasco(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Twain() {
        Pathfork.Ipava.setInvalid();
    }
    action Boonsboro(bit<20> Talco) {
        Twain();
        Tombstone.Coulter.Bushland = 3w2;
        Tombstone.Coulter.Calcasieu = Talco;
        Tombstone.Coulter.Kaluaaha = Tombstone.Algoa.Roosville;
        Tombstone.Coulter.Dassel = 10w0;
    }
    action Terral() {
        Twain();
        Tombstone.Coulter.Bushland = 3w3;
        Tombstone.Algoa.Blencoe = 1w0;
        Tombstone.Algoa.Florien = 1w0;
    }
    action HighRock() {
        Tombstone.Algoa.Chaska = 1w1;
    }
    table WebbCity {
        actions = {
            Boonsboro();
            Terral();
            HighRock();
            Twain();
        }
        key = {
            Pathfork.Ipava.Luzerne    : exact;
            Pathfork.Ipava.Devers     : exact;
            Pathfork.Ipava.Crozet     : exact;
            Pathfork.Ipava.Laxon      : exact;
            Tombstone.Coulter.Bushland: ternary;
        }
        size = 512;
        default_action = HighRock();
    }
    apply {
        WebbCity.apply();
    }
}

control Covert(inout Hematite Pathfork, inout Daphne Tombstone, inout ingress_intrinsic_metadata_for_tm_t Merrill, in ingress_intrinsic_metadata_t Exton) {
    DirectMeter(MeterType_t.BYTES) Ekwok;
    action Crump(bit<20> Talco) {
        Tombstone.Coulter.Calcasieu = Talco;
    }
    action Wyndmoor(bit<16> Levittown) {
        Merrill.mcast_grp_a = Levittown;
    }
    action Picabo(bit<20> Talco, bit<10> Dassel) {
        Tombstone.Coulter.Dassel = Dassel;
        Crump(Talco);
        Tombstone.Coulter.Ocoee = (bit<3>)3w5;
    }
    action Circle() {
        Tombstone.Algoa.Allgood = (bit<1>)1w1;
    }
    action Maddock() {
        ;
    }
    table Jayton {
        actions = {
            Crump();
            Wyndmoor();
            Picabo();
            Circle();
            Maddock();
        }
        key = {
            Tombstone.Coulter.Paisano  : exact;
            Tombstone.Coulter.Boquillas: exact;
            Tombstone.Coulter.Kaluaaha : exact;
        }
        size = 256;
        default_action = Maddock();
    }
    action Millstone() {
        Tombstone.Algoa.Willard = (bit<1>)Ekwok.execute();
        Tombstone.Coulter.Suwannee = Tombstone.Algoa.Freeburg;
        Merrill.copy_to_cpu = Tombstone.Algoa.Florien;
        Merrill.mcast_grp_a = (bit<16>)Tombstone.Coulter.Kaluaaha;
    }
    action Lookeba() {
        Tombstone.Algoa.Willard = (bit<1>)Ekwok.execute();
        Merrill.mcast_grp_a = (bit<16>)Tombstone.Coulter.Kaluaaha | 16w4096;
        Tombstone.Algoa.Avondale = 1w1;
        Tombstone.Coulter.Suwannee = Tombstone.Algoa.Freeburg;
    }
    action Alstown() {
        Tombstone.Algoa.Willard = (bit<1>)Ekwok.execute();
        Merrill.mcast_grp_a = (bit<16>)Tombstone.Coulter.Kaluaaha;
        Tombstone.Coulter.Suwannee = Tombstone.Algoa.Freeburg;
    }
    table Longwood {
        actions = {
            Millstone();
            Lookeba();
            Alstown();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Exton.Roachdale & 9w0x7f: ternary;
            Tombstone.Coulter.Paisano         : ternary;
            Tombstone.Coulter.Boquillas       : ternary;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        switch (Jayton.apply().action_run) {
            Maddock: {
                Longwood.apply();
            }
        }

    }
}

control Yorkshire(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Knights() {
        Tombstone.Coulter.Bushland = (bit<3>)3w0;
        Tombstone.Coulter.Hackett = (bit<1>)1w1;
        Tombstone.Coulter.Loring = (bit<8>)8w16;
    }
    table Humeston {
        actions = {
            Knights();
        }
        size = 1;
        default_action = Knights();
    }
    apply {
        if (Tombstone.Uvalde.Killen != 2w0 && Tombstone.Coulter.Bushland == 3w1 && Tombstone.Pridgen.Westboro & 4w0x1 == 4w0x1 && Pathfork.Barrow.Lafayette == 16w0x806) {
            Humeston.apply();
        }
    }
}

control Armagh(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Basco() {
        Tombstone.Algoa.Ronan = 1w1;
    }
    action McBrides() {
        ;
    }
    table Gamaliel {
        actions = {
            Basco();
            McBrides();
        }
        key = {
            Pathfork.Barrow.Paisano    : ternary;
            Pathfork.Barrow.Boquillas  : ternary;
            Pathfork.Brainard.Osterdock: exact;
        }
        size = 512;
        default_action = Basco();
    }
    apply {
        if (Tombstone.Uvalde.Killen != 2w0 && Tombstone.Coulter.Bushland == 3w1 && Tombstone.Pridgen.Newfane == 1w1) {
            Gamaliel.apply();
        }
    }
}

control Orting(inout Hematite Pathfork, inout Daphne Tombstone) {
    Hash<bit<16>>(HashAlgorithm_t.CRC16) SanRemo;
    action Thawville() {
        Tombstone.Kapalua.StarLake = SanRemo.get<tuple<bit<24>, bit<24>, bit<24>, bit<24>, bit<16>>>({ Pathfork.Barrow.Paisano, Pathfork.Barrow.Boquillas, Pathfork.Barrow.McCaulley, Pathfork.Barrow.Everton, Pathfork.Barrow.Lafayette });
    }
    table Harriet {
        actions = {
            Thawville();
        }
        size = 1;
        default_action = Thawville();
    }
    apply {
        Harriet.apply();
    }
}

control Dushore(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Bratt(bit<32> Ambrose) {
        Tombstone.Beaverdam.Quogue = (Tombstone.Beaverdam.Quogue >= Ambrose ? Tombstone.Beaverdam.Quogue : Ambrose);
    }
    table Tabler {
        actions = {
            Bratt();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.ElVerano.Mystic   : exact;
            Tombstone.Brinkman.Fayette  : exact;
            Tombstone.Brinkman.Osterdock: exact;
            Tombstone.Brinkman.Aguilita : exact;
            Tombstone.Brinkman.Harbor   : exact;
            Tombstone.Brinkman.Kenbridge: exact;
            Tombstone.Brinkman.Alameda  : exact;
            Tombstone.Brinkman.Davie    : exact;
            Tombstone.Brinkman.Parkville: exact;
            Tombstone.Brinkman.Kearns   : exact;
        }
        size = 8192;
        default_action = NoAction();
    }
    apply {
        Tabler.apply();
    }
}

control Hearne(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Bratt(bit<32> Ambrose) {
        Tombstone.Beaverdam.Quogue = (Tombstone.Beaverdam.Quogue >= Ambrose ? Tombstone.Beaverdam.Quogue : Ambrose);
    }
    table Moultrie {
        actions = {
            Bratt();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.ElVerano.Mystic   : exact;
            Tombstone.Brinkman.Fayette  : exact;
            Tombstone.Brinkman.Osterdock: exact;
            Tombstone.Brinkman.Aguilita : exact;
            Tombstone.Brinkman.Harbor   : exact;
            Tombstone.Brinkman.Kenbridge: exact;
            Tombstone.Brinkman.Alameda  : exact;
            Tombstone.Brinkman.Davie    : exact;
            Tombstone.Brinkman.Parkville: exact;
            Tombstone.Brinkman.Kearns   : exact;
        }
        size = 4096;
        default_action = NoAction();
    }
    apply {
        Moultrie.apply();
    }
}

control Pinetop(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Bratt(bit<32> Ambrose) {
        Tombstone.Beaverdam.Quogue = (Tombstone.Beaverdam.Quogue >= Ambrose ? Tombstone.Beaverdam.Quogue : Ambrose);
    }
    table Garrison {
        actions = {
            Bratt();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.ElVerano.Mystic   : exact;
            Tombstone.Brinkman.Fayette  : exact;
            Tombstone.Brinkman.Osterdock: exact;
            Tombstone.Brinkman.Aguilita : exact;
            Tombstone.Brinkman.Harbor   : exact;
            Tombstone.Brinkman.Kenbridge: exact;
            Tombstone.Brinkman.Alameda  : exact;
            Tombstone.Brinkman.Davie    : exact;
            Tombstone.Brinkman.Parkville: exact;
            Tombstone.Brinkman.Kearns   : exact;
        }
        size = 4096;
        default_action = NoAction();
    }
    apply {
        Garrison.apply();
    }
}

control Milano(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Bratt(bit<32> Ambrose) {
        Tombstone.Beaverdam.Quogue = (Tombstone.Beaverdam.Quogue >= Ambrose ? Tombstone.Beaverdam.Quogue : Ambrose);
    }
    table Dacono {
        actions = {
            Bratt();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.ElVerano.Mystic   : exact;
            Tombstone.Brinkman.Fayette  : exact;
            Tombstone.Brinkman.Osterdock: exact;
            Tombstone.Brinkman.Aguilita : exact;
            Tombstone.Brinkman.Harbor   : exact;
            Tombstone.Brinkman.Kenbridge: exact;
            Tombstone.Brinkman.Alameda  : exact;
            Tombstone.Brinkman.Davie    : exact;
            Tombstone.Brinkman.Parkville: exact;
            Tombstone.Brinkman.Kearns   : exact;
        }
        size = 8192;
        default_action = NoAction();
    }
    apply {
        Dacono.apply();
    }
}

control Biggers(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Pineville(bit<16> Fayette, bit<16> Osterdock, bit<16> Aguilita, bit<16> Harbor, bit<8> Kenbridge, bit<6> Alameda, bit<8> Davie, bit<8> Parkville, bit<1> Kearns) {
        Tombstone.Brinkman.Fayette = Tombstone.ElVerano.Fayette & Fayette;
        Tombstone.Brinkman.Osterdock = Tombstone.ElVerano.Osterdock & Osterdock;
        Tombstone.Brinkman.Aguilita = Tombstone.ElVerano.Aguilita & Aguilita;
        Tombstone.Brinkman.Harbor = Tombstone.ElVerano.Harbor & Harbor;
        Tombstone.Brinkman.Kenbridge = Tombstone.ElVerano.Kenbridge & Kenbridge;
        Tombstone.Brinkman.Alameda = Tombstone.ElVerano.Alameda & Alameda;
        Tombstone.Brinkman.Davie = Tombstone.ElVerano.Davie & Davie;
        Tombstone.Brinkman.Parkville = Tombstone.ElVerano.Parkville & Parkville;
        Tombstone.Brinkman.Kearns = Tombstone.ElVerano.Kearns & Kearns;
    }
    table Nooksack {
        actions = {
            Pineville();
        }
        key = {
            Tombstone.ElVerano.Mystic: exact;
        }
        size = 256;
        default_action = Pineville(16w0xffff, 16w0xffff, 16w0xffff, 16w0xffff, 8w0xff, 6w0x3f, 8w0xff, 8w0xff, 1w1);
    }
    apply {
        Nooksack.apply();
    }
}

control Courtdale(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Bratt(bit<32> Ambrose) {
        Tombstone.Beaverdam.Quogue = (Tombstone.Beaverdam.Quogue >= Ambrose ? Tombstone.Beaverdam.Quogue : Ambrose);
    }
    table Swifton {
        actions = {
            Bratt();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.ElVerano.Mystic   : exact;
            Tombstone.Brinkman.Fayette  : exact;
            Tombstone.Brinkman.Osterdock: exact;
            Tombstone.Brinkman.Aguilita : exact;
            Tombstone.Brinkman.Harbor   : exact;
            Tombstone.Brinkman.Kenbridge: exact;
            Tombstone.Brinkman.Alameda  : exact;
            Tombstone.Brinkman.Davie    : exact;
            Tombstone.Brinkman.Parkville: exact;
            Tombstone.Brinkman.Kearns   : exact;
        }
        size = 8192;
        default_action = NoAction();
    }
    apply {
        Swifton.apply();
    }
}

control PeaRidge(inout Hematite Pathfork, inout Daphne Tombstone) {
    apply {
    }
}

control Cranbury(inout Hematite Pathfork, inout Daphne Tombstone) {
    apply {
    }
}

control Neponset(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Bronwood(bit<16> Fayette, bit<16> Osterdock, bit<16> Aguilita, bit<16> Harbor, bit<8> Kenbridge, bit<6> Alameda, bit<8> Davie, bit<8> Parkville, bit<1> Kearns) {
        Tombstone.Brinkman.Fayette = Tombstone.ElVerano.Fayette & Fayette;
        Tombstone.Brinkman.Osterdock = Tombstone.ElVerano.Osterdock & Osterdock;
        Tombstone.Brinkman.Aguilita = Tombstone.ElVerano.Aguilita & Aguilita;
        Tombstone.Brinkman.Harbor = Tombstone.ElVerano.Harbor & Harbor;
        Tombstone.Brinkman.Kenbridge = Tombstone.ElVerano.Kenbridge & Kenbridge;
        Tombstone.Brinkman.Alameda = Tombstone.ElVerano.Alameda & Alameda;
        Tombstone.Brinkman.Davie = Tombstone.ElVerano.Davie & Davie;
        Tombstone.Brinkman.Parkville = Tombstone.ElVerano.Parkville & Parkville;
        Tombstone.Brinkman.Kearns = Tombstone.ElVerano.Kearns & Kearns;
    }
    table Cotter {
        actions = {
            Bronwood();
        }
        key = {
            Tombstone.ElVerano.Mystic: exact;
        }
        size = 256;
        default_action = Bronwood(16w0xffff, 16w0xffff, 16w0xffff, 16w0xffff, 8w0xff, 6w0x3f, 8w0xff, 8w0xff, 1w1);
    }
    apply {
        Cotter.apply();
    }
}

control Kinde(inout Hematite Pathfork, inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton) {
    action Hillside(bit<3> Armona, bit<6> Petrey, bit<2> Burrel) {
        Tombstone.Juniata.Armona = Armona;
        Tombstone.Juniata.Petrey = Petrey;
        Tombstone.Juniata.Burrel = Burrel;
    }
    table Wanamassa {
        actions = {
            Hillside();
        }
        key = {
            Tombstone.Exton.Roachdale: exact;
        }
        size = 512;
        default_action = Hillside(3w0, 6w0, 2w0);
    }
    apply {
        Wanamassa.apply();
    }
}

control Peoria(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Frederika(bit<16> Fayette, bit<16> Osterdock, bit<16> Aguilita, bit<16> Harbor, bit<8> Kenbridge, bit<6> Alameda, bit<8> Davie, bit<8> Parkville, bit<1> Kearns) {
        Tombstone.Brinkman.Fayette = Tombstone.ElVerano.Fayette & Fayette;
        Tombstone.Brinkman.Osterdock = Tombstone.ElVerano.Osterdock & Osterdock;
        Tombstone.Brinkman.Aguilita = Tombstone.ElVerano.Aguilita & Aguilita;
        Tombstone.Brinkman.Harbor = Tombstone.ElVerano.Harbor & Harbor;
        Tombstone.Brinkman.Kenbridge = Tombstone.ElVerano.Kenbridge & Kenbridge;
        Tombstone.Brinkman.Alameda = Tombstone.ElVerano.Alameda & Alameda;
        Tombstone.Brinkman.Davie = Tombstone.ElVerano.Davie & Davie;
        Tombstone.Brinkman.Parkville = Tombstone.ElVerano.Parkville & Parkville;
        Tombstone.Brinkman.Kearns = Tombstone.ElVerano.Kearns & Kearns;
    }
    table Saugatuck {
        actions = {
            Frederika();
        }
        key = {
            Tombstone.ElVerano.Mystic: exact;
        }
        size = 256;
        default_action = Frederika(16w0xffff, 16w0xffff, 16w0xffff, 16w0xffff, 8w0xff, 6w0x3f, 8w0xff, 8w0xff, 1w1);
    }
    apply {
        Saugatuck.apply();
    }
}

control Flaherty(inout Hematite Pathfork, inout Daphne Tombstone) {
    Hash<bit<16>>(HashAlgorithm_t.CRC16) Sunbury;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) Casnovia;
    action Sedan() {
        Tombstone.Kapalua.Grannis = Sunbury.get<tuple<bit<16>, bit<16>, bit<16>>>({ Tombstone.Kapalua.Helton, Pathfork.Whitefish.Aguilita, Pathfork.Whitefish.Harbor });
    }
    action Almota() {
        Tombstone.Kapalua.SoapLake = Casnovia.get<tuple<bit<16>, bit<16>, bit<16>>>({ Tombstone.Kapalua.Rains, Pathfork.Ayden.Aguilita, Pathfork.Ayden.Harbor });
    }
    action Lemont() {
        Sedan();
        Almota();
    }
    table Hookdale {
        actions = {
            Lemont();
        }
        size = 1;
        default_action = Lemont();
    }
    apply {
        Hookdale.apply();
    }
}

control Funston(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Yerington(bit<15> Kalida) {
        Tombstone.Tenino.Comfrey = (bit<2>)2w0;
        Tombstone.Tenino.Kalida = Kalida;
    }
    action Belmore(bit<15> Kalida) {
        Tombstone.Tenino.Comfrey = (bit<2>)2w2;
        Tombstone.Tenino.Kalida = Kalida;
    }
    action Millhaven(bit<15> Kalida) {
        Tombstone.Tenino.Comfrey = (bit<2>)2w3;
        Tombstone.Tenino.Kalida = Kalida;
    }
    action Newhalem(bit<15> Wallula) {
        Tombstone.Tenino.Wallula = Wallula;
        Tombstone.Tenino.Comfrey = (bit<2>)2w1;
    }
    action Mayflower() {
        Yerington(15w1);
    }
    action Maddock() {
        ;
    }
    action Halltown(bit<16> Baudette, bit<15> Kalida) {
        Tombstone.Parkland.Quinwood = Baudette;
        Yerington(Kalida);
    }
    action Recluse(bit<16> Baudette, bit<15> Kalida) {
        Tombstone.Parkland.Quinwood = Baudette;
        Belmore(Kalida);
    }
    action Arapahoe(bit<16> Baudette, bit<15> Kalida) {
        Tombstone.Parkland.Quinwood = Baudette;
        Millhaven(Kalida);
    }
    action Parkway(bit<16> Baudette, bit<15> Wallula) {
        Tombstone.Parkland.Quinwood = Baudette;
        Newhalem(Wallula);
    }
    action Palouse() {
        Yerington(15w1);
    }
    action Sespe(bit<15> Callao) {
        Yerington(Callao);
    }
    @idletime_precision(1) @action_default_only("Mayflower") table Wagener {
        idle_timeout = true;
        actions = {
            Yerington();
            Belmore();
            Millhaven();
            Newhalem();
            @defaultonly Mayflower();
        }
        key = {
            Tombstone.Pridgen.LasVegas                : exact;
            Tombstone.Thayne.Osterdock & 32w0xfff00000: lpm;
        }
        size = 128;
        default_action = Mayflower();
    }
    @idletime_precision(1) table Monrovia {
        idle_timeout = true;
        actions = {
            Halltown();
            Recluse();
            Arapahoe();
            Parkway();
            Maddock();
        }
        key = {
            Tombstone.Pridgen.LasVegas                                           : exact;
            Tombstone.Parkland.Osterdock & 128w0xffffffffffffffff0000000000000000: lpm;
        }
        size = 1024;
        default_action = Maddock();
    }
    @action_default_only("Palouse") @idletime_precision(1) table Rienzi {
        idle_timeout = true;
        actions = {
            Yerington();
            Belmore();
            Millhaven();
            Newhalem();
            Palouse();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Pridgen.LasVegas                                           : exact;
            Tombstone.Parkland.Osterdock & 128w0xfffffc00000000000000000000000000: lpm;
        }
        size = 64;
        default_action = NoAction();
    }
    table Ambler {
        actions = {
            Sespe();
        }
        key = {
            Tombstone.Pridgen.Westboro & 4w1: exact;
            Tombstone.Algoa.Cacao           : exact;
        }
        size = 2;
        default_action = Sespe(15w0);
    }
    apply {
        if (Tombstone.Algoa.Union == 1w0 && Tombstone.Pridgen.Newfane == 1w1 && Tombstone.Uvalde.Killen != 2w0 && Tombstone.Fairland.Pilar == 1w0 && Tombstone.Fairland.Loris == 1w0) {
            if (Tombstone.Pridgen.Westboro & 4w0x1 == 4w0x1 && Tombstone.Algoa.Cacao == 3w0x1) {
                if (Tombstone.Thayne.Quinwood != 16w0) {
                }
                else {
                    if (Tombstone.Tenino.Kalida == 15w0) {
                        Wagener.apply();
                    }
                }
            }
            else {
                if (Tombstone.Pridgen.Westboro & 4w0x2 == 4w0x2 && Tombstone.Algoa.Cacao == 3w0x2) {
                    if (Tombstone.Parkland.Quinwood != 16w0) {
                    }
                    else {
                        if (Tombstone.Tenino.Kalida == 15w0) {
                            Monrovia.apply();
                            if (Tombstone.Parkland.Quinwood != 16w0) {
                            }
                            else {
                                if (Tombstone.Tenino.Kalida == 15w0) {
                                    Rienzi.apply();
                                }
                            }
                        }
                    }
                }
                else {
                    if (Tombstone.Coulter.Hackett == 1w0 && (Tombstone.Algoa.Florien == 1w1 || Tombstone.Pridgen.Westboro & 4w0x1 == 4w0x1 && Tombstone.Algoa.Cacao == 3w0x3)) {
                        Ambler.apply();
                    }
                }
            }
        }
    }
}

control Olmitz(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Baker(bit<3> Tallassee) {
        Tombstone.Juniata.Tallassee = Tallassee;
    }
    action Glenoma(bit<3> Thurmond) {
        Tombstone.Juniata.Tallassee = Thurmond;
        Tombstone.Algoa.Lafayette = Pathfork.Lapoint[0].Lafayette;
    }
    action Lauada(bit<3> Thurmond) {
        Tombstone.Juniata.Tallassee = Thurmond;
        Tombstone.Algoa.Lafayette = Pathfork.Lapoint[1].Lafayette;
    }
    action RichBar() {
        Tombstone.Juniata.Alameda = Tombstone.Juniata.Petrey;
    }
    action Harding() {
        Tombstone.Juniata.Alameda = 6w0;
    }
    action Nephi() {
        Tombstone.Juniata.Alameda = Tombstone.Thayne.Alameda;
    }
    action Tofte() {
        Nephi();
    }
    action Jerico() {
        Tombstone.Juniata.Alameda = Tombstone.Parkland.Alameda;
    }
    table Wabbaseka {
        actions = {
            Baker();
            Glenoma();
            Lauada();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Algoa.Bledsoe      : exact;
            Tombstone.Juniata.Armona     : exact;
            Pathfork.Lapoint[0].Weatherby: exact;
            Pathfork.Lapoint[1].isValid(): exact;
        }
        size = 256;
        default_action = NoAction();
    }
    table Clearmont {
        actions = {
            RichBar();
            Harding();
            Nephi();
            Tofte();
            Jerico();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Coulter.Bushland: exact;
            Tombstone.Algoa.Cacao     : exact;
        }
        size = 17;
        default_action = NoAction();
    }
    apply {
        Wabbaseka.apply();
        Clearmont.apply();
    }
}

control Ruffin(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Rochert(bit<16> Fayette, bit<16> Osterdock, bit<16> Aguilita, bit<16> Harbor, bit<8> Kenbridge, bit<6> Alameda, bit<8> Davie, bit<8> Parkville, bit<1> Kearns) {
        Tombstone.Brinkman.Fayette = Tombstone.ElVerano.Fayette & Fayette;
        Tombstone.Brinkman.Osterdock = Tombstone.ElVerano.Osterdock & Osterdock;
        Tombstone.Brinkman.Aguilita = Tombstone.ElVerano.Aguilita & Aguilita;
        Tombstone.Brinkman.Harbor = Tombstone.ElVerano.Harbor & Harbor;
        Tombstone.Brinkman.Kenbridge = Tombstone.ElVerano.Kenbridge & Kenbridge;
        Tombstone.Brinkman.Alameda = Tombstone.ElVerano.Alameda & Alameda;
        Tombstone.Brinkman.Davie = Tombstone.ElVerano.Davie & Davie;
        Tombstone.Brinkman.Parkville = Tombstone.ElVerano.Parkville & Parkville;
        Tombstone.Brinkman.Kearns = Tombstone.ElVerano.Kearns & Kearns;
    }
    table Swanlake {
        actions = {
            Rochert();
        }
        key = {
            Tombstone.ElVerano.Mystic: exact;
        }
        size = 256;
        default_action = Rochert(16w0xffff, 16w0xffff, 16w0xffff, 16w0xffff, 8w0xff, 6w0x3f, 8w0xff, 8w0xff, 1w1);
    }
    apply {
        Swanlake.apply();
    }
}

control Geistown(inout Hematite Pathfork, inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton, inout ingress_intrinsic_metadata_for_deparser_t LaUnion) {
    action Lindy() {
    }
    action Brady() {
        LaUnion.digest_type = (bit<3>)3w2;
        Lindy();
    }
    action Emden() {
        LaUnion.digest_type = (bit<3>)3w3;
        Lindy();
    }
    action Skillman() {
        Tombstone.Coulter.Hackett = 1w1;
        Tombstone.Coulter.Loring = 8w22;
        Lindy();
        Tombstone.Fairland.Loris = 1w0;
        Tombstone.Fairland.Pilar = 1w0;
    }
    action Corinth() {
        Tombstone.Algoa.Corinth = 1w1;
        Lindy();
    }
    table Olcott {
        actions = {
            Brady();
            Emden();
            Skillman();
            Corinth();
            @defaultonly Lindy();
        }
        key = {
            Tombstone.Boerne.Blakeley            : exact;
            Tombstone.Algoa.Virgil               : ternary;
            Tombstone.Exton.Roachdale            : ternary;
            Tombstone.Algoa.Homeacre & 20w0x40000: ternary;
            Tombstone.Fairland.Loris             : ternary;
            Tombstone.Fairland.Pilar             : ternary;
            Tombstone.Algoa.Toklat               : ternary;
        }
        size = 512;
        default_action = Lindy();
    }
    apply {
        if (Tombstone.Boerne.Blakeley != 2w0) {
            Olcott.apply();
        }
    }
}

control Westoak(inout Hematite Pathfork, inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton) {
    action Lefor(bit<2> Comfrey, bit<15> Kalida) {
        Tombstone.Tenino.Comfrey = Comfrey;
        Tombstone.Tenino.Kalida = Kalida;
    }
    Hash<bit<16>>(HashAlgorithm_t.CRC16) Starkey;
    ActionSelector(32w1024, Starkey, SelectorMode_t.RESILIENT) Volens;
    table Wallula {
        actions = {
            Lefor();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Tenino.Wallula & 15w0x3ff: exact;
            Tombstone.Halaula.Ledoux           : selector;
            Tombstone.Exton.Roachdale          : selector;
        }
        size = 1024;
        implementation = Volens;
        default_action = NoAction();
    }
    apply {
        if (Tombstone.Uvalde.Killen != 2w0 && Tombstone.Tenino.Comfrey == 2w1) {
            Wallula.apply();
        }
    }
}

control Ravinia(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Virgilina(bit<16> Dwight, bit<16> Ramapo, bit<1> Bicknell, bit<1> Naruna) {
        Tombstone.Elderon.Galloway = Dwight;
        Tombstone.Alamosa.Bicknell = Bicknell;
        Tombstone.Alamosa.Ramapo = Ramapo;
        Tombstone.Alamosa.Naruna = Naruna;
    }
    @idletime_precision(1) table RockHill {
        idle_timeout = true;
        actions = {
            Virgilina();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Thayne.Osterdock: exact;
            Tombstone.Algoa.Dixboro   : exact;
        }
        size = 16384;
        default_action = NoAction();
    }
    apply {
        if (Tombstone.Algoa.Union == 1w0 && Tombstone.Fairland.Pilar == 1w0 && Tombstone.Fairland.Loris == 1w0 && Tombstone.Pridgen.Westboro & 4w0x4 == 4w0x4 && Tombstone.Algoa.Moorcroft == 1w1 && Tombstone.Algoa.Cacao == 3w0x1) {
            RockHill.apply();
        }
    }
}

control Robstown(inout Hematite Pathfork, inout Daphne Tombstone, inout ingress_intrinsic_metadata_for_tm_t Merrill) {
    action Ponder(bit<3> Kremlin, bit<5> Fishers) {
        Merrill.ingress_cos = Kremlin;
        Merrill.qid = Fishers;
    }
    table Philip {
        actions = {
            Ponder();
        }
        key = {
            Tombstone.Juniata.Burrel   : ternary;
            Tombstone.Juniata.Armona   : ternary;
            Tombstone.Juniata.Tallassee: ternary;
            Tombstone.Juniata.Alameda  : ternary;
            Tombstone.Juniata.Hampton  : ternary;
            Tombstone.Coulter.Bushland : ternary;
            Pathfork.Ipava.Burrel      : ternary;
            Pathfork.Ipava.Kremlin     : ternary;
        }
        size = 306;
        default_action = Ponder(3w0, 5w0);
    }
    apply {
        Philip.apply();
    }
}

control Levasy(inout Hematite Pathfork, inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton) {
    action Anacortes() {
        Tombstone.Algoa.Anacortes = (bit<1>)1w1;
    }
    action Indios(bit<10> Larwill) {
        Tombstone.Montross.Joslin = Larwill;
    }
    table Rhinebeck {
        actions = {
            Anacortes();
            Indios();
        }
        key = {
            Tombstone.Exton.Roachdale   : ternary;
            Tombstone.ElVerano.McBride  : ternary;
            Tombstone.ElVerano.Vinemont : ternary;
            Tombstone.Juniata.Alameda   : ternary;
            Tombstone.Algoa.Rugby       : ternary;
            Tombstone.Algoa.Davie       : ternary;
            Pathfork.Whitefish.Aguilita : ternary;
            Pathfork.Whitefish.Harbor   : ternary;
            Tombstone.ElVerano.Kearns   : ternary;
            Tombstone.ElVerano.Parkville: ternary;
        }
        size = 1024;
        default_action = Indios(10w0);
    }
    apply {
        Rhinebeck.apply();
    }
}

control Chatanika(inout Hematite Pathfork, inout Daphne Tombstone, inout ingress_intrinsic_metadata_for_tm_t Merrill) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) Boyle;
    action Ackerly(bit<8> Loring) {
        Boyle.count();
        Merrill.mcast_grp_a = 16w0;
        Tombstone.Coulter.Hackett = 1w1;
        Tombstone.Coulter.Loring = Loring;
    }
    action Noyack(bit<8> Loring, bit<1> Hettinger) {
        Boyle.count();
        Merrill.copy_to_cpu = (bit<1>)1w1;
        Tombstone.Coulter.Loring = Loring;
    }
    action McBrides() {
        Boyle.count();
    }
    table Hackett {
        actions = {
            Ackerly();
            Noyack();
            McBrides();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Algoa.Lafayette                                            : ternary;
            Tombstone.Algoa.Glassboro                                            : ternary;
            Tombstone.Algoa.Avondale                                             : ternary;
            Tombstone.Algoa.Dixboro                                              : ternary;
            Tombstone.Algoa.Mankato                                              : ternary;
            Tombstone.Algoa.Aguilita                                             : ternary;
            Tombstone.Algoa.Harbor                                               : ternary;
            Tombstone.Uvalde.Dowell                                              : ternary;
            Tombstone.Pridgen.Newfane                                            : ternary;
            Tombstone.Algoa.Davie                                                : ternary;
            Pathfork.Wamego.isValid()                                            : ternary;
            Pathfork.Wamego.Philbrook                                            : ternary;
            Tombstone.Algoa.Blencoe                                              : ternary;
            Tombstone.Thayne.Osterdock                                           : ternary;
            Tombstone.Algoa.Rugby                                                : ternary;
            Tombstone.Coulter.Suwannee                                           : ternary;
            Tombstone.Coulter.Bushland                                           : ternary;
            Tombstone.Parkland.Osterdock & 128w0xffff0000000000000000000000000000: ternary;
            Tombstone.Algoa.Florien                                              : ternary;
            Tombstone.Coulter.Loring                                             : ternary;
        }
        size = 512;
        counters = Boyle;
        default_action = NoAction();
    }
    apply {
        Hackett.apply();
    }
}

control Coryville(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Bellamy(bit<16> Ramapo, bit<1> Bicknell, bit<1> Naruna) {
        Tombstone.Knierim.Ramapo = Ramapo;
        Tombstone.Knierim.Bicknell = Bicknell;
        Tombstone.Knierim.Naruna = Naruna;
    }
    table Tularosa {
        actions = {
            Bellamy();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Coulter.Paisano  : exact;
            Tombstone.Coulter.Boquillas: exact;
            Tombstone.Coulter.Kaluaaha : exact;
        }
        size = 16384;
        default_action = NoAction();
    }
    apply {
        if (Tombstone.Algoa.Avondale == 1w1) {
            Tularosa.apply();
        }
    }
}

control Uniopolis(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Moosic(bit<10> Ossining) {
        Tombstone.Montross.Joslin[9:7] = Ossining[9:7];
    }
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) Starkey;
    ActionSelector(32w128, Starkey, SelectorMode_t.RESILIENT) Nason;
    @ternary(1) table Marquand {
        actions = {
            Moosic();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Montross.Joslin & 10w0x7f: exact;
            Tombstone.Halaula.Conner           : selector;
        }
        size = 128;
        implementation = Nason;
        default_action = NoAction();
    }
    apply {
        Marquand.apply();
    }
}

control Kempton(inout Hematite Pathfork, inout Daphne Tombstone) {
    action GunnCity(bit<8> Loring) {
        Tombstone.Coulter.Hackett = (bit<1>)1w1;
        Tombstone.Coulter.Loring = Loring;
    }
    action Oneonta() {
        Tombstone.Algoa.Blitchton = Tombstone.Algoa.Matheson;
    }
    action Sneads(bit<20> Calcasieu, bit<10> Dassel, bit<2> Adona) {
        Tombstone.Coulter.Albemarle = (bit<1>)1w1;
        Tombstone.Coulter.Calcasieu = Calcasieu;
        Tombstone.Coulter.Dassel = Dassel;
        Tombstone.Algoa.Adona = Adona;
    }
    table Hemlock {
        actions = {
            GunnCity();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Tenino.Kalida & 15w0xf: exact;
        }
        size = 16;
        default_action = NoAction();
    }
    table Blitchton {
        actions = {
            Oneonta();
        }
        size = 1;
        default_action = Oneonta();
    }
    @use_hash_action(1) table Mabana {
        actions = {
            Sneads();
        }
        key = {
            Tombstone.Tenino.Kalida: exact;
        }
        size = 32768;
        default_action = Sneads(20w511, 10w0, 2w0);
    }
    apply {
        if (Tombstone.Tenino.Kalida != 15w0) {
            Blitchton.apply();
            if (Tombstone.Tenino.Kalida & 15w0x7ff0 == 15w0) {
                Hemlock.apply();
            }
            else {
                Mabana.apply();
            }
        }
    }
}

control Hester(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Goodlett(bit<16> Ramapo, bit<1> Naruna) {
        Tombstone.Alamosa.Ramapo = Ramapo;
        Tombstone.Alamosa.Bicknell = (bit<1>)1w1;
        Tombstone.Alamosa.Naruna = Naruna;
    }
    @idletime_precision(1) @ways(2) table BigPoint {
        idle_timeout = true;
        actions = {
            Goodlett();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Thayne.Fayette  : exact;
            Tombstone.Elderon.Galloway: exact;
        }
        size = 16384;
        default_action = NoAction();
    }
    apply {
        if (Tombstone.Elderon.Galloway != 16w0 && Tombstone.Algoa.Cacao == 3w0x1) {
            BigPoint.apply();
        }
    }
}

control Tenstrike(inout Hematite Pathfork, inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton) {
    apply {
    }
}

control Castle(inout Hematite Pathfork, inout Daphne Tombstone) {
    Meter<bit<32>>(32w128, MeterType_t.BYTES) Aguila;
    action Nixon(bit<32> Mattapex) {
        Tombstone.Montross.Powderly = (bit<2>)Aguila.execute((bit<32>)Mattapex);
    }
    action Midas() {
        Tombstone.Montross.Powderly = (bit<2>)2w2;
    }
    @force_table_dependency("Marquand") table Kapowsin {
        actions = {
            Nixon();
            Midas();
        }
        key = {
            Tombstone.Montross.Weyauwega: exact;
        }
        size = 1024;
        default_action = Midas();
    }
    apply {
        Kapowsin.apply();
    }
}

control Crown(inout Hematite Pathfork, inout Daphne Tombstone, inout ingress_intrinsic_metadata_for_tm_t Merrill) {
    action McBrides() {
        ;
    }
    action Vanoss() {
        Tombstone.Algoa.Shabbona = (bit<1>)1w1;
    }
    action Potosi() {
        Tombstone.Algoa.Selawik = (bit<1>)1w1;
    }
    action Mulvane(bit<20> Calcasieu, bit<32> Luning) {
        Tombstone.Coulter.Dugger = (bit<32>)Tombstone.Coulter.Calcasieu;
        Tombstone.Coulter.Laurelton = Luning;
        Tombstone.Coulter.Calcasieu = Calcasieu;
        Tombstone.Coulter.Ocoee = 3w5;
        Merrill.disable_ucast_cutthru = (bit<1>)1w1;
    }
    @ways(1) table Flippen {
        actions = {
            McBrides();
            Vanoss();
        }
        key = {
            Tombstone.Coulter.Calcasieu & 20w0x7ff: exact;
        }
        size = 258;
        default_action = McBrides();
    }
    table Cadwell {
        actions = {
            Potosi();
        }
        size = 1;
        default_action = Potosi();
    }
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) Starkey;
    ActionSelector(32w128, Starkey, SelectorMode_t.RESILIENT) Boring;
    @ways(2) table Nucla {
        actions = {
            Mulvane();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Coulter.Dassel: exact;
            Tombstone.Halaula.Conner: selector;
        }
        size = 2;
        implementation = Boring;
        default_action = NoAction();
    }
    apply {
        if (Tombstone.Algoa.Union == 1w0 && Tombstone.Coulter.Albemarle == 1w0 && Tombstone.Algoa.Avondale == 1w0 && Tombstone.Algoa.Glassboro == 1w0 && Tombstone.Fairland.Pilar == 1w0 && Tombstone.Fairland.Loris == 1w0) {
            if (Tombstone.Algoa.Homeacre == Tombstone.Coulter.Calcasieu || Tombstone.Coulter.Bushland == 3w1 && Tombstone.Coulter.Ocoee == 3w5) {
                Cadwell.apply();
            }
            else {
                if (Tombstone.Uvalde.Killen == 2w2 && Tombstone.Coulter.Calcasieu & 20w0xff800 == 20w0x3800) {
                    Flippen.apply();
                }
            }
        }
        Nucla.apply();
    }
}

control Tillson(inout Hematite Pathfork, inout Daphne Tombstone, inout ingress_intrinsic_metadata_for_tm_t Merrill) {
    action Micro() {
    }
    action Lattimore(bit<1> Naruna) {
        Micro();
        Merrill.mcast_grp_a = Tombstone.Alamosa.Ramapo;
        Merrill.copy_to_cpu = Naruna | Tombstone.Alamosa.Naruna;
    }
    action Cheyenne(bit<1> Naruna) {
        Micro();
        Merrill.mcast_grp_a = Tombstone.Knierim.Ramapo;
        Merrill.copy_to_cpu = Naruna | Tombstone.Knierim.Naruna;
    }
    action Pacifica(bit<1> Naruna) {
        Micro();
        Merrill.mcast_grp_a = (bit<16>)Tombstone.Coulter.Kaluaaha | 16w4096;
        Merrill.copy_to_cpu = Naruna;
    }
    action Judson() {
        Tombstone.Algoa.Waipahu = (bit<1>)1w1;
    }
    action Mogadore(bit<1> Naruna) {
        Merrill.mcast_grp_a = (bit<16>)16w0;
        Merrill.copy_to_cpu = Naruna;
    }
    action Westview(bit<1> Naruna) {
        Micro();
        Merrill.mcast_grp_a = (bit<16>)Tombstone.Coulter.Kaluaaha;
        Merrill.copy_to_cpu = Merrill.copy_to_cpu | Naruna;
    }
    table Pimento {
        actions = {
            Lattimore();
            Cheyenne();
            Pacifica();
            Judson();
            Mogadore();
            Westview();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Alamosa.Bicknell: ternary;
            Tombstone.Knierim.Bicknell: ternary;
            Tombstone.Algoa.Rugby     : ternary;
            Tombstone.Algoa.Moorcroft : ternary;
            Tombstone.Algoa.Blencoe   : ternary;
            Tombstone.Thayne.Osterdock: ternary;
            Tombstone.Coulter.Hackett : ternary;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        Pimento.apply();
    }
}

control Campo(inout Hematite Pathfork, inout Daphne Tombstone) {
    action SanPablo(bit<5> Solomon) {
        Tombstone.Juniata.Solomon = Solomon;
    }
    table Forepaugh {
        actions = {
            SanPablo();
        }
        key = {
            Pathfork.Wamego.isValid(): ternary;
            Tombstone.Coulter.Loring : ternary;
            Tombstone.Coulter.Hackett: ternary;
            Tombstone.Algoa.Glassboro: ternary;
            Tombstone.Algoa.Rugby    : ternary;
            Tombstone.Algoa.Aguilita : ternary;
            Tombstone.Algoa.Harbor   : ternary;
        }
        size = 512;
        default_action = SanPablo(5w0);
    }
    apply {
        Forepaugh.apply();
    }
}

control Chewalla(inout Hematite Pathfork, inout Daphne Tombstone, inout ingress_intrinsic_metadata_for_tm_t Merrill) {
    action WildRose(bit<6> Alameda) {
        Tombstone.Juniata.Alameda = Alameda;
    }
    action Kellner(bit<3> Tallassee) {
        Tombstone.Juniata.Tallassee = Tallassee;
    }
    action Hagaman(bit<3> Tallassee, bit<6> Alameda) {
        Tombstone.Juniata.Tallassee = Tallassee;
        Tombstone.Juniata.Alameda = Alameda;
    }
    action McKenney(bit<1> Dunstable, bit<1> Madawaska) {
        Tombstone.Juniata.Dunstable = Dunstable;
        Tombstone.Juniata.Madawaska = Madawaska;
    }
    @ternary(1) table Decherd {
        actions = {
            WildRose();
            Kellner();
            Hagaman();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Juniata.Burrel   : exact;
            Tombstone.Juniata.Dunstable: exact;
            Tombstone.Juniata.Madawaska: exact;
            Merrill.ingress_cos        : exact;
            Tombstone.Coulter.Bushland : exact;
        }
        size = 1024;
        default_action = NoAction();
    }
    table Bucklin {
        actions = {
            McKenney();
        }
        size = 1;
        default_action = McKenney(1w0, 1w0);
    }
    apply {
        Bucklin.apply();
        Decherd.apply();
    }
}

control Bernard(inout Hematite Pathfork, inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton, inout ingress_intrinsic_metadata_for_tm_t Merrill) {
    action Owanka(bit<9> Natalia) {
        Merrill.level2_mcast_hash = (bit<13>)Tombstone.Halaula.Conner;
        Merrill.level2_exclusion_id = Natalia;
    }
    @ternary(1) table Sunman {
        actions = {
            Owanka();
        }
        key = {
            Tombstone.Exton.Roachdale: exact;
        }
        size = 512;
        default_action = Owanka(9w0);
    }
    apply {
        Sunman.apply();
    }
}

control FairOaks(inout Hematite Pathfork, inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton, inout ingress_intrinsic_metadata_for_tm_t Merrill) {
    action Baranof() {
        Tombstone.Coulter.Dugger = Tombstone.Coulter.Dugger | Tombstone.Coulter.Laurelton;
    }
    action Anita(bit<9> Cairo) {
        Merrill.ucast_egress_port = Cairo;
        Baranof();
    }
    action Exeter() {
        Merrill.ucast_egress_port = (bit<9>)Tombstone.Coulter.Calcasieu;
        Baranof();
    }
    action Yulee() {
        Merrill.ucast_egress_port = 9w511;
    }
    action Oconee() {
        Baranof();
        Yulee();
    }
    Hash<bit<16>>(HashAlgorithm_t.CRC16) Starkey;
    ActionSelector(32w1024, Starkey, SelectorMode_t.RESILIENT) Salitpa;
    table Spanaway {
        actions = {
            Anita();
            Exeter();
            Oconee();
            Yulee();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Coulter.Calcasieu: ternary;
            Tombstone.Exton.Roachdale  : selector;
            Tombstone.Halaula.Conner   : selector;
        }
        size = 258;
        implementation = Salitpa;
        default_action = NoAction();
    }
    apply {
        Spanaway.apply();
    }
}

control Notus(inout Hematite Pathfork, inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton, inout ingress_intrinsic_metadata_for_tm_t Merrill) {
    action Dahlgren(bit<9> Andrade, bit<5> McDonough) {
        Merrill.ucast_egress_port = Andrade;
        Merrill.qid = McDonough;
    }
    action Ozona(bit<9> Andrade, bit<5> McDonough) {
        Dahlgren(Andrade, McDonough);
        Tombstone.Coulter.Buckeye = (bit<1>)1w0;
    }
    action Leland(bit<5> Aynor) {
        Merrill.qid[4:3] = Aynor[4:3];
    }
    action McIntyre(bit<5> Aynor) {
        Leland(Aynor);
        Tombstone.Coulter.Buckeye = (bit<1>)1w0;
    }
    action Millikin(bit<9> Andrade, bit<5> McDonough) {
        Dahlgren(Andrade, McDonough);
        Tombstone.Coulter.Buckeye = (bit<1>)1w1;
    }
    action Meyers(bit<5> Aynor) {
        Leland(Aynor);
        Tombstone.Coulter.Buckeye = (bit<1>)1w1;
    }
    action Earlham(bit<9> Andrade, bit<5> McDonough) {
        Millikin(Andrade, McDonough);
        Tombstone.Algoa.Roosville = Pathfork.Lapoint[0].Norwood;
    }
    action Lewellen(bit<5> Aynor) {
        Meyers(Aynor);
        Tombstone.Algoa.Roosville = Pathfork.Lapoint[0].Norwood;
    }
    table Absecon {
        actions = {
            Ozona();
            McIntyre();
            Millikin();
            Meyers();
            Earlham();
            Lewellen();
        }
        key = {
            Tombstone.Coulter.Hackett    : exact;
            Tombstone.Algoa.Bledsoe      : exact;
            Tombstone.Uvalde.Littleton   : ternary;
            Tombstone.Coulter.Loring     : ternary;
            Pathfork.Lapoint[0].isValid(): ternary;
        }
        size = 512;
        default_action = Meyers(5w0);
    }
    FairOaks() Brodnax;
    apply {
        switch (Absecon.apply().action_run) {
            Earlham: {
            }
            Millikin: {
            }
            Ozona: {
            }
            default: {
                Brodnax.apply(Pathfork, Tombstone, Exton, Merrill);
            }
        }

    }
}

control Bowers(inout Hematite Pathfork) {
    action Skene() {
        Pathfork.McCammon.Lafayette = Pathfork.Lapoint[0].Lafayette;
        Pathfork.Lapoint[0].setInvalid();
    }
    table Scottdale {
        actions = {
            Skene();
        }
        size = 1;
        default_action = Skene();
    }
    apply {
        Scottdale.apply();
    }
}

control Camargo(inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton, inout ingress_intrinsic_metadata_for_deparser_t LaUnion) {
    action Pioche() {
        LaUnion.mirror_type = (bit<3>)3w1;
    }
    table Florahome {
        actions = {
            Pioche();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Montross.Powderly: exact;
        }
        size = 2;
        default_action = NoAction();
    }
    apply {
        if (Tombstone.Montross.Joslin != 10w0) {
            Florahome.apply();
        }
    }
}

control Newtonia(inout Hematite Pathfork, inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton, inout ingress_intrinsic_metadata_for_tm_t Merrill, inout ingress_intrinsic_metadata_for_deparser_t LaUnion) {
    DirectCounter<bit<63>>(CounterType_t.PACKETS) Waterman;
    DirectCounter<bit<64>>(CounterType_t.PACKETS) Flynn;
    Counter<bit<64>, bit<32>>(32w4096, CounterType_t.PACKETS) Algonquin;
    Meter<bit<32>>(32w4096, MeterType_t.BYTES) Beatrice;
    action Morrow(bit<32> Elkton) {
        LaUnion.drop_ctl = (bit<3>)Beatrice.execute((bit<32>)Elkton);
    }
    action Penzance(bit<32> Elkton) {
        Algonquin.count((bit<32>)Elkton);
    }
    action Shasta(bit<32> Elkton) {
        Morrow(Elkton);
        Penzance(Elkton);
    }
    action Weathers() {
        Waterman.count();
        ;
    }
    table Coupland {
        actions = {
            Weathers();
        }
        key = {
            Tombstone.Beaverdam.Quogue & 32w0x7ffff: exact;
        }
        size = 32768;
        default_action = Weathers();
        counters = Waterman;
    }
    action Laclede() {
        Flynn.count();
        LaUnion.drop_ctl = LaUnion.drop_ctl | 3w3;
    }
    action RedLake() {
        Flynn.count();
        Merrill.copy_to_cpu = Merrill.copy_to_cpu | 1w0;
    }
    action Ruston() {
        Flynn.count();
        Merrill.copy_to_cpu = (bit<1>)1w1;
    }
    action LaPlant() {
        Merrill.copy_to_cpu = Merrill.copy_to_cpu | 1w0;
        Laclede();
    }
    action DeepGap() {
        Merrill.copy_to_cpu = (bit<1>)1w1;
        Laclede();
    }
    table Horatio {
        actions = {
            RedLake();
            Ruston();
            LaPlant();
            DeepGap();
            Laclede();
        }
        key = {
            Tombstone.Exton.Roachdale & 9w0x7f     : ternary;
            Tombstone.Beaverdam.Quogue & 32w0x18000: ternary;
            Tombstone.Algoa.Union                  : ternary;
            Tombstone.Algoa.Sudbury                : ternary;
            Tombstone.Algoa.Allgood                : ternary;
            Tombstone.Algoa.Chaska                 : ternary;
            Tombstone.Algoa.Selawik                : ternary;
            Tombstone.Algoa.Blitchton              : ternary;
            Tombstone.Algoa.Shabbona               : ternary;
            Tombstone.Algoa.Cacao & 3w0x4          : ternary;
            Tombstone.Coulter.Calcasieu            : ternary;
            Merrill.mcast_grp_a                    : ternary;
            Tombstone.Coulter.Albemarle            : ternary;
            Tombstone.Coulter.Hackett              : ternary;
            Tombstone.Algoa.Ronan                  : ternary;
            Tombstone.Algoa.Anacortes              : ternary;
            Tombstone.Algoa.Cabot                  : ternary;
            Tombstone.Fairland.Loris               : ternary;
            Tombstone.Fairland.Pilar               : ternary;
            Tombstone.Algoa.Corinth                : ternary;
            Tombstone.Algoa.Bayshore & 3w0x2       : ternary;
            Merrill.copy_to_cpu                    : ternary;
            Tombstone.Algoa.Willard                : ternary;
        }
        size = 1536;
        default_action = RedLake();
        counters = Flynn;
    }
    table Rives {
        actions = {
            Penzance();
            Shasta();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Juniata.Kendrick: exact;
            Tombstone.Juniata.Solomon : exact;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        switch (Horatio.apply().action_run) {
            Laclede: {
            }
            LaPlant: {
            }
            DeepGap: {
            }
            default: {
                Rives.apply();
                Coupland.apply();
            }
        }

    }
}

control Sedona(inout Hematite Pathfork, inout Daphne Tombstone, inout ingress_intrinsic_metadata_for_tm_t Merrill) {
    action Kotzebue(bit<16> Felton) {
        Merrill.level1_exclusion_id = Felton;
        Merrill.rid = Merrill.mcast_grp_a;
    }
    action Arial(bit<16> Felton) {
        Kotzebue(Felton);
    }
    action Amalga(bit<16> Felton) {
        Merrill.rid = (bit<16>)16w0xffff;
        Merrill.level1_exclusion_id = Felton;
    }
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) Daleville;
    action Burmah() {
        Amalga(16w0);
    }
    table Leacock {
        actions = {
            Kotzebue();
            Arial();
            Amalga();
            Burmah();
        }
        key = {
            Tombstone.Coulter.Bushland              : ternary;
            Tombstone.Coulter.Albemarle             : ternary;
            Tombstone.Uvalde.Killen                 : ternary;
            Tombstone.Coulter.Calcasieu & 20w0xf0000: ternary;
            Merrill.mcast_grp_a & 16w0xf000         : ternary;
        }
        size = 512;
        default_action = Arial(16w0);
    }
    apply {
        if (Tombstone.Coulter.Hackett == 1w0) {
            Leacock.apply();
        }
    }
}

control WestPark(inout Hematite Pathfork, inout Daphne Tombstone, in ingress_intrinsic_metadata_t Exton, in ingress_intrinsic_metadata_from_parser_t Belmont, inout ingress_intrinsic_metadata_for_deparser_t LaUnion, inout ingress_intrinsic_metadata_for_tm_t Merrill) {
    action WestEnd() {
        {
            Tombstone.Merrill.Churchill = Merrill.ingress_cos;
            Pathfork.Orrick.Provo = (bit<8>)8w0;
            Tombstone.Glenmora.Provo = (bit<8>)8w1;
            Tombstone.Glenmora.Horton = Tombstone.Exton.Roachdale;
            Tombstone.Coulter.Horton = Tombstone.Exton.Roachdale;
        }
        {
            Pathfork.Orrick.setValid();
            {
            }
            Pathfork.Orrick.Manilla = Tombstone.Uvalde.Littleton;
        }
    }
    action Jenifer(bit<1> Willey) {
        Tombstone.Coulter.Hoagland = Willey;
        Pathfork.Brainard.Rugby = Tombstone.Level.Wheaton | 8w0x80;
    }
    action Endicott(bit<1> Willey) {
        Tombstone.Coulter.Hoagland = Willey;
        Pathfork.Fristoe.Palatine = Tombstone.Level.Wheaton | 8w0x80;
    }
    action BigRock() {
        Tombstone.Halaula.Ledoux = Tombstone.Kapalua.Helton;
    }
    action Timnath() {
        Tombstone.Halaula.Ledoux = Tombstone.Kapalua.Grannis;
    }
    action Woodsboro() {
        Tombstone.Halaula.Ledoux = Tombstone.Kapalua.Rains;
    }
    action Amherst() {
        Tombstone.Halaula.Ledoux = Tombstone.Kapalua.SoapLake;
    }
    action Luttrell() {
        Tombstone.Halaula.Ledoux = Tombstone.Kapalua.StarLake;
    }
    action Maddock() {
        ;
    }
    action Plano() {
        Tombstone.Beaverdam.Quogue = (bit<32>)32w0;
    }
    Hash<bit<16>>(HashAlgorithm_t.CRC16) Leoma;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) Aiken;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) Anawalt;
    action Asharoken() {
        Tombstone.Kapalua.Rains = Leoma.get<tuple<bit<32>, bit<32>, bit<8>>>({ Tombstone.Thayne.Fayette, Tombstone.Thayne.Osterdock, Tombstone.Level.Dunedin });
    }
    action Weissert() {
        Tombstone.Kapalua.Rains = Aiken.get<tuple<bit<128>, bit<128>, bit<4>, bit<20>, bit<8>>>({ Tombstone.Parkland.Fayette, Tombstone.Parkland.Osterdock, 4w0, Pathfork.Raiford.Randall, Tombstone.Level.Dunedin });
    }
    action Bellmead() {
        Tombstone.Halaula.Conner = Anawalt.get<tuple<bit<24>, bit<24>, bit<24>, bit<24>, bit<16>>>({ Pathfork.McCammon.Paisano, Pathfork.McCammon.Boquillas, Pathfork.McCammon.McCaulley, Pathfork.McCammon.Everton, Tombstone.Algoa.Lafayette });
    }
    action NorthRim() {
        Tombstone.Halaula.Conner = Tombstone.Kapalua.Helton;
    }
    action Wardville() {
        Tombstone.Halaula.Conner = Tombstone.Kapalua.Grannis;
    }
    action Oregon() {
        Tombstone.Halaula.Conner = Tombstone.Kapalua.StarLake;
    }
    action Ranburne() {
        Tombstone.Halaula.Conner = Tombstone.Kapalua.Rains;
    }
    action Barnsboro() {
        Tombstone.Halaula.Conner = Tombstone.Kapalua.SoapLake;
    }
    action Standard(bit<24> Paisano, bit<24> Boquillas, bit<12> Wolverine) {
        Tombstone.Coulter.Paisano = Paisano;
        Tombstone.Coulter.Boquillas = Boquillas;
        Tombstone.Coulter.Kaluaaha = Wolverine;
    }
    table Wentworth {
        actions = {
            Jenifer();
            Endicott();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Level.Wheaton & 8w0x80: exact;
            Pathfork.Brainard.isValid()     : exact;
            Pathfork.Fristoe.isValid()      : exact;
        }
        size = 8;
        default_action = NoAction();
    }
    table ElkMills {
        actions = {
            BigRock();
            Timnath();
            Woodsboro();
            Amherst();
            Luttrell();
            Maddock();
            @defaultonly NoAction();
        }
        key = {
            Pathfork.Ayden.isValid()    : ternary;
            Pathfork.Foster.isValid()   : ternary;
            Pathfork.Raiford.isValid()  : ternary;
            Pathfork.Barrow.isValid()   : ternary;
            Pathfork.Whitefish.isValid(): ternary;
            Pathfork.Fristoe.isValid()  : ternary;
            Pathfork.Brainard.isValid() : ternary;
        }
        size = 512;
        default_action = NoAction();
    }
    @stage(10) table Bostic {
        actions = {
            Plano();
        }
        size = 1;
        default_action = Plano();
    }
    table Danbury {
        actions = {
            Asharoken();
            Weissert();
            @defaultonly NoAction();
        }
        key = {
            Pathfork.Foster.isValid() : exact;
            Pathfork.Raiford.isValid(): exact;
        }
        size = 2;
        default_action = NoAction();
    }
    table Monse {
        actions = {
            Bellmead();
            NorthRim();
            Wardville();
            Oregon();
            Ranburne();
            Barnsboro();
            Maddock();
            @defaultonly NoAction();
        }
        key = {
            Pathfork.Ayden.isValid()    : ternary;
            Pathfork.Foster.isValid()   : ternary;
            Pathfork.Raiford.isValid()  : ternary;
            Pathfork.Barrow.isValid()   : ternary;
            Pathfork.Whitefish.isValid(): ternary;
            Pathfork.Brainard.isValid() : ternary;
            Pathfork.Fristoe.isValid()  : ternary;
            Pathfork.McCammon.isValid() : ternary;
        }
        size = 256;
        default_action = NoAction();
    }
    table Kalida {
        actions = {
            Standard();
        }
        key = {
            Tombstone.Tenino.Kalida: exact;
        }
        size = 32768;
        default_action = Standard(24w0, 24w0, 12w0);
    }
    Aldan() Chatom;
    Savery() Ravenwood;
    Cassa() Poneto;
    Bridger() Lurton;
    Livonia() Quijotoa;
    Readsboro() Frontenac;
    Shingler() Gilman;
    Mather() Kalaloch;
    Balmorhea() Papeton;
    Wesson() Yatesboro;
    Magasco() Maxwelton;
    Covert() Ihlen;
    Armagh() Faulkton;
    Yorkshire() Philmont;
    Orting() ElCentro;
    Dushore() Twinsburg;
    Neponset() Redvale;
    Kinde() Macon;
    Flaherty() Bains;
    Hearne() Franktown;
    Peoria() Willette;
    Funston() Mayview;
    Olmitz() Swandale;
    Pinetop() Neosho;
    Ruffin() Islen;
    Geistown() BarNunn;
    Westoak() Jemison;
    Milano() Pillager;
    Biggers() Nighthawk;
    Ravinia() Tullytown;
    Robstown() Heaton;
    Levasy() Somis;
    Chatanika() Aptos;
    Coryville() Lacombe;
    Uniopolis() Clifton;
    Kempton() Kingsland;
    Hester() Eaton;
    Cranbury() Trevorton;
    PeaRidge() Fordyce;
    Courtdale() Ugashik;
    Tenstrike() Rhodell;
    Castle() Heizer;
    Crown() Froid;
    Tillson() Hector;
    Campo() Wakefield;
    Chewalla() Miltona;
    Bernard() Wakeman;
    Notus() Chilson;
    Bowers() Reynolds;
    Camargo() Kosmos;
    Newtonia() Ironia;
    Sedona() BigFork;
    apply {
        {
        }
        ;
        Danbury.apply();
        if (Tombstone.Uvalde.Killen != 2w0) {
            Chatom.apply(Pathfork, Tombstone, Exton);
        }
        Ravenwood.apply(Pathfork, Tombstone, Exton);
        Poneto.apply(Pathfork, Tombstone, Exton);
        if (Tombstone.Uvalde.Killen != 2w0) {
            Lurton.apply(Pathfork, Tombstone, Exton, Belmont);
        }
        Quijotoa.apply(Pathfork, Tombstone, Exton);
        Frontenac.apply(Pathfork, Tombstone);
        Gilman.apply(Pathfork, Tombstone);
        Kalaloch.apply(Pathfork, Tombstone);
        if (Tombstone.Algoa.Union == 1w0 && Tombstone.Fairland.Pilar == 1w0 && Tombstone.Fairland.Loris == 1w0) {
            if (Tombstone.Pridgen.Westboro & 4w0x2 == 4w0x2 && Tombstone.Algoa.Cacao == 3w0x2 && Tombstone.Uvalde.Killen != 2w0 && Tombstone.Pridgen.Newfane == 1w1) {
                Papeton.apply(Pathfork, Tombstone);
            }
            else {
                if (Tombstone.Pridgen.Westboro & 4w0x1 == 4w0x1 && Tombstone.Algoa.Cacao == 3w0x1 && Tombstone.Uvalde.Killen != 2w0 && Tombstone.Pridgen.Newfane == 1w1) {
                    Yatesboro.apply(Pathfork, Tombstone);
                }
                else {
                    if (Pathfork.Ipava.isValid()) {
                        Maxwelton.apply(Pathfork, Tombstone);
                    }
                    if (Tombstone.Coulter.Hackett == 1w0 && Tombstone.Coulter.Bushland != 3w2) {
                        Ihlen.apply(Pathfork, Tombstone, Merrill, Exton);
                    }
                }
            }
        }
        Faulkton.apply(Pathfork, Tombstone);
        Philmont.apply(Pathfork, Tombstone);
        ElCentro.apply(Pathfork, Tombstone);
        Twinsburg.apply(Pathfork, Tombstone);
        Redvale.apply(Pathfork, Tombstone);
        Macon.apply(Pathfork, Tombstone, Exton);
        Bains.apply(Pathfork, Tombstone);
        Franktown.apply(Pathfork, Tombstone);
        Willette.apply(Pathfork, Tombstone);
        Mayview.apply(Pathfork, Tombstone);
        Swandale.apply(Pathfork, Tombstone);
        Neosho.apply(Pathfork, Tombstone);
        Islen.apply(Pathfork, Tombstone);
        ElkMills.apply();
        BarNunn.apply(Pathfork, Tombstone, Exton, LaUnion);
        Jemison.apply(Pathfork, Tombstone, Exton);
        Pillager.apply(Pathfork, Tombstone);
        Nighthawk.apply(Pathfork, Tombstone);
        Tullytown.apply(Pathfork, Tombstone);
        Heaton.apply(Pathfork, Tombstone, Merrill);
        Somis.apply(Pathfork, Tombstone, Exton);
        Aptos.apply(Pathfork, Tombstone, Merrill);
        Lacombe.apply(Pathfork, Tombstone);
        Clifton.apply(Pathfork, Tombstone);
        Kingsland.apply(Pathfork, Tombstone);
        Eaton.apply(Pathfork, Tombstone);
        Trevorton.apply(Pathfork, Tombstone);
        Fordyce.apply(Pathfork, Tombstone);
        Ugashik.apply(Pathfork, Tombstone);
        Rhodell.apply(Pathfork, Tombstone, Exton);
        Heizer.apply(Pathfork, Tombstone);
        Monse.apply();
        if (Tombstone.Coulter.Hackett == 1w0) {
            Froid.apply(Pathfork, Tombstone, Merrill);
        }
        Hector.apply(Pathfork, Tombstone, Merrill);
        if (Tombstone.Coulter.Bushland == 3w0 || Tombstone.Coulter.Bushland == 3w3) {
            Wentworth.apply();
        }
        Wakefield.apply(Pathfork, Tombstone);
        if (Tombstone.Tenino.Kalida & 15w0x7ff0 != 15w0) {
            Kalida.apply();
        }
        if (Tombstone.Algoa.Higginson == 1w1 && Tombstone.Pridgen.Newfane == 1w0) {
            Bostic.apply();
        }
        if (Tombstone.Uvalde.Killen != 2w0) {
            Miltona.apply(Pathfork, Tombstone, Merrill);
        }
        Wakeman.apply(Pathfork, Tombstone, Exton, Merrill);
        Chilson.apply(Pathfork, Tombstone, Exton, Merrill);
        if (Pathfork.Lapoint[0].isValid() && Tombstone.Coulter.Bushland != 3w2) {
            Reynolds.apply(Pathfork);
        }
        Kosmos.apply(Tombstone, Exton, LaUnion);
        Ironia.apply(Pathfork, Tombstone, Exton, Merrill, LaUnion);
        BigFork.apply(Pathfork, Tombstone, Merrill);
        {
            WestEnd();
        }
    }
}

control Kenvil(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Rhine(bit<32> Osterdock, bit<32> LaJara) {
        Tombstone.Coulter.Spearman = Osterdock;
        Tombstone.Coulter.Chevak = LaJara;
    }
    action Bammel(bit<24> Caroleen, bit<8> Lordstown) {
        Tombstone.Coulter.Ronda = Caroleen;
        Tombstone.Coulter.LaPalma = Lordstown;
    }
    table Mendoza {
        actions = {
            Rhine();
        }
        key = {
            Tombstone.Coulter.Dugger & 32w0x1: exact;
        }
        size = 1;
        default_action = Rhine(32w0, 32w0);
    }
    table Paragonah {
        actions = {
            Bammel();
        }
        key = {
            Tombstone.Coulter.Kaluaaha: exact;
        }
        size = 4096;
        default_action = Bammel(24w0, 8w0);
    }
    apply {
        if (Tombstone.Coulter.Dugger & 32w0xc0000 != 32w0) {
            if (Tombstone.Coulter.Dugger & 32w0x20000 == 32w0) {
                Mendoza.apply();
            }
            else {
            }
        }
        Paragonah.apply();
    }
}

control DeRidder(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Bechyn(bit<24> Duchesne, bit<24> Centre, bit<12> Pocopson) {
        Tombstone.Coulter.Eldred = Duchesne;
        Tombstone.Coulter.Chloride = Centre;
        Tombstone.Coulter.Kaluaaha = Pocopson;
    }
    table Barnwell {
        actions = {
            Bechyn();
        }
        key = {
            Tombstone.Coulter.Dugger & 32w0xff000000: exact;
        }
        size = 256;
        default_action = Bechyn(24w0, 24w0, 12w0);
    }
    apply {
        Barnwell.apply();
    }
}

control Tulsa(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Cropper(bit<32> Beeler, bit<32> Slinger) {
        Pathfork.Traverse.Eastwood = Beeler;
        Pathfork.Traverse.Placedo[31:16] = Slinger[31:16];
        Pathfork.Traverse.Onycha[3:0] = (Tombstone.Coulter.Spearman >> 16)[3:0];
        Pathfork.Traverse.Delavan = Tombstone.Coulter.Chevak;
    }
    action Maddock() {
        ;
    }
    table Lovelady {
        actions = {
            Cropper();
            @defaultonly Maddock();
        }
        key = {
            Tombstone.Coulter.Spearman & 32w0xff000000: exact;
        }
        size = 256;
        default_action = Maddock();
    }
    apply {
        if (Tombstone.Coulter.Dugger & 32w0xc0000 == 32w0x80000) {
            Lovelady.apply();
        }
    }
}

control PellCity(inout Hematite Pathfork, inout Daphne Tombstone, in egress_intrinsic_metadata_t Lebanon, in egress_intrinsic_metadata_from_parser_t Siloam) {
    Counter<bit<64>, bit<12>>(32w4096, CounterType_t.PACKETS_AND_BYTES) Ozark;
    Hash<bit<12>>(HashAlgorithm_t.IDENTITY) Daleville;
    action Hagewood() {
        {
            bit<12> Blakeman;
            Blakeman = Daleville.get<tuple<bit<9>, bit<5>>>({ Lebanon.egress_port, Lebanon.egress_qid });
            Ozark.count(Blakeman);
        }
        Tombstone.Coulter.Weinert[15:0] = ((bit<16>)Siloam.global_tstamp)[15:0];
    }
    table Palco {
        actions = {
            Hagewood();
        }
        size = 1;
        default_action = Hagewood();
    }
    apply {
        Palco.apply();
    }
}

control Melder(inout Hematite Pathfork, inout Daphne Tombstone, in egress_intrinsic_metadata_t Lebanon) {
    action FourTown(bit<12> Pocopson) {
        Tombstone.Coulter.Kaluaaha = Pocopson;
        Tombstone.Coulter.Albemarle = 1w1;
    }
    action Rhine(bit<32> Osterdock, bit<32> LaJara) {
        Tombstone.Coulter.Spearman = Osterdock;
        Tombstone.Coulter.Chevak = LaJara;
    }
    action Bechyn(bit<24> Duchesne, bit<24> Centre, bit<12> Pocopson) {
        Tombstone.Coulter.Eldred = Duchesne;
        Tombstone.Coulter.Chloride = Centre;
        Tombstone.Coulter.Kaluaaha = Pocopson;
    }
    action Hyrum(bit<32> Mendoza, bit<24> Paisano, bit<24> Boquillas, bit<12> Pocopson, bit<3> Ocoee) {
        Rhine(Mendoza, Mendoza);
        Bechyn(Paisano, Boquillas, Pocopson);
        Tombstone.Coulter.Ocoee = Ocoee;
    }
    action Maddock() {
        ;
    }
    @ways(2) table Farner {
        actions = {
            FourTown();
            @defaultonly NoAction();
        }
        key = {
            Lebanon.egress_rid: exact;
        }
        size = 16384;
        default_action = NoAction();
    }
    table Mondovi {
        actions = {
            Hyrum();
            @defaultonly Maddock();
        }
        key = {
            Lebanon.egress_rid: exact;
        }
        size = 4096;
        default_action = Maddock();
    }
    apply {
        if (Lebanon.egress_rid != 16w0) {
            switch (Mondovi.apply().action_run) {
                Maddock: {
                    Farner.apply();
                }
            }

        }
    }
}

control Lynne(inout Hematite Pathfork, inout Daphne Tombstone, in egress_intrinsic_metadata_t Lebanon) {
    action OldTown(bit<10> Larwill) {
        Tombstone.DonaAna.Joslin = Larwill;
    }
    table Govan {
        actions = {
            OldTown();
        }
        key = {
            Lebanon.egress_port: exact;
        }
        size = 128;
        default_action = OldTown(10w0);
    }
    apply {
        Govan.apply();
    }
}

control Gladys(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Rumson(bit<6> Alameda) {
        Tombstone.Juniata.Antlers = Alameda;
    }
    @ternary(1) table McKee {
        actions = {
            Rumson();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Merrill.Churchill: exact;
        }
        size = 8;
        default_action = NoAction();
    }
    apply {
        McKee.apply();
    }
}

control Bigfork(inout Hematite Pathfork, inout Daphne Tombstone) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) Jauca;
    action Brownson() {
        Jauca.count();
        ;
    }
    table Punaluu {
        actions = {
            Brownson();
        }
        key = {
            Tombstone.Coulter.Bushland: exact;
            Tombstone.Algoa.Dixboro   : exact;
        }
        size = 512;
        default_action = Brownson();
        counters = Jauca;
    }
    apply {
        if (Tombstone.Coulter.Albemarle == 1w1) {
            Punaluu.apply();
        }
    }
}

control Linville(inout Hematite Pathfork, inout Daphne Tombstone) {
    Meter<bit<32>>(32w128, MeterType_t.BYTES) Kelliher;
    action Hopeton(bit<32> Mattapex) {
        Tombstone.DonaAna.Powderly = (bit<2>)Kelliher.execute((bit<32>)Mattapex);
    }
    action Bernstein() {
        Tombstone.DonaAna.Powderly = (bit<2>)2w2;
    }
    @ternary(1) table Kingman {
        actions = {
            Hopeton();
            Bernstein();
        }
        key = {
            Tombstone.DonaAna.Weyauwega: exact;
        }
        size = 1024;
        default_action = Bernstein();
    }
    apply {
        Kingman.apply();
    }
}

control Lyman(inout Hematite Pathfork, inout Daphne Tombstone, in egress_intrinsic_metadata_t Lebanon) {
    action BirchRun(bit<12> Norwood) {
        Tombstone.Coulter.Norwood = Norwood;
    }
    action Portales(bit<12> Norwood) {
        Tombstone.Coulter.Norwood = Norwood;
        Tombstone.Coulter.Topanga = 1w1;
    }
    action Owentown() {
        Tombstone.Coulter.Norwood = Tombstone.Coulter.Kaluaaha;
    }
    table Basye {
        actions = {
            BirchRun();
            Portales();
            Owentown();
        }
        key = {
            Lebanon.egress_port & 9w0x7f: exact;
            Tombstone.Coulter.Kaluaaha  : exact;
        }
        size = 16;
        default_action = Owentown();
    }
    apply {
        Basye.apply();
    }
}

control Woolwine(inout Hematite Pathfork, inout Daphne Tombstone, in egress_intrinsic_metadata_t Lebanon) {
    action Agawam() {
        Tombstone.Coulter.Bushland = (bit<3>)3w0;
        Tombstone.Coulter.Ocoee = (bit<3>)3w3;
    }
    action Berlin(bit<8> Ardsley) {
        Tombstone.Coulter.Loring = Ardsley;
        Tombstone.Coulter.Allison = (bit<1>)1w1;
        Tombstone.Coulter.Bushland = (bit<3>)3w0;
        Tombstone.Coulter.Ocoee = (bit<3>)3w2;
        Tombstone.Coulter.Algodones = (bit<1>)1w1;
        Tombstone.Coulter.Albemarle = (bit<1>)1w0;
    }
    action Astatula(bit<32> Brinson, bit<32> Westend, bit<8> Davie, bit<6> Alameda, bit<16> Scotland, bit<12> Norwood, bit<24> Paisano, bit<24> Boquillas) {
        Tombstone.Coulter.Bushland = (bit<3>)3w0;
        Tombstone.Coulter.Ocoee = (bit<3>)3w4;
        Pathfork.Brainard.setValid();
        Pathfork.Brainard.Guadalupe = (bit<4>)4w0x4;
        Pathfork.Brainard.Buckfield = (bit<4>)4w0x5;
        Pathfork.Brainard.Alameda = Alameda;
        Pathfork.Brainard.Rugby = (bit<8>)8w47;
        Pathfork.Brainard.Davie = Davie;
        Pathfork.Brainard.Weinert = (bit<16>)16w0;
        Pathfork.Brainard.Parkville = (bit<3>)3w0;
        Pathfork.Brainard.Moquah = (bit<13>)13w0;
        Pathfork.Brainard.Fayette = Brinson;
        Pathfork.Brainard.Osterdock = Westend;
        Pathfork.Brainard.Rayville = Lebanon.pkt_length + 16w15;
        Pathfork.Pachuta.setValid();
        Pathfork.Pachuta.Kenbridge = Scotland;
        Tombstone.Coulter.Norwood = Norwood;
        Tombstone.Coulter.Paisano = Paisano;
        Tombstone.Coulter.Boquillas = Boquillas;
        Tombstone.Coulter.Albemarle = (bit<1>)1w0;
    }
    @ternary(1) table Addicks {
        actions = {
            Agawam();
            Berlin();
            Astatula();
            @defaultonly NoAction();
        }
        key = {
            Lebanon.egress_rid : exact;
            Lebanon.egress_port: exact;
        }
        size = 256;
        default_action = NoAction();
    }
    apply {
        Addicks.apply();
    }
}

control Wyandanch(inout Hematite Pathfork, inout Daphne Tombstone, in egress_intrinsic_metadata_t Lebanon, inout egress_intrinsic_metadata_for_deparser_t Vananda) {
    action Yorklyn(bit<2> Lacona) {
        Tombstone.Coulter.Algodones = (bit<1>)1w1;
        Tombstone.Coulter.Ocoee = (bit<3>)3w2;
        Tombstone.Coulter.Lacona = Lacona;
        Tombstone.Coulter.Idalia = (bit<2>)2w0;
    }
    action Maddock() {
        ;
    }
    action Botna() {
        Vananda.drop_ctl = (bit<3>)3w0x1;
    }
    action Chappell(bit<24> Estero, bit<24> Inkom) {
        Pathfork.McCammon.Paisano = Tombstone.Coulter.Paisano;
        Pathfork.McCammon.Boquillas = Tombstone.Coulter.Boquillas;
        Pathfork.McCammon.McCaulley = Estero;
        Pathfork.McCammon.Everton = Inkom;
    }
    action Gowanda(bit<24> Estero, bit<24> Inkom) {
        Chappell(Estero, Inkom);
        Pathfork.Brainard.Davie = Pathfork.Brainard.Davie - 8w1;
    }
    action BurrOak(bit<24> Estero, bit<24> Inkom) {
        Chappell(Estero, Inkom);
        Pathfork.Fristoe.Soledad = Pathfork.Fristoe.Soledad - 8w1;
    }
    action Gardena() {
    }
    action Verdery() {
    }
    action Onamia() {
        Pathfork.Clover.setInvalid();
        Pathfork.Ralls.setInvalid();
        Pathfork.Blairsden.setInvalid();
        Pathfork.Whitefish.setInvalid();
        Pathfork.McCammon = Pathfork.Barrow;
        Pathfork.Barrow.setInvalid();
        Pathfork.Brainard.setInvalid();
        Pathfork.Fristoe.setInvalid();
    }
    action Brule(bit<8> Loring) {
        Pathfork.Ipava.setValid();
        Pathfork.Ipava.Allison = Tombstone.Coulter.Allison;
        Pathfork.Ipava.Loring = Loring;
        Pathfork.Ipava.Brinklow = Tombstone.Algoa.Roosville;
        Pathfork.Ipava.Lacona = Tombstone.Coulter.Lacona;
        Pathfork.Ipava.Chaffee = Tombstone.Coulter.Idalia;
    }
    action Durant(bit<8> Loring) {
        Onamia();
        Brule(Loring);
    }
    action Kingsdale() {
        Pathfork.Lapoint[0].setValid();
        Pathfork.Lapoint[0].Norwood = Tombstone.Coulter.Norwood;
        Pathfork.Lapoint[0].Lafayette = Pathfork.McCammon.Lafayette;
        Pathfork.Lapoint[0].Weatherby = Tombstone.Juniata.Tallassee;
        Pathfork.Lapoint[0].Irvine = Tombstone.Juniata.Irvine;
        Pathfork.McCammon.Lafayette = (bit<16>)16w0x8100;
    }
    action Tekonsha() {
        Kingsdale();
    }
    action Clermont() {
        Pathfork.Brainard.setInvalid();
    }
    action Blanding() {
        Clermont();
        Pathfork.McCammon.Lafayette = (bit<16>)16w0x800;
        Brule(Tombstone.Coulter.Loring);
    }
    action Ocilla() {
        Clermont();
        Pathfork.McCammon.Lafayette = (bit<16>)16w0x86dd;
        Brule(Tombstone.Coulter.Loring);
    }
    action Shelby() {
        Brule(Tombstone.Coulter.Loring);
    }
    action Chambers() {
        Pathfork.McCammon.Boquillas = Pathfork.McCammon.Boquillas;
    }
    action Ardenvoir(bit<24> Estero, bit<24> Inkom) {
        Pathfork.Clover.setInvalid();
        Pathfork.Ralls.setInvalid();
        Pathfork.Blairsden.setInvalid();
        Pathfork.Whitefish.setInvalid();
        Pathfork.Brainard.setInvalid();
        Pathfork.Fristoe.setInvalid();
        Pathfork.McCammon.Paisano = Tombstone.Coulter.Paisano;
        Pathfork.McCammon.Boquillas = Tombstone.Coulter.Boquillas;
        Pathfork.McCammon.McCaulley = Estero;
        Pathfork.McCammon.Everton = Inkom;
        Pathfork.McCammon.Lafayette = Pathfork.Barrow.Lafayette;
        Pathfork.Barrow.setInvalid();
    }
    action Clinchco(bit<24> Estero, bit<24> Inkom) {
        Ardenvoir(Estero, Inkom);
        Pathfork.Foster.Davie = Pathfork.Foster.Davie - 8w1;
    }
    action Snook(bit<24> Estero, bit<24> Inkom) {
        Ardenvoir(Estero, Inkom);
        Pathfork.Raiford.Soledad = Pathfork.Raiford.Soledad - 8w1;
    }
    action OjoFeliz(bit<24> Estero, bit<24> Inkom) {
        Pathfork.Brainard.setInvalid();
        Pathfork.McCammon.Paisano = Tombstone.Coulter.Paisano;
        Pathfork.McCammon.Boquillas = Tombstone.Coulter.Boquillas;
        Pathfork.McCammon.McCaulley = Estero;
        Pathfork.McCammon.Everton = Inkom;
    }
    action Havertown(bit<24> Estero, bit<24> Inkom) {
        OjoFeliz(Estero, Inkom);
        Pathfork.McCammon.Lafayette = (bit<16>)16w0x800;
        Pathfork.Foster.Davie = Pathfork.Foster.Davie - 8w1;
    }
    action Napanoch(bit<24> Estero, bit<24> Inkom) {
        OjoFeliz(Estero, Inkom);
        Pathfork.McCammon.Lafayette = (bit<16>)16w0x86dd;
        Pathfork.Raiford.Soledad = Pathfork.Raiford.Soledad - 8w1;
    }
    action Pearcy(bit<16> Westhoff, bit<16> Ghent, bit<24> McCaulley, bit<24> Everton, bit<24> Estero, bit<24> Inkom, bit<16> Protivin) {
        Pathfork.Barrow.Paisano = Tombstone.Coulter.Paisano;
        Pathfork.Barrow.Boquillas = Tombstone.Coulter.Boquillas;
        Pathfork.Barrow.McCaulley = McCaulley;
        Pathfork.Barrow.Everton = Everton;
        Pathfork.Ralls.Westhoff = Westhoff + Ghent;
        Pathfork.Blairsden.Chatmoss = (bit<16>)16w0;
        Pathfork.Whitefish.Harbor = Tombstone.Coulter.Maryhill;
        Pathfork.Whitefish.Aguilita = Tombstone.Halaula.Conner + Protivin;
        Pathfork.Clover.Parkville = (bit<8>)8w0x8;
        Pathfork.Clover.Etter = (bit<24>)24w0;
        Pathfork.Clover.Caroleen = Tombstone.Coulter.Ronda;
        Pathfork.Clover.TroutRun = Tombstone.Coulter.LaPalma;
        Pathfork.McCammon.Paisano = Tombstone.Coulter.Eldred;
        Pathfork.McCammon.Boquillas = Tombstone.Coulter.Chloride;
        Pathfork.McCammon.McCaulley = Estero;
        Pathfork.McCammon.Everton = Inkom;
    }
    action Medart(bit<16> Waseca, bit<16> Haugen) {
        Pathfork.Brainard.Guadalupe = (bit<4>)4w0x4;
        Pathfork.Brainard.Buckfield = (bit<4>)4w0x5;
        Pathfork.Brainard.Alameda = (bit<6>)6w0;
        Pathfork.Brainard.Commack = (bit<2>)2w0;
        Pathfork.Brainard.Rayville = Waseca + Haugen;
        Pathfork.Brainard.Weinert = Tombstone.Coulter.Weinert;
        Pathfork.Brainard.Parkville = (bit<3>)3w0x2;
        Pathfork.Brainard.Moquah = (bit<13>)13w0;
        Pathfork.Brainard.Davie = (bit<8>)8w64;
        Pathfork.Brainard.Rugby = (bit<8>)8w17;
        Pathfork.Brainard.Fayette = Tombstone.Coulter.Cecilton;
        Pathfork.Brainard.Osterdock = Tombstone.Coulter.Spearman;
        Pathfork.McCammon.Lafayette = (bit<16>)16w0x800;
    }
    action Goldsmith(bit<24> McCaulley, bit<24> Everton, bit<16> Protivin) {
        Pearcy(Pathfork.Ralls.Westhoff, 16w0, McCaulley, Everton, McCaulley, Everton, Protivin);
        Medart(Pathfork.Brainard.Rayville, 16w0);
    }
    action Encinitas(bit<24> Estero, bit<24> Inkom, bit<16> Protivin) {
        Goldsmith(Estero, Inkom, Protivin);
        Pathfork.Foster.Davie = Pathfork.Foster.Davie - 8w1;
    }
    action Issaquah(bit<24> Estero, bit<24> Inkom, bit<16> Protivin) {
        Goldsmith(Estero, Inkom, Protivin);
        Pathfork.Raiford.Soledad = Pathfork.Raiford.Soledad - 8w1;
    }
    action Herring(bit<8> Davie) {
        Pathfork.Foster.Guadalupe = Pathfork.Brainard.Guadalupe;
        Pathfork.Foster.Buckfield = Pathfork.Brainard.Buckfield;
        Pathfork.Foster.Alameda = Pathfork.Brainard.Alameda;
        Pathfork.Foster.Commack = Pathfork.Brainard.Commack;
        Pathfork.Foster.Rayville = Pathfork.Brainard.Rayville;
        Pathfork.Foster.Weinert = Pathfork.Brainard.Weinert;
        Pathfork.Foster.Parkville = Pathfork.Brainard.Parkville;
        Pathfork.Foster.Moquah = Pathfork.Brainard.Moquah;
        Pathfork.Foster.Davie = Pathfork.Brainard.Davie + Davie;
        Pathfork.Foster.Rugby = Pathfork.Brainard.Rugby;
        Pathfork.Foster.Fayette = Pathfork.Brainard.Fayette;
        Pathfork.Foster.Osterdock = Pathfork.Brainard.Osterdock;
    }
    action Wattsburg(bit<16> Westhoff, bit<16> DeBeque, bit<24> McCaulley, bit<24> Everton, bit<24> Estero, bit<24> Inkom, bit<16> Protivin) {
        Pathfork.Barrow.setValid();
        Pathfork.Ralls.setValid();
        Pathfork.Blairsden.setValid();
        Pathfork.Whitefish.setValid();
        Pathfork.Clover.setValid();
        Pathfork.Barrow.Lafayette = Pathfork.McCammon.Lafayette;
        Pearcy(Westhoff, DeBeque, McCaulley, Everton, Estero, Inkom, Protivin);
    }
    action Truro(bit<16> Westhoff, bit<16> DeBeque, bit<16> Plush, bit<24> McCaulley, bit<24> Everton, bit<24> Estero, bit<24> Inkom, bit<16> Protivin) {
        Wattsburg(Westhoff, DeBeque, McCaulley, Everton, Estero, Inkom, Protivin);
        Medart(Westhoff, Plush);
    }
    action Bethune(bit<24> Estero, bit<24> Inkom, bit<16> Protivin) {
        Pathfork.Brainard.setValid();
        Truro(Lebanon.pkt_length, 16w12, 16w32, Pathfork.McCammon.McCaulley, Pathfork.McCammon.Everton, Estero, Inkom, Protivin);
    }
    action PawCreek(bit<24> Estero, bit<24> Inkom, bit<16> Protivin) {
        Pathfork.Foster.setValid();
        Herring(8w0);
        Bethune(Estero, Inkom, Protivin);
    }
    action Cornwall(bit<8> Davie) {
        Pathfork.Raiford.Guadalupe = Pathfork.Fristoe.Guadalupe;
        Pathfork.Raiford.Alameda = Pathfork.Fristoe.Alameda;
        Pathfork.Raiford.Commack = Pathfork.Fristoe.Commack;
        Pathfork.Raiford.Randall = Pathfork.Fristoe.Randall;
        Pathfork.Raiford.Sheldahl = Pathfork.Fristoe.Sheldahl;
        Pathfork.Raiford.Palatine = Pathfork.Fristoe.Palatine;
        Pathfork.Raiford.Fayette = Pathfork.Fristoe.Fayette;
        Pathfork.Raiford.Osterdock = Pathfork.Fristoe.Osterdock;
        Pathfork.Raiford.Soledad = Pathfork.Fristoe.Soledad + Davie;
    }
    action Langhorne(bit<24> Estero, bit<24> Inkom, bit<16> Protivin) {
        Pathfork.Raiford.setValid();
        Cornwall(8w0);
        Pathfork.Fristoe.setInvalid();
        Bethune(Estero, Inkom, Protivin);
    }
    action Comobabi(bit<24> Estero, bit<24> Inkom, bit<16> Protivin) {
        Pathfork.Foster.setValid();
        Herring(8w255);
        Truro(Pathfork.Brainard.Rayville, 16w30, 16w50, Estero, Inkom, Estero, Inkom, Protivin);
    }
    action Bovina(bit<24> Estero, bit<24> Inkom, bit<16> Protivin) {
        Pathfork.Raiford.setValid();
        Cornwall(8w255);
        Pathfork.Brainard.setValid();
        Truro(Lebanon.pkt_length, 16w12, 16w32, Estero, Inkom, Estero, Inkom, Protivin);
        Pathfork.Fristoe.setInvalid();
    }
    action Natalbany(bit<24> Estero, bit<24> Inkom) {
        Pathfork.McCammon.setValid();
        Pathfork.McCammon.Paisano = Tombstone.Coulter.Paisano;
        Pathfork.McCammon.Boquillas = Tombstone.Coulter.Boquillas;
        Pathfork.McCammon.McCaulley = Estero;
        Pathfork.McCammon.Everton = Inkom;
        Pathfork.McCammon.Lafayette = (bit<16>)16w0x800;
    }
    action Lignite() {
        Pathfork.McCammon.Paisano = Pathfork.McCammon.Paisano;
        ;
    }
    action Clarkdale(bit<16> Waseca, bit<16> Haugen, bit<32> Nenana, bit<32> Morstein, bit<32> Waubun, bit<32> Minto) {
        Pathfork.Traverse.setValid();
        Pathfork.Traverse.Guadalupe = (bit<4>)4w0x6;
        Pathfork.Traverse.Alameda = (bit<6>)6w0;
        Pathfork.Traverse.Commack = (bit<2>)2w0;
        Pathfork.Traverse.Randall = (bit<20>)20w0;
        Pathfork.Traverse.Sheldahl = Waseca + Haugen;
        Pathfork.Traverse.Palatine = (bit<8>)8w17;
        Pathfork.Traverse.Nenana = Nenana;
        Pathfork.Traverse.Morstein = Morstein;
        Pathfork.Traverse.Waubun = Waubun;
        Pathfork.Traverse.Minto = Minto;
        Pathfork.Traverse.Placedo[15:0] = Tombstone.Coulter.Spearman[15:0];
        Pathfork.Traverse.Onycha[31:4] = (bit<28>)28w0;
        Pathfork.Traverse.Soledad = (bit<8>)8w64;
        Pathfork.McCammon.Lafayette = (bit<16>)16w0x86dd;
    }
    action Talbert(bit<16> Westhoff, bit<16> DeBeque, bit<16> Brunson, bit<24> McCaulley, bit<24> Everton, bit<24> Estero, bit<24> Inkom, bit<32> Nenana, bit<32> Morstein, bit<32> Waubun, bit<32> Minto, bit<16> Protivin) {
        Pathfork.Brainard.setInvalid();
        Wattsburg(Westhoff, DeBeque, McCaulley, Everton, Estero, Inkom, Protivin);
        Clarkdale(Westhoff, Brunson, Nenana, Morstein, Waubun, Minto);
    }
    action Catlin(bit<24> Estero, bit<24> Inkom, bit<32> Nenana, bit<32> Morstein, bit<32> Waubun, bit<32> Minto, bit<16> Protivin) {
        Talbert(Lebanon.pkt_length, 16w12, 16w12, Pathfork.McCammon.McCaulley, Pathfork.McCammon.Everton, Estero, Inkom, Nenana, Morstein, Waubun, Minto, Protivin);
    }
    action Antoine(bit<24> Estero, bit<24> Inkom, bit<32> Nenana, bit<32> Morstein, bit<32> Waubun, bit<32> Minto, bit<16> Protivin) {
        Pathfork.Foster.setValid();
        Herring(8w0);
        Talbert(Pathfork.Brainard.Rayville, 16w30, 16w30, Pathfork.McCammon.McCaulley, Pathfork.McCammon.Everton, Estero, Inkom, Nenana, Morstein, Waubun, Minto, Protivin);
    }
    action Romeo(bit<24> Estero, bit<24> Inkom, bit<32> Nenana, bit<32> Morstein, bit<32> Waubun, bit<32> Minto, bit<16> Protivin) {
        Pathfork.Foster.setValid();
        Herring(8w255);
        Talbert(Pathfork.Brainard.Rayville, 16w30, 16w30, Estero, Inkom, Estero, Inkom, Nenana, Morstein, Waubun, Minto, Protivin);
    }
    action Caspian(bit<24> Estero, bit<24> Inkom, bit<32> Nenana, bit<32> Morstein, bit<32> Waubun, bit<32> Minto, bit<16> Protivin) {
        Pearcy(Pathfork.Ralls.Westhoff, 16w0, Estero, Inkom, Estero, Inkom, Protivin);
        Clarkdale(Lebanon.pkt_length, 16w65478, Nenana, Morstein, Waubun, Minto);
        Pathfork.Fristoe.setInvalid();
        Pathfork.Foster.Davie = Pathfork.Foster.Davie - 8w1;
    }
    action Norridge(bit<24> Estero, bit<24> Inkom, bit<32> Nenana, bit<32> Morstein, bit<32> Waubun, bit<32> Minto, bit<16> Protivin) {
        Pearcy(Pathfork.Ralls.Westhoff, 16w0, Estero, Inkom, Estero, Inkom, Protivin);
        Clarkdale(Lebanon.pkt_length, 16w65498, Nenana, Morstein, Waubun, Minto);
        Pathfork.Brainard.setInvalid();
        Pathfork.Foster.Davie = Pathfork.Foster.Davie - 8w1;
    }
    action Lowemont(bit<24> Estero, bit<24> Inkom, bit<16> Protivin) {
        Pathfork.Brainard.setValid();
        Pearcy(Pathfork.Ralls.Westhoff, 16w0, Estero, Inkom, Estero, Inkom, Protivin);
        Medart(Lebanon.pkt_length, 16w65498);
        Pathfork.Fristoe.setInvalid();
        Pathfork.Foster.Davie = Pathfork.Foster.Davie - 8w1;
    }
    action Wauregan(bit<16> Harbor, bit<16> CassCity, bit<16> Sanborn) {
        Tombstone.Coulter.Maryhill = Harbor;
        Tombstone.Halaula.Conner = Tombstone.Halaula.Conner & Sanborn;
    }
    action Kerby(bit<32> Cecilton, bit<16> Harbor, bit<16> CassCity, bit<16> Sanborn) {
        Tombstone.Coulter.Cecilton = Cecilton;
        Wauregan(Harbor, CassCity, Sanborn);
    }
    action Saxis(bit<32> Cecilton, bit<16> Harbor, bit<16> CassCity, bit<16> Sanborn) {
        Tombstone.Coulter.Spearman = Tombstone.Coulter.Chevak;
        Tombstone.Coulter.Cecilton = Cecilton;
        Wauregan(Harbor, CassCity, Sanborn);
    }
    action Langford(bit<16> CassCity) {
    }
    action Cowley(bit<6> Lackey, bit<10> Trion, bit<4> Baldridge, bit<12> Carlson) {
        Pathfork.Ipava.Luzerne = Lackey;
        Pathfork.Ipava.Devers = Trion;
        Pathfork.Ipava.Crozet = Baldridge;
        Pathfork.Ipava.Laxon = Carlson;
    }
    @ternary(1) table Ivanpah {
        actions = {
            Yorklyn();
            @defaultonly Maddock();
        }
        key = {
            Lebanon.egress_port       : exact;
            Tombstone.Uvalde.Littleton: exact;
            Tombstone.Coulter.Buckeye : exact;
            Tombstone.Coulter.Bushland: exact;
        }
        size = 32;
        default_action = Maddock();
    }
    table Kevil {
        actions = {
            Botna();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Coulter.Garibaldi : exact;
            Lebanon.egress_port & 9w0x7f: exact;
        }
        size = 512;
        default_action = NoAction();
    }
    table Newland {
        actions = {
            Gowanda();
            BurrOak();
            Gardena();
            Verdery();
            Durant();
            Tekonsha();
            Blanding();
            Ocilla();
            Shelby();
            Chambers();
            Onamia();
            Clinchco();
            Snook();
            Havertown();
            Napanoch();
            Encinitas();
            Issaquah();
            PawCreek();
            Langhorne();
            Comobabi();
            Bovina();
            Bethune();
            Natalbany();
            Lignite();
            Catlin();
            Antoine();
            Romeo();
            Caspian();
            Norridge();
            Lowemont();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Coulter.Bushland           : exact;
            Tombstone.Coulter.Ocoee              : exact;
            Tombstone.Coulter.Albemarle          : exact;
            Pathfork.Brainard.isValid()          : ternary;
            Pathfork.Fristoe.isValid()           : ternary;
            Pathfork.Foster.isValid()            : ternary;
            Pathfork.Raiford.isValid()           : ternary;
            Tombstone.Coulter.Dugger & 32w0xc0000: ternary;
        }
        size = 512;
        default_action = NoAction();
    }
    @no_egress_length_correct(1) @ternary(1) table Waumandee {
        actions = {
            Wauregan();
            Kerby();
            Saxis();
            Langford();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Coulter.Bushland           : ternary;
            Tombstone.Coulter.Ocoee              : exact;
            Tombstone.Coulter.Buckeye            : ternary;
            Tombstone.Coulter.Dugger & 32w0x50000: ternary;
        }
        size = 16;
        default_action = NoAction();
    }
    @ternary(1) table Nowlin {
        actions = {
            Cowley();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Coulter.Horton: exact;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        switch (Ivanpah.apply().action_run) {
            Maddock: {
                Waumandee.apply();
            }
        }

        Nowlin.apply();
        if (Tombstone.Coulter.Albemarle == 1w0 && Tombstone.Coulter.Bushland == 3w0 && Tombstone.Coulter.Ocoee == 3w0) {
            Kevil.apply();
        }
        Newland.apply();
    }
}

control Sully(inout Hematite Pathfork, inout Daphne Tombstone) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) Ragley;
    action Dunkerton() {
        Ragley.count();
        ;
    }
    table Gunder {
        actions = {
            Dunkerton();
        }
        key = {
            Tombstone.Coulter.Bushland & 3w0x1: exact;
            Tombstone.Coulter.Kaluaaha        : exact;
        }
        size = 512;
        default_action = Dunkerton();
        counters = Ragley;
    }
    apply {
        if (Tombstone.Coulter.Albemarle == 1w1) {
            Gunder.apply();
        }
    }
}

Register<bit<1>, bit<32>>(32w294912, 1w0) Maury;

Register<bit<1>, bit<32>>(32w294912, 1w0) Ashburn;

control Estrella(inout Hematite Pathfork, inout Daphne Tombstone, in egress_intrinsic_metadata_t Lebanon) {
    RegisterAction<bit<1>, bit<32>, bit<1>>(Maury) Luverne = {
        void apply(inout bit<1> Ackley, out bit<1> Knoke) {
            Knoke = 1w0;
            bit<1> McAllen;
            McAllen = Ackley;
            Ackley = McAllen;
            Knoke = Ackley;
        }
    };
    RegisterAction<bit<1>, bit<32>, bit<1>>(Ashburn) Amsterdam = {
        void apply(inout bit<1> Ackley, out bit<1> Knoke) {
            Knoke = 1w0;
            bit<1> McAllen;
            McAllen = Ackley;
            Ackley = McAllen;
            Knoke = ~Ackley;
        }
    };
    Hash<bit<19>>(HashAlgorithm_t.IDENTITY) Daleville;
    action Gwynn() {
        {
            bit<19> Rolla;
            Rolla = Daleville.get<tuple<bit<9>, bit<12>>>({ Lebanon.egress_port, Tombstone.Coulter.Norwood });
            Tombstone.Altus.Loris = Luverne.execute((bit<32>)Rolla);
        }
    }
    action Brookwood() {
        {
            bit<19> Granville;
            Granville = Daleville.get<tuple<bit<9>, bit<12>>>({ Lebanon.egress_port, Tombstone.Coulter.Norwood });
            Tombstone.Altus.Pilar = Amsterdam.execute((bit<32>)Granville);
        }
    }
    table Council {
        actions = {
            Gwynn();
        }
        size = 1;
        default_action = Gwynn();
    }
    table Capitola {
        actions = {
            Brookwood();
        }
        size = 1;
        default_action = Brookwood();
    }
    apply {
        Capitola.apply();
        Council.apply();
    }
}

control Liberal(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Doyline(bit<10> Ossining) {
        Tombstone.DonaAna.Joslin = Tombstone.DonaAna.Joslin | Ossining;
    }
    Hash<bit<16>>(HashAlgorithm_t.CRC16) Belcourt;
    ActionSelector(32w1024, Belcourt, SelectorMode_t.RESILIENT) Moorman;
    @ternary(1) table Parmelee {
        actions = {
            Doyline();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.DonaAna.Joslin & 10w0x7f: exact;
            Tombstone.Halaula.Conner          : selector;
        }
        size = 128;
        implementation = Moorman;
        default_action = NoAction();
    }
    apply {
        Parmelee.apply();
    }
}

control Bagwell(inout Hematite Pathfork, inout Daphne Tombstone) {
    action Wright() {
        Pathfork.Brainard.Alameda = Tombstone.Juniata.Alameda;
    }
    action Stone() {
        Pathfork.Fristoe.Alameda = Tombstone.Juniata.Alameda;
    }
    action Milltown() {
        Pathfork.Foster.Alameda = Tombstone.Juniata.Alameda;
    }
    action TinCity() {
        Pathfork.Raiford.Alameda = Tombstone.Juniata.Alameda;
    }
    action Comunas() {
        Pathfork.Brainard.Alameda = Tombstone.Juniata.Antlers;
    }
    action Alcoma() {
        Comunas();
        Pathfork.Foster.Alameda = Tombstone.Juniata.Alameda;
    }
    action Kilbourne() {
        Comunas();
        Pathfork.Raiford.Alameda = Tombstone.Juniata.Alameda;
    }
    action Bluff() {
        Pathfork.Traverse.Alameda = Tombstone.Juniata.Antlers;
    }
    action Bedrock() {
        Bluff();
        Pathfork.Foster.Alameda = Tombstone.Juniata.Alameda;
    }
    table Silvertip {
        actions = {
            Wright();
            Stone();
            Milltown();
            TinCity();
            Comunas();
            Alcoma();
            Kilbourne();
            Bluff();
            Bedrock();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Coulter.Ocoee    : ternary;
            Tombstone.Coulter.Bushland : ternary;
            Tombstone.Coulter.Albemarle: ternary;
            Pathfork.Brainard.isValid(): ternary;
            Pathfork.Fristoe.isValid() : ternary;
            Pathfork.Foster.isValid()  : ternary;
            Pathfork.Raiford.isValid() : ternary;
        }
        size = 14;
        default_action = NoAction();
    }
    apply {
        Silvertip.apply();
    }
}

control Thatcher(inout Hematite Pathfork, inout Daphne Tombstone, in egress_intrinsic_metadata_t Lebanon, inout egress_intrinsic_metadata_for_deparser_t Vananda) {
    action Archer() {
        Tombstone.Coulter.Horton = Lebanon.egress_port;
        Tombstone.Algoa.Roosville = Tombstone.Coulter.Kaluaaha;
        Vananda.mirror_type = (bit<3>)3w1;
    }
    table Virginia {
        actions = {
            Archer();
        }
        size = 1;
        default_action = Archer();
    }
    apply {
        if (Tombstone.DonaAna.Joslin != 10w0 && Tombstone.DonaAna.Powderly == 2w0) {
            Virginia.apply();
        }
    }
}

control Cornish(inout Hematite Pathfork, inout Daphne Tombstone, in egress_intrinsic_metadata_t Lebanon, inout egress_intrinsic_metadata_for_deparser_t Vananda) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS) Hatchel;
    action Dougherty() {
        Hatchel.count();
        Vananda.drop_ctl = (bit<3>)3w0x1;
    }
    action Maddock() {
        Hatchel.count();
        ;
    }
    table Pelican {
        actions = {
            Dougherty();
            Maddock();
        }
        key = {
            Lebanon.egress_port & 9w0x7f: exact;
            Tombstone.Altus.Loris       : ternary;
            Tombstone.Altus.Pilar       : ternary;
            Tombstone.Juniata.Beasley   : ternary;
        }
        size = 256;
        default_action = Maddock();
        counters = Hatchel;
    }
    Thatcher() Unionvale;
    apply {
        switch (Pelican.apply().action_run) {
            Maddock: {
                Unionvale.apply(Pathfork, Tombstone, Lebanon, Vananda);
            }
        }

    }
}

control Bigspring(inout Hematite Pathfork, inout Daphne Tombstone, in egress_intrinsic_metadata_t Lebanon) {
    action Advance() {
        ;
    }
    action Kingsdale() {
        Pathfork.Lapoint[0].setValid();
        Pathfork.Lapoint[0].Norwood = Tombstone.Coulter.Norwood;
        Pathfork.Lapoint[0].Lafayette = Pathfork.McCammon.Lafayette;
        Pathfork.Lapoint[0].Weatherby = Tombstone.Juniata.Tallassee;
        Pathfork.Lapoint[0].Irvine = Tombstone.Juniata.Irvine;
        Pathfork.McCammon.Lafayette = (bit<16>)16w0x8100;
    }
    @ways(2) table Rockfield {
        actions = {
            Advance();
            Kingsdale();
        }
        key = {
            Tombstone.Coulter.Norwood   : exact;
            Lebanon.egress_port & 9w0x7f: exact;
            Tombstone.Coulter.Topanga   : exact;
        }
        size = 128;
        default_action = Kingsdale();
    }
    apply {
        Rockfield.apply();
    }
}

control Redfield(inout Hematite Pathfork, inout Daphne Tombstone, in egress_intrinsic_metadata_t Lebanon, in egress_intrinsic_metadata_from_parser_t Siloam, inout egress_intrinsic_metadata_for_deparser_t Vananda, inout egress_intrinsic_metadata_for_output_port_t Baskin) {
    action Wakenda() {
        Pathfork.Brainard.Rugby = Pathfork.Brainard.Rugby & 8w0x7f;
    }
    action Mynard() {
        Pathfork.Fristoe.Palatine = Pathfork.Fristoe.Palatine & 8w0x7f;
    }
    table Hoagland {
        actions = {
            Wakenda();
            Mynard();
            @defaultonly NoAction();
        }
        key = {
            Tombstone.Coulter.Hoagland : exact;
            Pathfork.Brainard.isValid(): exact;
            Pathfork.Fristoe.isValid() : exact;
        }
        size = 16;
        default_action = NoAction();
    }
    Kenvil() Crystola;
    PellCity() LasLomas;
    Gladys() Deeth;
    Lynne() Devola;
    Melder() Shevlin;
    Bigfork() Eudora;
    DeRidder() Buras;
    Linville() Mantee;
    Lyman() Walland;
    Woolwine() Melrose;
    Wyandanch() Angeles;
    Sully() Ammon;
    Estrella() Wells;
    Liberal() Edinburgh;
    Bagwell() Chalco;
    Tulsa() Twichell;
    Cornish() Ferndale;
    Bigspring() Broadford;
    apply {
        Crystola.apply(Pathfork, Tombstone);
        LasLomas.apply(Pathfork, Tombstone, Lebanon, Siloam);
        if (Tombstone.Coulter.Allison == 1w0) {
            Deeth.apply(Pathfork, Tombstone);
            Devola.apply(Pathfork, Tombstone, Lebanon);
            Shevlin.apply(Pathfork, Tombstone, Lebanon);
            if (Lebanon.egress_rid == 16w0 && Lebanon.egress_port != 9w66) {
                Eudora.apply(Pathfork, Tombstone);
            }
            if (Tombstone.Coulter.Bushland == 3w0 || Tombstone.Coulter.Bushland == 3w3) {
                Hoagland.apply();
            }
            Buras.apply(Pathfork, Tombstone);
            Mantee.apply(Pathfork, Tombstone);
            Walland.apply(Pathfork, Tombstone, Lebanon);
        }
        else {
            Melrose.apply(Pathfork, Tombstone, Lebanon);
        }
        Angeles.apply(Pathfork, Tombstone, Lebanon, Vananda);
        if (Tombstone.Coulter.Allison == 1w0 && Tombstone.Coulter.Algodones == 1w1) {
            Ammon.apply(Pathfork, Tombstone);
            if (Tombstone.Coulter.Bushland != 3w2 && Tombstone.Coulter.Topanga == 1w0) {
                Wells.apply(Pathfork, Tombstone, Lebanon);
            }
            Edinburgh.apply(Pathfork, Tombstone);
            Chalco.apply(Pathfork, Tombstone);
            Twichell.apply(Pathfork, Tombstone);
            Ferndale.apply(Pathfork, Tombstone, Lebanon, Vananda);
        }
        if (Tombstone.Coulter.Algodones == 1w0 && Tombstone.Coulter.Bushland != 3w2 && Tombstone.Coulter.Ocoee != 3w3) {
            Broadford.apply(Pathfork, Tombstone, Lebanon);
        }
    }
}

parser Nerstrand(packet_in Norland, out Hematite Pathfork, out Daphne Tombstone, out egress_intrinsic_metadata_t Lebanon) {
    state start {
        Norland.extract<egress_intrinsic_metadata_t>(Lebanon);
        transition Konnarock;
    }
    state Konnarock {
        {
            Norland.extract(Pathfork.Orrick);
            {
            }
        }
        transition Staunton;
    }
    state Staunton {
        Norland.extract<Bradner>(Pathfork.McCammon);
        transition select((Norland.lookahead<bit<8>>())[7:0], Pathfork.McCammon.Lafayette) {
            (8w0x0 &&& 8w0x0, 16w0x8100): Lugert;
            (8w0x45, 16w0x800): McGrady;
            (8w0x0 &&& 8w0x0, 16w0x800): Wellton;
            (8w0x60 &&& 8w0xf0, 16w0x86dd): Kenney;
            (8w0x60 &&& 8w0xf0, 16w0x86dd): Tillicum;
            default: accept;
        }
    }
    state Rocklake {
        Norland.extract<RioPecos>(Pathfork.Lapoint[1]);
        transition accept;
    }
    state Lugert {
        Norland.extract<RioPecos>(Pathfork.Lapoint[0]);
        transition select((Norland.lookahead<bit<8>>())[7:0], Pathfork.Lapoint[0].Lafayette) {
            (8w0x45, 16w0x800): McGrady;
            (8w0x0 &&& 8w0x0, 16w0x800): Wellton;
            (8w0x60 &&& 8w0xf0, 16w0x86dd): Kenney;
            (8w0x60 &&& 8w0xf0, 16w0x86dd): Tillicum;
            (8w0 &&& 8w0, 16w0x8100): Rocklake;
            default: accept;
        }
    }
    state McGrady {
        Norland.extract<Fairmount>(Pathfork.Brainard);
        transition select(Pathfork.Brainard.Moquah, Pathfork.Brainard.Rugby) {
            (13w0, 8w1): Oilmont;
            (13w0, 8w17): Tornillo;
            (13w0, 8w6): Townville;
            (13w0, 8w47): Monahans;
            (13w0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): accept;
            (13w0 &&& 13w0x0, 8w6 &&& 8w0xff): Chavies;
            default: Miranda;
        }
    }
    state Monahans {
        Norland.extract<Skyway>(Pathfork.Pachuta);
        transition select(Pathfork.Pachuta.Rocklin, Pathfork.Pachuta.Wakita, Pathfork.Pachuta.Latham, Pathfork.Pachuta.Dandridge, Pathfork.Pachuta.Colona, Pathfork.Pachuta.Wilmore, Pathfork.Pachuta.Parkville, Pathfork.Pachuta.Piperton, Pathfork.Pachuta.Kenbridge) {
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x800): Pinole;
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x86dd): Corydon;
            default: accept;
        }
    }
    state Bells {
        transition select((Norland.lookahead<bit<8>>())[3:0]) {
            4w0x5: Renick;
            default: FortHunt;
        }
    }
    state Heuvelton {
        transition Hueytown;
    }
    state Oilmont {
        transition accept;
    }
    state RedElm {
        Norland.extract<Bradner>(Pathfork.Barrow);
        transition select((Norland.lookahead<bit<8>>())[7:0], Pathfork.Barrow.Lafayette) {
            (8w0x45, 16w0x800): Renick;
            (8w0x0 &&& 8w0x0, 16w0x800): FortHunt;
            (8w0x60 &&& 8w0xf0, 16w0x86dd): Hueytown;
            default: accept;
        }
    }
    state Pettry {
        Norland.extract<Bradner>(Pathfork.Barrow);
        transition select((Norland.lookahead<bit<8>>())[7:0], Pathfork.Barrow.Lafayette) {
            (8w0x45, 16w0x800): Renick;
            (8w0x0 &&& 8w0x0, 16w0x800): FortHunt;
            default: accept;
        }
    }
    state Pajaros {
        transition accept;
    }
    state Renick {
        Norland.extract<Fairmount>(Pathfork.Foster);
        transition select(Pathfork.Foster.Moquah, Pathfork.Foster.Rugby) {
            (13w0, 8w1): Pajaros;
            (13w0, 8w17): Wauconda;
            (13w0, 8w6): Richvale;
            (13w0 &&& 13w0x1fff, 8w0 &&& 8w0x0): accept;
            (13w0 &&& 13w0x0, 8w6 &&& 8w0xff): SomesBar;
            default: Vergennes;
        }
    }
    state Pinole {
        transition select((Norland.lookahead<bit<4>>())[3:0]) {
            4w0x4: Bells;
            default: accept;
        }
    }
    state FortHunt {
        transition accept;
    }
    state Hueytown {
        Norland.extract<Mayday>(Pathfork.Raiford);
        transition select(Pathfork.Raiford.Palatine) {
            8w0x3a: Pajaros;
            8w17: Wauconda;
            8w6: Richvale;
            default: accept;
        }
    }
    state Corydon {
        transition select((Norland.lookahead<bit<4>>())[3:0]) {
            4w0x6: Heuvelton;
            default: accept;
        }
    }
    state Richvale {
        Norland.extract<NewMelle>(Pathfork.Ayden);
        Norland.extract<Heppner>(Pathfork.Bonduel);
        Norland.extract<Gasport>(Pathfork.Kaaawa);
        transition accept;
    }
    state Wauconda {
        Norland.extract<NewMelle>(Pathfork.Ayden);
        Norland.extract<Dyess>(Pathfork.Sardinia);
        Norland.extract<Gasport>(Pathfork.Kaaawa);
        transition accept;
    }
    state Wellton {
        transition accept;
    }
    state Tornillo {
        Norland.extract<NewMelle>(Pathfork.Whitefish);
        Norland.extract<Dyess>(Pathfork.Ralls);
        Norland.extract<Gasport>(Pathfork.Blairsden);
        transition select(Pathfork.Whitefish.Harbor) {
            16w4789: Satolah;
            16w65330: Satolah;
            default: accept;
        }
    }
    state Kenney {
        Norland.extract<Mayday>(Pathfork.Fristoe);
        transition select(Pathfork.Fristoe.Palatine) {
            8w0x3a: Oilmont;
            8w17: Crestone;
            8w6: Townville;
            default: accept;
        }
    }
    state Tillicum {
        Norland.extract<Havana>(Pathfork.Traverse);
        transition select(Pathfork.Traverse.Palatine) {
            8w0x3a: Oilmont;
            8w17: Crestone;
            8w6: Townville;
            default: accept;
        }
    }
    state Crestone {
        Norland.extract<NewMelle>(Pathfork.Whitefish);
        Norland.extract<Dyess>(Pathfork.Ralls);
        Norland.extract<Gasport>(Pathfork.Blairsden);
        transition select(Pathfork.Whitefish.Harbor) {
            16w4789: Buncombe;
            default: accept;
        }
    }
    state Buncombe {
        Norland.extract<Bennet>(Pathfork.Clover);
        transition Pettry;
    }
    state Townville {
        Norland.extract<NewMelle>(Pathfork.Whitefish);
        Norland.extract<Heppner>(Pathfork.Standish);
        Norland.extract<Gasport>(Pathfork.Blairsden);
        transition accept;
    }
    state Satolah {
        Norland.extract<Bennet>(Pathfork.Clover);
        transition RedElm;
    }
    state Miranda {
        transition accept;
    }
    state Vergennes {
        transition accept;
    }
    state SomesBar {
        transition accept;
    }
    state Chavies {
        transition accept;
    }
}

control Trail(packet_out Norland, inout Hematite Pathfork, in Daphne Tombstone, in egress_intrinsic_metadata_for_deparser_t Vananda) {
    Checksum() Magazine;
    Checksum() McDougal;
    apply {
        Pathfork.Brainard.Forkville = Magazine.update<tuple<bit<4>, bit<4>, bit<6>, bit<2>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ Pathfork.Brainard.Guadalupe, Pathfork.Brainard.Buckfield, Pathfork.Brainard.Alameda, Pathfork.Brainard.Commack, Pathfork.Brainard.Rayville, Pathfork.Brainard.Weinert, Pathfork.Brainard.Parkville, Pathfork.Brainard.Moquah, Pathfork.Brainard.Davie, Pathfork.Brainard.Rugby, Pathfork.Brainard.Fayette, Pathfork.Brainard.Osterdock });
        Pathfork.Foster.Forkville = McDougal.update<tuple<bit<4>, bit<4>, bit<6>, bit<2>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ Pathfork.Foster.Guadalupe, Pathfork.Foster.Buckfield, Pathfork.Foster.Alameda, Pathfork.Foster.Commack, Pathfork.Foster.Rayville, Pathfork.Foster.Weinert, Pathfork.Foster.Parkville, Pathfork.Foster.Moquah, Pathfork.Foster.Davie, Pathfork.Foster.Rugby, Pathfork.Foster.Fayette, Pathfork.Foster.Osterdock });
        Norland.emit<Hematite>(Pathfork);
    }
}

Pipeline<Hematite, Daphne, Hematite, Daphne>(Gause(), WestPark(), Stilwell(), Nerstrand(), Redfield(), Trail()) pipe;

Switch<Hematite, Daphne, Hematite, Daphne, _, _, _, _, _, _, _, _, _, _, _, _>(pipe) main;

