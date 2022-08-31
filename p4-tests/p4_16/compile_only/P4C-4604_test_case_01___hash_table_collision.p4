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

#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif


header ethernet_h {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
}
header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}
header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_length;
    bit<16> checksum;
}
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

struct header_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    udp_h udp;
    vxlan_h vxlan;
    ipv4_h inner_ipv4;
    udp_h inner_udp;
}



#define GROUP_TABLE_SIZE 4096
#define NH_SIZE 34816
#define MAX_GROUP_SIZE 128

struct tunnel_metadata_t {
    bit<32> nexthop;
}

struct five_tuple_t {
    bit<32> sip;
    bit<32> dip;
    bit<16> l4_sport;
    bit<16> l4_dport;
    bit<8> ip_proto;
}
struct metadata_t {
    tunnel_metadata_t tunnel;
    five_tuple_t inner_five_tuple;
    five_tuple_t outer_five_tuple;
}

parser PacketParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t meta) {

    state start {
        pkt.extract(hdr.ethernet);
        transition parse_ipv4;
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        meta.outer_five_tuple.sip = hdr.ipv4.src_addr;
        meta.outer_five_tuple.dip = hdr.ipv4.dst_addr;
        meta.outer_five_tuple.ip_proto = hdr.ipv4.protocol;
        transition parse_udp;
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        meta.outer_five_tuple.l4_sport = hdr.udp.src_port;
        meta.outer_five_tuple.l4_dport = hdr.udp.dst_port;
        transition parse_vxlan;
    }
    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_inner_ipv4;
    }
    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        meta.inner_five_tuple.sip = hdr.inner_ipv4.src_addr;
        meta.inner_five_tuple.dip = hdr.inner_ipv4.dst_addr;
        meta.inner_five_tuple.ip_proto = hdr.inner_ipv4.protocol;
        transition parse_inner_udp;
    }
    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        meta.inner_five_tuple.l4_sport = hdr.inner_udp.src_port;
        meta.inner_five_tuple.l4_dport = hdr.inner_udp.dst_port;
        transition accept;
    } 
}

parser IngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    
    PacketParser() packet_parser;
    
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
        packet_parser.apply(pkt, hdr, ig_md);
        transition accept;
    }
}


control ExampleA(inout header_t hdr, inout metadata_t meta) {
    action example_tbl_a_action(bit<32> tunnel_nexthop) {
        meta.tunnel.nexthop = tunnel_nexthop;
    }
    table example_tbl_a {
        key = {
            hdr.vxlan.vni : exact;
            hdr.inner_ipv4.dst_addr : exact;
        }
        actions = {
            example_tbl_a_action;
        }
        proxy_hash = Hash<bit<16>>(HashAlgorithm_t.CRC16);
        size = 1157120;
    }
    apply {
        example_tbl_a.apply();
    }
}
control IngressPacketProcess(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    ExampleA() example_a;
    apply {
        example_a.apply(hdr, ig_md);
    }
}

control IngressDeParser(packet_out pkt,
                        inout header_t hdr,
                        in metadata_t ig_md,
                        in ingress_intrinsic_metadata_for_deparser_t
                          ig_intr_dprsr_md) {
    apply {
        pkt.emit(hdr);
    }
}

parser EgressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    
    PacketParser() packet_parser;
    
    state start {
        pkt.extract(eg_intr_md);
        packet_parser.apply(pkt, hdr, eg_md);
        transition accept;
    }
}

control ExampleB(inout header_t hdr, inout metadata_t meta) {
    Hash<bit<16>>(HashAlgorithm_t.CRC16) selector_hash;
    ActionProfile(NH_SIZE) group_selector;
    ActionSelector(group_selector, selector_hash, SelectorMode_t.FAIR, MAX_GROUP_SIZE, GROUP_TABLE_SIZE) group_action_profile;
    action example_tbl_b_action(bit<32> nexthop) {
        hdr.ipv4.dst_addr = nexthop;
    }
    table example_tbl_b {
        key = {
            meta.tunnel.nexthop : exact;
            meta.inner_five_tuple.dip : selector;
            meta.inner_five_tuple.l4_dport : selector;
            meta.inner_five_tuple.sip : selector;
            meta.inner_five_tuple.l4_sport : selector;
            meta.inner_five_tuple.ip_proto : selector;
        }
        actions = {
            example_tbl_b_action;
        }
        implementation = group_action_profile;
        size = GROUP_TABLE_SIZE;
    }
    apply {
        example_tbl_b.apply();
    }
}


control EgressPacketProcess(
        inout header_t hdr,
        inout metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    ExampleB() example_b;
    apply {
        example_b.apply(hdr, eg_md);
    }
}
control EgressDeParser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
        pkt.emit(hdr);
    }
}
Pipeline(IngressParser(),
        IngressPacketProcess(),
        IngressDeParser(),
        EgressParser(),
        EgressPacketProcess(),
        EgressDeParser()) pipe;

//----------------------------------------------------------------------
Switch(pipe) main;

