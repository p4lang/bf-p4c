#include <core.p4>
#include <v1model.p4>

struct Harvest {
    bit<24> Lasara;
    bit<24> Ivanhoe;
    bit<24> McCune;
    bit<24> Lignite;
    bit<16> Monohan;
    bit<16> Calabash;
    bit<16> Kasilof;
    bit<16> Allegan;
    bit<12> Neches;
    bit<2>  Faulkton;
    bit<1>  Arvada;
    bit<1>  Dushore;
    bit<1>  BeeCave;
    bit<1>  ShowLow;
    bit<1>  Elsey;
    bit<1>  Remington;
    bit<1>  Weslaco;
    bit<1>  Valmont;
    bit<1>  Lindy;
    bit<1>  Browndell;
    bit<1>  KeyWest;
}

struct Tulip {
    bit<128> Lumberton;
    bit<128> Keener;
    bit<20>  Millbrae;
    bit<8>   Newkirk;
}

struct Southdown {
    bit<1> Rehobeth;
    bit<1> Maida;
}

struct Isleta {
    bit<14> Bannack;
    bit<1>  Litroe;
    bit<1>  Ruffin;
    bit<12> Natalbany;
    bit<1>  Montbrook;
    bit<6>  Columbia;
}

struct Loring {
    bit<32> Candle;
    bit<32> Wilmore;
}

struct Accord {
    bit<16> Trimble;
}

struct Roxboro {
    bit<8> Rockfield;
}

struct Asherton {
    bit<8> Higley;
    bit<1> NantyGlo;
    bit<1> Hallwood;
    bit<1> Remsen;
    bit<1> Yerington;
    bit<1> Wickett;
}

struct Stuttgart {
    bit<32> Mendon;
    bit<32> Waimalu;
    bit<8>  Hewins;
    bit<16> Chambers;
}

struct Lostine {
    bit<24> Roscommon;
    bit<24> Bendavis;
    bit<24> RoyalOak;
    bit<24> Blueberry;
    bit<24> Shasta;
    bit<24> Cabot;
    bit<16> Dresser;
    bit<16> Carnero;
    bit<16> Leonidas;
    bit<12> Pelion;
    bit<3>  Alston;
    bit<3>  BlueAsh;
    bit<1>  Pittsboro;
    bit<1>  Bowen;
    bit<1>  Benkelman;
    bit<1>  Lapel;
    bit<1>  Fergus;
    bit<1>  Milam;
    bit<1>  Guadalupe;
    bit<1>  Dubuque;
    bit<8>  Vacherie;
}

header Grenville {
    bit<4>   Melba;
    bit<8>   Meeker;
    bit<20>  Lacona;
    bit<16>  Ralph;
    bit<8>   Belgrade;
    bit<8>   Silesia;
    bit<128> Noelke;
    bit<128> Kipahulu;
}

header Manteo {
    bit<16> Taylors;
    bit<16> Salduro;
    bit<8>  Driftwood;
    bit<8>  Oskaloosa;
    bit<16> Susank;
}

@name("Alamosa") header Alamosa_0 {
    bit<4>  Sunrise;
    bit<4>  Logandale;
    bit<8>  Radcliffe;
    bit<16> Melstrand;
    bit<16> NorthRim;
    bit<3>  Ranier;
    bit<13> Ravena;
    bit<8>  Robinette;
    bit<8>  Tunica;
    bit<16> VanZandt;
    bit<32> Finney;
    bit<32> Alamota;
}

@name("Beaverton") header Beaverton_0 {
    bit<16> Claunch;
    bit<16> Longdale;
    bit<32> Daykin;
    bit<32> Hammett;
    bit<4>  Hartford;
    bit<4>  Oklee;
    bit<8>  Correo;
    bit<16> Alexis;
    bit<16> Bowdon;
    bit<16> Bunker;
}

@name("Langhorne") header Langhorne_0 {
    bit<1>  Surrency;
    bit<1>  Combine;
    bit<1>  Rozet;
    bit<1>  Lenexa;
    bit<1>  Polkville;
    bit<3>  Laplace;
    bit<5>  Charenton;
    bit<3>  Kansas;
    bit<16> Wauconda;
}

header Donnelly {
    bit<16> Linville;
    bit<16> McKee;
    bit<16> Broadus;
    bit<16> Kinston;
}

@name("Caldwell") header Caldwell_0 {
    bit<8>  McManus;
    bit<24> Manilla;
    bit<24> Greenwood;
    bit<8>  Melrose;
}

