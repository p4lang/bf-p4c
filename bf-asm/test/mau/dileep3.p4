#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 3;
        ecn : 3;
        ctrl : 6;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        hdr_length : 16;
        checksum : 16;
    }
}

parser start {
    return parse_ethernet;
}

header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0x800 : parse_ipv4;
        default: ingress;
    }
}

#define IP_PROTOCOLS_TCP 6
#define IP_PROTOCOLS_UDP 17

header ipv4_t ipv4;

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.fragOffset, latest.protocol) {
        IP_PROTOCOLS_TCP : parse_tcp;
        IP_PROTOCOLS_UDP : parse_udp;
        default: ingress;
    }
}

header tcp_t tcp;

parser parse_tcp {
    extract(tcp);
    return ingress;
}

header udp_t udp;

parser parse_udp {
    extract(udp);
    return ingress;
}

header_type routing_metadata_t {
    fields {
        drop: 1;
    }
}

metadata routing_metadata_t /*metadata*/ routing_metadata;

field_list ipv4_field_list {
    ipv4.version;
    ipv4.ihl;
    ipv4.diffserv;
    ipv4.totalLen;
    ipv4.identification;
    ipv4.flags;
    ipv4.fragOffset;
    ipv4.ttl;
    ipv4.protocol;
    ipv4.srcAddr;
    ipv4.dstAddr;
}

field_list_calculation ipv4_chksum_calc {
    input {
        ipv4_field_list;
    }
    algorithm: csum16;
    output_width: 16;
}

calculated_field ipv4.hdrChecksum {
    update ipv4_chksum_calc;
}

action nop() {
}

action hop(ttl, egress_port) {
    add_to_field(ttl, -1);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
}

action hop_ipv4(egress_port /*,srcmac, dstmac*/) {
    hop(ipv4.ttl, egress_port);
//    modify_field(ethernet.srcAddr, srcmac);
//    modify_field(ethernet.dstAddr, dstmac);
}

action next_hop_ipv4(egress_port ,srcmac, dstmac) {
    hop(ipv4.ttl, egress_port);
    modify_field(ethernet.srcAddr, srcmac);
    modify_field(ethernet.dstAddr, dstmac);
}

action ig_drop() {
//    modify_field(routing_metadata.drop, 1);
    add_to_field(ipv4.ttl, -1);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action mod_mac_adr(egress_port, srcmac, dstmac) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
    modify_field(ethernet.srcAddr, srcmac);
    modify_field(ethernet.dstAddr, dstmac);
}

action udp_hdr_add (egress_port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
    add_header(udp);
    modify_field(ipv4.protocol, IP_PROTOCOLS_UDP);
    add_to_field(ipv4.totalLen, 8);
}

action tcp_hdr_rm (egress_port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
    remove_header(tcp);
    modify_field(ipv4.protocol, 0);
//    add_to_field(ipv4.totalLen, -20);
//    modify_field(ipv4.totalLen, 66);
}

action modify_tcp_dst_port(dstPort) {
    modify_field(tcp.dstPort, dstPort);
}

table ipv4_routing {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
      nop;
      hop_ipv4;
    }
}

table ipv4_routing_exm_ways_3_pack_5 {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
        nop;
        hop_ipv4;
    }
}

table ipv4_routing_exm_ways_3_pack_3 {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
      nop;
      next_hop_ipv4;
    }
}

table ipv4_routing_exm_ways_4_pack_3_stage_1 {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
      nop;
      next_hop_ipv4;
    }
}

table ipv4_routing_stage_1 {
    reads {
        ipv4.dstAddr : lpm;
        ipv4.srcAddr : exact;
    }
    actions {
      nop;
      hop_ipv4;
    }
    size : 1024;
}

table tcam_tbl_stage_2 {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
      nop;
      mod_mac_adr;
    }
}

table ipv4_routing_exm_ways_4_pack_7_stage_2 {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
      nop;
      next_hop_ipv4;
    }
}

table ipv4_routing_exm_ways_5_pack_3_stage_3 {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
      nop;
      next_hop_ipv4;
    }
}

table udp_add_tbl_stage_3 {
    reads {
        ethernet.srcAddr : ternary;
    }
    actions {
        nop;
        udp_hdr_add;
    }
}

table ipv4_routing_exm_ways_6_pack_3_stage_4 {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
      nop;
      next_hop_ipv4;
    }
}

table tcp_rm_tbl_stage_4 {
    reads {
        ethernet.srcAddr : ternary;
    }
    actions {
        nop;
        tcp_hdr_rm;
    }
}

table ipv4_routing_exm_ways_3_pack_4_stage_5 {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
      nop;
      next_hop_ipv4;
    }
}

table ipv4_routing_exm_ways_4_pack_4_stage_6 {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
      nop;
      next_hop_ipv4;
    }
}

table ipv4_routing_exm_ways_5_pack_4_stage_7 {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
      nop;
      next_hop_ipv4;
    }
}

table ipv4_routing_exm_ways_6_pack_4_stage_8 {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
      nop;
      next_hop_ipv4;
    }
}

/* Main control flow */
control ingress {
    apply(ipv4_routing_exm_ways_3_pack_5);
}

action eg_drop() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 0);
    modify_field(eg_intr_md.egress_port, 0);
}

action permit() {
}

table egress_acl {
    reads {
        routing_metadata.drop: ternary;
    }
    actions {
        permit;
        eg_drop;
    }
}

control egress {
//    apply(egress_acl);
}