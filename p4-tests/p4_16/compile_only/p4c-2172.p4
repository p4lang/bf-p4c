/*******************************************************************************
 * MICROSOFT CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2019 Microsoft Corp.
 * All Rights Reserved.
 ******************************************************************************/

#include <core.p4>
#if __TARGET_TOFINO__ >= 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

// ---------------------------------------------------------------------------
// Headers
// ---------------------------------------------------------------------------
typedef bit<48> mac_addr_t;
typedef bit<16> ether_type_t;

header ethernet_h {
    mac_addr_t   dst_addr;
    mac_addr_t   src_addr;
    ether_type_t ether_type;
}

const ether_type_t ETHERTYPE_SHALLOWDATA = 16w0x88B7;
const ether_type_t ETHERTYPE_DEEPDATA1   = 16w0x88B8;

header data_h {
    bit<32> d00;
}

struct header_t {
    ethernet_h ethernet;
    data_h d00;
}

struct metadata_t {
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1       : parse_resubmit;
            default : parse_port_metadata;
        }
    }

    state parse_resubmit {
        // skip for now
        transition parse_port_metadata;
    }

    state parse_port_metadata {
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
            ETHERTYPE_SHALLOWDATA : parse_shallowdata;
            ETHERTYPE_DEEPDATA1    : parse_deepdata1;
            default : accept;
        }
    }

#ifdef CASE_FIX
    state parse_deepdata1 {
        pkt.advance(512);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_DEEPDATA1: parse_deepdata2;
        }
    }
    
    state parse_deepdata2 {
        pkt.advance(512);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_DEEPDATA1: parse_deepdata3;
        }
    }
    
    state parse_deepdata3 {
        pkt.advance(512);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_DEEPDATA1: parse_deepdata4;
        }
    }
    
    state parse_deepdata4 {
        pkt.advance(512);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_DEEPDATA1: parse_deepdata5;
        }
    }
    
    state parse_deepdata5 {
        pkt.advance(512);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_DEEPDATA1: parse_deepdata6;
        }
    }
      
    state parse_deepdata6 {
        pkt.advance(16);
        transition parse_shallowdata;
    }
#else
    state parse_deepdata1 {
        pkt.advance(2576);
        transition parse_shallowdata;
    }
#endif
    state parse_shallowdata {
        pkt.extract(hdr.d00);
        transition accept;
    }

}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    apply {
        pkt.emit(hdr);
    }
}

// ---------------------------------------------------------------------------
// Ingress Control
// ---------------------------------------------------------------------------
control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    apply {
        if ((hdr.ethernet.ether_type == ETHERTYPE_SHALLOWDATA) ||
            (hdr.ethernet.ether_type == ETHERTYPE_DEEPDATA1)) {
            // send out selected port
            ig_tm_md.ucast_egress_port = 0;
            ig_dprsr_md.drop_ctl = 0;
        } else {
            // drop
            ig_dprsr_md.drop_ctl = 1;
        }
    }
}


//
// egress
//
parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

control SwitchEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md) {
    apply {}
}

control SwitchEgress(
    inout header_t hdr,
    inout metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}


Pipeline(
    SwitchIngressParser(),
    SwitchIngress(),
    SwitchIngressDeparser(),
    SwitchEgressParser(),
    SwitchEgress(),
    SwitchEgressDeparser()) pipe;

Switch(pipe) main;