header Knippa {
    bit<24> SanJuan;
    bit<24> Weatherly;
    bit<24> Gordon;
    bit<24> Topton;
    bit<16> Lilydale;
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

header Marie {
    bit<3>  Fairborn;
    bit<1>  Equality;
    bit<12> Jigger;
    bit<16> Bellmore;
}

struct metadata {
    @pa_solitary("ingress", "Algoa.Calabash") @pa_solitary("ingress", "Algoa.Kasilof") @pa_solitary("ingress", "Algoa.Allegan") @pa_solitary("egress", "Roachdale.Leonidas") @name(".Algoa") 
    Harvest   Algoa;
    @name(".Blevins") 
    Tulip     Blevins;
    @name(".Boyle") 
    Southdown Boyle;
    @name(".Brodnax") 
    Isleta    Brodnax;
    @name(".Buckeye") 
    Loring    Buckeye;
    @name(".Collis") 
    Accord    Collis;
    @name(".DonaAna") 
    Roxboro   DonaAna;
    @name(".Downs") 
    Asherton  Downs;
    @name(".ElJebel") 
    Stuttgart ElJebel;
    @name(".Roachdale") 
    Lostine   Roachdale;
}

struct headers {
    @name(".Baidland") 
    Grenville                                      Baidland;
    @name(".Crestone") 
    Manteo                                         Crestone;
    @name(".Fitzhugh") 
    Alamosa_0                                      Fitzhugh;
    @name(".Frewsburg") 
    Grenville                                      Frewsburg;
    @name(".Lovelady") 
    Beaverton_0                                    Lovelady;
    @name(".Mather") 
    Langhorne_0                                    Mather;
    @name(".Nanson") 
    Donnelly                                       Nanson;
    @name(".Needles") 
    Caldwell_0                                     Needles;
    @name(".Otranto") 
    Donnelly                                       Otranto;
    @name(".Switzer") 
    Alamosa_0                                      Switzer;
    @name(".TroutRun") 
    Knippa                                         TroutRun;
    @name(".Twain") 
    Knippa                                         Twain;
    @name(".Youngwood") 
    Beaverton_0                                    Youngwood;
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
    @name(".Jayton") 
    Marie[2]                                       Jayton;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Alvwood") state Alvwood {
        packet.extract(hdr.Jayton[0]);
        transition select(hdr.Jayton[0].Bellmore) {
            16w0x800: Armona;
            16w0x86dd: Lansdale;
            16w0x806: Rexville;
            default: accept;
        }
    }
    @name(".Armona") state Armona {
        packet.extract(hdr.Switzer);
        transition select(hdr.Switzer.Ravena, hdr.Switzer.Logandale, hdr.Switzer.Tunica) {
            (13w0x0, 4w0x5, 8w0x11): Paxico;
            default: accept;
        }
    }
    @name(".Brawley") state Brawley {
        packet.extract(hdr.Twain);
        transition select(hdr.Twain.Lilydale) {
            16w0x8100: Alvwood;
            16w0x800: Armona;
            16w0x86dd: Lansdale;
            16w0x806: Rexville;
            default: accept;
        }
    }
    @name(".Charlack") state Charlack {
        meta.Algoa.Faulkton = 2w2;
        transition Masardis;
    }
    @name(".Folger") state Folger {
        packet.extract(hdr.TroutRun);
        transition select(hdr.TroutRun.Lilydale) {
            16w0x800: Stecker;
            16w0x86dd: Masardis;
            default: accept;
        }
    }
    @name(".Lansdale") state Lansdale {
        packet.extract(hdr.Baidland);
        transition accept;
    }
    @name(".Masardis") state Masardis {
        packet.extract(hdr.Frewsburg);
        transition accept;
    }
    @name(".Paxico") state Paxico {
        packet.extract(hdr.Otranto);
        transition select(hdr.Otranto.McKee) {
            16w4789: Pittwood;
            default: accept;
        }
    }
    @name(".Pittwood") state Pittwood {
        packet.extract(hdr.Needles);
        meta.Algoa.Faulkton = 2w1;
        transition Folger;
    }
    @name(".Purdon") state Purdon {
        meta.Algoa.Faulkton = 2w2;
        transition Stecker;
    }
    @name(".Rexville") state Rexville {
        packet.extract(hdr.Crestone);
        transition accept;
    }
    @name(".Schaller") state Schaller {
        packet.extract(hdr.Mather);
        transition select(hdr.Mather.Surrency, hdr.Mather.Combine, hdr.Mather.Rozet, hdr.Mather.Lenexa, hdr.Mather.Polkville, hdr.Mather.Laplace, hdr.Mather.Charenton, hdr.Mather.Kansas, hdr.Mather.Wauconda) {
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x800): Purdon;
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x86dd): Charlack;
            default: accept;
        }
    }
    @name(".Stecker") state Stecker {
        packet.extract(hdr.Fitzhugh);
        transition accept;
    }
    @name(".start") state start {
        transition Brawley;
    }
}

@name(".FlyingH") @mode("resilient") action_selector(HashAlgorithm.identity, 32w1024, 32w51) FlyingH;

@name(".Lackey") register<bit<1>>(32w262144) Lackey;

@name(".Seagrove") register<bit<1>>(32w262144) Seagrove;

