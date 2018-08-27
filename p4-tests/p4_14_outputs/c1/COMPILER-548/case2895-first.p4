#include <core.p4>
#include <v1model.p4>

struct Anvik {
    bit<1> Tolleson;
    bit<1> Mekoryuk;
}

struct Duelm {
    bit<32> Berea;
    bit<32> Enderlin;
}

struct Huntoon {
    bit<14> Secaucus;
    bit<1>  Lakota;
    bit<12> Kirkwood;
    bit<1>  Ladelle;
    bit<1>  Neuse;
    bit<6>  Lovilia;
    bit<2>  Topmost;
    bit<6>  Switzer;
    bit<3>  Cadott;
}

struct Endeavor {
    bit<8> Leoma;
}

struct Segundo {
    bit<16> Livengood;
    bit<16> Kneeland;
    bit<8>  Cashmere;
    bit<8>  Mishawaka;
    bit<8>  WestGate;
    bit<8>  Rawson;
    bit<1>  Carnegie;
    bit<1>  Marcus;
    bit<1>  Standard;
    bit<1>  Maybeury;
    bit<1>  Froid;
    bit<1>  Freetown;
}

struct Hohenwald {
    bit<14> Crary;
    bit<1>  Winnebago;
    bit<1>  Braxton;
}

struct ShadeGap {
    bit<32> Monohan;
    bit<32> Globe;
    bit<32> Westpoint;
}

struct Gravette {
    bit<24> Leland;
    bit<24> Newland;
    bit<24> Arvada;
    bit<24> Hitterdal;
    bit<16> Ipava;
    bit<16> Pardee;
    bit<16> Dixmont;
    bit<16> Bemis;
    bit<16> Cowden;
    bit<8>  Kotzebue;
    bit<8>  Nettleton;
    bit<1>  Tulsa;
    bit<1>  Woodsdale;
    bit<12> Dante;
    bit<2>  Metzger;
    bit<1>  Amonate;
    bit<1>  Bammel;
    bit<1>  Chugwater;
    bit<1>  Exira;
    bit<1>  Uniopolis;
    bit<1>  Ballville;
    bit<1>  Welch;
    bit<1>  Ogunquit;
    bit<1>  Hodges;
    bit<1>  Washta;
    bit<1>  Golden;
    bit<1>  Colona;
    bit<1>  Kekoskee;
    bit<1>  Marbury;
    bit<1>  Knierim;
}

struct Engle {
    bit<14> Millsboro;
    bit<1>  Westview;
    bit<1>  Calumet;
}

struct Satolah {
    bit<128> Coconut;
    bit<128> Bladen;
    bit<20>  Davant;
    bit<8>   McGrady;
    bit<11>  Salineno;
    bit<6>   Locke;
    bit<13>  Bovina;
}

struct Talent {
    bit<32> Burwell;
    bit<32> Gardena;
    bit<6>  Heaton;
    bit<16> Ayden;
}

struct Nicodemus {
    bit<16> Cutler;
    bit<11> Minneota;
}

struct Wondervu {
    bit<1> Wapinitia;
    bit<1> Hartville;
    bit<1> Wauneta;
    bit<3> Cistern;
    bit<1> Hermiston;
    bit<6> Lizella;
    bit<5> Coffman;
}

struct Newkirk {
    bit<16> Raynham;
}

struct Tuscumbia {
    bit<24> Blackman;
    bit<24> Fernway;
    bit<24> Daphne;
    bit<24> Annetta;
    bit<24> Tingley;
    bit<24> Emida;
    bit<24> Verdigris;
    bit<24> Goosport;
    bit<16> Hackney;
    bit<16> Pilar;
    bit<16> Trenary;
    bit<16> Faith;
    bit<12> Pawtucket;
    bit<1>  Shirley;
    bit<3>  Siloam;
    bit<1>  Northcote;
    bit<3>  Funkley;
    bit<1>  Tanner;
    bit<1>  McDaniels;
    bit<1>  Bethune;
    bit<1>  Oakford;
    bit<1>  Annawan;
    bit<8>  LaneCity;
    bit<12> Ivanpah;
    bit<4>  Captiva;
    bit<6>  Loveland;
    bit<10> Trion;
    bit<9>  NewAlbin;
    bit<1>  Boistfort;
    bit<1>  Brothers;
    bit<1>  Couchwood;
    bit<1>  Fosters;
    bit<1>  Virgin;
}

struct Chevak {
    bit<8> Wallace;
    bit<1> Tiburon;
    bit<1> Laton;
    bit<1> Covina;
    bit<1> Bowen;
    bit<1> Higley;
}

header Magasco {
    bit<16> Dockton;
    bit<16> Sontag;
}

header Talbotton {
    bit<32> Cathay;
    bit<32> Calverton;
    bit<4>  Ocracoke;
    bit<4>  Ahmeek;
    bit<8>  Hitchland;
    bit<16> ElmGrove;
    bit<16> Lueders;
    bit<16> Hartman;
}

header Joseph {
    bit<16> Brinklow;
    bit<16> Florala;
}

header Potosi {
    bit<8>  Murdock;
    bit<24> Ekron;
    bit<24> Baroda;
    bit<8>  Wesson;
}

header Toluca {
    bit<4>   Farlin;
    bit<6>   Finlayson;
    bit<2>   Humeston;
    bit<20>  Quitman;
    bit<16>  Gobler;
    bit<8>   ElkNeck;
    bit<8>   Henderson;
    bit<128> Parkland;
    bit<128> Clermont;
}

header Robinette {
    bit<4>  Dryden;
    bit<4>  Talihina;
    bit<6>  Klukwan;
    bit<2>  Brimley;
    bit<16> Tramway;
    bit<16> Trilby;
    bit<3>  Callands;
    bit<13> Valencia;
    bit<8>  Beatrice;
    bit<8>  Becida;
    bit<16> Tusculum;
    bit<32> Carlson;
    bit<32> Turkey;
}

header Flaxton {
    bit<16> Chitina;
    bit<16> Mynard;
    bit<8>  Nipton;
    bit<8>  Boxelder;
    bit<16> Alcalde;
}

header Rocheport {
    bit<6>  Placid;
    bit<10> Tahuya;
    bit<4>  Fontana;
    bit<12> Elsmere;
    bit<12> Bethania;
    bit<2>  Belfast;
    bit<2>  Parnell;
    bit<8>  WyeMills;
    bit<3>  Seibert;
    bit<5>  Southam;
}

header Hobergs {
    bit<24> Lanesboro;
    bit<24> ElRio;
    bit<24> Trimble;
    bit<24> Paulding;
    bit<16> Brashear;
}

@name("Geistown") header Geistown_0 {
    bit<1>  Pearcy;
    bit<1>  Boysen;
    bit<1>  Calabash;
    bit<1>  Dunmore;
    bit<1>  Hartfield;
    bit<3>  Accomac;
    bit<5>  Decorah;
    bit<3>  Council;
    bit<16> Heron;
}

header egress_intrinsic_metadata_t {
    bit<7>  _pad0;
    bit<9>  egress_port;
    bit<5>  _pad1;
    bit<19> enq_qdepth;
    bit<6>  _pad2;
    bit<2>  enq_congest_stat;
    bit<32> enq_tstamp;
    bit<5>  _pad3;
    bit<19> deq_qdepth;
    bit<6>  _pad4;
    bit<2>  deq_congest_stat;
    bit<8>  app_pool_congest_stat;
    bit<32> deq_timedelta;
    bit<16> egress_rid;
    bit<7>  _pad5;
    bit<1>  egress_rid_first;
    bit<3>  _pad6;
    bit<5>  egress_qid;
    bit<5>  _pad7;
    bit<3>  egress_cos;
    bit<7>  _pad8;
    bit<1>  deflection_flag;
    bit<16> pkt_length;
}

header egress_intrinsic_metadata_for_mirror_buffer_t {
    bit<6>  _pad1;
    bit<10> egress_mirror_id;
    bit<1>  coalesce_flush;
    bit<7>  coalesce_length;
}

header egress_intrinsic_metadata_for_output_port_t {
    bit<2> _pad1;
    bit<1> capture_tstamp_on_tx;
    bit<1> update_delay_on_tx;
    bit<1> force_tx_error;
    bit<3> drop_ctl;
}

header egress_intrinsic_metadata_from_parser_aux_t {
    bit<48> egress_global_tstamp;
    bit<32> egress_global_ver;
    bit<16> egress_parser_err;
    bit<4>  clone_digest_id;
    bit<4>  clone_src;
    bit<8>  coalesce_sample_count;
}

header ingress_intrinsic_metadata_t {
    bit<1>  resubmit_flag;
    bit<1>  _pad1;
    bit<2>  _pad2;
    bit<3>  _pad3;
    bit<9>  ingress_port;
    bit<48> ingress_mac_tstamp;
}

header ingress_intrinsic_metadata_for_mirror_buffer_t {
    bit<6>  _pad1;
    bit<10> ingress_mirror_id;
}

header ingress_intrinsic_metadata_for_tm_t {
    bit<7>  _pad1;
    bit<9>  ucast_egress_port;
    bit<3>  drop_ctl;
    bit<1>  bypass_egress;
    bit<1>  deflect_on_drop;
    bit<3>  ingress_cos;
    bit<5>  qid;
    bit<3>  icos_for_copy_to_cpu;
    bit<3>  _pad2;
    bit<1>  copy_to_cpu;
    bit<2>  packet_color;
    bit<1>  disable_ucast_cutthru;
    bit<1>  enable_mcast_cutthru;
    bit<16> mcast_grp_a;
    bit<16> mcast_grp_b;
    bit<3>  _pad3;
    bit<13> level1_mcast_hash;
    bit<3>  _pad4;
    bit<13> level2_mcast_hash;
    bit<16> level1_exclusion_id;
    bit<7>  _pad5;
    bit<9>  level2_exclusion_id;
    bit<16> rid;
}

header ingress_intrinsic_metadata_from_parser_aux_t {
    bit<48> ingress_global_tstamp;
    bit<32> ingress_global_ver;
    bit<16> ingress_parser_err;
}

@name("generator_metadata_t") header generator_metadata_t_0 {
    bit<16> app_id;
    bit<16> batch_id;
    bit<16> instance_id;
}

header ingress_parser_control_signals {
    bit<3> priority;
    bit<5> _pad1;
    bit<8> parser_counter;
}

header Wolverine {
    bit<3>  Elvaston;
    bit<1>  Leona;
    bit<12> Toxey;
    bit<16> Hercules;
}

struct metadata {
    @pa_container_size("ingress", "Biscay.Mekoryuk", 32) @name(".Biscay") 
    Anvik     Biscay;
    @name(".DuckHill") 
    Duelm     DuckHill;
    @name(".ElkFalls") 
    Huntoon   ElkFalls;
    @name(".Kingsland") 
    Endeavor  Kingsland;
    @name(".Loogootee") 
    Segundo   Loogootee;
    @name(".Lumberton") 
    Hohenwald Lumberton;
    @name(".Mesita") 
    ShadeGap  Mesita;
    @name(".Miranda") 
    Gravette  Miranda;
    @name(".Ringwood") 
    Engle     Ringwood;
    @name(".Rockham") 
    Satolah   Rockham;
    @name(".Roxboro") 
    Talent    Roxboro;
    @name(".Sallisaw") 
    Nicodemus Sallisaw;
    @name(".Selawik") 
    Wondervu  Selawik;
    @name(".Shivwits") 
    Newkirk   Shivwits;
    @pa_no_init("ingress", "Stanwood.Blackman") @pa_no_init("ingress", "Stanwood.Fernway") @pa_no_init("ingress", "Stanwood.Daphne") @pa_no_init("ingress", "Stanwood.Annetta") @name(".Stanwood") 
    Tuscumbia Stanwood;
    @name(".Tuskahoma") 
    Chevak    Tuskahoma;
}

