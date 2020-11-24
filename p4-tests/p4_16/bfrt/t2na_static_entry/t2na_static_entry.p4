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
//#define ETHERTYPE_IPV6 0x86dd

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

struct switch_header_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
}

struct switch_metadata_t {
    bit<20> field;
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
        #if __TARGET_TOFINO__ >= 2
            pkt.advance(192);
        #else
            pkt.advance(64);
        #endif
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            //ETHERTYPE_IPV6 : accept;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
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

    action set_port_and_smac(bit<32> src_addr) {
        hdr.ethernet.src_addr = (bit<48>) src_addr;
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }

    table forward {
        key = { hdr.ethernet.ether_type : exact; }
        actions = { set_port_and_smac; }
        const default_action = set_port_and_smac(32w0x1);
        const entries = {
            ETHERTYPE_IPV4 : set_port_and_smac(32w0x2);
            //ETHERTYPE_IPV6 : set_port_and_smac(32w0x3);
        }
        size = 1;
    }

    table forward_tern {
        key = {
            hdr.ethernet.ether_type : exact;
            hdr.ipv4.src_addr : ternary;
            ig_md.field : ternary;
            hdr.ipv4.protocol : range;
        }
        actions = { set_port_and_smac; }
        const default_action = set_port_and_smac(32w0x1);
        const entries = {
            (ETHERTYPE_IPV4, 255, 0x10307, 5..5)  : set_port_and_smac(32w0x2);
            (ETHERTYPE_IPV4, 255 &&& 0xa, 0x10307, 1..10) : set_port_and_smac(32w0x3);
            (ETHERTYPE_IPV4, 255 &&& 0xa, 0x10307 &&& 0x7, 1..10) : set_port_and_smac(32w0x4);
        }
    }

    action set_md_field() {
        ig_md.field = hdr.ethernet.dst_addr[19:0];
    }

    table set_md {
        actions = {set_md_field;}
        const default_action = set_md_field();
    }

    apply {
        if (hdr.ethernet.src_addr[8:0] == 0) {
            forward.apply();
        } else {
            set_md.apply();
            forward_tern.apply();
        }
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
       SwitchEgressDeparser()) Luke;

Switch(Luke) main;