control Alakanuk(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Cricket") RegisterAction<bit<1>, bit<1>>(Seagrove) Cricket = {
        void apply(inout bit<1> value, out bit<1> rv) {
            rv = 1w0;
            bit<1> in_value;
            in_value = value;
            value = in_value;
            rv = value;
        }
    };
    @name(".Jerico") RegisterAction<bit<1>, bit<1>>(Lackey) Jerico = {
        void apply(inout bit<1> value, out bit<1> rv) {
            rv = 1w0;
            bit<1> in_value;
            in_value = value;
            value = in_value;
            rv = value;
        }
    };
    @name(".Advance") action Advance() {
        meta.Algoa.Neches = meta.Brodnax.Natalbany;
        meta.Algoa.Arvada = 1w0;
    }
    @name(".Telephone") action Telephone() {
        {
            bit<18> temp;
            hash(temp, HashAlgorithm.identity, 18w0, { meta.Brodnax.Columbia, hdr.Jayton[0].Jigger }, 19w262144);
            meta.Boyle.Maida = Jerico.execute((bit<32>)temp);
        }
    }
    @name(".Clementon") action Clementon() {
        {
            bit<18> temp_0;
            hash(temp_0, HashAlgorithm.identity, 18w0, { meta.Brodnax.Columbia, hdr.Jayton[0].Jigger }, 19w262144);
            meta.Boyle.Rehobeth = Cricket.execute((bit<32>)temp_0);
        }
    }
    @name(".Moosic") action Moosic(bit<1> Ossineke) {
        meta.Boyle.Maida = Ossineke;
    }
    @name(".Ackerman") action Ackerman() {
        meta.Algoa.Neches = hdr.Jayton[0].Jigger;
        meta.Algoa.Arvada = 1w1;
    }
    @name(".BigPiney") table BigPiney {
        actions = {
            Advance;
        }
        size = 1;
    }
    @name(".Estrella") table Estrella {
        actions = {
            Telephone;
        }
        size = 1;
        default_action = Telephone();
    }
    @name(".Harpster") table Harpster {
        actions = {
            Clementon;
        }
        size = 1;
        default_action = Clementon();
    }
    @use_hash_action(0) @name(".Hillister") table Hillister {
        actions = {
            Moosic;
        }
        key = {
            meta.Brodnax.Columbia: exact;
        }
        size = 64;
    }
    @name(".Whitewood") table Whitewood {
        actions = {
            Ackerman;
        }
        size = 1;
    }
    apply {
        if (hdr.Jayton[0].isValid()) {
            Whitewood.apply();
            if (meta.Brodnax.Montbrook == 1w1) {
                Harpster.apply();
                Estrella.apply();
            }
        }
        else {
            BigPiney.apply();
            if (meta.Brodnax.Montbrook == 1w1) {
                Hillister.apply();
            }
        }
    }
}

control Caspian(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Ganado") action Ganado(bit<14> Abernant, bit<1> Roseworth, bit<12> Cadott, bit<1> Sutter, bit<1> Hauppauge, bit<6> Grantfork) {
        meta.Brodnax.Bannack = Abernant;
        meta.Brodnax.Litroe = Roseworth;
        meta.Brodnax.Natalbany = Cadott;
        meta.Brodnax.Ruffin = Sutter;
        meta.Brodnax.Montbrook = Hauppauge;
        meta.Brodnax.Columbia = Grantfork;
    }
    @command_line("--no-dead-code-elimination") @name(".Waterman") table Waterman {
        actions = {
            Ganado;
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact;
        }
        size = 288;
    }
    apply {
        if (hdr.ig_intr_md.resubmit_flag == 1w0) {
            Waterman.apply();
        }
    }
}

control Columbus(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Grasmere") action Grasmere() {
        hash(meta.Buckeye.Candle, HashAlgorithm.crc32, (bit<32>)0, { hdr.Twain.SanJuan, hdr.Twain.Weatherly, hdr.Twain.Gordon, hdr.Twain.Topton, hdr.Twain.Lilydale }, (bit<64>)65536);
    }
    @name(".Kapowsin") action Kapowsin() {
        ;
    }
    @immediate(0) @name(".Bernard") table Bernard {
        actions = {
            Grasmere;
            Kapowsin;
        }
        key = {
            hdr.Youngwood.isValid(): ternary;
            hdr.Nanson.isValid()   : ternary;
            hdr.Fitzhugh.isValid() : ternary;
            hdr.Frewsburg.isValid(): ternary;
            hdr.TroutRun.isValid() : ternary;
            hdr.Lovelady.isValid() : ternary;
            hdr.Otranto.isValid()  : ternary;
            hdr.Switzer.isValid()  : ternary;
            hdr.Baidland.isValid() : ternary;
            hdr.Twain.isValid()    : ternary;
        }
        size = 256;
        default_action = Kapowsin();
    }
    apply {
        Bernard.apply();
    }
}

control Fleetwood(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Nederland") action Nederland() {
        hdr.Twain.Lilydale = hdr.Jayton[0].Bellmore;
        hdr.Jayton[0].setInvalid();
    }
    @name(".Gowanda") table Gowanda {
        actions = {
            Nederland;
        }
        size = 1;
        default_action = Nederland();
    }
    apply {
        Gowanda.apply();
    }
}

control Hanston(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Whitman") action Whitman(bit<24> MiraLoma, bit<24> Isabela) {
        meta.Roachdale.Shasta = MiraLoma;
        meta.Roachdale.Cabot = Isabela;
    }
    @name(".Hopkins") action Hopkins() {
        hdr.Twain.SanJuan = meta.Roachdale.Roscommon;
        hdr.Twain.Weatherly = meta.Roachdale.Bendavis;
        hdr.Twain.Gordon = meta.Roachdale.Shasta;
        hdr.Twain.Topton = meta.Roachdale.Cabot;
    }
    @name(".Greenland") action Greenland() {
        Hopkins();
        hdr.Switzer.Robinette = hdr.Switzer.Robinette + 8w255;
    }
    @name(".Wyatte") action Wyatte() {
        Hopkins();
        hdr.Baidland.Silesia = hdr.Baidland.Silesia + 8w255;
    }
    @name(".Ozark") table Ozark {
        actions = {
            Whitman;
        }
        key = {
            meta.Roachdale.Alston: exact;
        }
        size = 8;
        default_action = Whitman(0, 1);
    }
    @name(".Parkline") table Parkline {
        actions = {
            Greenland;
            Wyatte;
        }
        key = {
            meta.Roachdale.BlueAsh: exact;
            meta.Roachdale.Alston : exact;
            meta.Roachdale.Dubuque: exact;
            hdr.Switzer.isValid() : ternary;
            hdr.Baidland.isValid(): ternary;
        }
        size = 512;
    }
    apply {
        Ozark.apply();
        Parkline.apply();
    }
}

