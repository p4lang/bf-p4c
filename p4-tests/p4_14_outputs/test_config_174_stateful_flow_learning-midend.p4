#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<16> hash_1;
    bit<16> hash_2;
    bit<1>  fc_1_1_hit;
    bit<1>  fc_1_2_hit;
    bit<1>  fc_2_1_hit;
    bit<1>  fc_2_2_hit;
    bit<4>  pad_0;
    bit<16> port_numbers;
    bit<16> ports;
    bit<16> proto_idx_pair1;
    bit<16> proto_idx_pair2;
    bit<8>  same_proto_1;
    bit<8>  same_proto_2;
    bit<16> rewrite_idx;
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

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
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
    @name(".tcp") 
    tcp_t                                          tcp;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            8w0x6: parse_tcp;
            default: accept;
        }
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract<tcp_t>(hdr.tcp);
        transition accept;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

struct flow_cache_1_way_1_alu_layout {
    bit<32> lo;
    bit<32> hi;
}

@name(".flow_cache_1_way_1") register<flow_cache_1_way_1_alu_layout>(32w16384) flow_cache_1_way_1;

struct flow_cache_1_way_2_alu_layout {
    bit<32> lo;
    bit<32> hi;
}

@name(".flow_cache_1_way_2") register<flow_cache_1_way_2_alu_layout>(32w16384) flow_cache_1_way_2;

struct flow_cache_2_way_1_alu_layout {
    bit<16> lo;
    bit<16> hi;
}

@name(".flow_cache_2_way_1") register<flow_cache_2_way_1_alu_layout>(32w16384) flow_cache_2_way_1;

struct flow_cache_2_way_2_alu_layout {
    bit<16> lo;
    bit<16> hi;
}

