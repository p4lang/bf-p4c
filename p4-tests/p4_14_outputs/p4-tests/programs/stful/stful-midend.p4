#include <core.p4>
#include <v1model.p4>

struct user_metadata_t {
    bit<16> ifid;
    bit<16> egr_ifid;
    bit<48> timestamp;
    int<32> offset;
    bit<1>  bf_tmp_1;
    bit<1>  bf_tmp_2;
    bit<1>  bf_tmp_3;
    bit<8>  flowlet_hash_input;
    bit<16> nh_id;
    bit<15> flowlet_temp;
    bit<32> flowlet_ts;
    bit<17> lag_tbl_bit_index;
    bit<17> ecmp_tbl_bit_index;
    bit<1>  pkt_gen_pkt;
    bit<1>  recirc_pkt;
    bit<1>  one_bit_val_1;
    bit<1>  one_bit_val_2;
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
    bit<48> dmac;
    bit<48> smac;
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

header ipv4_t {
    bit<4>  ver;
    bit<4>  len;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> id;
    bit<3>  flags;
    bit<13> offset;
    bit<8>  ttl;
    bit<8>  proto;
    bit<16> csum;
    bit<32> sip;
    bit<32> dip;
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

header recirc_header_t {
    bit<4>  tag;
    bit<4>  rtype;
    bit<8>  pad;
    bit<16> key;
}

header tcp_t {
    bit<16> sPort;
    bit<16> dPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> sPort;
    bit<16> dPort;
    bit<16> hdr_length;
    bit<16> checksum;
}

struct metadata {
    @pa_solitary("ingress", "md.flowlet_temp") @name(".md") 
    user_metadata_t md;
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
    @name(".ipv4") 
    ipv4_t                                         ipv4;
    @name(".pktgen_generic") 
    pktgen_generic_header_t                        pktgen_generic;
    @name(".pktgen_port_down") 
    pktgen_port_down_header_t                      pktgen_port_down;
    @name(".pktgen_recirc") 
    pktgen_recirc_header_t                         pktgen_recirc;
    @name(".pktgen_timer") 
    pktgen_timer_header_t                          pktgen_timer;
    @name(".recirc_hdr") 
    recirc_header_t                                recirc_hdr;
    @name(".tcp") 
    tcp_t                                          tcp;
    @name(".udp") 
    udp_t                                          udp;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<8> tmp_7;
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.ethertype) {
            16w0x800: parse_ipv4;
            default: noMatch;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition select(hdr.ipv4.proto) {
            8w6: parse_tcp;
            8w17: parse_udp;
            default: noMatch;
        }
    }
    @name(".parse_pkt_gen_hw_clr") state parse_pkt_gen_hw_clr {
        packet.extract<pktgen_generic_header_t>(hdr.pktgen_generic);
        meta.md.pkt_gen_pkt = 1w1;
        transition accept;
    }
    @name(".parse_pkt_gen_port_down") state parse_pkt_gen_port_down {
        packet.extract<pktgen_port_down_header_t>(hdr.pktgen_port_down);
        meta.md.pkt_gen_pkt = 1w1;
        transition accept;
    }
    @name(".parse_pkt_gen_recirc") state parse_pkt_gen_recirc {
        packet.extract<pktgen_recirc_header_t>(hdr.pktgen_recirc);
        meta.md.pkt_gen_pkt = 1w1;
        transition accept;
    }
    @name(".parse_recirc_pkt") state parse_recirc_pkt {
        packet.extract<recirc_header_t>(hdr.recirc_hdr);
        meta.md.recirc_pkt = 1w1;
        transition select(hdr.recirc_hdr.rtype) {
            4w1: parse_pkt_gen_port_down;
            4w2: parse_recirc_trigger_pkt;
            default: accept;
        }
    }
    @name(".parse_recirc_trigger_pkt") state parse_recirc_trigger_pkt {
        transition parse_ethernet;
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract<tcp_t>(hdr.tcp);
        transition accept;
    }
    @name(".parse_udp") state parse_udp {
        packet.extract<udp_t>(hdr.udp);
        transition accept;
    }
    @name(".start") state start {
        tmp_7 = packet.lookahead<bit<8>>();
        transition select(tmp_7[7:0]) {
            8w0x1 &&& 8w0xe7: parse_pkt_gen_port_down;
            8w0x2 &&& 8w0xe7: parse_pkt_gen_recirc;
            8w0x3 &&& 8w0xe7: parse_pkt_gen_hw_clr;
            8w0xf0 &&& 8w0xf0: parse_recirc_pkt;
            default: parse_ethernet;
        }
    }
    state noMatch {
        verify(false, error.NoMatch);
        transition reject;
    }
}

@name(".lag_ap") @mode("resilient") action_selector(HashAlgorithm.random, 32w4096, 32w66) lag_ap;

@name(".next_hop_ecmp_ap") @mode("fair") action_selector(HashAlgorithm.crc32, 32w4096, 32w29) next_hop_ecmp_ap;

@name(".bloom_filter_1") register<bit<1>>(32w262144) bloom_filter_1;

@name(".bloom_filter_2") register<bit<1>>(32w262144) bloom_filter_2;

@name(".bloom_filter_3") register<bit<1>>(32w262144) bloom_filter_3;

@name(".next_hop_ecmp_reg") register<bit<1>>(32w131072) next_hop_ecmp_reg;

@name(".lag_reg") register<bit<1>>(32w131072) lag_reg;

@name(".ifid_cntr") register<bit<16>>(32w0) ifid_cntr;

@name(".ob1") register<bit<1>>(32w1000) ob1;

@name(".ob2") register<bit<1>>(32w1000) ob2;

struct counter_alu_layout {
    int<32> lo;
    int<32> hi;
}

@name(".port_cntr") register<counter_alu_layout>(32w0) port_cntr;

@name(".sampling_cntr") register<bit<32>>(32w143360) sampling_cntr;

@name(".scratch") register<bit<16>>(32w4096) scratch;

@name(".two_instr_no_idx_reg") register<bit<8>>(32w512) two_instr_no_idx_reg;

struct tuple_0 {
    bit<8>  field;
    bit<32> field_0;
    bit<32> field_1;
    bit<16> field_2;
    bit<16> field_3;
}

struct tuple_1 {
    bit<16> field_4;
    bit<16> field_5;
}

struct tuple_2 {
    bit<17> field_6;
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<18> temp;
    bit<18> temp_0;
    bit<18> temp_1;
    bit<1> tmp_8;
    bit<1> tmp_9;
    bit<1> tmp_10;
    bit<1> tmp_11;
    bit<1> tmp_12;
    bit<32> tmp_13;
    bool tmp_14;
    bit<18> _pgen_pass_1_ctrl_flow_temp_3;
    bit<18> _pgen_pass_1_ctrl_flow_temp_4;
    bit<18> _pgen_pass_1_ctrl_flow_temp_5;
    bit<17> _pgen_pass_1_ctrl_flow_temp_6;
    bit<17> _pgen_pass_2_ctrl_flow_temp_0;
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_10() {
    }
    @name(".NoAction") action NoAction_11() {
    }
    @name(".NoAction") action NoAction_12() {
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
    @name(".bloom_filter_alu_1") RegisterAction<bit<1>, bit<1>>(bloom_filter_1) bloom_filter_alu_1 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            value = 1w1;
            rv = 1w0;
        }
    };
    @name(".bloom_filter_alu_2") RegisterAction<bit<1>, bit<1>>(bloom_filter_2) bloom_filter_alu_2 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            value = 1w1;
            rv = 1w0;
        }
    };
    @name(".bloom_filter_alu_3") RegisterAction<bit<1>, bit<1>>(bloom_filter_3) bloom_filter_alu_3 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            value = 1w1;
            rv = 1w0;
        }
    };
    @name(".counter_alu") RegisterAction<counter_alu_layout, int<32>>(port_cntr) counter_alu = {
        void apply(inout         struct counter_alu_layout {
            int<32> lo;
            int<32> hi;
        }
value) {
            counter_alu_layout in_value_2;
            in_value_2.lo = value.lo;
            in_value_2.hi = value.hi;
            if (value.lo < 32s0 && value.lo + meta.md.offset >= 32s0) 
                value.hi = value.hi + 32s1;
            if (value.lo >= 32s0 && value.lo + meta.md.offset < 32s0) 
                value.hi = in_value_2.hi + -32s1;
            value.lo = value.lo + meta.md.offset;
        }
    };
    @name(".ifid_cntr_alu") RegisterAction<int<16>, int<16>>(ifid_cntr) ifid_cntr_alu = {
        void apply(inout int<16> value) {
            value = value + (int<16>)(bit<16>)hdr.ipv4.ttl;
        }
    };
    @name(".one_bit_alu_1") RegisterAction<bit<1>, bit<1>>(ob1) one_bit_alu_1 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            rv = value;
        }
    };
    @name(".one_bit_alu_2") RegisterAction<bit<1>, bit<1>>(ob2) one_bit_alu_2 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            rv = value;
        }
    };
    @initial_register_lo_value(1) @name(".sampling_alu") RegisterAction<bit<32>, bit<32>>(sampling_cntr) sampling_alu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            bit<32> in_value_20;
            rv = 32w0;
            in_value_20 = value;
            if (value >= 32w10) 
                value = 32w1;
            if (in_value_20 < 32w10) 
                value = in_value_20 + 32w1;
            if (in_value_20 >= 32w10 || hdr.ig_intr_md_for_tm.copy_to_cpu != 1w0) 
                rv = 32w1;
        }
    };
    @name(".scratch_alu_add") RegisterAction<bit<16>, bit<16>>(scratch) scratch_alu_add = {
        void apply(inout bit<16> value) {
            value = value + meta.md.nh_id;
        }
    };
    @name(".scratch_alu_invert") RegisterAction<bit<16>, bit<16>>(scratch) scratch_alu_invert = {
        void apply(inout bit<16> value) {
            value = ~value;
        }
    };
    @name(".scratch_alu_sub") RegisterAction<bit<16>, bit<16>>(scratch) scratch_alu_sub = {
        void apply(inout bit<16> value) {
            value = meta.md.nh_id - value;
        }
    };
    @name(".scratch_alu_zero") RegisterAction<bit<16>, bit<16>>(scratch) scratch_alu_zero = {
        void apply(inout bit<16> value) {
            value = 16w0;
        }
    };
    @name(".two_instr_no_idx_alu_1") RegisterAction<bit<8>, bit<8>>(two_instr_no_idx_reg) two_instr_no_idx_alu_1 = {
        void apply(inout bit<8> value) {
            value = value + 8w9;
        }
    };
    @name(".two_instr_no_idx_alu_2") RegisterAction<bit<8>, bit<8>>(two_instr_no_idx_reg) two_instr_no_idx_alu_2 = {
        void apply(inout bit<8> value) {
            value = 8w17 - value;
        }
    };
    @name(".check_bloom_filter_1") action check_bloom_filter() {
        hash<bit<18>, bit<18>, tuple_0, bit<19>>(temp, HashAlgorithm.random, 18w0, { hdr.ipv4.proto, hdr.ipv4.sip, hdr.ipv4.dip, hdr.tcp.sPort, hdr.tcp.dPort }, 19w262144);
        tmp_8 = bloom_filter_alu_1.execute((bit<32>)temp);
        meta.md.bf_tmp_1 = tmp_8;
    }
    @name(".check_bloom_filter_2") action check_bloom_filter_0() {
        hash<bit<18>, bit<18>, tuple_0, bit<19>>(temp_0, HashAlgorithm.random, 18w0, { hdr.ipv4.proto, hdr.ipv4.sip, hdr.ipv4.dip, hdr.tcp.sPort, hdr.tcp.dPort }, 19w262144);
        tmp_9 = bloom_filter_alu_2.execute((bit<32>)temp_0);
        meta.md.bf_tmp_2 = tmp_9;
    }
    @name(".check_bloom_filter_3") action check_bloom_filter_4() {
        hash<bit<18>, bit<18>, tuple_0, bit<19>>(temp_1, HashAlgorithm.random, 18w0, { hdr.ipv4.proto, hdr.ipv4.sip, hdr.ipv4.dip, hdr.tcp.sPort, hdr.tcp.dPort }, 19w262144);
        tmp_10 = bloom_filter_alu_3.execute((bit<32>)temp_1);
        meta.md.bf_tmp_3 = tmp_10;
    }
    @name(".bloom_filter_mark_sample") action bloom_filter_mark_sample_0() {
        hdr.ig_intr_md_for_tm.copy_to_cpu = 1w1;
    }
    @name(".set_egr_port") action set_egr_port_0(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".set_dest") action set_dest_0(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
        counter_alu.execute();
    }
    @name(".set_flowlet_hash_and_ts") action set_flowlet_hash_and_ts_0() {
        hash<bit<15>, bit<15>, tuple_0, bit<30>>(meta.md.flowlet_temp, HashAlgorithm.crc16, 15w0, { hdr.ipv4.proto, hdr.ipv4.sip, hdr.ipv4.dip, hdr.tcp.sPort, hdr.tcp.dPort }, 30w32768);
        meta.md.flowlet_ts = (bit<32>)meta.md.timestamp;
    }
    @name(".set_ifid_based_params") action set_ifid_based_params_0(bit<48> ts, int<32> offset) {
        ifid_cntr_alu.execute();
        meta.md.timestamp = ts;
        meta.md.offset = offset;
    }
    @name(".drop_it") action drop_it_0() {
        ifid_cntr_alu.execute();
        mark_to_drop();
    }
    @name(".set_ifid") action set_ifid_0(bit<16> ifid) {
        meta.md.ifid = ifid;
    }
    @name(".set_next_hop") action set_next_hop_0(bit<16> nh) {
        meta.md.nh_id = nh;
    }
    @name(".set_next_hop") action set_next_hop_2(bit<16> nh) {
        meta.md.nh_id = nh;
    }
    @name(".set_ecmp") action set_ecmp_0(bit<16> ecmp_id) {
        meta.md.nh_id = ecmp_id;
    }
    @name(".set_egr_ifid") action set_egr_ifid_0(bit<16> ifid) {
        meta.md.egr_ifid = ifid;
    }
    @name(".scratch_add") action scratch_add_0(bit<32> index, bit<16> ifid) {
        meta.md.egr_ifid = ifid;
        scratch_alu_add.execute(index);
    }
    @name(".scratch_sub") action scratch_sub_0(bit<32> index, bit<16> ifid) {
        meta.md.egr_ifid = ifid;
        scratch_alu_sub.execute(index);
    }
    @name(".scratch_zero") action scratch_zero_0(bit<32> index, bit<16> ifid) {
        meta.md.egr_ifid = ifid;
        scratch_alu_zero.execute(index);
    }
    @name(".scratch_invert") action scratch_invert_0(bit<32> index, bit<16> ifid) {
        meta.md.egr_ifid = ifid;
        scratch_alu_invert.execute(index);
    }
    @name(".next_hop_down") action next_hop_down_0(bit<16> mgid) {
        hdr.recirc_hdr.setValid();
        hdr.recirc_hdr.tag = 4w0xf;
        hdr.recirc_hdr.rtype = 4w2;
        hdr.recirc_hdr.pad = 8w0;
        hdr.recirc_hdr.key = meta.md.nh_id;
        hdr.ig_intr_md_for_tm.mcast_grp_b = mgid;
    }
    @name(".run_one_bit_read_1") action run_one_bit_read() {
        tmp_11 = one_bit_alu_1.execute(32w1);
        meta.md.one_bit_val_1 = tmp_11;
    }
    @name(".run_one_bit_read_2") action run_one_bit_read_0() {
        tmp_12 = one_bit_alu_2.execute(32w2);
        meta.md.one_bit_val_2 = tmp_12;
    }
    @name(".sample") action sample_0(bit<32> index) {
        tmp_13 = sampling_alu.execute(index);
        hdr.ig_intr_md_for_tm.copy_to_cpu = (bit<1>)tmp_13;
    }
    @name(".no_sample") action no_sample_0() {
    }
    @name(".add_9") action add() {
        two_instr_no_idx_alu_1.execute((bit<32>)hdr.ig_intr_md.ingress_port);
        hdr.ig_intr_md_for_tm.drop_ctl[0:0] = 1w0;
        hdr.ig_intr_md_for_tm.ucast_egress_port = hdr.ig_intr_md.ingress_port;
    }
    @name(".rsub_17") action rsub() {
        two_instr_no_idx_alu_2.execute((bit<32>)hdr.ig_intr_md.ingress_port);
        hdr.ig_intr_md_for_tm.drop_ctl[0:0] = 1w0;
        hdr.ig_intr_md_for_tm.ucast_egress_port = hdr.ig_intr_md.ingress_port;
    }
    @name(".do_undrop") action do_undrop_0() {
        hdr.ig_intr_md_for_tm.drop_ctl[0:0] = 1w0;
        hdr.ig_intr_md_for_tm.ucast_egress_port = hdr.ig_intr_md.ingress_port;
    }
    @stage(0) @name(".bloom_filter_1") table bloom_filter_1_0 {
        actions = {
            check_bloom_filter();
        }
        size = 1;
        default_action = check_bloom_filter();
    }
    @stage(1) @name(".bloom_filter_2") table bloom_filter_2_0 {
        actions = {
            check_bloom_filter_0();
        }
        size = 1;
        default_action = check_bloom_filter_0();
    }
    @stage(1) @name(".bloom_filter_3") table bloom_filter_3_0 {
        actions = {
            check_bloom_filter_4();
        }
        size = 1;
        default_action = check_bloom_filter_4();
    }
    @name(".bloom_filter_sample") table bloom_filter_sample {
        actions = {
            bloom_filter_mark_sample_0();
        }
        size = 1;
        default_action = bloom_filter_mark_sample_0();
    }
    @seletor_num_max_groups(128) @selector_max_group_size(1200) @name(".egr_ifid") table egr_ifid_1 {
        actions = {
            set_egr_port_0();
            @defaultonly NoAction_0();
        }
        key = {
            meta.md.egr_ifid           : exact @name("md.egr_ifid") ;
            hdr.ipv4.proto             : selector @name("ipv4.proto") ;
            hdr.ipv4.sip               : selector @name("ipv4.sip") ;
            hdr.ipv4.dip               : selector @name("ipv4.dip") ;
            hdr.tcp.sPort              : selector @name("tcp.sPort") ;
            hdr.tcp.dPort              : selector @name("tcp.dPort") ;
            hdr.ig_intr_md.ingress_port: selector @name("ig_intr_md.ingress_port") ;
        }
        size = 16384;
        implementation = lag_ap;
        default_action = NoAction_0();
    }
    @name(".egr_port") table egr_port {
        actions = {
            set_dest_0();
            @defaultonly NoAction_10();
        }
        key = {
            meta.md.egr_ifid: ternary @name("md.egr_ifid") ;
        }
        size = 16384;
        default_action = NoAction_10();
    }
    @name(".flowlet_prepare") table flowlet_prepare {
        actions = {
            set_flowlet_hash_and_ts_0();
        }
        size = 1;
        default_action = set_flowlet_hash_and_ts_0();
    }
    @name(".ifid") table ifid_1 {
        actions = {
            set_ifid_based_params_0();
            drop_it_0();
            @defaultonly NoAction_11();
        }
        key = {
            meta.md.ifid: exact @name("md.ifid") ;
        }
        size = 25000;
        default_action = NoAction_11();
    }
    @pragma("--metadata-overlay", "False") @name(".ing_port") table ing_port {
        actions = {
            set_ifid_0();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 288;
        default_action = set_ifid_0(16w0);
    }
    @name(".ipv4_route") table ipv4_route {
        actions = {
            set_next_hop_0();
            set_ecmp_0();
            @defaultonly NoAction_12();
        }
        key = {
            hdr.ipv4.dip: lpm @name("ipv4.dip") ;
        }
        size = 512;
        default_action = NoAction_12();
    }
    @name(".next_hop") table next_hop {
        actions = {
            set_egr_ifid_0();
            scratch_add_0();
            scratch_sub_0();
            scratch_zero_0();
            scratch_invert_0();
            next_hop_down_0();
            @defaultonly NoAction_13();
        }
        key = {
            meta.md.nh_id: ternary @name("md.nh_id") ;
        }
        size = 4096;
        default_action = NoAction_13();
    }
    @stage(6) @selector_max_group_size(200) @name(".next_hop_ecmp") table next_hop_ecmp {
        actions = {
            set_next_hop_2();
            @defaultonly NoAction_14();
        }
        key = {
            meta.md.nh_id             : exact @name("md.nh_id") ;
            hdr.ipv4.proto            : selector @name("ipv4.proto") ;
            hdr.ipv4.sip              : selector @name("ipv4.sip") ;
            hdr.ipv4.dip              : selector @name("ipv4.dip") ;
            hdr.tcp.sPort             : selector @name("tcp.sPort") ;
            hdr.tcp.dPort             : selector @name("tcp.dPort") ;
            meta.md.flowlet_hash_input: selector @name("md.flowlet_hash_input") ;
        }
        size = 4096;
        implementation = next_hop_ecmp_ap;
        default_action = NoAction_14();
    }
    @name(".one_bit_read_1") table one_bit_read_1 {
        actions = {
            run_one_bit_read();
        }
        size = 1;
        default_action = run_one_bit_read();
    }
    @name(".one_bit_read_2") table one_bit_read_2 {
        actions = {
            run_one_bit_read_0();
        }
        size = 1;
        default_action = run_one_bit_read_0();
    }
    @name(".sip_sampler") table sip_sampler {
        actions = {
            sample_0();
            no_sample_0();
            @defaultonly NoAction_15();
        }
        key = {
            hdr.ipv4.sip: exact @name("ipv4.sip") ;
        }
        size = 1024;
        default_action = NoAction_15();
    }
    @name(".two_instr_no_idx") table two_instr_no_idx {
        actions = {
            add();
            rsub();
            @defaultonly NoAction_16();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 17;
        default_action = NoAction_16();
    }
    @name(".undrop") table undrop {
        actions = {
            do_undrop_0();
        }
        size = 1;
        default_action = do_undrop_0();
    }
    @name(".clr_bloom_filter_alu_1") RegisterAction<bit<1>, bit<1>>(bloom_filter_1) _clr_bloom_filter_alu_2 = {
        void apply(inout bit<1> value) {
            value = 1w0;
        }
    };
    @name(".clr_bloom_filter_alu_2") RegisterAction<bit<1>, bit<1>>(bloom_filter_2) _clr_bloom_filter_alu_3 = {
        void apply(inout bit<1> value) {
            value = 1w0;
        }
    };
    @name(".clr_bloom_filter_alu_3") RegisterAction<bit<1>, bit<1>>(bloom_filter_3) _clr_bloom_filter_alu_4 = {
        void apply(inout bit<1> value) {
            value = 1w0;
        }
    };
    @name(".next_hop_ecmp_alu") selector_action(next_hop_ecmp_ap) _next_hop_ecmp_alu_0 = {
        void apply(inout bit<1> value) {
            value = 1w0;
        }
    };
    @name(".clear_bloom_filter_1") action _clear_bloom_filter() {
        hash<bit<18>, bit<18>, tuple_1, bit<19>>(_pgen_pass_1_ctrl_flow_temp_3, HashAlgorithm.identity, 18w0, { hdr.pktgen_generic.batch_id, hdr.pktgen_generic.packet_id }, 19w262144);
        _clr_bloom_filter_alu_2.execute((bit<32>)_pgen_pass_1_ctrl_flow_temp_3);
    }
    @name(".clear_bloom_filter_2") action _clear_bloom_filter_0() {
        hash<bit<18>, bit<18>, tuple_1, bit<19>>(_pgen_pass_1_ctrl_flow_temp_4, HashAlgorithm.identity, 18w0, { hdr.pktgen_generic.batch_id, hdr.pktgen_generic.packet_id }, 19w262144);
        _clr_bloom_filter_alu_3.execute((bit<32>)_pgen_pass_1_ctrl_flow_temp_4);
    }
    @name(".clear_bloom_filter_3") action _clear_bloom_filter_1() {
        hash<bit<18>, bit<18>, tuple_1, bit<19>>(_pgen_pass_1_ctrl_flow_temp_5, HashAlgorithm.identity, 18w0, { hdr.pktgen_generic.batch_id, hdr.pktgen_generic.packet_id }, 19w262144);
        _clr_bloom_filter_alu_4.execute((bit<32>)_pgen_pass_1_ctrl_flow_temp_5);
    }
    @name(".set_ecmp_fast_update_key") action _set_ecmp_fast_update_key(bit<17> key) {
        meta.md.ecmp_tbl_bit_index = key;
    }
    @name(".drop_ecmp_update_pkt") action _drop_ecmp_update_pkt() {
        mark_to_drop();
    }
    @name(".set_mbr_down") action _set_mbr_down() {
        hash<bit<17>, bit<17>, tuple_2, bit<18>>(_pgen_pass_1_ctrl_flow_temp_6, HashAlgorithm.identity, 17w0, { meta.md.ecmp_tbl_bit_index }, 18w131072);
        _next_hop_ecmp_alu_0.execute((bit<32>)_pgen_pass_1_ctrl_flow_temp_6);
        mark_to_drop();
    }
    @name(".prepare_for_recirc") action _prepare_for_recirc(bit<4> rtype, bit<16> mgid) {
        hdr.recirc_hdr.setValid();
        hdr.recirc_hdr.tag = 4w0xf;
        hdr.recirc_hdr.rtype = rtype;
        hdr.ig_intr_md_for_tm.mcast_grp_b = mgid;
    }
    @stage(0) @name(".clr_bloom_filter_1") table _clr_bloom_filter_2 {
        actions = {
            _clear_bloom_filter();
        }
        size = 1;
        default_action = _clear_bloom_filter();
    }
    @stage(1) @name(".clr_bloom_filter_2") table _clr_bloom_filter_3 {
        actions = {
            _clear_bloom_filter_0();
        }
        size = 1;
        default_action = _clear_bloom_filter_0();
    }
    @stage(1) @name(".clr_bloom_filter_3") table _clr_bloom_filter_4 {
        actions = {
            _clear_bloom_filter_1();
        }
        size = 1;
        default_action = _clear_bloom_filter_1();
    }
    @stage(5) @name(".make_key_ecmp_fast_update") table _make_key_ecmp_fast_update_0 {
        actions = {
            _set_ecmp_fast_update_key();
            _drop_ecmp_update_pkt();
        }
        key = {
            hdr.pktgen_recirc.key[15:0]: exact @name("pktgen_recirc.key[15:0]") ;
            hdr.pktgen_recirc.packet_id: exact @name("pktgen_recirc.packet_id") ;
        }
        size = 16384;
        default_action = _drop_ecmp_update_pkt();
    }
    @stage(6) @name(".next_hop_ecmp_fast_update") table _next_hop_ecmp_fast_update_0 {
        actions = {
            _set_mbr_down();
        }
        size = 1;
        default_action = _set_mbr_down();
    }
    @stage(8) @name(".prepare_for_recirc") table _prepare_for_recirc_2 {
        actions = {
            _prepare_for_recirc();
            @defaultonly NoAction_17();
        }
        key = {
            hdr.pktgen_port_down.app_id: exact @name("pktgen_port_down.app_id") ;
        }
        size = 7;
        default_action = NoAction_17();
    }
    @name(".lag_alu") selector_action(lag_ap) _lag_alu_0 = {
        void apply(inout bit<1> value) {
            value = 1w0;
        }
    };
    @name(".set_lag_mbr_down") action _set_lag_mbr_down() {
        hash<bit<17>, bit<17>, tuple_2, bit<18>>(_pgen_pass_2_ctrl_flow_temp_0, HashAlgorithm.identity, 17w0, { meta.md.lag_tbl_bit_index }, 18w131072);
        _lag_alu_0.execute((bit<32>)_pgen_pass_2_ctrl_flow_temp_0);
        mark_to_drop();
    }
    @name(".set_lag_fast_update_key") action _set_lag_fast_update_key(bit<17> key) {
        meta.md.lag_tbl_bit_index = key;
    }
    @name(".drop_ifid_update_pkt") action _drop_ifid_update_pkt() {
        mark_to_drop();
    }
    @stage(8) @name(".egr_ifid_fast_update") table _egr_ifid_fast_update_0 {
        actions = {
            _set_lag_mbr_down();
        }
        size = 1;
        default_action = _set_lag_mbr_down();
    }
    @stage(7) @name(".egr_ifid_fast_update_make_key") table _egr_ifid_fast_update_make_key_0 {
        actions = {
            _set_lag_fast_update_key();
            _drop_ifid_update_pkt();
        }
        key = {
            hdr.pktgen_port_down.port_num : exact @name("pktgen_port_down.port_num") ;
            hdr.pktgen_port_down.packet_id: exact @name("pktgen_port_down.packet_id") ;
        }
        size = 16384;
        default_action = _drop_ifid_update_pkt();
    }
    @hidden action act() {
        tmp_14 = true;
    }
    @hidden action act_0() {
        tmp_14 = false;
    }
    @hidden table tbl_act {
        actions = {
            act();
        }
        const default_action = act();
    }
    @hidden table tbl_act_0 {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    apply {
        if (1w0 == hdr.ig_intr_md.resubmit_flag) 
            ing_port.apply();
        if (1w0 == meta.md.recirc_pkt && 1w0 == meta.md.pkt_gen_pkt) 
            switch (ifid_1.apply().action_run) {
                default: {
                    bloom_filter_1_0.apply();
                    bloom_filter_2_0.apply();
                    bloom_filter_3_0.apply();
                    if (meta.md.bf_tmp_1 != 1w0 || meta.md.bf_tmp_2 != 1w0 || meta.md.bf_tmp_3 != 1w0) 
                        bloom_filter_sample.apply();
                    sip_sampler.apply();
                    flowlet_prepare.apply();
                    switch (ipv4_route.apply().action_run) {
                        set_ecmp_0: {
                            next_hop_ecmp.apply();
                        }
                    }

                    next_hop.apply();
                    if (egr_ifid_1.apply().hit) 
                        tbl_act.apply();
                    else 
                        tbl_act_0.apply();
                    if (tmp_14) 
                        ;
                    else 
                        egr_port.apply();
                }
                drop_it_0: {
                    one_bit_read_1.apply();
                    one_bit_read_2.apply();
                    if (meta.md.one_bit_val_1 == 1w1 && meta.md.one_bit_val_2 == 1w1) 
                        undrop.apply();
                    two_instr_no_idx.apply();
                }
            }

        else 
            if (1w0 == meta.md.recirc_pkt && 1w1 == meta.md.pkt_gen_pkt) 
                if (hdr.pktgen_generic.isValid()) {
                    _clr_bloom_filter_2.apply();
                    _clr_bloom_filter_3.apply();
                    _clr_bloom_filter_4.apply();
                }
                else 
                    if (hdr.pktgen_recirc.isValid()) {
                        _make_key_ecmp_fast_update_0.apply();
                        _next_hop_ecmp_fast_update_0.apply();
                    }
                    else 
                        _prepare_for_recirc_2.apply();
            else 
                if (1w1 == meta.md.recirc_pkt && 1w0 == meta.md.pkt_gen_pkt) 
                    ;
                else 
                    if (1w1 == meta.md.recirc_pkt && 1w1 == meta.md.pkt_gen_pkt) 
                        if (hdr.recirc_hdr.rtype == 4w2) 
                            ;
                        else 
                            if (hdr.recirc_hdr.rtype == 4w1) {
                                _egr_ifid_fast_update_make_key_0.apply();
                                _egr_ifid_fast_update_0.apply();
                            }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<recirc_header_t>(hdr.recirc_hdr);
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<udp_t>(hdr.udp);
        packet.emit<tcp_t>(hdr.tcp);
        packet.emit<pktgen_generic_header_t>(hdr.pktgen_generic);
        packet.emit<pktgen_recirc_header_t>(hdr.pktgen_recirc);
        packet.emit<pktgen_port_down_header_t>(hdr.pktgen_port_down);
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

