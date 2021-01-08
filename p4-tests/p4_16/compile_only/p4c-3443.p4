#include<tna.p4>
#include<core.p4>
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2019-present Barefoot Networks, Inc.
 *
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.  Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/




typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_IPV4 = 4;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;
const ip_protocol_t IP_PROTOCOLS_IPV6 = 41;
const ip_protocol_t IP_PROTOCOLS_SRV6 = 43;
const ip_protocol_t IP_PROTOCOLS_NONXT = 59;

typedef bit<16> udp_port_t;
const udp_port_t UDP_PORT_GTPC = 2123;
const udp_port_t UDP_PORT_GTPU = 2152;
const udp_port_t UDP_PORT_VXLAN = 4789;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    bit<16> ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<6 > dscp;
    bit<2 > ecn;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_length;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type_;
    bit<8> code;
    bit<16> hdr_checksum;
}

// Segment Routing Extension (SRH) -- IETFv14
// See https://tools.ietf.org/html/draft-ietf-6man-segment-routing-header-14.
header srh_h {
    bit<8> next_hdr;
    bit<8> hdr_ext_len;
    bit<8> routing_type;
    bit<8> segment_left;
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}

header srh_segment_list_t {
    bit<128> sid;
}

// GTP User Data Messages (GTPv1)
header gtpu_h {
    bit<3> version;
    bit<1> pt; // Protocol type
    bit<1> reserved;
    bit<1> e; // Extension header flag
    bit<1> s; // Sequence number flag
    bit<1> pn; // N-PDU number flag
    bit<8> message_type;
    bit<16> message_len;
    bit<32> teid; // Tunnel endpoint id */
}
# 21 "/mnt/main.p4" 2

// Common types
typedef bit<16> bd_t;
typedef bit<16> vrf_t;
typedef bit<16> nexthop_t;
typedef bit<16> ifindex_t;

typedef bit<8> bypass_t;
const bypass_t BYPASS_L2 = 8w0x01;
const bypass_t BYPASS_L3 = 8w0x02;
const bypass_t BYPASS_ACL = 8w0x04;
// Add more bypass flags here.
const bypass_t BYPASS_ALL = 8w0xff;


typedef bit<128> srv6_sid_t;
struct srv6_metadata_t {
    srv6_sid_t sid; // SRH[SL]
    bit<16> rewrite; // Rewrite index
    bool psp; // Penultimate Segment Pop
    bool usp; // Ultimate Segment Pop
    bool decap;
    bool encap;
}

struct ingress_metadata_t {
    bool checksum_err;
    bd_t bd;
    vrf_t vrf;
    nexthop_t nexthop;
    ifindex_t ifindex;
    ifindex_t egress_ifindex;
    bypass_t bypass;
    srv6_metadata_t srv6;
}

struct egress_metadata_t {
    srv6_metadata_t srv6;
}

header bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress.
    bit<16> rewrite;
    bit<1> psp; // Penultimate Segment Pop
    bit<1> usp; // Ultimate Segment Pop
    bit<1> decap;
    bit<1> encap;
    bit<4> pad;
}

struct lookup_fields_t {
    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;

    bit<4> ip_version;
    bit<8> ip_proto;
    bit<8> ip_ttl;
    bit<8> ip_dscp;

    bit<20> ipv6_flow_label;
    ipv4_addr_t ipv4_src_addr;
    ipv4_addr_t ipv4_dst_addr;
    ipv6_addr_t ipv6_src_addr;
    ipv6_addr_t ipv6_dst_addr;
}

struct header_t {
    bridged_metadata_t bridged_md;
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
    ipv4_h ipv4;
    ipv6_h ipv6;
    srh_h srh;
    srh_segment_list_t[5] srh_segment_list;
    tcp_h tcp;
    udp_h udp;
    gtpu_h gtpu;
    ethernet_h inner_ethernet;
    ipv6_h inner_ipv6;
    srh_h inner_srh;
    srh_segment_list_t[5] inner_srh_segment_list;
    ipv4_h inner_ipv4;
    tcp_h inner_tcp;
    udp_h inner_udp;

    // Add more headers here.
}

# 1 "/mnt/parde.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2018-2019 Barefoot Networks, Inc.
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 ******************************************************************************/

parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }

    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition accept;
    }
}

parser TofinoEgressParser(
        packet_in pkt,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}


// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() ipv4_checksum;
    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            ETHERTYPE_VLAN : parse_vlan;
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);
        ig_md.checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            IP_PROTOCOLS_SRV6 : parse_srh;
            IP_PROTOCOLS_IPV6 : parse_inner_ipv6;
            IP_PROTOCOLS_IPV4 : parse_inner_ipv4;
            default : accept;
        }
    }

    state parse_srh {
        pkt.extract(hdr.srh);
        transition parse_srh_segment_0;
    }

//FIXME(msharif): ig_md.srv6.sid is NOT set correctly.
# 135 "/mnt/parde.p4"
state parse_srh_segment_0 { pkt.extract(hdr.srh_segment_list[0]); transition select(hdr.srh.last_entry) { 0 : parse_srh_next_header; default : parse_srh_segment_1; } } state set_active_segment_0 { transition parse_srh_segment_1; }
state parse_srh_segment_1 { pkt.extract(hdr.srh_segment_list[1]); transition select(hdr.srh.last_entry) { 1 : parse_srh_next_header; default : parse_srh_segment_2; } } state set_active_segment_1 { transition parse_srh_segment_2; }
state parse_srh_segment_2 { pkt.extract(hdr.srh_segment_list[2]); transition select(hdr.srh.last_entry) { 2 : parse_srh_next_header; default : parse_srh_segment_3; } } state set_active_segment_2 { transition parse_srh_segment_3; }
state parse_srh_segment_3 { pkt.extract(hdr.srh_segment_list[3]); transition select(hdr.srh.last_entry) { 3 : parse_srh_next_header; default : parse_srh_segment_4; } } state set_active_segment_3 { transition parse_srh_segment_4; }

    state parse_srh_segment_4 {
        pkt.extract(hdr.srh_segment_list[4]);
        transition parse_srh_next_header;
    }

    state set_active_segment_4 {
        ig_md.srv6.sid = hdr.srh_segment_list[4].sid;
        transition parse_srh_next_header;
    }

    state parse_srh_next_header {
        transition select(hdr.srh.next_hdr) {
            IP_PROTOCOLS_IPV6 : parse_inner_ipv6;
            IP_PROTOCOLS_IPV4 : parse_inner_ipv4;
            IP_PROTOCOLS_SRV6 : parse_inner_srh;
            IP_PROTOCOLS_NONXT : accept;
            default : reject;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            UDP_PORT_GTPU: parse_gtpu;
            default: accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }


    state parse_gtpu {
        pkt.extract(hdr.gtpu);
        bit<4> version = pkt.lookahead<bit<4>>();
        transition select(version) {
            4w4 : parse_inner_ipv4;
            4w6 : parse_inner_ipv6;
        }
    }


    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol) {
            IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
            IP_PROTOCOLS_SRV6 : parse_inner_srh;
            default : accept;
        }
    }

    state parse_inner_srh {
        pkt.extract(hdr.inner_srh);
        transition accept;
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition select(hdr.inner_udp.dst_port) {
            default: accept;
        }
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    apply {
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.srh);
        pkt.emit(hdr.srh_segment_list);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.gtpu);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_srh);
        pkt.emit(hdr.inner_srh_segment_list);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
    }
}

// ---------------------------------------------------------------------------
// Egress parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        transition parse_bridged_metadata;
    }

    state parse_bridged_metadata {
        pkt.extract(hdr.bridged_md);
        eg_md.srv6.rewrite = hdr.bridged_md.rewrite;
        eg_md.srv6.psp = (bool) hdr.bridged_md.psp;
        eg_md.srv6.usp = (bool) hdr.bridged_md.psp;
        eg_md.srv6.encap = (bool) hdr.bridged_md.encap;
        eg_md.srv6.decap = (bool) hdr.bridged_md.decap;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            ETHERTYPE_VLAN : parse_vlan;
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_UDP : parse_udp;
            IP_PROTOCOLS_SRV6 : parse_srh;
            IP_PROTOCOLS_IPV6 : parse_inner_ipv6;
            IP_PROTOCOLS_IPV4 : parse_inner_ipv4;
            default : accept;
        }
    }

    state parse_srh {
        pkt.extract(hdr.srh);
        transition parse_srh_segment_0;
    }
