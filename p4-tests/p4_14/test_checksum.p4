
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

/*
 * This sample program hightlights the use of checksum on Tofino
 * Not tested on BM (v1 or v2).
 */

/* P4TEST_IGNORE_STDERR */

#ifdef __TARGET_TOFINO__
#include <tofino/intrinsic_metadata.p4>
#endif

#define IP_PROTOCOLS_IPHL_TCP 0x506
#define IP_PROTOCOLS_IPHL_UDP 0x511
#define UDP_PORT_VXLAN 4789
#define UDP_PORT_GENV 6081

#define ETHERTYPE_IPV4         0x0800
#define ETHERTYPE_ETHERNET     0x6558

#define PORTMAP_TABLE_SIZE     288

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header ethernet_t ethernet;
header ethernet_t inner_ethernet;

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

// This ensures hdrChecksum and protocol fields are allocated to different
// containers so that the deparser can calculate the IPv4 checksum correctly.
// We are enforcing a stronger constraint than necessary. In reality, even if
// protocol and hdrChecksum are allocated to the same 32b container, it is OK
// as long as hdrChecksum occupies the first or last 16b. It should just not be
// in the middle of the 32b container. But, there is no pragma to enforce such
// a constraint precisely. So, using pa_fragment.
// @pragma pa_fragment ingress ipv4.hdrChecksum
// @pragma pa_fragment egress ipv4.hdrChecksum

header ipv4_t ipv4;
header ipv6_t ipv6;
header ipv4_t inner_ipv4;

header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo   : 32;
        ackNo   : 32;
        dataOffset : 4;
        res : 4;
        flags : 8;
        window : 16;
        checksum : 16;
        urgentPtr : 16;

    }
}


// @pragma pa_fragment ingress tcp.checksum
// @pragma pa_fragment egress tcp.checksum
header tcp_t tcp;

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        len : 16;
        checksum : 16;
    }
}

// @pragma pa_fragment ingress udp.checksum
// @pragma pa_fragment egress udp.checksum
header udp_t udp;

/*
 * This checksum does not have
 * a parser counterpart, because of the
 * absence of payload
 */