@name("Aredale") struct Aredale {
    bit<8>  Rockfield;
    bit<16> Calabash;
    bit<24> Gordon;
    bit<24> Topton;
    bit<32> Finney;
}

control Haugen(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Morita") action Morita() {
        digest<Aredale>((bit<32>)0, { meta.DonaAna.Rockfield, meta.Algoa.Calabash, hdr.TroutRun.Gordon, hdr.TroutRun.Topton, hdr.Switzer.Finney });
    }
    @name(".Vernal") table Vernal {
        actions = {
            Morita;
        }
        size = 1;
        default_action = Morita();
    }
    apply {
        if (meta.Algoa.BeeCave == 1w1) {
            Vernal.apply();
        }
    }
}

control Kaibab(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Coleman") action Coleman() {
        meta.Roachdale.Roscommon = meta.Algoa.Lasara;
        meta.Roachdale.Bendavis = meta.Algoa.Ivanhoe;
        meta.Roachdale.RoyalOak = meta.Algoa.McCune;
        meta.Roachdale.Blueberry = meta.Algoa.Lignite;
        meta.Roachdale.Dresser = meta.Algoa.Calabash;
    }
    @name(".Traverse") table Traverse {
        actions = {
            Coleman;
        }
        size = 1;
        default_action = Coleman();
    }
    apply {
        if (meta.Algoa.Calabash != 16w0) {
            Traverse.apply();
        }
    }
}

control Lamoni(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Celada") action Celada(bit<12> Inola) {
        meta.Roachdale.Pelion = Inola;
    }
    @name(".Elsmere") action Elsmere() {
        meta.Roachdale.Pelion = (bit<12>)meta.Roachdale.Dresser;
    }
    @name(".Luhrig") action Luhrig() {
        meta.Roachdale.Dresser = hdr.eg_intr_md.egress_rid;
    }
    @name(".Cacao") table Cacao {
        actions = {
            Celada;
            Elsmere;
        }
        key = {
            hdr.eg_intr_md.egress_port: exact;
            meta.Roachdale.Dresser    : exact;
        }
        size = 4096;
        default_action = Elsmere();
    }
    @name(".Gratiot") table Gratiot {
        actions = {
            Luhrig;
        }
        key = {
            hdr.eg_intr_md.egress_rid: exact;
        }
        size = 65536;
    }
    apply {
        if (hdr.eg_intr_md.egress_rid != 16w0) {
            Gratiot.apply();
        }
        Cacao.apply();
    }
}

