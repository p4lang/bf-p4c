#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<8> x_8;
    bit<8> y_8;
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
    bit<8>  clone_src;
    bit<8>  coalesce_sample_count;
}

header hdr1_t {
    bit<8> a_8;
    bit<8> b_8;
    bit<8> c_8;
    bit<8> d_8;
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
}

struct metadata {
    @name(".meta") 
    meta_t meta;
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
    @name(".hdr1") 
    hdr1_t                                         hdr1;
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
    @name(".parse_pkt") state parse_pkt {
        packet.extract<hdr1_t>(hdr.hdr1);
        meta.meta.x_8 = hdr.hdr1.a_8;
        transition accept;
    }
    @name(".start") state start {
        transition parse_pkt;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".a0") action a0_0(bit<8> x) {
        meta.meta.x_8 = x;
    }
    @name(".do_nothing") action do_nothing_0() {
    }
    @name(".a1") action a1_0(bit<8> a) {
        hdr.hdr1.a_8 = a;
    }
    @name(".a2") action a2_0(bit<8> b) {
        hdr.hdr1.b_8 = b;
    }
    @name(".a3") action a3_0(bit<8> c) {
        hdr.hdr1.c_8 = c;
    }
    @name(".a4") action a4_0(bit<8> y) {
        meta.meta.y_8 = y;
    }
    @name(".a5") action a5_0(bit<8> a) {
        hdr.hdr1.a_8 = a;
    }
    @name(".a6") action a6_0(bit<8> b) {
        hdr.hdr1.b_8 = b;
    }
    @name(".a7") action a7_0(bit<8> d) {
        hdr.hdr1.d_8 = d;
    }
    @name(".t0") table t0_0 {
        actions = {
            a0_0();
            do_nothing_0();
            @defaultonly NoAction();
        }
        key = {
            meta.meta.x_8: ternary @name("meta.x_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".t1") table t1_0 {
        actions = {
            a1_0();
            do_nothing_0();
            @defaultonly NoAction();
        }
        key = {
            meta.meta.x_8: ternary @name("meta.x_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".t2") table t2_0 {
        actions = {
            a2_0();
            do_nothing_0();
            @defaultonly NoAction();
        }
        key = {
            meta.meta.x_8: ternary @name("meta.x_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".t3") table t3_0 {
        actions = {
            a3_0();
            do_nothing_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.hdr1.a_8: ternary @name("hdr1.a_8") ;
            hdr.hdr1.b_8: ternary @name("hdr1.b_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".t4") table t4_0 {
        actions = {
            a4_0();
            do_nothing_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.hdr1.a_8: ternary @name("hdr1.a_8") ;
            hdr.hdr1.b_8: ternary @name("hdr1.b_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".t5") table t5_0 {
        actions = {
            a5_0();
            do_nothing_0();
            @defaultonly NoAction();
        }
        key = {
            meta.meta.y_8: ternary @name("meta.y_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".t6") table t6_0 {
        actions = {
            a6_0();
            do_nothing_0();
            @defaultonly NoAction();
        }
        key = {
            meta.meta.y_8: ternary @name("meta.y_8") ;
            hdr.hdr1.c_8 : ternary @name("hdr1.c_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".t7") table t7_0 {
        actions = {
            a7_0();
            do_nothing_0();
            @defaultonly NoAction();
        }
        key = {
            meta.meta.y_8: ternary @name("meta.y_8") ;
            hdr.hdr1.a_8 : ternary @name("hdr1.a_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    apply {
        t0_0.apply();
        if (hdr.hdr1.isValid()) {
            t1_0.apply();
            t4_0.apply();
            t5_0.apply();
        }
        else {
            t2_0.apply();
            t3_0.apply();
            t6_0.apply();
        }
        t7_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<hdr1_t>(hdr.hdr1);
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
