#include <core.p4>
#include <t2na.p4>

// This program tests the maximum amount of CLOTs you can have per packet (16)
// and per gress (64). This is done by having 4 mutually exclusive parser paths
// with 16 CLOTs.

#define TAKE_PATH_A_INGRESS 0x00000010
#define TAKE_PATH_B_INGRESS 0x00000011
#define TAKE_PATH_C_INGRESS 0x00000012
#define TAKE_PATH_D_INGRESS 0x00000013

#define TAKE_PATH_A_EGRESS 0x000000E0
#define TAKE_PATH_B_EGRESS 0x000000E1
#define TAKE_PATH_C_EGRESS 0x000000E2
#define TAKE_PATH_D_EGRESS 0x000000E3

header path_t {
    bit<32> field_0;
}

// Any clot_t bigger than 8 bytes will cause the deparser to run out of chunks.
header clot_t {
    bit<64> unused_field;
}

struct metadata {
}

struct headers {
    path_t path;
    clot_t[16] a;
    clot_t[16] b;
    clot_t[16] c;
    clot_t[16] d;
}

parser IngressParser(packet_in packet, out headers hdr, out metadata meta,
                     out ingress_intrinsic_metadata_t ig_intr_md) {

    ParserCounter() parser_counter;
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.path);
        parser_counter.set(8w15);
        transition select(hdr.path.field_0) {
            (TAKE_PATH_A_INGRESS) : parse_a;
            (TAKE_PATH_B_INGRESS) : parse_b;
            (TAKE_PATH_C_INGRESS) : parse_c;
            (TAKE_PATH_D_INGRESS) : parse_d;
            default: accept;
        }
    }

    state parse_a {
        transition select(parser_counter.is_zero()) {
            true: accept;
            false: parse_a_element;
        }
    }
    state parse_a_element {
        packet.extract(hdr.a.next);
        parser_counter.decrement(1);
        transition parse_a;
    }

    state parse_b {
        transition select(parser_counter.is_zero()) {
            true: accept;
            false: parse_b_element;
        }
    }
    state parse_b_element {
        packet.extract(hdr.b.next);
        parser_counter.decrement(1);
        transition parse_b;
    }

    state parse_c {
        transition select(parser_counter.is_zero()) {
            true: accept;
            false: parse_c_element;
        }
    }
    state parse_c_element {
        packet.extract(hdr.c.next);
        parser_counter.decrement(1);
        transition parse_c;
    }

    state parse_d {
        transition select(parser_counter.is_zero()) {
            true: accept;
            false: parse_d_element;
        }
    }
    state parse_d_element {
        packet.extract(hdr.d.next);
        parser_counter.decrement(1);
        transition parse_d;
    }
}

control IngressPipeline(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        ig_intr_tm_md.ucast_egress_port = 2;

        // Must write to hdr.path.field_0 to test a path in egress parser
        // and to avoid it being allocated to CLOTs intead of a/b/c/d
        if (hdr.a[0].isValid()) {
            hdr.path.field_0 = TAKE_PATH_A_EGRESS;
        }

        if (hdr.b[0].isValid()) {
            hdr.path.field_0 = TAKE_PATH_B_EGRESS;
        }

        if (hdr.c[0].isValid()) {
            hdr.path.field_0 = TAKE_PATH_C_EGRESS;
        }

        if (hdr.d[0].isValid()) {
            hdr.path.field_0 = TAKE_PATH_D_EGRESS;
        }
    }
}

control IngressDeparser(packet_out packet,
                        inout headers hdr,
                        in metadata meta,
                        in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        packet.emit(hdr);
    }
}

parser EgressParser(packet_in packet, out headers hdr, out metadata meta,
                    out egress_intrinsic_metadata_t eg_intr_md) {

    ParserCounter() parser_counter;
    state start {
        packet.extract(eg_intr_md);
        packet.extract(hdr.path);
        parser_counter.set(8w15);
        transition select(hdr.path.field_0) {
            (TAKE_PATH_A_EGRESS) : parse_a;
            (TAKE_PATH_B_EGRESS) : parse_b;
            (TAKE_PATH_C_EGRESS) : parse_c;
            (TAKE_PATH_D_EGRESS) : parse_d;
        }
    }

    state parse_a {
        transition select(parser_counter.is_zero()) {
            true: accept;
            false: parse_a_element;
        }
    }
    state parse_a_element {
        packet.extract(hdr.a.next);
        parser_counter.decrement(1);
        transition parse_a;
    }

    state parse_b {
        transition select(parser_counter.is_zero()) {
            true: accept;
            false: parse_b_element;
        }
    }
    state parse_b_element {
        packet.extract(hdr.b.next);
        parser_counter.decrement(1);
        transition parse_b;
    }

    state parse_c {
        transition select(parser_counter.is_zero()) {
            true: accept;
            false: parse_c_element;
        }
    }
    state parse_c_element {
        packet.extract(hdr.c.next);
        parser_counter.decrement(1);
        transition parse_c;
    }

    state parse_d {
        transition select(parser_counter.is_zero()) {
            true: accept;
            false: parse_d_element;
        }
    }
    state parse_d_element {
        packet.extract(hdr.d.next);
        parser_counter.decrement(1);
        transition parse_d;
    }
}

control EgressPipeline(
        inout headers hdr,
        inout metadata meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
        // Must write to hdr.path.field_0 to avoid it being allocated to CLOTs
        // intead of a/b/c/d
        if (hdr.a[0].isValid()) {
            hdr.path.field_0 = TAKE_PATH_A_EGRESS;
        }

        if (hdr.b[0].isValid()) {
            hdr.path.field_0 = TAKE_PATH_B_EGRESS;
        }

        if (hdr.c[0].isValid()) {
            hdr.path.field_0 = TAKE_PATH_C_EGRESS;
        }

        if (hdr.d[0].isValid()) {
            hdr.path.field_0 = TAKE_PATH_D_EGRESS;
        }
    }
}

control EgressDeparser(packet_out packet,
                       inout headers hdr,
                       in metadata meta,
                       in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
        packet.emit(hdr);
    }
}

Pipeline(IngressParser(),
         IngressPipeline(),
         IngressDeparser(),
         EgressParser(),
         EgressPipeline(),
         EgressDeparser()) pipe;

Switch(pipe) main;
