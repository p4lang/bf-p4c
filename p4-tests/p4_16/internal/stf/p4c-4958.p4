/*
 * Tests the complete exclusion of a match field from the exact match hash calculation.
 *
 * The same P4 code is used in gtest MaskExactMatchHashBitsTest.TotalFieldExclusion
 * to validate the resources allocated.
 */

#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ethertype;
}

header hdr32b_t {
    bit<10> f1;
    bit<2> f2;
    bit<4> f3;
    bit<32> f4;
};

struct headers_t {
    ethernet_t eth;
    hdr32b_t h1;
}

struct metadata_t {
}

parser IngressParser(
    packet_in pkt,
    out headers_t hdr,
    out metadata_t meta,
    out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.eth);
        transition select(hdr.eth.ethertype) {
            0xcdef : parse_h1;
            default : accept;
        }
    }

    state parse_h1 {
        pkt.extract(hdr.h1);
        transition accept;
    }
}

parser EgressParser(
    packet_in pkt,
    out headers_t hdr,
    out metadata_t meta,
    out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

control Ingress(
    inout headers_t hdr,
    inout metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action hit() {
        hdr.eth.dst_addr = hdr.eth.src_addr;
    }

    action hit2() {
        hdr.eth.dst_addr = hdr.eth.src_addr;
    }

    action hit3() {
        hdr.eth.dst_addr = hdr.eth.src_addr;
    }

    action hit4() {
        hdr.eth.dst_addr = hdr.eth.src_addr;
    }

    action hit5() {
        ig_intr_tm_md.ucast_egress_port = 2;
    }

    action hit6(bit<48> eth_dst) {
        hdr.eth.dst_addr = eth_dst;
    }

    action hit7(bit<16> eth_type) {
        hdr.eth.ethertype = eth_type;
    }

    table table1 {
        key = {
            hdr.h1.f1 : exact;
            hdr.h1.f2 : exact @hash_mask(0);  // Field excluded completely from hash calculation.
        }

        actions = {
            hit;
            hit2;
            hit3;
            hit4;
            hit5;
            hit7;
            NoAction;
        }

        size = 1024;
    }

    table table2 {
        key = {
            hdr.h1.f3 : exact;
            hdr.h1.f4 : exact;
        }

        actions = {
            hit;
            NoAction;
        }

        size = 4096;
    }

    apply {
        table1.apply();
        table2.apply();
    }
}

control Egress(
    inout headers_t hdr,
    inout metadata_t meta,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

control IngressDeparser(
    packet_out pkt,
    inout headers_t hdr,
    in metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        pkt.emit(hdr);
    }
}

control EgressDeparser(
    packet_out pkt,
    inout headers_t hdr,
    in metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {
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
