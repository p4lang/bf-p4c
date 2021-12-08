// Verify that parse depth checks/adjustments are implemented correctly
//
// Tofino 1:
//  - egress parser:
//     - min depth: 65 B
//     - max depth: 160 B
//
// Slightly complex case:
//  - unused parser counter
//  - variable-length header

#include <tna.p4>    /* TOFINO1_ONLY */

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ethertype;
}

header IPv4_no_options_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header IPv4_options_h {
    varbit<128> options;
}

header hdr32b_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<32> f5;
    bit<32> f6;
    bit<32> f7;
    bit<32> f8;
};

struct headers_t {
    ethernet_t eth;
    IPv4_no_options_h ipv4;
    IPv4_options_h ipv4_opt;
    hdr32b_t h1;
    hdr32b_t h2;
}

struct metadata_t {
}

error { InvalidIPv4Header }

parser CommonParser(
    packet_in pkt,
    out headers_t hdr) {
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.eth);
        transition select(hdr.eth.ethertype) {
            0xcdef : parse_h1;
            0x0800 : parse_ipv4;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        verify(hdr.ipv4.ihl >= 5, error.InvalidIPv4Header);
        transition select (hdr.ipv4.ihl) {
            5: parse_h1;
            _: parse_ipv4_options;
        }
    }

    state parse_ipv4_options {
        // use information in the ipv4 header to compute the number
        // of bits to extract
        pkt.extract(hdr.ipv4_opt,
            (bit<32>)(((bit<16>)hdr.ipv4.ihl - 5) * 32));
        transition parse_h1;
    }


    state parse_h1 {
        pkt.extract(hdr.h1);
        transition select(hdr.h1.f1[31:24]) {
            0xf : parse_h2;
            0xe : reject;
            default : accept;
        }
    }

    state parse_h2 {
        pkt.extract(hdr.h2);
        transition accept;
    }
}

parser IngressParser(
    packet_in pkt,
    out headers_t hdr,
    out metadata_t meta,
    out ingress_intrinsic_metadata_t ig_intr_md) {
    CommonParser() common_parser;

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_packet;
    }

    state parse_packet {
        common_parser.apply(pkt, hdr);
        transition accept;
    }
}

parser EgressParser(
    packet_in pkt,
    out headers_t hdr,
    out metadata_t meta,
    out egress_intrinsic_metadata_t eg_intr_md) {
    CommonParser() common_parser;
    ParserCounter() pctr;

    state start {
        pkt.extract(eg_intr_md);
        transition parse_bridged_metadata;
    }

    state parse_bridged_metadata {
        transition parse_packet;
    }

    state parse_packet {
        common_parser.apply(pkt, hdr);
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
    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;

        // Operation to ensure that the h2 header is extracted
        if (hdr.h2.isValid() && hdr.h2.f6[0:0] != 0x0) {
            hdr.h2.f8 = hdr.h2.f7;
        }
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
        // Operation to ensure that the h2 header is extracted
        if (hdr.h2.isValid() && hdr.h2.f6[1:1] != 0x0) {
            hdr.h2.f7 = hdr.h2.f8;
        }
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
