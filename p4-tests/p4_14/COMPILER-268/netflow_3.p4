/*
Copyright 2013-present Barefoot Networks, Inc. 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include <tofino/intrinsic_metadata.p4>
#include <tofino/stateful_alu_blackbox.p4>
#include <tofino/constants.p4>

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

header_type icmp_t {
    fields {
        type_code: 16;
        cksum : 16;
    }
}

header_type md_t {
    fields {
        sport : 16;
        dport : 16;
        sport_dport : 32;
        timestamp : 32;

        flow_id : 18;

        cache_flags_0 : 2;
    }
}

header ethernet_t ethernet;
header ipv4_t ipv4;
header ipv6_t ipv6;
header tcp_t tcp;
header udp_t udp;
header icmp_t icmp;
metadata md_t md;

parser start {
    return parse_ethernet;
}
parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0x0800 : parse_ipv4;
        0x86DD : parse_ipv6;
    }
}

#define IP_PROTOCOLS_ICMP  1
#define IP_PROTOCOLS_TCP   6
#define IP_PROTOCOLS_UDP  17

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.fragOffset, latest.protocol) {
        IP_PROTOCOLS_ICMP : parse_icmp;
        IP_PROTOCOLS_TCP : parse_tcp;
        IP_PROTOCOLS_UDP : parse_udp;
        default: ingress;
    }
}

parser parse_ipv6 {
  extract(ipv6);
  return select(latest.nextHdr) {
    IP_PROTOCOLS_ICMP : parse_icmp;
    IP_PROTOCOLS_TCP : parse_tcp;
    IP_PROTOCOLS_UDP : parse_udp;
    default: ingress;
  }
}

parser parse_icmp {
    extract(icmp);
    set_metadata(md.sport, latest.type_code);
    return ingress;
}

parser parse_tcp {
    extract(tcp);
    set_metadata(md.sport, latest.srcPort);
    set_metadata(md.dport, latest.dstPort);
    return ingress;
}

parser parse_udp {
    extract(udp);
    set_metadata(md.sport, latest.srcPort);
    set_metadata(md.dport, latest.dstPort);
    return ingress;
}


action nothing() {}

/******************************************************************************
 *
 * A dummy table to combine two 16 bit metadatas into one 32 bit metadata since
 * the blackbox stateful alu can't take a hash as an input.
 *
 *****************************************************************************/
table l4_ports_to_hash {
    actions { combine_ports_with_hash; }
    default_action: combine_ports_with_hash;
    size : 1;
}
field_list ports_fl {
    md.sport;
    md.dport;
}
field_list_calculation port_flc {
    input { ports_fl; }
    algorithm: identity;
    output_width: 32;
}
action combine_ports_with_hash() {
    modify_field_with_hash_based_offset(md.sport_dport, 0, port_flc, 32);
}


/******************************************************************************
 *
 * A dummy table to convert a 48 bit nano-second timestamp to a 32 bit micro-
 * second timestamp.  Right shift by 10 (divides by 1024 for an approximate
 * nanosecond to microsecond conversion) and then drop the remaining high bits
 *
 *****************************************************************************/
table make_timestamp {
    actions { save_timestamp; }
    default_action: save_timestamp;
    size : 1;
}
action save_timestamp() {
    // TODO - Tofino compiler does not yet support funnel-shift operations
    //        required to shift a 48 bit field right and put the result in a
    //        32 bit field.  As a work around skip the shift and leave the
    //        timestamp in nanosecond resolution rather than microsecond
    //        resolution.
    //shift_right(md.timestamp, ig_intr_md.ingress_mac_tstamp, 10);
    modify_field(md.timestamp, ig_intr_md.ingress_mac_tstamp);
}


/******************************************************************************
 *
 * Main match table for IPv4 flows, maps a 5 tuple to flow-id.
 *
 *****************************************************************************/
table flows_v4 {
    reads {
        ipv4.srcAddr  : exact;
        ipv4.dstAddr  : exact;
        md.sport      : exact;
        md.dport      : exact;
        ipv4.protocol : exact;
    }
    actions {
        nothing;
        set_flow_id;
    }
    default_action: nothing;
    size : 262144;
    support_timeout: true;
}

action set_flow_id(fi) {
    modify_field(md.flow_id, fi);
}

/******************************************************************************
 *
 * D-Left hash to hold flows while they are waiting for the CPU to install them
 * in the main match table.
 *
 *****************************************************************************/
