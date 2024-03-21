#include <core.p4>
#include <v1model.p4>

struct routing_metadata_t {
    bit<1> drop;
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

header ipv6_t {
    bit<4>   version;
    bit<8>   trafficClass;
    bit<20>  flowLabel;
    bit<16>  payloadLen;
    bit<8>   nextHdr;
    bit<8>   hopLimit;
    bit<128> srcAddr;
    bit<128> dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
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
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> hdr_length;
    bit<16> checksum;
}

header vlan_tag_t {
    bit<3>  pri;
    bit<1>  cfi;
    bit<12> vlan_id;
    bit<16> etherType;
}

struct metadata {
    @name(".routing_metadata") 
    routing_metadata_t routing_metadata;
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
    @name(".ipv6") 
    ipv6_t                                         ipv6;
    @pa_container_size("ingress", "ipv4.identification", 32) @name(".tcp") 
    tcp_t                                          tcp;
    @name(".udp") 
    udp_t                                          udp;
    @name(".vlan_tag") 
    vlan_tag_t                                     vlan_tag;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x8100: parse_vlan_tag;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: accept;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name(".parse_ipv6") state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            8w6: parse_tcp;
            8w17: parse_udp;
            default: accept;
        }
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }
    @name(".parse_udp") state parse_udp {
        packet.extract(hdr.udp);
        transition accept;
    }
    @name(".parse_vlan_tag") state parse_vlan_tag {
        packet.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

@name(".custom_action_2_profile") action_profile(32w1024) custom_action_2_profile;

@name(".custom_action_3_profile") action_profile(32w1024) custom_action_3_profile;

@name(".ecmp_action_profile") @mode("resilient") action_selector(HashAlgorithm.random, 32w1024, 32w64) ecmp_action_profile;

@name(".indirect_action_profile") action_profile(32w1) indirect_action_profile;

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

@name(".keyless_reg") register<bit<32>>(32w512) keyless_reg;
#include <tofino/p4_14_prim.p4>

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".CounterA") counter(32w1024, CounterType.packets) CounterA;
    @name(".keyless_cntr") counter(32w512, CounterType.packets) keyless_cntr;
    @name(".meter_1") direct_meter<bit<8>>(MeterType.bytes) meter_1;
    @meter_pre_color_aware_per_flow_enable(1) @name(".meter_2") meter(32w500, MeterType.bytes) meter_2;
    @initial_register_lo_value(1) @name(".r_alu") RegisterAction<bit<32>, bit<32>, bit<32>>(keyless_reg) r_alu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = in_value + 32w5;
        }
    };
    @name("._CounterAAction1") action _CounterAAction1(bit<32> idx) {
        CounterA.count((bit<32>)idx);
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w3;
    }
    @name("._CounterAAction2") action _CounterAAction2() {
        CounterA.count((bit<32>)32w37);
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w3;
    }
    @name(".act_1") action act_1(bit<12> value_0, bit<3> value_1, bit<8> value_2) {
        hdr.vlan_tag.vlan_id = value_0;
        hdr.vlan_tag.pri = value_1;
        hdr.ipv4.ttl = value_2;
    }
    @name(".set_egr") action set_egr(bit<9> egress_spec) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_spec;
    }
    @name(".nop") action nop() {
    }
    @name(".hop") action hop(inout bit<8> ttl, bit<9> egress_port) {
        ttl = ttl - 8w1;
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
    }
    @name(".custom_action_3") action custom_action_3(bit<9> egress_port, bit<48> dstAddr, bit<32> dstIp) {
        hdr.ipv4.dstAddr = dstIp;
        hdr.ethernet.dstAddr = dstAddr;
        hop(hdr.ipv4.ttl, egress_port);
    }
    @name(".egress_port") action egress_port(bit<9> egress_port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
    }
    @name(".nhop_set") action nhop_set(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".set_ipv4_dst") action set_ipv4_dst(bit<32> x) {
        hdr.ipv4.dstAddr = x;
    }
    @name(".keyless_counts") action keyless_counts(bit<32> stat_idx, bit<32> stful_idx) {
        keyless_cntr.count((bit<32>)stat_idx);
        r_alu.execute(stful_idx);
    }
    @name(".keyless_action") action keyless_action(bit<12> value_0, bit<3> value_1, bit<8> value_2, bit<9> value_3) {
        hdr.vlan_tag.vlan_id = value_0;
        hdr.vlan_tag.pri = value_1;
        hdr.ipv4.ttl = value_2;
        hdr.ig_intr_md_for_tm.ucast_egress_port = value_3;
    }
    @name(".next_hop_ipv4") action next_hop_ipv4(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        hop(hdr.ipv4.ttl, egress_port);
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name(".meter_action_color_aware") action meter_action_color_aware(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac, bit<32> idx) {
        next_hop_ipv4(egress_port, srcmac, dstmac);
        execute_meter_with_color(meter_2, idx, hdr.ipv4.diffserv, hdr.ipv4.diffserv);
    }
    @name(".keyless_set_egr") action keyless_set_egr() {
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w0;
    }
    @name(".prepare_keyless") action prepare_keyless(bit<9> egr_port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egr_port;
        hdr.tcp.srcPort = 16w9006;
    }
    @name(".custom_action_2") action custom_action_2(bit<8> ttl) {
        hdr.ipv4.ttl = ttl;
    }
    @name("._CounterATable") table _CounterATable {
        actions = {
            _CounterAAction1;
            _CounterAAction2;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
        }
        size = 512;
    }
    @name(".exm_dir") table exm_dir {
        actions = {
            act_1;
            set_egr;
            nop;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
        }
    }
    @name(".exm_indr") table exm_indr {
        actions = {
            nop;
            custom_action_3;
            egress_port;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
            hdr.ipv4.srcAddr: exact;
            hdr.tcp.srcPort : exact;
        }
        size = 256;
        implementation = custom_action_3_profile;
    }
    @name(".ipv4_routing_select") table ipv4_routing_select {
        actions = {
            nhop_set;
            nop;
        }
        key = {
            hdr.ipv4.dstAddr       : lpm;
            hdr.ipv4.srcAddr       : selector;
            hdr.ipv4.dstAddr       : selector;
            hdr.ipv4.identification: selector;
            hdr.ipv4.protocol      : selector;
        }
        size = 512;
        implementation = ecmp_action_profile;
    }
    @name(".keyless_direct") table keyless_direct {
        actions = {
            set_ipv4_dst;
            nop;
        }
        default_action = set_ipv4_dst(127);
    }
    @name(".keyless_direct_2") table keyless_direct_2 {
        actions = {
            set_ipv4_dst;
            @defaultonly nop;
        }
        default_action = nop();
    }
    @name(".keyless_indirect") table keyless_indirect {
        actions = {
            egress_port;
        }
        implementation = indirect_action_profile;
    }
    @name(".keyless_indirect_resources") table keyless_indirect_resources {
        actions = {
            keyless_counts;
        }
        default_action = keyless_counts(1, 2);
    }
    @name(".keyless_table") table keyless_table {
        actions = {
            keyless_action;
        }
        default_action = keyless_action(1901, 3, 32, 56);
    }
    @name(".meter_tbl_color_aware_indirect") table meter_tbl_color_aware_indirect {
        actions = {
            nop;
            meter_action_color_aware;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
            hdr.ipv4.srcAddr: exact;
        }
    }
    @name(".nop") action nop_0() {
        meter_1.read(hdr.ipv4.diffserv);
    }
    @name(".next_hop_ipv4") action next_hop_ipv4_0(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        meter_1.read(hdr.ipv4.diffserv);
        hop(hdr.ipv4.ttl, egress_port);
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name(".meter_tbl_direct") table meter_tbl_direct {
        actions = {
            nop_0;
            next_hop_ipv4_0;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
            hdr.ipv4.srcAddr: exact;
        }
        meters = meter_1;
    }
    @name(".pure_keyless") table pure_keyless {
        actions = {
            keyless_set_egr;
        }
        default_action = keyless_set_egr();
    }
    @alpm(1) @name(".set_egr_alpm") table set_egr_alpm {
        actions = {
            prepare_keyless;
            nop;
        }
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        default_action = prepare_keyless(2);
    }
    @clpm_prefix("ipv4.dstAddr") @clpm_prefix_length(1, 7, 512) @clpm_prefix_length(8, 1024) @clpm_prefix_length(9, 32, 512) @name(".set_egr_clpm") table set_egr_clpm {
        actions = {
            prepare_keyless;
            nop;
        }
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        size = 2048;
        default_action = prepare_keyless(3);
    }
    @name(".set_egr_exm") table set_egr_exm {
        actions = {
            prepare_keyless;
            nop;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        default_action = prepare_keyless(egr_port = 0);
    }
    @name(".set_egr_tcam") table set_egr_tcam {
        actions = {
            prepare_keyless;
            nop;
        }
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        default_action = prepare_keyless(1);
    }
    @name(".tcam_dir") table tcam_dir {
        actions = {
            act_1;
            set_egr;
            nop;
        }
        key = {
            hdr.ethernet.dstAddr: ternary;
            hdr.ethernet.srcAddr: ternary;
        }
    }
    @name(".tcam_indr") table tcam_indr {
        actions = {
            nop;
            custom_action_2;
        }
        key = {
            hdr.ipv4.dstAddr: ternary;
            hdr.ipv4.srcAddr: ternary;
            hdr.tcp.srcPort : ternary;
        }
        size = 256;
        implementation = custom_action_2_profile;
    }
    apply {
        if (hdr.tcp.srcPort == 16w9001) {
            keyless_table.apply();
            exm_dir.apply();
            exm_indr.apply();
            _CounterATable.apply();
            meter_tbl_direct.apply();
            meter_tbl_color_aware_indirect.apply();
            ipv4_routing_select.apply();
            tcam_dir.apply();
            tcam_indr.apply();
            if (hdr.ig_intr_md_for_tm.ucast_egress_port != 9w0) {
                pure_keyless.apply();
            }
        }
        else {
            if (hdr.tcp.srcPort == 16w9002) {
                set_egr_exm.apply();
            }
            else {
                if (hdr.tcp.srcPort == 16w9003) {
                    set_egr_tcam.apply();
                }
                else {
                    if (hdr.tcp.srcPort == 16w9004) {
                        set_egr_alpm.apply();
                    }
                    else {
                        if (hdr.tcp.srcPort == 16w9005) {
                            set_egr_clpm.apply();
                        }
                    }
                }
            }
        }
        if (hdr.tcp.srcPort == 16w9006) {
            keyless_direct.apply();
            keyless_direct_2.apply();
            keyless_indirect_resources.apply();
            if (hdr.ig_intr_md_for_tm.ucast_egress_port == 9w0) {
                keyless_indirect.apply();
            }
        }
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv6);
        packet.emit(hdr.vlan_tag);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.tcp);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum(true, { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