control Mantee(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".McAllen") action McAllen(bit<16> Salus) {
        meta.Algoa.Kasilof = Salus;
    }
    @name(".Gibson") action Gibson() {
        meta.Algoa.BeeCave = 1w1;
        meta.DonaAna.Rockfield = 8w1;
    }
    @name(".Carroll") action Carroll() {
        meta.ElJebel.Mendon = hdr.Fitzhugh.Finney;
        meta.ElJebel.Waimalu = hdr.Fitzhugh.Alamota;
        meta.ElJebel.Hewins = hdr.Fitzhugh.Tunica;
        meta.Blevins.Lumberton = hdr.Frewsburg.Noelke;
        meta.Blevins.Keener = hdr.Frewsburg.Kipahulu;
        meta.Blevins.Millbrae = hdr.Frewsburg.Lacona;
        meta.Algoa.Lasara = hdr.TroutRun.SanJuan;
        meta.Algoa.Ivanhoe = hdr.TroutRun.Weatherly;
        meta.Algoa.McCune = hdr.TroutRun.Gordon;
        meta.Algoa.Lignite = hdr.TroutRun.Topton;
        meta.Algoa.Monohan = hdr.TroutRun.Lilydale;
    }
    @name(".Whatley") action Whatley() {
        meta.Algoa.Faulkton = 2w0;
        meta.ElJebel.Mendon = hdr.Switzer.Finney;
        meta.ElJebel.Waimalu = hdr.Switzer.Alamota;
        meta.ElJebel.Hewins = hdr.Switzer.Tunica;
        meta.Blevins.Lumberton = hdr.Baidland.Noelke;
        meta.Blevins.Keener = hdr.Baidland.Kipahulu;
        meta.Blevins.Millbrae = hdr.Frewsburg.Lacona;
        meta.Algoa.Lasara = hdr.Twain.SanJuan;
        meta.Algoa.Ivanhoe = hdr.Twain.Weatherly;
        meta.Algoa.McCune = hdr.Twain.Gordon;
        meta.Algoa.Lignite = hdr.Twain.Topton;
        meta.Algoa.Monohan = hdr.Twain.Lilydale;
    }
    @name(".LoneJack") action LoneJack(bit<8> Kurthwood, bit<1> Fowler, bit<1> Newcomb, bit<1> Ortley, bit<1> Viroqua) {
        meta.Downs.Higley = Kurthwood;
        meta.Downs.NantyGlo = Fowler;
        meta.Downs.Remsen = Newcomb;
        meta.Downs.Hallwood = Ortley;
        meta.Downs.Yerington = Viroqua;
    }
    @name(".Kenyon") action Kenyon(bit<8> Kurthwood, bit<1> Fowler, bit<1> Newcomb, bit<1> Ortley, bit<1> Viroqua) {
        meta.Algoa.Allegan = (bit<16>)meta.Brodnax.Natalbany;
        meta.Algoa.Remington = 1w1;
        LoneJack(Kurthwood, Fowler, Newcomb, Ortley, Viroqua);
    }
    @name(".Olcott") action Olcott() {
        meta.Algoa.Calabash = (bit<16>)meta.Brodnax.Natalbany;
        meta.Algoa.Kasilof = (bit<16>)meta.Brodnax.Bannack;
    }
    @name(".Cleta") action Cleta(bit<16> Sublett) {
        meta.Algoa.Calabash = Sublett;
        meta.Algoa.Kasilof = (bit<16>)meta.Brodnax.Bannack;
    }
    @name(".Lofgreen") action Lofgreen() {
        meta.Algoa.Calabash = (bit<16>)hdr.Jayton[0].Jigger;
        meta.Algoa.Kasilof = (bit<16>)meta.Brodnax.Bannack;
    }
    @name(".Rendville") action Rendville(bit<16> Oriskany, bit<8> Kurthwood, bit<1> Fowler, bit<1> Newcomb, bit<1> Ortley, bit<1> Viroqua, bit<1> Gerlach) {
        meta.Algoa.Calabash = Oriskany;
        meta.Algoa.Remington = Gerlach;
        LoneJack(Kurthwood, Fowler, Newcomb, Ortley, Viroqua);
    }
    @name(".Egypt") action Egypt() {
        meta.Algoa.Elsey = 1w1;
    }
    @name(".Dilia") action Dilia(bit<16> Gladstone, bit<8> Kurthwood, bit<1> Fowler, bit<1> Newcomb, bit<1> Ortley, bit<1> Viroqua) {
        meta.Algoa.Allegan = Gladstone;
        meta.Algoa.Remington = 1w1;
        LoneJack(Kurthwood, Fowler, Newcomb, Ortley, Viroqua);
    }
    @name(".Kapowsin") action Kapowsin() {
        ;
    }
    @name(".Kamas") action Kamas(bit<8> Kurthwood, bit<1> Fowler, bit<1> Newcomb, bit<1> Ortley, bit<1> Viroqua) {
        meta.Algoa.Allegan = (bit<16>)hdr.Jayton[0].Jigger;
        meta.Algoa.Remington = 1w1;
        LoneJack(Kurthwood, Fowler, Newcomb, Ortley, Viroqua);
    }
    @name(".Brinson") table Brinson {
        actions = {
            McAllen;
            Gibson;
        }
        key = {
            hdr.Switzer.Finney: exact;
        }
        size = 4096;
        default_action = Gibson();
    }
    @name(".Colstrip") table Colstrip {
        actions = {
            Carroll;
            Whatley;
        }
        key = {
            hdr.Twain.SanJuan  : exact;
            hdr.Twain.Weatherly: exact;
            hdr.Switzer.Alamota: exact;
            meta.Algoa.Faulkton: exact;
        }
        size = 1024;
        default_action = Whatley();
    }
    @name(".Elburn") table Elburn {
        actions = {
            Kenyon;
        }
        key = {
            meta.Brodnax.Natalbany: exact;
        }
        size = 4096;
    }
    @name(".Filley") table Filley {
        actions = {
            Olcott;
            Cleta;
            Lofgreen;
        }
        key = {
            meta.Brodnax.Bannack   : ternary;
            hdr.Jayton[0].isValid(): exact;
            hdr.Jayton[0].Jigger   : ternary;
        }
        size = 4096;
    }
    @name(".Flomot") table Flomot {
        actions = {
            Rendville;
            Egypt;
        }
        key = {
            hdr.Needles.Greenwood: exact;
        }
        size = 4096;
    }
    @name(".Hilburn") table Hilburn {
        actions = {
            Dilia;
            Kapowsin;
        }
        key = {
            meta.Brodnax.Bannack: exact;
            hdr.Jayton[0].Jigger: exact;
        }
        size = 1024;
        default_action = Kapowsin();
    }
    @name(".Metzger") table Metzger {
        actions = {
            Kamas;
        }
        key = {
            hdr.Jayton[0].Jigger: exact;
        }
        size = 4096;
        default_action = Kamas(0, 1, 2, 3, 4);
    }
    apply {
        switch (Colstrip.apply().action_run) {
            Carroll: {
                Brinson.apply();
                Flomot.apply();
            }
            Whatley: {
                if (meta.Brodnax.Ruffin == 1w1) {
                    Filley.apply();
                }
                if (hdr.Jayton[0].isValid()) {
                    switch (Hilburn.apply().action_run) {
                        Kapowsin: {
                            Metzger.apply();
                        }
                    }

                }
                else {
                    Elburn.apply();
                }
            }
        }

    }
}