struct headers {
    @name(".Alberta") 
    Magasco                                        Alberta;
    @name(".BlackOak") 
    Talbotton                                      BlackOak;
    @name(".Comunas") 
    Joseph                                         Comunas;
    @name(".Corum") 
    Talbotton                                      Corum;
    @name(".Harney") 
    Potosi                                         Harney;
    @name(".Heppner") 
    Toluca                                         Heppner;
    @name(".Holliday") 
    Toluca                                         Holliday;
    @pa_fragment("ingress", "Kasilof.Tusculum") @pa_fragment("egress", "Kasilof.Tusculum") @name(".Kasilof") 
    Robinette                                      Kasilof;
    @name(".Krupp") 
    Flaxton                                        Krupp;
    @name(".Louin") 
    Rocheport                                      Louin;
    @name(".Lyncourt") 
    Hobergs                                        Lyncourt;
    @name(".Orosi") 
    Geistown_0                                     Orosi;
    @pa_fragment("ingress", "Sprout.Tusculum") @pa_fragment("egress", "Sprout.Tusculum") @name(".Sprout") 
    Robinette                                      Sprout;
    @name(".Teaneck") 
    Hobergs                                        Teaneck;
    @name(".Thayne") 
    Hobergs                                        Thayne;
    @name(".Varnell") 
    Joseph                                         Varnell;
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md") @pa_atomic("egress", "eg_intr_md.egress_port") @pa_fragment("egress", "eg_intr_md._pad1") @pa_fragment("egress", "eg_intr_md._pad7") @pa_fragment("egress", "eg_intr_md._pad8") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_port") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_cos") @name(".eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @dont_trim @pa_intrinsic_header("egress", "eg_intr_md_for_mb") @pa_atomic("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_fragment("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_length") @not_deparsed("ingress") @not_deparsed("egress") @name(".eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @dont_trim @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_oport.drop_ctl") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_for_oport") @name(".eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @pa_fragment("egress", "eg_intr_md_from_parser_aux.coalesce_sample_count") @pa_fragment("egress", "eg_intr_md_from_parser_aux.clone_src") @pa_fragment("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @pa_atomic("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_from_parser_aux") @name(".eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md.ingress_port") @name(".ig_intr_md") 
    ingress_intrinsic_metadata_t                   ig_intr_md;
    @dont_trim @pa_intrinsic_header("ingress", "ig_intr_md_for_mb") @pa_atomic("ingress", "ig_intr_md_for_mb.ingress_mirror_id") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_mb.ingress_mirror_id") @not_deparsed("ingress") @not_deparsed("egress") @name(".ig_intr_md_for_mb") 
    ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb;
    @pa_atomic("ingress", "ig_intr_md_for_tm.ucast_egress_port") @pa_fragment("ingress", "ig_intr_md_for_tm.drop_ctl") @pa_fragment("ingress", "ig_intr_md_for_tm.qid") @pa_fragment("ingress", "ig_intr_md_for_tm._pad2") @pa_atomic("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_fragment("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_atomic("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_fragment("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_atomic("ingress", "ig_intr_md_for_tm.level1_mcast_hash") @pa_fragment("ingress", "ig_intr_md_for_tm._pad3") @pa_atomic("ingress", "ig_intr_md_for_tm.level2_mcast_hash") @pa_fragment("ingress", "ig_intr_md_for_tm._pad4") @pa_atomic("ingress", "ig_intr_md_for_tm.level1_exclusion_id") @pa_fragment("ingress", "ig_intr_md_for_tm.level1_exclusion_id") @pa_atomic("ingress", "ig_intr_md_for_tm.level2_exclusion_id") @pa_fragment("ingress", "ig_intr_md_for_tm._pad5") @pa_atomic("ingress", "ig_intr_md_for_tm.rid") @pa_fragment("ingress", "ig_intr_md_for_tm.rid") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md_for_tm") @dont_trim @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.drop_ctl") @name(".ig_intr_md_for_tm") 
    ingress_intrinsic_metadata_for_tm_t            ig_intr_md_for_tm;
    @pa_fragment("ingress", "ig_intr_md_from_parser_aux.ingress_parser_err") @pa_atomic("ingress", "ig_intr_md_from_parser_aux.ingress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md_from_parser_aux") @name(".ig_intr_md_from_parser_aux") 
    ingress_intrinsic_metadata_from_parser_aux_t   ig_intr_md_from_parser_aux;
    @not_deparsed("ingress") @not_deparsed("egress") @name(".ig_pg_md") 
    generator_metadata_t_0                         ig_pg_md;
    @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_prsr_ctrl") @name(".ig_prsr_ctrl") 
    ingress_parser_control_signals                 ig_prsr_ctrl;
    @name(".Mondovi") 
    Wolverine[2]                                   Mondovi;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Abbyville") state Abbyville {
        packet.extract<Magasco>(hdr.Alberta);
        packet.extract<Joseph>(hdr.Comunas);
        transition select(hdr.Alberta.Sontag) {
            16w4789: Williams;
            default: accept;
        }
    }
    @name(".Bolckow") state Bolckow {
        packet.extract<Hobergs>(hdr.Teaneck);
        transition Casnovia;
    }
    @name(".Cartago") state Cartago {
        packet.extract<Flaxton>(hdr.Krupp);
        meta.Loogootee.Freetown = 1w1;
        transition accept;
    }
    @name(".Casnovia") state Casnovia {
        packet.extract<Rocheport>(hdr.Louin);
        transition Wabuska;
    }
    @name(".Duncombe") state Duncombe {
        packet.extract<Robinette>(hdr.Sprout);
        meta.Loogootee.Mishawaka = hdr.Sprout.Becida;
        meta.Loogootee.Rawson = hdr.Sprout.Beatrice;
        meta.Loogootee.Kneeland = hdr.Sprout.Tramway;
        meta.Loogootee.Maybeury = 1w0;
        meta.Loogootee.Marcus = 1w1;
        transition accept;
    }
    @name(".Elderon") state Elderon {
        packet.extract<Toluca>(hdr.Heppner);
        meta.Loogootee.Mishawaka = hdr.Heppner.ElkNeck;
        meta.Loogootee.Rawson = hdr.Heppner.Henderson;
        meta.Loogootee.Kneeland = hdr.Heppner.Gobler;
        meta.Loogootee.Maybeury = 1w1;
        meta.Loogootee.Marcus = 1w0;
        transition accept;
    }
    @name(".Elyria") state Elyria {
        meta.Miranda.Metzger = 2w2;
        transition Duncombe;
    }
    @name(".Hilbert") state Hilbert {
        packet.extract<Magasco>(hdr.Alberta);
        packet.extract<Talbotton>(hdr.BlackOak);
        transition accept;
    }
    @name(".Machens") state Machens {
        packet.extract<Hobergs>(hdr.Lyncourt);
        transition select(hdr.Lyncourt.Brashear) {
            16w0x800: Duncombe;
            16w0x86dd: Elderon;
            default: accept;
        }
    }
    @name(".Miller") state Miller {
        packet.extract<Geistown_0>(hdr.Orosi);
        transition select(hdr.Orosi.Pearcy, hdr.Orosi.Boysen, hdr.Orosi.Calabash, hdr.Orosi.Dunmore, hdr.Orosi.Hartfield, hdr.Orosi.Accomac, hdr.Orosi.Decorah, hdr.Orosi.Council, hdr.Orosi.Heron) {
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x800): Elyria;
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x86dd): Perryton;
            default: accept;
        }
    }
    @name(".Netcong") state Netcong {
        packet.extract<Magasco>(hdr.Alberta);
        packet.extract<Joseph>(hdr.Comunas);
        transition accept;
    }
    @name(".Penzance") state Penzance {
        packet.extract<Wolverine>(hdr.Mondovi[0]);
        meta.Loogootee.Froid = 1w1;
        transition select(hdr.Mondovi[0].Hercules) {
            16w0x800: Rendon;
            16w0x86dd: Sherrill;
            16w0x806: Cartago;
            default: accept;
        }
    }
    @name(".Perryton") state Perryton {
        meta.Miranda.Metzger = 2w2;
        transition Elderon;
    }
    @name(".Rendon") state Rendon {
        packet.extract<Robinette>(hdr.Kasilof);
        meta.Loogootee.Cashmere = hdr.Kasilof.Becida;
        meta.Loogootee.WestGate = hdr.Kasilof.Beatrice;
        meta.Loogootee.Livengood = hdr.Kasilof.Tramway;
        meta.Loogootee.Standard = 1w0;
        meta.Loogootee.Carnegie = 1w1;
        transition select(hdr.Kasilof.Valencia, hdr.Kasilof.Talihina, hdr.Kasilof.Becida) {
            (13w0x0, 4w0x5, 8w0x11): Abbyville;
            (13w0x0, 4w0x5, 8w0x6): Hilbert;
            default: accept;
        }
    }
    @name(".Sherrill") state Sherrill {
        packet.extract<Toluca>(hdr.Holliday);
        meta.Loogootee.Cashmere = hdr.Holliday.ElkNeck;
        meta.Loogootee.WestGate = hdr.Holliday.Henderson;
        meta.Loogootee.Livengood = hdr.Holliday.Gobler;
        meta.Loogootee.Standard = 1w1;
        meta.Loogootee.Carnegie = 1w0;
        transition select(hdr.Holliday.ElkNeck) {
            8w0x11: Netcong;
            8w0x6: Hilbert;
            default: accept;
        }
    }
    @name(".Wabuska") state Wabuska {
        packet.extract<Hobergs>(hdr.Thayne);
        transition select(hdr.Thayne.Brashear) {
            16w0x8100: Penzance;
            16w0x800: Rendon;
            16w0x86dd: Sherrill;
            16w0x806: Cartago;
            default: accept;
        }
    }
    @name(".Williams") state Williams {
        packet.extract<Potosi>(hdr.Harney);
        meta.Miranda.Metzger = 2w1;
        transition Machens;
    }
    @name(".start") state start {
        transition select((packet.lookahead<bit<112>>())[15:0]) {
            16w0xbf00: Bolckow;
            default: Wabuska;
        }
    }
}

@name(".Skokomish") @mode("resilient") action_selector(HashAlgorithm.identity, 32w65536, 32w66) Skokomish;

@name(".Wisdom") @mode("resilient") action_selector(HashAlgorithm.identity, 32w1024, 32w51) Wisdom;

control Armona(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".RoyalOak") action RoyalOak(bit<24> Betterton, bit<24> Friend, bit<16> Loyalton) {
        meta.Stanwood.Hackney = Loyalton;
        meta.Stanwood.Blackman = Betterton;
        meta.Stanwood.Fernway = Friend;
        meta.Stanwood.Boistfort = 1w1;
        hdr.ig_intr_md_for_tm.rid = 16w0xffff;
    }
    @name(".Columbia") action Columbia() {
        meta.Miranda.Exira = 1w1;
        mark_to_drop();
    }
    @name(".FarrWest") action FarrWest() {
        Columbia();
    }
    @name(".Hampton") action Hampton(bit<8> Sudden) {
        meta.Stanwood.Northcote = 1w1;
        meta.Stanwood.LaneCity = Sudden;
    }
    @name(".Bremond") table Bremond {
        actions = {
            RoyalOak();
            FarrWest();
            Hampton();
            @defaultonly NoAction();
        }
        key = {
            meta.Sallisaw.Cutler: exact @name("Sallisaw.Cutler") ;
        }
        size = 65536;
        default_action = NoAction();
    }
    apply {
        if (meta.Sallisaw.Cutler != 16w0) 
            Bremond.apply();
    }
}

