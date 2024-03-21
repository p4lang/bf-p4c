#include <core.p4>
#include <v1model.p4>

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

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
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

struct metadata {
}

struct headers {
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md") @pa_atomic("egress", "eg_intr_md.egress_port") @pa_fragment("egress", "eg_intr_md._pad1") @pa_fragment("egress", "eg_intr_md._pad7") @pa_fragment("egress", "eg_intr_md._pad8") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_port") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_cos") @name(".eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @dont_trim @pa_intrinsic_header("egress", "eg_intr_md_for_mb") @pa_atomic("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_fragment("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_length") @not_deparsed("ingress") @not_deparsed("egress") @name(".eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @dont_trim @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_oport.drop_ctl") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_for_oport") @name(".eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @pa_fragment("egress", "eg_intr_md_from_parser_aux.coalesce_sample_count") @pa_fragment("egress", "eg_intr_md_from_parser_aux.clone_src") @pa_fragment("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @pa_atomic("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_from_parser_aux") @name(".eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
    @name(".ethernet") 
    ethernet_t                                     ethernet;
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
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            default: accept;
        }
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".counter_egress") counter(32w512, CounterType.packets) counter_egress_0;
    @name(".egress_action") action egress_action() {
        counter_egress_0.count((bit<32>)hdr.eg_intr_md.egress_port);
    }
    @name(".simple_table_egress") table simple_table_egress_0 {
        actions = {
            egress_action();
        }
        default_action = egress_action();
    }
    apply {
        simple_table_egress_0.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_13() {
    }
    @name(".NoAction") action NoAction_14() {
    }
    @name(".NoAction") action NoAction_15() {
    }
    @name(".NoAction") action NoAction_16() {
    }
    @name(".NoAction") action NoAction_17() {
    }
    @name(".NoAction") action NoAction_18() {
    }
    @name(".NoAction") action NoAction_19() {
    }
    @name(".NoAction") action NoAction_20() {
    }
    @name(".NoAction") action NoAction_21() {
    }
    @name(".NoAction") action NoAction_22() {
    }
    @name(".NoAction") action NoAction_23() {
    }
    @name(".counter_ingress") counter(32w512, CounterType.packets) counter_ingress_0;
    @name(".action_0") action action_0(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".action_1") action action_1(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".action_10") action action_2(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".action_11") action action_3(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".action_2") action action_4(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".action_3") action action_5(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".action_4") action action_6(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".action_5") action action_7(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".action_6") action action_8(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".action_7") action action_9(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".action_8") action action_10(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".action_9") action action_11(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".ingress_action") action ingress_action() {
        counter_ingress_0.count((bit<32>)hdr.ig_intr_md.ingress_port);
    }
    @use_identity_hash(1) @immediate(0) @stage_0 @name(".simple_table_0") table simple_table {
        actions = {
            action_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.ethernet.srcAddr[12:0]: ternary @name("ethernet.srcAddr") ;
        }
        size = 8192;
        default_action = NoAction_0();
    }
    @use_identity_hash(1) @immediate(0) @stage_1 @name(".simple_table_1") table simple_table_12 {
        actions = {
            action_1();
            @defaultonly NoAction_13();
        }
        key = {
            hdr.ethernet.srcAddr[12:0]: ternary @name("ethernet.srcAddr") ;
        }
        size = 8192;
        default_action = NoAction_13();
    }
    @use_identity_hash(1) @immediate(0) @stage_10 @name(".simple_table_10") table simple_table_13 {
        actions = {
            action_2();
            @defaultonly NoAction_14();
        }
        key = {
            hdr.ethernet.srcAddr[12:0]: ternary @name("ethernet.srcAddr") ;
        }
        size = 8192;
        default_action = NoAction_14();
    }
    @use_identity_hash(1) @immediate(0) @stage_11 @name(".simple_table_11") table simple_table_14 {
        actions = {
            action_3();
            @defaultonly NoAction_15();
        }
        key = {
            hdr.ethernet.srcAddr[12:0]: ternary @name("ethernet.srcAddr") ;
        }
        size = 8192;
        default_action = NoAction_15();
    }
    @use_identity_hash(1) @immediate(0) @stage_2 @name(".simple_table_2") table simple_table_15 {
        actions = {
            action_4();
            @defaultonly NoAction_16();
        }
        key = {
            hdr.ethernet.srcAddr[12:0]: ternary @name("ethernet.srcAddr") ;
        }
        size = 8192;
        default_action = NoAction_16();
    }
    @use_identity_hash(1) @immediate(0) @stage_3 @name(".simple_table_3") table simple_table_16 {
        actions = {
            action_5();
            @defaultonly NoAction_17();
        }
        key = {
            hdr.ethernet.srcAddr[12:0]: ternary @name("ethernet.srcAddr") ;
        }
        size = 8192;
        default_action = NoAction_17();
    }
    @use_identity_hash(1) @immediate(0) @stage_4 @name(".simple_table_4") table simple_table_17 {
        actions = {
            action_6();
            @defaultonly NoAction_18();
        }
        key = {
            hdr.ethernet.srcAddr[12:0]: ternary @name("ethernet.srcAddr") ;
        }
        size = 8192;
        default_action = NoAction_18();
    }
    @use_identity_hash(1) @immediate(0) @stage_5 @name(".simple_table_5") table simple_table_18 {
        actions = {
            action_7();
            @defaultonly NoAction_19();
        }
        key = {
            hdr.ethernet.srcAddr[12:0]: ternary @name("ethernet.srcAddr") ;
        }
        size = 8192;
        default_action = NoAction_19();
    }
    @use_identity_hash(1) @immediate(0) @stage_6 @name(".simple_table_6") table simple_table_19 {
        actions = {
            action_8();
            @defaultonly NoAction_20();
        }
        key = {
            hdr.ethernet.srcAddr[12:0]: ternary @name("ethernet.srcAddr") ;
        }
        size = 8192;
        default_action = NoAction_20();
    }
    @use_identity_hash(1) @immediate(0) @stage_7 @name(".simple_table_7") table simple_table_20 {
        actions = {
            action_9();
            @defaultonly NoAction_21();
        }
        key = {
            hdr.ethernet.srcAddr[12:0]: ternary @name("ethernet.srcAddr") ;
        }
        size = 8192;
        default_action = NoAction_21();
    }
    @use_identity_hash(1) @immediate(0) @stage_8 @name(".simple_table_8") table simple_table_21 {
        actions = {
            action_10();
            @defaultonly NoAction_22();
        }
        key = {
            hdr.ethernet.srcAddr[12:0]: ternary @name("ethernet.srcAddr") ;
        }
        size = 8192;
        default_action = NoAction_22();
    }
    @use_identity_hash(1) @immediate(0) @stage_9 @name(".simple_table_9") table simple_table_22 {
        actions = {
            action_11();
            @defaultonly NoAction_23();
        }
        key = {
            hdr.ethernet.srcAddr[12:0]: ternary @name("ethernet.srcAddr") ;
        }
        size = 8192;
        default_action = NoAction_23();
    }
    @stage_0 @name(".simple_table_ingress") table simple_table_ingress_0 {
        actions = {
            ingress_action();
        }
        default_action = ingress_action();
    }
    apply {
        if (hdr.ethernet.etherType == 16w0) 
            simple_table.apply();
        if (hdr.ethernet.etherType == 16w1) 
            simple_table_12.apply();
        if (hdr.ethernet.etherType == 16w2) 
            simple_table_15.apply();
        if (hdr.ethernet.etherType == 16w3) 
            simple_table_16.apply();
        if (hdr.ethernet.etherType == 16w4) 
            simple_table_17.apply();
        if (hdr.ethernet.etherType == 16w5) 
            simple_table_18.apply();
        if (hdr.ethernet.etherType == 16w6) 
            simple_table_19.apply();
        if (hdr.ethernet.etherType == 16w7) 
            simple_table_20.apply();
        if (hdr.ethernet.etherType == 16w8) 
            simple_table_21.apply();
        if (hdr.ethernet.etherType == 16w9) 
            simple_table_22.apply();
        if (hdr.ethernet.etherType == 16w10) 
            simple_table_13.apply();
        if (hdr.ethernet.etherType == 16w11) 
            simple_table_14.apply();
        simple_table_ingress_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
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

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