control Neavitt(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Tascosa") action Tascosa(bit<16> Almelund) {
        meta.Roachdale.Carnero = Almelund;
        hdr.ig_intr_md_for_tm.ucast_egress_port = (bit<9>)Almelund;
    }
    @name(".Kapowsin") action Kapowsin() {
        ;
    }
    @name(".Twisp") table Twisp {
        actions = {
            Tascosa;
            Kapowsin;
        }
        key = {
            meta.Roachdale.Carnero: exact;
            meta.Buckeye.Candle   : selector;
        }
        size = 1024;
        implementation = FlyingH;
    }
    apply {
        if (meta.Roachdale.Carnero & 16w0x2000 == 16w0x2000) {
            Twisp.apply();
        }
    }
}

@name(".Floyd") register<bit<1>>(32w65536) Floyd;

control NewRoads(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Elihu") @min_width(16) direct_counter(CounterType.packets_and_bytes) Elihu;
    @name(".Fowlkes") RegisterAction<bit<1>, bit<1>>(Floyd) Fowlkes = {
        void apply(inout bit<1> value) {
            bit<1> in_value;
            in_value = value;
            value = 1w1;
        }
    };
    @name(".Colonias") action Colonias() {
        meta.Algoa.ShowLow = 1w1;
    }
    @name(".Kapowsin") action Kapowsin() {
        ;
    }
    @name(".Fentress") action Fentress(bit<8> Abernathy) {
        Fowlkes.execute();
    }
    @name(".Chunchula") action Chunchula() {
        meta.Algoa.Dushore = 1w1;
        meta.DonaAna.Rockfield = 8w0;
    }
    @name(".Tolleson") action Tolleson() {
        meta.Downs.Wickett = 1w1;
    }
    @name(".Colonias") action Colonias_0() {
        Elihu.count();
        meta.Algoa.ShowLow = 1w1;
    }
    @name(".Kapowsin") action Kapowsin_0() {
        Elihu.count();
        ;
    }
    @name(".Layton") table Layton {
        actions = {
            Colonias_0;
            Kapowsin_0;
        }
        key = {
            meta.Brodnax.Columbia: exact;
            meta.Boyle.Maida     : ternary;
            meta.Boyle.Rehobeth  : ternary;
            meta.Algoa.Elsey     : ternary;
            meta.Algoa.Valmont   : ternary;
            meta.Algoa.Weslaco   : ternary;
        }
        size = 512;
        default_action = Kapowsin_0();
        counters = Elihu;
    }
    @name(".Talbotton") table Talbotton {
        actions = {
            Fentress;
            Chunchula;
        }
        key = {
            meta.Algoa.McCune  : exact;
            meta.Algoa.Lignite : exact;
            meta.Algoa.Calabash: exact;
            meta.Algoa.Kasilof : exact;
        }
        size = 65536;
    }
    @name(".Tiburon") table Tiburon {
        actions = {
            Tolleson;
        }
        key = {
            meta.Algoa.Allegan: ternary;
            meta.Algoa.Lasara : exact;
            meta.Algoa.Ivanhoe: exact;
        }
        size = 512;
    }
    apply {
        switch (Layton.apply().action_run) {
            Kapowsin_0: {
                if (meta.Brodnax.Litroe == 1w0 && meta.Algoa.BeeCave == 1w0) {
                    Talbotton.apply();
                }
                Tiburon.apply();
            }
        }

    }
}

control Nuiqsut(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Hoadly") action Hoadly(bit<24> Piperton, bit<24> Freeville, bit<16> Edwards) {
        meta.Roachdale.Dresser = Edwards;
        meta.Roachdale.Roscommon = Piperton;
        meta.Roachdale.Bendavis = Freeville;
        meta.Roachdale.Dubuque = 1w1;
    }
    @name(".Missoula") table Missoula {
        actions = {
            Hoadly;
        }
        key = {
            meta.Collis.Trimble: exact;
        }
        size = 65536;
        default_action = Hoadly(0, 1, 2);
    }
    apply {
        if (meta.Collis.Trimble != 16w0) {
            Missoula.apply();
        }
    }
}

control OakLevel(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Bowlus") action Bowlus() {
        meta.Algoa.ShowLow = 1w1;
    }
    @name(".Browning") table Browning {
        actions = {
            Bowlus;
        }
        size = 1;
        default_action = Bowlus();
    }
    apply {
        if (meta.Roachdale.Dubuque == 1w0 && meta.Algoa.Kasilof == meta.Roachdale.Carnero) {
            Browning.apply();
        }
    }
}

control Overlea(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".RockHill") action RockHill(bit<8> Springlee) {
        meta.Roachdale.Pittsboro = 1w1;
        meta.Roachdale.Vacherie = Springlee;
        meta.Algoa.Lindy = 1w1;
    }
    @name(".Wapinitia") action Wapinitia() {
        meta.Algoa.Weslaco = 1w1;
        meta.Algoa.KeyWest = 1w1;
    }
    @name(".Jackpot") action Jackpot() {
        meta.Algoa.Lindy = 1w1;
    }
    @name(".Piketon") action Piketon() {
        meta.Algoa.Browndell = 1w1;
    }
    @name(".Moodys") action Moodys() {
        meta.Algoa.KeyWest = 1w1;
    }
    @name(".Lemoyne") action Lemoyne() {
        meta.Algoa.Valmont = 1w1;
    }
    @name(".Clintwood") table Clintwood {
        actions = {
            RockHill;
            Wapinitia;
            Jackpot;
            Piketon;
            Moodys;
        }
        key = {
            hdr.Twain.SanJuan  : ternary;
            hdr.Twain.Weatherly: ternary;
        }
        size = 512;
        default_action = Moodys();
    }
    @name(".Orlinda") table Orlinda {
        actions = {
            Lemoyne;
        }
        key = {
            hdr.Twain.Gordon: ternary;
            hdr.Twain.Topton: ternary;
        }
        size = 512;
    }
    apply {
        Clintwood.apply();
        Orlinda.apply();
    }
}