field_list ipv4_5_tuple {
    ipv4.srcAddr;
    ipv4.dstAddr;
    md.sport;
    md.dport;
    ipv4.protocol;
}
field_list_calculation v4_cache_way_0_hash {
    input { ipv4_5_tuple; }
    algorithm: random;
    output_width: 15;
}
register flow_v4_cache_way_0_tbl_0 {
    width : 32;
    instance_count : 32768;
}
register flow_v4_cache_way_0_tbl_1 {
    width : 32;
    instance_count : 32768;
}
register flow_v4_cache_way_0_tbl_2 {
    width : 64;
    instance_count : 32768;
}
register flow_v4_cache_way_0_tbl_3 {
    width : 8;
    instance_count : 32768;
}
/* 
 * One instruction per ALU to do a search+learn.
 */
blackbox stateful_alu flow_v4_cache_way_0_tbl_0 {
    reg: flow_v4_cache_way_0_tbl_0;
    condition_lo: register_lo == ipv4.srcAddr;
    condition_hi: register_lo == 0xFFFFFFFF;
    update_hi_1_predicate: not condition_lo and not condition_hi;
    update_hi_2_predicate: condition_hi;
    update_hi_1_value: 1;
    update_hi_2_value: 2;
    update_lo_1_predicate: condition_hi;
    update_lo_1_value: ipv4.srcAddr;
    output_dst: md.cache_flags_0;
    reduction_or_group: v4_cache_way_0;
    output_predicate: condition_hi or not condition_lo;
    output_value: alu_hi;
}
blackbox stateful_alu flow_v4_cache_way_0_tbl_1 {
    reg: flow_v4_cache_way_0_tbl_1;
    condition_lo: register_lo == ipv4.dstAddr;
    condition_hi: register_lo == 0xFFFFFFFF;
    update_hi_1_predicate: not condition_lo and not condition_hi;
    update_hi_2_predicate: condition_hi;
    update_hi_1_value: 1;
    update_hi_2_value: 2;
    update_lo_1_predicate: condition_hi;
    update_lo_1_value: ipv4.dstAddr;
    output_dst: md.cache_flags_0;
    reduction_or_group: v4_cache_way_0;
    output_predicate: condition_hi or not condition_lo;
    output_value: alu_hi;
}
blackbox stateful_alu flow_v4_cache_way_0_tbl_2 {
    reg: flow_v4_cache_way_0_tbl_2;
    condition_lo: register_lo == md.sport_dport;
    condition_hi: register_lo == 0xFFFFFFFF;
    update_hi_1_predicate: not condition_hi;
    update_hi_1_value: md.timestamp;
    update_lo_1_predicate: condition_hi;
    update_lo_1_value: md.sport_dport;
    output_dst: md.cache_flags_0;
    reduction_or_group: v4_cache_way_0;
    output_predicate: not condition_lo and not condition_hi;
    output_value: combined_predicate;
}
blackbox stateful_alu flow_v4_cache_way_0_tbl_3 {
    reg: flow_v4_cache_way_0_tbl_3;
    condition_lo: register_lo == ipv4.protocol;
    condition_hi: register_lo == 0xFF;
    update_hi_1_predicate: not condition_lo and not condition_hi;
    update_hi_2_predicate: condition_hi;
    update_hi_1_value: 1;
    update_hi_2_value: 2;
    update_lo_1_predicate: condition_hi;
    update_lo_1_value: ipv4.protocol;
    output_dst: md.cache_flags_0;
    reduction_or_group: v4_cache_way_0;
    output_predicate: condition_hi or not condition_lo;
    output_value: alu_hi;
}

@pragma stage 3
table flow_v4_cache_way_0_tbl_0 {
    actions { run_alu_v4_way_0_tbl_0; }
    default_action: run_alu_v4_way_0_tbl_0;
    size: 1;
}
table flow_v4_cache_way_0_tbl_1 {
    actions { run_alu_v4_way_0_tbl_1; }
    default_action: run_alu_v4_way_0_tbl_1;
    size: 1;
}
table flow_v4_cache_way_0_tbl_2 {
    actions { run_alu_v4_way_0_tbl_2; }
    default_action: run_alu_v4_way_0_tbl_2;
    size: 1;
}
table flow_v4_cache_way_0_tbl_3 {
    actions { run_alu_v4_way_0_tbl_3; }
    default_action: run_alu_v4_way_0_tbl_3;
    size: 1;
}
action run_alu_v4_way_0_tbl_0() {
    flow_v4_cache_way_0_tbl_0.execute_stateful_alu_from_hash( v4_cache_way_0_hash );
}
action run_alu_v4_way_0_tbl_1() {
    flow_v4_cache_way_0_tbl_1.execute_stateful_alu_from_hash( v4_cache_way_0_hash );
}
action run_alu_v4_way_0_tbl_2() {
    flow_v4_cache_way_0_tbl_2.execute_stateful_alu_from_hash( v4_cache_way_0_hash );
}
action run_alu_v4_way_0_tbl_3() {
    flow_v4_cache_way_0_tbl_3.execute_stateful_alu_from_hash( v4_cache_way_0_hash );
}

