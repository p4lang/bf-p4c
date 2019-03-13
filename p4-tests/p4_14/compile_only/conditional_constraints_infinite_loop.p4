/*
 * Copyright (c) 2017, 2018, MantisNet, Inc. All rights reserved.
 */






/* L2 */
header_type ethernet_t
{
    fields
    {
        DMAC : 48;
        SMAC : 48;
        etherType : 16;
    }
}
header ethernet_t ethernet;

/* L2.5 */
header_type vlan_tag_t
{
    fields
    {
        vlan : 16;
        etherType : 16;
    }
}
header vlan_tag_t vlan_tag[3];
header vlan_tag_t cvlan_tag;

/* L2.5 */
header_type mpls_label_t
{
    fields
    {
        label : 20;
        EXP : 3;
        BoS : 1;
        TTL : 8;
    }
}
header mpls_label_t mpls_label[3];

/* L2.5 */
header_type pwe3_t
{
    fields
    {
       unused : 32;
       DMAC : 48;
       SMAC : 48;
       etherType : 16;
    }
}
header pwe3_t pwe3;

/* L2.5 */
header_type AQ_t
{
    fields
    {
       ISID : 32;
       CDMAC : 48;
       CSMAC : 48;
       etherType : 16;
    }
}
header AQ_t AQ;

/* L3 */
header_type ipv4_t {
   fields {
        version : 4;
        ihl : 4;
        DSCP : 8;
        totalLength : 16;
        identification : 16;
        flags : 3;
        fragmentOffset : 13;
        TTL : 8;
        protocol : 8;
        headerChecksum : 16;
        SIP : 32;
        DIP : 32;
        }
}
header ipv4_t ipv4;

/* L3 */
header_type ipv6_t {
   fields {
        version : 4;
        trafficClass : 8;
        flowLabel : 20;
        payloadLength : 16;
        nextHeader : 8;
        hopLimit : 8;
        SIP : 128;
        DIP : 128;
        }
}
header ipv6_t ipv6;

/* L3.5 */
header_type ip_option_t {
   fields {
        unused : 32;
        }
}
header ip_option_t ip_option[2];

/* L4 */
header_type udp_t {
   fields {
        sport : 16;
        dport : 16;
        udpLength : 16;
        udpChecksum : 16;
        }
}
header udp_t udp;

/* L4 */
header_type tcp_t {
   fields {
        sport : 16;
        dport : 16;
        sequenceNumber : 32;
        ackNumber : 32;
        doff : 4;
        reserved : 6;
        flags : 6;
        window : 16;
        tcpChecksum : 16;
        urgentPointer : 16;
        }
}
header tcp_t tcp;

/* L4 */
header_type sctp_t {
   fields {
        sport : 16;
        dport : 16;
        vtag : 32;
        checksum : 32;
        }
}
header sctp_t sctp;

/* L5 GTP */
header_type gtp_t {
   fields {
        version : 3;
        pt : 1;
        res : 1;
        extension : 1;
        seq : 1;
        npdu : 1;
        pduType : 8;
        pduLength : 16;
   }
}
header gtp_t gtp;

/* COMMON METADATA */
header_type user_metadata_t
{
    fields
    {
        found : 1;
        lag_valid : 1;
        lag : 6;
        ipv6_ip : 11;
        l4_valid : 1;
        sport : 16;
        dport : 16;
        parse_failed : 4;
        act_push_vlan : 1;
        act_pop_vlan : 1;
        act_modify_vlan1 : 1;
        act_modify_vlan2 : 1;
        act_modify_vlan3 : 1;
        act_decap_8021aq : 1;
        act_encap_8021aq : 1;
        act_monitor : 8;
        act_vlan_tag : 16;
        act_8021aq_DMAC : 48;
        act_8021aq_SMAC : 48;
        act_8021aq_ISID : 32;
    }
}
metadata user_metadata_t md;
parser start
{
    extract(ethernet);
    return select(latest.etherType) {
        0x8100, 0x88a8, 0x9100, 0x9200, 0x9300 : parse_vlan;
        0x8847, 0x8848 : parse_mpls;
        0x0800 : parse_ipv4;
        0x86dd : parse_ipv6;
        0x0806 : ingress;
        default : parse_failed_unknown_ethertype;
        }
}

parser parse_vlan {
    extract(vlan_tag[next]);
    return select(latest.etherType) {
        0x8100, 0x88a8, 0x9100, 0x9200, 0x9300 : parse_vlan;
        0x0800 : parse_ipv4;
        0x86dd : parse_ipv6;
        0x88e7 : parse_8021aq;
        0x0806 : ingress;
        default : parse_failed_unknown_ethertype;
    }
}

parser parse_cvlan {
    extract(cvlan_tag);
    return select(latest.etherType) {
        0x8100, 0x88a8, 0x9100, 0x9200, 0x9300 : parse_failed_invalid_8021aq;
        0x0800 : parse_ipv4;
        0x86dd : parse_ipv6;
        0x0806 : ingress;
        default : parse_failed_unknown_ethertype;
    }
}

parser parse_mpls {
    extract(mpls_label[next]);
    return select(latest.BoS, current(0,24)) {
        0x0000000 mask 0x1000000 : parse_mpls;
        0x1000000 mask 0x1FFFFFF : parse_pwe3;
        0x1400000 mask 0x1F00000 : parse_ipv4;
        0x1600000 mask 0x1F00000 : parse_ipv6;
        default : parse_failed_unknown_mpls_guess;
        }
}

