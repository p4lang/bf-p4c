



metadata intrinsic_metadata_t intrinsic_metadata;
#include "tofino/intrinsic_metadata.p4"
#include "tofino/constants.p4"


header_type packet_in_t {
    fields {
        ingress_port: 9;
    }
}

header_type packet_out_t {
    fields {
        egress_port: 9;
    }
}

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
        length_ : 16;
        checksum : 16;
    }
}




header packet_in_t packet_in_hdr;
header packet_out_t packet_out_hdr;
header ethernet_t ethernet;
header ipv4_t ipv4;
header tcp_t tcp;
header udp_t udp;

parser start {


    return select( current(96, 8) ) {
        0x00 : parse_pkt_in;
        default : default_parser;
    }
}

parser parse_pkt_in {
    extract(packet_in_hdr);
    return parse_ethernet;
}

parser default_parser {
    return select(ig_intr_md.ingress_port) {
        255 : parse_pkt_out;
        default : parse_ethernet;
    }
}

parser parse_pkt_out {
    extract(packet_out_hdr);
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0x0800 : parse_ipv4;
        default : ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.fragOffset, latest.protocol) {
        6 : parse_tcp;
        17 : parse_udp;
        default: ingress;
    }
}

parser parse_tcp {
    extract(tcp);
    return ingress;
}

parser parse_udp {
    extract(udp);
    return ingress;
}




action set_egress_port(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

action mark_to_drop() {

    drop();



}

action send_to_cpu() {

    modify_field(ig_intr_md_for_tm.copy_to_cpu, 1);



}



counter ingress_port_counter {
    type : packets;
    instance_count : 254;
    min_width : 32;
}

counter egress_port_counter {
    type: packets;
    instance_count : 254;
    min_width : 32;
}

action count_ingress() {
    count(ingress_port_counter, ig_intr_md.ingress_port);
}

action count_egress() {
    count(egress_port_counter, ig_intr_md_for_tm.ucast_egress_port);
}

table ingress_port_count_table {
    actions { count_ingress; }
    default_action: count_ingress;
}

table egress_port_count_table {
    actions { count_egress; }
    default_action: count_egress;
}

control process_port_counters {
    if (ig_intr_md_for_tm.ucast_egress_port < 254) {
        apply(ingress_port_count_table);
        apply(egress_port_count_table);
    }
}





action _packet_out() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, packet_out_hdr.egress_port);
    remove_header(packet_out_hdr);
}

table ingress_pkt {
    actions {
        _packet_out;
    }
    default_action: _packet_out();
}

control ingress_pkt_io {
    if (valid(packet_out_hdr)) {
        apply(ingress_pkt);
    }
}

action add_packet_in_hdr() {
    add_header(packet_in_hdr);
    modify_field(packet_in_hdr.ingress_port, ig_intr_md.ingress_port);
}

table egress_pkt {
    actions {
        add_packet_in_hdr;
    }
    default_action: add_packet_in_hdr();
}

control egress_pkt_io {

    if (ig_intr_md_for_tm.copy_to_cpu == 1) {



        apply(egress_pkt);
    }
}








header_type ecmp_metadata_t {
    fields {
        groupId : 16;
        selector : 16;
    }
}

metadata ecmp_metadata_t ecmp_metadata;

field_list ecmp_hash_fields {
    ipv4.srcAddr;
    ipv4.dstAddr;
    udp.srcPort;
    udp.dstPort;
}

field_list_calculation ecmp_hash {
    input {
        ecmp_hash_fields;
    }
    algorithm : crc32;
    output_width : 32;
}

action ecmp_group(groupId) {
    modify_field(ecmp_metadata.groupId, groupId);
    modify_field_with_hash_based_offset(ecmp_metadata.selector, 0, ecmp_hash, 4);
}

table table0 {
    reads {
        ig_intr_md.ingress_port : ternary;
        ethernet.dstAddr : ternary;
        ethernet.srcAddr : ternary;
        ethernet.etherType : ternary;
    }
    actions {
        set_egress_port;
        ecmp_group;
        send_to_cpu;
        mark_to_drop;
    }
    support_timeout: true;
}

table ecmp_group_table {
    reads {
        ecmp_metadata.groupId : exact;
        ecmp_metadata.selector : exact;
    }
    actions {
        set_egress_port;
    }
}

counter table0_counter {
    type: packets;
    direct: table0;
    min_width : 32;
}

counter ecmp_group_table_counter {
    type: packets;
    direct: ecmp_group_table;
    min_width : 32;
}

control ingress {
    ingress_pkt_io();
    if (not valid(packet_out_hdr)) {
        apply(table0) {
            ecmp_group {
                apply(ecmp_group_table);
            }
        }
    }
    process_port_counters();
}

control egress {
    egress_pkt_io();
}
