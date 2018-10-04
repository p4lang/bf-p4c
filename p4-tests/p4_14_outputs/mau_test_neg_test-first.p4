#include <core.p4>
#include <v1model.p4>

struct metadata_t {
    bit<32> stats_key;
    bit<8>  m1_clr;
    bit<32> m1_idx;
    bit<1>  m1_drop;
    bit<1>  drop_it;
    bit<2>  count_it;
    bit<1>  resubmit_for_meter_test;
    bit<1>  dummy;
    bit<8>  mr_clr;
    bit<8>  e3_meter;
    bit<8>  t3_meter;
    bit<8>  e4_meter;
    bit<8>  t4_meter;
    bit<32> e5_lpf;
    bit<32> t5_lpf;
    bit<32> e6_lpf;
    bit<32> t6_lpf;
    bit<32> e5_lpf_tmp1;
    bit<32> t5_lpf_tmp1;
    bit<32> e6_lpf_tmp1;
    bit<32> t6_lpf_tmp1;
    bit<32> e5_lpf_tmp2;
    bit<32> t5_lpf_tmp2;
    bit<32> e6_lpf_tmp2;
    bit<32> t6_lpf_tmp2;
    bit<32> e1_stful;
    bit<32> t1_stful;
    bit<32> mr1_fail;
    bit<16> etherType_hi;
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
    bit<16> srcAddrHi;
    bit<32> srcAddr;
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

header move_reg_key_t {
    bit<8> hi;
    bit<8> lo;
}

struct metadata {
    @name(".md") 
    metadata_t md;
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
    @pa_fragment("egress", "ethernet.etherType") @name(".ethernet") 
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
    @pa_fragment("egress", "mrk.hi") @pa_fragment("egress", "mrk.lo") @name(".mrk") 
    move_reg_key_t                                 mrk;
}
#include <tofino/lpf.p4>
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".drop_tag") state drop_tag {
        meta.md.drop_it = 1w1;
        transition accept;
    }
    @name(".get_move_reg_key") state get_move_reg_key {
        packet.extract<move_reg_key_t>(hdr.mrk);
        transition accept;
    }
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0xccc1: stat_tag_one;
            16w0xccc2: stat_tag_two;
            16w0xccc3: stat_tag_three;
            16w0xdead: drop_tag;
            default: get_move_reg_key;
        }
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
    @name(".stat_tag_one") state stat_tag_one {
        meta.md.count_it = 2w1;
        transition accept;
    }
    @name(".stat_tag_three") state stat_tag_three {
        meta.md.count_it = 2w3;
        transition accept;
    }
    @name(".stat_tag_two") state stat_tag_two {
        meta.md.count_it = 2w2;
        transition accept;
    }
}

@name(".sel_tbl_ap") @mode("resilient") action_selector(HashAlgorithm.random, 32w1024, 32w51) sel_tbl_ap;

struct e1_alu_layout {
    int<32> lo;
    int<32> hi;
}

@name(".e1_reg") register<e1_alu_layout>(32w0) e1_reg;

struct e2_alu_layout {
    bit<16> lo;
    bit<16> hi;
}

@name(".e2_reg") register<e2_alu_layout>(32w0) e2_reg;

struct t1_alu_layout {
    int<32> lo;
    int<32> hi;
}

@name(".t1_reg") register<t1_alu_layout>(32w0) t1_reg;

struct t2_alu_layout {
    bit<16> lo;
    bit<16> hi;
}

@name(".t2_reg") register<t2_alu_layout>(32w0) t2_reg;

struct vp5_alu_layout {
    bit<32> lo;
    bit<32> hi;
}

@name(".vp5_reg") register<vp5_alu_layout>(32w0) vp5_reg;

struct vp6_alu_layout {
    bit<32> lo;
    bit<32> hi;
}

@name(".vp6_reg") register<vp6_alu_layout>(32w0) vp6_reg;

struct vpp5_alu_layout {
    bit<32> lo;
    bit<32> hi;
}

@name(".vpp5_reg") register<vpp5_alu_layout>(32w0) vpp5_reg;

struct vpp6_alu_layout {
    bit<32> lo;
    bit<32> hi;
}