@name(".flow_cache_2_way_2") register<flow_cache_2_way_2_alu_layout>(32w16384) flow_cache_2_way_2;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<32> tmp_3;
    bit<32> tmp_4;
    bit<16> tmp_5;
    bit<16> tmp_6;
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
    @name(".flow_cache_1_way_1_alu") RegisterAction<flow_cache_1_way_1_alu_layout, bit<32>>(flow_cache_1_way_1) flow_cache_1_way_1_alu = {
        void apply(inout         struct flow_cache_1_way_1_alu_layout {
            bit<32> lo;
            bit<32> hi;
        }
value, out bit<32> rv) {
            flow_cache_1_way_1_alu_layout in_value;
            rv = 32w0;
            in_value.lo = value.lo;
            in_value.hi = value.hi;
            value.lo = 32w1;
            if (in_value.lo == hdr.ipv4.dstAddr && value.hi == hdr.ipv4.srcAddr) 
                rv = 32w1;
        }
    };
    @name(".flow_cache_1_way_1_learn_alu") RegisterAction<flow_cache_1_way_1_alu_layout, bit<32>>(flow_cache_1_way_1) flow_cache_1_way_1_learn_alu = {
        void apply(inout         struct flow_cache_1_way_1_alu_layout {
            bit<32> lo;
            bit<32> hi;
        }
value) {
            flow_cache_1_way_1_alu_layout in_value_6;
            in_value_6.lo = value.lo;
            in_value_6.hi = value.hi;
            if (value.lo == 32w0 && value.hi == 32w0) 
                value.hi = hdr.ipv4.srcAddr;
            if (value.lo == 32w0 && in_value_6.hi == 32w0) 
                value.lo = hdr.ipv4.dstAddr;
        }
    };
    @name(".flow_cache_1_way_2_alu") RegisterAction<flow_cache_1_way_2_alu_layout, bit<32>>(flow_cache_1_way_2) flow_cache_1_way_2_alu = {
        void apply(inout         struct flow_cache_1_way_2_alu_layout {
            bit<32> lo;
            bit<32> hi;
        }
value, out bit<32> rv) {
            flow_cache_1_way_2_alu_layout in_value_7;
            rv = 32w0;
            in_value_7.lo = value.lo;
            in_value_7.hi = value.hi;
            value.lo = 32w1;
            if (in_value_7.lo == hdr.ipv4.dstAddr && value.hi == hdr.ipv4.srcAddr) 
                rv = 32w1;
        }
    };
    @name(".flow_cache_2_way_1_alu") RegisterAction<flow_cache_2_way_1_alu_layout, bit<16>>(flow_cache_2_way_1) flow_cache_2_way_1_alu = {
        void apply(inout         struct flow_cache_2_way_1_alu_layout {
            bit<16> lo;
            bit<16> hi;
        }
value, out bit<16> rv) {
            rv = 16w0;
            if (value.hi == meta.meta.port_numbers) 
                rv = value.lo;
        }
    };
    @name(".flow_cache_2_way_1_learn_alu") RegisterAction<flow_cache_2_way_1_alu_layout, bit<16>>(flow_cache_2_way_1) flow_cache_2_way_1_learn_alu = {
        void apply(inout         struct flow_cache_2_way_1_alu_layout {
            bit<16> lo;
            bit<16> hi;
        }
value) {
            flow_cache_2_way_1_alu_layout in_value_9;
            in_value_9.lo = value.lo;
            in_value_9.hi = value.hi;
            if (value.lo == 16w0 && value.hi == 16w0) 
                value.hi = meta.meta.port_numbers;
            if (value.lo == 16w0 && in_value_9.hi == 16w0) 
                value.lo = meta.meta.proto_idx_pair1;
        }
    };
    @name(".flow_cache_2_way_2_alu") RegisterAction<flow_cache_2_way_2_alu_layout, bit<16>>(flow_cache_2_way_2) flow_cache_2_way_2_alu = {
        void apply(inout         struct flow_cache_2_way_2_alu_layout {
            bit<16> lo;
            bit<16> hi;
        }
value, out bit<16> rv) {
            rv = 16w0;
            if (value.hi == meta.meta.port_numbers) 
                rv = value.lo;
        }
    };
    @name(".do_flow_table_cache_1_1") action do_flow_table_cache_1() {
        tmp_3 = flow_cache_1_way_1_alu.execute();
        meta.meta.fc_1_1_hit = (bit<1>)tmp_3;
    }
    @name(".do_flow_table_cache_1_2") action do_flow_table_cache_1_0() {
        tmp_4 = flow_cache_1_way_2_alu.execute();
        meta.meta.fc_1_1_hit = (bit<1>)tmp_4;
    }
    @name(".do_flow_table_learn_1_1") action do_flow_table_learn_1() {
        flow_cache_1_way_1_learn_alu.execute();
    }
    @name(".do_flow_table_cache_2_1") action do_flow_table_cache_2() {
        tmp_5 = flow_cache_2_way_1_alu.execute();
        meta.meta.proto_idx_pair1 = tmp_5;
    }
    @name(".do_flow_table_cache_2_2") action do_flow_table_cache_2_0() {
        tmp_6 = flow_cache_2_way_2_alu.execute();
        meta.meta.proto_idx_pair1 = tmp_6;
    }
    @name(".do_flow_table_learn_2_1") action do_flow_table_learn_2() {
        flow_cache_2_way_1_learn_alu.execute();
    }
    @name(".set_rewrite_idx") action set_rewrite_idx_0(bit<16> rewrite_idx) {
        meta.meta.rewrite_idx = rewrite_idx;
    }
    @name(".on_miss") action on_miss_0() {
    }
    @name(".set_dst_port") action set_dst_port_0(bit<16> port) {
        hdr.tcp.dstPort = port;
    }
    @name(".do_nothing") action do_nothing_0() {
    }
    @name(".do_nothing") action do_nothing_2() {
    }
    @name(".flow_table_cache_1_1") table flow_table_cache {
        actions = {
            do_flow_table_cache_1();
            @defaultonly NoAction_0();
        }
        key = {
            meta.meta.hash_1: exact @name("meta.hash_1") ;
        }
        size = 65536;
        default_action = NoAction_0();
    }
    @name(".flow_table_cache_1_2") table flow_table_cache_1_1 {
        actions = {
            do_flow_table_cache_1_0();
            @defaultonly NoAction_10();
        }
        key = {
            meta.meta.hash_1: exact @name("meta.hash_1") ;
        }
        size = 1;
        default_action = NoAction_10();
    }
    @name(".flow_table_cache_1_age") table flow_table_cache_1_age {
        actions = {
            do_flow_table_learn_1();
            @defaultonly NoAction_11();
        }
        key = {
            meta.meta.hash_1: exact @name("meta.hash_1") ;
        }
        size = 65536;
        default_action = NoAction_11();
    }
    @name(".flow_table_cache_2_1") table flow_table_cache_0 {
        actions = {
            do_flow_table_cache_2();
            @defaultonly NoAction_12();
        }
        key = {
            meta.meta.hash_2: exact @name("meta.hash_2") ;
        }
        size = 65536;
        default_action = NoAction_12();
    }
    @name(".flow_table_cache_2_2") table flow_table_cache_2_1 {
        actions = {
            do_flow_table_cache_2_0();
            @defaultonly NoAction_13();
        }
        key = {
            meta.meta.hash_2: exact @name("meta.hash_2") ;
        }
        size = 1;
        default_action = NoAction_13();
    }
    @name(".flow_table_cache_2_age") table flow_table_cache_2_age {
        actions = {
            do_flow_table_learn_2();
            @defaultonly NoAction_14();
        }
        key = {
            meta.meta.hash_2: exact @name("meta.hash_2") ;
        }
        size = 65536;
        default_action = NoAction_14();
    }
    @name(".flow_table_cpu") table flow_table_cpu {
        actions = {
            set_rewrite_idx_0();
            on_miss_0();
            @defaultonly NoAction_15();
        }
        key = {
            hdr.ipv4.srcAddr : exact @name("ipv4.srcAddr") ;
            hdr.ipv4.dstAddr : exact @name("ipv4.dstAddr") ;
            hdr.ipv4.protocol: exact @name("ipv4.protocol") ;
            meta.meta.ports  : exact @name("meta.ports") ;
        }
        size = 4096;
        default_action = NoAction_15();
    }
    @name(".rewrite_tbl") table rewrite_tbl {
        actions = {
            set_dst_port_0();
            do_nothing_0();
            @defaultonly NoAction_16();
        }
        key = {
            meta.meta.rewrite_idx: exact @name("meta.rewrite_idx") ;
        }
        size = 4096;
        default_action = NoAction_16();
    }
    @name(".slow_path") table slow_path {
        actions = {
            do_nothing_2();
            @defaultonly NoAction_17();
        }
        key = {
            hdr.ipv4.totalLen     : exact @name("ipv4.totalLen") ;
            meta.meta.port_numbers: exact @name("meta.port_numbers") ;
        }
        size = 3072;
        default_action = NoAction_17();
    }
    apply {
        switch (flow_table_cpu.apply().action_run) {
            default: {
                rewrite_tbl.apply();
            }
            on_miss_0: {
                flow_table_cache.apply();
                flow_table_cache_0.apply();
                flow_table_cache_1_1.apply();
                flow_table_cache_2_1.apply();
                if (meta.meta.fc_1_1_hit == 1w1 && meta.meta.same_proto_1 == 8w0 && meta.meta.proto_idx_pair1 & 16w0xffff != 16w0) 
                    flow_table_cache_1_age.apply();
                else 
                    if (meta.meta.fc_1_2_hit == 1w1 && meta.meta.same_proto_2 == 8w0 && meta.meta.proto_idx_pair2 & 16w0xffff != 16w0) 
                        flow_table_cache_2_age.apply();
                    else 
                        slow_path.apply();
            }
        }

    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<tcp_t>(hdr.tcp);
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

