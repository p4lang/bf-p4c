#include <core.p4>
#include <v1model.p4>

struct hct_metadata_t {
    bit<1>  enable_capture_timestamp;
    bit<1>  capture_timestamp_trigger;
    bit<32> timestamp_index;
    bit<32> timestamp_temp;
    bit<4>  capture_timestamp_1;
    bit<4>  capture_timestamp_2;
    bit<4>  capture_timestamp_3;
    bit<4>  capture_timestamp_4;
    bit<4>  capture_timestamp_5;
    bit<4>  capture_timestamp_6;
    bit<4>  capture_timestamp_7;
    bit<4>  capture_timestamp_8;
    bit<4>  capture_timestamp_9;
    bit<4>  capture_timestamp_10;
    bit<4>  capture_timestamp_11;
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

header pktgen_generic_header_t {
    bit<3>  _pad0;
    bit<2>  pipe_id;
    bit<3>  app_id;
    bit<8>  key_msb;
    bit<16> batch_id;
    bit<16> packet_id;
}

header pktgen_port_down_header_t {
    bit<3>  _pad0;
    bit<2>  pipe_id;
    bit<3>  app_id;
    bit<15> _pad1;
    bit<9>  port_num;
    bit<16> packet_id;
}

header pktgen_recirc_header_t {
    bit<3>  _pad0;
    bit<2>  pipe_id;
    bit<3>  app_id;
    bit<24> key;
    bit<16> packet_id;
}

header pktgen_timer_header_t {
    bit<3>  _pad0;
    bit<2>  pipe_id;
    bit<3>  app_id;
    bit<8>  _pad1;
    bit<16> batch_id;
    bit<16> packet_id;
}

struct metadata {
    @name(".hct_metadata") 
    hct_metadata_t hct_metadata;
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
    @name(".pktgen_generic") 
    pktgen_generic_header_t                        pktgen_generic;
    @name(".pktgen_port_down") 
    pktgen_port_down_header_t                      pktgen_port_down;
    @name(".pktgen_recirc") 
    pktgen_recirc_header_t                         pktgen_recirc;
    @name(".pktgen_timer") 
    pktgen_timer_header_t                          pktgen_timer;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition accept;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

@name(".timestamp_1") register<bit<32>>(32w143360) timestamp_1;

@name(".timestamp_10") register<bit<32>>(32w143360) timestamp_10;

@name(".timestamp_11") register<bit<32>>(32w143360) timestamp_11;

@name(".timestamp_2") register<bit<32>>(32w143360) timestamp_2;

@name(".timestamp_3") register<bit<32>>(32w143360) timestamp_3;

@name(".timestamp_4") register<bit<32>>(32w143360) timestamp_4;

@name(".timestamp_5") register<bit<32>>(32w143360) timestamp_5;

@name(".timestamp_6") register<bit<32>>(32w143360) timestamp_6;

@name(".timestamp_7") register<bit<32>>(32w143360) timestamp_7;

@name(".timestamp_8") register<bit<32>>(32w143360) timestamp_8;

@name(".timestamp_9") register<bit<32>>(32w143360) timestamp_9;

struct timestamp_index_layout {
    bit<32> lo;
    bit<32> hi;
}

@name(".timestamp_index") register<timestamp_index_layout>(32w1) timestamp_index;

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<32> tmp;
    bit<32> tmp_0;
    bit<32> tmp_1;
    bit<32> tmp_2;
    bit<32> tmp_3;
    bit<32> tmp_4;
    bit<32> tmp_5;
    bit<32> tmp_6;
    bit<32> tmp_7;
    bit<32> tmp_8;
    bit<32> tmp_9;
    bit<32> tmp_10;
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_1() {
    }
    @name(".NoAction") action NoAction_20() {
    }
    @name(".NoAction") action NoAction_21() {
    }
    @name(".NoAction") action NoAction_22() {
    }
    @name(".NoAction") action NoAction_23() {
    }
    @name(".NoAction") action NoAction_24() {
    }
    @name(".NoAction") action NoAction_25() {
    }
    @name(".NoAction") action NoAction_26() {
    }
    @name(".NoAction") action NoAction_27() {
    }
    @name(".NoAction") action NoAction_28() {
    }
    @name(".NoAction") action NoAction_29() {
    }
    @name(".capture_timestamp_1") RegisterAction<bit<32>, bit<32>, bit<32>>(timestamp_1) capture_timestamp = {
        void apply(inout bit<32> value, out bit<32> rv) {
            bit<32> in_value_0;
            in_value_0 = value;
            rv = 32w1;
            if (meta.hct_metadata.timestamp_index < 32w262144 && meta.hct_metadata.timestamp_index >= 32w0) 
                value = meta.hct_metadata.timestamp_temp;
            if (meta.hct_metadata.timestamp_index >= 32w262144 || meta.hct_metadata.timestamp_index < 32w0) 
                value = in_value_0;
        }
    };
    @name(".capture_timestamp_10") RegisterAction<bit<32>, bit<32>, bit<32>>(timestamp_10) capture_timestamp_0 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            bit<32> in_value_1;
            in_value_1 = value;
            rv = 32w1;
            if (meta.hct_metadata.timestamp_index < 32w2621440 && meta.hct_metadata.timestamp_index >= 32w2359296) 
                value = meta.hct_metadata.timestamp_temp;
            if (meta.hct_metadata.timestamp_index >= 32w2621440 || meta.hct_metadata.timestamp_index < 32w2359296) 
                value = in_value_1;
        }
    };
    @name(".capture_timestamp_11") RegisterAction<bit<32>, bit<32>, bit<32>>(timestamp_11) capture_timestamp_12 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            bit<32> in_value_2;
            in_value_2 = value;
            rv = 32w1;
            if (meta.hct_metadata.timestamp_index < 32w2883584 && meta.hct_metadata.timestamp_index >= 32w2621440) 
                value = meta.hct_metadata.timestamp_temp;
            if (meta.hct_metadata.timestamp_index >= 32w2883584 || meta.hct_metadata.timestamp_index < 32w2621440) 
                value = in_value_2;
        }
    };
    @name(".capture_timestamp_2") RegisterAction<bit<32>, bit<32>, bit<32>>(timestamp_2) capture_timestamp_13 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            bit<32> in_value_3;
            in_value_3 = value;
            rv = 32w1;
            if (meta.hct_metadata.timestamp_index < 32w524288 && meta.hct_metadata.timestamp_index >= 32w262144) 
                value = meta.hct_metadata.timestamp_temp;
            if (meta.hct_metadata.timestamp_index >= 32w524288 || meta.hct_metadata.timestamp_index < 32w262144) 
                value = in_value_3;
        }
    };
    @name(".capture_timestamp_3") RegisterAction<bit<32>, bit<32>, bit<32>>(timestamp_3) capture_timestamp_14 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            bit<32> in_value_4;
            in_value_4 = value;
            rv = 32w1;
            if (meta.hct_metadata.timestamp_index < 32w786432 && meta.hct_metadata.timestamp_index >= 32w524288) 
                value = meta.hct_metadata.timestamp_temp;
            if (meta.hct_metadata.timestamp_index >= 32w786432 || meta.hct_metadata.timestamp_index < 32w524288) 
                value = in_value_4;
        }
    };
    @name(".capture_timestamp_4") RegisterAction<bit<32>, bit<32>, bit<32>>(timestamp_4) capture_timestamp_15 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            bit<32> in_value_5;
            in_value_5 = value;
            rv = 32w1;
            if (meta.hct_metadata.timestamp_index < 32w1048576 && meta.hct_metadata.timestamp_index >= 32w786432) 
                value = meta.hct_metadata.timestamp_temp;
            if (meta.hct_metadata.timestamp_index >= 32w1048576 || meta.hct_metadata.timestamp_index < 32w786432) 
                value = in_value_5;
        }
    };
    @name(".capture_timestamp_5") RegisterAction<bit<32>, bit<32>, bit<32>>(timestamp_5) capture_timestamp_16 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            bit<32> in_value_6;
            in_value_6 = value;
            rv = 32w1;
            if (meta.hct_metadata.timestamp_index < 32w1310720 && meta.hct_metadata.timestamp_index >= 32w1048576) 
                value = meta.hct_metadata.timestamp_temp;
            if (meta.hct_metadata.timestamp_index >= 32w1310720 || meta.hct_metadata.timestamp_index < 32w1048576) 
                value = in_value_6;
        }
    };
    @name(".capture_timestamp_6") RegisterAction<bit<32>, bit<32>, bit<32>>(timestamp_6) capture_timestamp_17 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            bit<32> in_value_7;
            in_value_7 = value;
            rv = 32w1;
            if (meta.hct_metadata.timestamp_index < 32w1572864 && meta.hct_metadata.timestamp_index >= 32w1310720) 
                value = meta.hct_metadata.timestamp_temp;
            if (meta.hct_metadata.timestamp_index >= 32w1572864 || meta.hct_metadata.timestamp_index < 32w1310720) 
                value = in_value_7;
        }
    };
    @name(".capture_timestamp_7") RegisterAction<bit<32>, bit<32>, bit<32>>(timestamp_7) capture_timestamp_18 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            bit<32> in_value_8;
            in_value_8 = value;
            rv = 32w1;
            if (meta.hct_metadata.timestamp_index < 32w1835008 && meta.hct_metadata.timestamp_index >= 32w1572864) 
                value = meta.hct_metadata.timestamp_temp;
            if (meta.hct_metadata.timestamp_index >= 32w1835008 || meta.hct_metadata.timestamp_index < 32w1572864) 
                value = in_value_8;
        }
    };
    @name(".capture_timestamp_8") RegisterAction<bit<32>, bit<32>, bit<32>>(timestamp_8) capture_timestamp_19 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            bit<32> in_value_9;
            in_value_9 = value;
            rv = 32w1;
            if (meta.hct_metadata.timestamp_index < 32w2097152 && meta.hct_metadata.timestamp_index >= 32w1835008) 
                value = meta.hct_metadata.timestamp_temp;
            if (meta.hct_metadata.timestamp_index >= 32w2097152 || meta.hct_metadata.timestamp_index < 32w1835008) 
                value = in_value_9;
        }
    };
    @name(".capture_timestamp_9") RegisterAction<bit<32>, bit<32>, bit<32>>(timestamp_9) capture_timestamp_20 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            bit<32> in_value_10;
            in_value_10 = value;
            rv = 32w1;
            if (meta.hct_metadata.timestamp_index < 32w2359296 && meta.hct_metadata.timestamp_index >= 32w2097152) 
                value = meta.hct_metadata.timestamp_temp;
            if (meta.hct_metadata.timestamp_index >= 32w2359296 || meta.hct_metadata.timestamp_index < 32w2097152) 
                value = in_value_10;
        }
    };
    @name(".timestamp_index_0") RegisterAction<timestamp_index_layout, bit<32>, bit<32>>(timestamp_index) timestamp_index_2 = {
        void apply(inout         struct timestamp_index_layout {
            bit<32> lo;
            bit<32> hi;
        }
value, out bit<32> rv) {
            timestamp_index_layout in_value_11;
            in_value_11.lo = value.lo;
            in_value_11.hi = value.hi;
            rv = value.lo;
            if (value.hi < 32w143359) 
                value.hi = value.hi + 32w1;
            if (in_value_11.hi >= 32w143359) 
                value.hi = 32w0;
            if (value.lo < 32w1576960 && in_value_11.hi < 32w143359) 
                value.lo = value.lo + 32w1;
            if (in_value_11.hi >= 32w143359) 
                value.lo = in_value_11.lo + 32w0x1d001;
        }
    };
    @name(".write_timestamp_1") action write_timestamp_1() {
        tmp = capture_timestamp.execute(meta.hct_metadata.timestamp_index);
        meta.hct_metadata.capture_timestamp_1 = (bit<4>)tmp;
    }
    @name(".write_timestamp_10") action write_timestamp_2() {
        tmp_0 = capture_timestamp_0.execute(meta.hct_metadata.timestamp_index);
        meta.hct_metadata.capture_timestamp_10 = (bit<4>)tmp_0;
    }
    @name(".write_timestamp_11") action write_timestamp_3() {
        tmp_1 = capture_timestamp_12.execute(meta.hct_metadata.timestamp_index);
        meta.hct_metadata.capture_timestamp_11 = (bit<4>)tmp_1;
    }
    @name(".write_timestamp_2") action write_timestamp_4() {
        tmp_2 = capture_timestamp_13.execute(meta.hct_metadata.timestamp_index);
        meta.hct_metadata.capture_timestamp_2 = (bit<4>)tmp_2;
    }
    @name(".write_timestamp_3") action write_timestamp_5() {
        tmp_3 = capture_timestamp_14.execute(meta.hct_metadata.timestamp_index);
        meta.hct_metadata.capture_timestamp_3 = (bit<4>)tmp_3;
    }
    @name(".write_timestamp_4") action write_timestamp_6() {
        tmp_4 = capture_timestamp_15.execute(meta.hct_metadata.timestamp_index);
        meta.hct_metadata.capture_timestamp_4 = (bit<4>)tmp_4;
    }
    @name(".write_timestamp_5") action write_timestamp_7() {
        tmp_5 = capture_timestamp_16.execute(meta.hct_metadata.timestamp_index);
        meta.hct_metadata.capture_timestamp_5 = (bit<4>)tmp_5;
    }
    @name(".write_timestamp_6") action write_timestamp_8() {
        tmp_6 = capture_timestamp_17.execute(meta.hct_metadata.timestamp_index);
        meta.hct_metadata.capture_timestamp_6 = (bit<4>)tmp_6;
    }
    @name(".write_timestamp_7") action write_timestamp_9() {
        tmp_7 = capture_timestamp_18.execute(meta.hct_metadata.timestamp_index);
        meta.hct_metadata.capture_timestamp_7 = (bit<4>)tmp_7;
    }
    @name(".write_timestamp_8") action write_timestamp_10() {
        tmp_8 = capture_timestamp_19.execute(meta.hct_metadata.timestamp_index);
        meta.hct_metadata.capture_timestamp_8 = (bit<4>)tmp_8;
    }
    @name(".write_timestamp_9") action write_timestamp_11() {
        tmp_9 = capture_timestamp_20.execute(meta.hct_metadata.timestamp_index);
        meta.hct_metadata.capture_timestamp_9 = (bit<4>)tmp_9;
    }
    @name(".timestamp_index_counter") action timestamp_index_counter() {
        tmp_10 = timestamp_index_2.execute(32w0);
        meta.hct_metadata.timestamp_index = tmp_10;
        meta.hct_metadata.timestamp_temp[31:0] = ((bit<32>)hdr.eg_intr_md_from_parser_aux.egress_global_tstamp)[31:0];
    }
    @name(".capture_timestamp_1") table capture_timestamp_1_1 {
        actions = {
            write_timestamp_1();
            @defaultonly NoAction_0();
        }
        default_action = NoAction_0();
    }
    @name(".capture_timestamp_10") table capture_timestamp_10_1 {
        actions = {
            write_timestamp_2();
            @defaultonly NoAction_1();
        }
        default_action = NoAction_1();
    }
    @name(".capture_timestamp_11") table capture_timestamp_11_1 {
        actions = {
            write_timestamp_3();
            @defaultonly NoAction_20();
        }
        default_action = NoAction_20();
    }
    @name(".capture_timestamp_2") table capture_timestamp_2_1 {
        actions = {
            write_timestamp_4();
            @defaultonly NoAction_21();
        }
        default_action = NoAction_21();
    }
    @name(".capture_timestamp_3") table capture_timestamp_3_1 {
        actions = {
            write_timestamp_5();
            @defaultonly NoAction_22();
        }
        default_action = NoAction_22();
    }
    @name(".capture_timestamp_4") table capture_timestamp_4_1 {
        actions = {
            write_timestamp_6();
            @defaultonly NoAction_23();
        }
        default_action = NoAction_23();
    }
    @name(".capture_timestamp_5") table capture_timestamp_5_1 {
        actions = {
            write_timestamp_7();
            @defaultonly NoAction_24();
        }
        default_action = NoAction_24();
    }
    @name(".capture_timestamp_6") table capture_timestamp_6_1 {
        actions = {
            write_timestamp_8();
            @defaultonly NoAction_25();
        }
        default_action = NoAction_25();
    }
    @name(".capture_timestamp_7") table capture_timestamp_7_1 {
        actions = {
            write_timestamp_9();
            @defaultonly NoAction_26();
        }
        default_action = NoAction_26();
    }
    @name(".capture_timestamp_8") table capture_timestamp_8_1 {
        actions = {
            write_timestamp_10();
            @defaultonly NoAction_27();
        }
        default_action = NoAction_27();
    }
    @name(".capture_timestamp_9") table capture_timestamp_9_1 {
        actions = {
            write_timestamp_11();
            @defaultonly NoAction_28();
        }
        default_action = NoAction_28();
    }
    @name(".timestamp_index") table timestamp_index_3 {
        actions = {
            timestamp_index_counter();
            @defaultonly NoAction_29();
        }
        size = 1;
        default_action = NoAction_29();
    }
    apply {
        if (meta.hct_metadata.capture_timestamp_trigger == 1w1) {
            timestamp_index_3.apply();
            capture_timestamp_1_1.apply();
            capture_timestamp_2_1.apply();
            capture_timestamp_3_1.apply();
            capture_timestamp_4_1.apply();
            capture_timestamp_5_1.apply();
            capture_timestamp_6_1.apply();
            capture_timestamp_7_1.apply();
            capture_timestamp_8_1.apply();
            capture_timestamp_9_1.apply();
            capture_timestamp_10_1.apply();
            capture_timestamp_11_1.apply();
        }
        else 
            ;
    }
}
#include <tofino/p4_14_prim.p4>

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<3> tmp_11;
    @name(".NoAction") action NoAction_30() {
    }
    @name(".NoAction") action NoAction_31() {
    }
    @name(".NoAction") action NoAction_32() {
    }
    @name(".NoAction") action NoAction_33() {
    }
    @name(".NoAction") action NoAction_34() {
    }
    @name(".NoAction") action NoAction_35() {
    }
    @name(".ingress_port_meter") meter(32w100, MeterType.bytes) ingress_port_meter_0;
    @name(".capture_timestamp_trigger") action capture_timestamp_trigger_0(bit<1> enable) {
        meta.hct_metadata.capture_timestamp_trigger = enable;
    }
    @name(".capture_timestamp_trigger_sync") action capture_timestamp_trigger_sync(bit<1> enable) {
        meta.hct_metadata.enable_capture_timestamp = enable;
    }
    @name("._drop") action _drop() {
        mark_to_drop();
    }
    @name("._drop") action _drop_2() {
        mark_to_drop();
    }
    @name(".route") action route(bit<9> port_out) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port_out;
    }
    @name(".route") action route_3(bit<9> port_out) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port_out;
    }
    @name(".nop") action nop() {
    }
    @name(".nop") action nop_4() {
    }
    @name(".nop") action nop_5() {
    }
    @name(".nop") action nop_6() {
    }
    @name(".drop_ctl") action drop_ctl_1(bit<3> drop_ctl) {
        hdr.ig_intr_md_for_tm.drop_ctl[1:0] = drop_ctl[1:0];
    }
    @name(".ingress_port_meter") action ingress_port_meter_3(bit<32> meter_idx) {
        execute_meter_with_color<meter, bit<32>, bit<3>>(ingress_port_meter_0, meter_idx, tmp_11, hdr.ig_intr_md_for_tm.drop_ctl);
        hdr.ig_intr_md_for_tm.drop_ctl = tmp_11;
    }
    @name(".capture_timestamp_trigger") table capture_timestamp_trigger_2 {
        actions = {
            capture_timestamp_trigger_0();
            @defaultonly NoAction_30();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 5;
        default_action = NoAction_30();
    }
    @name(".capture_timestamp_trigger_sync") table capture_timestamp_trigger_sync_2 {
        actions = {
            capture_timestamp_trigger_sync();
            @defaultonly NoAction_31();
        }
        size = 1;
        default_action = NoAction_31();
    }
    @name(".dmac") table dmac_0 {
        support_timeout = true;
        actions = {
            _drop();
            route();
            nop();
            @defaultonly NoAction_32();
        }
        key = {
            hdr.ethernet.dstAddr: ternary @name("ethernet.dstAddr") ;
        }
        size = 1024;
        default_action = NoAction_32();
    }
    @name(".drop_ctl_table") table drop_ctl_table_0 {
        actions = {
            drop_ctl_1();
            nop_4();
            @defaultonly NoAction_33();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 32;
        default_action = NoAction_33();
    }
    @name(".ingress_port_meter") table ingress_port_meter_4 {
        actions = {
            ingress_port_meter_3();
            nop_5();
            @defaultonly NoAction_34();
        }
        key = {
            hdr.ethernet.dstAddr: ternary @name("ethernet.dstAddr") ;
        }
        size = 1024;
        default_action = NoAction_34();
    }
    @name(".route") table route_4 {
        support_timeout = true;
        actions = {
            _drop_2();
            route_3();
            nop_6();
            @defaultonly NoAction_35();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 260;
        default_action = NoAction_35();
    }
    apply {
        route_4.apply();
        dmac_0.apply();
        capture_timestamp_trigger_sync_2.apply();
        if (meta.hct_metadata.enable_capture_timestamp == 1w1) 
            capture_timestamp_trigger_2.apply();
        else 
            ;
        drop_ctl_table_0.apply();
        ingress_port_meter_4.apply();
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

