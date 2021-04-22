
#include <t2na.p4>





//-----------------------------------------------------------------------------
// Egress parser code producing the following error:
//
// error: Inferred incompatible container alignments for field egress::eg_md.field:
// ../../p4c-3431.p4(71): alignment = 6 (little endian)
//         eg_md.field = parse_1_md.field;
//         ^^^^^^^^^^^
// Previously inferred alignments:
// ../../p4c-3431.p4(62): alignment = 0 (little endian)
//         eg_md.field = hdr.field;
//         ^^^^^^^^^^^
//-----------------------------------------------------------------------------

header pkt_id_metadata_t {
    bit<8> type;
}

// Extracted in parse_0
@flexible
header header_t {
    bit<3> _pad0;
    bit<5> _pad1;
    bit<10> field;  // offset 6
    bit<6> _pad2;
}

// Extracted in parse_1
header parse_1_metadata_t {
    bit<8> _pad0;
    bit<8> _pad1;
    bit<48> _pad2;
    bit<10> field;  // offset 0
    bit<6> _pad3;
}

// Assigned in parse_0 and parse_1
struct metadata_t {
    bit<10> field;  // offset 0
}


parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);

        pkt_id_metadata_t pkt_id_md = pkt.lookahead<pkt_id_metadata_t>();
        transition select(pkt_id_md.type) {
            0 : parse_0;
            1 : parse_1;
        }
    }

    state parse_0 {
        pkt.extract(hdr);

        eg_md.field = hdr.field;

        transition accept;
    }

    state parse_1 {
        parse_1_metadata_t parse_1_md;
        pkt.extract(parse_1_md);

        eg_md.field = parse_1_md.field;

        transition accept;
    }
}





//-----------------------------------------------------------------------------
// Other controls
//-----------------------------------------------------------------------------

struct empty_header_t {}

struct empty_metadata_t {}

parser EmptyIngressParser(
        packet_in pkt,
        out empty_header_t hdr,
        out empty_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyIngressDeparser(
        packet_out pkt,
        inout empty_header_t hdr,
        in empty_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyIngress(
        inout empty_header_t hdr,
        inout empty_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        in ghost_intrinsic_metadata_t g_intr_md
        ) {
    apply {}
}

control SwitchEgress(
        inout header_t hdr,
        inout metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {}
}

control SwitchEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {}
}

Pipeline(EmptyIngressParser(),
         EmptyIngress(),
         EmptyIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()
        ) pipe;

Switch(pipe) main;