# 326 "/mnt/parde.p4"
state parse_srh_segment_0 { pkt.extract(hdr.srh_segment_list[0]); transition select(hdr.srh.last_entry) { 0 : parse_srh_next_header; default : parse_srh_segment_1; } }
state parse_srh_segment_1 { pkt.extract(hdr.srh_segment_list[1]); transition select(hdr.srh.last_entry) { 1 : parse_srh_next_header; default : parse_srh_segment_2; } }
state parse_srh_segment_2 { pkt.extract(hdr.srh_segment_list[2]); transition select(hdr.srh.last_entry) { 2 : parse_srh_next_header; default : parse_srh_segment_3; } }
state parse_srh_segment_3 { pkt.extract(hdr.srh_segment_list[3]); transition select(hdr.srh.last_entry) { 3 : parse_srh_next_header; default : parse_srh_segment_4; } }

    state parse_srh_segment_4 {
        pkt.extract(hdr.srh_segment_list[4]);
        transition parse_srh_next_header;
    }

    state parse_srh_next_header {
        transition select(hdr.srh.next_hdr) {
            IP_PROTOCOLS_IPV6 : parse_inner_ipv6;
            IP_PROTOCOLS_IPV4 : parse_inner_ipv4;
            IP_PROTOCOLS_SRV6 : parse_inner_srh;
            IP_PROTOCOLS_NONXT : accept;
            default : reject;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            UDP_PORT_GTPU: parse_gtpu;
            default: accept;
        }
    }

    state parse_gtpu {
        pkt.extract(hdr.gtpu);
        bit<4> version = pkt.lookahead<bit<4>>();
        transition select(version) {
            4w4 : parse_inner_ipv4;
            4w6 : parse_inner_ipv6;
        }
    }


    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol) {
            IP_PROTOCOLS_UDP : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            IP_PROTOCOLS_UDP : parse_inner_udp;
            IP_PROTOCOLS_SRV6 : parse_inner_srh;
            default : accept;
        }
    }

    state parse_inner_srh {
        pkt.extract(hdr.inner_srh);
        transition accept;
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition select(hdr.inner_udp.dst_port) {
            default: accept;
        }
    }
}

// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    Checksum() ipv4_checksum;

    apply {
        hdr.ipv4.hdr_checksum = ipv4_checksum.update(
                {hdr.ipv4.version,
                 hdr.ipv4.ihl,
                 hdr.ipv4.dscp,
                 hdr.ipv4.ecn,
                 hdr.ipv4.total_len,
                 hdr.ipv4.identification,
                 hdr.ipv4.flags,
                 hdr.ipv4.frag_offset,
                 hdr.ipv4.ttl,
                 hdr.ipv4.protocol,
                 hdr.ipv4.src_addr,
                 hdr.ipv4.dst_addr});

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.srh);
        pkt.emit(hdr.srh_segment_list);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.gtpu);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_srh);
        pkt.emit(hdr.inner_srh_segment_list);
        pkt.emit(hdr.inner_udp);
    }
}
# 111 "/mnt/main.p4" 2
# 128 "/mnt/main.p4"
control ProcessEgressDscpAndDrop(inout header_t hdr, inout egress_metadata_t meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_prsr_md, inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md, inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {

    Counter<bit<32>,bit<8>>(256, CounterType_t.PACKETS_AND_BYTES) egress_dscp_counter;

    action egress_dscp_counter_increase_action() {
        egress_dscp_counter.count((bit<8>)(hdr.ipv4.dscp));
    }

    action drop_packet() {
        eg_dprsr_md.drop_ctl = 5;
    }

    table egress_dscp_and_drop {
        key = {
            hdr.ipv4.dscp : exact;
        }
        actions = {
            egress_dscp_counter_increase_action;
            drop_packet;
        }

        size = 256;
    }
    apply{
        egress_dscp_and_drop.apply();
    }
}

control SwitchIngress(inout header_t hdr, inout ingress_metadata_t meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    apply {
    }
}

control SwitchEgress(inout header_t hdr, inout egress_metadata_t meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_prsr_md, inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md, inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {
    ProcessEgressDscpAndDrop() egress_dscp_and_drop;

    apply {
        egress_dscp_and_drop.apply(hdr,meta,eg_intr_md,eg_prsr_md,eg_dprsr_md,eg_oport_md);
    }
}

//----------------------------------------------------------------------

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

//----------------------------------------------------------------------

Switch(pipe) main;

//----------------------------------------------------------------------