parser parse_pwe3 {
    extract(pwe3);
    return select(latest.etherType) {
        0x0800 : parse_ipv4;
        0x86dd : parse_ipv6;
        0x0806 : ingress;
        default : parse_failed_unknown_ethertype;
        }
}

parser parse_8021aq {
    extract(AQ);
    return select(latest.etherType) {
        0x8100, 0x88a8, 0x9100, 0x9200, 0x9300 : parse_cvlan;
        default : parse_failed_invalid_8021aq;
        }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.ihl, latest.protocol) {
        0x501 : ingress;
        0x502 : ingress;
        0x504 : ingress;
        0x506 : parse_tcp;
        0x511 : parse_udp;
        0x529 : ingress;
        0x52F : ingress;
        0x532 : ingress;
        0x533 : ingress;
        0x559 : ingress;
        0x584 : parse_sctp;
        0x589 : ingress;
        0x606 : parse_o1_tcp;
        0x611 : parse_o1_udp;
        0x706 : parse_o2_tcp;
        0x711 : parse_o2_udp;
        default : parse_failed_unknown_protocol;
    }
}

parser parse_ipv6 {
    extract(ipv6);
    return select(latest.nextHeader) {
        0x01 : ingress;
        0x02 : ingress;
        0x04 : ingress;
        0x06 : parse_tcp;
        0x11 : parse_udp;
        0x29 : ingress;
        0x2F : ingress;
        0x32 : ingress;
        0x33 : ingress;
        0x59 : ingress;
        0x84 : parse_sctp;
        0x89 : ingress;
        default : parse_failed_unknown_protocol;
    }
}

parser parse_tcp {
    extract(tcp);
    set_metadata(md.sport, latest.sport);
    set_metadata(md.dport, latest.dport);
    set_metadata(md.l4_valid, 1);
    return ingress;
}

parser parse_udp {
    extract(udp);
    set_metadata(md.sport, latest.sport);
    set_metadata(md.dport, latest.dport);
    set_metadata(md.l4_valid, 1);
    return select(latest.dport) {
        0x0868, 0x084B : parse_gtp;
        default : ingress;
    }
}

parser parse_sctp {
    extract(sctp);
    set_metadata(md.sport, latest.sport);
    set_metadata(md.dport, latest.dport);
    set_metadata(md.l4_valid, 1);
    return ingress;
}

parser parse_o1_tcp {
    extract(ip_option[0]);
    return parse_tcp;
}

parser parse_o1_udp {
    extract(ip_option[0]);
    return parse_udp;
}

parser parse_o2_tcp {
    extract(ip_option[0]);
    extract(ip_option[1]);
    return parse_tcp;
}

parser parse_o2_udp {
    extract(ip_option[0]);
    extract(ip_option[1]);
    return parse_udp;
}

parser parse_gtp {
    extract(gtp);
    return ingress;
}

parser parse_failed_unknown_ethertype {
    set_metadata(md.parse_failed, 1);
    return ingress;
}

parser parse_failed_unknown_mpls_guess {
    set_metadata(md.parse_failed, 3);
    return ingress;
}

parser parse_failed_unknown_protocol {
    set_metadata(md.parse_failed, 5);
    return ingress;
}

parser parse_failed_invalid_8021aq {
    set_metadata(md.parse_failed, 7);
    return ingress;
}

#include "tofino/intrinsic_metadata.p4" 
#include "tofino/stateful_alu_blackbox.p4"
#include "tofino/pktgen_headers.p4"






header_type flow_metadata_t
{
    fields
    {
        flow_hash : 14;
        key_match : 1;
        ingress_port : 8;
        ingress_mac_tstamp : 32;
        totalLength : 32;

        tmp_SIP : 32;
        tmp_DIP : 32;
        tmp_SPORT : 16;
        tmp_DPORT : 16;
        tmp_PROTO : 8;
        tmp_port : 8;
        tmp_keep : 8;

        tmp_start_time : 32;
        tmp_update_time : 32;
        tmp_packet_count : 32;
        tmp_octet_count : 32;

        xor_SIP : 32;
        xor_DIP : 32;
        xor_SPORT : 16;
        xor_DPORT : 16;
        xor_PROTO : 8;
        xor_port : 8;

        evict_index : 14;
    }
}
@pragma pa_solitary ingress fd.key_match
@pragma pa_no_overlay ingress fd.key_match
metadata flow_metadata_t fd;


field_list flow_hash_fields
{
    ethernet.DMAC;
    ethernet.SMAC;
    ethernet.etherType;
    ipv4.SIP;
    ipv4.DIP;
    ipv4.protocol;
    md.sport;
    md.dport;
    vlan_tag[0].vlan;
    vlan_tag[1].vlan;
    vlan_tag[2].vlan;
    cvlan_tag.vlan;
    mpls_label[0].label;
    mpls_label[1].label;
    mpls_label[2].label;
}

field_list_calculation flow_hash
{
    input
    {
        flow_hash_fields;
    }
    algorithm : crc16;
    output_width : 14;
}


register timestamp {
    width : 32;
    instance_count : 1;
}

