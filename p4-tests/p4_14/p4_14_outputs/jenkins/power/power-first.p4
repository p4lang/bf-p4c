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
    bit<16>  etherType;
    bit<904> exm_key1;
    bit<520> exm_key2;
    bit<40>  tcam_key1;
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
    bit<5> _pad;
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
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".egr_eq_ing_action") action egr_eq_ing_action(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".do_nothing") action do_nothing() {
    }
    @name(".eg_port") table eg_port {
        actions = {
            egr_eq_ing_action();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        default_action = NoAction();
    }
    @stage(0) @ways(5) @name(".exm_table0_0") table exm_table0_0 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key2: exact @name("ethernet.exm_key2") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(0) @ways(5) @name(".exm_table0_1") table exm_table0_1 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key2: exact @name("ethernet.exm_key2") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(10) @ways(5) @pack(8) @name(".exm_table10_0") table exm_table10_0 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(10) @ways(5) @pack(8) @name(".exm_table10_1") table exm_table10_1 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(11) @ways(5) @pack(8) @name(".exm_table11_0") table exm_table11_0 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(11) @ways(5) @pack(8) @name(".exm_table11_1") table exm_table11_1 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(1) @ways(5) @pack(8) @name(".exm_table1_0") table exm_table1_0 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(1) @ways(5) @pack(8) @name(".exm_table1_1") table exm_table1_1 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(2) @ways(5) @pack(8) @name(".exm_table2_0") table exm_table2_0 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(2) @ways(5) @pack(8) @name(".exm_table2_1") table exm_table2_1 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(3) @ways(5) @pack(8) @name(".exm_table3_0") table exm_table3_0 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(3) @ways(5) @pack(8) @name(".exm_table3_1") table exm_table3_1 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(4) @ways(5) @pack(8) @name(".exm_table4_0") table exm_table4_0 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(4) @ways(5) @pack(8) @name(".exm_table4_1") table exm_table4_1 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(5) @ways(5) @pack(8) @name(".exm_table5_0") table exm_table5_0 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(5) @ways(5) @pack(8) @name(".exm_table5_1") table exm_table5_1 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(6) @ways(5) @pack(8) @name(".exm_table6_0") table exm_table6_0 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(6) @ways(5) @pack(8) @name(".exm_table6_1") table exm_table6_1 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(7) @ways(5) @pack(8) @name(".exm_table7_0") table exm_table7_0 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(7) @ways(5) @pack(8) @name(".exm_table7_1") table exm_table7_1 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(8) @ways(5) @pack(8) @name(".exm_table8_0") table exm_table8_0 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(8) @ways(5) @pack(8) @name(".exm_table8_1") table exm_table8_1 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(9) @ways(5) @pack(8) @name(".exm_table9_0") table exm_table9_0 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(9) @ways(5) @pack(8) @name(".exm_table9_1") table exm_table9_1 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.exm_key1: exact @name("ethernet.exm_key1") ;
        }
        size = 5120;
        default_action = NoAction();
    }
    @stage(0) @name(".tcam_table0") table tcam_table0 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.tcam_key1: ternary @name("ethernet.tcam_key1") ;
        }
        size = 12288;
        default_action = NoAction();
    }
    @stage(1) @name(".tcam_table1") table tcam_table1 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.tcam_key1: ternary @name("ethernet.tcam_key1") ;
        }
        size = 12288;
        default_action = NoAction();
    }
    @stage(10) @name(".tcam_table10") table tcam_table10 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.tcam_key1: ternary @name("ethernet.tcam_key1") ;
        }
        size = 12288;
        default_action = NoAction();
    }
    @stage(11) @name(".tcam_table11") table tcam_table11 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.tcam_key1: ternary @name("ethernet.tcam_key1") ;
        }
        size = 12288;
        default_action = NoAction();
    }
    @stage(2) @name(".tcam_table2") table tcam_table2 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.tcam_key1: ternary @name("ethernet.tcam_key1") ;
        }
        size = 12288;
        default_action = NoAction();
    }
    @stage(3) @name(".tcam_table3") table tcam_table3 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.tcam_key1: ternary @name("ethernet.tcam_key1") ;
        }
        size = 12288;
        default_action = NoAction();
    }
    @stage(4) @name(".tcam_table4") table tcam_table4 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.tcam_key1: ternary @name("ethernet.tcam_key1") ;
        }
        size = 12288;
        default_action = NoAction();
    }
    @stage(5) @name(".tcam_table5") table tcam_table5 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.tcam_key1: ternary @name("ethernet.tcam_key1") ;
        }
        size = 12288;
        default_action = NoAction();
    }
    @stage(6) @name(".tcam_table6") table tcam_table6 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.tcam_key1: ternary @name("ethernet.tcam_key1") ;
        }
        size = 12288;
        default_action = NoAction();
    }
    @stage(7) @name(".tcam_table7") table tcam_table7 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.tcam_key1: ternary @name("ethernet.tcam_key1") ;
        }
        size = 12288;
        default_action = NoAction();
    }
    @stage(8) @name(".tcam_table8") table tcam_table8 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.tcam_key1: ternary @name("ethernet.tcam_key1") ;
        }
        size = 12288;
        default_action = NoAction();
    }
    @stage(9) @name(".tcam_table9") table tcam_table9 {
        actions = {
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.tcam_key1: ternary @name("ethernet.tcam_key1") ;
        }
        size = 12288;
        default_action = NoAction();
    }
    apply {
        eg_port.apply();
        exm_table0_0.apply();
        exm_table0_1.apply();
        tcam_table0.apply();
        exm_table1_0.apply();
        exm_table1_1.apply();
        tcam_table1.apply();
        exm_table2_0.apply();
        exm_table2_1.apply();
        tcam_table2.apply();
        exm_table3_0.apply();
        exm_table3_1.apply();
        tcam_table3.apply();
        exm_table4_0.apply();
        exm_table4_1.apply();
        tcam_table4.apply();
        exm_table5_0.apply();
        exm_table5_1.apply();
        tcam_table5.apply();
        exm_table6_0.apply();
        exm_table6_1.apply();
        tcam_table6.apply();
        exm_table7_0.apply();
        exm_table7_1.apply();
        tcam_table7.apply();
        exm_table8_0.apply();
        exm_table8_1.apply();
        tcam_table8.apply();
        exm_table9_0.apply();
        exm_table9_1.apply();
        tcam_table9.apply();
        exm_table10_0.apply();
        exm_table10_1.apply();
        tcam_table10.apply();
        exm_table11_0.apply();
        exm_table11_1.apply();
        tcam_table11.apply();
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