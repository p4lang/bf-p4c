/* -*- P4_14 -*- */

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#else
#error This program is intended to compile for Tofino P4 architecture only
#endif

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
header_type ethernet_t {
    fields {
        dstAddr   : 48;
        srcAddr   : 48;
        etherType : 16;
    }
}

header_type vlan_tag_t {
    fields {
        pcp       : 3;
        cfi       : 1;
        vid       : 12;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version        : 4;
        ihl            : 4;
        diffserv       : 8;
        totalLen       : 16;
        identification : 16;
        flags          : 3;
        fragOffset     : 13;
        ttl            : 8;
        protocol       : 8;
        hdrChecksum    : 16;
        srcAddr        : 32;
        dstAddr        : 32;
    }
}

header_type option_word_t {
    fields {
        data : 32;
    }
}

header_type ipv6_t {
    fields {
        version : 4;
        trafficClass : 8;
        flowLabel : 20;
        payloadLen : 16;
        nextHdr : 8;
        hopLimit : 8;
        srcAddr : 128;
        dstAddr : 128;
    }
}

header_type icmp_t {
    fields {
        typeCode    : 16;
        checksum    : 16;
    }
}

header_type tcp_t {
    fields {
        srcPort     : 16;
        dstPort     : 16;
        seqNo       : 32;
        ackNo       : 32;
        dataOffset  : 4;
        res         : 4;
        flags       : 8;
        window      : 16;
    }
}

header_type tcp_checksum_t {
    fields {
        checksum    : 16;
        urgentPtr   : 16;
    }
}

header_type udp_t {
    fields {
        srcPort     : 16;
        dstPort     : 16;
        length_     : 16;  /* length is a reserved word */
    }
}

header_type udp_checksum_t {
    fields {
        checksum    : 16;
    }
}

header_type igmp_t {
 fields {
        typeCode    : 16;
        checksum    : 16;
    }
} 

/*************************************************************************
 ***********************  M E T A D A T A  *******************************
 *************************************************************************/
header_type l4_lookup_t {
    fields {
        word_1     : 16;
        word_2     : 16;
        first_frag : 1;
    }
}   

metadata l4_lookup_t l4_lookup;

header_type meta_t {
    fields {
        ipv4_processing     : 1;
        ipv4_tcp_processing : 1;
        ipv4_udp_processing : 1;
        ipv6_processing     : 1;
        ipv6_tcp_processing : 1;
        ipv6_udp_processing : 1;
    }
}

metadata meta_t meta;

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
header ethernet_t      ethernet;
header vlan_tag_t      vlan_tag[2];
header ipv4_t          ipv4;
header option_word_t   ipv4_option_word_1;
header option_word_t   ipv4_option_word_2;
header option_word_t   ipv4_option_word_3;
header option_word_t   ipv4_option_word_4;
header option_word_t   ipv4_option_word_5;
header option_word_t   ipv4_option_word_6;
header option_word_t   ipv4_option_word_7;
header option_word_t   ipv4_option_word_8;
header option_word_t   ipv4_option_word_9;
header option_word_t   ipv4_option_word_10;
header ipv6_t          ipv6;
header icmp_t          icmp;
header igmp_t          igmp;
header tcp_t           tcp;
header tcp_checksum_t  tcp_checksum_v4;
header tcp_checksum_t  tcp_checksum_v6;
header udp_t           udp;
header udp_checksum_t  udp_checksum_v4;
header udp_checksum_t  udp_checksum_v6;

parser start {
    extract(ethernet);
    return select(ethernet.etherType) {
        0x8100 : parse_vlan_tag;
        0x0800 : parse_ipv4;
        0x86DD : parse_ipv6;
        default: ingress;
    }
}

parser parse_vlan_tag {
    extract(vlan_tag[next]);
    return select(latest.etherType) {
        0x8100 : parse_vlan_tag;
        0x0800 : parse_ipv4;
        0x86DD : parse_ipv6;
        default: ingress;
    }
}