register flow_SIP {
    width : 32;
    instance_count : 16384;
}
register flow_DIP {
    width : 32;
    instance_count : 16384;
}
register flow_SPORT {
    width : 16;
    instance_count : 16384;
}
register flow_DPORT {
    width : 16;
    instance_count : 16384;
}
register flow_PROTO {
    width : 8;
    instance_count : 16384;
}
register flow_port {
    width : 8;
    instance_count : 16384;
}
register flow_update_time {
    width : 32;
    instance_count : 16384;
}
register flow_keep {
    width : 8;
    instance_count : 16384;
}
register flow_start_time {
    width : 32;
    instance_count : 16384;
}
register flow_packet_count {
    width : 32;
    instance_count : 16384;
}
register flow_octet_count {
    width : 32;
    instance_count : 16384;
}

register evict_index {
    width : 16;
    instance_count : 1;
}
register evict_SIP {
    width : 32;
    instance_count : 16384;
}
register evict_DIP {
    width : 32;
    instance_count : 16384;
}
register evict_SPORT {
    width : 16;
    instance_count : 16384;
}
register evict_DPORT {
    width : 16;
    instance_count : 16384;
}
register evict_PROTO {
    width : 8;
    instance_count : 16384;
}
register evict_port {
    width : 8;
    instance_count : 16384;
}
register evict_update_time {
    width : 32;
    instance_count : 16384;
}
register evict_start_time {
    width : 32;
    instance_count : 16384;
}
register evict_packet_count {
    width : 32;
    instance_count : 16384;
}
register evict_octet_count {
    width : 32;
    instance_count : 16384;
}

blackbox stateful_alu rmw_SIP {
    reg : flow_SIP;
    update_lo_1_value : ipv4.SIP;
    update_hi_1_value : register_lo;
    output_value : alu_hi;
    output_dst : fd.tmp_SIP;
}
blackbox stateful_alu rmw_DIP {
    reg : flow_DIP;
    update_lo_1_value : ipv4.DIP;
    update_hi_1_value : register_lo;
    output_value : alu_hi;
    output_dst : fd.tmp_DIP;
}
blackbox stateful_alu rmw_SPORT {
    reg : flow_SPORT;
    update_lo_1_value : md.sport;
    update_hi_1_value : register_lo;
    output_value : alu_hi;
    output_dst : fd.tmp_SPORT;
}
blackbox stateful_alu rmw_DPORT {
    reg : flow_DPORT;
    update_lo_1_value : md.dport;
    update_hi_1_value : register_lo;
    output_value : alu_hi;
    output_dst : fd.tmp_DPORT;
}
blackbox stateful_alu rmw_PROTO {
    reg : flow_PROTO;
    update_lo_1_value : ipv4.protocol;
    update_hi_1_value : register_lo;
    output_value : alu_hi;
    output_dst : fd.tmp_PROTO;
}
blackbox stateful_alu rmw_port {
    reg : flow_port;
    update_lo_1_value : fd.ingress_port;
    update_hi_1_value : register_lo;
    output_value : alu_hi;
    output_dst : fd.tmp_port;
}
blackbox stateful_alu rmw_update_time {
    reg : flow_update_time;
    update_lo_1_value : fd.ingress_mac_tstamp;
    update_hi_1_value : register_lo;
    output_value : alu_hi;
    output_dst : fd.tmp_update_time;
}
blackbox stateful_alu rmw_keep {
    reg : flow_keep;
    update_lo_1_value : md.act_monitor;
    update_hi_1_value : register_lo;
    output_value : alu_hi;
    output_dst : fd.tmp_keep;
}
blackbox stateful_alu rmw_start_time {
    reg : flow_start_time;
    condition_lo : fd.key_match == 1;
    update_lo_1_predicate : condition_lo;
    update_lo_1_value : register_lo;
    update_lo_2_predicate : not condition_lo;
    update_lo_2_value : fd.ingress_mac_tstamp;
    update_hi_1_predicate : true;
    update_hi_1_value : register_lo;
    output_value : alu_hi;
    output_dst : fd.tmp_start_time;
}
blackbox stateful_alu rmw_packet_count {
    reg : flow_packet_count;
    condition_lo : fd.key_match == 1;
    update_lo_1_predicate : condition_lo;
    update_lo_1_value : register_lo + 1;
    update_lo_2_predicate : not condition_lo;
    update_lo_2_value : 1;
    update_hi_1_predicate : true;
    update_hi_1_value : register_lo;
    output_value : alu_hi;
    output_dst : fd.tmp_packet_count;
}
blackbox stateful_alu rmw_octet_count {
    reg : flow_octet_count;
    condition_lo : fd.key_match == 1;
    update_lo_1_predicate : condition_lo;
    update_lo_1_value : fd.totalLength + register_lo;
    update_lo_2_predicate : not condition_lo;
    update_lo_2_value : fd.totalLength;
    update_hi_1_predicate : true;
    update_hi_1_value : register_lo;
    output_value : alu_hi;
    output_dst : fd.tmp_octet_count;
}
blackbox stateful_alu inc_evict_index {
    reg : evict_index;
    update_lo_1_value : register_lo + 1;
    update_hi_1_value : register_lo;
    output_value : alu_hi;
    output_dst : fd.evict_index;
}
blackbox stateful_alu write_evict_SIP {
    reg : evict_SIP;
    update_lo_1_value : fd.tmp_SIP;
}
blackbox stateful_alu write_evict_DIP {
    reg : evict_DIP;
    update_lo_1_value : fd.tmp_DIP;
}
blackbox stateful_alu write_evict_SPORT {
    reg : evict_SPORT;
    update_lo_1_value : fd.tmp_SPORT;
}
blackbox stateful_alu write_evict_DPORT {
    reg : evict_DPORT;
    update_lo_1_value : fd.tmp_DPORT;
}
blackbox stateful_alu write_evict_PROTO {
    reg : evict_PROTO;
    update_lo_1_value : fd.tmp_PROTO;
}
blackbox stateful_alu write_evict_port {
    reg : evict_port;
    update_lo_1_value : fd.tmp_port;
}
blackbox stateful_alu write_evict_update_time {
    reg : evict_update_time;
    update_lo_1_value : fd.tmp_update_time;
}
blackbox stateful_alu write_evict_start_time {
    reg : evict_start_time;
    update_lo_1_value : fd.tmp_start_time;
}
blackbox stateful_alu write_evict_packet_count {
    reg : evict_packet_count;
    update_lo_1_value : fd.tmp_packet_count;
}
blackbox stateful_alu write_evict_octet_count {
    reg : evict_octet_count;
    update_lo_1_value : fd.tmp_octet_count;
}
@pragma stateful_field_slice ig_intr_md.ingress_mac_tstamp 47 16
blackbox stateful_alu calc_timestamp {
    reg : timestamp;
    update_lo_1_value : ig_intr_md.ingress_mac_tstamp;
    output_value : alu_lo;
    output_dst : fd.ingress_mac_tstamp;
}

