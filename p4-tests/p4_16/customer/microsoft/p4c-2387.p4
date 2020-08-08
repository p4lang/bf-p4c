/********************************************************
*                                                       *
*   Copyright (C) Microsoft. All rights reserved.       *
*                                                       *
********************************************************/

//
// ALU op selection bug report example.
//

#include <core.p4>

#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

typedef bit<32> worker_bitmap_t;
typedef bit<17> pool_index_t;
typedef bit<8> num_workers_t;
typedef bit<16> drop_random_value_t;

enum bit<2> packet_type_t {
    IGNORE  = 0x0,
    CONSUME = 0x1,
    HARVEST = 0x2,
    EGRESS  = 0x3
}

header switchml_md_h {
    MulticastGroupId_t mgid;

    @padding
    bit<7> pad2;
    
    PortId_t ingress_port;

    @padding
    bit<5> pad;

    // what should we do with this packet?
    packet_type_t packet_type;

    // which pool element are we talking about?
    pool_index_t pool_index; // Index of pool element, including both sets.


    // random number used to simulated packet drops
    drop_random_value_t drop_random_value;

    // 0 if packet is first packet; non-zero if retransmission
    worker_bitmap_t map_result;

    // 0 if first packet, 1 if last packet
    num_workers_t first_last_flag;

    // bitmaps before and after the current worker is ORed in
    worker_bitmap_t worker_bitmap_before;
    worker_bitmap_t worker_bitmap_after;
}

header dummy_h {
    bit<32> a;
    bit<32> b;
}


typedef bit<48> mac_addr_t;
typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_DUMMY = 16w0x88b5;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16>    ether_type;
}

struct header_t {
    ethernet_h  ethernet;
    dummy_h dummy;
}

struct ingress_metadata_t {
}

struct egress_metadata_t  {
    switchml_md_h switchml_md;
}


//
// Ingress parser
//

// empty
parser IngressParser(
    packet_in pkt,
    out header_t hdr,
    out ingress_metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        transition accept;
    }
}

// empty
control Ingress(
    inout header_t hdr,
    inout ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    apply {
    }
}

// empty
control IngressDeparser(
    packet_out pkt,
    inout header_t hdr,
    in ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    apply {
    }
}

//
// Problem occurs here
//
parser EgressParser(
    packet_in pkt,
    out header_t hdr,
    out egress_metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);

        // BUG: problem occurs when merging these stages
        transition parse_metadata;

        // // if I replace the transition with this, the bug goes away
        // transition select(eg_intr_md.egress_port) {
        //     0 : parse_metadata;
        //     _ : parse_metadata;
        // }
    }

    state parse_metadata {
        pkt.extract(eg_md.switchml_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

control Egress(
    inout header_t hdr,
    inout egress_metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {

    apply {
        // BUG: the bug only shows up when I reference the switchml_md header here.
        // do some stuff to ensure the headers aren't optimized away..
        if (eg_md.switchml_md.packet_type == packet_type_t.EGRESS) {
            hdr.dummy.setValid();
            hdr.dummy.a = 23w0 ++ eg_intr_md.egress_port;
            hdr.dummy.b = 16w0 ++ eg_intr_md.egress_rid;
        }
    }
}

control EgressDeparser(
    packet_out pkt,
    inout header_t hdr,
    in egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {

    apply {
        pkt.emit(hdr);
    }
}

Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()) pipe;

Switch(pipe) main;

