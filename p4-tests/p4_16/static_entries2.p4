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

header ethernet_h {
    bit<128> ipv6_dst_addr;
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
    bit<16> range_type;
    bit<16> lpm_type;
}

struct switch_header_t {
    ethernet_h ethernet;
}

struct switch_metadata_t { }

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

    action set_port_and_smac(bit<32> src_addr, bit<9> port) {
        hdr.ethernet.src_addr = (bit<48>) src_addr;
        ig_intr_tm_md.ucast_egress_port = port;
    }

    table forward {
        key = {
            hdr.ethernet.ether_type : ternary;
            // hdr.ethernet.ipv6_dst_addr : ternary; // >64 bits Not supported
            // in json generation and driver json parsing
            hdr.ethernet.src_addr[31:24] : ternary;
            hdr.ethernet.range_type : range;
            // hdr.ethernet.lpm_type: lpm; // Not supported as we cannot specify
            // prefix length with value on static entry
        }
        actions = { set_port_and_smac; }
        const default_action = set_port_and_smac(32w0xFF, 9w0x1);
        const entries = {
            (1 /*, 150 &&& 0xffff00 */,  255 &&& 0xf0, _ /*, _ */) : set_port_and_smac(32w0xFA, 9w0x2); // priority 0
            (2 /*, _ */, _, _ /*, _ */) : set_port_and_smac(32w0xFB, 9w0x3);          // priority 1
            (3 /*, _ */, _, 1..9 /*, 8 */) : set_port_and_smac(32w0xFC, 9w0x4);       // priority 2
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