@pragma stage 0
table flow_hash_calc { actions { action_flow_hash_calc; } default_action : action_flow_hash_calc; }
action action_flow_hash_calc() { modify_field_with_hash_based_offset(fd.flow_hash, 0, flow_hash, 16384); }

@pragma stage 0
table flow_prep_metadata { actions { action_flow_prep_metadata; } default_action : action_flow_prep_metadata; }
action action_flow_prep_metadata()
{
    modify_field(fd.ingress_port, ig_intr_md.ingress_port);
    modify_field(fd.totalLength, ipv4.totalLength);
#ifndef CASE_FIX    
    calc_timestamp.execute_stateful_alu(0); // Comment out this line and uncomment line 348 to make it work
#endif    
}

@pragma stage 0
table flow_slice_timestamp { actions { action_flow_slice_timestamp; } default_action : action_flow_slice_timestamp; }
action action_flow_slice_timestamp()
{
#ifdef CASE_FIX
    calc_timestamp.execute_stateful_alu();
#endif
}

@pragma stage 1
table flow_rmw_SIP { actions { action_rmw_SIP; } default_action : action_rmw_SIP; }
action action_rmw_SIP() { rmw_SIP.execute_stateful_alu(fd.flow_hash); }
@pragma stage 1
table flow_rmw_DIP { actions { action_rmw_DIP; } default_action : action_rmw_DIP; }
action action_rmw_DIP() { rmw_DIP.execute_stateful_alu(fd.flow_hash); }
@pragma stage 1
table flow_rmw_SPORT { actions { action_rmw_SPORT; } default_action : action_rmw_SPORT; }
action action_rmw_SPORT() { rmw_SPORT.execute_stateful_alu(fd.flow_hash); }
@pragma stage 1
table flow_rmw_DPORT { actions { action_rmw_DPORT; } default_action : action_rmw_DPORT; }
action action_rmw_DPORT() { rmw_DPORT.execute_stateful_alu(fd.flow_hash); }
@pragma stage 2
table flow_rmw_PROTO { actions { action_rmw_PROTO; } default_action : action_rmw_PROTO; }
action action_rmw_PROTO() { rmw_PROTO.execute_stateful_alu(fd.flow_hash); }
@pragma stage 2
table flow_rmw_port { actions { action_rmw_port; } default_action : action_rmw_port; }
action action_rmw_port() { rmw_port.execute_stateful_alu(fd.flow_hash); }
@pragma stage 2
table flow_rmw_update_time { actions { action_rmw_update_time; } default_action : action_rmw_update_time; }
action action_rmw_update_time() { rmw_update_time.execute_stateful_alu(fd.flow_hash); }

@pragma stage 3
table flow_build_xor { actions { action_build_xor; } default_action : action_build_xor; }
action action_build_xor() {
    bit_xor(fd.xor_SIP, ipv4.SIP, fd.tmp_SIP);
    bit_xor(fd.xor_DIP, ipv4.DIP, fd.tmp_DIP);
    bit_xor(fd.xor_SPORT, md.sport, fd.tmp_SPORT);
    bit_xor(fd.xor_DPORT, md.dport, fd.tmp_DPORT);
    bit_xor(fd.xor_PROTO, ipv4.protocol, fd.tmp_PROTO);
    bit_xor(fd.xor_port, fd.ingress_port, fd.tmp_port);
}

@pragma stage 4
table flow_match_key_test
{
    reads
    {
        fd.xor_SIP : exact;
        fd.xor_DIP : exact;
        fd.xor_SPORT : exact;
        fd.xor_DPORT : exact;
        fd.xor_PROTO : exact;
        fd.xor_port : exact;
    }
    actions
    {
        action_flow_match_key_test;
    }
    size : 2;
}
action action_flow_match_key_test() { modify_field(fd.key_match, 1); }