control Reynolds(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".McCartys") action McCartys(bit<16> Cornell) {
        meta.Roachdale.Dubuque = 1w1;
        meta.Collis.Trimble = Cornell;
    }
    @name(".Kapowsin") action Kapowsin() {
        ;
    }
    @name(".Burgin") action Burgin(bit<16> Point) {
        meta.ElJebel.Chambers = Point;
    }
    @atcam_partition_index("ElJebel.Chambers") @atcam_number_partitions(16384) @name(".Leland") table Leland {
        actions = {
            McCartys;
            Kapowsin;
        }
        key = {
            meta.ElJebel.Chambers     : exact;
            meta.ElJebel.Waimalu[19:0]: lpm;
        }
        size = 131072;
        default_action = Kapowsin();
    }
    @idletime_precision(1) @name(".Mumford") table Mumford {
        support_timeout = true;
        actions = {
            McCartys;
            Kapowsin;
        }
        key = {
            meta.Downs.Higley   : exact;
            meta.ElJebel.Waimalu: lpm;
        }
        size = 1024;
        default_action = Kapowsin();
    }
    @name(".Nashoba") table Nashoba {
        actions = {
            Burgin;
        }
        key = {
            meta.Downs.Higley   : exact;
            meta.ElJebel.Waimalu: lpm;
        }
        size = 16384;
    }
    @idletime_precision(1) @name(".RioLajas") table RioLajas {
        support_timeout = true;
        actions = {
            McCartys;
            Kapowsin;
        }
        key = {
            meta.Downs.Higley   : exact;
            meta.ElJebel.Waimalu: exact;
        }
        size = 65536;
        default_action = Kapowsin();
    }
    @idletime_precision(1) @name(".WestPike") table WestPike {
        support_timeout = true;
        actions = {
            McCartys;
            Kapowsin;
        }
        key = {
            meta.Downs.Higley  : exact;
            meta.Blevins.Keener: exact;
        }
        size = 65536;
        default_action = Kapowsin();
    }
    apply {
        if (meta.Algoa.ShowLow == 1w0 && meta.Downs.Wickett == 1w1) {
            if (meta.Downs.NantyGlo == 1w1 && (meta.Algoa.Faulkton == 2w0 && hdr.Switzer.isValid() || meta.Algoa.Faulkton != 2w0 && hdr.Fitzhugh.isValid())) {
                switch (RioLajas.apply().action_run) {
                    Kapowsin: {
                        Nashoba.apply();
                        if (meta.ElJebel.Chambers != 16w0) {
                            Leland.apply();
                        }
                        if (meta.Collis.Trimble == 16w0) {
                            Mumford.apply();
                        }
                    }
                }

            }
            else {
                if (meta.Downs.Remsen == 1w1 && (meta.Algoa.Faulkton == 2w0 && hdr.Baidland.isValid()) || meta.Algoa.Faulkton != 2w0 && hdr.Frewsburg.isValid()) {
                    WestPike.apply();
                }
            }
        }
    }
}

control Tecumseh(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Naguabo") action Naguabo() {
        ;
    }
    @name(".Martelle") action Martelle() {
        hdr.Jayton[0].setValid();
        hdr.Jayton[0].Jigger = meta.Roachdale.Pelion;
        hdr.Jayton[0].Bellmore = hdr.Twain.Lilydale;
        hdr.Twain.Lilydale = 16w0x8100;
    }
    @name(".Chatanika") table Chatanika {
        actions = {
            Naguabo;
            Martelle;
        }
        key = {
            meta.Roachdale.Pelion     : exact;
            hdr.eg_intr_md.egress_port: exact;
        }
        size = 64;
        default_action = Martelle();
    }
    apply {
        Chatanika.apply();
    }
}