/* 
 * One instruction per ALU to clear a specific 5 tuple.
 */
blackbox stateful_alu flow_v4_cache_way_0_tbl_0_clr {
    reg: flow_v4_cache_way_0_tbl_0;
    condition_lo: register_lo == ipv4.srcAddr;
    update_lo_1_predicate: condition_lo;
    update_lo_1_value: 0xFFFFFFFF;
}
blackbox stateful_alu flow_v4_cache_way_0_tbl_1_clr {
    reg: flow_v4_cache_way_0_tbl_1;
    condition_lo: register_lo == ipv4.dstAddr;
    update_lo_1_predicate: condition_lo;
    update_lo_1_value: 0xFFFFFFFF;
}
blackbox stateful_alu flow_v4_cache_way_0_tbl_2_clr {
    reg: flow_v4_cache_way_0_tbl_2;
    condition_lo: register_lo == md.sport_dport;
    update_hi_1_predicate: condition_lo;
    update_hi_1_value: 0xFFFFFFFF;
    update_lo_1_predicate: condition_lo;
    update_lo_1_value: 0xFFFFFFFF;
}
blackbox stateful_alu flow_v4_cache_way_0_tbl_3_clr {
    reg: flow_v4_cache_way_0_tbl_3;
    condition_lo: register_lo == ipv4.protocol;
    update_lo_1_predicate: condition_lo;
    update_lo_1_value: 0xFF;
}
@pragma stage 3
table flow_v4_cache_way_0_tbl_0_clr {
    actions { run_alu_v4_way_0_tbl_0_clr; }
    default_action: run_alu_v4_way_0_tbl_0_clr;
    size: 1;
}
table flow_v4_cache_way_0_tbl_1_clr {
    actions { run_alu_v4_way_0_tbl_1_clr; }
    default_action: run_alu_v4_way_0_tbl_1_clr;
    size: 1;
}
table flow_v4_cache_way_0_tbl_2_clr {
    actions { run_alu_v4_way_0_tbl_2_clr; }
    default_action: run_alu_v4_way_0_tbl_2_clr;
    size: 1;
}
table flow_v4_cache_way_0_tbl_3_clr {
    actions { run_alu_v4_way_0_tbl_3_clr; }
    default_action: run_alu_v4_way_0_tbl_3_clr;
    size: 1;
}
action run_alu_v4_way_0_tbl_0_clr() {
    flow_v4_cache_way_0_tbl_0_clr.execute_stateful_alu_from_hash( v4_cache_way_0_hash );
}
action run_alu_v4_way_0_tbl_1_clr() {
    flow_v4_cache_way_0_tbl_1_clr.execute_stateful_alu_from_hash( v4_cache_way_0_hash );
}
action run_alu_v4_way_0_tbl_2_clr() {
    flow_v4_cache_way_0_tbl_2_clr.execute_stateful_alu_from_hash( v4_cache_way_0_hash );
}
action run_alu_v4_way_0_tbl_3_clr() {
    flow_v4_cache_way_0_tbl_3_clr.execute_stateful_alu_from_hash( v4_cache_way_0_hash );
}
control ingress {
    apply( l4_ports_to_hash );
    apply( make_timestamp );
    apply( flows_v4 ) {
        miss {
            apply( flow_v4_cache_way_0_tbl_0 );
            apply( flow_v4_cache_way_0_tbl_1 );
            apply( flow_v4_cache_way_0_tbl_2 );
            apply( flow_v4_cache_way_0_tbl_3 );
        } hit {
            apply( flow_v4_cache_way_0_tbl_0_clr );
            apply( flow_v4_cache_way_0_tbl_1_clr );
            apply( flow_v4_cache_way_0_tbl_2_clr );
            apply( flow_v4_cache_way_0_tbl_3_clr );
        }
    }
}