@pragma stage 5
table flow_rmw_keep { actions { action_rmw_keep; } default_action : action_rmw_keep; }
action action_rmw_keep() { rmw_keep.execute_stateful_alu(fd.flow_hash); }
@pragma stage 5
table flow_rmw_start_time { actions { action_rmw_start_time; } default_action : action_rmw_start_time; }
action action_rmw_start_time() { rmw_start_time.execute_stateful_alu(fd.flow_hash); }
@pragma stage 5
table flow_rmw_packet_count { actions { action_rmw_packet_count; } default_action : action_rmw_packet_count; }
action action_rmw_packet_count() { rmw_packet_count.execute_stateful_alu(fd.flow_hash); }
@pragma stage 5
table flow_rmw_octet_count { actions { action_rmw_octet_count; } default_action : action_rmw_octet_count; }
action action_rmw_octet_count() { rmw_octet_count.execute_stateful_alu(fd.flow_hash); }

//@pragma stage 6
table flow_inc_evict_index { actions { action_inc_evict_index; } default_action : action_inc_evict_index; }
action action_inc_evict_index() { inc_evict_index.execute_stateful_alu(0); }
//@pragma stage 7
table flow_write_evict_SIP { actions { action_write_evict_SIP; } default_action : action_write_evict_SIP; }
action action_write_evict_SIP() { write_evict_SIP.execute_stateful_alu(fd.evict_index); }
//@pragma stage 7
table flow_write_evict_DIP { actions { action_write_evict_DIP; } default_action : action_write_evict_DIP; }
action action_write_evict_DIP() { write_evict_DIP.execute_stateful_alu(fd.evict_index); }
//@pragma stage 7
table flow_write_evict_SPORT { actions { action_write_evict_SPORT; } default_action : action_write_evict_SPORT; }
action action_write_evict_SPORT() { write_evict_SPORT.execute_stateful_alu(fd.evict_index); }
//@pragma stage 7
table flow_write_evict_DPORT { actions { action_write_evict_DPORT; } default_action : action_write_evict_DPORT; }
action action_write_evict_DPORT() { write_evict_DPORT.execute_stateful_alu(fd.evict_index); }
//@pragma stage 8
table flow_write_evict_PROTO { actions { action_write_evict_PROTO; } default_action : action_write_evict_PROTO; }
action action_write_evict_PROTO() { write_evict_PROTO.execute_stateful_alu(fd.evict_index); }
//@pragma stage 8
table flow_write_evict_port { actions { action_write_evict_port; } default_action : action_write_evict_port; }
action action_write_evict_port() { write_evict_port.execute_stateful_alu(fd.evict_index); }
//@pragma stage 8
table flow_write_evict_update_time { actions { action_write_evict_update_time; } default_action : action_write_evict_update_time; }
action action_write_evict_update_time() { write_evict_update_time.execute_stateful_alu(fd.evict_index); }
//@pragma stage 8
table flow_write_evict_start_time { actions { action_write_evict_start_time; } default_action : action_write_evict_start_time; }
action action_write_evict_start_time() { write_evict_start_time.execute_stateful_alu(fd.evict_index); }
//@pragma stage 9
table flow_write_evict_packet_count { actions { action_write_evict_packet_count; } default_action : action_write_evict_packet_count; }
action action_write_evict_packet_count() { write_evict_packet_count.execute_stateful_alu(fd.evict_index); }
//@pragma stage 9
table flow_write_evict_octet_count { actions { action_write_evict_octet_count; } default_action : action_write_evict_octet_count; }
action action_write_evict_octet_count() { write_evict_octet_count.execute_stateful_alu(fd.evict_index); }
#include "tofino/intrinsic_metadata.p4"
#include "tofino/constants.p4"


@pragma symmetric ethernet.DMAC ethernet.SMAC
@pragma symmetric ipv4.SIP ipv4.DIP
@pragma symmetric ipv6.SIP ipv6.DIP
@pragma symmetric md.sport md.dport


/* UNICAST FORWARDING */
action set_unicast(egress_port, push_vlan, replace_vlan1, replace_vlan2, replace_vlan3, pop_vlan, vlan_tag, decap_8021aq, encap_8021aq, enacp_8021aq_dmac, encap_8021aq_smac, encap_8021aq_isid, monitor)
{
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
    modify_field(md.act_push_vlan, push_vlan);
    modify_field(md.act_modify_vlan1, replace_vlan1);
    modify_field(md.act_modify_vlan2, replace_vlan2);
    modify_field(md.act_modify_vlan3, replace_vlan3);
    modify_field(md.act_pop_vlan, pop_vlan);
    modify_field(md.act_vlan_tag, vlan_tag);
    modify_field(md.act_decap_8021aq, decap_8021aq);
    modify_field(md.act_encap_8021aq, encap_8021aq);
    modify_field(md.act_8021aq_DMAC, enacp_8021aq_dmac);
    modify_field(md.act_8021aq_SMAC, encap_8021aq_smac);
    modify_field(md.act_8021aq_ISID, encap_8021aq_isid);
    modify_field(md.act_monitor, monitor);
    modify_field(md.found, 1);
}


/* MULTICAST (REPLICATION) FORWARDING */
action set_rg(egress_grp, push_vlan, replace_vlan1, replace_vlan2, replace_vlan3, pop_vlan, vlan_tag, decap_8021aq, encap_8021aq, enacp_8021aq_dmac, encap_8021aq_smac, encap_8021aq_isid, monitor)
{
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 0x1FF);
    modify_field(ig_intr_md_for_tm.mcast_grp_a, egress_grp);
    modify_field(md.act_push_vlan, push_vlan);
    modify_field(md.act_modify_vlan1, replace_vlan1);
    modify_field(md.act_modify_vlan2, replace_vlan2);
    modify_field(md.act_modify_vlan3, replace_vlan3);
    modify_field(md.act_pop_vlan, pop_vlan);
    modify_field(md.act_vlan_tag, vlan_tag);
    modify_field(md.act_decap_8021aq, decap_8021aq);
    modify_field(md.act_encap_8021aq, encap_8021aq);
    modify_field(md.act_8021aq_DMAC, enacp_8021aq_dmac);
    modify_field(md.act_8021aq_SMAC, encap_8021aq_smac);
    modify_field(md.act_8021aq_ISID, encap_8021aq_isid);
    modify_field(md.act_monitor, monitor);
    modify_field(md.found, 1);
}


