#include <core.p4>
#include <v1model.p4>

struct intrinsic_metadata_t {
    bit<9>  ingress_port;
    bit<16> packet_length;
    bit<32> eg_ucast_port;
    bit<6>  eg_queue;
    bit<16> eg_mcast_group1;
    bit<16> eg_mcast_group2;
    bit<1>  copy_to_cpu;
    bit<3>  cos_for_copy_to_cpu;
    bit<32> egress_port;
    bit<16> egress_instance;
    bit<2>  instance_type;
    bit<8>  parser_status;
    bit<8>  parser_error_location;
    bit<32> global_version_num;
    bit<48> ingress_global_timestamp;
    bit<48> egress_global_timestamp;
    bit<48> ingress_mac_timestamp;
    bit<13> mcast_hash1;
    bit<13> mcast_hash2;
    bit<1>  deflect_on_drop;
    bit<3>  meter1;
    bit<3>  meter2;
    bit<19> enq_qdepth;
    bit<2>  enq_congest_stat;
    bit<32> enq_timestamp;
    bit<19> deq_qdepth;
    bit<2>  deq_congest_stat;
    bit<32> deq_timedelta;
}

struct l3_metadata_t {
    bit<24> vrf;
    bit<1>  fib_hit;
    bit<16> fib_nexthop;
    bit<1>  fib_nexthop_type;
}

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
    bit<8>  clone_src;
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
    @name(".intrinsic_metadata") 
    intrinsic_metadata_t intrinsic_metadata;
    @name(".l3_metadata") 
    l3_metadata_t        l3_metadata;
    @name(".routing_metadata") 
    routing_metadata_t   routing_metadata;
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

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".egr_cntDum1") direct_counter(CounterType.packets) egr_cntDum1;
    @name(".nop") action nop() {
    }
    @name(".fib_hit_nexthop") action fib_hit_nexthop(bit<16> nexthop_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = nexthop_index;
        meta.l3_metadata.fib_nexthop_type = 1w0;
    }
    @name(".fib_hit_ecmp") action fib_hit_ecmp(bit<16> ecmp_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = ecmp_index;
        meta.l3_metadata.fib_nexthop_type = 1w1;
    }
    @name(".action1") action action1() {
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    @name(".egr_act1") action egr_act1(bit<16> tcp_sport) {
        hdr.tcp.srcPort = tcp_sport;
    }
    @name(".duplicate_check_exm_immediate_action") table duplicate_check_exm_immediate_action {
        actions = {
            nop;
            fib_hit_nexthop;
            fib_hit_ecmp;
        }
        key = {
            meta.l3_metadata.vrf: exact;
            hdr.ipv4.dstAddr    : exact;
        }
        size = 2048;
    }
    @name(".exm_txn_test1") table exm_txn_test1 {
        actions = {
            action1;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        size = 4096;
    }
    @name(".egr_act1") action egr_act1_0(bit<16> tcp_sport) {
        egr_cntDum1.count();
        hdr.tcp.srcPort = tcp_sport;
    }
    @name(".stat_tcam_direct_pkt_64bit") table stat_tcam_direct_pkt_64bit {
        actions = {
            egr_act1_0;
        }
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        size = 2048;
        counters = egr_cntDum1;
    }
    apply {
        stat_tcam_direct_pkt_64bit.apply();
        duplicate_check_exm_immediate_action.apply();
        exm_txn_test1.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".cntDum1") direct_counter(CounterType.packets) cntDum1;
    @name(".cntDum2") direct_counter(CounterType.packets) cntDum2;
    @name(".cntDum4") direct_counter(CounterType.packets_and_bytes) cntDum4;
    @name(".cntDum5") direct_counter(CounterType.packets_and_bytes) cntDum5;
    @name(".cntDum") counter(32w256, CounterType.packets) cntDum;
    @name(".cntDum3") counter(32w256, CounterType.packets) cntDum3;
    @name(".cntDum6") counter(32w256, CounterType.packets_and_bytes) cntDum6;
    @name(".nop") action nop() {
    }
    @name(".hop") action hop(inout bit<8> ttl, bit<9> egress_port) {
        ttl = ttl + 8w255;
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
    }
    @name(".next_hop_ipv4") action next_hop_ipv4(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        hop(hdr.ipv4.ttl, egress_port);
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name(".custom_action_1") action custom_action_1(bit<9> egress_port, bit<32> ipAddr, bit<48> dstAddr, bit<16> tcpPort) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        hdr.ipv4.srcAddr = ipAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.tcp.dstPort = tcpPort;
    }
    @name(".modify_tcp_dst_port_1") action modify_tcp_dst_port_1(bit<16> dstPort, bit<9> egress_port) {
        hdr.tcp.dstPort = dstPort;
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
    @name(".custom_action_2") action custom_action_2(bit<9> egress_port, bit<32> ipAddr, bit<16> tcpPort) {
        hdr.ipv4.srcAddr = ipAddr;
        hdr.tcp.dstPort = tcpPort;
        hop(hdr.ipv4.ttl, egress_port);
    }
    @name(".mod_mac_addr") action mod_mac_addr(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name(".nhop_set") action nhop_set(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        hop(hdr.ipv4.ttl, egress_port);
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name(".set_ucast_dest") action set_ucast_dest(bit<9> dest) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = dest;
    }
    @name(".hash_action") action hash_action(bit<8> value) {
        hdr.ipv4.ttl = hdr.ipv4.ttl + value;
    }
    @name(".nhop_set_1") action nhop_set_1(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".act4") action act4(bit<9> egress_port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
    }
    @name(".act1") action act1(bit<9> egress_port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
    }
    @name(".act2") action act2(bit<32> idx, bit<9> egress_port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        cntDum3.count((bit<32>)idx);
    }
    @name(".act") action act(bit<32> idx, bit<9> egress_port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        cntDum.count((bit<32>)idx);
    }
    @name(".act5") action act5(bit<32> idx, bit<9> egress_port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        cntDum6.count((bit<32>)idx);
    }
    @stage(5) @pack(7) @ways(3) @name(".exm_3ways_7Entries") table exm_3ways_7Entries {
        actions = {
            nop;
            next_hop_ipv4;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        size = 21504;
        @name(".next_hop_ipv4_1_profile") implementation = action_profile(32w2048);
    }
    @stage(2) @pack(6) @ways(4) @name(".exm_4ways_6Entries") table exm_4ways_6Entries {
        actions = {
            nop;
            custom_action_1;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
        }
        size = 24576;
        @name(".custom_action_1_profile") implementation = action_profile(32w2048);
    }
    @stage(6) @pack(8) @ways(4) @name(".exm_4ways_8Entries") table exm_4ways_8Entries {
        actions = {
            nop;
            modify_tcp_dst_port_1;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
            hdr.ipv4.srcAddr: exact;
        }
        size = 32768;
        @name(".modify_tcp_dst_port_1_profile") implementation = action_profile(32w1024);
    }
    @command_line("--placement", "pragma") @command_line("--no-dead-code-elimination") @stage(0) @pack(5) @ways(5) @name(".exm_5ways_5Entries") table exm_5ways_5Entries {
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
        size = 25600;
        @name(".custom_action_3_profile") implementation = action_profile(32w1024);
    }
    @stage(3) @pack(6) @ways(5) @name(".exm_5ways_6Entries") table exm_5ways_6Entries {
        actions = {
            nop;
            custom_action_2;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
        }
        size = 30720;
        @name(".custom_action_2_profile") implementation = action_profile(32w2048);
    }
    @stage(1) @pack(5) @ways(6) @name(".exm_6ways_5Entries") table exm_6ways_5Entries {
        actions = {
            nop;
            next_hop_ipv4;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ipv4.dstAddr    : exact;
            hdr.tcp.dstPort     : exact;
        }
        size = 30720;
        @name(".next_hop_ipv4_profile") implementation = action_profile(32w2048);
    }
    @stage(4) @pack(6) @ways(6) @name(".exm_6ways_6Entries") table exm_6ways_6Entries {
        actions = {
            nop;
            mod_mac_addr;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.tcp.srcPort     : exact;
        }
        size = 36864;
        @name(".mod_mac_addr_profile") implementation = action_profile(32w1024);
    }
    @stage(7) @name(".exm_ipv4_routing") table exm_ipv4_routing {
        actions = {
            nhop_set;
            nop;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
            hdr.ipv4.dstAddr    : exact;
            hdr.ipv4.srcAddr    : exact;
        }
        size = 32768;
        @name(".next_hop_profile") implementation = action_profile(32w4096);
    }
    @stage(11) @name(".exm_txn_test") table exm_txn_test {
        actions = {
            set_ucast_dest;
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact;
        }
        size = 256;
    }
    @stage(11) @use_hash_action(1) @name(".hash_action_exm") table hash_action_exm {
        actions = {
            hash_action;
        }
        key = {
            hdr.ipv4.ttl: exact;
        }
        size = 256;
        default_action = hash_action(1);
    }
    @stage(8) @name(".ipv4_routing_select") table ipv4_routing_select {
        actions = {
            nop;
            nhop_set_1;
        }
        key = {
            hdr.ipv4.dstAddr       : exact;
            hdr.ipv4.srcAddr       : selector;
            hdr.ipv4.dstAddr       : selector;
            hdr.ipv4.identification: selector;
            hdr.ipv4.protocol      : selector;
        }
        @name(".ecmp_action_profile") @mode("resilient") implementation = action_selector(HashAlgorithm.random, 32w1024, 32w64);
    }
    @stage(8) @name(".ipv4_routing_select_iter") table ipv4_routing_select_iter {
        actions = {
            nop;
            nhop_set_1;
        }
        key = {
            hdr.ipv4.dstAddr       : exact;
            hdr.ipv4.srcAddr       : selector;
            hdr.ipv4.dstAddr       : selector;
            hdr.ipv4.identification: selector;
            hdr.ipv4.protocol      : selector;
        }
        @name(".ecmp_action_profile_iter") @mode("resilient") implementation = action_selector(HashAlgorithm.random, 32w1024, 32w64);
    }
    @name(".act4") action act4_0(bit<9> egress_port) {
        cntDum2.count();
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
    }
    @stage(10) @name(".stat_tbl_direct_pkt_32bit") table stat_tbl_direct_pkt_32bit {
        actions = {
            act4_0;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
        }
        size = 2048;
        counters = cntDum2;
    }
    @name(".act1") action act1_0(bit<9> egress_port) {
        cntDum1.count();
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
    }
    @stage(10) @name(".stat_tbl_direct_pkt_64bit") table stat_tbl_direct_pkt_64bit {
        actions = {
            act1_0;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
        }
        size = 2048;
        counters = cntDum1;
    }
    @name(".act1") action act1_1(bit<9> egress_port) {
        cntDum5.count();
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
    }
    @stage(11) @name(".stat_tbl_direct_pkt_byte_32bit") table stat_tbl_direct_pkt_byte_32bit {
        actions = {
            act1_1;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
        }
        size = 2048;
        counters = cntDum5;
    }
    @name(".act1") action act1_2(bit<9> egress_port) {
        cntDum4.count();
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
    }
    @stage(11) @name(".stat_tbl_direct_pkt_byte_64bit") table stat_tbl_direct_pkt_byte_64bit {
        actions = {
            act1_2;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
        }
        size = 2048;
        counters = cntDum4;
    }
    @stage(9) @name(".stat_tbl_indirect_pkt_32bit") table stat_tbl_indirect_pkt_32bit {
        actions = {
            act2;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
        }
        size = 2048;
    }
    @stage(9) @name(".stat_tbl_indirect_pkt_64bit") table stat_tbl_indirect_pkt_64bit {
        actions = {
            act;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
        }
        size = 2048;
    }
    @stage(9) @name(".stat_tbl_indirect_pkt_byte_64bit") table stat_tbl_indirect_pkt_byte_64bit {
        actions = {
            act5;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
        }
        size = 2048;
    }
    apply {
        exm_5ways_5Entries.apply();
        exm_6ways_5Entries.apply();
        exm_4ways_6Entries.apply();
        exm_5ways_6Entries.apply();
        exm_6ways_6Entries.apply();
        exm_3ways_7Entries.apply();
        exm_4ways_8Entries.apply();
        exm_ipv4_routing.apply();
        ipv4_routing_select.apply();
        ipv4_routing_select_iter.apply();
        stat_tbl_indirect_pkt_64bit.apply();
        stat_tbl_indirect_pkt_32bit.apply();
        stat_tbl_indirect_pkt_byte_64bit.apply();
        stat_tbl_direct_pkt_64bit.apply();
        stat_tbl_direct_pkt_32bit.apply();
        stat_tbl_direct_pkt_byte_64bit.apply();
        stat_tbl_direct_pkt_byte_32bit.apply();
        hash_action_exm.apply();
        exm_txn_test.apply();
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
