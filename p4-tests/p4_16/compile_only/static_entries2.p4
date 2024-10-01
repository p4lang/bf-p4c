/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2016 Barefoot Networks, Inc.
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
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

#include <core.p4>
#include <tna.p4>

#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_IPV6 0x86dd

typedef bit<32> src_addr_t;

struct switch_ingress_flags_t {
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
    bool link_local;
    bool routed;
    bool acl_deny;
    bool racl_deny;
    bool port_vlan_miss;
    bool rmac_hit;
    bool myip;
    bool glean;
    bool storm_control_drop;
    bool qos_policer_drop;
    bool flood_to_multicast_routers;

    // Add more flags here.
}

header ethernet_h {
    bit<128> ipv6_dst_addr;
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
    bit<16> range_type;
    bit<16> lpm_type;
    switch_ingress_flags_t flags;
    bit<3> pad;
}

struct switch_metadata_t {
    bool ipv4_checksum_error;
}

struct switch_header_t {
    ethernet_h ethernet;
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(64);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Egress parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(packet_out pkt,
                              inout switch_header_t hdr,
                              in switch_metadata_t ig_md,
                              in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply { pkt.emit(hdr); }
}

// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(packet_out pkt,
                             inout switch_header_t hdr,
                             in switch_metadata_t eg_md,
                             in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}


control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    // Exercising typedef, bool in action
    action set_port_and_smac(src_addr_t src_addr, PortId_t port, bool link_local) {
        hdr.ethernet.src_addr = (bit<48>) src_addr;
        ig_intr_tm_md.ucast_egress_port = port;
        hdr.ethernet.flags.link_local = link_local;
    }

    table forward {
        key = {
            ig_md.ipv4_checksum_error : ternary;
            hdr.ethernet.ether_type : ternary;
            hdr.ethernet.ipv6_dst_addr : ternary; // >64 bits ternary 
            hdr.ethernet.src_addr[31:24] : ternary;
            hdr.ethernet.range_type : range;
            // Backend does not support ranges >20 bits, although it should? 
            // Error: Currently in p4c, the
            // table forward_0 cannot perform a range match on key
            // ingress::hdr.ethernet.ipv6_src_addr as the key does not fit in
            // under 5 PHV nibbles
            // hdr.ethernet.ipv6_src_addr : range;
            //
            // LPM entries are not supported as we cannot specify prefix length
            // with value on static entry
            // hdr.ethernet.lpm_type: lpm;
        }
        actions = { set_port_and_smac; }
        const default_action = set_port_and_smac(32w0xFF, 0x1, false);
        const entries = {
            (_, 1, 150 &&& 0xffff0000ffff0000ffff0000ffff0000,  255 &&& 0xf0, _ /*, _ */) : set_port_and_smac(32w0xFA, 0x2, true); // priority 0
            (true, 2, _, _, _ /*, _ */) : set_port_and_smac(32w0xFB, 0x3, true);          // priority 1
            (false, 3, _, _, 1..9 /*, 8 */) : set_port_and_smac(32w0xFC, 0x4, false);       // priority 2
        }
    }

    apply {
        forward.apply();
    }
}


control SwitchEgress(
        inout switch_header_t hdr,
        inout switch_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}

Pipeline(SwitchIngressParser(),
       SwitchIngress(),
       SwitchIngressDeparser(),
       SwitchEgressParser(),
       SwitchEgress(),
       SwitchEgressDeparser()) pipe0;

Switch(pipe0) main;