parser parse_ipv4 {
    extract(ipv4);
    return select(ipv4.ihl) {
        0x5 : parse_ipv4_no_options;
        0x6 : parse_ipv4_options_1;
        0x7 : parse_ipv4_options_2;
        0x8 : parse_ipv4_options_3;
        0x9 : parse_ipv4_options_4;
        0xA : parse_ipv4_options_5;
        0xB : parse_ipv4_options_6;
        0xC : parse_ipv4_options_7;
        0xD : parse_ipv4_options_8; 
        0xE : parse_ipv4_options_9; 
        0xF : parse_ipv4_options_10;
        default  : ingress; 
    }
}

parser parse_ipv4_options_1 {
    extract(ipv4_option_word_1);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_2 {
    extract(ipv4_option_word_1);
    extract(ipv4_option_word_2);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_3 {
    extract(ipv4_option_word_1);
    extract(ipv4_option_word_2);
    extract(ipv4_option_word_3);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_4 {
    extract(ipv4_option_word_1);
    extract(ipv4_option_word_2);
    extract(ipv4_option_word_3);
    extract(ipv4_option_word_4);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_5 {
    extract(ipv4_option_word_1);
    extract(ipv4_option_word_2);
    extract(ipv4_option_word_3);
    extract(ipv4_option_word_4);
    extract(ipv4_option_word_5);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_6 {
    extract(ipv4_option_word_1);
    extract(ipv4_option_word_2);
    extract(ipv4_option_word_3);
    extract(ipv4_option_word_4);
    extract(ipv4_option_word_5);
    extract(ipv4_option_word_6);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_7 {
    extract(ipv4_option_word_1);
    extract(ipv4_option_word_2);
    extract(ipv4_option_word_3);
    extract(ipv4_option_word_4);
    extract(ipv4_option_word_5);
    extract(ipv4_option_word_6);
    extract(ipv4_option_word_7);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_8 {
    extract(ipv4_option_word_1);
    extract(ipv4_option_word_2);
    extract(ipv4_option_word_3);
    extract(ipv4_option_word_4);
    extract(ipv4_option_word_5);
    extract(ipv4_option_word_6);
    extract(ipv4_option_word_7);
    extract(ipv4_option_word_8);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_9 {
    extract(ipv4_option_word_1);
    extract(ipv4_option_word_2);
    extract(ipv4_option_word_3);
    extract(ipv4_option_word_4);
    extract(ipv4_option_word_5);
    extract(ipv4_option_word_6);
    extract(ipv4_option_word_7);
    extract(ipv4_option_word_8);
    extract(ipv4_option_word_9);
    return parse_ipv4_no_options;
}

parser parse_ipv4_options_10 {
    extract(ipv4_option_word_1);
    extract(ipv4_option_word_2);
    extract(ipv4_option_word_3);
    extract(ipv4_option_word_4);
    extract(ipv4_option_word_5);
    extract(ipv4_option_word_6);
    extract(ipv4_option_word_7);
    extract(ipv4_option_word_8);
    extract(ipv4_option_word_9);
    extract(ipv4_option_word_10);
    return parse_ipv4_no_options;
}

parser parse_ipv4_no_options {
    set_metadata(l4_lookup.word_1, current(0, 16));
    set_metadata(l4_lookup.word_2, current(16, 16));

    return select(ipv4.fragOffset, ipv4.protocol) {
        0x000001 : parse_icmp;
        0x000002 : parse_igmp;
        0x000006 : parse_tcp_v4;
        0x000011 : parse_udp_v4;
        0x000000 mask 0x1FFF00 : parse_first_fragment;
        default  : ingress;
    }
}

parser parse_first_fragment {
    set_metadata(l4_lookup.first_frag, 1);
    return ingress;
}

parser parse_ipv6 {
    extract(ipv6);

    set_metadata(l4_lookup.word_1, current(0, 16));
    set_metadata(l4_lookup.word_2, current(16, 16));

    return select(ipv6.nextHdr) {
        0x01 : parse_icmp;
        0x02 : parse_igmp;
        0x06 : parse_tcp_v6;
        0x11 : parse_udp_v6;
        default: parse_first_fragment;
    }
}

parser parse_icmp {
    extract(icmp);
    return parse_first_fragment;
}

parser parse_igmp {
    extract(igmp);
    return parse_first_fragment;
}

parser parse_tcp_v4 {
    extract(tcp);
    extract(tcp_checksum_v4);
    return parse_first_fragment;
}

parser parse_tcp_v6 {
    extract(tcp);
    extract(tcp_checksum_v6);
    return parse_first_fragment;
}

parser parse_udp_v4 {
    extract(udp);
    extract(udp_checksum_v4);
    return parse_first_fragment;
}

parser parse_udp_v6 {
    extract(udp);
    extract(udp_checksum_v6);
    return parse_first_fragment;
}

/*************************************************************************
 **************  C H E C K S U M    P R O C E S S I N G   ****************
 *************************************************************************/
/* IPv4 */
field_list ipv4_checksum_list {
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
    ipv4_option_word_1.data;
    ipv4_option_word_2.data;
    ipv4_option_word_3.data;
    ipv4_option_word_4.data;
    ipv4_option_word_5.data;
    ipv4_option_word_6.data;
    ipv4_option_word_7.data;
    ipv4_option_word_8.data;
    ipv4_option_word_9.data;
    ipv4_option_word_10.data;
}

field_list_calculation ipv4_checksum {
    input        { ipv4_checksum_list; }
    algorithm    : csum16;
    output_width : 16;
}

calculated_field ipv4.hdrChecksum  {
    verify ipv4_checksum;
    update ipv4_checksum if (meta.ipv4_processing == 1);
}

/* TCP */
field_list tcp_ipv4_checksum_list {
    ipv4.srcAddr;
    ipv4.dstAddr;
    8'0;
    ipv4.protocol;
    ipv4.totalLen;
    tcp.srcPort;
    tcp.dstPort;
    tcp.seqNo;
    tcp.ackNo;
    tcp.dataOffset;
    tcp.res;
    tcp.flags;
    tcp.window;
    tcp_checksum_v4.urgentPtr;
    payload;
}

field_list_calculation tcp_ipv4_checksum {
    input        { tcp_ipv4_checksum_list; }
    algorithm    : csum16;
    output_width : 16;
}

field_list tcp_ipv6_checksum_list {
    ipv6.srcAddr;
    ipv6.dstAddr;
    ipv6.payloadLen;
    8'0;
    ipv6.nextHdr;
    tcp.srcPort;
    tcp.dstPort;
    tcp.seqNo;
    tcp.ackNo;
    tcp.dataOffset;
    tcp.res;
    tcp.flags;
    tcp.window;
    tcp_checksum_v6.urgentPtr;
    payload;
}

field_list_calculation tcp_ipv6_checksum {
    input        { tcp_ipv6_checksum_list; }
    algorithm    : csum16;
    output_width : 16;
}

calculated_field tcp_checksum_v4.checksum {
    update tcp_ipv4_checksum;
}

calculated_field tcp_checksum_v6.checksum {
    update tcp_ipv6_checksum;
}

/* UDP */
field_list udp_ipv4_checksum_list {
    ipv4.srcAddr;
    ipv4.dstAddr;
    // udp.length_; Should be be here by RFC, but can't use the same field twice
    8'0;
    ipv4.protocol;
    ipv4.totalLen;
    udp.srcPort;
    udp.dstPort;
    // udp.length_; Should be be here by RFC, but can't use the same field twice
    payload;
}

field_list_calculation udp_ipv4_checksum {
    input        { udp_ipv4_checksum_list; }
    algorithm    : csum16;
    output_width : 16;
}

field_list udp_ipv6_checksum_list {
    ipv6.srcAddr;
    ipv6.dstAddr;
    // udp.length_; Should be be here by RFC, but can't use the same field twice
    8'0;
    ipv6.nextHdr;
    udp.srcPort;
    udp.dstPort;
    // udp.length_; Should be be here by RFC, but can't use the same field twice
    payload;
}

field_list_calculation udp_ipv6_checksum {
    input        { udp_ipv6_checksum_list; }
    algorithm    : csum16;
    output_width : 16;
}

calculated_field udp_checksum_v4.checksum {
    update udp_ipv4_checksum;
}

calculated_field udp_checksum_v6.checksum {
    update udp_ipv6_checksum;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

/*
 * Common Actions 
 */
action send(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

action discard() {
    modify_field(ig_intr_md_for_tm.drop_ctl, 1);
}

action l3_forward(dmac, smac, port) {
    modify_field(ethernet.dstAddr, dmac);
    modify_field(ethernet.srcAddr, smac);
    send(port);
}

/*
 * IPv4 Actions
 */
action l3_forward_v4(dmac, smac, port) {
    modify_field(meta.ipv4_processing, 1);
#ifdef __P4C__
    subtract_from_field(ipv4.ttl, 1);
#else
    add_to_field(ipv4.ttl, -1);
#endif
    l3_forward(dmac, smac, port);
}

action nat_v4(sip, dip, ttl, port) {
    modify_field(meta.ipv4_processing, 1);
    modify_field(ipv4.srcAddr, sip);
    modify_field(ipv4.dstAddr, dip);
    modify_field(ipv4.ttl, ttl);
    send(port);
}

action tcp_nat_v4(sip, dip, ttl, port, sport, dport) {
    modify_field(tcp.srcPort, sport);
    modify_field(tcp.dstPort, dport);
    nat_v4(sip, dip, ttl, port);
}

action udp_nat_v4(sip, dip, ttl, port, sport, dport) {
    modify_field(tcp.srcPort, sport);
    modify_field(tcp.dstPort, dport);
    nat_v4(sip, dip, ttl, port);
}
    
table ipv4_acl {
    reads {
        ipv4.srcAddr         : ternary;
        ipv4.dstAddr         : ternary;
        ipv4.protocol        : ternary;
        l4_lookup.word_1     : ternary;
        l4_lookup.word_2     : ternary;
        l4_lookup.first_frag : ternary;
        ig_intr_md_from_parser_aux.ingress_parser_err : ternary;
    }
    actions {
        send; discard;
        l3_forward; l3_forward_v4;
        nat_v4; tcp_nat_v4; udp_nat_v4;
    }
    size : 1024;
}

/*
 * IPv6 Actions
 */
action l3_forward_v6(dmac, smac, port) {
    l3_forward(dmac, smac, port);
#ifdef __P4C__
    subtract_from_field(ipv6.hopLimit, 1);
#else
    add_to_field(ipv6.hopLimit, -1);
#endif
}

action nat_v6(sip, dip, ttl, port) {
    modify_field(ipv6.srcAddr, sip);
    modify_field(ipv6.dstAddr, dip);
    modify_field(ipv6.hopLimit, ttl);
    send(port);
}

action tcp_nat_v6(sip, dip, ttl, port, sport, dport) {
    modify_field(tcp.srcPort, sport);
    modify_field(tcp.dstPort, dport);
    nat_v6(sip, dip, ttl, port);
}

action udp_nat_v6(sip, dip, ttl, port, sport, dport) {
    modify_field(tcp.srcPort, sport);
    modify_field(tcp.dstPort, dport);
    nat_v6(sip, dip, ttl, port);
}
    
table ipv6_acl {
    reads {
        ipv6.srcAddr         : ternary;
        ipv6.dstAddr         : ternary;
        ipv6.nextHdr         : ternary;
        l4_lookup.word_1     : ternary;
        l4_lookup.word_2     : ternary;
        l4_lookup.first_frag : ternary;
        /* This field should normally be 0, but let's keep it here */
        ig_intr_md_from_parser_aux.ingress_parser_err : ternary; 
    }
    actions {
        send; discard;
        l3_forward; l3_forward_v6;
        nat_v6; tcp_nat_v6; udp_nat_v6;
    }
    size : 1024;
}

control ingress {
    if (valid(ipv4)) {
        apply(ipv4_acl);
    } else if (valid(ipv6)) {
        apply(ipv6_acl);
    }    
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control egress {
}
