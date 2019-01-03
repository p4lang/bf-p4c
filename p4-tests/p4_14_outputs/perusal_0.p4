#include <core.p4>
#include <v1model.p4>

header cesspool {
    bit<2>  odditys;
    @saturating 
    int<2>  shipbuilders;
    bit<16> nagy;
    @saturating 
    int<8>  rastabans;
    bit<4>  histologists;
}

header dendrites {
    bit<5>  complication;
    bit<8>  confinements;
    bit<7>  razzed;
    bit<9>  noncrystalline;
    bit<11> prisoners;
    @saturating 
    int<48> welcomes;
    @saturating 
    int<16> extensions;
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

header salinger {
    bit<5>  epistle;
    bit<7>  jam;
    bit<8>  showjumping;
    bit<8>  slyer;
    @saturating 
    int<4>  packinghouses;
    bit<48> commingles;
}

header unethical {
    bit<6>  hipsters;
    @saturating 
    int<2>  impartially;
    int<8>  thence;
    int<16> hatstands;
}

header mussier {
    bit<5>  ordures;
    int<16> dogcarts;
    bit<32> placebos;
    bit<8>  hectometres;
    bit<3>  natty;
    bit<8>  admixed;
}

struct metadata {
}

struct headers {
    @name(".airbags") 
    cesspool                                       airbags;
    @name(".countersignatures") 
    dendrites                                      countersignatures;
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
    @name(".jerky") 
    salinger                                       jerky;
    @name(".sapsucker") 
    unethical                                      sapsucker;
    @name(".shamelessness") 
    mussier                                        shamelessness;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_airbags") state parse_airbags {
        packet.extract(hdr.airbags);
        transition select(hdr.airbags.nagy) {
            16w5392: parse_jerky;
            16w27569: parse_sapsucker;
        }
    }
    @name(".parse_countersignatures") state parse_countersignatures {
        packet.extract(hdr.countersignatures);
        transition select(hdr.countersignatures.complication) {
            5w4: parse_airbags;
            5w9: parse_sapsucker;
        }
    }
    @name(".parse_jerky") state parse_jerky {
        packet.extract(hdr.jerky);
        transition select(hdr.jerky.slyer) {
            8w29: parse_sapsucker;
        }
    }
    @name(".parse_sapsucker") state parse_sapsucker {
        packet.extract(hdr.sapsucker);
        transition accept;
    }
    @name(".parse_shamelessness") state parse_shamelessness {
        packet.extract(hdr.shamelessness);
        transition select(hdr.shamelessness.hectometres) {
            8w71: parse_countersignatures;
            8w27: parse_jerky;
        }
    }
    @name(".start") state start {
        transition parse_shamelessness;
    }
}

@name(".cranny") action_profile(32w30) cranny;

@name(".flashcards") action_profile(32w32) flashcards;

@name(".lifts") action_profile(32w4) lifts;