control Vantage(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".ElCentro") action ElCentro(bit<16> Norborne) {
        meta.Roachdale.Fergus = 1w1;
        meta.Roachdale.Carnero = Norborne;
        hdr.ig_intr_md_for_tm.ucast_egress_port = (bit<9>)Norborne;
    }
    @name(".Wells") action Wells(bit<16> Mizpah) {
        meta.Roachdale.Lapel = 1w1;
        meta.Roachdale.Leonidas = Mizpah;
    }
    @name(".Balfour") action Balfour() {
    }
    @name(".Sigsbee") action Sigsbee() {
        meta.Roachdale.Benkelman = 1w1;
        meta.Roachdale.Bowen = 1w1;
        meta.Roachdale.Leonidas = meta.Roachdale.Dresser;
    }
    @name(".Norco") action Norco() {
    }
    @name(".Earlham") action Earlham() {
        meta.Roachdale.Lapel = 1w1;
        meta.Roachdale.Guadalupe = 1w1;
        meta.Roachdale.Leonidas = meta.Roachdale.Dresser + 16w4096;
    }
    @name(".Larsen") action Larsen() {
        meta.Roachdale.Milam = 1w1;
        meta.Roachdale.Leonidas = meta.Roachdale.Dresser;
    }
    @name(".Blakeman") table Blakeman {
        actions = {
            ElCentro;
            Wells;
            Balfour;
        }
        key = {
            meta.Roachdale.Roscommon: exact;
            meta.Roachdale.Bendavis : exact;
            meta.Roachdale.Dresser  : exact;
        }
        size = 65536;
        default_action = Balfour();
    }
    @ways(1) @name(".Gotebo") table Gotebo {
        actions = {
            Sigsbee;
            Norco;
        }
        key = {
            meta.Roachdale.Roscommon: exact;
            meta.Roachdale.Bendavis : exact;
        }
        size = 1;
        default_action = Norco();
    }
    @name(".Karlsruhe") table Karlsruhe {
        actions = {
            Earlham;
        }
        size = 1;
        default_action = Earlham();
    }
    @name(".Sanchez") table Sanchez {
        actions = {
            Larsen;
        }
        size = 1;
        default_action = Larsen();
    }
    apply {
        if (meta.Algoa.ShowLow == 1w0) {
            switch (Blakeman.apply().action_run) {
                Balfour: {
                    switch (Gotebo.apply().action_run) {
                        Norco: {
                            if (meta.Roachdale.Roscommon & 24w0x10000 == 24w0x10000) {
                                Karlsruhe.apply();
                            }
                            else {
                                Sanchez.apply();
                            }
                        }
                    }

                }
            }

        }
    }
}

@name("Benson") struct Benson {
    bit<8>  Rockfield;
    bit<24> McCune;
    bit<24> Lignite;
    bit<16> Calabash;
    bit<16> Kasilof;
}

control Vieques(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Naalehu") action Naalehu() {
        digest<Benson>((bit<32>)0, { meta.DonaAna.Rockfield, meta.Algoa.McCune, meta.Algoa.Lignite, meta.Algoa.Calabash, meta.Algoa.Kasilof });
    }
    @name(".Powhatan") table Powhatan {
        actions = {
            Naalehu;
        }
        size = 1;
    }
    apply {
        if (meta.Algoa.Dushore == 1w1) {
            Powhatan.apply();
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Lamoni") Lamoni() Lamoni_0;
    @name(".Hanston") Hanston() Hanston_0;
    @name(".Tecumseh") Tecumseh() Tecumseh_0;
    apply {
        Lamoni_0.apply(hdr, meta, standard_metadata);
        Hanston_0.apply(hdr, meta, standard_metadata);
        Tecumseh_0.apply(hdr, meta, standard_metadata);
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".Caspian") Caspian() Caspian_0;
    @name(".Overlea") Overlea() Overlea_0;
    @name(".Mantee") Mantee() Mantee_0;
    @name(".Alakanuk") Alakanuk() Alakanuk_0;
    @name(".NewRoads") NewRoads() NewRoads_0;
    @name(".Reynolds") Reynolds() Reynolds_0;
    @name(".Kaibab") Kaibab() Kaibab_0;
    @name(".Nuiqsut") Nuiqsut() Nuiqsut_0;
    @name(".Columbus") Columbus() Columbus_0;
    @name(".Vantage") Vantage() Vantage_0;
    @name(".OakLevel") OakLevel() OakLevel_0;
    @name(".Neavitt") Neavitt() Neavitt_0;
    @name(".Haugen") Haugen() Haugen_0;
    @name(".Vieques") Vieques() Vieques_0;
    @name(".Fleetwood") Fleetwood() Fleetwood_0;
    apply {
        Caspian_0.apply(hdr, meta, standard_metadata);
        Overlea_0.apply(hdr, meta, standard_metadata);
        Mantee_0.apply(hdr, meta, standard_metadata);
        Alakanuk_0.apply(hdr, meta, standard_metadata);
        NewRoads_0.apply(hdr, meta, standard_metadata);
        Reynolds_0.apply(hdr, meta, standard_metadata);
        Kaibab_0.apply(hdr, meta, standard_metadata);
        Nuiqsut_0.apply(hdr, meta, standard_metadata);
        Columbus_0.apply(hdr, meta, standard_metadata);
        Vantage_0.apply(hdr, meta, standard_metadata);
        OakLevel_0.apply(hdr, meta, standard_metadata);
        Neavitt_0.apply(hdr, meta, standard_metadata);
        Haugen_0.apply(hdr, meta, standard_metadata);
        Vieques_0.apply(hdr, meta, standard_metadata);
        if (hdr.Jayton[0].isValid()) {
            Fleetwood_0.apply(hdr, meta, standard_metadata);
        }
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.Twain);
        packet.emit(hdr.Jayton[0]);
        packet.emit(hdr.Crestone);
        packet.emit(hdr.Baidland);
        packet.emit(hdr.Switzer);
        packet.emit(hdr.Otranto);
        packet.emit(hdr.Needles);
        packet.emit(hdr.TroutRun);
        packet.emit(hdr.Frewsburg);
        packet.emit(hdr.Fitzhugh);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