/* LINK-AGGREGATION (FLOW-AWARE) FORWARDING */
action set_lag(egress_lag, push_vlan, replace_vlan1, replace_vlan2, replace_vlan3, pop_vlan, vlan_tag, decap_8021aq, encap_8021aq, enacp_8021aq_dmac, encap_8021aq_smac, encap_8021aq_isid, monitor)
{
    modify_field(md.lag, egress_lag);
    modify_field(md.lag_valid, 1);
    modify_field(md.act_push_vlan, push_vlan);
    modify_field(md.act_modify_vlan1, replace_vlan1);
    modify_field(md.act_modify_vlan2, replace_vlan2);
    modify_field(md.act_modify_vlan3, replace_vlan3);
    modify_field(md.act_pop_vlan, pop_vlan);
    modify_field(md.act_vlan_tag, vlan_tag);
    modify_field(md.act_decap_8021aq, decap_8021aq);
    modify_field(md.act_encap_8021aq, encap_8021aq);
    modify_field(md.act_8021aq_DMAC, enacp_8021aq_dmac);
    modify_field(md.act_8021aq_SMAC, encap_8021aq_smac);
    modify_field(md.act_8021aq_ISID, encap_8021aq_isid);
    modify_field(md.act_monitor, monitor);
    modify_field(md.found, 1);
}

action set_drop()
{
    modify_field(md.found, 1);
    drop();
}

counter v4_lag_stats
{
    type : packets_and_bytes;
    direct : v4_lag;
}

@pragma stage 6
table v4_lag
{
    reads
    {
        md.lag : exact;
    }
    action_profile : v4_lag_action_profile;
    size : 64;
}

field_list v4_lag_hash_fields
{
    ethernet.DMAC;
    ethernet.SMAC;
    ethernet.etherType;
    ipv4.SIP;
    ipv4.DIP;
    ipv4.protocol;
    md.sport;
    md.dport;
    vlan_tag[0].vlan;
    vlan_tag[1].vlan;
    vlan_tag[2].vlan;
    cvlan_tag.vlan;
    mpls_label[0].label;
    mpls_label[1].label;
    mpls_label[2].label;
}

field_list_calculation v4_lag_hash
{
    input
    {
        v4_lag_hash_fields;
    }
    algorithm : crc16;
    output_width : 16;
}

action_profile v4_lag_action_profile
{
    actions
    {
       lag_nhop_set;
    }
    size : 64;
    dynamic_action_selection : v4_lag_selector;
}

action_selector v4_lag_selector
{
    selection_key : v4_lag_hash;
}

counter v6_lag_stats
{
    type : packets_and_bytes;
    direct : v6_lag;
}

@pragma stage 6
table v6_lag
{
    reads
    {
        md.lag : exact;
    }
    action_profile : v6_lag_action_profile;
    size : 64;
}

field_list v6_lag_hash_fields
{
    ethernet.DMAC;
    ethernet.SMAC;
    ethernet.etherType;
    ipv6.SIP;
    ipv6.DIP;
    ipv6.nextHeader;
    md.sport;
    md.dport;
    vlan_tag[0].vlan;
    vlan_tag[1].vlan;
    vlan_tag[2].vlan;
    cvlan_tag.vlan;
    mpls_label[0].label;
    mpls_label[1].label;
    mpls_label[2].label;
}

field_list_calculation v6_lag_hash
{
    input
    {
        v6_lag_hash_fields;
    }
    algorithm : crc16;
    output_width : 16;
}

action_profile v6_lag_action_profile
{
    actions
    {
        lag_nhop_set;
    }
    size : 64;
    dynamic_action_selection : v6_lag_selector;
}

action_selector v6_lag_selector
{
    selection_key : v6_lag_hash;
}