@name(".nations") action_profile(32w13) nations;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".cycladess") action cycladess(bit<8> combo, bit<8> inauspiciously, bit<8> cautioning) {
        hdr.airbags.rastabans = hdr.sapsucker.thence | (int<8>)hdr.shamelessness.admixed;
        hdr.airbags.odditys = 2w0 + (bit<2>)hdr.airbags.shipbuilders;
        hdr.countersignatures.setValid();
    }
    @name(".carbides") action carbides() {
        random(hdr.airbags.shipbuilders, (int<2>)0, -2s1);
        random(hdr.jerky.epistle, (bit<5>)9, 5w15);
        hdr.jerky.packinghouses = 4s1 |+| 4s7;
        hdr.countersignatures.confinements = hdr.shamelessness.admixed - hdr.countersignatures.confinements;
        random(hdr.countersignatures.prisoners, (bit<11>)1662, 11w2047);
        hdr.shamelessness.hectometres = (bit<8>)hdr.airbags.rastabans;
        hdr.countersignatures.complication = hdr.shamelessness.ordures;
    }
    @name(".causal") action causal(bit<8> malaysians, bit<8> sarnoff, bit<8> recommences) {
        hdr.sapsucker.thence = hdr.sapsucker.thence + (int<8>)hdr.shamelessness.hectometres;
        hdr.shamelessness.placebos = hdr.shamelessness.placebos - hdr.shamelessness.placebos;
    }
    @name(".bids") action bids() {
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w1;
    }
    @name(".concertinaing") table concertinaing {
        actions = {
        }
    }
    @name(".exhorts") table exhorts {
        actions = {
            cycladess;
        }
        key = {
            hdr.shamelessness.ordures      : exact;
            hdr.shamelessness.dogcarts     : exact;
            hdr.shamelessness.placebos     : exact;
            hdr.countersignatures.isValid(): exact;
            hdr.airbags.odditys            : exact;
            hdr.airbags.shipbuilders       : exact;
            hdr.airbags.nagy               : exact;
            hdr.airbags.rastabans          : exact;
            hdr.airbags.histologists       : exact;
            hdr.jerky.jam                  : range;
            hdr.jerky.showjumping[0:0]     : lpm @name("jerky.showjumping") ;
            hdr.jerky.slyer                : exact;
            hdr.jerky.packinghouses        : lpm;
        }
    }
    @name(".flightier") table flightier {
        actions = {
            cycladess;
            carbides;
            causal;
            bids;
        }
        implementation = nations;
    }
    @name(".glamoured") table glamoured {
        actions = {
            carbides;
            causal;
        }
        key = {
            hdr.shamelessness.isValid()  : exact;
            hdr.shamelessness.ordures    : lpm;
            hdr.shamelessness.dogcarts   : ternary;
            hdr.shamelessness.placebos   : ternary;
            hdr.shamelessness.hectometres: ternary;
            hdr.shamelessness.admixed    : exact;
            hdr.jerky.isValid()          : exact;
            hdr.jerky.epistle            : exact;
            hdr.jerky.showjumping        : exact;
            hdr.jerky.commingles & 48w40 : exact @name("jerky.commingles") ;
            hdr.sapsucker.isValid()      : exact;
            hdr.sapsucker.hipsters       : exact;
            hdr.sapsucker.impartially    : exact;
            hdr.sapsucker.thence         : exact;
        }
        implementation = cranny;
    }
    @name(".hawking") table hawking {
        actions = {
            cycladess;
        }
        key = {
            hdr.jerky.isValid()    : exact;
            hdr.jerky.jam          : exact;
            hdr.jerky.showjumping  : exact;
            hdr.jerky.slyer        : exact;
            hdr.jerky.packinghouses: exact;
            hdr.sapsucker.isValid(): exact;
        }
    }
    @name(".innersole") table innersole {
        actions = {
        }
        key = {
            hdr.countersignatures.isValid()     : exact;
            hdr.countersignatures.complication  : lpm;
            hdr.countersignatures.confinements  : exact;
            hdr.countersignatures.noncrystalline: lpm;
            hdr.countersignatures.welcomes      : lpm;
            hdr.countersignatures.extensions    : lpm;
            hdr.jerky.isValid()                 : exact;
            hdr.jerky.epistle                   : lpm;
            hdr.jerky.jam                       : lpm;
            hdr.jerky.slyer                     : exact;
            hdr.jerky.packinghouses             : exact;
        }
    }
    @name(".medicos") table medicos {
        actions = {
            bids;
            carbides;
            cycladess;
        }
        key = {
            hdr.sapsucker.isValid(): exact;
        }
    }
    @name(".photocells") table photocells {
        actions = {
            cycladess;
            carbides;
            causal;
            bids;
        }
        key = {
            hdr.shamelessness.ordures         : exact;
            hdr.shamelessness.natty           : exact;
            hdr.shamelessness.admixed         : exact;
            hdr.countersignatures.confinements: exact;
            hdr.countersignatures.welcomes    : exact;
            hdr.countersignatures.extensions  : lpm;
            hdr.airbags.isValid()             : exact;
            hdr.airbags.odditys               : exact;
            hdr.airbags.shipbuilders          : exact;
            hdr.airbags.nagy                  : ternary;
            hdr.airbags.rastabans             : ternary;
            4w0                               : exact @name("airbags.histologists") ;
            hdr.jerky.isValid()               : exact;
            hdr.jerky.commingles              : exact;
            hdr.sapsucker.impartially         : lpm;
            hdr.sapsucker.thence              : exact;
            hdr.sapsucker.hatstands           : ternary;
        }
        implementation = lifts;
    }
    @name(".repudiating") table repudiating {
        actions = {
            carbides;
            causal;
            cycladess;
        }
    }
    @name(".ru") table ru {
        actions = {
            bids;
            cycladess;
        }
    }
    @name(".runways") table runways {
        actions = {
        }
        key = {
            hdr.shamelessness.isValid()              : exact;
            hdr.shamelessness.ordures                : lpm;
            hdr.countersignatures.isValid()          : exact;
            hdr.countersignatures.complication       : ternary;
            hdr.countersignatures.confinements       : exact;
            hdr.countersignatures.razzed             : lpm;
            hdr.countersignatures.noncrystalline[2:1]: lpm @name("countersignatures.noncrystalline") ;
            hdr.airbags.isValid()                    : exact;
            hdr.airbags.odditys                      : lpm;
        }
    }
    @name(".savour") table savour {
        actions = {
        }
        key = {
            hdr.shamelessness.isValid()         : exact;
            hdr.shamelessness.dogcarts          : lpm;
            hdr.countersignatures.confinements  : lpm;
            hdr.countersignatures.razzed        : exact;
            hdr.countersignatures.noncrystalline: exact;
            hdr.countersignatures.prisoners     : exact;
            hdr.countersignatures.extensions    : ternary;
            hdr.airbags.odditys                 : ternary;
            hdr.airbags.shipbuilders            : exact;
            hdr.airbags.nagy                    : exact;
            hdr.airbags.rastabans               : exact;
            hdr.airbags.histologists            : exact;
        }
    }
    @name(".wont") table wont {
        actions = {
            carbides;
        }
        key = {
            hdr.shamelessness.isValid()       : exact;
            hdr.shamelessness.ordures[2:2]    : exact @name("shamelessness.ordures") ;
            hdr.shamelessness.dogcarts        : exact;
            32w0                              : exact @name("shamelessness.placebos") ;
            hdr.shamelessness.hectometres[1:1]: exact @name("shamelessness.hectometres") ;
            hdr.airbags.odditys               : ternary;
            hdr.airbags.shipbuilders          : exact;
            hdr.airbags.nagy                  : exact;
        }
        implementation = flashcards;
    }
    apply {
        if ((bit<11>)hdr.shamelessness.natty != hdr.countersignatures.prisoners) {
            ru.apply();
            wont.apply();
            flightier.apply();
        }
        else {
            photocells.apply();
        }
        medicos.apply();
        if (!(hdr.sapsucker.thence < 8s107)) {
            exhorts.apply();
            glamoured.apply();
            hawking.apply();
        }
        savour.apply();
        repudiating.apply();
        innersole.apply();
        concertinaing.apply();
        runways.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.shamelessness);
        packet.emit(hdr.countersignatures);
        packet.emit(hdr.airbags);
        packet.emit(hdr.jerky);
        packet.emit(hdr.sapsucker);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
        verify_checksum(true, { hdr.countersignatures.razzed, hdr.shamelessness.placebos, hdr.shamelessness.ordures, hdr.jerky.packinghouses, hdr.countersignatures.extensions, hdr.jerky.commingles, hdr.sapsucker.hatstands, hdr.jerky.epistle, hdr.countersignatures.welcomes, hdr.shamelessness.natty, hdr.shamelessness.dogcarts }, hdr.airbags.nagy, HashAlgorithm.csum16);
        verify_checksum(true, { hdr.airbags, hdr.shamelessness.natty, hdr.jerky.slyer, hdr.shamelessness.placebos }, hdr.airbags.nagy, HashAlgorithm.csum16);
        verify_checksum(true, { hdr.airbags.histologists, hdr.jerky.commingles, hdr.shamelessness.ordures, hdr.countersignatures.confinements, hdr.shamelessness.admixed, hdr.airbags.nagy, hdr.jerky.jam, hdr.shamelessness.natty }, hdr.countersignatures.extensions, HashAlgorithm.csum16);
        verify_checksum(true, { hdr.airbags, hdr.shamelessness.natty, hdr.jerky.slyer, hdr.shamelessness.placebos }, hdr.sapsucker.hatstands, HashAlgorithm.csum16);
        verify_checksum(true, { hdr.countersignatures.razzed, hdr.shamelessness.placebos, hdr.shamelessness.ordures, hdr.jerky.packinghouses, hdr.countersignatures.extensions, hdr.jerky.commingles, hdr.sapsucker.hatstands, hdr.jerky.epistle, hdr.countersignatures.welcomes, hdr.shamelessness.natty, hdr.shamelessness.dogcarts }, hdr.sapsucker.hatstands, HashAlgorithm.csum16);
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum(true, { hdr.countersignatures.razzed, hdr.shamelessness.placebos, hdr.shamelessness.ordures, hdr.jerky.packinghouses, hdr.countersignatures.extensions, hdr.jerky.commingles, hdr.sapsucker.hatstands, hdr.jerky.epistle, hdr.countersignatures.welcomes, hdr.shamelessness.natty, hdr.shamelessness.dogcarts }, hdr.airbags.nagy, HashAlgorithm.csum16);
        update_checksum(true, { hdr.countersignatures.razzed, hdr.shamelessness.placebos, hdr.shamelessness.ordures, hdr.jerky.packinghouses, hdr.countersignatures.extensions, hdr.jerky.commingles, hdr.sapsucker.hatstands, hdr.jerky.epistle, hdr.countersignatures.welcomes, hdr.shamelessness.natty, hdr.shamelessness.dogcarts }, hdr.sapsucker.hatstands, HashAlgorithm.csum16);
        update_checksum(true, { hdr.countersignatures.razzed, hdr.shamelessness.placebos, hdr.shamelessness.ordures, hdr.jerky.packinghouses, hdr.countersignatures.extensions, hdr.jerky.commingles, hdr.sapsucker.hatstands, hdr.jerky.epistle, hdr.countersignatures.welcomes, hdr.shamelessness.natty, hdr.shamelessness.dogcarts }, hdr.shamelessness.dogcarts, HashAlgorithm.csum16);
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

