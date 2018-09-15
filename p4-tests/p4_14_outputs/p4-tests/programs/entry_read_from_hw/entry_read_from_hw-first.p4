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
    @name(".tcp") 
    tcp_t                                          tcp;
    @name(".udp") 
    udp_t                                          udp;
    @name(".vlan_tag") 
    vlan_tag_t                                     vlan_tag;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x8100: parse_vlan_tag;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: accept;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name(".parse_ipv6") state parse_ipv6 {
        packet.extract<ipv6_t>(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            8w6: parse_tcp;
            8w17: parse_udp;
            default: accept;
        }
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract<tcp_t>(hdr.tcp);
        transition accept;
    }
    @name(".parse_udp") state parse_udp {
        packet.extract<udp_t>(hdr.udp);
        transition accept;
    }
    @name(".parse_vlan_tag") state parse_vlan_tag {
        packet.extract<vlan_tag_t>(hdr.vlan_tag);
        transition select(hdr.vlan_tag.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

@name(".act_profile_1") action_profile(32w2048) act_profile_1;

@name(".act_profile_2") action_profile(32w2048) act_profile_2;

@name(".act_profile_3") action_profile(32w2048) act_profile_3;

@name(".act_profile_4") action_profile(32w2048) act_profile_4;

@name(".act_profile_5") action_profile(32w2048) act_profile_5;

@name(".act_profile_6") action_profile(32w2048) act_profile_6;
#include <tofino/p4_14_prim.p4>

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @meter_pre_color_aware_per_flow_enable(1) @name(".meter_1") meter(32w500, MeterType.bytes) meter_1;
    @meter_pre_color_aware_per_flow_enable(1) @name(".meter_2") meter(32w500, MeterType.bytes) meter_2;
    @name(".act_12") action act_12(bit<48> srcMac, bit<48> dstMac, bit<32> meterIdx) {
        hdr.ethernet.srcAddr = srcMac;
        hdr.ethernet.dstAddr = dstMac;
        execute_meter_with_color<meter, bit<32>, bit<8>>(meter_1, meterIdx, hdr.ipv4.diffserv, hdr.ipv4.diffserv);
    }
    @name(".act_22") action act_22(bit<32> ipsrcAddr, bit<16> tcpSport) {
        hdr.ipv4.srcAddr = ipsrcAddr;
        hdr.tcp.srcPort = tcpSport;
    }
    @name(".mod_field") action mod_field(bool cond, bit<48> value) {
        hdr.ethernet.srcAddr = (cond ? value : hdr.ethernet.srcAddr);
    }
    @name(".act_61") action act_61(bit<32> ipsrcAddr, bit<48> dstMac, bit<32> meterIdx) {
        hdr.ipv4.srcAddr = ipsrcAddr;
        hdr.ethernet.dstAddr = dstMac;
        execute_meter_with_color<meter, bit<32>, bit<8>>(meter_2, meterIdx, hdr.ipv4.diffserv, hdr.ipv4.diffserv);
    }
    @name(".act_62") action act_62(bit<32> ipsrcAddr, bit<32> ipdstAddr) {
        hdr.ipv4.srcAddr = ipsrcAddr;
        hdr.ipv4.dstAddr = ipdstAddr;
    }
    @name(".exm_with_indirect_meter") table exm_with_indirect_meter {
        actions = {
            act_12();
            act_22();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.dstAddr: exact @name("ethernet.dstAddr") ;
        }
        size = 2048;
        implementation = act_profile_5;
        default_action = NoAction();
    }
    @name(".mod_field_conditionally_tbl") table mod_field_conditionally_tbl {
        actions = {
            mod_field();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.dstAddr: exact @name("ethernet.dstAddr") ;
        }
        size = 2048;
        default_action = NoAction();
    }
    @name(".tcam_with_indirect_meter") table tcam_with_indirect_meter {
        actions = {
            act_61();
            act_62();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.dstAddr: ternary @name("ipv4.dstAddr") ;
        }
        size = 2048;
        implementation = act_profile_6;
        default_action = NoAction();
    }
    apply {
        exm_with_indirect_meter.apply();
        tcam_with_indirect_meter.apply();
        mod_field_conditionally_tbl.apply();
    }
}

@name(".r") register<bit<32>>(32w2048) r;

@name(".r1") register<bit<32>>(32w2048) r1;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".cntr") counter(32w2048, CounterType.packets) cntr;
    @name(".cntr1") counter(32w2048, CounterType.packets) cntr1;
    @initial_register_lo_value(1) @name(".r1_alu1") RegisterAction<bit<32>, bit<32>>(r1) r1_alu1 = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = in_value + 32w1;
        }
    };
    @initial_register_lo_value(1) @name(".r1_alu2") RegisterAction<bit<32>, bit<32>>(r1) r1_alu2 = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = in_value + 32w100;
        }
    };
    @initial_register_lo_value(1) @name(".r_alu1") RegisterAction<bit<32>, bit<32>>(r) r_alu1 = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = in_value + 32w1;
        }
    };
    @initial_register_lo_value(1) @name(".r_alu2") RegisterAction<bit<32>, bit<32>>(r) r_alu2 = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = in_value + 32w100;
        }
    };
    @name(".atcam_action") action atcam_action(bit<48> dstMac, bit<32> ipSrc) {
        hdr.ethernet.dstAddr = dstMac;
        hdr.ipv4.srcAddr = ipSrc;
    }
    @name(".hop") action hop(inout bit<8> ttl, bit<9> egress_port) {
        ttl = ttl + 8w255;
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
    }
    @name(".hop_ipv4") action hop_ipv4(bit<9> egress_port) {
        hop(hdr.ipv4.ttl, egress_port);
    }
    @command_line("--no-dead-code-elimination") @name(".direct_action_exm_1") action direct_action_exm_1(bit<32> ipsrcAddr, bit<16> tcpSrcport) {
        hdr.ipv4.srcAddr = ipsrcAddr;
        hdr.tcp.srcPort = tcpSrcport;
    }
    @name(".direct_action_exm_2") action direct_action_exm_2(bit<32> ipsrcAddr, bit<32> ipdstAddr) {
        hdr.ipv4.srcAddr = ipsrcAddr;
        hdr.ipv4.dstAddr = ipdstAddr;
    }
    @name(".direct_action_exm_3") action direct_action_exm_3(bit<48> srcMac, bit<48> dstMac) {
        hdr.ethernet.srcAddr = srcMac;
        hdr.ethernet.dstAddr = dstMac;
    }
    @name(".exm_act_1") action exm_act_1(bit<48> srcMac, bit<48> dstMac) {
        hdr.ethernet.srcAddr = srcMac;
        hdr.ethernet.dstAddr = dstMac;
    }
    @name(".exm_act_2") action exm_act_2(bit<32> ipsrcAddr, bit<16> tcpSport) {
        hdr.ipv4.srcAddr = ipsrcAddr;
        hdr.tcp.srcPort = tcpSport;
    }
    @name(".exm_act_3") action exm_act_3(bit<48> dstMac, bit<32> ipdstAddr) {
        hdr.ethernet.dstAddr = dstMac;
        hdr.ipv4.dstAddr = ipdstAddr;
    }
    @name(".act_1") action act_1(bit<48> srcMac, bit<48> dstMac, bit<32> statsIdx, bit<32> stfulIdx) {
        hdr.ethernet.srcAddr = srcMac;
        hdr.ethernet.dstAddr = dstMac;
        cntr.count(statsIdx);
        r_alu1.execute(stfulIdx);
    }
    @name(".act_2") action act_2(bit<32> ipsrcAddr, bit<16> tcpSport, bit<32> stfulIdx) {
        hdr.ipv4.srcAddr = ipsrcAddr;
        hdr.tcp.srcPort = tcpSport;
        r_alu2.execute(stfulIdx);
    }
    @name(".act_3") action act_3(bit<48> dstMac, bit<32> ipdstAddr, bit<32> statsIdx) {
        hdr.ethernet.dstAddr = dstMac;
        hdr.ipv4.dstAddr = ipdstAddr;
        cntr.count(statsIdx);
    }
    @name(".wide_action") action wide_action(bit<48> dstMac, bit<48> srcMac, bit<32> ipsrcAddr, bit<32> ipdstAddr, bit<16> srcPort, bit<16> dstPort) {
        hdr.ethernet.dstAddr = dstMac;
        hdr.ethernet.srcAddr = srcMac;
        hdr.ipv4.dstAddr = ipdstAddr;
        hdr.ipv4.srcAddr = ipsrcAddr;
        hdr.tcp.srcPort = srcPort;
        hdr.tcp.dstPort = dstPort;
    }
    @name(".nop") action nop() {
    }
    @name(".direct_action_tcam_1") action direct_action_tcam_1(bit<48> srcmacAddr) {
        hdr.ethernet.srcAddr = srcmacAddr;
    }
    @name(".direct_action_tcam_2") action direct_action_tcam_2(bit<32> ipsrcAddr) {
        hdr.ipv4.srcAddr = ipsrcAddr;
    }
    @name(".direct_action_tcam_3") action direct_action_tcam_3(bit<32> ipsrcAddr, bit<48> dstMac) {
        hdr.ipv4.srcAddr = ipsrcAddr;
        hdr.ethernet.dstAddr = dstMac;
    }
    @name(".tcam_act_1") action tcam_act_1(bit<48> srcMac, bit<32> ipdstAddr) {
        hdr.ethernet.srcAddr = srcMac;
        hdr.ipv4.dstAddr = ipdstAddr;
    }
    @name(".tcam_act_2") action tcam_act_2(bit<32> ipsrcAddr, bit<32> ipdstAddr, bit<16> tcpSport) {
        hdr.ipv4.srcAddr = ipsrcAddr;
        hdr.ipv4.dstAddr = ipdstAddr;
        hdr.tcp.srcPort = tcpSport;
    }
    @name(".tcam_act_3") action tcam_act_3(bit<48> dstMac, bit<32> ipdstAddr) {
        hdr.ethernet.dstAddr = dstMac;
        hdr.ipv4.dstAddr = ipdstAddr;
    }
    @name(".act_11") action act_11(bit<48> srcMac, bit<48> dstMac, bit<32> statsIdx, bit<32> stfulIdx) {
        hdr.ethernet.srcAddr = srcMac;
        hdr.ethernet.dstAddr = dstMac;
        cntr1.count(statsIdx);
        r1_alu1.execute(stfulIdx);
    }
    @name(".act_21") action act_21(bit<32> ipsrcAddr, bit<16> tcpSport, bit<32> stfulIdx) {
        hdr.ipv4.srcAddr = ipsrcAddr;
        hdr.tcp.srcPort = tcpSport;
        r1_alu2.execute(stfulIdx);
    }
    @name(".act_31") action act_31(bit<48> dstMac, bit<32> ipdstAddr, bit<32> statsIdx) {
        hdr.ethernet.dstAddr = dstMac;
        hdr.ipv4.dstAddr = ipdstAddr;
        cntr1.count(statsIdx);
    }
    @atcam_partition_index("vlan_tag.vlan_id") @name(".atcam_tbl") table atcam_tbl {
        actions = {
            atcam_action();
            @defaultonly NoAction();
        }
        key = {
            hdr.tcp.isValid()   : ternary @name("tcp.$valid$") ;
            hdr.vlan_tag.vlan_id: exact @name("vlan_tag.vlan_id") ;
            hdr.ipv4.dstAddr    : ternary @name("ipv4.dstAddr") ;
        }
        size = 100000;
        default_action = NoAction();
    }
    @name(".exm_valid") table exm_valid {
        actions = {
            hop_ipv4();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("ipv4.$valid$") ;
            hdr.tcp.isValid() : exact @name("tcp.$valid$") ;
        }
        default_action = NoAction();
    }
    @name(".exm_with_direct_action") table exm_with_direct_action {
        actions = {
            direct_action_exm_1();
            direct_action_exm_2();
            direct_action_exm_3();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.dstAddr: exact @name("ipv4.dstAddr") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    @name(".exm_with_indirect_action") table exm_with_indirect_action {
        actions = {
            exm_act_1();
            exm_act_2();
            exm_act_3();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.dstAddr: exact @name("ipv4.dstAddr") ;
            hdr.ipv4.srcAddr: exact @name("ipv4.srcAddr") ;
        }
        size = 16384;
        implementation = act_profile_1;
        default_action = NoAction();
    }
    @name(".exm_with_indirect_action_and_stats") table exm_with_indirect_action_and_stats {
        actions = {
            act_1();
            act_2();
            act_3();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.dstAddr: exact @name("ipv4.dstAddr") ;
        }
        size = 8192;
        implementation = act_profile_3;
        default_action = NoAction();
    }
    @name(".exm_with_wide_action_data") table exm_with_wide_action_data {
        actions = {
            wide_action();
            nop();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.dstAddr    : exact @name("ipv4.dstAddr") ;
            hdr.ipv4.srcAddr    : exact @name("ipv4.srcAddr") ;
            hdr.vlan_tag.vlan_id: exact @name("vlan_tag.vlan_id") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    @name(".lpm") table lpm_0 {
        actions = {
            direct_action_tcam_1();
            direct_action_tcam_2();
            direct_action_tcam_3();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.dstAddr: lpm @name("ipv4.dstAddr") ;
        }
        size = 8192;
        default_action = NoAction();
    }
    @name(".tcam_range_1") table tcam_range_1 {
        actions = {
            nop();
            hop_ipv4();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.dstAddr: ternary @name("ipv4.dstAddr") ;
            hdr.tcp.dstPort : range @name("tcp.dstPort") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".tcam_range_2") table tcam_range_2 {
        actions = {
            nop();
            hop_ipv4();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.dstAddr: ternary @name("ipv4.dstAddr") ;
            hdr.tcp.dstPort : range @name("tcp.dstPort") ;
            hdr.tcp.srcPort : range @name("tcp.srcPort") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".tcam_valid") table tcam_valid {
        actions = {
            hop_ipv4();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("ipv4.$valid$") ;
            hdr.tcp.isValid() : ternary @name("tcp.$valid$") ;
        }
        default_action = NoAction();
    }
    @name(".tcam_with_direct_action") table tcam_with_direct_action {
        actions = {
            direct_action_tcam_1();
            direct_action_tcam_2();
            direct_action_tcam_3();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.dstAddr: ternary @name("ipv4.dstAddr") ;
        }
        size = 8192;
        default_action = NoAction();
    }
    @name(".tcam_with_indirect_action") table tcam_with_indirect_action {
        actions = {
            tcam_act_1();
            tcam_act_2();
            tcam_act_3();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr: ternary @name("ethernet.srcAddr") ;
            hdr.ethernet.dstAddr: ternary @name("ethernet.dstAddr") ;
        }
        size = 8192;
        implementation = act_profile_2;
        default_action = NoAction();
    }
    @name(".tcam_with_indirect_action_and_stats") table tcam_with_indirect_action_and_stats {
        actions = {
            act_11();
            act_21();
            act_31();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr: ternary @name("ethernet.srcAddr") ;
            hdr.ethernet.dstAddr: ternary @name("ethernet.dstAddr") ;
        }
        size = 2048;
        implementation = act_profile_4;
        default_action = NoAction();
    }
    apply {
        exm_with_direct_action.apply();
        tcam_with_direct_action.apply();
        exm_with_indirect_action.apply();
        tcam_with_indirect_action.apply();
        exm_with_indirect_action_and_stats.apply();
        tcam_with_indirect_action_and_stats.apply();
        exm_with_wide_action_data.apply();
        exm_valid.apply();
        tcam_valid.apply();
        lpm_0.apply();
        tcam_range_1.apply();
        tcam_range_2.apply();
        atcam_tbl.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<ipv6_t>(hdr.ipv6);
        packet.emit<vlan_tag_t>(hdr.vlan_tag);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<udp_t>(hdr.udp);
        packet.emit<tcp_t>(hdr.tcp);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>, bit<16>>(true, { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

