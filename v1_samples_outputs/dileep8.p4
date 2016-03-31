#include "/home/mbudiu/barefoot/git/P4/p4c/build/../p4include/core.p4"
#include "/home/mbudiu/barefoot/git/P4/p4c/build/../p4include/v1model.p4"

struct egress_intrinsic_metadata_t {
    bit<16> egress_port;
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

struct egress_intrinsic_metadata_for_mirror_buffer_t {
    bit<6>  _pad1;
    bit<10> egress_mirror_id;
    bit<1>  coalesce_flush;
    bit<7>  coalesce_length;
}

struct egress_intrinsic_metadata_for_output_port_t {
    bit<2> _pad1;
    bit<1> capture_tstamp_on_tx;
    bit<1> update_delay_on_tx;
    bit<1> force_tx_error;
    bit<3> drop_ctl;
}

struct egress_intrinsic_metadata_from_parser_aux_t {
    bit<48> egress_global_tstamp;
    bit<32> egress_global_ver;
    bit<16> egress_parser_err;
    bit<8>  clone_src;
    bit<8>  coalesce_sample_count;
}

struct ingress_intrinsic_metadata_t {
    bit<1>  resubmit_flag;
    bit<1>  _pad1;
    bit<2>  _pad2;
    bit<3>  _pad3;
    bit<9>  ingress_port;
    bit<48> ingress_mac_tstamp;
}

struct ingress_intrinsic_metadata_for_mirror_buffer_t {
    bit<6>  _pad1;
    bit<10> ingress_mirror_id;
}

struct ingress_intrinsic_metadata_for_tm_t {
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

struct ingress_intrinsic_metadata_from_parser_aux_t {
    bit<48> ingress_global_tstamp;
    bit<32> ingress_global_ver;
    bit<16> ingress_parser_err;
}

struct generator_metadata_t {
    bit<16> app_id;
    bit<16> batch_id;
    bit<16> instance_id;
}

struct ingress_parser_control_signals {
    bit<3> priority;
}

struct routing_metadata_t {
    bit<1> drop;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
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
    @name("routing_metadata") 
    routing_metadata_t                             routing_metadata;
}

struct headers {
    @name("ethernet") 
    ethernet_t ethernet;
    @name("ipv4") 
    ipv4_t     ipv4;
    @name("tcp") 
    tcp_t      tcp;
    @name("udp") 
    udp_t      udp;
    @name("vlan_tag") 
    vlan_tag_t vlan_tag;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_ethernet") state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x8100: parse_vlan_tag;
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name("parse_ipv4") state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name("parse_tcp") state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }
    @name("parse_udp") state parse_udp {
        packet.extract(hdr.udp);
        transition accept;
    }
    @name("parse_vlan_tag") state parse_vlan_tag {
        packet.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name("start") state start {
        transition parse_ethernet;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action nop() {
    }
    action hop(inout bit<8> ttl, in bit<9> egress_port) {
        ttl = ttl + 8w255;
        meta.ig_intr_md_for_tm.ucast_egress_port = egress_port;
    }
    action next_hop_ipv4(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        hop(hdr.ipv4.ttl, egress_port);
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    action custom_action_2(bit<9> egress_port, bit<32> ipAddr, bit<16> tcpPort) {
        hdr.ipv4.srcAddr = ipAddr;
        hdr.tcp.dstPort = tcpPort;
        hop(hdr.ipv4.ttl, egress_port);
    }
    action custom_action_3(bit<9> egress_port, bit<48> dstAddr, bit<32> dstIp) {
        hdr.ipv4.dstAddr = dstIp;
        hdr.ethernet.dstAddr = dstAddr;
        hop(hdr.ipv4.ttl, egress_port);
    }
    action mod_mac_addr(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        meta.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name("exm_2ways_7Entries_stage_3") table exm_2ways_7Entries_stage_3() {
        actions = {
            nop;
            next_hop_ipv4;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
            hdr.ipv4.dstAddr    : exact;
        }
    }

    @name("exm_3ways_1Entries") table exm_3ways_1Entries() {
        actions = {
            nop;
            next_hop_ipv4;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
        }
    }

    @name("exm_3ways_2Entries_stage_3") table exm_3ways_2Entries_stage_3() {
        actions = {
            nop;
            next_hop_ipv4;
        }
        key = {
            hdr.ipv4.srcAddr: exact;
            hdr.ipv4.dstAddr: exact;
            hdr.tcp.dstPort : exact;
        }
    }

    @name("exm_4ways_16k_stage_5") table exm_4ways_16k_stage_5() {
        actions = {
            nop;
            next_hop_ipv4;
        }
        key = {
            hdr.ipv4.dstAddr    : exact;
            hdr.ipv4.srcAddr    : exact;
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
        }
        size = 16384;
    }

    @name("exm_4ways_1Entries") table exm_4ways_1Entries() {
        actions = {
            nop;
            custom_action_2;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
            hdr.tcp.dstPort : exact;
        }
    }

    @name("exm_4ways_2Entries_stage_4") table exm_4ways_2Entries_stage_4() {
        actions = {
            nop;
            next_hop_ipv4;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
            hdr.tcp.srcPort : exact;
        }
    }

    @name("exm_5ways_2Entries_stage_4") table exm_5ways_2Entries_stage_4() {
        actions = {
            nop;
            custom_action_3;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
            hdr.ipv4.srcAddr: exact;
            hdr.tcp.dstPort : exact;
        }
    }

    @name("exm_5ways_7Entries") table exm_5ways_7Entries() {
        actions = {
            nop;
            custom_action_3;
        }
        key = {
            hdr.ipv4.dstAddr    : exact;
            hdr.ethernet.dstAddr: exact;
        }
    }

    @name("exm_6ways_1Entries_stage_3") table exm_6ways_1Entries_stage_3() {
        actions = {
            nop;
            next_hop_ipv4;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ipv4.dstAddr    : exact;
        }
    }

    @name("exm_6ways_2Entries_stage_4") table exm_6ways_2Entries_stage_4() {
        actions = {
            nop;
            custom_action_2;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
        }
    }

    @name("exm_6ways_7Entries_stage_1") table exm_6ways_7Entries_stage_1() {
        actions = {
            nop;
            next_hop_ipv4;
        }
        key = {
            hdr.ipv4.dstAddr    : exact;
            hdr.ipv4.srcAddr    : exact;
            hdr.ethernet.srcAddr: exact;
        }
    }

    @name("exm_6ways_8Entries_stage_2") table exm_6ways_8Entries_stage_2() {
        actions = {
            nop;
            mod_mac_addr;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
            hdr.tcp.srcPort     : exact;
        }
    }

    apply {
        exm_5ways_7Entries.apply();
        exm_3ways_1Entries.apply();
        exm_4ways_1Entries.apply();
        exm_6ways_7Entries_stage_1.apply();
        exm_6ways_8Entries_stage_2.apply();
        exm_2ways_7Entries_stage_3.apply();
        exm_6ways_1Entries_stage_3.apply();
        exm_3ways_2Entries_stage_3.apply();
        exm_4ways_2Entries_stage_4.apply();
        exm_5ways_2Entries_stage_4.apply();
        exm_6ways_2Entries_stage_4.apply();
        exm_4ways_16k_stage_5.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.vlan_tag);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.tcp);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    Checksum16() ipv4_chksum_calc;
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