@name(".vpp6_reg") register<vpp6_alu_layout>(32w0) vpp6_reg;

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @lrt_enable(0) @lrt_scale(154) @name(".e1_cntr") @min_width(64) direct_counter(CounterType.packets) e1_cntr;
    @lrt_enable(0) @lrt_scale(15811) @name(".e2_cntr") @min_width(32) direct_counter(CounterType.packets) e2_cntr;
    @lrt_enable(0) @lrt_scale(154) @name(".e3_cntr") @min_width(64) direct_counter(CounterType.bytes) e3_cntr;
    @lrt_enable(0) @lrt_scale(15811) @name(".e4_cntr") direct_counter(CounterType.packets) e4_cntr;
    @lrt_enable(0) @lrt_scale(154) @name(".e5_cntr") @min_width(32) direct_counter(CounterType.bytes) e5_cntr;
    @lrt_enable(0) @lrt_scale(15811) @name(".e6_cntr") direct_counter(CounterType.packets) e6_cntr;
    @lrt_enable(0) @lrt_scale(154) @name(".t1_cntr") @min_width(64) direct_counter(CounterType.packets) t1_cntr;
    @lrt_enable(0) @lrt_scale(15811) @name(".t2_cntr") @min_width(32) direct_counter(CounterType.packets) t2_cntr;
    @lrt_enable(0) @lrt_scale(154) @name(".t3_cntr") @min_width(64) direct_counter(CounterType.bytes) t3_cntr;
    @lrt_enable(0) @lrt_scale(15811) @name(".t4_cntr") direct_counter(CounterType.packets) t4_cntr;
    @lrt_enable(0) @lrt_scale(154) @name(".t5_cntr") @min_width(32) direct_counter(CounterType.bytes) t5_cntr;
    @lrt_enable(0) @lrt_scale(15811) @name(".t6_cntr") direct_counter(CounterType.packets) t6_cntr;
    @name(".v3_cntr") direct_counter(CounterType.bytes) v3_cntr;
    @name(".v4_cntr") direct_counter(CounterType.packets) v4_cntr;
    @name(".v5_cntr") direct_counter(CounterType.bytes) v5_cntr;
    @name(".v6_cntr") direct_counter(CounterType.packets) v6_cntr;
    @lrt_enable(1) @name(".eg_cntr_1") @min_width(32) counter(32w32768, CounterType.packets_and_bytes) eg_cntr_1;
    @lrt_enable(1) @name(".eg_cntr_2") @min_width(32) counter(32w4096, CounterType.packets_and_bytes) eg_cntr_2;
    @name(".eg_cntr_3") counter(32w16384, CounterType.packets_and_bytes) eg_cntr_3;
    @name(".eg_cntr_4") counter(32w2048, CounterType.packets) eg_cntr_4;
    @meter_sweep_interval(0) @name(".e3_meter") @pre_color(meta.md.mr_clr) direct_meter<bit<8>>(MeterType.bytes) e3_meter;
    @meter_sweep_interval(0) @name(".e4_meter") @pre_color(meta.md.mr_clr) direct_meter<bit<8>>(MeterType.packets) e4_meter;
    @meter_sweep_interval(0) @name(".t3_meter") @pre_color(meta.md.mr_clr) direct_meter<bit<8>>(MeterType.bytes) t3_meter;
    @meter_sweep_interval(0) @name(".t4_meter") @pre_color(meta.md.mr_clr) direct_meter<bit<8>>(MeterType.packets) t4_meter;
    @name(".e1_alu") DirectRegisterAction<e1_alu_layout, int<32>>(e1_reg) e1_alu = {
        void apply(inout         struct e1_alu_layout {
            int<32> lo;
            int<32> hi;
        }
value, out int<32> rv) {
            rv = 32s0;
            e1_alu_layout in_value;
            in_value = value;
            rv = in_value.hi;
            value.hi = in_value.hi + 32s1;
            if (in_value.lo != (int<32>)(bit<32>)hdr.ethernet.etherType) 
                value.lo = 32s0;
        }
    };
    @name(".e2_alu") DirectRegisterAction<e2_alu_layout, bit<16>>(e2_reg) e2_alu = {
        void apply(inout         struct e2_alu_layout {
            bit<16> lo;
            bit<16> hi;
        }
value) {
            e2_alu_layout in_value;
            in_value = value;
            value.hi = in_value.hi + 16w1;
            if (in_value.lo != hdr.ethernet.etherType) 
                value.lo = 16w0;
        }
    };
    @name(".e5_lpf") DirectLpf<bit<32>>() e5_lpf;
    @name(".e6_lpf") DirectLpf<bit<32>>() e6_lpf;
    @name(".t1_alu") DirectRegisterAction<t1_alu_layout, int<32>>(t1_reg) t1_alu = {
        void apply(inout         struct t1_alu_layout {
            int<32> lo;
            int<32> hi;
        }
value, out int<32> rv) {
            rv = 32s0;
            t1_alu_layout in_value;
            in_value = value;
            rv = in_value.hi;
            value.hi = in_value.hi + 32s1;
            if (in_value.lo != (int<32>)(bit<32>)hdr.ethernet.etherType) 
                value.lo = 32s0;
        }
    };
    @name(".t2_alu") DirectRegisterAction<t2_alu_layout, bit<16>>(t2_reg) t2_alu = {
        void apply(inout         struct t2_alu_layout {
            bit<16> lo;
            bit<16> hi;
        }
value) {
            t2_alu_layout in_value;
            in_value = value;
            value.hi = in_value.hi + 16w1;
            if (in_value.lo != hdr.ethernet.etherType) 
                value.lo = 16w0;
        }
    };
    @name(".t5_lpf") DirectLpf<bit<32>>() t5_lpf;
    @name(".t6_lpf") DirectLpf<bit<32>>() t6_lpf;
    @name(".vp5_alu") DirectRegisterAction<vp5_alu_layout, bit<32>>(vp5_reg) vp5_alu = {
        void apply(inout         struct vp5_alu_layout {
            bit<32> lo;
            bit<32> hi;
        }
value) {
            vp5_alu_layout in_value;
            in_value = value;
            if (in_value.lo == 32w0xffffffff) 
                value.hi = in_value.hi + 32w1;
            value.lo = in_value.lo + 32w1;
        }
    };
    @name(".vp6_alu") DirectRegisterAction<vp6_alu_layout, bit<32>>(vp6_reg) vp6_alu = {
        void apply(inout         struct vp6_alu_layout {
            bit<32> lo;
            bit<32> hi;
        }
value) {
            vp6_alu_layout in_value;
            in_value = value;
            if (in_value.lo == 32w0xffffffff) 
                value.hi = in_value.hi + 32w1;
            value.lo = in_value.lo + 32w1;
        }
    };
    @name(".vpp5_alu") DirectRegisterAction<vpp5_alu_layout, bit<32>>(vpp5_reg) vpp5_alu = {
        void apply(inout         struct vpp5_alu_layout {
            bit<32> lo;
            bit<32> hi;
        }
value) {
            vpp5_alu_layout in_value;
            in_value = value;
            if (in_value.lo == 32w0xffffffff) 
                value.hi = in_value.hi + 32w1;
            value.lo = in_value.lo + 32w1;
        }
    };
    @name(".vpp6_alu") DirectRegisterAction<vpp6_alu_layout, bit<32>>(vpp6_reg) vpp6_alu = {
        void apply(inout         struct vpp6_alu_layout {
            bit<32> lo;
            bit<32> hi;
        }
value) {
            vpp6_alu_layout in_value;
            in_value = value;
            if (in_value.lo == 32w0xffffffff) 
                value.hi = in_value.hi + 32w1;
            value.lo = in_value.lo + 32w1;
        }
    };
    @name(".e1_action") action e1_action() {
        meta.md.e1_stful = (bit<32>)e1_alu.execute();
    }
    @name(".e2_action") action e2_action() {
        e2_alu.execute();
    }
    @name(".e3_action") action e3_action() {
    }
    @name(".e4_action") action e4_action() {
    }
    @name(".e5_action") action e5_action() {
        meta.md.e5_lpf = e5_lpf.execute(hdr.ethernet.srcAddr);
    }
    @name(".e6_action") action e6_action() {
        meta.md.e6_lpf = e6_lpf.execute(hdr.ethernet.srcAddr);
    }
    @name(".eg_dummy_action") action eg_dummy_action() {
        meta.md.t3_meter = meta.md.t3_meter;
        meta.md.e3_meter = meta.md.e3_meter;
        meta.md.t4_meter = meta.md.t4_meter;
        meta.md.e4_meter = meta.md.e4_meter;
        meta.md.t5_lpf = meta.md.t5_lpf;
        meta.md.e5_lpf = meta.md.e5_lpf;
        meta.md.t6_lpf = meta.md.t6_lpf;
        meta.md.e6_lpf = meta.md.e6_lpf;
        meta.md.mr_clr = meta.md.mr_clr;
        hdr.mrk.hi = 8w0x30;
        hdr.mrk.lo = 8w0x30;
    }
    @name(".nothing") action nothing() {
    }
    @name(".setup_mr_meter_clr") action setup_mr_meter_clr() {
        meta.md.mr_clr[1:0] = ((bit<8>)hdr.ethernet.dstAddr)[1:0];
    }
    @name(".inc_eg_cntr_1") action inc_eg_cntr_1(bit<32> cntr_index) {
        eg_cntr_1.count(cntr_index);
    }
    @name(".inc_eg_cntr_2") action inc_eg_cntr_2(bit<32> cntr_index) {
        eg_cntr_2.count(cntr_index);
    }
    @name(".inc_eg_cntr_3") action inc_eg_cntr_3(bit<32> cntr_index) {
        eg_cntr_3.count(cntr_index);
    }
    @name(".inc_eg_cntr_4") action inc_eg_cntr_4(bit<32> cntr_index) {
        eg_cntr_4.count(cntr_index);
    }
    @name(".mr1_verify_fail") action mr1_verify_fail() {
        meta.md.mr1_fail = 32w1;
    }
    @name(".mr_verify_setup_action") action mr_verify_setup_action() {
        meta.md.t5_lpf_tmp1 = meta.md.t5_lpf >> 4;
        meta.md.t5_lpf_tmp2 = meta.md.t5_lpf >> 8;
        meta.md.e5_lpf_tmp1 = meta.md.e5_lpf >> 4;
        meta.md.e5_lpf_tmp2 = meta.md.e5_lpf >> 8;
        meta.md.t6_lpf_tmp1 = meta.md.t6_lpf >> 4;
        meta.md.t6_lpf_tmp2 = meta.md.t6_lpf >> 8;
        meta.md.e6_lpf_tmp1 = meta.md.e6_lpf >> 4;
        meta.md.e6_lpf_tmp2 = meta.md.e6_lpf >> 8;
    }
    @name(".t1_action") action t1_action() {
        meta.md.t1_stful = (bit<32>)t1_alu.execute();
    }
    @name(".t2_action") action t2_action() {
        t2_alu.execute();
    }
    @name(".t3_action") action t3_action() {
    }
    @name(".t4_action") action t4_action() {
    }
    @name(".t5_action") action t5_action() {
        meta.md.t5_lpf = t5_lpf.execute(hdr.ethernet.srcAddr);
    }
    @name(".t6_action") action t6_action() {
        meta.md.t6_lpf = t6_lpf.execute(hdr.ethernet.srcAddr);
    }
    @name(".vp5_action") action vp5_action() {
        vp5_alu.execute();
    }
    @name(".vp6_action") action vp6_action() {
        vp6_alu.execute();
    }
    @name(".vpp5_action") action vpp5_action() {
        vpp5_alu.execute();
    }
    @name(".vpp6_action") action vpp6_action() {
        vpp6_alu.execute();
    }
    @name(".e1_action") action e1_action_0() {
        e1_cntr.count();
        meta.md.e1_stful = (bit<32>)e1_alu.execute();
    }
    @idletime_precision(1) @stage(0) @pack(1) @ways(4) @random_seed(1027) @name(".e1") table e1 {
        support_timeout = true;
        actions = {
            e1_action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.mrk.lo: exact @name("mrk.lo") ;
            hdr.mrk.hi: exact @name("mrk.hi") ;
        }
        size = 4096;
        counters = e1_cntr;
        default_action = NoAction();
    }
    @name(".e2_action") action e2_action_0() {
        e2_cntr.count();
        e2_alu.execute();
    }
    @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(1) @stage(9) @pack(1) @ways(4) @random_seed(1027) @name(".e2") table e2 {
        support_timeout = true;
        actions = {
            e2_action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.mrk.lo: exact @name("mrk.lo") ;
            hdr.mrk.hi: exact @name("mrk.hi") ;
        }
        size = 4096;
        counters = e2_cntr;
        default_action = NoAction();
    }
    @name(".e3_action") action e3_action_0() {
        e3_meter.read(meta.md.e3_meter);
        e3_cntr.count();
    }
    @stage(10) @pack(1) @ways(4) @random_seed(1027) @name(".e3") table e3 {
        actions = {
            e3_action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.mrk.lo: exact @name("mrk.lo") ;
            hdr.mrk.hi: exact @name("mrk.hi") ;
        }
        size = 4096;
        counters = e3_cntr;
        meters = e3_meter;
        default_action = NoAction();
    }
    @name(".e4_action") action e4_action_0() {
        e4_meter.read(meta.md.e4_meter);
        e4_cntr.count();
    }
    @stage(10) @pack(1) @ways(4) @random_seed(1027) @name(".e4") table e4 {
        actions = {
            e4_action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.mrk.lo: exact @name("mrk.lo") ;
            hdr.mrk.hi: exact @name("mrk.hi") ;
        }
        size = 4096;
        counters = e4_cntr;
        meters = e4_meter;
        default_action = NoAction();
    }
    @name(".e5_action") action e5_action_0() {
        e5_cntr.count();
        meta.md.e5_lpf = e5_lpf.execute(hdr.ethernet.srcAddr);
    }
    @stage(8) @pack(1) @ways(4) @random_seed(1027) @name(".e5") table e5 {
        actions = {
            e5_action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.mrk.lo: exact @name("mrk.lo") ;
            hdr.mrk.hi: exact @name("mrk.hi") ;
        }
        size = 4096;
        counters = e5_cntr;
        default_action = NoAction();
    }
    @name(".e6_action") action e6_action_0() {
        e6_cntr.count();
        meta.md.e6_lpf = e6_lpf.execute(hdr.ethernet.srcAddr);
    }
    @stage(8) @pack(1) @ways(4) @random_seed(1027) @name(".e6") table e6 {
        actions = {
            e6_action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.mrk.lo: exact @name("mrk.lo") ;
            hdr.mrk.hi: exact @name("mrk.hi") ;
        }
        size = 4096;
        counters = e6_cntr;
        default_action = NoAction();
    }
    @stage(11) @name(".eg_dummy") table eg_dummy {
        actions = {
            eg_dummy_action();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @stage(3) @include_idletime(1) @idletime_precision(1) @name(".eg_idle_1") table eg_idle_1 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[15:0]: exact @name("ethernet.srcAddr[15:0]") ;
        }
        size = 131072;
        default_action = NoAction();
    }
    @stage(3) @include_idletime(1) @idletime_precision(1) @name(".eg_idle_2") table eg_idle_2 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[15:0]: exact @name("ethernet.srcAddr[15:0]") ;
        }
        size = 65536;
        default_action = NoAction();
    }
    @stage(3) @include_idletime(1) @idletime_precision(1) @name(".eg_idle_3") table eg_idle_3 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[15:0]: exact @name("ethernet.srcAddr[15:0]") ;
        }
        size = 65536;
        default_action = NoAction();
    }
    @stage(3) @include_idletime(1) @idletime_precision(1) @name(".eg_idle_4") table eg_idle_4 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[15:0]: exact @name("ethernet.srcAddr[15:0]") ;
        }
        size = 65536;
        default_action = NoAction();
    }
    @stage(0) @name(".eg_mr_meter_clr_setup") table eg_mr_meter_clr_setup {
        actions = {
            setup_mr_meter_clr();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @stage(1) @name(".eg_stat_1") table eg_stat_1 {
        actions = {
            inc_eg_cntr_1();
            @defaultonly NoAction();
        }
        key = {
            meta.md.stats_key: exact @name("md.stats_key") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    @stage(1) @name(".eg_stat_2") table eg_stat_2 {
        actions = {
            inc_eg_cntr_2();
            @defaultonly NoAction();
        }
        key = {
            meta.md.stats_key: exact @name("md.stats_key") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    @stage(6) @name(".eg_stat_3") table eg_stat_3 {
        actions = {
            inc_eg_cntr_3();
            @defaultonly NoAction();
        }
        key = {
            meta.md.stats_key[11:0]: exact @name("md.stats_key[11:0]") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    @stage(6) @name(".eg_stat_4") table eg_stat_4 {
        actions = {
            inc_eg_cntr_4();
            @defaultonly NoAction();
        }
        key = {
            meta.md.stats_key[11:0]: exact @name("md.stats_key[11:0]") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    @stage(10) @name(".mr1_verify") table mr1_verify {
        actions = {
            mr1_verify_fail();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @stage(10) @name(".mr_verify_setup") table mr_verify_setup {
        actions = {
            mr_verify_setup_action();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @name(".t1_action") action t1_action_0() {
        t1_cntr.count();
        meta.md.t1_stful = (bit<32>)t1_alu.execute();
    }
    @idletime_precision(1) @stage(0) @name(".t1") table t1 {
        support_timeout = true;
        actions = {
            t1_action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.etherType: ternary @name("ethernet.etherType") ;
        }
        counters = t1_cntr;
        default_action = NoAction();
    }
    @name(".t2_action") action t2_action_0() {
        t2_cntr.count();
        t2_alu.execute();
    }
    @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(1) @stage(9) @name(".t2") table t2 {
        support_timeout = true;
        actions = {
            t2_action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.etherType: ternary @name("ethernet.etherType") ;
        }
        counters = t2_cntr;
        default_action = NoAction();
    }
    @name(".t3_action") action t3_action_0() {
        t3_meter.read(meta.md.t3_meter);
        t3_cntr.count();
    }
    @stage(10) @name(".t3") table t3 {
        actions = {
            t3_action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.etherType: ternary @name("ethernet.etherType") ;
        }
        counters = t3_cntr;
        meters = t3_meter;
        default_action = NoAction();
    }
    @name(".t4_action") action t4_action_0() {
        t4_meter.read(meta.md.t4_meter);
        t4_cntr.count();
    }
    @stage(10) @name(".t4") table t4 {
        actions = {
            t4_action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.etherType: ternary @name("ethernet.etherType") ;
        }
        counters = t4_cntr;
        meters = t4_meter;
        default_action = NoAction();
    }
    @name(".t5_action") action t5_action_0() {
        t5_cntr.count();
        meta.md.t5_lpf = t5_lpf.execute(hdr.ethernet.srcAddr);
    }
    @stage(8) @name(".t5") table t5 {
        actions = {
            t5_action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.etherType: ternary @name("ethernet.etherType") ;
        }
        counters = t5_cntr;
        default_action = NoAction();
    }
    @name(".t6_action") action t6_action_0() {
        t6_cntr.count();
        meta.md.t6_lpf = t6_lpf.execute(hdr.ethernet.srcAddr);
    }
    @stage(8) @name(".t6") table t6 {
        actions = {
            t6_action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.etherType: ternary @name("ethernet.etherType") ;
        }
        counters = t6_cntr;
        default_action = NoAction();
    }
    @name(".nothing") action nothing_0() {
        v3_cntr.count();
    }
    @stage(11) @name(".v3") table v3 {
        actions = {
            nothing_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.etherType: exact @name("ethernet.etherType") ;
        }
        counters = v3_cntr;
        default_action = NoAction();
    }
    @name(".nothing") action nothing_1() {
        v4_cntr.count();
    }
    @stage(11) @name(".v4") table v4 {
        actions = {
            nothing_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.etherType: exact @name("ethernet.etherType") ;
        }
        counters = v4_cntr;
        default_action = NoAction();
    }
    @name(".nothing") action nothing_2() {
        v5_cntr.count();
    }
    @stage(11) @name(".v5") table v5 {
        actions = {
            nothing_2();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.etherType: exact @name("ethernet.etherType") ;
        }
        counters = v5_cntr;
        default_action = NoAction();
    }
    @name(".nothing") action nothing_3() {
        v6_cntr.count();
    }
    @stage(11) @name(".v6") table v6 {
        actions = {
            nothing_3();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.etherType: exact @name("ethernet.etherType") ;
        }
        counters = v6_cntr;
        default_action = NoAction();
    }
    @stage(11) @name(".vp5") table vp5 {
        actions = {
            vp5_action();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.etherType: exact @name("ethernet.etherType") ;
        }
        default_action = NoAction();
    }
    @stage(11) @name(".vp6") table vp6 {
        actions = {
            vp6_action();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.etherType: exact @name("ethernet.etherType") ;
        }
        default_action = NoAction();
    }
    @stage(11) @name(".vpp5") table vpp5 {
        actions = {
            vpp5_action();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.etherType: exact @name("ethernet.etherType") ;
        }
        default_action = NoAction();
    }
    @stage(11) @name(".vpp6") table vpp6 {
        actions = {
            vpp6_action();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.etherType: exact @name("ethernet.etherType") ;
        }
        default_action = NoAction();
    }
    apply {
        t1.apply();
        e1.apply();
        eg_mr_meter_clr_setup.apply();
        if (2w1 == meta.md.count_it || 2w2 == meta.md.count_it || 2w3 == meta.md.count_it || meta.md.m1_drop == 1w1) {
            eg_stat_1.apply();
            eg_stat_2.apply();
        }
        eg_idle_1.apply();
        eg_idle_2.apply();
        eg_idle_3.apply();
        eg_idle_4.apply();
        eg_stat_3.apply();
        eg_stat_4.apply();
        t5.apply();
        e5.apply();
        t6.apply();
        e6.apply();
        t2.apply();
        e2.apply();
        if (meta.md.t1_stful != meta.md.e1_stful) 
            mr1_verify.apply();
        t3.apply();
        e3.apply();
        t4.apply();
        e4.apply();
        mr_verify_setup.apply();
        if (meta.md.t3_meter == meta.md.e3_meter) 
            v3.apply();
        if (meta.md.t4_meter == meta.md.e4_meter) 
            v4.apply();
        if (meta.md.t5_lpf == meta.md.e5_lpf) 
            v5.apply();
        if (meta.md.t6_lpf == meta.md.e6_lpf) 
            v6.apply();
        if (meta.md.t5_lpf_tmp1 == meta.md.e5_lpf_tmp1) 
            vp5.apply();
        if (meta.md.t5_lpf_tmp2 == meta.md.e5_lpf_tmp2) 
            vpp5.apply();
        if (meta.md.t6_lpf_tmp1 == meta.md.e6_lpf_tmp1) 
            vp6.apply();
        if (meta.md.t6_lpf_tmp2 == meta.md.e6_lpf_tmp2) 
            vpp6.apply();
        eg_dummy.apply();
    }
}

@name(".mrk_hi_reg") register<bit<16>>(32w1024) mrk_hi_reg;

@name(".mrk_lo_reg") register<bit<16>>(32w1024) mrk_lo_reg;

@name(".sel_res_reg") register<bit<16>>(32w64) sel_res_reg;

@name(".sel_tbl_reg") register<bit<1>>(32w131072) sel_tbl_reg;

struct stats_key_alu1_layout {
    bit<32> lo;
    bit<32> hi;
}

@name(".stats_key_reg") register<stats_key_alu1_layout>(32w2048) stats_key_reg;
#include <tofino/p4_14_prim.p4>

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".ig_m1_cntr") direct_counter(CounterType.bytes) ig_m1_cntr;
    @lrt_enable(1) @name(".ig_cntr_1") @min_width(32) counter(32w32768, CounterType.packets_and_bytes) ig_cntr_1;
    @lrt_enable(1) @name(".ig_cntr_2") @min_width(32) counter(32w4096, CounterType.packets_and_bytes) ig_cntr_2;
    @name(".ig_cntr_3") counter(32w16384, CounterType.packets_and_bytes) ig_cntr_3;
    @name(".ig_cntr_4") counter(32w2048, CounterType.packets) ig_cntr_4;
    @meter_per_flow_enable(1) @meter_pre_color_aware_per_flow_enable(1) @meter_sweep_interval(0) @name(".m1") meter(32w20480, MeterType.bytes) m1;
    @name(".sel_res_alu") RegisterAction<bit<16>, bit<32>, bit<16>>(sel_res_reg) sel_res_alu = {
        void apply(inout bit<16> value) {
            bit<16> in_value;
            in_value = value;
            value = (bit<16>)hdr.ig_intr_md_for_tm.ucast_egress_port;
        }
    };
    @name(".set_mrk_hi_alu") RegisterAction<bit<16>, bit<32>, bit<16>>(mrk_hi_reg) set_mrk_hi_alu = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = 16w0;
            bit<16> in_value;
            in_value = value;
            value = meta.md.etherType_hi;
            rv = value;
        }
    };
    @name(".set_mrk_lo_alu") RegisterAction<bit<16>, bit<32>, bit<16>>(mrk_lo_reg) set_mrk_lo_alu = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = 16w0;
            bit<16> in_value;
            in_value = value;
            value = hdr.ethernet.etherType & 16w0xff;
            rv = value;
        }
    };
    @name(".stateful_selection_alu") @reg("sel_tbl_reg") selector_action(sel_tbl_ap) stateful_selection_alu = {
        void apply(inout bit<1> value) {
            bit<1> in_value;
            in_value = value;
            value = 1w0;
        }
    };
    @initial_register_lo_value(100) @name(".stats_key_alu1") RegisterAction<stats_key_alu1_layout, bit<32>, bit<32>>(stats_key_reg) stats_key_alu1 = {
        void apply(inout         struct stats_key_alu1_layout {
            bit<32> lo;
            bit<32> hi;
        }
value, out bit<32> rv) {
            rv = 32w0;
            stats_key_alu1_layout in_value;
            in_value = value;
            rv = in_value.lo;
            if (in_value.hi < 32w2) 
                value.hi = in_value.hi + 32w1;
            if (in_value.hi >= 32w2) 
                value.hi = 32w0;
            if (in_value.hi >= 32w2 && in_value.lo < 32w2099) 
                value.lo = in_value.lo + 32w1;
            if (in_value.lo >= 32w2099) 
                value.lo = 32w100;
        }
    };
    @name(".stats_key_alu3") RegisterAction<stats_key_alu1_layout, bit<32>, bit<32>>(stats_key_reg) stats_key_alu3 = {
        void apply(inout         struct stats_key_alu1_layout {
            bit<32> lo;
            bit<32> hi;
        }
value, out bit<32> rv) {
            rv = 32w0;
            stats_key_alu1_layout in_value;
            in_value = value;
            rv = in_value.lo;
            if (in_value.hi < 32w2) 
                value.hi = in_value.hi + 32w1;
            if (in_value.hi >= 32w2) 
                value.hi = 32w0;
            if (in_value.hi >= 32w2 && in_value.lo < 32w11) 
                value.lo = in_value.lo + 32w1;
            if (in_value.lo >= 32w11) 
                value.lo = 32w0;
        }
    };
    @name(".set_dest") action set_dest() {
        hdr.ig_intr_md_for_tm.ucast_egress_port = hdr.ig_intr_md.ingress_port;
        meta.md.etherType_hi = hdr.ethernet.etherType >> 8;
    }
    @name(".update_stful_sel_tbl") action update_stful_sel_tbl(bit<32> index) {
        stateful_selection_alu.execute(index);
    }
    @name(".nothing") action nothing() {
    }
    @name(".m1") action m1_0(bit<32> index) {
        execute_meter_with_color<meter, bit<32>, bit<8>>(m1, index, meta.md.m1_clr, meta.md.m1_clr);
        meta.md.m1_idx = index;
    }
    @name(".set_m1_clr") action set_m1_clr() {
        meta.md.m1_clr[1:0] = ((bit<8>)hdr.ethernet.etherType)[1:0];
    }
    @name(".mark_meter_resubmit") action mark_meter_resubmit() {
        meta.md.resubmit_for_meter_test = 1w1;
    }
    @name(".m1_tag_for_drop") action m1_tag_for_drop() {
        meta.md.m1_drop = 1w1;
    }
    @name(".inc_ig_cntr_1") action inc_ig_cntr_1(bit<32> cntr_index) {
        ig_cntr_1.count(cntr_index);
    }
    @name(".inc_ig_cntr_2") action inc_ig_cntr_2(bit<32> cntr_index) {
        ig_cntr_2.count(cntr_index);
    }
    @name(".inc_ig_cntr_3") action inc_ig_cntr_3(bit<32> cntr_index) {
        ig_cntr_3.count(cntr_index);
    }
    @name(".inc_ig_cntr_4") action inc_ig_cntr_4(bit<32> cntr_index) {
        ig_cntr_4.count(cntr_index);
    }
    @name(".do_resubmit") action do_resubmit() {
        resubmit<tuple<>>({  });
    }
    @name(".log_egr_port") action log_egr_port() {
        {
            bit<6> temp;
            hash<bit<6>, bit<6>, tuple<bit<48>>, bit<7>>(temp, HashAlgorithm.identity, 6w0, { hdr.ethernet.dstAddr }, 7w64);
            sel_res_alu.execute((bit<32>)temp);
        }
    }
    @name(".set_egr_port") action set_egr_port(bit<9> p) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = p;
    }
    @name(".do_set_mrk_hi") action do_set_mrk_hi() {
        hdr.mrk.hi = (bit<8>)set_mrk_hi_alu.execute(32w0);
    }
    @name(".do_set_mrk_lo") action do_set_mrk_lo() {
        hdr.mrk.lo = (bit<8>)set_mrk_lo_alu.execute(32w0);
    }
    @name(".do_set_stats_key1") action do_set_stats_key1() {
        meta.md.stats_key = stats_key_alu1.execute(32w0);
    }
    @name(".do_set_stats_key2") action do_set_stats_key2() {
        meta.md.stats_key = 32w0xffffffff;
    }
    @name(".do_set_stats_key3") action do_set_stats_key3() {
        meta.md.stats_key = stats_key_alu3.execute(32w1);
    }
    @command_line("--no-dead-code-elimination") @name(".dest") table dest {
        actions = {
            set_dest();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @stage(5) @name(".dummy_tbl") table dummy_tbl {
        actions = {
            update_stful_sel_tbl();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.dstAddr: exact @name("ethernet.dstAddr") ;
        }
        size = 1;
        default_action = NoAction();
    }
    @stage(2) @include_idletime(1) @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(1) @name(".ig_idle_1") table ig_idle_1 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[13:0]: exact @name("ethernet.srcAddr[13:0]") ;
        }
        size = 18432;
        default_action = NoAction();
    }
    @stage(2) @include_idletime(1) @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(0) @name(".ig_idle_10") table ig_idle_10 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[13:0]: ternary @name("ethernet.srcAddr[13:0]") ;
        }
        size = 1536;
        default_action = NoAction();
    }
    @stage(2) @include_idletime(1) @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(0) @name(".ig_idle_11") table ig_idle_11 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[13:0]: ternary @name("ethernet.srcAddr[13:0]") ;
        }
        size = 1536;
        default_action = NoAction();
    }
    @stage(2) @include_idletime(1) @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(0) @name(".ig_idle_12") table ig_idle_12 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[13:0]: ternary @name("ethernet.srcAddr[13:0]") ;
        }
        size = 1536;
        default_action = NoAction();
    }
    @stage(2) @include_idletime(1) @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(0) @name(".ig_idle_13") table ig_idle_13 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[13:0]: ternary @name("ethernet.srcAddr[13:0]") ;
        }
        size = 1536;
        default_action = NoAction();
    }
    @stage(2) @include_idletime(1) @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(0) @name(".ig_idle_14") table ig_idle_14 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[13:0]: ternary @name("ethernet.srcAddr[13:0]") ;
        }
        size = 1536;
        default_action = NoAction();
    }
    @stage(2) @include_idletime(1) @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(0) @name(".ig_idle_15") table ig_idle_15 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[13:0]: ternary @name("ethernet.srcAddr[13:0]") ;
        }
        size = 1536;
        default_action = NoAction();
    }
    @stage(2) @include_idletime(1) @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(0) @name(".ig_idle_16") table ig_idle_16 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[15:0]: ternary @name("ethernet.srcAddr[15:0]") ;
        }
        size = 1536;
        default_action = NoAction();
    }
    @stage(2) @include_idletime(1) @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(1) @name(".ig_idle_2") table ig_idle_2 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[13:0]: exact @name("ethernet.srcAddr[13:0]") ;
        }
        size = 8192;
        default_action = NoAction();
    }
    @stage(2) @include_idletime(1) @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(1) @name(".ig_idle_3") table ig_idle_3 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[13:0]: exact @name("ethernet.srcAddr[13:0]") ;
        }
        size = 8192;
        default_action = NoAction();
    }
    @stage(2) @include_idletime(1) @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(1) @name(".ig_idle_4") table ig_idle_4 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[13:0]: exact @name("ethernet.srcAddr[13:0]") ;
        }
        size = 8192;
        default_action = NoAction();
    }
    @stage(2) @include_idletime(1) @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(1) @name(".ig_idle_5") table ig_idle_5 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[13:0]: exact @name("ethernet.srcAddr[13:0]") ;
        }
        size = 8192;
        default_action = NoAction();
    }
    @stage(2) @include_idletime(1) @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(1) @name(".ig_idle_6") table ig_idle_6 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[13:0]: exact @name("ethernet.srcAddr[13:0]") ;
        }
        size = 8192;
        default_action = NoAction();
    }
    @stage(2) @include_idletime(1) @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(1) @name(".ig_idle_7") table ig_idle_7 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[13:0]: exact @name("ethernet.srcAddr[13:0]") ;
        }
        size = 8192;
        default_action = NoAction();
    }
    @stage(2) @include_idletime(1) @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(1) @name(".ig_idle_8") table ig_idle_8 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[13:0]: exact @name("ethernet.srcAddr[13:0]") ;
        }
        size = 8192;
        default_action = NoAction();
    }
    @stage(2) @include_idletime(1) @idletime_precision(3) @idletime_two_way_notification(1) @idletime_per_flow_idletime(0) @name(".ig_idle_9") table ig_idle_9 {
        support_timeout = true;
        actions = {
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr[13:0]: ternary @name("ethernet.srcAddr[13:0]") ;
        }
        size = 1536;
        default_action = NoAction();
    }
    @stage(4) @name(".ig_m1") table ig_m1 {
        actions = {
            m1_0();
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.dstAddr[47:32]: exact @name("ethernet.dstAddr[47:32]") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".nothing") action nothing_4() {
        ig_m1_cntr.count();
    }
    @name(".ig_m1_cnt") table ig_m1_cnt {
        actions = {
            nothing_4();
            @defaultonly NoAction();
        }
        key = {
            meta.md.m1_idx: exact @name("md.m1_idx") ;
            meta.md.m1_clr: exact @name("md.m1_clr") ;
        }
        size = 1024;
        counters = ig_m1_cntr;
        default_action = NoAction();
    }
    @name(".ig_m1_color") table ig_m1_color {
        actions = {
            set_m1_clr();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @name(".ig_meter_resubmit") table ig_meter_resubmit {
        actions = {
            mark_meter_resubmit();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @name(".ig_meter_test_discard") table ig_meter_test_discard {
        actions = {
            m1_tag_for_drop();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @stage(1) @name(".ig_stat_1") table ig_stat_1 {
        actions = {
            inc_ig_cntr_1();
            @defaultonly NoAction();
        }
        key = {
            meta.md.stats_key: exact @name("md.stats_key") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    @stage(1) @name(".ig_stat_2") table ig_stat_2 {
        actions = {
            inc_ig_cntr_2();
            @defaultonly NoAction();
        }
        key = {
            meta.md.stats_key: exact @name("md.stats_key") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    @stage(6) @name(".ig_stat_3") table ig_stat_3 {
        actions = {
            inc_ig_cntr_3();
            @defaultonly NoAction();
        }
        key = {
            meta.md.stats_key[11:0]: exact @name("md.stats_key[11:0]") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    @stage(6) @name(".ig_stat_4") table ig_stat_4 {
        actions = {
            inc_ig_cntr_4();
            @defaultonly NoAction();
        }
        key = {
            meta.md.stats_key[11:0]: exact @name("md.stats_key[11:0]") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    @name(".resubmit_2_tbl") table resubmit_2_tbl {
        actions = {
            do_resubmit();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @name(".sel_res") table sel_res {
        actions = {
            log_egr_port();
            nothing();
        }
        key = {
            hdr.ethernet.dstAddr: ternary @name("ethernet.dstAddr") ;
        }
        size = 64;
        default_action = nothing();
    }
    @action_default_only("nothing") @stage(5) @name(".sel_tbl") table sel_tbl {
        actions = {
            set_egr_port();
            nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.dstAddr  : ternary @name("ethernet.dstAddr") ;
            hdr.ethernet.dstAddr  : selector @name("ethernet.dstAddr") ;
            hdr.ethernet.etherType: selector @name("ethernet.etherType") ;
        }
        size = 1;
        implementation = sel_tbl_ap;
        default_action = NoAction();
    }
    @stage(1) @name(".set_mrk_hi") table set_mrk_hi {
        actions = {
            do_set_mrk_hi();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @stage(0) @name(".set_mrk_lo") table set_mrk_lo {
        actions = {
            do_set_mrk_lo();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @name(".set_stats_key1") table set_stats_key1 {
        actions = {
            do_set_stats_key1();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @name(".set_stats_key2") table set_stats_key2 {
        actions = {
            do_set_stats_key2();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @name(".set_stats_key3") table set_stats_key3 {
        actions = {
            do_set_stats_key3();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @name(".stats_resubmit") table stats_resubmit {
        actions = {
            nothing();
            do_resubmit();
        }
        key = {
            hdr.ethernet.etherType: ternary @name("ethernet.etherType") ;
        }
        default_action = nothing();
    }
    apply {
        dest.apply();
        set_mrk_lo.apply();
        if (1w0 == hdr.ig_intr_md.resubmit_flag && 1w0 == meta.md.drop_it) 
            stats_resubmit.apply();
        if (2w1 == meta.md.count_it) 
            set_stats_key1.apply();
        else 
            if (2w2 == meta.md.count_it) 
                set_stats_key2.apply();
            else 
                if (2w3 == meta.md.count_it) 
                    set_stats_key3.apply();
        if (32w1 == hdr.ethernet.srcAddr & 32w1 && 1w0 == hdr.ig_intr_md.resubmit_flag && 1w0 == meta.md.drop_it) 
            ig_meter_resubmit.apply();
        set_mrk_hi.apply();
        if (2w1 == meta.md.count_it || 2w2 == meta.md.count_it || 2w3 == meta.md.count_it) {
            ig_stat_1.apply();
            ig_stat_2.apply();
        }
        ig_idle_1.apply();
        ig_idle_2.apply();
        ig_idle_3.apply();
        ig_idle_4.apply();
        ig_idle_5.apply();
        ig_idle_6.apply();
        ig_idle_7.apply();
        ig_idle_8.apply();
        ig_idle_9.apply();
        ig_idle_10.apply();
        ig_idle_11.apply();
        ig_idle_12.apply();
        ig_idle_13.apply();
        ig_idle_14.apply();
        ig_idle_15.apply();
        ig_idle_16.apply();
        if (1w1 == meta.md.resubmit_for_meter_test && 1w0 == hdr.ig_intr_md.resubmit_flag) 
            resubmit_2_tbl.apply();
        else {
            ig_m1_color.apply();
            if (ig_m1.apply().hit) {
                ig_m1_cnt.apply();
                if (meta.md.m1_clr == 8w3) 
                    ig_meter_test_discard.apply();
            }
        }
        if (1w0 == meta.md.dummy) 
            if (sel_tbl.apply().hit) 
                sel_res.apply();
            else {
                ig_stat_3.apply();
                ig_stat_4.apply();
            }
        else 
            dummy_tbl.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<move_reg_key_t>(hdr.mrk);
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

