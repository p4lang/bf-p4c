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
    bit<8>  clone_src;
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

header generator_metadata_t {
    bit<16> app_id;
    bit<16> batch_id;
    bit<16> instance_id;
}

header ingress_parser_control_signals {
    bit<3> priority;
}

header pkt_t {
    bit<32> field_a_32;
    int<32> field_b_32;
    bit<32> field_c_32;
    bit<32> field_d_32;
    bit<16> field_e_16;
    bit<16> field_f_16;
    bit<16> field_g_16;
    bit<16> field_h_16;
    bit<8>  field_i_8;
    bit<8>  field_j_8;
    bit<8>  field_k_8;
    bit<8>  field_l_8;
    int<32> field_x_32;
}

struct metadata {
}

struct headers {
    @name("eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @name("eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @name("eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @name("eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
    @name("ig_intr_md") 
    ingress_intrinsic_metadata_t                   ig_intr_md;
    @name("ig_intr_md_for_mb") 
    ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb;
    @name("ig_intr_md_for_tm") 
    ingress_intrinsic_metadata_for_tm_t            ig_intr_md_for_tm;
    @name("ig_intr_md_from_parser_aux") 
    ingress_intrinsic_metadata_from_parser_aux_t   ig_intr_md_from_parser_aux;
    @name("ig_pg_md") 
    generator_metadata_t                           ig_pg_md;
    @name("ig_prsr_ctrl") 
    ingress_parser_control_signals                 ig_prsr_ctrl;
    @name("pkt") 
    pkt_t                                          pkt;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_ethernet") state parse_ethernet {
        packet.extract<pkt_t>(hdr.pkt);
        transition accept;
    }
    @name("start") state start {
        transition parse_ethernet;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("NoAction_1") action NoAction() {
    }
    @name("action_0") action action_14() {
        hdr.pkt.field_a_32 = (bit<32>)~(hdr.pkt.field_b_32 | (int<32>)hdr.pkt.field_c_32);
    }
    @name("action_1") action action_15(bit<32> param0) {
        hdr.pkt.field_a_32 = ~(param0 & hdr.pkt.field_c_32);
    }
    @name("action_2") action action_16(bit<32> param0) {
        hdr.pkt.field_a_32 = (bit<32>)~(hdr.pkt.field_b_32 ^ (int<32>)param0);
    }
    @name("action_3") action action_17() {
        hdr.pkt.field_a_32 = ~hdr.pkt.field_d_32;
    }
    @name("action_4") action action_18(bit<32> param0) {
        hdr.pkt.field_a_32 = (hdr.pkt.field_d_32 <= param0 ? hdr.pkt.field_d_32 : param0);
    }
    @name("action_5") action action_19(bit<32> param0) {
        hdr.pkt.field_a_32 = (param0 >= hdr.pkt.field_d_32 ? param0 : hdr.pkt.field_d_32);
    }
    @name("action_6") action action_20() {
        hdr.pkt.field_b_32 = (int<32>)(hdr.pkt.field_d_32 <= 32w7 ? hdr.pkt.field_d_32 : 32w7);
    }
    @name("action_7") action action_21(int<32> param0) {
        hdr.pkt.field_b_32 = (param0 >= (int<32>)hdr.pkt.field_d_32 ? param0 : (int<32>)hdr.pkt.field_d_32);
    }
    @name("action_8") action action_22(int<32> param0) {
        hdr.pkt.field_x_32 = (hdr.pkt.field_x_32 >= param0 ? hdr.pkt.field_x_32 : param0);
    }
    @name("action_9") action action_23() {
        hdr.pkt.field_x_32 = hdr.pkt.field_x_32 >> 7;
    }
    @name("action_10") action action_24(bit<32> param0) {
        hdr.pkt.field_a_32 = ~param0 & hdr.pkt.field_a_32;
    }
    @name("action_11") action action_25(bit<32> param0) {
        hdr.pkt.field_a_32 = param0 & ~hdr.pkt.field_a_32;
    }
    @name("action_12") action action_26(bit<32> param0) {
        hdr.pkt.field_a_32 = ~param0 | hdr.pkt.field_a_32;
    }
    @name("action_13") action action_27(bit<32> param0) {
        hdr.pkt.field_a_32 = param0 | ~hdr.pkt.field_a_32;
    }
    @name("do_nothing") action do_nothing_0() {
    }
    @name("table_0") table table_0() {
        actions = {
            action_14();
            action_15();
            action_16();
            action_17();
            action_18();
            action_19();
            action_20();
            action_21();
            action_22();
            action_23();
            action_24();
            action_25();
            action_26();
            action_27();
            do_nothing_0();
            NoAction();
        }
        key = {
            hdr.pkt.field_a_32: ternary;
            hdr.pkt.field_b_32: ternary;
            hdr.pkt.field_c_32: ternary;
            hdr.pkt.field_d_32: ternary;
            hdr.pkt.field_g_16: ternary;
            hdr.pkt.field_h_16: ternary;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        table_0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<pkt_t>(hdr.pkt);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