field_list ipv4_cksum_fields {
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

field_list_calculation ipv4_csum {
    input {
        ipv4_cksum_fields;
    }
    algorithm : csum16;
    output_width : 16;
}

// keep separate calculation object for egress for testing
field_list_calculation ipv4_csum_update {
    input {
        ipv4_cksum_fields;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field ipv4.hdrChecksum  {
    verify ipv4_csum;
    update ipv4_csum_update;
}

/*
 * Checksum for UDP
 */
header_type l4_csum_meta_t {
    fields {
        len_delta : 16;
    }
}

metadata l4_csum_meta_t l4_csum_len;

field_list l4_checksum_list_v4 {
    ipv4.srcAddr;
    ipv4.dstAddr;
    8'0;
    ipv4.protocol;
    // l4 protocol len is not included - since this is incremental checksum
    // len is not needed as long as we do not modify it
    l4_csum_len.len_delta;
}
field_list udp_checksum_list {
    udp.srcPort;
    udp.dstPort;
    udp.len;    
    udp.checksum;    
}
field_list checksum_payload_list {
    payload;
}

field_list_calculation udp_checksum_v4 {
    input {
        l4_checksum_list_v4;
        udp_checksum_list;
        checksum_payload_list;
    }
    algorithm : csum16;
    output_width : 16;
}

field_list l4_checksum_list_v6 {
    ipv6.srcAddr;
    ipv6.dstAddr;
    24'0;
    ipv6.nextHdr;
}

field_list_calculation udp_checksum_v6 {
    input {
        l4_checksum_list_v6;
        udp_checksum_list;
        checksum_payload_list;
    }
    algorithm : csum16;
    output_width : 16;
}

header_type csum_ctrl_t {
    fields {
        v4_tcp_enable : 1;
        v6_tcp_enable : 1;
        v4_udp_enable : 1;
        v6_udp_enable : 1;
        inner_v4_udp_enable : 1;
    }
}
metadata csum_ctrl_t csum_ctrl;

calculated_field udp.checksum {
    update udp_checksum_v4 if (csum_ctrl.v4_udp_enable == 1);
    update udp_checksum_v6 if (csum_ctrl.v6_udp_enable == 1);
}

field_list tcp_checksum_list {
    tcp.srcPort;
    tcp.dstPort;
    tcp.seqNo;
    tcp.ackNo;
    tcp.dataOffset;
    tcp.res;
    tcp.flags;
    tcp.window;
    tcp.urgentPtr;
}

field_list_calculation tcp_checksum_v4 {
    input {
        l4_checksum_list_v4;
        tcp_checksum_list;
        checksum_payload_list;
    }
    algorithm : csum16;
    output_width : 16;
}

field_list_calculation tcp_checksum_v6 {
    input {
        l4_checksum_list_v6;
        tcp_checksum_list;
        checksum_payload_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field tcp.checksum  {
    update tcp_checksum_v4 if (csum_ctrl.v4_tcp_enable == 1);
    update tcp_checksum_v6 if (csum_ctrl.v6_tcp_enable == 1);
}

header_type vlan_tag_t {
    fields {
        tag : 16;
        etherType : 16;
    }
}

header vlan_tag_t  vlan_hdr;

parser start {
    extract(ethernet);
    return select(latest.etherType) {
        0x0800: parse_ipv4;
        0x86dd: parse_ipv6;
        0x8100: parse_vlan;
        default: ingress;
    }
}

parser parse_vlan {
    extract(vlan_hdr);
    return select(latest.etherType) {
        0x800: parse_ipv4;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.fragOffset, latest.ihl, latest.protocol) {
        IP_PROTOCOLS_IPHL_TCP: parse_tcp;
        IP_PROTOCOLS_IPHL_UDP: parse_udp;
        default: ingress;
    }
}

parser parse_ipv6 {
    extract(ipv6);
    return select(latest.nextHdr) {
        IP_PROTOCOLS_IPHL_TCP: parse_tcp;
        IP_PROTOCOLS_IPHL_UDP: parse_udp;
        default: ingress;
    }
}

parser parse_tcp {
    extract(tcp);
    // just for testing
    return select(latest.dstPort) {
        0x4118: parse_inner_ipv4;
        default: ingress;
    }
}

parser parse_udp {
    extract(udp);
    return select(latest.dstPort) {
        0x4118: parse_vxlan;
        default: ingress;
    }
}

header_type vxlan_t {
    fields {
        flags : 8;
        reserved : 24;
        vni : 24;
        reserved2 : 8;
    }
}

header vxlan_t vxlan;

parser parse_vxlan {
    extract(vxlan);
    return parse_inner_ethernet;
}
parser parse_inner_ethernet {
    extract(inner_ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_inner_ipv4;
        default: ingress;
    }
}
parser parse_inner_ipv4 {
    extract(inner_ipv4);
    return select(latest.fragOffset, latest.ihl, latest.protocol) {
        IP_PROTOCOLS_IPHL_TCP: parse_inner_tcp;
        IP_PROTOCOLS_IPHL_UDP: parse_inner_udp;
        default: ingress;
    }
}

header tcp_t inner_tcp;

parser parse_inner_tcp {
    extract(inner_tcp);
    return ingress;
}

header udp_t inner_udp;

field_list inner_l4_checksum_list_v4 {
    inner_ipv4.srcAddr;
    inner_ipv4.dstAddr;
    8'0;
    inner_ipv4.protocol;
    // l4 protocol len is not included - since this is incremental checksum
    // len is not needed as long as we do not modify it
}

field_list inner_udp_checksum_list {
    inner_udp.srcPort;
    inner_udp.dstPort;
    inner_udp.len;    
    inner_udp.checksum;    
}

field_list_calculation inner_udp_checksum_v4 {
    input {
        inner_l4_checksum_list_v4;
        inner_udp_checksum_list;
        checksum_payload_list;
    }
    algorithm : csum16;
    output_width : 16;
}
calculated_field inner_udp.checksum {
    update inner_udp_checksum_v4 if (csum_ctrl.inner_v4_udp_enable == 1);
}

parser parse_inner_udp {
    extract(inner_udp);
    return ingress;
}

field_list inner_ipv4_cksum_fields {
    inner_ipv4.version;
    inner_ipv4.ihl;
    inner_ipv4.diffserv;
    inner_ipv4.totalLen;
    inner_ipv4.identification;
    inner_ipv4.flags;
    inner_ipv4.fragOffset;
    inner_ipv4.ttl;
    inner_ipv4.protocol;
    inner_ipv4.srcAddr;
    inner_ipv4.dstAddr;
}

field_list_calculation inner_ipv4_csum {
    input {
        inner_ipv4_cksum_fields;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field inner_ipv4.hdrChecksum  {
    // ERROR - too many checksum engines
    // verify inner_ipv4_csum;
    update inner_ipv4_csum;
}

action nop() {
}

action nhop_set(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
    //add_to_field(ipv4.ttl, -1);
    //add_to_field(tcp_csum.tcp_len, port);
    // Test handling of mirror pov bits
    clone_ingress_pkt_to_egress(100);
}

/* Use phase 0 table to set the checksum metadata for TCP pseudo length */

action set_pseudolen() {
    //add(tcp_csum.tcp_len, ipv4.totalLen, -20);
}

table ingress_port_mapping {
    reads {
        ig_intr_md.ingress_port : exact;
        ig_intr_md_from_parser_aux.ingress_parser_err : exact;
    }
    actions {
        //set_pseudolen;
        nop;
    }
    size : PORTMAP_TABLE_SIZE;
}

table ip_nhop {
    reads {
        ipv4.dstAddr: exact;
    }
    actions {
        nhop_set;
        nop;
    }
    size : 512;
}

/* Main control flow */
control ingress {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(ingress_port_mapping);
    }
    apply(ip_nhop);
}

action ip_header_modify() {
    add_to_field(ipv4.ttl, -1);
    modify_field(ipv4.hdrChecksum, 0);
    // Test handling of mirror pov bits
    clone_egress_pkt_to_egress(200);
}

table ip_hdr_update {
    actions {
        ip_header_modify;
    }
    size : 1;
}

control egress {
    apply(ip_hdr_update);
}