control Bains(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Anchorage") action Anchorage() {
        hdr.Thayne.Brashear = hdr.Mondovi[0].Hercules;
        hdr.Mondovi[0].setInvalid();
    }
    @name(".Baskett") table Baskett {
        actions = {
            Anchorage();
        }
        size = 1;
        default_action = Anchorage();
    }
    apply {
        Baskett.apply();
    }
}
#include <tofino/p4_14_prim.p4>

control Beaman(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Wabasha") action Wabasha() {
        meta.Stanwood.Blackman = meta.Miranda.Leland;
        meta.Stanwood.Fernway = meta.Miranda.Newland;
        meta.Stanwood.Daphne = meta.Miranda.Arvada;
        meta.Stanwood.Annetta = meta.Miranda.Hitterdal;
        meta.Stanwood.Hackney = meta.Miranda.Pardee;
        invalidate<bit<9>>(hdr.ig_intr_md_for_tm.ucast_egress_port);
    }
    @name(".Barksdale") table Barksdale {
        actions = {
            Wabasha();
        }
        size = 1;
        default_action = Wabasha();
    }
    apply {
        Barksdale.apply();
    }
}

control Belle(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Cascade") action Cascade(bit<16> Tiskilwa, bit<14> Hahira, bit<1> Bardwell, bit<1> Willows) {
        meta.Shivwits.Raynham = Tiskilwa;
        meta.Ringwood.Westview = Bardwell;
        meta.Ringwood.Millsboro = Hahira;
        meta.Ringwood.Calumet = Willows;
    }
    @name(".Sutton") table Sutton {
        actions = {
            Cascade();
            @defaultonly NoAction();
        }
        key = {
            meta.Roxboro.Gardena: exact @name("Roxboro.Gardena") ;
            meta.Miranda.Bemis  : exact @name("Miranda.Bemis") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    apply {
        if (meta.Miranda.Exira == 1w0 && meta.Tuskahoma.Laton == 1w1 && meta.Miranda.Kekoskee == 1w1) 
            Sutton.apply();
    }
}

control Belvue(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Reydon") action Reydon(bit<16> Glendevey, bit<1> Grottoes) {
        meta.Stanwood.Hackney = Glendevey;
        meta.Stanwood.Boistfort = Grottoes;
    }
    @name(".Ashley") action Ashley() {
        mark_to_drop();
    }
    @name(".Leawood") table Leawood {
        actions = {
            Reydon();
            @defaultonly Ashley();
        }
        key = {
            hdr.eg_intr_md.egress_rid: exact @name("eg_intr_md.egress_rid") ;
        }
        size = 57344;
        default_action = Ashley();
    }
    apply {
        if (hdr.eg_intr_md.egress_rid != 16w0 && hdr.eg_intr_md.egress_rid & 16w0xe000 != 16w0xe000) 
            Leawood.apply();
    }
}

@name(".Aniak") register<bit<1>>(32w262144) Aniak;

@name(".Denby") register<bit<1>>(32w262144) Denby;

