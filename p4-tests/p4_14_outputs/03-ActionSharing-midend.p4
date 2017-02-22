#include <core.p4>
#include <v1model.p4>

struct metadata_t {
    bit<1>  field1_1;
    bit<1>  field1_2;
    bit<1>  field1_3;
    bit<1>  field1_4;
    bit<1>  field1_5;
    bit<1>  field1_6;
    bit<1>  field1_7;
    bit<1>  field1_8;
    bit<8>  field8_1;
    bit<8>  field8_2;
    bit<8>  field8_3;
    bit<8>  field8_4;
    bit<8>  field8_5;
    bit<8>  field8_6;
    bit<8>  field8_7;
    bit<8>  field8_8;
    bit<64> field16_1;
    bit<64> field16_2;
    bit<64> field16_3;
    bit<64> field16_4;
    bit<64> field16_5;
    bit<64> field16_6;
    bit<64> field16_7;
    bit<64> field16_8;
    bit<32> field32_1;
    bit<32> field32_2;
    bit<32> field32_3;
    bit<32> field32_4;
    bit<32> field32_5;
    bit<32> field32_6;
    bit<32> field32_7;
    bit<32> field32_8;
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

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> ethertype;
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

struct metadata {
    @name("md") 
    metadata_t md;
}

struct headers {
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md") @pa_atomic("egress", "eg_intr_md.egress_port") @pa_fragment("egress", "eg_intr_md._pad1") @pa_fragment("egress", "eg_intr_md._pad7") @pa_fragment("egress", "eg_intr_md._pad8") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_port") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_cos") @name("eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @dont_trim @pa_intrinsic_header("egress", "eg_intr_md_for_mb") @pa_atomic("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_fragment("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_length") @not_deparsed("ingress") @not_deparsed("egress") @name("eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @dont_trim @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_oport.drop_ctl") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_for_oport") @name("eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @pa_fragment("egress", "eg_intr_md_from_parser_aux.coalesce_sample_count") @pa_fragment("egress", "eg_intr_md_from_parser_aux.clone_src") @pa_fragment("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @pa_atomic("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_from_parser_aux") @name("eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
    @name("ethernet") 
    ethernet_t                                     ethernet;
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md.ingress_port") @name("ig_intr_md") 
    ingress_intrinsic_metadata_t                   ig_intr_md;
    @dont_trim @pa_intrinsic_header("ingress", "ig_intr_md_for_mb") @pa_atomic("ingress", "ig_intr_md_for_mb.ingress_mirror_id") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_mb.ingress_mirror_id") @not_deparsed("ingress") @not_deparsed("egress") @name("ig_intr_md_for_mb") 
    ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb;
    @pa_atomic("ingress", "ig_intr_md_for_tm.ucast_egress_port") @pa_fragment("ingress", "ig_intr_md_for_tm.drop_ctl") @pa_fragment("ingress", "ig_intr_md_for_tm.qid") @pa_fragment("ingress", "ig_intr_md_for_tm._pad2") @pa_atomic("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_fragment("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_atomic("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_fragment("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_atomic("ingress", "ig_intr_md_for_tm.level1_mcast_hash") @pa_fragment("ingress", "ig_intr_md_for_tm._pad3") @pa_atomic("ingress", "ig_intr_md_for_tm.level2_mcast_hash") @pa_fragment("ingress", "ig_intr_md_for_tm._pad4") @pa_atomic("ingress", "ig_intr_md_for_tm.level1_exclusion_id") @pa_fragment("ingress", "ig_intr_md_for_tm.level1_exclusion_id") @pa_atomic("ingress", "ig_intr_md_for_tm.level2_exclusion_id") @pa_fragment("ingress", "ig_intr_md_for_tm._pad5") @pa_atomic("ingress", "ig_intr_md_for_tm.rid") @pa_fragment("ingress", "ig_intr_md_for_tm.rid") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md_for_tm") @dont_trim @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.drop_ctl") @name("ig_intr_md_for_tm") 
    ingress_intrinsic_metadata_for_tm_t            ig_intr_md_for_tm;
    @pa_fragment("ingress", "ig_intr_md_from_parser_aux.ingress_parser_err") @pa_atomic("ingress", "ig_intr_md_from_parser_aux.ingress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md_from_parser_aux") @name("ig_intr_md_from_parser_aux") 
    ingress_intrinsic_metadata_from_parser_aux_t   ig_intr_md_from_parser_aux;
    @not_deparsed("ingress") @not_deparsed("egress") @name("ig_pg_md") 
    generator_metadata_t                           ig_pg_md;
    @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_prsr_ctrl") @name("ig_prsr_ctrl") 
    ingress_parser_control_signals                 ig_prsr_ctrl;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("start") state start {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("NoAction") action NoAction_0() {
    }
    @name("NoAction") action NoAction_3() {
    }
    @name("set_field1_1") action set_field1(bit<1> value) {
        meta.md.field1_1 = value;
    }
    @name("set_field1_1") action set_field1_0(bit<1> value) {
        meta.md.field1_1 = value;
    }
    @name("set_field1_2") action set_field1_9(bit<1> value) {
        meta.md.field1_2 = value;
    }
    @name("set_field1_2") action set_field1_10(bit<1> value) {
        meta.md.field1_2 = value;
    }
    @name("set_field1_3") action set_field1_11(bit<1> value) {
        meta.md.field1_3 = value;
    }
    @name("set_field1_3") action set_field1_12(bit<1> value) {
        meta.md.field1_3 = value;
    }
    @name("set_field1_4") action set_field1_13(bit<1> value) {
        meta.md.field1_4 = value;
    }
    @name("set_field1_4") action set_field1_14(bit<1> value) {
        meta.md.field1_4 = value;
    }
    @name("set_field1_5") action set_field1_23(bit<1> value) {
        meta.md.field1_5 = value;
    }
    @name("set_field1_5") action set_field1_24(bit<1> value) {
        meta.md.field1_5 = value;
    }
    @name("set_field1_6") action set_field1_25(bit<1> value) {
        meta.md.field1_6 = value;
    }
    @name("set_field1_6") action set_field1_26(bit<1> value) {
        meta.md.field1_6 = value;
    }
    @name("set_field1_7") action set_field1_27(bit<1> value) {
        meta.md.field1_7 = value;
    }
    @name("set_field1_7") action set_field1_28(bit<1> value) {
        meta.md.field1_7 = value;
    }
    @name("set_field1_8") action set_field1_29(bit<1> value) {
        meta.md.field1_8 = value;
    }
    @name("set_field1_8") action set_field1_30(bit<1> value) {
        meta.md.field1_8 = value;
    }
    @name("set_field8_1") action set_field8(bit<8> value) {
        meta.md.field8_1 = value;
    }
    @name("set_field8_1") action set_field8_0(bit<8> value) {
        meta.md.field8_1 = value;
    }
    @name("set_field8_2") action set_field8_9(bit<8> value) {
        meta.md.field8_2 = value;
    }
    @name("set_field8_2") action set_field8_10(bit<8> value) {
        meta.md.field8_2 = value;
    }
    @name("set_field8_3") action set_field8_11(bit<8> value) {
        meta.md.field8_3 = value;
    }
    @name("set_field8_3") action set_field8_12(bit<8> value) {
        meta.md.field8_3 = value;
    }
    @name("set_field8_4") action set_field8_13(bit<8> value) {
        meta.md.field8_4 = value;
    }
    @name("set_field8_4") action set_field8_14(bit<8> value) {
        meta.md.field8_4 = value;
    }
    @name("set_field8_5") action set_field8_23(bit<8> value) {
        meta.md.field8_5 = value;
    }
    @name("set_field8_5") action set_field8_24(bit<8> value) {
        meta.md.field8_5 = value;
    }
    @name("set_field8_6") action set_field8_25(bit<8> value) {
        meta.md.field8_6 = value;
    }
    @name("set_field8_6") action set_field8_26(bit<8> value) {
        meta.md.field8_6 = value;
    }
    @name("set_field8_7") action set_field8_27(bit<8> value) {
        meta.md.field8_7 = value;
    }
    @name("set_field8_7") action set_field8_28(bit<8> value) {
        meta.md.field8_7 = value;
    }
    @name("set_field8_8") action set_field8_29(bit<8> value) {
        meta.md.field8_8 = value;
    }
    @name("set_field8_8") action set_field8_30(bit<8> value) {
        meta.md.field8_8 = value;
    }
    @name("set_field16_1") action set_field16(bit<64> value) {
        meta.md.field16_1 = value;
    }
    @name("set_field16_1") action set_field16_0(bit<64> value) {
        meta.md.field16_1 = value;
    }
    @name("set_field16_2") action set_field16_9(bit<64> value) {
        meta.md.field16_2 = value;
    }
    @name("set_field16_2") action set_field16_10(bit<64> value) {
        meta.md.field16_2 = value;
    }
    @name("set_field16_3") action set_field16_11(bit<64> value) {
        meta.md.field16_3 = value;
    }
    @name("set_field16_3") action set_field16_12(bit<64> value) {
        meta.md.field16_3 = value;
    }
    @name("set_field16_4") action set_field16_13(bit<64> value) {
        meta.md.field16_4 = value;
    }
    @name("set_field16_4") action set_field16_14(bit<64> value) {
        meta.md.field16_4 = value;
    }
    @name("set_field16_5") action set_field16_23(bit<64> value) {
        meta.md.field16_5 = value;
    }
    @name("set_field16_5") action set_field16_24(bit<64> value) {
        meta.md.field16_5 = value;
    }
    @name("set_field16_6") action set_field16_25(bit<64> value) {
        meta.md.field16_6 = value;
    }
    @name("set_field16_6") action set_field16_26(bit<64> value) {
        meta.md.field16_6 = value;
    }
    @name("set_field16_7") action set_field16_27(bit<64> value) {
        meta.md.field16_7 = value;
    }
    @name("set_field16_7") action set_field16_28(bit<64> value) {
        meta.md.field16_7 = value;
    }
    @name("set_field16_8") action set_field16_29(bit<64> value) {
        meta.md.field16_8 = value;
    }
    @name("set_field16_8") action set_field16_30(bit<64> value) {
        meta.md.field16_8 = value;
    }
    @name("set_field32_1") action set_field32(bit<32> value) {
        meta.md.field32_1 = value;
    }
    @name("set_field32_1") action set_field32_0(bit<32> value) {
        meta.md.field32_1 = value;
    }
    @name("set_field32_2") action set_field32_8(bit<32> value) {
        meta.md.field32_2 = value;
    }
    @name("set_field32_2") action set_field32_9(bit<32> value) {
        meta.md.field32_2 = value;
    }
    @name("set_field32_3") action set_field32_10(bit<32> value) {
        meta.md.field32_3 = value;
    }
    @name("set_field32_3") action set_field32_11(bit<32> value) {
        meta.md.field32_3 = value;
    }
    @name("set_field32_4") action set_field32_12(bit<32> value) {
        meta.md.field32_4 = value;
    }
    @name("set_field32_4") action set_field32_20(bit<32> value) {
        meta.md.field32_4 = value;
    }
    @name("set_field32_5") action set_field32_21(bit<32> value) {
        meta.md.field32_5 = value;
    }
    @name("set_field32_5") action set_field32_22(bit<32> value) {
        meta.md.field32_5 = value;
    }
    @name("set_field32_6") action set_field32_23(bit<32> value) {
        meta.md.field32_6 = value;
    }
    @name("set_field32_6") action set_field32_24(bit<32> value) {
        meta.md.field32_6 = value;
    }
    @name("set_field32_7") action set_field32_25(bit<32> value) {
        meta.md.field32_7 = value;
    }
    @name("set_field32_7") action set_field32_26(bit<32> value) {
        meta.md.field32_7 = value;
    }
    @name("dmac1") table dmac1() {
        actions = {
            set_field1();
            set_field1_9();
            set_field1_11();
            set_field1_13();
            set_field1_23();
            set_field1_25();
            set_field1_27();
            set_field1_29();
            set_field8();
            set_field8_9();
            set_field8_11();
            set_field8_13();
            set_field8_23();
            set_field8_25();
            set_field8_27();
            set_field8_29();
            set_field16();
            set_field16_9();
            set_field16_11();
            set_field16_13();
            set_field16_23();
            set_field16_25();
            set_field16_27();
            set_field16_29();
            set_field32();
            set_field32_8();
            set_field32_10();
            set_field32_12();
            set_field32_21();
            set_field32_23();
            set_field32_25();
            @default_only NoAction_0();
        }
        key = {
            hdr.ethernet.dstAddr: exact @name("hdr.ethernet.dstAddr") ;
        }
        size = 32768;
        default_action = NoAction_0();
    }
    @name("dmac2") table dmac2() {
        actions = {
            set_field1_0();
            set_field1_10();
            set_field1_12();
            set_field1_14();
            set_field1_24();
            set_field1_26();
            set_field1_28();
            set_field1_30();
            set_field8_0();
            set_field8_10();
            set_field8_12();
            set_field8_14();
            set_field8_24();
            set_field8_26();
            set_field8_28();
            set_field8_30();
            set_field16_0();
            set_field16_10();
            set_field16_12();
            set_field16_14();
            set_field16_24();
            set_field16_26();
            set_field16_28();
            set_field16_30();
            set_field32_0();
            set_field32_9();
            set_field32_11();
            set_field32_20();
            set_field32_22();
            set_field32_24();
            set_field32_26();
            @default_only NoAction_3();
        }
        key = {
            hdr.ethernet.dstAddr: exact @name("hdr.ethernet.dstAddr") ;
        }
        size = 32768;
        default_action = NoAction_3();
    }
    apply {
        if ((hdr.ig_intr_md.ingress_port & 9w0x1) == 9w0x1) 
            dmac1.apply();
        else 
            dmac2.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
