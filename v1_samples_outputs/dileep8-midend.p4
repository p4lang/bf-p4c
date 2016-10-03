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

header generator_metadata_t {
    bit<16> app_id;
    bit<16> batch_id;
    bit<16> instance_id;
}

header ingress_parser_control_signals {
    bit<3> priority;
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
    @name("routing_metadata") 
    routing_metadata_t routing_metadata;
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
    @name("ethernet") 
    ethernet_t                                     ethernet;
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
    @name("ipv4") 
    ipv4_t                                         ipv4;
    @name("tcp") 
    tcp_t                                          tcp;
    @name("udp") 
    udp_t                                          udp;
    @name("vlan_tag") 
    vlan_tag_t                                     vlan_tag;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x8100: parse_vlan_tag;
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name("parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name("parse_tcp") state parse_tcp {
        packet.extract<tcp_t>(hdr.tcp);
        transition accept;
    }
    @name("parse_udp") state parse_udp {
        packet.extract<udp_t>(hdr.udp);
        transition accept;
    }
    @name("parse_vlan_tag") state parse_vlan_tag {
        packet.extract<vlan_tag_t>(hdr.vlan_tag);
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
    @name("ttl_0") bit<8> ttl_3;
    @name("ttl_0") bit<8> ttl_4;
    @name("ttl_0") bit<8> ttl_5;
    @name("ttl_0") bit<8> ttl_6;
    @name("ttl_0") bit<8> ttl_7;
    @name("ttl_0") bit<8> ttl_8;
    @name("ttl_0") bit<8> ttl_9;
    @name("ttl_1") bit<8> ttl_10;
    @name("ttl_1") bit<8> ttl_11;
    @name("ttl_2") bit<8> ttl_12;
    @name("ttl_2") bit<8> ttl_13;
    @name("NoAction_1") action NoAction() {
    }
    @name("NoAction_2") action NoAction_0() {
    }
    @name("NoAction_3") action NoAction_13() {
    }
    @name("NoAction_4") action NoAction_14() {
    }
    @name("NoAction_5") action NoAction_15() {
    }
    @name("NoAction_6") action NoAction_16() {
    }
    @name("NoAction_7") action NoAction_17() {
    }
    @name("NoAction_8") action NoAction_18() {
    }
    @name("NoAction_9") action NoAction_19() {
    }
    @name("NoAction_10") action NoAction_20() {
    }
    @name("NoAction_11") action NoAction_21() {
    }
    @name("NoAction_12") action NoAction_22() {
    }
    @name("nop") action nop_0() {
    }
    @name("nop") action nop_12() {
    }
    @name("nop") action nop_13() {
    }
    @name("nop") action nop_14() {
    }
    @name("nop") action nop_15() {
    }
    @name("nop") action nop_16() {
    }
    @name("nop") action nop_17() {
    }
    @name("nop") action nop_18() {
    }
    @name("nop") action nop_19() {
    }
    @name("nop") action nop_20() {
    }
    @name("nop") action nop_21() {
    }
    @name("nop") action nop_22() {
    }
    @name("next_hop_ipv4") action next_hop_ipv4_0(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        @name("hop") {
            ttl_3 = hdr.ipv4.ttl;
            ttl_3 = ttl_3 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_3;
        }
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name("next_hop_ipv4") action next_hop_ipv4_7(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        @name("hop") {
            ttl_4 = hdr.ipv4.ttl;
            ttl_4 = ttl_4 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_4;
        }
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name("next_hop_ipv4") action next_hop_ipv4_8(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        @name("hop") {
            ttl_5 = hdr.ipv4.ttl;
            ttl_5 = ttl_5 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_5;
        }
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name("next_hop_ipv4") action next_hop_ipv4_9(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        @name("hop") {
            ttl_6 = hdr.ipv4.ttl;
            ttl_6 = ttl_6 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_6;
        }
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name("next_hop_ipv4") action next_hop_ipv4_10(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        @name("hop") {
            ttl_7 = hdr.ipv4.ttl;
            ttl_7 = ttl_7 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_7;
        }
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name("next_hop_ipv4") action next_hop_ipv4_11(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        @name("hop") {
            ttl_8 = hdr.ipv4.ttl;
            ttl_8 = ttl_8 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_8;
        }
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name("next_hop_ipv4") action next_hop_ipv4_12(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        @name("hop") {
            ttl_9 = hdr.ipv4.ttl;
            ttl_9 = ttl_9 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_9;
        }
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name("custom_action_2") action custom_action(bit<9> egress_port, bit<32> ipAddr, bit<16> tcpPort) {
        hdr.ipv4.srcAddr = ipAddr;
        hdr.tcp.dstPort = tcpPort;
        @name("hop") {
            ttl_10 = hdr.ipv4.ttl;
            ttl_10 = ttl_10 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_10;
        }
    }
    @name("custom_action_2") action custom_action_0(bit<9> egress_port, bit<32> ipAddr, bit<16> tcpPort) {
        hdr.ipv4.srcAddr = ipAddr;
        hdr.tcp.dstPort = tcpPort;
        @name("hop") {
            ttl_11 = hdr.ipv4.ttl;
            ttl_11 = ttl_11 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_11;
        }
    }
    @name("custom_action_3") action custom_action_5(bit<9> egress_port, bit<48> dstAddr, bit<32> dstIp) {
        hdr.ipv4.dstAddr = dstIp;
        hdr.ethernet.dstAddr = dstAddr;
        @name("hop") {
            ttl_12 = hdr.ipv4.ttl;
            ttl_12 = ttl_12 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_12;
        }
    }
    @name("custom_action_3") action custom_action_6(bit<9> egress_port, bit<48> dstAddr, bit<32> dstIp) {
        hdr.ipv4.dstAddr = dstIp;
        hdr.ethernet.dstAddr = dstAddr;
        @name("hop") {
            ttl_13 = hdr.ipv4.ttl;
            ttl_13 = ttl_13 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_13;
        }
    }
    @name("mod_mac_addr") action mod_mac_addr_0(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name("exm_2ways_7Entries_stage_3") table exm_2ways_7Entries_stage_0() {
        actions = {
            nop_0();
            next_hop_ipv4_0();
            NoAction();
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
            hdr.ipv4.dstAddr    : exact;
        }
        default_action = NoAction();
    }
    @name("exm_3ways_1Entries") table exm_3ways_1Entries() {
        actions = {
            nop_12();
            next_hop_ipv4_7();
            NoAction_0();
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
        }
        default_action = NoAction_0();
    }
    @name("exm_3ways_2Entries_stage_3") table exm_3ways_2Entries_stage_0() {
        actions = {
            nop_13();
            next_hop_ipv4_8();
            NoAction_13();
        }
        key = {
            hdr.ipv4.srcAddr: exact;
            hdr.ipv4.dstAddr: exact;
            hdr.tcp.dstPort : exact;
        }
        default_action = NoAction_13();
    }
    @name("exm_4ways_16k_stage_5") table exm_4ways_16k_stage_0() {
        actions = {
            nop_14();
            next_hop_ipv4_9();
            NoAction_14();
        }
        key = {
            hdr.ipv4.dstAddr    : exact;
            hdr.ipv4.srcAddr    : exact;
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
        }
        size = 16384;
        default_action = NoAction_14();
    }
    @name("exm_4ways_1Entries") table exm_4ways_1Entries() {
        actions = {
            nop_15();
            custom_action();
            NoAction_15();
        }
        key = {
            hdr.ipv4.dstAddr: exact;
            hdr.tcp.dstPort : exact;
        }
        default_action = NoAction_15();
    }
    @name("exm_4ways_2Entries_stage_4") table exm_4ways_2Entries_stage_0() {
        actions = {
            nop_16();
            next_hop_ipv4_10();
            NoAction_16();
        }
        key = {
            hdr.ipv4.dstAddr: exact;
            hdr.tcp.srcPort : exact;
        }
        default_action = NoAction_16();
    }
    @name("exm_5ways_2Entries_stage_4") table exm_5ways_2Entries_stage_0() {
        actions = {
            nop_17();
            custom_action_5();
            NoAction_17();
        }
        key = {
            hdr.ipv4.dstAddr: exact;
            hdr.ipv4.srcAddr: exact;
            hdr.tcp.dstPort : exact;
        }
        default_action = NoAction_17();
    }
    @name("exm_5ways_7Entries") table exm_5ways_7Entries() {
        actions = {
            nop_18();
            custom_action_6();
            NoAction_18();
        }
        key = {
            hdr.ipv4.dstAddr    : exact;
            hdr.ethernet.dstAddr: exact;
        }
        default_action = NoAction_18();
    }
    @name("exm_6ways_1Entries_stage_3") table exm_6ways_1Entries_stage_0() {
        actions = {
            nop_19();
            next_hop_ipv4_11();
            NoAction_19();
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ipv4.dstAddr    : exact;
        }
        default_action = NoAction_19();
    }
    @name("exm_6ways_2Entries_stage_4") table exm_6ways_2Entries_stage_0() {
        actions = {
            nop_20();
            custom_action_0();
            NoAction_20();
        }
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        default_action = NoAction_20();
    }
    @name("exm_6ways_7Entries_stage_1") table exm_6ways_7Entries_stage_0() {
        actions = {
            nop_21();
            next_hop_ipv4_12();
            NoAction_21();
        }
        key = {
            hdr.ipv4.dstAddr    : exact;
            hdr.ipv4.srcAddr    : exact;
            hdr.ethernet.srcAddr: exact;
        }
        default_action = NoAction_21();
    }
    @name("exm_6ways_8Entries_stage_2") table exm_6ways_8Entries_stage_0() {
        actions = {
            nop_22();
            mod_mac_addr_0();
            NoAction_22();
        }
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ethernet.srcAddr: exact;
            hdr.tcp.srcPort     : exact;
        }
        default_action = NoAction_22();
    }
    apply {
        exm_5ways_7Entries.apply();
        exm_3ways_1Entries.apply();
        exm_4ways_1Entries.apply();
        exm_6ways_7Entries_stage_0.apply();
        exm_6ways_8Entries_stage_0.apply();
        exm_2ways_7Entries_stage_0.apply();
        exm_6ways_1Entries_stage_0.apply();
        exm_3ways_2Entries_stage_0.apply();
        exm_4ways_2Entries_stage_0.apply();
        exm_5ways_2Entries_stage_0.apply();
        exm_6ways_2Entries_stage_0.apply();
        exm_4ways_16k_stage_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<vlan_tag_t>(hdr.vlan_tag);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<udp_t>(hdr.udp);
        packet.emit<tcp_t>(hdr.tcp);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

struct struct_0 {
    bit<4>  field;
    bit<4>  field_0;
    bit<8>  field_1;
    bit<16> field_2;
    bit<16> field_3;
    bit<3>  field_4;
    bit<13> field_5;
    bit<8>  field_6;
    bit<8>  field_7;
    bit<32> field_8;
    bit<32> field_9;
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    @name("ipv4_chksum_calc") Checksum16() ipv4_chksum_calc;
    action act() {
        hdr.ipv4.hdrChecksum = ipv4_chksum_calc.get<struct_0>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr });
    }
    table tbl_act() {
        actions = {
            act();
        }
        const default_action = act();
    }
    apply {
        tbl_act.apply();
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