action lag_nhop_set(port)
{
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

action set_ipv6_hit(val)
{
    modify_field(md.ipv6_ip, val);
}


/* IGNORE */
action _ignore()
{
}


/* MAIN ACL RULES */
counter rule1_stats
{
    type : packets_and_bytes;
    direct : rule1;
}

@pragma stage 1
table rule1
{
    reads
    {
        md.found : exact;
        ig_intr_md.ingress_port : exact;
        ethernet.DMAC : ternary;
        ethernet.SMAC : ternary;
        ethernet.etherType : ternary;
        ipv4.SIP : ternary;
        ipv4.DIP : ternary;
        ipv4.protocol : ternary;
        ipv4.TTL : ternary;
        ipv4.DSCP : ternary;
        tcp.flags : ternary;
        md.ipv6_ip : ternary;
        md.l4_valid : ternary;
        md.sport : ternary;
        md.dport : ternary;
        gtp.pduType : ternary;
        vlan_tag[0].vlan : ternary;
        vlan_tag[1].vlan : ternary;
        vlan_tag[2].vlan : ternary;
        cvlan_tag.vlan : ternary;
        AQ.ISID : ternary;
        mpls_label[0].label : ternary;
        mpls_label[1].label : ternary;
        mpls_label[2].label : ternary;
        md.parse_failed : ternary;
        ipv6.nextHeader : ternary;
        ipv6.hopLimit : ternary;
        ipv6.trafficClass : ternary;
    }
    actions
    {
        set_unicast;
        set_rg;
        set_lag;
        set_drop;
    }
    // NO default_action
    size : 1024;
}

counter rule2_stats
{
    type : packets_and_bytes;
    direct : rule2;
}

@pragma stage 2
table rule2
{
    reads
    {
        md.found : exact;
        ig_intr_md.ingress_port : exact;
        ethernet.DMAC : ternary;
        ethernet.SMAC : ternary;
        ethernet.etherType : ternary;
        ipv4.SIP : ternary;
        ipv4.DIP : ternary;
        ipv4.protocol : ternary;
        ipv4.TTL : ternary;
        ipv4.DSCP : ternary;
        tcp.flags : ternary;
        md.ipv6_ip : ternary;
        md.l4_valid : ternary;
        md.sport : ternary;
        md.dport : ternary;
        gtp.pduType : ternary;
        vlan_tag[0].vlan : ternary;
        vlan_tag[1].vlan : ternary;
        vlan_tag[2].vlan : ternary;
        cvlan_tag.vlan : ternary;
        AQ.ISID : ternary;
        mpls_label[0].label : ternary;
        mpls_label[1].label : ternary;
        mpls_label[2].label : ternary;
        md.parse_failed : ternary;
        ipv6.nextHeader : ternary;
        ipv6.hopLimit : ternary;
        ipv6.trafficClass : ternary;
    }
    actions
    {
        set_unicast;
        set_rg;
        set_lag;
        set_drop;
    }
    // NO default_action
    size : 1024;
}

counter rule3_stats
{
    type : packets_and_bytes;
    direct : rule3;
}

@pragma stage 3
table rule3
{
    reads
    {
        md.found : exact;
        ig_intr_md.ingress_port : exact;
        ethernet.DMAC : ternary;
        ethernet.SMAC : ternary;
        ethernet.etherType : ternary;
        ipv4.SIP : ternary;
        ipv4.DIP : ternary;
        ipv4.protocol : ternary;
        ipv4.TTL : ternary;
        ipv4.DSCP : ternary;
        tcp.flags : ternary;
        md.ipv6_ip : ternary;
        md.l4_valid : ternary;
        md.sport : ternary;
        md.dport : ternary;
        gtp.pduType : ternary;
        vlan_tag[0].vlan : ternary;
        vlan_tag[1].vlan : ternary;
        vlan_tag[2].vlan : ternary;
        cvlan_tag.vlan : ternary;
        AQ.ISID : ternary;
        mpls_label[0].label : ternary;
        mpls_label[1].label : ternary;
        mpls_label[2].label : ternary;
        md.parse_failed : ternary;
        ipv6.nextHeader : ternary;
        ipv6.hopLimit : ternary;
        ipv6.trafficClass : ternary;
    }
    actions
    {
        set_unicast;
        set_rg;
        set_lag;
        set_drop;
    }
    // NO default_action
    size : 1024;
}

counter rule4_stats
{
    type : packets_and_bytes;
    direct : rule4;
}

@pragma stage 4
table rule4
{
    reads
    {
        md.found : exact;
        ig_intr_md.ingress_port : exact;
        ethernet.DMAC : ternary;
        ethernet.SMAC : ternary;
        ethernet.etherType : ternary;
        ipv4.SIP : ternary;
        ipv4.DIP : ternary;
        ipv4.protocol : ternary;
        ipv4.TTL : ternary;
        ipv4.DSCP : ternary;
        tcp.flags : ternary;
        md.ipv6_ip : ternary;
        md.l4_valid : ternary;
        md.sport : ternary;
        md.dport : ternary;
        gtp.pduType : ternary;
        vlan_tag[0].vlan : ternary;
        vlan_tag[1].vlan : ternary;
        vlan_tag[2].vlan : ternary;
        cvlan_tag.vlan : ternary;
        AQ.ISID : ternary;
        mpls_label[0].label : ternary;
        mpls_label[1].label : ternary;
        mpls_label[2].label : ternary;
        md.parse_failed : ternary;
        ipv6.nextHeader : ternary;
        ipv6.hopLimit : ternary;
        ipv6.trafficClass : ternary;
    }
    actions
    {
        set_unicast;
        set_rg;
        set_lag;
        set_drop;
    }
    size : 1024;
}

@pragma stage 0
table ipv6_rule
{
    reads
    {
        ipv6.SIP : ternary;
        ipv6.DIP : ternary;
    }
    actions
    {
        set_ipv6_hit;
        _ignore;
    }
    default_action : _ignore();
    size : 1536;
}

counter parse_failed_stats
{
    type : packets_and_bytes;
    direct : parse_failed;
}

action mark_parse_failed(val)
{
    modify_field(md.parse_failed, val);
}

@pragma stage 0
table parse_failed
{
    reads
    {
        vlan_tag[1].valid : ternary;
        AQ.valid : ternary;
        md.parse_failed : ternary;
        ig_intr_md_from_parser_aux.ingress_parser_err : ternary;

// 1 1 x x = invalid_8021aq (7)
// x x 0 0 = nop
// x x x 0 = mark_parse_failed (x)
// x x 0 x = mark_parse_failed (15) - default

    }
    actions
    {
        act_nop;
        mark_parse_failed;
    }
    default_action : mark_parse_failed(15);
    size : 17; // NOTE: This needs to change in we add more bits
}

action act_nop()
{
    no_op();
}

action act_push_vlan()
{
    push(vlan_tag, 1);
    modify_field(vlan_tag[0].etherType, ethernet.etherType);
    modify_field(vlan_tag[0].vlan, md.act_vlan_tag);
    modify_field(ethernet.etherType, 0x8100);
}

action act_pop_vlan()
{
    modify_field(ethernet.etherType, vlan_tag[0].etherType);
    pop(vlan_tag, 1);
}

action act_modify_vlan1()
{
    modify_field(vlan_tag[0].vlan, md.act_vlan_tag);
}

action act_modify_vlan2()
{
    modify_field(vlan_tag[1].vlan, md.act_vlan_tag);
}

action act_modify_vlan3()
{
    modify_field(vlan_tag[2].vlan, md.act_vlan_tag);
}

action act_decap_8021aq()
{
    modify_field(ethernet.DMAC, AQ.CDMAC);
    modify_field(ethernet.SMAC, AQ.CSMAC);
    modify_field(ethernet.etherType, AQ.etherType);
    modify_field(vlan_tag[0].vlan, cvlan_tag.vlan);
    modify_field(vlan_tag[0].etherType, cvlan_tag.etherType);
    remove_header(AQ);
    remove_header(cvlan_tag);
    remove_header(vlan_tag[2]);
    remove_header(vlan_tag[1]);
}

action act_encap_8021aq()
{
    add_header(AQ);
    add_header(cvlan_tag);
    modify_field(AQ.ISID, md.act_8021aq_ISID);
    modify_field(AQ.CDMAC, ethernet.DMAC);
    modify_field(AQ.CSMAC, ethernet.SMAC);
    modify_field(AQ.etherType, ethernet.etherType);
    modify_field(cvlan_tag.vlan, vlan_tag[0].vlan);
    modify_field(cvlan_tag.etherType, vlan_tag[0].etherType);
    modify_field(ethernet.DMAC, md.act_8021aq_DMAC);
    modify_field(ethernet.SMAC, md.act_8021aq_SMAC);
    modify_field(ethernet.etherType, 0x8100);
    modify_field(vlan_tag[0].vlan, md.act_vlan_tag);
    modify_field(vlan_tag[0].etherType, 0x88e7);
}

counter header_xform_stats
{
    type : packets_and_bytes;
    direct : header_xform;
}

@pragma stage 6
table header_xform
{
    reads
    {
        md.found : ternary;
        md.act_push_vlan : exact;
        md.act_pop_vlan : exact;
        md.act_modify_vlan1 : exact;
        md.act_modify_vlan2 : exact;
        md.act_modify_vlan3 : exact;
        md.act_decap_8021aq : exact;
        md.act_encap_8021aq : exact;
    }
    actions
    {
        set_drop;
        act_nop;
        act_push_vlan;
        act_pop_vlan;
        act_modify_vlan1;
        act_modify_vlan2;
        act_modify_vlan3;
        act_decap_8021aq;
        act_encap_8021aq;
    }
    default_action : act_nop;
    size : 8;
}


control ingress
{
    // stage 0
    apply(parse_failed);
    apply(flow_hash_calc);
    apply(flow_prep_metadata);
    apply(ipv6_rule);
    apply(flow_slice_timestamp);

    // stage 1
    apply(flow_rmw_SIP);
    apply(flow_rmw_DIP);
    apply(flow_rmw_SPORT);
    apply(flow_rmw_DPORT);
    apply(rule1);

    // stage 2
    apply(flow_rmw_PROTO);
    apply(flow_rmw_port);
    apply(flow_rmw_update_time);
    apply(rule2);

    // stage 3
    apply(flow_build_xor);
    apply(rule3);

    // stage 4
    apply(flow_match_key_test);
    apply(rule4);

    // stage 5
    apply(flow_rmw_keep); // needs md.act_monitor from rule4
    apply(flow_rmw_start_time); // needs fd.key_match from flow_match_key_test
    apply(flow_rmw_packet_count); // needs fd.key_match from flow_match_key_test
    apply(flow_rmw_octet_count); // needs fd.key_match from flow_match_key_test

    // stage 6
    if (md.lag_valid == 1)
    {
        if (valid(ipv6))
        {
            apply(v6_lag);
        }
        else
        {
            apply(v4_lag);
        }
    }
    apply(header_xform);

    if (fd.tmp_keep == 1)
    {
        if (fd.key_match == 0)
 {
            // stage 6
            apply(flow_inc_evict_index);
            // stage 7
            apply(flow_write_evict_SIP);
            apply(flow_write_evict_DIP);
            apply(flow_write_evict_SPORT);
            apply(flow_write_evict_DPORT);
            // stage 8
            apply(flow_write_evict_PROTO);
            apply(flow_write_evict_port);
            apply(flow_write_evict_update_time);
            apply(flow_write_evict_start_time);
            // stage 9
            apply(flow_write_evict_packet_count);
            apply(flow_write_evict_octet_count);
 }
    }
}

control egress
{
}


// add_header(name);
// copy_header (a, b);
// remove_header(name);
// modify_field_with_hash_based_offset(dest, 0, field_list_calc, 2^bits)