control Bienville(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Bogota") RegisterAction<bit<1>, bit<1>>(Denby) Bogota = {
        void apply(inout bit<1> value, out bit<1> rv) {
            rv = 1w0;
            bit<1> in_value;
            in_value = value;
            value = in_value;
            rv = ~value;
        }
    };
    @name(".McIntosh") RegisterAction<bit<1>, bit<1>>(Aniak) McIntosh = {
        void apply(inout bit<1> value, out bit<1> rv) {
            rv = 1w0;
            bit<1> in_value;
            in_value = value;
            value = in_value;
            rv = value;
        }
    };
    @name(".Lynch") action Lynch(bit<1> Lenox) {
        meta.Biscay.Mekoryuk = Lenox;
    }
    @name(".Bellamy") action Bellamy() {
        meta.Miranda.Dante = hdr.Mondovi[0].Toxey;
        meta.Miranda.Amonate = 1w1;
    }
    @name(".Hamburg") action Hamburg() {
        meta.Miranda.Dante = meta.ElkFalls.Kirkwood;
        meta.Miranda.Amonate = 1w0;
    }
    @name(".Dateland") action Dateland() {
        {
            bit<18> temp;
            hash<bit<18>, bit<18>, tuple<bit<6>, bit<12>>, bit<19>>(temp, HashAlgorithm.identity, 18w0, { meta.ElkFalls.Lovilia, hdr.Mondovi[0].Toxey }, 19w262144);
            meta.Biscay.Mekoryuk = McIntosh.execute((bit<32>)temp);
        }
    }
    @name(".Gannett") action Gannett() {
        {
            bit<18> temp_0;
            hash<bit<18>, bit<18>, tuple<bit<6>, bit<12>>, bit<19>>(temp_0, HashAlgorithm.identity, 18w0, { meta.ElkFalls.Lovilia, hdr.Mondovi[0].Toxey }, 19w262144);
            meta.Biscay.Tolleson = Bogota.execute((bit<32>)temp_0);
        }
    }
    @use_hash_action(0) @name(".Ambler") table Ambler {
        actions = {
            Lynch();
            @defaultonly NoAction();
        }
        key = {
            meta.ElkFalls.Lovilia: exact @name("ElkFalls.Lovilia") ;
        }
        size = 64;
        default_action = NoAction();
    }
    @name(".Elwood") table Elwood {
        actions = {
            Bellamy();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    @name(".Hawthorne") table Hawthorne {
        actions = {
            Hamburg();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    @name(".Kenefic") table Kenefic {
        actions = {
            Dateland();
        }
        size = 1;
        default_action = Dateland();
    }
    @name(".Paradise") table Paradise {
        actions = {
            Gannett();
        }
        size = 1;
        default_action = Gannett();
    }
    apply {
        if (hdr.Mondovi[0].isValid()) {
            Elwood.apply();
            if (meta.ElkFalls.Neuse == 1w1) {
                Paradise.apply();
                Kenefic.apply();
            }
        }
        else {
            Hawthorne.apply();
            if (meta.ElkFalls.Neuse == 1w1) 
                Ambler.apply();
        }
    }
}

control BigBow(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Kinsey") action Kinsey(bit<14> Danbury, bit<1> Langford, bit<1> Reynolds) {
        meta.Ringwood.Millsboro = Danbury;
        meta.Ringwood.Westview = Langford;
        meta.Ringwood.Calumet = Reynolds;
    }
    @name(".Wauregan") table Wauregan {
        actions = {
            Kinsey();
            @defaultonly NoAction();
        }
        key = {
            meta.Roxboro.Burwell : exact @name("Roxboro.Burwell") ;
            meta.Shivwits.Raynham: exact @name("Shivwits.Raynham") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    apply {
        if (meta.Shivwits.Raynham != 16w0) 
            Wauregan.apply();
    }
}

control BigPiney(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Vallejo") action Vallejo() {
        meta.Selawik.Cistern = meta.ElkFalls.Cadott;
    }
    @name(".Everest") action Everest() {
        meta.Selawik.Cistern = hdr.Mondovi[0].Elvaston;
        meta.Miranda.Ipava = hdr.Mondovi[0].Hercules;
    }
    @name(".Ivyland") action Ivyland() {
        meta.Selawik.Lizella = meta.ElkFalls.Switzer;
    }
    @name(".Comobabi") action Comobabi() {
        meta.Selawik.Lizella = meta.Roxboro.Heaton;
    }
    @name(".Gurdon") action Gurdon() {
        meta.Selawik.Lizella = meta.Rockham.Locke;
    }
    @name(".Overton") table Overton {
        actions = {
            Vallejo();
            Everest();
            @defaultonly NoAction();
        }
        key = {
            meta.Miranda.Marbury: exact @name("Miranda.Marbury") ;
        }
        size = 2;
        default_action = NoAction();
    }
    @name(".Pineridge") table Pineridge {
        actions = {
            Ivyland();
            Comobabi();
            Gurdon();
            @defaultonly NoAction();
        }
        key = {
            meta.Miranda.Woodsdale: exact @name("Miranda.Woodsdale") ;
            meta.Miranda.Tulsa    : exact @name("Miranda.Tulsa") ;
        }
        size = 3;
        default_action = NoAction();
    }
    apply {
        Overton.apply();
        Pineridge.apply();
    }
}

control Bronaugh(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Sabana") action Sabana() {
        hash<bit<32>, bit<32>, tuple<bit<8>, bit<32>, bit<32>>, bit<64>>(meta.Mesita.Globe, HashAlgorithm.crc32, 32w0, { hdr.Kasilof.Becida, hdr.Kasilof.Carlson, hdr.Kasilof.Turkey }, 64w4294967296);
    }
    @name(".Tununak") action Tununak() {
        hash<bit<32>, bit<32>, tuple<bit<128>, bit<128>, bit<20>, bit<8>>, bit<64>>(meta.Mesita.Globe, HashAlgorithm.crc32, 32w0, { hdr.Holliday.Parkland, hdr.Holliday.Clermont, hdr.Holliday.Quitman, hdr.Holliday.ElkNeck }, 64w4294967296);
    }
    @name(".Lebanon") table Lebanon {
        actions = {
            Sabana();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    @name(".Shabbona") table Shabbona {
        actions = {
            Tununak();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        if (hdr.Kasilof.isValid()) 
            Lebanon.apply();
        else 
            if (hdr.Holliday.isValid()) 
                Shabbona.apply();
    }
}

control Campbell(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Wittman") action Wittman() {
        hash<bit<32>, bit<32>, tuple<bit<24>, bit<24>, bit<24>, bit<24>, bit<16>>, bit<64>>(meta.Mesita.Monohan, HashAlgorithm.crc32, 32w0, { hdr.Thayne.Lanesboro, hdr.Thayne.ElRio, hdr.Thayne.Trimble, hdr.Thayne.Paulding, hdr.Thayne.Brashear }, 64w4294967296);
    }
    @name(".Anguilla") table Anguilla {
        actions = {
            Wittman();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        Anguilla.apply();
    }
}

control CapeFair(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Waring") @min_width(16) direct_counter(CounterType.packets_and_bytes) Waring;
    @name(".Brazil") action Brazil() {
    }
    @name(".CoosBay") action CoosBay() {
        meta.Miranda.Bammel = 1w1;
        meta.Kingsland.Leoma = 8w0;
    }
    @name(".Temple") action Temple(bit<1> Decherd) {
        meta.Miranda.Knierim = Decherd;
    }
    @name(".Margie") action Margie() {
    }
    @name(".Columbia") action Columbia() {
        meta.Miranda.Exira = 1w1;
        mark_to_drop();
    }
    @name(".Rockland") action Rockland() {
        meta.Tuskahoma.Higley = 1w1;
    }
    @name(".Annandale") table Annandale {
        support_timeout = true;
        actions = {
            Brazil();
            CoosBay();
        }
        key = {
            meta.Miranda.Arvada   : exact @name("Miranda.Arvada") ;
            meta.Miranda.Hitterdal: exact @name("Miranda.Hitterdal") ;
            meta.Miranda.Pardee   : exact @name("Miranda.Pardee") ;
            meta.Miranda.Dixmont  : exact @name("Miranda.Dixmont") ;
        }
        size = 65536;
        default_action = CoosBay();
    }
    @name(".Hagewood") table Hagewood {
        actions = {
            Temple();
            Margie();
        }
        key = {
            meta.Miranda.Pardee: exact @name("Miranda.Pardee") ;
        }
        size = 4096;
        default_action = Margie();
    }
    @name(".Jelloway") table Jelloway {
        actions = {
            Columbia();
            Margie();
        }
        key = {
            meta.Miranda.Arvada   : exact @name("Miranda.Arvada") ;
            meta.Miranda.Hitterdal: exact @name("Miranda.Hitterdal") ;
            meta.Miranda.Pardee   : exact @name("Miranda.Pardee") ;
        }
        size = 4096;
        default_action = Margie();
    }
    @name(".Columbia") action Columbia_0() {
        Waring.count();
        meta.Miranda.Exira = 1w1;
        mark_to_drop();
    }
    @name(".Margie") action Margie_0() {
        Waring.count();
    }
    @name(".Monetta") table Monetta {
        actions = {
            Columbia_0();
            Margie_0();
        }
        key = {
            meta.ElkFalls.Lovilia : exact @name("ElkFalls.Lovilia") ;
            meta.Biscay.Mekoryuk  : ternary @name("Biscay.Mekoryuk") ;
            meta.Biscay.Tolleson  : ternary @name("Biscay.Tolleson") ;
            meta.Miranda.Uniopolis: ternary @name("Miranda.Uniopolis") ;
            meta.Miranda.Ogunquit : ternary @name("Miranda.Ogunquit") ;
            meta.Miranda.Welch    : ternary @name("Miranda.Welch") ;
        }
        size = 512;
        default_action = Margie_0();
        counters = Waring;
    }
    @name(".Newtok") table Newtok {
        actions = {
            Rockland();
            @defaultonly NoAction();
        }
        key = {
            meta.Miranda.Bemis  : ternary @name("Miranda.Bemis") ;
            meta.Miranda.Leland : exact @name("Miranda.Leland") ;
            meta.Miranda.Newland: exact @name("Miranda.Newland") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        switch (Monetta.apply().action_run) {
            Margie_0: {
                switch (Jelloway.apply().action_run) {
                    Margie: {
                        if (meta.ElkFalls.Lakota == 1w0 && meta.Miranda.Chugwater == 1w0) 
                            Annandale.apply();
                        Hagewood.apply();
                        Newtok.apply();
                    }
                }

            }
        }

    }
}

control Chalco(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Linville") action Linville() {
        meta.Stanwood.McDaniels = 1w1;
        meta.Stanwood.Annawan = 1w1;
        hdr.ig_intr_md_for_tm.mcast_grp_a = meta.Stanwood.Hackney + 16w4096;
    }
    @name(".Gorman") action Gorman() {
        meta.Stanwood.Oakford = 1w1;
        meta.Stanwood.Fosters = 1w1;
        hdr.ig_intr_md_for_tm.mcast_grp_a = meta.Stanwood.Hackney;
    }
    @name(".Barwick") action Barwick(bit<16> Oilmont) {
        meta.Stanwood.Bethune = 1w1;
        hdr.ig_intr_md_for_tm.ucast_egress_port = (bit<9>)Oilmont;
        meta.Stanwood.Trenary = Oilmont;
    }
    @name(".ElMango") action ElMango(bit<16> Wimberley) {
        meta.Stanwood.McDaniels = 1w1;
        meta.Stanwood.Faith = Wimberley;
    }
    @name(".Columbia") action Columbia() {
        meta.Miranda.Exira = 1w1;
        mark_to_drop();
    }
    @name(".Kenvil") action Kenvil() {
    }
    @name(".CityView") action CityView() {
        meta.Stanwood.Tanner = 1w1;
        meta.Stanwood.Fosters = 1w1;
        hdr.ig_intr_md_for_tm.copy_to_cpu = meta.Miranda.Ballville | meta.Loogootee.Freetown;
        hdr.ig_intr_md_for_tm.mcast_grp_a = meta.Stanwood.Hackney;
    }
    @name(".Loysburg") action Loysburg() {
    }
    @name(".Boyce") table Boyce {
        actions = {
            Linville();
        }
        size = 1;
        default_action = Linville();
    }
    @name(".Kahaluu") table Kahaluu {
        actions = {
            Gorman();
        }
        size = 1;
        default_action = Gorman();
    }
    @name(".Norland") table Norland {
        actions = {
            Barwick();
            ElMango();
            Columbia();
            Kenvil();
        }
        key = {
            meta.Stanwood.Blackman: exact @name("Stanwood.Blackman") ;
            meta.Stanwood.Fernway : exact @name("Stanwood.Fernway") ;
            meta.Stanwood.Hackney : exact @name("Stanwood.Hackney") ;
        }
        size = 65536;
        default_action = Kenvil();
    }
    @ways(1) @name(".Palomas") table Palomas {
        actions = {
            CityView();
            Loysburg();
        }
        key = {
            meta.Stanwood.Blackman: exact @name("Stanwood.Blackman") ;
            meta.Stanwood.Fernway : exact @name("Stanwood.Fernway") ;
        }
        size = 1;
        default_action = Loysburg();
    }
    apply {
        if (meta.Miranda.Exira == 1w0 && !hdr.Louin.isValid()) 
            switch (Norland.apply().action_run) {
                Kenvil: {
                    switch (Palomas.apply().action_run) {
                        Loysburg: {
                            if (meta.Stanwood.Blackman & 24w0x10000 == 24w0x10000) 
                                Boyce.apply();
                            else 
                                Kahaluu.apply();
                        }
                    }

                }
            }

    }
}

control Dixboro(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Brunson") action Brunson(bit<9> Walnut) {
        meta.Stanwood.Shirley = 1w0;
        hdr.ig_intr_md_for_tm.ucast_egress_port = Walnut;
        meta.Stanwood.NewAlbin = hdr.ig_intr_md.ingress_port;
    }
    @name(".Tuckerton") action Tuckerton(bit<9> Menomonie) {
        meta.Stanwood.Shirley = 1w1;
        hdr.ig_intr_md_for_tm.ucast_egress_port = Menomonie;
        meta.Stanwood.NewAlbin = hdr.ig_intr_md.ingress_port;
    }
    @name(".Barber") action Barber() {
        meta.Stanwood.Shirley = 1w0;
    }
    @name(".Varnado") action Varnado() {
        meta.Stanwood.Shirley = 1w1;
        meta.Stanwood.NewAlbin = hdr.ig_intr_md.ingress_port;
    }
    @ternary(1) @name(".Rosebush") table Rosebush {
        actions = {
            Brunson();
            Tuckerton();
            Barber();
            Varnado();
            @defaultonly NoAction();
        }
        key = {
            meta.Stanwood.Northcote          : exact @name("Stanwood.Northcote") ;
            hdr.ig_intr_md_for_tm.copy_to_cpu: exact @name("ig_intr_md_for_tm.copy_to_cpu") ;
            meta.Tuskahoma.Higley            : exact @name("Tuskahoma.Higley") ;
            meta.ElkFalls.Ladelle            : ternary @name("ElkFalls.Ladelle") ;
            meta.Stanwood.LaneCity           : ternary @name("Stanwood.LaneCity") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        Rosebush.apply();
    }
}

control Geismar(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Kaufman") action Kaufman(bit<14> Oskawalik, bit<1> Dougherty, bit<1> DeSmet) {
        meta.Lumberton.Crary = Oskawalik;
        meta.Lumberton.Winnebago = Dougherty;
        meta.Lumberton.Braxton = DeSmet;
    }
    @name(".Alabam") table Alabam {
        actions = {
            Kaufman();
            @defaultonly NoAction();
        }
        key = {
            meta.Stanwood.Blackman: exact @name("Stanwood.Blackman") ;
            meta.Stanwood.Fernway : exact @name("Stanwood.Fernway") ;
            meta.Stanwood.Hackney : exact @name("Stanwood.Hackney") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    apply {
        if (meta.Miranda.Exira == 1w0 && meta.Miranda.Washta == 1w1) 
            Alabam.apply();
    }
}

control Goodyear(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Lakeside") action Lakeside() {
    }
    @name(".Dobbins") action Dobbins() {
        hdr.Mondovi[0].setValid();
        hdr.Mondovi[0].Toxey = meta.Stanwood.Pawtucket;
        hdr.Mondovi[0].Hercules = hdr.Thayne.Brashear;
        hdr.Mondovi[0].Elvaston = meta.Selawik.Cistern;
        hdr.Mondovi[0].Leona = meta.Selawik.Hermiston;
        hdr.Thayne.Brashear = 16w0x8100;
    }
    @name(".Coalton") table Coalton {
        actions = {
            Lakeside();
            Dobbins();
        }
        key = {
            meta.Stanwood.Pawtucket   : exact @name("Stanwood.Pawtucket") ;
            hdr.eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        size = 128;
        default_action = Dobbins();
    }
    apply {
        Coalton.apply();
    }
}

control Gwinn(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Speedway") action Speedway(bit<6> Suwanee) {
        meta.Selawik.Lizella = Suwanee;
    }
    @name(".Halltown") action Halltown(bit<3> Ferry) {
        meta.Selawik.Cistern = Ferry;
    }
    @name(".Muncie") action Muncie(bit<3> Piperton, bit<6> Wyocena) {
        meta.Selawik.Cistern = Piperton;
        meta.Selawik.Lizella = Wyocena;
    }
    @name(".Sunman") action Sunman(bit<1> Davie, bit<1> Ochoa) {
        meta.Selawik.Wapinitia = meta.Selawik.Wapinitia | Davie;
        meta.Selawik.Hartville = meta.Selawik.Hartville | Ochoa;
    }
    @name(".Sopris") table Sopris {
        actions = {
            Speedway();
            Halltown();
            Muncie();
            @defaultonly NoAction();
        }
        key = {
            meta.ElkFalls.Topmost            : exact @name("ElkFalls.Topmost") ;
            meta.Selawik.Wapinitia           : exact @name("Selawik.Wapinitia") ;
            meta.Selawik.Hartville           : exact @name("Selawik.Hartville") ;
            hdr.ig_intr_md_for_tm.ingress_cos: exact @name("ig_intr_md_for_tm.ingress_cos") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".Termo") table Termo {
        actions = {
            Sunman();
        }
        size = 1;
        default_action = Sunman();
    }
    apply {
        Termo.apply();
        Sopris.apply();
    }
}

control Hanks(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Excel") action Excel() {
        meta.DuckHill.Enderlin = meta.Mesita.Westpoint;
    }
    @name(".Margie") action Margie() {
    }
    @name(".Almont") action Almont() {
        meta.DuckHill.Berea = meta.Mesita.Monohan;
    }
    @name(".Moclips") action Moclips() {
        meta.DuckHill.Berea = meta.Mesita.Globe;
    }
    @name(".Deerwood") action Deerwood() {
        meta.DuckHill.Berea = meta.Mesita.Westpoint;
    }
    @immediate(0) @name(".Alzada") table Alzada {
        actions = {
            Excel();
            Margie();
            @defaultonly NoAction();
        }
        key = {
            hdr.Corum.isValid()   : ternary @name("Corum.$valid$") ;
            hdr.Varnell.isValid() : ternary @name("Varnell.$valid$") ;
            hdr.BlackOak.isValid(): ternary @name("BlackOak.$valid$") ;
            hdr.Comunas.isValid() : ternary @name("Comunas.$valid$") ;
        }
        size = 6;
        default_action = NoAction();
    }
    @action_default_only("Margie") @immediate(0) @name(".Frewsburg") table Frewsburg {
        actions = {
            Almont();
            Moclips();
            Deerwood();
            Margie();
            @defaultonly NoAction();
        }
        key = {
            hdr.Corum.isValid()   : ternary @name("Corum.$valid$") ;
            hdr.Varnell.isValid() : ternary @name("Varnell.$valid$") ;
            hdr.Sprout.isValid()  : ternary @name("Sprout.$valid$") ;
            hdr.Heppner.isValid() : ternary @name("Heppner.$valid$") ;
            hdr.Lyncourt.isValid(): ternary @name("Lyncourt.$valid$") ;
            hdr.BlackOak.isValid(): ternary @name("BlackOak.$valid$") ;
            hdr.Comunas.isValid() : ternary @name("Comunas.$valid$") ;
            hdr.Kasilof.isValid() : ternary @name("Kasilof.$valid$") ;
            hdr.Holliday.isValid(): ternary @name("Holliday.$valid$") ;
            hdr.Thayne.isValid()  : ternary @name("Thayne.$valid$") ;
        }
        size = 256;
        default_action = NoAction();
    }
    apply {
        Alzada.apply();
        Frewsburg.apply();
    }
}

@name("Genola") struct Genola {
    bit<8>  Leoma;
    bit<24> Arvada;
    bit<24> Hitterdal;
    bit<16> Pardee;
    bit<16> Dixmont;
}

control Hilburn(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".McCartys") action McCartys() {
        digest<Genola>(32w0, { meta.Kingsland.Leoma, meta.Miranda.Arvada, meta.Miranda.Hitterdal, meta.Miranda.Pardee, meta.Miranda.Dixmont });
    }
    @name(".Talco") table Talco {
        actions = {
            McCartys();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        if (meta.Miranda.Bammel == 1w1) 
            Talco.apply();
    }
}

control Hooks(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Rolla") action Rolla(bit<16> Triplett) {
        meta.Miranda.Dixmont = Triplett;
    }
    @name(".Silica") action Silica() {
        meta.Miranda.Chugwater = 1w1;
        meta.Kingsland.Leoma = 8w1;
    }
    @name(".Yreka") action Yreka(bit<8> Lapeer, bit<1> Harriet, bit<1> Goodrich, bit<1> Cowan, bit<1> Needham) {
        meta.Tuskahoma.Wallace = Lapeer;
        meta.Tuskahoma.Tiburon = Harriet;
        meta.Tuskahoma.Covina = Goodrich;
        meta.Tuskahoma.Laton = Cowan;
        meta.Tuskahoma.Bowen = Needham;
    }
    @name(".Tuttle") action Tuttle(bit<16> Huffman, bit<8> Diomede, bit<1> Grays, bit<1> Leucadia, bit<1> Waupaca, bit<1> Claypool) {
        meta.Miranda.Bemis = Huffman;
        meta.Miranda.Ballville = 1w1;
        Yreka(Diomede, Grays, Leucadia, Waupaca, Claypool);
    }
    @name(".Margie") action Margie() {
    }
    @name(".Newtonia") action Newtonia(bit<16> Point, bit<8> Bunavista, bit<1> Mathias, bit<1> Canfield, bit<1> Hooker, bit<1> Darden, bit<1> Francisco) {
        meta.Miranda.Pardee = Point;
        meta.Miranda.Bemis = Point;
        meta.Miranda.Ballville = Francisco;
        Yreka(Bunavista, Mathias, Canfield, Hooker, Darden);
    }
    @name(".Islen") action Islen() {
        meta.Miranda.Uniopolis = 1w1;
    }
    @name(".Sarepta") action Sarepta() {
        meta.Miranda.Pardee = (bit<16>)meta.ElkFalls.Kirkwood;
        meta.Miranda.Dixmont = (bit<16>)meta.ElkFalls.Secaucus;
    }
    @name(".Dowell") action Dowell(bit<16> Norias) {
        meta.Miranda.Pardee = Norias;
        meta.Miranda.Dixmont = (bit<16>)meta.ElkFalls.Secaucus;
    }
    @name(".Palmer") action Palmer() {
        meta.Miranda.Pardee = (bit<16>)hdr.Mondovi[0].Toxey;
        meta.Miranda.Dixmont = (bit<16>)meta.ElkFalls.Secaucus;
    }
    @name(".Camargo") action Camargo() {
        meta.Roxboro.Burwell = hdr.Sprout.Carlson;
        meta.Roxboro.Gardena = hdr.Sprout.Turkey;
        meta.Roxboro.Heaton = hdr.Sprout.Klukwan;
        meta.Rockham.Coconut = hdr.Heppner.Parkland;
        meta.Rockham.Bladen = hdr.Heppner.Clermont;
        meta.Rockham.Davant = hdr.Heppner.Quitman;
        meta.Rockham.Locke = hdr.Heppner.Finlayson;
        meta.Miranda.Leland = hdr.Lyncourt.Lanesboro;
        meta.Miranda.Newland = hdr.Lyncourt.ElRio;
        meta.Miranda.Arvada = hdr.Lyncourt.Trimble;
        meta.Miranda.Hitterdal = hdr.Lyncourt.Paulding;
        meta.Miranda.Ipava = hdr.Lyncourt.Brashear;
        meta.Miranda.Cowden = meta.Loogootee.Kneeland;
        meta.Miranda.Kotzebue = meta.Loogootee.Mishawaka;
        meta.Miranda.Nettleton = meta.Loogootee.Rawson;
        meta.Miranda.Woodsdale = meta.Loogootee.Marcus;
        meta.Miranda.Tulsa = meta.Loogootee.Maybeury;
        meta.Miranda.Marbury = 1w0;
        meta.Stanwood.Funkley = 3w1;
        meta.ElkFalls.Topmost = 2w1;
        meta.ElkFalls.Cadott = 3w0;
        meta.ElkFalls.Switzer = 6w0;
        meta.Selawik.Wapinitia = 1w1;
        meta.Selawik.Hartville = 1w1;
    }
    @name(".Skime") action Skime() {
        meta.Miranda.Metzger = 2w0;
        meta.Roxboro.Burwell = hdr.Kasilof.Carlson;
        meta.Roxboro.Gardena = hdr.Kasilof.Turkey;
        meta.Roxboro.Heaton = hdr.Kasilof.Klukwan;
        meta.Rockham.Coconut = hdr.Holliday.Parkland;
        meta.Rockham.Bladen = hdr.Holliday.Clermont;
        meta.Rockham.Davant = hdr.Holliday.Quitman;
        meta.Rockham.Locke = hdr.Holliday.Finlayson;
        meta.Miranda.Leland = hdr.Thayne.Lanesboro;
        meta.Miranda.Newland = hdr.Thayne.ElRio;
        meta.Miranda.Arvada = hdr.Thayne.Trimble;
        meta.Miranda.Hitterdal = hdr.Thayne.Paulding;
        meta.Miranda.Ipava = hdr.Thayne.Brashear;
        meta.Miranda.Cowden = meta.Loogootee.Livengood;
        meta.Miranda.Kotzebue = meta.Loogootee.Cashmere;
        meta.Miranda.Nettleton = meta.Loogootee.WestGate;
        meta.Miranda.Woodsdale = meta.Loogootee.Carnegie;
        meta.Miranda.Tulsa = meta.Loogootee.Standard;
        meta.Selawik.Hermiston = hdr.Mondovi[0].Leona;
        meta.Miranda.Marbury = meta.Loogootee.Froid;
    }
    @name(".Derita") action Derita(bit<8> Basic, bit<1> Hatteras, bit<1> Theta, bit<1> Higgston, bit<1> Caborn) {
        meta.Miranda.Bemis = (bit<16>)hdr.Mondovi[0].Toxey;
        meta.Miranda.Ballville = 1w1;
        Yreka(Basic, Hatteras, Theta, Higgston, Caborn);
    }
    @name(".Guion") action Guion(bit<8> Trail, bit<1> Seattle, bit<1> Bridgton, bit<1> RockyGap, bit<1> Slayden) {
        meta.Miranda.Bemis = (bit<16>)meta.ElkFalls.Kirkwood;
        meta.Miranda.Ballville = 1w1;
        Yreka(Trail, Seattle, Bridgton, RockyGap, Slayden);
    }
    @name(".Jenera") table Jenera {
        actions = {
            Rolla();
            Silica();
        }
        key = {
            hdr.Kasilof.Carlson: exact @name("Kasilof.Carlson") ;
        }
        size = 4096;
        default_action = Silica();
    }
    @action_default_only("Margie") @name(".Micco") table Micco {
        actions = {
            Tuttle();
            Margie();
            @defaultonly NoAction();
        }
        key = {
            meta.ElkFalls.Secaucus: exact @name("ElkFalls.Secaucus") ;
            hdr.Mondovi[0].Toxey  : exact @name("Mondovi[0].Toxey") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".Paxico") table Paxico {
        actions = {
            Newtonia();
            Islen();
            @defaultonly NoAction();
        }
        key = {
            hdr.Harney.Baroda: exact @name("Harney.Baroda") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    @name(".Pittsboro") table Pittsboro {
        actions = {
            Sarepta();
            Dowell();
            Palmer();
            @defaultonly NoAction();
        }
        key = {
            meta.ElkFalls.Secaucus  : ternary @name("ElkFalls.Secaucus") ;
            hdr.Mondovi[0].isValid(): exact @name("Mondovi[0].$valid$") ;
            hdr.Mondovi[0].Toxey    : ternary @name("Mondovi[0].Toxey") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    @name(".Supai") table Supai {
        actions = {
            Camargo();
            Skime();
        }
        key = {
            hdr.Thayne.Lanesboro: exact @name("Thayne.Lanesboro") ;
            hdr.Thayne.ElRio    : exact @name("Thayne.ElRio") ;
            hdr.Kasilof.Turkey  : exact @name("Kasilof.Turkey") ;
            meta.Miranda.Metzger: exact @name("Miranda.Metzger") ;
        }
        size = 1024;
        default_action = Skime();
    }
    @name(".Westbrook") table Westbrook {
        actions = {
            Margie();
            Derita();
            @defaultonly NoAction();
        }
        key = {
            hdr.Mondovi[0].Toxey: exact @name("Mondovi[0].Toxey") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    @name(".Wyman") table Wyman {
        actions = {
            Margie();
            Guion();
            @defaultonly NoAction();
        }
        key = {
            meta.ElkFalls.Kirkwood: exact @name("ElkFalls.Kirkwood") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    apply {
        switch (Supai.apply().action_run) {
            Camargo: {
                Jenera.apply();
                Paxico.apply();
            }
            Skime: {
                if (!hdr.Louin.isValid() && meta.ElkFalls.Ladelle == 1w1) 
                    Pittsboro.apply();
                if (hdr.Mondovi[0].isValid()) 
                    switch (Micco.apply().action_run) {
                        Margie: {
                            Westbrook.apply();
                        }
                    }

                else 
                    Wyman.apply();
            }
        }

    }
}

control LaPalma(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".SwissAlp") meter(32w2304, MeterType.packets) SwissAlp;
    @name(".McGonigle") action McGonigle(bit<32> ElLago) {
        SwissAlp.execute_meter<bit<2>>(ElLago, hdr.ig_intr_md_for_tm.packet_color);
    }
    @name(".Talkeetna") table Talkeetna {
        actions = {
            McGonigle();
            @defaultonly NoAction();
        }
        key = {
            meta.ElkFalls.Lovilia: exact @name("ElkFalls.Lovilia") ;
            meta.Selawik.Coffman : exact @name("Selawik.Coffman") ;
        }
        size = 2304;
        default_action = NoAction();
    }
    apply {
        if (hdr.ig_intr_md_for_tm.drop_ctl & 3w0x1 == 3w0 && meta.Stanwood.Northcote == 1w1 || hdr.ig_intr_md_for_tm.drop_ctl & 3w0x2 == 3w0 && hdr.ig_intr_md_for_tm.copy_to_cpu == 1w1) 
            Talkeetna.apply();
    }
}

control Sewaren(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Humacao") action Humacao(bit<9> Wardville) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = Wardville;
    }
    @name(".Margie") action Margie() {
    }
    @name(".Glenshaw") table Glenshaw {
        actions = {
            Humacao();
            Margie();
            @defaultonly NoAction();
        }
        key = {
            meta.Stanwood.Trenary: exact @name("Stanwood.Trenary") ;
            meta.DuckHill.Berea  : selector @name("DuckHill.Berea") ;
        }
        size = 1024;
        implementation = Wisdom;
        default_action = NoAction();
    }
    apply {
        if (meta.Stanwood.Trenary & 16w0x2000 == 16w0x2000) 
            Glenshaw.apply();
    }
}

control Lennep(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Columbia") action Columbia() {
        meta.Miranda.Exira = 1w1;
        mark_to_drop();
    }
    @name(".Skagway") action Skagway() {
        meta.Miranda.Hodges = 1w1;
        Columbia();
    }
    @name(".Potter") table Potter {
        actions = {
            Skagway();
        }
        size = 1;
        default_action = Skagway();
    }
    @name(".Sewaren") Sewaren() Sewaren_0;
    apply {
        if (meta.Miranda.Exira == 1w0) 
            if (meta.Stanwood.Boistfort == 1w0 && meta.Miranda.Washta == 1w0 && meta.Miranda.Golden == 1w0 && meta.Miranda.Dixmont == meta.Stanwood.Trenary) 
                Potter.apply();
            else 
                Sewaren_0.apply(hdr, meta, standard_metadata);
    }
}

control Lurton(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Wellford") action Wellford(bit<12> Hilltop) {
        meta.Stanwood.Pawtucket = Hilltop;
    }
    @name(".LaPlant") action LaPlant() {
        meta.Stanwood.Pawtucket = (bit<12>)meta.Stanwood.Hackney;
    }
    @name(".Cockrum") table Cockrum {
        actions = {
            Wellford();
            LaPlant();
        }
        key = {
            hdr.eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
            meta.Stanwood.Hackney     : exact @name("Stanwood.Hackney") ;
        }
        size = 4096;
        default_action = LaPlant();
    }
    apply {
        Cockrum.apply();
    }
}

@name("Geneva") struct Geneva {
    bit<8>  Leoma;
    bit<16> Pardee;
    bit<24> Trimble;
    bit<24> Paulding;
    bit<32> Carlson;
}

control Malabar(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Milam") action Milam() {
        digest<Geneva>(32w0, { meta.Kingsland.Leoma, meta.Miranda.Pardee, hdr.Lyncourt.Trimble, hdr.Lyncourt.Paulding, hdr.Kasilof.Carlson });
    }
    @name(".Bloomburg") table Bloomburg {
        actions = {
            Milam();
        }
        size = 1;
        default_action = Milam();
    }
    apply {
        if (meta.Miranda.Chugwater == 1w1) 
            Bloomburg.apply();
    }
}

control Mogadore(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Nellie") @min_width(16) direct_counter(CounterType.packets_and_bytes) Nellie;
    @name(".Milan") action Milan() {
        meta.Miranda.Ogunquit = 1w1;
    }
    @name(".Olene") action Olene(bit<8> Advance, bit<1> Dunbar) {
        meta.Stanwood.Northcote = 1w1;
        meta.Stanwood.LaneCity = Advance;
        meta.Miranda.Washta = 1w1;
        meta.Selawik.Wauneta = Dunbar;
    }
    @name(".Odenton") action Odenton() {
        meta.Miranda.Welch = 1w1;
        meta.Miranda.Colona = 1w1;
    }
    @name(".Cisne") action Cisne() {
        meta.Miranda.Washta = 1w1;
    }
    @name(".Thomas") action Thomas() {
        meta.Miranda.Golden = 1w1;
    }
    @name(".Berne") action Berne() {
        meta.Miranda.Colona = 1w1;
    }
    @name(".White") action White() {
        meta.Miranda.Washta = 1w1;
        meta.Miranda.Kekoskee = 1w1;
    }
    @name(".Jacobs") table Jacobs {
        actions = {
            Milan();
            @defaultonly NoAction();
        }
        key = {
            hdr.Thayne.Trimble : ternary @name("Thayne.Trimble") ;
            hdr.Thayne.Paulding: ternary @name("Thayne.Paulding") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".Olene") action Olene_0(bit<8> Advance, bit<1> Dunbar) {
        Nellie.count();
        meta.Stanwood.Northcote = 1w1;
        meta.Stanwood.LaneCity = Advance;
        meta.Miranda.Washta = 1w1;
        meta.Selawik.Wauneta = Dunbar;
    }
    @name(".Odenton") action Odenton_0() {
        Nellie.count();
        meta.Miranda.Welch = 1w1;
        meta.Miranda.Colona = 1w1;
    }
    @name(".Cisne") action Cisne_0() {
        Nellie.count();
        meta.Miranda.Washta = 1w1;
    }
    @name(".Thomas") action Thomas_0() {
        Nellie.count();
        meta.Miranda.Golden = 1w1;
    }
    @name(".Berne") action Berne_0() {
        Nellie.count();
        meta.Miranda.Colona = 1w1;
    }
    @name(".White") action White_0() {
        Nellie.count();
        meta.Miranda.Washta = 1w1;
        meta.Miranda.Kekoskee = 1w1;
    }
    @name(".Pensaukee") table Pensaukee {
        actions = {
            Olene_0();
            Odenton_0();
            Cisne_0();
            Thomas_0();
            Berne_0();
            White_0();
            @defaultonly NoAction();
        }
        key = {
            meta.ElkFalls.Lovilia: exact @name("ElkFalls.Lovilia") ;
            hdr.Thayne.Lanesboro : ternary @name("Thayne.Lanesboro") ;
            hdr.Thayne.ElRio     : ternary @name("Thayne.ElRio") ;
        }
        size = 1024;
        counters = Nellie;
        default_action = NoAction();
    }
    apply {
        Pensaukee.apply();
        Jacobs.apply();
    }
}

control Rankin(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Fairchild") action Fairchild(bit<3> Juneau, bit<5> Adelino) {
        hdr.ig_intr_md_for_tm.ingress_cos = Juneau;
        hdr.ig_intr_md_for_tm.qid = Adelino;
    }
    @name(".Toano") table Toano {
        actions = {
            Fairchild();
            @defaultonly NoAction();
        }
        key = {
            meta.ElkFalls.Topmost: ternary @name("ElkFalls.Topmost") ;
            meta.ElkFalls.Cadott : ternary @name("ElkFalls.Cadott") ;
            meta.Selawik.Cistern : ternary @name("Selawik.Cistern") ;
            meta.Selawik.Lizella : ternary @name("Selawik.Lizella") ;
            meta.Selawik.Wauneta : ternary @name("Selawik.Wauneta") ;
        }
        size = 81;
        default_action = NoAction();
    }
    apply {
        Toano.apply();
    }
}

control Risco(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".WestBend") action WestBend() {
        meta.Stanwood.Funkley = 3w2;
        meta.Stanwood.Trenary = 16w0x2000 | (bit<16>)hdr.Louin.Elsmere;
    }
    @name(".Emory") action Emory(bit<16> Hospers) {
        meta.Stanwood.Funkley = 3w2;
        hdr.ig_intr_md_for_tm.ucast_egress_port = (bit<9>)Hospers;
        meta.Stanwood.Trenary = Hospers;
    }
    @name(".Columbia") action Columbia() {
        meta.Miranda.Exira = 1w1;
        mark_to_drop();
    }
    @name(".Runnemede") action Runnemede() {
        Columbia();
    }
    @name(".Hoven") table Hoven {
        actions = {
            WestBend();
            Emory();
            Runnemede();
        }
        key = {
            hdr.Louin.Placid : exact @name("Louin.Placid") ;
            hdr.Louin.Tahuya : exact @name("Louin.Tahuya") ;
            hdr.Louin.Fontana: exact @name("Louin.Fontana") ;
            hdr.Louin.Elsmere: exact @name("Louin.Elsmere") ;
        }
        size = 256;
        default_action = Runnemede();
    }
    apply {
        Hoven.apply();
    }
}

control SanRemo(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Sutter") action Sutter(bit<24> Mabelvale, bit<24> Maxwelton) {
        meta.Stanwood.Tingley = Mabelvale;
        meta.Stanwood.Emida = Maxwelton;
    }
    @name(".Cotter") action Cotter() {
        meta.Stanwood.Brothers = 1w1;
        meta.Stanwood.Siloam = 3w2;
    }
    @name(".Nerstrand") action Nerstrand() {
        meta.Stanwood.Brothers = 1w1;
        meta.Stanwood.Siloam = 3w1;
    }
    @name(".Margie") action Margie() {
    }
    @name(".Alabaster") action Alabaster() {
        hdr.Thayne.Lanesboro = meta.Stanwood.Blackman;
        hdr.Thayne.ElRio = meta.Stanwood.Fernway;
        hdr.Thayne.Trimble = meta.Stanwood.Tingley;
        hdr.Thayne.Paulding = meta.Stanwood.Emida;
    }
    @name(".Horsehead") action Horsehead() {
        Alabaster();
        hdr.Kasilof.Beatrice = hdr.Kasilof.Beatrice + 8w255;
        hdr.Kasilof.Klukwan = meta.Selawik.Lizella;
    }
    @name(".Lowland") action Lowland() {
        Alabaster();
        hdr.Holliday.Henderson = hdr.Holliday.Henderson + 8w255;
        hdr.Holliday.Finlayson = meta.Selawik.Lizella;
    }
    @name(".Wheatland") action Wheatland() {
        hdr.Kasilof.Klukwan = meta.Selawik.Lizella;
    }
    @name(".Tatum") action Tatum() {
        hdr.Holliday.Finlayson = meta.Selawik.Lizella;
    }
    @name(".Dobbins") action Dobbins() {
        hdr.Mondovi[0].setValid();
        hdr.Mondovi[0].Toxey = meta.Stanwood.Pawtucket;
        hdr.Mondovi[0].Hercules = hdr.Thayne.Brashear;
        hdr.Mondovi[0].Elvaston = meta.Selawik.Cistern;
        hdr.Mondovi[0].Leona = meta.Selawik.Hermiston;
        hdr.Thayne.Brashear = 16w0x8100;
    }
    @name(".Greycliff") action Greycliff() {
        Dobbins();
    }
    @name(".Kerrville") action Kerrville(bit<24> Estrella, bit<24> Kansas, bit<24> Blanding, bit<24> Riley) {
        hdr.Teaneck.setValid();
        hdr.Teaneck.Lanesboro = Estrella;
        hdr.Teaneck.ElRio = Kansas;
        hdr.Teaneck.Trimble = Blanding;
        hdr.Teaneck.Paulding = Riley;
        hdr.Teaneck.Brashear = 16w0xbf00;
        hdr.Louin.setValid();
        hdr.Louin.Placid = meta.Stanwood.Loveland;
        hdr.Louin.Tahuya = meta.Stanwood.Trion;
        hdr.Louin.Fontana = meta.Stanwood.Captiva;
        hdr.Louin.Elsmere = meta.Stanwood.Ivanpah;
        hdr.Louin.WyeMills = meta.Stanwood.LaneCity;
    }
    @name(".Trevorton") action Trevorton() {
        hdr.Teaneck.setInvalid();
        hdr.Louin.setInvalid();
    }
    @name(".Dialville") action Dialville() {
        hdr.Harney.setInvalid();
        hdr.Comunas.setInvalid();
        hdr.Alberta.setInvalid();
        hdr.Thayne = hdr.Lyncourt;
        hdr.Lyncourt.setInvalid();
        hdr.Kasilof.setInvalid();
    }
    @name(".Powhatan") action Powhatan() {
        Dialville();
        hdr.Sprout.Klukwan = meta.Selawik.Lizella;
    }
    @name(".Buckholts") action Buckholts() {
        Dialville();
        hdr.Heppner.Finlayson = meta.Selawik.Lizella;
    }
    @name(".Deferiet") action Deferiet(bit<6> Pachuta, bit<10> Baker, bit<4> Kooskia, bit<12> Despard) {
        meta.Stanwood.Loveland = Pachuta;
        meta.Stanwood.Trion = Baker;
        meta.Stanwood.Captiva = Kooskia;
        meta.Stanwood.Ivanpah = Despard;
    }
    @name(".Ivydale") table Ivydale {
        actions = {
            Sutter();
            @defaultonly NoAction();
        }
        key = {
            meta.Stanwood.Siloam: exact @name("Stanwood.Siloam") ;
        }
        size = 8;
        default_action = NoAction();
    }
    @name(".RichBar") table RichBar {
        actions = {
            Cotter();
            Nerstrand();
            @defaultonly Margie();
        }
        key = {
            meta.Stanwood.Shirley     : exact @name("Stanwood.Shirley") ;
            hdr.eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        size = 16;
        default_action = Margie();
    }
    @name(".Tyrone") table Tyrone {
        actions = {
            Horsehead();
            Lowland();
            Wheatland();
            Tatum();
            Greycliff();
            Kerrville();
            Trevorton();
            Dialville();
            Powhatan();
            Buckholts();
            @defaultonly NoAction();
        }
        key = {
            meta.Stanwood.Funkley  : exact @name("Stanwood.Funkley") ;
            meta.Stanwood.Siloam   : exact @name("Stanwood.Siloam") ;
            meta.Stanwood.Boistfort: exact @name("Stanwood.Boistfort") ;
            hdr.Kasilof.isValid()  : ternary @name("Kasilof.$valid$") ;
            hdr.Holliday.isValid() : ternary @name("Holliday.$valid$") ;
            hdr.Sprout.isValid()   : ternary @name("Sprout.$valid$") ;
            hdr.Heppner.isValid()  : ternary @name("Heppner.$valid$") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".Vernal") table Vernal {
        actions = {
            Deferiet();
            @defaultonly NoAction();
        }
        key = {
            meta.Stanwood.NewAlbin: exact @name("Stanwood.NewAlbin") ;
        }
        size = 256;
        default_action = NoAction();
    }
    apply {
        switch (RichBar.apply().action_run) {
            Margie: {
                Ivydale.apply();
            }
        }

        Vernal.apply();
        Tyrone.apply();
    }
}

control Silesia(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Jones") action Jones(bit<16> Sheldahl) {
        meta.Sallisaw.Cutler = Sheldahl;
    }
    @selector_max_group_size(256) @name(".Subiaco") table Subiaco {
        actions = {
            Jones();
            @defaultonly NoAction();
        }
        key = {
            meta.Sallisaw.Minneota: exact @name("Sallisaw.Minneota") ;
            meta.DuckHill.Enderlin: selector @name("DuckHill.Enderlin") ;
        }
        size = 2048;
        implementation = Skokomish;
        default_action = NoAction();
    }
    apply {
        if (meta.Sallisaw.Minneota != 11w0) 
            Subiaco.apply();
    }
}

control Sonoma(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Hoadly") action Hoadly(bit<9> Howland) {
        hdr.ig_intr_md_for_tm.level2_mcast_hash = (bit<13>)meta.DuckHill.Berea;
        hdr.ig_intr_md_for_tm.level2_exclusion_id = Howland;
    }
    @name(".Dresser") table Dresser {
        actions = {
            Hoadly();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (hdr.ig_intr_md_for_tm.mcast_grp_a != 16w0) 
            Dresser.apply();
    }
}

control Sparkill(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Corinth") action Corinth() {
        hash<bit<32>, bit<32>, tuple<bit<32>, bit<32>, bit<16>, bit<16>>, bit<64>>(meta.Mesita.Westpoint, HashAlgorithm.crc32, 32w0, { hdr.Kasilof.Carlson, hdr.Kasilof.Turkey, hdr.Alberta.Dockton, hdr.Alberta.Sontag }, 64w4294967296);
    }
    @name(".Kaolin") table Kaolin {
        actions = {
            Corinth();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        if (hdr.Comunas.isValid()) 
            Kaolin.apply();
    }
}

control Vining(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Jones") action Jones(bit<16> Sheldahl) {
        meta.Sallisaw.Cutler = Sheldahl;
    }
    @name(".Burgdorf") action Burgdorf(bit<11> Excello) {
        meta.Sallisaw.Minneota = Excello;
    }
    @name(".Margie") action Margie() {
    }
    @name(".Godley") action Godley(bit<13> Pettigrew, bit<16> Antlers) {
        meta.Rockham.Bovina = Pettigrew;
        meta.Sallisaw.Cutler = Antlers;
    }
    @name(".Tontogany") action Tontogany(bit<8> Occoquan) {
        meta.Stanwood.Northcote = 1w1;
        meta.Stanwood.LaneCity = 8w9;
    }
    @name(".FoxChase") action FoxChase(bit<11> Veteran, bit<16> Nordland) {
        meta.Rockham.Salineno = Veteran;
        meta.Sallisaw.Cutler = Nordland;
    }
    @name(".Gonzalez") action Gonzalez(bit<16> Shoup, bit<16> Chatfield) {
        meta.Roxboro.Ayden = Shoup;
        meta.Sallisaw.Cutler = Chatfield;
    }
    @name(".Allerton") action Allerton(bit<8> Plush) {
        meta.Stanwood.Northcote = 1w1;
        meta.Stanwood.LaneCity = Plush;
    }
    @idletime_precision(1) @name(".BullRun") table BullRun {
        support_timeout = true;
        actions = {
            Jones();
            Burgdorf();
            Margie();
        }
        key = {
            meta.Tuskahoma.Wallace: exact @name("Tuskahoma.Wallace") ;
            meta.Roxboro.Gardena  : exact @name("Roxboro.Gardena") ;
        }
        size = 65536;
        default_action = Margie();
    }
    @action_default_only("Tontogany") @name(".Dunnellon") table Dunnellon {
        actions = {
            Godley();
            Tontogany();
            @defaultonly NoAction();
        }
        key = {
            meta.Tuskahoma.Wallace     : exact @name("Tuskahoma.Wallace") ;
            meta.Rockham.Bladen[127:64]: lpm @name("Rockham.Bladen[127:64]") ;
        }
        size = 8192;
        default_action = NoAction();
    }
    @action_default_only("Margie") @name(".Ferrum") table Ferrum {
        actions = {
            FoxChase();
            Margie();
            @defaultonly NoAction();
        }
        key = {
            meta.Tuskahoma.Wallace: exact @name("Tuskahoma.Wallace") ;
            meta.Rockham.Bladen   : lpm @name("Rockham.Bladen") ;
        }
        size = 2048;
        default_action = NoAction();
    }
    @ways(2) @atcam_partition_index("Roxboro.Ayden") @atcam_number_partitions(16384) @name(".Gower") table Gower {
        actions = {
            Jones();
            Burgdorf();
            Margie();
        }
        key = {
            meta.Roxboro.Ayden        : exact @name("Roxboro.Ayden") ;
            meta.Roxboro.Gardena[19:0]: lpm @name("Roxboro.Gardena[19:0]") ;
        }
        size = 131072;
        default_action = Margie();
    }
    @atcam_partition_index("Rockham.Bovina") @atcam_number_partitions(8192) @name(".Hiland") table Hiland {
        actions = {
            Jones();
            Burgdorf();
            Margie();
        }
        key = {
            meta.Rockham.Bovina        : exact @name("Rockham.Bovina") ;
            meta.Rockham.Bladen[106:64]: lpm @name("Rockham.Bladen[106:64]") ;
        }
        size = 65536;
        default_action = Margie();
    }
    @atcam_partition_index("Rockham.Salineno") @atcam_number_partitions(2048) @name(".Levasy") table Levasy {
        actions = {
            Jones();
            Burgdorf();
            Margie();
        }
        key = {
            meta.Rockham.Salineno    : exact @name("Rockham.Salineno") ;
            meta.Rockham.Bladen[63:0]: lpm @name("Rockham.Bladen[63:0]") ;
        }
        size = 16384;
        default_action = Margie();
    }
    @idletime_precision(1) @name(".Mackville") table Mackville {
        support_timeout = true;
        actions = {
            Jones();
            Burgdorf();
            Margie();
        }
        key = {
            meta.Tuskahoma.Wallace: exact @name("Tuskahoma.Wallace") ;
            meta.Rockham.Bladen   : exact @name("Rockham.Bladen") ;
        }
        size = 65536;
        default_action = Margie();
    }
    @action_default_only("Margie") @stage(2, 8192) @stage(3) @name(".Merkel") table Merkel {
        actions = {
            Gonzalez();
            Margie();
            @defaultonly NoAction();
        }
        key = {
            meta.Tuskahoma.Wallace: exact @name("Tuskahoma.Wallace") ;
            meta.Roxboro.Gardena  : lpm @name("Roxboro.Gardena") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    @action_default_only("Tontogany") @idletime_precision(1) @name(".Sarasota") table Sarasota {
        support_timeout = true;
        actions = {
            Jones();
            Burgdorf();
            Tontogany();
            @defaultonly NoAction();
        }
        key = {
            meta.Tuskahoma.Wallace: exact @name("Tuskahoma.Wallace") ;
            meta.Roxboro.Gardena  : lpm @name("Roxboro.Gardena") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".Valmeyer") table Valmeyer {
        actions = {
            Allerton();
        }
        size = 1;
        default_action = Allerton();
    }
    apply {
        if (meta.Miranda.Exira == 1w0 && meta.Tuskahoma.Higley == 1w1) 
            if (meta.Tuskahoma.Tiburon == 1w1 && meta.Miranda.Woodsdale == 1w1) 
                switch (BullRun.apply().action_run) {
                    Margie: {
                        switch (Merkel.apply().action_run) {
                            Gonzalez: {
                                Gower.apply();
                            }
                            Margie: {
                                Sarasota.apply();
                            }
                        }

                    }
                }

            else 
                if (meta.Tuskahoma.Covina == 1w1 && meta.Miranda.Tulsa == 1w1) 
                    switch (Mackville.apply().action_run) {
                        Margie: {
                            switch (Ferrum.apply().action_run) {
                                FoxChase: {
                                    Levasy.apply();
                                }
                                Margie: {
                                    switch (Dunnellon.apply().action_run) {
                                        Godley: {
                                            Hiland.apply();
                                        }
                                    }

                                }
                            }

                        }
                    }

                else 
                    if (meta.Miranda.Ballville == 1w1) 
                        Valmeyer.apply();
    }
}

control Vinita(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Harshaw") action Harshaw(bit<14> RedBay, bit<1> Danese, bit<12> Hamel, bit<1> Emden, bit<1> Netarts, bit<6> Edler, bit<2> Broadwell, bit<3> Headland, bit<6> Friday) {
        meta.ElkFalls.Secaucus = RedBay;
        meta.ElkFalls.Lakota = Danese;
        meta.ElkFalls.Kirkwood = Hamel;
        meta.ElkFalls.Ladelle = Emden;
        meta.ElkFalls.Neuse = Netarts;
        meta.ElkFalls.Lovilia = Edler;
        meta.ElkFalls.Topmost = Broadwell;
        meta.ElkFalls.Cadott = Headland;
        meta.ElkFalls.Switzer = Friday;
    }
    @command_line("--no-dead-code-elimination") @name(".Raeford") table Raeford {
        actions = {
            Harshaw();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 288;
        default_action = NoAction();
    }
    apply {
        if (hdr.ig_intr_md.resubmit_flag == 1w0) 
            Raeford.apply();
    }
}

control Wanamassa(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Gabbs") @min_width(128) counter(32w1024, CounterType.packets_and_bytes) Gabbs;
    @name(".Hillsview") action Hillsview(bit<32> Norborne) {
        Gabbs.count(Norborne);
    }
    @name(".Fragaria") table Fragaria {
        actions = {
            Hillsview();
            @defaultonly NoAction();
        }
        key = {
            hdr.eg_intr_md.egress_port[6:0]: exact @name("eg_intr_md.egress_port[6:0]") ;
            hdr.eg_intr_md.egress_qid[2:0] : exact @name("eg_intr_md.egress_qid[2:0]") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        Fragaria.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Belvue") Belvue() Belvue_0;
    @name(".Lurton") Lurton() Lurton_0;
    @name(".SanRemo") SanRemo() SanRemo_0;
    @name(".Goodyear") Goodyear() Goodyear_0;
    @name(".Wanamassa") Wanamassa() Wanamassa_0;
    apply {
        Belvue_0.apply(hdr, meta, standard_metadata);
        Lurton_0.apply(hdr, meta, standard_metadata);
        SanRemo_0.apply(hdr, meta, standard_metadata);
        if (meta.Stanwood.Brothers == 1w0 && meta.Stanwood.Funkley != 3w2) 
            Goodyear_0.apply(hdr, meta, standard_metadata);
        Wanamassa_0.apply(hdr, meta, standard_metadata);
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Linden") action Linden() {
        meta.Stanwood.Fosters = 1w1;
    }
    @name(".Fentress") action Fentress(bit<1> Homeacre) {
        Linden();
        hdr.ig_intr_md_for_tm.mcast_grp_a = (bit<16>)meta.Ringwood.Millsboro;
        hdr.ig_intr_md_for_tm.copy_to_cpu = Homeacre | meta.Ringwood.Calumet;
    }
    @name(".Weslaco") action Weslaco(bit<1> Foster) {
        Linden();
        hdr.ig_intr_md_for_tm.mcast_grp_a = (bit<16>)meta.Lumberton.Crary;
        hdr.ig_intr_md_for_tm.copy_to_cpu = Foster | meta.Lumberton.Braxton;
    }
    @name(".Chatanika") action Chatanika(bit<1> Redondo) {
        Linden();
        hdr.ig_intr_md_for_tm.mcast_grp_a = meta.Stanwood.Hackney + 16w4096;
        hdr.ig_intr_md_for_tm.copy_to_cpu = Redondo;
    }
    @name(".Farnham") action Farnham() {
        meta.Stanwood.Virgin = 1w1;
    }
    @name(".Cahokia") action Cahokia(bit<5> Callery) {
        meta.Selawik.Coffman = Callery;
    }
    @name(".Greenbelt") action Greenbelt(bit<5> Romeo, bit<5> Caplis) {
        Cahokia(Romeo);
        hdr.ig_intr_md_for_tm.qid = Caplis;
    }
    @name(".Sandpoint") table Sandpoint {
        actions = {
            Fentress();
            Weslaco();
            Chatanika();
            Farnham();
            @defaultonly NoAction();
        }
        key = {
            meta.Ringwood.Westview  : ternary @name("Ringwood.Westview") ;
            meta.Ringwood.Millsboro : ternary @name("Ringwood.Millsboro") ;
            meta.Lumberton.Crary    : ternary @name("Lumberton.Crary") ;
            meta.Lumberton.Winnebago: ternary @name("Lumberton.Winnebago") ;
            meta.Miranda.Kotzebue   : ternary @name("Miranda.Kotzebue") ;
            meta.Miranda.Washta     : ternary @name("Miranda.Washta") ;
        }
        size = 32;
        default_action = NoAction();
    }
    @name(".Steprock") table Steprock {
        actions = {
            Cahokia();
            Greenbelt();
            @defaultonly NoAction();
        }
        key = {
            meta.Stanwood.Northcote          : ternary @name("Stanwood.Northcote") ;
            hdr.ig_intr_md_for_tm.copy_to_cpu: ternary @name("ig_intr_md_for_tm.copy_to_cpu") ;
            meta.Stanwood.LaneCity           : ternary @name("Stanwood.LaneCity") ;
            meta.Miranda.Woodsdale           : ternary @name("Miranda.Woodsdale") ;
            meta.Miranda.Tulsa               : ternary @name("Miranda.Tulsa") ;
            meta.Miranda.Ipava               : ternary @name("Miranda.Ipava") ;
            meta.Miranda.Kotzebue            : ternary @name("Miranda.Kotzebue") ;
            meta.Miranda.Nettleton           : ternary @name("Miranda.Nettleton") ;
            meta.Stanwood.Boistfort          : ternary @name("Stanwood.Boistfort") ;
            hdr.Alberta.Sontag               : ternary @name("Alberta.Sontag") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".Vinita") Vinita() Vinita_0;
    @name(".Mogadore") Mogadore() Mogadore_0;
    @name(".Hooks") Hooks() Hooks_0;
    @name(".Bienville") Bienville() Bienville_0;
    @name(".CapeFair") CapeFair() CapeFair_0;
    @name(".Campbell") Campbell() Campbell_0;
    @name(".Bronaugh") Bronaugh() Bronaugh_0;
    @name(".Sparkill") Sparkill() Sparkill_0;
    @name(".Vining") Vining() Vining_0;
    @name(".Hanks") Hanks() Hanks_0;
    @name(".BigPiney") BigPiney() BigPiney_0;
    @name(".Silesia") Silesia() Silesia_0;
    @name(".Beaman") Beaman() Beaman_0;
    @name(".Belle") Belle() Belle_0;
    @name(".Armona") Armona() Armona_0;
    @name(".BigBow") BigBow() BigBow_0;
    @name(".Malabar") Malabar() Malabar_0;
    @name(".Hilburn") Hilburn() Hilburn_0;
    @name(".Risco") Risco() Risco_0;
    @name(".Geismar") Geismar() Geismar_0;
    @name(".Chalco") Chalco() Chalco_0;
    @name(".Rankin") Rankin() Rankin_0;
    @name(".Lennep") Lennep() Lennep_0;
    @name(".Gwinn") Gwinn() Gwinn_0;
    @name(".LaPalma") LaPalma() LaPalma_0;
    @name(".Bains") Bains() Bains_0;
    @name(".Sonoma") Sonoma() Sonoma_0;
    @name(".Dixboro") Dixboro() Dixboro_0;
    apply {
        Vinita_0.apply(hdr, meta, standard_metadata);
        if (meta.ElkFalls.Neuse != 1w0) 
            Mogadore_0.apply(hdr, meta, standard_metadata);
        Hooks_0.apply(hdr, meta, standard_metadata);
        if (meta.ElkFalls.Neuse != 1w0) {
            Bienville_0.apply(hdr, meta, standard_metadata);
            CapeFair_0.apply(hdr, meta, standard_metadata);
        }
        Campbell_0.apply(hdr, meta, standard_metadata);
        Bronaugh_0.apply(hdr, meta, standard_metadata);
        Sparkill_0.apply(hdr, meta, standard_metadata);
        if (meta.ElkFalls.Neuse != 1w0) 
            Vining_0.apply(hdr, meta, standard_metadata);
        Hanks_0.apply(hdr, meta, standard_metadata);
        BigPiney_0.apply(hdr, meta, standard_metadata);
        if (meta.ElkFalls.Neuse != 1w0) 
            Silesia_0.apply(hdr, meta, standard_metadata);
        Beaman_0.apply(hdr, meta, standard_metadata);
        Belle_0.apply(hdr, meta, standard_metadata);
        if (meta.ElkFalls.Neuse != 1w0) 
            Armona_0.apply(hdr, meta, standard_metadata);
        BigBow_0.apply(hdr, meta, standard_metadata);
        Malabar_0.apply(hdr, meta, standard_metadata);
        Hilburn_0.apply(hdr, meta, standard_metadata);
        if (meta.Stanwood.Northcote == 1w0) 
            if (hdr.Louin.isValid()) 
                Risco_0.apply(hdr, meta, standard_metadata);
            else {
                Geismar_0.apply(hdr, meta, standard_metadata);
                Chalco_0.apply(hdr, meta, standard_metadata);
            }
        if (!hdr.Louin.isValid()) 
            Rankin_0.apply(hdr, meta, standard_metadata);
        if (meta.Stanwood.Northcote == 1w0) 
            Lennep_0.apply(hdr, meta, standard_metadata);
        if (meta.ElkFalls.Neuse != 1w0) 
            if (meta.Stanwood.Northcote == 1w0 && meta.Miranda.Washta == 1w1) 
                Sandpoint.apply();
            else 
                Steprock.apply();
        if (meta.ElkFalls.Neuse != 1w0) 
            Gwinn_0.apply(hdr, meta, standard_metadata);
        LaPalma_0.apply(hdr, meta, standard_metadata);
        if (hdr.Mondovi[0].isValid()) 
            Bains_0.apply(hdr, meta, standard_metadata);
        if (meta.Stanwood.Northcote == 1w0) 
            Sonoma_0.apply(hdr, meta, standard_metadata);
        Dixboro_0.apply(hdr, meta, standard_metadata);
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<Hobergs>(hdr.Teaneck);
        packet.emit<Rocheport>(hdr.Louin);
        packet.emit<Hobergs>(hdr.Thayne);
        packet.emit<Wolverine>(hdr.Mondovi[0]);
        packet.emit<Flaxton>(hdr.Krupp);
        packet.emit<Toluca>(hdr.Holliday);
        packet.emit<Robinette>(hdr.Kasilof);
        packet.emit<Magasco>(hdr.Alberta);
        packet.emit<Talbotton>(hdr.BlackOak);
        packet.emit<Joseph>(hdr.Comunas);
        packet.emit<Potosi>(hdr.Harney);
        packet.emit<Hobergs>(hdr.Lyncourt);
        packet.emit<Toluca>(hdr.Heppner);
        packet.emit<Robinette>(hdr.Sprout);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
        verify_checksum<tuple<bit<4>, bit<4>, bit<6>, bit<2>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>, bit<16>>(true, { hdr.Kasilof.Dryden, hdr.Kasilof.Talihina, hdr.Kasilof.Klukwan, hdr.Kasilof.Brimley, hdr.Kasilof.Tramway, hdr.Kasilof.Trilby, hdr.Kasilof.Callands, hdr.Kasilof.Valencia, hdr.Kasilof.Beatrice, hdr.Kasilof.Becida, hdr.Kasilof.Carlson, hdr.Kasilof.Turkey }, hdr.Kasilof.Tusculum, HashAlgorithm.csum16);
        verify_checksum<tuple<bit<4>, bit<4>, bit<6>, bit<2>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>, bit<16>>(true, { hdr.Sprout.Dryden, hdr.Sprout.Talihina, hdr.Sprout.Klukwan, hdr.Sprout.Brimley, hdr.Sprout.Tramway, hdr.Sprout.Trilby, hdr.Sprout.Callands, hdr.Sprout.Valencia, hdr.Sprout.Beatrice, hdr.Sprout.Becida, hdr.Sprout.Carlson, hdr.Sprout.Turkey }, hdr.Sprout.Tusculum, HashAlgorithm.csum16);
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum<tuple<bit<4>, bit<4>, bit<6>, bit<2>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>, bit<16>>(true, { hdr.Kasilof.Dryden, hdr.Kasilof.Talihina, hdr.Kasilof.Klukwan, hdr.Kasilof.Brimley, hdr.Kasilof.Tramway, hdr.Kasilof.Trilby, hdr.Kasilof.Callands, hdr.Kasilof.Valencia, hdr.Kasilof.Beatrice, hdr.Kasilof.Becida, hdr.Kasilof.Carlson, hdr.Kasilof.Turkey }, hdr.Kasilof.Tusculum, HashAlgorithm.csum16);
        update_checksum<tuple<bit<4>, bit<4>, bit<6>, bit<2>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>, bit<16>>(true, { hdr.Sprout.Dryden, hdr.Sprout.Talihina, hdr.Sprout.Klukwan, hdr.Sprout.Brimley, hdr.Sprout.Tramway, hdr.Sprout.Trilby, hdr.Sprout.Callands, hdr.Sprout.Valencia, hdr.Sprout.Beatrice, hdr.Sprout.Becida, hdr.Sprout.Carlson, hdr.Sprout.Turkey }, hdr.Sprout.Tusculum, HashAlgorithm.csum16);
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

