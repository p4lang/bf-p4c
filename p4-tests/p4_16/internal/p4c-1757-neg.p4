#include <core.p4>
#include <tna.p4>

header common_h {
    bit<8> type;
}

header hdr1_h {
    bit<2048> foo;
}

header hdr2_h {
    bit<2048> foo;
}

header hdr3_h {
    bit<2048> foo;
}

struct headers_t {
    common_h common;
    hdr1_h hdr1;
    hdr2_h hdr2;
    hdr3_h hdr3;
}

struct metadata_t {
}

parser ingress_parser(
        packet_in pkt,
        out headers_t hdr,
        out metadata_t metadata,
        out ingress_intrinsic_metadata_t
            ingress_intrinsic_metadata)
{
    state start {
        pkt.extract(hdr.common);
        transition select(hdr.common.type) {
            0x01: parse_hdr1;
            0x02: parse_hdr2;
            0x03: parse_hdr3;
        }
    }

    state parse_hdr1 {
        pkt.extract(hdr.hdr1);
        transition accept;
    }

    state parse_hdr2 {
        pkt.extract(hdr.hdr2);
        transition accept;
    }

    state parse_hdr3 {
        pkt.extract(hdr.hdr3);
        transition accept;
    }
}

control ingress_control(
        inout headers_t hdr,
        inout metadata_t metadata,
        in ingress_intrinsic_metadata_t ingress_intrinsic_metadata,
        in ingress_intrinsic_metadata_from_parser_t
            ingress_intrinsic_metadata_from_parser,
        inout ingress_intrinsic_metadata_for_deparser_t
            ingress_intrinsic_metadata_for_deparser,
        inout ingress_intrinsic_metadata_for_tm_t
            ingress_intrinsic_metadata_for_tm)
{
    apply {
    }
}

control ingress_deparser(
        packet_out pkt,
        inout headers_t hdr,
        in metadata_t metadata,
        in ingress_intrinsic_metadata_for_deparser_t
            ingress_intrinsic_metadata_for_deparser)
{
    apply {
        pkt.emit(hdr);
    }
}

parser egress_parser(
        packet_in pkt,
        out headers_t hdr,
        out metadata_t metadata,
        out egress_intrinsic_metadata_t egress_intrinsic_metadata)
{
    state start {
        transition accept;
    }
}

control egress_control(
        inout headers_t hdr,
        inout metadata_t metadata,
        in egress_intrinsic_metadata_t egress_intrinsic_metadata,
        in egress_intrinsic_metadata_from_parser_t
            egress_intrinsic_metadata_from_parser,
        inout egress_intrinsic_metadata_for_deparser_t
            egress_intrinsic_metadata_for_deparser,
        inout egress_intrinsic_metadata_for_output_port_t
            egress_intrinsic_metadata_for_output_port)
{
    apply {}
}

control egress_deparser(
        packet_out pkt,
        inout headers_t hdr,
        in metadata_t metadata,
        in egress_intrinsic_metadata_for_deparser_t
            egress_intrinsic_metadata_for_deparser)
{
    apply {}
}

Pipeline(
    ingress_parser(),
    ingress_control(),
    ingress_deparser(),
    egress_parser(),
    egress_control(),
    egress_deparser()
) pipe;

Switch(pipe) main;
